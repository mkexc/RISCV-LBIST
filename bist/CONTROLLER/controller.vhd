library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.constants.all;

entity controller is
    generic (
        GOLDEN_SIGNATURE : std_logic_vector(N_MISR-1 downto 0)
    );
    port (
        clk, rst, TEST : in std_logic;
        MISR_OUT: in std_logic_vector(N_MISR-1 downto 0);
        SEED_ADDR: out std_logic_vector(3 downto 0);
        GO, TPG_MUX_en, ODE_en, END_TEST, TPG_LD, SCAN_EN, DUT_RESET, LFSR_MISR_RESET: out std_logic
    );
end entity controller;

architecture rtl of controller is
    type StateType is (S_init, S_Wait, S_TRST, S_Seed, S_lo_unlo, S_Capt, S_end);
    signal currState, nextState: StateType;

    signal currCnt, nextCnt : std_logic_vector(5 downto 0);
    signal currCycles, nextCycles : std_logic_vector(6 downto 0);
    signal currRes, nextRes : std_logic_vector(3 downto 0);
    
begin
    
    regs: process(clk)
    begin
        if (rising_edge(clk)) then
            if rst='1' then
                currState<=S_init;
                currRes<=(others => '0');
                currCnt<=(others => '0');
                currCycles<=(others => '0');
            else 
                currState<=nextState;
                currRes<=nextRes;
                currCnt<=nextCnt;
                currCycles<=nextCycles;
            end if;
        end if;
    end process regs;
    
    comb: process(currState,currRes,currCnt,currCycles,TEST,MISR_OUT)
    begin
        GO<='0'; TPG_MUX_en<='0'; ODE_en<='0'; END_TEST <= '0'; -- normal inputs/ LFSR and MISR disabled
        LFSR_MISR_RESET<='0'; DUT_RESET <= '1'; TPG_LD<='0'; SCAN_EN <= '0';
        case currState is
            when S_init =>
                nextState<=S_Wait;
                nextRes<=(others => '0');
                nextCnt<=(others => '0');
                nextCycles<=(others => '0');
            when S_Wait => 
                if(TEST = '1') then
                    nextState<=S_TRST; 
                else
                    nextState<=S_Wait;
                end if;
                nextRes<=(others => '0');
                nextCnt<=(others => '0');
                nextCycles<=(others => '0');
            when S_TRST =>
                SCAN_EN <= '1';
                TPG_MUX_en<='1';
                LFSR_MISR_RESET<='1'; 
                DUT_RESET <= '0';
                if(TEST = '0') then
                    nextState<=S_wait;
                else 
                    nextState<=S_Seed;
                end if;
                nextRes<=(others => '0');
                nextCnt<=(others => '0');
                nextCycles<=(others => '0');
            when S_Seed => 
                TPG_LD<='1';
                SCAN_EN <= '1';
                TPG_MUX_en<='1';
                nextRes<=std_logic_vector(unsigned(currRes)+1);
                nextCnt<=(others => '0');
                nextCycles<=(others => '0');
                if(TEST = '0') then
                    nextState<=S_wait;
                else 
                    nextState<=S_lo_unlo;
                end if;
            when S_lo_unlo =>
                SCAN_EN <= '1';
                TPG_MUX_en<='1';
                if(unsigned(currRes) = 1 and unsigned(currCycles) = 0) then
                    ODE_en<='0';
                else
                    ODE_en<='1';
                end if;
                nextRes<=currRes;
                nextCnt<=std_logic_vector(unsigned(currCnt)+1);
                nextCycles<=currCycles;
                if (TEST = '1' and unsigned(currCnt) < 49) then
                    nextState<=S_lo_unlo;
                elsif (TEST = '1' and unsigned(currCnt)>=49) then
                    nextState<=S_Capt;
                else
                    nextState<=S_Wait;
                end if;
            when S_Capt =>
                SCAN_EN <= '0';
                TPG_MUX_en<='1';
                ODE_en<='1';
                nextRes<=currRes;
                nextCnt<=(others => '0');
                nextCycles<=std_logic_vector(unsigned(currCycles)+1);
                if(TEST = '0') then
                    nextState<=S_wait;
                elsif(unsigned(currCycles)<64) then
                    nextState<=S_lo_unlo;
                elsif(unsigned(currCycles)>=64 and unsigned(currRes)<12) then
                    nextState<=S_Seed;
                else
                    nextState<=S_end;
                end if;
            when S_end =>
                END_TEST <= '1';
                nextRes<=(others => '0');
                nextCnt<=(others => '0');
                nextCycles<=(others => '0');
                if (MISR_OUT = GOLDEN_SIGNATURE) then
                    GO<='1';
                end if;
                nextState<=S_wait;
            when others =>
                nextState<=S_init;
                nextRes<=(others => '0');
                nextCnt<=(others => '0');
                nextCycles<=(others => '0');
        end case;
    end process comb;
    
    SEED_ADDR<=currRes;

end architecture rtl;