;--------------------------------------------------------------------------
;
; 64x24 screen
;
;
SCR_POS		= 000Ch
SCR_SCROLL	= 000Eh
PUT_CHR		= 0FF90h
CLS		= 0FD00h

CR		= 0Dh
LF		= 0Ah
ESC		= 27h
CTRLC		= 03h
CTRLZ		= 1Ah

MAPW		= 10
MAPH		= 23

BUFW		= MAPW+2		; including side walls
BUFH		= MAPH+2		; including top and bottom walls

SCRX		= (64-20)/2

;-----------------------------------------------------------------------
	.org	0100h

	LD	A, 01h	; 8x8, Font 1bit, Scale x2
;	LD	A, 11h	; 8x16, Font 1bit, Scale x2
	OUT	(0F7h), A

	LD	hl, 0
	LD	(SCR_POS), HL
	LD	(SCR_SCROLL), HL

BEGIN:
	call	CLS
	call	INIMAP		; initialize container map
	ld	hl,0
	ld	(FLROWS),hl
	ld	(SHAPES),hl
	ld	a,10
	ld	(LCNT),a
	call	DRWMAP		; draw container
	call	GETLVL		; get initial level
	call	STATUS		; output status info, etc.
	ld	hl,MSTART
	call	PRNTXY
	call	GETCH		; wait for a key
	cp	3
	jp	z,QUIT
	ld	hl,CLRMST
	call	PRNTXY
	call	RND		; pick a random figure
NEXTS:
	ld	(INISHP),hl	; remember initial orientation
	ld	(CURSHP),hl	; set current shape
	call	RND		; pick a random figure
	ld	(NXTSHP),hl	; save as next
	call	DRWNXT		; draw next shape
	call	CKFULL		; compress any for full rows
	ld	h,0		; set initial position
	ld	l,5		; set initial position
	ld	(CPOS),hl	;  to the middle of the top line
	ld	a,1
	ld	(ORIENT),a	; reset figure orientation
NEXTR:
	ld	a,(DLYCON)
	ld	(DLYCNT),a	; reset delay counter
	call	DRWSHP		; draw shape
CKEY:
	ld	hl,DCNT
	push	hl		; push return address
	call	INKEY
	cp	3
	jp	z,QUIT
	ld	hl,LASTK
	cp	(hl)
	ret	z
	ld	(hl),a
	cp	'A'
	jp	z,LEFT
	cp	'D'
	jp	z,RIGHT
	cp	'W'
	jp	z,ROTATE
	cp	'S'
	jp	z,DROP
	ret

DCNT:
	ld	a,1
	call	DELAY
	ld	hl,DLYCNT
	dec	(hl)
	jr	nz,CKEY
	call	DOWN		; down one row
	jr	NEXTR		; and loop

DROP:
	pop	hl		; drop return address
drp1:
	call	DOWN		; down one row
	call	DRWSHP
	jr	drp1		; until bottom reached

QUIT:
	pop	hl		; drop return address
	call	CLS
	RET

;--------------------------------------------------------------------------
; Move shape right one column
RIGHT:
	ld	hl,(CPOS)
	inc	l
	jr	move

; Move shape left one column
LEFT:
	ld	hl,(CPOS)
	dec	l
move:
	ld	(NPOS),hl
	ld	hl,(CURSHP)
	ld	(TPTR),hl
	ld	de,0
	ld	b,4		; all shapes are made of 4 little blocks
chk1:
	ld	hl,(NPOS)
	call	XYBUF
	ld	a,(hl)
	or	a		; busy cell?
	ret	nz		; return if yes, can't move
	ld	hl,(TPTR)
	ld	e,(hl)		; else try next cell
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	chk1
	call	CLRSHP		; clear shape
	ld	hl,(NPOS)
	ld	(CPOS),hl	; move to new position
	jp	DRWSHP		; draw shape and return

;--------------------------------------------------------------------------
; Rotate shape
ROTATE:
	ld	a,(ORIENT)	; get current orientation
	inc	a		; rotate
	cp	5		; max reached? (1..4)
	jr	nc,rot1		; branch if yes
	ld	hl,(CURSHP)
	ld	bc,6
	add	hl,bc		; point to next fig data
	jr	rot2
rot1:
	ld	a,1		; reset orientation
	ld	hl,(INISHP)
rot2:
	ld	(NORIEN),a	; else save new
	ld	(NPOS),hl	; save temp new fig ptr
	ld	(TPTR),hl
	ld	de,0		; then check if OK to rotate
	ld	b,4
chk4:
	ld	hl,(CPOS)	; get current pos
	call	XYBUF
	ld	a,(hl)
	or	a		; cell busy?
	ret	nz		; return, can't rotate
	ld	hl,(TPTR)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	chk4
	call	CLRSHP		; rotate OK, clear shape
	ld	a,(NORIEN)
	ld	(ORIENT),a
	ld	hl,(NPOS)
	ld	(CURSHP),hl	; make this orientation current
	jp	DRWSHP		; draw shape and return

;--------------------------------------------------------------------------
; Move shape down one row
DOWN:
	ld	hl,(CPOS)
	inc	h
	ld	(NPOS),hl	; save temp new pos
	ld	hl,(CURSHP)
	ld	(TPTR),hl
	ld	de,0
	ld	b,4
chk2:
	ld	hl,(NPOS)
	call	XYBUF
	ld	a,(hl)
	or	a		; busy cell?
	jr	nz,chk3		; exit loop if yes, can't go down any further
	ld	hl,(TPTR)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	chk2
	call	CLRSHP		; clear shape
	ld	hl,(NPOS)
	ld	(CPOS),hl	; set new pos
	ret

chk3:
	pop	de		; drop return address
	ld	hl,(CPOS)
	ld	a,h
	or	a		; at first row?
	jr	z,over		; then game is over
	call	FREEZE		; else shape freezes
	ld	hl,(NXTSHP)	; next figure
	jp	NEXTS		;  becomes current

over:
	ld	hl,GAMOVR
	call	PRNTXY
wtcr:
	call	GETCH
	cp	3
	jp	z,QUIT
	cp	CR
	jr	nz,wtcr		; wait for CR
	ld	hl,CLRGMO
	call	PRNTXY
	jp	BEGIN		; then restart game

;--------------------------------------------------------------------------
; Freeze shape
FREEZE:
	ld	hl,(CURSHP)
	ld	(TPTR),hl
	ld	de,0
	ld	b,4
frz1:
	ld	hl,(CPOS)
	call	XYBUF
	ld	(hl),2		; shape freezes
	ld	hl,(TPTR)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	frz1
	ret

;--------------------------------------------------------------------------
; Draw shape
DRWSHP:
	ld	hl,(CURSHP)
	ld	(TPTR),hl
	ld	de,0
	ld	b,4
drw1:
	ld	hl,(CPOS)
	ld	a,e
	add	a,l
	add	a,a
	add	a,SCRX		; shape is drawn relative to X=SCRX, Y=0
	ld	L,a
	ld	a,d
	add	a,h
	ld	h,a
	LD	(SCR_POS), HL
	ld	A, '['
	call	PUTCH
	ld	A, ']'
	call	PUTCH
	ld	hl,(TPTR)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	drw1
	ret

;--------------------------------------------------------------------------
; Clear shape
CLRSHP:
	ld	hl,(CURSHP)
	ld	(TPTR),hl
	ld	de,0
	ld	b,4
clr1:
	ld	hl,(CPOS)
	ld	a,e
	add	a,l
	add	a,a
	add	a,SCRX		; shape is drawn relative to X=SCRX, Y=0
	ld	L,a
	ld	a,d
	add	a,h
	ld	h,a
	LD	(SCR_POS), HL
	ld	A, ' '
	call	PUTCH
	ld	A, '.'
	call	PUTCH
	ld	hl,(TPTR)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	clr1
	ret

;--------------------------------------------------------------------------
; Draw next shape hint
DRWNXT:
	ld	hl,CLRSTR	; clear next shape
	call	PRNTXY
	ld	hl,(NXTSHP)
	ld	(TPTR),hl
	ld	de,0
	ld	b,4
dnxt1:
	ld	a,e
	add	a,a
	add	a,7		; shape is drawn at X=7, Y=16
	ld	l,a
	ld	a,d
	add	a,16
	ld	h,a
	LD	(SCR_POS), HL
	ld	A,'['
	call	PUTCH
	ld	A,']'
	call	PUTCH
	ld	hl,(TPTR)
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	inc	hl
	ld	(TPTR),hl
	djnz	dnxt1
	ret

;--------------------------------------------------------------------------
; Index into map, called with HL = x,y coordinates and DE = x,y shape data
XYBUF:
	push	bc
	inc	d		; add wall offset, this also ensures that
	inc	e		;  relative Y offset is always positive
	ld	a,l
	add	a,e
	ld	c,a
	ld	b,0

	ld	a,h
	add	a,d
	ld	e,BUFW
	call	MULT8
	add	hl,bc
	ld	bc,BUF
	add	hl,bc
	pop	bc
	ret

;--------------------------------------------------------------------------
; Delete any rows that are full
CKFULL:
	ld	h,BUFH-2	; start from the bottom
	ld	l,0
ckfr1:
	ld	(NPOS),hl
	ld	de,0FF00h
	call	XYBUF		; obtain map coordinates
	ld	(TPTR),hl
ckfr2:
	ld	a,(hl)
	dec	a		; wall?
	jr	z,ckfr4		; exit this loop if yes, compress this row
	dec	a		; old accumulated garbage?
	jr	nz,ckfr3	; branch if not
	inc	hl		; else advance to next cell
	jr	ckfr2		; and loop

ckfr3:
	ld	hl,(NPOS)
	dec	h		; up one row
	jr	nz,ckfr1	; loop until top reached
	ld	hl,(SHAPES)	; inc number of shapes
	inc	hl
	ld	(SHAPES),hl
	jp	UPDST		; update status info and return

ckfr4:
	ld	hl,(FLROWS)	; inc number of full rows
	inc	hl
	ld	(FLROWS),hl
	ld	hl,LCNT
	dec	(hl)		; time to increase level?
	jr	nz,upd		; branch if not
	ld	(hl),10
	ld	a,(LEVEL)
	cp	10		; max allowed
	jr	nc,upd
	inc	a
	ld	(LEVEL),a
	call	SETSPD		; cranck up speed
upd:
	call	UPDST		; update status info on the screen
cpr1:
	ld	hl,(NPOS)
	dec	h		; up one row
	ld	(NPOS),hl
	jr	z,cpr2		; exit loop when done
	ld	de,(TPTR)	; DE = dst (current row)
	ld	hl,-BUFW
	add	hl,de		; HL = src (upper row)
	ld	(TPTR),hl
	ld	bc,MAPW
	ldir			; copy row down
	call	DROW		; update row on the screen
	jr	cpr1		; continue compressing until top reached
cpr2:
	jr	CKFULL		; repeat until all full rows are deleted

;--------------------------------------------------------------------------
; Draw one row. Called during full row deletion
DROW:
	ld	hl,(NPOS)
	ld	a,l
	add	a,a
	add	a,SCRX		; rows are drawn relative to X=SCRX, Y=0
	ld	l,a
	LD	(SCR_POS), HL
	ld	hl,(TPTR)
	ld	b,MAPW
dr1:
	ld	a,(hl)
	or	a		; empty cell?
	jr	z,dr2		; branch if yes
	ld	A,'['
	call	PUTCH
	ld	A,']'
	call	PUTCH
	jr	dr3
dr2:
	ld	A, ' '
	call	PUTCH
	ld	A, '.'
	call	PUTCH
dr3:
	inc	hl
	djnz	dr1
	ret

;--------------------------------------------------------------------------
; Initialize map
INIMAP:
	ld	hl,BUF
	call	ini3		; top wall
	ld	c,MAPH
ini1:
	ld	(hl),1		; left wall
	inc	hl
	ld	b,MAPW
	xor	a
ini2:
	ld	(hl),a
	inc	hl
	djnz	ini2
	ld	(hl),1		; right wall
	inc	hl
	dec	c
	jr	nz,ini1
ini3:
	ld	b,BUFW
ini4:
	ld	a,1
	ld	(hl),a		; bottom wall
	inc	hl
	djnz	ini4
	ret

;--------------------------------------------------------------------------
; Draw container
DRWMAP:
	ld	h,0
	ld	l,SCRX-2	; X=SCRX-2, Y=0
dm1:
	LD	(SCR_POS), HL
	ex	de,hl
	ld	hl,WROW		; draw well
	call	PUTSTR
	ex	de,hl
	inc	h		; inc Y
	ld	a,h
	cp	MAPH
	jr	nz,dm1
	LD	(SCR_POS), HL
	ld	hl,WBOTM	; draw well
	call	PUTSTR
	ret

;--------------------------------------------------------------------------
; Prompt for and get initial level
GETLVL:
	ld	hl,BANNER
	call	PRNTXY
glv1:
	call	RND
	ld	a,1
	call	DELAY
	call	INKEY		; get char
	cp	3		; ^C returns to system
	jp	z,QUIT
	sub	'0'
	jr	c,glv1
	cp	10
	jr	nc,glv1
	ld	(LEVEL),a	; store level char
	call	SETSPD		; setup delay constant
	ld	hl,CLRBNR
	call	PRNTXY
	ret

;--------------------------------------------------------------------------
; Set speed according to level
SETSPD:
	ld	hl,VTAB
	ld	e,a
	ld	d,0
	add	hl,de		; index into table
	ld	a,(hl)
	ld	(DLYCON),a
	ret

VTAB:	.db	140		;  0
	.db	120		;  1
	.db	100		;  2
	.db	80		;  3
	.db	60		;  4
	.db	48		;  5
	.db	36		;  6
	.db	22		;  7
	.db	12		;  8
	.db	5		;  9
	.db	2		; 10

;--------------------------------------------------------------------------
; Display status info
STATUS:
	ld	hl,STINFO
	call	PRNTXY		; output status text
UPDST:
	ld	l,9
	ld	h,2
	LD	(SCR_POS), HL
	ld	a,(LEVEL)
	ld	l,a
	ld	h,0
	ld	a,' '
	call	HLDEC		; display current level
	ld	l,9
	ld	h,3
	LD	(SCR_POS), HL
	ld	hl,(FLROWS)
	ld	a,' '
	call	HLDEC
	ld	l,9
	ld	h,4
	LD	(SCR_POS), HL
	ld	hl,(SHAPES)
	ld	a,' '
	call	HLDEC
	ret

;--------------------------------------------------------------------------
; HL = A * E
MULT8:
	ld	hl,0
	ld	d,0
nxt:
	or	a
	ret	z
	rra
	jr	nc,shft
	add	hl,de
shft:
	ex	de,hl
	add	hl,hl
	ex	de,hl
	jr	nxt

;--------------------------------------------------------------------------
; Pick a random figure
RND:
	ld	hl,(RAND)
	ld	b,16
r1:
	ld	a,h
	add	hl,hl
	and	60h
	jp	pe,r2
	inc	hl
r2:
	djnz	r1
	ld	(RAND),hl
	ld	a,l
	and	7
	cp	7
	jr	z,RND		; number must be 0..6
	ld	hl,LAST
	cp	(hl)
	jr	z,RND		; and different than the previous one
	ld	(hl),a
	add	a,a
	add	a,a
	add	a,a		; *8
	ld	c,a
	add	a,a		; *16
	add	a,c		; *24
	ld	c,a
	ld	b,0
	ld	hl,FTAB
	add	hl,bc		; index into table
	ret

;---------------------------------------------------------------------------
;--------------------------------------------------------------------------
DEC_A:
	PUSH	de
	PUSH	bc
	LD	d, 0
	LD	b, 100
	CALL	ad1
	LD	b, 10
	CALL	ad1
	add	a, '0'
	CALL	PUTCH
	POP	bc
	POP	de
	ret

ad1:
	LD	c,'0'-1
ad2:
	inc	c
	sub	b
	jr	nc, ad2
	add	a, b
	PUSH	af
	LD	a, c
	cp	'0'
	jr	nz, ad4
	inc	d
	dec	d
	jr	z, ad5
ad4:
	CALL	PUTCH
	inc	d
ad5:
	POP	af
	ret

HLDEC:
DEC_HL:
	LD	(filler), a
	PUSH	hl
	PUSH	de
	PUSH	bc
	LD	b,0
	LD	de,-10000
	CALL	sbcnt
	LD	de,-1000
	CALL	sbcnt
	LD	de,-100
	CALL	sbcnt
	LD	de,-10
	CALL	sbcnt
	LD	a,l
	add	a,'0'
	CALL	PUTCH
	POP	bc
	POP	de
	POP	hl
	ret

sbcnt:
	LD	c, '0'-1
sb1:
	inc	c
	add	hl, de
	jr	c, sb1
	sbc	hl, de
	bit	7, b
	jr	nz, sb3
	LD	a, c
	cp	'0'
	jr	nz, sb2
	LD	a, (filler)
	or	a
	ret	z
	LD	c, a
	jr	sb3
sb2:
	set	7, b
sb3:
	LD	a, c
	CALL	PUTCH
	inc	b
	ret

CPHLDE:	LD	a,d
	cp	h
	ret	nz
	LD	a,e
	cp	l
	ret

DELAY:
	LD	c,a
d0:
	LD	b,30		; speed
d1:
	PUSH	bc
	LD	bc,0100h
d2:
	dec	bc
	LD	a,b
	or	c
	jr	nz,d2
	POP	bc
	djnz	d1
	dec	c
	jr	nz,d0
	ret

UCASE:
	cp	'a'
	ret	c
	cp	'z'+1
	ret	nc
	and	5Fh
	ret

SETCUR_:
	LD	A, L
	LD	L, H
	LD	H, A
	LD	(SCR_POS), HL
	RET
PUTCH:
	PUSH	HL
	LD	HL, (SCR_POS)
	CALL	PUT_CHR
	INC	HL
	LD	(SCR_POS), HL
	POP	HL
	RET

INKEY:
	RST	18h
	LD	A, 0
	RET	Z
GETCH:
	RST	10h
	RET

PRNTXY:
	ld	a, (hl)
	cp	0FFh
	ret	z
	ld	E, a		; X
	inc	hl
	ld	D, (hl)		; Y
	inc	hl
	ex	de, hl
	LD	(SCR_POS), HL
	ex	de, hl
	call	PUTSTR
	inc	hl
	jr	PRNTXY

PUTSTR:
	PUSH	DE
	EX	DE, HL
	LD	HL, (SCR_POS)
PS:
	LD	A, (DE)
	OR	A
	JR	Z, PS_
	CALL	PUT_CHR
	INC	DE
	INC	HL
	Jr	PS
PS_:
	EX	DE, HL
	POP	DE
	RET

;--------------------------------------------------------------------------
; Table of figures. Values are x,y offset from center of rotation point,
; the center point itself is not included.

FTAB:	; ####
	.db	-2, 0,  -1, 0,  1, 0	;   0 degrees
	.db	 0,-1,   0, 1,  0, 2	;  90   "
	.db	-2, 0,  -1, 0,  1, 0	; 180   "
	.db	 0,-1,   0, 1,  0, 2	; 270   "

	;  #
	; ###
	.db	-1, 0,   1, 0,  0, 1
	.db	 0, 1,   1, 0,  0,-1
	.db	-1, 0,   0,-1,  1, 0
	.db	-1, 0,   0, 1,  0,-1

	; #  
	; ###
	.db	-1, 0,   1, 0, -1, 1
	.db	 0,-1,   0, 1,  1, 1
	.db	-1, 0,   1,-1,  1, 0
	.db	 0,-1,  -1,-1,  0, 1

	; ##
	;  ##
	.db	 1, 0,  -1, 1,  0, 1
	.db	 0,-1,   1, 0,  1, 1
	.db	 1, 0,  -1, 1,  0, 1
	.db	 0,-1,   1, 0,  1, 1

	;   #
	; ###
	.db	-1, 0,   1, 0,  1, 1
	.db	 0,-1,   1,-1,  0, 1
	.db	-1, 0,  -1,-1,  1, 0
	.db	 0,-1,   0, 1, -1, 1

	;  ##
	; ##
	.db	-1, 0,   0, 1,  1, 1
	.db	 0, 1,   1, 0,  1,-1
	.db	-1, 0,   0, 1,  1, 1
	.db	 0, 1,   1, 0,  1,-1

	; ##
	; ##
	.db	-1, 0,  -1, 1,  0, 1
	.db	-1, 0,  -1, 1,  0, 1
	.db	-1, 0,  -1, 1,  0, 1
	.db	-1, 0,  -1, 1,  0, 1

;--------------------------------------------------------------------------
	.db	"ooooooooooooo oooooooooooo ooooooooooooo ooooooooo.   ooooo  .oooooo..o"
	.db	"8'   888   `8 `888'     `8 8'   888   `8 `888   `Y88. `888' d8P'    `Y8"
	.db	"     888       888              888       888   .d88'  888  Y88bo.     "
	.db	"     888       888oooo8         888       888ooo88P'   888   `'Y8888o. "
	.db	"     888       888    '         888       888`88b.     888       `'Y88b"
	.db	"     888       888       o      888       888  `88b.   888  oo     .d8P"
	.db	"    o888o     o888ooooood8     o888o     o888o  o888o o888o 8''88888P' "


BANNER:	.db	4, 2, "T E T R I S", 0
	.db	2, 4, "Level (0...9) ? ", 0
	.db	0FFh

CLRBNR:	.db	4, 2, "           ", 0
	.db	2, 4, "                  ", 0
	.db	0FFh

MSTART:	.db	36, 16, "Press any key to start", 0
	.db	0FFh

GAMOVR:	.db	40, 14, "GAME OVER", 0
	.db	36, 16, "Press Enter to restart", 0
	.db	0FFh

CLRGMO:	.db	40, 14, "         ", 0
CLRMST:	.db	36, 16, "                      ", 0
	.db	0FFh

WROW:	.db	"## . . . . . . . . . .##", 0
WBOTM:	.db	"########################", 0

STINFO:	.db	1,  2, "Level:", 0
	.db	1,  3, "Score:", 0
	.db	1,  4, "Pieces:", 0
	.db	1, 14, "Next piece:", 0
	.db	56, 4, "A: move left", 0
	.db	55, 5, "D: move right", 0
	.db	58, 6, "W: rotate", 0
	.db	56, 7, "S: drop", 0
	.db	0FFh

CLRSTR:	.db	2, 16, "           ", 0
	.db	2, 17, "           ", 0
	.db	0FFh

;-----------------------------------------------------------------------

filler:	.db	0
LEVEL:	.db	1	; current level
LCNT:	.db	1	; rows to collect before switching to next level
DLYCON:	.db	1	; delay constant, according to level
DLYCNT:	.db	1
LASTK:	.db	0	; last key
FLROWS:	.dw	2	; rows completed
SHAPES:	.dw	2	; shapes used

ORIENT:	.db	1	; current orientation
CPOS:	.dw	2	; current shape position
NORIEN:	.db	1	; next orientation
NPOS:	.dw	2	; next position
INISHP:	.dw	2	; ptr to current figure, initial orientation
CURSHP:	.dw	2	; ptr to current figure, current orientation
NXTSHP:	.dw	2	; ptr to next figure
TPTR:	.dw	2	; temp pointer, used mostly when drawing figs
LAST:	.db	0	; last figure used, to ensure next one is different
RAND:	.dw	0FD5Ah

BUF:

	.end
