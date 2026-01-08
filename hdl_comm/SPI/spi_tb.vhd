library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity spi_tb is
end spi_tb;

architecture rtl of spi_tb is

  signal tb_clk      : std_logic := '0';
  signal clk_period  : time      := 1 ns;
  signal tb_done     : std_logic := '0';
  signal tb_rst_n    : std_logic := '0';
  signal tb_rst      : std_logic := '1';
  signal tb_rst_done : std_logic := '0';

  constant w_data_c     : integer   := 32;
  constant cpol_c       : std_logic := '0';
  constant cpha_c       : std_logic := '0';
  constant clk_div_c    : integer   := 2;
  constant n_subnodes_c : integer   := 3;

  signal tb_main_tx_data_i  : std_logic_vector(w_data_c-1 downto 0) := (others => '0');
  signal tb_main_rx_data_o  : std_logic_vector(w_data_c-1 downto 0);
  signal tb_main_tx_start_i : std_logic := '0';
  signal tb_main_rx_valid_o : std_logic;
  signal tb_main_spi_busy_o : std_logic;
  signal tb_main_SCLK       : std_logic;
  signal tb_main_MOSI       : std_logic;
  signal tb_main_MISO       : std_logic;
  signal tb_main_CS         : std_logic_vector(n_subnodes_c-1 downto 0);

  signal tb_sub_MISO       : std_logic;
  signal tb_sub_SCLK : std_logic := cpol_c;

  signal tb_sub0_tx_data_i  : std_logic_vector(w_data_c-1 downto 0) := (others => '0');
  signal tb_sub0_rx_data_o  : std_logic_vector(w_data_c-1 downto 0);
  signal tb_sub0_rx_valid_o : std_logic;
  signal tb_sub0_MOSI       : std_logic := cpol_c;
  signal tb_sub0_MISO       : std_logic;
  signal tb_sub0_CS         : std_logic := '0';

  signal tb_sub1_tx_data_i  : std_logic_vector(w_data_c-1 downto 0) := (others => '0');
  signal tb_sub1_rx_data_o  : std_logic_vector(w_data_c-1 downto 0);
  signal tb_sub1_rx_valid_o : std_logic;
  signal tb_sub1_MOSI       : std_logic := cpol_c;
  signal tb_sub1_MISO       : std_logic;
  signal tb_sub1_CS         : std_logic := '0';

  signal tb_sub2_tx_data_i  : std_logic_vector(w_data_c-1 downto 0) := (others => '0');
  signal tb_sub2_rx_data_o  : std_logic_vector(w_data_c-1 downto 0);
  signal tb_sub2_rx_valid_o : std_logic;
  signal tb_sub2_MOSI       : std_logic := cpol_c;
  signal tb_sub2_MISO       : std_logic;
  signal tb_sub2_CS         : std_logic := '0';

begin

  tb_clk <= not tb_clk after clk_period when tb_done /= '1' else '0';

  tb_rst <= not tb_rst_n;

  spi_main : entity work.spi_main
    Generic map(
      n_subnodes_g => n_subnodes_c,
      w_trans_g    => w_data_c,  -- 32bit serial word length is default
      clk_div_g    => clk_div_c, -- SPI mode selection (mode 0 default)
      cpol_g       => cpol_c,    -- CPOL = clock polarity, CPHA = clock phase.
      cpha_g       => cpha_c
    )
    Port map (
      clk    => tb_clk,   -- high-speed serial interface system clock
      n_arst => tb_rst_n, -- reset core
                          ---- serial interface ----
      tx_data_i  => tb_main_tx_data_i,
      rx_data_o  => tb_main_rx_data_o,
      tx_start_i => tb_main_tx_start_i,
      rx_valid_o => tb_main_rx_valid_o,
      spi_busy_o => tb_main_spi_busy_o,
      SCLK       => tb_main_SCLK,
      MOSI       => tb_main_MOSI,
      MISO       => tb_main_MISO,
      CS         => tb_main_CS
    );

  spi_sub0 : entity work.spi_subnode
    Generic map(
      w_trans_g => w_data_c, -- 32bit serial word length is default
      cpol_g    => cpol_c,   -- CPOL = clock polarity, CPHA = clock phase.
      cpha_g    => cpha_c
    )
    Port map (
      clk    => tb_clk,   -- high-speed serial interface system clock
      n_arst => tb_rst_n, -- reset core
                          ---- serial interface ----
      tx_data_i  => tb_sub0_tx_data_i,
      rx_data_o  => tb_sub0_rx_data_o,
      rx_valid_o => tb_sub0_rx_valid_o,
      SCLK       => tb_sub_SCLK,
      MOSI       => tb_sub0_MOSI,
      MISO       => tb_sub0_MISO,
      CS         => tb_sub0_CS
    );

  spi_sub1 : entity work.spi_subnode
    Generic map(
      w_trans_g => w_data_c, -- 32bit serial word length is default
      cpol_g    => cpol_c,   -- CPOL = clock polarity, CPHA = clock phase.
      cpha_g    => cpha_c
    )
    Port map (
      clk    => tb_clk,   -- high-speed serial interface system clock
      n_arst => tb_rst_n, -- reset core
                          ---- serial interface ----
      tx_data_i  => tb_sub1_tx_data_i,
      rx_data_o  => tb_sub1_rx_data_o,
      rx_valid_o => tb_sub1_rx_valid_o,
      SCLK       => tb_sub_SCLK,
      MOSI       => tb_sub1_MOSI,
      MISO       => tb_sub1_MISO,
      CS         => tb_sub1_CS
    );

  spi_sub2 : entity work.spi_subnode
    Generic map(
      w_trans_g => w_data_c, -- 32bit serial word length is default
      cpol_g    => cpol_c,   -- CPOL = clock polarity, CPHA = clock phase.
      cpha_g    => cpha_c
    )
    Port map (
      clk    => tb_clk,   -- high-speed serial interface system clock
      n_arst => tb_rst_n, -- reset core
                          ---- serial interface ----
      tx_data_i  => tb_sub2_tx_data_i,
      rx_data_o  => tb_sub2_rx_data_o,
      rx_valid_o => tb_sub2_rx_valid_o,
      SCLK       => tb_sub_SCLK,
      MOSI       => tb_sub2_MOSI,
      MISO       => tb_sub2_MISO,
      CS         => tb_sub2_CS
    );

  tb_sub_SCLK  <= tb_main_SCLK;

  tb_sub0_MOSI <= tb_main_MOSI;
  tb_sub1_MOSI <= tb_main_MOSI;
  tb_sub2_MOSI <= tb_main_MOSI;

  tb_main_MISO <= tb_sub0_MISO when tb_sub0_CS = '0' else
                  tb_sub1_MISO when tb_sub1_CS = '0' else
                  tb_sub2_MISO when tb_sub2_CS = '0' else
                  'X';
  tb_sub0_CS <= tb_main_CS(0);
  tb_sub1_CS <= tb_main_CS(1);
  tb_sub2_CS <= tb_main_CS(2);

  cs_mux : process (tb_main_CS,tb_sub0_MISO,tb_sub1_MISO,tb_sub2_MISO)
  begin
    tb_sub_MISO <= '0';
    if tb_main_CS(0) = '1' then
      tb_sub_MISO <= tb_sub0_MISO;
    elsif tb_main_CS(1) = '1' then
      tb_sub_MISO <= tb_sub1_MISO;
    elsif tb_main_CS(2) = '1' then
      tb_sub_MISO <= tb_sub2_MISO;
    else
      tb_sub_MISO <= '0';
    end if;
  end process cs_mux;

  process begin
    tb_rst_n <= '0';
    wait for 2*clk_period;
    tb_rst_n    <= '1';
    tb_rst_done <= '1';
    wait;
  end process;

  process begin
    wait until tb_rst_done='1';
    --tb_main_MISO <= '0';
    wait for 2*clk_period;
    tb_main_tx_data_i <= x"80F00F01";
    tb_sub0_tx_data_i <= x"CA666653";
    tb_sub1_tx_data_i <= x"EA099057";
    tb_sub2_tx_data_i <= x"F096690F";
    wait for 2*clk_period;
    wait until rising_edge(tb_clk);
    tb_main_tx_start_i <= '1';
    --tb_main_MISO       <= tb_sub0_MISO;
    wait until rising_edge(tb_clk);
    tb_main_tx_start_i <= '0';
    wait until tb_main_rx_valid_o = '1';
    assert (tb_main_rx_data_o = x"CA666653") report "0 : main_rx output error" severity error;
    assert (tb_sub0_rx_data_o = x"80F00F01") report "0 : sub0 output error" severity error;
    wait for 2*clk_period; wait until rising_edge(tb_clk);
    wait until tb_main_rx_valid_o = '1';
    assert (tb_main_rx_data_o = x"EA099057") report "1 : main_rx output error" severity error;
    assert (tb_sub1_rx_data_o = x"80F00F01") report "1 : sub1 output error" severity error;
    wait for 2*clk_period; wait until rising_edge(tb_clk);
    wait until tb_main_rx_valid_o = '1';
    assert (tb_main_rx_data_o = x"F096690F") report "2 : main_rx output error" severity error;
    assert (tb_sub2_rx_data_o = x"80F00F01") report "2 : sub2 output error" severity error;

    wait;
  end process;
end architecture rtl;
