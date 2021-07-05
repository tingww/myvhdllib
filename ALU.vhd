--integer ALU module
--add, subtract, and, or, xor 
--set-less-then, slt-unsigned 
--shift-left-logical, srl, shift-right-arithmetric

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.conf.all;

entity alu is
    port (
        data_i0,data_i1: in std_logic_vector(memwidth-1 downto 0);
        alu_ctrl : in alu_opcode;
        data_o : out std_logic_vector(memwidth-1 downto 0)
    );
end alu;

architecture rtl of alu is
    constant log2memwidth : integer := integer((log2(real(memwidth))));
begin
    process(data_i0,data_i1,alu_ctrl)
        variable d0,d1 : signed(memwidth-1 downto 0);
    begin
        d0 := signed(data_i0);
        d1 := signed(data_i1);
        case alu_ctrl is
        
            when add =>
                data_o <= std_logic_vector(d0+d1);
            when sub =>
                data_o <= std_logic_vector(d0-d1);
            when andd =>
                data_o <= data_i0 and data_i1;
            when orr =>
                data_o <= data_i0 or data_i1;
            when xorr =>
                data_o <= data_i0 xor data_i1;
            when slt =>
                if d0 < d1 then
                    data_o <= (0 => '1', others => '0');
                else
                    data_o <= (others => '0');
                end if;
            when sltu =>
                if unsigned(data_i0) < unsigned(data_i1) then
                    data_o <= (0 => '1', others => '0');
                else
                    data_o <= (others => '0');
                end if;
            when slll =>    --data 0 shift left by lower 5 bits of data 1
                data_o <= data_i0 sll to_integer(unsigned(data_i1(log2memwidth-1 downto 0)));
            when srll =>
                data_o <= data_i0 srl to_integer(unsigned(data_i1(log2memwidth-1 downto 0)));
            when sraa =>
                data_o <= std_logic_vector(d0 sra to_integer(unsigned(data_i1(log2memwidth-1 downto 0))));
            when others =>
                data_o <= (others => '1');
        end case;
    end process;
    
end architecture;