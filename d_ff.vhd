library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity d_ff is
    generic(
        delay : time := 0 ns
    );
    port (
        d,ce,clk,rst: in std_logic;
        q,qn: out std_logic
    );
end d_ff;

architecture rtl of d_ff is

begin
    PROC : process(d,ce,rst,clk)
        
    begin
        if rst='1' then
            q<='0' after delay;
        elsif rising_edge(clk) and ce='1' then
            q<=d after delay;
            qn<= not d after delay;    
        end if;
    end process;

end architecture;