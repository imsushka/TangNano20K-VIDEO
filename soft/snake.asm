	.org	0100h

SCR_POS		= 000Ch
PUT_CHR		= 0FF90h

CR	.equ	0Dh
LF	.equ	0Ah
ESC	.equ	27h
CTRLC	.equ	03h
CTRLZ	.equ	1Ah

XMAX	.equ	64		; playfield size
YMAX	.equ	24

START:
	call	CLS

	ld	h,20
	ld	l,3
	call	SETCUR
	ld	hl,SPDMSG
	call	PUTSTR

wtk:
	call	RND		; to generate different random seq each time
	call	INKEY
	cp	CTRLC
	jp	z,quit
	cp	CTRLZ
	jp	z,quit
	cp	'0'
	jr	c,wtk1
	cp	'9'+1
	jr	c,setspd
wtk1:
	ld	a,10
	call	DELAY
	jr	wtk

setspd:
;	ld	c,a
	ld	b,a
	ld	a,'9'
	sub	b
	inc	a
	ld	b,a
	add	a,a
	add	a,b		; *3
	srl	a		; /2
	ld	(speed),a
;	call	PUTCH
	
; main loop
MLOOP:
	call	CLS

	ld	HL, screen
	LD	B, 65
S2:
	LD	A, '+'
	LD	(HL), A
	CALL	ToScreen
	INC	HL
	DJNZ	S2

	LD	C, 21
S4:
	LD	B, 62
S3:
	LD	A, 0
	LD	(HL), A
	CALL	ToScreen
	INC	HL
	DJNZ	S3

	LD	A, '+'
	LD	(HL), A
	CALL	ToScreen
	INC	HL
	LD	A, '+'
	LD	(HL), A
	CALL	ToScreen
	INC	HL

	DEC	C
	JR	NZ, S4

	LD	B, 63
S5:
	LD	A, '+'
	LD	(HL), A
	CALL	ToScreen
	INC	HL
	DJNZ	S5

	ld	hl, 0
	ld	(eaten), hl
	ld	a, 0
	ld	(len),a		; initial size is 5
	ld	a, 5
	ld	(vLen),a	; inc size is 1
	ld	a, 0
	ld	(tLen),a	; inc size is 1

	ld	hl, snake
	ld	(head),hl	; snake starts at the center of screen
	ld	(tail),hl

	ld	hl,screen + (XMAX / 2) + ((YMAX / 2) * XMAX)
;	ld	(snake),hl
	push	hl
	ld	hl, 1
;	ld	(dir), hl	; and moving right
	push	hl

	call	STATLN
	call	NEWCUK		; new cookie
    
	jp	Game_START

LOOP:	; game loop
	ld	a, (speed)
	call	DELAY

	call	INKEY
	call	UCASE
	cp	CTRLC
	jp	z, quit
	ld	hl, -XMAX
	cp	'W'		; up
	jr	z,k1
	ld	hl, XMAX
	cp	'S'		; down
	jr	z,k1
	ld	hl, 1
	cp	'D'		; right
	jr	z,k1
	ld	hl, -1
	cp	'A'		; left
	jr	z,k1
	ex	(sp), hl
k1:
	pop	bc
	pop	de
	ex	de, hl		; DE = move
	add	hl, de		; HL = to Screen
	push	hl
	push	de

	ld	C, (hl)
	ld	A, 'O'
	ld	(hl), A
	CALL	ToScreen
	ex	de, hl
	ld	hl, (head)
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl

	LD	DE, snake_
	CALL	CPHLDE
	JR	NZ, k2
	ld	hl, snake
k2:
	ld	(head), hl

	ld	a, c
	or	a
	JR	Z, k3
	cp	'@'
	JR	NZ, end_

	ld	hl,(eaten)
	inc	hl
	ld	(eaten),hl

	call	NEWCUK		; new cookie

Game_START:
	ld	a, (tLen)
	ld	C, A
	ld	a, (vLen)
	ADD	A, C
	ld	(tLen), a
k3:
	LD	hl, tLen
	DEC	(HL)
	jp	m, k4

	ld	hl,(len)
	inc	hl
	ld	(len),hl	; store new length

	call	UPDST		; update status

	jp	LOOP
k4:
	inc	(hl)
	ld	hl, (tail)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl

	PUSH	DE
	LD	DE, snake_
	CALL	CPHLDE
	JR	NZ, k5
	ld	hl, snake
k5:
	ld	(tail), hl
	POP	HL
	xor	a
	ld	(HL), a
	CALL	ToScreen

	jp	LOOP

end_:
	POP	BC
	POP	BC
	jr	CRASH

CRASH:	; snake crashed

	ld	hl,(head)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	EX	DE, HL
	ld	a,'*'
	CALL	ToScreen
	ld	h,30
	ld	l,3
	call	SETCUR
	ld	hl,CMSG
	call	PUTSTR
	ld	h,26
	ld	l,5
	call	SETCUR
	ld	hl,AGMSG
	call	PUTSTR

WNXT:	call	GETCH		; wait for key
	cp	CTRLC
	jp	z,quit
	cp	CTRLZ
	jp	z,quit
	call	UCASE
	cp	'N'
	jp	z,quit
	cp	'Y'
	jp	z,MLOOP
	jr	WNXT

quit:	call	CLS
	ld	hl,0
	call	SETCUR
	jp	0

SPDMSG:	.db	"Enter speed (0-9): ",0
CMSG:	.db	" C R A S H !!! ",0
AGMSG:	.db	" Another game (Y/N) ? ",0

; Generate random number in the 0..A-1 range

RND:	push	af
	ld	bc,(rseed)
	ld	de,61069
	call	MULT16
	inc	hl
	ld	(rseed),hl	; rseed = rseed * 61069 + 1
	ld	e,h
	pop	af
	ld	d,a
	call	DIV8		; rnd = (rseed >> 8) % A
	ld	a,c
	ret

; DEHL = DE * BC

MULT16:	ld	hl,0
	ld	a,16
mu1:	add	hl,hl
	rl	e
	rl	d
	jr	nc,mu2
	add	hl,bc
	jr	nc,mu2
	inc	de
mu2:	dec	a
	jr	nz,mu1
	ret

; H = E / D, remainder in C

DIV8:	ld	b,8
	ld	c,0
next:	rl	e
	ld	a,c
	rla
	sub	d
	jr	nc,noadd
	add	a,d
noadd:	ld	c,a
	ccf
	rl	h
	djnz	next
	ret

; Display status line

STATLN:
	ld	h,0
	ld	l,23
	call	SETCUR
	ld	b,64
invln:	
	ld	a,' '
	call	PUTCH		; put bottom line in reverse video
	djnz	invln

	ld	h,10
	ld	l,23
	call	SETCUR
	ld	hl,STMSG1
	call	PUTSTR
	ld	h,31
	ld	l,23
	call	SETCUR
	ld	hl,STMSG2
	call	PUTSTR
UPDST:
	ld	h,18
	ld	l,23
	call	SETCUR
	ld	hl,(len)
	xor	a
	call	HLDEC
	ld	h,38
	ld	l,23
	call	SETCUR
	ld	hl,(eaten)
	xor	a
	JP	HLDEC

STMSG1:	.db	"Length:",0
STMSG2:	.db	"Eaten:",0

; Get new cookie

NEWCUK:
	ld	a,XMAX-2
	call	RND	
	inc	a
	rlca
	rlca
	ld	l,a
	ld	a,YMAX-2
	push	hl
	call	RND
	pop	hl
	inc	a
	ld	h,a
	srl	h
	rr	l
	srl	h
	rr	l
	LD	BC, screen
	ADD	HL, BC
	LD	A, (HL)
	OR	A
	jr	nz,NEWCUK

	LD	A, '@'
	LD	(HL), A
	call	ToScreen

	ld	a, 9
	call	RND
	inc	a
	ld	(vLen),a
	ret

ToScreen:
        PUSH	BC
        PUSH	HL

        PUSH	AF

	XOR	A
	LD	BC, screen
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

	POP	AF
	CALL	PUT_CHR

	POP	HL
	POP	BC
	RET
;-----------------------------------------------------------------------
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
ADEC:
	push	de
	push	bc
	ld	d, 0
	ld	b, 100
	call	ad1
	ld	b, 10
	call	ad1
	add	a, '0'
	call	PUTCH
;	inc	d
;	ld	a, d		; return length in A
	pop	bc
	pop	de
	ret

ad1:
	ld	c,'0'-1
ad2:
	inc	c
	sub	b
	jr	nc, ad2
	add	a, b
	push	af
	ld	a, c
	cp	'0'
	jr	nz, ad4
	inc	d
	dec	d
	jr	z, ad5
ad4:
	call	PUTCH
	inc	d
ad5:
	pop	af
	ret

HLDEC:
	ld	(filler), a
	push	hl
	push	de
	push	bc
	ld	b,0
	ld	de,-10000
	call	sbcnt
	ld	de,-1000
	call	sbcnt
	ld	de,-100
	call	sbcnt
	ld	de,-10
	call	sbcnt
	ld	a,l
	add	a,'0'
;	ld	c,a
	call	PUTCH
	inc	b
	res	7,b
	ld	a,b		; return length in A
	pop	bc
	pop	de
	pop	hl
	ret

sbcnt:
	ld	c, '0'-1
sb1:
	inc	c
	add	hl, de
	jr	c, sb1
	sbc	hl, de
	bit	7, b
	jr	nz, sb3
	ld	a, c
	cp	'0'
	jr	nz, sb2
	ld	a, (filler)
	or	a
	ret	z
	ld	c, a
	jr	sb3
sb2:
	set	7, b
sb3:
	ld	a, c
	call	PUTCH
	inc	b
	ret

CPHLDE:	ld	a,d
	cp	h
	ret	nz
	ld	a,e
	cp	l
	ret

DELAY:
	ld	c,a
d0:
	ld	b,30		; speed
d1:
	push	bc
	ld	bc,0100h
d2:
	dec	bc
	ld	a,b
	or	c
	jr	nz,d2
	pop	bc
	djnz	d1
	dec	c
	jr	nz,d0
	ret

UCASE:	cp	'a'
	ret	c
	cp	'z'+1
	ret	nc
	and	5Fh
	ret

;TTFLSH:
;	ret
PUTCH:
	PUSH	HL
	LD	HL, (SCR_POS)
	CALL	PUT_CHR
	INC	HL
	LD	(SCR_POS), HL
	POP	HL
	RET

SETCUR:
	LD	A, L
	LD	L, H
	LD	H, A
	LD	(SCR_POS), HL
	RET
CLS:
	JP	0FD00h
	RET
;CRLF:
;	ld	a,CR
;	call	PUTCH
;	ld	a,LF
;	call	PUTCH
;	RET
INKEY:
	RST	18h
	LD	A, 0
	RET	Z
GETCH:
	RST	10h
	RET
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
	POP	DE
	RET
;-----------------------------------------------------------------------


speed:	.DB	0
len:	.DW	0
vLen:	.DB	0
tLen:	.DB	0
eaten:	.DW	0

cookie:	.DW	0
cval:	.DB	0

head:	.DW	0
tail:	.DW	0
dir:	.DW	0

rseed:	.dw	22095
filler:	.db	0

screen:	= $
snake:	= screen + (XMAX * YMAX)
snake_:	= snake + ((XMAX * YMAX) * 2)

	.end
