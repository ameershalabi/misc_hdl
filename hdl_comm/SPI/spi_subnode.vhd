--------------------------------------------------------------------------------
-- Title       : SPI subnode block
-- Project     : hdl_comm (misc_hdl)
--------------------------------------------------------------------------------
-- File        : spi_subnode.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Mon Jan  5 09:39:24 2026
-- Last update : Thu Jan  8 13:21:22 2026
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Description: An implementation of an SPI subnode block
-- The subnode block remains inactive until the CS in pulled LOW by the main.
-- An edge detector continously checks for the falling edge of the CS. When a 
-- falling edge is detected, the input data to the the subnode in tx_data_i
-- is caputred. Two edge detectors are connected to the SCLK sent by the main
-- and are used to connect to the falling and rising edge triggers to indicate
-- sample enable (samp_en) and shift enable (shft_en).
-- When CS is LOW, the samp_en triggers the shift of bit at the MOSI 
-- port into the MSB of the sample register (shift right). The shft_en triggers
-- the shift of the LSB bit of the shift register (shift right) to the MISO
-- port. At each trigger of both samp_en and shft_en, a dedicated counter is 
-- incremented. When sampling and shifting are both enabled w_trans_g times,
-- the transation is over. A single clock cycle valid flag is put on the 
-- rx_valid_o. Once the CS port is pulled HIGH, the subnode block is inactive.
--------------------------------------------------------------------------------

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

    -- detect falling edge on CS
    if (curr_cs_v = '0' and prev_cs_v = '1') then
      cs_falling <= '1';
    end if;

  end process;

  -- generate edge detection registers
  pol_generator_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      sclk_prev_r <= idle_pol;
      prev_cs_r   <= '1';
    elsif rising_edge(clk) then
      -- get previous cycle CS
      prev_cs_r <= CS;
      -- if CS is high, previous clock is idle_pol
      sclk_prev_r <= idle_pol;
      -- if CS is low, previous cycle clock
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
      -- sample data is invalid by default
      samp_data_valid_r <= '0';
      -- when falling edge on CS is detected,
      -- capture input data
      if (cs_falling = '1') then
        shft_data_r <= tx_data_i;
      end if;

      -- when SC is low,
      if (CS = '0') then
        if (samp_en = '1') then
          -- capture MOSI bit into sample register
          samp_data_r <= MOSI & samp_data_r(w_trans_g-1 downto 1);
        end if;
        if (shft_en = '1') then
          -- shift out LSB bit from shft_data_r
          shft_data_r <= '0' & shft_data_r(w_trans_g-1 downto 1);
        end if;
        -- reset transaction counter when it is done
        -- mark output Rx as valid
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

  -- transacations are done when the transaction counter is 
  -- equal to the width of the data (w_trans_g)
  trans_done <= '1' when trans_counter_r = w_trans_g else '0';

  -- MISO is connected to the LSB of the shft_data_r
  MISO       <= shft_data_r(0);
  rx_data_o  <= samp_data_r;
  rx_valid_o <= samp_data_valid_r;


end architecture arch;