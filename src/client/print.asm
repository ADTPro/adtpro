;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2014 by David Schmidt
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

.global PMSG09

;---------------------------------------------------------
; PREPPRG
; 
; Sets up the progress screen
;
; Input:
;   NUMBLKS
;   NUMBLKS+1 contain the total capacity of the volume
;---------------------------------------------------------
PREPPRG:
	stx SLOWX	; Preserve X
	jsr HOME
	jsr SHOWLOGO
	ldx #H_BLK	; Column
	ldy #V_MSG	; Row
	jsr GOTOXY
	ldy #PMSG09
	jsr WRITEMSG
	lda #CHR_SP
	jsr COUT	; Space over one character

	lda NUMBLKS
	ldx NUMBLKS+1
	ldy #CHR_0
	jsr PRD

	ldx #$00	; Column
	ldy #V_BUF-2	; Row
	jsr GOTOXY
	jsr HLINE	; Print out a row of underlines
	lda #V_BUF+1	; Row
	jsr TABV
	jsr HLINE
	ldx SLOWX	; Restore X
	rts

;---------------------------------------------------------
; ToDecimal
; Prints accumulator as a decimal number
; The number is right/space justified to 3 digits
;---------------------------------------------------------
ToDecimal:
	ldy #$00
	sty DigitYet
	ldy #2
TD1:	ldx #_'0'
TD2:	cmp DECTBL,Y  
	bcc TD3		; Digit finished
	sbc DECTBL,Y  
	inx              
	bne TD2		; Branch ...always
TD3:	pha		; Save remainder
	txa
	cmp #_'0'
	bne :+
	ldx DigitYet
	bne :+
	cpy #$00
	beq :+
	lda #_' '
	jmp TD4
:	inc DigitYet	; Print out a digit
TD4:	jsr COUT
	pla		; Get remainder
	dey
	bpl TD1
	rts    

DECTBL:	.byte	1,10,100           
DigitYet:
	.byte 0

;--------------------------------
;   Decimal printer by Jan Eugenides and Bob S-C
;
;      Call with A, X, and Y as follows:
;          (A) = low-byte of number to be printed
;          (X) = high byte of number
;          (Y) = fill character (or 00 if no fill)
;--------------------------------
PRD:	stx NUM+1	; Store high byte of number
	STY FILL	; Store fill character
	LDX #3		; FOR X = 3 TO 0
	stx FLAG	; Clear bit 7 in leading-zero flag
@1:	LDY #CHR_0	; Start with digit = ASCII 0
@2:	STA NUM		; Compare number to power of ten
	CMP TENTBL,X	; 10^(X+1) ... lo-byte
	LDA NUM+1
	SBC TENTBH,X	; 10^(X+1) ... hi-byte
	BCC @3		; Remainder is smaller than 10^(X+1)
	STA NUM+1	; Store remainder hi-byte
	LDA NUM		; Get remainder lo-byte
	SBC TENTBL,X
	INY		; Increment ASCII digit
	BNE @2		;  ...always
;---Print a digit----------------
@3:	TYA		; Digit in ASCII
	CMP #CHR_0	; Is it a zero?
	BEQ @4		;  ...yes, might be leading zero
	STA FLAG	;  ...no, so clear leading-zero flag
@4:	BIT FLAG	; If this is leading-zero, will be +
	BMI @5		;  ...not a leading zero
	LDA FILL	;  ...leading zero, so use fill-char
	BEQ @6		;  ...Oops, no fill-char
@5:	JSR COUT	; Print the digit or fill-char
@6:	LDA NUM		; Get lo-byte of remainder
	DEX		; Next X
	BPL @1		; Go get next digit
	ORA #CHR_0	; Change remainder to ASCII
	JMP COUT	; Print Unit's digit & RTS
;--------------------------------
TENTBL:	.byte <10,<100,<1000,<10000
TENTBH:	.byte >10,>100,>1000,>10000
;--------------------------------
FLAG:	.byte $00
FILL:	.byte $00
NUM:	.byte $00, $00

;---------------------------------------------------------
; CHROVER - Write new contents without advancing cursor
;---------------------------------------------------------
CHROVER:
	ldy CH
	sta (BASL),Y
	rts
