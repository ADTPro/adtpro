*---------------------------------------------------------
* PICKVOL
*
* Returns:
*   Index into the device table in A
*   $FF in A if escape was hit
*---------------------------------------------------------
PICKVOL
	jsr PRINTVOL
	lda #$00
	sta VCURROW
	jsr INVROW
	jsr VOLLOOP
	rts

*---------------------------------------------------------
* VOLLOOP
* 
* Manages the volume screen, returns selection in A
* which is an index into the device table
*---------------------------------------------------------
VOLLOOP	lda #$23	Column
	sta <CH
	lda #$15	Row
	JSR TABV

	jsr rdkey
	AND #$DF	CONVERT TO UPPERCASE

vKEYDN	cmp #$8a
	bne VKEYR
	jmp VKEYD

VKEYR	cmp #$95
	bne VKEYUP

VKEYD	lda VCURROW
	cmp LASTVOL
	beq VOLLOOP	NOP if hit down on the bottom row
	jsr INVROW
	inc VCURROW
	jsr INVROW
	jmp VOLLOOP

VKEYUP	cmp #$8b
	bne VKEYL
	jmp VKEYU

VKEYL	cmp #$88
	bne VENTER

VKEYU	lda VCURROW
	beq VOLLOOP	NOP if hit up on the top row
	jsr INVROW
	dec VCURROW
	jsr INVROW
	jmp VOLLOOP

VENTER	cmp #$8d	Process enter
	bne VESC

	lda VCURROW	Extract unit number
	jsr WHATUNIT
	sta UNITNBR

	lda VCURROW	Extract unit capacity
	clc
	rol		Multiply by 2
	tax		X is now the index into blocks table
	lda CAPBLKS,X
	sta NUMBLKS
	lda CAPBLKS+1,X
	sta NUMBLKS+1

	lda VCURROW	Send the row selection back out
	rts

VESC	cmp #$9B
	bne VOLLOOP	No, it was an unknown key - loop back around
	lda #$FF	Set accumulator negative - no choice made
	rts		Back out to caller


*---------------------------------------------------------
* INVROW - Inverts the current row
*---------------------------------------------------------
INVROW
	lda VCURROW
	clc
	adc #VROFFS
	tay
	lda #$24	The length of line to highlight
	ldx #H_SL	Start at the "Slot" column
	jsr INVERSE
	rts

VCURROW	.db $00
VROFFS	.eq $05

