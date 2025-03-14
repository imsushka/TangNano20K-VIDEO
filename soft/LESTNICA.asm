;
; 64x24 screen
;
;
SCR_POS		= 000Ch
Screen		= 6000h
PUT_CHR		= 0FF90h

CHR_PLAYER	= '&'
CHR_MUSHROOM	= '^'
CHR_APPLE	= '@'
CHR_STONEHOLDER	= 'U'
CHR_STONE	= 'O'
CHR_DBLSTONE	= ' '
CHR_STONEKILL	= '*'
CHR_LAD		= 'H'
CHR_JOKER	= '.'
CHR_EXIT	= '$'
CHR_BRICK	= '#'
CHR_BRIDGE	= '-'
CHR_FLOOR	= '='

MOV_UP		= 19h
MOV_DN		= 1Ah
MOV_L		= 08h
MOV_R		= 18h
MOV_INV		= 10h	; MOV_L XOR MOV_R

MAP_WIDTH	= 64

	.ORG	0100h

loc_100:
	LD	sp, 6900h

	LD	A, 01h	; 8x16, Font 1bit, Scale x2
;	LD	A, 00h	; 8x16, Font 1bit, Scale x2
	OUT	(0F7h), A

	LD	hl, 0
	LD	(SCR_POS), HL
	LD	(000Eh), HL

	LD	hl, MapOfs
	LD	(CurrentMapAddress), hl

	LD	hl, vRandom
	LD	(hl), 5Ah
	inc	hl
	LD	(hl), 34h
	inc	hl
	LD	(hl), 17h
	inc	hl
	LD	(hl), 71h

;	LD	hl, vLevel
	inc	hl
	LD	(hl), 1

;	LD	hl, vPopitok
	inc	hl
	LD	(hl), 7

	LD	hl, 0
	LD	(vScore), hl

	LD	hl,  9001h
	LD	(vSpeed), HL

	LD	de, StartMenuScr
	call	OutMap
loc_6DC:
	call	0010h
	cp	'P'
	jp	z, RunGame
	cp	'E'
	jp	z, 0E000h
	cp	'L'
	jr	nz, loc_72B
; ---------------------------------------------------------------------------
	LD	a, (StoneTable - 1)
	cp	08h
	jr	nz, loc_711

	LD	hl, 0
;	LD	(SCR_POS), HL
	LD	A, '2'
	CALL	PUT_CHR

	LD	A, 10h
	LD	(StoneTable - 1), A
	jr	loc_6DC
; ---------------------------------------------------------------------------
loc_711:
	LD	hl, 0
;	LD	(SCR_POS), HL
	LD	A, '1'
	CALL	PUT_CHR

	LD	A, 08h
	LD	(StoneTable - 1), A
	jr	loc_6DC
; ---------------------------------------------------------------------------
loc_72B:
	cp	'S'
	jr	nz, loc_6DC
; ---------------------------------------------------------------------------
	LD	A, (vSpeed + 1)
	cp	0
	jr	z, loc_74D
	sub	8
	LD	(vSpeed + 1), A

	LD	hl, 0
;	LD	(SCR_POS), HL
	INC	A
	CALL	PUT_CHR
	jr	loc_6DC
; ---------------------------------------------------------------------------
loc_74D:
	LD	A, 0A0h
	LD	(vSpeed + 1), A

	LD	hl, 0
;	LD	(SCR_POS), HL
	LD	A, '1'
	CALL	PUT_CHR
	jr	loc_6DC
; ---------------------------------------------------------------------------
loc_14A:
	LD	B, 10
loc_7A3:
	LD	HL, 1821h
	LD	DE, aYPozdrawlqSPob
	call	PrintString
	LD	HL, 7FFh
	call	Wait
	LD	DE, aY
	LD	HL, 1821h
	call	PrintString
	LD	HL, 7FFh
	call	Wait
	dec	B
	jr	nz, loc_7A3
	jp	loc_100
; ---------------------------------------------------------------------------
;
; ---------------------------------------------------------------------------
RunGame:
;	LD	A, 01h	; 8x16, Font 1bit, Scale x2
;	OUT	(0F7h), A

	LD	hl, (CurrentMapAddress)
	LD	e, (hl)
	inc	hl
	LD	d, (hl)
	inc	hl
	LD	(CurrentMapAddress), hl

	LD	a, e
	or	d
	jr	z, loc_14A
; ---------------------------------------------------------------------------
;
; ---------------------------------------------------------------------------
	call	OutMap
	call	FindPlayerAndStone
	LD	de, aY8pprigotowtes
	LD	HL, 1821h
	call	PrintString
StartRound:
	LD	HL, 0FFFFh
	call	Wait
	LD	DE, aY8p
	LD	HL, 1821h
	call	PrintString
; ---------------------------------------------------------------------------
Round:
	LD	hl, PlayerStat
	XOR	A
	LD	(hl), A
	inc	hl
	LD	(hl), A
	inc	hl
	LD	(hl), A

;	LD	(BitPlayerDead), A
	inc	hl
	LD	(hl), A
;	LD	(BitSymbolExit), A
	inc	hl
	LD	(hl), A

	LD	hl, StoneTable - 1
	LD	b, (HL)
	INC	HL
loc_19D:
	LD	(hl), A
	inc	hl
	LD	(hl), A
	inc	hl
	LD	(hl), CHR_STONEHOLDER
	inc	hl
	LD	(hl), MOV_DN
	inc	hl
	djnz	loc_19D

	LD	hl, (PS_Addr)
	LD	A, CHR_PLAYER
	LD	(hl), A
	LD	(PS_AddrTmp), hl
	CALL	ToScreen

	LD	hl, vTime
	LD	(hl), 40h

GameLoop:
	LD	hl, byte_816
	LD	(hl), 0Fh

ShortLoop:
	LD	hl, byte_816
	LD	a, (hl)
	dec	a
	LD	(hl), a
	jr	z, DecTime

	call	Wait30
	call	Keyboard
	call	StoneStep
	call	PlayerStep
	call	OutScreenVars

	LD	a, (BitSymbolExit)
	cp	0FFh
	jr	z, IncLevel

	LD	a, (vTime)
	cp	0
	jr	z, loc_20A

	LD	a, (BitPlayerDead)
	cp	0FFh
	jr	nz, ShortLoop

loc_20A:
	LD	a, (PlayerStat)
	cp	CHR_STONE
	jr	z, loc_21C

	LD	hl, (PS_AddrTmp)
	LD	(hl), a
	CALL	ToScreen

loc_21C:
	LD	ix,  StoneTable
	LD	b, (IX - 1)
loc_222:
	LD	a, (ix + 2)
	cp	CHR_PLAYER
	jr	z, loc_23B
	cp	CHR_STONE
	jr	z, loc_23B
	cp	CHR_DBLSTONE
	jr	z, loc_23B
	LD	l, (ix + 0)
	LD	h, (ix + 1)
	LD	(hl), a
	CALL	ToScreen
loc_23B:
	inc	ix
	inc	ix
	inc	ix
	inc	ix
	djnz	loc_222

	LD	hl, vPopitok
	LD	a, (hl)
	dec	a
	LD	(hl), a
	jp	nz, Round
	jp	loc_100
; ---------------------------------------------------------------------------
DecTime:
	LD	hl, vTime
	LD	a, (hl)
	dec	a
	LD	(hl), a
;	and	0Fh
;	jp	nz, GameLoop
	jr	GameLoop
; ---------------------------------------------------------------------------
IncLevel:
	LD	hl, vTime
	LD	c, (hl)
	LD	(hl), 0
	RLC	C
	CALL	IncScore
	LD	hl, vLevel
	LD	a, (hl)
	inc	a
	LD	(hl), a
	jp	RunGame

; ---------------------------------------------------------------------------
IncScore:
	LD	HL, (vScore)
	LD	A, L
	ADD	A, C
	LD	L, A
	JR	NC, loc_313
	INC	H
	LD	A, (vPopitok)
	INC	A
	LD	(vPopitok), A
loc_313:
	LD	(vScore), HL
	RET
; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================
; In/Out
;	HL - Address screen position
;	D  - Moves
;	E  - Symbol

PlayerStep:
	push	af
	push	bc
	push	de
	push	hl
	LD	hl, PlayerStat
	LD	a, (hl)
	cp	CHR_APPLE	; Apple !!!
	jp	z, loc_319
; ---------------------------------------------------------------------------
	cp	CHR_MUSHROOM	; Mushroom !!!
	jr	nz, loc_32B
PlayerDead:
	LD	hl, BitPlayerDead
	LD	(hl), 0FFh
	jr	loc_314
; ---------------------------------------------------------------------------
loc_32B:
	cp	CHR_STONE
	jr	z, PlayerDead
	cp	CHR_LAD
	jr	nz, loc_348

	LD	hl, KeyPressed
	LD	a, (hl)
	and	80h
;	cp	0
	jr	z, loc_348

	XOR	A
	LD	(hl), A		; KeyPressed
	inc	hl
	LD	(hl), A		; KeyPressed+1
	jr	loc_314
; ---------------------------------------------------------------------------
loc_348:
	cp	CHR_JOKER
	jr	nz, loc_391

	LD	hl, KeyPressed
	call	Random
	sub	3Fh
	jp	m, loc_35D
	LD	(hl), MOV_L	; to left
	jr	loc_35F
; ---------------------------------------------------------------------------
loc_35D:
	LD	(hl), MOV_R	; to right
loc_35F:
	call	Random
	sub	3Fh
	jp	m, loc_371

	LD	a, (hl)		;
	OR	80h		; add jump flag
	LD	(hl), a		;
	inc	hl
	LD	(hl), 2		; jump 2 
	jr	loc_314
; ---------------------------------------------------------------------------
loc_371:
	inc	hl
	LD	(hl), 0		; no jump
	jr	loc_314
; ---------------------------------------------------------------------------
loc_391:
	cp	CHR_EXIT
	jr	nz, loc_377

	LD	hl, BitSymbolExit
	LD	(hl), 0FFh
	jr	loc_314
; ---------------------------------------------------------------------------
; ÂÒÎË ÔÓ‰ Ë„ÓÍÓÏ ÔÓıÓ‰ËÚ Í‡ÏÂÌ¸ ÚÓ ‰Ó·‡‚ËÚ¸ Ò˜ÂÚ
;
loc_377:
	LD	c, 3
	LD	hl, (PS_AddrTmp)
loc_37C:
	call	IncY_HL
	LD	a, (hl)
	cp	CHR_STONE
	jr	z, loc_37D
	dec	c
	LD	a, c
	cp	1
	jr	nz, loc_37C

	jr	loc_314

loc_319:
	XOR	A
	LD	(hl), A
	CALL	ToScreen

	LD	c, 45
loc_37D:
	RLC	C
	CALL	IncScore
loc_314:
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================
; In/Out
;	none

Keyboard:
	push	af
	push	hl
	push	de
	push	bc
	call	0018h
	jr	z, loc_417
	LD	hl, KeyPressed
	call	0010h
	cp	'P'
	jr	nz, KeyLeft

KeyPause:
	call	0010h
	cp	0Dh
	jr	nz, KeyPause
	jr	loc_417
; ---------------------------------------------------------------------------

KeyLeft:
	cp	'a'
	jr	nz, KeyRight

	LD	a, (hl)
	and	80h
	OR	MOV_L
	jr	loc_416
; ---------------------------------------------------------------------------

KeyRight:
	cp	'd'
	jr	nz, KeyUp

	LD	a, (hl)
	and	80h
	OR	MOV_R
	jr	loc_416
; ---------------------------------------------------------------------------

KeyUp:
	cp	'w'
	jr	nz, KeyDown

	LD	a, (hl)
	and	80h
	OR	MOV_UP
	jr	loc_416
; ---------------------------------------------------------------------------

KeyDown:
	cp	's'
	jr	nz, KeySpace

	LD	a, (hl)
	and	80h
	OR	MOV_DN
	jr	loc_416
; ---------------------------------------------------------------------------

KeySpace:
	cp	20h ; ' '
	jr	nz, KeyNone

	LD	a, (hl)
	OR	80h
	jr	loc_416
; ---------------------------------------------------------------------------

KeyNone:
	LD	a, (hl)
	and	80h

; ---------------------------------------------------------------------------
; ---------------------------------------------------------------------------
; Move player
;
loc_416:
	LD	(hl), a
loc_417:
	LD	a, (KeyPressed + 1)
	and	7Fh
	jr	nz, loc_46E
; no jump
	LD	hl, (PS_AddrTmp)
	call	IncY_HL

	LD	a, (hl)
	cp	CHR_FLOOR
	jr	z, loc_46E
	cp	CHR_BRICK
	jr	z, loc_46E
	cp	CHR_BRIDGE
	jr	nz, loc_444

	XOR	A
	LD	(hl), A
	CALL	ToScreen
	jr	loc_46E
; ---------------------------------------------------------------------------
loc_444:
	LD	a, (PlayerStat)
	cp	CHR_LAD
	jp	nz, loc_513

; ---------------------------------------------------------------------------
loc_46E:
	LD	hl, (PS_AddrTmp)
	ex	de, hl

	LD	hl, KeyPressed
	LD	a, (hl)
	and	80h
	jr	z, loc_4AA
	                                                                                              	
	inc	hl
	LD	a, (hl)
	and	7Fh
	jr	nz, loc_486
	LD	a, 2	; 2-(0,0), 4-(+1,+1), 8-(+2,+2), 10-(+2,+3), 20-(+2,+4), 40-(+1,+5), 80-(0,+6)
loc_486:
	RLA
	LD	(hl), a
	DEC	HL

	push	af
	and	0Ch
	jr	z, loc_492
	call	DecY_DE
loc_492:
	pop	af

	push	af
	and	0C0h
	jr	z, loc_49D
	call	IncY_DE
loc_49D:
	pop	af
	cp	80h
	jr	nz, loc_4AA

	LD	a, (hl)
	and	7Fh
	LD	(hl), a
loc_4AA:
	LD	a, (hl)
	and	7Fh
	cp	MOV_L
	jr	nz, loc_4B9

	DEC	DE
	LD	A, MAP_WIDTH-1
	AND	E
	CP	MAP_WIDTH-1
	JP	NZ, loc_4EF
	INC	DE
	JR	loc_4EF
; ---------------------------------------------------------------------------
loc_4B9:
	cp	MOV_R
	jr	nz, loc_4C2

	INC	DE
	LD	A, MAP_WIDTH-1
	AND	E
	JR	NZ, loc_4EF
	DEC	DE
	JR	loc_4EF
; ---------------------------------------------------------------------------
loc_4C2:
	cp	MOV_DN
	jr	nz, loc_4D7

	LD	a, (PlayerStat)
	cp	CHR_LAD
	jr	nz, loc_4EF

	call	IncY_DE
	jr	loc_4EF
; ---------------------------------------------------------------------------
loc_4D7:
	cp	MOV_UP
	jr	nz, loc_4EF

	LD	a, (PlayerStat)
	cp	CHR_LAD
	jr	nz, loc_4EF

	call	DecY_DE

loc_4EF:
	ex	de, hl
	LD	a, (hl)
	cp	CHR_FLOOR
	jr	z, loc_4F6
	cp	CHR_BRICK
	jr	z, loc_4F6
	cp	CHR_BRIDGE
	jr	nz, loc_513

loc_4F6:
	LD	hl, 0000h
	LD	(KeyPressed), HL
	jr	loc_514

loc_513:
	ex	de, hl
	LD	hl, (PS_AddrTmp)
	LD	a, (PlayerStat)
	LD	(hl), a
	CALL	ToScreen

	ex	de, hl
	LD	a, (hl)
	LD	(PlayerStat), a

	LD	A, CHR_PLAYER
	LD	(hl), A
	LD	(PS_AddrTmp), hl
	CALL	ToScreen
loc_514:
	pop	bc
	pop	de
	pop	hl
	pop	af
	ret

; =============== S U B	R O U T	I N E =======================================

IncY_DE:
	push	af
	LD	a, e
	add	a, MAP_WIDTH
	LD	e, a
	jr	nc, loc_534
	inc	d
loc_534:
	pop	af
	ret

IncY_HL:
	push	af
	LD	a, l
	add	a, MAP_WIDTH
	LD	l, a
	jr	nc, loc_535
	inc	h
loc_535:
	pop	af
	ret

; =============== S U B	R O U T	I N E =======================================

DecY_DE:
	push	af
	LD	a, e
	sub	MAP_WIDTH
	LD	e, a
	jr	nc, loc_542
	dec	d
loc_542:
	pop	af
	ret

DecY_HL:
	push	af
	LD	a, l
	sub	MAP_WIDTH
	LD	l, a
	jr	nc, loc_543
	dec	h
loc_543:
	pop	af
	ret

; =============== S U B	R O U T	I N E =======================================

Random:
	push	hl
	push	de
	push	bc
	push	af
	LD	hl, vRandom
	LD	d, (hl)
	inc	hl
	LD	e, (hl)
	LD	hl, (vRandom+2)
	add	hl, hl
	LD	a, e
	rla
	LD	e, a
	LD	a, d
	rla
	LD	d, a
	xor	l
	jp	p, loc_55F
	inc	hl

loc_55F:
	LD	(vRandom+2), hl
	LD	hl, vRandom
	LD	(hl), d
	inc	hl
	LD	(hl), e
	LD	b, a
	pop	af
	LD	a, b
	pop	bc
	pop	de
	pop	hl
	ret

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================
; In/Out
;	none

StoneStep:
	push	hl
	push	de
	push	bc
	push	af

	LD	ix,  StoneTable
	LD	b, (IX - 1)
loc_61D:
	LD	a, (ix + 1)	; AddrH
	OR	A
	jr	z, SS_AddNew

	LD	l, (ix + 0)	; AddrL
	LD	h, (ix + 1)	; AddrH
	LD	e, (ix + 2)	; Char
	LD	d, (ix + 3)	; Moves

; HL - Moves and Char
; DE - Addr stone screen
	call	DrawStone
	call	DrawStone2

	LD	(ix + 0), l	; AddrL
	LD	(ix + 1), h	; AddrH
	LD	(ix + 2), e	; Char
	LD	(ix + 3), d	; Moves
	jr	SS_Next
; ---------------------------------------------------------------------------
SS_AddNew:
	call	Random
	sub	3Fh
	jp	p, SS_Next

	LD	a, (StoneHolderCnt)
	LD	C, A

	LD	hl, (StoneHolderAddress1)
	DEC	C
	JR	Z, loc_6B6

	call	Random
	sub	3Fh
	jp	m, loc_6B6

	LD	hl, (StoneHolderAddress2)
	DEC	C
	JR	Z, loc_6B6

	call	Random
	sub	3Fh
	jp	m, loc_6B6

	LD	hl, (StoneHolderAddress3)
	DEC	C
	JR	Z, loc_6B6

	call	Random
	sub	3Fh
	jp	m, loc_6B6

	LD	hl, (StoneHolderAddress4)
loc_6B6:
	LD	a, (hl)
	cp	CHR_STONEHOLDER
	jr	nz, SS_Next

	LD	(ix + 0), l	; AddrL
	LD	(ix + 1), h	; AddrH
; ---------------------------------------------------------------------------
SS_Next:
	inc	ix
	inc	ix
	inc	ix
	inc	ix

	djnz	loc_61D

	pop	af
	pop	bc
	pop	de
	pop	hl
	ret
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================
; In/Out
;	HL - Address screen position
;	D  - Moves
;	E  - Symbol

DrawStone:
	LD	(TmpAddress), hl
	ex	de, hl
	LD	(TmpMove), hl
	ex	de, hl

	call	IncY_HL

	LD	a, (hl)
	cp	CHR_FLOOR
	jr	z, DS_LR
	cp	CHR_BRICK
	jr	z, DS_LR
	cp	CHR_BRIDGE
	jr	z, DS_LR
	cp	CHR_LAD
	jr	nz, DS_DN

	LD	a, d
	cp	MOV_DN
	jr	z, DS_DN

	call	Random
	sub	7Fh
	jp	m, DS_LR

DS_DN:
	LD	D, MOV_DN
	jr	DS_Exit
; ---------------------------------------------------------------------------
; Move Left / Right
DS_LR:
	LD	a, d
	cp	MOV_DN
	jr	nz, loc_5DA

	call	Random
	sub	7Fh
	jp	m, loc_5D7

	LD	d, MOV_L
	jr	loc_5DA
; ---------------------------------------------------------------------------
loc_5D7:
	LD	d, MOV_R

loc_5DA:
	LD	hl, (TmpAddress)
	LD	a, d
	cp	MOV_L
	jr	z, loc_5E7

	INC	HL
	LD	A, MAP_WIDTH-1
	AND	L
	JR	NZ, loc_5E8
	DEC	HL
	JR	loc_5EE
; ---------------------------------------------------------------------------
loc_5E7:
	DEC	HL
	LD	A, MAP_WIDTH-1
	AND	L
	CP	MAP_WIDTH-1
	JR	NZ, loc_5E8
	INC	HL
	JR	loc_5EE
loc_5E8:

	LD	a, (hl)
	cp	CHR_BRICK
	jr	nz, loc_5F5
loc_5EE:
	LD	a, d
	xor	MOV_INV
	LD	d, a
	jr	loc_5DA
; ---------------------------------------------------------------------------
loc_5F5:
	cp	CHR_LAD
	jr	nz, DS_Exit

	call	Random
	sub	7Fh
	jp	m, loc_5EE

; ---------------------------------------------------------------------------
; 
DS_Exit:
	PUSH	HL
	LD	hl, (TmpAddress)

	LD	a, e
	cp	CHR_DBLSTONE
	jr	z, loc_5B6
	LD	(hl), e
	CALL	ToScreen

loc_5B6:
	POP	HL

	LD	e, (hl)
	LD	A, CHR_STONE
	LD	(hl), A
	CALL	ToScreen
	ret
; ---------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================
; In/Out
;	HL - Address screen position
;	D  - Moves
;	E  - Symbol

DrawStone2:
	LD	a, e
	cp	CHR_PLAYER
	jr	nz, loc_668

	LD	A, 0FFh
	LD	(BitPlayerDead), A
	jr	DS2_Exit
; ---------------------------------------------------------------------------
loc_668:
	cp	CHR_DBLSTONE
	jr	nz, loc_674

	LD	e, 0
	jr	DS2_Exit
; ---------------------------------------------------------------------------
loc_674:
	cp	CHR_STONE
	jr	nz, loc_688

	LD	e, CHR_DBLSTONE
	jr	DS2_Exit
; ---------------------------------------------------------------------------
loc_688:
	cp	CHR_STONEKILL
	jr	nz, DS2_Exit

	LD	d, MOV_DN
	LD	e, CHR_STONEHOLDER
	LD	A, CHR_STONEKILL
	LD	(hl), A
	CALL	ToScreen
	LD	hl, 0
; ---------------------------------------------------------------------------
DS2_Exit:
	ret

; ---------------------------------------------------------------------------
aYPozdrawlqSPob:.DB "œŒ«ƒ–¿¬Àﬂ≈Ã — œŒ¡≈ƒŒ…!",0
aY:		.DB "                      ",0

; =============== S U B	R O U T	I N E =======================================
OutScreenVars:				; CODE XREF: Round+55p
	LD	a, (vLevel)
	LD	HL, 1808h
	call	PrintHex

	LD	a, (vPopitok)
	LD	HL, 1810h
	call	PrintHex

	LD	a, (vScore+1)
	LD	HL, 1818h
	call	PrintHex

	LD	a, (vScore)
	LD	HL, 181Ah
	call	PrintHex

	LD	a, (vTime)
	LD	HL, 1828h
	call	PrintHex
	ret

; ---------------------------------------------------------------------------
; =============== S U B	R O U T	I N E =======================================
OutMap:
	LD	hl, Screen
OM_0:
	LD	a, (de)
	INC	DE
	cp	0FFh
	ret	z
	cp	80h
	jr	c, OM_
	AND	7Fh
	LD	B, A
	LD	A, (DE)
	LD	C, A
OM_1:
	LD	A, C
	LD	(hl), A
	CALL	ToScreen
	inc	hl
	DJNZ	OM_1
	INC	DE
	jr	OM_0

OM_:
	LD	B, A
OM_2:
	LD	A, (DE)
	LD	(hl), a
	CALL	ToScreen
	inc	hl
	inc	de
	DJNZ	OM_2
	jr	OM_0

; =============== S U B	R O U T	I N E =======================================

Wait30:
	LD	HL, (vSpeed)
Wait:
	dec	hl
	LD	A, H
	OR	L
	jr	nz, Wait
	ret

; =============== S U B	R O U T	I N E =======================================

FindPlayerAndStone:
	LD	b, CHR_PLAYER
	LD	hl, Screen
	call	FindScreen
	LD	(PS_Addr), hl

	LD	C, 1
	LD	b, CHR_STONEHOLDER
	LD	hl, Screen
	call	FindScreen
	LD	(StoneHolderAddress1), hl
	inc	hl

	call	FindScreen
	cp	0FFh
	jr	Z, FP_
	LD	(StoneHolderAddress2), hl
	inc	hl
	INC	C

	call	FindScreen
	cp	0FFh
	jr	Z, FP_
	LD	(StoneHolderAddress3), hl
	inc	hl
	INC	C

	call	FindScreen
	cp	0FFh
	jr	Z, FP_
	LD	(StoneHolderAddress4), hl
	INC	C

FP_:
	LD	A, C
	LD	(StoneHolderCnt), A
	ret

; =============== S U B	R O U T	I N E =======================================

FindScreen:
	LD	a, (hl)
	cp	b
	ret	z
	cp	0FFh
	ret	z
	inc	hl
	jr	FindScreen

; ---------------------------------------------------------------------------
PrintString:
;	LD	(SCR_POS), HL
	LD	A, (DE)
	OR	A
	RET	Z
	CALL	PUT_CHR
	INC	DE
	INC	HL
	Jr	PrintString

PrintHex:				; Display A
;	LD	(SCR_POS), HL
	PUSH	AF		; Protect AF
	RRA			; Move MSN to LSN
	RRA
	RRA
	RRA
	CALL	Hex		; High 4 bits
	POP	AF
Hex:
	AND	0FH		; Low 4 bits
	ADD	A, '0'		; ASCII bias
	CP	$3A		; Digit 0-9
	JR	C, H_		; Display digit, tail call exit
	ADD	A, 7		; Alpha digit A-F
H_:
	CALL	PUT_CHR
;	LD	A, (SCR_POS)
;	INC	A
;	LD	(SCR_POS), A
	RET
; ---------------------------------------------------------------------------
ToScreen:
        PUSH	BC
;        PUSH	DE
        PUSH	HL

        PUSH	AF

	XOR	A
	LD	BC, Screen
	SBC	HL, BC
	LD	A, L
	AND	3Fh
	LD	C, A
	LD	A, L
	AND	0C0h
	LD	L, A
	ADD	HL, HL	
	ADD	HL, HL	
	LD	L, C
;	ADD	HL, HL	

;	LD	(SCR_POS), HL
	POP	AF
	CALL	PUT_CHR

	POP	HL
;	POP	DE
	POP	BC
	RET
; ---------------------------------------------------------------------------
PlayerStat:
	.DB	0
KeyPressed:
	.DW	0
BitPlayerDead:
	.DB	0
BitSymbolExit:
	.DB	0
vRandom:
	.DW	0
	.DW	0
vLevel:
	.DB	0
vPopitok:
	.DB	0
vScore:
	.DW	0
vTime:
	.DB	0
byte_816:
	.DB	0

TmpAddress:
	.DW	0
TmpMove:
	.DW	0
PS_AddrTmp:
	.DW	0
PS_Addr:
	.DW	0
StoneHolderCnt:
	.DB	0
StoneHolderAddress1:
	.DW	0
StoneHolderAddress2:
	.DW	0
StoneHolderAddress3:
	.DW	0
StoneHolderAddress4:
	.DW	0
CurrentMapAddress:
	.DW	MapOfs
vSpeed:
	.DW	0A001h
vSlojnost:
	.DB	24
StoneTable:
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0

	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0

	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0
	.DW	0, 0

	.DW	0FFFFh

MapOfs:
	.DW Map0
	.DW Map1
        .DW Map2
	.DW Map1
	.DW Map2
	.DW Map3
	.DW Map1
	.DW Map2
	.DW Map3
	.DW Map4
	.DW Map1
	.DW Map2
	.DW Map3
	.DW Map4
	.DW Map5
	.DW Map1
	.DW Map2
	.DW Map3
	.DW Map4
	.DW Map5
	.DW Map6
	.DW Map1
	.DW Map2
	.DW Map3
	.DW Map4
	.DW Map5
	.DW Map6
	.DW Map7
	.DW	0

aY8pprigotowtes:.DB "œ–»√Œ“Œ¬“≈—‹!",0
aY8p:		.DB "             ",0

StartMenuScr:
;			   1         2	       3         4         5         6
;		 0123456789012345678901234567890123456789012345678901234567890123
;		------------------------------------------------------------------
;	.DB	"                                                                "
;	.DB	"    OOO OOOO  OOO  OOOOO O   O O   O O   O     OOO        O     "
;	.DB	"   O  O O    O   O   O   O   O O   O O   O    O  O       OO     "
;	.DB	"   O  O OOO  O       O   OOOOO O  OO O   O   O   O        O     "
;	.DB	"   O  O O    O       O   O   O O O O O   O   OOOOO  OOO   O     "
;	.DB	"   O  O O    O   O   O   O   O OO  O O   O   O   O        O     "
;	.DB	"  OO  O OOOO  OOO    O   O   O O   O OOOOOOO O   O       OOO    "
;	.DB	"                                         O                      "
;	.DB	"                                                                "
;	.DB	"                              ¬≈–—»ﬁ ƒÀﬂ œ›¬Ã '–¿ƒ»Œ-86– '      "
;	.DB	"                              –¿«–¿¡Œ“¿À —»ÃŒÕŒ¬ ﬁ.¡.           "
;	.DB	"                                                                "
;	.DB	"  ===========================================================   "
;	.DB	"                                  # $ - ¬€’Œƒ »« ”–Œ¬Õﬂ         "
;	.DB	"  P - Õ¿◊¿ÀŒ »√–€         ]<      # ^ - Œ◊≈Õ‹ œÀŒ’¿ﬂ ÿ“” ¿      "
;	.DB	"  L - ”—“¿ÕŒ¬ ¿ —ÀŒ∆ÕŒ—“» ]< ¬¿ÿ  # . - Œ◊≈Õ‹ ’»“–¿ﬂ ÿ“” ¿      "
;	.DB	"  S - ”—“¿ÕŒ¬ ¿ — Œ–Œ—“»  ]< ’Œƒ  # Œ - ”¬≈—»—“€… ¡”À€∆Õ»       "
;	.DB	"  ≈ - ¬€’Œƒ ¬ ÃŒÕ»“Œ–     ]<      # @ - œ–»ﬂ“Õ¿ﬂ ¬≈Ÿ‹           "
;	.DB	"                                  # Õ - À≈—“Õ»÷¿                "
;	.DB	"      —ÀŒ∆ÕŒ—“‹ - 1               # & - ¿ ›“Œ - À»◊ÕŒ ¬€        "
;	.DB	"                                  #   ” œ – ¿ ¬ À ≈ Õ » ≈ :     "
;	.DB	"      — Œ–Œ—“‹  - 1               # ¬œ–¿¬Œ, ¬À≈¬Œ, ¬¬≈–’ »      "
;	.DB	"                                  # ¬Õ»« œŒ À≈—“Õ»÷≈ -  À¿¬»-   "
;	.DB	"                                  # ÿ¿Ã» ”œ–¿¬À≈Õ»ﬂ  ”–—Œ–ŒÃ,   "
;	.DB	"                                  # œ–€∆Œ  - œ–Œ¡≈À.            "

	.DB	$C0, " ", 
	.DB	$84, " ", $83, "O", $01, " ", $84, "O", $82, " ", $83, "O", $82, " ", $85, "O", $02, " O", $83, " ", $03, "O O", $83, " ", $03, "O O", $83, " ", $01, "O", $85, " ", $83, "O", $88, " ", $01, "O", $85, " ", 
	.DB	$83, " ", $01, "O", $82, " ", $03, "O O", $84, " ", $01, "O", $83, " ", $01, "O", $83, " ", $01, "O", $83, " ", $01, "O", $83, " ", $03, "O O", $83, " ", $03, "O O", $83, " ", $01, "O", $84, " ", $01, "O", $82, " ", $01, "O", $87, " ", $82, "O", $85, " ", 
	.DB	$83, " ", $01, "O", $82, " ", $02, "O ", $83, "O", $82, " ", $01, "O", $87, " ", $01, "O", $83, " ", $85, "O", $02, " O", $82, " ", $82, "O", $02, " O", $83, " ", $01, "O", $83, " ", $01, "O", $83, " ", $01, "O", $88, " ", $01, "O", $85, " ", 
	.DB	$83, " ", $01, "O", $82, " ", $03, "O O", $84, " ", $01, "O", $87, " ", $01, "O", $83, " ", $01, "O", $83, " ", $09, "O O O O O", $83, " ", $01, "O", $83, " ", $85, "O", $82, " ", $83, "O", $83, " ", $01, "O", $85, " ", 
	.DB	$83, " ", $01, "O", $82, " ", $03, "O O", $84, " ", $01, "O", $83, " ", $01, "O", $83, " ", $01, "O", $83, " ", $01, "O", $83, " ", $02, "O ", $82, "O", $82, " ", $03, "O O", $83, " ", $01, "O", $83, " ", $01, "O", $83, " ", $01, "O", $88, " ", $01, "O", $85, " ", 
	.DB	$82, " ", $82, "O", $82, " ", $02, "O ", $84, "O", $82, " ", $83, "O", $84, " ", $01, "O", $83, " ", $01, "O", $83, " ", $03, "O O", $83, " ", $02, "O ", $87, "O", $02, " O", $83, " ", $01, "O", $87, " ", $83, "O", $84, " ", 
	.DB	$A9, " ", $01, "O", $96, " ", 
	.DB	$C0, " ", 
	.DB	$9E, " ", $1C, "¬≈–—»ﬁ ƒÀﬂ œ›¬Ã '–¿ƒ»Œ-86– '", $86, " ", 
	.DB	$9E, " ", $17, "–¿«–¿¡Œ“¿À —»ÃŒÕŒ¬ ﬁ.¡.", $8B, " ", 
	.DB	$C0, " ", 
	.DB	$82, " ", $BB, "=", $83, " ", 
	.DB	$A2, " ", $15, "# $ - ¬€’Œƒ »« ”–Œ¬Õﬂ", $89, " ", 
	.DB	$82, " ", $0F, "P - Õ¿◊¿ÀŒ »√–€", $89, " ", $02, "]<", $86, " ", $18, "# ^ - Œ◊≈Õ‹ œÀŒ’¿ﬂ ÿ“” ¿", $86, " ", 
	.DB	$82, " ", $1E, "L - ”—“¿ÕŒ¬ ¿ —ÀŒ∆ÕŒ—“» ]< ¬¿ÿ", $82, " ", $18, "# . - Œ◊≈Õ‹ ’»“–¿ﬂ ÿ“” ¿", $86, " ", 
	.DB	$82, " ", $16, "S - ”—“¿ÕŒ¬ ¿ — Œ–Œ—“»", $82, " ", $06, "]< ’Œƒ", $82, " ", $18, "# Œ - ”¬≈—»—“€… ¡”À€∆Õ» ", $86, " ", 
	.DB	$82, " ", $13, "≈ - ¬€’Œƒ ¬ ÃŒÕ»“Œ–", $85, " ", $02, "]<", $86, " ", $13, "# @ - œ–»ﬂ“Õ¿ﬂ ¬≈Ÿ‹", $8B, " ", 
	.DB	$A2, " ", $0E, "# Õ - À≈—“Õ»÷¿", $90, " ", 
	.DB	$86, " ", $0D, "—ÀŒ∆ÕŒ—“‹ - 1", $8F, " ", $16, "# & - ¿ ›“Œ - À»◊ÕŒ ¬€", $88, " ", 
	.DB	$A2, " ", $01, "#", $83, " ", $15, "” œ – ¿ ¬ À ≈ Õ » ≈ :", $85, " ", 
	.DB	$86, " ", $08, "— Œ–Œ—“‹", $82, " ", $03, "- 1", $8F, " ", $11, "# ¬œ–¿¬Œ, ¬À≈¬Œ, ", $82, "¬", $05, "≈–’ »", $86, " ", 
	.DB	$A2, " ", $1B, "# ¬Õ»« œŒ À≈—“Õ»÷≈ -  À¿¬»-", $83, " ", 
	.DB	$A2, " ", $1B, "# ÿ¿Ã» ”œ–¿¬À≈Õ»ﬂ  ”–—Œ–ŒÃ,", $83, " ", 
	.DB	0FFh
Map0:
;	.DB	"                                      U         $               "1
;	.DB	"                                                H               "2
;	.DB	"           H                                    H               "3
;	.DB	"      =====H============================================        "4
;	.DB	"           H                                                H   "5
;	.DB	"           H                                                H   "6
;	.DB	"           H        H                                       H   "7
;	.DB	"===========H========H=============   ==========================="8
;	.DB	"           @        H                                |      |   "9
;	.DB	"                                                    ›“Œ œ–Œ—“Œ  "0
;	.DB	"                                            H                   "1
;	.DB	"        =====================  =============H==                 "2
;	.DB	"                                            H                   "3
;	.DB	"                                            H                   "4
;	.DB	"         H                                  H                   "5
;	.DB	"     ====H=======H=======  =======================              "6
;	.DB	"         H                                                      "7
;	.DB	"         H                                                      "8
;	.DB	"         H                                    H                 "9
;	.DB	"================== ================== ========H==========       "0  
;	.DB	"                                              H                 "1
;	.DB	"                                              H                 "2
;	.DB	"#*  &                                         H               *#"3
;	.DB	"================================================================"4

	.DB	$A6, " ", $01, "U", $89, " ", $01, "$", $8F, " ", 
	.DB	$B0, " ", $01, "H", $8E, " ", $01, "#", 
	.DB	$01, " ", $8A, " ", $01, "H", $A4, " ", $01, "H", $8F, " "
	.DB	$01, " ", $85, " ", $85, "=", $01, "H", $AC, "=", $88, " "
	.DB	$01, " ", $8A, " ", $01, "H", $B0, " ", $01, "H", $83, " "
	.DB	$01, " ", $8A, " ", $01, "H", $B0, " ", $01, "H", $83, " "
	.DB	$01, " ", $8A, " ", $01, "H", $88, " ", $01, "H", $A7, " ", $01, "H", $83, " "
	.DB	$8B, "=", $01, "H", $88, "=", $01, "H", $8D, "=", $83, " ", $9B, "=", 
	.DB	$8B, " ", $01, "@", $88, " ", $01, "H", $A0, " ", $01, "|", $86, " ", $01, "|", $83, " ", 
	.DB	$B4, " ", $0A, "›“Œ œ–Œ—“Œ", $82, " ", 
	.DB	$AC, " ", $01, "H", $93, " ", 
	.DB	$88, " ", $95, "=", $82, " ", $8D, "=", $01, "H", $82, "=", $91, " ", 
	.DB	$AC, " ", $01, "H", $93, " ", 
	.DB	$AC, " ", $01, "H", $93, " ", 
	.DB	$89, " ", $01, "H", $A2, " ", $01, "H", $93, " ", 
	.DB	$85, " ", $84, "=", $01, "H", $87, "=", $01, "H", $87, "=", $82, " ", $97, "=", $8E, " ", 
	.DB	$01, " ", $88, " ", $01, "H", $B6, " ", 
	.DB	$01, " ", $88, " ", $01, "H", $B6, " ", 
	.DB	$01, " ", $88, " ", $01, "H", $A4, " ", $01, "H", $91, " "
	.DB	$92, "=", $01, " ", $92, "=", $01, " ", $88, "=", $01, "H", $8A, "=", $87, " "
	.DB	$01, " ", $AD, " ", $01, "H", $91, " "
	.DB	$01, "&", $AD, " ", $01, "H", $91, " "
	.DB	$02, "#*", $83, " ", $A9, " ", $01, "H", $8F, " ", $02, "*#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map1:
;	.DB	"                                                                "
;	.DB	"                        “ » ’ Œ ≈   Ã ≈ — “ Œ                   "
;	.DB	"                           U         U         $                "
;	.DB	"                                               H                "
;	.DB	"           H               #       .....       H                "
;	.DB	"         ==H=================H===================               "
;	.DB	"           H                 H                                  "
;	.DB	"           H                                                    "
;	.DB	"           H        H     .                     H               "
;	.DB	"       ====H========H===H==    =================H==             "
;	.DB	"           @        H                           H               "
;	.DB	"                          =-H-=======           H               "
;	.DB	"           H                                    H               "
;	.DB	"          =H============   ============= =========              "
;	.DB	"           H                                                    "
;	.DB	"           H                                                    "
;	.DB	"           H             ^                        H             "
;	.DB	"       =============  ==============    ==========H=====        "
;	.DB	"#                                                 H             "
;	.DB	"#                                                 H             "
;	.DB	"#&               ==H==H====== =====H====H=========H            #"
;	.DB	"#=             ==                                              #"
;	.DB	"#*.           ^                                   ^           *#"
;	.DB	"================================================================"

	.DB	$C0, " ", 
	.DB	$98, " ", $09, "“ » ’ Œ ≈", $83, " ", $09, "Ã ≈ — “ Œ", $93, " ", 
	.DB	$9B, " ", $01, "U", $89, " ", $01, "U", $89, " ", $01, "$", $90, " ", 
	.DB	$AF, " ", $01, "H", $90, " ", 
	.DB	$8B, " ", $01, "H", $8F, " ", $01, "#", $87, " ", $85, ".", $87, " ", $01, "H", $90, " ", 
	.DB	$89, " ", $82, "=", $01, "H", $91, "=", $01, "H", $93, "=", $8F, " ", 
	.DB	$8B, " ", $01, "H", $91, " ", $01, "H", $A2, " ", 
	.DB	$8B, " ", $01, "H", $B4, " ", 
	.DB	$8B, " ", $01, "H", $88, " ", $01, "H", $85, " ", $01, ".", $95, " ", $01, "H", $8F, " ", 
	.DB	$87, " ", $84, "=", $01, "H", $88, "=", $01, "H", $83, "=", $01, "H", $82, "=", $84, " ", $91, "=", $01, "H", $82, "=", $8D, " ", 
	.DB	$8B, " ", $01, "@", $88, " ", $01, "H", $9B, " ", $01, "H", $8F, " ", 
	.DB	$9A, " ", $04, "=-H-", $87, "=", $8B, " ", $01, "H", $8F, " ", 
	.DB	$8B, " ", $01, "H", $A4, " ", $01, "H", $8F, " ", 
	.DB	$8A, " ", $02, "=H", $8C, "=", $83, " ", $8D, "=", $01, " ", $89, "=", $8E, " ", 
	.DB	$8B, " ", $01, "H", $B4, " ", 
	.DB	$8B, " ", $01, "H", $B4, " ", 
	.DB	$8B, " ", $01, "H", $8D, " ", $01, "^", $98, " ", $01, "H", $8D, " ", 
	.DB	$87, " ", $8D, "=", $82, " ", $8E, "=", $84, " ", $8A, "=", $01, "H", $85, "=", $88, " ", 
	.DB	$01, "#", $B1, " ", $01, "H", $8D, " ", 
	.DB	$01, "#", $B1, " ", $01, "H", $8D, " ", 
	.DB	$02, "#&", $8F, " ", $82, "=", $01, "H", $82, "=", $01, "H", $86, "=", $01, " ", $85, "=", $01, "H", $84, "=", $01, "H", $89, "=", $01, "H", $8C, " ", $01, "#", 
	.DB	$02, "#=", $8D, " ", $82, "=", $AE, " ", $01, "#", 
	.DB	$03, "#*.", $8B, " ", $01, "^", $A3, " ", $01, "^", $8B, " ", $02, "*#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map2:
;	.DB	"                       U    —œŒ Œ…Õ¿ﬂ  œ–Œ√”À ¿                 "
;	.DB	"ÀŒ¬”ÿ ¿                                                         "
;	.DB	"  ƒÀﬂ                   H                                       "
;	.DB	"ƒ”–¿ Œ¬              ====                             $         "
;	.DB	"   !                  H .                             H         "
;	.DB	"   !              =   ---==H==H==H==H==H-         ^   H         "
;	.DB	"   !     H                                       U#   H         "
;	.DB	"   !    =H=====H=======  =============H===  ============        "
;	.DB	"   !     H                                                      "
;	.DB	"   V     H            #                                         "
;	.DB	"         H          ^ #                   . .       H           "
;	.DB	"#       =H=========== =====   ======H====== ========H=          "
;	.DB	"#       #                                           H  # #     #"
;	.DB	"# ^ ^ . #                   #                       H  # #     #"
;	.DB	"===H====  H                 #            .  .       H  #H. .^. #"
;	.DB	"         =H=======    =======  ===========  ====H====  #H#######"
;	.DB	"          H                                            #H       "
;	.DB	"          H         #                                           "
;	.DB	"          H         #^                  .   .        H          "
;	.DB	"         =========  ======   ============   =========H=         "
;	.DB	"#                                                    H         #"
;	.DB	"#                          ^                         H         #"
;	.DB	"#  &              *        #               *         H  ^      #"
;	.DB	"================================================================"

	.DB	$97, " ", $01, "U", $84, " ", $09, "—œŒ Œ…Õ¿ﬂ", $82, " ", $08, "œ–Œ√”À ¿", $91, " ", 
	.DB	$07, "ÀŒ¬”ÿ ¿", $B9, " ", 
	.DB	$82, " ", $03, "ƒÀﬂ", $93, " ", $01, "H", $A7, " ", 
	.DB	$07, "ƒ”–¿ Œ¬", $8E, " ", $84, "=", $9D, " ", $01, "$", $89, " ", 
	.DB	$83, " ", $01, "!", $92, " ", $03, "H .", $9D, " ", $01, "H", $89, " ", 
	.DB	$83, " ", $01, "!", $8E, " ", $01, "=", $83, " ", $83, "-", $82, "=", $01, "H", $82, "=", $01, "H", $82, "=", $01, "H", $82, "=", $01, "H", $82, "=", $02, "H-", $89, " ", $01, "^", $83, " ", $01, "H", $89, " ", 
	.DB	$83, " ", $01, "!", $85, " ", $01, "H", $A7, " ", $02, "U#", $83, " ", $01, "H", $89, " ", 
	.DB	$83, " ", $01, "!", $84, " ", $02, "=H", $85, "=", $01, "H", $87, "=", $82, " ", $8D, "=", $01, "H", $83, "=", $82, " ", $8C, "=", $88, " ", 
	.DB	$83, " ", $01, "!", $85, " ", $01, "H", $B6, " ", 
	.DB	$83, " ", $01, "V", $85, " ", $01, "H", $8C, " ", $01, "#", $A9, " ", 
	.DB	$89, " ", $01, "H", $8A, " ", $03, "^ #", $93, " ", $03, ". .", $87, " ", $01, "H", $8B, " ", 
	.DB	$01, "#", $87, " ", $02, "=H", $8B, "=", $01, " ", $85, "=", $83, " ", $86, "=", $01, "H", $86, "=", $01, " ", $88, "=", $02, "H=", $8A, " ", 
	.DB	$01, "#", $87, " ", $01, "#", $AB, " ", $01, "H", $82, " ", $03, "# #", $85, " ", $01, "#", 
	.DB	$09, "# ^ ^ . #", $93, " ", $01, "#", $97, " ", $01, "H", $82, " ", $03, "# #", $85, " ", $01, "#", 
	.DB	$83, "=", $01, "H", $84, "=", $82, " ", $01, "H", $91, " ", $01, "#", $8C, " ", $01, ".", $82, " ", $01, ".", $87, " ", $01, "H", $82, " ", $09, "#H. .^. #", 
	.DB	$89, " ", $02, "=H", $87, "=", $84, " ", $87, "=", $82, " ", $8B, "=", $82, " ", $84, "=", $01, "H", $84, "=", $82, " ", $02, "#H", $87, "#", 
	.DB	$8A, " ", $01, "H", $AC, " ", $02, "#H", $87, " ", 
	.DB	$8A, " ", $01, "H", $89, " ", $01, "#", $AB, " ", 
	.DB	$8A, " ", $01, "H", $89, " ", $02, "#^", $92, " ", $01, ".", $83, " ", $01, ".", $88, " ", $01, "H", $8A, " ", 
	.DB	$89, " ", $89, "=", $82, " ", $86, "=", $83, " ", $8C, "=", $83, " ", $89, "=", $02, "H=", $89, " ", 
	.DB	$01, "#", $B4, " ", $01, "H", $89, " ", $01, "#", 
	.DB	$01, "#", $9A, " ", $01, "^", $99, " ", $01, "H", $89, " ", $01, "#", 
	.DB	$01, "#", $82, " ", $01, "&", $8E, " ", $01, "*", $88, " ", $01, "#", $8F, " ", $01, "*", $89, " ", $01, "H", $82, " ", $01, "^", $86, " ", $01, "#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map3:
;	.DB	"#                       U  œŒœ–€√”Õ◊» »  U                      "
;	.DB	"#                                                  $            "
;	.DB	"#  &       H                                     .^^^.          "
;	.DB	"===========H=                                  H======H         "
;	.DB	"           H                                   H      H         "
;	.DB	"           H                 .  @           .  H      H         "
;	.DB	"        ===H=====     =    ======    =     ====H==    H         "
;	.DB	"       ¡         ^^^^^@^^^^      ^^^^@^^^^^           .         "
;	.DB	"       €                                      #       $         "
;	.DB	"       — #..       H      H      H         @  #                 "
;	.DB	"       “ ==========H==H======H====H-=H======  =====.            "
;	.DB	"       –           H        # . @  ##                           "
;	.DB	"       €           H        #     H                             "
;	.DB	"       … @         H        ===H===                             "
;	.DB	"                   H                                            "
;	.DB	"       —   #.      H                        ^     H             "
;	.DB	"       œ   ===----=H====---====H==============H===H==           "
;	.DB	"       ”                                          H             "
;	.DB	"       —                                          H             "
;	.DB	"                               .          H       H             "
;	.DB	"#           =H=               =^=         H========            #"
;	.DB	"#                  ^        == . ==       H                    #"
;	.DB	"#  *             .^^^.         ^          H       .^.^.^.   *  #"
;	.DB	"================================================================"

	.DB	$01, "#", $97, " ", $01, "U", $82, " ", $0C, "œŒœ–€√”Õ◊» »", $82, " ", $01, "U", $96, " ", 
	.DB	$01, "#", $B2, " ", $01, "$", $8C, " ", 
	.DB	$01, "#", $82, " ", $01, "&", $87, " ", $01, "H", $A5, " ", $01, ".", $83, "^", $01, ".", $8A, " ", 
	.DB	$8B, "=", $02, "H=", $A2, " ", $01, "H", $86, "=", $01, "H", $89, " ", 
	.DB	$8B, " ", $01, "H", $A3, " ", $01, "H", $86, " ", $01, "H", $89, " ", 
	.DB	$8B, " ", $01, "H", $91, " ", $01, ".", $82, " ", $01, "@", $8B, " ", $01, ".", $82, " ", $01, "H", $86, " ", $01, "H", $89, " ", 
	.DB	$88, " ", $83, "=", $01, "H", $85, "=", $85, " ", $01, "=", $84, " ", $86, "=", $84, " ", $01, "=", $85, " ", $84, "=", $01, "H", $82, "=", $84, " ", $01, "H", $89, " ", 
	.DB	$87, " ", $01, "¡", $89, " ", $85, "^", $01, "@", $84, "^", $86, " ", $84, "^", $01, "@", $85, "^", $8B, " ", $01, ".", $89, " ", 
	.DB	$87, " ", $01, "€", $A6, " ", $01, "#", $87, " ", $01, "$", $89, " ", 
	.DB	$87, " ", $03, "— #", $82, ".", $87, " ", $01, "H", $86, " ", $01, "H", $86, " ", $01, "H", $89, " ", $01, "@", $82, " ", $01, "#", $91, " ", 
	.DB	$87, " ", $02, "“ ", $8A, "=", $01, "H", $82, "=", $01, "H", $86, "=", $01, "H", $84, "=", $04, "H-=H", $86, "=", $82, " ", $85, "=", $01, ".", $8C, " ", 
	.DB	$87, " ", $01, "–", $8B, " ", $01, "H", $88, " ", $05, "# . @", $82, " ", $82, "#", $9B, " ", 
	.DB	$87, " ", $01, "€", $8B, " ", $01, "H", $88, " ", $01, "#", $85, " ", $01, "H", $9D, " ", 
	.DB	$87, " ", $03, "… @", $89, " ", $01, "H", $88, " ", $83, "=", $01, "H", $83, "=", $9D, " ", 
	.DB	$93, " ", $01, "H", $AC, " ", 
	.DB	$87, " ", $01, "—", $83, " ", $02, "#.", $86, " ", $01, "H", $98, " ", $01, "^", $85, " ", $01, "H", $8D, " ", 
	.DB	$87, " ", $01, "œ", $83, " ", $83, "=", $84, "-", $02, "=H", $84, "=", $83, "-", $84, "=", $01, "H", $8E, "=", $01, "H", $83, "=", $01, "H", $82, "=", $8B, " ", 
	.DB	$87, " ", $01, "”", $AA, " ", $01, "H", $8D, " ", 
	.DB	$87, " ", $01, "—", $AA, " ", $01, "H", $8D, " ", 
	.DB	$87, " ", $01, " ", $97, " ", $01, ".", $8A, " ", $01, "H", $87, " ", $01, "H", $8D, " ", 
	.DB	$01, "#", $8B, " ", $03, "=H=", $8F, " ", $03, "=^=", $89, " ", $01, "H", $88, "=", $8C, " ", $01, "#", 
	.DB	$01, "#", $92, " ", $01, "^", $88, " ", $82, "=", $03, " . ", $82, "=", $87, " ", $01, "H", $94, " ", $01, "#", 
	.DB	$01, "#", $82, " ", $01, "*", $8D, " ", $01, ".", $83, "^", $01, ".", $89, " ", $01, "^", $8A, " ", $01, "H", $87, " ", $07, ".^.^.^.", $83, " ", $01, "*", $82, " ", $01, "#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map4:
;	.DB	"#                  U                            U               "
;	.DB	"#                                                               "
;	.DB	"#   H.....H    H....H    H....H    # .    .  H  .               "
;	.DB	"====H-----=====H=======H============ ==---===H========          "
;	.DB	"    H          H  @        # @ @             H                  "
;	.DB	"    H          H           =============     H                  "
;	.DB	"    H       #  H         H  ¬≈—≈À€…   H      H     -H--H-       "
;	.DB	"    H       =======H=---=H============H      H                  "
;	.DB	"    H            H  @      H “”ÕÕ≈À‹ @H      H                  "
;	.DB	"    H           =H=========H==========H      H                  "
;	.DB	"    H           #H      @          H         H    . . . .       "
;	.DB	"    H^^^^^^^^^. ===================H         H   Õ≈ —Œ¬—≈Ã      "
;	.DB	"    H Ã Œ – √ H                    H  H#     H   .^^^^^^^.      "
;	.DB	"    H         H=====@-== -============H=     H    Ã Œ – √       "
;	.DB	"    H       ..H                       H      H                  "
;	.DB	"#           ==H=====--====----==========     H                  "
;	.DB	"#             H                            @ H                  "
;	.DB	"#.  .   .     H               ^  ^        ^  H     ------       "
;	.DB	"#==---==#     H    ^  ^  ^                #  H                  "
;	.DB	"#       #     H          #==--------=======  H                  "
;	.DB	"#  ===  #   =====-------==                   H      & H        #"
;	.DB	"#   $   #         ==            ^            H     ===H==      #"
;	.DB	"#* $$$ *# .^.                 .^.^.       .* H       *H   .^.  #"
;	.DB	"================================================================"

	.DB	$01, "#", $92, " ", $01, "U", $9C, " ", $01, "U", $8F, " ", 
	.DB	$01, "#", $BF, " ", 
	.DB	$01, "#", $83, " ", $01, "H", $85, ".", $01, "H", $84, " ", $01, "H", $84, ".", $01, "H", $84, " ", $01, "H", $84, ".", $01, "H", $84, " ", $03, "# .", $84, " ", $01, ".", $82, " ", $01, "H", $82, " ", $01, ".", $8F, " ", 
	.DB	$84, "=", $01, "H", $85, "-", $85, "=", $01, "H", $87, "=", $01, "H", $8C, "=", $01, " ", $82, "=", $83, "-", $83, "=", $01, "H", $88, "=", $8A, " ", 
	.DB	$84, " ", $01, "H", $8A, " ", $01, "H", $82, " ", $01, "@", $88, " ", $05, "# @ @", $8D, " ", $01, "H", $92, " ", 
	.DB	$84, " ", $01, "H", $8A, " ", $01, "H", $8B, " ", $8D, "=", $85, " ", $01, "H", $92, " ", 
	.DB	$84, " ", $01, "H", $87, " ", $01, "#", $82, " ", $01, "H", $89, " ", $01, "H", $82, " ", $07, "¬≈—≈À€…", $83, " ", $01, "H", $86, " ", $01, "H", $85, " ", $02, "-H", $82, "-", $02, "H-", $87, " ", 
	.DB	$84, " ", $01, "H", $87, " ", $87, "=", $02, "H=", $83, "-", $02, "=H", $8C, "=", $01, "H", $86, " ", $01, "H", $92, " ", 
	.DB	$84, " ", $01, "H", $8C, " ", $01, "H", $82, " ", $01, "@", $86, " ", $04, "H “”", $82, "Õ", $06, "≈À‹ @H", $86, " ", $01, "H", $92, " ", 
	.DB	$84, " ", $01, "H", $8B, " ", $02, "=H", $89, "=", $01, "H", $8A, "=", $01, "H", $86, " ", $01, "H", $92, " ", 
	.DB	$84, " ", $01, "H", $8B, " ", $02, "#H", $86, " ", $01, "@", $8A, " ", $01, "H", $89, " ", $01, "H", $84, " ", $07, ". . . .", $87, " ", 
	.DB	$84, " ", $01, "H", $89, "^", $02, ". ", $93, "=", $01, "H", $89, " ", $01, "H", $83, " ", $09, "Õ≈ —Œ¬—≈Ã", $86, " ", 
	.DB	$84, " ", $0B, "H Ã Œ – √ H", $94, " ", $01, "H", $82, " ", $02, "H#", $85, " ", $01, "H", $83, " ", $01, ".", $87, "^", $01, ".", $86, " ", 
	.DB	$84, " ", $01, "H", $89, " ", $01, "H", $85, "=", $02, "@-", $82, "=", $02, " -", $8C, "=", $02, "H=", $85, " ", $01, "H", $84, " ", $07, "Ã Œ – √", $87, " ", 
	.DB	$84, " ", $01, "H", $87, " ", $82, ".", $01, "H", $97, " ", $01, "H", $86, " ", $01, "H", $92, " ", 
	.DB	$01, "#", $8B, " ", $82, "=", $01, "H", $85, "=", $82, "-", $84, "=", $84, "-", $8A, "=", $85, " ", $01, "H", $92, " ", 
	.DB	$01, "#", $8D, " ", $01, "H", $9C, " ", $03, "@ H", $92, " ", 
	.DB	$02, "#.", $82, " ", $01, ".", $83, " ", $01, ".", $85, " ", $01, "H", $8F, " ", $01, "^", $82, " ", $01, "^", $88, " ", $01, "^", $82, " ", $01, "H", $85, " ", $86, "-", $87, " ", 
	.DB	$01, "#", $82, "=", $83, "-", $82, "=", $01, "#", $85, " ", $01, "H", $84, " ", $01, "^", $82, " ", $01, "^", $82, " ", $01, "^", $90, " ", $01, "#", $82, " ", $01, "H", $92, " ", 
	.DB	$01, "#", $87, " ", $01, "#", $85, " ", $01, "H", $8A, " ", $01, "#", $82, "=", $88, "-", $87, "=", $82, " ", $01, "H", $92, " ", 
	.DB	$01, "#", $82, " ", $83, "=", $82, " ", $01, "#", $83, " ", $85, "=", $87, "-", $82, "=", $93, " ", $01, "H", $86, " ", $03, "& H", $88, " ", $01, "#", 
	.DB	$01, "#", $83, " ", $01, "$", $83, " ", $01, "#", $89, " ", $82, "=", $8C, " ", $01, "^", $8C, " ", $01, "H", $85, " ", $83, "=", $01, "H", $82, "=", $86, " ", $01, "#", 
	.DB	$03, "#* ", $83, "$", $07, " *# .^.", $91, " ", $05, ".^.^.", $87, " ", $04, ".* H", $87, " ", $02, "*H", $83, " ", $03, ".^.", $82, " ", $01, "#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map5:
;	.DB	"œŒƒ⁄≈Ã         Œ“ƒ€’  ¬  √Œ–¿’              À¿¬»Õ€             #"
;	.DB	" +     $                                 @  !  U !             #"
;	.DB	" +     H   œ–»ﬂ“ÕŒ√Œ ¬¿Ã Œ“ƒ€’¿ !           V    V  H     &    #"
;	.DB	" ++++> H                                H          =H==========="
;	.DB	"       H                                H           H           "
;	.DB	"       HHHHHHHHHHHHH    .HHHHHHHH--------           H           "
;	.DB	"#      @                  U     H              --H--H           "
;	.DB	"#                               n                   H           "
;	.DB	"#      H                        H     .             H    .      "
;	.DB	"=======H======H====---=---===H==H===                H   -=-     "
;	.DB	"       H                                     H      H           "
;	.DB	"       H                                  ===H========          "
;	.DB	"œ–Œ¬¿À H                        H            H        ^.^      #"
;	.DB	"       H       @..^^^. .^.^. ^^ H#=-------   H                 #"
;	.DB	"   !   H      ========H=========H    @       H          H      #"
;	.DB	"   !   H      === = @= =    === H    -------============H======="
;	.DB	"   !   H                        H                       H       "
;	.DB	"   !   H      .           @   . H   .    @ .            H       "
;	.DB	"   !   ========----H----------=======------H=============       "
;	.DB	"   V                                                 .          "
;	.DB	"#              ==----   ----==       ==----===========         #"
;	.DB	"#                 @       @             @ @     @              #"
;	.DB	"#^^^*^^^^^   ^^ ^^#^^^*^^^#^^ ^^*^.^^ ^#^*^^^  ^.       # ^^^*^#"
;	.DB	"================================================================"

	.DB	$06, "œŒƒ⁄≈Ã", $89, " ", $05, "Œ“ƒ€’", $82, " ", $01, "¬", $82, " ", $05, "√Œ–¿’", $8E, " ", $06, "À¿¬»Õ€", $8D, " ", $01, "#", 
	.DB	$02, " +", $85, " ", $01, "$", $A1, " ", $01, "@", $82, " ", $01, "!", $82, " ", $03, "U !", $8D, " ", $01, "#", 
	.DB	$02, " +", $85, " ", $01, "H", $83, " ", $16, "œ–»ﬂ“ÕŒ√Œ ¬¿Ã Œ“ƒ€’¿ !", $8B, " ", $01, "V", $84, " ", $01, "V", $82, " ", $01, "H", $85, " ", $01, "&", $84, " ", $01, "#", 
	.DB	$01, " ", $84, "+", $03, "> H", $A0, " ", $01, "H", $8A, " ", $02, "=H", $8B, "=", 
	.DB	$87, " ", $01, "H", $A0, " ", $01, "H", $8B, " ", $01, "H", $8B, " ", 
	.DB	$87, " ", $8D, "H", $84, " ", $01, ".", $88, "H", $88, "-", $8B, " ", $01, "H", $8B, " ", 
	.DB	$01, "#", $86, " ", $01, "@", $92, " ", $01, "U", $85, " ", $01, "H", $8E, " ", $82, "-", $01, "H", $82, "-", $01, "H", $8B, " ", 
	.DB	$01, "#", $9F, " ", $01, "n", $93, " ", $01, "H", $8B, " ", 
	.DB	$01, "#", $86, " ", $01, "H", $98, " ", $01, "H", $85, " ", $01, ".", $8D, " ", $01, "H", $84, " ", $01, ".", $86, " ", 
	.DB	$87, "=", $01, "H", $86, "=", $01, "H", $84, "=", $83, "-", $01, "=", $83, "-", $83, "=", $01, "H", $82, "=", $01, "H", $83, "=", $90, " ", $01, "H", $83, " ", $03, "-=-", $85, " ", 
	.DB	$87, " ", $01, "H", $A5, " ", $01, "H", $86, " ", $01, "H", $8B, " ", 
	.DB	$87, " ", $01, "H", $A2, " ", $83, "=", $01, "H", $88, "=", $8A, " ", 
	.DB	$08, "œ–Œ¬¿À H", $98, " ", $01, "H", $8C, " ", $01, "H", $88, " ", $03, "^.^", $86, " ", $01, "#", 
	.DB	$87, " ", $01, "H", $87, " ", $01, "@", $82, ".", $83, "^", $08, ". .^.^. ", $82, "^", $04, " H#=", $87, "-", $83, " ", $01, "H", $91, " ", $01, "#", 
	.DB	$83, " ", $01, "!", $83, " ", $01, "H", $86, " ", $88, "=", $01, "H", $89, "=", $01, "H", $84, " ", $01, "@", $87, " ", $01, "H", $8A, " ", $01, "H", $86, " ", $01, "#", 
	.DB	$83, " ", $01, "!", $83, " ", $01, "H", $86, " ", $83, "=", $07, " = @= =", $84, " ", $83, "=", $02, " H", $84, " ", $87, "-", $8C, "=", $01, "H", $87, "=", 
	.DB	$83, " ", $01, "!", $83, " ", $01, "H", $98, " ", $01, "H", $97, " ", $01, "H", $87, " ", 
	.DB	$83, " ", $01, "!", $83, " ", $01, "H", $86, " ", $01, ".", $8B, " ", $01, "@", $83, " ", $03, ". H", $83, " ", $01, ".", $84, " ", $03, "@ .", $8C, " ", $01, "H", $87, " ", 
	.DB	$83, " ", $01, "!", $83, " ", $88, "=", $84, "-", $01, "H", $8A, "-", $87, "=", $86, "-", $01, "H", $8D, "=", $87, " ", 
	.DB	$83, " ", $01, "V", $B1, " ", $01, ".", $8A, " ", 
	.DB	$01, "#", $8E, " ", $82, "=", $84, "-", $83, " ", $84, "-", $82, "=", $87, " ", $82, "=", $84, "-", $8B, "=", $89, " ", $01, "#", 
	.DB	$01, "#", $91, " ", $01, "@", $87, " ", $01, "@", $8D, " ", $03, "@ @", $85, " ", $01, "@", $8E, " ", $01, "#", 
	.DB	$01, "#", $83, "^", $01, "*", $85, "^", $83, " ", $82, "^", $01, " ", $82, "^", $01, "#", $83, "^", $01, "*", $83, "^", $01, "#", $82, "^", $01, " ", $82, "^", $03, "*^.", $82, "^", $05, " ^#^*", $83, "^", $82, " ", $02, "^.", $87, " ", $02, "# ", $83, "^", $03, "*^#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map6:
;	.DB	"–¿——≈»¬¿“≈À‹ #                     ^             U              "
;	.DB	"------------>=H======H=============H==============  ”—À¿ƒ¿      "
;	.DB	"                             >>HHHHHH                —≈–ƒ÷¿     "
;	.DB	"                             HHH.    HHH                        "
;	.DB	"       H      ^              .     .                            "
;	.DB	"       H======#      ^       #     #^ =======        H          "
;	.DB	"       n      #=====H=====   # ^^^ #  U           ===H===       "
;	.DB	"       H                     #     #        –»¬¿ﬂ    H          "
;	.DB	"       n                     ===H===  # $            H          "
;	.DB	"       H         H              .     # n    ƒŒ–Œ√¿  H          "
;	.DB	"  ^    n       ==H====          &     #@H H          H         ^"
;	.DB	"  #    H         H           =============H       ====         #"
;	.DB	"  #    n         H     @#                 H               H    #"
;	.DB	"  #    H         H     @#           H     H          =====H==  #"
;	.DB	"  =====H===@     H      ========H===H     H   –¿…— »≈     H    #"
;	.DB	"  #@   . @#      H                  H     H    !   ”◊»    H    #"
;	.DB	"  =====n===      H                  H     @    !          H    #"
;	.DB	" Œ“ƒ€’ ƒÀﬂ    ===H==   ===    H     @          !          H    #"
;	.DB	"     ƒ”ÿ»       .@.           H==H==      ===  ! =^^^^ #========"
;	.DB	"^                             H   @            !^  ===H======   "
;	.DB	"#                      ^^^^...H-===-=        ^ +-->#@      @#  #"
;	.DB	"#                  ==  =======H         =====H======  .  .  #  #"
;	.DB	"#*     ^   ^     ^            H           H    .   H.   ^  H^ *#"
;	.DB	"================================================================"

	.DB	$02, "–¿", $82, "—", $0A, "≈»¬¿“≈À‹ #", $95, " ", $01, "^", $8D, " ", $01, "U", $8E, " ", 
	.DB	$8C, "-", $03, ">=H", $86, "=", $01, "H", $8D, "=", $01, "H", $8E, "=", $82, " ", $06, "”—À¿ƒ¿", $86, " ", 
	.DB	$9D, " ", $82, ">", $86, "H", $90, " ", $06, "—≈–ƒ÷¿", $85, " ", 
	.DB	$9D, " ", $83, "H", $01, ".", $84, " ", $83, "H", $98, " ", 
	.DB	$87, " ", $01, "H", $86, " ", $01, "^", $8E, " ", $01, ".", $85, " ", $01, ".", $9C, " ", 
	.DB	$87, " ", $01, "H", $86, "=", $01, "#", $86, " ", $01, "^", $87, " ", $01, "#", $85, " ", $03, "#^ ", $87, "=", $88, " ", $01, "H", $8A, " ", 
	.DB	$87, " ", $01, "n", $86, " ", $01, "#", $85, "=", $01, "H", $85, "=", $83, " ", $02, "# ", $83, "^", $02, " #", $82, " ", $01, "U", $8B, " ", $83, "=", $01, "H", $83, "=", $87, " ", 
	.DB	$87, " ", $01, "H", $95, " ", $01, "#", $85, " ", $01, "#", $87, " ", $06, " –»¬¿ﬂ", $84, " ", $01, "H", $8A, " ", 
	.DB	$87, " ", $01, "n", $95, " ", $83, "=", $01, "H", $83, "=", $82, " ", $03, "# $", $8C, " ", $01, "H", $8A, " ", 
	.DB	$87, " ", $01, "H", $89, " ", $01, "H", $8E, " ", $01, ".", $85, " ", $03, "# n", $84, " ", $06, "ƒŒ–Œ√¿", $82, " ", $01, "H", $8A, " ", 
	.DB	$82, " ", $01, "^", $84, " ", $01, "n", $87, " ", $82, "=", $01, "H", $84, "=", $8A, " ", $01, "&", $85, " ", $05, "#@H H", $8A, " ", $01, "H", $89, " ", $01, "^", 
	.DB	$82, " ", $01, "#", $84, " ", $01, "H", $89, " ", $01, "H", $8B, " ", $8D, "=", $01, "H", $87, " ", $84, "=", $89, " ", $01, "#", 
	.DB	$82, " ", $01, "#", $84, " ", $01, "n", $89, " ", $01, "H", $85, " ", $02, "@#", $91, " ", $01, "H", $8F, " ", $01, "H", $84, " ", $01, "#", 
	.DB	$82, " ", $01, "#", $84, " ", $01, "H", $89, " ", $01, "H", $85, " ", $02, "@#", $8B, " ", $01, "H", $85, " ", $01, "H", $8A, " ", $85, "=", $01, "H", $82, "=", $82, " ", $01, "#", 
	.DB	$82, " ", $85, "=", $01, "H", $83, "=", $01, "@", $85, " ", $01, "H", $86, " ", $88, "=", $01, "H", $83, "=", $01, "H", $85, " ", $01, "H", $83, " ", $07, "–¿…— »≈", $85, " ", $01, "H", $84, " ", $01, "#", 
	.DB	$82, " ", $02, "#@", $83, " ", $04, ". @#", $86, " ", $01, "H", $92, " ", $01, "H", $85, " ", $01, "H", $84, " ", $01, "!", $82, " ", $04, " ”◊»", $84, " ", $01, "H", $84, " ", $01, "#", 
	.DB	$82, " ", $85, "=", $01, "n", $83, "=", $86, " ", $01, "H", $92, " ", $01, "H", $85, " ", $01, "@", $84, " ", $01, "!", $8A, " ", $01, "H", $84, " ", $01, "#", 
	.DB	$0A, " Œ“ƒ€’ ƒÀﬂ", $84, " ", $83, "=", $01, "H", $82, "=", $83, " ", $83, "=", $84, " ", $01, "H", $85, " ", $01, "@", $8A, " ", $01, "!", $8A, " ", $01, "H", $84, " ", $01, "#", 
	.DB	$85, " ", $04, "ƒ”ÿ»", $87, " ", $03, ".@.", $8B, " ", $01, "H", $82, "=", $01, "H", $82, "=", $86, " ", $83, "=", $82, " ", $03, "! =", $84, "^", $02, " #", $88, "=", 
	.DB	$01, "^", $9D, " ", $01, "H", $83, " ", $01, "@", $8C, " ", $02, "!^", $82, " ", $83, "=", $01, "H", $86, "=", $83, " ", 
	.DB	$01, "#", $96, " ", $84, "^", $83, ".", $02, "H-", $83, "=", $02, "-=", $88, " ", $03, "^ +", $82, "-", $03, ">#@", $86, " ", $02, "@#", $82, " ", $01, "#", 
	.DB	$01, "#", $92, " ", $82, "=", $82, " ", $87, "=", $01, "H", $89, " ", $85, "=", $01, "H", $86, "=", $82, " ", $01, ".", $82, " ", $01, ".", $82, " ", $01, "#", $82, " ", $01, "#", 
	.DB	$02, "#*", $85, " ", $01, "^", $83, " ", $01, "^", $85, " ", $01, "^", $8C, " ", $01, "H", $8B, " ", $01, "H", $84, " ", $01, ".", $83, " ", $02, "H.", $83, " ", $01, "^", $82, " ", $05, "H^ *#", 
	.DB	$C0, "=", 
	.DB	0FFh
Map7:
;	.DB	"    – ≈ « Œ À ﬁ ÷ » ﬂ     !   ”–Œ¬≈Õ‹ ƒÀﬂ —¿Ã€’ —◊¿—“À»¬€’      "
;	.DB	"--------------------------+ H            U                      "
;	.DB	"                            ==========H===         ...          "
;	.DB	"                     #                             ...          "
;	.DB	"        #  &  H      #@     #                      ...  H   Ã   "
;	.DB	"¬ — ≈   ======H      # ^    H        @   ======H====H===H       "
;	.DB	"            U H      # . ^  #        ==            @    H   »   "
;	.DB	" ƒ À ﬂ        H      ==H=====  H                ^^^.    H       "
;	.DB	"              H                H==              ------- H   –   "
;	.DB	"  ¬ ¿ —   H   H                H            @           H       "
;	.DB	"          H===H                H        #   #      ^    H   ¿   "
;	.DB	"   ! ! !  H           ^^@@^^ @^H    H   #   =======H====H       "
;	.DB	"          H         ====H======H====H====     @         H   ∆   "
;	.DB	"          H                    n    H        @@@        H       "
;	.DB	"                               n    H       @@@@@^^..^^ H   »   "
;	.DB	"                               H    H       ============H       "
;	.DB	"                     ==----======   H   #      $    $       +   "
;	.DB	"                                #   H   #     $$$  $$$      +   "
;	.DB	"       ===-----===              #   H   #    $$$$$$$$$$  <+++   "
;	.DB	"^      ¿ «ƒ≈—‹   #   =          # ======#   ============       ^"
;	.DB	"#     œ–»ƒ≈“—ﬂ   #   $           ^   @                         #"
;	.DB	"#   œŒ“–”ƒ»“‹—ﬂ  #^^^^^^   $ ^      =====                      #"
;	.DB	"#*                 .... @ ^H*^           ^ ^           ^^^^^^^^#"
;	.DB	"================================================================"

	.DB	$84, " ", $11, "– ≈ « Œ À ﬁ ÷ » ﬂ", $85, " ", $01, "!", $83, " ", $1C, "”–Œ¬≈Õ‹ ƒÀﬂ —¿Ã€’ —◊¿—“À»¬€’", $86, " ", 
	.DB	$9A, "-", $03, "+ H", $8C, " ", $01, "U", $96, " ", 
	.DB	$9C, " ", $8A, "=", $01, "H", $83, "=", $89, " ", $83, ".", $8A, " ", 
	.DB	$95, " ", $01, "#", $9D, " ", $83, ".", $8A, " ", 
	.DB	$88, " ", $01, "#", $82, " ", $01, "&", $82, " ", $01, "H", $86, " ", $02, "#@", $85, " ", $01, "#", $96, " ", $83, ".", $82, " ", $01, "H", $83, " ", $01, "Ã", $83, " ", 
	.DB	$05, "¬ — ≈", $83, " ", $86, "=", $01, "H", $86, " ", $03, "# ^", $84, " ", $01, "H", $88, " ", $01, "@", $83, " ", $86, "=", $01, "H", $84, "=", $01, "H", $83, "=", $01, "H", $87, " ", 
	.DB	$8C, " ", $03, "U H", $86, " ", $05, "# . ^", $82, " ", $01, "#", $88, " ", $82, "=", $8C, " ", $01, "@", $84, " ", $01, "H", $83, " ", $01, "»", $83, " ", 
	.DB	$06, " ƒ À ﬂ", $88, " ", $01, "H", $86, " ", $82, "=", $01, "H", $85, "=", $82, " ", $01, "H", $90, " ", $83, "^", $01, ".", $84, " ", $01, "H", $87, " ", 
	.DB	$8E, " ", $01, "H", $90, " ", $01, "H", $82, "=", $8E, " ", $87, "-", $02, " H", $83, " ", $01, "–", $83, " ", 
	.DB	$82, " ", $05, "¬ ¿ —", $83, " ", $01, "H", $83, " ", $01, "H", $90, " ", $01, "H", $8C, " ", $01, "@", $8B, " ", $01, "H", $87, " ", 
	.DB	$8A, " ", $01, "H", $83, "=", $01, "H", $90, " ", $01, "H", $88, " ", $01, "#", $83, " ", $01, "#", $86, " ", $01, "^", $84, " ", $01, "H", $83, " ", $01, "¿", $83, " ", 
	.DB	$83, " ", $05, "! ! !", $82, " ", $01, "H", $8B, " ", $82, "^", $82, "@", $82, "^", $04, " @^H", $84, " ", $01, "H", $83, " ", $01, "#", $83, " ", $87, "=", $01, "H", $84, "=", $01, "H", $87, " ", 
	.DB	$8A, " ", $01, "H", $89, " ", $84, "=", $01, "H", $86, "=", $01, "H", $84, "=", $01, "H", $84, "=", $85, " ", $01, "@", $89, " ", $01, "H", $83, " ", $01, "∆", $83, " ", 
	.DB	$8A, " ", $01, "H", $94, " ", $01, "n", $84, " ", $01, "H", $88, " ", $83, "@", $88, " ", $01, "H", $87, " ", 
	.DB	$9F, " ", $01, "n", $84, " ", $01, "H", $87, " ", $85, "@", $82, "^", $82, ".", $82, "^", $02, " H", $83, " ", $01, "»", $83, " ", 
	.DB	$9F, " ", $01, "H", $84, " ", $01, "H", $87, " ", $8C, "=", $01, "H", $87, " ", 
	.DB	$95, " ", $82, "=", $84, "-", $86, "=", $83, " ", $01, "H", $83, " ", $01, "#", $86, " ", $01, "$", $84, " ", $01, "$", $87, " ", $01, "+", $83, " ", 
	.DB	$A0, " ", $01, "#", $83, " ", $01, "H", $83, " ", $01, "#", $85, " ", $83, "$", $82, " ", $83, "$", $86, " ", $01, "+", $83, " ", 
	.DB	$87, " ", $83, "=", $85, "-", $83, "=", $8E, " ", $01, "#", $83, " ", $01, "H", $83, " ", $01, "#", $84, " ", $8A, "$", $82, " ", $01, "<", $83, "+", $83, " ", 
	.DB	$01, "^", $86, " ", $07, "¿ «ƒ≈—‹", $83, " ", $01, "#", $83, " ", $01, "=", $8A, " ", $02, "# ", $86, "=", $01, "#", $83, " ", $8C, "=", $87, " ", $01, "^", 
	.DB	$01, "#", $85, " ", $08, "œ–»ƒ≈“—ﬂ", $83, " ", $01, "#", $83, " ", $01, "$", $8B, " ", $01, "^", $83, " ", $01, "@", $99, " ", $01, "#", 
	.DB	$01, "#", $83, " ", $0B, "œŒ“–”ƒ»“‹—ﬂ", $82, " ", $01, "#", $86, "^", $83, " ", $03, "$ ^", $86, " ", $85, "=", $96, " ", $01, "#", 
	.DB	$02, "#*", $91, " ", $84, ".", $07, " @ ^H*^", $8B, " ", $03, "^ ^", $8B, " ", $88, "^", $01, "#", 
	.DB	$C0, "=", 
	.DB	0FFh
; end of 'ROM'

;Screen:
;	.FILL	64*24, 0

		.end

;			   1         2	       3         4         5         6
;		 0123456789012345678901234567890123456789012345678901234567890123
;		------------------------------------------------------------------
