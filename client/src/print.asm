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

.global PMSG01, PMSG02, PMSG03, PMSG05, PMSG06, PMSG07, PMSG08
.global PMSG09, PMSG10, PMSG11, PMSG12, PMSG13, PMSG14, PMSG15, PMSG16
.global PMSG17, PMSG18, PMSG19, PMSG20, PMSG21, PMSG22, PMSG23, PMSG24
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
	jsr SHOWMSG
	inc ZP
	inc ZP		; Get next logo message
	lda ZP
	cmp #<PMLOGO5+2	; Stop at MLOGO5 message
	bne LogoLoop

	jsr CROUT
    	lda #$12
	sta CH
	ldy #PMSG01	; Version number
	jsr SHOWMSG
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
	jsr SHOWMSG	; Y holds the top line message number

	lda #$07	; Column
	sta CH
	lda #$02	; Row
	jsr TABV
	ldy #PMSG19	; 'VOLUMES CURRENTLY ON-LINE:'
	jsr SHOWMSG

	lda #H_SL	; "Slot" starting column
	sta CH
	lda #$03	; Row
	jsr TABV
	ldy #PMSG20	; 'SLOT  DRIVE  VOLUME NAME      BLOCKS'
	jsr SHOWMSG

	lda #H_SL	; "Slot" starting column
	sta CH
	lda #$04	; Row
	jsr TABV
	ldy #PMSG21	; '----  -----  ---------------  ------'
	jsr SHOWMSG
VOLINSTRUCT:
	lda #$00	; Column
	sta CH
	lda #$14	; Row
	jsr TABV
	ldy #PMSG22	; 'CHANGE VOLUME/SLOT/DRIVE WITH ARROW KEYS'
	jsr SHOWMSG

	lda #$04	; Column
	sta CH
	lda #$15	; Row
	jsr TABV
	ldy #PMSG23	; 'SELECT WITH RETURN, ESC CANCELS'
	jsr SHOWMSG

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
	jsr SHOWMSG
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
	lda #$df
	ldx #$28
HLINE1:	jsr COUT1
	dex
	bne HLINE1
	rts


;---------------------------------------------------------
; SHOWMSG - SHOW NULL-TERMINATED MESSAGE #Y AT current
; cursor location.
; Call SHOWM1 to clear/print at message area.
;---------------------------------------------------------
SHOWM1:
	sty SLOWY
	lda #$16
	jsr TABV
SHOWM2:
	lda #$00	; TODO: may need to swap back before setting TABV
	sta CH
	jsr CLREOP
	ldy SLOWY

SHOWMSG:
	lda MSGTBL,Y
	sta UTILPTR
	lda MSGTBL+1,Y
	sta UTILPTR+1

	ldy #$00
MSGLOOP:
	lda (UTILPTR),Y
	beq MSGEND
	jsr COUT1
	iny
	bne MSGLOOP
MSGEND:
	rts

;---------------------------------------------------------
; WRITEMSG - Print null-terminated message number in Y
;---------------------------------------------------------
WRITEMSGAREA:
	sty SLOWY
	lda #$16
	jsr TABV
	ldy SLOWY
WRITEMSGLEFT:
	sty SLOWY
	lda #$00
	sta CH
	jsr CLREOP
	ldy SLOWY
WRITEMSG:
	lda MSGTBL,Y
	sta UTILPTR
	lda MSGTBL+1,Y
	sta UTILPTR+1
WRITEMSGRAW:
	ldy #$00
:
	lda (UTILPTR),Y
	beq WRITEMSGEND
	jsr COUT1
	iny
	bne :-
WRITEMSGEND:
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
	jmp MSGLOOP	; Call the regular message printer
	
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
;   By Jan Eugenides and Bob S-C
;
;      Call with A, X, and Y as follows:
;          (A) = low-byte of number to be printed
;          (X) = high byte of number
;          (Y) = fill character (or 00 if no fill)
;--------------------------------
PRD:	STX NUM+1    ;Store high byte of number
	STY FILL     ;Store fill character
	LDX #3       ;FOR X = 3 TO 0
	STX FLAG     ;Clear bit 7 in leading-zero flag
@1:	LDY #CHR_0     ;Start with digit = ASCII 0
@2:	STA NUM      ;Compare number to power of ten
	CMP TENTBL,X      ;10^(X+1) ... lo-byte
	LDA NUM+1
	SBC TENTBH,X      ;10^(X+1) ... hi-byte
	BCC @3       ;Remainder is smaller than 10^(X+1)
	STA NUM+1    ;Store remainder hi-byte
	LDA NUM      ;Get remainder lo-byte
	SBC TENTBL,X
	INY          ;Increment ASCII digit
	BNE @2      ; ...always
;---Print a digit----------------
@3:	TYA          ;digit in ASCII
	CMP #CHR_0     ;Is it a zero?
	BEQ @4      ; ...yes, might be leading zero
	STA FLAG     ;...no, so clear leading-zero flag
@4:	BIT FLAG     ;If this is leading-zero, will be +
	BMI @5      ; ...not a leading zero
	LDA FILL     ;...leading zero, so use fill-char
	BEQ @6      ; ...Oops, no fill-char
@5:	JSR COUT     ;Print the digit or fill-char
@6:	LDA NUM      ;Get lo-byte of remainder
	DEX          ;Next X
	BPL @1      ; Go get next digit
	ORA #CHR_0     ;Change remainder to ASCII
	JMP COUT     ;Print Unit's digit & RTS
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
	.addr MSG01,MSG02,MSG03,MSG05,MSG06,MSG07,MSG08
	.addr MSG09,MSG10,MSG11,MSG12,MSG13,MSG14,MSG15,MSG16
	.addr MSG17,MSGSOU,MSGDST,MSG19,MSG20,MSG21,MSG22,MSG23,MSG24
	.addr MSG25,MSG28,MSG28a,MSG29,MSG30,MNONAME,MIOERR
	.addr MNODISK,MSG34,MSG35
	.addr MLOGO1,MLOGO2,MLOGO3,MLOGO4,MLOGO5,MWAIT,MCDIR,MFORC,MFEX
	.addr MUTHBAD, MPREFIX, MINSERTDISK, MFORMAT, MANALYSIS, MNOCREATE
	.addr MVolName, MBlank, MTheOld, MUnRecog, MDead
	.addr MProtect, MNoDisk, MNuther, MUnitNone
	.addr MNULL

MSG01:	ascz "v.r.m"
MSG02:	asccr "(S)END (R)ECEIVE (D)IR (B)ATCH (C)D"
	.byte $8d,$00
MSG03:	ascz "(V)OLUMES CONFI(G) (F)ORMAT (?) (Q)UIT:"
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
MSG22:	ascz "CHANGE VOLUME/SLOT/DRIVE WITH ARROW KEYS"
MSG23:	ascz "SELECT WITH RETURN, ESC CANCELS"
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
MNULL:	.byte $00

;---------------------------------------------------------
; Message equates
;---------------------------------------------------------

PMSG01	= $00
PMSG02	= $02
PMSG03	= $04
PMSG05	= $06
PMSG06	= $08
PMSG07	= $0a
PMSG08	= $0c
PMSG09	= $0e
PMSG10	= $10
PMSG11	= $12
PMSG12	= $14
PMSG13	= $16
PMSG14	= $18
PMSG15	= $1a
PMSG16	= $1c
PMSG17	= $1e
PMSGSOU	= $20
PMSGDST	= $22
PMSG19	= $24
PMSG20	= $26
PMSG21	= $28
PMSG22	= $2a
PMSG23	= $2c
PMSG24	= $2e
PMSG25	= $30
PMSG28	= $32
PMSG28a	= $34
PMSG29	= $36
PMSG30	= $38
PMNONAME	= $3a
PMIOERR	= $3c
PMNODISK	= $3e
PMSG34	= $40
PMSG35	= $42
PMLOGO1	= $44
PMLOGO2	= $46
PMLOGO3	= $48
PMLOGO4	= $4a
PMLOGO5	= $4c
PMWAIT	= $4e
PMCDIR	= $50
PMFORC	= $52
PMFEX	= $54
PMUTHBAD	= $56
PMPREFIX	= $58
PMINSERTDISK	= $5a
PMFORMAT	= $5c
PMANALYSIS	= $5e
PMNOCREATE	= $60
PMVolName	= $62
PMBlank		= $64
PMTheOld		= $66
PMUnRecog	= $68
PMDead		= $6a
PMProtect	= $6c
PMNoDisk		= $6e
PMNuther		= $70
PMUnitNone	= $72
PMNULL	= $74
