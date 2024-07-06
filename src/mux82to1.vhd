LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY mux82to1 IS 
	PORT
	(
		D :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		S :   IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		Q :   OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
END mux82to1;

ARCHITECTURE bdf_type OF mux82to1 IS 

BEGIN 

WITH ( S ) SELECT
  Q <=
    D(15 DOWNTO 14)   WHEN "000",
    D(13 DOWNTO 12)   WHEN "001",
    D(11 DOWNTO 10)   WHEN "010",
    D( 9 DOWNTO  8)   WHEN "011",
    D( 7 DOWNTO  6)   WHEN "100",
    D( 5 DOWNTO  4)   WHEN "101",
    D( 3 DOWNTO  2)   WHEN "110",
    D( 1 DOWNTO  0)   WHEN "111";

END bdf_type;