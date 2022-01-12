library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity tb_controller is
end entity tb_controller;

architecture rtl of tb_controller is
    component controller is
        generic (
            GOLDEN_SIGNATURE : std_logic_vector(N_MISR-1 downto 0)
        );
        port (
            clk, rst, TEST : in std_logic;
            MISR_OUT: in std_logic_vector(N_MISR-1 downto 0);
            SEED_ADDR: out std_logic_vector(3 downto 0);
            GO, TPG_MUX_en, ODE_en, END_TEST, TPG_LD, SCAN_EN, DUT_RESET, LFSR_MISR_RESET: out std_logic
        );
    end component controller;

    component ROM is
        port (
            addr: in std_logic_vector(3 downto 0);
            dout: out std_logic_vector(N_LFSR-1 downto 0)
        );
    end component ROM;

    signal clk_s,rst_s,TEST_s,GO_s,TPG_MUX_en_s, ODE_en_s, END_TEST_s, TPG_LD_s, SCAN_EN_s, DUT_RESET_s, LFSR_MISR_RESET_s : std_logic;
    signal MISR_OUT_s : std_logic_vector(N_MISR-1 downto 0);
    signal ROM_OUT_s : std_logic_vector(N_LFSR-1 downto 0);
    signal SEED_ADDR_s : std_logic_vector(3 downto 0);
    constant clkper : time := 20 ns;
begin
    
    ctlr: controller 
    generic map (
        GOLDEN_SIGNATURE => "0101010100101010101001010101001010101010010101010010011010101010"
    )
    port map (
        clk=>clk_s,
        rst=>rst_s,
        TEST=>TEST_s,
        MISR_OUT=>MISR_OUT_s,
        SEED_ADDR=>SEED_ADDR_s,
        GO=>GO_s,
        TPG_MUX_en=>TPG_MUX_en_s,
        ODE_en=>ODE_en_s,
        END_TEST=>END_TEST_s,
        TPG_LD=>TPG_LD_s,
        SCAN_EN=>SCAN_EN_s,
        DUT_RESET=>DUT_RESET_s,
        LFSR_MISR_RESET=>LFSR_MISR_RESET_s
    );
    
    rom_i: ROM 
    port map(
        addr=>SEED_ADDR_s,
        dout=>ROM_OUT_s
    );

    clkgen: process 
    begin
        clk_s<='0';
        wait for clkper/2;
        clk_s<='1';
        wait for clkper/2;
    end process clkgen;

    testvect: process
    begin
        rst_s<='1'; TEST_s<='0'; 
        MISR_OUT_s<="0100101010011100100010110001010100010010010101001010101001010010";
        wait for clkper;
        rst_s<='0';
        wait for 2*clkper;
        TEST_s<='1';
        MISR_OUT_s<="0101010100101010101001010101001010101010010101010010011010101010";
        wait until END_TEST_s='1';
        assert GO_s='1' report "ERROR NO GO";
        TEST_s<='0';
        wait for clkper;
        wait;
    end process;

end architecture rtl;