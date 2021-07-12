library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.d_ff;


entity shift_reg is
    generic(
        size : natural := 4
    );
    port (
        clk,rst,d,ce: in std_logic;
        q,qn: out std_logic_vector(size-1 downto 0)      --vhdl 2008 needed for reading output
    );
end shift_reg;

architecture rtl of shift_reg is
    component D_FF is
    port (
        d,ce,clk,rst: in std_logic;
        q,qn: out std_logic
    );
    end component;
    signal q_intern : std_logic_vector(size downto 0);
begin
    q_intern(0) <= d;
    gen: for i in 1 to size generate
        dff_i: D_FF port map(
            q_intern(i-1),ce,clk,rst,q_intern(i),qn(i-1)
        );
    end generate;

    q <= q_intern(size downto 1);
end architecture;

configuration rtl of shift_reg is
    
    for rtl 
        for gen
        
            for dff_i: D_FF use entity work.D_FF(rtl);
            end for;
        end for;
    end for;
    
end configuration rtl;
