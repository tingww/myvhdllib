--package
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package conf is
    constant memwidth : integer := 32;
    constant clock_period : time := 10 ns;
    constant rst_val : std_logic := '0';

    type natural_arr is array (integer range <>) of natural;
    type slv_arr is array (integer range <>) of std_logic_vector(memwidth-1 downto 0);
    type alu_opcode is 
        (add, slt, sltu, andd, orr, xorr,slll, srll, sub, sraa);
    --add, subtract, and, or, xor 
    --set-less-then, slt-unsigned 
    --shift-left-logical, srl, shift-right-arithmetric

    procedure conditional_counter(              --count up when en, incr = 1; reset on rst or rising edge enable
        signal clk,rst,en,incr,start : in std_logic;
        signal ctr_val : out unsigned
        );
end package conf;

package body conf is
    procedure conditional_counter(              --count up when en, incr = 1; reset on rst or start
        signal clk,rst,en,incr,start : in std_logic;
        signal ctr_val : out unsigned
        ) is
        variable temp,temp_nxt : unsigned(ctr_val'length downto 0);
    begin
        if rst = rst_val then
            temp := (ctr_val'length downto 0 => '0');
        elsif rising_edge(clk) then     
            temp := temp_nxt;
        end if;
        
        if start = '1' then
            temp_nxt := (ctr_val'length downto 0 => '0');
        elsif en='1' and incr='1' then
            temp_nxt := temp + (temp'length downto 0 => '0')&'1';
        else
            temp_nxt := temp;
        end if;
        ctr_val<=temp;
    end procedure;
    
    
end package body conf;