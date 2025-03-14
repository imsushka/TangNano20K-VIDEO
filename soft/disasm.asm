; ====================
; DIS-Z80 was published in the SUBSET column of Personal Computer World 1987.
; The routine disassembles a single Z80 instruction at address DE. 
; It is required to be followed by a routine called CHROP that outputs a 
; single ASCII character.
; It was originally developed for CP/M on an Amstrad CPC128.
; The original ORG was $0100. I have added $5000 to all addresses.
; The stated aim was to write a Z80 disassembly routine in as short a space
; as possible and, at just over 1K (1090 bytes), it is a rather incredible 
; program. 
; The SUBSET editor David Barrow was able to trim only one byte from John 
; Kerr's compact code. I've forgotten where so there's a challenge.
; ====================

disz80:	CALL    ADRSP
        LD      BC, $0900
        LD      HL, $2020

DBUFFER:PUSH    HL
        DJNZ    DBUFFER
        LD      H, B
        LD      L, C
        ADD     HL, SP

        PUSH    BC		; Store IX
        EX      (SP), IX
        PUSH    BC
        PUSH    BC
        ADD     IX, SP

        PUSH    HL		; Store start string
        LD      HL, GROUP3

TRYNDX:	CALL    DFETCH		; 1st byte

        LD      B, C
        CP      $ED
        JR      Z, CONFLG

        INC     B
        CP      $DD
        JR      Z, CONFLG

        INC     B
        CP      $FD
        JR      NZ, NOTNDX
; 0 - ED, 1 - DD, 2 - FD
CONFLG:	LD      (IX + 1), B
        INC     B
        DJNZ    TRYNDX

        JR      NXBYTE
; --- DD, FD or std
NOTNDX:	LD      C, A
        LD      A, (IX + 1)
        OR      A
        JR      Z, NODISP	; std

        LD      A, C
        CP      $CB
        JR      Z, GETDIS

        AND     $44
        CP      4
        JR      Z, GETDIS

        LD      A, C
        AND     $C0
        CP      $40
        JR      NZ, NODISP

GETDIS:	CALL    DFETCH		; 2nd byte 0DDh, 0FDh
        LD      (IX + 2), A

NODISP:	LD      HL, GROUP1
        LD      A, C
        CP      $CB
        JR      NZ, NEWMSK

        LD      HL, GROUP2

NXBYTE:	CALL    DFETCH		; 2nd byte 0CB,
        LD      C, A

NEWMSK:	LD      A, (HL)
        OR      A
        JR      Z, TABEND

        AND     C
        INC     HL

NEWMOD:	LD      B, (HL)
        INC     HL
        INC     B
        JR      Z, NEWMSK

TRYMAT:	CP      (HL)
        INC     HL
        JR      Z,GETNDX

        BIT     7, (HL)
        INC     HL
        JR      Z, TRYMAT

        JR      NEWMOD
; ---
GETNDX:	LD      A, (HL)
        AND     $7F
        DEC     B
; A - index 
TABEND:
	POP     HL		; Restore start string
        PUSH    DE
        PUSH    HL

        EX      DE, HL
        LD      HL, MONICS
        CALL    XTRACT

        POP     HL
        LD      DE, 5
        ADD     HL, DE
        POP     DE

        LD      A, B
        AND     $F0
        JR      Z, SECOND

        RRA
        RRA
        RRA
        RRA
        PUSH    BC

        LD      B,A
        LD      A,C
        CALL    OPRND1

        POP     BC
        LD      A,B
        AND     $0F
        JR      Z, OPDONE

        LD      (HL), ','
        INC     HL

SECOND:	LD      A,B
        AND     $0F

        LD      B,A
        LD      A,C
        CALL    NZ, OPRND2

OPDONE:	LD      A, 4
        SUB     (IX + 0)	; Bytes count

        POP     HL
        POP     HL
        POP     IX

        JR      C, OUTEXT

        INC     A
        LD      B,A
        ADD     A,B
        ADD     A,B
        LD      B,A

DSPACES:LD      A, ' '
        RST	08h
        DJNZ    DSPACES

OUTEXT:	LD      B, 18

PUTOUT:	DEC     SP
        POP     HL
        LD      A,H
        RST	08h
        DJNZ    PUTOUT

        RET

; -------------------------------------
; Prefix CBh
GROUP2:	.DB	$C0		; MASK = C0h
	.DB	$36		; MOD = 36h, 1st = 3, 2nd = 6
	.DB	$40,$04		; BIT
	.DB	$80,$2D		; RES
	.DB	$C0,$BE		; SET
	.DB	$FF
        .DB	$F8		; MASK = F8h
	.DB	$06		; MOD = 06h, 1st = 0, 2nd = 6
	.DB	$00,$33		; RLC
        .DB	$08,$38		; RRC
	.DB	$10,$35		; RL
	.DB	$18,$3A		; RR
	.DB	$20,$3F		; SLA
	.DB	$28,$40		; SRA
        .DB	$30,$00		; 0  SLL
	.DB	$38,$C1		; SRL

; -------------------------------------
GROUP1:	.DB	$FF		; MASK = FFh
	.DB	$00		; MOD = 00h, 1st = 0, 2nd = 0
	.DB	$00,$24		; NOP
	.DB	$07,$32		; RLCA
	.DB	$0F,$37		; RRCA
        .DB	$17,$31		; RLA
	.DB	$1F,$36		; RRA
	.DB	$27,$0D		; DAA
	.DB	$2F,$0B		; CPL
	.DB	$37,$3D		; SCF
        .DB	$3F,$06		; CCF
	.DB	$76,$14		; HALT
	.DB	$C9,$30		; RET
	.DB	$D9,$12		; EXX
	.Db	$F3,$0F		; DI
        .DB	$FB,$91		; EI

	.DB	$72		; MOD = 72h, 1st = 7, 2nd = 2
	.DB	$C6,$02		; ADD 
        .DB	$CE,$01		; ADC
	.DB	$DE,$BC		; SBC

	.DB	$02		; MOD = 02h, 1st = 0, 2nd = 2
        .DB	$D6,$42		; SUB
	.DB	$E6,$03		; AND
	.DB	$EE,$43		; XOR
	.DB	$F6,$25		; OR
	.DB	$FE,$8C		; CP

        .DB	$04		; MOD = 04h, 1st = 0, 2nd = 4
	.DB	$08,$93		; EX

	.DB	$01		; MOD = 01h, 1st = 0, 2nd = 1
	.DB	$10,$10		; DJNZ
	.DB	$18,$9D		; JR
	.DB	$AF		; MOD = AFh, 1st = A, 2nd = F
	.DB	$22,$A2		; LD
	.DB	$FA		; MOD = FAh, 1st = F, 2nd = A
	.DB	$2A,$A2		; LD
	.DB	$A7		; MOD = A7h, 1st = A, 2nd = 7
        .DB	$32,$A2		; LD
	.DB	$7A		; MOD = 7Ah, 1st = 7, 2nd = A
	.DB	$3A,$A2		; LD
        .DB	$03		; MOD = 03h, 1st = 0, 2nd = 3
	.DB	$C3,$1C		; JP
	.DB	$CD,$85		; CALL
        .DB	$97		; MOD = 97h, 1st = 9, 2nd = 7
	.DB	$D3,$AA		; OUT
	.DB	$79		; MOD = 79h, 1st = 7, 2nd = 9
	.DB	$DB,$9B		; IN
	.DB	$5F		; MOD = 5Fh, 1st = 5, 2nd = F
	.DB	$E3,$93		; EX
	.DB	$0E		; MOD = 0Eh, 1st = 0, 2nd = E
        .DB	$E9,$9C		; JP
	.DB	$05 		; MOD = 05h, 1st = 0, 2nd = 5
	.DB	$EB,$93		; EX
        .DB	$DF		; MOD = DFh, 1st = D, 2nd = F
	.DB	$F9,$A2		; LD
	.DB	$FF
	.DB	$C0		; MASK = C0h
	.DB	$B6		; MOD = B6h, 1st = B, 2nd = 6
	.DB	$40,$A2		; LD		
	.DB	$FF
	.DB	$F8		; MASK = F8h
	.DB	$76		; MOD = 76h, 1st = 7, 2nd = 6
	.DB	$80,$02		; ADD
	.DB	$88,$01		; ADC
        .DB	$98,$BC		; SBC
	.DB	$06		; MOD = 06h, 1st = 0, 2nd = 6
	.DB	$90,$42		; SUB
        .DB	$A0,$03		; AND
	.DB	$A8,$43		; XOR
	.DB	$B0,$25		; OR
	.DB	$B8,$8C		; CP
	.DB	$FF
	.DB	$C7		; MASK = C7h
	.DB	$0B		; MOD = 0Bh, 1st = 0, 2nd = B
	.DB	$04,$16		; INC
	.DB	$05,$8E		; DEC
        .DB	$B2		; MOD = B2h, 1st = B, 2nd = 2
	.DB	$06,$A2		; LD
	.DB	$20		; MOD = 20h, 1st = 2, 2nd = 0
	.DB	$C0,$B0		; RET
	.DB	$23		; MOD = 23h, 1st = 2, 2nd = 3
	.DB	$C2,$1C		; JP
	.DB	$C4,$85		; CALL
	.Db	$10		; MOD = 10h, 1st = 1, 2nd = 0
	.DB	$C7,$BB		; RST
	.DB	$FF
        .DB	$CF		; MASK = CFh
	.DB	$D3		; MOD = D3h, 1st = D, 2nd = 3
	.DB	$01,$A2		; LD
	.DB	$0D		; MOD = 0Dh, 1st = 0, 2nd = D
	.DB	$03,$16		; INC
	.DB	$0B,$8E		; DEC
	.DB	$FD		; MOD = FDh, 1st = F, 2nd = D
        .DB	$09,$82		; ADD
	.DB	$60		; MOD = 60h, 1st = 6, 2nd = 0
	.DB	$C1,$2B		; POP
        .DB	$C5,$AC		; PUSH
	.DB	$FF
	.DB	$E7		; MASK = E7h
	.DB	$21		; MOD = 21h, 1st = 2, 2nd = 1
        .DB	$20,$9D		; JR
	.DB	$FF
	.DB	$EF		; MASK = EFh
	.DB	$E7		; MOD = E7h, 1st = E, 2nd = 7
        .DB	$02,$A2		; LD
	.DB	$7E		; MOD = 7Eh, 1st = 7, 2nd = E
	.DB	$0A,$A2		; LD

; -------------------------------------
; ED xx
GROUP3:	.DB	$FF		; MASK = FFh
	.DB	$00		; MOD = 00h, 1st = 0, 2nd = 0
	.DB	$44,$23		; NEG
	.DB	$45,$2F		; RETN
	.DB	$4D,$2E		; RETI
        .DB	$4E,$00		; ??? IM 3 ???

	.DB	$67,$39		; RRD
	.DB	$6F,$34		; RLD

	.DB	$70,$00		; ??? IN  (C)
	.DB	$71,$00		; ??? OUT (C), 0

        .DB	$A0,$21		; LDI
	.DB	$A1,$0A		; CPI
	.DB	$A2,$1A		; INI
	.DB	$A3,$29		; OUTI
	.DB	$A8,$1F		; LDD
        .DB	$A9,$08		; CPD
	.DB	$AA,$18		; IND
	.DB	$AB,$28		; OUTD
	.DB	$B0,$20		; LDIR
	.DB	$B1,$09		; CPIR
        .DB	$B2,$19		; INIR
	.DB	$B3,$27		; OTIR
	.DB	$B8,$1E		; LDDR
	.DB	$B9,$07		; CPDR
	.DB	$BA,$17		; INDR
        .DB	$BB,$A6		; OTDR
	.DB	$FF
	.DB	$C7		; MASK = C7h
	.DB	$B8		; MOD = B8h, 1st = B, 2nd = 8
        .DB	$40,$9B		; IN
	.DB	$8B		; MOD = 8Bh, 1st = 8, 2nd = B
	.DB	$41,$AA		; OUT
        .DB	$FF
	.DB	$CF		; MASK = CFh
	.DB	$FD		; MOD = FDh, 1st = F, 2nd = D
	.DB	$42,$3C		; SBC
        .DB	$4A,$81		; ADC
	.DB	$AD		; MOD = ADh, 1st = A, 2nd = D
	.DB	$43,$A2		; LD
        .DB	$DA		; MOD = DAh, 1st = D, 2nd = A
	.DB	$4B,$A2		; LD
	.DB	$FF
	.DB	$E7		; MASK = E7h
	.DB	$40		; MOD = 40h, 1st = 4, 2nd = 0
	.DB	$46,$95		; IM
	.DB	$FF
	.DB	$F7		; MASK = F7h
	.DB	$C7		; MOD = C7h, 1st = C, 2nd = 7
	.DB	$47,$A2		; LD
	.DB	$7C		; MOD = 7Ch, 1st = 7, 2nd = C
	.DB	$57,$A2		; LD
	.DB	$FF
	.DB	$00

; -------------------------------------
MONICS:	.DB	$BF
        .DB	'A','D','C'+$80         ; ADC	01
        .DB	'A','D','D'+$80         ; ADD	02
        .DB	'A','N','D'+$80         ; AND	03
        .DB	'B','I','T'+$80         ; BIT	04
        .DB	'C','A','L','L'+$80     ; CALL	05
        .DB	'C','C','F'+$80         ; CCF	06
        .DB	'C','P','D','R'+$80     ; CPDR	07
        .DB	'C','P','D'+$80         ; CPD	08
        .DB	'C','P','I','R'+$80     ; CPIR	09
        .DB	'C','P','I'+$80         ; CPI	0A
        .DB	'C','P','L'+$80         ; CPL	0B
        .DB	'C','P'+$80             ; CP	0C
        .DB	'D','A','A'+$80         ; DAA	0D
        .DB	'D','E','C'+$80         ; DEC	0E
        .DB	'D','I'+$80             ; DI	0F
        .DB	'D','J','N','Z'+$80     ; DJNZ	10
        .DB	'E','I'+$80             ; EI	11
        .DB	'E','X','X'+$80         ; EXX	12
        .DB	'E','X'+$80             ; EX	13
        .DB	'H','A','L','T'+$80     ; HALT	14
        .DB	'I','M'+$80             ; IM	15
        .DB	'I','N','C'+$80         ; INC	16
        .DB	'I','N','D','R'+$80     ; INDR	17
        .DB	'I','N','D'+$80         ; IND	18
        .DB	'I','N','I','R'+$80     ; INIR	19
        .DB	'I','N','I'+$80         ; INI	1A
        .DB	'I','N'+$80             ; IN	1B
        .DB	'J','P'+$80             ; JP	1C
        .DB	'J','R'+$80             ; JR	1D
        .DB	'L','D','D','R'+$80     ; LDDR	1E
        .DB	'L','D','D'+$80         ; LDD	1F
        .DB	'L','D','I','R'+$80     ; LDIR	20
        .DB	'L','D','I'+$80         ; LDI	21
        .DB	'L','D'+$80             ; LD	22
        .DB	'N','E','G'+$80         ; NEG	23
        .DB	'N','O','P'+$80         ; NOP	24
        .DB	'O','R'+$80             ; OR	25
        .DB	'O','T','D','R'+$80     ; OTDR	26
        .DB	'O','T','I','R'+$80     ; OTIR	27
        .DB	'O','U','T','D'+$80     ; OUTD	28
        .DB	'O','U','T','I'+$80     ; OUTI	29
        .DB	'O','U','T'+$80         ; OUT	2A
        .DB	'P','O','P'+$80         ; POP	2B
        .DB	'P','U','S','H'+$80     ; PUSH	2C
        .DB	'R','E','S'+$80         ; RES	2D
        .DB	'R','E','T','I'+$80     ; RETI	2E
        .DB	'R','E','T','N'+$80     ; RETN	2F
        .DB	'R','E','T'+$80         ; RET	30
        .DB	'R','L','A'+$80         ; RLA	31
        .DB	'R','L','C','A'+$80     ; RLCA	32
        .DB	'R','L','C'+$80         ; RLC	33
        .DB	'R','L','D'+$80         ; RLD	34
        .DB	'R','L'+$80             ; RL	35
        .DB	'R','R','A'+$80         ; RRA	36
        .DB	'R','R','C','A'+$80     ; RRCA	37
        .DB	'R','R','C'+$80         ; RRC	38
        .DB	'R','R','D'+$80         ; RRD	39
        .DB	'R','R'+$80             ; RR	3A
        .DB	'R','S','T'+$80         ; RST	3B
        .DB	'S','B','C'+$80         ; SBC	3C
        .DB	'S','C','F'+$80         ; SCF	3D
        .DB	'S','E','T'+$80         ; SET	3E
        .DB	'S','L','A'+$80         ; SLA	3F
        .DB	'S','R','A'+$80         ; SRA	40
        .DB	'S','R','L'+$80         ; SRL	41
        .DB	'S','U','B'+$80         ; SUB	42
        .DB	'X','O','R'+$80         ; XOR	43

; -------------------------------------

OPRND2:	DJNZ    DAT8
; OP2 B = 1
RELADR:	CALL    DFETCH
        LD      C,A
        RLA
        SBC     A,A
        LD      B,A
        EX      DE,HL
        PUSH    HL
        ADD     HL,BC
        JR      DHL

DAT8:	DJNZ    DAT16
; OP2 B = 2
D8:	CALL    DFETCH
        JR      DA

; -------------------------------------
OPRND1:	DJNZ    CONDIT
; OP1 B = 1
RSTADR:	AND     $38
        JR      DA
; OP1 B = 2
CONDIT:	RRA
        RRA
        RRA
        DJNZ    BITNUM
; OP1 B = 3
        BIT     4,A
        JR      NZ, DIABS

        AND     3
        
DIABS:	AND     7
        ADD     A,$14
        JR      PS1
; --- OP1
BITNUM:	DJNZ    INTMOD
; OP1 B = 4
        AND     7

DA:	LD      C,A
        SUB     A
        JR      DAC
; --- OP2
DAT16:	DJNZ    EXAF
; OP2 B = 3        
D16:	CALL    DFETCH
        LD      C,A
        CALL    DFETCH

DAC:	EX      DE,HL
        PUSH    HL
        LD      H,A
        LD      L,C

DHL:	LD      C, $F8
        PUSH    HL
        CALL    CONVHL
        POP     HL
        LD      BC, $000A
        OR      A
        SBC     HL,BC
        POP     HL
        EX      DE,HL
        RET     C

        LD      (HL), 'H'
        INC     HL
        RET
; -----------------------
; --- OP1
INTMOD:	DJNZ    STKTOP
; OP1 B = 5
        AND     3
        ADD     A, $1C
        
PS1:	JR      PS3
; --- OP1
STKTOP:	LD      C, $13
        DEC     B
        JR      Z,PS2

REG16P:	DJNZ    COMMON
; B = 7
        RRA
        AND     3
        CP      3
        JR      NZ,RX

        DEC     A
        JR      RNX
; --- OP2
EXAF:	LD      C, $0A
        DEC     B
        JR      Z,PS2

EXDE:	INC     C
        DEC     B
        JR      Z,PS2

REG8S:	DJNZ    ACCUM
; B =
R8:	AND     7
        CP      6
        JR      NZ,PS3

        LD      (HL),'('
        INC     HL
        CALL    REGX
        LD      A,(IX + 2)
        OR      A
        JR      Z,RP

        LD      (HL),'+'
        RLCA
        RRCA
        JR      NC,DPOS

        LD      (HL),'-'
        NEG

DPOS:	INC     HL
        EX      DE,HL
        PUSH    HL
        LD      H,B
        LD      L,A
        LD      C, $FB
        CALL    CONVHL
        POP     HL
        EX      DE,HL
        JR      RP
; ---
ACCUM:	RRA
        RRA
        RRA

COMMON:	LD      C,7
        DEC     B
        JR      Z,PS2

PORTC:	DEC     C
        DJNZ    IDAT8

PS2:	LD      A,C
PS3:	JR      PS4
; ---
IDAT8:	DJNZ    IDAT16
; B =
        LD      (HL),'('
        INC     HL
        CALL    D8
        JR      RP
; ---
IDAT16:	DJNZ    REG8
; B = 
        LD      (HL),'('
        INC     HL
        CALL    D16
        JR      RP
; ---
REG8:	DEC     B
        JR      Z,R8

IPAREF:	DJNZ    REG16
; B =
        AND     9
        JR      PS4
; ---
REG16:	RRA
        DJNZ    IREG16
; B = 
R16:	AND     3
RX:	CP      2
        JR      Z,REGX

RNX:	ADD     A, $0C
        JR      PS4
; ---
IREG16:	DJNZ    REGX
; B = 
        LD      (HL),'('
        INC     HL
        CALL    R16

RP:	LD      (HL),')'
        INC     HL
        RET

REGX:	LD      A, (IX + 1)
        ADD     A, $10

PS4:	EX      DE, HL
        PUSH    HL
        LD      HL, RGSTRS
        CALL    XTRACT
        POP     HL
        EX      DE,HL
        RET

; -------------------------------------
RGSTRS:	.DB	'B'                             +$80	; 0
        .DB	'C'                             +$80	; 1
        .DB	'D'                             +$80	; 2
        .DB	'E'                             +$80	; 3
        .DB	'H'                             +$80	; 4
        .DB	'L'                             +$80	; 5
; + 06h
        .DB	'(','C',')'                     +$80
; + 07h
        .DB	'A'                             +$80	; 7
        .DB	'I'                             +$80
        .DB	'R'                             +$80
; + 0Ah
        .DB	'A','F',',','A','F','''         +$80
        .DB	'D','E',',','H','L'             +$80
; + 0Ch
        .DB	'B','C'                         +$80	; 0
        .DB	'D','E'                         +$80	; 1
        .DB	'A','F'                         +$80	; 3
        .DB	'S','P'                         +$80	; 3
; + 10h
        .DB	'H','L'                         +$80	; 2
        .DB	'I','X'                         +$80
        .DB	'I','Y'                         +$80
        .DB	'(','S','P',')'                 +$80
; + 14h
        .DB	'N','Z'                         +$80	; 0
        .DB	'Z'                             +$80	; 1
        .DB	'N','C'                         +$80	; 2
        .DB	'C'                             +$80	; 3
        .DB	'P','O'                         +$80	; 4
        .DB	'P','E'                         +$80	; 5
        .DB	'P'                             +$80	; 6
        .DB	'M'                             +$80	; 7
; + 1Ch
        .DB	'0'                             +$80
        .DB	'?'                             +$80
        .DB	'1'                             +$80
        .DB	'2'                             +$80

; -------------------------------------
CONVHL:	SUB     A

CVHL1:	PUSH    AF
        SUB     A
        LD      B, 16

CVHL2:	ADD     A, C
        JR      C, CVHL3
        SUB     C

CVHL3:	ADC     HL, HL
        RLA
        DJNZ    CVHL2

        JR      NZ, CVHL1

        CP      10
        INC     B
        JR      NC, CVHL1

CVHL4:	CP      10
        SBC     A, $69
        DAA
        LD      (DE), A
        INC     DE
        POP     AF
        JR      NZ, CVHL4

        RET

; -------------------------------------
; Copy string, A - nuber str, end of str MSB set
XTRACT:	OR      A
        JR      Z, DCOPY

DSKIP:	BIT     7, (HL)
        INC     HL
        JR      Z, DSKIP

        DEC     A
        JR      NZ, DSKIP

DCOPY:	LD      A, (HL)
        RLCA
        SRL     A
        LD      (DE), A

        INC     DE
        INC     HL
        JR      NC, DCOPY

        RET

; -------------------------------------
; Load next byte
DFETCH:	LD      A, (DE)
        INC     DE
        INC     (IX + 0)	; Bytes count
        PUSH    AF
        CALL    BYTSP
        POP     AF
        RET

ADRSP:	LD      A, D
        CALL    HexA
        LD      A, E

BYTSP:	CALL    HexA
        LD      A,$20
        JP	0008h
; -----------------------------------
;
; End of John Kerr's DIS-Z80 routine.
; 
; The next routine outputs a character.
;
; -------------------------------------
