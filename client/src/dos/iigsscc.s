;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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
initzgs:
	sei			; TURN OFF INTERRUPTS
	jsr initzscc
	jsr patchzgs
	rts

;---------------------------------------------------------
; zccp - Send accumulator out the SCC serial port
;---------------------------------------------------------
zccp:
	STA	tempa
	STX	tempx

zsend:	LDA	gscmdb		; rr0

	TAX
	AND	#%00000100	; test bit 2 (hardware handshaking)
	BEQ	zsend
	TXA
	AND	#%00100000	; test bit 5 (ready to send?)
	BEQ	zsend

exit0:	LDA	tempa		; get char to send
	STA	gsdatab		; send the character

exit:	LDX	tempx
	LDA	tempa
	RTS

tempa:	.byte	1
tempx:	.byte	1


;---------------------------------------------------------
; zccg - Get a character from the SCC serial port (XY unchanged)
;---------------------------------------------------------

zccg:
	LDA gscmdb	; DUMMY READ TO RESET 8530 POINTER TO 0

pollscc:
	lda $C000
	cmp #esc	; escape = abort
	bne sccnext
	jmp pabort

sccnext:
	LDA gscmdb	; READ 8530 READ REGISTER 0
	AND #$01        ; BIT 0 MEANS RX CHAR AVAILABLE
	cmp #$01
	bne pollscc

			;  THERE'S A CHAR IN THE 8530 RX BUFFER
pullIt:
	LDA #$01	;  SET 'POINTER' TO rr1
	STA gscmdb  
	LDA gscmdb	;  READ THE 8530 READ REGISTER 1
	AND #$20	;  CHECK FOR bit 5=RX OVERRUN
	BEQ itsOK
	ldx #$30	; Clear Receive overrun
	stx gscmdb
	ldx #$00
	stx gscmdb

itsOK:
	LDA #$08	;  WE WANT TO READ rr8
	STA gscmdb	;  SET 'POINTER' TO rr8
	LDA gscmdb	;  READ rr8
	rts

;---------------------------------------------------------
; initzscc - initialize the Modem Port
; (Channel B is modem port, A is printer port)
;---------------------------------------------------------

initzscc:
	SEI
	clc
	lda pspeed	; 0 = 300, 1 = 1200, 2 = 2400, 3 = 4800, 4 = 9600, 5=19200, 6=115200
	sta baud
	inc baud

	LDA	gscmdb	;hit rr0 once to sync up

	LDX	#9	;wr9
	LDA	#resetb	;load constant to reset Ch B
			;for Ch A, use RESETCHA
	STX	gscmdb
	STA	gscmdb
	NOP		;SCC needs 11 pclck to recover

	LDX	#3	;wr3
	LDA	#%11000000	;8 data bits, receiver disabled
	STX	gscmdb	;could be 7 or 6 or 5 data bits
	STA	gscmdb	;for 8 bits, bits 7,6 = 1,1

	LDX	#5	;wr5
	LDA	#%01100010	;DTR enabled 0=/HIGH, 8 data bits
	STX	gscmdb	;no BRK, xmit disabled, no SDLC
	STA	gscmdb	;RTS ;MUST; be disabled, no crc

	LDX	#14	;wr14
	LDA	#%00000000	;null cmd, no loopback
	STX	gscmdb	;no echo, /DTR follows wr5
	STA	gscmdb	;BRG source is XTAL or RTxC

	lda pspeed
	cmp #$06
	beq gofast

	LDX	#4	;wr4
	LDA	#%01000100	;X16 clock mode,
	STX	gscmdb	;1 stop bit, no parity
	STA	gscmdb	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1

	LDX	#11	;wr11
	LDA	#wr11bbrg	;load constant to write
	STX	gscmdb
	STA	gscmdb

	JSR	TIMECON	;set up wr12 and wr13
			;to set baud rate.

; Enables
	ORA	#%00000001	;enable baud rate gen
	LDX	#14	;wr14
	STX	gscmdb
	STA	gscmdb	;write value
	jmp initcommon

gofast:
	LDX	#4	;wr4
	LDA	#%10000100	;X32 clock mode,
	STX	gscmdb	;1 stop bit, no parity
	STA	gscmdb	;could be 1.5 or 2 stop bits
			;1.5 set bits 3,2 to 1,0
			;2   set bits 3,2 to 1,1

	LDX	#11	;wr11
	LDA	#wr11bxtal	;load constant to write
	STX	gscmdb
	STA	gscmdb

initcommon:
	LDA	#%11000001	;8 data bits, Rx enable
	LDX	#3
	STX	gscmdb
	STA	gscmdb	;write value

	LDA	#%01101010	;DTR enabled; Tx enable
	LDX	#5
	STX	gscmdb
	STA	gscmdb	;write value

; Enable Interrupts

	LDX	#15	;wr15

; The next line is commented out. This driver wants
; interrupts when GPi changes state, ie. the user
; on the BBS may have hung up. You can write a 0
; to this register if you don't need any external
; status interrupts. Then in the IRQIN routine you
; won't need handling for overruns; they won't be
; latched. See the Zilog Tech Ref. for details.

; LDA #%00100000 ;allow ext. int. on CTS/HSKi

	LDA	#%00000000	;allow ext. int. on DCD/GPi

	STX	gscmdb
	STA	gscmdb

	LDX	#0
	LDA	#%00010000	;reset ext. stat. ints.
	STX	gscmdb
	STA	gscmdb	;write it twice

	STX	gscmdb
	STA	gscmdb

	LDX	#1	;wr1
	LDA	#%00000000	;Wait Request disabled
	STX	gscmdb	;allow IRQs on Rx all & ext. stat
	STA	gscmdb	;No transmit interrupts (b1)

	LDA gscmdb		; READ TO RESET channelB POINTER TO 0
	LDA #$09
	STA gscmdb		; SET 'POINTER' TO wr9
	LDA #$00
	STA gscmdb		; Anti BluRry's syndrome medication 

	CLI
	RTS		;we're done!


; TIMECON: Set time constant bytes in wr12 & wr13
; (In other words, set the baud rate.)

TIMECON:
	LDY	baud
	LDA	#12
	STA	gscmdb
	LDA	baudl-1,y	;load time constant low
	STA	gscmdb

	LDA	#13
	STA	gscmdb
	LDA	baudh-1,y	;load time constant high
	STA	gscmdb
	RTS

; Table of values for different baud rates. There is
; a low byte and a high byte table.

baudl:	.byte	126	;300 bps (1)
	.byte	94	;1200 (2)
	.byte	46	;2400 (3)
	.byte	22	;4800 (4)
	.byte	10	;9600 (5)
	.byte	4	;19200 (6)
	.byte	1	;38400 (7)
	.byte	0	;57600 (8)

baudh:	.byte	1	;300 bps (1)
	.byte	0	;1200 (2)
	.byte	0	;2400 (3)
	.byte	0	;4800 (4)
	.byte	0	;9600 (5)
	.byte	0	;19200 (6)
	.byte	0	;38400 (7)
	.byte	0	;57600 (8)

;---------------------------------------------------------
; resetzgs - Clean up SCC every time we hit the main loop
;---------------------------------------------------------
resetzgs:
	lda gscmdb	; READ TO RESET channelB POINTER TO 0
	rts

;---------------------------------------------------------
; PATCHZGS - Patch the entry point of putc and getc over
;           to the IIgs versions
;---------------------------------------------------------
patchzgs:
	lda #<zccp
	sta putc+1
	lda #>zccp
	sta putc+2

	lda #<zccg
	sta getc+1
	lda #>zccg
	sta getc+2

	lda #<resetzgs
	sta resetio+1
	lda #>resetzgs
	sta resetio+2

	rts

;---------------------------------------------------------
; Default SCC baud rate
;---------------------------------------------------------
baud:	.byte 6	;1=300, 2=1200, 3=2400
		;4=4800, 5=9600, 6=19200
		;7=38400, 8=57600.

;---------------------------------------------------------
; Apple IIgs SCC Z8530 registers and constants
;---------------------------------------------------------

gscmdb	=	$C038
gsdatab	=	$C03A

gscmda	=	$C039
gsdataa	=	$C03B

reseta	=	%11010001	; constant to reset Channel A
resetb	=	%01010001	; constant to reset Channel B
wr11a	=	%11010000	; init wr11 in Ch A
wr11bxtal	=	%00000000	; init wr11 in Ch B - use external clock
wr11bbrg	=	%01010000	; init wr11 in Ch B - use baud rate generator
