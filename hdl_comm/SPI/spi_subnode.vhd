--------------------------------------------------------------------------------
-- Title       : SPI subnode block
-- Project     : hdl_comm (misc_hdl)
--------------------------------------------------------------------------------
-- File        : spi_subnode.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Mon Jan  5 09:39:24 2026
-- Last update : Wed Jan  7 21:29:24 2026
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
-- Copyright (c) 2024 User Company Name
-------------------------------------------------------------------------------
-- Description: An implementation of an SPI subnode block
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity spi_subnode is
  generic (
    w_trans_g : integer   := 32; -- width of tranmission data
    cpol_g    : std_logic := '0';
    cpha_g    : std_logic := '0'
  );
  port (
    clk    : in std_logic; -- clock pin
    n_arst : in std_logic; -- active low rest pin

    tx_data_i : in  std_logic_vector(w_trans_g-1 downto 0); -- data to send
    rx_data_o : out std_logic_vector(w_trans_g-1 downto 0); -- data recieved

    rx_valid_o : out std_logic; -- recieved data is valid
    
    SCLK : in  std_logic; -- synch clk
    MOSI : in  std_logic; -- data being recieved from main
    MISO : out std_logic; -- data being sent from subnode

    -- chip select port
    CS : in std_logic

  );
end entity spi_subnode;

architecture arch of spi_subnode is
  -- clock polarity constant
  constant idle_pol : std_logic := cpol_g;

  -- Edge detection
  signal sclk_prev_r      : std_logic;
  signal sclk_clk_rising  : std_logic;
  signal sclk_clk_falling : std_logic;

  signal prev_cs_r  : std_logic;
  signal cs_falling : std_logic;

  -- sample and shift enable signals
  signal samp_en : std_logic;
  signal shft_en : std_logic;

  -- register to store input data
  signal in_data_r : std_logic_vector(w_trans_g-1 downto 0);
  -- shift data register (parallel input)
  signal shft_data_r : std_logic_vector(w_trans_g-1 downto 0);
  -- sample data register (parallel output)
  signal samp_data_r : std_logic_vector(w_trans_g-1 downto 0);

  -- transaction control signals
  signal trans_counter_r     : integer range 0 to w_trans_g;
  signal trans_done          : std_logic;
  signal trans_count_trigger : std_logic;

  -- rx output signals
  signal samp_data_valid_r : std_logic;

begin

  -------------------------------
  -- CREATE THE SPI MODE CONTROL
  -------------------------------

  -- SPI modes using cpol_g and cpha_g
  --|------|--------|--------|------------|---------|---------|
  --| mode | cpol_g | cpha_g | idle state | sample  |  shift  |
  --|------|--------|--------|------------|---------|---------|
  --|   0  |   '0'  |   '0'  |    '0'     | falling | rising  |
  --|------|--------|--------|------------|---------|---------|
  --|   1  |   '0'  |   '1'  |    '0'     | rising  | falling |
  --|------|--------|--------|------------|---------|---------|
  --|   2  |   '1'  |   '0'  |    '1'     | rising  | falling |
  --|------|--------|--------|------------|---------|---------|
  --|   3  |   '1'  |   '1'  |    '1'     | falling | rising  |
  --|------|--------|--------|------------|---------|---------|

  -- create clock sample/shift polarity at each clock polarity
  gen_pol_p : if (cpol_g = '0') generate
    trans_count_trigger <= sclk_clk_falling;
    gen_phase_pol_0 : if (cpha_g = '0') generate
      samp_en <= sclk_clk_falling;
      shft_en <= sclk_clk_rising;
    end generate;
    gen_phase_pol_1 : if (cpha_g = '1') generate
      samp_en <= sclk_clk_rising;
      shft_en <= sclk_clk_falling;
    end generate;
  end generate;

  gen_pol_n : if (cpol_g = '1') generate
    trans_count_trigger <= sclk_clk_rising;
    gen_phase_pol_2 : if (cpha_g = '0') generate
      samp_en <= sclk_clk_rising;
      shft_en <= sclk_clk_falling;
    end generate;
    gen_phase_pol_3 : if (cpha_g = '1') generate
      samp_en <= sclk_clk_falling;
      shft_en <= sclk_clk_rising;
    end generate;
  end generate;

  edge_detectors_proc : process (
      SCLK,
      sclk_prev_r,
      CS,
      prev_cs_r
    )
    variable curr_clk_v : std_logic;
    variable prev_clk_v : std_logic;
    variable curr_cs_v  : std_logic;
    variable prev_cs_v  : std_logic;
  begin

    -- generate the signals needed for edge detection
    curr_clk_v       := SCLK;
    prev_clk_v       := sclk_prev_r;
    sclk_clk_rising  <= '0';
    sclk_clk_falling <= '0';

    curr_cs_v  := CS;
    prev_cs_v  := prev_cs_r;
    cs_falling <= '0';

    -- generate clock edge detectors when CS is pulled low
    if (CS = '0') then
      if (curr_clk_v = '1' and prev_clk_v = '0') then
        sclk_clk_rising <= '1';
      end if;
      if (curr_clk_v = '0' and prev_clk_v = '1') then
        sclk_clk_falling <= '1';
      end if;
    end if;

    if (curr_cs_v = '0' and prev_cs_v = '1') then
      cs_falling <= '1';
    end if;

  end process;



  -- generate divider clock
  pol_generator_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      sclk_prev_r <= idle_pol;
      prev_cs_r   <= '1';
    elsif rising_edge(clk) then
      prev_cs_r <= CS;
      if (CS = '0') then
        sclk_prev_r <= SCLK;
      end if;
    end if; -- spi_clk_enb
  end process;

  sample_shift_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      in_data_r         <= (others => '0');
      shft_data_r       <= (others => '0');
      samp_data_r       <= (others => '0');
      trans_counter_r   <= 0;
      samp_data_valid_r <= '0';
    elsif rising_edge(clk) then
      samp_data_valid_r <= '0';
      if (cs_falling = '1') then
        shft_data_r <= tx_data_i;
      end if;

      if (CS = '0') then
        if (samp_en = '1') then
          samp_data_r <= MOSI & samp_data_r(w_trans_g-1 downto 1);
        end if;
        if (shft_en = '1') then
          shft_data_r <= '0' & shft_data_r(w_trans_g-1 downto 1);
        end if;
        -- reset transaction counter when it is done
        if (trans_done = '1') then
          trans_counter_r   <= 0;
          samp_data_valid_r <= '1';
        else
          -- otherwise
          -- if transaction trigger is high, increment transaction
          -- counter
          if (trans_count_trigger = '1') then
            trans_counter_r <= trans_counter_r + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  MISO       <= shft_data_r(0);
  rx_data_o  <= samp_data_r;
  rx_valid_o <= samp_data_valid_r;
  trans_done <= '1' when trans_counter_r = w_trans_g else '0';

end architecture arch;