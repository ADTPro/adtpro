;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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
; SEND/RECEIVE functions
;
; Assumes a volume has been chosen via PICKVOL, setting:
;   UNITNBR
;   NUMBLKS
;   NUMBLKS+1
;---------------------------------------------------------

;---------------------------------------------------------
; QUERYFN
;---------------------------------------------------------
QUERYFN:
	jsr PARMINT
	ldy #PMWAIT
	jsr SHOWM1	; Tell user to have patience

	lda #CHR_Z	; Ask host for file size
	jsr PUTC

	jsr SENDFN	; Send file name

	jsr GETC	; Get response from host: file size
	sta HOSTBLX
	jsr GETC
	sta HOSTBLX+1
	jsr GETC	; Get response from host: return code/message
	rts

;---------------------------------------------------------
; SEND
;---------------------------------------------------------
SEND:
	lda #$00
	sta ECOUNT	; Clear error flag
	jsr GETFN
	bne SMVALID
	jmp SMDONE
SMVALID:
	; Validate the filename won't overwite
	jsr QUERYFN
	cmp #$02	; File doesn't exist - so everything's ok
	beq SMSTART
	lda #$00
	sta <CH
	lda #$15
	jsr TABV
	jsr CLREOP
	ldy #PMFEX
	jsr SHOWMSG
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

	lda #$00
	sta <CH
	lda #$14
	jsr TABV
	jsr CLREOP

	ldy #PMWAIT
	jsr SHOWM1	; Tell user to have patience

	lda #CHR_P	; Tell host we are Putting/Sending
	jsr PUTC

	jsr SENDFN	; Send file name

	lda NUMBLKS	; Send the total block size
	jsr PUTC
	lda NUMBLKS+1
	jsr PUTC
	jsr GETC	; Get response from host
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
	jsr PREPPRG	; Prepare the progress screen
	lda #CHR_ACK
	jsr PUTC
	lda #$00
	sta CURBLK
	sta CURBLK+1

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
	jsr READING
	lda CURBLK
	sta BLKLO
	lda CURBLK+1
	sta BLKHI
	ldy DIFF	
	jsr SENDING

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

	lda ECOUNT	; Errors during send?
	jsr PUTC	; Send error flag to host

	jsr COMPLETE
SMDONE:	rts

;---------------------------------------------------------
; RECEIVE
;---------------------------------------------------------
RECEIVE	:
	lda #$00
	sta ECOUNT	; Clear error flag
	jsr GETFN
	bne SRSTART
	jmp SRDONE

SRSTART:
	jsr QUERYFN
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

SRMISMATCH:
	lda #$00
	sta <CH
	lda #$14
	jsr TABV
	jsr CLREOP

	lda #$15
	jsr TABV
	ldy #PMSG35
	jsr SHOWMSG
	ldy #PMFORC
	jsr YN
	bne SROK2
	ldy #PMSGDST	; 'SELECT DESTINATION VOLUME'
	jsr PICKVOL2
	jmp SRREENTRY

SROK2:
	lda UNITNBR
	sta PARMBUF+1

	lda #CHR_G	; Tell host we are Getting/Receiving
	jsr PUTC
	jsr SENDFN	; Send file name
	jsr GETC	; Get response from host: return code/message
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

	lda #CHR_ACK	; Send last ACK
	jsr PUTC
	lda ECOUNT	; Errors during send?
	jsr PUTC	; Send error flag to host

	jsr COMPLETE
SRDONE:
	rts

COMPLETE:
;	lda #$00	; Reposition cursor to previous
;	sta <CH		; buffer row
;	lda #$16
;	jsr TABV
	ldy #PMSG14
	jsr SHOWM1
	lda ECOUNT
	beq CNOERR
	ldy #PMSG15
	jsr SHOWMSG
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
;   Y: Count of blocks
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
	sty SRBCNT
	lda #H_BUF
	sta <CH
	lda #V_MSG	; Message row
	jsr TABV
	ldy SR_WR_C
	jsr SHOWMSG

	lda #$00	; Reposition cursor to beginning of
	sta <CH		; buffer row
	lda #V_BUF
	jsr TABV

	jsr SRBLOX

	rts

;---------------------------------------------------------
; SRBLOX
;
; Read or write from zero to 40 ($28) blocks
; Starting from BIGBUF
;
; Input:
;   SRBCNT: Count of blocks
;   BLKLO: starting block (lo)
;   BLKHI: starting block (hi)
;---------------------------------------------------------
SRBLOX:
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1

SRCALL:
	lda SRCHR
	jsr CHROVER

	lda <CH
	sta <COL_SAV

	lda #V_MSG	; Start printing at first number spot
	jsr TABV
	lda #H_NUM1
	sta <CH

	lda BLKLO	; Increment the 16-bit block number
	clc
	adc #$01
	sta PRTPTR
	lda BLKHI
	bcc SRNEXT
	clc
	adc #$01
SRNEXT:
	sta PRTPTR+1
	jsr PRTNUM	; Print block number in decimial

	lda <COL_SAV	; Position cursor to next
	sta <CH		;   buffer row
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
	lda <COL_SAV	; Position cursor to next buffer row - 
	sta <CH		;   have to reassert this, as IIgs messes it up
	lda SRCHROK
	jmp SROK

SRBAD:
	lda #$01
	sta ECOUNT
	lda <COL_SAV	; Position cursor to next
	sta <CH		;   buffer row
	lda #CHR_X
SROK:	jsr COUT1
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
; SENDBLK - Send a block with RLE
; CRC is sent to host
; BLKPTR points to full block to send - updated here
;---------------------------------------------------------
SENDBLK:
	lda #$02
	sta <ZP

SENDMORE:
	jsr SENDHBLK
	lda <CRC	; Send the CRC of that block
	jsr PUTC
	lda <CRC+1
	jsr PUTC
	jsr GETC	; Receive reply
	cmp #CHR_ACK	; Is it ACK?  Loop back if NAK.
	bne SENDMORE
	inc <BLKPTR+1	; Get next 256 bytes
	dec <ZP
	bne SENDMORE
	rts

;---------------------------------------------------------
; SENDHBLK - Send half a block with RLE
; CRC is computed and stored
; BLKPTR points to half block to send
;---------------------------------------------------------
SENDHBLK:
	ldy #$00	; Start at first byte
	sty <CRC	; Clean out CRC
	sty <CRC+1
	sty <RLEPREV

SS1:	lda (BLKPTR),Y	; GET BYTE TO SEND
	jsr UPDCRC	; UPDATE CRC
	tax		; KEEP A COPY IN X
	sec		; SUBTRACT FROM PREVIOUS
	sbc <RLEPREV
	stx <RLEPREV	; SAVE PREVIOUS BYTE
	jsr PUTC	; SEND DIFFERENCE
	beq SS3		; WAS IT A ZERO?
	iny		; NO, DO NEXT BYTE
	bne SS1		; LOOP IF MORE TO DO
	rts		; ELSE RETURN

SS2:	jsr UPDCRC
SS3:	iny		; ANY MORE BYTES?
	beq SS4		; NO, IT WAS 00 UP TO END
	lda (BLKPTR),Y	; LOOK AT NEXT BYTE
	cmp <RLEPREV
	beq SS2		; SAME AS BEFORE, CONTINUE
SS4:	tya		; DIFFERENCE NOT A ZERO
	jsr PUTC	; SEND NEW ADDRESS
	bne SS1		; AND GO BACK TO MAIN LOOP
	rts		; OR RETURN IF NO MORE BYTES

SRCHR:	.byte CHR_V
SRCHROK:	.byte CHR_SP


;---------------------------------------------------------
; SENDFN - Send a file name
;
; Assumes input is at $0200
;---------------------------------------------------------
SENDFN:
	ldx #$00	
FNLOOP:	lda $0200,X
	jsr PUTC
	beq @Done
	inx
	bne FNLOOP
@Done:
	rts


;---------------------------------------------------------
; RECVBLK - Receive a block with RLE
;
; BLKPTR points to full block to receive - updated here
;---------------------------------------------------------
RECVBLK:
	lda #$02
	sta <ZP
	lda #CHR_ACK

RECVMORE:
	tax
	ldy #$00	; Clear out the new half-block
	tya
CLRLOOP:
	sta (BLKPTR),Y
	iny
	bne CLRLOOP
	txa
	jsr PUTC	; Send ack/nak

	jsr RECVHBLK
	jsr GETC	; Receive reply
	sta PCCRC	; Receive the CRC of that block
	jsr GETC
	sta PCCRC+1
	jsr UNDIFF

	lda <CRC
	cmp PCCRC
	bne RECVERR
	lda <CRC+1
	cmp PCCRC+1
	bne RECVERR

RECBRANCH:
	lda #CHR_ACK
	inc <BLKPTR+1	; Get next 256 bytes
	dec <ZP
RECOK:	bne RECVMORE
	lda #$00
	rts

RECVERR:
	lda #CHR_NAK	; CRC error, ask for a resend
	jmp RECVMORE

;---------------------------------------------------------
; RECVHBLK - Receive half a block with RLE
;
; CRC is computed and stored
;---------------------------------------------------------
RECVHBLK:
	ldy #00		; Start at beginning of buffer
RC1:
	jsr GETC	; Get difference
	beq RC2		; If zero, get new index
	sta (BLKPTR),Y	; else put char in buffer
	iny		; ...and increment index
	bne RC1		; Loop if not at end of buffer
	rts		; ...else return
RC2:
	jsr GETC	; Get new index
	tay		; in the Y register
	bne RC1		; Loop if index <> 0
	rts		; ...else return

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

PUTC:	jmp $0000	; Pseudo-indirect JSR - self-modified
GETC:	jmp $0000	; Pseudo-indirect JSR - self-modified

PABORT:	jmp BABORT

SCOUNT:	.byte $00
ECOUNT:	.byte $00

