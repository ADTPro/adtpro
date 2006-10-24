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
; Call with carry set to divide evaluation by 10
; Returns the current value in the accumulator
;---------------------------------------------------------
EvaluateScreen:
	php
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
	plp
	bcs EvalTensOnly
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
EvalTensOnly:
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
	lda current_value
	rts

;---------------------------------------------------------
; PushDigit
;---------------------------------------------------------
PushDigit:
	clc
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
	jsr RenderNumber
PushAbort:
	rts

pushTemp:	.byte $00

;---------------------------------------------------------
; PullDigit
;---------------------------------------------------------
PullDigit:
	; First, is it zero?
	clc
	jsr EvaluateScreen
	beq PullAbort
	; Ok, it's nonzero.  What if we divide by 10?
	sec
	jsr EvaluateScreen
	sta current_value
	jsr RenderNumber
PullAbort:
	rts
