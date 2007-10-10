;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006, 2007 by David Schmidt
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
; SHOWLOGO
; 
; Prints the logo on the screen
;---------------------------------------------------------
SHOWLOGO:
	lda #$0d
	sta CH
	lda #$03
	jsr TABV

	lda #<PMLOGO1	; Start with MLOGO1 message
	sta ZP
    	ldx #$0d	; Get ready to HTAB $0d chars over
LogoLoop:
	stx CH		; Tab over to starting position
	tay
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	lda ZP
	cmp #<PMLOGO5+2	; Stop at MLOGO5 message
	bne LogoLoop

	jsr CROUT
    	lda #$12
	sta CH
	ldy #PMSG01	; Version number
	jsr WRITEMSG
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
	ldy #$00
WRITEMSGLOOP:
	lda (UTILPTR),Y
	beq WRITEMSGEND
	jsr COUT1
	iny
	bne WRITEMSGLOOP
WRITEMSGEND:
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

;---------------------------------------------------------
; Client messages
;---------------------------------------------------------

MSGTBL:
	.addr MSG01,MSG02,MSG03,MSG04,MSG05,MSG06,MSG07,MSG08
	.addr MSG09,MSG10,MSG11,MSG12,MSG13,MSG14,MSG15,MSG16
	.addr MSG17,MSGSOU,MSGDST,MSG19,MSG20,MSG21,MSG22,MSG23,MSG23a,MSG24
	.addr MSG25,MSG28,MSG28a,MSG29,MSG30,MNONAME,MIOERR
	.addr MNODISK,MSG34,MSG35
	.addr MLOGO1,MLOGO2,MLOGO3,MLOGO4,MLOGO5,MWAIT,MCDIR,MFORC,MFEX
	.addr MUTHBAD, MPREFIX, MINSERTDISK, MFORMAT, MANALYSIS, MNOCREATE
	.addr MVolName, MBlank, MTheOld, MUnRecog, MDead
	.addr MProtect, MNoDisk, MNuther, MUnitNone, MNIBTOP
	.addr MNULL

MSG01:	ascz "v.r.m"
MSG02:	asccr "(S)END (R)ECEIVE (D)IR (B)ATCH (C)D"
	.byte $8d,$00
MSG03:	ascz "(V)OLUMES CONFI(G) (F)ORMAT (?) (Q)UIT:"
MSG04:	ascz "(S)TANDARD OR (N)IBBLE?"
MSG05:	ascz "RECEIVING"
MSG06:	ascz "  SENDING"
MSG07:	ascz "  READING"
MSG08:	ascz "  WRITING"
MSG09:	ascz "BLOCK 00000 OF"
MSG10:	.byte $20,$20,$20,$A0,$A0,$20,$20,$20
	.byte $A0,$A0,$20,$A0,$A0,$A0,$20,$8D
	.byte $00
MSG11:	.byte $20,$A0,$A0,$20,$A0,$20,$A0,$A0
	.byte $20,$A0,$A0,$20,$A0,$20,$8D
	.byte $00
MSG12:	.byte $20,$A0,$A0,$20,$A0,$20,$A0,$A0
	.byte $20,$A0,$A0,$A0,$20,$8D
	.byte $00
MSG13:	ascz "FILENAME: "
MSG14:	ascz "COMPLETE"
MSG15:	ascz " - WITH ERRORS"
MSG16:	ascz "PRESS A KEY TO CONTINUE..."
MSG17:	asc "ADTPRO BY DAVID SCHMIDT. BASED ON WORKS "
	asc "    BY PAUL GUERTIN AND MANY OTHERS.    "
        ascz "  VISIT: HTTP://ADTPRO.SOURCEFORGE.NET "
MSGSOU:	ascz "   SELECT SOURCE VOLUME"
MSGDST:	ascz "SELECT DESTINATION VOLUME"
MSG19:	ascz "VOLUMES CURRENTLY ON-LINE:"
MSG20:	ascz "SLOT  DRIVE  VOLUME NAME      BLOCKS"
MSG21:	ascz "----  -----  ---------------  ------"
MSG22:	ascz "CHANGE SELECTION WITH ARROW KEYS&RETURN "
MSG23:	ascz " (R) TO RE-SCAN DRIVES, ESC TO CANCEL"
MSG23a:	ascz "SELECT WITH RETURN, ESC CANCELS"
MSG24:	ascz "CONFIGURE ADTPRO PARAMETERS"
MSG25:	ascz "CHANGE PARAMETERS WITH ARROW KEYS"
; Note: Messages MSG26 and MSG27 are set in 
; the serial and ethernet config files.
MSG28:	ascz "ENABLE SOUND"
MSG28a:	ascz "SAVE CONFIG"
MSG29:	ascz "ANY KEY TO CONTINUE, ESC TO STOP: "
MSG30:	ascz "END OF DIRECTORY.  HIT A KEY: "
MNONAME:	ascz "<NO NAME>"
MIOERR:	ascz "<I/O ERROR>"
MNODISK:	ascz "<NO DISK>"
MSG34:	ascz "FILE EXISTS"
MSG35:	asccr "IMAGE/DRIVE SIZE MISMATCH!"
	.byte $00
MLOGO1:	.byte $a0,$20,$20,$a0,$a0,$20,$20,$20,$a0,$a0,$20,$20,$20,$20,$20,$8d,$00
MLOGO2:	.byte $20,$a0,$a0,$20,$a0,$20,$a0,$a0,$20,$a0,$a0,$a0,$20,$8d,$00
MLOGO3:	.byte $20,$20,$20,$20,$a0,$20,$a0,$a0,$20,$a0,$a0,$a0,$20,$8d,$00
MLOGO4:	.byte $20,$a0,$a0,$20,$a0,$20,$a0,$a0,$20,$a0,$a0,$a0,$20,$8d,$00
MLOGO5:	.byte $20,$a0,$a0,$20,$a0,$20,$20,$20,$a0,$a0,$a0,$a0,$20,$a0
	asc "PRO"
	.byte $8d,$00
MWAIT:	ascz "WAITING FOR HOST REPLY, ESC CANCELS"
MCDIR:	ascz "DIRECTORY: "
MFORC:	ascz "COPY IMAGE DATA ANYWAY? (Y/N):"
MFEX:	ascz "FILE ALREADY EXISTS AT HOST."
MUTHBAD:	ascz "UTHERNET INIT FAILED; PLEASE RUN CONFIG."
MPREFIX:	ascz "FILENAME PREFIX: "
MINSERTDISK:	ascz "INSERT THE NEXT DISK TO SEND."
MFORMAT:	ascz " CHOOSE VOLUME TO FORMAT"
MANALYSIS:	ascz "HOST UNABLE TO ANALYZE TRACK."
MNOCREATE:	ascz "UNABLE TO CREATE CONFIG FILE."
; Messages from formatter routine
MVolName:
	asc "VOLUME NAME: /"
MBlank:	asc "BLANK"
	ascz "__________"
MTheOld:	ascz "READY TO FORMAT? (Y/N):"
MUnRecog:
	ascz "UNRECOGNIZED ERROR = "
MDead:	ascz "CHECK DISK OR DRIVE DOOR!"
MProtect:
	ascz "DISK IS WRITE PROTECTED!"
MNoDisk:	ascz "NO DISK IN THE DRIVE!"
MNuther:	ascz "FORMAT ANOTHER? (Y/N):"
MUnitNone:
	ascz "NO UNIT IN THAT SLOT AND DRIVE"
MNIBTOP:
	inv "  00000000000000001111111111111111222  "
	.byte $8D
	inv "  0123456789ABCDEF0123456789ABCDEF012  "
	.byte $8D, $00

MNULL:	.byte $00

;---------------------------------------------------------
; Message equates
;---------------------------------------------------------

PMSG01		= $00
PMSG02		= $02
PMSG03		= $04
PMSG04		= $06
PMSG05		= $08
PMSG06		= $0a
PMSG07		= $0c
PMSG08		= $0e
PMSG09		= $10
PMSG10		= $12
PMSG11		= $14
PMSG12		= $16
PMSG13		= $18
PMSG14		= $1a
PMSG15		= $1c
PMSG16		= $1e
PMSG17		= $20
PMSGSOU		= $22
PMSGDST		= $24
PMSG19		= $26
PMSG20		= $28
PMSG21		= $2a
PMSG22		= $2c
PMSG23		= $2e
PMSG23a		= $30
PMSG24		= $32
PMSG25		= $34
PMSG28		= $36
PMSG28a		= $38
PMSG29		= $3a
PMSG30		= $3c
PMNONAME	= $3e
PMIOERR		= $40
PMNODISK	= $42
PMSG34		= $44
PMSG35		= $46
PMLOGO1		= $48
PMLOGO2		= $4a
PMLOGO3		= $4c
PMLOGO4		= $4e
PMLOGO5		= $50
PMWAIT		= $52
PMCDIR		= $54
PMFORC		= $56
PMFEX		= $58
PMUTHBAD	= $5a
PMPREFIX	= $5c
PMINSERTDISK	= $5e
PMFORMAT	= $60
PMANALYSIS	= $62
PMNOCREATE	= $64
PMVolName	= $66
PMBlank		= $68
PMTheOld	= $6a
PMUnRecog	= $6c
PMDead		= $6e
PMProtect	= $70
PMNoDisk	= $72
PMNuther	= $74
PMUnitNone	= $76
PMNIBTOP	= $78
PMNULL		= $7a
