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

	.org $A000

KBDSTROBE	:= $C010
E_REG		:= $FFDF
B_REG		:= $FFEF
screenptr	:= $7c
screenptr_lsb	:= $7c
screenptr_msb	:= $7d
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
	sta screenptr_lsb
	lda #$1e	; Initial SOS.KERNEL runs from $1e00 to $73ff
	sta buffer_msb
	lda #$04	; Screen memory
	sta screenptr_msb

; Set up the serial port
	lda #$0b	; No parity, etc.
	sta $c0f2
	lda #$10	; 115kbps
	sta $c0f3

; Poll the port until we get a magic incantation
Poll:
	jsr IIIGET
	cmp #$a3
	bne Poll

; We got the magic signature; start reading data
Read:	
	jsr IIIGET	; Pull a byte
	sta (buffer),y	; Save it
	sta (screenptr),y	; Print it
	iny
	bne Read
	inc buffer_msb
	cmp #$74
	bne Read

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
