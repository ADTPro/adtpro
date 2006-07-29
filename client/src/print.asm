*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

*---------------------------------------------------------
* SHOWLOGO
* 
* Prints the logo on the screen
*---------------------------------------------------------
SHOWLOGO
	lda #$0d
	sta <CH
	lda #$03
	jsr TABV

	ldy #PMLOGO1	Main title - Line 1
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMLOGO2	Main title - line 2
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMLOGO3	Main title - line 3
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMLOGO4	Main title - line 4
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMLOGO5	Main title - line 5
	jsr SHOWMSG

	jsr CROUT
    	lda #$12
	sta <CH
	ldy #PMSG01	Version number
	jsr SHOWMSG
	rts

*---------------------------------------------------------
* PRINTVOL
* 
* Prints on-line volume information 
* Y holds pointer to top line message
*---------------------------------------------------------
PRINTVOL
	tya
	pha
	jsr HOME	Clear screen
	pla
	tay
	jsr DRAWBDR
	jsr ONLINE
	rts

*---------------------------------------------------------
* PRT1VOL
*
* Inputs:
*   X register holds the index to the device table
*   Y register is preserved
* Prints one volume's worth of information
* Called from ONLINE
*---------------------------------------------------------
PRT1VOL
	tya
	pha
	stx SLOWX

	lda #H_SL	"Slot" starting column
	sta <CH

	lda DEVICES,X
	and #$70	Mask off length nybble
	lsr
	lsr
	lsr
	lsr		Acc now holds the slot number
	clc
	adc #$B0
	sta PRTSVA
	jsr COUT1

	lda #H_DR	"Drive" starting column
	sta <CH
	lda DEVICES,X
	and #$80
	cmp #$80
	beq PR.DR2
	lda #$B1
	jmp PR.OUT
PR.DR2	lda #$B2
PR.OUT	jsr COUT1

	lda #H_VO	"Volume" starting column
	sta <CH
	lda DEVICES,X
	and #$0f
	sta PRTSVA
	beq PR.VO.DONE
	ldy #$00
PR.LOOP	lda DEVICES+1,X
	ora #$80
	jsr COUT1
	inx
	iny
	cpy PRTSVA
	bne PR.LOOP

	lda #H_SZ	"Size" starting column
	sta <CH

	lda SLOWX	Get a copy of original X into Acc

	beq PR.num
	lsr
	lsr
	lsr
PR.num	tax
	lda CAPBLKS,X
	sta PRTPTR
	lda CAPBLKS+1,X
	sta PRTPTR+1
	jsr PRTNUMB

PR.vo.DONE
	jsr crOUT

	ldx SLOWX
	pla
	tay
	rts

PRTSVA	.db $00
P.OFF	.db $00

*---------------------------------------------------------
* DRAWBDR
* 
* Draws the volume picker decorative border
*---------------------------------------------------------
DRAWBDR
	lda #$07
	sta <CH
	lda #$00
	jsr TABV
	jsr SHOWMSG

	lda #$07	Column
	sta <CH
	lda #$02	Row
	JSR TABV
	ldy #PMSG19	'VOLUMES CURRENTLY ON-LINE:'
	jsr SHOWMSG

	lda #H_SL	"Slot" starting column
	sta <CH
	lda #$03	Row
	JSR TABV
	ldy #PMSG20	'SLOT  DRIVE  VOLUME NAME      BLOCKS'
	jsr SHOWMSG

	lda #H_SL	"Slot" starting column
	sta <CH
	lda #$04	Row
	JSR TABV
	ldy #PMSG21	'----  -----  ---------------  ------'
	jsr SHOWMSG

	lda #$00	Column
	sta <CH
	lda #$14	Row
	JSR TABV
	ldy #PMSG22	'CHANGE VOLUME/SLOT/DRIVE WITH ARROW KEYS'
	jsr SHOWMSG

	lda #$04	Column
	sta <CH
	lda #$15	Row
	JSR TABV
	ldy #PMSG23	'SELECT WITH RETURN, ESC CANCELS'
	jsr SHOWMSG

	lda #$05	starting row for slot/drive entries
	JSR TABV
	rts

*---------------------------------------------------------
* PREPPRG
* 
* Sets up the progress screen
*
* Input:
*   NUMBLKS
*   NUMBLKS+1 contain the total capacity of the volume
*---------------------------------------------------------
PREPPRG
	stx SLOWX	Preserve X
	jsr HOME
	jsr SHOWLOGO
	lda #H_BLK	Column
	sta <CH
	lda #V_MSG	Row
	JSR TABV
	ldy #PMSG09
	jsr SHOWMSG
	inc <CH		Space over one character

	lda NUMBLKS
	sta PRTPTR
	lda NUMBLKS+1
	sta PRTPTR+1
	jsr PRTNUM

	lda #$00	Column
	sta <CH
	lda #V_BUF-2	Row
	jsr TABV
	jsr HLINE		Print out a row of underlines
	lda #V_BUF+1	Row
	jsr TABV
	jsr HLINE
	ldx SLOWX	Restore X
	rts

*---------------------------------------------------------
* HLINE - Prints a row of underlines at current cursor position
*---------------------------------------------------------
HLINE
	lda #$df
	ldx #$28
HLINE.1	jsr COUT1
	dex
	bne HLINE.1
	rts


*---------------------------------------------------------
* SHOWMSG - SHOW NULL-TERMINATED MESSAGE #Y AT current
* cursor location.
* Call SHOWM1 to clear/print at message area.
*---------------------------------------------------------
SHOWM1
	sty SLOWY
	lda #$00
	sta <CH
	lda #$16
	jsr TABV
	jsr CLREOP
	ldy SLOWY

SHOWMSG
	lda MSGTBL,Y
	sta <UTILPTR
	lda MSGTBL+1,Y
	sta <UTILPTR+1

	ldy #$00
MSGLOOP	lda (UTILPTR),Y
	beq MSGEND
	jsr COUT1
	iny
	bne MSGLOOP
MSGEND	rts


*---------------------------------------------------------
* SHOWHMSG - Show null-terminated host message #Y at current
* cursor location.  We further constrain messages to be
* even and within the host message range.
* Call SHOWHM1 to clear/print at message area.
*---------------------------------------------------------
SHOWHM1
	sty SLOWY
	lda #$00
	sta <CH
	lda #$16
	jsr TABV
	jsr CLREOP
	ldy SLOWY

SHOWHMSG
	tya
	and #$01	If it's odd, it's garbage
	cmp #$01
	beq HGARBAGE
	tya
	clc
	cmp PHMMAX
	bcs HGARBAGE	If it's greater than max, it's garbage
	jmp HMOK
HGARBAGE
	ldy #PHMGBG
HMOK
	lda HMSGTBL,Y
	sta <UTILPTR
	lda HMSGTBL+1,Y
	sta <UTILPTR+1

	ldy #$00
HMSGLOOP
	lda (UTILPTR),Y
	beq HMSGEND
	jsr COUT1
	iny
	bne HMSGLOOP
HMSGEND	rts


*---------------------------------------------------------
* PRTNUM
*
* Prints a right-justified, zero-padded 5-digit number from
* a pointer in PRTPTR/PRTPTR+1 (lo/hi)
*---------------------------------------------------------
PRTNUM
	lda #CHR_0
	sta PADCHR
	jmp PRTIT
PRTNUMB	lda #CHR_SP
	sta PADCHR

PRTIT	lda PRTPTR+1
	cmp #$27
	bcs PRTN.1
	jmp OXXXX	Number is less than $2700
PRTN.1	bne PRTNUM1	Number is > $2700
	lda PRTPTR
	cmp #$10
	bcs PRTN.2
	jmp OXXXX	Number is less than $2710
PRTN.2	jmp PRTNUM1	Number is >= $2710

OXXXX	lda PADCHR
	jsr COUT1
	lda PRTPTR+1
	cmp #$03
	bcs PRTN.3
	jmp OOXXX	Number is less than $0300
PRTN.3	bne PRTN.4	Number is >= $0300
	lda PRTPTR
	cmp #$E8
	bcs PRTN.4
	jmp OOXXX	Number is less than $03e8
PRTN.4	jmp PRTNUM1	Number is >= $03e8

OOXXX	lda PADCHR
	jsr COUT1
	lda PRTPTR+1
	cmp #$00
	bcs PRTN.5
	jmp OOOXX	Number is less than $0064
PRTN.5	bne PRTNUM1	Number is >= $0064
	lda PRTPTR
	cmp #$64
	bcs PRTNUM1

OOOXX	lda PADCHR
	jsr COUT1
	lda PRTPTR
	cmp #$0a
	bcs PRTN.7
	jmp OOOOX	Number is less than $000a
PRTN.7	jmp PRTNUM1	Number is >= $000a

OOOOX	lda PADCHR
	jsr COUT1

PRTNUM1	ldx PRTPTR	LO
	lda PRTPTR+1	HI
	jsr PRDEC

	rts

PADCHR	.db CHR_0
PRTPTR	.db $00,$00

*---------------------------------------------------------
* CHROVER - Write new contents without advancing cursor
*---------------------------------------------------------
CHROVER	ldy <CH
	sta (BASL),Y
	rts

*---------------------------------------------------------
* INVERSE - Invert the characters on the screen
*
* Inputs:
*   A - number of bytes to process
*   X - starting x coordinate
*   Y - starting y coordinate
*---------------------------------------------------------
INVERSE
	clc
	sta INUM
	stx <CH		Set cursor to first position
	txa
	adc INUM
	sta INUM
	tya
	jsr TABV
	ldy <CH
INV.1	lda (BASL),Y
	and #$BF
	eor #$80
	sta (BASL),Y
	iny
	cpy INUM
	bne INV.1
	rts

INUM	.db $00


*---------------------------------------------------------
* Host messages
*---------------------------------------------------------

HMSGTBL
	.da HMGBG,HMFIL,HMFMT,HMDIR

HMGBG	.as -'GARBAGE RECEIVED FROM HOST'
	.db $8d,$00
HMFIL	.as -'UNABLE TO OPEN FILE'
	.db $8d,$00
HMFMT	.as -'FILE FORMAT NOT RECOGNIZED'
	.db $8d,$00
HMDIR	.as -'UNABLE TO CHANGE DIRECTORY'
	.db $8d,$00

*---------------------------------------------------------
* Host message equates
*---------------------------------------------------------

PHMGBG	.eq $00
PHMFIL	.eq $02
PHMFMT	.eq $04
PHMDIR	.eq $06
PHMMAX	.eq $07	This must be one greater than the largest host message

*---------------------------------------------------------
* Client messages
*---------------------------------------------------------

MSGTBL
	.da MSG01,MSG02,MSG03,MSG04,MSG05,MSG06,MSG07,MSG08
	.da MSG09,MSG10,MSG11,MSG12,MSG13,MSG14,MSG15,MSG16
	.da MSG17,MSGSOU,MSGDST,MSG19,MSG20,MSG21,MSG22,MSG23,MSG24
	.da MSG25,MSG26,MSG27,MSG28,MSG28a,MSG29,MSG30,MNONAME,MIOERR
	.da MNODISK,MSG34,MSG35
	.da MLOGO1,MLOGO2,MLOGO3,MLOGO4,MLOGO5,MWAIT,MCDIR,MFORC,MFEX

MSG01	.as -'0.0.5'
*MSG01	.as -'v.r.m'
	.db $00
MSG02	.as -'(S)END (R)ECEIVE (D)IR (C)D'
	.db $8d,$8d,$00
MSG03	.as -'CONFI(G) (?)ABOUT (Q)UIT:'
	.db $00
MSG04	.db $8d
	.as -'GOODBYE - THANKS FOR USING ADTPRO!'
	.db $8d,$8d,$00
MSG05	.as -'RECEIVING'
	.db $00
MSG06	.as -'  SENDING'
	.db $00
MSG07	.as -'  READING'
	.db $00
MSG08	.as -'  WRITING'
	.db $00
MSG09	.as -"BLOCK 00000 OF"
	.db $00
MSG10	.db $20,$20,$20,$A0,$A0,$20,$20,$20
	.db $A0,$A0,$20,$A0,$A0,$A0,$20,$8D
	.db $00
MSG11	.db $20,$A0,$A0,$20,$A0,$20,$A0,$A0
	.db $20,$A0,$A0,$20,$A0,$20,$8D
	.db $00
MSG12	.db $20,$A0,$A0,$20,$A0,$20,$A0,$A0
	.db $20,$A0,$A0,$A0,$20,$8D
	.db $00
MSG13	.as -'FILENAME: '
	.db $00
MSG14	.as -'COMPLETE'
	.db $00
MSG15	.as -' - WITH ERRORS'
	.db $00
MSG16	.as -'PRESS A KEY TO CONTINUE...'
	.db $00
MSG17	.as -"ADTPRO BY DAVID SCHMIDT.  BASED ON WORKS"
	.as -"BY PAUL GUERTIN, MARK PERCIVAL, JOESEPH "
	.as -"OSWOLD, KNUT ROLL-LUND AND OTHERS."
	.db $00
MSGSOU	.as -'   SELECT SOURCE VOLUME'
	.db $00
MSGDST	.as -'SELECT DESTINATION VOLUME'
	.db $00
MSG19	.as -'VOLUMES CURRENTLY ON-LINE:'
	.db $00
MSG20	.as -'SLOT  DRIVE  VOLUME NAME      BLOCKS'
	.db $00
MSG21	.as -'----  -----  ---------------  ------'
	.db $00
MSG22	.as -'CHANGE VOLUME/SLOT/DRIVE WITH ARROW KEYS'
	.db $00
MSG23	.as -'SELECT WITH RETURN, ESC CANCELS'
	.db $00
MSG24	.as -'CONFIGURE ADTPRO PARAMETERS'
	.db $00
MSG25	.as -'CHANGE PARAMETERS WITH ARROW KEYS'
	.db $00
MSG26	.as -'SSC SLOT'
	.db $00
MSG27	.as -'BAUD RATE'
	.db $00
MSG28	.as -'ENABLE SOUND'
	.db $00
MSG28a	.as -'SAVE CONFIG'
	.db $00
MSG29	.as -'KEY TO CONTINUE, ESC TO STOP: '
	.db $00
MSG30	.as -'END OF DIRECTORY.  HIT A KEY: '
	.db $00
MNONAME	.as -'<NO NAME>'
	.db $00
MIOERR	.as -'<I/O ERROR>'
	.db $00
MNODISK	.as -'<NO DISK>'
	.db $00
MSG34	.as -'FILE EXISTS'
	.db $00
MSG35	.as -'IMAGE/DRIVE SIZE MISMATCH!'
	.db $8d,$00
MLOGO1	.db $a0,$20,$20,$a0,$a0,$20,$20,$20,$a0,$a0,$20,$20,$20,$20,$20,$8d,$00
MLOGO2	.db $20,$a0,$a0,$20,$a0,$20,$a0,$a0,$20,$a0,$a0,$a0,$20,$8d,$00
MLOGO3	.db $20,$20,$20,$20,$a0,$20,$a0,$a0,$20,$a0,$a0,$a0,$20,$8d,$00
MLOGO4	.db $20,$a0,$a0,$20,$a0,$20,$a0,$a0,$20,$a0,$a0,$a0,$20,$8d,$00
MLOGO5	.db $20,$a0,$a0,$20,$a0,$20,$20,$20,$a0,$a0,$a0,$a0,$20,$a0
	.as -'PRO'
	.db $8d,$00
MWAIT	.as -'WAITING FOR HOST REPLY, ESC CANCELS'
	.db $00
MCDIR	.as -'DIRECTORY: '
	.db $00
MFORC	.as -'COPY IMAGE DATA ANYWAY? (Y/N):'
	.db $00
MFEX	.as -'FILE ALREADY EXISTS AT HOST.'
	.db $00


*---------------------------------------------------------
* Message equates
*---------------------------------------------------------

PMSG01	.eq $00
PMSG02	.eq $02
PMSG03	.eq $04
PMSG04	.eq $06
PMSG05	.eq $08
PMSG06	.eq $0a
PMSG07	.eq $0c
PMSG08	.eq $0e
PMSG09	.eq $10
PMSG10	.eq $12
PMSG11	.eq $14
PMSG12	.eq $16
PMSG13	.eq $18
PMSG14	.eq $1a
PMSG15	.eq $1c
PMSG16	.eq $1e
PMSG17	.eq $20
PMSGSOU	.eq $22
PMSGDST	.eq $24
PMSG19	.eq $26
PMSG20	.eq $28
PMSG21	.eq $2a
PMSG22	.eq $2c
PMSG23	.eq $2e
PMSG24	.eq $30
PMSG25	.eq $32
PMSG26	.eq $34
PMSG27	.eq $36
PMSG28	.eq $38
PMSG28a	.eq $3a
PMSG29	.eq $3c
PMSG30	.eq $3e
PMNONAME	.eq $40
PMIOERR	.eq $42
PMNODISK	.eq $44
PMSG34	.eq $46
PMSG35	.eq $48
PMLOGO1	.eq $4a
PMLOGO2	.eq $4c
PMLOGO3	.eq $4e
PMLOGO4	.eq $50
PMLOGO5	.eq $52
PMWAIT	.eq $54
PMCDIR	.eq $56
PMFORC	.eq $58
PMFEX	.eq $5a
