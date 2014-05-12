;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2014 by David Schmidt
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

	.export DELAY

;---------------------------------------------------------
; INIT_SCREEN
; 
; Sets up the screen for behaviors we expect
;---------------------------------------------------------
INIT_SCREEN:
	; Prepare the system for our expectations
	jsr SETUP
	jsr COL40

	CALLOS OS_FIND_SEG, FIND_SEG_PARMS
	bne Local_Quit

	lda #$00
	sta BIGBUF_ADDR_LO
	lda FIND_SEG_BASE+1
	sta BIGBUF_ADDR_HI
	lda FIND_SEG_BASE
	and #$0F			; Mask off the high nibble
	ora #$80			; Add the extended addressing bit
	sta BIGBUF_XBYTE		; This is our xbyte for BIGBUF addressing

	lda E_REG			; Read the environment register
	and #$f7			; Turn $C000-$CFFF to R/W
	ora #$40			; Turn $C000-$CFFF to I/O
	sta E_REG			; Write the environment register

; Points SOS' NMI vector at the debug routine in SOS. It normally
; points at an RTS so that hitting RESET doesn't do anything. This
; changes it so when you hit RESET, SOS enters a routine that saves all the
; important stuff, and jumps into the built in monitor. To reenter SOS, do
; a 198CG from the monitor. Known to work through SOS 1.3.
; To bank your memory in, set the bank register to the highest page
; I.e. FFEF:F6 for a 256k machine.
; Your zero page actually lives at $1A00-$1AFF.
	lda $1904			; Grab low byte of NMI vector
	sec				; Make sure that carry is set.
	sbc #$07			; Fall back 7 bytes from the
	sta $1911			; byte currently pointed to
	lda $1905			; (an RTS), and store this in
	sbc #$00			; the NMI JMP instruction.
	sta $1912			; Unwrap the high byte.

	rts

Local_Quit:
	jmp QUIT

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
    	lda #$02	; Get ready to HTAB $02 chars over
	sta <CH		; Tab over to starting position
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	ldy ZP
	cpy #PMLOGO6+2	; Stop at MLOGO6 message
	bne LogoLoop

	jsr CROUT
    	lda #$12
	sta <CH
	ldy #PMSG01	; Version number
	jsr WRITEMSG

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
	jsr COUT
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
; SHOWHMSG - Show host-initiated message #Y at current
; cursor location.  We further constrain messages to be
; even and within the host message range.
; Call SHOWHM1 to clear/print at message area.
;---------------------------------------------------------
SHOWHM1:
	sty SLOWY
	ldx #$00
	ldy #$16
	jsr GOTOXY
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
	clc
	tya
	ror		; Divide Y by 2 to get the message length out of the table
	tay
	lda HMSGLENTBL,Y
	jmp WRITEMSG_RAWLEN	; Call the regular message printer
	
;---------------------------------------------------------
; HLINE - Prints a row of underlines at current cursor position
;---------------------------------------------------------
HLINE:
	ldx #$28
HLINEX:			; Send in your own X for length
	lda #$DF
HLINE1:	jsr COUT
	dex
	bne HLINEX
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
; READ_LINE - Read a line of input from the console
;---------------------------------------------------------
READ_LINE:
	jsr GETLN2	; Get answer from INBUF (no prompt character)
	ldy RDTEMP
	lda #0		; Null terminate it
	sta (INBUF),y
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
; SET_INVERSE - Set output to inverse mode
; SET_NORMAL - Set output to normal mode
;---------------------------------------------------------
SET_INVERSE:
	lda MODES	; Start printing in inverse
	and #$7f	; Turn high bit off
	sta MODES
	rts
SET_NORMAL:
	lda MODES	; Start printing in inverse
	ora #$80	; Tick high bit on
	sta MODES
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
	sta INUM
	stx CH		; Set cursor to first position
	txa
	clc
	adc INUM	; Add starting position to count of total bytes
	sta INUM
	tya
	jsr TABV
	ldy CH
INV1:
	lda (BAS4L),Y
	pha
	asl
	bcs @WasNorm
	pla
	ora #$80
	bmi @PrintIt	; Always
@WasNorm:
	pla
	and #$7f	; Turn bit 7 off, for inverse-ness
@PrintIt:
	sta (BAS4L),Y
	iny
	cpy INUM
	bne INV1
	rts

INUM:	.byte $00

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
; WAIT - # cycles = (5*A*A + 27*A + 26)/2
;---------------------------------------------------------
DELAY:
	GO_SLOW
WAIT:	SEC		; Delay: # cycles = (5*A*A + 27*A + 26)/2
WAIT2:	PHA
WAIT3:	SBC #$01
	BNE WAIT3	; 1.0204 USEC
	PLA		;(13+27/2*A+5/2*A*A)
	SBC #$01
	BNE WAIT2
	GO_FAST
	RTS

GO_SLOW_SOS:
	php
	pha
	lda E_REG			; Read the environment register
	ora #$80			; Set 1MHz switch
	sta E_REG			; Write the environment register
	pla
	plp
	rts

GO_FAST_SOS:
	php
	pha
	lda E_REG			; Read the environment register
	and #$7f			; Set 2MHz switch
	sta E_REG			; Write the environment register
	pla
	plp
	rts


;---------------------------------------------------------
; SCRAPE - Scrape a line of text from the screen at the current cursor position, copy to input buffer
;---------------------------------------------------------
SCRAPE:
	ldy #$00
	sta CH		; Set cursor to first position
@Scr1:	lda (BAS4L),Y
	cmp #$A0
	beq :+
	sty INUM
:	sta IN_BUF,Y
	iny
	cpy #$28	; Whole screen width
	bne @Scr1
	lda #$00	; Null-terminate it
	ldy INUM
	iny
	sta IN_BUF,y
	rts

;---------------------------------------------------------
; Quit to SOS
;---------------------------------------------------------

QUIT:
	CALLOS OS_QUIT, QUITL

QUITL:
	.byte	$00,$00,$00,$00,$00,$00