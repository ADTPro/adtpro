;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2018 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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
	lda #$00
	sta $c00f	; Turn mousetext on for inverse lowercase

	; Clean out the whole system bit map
	ldx	#($C0 / 8) - 1

	; Set protection for pages $B8 - $BF
	lda	#%00000001
	sta	BITMAP,x
	dex

	; Set protection for pages $08 - $B7
	lda	#%00000000
:	sta	BITMAP,x
	dex
	bne	:-

	; Set protection for pages $00 - $07
	lda	#%11001111
	sta	BITMAP,x

	rts

;---------------------------------------------------------
; SHOWLOGO
; 
; Prints the logo on the screen
;---------------------------------------------------------
SHOWLOGO:
	ldx #$02
	ldy #$02
	jsr GOTOXY
	lda #PMLOGO1	; Start with MLOGO1 message
	sta ZP
	tay
LogoLoop:
    	lda #$02	; Get ready to HTAB $0a chars over
	SET_HTAB	; Tab over to starting position
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	ldy ZP
	cpy #PMLOGO6+2	; Stop at MLOGO6 message
	bne LogoLoop

	jsr CROUT
    	lda #$12
	SET_HTAB
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
; HLINE - Prints a row of underlines at current cursor position
;---------------------------------------------------------
HLINE:
	ldx #$28
HLINEX:			; Send in your own X for length
	lda #$df
HLINE1:	jsr COUT1
	dex
	bne HLINE1
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
; Entry - print message at left border, current row, clear to end of page
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
WRITEMSG_RAW:
	clc
	tya
	ror		; Divide Y by 2 to get the message length out of the table
	tay
	lda MSGLENTBL,Y
	beq WRITEMSGEND	; Bail if length is zero (i.e. MNULL)
WRITEMSG_RAWLEN:
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
; IPShowMsg
;---------------------------------------------------------
IPShowMsg:
	sta UTILPTR
	stx UTILPTR+1
	tya		; Put the length in accumulator
	jsr WRITEMSG_RAWLEN
	rts

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
UNINVERSE:
INV_GO:
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
	sta ZP		; Stash A for a minute
	and #$e0	; Isolate the top 3 bits
	cmp #$80	; Is it 8?
	beq @PrintIt	; Yes, so stays 8
	cmp #$a0	; is it a?
	bne :+		; No
	lda ZP		; Yes, so change to 2
	and #$1f
	ora #$20
	jmp @PrintIt
:	cmp #$c0	; is it c?
	bne :+		; No
	lda ZP		; Yes, so changes to 0
	and #$1f
	jmp @PrintIt
:	cmp #$e0	; is it e?
	bne :+		; No
	lda ZP		; Yes, so changes to 6
	and #$1f
	ora #$60
	jmp @PrintIt
:	cmp #$20	; Is it 2?
	bne @TryZero	; No
	lda ZP		; Yes, so change to a
	and #$1f
	ora #$a0
	jmp @PrintIt
@TryZero:
	cmp #$00	; Is it 0?
	bne :+
	lda ZP		; Yes, so change to c
	ora #$c0
	jmp @PrintIt
:	lda ZP		; Must be 6
	and #$1f	; Change to e
	ora #$e0
@PrintIt:
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

;---------------------------------------------------------
; SCRAPE - Copy directory page and row numbers to input buffer
;---------------------------------------------------------
SCRAPE:
	lda #$01
	sta IN_BUF
	lda NIBPCNT	; Current directory page being viewed
	clc
	adc #$01	; Bump directory page by 1 so it's never zero
	sta IN_BUF + 1
	lda CV		; Vertical position on screen; will always be +3
	sta IN_BUF + 2
	lda #$00	; Null-terminate it
	sta IN_BUF + 3
	rts

;---------------------------------------------------------
; Quit to ProDOS
;---------------------------------------------------------

QUIT:
	sta ROM
	CALLOS OS_QUIT, QUITL

QUITL:
	.byte	4
        .byte	$00,$00,$00,$00,$00,$00