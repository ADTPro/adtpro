;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2008 by David Schmidt
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

.global PMSG01, PMSG02, PMSG03, PMSG04, PMSG05, PMSG06, PMSG07, PMSG08
.global PMSG09, PMSG10, PMSG11, PMSG12, PMSG13, PMSG14, PMSG15, PMSG16
.global PMSG17, PMSG18, PMSG19, PMSG20, PMSG21, PMSG22, PMSG23, PMSG23a, PMSG24
.global PMSG25, PMSG28, PMSG29, PMSG30, PMSG34, PMSG35
.global MNONAME, MIOERR, MNODISK, PMUTHBAD, PMPREFIX, PMINSERTDISK, PMFORMAT
.global PMANALYSIS

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
	jsr DRAWBDR
	jsr ONLINE
	rts

;---------------------------------------------------------
; PRT1VOL
;
; Inputs:
;   X register holds the index to the device table
;   Y register is preserved
; Prints one volume's worth of information
; Called from ONLINE
;---------------------------------------------------------
PRT1VOL:
	tya
	pha
	stx SLOWX

	lda #H_SL	; "Slot" starting column
	sta CH

	lda DEVICES,X
	and #$70	; Mask off length nybble
	lsr
	lsr
	lsr
	lsr		; Acc now holds the slot number
	clc
	adc #$B0
	sta PRTSVA
	jsr COUT1

	lda #H_DR	; "Drive" starting column
	sta CH
	lda DEVICES,X
	and #$80
	cmp #$80
	beq PRDR2
	lda #$B1
	jmp PROUT
PRDR2:	lda #$B2
PROUT:	jsr COUT1

	lda #H_VO	; "Volume" starting column
	sta CH
	lda DEVICES,X
	and #$0f
	sta PRTSVA
	beq PRVODONE
	ldy #$00
PRLOOP:
	lda DEVICES+1,X
	ora #$80
	jsr COUT1
	inx
	iny
	cpy PRTSVA
	bne PRLOOP

	lda #H_SZ	; "Size" starting column
	sta CH

	lda SLOWX	; Get a copy of original X into Acc

	beq PRnum
	lsr
	lsr
	lsr
PRnum:	tax
	lda CAPBLKS+1,X
	sta FILL
	lda CAPBLKS,X
	ldx FILL
	ldy #CHR_SP
	jsr PRD

PRVODONE:
	jsr CROUT

	ldx SLOWX
	pla
	tay
	rts

PRTSVA:	.byte $00
POFF:	.byte $00

;---------------------------------------------------------
; DRAWBDR
; 
; Draws the volume picker decorative border
; Y holds the top line message number
;---------------------------------------------------------
DRAWBDR:
	lda #$07
	sta CH
	lda #$00
	jsr TABV
	jsr WRITEMSG	; Y holds the top line message number

	lda #$07	; Column
	sta CH
	lda #$02	; Row
	jsr TABV
	ldy #PMSG19	; 'VOLUMES CURRENTLY ON-LINE:'
	jsr WRITEMSG

	lda #H_SL	; "Slot" starting column
	sta CH
	lda #$03	; Row
	jsr TABV
	ldy #PMSG20	; 'SLOT  DRIVE  VOLUME NAME      BLOCKS'
	jsr WRITEMSG

	lda #H_SL	; "Slot" starting column
	sta CH
	lda #$04	; Row
	jsr TABV
	ldy #PMSG21	; '----  -----  ---------------  ------'
	jsr WRITEMSG
VOLINSTRUCT:
	lda #$14	; Row
	jsr TABV
	ldy #PMSG22	; 'CHANGE VOLUME/SLOT/DRIVE WITH ARROW KEYS'
	jsr WRITEMSGLEFT

	lda #$15	; Row
	jsr TABV
	ldy #PMSG23	; 'SELECT WITH RETURN, ESC CANCELS'
	jsr WRITEMSGLEFT

	lda #$05	; starting row for slot/drive entries
	jsr TABV
	rts

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
	lda #H_BLK	; Column
	sta CH
	lda #V_MSG	; Row
	jsr TABV
	ldy #PMSG09
	jsr WRITEMSG
	inc CH		; Space over one character

	lda NUMBLKS
	ldx NUMBLKS+1
	ldy #CHR_0
	jsr PRD

	lda #$00	; Column
	sta CH
	lda #V_BUF-2	; Row
	jsr TABV
	jsr HLINE	; Print out a row of underlines
	lda #V_BUF+1	; Row
	jsr TABV
	jsr HLINE
	ldx SLOWX	; Restore X
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
TD4:	jsr COUT1
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
; nibtitle - show title screen for nibble disk transfer
;---------------------------------------------------------
nibtitle:
	jsr HOME
	jsr SHOWLOGO
	jsr CROUT
	jsr CROUT
	ldx #$27
	jsr HLINEX
	jsr CROUT
	ldy #PMNIBTOP
	jsr WRITEMSG
	lda #$0e		; show one block left and right
	sta CV			; on line $0e
	jsr VTAB
	lda #_I' '		; inverse space char
	ldy #38			; at end of line
	sta (BASL),y
	ldy #0			; at start of line
	sta (BASL),y
	lda #_I'>'		; inverse character!
	iny			; next position in line
	sta (BASL),y
	lda #_I'<'		; inverse character!
	ldy #37			; one-but-last position in line
	sta (BASL),y
	lda SendType		; check to see if we need to
	cmp #CHR_H		; display halftrack line
	bne nibtdone
	lda #$0f		; move one line down
	sta CV
	jsr VTAB
	lda #_I'.'		; put an inverse . on screen
	ldy #0			;  at horiz pos 0
	sta (BASL),y
	lda #'5'		; and now put a 5 so we see
	ldy #1			;  .5 which means halftrk
	sta (BASL),y
	lda #_I' '		; put 2 inverse spaces at the end
	ldy #37
	sta (BASL),y
	iny
	sta (BASL),y

nibtdone:
	rts


;---------------------------------------------------------
; Host messages
;---------------------------------------------------------

HMSGTBL:	.addr HMGBG,HMFIL,HMFMT,HMDIR,HMTIMEOUT

HMGBG:	asc "GARBAGE RECEIVED FROM HOST"
	.byte $8d,$00
HMFIL:	asc "UNABLE TO OPEN FILE"
	.byte $8d,$00
HMFMT:	asc "FILE FORMAT NOT RECOGNIZED"
	.byte $8d,$00
HMDIR:	asc "UNABLE TO CHANGE DIRECTORY"
	.byte $8d,$00
HMTIMEOUT:
	asc "HOST TIMEOUT"
	.byte $8d,$00

;---------------------------------------------------------
; Host message equates
;---------------------------------------------------------

PHMGBG	= $00
PHMFIL	= $02
PHMFMT	= $04
PHMDIR	= $06
PHMTIMEOUT	= $08
PHMMAX	= $0a		; This must be two greater than the largest host message
