library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use std.textio.all;
use std.env.finish;

library osvvm;
use osvvm.randompkg.all;

use work.conf.all;

entity ALU_tb is
end ALU_tb;

architecture sim of ALU_tb is
    signal data_i0, data_i1, data_o : std_logic_vector(memwidth-1 downto 0) := (others => '0');
    signal alu_ctrl : alu_opcode;
begin
    DUT : entity work.ALU(rtl)
    port map (
        data_i0,data_i1,alu_ctrl,data_o
    );
    PROC : process is
        --variable RV : RandomPType ;
    begin
        --RV.InitSeed (1000);
        data_i0 <= std_logic_vector(to_signed( -2, data_i0'length));
        data_i1 <= std_logic_vector(to_signed( 1, data_i1'length));
        alu_ctrl <= slt;
        wait for 10 ns;
        assert data_o = std_logic_vector(to_signed( 1, data_i1'length))
            report "Something went wrong..." ;

        data_i0 <= std_logic_vector(to_signed( -1, data_i0'length));
        data_i1 <= std_logic_vector(to_signed( -2, data_i1'length));
        alu_ctrl <= sltu;
        wait for 10 ns;
        assert data_o = std_logic_vector(to_signed( 0, data_i1'length))
            report "Something went wrong..." ;

        data_i0 <= std_logic_vector(to_signed( -2, data_i0'length));
        data_i1 <= std_logic_vector(to_signed( 1, data_i1'length));
        alu_ctrl <= sraa;
        wait for 10 ns;
        assert data_o = std_logic_vector(to_signed( -1, data_i1'length))
            report "Something went wrong..." ;
        report to_string( integer((log2(real(32))) ));
        
        
        finish;
    end process;
end architecture;