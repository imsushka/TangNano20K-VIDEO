SCR_POS		= 000Ch
PUT_CHR		= 0FF90h

	.org	0100h

;	extrn	CLS,CSROFF,CSRON,SETCUR,CLREOL
;	extrn	UCASE,PUTCH,PUTSTR,TTFLSH,INKEY,GETCH
;	extrn	DELAY,INIT,EXIT

ESC	=	1Bh
CR	=	0Dh
LF	=	0Ah

; Screen size, playing field is one row shorter to make space for the status
; line. Screen buffer has one-char margin around it (i.e. two extra rows and
; columns) to prevent the black blocks (ants) from escaping into the void...

SCRW	=	64
SCRH	=	24

MAPW	=	SCRW-2
MAPH	=	SCRH-1

BUFW	=	MAPW+2
BUFH	=	MAPH+2

; Figure codes

PLAYER	=	17H	; player (spider), moving inside the claimed area
MOVING	=	7Fh	; player, moving/collecting (eatable)
ANT	=	0dH	; dark block (ant)
BCKGND	=	08H	; inside background, invisible
BORDER	=	20h	; outside background, invisible
FLY	=	'O'	; round ball (fly)
WALL	=	'S'	; wall (claimed area)
TRAIL	=	'*'	; trail character
LFILL	=	00h	; used during fill to mark a border around the wall
LSTART	=	0Ah	; marks the start of the loop

; Status message coordinates (screen columns)

XTIME	=	48	; time
XSCORE	=	1	; current score
XTOTAL	=	16	; total score
XLIVES	=	32	; remaining lives

YSTLN	=	0	; screen row of status line


#DEFINE	LD_IX_BC	PUSH BC \ POP IX
#DEFINE	LD_IX_DE	PUSH DE \ POP IX
#DEFINE	LD_IX_HL	PUSH HL \ POP IX
;-----------------------------------------------------------------------

;	cseg

;START:
;	ld	sp,STACK	; setup stack
;	call	INIT		; system-dependent initializations
;	call	CSROFF		; turn off cursor
;;	call	PRE		; title screen
;XLOOP:
	call	XONIX
;	jp	FINISH
;;	jp	XLOOP		; over and over

;-----------------------------------------------------------------------

; Exit to system

;FINISH:
;	call	CSRON		; turn cursor on
;  IF 0
;	call	HOME
;	call	CLS		; clear screen
;  ELSE
;	ld	h,0
;	ld	l,SCRH-1
;	call	SETCUR
;  ENDIF
;	jp	EXIT		; exit to system

;	ld	a,'F'
;	RST	08h

	RET	
;	jp	0		; exit to system

;-----------------------------------------------------------------------
; Actual game starts here

XONIX:
	ld	(TMPSP),sp	; save startup stack pointer
	ld	de,(FLYDAT+4)	; NOTE: this assumes FLYDAT was initialized
	ld	hl,0		;  at compile time to all zeros!
	ld	a,20h
	cp	e
	jr	nz,B1
	xor	a
	cp	d
	jr	z,B2
B1:
	ld	a,'0'
	ld	(TOTAL+3),a	; not used anyway
B2:
	ld	(TOTAL+1),hl
	ld	a,'0'
	ld	(TOTAL),a
	ld	a,03h		; H = number of flies, L = number of lives
	ld	(NUMFLY),a
	ld	a,05h		; H = number of flies, L = number of lives
	ld	(LIVES),a
	call	INIFLY		; initialize fly table
	call	SCRN
	call	STMSG		; wait for key to start
	jr	B3

;-----------------------------------------------------------------------
BEGIN:
	ld	sp,(TMPSP)	; reset stack
	call	SCRN		; draw screen
B3:
;	ld	a,'B'
;	RST	08h

	;ld	hl,WALL SHL 8 OR 00h ; H=WALL, L=00h
	ld	a,WALL
	ld	(SCRNCH),a	; NUMANT=0, SCRNCH=WALL
	ld	a,0
	ld	(NUMANT),a	; NUMANT=0, SCRNCH=WALL
	ld	hl,SCRBUF + (BUFW + BUFW + (BUFW / 2) + 1)	; starting player postion is
	ld	(PLYADR),hl		;  at the middle-top of playing area
	ld	(STARTP),hl
	ld	(hl),PLAYER	; store player
	call	DPOBJ		; display it on the screen
	call	DPFLY		; setup and display active flies
	ld	hl,0
	ld	(SCORE),hl	; clear score
NEXTL:
;	ld	a,'L'
;	RST	08h

	ld	hl,0
	ld	(TIME),hl	; clear time
	ld	sp,(TMPSP)	; reset stack
	call	INIANT		; initialize ant table
NEXT:
;	ld	a,'N'
;	RST	08h

	ld	sp,(TMPSP)	; reset stack
	xor	a
	ld	(LSTKEY),a	; clear last key
	call	STLINE		; display status line
	call	STATUS		; display initial values
MLOOP:
	call	MVFLY		; move flies
	call	MVPLYR		; move spider (player)

;	ld	a,'1'
;	RST	08h

	ld	de,ANTDAT
	call	CHKMOV		; move ant 1

	call	MVFLY		; move flies
	call	INCT		; increment time

;	ld	a,'2'
;	RST	08h

	ld	de,ANTDAT+6
	call	CHKMOV		; move ant 2

	call	MVFLY		; move flies
	call	MVPLYR		; move spider (player)

;	ld	a,'3'
;	RST	08h

	ld	de,ANTDAT+12
	call	CHKMOV		; move ant 3

	call	MVFLY		; move flies
	call	INCT		; increment time

;	ld	a,'4'
;	RST	08h

	jp	MLOOP		; loop

;-----------------------------------------------------------------------
; Draw starting screen

SCRN:
	call	CLRMAP		; clear screen and playing field
	ld	c,WALL		; wall (collected area) character
	ld	de, BUFW - MAPW + 1
	ld	hl, SCRBUF + BUFW + 1; playfield starts on 2nd row of buffer
	call	HWALL		; draw 2-char high top wall
	call	VWALL		; draw middle area and 3-char wide walls
	call	HWALL		; draw 2-char high bottom wall
	ret

HWALL:	call	F4		; execute twice
F4:	ld	b,MAPW-1	; playable area width = 61
F1:	ld	(hl),c
	call	DPOBJ		;; this can be done faster
	inc	hl
	djnz	F1
	ld	(hl),c
	call	DPOBJ		;;
	add	hl,de
	ret

VWALL:	ld	b,MAPH-4	; playable area height = 23
F3:	ld	(hl),c		; left wall is 3 chars wide
	call	DPOBJ		;;
	inc	hl
	ld	(hl),c
	call	DPOBJ		;; this can be done faster
	inc	hl
	ld	(hl),c
	call	DPOBJ		;;
	ld	a,MAPW-3-3	; empty area
F2:	inc	hl
	ld	(hl),BCKGND
	dec	a
	jr	nz,F2
	inc	hl
	ld	(hl),c		; right wall is also 3 chars wide
	call	DPOBJ		;;
	inc	hl
	ld	(hl),c
	call	DPOBJ		;;
	inc	hl
	ld	(hl),c
	call	DPOBJ		;;
	add	hl,de
	djnz	F3
	ret

STMSG:	ld	hl,256*(64-STLEN)/2+YSTLN
	call	SETCUR
	ld	hl,STSTR
	call	PUTSTR
;	call	TTFLSH
st0:	call	GETCH
	call	UCASE
	cp	3
	jp	z,ENDGAM
	cp	'S'
	jr	nz,st0
;	ld	hl,0*256+YSTLN
;	call	SETCUR
;	call	CLREOL
	ret

STSTR:	.db	"Press S to Start",0
STLEN	=	$-STSTR-1

;-----------------------------------------------------------------------
; Display status line

STLINE:	ld	hl,XTIME*256+YSTLN
	call	SETCUR
	ld	hl,STIME
	call	PUTSTR
	ld	hl,XSCORE*256+YSTLN
	call	SETCUR
	ld	hl,SSCORE
	call	PUTSTR
	ld	hl,XTOTAL*256+YSTLN
	call	SETCUR
	ld	hl,STOTAL
	call	PUTSTR
	ld	hl,XLIVES*256+YSTLN
	call	SETCUR
	ld	hl,SLIVES
	jp	PUTSTR

STIME:	.db	"Time: ",0
SSCORE:	.db	"Score: ",0
STOTAL:	.db	"Total: ",0
SLIVES:	.db	"Lives: ",0

;-----------------------------------------------------------------------
; Update status line fields

STATUS:	ld	de,(TIME)
	ld	hl,256*(XTIME+6)+YSTLN
	call	WNUM		; display time
	ld	de,(SCORE)
	ld	hl,256*(XSCORE+7)+YSTLN
	call	WNUM		; display score
	ld	hl,256*(XTOTAL+7)+YSTLN
	call	SETCUR
	ld	a,(TOTAL)
;	ld	c,a
	call	PUTCH
	ld	hl,256*(XTOTAL+8)+YSTLN
	ld	de,(TOTAL+1)
	call	WNUM		; display total
	ld	hl,256*(XLIVES+7)+YSTLN
	call	SETCUR
	ld	a,(LIVES)
	call	W1		; display lives
	ret

; Display BCD number

WNUM:	call	SETCUR
WNUM1:	ld	a,d
	call	AHEX
	ld	a,e
W1:	call	AHEX
	ret

;-----------------------------------------------------------------------
; Initialize the flies table

INIFLY:
	ld	ix, FLYDAT	; point to end of flies table
	ld	b, 80h		; home
	ld	c, 00h		; mask
	ld	de, SCRBUF + (BUFW * ((BUFH / 2) + 2) + (BUFW / 2) - 9)
	ld	hl, DTBL1
	ld	a,17		; max number of flies (table size)
	ld	(COUNT),a
	ld	a,4		; 4 tables
	ld	(COUNT2),a
S1:
	ld	(ix+0),e
	ld	(ix+1),d
	ld	(ix+2),l
	ld	(ix+3),h
	ld	(ix+4),c
	ld	(ix+5),b
	ld	a, 40		; 20 words = 40 bytes
	call	ADDHLA		; point to next data table
	ld	a,(COUNT2)
	dec	a
	jr	nz, S6
	ld	hl, DTBL1
	ld	a,4
S6:
	ld	(COUNT2),a
	inc	de		; inc screen address (X+1)
;	inc	de		; inc screen address (X+1)
	push	bc
	ld	bc,6
	add	ix,bc
	pop	bc
	ld	a,(COUNT)
	dec	a
	ld	(COUNT),a
	jr	nz, S1		; loop until all flies are initialized
	ret

;-----------------------------------------------------------------------
; Display the active flies at their initial position

DPFLY:
	ld	ix,FLYDAT
	ld	b, BCKGND
	ld	c, 20h
	ld	a,(NUMFLY)	; get number of active flies into A
S3:
	ld	l,(ix+0)	; get screen address into HL
	ld	h,(ix+1)
	ld	(hl),FLY	; store fly
	call	DPOBJ		; display it
	ld	(ix+4),c	; replace 3rd word
	ld	(ix+5),b
	ld	de,6
	add	ix,de
	dec	a
	jr	nz, S3
	ret

;-----------------------------------------------------------------------
; Initialize the ants table

INIANT:
	ld	ix, ANTDAT	; point to end of ants table
	ld	b, 08h
	ld	c, 00h
	ld	de, SCRBUF + (BUFW * (BUFH - 3) + (BUFW / 2))
	ld	hl, DTBL1
	ld	a,3
	ld	(COUNT),a
S4:
	ld	(ix+0),e
	ld	(ix+1),d
	ld	(ix+2),l
	ld	(ix+3),h
	ld	(ix+4),c
	ld	(ix+5),b
	ld	a,40
	call	ADDHLA
	push	bc
	ld	bc,6
	add	ix,bc
	pop	bc
	ld	a,(COUNT)
	dec	a
	ld	(COUNT),a
	jr	nz, S4
	ret

;-----------------------------------------------------------------------
; Display the active ants

DPANT:
	ld	ix,ANTDAT
	ld	b, WALL
	ld	c, 80h
	ld	a,(NUMANT)	; get number of active ants into A
S5:
	ld	l,(ix+0)	; get screen address into HL
	ld	h,(ix+1)
	ld	(hl),ANT	; store ant
	call	DPOBJ		; display it
	ld	(ix+4),c	; replace 3rd word
	ld	(ix+5),b
	ld	de,6
	add	ix,de
	dec	a
	jr	nz, S5
	ret

;-----------------------------------------------------------------------
ADDHLA:
;	PUSH	AX
;	ld	a,40		; 20 words = 40 bytes
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret

;-----------------------------------------------------------------------
; HL = HL / C, remainder in A

DIV8:
	xor	a
	ld	b,16
dv81:
	add	hl,hl
	rla
	cp	c
	jr	c,dv82
	sub	c
	inc	hl
dv82:
	djnz	dv81
	ret

;-----------------------------------------------------------------------
; Bounce flies around

;  IF 0
;MVFLY:
;	ld	a,17		; max number of flies
;	ld	(COUNT),a
;	ld	de,FLYDAT	; DE = start of flies table
;D1:
;	call	CHKMOV		; move fly
;
;	ld	a,1
;	call	DELAY		; delay
;
;	ld	hl,6
;	add	hl,de		; next fly
;	ex	de,hl
;
;	ld	a,(COUNT)
;	dec	a
;	ld	(COUNT),a
;	jr	nz,D1
;
;	ret
;  ELSE
MVFLY:
	ld	a,17		; max number of flies
	ld	(COUNT),a
	ld	de,FLYDAT	; DE = start of flies table
D1:
	call	CHKMOV		; move fly

	ld	hl,6
	add	hl,de		; next fly
	ex	de,hl

	ld	a,(COUNT)
	dec	a
	ld	(COUNT),a
	jr	nz,D1

	ld	a,1
	call	DELAY		;;

	ret
;  ENDIF

;-----------------------------------------------------------------------
; Display the player character, leaves a trail if moving trough empty space.
; HL = new position (screen address)
; DE = old position (screen address)
; Returns old screen char in C, new one in A.

DPLYR:
	ld	a,(SCRNCH)	; get saved screen character (under player)
	ld	c,a		;  into C
	cp	BCKGND		; empty space?
	jr	nz,Q1		; jump if not, restore old character
	ld	a,TRAIL		; else leave a trail
Q1:
	ld	(de),a		; store character
	ex	de,hl
	call	DPOBJ		; display it
	ex	de,hl

	ld	a,(hl)		; get character from next pos
	ld	(SCRNCH),a	; remember it
	cp	WALL
	jr	z,Q2
	ld	(hl),MOVING
	call	DPOBJ
	ret
Q2:
	ld	(hl),PLAYER
	call	DPOBJ
	ret

;-----------------------------------------------------------------------
; Move player around

MVPLYR:
	ld	hl,(PLYADR)	; get player position (screen address) into HL
	ld	d,h		;  and into DE
	ld	e,l
	ld	a,(LSTKEY)	; get last key
	ld	b,a		;  into B
	call	INKEY		; check for new key
	cp	3		; ^C ends game
	jp	z,ENDGAM
RKEY:
	cp	'd'
	jr	z,RIGHT
	cp	'6'
	jr	z,RIGHT		; jump if moving right
LKEY:
	cp	'a'
	jr	z,LEFT
	cp	'4'
	jr	z,LEFT		; jump if moving left
UKEY:
	cp	'w'
	jr	z,UP
	cp	'8'
	jr	z,UP		; jump if moving up
DKEY:
	cp	's'
	jr	z,DOWN
	cp	'2'
	jr	z,DOWN		; jump if moving down
	ld	a,b		; else use last direction key
	or	a		;  if valid
	jr	nz,RKEY		; check again
	ret

RIGHT:
	inc	hl		; HL = new position
	jp	MOVE

LEFT:
	dec	hl		; HL = new position
	jp	MOVE

UP:
	push	de
	ld	de,-BUFW
	add	hl,de		; HL = new position
	pop	de
	jp	MOVE

DOWN:
	push	de
	ld	de,BUFW
	add	hl,de		; HL = new position
	pop	de

MOVE:
	ld	b,a		; get new key code into B
	ld	a,(hl)		; see what's in the new position
	cp	BORDER		; trying to move outside game area?
	jr	z,STOP		; jump if yes
	cp	ANT		; ant?
	jp	z, KILLED	; yes, player killed
	and	24h
	jp	nz, CRASH	; else jump if not BCKGND or WALL
	call	DPLYR		; move player on screen
	ld	(PLYADR),hl	; remember new position
	xor	c		; compare new char under player with old
	jr	z,STOP		; jump if same
	xor	c		; restore new char
	cp	WALL		; touched wall again?
	jr	z,FILL		; then claim space
	ex	de,hl
	ld	(STARTP),hl
STOP:
	ld	a,b
	ld	(LSTKEY),a
	ret

;-----------------------------------------------------------------------
; Claim collected space, fill area if there are no flies inside

DBGFILL	=	0

FILL:
	ld	a,(NUMFLY)	; get number of active flies
	ld	b,a		;  into B
	ld	ix,FLYDAT	; point to flies data block
L1:
	ld	e,(ix+0)	; get screen address of a fly into DE
	ld	d,(ix+1)
L2:
	inc	de		; see what's to the right of it
	ld	a,(de)
	cp	WALL		; wall? (collected space)
	jr	z,L3		; jump if yes
	cp	TRAIL		; trail?
	jr	nz,L2		; loop if not
L3:
	dec	de		; see what's to the left
	ld	a,(de)
	cp	BCKGND+1	; > BCKGND?
	jr	nc,L3		; loop if yes
	or	a		; LFILL loop-around-the-wall char?
	jr	z,L8		; branch if yes
	ld	c,2
	ld	hl,LRGT		; direction = right
	ld	(GOADDR),hl
L4:
	ld	a,0Ah		; LSTART
	ld	(de),a		; mark this cell as the starting point
;  IF DBGFILL
;	ex	de,hl
;	call	DPOBJ
;	ex	de,hl
;  ENDIF
L5:
	ld	hl,(GOADDR)	; get routine address
	jp	(hl)		; go to routine

L6:
	ld	hl,LRGT
	ld	a,l		; LOW LRGT
	ld	hl,(GOADDR)
	cp	l
	jr	z,L7

LRGT:
	ld	h,d		; get screen address into HL
	ld	l,e
	inc	hl		; see what's right
	ld	a,(hl)
	cp	0Bh		; LSTART+1 ; > LSTART?
	jr	nc,LUP
	ex	de,hl
	ld	hl,LDN
	jr	LNEXT

LUP:
	ld	hl,-BUFW
	add	hl,de		; see what's above
	ld	a,(hl)
	cp	0Bh		; LSTART+1 ; > LSTART?
	jr	nc,LLFT
	ex	de,hl
	ld	hl,LRGT
	jr	LNEXT

LLFT:
	ld	h,d
	ld	l,e
	dec	hl		; see what's left
	ld	a,(hl)
	cp	0Bh		; LSTART+1 ; > LSTART?
	jr	nc,LDN
	ex	de,hl
	ld	hl,LUP
	jr	LNEXT

LDN:
	ld	hl,BUFW
	add	hl,de		; see what's below
	ld	a,(hl)
	cp	0Bh		; LSTART+1 ; > LSTART?
	jr	nc,L6
	ex	de,hl
	ld	hl,LLFT
LNEXT:
	ld	(GOADDR),hl
	cp	0Ah		; LSTART
L7:
	ld	a,0		; LFILL
	ld	(de),a
;  IF DBGFILL
;	ex	de,hl
;	call	DPOBJ
;	ex	de,hl
;  ENDIF
	jr	nz,L5
	dec	c
	jr	nz,L4
L8:
	ld	de,6
	add	ix,de
	dec	b		; decrement fly count
	jp	nz,L1		; if not zero, do next fly
; -------------------------------------
	ld	hl, SCRBUF + (BUFW * 3 + 3)
	ld	b, WALL
	ld	c, BCKGND
L9:
	inc	hl
	ld	de, SCRBUF + (BUFW * (BUFH - 1))
	call	CPHLDE
	jr	c,L13
	ld	a,(hl)
	or	a		; LFILL
	jr	z,L11
	and	9
	cp	c
	jr	nz,L9
L10:
	ld	(hl),b		; WALL (fill claimed territory)
	call	DPOBJ		; display it
	ex	de,hl
	ld	hl,(SCORE)	; get score
	call	IHLDEC		; increment the BCD number
	ld	(SCORE),hl	; store new value
	ex	de,hl
	jr	L9

L11:
	ld	(hl),c		; BCKGND
;  IF DBGFILL
;	call	DPOBJ
;  ENDIF
L12:
	inc	hl
	ld	a,(hl)
	cp	TRAIL
	jr	z,L10
	cp	b
	jr	z,L9
	cp	9
	jr	c,L11
	jr	L12

L13:
	ld	hl,(SCORE)	; get BCD score
	ld	a,9
	cp	h		; > 999?
	jp	nc, NEXT	; branch if not

	ex	de,hl
	ld	hl,256*(XSCORE+7)+YSTLN
	call	WNUM		; display score
	ld	hl,(TOTAL+1)
	ld	a,l
	add	a,e		; add to BCD total
	daa
	ld	l,a
	ld	a,h
	adc	a,d
	daa
	ld	h,a
	ld	(TOTAL+1),hl
	ld	a,(TOTAL)
	adc	a,0
	ld	(TOTAL),a
	ld	hl,(LIVES)	; L=LIVES, H=NUMFLY
	ld	a,2
	add	a,l		; 2 additional lifes
	daa
	ld	l,a
	inc	h		; one more fly to make it harder
	ld	(LIVES),hl
	jp	BEGIN

;-----------------------------------------------------------------------
; Move thing (fly or ant), called with DE = object data block

CHKMOV:
	push	de

	push	de
	pop	ix		; IX now points to data block

	ld	(TMP2),ix
	ld	e,(ix+0)	; get screen address into DE
	ld	d,(ix+1)
	ld	l,(ix+2)	; get data table address into HL
	ld	h,(ix+3)
	ld	c,(ix+4)	; pop 'home' and mask into BC
	ld	b,(ix+5)

	push	hl
	pop	ix		; IX now points to data table

	ld	a,c
	ld	(TMP1),a

NP0:
	ld	l,(ix+0)	; get direction (offset into screen) into HL
	ld	h,(ix+1)
	add	hl,de		; add object screen address
	ld	a,(hl)		; see what's there
	cp	PLAYER		; player?
	jr	nz,NP1		; jump if not
	or	80h		; else flag it
NP1:
	ld	c,a
	ld	l,(ix+2)	; get next direction
	ld	h,(ix+3)
	add	hl,de		; add object screen address
	ld	a,(hl)		; see what's there
	cp	PLAYER		; player?
	jr	nz,NP2		; jump if not
	or	80h		; else flag it
NP2:
	or	c		; merge with previous flag
	ld	c,a
	ld	(TMP3),a

	ld	l,(ix+4)	; get next direction (=sum of the two above)
	ld	h,(ix+5)
	add	hl,de		; add object screen address
	ld	a,(hl)		; see what's there
	cp	PLAYER		; player?
	jr	nz,NP3		; jump if not
	or	80h		; else flag it
NP3:
	or	c		; merge with previous flag
	cp	b		; compare with B (non-active flies have the flag set)
	jr	Z, OKMOVE	; jump if same (ignore collision), OK to move

	ld	c,a
	ld	a,(TMP1)
	and	c
	jr	nz,COLLIS

	ld	l,(ix+8)	; get routine address
	ld	h,(ix+9)
	push	de
	ld	de,10
	add	ix,de		; IX = next data table row
	pop	de

	jp	(hl)		; exec routine

NP4:
	ld	a,(TMP3)
	cp	b
	jr	nz,NP0		; loop

	push	de
	ld	de,10
	add	ix,de

	ld	l,(ix+8)	; get routine address
	ld	h,(ix+9)
	ld	de,10
	add	ix,de
	pop	de

	jp	(hl)		; next direction

OKMOVE:
	ld	a, (de)		; get object from screen (old address)
	ld	c, a		; save it in C
	ld	a, (hl)		; get whatever is at new address
	ld	(de), a		; store in old position
	ex	de, hl
	call	DPOBJ		; restore it on the screen
	ex	de, hl
	ld	(hl), c		; move object to new position
	call	DPOBJ		; and update it on the screen too
	ex	de, hl		; get new screen address into HL
	ld	c,(ix+6)	; get table address into BC
	ld	b,(ix+7)
	ld	ix,(TMP2)
	ld	(ix+0),e	; store new screen address
	ld	(ix+1),d
	ld	(ix+2),c	; store new table address in object data block
	ld	(ix+3),b
LRET:
	pop	de
	ret

COLLIS:
;	ld	sp,(TMPSP)
	pop	de

;	PUSH	AF
;	LD	A, 'C'
;	RST	08h
;	POP	AF

	jp	m, KILLED	; jump if hi-bit flag set (player killed)
	jp	CRASH

CPHLDE:	ld	a,d
	cp	h
	ret	nz
	ld	a,e
	cp	l
	ret

;-----------------------------------------------------------------------
; Display object on the screen at the specified map address

DPOBJ:	push	af
	push	bc
	push	de

	push	hl
	ld	de,SCRBUF + (BUFW + 1)
	or	a
	sbc	hl,de
	ld	c,BUFW
	call	DIV8
	ld	h,a
	inc	h
	inc	l
	call	SETCUR
	pop	hl

	ld	a,(hl)
	ld	c,'#'
	cp	PLAYER
	jr	z,cc1
	cp	MOVING
	jr	z,cc1

	ld	c,' '
	cp	ANT
	jr	z,cc1
	cp	BCKGND
	jr	z,cc1
	cp	BORDER
	jr	z,cc1
	ld	c,a
cc1:
	ld	a,c
	call	PUTCH
;	call	TTFLSH
	pop	de
	pop	bc
	pop	af
	ret

DTBL1:	.dw	-BUFW,     1, -BUFW+1, DTBL1, NP4	; U R RU
	.dw	    1,  BUFW,  BUFW+1, DTBL2, NP0	; R D RD
	.dw	   -1, -BUFW, -BUFW-1, DTBL4, NP0	; L U LU
	.dw	 BUFW,    -1,  BUFW-1, DTBL3, LRET	; D L LD

DTBL2:	.dw	    1,  BUFW,  BUFW+1, DTBL2, NP4	; R D RD
	.dw	-BUFW,     1, -BUFW+1, DTBL1, NP0	; U R RU
	.dw	 BUFW,    -1,  BUFW-1, DTBL3, NP0	; D L LD
	.dw	   -1, -BUFW, -BUFW-1, DTBL4, LRET	; L U LU

DTBL3:	.dw	 BUFW,    -1,  BUFW-1, DTBL3, NP4	; D L LD
	.dw	    1,  BUFW,  BUFW+1, DTBL2, NP0	; R D RD
	.dw	   -1, -BUFW, -BUFW-1, DTBL4, NP0	; L U LU
	.dw	-BUFW,     1, -BUFW+1, DTBL1, LRET	; U R RU

DTBL4:	.dw	   -1, -BUFW, -BUFW-1, DTBL4, NP4	; L U LU
	.dw	 BUFW,    -1,  BUFW-1, DTBL3, NP0	; D L LD
	.dw	-BUFW,     1, -BUFW+1, DTBL1, NP0	; U R RU
	.dw	    1,  BUFW,  BUFW+1, DTBL2, LRET	; R D RD


;-----------------------------------------------------------------------
; Increment time and check if we ran out of time

INCT:
;	ld	a,'T'
;	RST	08h

	ld	hl,(TIME)
	call	IHLDEC
	ld	(TIME),hl
	ex	de,hl
	ld	hl,256*(XTIME+6)+YSTLN
	call	WNUM		; display time
	ld	a,99h
	cp	e
	jr	nz,inc1
	cp	d
	jp	z, ENDGAM	; end game when time reaches 9999
inc1:	ld	a,d
	and	0F0h		; get the most significative nibble into A
	rrca
	rrca
	rrca
	rrca
	cp	3
	ret	nc		; return if >= 3 (all ants are active)
	ld	e,a
	ld	a,(NUMANT)
	cp	e		; check against current number of ants
	ret	z		; return if same
	ld	a,e
	ld	(NUMANT),a	; else a new ant is born
	ret

; Increment BCD number in HL

IHLDEC:	ld	a,1
	add	a,l
	daa
	ld	l,a
	ld	a,0
	adc	a,h
	daa
	ld	h,a
	ret

;-----------------------------------------------------------------------
; Killed by an ant

KILLED:
;	ld	a,'K'
;	RST	08h

	ld	de,(PLYADR)
	ld	hl,SCRBUF + (BUFW + (BUFW / 2) + 1)	; starting player postion is
	ld	(STARTP),hl	; reset player position to default (middle top)
	jp	CRASH1

;-----------------------------------------------------------------------
; Killed by a fly or by running over own trail

CRASH:
;	ld	a,'c'
;	RST	08h

	ld	hl,(PLYADR)
	ex	de,hl
	ld	hl,(STARTP)	; reset player position to start of trail

CRASH1:
	ld	(PLYADR),hl
	call	DPLYR
	ld	hl,SCRBUF + BUFW	; clear trail
;	ld	bc,TRAIL SHL 8 OR BCKGND ; B=TRAIL, C=BCKGND
	ld	b,TRAIL
	ld	c,BCKGND
clr:
	inc	hl
	ld	a,(hl)
	cp	b		; trail character?
	jr	nz, ncl		; jump if not
	ld	(hl),c		; else replace it with background
	call	DPOBJ		; update screen
ncl:
	ld	de,SCRBUF + (BUFW * (BUFH - 1))
	call	CPHLDE
	jr	nz, clr		; loop if not
	ld	a,(LIVES)
	add	a,99h		; -1 BCD
	daa
	ld	(LIVES),a	; decrement life count
	jp	z, ENDGAM	; end game if zero

	ld	ix, ANTDAT
	ld	b,3
clrn:
	ld	l,(ix+0)	; get screen address into HL
	ld	h,(ix+1)
	ld	(hl),WALL	; erase ants from the screen
	call	DPOBJ		; update screen
	ld	de,6
	add	ix,de
	djnz	clrn
	jp	NEXTL		; play next life

;-----------------------------------------------------------------------
; Exit game back to menu

ENDGAM:	ld	sp,(TMPSP)

	ld	a,'E'
	RST	08h

	ret

;-----------------------------------------------------------------------
; Clear screen and playing field

CLRMAP:	call	CLS
	ld	hl,SCRBUF
	ld	de,BUFW*BUFH
clm:	ld	(hl),BORDER	; use the "outside" character
	inc	hl
	dec	de
	ld	a,d
	or	e
	jr	nz,clm
	ret

;-----------------------------------------------------------------------
; Display accum as hexadecimal (BCD) value

AHEX:	push	af
	rrca
	rrca
	rrca
	rrca
	call	NIBBLE
	pop	af
NIBBLE:	and	0Fh
	add	a,90h
	daa
	adc	a,40h
	daa
;	ld	c,a
	jp	PUTCH

;-----------------------------------------------------------------------
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

;	dseg

COUNT:	.db	0
COUNT2:	.db	0
TMP1:	.db	0
TMP2:	.dw	0
TMP3:	.db	0

LIVES:	.db	0
NUMFLY:	.db	0		; number of active flies

NUMANT:	.db	0		; number of active ants
SCRNCH:	.db	0		; character under spider

PLYADR:	.dw	0
STARTP:	.dw	0
LSTKEY:	.db	0
TIME:	.dw	0
SCORE:	.dw	0
TOTAL:	.dw	0, 0		; TOTAL+3 is set but not used

; Object data has the following structure
;	dw	screen_addr	; current position
;	dw	dir_offset	; current direction
;	db	home		; object "home" or territory
;	db	mask

ANTDAT:	.fill	8*6, 0		; ant data (max 3 ants)
FLYDAT:	.fill	32*6, 0		; fly data (max 17 flies)

GOADDR:	.dw	0		; rotine address, used during fill operation
TMPSP:	.dw	0

;	.fill	256, 0
;STACK	=	$

SCRBUF:

	.end
