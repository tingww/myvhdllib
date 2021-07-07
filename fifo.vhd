--fifo with n slots memwidth

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity fifo is
    generic(
        n : natural := 8;
        memwidth : natural := 32;
        rst_val : std_logic := '0'
    );
    port (
        valid : in std_logic;
        ready : out std_logic;
        d_in : in std_logic_vector(memwidth-1 downto 0);
        d_out : out std_logic_vector(memwidth-1 downto 0);
        rewr : in std_logic;
        full : out std_logic := '0';
        empty : out std_logic := '0';
        rst : in std_logic;
        clk : in std_logic            
    );
end fifo;

architecture rtl of fifo is
    signal head, head_nxt , tail , tail_nxt : unsigned(integer(ceil(log2(real(n))))-1 downto 0);
    type state_type is (normal, almost_full, full_state, empty_state);
    signal state, state_nxt : state_type;

    signal full_nxt,empty_nxt,ready_nxt : std_logic;
    signal d_out_nxt : std_logic_vector(memwidth-1 downto 0);

    signal d_in_reg,d_in_reg_nxt : std_logic_vector(memwidth-1 downto 0);
    signal rewr_reg,rewr_reg_nxt : std_logic;

    component ram is 
        generic(
            address_size : natural;
            memwidth : natural
        );
        port(
        w_data : in std_logic_vector(memwidth-1 downto 0);
        r_data : out std_logic_vector(memwidth-1 downto 0);
        address : in std_logic_vector(head'length-1 downto 0);
        en : in std_logic;
        rewr : in std_logic
        );
    end component;
    signal w_data,r_data : std_logic_vector(memwidth-1 downto 0);
    signal address : std_logic_vector(head'length-1 downto 0) ;
    signal en,rewr_ram : std_logic;
begin
    reg : process( clk,rst )
    begin
        if rst=rst_val  then
            ready <= '1';
            state <= empty_state;
            head <= (head'length-1 downto 0 => '0');
            tail <= (tail'length-1 downto 0 => '0');
            full <= '0';
            empty <= '1';
            d_out <= (d_out'length-1 downto 0 => '0');
            d_in_reg <= (d_in_reg'length-1 downto 0 => '0');
            rewr_reg <= '0';
        elsif rising_edge(clk) then
            ready <= ready_nxt;
            state <= state_nxt;
            head <= head_nxt;
            tail <= tail_nxt;    
            full <= full_nxt;
            empty <= empty_nxt;   
            d_out <= d_out_nxt;     
            d_in_reg <= d_in_reg_nxt;
            rewr_reg <= rewr_reg_nxt;
        end if ;
    end process ; -- reg

    full_nxt <= '1' when state_nxt=full_state else '0';
    empty_nxt <= '1' when state_nxt=empty_state else '0';

    ram0 : ram 
        generic map(
            address_size => address'length,
            memwidth => memwidth
        )
        port map(
            w_data => w_data,
            r_data => r_data,
            address => address,
            en => en,
            rewr => rewr_ram
        );
    w_data <= d_in_reg;
    d_out_nxt <= r_data;
    rewr_ram <= rewr_reg;

    en_pro : process( all )
    begin
        if ready='0' then
            if (state=full_state and rewr_reg='1') or (state=empty_state and rewr_reg='0') then
                en <= '0';
            else 
                en <= '1';
            end if ;
        else
            en <= '0';
        end if ;    
    end process ; -- en_pro

    address_pro : process( all )
    begin
        if rewr_reg='0' then
            address <= std_logic_vector(tail);
        else
            address <= std_logic_vector(head);
        end if ;
    end process ; -- address_pro

    ready_pro : process( all )  --one cycle delay
    begin
        if valid='1' and ready='1'  then
            if (state=full_state and rewr='1') or (state=empty_state and rewr='0') then
                ready_nxt <= '1';
            else
                ready_nxt <= '0';
            end if ;
        else
            ready_nxt <= '1';
        end if ;
    end process ; -- ready_pro

    input_reg_pro : process( all )
    begin
        if valid='1' and ready='1' then
            d_in_reg_nxt <= d_in;
            rewr_reg_nxt <= rewr;
        else
            d_in_reg_nxt <= d_in_reg;
            rewr_reg_nxt <= rewr_reg;
        end if ;
    end process ; -- input_reg_pro

    state_pro : process( all )
    begin
        case( state ) is
        
            when empty_state => 
                if ready='0' and rewr_reg='1' then
                    state_nxt <= normal;
                else
                    state_nxt <= state;
                end if ;
            when normal =>
                if ready='0' and rewr_reg='1' and (head+to_unsigned(2,head'length))=tail then
                    state_nxt <= almost_full;
                elsif ready='0' and rewr_reg='0' and (tail+to_unsigned(1,tail'length))=head then
                    state_nxt <= empty_state;
                else
                    state_nxt <= state;
                end if ;
            when almost_full =>
                if ready='0' and rewr_reg='1' then
                    state_nxt <= full_state;
                elsif ready='0' and rewr_reg='0' then
                    state_nxt <= normal;
                else 
                    state_nxt <= state;
                end if ;
            when full_state =>
                if ready='0' and rewr_reg='0' then
                    state_nxt <= almost_full;
                else
                    state_nxt <= state;
                end if ;
        end case ;
    end process ; -- state_pro

    head_pro : process( all )
    begin
        if ready='0' and ready_nxt='1' and rewr_reg='1' and state/=full_state then
            head_nxt <= head + to_unsigned(1,head'length);
        else
            head_nxt <= head;
        end if ;
    end process ; -- head_pro

    tail_pro : process( all )
    begin
        if ready='0' and ready_nxt='1' and rewr_reg='0' and state/=empty_state then
            tail_nxt <= tail + to_unsigned(1,head'length);
        else
            tail_nxt <= tail;
        end if ;
    end process ; -- tail_pro


end architecture;