;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006-2007 by David Schmidt
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
; BSAVE - Save a copy of ADTPro in memory
;---------------------------------------------------------
BSAVE:
	lda LENGTH+1	; Convert 16-bit length to a hex string
	pha
	jsr tochrhi		; Hi nybble, hi byte
	sta NYBBLE1
	pla
	jsr tochrlo		; Lo nybble, hi byte
	sta NYBBLE2
	lda LENGTH
	pha
	jsr tochrhi		; Hi nybble, lo byte
	sta NYBBLE3
	pla
	jsr tochrlo		; Lo nybble, lo byte
	sta NYBBLE4

	ldx #$00
:	lda COMMAND,X
	sta $0200,X
	inx
	cpx CMDEND-COMMAND
	bne :-
	lda #$00
	sta $BE0F	; Clear ProDOS error code
	jsr $BE03	; Execute the input buffer

	lda #$00	; Prepare to print ProDOS error message
	sta <CH
	lda #$15
	jsr TABV

	lda $BE0F	; Grab the error code out of ProDOS
	beq BSAVEOK	; If no problem - exit
	jsr $BE0C	; Print ProDOS error message
	jmp BSAVEDONE
BSAVEOK:
	lda #$16
	jsr TABV
	ldy #PMSG14
	jsr SHOWMSG
BSAVEDONE:
	jsr PAUSE
	rts

;---------------------------------------------------------
; tochrlo/hi:
; Convert a nybble in A to a character representing its
; hex value, returned in A
;---------------------------------------------------------
tochrlo:
	and #$0f
	jmp tochrgo
tochrhi:
	lsr
	lsr
	lsr
	lsr
tochrgo:
	clc
	cmp #$0a
	bcc gt9			; A is greater than 9
	adc #$B6
	jmp tochrdone
gt9:
	ora #$B0
tochrdone:
	rts

; Note - the device-specific bsave routine is appended here, depending
;        on what type of device we're talking to (serial vs. ethernet).
; See: ethernet/ethbsave.asm, serial/serbsave.asm