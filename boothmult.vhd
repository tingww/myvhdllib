-- 16-bit booth multiplier
-- 8 cycles delay

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity boothmult is
    port (
        clk : in std_logic;
        rst : in std_logic;
        en : in std_logic;
        i0,i1 : in std_logic_vector(15 downto 0);
        o : out std_logic_vector(31 downto 0);
        ready : out std_logic
    );
end boothmult;

architecture rtl of boothmult is
    signal i1_pad : std_logic_vector(16 downto 0);
    signal i0_shifted,i0_shifted_nxt : std_logic_vector(31 downto 0);
    signal counter, counter_nxt : unsigned(2 downto 0);
    signal o_nxt : std_logic_vector(31 downto 0) ;
    signal ready_nxt : std_logic;
begin
    seq : process( clk,rst )
    begin
        if rst='1' then
            o <= (others => '0');
            ready <= '0';
            i0_shifted <= (others => '0');
        elsif rising_edge(clk) then
            o <= o_nxt;
            ready <= ready_nxt;            
            i0_shifted <= i0_shifted_nxt;
        end if ;
    end process ; -- seq

    counter_pro : process( clk,rst )
    begin
        if rst='1' then
            counter <= (others => '0');
        elsif rising_edge(clk) and en = '1' then
            counter <= counter + to_unsigned(1, counter'length);
        end if ;
    end process ; -- counter

    i1_pad <= i1 & '0';

    comb : process( all )
        variable index : natural;
        variable i0_temp,i0_2_temp : signed(31 downto 0);
        variable o_temp : std_logic_vector(31 downto 0) ;
    begin
        index := to_integer(counter)*2;

        if en='1' then

            if counter=to_unsigned(0, counter'length) then
                i0_temp := resize(signed(i0),i0_temp'length);
                i0_2_temp := resize(signed(i0),i0_2_temp'length-1) & '0';
                o_temp := (others => '0');
            else
                i0_temp := signed(i0_shifted);
                i0_2_temp := signed(i0_shifted(30 downto 0)) & '0';
                o_temp := o;
            end if ;

            case( i1_pad(index+2 downto index) ) is
                when "000" => 
                    o_nxt <= o_temp;
                when "111" =>
                    o_nxt <= o_temp;
                when "001" =>
                    o_nxt <= std_logic_vector(signed(o_temp) +  i0_temp);
                when "010" =>
                    o_nxt <= std_logic_vector(signed(o_temp) +  i0_temp);
                when "011" =>
                    o_nxt <= std_logic_vector(signed(o_temp) +  i0_2_temp);
                when "100" =>
                    o_nxt <= std_logic_vector(signed(o_temp) -  i0_2_temp);
                when "101" =>
                    o_nxt <= std_logic_vector(signed(o_temp) -  i0_temp);
                when "110" =>
                    o_nxt <= std_logic_vector(signed(o_temp) -  i0_temp);
                when others =>
                    report "Case should not be here";                    
            end case ;
        else
            i0_temp := (others => '0');
            i0_2_temp := (others => '0');
            o_nxt <= o ;
        end if ;

        if counter=(counter'length-1 downto 0 => '1') then
            ready_nxt <= '1';
        else
            ready_nxt <= '0';
        end if ;

        i0_shifted_nxt <=std_logic_vector(i0_2_temp(30 downto 0)) & '0';

    end process ; -- comb
end architecture;