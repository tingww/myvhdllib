library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library work;
use work.conv_dec_pack.all;

use std.textio.all;
use std.env.stop;

library txt_util;
use txt_util.txt_util.str;

entity conv_dec_tb is
end conv_dec_tb;

architecture sim of conv_dec_tb is

    constant clk_hz : integer := 100e6;
    constant clk_period : time := 1 sec / clk_hz;

    signal clk : std_logic := '1';
    signal rst : std_logic := '1';
    signal d_out,enable,valid_out : std_logic;
    signal d_in : std_logic_vector(1 downto 0) ;
    file f : text open read_mode is "testbench/conv_dec_tb.txt";

begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.conv_dec(rtl)
    port map (
        clk => clk,
        rst => rst,
        enable => enable,
        d_in => d_in,
        d_out => d_out,
        valid_out => valid_out
    );

    SEQUENCER_PROC : process
        variable f_line : line;
        variable f_in : std_logic_vector(4 downto 0) ;
        variable d_out_ref,valid_out_ref : std_logic;
        variable line_count : natural :=0;
    begin
        wait for clk_period * 2;

        rst <= '0';

        while not (endfile(f)) loop
            wait for 1 ps;
            line_count := line_count + 1;
            readline(f,f_line);
            read(f_line,f_in);
            enable <= f_in(4);
            d_in <= f_in(3 downto 2);
            d_out_ref := f_in(1);
            valid_out_ref := f_in(0);
            if d_out_ref /= d_out then
                report("There's a error at " & integer'image(line_count) & ", d_out is " & str(d_out) & ", d_out_ref is " & str(d_out_ref));
            end if ;
            wait until rising_edge(clk);
        end loop;
        wait for clk_period * 2;
        report "End of Sim.";        
        stop;
    end process;

end architecture;