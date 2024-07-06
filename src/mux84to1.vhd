LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY mux84to1 IS 
	PORT
	(
		Dl :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		Dh :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		S :   IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		Q :   OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END mux84to1;

ARCHITECTURE bdf_type OF mux84to1 IS 

BEGIN 

WITH ( S ) SELECT
  Q <=
    Dl(15 DOWNTO 12)   WHEN "000",
    Dl(11 DOWNTO  8)   WHEN "001",
    Dl( 7 DOWNTO  4)   WHEN "010",
    Dl( 3 DOWNTO  0)   WHEN "011",
    Dh(15 DOWNTO 12)   WHEN "100",
    Dh(11 DOWNTO  8)   WHEN "101",
    Dh( 7 DOWNTO  4)   WHEN "110",
    Dh( 3 DOWNTO  0)   WHEN "111";

END bdf_type;