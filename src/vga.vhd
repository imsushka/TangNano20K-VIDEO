LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

LIBRARY work;

ENTITY VGA IS 
	PORT
	(
		CLK	:  IN STD_LOGIC;
		RESET_n	:  IN STD_LOGIC;

		CONTROL	:  IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		HSCROLLM:  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		VSCROLLM:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		HSCROLLS:  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		VSCROLLS:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		HSCROLLB:  IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		VSCROLLB:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		HCURSOR	:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);
		VCURSOR	:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);

		M_SPLIT0:  IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		M_SPLIT1:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);

		S_SPLIT0:  IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		S_SPLIT1:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);

		B_SPLIT0:  IN STD_LOGIC_VECTOR(5 DOWNTO 0);
		B_SPLIT1:  IN STD_LOGIC_VECTOR(6 DOWNTO 0);

		BLANK	:  IN STD_LOGIC;

		H       :  IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		V       :  IN STD_LOGIC_VECTOR(11 DOWNTO 0);

		ANIMAT	:  IN STD_LOGIC_VECTOR(2 DOWNTO 0);

		M_COLOR	: OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
		S_COLOR	: OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
		B_COLOR	: OUT STD_LOGIC_VECTOR(5 DOWNTO 0);

		MSEL	: OUT STD_LOGIC;
		MA	: OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
		MDi	:  IN STD_LOGIC_VECTOR(15 DOWNTO 0)
	);
END;

ARCHITECTURE bdf_type OF VGA IS 

SIGNAL	DOTBLANK	: STD_LOGIC;

SIGNAL	M_DOTCLK	: STD_LOGIC;
SIGNAL	M_DOTStep	: STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	M_F08x08	: STD_LOGIC;
SIGNAL	M_F08x16	: STD_LOGIC;
SIGNAL	M_F16x08	: STD_LOGIC;
SIGNAL	M_F16x16	: STD_LOGIC;
SIGNAL	M_F16x32	: STD_LOGIC;
SIGNAL	M_F32x16	: STD_LOGIC;
SIGNAL	M_F32x32	: STD_LOGIC;
SIGNAL	M_GRAF		: STD_LOGIC;

SIGNAL	M_FMULTY	: STD_LOGIC;
SIGNAL	M_EXTATR	: STD_LOGIC;
SIGNAL	M_FEXTEND	: STD_LOGIC;

SIGNAL	M_F08Pix	: STD_LOGIC;
SIGNAL	M_F16Pix	: STD_LOGIC;
SIGNAL	M_F32Pix	: STD_LOGIC;
SIGNAL	M_F08Line	: STD_LOGIC;
SIGNAL	M_F16Line	: STD_LOGIC;
SIGNAL	M_F32Line	: STD_LOGIC;

SIGNAL	M_FONT_1bpp	: STD_LOGIC;
SIGNAL	M_FONT_2bpp	: STD_LOGIC;
SIGNAL	M_FONT_4bpp	: STD_LOGIC;
SIGNAL	M_FONT_1bppE	: STD_LOGIC;

SIGNAL	M_SCALE_x1	: STD_LOGIC;
SIGNAL	M_SCALE_x2	: STD_LOGIC;
SIGNAL	M_SCALE_x4	: STD_LOGIC;

SIGNAL	S_DOTCLK	: STD_LOGIC;
SIGNAL	S_DOTStep	: STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	S_F08x08	: STD_LOGIC;
SIGNAL	S_F08x16	: STD_LOGIC;
SIGNAL	S_F16x08	: STD_LOGIC;
SIGNAL	S_F16x16	: STD_LOGIC;
SIGNAL	S_F16x32	: STD_LOGIC;
SIGNAL	S_F32x16	: STD_LOGIC;
SIGNAL	S_F32x32	: STD_LOGIC;
SIGNAL	S_F64X64	: STD_LOGIC;

SIGNAL	S_FMULTY	: STD_LOGIC;
SIGNAL	S_EXTATR	: STD_LOGIC;
SIGNAL	S_FEXTEND	: STD_LOGIC;

SIGNAL	S_F08Pix	: STD_LOGIC;
SIGNAL	S_F16Pix	: STD_LOGIC;
SIGNAL	S_F32Pix	: STD_LOGIC;
SIGNAL	S_F08Line	: STD_LOGIC;
SIGNAL	S_F16Line	: STD_LOGIC;
SIGNAL	S_F32Line	: STD_LOGIC;

SIGNAL	S_FONT_1bpp	: STD_LOGIC;
SIGNAL	S_FONT_2bpp	: STD_LOGIC;
SIGNAL	S_FONT_4bpp	: STD_LOGIC;
SIGNAL	S_FONT_1bppE	: STD_LOGIC;

SIGNAL	S_DISABLE	: STD_LOGIC;
SIGNAL	S_SCALE_x1	: STD_LOGIC;
SIGNAL	S_SCALE_x2	: STD_LOGIC;
SIGNAL	S_SCALE_x4	: STD_LOGIC;

SIGNAL	B_DOTCLK	: STD_LOGIC;
SIGNAL	B_DOTStep	: STD_LOGIC_VECTOR(2 DOWNTO 0);
SIGNAL	B_F08x08	: STD_LOGIC;
SIGNAL	B_F08x16	: STD_LOGIC;
SIGNAL	B_F16x08	: STD_LOGIC;
SIGNAL	B_F16x16	: STD_LOGIC;

SIGNAL	B_DISABLE	: STD_LOGIC;
SIGNAL	B_SCALE_x1	: STD_LOGIC;
SIGNAL	B_SCALE_x2	: STD_LOGIC;
SIGNAL	B_SCALE_x4	: STD_LOGIC;

SIGNAL	B_F08Pix	: STD_LOGIC;
SIGNAL	B_F16Pix	: STD_LOGIC;
SIGNAL	B_F08Line	: STD_LOGIC;
SIGNAL	B_F16Line	: STD_LOGIC;

SIGNAL	M_FBIG     : STD_LOGIC;
SIGNAL	S_FBIG     : STD_LOGIC;

SIGNAL	MvFONT     : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	MvFONT_C   : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	M_FONT0    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	S_FONT0    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	B_FONT0    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	M_FONT1    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	S_FONT1    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	B_FONT1    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	M_FONT2    : STD_LOGIC_VECTOR(15 DOWNTO 0);
SIGNAL	S_FONT2    : STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL  MvCOLOR    : STD_LOGIC_VECTOR(7 DOWNTO 0);

SIGNAL  M_COLORv   : STD_LOGIC_VECTOR(8 DOWNTO 2);
SIGNAL  S_COLORv   : STD_LOGIC_VECTOR(8 DOWNTO 2);
SIGNAL  B_COLORv   : STD_LOGIC_VECTOR(5 DOWNTO 2);

SIGNAL	M_HByte    : STD_LOGIC;
SIGNAL	M_HFlip    : STD_LOGIC;
SIGNAL	CURSOR     : STD_LOGIC;
SIGNAL	S_HByte    : STD_LOGIC;
SIGNAL	S_HFlip    : STD_LOGIC;

SIGNAL  M_COLs     : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL  S_COLs     : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL  M_ROWs     : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL  S_ROWs     : STD_LOGIC_VECTOR(4 DOWNTO 0);
SIGNAL  M_X        : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  S_X        : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  M_Y        : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL  S_Y        : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL  M_Xs       : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  S_Xs       : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL  M_Ys       : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL  S_Ys       : STD_LOGIC_VECTOR(6 DOWNTO 0);
SIGNAL  M_V        : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL  S_V        : STD_LOGIC_VECTOR(1 DOWNTO 0);
SIGNAL  B_V        : STD_LOGIC_VECTOR(1 DOWNTO 0);

SIGNAL	M_ADDR     : STD_LOGIC_VECTOR(17 DOWNTO 0);
SIGNAL	S_ADDR     : STD_LOGIC_VECTOR(17 DOWNTO 0);
SIGNAL	B_ADDR     : STD_LOGIC_VECTOR(17 DOWNTO 0);
SIGNAL	G_ADDR     : STD_LOGIC_VECTOR(17 DOWNTO 0);

--SIGNAL	SH0, SH1, SH2, SH3 : STD_LOGIC_VECTOR(7 downto 0);

BEGIN 
-------------------------------------------------------------------------------
-- 0x00000 - 0x07FFF = 32768 WORDS screen buffer master
-- 0x08000 - 0x0FFFF = 32768 WORDS screen buffer slave
-- 0x10000 - 0x1FFFF = 65536 WORDS fonts
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
-- 10-8  - Palette for 2bpps modes
-- 7-0   - tile index
--
--
-- ExFn - Extended font
-- AnBlk - Animation block
-- AnSiz - Animation size (0 bit in tile index if set AnBlk)
-- Pal - Palette
--                                  |  7  |  6  |  5  |  4  |  3  |  2  |  1  |  0  |CTRL7|TILE0|
--                                  |VFlip|HFlip|ExFn0|ExFn1|AnBlk|Pal2 |Pal1 |Pal0 |MFont|AnSiz|
-- Mode 08x08 1bppE (  8 bit font ) | yes   yes   yes   yes   yes   ext   ext   ext   yes   yes
-- Mode 08x16 1bppE (  8 bit font ) | yes   yes   yes   yes   yes   ext   ext   ext   yes   yes
--                                                                                             
-- Mode 08x08 2bpp (  16 bit font ) | yes   yes   yes   yes   yes   yes   yes   yes   yes   yes
-- Mode 08x16 2bpp (  16 bit font ) | yes   yes   yes   yes   yes   yes   yes   yes   yes   yes
-- Mode 16x08 2bpp (  32 bit font ) | yes   yes   yes   no    yes   yes   yes   yes   yes   yes
-- Mode 16x16 2bpp (  32 bit font ) | yes   yes   yes   no    yes   yes   yes   yes   yes   yes
--                                                                                             
-- Mode 08x08 4bpp (  32 bit font ) | yes   yes   yes   no    yes   ext   ext   ext   yes   yes
-- Mode 08x16 4bpp (  32 bit font ) | yes   yes   yes   no    yes   ext   ext   ext   yes   yes
-- Mode 16x08 4bpp (  64 bit font ) | yes   yes   no    no    yes   ext   ext   ext   yes   yes
-- Mode 16x16 4bpp (  64 bit font ) | yes   yes   no    no    yes   ext   ext   ext   yes   yes
--                                                                                             
-- Mode 16x32 2bpp (  32 bit font ) | yes   yes   no    no    yes   yes   yes   yes   no    yes
-- Mode 32x16 2bpp (  64 bit font ) | yes   yes   no    no    yes   yes   yes   yes   no    yes
-- Mode 32x32 2bpp (  64 bit font ) | yes   yes   no    no    yes   yes   yes   yes   no    yes
--                                                                                             
-- Mode 16x32 4bpp (  64 bit font ) | yes   yes   no    no    yes   ext   ext   ext   no    yes
-- Mode 32x16 4bpp ( 128 bit font ) | yes   yes   no    no    yes   ext   ext   ext   no    yes
-- Mode 32x32 4bpp ( 128 bit font ) | yes   yes   no    no    yes   ext   ext   ext   no    yes
--
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- STATIC CONFIGURATION -------------------------------------------------------
-------------------------------------------------------------------------------
-- Master plane
-------------------------------------------------------------------------------
M_F08x08     <= NOT(CONTROL(2)) AND NOT(CONTROL(1)) AND NOT(CONTROL(0));
M_F08x16     <= NOT(CONTROL(2)) AND NOT(CONTROL(1)) AND     CONTROL(0);
M_F16x08     <= NOT(CONTROL(2)) AND     CONTROL(1)  AND NOT(CONTROL(0));
M_F16x16     <= NOT(CONTROL(2)) AND     CONTROL(1)  AND     CONTROL(0);

M_GRAF       <=     CONTROL(2)  AND NOT(CONTROL(1)) AND NOT(CONTROL(0));
M_F16x32     <=     CONTROL(2)  AND NOT(CONTROL(1)) AND     CONTROL(0);
M_F32x16     <=     CONTROL(2)  AND     CONTROL(1)  AND NOT(CONTROL(0));
M_F32x32     <=     CONTROL(2)  AND     CONTROL(1)  AND     CONTROL(0);
-------------------------------------------------------------------------------
M_SCALE_x1   <= ( NOT(CONTROL(5)) AND NOT(CONTROL(4)) ) OR ( NOT(CONTROL(5)) AND CONTROL(4) );
M_SCALE_x2   <=       CONTROL(5)  AND NOT(CONTROL(4));
M_SCALE_x4   <=       CONTROL(5)  AND     CONTROL(4);

M_FONT_1bpp  <= ( NOT(CONTROL(7)) AND NOT(CONTROL(6)) ) OR ( CONTROL(7) AND CONTROL(6) AND NOT(M_F08Pix) );
M_FONT_2bpp  <=   NOT(CONTROL(7)) AND     CONTROL(6);
M_FONT_4bpp  <=       CONTROL(7)  AND NOT(CONTROL(6));
M_FONT_1bppE <=       CONTROL(7)  AND     CONTROL(6)    AND M_F08Pix;
-------------------------------------------------------------------------------
M_F08Pix     <= M_F08x08 OR M_F08x16;
M_F16Pix     <= M_F16x16 OR M_F16x08 OR M_F16x32;
M_F32Pix     <= M_F32x32 OR M_F32x16;

M_F08Line    <= M_F08x08 OR M_F16x08;
M_F16Line    <= M_F16x16 OR M_F08x16 OR M_F32x16;
M_F32Line    <= M_F32x32 OR M_F16x32;
-------------------------------------------------------------------------------
M_FMULTY     <= CONTROL(3) AND NOT(CONTROL(2));

M_EXTATR     <= NOT(M_GRAF) AND NOT(M_FONT_1bpp);
M_FEXTEND    <= M_EXTATR AND NOT(CONTROL(2));

--M_FBIG       <= M_F32x32 OR M_F16x32 OR M_F32x16;
-------------------------------------------------------------------------------
--M_GRAF4x4    <= M_FONT_4bpp AND M_SCALE_x4;
--M_GRAF2x4    <= M_FONT_2bpp AND M_SCALE_x4;
--M_GRAF2x2    <= M_FONT_2bpp AND M_SCALE_x2;
--M_GRAF1x4    <= M_FONT_1bpp AND M_SCALE_x4;
--M_GRAF1x2    <= M_FONT_1bpp AND M_SCALE_x2;
--M_GRAF1x1    <= M_FONT_1bpp AND M_SCALE_x1;

--M_GRAF+      <= (M_GRAF1x1 OR M_GRAF1x2 OR M_GRAF1x4 OR M_GRAF2x2 OR M_GRAF2x4 OR M_GRAF4x4) AND M_GRAF;
-------------------------------------------------------------------------------
M_DOTClk     <= '1' WHEN ( (M_SCALE_x1 = '1') OR
                           (M_SCALE_x2 = '1' AND H(0) = '0') OR
                           (M_SCALE_x4 = '1' AND H(1 DOWNTO 0) = "00") )
                           ELSE '0';
-------------------------------------------------------------------------------
M_COLs       <= H(6 DOWNTO 2) WHEN ( M_SCALE_x4 = '1' ) ELSE
                H(5 DOWNTO 1) WHEN ( M_SCALE_x2 = '1' ) ELSE
                H(4 DOWNTO 0);
-------------------------------------------------------------------------------
M_ROWs       <= V(6 DOWNTO 2) WHEN ( M_SCALE_x4 = '1' ) ELSE
                V(5 DOWNTO 1) WHEN ( M_SCALE_x2 = '1' ) ELSE
                V(4 DOWNTO 0);
-------------------------------------------------------------------------------
M_X          <= "00000" & H(9 DOWNTO 7) WHEN ( M_F32Pix = '1'  AND M_SCALE_x4 = '1' ) ELSE
                "0000"  & H(9 DOWNTO 6) WHEN ( M_F32Pix = '1'  AND M_SCALE_x2 = '1' ) OR
                                             ( M_F16Pix = '1'  AND M_SCALE_x4 = '1' ) ELSE
                "000"   & H(9 DOWNTO 5) WHEN ( M_F32Pix = '1'  AND M_SCALE_x1 = '1' ) OR
                                             ( M_F16Pix = '1'  AND M_SCALE_x2 = '1' ) OR
                                             ( M_F08Pix = '1'  AND M_SCALE_x4 = '1' ) ELSE
                "00"    & H(9 DOWNTO 4) WHEN ( M_F16Pix = '1'  AND M_SCALE_x1 = '1' ) OR
                                             ( M_F08Pix = '1'  AND M_SCALE_x2 = '1' ) ELSE
                '0'     & H(9 DOWNTO 3);
-------------------------------------------------------------------------------
M_Y          <= "0000" & V(9 DOWNTO 7) WHEN ( M_F32Line = '1'  AND M_SCALE_x4 = '1' ) ELSE
                "000"  & V(9 DOWNTO 6) WHEN ( M_F32Line = '1'  AND M_SCALE_x2 = '1' ) OR
                                            ( M_F16Line = '1'  AND M_SCALE_x4 = '1' ) ELSE
                "00"   & V(9 DOWNTO 5) WHEN ( M_F32Line = '1'  AND M_SCALE_x1 = '1' ) OR
                                            ( M_F16Line = '1'  AND M_SCALE_x2 = '1' ) OR
                                            ( M_F08Line = '1'  AND M_SCALE_x4 = '1' ) ELSE
                "0"    & V(9 DOWNTO 4) WHEN ( M_F16Line = '1'  AND M_SCALE_x1 = '1' ) OR
                                            ( M_F08Line = '1'  AND M_SCALE_x2 = '1' ) ELSE
                         V(9 DOWNTO 3);
-------------------------------------------------------------------------------
M_Xs         <= M_X + HSCROLLM WHEN CONTROL(28) = '0'    ELSE
                M_X            WHEN M_Y < '0' & M_SPLIT0 ELSE
                M_X + HSCROLLM WHEN M_Y <       M_SPLIT1 ELSE
                M_X;

M_Ys         <= M_Y + VSCROLLM WHEN CONTROL(28) = '0'    ELSE
                M_Y            WHEN M_Y < '0' & M_SPLIT0 ELSE
                M_Y + VSCROLLM WHEN M_Y <       M_SPLIT1 ELSE
                (M_Y(6) OR M_Y(5)) & (M_Y(5) XOR '1') & M_Y(4 DOWNTO 0);

M_V          <= "00"           WHEN M_FMULTY = '0'       ELSE
                V(9 DOWNTO 8)  WHEN CONTROL(28) = '0'    ELSE
                "01"           WHEN M_Y < '0' & M_SPLIT0 ELSE
                "10"           WHEN M_Y <       M_SPLIT1 ELSE
                "11";

-------------------------------------------------------------------------------
G_ADDR       <= "0000"    & V( 9 DOWNTO 2) & H( 9 DOWNTO 4) WHEN ( M_FONT_4bpp = '1' AND M_SCALE_x4 = '1' ) ELSE
--              "00000"   & V( 9 DOWNTO 2) & H( 9 DOWNTO 5) WHEN ( M_FONT_2bpp = '1' AND M_SCALE_x4 = '1' ) ELSE
                "000"     & V( 9 DOWNTO 1) & H( 9 DOWNTO 4) WHEN ( M_FONT_2bpp = '1' AND M_SCALE_x2 = '1' ) ELSE
--              "0000000" & V( 9 DOWNTO 2) & H( 9 DOWNTO 6) WHEN ( M_FONT_1bpp = '1' AND M_SCALE_x4 = '1' ) ELSE
--              "00000"   & V( 9 DOWNTO 1) & H( 9 DOWNTO 5) WHEN ( M_FONT_1bpp = '1' AND M_SCALE_x2 = '1' ) ELSE
                "00"      & V( 9 DOWNTO 0) & H( 9 DOWNTO 4);
-------------------------------------------------------------------------------
M_ADDR       <= G_ADDR WHEN M_GRAF = '1' ELSE "000" & M_Ys & M_Xs;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Slave plane
-------------------------------------------------------------------------------
S_F08x08      <=  NOT(CONTROL(10))  AND NOT(CONTROL(9)) AND NOT(CONTROL(8));
S_F08x16      <=  NOT(CONTROL(10))  AND NOT(CONTROL(9)) AND     CONTROL(8);
S_F16x08      <=  NOT(CONTROL(10))  AND     CONTROL(9)  AND NOT(CONTROL(8));
S_F16x16      <=  NOT(CONTROL(10))  AND     CONTROL(9)  AND     CONTROL(8);

S_F64x64      <=      CONTROL(10)   AND NOT(CONTROL(9)) AND NOT(CONTROL(8));
S_F16x32      <=      CONTROL(10)   AND NOT(CONTROL(9)) AND     CONTROL(8);
S_F32x16      <=      CONTROL(10)   AND     CONTROL(9)  AND NOT(CONTROL(8));
S_F32x32      <=      CONTROL(10)   AND     CONTROL(9)  AND     CONTROL(8);
-------------------------------------------------------------------------------
S_DISABLE     <=  NOT(CONTROL(13)) AND NOT(CONTROL(12));
S_SCALE_x1    <=  NOT(CONTROL(13)) AND     CONTROL(12);
S_SCALE_x2    <=      CONTROL(13)  AND NOT(CONTROL(12));
S_SCALE_x4    <=      CONTROL(13)  AND     CONTROL(12);

S_FONT_1bpp   <= (NOT(CONTROL(15)) AND NOT(CONTROL(14)) ) OR ( CONTROL(15) AND CONTROL(14) AND NOT(S_F08Pix) );
S_FONT_2bpp   <=  NOT(CONTROL(15)) AND     CONTROL(14);
S_FONT_4bpp   <=      CONTROL(15)  AND NOT(CONTROL(14));
S_FONT_1bppE  <=      CONTROL(15)  AND     CONTROL(14)    AND S_F08Pix;
-------------------------------------------------------------------------------
S_F08Pix     <= S_F08x08 OR S_F08x16;
S_F16Pix     <= S_F16x16 OR S_F16x08 OR S_F16x32 OR S_F64x64;
S_F32Pix     <= S_F32x32 OR S_F32x16;

S_F08Line    <= S_F08x08 OR S_F16x08;
S_F16Line    <= S_F16x16 OR S_F08x16 OR S_F32x16 OR S_F64x64;
S_F32Line    <= S_F32x32 OR S_F16x32;
-------------------------------------------------------------------------------
S_FMULTY      <= CONTROL(11) AND NOT(CONTROL(10));

S_EXTATR     <= NOT(S_FONT_1bpp);
S_FEXTEND    <= S_EXTATR AND NOT(CONTROL(10));
-------------------------------------------------------------------------------
S_DOTClk     <= '1' WHEN ( (S_SCALE_x1 = '1') OR
                           (S_SCALE_x2 = '1' AND H(0) = '0') OR
                           (S_SCALE_x4 = '1' AND H(1 DOWNTO 0) = "00") )
                           ELSE '0';
-------------------------------------------------------------------------------
S_COLs       <= H(6 DOWNTO 2) WHEN ( S_SCALE_x4 = '1' ) ELSE
                H(5 DOWNTO 1) WHEN ( S_SCALE_x2 = '1' ) ELSE
                H(4 DOWNTO 0);
-------------------------------------------------------------------------------
S_ROWs       <= V(6 DOWNTO 2) WHEN ( S_SCALE_x4 = '1' ) ELSE
                V(5 DOWNTO 1) WHEN ( S_SCALE_x2 = '1' ) ELSE
                V(4 DOWNTO 0);
-------------------------------------------------------------------------------
S_X          <= "00000" & H(9 DOWNTO 7) WHEN ( S_F32Pix = '1'  AND S_SCALE_x4 = '1' ) ELSE
                "0000"  & H(9 DOWNTO 6) WHEN ( S_F32Pix = '1'  AND S_SCALE_x2 = '1' ) OR
                                             ( S_F16Pix = '1'  AND S_SCALE_x4 = '1' ) ELSE
                "000"   & H(9 DOWNTO 5) WHEN ( S_F32Pix = '1'  AND S_SCALE_x1 = '1' ) OR
                                             ( S_F16Pix = '1'  AND S_SCALE_x2 = '1' ) OR
                                             ( S_F08Pix = '1'  AND S_SCALE_x4 = '1' ) ELSE
                "00"    & H(9 DOWNTO 4) WHEN ( S_F16Pix = '1'  AND S_SCALE_x1 = '1' ) OR
                                             ( S_F08Pix = '1'  AND S_SCALE_x2 = '1' ) ELSE
                '0'     & H(9 DOWNTO 3);
-------------------------------------------------------------------------------
S_Y          <= "0000" & V(9 DOWNTO 7) WHEN ( S_F32Line = '1'  AND S_SCALE_x4 = '1' ) ELSE
                "000"  & V(9 DOWNTO 6) WHEN ( S_F32Line = '1'  AND S_SCALE_x2 = '1' ) OR
                                            ( S_F16Line = '1'  AND S_SCALE_x4 = '1' ) ELSE
                "00"   & V(9 DOWNTO 5) WHEN ( S_F32Line = '1'  AND S_SCALE_x1 = '1' ) OR
                                            ( S_F16Line = '1'  AND S_SCALE_x2 = '1' ) OR
                                            ( S_F08Line = '1'  AND S_SCALE_x4 = '1' ) ELSE
                "0"    & V(9 DOWNTO 4) WHEN ( S_F16Line = '1'  AND S_SCALE_x1 = '1' ) OR
                                            ( S_F08Line = '1'  AND S_SCALE_x2 = '1' ) ELSE
                         V(9 DOWNTO 3);
-------------------------------------------------------------------------------
S_Xs         <= S_X + HSCROLLS WHEN CONTROL(29) = '0' ELSE
                S_X            WHEN S_Y < '0' & S_SPLIT0 ELSE
                S_X + HSCROLLS WHEN S_Y <       S_SPLIT1 ELSE
                S_X;

S_Ys         <= S_Y + VSCROLLS WHEN CONTROL(29) = '0' ELSE
                S_Y            WHEN S_Y < '0' & S_SPLIT0 ELSE
                S_Y + VSCROLLS WHEN S_Y <       S_SPLIT1 ELSE
                (S_Y(6) OR S_Y(5)) & (S_Y(5) XOR '1') & S_Y(4 DOWNTO 0);

S_V          <= "00"           WHEN S_FMULTY = '0'       ELSE
                V(9 DOWNTO 8)  WHEN CONTROL(29) = '0'    ELSE
                "01"           WHEN S_Y < '0' & S_SPLIT0 ELSE
                "10"           WHEN S_Y <       S_SPLIT1 ELSE
                "11";

-------------------------------------------------------------------------------
S_ADDR       <= "001" & S_Ys & S_Xs;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- Background plane
-------------------------------------------------------------------------------
--B_F08x08      <=  NOT(CONTROL(17)) AND NOT(CONTROL(16));
--B_F08x16      <=  NOT(CONTROL(17)) AND     CONTROL(16);
--B_F16x08      <=      CONTROL(17)  AND NOT(CONTROL(16));
--B_F16x16      <=      CONTROL(17)  AND     CONTROL(16);
-------------------------------------------------------------------------------
--B_FONT_1bpp   <=  NOT(CONTROL(22));
--B_FONT_2bpp   <=      CONTROL(22);

--B_DISABLE     <=  NOT(CONTROL(21)) AND NOT(CONTROL(20));
--B_SCALE_x1    <=  NOT(CONTROL(21)) AND     CONTROL(20);
--B_SCALE_x2    <=      CONTROL(21)  AND NOT(CONTROL(20));
--B_SCALE_x4    <=      CONTROL(21)  AND     CONTROL(20);
-------------------------------------------------------------------------------
--B_F08Pix     <= B_F08x08 OR B_F08x16;
--B_F16Pix     <= B_F16x16 OR B_F16x08;

--B_F08Line    <= B_F08x08 OR B_F16x08;
--B_F16Line    <= B_F16x16 OR B_F08x16;
-------------------------------------------------------------------------------
--B_FMULTY     <= CONTROL(19);

--B_EXTATR     <= NOT(B_FONT_1bpp);
--B_FEXTEND    <= B_EXTATR AND NOT(CONTROL( ));
-------------------------------------------------------------------------------
--B_DOTClk     <= '1' WHEN ( (B_SCALE_x1 = '1') OR
--                           (B_SCALE_x2 = '1' AND H(0) = '0') OR
--                           (B_SCALE_x4 = '1' AND H(1 DOWNTO 0) = "00") )
--                           ELSE '0';
-------------------------------------------------------------------------------
--B_COLs       <= H(6 DOWNTO 2) WHEN ( B_SCALE_x4 = '1' ) ELSE
--                H(5 DOWNTO 1) WHEN ( B_SCALE_x2 = '1' ) ELSE
--                H(4 DOWNTO 0);
-------------------------------------------------------------------------------
--B_ROWs       <= V(6 DOWNTO 2) WHEN ( B_SCALE_x4 = '1' ) ELSE
--                V(5 DOWNTO 1) WHEN ( B_SCALE_x2 = '1' ) ELSE
--                V(4 DOWNTO 0);
-------------------------------------------------------------------------------
--B_X          <= "0000"  & H(9 DOWNTO 6) WHEN ( B_F16Pix = '1'  AND B_SCALE_x4 = '1' ) ELSE
--                "000"   & H(9 DOWNTO 5) WHEN ( B_F16Pix = '1'  AND B_SCALE_x2 = '1' ) OR
--                                             ( B_F08Pix = '1'  AND B_SCALE_x4 = '1' ) ELSE
--                "00"    & H(9 DOWNTO 4) WHEN ( B_F16Pix = '1'  AND B_SCALE_x1 = '1' ) OR
--                                             ( B_F08Pix = '1'  AND B_SCALE_x2 = '1' ) ELSE
--                '0'     & H(9 DOWNTO 3);
-------------------------------------------------------------------------------
--B_Y          <= "000"  & V(9 DOWNTO 6) WHEN ( B_F16Line = '1'  AND B_SCALE_x4 = '1' ) ELSE
--                "00"   & V(9 DOWNTO 5) WHEN ( B_F16Line = '1'  AND B_SCALE_x2 = '1' ) OR
--                                            ( B_F08Line = '1'  AND B_SCALE_x4 = '1' ) ELSE
--                "0"    & V(9 DOWNTO 4) WHEN ( B_F16Line = '1'  AND B_SCALE_x1 = '1' ) OR
--                                            ( B_F08Line = '1'  AND B_SCALE_x2 = '1' ) ELSE
--                         V(9 DOWNTO 3);
-------------------------------------------------------------------------------
--B_Xs         <= B_X + HSCROLLB WHEN CONTROL(30) = '0' ELSE
--                B_X            WHEN B_Y < '0' & B_SPLIT0 ELSE
--                B_X + HSCROLLB WHEN B_Y <       B_SPLIT1 ELSE
--                B_X;

--B_Ys         <= B_Y + VSCROLLB WHEN CONTROL(30) = '0' ELSE
--                B_Y            WHEN B_Y < '0' & B_SPLIT0 ELSE
--                B_Y + VSCROLLB WHEN B_Y <       B_SPLIT1 ELSE
--                (B_Y(6) OR B_Y(5)) & (B_Y(5) XOR '1') & B_Y(4 DOWNTO 0);

--B_V          <= "00"           WHEN B_FMULTY = '0'       ELSE
--                V(9 DOWNTO 8)  WHEN CONTROL(30) = '0'    ELSE
--                "01"           WHEN B_Y < '0' & B_SPLIT0 ELSE
--                "10"           WHEN B_Y <       B_SPLIT1 ELSE
--                "11";

-------------------------------------------------------------------------------
--B_ADDR       <= "010" & B_Ys & B_Xs;
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
--PROCESS(CLK, H)
--BEGIN
--  IF (RISING_EDGE(CLK)) THEN
--    IF H(2 DOWNTO 0) = "001" THEN
--      M_FONT0 <= MDi;
--    END IF;
--    IF H(2 DOWNTO 0) = "010" THEN
--      S_FONT0 <= MDi;
--    END IF;
--    IF H(2 DOWNTO 0) = "011" THEN
--      M_FONT1 <= MDi;
--    END IF;
--    IF H(2 DOWNTO 0) = "100" THEN
--      S_FONT1 <= MDi;
--    END IF;
--    IF H(2 DOWNTO 0) = "101" THEN
--      M_FONT2 <= MDi;
--    END IF;
--    IF H(2 DOWNTO 0) = "110" THEN
--      S_FONT2 <= MDi;
--    END IF;
--  END IF;
--END PROCESS;
-------------------------------------------------------------------------------
-- 000 - master screen (master tile map) 64 kbytes
-- 001 - slave screen  (slave tile map)  64 kbytes
-- 01x - font          (tile)           128 kbytes
--                                total 256 kbytes (128k x 16bit)
-- 100 - background screen               64 kbytes
-- 101 -                                 64 kbytes
-- 110 - sprite map                      64 kbytes
-- 111 - sprite tile                     64 kbytes
--                                total 256 kbytes (128k x 16bit)
-------------------------------------------------------------------------------
-- MEMORY ACCESS - Font 4 bits
-------------------------------------------------------------------------------
PROCESS(CLK, H,         V,         M_COLs, M_ROWs, M_X, M_Y,
             BLANK,     M_FMULTY,   M_GRAF,
             M_F32Pix,    M_F16Pix,    M_F08Pix, 
             M_F32Line,   M_F16Line,   M_F08Line, 
             M_FONT_4bpp, M_FONT_2bpp, M_FONT_1bpp )

variable vMADDR      : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vMFONT      : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vMATTRIBUTE : STD_LOGIC_VECTOR(7 DOWNTO 0);

variable vMLINE      : STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vMCOL       : STD_LOGIC_VECTOR(4 DOWNTO 0);

variable vMCOLOR     : STD_LOGIC_VECTOR(8 DOWNTO 2);

variable vSADDR      : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vSFONT      : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vSATTRIBUTE : STD_LOGIC_VECTOR(7 DOWNTO 0);

variable vSLINE      : STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vSCOL       : STD_LOGIC_VECTOR(4 DOWNTO 0);

variable vSCOLOR     : STD_LOGIC_VECTOR(8 DOWNTO 2);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(CLK)) THEN

    IF ( BLANK = '0' ) THEN
      DOTBLANK <= '0';
    END IF;
--    ELSE
    CASE H(2 DOWNTO 0) IS
-------------------------------------------------------------------------------
    WHEN "000" =>
      MA <= M_ADDR;
-------------------------------------------------------------------------------
    WHEN "001" =>
      M_FONT0 <= MDi;

      vMFONT      := MDi( 7 DOWNTO 0);
      vMATTRIBUTE := MDi(15 DOWNTO 8);
------
      MA <= S_ADDR;
-------------------------------------------------------------------------------
    WHEN "010" =>
      S_FONT0 <= MDi;

      vSFONT      := MDi( 7 DOWNTO 0);
      vSATTRIBUTE := MDi(15 DOWNTO 8);
------
      IF ( M_EXTATR = '1' AND vMATTRIBUTE(7) = '1' ) THEN -- VFlip
        vMLINE := NOT(M_ROWs);
      ELSE
        vMLINE := M_ROWs;
      END IF;

      IF ( M_EXTATR = '1' AND vMATTRIBUTE(6) = '1' ) THEN -- HFlip
        vMCOL := NOT(M_COLs);
      ELSE
        vMCOL := M_COLs;
      END IF;

      IF ( M_EXTATR = '1' AND vMATTRIBUTE(3) = '1' ) THEN -- Animation
        vMFONT(2) := (vMFONT(2) AND NOT(vMFONT(0))) OR (ANIMAT(2) AND vMFONT(0));
        vMFONT(1) := ANIMAT(1);
        vMFONT(0) := ANIMAT(0);
      END IF;

      IF ( CONTROL(2) = '1' )  THEN
        vMADDR(15 DOWNTO 8) := vMFONT;
        vMADDR( 7 DOWNTO 3) := vMLINE;
        vMADDR(2)           := M_F32Pix AND vMCOL(4);
      ELSE
        vMADDR(15)          := M_V(1);
        vMADDR(14)          := M_V(0);
        vMADDR(13 DOWNTO 6) := vMFONT;
        vMADDR(5)           := NOT(M_F08line) AND vMLINE(3);
        vMADDR(4 DOWNTO 2)  := vMLINE(2 DOWNTO 0);
      END IF;
    
      IF ( M_F08Pix = '1' )  THEN
        vMADDR(1) := M_FEXTEND AND vMATTRIBUTE(4);
      ELSE
        vMADDR(1) := NOT(M_FONT_1bpp OR M_FONT_1bppE) AND vMCOL(3);
      END IF;

      IF ( M_FONT_4bpp = '1' ) THEN
        vMADDR(0)  := vMCOL(2);
      ELSE
        vMADDR(0) := M_FEXTEND AND vMATTRIBUTE(5);
      END IF;

      MA <= "10" & vMADDR;
-------------------------------------------------------------------------------
    WHEN "011" =>
      M_FONT1 <= MDi;
------
      IF ( S_EXTATR = '1' AND vSATTRIBUTE(7) = '1' ) THEN -- VFlip
        vSLINE := NOT(S_ROWs);
      ELSE
        vSLINE := S_ROWs;
      END IF;

      IF ( S_EXTATR = '1' AND vSATTRIBUTE(6) = '1' ) THEN -- HFlip
        vSCOL := NOT(S_COLs);
      ELSE
        vSCOL := S_COLs;
      END IF;

      IF ( S_EXTATR = '1' AND vSATTRIBUTE(3) = '1' ) THEN -- Animation
        vSFONT(2) := (vSFONT(2) AND NOT(vSFONT(0))) OR (ANIMAT(2) AND vSFONT(0));
        vSFONT(1) := ANIMAT(1);
        vSFONT(0) := ANIMAT(0);
      END IF;

      IF ( CONTROL(10) = '1' )  THEN
        vSADDR(15 DOWNTO 8) := vSFONT;
        vSADDR( 7 DOWNTO 3) := vSLINE;
        vSADDR(2)           := S_F32Pix AND vSCOL(4);
      ELSE
        vSADDR(15)          := S_V(1);
        vSADDR(14)          := S_V(0);
        vSADDR(13 DOWNTO 6) := vSFONT;
        vSADDR(5)           := NOT(S_F08line) AND vSLINE(3);
        vSADDR(4 DOWNTO 2)  := vSLINE(2 DOWNTO 0);
      END IF;
    
      IF ( S_F08Pix = '1' )  THEN
        vSADDR(1) := S_FEXTEND AND vSATTRIBUTE(4);
      ELSE
        vSADDR(1) := NOT(S_FONT_1bpp OR S_FONT_1bppE) AND vSCOL(3);
      END IF;

      IF ( S_FONT_4bpp = '1' ) THEN
        vSADDR(0)  := vSCOL(2);
      ELSE
        vSADDR(0) := S_FEXTEND AND vSATTRIBUTE(5);
      END IF;

      MA <= "10" & vSADDR;
-------------------------------------------------------------------------------
    WHEN "100" =>
      S_FONT1 <= MDi;
------
      IF ( M_FONT_4bpp = '1' ) THEN
        vMADDR(0) := NOT(vMCOL(2));
      ELSE
        vMADDR(0) := M_FEXTEND AND vMATTRIBUTE(5);
      END IF;

      vMCOLOR(8) := '0';
      vMCOLOR(7) := M_V(1);
      vMCOLOR(6) := '0';
      vMCOLOR(5) := M_V(0);
      vMCOLOR(4) := '0';
      vMCOLOR(3) := '0';
      vMCOLOR(2) := '0';
      IF ( M_FONT_2bpp = '1' ) THEN
        vMCOLOR(4) := vMATTRIBUTE(2);
        vMCOLOR(3) := vMATTRIBUTE(1);
        vMCOLOR(2) := vMATTRIBUTE(0);
      ELSIF ( ( M_FONT_4bpp = '1' OR M_FONT_1bppE = '1' ) AND vMATTRIBUTE(2 DOWNTO 0) /= "000" ) THEN
        vMCOLOR(8) := '1';
        vMCOLOR(7) := '0';
        vMCOLOR(6) := vMATTRIBUTE(2);
        vMCOLOR(5) := vMATTRIBUTE(1);
        vMCOLOR(4) := vMATTRIBUTE(0);
      END IF;

      MA <= "10" & vMADDR;
-------------------------------------------------------------------------------
    WHEN "101" =>
      M_FONT2 <= MDi;
------
      IF ( S_FONT_4bpp = '1' ) THEN
        vSADDR(0) := NOT(vSCOL(2));
      ELSE
        vSADDR(0) := S_FEXTEND AND vSATTRIBUTE(5);
      END IF;

      vSCOLOR(8) := '0';
      vSCOLOR(7) := S_V(1);
      vSCOLOR(6) := '0';
      vSCOLOR(5) := S_V(0);
      vSCOLOR(4) := '0';
      vSCOLOR(3) := '0';
      vSCOLOR(2) := '0';
      IF ( S_FONT_2bpp = '1' ) THEN
        vSCOLOR(4) := vSATTRIBUTE(2);
        vSCOLOR(3) := vSATTRIBUTE(1);
        vSCOLOR(2) := vSATTRIBUTE(0);
      ELSIF ( ( S_FONT_4bpp = '1' OR S_FONT_1bppE = '1' ) AND vSATTRIBUTE(2 DOWNTO 0) /= "000" ) THEN
        vSCOLOR(8) := '1';
        vSCOLOR(7) := '0';
        vSCOLOR(6) := vSATTRIBUTE(2);
        vSCOLOR(5) := vSATTRIBUTE(1);
        vSCOLOR(4) := vSATTRIBUTE(0);
      END IF;

      MA <= "10" & vSADDR;
-------------------------------------------------------------------------------
    WHEN "110" =>
      S_FONT2 <= MDi;
------
      MSEL <= '1';
-------------------------------------------------------------------------------
    WHEN "111" =>
--------
      IF ( CONTROL(24) = '1' AND VCURSOR = M_Y AND HCURSOR = M_X(6 DOWNTO 0) ) THEN
        CURSOR <= '1' AND M_FONT_1bpp;
      ELSE
        CURSOR <= '0';
      END IF;
--------
      DOTBLANK <= '1';

      M_HByte <= NOT M_F08Pix AND (NOT(vMCOL(3)) XOR (M_EXTATR AND vMATTRIBUTE(6)));
      M_HFlip <= M_EXTATR AND vMATTRIBUTE(6);

      M_COLORv <= vMCOLOR;

      S_HByte <= NOT S_F08Pix AND (NOT(vSCOL(3)) XOR (S_EXTATR AND vSATTRIBUTE(6)));
      S_HFlip <= S_EXTATR AND vSATTRIBUTE(6);

      S_COLORv <= vSCOLOR;

      MSEL <= '0';
    END CASE;

--    END IF;
  END IF;
-------------------------------------------------------------------------------
END PROCESS;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
--PROCESS(CLK)
--BEGIN
--  IF (RISING_EDGE(CLK)) THEN
--    IF H(2 DOWNTO 0) = "010" THEN
--      M_FONT0 <= VDi;
--    END IF;
--  END IF;
--END PROCESS;

--PROCESS(CLK)
--BEGIN
--  IF (RISING_EDGE(CLK)) THEN
--    IF H(2 DOWNTO 0) = "100" THEN
--      M_FONT1 <= VDi;
--    END IF;
--  END IF;
--END PROCESS;

--PROCESS(CLK)
--BEGIN
--  IF (RISING_EDGE(CLK)) THEN
--    IF H(2 DOWNTO 0) = "110" THEN
--      M_FONT2 <= VDi;
--    END IF;
--  END IF;
--END PROCESS;

--PROCESS(CLK)
--BEGIN
--  IF (RISING_EDGE(CLK)) THEN
--    IF H(2 DOWNTO 0) = "111" THEN
--      IF ( CONTROL(18) = '1' AND VCURSOR = M_Y AND HCURSOR = M_X(6 DOWNTO 0) ) THEN
--        CURSOR <= '1' AND M_FONT_1bpp;
--      ELSE
--        CURSOR <= '0';
--      END IF;
--
--      MvFONT_C <= M_FONT2;
--
--      IF ( M_GRAF = '1' ) THEN
--        MvFONT <= M_FONT0;
--
--        MvCOLOR <= "00001111";
--      ELSE
--        MvFONT <= M_FONT1;
--
--        IF ( M_FONT_1bppE = '1' ) THEN
--          MvCOLOR <= M_FONT1(15 DOWNTO 8);
--        ELSE
--          MvCOLOR <= M_FONT0(15 DOWNTO 8);
--        END IF;
--      END IF;
--    END IF;
--  END IF;
--END PROCESS;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- OUT Master
-------------------------------------------------------------------------------
PROCESS(CLK, M_DOTCLK, M_DOTStep, DOTBLANK,
             M_FONT0, M_FONT1, M_FONT2,
             M_GRAF, M_FONT_2bpp, M_FONT_1bpp, M_FONT_1bppE)

variable vCOLOR    : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable tCOLOR    : STD_LOGIC_VECTOR(8 DOWNTO 0);
variable eCOLOR    : STD_LOGIC_VECTOR(8 DOWNTO 2);

variable tCURSOR   : STD_LOGIC;
variable tTMP      : STD_LOGIC;

variable vFONT     : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONTe    : STD_LOGIC_VECTOR(15 DOWNTO 0);

variable vPIXEL1   : STD_LOGIC;
variable vPIXEL2   : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vPIXEL4   : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(CLK)) THEN
    IF M_DOTCLK = '1' THEN

      CASE M_DOTStep IS
      WHEN "000" =>
        tCURSOR := CURSOR;
--------
--        vFONT  := MvFONT;
--        vCOLOR := MvCOLOR;

        IF ( M_GRAF = '1' ) THEN
          vFONT := M_FONT0;

          vCOLOR := "00001111";
        ELSE
          vFONT := M_FONT1;

          IF ( M_FONT_1bppE = '1' ) THEN
            vCOLOR := M_FONT1(15 DOWNTO 8);
          ELSE
            vCOLOR := M_FONT0(15 DOWNTO 8);
          END IF;
        END IF;
--------
        eCOLOR  := M_COLORv;

        vFONTe := M_FONT2;

        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(8);
          ELSE
            vPIXEL1 := vFONT(0);
          END IF;
          vPIXEL2   := vFONT( 1 DOWNTO  0);
          vPIXEL4   := vFONTe( 3 DOWNTO  0);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(15);
          ELSE
            vPIXEL1 := vFONT(7);
          END IF;
          vPIXEL2   := vFONT(15 DOWNTO 14);
          vPIXEL4   := vFONT(15 DOWNTO 12);
        END IF;

        IF ( DOTBLANK = '0' ) THEN
          M_DOTStep <= "000";
        ELSE
          M_DOTStep <= "001";
        END IF;
-------------------------------------------------------------------------------
      WHEN "001" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(9);
          ELSE
            vPIXEL1 := vFONT(1);
          END IF;
          vPIXEL2   := vFONT( 3 DOWNTO  2);
          vPIXEL4   := vFONTe( 7 DOWNTO  4);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(14);
          ELSE
            vPIXEL1 := vFONT(6);
          END IF;
          vPIXEL2   := vFONT(13 DOWNTO 12);
          vPIXEL4   := vFONT(11 DOWNTO 8);
        END IF;

        M_DOTStep <= "010";
-------------------------------------------------------------------------------
      WHEN "010" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(10);
          ELSE
            vPIXEL1 := vFONT(2);
          END IF;
          vPIXEL2   := vFONT(5 DOWNTO 4);
          vPIXEL4   := vFONTe(11 DOWNTO 8);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(13);
          ELSE
            vPIXEL1 := vFONT(5);
          END IF;
          vPIXEL2   := vFONT(11 DOWNTO 10);
          vPIXEL4   := vFONT(7 DOWNTO 4);
        END IF;

        M_DOTStep <= "011";
-------------------------------------------------------------------------------
      WHEN "011" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(11);
          ELSE
            vPIXEL1 := vFONT(3);
          END IF;
          vPIXEL2   := vFONT( 7 DOWNTO  6);
          vPIXEL4   := vFONTe(15 DOWNTO 12);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(12);
          ELSE
            vPIXEL1 := vFONT(4);
          END IF;
          vPIXEL2   := vFONT(9 DOWNTO 8);
          vPIXEL4   := vFONT(3 DOWNTO 0);
        END IF;

        IF ( M_GRAF = '1' AND M_SCALE_x4 = '1' AND M_FONT_4bpp = '1' ) THEN
          M_DOTStep <= "000";
        ELSE
          M_DOTStep <= "100";
        END IF;
-------------------------------------------------------------------------------
      WHEN "100" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(12);
          ELSE
            vPIXEL1 := vFONT(4);
          END IF;
          vPIXEL2   := vFONT( 9 DOWNTO  8);
          vPIXEL4   := vFONT(3 DOWNTO 0);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(11);
          ELSE
            vPIXEL1 := vFONT(3);
          END IF;
          vPIXEL2   := vFONT(7 DOWNTO 6);
          vPIXEL4   := vFONTe(15 DOWNTO 12);
        END IF;

        M_DOTStep <= "101";
-------------------------------------------------------------------------------
      WHEN "101" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(13);
          ELSE
            vPIXEL1 := vFONT(5);
          END IF;
          vPIXEL2   := vFONT(11 DOWNTO 10);
          vPIXEL4   := vFONT(7 DOWNTO 4);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(10);
          ELSE
            vPIXEL1 := vFONT(2);
          END IF;
          vPIXEL2   := vFONT(5 DOWNTO 4);
          vPIXEL4   := vFONTe(11 DOWNTO 8);
        END IF;

        M_DOTStep <= "110";
-------------------------------------------------------------------------------
      WHEN "110" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(14);
          ELSE
            vPIXEL1 := vFONT(6);
          END IF;
          vPIXEL2   := vFONT(13 DOWNTO 12);
          vPIXEL4   := vFONT(11 DOWNTO 8);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(9);
          ELSE
            vPIXEL1 := vFONT(1);
          END IF;
          vPIXEL2   := vFONT(3 DOWNTO 2);
          vPIXEL4   := vFONTe(7 DOWNTO 4);
        END IF;

        M_DOTStep <= "111";
-------------------------------------------------------------------------------
      WHEN "111" =>
        IF ( M_HFlip = '1' ) THEN
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(15);
          ELSE
            vPIXEL1 := vFONT(7);
          END IF;
          vPIXEL2   := vFONT(15 DOWNTO 14);
          vPIXEL4   := vFONT(15 DOWNTO 12);
        ELSE
          IF ( M_HByte = '1' ) THEN
            vPIXEL1 := vFONT(8);
          ELSE
            vPIXEL1 := vFONT(0);
          END IF;
          vPIXEL2   := vFONT(1 DOWNTO 0);
          vPIXEL4   := vFONTe(3 DOWNTO 0);
        END IF;

        M_DOTStep <= "000";
      END CASE;
-------------------------------------------------------------------------------
    END IF;
-------------------------------------------------------------------------------
    IF ( DOTBLANK = '0' ) THEN
      tCOLOR := (OTHERS => '0');
    ELSE
      IF ( ( M_FONT_1bpp OR M_FONT_1bppE ) = '1' ) THEN
        tTMP := tCURSOR XOR vPIXEL1;
        IF ( tTMP = '1' ) THEN
          tCOLOR := eCOLOR(8 DOWNTO 4) & vCOLOR(3 DOWNTO 0);
        ELSE
          tCOLOR := eCOLOR(8 DOWNTO 4) & vCOLOR(7 DOWNTO 4);
        END IF;
      ELSIF ( M_FONT_2bpp = '1' ) THEN
        tCOLOR := eCOLOR & vPIXEL2;
      ELSE
        tCOLOR := eCOLOR(8 DOWNTO 4) & vPIXEL4;
      END IF;
    END IF;

  END IF;
-------------------------------------------------------------------------------
  M_COLOR <= tCOLOR;
-------------------------------------------------------------------------------
END PROCESS;

-------------------------------------------------------------------------------
-- OUT Slave
-------------------------------------------------------------------------------
PROCESS(CLK, S_DOTCLK, S_DOTStep, DOTBLANK,
             S_FONT0, S_FONT1, S_FONT2,
             S_FONT_2bpp, S_FONT_1bpp, S_FONT_1bppE)

variable vCOLOR    : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable tCOLOR    : STD_LOGIC_VECTOR(8 DOWNTO 0);
variable eCOLOR    : STD_LOGIC_VECTOR(8 DOWNTO 2);

variable vFONT     : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vFONTe    : STD_LOGIC_VECTOR(15 DOWNTO 0);

variable vPIXEL1   : STD_LOGIC;
variable vPIXEL2   : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vPIXEL4   : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
-------------------------------------------------------------------------------
  IF (RISING_EDGE(CLK)) THEN
    IF S_DOTCLK = '1' THEN

      CASE S_DOTStep IS
      WHEN "000" =>

        IF ( S_FONT_1bppE = '1' ) THEN
          vCOLOR := S_FONT1(15 DOWNTO 8);
        ELSE
          vCOLOR := S_FONT0(15 DOWNTO 8);
        END IF;

        eCOLOR := S_COLORv;

        vFONT  := S_FONT1;
        vFONTe := S_FONT2;

        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(8);
          ELSE
            vPIXEL1 := vFONT(0);
          END IF;
          vPIXEL2   := vFONT( 1 DOWNTO  0);
          vPIXEL4   := vFONTe( 3 DOWNTO  0);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(15);
          ELSE
            vPIXEL1 := vFONT(7);
          END IF;
          vPIXEL2   := vFONT(15 DOWNTO 14);
          vPIXEL4   := vFONT(15 DOWNTO 12);
        END IF;

        IF ( DOTBLANK = '0' ) THEN
          S_DOTStep <= "000";
        ELSE
          S_DOTStep <= "001";
        END IF;
-------------------------------------------------------------------------------
      WHEN "001" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(9);
          ELSE
            vPIXEL1 := vFONT(1);
          END IF;
          vPIXEL2   := vFONT( 3 DOWNTO  2);
          vPIXEL4   := vFONTe( 7 DOWNTO  4);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(14);
          ELSE
            vPIXEL1 := vFONT(6);
          END IF;
          vPIXEL2   := vFONT(13 DOWNTO 12);
          vPIXEL4   := vFONT(11 DOWNTO 8);
        END IF;

        S_DOTStep <= "010";
-------------------------------------------------------------------------------
      WHEN "010" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(10);
          ELSE
            vPIXEL1 := vFONT(2);
          END IF;
          vPIXEL2   := vFONT( 5 DOWNTO  4);
          vPIXEL4   := vFONTe(11 DOWNTO 8);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(13);
          ELSE
            vPIXEL1 := vFONT(5);
          END IF;
          vPIXEL2   := vFONT(11 DOWNTO 10);
          vPIXEL4   := vFONT(7 DOWNTO 4);
        END IF;

        S_DOTStep <= "011";
-------------------------------------------------------------------------------
      WHEN "011" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(11);
          ELSE
            vPIXEL1 := vFONT(3);
          END IF;
          vPIXEL2   := vFONT( 7 DOWNTO  6);
          vPIXEL4   := vFONTe(15 DOWNTO 12);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(12);
          ELSE
            vPIXEL1 := vFONT(4);
          END IF;
          vPIXEL2   := vFONT(9 DOWNTO 8);
          vPIXEL4   := vFONT(3 DOWNTO 0);
        END IF;

        S_DOTStep <= "100";
-------------------------------------------------------------------------------
      WHEN "100" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(12);
          ELSE
            vPIXEL1 := vFONT(4);
          END IF;
          vPIXEL2   := vFONT( 9 DOWNTO  8);
          vPIXEL4   := vFONT(3 DOWNTO 0);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(11);
          ELSE
            vPIXEL1 := vFONT(3);
          END IF;
          vPIXEL2   := vFONT(7 DOWNTO 6);
          vPIXEL4   := vFONTe(15 DOWNTO 12);
        END IF;

        S_DOTStep <= "101";
-------------------------------------------------------------------------------
      WHEN "101" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(13);
          ELSE
            vPIXEL1 := vFONT(5);
          END IF;
          vPIXEL2   := vFONT(11 DOWNTO 10);
          vPIXEL4   := vFONT(7 DOWNTO 4);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(10);
          ELSE
            vPIXEL1 := vFONT(2);
          END IF;
          vPIXEL2   := vFONT(5 DOWNTO 4);
          vPIXEL4   := vFONTe(11 DOWNTO 8);
        END IF;

        S_DOTStep <= "110";
-------------------------------------------------------------------------------
      WHEN "110" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(14);
          ELSE
            vPIXEL1 := vFONT(6);
          END IF;
          vPIXEL2   := vFONT(13 DOWNTO 12);
          vPIXEL4   := vFONT(11 DOWNTO 8);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(9);
          ELSE
            vPIXEL1 := vFONT(1);
          END IF;
          vPIXEL2   := vFONT(3 DOWNTO 2);
          vPIXEL4   := vFONTe(7 DOWNTO 4);
        END IF;

        S_DOTStep <= "111";
-------------------------------------------------------------------------------
      WHEN "111" =>
        IF ( S_HFlip = '1' ) THEN
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(15);
          ELSE
            vPIXEL1 := vFONT(7);
          END IF;
          vPIXEL2   := vFONT(15 DOWNTO 14);
          vPIXEL4   := vFONT(15 DOWNTO 12);
        ELSE
          IF ( S_HByte = '1' ) THEN
            vPIXEL1 := vFONT(8);
          ELSE
            vPIXEL1 := vFONT(0);
          END IF;
          vPIXEL2   := vFONT(1 DOWNTO 0);
          vPIXEL4   := vFONTe(3 DOWNTO 0);
        END IF;

        S_DOTStep <= "000";
      END CASE;
-------------------------------------------------------------------------------
    END IF;
-------------------------------------------------------------------------------
    IF ( DOTBLANK = '0' OR S_DISABLE = '1' ) THEN
      tCOLOR := (OTHERS => '0');
    ELSE
      IF ( ( S_FONT_1bpp OR S_FONT_1bppE ) = '1' ) THEN
        IF ( vPIXEL1 = '1' ) THEN
          tCOLOR := eCOLOR(8 DOWNTO 4) & vCOLOR(3 DOWNTO 0);
        ELSE
          tCOLOR := eCOLOR(8 DOWNTO 4) & vCOLOR(7 DOWNTO 4);
        END IF;
      ELSIF ( S_FONT_2bpp = '1' ) THEN
        tCOLOR := eCOLOR & vPIXEL2;
      ELSE
        tCOLOR := eCOLOR(8 DOWNTO 4) & vPIXEL4;
      END IF;
    END IF;

  END IF;
-------------------------------------------------------------------------------
  S_COLOR <= tCOLOR;
-------------------------------------------------------------------------------
END PROCESS;

-------------------------------------------------------------------------------
-- OUT Background
-------------------------------------------------------------------------------
--PROCESS(CLK, B_DOTCLK, B_DOTStep, DOTBLANK,
--             B_FONT0, B_FONT1,
--             B_FONT_2bpp, B_FONT_1bpp)

--variable vCOLOR    : STD_LOGIC_VECTOR(7 DOWNTO 0);
--variable tCOLOR    : STD_LOGIC_VECTOR(8 DOWNTO 0);
--variable eCOLOR    : STD_LOGIC_VECTOR(8 DOWNTO 2);

--variable vFONT     : STD_LOGIC_VECTOR(15 DOWNTO 0);
--variable vFONTe    : STD_LOGIC_VECTOR(15 DOWNTO 0);

--variable vPIXEL1   : STD_LOGIC;
--variable vPIXEL2   : STD_LOGIC_VECTOR(1 DOWNTO 0);

--BEGIN
-------------------------------------------------------------------------------
--  IF (RISING_EDGE(CLK)) THEN
--    IF B_DOTCLK = '1' THEN

--      CASE B_DOTStep IS
--      WHEN "000" =>

--        vCOLOR := B_FONT0(15 DOWNTO 8);

--        eCOLOR := B_COLORv;

--        vFONT  := B_FONT1;

--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(8);
--          ELSE
--            vPIXEL1 := vFONT(0);
--          END IF;
--          vPIXEL2   := vFONT( 1 DOWNTO  0);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(15);
--          ELSE
--            vPIXEL1 := vFONT(7);
--          END IF;
--          vPIXEL2   := vFONT(15 DOWNTO 14);
--        END IF;

--        IF ( DOTBLANK = '0' ) THEN
--          B_DOTStep <= "000";
--        ELSE
--          B_DOTStep <= "001";
--        END IF;
-------------------------------------------------------------------------------
--      WHEN "001" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(9);
--          ELSE
--            vPIXEL1 := vFONT(1);
--          END IF;
--          vPIXEL2   := vFONT( 3 DOWNTO  2);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(14);
--          ELSE
--            vPIXEL1 := vFONT(6);
--          END IF;
--          vPIXEL2   := vFONT(13 DOWNTO 12);
--        END IF;

--        B_DOTStep <= "010";
-------------------------------------------------------------------------------
--      WHEN "010" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(10);
--          ELSE
--            vPIXEL1 := vFONT(2);
--          END IF;
--          vPIXEL2   := vFONT( 5 DOWNTO  4);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(13);
--          ELSE
--            vPIXEL1 := vFONT(5);
--          END IF;
--          vPIXEL2   := vFONT(11 DOWNTO 10);
--        END IF;
  
--        B_DOTStep <= "011";
-------------------------------------------------------------------------------
--      WHEN "011" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(11);
--          ELSE
--            vPIXEL1 := vFONT(3);
--          END IF;
--          vPIXEL2   := vFONT( 7 DOWNTO  6);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(12);
--          ELSE
--            vPIXEL1 := vFONT(4);
--          END IF;
--          vPIXEL2   := vFONT(9 DOWNTO 8);
--        END IF;
  
--        B_DOTStep <= "100";
-------------------------------------------------------------------------------
--      WHEN "100" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(12);
--          ELSE
--            vPIXEL1 := vFONT(4);
--          END IF;
--          vPIXEL2   := vFONT( 9 DOWNTO  8);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(11);
--          ELSE
--            vPIXEL1 := vFONT(3);
--          END IF;
--          vPIXEL2   := vFONT(7 DOWNTO 6);
--        END IF;
  
--        B_DOTStep <= "101";
-------------------------------------------------------------------------------
--      WHEN "101" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(13);
--          ELSE
--            vPIXEL1 := vFONT(5);
--          END IF;
--          vPIXEL2   := vFONT(11 DOWNTO 10);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(10);
--          ELSE
--            vPIXEL1 := vFONT(2);
--          END IF;
--          vPIXEL2   := vFONT(5 DOWNTO 4);
--        END IF;
  
--        B_DOTStep <= "110";
-------------------------------------------------------------------------------
--      WHEN "110" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(14);
--          ELSE
--            vPIXEL1 := vFONT(6);
--          END IF;
--          vPIXEL2   := vFONT(13 DOWNTO 12);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(9);
--          ELSE
--            vPIXEL1 := vFONT(1);
--          END IF;
--          vPIXEL2   := vFONT(3 DOWNTO 2);
--        END IF;
  
--        B_DOTStep <= "111";
-------------------------------------------------------------------------------
--      WHEN "111" =>
--        IF ( B_HFlip = '1' ) THEN
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(15);
--          ELSE
--            vPIXEL1 := vFONT(7);
--          END IF;
--          vPIXEL2   := vFONT(15 DOWNTO 14);
--        ELSE
--          IF ( B_HByte = '1' ) THEN
--            vPIXEL1 := vFONT(8);
--          ELSE
--            vPIXEL1 := vFONT(0);
--          END IF;
--          vPIXEL2   := vFONT(1 DOWNTO 0);
--        END IF;
  
--        B_DOTStep <= "000";
--      END CASE;
-------------------------------------------------------------------------------
--    END IF;
-------------------------------------------------------------------------------
--    IF ( DOTBLANK = '0' OR B_DISABLE = '1' ) THEN
--      tCOLOR := (OTHERS => '0');
--    ELSE
--      IF ( B_FONT_1bpp = '1' ) THEN
--        IF ( vPIXEL1 = '1' ) THEN
--          tCOLOR := eCOLOR(8 DOWNTO 4) & vCOLOR(3 DOWNTO 0);
--        ELSE
--          tCOLOR := eCOLOR(8 DOWNTO 4) & vCOLOR(7 DOWNTO 4);
--        END IF;
--      ELSE
--        tCOLOR := eCOLOR & vPIXEL2;
--      END IF;
--    END IF;

--  END IF;
-------------------------------------------------------------------------------
--  B_COLOR <= tCOLOR;
-------------------------------------------------------------------------------
--END PROCESS;

--S_COLOR <= (OTHERS => '0');
B_COLOR <= (OTHERS => '0');

-------------------------------------------------------------------------------
END;
