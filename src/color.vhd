LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY color_sel IS 
	PORT
	(
		COLOR :  IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		RGB   :  OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
	);
END color_sel;

ARCHITECTURE bdf_type OF color_sel IS 

BEGIN 

    WITH ( COLOR ) SELECT RGB <=
        "000" & "000" & "000"    WHEN "0000",
        "000" & "000" & "011"    WHEN "0001",
        "000" & "011" & "000"    WHEN "0010",
        "000" & "011" & "011"    WHEN "0011",
        "011" & "000" & "000"    WHEN "0100",
        "011" & "000" & "011"    WHEN "0101",
        "011" & "011" & "000"    WHEN "0110",
        "011" & "011" & "011"    WHEN "0111",
        "100" & "111" & "010"    WHEN "1000",
        "000" & "000" & "111"    WHEN "1001",
        "000" & "111" & "000"    WHEN "1010",
        "000" & "111" & "111"    WHEN "1011",
        "111" & "000" & "000"    WHEN "1100",
        "111" & "000" & "111"    WHEN "1101",
        "111" & "111" & "000"    WHEN "1110",
        "111" & "111" & "111"    WHEN "1111";

--    WITH ( COLOR ) SELECT RGB <=
--        PAL_REG0                 WHEN "0000",
--        PAL_REG1                 WHEN "0001",
--        PAL_REG2                 WHEN "0010",
--        PAL_REG3                 WHEN "0011",
--        PAL_REG4                 WHEN "0100",
--        PAL_REG5                 WHEN "0101",
--        PAL_REG6                 WHEN "0110",
--        PAL_REG7                 WHEN "0111",
--        PAL_REG8                 WHEN "1000",
--        PAL_REG9                 WHEN "1001",
--        PAL_REGA                 WHEN "1010",
--        PAL_REGB                 WHEN "1011",
--        PAL_REGC                 WHEN "1100",
--        PAL_REGD                 WHEN "1101",
--        PAL_REGE                 WHEN "1110",
--        PAL_REGF                 WHEN "1111";

END bdf_type;