LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

LIBRARY work;

ENTITY VGA IS 
	PORT
	(
		CLK     :  IN  STD_LOGIC;
		RESET_n :  IN  STD_LOGIC;

		CONTROL :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HSCROLL :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VSCROLL :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HCURSOR :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VCURSOR :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

		H       :  IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
		V       :  IN  STD_LOGIC_VECTOR(11 DOWNTO 0);

		BLANK   :  IN  STD_LOGIC;
		COLOR   : OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		PALETTE : OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);

		VDi     :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		VA      : OUT  STD_LOGIC_VECTOR(16 DOWNTO 0);
		VOE     : OUT  STD_LOGIC
	);
END VGA;

ARCHITECTURE bdf_type OF VGA IS 

SIGNAL	DOTCLK     : STD_LOGIC;
SIGNAL	DOTBLANK   : STD_LOGIC;
SIGNAL	DOTStep    : STD_LOGIC_VECTOR(2 DOWNTO 0);

SIGNAL	F08x08     : STD_LOGIC;
SIGNAL	F08x16     : STD_LOGIC;
SIGNAL	F16x08     : STD_LOGIC;
SIGNAL	F16x16     : STD_LOGIC;
SIGNAL	F16x32     : STD_LOGIC;
SIGNAL	F32x16     : STD_LOGIC;
SIGNAL	F32x32     : STD_LOGIC;
SIGNAL	GRAF       : STD_LOGIC;

SIGNAL	SCALE_x1   : STD_LOGIC;
SIGNAL	SCALE_x2   : STD_LOGIC;
SIGNAL	SCALE_x4   : STD_LOGIC;
--SIGNAL	SCALE_x8   : STD_LOGIC;

SIGNAL	F08Pix     : STD_LOGIC;
SIGNAL	F16Pix     : STD_LOGIC;
SIGNAL	F32Pix     : STD_LOGIC;
SIGNAL	F08Line    : STD_LOGIC;
SIGNAL	F16Line    : STD_LOGIC;
SIGNAL	F32Line    : STD_LOGIC;
SIGNAL	MFONT      : STD_LOGIC;
SIGNAL	EXTATR     : STD_LOGIC;
SIGNAL	EXTATRF    : STD_LOGIC;

SIGNAL	FONT_1bit  : STD_LOGIC;
SIGNAL	FONT_2bit  : STD_LOGIC;
SIGNAL	FONT_4bit  : STD_LOGIC;
SIGNAL	FONT_1bitE : STD_LOGIC;

SIGNAL	FONT_ROW0  : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW1  : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW2  : STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	HByte      : STD_LOGIC;
SIGNAL	HFlip      : STD_LOGIC;
SIGNAL	CURSOR     : STD_LOGIC;

BEGIN 
-------------------------------------------------------------------------------
-- 0x00000 - 0x07FFF = 32768 WORDS screen buffer
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Resolution        1024 x 768
--
-- Virtual screen     256 x 128 = 32768 words
--
--MEM_SCR_08x08x1 --  128 x  96 = 12288
--MEM_SCR_08x08x2 --   64 x  48 =  3072
--MEM_SCR_08x08x4 --   32 x  24 =   768

--MEM_SCR_08x16x1 --  128 x  48 =  6144
--MEM_SCR_16x08x1 --   64 x  96 =  6144

--MEM_SCR_16x16x1 --   64 x  48 =  3072
--MEM_SCR_16x16x2 --   32 x  24 =   768
--MEM_SCR_16x16x4 --   16 x  12 =   192

--MEM_SCR_16x32x1 --   64 x  24 =  1536
--MEM_SCR_32x16x1 --   32 x  48 =  1536
--MEM_SCR_32x32x1 --   32 x  24 =   768
-------------------------------------------------------------------------------
--MEM_SCR_GRAFx1  -- 1024 x 768 = 98304 bytes
--MEM_SCR_GRAFx2  --  512 x 384 = 49152
--MEM_SCR_GRAFx4  --  256 x 192 = 24576
-------------------------------------------------------------------------------
-- Mode 08x08 and 08x16 1bitE ( 8 bit font )
-- attribute bits
-- 3-0 - not used
-- 5-4 - 4 font table (1024 chars)
-- 6   - H flip
-- 7   - V flip
--
-- Mode 08x08 and 08x16 2bit ( 16 bit font )
-- attribute bits
-- 3-0 - 16 colors palets, 4 color eath
-- 5-4 - 4 font table (1024 chars)
-- 6   - H flip
-- 7   - V flip
--
-- Mode 16x08 and 16x16 2bit ( 32 bit font )
-- attribute bits
-- 3-0 - 16 colors palets, 4 color eath
-- 4   - not used
-- 5   - 2 font table (512 chars)
-- 6   - H flip
-- 7   - V flip
--
-- Mode 08x08 and 08x16 4bit ( 32 bit font )
-- attribute bits
-- 4-0 - not used
-- 5   - 2 font table (512 chars)
-- 6   - H flip
-- 7   - V flip
--
-- Mode 16x08 and 16x16 4bit ( 64 bit font )
-- attribute bits
-- 5-0 - not used
-- 6   - H flip
-- 7   - V flip
--
-- Mode 16x32 and 32x32 2bit ( 32/64 bit font )
-- attribute bits
-- 3-0 - 16 colors palets, 4 color eath
-- 5-4 - not used
-- 6   - H flip
-- 7   - V flip
--
-- Mode 16x32 and 32x32 4bit ( 64/128 bit font )
-- attribute bits
-- 5-0 - not used
-- 6   - H flip
-- 7   - V flip
--
-------------------------------------------------------------------------------
-- Sprite
--
-- 1st word
--  9- 0 Y
-- 11-10 Prio
-- 15-12 Char lo
--
-- 2nd word
-- 10- 0 X
-- 11    
-- 15-12 Char hi
--
-- 3rd word
--  7- 0 Color
--  9- 8 Bits
-- 12-10 Size 8x8 / 16x16 /32x32
-- 13
-- 14    H flip
-- 15    V flip 
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- STATIC CONFIGURATION -------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
F08x08       <= NOT(CONTROL(6)) AND NOT(CONTROL(5)) AND NOT(CONTROL(4));
F08x16       <= NOT(CONTROL(6)) AND NOT(CONTROL(5)) AND     CONTROL(4);
F16x08       <= NOT(CONTROL(6)) AND     CONTROL(5)  AND NOT(CONTROL(4));
F16x16       <= NOT(CONTROL(6)) AND     CONTROL(5)  AND     CONTROL(4);

GRAF         <=     CONTROL(6)  AND NOT(CONTROL(5)) AND NOT(CONTROL(4));
F16x32       <=     CONTROL(6)  AND NOT(CONTROL(5)) AND     CONTROL(4);
F32x16       <=     CONTROL(6)  AND     CONTROL(5)  AND NOT(CONTROL(4));
F32x32       <=     CONTROL(6)  AND     CONTROL(5)  AND     CONTROL(4);
-------------------------------------------------------------------------------
FONT_1bit    <= NOT(CONTROL(3)) AND NOT(CONTROL(2));
FONT_2bit    <= NOT(CONTROL(3)) AND     CONTROL(2);
FONT_4bit    <=     CONTROL(3)  AND NOT(CONTROL(2));
FONT_1bitE   <=     CONTROL(3)  AND     CONTROL(2)  AND F08Pix;

SCALE_x1     <= ( NOT(CONTROL(1)) AND NOT(CONTROL(0)) ) OR ( CONTROL(1) AND CONTROL(0) );
SCALE_x2     <=   NOT(CONTROL(1)) AND     CONTROL(0);
SCALE_x4     <=       CONTROL(1)  AND NOT(CONTROL(0));
--SCALE_x8     <=     CONTROL(1)  AND     CONTROL(0);
-------------------------------------------------------------------------------
F08Pix       <= F08x08 OR F08x16;
F16Pix       <= F16x16 OR F16x08 OR F16x32;
F32Pix       <= F32x32 OR F32x16;

F08Line      <= F08x08 OR F16x08;
F16Line      <= F16x16 OR F08x16 OR F32x16;
F32Line      <= F32x32 OR F16x32;
-------------------------------------------------------------------------------
MFONT        <= CONTROL(7) AND NOT(CONTROL(6));

EXTATR       <= NOT(GRAF) AND NOT(FONT_1bit);
EXTATRF      <= EXTATR AND NOT(CONTROL(6));
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
DOTClk <= H(1) WHEN ( SCALE_x4 = '1' ) ELSE
          H(0) WHEN ( SCALE_x2 = '1' ) ELSE
          CLK;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- MEMORY ACCESS - Font 4 bits
-------------------------------------------------------------------------------
PROCESS(CLK, H,         V,
             BLANK,     MFONT,     GRAF,
             SCALE_x4,  SCALE_x2,  SCALE_x1,
             F32Pix,    F16Pix,    F08Pix, 
             F32Line,   F16Line,   F08Line, 
             FONT_4bit, FONT_2bit, FONT_1bit )

variable vADDR      :  STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONT_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONT      :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vATTRIBUTE :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vCOLOR     :  STD_LOGIC_VECTOR(7 DOWNTO 0);

variable vX         :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vY         :  STD_LOGIC_VECTOR(6 DOWNTO 0);
variable v_X        :  STD_LOGIC_VECTOR(6 DOWNTO 0);
variable v_Y        :  STD_LOGIC_VECTOR(6 DOWNTO 0);
variable vCOLS      :  STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vLINE      :  STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(CLK)) THEN

    IF ( BLANK = '0' ) THEN
      DOTBLANK <= '0';
    END IF;

    IF    ( SCALE_x4 = '1' ) THEN
      vCOLS := H(6 DOWNTO 2);
      vLINE := V(6 DOWNTO 2);
    ELSIF ( SCALE_x2 = '1' ) THEN
      vCOLS := H(5 DOWNTO 1);
      vLINE := V(5 DOWNTO 1);
    ELSE
      vCOLS := H(4 DOWNTO 0);
      vLINE := V(4 DOWNTO 0);
    END IF;

    CASE H(2 DOWNTO 0) IS
-------------------------------------------------------------------------------
    WHEN "000" =>
      IF    ( GRAF = '1' AND SCALE_x4 = '1' AND FONT_4bit = '1' ) THEN
        vADDR := "00" & V( 9 DOWNTO 2) & H( 9 DOWNTO 4);
      ELSIF ( GRAF = '1' AND SCALE_x2 = '1' AND FONT_2bit = '1' ) THEN
        vADDR :=  "0" & V( 9 DOWNTO 1) & H( 9 DOWNTO 4);
      ELSIF ( GRAF = '1' AND SCALE_x1 = '1' AND FONT_1bit = '1' ) THEN
        vADDR :=        V( 9 DOWNTO 0) & H( 9 DOWNTO 4);
      ELSE
        IF     ( F32Pix = '1'  AND SCALE_x4 = '1' )  THEN
          vX := "00000" & H( 9 DOWNTO 7);
        ELSIF (( F32Pix = '1'  AND SCALE_x2 = '1' ) OR
               ( F16Pix = '1'  AND SCALE_x4 = '1' )) THEN
          vX := "0000"  & H( 9 DOWNTO 6);
        ELSIF (( F32Pix = '1'  AND SCALE_x1 = '1' ) OR
               ( F16Pix = '1'  AND SCALE_x2 = '1' ) OR
               ( F08Pix = '1'  AND SCALE_x4 = '1' )) THEN
          vX := "000"   & H( 9 DOWNTO 5);
        ELSIF (( F16Pix = '1'  AND SCALE_x1 = '1' ) OR
               ( F08Pix = '1'  AND SCALE_x2 = '1' )) THEN
          vX := "00"    & H( 9 DOWNTO 4);
        ELSE
          vX := '0'     & H( 9 DOWNTO 3);
        END IF;
  
        IF     ( F32Line = '1'  AND SCALE_x4 = '1' )  THEN
          vY := "0000" & V( 9 DOWNTO 7);
        ELSIF (( F32Line = '1'  AND SCALE_x2 = '1' ) OR
               ( F16Line = '1'  AND SCALE_x4 = '1' )) THEN
          vY := "000"  & V( 9 DOWNTO 6);
        ELSIF (( F32Line = '1'  AND SCALE_x1 = '1' ) OR
               ( F16Line = '1'  AND SCALE_x2 = '1' ) OR
               ( F08Line = '1'  AND SCALE_x4 = '1' )) THEN
          vY := "00"   & V( 9 DOWNTO 5);
        ELSIF (( F16Line = '1'  AND SCALE_x1 = '1' ) OR
               ( F08Line = '1'  AND SCALE_x2 = '1' )) THEN
          vY := '0'    & V( 9 DOWNTO 4);
        ELSE
          vY :=          V( 9 DOWNTO 3);
        END IF;
  
        v_X := vX(6 DOWNTO 0);
        v_Y := vY;

        vX  := vX + HSCROLL;
        vY  := vY + VSCROLL(6 DOWNTO 0);
        vADDR := '0' & vY & vX;
      END IF;
  
      VA <= '0' & vADDR;

    WHEN "001" =>
-------------------------------------------------------------------------------
    WHEN "010" =>
      FONT_ROW0 <= VDi;

      vFONT      := VDi( 7 DOWNTO 0);
      vATTRIBUTE := VDi(15 DOWNTO 8);

      IF ( EXTATR = '1' AND vATTRIBUTE(7) = '1' ) THEN
        vLINE := NOT(vLINE);
      END IF;

      IF ( CONTROL(6) = '1' )  THEN
        vFONT_ADDR(15 DOWNTO 8) := vFONT;
        vFONT_ADDR( 7 DOWNTO 3) := vLINE;
        vFONT_ADDR(2)           := F32Pix AND vCOLS(4);
      ELSE
        vFONT_ADDR(15)          := MFONT AND V(9);
        vFONT_ADDR(14)          := MFONT AND V(8);
        vFONT_ADDR(13 DOWNTO 6) := vFONT;
        vFONT_ADDR(5)           := NOT(F08line) AND vLINE(3);
        vFONT_ADDR(4 DOWNTO 2)  := vLINE(2 DOWNTO 0);
      END IF;
    
      IF ( F08Pix = '1' )  THEN
        vFONT_ADDR(1) := EXTATRF AND vATTRIBUTE(4);
      ELSE
        vFONT_ADDR(1) := NOT(FONT_1bit OR FONT_1bitE) AND vCOLS(3);
      END IF;

      IF ( FONT_4bit = '1' ) THEN
        vFONT_ADDR(0) := vCOLS(2);
      ELSE
        vFONT_ADDR(0) := EXTATRF AND vATTRIBUTE(5);
      END IF;

      VA <= '1' & vFONT_ADDR;
    WHEN "011" =>
-------------------------------------------------------------------------------
    WHEN "100" =>
      FONT_ROW1 <= VDi;

      IF ( FONT_4bit = '1' ) THEN
        vFONT_ADDR(0) := NOT(vCOLS(2));
      ELSE
        vFONT_ADDR(0) := EXTATRF AND vATTRIBUTE(5);
      END IF;

      IF ( FONT_2bit = '1' ) THEN
        VA <= '0' & "1111111111" & (MFONT AND V(9)) & (MFONT AND V(8)) & vATTRIBUTE(3 DOWNTO 0);
      ELSE
        VA <= '1' & vFONT_ADDR;
      END IF;
    WHEN "101" =>
-------------------------------------------------------------------------------
    WHEN "110" =>
      FONT_ROW2 <= VDi;

      VOE <= '1';
-------------------------------------------------------------------------------
    WHEN "111" =>
      IF ( ( VCURSOR(7 DOWNTO  0) = '1' & V_y ) AND HCURSOR(6 DOWNTO 0) = V_x ) THEN
        CURSOR <= '1';
      ELSE
        CURSOR <= '0';
      END IF;

      DOTBLANK <= '1';

      HByte <= NOT F08Pix AND (NOT(vCOLS(3)) XOR (EXTATR AND vATTRIBUTE(6)));
      HFlip <= EXTATR AND vATTRIBUTE(6);

      VOE <= '0';
    END CASE;

  END IF;
-------------------------------------------------------------------------------
END PROCESS;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- OUT 
-------------------------------------------------------------------------------
PROCESS(DOTCLK, DOTStep, DOTBLANK,
             FONT_ROW0, FONT_ROW1, FONT_ROW2,
             GRAF, FONT_2bit, FONT_1bit, FONT_1bitE)

variable vCOLOR    :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vCOLOR0   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR1   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR2   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR3   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable tCOLOR    :  STD_LOGIC_VECTOR(3 DOWNTO 0);

variable tCURSOR   :  STD_LOGIC;
variable tTMP      :  STD_LOGIC;

variable vFONT_ROW :  STD_LOGIC_VECTOR(15 DOWNTO 0);

variable vPIXEL1   :  STD_LOGIC;
variable vPIXEL2   :  STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vPIXEL4   :  STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(DOTCLK)) THEN

    CASE DOTStep IS
      WHEN "000" =>
        tCURSOR := CURSOR;

        IF ( FONT_1bit = '1' ) THEN
          PALETTE <= "0000";
        ELSE
          PALETTE <= FONT_ROW0(11 DOWNTO 8);
        END IF;

        IF ( FONT_1bitE = '1' ) THEN
          vCOLOR := FONT_ROW1(15 DOWNTO 8);
        ELSE
          vCOLOR := FONT_ROW0(15 DOWNTO 8);
        END IF;

        IF ( GRAF = '1' ) THEN
          vFONT_ROW := FONT_ROW0;
        ELSE
          vFONT_ROW := FONT_ROW1;
        END IF;

        vCOLOR3 := FONT_ROW2(15 DOWNTO 12);
        vCOLOR2 := FONT_ROW2(11 DOWNTO  8);
        vCOLOR1 := FONT_ROW2( 7 DOWNTO  4);
        vCOLOR0 := FONT_ROW2( 3 DOWNTO  0);

        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(8);
          ELSE
            vPIXEL1 := vFONT_ROW(0);
          END IF;
          vPIXEL2   := vFONT_ROW( 1 DOWNTO  0);
          vPIXEL4   := vCOLOR0;
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(15);
          ELSE
            vPIXEL1 := vFONT_ROW(7);
          END IF;
          vPIXEL2   := vFONT_ROW(15 DOWNTO 14);
          vPIXEL4   := vFONT_ROW(15 DOWNTO 12);
        END IF;

        IF ( DOTBLANK = '0' ) THEN
          DOTStep <= "000";
        ELSE
          DOTStep <= "001";
        END IF;
-------------------------------------------------------------------------------
      WHEN "001" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(9);
          ELSE
            vPIXEL1 := vFONT_ROW(1);
          END IF;
          vPIXEL2   := vFONT_ROW( 3 DOWNTO  2);
          vPIXEL4   := vCOLOR1;
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(14);
          ELSE
            vPIXEL1 := vFONT_ROW(6);
          END IF;
          vPIXEL2   := vFONT_ROW(13 DOWNTO 12);
          vPIXEL4   := vFONT_ROW(11 DOWNTO 8);
        END IF;

        DOTStep <= "010";
-------------------------------------------------------------------------------
      WHEN "010" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(10);
          ELSE
            vPIXEL1 := vFONT_ROW(2);
          END IF;
          vPIXEL2   := vFONT_ROW( 5 DOWNTO  4);
          vPIXEL4   := vCOLOR2;
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(13);
          ELSE
            vPIXEL1 := vFONT_ROW(5);
          END IF;
          vPIXEL2   := vFONT_ROW(11 DOWNTO 10);
          vPIXEL4   := vFONT_ROW(7 DOWNTO 4);
        END IF;

        DOTStep <= "011";
-------------------------------------------------------------------------------
      WHEN "011" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(11);
          ELSE
            vPIXEL1 := vFONT_ROW(3);
          END IF;
          vPIXEL2   := vFONT_ROW( 7 DOWNTO  6);
          vPIXEL4   := vCOLOR3;
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(12);
          ELSE
            vPIXEL1 := vFONT_ROW(4);
          END IF;
          vPIXEL2   := vFONT_ROW(9 DOWNTO 8);
          vPIXEL4   := vFONT_ROW(3 DOWNTO 0);
        END IF;

        IF ( GRAF = '1' AND SCALE_x4 = '1' AND FONT_4bit = '1' ) THEN
          DOTStep <= "000";
        ELSE
          DOTStep <= "100";
        END IF;
-------------------------------------------------------------------------------
      WHEN "100" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(12);
          ELSE
            vPIXEL1 := vFONT_ROW(4);
          END IF;
          vPIXEL2   := vFONT_ROW( 9 DOWNTO  8);
          vPIXEL4   := vFONT_ROW(3 DOWNTO 0);
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(11);
          ELSE
            vPIXEL1 := vFONT_ROW(3);
          END IF;
          vPIXEL2   := vFONT_ROW(7 DOWNTO 6);
          vPIXEL4   := vCOLOR3;
        END IF;

        DOTStep <= "101";
-------------------------------------------------------------------------------
      WHEN "101" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(13);
          ELSE
            vPIXEL1 := vFONT_ROW(5);
          END IF;
          vPIXEL2   := vFONT_ROW(11 DOWNTO 10);
          vPIXEL4   := vFONT_ROW(7 DOWNTO 4);
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(10);
          ELSE
            vPIXEL1 := vFONT_ROW(2);
          END IF;
          vPIXEL2   := vFONT_ROW(5 DOWNTO 4);
          vPIXEL4   := vCOLOR2;
        END IF;

        DOTStep <= "110";
-------------------------------------------------------------------------------
      WHEN "110" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(14);
          ELSE
            vPIXEL1 := vFONT_ROW(6);
          END IF;
          vPIXEL2   := vFONT_ROW(13 DOWNTO 12);
          vPIXEL4   := vFONT_ROW(11 DOWNTO 8);
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(9);
          ELSE
            vPIXEL1 := vFONT_ROW(1);
          END IF;
          vPIXEL2   := vFONT_ROW(3 DOWNTO 2);
          vPIXEL4   := vCOLOR1;
        END IF;

        DOTStep <= "111";
-------------------------------------------------------------------------------
      WHEN "111" =>
        IF ( HFlip = '1' ) THEN
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(15);
          ELSE
            vPIXEL1 := vFONT_ROW(7);
          END IF;
          vPIXEL2   := vFONT_ROW(15 DOWNTO 14);
          vPIXEL4   := vFONT_ROW(15 DOWNTO 12);
        ELSE
          IF ( HByte = '1' ) THEN
            vPIXEL1 := vFONT_ROW(8);
          ELSE
            vPIXEL1 := vFONT_ROW(0);
          END IF;
          vPIXEL2   := vFONT_ROW(1 DOWNTO 0);
          vPIXEL4   := vCOLOR0;
        END IF;

        DOTStep <= "000";
    END CASE;
-------------------------------------------------------------------------------
    IF ( DOTBLANK = '0' ) THEN
      tCOLOR := "0000";
    ELSE
      IF ( ( FONT_1bit OR FONT_1bitE ) = '1' ) THEN
        IF ( GRAF = '1' ) THEN
          IF ( vPIXEL1 = '1' ) THEN
            tCOLOR := "1111";
          ELSE
            tCOLOR := "0000";
          END IF;
        ELSE
          tTMP := tCURSOR XOR vPIXEL1;
          IF ( tTMP = '1' ) THEN
            tCOLOR := vCOLOR(3 DOWNTO 0);
          ELSE
            tCOLOR := vCOLOR(7 DOWNTO 4);
          END IF;
        END IF;
      ELSIF ( FONT_2bit = '1' ) THEN
        CASE vPIXEL2 IS
        WHEN "00" => tCOLOR := vCOLOR0;
        WHEN "01" => tCOLOR := vCOLOR1;
        WHEN "10" => tCOLOR := vCOLOR2;
        WHEN "11" => tCOLOR := vCOLOR3;
        END CASE;
      ELSE
        tCOLOR := vPIXEL4;
      END IF;
    END IF;

  END IF;
-------------------------------------------------------------------------------
  COLOR <= tCOLOR;
-------------------------------------------------------------------------------
END PROCESS;
-------------------------------------------------------------------------------
END bdf_type;
