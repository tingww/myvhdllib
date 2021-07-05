library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

use work.conf.all;

entity fifo_tb is
end fifo_tb;

architecture sim of fifo_tb is

    constant clk_hz : integer := 100e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal d_in : std_logic_vector(memwidth-1 downto 0) := (others => '0');
    signal w_en : std_logic := '0';
    signal d_out : std_logic_vector(memwidth-1 downto 0) := (others => '0');
    signal r_en : std_logic := '0';
    signal full : std_logic := '0';
    signal empty : std_logic := '0';
begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.fifo(rtl)
    port map (
        clk => clk,
        rst => rst,
        d_in => d_in,
        w_en => w_en,
        d_out => d_out,
        r_en => r_en,
        full => full,
        empty => empty
    );

    SEQUENCER_PROC : process
        variable one : unsigned(integer(ceil(log2(real(8))))-1 downto 0) := (0 =>'1', others => '0');
    begin
        wait for clk_period * 2;

        rst <= '1';
        wait for clk_period;
        rst <= '0';
        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);
        r_en <= '1';

        wait for clk_period;
        w_en <= '0';
        d_in <= std_logic_vector(unsigned(d_in)+one);
        r_en <= '1';
        
        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        w_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        r_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        r_en <= '1';
        d_in <= std_logic_vector(unsigned(d_in)+one);

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';

        wait for clk_period;
        r_en <= '1';
        
        wait for clk_period * 10;
        assert false
            report "Replace this with your test cases"
            severity failure;

        finish;
    end process;

end architecture;