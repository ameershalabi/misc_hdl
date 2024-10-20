--------------------------------------------------------------------------------
-- Title       : 32 to 5 Encoder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : OR_ARRAY_32x5_Enc.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 14 00:00:00 2020
-- Last update : Fri Oct 30 09:28:49 2020
-- Platform    : -
-- Standard    : <VHDL-2008 | VHDL-2002 | VHDL-1993 | VHDL-1987>
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description: A 32 to 5 Encoder using a balanced OR tree.
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all; -- for addition & counting
use ieee.numeric_std.all;        -- for type conversions
use ieee.math_real.all;          -- for the ceiling and log constant calculation functions


entity OR_ARRAY_32x5_Enc is
	port (
		in_32 : in  std_logic_vector (31 downto 0);
		out_5 : out std_logic_vector (4 downto 0)
	);
end OR_ARRAY_32x5_Enc;

--53 OR gates required

architecture OR_ARRAY_32x5_Enc_arch of OR_ARRAY_32x5_Enc is
	signal input_sig  : std_logic_vector (31 downto 0); -- signal for input	
	signal output_sig : std_logic_vector (4 downto 0);     -- signal for output

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_31_30, OR_31_29, OR_29_28 : std_logic;
	signal OR_27_26, OR_27_25, OR_25_24 : std_logic;
	signal OR_23_22, OR_23_21, OR_21_20 : std_logic;
	signal OR_19_18, OR_19_17, OR_17_16 : std_logic;
	signal OR_15_14, OR_15_13, OR_13_12 : std_logic;
	signal OR_11_10, OR_11_09, OR_09_08 : std_logic;
	signal OR_07_06, OR_07_05, OR_05_04 : std_logic;
	signal OR_03_02, OR_03_01           : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_31_30_29_28, OR_27_26_25_24, OR_23_22_21_20, OR_19_18_17_16 : std_logic;
	signal OR_15_14_13_12, OR_11_10_09_08, OR_07_06_05_04, OR_31_30_27_26 : std_logic;
	signal OR_23_22_19_18, OR_15_14_11_10, OR_07_06_03_02, OR_31_29_27_25 : std_logic;
	signal OR_23_21_19_17, OR_15_13_11_09, OR_07_05_03_01                 : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_4_1, OR_4_2 : std_logic;
	signal OR_3_1, OR_3_2 : std_logic;
	signal OR_2_1, OR_2_2 : std_logic;
	signal OR_1_1, OR_1_2 : std_logic;
	signal OR_0_1, OR_0_2 : std_logic;

begin

	input_assign_proc : process (in_32)
	begin
		input_sig <= (others => '0');
		input_sig <= in_32;
	end process input_assign_proc;

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_31_30 <= input_sig(31) or input_sig(30); OR_27_26 <= input_sig(27) or input_sig(26); OR_23_22 <= input_sig(23) or input_sig(22);
	OR_31_29 <= input_sig(31) or input_sig(29); OR_27_25 <= input_sig(27) or input_sig(25); OR_23_21 <= input_sig(23) or input_sig(21);
	OR_29_28 <= input_sig(29) or input_sig(28); OR_25_24 <= input_sig(25) or input_sig(24); OR_21_20 <= input_sig(21) or input_sig(20);

	OR_19_18 <= input_sig(19) or input_sig(18); OR_15_14 <= input_sig(15) or input_sig(14); OR_11_10 <= input_sig(11) or input_sig(10);
	OR_19_17 <= input_sig(19) or input_sig(17); OR_15_13 <= input_sig(15) or input_sig(13); OR_11_09 <= input_sig(11) or input_sig(9);
	OR_17_16 <= input_sig(17) or input_sig(16); OR_13_12 <= input_sig(13) or input_sig(12); OR_09_08 <= input_sig(9) or input_sig(8);

	OR_07_06 <= input_sig(7) or input_sig(6); OR_03_02 <= input_sig(3) or input_sig(2);
	OR_07_05 <= input_sig(7) or input_sig(5); OR_03_01 <= input_sig(3) or input_sig(1);
	OR_05_04 <= input_sig(5) or input_sig(4);
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_31_30_29_28 <= OR_31_30 or OR_29_28; OR_27_26_25_24 <= OR_27_26 or OR_25_24; OR_23_22_21_20 <= OR_23_22 or OR_21_20;
	OR_19_18_17_16 <= OR_19_18 or OR_17_16; OR_31_30_27_26 <= OR_31_30 or OR_27_26; OR_31_29_27_25 <= OR_31_29 or OR_27_25;
	OR_15_14_13_12 <= OR_15_14 or OR_13_12; OR_11_10_09_08 <= OR_11_10 or OR_09_08; OR_07_06_05_04 <= OR_07_06 or OR_05_04;
	OR_23_22_19_18 <= OR_23_22 or OR_19_18; OR_15_14_11_10 <= OR_15_14 or OR_11_10; OR_07_06_03_02 <= OR_07_06 or OR_03_02;
	OR_23_21_19_17 <= OR_23_21 or OR_19_17; OR_15_13_11_09 <= OR_15_13 or OR_11_09; OR_07_05_03_01 <= OR_07_05 or OR_03_01;
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_4_1 <= OR_31_30_29_28 or OR_27_26_25_24; OR_4_2 <= OR_23_22_21_20 or OR_19_18_17_16;
	OR_3_1 <= OR_31_30_29_28 or OR_27_26_25_24; OR_3_2 <= OR_15_14_13_12 or OR_11_10_09_08;
	OR_2_1 <= OR_31_30_29_28 or OR_23_22_21_20; OR_2_2 <= OR_15_14_13_12 or OR_07_06_05_04;
	OR_1_1 <= OR_31_30_27_26 or OR_23_22_19_18; OR_1_2 <= OR_15_14_11_10 or OR_07_06_03_02;
	OR_0_1 <= OR_31_29_27_25 or OR_23_21_19_17; OR_0_2 <= OR_15_13_11_09 or OR_07_05_03_01;

	-----------------------------------------------------------------------------------------------------------------------------------

	output_sig(4) <= OR_4_1 or OR_4_2;
	output_sig(3) <= OR_3_1 or OR_3_2;
	output_sig(2) <= OR_2_1 or OR_2_2;
	output_sig(1) <= OR_1_1 or OR_1_2;
	output_sig(0) <= OR_0_1 or OR_0_2;

	out_5 <= output_sig;

end OR_ARRAY_32x5_Enc_arch;
