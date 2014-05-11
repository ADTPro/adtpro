;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2014 by David Schmidt
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

xpos		= $14	; Starting column of dotted-decimal config numbers
ypos		= $09	; Starting row of dotted-decimal config numbers
raw_x:		.byte $00
raw_y:		.byte $00
current_value:	.byte $00
new_digit:	.byte $09
ip_parms_temp:
		.byte 192, 168,   0,  12
		.byte   0,   0,   0,   0
		.byte   0,   0,   0,   0
		.byte   0,   0,   0,   0
		.byte   0,   0,   0,   0
		.byte   0,   0,   0,   0
ip_parms_temp_done:
Hundred = $64
Ten = $0a

;---------------------------------------------------------
; IPConfig
;
; 
;---------------------------------------------------------
IPConfig:
	; Pull in IP parms
	ldy #ip_parms_temp_done-ip_parms_temp-1
:	lda ip_parms,y
	sta ip_parms_temp,y
	dey
	bpl :-

	lda #<ip_parms_temp
	sta UTILPTR2
	lda #>ip_parms_temp
	sta UTILPTR2+1

	lda #ypos
	tay
	jsr TABV
@Dots:	clc
	lda #xpos
	adc #$03
	sta <CH
	lda #CHR_DOT
	jsr COUT1
	lda #xpos
	adc #$07
	sta <CH
	lda #CHR_DOT
	jsr COUT1
	lda #xpos
	adc #$0b
	sta <CH
	lda #CHR_DOT
	jsr COUT1
	iny
	cpy #ypos+4
	beq :+
	tya
	jsr TABV
	jmp @Dots
:

@Paint:
	lda #$00
	sta raw_x
	sta raw_y
@PLoop:	
	jsr BuildIndex
	lda (UTILPTR2),Y
	sta current_value
	jsr RenderNumber
	clc
	lda raw_x
	adc #$04
	sta raw_x
	cmp #$10
	bne @PLoop
	lda #$00
	sta raw_x
	inc raw_y
	lda raw_y
	cmp #$04
	bne @PLoop
	lda #$00
	sta raw_x
	sta raw_y
	sta dirtyBit
	rts

IPConfigTopEntry:
	lda #$05
	jsr COUT		; Turn cursor on
	lda #$00
	sta raw_x
	sta raw_y
	jmp IPConfigReEntry

IPConfigBottomEntry:
	lda #$05
	jsr COUT		; Turn cursor on
	lda #$00
	sta raw_x
	lda #$03
	sta raw_y
	jmp IPConfigReEntry

IPConfigReEntry:
	jsr BuildIndex
	lda (UTILPTR2),Y
	sta current_value
	jsr RenderNumber
	jsr InputLoop
	bmi IPConfigExit
	pha		; Save the return value
	clc
	jsr EvaluateScreen
	jsr BuildIndex
	sta (UTILPTR2),Y
	pla
	beq ExitRight
	cmp #$01
	beq ExitUp
	cmp #$02
	beq ExitDown
	cmp #$03
	beq ExitLeft
IPConfigExit:
	pha
	lda #$06	; Turn the cursor back off
	jsr COUT
	pla
	rts

ExitLeft:
	lda raw_x
	sec
	sbc #$04
	bcs :+		; >= 0?
	lda #$0C	; It's negative, so go to the right
:	sta raw_x
	jmp IPConfigReEntry

ExitRight:
	lda raw_x
	clc
	adc #$04
	cmp #$0D
	bmi :+
	lda #$00
:	sta raw_x
	jmp IPConfigReEntry

ExitUp:
	lda #$00
	sta raw_x
	lda raw_y
	sec
	sbc #$01
	bcs :+
	lda #$06	; Turn the cursor back off
	jsr COUT
	ldx #PARMNUM-1	; Head back to upper config items - bottom
	rts
:	sta raw_y
	jmp IPConfigReEntry

ExitDown:
	lda #$00
	sta raw_x
	lda #$01
	clc
	adc raw_y
	cmp #$04
	bmi :+
	lda #$06	; Turn the cursor back off
	jsr COUT
	ldx #$00	; Head back to upper config items - top
	txa
	rts
:	sta raw_y
	jmp IPConfigReEntry

;---------------------------------------------------------
; InputLoop
;
; Keyboard handler, dispatcher
;---------------------------------------------------------
InputLoop:
	jsr RDKEY	; GET ANSWER
	cmp #$b0	; Is it between zero...
	bmi @NotNum
	cmp #$ba	; ... and nine?
	bpl @NotNum
	and #$4f	; Yes - we have a new digit!
	sta new_digit
	jsr PushDigit
	jmp InputLoop
@NotNum:
	cmp #$95	; Right arrow key?
	bne :+
	lda #$00
	sta dirtyBit
	rts
:
	cmp #$ae	; Period (Right)?
	bne :+
	lda #$00
	sta dirtyBit
	rts
:
	cmp #$8b	; Up arrow?
	bne :+
	lda #$00
	sta dirtyBit
	lda #$01
	rts
:
	cmp #$8a	; Down arrow?
	beq :+
	cmp #$a0	; Space?
	beq :+
	jmp @Next
:	lda #$00
	sta dirtyBit
	lda #$02
	rts
@Next:
	cmp #$88	; Left arrow?
	bne :+
	lda #$00
	sta dirtyBit
	lda #$03
	rts
:
	cmp #$9B	; Escape?
	bne :+		; Nope, next...
	lda #$FF
	rts
:
	cmp #$8d	; Enter
	bne :+		; Nope, next...
	lda #$04
	rts
:
	jmp InputLoop

;---------------------------------------------------------
; RenderNumber
; Renders current_value at (xpos,ypos)
;---------------------------------------------------------
RenderNumber:
	clc
	lda #ypos
	adc raw_y
	jsr TABV
	clc
	lda #xpos
	adc raw_x
	sta <CH
	lda current_value
	jsr ToDecimal
	clc
	lda #xpos
	adc raw_x
	adc #$02
	sta <CH
	rts

;---------------------------------------------------------
; EvaluateScreen
; Call with carry set to divide evaluation by 10
; Returns the current value in the accumulator
;---------------------------------------------------------
EvaluateScreen:
	php
	lda #$00
	sta current_value
	clc
; Keep running total of X,Y and read screen
	lda #ypos
	adc raw_y
	jsr BASCALC
	clc
	lda #xpos
	adc raw_x
	adc BASL
	sta BASL
	bcc :+
	inc BASH
:	ldy #$00
	plp
	bcs EvalTensOnly
	lda (BASL),Y
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
	inc BASL
	bcc :+
	inc BASH
:	ldy #$00
EvalTensOnly:
	lda (BASL),Y
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
	inc BASL
	bcc :+
	inc BASH
:	lda (BASL),Y
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
	lda dirtyBit
	bne :+
	lda #$01
	sta dirtyBit
	lda #$00
	sta current_value
	jmp PushColdEntry
:	clc
	jsr EvaluateScreen
PushColdEntry:
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
PushAbort:
	jsr RenderNumber
	rts

pushTemp:	.byte $00
dirtyBit:	.byte $00
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

;---------------------------------------------------------
; BuildIndex
;
; Loads the index to the save array in Y based on raw_x and raw_y
;---------------------------------------------------------
BuildIndex:
	pha
	lda raw_x
	lsr
	lsr
	sta pushTemp
	lda raw_y
	asl
	asl
	clc
	adc pushTemp
	tay
	pla
	rts
