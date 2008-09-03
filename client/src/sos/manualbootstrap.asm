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

	.org $B000
; Slow down to 1MHz
	lda $ffdf	; Read the environment register
	ora #$80	; Set 1MHz switch
	sta $ffdf	; Write the environment register

; Set up the serial port
	lda #$0b	; No parity, etc.
	sta $c0f2
	lda #$10	; 115kbps
	sta $c0f3

; Set up our pointer
	lda #$00
	tay		; We'll use Y later as an index
	sta $7c
	sta $7e
	lda #$a0
	sta $7f
	lda #$04
	sta $7d

; Poll the port until we get a magic incantation
Poll:
	jsr IIIGET
	cmp #$a3
	bne Poll

; We got the magic signature; start reading data
Read:	
	jsr IIIGET	; Pull a byte
	sta ($7e),y	; Save it
	sta ($7c),y
	iny
	bne Read
	inc $7f
	cmp #$a2
	bne Read

; Go fast again
	lda $ffdf	; Read the environment register
	and #$7f	; Set 2MHz switch
	sta $ffdf	; Write the environment register

; Call SOSLDR entry point
	jmp $a06e	; Entry point - varies by specific loader version

IIIGET:
	lda $c000
	lda $c0f1	; Check status bits
	and #$68
	cmp #$08
	bne IIIGET	; Input register empty, loop
	lda $c0f0	; Get character
	rts
