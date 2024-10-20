--------------------------------------------------------------------------------
-- Title       : 16 to 4 Encoder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : OR_ARRAY_16x4_Enc.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 29 17:47:46 2020
-- Last update : Fri Oct 30 12:50:32 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description: A 16 to 4 Encoder using a balanced OR tree.
--------------------------------------------------------------------------------


library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions


entity OR_ARRAY_16x4_Enc is
	port (
		in_16 : in  std_logic_vector (15 downto 0);
		out_4 : out std_logic_vector (3 downto 0)
	);
end OR_ARRAY_16x4_Enc;

--53 OR gates required

architecture OR_ARRAY_16x4_Enc_arch of OR_ARRAY_16x4_Enc is
	signal input_sig  : std_logic_vector (15 downto 0); -- signal for input	
	signal output_sig : std_logic_vector (3 downto 0);     -- signal for output

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_15_14, OR_15_13, OR_13_12 : std_logic;
	signal OR_11_10, OR_11_09, OR_09_08 : std_logic;
	signal OR_07_06, OR_07_05, OR_05_04 : std_logic;
	signal OR_03_02, OR_03_01           : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_15_14_13_12, OR_11_10_09_08, OR_07_06_05_04 : std_logic;
	signal OR_15_14_11_10, OR_07_06_03_02                 : std_logic;
	signal OR_15_13_11_09, OR_07_05_03_01                 : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_3 : std_logic;
	signal OR_2 : std_logic;
	signal OR_1 : std_logic;
	signal OR_0 : std_logic;

begin

	input_assign_proc : process (in_16)
	begin
		input_sig <= (others => '0');
		input_sig <= in_16;
	end process input_assign_proc;

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------

	OR_15_14 <= input_sig(15) or input_sig(14); OR_11_10 <= input_sig(11) or input_sig(10);
	OR_15_13 <= input_sig(15) or input_sig(13); OR_11_09 <= input_sig(11) or input_sig(9);
	OR_13_12 <= input_sig(13) or input_sig(12); OR_09_08 <= input_sig(9) or input_sig(8);

	OR_07_06 <= input_sig(7) or input_sig(6); OR_03_02 <= input_sig(3) or input_sig(2);
	OR_07_05 <= input_sig(7) or input_sig(5); OR_03_01 <= input_sig(3) or input_sig(1);
	OR_05_04 <= input_sig(5) or input_sig(4);
	-----------------------------------------------------------------------------------------------------------------------------------


	OR_15_14_13_12 <= OR_15_14 or OR_13_12; OR_11_10_09_08 <= OR_11_10 or OR_09_08; OR_07_06_05_04 <= OR_07_06 or OR_05_04;
	OR_15_14_11_10 <= OR_15_14 or OR_11_10; OR_07_06_03_02 <= OR_07_06 or OR_03_02;
	OR_15_13_11_09 <= OR_15_13 or OR_11_09; OR_07_05_03_01 <= OR_07_05 or OR_03_01;
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_3 <= OR_15_14_13_12 or OR_11_10_09_08;
	OR_2 <= OR_15_14_13_12 or OR_07_06_05_04;
	OR_1 <= OR_15_14_11_10 or OR_07_06_03_02;
	OR_0 <= OR_15_13_11_09 or OR_07_05_03_01;

	-----------------------------------------------------------------------------------------------------------------------------------

	output_sig(3) <= OR_3;
	output_sig(2) <= OR_2;
	output_sig(1) <= OR_1;
	output_sig(0) <= OR_0;

	out_4 <= output_sig;

end OR_ARRAY_16x4_Enc_arch;
