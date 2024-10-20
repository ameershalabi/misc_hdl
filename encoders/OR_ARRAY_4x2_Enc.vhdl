--------------------------------------------------------------------------------
-- Title       : 16 to 4 Encoder
-- Project     : amshal_misc package
--------------------------------------------------------------------------------
-- File        : OR_ARRAY_4x2_Enc.vhdl
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Thu Oct 29 17:47:46 2020
-- Last update : Fri Oct 30 09:28:29 2020
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


entity OR_ARRAY_4x2_Enc is
	port (
		in_4  : in  std_logic_vector (3 downto 0);
		out_2 : out std_logic_vector (1 downto 0)
	);
end OR_ARRAY_4x2_Enc;

--53 OR gates required

architecture OR_ARRAY_4x2_Enc_arch of OR_ARRAY_4x2_Enc is
	signal input_sig  : std_logic_vector (3 downto 0); -- signal for input	
	signal output_sig : std_logic_vector (1 downto 0);    -- signal for output

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------
	signal OR_03_02, OR_03_01           : std_logic;
	-----------------------------------------------------------------------------------------------------------------------------------
begin

	input_assign_proc : process (in_4)
	begin
		input_sig <= (others => '0');
		input_sig <= in_4;
	end process input_assign_proc;

	-- lowest level of the trees
	-----------------------------------------------------------------------------------------------------------------------------------
	OR_03_02 <= input_sig(3) or input_sig(2);
	OR_03_01 <= input_sig(3) or input_sig(1);
	-----------------------------------------------------------------------------------------------------------------------------------
	output_sig(1) <= OR_03_02;
	output_sig(0) <= OR_03_01;

	out_2 <= output_sig;

end OR_ARRAY_4x2_Enc_arch;
