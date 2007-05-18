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
.global PMSG17, PMSG18, PMSG19, PMSG20, PMSG21, PMSG22, PMSG23, PMSG24
.global PMSG25, PMSG26, PMSG27, PMSG28, PMSG29, PMSG30, PMSG34, PMSG35
.global MNONAME, MIOERR, MNODISK, PMUTHBAD, PMPREFIX, PMINSERTDISK

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

	ldy #PMLOGO1	; Main title - Line 1
	jsr SHOWMSG

    	lda #$0d
	sta CH
	ldy #PMLOGO2	; Main title - line 2
	jsr SHOWMSG

    	lda #$0d
	sta CH
	ldy #PMLOGO3	; Main title - line 3
	jsr SHOWMSG

    	lda #$0d
	sta CH
	ldy #PMLOGO4	; Main title - line 4
	jsr SHOWMSG

    	lda #$0d
	sta CH
	ldy #PMLOGO5	; Main title - line 5
	jsr SHOWMSG

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
	lda CAPBLKS,X
	sta PRTPTR
	lda CAPBLKS+1,X
	sta PRTPTR+1
	jsr PRTNUMSP

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
	sta PRTPTR
	lda NUMBLKS+1
	sta PRTPTR+1
	jsr PRTNUM

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
	lda #$00
	sta CH
	lda #$16
	jsr TABV
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
MSGEND:	rts


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
	cmp PHMMAX
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
; PRTNUM
;
; Prints a right-justified, zero-padded 5-digit number from
; a pointer in PRTPTR/PRTPTR+1 (lo/hi)
;---------------------------------------------------------
PRTNUMSP:		; Entry: assumes printing 5 digits long, space-padded
	lda #CHR_SP
	sta PADCHR
	jmp PRTIT
PRTNUMB:		; Entry: assumes printing a single byte, space-padded, three spaces wide
	lda #CHR_SP
	sta PADCHR
	jmp ByteEntry
PRTNUM:
	lda #CHR_0
	sta PADCHR
PRTIT:
	lda PRTPTR+1
	cmp #$27
	bcs PRTN1
	jmp OXXXX	; Number is less than $2700
PRTN1:	bne PRTNUM1	; Number is > $2700
	lda PRTPTR
	cmp #$10
	bcs PRTN2
	jmp OXXXX	; Number is less than $2710
PRTN2:	jmp PRTNUM1	; Number is >= $2710

OXXXX:	lda PADCHR
	jsr COUT1
	lda PRTPTR+1
	cmp #$03
	bcs PRTN3
	jmp OOXXX	; Number is less than $0300
PRTN3:	bne PRTN4	; Number is >= $0300
	lda PRTPTR
	cmp #$E8
	bcs PRTN4
	jmp OOXXX	; Number is less than $03e8
PRTN4:	jmp PRTNUM1	; Number is >= $03e8

OOXXX:	lda PADCHR
	jsr COUT1
ByteEntry:
	lda PRTPTR+1
	cmp #$00
	bcs PRTN5
	jmp OOOXX	; Number is less than $0064
PRTN5:	bne PRTNUM1	; Number is >= $0064
	lda PRTPTR
	cmp #$64
	bcs PRTNUM1

OOOXX:	lda PADCHR
	jsr COUT1
	lda PRTPTR
	cmp #$0a
	bcs PRTN7
	jmp OOOOX	; Number is less than $000a
PRTN7:	jmp PRTNUM1	; Number is >= $000a

OOOOX:	lda PADCHR
	jsr COUT1

PRTNUM1:
	ldx PRTPTR	; LO
	lda PRTPTR+1	; HI
	jsr PRDEC

	rts

PADCHR:	.byte CHR_0
PRTPTR:	.byte $00,$00

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
	.addr MSG01,MSG02,MSG03,MSG04,MSG05,MSG06,MSG07,MSG08
	.addr MSG09,MSG10,MSG11,MSG12,MSG13,MSG14,MSG15,MSG16
	.addr MSG17,MSGSOU,MSGDST,MSG19,MSG20,MSG21,MSG22,MSG23,MSG24
	.addr MSG25,MSG26,MSG27,MSG28,MSG28a,MSG29,MSG30,MNONAME,MIOERR
	.addr MNODISK,MSG34,MSG35
	.addr MLOGO1,MLOGO2,MLOGO3,MLOGO4,MLOGO5,MWAIT,MCDIR,MFORC,MFEX
	.addr MUTHBAD, MPREFIX, MINSERTDISK
	.addr MNULL

MSG01:	ascz "0.2.5"
MSG02:	asccr "(S)END (R)ECEIVE (D)IR (B)ATCH (C)D"
	.byte $8d,$00
MSG03:	ascz "(V)OLUMES CONFI(G) (?)ABOUT (Q)UIT:"
MSG04:	.byte $8d
	asccr "GOODBYE - THANKS FOR USING ADTPRO!"
	.byte $8d,$00
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
	asc " BY PAUL GUERTIN, MARK PERCIVAL, JOSEPH "
	asc "   OSWALD, KNUT ROLL-LUND AND OTHERS.   "
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
MSG26:	ascz "COMMS DEVICE"
MSG27:	ascz "BAUD RATE"
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
MNULL:	.byte $00

;---------------------------------------------------------
; Message equates
;---------------------------------------------------------

PMSG01	= $00
PMSG02	= $02
PMSG03	= $04
PMSG04	= $06
PMSG05	= $08
PMSG06	= $0a
PMSG07	= $0c
PMSG08	= $0e
PMSG09	= $10
PMSG10	= $12
PMSG11	= $14
PMSG12	= $16
PMSG13	= $18
PMSG14	= $1a
PMSG15	= $1c
PMSG16	= $1e
PMSG17	= $20
PMSGSOU	= $22
PMSGDST	= $24
PMSG19	= $26
PMSG20	= $28
PMSG21	= $2a
PMSG22	= $2c
PMSG23	= $2e
PMSG24	= $30
PMSG25	= $32
PMSG26	= $34
PMSG27	= $36
PMSG28	= $38
PMSG28a	= $3a
PMSG29	= $3c
PMSG30	= $3e
PMNONAME	= $40
PMIOERR	= $42
PMNODISK	= $44
PMSG34	= $46
PMSG35	= $48
PMLOGO1	= $4a
PMLOGO2	= $4c
PMLOGO3	= $4e
PMLOGO4	= $50
PMLOGO5	= $52
PMWAIT	= $54
PMCDIR	= $56
PMFORC	= $58
PMFEX	= $5a
PMUTHBAD	= $5c
PMPREFIX	= $5e
PMINSERTDISK	= $60
PMNULL	= $62
