;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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

; The manual bootstrapping startup procedure.
; This would need to be typed into the monitor (ctrl-OA-reset) and then
; run (A000G).  Alternatively, you can test this by inserting the assembled
; code into sector zero (block zero) of a diskette and booting it.
; The /// ROM will pull it into $A000 and execute it.

	.org $a000

KBDSTROBE	:= $C010
ENV_REG		:= $FFDF
BANK_REG	:= $FFEF
buffer_lsb	:= $7e
buffer_msb	:= $7f

ACIADR		:= $c0f0	; Data register. $c0f0 for ///, $c088+S0 for SSC
ACIASR		:= $c0f1	; Status register. $c0f1 for ///, $c089+S0 for SSC
ACIAMR		:= $c0f2	; Command mode register. $c0f2 for ///, $c08a+S0 for SSC
ACIACR		:= $c0f3	; Control register.  $c0f3 for ///, $c08b+S0 for SSC

entry:	sei
	cld
	lda #$77
	sta ENV_REG
	ldx #$FB
	txs
	bit KBDSTROBE
	lda #$40
	sta $FFCA		; Disable interrupts
	lda #$07
	sta BANK_REG
	ldx #$00		; Note - we rely on x remaining zero until we print our welcome message
banktest:			; Find highest writable bank
	dec BANK_REG
	stx $2000
	lda $2000
	bne banktest

; Slow down to 1MHz
	lda ENV_REG		; Read the environment register
	ora #$80		; Set 1MHz switch
	sta ENV_REG		; Write the environment register

; Set up our pointers
	stx buffer_lsb		; x is still zero
	lda #$1e		; SOS.KERNEL initially occupies $1e00 to $73ff
	sta buffer_msb

; Set up the serial port
	lda #$0b		; No parity, etc.
	sta ACIAMR		; Store via ACIA mode register.
	lda #$10		; $16=300, $1e=9600, $1f=19200, $10=115k
	sta ACIACR		; Store via ACIA control register.

; Say we're active
	ldy #$03
:	lda message_1,y
	sta $0400,y
	dey
	bpl :-
	iny			; Make y zero

; Poll the port until we get a magic incantation
Poll:
	jsr IIIGET
	cmp #$53		; First character will be "S" from "SOS" in SOS.KERNEL
	bne Poll
	sta (buffer_lsb),y	; Save that first "S"
	iny

; We got the magic signature; start reading data
Read:	
	jsr IIIGET		; Pull a byte
	sta (buffer_lsb),y	; Save it
	sta $0405		; Print it in the status area
	iny
	bne Read
	inc buffer_msb		; Increment another page
	lda buffer_msb
	cmp #$74		; Are we done? (SOS.KERNEL v1.3 is $56 pages long; $1E+$56=$74)
	bne Read		; If not... go back for more

; Go fast again
	lda ENV_REG	; Read the environment register
	and #$7f	; Set 2MHz switch
	sta ENV_REG	; Write the environment register

; Call SOSLDR entry point
	jmp $1e70	; SOSLDR v1.3 Entry point

IIIGET:
	lda ACIASR	; Check status bits via ACIA status register
	and #$68
	cmp #$08
	bne IIIGET	; Input register empty, loop
	lda ACIADR	; Get character via ACIA data register
	rts

message_1:
	.byte	"ำลาบ"	; "SER:"

.align	256
.assert	* = $a100, error, "Code got too big to fit in a block!  C'mon, someone is supposed to be able to type this into the monitor!"
