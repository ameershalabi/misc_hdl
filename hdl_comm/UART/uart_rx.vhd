--------------------------------------------------------------------------------
-- Title       : UART receiver
-- Project     : hdl_comm (misc_hdl)
--------------------------------------------------------------------------------
-- File        : uart_rx.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : 
-- Created     : Thu Mar  7 11:26:13 2024
-- Last update : Fri Nov 15 15:23:47 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: UART Rx block. 1 stop bit, 8 data bits, 1 parity bit, 1 stop bit
--            : Data is recieved LSB first
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity uart_rx is
  generic (
    target_clk_freq_g : integer := 50000000; -- 50MHz
    baud_rate_g       : integer := 9600;
    sample_period_g   : integer := 400 -- period when Rx is sampled during states
  );
  port (
    clk    : in std_logic; -- clock pin
    n_arst : in std_logic; -- active low rest pin

    rx_i           : in  std_logic;                   -- Rx line  
    parity_err_o : out std_logic;                   -- parity check
    busy_o       : out std_logic;                   -- busy flag
    received_o   : out std_logic;                   -- data was recieved
    d_rx_o       : out std_logic_vector(7 downto 0) -- recieved data

  );
end entity uart_rx;

architecture arch of uart_rx is

  -- calculate the period per bit (clk freq over baud rate)
  constant bit_period_c      : integer := target_clk_freq_g/baud_rate_g;
  constant half_bit_period_c : integer := bit_period_c/2;

  -- bounds of Rx sample range
  constant rx_low_sample_point_c  : integer := half_bit_period_c - sample_period_g/2;
  constant rx_high_sample_point_c : integer := half_bit_period_c + sample_period_g/2;

  -- create states of the Rx FSM
  type rx_state is (idle, start_rx, rx_data, rx_parity, stop_rx);
  signal rx_state_r : rx_state;

  -- data registers
  signal rx_data_shft_r : std_logic_vector(7 downto 0);
  signal rx_data_out_r  : std_logic_vector(7 downto 0);
  signal rx_data_bit_r  : std_logic;

  -- parity bit registers
  signal parity_rx_sample_r : std_logic;
  signal rx_data_parity_r   : std_logic;

  -- counter for bit period
  signal baud_counter_r : integer range 0 to bit_period_c-1;

  -- data counter
  signal data_counter_r : integer range 0 to 7;

  -- trigger receving data when Rx gets start bit
  signal start_data_rx_r : std_logic;

  -- trigger stopping data when Rx gets stop bit
  signal stop_data_rx_r : std_logic;

  -- indicate baud counter within bit Rx sample range
  signal rx_sample_range : std_logic;

begin

  -- indicate if the current baud counter is within the Rx sample range
  rx_sample_range <= '1' when
    baud_counter_r > rx_low_sample_point_c and
    baud_counter_r < rx_high_sample_point_c
  else '0';

  rx_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      rx_state_r         <= idle;
      rx_data_shft_r     <= (others => '0');
      rx_data_out_r      <= (others => '0');
      baud_counter_r     <= 0;
      data_counter_r     <= 0;
      rx_data_parity_r   <= '0';
      start_data_rx_r    <= '0';
      stop_data_rx_r     <= '0';
      rx_data_bit_r      <= '0';
      parity_rx_sample_r <= '0';
    elsif rising_edge(clk) then
      case rx_state_r is
        -- IDEL STATE:
        -- Wait for Rx line to flip from high to low
        -- go to start state
        when idle =>
          busy_o       <= '0';
          parity_err_o <= '0';
          received_o   <= '0';
          -- if start bit detected, sample Rx at half baud period
          if (rx_i = '0') then
            rx_state_r <= start_rx;
          end if;

        -- START STATE:
        -- Check if start bit is still there after half
        -- baud period
        -- go to receiving data state
        when start_rx =>
          busy_o       <= '1';
          parity_err_o <= '0';
          received_o   <= '0';
          -- start the baud counter for the start bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- check during Rx smaple range if Rx is still start bit
            if rx_sample_range = '1' then
              if rx_i = '0' then
                -- indicate that data is being sent
                start_data_rx_r <= '1';
              else
                -- if no data, then go back to idle
                start_data_rx_r <= '0';
              end if;
            end if;
          else
            -- if data being sent
            -- reset counter, start data state
            if start_data_rx_r = '1' then
              baud_counter_r  <= 0;
              rx_state_r      <= rx_data;
              start_data_rx_r <= '0';
            else
              -- if no data being sent
              -- reset counter, go to idle state
              baud_counter_r <= 0;
              rx_state_r     <= idle;
            end if;
          end if;

        -- DATA STATE:
        -- sample Rx pin during the Rx sample range
        -- once baud counter is done, shift the Rx bit to data register
        -- calculate parity
        -- repeat until bit counter is at max
        -- go to parity state
        when rx_data =>
          busy_o       <= '1';
          parity_err_o <= '0';
          received_o   <= '0';
          -- start the baud counter for the data bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- get the bit during Rx sampling range
            if rx_sample_range = '1' then
              rx_data_bit_r <= rx_i;
            end if;
          else
            baud_counter_r <= 0;
            -- shift data into output shift register
            rx_data_shft_r <= rx_data_bit_r & rx_data_shft_r(7 downto 1);
            -- check data counter
            if data_counter_r < 7 then
              -- if still data not sent, update data counter
              data_counter_r <= data_counter_r + 1;
              -- genrate parity of sent bit
              rx_data_parity_r <= rx_data_parity_r xor rx_data_bit_r;
            else
              -- if done, reset data counter
              data_counter_r <= 0;
              -- go to stop state
              rx_state_r <= rx_parity;
            end if;
          end if;

        -- PARITY STATE
        -- sample Rx pin during the Rx sample range for parity bit
        -- store the parity bit to parity register
        -- go to stop state
        when rx_parity =>
          busy_o       <= '1';
          parity_err_o <= '0';
          received_o   <= '0';
          -- start the baud counter for the data bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- get the parity during Rx sampling range
            if rx_sample_range = '1' then
              parity_rx_sample_r <= rx_i;
            end if;
          else
            baud_counter_r <= 0;
            rx_state_r     <= stop_rx;
          end if;

        -- STOP STATE
        -- sample Rx pin during the Rx sample range for stop bit
        -- if stop bit is high, indicate data was recieved
        -- the recieved signal is held for single clock cycle 
        -- during next idle state, data must be captured within
        -- that cycle
        -- go to idle state
        when stop_rx =>
          busy_o <= '1';
          -- start the baud counter for the data bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- get the bit during Rx sampling range
            if rx_sample_range = '1' then
              stop_data_rx_r <= rx_i;
            end if;
          else
            baud_counter_r <= 0;
            received_o     <= stop_data_rx_r;
            rx_data_out_r  <= rx_data_shft_r;
            rx_state_r     <= idle;

          end if;
      end case;
    end if;
    d_rx_o <= rx_data_out_r;
  end process rx_proc;

end architecture arch;