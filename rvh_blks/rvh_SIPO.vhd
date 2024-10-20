--------------------------------------------------------------------------------
-- Title       : rvh_SIPO
-- Project     : rvh_blocks
--------------------------------------------------------------------------------
-- File        : rvh_SIPO.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Jan 30 00:00:46 2024
-- Last update : Wed Mar  6 17:47:33 2024
-- Platform    : -
-- Standard    : <VHDL-2008>
-------------------------------------------------------------------------------
-- Description: A serrial-in parallel-out register with ready valid handshake.
-- The register takes in n_words_g number of data words of width w_data_in_c
-- serially and outputs them as a concatenated n_words_g*w_data_in_c width 
-- data word. The first input word occupies the w_data_in_c LSB of the output 
-- word and the second is concatenated to it from the MSB side and so on.
-------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity rvh_SIPO is
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
    data_i  : in std_logic_vector(w_word_g -1 downto 0);

    -- output signals
    valid_o : out std_logic;
    ready_o : out std_logic;
    data_o  : out std_logic_vector(w_word_g * n_words_g -1 downto 0)


  );
end rvh_SIPO;

architecture Behavioral of rvh_SIPO is

  constant counter_max_value : integer := n_words_g;

  type sipo_arr is array (n_words_g -1 downto 0) of std_logic_vector(w_word_g-1 downto 0);
  signal sipo_arr_r : sipo_arr;

  signal counter_r : integer range 0 to n_words_g;

  signal sipo_ready : std_logic;
  signal sipo_valid : std_logic;

  signal msb_first_r : std_logic;

begin

  vald_rdy_proc : process (counter_r, enb)
  begin
    -- if disabled, both ready and valid are disabled
    sipo_ready <= '0';
    sipo_valid <= '0';
    if (enb = '1') then
      -- if the counter at max, all data received is valid and stored
      -- in the data registers. therfore, output data is valid
      if (counter_r = counter_max_value) then
        sipo_valid <= '1';

      -- if the counter is not at max, more data can be received
      -- therfore, the sipo is ready to receive more data
      else
        sipo_ready <= '1';
      end if;
    end if;
  end process vald_rdy_proc;

  SIPO_reg_proc : process (clk, rst)
  begin

    -- active low reset block
    if (rst = '0') then
      sipo_arr_r  <= (others => (others => '0'));
      counter_r   <= 0;
      msb_first_r <= '0';

    -- clk trigger  
    elsif rising_edge(clk) then
      -- When the register is enabled
      if (enb = '1') then

        -----------------------------------
        -- -- read data from sender when:
        -- -- input is valid
        -- -- sipo is ready to recieve
        -- Data is only captured from input when the sender has valid data
        -- and the sipo is ready to receive the data. sipo is ready
        -- to receive when the counter is at max value
        -----------------------------------
        if valid_i = '1' and sipo_ready = '1' then
          -- increment counter if sipo has at least one data register empty
          -- as long as sipo counter is less that max value, data can be 
          -- received
          if (msb_first_r = '0') then
            sipo_arr_r(counter_r) <= data_i;
            if (counter_r < counter_max_value) then
              counter_r <= counter_r + 1;
            end if;
          else
            if (counter_r < counter_max_value) then
              sipo_arr_r(counter_max_value-1-counter_r) <= data_i;
              counter_r                               <= counter_r + 1;
            else
              sipo_arr_r(counter_max_value-counter_r) <= data_i;
            end if;
          end if;


        end if;
        -----------------------------------
        -- invalidate data when :
        -- -- output is valid
        -- -- receiver is ready to recieve
        -- When the data inside the sipo is valid, and the receiver is ready,
        -- the receiver captures the data on the output of the sipo. This
        -- means that the data inside the sipo is no longer valid and new
        -- data can be ready into the sipo data registers from the sender
        -- the sipo counter is reset to srart receiving new data.
        -----------------------------------
        if sipo_valid = '1' and ready_i = '1' then
          counter_r <= 0;
        end if;


        -- Clear port is only effective when the register is enabled.
        if (clr = '1') then
          sipo_arr_r  <= (others => (others => '0'));
          counter_r   <= 0;
          msb_first_r <= msb_first_i;

        end if;
      end if;
    end if;
  end process SIPO_reg_proc;


  valid_o <= sipo_valid;
  ready_o <= sipo_ready;

  -- generate output data by concatenating the data inside the register
  gen_output_loop : for i in 0 to n_words_g-1 generate
    data_o(i * w_word_g + w_word_g -1 downto i * w_word_g) <= sipo_arr_r(i);
  end generate gen_output_loop;

end Behavioral;
