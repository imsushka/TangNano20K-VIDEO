LIBRARY ieee;
USE ieee.std_logic_1164.all; 

LIBRARY work;

ENTITY comp1024x768 IS 
	PORT
	(
		CLK :	 IN  STD_LOGIC;
		RST :	 IN  STD_LOGIC;
		H :      IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
		V :      IN  STD_LOGIC_VECTOR(11 DOWNTO 0);

		HSync  : OUT  STD_LOGIC;
		VSync  : OUT  STD_LOGIC;

		BLANK  : OUT  STD_LOGIC;

		HBLANK : OUT  STD_LOGIC;
		VBLANK : OUT  STD_LOGIC;

		HReset : OUT  STD_LOGIC;
		VReset : OUT  STD_LOGIC
	);
END comp1024x768;

ARCHITECTURE bdf_type OF comp1024x768 IS 

SIGNAL	HBSync      :  STD_LOGIC;
SIGNAL	HEnd        :  STD_LOGIC;
SIGNAL	HEndVisible :  STD_LOGIC;
SIGNAL	HESync      :  STD_LOGIC;
SIGNAL	HB          :  STD_LOGIC;
SIGNAL	HS          :  STD_LOGIC;
SIGNAL	H_B         :  STD_LOGIC;
SIGNAL	H_S         :  STD_LOGIC;
SIGNAL	VBSync      :  STD_LOGIC;
SIGNAL	VEnd        :  STD_LOGIC;
SIGNAL	VEndVisible :  STD_LOGIC;
SIGNAL	VESync      :  STD_LOGIC;
SIGNAL	VB          :  STD_LOGIC;
SIGNAL	VS          :  STD_LOGIC;
SIGNAL	V_B         :  STD_LOGIC;
SIGNAL	V_S         :  STD_LOGIC;

BEGIN
-- Horisontal
-- End of visible							-- $400 - 1024
HEndVisible <= NOT(H(3))  AND NOT(H(2))  AND NOT(H(1)) AND NOT(H(0)) AND	-- 0000
               NOT(H(7))  AND NOT(H(6))  AND NOT(H(5)) AND NOT(H(4)) AND	-- 0000
               NOT(H(11)) AND    (H(10)) AND NOT(H(9)) AND NOT(H(8));		-- 0100

-- Start sync								-- $4A0 - 1184
HBSync      <= NOT(H(3))  AND NOT(H(2))  AND NOT(H(1)) AND NOT(H(0)) AND	-- 0000
                  (H(7))  AND NOT(H(6))  AND    (H(5)) AND NOT(H(4)) AND	-- 1010
               NOT(H(11)) AND    (H(10)) AND NOT(H(9)) AND NOT(H(8));		-- 0100

-- End sync								-- $528 - 1320
HESync      <=    (H(3))  AND NOT(H(2))  AND NOT(H(1)) AND NOT(H(0)) AND	-- 1000
               NOT(H(7))  AND NOT(H(6))  AND    (H(5)) AND NOT(H(4)) AND	-- 0010
               NOT(H(11)) AND    (H(10)) AND NOT(H(9)) AND    (H(8));		-- 0101

-- End of count								-- $540 - 1344
HEnd        <= NOT(H(3))  AND NOT(H(2))  AND NOT(H(1)) AND NOT(H(0)) AND	-- 0000
               NOT(H(7))  AND    (H(6))  AND NOT(H(5)) AND NOT(H(4)) AND	-- 0100
               NOT(H(11)) AND    (H(10)) AND NOT(H(9)) AND    (H(8));		-- 0101

-- Vertical
-- End of visible							-- $300 - 768
VEndVisible <= NOT(V(3))  AND NOT(V(2))  AND NOT(V(1)) AND NOT(V(0)) AND	-- 0000
               NOT(V(7))  AND NOT(V(6))  AND NOT(V(5)) AND NOT(V(4)) AND	-- 0000
               NOT(V(11)) AND NOT(V(10)) AND    (V(9)) AND    (V(8));		-- 0011

-- Start sync								-- $31D - 797
VBSync      <=    (V(3))  AND    (V(2))  AND NOT(V(1)) AND    (V(0)) AND	-- 1101
               NOT(V(7))  AND NOT(V(6))  AND NOT(V(5)) AND    (V(4)) AND	-- 0001
               NOT(V(11)) AND NOT(V(10)) AND    (V(9)) AND    (V(8));		-- 0011

-- End sync								-- $323 - 803
VESync      <= NOT(V(3))  AND NOT(V(2))  AND    (V(1)) AND    (V(0)) AND	-- 0011
               NOT(V(7))  AND NOT(V(6))  AND    (V(5)) AND NOT(V(4)) AND	-- 0010
               NOT(V(11)) AND NOT(V(10)) AND    (V(9)) AND    (V(8));		-- 0011

-- End of count								-- $326 - 806
VEnd        <= NOT(V(3))  AND    (V(2))  AND    (V(1)) AND NOT(V(0)) AND	-- 0110
               NOT(V(7))  AND NOT(V(6))  AND    (V(5)) AND NOT(V(4)) AND	-- 0010
               NOT(V(11)) AND NOT(V(10)) AND    (V(9)) AND    (V(8));		-- 0011

PROCESS(CLK, RST, HEndVisible, HEnd)
BEGIN
  IF (RST = '0') THEN
    HB       <= '0';
  ELSIF (RISING_EDGE(CLK)) THEN
    IF ( HEndVisible = '1' ) THEN
      HB       <= '0';
    END IF;
    IF ( HEnd = '1' ) THEN
      HB       <= '1';
    END IF;
  END IF;
END PROCESS;

PROCESS(CLK, RST, HBSync, HESync)
BEGIN
  IF (RST = '0') THEN
    HS       <= '1';
  ELSIF (RISING_EDGE(CLK)) THEN
    IF ( HBSync = '1' ) THEN
      HS       <= '0';
    END IF;
    IF ( HESync = '1' ) THEN
      HS       <= '1';
    END IF;
  END IF;
END PROCESS;

PROCESS(CLK, RST, VEndVisible, VEnd)
BEGIN
  IF (RST = '0') THEN
    VB       <= '0';
  ELSIF (RISING_EDGE(CLK)) THEN
    IF ( VEndVisible = '1' ) THEN
      VB       <= '0';
    END IF;
    IF ( VEnd = '1' ) THEN
      VB       <= '1';
    END IF;
  END IF;
END PROCESS;

PROCESS(CLK, RST, VBSync, VESync)
BEGIN
  IF (RST = '0') THEN
    VS       <= '1';
  ELSIF (RISING_EDGE(CLK)) THEN
    IF ( VBSync = '1' ) THEN
      VS       <= '0';
    END IF;
    IF ( VESync = '1' ) THEN
      VS       <= '1';
    END IF;
  END IF;
END PROCESS;

--PROCESS(CLK, RST)
--BEGIN
--IF (RST = '0') THEN
--	HSync       <= '1';
--	VSync       <= '1';

--	BLANK       <= '0';
--	HReset      <= '0';
--	VReset      <= '0';
--ELSIF (RISING_EDGE(CLK)) THEN
--	HSync       <= NOT(HS);
--	VSync       <= NOT(VS);

--	BLANK       <= HB AND VB;
--	HReset      <= NOT(HEnd);
--	VReset      <= NOT(VEnd);
--END IF;
--END PROCESS;

HSync       <= HS;
VSync       <= VS;

BLANK       <= HB AND VB;
HBLANK      <= HB;
VBLANK      <= VB;

HReset      <= NOT(HEnd);
VReset      <= NOT(VEnd);

END bdf_type;