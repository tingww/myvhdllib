library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.conf.all;

entity mem is
    generic(
        constant n_words : integer := 2**(memwidth-memwidth/8);
        constant r_delay : time := 1*clock_period;
        constant w_delay : time := 1*clock_period
    );
    port (
        r_address : in std_logic_vector(memwidth-1 downto 0);
        r_arready : out std_logic;
        r_arvalid : in std_logic;
        r_data : out std_logic_vector(memwidth-1 downto 0);
        r_ready : in std_logic;
        r_valid : out std_logic;

        w_address : in std_logic_vector(memwidth-1 downto 0);
        w_data : in std_logic_vector(memwidth-1 downto 0);
        w_ready : out std_logic;
        w_valid : in std_logic;
        clk : in bit
    );
end mem;

architecture rtl of mem is
    type sram_type is array (n_words downto 0) of std_logic_vector(memwidth-1 downto 0);
    signal sram : sram_type;
begin
    r_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if  r_arvalid and r_arready then
                r_arready <= '0';
                r_data <= sram(to_integer(unsigned(r_address))) after r_delay;
                r_valid <= '1' after r_delay;
                r_arready <= '1' after r_delay;
            else 
                r_valid <='0';
            end if;
        end if;
    end process;

    w_PROC : process(clk)
    begin
        if rising_edge(clk) then
            if  w_valid and w_ready then
                w_ready <= '0';
                sram(to_integer(unsigned(w_address))) <= w_data after w_delay;
                w_ready <= '1' after w_delay;
            end if;
        end if;
    end process;


end architecture;