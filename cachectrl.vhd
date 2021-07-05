--cache controller
--use write buffer

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.conf.all;

entity cachectrl is
    generic(
        constant blockfield : natural := 2 --block size = 4 words
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        --processer
        address : in std_logic_vector(memwidth-1 downto 0);
        w_data : in std_logic_vector(memwidth-1 downto 0);
        r_data : out std_logic_vector(memwidth-1 downto 0);
        rewr : in std_logic;
        valid : in std_logic;
        ready : out std_logic;

        --upper level memory
        u_address : out std_logic_vector(memwidth-1 downto 0);
        u_w_data : out std_logic_vector(memwidth-1 downto 0);
        u_r_data : in std_logic_vector(memwidth-1 downto 0);
        u_rewr : out std_logic;
        u_valid : out std_logic;
        u_ready : in std_logic;
        u_idle : in std_logic
    );
end cachectrl;

architecture rtl of cachectrl is

    type state_type is (idle, acces, allocate, writeback);
    signal state,state_nxt : state_type;
    signal u_counter, c_counter, wb_counter : unsigned(blockfield-1 downto 0);
    signal u_ctr_en, u_ctr_start, u_ctr_incr, c_ctr_en, c_ctr_start, c_ctr_incr, wb_ctr_en, wb_ctr_start, wb_ctr_incr : std_logic;
    signal u_burst_done, c_burst_done, wb_burst_done : std_logic;               --assert 1 when last valid/ready handshake completes
    --input registers
    signal address_valid, w_data_valid : std_logic_vector(memwidth-1 downto 0);
    signal rewr_valid : std_logic;
    --output registers, registers of r_data and u_w_data are assumed in the module
    signal ready_nxt, u_rewr_nxt, u_valid_nxt : std_logic;                      
    signal u_address_nxt : std_logic_vector(memwidth-1 downto 0);
    --connection to cache
    signal cache_hit, cache_ready, cache_dirty ,cache_rewr, cache_tagop, cache_invalidate: std_logic;
    signal cache_address, cache_w_data, cache_r_data: std_logic_vector(memwidth-1 downto 0);
    --connection to write buffer
    signal wbuffer_ready, wbuffer_valid, wbuffer_rewr, wbuffer_full, wbuffer_empty, wbuffer_idle : std_logic;
    signal wbuffer_address, wbuffer_data, wbuffer_r_data : std_logic_vector(memwidth-1 downto 0);

    
begin
    cache0: entity work.cache port map(
        cache_valid => cache_valid,
        cache_ready => cache_ready,
        rewr => cache_rewr,
        inval => cache_invalidate,
        tagop => cache_tagop,
        address => cache_address,
        w_data => cache_w_data,
        r_data => cache_r_data,
        hit => cache_hit,
        dirty => cache_dirty
    );
    r_data <= cache_r_data;

    wbuffer0: entity work.wbuffer port map(
        valid => wbuffer_valid,
        ready => wbuffer_ready,
        rewr => wbuffer_rewr,
        idle => wbuffer_idle,
        address => wbuffer_address,
        w_data => wbuffer_w_data,
        r_data => wbuffer_r_data,
        full => wbuffer_full,
        empty => wbuffer_empty
    );
    u_w_data <= wbuffer_r_data;     --only write buffer writes to upstream memory

    out_seq: process(clk, rst)
    begin
        if rst = rst_val then
            ready <= '1';
            u_rewr <= '0';
            u_valid <= '0';
            u_address <= (memwidth-1 downto 0 => '0');
            state <= idle;
        elsif rising_edge(clk) then
            ready <= ready_nxt;
            u_rewr <= u_rewr_nxt;
            u_valid <= u_valid_nxt;
            u_address <= u_address_nxt;
            state <= state_nxt;  
        end if;
    end process out_seq;

    in_seq: process(clk, rst)
    begin
        if rst = rst_val then
            address_valid <= (address_valid'length downto 0 => '0');
            w_data_valid <= (w_data_valid'length downto 0 => '0');
            rewr_valid <= '0';
        elsif rising_edge(clk) then
            if state=idle and valid='1' then
                address_valid <= address;
                w_data_valid <= w_data;
                rewr_valid <= rewr;
            end if;
        end if;
    end process in_seq;

    state_transition: process(all)
    begin
        case state is
            when idle =>
                if valid = '1' then
                    state_nxt <= acces;
                else
                    state_nxt <= state;
                end if;

            when acces =>
                if cache_hit='1' and cache_ready='1' then                         --valid,hit,(-)
                    state_nxt <= idle;
                elsif cache_hit='0' and cache_ready='1' and cache_dirty='0' and u_idle='1' then  --(-),miss,clean
                    state_nxt <= allocate;
                elsif cache_hit='0' and cache_ready='1' and cache_dirty='1' and wbuffer_idle='1' then  --valid,miss,dirty
                    state_nxt <= writeback;
                else
                    state_nxt <= state;
                end if;

            when allocate =>
                if c_burst_done = '1' and u_burst_done='1' and cache_ready='1' then    --when both submodule last handshakes complete and cache is ready
                    state_nxt <= acces;
                else
                    state_nxt <= state;
                end if;

            when writeback =>
                if c_burst_done = '1' and cache_ready='1' then      --when cache submodule last handshake complete and cache is ready
                    state_nxt <= allocate;
                else
                    state_nxt <= state;
                end if;
        
            when others =>
                assert false
                    report "state value incorrect"
                    severity failure;
        end case;
    end process state_transition;

    ready_nxt_proc: process(all)
    begin
        if state_nxt=idle then
            ready_nxt <= '1';
        else
            ready_nxt <= '0';
        end if;
    end process;

    u_rewr_proc: process(all)
    begin
        if state_nxt=allocate then
            u_rewr_nxt <= '0';
        else
            u_rewr_nxt <= '1';
        end if;
    end process;

    u_valid_proc: process(all)
    begin
        if state_nxt=allocate and u_burst_done='0' then
            if u_counter=(u_counter'length downto 0 => '0') then    --first read
                u_valid_nxt <= '1';
            elsif u_counter-c_counter=(u_counter'length downto 1 => '0' , 0 => '1') and c_ctr_incr='1' then --u is ahead of c and next cycle c will catch up
                u_valid_nxt <= '1';
            else
                u_valid_nxt <= '0';
            end if;
        else
            u_valid_nxt <= '0';
        end if;
    end process;

    u_address_proc : process(all)
    begin
        if state_nxt=allocate then
            u_address_nxt <= (address_valid(memwidth-1 downto 4),u_counter,others => '0');
        else
            u_address_nxt <= (u_address_nxt'length downto 0 => '0');
        end if;
    end process;


    control_signal: process(state)
    begin
        case state is
            when idle =>
                u_ctr_en <='0';
                c_ctr_en <= '0';
                wb_ctr_en <= '0';
                
                cache_address <= address_valid;
                cache_w_data <= w_data_valid;
                cache_rewr <= rewr_valid;
                cache_valid <= valid;

            when acces =>
                u_ctr_en <='0';
                c_ctr_en <= '0';
                wb_ctr_en <= '0';
            
                cache_address <= address_valid;
                cache_w_data <= w_data_valid;
                cache_rewr <= rewr_valid;
                cache_valid <= '0';

            when allocate =>                    --write cache with upstream memory data, burst length = block size
                u_ctr_en <= '1';
                c_ctr_en <= '1';
                wb_ctr_en <= '0';

                cache_address <= (address_valid(memwidth-1 downto 4),c_counter,others => '0');   
                cache_w_data <= u_r_data;
                cache_rewr <= '1';
                cache_valid <= u_ready when (u_counter or c_counter) /= (u_counter'length downto 0 => '0') else '0';

                wbuffer_valid <= '0';

            when writeback =>
                u_ctr_en <= '0';
                c_ctr_en <= '1';
                wb_ctr_en <= '1';

                cache_address <= (address_valid(memwidth-1 downto 4),c_counter,others => '0');   --read cache to write buffer, burst length = block size
                cache_w_data <= w_data_valid;
                cache_rewr <= '0';
                if c_burst_done='0' then
                    if c_counter=(c_counter'length downto 0 => '0') then    --first read
                        cache_valid <= '1';
                    elsif c_counter-wb_counter=(c_counter'length downto 1 => '0' , 0 => '1') and wb_ctr_incr='1' then --c is ahead of wb and next cycle wb will catch up
                        cache_valid <= '1';
                    else
                        cache_valid <= '0';
                    end if;
                else
                    cache_valid <= '0';
                end if;
-------------------Write back address not yet ready---------------
                wbuffer_address <= (wb_address(memwidth-1 downto 4),wb_counter,others => '0');
                wbuffer_w_data <= cache_r_data;
                wbuffer_rewr <= '1';
                wbuffer_valid <= cache_ready when (wb_counter or c_counter) /= (wb_counter'length downto 0 => '0') else '0';;
        
            when others =>
                assert false
                    report "state value incorrect"
                    severity failure;
        end case;
    end process control_signal;

    upstream_mem_counter : conditional_counter(clk, rst, u_ctr_en, u_ctr_start, u_counter); --counts numbers of (u_valid and u_ready) when enabled
    cache_counter : conditional_counter(clk, rst, c_ctr_en, c_ctr_start, c_counter);
    writebuffer_counter : conditional_counter(clk, rst, wb_ctr_en, wb_ctr_start, wb_counter);

    if state/=allocate and state_nxt=allocate then
        u_ctr_start <= '1';
    else
        u_ctr_start <= '0';
    end if;

    if u_ctr_en='1' and u_ready='1' and u_valid='1' then
        u_ctr_incr <= '1';
    else
        u_ctr_incr <= '0';
    end if;

    if state=acces and (state_nxt=writeback or state_nxt=allocate) then
        c_ctr_start <= '1';
    else
        c_ctr_start <= '0';
    end if;

    if c_ctr_en='1' and cache_ready='1' and cache_valid='1' then
        c_ctr_incr <= '1';
    else
        c_ctr_incr <= '0';
    end if;

    if state=acces and state_nxt=writeback then
        wb_ctr_start <= '1';
    else
        wb_ctr_start <= '0';
    end if;

    if wb_ctr_en='1' and wbuffer_ready='1' and wbuffer_valid='1' then
        wb_ctr_incr <= '1';
    else
        wb_ctr_incr <= '0';
    end if;

    u_burst_done_proc : process(clk, rst)
    begin
        if rst = rst_val then
            u_burst_done <= '0';
        elsif u_ctr_en = '1' then
            if rising_edge(clk) then
                if (u_valid='1' and u_ready='1' and u_counter=(u_counter'length downto 0 => '1')) then
                    u_burst_done <= '1';
                end if;
            end if;
        else
            u_burst_done <= '0';
        end if;
    end process u_burst_done_proc;

    wb_burst_done_proc : process(clk, rst)
    begin
        if rst = rst_val then
            wb_burst_done <= '0';
        elsif wb_ctr_en = '1' then
            if rising_edge(clk) then
                if (wb_valid='1' and wb_ready='1' and wb_counter=(wb_counter'length downto 0 => '1')) then
                    wb_burst_done <= '1';
                end if;
            end if;
        else
            wb_burst_done <= '0';
        end if;
    end process wb_burst_done_proc;


    c_burst_done_proc : process(clk,rst)
    begin
        if rst = rst_val then
            c_burst_done <= '0';
        elsif c_ctr_en = '1' then
            if rising_edge(clk) then
                if (cache_valid='1' and cache_ready='1' and c_counter=(c_counter'length downto 0 => '1')) then
                    c_burst_done <= '1';
                end if;
            end if;
        else
            c_burst_done <= '0';
        end if;
    end process c_burst_done_proc;


end architecture;