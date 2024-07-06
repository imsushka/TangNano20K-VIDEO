LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY mux81to1 IS 
	PORT
	(
		D :   IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		S :   IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		Q :   OUT STD_LOGIC
	);
END mux81to1;

ARCHITECTURE bdf_type OF mux81to1 IS 

BEGIN 

WITH ( S ) SELECT
  Q <=
    D(7)   WHEN "000",
    D(6)   WHEN "001",
    D(5)   WHEN "010",
    D(4)   WHEN "011",
    D(3)   WHEN "100",
    D(2)   WHEN "101",
    D(1)   WHEN "110",
    D(0)   WHEN "111";

END bdf_type;