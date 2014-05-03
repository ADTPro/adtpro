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

;---------------------------------------------------------
; PICKVOL
;   On entry: Y holds the pointer to the top line message
;
; Returns:
;   Index into the device table in A
;   $FF in A if escape was hit
;---------------------------------------------------------
PICKVOL:
	sty TopMessage
	jsr PRINTVOL
	jsr INVROW
	lda LASTVOL
	jsr VOLLOOP
	rts

;---------------------------------------------------------
; PRINTVOL
; 
; Prints on-line volume information 
; Y holds pointer to top line message
;---------------------------------------------------------
PRINTVOL:
	tya
	pha
	jsr HOME	; Clear screen
	pla
	tay
	jsr ONLINE
	rts

;---------------------------------------------------------
; VOLLOOP
; 
; Manages the volume screen, returns row selection in A
; ...which is an index into the device table
;---------------------------------------------------------
VOLLOOP:
	ldx #$25	; Column
	ldy #$15	; Row
	jsr GOTOXY
	jsr RDKEY
	CONDITION_KEYPRESS

VKEYDN:
	cmp #$8a	; Is it a key down?
	bne VKSPACE
	jmp VKEYD

VKSPACE:		; Is it a space?
	cmp #$80
	bne VKEYR
	jmp VKEYD

VKEYR:	cmp #$95	; Is it a key right?
	bne VKEYUP	; No - continue with next group

VKEYD:	lda VCURROW	; All roads lead to down
	cmp LASTVOLZERO
	beq LOOPUP	; Loop around to the top again
	jsr UNINVROW
	inc VCURROW
	jsr INVROW
	jmp VOLLOOP

LOOPUP:
	jsr UNINVROW
	lda #$00
	sta VCURROW
	jsr INVROW
	jmp VOLLOOP

VKEYUP:	cmp #$8b	; Is it a key up?
	bne VKEYL
	jmp VKEYU

VKEYL:	cmp #$88	; Is it a key left?
	bne VENTER	; No - continue with next group

VKEYU:	lda VCURROW	; All roads lead to up
	beq LOOPDN	; Loop around to bottom again
	jsr UNINVROW
	dec VCURROW
	jsr INVROW
	jmp VOLLOOP

LOOPDN:
	jsr UNINVROW
	lda LASTVOLZERO
	sta VCURROW
	jsr INVROW
	jmp VOLLOOP

VENTER:
	cmp #$8d	; Is it Enter?
	bne VREREAD	; No - process next group
	lda VCURROW	; Extract unit number
	jsr INTERPRET_ONLINE
	lda VCURROW	; Send the row selection back out
	rts

VREREAD:
	cmp #CHR_R	; Is it "R" - re-read?
	bne VESC	; No - continue with next group
	lda #$00	; Yes - re-read volume information
	sta LASTVOL	; Reset volume counter
	ldy TopMessage	; Get our top-line message back
	jsr PRINTVOL	; Re-read volume information
	jsr INVROW	; Invert the current row selection
	jmp VOLLOOP	; Back to the top of the loop

VESC:	cmp #$9B
	beq ESCAPE
	jmp VOLLOOP	; No, it was an unknown key - loop back around
ESCAPE:
	lda #$FF	; Set accumulator negative - no choice made
	rts		; Back out to caller

;---------------------------------------------------------
; PICKVOL2 - Re-entry to the volume screen; clears the 
;            operator area and lets you pick again
; Preserves X, Y
;---------------------------------------------------------
PICKVOL2:
	tya
	pha
	txa
	pha
	ldx #$00
	ldy #$16
	jsr GOTOXY
	jsr CLREOP
	pla
	tax
	pla
	tay
	jsr DRAWBDR
	jmp VOLLOOP

;---------------------------------------------------------
; INVROW - Inverts the current row
;---------------------------------------------------------
INVROW:
	lda VCURROW
	clc
	adc #VROFFS
	tay
	lda #VOL_LINE_LEN	; The length of line to highlight
	ldx #H_SL		; Start at the "Slot" column
	jsr INVERSE
	rts

UNINVROW:
	lda VCURROW
	clc
	adc #VROFFS
	tay
	lda #VOL_LINE_LEN	; The length of line to highlight
	ldx #H_SL		; Start at the "Slot" column
	jsr UNINVERSE
	rts

VCURROW:	.byte $00	; The current row the cursor is on (zero-indexed)
LASTVOLZERO:	.byte $00
VROFFS	= $05
TopMessage:	.byte $00