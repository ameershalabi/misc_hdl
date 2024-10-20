--------------------------------------------------------------------------------
-- Title       : rvh_FIFO
-- Project     : rvh_blocks
--------------------------------------------------------------------------------
-- File        : rvh_FIFO.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Feb 13 12:37:04 2024
-- Last update : Wed Mar  6 17:53:22 2024
-- Platform    : -
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity rvh_FIFO is
  generic (
    w_data_in_g : integer := 16;
    d_FIFO_g    : integer := 8
  );

  Port (

    -- ctrl signals
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    -- input signals
    valid_i : in std_logic;
    ready_i : in std_logic;
    data_i  : in std_logic_vector(w_data_in_g -1 downto 0);

    -- output signals
    full_o  : out std_logic;
    empty_o : out std_logic;

    valid_o : out std_logic;
    ready_o : out std_logic;
    data_o  : out std_logic_vector(w_data_in_g -1 downto 0)

  );
end rvh_FIFO;

architecture Behavioral of rvh_FIFO is

  signal clr_r : std_logic;
  signal enb_r : std_logic;

  type fifo_r_t is array (d_FIFO_g-1 downto 0) of std_logic_vector(w_data_in_g -1 downto 0);
  signal fifo_r : fifo_r_t;

  signal fifo_valid_r : std_logic_vector(d_FIFO_g -1 downto 0);
  signal head_r       : integer range 0 to d_FIFO_g-1;
  signal tail_r       : integer range 0 to d_FIFO_g-1;

  signal fifo_ready : std_logic;
  signal fifo_full  : std_logic;
  signal fifo_empty : std_logic;

begin

  get_input_proc : process (clk, rst)
  begin
    if (rst = '0') then
      clr_r <= '0';
      enb_r <= '0';
    elsif rising_edge(clk) then
      clr_r <= clr;
      enb_r <= enb;
    end if;
  end process get_input_proc;


  ctrl_proc : process (fifo_valid_r)
  begin
    fifo_full  <= '0';
    fifo_empty <= '0';
    fifo_ready <= '1';
    if (unsigned(not fifo_valid_r) = to_unsigned(0,d_FIFO_g-1)) then
      fifo_full  <= '1';
      fifo_ready <= '0';
    elsif(unsigned(fifo_valid_r) = to_unsigned(0,d_FIFO_g-1)) then
      fifo_empty <= '1';
      fifo_ready <= '1';
    else
      fifo_full  <= '0';
      fifo_empty <= '0';
      fifo_ready <= '1';
    end if;
  end process ctrl_proc;


  fifo_proc : process (clk, rst)
  begin
    if (rst = '0') then
      fifo_r       <= (others => (others => '0'));
      fifo_valid_r <= (others => '0');
      head_r       <= 0;
      tail_r       <= 0;
    elsif rising_edge(clk) then
      if (enb_r = '1') then
        --if (fifo_full = '0') then
        if (valid_i = '1' and fifo_ready = '1') then
          -- read input
          fifo_valid_r(head_r) <= '1';
          -- update valid
          fifo_r(head_r) <= data_i;
          -- increment head of queue
          if head_r = d_FIFO_g-1 then
            head_r <= 0;
          else
            head_r <= head_r + 1;
          end if;

        end if;
        --end if;

        --if (fifo_empty = '0') then
        if (ready_i = '1' and fifo_valid_r(tail_r) = '1') then
          -- increment tail
          if tail_r = d_FIFO_g-1 then
            tail_r <= 0;
          else
            tail_r <= tail_r + 1;
          end if;
          fifo_valid_r(tail_r) <= '0';
        -- update valid
        end if;
        --end if;

        if (clr_r = '1') then
          fifo_r       <= (others => (others => '0'));
          fifo_valid_r <= (others => '0');
          head_r       <= 0;
          tail_r       <= 0;
        end if;
      end if;
    end if;
  end process fifo_proc;

  full_o  <= fifo_full;
  empty_o <= fifo_empty;
  valid_o <= fifo_valid_r(tail_r);
  ready_o <= fifo_ready;
  data_o  <= fifo_r(tail_r);

end Behavioral;
