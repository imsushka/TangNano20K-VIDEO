;--------------------------------------------------------------------------
; A buffer for exchanging messages with the SD card
;--------------------------------------------------------------------------
GPIO_OUT_CACHE	= SD_VAR
SD_TYPE		= SD_VAR + 01h
SD_SCRATCH	= SD_VAR + 02h

; Port assignments for GPIO
GPIO_IN		= $E8
GPIO_OUT	= $E8

; Bit-assignments for the General Purpose I/O ports
GPIO_OUT_SD_MOSI	= $01
GPIO_OUT_SD_CLK		= $02
GPIO_OUT_SD_SSEL	= $04
GPIO_OUT_3      	= $08
GPIO_OUT_4  		= $10
GPIO_OUT_5  		= $20
GPIO_OUT_6  		= $40
GPIO_OUT_7  		= $80

GPIO_IN_0      		= $01
GPIO_IN_1       	= $02
GPIO_IN_2       	= $04
GPIO_IN_3      		= $08
GPIO_IN_4      		= $10
GPIO_IN_5    		= $20
GPIO_IN_SD_DET		= $40
GPIO_IN_SD_MISO		= $80

;--------------------------------------------------------------------------
; SD_ERROR - display SD card error message
; Destroys: HL
;--------------------------------------------------------------------------
SD_ERROR:
	CALL	PRINT_MSG_TTY
	.DB	"- Error with SD card",CR,BIT7+LF

	JP	MONIT		; Restart monitor

;--------------------------------------------------------------------------
; SD_DETECT- check if physical SD card inserted
; Destroys: A, HL
;--------------------------------------------------------------------------
SD_DETECT:
	IN	A, (GPIO_IN)		
	AND	GPIO_IN_SD_DET
	RET	Z		; RET if card inserted

; Display error and exit if no SD card in slot
	CALL	PRINT_MSG_TTY
	.DB	"- SD slot empty",CR,BIT7+LF

	JP	MONIT		; Restart monitor

;--------------------------------------------------------------------------
; SSEL = HI (de-assert)
; Wait at least 1msec after power up
; Send at least 74 (80) SCLK rising edges
; Destroys: A, B, DE
;--------------------------------------------------------------------------
SD_BOOT:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	B, 10		; 10*8 = 80 bits to read

SD_BOOT1:
	CALL	SPI_READ8	; Read 8 bits (causes 8 CLK x-itions)
	DJNZ	SD_BOOT1	; If not yet done, do another byte

; The response byte should be $01 (idle) from CMD0
	CALL	SD_CMD0
	CP	$01
	JR	NZ, SD_BERROR

BOOT_SD_1:
	LD	DE, SD_SCRATCH	; Temporary buffer
	CALL	SD_CMD8		; CMD8 verify v2+ SD card and agree on voltage
				; CMD8 also expands functionality of CMD58 & ACMD41
		
; The response should be: $01 $00 $00 $01 $AA
	LD	A, (SD_SCRATCH)
	CP	1
	JR	NZ, SD_BERROR

BOOT_SD_2:
AC41_MAX_RETRY: =	$80	; Limit the number of ACMD41 retries

	LD	B,AC41_MAX_RETRY

AC41_LOOP:
	PUSH	BC		; Save BC since B contains the retry count
	LD	DE, SD_SCRATCH	; Store command response
	CALL	SD_ACMD41	; Ask if the card is ready
	POP	BC		; Restore our retry counter
	OR	A		; Check to see if A is zero
	JR	Z,AC41_DONE	; If A is zero, then the card is ready

; Card is not ready, waste some time before trying again
	LD	HL,$1000	; Count to $1000 to consume time

AC41_DLY:
	DEC	HL		; HL = HL-1
	LD	A,H		; Does HL == 0?
	OR	L
	JR	NZ,AC41_DLY	; If HL != 0 then keep counting

	DJNZ	AC41_LOOP	; If (--retries != 0) then try again

;AC41_FAIL:
	JR	SD_BERROR

AC41_DONE:

	LD	DE, SD_SCRATCH
	CALL	SD_CMD9

	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	HL, SD_SCRATCH	; Temporary buffer
	LD	DE, SD_SCRATCH+31
	CALL	DMPLINE
	POP	HL
	POP	DE
	POP	BC

	LD	DE, SD_SCRATCH
	CALL	SD_CMD10

	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	HL, SD_SCRATCH	; Temporary buffer
	LD	DE, SD_SCRATCH+31
	CALL	DMPLINE
	POP	HL
	POP	DE
	POP	BC

; Find out the card capacity (HC or XC)
; This status is not valid until after ACMD41
	LD	DE, SD_SCRATCH
	CALL	SD_CMD58

; Check that CCS == 1 here to indicate that we have an HC/XC card
;	LD	(SD_TYPE), A
	LD	A,(SD_SCRATCH+1)
	AND	$40		; CCS bit is here (See spec p275)
	LD	A, 2
	JR	NZ, SD_		; Good to go
; SDSC Card
	LD	A, 1
SD_:
	LD	(SD_TYPE), A
	POP	HL
	POP	DE
	POP	BC
	RET

SD_BERROR:
	XOR	A
	JR	SD_

;**************************************************************************
;
; An SD card library suitable for talking to SD cards in SPI mode 0
;
; WARNING: SD cards are 3.3v ONLY!
; Must provide a pull up on MISO to 3.3V
; SD cards operate on SPI mode 0
;
; References:
; - SD Simplified Specifications, Physical Layer Simplified Specification,
;	Version 8.00:	https://www.sdcard.org/downloads/pls/
;
; The details on operating an SD card in SPI mode can be found in
; Section 7 of the SD specification, p242-264
;
; To initialize an SDHC/SDXC card:
; - send at least 74 CLKs
; - send CMD0 & expect reply message = $01 (enter SPI mode)
; - send CMD8 (establish that the host uses Version 2.0 SD SPI protocol)
; - send ACMD41 (finish bringing the SD card on line)
; - send CMD58 to verify the card is SDHC/SDXC mode (512-byte block size)
;
; At this point the card is on line and ready to read and write
; memory blocks
;
; - use CMD17 to read one 512-byte block
; - use CMD24 to write one 512-byte block
;
;**************************************************************************

;--------------------------------------------------------------------------
; NOTE: Response message formats in SPI mode are different than in SD mode
;
; Read bytes until we find one with MSB = 0 or bail out retrying
; Return last read byte in A (and a copy also in E)
; Calls SPI_READ8
; Destroys: A, B, DE
;--------------------------------------------------------------------------
SD_READ_R1:
	LD	B, $F0		; B = number of retries

SD_R1_LOOP:
	CALL	SPI_READ8	; Read a byte into A (and a copy in E as well)
	AND	BIT7		; Is the MSB set to 1?
	JR	Z, SD_R1_DONE	; If MSB == 0 then we are done
	DJNZ	SD_R1_LOOP	; Else try again until the retry count runs out

SD_R1_DONE:
	LD	A,E		; Copy the final value into A
	RET

;--------------------------------------------------------------------------
; NOTE: Response message formats in SPI mode are different than in SD mode
;
; Read an R7 message into the 5-byte buffer pointed to by HL
; Destroys: A, B, DE, HL
;--------------------------------------------------------------------------
SD_READ_R2:
	CALL	SD_READ_R1		; A = byte #1
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #2
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #3
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #4
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #5
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #6
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #7
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #8
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #9
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #10
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #11
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #12
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #13
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #14
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #15
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #16
	LD	(HL), A			; Save it
	RET

;--------------------------------------------------------------------------
; NOTE: Response message formats in SPI mode are different than in SD mode
;
; Read an R7 message into the 5-byte buffer pointed to by HL
; Destroys: A, B, DE, HL
;--------------------------------------------------------------------------
SD_READ_R7:
	CALL	SD_READ_R1		; A = byte #1
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #2
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #3
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #4
	LD	(HL), A			; Save it
	INC	HL			; Advance receive buffer pointer
	CALL	SPI_READ8		; A = byte #5
	LD	(HL), A			; Save it
	RET

;--------------------------------------------------------------------------
; Send a command and read an R1 response message
; HL = command buffer address
; B = command byte length
; Returns A = reply message byte
; Destroys: A, BC, DE, HL
;
; Modus operandi
; SSEL = LO (assert)
; Send CMD
; Send arg 0
; Send arg 1
; Send arg 2
; Send arg 3
; Send CRC 
; Wait for reply (MSB = 0)
; Read reply
; SSEL = HI
;--------------------------------------------------------------------------
SD_CMD_R1:
; Assert the SSEL line
	CALL	SPI_SSEL_TRUE

; Write a sequence of bytes representing the CMD message
	CALL	SPI_WRITE_STR	; Write B bytes from HL buffer address

; Read the R1 response message
	CALL	SD_READ_R1	; A = E = message response byte

; De-assert the SSEL line
	CALL	SPI_SSEL_FALSE

	LD	A,E
	RET

;--------------------------------------------------------------------------
; Send a command and read an R2 response message
; HL = command buffer address
; B = command byte length
; DE = 16-byte response buffer address
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD_R2:
	CALL	SPI_SSEL_TRUE

	PUSH	DE		; Save the response buffer address
	CALL	SPI_WRITE_STR	; Write cmd buffer from HL, length = B

; Read the response message into buffer address in HL
	POP	HL		; Pop the response buffer address HL
	CALL	SD_READ_R2

; De-assert the SSEL line
	CALL	SPI_SSEL_FALSE
	RET

;--------------------------------------------------------------------------
; Send a command and read an R7 response message
; Note that an R3 response is the same size, so can use the same code
; HL = command buffer address
; B = command byte length
; DE = 5-byte response buffer address
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD_R3:
SD_CMD_R7:
	CALL	SPI_SSEL_TRUE

	PUSH	DE		; Save the response buffer address
	CALL	SPI_WRITE_STR	; Write cmd buffer from HL, length = B

; Read the response message into buffer address in HL
	POP	HL		; Pop the response buffer address HL
	CALL	SD_READ_R7

; De-assert the SSEL line
	CALL	SPI_SSEL_FALSE
	RET

;--------------------------------------------------------------------------
; Send a CMD0 (GO_IDLE) message and read an R1 response
;
; CMD0 will
; 1) Establish the card protocol as SPI (if has just powered up)
; 2) Tell the card the voltage at which we are running it
; 3) Enter the IDLE state
;
; Return the response byte in A
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD0:
	LD	HL, SD_CMD0_BUF	; HL = command buffer
	LD	B, SD_CMD0_LEN	; B = command buffer length
	CALL	SD_CMD_R1	; Send CMD0, A = response byte
	RET

SD_CMD0_BUF:	.DB	0|$40,0,0,0,0,$94|$01
SD_CMD0_LEN	=	$-SD_CMD0_BUF

;--------------------------------------------------------------------------
; Send a CMD8 (SEND_IF_COND) message and read an R7 response
;
; Establish that we are squawking V2.0 of spec & tell the SD
; card the operating voltage is 3.3V.  The reply to CMD8 should
; be to confirm that 3.3V is OK and must echo the $AA back as
; an extra confirm that the command has been processed properly
; The $01 in the byte before the $AA in the command buffer
; below is the flag for 2.7-3.6V operation
;
; Establishing V2.0 of the SD spec enables the HCS bit in
; ACMD41 and CCS bit in CMD58
;
; Return the 5-byte response in the buffer pointed to by DE
; The response should be: $01 $00 $00 $01 $AA
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD8:
	LD	HL, SD_CMD8_BUF
	LD	B, SD_CMD8_LEN
	CALL	SD_CMD_R7
	RET

SD_CMD8_BUF:	.DB	8|$40,0,0,$01,$AA,$86|$01
SD_CMD8_LEN	=	$-SD_CMD8_BUF

;--------------------------------------------------------------------------
; Send a CMD9 (SEND_IF_COND) message and read an R7 response
;
; Return the 5-byte response in the buffer pointed to by DE
; The response should be: $01 $00 $00 $01 $AA
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD9:
	LD	HL, SD_CMD9_BUF
	LD	B, SD_CMD9_LEN
	CALL	SD_CMD_R2
	RET

SD_CMD9_BUF:	.DB	9|$40,0,0,0,0,$00|$01
SD_CMD9_LEN	=	$-SD_CMD9_BUF

;--------------------------------------------------------------------------
; Send a CMD10 (SEND_IF_COND) message and read an R7 response
;
; Return the 5-byte response in the buffer pointed to by DE
; The response should be: $01 $00 $00 $01 $AA
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD10:
	LD	HL, SD_CMD10_BUF
	LD	B, SD_CMD10_LEN
	CALL	SD_CMD_R2
	RET

SD_CMD10_BUF:	.DB	10|$40,0,0,0,0,$00|$01
SD_CMD10_LEN	=	$-SD_CMD10_BUF

;--------------------------------------------------------------------------
; Send a CMD58 message and read an R3 response
; CMD58 is used to ask the card what voltages it supports and
; if it is an SDHC/SDXC card or not
; Return the 5-byte response in the buffer pointed to by DE
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD58:
	LD	HL, SD_CMD58_BUF
	LD	B, SD_CMD58_LEN
	CALL	SD_CMD_R3
	RET

SD_CMD58_BUF:	.DB	58|$40,0,0,0,0,$00|$01
SD_CMD58_LEN	=	$-SD_CMD58_BUF

;--------------------------------------------------------------------------
; Send a CMD55 (APP_CMD) message and read an R1 response
; CMD55 is used to notify the card that the following message is an ACMD
; (as opposed to a regular CMD.)
; Return the 1-byte response in A
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SD_CMD55:
	LD	HL, SD_CMD55_BUF	; HL = buffer to write
	LD	B, SD_CMD55_LEN	; B = buffer byte count
	CALL	SD_CMD_R1	; Write buffer, A = R1 response byte
	RET

SD_CMD55_BUF:	.DB	55|$40,0,0,0,0,$00|$01
SD_CMD55_LEN	=	$-SD_CMD55_BUF

;--------------------------------------------------------------------------
; Send a ACMD41 (SD_SEND_OP_COND) message and return an R1 response byte in A
;
; The main purpose of ACMD41 to set the SD card state to READY so
; that data blocks may be read and written.  It can fail if the card
; is not happy with the operating voltage
;
; Destroys: A, BC, DE, HL
; Note that A-commands are prefixed with a CMD55
;--------------------------------------------------------------------------
SD_ACMD41:
	CALL	SD_CMD55	; Send the A-command prefix

	LD	HL, SD_ACMD41_BUF; HL = command buffer
	LD	B, SD_ACMD41_LEN; B = buffer byte count
	CALL	SD_CMD_R1
	RET

; SD spec p263 Fig 7.1 footnote 1 says we want to set the HCS bit here for HC/XC cards
; Notes on Internet about setting the supply voltage in ACMD41. But not in SPI mode?
; The following works on my MicroCenter SDHC cards:

SD_ACMD41_BUF:	.DB	41|$40,$40,0,0,0,$00|$01	; Note the HCS flag is set here
SD_ACMD41_LEN	=	$-SD_ACMD41_BUF

;--------------------------------------------------------------------------
;
;--------------------------------------------------------------------------
LBATOSD:
	LD	A, (SD_TYPE)
	CP	2
	JR	Z, SDHC_0
	
;	PUSH	DE

	LD	A, (IX+0)
	RLA
	RL	(IX+1)
	RL	(IX+2)
	LD	D, (IX+2)
	LD	(IX+3), D
	LD	D, (IX+1)
	LD	(IX+2), D
	AND	0FEh
	LD	(IX+1), A
	XOR	A
	LD	(IX+0), A

;	POP	DE
SDHC_0:
	RET

;--------------------------------------------------------------------------
; CMD17 (READ_SINGLE_BLOCK)
;
; Read one block given by the 32-bit (little endian) number at
; the top of the stack into the buffer given by address in DE
;
; - Set SSEL = true
; - Send command
; - Read for CMD ACK
; - Wait for 'data token'
; - Read data block
; - Read data CRC
; - Set SSEL = false
;
; A = 0 if the read operation was successful. Else A = 1
; Destroys: A, IX
;--------------------------------------------------------------------------
SD_CMD17:
				; +10 = &block_number
				; +8 = return address
	PUSH	BC		; +6
	PUSH	HL		; +4
	PUSH	IY		; +2
	PUSH	DE		; +0 target buffer address

	LD	IY,SD_SCRATCH	; IY = buffer to format command
	LD	IX,10		; 10 is the offset from SP to the location of the block number
	ADD	IX,SP		; IX = address of uint32_t sd_lba_block number

	CALL	LBATOSD

	LD	(IY+0),17|$40	; The command byte
	LD	A,(IX+3)	; Stack = little endian
	LD	(IY+1),A	; cmd_buffer = big endian
	LD	A,(IX+2)
	LD	(IY+2),A
	LD	A,(IX+1)
	LD	(IY+3),A
	LD	A,(IX+0)
	LD	(IY+4),A
	LD	(IY+5),$00|$01	; The CRC byte

; Assert the SSEL line
	CALL	SPI_SSEL_TRUE

; Send the command 
	PUSH	IY
	POP	HL		; HL = IY = cmd_buffer address
	LD	B,6		; B = command buffer length
	CALL	SPI_WRITE_STR	; Destroys A, BC, D, HL

; Read the R1 response message
	CALL	SD_READ_R1	; Destroys A, B, DE

; If R1 status != SD_READY ($00) then error (SD spec p265, Section 7.2.3)
	OR	A				; If (A == $00) then is OK
	JR	Z,SD_CMD17_R1OK

	JR	SD_CMD17_ERR

SD_CMD17_R1OK:
; Read and toss bytes while waiting for the data token
	LD	BC,$1000		; Expect to wait a while for a reply ~ 14.5msec @ 10Mhz

SD_CMD17_LOOP:
	CALL	SPI_READ8		; Destroys A, DE
	CP	$FF			; If (A == $FF) then command is not yet completed
	JR	NZ,SD_CMD17_TOKEN
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,SD_CMD17_LOOP

	JR	SD_CMD17_ERR	; No flag ever arrived

SD_CMD17_TOKEN:
	CP	$FE			; A == data block token? (else is junk from the SD)
	JR	Z,SD_CMD17_TOKOK

	JR	SD_CMD17_ERR

SD_CMD17_TOKOK:
	POP	HL				; HL = target buffer address
	PUSH	HL				; And keep the stack level the same
	LD	BC,$200		; 512 bytes to read

SD_CMD17_BLK:
	CALL	SPI_READ8		; Destroys A, DE
	LD	(HL),A
	INC	HL				; Increment the buffer pointer
	DEC	BC				; Decrement the byte counter

	LD	A,B				; Did BC reach zero?
	OR	C
	JR	NZ,SD_CMD17_BLK	; If not, go back & read another byte

	CALL	SPI_READ8		; Read the CRC value (XXX should check this)
	CALL	SPI_READ8		; Read the CRC value (XXX should check this)

	CALL	SPI_SSEL_FALSE
	XOR	A				; A = 0 = success!

SD_CMD17_DONE:
	POP	DE
	POP	IY
	POP	HL
	POP	BC
	RET     

SD_CMD17_ERR:
	CALL	SPI_SSEL_FALSE

	LD	A,$01			; Return an error flag
	JR	SD_CMD17_DONE

;--------------------------------------------------------------------------
; CMD24 (WRITE_SINGLE_BLOCK)
;
; Write one block given by the 32-bit (little endian) number at
; the top of the stack from the buffer given by address in DE
;
; - Set SSEL = true
; - Send command
; - Read for CMD ACK
; - Send 'data token'
; - Write data block
; - Wait while busy
; - Read 'data response token' (must be 0bxxx00101 else errors) (see SD spec: 7.3.3.1, p281)
; - Set SSEL = false
;
; - Set SSEL = true
; - Wait while busy		Wait for the write operation to complete
; - Set SSEL = false
;
; XXX This /should/ check to see if the block address was valid
; and that there was no write protect error by sending a CMD13
; after the long busy wait has completed.
;
; A = 0 if the write operation was successful. Else A = 1
; Destroys: A, IX
;--------------------------------------------------------------------------
SD_CMD24:
							; +10 = &block_number
							; +8 = return address
	PUSH	BC				; +6
	PUSH	DE				; +4 target buffer address
	PUSH	HL				; +2
	PUSH	IY				; +0

	LD	IY,SD_SCRATCH	; IY = buffer to format command
	LD	IX,10			; 10 is the offset from SP to the location of the block number
	ADD	IX,SP			; IX = address of uint32_t sd_lba_block number

	CALL	LBATOSD

SD_CMD24_LEN =	6

	LD	(IY+0),24|$40	; The command byte
	LD	A,(IX+3)		; Stack = little endian
	LD	(IY+1),A		; cmd_buffer = big endian
	LD	A,(IX+2)
	LD	(IY+2),A
	LD	A,(IX+1)
	LD	(IY+3),A
	LD	A,(IX+0)
	LD	(IY+4),A
	LD	(IY+5),$00|$01	; The CRC byte

; Assert the SSEL line
	CALL	SPI_SSEL_TRUE

; Send the command 
	PUSH	IY
	POP	HL				; HL = IY = &cmd_buffer
	LD	B,SD_CMD24_LEN
	CALL	SPI_WRITE_STR	; Destroys A, BC, D, HL

; Read the R1 response message
	CALL	SD_READ_R1		; Destroys A, B, DE

; If R1 status != SD_READY ($00) then error
	OR	A				; If (A == $00)
	JR	Z,SD_CMD24_R1OK	; Then OK
							; Else error...
	JR	SD_CMD24_ERR

SD_CMD24_R1OK:
; Give the SD card an extra 8 clocks before we send the start token
	CALL	SPI_READ8

; Send the start token: $FE
	LD	C,$FE
	CALL	SPI_WRITE8		; Destroys A, DE

; Send 512 bytes
	LD	L,(IX-6)		; HL = source buffer address
	LD	H,(IX-5)
	LD	BC,$200		; BC = 512 bytes to write

SD_CMD24_BLK:
	PUSH	BC				; XXX speed this up
	LD	C,(HL)
	CALL	SPI_WRITE8		; Destroys A, DE
	INC	HL
	POP	BC				; XXX speed this up
	DEC	BC
	LD	A,B
	OR	C
	JR	NZ,SD_CMD24_BLK

; Read for up to 250msec waiting on a completion status
	LD	BC,$AB00			; Wait a potentially /long/ time for the write to complete

; [n] = number of T states, 57 T states @ 10Mhz = 5.7us. 250msec ~ $AB00 loop cycles
SD_CMD24_WDR:					; Wait for data response message
	CALL	SPI_READ8			; [17] Destroys A, DE
	CP	$FF				; [7]
	JR	NZ,SD_CMD24_DRC	; [7F/12T]
	DEC	BC					; [6]
	LD	A,B					; [4]
	OR	C					; [4]
	JR	NZ,SD_CMD24_WDR	; [7F/12T]

	JR	SD_CMD24_ERR		; Timed out

SD_CMD24_DRC:
; Make sure the response is 0bxxx00101 else is an error
	AND	$1F
	CP	$05
	JR	Z,SD_CMD24_OK

	JR	SD_CMD24_ERR

SD_CMD24_OK:
	CALL	SPI_SSEL_FALSE

; Wait until the card reports that it is not busy
	CALL	SPI_SSEL_TRUE

SD_CMD24_BUSY:
	CALL	SPI_READ8		; Destroys A, DE
	CP	$FF
	JR	NZ,SD_CMD24_BUSY

	CALL	SPI_SSEL_FALSE

	XOR	A				; A = 0 = success!

SD_CMD24_DONE:
	POP	IY
	POP	HL
	POP	DE
	POP	BC
	RET

SD_CMD24_ERR:
	CALL	SPI_SSEL_FALSE

	LD	A,$01			; Return an error flag
	JR	SD_CMD24_DONE

;**************************************************************************
;
;					S P I  P O R T  S U B R O U T I N E S
;
;**************************************************************************

;**************************************************************************
; An SPI library suitable for talking to SD cards
;
; This library implements SPI mode 0 (SD cards operate on SPI mode 0.)
; Data changes on falling CLK edge & sampled on rising CLK edge:
;        __                                             ___
; /SSEL    \______________________ ... ________________/      Host --> Device
;                 __    __    __   ... _    __    __
; CLK    ________/  \__/  \__/  \__     \__/  \__/  \______   Host --> Device
;        _____ _____ _____ _____ _     _ _____ _____ ______
; MOSI        \_____X_____X_____X_ ... _X_____X_____/         Host --> Device
;        _____ _____ _____ _____ _     _ _____ _____ ______
; MISO        \_____X_____X_____X_ ... _X_____X_____/         Host <-- Device
;
;**************************************************************************

;--------------------------------------------------------------------------
; Write 8 bits in C to the SPI port and discard the received data
; It is assumed that the GPIO_OUT_CACHE value matches the current state
; of the GP output port and that SSEL is low
; This will leave: CLK = 1, MOSI = (the LSB of the byte written)
; Destroys: A, DE
;--------------------------------------------------------------------------
SPI_WRITE8:
	LD	A, (GPIO_OUT_CACHE)	; Get current GPIO_OUT value
	AND	0+~(GPIO_OUT_SD_MOSI|GPIO_OUT_SD_CLK)	; MOSI & CLK = 0
	LD	D,A			; Save in D for reuse

	PUSH	BC			; Setup to run .SPI_WRITE1 8 times
	LD	B,8   
	LD	E,BIT7			; Bit mask

; Send the 8 bits ([n] = number of T states used)
SPI_WRITE1:
	LD	A,E			; [9] Get current bit mask
	AND	C			; [4] Check if bit in C is a 1
	LD	A,D			; [9] A = GPIO_OUT value w/CLK & MOSI = 0
	JR	Z,LO_BIT		; [7F/12T] Send a 0
	OR	GPIO_OUT_SD_MOSI	; [7] prepare to transmit a 1

LO_BIT:
	OUT	(GPIO_OUT),A		; [11] Set data value & CLK falling edge
	OR	GPIO_OUT_SD_CLK		; [7] Ready the CLK to send a 1
	OUT	(GPIO_OUT),A		; [11] Set the CLK's rising edge

	SRL	E			; [8] Adjust bit mask
	DJNZ	SPI_WRITE1		; [8 B=0/13] Continue until all 8 bits are sent

	POP	BC
	RET

;--------------------------------------------------------------------------
; Read 8 bits from the SPI & return it in A
; MOSI will be set to 1 during all bit transfers
; This will leave: CLK = 1, MOSI = 1
; Returns the byte read in A (and a copy of it also in E)
; Destroys: A, DE
;--------------------------------------------------------------------------
SPI_READ8:
	LD	E, 0			; Prepare to accumulate the bits into E

	LD	A, (GPIO_OUT_CACHE)	; Get current GPIO_OUT value
	AND	~GPIO_OUT_SD_CLK	; CLK = 0
	OR	GPIO_OUT_SD_MOSI	; MOSI = 1
	LD	D, A			; Save in D for reuse

	PUSH	BC			; Setup to run .SPI_READ1 8 times
	LD	B, 8

; Read the 8 bits
SPI_READ1:
	LD	A, D
	OUT	(GPIO_OUT), A		; Set data value & CLK falling edge
	OR	GPIO_OUT_SD_CLK		; Set the CLK bit
	OUT	(GPIO_OUT), A		; CLK rising edge

	IN	A, (GPIO_IN)		; Read MISO
	AND	GPIO_IN_SD_MISO		; Strip all but the MISO bit
	OR	E			; Accumulate the current MISO value
	RLCA				; The LSB is read last, rotate into proper place
					; NOTE: this only works because GPIO_IN_SD_MISO = $80
	LD	E, A			; Save a copy of the running value in A and E

	DJNZ	SPI_READ1		; Continue until all 8 bits are read

; The final value will be in both the E and A registers
	POP	BC
	RET

;--------------------------------------------------------------------------
; Assert the select line (set it low)
; This will leave: SSEL = 0, CLK = 0, MOSI = 1
; Destroys: A
;--------------------------------------------------------------------------
SPI_SSEL_TRUE:
	PUSH	DE			; Save DE because READ8 alters it

; Read and discard a byte to generate 8 clk cycles
	CALL	SPI_READ8

	LD	A, (GPIO_OUT_CACHE)

; Make sure the clock is low before we enable the card
	AND	~GPIO_OUT_SD_CLK	; CLK = 0
	OR	GPIO_OUT_SD_MOSI	; MOSI = 1
	OUT	(GPIO_OUT), A

; Enable the card
	AND	~GPIO_OUT_SD_SSEL	; SSEL = 0
	LD	(GPIO_OUT_CACHE), A	; Save current state in the cache
	OUT	(GPIO_OUT), A

; Generate another 8 clk cycles
	CALL	SPI_READ8

	POP	DE
	RET

;--------------------------------------------------------------------------
; De-assert the select line (set it high)
; This will leave: SSEL = 1, CLK = 0, MOSI = 1
; Destroys: A
;
; See section 4 of 
;	Physical Layer Simplified Specification Version 8.00
;--------------------------------------------------------------------------
SPI_SSEL_FALSE:
	PUSH	DE			; Save DE because READ8 alters it

; Read and discard a byte to generate 8 clk cycles
	CALL	SPI_READ8

	LD	A, (GPIO_OUT_CACHE)

; Make sure the clock is low before we disable the card
	AND	~GPIO_OUT_SD_CLK	; CLK = 0
	OUT	(GPIO_OUT), A

	OR	GPIO_OUT_SD_SSEL|GPIO_OUT_SD_MOSI	; SSEL = 1, MOSI = 1
	LD	(GPIO_OUT_CACHE), A
	OUT	(GPIO_OUT), A

; Generate another 16 clk cycles
	CALL	SPI_READ8
	CALL	SPI_READ8

	POP	DE
	RET

;--------------------------------------------------------------------------
; HL = address of bytes to write
; B = byte count
; Destroys: A, BC, DE, HL
;--------------------------------------------------------------------------
SPI_WRITE_STR:
	LD	C, (HL)		; Get next byte to send
	CALL	SPI_WRITE8	; Send it
	INC	HL		; Point to the next byte
	DJNZ	SPI_WRITE_STR	; Count the byte & continue if not done
	RET
