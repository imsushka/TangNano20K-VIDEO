LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY mux4to1 IS 
	PORT
	(
		Sa :  IN  STD_LOGIC;
		Sb :  IN  STD_LOGIC;
		Sc :  IN  STD_LOGIC;
		Sd :  IN  STD_LOGIC;
		A :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		B :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		C :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		D :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		Q :   OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END mux4to1;

ARCHITECTURE bdf_type OF mux4to1 IS 

BEGIN 

Q(0)  <= (A( 0) AND Sa) OR (B( 0) AND Sb) OR (C( 0) AND Sc) OR (D( 0) AND Sd);
Q(1)  <= (A( 1) AND Sa) OR (B( 1) AND Sb) OR (C( 1) AND Sc) OR (D( 1) AND Sd);
Q(2)  <= (A( 2) AND Sa) OR (B( 2) AND Sb) OR (C( 2) AND Sc) OR (D( 2) AND Sd);
Q(3)  <= (A( 3) AND Sa) OR (B( 3) AND Sb) OR (C( 3) AND Sc) OR (D( 3) AND Sd);
Q(4)  <= (A( 4) AND Sa) OR (B( 4) AND Sb) OR (C( 4) AND Sc) OR (D( 4) AND Sd);
Q(5)  <= (A( 5) AND Sa) OR (B( 5) AND Sb) OR (C( 5) AND Sc) OR (D( 5) AND Sd);
Q(6)  <= (A( 6) AND Sa) OR (B( 6) AND Sb) OR (C( 6) AND Sc) OR (D( 6) AND Sd);
Q(7)  <= (A( 7) AND Sa) OR (B( 7) AND Sb) OR (C( 7) AND Sc) OR (D( 7) AND Sd);
Q(8)  <= (A( 8) AND Sa) OR (B( 8) AND Sb) OR (C( 8) AND Sc) OR (D( 8) AND Sd);
Q(9)  <= (A( 9) AND Sa) OR (B( 9) AND Sb) OR (C( 9) AND Sc) OR (D( 9) AND Sd);
Q(10) <= (A(10) AND Sa) OR (B(10) AND Sb) OR (C(10) AND Sc) OR (D(10) AND Sd);
Q(11) <= (A(11) AND Sa) OR (B(11) AND Sb) OR (C(11) AND Sc) OR (D(11) AND Sd);
Q(12) <= (A(12) AND Sa) OR (B(12) AND Sb) OR (C(12) AND Sc) OR (D(12) AND Sd);
Q(13) <= (A(13) AND Sa) OR (B(13) AND Sb) OR (C(13) AND Sc) OR (D(13) AND Sd);
Q(14) <= (A(14) AND Sa) OR (B(14) AND Sb) OR (C(14) AND Sc) OR (D(14) AND Sd);
Q(15) <= (A(15) AND Sa) OR (B(15) AND Sb) OR (C(15) AND Sc) OR (D(15) AND Sd);

END bdf_type;