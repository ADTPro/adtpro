*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

*---------------------------------------------------------
* PICKVOL
*
* Returns:
*   Index into the device table in A
*   $FF in A if escape was hit
*   Y holds the pointer to the top line message
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
	AND #$DF	Convert to upper case

VKEYDN	cmp #$8a
	bne VKSPACE
	jmp VKEYD

VKSPACE	cmp #$80
	bne VKEYR
	jmp VKEYD

VKEYR	cmp #$95
	bne VKEYUP

VKEYD	lda VCURROW
	cmp LASTVOL
	beq LOOPUP	Loop around to the top again
	jsr INVROW
	inc VCURROW
	jsr INVROW
	jmp VOLLOOP

LOOPUP
	jsr INVROW
	lda #$00
	sta VCURROW
	jsr INVROW
	jmp VOLLOOP

VKEYUP	cmp #$8b
	bne VKEYL
	jmp VKEYU

VKEYL	cmp #$88
	bne VENTER

VKEYU	lda VCURROW
	beq LOOPDN	Loop around to bottom again
	jsr INVROW
	dec VCURROW
	jsr INVROW
	jmp VOLLOOP

LOOPDN
	jsr INVROW
	lda LASTVOL
	sta VCURROW
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
	beq ESCAPE
	jmp VOLLOOP	No, it was an unknown key - loop back around
ESCAPE
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

