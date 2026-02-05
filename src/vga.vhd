LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

LIBRARY work;

ENTITY VGA IS 
	PORT
	(
		CLK     :  IN  STD_LOGIC;
		RESET_n :  IN  STD_LOGIC;

		CONTROL :  IN  STD_LOGIC_VECTOR(9 DOWNTO 0);
		HSCROLL :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VSCROLL :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		HCURSOR :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		VCURSOR :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

		H       :  IN  STD_LOGIC_VECTOR(11 DOWNTO 0);
		V       :  IN  STD_LOGIC_VECTOR(11 DOWNTO 0);

		ANIMAT  :  IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		SPLIT0  :  IN  STD_LOGIC_VECTOR(5 DOWNTO 0);
		SPLIT1  :  IN  STD_LOGIC_VECTOR(6 DOWNTO 0);

		BLANK   :  IN  STD_LOGIC;
		COLOR   : OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);
		PALETTE : OUT  STD_LOGIC_VECTOR(3 DOWNTO 0);

		VDi     :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		VA      : OUT  STD_LOGIC_VECTOR(16 DOWNTO 0);
		VOE     : OUT  STD_LOGIC
	);
END;

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

SIGNAL  COLs       :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL  ROWs       :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL  X          :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  Y          :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  Xs         :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  Ys         :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	TILE_ADDR  : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	GRAF_ADDR  : STD_LOGIC_VECTOR(15 DOWNTO 0);

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
-- Tile map format - 16 bit
-- 15-12 - background color
-- 11-8  - fg color
-- 7-0   - tile index
--
-- for next modes tile map format - 16 bit
-- 15    - VFlip
-- 14    - HFlip
-- 13    - tile index 8 (8/16 pixel modes)
-- 12    - tile index 9 (8 pixel mode only)
-- 11    - Animation block (tile index mod 4/8, tile index 0 set animation size 4 or 8 tiles)
-- 10-8  - Palette for 2bits modes
-- 7-0   - tile index
--
--
-- ExFn - Extended font
-- AnBlk - Animation block
-- AnSiz - Animation size (0 bit in tile index if set AnBlk)
-- Pal - Palette
--                                  |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |CTRL7|TILE0|
--                                  |VFlip|HFlip|ExFn0|ExFn1|AnBlk|Pal2 |Pal1 |Pal0 |MFont|AnSiz|
-- Mode 08x08 1bitE (  8 bit font ) | yes   yes   yes   yes   yes   no    no    no    yes   yes
-- Mode 08x16 1bitE (  8 bit font ) | yes   yes   yes   yes   yes   no    no    no    yes   yes
--                                                                                             
-- Mode 08x08 2bit (  16 bit font ) | yes   yes   yes   yes   yes   yes   yes   yes   yes   yes
-- Mode 08x16 2bit (  16 bit font ) | yes   yes   yes   yes   yes   yes   yes   yes   yes   yes
-- Mode 16x08 2bit (  32 bit font ) | yes   yes   yes   no    yes   yes   yes   yes   yes   yes
-- Mode 16x16 2bit (  32 bit font ) | yes   yes   yes   no    yes   yes   yes   yes   yes   yes
--                                                                                             
-- Mode 08x08 4bit (  32 bit font ) | yes   yes   yes   no    yes   no    no    no    yes   yes
-- Mode 08x16 4bit (  32 bit font ) | yes   yes   yes   no    yes   no    no    no    yes   yes
-- Mode 16x08 4bit (  64 bit font ) | yes   yes   no    no    yes   no    no    no    yes   yes
-- Mode 16x16 4bit (  64 bit font ) | yes   yes   no    no    yes   no    no    no    yes   yes
--                                                                                             
-- Mode 16x32 2bit (  32 bit font ) | yes   yes   no    no    yes   yes   yes   yes   no    yes
-- Mode 32x32 2bit (  64 bit font ) | yes   yes   no    no    yes   yes   yes   yes   no    yes
--                                                                                             
-- Mode 16x32 4bit (  64 bit font ) | yes   yes   no    no    yes   no    no    no    no    yes
-- Mode 32x32 4bit ( 128 bit font ) | yes   yes   no    no    yes   no    no    no    no    yes
--
-------------------------------------------------------------------------------
--
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
FONT_1bit    <= ( NOT(CONTROL(3)) AND NOT(CONTROL(2)) ) OR ( CONTROL(3) AND CONTROL(2) AND NOT(F08Pix) );
FONT_2bit    <=   NOT(CONTROL(3)) AND     CONTROL(2);
FONT_4bit    <=       CONTROL(3)  AND NOT(CONTROL(2));
FONT_1bitE   <=       CONTROL(3)  AND     CONTROL(2)    AND F08Pix;

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
DOTClk       <= H(1) WHEN ( SCALE_x4 = '1' ) ELSE
                H(0) WHEN ( SCALE_x2 = '1' ) ELSE
                CLK;
-------------------------------------------------------------------------------
COLs         <= H(6 DOWNTO 2) WHEN ( SCALE_x4 = '1' ) ELSE
                H(5 DOWNTO 1) WHEN ( SCALE_x2 = '1' ) ELSE
                H(4 DOWNTO 0);
-------------------------------------------------------------------------------
ROWs         <= V(6 DOWNTO 2) WHEN ( SCALE_x4 = '1' ) ELSE
                V(5 DOWNTO 1) WHEN ( SCALE_x2 = '1' ) ELSE
                V(4 DOWNTO 0);
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
X            <= "00000" & H(9 DOWNTO 7) WHEN ( F32Pix = '1'  AND SCALE_x4 = '1' ) ELSE
                "0000"  & H(9 DOWNTO 6) WHEN ( F32Pix = '1'  AND SCALE_x2 = '1' ) OR
                                             ( F16Pix = '1'  AND SCALE_x4 = '1' ) ELSE
                "000"   & H(9 DOWNTO 5) WHEN ( F32Pix = '1'  AND SCALE_x1 = '1' ) OR
                                             ( F16Pix = '1'  AND SCALE_x2 = '1' ) OR
                                             ( F08Pix = '1'  AND SCALE_x4 = '1' ) ELSE
                "00"    & H(9 DOWNTO 4) WHEN ( F16Pix = '1'  AND SCALE_x1 = '1' ) OR
                                             ( F08Pix = '1'  AND SCALE_x2 = '1' ) ELSE
                '0'     & H(9 DOWNTO 3);
-------------------------------------------------------------------------------
Y            <= "00000" & V(9 DOWNTO 7) WHEN ( F32Line = '1'  AND SCALE_x4 = '1' ) ELSE
                "0000"  & V(9 DOWNTO 6) WHEN ( F32Line = '1'  AND SCALE_x2 = '1' ) OR
                                             ( F16Line = '1'  AND SCALE_x4 = '1' ) ELSE
                "000"   & V(9 DOWNTO 5) WHEN ( F32Line = '1'  AND SCALE_x1 = '1' ) OR
                                             ( F16Line = '1'  AND SCALE_x2 = '1' ) OR
                                             ( F08Line = '1'  AND SCALE_x4 = '1' ) ELSE
                "00"    & V(9 DOWNTO 4) WHEN ( F16Line = '1'  AND SCALE_x1 = '1' ) OR
                                             ( F08Line = '1'  AND SCALE_x2 = '1' ) ELSE
                '0'     & V(9 DOWNTO 3);
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--PROCESS(X, Y, HSCROLL, VSCROLL)
--variable vX : STD_LOGIC_VECTOR(7 DOWNTO 0);
--variable vY : STD_LOGIC_VECTOR(7 DOWNTO 0);
--BEGIN
--  IF CONTROL(8) = '1' THEN
--    IF Y < "00" & SPLIT0 THEN
--      vX := X;
--      vY := Y;
--    ELSIF Y < '0' & SPLIT1 THEN
--      vX := X + HSCROLL;
--      vY := Y + VSCROLL;
--    ELSE
--      vX := X;
--      vY(4 DOWNTO 0) := Y(4 DOWNTO 0);
--      vY(5) := Y(5) XOR '1';
--      vY(6) := Y(6) OR Y(5);
--      vY(7) := Y(7);
--    END IF;
--  ELSE
--    vX := X + HSCROLL;
--    vY := Y + VSCROLL;
--  END IF;
--  Xs <= vX;
--  Ys <= vY;
--END PROCESS;

Xs <= X + HSCROLL WHEN CONTROL(8) = '0'  ELSE
      X           WHEN Y < "00" & SPLIT0 ELSE
      X + HSCROLL WHEN Y <  '0' & SPLIT1 ELSE
      X;

Ys <= Y + VSCROLL WHEN CONTROL(8) = '0'  ELSE
      Y           WHEN Y < "00" & SPLIT0 ELSE
      Y + VSCROLL WHEN Y <  '0' & SPLIT1 ELSE
      Y(7) & (Y(6) OR Y(5)) & (Y(5) XOR '1') & Y(4 DOWNTO 0);

--Xs <= X + HSCROLL;
--Ys <= Y + VSCROLL;

-------------------------------------------------------------------------------
GRAF_ADDR    <= "00" & V( 9 DOWNTO 2) & H( 9 DOWNTO 4) WHEN ( FONT_4bit = '1' AND SCALE_x4 = '1' ) ELSE
                "0"  & V( 9 DOWNTO 1) & H( 9 DOWNTO 4) WHEN ( FONT_2bit = '1' AND SCALE_x2 = '1' ) ELSE
                       V( 9 DOWNTO 0) & H( 9 DOWNTO 4);
-------------------------------------------------------------------------------
TILE_ADDR    <= GRAF_ADDR WHEN GRAF = '1' ELSE Ys & Xs;
-------------------------------------------------------------------------------
-- MEMORY ACCESS - Font 4 bits
-------------------------------------------------------------------------------
PROCESS(CLK, H,         V,         COLs, ROWs, X, Y,
             BLANK,     MFONT,     GRAF,
             F32Pix,    F16Pix,    F08Pix, 
             F32Line,   F16Line,   F08Line, 
             FONT_4bit, FONT_2bit, FONT_1bit )

variable vADDR      : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONT_ADDR : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONT      : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vATTRIBUTE : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vCOLOR     : STD_LOGIC_VECTOR(7 DOWNTO 0);

variable vLINE      : STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vCOL       : STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(CLK)) THEN

    IF ( BLANK = '0' ) THEN
      DOTBLANK <= '0';
    END IF;

    CASE H(2 DOWNTO 0) IS
-------------------------------------------------------------------------------
    WHEN "000" =>
      VA <= '0' & TILE_ADDR;
-------------------------------------------------------------------------------
    WHEN "001" =>
-------------------------------------------------------------------------------
    WHEN "010" =>
      FONT_ROW0 <= VDi;

      vFONT      := VDi( 7 DOWNTO 0);
      vATTRIBUTE := VDi(15 DOWNTO 8);

      IF ( EXTATR = '1' AND vATTRIBUTE(7) = '1' ) THEN -- VFlip
        vLINE := NOT(ROWs);
      ELSE
        vLINE := ROWs;
      END IF;

      IF ( EXTATR = '1' AND vATTRIBUTE(6) = '1' ) THEN -- HFlip
        vCOL := NOT(COLs);
      ELSE
        vCOL := COLs;
      END IF;

      IF ( EXTATR = '1' AND vATTRIBUTE(3) = '1' ) THEN -- Animation
        vFONT(2) := (vFONT(2) AND NOT(vFONT(0))) OR (ANIMAT(2) AND vFONT(0));
        vFONT(1) := ANIMAT(1);
        vFONT(0) := ANIMAT(0);
      END IF;

      IF ( CONTROL(6) = '1' )  THEN
        vFONT_ADDR(15 DOWNTO 8) := vFONT;
        vFONT_ADDR( 7 DOWNTO 3) := vLINE;
        vFONT_ADDR(2)           := F32Pix AND vCOL(4);
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
        vFONT_ADDR(1) := NOT(FONT_1bit OR FONT_1bitE) AND vCOL(3);
      END IF;

      IF ( FONT_4bit = '1' ) THEN
        vFONT_ADDR(0) := vCOL(2);
      ELSE
        vFONT_ADDR(0) := EXTATRF AND vATTRIBUTE(5);
      END IF;

      VA <= '1' & vFONT_ADDR;
-------------------------------------------------------------------------------
    WHEN "011" =>
-------------------------------------------------------------------------------
    WHEN "100" =>
      FONT_ROW1 <= VDi;

      IF ( FONT_4bit = '1' ) THEN
        vFONT_ADDR(0) := NOT(vCOL(2));
      ELSE
        vFONT_ADDR(0) := EXTATRF AND vATTRIBUTE(5);
      END IF;

      IF ( FONT_2bit = '1' ) THEN
        VA <= '0' & "11111111111" & (MFONT AND V(9)) & (MFONT AND V(8)) & vATTRIBUTE(2 DOWNTO 0);
      ELSE
        VA <= '1' & vFONT_ADDR;
      END IF;
-------------------------------------------------------------------------------
    WHEN "101" =>
-------------------------------------------------------------------------------
    WHEN "110" =>
      FONT_ROW2 <= VDi;

      VOE <= '1';
-------------------------------------------------------------------------------
    WHEN "111" =>
      IF ( ( VCURSOR(7 DOWNTO  0) = '1' & Y(6 DOWNTO 0) ) AND HCURSOR(6 DOWNTO 0) = X(6 DOWNTO 0) ) THEN
        CURSOR <= '1' AND FONT_1bit;
      ELSE
        CURSOR <= '0';
      END IF;

      DOTBLANK <= '1';

      HByte <= NOT F08Pix AND (NOT(vCOL(3)) XOR (EXTATR AND vATTRIBUTE(6)));
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

variable vCOLOR    : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vCOLOR0   : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR1   : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR2   : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR3   : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable tCOLOR    : STD_LOGIC_VECTOR(3 DOWNTO 0);

variable tCURSOR   : STD_LOGIC;
variable tTMP      : STD_LOGIC;

variable vFONT_ROW : STD_LOGIC_VECTOR(15 DOWNTO 0);

variable vPIXEL1   : STD_LOGIC;
variable vPIXEL2   : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vPIXEL4   : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(DOTCLK)) THEN

    CASE DOTStep IS
      WHEN "000" =>
        tCURSOR := CURSOR;

        IF ( FONT_1bit = '1' ) THEN
          PALETTE <= "0000";
        ELSE
          PALETTE <= "00" & FONT_ROW0(9 DOWNTO 8);
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
END;
