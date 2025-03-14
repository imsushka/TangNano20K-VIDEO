;**************************************************************************
;
;			Z 8 0 - R E T R O !  U T I L I T Y  M O N I T O R
;
;**************************************************************************
;	retromon.asm v1.8 - a monitor for the <jb> Z80-Retro! SBC
;	Kenny Maytum - KRSynthWorx - April 25th, 2023
;**************************************************************************

;**************************************************************************
;							L I C E N S E S
;**************************************************************************
;
;	This utility monitor...
;
;	Copyright (C) 2022,2023 Kenny Maytum
;	https://github.com/KRSynthWorx/z80-retro-monitor 
;
;	This library is free software; you can redistribute it and/or
;	modify it under the terms of the GNU Lesser General Public
;	License as published by the Free Software Foundation; either
;	version 2.1 of the License, or (at your option) any later version.
;
;	This library is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;	Lesser General Public License for more details.
;
;	You should have received a copy of the GNU Lesser General Public
;	License along with this library; if not, write to the Free Software
;	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;	02110-1301 USA
;
;	https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
;
;--------------------------------------------------------------------------
;
;	The SPI/SD Card library algorithms provided by John Winans...
;
;	Copyright (C) 2021,2022 John Winans
;	https://github.com/Z80-Retro/2063-Z80-cpm
;
;	This library is free software; you can redistribute it and/or
;	modify it under the terms of the GNU Lesser General Public
;	License as published by the Free Software Foundation; either
;	version 2.1 of the License, or (at your option) any later version.
;
;	This library is distributed in the hope that it will be useful,
;	but WITHOUT ANY WARRANTY; without even the implied warranty of
;	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;	Lesser General Public License for more details.
;
;	You should have received a copy of the GNU Lesser General Public
;	License along with this library; if not, write to the Free Software
;	Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
;	02110-1301 USA
;
;	https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
;
;**************************************************************************

;**************************************************************************
;						A C K N O W L E D G E M E N T S
;**************************************************************************
;
;	This monitor utility is inspired by and based on the 8080 assembler
;	1977-1979 versions of the Vector Graphic Inc. monitors by R. S. Harp.
;
;	Additional modifications, additions, improvements, and inspiration from
;	ideas and works by:
;	Mike Douglas:		https://deramp.com
;	Martin Eberhard:	https://en.wikipedia.org/wiki/Martin_Eberhard
;
;	Z80-Retro! SBC, FLASH programmer hardware, SPI and SD card library
;	routines closely based on work by John Winans.
;
;	Z80-Retro! project:	https://github.com/Z80-Retro/2063-Z80
;	FLASH programmer:	https://github.com/Z80-Retro/2065-Z80-programmer
;	CP/M BIOS project:	https://github.com/Z80-Retro/2063-Z80-cpm
;
;	John's Basement <jb> YouTube Channel:
;	https://www.youtube.com/c/JohnsBasement
;
;--------------------------------------------------------------------------
;
;	Many thanks to the above listed people that have made this
;	project possible!
;
;	Kenny Maytum
;	KRSynthWorx
;	https://github.com/KRSynthWorx/z80-retro-monitor
;
;**************************************************************************

;--------------------------------------------------------------------------
;			Build Commands | Command Summary | Using Retromon
;--------------------------------------------------------------------------
;
;	Set editor for tabstops = 4
;	You can also set Github tabstops to 4 permanently from the upper right
;	hand corner->profile icon dropdown->Settings->Appearance->
;	Tab size preference
;
;	Build using z80asm v1.8 running on a Raspberry Pi:
;		Source available at https://www.nongnu.org/z80asm
;		or install binary via command line: sudo apt-get install z80asm
;
;	Flash programmer running on a Rasberry Pi:
;		https://github.com/Z80-Retro/2065-Z80-programmer
;
;	***********************************************************************
;	***********************************************************************
;	* NOTE: Before building, set the SRAM size in the EQU at line 313     *
;	* The default configuration (EQU 0) is for a 512K SRAM chip installed *
;	*                                                                     *
;	* NOTE: Enable/Disable SD card partition 1 auto boot at line 314      *
;	* The default configuration (EQU 1) is auto boot enable               *
;	***********************************************************************
;	***********************************************************************
;
;	Build using the included Makefile (assumes flash utility is in your PATH)
;	make			; Build retromon.bin only
;	make flash		; Build retromon.bin and execute flash utility
;	make stack_test	; Build a program to test breakpoint/stack display
;	make clean		; Remove all built items
;
;	-Command Summary-
;
;	A -> D select low 32k RAM bank
;	B -> D boot SD partition
;	C -> SSSS FFFF DDDD compare blocks
;	D -> SSSS FFFF dump hex and ASCII
;	E -> SSSS FFFF DDDD exchange block
;	F -> SSSS FFFF DD DD two byte search
;	G -> LLLL go to and execute
;	H -> Command help
;	I -> PP input from I/O port
;	J -> SSSS FFFF dump Intel hex file
;	K -> SSSS FFFF DD fill with constant
;	L -> Load Intel hex file
;	M -> SSSS FFFF DDDD copy block
;	N -> Non-destructive memory test
;	O -> PP DD output to port
;	P -> LLLL program memory
;	Q -> SSSS FFFF compute checksum
;	R -> BBBB BBBB DDDD read SD block (512 bytes)
;	S -> SSSS FFFF DD one byte search
;	T -> SSSS FFFF destructive memory test
;	U -> LLLL set breakpoint
;	V -> Clear breakpoint
;	W -> LLLL BBBB BBBB write SD block (512 bytes)
;	X -> Reboot monitor
;	Y -> DDDD CCCC load binary file
;	Z -> LLLL CCCC dump binary file
;
;	<SSSS>Start Address <FFFF>Finish Address
;	<DDDD>Destination Address <D/DD>Data <PP>Port
;	<BBBB BBBB>32-bit SD Block <LLLL>Location Address
;	<CCCC>Size <Esc/Ctrl-c>Abort <Space>Pause
;
;	Using Retromon:
;
;	OK, please bear with me on this...
;
;	This monitor runs entirely in a 4096 byte page of SRAM on the Z80-Retro!
;	The stack is located at the end of this page. The device initialization
;	code is first copied from FLASH to SRAM low bank 0 (or E if a 128K SRAM
;	is installed instead of a 512K SRAM) beginning at 0x0000 on every boot.
;	Next, the monitor code is copied from the FLASH to its final location in
;	SRAM high bank F. The FLASH is then disabled which remaps the SRAM into
;	the FLASH address space. Execution continues in the SRAM low bank to
;	finish device initialization. The code then jumps and begins execution
;	in the upper bank and the low bank is now available for any use.
;
;	Whew... ok, all this trouble saves some SRAM as the device
;	initialization code only needs to execute once on boot and can be
;	discarded. Additionally we need the low SRAM to use CP/M.
;
;	When auto boot is enabled (see note above) and during the initialization
;	process, the following occurs. A startup message is displayed along with
;	a 5 second message and progress dots allowing you to press any key and
;	skip the auto boot from partition 1 of an SD card. If no SD card is
;	installed or there is an SD card error, an SD card error message is
;	displayed followed by the monitor asterisk command prompt. When auto boot
;	is disabled, the monitor command prompt is immediately displayed.
;
;	Up to 4 partitions on the SD card are available and information on these
;	partitions is located in the Master Boot Record (MBR) beginning at SD
;	block 0 on the SD card. Partition SD block starting addresses are stored
;	at the following offset locations from the beginning of the MBR:
;		Partition 1 -> 0x1BE+0x08
;		Partition 2 -> 0x1CE+0x08
;		Partition 3 -> 0x1DE+0x08
;		Partition 4 -> 0x1EE+0x08
;	The 32-bit address at these pointer locations indicates the SD card
;	block number of the beginning of the corresponding partition on the SD
;	card. Each SD block is 512 bytes in size. The monitor <B> 'Boot SD partition'
;	command extracts this information from the MBR. It then reads in 32 blocks
;	(16k bytes) and stores this beginning at 0xC000 in SRAM (which is always in
;	SRAM bank F). It then sets the A register to a 1 (indicating we are supplying
;	the partition and starting block information), sets the C register to the
;	partition number 1 - 4, sets the DE register to the high word of the starting
;	block address, and sets the HL register to the low word of the starting block
;	address where the code was read in from. The monitor then jumps to 0xC000
;	and begins execution. Hopefully something is useful there to execute.
;
;	All commands immediately echo a full command name as soon as the
;	first command letter is typed. This makes it easier to identify
;	commands without a list of commands present, although <H> 'Help' will
;	list all available commands for you. Upper or lower case can be used.
;
;	The command prompt is an asterisk. Backspace and DEL are not used.
;	If you make a mistake, type ESC (or ctrl-c) to get back to the prompt
;	and re-enter the command. Most executing commands can be aborted by
;	ESC (or ctrl-c).
;
;	All commands are a single letter. Four hex digits must be typed in
;	for an address. Two hex digits must be typed for a byte. Exceptions to 
;	this are the <A> 'Select Bank' and <B> 'Boot SD partition' command which
;	accept only 1 hex digit. The <H> 'Help' command indicates the number of
;	arguments each command accepts.
;
;	The spaces you see between the parameters are displayed by the monitor,
;	you don't type them. The command executes as soon as the last required
;	value is typed – a RETURN should not be typed.
;
;	Long running displays can be paused/resumed with the space bar.
;
;	The <D> 'Dump' command shows the currently selected lower 32K SRAM
;	bank in the first column of the display, the memory contents requested,
;	and an ASCII representation in additional columns. Bank 0 (or E if a
;	128K SRAM is configured) is selected at every boot and reflects
;	addresses 0x0000-0x7FFF. You can change this low 32K bank with the
;	<A> 'Select Bank' command to any desired bank 0 - E (or C - E if a
;	128K SRAM is configured). Addresses 0x8000-0xFFFF are always in bank F
;	and not switchable. The dump display always shows bank F when viewing
;	memory above 0x7FFF. The breakpoint, register and stack display also
;	indicates the currently selected 32K bank in the first column of the
;	display.
;
;	NOTE: All memory operation commands operate on the memory within
;	the currently selected low 32K bank. Memory operations above 0x7FFF
;	(upper 32K bank F) always affect that bank only regardless of the
;	currently selected low 32K bank. Currently there is no facility to
;	transfer memory between different low banks with this monitor but
;	this can be done in your own programs by accessing the GPIO_OUT
;	port 0x10 bits 4-7. Programs changing the SRAM bank should be
;	executed only from the upper 32K bank beginning at 0x8000 to avoid
;	crashing when the bank switch occurs. Otherwise the switch over code
;	can be duplicated in multiple banks to allow uninterrupted execution
;	between low banks. This monitor is currently located at 0xB000-0xBFFF.
;	Addresses 0xC000-0xFFFF are reserved for the CP/M loader, BDOS, CCP
;	and BIOS, but can still be used if not booting CP/M from the SD card.
;
;	The <N> 'Non-Destructive Test' command takes no parameters and runs
;	through the full 64K of SRAM (currently selected 32K low bank and 32k
;	high bank F). It skips the handful of bytes used in the memory
;	compare/swap routine to prevent crashing. A dot pacifier is displayed
;	at the start of each cycle through the memory test. Use ESC (or ctrl-c)
;	to exit back to the command prompt. Other low 32K SRAM banks can be
;	tested by first selecting another bank with the <A> 'Select Bank'
;	command.
;
;	The <T> 'Destructive Test' command skips the 4096 byte page that the
;	monitor and stack are in to prevent crashing. A dot pacifier is also
;	displayed as in the <N> command. Use ESC (or ctrl-c) to exit back to
;	the command prompt. As above, additional SRAM low banks can be tested
;	by first selecting the <A> 'Select Bank' command.
;
;	The <U> 'Break at' command sets a RST 08 opcode at the address
;	specified. The monitor then displays its asterisk main command prompt.
;	The <V> 'Clear Breakpoint' command can be used to manually remove an
;	unwanted breakpoint. Setting another breakpoint will clear the previous
;	breakpoint and install a new one. Upon execution of the code containing
;	the breakpoint, control is returned to the monitor and a register/stack
;	display is shown. The breakpoint is automatically cleared at this point.
;	A sub command line is presented that allows <Esc> 'Abort' back to
;	the monitor main prompt; <Enter> 'Continue' executing code with no more
;	breakpoints; <Space> 'Dump' a range of memory you specify; and
;	<LLLL> 'New BP' where a new location address can be specified. Execution
;	will immediately resume to the new breakpoint.
;
;	NOTE: Your code listing should be referenced when choosing breakpoint
;	locations if you wish to continue execution or add new breakpoints
;	using the sub command options described above. Breakpoints should be
;	placed on opcode not operand/mid-instruction/data area addresses. The
;	monitor breakpoint code does not keep track of how long each
;	instruction is so the code under test could crash if it is stopped and
;	restarted mid-instruction. If you ESC out to the main command prompt
;	after the FIRST breakpoint then it doesn't matter where you place it.
;
;	Currently configured console port settings are 9600:8N1. See the note
;	below in the .INIT_CTC_1 function to change these settings.
;
;	Semi-Pro Tip... If you include retromon.sym at the beginning of your
;	code, you will have access to all of the Z80-Retro! monitor public
;	subroutines and equate values by name.
;
;--------------------------------------------------------------------------

MONSTART	= $E000	; Beginning of Monitor (4K byte boundary)
;BASIC		= $A000	; BASIC
MEMSTART	= $0000	; Beginning of RAM/FLASH
LOAD_BASE	= $4000	; SD card boot loader image location
LOAD_BLKS	= 16	; SD card number of blocks to load

; Temporary storage area (21D bytes)
AFTEMP		= MONITOR_VAR + $00	; DW
BCTEMP		= MONITOR_VAR + $02	; DW
DETEMP		= MONITOR_VAR + $04	; DW
HLTEMP		= MONITOR_VAR + $06	; DW
PCTEMP		= MONITOR_VAR + $08	; DW
SPTEMP		= MONITOR_VAR + $0A	; DW
PARTITION	= MONITOR_VAR + $0C	; DB
PORT_RW		= MONITOR_VAR + $0D	; DB 0, 0, 0
BP_BYTE		= MONITOR_VAR + $10	;
BP_ADDR		= MONITOR_VAR + $11	;

RST6		= $0030		; RST6 vector at $0030

; Option equates
;**************************************************************************
AUTOSD_EN	= 1	; SET TO: Auto SD Boot 1 = Enable, 0 = Disable
;**************************************************************************

; Misc equates
BELL		= $07
BACKS		= $08
TAB		= $09
LF		= $0A
FF		= $0C
CR		= $0D
CTRLC		= $03
ESC		= $1B
BIT7		= $80		; MSB set for message string terminator
HXRLEN		= $10		; Intel hex record length

TBE		= $10
RDA		= $80

;--------------------------------------------------------------------------
; MONIT <X> - monitor entry point
;--------------------------------------------------------------------------
	CALL	PRINT_MSG_TTY			; Display monitor startup message
	.DB	CR,LF,LF,"Monitor Ready",CR,LF
	.DB	"<H> for hel",BIT7+'p'

; START - command processing loop
START:
	LD	SP, SYSTEM_STACK	; Re-init stack pointer
	LD	HL, START		
	PUSH	HL		; RET's go back to START

	CALL	CRLF		; Start a new line
	LD	A, '>'
	RST	08h	; Display '*' prompt

	CALL	GETCON		; Read command from keyboard to A
	AND	$5F		; Lower case to upper case
	CP	'A'		; Carry set if A < 'A'
	RET	C
	CP	'Z'+1		; Carry cleared if A > 'Z'
	RET	NC

	LD	DE, CMDTBL	; 'A' indexes to start of .CMDTBL
	SUB	'A'
	LD	H, 0
	LD	L, A
	ADD	HL, HL
	ADD	HL, DE

	LD	E, (HL)		; E = LSB of jump address
	INC	HL
	LD	D, (HL)		; D = MSB of jump address
	EX	DE, HL

	JP	(HL)		; Execute

; Command Table
CMDTBL:
	.DW	SBANK		; A -> D select low 32k RAM bank !!!!!! D DDD select range and bank 8k
	.DW	BASIC		; B -> Start BASIC
	.DW	START		; C -> Start CP/M
	.DW	DISASM		; D -> D boot SD partition
	.DW	START		; E -> 
	.DW	START		; F -> 
	.DW	EXEC		; G -> LLLL go to and execute
	.DW	HELP		; H -> Command help
	.DW	PINPT		; I -> PP input from I/O port
	.DW	HEXDUMP		; J -> SSSS FFFF dump Intel hex file
	.DW	START		; K -> 
	.DW	HEXLOAD		; L -> Load Intel hex file
	.DW	MENU2		; M -> Memory menu
	.DW	START		; N -> 
	.DW	POUTP		; O -> PP DD output to port
	.DW	DOBOOT		; P -> 
	.DW	START		; Q -> 
	.DW	SDREAD		; R -> BBBB BBBB DDDD read SD block (512 bytes)
	.DW	START		; S -> 
	.DW	START		; T -> 
	.DW	SETBRK		; U -> LLLL set breakpoint
	.DW	CLRBRK		; V -> Clear breakpoint
	.DW	SDWRT		; W -> LLLL BBBB BBBB write SD block (512 bytes)
	.DW	MONIT		; X -> Reboot monitor
	.DW	BLOAD		; Y -> DDDD CCCC load binary file
	.DW	BDUMP		; Z -> LLLL CCCC dump binary file

;--------------------------------------------------------------------------
; Memory works menu
;
MENU2:
	LD	SP, SYSTEM_STACK	; Re-init stack pointer
	LD	HL, MENU2		
	PUSH	HL		; RET's go back to START

	CALL	CRLF		; Start a new line
	LD	A, '>'
	RST	08h	; Display '*' prompt

	CALL	GETCON		; Read command from keyboard to A
	AND	$5F		; Lower case to upper case
	CP	'A'		; Carry set if A < 'A'
	RET	C
	CP	'Z'+1		; Carry cleared if A > 'Z'
	RET	NC

	LD	DE, CMDTBL1	; 'A' indexes to start of .CMDTBL
	SUB	'A'
	LD	H, 0
	LD	L, A
	ADD	HL, HL
	ADD	HL, DE

	LD	E, (HL)		; E = LSB of jump address
	INC	HL
	LD	D, (HL)		; D = MSB of jump address
	EX	DE, HL

	JP	(HL)		; Execute

CMDTBL1:
	.DW	SBANK		; A -> D select low 32k RAM bank !!!!!! D DDD select range and bank 8k
	.DW	START		; B -> Back to top menu
	.DW	COMPR		; C -> SSSS FFFF DDDD compare blocks
	.DW	DUMP		; D -> SSSS FFFF dump hex and ASCII
	.DW	EXCHG		; E -> SSSS FFFF DDDD exchange block
	.DW	SRCH2		; F -> SSSS FFFF DD DD two byte search
	.DW	EXEC		; G -> LLLL go to and execute
	.DW	HELP1		; H -> Command help
	.DW	START		; I -> 
	.DW	START		; J -> 
	.DW	FILL		; K -> SSSS FFFF DD fill RAM with constant
	.DW	START		; L -> 
	.DW	MOVEB		; M -> SSSS FFFF DDDD copy block
	.DW	NDMT		; N -> Non-destructive memory test
	.DW	START		; O -> 
	.DW	PGM		; P -> LLLL program memory
	.DW	CHKSUM		; Q -> SSSS FFFF compute checksum
	.DW	START		; R -> 
	.DW	SRCH1		; S -> SSSS FFFF DD one byte search
	.DW	TMEM		; T -> SSSS FFFF destructive memory test
	.DW	START		; U -> 
	.DW	START		; V -> 
	.DW	START		; W -> 
	.DW	START		; X -> Reboot monitor
	.DW	MEMMAP		; Y -> Memory map
	.DW	MAPPER		; Z -> Memory mapper


;**************************************************************************
;
;					C O M M A N D  S U B R O U T I N E S
;
;**************************************************************************
BASIC:
	LD	A, 0FEh
	LD	IX, 0E000h
	JP      $0028

;--------------------------------------------------------------------------
; SBANK <A> - select which low 32K RAM bank to use.
;	Valid ranges: 0-E using 512K SRAM, C-E using 128K SRAM
;--------------------------------------------------------------------------
SBANK:
	CALL	PRINT_MSG_TTY
	.DB	"Select slo",BIT7+'t'

	LD	C, 1		; Read 1 hex digit from command line
	CALL	AHE0		; Desired slot number to 7

	LD	A, E
;	OR	A
;	JR	Z,SBANK2	; OK if 0-7 selected

	CP	$08
	JR	C, SBANK1	; OK if 0-7 selected
SBANK2:
	CALL	PRINT_MSG_TTY		; Display range error message
	.DB	"Slot 0-7 onl",BIT7+'y'

	RET

SBANK1:
	CALL	PRINT_MSG_TTY
	.DB	CR, LF, "Select bloc",BIT7+'k'

        LD      B, E
	LD	C, 3		; Read 1 hex digit from command line
	CALL	AHE0		; Desired slot number to 7

	LD      A, B
	CALL    SLOT_CHANGE
	RET

;--------------------------------------------------------------------------
; 
;
;--------------------------------------------------------------------------
MAPPER:
	CALL	PRINT_MSG_TTY			; Display monitor startup message
	.DB	CR,LF,LF,"Memory mapper",CR,LF
	.DB	"Address - Block",CR,BIT7+LF

	LD	DE,0040h
	LD	HL,0000h
MM10:
	CALL	HexHL_CRLF
	LD	A, '-'
	RST	08h
	LD	A, ' '
	RST	08h

	EX	DE, HL
	PUSH	DE

	LD      E, (HL)
	INC	HL
	LD      D, (HL)
	EX	DE, HL
	LD	A, 'I'
	ADD	HL, HL
	JR	C, MM11
	LD	A, 'E'
MM11:
	RST	08h
	LD	A, ' '
	RST	08h
	LD	A, H
	AND	$0F
	CALL	Hex
	LD	A,L
	CALL	HexA
	LD	A, $00
	CALL	HexA
	CALL	Hex

	INC	DE
	POP	HL
	LD	A, 20h
	ADD	A, H
	LD	H, A
	JR	NC, MM10

	CALL	CRLF
	RET

;--------------------------------------------------------------------------
; 
;
;--------------------------------------------------------------------------
MEMMAP:
	CALL	PRINT_MSG_TTY			; Display monitor startup message
	.DB	CR,LF,LF,"Memory map",CR,LF
	.DB	"<R> - RAM, p - ROM, . - none",CR,BIT7+LF

	LD	HL,0000h
	LD	B,1

MAP1:	LD	E,'R'			;PRINT R FOR RAM
	LD	A,(HL)
	CPL
	LD	(HL),A
	CP	(HL)
	CPL
	LD	(HL),A
	JR	NZ,MAP2
	CP	(HL)
	JR	Z,PRINT
MAP2:	LD	E,'p'
MAP3:	LD	A,0FFH
	CP	(HL)
	JR	NZ,PRINT
	INC	L
	XOR	A
	CP	L
	JR	NZ,MAP3
	LD	E,'.'

PRINT:	LD	L,0
	DEC	B
	JR	NZ,NLINE
	LD	B,16
	CALL	CRLF
	CALL	HexHL_SPC
NLINE:	LD	A,' '
	RST	08h
	LD	A,E
	RST	08h
	INC	H
	JR	NZ,MAP1
	CALL	CRLF
	CALL	CRLF
	RET

;--------------------------------------------------------------------------
; 
;
;--------------------------------------------------------------------------
MEMMAP1:
	CALL	PRINT_MSG_TTY			; Display monitor startup message
	.DB	CR,LF,LF,"Memory map",CR,LF
	.DB	"<R> - RAM, p - ROM, . - none",CR,BIT7+LF

	LD	BC, $0001          ; page 255 of 255
boot_ram_loop:
; ----- $4000-$5FFF
	LD	A, C
	OUT	(SLOT1), A
	LD	A, B
	OUT	(SLOT1), A

	LD	A, C
	LD	($2000), A
	INC	A
	LD	($2001), A
	INC	A
	LD	($2002), A
	LD	A, B
	LD	($2003), A

	INC	BC
	LD	A, B
	CP	16
	JR	NZ, boot_ram_loop       ; never write to bank 0, that's this one!

; step two, check $4000 with each bank in page 1 to see if the address
; matches the one we wrote

	LD	DE, $0001          ; page 255 of 255
boot_check_ram:
	LD	B,16
	CALL	CRLF
	EX      DE, HL
	CALL	HexHL_SPC
	EX      DE, HL
      	LD	A,'.'
	RST	08h

boot_check_ram_loop:
	LD      HL, $2000

; ----- $4000-$5FFF
	LD	A, E
	OUT	(SLOT1), A
	LD	A, D
	OUT	(SLOT1), A

	LD	C, 'R'			;PRINT R FOR RAM

	LD	A, E
	xor     (hl)
	jr      nz, boot_check_ram_
	ld      a, E
	inc     a
	inc     hl
	xor     (hl)
	jr      nz, boot_check_ram_
	ld      a, E
	inc     a
	inc     a
	inc     hl
	xor     (hl)
	jr      nz, boot_check_ram_

boot_check_ram_next:
	INC	DE
	LD	A, D
	CP	16
	jr      z, boot_found_ramtop

      	LD	A, C
	RST	08h
	DEC	B
	JR	NZ,boot_check_ram_loop

	JR      boot_check_ram
boot_check_ram_:
	LD	A,(HL)
	CPL
	LD	(HL),A
	CP	(HL)
	CPL
	LD	(HL),A
	JR	NZ, MAP12
	CP	(HL)
	JR	Z, MAP11
MAP12:	LD	C, 'p'
MAP13:	LD	A,0FFH
	CP	(HL)
	JR	NZ, MAP11
	INC	L
	XOR	A
	CP	L
	JR	NZ,MAP13
	LD	C, '.'
MAP11:	JR	boot_check_ram_next

boot_found_ramtop:


; b now contains the highest available bank save in ram_top register
; plus $3fff for the lower 14 bits of the last address
	LD	A, C
	LD	(002Eh), A
	LD	A, B
	LD	(002Fh), A

; ----- $2000-$3FFF
	LD	A, 00000001B
	OUT	(SLOT1), A
	LD	A, 00001000B
	OUT	(SLOT1), A

	CALL	CRLF
	CALL	CRLF
	RET

;--------------------------------------------------------------------------
; DOBOOT <B> - boot SD partition
; DOBOOT_AUTO - autoboot from partition number in .PARTITION
;--------------------------------------------------------------------------
DOBOOT:
	CALL	PRINT_MSG_TTY
	.DB	"Boot SD partitio",BIT7+'n'
	
	LD	C,1		; Read 1 hex digit from command line
	CALL	AHE0		; Get desired partition in E

	LD	A,E
	CP	1
	JP	C,START		; Carry set if A < 1
	CP	5
	JP	NC,START	; Carry cleared if A > 4

	LD	(PARTITION), A	; Save partition number
	CALL	SD_DETECT	; Check for physical SD card

DOBOOT_AUTO:	
	CALL	SD_BOOT		; Boot SD card for block transfers

; Read the MBR (SD block 0, 512 bytes), store in SRAM beginning at .LOAD_BASE
; Push the starting block number onto the stack in little-endian order
	LD	HL,0		; SD card block number to read
	PUSH	HL		; High half
	PUSH	HL		; Low half
	LD	DE,LOAD_BASE	; Destination of read sector data
	CALL	SD_CMD17
	POP	HL		; Remove the block number from the stack
	POP	HL

	OR	A		; Check SD_CMD17 return code
	JR	Z,BOOT_CMD17_OK

	JP	SD_ERROR

; Read the 32 SD blocks of the desired partition
BOOT_CMD17_OK:
	CALL	CRLF
	LD	IX,LOAD_BASE+$01BE
	LD	A, (IX+0)	; Boot
	CALL	HexA
	CALL	SPCE
	LD	A, (IX+1)	; Start head
	CALL	HexA
	CALL	SPCE
	LD	A, (IX+2)	; Start sector
	PUSH	AF
	AND	3Fh
	CALL	HexA
	CALL	SPCE
	LD	L, (IX+3)	; Start cylinder
	POP	AF
	RLCA
	RLCA
	AND	3
	LD	H, A
	CALL	HexHL
	CALL	SPCE
	LD	A, (IX+4)	; Type
	CALL	HexA
	CALL	SPCE
	LD	A, (IX+5)	; Start head
	CALL	HexA
	CALL	SPCE
	LD	A, (IX+6)	; Start sector
	PUSH	AF
	AND	3Fh
	CALL	HexA
	CALL	SPCE
	LD	L, (IX+7)	; Start cylinder
	POP	AF
	RLCA
	RLCA
	AND	3
	LD	H, A
	CALL	HexHL
	CALL	SPCE
	LD	L, (IX+10)	; Start cylinder
	LD	H, (IX+11)	; Start cylinder
	CALL	HexHL
	LD	L, (IX+8)	; Start cylinder
	LD	H, (IX+9)	; Start cylinder
	CALL	HexHL
	CALL	SPCE
	LD	L, (IX+14)	; Start cylinder
	LD	H, (IX+15)	; Start cylinder
	CALL	HexHL
	LD	L, (IX+12)	; Start cylinder
	LD	H, (IX+13)	; Start cylinder
	CALL	HexHL
	CALL	CRLF

	LD	A,(PARTITION)	; Get desired partition number
	CP	1
	JR	Z,PART_1
	CP	2
	JR	Z,PART_2
	CP	3
	JR	Z,PART_3

	LD	IX,LOAD_BASE+$01EE+$08
	JR	DOBOOT1		; Else partition 4

PART_1:
	LD	IX,LOAD_BASE+$01BE+$08
	JR	DOBOOT1

PART_2:
	LD	IX,LOAD_BASE+$01CE+$08
	JR	DOBOOT1

PART_3:
	LD	IX,LOAD_BASE+$01DE+$08
	
DOBOOT1:
	CALL	PRINT_MSG_TTY
	.DB	CR,LF,"Partitio",BIT7+'n'

	LD	A,(PARTITION)
	CALL	Hex		; Display partition number
	CALL	SPCE

	LD	D,(IX+3)
	LD	E,(IX+2)
	PUSH	DE		; DE -> high word of block address to load
	LD	D,(IX+1)
	LD	E,(IX+0)
	PUSH	DE		; DE -> low word of block address to load

	LD	DE, LOAD_BASE	; Destination of read sector data
	LD	B, LOAD_BLKS	; Number of blocks to load (should be 32 == 16K)

	CALL	READ_BLOCKS
	POP	HL		; HL -> low word of block address loaded
	POP	DE		; DE -> high word of block address loaded

	OR	A		; Check READ_BLOCKS return code
	LD	A,(PARTITION)
	LD	C,A		; C -> partition number loaded
	LD	A,1		; Boot code version number 1 (for selectable partitions)
	RET	Z;,LOAD_BASE	; If no error, run the code read in from the SD card

	JP	SD_ERROR
;	RET

;--------------------------------------------------------------------------
; Read B number of blocks into memory at address DE starting with
; 32-bit little-endian block number on the stack
; Return A = 0 = success!
;--------------------------------------------------------------------------
READ_BLOCKS:
					; +12 = starting block number
					; +10 = return address
	PUSH	BC			; +8
	PUSH	DE			; +6
;	PUSH	IY			; +4

	LD	IY,-4
	ADD	IY,SP			; IY = &block_number
	LD	SP,IY

; Copy the first block number
	LD	A,(IY+10)
	LD	(IY+0),A
	LD	A,(IY+11)
	LD	(IY+1),A
	LD	A,(IY+12)
	LD	(IY+2),A
	LD	A,(IY+13)
	LD	(IY+3),A

READ_BLOCK_N:
	LD	A,'.'
	CALL 	0008h			; Display loading progress dots ...
	
; SP is currently pointing at the block number
	CALL	SD_CMD17
	OR	A
	JR	NZ,RB_FAIL

; Count the block
	DEC	B
	JR	Z,RB_SUCCESS	; Note that A == 0 here = success!

; Increment the target address by 512
	INC	D
	INC	D

; Increment the 32-bit block number
	INC	(IY+0)
	JR	NZ, READ_BLOCK_N
	INC	(IY+1)
	JR	NZ, READ_BLOCK_N
	INC	(IY+2)
	JR	NZ, READ_BLOCK_N
	INC	(IY+3)
	JR	READ_BLOCK_N

RB_SUCCESS:
	XOR	A

RB_FAIL:
	LD	IY,4
	ADD	IY,SP
	LD	SP,IY
;	POP	IY
	POP	DE
	POP	BC
	RET

;--------------------------------------------------------------------------
; COMPR <C> - compare two blocks of memory
;--------------------------------------------------------------------------
COMPR:
	CALL	PRINT_MSG_TTY
	.DB	"Compar",BIT7+'e'

	CALL	TAHEX			; Read addresses
	PUSH	HL				; Source start on stack
	CALL	AHEX
	EX	DE,HL			; DE = source end, HL = compare start

VMLOP:
	LD	A,(HL)			; A = compare byte
	INC	HL
	EX	(SP),HL			; HL -> source byte
	CP	(HL)			; Same?
	LD	B,(HL)			; B = source byte
	CALL	NZ,ERR			; Display the error
	CALL	BMP				; Increment pointers
	EX	(SP),HL			; HL -> compare byte
	JR	NZ,VMLOP

	POP	HL				; Remove temp pointer from stack
	RET

;--------------------------------------------------------------------------
; DUMP <D> - show current 32K bank & dump memory contents in hex and ASCII
;--------------------------------------------------------------------------
DUMP:
	CALL	PRINT_MSG_TTY
	.DB	"Dum",BIT7+'p'

	CALL	TAHEX			; HL -> start address, DE -> end address

DMPLINE:
	PUSH	HL				; Save start address
	CALL	CRLF
	CALL	DSPBANK			; Display current SRAM bank
	CALL	HexHL_SPC			; Display current address
	CALL	SPCE			; Add an extra space
	LD	C, 8				; 8 locations per line
	LD	B, 2				; Run .DMPHEX twice

; Dump line in hex
DMPHEX:
	LD	A,(HL)			; A = byte to display
	CALL	HexA				; Display it
	CALL	SPCE
	INC	HL
	DEC	C				; Decrement line byte count
	JR	NZ,DMPHEX		; Loop until 8 bytes done

	CALL 	SPCE
	LD	C,8				; Do 8 more bytes
	DEC	B
	JR	NZ,DMPHEX

; Dump line in ASCII
	CALL	SPCE
	POP	HL				; HL -> start of line
	LD	C,16			; 16 locations per line

DMPASC:
	LD	A,(HL)			; A = byte to display
	CP	$7F			; Clear carry if >= $7F
	JR	NC,DSPDOT		; Non printable, show '.'

	CP	' '				; Displayable character?
	JR	NC,DSPASC		; Yes, go display it

DSPDOT:
	LD	A,'.'			; Display '.' instead

DSPASC:
	RST	08h			; Display the character
	CALL	BMP				; Increment HL, possibly DE
	DEC	C				; Decrement line byte count
	JR	NZ,DMPASC		; Loop until 16 bytes done

	CALL	BMP				; Done?
	RET	Z				; Yes
	DEC	HL				; Else undo extra bump of HL
	JR	DMPLINE		; Do another line

;--------------------------------------------------------------------------
; EXCHG <E> - exchange block of memory
; MOVEB <M> - move (copy only) a block of memory
;--------------------------------------------------------------------------
MOVEB:
	CALL	PRINT_MSG_TTY
	.DB	"Mov",BIT7+'e'

	XOR	A				; A = 0 means "move" command
	JR	DOMOVE

EXCHG:
	CALL	PRINT_MSG_TTY
	.DB	"Exchang",BIT7+'e'
							; A returned <> 0 means "exchange" command

DOMOVE:
	LD	B,A				; Save move/exchange flag in B
	CALL	TAHEX			; Read addresses
	PUSH	HL
	CALL	AHEX
	EX	DE,HL
	EX	(SP),HL			; HL -> start, DE -> end, stack has destination

MLOOP:
	LD	C,(HL)			; C = byte from source
	EX	(SP),HL			; HL -> destination

	LD	A,B				; Move or exchange?
	OR	A
	JR	Z,NEXCH		; 0 means move only

	LD	A,(HL)			; A = from destination
	EX	(SP),HL			; HL -> source
	LD	(HL),A			; Move destination to source
	EX	(SP),HL			; HL -> destination

NEXCH:
	LD	(HL),C			; Move source to destination
	INC	HL				; Increment destination
	EX	(SP),HL			; HL -> source
	CALL	BMP				; Increment source and compare to end
	JR	NZ,MLOOP

	POP	HL				; Remove temp pointer from stack
	RET

;--------------------------------------------------------------------------
; EXEC <G> - execute the code at the address
;--------------------------------------------------------------------------
EXEC:
	CALL	PRINT_MSG_TTY
	.DB	"Got",BIT7+'o'

	CALL	AHEX		; DE -> address to begin execution
	EX	DE,HL

	JP	(HL)		; Execute from HL

;--------------------------------------------------------------------------
; HELP <H> - display command help table
;--------------------------------------------------------------------------
HELP:
	CALL	PRINT_MSG_TTY
	.DB	CR,LF,"A -> D select low 32k RAM bank",CR,LF
	.DB	"B -> Start BASIC",CR,LF
	.DB	"C -> Start CP/M",CR,LF
	.DB	"D -> SSSS FFFF disasm",CR,LF
;	.DB	"E -> ",CR,LF
;	.DB	"F -> ",CR,LF
	.DB	"G -> LLLL go to and execute",CR,LF
	.DB	"H -> Command help",CR,LF
	.DB	"I -> PP input from I/O port",CR,LF
	.DB	"J -> SSSS FFFF dump Intel hex file",CR,LF
;	.DB	"K -> ",CR,LF
	.DB	"L -> Load Intel hex file",CR,LF
	.DB	"M -> Memory menu",CR,LF
;	.DB	"N -> ",CR,LF
	.DB	"O -> PP DD output to port",CR,LF
	.DB	"P -> Boot SD partition",CR,LF
;	.DB	"Q -> ",CR,LF
	.DB	"R -> BBBB BBBB DDDD read SD block (512 bytes)",CR,LF
;	.DB	"S -> ",CR,LF
;	.DB	"T -> ",CR,LF
	.DB	"U -> LLLL set breakpoint",CR,LF
	.DB	"V -> Clear breakpoint",CR,LF
	.DB	"W -> LLLL BBBB BBBB write SD block (512 bytes)",CR,LF
	.DB	"X -> Reboot monitor",CR,LF
	.DB	"Y -> DDDD CCCC load binary file",CR,LF
	.DB	"Z -> LLLL CCCC dump binary file",CR,LF,LF
	.DB	"<SSSS>Start Address <FFFF>Finish Address",CR,LF
	.DB	"<DDDD>Destination Address <D/DD>Data <PP>Port",CR,LF
	.DB	"<BBBB BBBB>32-bit SD Block <LLLL>Location Address",CR,LF
	.DB	"<CCCC>Size <Esc/Ctrl-c>Abort <Space>Pause",CR,BIT7+LF

	RET

;--------------------------------------------------------------------------
; HELP <H> - display command help table
;--------------------------------------------------------------------------
HELP1:
	CALL	PRINT_MSG_TTY
	.DB	CR,LF,"A -> D LLLL select 8k slot RAM bank",CR,LF
	.DB	"B -> Back to top menu",CR,LF
	.DB	"C -> SSSS FFFF DDDD compare block",CR,LF
	.DB	"D -> SSSS FFFF dump hex and ASCII",CR,LF
	.DB	"E -> SSSS FFFF DDDD exchange block",CR,LF
	.DB	"F -> SSSS FFFF DD DD two byte search",CR,LF
	.DB	"G -> LLLL go to and execute",CR,LF
	.DB	"H -> Command help",CR,LF
;	.DB	"I -> ",CR,LF
;	.DB	"J -> ",CR,LF
	.DB	"K -> SSSS FFFF DD fill RAM with constant",CR,LF
;	.DB	"L -> ",CR,LF
	.DB	"M -> SSSS FFFF DDDD copy block",CR,LF
	.DB	"N -> Non-destructive memory test",CR,LF
;	.DB	"O -> ",CR,LF
	.DB	"P -> LLLL program memory",CR,LF
	.DB	"Q -> SSSS FFFF compute checksum",CR,LF
	.DB	"R -> BBBB BBBB DDDD read SD block (512 bytes)",CR,LF
	.DB	"S -> SSSS FFFF DD one byte search",CR,LF
	.DB	"T -> SSSS FFFF destructive memory test",CR,LF
;	.DB	"U -> ",CR,LF
;	.DB	"V -> ",CR,LF
;	.DB	"W -> ",CR,LF
	.DB	"X -> Reboot monitor",CR,LF
	.DB	"Y -> Memory map",CR,LF
	.DB	"Z -> Memory mapper",CR,LF,LF
	.DB	"<SSSS>Start Address <FFFF>Finish Address",CR,LF
	.DB	"<DDDD>Destination Address <D/DD>Data <PP>Port",CR,LF
	.DB	"<BBBB BBBB>32-bit SD Block <LLLL>Location Address",CR,LF
	.DB	"<CCCC>Size <Esc/Ctrl-c>Abort <Space>Pause",CR,BIT7+LF

	RET

;--------------------------------------------------------------------------
; PINPT <I> - input data from a port
;--------------------------------------------------------------------------
PINPT:
	CALL	PRINT_MSG_TTY
	.DB	"I",BIT7+'n'

	LD	C,2		; Read 2 hex digits from command line
	CALL	AHE0		; Port number to E

	LD	HL,PORT_RW+2	; Form IN PP RET in memory at HL
	LD	(HL),$C9	; RET opcode
	DEC	HL
	LD	(HL),E		; Input port of IN instruction
	DEC	HL
	LD	(HL),$DB	; IN opcode
	CALL	PORT_RW		; Call IN PP RET

	JP	HexA		; Tail call exit

;--------------------------------------------------------------------------
; HEXDUMP <J> - dump Intel hex file
;--------------------------------------------------------------------------
HEXDUMP:
	CALL	PRINT_MSG_TTY
	.DB	"Hexdum",BIT7+'p'

	CALL	TAHEX		; HL -> start address, DE -> end address

	EX	DE,HL
	AND	A				; Clear carry
	SBC	HL,DE			; Get difference
	INC	HL				; Add 1
	EX	DE,HL			; DE = byte count

; Loop to send requested data in .HXRLEN-byte records
; Send record-start
HXLINE:
	CALL	CRLF			; Send CRLF

	LD	BC,HXRLEN*256	; BC = bytes/line
							; C = 0 initial checksum
	LD	A,':'			; Record start
	RST	08h

; Compute this record length (B=.HXRLEN here)
	LD	A,E				; Short last line?
	SUB	B				; Normal bytes/line
	LD	A,D				; 16-bit subtract
	SBC	A,C				; C = 0 here
	JR	NC,HXLIN1		; N:full line
	LD	B,E				; Y:short line

HXLIN1:
; If byte count is 0 then go finish EOF record
	LD	A,B
	OR	A
	JR	Z,HXEOF

; Send record byte count = A, checksum = 0 in C here
	CALL	PAHCSM

; Send the address at the beginning of each line,
; computing the checksum in C
	CALL	PHLHEX			; HL = address

; Send the record type (00), checksum in C
	XOR	A
	CALL	PAHCSM

; Send B bytes of hex data on each line, computing the checksum in C
HXLOOP:
	CALL	PMHCSM			; Send character

	DEC	DE
	INC	HL
	DEC	B				; Next
	JR	NZ,HXLOOP

; Compute & send the checksum
	XOR	A
	SUB	C
	INC	B				; Send character
	CALL	PAHCSM

; Give the user a chance to break in at the end of each line
	CALL	PAUSE
	JR	HXLINE			; Next record

HXEOF:
	LD	B,3				; 3 bytes for start of EOF

HXELUP:
	XOR	A
	CALL	HexA				; Send $00 characters
	DEC	B
	JR	NZ,HXELUP

	LD	A,$01
	CALL	HexA				; Send $01 character, 4th EOF character
	LD	A,$FF
	CALL	HexA				; Send $FF character, 5th EOF character

	JP	CRLF			; Tail call exit

PHLHEX:
	LD	A,H				; H first
	CALL	PAHCSM
	LD	A,L				; Then L

	.DB	$FE			; CP opcode, skip over .PMHCSM

PMHCSM:
	LD	A,(HL)			; Get byte to send

PAHCSM:
	PUSH	AF
	ADD	A,C				; Compute checksum
	LD	C,A
	POP	AF				; Recover and send character
	CALL	HexA
	RET

;--------------------------------------------------------------------------
; FILL <K> - fill memory with a constant
;--------------------------------------------------------------------------
FILL:
	CALL	PRINT_MSG_TTY
	.DB	"Fil",BIT7+'l'

	CALL	TAHEX		; Read addresses
	PUSH	HL		; Start address on stack
	LD	C,2		; Read 2 hex digits from command line
	CALL	AHE0		; Input fill byte
	EX	DE,HL		; Byte to write from E to L
	EX	(SP),HL		; HL = start address, stack = fill byte
	POP	BC		; C = fill byte from stack

ZLOOP:
	LD	(HL),C		; Write into memory
	CALL	BMP		; Compare address, increment HL
	RET	Z		; Leave when done

	JR	ZLOOP

;--------------------------------------------------------------------------
; HEXLOAD <L> - load Intel hex through console port
;--------------------------------------------------------------------------
HEXLOAD:
	DI
	CALL	PRINT_MSG_TTY
	.DB	"Hexload - Paste hex file..",BIT7+'.'

; Receive a hex file line
RCVLINE:
	CALL	CRLF
	LD	C,0		; Clear echo character flag

WTMARK:
	CALL	CNTLC		; Read character from console
	SUB	':'		; Record marker?
	JR	NZ,WTMARK	; No, keep looking

; Have start of new record. Save the byte count and load address
; The load address is echoed to the screen so the user can
;	see the file load progress. Note A is zero here from above SUB ':'
	LD	D,A		; Init checksum in D to zero

	CALL	IBYTE		; Input two hex digits (byte count)
	LD	A,E		; Test for zero byte count
	OR	A
	JR	Z,FLUSH		; Count of 0 means end

	LD	B,E		; B = byte count on line

	INC	C		; Set echo flag for address bytes
	CALL	IBYTE		; Get MSB of address
	LD	H,E		; H = address MSB
	CALL	IBYTE		; Get LSB of address
	LD	L,E		; L = address LSB
	DEC	C		; Clear echo flag
;	LD	A, 0Dh
;	RST	08h

	CALL	IBYTE		; Ignore/discard record type

; Receive the data bytes of the record and move to memory
DATA:
	CALL	IBYTE		; Read a data byte (2 hex digits)
	LD	(HL),E		; Store in memory
	INC	HL
	DEC	B
	JR	NZ,DATA

; Validate checksum
	CALL	IBYTE		; Read and add checksum
	JR	Z,RCVLINE	; Checksum good, receive next line

	CALL	PRINT_MSG_TTY	; Display error message
	.DB	" Erro",BIT7+'r'
				; Fall into flush

; Flush rest of file as it comes in until no characters
;	received for about 1/4 second to prevent incoming file
;	data looking like typed monitor commands
;	[n] = number of T states, 51 T states @ 10Mhz = 5.1us
;	250msec ~ $BF70 loop cycles
FLUSH:
	IN	A,(USART_DATA)	; Clear possible received char
	LD	DE,$BF70	; 250msec delay

FLSHLP:
	IN	A,(USART_STAT)	; [11] Look for character on console
	AND	RDA		; [7]
	JR	NZ,FLUSH	; [7F/12T] Data received, restart

	DEC	DE		; [6] Decrement timeout
	LD	A,D		; [4]
	OR	E		; [4]
	JR	NZ,FLSHLP	; [7F/12T] Loop until zero
	EI
	RET

;--------------------------------------------------------------------------
; NDMT <N> - non-destructive memory test, skipping compare code below
;--------------------------------------------------------------------------
NDMT:
	CALL	PRINT_MSG_TTY
	.DB	"Non-Destructive Tes",BIT7+'t'

	LD	HL, MEMSTART	; Start address

NDCYCLE:
	LD	A,'.'		; Display '.' before each cycle
	RST	08h
	CALL	PAUSE		; Check for ctrl-c, esc, or space

NDLOP:
	LD	A,H			
	AND	$F0		; Upper nibble of H
	CP	MONSTART>>8	; On monitor 4k page?
	JR	NZ,DOCMP	; No, ok to compare

	LD	A,L		; Get LSB of current address
	CP	DOCMP&$FF	; Address < LSB .DOCMP?
	JR	C,DOCMP		; Yes, ok to compare

	CP	NDCONT&$FF	; Address < LSB .NDCONT?
	JR	C,NDCONT	; Yes, in compare code so skip memory test

DOCMP:
	LD	A,(HL)		; Read from address in HL
	LD	B,A		; Save original value in B
	CPL			; Form and write inverted value
	LD	(HL),A
	CP	(HL)		; Read and compare
	LD	(HL),B		; Restore original value
	CALL	NZ,ERR		; Display error if mismatch

NDCONT:
	INC	HL		; Next address to test
	LD	A,H
	OR	L		; HL wrap around to 0?
	JR	Z,NDCYCLE	; Then continue from beginning of memory

	JR	NDLOP		; Else continue test

;--------------------------------------------------------------------------
; POUTP <O> - output data to a port
;--------------------------------------------------------------------------
POUTP:
	CALL	PRINT_MSG_TTY
	.DB	"Ou",BIT7+'t'

	LD	C,2		; Read 2 hex digits from command line
	CALL	AHE0		; Port number in E

	LD	C,2		; Read 2 hex digits from command line
	CALL	AHE0		; Port to L, data in E

	LD	D,L		; D = port
	LD	HL,PORT_RW+2	; Form OUT PP RET in memory at HL
	LD	(HL),$C9	; RET opcode
	DEC	HL
	LD	(HL),D		; Output port for OUT instruction
	DEC	HL
	LD	(HL),$D3	; OUT opcode
	LD	A,E		; Port data value in A

	JP	(HL)		; Call OUT PP RET

;--------------------------------------------------------------------------
; PGM <P> - program memory
;--------------------------------------------------------------------------
PGM:
	CALL	PRINT_MSG_TTY
	.DB	"Progra",BIT7+'m'

	CALL	AHEX		; Read address
	EX	DE,HL
	CALL	CRLF

PGLP:
	LD	A,(HL)		; Read memory
	CALL	HexA		; Display 2 digits
	LD	A,'-'		; Load dash
	RST	08h		; Display dash

CRIG:
	CALL	GETCON_Echo	; Get user input
	CP	' '		; Space
	JR	Z,CON2		; Skip if space
	CP	CR		; Skip if CR
	JR	NZ,CON1
	CALL	CRLF		; Display CR,LF
	JR	CON2		; Continue on new line

CON1:
	EX	DE,HL
	LD	HL,0		; Get 16 bit zero
	LD	C,2		; Count 2 digits
	CALL	AHEXNR		; Convert to hex (no read)
	LD	(HL),E

CON2:
	INC	HL		; Next address
	JR	PGLP

;--------------------------------------------------------------------------
; CHKSUM <Q> - compute checksum
;--------------------------------------------------------------------------
CHKSUM:
	CALL	PRINT_MSG_TTY
	.DB	"Checksu",BIT7+'m'

	CALL	TAHEX
	LD	B,0		; Start checksum = 0

CSLOOP:
	LD	A,(HL)		; Get data from memory
	ADD	A,B		; Add to checksum
	LD	B,A
	CALL	BMP
	JR	NZ,CSLOOP	; Repeat loop

	LD	A,B		; A = checksum
	JP	HexA		; Display checksum and tail call exit

;--------------------------------------------------------------------------
; SDREAD <R> - read one SD block (512 bytes)
;--------------------------------------------------------------------------
SDREAD:
	CALL	PRINT_MSG_TTY
	.DB	"SD Rea",BIT7+'d'

	CALL	SD_DETECT	; Check for physical SD card
	CALL	SD_BOOT		; Boot SD card for block transfers
	CALL	TAHEX		; HL -> source block MSW, DE -> source block LSW

; Push the 32-bit starting block number onto the stack in little-endian order
	PUSH	HL		; High half in HL
	PUSH	DE		; Low half in DE

	CALL	AHEX		; DE -> destination address
	CALL	SD_CMD17
	POP	HL		; Remove the block number from the stack
	POP	HL

	OR	A
	RET	Z		; Return to command loop if no error

	JP	SD_ERROR

;	CALL	setDskIO
;	CALL	readsys
;	RET

;--------------------------------------------------------------------------
; SRCH1 <S> - search for one byte
; SRCH2 <F> - search for two bytes
;--------------------------------------------------------------------------
SRCH1:
	CALL	PRINT_MSG_TTY
	.DB	"Find ",BIT7+'1'

	XOR	A				; Zero flag means one byte search
	JR	DOSRCH

SRCH2:
	CALL	PRINT_MSG_TTY
	.DB	"Find ",BIT7+'2'
							; A returned <> 0 means two byte search
DOSRCH:
	PUSH	AF				; Save one/two byte flag on stack
	CALL	TAHEX

	PUSH	HL				; Save HL, getting 1st byte to find
	LD	C,2				; Read 2 hex digits from command line
	CALL	AHE0
	EX	DE,HL			; H = code, D = F
	LD	B,L				; Put code in B
	POP	HL				; Restore HL

	POP	AF				; A = one/two byte flag
	OR	A				; Zero true if one byte search
	PUSH	AF
	JR	Z,CONT

	PUSH	HL				; Save HL, getting 2nd byte to find
	LD	C,2				; Read 2 hex digits from command line
	CALL	AHE0
	EX	DE,HL
	LD	C,L
	POP	HL

CONT:
	LD	A,(HL)			; Read memory
	CP	B				; Compare to code
	JR	NZ,SKP			; Skip if no compare

	POP	AF				; A = one/two byte flag
	OR	A				; Zero true if one byte search
	PUSH	AF
	JR	Z,OBCP

	INC	HL				; Two byte search
	LD	A,(HL)
	DEC	HL
	CP	C
	JR	NZ,SKP

OBCP:
	INC	HL
	LD	A,(HL)			; Read next byte
	DEC	HL				; Decrement address
	CALL	ERR				; Display data found

SKP:
	CALL	BMP				; Check if done
	JR	NZ,CONT		; Back for more
	POP	AF				; Remove flag saved on stack
	RET

;--------------------------------------------------------------------------
; TMEM <T> - destructive memory test routine, skipping monitor page
;--------------------------------------------------------------------------
TMEM:
	CALL	PRINT_MSG_TTY
	.DB	"Destructive Tes",BIT7+'t'

	CALL	TAHEX		; Read addresses
	LD	BC,$5A5A	; Init BC to 01011010,01011010

CYCL:
	LD	A,'.'		; Display '.' before each cycle
	RST	08h
	CALL	RNDM
	PUSH	BC		; Keep all registers
	PUSH	HL
	PUSH	DE

TLOP:
	LD	A,H		; Get MSB of address
	AND	$F0		; Upper nibble only
	CP	MONSTART>>8	; Compare to MSB of monitor page
	JR	Z,SKIPWR	; In monitor, skip write

	CALL	RNDM
	LD	(HL),B		; Write in memory

SKIPWR:
	CALL	BMP
	JR	NZ,TLOP		; Repeat loop

	POP	DE		; Restore original values
	POP	HL
	POP	BC
	PUSH	HL
	PUSH	DE

RLOP:
	LD	A,H		; Get MSB of address
	AND	$F0		; Upper nibble only
	CP	MONSTART>>8	; Compare to MSB of monitor page
	JR	Z,SKIPRD	; In monitor, skip the read
                                
	CALL	RNDM		; Generate new sequence
	LD	A,(HL)		; Read memory
	CP	B		; Compare memory
	CALL	NZ,ERR		; Call error routine

SKIPRD:
	CALL	BMP
	JR	NZ,RLOP

	POP	DE
	POP	HL
	CALL	PAUSE		; Check for ctrl-c, esc, or space
	JR	CYCL		; Cycle again

; This routine generates pseudo-random numbers
RNDM:
	LD	A,B		; Look at B
	AND	10110100B	; Mask bits
	AND	A		; Clear carry
	JP	PE,PEVE		; Jump if even
	SCF

PEVE:
	LD	A,C		; Look at C
	RLA			; Rotate carry in
	LD	C,A		; Restore C
	LD	A,B		; Look at B
	RLA			; Rotate carry in
	LD	B,A		; Restore B
	RET			; Return with new BC

;--------------------------------------------------------------------------
; SETBRK <U> - set breakpoint
;--------------------------------------------------------------------------
SETBRK:
	CALL	PRINT_MSG_TTY
	.DB	"Break a",BIT7+'t'
	CALL	AHEX		; DE = breakpoint address

; Patch RST1 vector
	LD	A, $C3		; JP opcode
	LD	(RST6), A	; RST1 vector address
	LD	HL, DUMPREGS
	LD	(RST6+1), HL	; Store breakpoint handler address

	LD 	HL, (BP_ADDR)	; Get breakpoint address
	LD	A, $F7		; RST 30 opcode
	CP	(HL)		; Check if another breakpoint is already set
	JR	NZ, SETCODE	; If not, set new breakpoint

	CALL	CLRBRK1		; Otherwise clear old breakpoint first

SETCODE:
	LD	(BP_ADDR), DE	; Store BP address in table
	LD	A, (DE)		; Retrieve byte at this location
	LD	(BP_BYTE), A	; Store byte
	LD	A, $F7		; RST 30 opcode
	LD	(DE), A		; Replace user byte with RST 08 opcode
	RET

;--------------------------------------------------------------------------
; CLRBRK <V> - remove breakpoint RST opcode if one is set
;--------------------------------------------------------------------------
CLRBRK:
	LD	HL, (BP_ADDR)	; Get breakpoint address
	LD	A, $F7		; RST 30 opcode
	CP	(HL)		; Check if another breakpoint is already set
	JR	Z, CLRDSP	; If set, display msg and clear breakpoint

	CALL	PRINT_MSG_TTY
	.DB	"No BP se",BIT7+'t'

	RET

CLRDSP:
	CALL	PRINT_MSG_TTY
	.DB	"BP cleare",BIT7+'d'

CLRBRK1:
	LD	HL, (BP_ADDR)	; Get breakpoint address
	LD	A, (BP_BYTE)	; Get original byte
	LD	(HL), A		; Replace original byte
	RET

;--------------------------------------------------------------------------
; SDWRT <W> - write one SD block (512 bytes)
;--------------------------------------------------------------------------
SDWRT:
	CALL	PRINT_MSG_TTY
	.DB	"SD Writ",BIT7+'e'

	CALL	SD_DETECT	; Check for physical SD card
	CALL	SD_BOOT		; Boot SD card for block transfers

	CALL	AHEX		; DE -> source address
	LD	(HLTEMP), DE	;	and save it

	CALL	TAHEX		; HL -> destination block MSW, DE -> destination block LSW

; Push the 32-bit starting block number onto the stack in little-endian order
	PUSH	HL		; High half in HL
	PUSH	DE		; Low half in DE
	LD	HL, (HLTEMP)	; Restore source address
	EX	DE, HL		;	and put in DE
	CALL	SD_CMD24 
	POP	HL		; Remove the block number from the stack
	POP	HL

	OR	A
	RET	Z		; Return to command loop if no error

	JP	SD_ERROR

;--------------------------------------------------------------------------
; BLOAD <Y> - load a binary file
;--------------------------------------------------------------------------
BLOAD:
	CALL	PRINT_MSG_TTY
	.DB	"Binary Loa",BIT7+'d'

	CALL	TAHEX		; Destination address in HL, size in DE

	PUSH	HL		; Protect HL
	CALL	PRINT_MSG_TTY
	.DB	CR,LF,"Waiting for file ...",CR,BIT7+LF

	POP	HL

BLOAD1:
	IN	A, (USART_STAT)	; Read port status
	AND	RDA		; Data available?
	JR	Z, BLOAD1	; Loop if not

	IN	A, (USART_DATA)	; Read byte
	LD	(HL), A		;	and save
	INC	HL		; Address counter

	DEC	DE		; Byte counter
	LD	A, D             
	OR	E		; Check if done
	JR	NZ, BLOAD1

	JP	FLUSH		; Flush console and tail call exit

;--------------------------------------------------------------------------
; BDUMP <Z> - dump a binary file
;--------------------------------------------------------------------------
BDUMP:
	CALL	PRINT_MSG_TTY
	.DB	"Binary Dum",BIT7+'p'

	CALL	TAHEX		; Source address in HL, size in DE

	PUSH	HL		; Protect HL
	CALL	PRINT_MSG_TTY
	.DB	CR,LF,"Any key to begin ...",CR,BIT7+LF

	POP	HL

BDLOP:
	IN	A, (USART_STAT)	; Read port status
	AND	RDA		; Data available?
	JR	Z, BDLOP	; Loop if not

BDUMP1:
	IN	A, (USART_STAT)	; Read port status
	AND	TBE		; OK to transmit?
	JR	Z, BDUMP1	; Loop if not

	LD	A, (HL)		; Get byte
	OUT	(USART_DATA), A	;	and send
	INC	HL		; Address counter

	DEC	DE		; Byte counter
	LD	A, D
	OR	E		; Check if done
	JR	NZ, BDUMP1
	RET

;--------------------------------------------------------------------------
;
;--------------------------------------------------------------------------
DISASM:
	CALL	PRINT_MSG_TTY
	.DB	"Disas",BIT7+'m'

	CALL	TAHEX		; HL -> start address, DE -> end address

	EX	DE, HL
        PUSH    HL		; Save end address
disloop:
	CALL    disz80		; Disassemble one instruction
	CALL	CRLF		; Display CR,LF
        POP     HL		; Get end address
        PUSH    HL		; and safe it again for later
        AND     A		; Clear carry, just in case
        SBC     HL, DE		; End address reached?
        JR      NC, disloop	; No, continue disassembling
        POP     HL		; Get end address
	JP	CRLF		; Display CR,LF

#include "disasm.asm"

;--------------------------------------------------------------------------
; BMP - binary compare address and increment HL. Return zero flag true if
;	HL = DE. Once HL = DE, then DE is incremented each time
;	so the comparison remains true for subsequent calls
; Destroys: A
;--------------------------------------------------------------------------
BMP:
	LD	A,E		; Compare LSB's of HL,DE
	SUB	L
	JR	NZ,GO_ON	; Not equal

	LD	A,D		; Compare MSB's of HL,DE
	SBC	A,H		; Gives zero flag true if equal

GO_ON:
	INC	HL		; Increment HL
	RET	NZ		; Exit if HL <> DE yet

	INC	DE		; Increase DE as well so it will
	RET			;	still be equal next time

;**************************************************************************
;
;		T Y P E  C O N V E R S I O N ,  I N P U T,  O U T P U T
;						S U B R O U T I N E S
;
;**************************************************************************

;--------------------------------------------------------------------------
; TAHEX - read two 16 bit hex addresses. 1st returned in HL, 2nd in DE
; Destroys: A, C
;--------------------------------------------------------------------------
TAHEX:
	CALL	AHEX		; Get first address parameter
				; Fall into AHEX to get 2nd parameter

;--------------------------------------------------------------------------
; AHEX - read 4 hex ASCII digits, convert to binary
; AHE0 - read number in C of ASCII hex digits, convert to binary
; AHEEXNR - verify ASCII hex digit in A, convert to binary
;
; Returns: Display a space, binary value in DE
; Destroys: A, C, HL
;--------------------------------------------------------------------------
AHEX:
	LD	C, 4		; Count of 4 digits

AHE0:
	LD	HL, 0		; 16 bit zero

AHE1:
	CALL	GETCON_Echo	; Read a byte

; Verify valid hex digit and convert from ASCII to binary and place in HL
AHEXNR:
	CP	'0'
	JP	C,START		; Below '0', abort
	CP	'9'+1
	JR	C,ALPH		; '9' or above jump else verify valid alpha digit

	AND	$5F		; Lower to upper case
	CP	'A'
	JP	C,START
	CP	'F'+1
	JP	NC,START	; Below 'A' or above 'F' abort back to START

ALPH:
	ADD	HL,HL		; HL * 2
	ADD	HL,HL		; HL * 4
	ADD	HL,HL		; HL * 8
	ADD	HL,HL		; HL * 16 (= shift L 4 bits left, one hex digit)

	CALL	ASC2BIN		; Convert A from ASCII to a binary value
	ADD	A,L
	LD	L,A		; Stuff into L
	DEC	C
	JR	NZ,AHE1		; Keep reading
	EX	DE,HL		; Result in DE
				; Fall through to display a space

;--------------------------------------------------------------------------
; SPCE - display a space
;--------------------------------------------------------------------------
SPCE:
	LD	A,' '		; Display space
	JP      0008h

;--------------------------------------------------------------------------
; ASC2BIN - ASCII hex digit to binary conversion. Digit
;	passed in A, returned in A
;--------------------------------------------------------------------------
ASC2BIN:
	SUB	'0'		; '0' to 0 (ASCII bias)
	CP	10		; Digit 0 - 9?
	RET	C

	SUB	7		; 'A-F' to A-F (Alpha bias)
	RET

;--------------------------------------------------------------------------
; CNTLC - see if a character is at the console. If not, return
;	zero true. If ctrl-c or ESC typed, abort and return to the
;	command loop. Otherwise, return the character in A
; Destroys: A
;--------------------------------------------------------------------------
CNTLC:
	RST	18h
;	IN	A,(USART_STAT)	; Character at console?
;	AND	RDA
	RET	Z		; No, exit with zero true

	RST	10h
;	IN	A,(USART_DATA)	; Get the character
	AND	$7F		; Strip off MSB

	CP	CTRLC
	JP	Z,START		; Abort with ctrl-c
	CP	ESC
	JP	Z,START		; Or ESC
	RET


;--------------------------------------------------------------------------
; DSPBANK - display the currently selected 32K RAM bank
;	using the address in HL
; Destroys: A
;--------------------------------------------------------------------------
DSPBANK:
;	PUSH	AF		; Protect AF
	CALL	PAUSE		; Check for ctrl-c, esc or space
;	POP	AF

	PUSH	HL
	LD	A, H		; Get bank if address < $8000
	RLCA
	RLCA
	RLCA
	RLCA
	AND	$0E
	ADD	A, 40h
	LD	L, A
	XOR	A
	LD	H, A
	INC	HL
	LD	A, (HL)
	DEC	HL
	LD	L, (HL)
	AND	$0F
	LD	H, A
	CALL	HexHL
	POP	HL

;GETBANK:
;	LD 	A,0	; Get current bank

;DMPBANK:
;	CALL	Hex		; Display low nibble
	CALL	SPCE		; Add a space
	RET

;--------------------------------------------------------------------------
; DUMPREGS - dump registers, flags and stack after a previously set
;	breakpoint. Offer option to escape to main command loop, continue
;	execution, do a memory dump or set a new breakpoint and then execute
;--------------------------------------------------------------------------
DUMPREGS:
	LD	(HLTEMP),HL	; Save HL when breakpoint occurred
	EX	(SP),HL		; Transfer SP contents -> HL (return address after breakpoint)
	DEC	HL		; Adjust back to breakpoint address
	LD	(PCTEMP),HL	; Save PC when breakpoint occurred
	EX	(SP),HL		; Swap back
	PUSH	AF		; Save AF

	LD	HL,2		; Skip over AF push above
	ADD	HL,SP
	LD	(SPTEMP),HL	; Save SP when breakpoint occurred

	CALL	PRINT_MSG_TTY	; Display register/flag status header
	.DB	CR,LF,LF,"BP reached",CR,LF
	.DB	"Bnk  PC  _Flag_  AF   BC   DE   HL   IX   IY   SP "
	.DB	"  AF",$27	; $27 = ' character
	.DB	"  BC",$27
	.DB	"  DE",$27
	.DB	"  HL",$27
	.DB	" @BC @DE @HL @SP",CR,BIT7+LF

	LD	HL,(PCTEMP)
	CALL	DSPBANK		; Display currently selected 32K RAM bank
	CALL	SPCE
	CALL	HexHL_SPC		; Then display PC

	POP	HL		; Transfer AF -> HL pushed on above
	LD	(AFTEMP),HL
	LD	(BCTEMP),BC
	LD	(DETEMP),DE	; Save AF BC DE when breakpoint occurred

; Display flags from HL (Shown as SZHENC; characters displayed when corresponding flag is set)
	LD	BC,$8053	; S - sign ($80 = 10000000, $53 = 'S')
	CALL	MASKFLG
	LD	BC,$405A	; Z - zero ($40 = 01000000, $5A = 'Z')
	CALL	MASKFLG
	LD	BC,$1048	; H - half carry ($10 = 00010000, $48 = 'H')
	CALL	MASKFLG
	LD	BC,$0445	; E - even parity ($04 = 00000100, $45 = 'E')
	CALL	MASKFLG
	LD	BC,$024E	; N - add/subtract ($02 = 00000010, $4E = 'N')
	CALL	MASKFLG
	LD	BC,$0143	; C - carry ($01 = 00000001, $43 = 'C')
	CALL	MASKFLG

	CALL	SPCE
	CALL	HexHL_SPC		; Display AF from HL

	LD	BC,(BCTEMP)
	LD	HL,(HLTEMP)	; Get back BC HL, DE still safe
	CALL	PTHREE		; Display BC DE HL

	PUSH	IX
	POP	HL		; Transfer IX -> HL
	CALL	HexHL_SPC		; Display IX from HL

	PUSH	IY
	POP	HL		; Transfer IY -> HL
	CALL	HexHL_SPC		; Display IY from HL

	LD	HL,(SPTEMP)	; Get breakpoint SP
	CALL	HexHL_SPC		; Display SP from HL

	EX	AF,AF'		; Swap AF <-> AF'
	PUSH	AF		; AF' on stack
	EX	AF,AF'		; Restore AF
	POP	HL		; Transfer AF' -> HL
	CALL	HexHL_SPC		; Display AF' from HL

	EXX			; Swap 16-bit register pairs
	CALL	PTHREE		; Display BC' DE' HL'
	EXX			; Swap back

	LD	BC,(BCTEMP)	; Restore BC
	LD	A,(BC)
	CALL	HexAS		; Display contents of BC

	LD	DE,(DETEMP)	; Restore DE
	LD	A,(DE)
	CALL	HexAS		; Display contents of DE

	LD	HL,(HLTEMP)	; Restore HL
	LD	A,(HL)
	CALL	HexAS		; Display contents of HL

	POP	HL		; Get contents of SP
	DEC	SP
	DEC	SP		; Restore back stack
	CALL	HexHL_SPC		; Display contents of SP

	CALL	PRINT_MSG_TTY
	.DB	CR,LF,LF,"_Stack Dump_ (SP+15 bytes",BIT7+')'

	CALL	CRLF
	LD	HL,(SPTEMP)	; Get breakpoint SP
	LD	B,16		; Show last 16 bytes of the stack

DSTACK:
	CALL	SPCE
	CALL	DSPBANK		; Display current RAM bank from address in HL
	CALL	SPCE
	CALL	HexHL_SPC		; Display current stack address from HL
	CALL	SPCE

	LD	A,(HL)		; A = byte to display
	CALL	HexA		; Display it
	CALL	CRLF

	INC	HL		; Advance stack address pointer
	DEC	B		; Adjust counter
	JR	NZ,DSTACK	; Continue?

	CALL	CLRBRK		; Clear and display breakpoint cleared
	CALL	CRLF

SUBMSG:
	CALL	PRINT_MSG_TTY
	.DB	CR,LF,"<Esc>Abort <Enter>Continue <Space>Dump <LLLL>New BP?-",BIT7+'>'

SUBCMD:
	LD	C,4		; Count of 4 digits
	LD	HL,$0000	; 16 bit zero

AHE2:
	CALL	GETCON_Echo	; Read a byte

	CP	ESC
	JP	Z,START		; Esc?, restart @ main command loop

	CP	' '
	JR	Z,PREDUMP	; Space?, process DUMP command

	CP	CR
	JR	Z,CONTINUE	; Enter?, continue from breakpoint
				; Else, process new breakpoint address

	CP	'0'
	JR	C,SUBMSG	; Below '0', abort back to .SUBMSG
	CP	'9'+1
	JR	C,ALPH2		; '9' or below jump else verify valid alpha digit

	AND	$5F		; Lower to upper case
	CP	'A'
	JR	C,SUBMSG
	CP	'F'+1
	JR	NC,SUBMSG	; Below 'A' or above 'F' abort back to .SUBMSG

ALPH2:
	ADD	HL,HL		; HL * 2
	ADD	HL,HL		; HL * 4
	ADD	HL,HL		; HL * 8
	ADD	HL,HL		; HL * 16 (= shift L 4 bits left, one hex digit)

	CALL	ASC2BIN		; Convert A from ASCII to a binary value
	ADD	A,L
	LD	L,A		; Stuff into L
	DEC	C		; Adjust counter
	JR	NZ,AHE2		; Keep reading

	LD	(BP_ADDR),HL	; Store BP address in table
	LD	A,(HL)		; Retrieve byte at this location
	LD	(BP_BYTE),A	; Store byte
	LD	A,$F7		; RST 30 opcode
	LD	(HL),A		; Replace user byte with RST 08 opcode

CONTINUE:			; Put registers back like they were before breakpoint occurred
	CALL	CRLF
	LD	HL,(AFTEMP)	; Restore AF
	PUSH	HL
	POP	AF

	LD	BC,(BCTEMP)	
	LD	DE,(DETEMP)
	LD	HL,(HLTEMP)	; Restore BC DE HL
				; SP still good at this point
	RET			; Continue where breakpoint left off

PREDUMP:
	PUSH	AF		; Protect AF BC HL
	PUSH	BC
	PUSH	HL

	CALL	CRLF
	LD	A,'*'
	RST	08h		; Display command prompt for uniformity
	CALL	DUMP		; Execute DUMP, get address range and display
	CALL	CRLF

	POP	HL
	POP	BC
	POP	AF
	JP	SUBMSG		; Back to .SUBMSG

HexAS:
	CALL	HexA		; Display 2 characters
	CALL	SPCE		; Display 2 spaces
	JP	SPCE		; Tail call exit

; Display BC DE HL in order
PTHREE:
	PUSH	HL		; Protect HL
	PUSH	BC      
	POP	HL		; Transfer BC -> HL
	CALL	HexHL_SPC		; Display BC
	PUSH	DE
	POP	HL		; Transfer DE -> HL
	CALL	HexHL_SPC		; Display DE
	POP	HL		; Get HL back
	JP	HexHL_SPC		; Display HL and tail call exit

MASKFLG:
	LD	A,L		; Get flags from L
	AND	B		; Flag mask in B
	LD	A, ' '		; Display blank if flag cleared
	JP	Z, 0008h	; Tail call exit
	LD	A, C		; Display flag character from C
	JP	0008h		; Tail call exit

;--------------------------------------------------------------------------
; ERR - display the address in HL followed by the value in B, then in A
;--------------------------------------------------------------------------
ERR:
	PUSH	AF				; Protect AF
	CALL	HexHL_CRLF			; Display address
	LD	A,B				; Display B
	CALL	HexA
	CALL	SPCE
	POP	AF
	JP      HexA

;--------------------------------------------------------------------------
; PAUSE - pause/resume with spacebar. Also look for a ctrl-c
;	or ESC to abort
; Destroys: A
;--------------------------------------------------------------------------
PAUSE:
	CALL	CNTLC		; Look for abort or other character
	CP	' '
	RET	NZ		; Return if not space or abort

PLOOP:
	CALL	CNTLC		; Loop here until space or abort pressed
	CP	' '
	JR	NZ,PLOOP
	RET

;--------------------------------------------------------------------------
; IBYTE - read two ASCII hex bytes and return binary value in E, add binary
;   value to running checksum in D
; Destroys: A
;--------------------------------------------------------------------------
IBYTE:
	CALL	GETCHAR		; Get a character
	CALL	ASC2BIN		; ASCII hex digit to binary
	ADD	A,A		; Put in MSN, zero LSN
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	E,A		; Save byte with MSN in E

; 2nd byte (LSN)
	CALL	GETCHAR		; Get a character
	CALL	ASC2BIN		; ASCII hex digit to binary
	ADD	A,E		; Combine MSN and LSN
	LD	E,A		; Save in E
	ADD	A,D		; Add character to checksum
	LD	D,A		; Save checksum back in D
	RET

;--------------------------------------------------------------------------
; PRINT_MSG_TTY - display in-line message. String terminated by byte
;	with MSB set. Leaves a trailing space
; Destroys: A, HL
;--------------------------------------------------------------------------
PRINT_MSG_TTY:
	POP	HL		; HL -> string to display from caller
PM_LOOP:
	LD	A, (HL)		; A = next character to display
	AND	$7F		; Strip off MSB
	RST	08h	; Display character
	OR	(HL)		; MSB set? (last byte)
	INC	HL		; Point to next character
	JP	P, PM_LOOP	; No, keep looping

	CALL	SPCE		; Display a trailing space
	JP	(HL)		; Return past the string

;--------------------------------------------------------------------------
; HexHL - display CR/LF and the address in HL
; HexHL1 - display the address in HL
; Destroys: A
;--------------------------------------------------------------------------
HexHL_CRLF:
	CALL	CRLF

HexHL_SPC:
	CALL	PAUSE		; Check for ctrl-c, esc, or space
	CALL	HexHL		; Display ASCII codes for address
	CALL	SPCE
	RET

;--------------------------------------------------------------------------
; HexHL - display the value in HL
;--------------------------------------------------------------------------
HexHL:
	LD	A,H
	CALL	HexA		; Display ASCII codes for address
	LD	A,L
;--------------------------------------------------------------------------
; HexA - display the value in A	
;--------------------------------------------------------------------------
HexA:				; Display A
	PUSH	AF		; Protect AF
	RRA			; Move MSN to LSN
	RRA
	RRA
	RRA
	CALL	Hex		; High 4 bits
	POP	AF
;--------------------------------------------------------------------------
; HexAh - display MSN of byte passed in A
; HexAl - display LSN of byte passed in A
;--------------------------------------------------------------------------
Hex:
	AND	0FH		; Low 4 bits
	ADD	A, '0'		; ASCII bias
	CP	$3A		; Digit 0-9
	JR	C, H_		; Display digit, tail call exit
	ADD	A, 7		; Alpha digit A-F
H_:
	JP	0008h		; Display alpha, tail call exit

;--------------------------------------------------------------------------
; DISPLAY 8 BITS OF [A] (No registers changed)
; DISPLAY BIT PATTERN IN [A]
;--------------------------------------------------------------------------
BIN:	PUSH	AF
	PUSH	BC
	PUSH	DE

	LD	E,A		
	LD	B,8
BL_:	SLA	E	
	LD	A,18H
	ADC	A,A
	RST	08h
	DJNZ	BL_

	POP	DE
	POP	BC
	POP	AF
	RET

;--------------------------------------------------------------------------
; Input: HL = number to convert
; Output: ASCII string
;--------------------------------------------------------------------------
DEC:	PUSH	BC
	LD	BC, -10000
	CALL	Num1
	LD	BC, -1000
	CALL	Num1
	LD	BC, -100
	CALL	Num1
	LD	C, -10
	CALL	Num1
	LD	C, B
	CALL	Num1
	POP	BC
	RET
Num1:
	LD	A, '0'-1
Num2:
	INC	A
	ADD	HL, BC
	JR	C, Num2
	SBC	HL, BC
	JP	0008h

;--------------------------------------------------------------------------
; CRLF - display CR/LF
; Destroys: A
;--------------------------------------------------------------------------
CRLF:
	LD	A, CR
	RST	08h
	LD	A, LF
	JP	0008h

;--------------------------------------------------------------------------
; GETCHAR - read a character from the console port into A. The
;	character is also echoed to the console port if the echo
;	flag (C) is set (non-zero)
;--------------------------------------------------------------------------
GETCHAR:
	PUSH	BC		; Protect BC

	CALL	GETCON		; Read character from console
				; Process new character in A
				; Echo to console if C is non-zero
	LD	B,A		; Save character in B
	LD	A,C		; Echo flag (C) set?
	OR	A
	JR	Z,NOECHO	; No echo

	LD	A,B		; A = character to send
	POP	BC
	JP	0008h		; Display character and tail call exit

NOECHO:
	LD	A,B		; A = byte read
	POP	BC
	RET

;--------------------------------------------------------------------------
; RDCN - read from console to A with echo to screen
; GETCON - read from console to A without echo
;--------------------------------------------------------------------------
GETCON_Echo:
	CALL	GETCON		; Get character from console
	CP	ESC		; ESC confuses smart terminals
	RET	Z		; 	 so don't echo escape
	JP	0008h		; Echo onto display and tail call exit

GETCON:
	RST	10h
;	IN	A,(USART_STAT)	; Read keyboard status
;	AND	RDA		; Data available?
;	JR	Z,GETCON

;	IN	A,(USART_DATA)	; Read from keyboard
	AND	$7F		; Strip off MSB
	RET
