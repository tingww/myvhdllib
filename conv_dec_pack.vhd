-- default encoder state transition
--prev state----in/out------- state
-- 00 -----------0/00---------- 00
-- 00 -----------1/11---------- 10
-- 10 -----------1/01---------- 11
-- 10 -----------0/10---------- 01
-- 11 -----------1/10---------- 11
-- 11 -----------0/01---------- 01
-- 01 -----------1/00---------- 10
-- 01 -----------0/11---------- 00
--
-- state table
--   state  | prev state 0  | prev state 1  |      out 0    |      out 1    |      in 0     |      in 1     |
--     00   |       00      |       01      |       00      |       11      |       0       |       0       |
--     01   |       10      |       11      |       10      |       01      |       0       |       0       |
--     10   |       00      |       01      |       11      |       00      |       1       |       1       |
--     11   |       10      |       11      |       01      |       10      |       1       |       1       |

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package conv_dec_pack is
    constant rstval : std_logic := '1';
    constant memory_element : natural := 2;
    constant state_num : natural := 4;
    constant generator_num : natural := 2;
    constant constrained_length : natural := 8;
    constant accum_cost_metric_bits : natural := 8; --maximum accumelative cost metric is 15
    constant acsu_delay : natural := 1;
    type bm_arr is array (0 to state_num-1) of std_logic_vector(generator_num-1 downto 0) ;
    type b_m_rec is record
        branch_out0 : bm_arr;
        branch_out1 : bm_arr;
    end record;
    type st_arr is array (0 to state_num-1) of integer ;
    type state_table_rec is record
        prev_state0 : st_arr;
        prev_state1 : st_arr;
        out0 : bm_arr;
        out1 : bm_arr;
        in0 : std_logic_vector(0 to state_num-1 );
        in1 : std_logic_vector(0 to state_num-1 );
    end record;
    type pme_arr is array (0 to state_num-1) of unsigned(memory_element-1 downto 0) ;   --path matrix entry type
    type acm_arr is array (0 to state_num-1) of unsigned(accum_cost_metric_bits-1 downto 0) ;
    constant state_table : state_table_rec := (
        prev_state0 => (0,2,0,2),
        prev_state1 => (1,3,1,3),
        out0 => ("00","10","11","01"),
        out1 => ("11","01","00","10"),
        in0 => ('0','0','1','1'),
        in1 => ('0','0','1','1')
    );
    function hamming_weight(a : std_logic_vector) return natural;
    function argmin_acm(acm : acm_arr) return integer;
end package;

package body conv_dec_pack is
    function hamming_weight(a : std_logic_vector) return natural is
        variable acc : natural :=0;
    begin
        for i in a'range loop   --not sure what this will be sythesize to
            if a(i)='1' then
                acc := acc +1;
            end if ;
        end loop;
        return acc;
    end function;  

    function argmin_acm(acm : acm_arr) return integer is
        variable temp : unsigned(accum_cost_metric_bits-1 downto 0) := (others => '1');
        variable index : integer := 0;
    begin
        for i in acm'range loop     --could be better if implement into recursive tree like structure?
            if acm(i)<temp then
                temp := acm(i);
                index := i;
            end if ;
        end loop;
        return index;
    end function;
end package body;