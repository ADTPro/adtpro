;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2008 by David Schmidt
; david__schmidt at users.sourceforge.net
;
; This program is free software; you can redistribute it and/or modify it 
; under the terms of the GNU General Public License as published by the 
; Free Software Foundation; either version 2 of the License, or (at your 
; option) any later version.
;
; This program is distributed in the hope that it will be useful, but 
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
; for more details.
;
; You should have received a copy of the GNU General Public License along 
; with this program; if not, write to the Free Software Foundation, Inc., 
; 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
;

;---------------------------------------------------------
; INITZGS - Set up IIgs SCC chip (kills firmware and GSOS)
;---------------------------------------------------------
INITZGS:
	sei			; TURN OFF INTERRUPTS
	jsr INITZSCC
	jsr PATCHZGS
	rts

;---------------------------------------------------------
; ZCCP - Send accumulator out the SCC serial port
;---------------------------------------------------------
ZCCP:
	STA TEMPA
	STX TEMPX

ZSEND:	LDA GSCMDB		; rr0

	TAX
	AND #%00000100		; test bit 2 (hardware handshaking)
	BEQ ZSEND
	TXA
	AND #%00100000		; test bit 5 (ready to send?)
	BEQ ZSEND

EXIT0:	LDA TEMPA		; get char to send
	STA GSDATAB		; send the character

EXIT:	LDX TEMPX
	LDA TEMPA
	RTS

TEMPA:	.byte	1
TEMPX:	.byte	1


;---------------------------------------------------------
; ZCCG - Get a character from the SCC serial port (XY unchanged)
;---------------------------------------------------------

ZCCG:
	LDA GSCMDB	; DUMMY READ TO RESET 8530 POINTER TO 0

pollSCC:
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	bne SCCNEXT
	jmp PABORT

SCCNEXT:
	LDA GSCMDB	; READ 8530 READ REGISTER 0
	AND #$01        ; BIT 0 MEANS RX CHAR AVAILABLE
	cmp #$01
	bne pollSCC

			;  THERE'S A CHAR IN THE 8530 RX BUFFER
pullIt:
	LDA #$01	;  SET 'POINTER' TO rr1
	STA GSCMDB  
	LDA GSCMDB	;  READ THE 8530 READ REGISTER 1
	AND #$20	;  CHECK FOR bit 5=RX OVERRUN
	BEQ itsOK
	ldx #$30	; Clear Receive overrun
	stx GSCMDB
	ldx #$00
	stx GSCMDB

itsOK:
	LDA #$08	;  WE WANT TO READ rr8
	STA GSCMDB	;  SET 'POINTER' TO rr8
	LDA GSCMDB	;  READ rr8
	rts

;---------------------------------------------------------
; INITZSCC - initialize the Modem Port
; (Channel B is modem port, A is printer port)
;---------------------------------------------------------

INITZSCC:
	SEI

	LDA GSCMDB	;hit rr0 once to sync up

	LDX #9		;wr9
	LDA #RESETB	;load constant to reset Ch B
			;for Ch A, use RESETCHA
	STX GSCMDB
	STA GSCMDB
	NOP		;SCC needs 11 pclck to recover

	LDX #3		;wr3
	LDA #%11000000	;8 data bits, receiver disabled
	STX GSCMDB	;could be 7 or 6 or 5 data bits
	STA GSCMDB	;for 8 bits, bits 7,6 = 1,1

	LDX #5		;wr5
	LDA %01100010	;DTR enabled 0=/HIGH, 8 data bits
	STX GSCMDB	;no BRK, xmit disabled, no SDLC
	STA GSCMDB	;RTS ;MUST; be disabled, no crc

	LDX #14		;wr14
	LDA #%00000000	;null cmd, no loopback
	STX GSCMDB	;no echo, /DTR follows wr5
	STA GSCMDB	;BRG source is XTAL or RTxC

	lda PSPEED
	cmp #$03	; 115200 baud?
	beq GOFAST	; Yes, go fast

	LDX #4		;wr4
	LDA #%01000100	;X16 clock mode,
	STX GSCMDB	;1 stop bit, no parity
	STA GSCMDB	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1

	LDX #11	;wr11
	LDA #WR11BBRG	;load constant to write
	STX GSCMDB
	STA GSCMDB

	JSR TIMECON	;set up wr12 and wr13
			;to set baud rate.

; Enables
	ORA #%00000001	;enable baud rate gen
	LDX #14		;wr14
	STX GSCMDB
	STA GSCMDB	;write value
	jmp INITCOMMON

GOFAST:
	LDX #4		;wr4
	LDA #%10000100	;X32 clock mode,
	STX GSCMDB	;1 stop bit, no parity
	STA GSCMDB	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1

	LDX #11	;wr11
	LDA #WR11BXTAL	;load constant to write
	STX GSCMDB
	STA GSCMDB

INITCOMMON:
	LDA #%11000001	;8 data bits, Rx enable
	LDX #3
	STX GSCMDB
	STA GSCMDB	;write value

	LDA #%01101010	;DTR enabled; Tx enable
	LDX #5
	STX GSCMDB
	STA GSCMDB	;write value

; Enable Interrupts

	LDX #15		;wr15

; The next line is commented out. This driver wants
; interrupts when GPi changes state, ie. the user
; on the BBS may have hung up. You can write a 0
; to this register if you don't need any external
; status interrupts. Then in the IRQIN routine you
; won't need handling for overruns; they won't be
; latched. See the Zilog Tech Ref. for details.

; LDA #%00100000 ;allow ext. int. on CTS/HSKi

	LDA #%00000000	;allow ext. int. on DCD/GPi

	STX GSCMDB
	STA GSCMDB

	LDX #0
	LDA #%00010000	;reset ext. stat. ints.
	STX GSCMDB
	STA GSCMDB	;write it twice

	STX GSCMDB
	STA GSCMDB

	LDX #1		;wr1
	LDA #%00000000	;Wait Request disabled
	STX GSCMDB	;allow IRQs on Rx all & ext. stat
	STA GSCMDB	;No transmit interrupts (b1)

	LDA GSCMDB	; READ TO RESET channelB POINTER TO 0
	LDA #$09
	STA GSCMDB	; SET 'POINTER' TO wr9
	LDA #$00
	STA GSCMDB	; Anti BluRry's syndrome medication 

	CLI
	RTS		;we're done!


; TIMECON: Set time constant bytes in wr12 & wr13
; (In other words, set the baud rate.)

TIMECON:
	ldy PSPEED
	LDA #12
	STA GSCMDB
	LDA BAUDL,Y	;load time constant low
	STA GSCMDB

	LDA #13
	STA GSCMDB
	LDA BAUDH,Y	;load time constant high
	STA GSCMDB
	RTS

; Table of values for different baud rates. There is
; a low byte and a high byte table.

BAUDL:	.byte	126	;300 bps
	.byte	10	;9600
	.byte	4	;19200

BAUDH:	.byte	1	;300 bps
	.byte	0	;9600
	.byte	0	;19200

; For reference, all the possible values:
;BAUDL:	.byte	126	;300 bps (1)
;	.byte	94	;1200 (2)
;	.byte	46	;2400 (3)
;	.byte	22	;4800 (4)
;	.byte	10	;9600 (5)
;	.byte	4	;19200 (6)
;	.byte	1	;38400 (7)
;	.byte	0	;57600 (8)
;
;BAUDH:	.byte	1	;300 bps (1)
;	.byte	0	;1200 (2)
;	.byte	0	;2400 (3)
;	.byte	0	;4800 (4)
;	.byte	0	;9600 (5)
;	.byte	0	;19200 (6)
;	.byte	0	;38400 (7)
;	.byte	0	;57600 (8)

;---------------------------------------------------------
; RESETZGS - Clean up SCC every time we hit the main loop
;---------------------------------------------------------
RESETZGS:
	LDA GSCMDB	; READ TO RESET channelB POINTER TO 0
	rts

;---------------------------------------------------------
; PATCHZGS - Patch the entry point of PUTC and GETC over
;           to the IIgs versions
;---------------------------------------------------------
PATCHZGS:
	lda #<ZCCP
	sta PUTC+1
	lda #>ZCCP
	sta PUTC+2

	lda #<ZCCG
	sta GETC+1
	lda #>ZCCG
	sta GETC+2

	lda #<RESETZGS
	sta RESETIO+1
	lda #>RESETZGS
	sta RESETIO+2

	rts

;---------------------------------------------------------
; Apple IIgs SCC Z8530 registers and constants
;---------------------------------------------------------

GSCMDB	=	$C038
GSDATAB	=	$C03A

GSCMDA	=	$C039
GSDATAA	=	$C03B

RESETA	=	%11010001	; constant to reset Channel A
RESETB	=	%01010001	; constant to reset Channel B
WR11A	=	%11010000	; init wr11 in Ch A
WR11BXTAL	=	%00000000	; init wr11 in Ch B - use external clock
WR11BBRG	=	%01010000	; init wr11 in Ch B - use baud rate generator
