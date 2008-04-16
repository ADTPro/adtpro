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
	; Prepare the system for our expecations
	CALLOS OS_OPEN, OPEN_PARMS	; Open the console
	bcs Local_Quit
	lda OPEN_REF
	sta WRITE_REF	; Save off our terminal references
	sta WRITE1_REF
	sta CONSREAD_REF

	lda #INIT_SCREEN_DATA_END-INIT_SCREEN_DATA
	sta WRITE_LEN
	lda #<INIT_SCREEN_DATA
	sta UTILPTR
	lda #>INIT_SCREEN_DATA
	sta UTILPTR+1
	jsr WRITEMSG_RAW
	rts

Local_Quit:
	jmp *	; TODO: Would be nice to jump to QUIT here...

INIT_SCREEN_DATA:
	.byte 16, 0	; Set 40 columns
	.byte 21, $0f	; Make return do newline
	.byte 28	; Clear screen
INIT_SCREEN_DATA_END:

;---------------------------------------------------------
; HOME
; 
; Clears the screen
;---------------------------------------------------------
HOME:
	lda #$1c
	jsr COUT
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
    	ldx #$0d	; Get ready to HTAB $0d chars over
LogoLoop:
	jsr HTAB	; Tab over to starting position
	tay
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	lda ZP
	cmp #PMLOGO5+2	; Stop at MLOGO5 message
	bne LogoLoop

	jsr CROUT
    	ldx #$12
	jsr HTAB
	ldy #PMSG01	; Version number
	jsr WRITEMSG
	rts

;---------------------------------------------------------
; WRITEMSG - Print null-terminated message number in Y
;---------------------------------------------------------
; Entry - clear and print at the message area (row $16)
WRITEMSGAREA:
	ldx #$16
	jsr VTAB
; Entry - print message at left border, current row
WRITEMSGLEFT:
	lda #$1e		; Clear line
	jsr COUT
WRITEMSG:
	lda MSGTBL,Y
	sta UTILPTR		; Point UTILPTR at our message
	lda MSGTBL+1,Y
	sta UTILPTR+1
WRITEMSGRAW:
	clc
	tya
	ror		; Divide Y by 2 to get the message length out of the table
	tay
	lda MSGLENTBL,Y
	sta WRITE_LEN
WRITEMSG_RAW:
	CALLOS OS_WRITEFILE, WRITE_PARMS
	jmp ERRORCK		; Retrun through error handler for SOS errors

;---------------------------------------------------------
; GOTOXY - Position the cursor
;---------------------------------------------------------
GOTOXY:
	stx WRITEMSG_XY+1
	sty WRITEMSG_XY+2
	lda #<WRITEMSG_XY
	sta UTILPTR
	lda #>WRITEMSG_XY
	sta UTILPTR+1
	lda #$03
	sta WRITE_LEN
	jsr WRITEMSG_RAW
	rts

WRITEMSG_XY:
	.byte 26, $00, $00

;---------------------------------------------------------
; VTAB - Vertical tab to row X
;---------------------------------------------------------
VTAB:
	stx WRITEMSG_VT+1
	lda #<WRITEMSG_VT
	sta UTILPTR
	lda #>WRITEMSG_VT
	sta UTILPTR+1
	lda #$02
	sta WRITE_LEN
	jsr WRITEMSG_RAW

WRITEMSG_VT:
	.byte $19,$16

;---------------------------------------------------------
; HTAB - Horizontal tab to column X
;---------------------------------------------------------
HTAB:
	stx WRITEMSG_HT+1
	lda #<WRITEMSG_HT
	sta UTILPTR
	lda #>WRITEMSG_HT
	sta UTILPTR+1
	lda #$02
	sta WRITE_LEN
	jsr WRITEMSG_RAW

WRITEMSG_HT:
	.byte $18,$16

;---------------------------------------------------------
; GETCHR1
; 
; Read a character from the console
;---------------------------------------------------------
GETCHR1:
	clc
	CALLOS OS_READFILE, CONSREAD_PARMS
	jsr ERRORCK
	lda CONSREAD_INPUT
	rts

ERRORCK:
	bcs SOS_ERROR
NoError:
	rts
SOS_ERROR:
	rts	; TODO: fixme
	;jmp QUIT

;---------------------------------------------------------
; Character output
; 
; Send one character to the console from Accumulator
; Special case: CROUT, which prints a carriage return
;---------------------------------------------------------
CROUT:	; Output return character
	lda #$8d
COUT:	; Character output routine (print to screen)
COUT1:	; Character output
	sta WRITE1_DATA
	CALLOS OS_WRITEFILE, WRITE1_PARMS
	clc
	rts

;---------------------------------------------------------
; CLRMSGAREA - Clear out the bottom part of the screen
;---------------------------------------------------------
CLRMSGAREA:
	lda #<CLRMSGAREA_DATA
	sta UTILPTR
	lda #>CLRMSGAREA_DATA
	sta UTILPTR+1
	lda #$03
	sta WRITE_LEN
	jsr WRITEMSG_RAW

CLRMSGAREA_DATA:
	.byte $19,$16,$1d

;---------------------------------------------------------
; TODO: Still Stubs
;---------------------------------------------------------
TABV:	; Set BASL from Accumulator
CLREOP:	; Clear to end of screen
CLREOL:	; Clear to end of line
WAIT:	; Monitor delay: # cycles = (5*A*A + 27*A + 26)/2
RDKEY:	; Character input
NXTCHAR:; Line input
PRBYTE:	; Print Byte routine (HEX value)

rts