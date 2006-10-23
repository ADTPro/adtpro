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

ypos:		.byte $0B
xpos:		.byte $12
initval:	.byte $c8
current_value:	.byte $00
new_digit:	.byte $09
Hundred = $64
Ten = $0a

;---------------------------------------------------------
; EvaluateScreen
;---------------------------------------------------------
EvaluateScreen:
	lda #$00
	sta current_value
	lda ypos
	jsr $FBC1	; BASCALC
	clc
	lda xpos
	adc $28
	sta $28
	bcc :+
	inc $29
:	ldy #$00
	lda ($28),Y
	and #$4F	; Mask off B0
	beq EvalTens
	tax
:	lda #Hundred
	clc
	adc current_value
	sta current_value
	dex
	bne :-
EvalTens:
	clc
	inc $28
	bcc :+
	inc $29
:	ldy #$00
	lda ($28),Y
	and #$4F
	beq EvalOnes
	tax
:	lda #Ten
	clc
	adc current_value
	sta current_value
	dex
	bne :-
EvalOnes:
	clc
	inc $28
	bcc :+
	inc $29
:	lda ($28),Y
	and #$4F
	beq EvalDone
	clc
	adc current_value
	sta current_value
EvalDone:
	rts

;---------------------------------------------------------
; PushDigit
;---------------------------------------------------------
PushDigit:
	jsr EvaluateScreen
	lda current_value
	sta pushTemp
	clc
	ldx #$03
:	asl
	bcs PushAbort
	dex
	bne :-
	adc pushTemp
	bcs PushAbort
	adc pushTemp
	bcs PushAbort
	adc new_digit
	bcs PushAbort
DigitOK:
	sta current_value
	ldx xpos
	stx CH
	lda ypos
	jsr TABV
	lda #$00
	sta PRTPTR+1
	lda current_value
	sta PRTPTR
	jsr PRTNUMB
PushAbort:
	rts

pushTemp:	.byte $00