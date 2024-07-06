LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY mux6to1 IS 
	PORT
	(
		S0 :  IN  STD_LOGIC;
		S1 :  IN  STD_LOGIC;
		S2 :  IN  STD_LOGIC;
		S3 :  IN  STD_LOGIC;
		S4 :  IN  STD_LOGIC;
		S5 :  IN  STD_LOGIC;
		A :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		B :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		C :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		D :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		E :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		F :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		Q :   OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END mux6to1;

ARCHITECTURE bdf_type OF mux6to1 IS 

BEGIN 

Q(0)  <= (A( 0) AND S0) OR (B( 0) AND S1) OR (C( 0) AND S2) OR (D( 0) AND S3) OR (E( 0) AND S4) OR (F( 0) AND S5);
Q(1)  <= (A( 1) AND S0) OR (B( 1) AND S1) OR (C( 1) AND S2) OR (D( 1) AND S3) OR (E( 1) AND S4) OR (F( 1) AND S5);
Q(2)  <= (A( 2) AND S0) OR (B( 2) AND S1) OR (C( 2) AND S2) OR (D( 2) AND S3) OR (E( 2) AND S4) OR (F( 2) AND S5);
Q(3)  <= (A( 3) AND S0) OR (B( 3) AND S1) OR (C( 3) AND S2) OR (D( 3) AND S3) OR (E( 3) AND S4) OR (F( 3) AND S5);
Q(4)  <= (A( 4) AND S0) OR (B( 4) AND S1) OR (C( 4) AND S2) OR (D( 4) AND S3) OR (E( 4) AND S4) OR (F( 4) AND S5);
Q(5)  <= (A( 5) AND S0) OR (B( 5) AND S1) OR (C( 5) AND S2) OR (D( 5) AND S3) OR (E( 5) AND S4) OR (F( 5) AND S5);
Q(6)  <= (A( 6) AND S0) OR (B( 6) AND S1) OR (C( 6) AND S2) OR (D( 6) AND S3) OR (E( 6) AND S4) OR (F( 6) AND S5);
Q(7)  <= (A( 7) AND S0) OR (B( 7) AND S1) OR (C( 7) AND S2) OR (D( 7) AND S3) OR (E( 7) AND S4) OR (F( 7) AND S5);
Q(8)  <= (A( 8) AND S0) OR (B( 8) AND S1) OR (C( 8) AND S2) OR (D( 8) AND S3) OR (E( 8) AND S4) OR (F( 8) AND S5);
Q(9)  <= (A( 9) AND S0) OR (B( 9) AND S1) OR (C( 9) AND S2) OR (D( 9) AND S3) OR (E( 9) AND S4) OR (F( 9) AND S5);
Q(10) <= (A(10) AND S0) OR (B(10) AND S1) OR (C(10) AND S2) OR (D(10) AND S3) OR (E(10) AND S4) OR (F(10) AND S5);
Q(11) <= (A(11) AND S0) OR (B(11) AND S1) OR (C(11) AND S2) OR (D(11) AND S3) OR (E(11) AND S4) OR (F(11) AND S5);
Q(12) <= (A(12) AND S0) OR (B(12) AND S1) OR (C(12) AND S2) OR (D(12) AND S3) OR (E(12) AND S4) OR (F(12) AND S5);
Q(13) <= (A(13) AND S0) OR (B(13) AND S1) OR (C(13) AND S2) OR (D(13) AND S3) OR (E(13) AND S4) OR (F(13) AND S5);
Q(14) <= (A(14) AND S0) OR (B(14) AND S1) OR (C(14) AND S2) OR (D(14) AND S3) OR (E(14) AND S4) OR (F(14) AND S5);
Q(15) <= (A(15) AND S0) OR (B(15) AND S1) OR (C(15) AND S2) OR (D(15) AND S3) OR (E(15) AND S4) OR (F(15) AND S5);

END bdf_type;