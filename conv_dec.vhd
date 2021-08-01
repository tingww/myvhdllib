--viterbi algorithm convolutional decoder
--states: idle, initialization, full_piped, termination
--default to (2,1,3) convolutional decoder with generator (7,5), Lc=8
--
-- default encoder state transition
--state---------in/out------next state
-- 00 -----------0/00---------- 00
-- 00 -----------1/11---------- 10
-- 10 -----------1/01---------- 11
-- 10 -----------0/10---------- 01
-- 11 -----------1/10---------- 11
-- 11 -----------0/01---------- 01
-- 01 -----------1/10---------- 10
-- 01 -----------0/11---------- 00

library ieee ;
    use ieee.std_logic_1164.all ;
    use ieee.numeric_std.all ;
library work;
    use work.conv_dec_pack.all;

entity conv_dec is
    port (
        enable : in std_logic;
        clk,rst : in std_logic;
        d_in : in std_logic_vector(generator_num-1 downto 0) ;
        d_out : out std_logic;
        valid_out : out std_logic
    ) ;
end conv_dec ; 

architecture rtl of conv_dec is
    component bmu is 
    port (
        d_in : in std_logic_vector(generator_num-1 downto 0);
        branch_metrics : out b_m_rec
    );
    end component;
    component acsu is 
    port (
        clk,rst,en : in std_logic;  
        branch_metrics : in b_m_rec;
        path_matrix_entry : out pme_arr;
        acm : out acm_arr
    );
    end component;
    component tbu is 
    port (
        clk,rst : in std_logic;
        path_matrix_entry : in pme_arr;
        acm : in acm_arr;
        d_out : out std_logic;
        valid_out : out std_logic;
        start : in std_logic;
        terminate : in std_logic 
    );
    end component;

    signal branch_metrics : b_m_rec;
    signal path_matrix_entry : pme_arr;
    signal acm : acm_arr;
    signal en,start,terminate : std_logic;
    signal counter_delay_nxt,counter_delay : unsigned(0 downto 0);
    constant acsu_delay_u : unsigned(0 downto 0) := to_unsigned(acsu_delay, counter_delay'length);
begin
    bmu0 : bmu
    port map(
        d_in => d_in,
        branch_metrics => branch_metrics
    );

    acsu0 : acsu 
    port map(
        clk => clk,
        rst => rst,
        en => en,  
        branch_metrics => branch_metrics,
        path_matrix_entry => path_matrix_entry,
        acm => acm
    );

    tbu0 : tbu
    port map(
        clk => clk,
        rst => rst,
        path_matrix_entry => path_matrix_entry,
        acm => acm,
        d_out => d_out,
        valid_out => valid_out,
        start => start,
        terminate => terminate
    );

    en <= enable;
    start <= enable;
    terminate <= not enable;



end architecture ;

configuration conv_dec_conf0 of conv_dec is
    for rtl 
        for all  : bmu use entity work.bmu(rtl);
        end for;
        for all  : acsu use entity work.acsu(rtl);
        end for;
        for all  : tbu use entity work.tbu(rtl);
        end for;
    end for;    
end configuration conv_dec_conf0;