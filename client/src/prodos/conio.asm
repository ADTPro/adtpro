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

;---------------------------------------------------------
; INIT_SCREEN
; 
; Sets up the screen for behaviors we expect
;---------------------------------------------------------
INIT_SCREEN:
	; Prepare the system for our expecations -
	; Basic, 64k Applesoft Apple ][.  That's all it
	; should take.

	jsr $FE84	; NORMAL TEXT
	jsr $FB2F	; TEXT MODE, FULL WINDOW
	jsr $FE89	; INPUT FROM KEYBOARD
	jsr $FE93	; OUTPUT TO 40-COL SCREEN
	rts

;---------------------------------------------------------
; SHOWLOGO
; 
; Prints the logo on the screen
;---------------------------------------------------------
SHOWLOGO:
	ldx #$0d
	ldy #$03
	jsr GOTOXY
	lda #PMLOGO1	; Start with MLOGO1 message
	sta ZP
	tay
LogoLoop:
    	lda #$0d	; Get ready to HTAB $0d chars over
	jsr HTAB	; Tab over to starting position
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	ldy ZP
	cpy #PMLOGO5+2	; Stop at MLOGO5 message
	bne LogoLoop

	jsr CROUT
    	lda #$12
	jsr HTAB
	ldy #PMSG01	; Version number
	jsr WRITEMSG

	rts

;---------------------------------------------------------
; GOTOXY - Position the cursor
;---------------------------------------------------------
GOTOXY:
	stx <CH
	tya
	jsr TABV
	rts

;---------------------------------------------------------
; HTAB - Horizontal tab to column in accumulator
;---------------------------------------------------------
HTAB:
	sta <CH
	rts

;---------------------------------------------------------
; WRITEMSG - Print null-terminated message number in Y
;---------------------------------------------------------
; Entry - clear and print at the message area (row $16)
WRITEMSGAREA:
	sty SLOWY
	lda #$16
	jsr TABV
	ldy SLOWY
; Entry - print message at left border, current row
WRITEMSGLEFT:
	sty SLOWY
	lda #$00
	sta CH
	jsr CLREOP
	ldy SLOWY
; Entry - print message at current cursor pos
WRITEMSG:
	lda MSGTBL,Y
	sta UTILPTR
	lda MSGTBL+1,Y
	sta UTILPTR+1
; Entry - print message at current cursor pos
;         set UTILPTR to point to null-term message
WRITEMSGRAW:
	clc
	tya
	ror		; Divide Y by 2 to get the message length out of the table
	tay
	lda MSGLENTBL,Y
	beq WRITEMSGEND	; Bail if length is zero (i.e. MNULL)
	sta WRITEMSGLEN
	ldy #$00
WRITEMSGLOOP:
	lda (UTILPTR),Y
	jsr COUT1
	iny
	cpy WRITEMSGLEN
	bne WRITEMSGLOOP
WRITEMSGEND:
	rts

WRITEMSGLEN:	.byte $00

;---------------------------------------------------------
; CLRMSGAREA - Clear out the bottom part of the screen
;---------------------------------------------------------
CLRMSGAREA:
	lda #$00
	sta <CH
	lda #$14
	jsr TABV
	jsr CLREOP
	rts

;---------------------------------------------------------
; SHOWHMSG - Show null-terminated host message #Y at current
; cursor location.  We further constrain messages to be
; even and within the host message range.
; Call SHOWHM1 to clear/print at message area.
;---------------------------------------------------------
SHOWHM1:
	sty SLOWY
	lda #$00
	sta CH
	lda #$16
	jsr TABV
	jsr CLREOP
	ldy SLOWY

SHOWHMSG:
	tya
	and #$01	; If it's odd, it's garbage
	cmp #$01
	beq HGARBAGE
	tya
	clc
	cmp #PHMMAX
	bcs HGARBAGE	; If it's greater than max, it's garbage
	jmp HMOK
HGARBAGE:
	ldy #PHMGBG
HMOK:
	lda HMSGTBL,Y
	sta UTILPTR
	lda HMSGTBL+1,Y
	sta UTILPTR+1

	ldy #$00
	jmp WRITEMSGLOOP	; Call the regular message printer
	
;---------------------------------------------------------
; READ_LINE - Read a line of input from the console
;---------------------------------------------------------
READ_LINE:
	ldx #0		; Get answer from $200
	jsr NXTCHAR
	lda #0		; Null terminate it
	sta $200,X
	txa
	rts

;---------------------------------------------------------
; READ_CHAR - Read a single character, no cursor
;---------------------------------------------------------
READ_CHAR:
	lda $C000         ;WAIT FOR NEXT COMMAND
	bpl READ_CHAR
	bit $C010
	rts

;---------------------------------------------------------
; INVERSE - Invert/highlight the characters on the screen
;
; Inputs:
;   A - number of bytes to process
;   X - starting x coordinate
;   Y - starting y coordinate
;---------------------------------------------------------
INVERSE:
	clc
	sta INUM
	stx CH		; Set cursor to first position
	txa
	adc INUM
	sta INUM
	tya
	jsr TABV
	ldy CH
INV1:	lda (BASL),Y
	and #$BF
	eor #$80
	sta (BASL),Y
	iny
	cpy INUM
	bne INV1
	rts

INUM:	.byte $00

;---------------------------------------------------------
; SET_INVERSE - Set output to inverse mode
; SET_NORMAL - Set output to normal mode
;---------------------------------------------------------
SET_INVERSE:
	lda #$3F	; Start printing in inverse
	sta <INVFLG
	rts
SET_NORMAL:
	lda #$FF	; Back to normal
	sta <INVFLG
	rts
