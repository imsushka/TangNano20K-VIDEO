;	TITLE	SPACE INVADERS

; Adapted from the RT-11 version by H. Peraza. Original credits and ChangeLog:
;
; 24-MAR-80	J. C. VENN
; 04-JUL-80	VT52 BY MIKE BROOK
; 18-JAN-81	VT100 BY KEN BELL
; 09-MAR-82	Steve Brecher--
;     |		user-selected level of expertise, with instruction for beginner;
;     |		avoid infinite loop in DBOMB routine by returning immediately
;     |		  if no invaders left;
;     |		new random number generator;
;     |		always randomize bombs if no kills yet;
;     |		keep count of invaders per column, reject empty column
;     |		  immediately in DBOMB routine;
;     V		add fast spaceship for 200 extra points.
; 10-MAR-82	correct "Ctrl-Q" to "Q" in instructions;
;     |		don't allow fire until previous missile moves up from base;
;     |		change macro and formal parameter names for compatibility with
;     |		  HT-11; expand "CALL" and "RETURN" in case those not
;     |		  compatible;
;     V		some optimization of UP and its subroutines.

	.org	0100h

SCR_POS		= 000Ch
PUT_CHR		= 0FF90h

CR	=	0Dh
LF	=	0Ah

CTIME	=	2	; number of hardware clock ticks per program clock tick
NTIMES	=	4	; number of CTIMEs between invader moves (initially)
BSLEEP	=	5	; number of CTIMEs before new base supplied
WTIME	=	120	; number of CTIMEs new base allowed to wait before moving
NSHIP	=	100	; number of CTIMEs between spaceships
SSLEEP	=	60	; number of CTIMEs before spaceship debris cleared away

NBASES	=	3	; number of bases to start with
NROWS	=	6	; number of rows of invaders
NCOLS	=	8	; number of columns of invaders
TOP	=	5	; initial top row of invaders

MAXBOMB	=	3	; max number of simultaneous bombs
MAXMISL	=	3	; max number of simultaneous missiles

;-----------------------------------------------------------------------

START:	ld	sp,stack
;	call	INIT
S1:	ld	hl,EXPMSG	; prompt for level of expertise
	call	PUTSTR
	call	GETCH
	cp	3
	jp	z, 0
	call	UCASE
	push	af
	call	CRLF
	pop	af
	ld	b,3		; init number of missiles for beginner
	ld	c,1		; and number of bombs
	cp	'B'		; beginner?
	jr	z,HELP		; if so, go print instructions
	dec	b		; assume intermediate
	inc	c
	cp	'I'		; intermediate?
	jr	z,STRTED
	dec	b		; assume expert
	inc	c
	cp	'E'		; expert?
	jr	z,STRTED
	jr	S1		; ask the dummy again

HELP:	ld	hl,HLPMSG
	call	PUTSTR
	call	GETCH
STRTED:	ld	a,b
	ld	(NMISIL),a
	ld	a,c
	ld	(NBOMBS),a

;;	ld	hl,dtbuf
;;	SC	.GDAT
;;	ld	hl,(dtbuf+5)	; lo=min, hi=sec
;;	ld	(SEED),hl

	ld	hl,0
	ld	(PRVMAX),hl

	; TODO:
	; - open file SY:[]SPCINV.DAT
	; - jr	c,RESTRT
	; - read PRVMAX (prev max)
	; - close file

RESTRT:	call	INIT0		; initialize for start of new game
NEXT:	call	INIT1		; initialize everything else

LOOP:	call	INKEY
	or	a
	jr	z,COMMON
	ld	c,a
	ld	a,(DEADB)
	or	a		; base dead?
	jr	nz,COMMON	; yes
	ld	a,c
	cp	'W'
	jr	z,SHOOT
	cp	' '
	jr	z,SHOOT		; stop base and fire
	cp	'A'
	jr	z,LEFT
	cp	','
	jr	z,LEFT		; base left
	cp	'D'
	jr	z,RIGHT
	cp	'.'
	jr	z,RIGHT		; base right
	call	UCASE
	cp	'Q'
	jr	z,QUIET		; stop/start bleep
	cp	3
	jp	z,EXITG		; exit
	jp	STOP

LEFT:	ld	hl,BASEL	; base left
	ld	(BSUB),hl
	jr	COMMON

RIGHT:	ld	hl,BASER	; base right
	ld	(BSUB),hl
	jr	COMMON

SHOOT:	ld	hl,0		; stop base moving
	ld	(BSUB),hl
	call	FIRE
	jr	COMMON

QUIET:	ld	hl,BELL		; toggle audio effect
	ld	a,(hl)
	xor	7
	ld	(hl),a
	jr	COMMON

STOP:	ld	hl,0		; any other key stops base
	ld	(BSUB),hl

COMMON:
	ld	a,CTIME
;	add	a,a
	call	DELAY
	ld	hl,FRECNT
	inc	(hl)		; increment free-running counter
	ld	a,(DEADB)
	or	a
	jr	z,c20
	dec	a
	ld	(DEADB),a
	jr	nz,c40

	ld	a,(NLIVES)
	or	a		; all bases used?
	jr	z,EXITG		; yes
	call	CLRBAS		; remove old base
	ld	a,2
	ld	(BASEX),a	; move new base to initial position
	call	DSPBAS
	ld	a,WTIME
	ld	(WLIMIT),a

c20:	ld	hl,(BSUB)
	ld	a,h
	or	l
	jr	nz,c30
	ld	a,(BASEX)
	cp	8
	jr	nc,c40
	ld	hl,WLIMIT
	dec	(hl)
	jr	nz,c40
	ld	hl,BASER	; force base out into the open
	ld	(BSUB),hl
c30:
	call	_BSUB		; move base
c40:
	call	UP		; move missiles up
	call	DOWN		; move bombs down
	call	MOVE		; move invaders about
	call	SHIP		; move spaceship
	ld	a,(BASEX)
	add	a,2
	ld	h,a		; position cursor on base
	ld	l,24
	call	STCUR0
;	call	TTFLSH
c80:	ld	a,(NUMINV)	; any invaders left?
	or	a
	jp	nz,LOOP		; yes
	ld	a,(SHIPX)	; any spaceship?
	or	a
	jp	nz,LOOP		; yes
	ld	a,(NLIVES)	; still alive?
	or	a
	jr	z,EXITG
	jp	m,EXITG
	inc	a
	ld	(NLIVES),a
	jp	NEXT		; yes - generate some more invaders

_BSUB:	ld	hl,(BSUB)
	jp	(hl)

; Game over

EXITG:	ld	hl,(POINTS)
	ld	de,(PRVMAX)
	call	CPHLDE
	jr	nc,ex2
	ld	(PRVMAX),hl

	; TODO:
	; - open file SY:[]SPCINV.DAT
	; - jr	nc,ex1
	; - create file SY:[]SPCINV.DAT
	; - jr	c,ex2
	; ex1:
	; - write PRVMAX to file
	; - close file

ex2:	call	CLRBAS		; remove base
	ld	hl,1*256+24
	call	STCUR0		; cursor on bottom line
;	call	BOLD
	ld	hl,AMSG
	call	PUTSTR		; ask for confirmation
;	call	NORMAL
ex3:	call	GETCH
	cp	3		; ^C
	jr	z,ex4
	cp	CR
	jr	nz,ex3
	jp	RESTRT

ex4:	call	CLS		; clear screen
	jp	0		; and exit

; Move base right

BASER:	ld	a,(BASEX)
	cp	71
	jr	nc,NOMOVE	; already max right
	inc	a
	ld	(BASEX),a
	jr	DSPBAS

; Move base left

BASEL:	ld	a,(BASEX)
	cp	8+1
	jr	c,NOMOVE	; already max left
	dec	a
	ld	(BASEX),a
DSPBAS:
	ld	a,(BASEX)
	ld	h,a
	ld	l,24
	call	STCUR0
	ld	hl,BASE
	jp	PUTSTR

; Clear base

CLRBAS:	ld	a,(BASEX)
	ld	h,a
	ld	l,24
	call	STCUR0
	ld	hl,BLANK
	jp	PUTSTR

; Stop base

NOMOVE:	ld	hl,0
	ld	(BSUB),hl
	ret

; Move missiles up

UP:	ld	a,(FRECNT)
	and	03h		; missiles move 3 out of four ticks (-123)
	ret	z
	ld	a,(NMISIL)
	ld	b,a
	ld	ix,UPXY
up2:	ld	e,(ix+0)	; get missile column into E
	ld	a,e
	or	a
	jp	z,up14		; no missile, skip
	ld	(OKFIRE),a	; set flag, OK to fire again
	ld	d,(ix+1)	; get row into D
	ld	h,e
	ld	l,d
	call	STCUR0
	ld	a,' '		; 08h
	call	PUTC
	dec	d		; move missile up
	ld	a,(SHIPX)
	dec	a		; ship moving?
	jp	p,up3		; branch if yes (branch if > 0)
	ld	a,d
	cp	3+1		; else prevent erasing bonus points line
	jp	c,up9
up3:	ld	a,d
	cp	1		; top of screen?
	jp	z,up9		; yes, destroy missile
	ld	(ix+1),d	; set new row
	ld	a,d
	cp	22		; barrier line?
	jr	c,up4		; no, above
	call	CBARR		; check for hit on barrier
	jp	nz,up9		; yes

up4:	ld	c,d
	inc	c		; old Y position
	ld	a,d
	cp	2		; on spaceship line?
	jr	nz,up5		; no
	ld	a,(SHIPX)	; spaceship moving?
	or	a
	jr	z,up5		; no
	jp	m,up5
	push	de
	push	bc
	call	CSHIP		; check for hit on spaceship
	pop	bc
	pop	de
	jp	z,up9		; yes
up5:	push	de
	push	bc
	push	ix
	call	CBOMB		; check for collision with bomb
	pop	ix
	pop	bc
	pop	de
	jp	z,up9		; yes

	ld	hl,ROWY		; check for hit on invaders, top row to bottom
	ld	e,0
up6:	ld	a,(hl)
	cp	d		; now on same line as row of invaders?
	jr	z,up7		; yes
	cp	c		; was on invader line pre-UP?
	jr	z,up7		; yes, invader moved down on missile?
	jp	nc,up13		; no, previously above invaders
	inc	hl
	inc	e
	ld	a,e
	cp	NROWS
	jr	nz,up6		; try next row
	jp	up13		; below invaders

up7:	ld	a,e
	add	a,a
	ld	hl,ROW
	call	ADDHLA
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a		; missile at row, check each column
	ld	c,NCOLS
up8:	ld	a,(hl)		; get column of invader
	or	a
	jp	z,up12		; already dead
	jp	m,up11		; cloud of smoke, missile cleans the air
	add	a,4		; right edge
	cp	(ix+0)
	ld	a,(ix+0)
	jp	c,up12		; missile to right of this invader
	cp	(hl)
	jp	c,up13		; missile to left of this invader
	ld	a,(hl)		; invader X coord
	set	7,(hl)		; mark as exploded
	push	af
	ld	a,NCOLS
	sub	c
	ld	(DEAD),a	; remember column of last kill
	ld	hl,COLCNT
	call	ADDHLA
	dec	(hl)		; one invader less in this column
	ld	a,e
	ld	hl,ROWY
	call	ADDHLA
	ld	l,(hl)
	pop	af
	ld	h,a
	call	STCUR0
	call	EXPLOD		; invader explodes
	ld	a,e
	ld	hl,PNTS
	call	ADDHLA
	ld	a,(hl)
	ld	hl,(POINTS)
	call	ADDHLA
	ld	(POINTS),hl
	call	SCORE		; update score
	ld	hl,NUMINV
	dec	(hl)		; one less invader
	jr	nz,up9		; but some left
	ld	a,(SHIPX)
	or	a		; spaceship moving?
	jr	z,up91
	jp	p,up9		; yes - don't disable base yet
up91:	ld	hl,0
	ld	(BSUB),hl	; stop base moving
	ld	a,BSLEEP
	ld	(DEADB),a
up9:	ld	(ix+0),0	; destroy missile
	jr	up14

up11:	push	hl
	push	de
	ld	d,(hl)
	ld	a,e
	ld	hl,ROWY
	call	ADDHLA
	ld	l,(hl)
	ld	h,d
	res	7,h		; clear 'on fire' bit
	call	STCUR0
	ld	hl,BLANK
	call	PUTSTR		; clear smoke
	pop	de
	pop	hl
	ld	(hl),0
	push	hl
	ld	h,(ix+0)
	inc	h
	ld	e,h
	ld	l,(ix+1)
	call	STCUR0		; reposition cursor
	pop	hl

up12:	inc	hl		; try next on this row
	dec	c
	jp	nz,up8

up13:	call	CSRUP		; cursor up
	ld	a,' '		; 08h
	call	PUTC
;	call	BOLD
	ld	a,(MISSLE)
	call	PUTC
;	call	NORMAL
up14:	inc	ix
	inc	ix
	dec	b
	jp	nz,up2
	ret

; Move bombs down

DOWN:	ld	a,(NBOMBS)	; move bombs down
	ld	b,a
	ld	ix,BOMBS
dn1:	ld	e,(ix+0)	; get column into E
	ld	a,e
	or	a
	jp	z,dn8		; no bomb
	ld	a,(FRECNT)
	and	03h		; all move on 1 out of 4 ticks, missiles still
	jr	z,dn2		;  (0---)
	ld	a,(ix+2)
	or	a		; fast bomb?
	jp	z,dn8
	jp	m,dn8	;BLE	; no
	ld	a,(FRECNT)
	and	03h		; fast bombs move 3 out of 4 ticks (012-)
	cp	03h
	jp	z,dn8
dn2:	ld	d,(ix+1)	; get row into D
	ld	a,(ix+2)	; get speed
	or	a		; first movement?
	jp	m,dn3		; yes
	ld	h,e
	ld	l,d
	call	STCUR0		; else erase from old location
	ld	a,' '
	call	PUTC
	jr	dn4
dn3:	inc	e
	ld	h,e
	ld	l,d
	call	STCUR0		; cursor right
	dec	e
	res	7,(ix+2)
dn4:	inc	(ix+1)		; one row down
	inc	d
	ld	a,d
	cp	25		; below bottom edge of screen?
	jr	nc,dn6		; yes, clear bomb
	cp	24		; base line?
	jr	z,dn5		; yes, kill base
	cp	22		; barrier line?
	jr	c,dn7		; no
	call	CBARR		; check for hit on barrier
	jr	z,dn7		; no
	jr	dn6		; yes

dn5:	ld	a,(DEADB)
	or	a		; base already dead?
	jr	nz,dn7		; yes
	ld	a,(BASEX)
	ld	c,a
	ld	a,e
	cp	c
	jr	c,dn7		; e < BASEX
	sub	4+1
	cp	c		; e-4 > BASEX (e > BASEX+4) e-5 >= BASEX
	jr	nc,dn7

	ld	h,c		; BASEX
	ld	l,24
	call	STCUR0
	call	EXPLOD		; base explodes
	ld	hl,0
	ld	(BSUB),hl	; stop base movement
	ld	a,BSLEEP
	ld	(DEADB),a	; dead base
	ld	hl,NLIVES
	dec	(hl)
;	call	BOLD
	call	DLIVES		; update number of bases left

dn6:	ld	(ix+0),0	; clear bomb
	jr	dn8

dn7:	call	CSRDN		; cursor down
	ld	a,' '		; 08h
	call	PUTC
;	call	BOLD
	ld	a,(BOMB)
	call	PUTC		; display bomb on new location
;	call	NORMAL
dn8:	inc	ix
	inc	ix
	inc	ix
	dec	b
	jp	nz,dn1
	ret

; Move invaders, drop bombs.

MOVE:	ld	hl,TCOUNT
	dec	(hl)
	jp	nz,DBOMB	; drop bomb
	ld	a,(TIME)
	ld	(hl),a
	xor	a
	ld	(MFLAG),a	; moved something flag

mv2:	ld	a,(TROW)
	ld	c,a		; get current row index of invaders into C
	ld	hl,ROWY
	call	ADDHLA
	ld	a,(hl)
	ld	d,a		; get screen row into D
	or	a
	jp	z,mv14		; if zero, no invaders in this row
	ld	a,(VMOVE)
	or	a		; vertical move?
	jr	z,mv5		; branch if not

	; move down a row of invaders
	; first, erase old row

	ld	a,c
	add	a,a
	ld	hl,ROW
	call	ADDHLA
	ld	a,(hl)		; get pointer to current row
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	b,NCOLS		; loop over columns
mv3:	ld	a,(hl)		; get invader column
	or	a
	jr	z,mv4		; if zero, no invader
	push	hl
	ld	h,a
	res	7,h		; in case is on fire
	ld	l,d
	call	STCUR0
	ld	hl,BLANK
	call	PUTSTR		; erase invader from screen
	pop	hl
	ld	a,(hl)
	or	a
	jp	p,mv4
	ld	(hl),0		; if negative (on fire), mark as destroyed
mv4:	inc	hl		; next invader
	djnz	mv3

	ld	a,c
	ld	hl,ROWY
	call	ADDHLA
	inc	(hl)		; down one row
	inc	d

	; display row of invaders

mv5:	ld	a,c
	add	a,a
	ld	hl,ROW
	call	ADDHLA
	ld	a,(hl)		; get pointer to current row again
	inc	hl
	ld	h,(hl)
	ld	l,a
	ld	b,NCOLS		; loop over columns
mv6:	ld	a,(hl)		; get screen column
	or	a
	jr	z,mv13		; invader dead
	jp	m,mv12		; invader on fire
	ld	a,(HMOVE)
	add	a,(hl)		; horizontal move
	ld	(hl),a		; set new screen column
	cp	8+1		; left limit for invaders
	jr	c,mv7		; branch if <= 8
	cp	72		; right limit
	jr	c,mv8
mv7:	ld	a,1
	ld	(EFLAG),a	; hit edge
mv8:	ld	a,d		; test screen row
	cp	23		; lowest line for invaders
	jr	nz,mv9
	ld	a,1
	ld	(BFLAG),a	; hit bottom
mv9:	ld	a,d
	cp	22
	call	nc,WBARR	; wipe out any barriers
	ld	a,(MFLAG)
	inc	a		; moved something
	ld	(MFLAG),a
	push	hl
	ld	h,(hl)		; column
	ld	l,d		; row
	call	STCUR0
	call	SETIN
	ld	hl,INVADR
	call	PUTSTR
	pop	hl
	jr	mv13

mv12:	ld	a,(VMOVE)
	or	a		; vertical move?
	jr	nz,mv13		; branch if yes
	push	hl
	ld	h,(hl)
	res	7,h		; clear 'on fire' bit
	ld	l,d
	call	STCUR0
	ld	hl,BLANK
	call	PUTSTR
	pop	hl
	ld	(hl),0		; destroyed
mv13:	inc	hl		; next invader
	djnz	mv6

	ld	a,(MFLAG)
	or	a		; anything moved?
	jr	nz,mv14		; branch if yes
	ld	a,c
	ld	hl,ROWY
	call	ADDHLA
	ld	(hl),0		; no invaders in this column
mv14:	ld	a,(TROW)
	dec	a		; set next column of invaders for next call
	ld	(TROW),a
	jp	m,mv16		; time to restart from top
	ld	a,(MFLAG)
	or	a		; anything moved?
	jp	z,mv2		; do next row if not
	ld	a,(MFLAG)
	ld	(TIME),a	; new time delay
	jp	DBOMB		; drop bomb

mv16:	ld	a,TOP
	ld	(TROW),a	; moved all rows
	ld	a,(INSW)
	cpl
	ld	(INSW),a
	ld	a,(VMOVE)
	or	a
	jr	z,mv17
	xor	a
	ld	(VMOVE),a
	jr	mv18
mv17:	ld	a,(EFLAG)
	or	a		; hit edge?
	jr	z,mv18
	ld	a,(HMOVE)
	neg			; change horizontal direction
	ld	(HMOVE),a
	ld	a,(BFLAG)
	or	a
	jr	nz,mv18		; hit bottom
	ld	a,1
	ld	(VMOVE),a	; and move down one line
mv18:	xor	a
	ld	(EFLAG),a
	ld	(BFLAG),a
	; continue below

; Drop bomb

DBOMB:	ld	a,(NUMINV)	; any invaders to drop bombs?
	or	a
	ret	z
	ld	a,(FRECNT)
	and	03h		; (0---)
	ret	nz
	ld	a,(NBOMBS)
	ld	b,a
	ld	ix,BOMBS
db1:	ld	a,(ix+0)
	or	a
	jr	z,db2		; found unused bomb slot
	inc	ix
	inc	ix
	inc	ix
	djnz	db1
	ret

db2:	call	RAND
	ld	a,(BMASK)
	and	h
	ret	nz
	call	RAND
	ld	a,(DEAD)	; column of last kill
	ld	c,a
	or	a
	jp	m,db3		; branch if no kills yet

;  IF 0
;	ex	de,hl
;	ld	hl,COLCNT
;	call	ADDHLA
;	ld	a,(hl)
;	ex	de,hl
;	or	a		; last kill was of last invader in that column?
;	jr	z,db3		; branch if yes, try different column
;  ENDIF

	add	hl,hl
	jr	c,db4		; 50% chance of bomb from col of last kill
db3:	ld	a,h		; column = remaining hi order 3 bits of HL
	rlca
	rlca
	rlca
	and	07h
	ld	c,a

db4:	ld	hl,COLCNT
	call	ADDHLA
	ld	a,(hl)
	or	a		; any invaders in this column?
	jr	z,db2		; try another column if not

	ld	hl,ROW14
	ld	e,NROWS
	push	bc
	ld	b,0		; BC = column #
db5:	add	hl,bc
	ld	a,(hl)		; look for bottom invader in column
	dec	e
	or	a
	ld	bc,-NCOLS
	jr	z,db5		; BLE
	jp	m,db5
	pop	bc

	ld	a,(hl)		; drop bomb
	add	a,2		; start column = center of invader
	ld	(ix+0),a	; set column
	ld	a,e
	ld	hl,ROWY
	call	ADDHLA
	ld	a,(hl)
	ld	(ix+1),a	; set row
	ld	(ix+2),80h	; set speed
	ld	a,e
	or	a
	jr	z,db7		; top row always drops fast bombs
	call	RAND
	ld	a,(FMASK)
	and	h
	ret	nz
db7:	inc	(ix+2)		; fast bomb!
	ret

; Check for hit on spaceship.
; Called with missile coordinates in reg E (X) and D (Y).

CSHIP:	ld	a,(SHIPX)
	ld	l,a
	ld	a,e
	sub	l
	cp	4
	jr	z,cs1
	ret	nc		; missed, return NZ
cs1:	ld	a,(SHIPX)
	ld	h,a
	ld	l,d
	call	STCUR0
	call	EXPLOD		; ship explodes
	call	RAND
	ld	a,h		; use 2-high order bits of HL for table offset
	rlca
	rlca
	and	03h
	ld	hl,SPNTS
	call	ADDHLA
	ld	e,(hl)		; get ship points into DE
	ld	d,0
	ld	a,(SHIPM)
	sra	a		; fast ship?
	ld	(SHIPM),a
	jr	c,cs5
	ld	hl,200		; 200 extra!
	add	hl,de
	ex	de,hl
cs5:	ld	hl,(POINTS)
	add	hl,de		; add ship points to score
	ld	(POINTS),hl
	push	de
	ld	a,(SHIPX)
	ld	h,a
	ld	l,3		; bonus points line
	call	STCUR0
;	call	BOLD
	ld	a,'('
	call	PUTC
	pop	hl
	xor	a
	call	HLDEC		; display bonus points
	ld	a,')'
	call	PUTC
;	call	NORMAL
	call	SCORE		; update score
	ld	a,(SHIPX)
	or	80h		; disable spaceship
	ld	(SHIPX),a
	xor	a
	ret

; Check for collision with bomb.
; Called with missile coordinates in reg E (X) and D (Y), C contains ...

CBOMB:	ld	a,(NBOMBS)
	ld	b,a
	ld	ix,BOMBS
cb1:	ld	a,(ix+0)	; get bomb column
	cp	e
	jr	nz,cb3
	ld	a,(ix+2)	; get bomb speed
	or	a
	jp	m,cb3
	ld	a,(ix+1)	; get bomb row
	cp	c		; did bomb move to stilled missile last tick?
	jr	z,cb2		; yes (CRT spot has been wiped by UP routine)
	cp	d		; missile moving to bomb this tick?
	jr	nz,cb3
	call	CSRUP		; cursor up
	ld	a,' '		; 08h
	call	PUTC
	ld	a,' '		; blank the bomb
	call	PUTC
cb2:	xor	a
	ld	(ix+0),a	; destroy bomb
	ret			; return Z to destroy missile

cb3:	inc	ix
	inc	ix
	inc	ix
	djnz	cb1
	inc	b		; return NZ
	ret

; Check for hit on barrier.
; Called with missile coordinates in reg E (X) and D (Y).

CBARR:	ld	a,e
	dec	a
	add	a,a
	add	a,d		; + line#, 22 or 23
	ld	hl,BARR-22 	; line 23 barrier data in odd bytes, hence -22
	call	ADDHLA
	ld	a,(hl)
	or	a
	ret	z
	dec	a
	ld	(hl),a
	push	af
	ld	h,e
	ld	l,d
	call	STCUR0
	pop	af
	ld	hl,BCHAR
	call	ADDHLA
	ld	a,(hl)
	call	PUTC
	or	0FFh		; return NZ
	ret

; Fire missile

FIRE:	ld	a,(OKFIRE)
	or	a
	ret	z
	ld	a,(NMISIL)
	ld	b,a
	ld	ix,UPXY
f1:	ld	a,(ix+0)
	or	a		; look for spare missile slot
	jr	nz,f2
	ld	a,(BASEX)
	cp	8		; base parked?
	ret	c		; return if yes
	add	a,2
	ld	(ix+0),a	; set missile column = center of base
	ld	(ix+1),24	; set missile row
	xor	a
	ld	(OKFIRE),a	; can't fire again 'til this missile moved up
	ret
f2:	inc	ix
	inc	ix
	djnz	f1
	ret

; Wipe out barriers.
; Called with invader coordinates in reg E (X) and D (Y).
; HL = pointer to current row.

WBARR:	push	hl
	push	de
	push	bc
	ld	e,(hl)
	dec	e
	ld	a,(HMOVE)
	or	a
	jp	m,wb1
	dec	e
wb1:	ld	a,e
	add	a,a
	add	a,d
	ld	hl,BARR-22
	call	ADDHLA
	ld	b,7
	xor	a
wb2:	ld	(hl),a
	inc	hl
	inc	hl
	djnz	wb2
	pop	bc
	pop	de
	pop	hl
	ret

; Setup invade.
; B = column number

SETIN:	bit	1,b
	jr	nz,st2
	ld	a,(INSW)
	or	a
	jr	nz,st3
st1:	ld	a,INV1
	ld	(IN1),a
	ld	a,INV5
	ld	(IN5),a
	ret
st2:	ld	a,(INSW)
	or	a
	jr	nz,st1
st3:	ld	a,INV5
	ld	(IN1),a
	ld	a,INV1
	ld	(IN5),a
	ret

; Move ship

SHIP:	ld	a,(SHIPX)	; ship moving?
	ld	c,a
	or	a
	jr	z,shp1
	jp	p,shp10		; yes
shp1:	ld	hl,SCOUNT
	dec	(hl)
	jr	nz,shp50

	; new ship

	ld	(hl),NSHIP
	ld	a,1		; start spaceship
	ld	c,a
	ld	(SHIPM),a
	ld	hl,SLOSHP
	ld	(SHIPIC),hl
	ld	de,0
	call	RAND
	add	hl,hl
	jr	nc,shp5
	add	hl,hl
	jr	nc,shp5
	ld	a,(SHIPM)
	inc	a		; 25% chance of fast ship
	ld	(SHIPM),a
	ld	de,FASSHP
	ld	(SHIPIC),de
	ld	de,FASSIZ
shp5:	ld	a,h
	or	a
	jp	p,shp10
	ld	a,(SHIPM)
	neg			; 50% chance right-to-left
	ld	(SHIPM),a
	ld	hl,(SHIPIC)
	add	hl,de
	ld	(SHIPIC),hl
	ld	c,74

shp10:	; ship moving

	ld	a,(FRECNT)
	and	03h		; move once per 4 ticks - when missiles still
	jr	nz,shp40	;  (0---)
	ld	a,(SHIPM)
	or	a
	jp	m,shp20
	ld	a,c
	cp	73		; edge of screen?
	jr	z,shp60
	jr	shp30

shp20:	ld	a,c
	cp	2
	jr	z,shp60
shp30:	ld	a,(SHIPM)
	add	a,c
	ld	c,a
	ld	h,a
	ld	l,2		; ship line
	call	STCUR0
	call	DSHIP		; display ship
shp40:	ld	a,c
	ld	(SHIPX),a
	ret

shp50:	ld	a,c
	or	a
	ret	z		; ship not there at all
	ld	a,(SCOUNT)
	cp	NSHIP-SSLEEP
	jr	z,shp60
	ret	p		; BGT
shp60:	res	7,c
	ld	h,c
	ld	l,2		; ship line
	call	STCUR0
	ld	hl,BLANK
	call	PUTSTR		; remove ship
	ld	h,c		; and any score
	ld	l,3
	call	STCUR0
	ld	hl,BLANK
	call	PUTSTR
	xor	a
	ld	(SHIPX),a
	ld	a,(NUMINV)
	or	a
	ret	nz
	ld	hl,0
	ld	(BSUB),hl	; stop base moving
	ld	a,BSLEEP
	ld	(DEADB),a
	ret

DSHIP:
;	call	BOLD
	ld	hl,(SHIPIC)
	call	PUTSTR
;	jp	NORMAL
	RET

EXPLOD:	ld	a,(BELL)
	call	PUTC
;	call	BOLD
	ld	hl,EXPLD
	call	PUTSTR
;	jp	NORMAL
	RET

; Return random HL -- linear congruential sequence with maximum period,
; HL := 2053*seed + 13849, modulo 2**16
; seed := HL
; Note: high-order bits of result are "more random" than low-order.

RAND:	push	de
	ld	hl,(SEED)
	ex	de,hl
	ld	h,e
	ld	l,0
	add	hl,hl		; *512
	add	hl,de		; *513
	add	hl,hl
	add	hl,hl		; *2052
	add	hl,de		; *2053
	ld	de,13849
	add	hl,de
	ld	(SEED),hl
	pop	de
	ret

SCORE:	ld	hl,43*256+1
	call	STCUR0
;	call	BOLD
	ld	hl,(POINTS)
	ld	a,' '
	call	HLDEC
DLIVES:	ld	hl,31*256+1
	call	STCUR0
	ld	a,(NLIVES)
	call	ADEC
;	jp	NORMAL
	RET

; Initialize for start of new game

INIT0:	ld	a,NBASES
	ld	(NLIVES),a
	ld	hl,0
	ld	(POINTS),hl
	ld	a,0F8h
	ld	(FMASK),a
	ld	a,0E0h
	ld	(BMASK),a

	ld	hl,BAR1
	ld	c,6
ini01:	ld	b,10
	ld	a,STRNG
ini02:	ld	(hl),a
	inc	hl
	djnz	ini02
	ld	a,10
	call	ADDHLA
	dec	c
	jr	nz,ini01
	ret

; Initialize everything else

INIT1:	ld	hl,ROWY
	ld	b,NROWS
	ld	a,4		; Y position
ini1:	ld	(hl),a
	inc	hl
	add	a,2
	djnz	ini1

	ld	hl,ROW4
	ld	c,NROWS
ini21:	ld	b,NCOLS
	ld	a,11		; X position
ini22:	ld	(hl),a
	inc	hl
	add	a,8
	djnz	ini22
	dec	c		; next row
	jr	nz,ini21

	ld	hl,COLCNT
	ld	b,NCOLS
	ld	a,NROWS
ini23:	ld	(hl),a
	inc	hl
	djnz	ini23

	ld	hl,ZB
	ld	b,ZE-ZB
	xor	a
ini3:	ld	(hl),a
	inc	hl
	djnz	ini3

	ld	a,-1
	ld	(DEAD),a
	ld	a,NROWS*NCOLS	; number of invaders
	ld	(NUMINV),a
	ld	a,2
	ld	(BASEX),a
	ld	a,WTIME
	ld	(WLIMIT),a
	ld	a,TOP
	ld	(TROW),a
	ld	a,NTIMES
	ld	(TCOUNT),a
	ld	(TIME),a
	ld	a,NSHIP
	ld	(SCOUNT),a
	ld	a,1
	ld	(HMOVE),a
	ld	a,(FMASK)	; make more fast bombs!
	add	a,a
	ld	(FMASK),a
	ld	a,(BMASK)	; make more bombs!
	add	a,a
	jr	nz,ini4
	rra			; never gets to zero
ini4:	ld	(BMASK),a
	call	CLS
;	call	BOLD
	ld	hl,2*256+24	; H=X, L=Y
	call	STCUR0
	ld	hl,BASE
	call	PUTSTR
	ld	hl,2*256+1
	call	STCUR0
	ld	hl,TITLE1
	call	PUTSTR
;	call	NORMAL
	ld	hl,TITLE2
	call	PUTSTR

	ld	hl,1*256+22	; display barriers
	call	STCUR0
	ld	de,BARR
	call	ini7
	ld	hl,1*256+23
	ld	de,BARR+1
	call	ini7

	call	SCORE		; display score
	ld	hl,62*256+1
	call	STCUR0
;	call	BOLD
	ld	hl,(PRVMAX)
	ld	a,' '
	call	HLDEC		; display hi-score
;	call	NORMAL
;	call	TTFLSH

	ld	de,ROWY
	ld	hl,ROW4
	ld	c,NROWS		; now display invaders
	ld	a,c
	ld	(OKFIRE),a	; set flag (any nonzero value)

ini5:	ld	b,NCOLS

ini6:	push	hl
	ld	h,(hl)
	ld	a,(de)
	ld	l,a
	call	STCUR0
	call	SETIN
	ld	hl,INVADR
	call	PUTSTR
	pop	hl
	inc	hl
	djnz	ini6
	inc	de
	dec	c
	jr	nz,ini5

	ld	a,(INSW)
	cpl
	ld	(INSW),a
	ret

ini7:	ld	b,70
ini8:	ld	a,(de)
	inc	de
	inc	de
	ld	hl,BCHAR
	call	ADDHLA
	ld	a,(hl)
	call	PUTC
	djnz	ini8
	ret

ADDHLA:	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret

STCUR0:	dec	h
	dec	l
	jp	SETCUR

PUTC:
;	push	bc
;	ld	c,a
	call	PUTCH
;	pop	bc
	ret

;-----------------------------------------------------------------------
ADEC:	push	de
	push	bc
	ld	d,0
	ld	b,100
	call	ad1
	ld	b,10
	call	ad1
	add	a,'0'
	ld	c,a
	call	PUTCH
	inc	d
	ld	a,d		; return length in A
	pop	bc
	pop	de
	ret

ad1:	ld	c,'0'-1
ad2:	inc	c
	sub	b
	jr	nc,ad2
	add	a,b
	push	af
	ld	a,c
	cp	'0'
	jr	nz,ad4
	inc	d
	dec	d
	jr	z,ad5
ad4:	call	PUTCH
	inc	d
ad5:	pop	af
	ret

HLDEC:	ld	(filler),a
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
	ld	c,a
	call	PUTCH
	inc	b
	res	7,b
	ld	a,b		; return length in A
	pop	bc
	pop	de
	pop	hl
	ret

sbcnt:	ld	c,'0'-1
sb1:	inc	c
	add	hl,de
	jr	c,sb1
	sbc	hl,de
	bit	7,b
	jr	nz,sb3
	ld	a,c
	cp	'0'
	jr	nz,sb2
	ld	a,(filler)
	or	a
	ret	z
	ld	c,a
	jr	sb3
sb2:
	set	7,b
sb3:
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

TTFLSH:
	ret
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
	RET
CRLF:
;	ld	a,CR
;	call	PUTCH
;	ld	a,LF
;	call	PUTCH
	RET
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

CSRUP:
	PUSH	HL
	LD	HL, (SCR_POS)
	DEC	H
	LD	(SCR_POS), HL
	POP	HL
	RET

CSRDN:
	PUSH	HL
	LD	HL, (SCR_POS)
	INC	H
	LD	(SCR_POS), HL
	POP	HL
	RET

CSRRGT:

CSRLFT:
	RET
;-----------------------------------------------------------------------

filler:	.db	0

EXPMSG:	.DB	CR,LF,"SPACE INVADERS!  "
	.DB	"Beginner, Intermediate, or Expert? (B/I/E): ",0

HLPMSG:	.DB	CR,LF
	.DB	"The `,` (lowercase `<`) key moves left.",CR,LF
	.DB	"The `.` (lowercase `>`) key moves right.",CR,LF
	.DB	"Press the spacebar to stop and fire.",CR,LF
	.DB	"`Q` toggles sound effects off/on (for those late night "
	.DB	"sessions.)",CR,LF
	.DB	"Press any other key to stop without firing.",CR,LF,LF
	.DB	"Insert quarter in nearest programmer and press RETURN "
	.DB	"to start game: ",0

TITLE1:	.DB	"SPACE INVADERS!       ",0
TITLE2:	.DB	"Bases:      Score:          Highest: ",0

AMSG:	.DB	"Press RETURN to play again, Ctrl-C to quit: ",0

ROW:	.DW	ROW4,ROW6,ROW8,ROW10,ROW12,ROW14
ROWY:	.FILL	NROWS		; current invader row coordinates
COLCNT:	.FILL	NCOLS		; alive invaders per column

ROW4:	.FILL	NCOLS		; map of invaders, the cells contain
ROW6:	.FILL	NCOLS		;  the column if alive, zero if destroyed
ROW8:	.FILL	NCOLS		;   and -column if on fire
ROW10:	.FILL	NCOLS
ROW12:	.FILL	NCOLS
ROW14:	.FILL	NCOLS

BARR:	.FILL	80*2		; barriers
BAR1	=	BARR+11*2

BCHAR:	.DB	" -+*#"		; chars used to draw the barriers
STRNG	=	$-BCHAR-1

ZB	=	$
BOMBS:	.FILL	3*MAXBOMB	; bomb position and speed (X,Y,S)
UPXY:	.FILL	2*MAXMISL	; missile position (X,Y)

FRECNT:	.DB	0		; free-running tick counter

BSUB:	.DW	0		; base movement subroutine address
DEADB:	.DB	0
EFLAG:	.DB	0		; edge condition flag
BFLAG:	.DB	0		; bottom flag
SHIPX:	.DB	0		; spaceship column
VMOVE:	.DB	0		; vert. move
HMOVE:	.DB	0		; horiz. move
ZE	=	$

SEED:	.DW	0

NMISIL:	.DB	3		; number of simultaneous missiles in flight
NBOMBS:	.DB	1		; number of simultaneous bombs

DEAD:	.DB	-1		; if >0, column word index of last invader kill
OKFIRE:	.DB	1		; flag: previous missile has moved above base
FMASK:	.DB	0
BMASK:	.DB	0
SHIPM:	.DB	0		; spaceship mode

NUMINV:	.DB	0		; total number of invaders
BASEX:	.DB	0		; initial X position of base
WLIMIT:	.DB	0
NLIVES:	.DB	0		; number of bases to start with

MFLAG:	.DB	0
TROW:	.DB	0
TCOUNT:	.DB	0
SCOUNT:	.DB	0

BELL:	.DB	7		; bell/no bell character

TIME:	.DB	NTIMES

PNTS:	.DB	30,25,20,15,10,5
SPNTS:	.DB	50,100,150,200
POINTS:	.DW	0		; current score
PRVMAX:	.DW	0		; high score

BASE:	.DB	" -- -- ",0

INSW:	.DB	0		; invader 'switch' selector
INVADR:	.DB	" "
IN1:	.DB	"/-O-"
IN5:	.DB	"\ ",0
INV1	=	'/'
INV5	=	'\'

SHIPIC:	.DW	0		; current ship pic
SLOSHP:	.DB	" -=O=- ",0	; slow ship
FASSHP:	.DB	"  =*>>>",0	; fast ship going right
FASSIZ	=	$-FASSHP
	.DB	"<<<*=  ",0	; fast ship going left

EXPLD:	.DB	"*****",0
BLANK:	.DB	"     ",0

MISSLE:	.DB	'!'
BOMB:	.DB	'O'

	.FILL	256
stack	=	$

	.END
