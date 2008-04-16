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
	lda #$0d
	sta CH
	lda #$03
	jsr TABV

	lda #PMLOGO1	; Start with MLOGO1 message
	sta ZP
    	ldx #$0d	; Get ready to HTAB $0d chars over
LogoLoop:
	stx CH		; Tab over to starting position
	tay
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	lda ZP
	cmp #PMLOGO5+2	; Stop at MLOGO5 message
	bne LogoLoop

	jsr CROUT
    	lda #$12
	sta CH
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
