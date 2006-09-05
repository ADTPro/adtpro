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
; BSAVE - Save a copy of ADTPro in memory
;---------------------------------------------------------
BSAVE:
	lda LENGTH+1
	lsr
	lsr
	lsr
	lsr
	clc
	cmp #$0a
	bcs BS1		; A is greater than 9
	adc #$B0
	jmp BS2
BS1:
	adc #$b6	; Get ascii of hex digit
BS2:
	sta NYBBLE1
	lda LENGTH+1
	and #$0F
	clc
	cmp #$0a
	bcs BS3		; A is greater than 9
	adc #$B0
	jmp BS4
BS3:
	adc #$b6
BS4:
	sta NYBBLE2

	lda LENGTH
	lsr
	lsr
	lsr
	lsr
	clc
	cmp #$0a
	bcs BS5		; A is greater than 9
	adc #$B0
	jmp BS6
BS5:
	adc #$b6
BS6:
	sta NYBBLE3
	lda LENGTH
	and #$0F
	clc
	cmp #$0a
	bcs BS7		; A is greater than 9
	adc #$B0
	jmp BS8
BS7:
	adc #$b6
BS8:
	sta NYBBLE4

	ldx #$00
LEWP:
	lda COMMAND,X
	sta $0200,X
	inx
	cpx CMDEND-COMMAND
	bne LEWP
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


COMMAND:	.byte "BSAVE ADTPRO,A$0803,L$"
NYBBLE1:	.byte $00
NYBBLE2:	.byte $00
NYBBLE3:	.byte $00
NYBBLE4:	.byte $00
CMDEND:	.byte $8D
LENGTH:	.word PEND-PBEGIN
