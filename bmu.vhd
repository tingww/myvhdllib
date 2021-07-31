--Branch metric unit
library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
library work;
    use work.conv_dec_pack.all;

entity bmu is
    port (
        d_in : in std_logic_vector(generator_num-1 downto 0) ;
        branch_metrics : out b_m_rec
    ) ;
end bmu ; 

architecture rtl of bmu is
begin
    bm_gen: for i in branch_metrics.branch_out0'range generate
        branch_metrics.branch_out0(i) <= state_table.out0(i) xor d_in;
        branch_metrics.branch_out1(i) <= state_table.out1(i) xor d_in;
    end generate bm_gen;
end architecture ;