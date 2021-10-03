library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;
use std.env.stop;

entity boothmult_tb is
end boothmult_tb;

architecture sim of boothmult_tb is

    constant clk_hz : integer := 100e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal en : std_logic;
    signal i0,i1 : std_logic_vector(15 downto 0);
    signal o :std_logic_vector(31 downto 0);
    signal ready :std_logic;

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.boothmult(rtl)
    port map (
        clk => clk,
        rst => rst,
        en => en,
        i0 => i0,
        i1 => i1,
        o => o,
        ready => ready
    );

    SEQUENCER_PROC : process
    begin
        wait for clk_period * 2;

        for i in 7 downto 0 loop
            rst <= '0';
            en <= '1';
            i1 <= std_logic_vector(to_signed(-18550, i1'length));
            i0 <= std_logic_vector(to_signed(21844, i0'length));
            

            wait for clk_period ;
        end loop;
        
        wait for 1 ns ;
        assert o=std_logic_vector(to_signed(-18550*21844, o'length))
            report "Something went wrong."
            severity failure;

        report "End of Sim.";        
        stop;
    end process;

end architecture;