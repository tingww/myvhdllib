--Add, compare, select unit
library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
library work;
    use work.conv_dec_pack.all;

entity acsu is
    port (
        clk,rst,en : in std_logic;  
        branch_metrics : in b_m_rec;
        path_matrix_entry : out pme_arr;
        acm : out acm_arr
    ) ;
end acsu ; 

architecture rtl of acsu is
    signal acm_nxt : acm_arr;
    signal path_matrix_entry_nxt : pme_arr;
begin
    seq : process( clk,rst ) 
    begin
        if rst=rstval then
            for i in acm'range loop
                acm(i) <= to_unsigned(0, acm(0)'length);
            end loop;
            for i in path_matrix_entry'range loop
                path_matrix_entry(i) <= to_unsigned(0, path_matrix_entry(0)'length);
            end loop;
        elsif rising_edge(clk) and en='1' then
            for i in acm'range loop
                acm(i) <= acm_nxt(i);
            end loop;
            for i in path_matrix_entry'range loop
                path_matrix_entry(i) <= path_matrix_entry_nxt(i);
            end loop;
        end if ;
    end process ; -- seq

    add_compare_select_pro : process( all )
        variable bm0,bm0_total,bm1,bm1_total : unsigned(accum_cost_metric_bits-1 downto 0);
    begin
        for i in 0 to state_num-1 loop
            bm0 := to_unsigned(hamming_weight(branch_metrics.branch_out0(i)), bm0'length);
            bm1 := to_unsigned(hamming_weight(branch_metrics.branch_out1(i)), bm1'length);
            bm0_total := bm0+acm(state_table.prev_state0(i));   --Add both branch metrics with previous accumulative metrics according to predefined state table
            bm1_total := bm1+acm(state_table.prev_state1(i));
            if bm0_total <= bm1_total then        --Compare
                acm_nxt(i) <= bm0_total;          --Select
                path_matrix_entry_nxt(i) <= to_unsigned(state_table.prev_state0(i),path_matrix_entry(0)'length);
            else 
                acm_nxt(i) <= bm1_total;
                path_matrix_entry_nxt(i) <= to_unsigned(state_table.prev_state1(i),path_matrix_entry(0)'length);
            end if;
        end loop;
    end process ; -- add_compare_select_pro
end architecture ;