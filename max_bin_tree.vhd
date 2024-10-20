--------------------------------------------------------------------------------
-- Title       : Max value binary tree
-- Project     : misc_hdl
--------------------------------------------------------------------------------
-- File        : max_bin_tree.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Oct 15 13:59:57 2024
-- Last update : Sun Oct 20 17:01:58 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Copyright (c) 2024 User Company Name
-------------------------------------------------------------------------------
-- Description: This block outputs the maximum value of length L from vector of 
-- width L x N, where N is the number of values stored inside such vector
--------------------------------------------------------------------------------
-- Revisions:  Revisions and documentation are controlled by
-- the revision control system (RCS).  The RCS should be consulted
-- on revision history.
-------------------------------------------------------------------------------

library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity max_bin_tree is
  generic (
    w_val_g : integer := 16; -- width of input vector, prefereably power of 2
    n_val_g : integer := 32  -- defines what type of gate to use 
  );
  port (
    clk    : in std_logic;
    n_arst : in std_logic;

    vector_i  : in  std_logic_vector (w_val_g*n_val_g-1 downto 0);
    max_val_o : out std_logic_vector (w_val_g-1 downto 0)

  );

end entity max_bin_tree;

architecture arch of max_bin_tree is

  -- get tree depth
  constant bin_tree_depth_c : positive := positive(ceil(log2(real(n_val_g))));

  -- generate the minimum value possible for the data
  constant min_val_c : signed(w_val_g - 1 downto 0) := to_signed(-2**(w_val_g-1),w_val_g);

  -- two dimintional array to specify where the comparator nodes are located
  type max_tree_arr is array (integer range bin_tree_depth_c downto 0,
      integer range 0 to n_val_g - 1) of signed(w_val_g-1 downto 0);
  signal max_tree_arr_r : max_tree_arr; -- max tree signal

begin

  max_val_p : process (clk, n_arst)
    variable n_nodes_per_level : integer range 0 to n_val_g-1;
    variable left_child      : signed(w_val_g - 1 downto 0);
    variable rigt_child      : signed(w_val_g - 1 downto 0);
  begin
    if (n_arst = '0') then
      max_tree_arr_r <= (others => (others => min_val_c));
    elsif rising_edge(clk) then
      -- get data into the max tree maximum depth
      max_depth_loop : for val in 0 to n_val_g-1 loop
        max_tree_arr_r(bin_tree_depth_c, val) <=
          signed(vector_i(val*w_val_g+w_val_g-1 downto val*w_val_g));
      end loop max_depth_loop;

      compare_level_loop : for depth_idx in bin_tree_depth_c-1 downto 0 loop
        -- get number of nodes per level
        n_nodes_per_level := 2**depth_idx;
        -- for every depth, get the right and left chiold of each node
        depth_idx_val_compare_loop : for idx in 0 to n_nodes_per_level-1 loop
          -- get left child
          left_child  := max_tree_arr_r(depth_idx+1, idx*2);
          
          -- get right child
          rigt_child := max_tree_arr_r(depth_idx+1, idx*2+1);
          
          -- get max of left and right children
          if left_child > rigt_child then
            max_tree_arr_r(depth_idx, idx) <= left_child;
          else
            max_tree_arr_r(depth_idx, idx) <= rigt_child;
          end if;

        end loop depth_idx_val_compare_loop;
      end loop compare_level_loop;


    end if;
  end process max_val_p;


  max_val_o <= std_logic_vector(max_tree_arr_r(0,0));

end arch;

