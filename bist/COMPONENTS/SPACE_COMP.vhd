library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity SPACE_COMP is
    port (
        D_in : in std_logic_vector(230 downto 0);
        D_out: out std_logic_vector(63 downto 0)
    );
end entity SPACE_COMP;

architecture rtl of SPACE_COMP is
    type mat_type is array(2 downto 0) of std_logic_vector(230 downto 0);
    signal mat : mat_type;
begin
    
    outer_loop: for i in 0 to 2 generate
        inner_loop: for j in 0 to 230 generate
            first_row: if (i = 0) generate
                place_cond: if(j mod 2 = 0 and j /= 230) generate
                    mat(i)(j)<=D_in(j) xor D_in(j+1);
                end generate place_cond;
            end generate first_row;
            second_row: if (i = 1) generate
                place_cond: if (j mod 4 = 0 and j < 208) generate
                    mat(i)(j)<=mat(i-1)(j) xor mat(i-1)(j+2);
                end generate place_cond;
                transpose: if( j mod 2 = 0 and j >= 208) generate
                    mat(i)(j)<=mat(i-1)(j);
                end generate transpose;    
            end generate second_row;
            compact: if (i=2) generate
                transp_1: if((j<208) and (j mod 4 = 0) ) generate
                    mat(i)(j/4)<=mat(i-1)(j);
                end generate transp_1;
                transp_2: if((j>=208) and (j mod 2 = 0) ) generate
                    mat(i)( ((j-208)/2+52) )<=mat(i-1)(j);
                end generate transp_2;
            end generate compact;
        end generate inner_loop;
        
    end generate outer_loop;

    D_out<=mat(2)(63 downto 0);

    mat(0)(230) <= D_in(230);
    
end architecture rtl;