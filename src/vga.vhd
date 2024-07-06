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
		VA      : OUT  STD_LOGIC_VECTOR(15 DOWNTO 0);
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

COMPONENT counta
	PORT(	CLK	: IN STD_LOGIC;
		SClr	: IN STD_LOGIC;
		Q	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
	);
END COMPONENT;

COMPONENT comp1024x768
	PORT(	CLK	: IN STD_LOGIC;
		RST	: IN STD_LOGIC;
		H	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		V	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		HSync	: OUT STD_LOGIC;
		VSync	: OUT STD_LOGIC;
		Blank	: OUT STD_LOGIC;
		HBlank	: OUT STD_LOGIC;
		VBlank	: OUT STD_LOGIC;
		HReset	: OUT STD_LOGIC;
		VReset	: OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT comp1024x768a
	PORT(	CLK	: IN STD_LOGIC;
		RST	: IN STD_LOGIC;
		H	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		V	: IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		HSync	: OUT STD_LOGIC;
		VSync	: OUT STD_LOGIC;
		Blank	: OUT STD_LOGIC;
		HBlank	: OUT STD_LOGIC;
		VBlank	: OUT STD_LOGIC;
		HReset	: OUT STD_LOGIC;
		VReset	: OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT comp1024x768b
	PORT(	CLK	: IN STD_LOGIC;
		RST	: IN STD_LOGIC;
		H	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		V	: OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
		HSync	: OUT STD_LOGIC;
		VSync	: OUT STD_LOGIC;
		Blank	: OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT mux4to1
	PORT(	Sa	: IN STD_LOGIC;
		Sb	: IN STD_LOGIC;
		Sc	: IN STD_LOGIC;
		Sd	: IN STD_LOGIC;
		A	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		B	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		C	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		D	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Q	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT mux6to1
	PORT(	S0	: IN STD_LOGIC;
		S1	: IN STD_LOGIC;
		S2	: IN STD_LOGIC;
		S3	: IN STD_LOGIC;
		S4	: IN STD_LOGIC;
		S5	: IN STD_LOGIC;
		A	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		B	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		C	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		D	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		E	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		F	: IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		Q	: OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END COMPONENT;

COMPONENT shift
	PORT(	CLK	: IN  STD_LOGIC;
		STLD	: IN  STD_LOGIC;
		SER	: IN  STD_LOGIC;
		D	: IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		QH	: OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT shift2 IS 
	PORT(	CLK     : IN  STD_LOGIC;
		STLD    : IN  STD_LOGIC;
		SER	: IN  STD_LOGIC_VECTOR(1 DOWNTO 0);
		D       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		QH      : OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT color_sel
	PORT(	COLOR	: IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
		RGB	: OUT STD_LOGIC_VECTOR(8 DOWNTO 0)
	);
END COMPONENT;

COMPONENT mux81to1 IS 
	PORT
	(
		D :   IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
		S :   IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		Q :   OUT STD_LOGIC
	);
END COMPONENT;

COMPONENT mux82to1 IS 
	PORT
	(
		D :   IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		S :   IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		Q :   OUT STD_LOGIC_VECTOR(1 DOWNTO 0)
	);
END COMPONENT;

COMPONENT mux84to1 IS 
	PORT
	(
		Dl :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		Dh :  IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
		S :   IN  STD_LOGIC_VECTOR(2 DOWNTO 0);
		Q :   OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
	);
END COMPONENT;

SIGNAL	HBlank :  STD_LOGIC;
SIGNAL	VBlank :  STD_LOGIC;

SIGNAL	DOTClk   : STD_LOGIC;
SIGNAL	DOTStart : STD_LOGIC;
SIGNAL	DOTStep  : STD_LOGIC_VECTOR(2 DOWNTO 0);


SIGNAL	F16x16  :  STD_LOGIC;
SIGNAL	F16x32  :  STD_LOGIC;
SIGNAL	F32x32  :  STD_LOGIC;
SIGNAL	F08x16  :  STD_LOGIC;
SIGNAL	F08x08  :  STD_LOGIC;
SIGNAL	F08x16m :  STD_LOGIC;
SIGNAL	F08x08m :  STD_LOGIC;
SIGNAL	F08x16c :  STD_LOGIC;
SIGNAL	F08x08c :  STD_LOGIC;
SIGNAL	GRAF    :  STD_LOGIC;

SIGNAL	SCALE_x1 :  STD_LOGIC;
SIGNAL	SCALE_x2 :  STD_LOGIC;
SIGNAL	SCALE_x4 :  STD_LOGIC;
SIGNAL	SCALE_x8 :  STD_LOGIC;

SIGNAL	F08Pix    :  STD_LOGIC;
SIGNAL	F16Pix    :  STD_LOGIC;
SIGNAL	F32Pix    :  STD_LOGIC;
SIGNAL	F08Line   :  STD_LOGIC;
SIGNAL	F16Line   :  STD_LOGIC;
SIGNAL	F32Line   :  STD_LOGIC;
SIGNAL	FCOLOR :  STD_LOGIC;
SIGNAL	FMULTY :  STD_LOGIC;

SIGNAL	FONT_1bit :  STD_LOGIC;
SIGNAL	FONT_2bit :  STD_LOGIC;
SIGNAL	FONT_4bit :  STD_LOGIC;
SIGNAL	FONT_8bit :  STD_LOGIC;

SIGNAL	nREG_CTRL :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG0 :  STD_LOGIC;
SIGNAL	REG1 :  STD_LOGIC;
SIGNAL	REG2 :  STD_LOGIC;
SIGNAL	REG3 :  STD_LOGIC;

SIGNAL	WRCPU :  STD_LOGIC;

SIGNAL	HReset :  STD_LOGIC;
SIGNAL	VReset :  STD_LOGIC;
SIGNAL	VCLK   :  STD_LOGIC;

SIGNAL	PIXELlo :  STD_LOGIC;
SIGNAL	PIXELhi :  STD_LOGIC;
SIGNAL	PIXEL1  :  STD_LOGIC;
SIGNAL	PIXEL2  :  STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL	PIXEL4  :  STD_LOGIC_VECTOR(3 DOWNTO 0);

SIGNAL	BHiEn :  STD_LOGIC;
SIGNAL	BLoEn :  STD_LOGIC;
SIGNAL	BDLo :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	BDHi :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	RALo :  STD_LOGIC;
SIGNAL	RAHi :  STD_LOGIC;
SIGNAL	WRMEMLo :  STD_LOGIC;
SIGNAL	WRMEMHi :  STD_LOGIC;

SIGNAL	MEM_SCR_08x08x1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_08x08x2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_08x08x4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_08x16x1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_16x16x1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_16x16x2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_16x16x4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_16x32x1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_32x32x1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_32x32x2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_GRAFx1       :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_GRAFx2       :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR_GRAFx4       :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_08x08_1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x08_2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x08_4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_08x16_1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x16_2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x16_4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_16x16_1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_16x16_2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_16x16_4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_08x08_1m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x08_2m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x08_4m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_08x16_1m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x16_2m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_08x16_4m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_16x16_1m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_16x16_2m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_16x16_4m    :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_16x32_1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_16x32_2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_16x32_4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_FNT_32x32_1     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_32x32_2     :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FNT_32x32_4     :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	MEM_COLOR           :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_FONT            :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SCR             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MEM_SEL             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	BA                  :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	REG_ADDR              :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	REG_DATA              :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG_COLOR             :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	REG_CTRL              :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	FONT                  :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	COLOR                 :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	bCOLOR                :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	eCOLOR                :  STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL	tCOLOR                :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	tbCOLOR               :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	tcCOLOR               :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	tgCOLOR               :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	tfCOLOR               :  STD_LOGIC_VECTOR(3 DOWNTO 0);

SIGNAL	COLOR0                :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLOR1                :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLOR2                :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLOR3                :  STD_LOGIC_VECTOR(3 DOWNTO 0);

SIGNAL	FONT_ROW0             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW1             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW2             :  STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	FONT_ROW3             :  STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL	COLs                  :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	COLss                 :  STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL	ROWs                  :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	ROWss                 :  STD_LOGIC_VECTOR(4 DOWNTO 0);

SIGNAL	COLs0                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLs1                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLs2                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLs3                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLs4                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLs5                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);
SIGNAL	COLs6                 :  STD_LOGIC_VECTOR(3 DOWNTO 0);

SIGNAL	RGB                   :  STD_LOGIC_VECTOR(8 DOWNTO 0);

SIGNAL	HS                    :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	HS1                    :  STD_LOGIC_VECTOR(11 DOWNTO 0);

SIGNAL	HSCROLL               :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	VSCROLL               :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	HPOS                  :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	VPOS                  :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	HPOS1                 :  STD_LOGIC_VECTOR(11 DOWNTO 0);
SIGNAL	VPOS1                 :  STD_LOGIC_VECTOR(11 DOWNTO 0);

SIGNAL	X                     :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	Y                     :  STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL	DOT                   :  STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL	DOTmax                :  STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL	SCAN                  :  STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL	SCANmax               :  STD_LOGIC_VECTOR(6 DOWNTO 0);

SIGNAL	S000 :  STD_LOGIC;
SIGNAL	S001 :  STD_LOGIC;
SIGNAL	S010 :  STD_LOGIC;
SIGNAL	S011 :  STD_LOGIC;
SIGNAL	S100 :  STD_LOGIC;
SIGNAL	S101 :  STD_LOGIC;
SIGNAL	S110 :  STD_LOGIC;
SIGNAL	S111 :  STD_LOGIC;
SIGNAL	S0 :  STD_LOGIC;
SIGNAL	S1 :  STD_LOGIC;
SIGNAL	S2 :  STD_LOGIC;
SIGNAL	S3 :  STD_LOGIC;
SIGNAL	S4 :  STD_LOGIC;
SIGNAL	S5 :  STD_LOGIC;
SIGNAL	S6 :  STD_LOGIC;
SIGNAL	S7 :  STD_LOGIC;

BEGIN 
-------------------------------------------------------------------------------
b2v_HCount : count
PORT MAP(CLK	=> CLK,
	 SClr	=> HReset,
	 Q	=> COLs(11 DOWNTO 0));

VCLK <= NOT(HReset);

b2v_VCount : count
PORT MAP(CLK	=> VCLK,
	 SClr	=> VReset,
	 Q	=> ROWs(11 DOWNTO 0));

b2v_TCount : count
PORT MAP(CLK	=> NOT(VReset),
	 SClr	=> RESET_n,
	 Q	=> HS1);

b2v_ECount : count
PORT MAP(CLK	=> NOT(HS1(3)),
	 SClr	=> RESET_n,
	 Q	=> HS);

b2v_CompHV : comp1024x768a
PORT MAP(CLK	=> CLK,
	 RST	=> RESET_n,
	 H	=> COLs(11 DOWNTO 0),
	 V	=> ROWs(11 DOWNTO 0),
	 HSync	=> HSYNC,
	 VSync	=> VSYNC,
	 Blank	=> BLANK,
	 HBlank	=> HBLANK,
	 VBlank	=> VBLANK,
	 HReset	=> HReset,
	 VReset	=> VReset);


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
X <= "00000" & COLs( 9 DOWNTO 7) WHEN ( F32Pix = '1'  AND SCALE_x4 = '1' ) ELSE
     "0000"  & COLs( 9 DOWNTO 6) WHEN ( F32Pix = '1'  AND SCALE_x2 = '1' ) OR
                                      ( F16Pix = '1'  AND SCALE_x4 = '1' ) ELSE
     "000"   & COLs( 9 DOWNTO 5) WHEN ( F32Pix = '1'  AND SCALE_x1 = '1' ) OR
                                      ( F16Pix = '1'  AND SCALE_x2 = '1' ) OR
                                      ( F08Pix = '1'  AND SCALE_x4 = '1' ) ELSE
     "00"    & COLs( 9 DOWNTO 4) WHEN ( F16Pix = '1'  AND SCALE_x1 = '1' ) OR
                                      ( F08Pix = '1'  AND SCALE_x2 = '1' ) ELSE
     '0'     & COLs( 9 DOWNTO 3) WHEN ( F08Pix = '1'  AND SCALE_x1 = '1' );

Y <= "00000" & ROWs( 9 DOWNTO 7) WHEN ( F32Line = '1' AND SCALE_x4 = '1' ) ELSE
     "0000"  & ROWs( 9 DOWNTO 6) WHEN ( F32Line = '1' AND SCALE_x2 = '1' ) OR
                                      ( F16Line = '1' AND SCALE_x4 = '1' ) ELSE
     "000"   & ROWs( 9 DOWNTO 5) WHEN ( F32Line = '1' AND SCALE_x1 = '1' ) OR
                                      ( F16Line = '1' AND SCALE_x2 = '1' ) OR
                                      ( F08Line = '1' AND SCALE_x4 = '1' ) ELSE
     "00"    & ROWs( 9 DOWNTO 4) WHEN ( F16Line = '1' AND SCALE_x1 = '1' ) OR
                                      ( F08Line = '1' AND SCALE_x2 = '1' ) ELSE
     '0'     & ROWs( 9 DOWNTO 3) WHEN ( F08Line = '1' AND SCALE_x1 = '1' );

--HPOS <= X + HSCROLL;
--VPOS <= Y + VSCROLL;

-------------------------------------------------------------------------------
COLss <= COLs(6 DOWNTO 2) WHEN ( SCALE_x4 = '1' ) ELSE
         COLs(5 DOWNTO 1) WHEN ( SCALE_x2 = '1' ) ELSE
         COLs(4 DOWNTO 0);

ROWss <= ROWs(6 DOWNTO 2) WHEN ( SCALE_x4 = '1' ) ELSE
         ROWs(5 DOWNTO 1) WHEN ( SCALE_x2 = '1' ) ELSE
         ROWs(4 DOWNTO 0);

--DOTClk <= COLs(1) WHEN ( SCALE_x4 = '1' ) ELSE
--          COLs(0) WHEN ( SCALE_x2 = '1' ) ELSE
--          CLK;

-------------------------------------------------------------------------------
--                                                                              1024 x 768           800 x 600      640 x 480     1280 x 720
-- Virtual screen                                                                256 x 192 = 49152 
--
--MEM_SCR_08x08x1 <= ("00"       & ROWs( 9 DOWNTO 3) & COLs( 9 DOWNTO 3));     --  128 x  96 = 12288 | 100 x  75 =  |  80 x  60 = |  160 x  90 = 14400
--MEM_SCR_08x16x1 <= ("000"      & ROWs( 9 DOWNTO 4) & COLs( 9 DOWNTO 3));     --  128 x  48 =  6144 | 100 x  38 =  |  80 x  30 = |  160 x  45 =  7200
--MEM_SCR_16x16x1 <= ("0000"     & ROWs( 9 DOWNTO 4) & COLs( 9 DOWNTO 4));     --   64 x  48 =  3072 |  50 x  38 =  |  40 x  30 = |   80 x  45 =  3600
--MEM_SCR_16x32x1 <= ("00000"    & ROWs( 9 DOWNTO 5) & COLs( 9 DOWNTO 4));     --   64 x  24 =  1536 |  50 x  19 =  |  40 x  15 = |   80 x  23 =  1800
--MEM_SCR_32x32x1 <= ("000000"   & ROWs( 9 DOWNTO 5) & COLs( 9 DOWNTO 5));     --   32 x  24 =   768 |  25 x  19 =  |  20 x  15 = |   40 x  23 =   900
-------------------------------------------------------------------------------
MEM_SCR_GRAFx1  <= (             ROWs( 9 DOWNTO 0) & COLs( 9 DOWNTO 4));     -- 1024 x 768 = 98304 | 800 x 600 =  | 640 x 480 = |
MEM_SCR_GRAFx2  <= ('0'        & ROWs( 9 DOWNTO 1) & COLs( 9 DOWNTO 4));     --  512 x 384 = 49152 | 400 x 300 =  | 320 x 240 = |
MEM_SCR_GRAFx4  <= ("00"       & ROWs( 9 DOWNTO 2) & COLs( 9 DOWNTO 4));     --  256 x 192 = 24576 | 200 x 150 =  | 160 x 120 = | 320 x 180 =
-------------------------------------------------------------------------------
MEM_FNT_08x08_1  <= ("11100"                   & FONT & ROWss(2 DOWNTO 0));                     --  256 x  8 x 1 =  2048
MEM_FNT_08x08_1m <= ("111" & ROWs( 9 DOWNTO 8) & FONT & ROWss(2 DOWNTO 0));                     --  256 x  8 x 1 =  2048 * 3
MEM_FNT_08x08_2  <= ("11101"                   & FONT & ROWss(2 DOWNTO 0));                     --  256 x  8 x 1 =  2048
MEM_FNT_08x08_2m <= ("111" & ROWs( 9 DOWNTO 8) & FONT & ROWss(2 DOWNTO 0));                     --  256 x  8 x 1 =  2048 * 3
MEM_FNT_08x08_4  <= ("1000"                    & FONT & ROWss(2 DOWNTO 0) & COLss(2));          --  256 x  8 x 2 =  4096
MEM_FNT_08x08_4m <= ("10"  & ROWs( 9 DOWNTO 8) & FONT & ROWss(2 DOWNTO 0) & COLss(2));          --  256 x  8 x 2 =  4096 * 3

MEM_FNT_08x16_1  <= ("1110"                    & FONT & ROWss(3 DOWNTO 0));                     --  256 x 16 x 1 =  4096
MEM_FNT_08x16_1m <= ("11"  & ROWs( 9 DOWNTO 8) & FONT & ROWss(3 DOWNTO 0));                     --  256 x 16 x 1 =  4096 * 3
MEM_FNT_08x16_2  <= ("1110"                    & FONT & ROWss(3 DOWNTO 0));                     --  256 x 16 x 1 =  4096
MEM_FNT_08x16_2m <= ("11"  & ROWs( 9 DOWNTO 8) & FONT & ROWss(3 DOWNTO 0));                     --  256 x 16 x 1 =  4096 * 3
MEM_FNT_08x16_4  <= ("100"                     & FONT & ROWss(3 DOWNTO 0) & COLss(2));          --  256 x 16 x 2 =  8192
MEM_FNT_08x16_4m <= ("1"   & ROWs( 9 DOWNTO 8) & FONT & ROWss(3 DOWNTO 0) & COLss(2));          --  256 x 16 x 2 =  8192 * 3

MEM_FNT_16x16_1  <= ("1000"                    & FONT & ROWss(3 DOWNTO 0));                     --  256 x 16 x 1 =  4096
MEM_FNT_16x16_1m <= ("10"  & ROWs( 9 DOWNTO 8) & FONT & ROWss(3 DOWNTO 0));                     --  256 x 16 x 1 =  4096 * 3
MEM_FNT_16x16_2  <= ("100"                     & FONT & ROWss(3 DOWNTO 0) & COLss(3));          --  256 x 16 x 2 =  8192
MEM_FNT_16x16_2m <= ("1"   & ROWs( 9 DOWNTO 8) & FONT & ROWss(3 DOWNTO 0) & COLss(3));          --  256 x 16 x 2 =  8192 * 3
MEM_FNT_16x16_4  <= ("10"                      & FONT & ROWss(3 DOWNTO 0) & COLss(3 DOWNTO 2)); --  256 x 16 x 4 = 16384
MEM_FNT_16x16_4m <= (        ROWs( 9 DOWNTO 8) & FONT & ROWss(3 DOWNTO 0) & COLss(3 DOWNTO 2)); --  256 x 16 x 4 = 16384 * 3

MEM_FNT_16x32_1  <= ("100"                     & FONT & ROWss(4 DOWNTO 0));                     --  256 x 32 x 1 =  8192
MEM_FNT_16x32_2  <= ("10"                      & FONT & ROWss(4 DOWNTO 0) & COLss(3));          --  256 x 32 x 2 = 16384
MEM_FNT_16x32_4  <= ('1'                       & FONT & ROWss(4 DOWNTO 0) & COLss(3 DOWNTO 2)); --  256 x 32 x 4 = 32768

MEM_FNT_32x32_1  <= ("10"                      & FONT & ROWss(4 DOWNTO 0) & COLss(4));          --  256 x 32 x 2 = 16384
MEM_FNT_32x32_2  <= ('1'                       & FONT & ROWss(4 DOWNTO 0) & COLss(4 DOWNTO 3)); --  256 x 32 x 4 = 32768
MEM_FNT_32x32_4  <= (                            FONT & ROWss(4 DOWNTO 0) & COLss(4 DOWNTO 2)); --  256 x 32 x 8 = 65536
-------------------------------------------------------------------------------
MEM_COLOR        <= ("11111111" & COLOR);                                    --  256      x 1 =   256
-------------------------------------------------------------------------------

MEM_SCR    <=
              MEM_SCR_GRAFx4  WHEN ( GRAF = '1' AND SCALE_x4 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_SCR_GRAFx2  WHEN ( GRAF = '1' AND SCALE_x2 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_SCR_GRAFx1  WHEN ( GRAF = '1' AND SCALE_x1 = '1' AND FONT_1bit = '1' ) ELSE
              (Y & X);

-------------------------------------------------------------------------------
MEM_FONT   <= 
              MEM_FNT_16x16_4m WHEN ( FMULTY = '1' AND F16x16 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_16x16_2m WHEN ( FMULTY = '1' AND F16x16 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_16x16_1m WHEN ( FMULTY = '1' AND F16x16 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_08x16_4m WHEN ( FMULTY = '1' AND F08x16 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_08x16_2m WHEN ( FMULTY = '1' AND F08x16 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_08x16_1m WHEN ( FMULTY = '1' AND F08x16 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_08x08_4m WHEN ( FMULTY = '1' AND F08x08 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_08x08_2m WHEN ( FMULTY = '1' AND F08x08 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_08x08_1m WHEN ( FMULTY = '1' AND F08x08 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_32x32_4  WHEN ( FMULTY = '0' AND F32x32 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_32x32_2  WHEN ( FMULTY = '0' AND F32x32 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_32x32_1  WHEN ( FMULTY = '0' AND F32x32 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_16x32_4  WHEN ( FMULTY = '0' AND F16x32 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_16x32_2  WHEN ( FMULTY = '0' AND F16x32 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_16x32_1  WHEN ( FMULTY = '0' AND F16x32 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_16x16_4  WHEN ( FMULTY = '0' AND F16x16 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_16x16_2  WHEN ( FMULTY = '0' AND F16x16 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_16x16_1  WHEN ( FMULTY = '0' AND F16x16 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_08x16_4  WHEN ( FMULTY = '0' AND F08x16 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_08x16_2  WHEN ( FMULTY = '0' AND F08x16 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_08x16_1  WHEN ( FMULTY = '0' AND F08x16 = '1' AND FONT_1bit = '1' ) ELSE

              MEM_FNT_08x08_4  WHEN ( FMULTY = '0' AND F08x08 = '1' AND FONT_4bit = '1' ) ELSE
              MEM_FNT_08x08_2  WHEN ( FMULTY = '0' AND F08x08 = '1' AND FONT_2bit = '1' ) ELSE
              MEM_FNT_08x08_1  WHEN ( FMULTY = '0' AND F08x08 = '1' AND FONT_1bit = '1' );

-------------------------------------------------------------------------------
MEM_SEL    <= MEM_COLOR WHEN ( FONT_2bit = '1' ) ELSE
              MEM_FONT;

-------------------------------------------------------------------------------
nREG_CTRL(0) <= NOT(REG_CTRL(0));
nREG_CTRL(1) <= NOT(REG_CTRL(1));
nREG_CTRL(2) <= NOT(REG_CTRL(2));
nREG_CTRL(3) <= NOT(REG_CTRL(3));

nREG_CTRL(4) <= NOT(REG_CTRL(4));
nREG_CTRL(5) <= NOT(REG_CTRL(5));

nREG_CTRL(6) <= NOT(REG_CTRL(6));
nREG_CTRL(7) <= NOT(REG_CTRL(7));

F08x08m   <= nREG_CTRL(6) AND nREG_CTRL(5) AND nREG_CTRL(4);
F08x08c   <= nREG_CTRL(6) AND nREG_CTRL(5) AND  REG_CTRL(4);
F08x16m   <= nREG_CTRL(6) AND  REG_CTRL(5) AND nREG_CTRL(4);
F08x16c   <= nREG_CTRL(6) AND  REG_CTRL(5) AND  REG_CTRL(4);
F16x16    <=  REG_CTRL(6) AND nREG_CTRL(5) AND nREG_CTRL(4);
F16x32    <=  REG_CTRL(6) AND nREG_CTRL(5) AND  REG_CTRL(4);
F32x32    <=  REG_CTRL(6) AND  REG_CTRL(5) AND nREG_CTRL(4);
GRAF      <=  REG_CTRL(6) AND  REG_CTRL(5) AND  REG_CTRL(4);

FONT_1bit <= (nREG_CTRL(3) AND nREG_CTRL(2)) OR (REG_CTRL(3) AND  REG_CTRL(2));
FONT_2bit <= nREG_CTRL(3) AND  REG_CTRL(2);
FONT_4bit <=  REG_CTRL(3) AND nREG_CTRL(2);
--FONT_8bit <=  REG_CTRL(3) AND  REG_CTRL(2);

SCALE_x1  <= (nREG_CTRL(1) AND nREG_CTRL(0)) OR (REG_CTRL(1) AND  REG_CTRL(0));
SCALE_x2  <= nREG_CTRL(1) AND  REG_CTRL(0);
SCALE_x4  <=  REG_CTRL(1) AND nREG_CTRL(0);
--SCALE_x8  <=  REG_CTRL(1) AND  REG_CTRL(0);

FCOLOR    <= F08x08c OR F08x16c;
F08x08    <= F08x08m OR F08x08c;
F08x16    <= F08x16m OR F08x16c;

F08Pix    <= F08x08  OR F08x16;
F16Pix    <= F16x16  OR F16x32;
F32Pix    <= F32x32;

F08Line   <= F08x08;
F16Line   <= F16x16  OR F08x16;
F32Line   <= F16x32  OR F32x32;

FMULTY    <= REG_CTRL(7);

--PIXmax <=  "0111111" WHEN (F32Pix = '1'  AND SCALE_x2 = '1') OR
--                          (F16Pix = '1'  AND SCALE_x4 = '1') ELSE
--           "0011111" WHEN (F32Pix = '1'  AND SCALE_x1 = '1') OR
--                          (F16Pix = '1'  AND SCALE_x2 = '1') OR
--                          (F08Pix = '1'  AND SCALE_x4 = '1') ELSE
--           "0001111" WHEN (F16Pix = '1'  AND SCALE_x1 = '1') OR
--                          (F08Pix = '1'  AND SCALE_x2 = '1') ELSE
--           "0000111";

--LINEmax <= "0111111" WHEN (F32Line = '1' AND SCALE_x2 = '1') OR
--                          (F16Line = '1' AND SCALE_x4 = '1') ELSE
--           "0011111" WHEN (F32Line = '1' AND SCALE_x1 = '1') OR
--                          (F16Line = '1' AND SCALE_x2 = '1') OR
--                          (F08Line = '1' AND SCALE_x4 = '1') ELSE
--           "0001111" WHEN (F16Line = '1' AND SCALE_x1 = '1') OR
--                          (F08Line = '1' AND SCALE_x2 = '1') ELSE
--           "0000111";

--S000 <= NOT(COLss(2)) AND NOT(COLss(1)) AND NOT(COLs(2)) AND NOT(COLs(1)) AND NOT(COLs(0));
S001 <= NOT(COLss(2)) AND NOT(COLss(1)) AND    (COLss(0));
S010 <= NOT(COLss(2)) AND    (COLss(1)) AND NOT(COLss(0));
S011 <= NOT(COLss(2)) AND    (COLss(1)) AND    (COLss(0));
S100 <=    (COLss(2)) AND NOT(COLss(1)) AND NOT(COLss(0));
S101 <=    (COLss(2)) AND NOT(COLss(1)) AND    (COLss(0));
S110 <=    (COLss(2)) AND    (COLss(1)) AND NOT(COLss(0));
S111 <=    (COLss(2)) AND    (COLss(1)) AND    (COLss(0));

S000 <= NOT(COLs(2)) AND NOT(COLs(1)) AND NOT(COLs(0));
S0   <= NOT(COLs(2)) AND NOT(COLs(1));-- AND NOT(COLs(0));
S1   <= NOT(COLs(2)) AND NOT(COLs(1)) AND     COLs(0) ;
S2   <= NOT(COLs(2)) AND     COLs(1);--  AND NOT(COLs(0));
S3   <= NOT(COLs(2)) AND     COLs(1)  AND     COLs(0) ;
S4   <=     COLs(2)  AND NOT(COLs(1));-- AND NOT(COLs(0));
S5   <=     COLs(2)  AND NOT(COLs(1)) AND     COLs(0) ;
S6   <=     COLs(2)  AND     COLs(1);--  AND NOT(COLs(0));
S7   <=     COLs(2)  AND     COLs(1)  AND     COLs(0);-- AND COLss(2) AND COLss(1);

-------------------------------------------------------------------------------
PROCESS(CLK)
BEGIN
    IF (RISING_EDGE(CLK)) THEN

      CASE COLs(2 DOWNTO 0) IS
-------------------------------------------------------------------------------
      WHEN "000" =>
--        VA <= MEM_SCR;

--        DOTStart <= '0';

-------------------------------------------------------------------------------
      WHEN "001" =>

-------------------------------------------------------------------------------
      WHEN "010" =>
--        VA <= MEM_FONT;
--        FONT  <= VDi(7 DOWNTO 0);
--        COLOR <= VDi(15 DOWNTO 8);

-------------------------------------------------------------------------------
      WHEN "011" =>

-------------------------------------------------------------------------------
      WHEN "100" =>
--        VA <= MEM_SEL;

-------------------------------------------------------------------------------
      WHEN "101" =>

--        FONT_ROW2 <= VDi;
--        eCOLOR <= VDi(15 DOWNTO 8);

-------------------------------------------------------------------------------
      WHEN "110" =>

-------------------------------------------------------------------------------
      WHEN "111" =>
--        FONT_ROW1 <= VDi;
--        COLOR0 <= VDi(15 DOWNTO 12);
--        COLOR1 <= VDi(11 DOWNTO  8);
--        COLOR2 <= VDi( 7 DOWNTO  4);
--        COLOR3 <= VDi( 3 DOWNTO  0);


      END CASE;

    END IF;
END PROCESS;

b2v_MuxADDR3 : mux4to1
PORT MAP(Sa	=> S0,
	 Sb	=> S2,
	 Sc	=> S4,
	 Sd	=> S6,
	 A	=> MEM_SCR,
	 B	=> MEM_FONT,
	 C	=> MEM_SEL,
	 D	=> BA,
	 Q	=> VA);


PROCESS(S000)
BEGIN
    IF (RISING_EDGE(S000)) THEN

        IF ( FCOLOR = '1' ) THEN
          bCOLOR <= eCOLOR;
        ELSE
          bCOLOR <= COLOR;
        END IF;

        IF ( GRAF = '1' ) THEN
          FONT_ROW0 <= COLOR & FONT;
        ELSE
          FONT_ROW0 <= FONT_ROW2;
        END IF;

        COLs0 <= COLss(3 DOWNTO 0);
    END IF;
END PROCESS;

PROCESS(S1)
BEGIN
  IF (RISING_EDGE(S1)) THEN
    FONT      <= VDi(7 DOWNTO 0);

    COLOR     <= VDi(15 DOWNTO 8);
  END IF;
END PROCESS;

PROCESS(S3)
BEGIN
  IF (RISING_EDGE(S3)) THEN
    FONT_ROW2 <= VDi;

    eCOLOR    <= VDi(15 DOWNTO 8);
  END IF;
END PROCESS;

PROCESS(S5)
BEGIN
  IF (RISING_EDGE(S5)) THEN
    FONT_ROW1 <= VDi;

    COLOR0    <= VDi(15 DOWNTO 12);
    COLOR1    <= VDi(11 DOWNTO  8);
    COLOR2    <= VDi( 7 DOWNTO  4);
    COLOR3    <= VDi( 3 DOWNTO  0);
  END IF;
END PROCESS;

-------------------------------------------------------------------------------
PROCESS(CLK, DOTCLK, DOTStart)
BEGIN
    IF (RISING_EDGE(CLK)) THEN

      CASE COlss(2 DOWNTO 0) IS
-------------------------------------------------------------------------------
      WHEN "000" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(15);
--        ELSE
--          PIXEL1 <= FONT_ROW0(7);
--        END IF;
--        PIXEL2   <= FONT_ROW0(15 DOWNTO 14);
--        PIXEL4   <= FONT_ROW0(15 DOWNTO 12);

--        DOTStep <= "001";
-------------------------------------------------------------------------------
      WHEN "001" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(14);
--        ELSE
--          PIXEL1 <= FONT_ROW0(6);
--        END IF;
--        PIXEL2   <= FONT_ROW0(13 DOWNTO 12);
--        PIXEL4   <= FONT_ROW0(11 DOWNTO 8);

--        DOTStep <= "010";
-------------------------------------------------------------------------------
      WHEN "010" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(13);
--        ELSE
--          PIXEL1 <= FONT_ROW0(5);
--        END IF;
--        PIXEL2   <= FONT_ROW0(11 DOWNTO 10);
--        PIXEL4   <= FONT_ROW0(7 DOWNTO 4);

--        DOTStep <= "011";
-------------------------------------------------------------------------------
      WHEN "011" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(12);
--        ELSE
--          PIXEL1 <= FONT_ROW0(4);
--        END IF;
--        PIXEL2   <= FONT_ROW0(9 DOWNTO 8);
--        PIXEL4   <= FONT_ROW0(3 DOWNTO 0);

--        DOTStep <= "100";
-------------------------------------------------------------------------------
      WHEN "100" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(11);
--        ELSE
--          PIXEL1 <= FONT_ROW0(3);
--        END IF;
--        PIXEL2   <= FONT_ROW0(7 DOWNTO 6);
--        PIXEL4   <= FONT_ROW1(15 DOWNTO 12);

--        DOTStep <= "101";
-------------------------------------------------------------------------------
      WHEN "101" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(10);
--        ELSE
--          PIXEL1 <= FONT_ROW0(2);
--        END IF;
--        PIXEL2   <= FONT_ROW0(5 DOWNTO 4);
--        PIXEL4   <= FONT_ROW1(11 DOWNTO 8);

--        DOTStep <= "110";
-------------------------------------------------------------------------------
      WHEN "110" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(9);
--        ELSE
--          PIXEL1 <= FONT_ROW0(1);
--        END IF;
--        PIXEL2   <= FONT_ROW0(3 DOWNTO 2);
--        PIXEL4   <= FONT_ROW1(7 DOWNTO 4);

--        DOTStep <= "111";
-------------------------------------------------------------------------------
      WHEN "111" =>

--        IF ( F08Pix = '0' AND COLs0(3) = '0' ) THEN
--          PIXEL1 <= FONT_ROW0(8);
--        ELSE
--          PIXEL1 <= FONT_ROW0(0);
--        END IF;
--        PIXEL2   <= FONT_ROW0(1 DOWNTO 0);
--        PIXEL4   <= FONT_ROW1(3 DOWNTO 0);

--        DOTStep <= "000";
      END CASE;

    END IF;
END PROCESS;


b2v_MuxPIXEL1lo : mux81to1
PORT MAP(D	=> FONT_ROW0(7 DOWNTO 0),
	 S	=> COLss(2 DOWNTO 0),
	 Q	=> PIXELlo);

b2v_MuxPIXEL1hi : mux81to1
PORT MAP(D	=> FONT_ROW0(15 DOWNTO 8),
	 S	=> COLss(2 DOWNTO 0),
	 Q	=> PIXELhi);

--WITH ( COLss(2 DOWNTO 0) ) SELECT
--  PIXELlo <=
--    FONT_ROW0(7)   WHEN "000",
--    FONT_ROW0(6)   WHEN "001",
--    FONT_ROW0(5)   WHEN "010",
--    FONT_ROW0(4)   WHEN "011",
--    FONT_ROW0(3)   WHEN "100",
--    FONT_ROW0(2)   WHEN "101",
--    FONT_ROW0(1)   WHEN "110",
--    FONT_ROW0(0)   WHEN "111";
--WITH ( COLss(2 DOWNTO 0) ) SELECT
--  PIXELhi <=
--    FONT_ROW0(15)  WHEN "000",
--    FONT_ROW0(14)  WHEN "001",
--    FONT_ROW0(13)  WHEN "010",
--    FONT_ROW0(12)  WHEN "011",
--    FONT_ROW0(11)  WHEN "100",
--    FONT_ROW0(10)  WHEN "101",
--    FONT_ROW0( 9)  WHEN "110",
--    FONT_ROW0( 8)  WHEN "111";
PIXEL1 <= PIXELHi WHEN ( F08Pix = '0' AND COLs0(3) = '0' ) ELSE PIXELlo;

b2v_MuxPIXEL2 : mux82to1
PORT MAP(D	=> FONT_ROW0(15 DOWNTO 0),
	 S	=> COLss(2 DOWNTO 0),
	 Q	=> PIXEL2);

--WITH ( COLss(2 DOWNTO 0) ) SELECT
--  PIXEL2 <=
--    FONT_ROW0(15 DOWNTO 14)   WHEN "000",
--    FONT_ROW0(13 DOWNTO 12)   WHEN "001",
--    FONT_ROW0(11 DOWNTO 10)   WHEN "010",
--    FONT_ROW0( 9 DOWNTO  8)   WHEN "011",
--    FONT_ROW0( 7 DOWNTO  6)   WHEN "100",
--    FONT_ROW0( 5 DOWNTO  4)   WHEN "101",
--    FONT_ROW0( 3 DOWNTO  2)   WHEN "110",
--    FONT_ROW0( 1 DOWNTO  0)   WHEN "111";

b2v_MuxPIXEL4 : mux84to1
PORT MAP(Dl	=> FONT_ROW0(15 DOWNTO 0),
         Dh	=> FONT_ROW1(15 DOWNTO 0),
	 S	=> COLss(2 DOWNTO 0),
	 Q	=> PIXEL4);

--WITH ( COLss(2 DOWNTO 0) ) SELECT
--  PIXEL4 <=
--    FONT_ROW0(15 DOWNTO 12)   WHEN "000",
--    FONT_ROW0(11 DOWNTO  8)   WHEN "001",
--    FONT_ROW0( 7 DOWNTO  4)   WHEN "010",
--    FONT_ROW0( 3 DOWNTO  0)   WHEN "011",
--    FONT_ROW1(15 DOWNTO 12)   WHEN "100",
--    FONT_ROW1(11 DOWNTO  8)   WHEN "101",
--    FONT_ROW1( 7 DOWNTO  4)   WHEN "110",
--    FONT_ROW1( 3 DOWNTO  0)   WHEN "111";

WITH ( PIXEL2 ) SELECT
  tcCOLOR <=
    COLOR0    WHEN "00",
    COLOR1    WHEN "01",
    COLOR2    WHEN "10",
    COLOR3    WHEN "11";

WITH ( PIXEL2 ) SELECT
  tfCOLOR <=
    "0000"    WHEN "00",
    "0011"    WHEN "01",
    "1100"    WHEN "10",
    "1111"    WHEN "11";


tgCOLOR <= "0000"             WHEN PIXEL1 = '0' ELSE "1111";
tbCOLOR <= bCOLOR(7 DOWNTO 4) WHEN PIXEL1 = '0' ELSE bCOLOR(3 DOWNTO 0);

tCOLOR <= tgCOLOR WHEN GRAF = '1' AND FONT_1bit = '1' ELSE
          tfCOLOR WHEN GRAF = '1' AND FONT_2bit = '1' ELSE
          tbCOLOR WHEN GRAF = '0' AND FONT_1bit = '1' ELSE
          tcCOLOR WHEN GRAF = '0' AND FONT_2bit = '1' ELSE
          PIXEL4;

b2v_MuxCOLOR : color_sel
PORT MAP(COLOR	=> tCOLOR,
	 RGB	=> RGB);

--WITH ( tCOLOR ) SELECT
--  RGB <=
--    "000" & "000" & "000"    WHEN "0000",
--    "000" & "000" & "011"    WHEN "0001",
--    "000" & "011" & "000"    WHEN "0010",
--    "000" & "011" & "011"    WHEN "0011",
--    "011" & "000" & "000"    WHEN "0100",
--    "011" & "000" & "011"    WHEN "0101",
--    "011" & "011" & "000"    WHEN "0110",
--    "011" & "011" & "011"    WHEN "0111",
--    "100" & "111" & "010"    WHEN "1000",
--    "000" & "000" & "111"    WHEN "1001",
--    "000" & "111" & "000"    WHEN "1010",
--    "000" & "111" & "111"    WHEN "1011",
--    "111" & "000" & "000"    WHEN "1100",
--    "111" & "000" & "111"    WHEN "1101",
--    "111" & "111" & "000"    WHEN "1110",
--    "111" & "111" & "111"    WHEN "1111";

B(2 DOWNTO 0) <= RGB(8 DOWNTO 6);
G(2 DOWNTO 0) <= RGB(5 DOWNTO 3);
R(2 DOWNTO 0) <= RGB(2 DOWNTO 0);

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------

REG0 <= NOT(CSreg) AND NOT(A(1)) AND NOT(A(0));
REG1 <= NOT(CSreg) AND NOT(A(1)) AND     A(0);
REG2 <= NOT(CSreg) AND     A(1)  AND NOT(A(0));
REG3 <= NOT(CSreg) AND     A(1)  AND     A(0);

PROCESS(RESET_n, REG0, CLK)
BEGIN
    IF (RESET_n = '0') THEN
        REG_CTRL(7 DOWNTO 0) <= "00000000";
    ELSIF (RISING_EDGE(CLK)) THEN
        REG_CTRL(7 DOWNTO 0) <= HS(11 DOWNTO 4);
    END IF;
END PROCESS;

-------------------------------------------------------------------------------

END bdf_type;