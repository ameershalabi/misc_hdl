--------------------------------------------------------------------------------
-- Title       : SPI main block
-- Project     : hdl_comm (misc_hdl)
--------------------------------------------------------------------------------
-- File        : spi_main.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Fri Nov 15 15:16:07 2024
-- Last update : Mon Jan  5 08:58:18 2026
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2024 User Company Name
-------------------------------------------------------------------------------
-- Description: An implementation of an SPI main block
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_main is
  generic (
    n_subnodes_g : integer := 1;  -- number of subnode per main
    w_trans_g    : integer := 32; -- width of tranmission data

    -- number of clk cycles per spi_clk transition
    -- e.g. if clk_div_g = 5, then one single spi_clk transition H->L or L->H
    -- happens every 5 clk cycles
    -- or, if clk is at 200Mhz, SCLK will be at (200/5+5) = 20 MHz
    clk_div_g : integer   := 5;
    cpol_g    : std_logic := '0';
    cpha_g    : std_logic := '0'
  );
  port (
    clk    : in std_logic; -- clock pin
    n_arst : in std_logic; -- active low rest pin

    tx_data_i : in  std_logic_vector(w_trans_g-1 downto 0); -- data to send
    rx_data_o : out std_logic_vector(w_trans_g-1 downto 0); -- data recieved

    tx_start_i : in  std_logic; -- start send bit
    rx_valid_o : out std_logic; -- recieved data is valid

    spi_busy_o : out std_logic; -- main is busy

    SCLK : out std_logic; -- synch clk
    MOSI : out std_logic; -- data being sent from main
    MISO : in  std_logic; -- data being recieved from subnode

    -- vector to hold CS for subnodes (active low)
    CS : out std_logic_vector(n_subnodes_g-1 downto 0)

  );
end entity spi_main;

architecture arch of spi_main is
  -- clock polarity signal
  constant idle_pol : std_logic := cpol_g;
  -- clock divider signals
  signal div_clk_r         : std_logic;
  signal div_clk_rising_r  : std_logic;
  signal div_clk_falling_r : std_logic;
  -- sample and shift enable signals
  signal samp_en : std_logic;
  signal shft_en : std_logic;
  -- shift data register (parallel input)
  signal shft_data_r : std_logic_vector(w_trans_g-1 downto 0);
  -- sample data register (parallel output)
  signal samp_data_r : std_logic_vector(w_trans_g-1 downto 0);
  -- internal signals
  signal internal_busy  : std_logic;
  signal internal_valid : std_logic;
  signal spi_start      : std_logic;

  -- spi clk singal
  signal spi_clk       : std_logic;
  signal enb_spi_clk   : std_logic;
  signal enb_spi_clk_r : std_logic;

  -- fsm control and registers
  type fsm_t is (idle, spi_active, output_rx);
  signal fsm_state : fsm_t;
  signal fsm_next  : fsm_t;

  -- fsm transaction counter
  signal samp_counter_r : integer range 0 to w_trans_g;
  signal shft_counter_r : integer range 0 to w_trans_g;
  signal samp_done      : std_logic;
  signal shft_done      : std_logic;
  signal spi_trans_done : std_logic;

  -- rx output signals
  signal samp_data_valid : std_logic;

begin
  -------------------------------
  -- CREATE THE SPI MODE CONTROL
  -------------------------------

  -- SPI modes using cpol_g and cpha_g
  --------|--------|--------|------------|---------|---------|
  -- mode | cpol_g | cpha_g | idle state | sample  |  shift  |
  --------|--------|--------|------------|---------|---------|
  --   0  |   '0'  |   '0'  |    '0'     | rising  | falling |
  --------|--------|--------|------------|---------|---------|
  --   1  |   '0'  |   '1'  |    '0'     | falling | rising  |
  --------|--------|--------|------------|---------|---------|
  --   2  |   '1'  |   '0'  |    '1'     | falling | rising  |
  --------|--------|--------|------------|---------|---------|
  --   3  |   '1'  |   '1'  |    '1'     | rising  | falling |
  --------|--------|--------|------------|---------|---------|

  -- create clock sample/shift polarity at each clock polarity
  gen_pol_p : if (cpol_g = '0') generate
    gen_phase_pol_0 : if (cpha_g = '0') generate
      samp_en <= div_clk_rising_r;
      shft_en <= div_clk_falling_r;
    end generate;
    gen_phase_pol_1 : if (cpha_g = '1') generate
      samp_en <= div_clk_falling_r;
      shft_en <= div_clk_rising_r;
    end generate;
  end generate;

  gen_pol_n : if (cpol_g = '1') generate
    gen_phase_pol_2 : if (cpha_g = '0') generate
      samp_en <= div_clk_falling_r;
      shft_en <= div_clk_rising_r;
    end generate;
    gen_phase_pol_3 : if (cpha_g = '1') generate
      samp_en <= div_clk_rising_r;
      shft_en <= div_clk_falling_r;
    end generate;
  end generate;

  -- generate divider clock
  pol_generator_proc : process (clk, n_arst)
    variable div_counter_v : integer range 0 to clk_div_g-1;
    variable half_trans_v  : std_logic;
    variable curr_clk      : std_logic;
    variable prev_clk      : std_logic;
  begin
    if (n_arst = '0') then
      div_counter_v := 0;
      -- create clock divider. initialise with idel polarity
      div_clk_r         <= idle_pol;
      div_clk_rising_r  <= '0';
      div_clk_falling_r <= '0';

      -- spi clock enable flag
      enb_spi_clk_r <= '0';

    elsif rising_edge(clk) then
      -- get previous clock polarity
      prev_clk      := div_clk_r;
      enb_spi_clk_r <= enb_spi_clk;
      if (enb_spi_clk_r = '1') then
        -- divider counter is at max value
        if div_counter_v = clk_div_g-1 then
          -- generate reverse clock polarity
          curr_clk := not div_clk_r;

          -- generate clock edge detectors
          if (curr_clk = '1' and prev_clk = '0') then
            div_clk_rising_r <= '1';
          end if;
          if (curr_clk = '0' and prev_clk = '1') then
            div_clk_falling_r <= '1';
          end if;

          -- reverse divider clock polarity
          div_clk_r <= curr_clk;

          -- reset divider counter
          div_counter_v := 0;
        else
          -- increment divider counter
          div_counter_v := div_counter_v + 1;
          -- edge detector signals not active before
          -- divider counter is max value
          div_clk_rising_r  <= '0';
          div_clk_falling_r <= '0';
        end if;
      else -- spi_clk_enb
        div_counter_v := 0;
        -- create clock divider. initialise with idel polarity
        div_clk_r         <= idle_pol;
        div_clk_rising_r  <= '0';
        div_clk_falling_r <= '0';
      end if; -- spi_clk_enb
    end if;
  end process;

  ----------------------------------------
  -- FSM CONTROL AND REGISTERS
  ---------------------------------------- 

  -- spi start tigger:
  -- when start trigger is high and the spi clock is enabled (spi busy)
  spi_start <= '1' when tx_start_i = '1' and enb_spi_clk_r = '0' else '0';

  -- input register control
  fsm_reg_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      -- always reset to idle
      fsm_state <= idle;
    elsif rising_edge(clk) then
      -- store next state
      fsm_state <= fsm_next;
    end if;
  end process;

  -- control the fsm transition
  fsm_ctrl_proc : process (
      fsm_state,
      spi_start,
      shft_data_r,
      spi_trans_done
    )
  begin
    -- set FSM defaults
    fsm_next        <= idle;
    enb_spi_clk     <= '0';
    MOSI            <= idle_pol;
    samp_data_valid <= '0';
    case (fsm_state) is
      -- in idle state, waiting for spi to start
      when idle =>
        enb_spi_clk <= '0';
        fsm_next    <= idle;
        -- when spi starts, go to active state
        -- enable the spi clock
        if (spi_start = '1') then
          fsm_next    <= spi_active;
          enb_spi_clk <= '1';
        end if;
      when spi_active =>
        -- in active state, forward the shift data to
        -- the MOSI port, keep spi clock enabled until 
        -- all transactions are completed
        fsm_next    <= spi_active;
        MOSI        <= shft_data_r(0);
        enb_spi_clk <= '1';
        -- when transactions are complete, go to output
        -- rx state
        -- disable spi clock
        if (spi_trans_done = '1') then
          fsm_next    <= output_rx;
          enb_spi_clk <= '0';
        end if;
      when output_rx =>
        -- in output rx state, flag sampled data as valid,
        -- go to idle state waiting for next transaction
        samp_data_valid <= '1';
        fsm_next        <= idle;
      when others =>
        fsm_next <= idle;
    end case;
  end process;

  ----------------------------------------
  -- CREATE THE SPI SHIFT REGISTER
  ---------------------------------------- 
  -- input register control
  read_shift_data_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      shft_data_r    <= (others => '0');
      samp_data_r    <= (others => '0');
      samp_counter_r <= 0;
      shft_counter_r <= 0;
    elsif rising_edge(clk) then
      -- if start trigger is recieved, and tx is not busy
      -- store tx_data into shift register
      if (spi_start = '1') then
        shft_data_r    <= tx_data_i;
        samp_counter_r <= 0;
        shft_counter_r <= 0;
      end if;
      if (samp_en = '1') then
        if (fsm_state = spi_active and samp_done = '0') then
          samp_data_r    <= MISO & samp_data_r(w_trans_g-1 downto 1);
          samp_counter_r <= samp_counter_r + 1;
        end if;
      end if;
      if (shft_en = '1') then
        if (fsm_state = spi_active and shft_done = '0') then
          shft_data_r    <= '0' & shft_data_r(w_trans_g-1 downto 1);
          shft_counter_r <= shft_counter_r + 1;
        end if;
      end if;

    end if;
  end process;

  -- sample and shift done flags are high when the counters 
  samp_done <= '1' when shft_counter_r = w_trans_g else '0';
  shft_done <= '1' when shft_counter_r = w_trans_g else '0';

  transaction_done_proc : process (samp_done, shft_done)
  begin
    spi_trans_done <= '0';
    if (samp_done = '1' and shft_done = '1') then
      spi_trans_done <= '1';
    end if;
  end process transaction_done_proc;

  ----------------------------------------
  -- SPI OUITPUTS
  ----------------------------------------
  -- connect spi clock to divider clock
  SCLK <= div_clk_r;
  -- internal is busy as long as the spi clock is enabled
  spi_busy_o <= enb_spi_clk_r;
  rx_valid_o <= samp_data_valid;
  rx_data_o  <= samp_data_r;
end architecture arch;