--N to 1 Multiplexer module
--numbers of inputs defined by n

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.conf.all;

entity mux is
    generic(
        constant n : positive := 4
    );
    port (
        data_i : in slv_arr(n-1 downto 0);
        data_o : out std_logic_vector(memwidth-1 downto 0);
        sel : in std_logic_vector(integer(ceil(log2(real(n))))-1 downto 0)
    );
end mux;

architecture rtl of mux is

begin
    data_o <= data_i(to_integer(unsigned(sel))+1);
end architecture;