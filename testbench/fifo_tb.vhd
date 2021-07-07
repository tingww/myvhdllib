library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.stop;


entity fifo_tb is
end fifo_tb;

architecture sim of fifo_tb is

    constant clk_hz : integer := 100e6; --100M
    constant clk_period : time := 1 sec / clk_hz;
    constant memwidth : natural := 32;

    constant n : natural := 8;

    signal clk : std_logic := '1';
    signal rst : std_logic := '0';

    signal valid : std_logic := '0';
    signal d_in : std_logic_vector(memwidth-1 downto 0) := (others => '0');
    signal rewr : std_logic := '0';

    signal d_out : std_logic_vector(memwidth-1 downto 0) := (others => '0');
    signal ready : std_logic := '0';
    signal full : std_logic := '0';
    signal empty : std_logic := '0';
begin

    clk <= not clk after clk_period / 2;

    DUT : entity work.fifo(rtl)
    generic map(
        n => n
    )
    port map (
        valid => valid,
        ready => ready,
        clk => clk,
        rst => rst,
        d_in => d_in,
        rewr => rewr,
        d_out => d_out,
        full => full,
        empty => empty
    );

    SEQUENCER_PROC : process
        variable val,val1 : natural := 0;
        variable j : integer := 0;
    begin
        wait for 2*clk_period;

        write2full_read2empty: for i in 0 to 6*n loop
            valid <= '1';
            rst <= '1';
            d_in <= std_logic_vector(to_unsigned(val, d_in'length));
            
            if i <= 3*n then
                rewr <= '1';
            else
                rewr <= '0';
            end if ;
            --evaluation at falling edge clk
            wait for clk_period/2;
            if i>3*n+1 and i<=5*n then
                if ready='1' then
                    assert d_out=std_logic_vector(to_unsigned(n-val-1, d_in'length)) report "there's an error" severity note;
                end if ;
            end if ;
            --increase val at rising edge clk
            wait for clk_period/2;
            if ready='1' then
                if rewr='1' and full/='1' then
                    val := val+1;
                end if ;
                if rewr='0' and empty/='1' then
                    val := val-1;
                end if ;
            end if ;
        end loop write2full_read2empty;

        val := 0;
        val1:= 0;
        almost_full_handling : while true loop
            valid <= '1';
            rst <= '1';
            d_in <= std_logic_vector(to_unsigned(val, d_in'length));
            if j<n then
                rewr<='1';
            else
                if (j mod 2)=1 then
                    rewr<='1';
                else 
                    rewr<='0';
                end if ;
            end if ;
            --evaluation at falling edge clk
            wait for clk_period/2;
            if j>n and (j mod 2)=1 then --read output at j>n and odd number, ex: read at 8th ready, output at 9th ready
                if ready='1' then
                    assert d_out=std_logic_vector(to_unsigned(val1-1, d_in'length)) report "there's an error" severity note;
                end if ;
            end if ;
            --increase val,val1,j at rising edge clk; j=j+1 at each valid handshake
            wait for clk_period/2;
            if ready='1' then
                if rewr='1' and full/='1' then
                    val := val+1;
                    j := j+1;
                end if ;
                if rewr='0' and empty/='1' then
                    val1 := val1+1;
                    j := j+1;
                end if ;
            end if ;

            if j>6*n then
                exit;
            end if ;
        end loop ; -- almost_full_handling

        report "End of simulation.";        
        stop;
    end process;

end architecture;