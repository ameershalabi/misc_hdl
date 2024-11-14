--------------------------------------------------------------------------------
-- Title       : UART receiver
-- Project     : hdl_comm (misc_hdl)
--------------------------------------------------------------------------------
-- File        : uart_rx.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : User Company Name
-- Created     : Thu Mar  7 11:26:13 2024
-- Last update : Thu Nov 14 17:16:30 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Description: 
--------------------------------------------------------------------------------
-- Revisions: 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

entity uart_rx is
  generic (
    target_clk_freq_g : integer := 50000000; -- 50MHz
    baud_rate_g       : integer := 9600;
    sample_period_g   : integer := 400 -- period when Rx is sampled during states
  );
  port (
    clk    : in std_logic; -- clock pin
    n_arst : in std_logic; -- active low rest pin

    rx           : in  std_logic;
    parity_err_o : out std_logic;
    busy_o       : out std_logic;
    received_o   : out std_logic;
    d_rx_o       : out std_logic_vector(7 downto 0)

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

  -- data register
  signal d_shft_r : std_logic_vector(7 downto 0);
  signal d_out_r  : std_logic_vector(7 downto 0);

  -- data bit register
  signal rx_bit_r : std_logic;

  -- parity bit register
  signal parity_bit_r : std_logic;

  -- counter for bit period
  signal baud_counter_r : integer range 0 to bit_period_c-1;

  -- data counter
  signal data_counter_r : integer range 0 to 7;

  -- parity bit
  signal parity_r : std_logic;

  -- trigger receving data when Rx gets start bit
  signal start_data_rx_r : std_logic;

  -- indicate the rx sample range
  signal rx_sample_range : std_logic;
begin

  -- indicate if the current baud counter is within the rx sample range
  rx_sample_range <= '1' when
    baud_counter_r > rx_low_sample_point_c and
    baud_counter_r < rx_high_sample_point_c
  else '0';

  rx_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      rx_state_r      <= idle;
      d_shft_r        <= (others => '0');
      d_out_r         <= (others => '0');
      baud_counter_r  <= 0;
      data_counter_r  <= 0;
      parity_r        <= '0';
      start_data_rx_r <= '0';
      rx_bit_r        <= '0';
      parity_bit_r    <= '0';
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
          if (rx = '0') then
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
            -- check during rx smaple range if rx is still start bit
            if rx_sample_range = '1' then
              if rx = '0' then
                -- indicate that data is being sent
                start_data_rx_r <= '1';
              else
                start_data_rx_r <= '0';
              end if;
            end if;
          else
            if start_data_rx_r = '1' then
              baud_counter_r  <= 0;
              rx_state_r      <= rx_data;
              start_data_rx_r <= '0';
            end if;
          end if;

        -- DATA STATE:
        -- sample rx during the Rx sample range
        -- once baud counter is done, shift the Rx bit to data register
        -- calculate parity
        -- repeat until bit counter is at max
        -- go to stop state
        when rx_data =>
          busy_o       <= '1';
          parity_err_o <= '0';
          received_o   <= '0';
          -- start the baud counter for the data bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- get the bit during rx sampling range
            if rx_sample_range = '1' then
              rx_bit_r <= rx;
            end if;
          else
            baud_counter_r <= 0;
            -- shift data into output shift register
            d_shft_r <= rx_bit_r & d_shft_r(7 downto 1);
            -- check data counter
            if data_counter_r < 7 then
              -- if still data not sent, update data counter
              data_counter_r <= data_counter_r + 1;
              -- genrate parity of sent bit
              parity_r <= parity_r xor rx_bit_r;
            else
              -- if done, reset data counter
              data_counter_r <= 0;
              -- go to stop state
              rx_state_r <= rx_parity;
            end if;
          end if;
        -- PARITY STATE
        -- sample rx during the Rx sample range for parity bit
        -- store the parity bit to parity register
        -- go to stop state
        when rx_parity =>
          busy_o       <= '1';
          parity_err_o <= '0';
          received_o   <= '0';
          -- start the baud counter for the data bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- get the bit during rx sampling range
            if rx_sample_range = '1' then
              parity_bit_r <= rx;
            end if;
          else
            baud_counter_r <= 0;
            rx_state_r     <= stop_rx;

          end if;
        when stop_rx =>
          busy_o     <= '1';
          received_o <= '1';
          -- start the baud counter for the data bit
          if baud_counter_r < bit_period_c-1 then
            baud_counter_r <= baud_counter_r + 1;
            -- get the bit during rx sampling range
            if rx_sample_range = '1' then
              if rx = '1' then
                -- indicate that data is being sent
                received_o <= '1';
                d_out_r    <= d_shft_r;

              else
                received_o <= '0';
              end if;
            end if;
          else
            baud_counter_r <= 0;
            rx_state_r     <= idle;

          end if;
      end case;
    end if;
    d_rx_o <= d_out_r;
  end process rx_proc;

end architecture arch;