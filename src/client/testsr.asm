;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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
; BATCH
;---------------------------------------------------------

BATCH:
;	ldy #PMPREFIX
;	jsr GETFN2
;	bne :+
;	jmp BATCHDONE
;:
	ldy #PMSGSOU	; 'SELECT SOURCE VOLUME'
	jsr PICKVOL
	bmi BATCHDONE
	sta SLOWA

	lda UNITNBR	; Set up the unit number
	sta PARMBUF+1

	jsr CLRMSGAREA
:
	ldy #PMINSERTDISK	; Tell user to insert the next disk...
	jsr WRITEMSGAREA
	jsr PAUSE
	bcs BATCHDONE

	ldy #PMWAIT
	jsr WRITEMSGAREA	; Tell user to have patience

	jsr BATCHREQUEST
	jsr PUTREPLY
	beq BATCHOK
	jmp PCERROR
BATCHOK:
	jsr PCOK
	bcs BATCHDONE
	jmp :-

BATCHDONE:	
	rts

;---------------------------------------------------------
; SEND/RECEIVE functions
;
; Assumes a volume has been chosen via PICKVOL, setting:
;   UNITNBR
;   NUMBLKS
;   NUMBLKS+1
;---------------------------------------------------------

;---------------------------------------------------------
; SEND
;---------------------------------------------------------
SEND:
;	jsr GETFN
;	bne @SendValid
;	jmp SMDONE
@SendValid:
	; Validate the filename won't overwite
	ldy #PMWAIT
	jsr WRITEMSGAREA	; Tell user to have patience
	jsr QUERYFNREQUEST
	jsr QUERYFNREPLY
	cmp #$02	; File doesn't exist - so everything's ok
	beq SMSTART
	lda #$00
	SET_HTAB
	lda #$15
	jsr TABV
	jsr CLREOP
	ldy #PMFEX
	jsr WRITEMSG
	ldy #PMFORC
	jsr YN		; Ask to overwrite
	cmp #$01
	beq SMSTART
	rts

SMSTART:
	ldy #PMSGSOU	; 'SELECT SOURCE VOLUME'
	jsr PICKVOL
;			Accumulator now has the index into device table
	bmi SMDONE1
	sta SLOWA

	lda UNITNBR	; Set up the unit number
	sta PARMBUF+1

	lda #CHR_P	; Set default send type
	sta SendType
	jsr CLRMSGAREA

	ldy #PMWAIT
	jsr WRITEMSGAREA	; Tell user to have patience

	jsr PUTREQUEST		; Note - SendType holds the type of request
	jsr PUTREPLY
	beq PCOK
	jmp PCERROR

SMDONE1:
	rts

PCERROR:
	tay
	jsr SHOWHM1
	jsr PAUSE
	jmp BABORT

PCOK:
	; Here's where we set up a loop
	; for all blocks to transfer.
	lda #$00
	sta ECOUNT	; Clear error flag
	sta CURBLK
	sta CURBLK+1
SendStandard:
	jsr INIT_DISKII
	jsr GO_TRACK0
SendPrep:		; Send standard 5.25"
	jsr PREPPRG	; Prepare the progress screen
	jsr PUTINITIALACK
SMMORE:
	lda NUMBLKS
	sec
	sbc CURBLK
	sta DIFF
	lda NUMBLKS+1
	sbc CURBLK+1
	sta DIFF+1
	bne SMFULL
	lda DIFF
	cmp #$28
	bcs SMFULL
	tay
	jmp SMPARTIAL

SMFULL:
	ldy #$28
	sty DIFF
SMPARTIAL:
	lda CURBLK
	sta BLKLO
	lda CURBLK+1
	sta BLKHI
	jsr READING	; DIFF holds number of blocks to read
	lda CURBLK
	sta BLKLO
	lda CURBLK+1
	sta BLKHI
	jsr SENDING	; DIFF still holds number of blocks to send

	lda BLKLO
	sta CURBLK
	lda BLKHI
	sta CURBLK+1

	; Now, need to see if we're over the size limit...

	cmp NUMBLKS+1	; Compare high-order num blocks byte
	bcc SMMORE
	lda BLKLO
	cmp NUMBLKS	; Compare low-order num blocks byte
	bcc SMMORE

	jsr PUTFINALACK

	jsr COMPLETE
SMDONE:	rts

;---------------------------------------------------------
; RECEIVE
;---------------------------------------------------------
RECEIVE:
	lda #$00
	sta ECOUNT	; Clear error flag
;	jsr GETFN
;	bne SRSTART
;	jmp SRDONE

SRSTART:
	ldy #PMWAIT
	jsr WRITEMSGAREA	; Tell user to have patience
	jsr QUERYFNREQUEST
	jsr QUERYFNREPLY
	cmp #$00
	beq @Ok
	jmp PCERROR
@Ok:
	ldy #PMSGDST	; 'SELECT DESTINATION VOLUME'
	jsr PICKVOL
;			; Accumulator now has the index into device table
; 			; Validate size matches volume picked
SRREENTRY:
	bmi SMDONE	; Branch backwards... we just need an RTS close by
	sta SLOWA	; Hang on to the device table index
	lda HOSTBLX
	cmp NUMBLKS
	bne SRMISMATCH
	lda HOSTBLX+1
	cmp NUMBLKS+1
	bne SRMISMATCH
	jmp SROK2

GoForNib:
	jmp ReceiveNib

SRMISMATCH:
	jsr CLRMSGAREA

	lda #$15
	jsr TABV
	ldy #PMSG35
	jsr WRITEMSG
	ldy #PMFORC
	jsr YN
	bne SROK2
	ldy #PMSGDST	; 'SELECT DESTINATION VOLUME'
	jsr PICKVOL2
	jmp SRREENTRY

SROK2:
	lda UNITNBR
	sta PARMBUF+1

	jsr GETREQUEST
	jsr GETREPLY
	beq SROK3
	jmp PCERROR

;			Here's where we set up a loop
;			for all blocks to transfer.
SROK3:
	ldx SLOWA
	jsr PREPPRG
	lda #$00
	sta CURBLK
	sta CURBLK+1

SRMORE:
	lda NUMBLKS
	sec
	sbc CURBLK
	sta DIFF
	lda NUMBLKS+1
	sbc CURBLK+1
	sta DIFF+1
	bne SRFULL
	lda DIFF
	cmp #$28
	bcs SRFULL
	tay
	jmp SRPARTIAL

SRFULL:
	ldy #$28
	sty DIFF

SRPARTIAL:
	lda CURBLK
	sta BLKLO
	lda CURBLK+1
	sta BLKHI
	jsr RECVING
	lda CURBLK
	sta BLKLO
	lda CURBLK+1
	sta BLKHI
	ldy DIFF	
	jsr WRITING

	lda BLKLO
	sta CURBLK
	lda BLKHI
	sta CURBLK+1

	; Now, need to see if we're over the size limit...

	cmp NUMBLKS+1	; Compare high-order num blocks byte
	bcc SRMORE
	lda BLKLO
	cmp NUMBLKS	; Compare low-order num blocks byte
	bcc SRMORE

	jsr GETFINALACK

	jsr COMPLETE
SRDONE:
	rts

COMPLETE:
	ldy #PMSG14
	jsr WRITEMSGAREA
	lda ECOUNT
	beq CNOERR
	ldy #PMSG15
	jsr WRITEMSG
CNOERR:
	lda #$a1
	jsr COUT1
	jsr CROUT
COMPLETE1:
	jsr PAUSE
COMPLETE2:
	rts

CURBLK:	.byte $00,$00
DIFF:	.byte $00,$00

;---------------------------------------------------------
; SENDING
; RECVING
;
; Read or write from zero to 40 ($28) blocks - inside
; a 64k Apple ][ buffer
;
; Input:
;   DIFF: Count of blocks
;   BLKLO: starting block (lo)
;   BLKHI: starting block (hi)
;---------------------------------------------------------
SENDING:
	lda #PMSG06
	sta SR_WR_C
	lda #CHR_S
	sta SRCHR
	lda #CHR_SP
	sta SRCHROK
	jmp SR_COMN

RECVING:
	lda #PMSG05
	sta SR_WR_C
	lda #CHR_V
	sta SRCHR
	lda #CHR_BLK
	sta SRCHROK

SR_COMN:
	lda #H_BUF
	SET_HTAB
	lda #V_MSG	; Message row
	jsr TABV
	ldy SR_WR_C
	jsr WRITEMSG
	lda #$00	; Reposition cursor to beginning of
	SET_HTAB	;   buffer row
	lda #V_BUF
	jsr TABV
	jsr SRBLOX

	rts

;---------------------------------------------------------
; SRBLOX
;
; Send or receive from zero to 40 ($28) blocks
; Starting from BIGBUF
;
; Input:
;   DIFF: Count of blocks
;   BLKLO: starting block (lo)
;   BLKHI: starting block (hi)
;---------------------------------------------------------
SRBLOX:
	lda DIFF
	sta SRBCNT	; Get a local copy of block count to mess with
	
	LDA_BIGBUF_ADDR_LO	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	LDA_BIGBUF_ADDR_HI
	sta BLKPTR+1

SRCALL:
	LDA_CH
	sta COL_SAV
	lda SRCHR
	jsr COUT

	lda COL_SAV	; Retrieve the previous horizontal cursor position

	lda #V_MSG	; Start printing at first number spot
	jsr TABV
	lda #H_NUM1
	SET_HTAB

	clc
	lda BLKLO	; Increment the 16-bit block number
	adc #$01
	sta NUM
	lda BLKHI
	adc #$00
	tax
	lda NUM
	ldy #CHR_0
	jsr PRD		; Print block number in decimial

	lda COL_SAV	; Position cursor to next
	SET_HTAB	;   buffer row
	lda #V_BUF
	jsr TABV

	lda SRCHR
	cmp #CHR_V	; Are we receiving?
	beq SR1		;   If so, branch around the sending code

	jsr SENDBLK	; Send the current block
	jmp SRCOMN	; Back to sending/receiving common

SR1:
	jsr RECVBLK	; Receive a block

SRCOMN:
	bne SRBAD
	lda COL_SAV	; Position cursor to next buffer row - 
	SET_HTAB	;   have to reassert this, as IIgs messes it up
	lda SRCHROK
	jmp SROK

SRBAD:
	lda #$01
	sta ECOUNT
	lda COL_SAV	; Position cursor to next
	SET_HTAB	;   buffer row
	lda #CHR_X
	sta SRCHROK
SROK:
	cmp #CHR_BLK
	bne :+
	jsr SET_INVERSE
	lda SRCHROK
:	jsr COUT1
	jsr SET_NORMAL
	inc BLKLO
	bne SRNOB
	inc BLKHI
SRNOB:	dec SRBCNT
	beq SRBDONE
	jmp SRCALL

SRBDONE:
	rts

SRBCNT:	.byte $00

;---------------------------------------------------------
; UNDIFF -  Finish RLE decompression and update CRC
;---------------------------------------------------------
UNDIFF:	ldy #0
	sty <CRC	; Clear CRC
	sty <CRC+1
	sty <RLEPREV	; Initial base is zero
UDLOOP:	lda (BLKPTR),Y	; Get new difference
	clc
	adc <RLEPREV	; Add to base
	jsr UPDCRC	; Update CRC
	sta <RLEPREV	; Accumulator is the new base
	sta (BLKPTR),Y 	; Store real byte
	iny
	bne UDLOOP 	; Repeat 256 times
	rts

PABORT:	jmp BABORT

SRCHR:		.byte CHR_V
SRCHROK:	.byte CHR_SP
SCOUNT:	.byte $00
ECOUNT:	.byte $00
