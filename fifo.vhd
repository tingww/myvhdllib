--fifo with n slots memwidth

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.conf.all;

entity fifo is
    generic(
        constant n : natural := 8
    );
    port (
        d_in : in std_logic_vector(memwidth-1 downto 0);
        w_en : in std_logic;
        d_out : out std_logic_vector(memwidth-1 downto 0);
        r_en : in std_logic;
        full : out std_logic := '0';
        empty : out std_logic := '0';
        rst : in std_logic;
        clk : in std_logic            
    );
end fifo;

architecture rtl of fifo is
    signal head,tail : unsigned(integer(ceil(log2(real(n))))-1 downto 0);
    type ring_buffer_type is array (0 to n-1) of std_logic_vector(memwidth-1 downto 0);
    signal ring_buffer : ring_buffer_type;
    signal almost_full, almost_empty : std_logic := '0';
begin
    HEAD_PROC : process(clk,rst)
        variable one : unsigned(integer(ceil(log2(real(n))))-1 downto 0) := (0 =>'1', others => '0');
    begin
        if rst then
            head <= (others => '0');
            full <= '0';
        elsif rising_edge(clk) then
            if w_en and (not full) then
                ring_buffer(to_integer(head)) <= d_in;
            end if;
            --could be in another clk process
            if almost_full then
                if w_en then
                    full <= '1';
                end if;
                if r_en and full then
                    full <= '0';
                    head <= head + one;
                end if;
            else
                if w_en then
                    head <= head + one;
                end if;
            end if;
        end if;
    end process;

    TAIL_PROC : process(clk,rst)
        variable one : unsigned(integer(ceil(log2(real(n))))-1 downto 0) := (0 =>'1', others => '0');
    begin
        if rst then
            tail <= (others => '0');
        elsif rising_edge(clk) then
            if r_en and (not empty) then
                d_out <= ring_buffer(to_integer(tail));
                tail <= tail + one;
            end if;
            if almost_empty then
                if r_en then
                    empty <= '1';
                end if;
                if w_en and empty then
                    empty <= '0';
                    tail <= tail + one;
                end if;
            else
                if r_en then
                    tail <= tail + one;
                end if;
            end if;
        end if;
    end process;

    --empty and almost_full update combinationally, full updates sequentially
    COMB_PROC : process(head,tail)
        variable one : unsigned(integer(ceil(log2(real(n))))-1 downto 0) := (0 =>'1', others => '0');
    begin
        if head = tail then
            almost_empty <= '1';
        else 
            almost_empty <= '0';
        end if;

        if (tail-one) = head then
            almost_full <= '1';
        else
            almost_full <= '0';
        end if;
    end process;

end architecture;