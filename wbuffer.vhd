--write buffer
--mode : read, write, read tag, write tag
--needs a controller
--controller state : idle, r/w tag, r/w word 0,1,2,3...
--state machine is in cache controller

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.conf.all;

entity wbuffer is
    generic(
        constant blockfield : natural := 2; --block size = 4 words
        constant wbuffer_size : natural := 2 --wbuffer size = 4 blocks
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        valid : in std_logic;
        ready : out std_logic;
        rewr : in std_logic;
        tagop : in std_logic;
        w_data : in std_logic_vector(memwidth-1 downto 0);
        r_data : out std_logic_vector(memwidth-1 downto 0);
        full : out std_logic
    );
end wbuffer;

architecture rtl of wbuffer is
    constant tagfield : integer := (memwidth-blockfield-2); --| tags | word offset | byte offset |
    constant linesize : integer := memwidth*(blockfield**2)+tagfield;  --tags, words
    type cache_type is array (natural range <>) of std_logic_vector(linesize-1 downto 0);
    signal cachemem : cache_type(0 to wbuffer_size-1);
    signal tag : std_logic_vector(tagfield-1 downto 0);
    signal index : integer;
    signal wordoffset : std_logic_vector(blockfield-1 downto 0);
    type word_bundle_type is array (0 to blockfield**2-1) of std_logic_vector(memwidth-1 downto 0);
    signal word_bundle : word_bundle_type;

    signal r_data_nxt : std_logic_vector(memwidth-1 downto 0);
    signal ready_nxt, full_nxt : std_logic;

    signal head, head_nxt, tail, tail_nxt : unsigned(wbuffer_size-1 downto 0);
begin
    tag <= w_data(memwidth-1 downto memwidth-tagfield);
    wordoffset <= to_integer(unsigned(r_data(blockfield+2-1 downto 2)));

    reg : process( clk,rst )
    begin
        if rst=rstval then
            ready <= '1';
            full <= '0';
            r_data <= (r_data'length-1 downto 0 => '0');
            head <= (wbuffer_size-1 downto 0 => '0');
            tail <= (wbuffer_size-1 downto 0 => '0');
        elsif clk'event and clk = '1' then
            ready <= ready_nxt;
            full <= full_nxt;
            r_data <= r_data_nxt;
            head <= head_nxt;
            tail <= tail_nxt;
        end if ;
    end process ; -- reg

    ready_pro : process( all )  --one clock cycle delay
    begin
        if valid='1' and ready='1' then
            ready_nxt <= '0';
        else
            ready_nxt <= '1';
        end if ;
    end process ; -- ready_pro

    full_pro : process( all )
    begin
        if head_nxt=tail_nxt then
            full_nxt <= '1';
        else
            full_nxt <= '0';
        end if ;
    end process ; -- full_pro

    word_bundle_gen : for i in blockfield**2-1 downto 0 generate
    begin
        word_bundle(i) <= cachemem(tail)(memwidth*(i+1)-1 downto memwidth*i);
    end generate;

    r_data_pro : process( all )
    begin
        if ready_nxt = '0' and rewr='0' then
            if tagop='1' then   --read tag
                r_data_nxt <= (memwidth-1 downto memwidth-1-tagfield) & cachemem(tail)(linesize-1 downto linesize-1-tagfield);
            else
                r_data_nxt <= word_bundle(wordoffset);
            end if ;
        else
            r_data_nxt <= r_data;
        end if ;
    end process ; -- r_data_pro

    head_pro : process( all )
    begin
        if ready_nxt = '0' and rewr='1' and tagop='1' then
            head_nxt <= head + unsigned(1,head'length);
        else 
            head_nxt <= head;
        end if ;
    end process ; -- head_pro

    tail_pro : process( all )
    begin
        if ready_nxt = '0' and rewr='0' and tagop='1' then
            tail_nxt <= tail + unsigned(1,tail'length);
        else 
            tail_nxt <= tail;
        end if ;
    end process ; -- tail_pro


end architecture;