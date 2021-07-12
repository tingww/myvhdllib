--convolutional encoder
--enable: high active, reset: high active
--default to (7,5) configuration
--physical connection of d_in is the LSB of the binary representation of elements in config
--
--     ---------------xor----------xor------d_out(0)
--     |               |            |
---d_in-----|reg0|---------|reg1|----
--     |                            |
--     ----------------------------xor------d_out(1)
--
library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
library work;
    use work.conf.all;

entity conv_enc is
    generic(
        constant memory_element : natural := 2;
        constant numbers_of_gen : natural := 2;
        constant config : natural_arr(numbers_of_gen-1 downto 0) := (7,5)
    );
    port (
        clk,rst,d_in,en : in std_logic;
        d_out : out std_logic_vector(config'length-1 downto 0)
    ) ;
end conv_enc ; 

architecture rtl of conv_enc is
    component shift_reg is 
    generic(
        size : natural 
    );
    port(
        clk,rst,d,ce : in std_logic;
        q,qn : out std_logic_vector(memory_element-1 downto 0)
    );
    end component;
    signal q : std_logic_vector(memory_element-1 downto 0) ;
    signal d : std_logic;
begin
    shift_reg_0 : shift_reg 
    generic map (
        size => memory_element
    )
    port map (
        clk => clk,
        rst => rst,
        d => d_in,
        ce => en,
        q => q,
        qn => open
    );
    output_pro : process( all ) 
        variable bin_rep : unsigned(memory_element downto 0);
        variable out_temp : std_logic := '0';
    begin
        out_gen: for i in numbers_of_gen-1 downto 0 loop  --loop through every elements in config
            bin_rep := to_unsigned(config(i) , bin_rep'length);
            out_temp := '0';
            sweep_config: for j in 0 to memory_element loop --loop through every bit of the binary representation
                if j=0 and bin_rep(j)='1' then
                    out_temp := out_temp xor d_in;
                elsif bin_rep(j)='1' then
                    out_temp := out_temp xor q(j-1);
                end if ;
            end loop sweep_config;
            d_out(i) <= out_temp;
        end loop out_gen;
    end process ; -- output_pro

end architecture ;

configuration myconf of conv_enc is
    
    for rtl 
        for shift_reg_0 : shift_reg use entity work.shift_reg(rtl);
        end for;
    end for;
    
end configuration myconf;