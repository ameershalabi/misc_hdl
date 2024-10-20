--------------------------------------------------------------------------------
-- Title       : rvh_PISO
-- Project     : rvh_blocks
--------------------------------------------------------------------------------
-- File        : rvh_PISO.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Jan 30 11:19:41 2024
-- Last update : Wed Mar  6 16:17:55 2024
-- Platform    : -
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Description: A parallel-in serrial-out register with ready valid handshake.
-- The register takes in a n_words_g*w_data_in_g data word of and outputs  
-- n_words_g number of words of w_data_in_g width.
-- The first output word is the w_data_in_g LSBs of the input word.
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity rvh_PISO is
  generic (
    n_words_g : integer := 4;
    w_word_g  : integer := 8
  );

  Port (

    -- ctrl signals
    clk : in std_logic; -- clock pin
    rst : in std_logic; -- active low rest pin
    clr : in std_logic; -- clear pin
    enb : in std_logic; -- enable pin

    msb_first_i : in std_logic;

    -- input signals
    valid_i : in std_logic;
    ready_i : in std_logic;
    data_i  : in std_logic_vector(n_words_g * w_word_g -1 downto 0);

    -- output signals
    valid_o : out std_logic;
    ready_o : out std_logic;
    data_o  : out std_logic_vector(w_word_g -1 downto 0)


  );
end rvh_PISO;

architecture Behavioral of rvh_PISO is

  constant counter_max_value : integer := n_words_g-1;

  type piso_arr is array (n_words_g -1 downto 0) of std_logic_vector(w_word_g-1 downto 0);
  signal piso_arr_r : piso_arr;

  signal counter_r : integer range 0 to n_words_g-1;

  signal piso_ready : std_logic;

  signal valid_r : std_logic;

  signal msb_first_r : std_logic;

begin

  vald_rdy_proc : process (counter_r,valid_r,enb)
  begin
    -- if disabled, both ready and valid are disabled
    piso_ready <= '0';
    if (enb = '1') then
      -- if the counter at 0 and the data inside the piso is
      -- nopt valid, then, piso is ready to get data.
      if (counter_r = 0) then
        if valid_r = '0' then
          piso_ready <= '1';
        end if;
      end if;
    end if;
  end process vald_rdy_proc;

  PISO_reg_proc : process (clk, rst)
  begin

    -- active low reset block
    if (rst = '0') then
      piso_arr_r  <= (others => (others => '0'));
      counter_r   <= 0;
      valid_r     <= '0';
      msb_first_r <= '0';

    -- clk trigger  
    elsif rising_edge(clk) then
      -- When the register is enabled
      if (enb = '1') then

        -----------------------------------
        -- -- read data from sender when:
        -- -- input is valid
        -- -- piso is ready to recieve
        -- Data is only captured from input when the sender has valid data
        -- and the piso is ready to receive the data. piso is ready
        -- to receive when the counter is at max value
        -----------------------------------
        if valid_i = '1' and piso_ready = '1' then

          if msb_first_r = '0' then
            -- the data is split into equal length words, least significant word first
            get_lsb_first_word_arr_loop : for word in 0 to n_words_g-1 loop
              piso_arr_r(word) <= data_i(word*w_word_g+w_word_g -1 downto word*w_word_g);
            end loop get_lsb_first_word_arr_loop;
          else
            -- the data is split into equal length words, most significant word first
            get_msb_first_word_arr_loop : for word in 0 to n_words_g-1 loop
              piso_arr_r(word) <= data_i(n_words_g-1-word*w_word_g+w_word_g -1 downto n_words_g-1-word*w_word_g);
            end loop get_msb_first_word_arr_loop;
          end if;
          valid_r <= '1';


        end if;
        -----------------------------------
        -- invalidate data when :
        -- -- all words are outputed
        -- -- receiver is ready to recieve
        -- When the data inside the piso is valid, and the receiver is ready,
        -- the receiver captures the data on the output of the piso. This
        -- means that a word inside the piso is no longer valid and the next
        -- word is sent out. if all words are sent out, then set counted to 0
        -- and set data inside piso to not valid
        -----------------------------------
        if valid_r = '1' and ready_i = '1' then

          if (counter_r < counter_max_value) then
            counter_r <= counter_r + 1;
          else
            counter_r <= 0;
            valid_r   <= '0';
          end if;
        end if;


        -- Clear port is only effective when the register is enabled.
        if (clr = '1') then
          piso_arr_r  <= (others => (others => '0'));
          counter_r   <= 0;
          valid_r     <= '0';
          msb_first_r <= msb_first_i;
        end if;
      end if;
    end if;
  end process PISO_reg_proc;
  ready_o <= piso_ready;
  valid_o <= valid_r;
  data_o  <= piso_arr_r(counter_r);

end Behavioral;
