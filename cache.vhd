--direct mapped cache
--mode : read, write, read tag, write tag, reset, invalidate
--cache line = | valid | dirty | tags     | data                |
--             | 1 bit | 1 bit | tagfield | memwidth*blocksize  |
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.conf.all;

entity cache is
    generic(
        constant blockfield : natural := 2; --block size = 4 words
        constant indexfield : natural := 10 --cache size = 1024 blocks
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        cache_valid : in std_logic;
        cache_ready : out std_logic;
        rewr : in std_logic;
        tagop : in std_logic;
        inval : in std_logic;
        address : in std_logic_vector(memwidth-1 downto 0);
        w_data : in std_logic_vector(memwidth-1 downto 0);
        r_data : out std_logic_vector(memwidth-1 downto 0);
        hit : out std_logic;
        dirty : out std_logic
    );
end cache;

architecture rtl of cache is
    constant tagfield : integer := (memwidth-indexfield-blockfield-2);
    constant linesize : integer := memwidth*(blockfield**2)+tagfield+1+1;  --valid bit, dirty bit, tags, words
    type cache_type is array (natural range <>) of std_logic_vector(linesize-1 downto 0);
    signal cachemem : cache_type(0 to indexfield-1);
    signal tag : std_logic_vector(tagfield-1 downto 0);
    signal index : integer;
    signal wordoffset : std_logic_vector(blockfield-1 downto 0);
    signal hit_nxt, dirty_nxt : std_logic;
    signal r_data_nxt : std_logic_vector(memwidth-1 downto 0);
    signal word_mux_out : std_logic_vector(memwidth-1 downto 0);
    type word_bundle_type is array (0 to blockfield**2-1) of std_logic_vector(memwidth-1 downto 0);
    signal word_bundle : word_bundle_type;
begin
    tag <= address(memwidth-1 downto memwidth-tagfield);
    index <= to_integer(unsigned( address(memwidth-tagfield-1 downto memwidth-tagfield-indexfield) ));
    wordoffset <= address(blockfield+2-1 downto 2);

    seq: process(clk, rst)
    begin
        if rst = rst_val then
            cache_ready <='0';
            hit <= '0';
            dirty <= '0';
            r_data <= (r_data'length-1 downto 0 => '0');
        elsif rising_edge(clk) then
            if cache_valid= '1' and cache_ready='1' then    --one clock_period delay, cache_ready hold high for one clock
                cache_ready <= '0';
            else
                cache_ready <= '1';
            end if;
            hit <= hit_nxt;
            dirty <= dirty_nxt;
            r_data <= r_data_nxt;
        end if;
    end process seq;

    word_bundle_gen : for i in blockfield**2-1 downto 0 generate
    begin
        word_bundle(i) <= cachemem(index)(memwidth*(i+1)-1 downto memwidth*i);
    end generate;

    r_data_nxt_proc: process(all)
    begin
        if cache_ready='0' and tagop='0' and rewr='0' and hit_nxt='1' then
            r_data_nxt <= word_bundle(to_integer(unsigned(wordoffset)));
        elsif cache_ready='0' and tagop='1' and rewr='0' then
            r_data_nxt <= cachemem(index)(linesize-1-1-1 downto linesize-1-1-tagfield);
        else
            r_data_nxt <= (r_data_nxt'length-1 downto 0 => '0');
        end if;
    end process;

    cachemem_proc: process(all)
        variable wo : natural := to_integer(unsigned(wordoffset));
    begin
        if cache_ready='0' and tagop='0' and rewr='1' and hit_nxt='1' then
            if inval= '1'then   --invalidate
                cachemem(index)(linesize-1) <= '0';
            else                --write
                cachemem(index)(memwidth*(wo+1)-1 downto memwidth*wo) <= w_data;  
                cachemem(index)(linesize-1-1) <= '1';   --set dirty bit
            end if;
        elsif cache_ready='0' and tagop='1' and rewr='1' then
            cachemem(index)(linesize-1-1-1 downto linesize-1-1-tagfield) <= tag;
        end if;
    end process;

    hit_dirty_proc : process(all)
    begin
        if cache_ready='0' then
            if cachemem(index)(linesize-1-1-1 downto linesize-1-1-tagfield) = tag and cachemem(index)(linesize-1) = '1' then    --valid hit
                hit_nxt <= '1';
                dirty_nxt <= '0';
                
            elsif cachemem(index)(linesize-1) = '1' and cachemem(index)(linesize-2) = '1' then  --valid miss dirty
                hit_nxt <= '0';
                dirty_nxt <= '1';
            else
                hit_nxt <= '0';
                dirty_nxt <= '0';
            end if;
        end if;
    end process;
    
    
end architecture;