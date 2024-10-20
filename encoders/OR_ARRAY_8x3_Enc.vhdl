--------------------------------------------------------------------------------
-- Title       : 16 to 4 Encoder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : OR_ARRAY_8x3_Enc.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 29 17:47:46 2020
-- Last update : Fri Oct 30 12:51:33 2020
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


entity OR_ARRAY_8x3_Enc is
	port (
		in_8  : in  std_logic_vector (7 downto 0);
		out_3 : out std_logic_vector (2 downto 0)
	);
end OR_ARRAY_8x3_Enc;

--53 OR gates required

architecture OR_ARRAY_8x3_Enc_arch of OR_ARRAY_8x3_Enc is
	signal input_sig  : std_logic_vector (7 downto 0); -- signal for input	
	signal output_sig : std_logic_vector (2 downto 0);    -- signal for output

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------

	signal OR_07_06, OR_07_05, OR_05_04 : std_logic;
	signal OR_03_02, OR_03_01           : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_07_06_05_04 : std_logic;
	signal OR_07_06_03_02 : std_logic;
	signal OR_07_05_03_01 : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_2 : std_logic;
	signal OR_1 : std_logic;
	signal OR_0 : std_logic;

begin

	input_assign_proc : process (in_8)
	begin
		input_sig <= (others => '0');
		input_sig <= in_8;
	end process input_assign_proc;

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_07_06 <= input_sig(7) or input_sig(6); OR_03_02 <= input_sig(3) or input_sig(2);
	OR_07_05 <= input_sig(7) or input_sig(5); OR_03_01 <= input_sig(3) or input_sig(1);
	OR_05_04 <= input_sig(5) or input_sig(4);
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_07_06_05_04 <= OR_07_06 or OR_05_04;
	OR_07_06_03_02 <= OR_07_06 or OR_03_02;
	OR_07_05_03_01 <= OR_07_05 or OR_03_01;
	-----------------------------------------------------------------------------------------------------------------------------------
	
	output_sig(2) <= OR_07_06_05_04;
	output_sig(1) <= OR_07_06_03_02;
	output_sig(0) <= OR_07_05_03_01;

	out_3 <= output_sig;

end OR_ARRAY_8x3_Enc_arch;
