library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use std.env.stop;




entity shift_reg_tb is
end shift_reg_tb;

architecture sim of shift_reg_tb is
    constant clk_period : time := 10 ns;
    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal d,ce : std_logic;
    signal q,qn : std_logic_vector(3 downto 0);

begin

    DUT : entity work.shift_reg(rtl)
    port map (
        clk,rst,d,ce,q,qn
    );

    clk <= not clk after clk_period/2;

    waveform_test : process
    begin
        wait for clk_period;
        ce <= '1';
        rst <= '0';
        d <= '1';
        wait for clk_period;

        report "End of simulation";        
        stop;
    end process;

end architecture;
