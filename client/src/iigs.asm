*---------------------------------------------------------
* INITGS - Do all the IIgs setup stuff
*---------------------------------------------------------
INITGS
	sei		TURN OFF INTERRUPTS
	jsr INITSCC
	jsr PATCHGS
	rts

*---------------------------------------------------------
* PUTCGS - Send accumulator out the SCC serial port
*---------------------------------------------------------
PUTCGS
	STA	:TEMPA
	STX	:TEMPX

:SEND	LDA	GSCMDB	;rr0

	TAX
	AND	#%00000100	;test bit 2 (hardware handshaking)
	BEQ	:SEND
	TXA
	AND	#%00100000	;test bit 5 (ready to send?)
	BEQ	:SEND

:EXIT0	LDA	:TEMPA	;get char to send
	STA	GSDATAB	;send the character

:EXIT	LDX	:TEMPX
	LDA	:TEMPA
	RTS

:TEMPA	.db	1
:TEMPX	.db	1


*---------------------------------------------------------
* GETCGS - Get a character from the SCC serial port (XY unchanged)
*---------------------------------------------------------

GETCGS
	LDA GSCMDB	; DUMMY READ TO RESET 8530 POINTER TO 0

pollSCC
	lda $C000
	cmp #CHR_ESC	Escape = abort
	bne SCCNEXT
	jmp PABORT

SCCNEXT	LDA GSCMDB	; READ 8530 READ REGISTER 0
	AND #$01        ; BIT 0 MEANS RX CHAR AVAILABLE
	cmp #$01
	bne pollSCC

			;  THERE'S A CHAR IN THE 8530 RX BUFFER
pullIt
	LDA #$01	;  SET 'POINTER' TO rr1
	STA GSCMDB  
	LDA GSCMDB	;  READ THE 8530 READ REGISTER 1
	AND #$20	;  CHECK FOR bit 5=RX OVERRUN
	BEQ itsOK
	ldx #$30	; Clear Receive overrun
	stx GSCMDB
	ldx #$00
	stx GSCMDB

itsOK
	LDA #$08	;  WE WANT TO READ rr8
	STA GSCMDB	;  SET 'POINTER' TO rr8
	LDA GSCMDB	;  READ rr8
	rts

*---------------------------------------------------------
* INITSCC - initialize the Modem Port
* (Channel B is modem port, A is printer port)
*---------------------------------------------------------

INITSCC
	SEI
	clc
	lda #$05
	adc PSPEED	0 = 9600, 1=19200, 2=115200
	sta BAUD

	LDA	GSCMDB	;hit rr0 once to sync up

	LDX	#9	;wr9
	LDA	#RESETB	;load constant to reset Ch B
			;for Ch A, use RESETCHA
	STX	GSCMDB
	STA	GSCMDB
	NOP		;SCC needs 11 pclck to recover

	LDX	#3	;wr3
	LDA	#%11000000	;8 data bits, receiver disabled
	STX	GSCMDB	;could be 7 or 6 or 5 data bits
	STA	GSCMDB	;for 8 bits, bits 7,6 = 1,1

	LDX	#5	;wr5
	LDA	#%01100010	;DTR enabled 0=/HIGH, 8 data bits
	STX	GSCMDB	;no BRK, xmit disabled, no SDLC
	STA	GSCMDB	;RTS *MUST* be disabled, no crc

	LDX	#14	;wr14
	LDA	#%00000000	;null cmd, no loopback
	STX	GSCMDB	;no echo, /DTR follows wr5
	STA	GSCMDB	;BRG source is XTAL or RTxC

	lda PSPEED
	cmp #$02
	beq GOFAST

	LDX	#4	;wr4
	LDA	#%01000100	;X16 clock mode,
	STX	GSCMDB	;1 stop bit, no parity
	STA	GSCMDB	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1

	LDX	#11	;wr11
	LDA	#WR11BBRG	;load constant to write
	STX	GSCMDB
	STA	GSCMDB

	JSR	TIMECON	;set up wr12 and wr13
			;to set baud rate.

* Enables
	ORA	#%00000001	;enable baud rate gen
	LDX	#14	;wr14
	STX	GSCMDB
	STA	GSCMDB	;write value
	jmp INITCOMMON

GOFAST
	LDX	#4	;wr4
	LDA	#%10000100	;X32 clock mode,
	STX	GSCMDB	;1 stop bit, no parity
	STA	GSCMDB	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1

	LDX	#11	;wr11
	LDA	#WR11BXTAL	;load constant to write
	STX	GSCMDB
	STA	GSCMDB

INITCOMMON
	LDA	#%11000001	;8 data bits, Rx enable
	LDX	#3
	STX	GSCMDB
	STA	GSCMDB	;write value

	LDA	#%01101010	;DTR enabled; Tx enable
	LDX	#5
	STX	GSCMDB
	STA	GSCMDB	;write value

* Enable Interrupts

	LDX	#15	;wr15

* The next line is commented out. This driver wants
* interrupts when GPi changes state, ie. the user
* on the BBS may have hung up. You can write a 0
* to this register if you don't need any external
* status interrupts. Then in the IRQIN routine you
* won't need handling for overruns; they won't be
* latched. See the Zilog Tech Ref. for details.

* LDA #%00100000 ;allow ext. int. on CTS/HSKi

	LDA	#%00000000	;allow ext. int. on DCD/GPi

	STX	GSCMDB
	STA	GSCMDB

	LDX	#0
	LDA	#%00010000	;reset ext. stat. ints.
	STX	GSCMDB
	STA	GSCMDB	;write it twice

	STX	GSCMDB
	STA	GSCMDB

	LDX	#1	;wr1
	LDA	#%00000000	;Wait Request disabled
	STX	GSCMDB	;allow IRQs on Rx all & ext. stat
	STA	GSCMDB	;No transmit interrupts (b1)

	LDA GSCMDB   //READ TO RESET channelB POINTER TO 0
	LDA #$09
	STA GSCMDB //SET 'POINTER' TO wr9
	LDA #$00
	STA GSCMDB //Anti BluRry's syndrome medication 

	CLI
	RTS		;we're done!


* TIMECON: Set time constant bytes in wr12 & wr13
* (In other words, set the baud rate.)

TIMECON	LDY	BAUD
	LDA	#12
	STA	GSCMDB
	LDA	BAUDL-1,Y	;load time constant low
	STA	GSCMDB

	LDA	#13
	STA	GSCMDB
	LDA	BAUDH-1,Y	;load time constant high
	STA	GSCMDB
	RTS

* Table of values for different baud rates. There is
* a low byte and a high byte table.

BAUDL	.db	126	;300 bps (1)
	.db	94	;1200 (2)
	.db	46	;2400 (3)
	.db	22	;4800 (4)
	.db	10	;9600 (5)
	.db	4	;19200 (6)
	.db	1	;38400 (7)
	.db	0	;57600 (8)

BAUDH	.db	1	;300 bps (1)
	.db	0	;1200 (2)
	.db	0	;2400 (3)
	.db	0	;4800 (4)
	.db	0	;9600 (5)
	.db	0	;19200 (6)
	.db	0	;38400 (7)
	.db	0	;57600 (8)

*---------------------------------------------------------
* PATCHGS - Patch the entry point of PUTC and GETC over
*           to the IIgs versions
*---------------------------------------------------------
PATCHGS
	lda PUTC
	sta SVP
	lda PUTC+1
	sta SVP+1
	lda PUTC+2
	sta SVP+2

	lda #$4c
	sta PUTC
	lda #PUTCGS
	sta PUTC+1
	lda /PUTCGS
	sta PUTC+2

	lda GETC
	sta SVG
	lda GETC+1
	sta SVG+1
	lda GETC+2
	sta SVG+2

	lda #$4c
	sta GETC
	lda #GETCGS
	sta GETC+1
	lda /GETCGS
	sta GETC+2

	rts

*---------------------------------------------------------
* PATCHII - Patch the entry point of PUTC and GETC back
*           to the original SSC versions
*---------------------------------------------------------
PATCHII
	lda #$48
	sta PUTC
	lda #$AD
	sta PUTC+1
	lda #$00
	sta PUTC+2

	lda #$AD
	sta GETC
	lda #$00
	sta GETC+1
	lda #$C0
	sta GETC+2

	rts

SVP	.db $00,$00,$00
SVG	.db $00,$00,$00

