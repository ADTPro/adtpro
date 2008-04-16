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

; Header for ProDOS interpreter

	.segment "SYS"

	.import ASMEND

	.org $2000

;---------------------------------------------------------
; Initialization - free ProDOS BASIC Interpreter memory
;---------------------------------------------------------
INIT:
	STA   ROM        ; Swap in ROM
	LDX   #23        ; Initialize bitmap
	LDA   #%00000001 ; $BF00-$BFFF (ProDOS Global Page)
	STA   BITMAP,X
	DEX
	LDA   #0         ; free main memory
:	STA   BITMAP,X
	DEX
	BNE   :-         ; don't touch the $0000-$07FF aera

;---------------------------------------------------------
; Kill the reset vector
;---------------------------------------------------------
	lda #$69		; Vector reset to the monitor
	sta $03f2
	lda #$ff
	sta $03f3	; $ff69, aka CALL -151
	eor #$a5
	sta $03f4	; Fixup powerup byte 

;---------------------------------------------------------
; ProDOS SYS relocators
;---------------------------------------------------------
PRE_MOVER:		; Need to protect relocation code
	lda #<MOVER
	sta <A1L
	lda #>MOVER
	sta <A1H
	lda #<MOVEREND-1
	sta <A2L
	lda #>MOVEREND
	sta <A2H
	lda #$00
	sta <A4L
	lda #$03
	sta <A4H
	ldy #$00
	jsr MEMMOVE
	jmp $0300

MOVER:			; Relocate full program
	lda #<MOVEREND
	sta <A1L
	lda #>MOVEREND
	sta <A1H
	lda #<(MOVEREND+ASMEND-ASMBEGIN)
	sta <A2L
	lda #>(MOVEREND+ASMEND-ASMBEGIN)
	sta <A2H
	lda #$00
	sta <A4L
	lda #$08
	sta <A4H
	ldy #$00
	jsr MEMMOVE
	jmp $0800
MOVEREND:

	.segment "STARTUP"
	.org $0800	; After relocation, this orgs at $0800 

ASMBEGIN:
	jmp entrypoint	; Start it up!