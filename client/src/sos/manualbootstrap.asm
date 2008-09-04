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
E_REG		:= $FFDF
B_REG		:= $FFEF
buffer		:= $7e
buffer_lsb	:= $7e
buffer_msb	:= $7f

entry:	sei
	cld
	lda #$77
	sta E_REG
	ldx #$FB
	txs
	bit KBDSTROBE
	lda #$40
	sta $FFCA	; Disable interrupts
	lda #$07
	sta B_REG
	ldx #$00
banktest:		; Find highest writable bank
	dec B_REG
	stx $2000
	lda $2000
	bne banktest

; Slow down to 1MHz
	lda $ffdf	; Read the environment register
	ora #$80	; Set 1MHz switch
	sta $ffdf	; Write the environment register

; Set up our pointers
	lda #$00
	tay		; We'll use Y later as an index
	sta buffer_lsb
	lda #$1e	; Initial SOS.KERNEL runs from $1e00 to $73ff
	sta buffer_msb

; Set up the serial port
	lda #$0b	; No parity, etc.
	sta $c0f2
	lda #$1e	; 9600 bps
	sta $c0f3

; Say we're active
	ldx #$00
:	lda message_1,x
	sta $0400,x
	inx
	cpx #$04
	bne :-

	lda #$57	; "W" - printed after message
	sta $0405

; Poll the port until we get a magic incantation
Poll:
	jsr IIIGET
	cmp #$53	; First character will be "S" from "SOS"
	bne Poll

; We got the magic signature; start reading data
Read:	
	jsr IIIGET	; Pull a byte
	sta (buffer),y	; Save it
	sta $0405	; Print it in the corner
	iny
	bne Read
	inc buffer_msb
	cmp #$74
	bne Read

; Say we're done
	ldx #$00
:	lda message_2,x
	sta $0400,x
	inx
	cpx #$04
	bne :-

; Go fast again
	lda $ffdf	; Read the environment register
	and #$7f	; Set 2MHz switch
	sta $ffdf	; Write the environment register

; Call SOSLDR entry point
	jmp $1e70	; SOSLDR Entry point

IIIGET:
	lda $c000
	lda $c0f1	; Check status bits
	and #$68
	cmp #$08
	bne IIIGET	; Input register empty, loop
	lda $c0f0	; Get character
	rts

message_1:
	.byte	"сер╨"	; "SER:"

message_2:
	.byte	"ок║ "	; "OK! "
;	.byte $d7, $c1, $c9, $d4, $c9, $ce, $c7, $ae, $ae, $ae

	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00
