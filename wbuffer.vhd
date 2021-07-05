--write buffer
--mode : read, write, read tag, write tag
--controller state : idle, r/w tag, r/w word 0,1,2,3...
--state machine is in cache controller

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.conf.all;

entity wbuffer is
    generic(
        constant blockfield : natural := 2; --block size = 4 words
        constant indexfield : natural := 2 --wbuffer size = 4 blocks
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        valid : in std_logic;
        ready : out std_logic;
        rewr : in std_logic;
        tagop : in std_logic;
        burst_last : in std_logic;
        address : in std_logic_vector(memwidth-1 downto 0);
        w_data : in std_logic_vector(memwidth-1 downto 0);
        r_data : out std_logic_vector(memwidth-1 downto 0);
        full : out std_logic
    );
end wbuffer;

architecture rtl of wbuffer is
    constant tagfield : integer := (memwidth-blockfield-2);
    constant linesize : integer := memwidth*(blockfield**2)+tagfield+1+1;  --valid bit, dirty bit, tags, words
    type cache_type is array (natural range <>) of std_logic_vector(linesize-1 downto 0);
    signal cachemem : cache_type(0 to indexfield-1);
    signal tag : std_logic_vector(tagfield-1 downto 0);
    signal index : integer;
    signal wordoffset : std_logic_vector(blockfield-1 downto 0);
    signal r_data_nxt : std_logic_vector(memwidth-1 downto 0);
begin
    tag <= address(memwidth-1 downto memwidth-tagfield);
    index <= to_integer(unsigned( address(memwidth-tagfield-1 downto memwidth-tagfield-indexfield) ));
    wordoffset <= address(blockfield+2-1 downto 2);

end architecture;