--------------------------------------------------------------------------------
-- Title       : UART transmitter
-- Project     : hdl_comm (misc_hdl)
--------------------------------------------------------------------------------
-- File        : uart_tx.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Wed Mar  6 12:55:38 2024
-- Last update : Fri Nov 15 15:23:58 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: UART Tx block. 1 stop bit, 8 data bits, 1 parity bit, 1 stop bit
--            : Data is sent LSB first
--------------------------------------------------------------------------------
-- Revisions: 
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_tx is
  generic (
    target_clk_freq_g : integer := 50000000; -- 50MHz
    baud_rate_g       : integer := 9600
  );
  port (
    clk    : in std_logic; -- clock pin
    n_arst : in std_logic; -- active low rest pin

    -- transmit interface
    tx_start_i : in  std_logic;                    -- start transmitting 8 bits of data
    data_i     : in  std_logic_vector(7 downto 0); -- 8 bit data
    busy_o     : out std_logic;                    -- busy flag
    tx_o       : out std_logic                     -- output transmission

  );
end entity uart_tx;

architecture arch of uart_tx is

  -- calculate the period per bit (clk freq over baud rate)
  constant bit_period_c : integer := target_clk_freq_g/baud_rate_g;

  -- create states of the Tx FSM
  type tx_state is (idle, start_tx, tx_data, tx_parity, stop_tx);
  signal tx_state_r : tx_state;

  -- data register
  signal tx_data_shft_r : std_logic_vector(7 downto 0);

  -- counter for bit period
  signal baud_counter_r : integer range 0 to bit_period_c-1;

  -- data counter
  signal data_counter_r : integer range 0 to 7;

  -- parity bit
  signal tx_data_parity_r : std_logic;

begin

  tx_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      tx_state_r       <= idle;
      tx_data_shft_r   <= (others => '0');
      baud_counter_r   <= 0;
      data_counter_r   <= 0;
      tx_data_parity_r <= '0';
    elsif rising_edge(clk) then
      case tx_state_r is

        -- IDEL STATE:
        -- Hold the Tx pin high to indicate nothing on Tx line
        -- go to start state when tx_start_i is high
        when idle =>

          tx_o   <= '1'; -- Nothing on transmission line, Tx pin always high
          busy_o <= '0'; -- Tx is not busy

          -- if transmission is started
          if (tx_start_i = '1') then
            tx_state_r     <= start_tx; -- set start state
            tx_data_shft_r <= data_i;   -- get data from input
          end if;

        -- START STATE:
        -- Initiate the Tx, pull Tx pin high, send start bit for
        -- baud period
        -- go to sending data state
        when start_tx =>

          tx_o   <= '0'; -- send start bit by puling Tx pin down
          busy_o <= '1'; -- flag busy block

          -- start the baud counter for the start bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
          else
            -- reset baud counter 
            baud_counter_r <= 0;
            -- start sending data
            tx_state_r <= tx_data;

          end if;

        -- SEND DATA STATE:
        -- Send the LSB of the shift rigster
        -- wait for baud period
        -- shift data, calculate parity
        -- send next bit
        -- repeat until bit counter is at max
        -- go to stop state
        when tx_data =>

          tx_o   <= tx_data_shft_r(0); -- send LSB of data shift register
          busy_o <= '1';               -- block is still busy

          -- start the baud counter for the current data
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
          else
            -- reset baud counter for next bit or for stop state
            baud_counter_r <= 0;

            -- check data counter
            if data_counter_r < 7 then
              -- if still data not sent, update data counter
              data_counter_r <= data_counter_r + 1;
              -- shift data
              tx_data_shft_r <= '0' & tx_data_shft_r(7 downto 1);
              -- genrate parity of sent bit
              tx_data_parity_r <= tx_data_parity_r xor tx_data_shft_r(0);
            else
              -- if done, reset data counter
              data_counter_r <= 0;
              -- go to stop state
              tx_state_r <= tx_parity;
            end if;
          end if;

        -- SEND PARITY STATE
        -- Set Tx line to value of parity
        when tx_parity =>
          tx_o   <= tx_data_parity_r; -- send parity bit
          busy_o <= '1';              -- flag busy block

          -- start the baud counter for the stop bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
          else
            -- reset baud counter for next state
            baud_counter_r <= 0;
            -- set state to idel
            tx_state_r <= idle;
            -- reset parity for next data Tx
            tx_data_parity_r <= '0';
          end if;

        when stop_tx =>
          tx_o   <= '1'; -- send stop bit by puling Tx pin up
          busy_o <= '1'; -- flag busy block

          -- start the baud counter for the stop bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
          else
            -- reset baud counter for next state
            baud_counter_r <= 0;
            -- set state to idel
            tx_state_r <= idle;

          end if;
      end case;
    end if;
  end process tx_proc;

end architecture arch;