#include "config.inc"

	.ORG	0E000H

;---------------------------------------------------------------
; BDOS to BIOS
;
;---------------------------------------------------------------
BOOT:   JP	CSTART
WBOOT:  JP	WSTART
CONST:  JP	_CHKIN_TTY_CHR
CONIN:  JP	_GET_TTY_CHR
CONOUT: JP	_PUT_TTY_CHR
LIST:   JP	_PUT_TTY_CHR
PUNCH:  JP	_PUT_TTY_CHR
READER: JP	_GET_TTY_CHR

HOME:   JP	_HOME
SELDSK: JP	_SELDSK
SETTRK: JP	_SETTRK
SETSEC: JP	_SETSEC
SETDMA: JP	_SETDMA
READ:   JP	_READ
WRITE:  JP	_WRITE

LISTST: JP	_LISTST
SECTRN: JP	_SECTRN

;---------------------------------------------------------------
;  list status
;
_LISTST:
	LD	A, $FF	   	;Return list status of 0xFF (ready).
_HOME:
_SELDSK:
_SETTRK:
_SETSEC:
_SETDMA:
_READ:
_WRITE:
_SECTRN:
	RET
;
; START BIOS
;
CSTART:
	DI

;	LD	A, 00000000B
;	OUT	(SLOT0), A
;	LD	A, 11111111B
;	OUT	(SLOT0), A
;	LD	A, 55h
;	LD	(0000h), A
;	LD	A, (0000h)
;	CP	0C3h
;	JR	NZ, EXT_MAPPER

; ----- $0000-$1FFF
;	LD	A, 00000000B
;	OUT	(SLOT0), A
; ----- $2000-$3FFF
;	LD	A, 00000001B
;	OUT	(SLOT1), A
; ----- $4000-$5FFF
;	LD	A, 00000010B
;	OUT	(SLOT2), A
; ----- $6000-$7FFF
;	LD	A, 00000011B
;	OUT	(SLOT3), A
; ----- $8000-$9FFF
;	LD	A, 00000100B
;	OUT	(SLOT4), A
; ----- $A000-$BFFF
;	LD	A, 11111110B
;	OUT	(SLOT5), A

;-------------------------------
; 8K VIDEO RAM
; ----- $C000-$DFFF
;	LD	A, 11000000B
;	OUT	(SLOT6), A
;	JR	MAP_E

EXT_MAPPER:
	LD	HL, ZEROPAGE + 40h
	LD	BC, 0EF7h
EM_:
	INC	C
	OUTI
	OUTI
	JR	NZ, EM_
MAP_E:
	LD	A, 0
	OUT	($F5), A	 ; Video hscroll reg
	OUT	($F6), A	 ; Video vscroll reg
	OUT	($F7), A	 ; Video ctrl reg - set scale x1

;---------------------------------------------------------------
; CHECK WRITE/READ CYCLE FIRS 8k of ADDRESS SPACE
;
	LD	HL,0000H
RAMLoop0:
	LD	A, 55H
	LD	(HL), A
	CP	(HL)
	JR	NZ, NoRAM
	INC	HL
	LD	A, H
	CP	020H
	JR	NZ, RAMLoop0

	LD	HL,0000H
RAMLoop1:
	LD	A, 0AAH
	LD	(HL), A
	CP	(HL)
	JR	NZ, NoRAM
	INC	HL
	LD	A, H
	CP	20H
	JR	NZ, RAMLoop1

	LD	HL,0000H
RAMLoop2:
	XOR	A
	LD	(HL), A
	CP	(HL)
	JR	NZ, NoRAM
	INC	HL
	LD	A, H
	CP	020H
	JR	NZ, RAMLoop2
	JR	WSTART
;---------------------------------------------------------------
;
;
NoRAM:
	LD	HL, 0C000H

NR0:	LD	A, 11011001B
	LD	(HL), A
	INC	HL

	LD	A, 10000111B
	LD	(HL), A
	INC	HL

	LD	A, H
	CP	0E0H
	JR	NZ, NR0

	JP	CSTART
;---------------------------------------------------------------
;
;
WSTART:
	LD	SP, SYSTEM_STACK

	LD	HL, SYSTEM_AREA
	XOR	A
	LD	B, A
SRAM_:
	LD	(HL), A
	INC	HL
	DJNZ	SRAM_

	LD	HL, ZEROPAGE
	LD	DE, 0000h
	LD	BC, 50H
	LDIR

	LD	HL, SYSAREA
	LD	DE, SYSTEM_AREA
	LD	BC, 0100H
	LDIR

;	CALL	CLEAR_SCR

	LD	DE, String0
	CALL	PRINT_STR_TTY
	LD	DE, String0
	CALL	PRINT_STR_SCR

	CALL	MEMMAP
	CALL	MAPPER

;---------------------------------------------------------------
;
;
;	IM	1
;	EI
	JP	MONIT


String0:
	.DB	FF, "Start BIOS",CR,LF,"Mapper enable",CR,LF,"First 8K RAM checked !!!",CR,LF,0

;--------------------------------------------------------------------------
; 0000-004F data block
;--------------------------------------------------------------------------
ZEROPAGE:
; 0000h
	JP	WBOOT
; 0003h
	.DB	0		; BDOS
; 0004h
	.DB	0		; BDOS
; 0005h
	JP	BDOS_HANDLE	; BDOS
; 0008h
	JP	_PUT_TTY_CHR	; in - A
	.DB	04Fh	 	; SCR_ATTR
	.DB	0		; SCR_POS, SCR_POSX
	.DB	0		;          SCR_POSY
	.DB	0		; SCR_HSCROLL
	.DB	0		; SCR_VSCROLL
; 0010h
	JP	_GET_TTY_CHR	; out - A
; 0013h
	.DB	004h		; SCR_SB
; 0014h
	JP	CHANGE_OUT
; 0017h
	.DB	0		; $00 - TTY, $FF - SCR
; 0018h
	JP	_CHKIN_TTY_CHR
; 001Bh
	.DB	0		;
; 001Ch
	JP	CHANGE_IN
; 001Fh
	.DB	0		; $00 - TTY, $FF - SCR
; 0020h
	JP	RST20_HANDLE
	NOP
	NOP
	NOP
	NOP
; 0027h
	RET
; 0028h
	JP	SLOT_CALL	; Inter slot call
; 002Bh
	.DB	0		;
; 002Ch
	JP	SLOT_CHANGE     ;
; 002Fh
	.DB	0		;
; 0030h
	JP	0000h		; DBG 
; 0033h
	.DW	0		;
; 0035h
	JP	0000h		; Inter slot call
; 00038h
	DI
	JP	Int_Handler     ; 00039h
; 003Ch
	.DW	0		; SP saved
; 003Eh
	.DW	RAM_TOP		; MEMORY_TOP
; 00040h
	.DW	0F800h
	.DW	0F801h
	.DW	0F802h
	.DW	0F803h
	.DW	0F804h
	.DW	0F805h		; RAM - 48k 
	.DW	0FC00h		; VIDEO - 8K (256 chars * 2 bytes * 16 lines)
	.DW	0FFFFh		; ROM - 8K, BIOS & Monitor
				; ROM - 8k, BASIC, CP/M

;	.ORG	0E1E0h
SYSAREA:
; 9EE0h CCP_VAR
#include "ccp.inc"
	.DW	INBUFF+2	; INPOINT
	.DW	0		; NAMEPNT

	.DB	0		; RTNCODE
	.DB	0		; CDRIVE
	.DB	0		; CHGDRV
	.DW	0		; NBYTES

	.DB	0		; BATCH
	.DB	0,"$$$     SUB" ; BATCHFCB
	.DB	0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0,0,0,0
	.DB	0,0,0,0,0

	.DB	0,"           "	; FCB
	.DB	0,0,0,0
	.DB	0,"           "
	.DB	0,0,0,0
	.DB	0

	.FILL	04h, 0
; 9F30h BDOS_VAR
;#include "bdos.inc"
	.DB	0E5h		; EMPTYFCB
	.DW	0		; WRTPRT
	.DW	0		; LOGIN
	.DW	80h		; USERDMA

	.DW	0		; SCRATCH1
	.DW	0		; SCRATCH2
	.DW	0		; SCRATCH3

	.DW	0		; DIRBUF
	.DW	0		; DISKPB
	.DW	0		; CHKVECT
	.DW	0		; ALOCVECT

	.DW	0		; SECTORS
	.DB	0		; BLKSHFT
	.DB	0		; BLKMASK
	.DB	0		; EXTMASK
	.DW	0		; DSKSIZE
	.DW	0		; DIRSIZE
	.DW	0		; ALLOC0
	.DW	0		; ALLOC1
	.DW	0		; OFFSET
	.DW	0		; XLATE

	.DB	0		; CLOSEFLG
	.DB	0		; RDWRTFLG
	.DB	0		; FNDSTAT
	.DB	0		; MODE
	.DB	0		; EPARAM
	.DB	0		; RELBLOCK
	.DB	0		; COUNTER
	.DW	0,0		; SAVEFCB
	.DB	0		; BIGDISK
	.DB	0		; AUTO
	.DB	0		; OLDDRV
	.DB	0		; AUTOFLAG
	.DB	0		; SAVNXT
	.DB	0		; SAVEXT
	.DW	0		; SAVNREC
	.DW	0		; BLKNMBR
	.DW	0		; LOGSECT
	.DB	0		; FCBPOS
	.DW	0		; FILEPOS

	.DB	0		; OUTFLAG
	.DB	2		; STARTING
	.DB	0		; CURPOS
	.DB	0		; PRTFLAG
	.DB	0		; CHARBUF
;
	.DB	0		; USERNO
	.DB	0		; ACTIVE
	.DW	0		; PARAMS
	.DW	0		; STATUS

	.DB	0,0,0,0,0,0,0,0	; CKSUMTBL
	.DB	0,0,0,0,0,0,0,0

	.DW	0		; USRSTACK

	.DB	0,0,0

; 9FB0h BIOS_VAR
#include "bios.inc"
	.DB	-1		; MNT
	.DB	-1
	.DB	-1
	
	.DB	-1		; CURVOL
	.DW	0		; CURTRK
	.DB	0		; CURHSEC
	.DW	0		; SECTOR

	.DB	-1		; REQVOL
	.DW	0		; REQTRK
	.DB	0		; REQHSEC

	.DB	0		; XFERCNT
	.DW	0		; XFERADDR
	.DW	0		; DMAADDR

	.DB	0		; DIRTY

	.DB	0, 0		; LBA
	.DB	0, 0		; LBA

	.DB	0
; 9FB0h SD_VAR
	.FILL   18h, 0
; 9FC8h MONITOR_VAR
	.FILL   18h, 0
; 9FE0h SCREEN_VAR
	.DB	000h		; SCR_CurBlock
	.DB	004h		; SCR_SizeBlock (128x96 = 4, 128x48 = 5, 32x24 = 6, 16x12 = 7 )
	.DB	000h		; SCR_MODE
	.DB	128		; SCR_WIDTH
	.DB	96		; SCR_HEIGHT
	.DW	0C000h		; SCR_ADDR
	.DB	0
;
	.FILL   8h, 0

;--------------------------------------------------------------------------
; MONITOR
;--------------------------------------------------------------------------
MONIT:
#include "monitor.asm"

#include "sd.asm"

;#include "disk.asm"
;---------------------------------------------------------------

;---------------------------------------------------------------
	.ORG	0FD00H
;	JR	PUT_SCR_CHR
;	JR	PUT_TTY_CHR
;	JR	PRINT_SCR_CHR
;	JR	PRINT_STR_TTY
;	JR	PRINT_STR_SCR
;	JR	PRINT_STACK_TTY
;	JR	PRINT_STACK_SCR
;	JR	HSCROLL
;	JR	VSCROLL
;	JR	CLEAR_SCR

;	.ORG	$FD20
;--------------------------------------------------------------------------
;  
;
CLEAR_SCR:
	PUSH	HL
	PUSH	BC

	LD	A, (SCR_ATTR)
	LD	C, A
	LD	B, 08H
CS0:
	LD	A, B
	DEC	A
	OUT	(SLOT6),A
	LD	A, 0FCh
	OUT	(SLOT6),A

	LD	HL, 0C000H
CS1:
	LD	(HL), 00h
	INC	HL
	LD	(HL), C
	INC	HL
	LD	A, H
	CP	0E0H
	JR	NZ, CS1

	DJNZ	CS0

	CALL	RESTORE_MAP

	POP	BC
	POP	HL
	RET
;--------------------------------------------------------------------------
;  
;
HSCROLL:
	LD	(SCR_HSCROLL), A
	OUT	($F5), A	 ; Video hscroll reg
	RET

;--------------------------------------------------------------------------
;  
;
VSCROLL:
	LD	(SCR_VSCROLL), A
	OUT	($F6), A	 ; Video vscroll reg
	RET
;--------------------------------------------------------------------------
;
;
RESTORE_MAP:
	LD	A, (MAPPER_REG + 0Ch)
	OUT	(SLOT6), A
	LD	A, (MAPPER_REG + 0Dh)
	OUT	(SLOT6), A

	RET
;--------------------------------------------------------------------------
;
;
SELECT_BLOCK:
	LD	A, (SCR_SB)	; SIZE_BLOCK - Lines count in 8K area
	LD	B, A
	LD	A, (SCR_VSCROLL)
	ADD	A, H		; Y - 
	LD	C, 1
SB_:
	RRCA
	SLA	C
	DJNZ	SB_

	AND	07h
	OUT	(SLOT6), A
	LD	A, 0FCh
	OUT	(SLOT6), A
;
; [ ADDR_SCREEN + ( SCR_POS.Y - SCR_BLOCK * SIZE_BLOCK, SCR_POS.X ) * 2 ] := CHAR
;
	LD	A, C
	DEC	A
	AND	H
	LD	H, A

	RET
;--------------------------------------------------------------------------
; A  - 0-0toL 1-Lto255
; HL - start pos YX
CLEAR_LINE:
	PUSH	HL
	PUSH	BC

	CALL	SELECT_BLOCK

	ADD	HL, HL
	LD	BC, 0C000h
	ADD	HL, BC

	LD	B, C
	LD	L, C
	LD	A, (SCR_ATTR)
CL1:
	LD	(HL), C
	INC	HL
	LD	(HL), A
	INC	HL
	DJNZ	CL1

	CALL	RESTORE_MAP

	POP	BC
	POP	HL
	RET
;---------------------------------------------------------------
;
;
PRINT_STR_TTY:
	LD	A, (DE)
	OR	A
	RET	Z
	CALL	_PUT_TTY_CHR
	INC	DE
	JR	PRINT_STR_TTY
;---------------------------------------------------------------
;
;
PRINT_STR_SCR:
	LD	A, (DE)
	OR	A
	RET	Z
	CALL	PRINT_SCR_CHR
	INC	DE
	JR	PRINT_STR_SCR
;--------------------------------------------------------------------------
; PRINT_MSG_TTY - display in-line message. String terminated by byte
;	with MSB set. Leaves a trailing space
; Destroys: A, HL
;--------------------------------------------------------------------------
;PRINT_STACK_TTY:
;	POP	HL		; HL -> string to display from caller
;PS_0:
;	LD	A, (HL)		; A = next character to display
;	AND	$7F		; Strip off MSB
;	CALL	_PUT_TTY_CHR	; Display character
;	OR	(HL)		; MSB set? (last byte)
;	INC	HL		; Point to next character
;	JR	NC, PS_0	; No, keep looping
;	JP	(HL)		; Return past the string
;--------------------------------------------------------------------------
;PRINT_STACK_SCR:
;	POP	HL		; HL -> string to display from caller
;PS_1:
;	LD	A, (HL)		; A = next character to display
;	AND	$7F		; Strip off MSB
;	CALL	PRINT_SCR_CHR	; Display character
;	OR	(HL)		; MSB set? (last byte)
;	INC	HL		; Point to next character
;	JR	NC, PS_1	; No, keep looping
;	JP	(HL)		; Return past the string
;---------------------------------------------------------------
;  C - char
;
PRINT_SCR_CHR:
	PUSH	HL
	PUSH	DE
	PUSH	BC

	LD	HL, (SCR_POS)
	LD	DE, (SCR_WIDTH)

	LD	C, A
	LD	A, (SCR_ESC)
	OR	A
	JP	NZ, PRN_SCR_ESC1
	LD	A, C

	CP	LF			;Is it a LF, Skip for now
	JR	Z, PRN_SCR_LF
	CP	FF			;Is it a FF (0CH,^L), if so clear screen 
	JR	Z, PRN_SCR_FF
	CP	CR			;Is it a CR, will convert to CR/LF
	JR	Z, PRN_SCR_CR
	CP	BACKS			;Back Space
	JR	Z, PRN_SCR_BS
	CP	TAB			;Is it a TAB, skip for now
	JR	Z, PRN_SCR_TAB
	CP	ESC			;ESC
	JR	Z, PRN_SCR_ESC
	CP	1FH			;Only real characters
	JR	C, PRN_SCR_EXIT

	CALL	_PUT_SCR_CHR

	INC	L
	LD	A, E
	CP	L
	JR	NZ, PRN_SCR_EXIT
PRN0:
	LD	L, 00h
; ---------------------------------------
PRN_SCR_LF:
	INC	H
	LD	A, D
	CP	H
	JR	NZ, PRN_SCR_EXIT

	DEC	H
	LD	A, (SCR_VSCROLL)
	INC	A
	LD	(SCR_VSCROLL), A
	OUT	($F6), A

	LD	B, L
	LD	L, 00h
	CALL	CLEAR_LINE
	LD	L, B
	JR	PRN_SCR_EXIT
; ---------------------------------------
PRN_SCR_BS:
	LD	A, L			;Get current RAM X position
	OR	A
	JR	Z, PRN_SCR_EXIT		;NO BS for first character, just return
	DEC	L
;	DEC	A
;	LD	(SCR_POSX), A
	LD	A, ' '
	CALL	_PUT_SCR_CHR
	JR	PRN_SCR_EXIT
; ---------------------------------------
PRN_SCR_TAB:
	LD	A, E
	INC	L
	CP	L
	JR	Z, PRN0

	LD	A, L
	AND	00000111B		;Max 8 spaces for tabs
	LD	B, A
	LD	A, 8
	SUB	B			
	LD	B, A			;1 to 8 spaces in loop below								
PRN2:
	INC	L
;	LD	A, L			;Get current RAM X position
;	LD	(SCR_POSX), A

	LD	A, ' '			;Print a space
	CALL	_PUT_SCR_CHR
	DJNZ	PRN2

	JR	PRN_SCR_EXIT
; ---------------------------------------
PRN_SCR_ESC:
	LD	A, 1
PRN_SCR_ESC_EXIT:
	LD	(SCR_ESC), A
	JR	PRN_SCR_EXIT_
; ---------------------------------------
PRN_SCR_FF:
	CALL	CLEAR_SCR
PRN_SCR_FF_:
	LD	H, 00h
PRN_SCR_CR:
	LD	L, 00h
PRN_SCR_EXIT:
	LD	(SCR_POS), HL
PRN_SCR_EXIT_:
	POP	BC
	POP	DE
	POP	HL
	RET
; ---------------------------------------
PRN_SCR_ESC1:
	DEC	A
	JR	NZ, PRN_SCR_ESC2
; ---------------------------------------
; 1
	LD	A, C
	CP	'A'
	JR	Z, PRN_L_UP
	CP	'B'
	JR	Z, PRN_L_DOWN
	CP	'C'
	JR	Z, PRN_L_RIGHT
	CP	'D'
	JR	Z, PRN_L_LEFT
	CP	'E'
	JR	Z, PRN_SCR_FF
	CP	'H'
	JR	Z, PRN_SCR_FF_
;	CP	'J'
;	JR	Z, PRN_L_ERASE
;	CP	'K'
;	JR	Z, PRN_L_LNERASE
	CP	'Y'
	JR	Z, PRN_L_MOVE
;	CP	'b'
;	JR	Z, PRN_L_BCOLOR
;	CP	'c'
;	JR	Z, PRN_L_COLOR
;	CP	'e'
;	JR	Z, PRN_L_ENCUR
;	CP	'f'
;	JR	Z, PRN_L_DISCUR
;	CP	'3'
;	JR	Z, PRN_L_SCRMODE
	CP	'['
	JR	Z, PRN_L_ESC
;	CP	'?'
;	JR	Z, PRN_L_ESC1
PRN_L_EXIT_:
	XOR	A
	JR	PRN_SCR_ESC_EXIT
; ---------------------------------------
PRN_L_UP:
	LD	A, H
	OR	A
	JR	Z, PRN_L_EXIT_
	DEC	H
PRN_L_EXIT:
	XOR	A
	LD	(SCR_ESC), A
	JR	PRN_SCR_EXIT
; ---------------------------------------
PRN_L_DOWN:
	LD	A, D ; HEIGHT
	INC	H
	CP	H
	JR	Z, PRN_L_EXIT_
	JR	PRN_L_EXIT
; ---------------------------------------
PRN_L_LEFT:
	LD	A, L
	OR	A
	JR	Z, PRN_L_EXIT_
	DEC	L
	JR	PRN_L_EXIT
; ---------------------------------------
PRN_L_RIGHT:
	LD	A, E ; WIDTH
	INC	L
	CP	L
	JR	Z, PRN_L_EXIT_
	JR	PRN_L_EXIT
; ---------------------------------------
PRN_L_ESC:
	LD	A, 2
	JR	PRN_SCR_ESC_EXIT
; ---------------------------------------
PRN_L_MOVE:
	LD	A, 3
	JR	PRN_SCR_ESC_EXIT

PRN_SCR_ESC2:
	DEC	A
	JR	NZ, PRN_SCR_ESC3
; ---------------------------------------
; 2
	LD	A, C
;	CP	'?'
;	JR	Z, PRN_L_11
;	CP	'0'
;	JR	C, PRN_L_EXIT_
;	CP	'9'+1
;	JR	NC, PRN_L_RIGHT
;	CP	'D'
;	JR	Z, PRN_L_LEFT

	JR	PRN_L_EXIT_

PRN_SCR_ESC3:
	DEC	A
	JR	NZ, PRN_SCR_ESC4
; ---------------------------------------
; 3
	LD	A, C
	SUB	20h
	LD	(SCR_POSY), A
	LD	A, 4
	JR	PRN_SCR_ESC_EXIT

PRN_SCR_ESC4:
	DEC	A
	JR	NZ, PRN_SCR_ESC5
; ---------------------------------------
; 4
	LD	A, C
	SUB	20h
	LD	(SCR_POSX), A

	JR	PRN_L_EXIT_

PRN_SCR_ESC5:
	JR	PRN_L_EXIT_

;---------------------------------------------------------------
;  C - char to AUX
;
CHANGE_OUT:
	PUSH	HL
	LD	HL, PRINT_SCR_CHR
	LD	A, (0017h)
	OR	A
	JR	Z, CH_0
	LD	HL, _PUT_TTY_CHR
CH_0:
	CPL
	LD	(0017h), A
	LD	(0009h), HL
	POP	HL
	RET
;---------------------------------------------------------------
;  C - char to AUX
;
CHANGE_IN:
	PUSH	HL
	LD	HL, _GET_PS2_CHR
	LD	A, (001Fh)
	OR	A
	JR	Z, CH_1
	LD	HL, _GET_TTY_CHR
CH_1:
	LD	(0011h), HL

	LD	HL, _CHKIN_PS2_CHR
	OR	A
	JR	Z, CH_2
	LD	HL, _CHKIN_TTY_CHR
CH_2:
	CPL
	LD	(001Fh), A
	LD	(0019h), HL
	POP	HL
	RET

;---------------------------------------------------------------
; Mapper and In/Out
;---------------------------------------------------------------
	.ORG	$FF00
;--------------------------------------------------------------------------
Int_Handler:
; switch stacks, then save CPU state on our interrupt stack
	LD	(SAVE_STACKPTR), SP
	LD	SP, INT_STACK
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	PUSH	IX
	PUSH	IY

; set preempted flag (so exitregion won't re-enable interrupts until we're done)
;	LD	A, 0FFh
;	LD	(preempted), A

	LD	A, (003Eh)
	DEC	A
	JR	NZ, IH_
	LD	A, (0027h)
	LD	(0C001h), A
	CPL
	LD	(0027h), A
	LD	A, 50
IH_:
	LD	(003Eh), A
Int_Done:
; clear preempted flag
;	XOR	A
;	LD	(preempted), A

	POP	IY
	POP	IX
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	LD	SP, (SAVE_STACKPTR)
	EI
	RET

	.ORG	$FF70
;---------------------------------------------------------------
;  C - char to AUX
;
_PUT_TTY_CHR:
	PUSH	AF
	IN	A, (USART_STAT)
	BIT	4,A
	JR	Z, $-4
	POP	AF
	OUT	(USART_DATA), A
	RET
;---------------------------------------------------------------
;  A - char from AUX
;
_GET_TTY_CHR:
	IN	A, (USART_STAT)
	BIT	7,A
	JR	Z, $-4
	IN	A, (USART_DATA)
	RET
;---------------------------------------------------------------
;  Z - char in AUX
;
_CHKIN_TTY_CHR:
	IN	A,(USART_STAT)	; Status byte
	BIT	7,A
	RET
;---------------------------------------------------------------
;  A - char from PS/2
;
_GET_PS2_CHR:
;	XOR	A
;	RET
;---------------------------------------------------------------
;  Z - char in PS/2
;
_CHKIN_PS2_CHR:
	XOR	A
	OR	A
	RET

	.ORG	$FF90
;---------------------------------------------------------------
;  A - char
;  HL - YX
;
_PUT_SCR_CHR:
	DI
	PUSH	BC
	PUSH	HL

	PUSH	AF

	CALL	SELECT_BLOCK

	LD	A, (SCR_HSCROLL)
	ADD	A, L
	LD	L, A

	ADD	HL, HL
	LD	BC, 0C000h ; (ADDR_SCREEN)
	ADD	HL, BC

	POP	AF
	LD	(HL), A
	INC	L
	LD	A, (SCR_ATTR)
	LD	(HL), A

	CALL	RESTORE_MAP

	POP	HL
	POP	BC
	EI
	RET
;---------------------------------------------------------------
;  A - slot
; DE - block
;	 
SLOT_CHANGE:
	DI
	PUSH	BC
	PUSH	HL

	AND	07h
	LD	B, A
	ADD	A, A		; system area
	ADD	A, 40h		; store reg 
	LD	L, A		;
	LD	H, 00h		; 0040h - 004Fh

	LD	(HL), E		;
	INC	L		;
	LD	(HL), D		;

	LD	A, B		; port index
	ADD	A, 0F8h		;
	LD	C, A		;

	LD	B, 0FFh		; write to mapper 
	OUT	(C), E		;
	OUT	(C), D		;

	POP	HL
	POP	BC
	EI
	RET
;---------------------------------------------------------------
;  A - block for slot (7)
; IX - addr
;
SLOT_CALL:
	DI
	PUSH	HL
	LD	(ISLOT_CALL+1), IX

	LD	HL, (MAPPER_REG + 0Eh)
	EX	(SP), HL
	PUSH	HL

	OUT	(SLOT7), A
	LD	A, 11111111B
	OUT	(SLOT7), A

	LD	A, 0C3h
	LD	(ISLOT_CALL), A
	LD	HL, _RET_
	EX	(SP), HL
	JP	ISLOT_CALL
_RET_:
	EX	(SP), HL
	PUSH	AF
	LD	A, L
	OUT	(SLOT7), A
	LD	A, H
	OUT	(SLOT7), A
	POP	AF
	POP	HL
	EI
	RET
;---------------------------------------------------------------
;
;---------------------------------------------------------------
;	.ORG	$FFF0
;	JR	SLOT_CHANGE
;	JR	SLOT_CALL
;	JR	_PUT_SCR_CHR
;---------------------------------------------------------------

.END