library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
library std;
    use std.env.stop;
library txt_util;
    use txt_util.txt_util.all;
library work;
    use work.conf.all;

entity conv_enc_tb is
end conv_enc_tb ; 

architecture arch of conv_enc_tb is
    constant clk_hz : integer := 100e6; --100Mhz
    constant clk_period : time := 1 sec / clk_hz;   --10 ns
    signal clk, rst, en, d_in : std_logic := '0';
    signal d_out : std_logic_vector(1 downto 0) ;
begin
    dut : entity work.conv_enc(rtl)
    generic map(
        memory_element => 2,
        config => (7,5)
    )
    port map (
        clk => clk,
        rst => rst,
        en => en,
        d_in => d_in,
        d_out => d_out
    ); 

    clk <= not clk after clk_period / 2;

    tb_pro : process
        type out_seq_type is array (7 downto 0) of std_logic_vector(1 downto 0) ;
        type truth_table_rec is record
            input_seq : std_logic_vector(7 downto 0);
            out_seq : out_seq_type;
        end record;
        constant truth_table : truth_table_rec := (
            input_seq => "01110100",
            out_seq => ("00","11","01","10","01","00","10","11"));
    begin
        rst <= '1';
        en <= '1';
        d_in <= '0';
        wait for clk_period;
        rst <= '0';
        exhaustive_test : for i in truth_table.input_seq'range loop
            d_in <= truth_table.input_seq(i);
            wait for clk_period/2;
            assert d_out=truth_table.out_seq(i)
                report "Wrong output! d_out : " & str(d_out)
                severity warning;
            wait until clk'event and clk='1';
        end loop ; -- exhaustive_test

        report "End of simlation.";
        stop;       
    end process ; -- tb_pro
end architecture ;