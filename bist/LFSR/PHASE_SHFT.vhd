library IEEE;
use IEEE.std_logic_1164.all; 

entity PHASE_SHFT is
	GENERIC (
		N: integer := 64
	);
	PORT(
		LFSR_OUT: IN std_logic_vector(N-1 DOWNTO 0);
		PH_SHFT_O: OUT std_logic_vector(N-1 DOWNTO 0)
	);
end PHASE_SHFT;

architecture Beh of PHASE_SHFT is
begin
	process(LFSR_OUT)
		begin
			for i in 0 to N-1 loop
				if i = (N-1) then
					PH_SHFT_O(i) <= LFSR_OUT(i) XOR LFSR_OUT(0);
				else
					PH_SHFT_O(i) <= LFSR_OUT(i) XOR LFSR_OUT(i+1);
				end if;
			end loop;
	end process;
end Beh;

configuration CFG_PHASE_SHFT of PHASE_SHFT is
   for Beh
   end for;
end CFG_PHASE_SHFT;
