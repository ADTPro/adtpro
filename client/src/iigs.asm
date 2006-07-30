*---------------------------------------------------------
* INITGS - Do all the IIgs setup stuff
*---------------------------------------------------------
INITGS
	sei		TURN OFF INTERRUPTS
	jsr SELFMOD
	jsr INITSLOT
	jsr INITSEND	Probably redundant with INITSCC now...
	jsr INITSCC
	jsr PATCHGS
	rts

*---------------------------------------------------------
* SELFMOD - Set up all self-modifying addresses
*---------------------------------------------------------
SELFMOD
	cld

	lda $C02D	IIgs slot ROM enable
	sta SVC02D
	and #$FB	Mask off bit 3: 4 decimal
	sta $C02D
	lda $C20D	PASCAL INIT ENTRY POINT
	sta MODINIT+1	MOD CODE!!
	iny
	lda $C20E	PASCAL READ ENTRY POINT
	sta MODREAD+1	MOD CODE!!
	iny
	lda $C20F	PASCAL WRITE ENTRY POINT
	sta MODWRITE+1	MOD CODE!!
	iny
	lda $C210	PASCAL STATUS ENTRY POINT
	sta MODSTAT1+1	MOD CODE!!
	sta MODSTAT2+1	MOD CODE!!
	iny
	iny
	lda $C212	PASCAL CONTROL ENTRY POINT
	rts

SVC02D	.db $84

*---------------------------------------------------------
* INITSLOT - Initialize the GS slot firmware
*---------------------------------------------------------
INITSLOT
	ldx #$C2	$CN, N=SLOT
	ldy #$20	$N0, N=SLOT
	lda #0
MODINIT
	jsr $C245	PASCAL INIT ENTRY POINT
	rts

*---------------------------------------------------------
* INITSEND - initialization string for serial port
*---------------------------------------------------------
* The IIgs serial port initially accepts control-commands
* in its output stream. This means the port is not
* fully 8-bit transparent. We must first send a
* control sequence to prevent the firmware from
* interpreting any of the binary data.
*
INITSTRING
	.db $01,$d8,$c4	ctrl-A X D disable XON/XOFF
	.db $01,$c3,$c4	ctrl-A C D disable auto CR
	.db $01,$cb	ctrl-A K disable auto LF after CR
	.db $01,$da	ctrl-A Z disable firmware control chars
	.db $00		terminate string
INITSEND
	ldy #0
SILOOP
	lda INITSTRING,Y
	BEQ SIDONE	ZERO terminates
	jsr PUTCGS	preserves Y
	iny
	bne SILOOP
SIDONE
	rts

*---------------------------------------------------------
* GSSPD -- SET SPEED OF GS PORT
* USES SOME 16-BIT CODE
*---------------------------------------------------------
GSSPD
	clc
	.db $FB           ; xce TO NATIVE MODE
	.db $C2,$30       ; rep #$30 16 BIT M,X
	.db $29,$FF,$00   ; and #$00FF
	tax               ; $AA
	lda L0EF8,X
	.db $29,$FF,$00   ; and #$00FF
	pha               ; $48 ; PARM 1 (2BYTE)
	.db $A9,$12,$00   ; lda #$0012
	pha               ; $48 ; PARM 2 (2BYTE)
	.db $A2,$03,$0B   ; ldx #$0B03 FUNC $B IN TOOL $3
	.db $22,$00,$00,$E1 ; jsl $E10000 ; DISPATCH
	sec
	.db $FB           ; xce TO EMULATION
	rts

*---------------------------------------------------------
* PUTCGS - Send accumulator out the SCC serial port
*---------------------------------------------------------
PUTCGS
	.db $DA           ; PHX
	.db $5A           ; PHY
	pha
K8D8
	lda $C000
	cmp #CHR_ESC	Escape = abort
	bne OK8E2
	jmp PABORT
OK8E2
	ldx #$C2          ; $CN, N=SLOT
	ldy #$20          ; $N0
	lda #0            ; READY FOR OUTPUT?
MODSTAT1
	jsr $C248         ; PASCAL STATUS ENTRY POINT
	bcc K8D8          ; CC MEANS NOT READY
	ldx #$C2          ; $CN
	ldy #$20          ; $N0
	pla               ; RETRIEVE CHAR
	pha               ; MUST SAVE FOR RETURN
MODWRITE
	jsr $C247         ; PASCAL WRITE ENTRY POINT
	pla
	.db $7A           ; PLY
	.db $FA           ; PLX
	and #$FF
	rts

*---------------------------------------------------------
* GETCGS - Get a character from the SCC serial port (XY unchanged)
*---------------------------------------------------------
GETCGS
	.db $DA		PHX
	.db $5A		PHY
K902
	lda $C000
	cmp #CHR_ESC	Escape = abort
	bne OK90C
	jmp PABORT
OK90C
	ldx #$C2	$CN, N=SLOT
	ldy #$20	$N0
	lda #1		INPUT READY?
MODSTAT2
	jsr $C248	PASCAL STATUS ENTRY POINT
	bcc K902	CC MEANS NO INPUT READY
	ldx #$C2	$CN
	ldy #$20	$N0
MODREAD
	jsr $C246	PASCAL READ ENTRY POINT
	.db $7A		PLY
	.db $FA		PLX
	and #$FF
	rts

*---------------------------------------------------------
* INITSCC - initialize the Modem Port
* (Channel B is modem port, A is printer port)
*---------------------------------------------------------

INITSCC
	SEI
	clc
	lda #$05
	adc PSPEED	0 = 9600, 1=19200
	cmp #$07
	sta BAUD

	LDA	GSCMDB	;hit rr0 once to sync up

	LDX	#9	;wr9
	LDA	#RESETB	;load constant to reset Ch B
			;for Ch A, use RESETCHA
	STX	GSCMDB
	STA	GSCMDB
	NOP		;SCC needs 11 pclck to recover

	LDX	#4	;wr4
	LDA	#%01000100	;X16 clock mode,
	STX	GSCMDB	;1 stop bit, no parity
	STA	GSCMDB	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1
	LDX	#3	;wr3
	LDA	#%11000000	;8 data bits, receiver disabled
	STX	GSCMDB	;could be 7 or 6 or 5 data bits
	STA	GSCMDB	;for 8 bits, bits 7,6 = 1,1

	LDX	#5	;wr5
	LDA	#%01100010	;DTR enabled 0=/HIGH, 8 data bits
	STX	GSCMDB	;no BRK, xmit disabled, no SDLC
	STA	GSCMDB	;RTS *MUST* be disabled, no crc
	LDX	#11	;wr11
	LDA	#WR11B	;load constant to write
			;use #WR11A for channel A
	STX	GSCMDB
	STA	GSCMDB
	JSR	TIMECON	;set up wr12 and wr13
			;to set baud rate.
	LDX	#14	;wr14
	LDA	#%00000000	;null cmd, no loopback
	STX	GSCMDB	;no echo, /DTR follows wr5
	STA	GSCMDB	;BRG source is XTAL or RTxC

* Enables

	ORA	#%00000001	;enable baud rate gen
	LDX	#14	;wr14
	STX	GSCMDB
	STA	GSCMDB	;write value

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

*	LDX	#9	;re-write wr9
*	LDA	#%00011001	;set Master Interrupt Enable
*	STX	GSCMDB	;this value gives us vector
*	STA	GSCMDB	;information with each irq,
			;in vector bits 6-5-4,
			;also including status.

* The vector bits are not used by firmware and IIGS
* TechNote #18. But they make irq handling easier.

			;(See IRQIN routine.)

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

* DOBAUD: Set baud rate without resetting entire 8530
* (Stop clock, set time constant, restart clock)

DOBAUD	SEI
	LDA	#0	;disable BRG (stop clock)
	LDX	#14	;wr14
	STX	GSCMDB
	STA	GSCMDB	;write it

	JSR	TIMECON	;set time constant bytes

	LDA	#%00000001	;re-enable BRG
	LDX	#14
	STX	GSCMDB
	STA	GSCMDB

	CLI
	RTS

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

