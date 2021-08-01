--Trace back unit, trivial design no pipeline
library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
    use ieee.math_real.all;

library work ;
    use work.conv_dec_pack.all;

entity tbu is
    port (
        clk,rst : in std_logic;
        path_matrix_entry : in pme_arr;
        acm : in acm_arr;
        d_out : out std_logic;
        valid_out : out std_logic;
        start : in std_logic;
        terminate : in std_logic    --assert when path matrix entry is the last one
    ) ;
end tbu ; 

architecture rtl of tbu is
    constant counter_size : integer := integer(ceil(log2(real(constrained_length))));
    type path_matrix_type is array (0 to constrained_length-1) of pme_arr;
    type state_type is (idle,ini,normal,term);
    signal state,state_nxt : state_type;
    signal path_matrix : path_matrix_type;
    signal counter,counter_nxt,counter_term,counter_term_nxt : unsigned(counter_size-1 downto 0) ;
    signal d_out_nxt, valid_out_nxt : std_logic;
    
begin
    seq : process( clk,rst )
    begin
        if rst=rstval then
            d_out <= '0';
            valid_out <= '0';
            state <= idle;
            counter <= to_unsigned(0, counter'length);
            counter_term <= to_unsigned(0, counter'length);
        elsif rising_edge(clk) then
            d_out <= d_out_nxt;
            valid_out <= valid_out_nxt;
            state <= state_nxt;
            counter <= counter_nxt;
            counter_term <= counter_term_nxt;
        end if ;
    end process ; -- seq

    state_transition : process( all )
    begin
        case( state ) is
            when idle =>
                if start='1' then
                    state_nxt <= ini;
                else
                    state_nxt <= state;
                end if ;
            when ini => 
                if counter=to_unsigned(constrained_length-1, counter'length) then
                    state_nxt <= normal;
                else
                    state_nxt <= state;
                end if ;
            when normal => 
                if terminate='1' then
                    state_nxt <= term;
                else
                    state_nxt <= state;
                end if ;
            when term =>
                if counter_term=counter then
                    state_nxt <= idle;
                else
                    state_nxt <= state;
                end if ;        
        end case ;
    end process ; -- state_transition

    counter0_pro : process( all )
    begin
        if state=idle then
            counter_nxt <= to_unsigned(0, counter'length);
        elsif state_nxt/=term then
            counter_nxt <= counter + to_unsigned(1, counter'length);
        else
            counter_nxt <= counter;
        end if ;
    end process ; -- counter0_pro

    counter_term_pro : process( all )
    begin
        if state=term then
            counter_term_nxt <= counter_term + to_unsigned(1, counter_term'length);
        else
            counter_term_nxt <= counter + to_unsigned(1, counter_term'length);  --plus 2 so the value is counter+2 when in the first cycle in termination state 
        end if ;
    end process ; -- counter1_pro

    path_matrix_pro : process( clk,rst )
    begin
        if rst=rstval then
            for j in path_matrix'range loop
                for i in path_matrix(0)'range loop
                    path_matrix(j)(i) <= to_unsigned(0, path_matrix(0)(0)'length);
                end loop;
            end loop;
        elsif rising_edge(clk) then
            if state=ini or (state=normal and terminate='0') then
                path_matrix( to_integer(counter) ) <= path_matrix_entry;
            end if ;
        end if ;
    end process ; -- path_matrix_pro

    d_out_pro : process( all )
        type pmi_type is array (0 to constrained_length+1) of integer;
        variable path_min_index : pmi_type;
        variable index_term : integer := 0;
    begin
        index_term := to_integer(counter-counter_term);

        -----------------trace back with compare-----------------------
        path_min_index(0) := argmin_acm(acm);                        --find the index of the minimum of accumulative state metrics
        path_min_index(1) := to_integer( path_matrix_entry( path_min_index(0) ) );  
        ---------------------------------------------------------------

        --trace index back to the last path entry, delay = (constrained length)*4-1-mux(2bits)
        path_min_loop : for i in 0 to constrained_length-1 loop     
            path_min_index(i+2)  := to_integer( path_matrix( to_integer(counter- to_unsigned(i, counter'length)- to_unsigned(1, counter'length)) )(path_min_index(i+1)) ) ;
        end loop ; -- path_min_loop
        
        --compare with the state table to obtain state transition input
        if state=normal then
            if path_min_index(constrained_length+1) = state_table.prev_state0(path_min_index(constrained_length)) then --comparing the tail one
                d_out_nxt <= state_table.in0(path_min_index(constrained_length)) ;
            elsif path_min_index(constrained_length+1) = state_table.prev_state1(path_min_index(constrained_length)) then
                d_out_nxt <= state_table.in1(path_min_index(constrained_length)) ;
            else
                report "Should not be here!" severity error;            
            end if ;
        elsif state=term then       --path_min_index(constrained_length-1 ~~ 0) as counter term counts up in termination
            if path_min_index(index_term+1) = state_table.prev_state0(path_min_index(index_term)) then --comparing paths depending on the termination stages
                d_out_nxt <= state_table.in0(path_min_index(index_term)) ;
            elsif path_min_index(index_term+1) = state_table.prev_state1(path_min_index(index_term)) then
                d_out_nxt <= state_table.in1(path_min_index(index_term)) ;
            else
                report "Should not be here!" severity error;            
            end if ;
        else
            d_out_nxt <= d_out;
        end if ;

    end process ; -- d_out_pro

    valid_out_pro : process( all )
    begin
        if state=normal or state=term then
            valid_out_nxt <= '1';
        else
            valid_out_nxt <= '0';
        end if ;
    end process ; -- valid_out_pro
    
end architecture ;