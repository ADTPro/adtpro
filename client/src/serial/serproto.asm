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
; DIRREQUEST - Request current directory contents
;---------------------------------------------------------
DIRREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_D	; Send "DIR" command to PC
	jsr PUTC
	rts

;---------------------------------------------------------
; DIRREPLY - Reply to current directory contents
;---------------------------------------------------------
DIRREPLY:
	jsr GETC	; Get character from serial port
	php		; Save flags
	sta (BLKPTR),Y	; Store byte
	iny		; Bump counter
	bne @NEXT	; Skip
	inc <BLKPTR+1	; Next 256 bytes
@NEXT:
	plp		; Restore flags
	bne DIRREPLY	; Loop until zero

	jsr GETC	; Get continuation character
	sta (BLKPTR),Y 	; Store continuation byte too
	rts

;---------------------------------------------------------
; DIRABORT - Abort current directory contents
;---------------------------------------------------------
DIRABORT:
	lda #$00
	jmp PUTC	; ESCAPE, SEND 00 AND RETURN
	rts

;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_C	; Ask host to Change Directory
	jsr PUTC
	jsr SENDFN	; Send directory name
			; Implicit rts from SENDFN
	rts

;---------------------------------------------------------
; CDREPLY - Reply to current directory change
;---------------------------------------------------------
CDREPLY:
	jsr GETC	; Get response from host
	rts

;---------------------------------------------------------
; PUTREQUEST - Request to send an image to the host
;---------------------------------------------------------
PUTREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_P	; Tell host we are Putting/Sending
	jsr PUTC

	jsr SENDFN	; Send file name

	lda NUMBLKS	; Send the total block size
	jsr PUTC
	lda NUMBLKS+1
	jsr PUTC
	rts

;---------------------------------------------------------
; PUTREPLY - Reply from send an image to the host
;---------------------------------------------------------
PUTREPLY:
	jsr GETC	; Get response from host
	rts

;---------------------------------------------------------
; PUTINITIALACK - Send initial ACK for a PUTREQUEST/PUTREPLY
;---------------------------------------------------------
PUTINITIALACK:
	lda #CHR_ACK
	jsr PUTC
	rts

;---------------------------------------------------------
; PUTFINALACK - Send final ACK for a PUTREQUEST/PUTREPLY
;---------------------------------------------------------
PUTFINALACK:
	lda ECOUNT	; Errors during send?
	jsr PUTC	; Send error flag to host
	rts

;---------------------------------------------------------
; GETREQUEST - Request an image be sent from the host
;---------------------------------------------------------
GETREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_G	; Tell host we are Getting/Receiving
	jsr PUTC
	jsr SENDFN	; Send file name
	rts

;---------------------------------------------------------
; GETREPLY - Reply from requesting an image be sent from the host
;---------------------------------------------------------
GETREPLY:
	jsr GETC	; Get response from host: return code/message
	rts

;---------------------------------------------------------
; GETFINALACK - Send final ACK after a GETREQUEST/GETREPLY
;---------------------------------------------------------
GETFINALACK:
	lda #CHR_ACK	; Send last ACK
	jsr PUTC
	lda ECOUNT	; Errors during send?
	jsr PUTC	; Send error flag to host
	rts

;---------------------------------------------------------
; QUERYFNREQUEST/REPLY
;---------------------------------------------------------
QUERYFNREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_Z	; Ask host for file size
	jsr PUTC
	jsr SENDFN	; Send file name
	rts

QUERYFNREPLY:
	jsr GETC	; Get response from host: file size
	sta HOSTBLX
	jsr GETC
	sta HOSTBLX+1
	jsr GETC	; Get response from host: return code/message
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

PUTC:	jmp $0000	; Pseudo-indirect JSR - self-modified
GETC:	jmp $0000	; Pseudo-indirect JSR - self-modified
