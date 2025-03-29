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

MAPW		= 64
MAPH		= 47

; some fixed map addresses

PMIPOS		= MAPW * 17 + 31 	; X=28, Y=17 - initial pacman position
                        
G1IPOS		= MAPW * 10 + 28 	; X=25, Y=10 - initial ghost 1 position
G2IPOS		= MAPW * 10 + 30 	; X=27, Y=10 - initial ghost 2 position
G3IPOS		= MAPW * 10 + 32 	; X=29, Y=10 - initial ghost 3 position
G4IPOS		= MAPW * 10 + 34 	; X=31, Y=10 - initial ghost 4 position
                        
G1RPOS		= MAPW * 8 + 28 	; X=25, Y=8  - initial released ghost 1 pos
G2RPOS		= MAPW * 8 + 30 	; X=27, Y=8  - initial released ghost 2 pos
G3RPOS		= MAPW * 8 + 32 	; X=29, Y=8  - initial released ghost 3 pos
G4RPOS		= MAPW * 8 + 34 	; X=31, Y=8  - initial released ghost 4 pos
                        
CDYPOS		= MAPW * 12 + 31 	; X=28, Y=12 - candy position
                        
LDOOR		= MAPW * 10 + 0 	; X=0,  Y=10 - left door
RDOOR		= MAPW * 10 + 62 	; X=56, Y=10 - right door

STATLINE	= MAPH

;--------------------------------------------------------------------------
	.org	0100h

	LD	A, 01h	; 8x8, Font 1bit, Scale x2
;	LD	A, 11h	; 8x16, Font 1bit, Scale x2
	OUT	(0F7h), A

	LD	hl, 0
	LD	(SCR_POS), HL
	LD	(SCR_SCROLL), HL

	call	CLS		; clear screen
	ld	a,1
	ld	(LEVEL),a	; default level
NEWGAM:
	ld	a,'a'
	ld	(CDYC),a	; init candy char
	xor	a
	ld	(CDCOLN),a
	ld	l,36		; coordinates of collected candies on screen
	ld	h, STATLINE
	ld	(CDCOLX),hl
	ld	l,24
	ld	h,10
	LD	(SCR_POS), HL
	ld	hl,LVLMSG	; 'Level?'
	call	PUTSTR
gc1:
	call	GETCH
	cp	3		; ^C = exit
	jp	z,QUIT
	cp	' '		; space = use previous level
	jr	z,gc2
	cp	'0'
	jr	c,gc1
	cp	'9'+1
	jr	nc,gc1
;	push	af
;	call	PUTCH
;	pop	af
	sub	'0'-1
	ld	(LEVEL),a	; store level
gc2:
;	ld	l,24
;	ld	h,10
;	LD	(SCR_POS), HL
;	ld	hl,LVLCLR
;	call	PUTSTR

	xor	a
	ld	(LIVES),a
	call	INITSC
INIMAP:
	ld	hl,0
	ld	(NDOTS),hl
	LD	(SCR_POS), HL
	ld	hl,MAP1	; game map
	ld	de,PLAYFL
	ld	c,MAPH-1
	push	bc
CP1:
	ld	b,MAPW
CP2:
	ld	a,(hl)
	cp	'.'
	jr	nz,CP23
	LD	A, 07h
	call	PUTCHR		; draw map
	LD	A, '.'
	JR	CP21
CP23:
	call	PUTCHR		; draw map
	cp	'a'
	jr	c,CP21
	ld	a,'+'
CP21:
;	call	PUTCHR		; draw map
	ld	(de),a
	cp	'.'
	call	z,CNTDOT	; count dots
	inc	hl
	inc	de
	djnz	CP2
	pop	bc
	dec	c
	jr	z,CP3
	push	bc
	push	hl
	LD	HL, (SCR_POS)
	LD	L, 0
	INC	H
	LD	(SCR_POS), HL
	pop	hl
	jr	CP1
CP3:
	ld	l,22
	ld	h,10
	LD	(SCR_POS), HL
	ld	hl,TITLE	; 'Pacman'
	call	PUTSTR

	ld	l,33
	ld	h,10
	LD	(SCR_POS), HL
	ld	hl,LVLO
	call	PUTSTR
	ld	l,38
	ld	h,10
	LD	(SCR_POS), HL
	ld	A, (LEVEL)
	add	A, '0'-1
	call	PUTCH
	call	LDELAY

	ld	l,0
	ld	h, STATLINE
	LD	(SCR_POS), HL
	ld	hl,LIVMSG	; 'LIVES'
	call	PUTSTR
	ld	l,10
	ld	h, STATLINE
	LD	(SCR_POS), HL
	ld	hl,SCMSG	; 'SCORE'
	call	PUTSTR
	call	SHOWSC
	ld	l,23
	ld	h, STATLINE
	LD	(SCR_POS), HL
	ld	hl,HSCMSG	; 'HIGH'
	call	PUTSTR
	call	UPDHIS
	ld	a,(LIVES)
	or	a
	jr	nz,skipl
	ld	a,'3'		; initial lives = 3
	ld	(LIVES),a
skipl:
	call	SHOWLV
	ld	hl,(NDOTS)
;	dec	hl
;	dec	hl
;	dec	hl
;	dec	hl
	ld	(NDOTS),hl	; dots to collect
NEXTL:	xor	a
	ld	(LASTD),a	; clear last pacman dir (key)
	ld	(LASTK),a	; clear last key
	ld	(CDYTM),a	; clear candy timer
	ld	(PILLTM),a	; clear pill (potion) active time
	ld	(GSDCNT),a
	ld	(SDCNT),a
	ld	a,' '
	ld	(PLAYFL + G1IPOS),a	; clear confined ghosts
	ld	(PLAYFL + G2IPOS),a
	ld	(PLAYFL + G3IPOS),a
	ld	(PLAYFL + G4IPOS),a
	ld	(PLAYFL + CDYPOS),a	; clear candy
	ld	(G1SAVC),a
	ld	(G1SAV2),a
	ld	(G2SAVC),a
	ld	(G2SAV2),a
	ld	(G3SAVC),a
	ld	(G3SAV2),a
	ld	(G4SAVC),a
	ld	(G4SAV2),a
	ld	hl, PLAYFL + PMIPOS	; initial pacman position
	ld	(PACLOC),hl	; store pacman location
	ld	h,17
	ld	l,31
	ld	(PACX),hl
	call	RSTG1		; reset ghost 1
	call	RSTG2		; reset ghost 2
	call	RSTG3		; reset ghost 3
	call	RSTG4		; reset ghost 4
	call	LVLDLY		; delay according to level
	ld	a,18		; time before ghosts escape from confinement
	ld	(JAILTM),a
	call	INITCH		; init and display characters
MLOOP:
	call	INKEY
	cp	3		; ^C?
	jp	z,QUIT
	call	UCASE
	cp	'P'		; pause?
	call	z,PAUSE
	or	a
	jr	z,m1
	ld	(LASTK),a	; store last key
m1:
	call	CHKMOV
	call	DOPILL		; check pill activity
	call	LVLDLY		; delay according to level
	ld	a,(PILLTM)
	or	a		; pill active?
	jr	z,m2		; branch if not
	ld	a,(GSDCNT)
	inc	a
	ld	(GSDCNT),a
	cp	2		; slow down ghosts while pill is active
	jr	c,m2
	xor	a
	ld	(GSDCNT),a
	jr	skpg
m2:
	ld	a,(JAILTM)
	or	a
	jr	z,m3
	dec	a
	ld	(JAILTM),a
	jr	skpg
m3:
	ld	a,(G3DEAD)
	or	a
	call	z,G3MOV		; process ghost 3 if alive
	ld	a,(G1DEAD)
	or	a
	call	z,G1MOV		; process ghost 1 if alive
	ld	a,(G2DEAD)
	or	a
	call	z,G2MOV		; process ghost 2 if alive
	ld	a,(G4DEAD)
	or	a
	call	z,G4MOV		; process ghost 4 if alive
skpg:
	call	CANDY		; process candy
	ld	a,(SDCNT)
	cp	2		; pacman slows down when eating dots
	jr	nz,m4
	xor	a
	ld	(SDCNT),a
;;	jr	m1		; loop
	jr	MLOOP

m4:
	ld	a,(LASTD)	; check last pacman direction
	cp	'A'
	jp	z,GOLEFT
	cp	'D'
	jp	z,GORGHT
	cp	'W'
	jp	z,GOUP
	cp	'S'
	jp	z,GODOWN
	jp	MLOOP

QUIT:
	call	CLS
	jp	0

CNTDOT:
	push	hl
	ld	hl,(NDOTS)
	inc	hl
	ld	(NDOTS),hl
	pop	hl
	ret

; Process player (pacman)
GOLEFT:
	ld	hl,(PACLOC)	; get pacman address
	ld	de,PACX
	call	CHKLD		; check left door
	dec	hl		; point to left cell
	call	CHKOBJ
	ld	a,(PACCHR)
	ld	(hl),a
	ld	(PACLOC),hl	; store new pacman address
	inc	hl
	ld	(hl),' '
	ld	hl,(PACX)
	ld	e,l
	ld	d,h
	dec	l		; --X
	ld	(PACX),hl
	ld	a,(PACCHR)
	ld	c,a
	ld	b,' '
	call	MOVOBJ
	jp	MLOOP

GORGHT:
	ld	hl,(PACLOC)	; get pacman address
	ld	de,PACX
	call	CHKRD		; check right door
	inc	hl
	call	CHKOBJ
	ld	a,(PACCHR)
	ld	(hl),a
	ld	(PACLOC),hl	; store new pacman address
	dec	hl
	ld	(hl),' '
	ld	hl,(PACX)
	ld	e,l
	ld	d,h
	inc	l		; ++X
	ld	(PACX),hl
	ld	a,(PACCHR)
	ld	c,a
	ld	b,' '
	call	MOVOBJ
	jp	MLOOP

GOUP:
	ld	hl,(PACLOC)	; get pacman address
	call	LNUP		; HL -= MAPW
	call	CHKOBJ
	ld	a,(PACCHR)
	ld	(hl),a
	ld	(PACLOC),hl	; store new pacman address
	call	LNDN		; HL += MAPW
	ld	(hl),' '
	ld	hl,(PACX)
	ld	e,l
	ld	d,h
	dec	h		; --Y
	ld	(PACX),hl
	ld	a,(PACCHR)
	ld	c,a
	ld	b,' '
	call	MOVOBJ
	jp	MLOOP

GODOWN:
	ld	hl,(PACLOC)	; get pacman address
	call	LNDN		; HL += MAPW
	call	CHKOBJ
	ld	a,(PACCHR)
	ld	(hl),a
	ld	(PACLOC),hl	; store new pacman address
	call	LNUP		; HL -= MAPW
	ld	(hl),' '
	ld	hl,(PACX)
	ld	e,l
	ld	d,h
	inc	h		; ++Y
	ld	(PACX),hl
	ld	a,(PACCHR)
	ld	c,a
	ld	b,' '
	call	MOVOBJ
	jp	MLOOP

; Move object on screen
;  HL = new coords, C = obj char
;  DE = old coords, B = erase char
MOVOBJ:
	ld	a,c
	CALL	PUT_CHR
	ex	de,hl
	ld	a,b
	JP	PUT_CHR

CLROBJ:
	ld	a,' '
	JP	PUT_CHR

; Check for nearby objects as pacman moves
CHKOBJ:
	ld	a,(hl)
	cp	'+'		; wall
	jr	z,WALL
	cp	'A'		; eatable ghost 1
	call	z,EATG1
	cp	'1'
	call	z,EATG1
	cp	'B'		; eatable ghost 2
	call	z,EATG2
	cp	'2'
	call	z,EATG2
	cp	'C'		; eatable ghost 3
	call	z,EATG3
	cp	'3'
	call	z,EATG3
	cp	'D'		; eatable ghost 4
	call	z,EATG4
	cp	'4'
	call	z,EATG4
	cp	'.'		; dot
	call	z,EATDOT
	ld	e,a
	ld	a,(CDYC)	; candy
	cp	e
	call	z,EATCDY
	ld	a,e
	cp	'&'		; ghost 1
	jp	z,DEAD
	cp	'$'		; ghost 2
	jp	z,DEAD
	cp	'#'		; ghost 3
	jp	z,DEAD
	cp	'@'		; ghost 4
	jp	z,DEAD
	cp	'S'		; pill (potion)
	call	z,EATPIL
	ret
WALL:
	inc	sp		; can't move further, drop return address
	inc	sp
	jp	MLOOP

EATDOT:
	ld	a,(SDCNT)
	inc	a
	ld	(SDCNT),a
	ld	bc,(NDOTS)
	dec	bc
	ld	(NDOTS),bc
	ld	a,b
	or	c
	jp	nz,INS1		; inc score by 1 and return
	ld	(hl),'O'
	ld	hl,(PACLOC)	; get pacman address
	ld	(hl),' '	; erase it from old location
	call	LDELAY
	ld	hl,CDYC
	ld	a,(hl)
	cp	'n'
	jr	z,ed1
	inc	(hl)		; next candy char
ed1:
	ld	hl,LIVES	; increase number of lives
	inc	(hl)
	call	SHOWLV		; display it
	ld	a,(LEVEL)	; get level
	dec	a
	jr	z,ed2		; don't go below 1
	ld	(LEVEL),a	; store new level
ed2:
	inc	sp		; drop return address
	inc	sp
	jp	INIMAP		; reset map and restart

; Show remaining lives
SHOWLV:
	ld	l,8
	ld	h, STATLINE
	ld	a,(LIVES)
	JP	PUT_CHR

; Show score
SHOWSC:
	ld	l,16
	ld	h, STATLINE
	LD	(SCR_POS), HL
	ld	hl,SCORE
	ld	b,5
SC1:
	ld	a,(hl)
	call	PUTCH
	inc	hl
	djnz	SC1
	RET

; Clear score
INITSC:
	ld	hl,SCORE
	ld	b,5
clsc:
	ld	(hl),'0'
	inc	hl
	djnz	clsc
	ret

; Increase score
;   INS1 - inc by 1
;   INS100 - inc by 100
; Score field must have been initialized to all ASCII '0's.
; Gets a new life every 1000 points
INS1:
	push	hl
	ld	hl,SCORE+4
	call	INC1
	call	SHOWSC
	pop	hl
	ret

INS100:
	push	hl
	ld	hl,SCORE+2
	call	INC100
	call	SHOWSC
	pop	hl
	ret

INC1:
	ld	a,(hl)
	cp	'9'
	jr	nz,INCDIG
	ld	(hl),'0'
	dec	hl
	ld	a,(hl)
	cp	'9'
	jr	nz,INCDIG
	ld	(hl),'0'
	dec	hl
INC100:
	ld	a,(hl)
	cp	'9'
	jr	nz,INCDIG
	push	hl
	ld	hl,LIVES	; got a new life
	inc	(hl)
	call	SHOWLV
	pop	hl
	ld	(hl),'0'
	dec	hl
	ld	a,(hl)
	cp	'9'
	jr	nz,INCDIG
	ld	(hl),'0'
	dec	hl
	ld	a,(hl)
	cp	'9'
	ret	z
INCDIG:
	inc	a
	ld	(hl),a
	ret

; See if pacman can move
CHKMOV:
	ld	a,(LASTK)	; get last key
	ld	c,a
	ld	hl,(PACLOC)	; get pacman address
	cp	'A'		; left
	jr	z,CKLEFT
	cp	'D'		; right
	jr	z,CKRGHT
	cp	'W'		; up
	jr	z,CKUP
	cp	'S'		; down
	jr	z,CKDOWN
	ret

CKLEFT:
	dec	hl
	jr	CHKWAL		; check for wall
CKRGHT:
	inc	hl
	jr	CHKWAL		; check for wall
CKUP:
	call	LNUP		; HL -= MAPW
	jr	CHKWAL		; check for wall
CKDOWN:
	call	LNDN		; HL += MAPW
CHKWAL:
	ld	a,(hl)
	cp	'+'
	ret	z
	cp	'X'
	ret	z
	ld	a,c
	ld	(LASTD),a	; remember pacman direction
	ret

; Process candy
CANDY:
	ld	a,(CDYTM)
	inc	a		; increment timer
	ld	(CDYTM),a
	jr	z,cdyoff
	cp	214
	ret	nz
;	ld	hl,PLAYFL + CDYPOS
	ld	a,(CDYC)
	ld	(PLAYFL + CDYPOS),a
;	ld	(hl),a		; show candy
	ld	l,31
	ld	h,12
	jp	PUT_CHR
cdyoff:
	ld	a,' '		; clear candy
	ld	(PLAYFL + CDYPOS),a
	ld	l,31
	ld	h,12
	jp	PUT_CHR

; Eat the candy
EATCDY:
	push	hl
	ld	a,(CDCOLN)
;	cp	4		; max 4 collected candies per row
;	jp	nz,ec1
;	ld	a,1
;	ld	(CDCOLN),a
;	ld	hl,(CDCOLX)
;	ld	l,59		; reset X coord
;	inc	h		; inc Y
;	ld	(CDCOLX),hl
;	jr	ec2
;ec1:
	inc	a
	ld	(CDCOLN),a
	ld	hl,(CDCOLX)
ec2:
	LD	(SCR_POS), HL
	ld	a,(CDYC)
	call	PUTCH		; display collected candy
	inc	l
;	inc	l		; X += 2
	ld	(CDCOLX),hl
	pop	hl
	call	INS100		; increase score by 100
	jp	INS100		; increase score by 100 (200 total)

; Process ghost 1
G1MOV:
	ld	a,(G1DIR)
	or	a
	jp	z,G1LEFT
	dec	a
	jp	z,G1RGHT
	dec	a
	jp	z,G1UP
	ld	hl,(G1LOC)	; ghost 1 location
	call	LNDN		; HL += MAPW
	call	G1HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G1SAV2),a	; save char under overlapping ghost, if any
	call	G1CWP		; check for wall or pacman
	ld	a,(G1CHR)
	ld	(hl),a		; move ghost
	ld	c,a
	ld	(G1LOC),hl	; ghost 1 location
	call	LNUP		; HL -= MAPW
	ld	a,(G1SAVC)	; char under ghost 1
	ld	(hl),a		; restore prev ghost cell
	ld	b,a
	ld	hl,(G1X)
	ld	e,l
	ld	d,h
	inc	h
	ld	(G1X),hl
	jp	G1DONE

G1LEFT:	ld	hl,(G1LOC)	; ghost 1 location
	dec	hl
	call	G1HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G1SAV2),a	; save char under overlapping ghost, if any
	call	G1CWP		; check for wall or pacman
	ld	a,(G1CHR)
	ld	(hl),a		; move ghost
	ld	c,a
	ld	(G1LOC),hl	; ghost 1 location
	inc	hl
	ld	a,(G1SAVC)	; char under ghost 1
	ld	(hl),a		; restore prev ghost cell
	ld	b,a
	ld	hl,(G1X)
	ld	e,l
	ld	d,h
	dec	l
	ld	(G1X),hl
	jp	G1DONE

G1RGHT:	ld	hl,(G1LOC)	; ghost 1 location
	inc	hl
	call	G1HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G1SAV2),a	; save char under overlapping ghost, if any
	call	G1CWP		; check for wall or pacman
	ld	a,(G1CHR)
	ld	(hl),a
	ld	c,a
	ld	(G1LOC),hl	; ghost 1 location
	dec	hl
	ld	a,(G1SAVC)	; char under ghost 1
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G1X)
	ld	e,l
	ld	d,h
	inc	l
	ld	(G1X),hl
	jp	G1DONE

G1UP:	ld	hl,(G1LOC)	; ghost 1 location
	call	LNUP		; HL -= MAPW
	call	G1HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G1SAV2),a	; save char under overlapping ghost, if any
	call	G1CWP		; check for wall or pacman
	ld	a,(G1CHR)
	ld	(hl),a
	ld	c,a
	ld	(G1LOC),hl	; ghost 1 location
	call	LNDN		; HL += MAPW
	ld	a,(G1SAVC)	; char under ghost 1
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G1X)
	ld	e,l
	ld	d,h
	dec	h
	ld	(G1X),hl
G1DONE:	call	MOVOBJ
	ld	a,(G1SAV2)
	ld	(G1SAVC),a	; char under ghost 1
	ret

; ghost 1 - check for wall of pacman

G1CWP:	cp	'O'
	jp	z,DEAD0
	cp	'+'
	ret	nz
	inc	sp		; drop return address
	inc	sp
	ld	bc,G1DIR
	ld	a,(bc)
	cp	2
	jp	p,g12
	ld	a,(PACY)
	ld	e,a
	ld	a,(G1Y)
	sub	e
	jp	p,g11
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWUP		; check turn up
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWDN		; check turn down
g11:
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWDN		; check turn down
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWUP		; check turn up
g12:
	ld	a,(PACX)
	ld	e,a
	ld	a,(G1X)
	sub	e
	jp	p,g13
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWRGT		; check turn right
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWLFT		; check turn left
g13:
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWLFT		; check turn left
	ld	hl,(G1LOC)	; ghost 1 location
	call	CWRGT		; check turn right
	ret

; Process ghost 2

G2MOV:	ld	a,(G2DIR)
	or	a
	jp	z,G2LEFT
	dec	a
	jp	z,G2RGHT
	dec	a
	jp	z,G2UP
	ld	hl,(G2LOC)	; ghost 2 location
	call	LNDN		; HL += MAPW
	call	G2HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G2SAV2),a	; save char under overlapping ghost, if any
	call	G2CWP		; check for wall or pacman
	ld	a,(G2CHR)
	ld	(hl),a
	ld	c,a
	ld	(G2LOC),hl	; ghost 2 location
	call	LNUP		; HL -= MAPW
	ld	a,(G2SAVC)	; char under ghost 2
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G2X)
	ld	e,l
	ld	d,h
	inc	h
	ld	(G2X),hl
	jp	G2DONE

G2LEFT:	ld	hl,(G2LOC)	; ghost 2 location
	ld	de,G2X
	call	CHKLD		; check left door
	dec	hl
	call	G2HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G2SAV2),a	; save char under overlapping ghost, if any
	call	G2CWP		; check for wall or pacman
	ld	a,(G2CHR)
	ld	(hl),a
	ld	c,a
	ld	(G2LOC),hl	; ghost 2 location
	inc	hl
	ld	a,(G2SAVC)	; char under ghost 2
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G2X)
	ld	e,l
	ld	d,h
	dec	l
	ld	(G2X),hl
	jp	G2DONE

G2RGHT:	ld	hl,(G2LOC)	; ghost 2 location
	ld	de,G2X
	call	CHKRD		; check right door
	inc	hl
	call	G2HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G2SAV2),a	; save char under overlapping ghost, if any
	call	G2CWP		; check for wall or pacman
	ld	a,(G2CHR)
	ld	(hl),a
	ld	c,a
	ld	(G2LOC),hl	; ghost 2 location
	dec	hl
	ld	a,(G2SAVC)	; char under ghost 2
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G2X)
	ld	e,l
	ld	d,h
	inc	l
	ld	(G2X),hl
	jp	G2DONE

G2UP:	ld	hl,(G2LOC)	; ghost 2 location
	call	LNUP		; HL -= MAPW
	call	G2HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G2SAV2),a	; save char under overlapping ghost, if any
	call	G2CWP		; check for wall or pacman
	ld	a,(G2CHR)
	ld	(hl),a
	ld	c,a
	ld	(G2LOC),hl	; ghost 2 location
	call	LNDN		; HL += MAPW
	ld	a,(G2SAVC)	; char under ghost 2
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G2X)
	ld	e,l
	ld	d,h
	dec	h
	ld	(G2X),hl
G2DONE:	call	MOVOBJ
	ld	a,(G2SAV2)
	ld	(G2SAVC),a	; char under ghost 2
	jp	g21

; ghost 2 - check for wall or pacman

G2CWP:	cp	'O'
	jp	z,DEAD0
	cp	'+'
	ret	nz
	inc	sp
	inc	sp
	ld	a,1
	ld	(G1WALL),a
g21:	ld	bc,G2DIR
	ld	a,(bc)
	cp	2
	jp	m,g24
	ld	a,(PACX)
	ld	e,a
	ld	a,(G2X)
	sub	e
	call	z,g22
	ld	a,(G2X)
	sub	e
	jp	p,g23
	ld	hl,(G2LOC)	; ghost 2 location
	call	CWRGT		; check turn right
	ld	a,(G1WALL)
	dec	a
	ret	nz
	ld	(G1WALL),a
	ld	hl,(G2LOC)	; ghost 2 location
	call	CWLFT		; check turn left
	ret

g22:	ld	a,(G1WALL)
	dec	a
	ret	z
	inc	sp		; drop return address
	inc	sp
	ret			; return one level higher

g23:	ld	hl,(G2LOC)	; ghost 2 location
	call	CWLFT		; check turn left
	ld	a,(G1WALL)
	dec	a
	ret	nz
	ld	(G1WALL),a
	ld	hl,(G2LOC)	; ghost 2 location
	call	CWRGT		; check turn right
	ret

g24:	ld	a,(PACY)
	ld	e,a
	ld	a,(G2Y)
	sub	e
	call	z,g22
	ld	a,(G2Y)
	sub	e
	jp	p,g25
	ld	hl,(G2LOC)	; ghost 2 location
	call	CWUP		; check turn up
	ld	a,(G1WALL)
	dec	a
	ret	nz
	ld	(G1WALL),a
	ld	hl,(G2LOC)	; ghost 2 location
	call	CWDN		; check turn down
	ret

g25:	ld	hl,(G2LOC)	; ghost 2 location
	call	CWDN		; check turn down
	ld	a,(G1WALL)
	dec	a
	ret	nz
	ld	(G1WALL),a
	ld	hl,(G2LOC)	; ghost 2 location
	call	CWUP		; check turn up
	ret

; Process ghost 3

G3MOV:	ld	a,(G3DIR)
	or	a
	jp	z,G3LEFT
	dec	a
	jp	z,G3RGHT
	dec	a
	jp	z,G3UP
	ld	hl,(G3LOC)	; ghost 3 location
	call	LNDN		; HL += MAPW
	call	G3HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G3SAV2),a	; save char under overlapping ghost, if any
	call	G3CWP		; check for wall or pacman
	ld	a,(G3CHR)
	ld	(hl),a
	ld	c,a
	ld	(G3LOC),hl	; ghost 3 location
	call	LNUP		; HL -= MAPW
	ld	a,(G3SAVC)	; char under ghost 3
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G3X)
	ld	e,l
	ld	d,h
	inc	h
	ld	(G3X),hl
	jp	G3DONE

G3LEFT:	ld	hl,(G3LOC)	; ghost 3 location
	ld	de,G3X
	call	CHKLD		; check left door
	dec	hl
	call	G3HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G3SAV2),a	; save char under overlapping ghost, if any
	call	G3CWP		; check for wall or pacman
	ld	a,(G3CHR)
	ld	(hl),a
	ld	c,a
	ld	(G3LOC),hl	; ghost 3 location
	inc	hl
	ld	a,(G3SAVC)	; char under ghost 3
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G3X)
	ld	e,l
	ld	d,h
	dec	l
	ld	(G3X),hl
	jp	G3DONE

G3RGHT:	ld	hl,(G3LOC)	; ghost 3 location
	ld	de,G3X
	call	CHKRD		; check right door
	inc	hl
	call	G3HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G3SAV2),a	; save char under overlapping ghost, if any
	call	G3CWP		; check for wall or pacman
	ld	a,(G3CHR)
	ld	(hl),a
	ld	c,a
	ld	(G3LOC),hl	; ghost 3 location
	dec	hl
	ld	a,(G3SAVC)	; char under ghost 3
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G3X)
	ld	e,l
	ld	d,h
	inc	l
	ld	(G3X),hl
	jp	G3DONE

G3UP:	ld	hl,(G3LOC)	; ghost 3 location
	call	LNUP		; HL -= MAPW
	call	G3HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G3SAV2),a	; save char under overlapping ghost, if any
	call	G3CWP		; check for wall or pacman
	ld	a,(G3CHR)
	ld	(hl),a
	ld	c,a
	ld	(G3LOC),hl	; ghost 3 location
	call	LNDN		; HL += MAPW
	ld	a,(G3SAVC)	; char under ghost 3
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G3X)
	ld	e,l
	ld	d,h
	dec	h
	ld	(G3X),hl
G3DONE:	call	MOVOBJ
	ld	a,(G3SAV2)
	ld	(G3SAVC),a	; char under ghost 3
	ld	a,(CDYTM)	; candy timer (used here as random number)
	ld	e,a
	ld	a,(PACX)
	xor	e
	ld	e,a
	ld	a,(PACY)
	xor	e
	and	1
	ret	z
	jp	g31

; ghost 3 - check for wall or pacman

G3CWP:	cp	'O'
	jp	z,DEAD0
	cp	'+'
	ret	nz
	inc	sp
	inc	sp
g31:	ld	bc,G3DIR
	ld	a,(bc)
	cp	2
	jp	m,g33
	ld	a,(PACX)
	ld	e,a
	ld	a,(G3X)
	sub	e
	jp	p,g32
	ld	hl,(G3LOC)	; ghost 3 location
	call	CWRGT		; check turn right
	ld	hl,(G3LOC)	; ghost 3 location
	call	CWLFT		; check turn left
	ret

g32:	ld	hl,(G3LOC)	; ghost 3 location
	call	CWLFT		; check turn left
	ld	hl,(G3LOC)	; ghost 3 location
	call	CWRGT		; check turn right
	ret

g33:	ld	a,(PACY)
	ld	e,a
	ld	a,(G3Y)
	sub	e
	jp	p,g34
	ld	hl,(G3LOC)	; ghost 3 location
	call	CWUP		; check turn up
	ld	hl,(G3LOC)	; ghost 3 location
	call	CWDN		; check turn down
	ret

g34:	ld	hl,(G3LOC)	; ghost 3 location
	call	CWDN		; check turn down
	ld	hl,(G3LOC)	; ghost 3 location
	call	CWUP		; check turn up
	ret

; Process ghost 4

G4MOV:
	ld	a,(G4DIR)
	or	a
	jp	z,G4LEFT
	dec	a
	jp	z,G4RGHT
	dec	a
	jp	z,G4UP
	ld	hl,(G4LOC)	; ghost 4 location
	call	LNDN		; HL += MAPW
	call	G4HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G4SAV2),a	; save char under overlapping ghost, if any
	call	G4CWP		; check for wall or pacman
	ld	a,(G4CHR)
	ld	(hl),a
	ld	c,a
	ld	(G4LOC),hl	; ghost 4 location
	call	LNUP		; HL -= MAPW
	ld	a,(G4SAVC)	; char under ghost 4
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G4X)
	ld	e,l
	ld	d,h
	inc	h
	ld	(G4X),hl
	jp	G4DONE

G4LEFT:
	ld	hl,(G4LOC)	; ghost 4 location
	ld	de,G4X
	call	CHKLD		; check left door
	dec	hl
	call	G4HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G4SAV2),a	; save char under overlapping ghost, if any
	call	G4CWP		; check for wall or pacman
	ld	a,(G4CHR)
	ld	(hl),a
	ld	c,a
	ld	(G4LOC),hl	; ghost 4 location
	inc	hl
	ld	a,(G4SAVC)	; char under ghost 4
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G4X)
	ld	e,l
	ld	d,h
	dec	l
	ld	(G4X),hl
	jp	G4DONE

G4RGHT:
	ld	hl,(G4LOC)	; ghost 4 location
	ld	de,G4X
	call	CHKRD		; check right door
	inc	hl
	call	G4HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G4SAV2),a	; save char under overlapping ghost, if any
	call	G4CWP		; check for wall or pacman
	ld	a,(G4CHR)
	ld	(hl),a
	ld	c,a
	ld	(G4LOC),hl	; ghost 4 location
	dec	hl
	ld	a,(G4SAVC)	; char under ghost 4
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G4X)
	ld	e,l
	ld	d,h
	inc	l
	ld	(G4X),hl
	jp	G4DONE

G4UP:
	ld	hl,(G4LOC)	; ghost 4 location
	call	LNUP		; HL -= MAPW
	call	G4HPAC		; check for collision with hungry pacman
	call	CHKOG		; check for other ghosts
	ld	(G4SAV2),a	; save char under overlapping ghost, if any
	call	G4CWP		; check for wall or pacman
	ld	a,(G4CHR)
	ld	(hl),a
	ld	c,a
	ld	(G4LOC),hl	; ghost 4 location
	call	LNDN		; HL += MAPW
	ld	a,(G4SAVC)	; char under ghost 4
	ld	(hl),a		; erase ghost
	ld	b,a
	ld	hl,(G4X)
	ld	e,l
	ld	d,h
	dec	h
	ld	(G4X),hl
G4DONE:
	call	MOVOBJ
	ld	a,(G4SAV2)
	ld	(G4SAVC),a	; char under ghost 4
	ld	a,(CDYTM)	; candy timer (used here as random number)
	ld	e,a
	ld	a,(G2X)
	xor	e
	ld	e,a
	ld	a,(G2Y)
	xor	e
	and	1
	ret	nz
	jp	g41

; ghost 4 - check for wall or pacman
G4CWP:
	cp	'O'
	jp	z,DEAD0
	cp	'+'
	ret	nz
	inc	sp
	inc	sp
g41:
	ld	bc,G4DIR
	ld	a,(bc)
	cp	2
	jp	m,g43
	ld	a,(PACX)
	ld	e,a
	ld	a,(G4X)
	sub	e
	jp	p,g42
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWRGT		; check turn right
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWLFT		; check turn left
	ret

g42:
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWLFT		; check turn left
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWRGT		; check turn right
	ret

g43:
	ld	a,(PACY)
	ld	e,a
	ld	a,(G4Y)
	sub	e
	jp	p,g44
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWUP		; check turn up
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWDN		; check turn down
	ret

g44:
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWDN		; check turn down
	ld	hl,(G4LOC)	; ghost 4 location
	call	CWUP		; check turn up
	ret

; Get char under (other) ghost, if any.
CHKOG:
	cp	'&'		; ghost 1
	jr	z,gch1
	cp	'A'
	jr	z,gch1
	cp	'1'
	jr	z,gch1
	cp	'$'		; ghost 2
	jr	z,gch2
	cp	'B'
	jr	z,gch2
	cp	'2'
	jr	z,gch2
	cp	'#'		; ghost 3
	jr	z,gch3
	cp	'C'
	jr	z,gch3
	cp	'3'
	jr	z,gch3
	cp	'@'		; ghost 4
	jr	z,gch4
	cp	'D'
	jr	z,gch4
	cp	'4'
	ret	nz
gch4:
	ld	a,(G4SAVC)	; char under ghost 4
	ret
gch3:
	ld	a,(G3SAVC)	; char under ghost 3
	ret
gch2:
	ld	a,(G2SAVC)	; char under ghost 2
	ret
gch1:
	ld	a,(G1SAVC)	; char under ghost 1
	ret

; Check for wall and turn accordingly
CWRGT:
	inc	hl		; check right
	ld	a,(hl)
	cp	'+'
	ret	z
	ld	a,1		; OK to move right
	jr	cw1

CWLFT:
	dec	hl		; check left
	ld	a,(hl)
	cp	'+'
	ret	z
	xor	a		; OK to move left
	jr	cw1

CWDN:
	call	LNDN		; HL += MAPW
	ld	a,(hl)
	cp	'+'
	ret	z
	cp	'X'
	ret	z
	ld	a,3		; OK to move down
	jr	cw1

CWUP:
	call	LNUP		; HL -= MAPW
	ld	a,(hl)
	cp	'+'
	ret	z
	ld	a,2		; OK to move up
cw1:
	ld	(bc),a		; store new direction
	inc	sp		; and return one level higher
	inc	sp
	ret

; Player was killed
DEAD0:
	inc	sp
	inc	sp
DEAD:
	ld	a,(LIVES)
	dec	a		; lost a life
	ld	(LIVES),a
	call	SHOWLV
	ld	a,(LIVES)
	cp	'0'		; out of lives?
	jp	z,RESET		; reset game if yes
	inc	sp		; drop return address
	inc	sp
	ld	hl,(PACLOC)	; get pacman address
	ld	(hl),' '	; clear it
	ld	hl,(PACX)
	call	CLROBJ
	ld	a,(G1SAVC)	; char under ghost 1
	ld	hl,(G1LOC)	; ghost 1 location
	ld	(hl),a		; clear it
	ld	hl,(G1X)
	call	PUT_CHR
	ld	a,(G2SAVC)	; char under ghost 2
	ld	hl,(G2LOC)	; ghost 2 location
	ld	(hl),a		; clear it
	ld	hl,(G2X)
	call	PUT_CHR
	ld	a,(G3SAVC)	; char under ghost 3
	ld	hl,(G3LOC)	; ghost 3 location
	ld	(hl),a		; clear it
	ld	hl,(G3X)
	call	PUT_CHR
	ld	a,(G4SAVC)	; char under ghost 4
	ld	hl,(G4LOC)	; ghost 4 location
	ld	(hl),a		; clear it
	ld	hl,(G4X)
	call	PUT_CHR
	jp	NEXTL		; next attempt

RESET:
	inc	sp		; drop return address
	inc	sp
	call	LVLDLY		; delay according to level
	call	UPDHIS		; update hi-score
	jp	NEWGAM		; restart game

; Init and display characters (ghosts and pacman)
; Assumes locations have been initialized.
INITCH:
	ld	a,'&'
	ld	(G1CHR),a
	ld	hl,(G1LOC)	; ghost 1 location
	ld	(hl),a		; store ghost 1
	ld	a,'$'
	ld	(G2CHR),a
	ld	hl,(G2LOC)	; ghost 2 location
	ld	(hl),a		; store ghost 2
	ld	a,'#'
	ld	(G3CHR),a
	ld	hl,(G3LOC)	; ghost 3 location
	ld	(hl),a		; store ghost 3
	ld	a,'@'
	ld	(G4CHR),a
	ld	hl,(G4LOC)	; ghost 4 location
	ld	(hl),a		; store ghost 4
	ld	a,'O'
	ld	(PACCHR),a
	ld	hl,(PACLOC)	; pacman location
	ld	(hl),a		; store pacman
	xor	a
	ld	(G1DEAD),a	; ghost 1 alive
	ld	(G2DEAD),a	; ghost 2 alive
	ld	(G3DEAD),a	; ghost 3 alive
	ld	(G4DEAD),a	; ghost 4 alive
	ld	hl,(PACX)
	ld	a,(PACCHR)
	CALL	PUT_CHR
RFSHG:
	push	hl
	ld	hl,(G1X)
	ld	a,(G1CHR)
	CALL	PUT_CHR
	ld	hl,(G2X)
	ld	a,(G2CHR)
	CALL	PUT_CHR
	ld	hl,(G3X)
	ld	a,(G3CHR)
	CALL	PUT_CHR
	ld	hl,(G4X)
	ld	a,(G4CHR)
	CALL	PUT_CHR
	pop	hl
	ret

; Pacman eats pill. Ghosts become 'eatable'.
EATPIL:
	ld	a,'A'		; ghost change look: 'A'
	ld	(G1CHR),a
	inc	a		; 'B'
	ld	(G2CHR),a
	inc	a		; 'C'
	ld	(G3CHR),a
	inc	a		; 'D'
	ld	(G4CHR),a
	ld	a,'0'		; Note 'O' becomes '0' (looks almost the same)
	ld	(PACCHR),a
	ld	a,96
	ld	(PILLTM),a	; start pill active time countdown
	xor	a
	ld	(GSDCNT),a
	jp	RFSHG		; redisplay all ghosts and return

; If pill is active, decrease the active time. Reset ghosts when count
; reaches zero. Warn by changing ghost appearance if below half time.
DOPILL:
	ld	a,(PILLTM)
	or	a		; pill active?
	ret	z		; return if not
	dec	a
	ld	(PILLTM),a
	jp	z,INITCH	; reset ghosts if just expired
	cp	96/2		; half time?
	ret	nz		; return if not
	ld	a,'1'		; else change ghost chars accordingly: '1'
	ld	(G1CHR),a
	inc	a		; '2'
	ld	(G2CHR),a
	inc	a		; '3'
	ld	(G3CHR),a
	inc	a		; '4'
	ld	(G4CHR),a
	jp	RFSHG		; redisplay all ghosts and return

; Check for collision with "hungry" pacman (accidental ghost "suicide")
; - ghost 1
G1HPAC:
	ld	a,(hl)
	cp	'0'
	ret	nz
	ld	hl,(G1LOC)	; ghost 1 location
	ld	a,(G1SAVC)	; char under ghost 1
	ld	(hl),a		; erase ghost
	ld	hl,(G1X)
	call	CLROBJ
	call	RSTG1		; reset ghost 1
	ld	hl,G1DEAD
	jp	gp1

; - ghost 2
G2HPAC:
	ld	a,(hl)
	cp	'0'
	ret	nz
	ld	hl,(G2LOC)	; ghost 2 location
	ld	a,(G2SAVC)	; char under ghost 2
	ld	(hl),a		; erase ghost
	ld	hl,(G2X)
	call	CLROBJ
	call	RSTG2		; reset ghost 2
	ld	hl,G2DEAD
	jp	gp1

; - ghost 3
G3HPAC:
	ld	a,(hl)
	cp	'0'
	ret	nz
	ld	hl,(G3LOC)	; ghost 3 location
	ld	a,(G3SAVC)	; char under ghost 3
	ld	(hl),a		; erase ghost
	ld	hl,(G3X)
	call	CLROBJ
	call	RSTG3		; reset ghost 3
	ld	hl,G3DEAD
	jp	gp1

; - ghost 4
G4HPAC:
	ld	a,(hl)
	cp	'0'
	ret	nz
	ld	hl,(G4LOC)	; ghost 4 location
	ld	a,(G4SAVC)	; char under ghost 4
	ld	(hl),a		; erase ghost
	ld	hl,(G4X)
	call	CLROBJ
	call	RSTG4		; reset ghost 4
	ld	hl,G4DEAD
gp1:
	inc	(hl)		; ghost now dead
	call	INS100		; increase score by 100
	inc	sp
	inc	sp
	ret

; Ghost 1 got eaten
EATG1:
	push	hl
	ld	a,(G1SAVC)	; char under ghost 1
	ld	e,a
	call	RSTG1		; reset ghost 1
	ld	hl,G1DEAD
	jp	eatg

; Ghost 2 got eaten
EATG2:
	push	hl
	ld	a,(G2SAVC)	; char under ghost 2
	ld	e,a
	call	RSTG2		; reset ghost 2
	ld	hl,G2DEAD
	jp	eatg

; Ghost 3 got eaten
EATG3:
	push	hl
	ld	a,(G3SAVC)	; char under ghost 3
	ld	e,a
	call	RSTG3		; reset ghost 3
	ld	hl,G3DEAD
	jp	eatg

; Ghost 4 got eaten
EATG4:
	push	hl
	ld	a,(G4SAVC)	; char under ghost 4
	ld	e,a
	call	RSTG4		; reset ghost 4
	ld	hl,G4DEAD
eatg:
	inc	(hl)
	call	INS100		; increase score by 100
	ld	a,e
	pop	hl
	ret

LNUP:
	ld	de,-MAPW
	add	hl,de
	ret

LNDN:
	ld	de,MAPW
	add	hl,de
	ret

; Reset ghost 1
RSTG1:
	ld	hl,PLAYFL + G1RPOS
	ld	(G1LOC),hl	; ghost 1 location
	ld	a,' '
	ld	(G1SAVC),a	; clear char under ghost 1
	xor	a
	ld	(G1DIR),a
	ld	h,8
	ld	l,28
	ld	(G1X),hl
	ret

; Reset ghost 2
RSTG2:
	ld	hl,PLAYFL + G2RPOS
	ld	(G2LOC),hl	; ghost 2 location
	ld	a,' '
	ld	(G2SAVC),a	; clear char under ghost 2
	ld	a,1
	ld	(G2DIR),a
	ld	h,8
	ld	l,30
	ld	(G2X),hl
	ret

; Reset ghost 3
RSTG3:
	ld	hl,PLAYFL + G3RPOS
	ld	(G3LOC),hl	; ghost 3 location
	ld	a,' '
	ld	(G3SAVC),a	; clear char under ghost 3
	xor	a
	ld	(G3DIR),a
	ld	h,8
	ld	l,32
	ld	(G3X),hl
	ret

; Reset ghost 4
RSTG4:
	ld	hl,PLAYFL + G4RPOS
	ld	(G4LOC),hl	; ghost 4 location
	ld	a,' '
	ld	(G4SAVC),a	; clear char under ghost 4
	ld	a,1
	ld	(G4DIR),a
	ld	h,8
	ld	l,34
	ld	(G4X),hl
	ret

; Check if character is exiting through left door.
; If yes, make it reappear on the other side.
;	hl = PLAYFL addr
;	de = XY addr
CHKLD:
	ld	bc,PLAYFL + LDOOR+1
	call	CPHLBC
	ret	nz
	ld	(hl),0
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	dec	hl
	ex	de,hl
	call	CLROBJ
	ld	hl,PLAYFL + RDOOR
	ld	a,(de)
;	add	a,MAPW-2
	LD	A, 62
	ld	(de),a
	ret

; Check if character is exiting through right door.
; If yes, make it reappear on the other side.
CHKRD:
	ld	bc,PLAYFL + RDOOR-1
	call	CPHLBC
	ret	nz
	ld	(hl),0
	ex	de,hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	dec	hl
	ex	de,hl
	call	CLROBJ
	ld	hl,PLAYFL + LDOOR
	ld	a,(de)
;	sub	MAPW-2
	LD	A, 0
	ld	(de),a
	ret

; Update and display hi-score
UPDHIS:
	ld	hl,HISCOR	; hi-score address
	ld	de,SCORE	; current score
	ld	b,5
his1:
	ld	c,(hl)
	ld	a,(de)
	cp	c
	jp	m,his4
	jr	z,his2
	jr	his3
his2:
	inc	hl
	inc	de
	djnz	his1
his3:
	ld	(hl),a
	inc	hl
	inc	de
	ld	a,(de)
	ld	(hl),a
	djnz	his3
his4:
	ld	l,28
	ld	h, STATLINE
	LD	(SCR_POS), HL
	ld	hl,HISCOR	; hi-score address
	ld	b,5
his5:
	ld	a,(hl)
	call	PUTCH
	inc	hl
	djnz	his5
	RET

PAUSE:
	call	GETCH
	cp	3
	jp	z,QUIT
	call	UCASE
	cp	'C'
	jr	nz,PAUSE
	ret

LVLDLY:
	ld	a,(LEVEL)	; get level
	jp	DELAY		; delay according to level level

LDELAY:
	ld	a,150
	jp	DELAY

CPHLBC:
	ld	a,h
	cp	b
	ret	nz
	ld	a,l
	cp	c
	ret

;---------------------------------------------------------------------------

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

PUTCHR:
	PUSH	AF
	CALL	PUTCH
	POP	AF
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

SETCUR:
	LD	A, L
	LD	L, H
	LD	H, A
	LD	(SCR_POS), HL
	RET

PRINTXY:
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
	jr	PRINTXY

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
;---------------------------------------------------------------------------

	.DB	29, 11
TITLE:	.db	"PACMAN",0
LVLO:	.db	"Lvl  ",0
	.DB	22, 10
LVLMSG:	.db	"Level (0-9) ? ",0
LVLCLR:	.db	"              ",0

; Game map, 24 rows x 57 cols

MAP0:           ;0123456789012345678901234567890123456789012345678901234567890123
        .DB     "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ "
	.DB	"³. . . . . . . . . . . . .³  Timer  ³. . . . . . . . . . . . .³ "
	.DB	"³SÚÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.³  00000  ³.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄ¿S³ "
	.DB	"³.ÀÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÙ.³ "
	.DB	"³. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .³ "
	.DB	"³.ÚÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄ¿.ÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄ.ÚÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄ¿.³ "
	.DB	"³.ÀÄÄÄÄÄÙ.³       ³. . . . .³     ³. . . . .³       ³.ÀÄÄÄÄÄÙ.³ "
	.DB	"³. . . . .³       ÃÄÄÄÄÄÄÄÄ.ÀÄÄÄÄÄÙ.ÄÄÄÄÄÄÄÄ´       ³. . . . .³ "
	.DB	"ÃÄÄÄÄÄÄÄ¿.³       ³. . . . . . . . . . . . .³       ³.ÚÄÄÄÄÄÄÄ´ "
	.DB	"ÀÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÙ.ÚÄÄÄÄÄÄÄXÄXÄXÄXÄÄÄÄÄÄÄ¿.ÀÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÙ "
	.DB	"         . . . . . .³   PACMAN   Lvl  0   ³. . . . . .          "
	.DB	"ÚÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄ¿.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÚÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄ¿ "
	.DB	"ÃÄÄÄÄÄÄÄÙ.³       ³. . . . . .   . . . . . .³       ³.ÀÄÄÄÄÄÄÄ´ "
	.DB	"³. . . . .ÀÄÄÄÄÄÄÄÙ.ÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄ.ÀÄÄÄÄÄÄÄÙ. . . . .³ "
	.DB	"³.ÚÄÄÄÄÄ¿. . . . . . . . . .³     ³. . . . . . . . . .ÚÄÄÄÄÄ¿.³ "
	.DB	"³.ÀÄÄÄ¿ ³.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.³     ³.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.³ ÚÄÄÄÙ.³ "
	.DB	"³S . .³ ³.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.³ ³. . S³ "
	.DB	"ÃÄÄÄ¿.³ ³. . . . . . . . . . . O . . . . . . . . . . .³ ³.ÚÄÄÄ´ "
	.DB	"ÃÄÄÄÙ.ÀÄÙ.ÚÄÄÄÄÄ¿.ÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ.ÚÄÄÄÄÄ¿.ÀÄÙ.ÀÄÄÄ´ "
	.DB	"³. . . . .³     ³. . . . .³         ³. . . . .³     ³. . . . .³ "
	.DB	"³.ÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄ.ÀÄÄÄÄÄÄÄÄÄÙ.ÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄ.³ "
	.DB	"³. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .³ "
	.DB	"ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ "
;	.DB	"Lives 00  Score 00000  High 00000   a b c d e f g h i j k l m n "

MAP1:
	.DB	"ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ "
	.DB	"³. . . . . . . . . . . . .³  Timer  ³. . . . . . . . . . . . .³ "
	.DB	"³SÚÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.³  00000  ³.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄ¿S³ "
	.DB	"³.ÀÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÙ.³ "
	.DB	"³. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .³ "
	.DB	"³.ÚÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄ¿.ÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄ.ÚÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄ¿.³ "
	.DB	"³.ÀÄÄÄÄÄÙ.³       ³. . . . .³     ³. . . . .³       ³.ÀÄÄÄÄÄÙ.³ "
	.DB	"³. . . . .³       ÃÄÄÄÄÄÄÄÄ.ÀÄÄÄÄÄÙ.ÄÄÄÄÄÄÄÄ´       ³. . . . .³ "
	.DB	"ÃÄÄÄÄÄÄÄ¿.³       ³. . . . . . . . . . . . .³       ³.ÚÄÄÄÄÄÄÄ´ "
	.DB	"ÀÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÙ.ÚÄÄÄÄÄÄÄXÄXÄXÄXÄÄÄÄÄÄÄ¿.ÀÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÙ "
	.DB	"         . . . . . .³   PACMAN   Lvl  0   ³. . . . . .          "
	.DB	"ÚÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄ¿.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÚÄÄÄÄÄÄÄ¿.ÚÄÄÄÄÄÄÄ¿ "
	.DB	"ÃÄÄÄÄÄÄÄÙ.³       ³. . . . . .   . . . . . .³       ³.ÀÄÄÄÄÄÄÄ´ "
	.DB	"³. . . . .ÀÄÄÄÄÄÄÄÙ.ÄÄÄÄÄÄÄÄÂÄÄÄÄÄÂÄÄÄÄÄÄÄÄ.ÀÄÄÄÄÄÄÄÙ. . . . .³ "
	.DB	"³.ÚÄÄÄÄÄ¿. . . . . . . . . .³     ³. . . . . . . . . .ÚÄÄÄÄÄ¿.³ "
	.DB	"³.ÀÄÄÄ¿ ³.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.³     ³.ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿.³ ÚÄÄÄÙ.³ "
	.DB	"³S . .³ ³.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.ÀÄÄÄÄÄÙ.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.³ ³. . S³ "
	.DB	"ÃÄÄÄ¿.³ ³. . . . . . . . . . . O . . . . . . . . . . .³ ³.ÚÄÄÄ´ "
	.DB	"ÃÄÄÄÙ.ÀÄÙ.ÚÄÄÄÄÄ¿.ÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄ.ÚÄÄÄÄÄ¿.ÀÄÙ.ÀÄÄÄ´ "
	.DB	"³. . . . .³     ³. . . . .³         ³. . . . .³     ³. . . . .³ "
	.DB	"³.ÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄ.ÀÄÄÄÄÄÄÄÄÄÙ.ÄÄÄÄÄÄÄÄÁÄÄÄÄÄÁÄÄÄÄÄÄÄÄ.³ "
        .DB     "³. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .³ "
        .DB     "³.ÚÄ¿.ÚÄ¿.ÚÄ¿.ÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ.ÚÄ¿.ÚÄ¿.ÚÄ¿.³ "
        .DB     "³.³ ³.³ ³.³ ³. . . . . . . . . . . . . . . . . . .³ ³.³ ³.³ ³.³ "
        .DB     "³.³ ³.³ ³.³ ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ ³.³ ³.³ ³.³ "
        .DB     "³.³ ³.³ ³.ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ.³ ³.³ ³.³ "
        .DB     "³.³ ³.ÀÄÙ. . . . . . . . . . . . . . . . . . . . . . .ÀÄÙ.³ ³.³ "
        .DB     "³.³ ³. . .ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿. . .³ ³.³ "
        .DB     "³.³ ÀÄÄÄÄÄÙ ÚÄÄÄÄÄ¿     ÚÄÄÄÄÄ¿ ÚÄÄÄÄÄ¿     ÚÄÄÄÄÄ¿ ÀÄÄÄÄÄÙ ³.³ "
        .DB     "³.ÀÄÄÄÄÄÄÄÄÄÙ. . .ÀÄÄÄÄÄÙ. . .ÀÄÙ. . .ÀÄÄÄÄÄÙ. . .ÀÄÄÄÄÄÄÄÄÄÙ.³ "
        .DB     "³. . . . . . .ÚÄ¿. . . . .ÚÄ¿. . .ÚÄ¿. . . . .ÚÄ¿. . . . . . .³ "
        .DB     "³.ÚÄÄÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÙ ÀÄÄÄÄÄÄÄÄÄÄÄ¿.³ "
        .DB     "³.ÀÄÄÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÄÄÄÄÙ.³ "
        .DB     "³. . . . . . .ÀÄÙ. . . . .ÀÄÙ. . .ÀÄÙ. . . . .ÀÄÙ. . . . . . .³ "
        .DB     "³.ÚÄÄÄÄÄÄÄÄÄ¿. . .ÚÄÄÄÄÄ¿. . .ÚÄ¿. . .ÚÄÄÄÄÄ¿. . .ÚÄÄÄÄÄÄÄÄÄ¿.³ "
        .DB     "³.³         ³.ÚÄ¿.³     ³.ÚÄ¿.³ ³.ÚÄ¿.³     ³.ÚÄ¿.³         ³.³ "
        .DB     "³.³         ³.³ ³.³     ³.³ ³.³ ³.³ ³.³     ³.³ ³.³         ³.³ "
        .DB     "³.³         ³.³ ³.³     ³.³ ³.³ ³.³ ³.³     ³.³ ³.³         ³.³ "
        .DB     "³.³     ÚÄÄÄÙ.³ ³.ÀÄÄÄÄÄÙ.³ ³.³ ³.³ ³.ÀÄÄÄÄÄÙ.³ ³.ÀÄÄÄ¿     ³.³ "
        .DB     "³.ÀÄÄÄÄÄÙ. . .³ ³. . . . .³ ³.³ ³.³ ³. . . . .³ ³. . .ÀÄÄÄÄÄÙ.³ "
        .DB     "³. . . . .ÚÄ¿.³ ³.ÚÄÄÄÄÄ¿.³ ³.³ ³.³ ³.ÚÄÄÄÄÄ¿.³ ³.ÚÄ¿. . . . .³ "
        .DB     "³.ÚÄÄÄÄÄ¿.³ ³.³ ³.³     ³.³ ³.³ ³.³ ³.³     ³.³ ³.³ ³.ÚÄÄÄÄÄ¿.³ "
        .DB     "³.³     ³.³ ³.³ ³.³     ³.³ ³.³ ³.³ ³.³     ³.³ ³.³ ³.³     ³.³ "
        .DB     "³.ÀÄÄÄÄÄÙ.³ ³.ÀÄÙ.ÀÄÄÄÄÄÙ.ÀÄÙ.³ ³.ÀÄÙ.ÀÄÄÄÄÄÙ.ÀÄÙ.³ ³.ÀÄÄÄÄÄÙ.³ "
        .DB     "³. . . . .³ ³. . . . . . . . .³ ³. . . . . . . . .³ ³. . . . .³ "
        .DB     "ÀÄÄÄÄÄÄÄÄÄÁÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÁÄÄÄÄÄÄÄÄÄÙ "

	.DB	59, 4
LIVMSG:	.db	"Lives",0
	.DB	59, 5
SCMSG:	.db	"Score",0
	.DB	59, 6
HSCMSG:	.db	"High",0

; variables and data addresses

NDOTS:	.dw	0	; dots to eat
JAILTM:	.db	0	; time before ghosts escape from confinement
PILLTM:	.db	0	; pill action time
GSDCNT:	.db	0	; ghost slowdown counter while pill is active

CDYC:	.db	0	; candy char
CDYTM:	.db	0	; candy timer
CDCOLN:	.db	0	; collected candies display - per row
CDCOLX:	.db	0	; collected candies display - coord x
	.db	0	;     "        "       "      coord y

SDCNT:	.db	0	; slow-down counter

LASTK:	.db	0	; last key
LASTD:	.db	0	; last pacman dir (key)
LEVEL:	.db	0	; current level (speed)

PACCHR:	.db	0	; pacman char

PACLOC:	.dw	0	; pacman location

PACX:	.db	0
PACY:	.db	0

G1DEAD:	.db	0	; 0 if ghost 1 is alive, 1 if dead
G2DEAD:	.db	0	; 0 if ghost 2 is alive, 1 if dead
G3DEAD:	.db	0	; 0 if ghost 3 is alive, 1 if dead
G4DEAD:	.db	0	; 0 if ghost 4 is alive, 1 if dead

G1CHR:	.db	0
G2CHR:	.db	0
G3CHR:	.db	0
G4CHR:	.db	0

G1LOC:	.dw	0	; ghost 1 location
G2LOC:	.dw	0	; ghost 2 location
G3LOC:	.dw	0	; ghost 3 location
G4LOC:	.dw	0	; ghost 4 location

G1X:	.db	0
G1Y:	.db	0

G2X:	.db	0
G2Y:	.db	0

G3X:	.db	0
G3Y:	.db	0

G4X:	.db	0
G4Y:	.db	0

G1DIR:	.db	0
G2DIR:	.db	0
G3DIR:	.db	0
G4DIR:	.db	0

G1WALL:	.db	0	; 1 if ghost 2 against wall
G1SAVC:	.db	0	; char under ghost 1
G1SAV2:	.db	0
G2SAVC:	.db	0	; char under ghost 2
G2SAV2:	.db	0
G3SAVC:	.db	0	; char under ghost 3
G3SAV2:	.db	0
G4SAVC:	.db	0	; char under ghost 4
G4SAV2:	.db	0

LIVES:	.db	0	; number of lives

SCORE:	.db	5, 0, 0,0,0
HISCOR:	.db	5, 0, 0,0,0	; best result

	.ORG	( $ & $FF00 ) + $100
PLAYFL:
	.end


;       .db     "ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿"
;       .db     "³ . . . . . . . . . . . . . . ³ ³ . . . . . . . . . . . . . . ³"
;       .db     "³ . ÚÄÄÄÄÄ¿ . ÚÄÄÄÄÄÄÄÄÄÄÄ¿ . ³ ³ . ÚÄÄÄÄÄÄÄÄÄÄÄ¿ . ÚÄÄÄÄÄ¿ . ³"
;       .db     "³ @ ³     ³ . ³           ³ . ³ ³ . ³           ³ . ³     ³ @ ³"
;       .db     "³ . ÀÄÄÄÄÄÙ . ÀÄÄÄÄÄÄÄÄÄÄÄÙ . ÀÄÙ . ÀÄÄÄÄÄÄÄÄÄÄÄÙ . ÀÄÄÄÄÄÙ . ³"
;       .db     "³ . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ³"
;       .db     "³ . ÚÄÄÄÄÄ¿ . ÚÄÄÄ¿ . ÄÄÄÄÄÄÄÄÂÄÂÄÄÄÄÄÄÄÄ . ÚÄÄÄ¿ . ÚÄÄÄÄÄ¿ . ³"
;       .db     "³ . ³     ³ . ³   ³ . . . . . ³ ³ . . . . . ³   ³ . ³     ³ . ³"
;       .db     "³ . ³     ³ . ³   ÀÄÄÄÂÄÄÄÄ . ÀÄÙ . ÄÄÄÄÂÄÄÄÙ   ³ . ³     ³ . ³"
;       .db     "³ . ³     ³ . ³       ³ . . . . . . . . ³       ³ . ÀÄÄÄÄÄÙ . ³"
;       .db     "³ . ÀÄÄÄÄÄÙ . ³       ³ . ÚÄÄ  Ä  ÄÄ¿ . ³       ³ . . . . . . ³"
;       .db     "³ . . . . . . ³       ³ . ³  \ \ \  ³ . ÀÄÄÄÄÄÄÄÙ . ÄÄÄÄÄÄÄÄÄÄÙ"
;       .db     "ÀÄÄÄÄÄÄÄÄÄÄ . ÀÄÄÄÄÄÄÄÙ . ³         ³ . . . . . . . . . . . . ."
;       .db     ". . . . . . . . . . . . . ³         ³ . ÚÄÄÄÄÄÄÄ¿ . ÄÄÄÄÄÄÂÄÄÄ¿"
;       .db     "ÚÄÄÄÄÄÄÄÄÄÄ . ÚÄÄÄÄÄÄÄ¿ . ÃÄÄÄÄÄÄÄÄÄ´ . ³       ³ . . . . ÀÄÄÄ´"
;       .db     "³ . . . . . . ³       ³ . ³         ³ . ³       ³ . ÚÄ¿ . . . ³"
;       .db     "³ . ÄÄÄÄÂÄ¿ . ÀÄÄÄÄÄÄÄÙ . ÀÄÄÄÄÄÄÄÄÄÙ . ÀÄÄÄÄÄÄÄÙ . ³ ÃÄÄÄÄ . ³"
;       .db     "³ @ . . ³ ³ . . . . . . . . . . . . . . . . . . . . ³ ³ . . @ ³"
;       .db     "ÃÄÄÄÄ . ÀÄÙ . ÚÄÄÄ¿ . ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿ . ÚÄÄÄ¿ . ÀÄÙ . ÄÄÄÄ´"
;       .db     "³ . . . . . . ³   ³ . ³                 ³ . ³   ³ . . . . . . ³"
;       .db     "³ . ÚÄÄÄÄÄÄÄÄÄÙ   ³ . ÀÄÄÄÄÄÄÄ¿ ÚÄÄÄÄÄÄÄÙ . ³   ÀÄÄÄÄÄÄÄÄÄ¿ . ³"
;       .db     "³ . ³             ³ . . . . . ³ ³ . . . . . ³             ³ . ³"
;       .db     "³ . ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄ . ÀÄÙ . ÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÙ . ³"
;       .db     "³ . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ³"
;       .db     "ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ"

;	.db	"_______________________________________________________________"
;	.db	"I . . . . . . . . . . . . . . . . . . . . . . I . . . . . . . I"
;	.db	"I . ___ . _________________ . ___ . _______ . I . _ . _____ . I"
;	.db	"I @ I I . I               I . . . . I     I . . . I . I   I . I"
;	.db	"I . I_I . I____________   I_________I     I__ . __I . I___I . I"
;	.db	"I . . . . . . . . . . I                     I . I I . . . . . I"
;	.db	"I . ___ . _________ . I________ ____________I . I_I____ . _ . I"
;	.db	"I . I I . I______ I . . . . . I I . . . . . . . . I___I . I . I"
;	.db	"I . I I . . . . I I________ . I_I . ___________ . I . . . I . I"
;	.db	"I . I I______ . I     I . . . . . . . . I     I . I . ____I . I"
;	.db	"I . I_______I . I     I . ___  _  ___ . I     I . I @ . . . . I"
;	.db	"I . . . . . . . I     I . I  \ \ \  I . I_____I . I________ . I"
;	.db	"I____________ . I_____I . I         I . . . . . . . . . . . . ."
;	.db	". . . . . . . . . . . . . I         I . _______ . _____________"
;	.db	"_ . _________ . _______ . I_________I . I     I . . . . . . . I"
;	.db	"I . . . . @ I . I     I . I         I . I     I . _________ . I"
;	.db	"I . _____ . I . I_____I . =========== . I_____I . I______ I . I"
;	.db	"I . I I . . I . . . . . . . . . . . . . . . . I . . . . I I . I"
;	.db	"I . I_I . __I__ . _________________________ . I______ . I_I . I"
;	.db	"I . . . . . I I . I                       I . . . . . . . . @ I"
;	.db	"I . _____ . I_I . I__     ___________     I__________ . ___ . I"
;	.db	"I . I   I . I . . . I     I . . . . I               I . I I . I"
;	.db	"I . I___I . I . _ . I_____I . ___ . I_______________I . I_I . I"
;	.db	"I . . . . . . . I . . . . . . . . . . . . . . . . . . . . . . I"
;	.db	"I_______________I_____________________________________________I"

;	.db	"_______________________________________________________________"
;	.db	"I . . . . . . . . . . . . . . I I . . . . . . . . . . . . . . I"
;	.db	"I . _______ . _____________ . I I . _____________ . _______ . I"
;	.db	"I @ I     I . I           I . I I . I           I . I     I @ I"
;	.db	"I . I   __I . I     ______I . I_I . I______     I . I__   I . I"
;	.db	"I . I   I . . I     I . . . . . . . . . . I     I . . I   I . I"
;	.db	"I . I   I . __I     I . _______________ . I     I__ . I   I . I"
;	.db	"I . I___I . I_______I . I             I . I_______I . I___I . I"
;	.db	"I . . . . . . . . . . . I_____________I . . . . . . . . . . . I"
;	.db	"I . _________ . _____ . . . . . . . . . . _____ . _________ . I"
;	.db	"I . I       I . I   I__ . ___, , ,___ . __I   I . I       I . I"
;	.db	"I . I       I . I     I . I         I . I     I . I_______I . I"
;	.db	"I . I_______I . I     I . I         I . I     I . . . . . . . I"
;	.db	"I . . . . . . . I     I . I         I . I     I . ____________I"
;	.db	"I____________ . I     I . I_________I . I     I . . . . . . . ."
;	.db	". . . . . . . . I     I . I         I . I     I . _________ . _"
;	.db	"_ . _________ . I__   I . =========== . I   __I . I       I . I"
;	.db	"I . I       I . . I   I . . . . . . . . I   I . . I       I . I"
;	.db	"I . I_______I__ . I   I . ___________ . I   I . __I_______I . I"
;	.db	"I . . . . . I I . I___I . I         I . I___I . I I . . . . . I"
;	.db	"I . _____ @ I I . . . . . I         I . . . . . I I @ _____ . I"
;	.db	"I . . . . . I I . _____ . I____ ____I . _____ . I I . . . . . I"
;	.db	"I . ________I_I . I   I . . . I_I . . . I   I . I_I________ . I"
;	.db	"I . . . . . . . . I   I____ . . . . ____I   I . . . . . . . . I"
;	.db	"I_________________I_______I_________I_______I_________________I"

;	.db	"_______________________________________________________________"
;	.db	"I . . . . . . . . . . . I   I . . . I I . . . . . . . . . . . I"
;	.db	"I @ _______ . _______ . I   I . _ . I I . _______ . _______ @ I"
;	.db	"I . I     I . I     I . I   I . I . I I . I     I . I_____I . I"
;	.db	"I . I_____I . I_____I . I___I . I . I_I . I_____I . . . . . . I"
;	.db	"I . . . . . . . . . . . . . . . . . . . . . . . . . _______ . I"
;	.db	"I . _ . _____________________ . _ . ___ . __________I     I . I"
;	.db	"I . I . I       I . . . . . . . I . I I . I               I . I"
;	.db	"I . I . I       I . _________ . I . I_I . I_______________I . I"
;	.db	"I . I . I   ____I . I I . . . . . . . . . . . . . . . . . . . I"
;	.db	"I . I . I   I . . . I I . ___, , ,___ . _____ . ___________ . I"
;	.db	"I . . . I   I . ____I I . I         I . I   I . I         I . I"
;	.db	"I____ . I   I . I     I . I         I . I __I . I_________I . I"
;	.db	"I___I . I___I . I_____I . I         I . I I . . . . . . . . . ."
;	.db	". . . . . . . . . . . . . I_________I . I I . _________________"
;	.db	"_____ . _____ . _ . ___ . I         I . I_I . . . . . . . . . I"
;	.db	"I   I . I   I . I . I I . =========== . . . . _____________ . I"
;	.db	"I   I . I __I . I . I I . . . . . . . . ______I           I . I"
;	.db	"I   I . I I . . I . I I__ . ____________I _______________ I . I"
;	.db	"I___I . I_I . __I . I   I . I             I . . . . @ . I I . I"
;	.db	"I . . . . . . . . . I___I . I____         I . _______ . I I . I"
;	.db	"I @ _____________ . I . . . . . I_________I . I____ I . I I . I"
;	.db	"I . I___________I . I . _____ . . . . . . . . . . I_I . I_I . I"
;	.db	"I . . . . . . . . . . . I   I__________________ . . . . . . . I"
;	.db	"I_______________________I_____________________I_______________I"

;                0123456789012345678901234567890123456789012345678901234567890123