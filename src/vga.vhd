LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

LIBRARY work;

ENTITY vga IS 
	PORT
	(
		CLK     :  IN  STD_LOGIC;
		RESET_n :  IN  STD_LOGIC;

		CSmem   :  IN  STD_LOGIC;
		CSreg   :  IN  STD_LOGIC;
		A       :  IN  STD_LOGIC_VECTOR(16 DOWNTO 0);
		D       :  IN  STD_LOGIC_VECTOR(7 DOWNTO 0);

		HSYNC   : OUT  STD_LOGIC;
		VSYNC   : OUT  STD_LOGIC;
		BLANK   : OUT  STD_LOGIC;
		B       : OUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		G       : OUT  STD_LOGIC_VECTOR(2 DOWNTO 0);
		R       : OUT  STD_LOGIC_VECTOR(2 DOWNTO 0);

		VDi     :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		VDo     : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
		VA      : OUT  STD_LOGIC_VECTOR(16 DOWNTO 0);
		VWE     : OUT  STD_LOGIC;
		VOE     : OUT  STD_LOGIC;
		BLE     : OUT  STD_LOGIC;
		BHE     : OUT  STD_LOGIC
	);
END vga;

ARCHITECTURE bdf_type OF vga IS 

COMPONENT count
	PORT(	CLK	: IN STD_LOGIC;
		SClr	: IN STD_LOGIC;
		Q	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	DOTCLK    :  STD_LOGIC;
SIGNAL	DOTBLANK  :  STD_LOGIC;
SIGNAL	SCRBLANK  :  STD_LOGIC;
SIGNAL	DOTStep   :  STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	RAMStep   :  STD_LOGIC_VECTOR(2 DOWNTO 0);

SIGNAL	F16x16    :  STD_LOGIC;
SIGNAL	F16x32    :  STD_LOGIC;
SIGNAL	F32x32    :  STD_LOGIC;
SIGNAL	F08x16    :  STD_LOGIC;
SIGNAL	F08x08    :  STD_LOGIC;
SIGNAL	F08x16m   :  STD_LOGIC;
SIGNAL	F08x08m   :  STD_LOGIC;
SIGNAL	F08x16c   :  STD_LOGIC;
SIGNAL	F08x08c   :  STD_LOGIC;
SIGNAL	GRAF      :  STD_LOGIC;

SIGNAL	SCALE_x1  :  STD_LOGIC;
SIGNAL	SCALE_x2  :  STD_LOGIC;
SIGNAL	SCALE_x4  :  STD_LOGIC;
SIGNAL	SCALE_x8  :  STD_LOGIC;

SIGNAL	F08Pix    :  STD_LOGIC;
SIGNAL	F16Pix    :  STD_LOGIC;
SIGNAL	F32Pix    :  STD_LOGIC;
SIGNAL	F08Line   :  STD_LOGIC;
SIGNAL	F16Line   :  STD_LOGIC;
SIGNAL	F32Line   :  STD_LOGIC;
SIGNAL	FCOLOR    :  STD_LOGIC;
SIGNAL	MFONT     :  STD_LOGIC;

SIGNAL	FONT_1bit :  STD_LOGIC;
SIGNAL	FONT_2bit :  STD_LOGIC;
SIGNAL	FONT_4bit :  STD_LOGIC;
SIGNAL	FONT_8bit :  STD_LOGIC;

SIGNAL	REG0 :  STD_LOGIC;
SIGNAL	REG1 :  STD_LOGIC;
SIGNAL	REG2 :  STD_LOGIC;
SIGNAL	REG3 :  STD_LOGIC;
SIGNAL	REG4 :  STD_LOGIC;
SIGNAL	REG5 :  STD_LOGIC;
SIGNAL	REG6 :  STD_LOGIC;
SIGNAL	REG7 :  STD_LOGIC;

SIGNAL	WRCPU :  STD_LOGIC;

SIGNAL	BHiEn :  STD_LOGIC;
SIGNAL	BLoEn :  STD_LOGIC;
SIGNAL	BDLo :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	BDHi :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	RALo :  STD_LOGIC;
SIGNAL	RAHi :  STD_LOGIC;
SIGNAL	WRMEMLo :  STD_LOGIC;
SIGNAL	WRMEMHi :  STD_LOGIC;

SIGNAL	BA                    :  STD_LOGIC_VECTOR(16 DOWNTO 0);

SIGNAL	REG_ADDR              :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	REG_DATA              :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG_COLOR             :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG_CTRL              :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG_HSCROLL           :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG_VSCROLL           :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	FONT_ROW0             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW1             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW2             :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	H                     :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	V                     :  STD_LOGIC_VECTOR(11 DOWNTO 0);

SIGNAL	HiByte                :  STD_LOGIC;

SIGNAL	RGB                   :  STD_LOGIC_VECTOR(8 DOWNTO 0);

SIGNAL	HS                    :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	HS1                   :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	HS2                   :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	HS3                   :  STD_LOGIC_VECTOR(11 DOWNTO 0);

BEGIN 
-------------------------------------------------------------------------------
b2v_HCount : count
PORT MAP(CLK	=> CLK,
	 SClr	=> RESET_n,
	 Q	=> HS3);

b2v_VCount : count
PORT MAP(CLK	=> HS3(11),
	 SClr	=> RESET_n,
	 Q	=> HS2);

b2v_TCount : count
PORT MAP(CLK	=> HS2(11),
	 SClr	=> RESET_n,
	 Q	=> HS1);

b2v_ECount : count
PORT MAP(CLK	=> HS1(0),
	 SClr	=> RESET_n,
	 Q	=> HS);
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Resolution        1024 x 768           800 x 600      640 x 480     1280 x 720
--
-- Virtual screen     256 x 128 = 32768
--
--MEM_SCR_08x08x1 --  128 x  96 = 12288 | 100 x  75 =  |  80 x  60 = |  160 x  90 = 14400
--MEM_SCR_08x08x2 --   64 x  48 =  3072 |  50 x  38 =  |  40 x  30 = |   80 x  45 =  3600
--MEM_SCR_08x08x4 --   32 x  24 =   768 |  25 x  19 =  |  20 x  15 = |   40 x  23 =   900

--MEM_SCR_08x16x1 --  128 x  48 =  6144 | 100 x  38 =  |  80 x  30 = |  160 x  45 =  7200

--MEM_SCR_16x16x1 --   64 x  48 =  3072 |  50 x  38 =  |  40 x  30 = |   80 x  45 =  3600
--MEM_SCR_16x16x2 --   32 x  24 =   768 |  25 x  19 =  |  20 x  15 = |   40 x  23 =   900
--MEM_SCR_16x16x4 --   16 x  12 =   192 |  25 x  19 =  |  20 x  15 = |   40 x  23 =   900

--MEM_SCR_16x32x1 --   64 x  24 =  1536 |  50 x  19 =  |  40 x  15 = |   80 x  23 =  1800

--MEM_SCR_32x32x1 --   32 x  24 =   768 |  25 x  19 =  |  20 x  15 = |   40 x  23 =   900
--MEM_SCR_32x32x2 --   16 x  12 =   192 |  25 x  19 =  |  20 x  15 = |   40 x  23 =   900
-------------------------------------------------------------------------------
--MEM_SCR_GRAFx1  -- 1024 x 768 = 98304 | 800 x 600 =  | 640 x 480 = |
--MEM_SCR_GRAFx2  --  512 x 384 = 49152 | 400 x 300 =  | 320 x 240 = |  640 x 360 =
--MEM_SCR_GRAFx4  --  256 x 192 = 24576 | 200 x 150 =  | 160 x 120 = |  320 x 180 =
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- STATIC CONFIGURATION -------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
F08x08m      <= NOT(REG_CTRL(6)) AND NOT(REG_CTRL(5)) AND NOT(REG_CTRL(4));
F08x08c      <= NOT(REG_CTRL(6)) AND NOT(REG_CTRL(5)) AND     REG_CTRL(4);
F08x16m      <= NOT(REG_CTRL(6)) AND     REG_CTRL(5)  AND NOT(REG_CTRL(4));
F08x16c      <= NOT(REG_CTRL(6)) AND     REG_CTRL(5)  AND     REG_CTRL(4);
F16x16       <=     REG_CTRL(6)  AND NOT(REG_CTRL(5)) AND NOT(REG_CTRL(4));
F16x32       <=     REG_CTRL(6)  AND NOT(REG_CTRL(5)) AND     REG_CTRL(4);
F32x32       <=     REG_CTRL(6)  AND     REG_CTRL(5)  AND NOT(REG_CTRL(4));
GRAF         <=     REG_CTRL(6)  AND     REG_CTRL(5)  AND     REG_CTRL(4);

FONT_1bit    <= ( NOT(REG_CTRL(3)) AND NOT(REG_CTRL(2)) ) OR ( REG_CTRL(3) AND  REG_CTRL(2) );
FONT_2bit    <= NOT(REG_CTRL(3)) AND     REG_CTRL(2);
FONT_4bit    <=     REG_CTRL(3)  AND NOT(REG_CTRL(2));
FONT_8bit    <=     REG_CTRL(3)  AND     REG_CTRL(2);

SCALE_x1     <= NOT(REG_CTRL(1)) AND NOT(REG_CTRL(0));
SCALE_x2     <= NOT(REG_CTRL(1)) AND     REG_CTRL(0);
SCALE_x4     <=     REG_CTRL(1)  AND NOT(REG_CTRL(0));
SCALE_x8     <=     REG_CTRL(1)  AND     REG_CTRL(0);

MFONT        <= REG_CTRL(7);

FCOLOR       <= F08x08c OR F08x16c;
F08x08       <= F08x08m OR F08x08c;
F08x16       <= F08x16m OR F08x16c;

F08Pix       <= F08x08  OR F08x16;
F16Pix       <= F16x16  OR F16x32;
F32Pix       <= F32x32;

F08Line      <= F08x08;
F16Line      <= F16x16  OR F08x16;
F32Line      <= F16x32  OR F32x32;

DOTClk <= H(1) WHEN ( SCALE_x4 = '1' ) ELSE
          H(0) WHEN ( SCALE_x2 = '1' ) ELSE
          CLK;
-------------------------------------------------------------------------------
-- Synchro 
-------------------------------------------------------------------------------
PROCESS(CLK, RESET_n, SCALE_x1,  SCALE_x2,  SCALE_x4)

variable vH    : STD_LOGIC_VECTOR(11 DOWNTO 0);
variable vV    : STD_LOGIC_VECTOR(11 DOWNTO 0);

variable vHx   : STD_LOGIC_VECTOR(11 DOWNTO 0);
variable vVy   : STD_LOGIC_VECTOR(11 DOWNTO 0);

variable vHDE  : STD_LOGIC;
variable vVDE  : STD_LOGIC;

variable vCOLS : STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vROWS : STD_LOGIC_VECTOR(4 DOWNTO 0);

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
    IF ( vH < 1071 AND vVDE = '1' ) THEN
      vHx  := vH;
    ELSE
      vHx  := (OTHERS => '0');
    END IF;

    IF ( 7 < vH AND vH < 1024+7 ) THEN
      vHDE := '1';
    ELSE
      vHDE := '0';
    END IF;

    IF ( vV < 768 ) THEN
      vVDE := '1';
      vVy  := vV;
    ELSE
      vVDE := '0';
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
    SCRBLANK <= vHDE AND vVDE;

    H <= vHx;
    V <= vVy;

    RAMStep <= vHx(2 DOWNTO 0);

END PROCESS;
-------------------------------------------------------------------------------
BLANK  <= SCRBLANK;
-------------------------------------------------------------------------------
-- MEMORY ACCESS 
-------------------------------------------------------------------------------
PROCESS(CLK, H,         V,         RAMStep,
             SCRBLANK,  MFONT,     GRAF,
             SCALE_x4,  SCALE_x2,  SCALE_x1,
             F32Pix,    F16Pix,    F08Pix, 
             F32Line,   F16Line,   F08Line, 
             FONT_4bit, FONT_2bit, FONT_1bit )

variable vADDR      :  STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONT_ADDR :  STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONT      :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vATTRIBUTE :  STD_LOGIC_VECTOR(7 DOWNTO 0);

variable vX         :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vY         :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vCOLS      :  STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vLINE      :  STD_LOGIC_VECTOR(4 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(CLK)) THEN

    IF ( SCRBLANK = '0' ) THEN
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

    HiByte <= NOT F08Pix AND NOT vCOLS(3);

    CASE RAMStep IS
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
          vY := "00000" & V( 9 DOWNTO 7);
        ELSIF (( F32Line = '1'  AND SCALE_x2 = '1' ) OR
               ( F16Line = '1'  AND SCALE_x4 = '1' )) THEN
          vY := "0000"  & V( 9 DOWNTO 6);
        ELSIF (( F32Line = '1'  AND SCALE_x1 = '1' ) OR
               ( F16Line = '1'  AND SCALE_x2 = '1' ) OR
               ( F08Line = '1'  AND SCALE_x4 = '1' )) THEN
          vY := "000"   & V( 9 DOWNTO 5);
        ELSIF (( F16Line = '1'  AND SCALE_x1 = '1' ) OR
               ( F08Line = '1'  AND SCALE_x2 = '1' )) THEN
          vY := "00"    & V( 9 DOWNTO 4);
        ELSE
          vY := '0'     & V( 9 DOWNTO 3);
        END IF;
  
        vx := vX + REG_HSCROLL;
        vY := vY + REG_VSCROLL;
        vADDR := vY & vX;
      END IF;
  
      VA <= '0' & vADDR;

    WHEN "001" =>
    WHEN "010" =>
      vFONT      := VDi( 7 DOWNTO 0);
      vATTRIBUTE := VDi(15 DOWNTO 8);

      FONT_ROW0 <= VDi;

      IF ( F32Line = '1' )  THEN
        vFONT_ADDR(15 DOWNTO 8) := vFONT;
        vFONT_ADDR( 7 DOWNTO 3) := vLINE;
      
        IF ( F32Pix = '1' )  THEN
          vFONT_ADDR(2) := vCOLS(4);
        ELSE
          vFONT_ADDR(2) := '0';
        END IF;
      ELSE
        IF ( MFONT = '1' )  THEN
          vFONT_ADDR(15 DOWNTO 14 ) := V(9 DOWNTO 8);
        ELSE
          vFONT_ADDR(15 DOWNTO 14 ) := "00";
        END IF;
      
        vFONT_ADDR(13 DOWNTO 6) := vFONT;
        vFONT_ADDR( 4 DOWNTO 2) := vLINE(2 DOWNTO 0);
      
        IF ( F08line = '1' )  THEN
          vFONT_ADDR(5) := '0';
        ELSE
          vFONT_ADDR(5) := vLINE(3);
        END IF;
      END IF;
    
      IF ( F08Pix = '1' )  THEN
        vFONT_ADDR(1) := '0';
      ELSE
        IF ( FONT_1bit = '1' ) THEN
          vFONT_ADDR(1) := '0';
        ELSE
          vFONT_ADDR(1) := vCOLS(3);
        END IF;
      END IF;

      IF ( FONT_4bit = '1' ) THEN
        vFONT_ADDR(0) := vCOLS(2);
      ELSE
        vFONT_ADDR(0) := '0';
      END IF;

      VA <= '1' & vFONT_ADDR;
    WHEN "011" =>
    WHEN "100" =>
      FONT_ROW1 <= VDi;

      IF ( FONT_4bit = '1' ) THEN
        vFONT_ADDR(0) := vCOLS(2);
      ELSE
        vFONT_ADDR(0) := '0';
      END IF;

      IF ( FONT_2bit = '1' ) THEN
        VA <= '0' & "11111111" & vATTRIBUTE;
      ELSE
        VA <= '1' & vFONT_ADDR;
      END IF;
    WHEN "101" =>
    WHEN "110" =>
      FONT_ROW2 <= VDi;
    WHEN "111" =>
      DOTBLANK <= '1';
    END CASE;

  END IF;
-------------------------------------------------------------------------------
END PROCESS;
-------------------------------------------------------------------------------
-- OUT 
-------------------------------------------------------------------------------
PROCESS(DOTCLK, DOTStep, DOTBLANK,
             FONT_ROW0, FONT_ROW1, FONT_ROW2,
             GRAF, FCOLOR, FONT_2bit, FONT_1bit)

variable vCOLOR    :  STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vCOLOR0   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR1   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR2   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vCOLOR3   :  STD_LOGIC_VECTOR(3 DOWNTO 0);
variable tCOLOR    :  STD_LOGIC_VECTOR(3 DOWNTO 0);

variable vFONT_ROW :  STD_LOGIC_VECTOR(15 DOWNTO 0);

variable vPIXEL1   :  STD_LOGIC;
variable vPIXEL2   :  STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vPIXEL4   :  STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(DOTCLK)) THEN

    CASE DOTStep IS
      WHEN "000" =>
        IF ( FCOLOR = '1' ) THEN
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

        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(15);
        ELSE
          vPIXEL1 := vFONT_ROW(7);
        END IF;
        vPIXEL2   := vFONT_ROW(15 DOWNTO 14);
        vPIXEL4   := vFONT_ROW(15 DOWNTO 12);

        IF ( DOTBLANK = '0' ) THEN
          DOTStep <= "000";
        ELSE
          DOTStep <= "001";
        END IF;
-------------------------------------------------------------------------------
      WHEN "001" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(14);
        ELSE
          vPIXEL1 := vFONT_ROW(6);
        END IF;
        vPIXEL2   := vFONT_ROW(13 DOWNTO 12);
        vPIXEL4   := vFONT_ROW(11 DOWNTO 8);

        DOTStep <= "010";
-------------------------------------------------------------------------------
      WHEN "010" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(13);
        ELSE
          vPIXEL1 := vFONT_ROW(5);
        END IF;
        vPIXEL2   := vFONT_ROW(11 DOWNTO 10);
        vPIXEL4   := vFONT_ROW(7 DOWNTO 4);

        DOTStep <= "011";
-------------------------------------------------------------------------------
      WHEN "011" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(12);
        ELSE
          vPIXEL1 := vFONT_ROW(4);
        END IF;
        vPIXEL2   := vFONT_ROW(9 DOWNTO 8);
        vPIXEL4   := vFONT_ROW(3 DOWNTO 0);

        DOTStep <= "100";
-------------------------------------------------------------------------------
      WHEN "100" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(11);
        ELSE
          vPIXEL1 := vFONT_ROW(3);
        END IF;
        vPIXEL2   := vFONT_ROW(7 DOWNTO 6);
        vPIXEL4   := vCOLOR3;

        DOTStep <= "101";
-------------------------------------------------------------------------------
      WHEN "101" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(10);
        ELSE
          vPIXEL1 := vFONT_ROW(2);
        END IF;
        vPIXEL2   := vFONT_ROW(5 DOWNTO 4);
        vPIXEL4   := vCOLOR2;

        DOTStep <= "110";
-------------------------------------------------------------------------------
      WHEN "110" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(9);
        ELSE
          vPIXEL1 := vFONT_ROW(1);
        END IF;
        vPIXEL2   := vFONT_ROW(3 DOWNTO 2);
        vPIXEL4   := vCOLOR1;

        DOTStep <= "111";
-------------------------------------------------------------------------------
      WHEN "111" =>
        IF ( HiByte = '1' ) THEN
          vPIXEL1 := vFONT_ROW(8);
        ELSE
          vPIXEL1 := vFONT_ROW(0);
        END IF;
        vPIXEL2   := vFONT_ROW(1 DOWNTO 0);
        vPIXEL4   := vCOLOR0;

        DOTStep <= "000";
    END CASE;
-------------------------------------------------------------------------------
    IF ( DOTBLANK = '0' ) THEN
      tCOLOR := "0000";
    ELSE
      IF ( FONT_1bit = '1' ) THEN
        IF ( GRAF = '1' ) THEN
          IF ( vPIXEL1 = '1' ) THEN
            tCOLOR := "1111";
          ELSE
            tCOLOR := "0000";
          END IF;
        ELSE
          IF ( vPIXEL1 = '1' ) THEN
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

    IF ( FONT_8bit = '1' AND tCOLOR = "0000" ) THEN
      RGB <= REG_COLOR & '0';
    ELSE
      CASE tCOLOR IS
      WHEN "0000" => RGB <= "000" & "000" & "000";
      WHEN "0001" => RGB <= "000" & "000" & "011";
      WHEN "0010" => RGB <= "000" & "011" & "000";
      WHEN "0011" => RGB <= "000" & "011" & "011";
      WHEN "0100" => RGB <= "011" & "000" & "000";
      WHEN "0101" => RGB <= "011" & "000" & "011";
      WHEN "0110" => RGB <= "011" & "011" & "000";
      WHEN "0111" => RGB <= "011" & "011" & "011";
      WHEN "1000" => RGB <= "100" & "111" & "010";
      WHEN "1001" => RGB <= "000" & "000" & "111";
      WHEN "1010" => RGB <= "000" & "111" & "000";
      WHEN "1011" => RGB <= "000" & "111" & "111";
      WHEN "1100" => RGB <= "111" & "000" & "000";
      WHEN "1101" => RGB <= "111" & "000" & "111";
      WHEN "1110" => RGB <= "111" & "111" & "000";
      WHEN "1111" => RGB <= "111" & "111" & "111";
      END CASE;
    END IF;

  END IF;
-------------------------------------------------------------------------------
END PROCESS;
-------------------------------------------------------------------------------
B(2 DOWNTO 0) <= RGB(8 DOWNTO 6);
G(2 DOWNTO 0) <= RGB(5 DOWNTO 3);
R(2 DOWNTO 0) <= RGB(2 DOWNTO 0);
-------------------------------------------------------------------------------
-- REGISTERS
-------------------------------------------------------------------------------
REG0 <= NOT(CSreg) AND NOT(A(2)) AND NOT(A(1)) AND NOT(A(0));
REG1 <= NOT(CSreg) AND NOT(A(2)) AND NOT(A(1)) AND     A(0);
REG2 <= NOT(CSreg) AND NOT(A(2)) AND     A(1)  AND NOT(A(0));
REG3 <= NOT(CSreg) AND NOT(A(2)) AND     A(1)  AND     A(0);
REG4 <= NOT(CSreg) AND     A(2)  AND NOT(A(1)) AND NOT(A(0));
REG5 <= NOT(CSreg) AND     A(2)  AND NOT(A(1)) AND     A(0);
REG6 <= NOT(CSreg) AND     A(2)  AND     A(1)  AND NOT(A(0));
REG7 <= NOT(CSreg) AND     A(2)  AND     A(1)  AND     A(0);

PROCESS(RESET_n, REG7, CLK)
BEGIN
    IF (RESET_n = '0') THEN
      REG_CTRL <= "00000000";
    ELSIF (RISING_EDGE(REG7)) THEN
      REG_CTRL <= D;
--      REG_CTRL <= HS1(11 DOWNTO 4);
    END IF;
END PROCESS;

PROCESS(RESET_n, REG6, CLK)
BEGIN
    IF (RESET_n = '0') THEN
      REG_VSCROLL <= "00000000";
    ELSIF (RISING_EDGE(REG6)) THEN
      REG_VSCROLL <= D;
    END IF;
END PROCESS;

PROCESS(RESET_n, REG5, CLK)
BEGIN
    IF (RESET_n = '0') THEN
      REG_HSCROLL <= "00000000";
    ELSIF (RISING_EDGE(REG5)) THEN
      REG_HSCROLL <= D;
    END IF;
END PROCESS;

PROCESS(RESET_n, REG4, CLK)
BEGIN
    IF (RESET_n = '0') THEN
      REG_COLOR <= "00000000";
    ELSIF (RISING_EDGE(REG4)) THEN
      REG_COLOR <= D;
--      REG_COLOR <= HS2(11 DOWNTO 4);
    END IF;
END PROCESS;
-------------------------------------------------------------------------------
END bdf_type;