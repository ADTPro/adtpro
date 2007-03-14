;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 by David Schmidt
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
; Some local constants
;---------------------------------------------------------
A1L	= $3c
A1H	= $3d
A2L	= $3e
A2H	= $3f
TIMEY	= $8a
DONE	= $1a
HEADR	= $FCC9
WRBIT	= $FCD6
LASTIN	= $2f
TAPEIN	= $C060

;---------------------------------------------------------
; DIRREQUEST - Request current directory contents
;---------------------------------------------------------
DIRREQUEST:
	lda #CHR_D
	jsr PUTC
	rts

;---------------------------------------------------------
; DIRREPLY - Reply to current directory contents
;---------------------------------------------------------
DIRREPLY:
	ldax #AUD_BUFFER
	stax A1L
	stax BLKPTR	; DIRDISP expects data at (BLKPTR)
	jsr aud_receive
	rts

;---------------------------------------------------------
; DIRABORT - Abort current directory contents
;---------------------------------------------------------
DIRABORT:
	lda #$00
	jsr PUTC
	rts

;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
	stax A2L	; Set everyone up to talk to the AUD_BUFFER
	ldy #$00
	lda #CHR_C	; First byte: 'C', for CD
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT	; Copy over user input area
	dey
	tya
	clc
	adc A1L		; Find the end
	sta A2L		; Tell A2 how long the data is
	bcc :+
	inc A2H
				; Max CD request will be 255 bytes
				; It's unlikely the $200 buffer is
				; much bigger than that anyway...
:	jsr aud_send
	rts

;---------------------------------------------------------
; CDREPLY - Reply to current directory change
; PUTREPLY - Reply from send an image to the host
; BATCHREPLY - Reply from send multiple images to the host
; GETREPLY - Reply from requesting an image be sent from the host
; One-byte replies
;---------------------------------------------------------
CDREPLY:
PUTREPLY:
BATCHREPLY:
GETREPLY:
	jsr GETC
	rts

;---------------------------------------------------------
; PUTREQUEST - Request to send an image to the host
;---------------------------------------------------------
PUTREQUEST:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L	; Set everyone up to talk to the AUD_BUFFER
	stx A2H
	ldy #$00
	lda #CHR_P		; Tell host we are Putting/Sending
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	lda NUMBLKS		; Send the total block size
	sta (BLKPTR),Y
	iny
	lda NUMBLKS+1
	sta (BLKPTR),Y
	tya
	clc
	adc A1L
	sta A2L
	bcc :+
	inc A2H
:	jsr aud_send
	rts

;---------------------------------------------------------
; PUTINITIALACK -
;---------------------------------------------------------
PUTINITIALACK:
	lda ACKMSG
	jsr PUTC
	rts

;---------------------------------------------------------
; PUTFINALACK -
;---------------------------------------------------------
PUTFINALACK:
	lda ECOUNT
	jsr PUTC
	rts

;---------------------------------------------------------
; GETREQUEST -
;---------------------------------------------------------
GETREQUEST:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
	stx A2H
	ldy #$00
	lda #CHR_G	; Ask host to send the file
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	dey
	tya
	clc
	adc A1L
	sta A2L
	bcc :+
	inc A2H
:	jsr aud_send
	rts

;---------------------------------------------------------
; GETFINALACK -
;---------------------------------------------------------
GETFINALACK:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
	stx A2H

	ldy #$00
	lda #CHR_ACK	; Send last ACK
	sta (BLKPTR),Y
	iny
	lda ECOUNT	; Errors during send?
	sta (BLKPTR),Y
	iny
	tya
	clc
	adc A1L
	sta A2L
	bcc :+
	inc A2H
:	jsr aud_send
	rts

;---------------------------------------------------------
; BATCHREQUEST - Request to send multiple images to the host
;---------------------------------------------------------
BATCHREQUEST:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
	stx A2H
	ldy #$00
	lda #CHR_B		; Tell host we are Putting/Sending
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	lda NUMBLKS		; Send the total block size
	sta (BLKPTR),Y
	iny
	lda NUMBLKS+1
	sta (BLKPTR),Y
	iny
	tya
	clc
	adc A1L
	sta A2L
	bcc :+
	inc A2H
:	jsr aud_send
	rts

;---------------------------------------------------------
; QUERYFNREQUEST
;---------------------------------------------------------
QUERYFNREQUEST:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
	stx A2H
	ldy #$00
	lda #CHR_Z	; Ask host for file size
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	tya
	clc
	adc A1L
	sta A2L
	bcc :+
	inc A2H
:	jsr aud_send
	rts

;---------------------------------------------------------
; QUERYFNREPLY -
;---------------------------------------------------------
QUERYFNREPLY:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
	stx A2H
	jsr aud_receive
	lda AUD_BUFFER	; File size lsb
	sta HOSTBLX
	lda AUD_BUFFER+1	; File size msb
	sta HOSTBLX+1
	lda AUD_BUFFER+2	; Return code/message
	sta QUERYRC	; Just some temp storage
	rts

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
	jsr PUTREPLY
	cmp #CHR_ACK	; Is it ACK?  Loop back if NAK ($17) or timeout ($08).
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
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L

	lda BLKLO
	jsr BUFBYTE	; Send the block number (LSB)
	lda BLKHI
	jsr BUFBYTE	; Send the block number (MSB)
	lda <ZP
	jsr BUFBYTE	; Send the half-block number

SS1:	lda (BLKPTR),Y	; GET BYTE TO SEND
	jsr UPDCRC	; UPDATE CRC
	tax		; KEEP A COPY IN X
	sec		; SUBTRACT FROM PREVIOUS
	sbc <RLEPREV
	stx <RLEPREV	; SAVE PREVIOUS BYTE
	jsr BUFBYTE	; SEND DIFFERENCE
	beq SS3		; WAS IT A ZERO?
	iny		; NO, DO NEXT BYTE
	bne SS1		; LOOP IF MORE TO DO
	jmp SENDHEND	; ELSE finish packet

SS2:	jsr UPDCRC
SS3:	iny		; ANY MORE BYTES?
	beq SS4		; NO, IT WAS 00 UP TO END
	lda (BLKPTR),Y	; LOOK AT NEXT BYTE
	cmp <RLEPREV
	beq SS2		; SAME AS BEFORE, CONTINUE
SS4:	tya		; DIFFERENCE NOT A ZERO
	jsr BUFBYTE	; SEND NEW ADDRESS
	bne SS1		; AND GO BACK TO MAIN LOOP

SENDHEND:
	lda <CRC	; Send the CRC of that block
	jsr BUFBYTE
	lda <CRC+1
	jsr BUFBYTE
	ldax UTILPTR
	stax A2L
	jsr aud_send
	rts

;---------------------------------------------------------
; BUFBYTE
; Add accumulator to the outgoing packet
; UTILPTR points to the data we're going to save
;---------------------------------------------------------
BUFBYTE:
	php
	sty UDPI	; Store Y for safe keeping
	ldy #$00
	sta (UTILPTR),Y
	inc UTILPTR
	bne :+
	inc UTILPTR+1
:	ldy UDPI	; Restore Y
	plp
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
	sta ACK_CHAR

RECVMORE:
	lda #$00	; Clear out the new half-block
	tay
CLRLOOP:
	sta (BLKPTR),Y
	iny
	bne CLRLOOP
	lda ACK_CHAR
	jsr PUTC	; Send ack/nak

	jsr RECVHBLK

RECVBLK2:
	jsr UNDIFF
	lda <CRC
	cmp PCCRC
	bne RECVERR
	lda <CRC+1
	cmp PCCRC+1
	bne RECVERR

RECBRANCH:
	lda #CHR_ACK
	sta ACK_CHAR
	inc <BLKPTR+1	; Get next 256 bytes
	dec <ZP
RECOK:	bne RECVMORE
	lda #$00
	rts

RECVERR:
	lda #CHR_NAK	; CRC error, ask for a resend
	sta ACK_CHAR
	jmp RECVMORE

ACK_CHAR: .byte CHR_ACK

;---------------------------------------------------------
; RECVHBLK - Receive half a block with RLE
;
; CRC is computed and stored
;---------------------------------------------------------
RECVHBLK:
	ldax #AUD_BUFFER
	stax UTILPTR	; Connect UTILPTR to audio buffer
	stax A1L
	lda #$00
	sta RLEPREV	; Start output at beginning of BLKPTR buffer
	sta UDPI	; Start input at beginning of UTILPTR buffer
	jsr aud_receive
RC1:
	ldy UDPI
	lda (UTILPTR),Y	; Get next byte out of audio buffer
	beq RC2		; If it's zero, get new index
	iny
	cpy #$00
	bne :+
	inc UTILPTR+1
:	sty UDPI
	ldy RLEPREV
	sta (BLKPTR),Y	; else put char in buffer
	iny		; ...and increment BLKPTR's index
	sty RLEPREV
	bne RC1		; Loop if not at end of buffer
	jmp RCVEND	; ...else done
RC2:
	iny		; Increment the UTILPTR index
	sty UDPI
	cpy #$00
	bne :+
	inc UTILPTR+1
:	lda (UTILPTR),Y	; Get next byte out of audio buffer - the next index
	sta RLEPREV	; Save the new BLKPTR index
	php
	iny		; Increment the UTILPTR index
	sty UDPI
	cpy #$00
	bne :+
	inc UTILPTR+1
:	plp
	bne RC1		; Loop if index <> 0
			; ...else done
RCVEND:
	ldy UDPI
	lda (UTILPTR),Y	; Get next byte out of audio buffer
	sta PCCRC	; Receive the CRC of that block
	iny
	cpy #$00
	bne :+
	inc UTILPTR+1	; Point at next 256 bytes
:	lda (UTILPTR),Y	; Get next byte out of audio buffer
	sta PCCRC+1
	rts

;---------------------------------------------------------
; PUTC - Send the accumulator alone in a packet
;---------------------------------------------------------
PUTC:
	sta AUD_BUFFER
	ldax #AUD_BUFFER
	stax A1L
	stax A2L
	jsr aud_send	; Let 'er rip
	rts

;---------------------------------------------------------
; GETC - Receive a packet and get the first byte from it
;---------------------------------------------------------
GETC:
	lda #$ff	; Stuff some non-zero garbage
	sta AUD_BUFFER	;   in the audio buffer
	ldax #AUD_BUFFER
	stax A1L
	jsr aud_receive
	lda AUD_BUFFER	; Send back whatever we received
	rts

;---------------------------------------------------------
; aud_send - Send a packet out the cassette port
;---------------------------------------------------------
aud_send:
	lda #$02	; Only train for a little while - not 10 seconds!
	jsr $FECF	; Write bytes from (A1L) to (A2L)
	rts

;---------------------------------------------------------
; aud_receive - Receive a packet from the cassette port
;---------------------------------------------------------
aud_receive:
	lda #$01
	sta DONE	; Done indicator
	jsr RD2BIT_NO_TIMEOUT	; Find tapein edge
	lda #$02	; Training duration
	jsr HEADR
	jsr RD2BIT_NO_TIMEOUT	; Find tapein edge
RD2:
	ldy #$10	; Look for sync bit
	jsr RDBIT_NO_TIMEOUT	;   (Short zero)
	bcs RD2		;   Loop until found
	jsr RDBIT_NO_TIMEOUT	; Skip second sync half cycle
	ldy #$1a ; 21	; Index for 0/1 test
RD3:	jsr RDBYTE	; Read a byte
	sta (A1L,X)	; Store at (A1)
	jsr BumpA1	; Bump A1
	ldy #$17 ; 1f	; Compensate 0/1 index
	lda DONE
	bne RD3		; Loop until done
	rts

RDBYTE:	ldx #$08	; 8 bits to read
RDBYT2:	pha		; Read two transitions
	lda #$ff	; Init timeout counter
	sta TIMEY	;   max timeout
	lda DONE
	beq RDBYTDONE
	jsr RD2BIT	; Find edge
	pla
	rol a		; Next bit
	ldy #$19 ;21	; Count for samples
	dex
	bne RDBYT2
	rts
RDBYTDONE:
	pla
	lda #$00
	ldx #$00
	rts
RD2BIT:	jsr RDBIT
RDBIT:
	dec TIMEY
	beq TAPTMOT
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	beq TAPABORT
	dey		; Decrement Y until
	lda TAPEIN	;   tape transition
	eor LASTIN
	bpl RDBIT
	eor LASTIN
	sta LASTIN
	cpy #$80	; Set carry on Y-register
	rts

RD2BIT_NO_TIMEOUT:
	jsr RDBIT_NO_TIMEOUT
RDBIT_NO_TIMEOUT:
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	beq TAPABORT
	dey		; Decrement Y until
	lda TAPEIN	;   tape transition
	eor LASTIN
	bpl RDBIT_NO_TIMEOUT
	eor LASTIN
	sta LASTIN
	cpy #$80	; Set carry on Y-register
	rts

BumpA1:
	clc
	inc A1L
	bne BumpA1Done
	inc A1H
BumpA1Done:
	rts

TAPTMOT:
	lda #$01
	sta TIMEY	; In case we come around once more, we'll still get decremented to zero
	lda #$00
	sta DONE
	clc
	rts

TAPABORT:
	jmp ABORT

;---------------------------------------------------------
; COPYINPUT - Copy data from input area to (BLKPTR);
; Y is assumed to point to the next available byte
; after (BLKPTR); Y will point to the next byte on exit
;---------------------------------------------------------
COPYINPUT:
	ldx #$00
@LOOP:	lda $0200,X
	sta (BLKPTR),Y
	php
	inx
	iny
	plp
	beq @Done
	bne @LOOP
@Done:	rts

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
AUD_BUFFER:
	.res  1500
QUERYRC:
	.byte $00
PUTCMSG:
	.byte $00
ABORTMSG:
	.byte $00
ACKMSG:
	.byte CHR_ACK
