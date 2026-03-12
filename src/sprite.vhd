LIBRARY ieee;
USE ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;
use IEEE.STD_LOGIC_ARITH.ALL;

LIBRARY work;

ENTITY sprite IS 
	PORT
	(
		CLK     :  IN STD_LOGIC;
		RESET_n :  IN STD_LOGIC;

		H       :  IN STD_LOGIC_VECTOR(11 DOWNTO 0);
		V       :  IN STD_LOGIC_VECTOR(11 DOWNTO 0);

		HACTIVE :  IN STD_LOGIC;
		VACTIVE :  IN STD_LOGIC;

		SPRITE_EN: IN STD_LOGIC;

--------------- External SRAM
--		OAM_Dio  : INOUT STD_LOGIC_VECTOR(31 DOWNTO 0);
--------------- Internal BRAM
		OAM_Di   :  IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		OAM_Do   : OUT STD_LOGIC_VECTOR(63 DOWNTO 0);
		OAM_A    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		OAM_WE   : OUT STD_LOGIC;
--		OAM_OE   : OUT STD_LOGIC;
		OAM_BLE  : OUT STD_LOGIC;
		OAM_BHE  : OUT STD_LOGIC;

--------------- External SRAM
--		LB_0_Dio : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--------------- Internal BRAM
		LB_0_Di  :  IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		LB_0_Do  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		LB_0_A   : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
		LB_0_WE  : OUT STD_LOGIC;
		LB_0_OE  : OUT STD_LOGIC;
		LB_0_BLE : OUT STD_LOGIC;
		LB_0_BHE : OUT STD_LOGIC;

--------------- External SRAM
--		LB_1_Dio : INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
--------------- Internal BRAM
		LB_1_Di  :  IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		LB_1_Do  : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
		LB_1_A   : OUT STD_LOGIC_VECTOR(8 DOWNTO 0);
		LB_1_WE  : OUT STD_LOGIC;
		LB_1_OE  : OUT STD_LOGIC;
		LB_1_BLE : OUT STD_LOGIC;
		LB_1_BHE : OUT STD_LOGIC;
----------------

		COLOR    : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);

		MDi      :  IN STD_LOGIC_VECTOR(15 DOWNTO 0);
		MRDY     :  IN STD_LOGIC;
		MA       : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
		MREQ     : OUT STD_LOGIC
	);
END;

ARCHITECTURE bdf_type OF sprite IS 

TYPE load_state_type IS (LOAD_IDLE, LOAD_0, LOAD_1, LOAD_2, LOAD_3, LOAD_DONE);
TYPE spr_state_type IS  (IDLE, CHK_Y, ADDR_D, LOAD_D, REND, NXT,DONE);

SIGNAL SPRITE_ADDR	: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL RENDER_ADDR	: STD_LOGIC_VECTOR(14 DOWNTO 0);

SIGNAL SCANLINE		: STD_LOGIC_VECTOR(9 DOWNTO 0);

SIGNAL CURRENT_BUFFER	: STD_LOGIC; -- 0 or 1
SIGNAL RENDER_BUFFER	: STD_LOGIC; -- Buffer being rendered to
--SIGNAL BUFFER_SWAP        : STD_LOGIC;

SIGNAL LB_OE		: STD_LOGIC;
SIGNAL LB_DATA		: STD_LOGIC_VECTOR(15 DOWNTO 0);

SIGNAL LB_ADDR_O	: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL LB_WE_O		: STD_LOGIC;
SIGNAL LB_ADDR_P	: STD_LOGIC_VECTOR(9 DOWNTO 0);
SIGNAL LB_DATA_P	: STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL LB_WE_P		: STD_LOGIC;

SIGNAL LB_0_BE		: STD_LOGIC;
SIGNAL LB_0_WR		: STD_LOGIC;
SIGNAL LB_1_BE		: STD_LOGIC;
SIGNAL LB_1_WR		: STD_LOGIC;

SIGNAL OAM_REQ		: STD_LOGIC;
SIGNAL OAM_BE		: STD_LOGIC;
SIGNAL OAM_Ard		: STD_LOGIC_VECTOR(8 DOWNTO 0);
SIGNAL OAM_Awr		: STD_LOGIC_VECTOR(8 DOWNTO 0);
SIGNAL OAM_OE		: STD_LOGIC;

SIGNAL R_REQ		: STD_LOGIC;

BEGIN 

-- Current scanline
SCANLINE <= V(9 DOWNTO 0) + 1     WHEN VACTIVE = '1'        ELSE (others => '0');

MA       <= "110" & RENDER_ADDR   WHEN VACTIVE = '1'        ELSE "01100000" & SPRITE_ADDR;
MREQ     <= R_REQ                 WHEN VACTIVE = '1'        ELSE OAM_REQ;
-------------------------------------------------------------------------------
-- Line buffer access
-------------------------------------------------------------------------------
LB_0_A   <= LB_ADDR_P(9 DOWNTO 1) WHEN CURRENT_BUFFER = '0' ELSE LB_ADDR_O(9 DOWNTO 1);
LB_0_WE  <= LB_WE_P               WHEN CURRENT_BUFFER = '0' ELSE LB_WE_O;
LB_0_OE  <= '1'                   WHEN CURRENT_BUFFER = '0' ELSE LB_OE;
LB_0_BLE <= LB_ADDR_P(0)          WHEN CURRENT_BUFFER = '0' ELSE '0';
LB_0_BHE <= NOT(LB_ADDR_P(0))     WHEN CURRENT_BUFFER = '0' ELSE '0';
--LB_0_Dio <= LB_DATA_P & LB_DATA_P WHEN CURRENT_BUFFER = '0' ELSE (others => '0') WHEN LB_OE = '1' ELSE (others => 'Z');
LB_0_Do  <= LB_DATA_P & LB_DATA_P WHEN CURRENT_BUFFER = '0' ELSE (others => '0');

LB_1_A   <= LB_ADDR_O(9 DOWNTO 1) WHEN CURRENT_BUFFER = '0' ELSE LB_ADDR_P(9 DOWNTO 1);
LB_1_WE  <= LB_WE_O               WHEN CURRENT_BUFFER = '0' ELSE LB_WE_P;
LB_1_OE  <= LB_OE                 WHEN CURRENT_BUFFER = '0' ELSE '1';
LB_1_BLE <= '0'                   WHEN CURRENT_BUFFER = '0' ELSE LB_ADDR_P(0);
LB_1_BHE <= '0'                   WHEN CURRENT_BUFFER = '0' ELSE NOT(LB_ADDR_P(0));
--LB_1_Dio <= LB_DATA_P & LB_DATA_P WHEN CURRENT_BUFFER = '1' ELSE (others => '0') WHEN LB_OE = '1' ELSE (others => 'Z');
LB_1_Do  <= (others => '0')       WHEN CURRENT_BUFFER = '0' ELSE LB_DATA_P & LB_DATA_P;

--LB_DATA  <= LB_1_Dio              WHEN CURRENT_BUFFER = '0' ELSE LB_0_Dio;
LB_DATA  <= LB_1_Di               WHEN CURRENT_BUFFER = '0' ELSE LB_0_Di;
-------------------------------------------------------------------------------
-- OAM
-------------------------------------------------------------------------------
--OAM_Dio <= OAM_Do  WHEN OAM_WE = '0' ELSE (others => 'z');
OAM_A    <= OAM_Awr(8 DOWNTO 1)   WHEN OAM_OE = '1'         ELSE OAM_Ard(8 DOWNTO 1);
OAM_BE   <= OAM_Awr(0)            WHEN OAM_OE = '1'         ELSE OAM_Ard(0);
OAM_BLE  <= OAM_BE                WHEN OAM_OE = '1'         ELSE '0';
OAM_BHE  <= NOT(OAM_BE)           WHEN OAM_OE = '1'         ELSE '0';
--OAM_Di  <= OAM_Dio;
-------------------------------------------------------------------------------
-- SPRITE EVALUATION PROCESS (Read sprite attributes during blanking)
-------------------------------------------------------------------------------
--
-- +00 - |7|6|5|4|3|2|1|0| SPRITE Y lo 8 bits
-- +01 - | | | | | | |1|0| SPRITE Y hi 2 bits
-- +01 - | | | | |3|2| | | SPRITE SCALE 2 bits
-- +01 - | | |5|4| | | | | SPRITE BITS 2 bits ( 00 - 1 bpp,   01 - 2bpp,      10 - 4bpp,        11 - 1 bit )
-- +01 - |7|6| | | | | | | SPRITE SIZE 2 bits ( 00 - Disable, 01 - 8x8 pixel, 10 - 16x16 pixel, 11 - 32x32 pixel)
--
-- +02 - |7|6|5|4|3|2|1|0| SPRITE CHAR lo 8 bits
-- +03 - | | | | | | |1|0| SPRITE CHAR hi 4 bits
-- +03 - | | | | |3|2| | | SPRITE ANIMATION 1 bits
-- +03 - | | |5|4| | | | | SPRITE PRIO 2 bits
-- +03 - | |6| | | | | | | SPRITE H FLIP 1 bit
-- +03 - |7| | | | | | | | SPRITE V FLIP 1 bit
--
-- +04 - |7|6|5|4|3|2|1|0| SPRITE X lo 8 bits
-- +05 - | | | | | |2|1|0| SPRITE X hi 3 bits
-- +05 - | | | | |?| | | | SPRITE ??? 1 bits
-- +05 - |7|6|5|4| | | | | SPRITE PALETTE 4 bits
--
-- +06 - | | | | |3|2|1|0| SPRITE COLOR0 4 bits 
-- +06 - |7|6|5|4| | | | | SPRITE COLOR1 4 bits
-- +07 - | | | | |3|2|1|0| SPRITE COLOR2 4 bits
-- +07 - |7|6|5|4| | | | | SPRITE COLOR3 4 bits
--
-------------------------------------------------------------------------------
-- sprite table - 256x8 bytes (256x4 words)
-- base addr "1100 00ss ssss ss00"

-- 32x32 -  64 sprites 4bpp  -  128 2bpp -  256 1bpp
-- base addr "10xx xxxx yyyy yccc"
-- 1 sprite - 512 bytes (256 words) - 16b (8w)

-- 16x16 - 256 sprites 4bpp  -  512 2bpp - 1024 1bpp
-- base addr "01xx xxxx xxyy yycc"
-- 1 sprite - 128 bytes (64 words)  - 8b (4w)

-- 08x08 - 1024 sprites 4bpp - 2048 2bpp - 4096 1bpp
-- base addr "00xx xxxx xxxx yyyc"
-- 1 sprite -  32 bytes (16 words)  - 4b (2w)
-------------------------------------------------------------------------------
-- Load SPRITE_INFO from VRAM to OAM when VACTIVE = 0
-- 256 sprites, 8 bytes / sprite
--
PROCESS(CLK, RESET_n)

variable vSTATE    : load_state_type;
variable vOAM_IDX    : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vADDR     : STD_LOGIC_VECTOR(1 DOWNTO 0);

variable vSPR_0 : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vSPR_1 : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vSPR_2 : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vSPR_3 : STD_LOGIC_VECTOR(15 DOWNTO 0);

BEGIN
  IF RESET_n = '0' THEN
    vSTATE   := LOAD_IDLE;
    vOAM_IDX := (others => '0');
    vADDR    := "00";
    OAM_OE   <= '1';

  ELSIF (RISING_EDGE(CLK)) THEN

    OAM_WE <= '1';

    CASE vSTATE IS
    WHEN LOAD_IDLE =>
      IF ( VACTIVE = '0' AND SPRITE_EN = '1' ) THEN
        vSTATE := LOAD_0;
        OAM_OE <= '1';
        OAM_REQ <= '1';
      END IF;

    WHEN LOAD_0 =>
      vSPR_0	:= MDi;

      vADDR	:= "01";
      vSTATE	:= LOAD_1;

    WHEN LOAD_1 =>
      vSPR_1	:= MDi;

--      vSTATE	:= WRITE_0;
--      OAM_Do  <= vSPR_0 & vSPR_1;
--      OAM_WE  <= '0';
--
--    WHEN WRITE_0 =>
--      OAM_WE  <= '0';
--
      vADDR	:= "10";
      vSTATE	:= LOAD_2;

    WHEN LOAD_2 =>
      vSPR_2	:= MDi;

      vADDR	:= "11";
      vSTATE	:= LOAD_3;
        
    WHEN LOAD_3 =>
      vSPR_3	:= MDi;
            
      -- Store sprite attributes in dedicated RAM
      OAM_Do  <= vSPR_3 & vSPR_2 & vSPR_1 & vSPR_0;
--      OAM_WE  <= '0';

      vADDR  := "00";
      vOAM_IDX := vOAM_IDX + 1;
      IF (vOAM_IDX = "00000000") THEN
        vSTATE := LOAD_DONE;
      ELSE
        vSTATE := LOAD_0;
      END IF;

    WHEN LOAD_DONE =>
      OAM_OE <= '0';
      OAM_REQ <= '0';
      IF ( VACTIVE = '1' ) THEN
        vSTATE := LOAD_IDLE;
      END IF;
    END CASE;

  END IF;

  OAM_Awr      <= vOAM_IDX & vADDR(1);
  SPRITE_ADDR  <= vOAM_IDX & vADDR;
END PROCESS;

-------------------------------------------------------------------------------
-- SPRITE: Find and load sprites from OAM
-------------------------------------------------------------------------------
PROCESS(CLK, RESET_n)
variable vSTATE : spr_state_type;
variable vSPR_IDX : STD_LOGIC_VECTOR(7 DOWNTO 0);

variable vSPR_Y     : STD_LOGIC_VECTOR(9 DOWNTO 0);
variable vTemp_Y    : STD_LOGIC_VECTOR(9 DOWNTO 0);
variable vSPR_SCALE : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vSPR_SIZE  : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vSPR_BITS  : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vSPR_CHAR  : STD_LOGIC_VECTOR(9 DOWNTO 0);
variable vSPR_VFLIP : STD_LOGIC;
variable vSPR_HFLIP : STD_LOGIC;

variable vSPR_X     : STD_LOGIC_VECTOR(10 DOWNTO 0);
variable vTemp_X    : STD_LOGIC_VECTOR(10 DOWNTO 0);
variable vSPR_COLOR0 : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vSPR_COLOR1 : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vSPR_COLOR2 : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vSPR_COLOR3 : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vSPR_PAL    : STD_LOGIC_VECTOR(3 DOWNTO 0);

variable vSPR_MASK  : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vSPR_WORDS : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vSPR_PIXELS : STD_LOGIC_VECTOR(2 DOWNTO 0);

variable vW : STD_LOGIC;

variable vSPR_DIS   : STD_LOGIC;
variable vSPR_x1    : STD_LOGIC;
variable vSPR_x2    : STD_LOGIC;
variable vSPR_x4    : STD_LOGIC;
variable vSPR_04    : STD_LOGIC;
variable vSPR_08    : STD_LOGIC;
variable vSPR_16    : STD_LOGIC;
variable vSPR_32    : STD_LOGIC;
variable vSPR_1bpp  : STD_LOGIC;
variable vSPR_2bpp  : STD_LOGIC;
variable vSPR_4bpp  : STD_LOGIC;
variable vSPR_1bppE : STD_LOGIC;

variable vADDR   : STD_LOGIC_VECTOR(14 DOWNTO 0);
variable vIDX_W  : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vTemp_W : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vIDX_P  : STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vTemp_P : STD_LOGIC_VECTOR(3 DOWNTO 0);
variable vX      : STD_LOGIC_VECTOR(10 DOWNTO 0);
variable vADD_X  : STD_LOGIC_VECTOR(4 DOWNTO 0);
variable vIDX_S  : STD_LOGIC_VECTOR(2 DOWNTO 0);
variable vSCALE  : STD_LOGIC_VECTOR(2 DOWNTO 0);

variable vDATA   : STD_LOGIC_VECTOR(15 DOWNTO 0);
variable vPixel1 : STD_LOGIC;
variable vPixel2 : STD_LOGIC_VECTOR(1 DOWNTO 0);
variable vPixel  : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN
  IF RESET_n = '0' THEN
    vSTATE := IDLE;
    vSPR_IDX := (others => '0');
    vIDX_W   := (others => '0');
    vIDX_P   := (others => '0');

    vSPR_X   := (others => '0');
  ELSIF (RISING_EDGE(CLK)) THEN

    LB_WE_P   <= '1';

    CASE vSTATE IS
-------------------------------------------------------------------------------
    WHEN IDLE =>
      IF ( HACTIVE = '1' AND VACTIVE = '1' AND SPRITE_EN = '1') THEN
        vSTATE := CHK_Y;
      END IF;
      vSPR_IDX := (others => '0');
--      vW := '0';
-------------------------------------------------------------------------------
    WHEN CHK_Y =>
      vSPR_Y      := OAM_Di( 9 DOWNTO  0);
      vSPR_SCALE  := OAM_Di(11 DOWNTO 10);
      vSPR_BITS   := OAM_Di(13 DOWNTO 12);
      vSPR_SIZE   := OAM_Di(15 DOWNTO 14);

      vSPR_CHAR   := OAM_Di(25 DOWNTO 16);
--      SPRITE_ANIM   <= OAM_Di(26);
--      SPRITE_ANIM   <= OAM_Di(27);
--      SPRITE_ANIM   <= OAM_Di(28);
--      SPRITE_PRIO(0)<= OAM_Di(29);
      vSPR_HFLIP  := OAM_Di(30);
      vSPR_VFLIP  := OAM_Di(31);

      vSPR_X      := OAM_Di(42 DOWNTO 32);
      vSPR_PAL    := OAM_Di(47 DOWNTO 44);

      vSPR_COLOR0 := OAM_Di(51 DOWNTO 48);
      vSPR_COLOR1 := OAM_Di(55 DOWNTO 52);
      vSPR_COLOR2 := OAM_Di(59 DOWNTO 56);
      vSPR_COLOR3 := OAM_Di(63 DOWNTO 60);

      vSPR_DIS    :=  NOT(vSPR_SCALE(1)) AND NOT(vSPR_SCALE(0));
      vSPR_x1     :=  NOT(vSPR_SCALE(1)) AND     vSPR_SCALE(0);
      vSPR_x2     :=      vSPR_SCALE(1)  AND NOT(vSPR_SCALE(0));
      vSPR_x4     :=      vSPR_SCALE(1)  AND     vSPR_SCALE(0);

      vSPR_04     :=  NOT(vSPR_SIZE(1))  AND NOT(vSPR_SIZE(0));
      vSPR_08     :=  NOT(vSPR_SIZE(1))  AND     vSPR_SIZE(0);
      vSPR_16     :=      vSPR_SIZE(1)   AND NOT(vSPR_SIZE(0));
      vSPR_32     :=      vSPR_SIZE(1)   AND     vSPR_SIZE(0);

      vSPR_1bpp   := (NOT(vSPR_BITS(1))  AND NOT(vSPR_BITS(0))) OR (vSPR_BITS(1) AND vSPR_BITS(0));
      vSPR_2bpp   :=  NOT(vSPR_BITS(1))  AND     vSPR_BITS(0);
      vSPR_4bpp   :=      vSPR_BITS(1)   AND NOT(vSPR_BITS(0));
--      vSPR_1bppE  :=      vSPR_BITS(1)  AND     vSPR_BITS(0);

      vSPR_MASK(1)    := NOT(vSPR_08) AND NOT(vSPR_04);	-- "0X111"
      vSPR_MASK(0)    := NOT(vSPR_04);			-- "00X11"

      vSPR_PIXELS(2)  := vSPR_1bpp AND NOT(vSPR_08 OR vSPR_04);	-- "X0000"
      vSPR_PIXELS(1)  := (vSPR_1bpp AND vSPR_08) OR		-- "0X000"
                         (vSPR_2bpp AND NOT(vSPR_04));
      vSPR_PIXELS(0)  := vSPR_4bpp OR vSPR_04;			-- "00X00"

--      vSCALE          := vSPR_x4 & vSPR_x2 & vSPR_x1;

      vSPR_WORDS      := "0000";
      IF vSPR_04 = '1' THEN
        vSPR_WORDS(0) := vSPR_1bpp OR
                         vSPR_2bpp OR
                         vSPR_4bpp;		-- 1 words
      END IF;
      IF vSPR_08 = '1' THEN
        vSPR_WORDS(1) := vSPR_4bpp;		-- 2 words
        vSPR_WORDS(0) := vSPR_1bpp OR
                         vSPR_2bpp;		-- 1 words
      END IF;
      IF vSPR_16 = '1' THEN
        vSPR_WORDS(2) := vSPR_4bpp;		-- 4 words
        vSPR_WORDS(1) := vSPR_2bpp;		-- 2 words
        vSPR_WORDS(0) := vSPR_1bpp;		-- 1 words
      END IF;
      IF vSPR_32 = '1' THEN
        vSPR_WORDS(3) := vSPR_4bpp;		-- 8 words
        vSPR_WORDS(2) := vSPR_2bpp;		-- 4 words
        vSPR_WORDS(1) := vSPR_1bpp;		-- 2 words
      END IF;

      vSTATE := DONE;
      IF vSPR_DIS = '0' THEN
        IF (SCANLINE >= vSPR_Y AND SCANLINE < (vSPR_Y + ('0' & vSPR_32 & vSPR_16 & vSPR_08 & vSPR_04 & "00"))) THEN
          vTemp_Y := SCANLINE - vSPR_Y;
          IF ( vSPR_VFLIP = '1' ) THEN
            vTemp_Y := NOT(vTemp_Y);
          END IF;
        
--          vW := '1';
          vIDX_W := (others => '0');

          vSTATE := ADDR_D;
--        ELSE
--          vSTATE := "111";
        END IF;
--      ELSE
--        vSTATE := "111";
      END IF;

-------------------------------------------------------------------------------
    WHEN ADDR_D =>
      vTemp_W := vIDX_W;
      IF vSPR_HFLIP = '1' THEN
        vTemp_W := NOT(vTemp_W);
      END IF;

      IF vSPR_04 = '1' THEN
        vADDR(14 DOWNTO 0) := "111" & vSPR_CHAR(9 DOWNTO 0) & vTemp_Y(1 DOWNTO 0);
      END IF;
      IF vSPR_08 = '1' THEN
        vADDR(14 DOWNTO 1) := "00" & vSPR_CHAR(9 DOWNTO 1) & vTemp_Y(2 DOWNTO 0);
        vADDR(0) := (vTemp_W(0) AND vSPR_4bpp)      OR (vSPR_CHAR(0) AND NOT(vSPR_4bpp));
      END IF;
      IF vSPR_16 = '1' THEN
        vADDR(14 DOWNTO 2) := "01" & vSPR_CHAR(8 DOWNTO 2) & vTemp_Y(3 DOWNTO 0);
        vADDR(1) := (vTemp_W(1) AND vSPR_4bpp)      OR (vSPR_CHAR(1) AND NOT(vSPR_4bpp));
        vADDR(0) := (vTemp_W(0) AND NOT(vSPR_1bpp)) OR (vSPR_CHAR(0) AND vSPR_1bpp);
      END IF;
      IF vSPR_32 = '1' THEN
        vADDR(14 DOWNTO 3) := "1"  & vSPR_CHAR(7 DOWNTO 2) & vTemp_Y(4 DOWNTO 0);
        vADDR(2) := (vTemp_W(2) AND vSPR_4bpp)      OR (vSPR_CHAR(1) AND NOT(vSPR_4bpp));
        vADDR(1) := (vTemp_W(1) AND NOT(vSPR_1bpp)) OR (vSPR_CHAR(0) AND vSPR_1bpp);
        vADDR(0) := vTemp_W(0);
      END IF;

      vIDX_P := (others => '0');
--      vIDX_S := (others => '0');

--      R_REQ  <= '1';

      vSTATE := LOAD_D;
-------------------------------------------------------------------------------
    WHEN LOAD_D =>
      vDATA := MDi;

--      IF MRDY = '1' THEN
        vSTATE := REND;
--      END IF;
-------------------------------------------------------------------------------
    WHEN REND =>
--      R_REQ  <= '0';
--      IF vWORK = '0' AND WORK = '1' THEN
--        vIDX_P := (others => '0');
--        vWORK  := '1';
--        vDATA  := MDi;
--      END IF;
--      IF vWORK = '1' THEN

      vTemp_P := vIDX_P(3 DOWNTO 0);
      IF vSPR_HFLIP = '0' THEN
        vTemp_P := NOT(vTemp_P);
      END IF;
      vTemp_P(3) := vTemp_P(3) AND vSPR_MASK(1);
      vTemp_P(2) := vTemp_P(2) AND vSPR_MASK(0);

      vPixel := "0000";
      IF vSPR_1bpp = '1' THEN
        CASE vTemp_P(3 DOWNTO 0) IS
        WHEN "0000" => 
            vPixel1 := vDATA(0);
        WHEN "0001" =>
            vPixel1 := vDATA(1);
        WHEN "0010" =>
            vPixel1 := vDATA(2);
        WHEN "0011" =>
            vPixel1 := vDATA(3);
        WHEN "0100" =>
            vPixel1 := vDATA(4);
        WHEN "0101" =>
            vPixel1 := vDATA(5);
        WHEN "0110" =>
            vPixel1 := vDATA(6);
        WHEN "0111" =>
            vPixel1 := vDATA(7);
        WHEN "1000" =>
            vPixel1 := vDATA(8);
        WHEN "1001" =>
            vPixel1 := vDATA(9);
        WHEN "1010" =>
            vPixel1 := vDATA(10);
        WHEN "1011" =>
            vPixel1 := vDATA(11);
        WHEN "1100" =>
            vPixel1 := vDATA(12);
        WHEN "1101" =>
            vPixel1 := vDATA(13);
        WHEN "1110" =>
            vPixel1 := vDATA(14);
        WHEN OTHERS =>
            vPixel1 := vDATA(15);
        END CASE;

        IF vPixel1 = '1' THEN
            vPixel := vSPR_COLOR0;
        ELSE
            vPixel := vSPR_COLOR1;
        END IF;
      END IF;
      IF vSPR_2bpp = '1' THEN
        CASE vTemp_P(2 DOWNTO 0) IS
        WHEN "000" =>
            vPixel2 := vDATA(1 DOWNTO 0);
        WHEN "001" =>
            vPixel2 := vDATA(3 DOWNTO 2);
        WHEN "010" =>
            vPixel2 := vDATA(5 DOWNTO 4);
        WHEN "011" =>
            vPixel2 := vDATA(7 DOWNTO 6);
        WHEN "100" =>
            vPixel2 := vDATA(9 DOWNTO 8);
        WHEN "101" =>
            vPixel2 := vDATA(11 DOWNTO 10);
        WHEN "110" =>
            vPixel2 := vDATA(13 DOWNTO 12);
        WHEN OTHERS =>
            vPixel2 := vDATA(15 DOWNTO 14);
        END CASE;

        CASE vPixel2 IS
        WHEN "00" =>
            vPixel := vSPR_COLOR0;
        WHEN "01" =>
            vPixel := vSPR_COLOR1;
        WHEN "10" =>
            vPixel := vSPR_COLOR2;
        WHEN OTHERS =>
            vPixel := vSPR_COLOR3;
        END CASE;
      END IF;
      IF vSPR_4bpp = '1' THEN
        CASE vTemp_P(1 DOWNTO 0) IS
        WHEN "00" =>
            vPixel := vDATA( 3 DOWNTO  0);
        WHEN "01" =>
            vPixel := vDATA( 7 DOWNTO  4);
        WHEN "10" =>
            vPixel := vDATA(11 DOWNTO  8);
        WHEN OTHERS =>
            vPixel := vDATA(15 DOWNTO 12);
        END CASE;
      END IF;
      
      IF (vPixel /= "0000" AND vSPR_X(10) = '0') THEN
        LB_ADDR_P <= vSPR_X(9 DOWNTO 0);
        LB_DATA_P <= vSPR_PAL & vPixel;

        LB_WE_P <= '0';
      END IF;

      vSPR_X := vSPR_X + 1;

      vIDX_P := vIDX_P + 1;
      IF ( vIDX_P = vSPR_PIXELS & "00" ) THEN
        vIDX_W := vIDX_W + 1;
        IF vIDX_W = vSPR_WORDS THEN
          vSTATE := DONE;
        ELSE
          vSTATE := ADDR_D;
        END IF;
      ELSE
        vSTATE := REND;
      END IF;

--      vIDX_P := vIDX_P + 1;
--      IF ( vIDX_P = vSPR_PIXELS & "00" ) THEN
--        vWORK := '0';
--      END IF;
-------------------------------------------------------------------------------
    WHEN DONE =>
--        vW := '0';

      IF HACTIVE = '1' THEN
        vSPR_IDX := vSPR_IDX + 1;
        IF vSPR_IDX = "00000000" THEN
          vSTATE := IDLE;
        ELSE
          vSTATE := CHK_Y;
        END IF;
      ELSE
        vSTATE := IDLE;
      END IF;
    WHEN OTHERS => NULL;
    END CASE;
  END IF;

  OAM_Ard <= vSPR_IDX & '0'; -- vW;

  RENDER_ADDR  <= vADDR;
END PROCESS;

-------------------------------------------------------------------------------
-- BUFFER SWAP PROCESS (Synchronous)
-------------------------------------------------------------------------------
PROCESS(CLK, RESET_n)
BEGIN
  IF RESET_n = '0' THEN
    CURRENT_BUFFER <= '0';
    RENDER_BUFFER  <= '1';
--    BUFFER_SWAP    <= '0';
  ELSIF (RISING_EDGE(CLK)) THEN
    -- Swap buffers at the start of active display (after rendering completed)
    IF ( H = 0 AND VACTIVE = '1' ) THEN
      CURRENT_BUFFER <= RENDER_BUFFER;
      RENDER_BUFFER  <= NOT RENDER_BUFFER;
--      BUFFER_SWAP    <= '1';
--    ELSE
--      BUFFER_SWAP    <= '0';
    END IF;
  END IF;
END PROCESS;

-------------------------------------------------------------------------------
-- OUT SPRITE
-------------------------------------------------------------------------------
PROCESS(CLK, RESET_n)
variable vPIX_IDX : STD_LOGIC_VECTOR(8 DOWNTO 0);
variable vDATA  : STD_LOGIC_VECTOR(7 DOWNTO 0);
variable vB     : STD_LOGIC;

BEGIN
  IF RESET_n = '0' THEN
    vPIX_IDX := (others => '0');
    vB     := '0';
  ELSIF (RISING_EDGE(CLK)) THEN
    IF ( HACTIVE = '1' AND VACTIVE = '1' AND SPRITE_EN = '1' ) THEN
      IF vB = '0' THEN
        vDATA    := LB_DATA(15 DOWNTO 8);
        COLOR    <= LB_DATA(7 DOWNTO 0);

        vB       := '1';
      ELSE
        COLOR    <= vDATA;

        vPIX_IDX := vPIX_IDX + 1;
        vB       := '0';
      END IF;
    ELSE
      vPIX_IDX   := (others => '0');
      vB         := '0';
    END IF;
  END IF;

  LB_ADDR_O <= vPIX_IDX & '0';
  LB_WE_O   <= NOT(vB);
  LB_OE     <= vB;
END PROCESS;

END;