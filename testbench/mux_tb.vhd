library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

use work.conf.all;

entity mux_tb is
end mux_tb;

architecture sim of mux_tb is

    constant n : integer := 4;
    signal data_i : slv_arr(n-1 downto 0);
    signal data_o : std_logic_vector(memwidth-1 downto 0);
    signal sel : std_logic_vector(integer(ceil(log2(real(n))))-1 downto 0);

begin


    DUT : entity work.mux(rtl)
    generic map(
        n => n
    )
    port map (
        data_i => data_i,
        data_o => data_o,
        sel => sel
    );

    SEQUENCER_PROC : process is
        variable xx : std_logic_vector(memwidth-1 downto 0) := (others => '1');
    begin
        data_i <= ((others => '0'),(others => '1'),(memwidth-1 downto 1 => '0', 0 => '1'),(memwidth-1 downto 1 => '1', 0 => '0'));
        sel <= B"01";
        wait for 10 ns;
        assert data_o = xx
            report "WRONG!!";

        finish;
    end process;

end architecture;