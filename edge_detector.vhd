--------------------------------------------------------------------------------
-- Title       : Edge Detector block
-- Project     : misc_hdl
--------------------------------------------------------------------------------
-- File        : edge_detector.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Mon Jan 27 11:00:13 2020
-- Last update : Mon Oct 21 12:07:20 2024
-- Platform    : Default Part Number
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
-------------------------------------------------------------------------------
-- Description: Edge detection block for single bit signals. Output indicates
-- rising and falling edge for a single clock cycle.
--------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity edge_detector is
  port (
    clk    : in std_logic;
    n_arst : in std_logic;

    signal_i       : in  std_logic;
    rising_edge_o  : out std_logic;
    falling_edge_o : out std_logic

  );

end entity edge_detector;

architecture arch of edge_detector is

  signal detector_r   : std_logic; -- register for signal
  signal signal_event : std_logic; -- check if signal has event

begin

  -- store value at clock event to the detector register
  detection_proc : process (clk, n_arst)
  begin
    if (n_arst = '0') then
      detector_r <= '0';
    elsif clk'event and clk = '1' then
      detector_r <= signal_i;
    end if;
  end process detection_proc;

  -- check if an event occurs on the signal
  signal_event <= detector_r xor signal_i;

  -- detection of the edge depends on the values of signal_i at 
  -- time when a signal event occurs. 
  -- -- if input signal is high, then signal is at
  -- -- rising edge. 
  -- -- if input signal is low, then signal is at
  -- -- falling edge
  rising_edge_o  <= signal_event and signal_i;
  falling_edge_o <= signal_event and not signal_i;

end arch;