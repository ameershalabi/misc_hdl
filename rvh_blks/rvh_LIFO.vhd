--------------------------------------------------------------------------------
-- Title       : rvh_LIFO
-- Project     : rvh_blocks
--------------------------------------------------------------------------------
-- File        : rvh_LIFO.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Wed Feb 14 10:31:24 2024
-- Last update : Sat Feb 17 11:44:52 2024
-- Platform    : -
-- Standard    : <VHDL-2008>
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------


library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity rvh_LIFO is
  generic (
    w_data_in_g : integer := 16;
    d_LIFO_g    : integer := 8
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
end rvh_LIFO;

architecture Behavioral of rvh_LIFO is
  signal clr_r : std_logic;
  signal enb_r : std_logic;

  type lifo_r_t is array (d_LIFO_g-1 downto 0) of std_logic_vector(w_data_in_g -1 downto 0);
  signal lifo_r : lifo_r_t;

  signal lifo_valid_r : std_logic_vector(d_LIFO_g -1 downto 0);

  signal lifo_ready : std_logic;
  signal lifo_full  : std_logic;
  signal lifo_empty : std_logic;

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

  ctrl_proc : process (lifo_valid_r)
  begin
    lifo_full  <= '0';
    lifo_empty <= '0';
    lifo_ready <= '1';

    if (unsigned(not lifo_valid_r) = to_unsigned(0,d_LIFO_g-1)) then
      lifo_full  <= '1';
      lifo_ready <= '0';
    end if;

    if(unsigned(lifo_valid_r) = to_unsigned(0,d_LIFO_g-1)) then
      lifo_empty <= '1';
    end if;
  end process ctrl_proc;

  lifo_proc : process (clk, rst)
  begin
    if (rst = '0') then
      lifo_r       <= (others => (others => '0'));
      lifo_valid_r <= (others => '0');
    elsif rising_edge(clk) then
      if (enb_r = '1') then

        if (valid_i = '1' and lifo_ready = '1') then

          push_stack_loop : for lifo_idx in d_LIFO_g-2 downto 0 loop
            lifo_r(lifo_idx)       <= lifo_r(lifo_idx+1);
            lifo_valid_r(lifo_idx) <= lifo_valid_r(lifo_idx+1);
          end loop push_stack_loop;
          lifo_r(d_LIFO_g-1)       <= data_i;
          lifo_valid_r(d_LIFO_g-1) <= '1';
        end if;

        if (ready_i = '1' and lifo_valid_r(d_LIFO_g-1)='1') then
          lifo_r(0)       <= (others => '0');
          lifo_valid_r(0) <= '0';
          pop_stack_loop : for lifo_idx in d_LIFO_g-1 downto 1 loop
            lifo_r(lifo_idx)       <= lifo_r(lifo_idx-1);
            lifo_valid_r(lifo_idx) <= lifo_valid_r(lifo_idx-1);
          end loop pop_stack_loop;

        end if;

        if (clr_r = '1') then
          lifo_r       <= (others => (others => '0'));
          lifo_valid_r <= (others => '0');
        end if;
      end if;
    end if;
  end process lifo_proc;

  full_o  <= lifo_full;
  empty_o <= lifo_empty;
  valid_o <= lifo_valid_r(d_LIFO_g-1);
  ready_o <= lifo_ready;
  data_o  <= lifo_r(d_LIFO_g-1);


end Behavioral;
