--------------------------------------------------------------------------------
-- Title       : Min value binary tree
-- Project     : misc_hdl
--------------------------------------------------------------------------------
-- File        : min_bin_tree.vhd
-- Author      : Ameer Shalabi <ameershalabi94@gmail.com>
-- Company     : -
-- Created     : Tue Oct 16 17:24:09 2024
-- Last update : Sun Oct 20 17:09:08 2024
-- Platform    : -
-- Standard    : VHDL-2008
--------------------------------------------------------------------------------
-- Copyright (c) 2024 User Company Name
-------------------------------------------------------------------------------
-- Description: This block outputs the minimum value of length L from vector of 
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

entity min_bin_tree is
  generic (
    w_val_g : integer := 16; -- width of input vector, prefereably power of 2
    n_val_g : integer := 32  -- number of values in input vector 
  );
  port (
    clk    : in std_logic;
    n_arst : in std_logic;

    vector_i  : in  std_logic_vector (w_val_g*n_val_g-1 downto 0);
    min_val_o : out std_logic_vector (w_val_g-1 downto 0)

  );

end entity min_bin_tree;

architecture arch of min_bin_tree is

  -- get tree depth
  constant bin_tree_depth_c : positive := positive(ceil(log2(real(n_val_g))));

  -- generate the maximum value possible for the data
  constant max_val_c : signed(w_val_g - 1 downto 0) := to_signed(2**(w_val_g-1)-1,w_val_g);

  -- two dimintional array to specify where the comparator nodes are located
  type min_tree_arr is array (integer range bin_tree_depth_c downto 0,
      integer range 0 to n_val_g - 1) of signed(w_val_g-1 downto 0);
  signal min_tree_arr_r : min_tree_arr; -- min tree signal

begin

  min_val_p : process (clk, n_arst)
    variable n_nodes_per_level : integer range 0 to n_val_g-1;
    variable left_child      : signed(w_val_g - 1 downto 0);
    variable rigt_child      : signed(w_val_g - 1 downto 0);
  begin
    if (n_arst = '0') then
      min_tree_arr_r <= (others => (others => max_val_c));
    elsif rising_edge(clk) then
      -- get data into the min tree minimum depth
      min_depth_loop : for val in 0 to n_val_g-1 loop
        min_tree_arr_r(bin_tree_depth_c, val) <=
          signed(vector_i(val*w_val_g+w_val_g-1 downto val*w_val_g));
      end loop min_depth_loop;

      compare_level_loop : for depth_idx in bin_tree_depth_c-1 downto 0 loop
        -- get number of nodes per level
        n_nodes_per_level := 2**depth_idx;
        -- for every depth, get the right and left child of each node
        depth_idx_val_compare_loop : for idx in 0 to n_nodes_per_level-1 loop
          -- get left child
          left_child  := min_tree_arr_r(depth_idx+1, idx*2);
          
          -- get right child
          rigt_child := min_tree_arr_r(depth_idx+1, idx*2+1);
          
          -- get min of left and right children
          if left_child < rigt_child then
            min_tree_arr_r(depth_idx, idx) <= left_child;
          else
            min_tree_arr_r(depth_idx, idx) <= rigt_child;
          end if;

        end loop depth_idx_val_compare_loop;
      end loop compare_level_loop;


    end if;
  end process min_val_p;


  min_val_o <= std_logic_vector(min_tree_arr_r(0,0));

end arch;

