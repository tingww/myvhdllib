library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;

entity ram is
    generic(
        address_size : natural := 3;
        memwidth : natural := 32
    );
    port (
        w_data : in std_logic_vector(memwidth-1 downto 0) ;
        r_data : out std_logic_vector(memwidth-1 downto 0) ;
        address : in std_logic_vector(address_size-1 downto 0) ;
        en : in std_logic;
        rewr : in std_logic
    ) ;
end ram ; 

architecture rtl of ram is
    type ram_type is array (0 to address_size-1) of std_logic_vector(memwidth-1 downto 0);
    signal ram_phy : ram_type;
begin
    r_data_pro : process( all )
    begin
        if en='1' then
            if rewr='0' then
                r_data <= ram_phy(to_integer(unsigned(address)));
            else
                r_data <= (r_data'length-1 downto 0 => 'Z');
            end if ;
        else
            r_data <= (r_data'length-1 downto 0 => 'Z');
        end if ;
    end process ; -- r_data_pro

    w_data_pro : process( all )
    begin
        if en='1' then
            if rewr='0' then
                ram_phy(to_integer(unsigned(address))) <= ram_phy(to_integer(unsigned(address)));
            else
                ram_phy(to_integer(unsigned(address))) <= w_data;
            end if ;
        else
            ram_phy(to_integer(unsigned(address))) <= ram_phy(to_integer(unsigned(address)));
        end if ;
    end process ; -- w_data_pro
end architecture ;