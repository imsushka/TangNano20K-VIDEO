LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

LIBRARY work;

ENTITY SYNCH IS 
	PORT
	(
		CLK     :  IN  STD_LOGIC;
		RESET_n :  IN  STD_LOGIC;

		H       : OUT  STD_LOGIC_VECTOR(11 DOWNTO 0);
		V       : OUT  STD_LOGIC_VECTOR(11 DOWNTO 0);

		HACTIVE : OUT  STD_LOGIC;
		VACTIVE : OUT  STD_LOGIC;

		HSYNC   : OUT  STD_LOGIC;
		VSYNC   : OUT  STD_LOGIC;
		BLANK   : OUT  STD_LOGIC
	);
END SYNCH;

ARCHITECTURE bdf_type OF SYNCH IS 

BEGIN 
-------------------------------------------------------------------------------
-- Synchro 
-------------------------------------------------------------------------------
PROCESS(CLK, RESET_n)

variable vH    : STD_LOGIC_VECTOR(11 DOWNTO 0);
variable vV    : STD_LOGIC_VECTOR(11 DOWNTO 0);

variable vHx   : STD_LOGIC_VECTOR(11 DOWNTO 0);
variable vVy   : STD_LOGIC_VECTOR(11 DOWNTO 0);

variable vHACTIVE  : STD_LOGIC;
variable vVACTIVE  : STD_LOGIC;

BEGIN
-------------------------------------------------------------------------------
-- Horisontal & Vertical counters
-------------------------------------------------------------------------------
  IF ( RESET_n = '0' ) THEN
    vH := (OTHERS => '0');
    vV := (OTHERS => '0');
  ELSIF ( RISING_EDGE(CLK) ) THEN
    vH := vH + 1;
    IF ( vH = 1344 ) THEN
      vH := (OTHERS => '0');
      vV := vV + 1;
      IF ( vV = 806 ) THEN
        vV := (OTHERS => '0');
      END IF;
    END IF;
  END IF;
-------------------------------------------------------------------------------
-- HSync, VSync & Blank
-------------------------------------------------------------------------------
  IF ( vH < 1071 AND vVACTIVE = '1' ) THEN
    vHx  := vH;
  ELSE
    vHx  := (OTHERS => '0');
  END IF;

  IF ( 7 < vH AND vH < 1024+7 ) THEN
    vHACTIVE := '1';
  ELSE
    vHACTIVE := '0';
  END IF;

  IF ( vV < 768 ) THEN
    vVACTIVE := '1';
    vVy  := vV;
  ELSE
    vVACTIVE := '0';
    vVy  := (OTHERS => '0');
  END IF;

  IF ( vH > 1023+160+16 AND vH < 1024+160+135+16 ) THEN
    HSync <= '1';
  ELSE
    HSync <= '0';
  END IF;

  IF ( vV > 767+29 AND vV < 767+29+5 ) THEN
    VSync <= '1';
  ELSE
    VSync <= '0';
  END IF;
-------------------------------------------------------------------------------
  H <= vHx;
  V <= vVy;

  HACTIVE <= vHACTIVE;
  VACTIVE <= vVACTIVE;
  BLANK   <= vHACTIVE AND vVACTIVE;
-------------------------------------------------------------------------------
END PROCESS;

END bdf_type;
