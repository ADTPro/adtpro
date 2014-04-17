;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2014 by David Schmidt
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
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	lda #CHR_C		; Ask host to Change Directory
	GO_SLOW			; Slow down for SOS
	jsr FNREQUEST
	lda CHECKBYTE
	jsr PUTC
	GO_FAST			; Speed up for SOS
	rts


;---------------------------------------------------------
; DIRREQUEST - Request current directory contents
; NIBPCNT contains the page number to request
;---------------------------------------------------------
DIRREQUEST:
	jsr PARMINT		; Clean up the comms device
	lda #CHR_D		; Send "DIR" command to PC
	GO_SLOW			; Slow down for SOS
	jsr FNREQUEST
	lda NIBPCNT
	jsr PUTC
	eor CHECKBYTE
	jsr PUTC
	GO_FAST			; Speed back up for SOS
	rts
	

;---------------------------------------------------------
; DIRREPLY - Reply to current directory contents
; NIBPCNT contains the page number that was requested - which is 1k-worth of transmission (4 256byte pages, 2 blocks, 2BAO)
; Returns carry set on CRC failure (should retry - nak sent)
; Returns TMOT > 0 on timeout (should not retry)
;---------------------------------------------------------
DIRREPLY:
	ldy #$00
	sty TMOT	; Clear timeout processing
	sty PAGECNT
	LDA_BIGBUF_ADDR_LO	; Connect the block pointer to the
	sta Buffer		; Big Buffer(TM), 1k * NIBPCNT
	sta BLKPTR
	lda #$04
	sta PAGECNT+1
	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta Buffer+1
	sta BLKPTR+1

	; clear out the memory at (Buffer)
	ldx #$04
	lda #$00
	tay
:	sta (Buffer),y
	iny
	bne :-
	inc Buffer+1
	dex
	bne :-
	lda BLKPTR+1
	sta Buffer+1	; Restore Buffer pointer

	jsr RECVWIDE
	bcs @DirTimeout
	lda HOSTBLX+1	; Prepare the acknowledge packet-required variables
	sta BLKHI
	lda HOSTBLX
	clc
	adc #$02
	sta BLKLO
	bcc :+
	inc BLKHI
:	lda <CRC
	cmp PCCRC
	bne @DirRetry
	lda <CRC+1
	cmp PCCRC+1
	bne @DirRetry
	ldx #CHR_ACK
	jsr PUTACKBLK
	LDA_BIGBUF_ADDR_LO	; Re-connect the block pointer to the
	sta Buffer		; Big Buffer(TM), 1k * NIBPCNT again
	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta Buffer+1
	clc		; Indicate success
	rts

@DirRetry:
	ldx #CHR_NAK
	jsr PUTACKBLK
	sec
	rts 

@DirTimeout:
	clc
	ldy #$01
	sta TMOT
	rts


;---------------------------------------------------------
; QUERYFNREQUEST/REPLY
;---------------------------------------------------------
QUERYFNREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_Z	; Ask host for file size
	GO_SLOW			; Slow down for SOS
	jsr FNREQUEST
	lda CHECKBYTE
	jsr PUTC
	GO_FAST		; Speed back up for SOS
	rts

QUERYFNREPLY:
	GO_SLOW			; Slow down for SOS
	jsr GETC	; Get response from host: file size
	bcs @QFNTimeout
	sta HOSTBLX
	jsr GETC
	bcs @QFNTimeout
	sta HOSTBLX+1
	jsr GETC	; Get response from host: return code/message
	bcs @QFNTimeout
	GO_FAST		; Speed back up for SOS
	rts
@QFNTimeout:
	GO_FAST		; Speed back up for SOS
	jsr HOSTTIMEOUT
	jmp BABORT


;---------------------------------------------------------
; FNREQUEST - Request something with a file name
; Assumes SOS has been slowed down already
;---------------------------------------------------------
FNREQUEST:
	pha
	jsr PARMINT	; Clean up the comms device
	lda #CHR_A	; Envelope
	sta CHECKBYTE
	jsr PUTC
	ldx #$00	; Count the length of the filename
@loop:	lda IN_BUF,x
	php
	inx
	plp
	bne @loop
	pla		; Which command was it?
	cmp #CHR_P	; Was it a Put?
	beq @addtwo
	cmp #CHR_N	; Was it a Nibble?
	beq @addtwo	
	cmp #CHR_B	; Was it a Batch?
	beq @addtwo
	cmp #CHR_M	; Was it a Multiple nibble?
	beq @addtwo
	cmp #CHR_G	; Was it a Get?
	beq @addone	
	cmp #CHR_D	; Was it a Dir?
	beq @addone
	jmp @noadd	; Everyone else - no add
@addtwo:
	inx		; Increment x twice if so... need room for 2 more bytes
@addone:
	inx		; Increment x once if so... need room for 1 more byte
@noadd:	pha
	txa
	jsr PUTC	; Payload length - lsb
	eor CHECKBYTE
	sta CHECKBYTE
	lda #$00
	jsr PUTC	; Payload length - msb
			; No need to update checksum... eor with 0 makes no change
	pla		; Pull the request byte
	jsr PUTC
	eor CHECKBYTE
	sta CHECKBYTE
	jsr PUTC	; Send the check byte for envelope
	jsr SENDFN	; Send requested name
	rts


;---------------------------------------------------------
; PUTREQUEST - Request to send an image to the host
; SendType holds request type:
; CHR_P - typical put
; CHR_N - nibble send
; CHR_H - half track send
;---------------------------------------------------------
PUTREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda SendType
	jsr FNREQUEST
	lda NUMBLKS	; Send the total block size
	jsr PUTC
	eor CHECKBYTE
	sta CHECKBYTE
	lda NUMBLKS+1
	jsr PUTC
	eor CHECKBYTE
	jsr PUTC	; Send check byte
	rts


;---------------------------------------------------------
; PUTACKBLK - Send acknowlegedment packet
; X contains the acknowledgement type
;---------------------------------------------------------
PUTACKBLK:
	stx SLOWX
	jsr PARMINT	; Clean up the comms device
	lda #CHR_A	; Envelope
	GO_SLOW		; Slow down for SOS
	jsr PUTC
	lda #$03	; Three byte payload
	jsr PUTC
	lda #$00
	jsr PUTC
	lda #CHR_K	; Acknowledgement packet
	jsr PUTC	; Send ack type
	lda #$09	; Pre-calculted check byte
	jsr PUTC	; Send check byte
	lda SLOWX	; Grab the ack type 
	jsr PUTC
	sta CHECKBYTE
	lda BLKLO	; Send the current block number LSB
	jsr PUTC
	eor CHECKBYTE
	sta CHECKBYTE
	lda BLKHI	; Send the current block number MSB
	jsr PUTC
	eor CHECKBYTE
	jsr PUTC	; Send check byte
	GO_FAST		; Speed back up for SOS
	rts


;---------------------------------------------------------
; PUTFINALACK - Send error count for requests
;---------------------------------------------------------
PUTFINALACK:
	lda #CHR_A
	jsr PUTC	; Wide protocol - 'A'
	lda #$01
	jsr PUTC	; Wide protocol - lsb of bytes to expect
	lda #$00
	jsr PUTC	; Wide protocol - msb of bytes to expect
	lda #CHR_Y	; Wide protocol - 'Y'
	jsr PUTC
	lda #$19
	jsr PUTC
	lda ECOUNT	; Errors during send?
	jsr PUTC
	jsr PUTC	; Check byte will be the same thing
	rts


;---------------------------------------------------------
; GETREQUEST - Request an image be sent from the host
;---------------------------------------------------------
GETREQUEST:
	jsr PARMINT	; Clean up the comms device
	lda #CHR_G	; Tell host we are Getting/Receiving
	jsr FNREQUEST
	lda BAOCNT
	jsr PUTC	; Express number of blocks at once (BAOCNT)
	eor CHECKBYTE
	jsr PUTC	; Send check byte
	rts


;---------------------------------------------------------
; PUTREPLY - Reply from send an image to the host
; BATCHREPLY - Reply from send multiple images to the host
; CDREPLY - Reply to current directory change
; GETREPLY - Reply from requesting an image be sent from the host
;---------------------------------------------------------
PUTREPLY:
CDREPLY:
GETREPLY:
GETREPLY2:
BATCHREPLY:
	jsr GETC
	rts


;---------------------------------------------------------
; BATCHREQUEST - Request to send multiple images to the host
;---------------------------------------------------------
BATCHREQUEST:
	lda SendType
	sta SLOWX	; Stash the SendType as we'll be modifying it briefly
	; CHR_P - typical put -> CHR_B (batch)
	; CHR_N - nibble send -> CHR_M (multiple nibble)
	cmp #CHR_P
	bne :+
	lda #CHR_B
	sta SendType
	jmp BGo
:	cmp #CHR_N
	bne BGo
	lda #CHR_M
	sta SendType
BGo:	jsr PUTREQUEST
	lda SLOWX
	sta SendType
	rts


;---------------------------------------------------------
; RECVBLKS - Receive blocks with RLE
;
; BLKPTR points to starting block to receive - updated here
;---------------------------------------------------------
RECVBLKS:
	lda BLKPTR
	sta PAGECNT
	lda BLKPTR+1
	sta PAGECNT+1
	
	ldx #CHR_ACK	; Initial ack

RECVMORE:
	lda BLKPTR+1
	sta SCOUNT	; Stash the msb of BLKPTR, which RECVWIDE trashes
	lda #$00
	sta PAGECNT
	sta PAGECNT+1
	lda SCOUNT
	sta BLKPTR+1	; Restore BLKPTR msb when looping

	GO_SLOW		; Slow down for SOS
	jsr PUTACKBLK	; Send ack/nak packet for blocks
	jsr RECVWIDE
	GO_FAST		; Speed back up for SOS
	bcs RECVERR
	lda <CRC
	cmp PCCRC
	bne RECVERR
	lda <CRC+1
	cmp PCCRC+1
	bne RECVERR
	clc		; Indicate success
	rts

RECVERR:
	ldx #CHR_NAK	; CRC error, ask for a resend
	jmp RECVMORE


;---------------------------------------------------------
; SENDBLKS - Send blocks with RLE
; CRC is sent to host
; BLKPTR points to full block to send - updated here
; BAOCNT is the number of blocks to send
; BLKLO/BLKHI - in - passed to SENDWIDE as the starting block
; Returns:
;   ACK character in accumulator, carry clear
;   carry set in case of timeout
;---------------------------------------------------------
SENDBLKS:
	lda BLKPTR+1
	sta SCOUNT	; Stash the msb of BLKPTR, which SENDWIDE trashes
	lda #$00
	sta PAGECNT
	lda BAOCNT
	asl		; Convert blocks to pages
	sta PAGECNT+1
:	lda SCOUNT
	sta BLKPTR+1	; Restore BLKPTR msb when looping
	GO_SLOW		; Slow down for SOS
	jsr SENDWIDE
	jsr GETC	; Receive reply
	GO_FAST		; Speed back up for SOS
	bcs @SendTimeout
	cmp #CHR_ACK	; Is it ACK?  Loop back if NAK.
	bne :-
	clc
	rts
@SendTimeout:
	sec		; Indicate failure
	rts


;---------------------------------------------------------
; RECVWIDE - Receive a chunk of data
; BLKPTR - in - points at buffer to save to
; PAGECNT is used as 2-byte value of length to ultimately receive
; CRC is computed and stored
;---------------------------------------------------------
RWERR:
	sec
	rts

RECVWIDE:
	lda BLKPTR
	sta BUFPTR
	lda BLKPTR+1
	sta BUFPTR+1
	ldy #00		; Start at beginning of buffer

	jsr GETC	; Get protocol - must be an 'A'
	bcs RWERR	; Timeout - bail
	cmp #CHR_A	;
	bne RWERR
	jsr GETC	; Get payload length, LSB
	bcs RWERR	; Timeout - bail
	sta PAGECNT	; Store length
	sta XFERLEN
	jsr GETC	; Get payload length, MSB
	bcs RWERR	; Timeout - bail
	sta PAGECNT+1	; Store length
	sta XFERLEN+1
	jsr GETC	; Get protocol - must be an 'S'
	bcs RWERR	; Timeout - bail
	cmp #CHR_S	;
	bne RWERR
	jsr GETC	; Get protocol - check byte (discarded for the moment)
	bcs RWERR	; Timeout - bail
	jsr GETC	; Get block number, LSB
	bcs RWERR	; Timeout - bail
	sta HOSTBLX
	jsr GETC	; Get block number, MSB
	bcs RWERR	; Timeout - bail
	sta HOSTBLX+1
			; TODO - probably should save/check the block number is the one we need...
RW1:
	jsr GETC	; Get difference
	bcs RWERR	; Timeout - bail
	beq RW2		; If zero, get new index
	sta (BLKPTR),Y	; else put char in buffer
	iny		; ...and increment index
	bne RW1		; Loop if not at end of buffer
	beq RWNext	; Branch always

RW2:
	jsr GETC	; Get new index ...
	bcs RWERR	; Timeout - bail
	tay		; ... in the Y register
	bne RW1		; Loop if index <> 0
			; ...else check for more or return

RWNext:	dec PAGECNT+1
	beq @Done	; Done?
	inc BLKPTR+1	; Get ready for another page
	jmp RW1
@Done:	jsr GETC	; Done - get CRC
	sta PCCRC
	jsr GETC
	GO_FAST		; Speed back up for SOS
	sta PCCRC+1
	lda XFERLEN+1
	sta PAGECNT+1
	lda BUFPTR
	sta BLKPTR
	lda BUFPTR+1
	sta BLKPTR+1
	jsr UNDIFFWide
	clc
	rts


;---------------------------------------------------------
; SENDWIDE - Send a chunk of data
;   BLKLO/BLKHI - in - block number to start with
;   BLKPTR points to data to send
;   PAGECNT holds the number of bytes to send
;---------------------------------------------------------
SENDWIDE:
	ldy #$00	; Start at first byte
	sty <CRC	; Clean out CRC
	sty <CRC+1
	sty <RLEPREV
	lda #CHR_A
	jsr PUTC	; Wide protocol - 'A'
	sta CHECKBYTE
	lda PAGECNT
	jsr PUTC	; Wide protocol - lsb of bytes to expect
	eor CHECKBYTE
	sta CHECKBYTE
	lda PAGECNT+1
	jsr PUTC	; Wide protocol - msb of bytes to expect
	eor CHECKBYTE
	sta CHECKBYTE
;	inc PAGECNT+1	; Bump the high byte - round up to next full page length
	lda #CHR_S	; Wide protocol - 'S'
	jsr PUTC
	eor CHECKBYTE
	jsr PUTC	; Send check byte of envelope
	lda BLKLO
	jsr PUTC	; Send the block number (LSB)
	lda BLKHI
	jsr PUTC	; Send the block number (MSB)
	dec BLKPTR+1	; Pre-decrement since the top of the loop increments the block pointer

SW0:	inc BLKPTR+1
SW1:	lda (BLKPTR),Y	; GET BYTE TO SEND
	jsr UPDCRC	; UPDATE CRC
	tax		; KEEP A COPY IN X
	sec		; SUBTRACT FROM PREVIOUS
	sbc <RLEPREV
	stx <RLEPREV	; SAVE PREVIOUS BYTE
	jsr PUTC	; SEND DIFFERENCE
	beq SW3		; WAS IT A ZERO?
	iny		; NO, DO NEXT BYTE
	bne SW1		; LOOP IF MORE TO DO
	dec PAGECNT+1	; Decrement the page counter
	bne SW0		; Loop if more to do
	lda <CRC	; Send the overall CRC
	jsr PUTC
	lda <CRC+1
	jsr PUTC
	inc BLKPTR+1	; Final update of BLKPTR
	rts

SW2:	jsr UPDCRC
SW3:	iny		; ANY MORE BYTES?
	beq SW4		; NO, IT WAS 00 UP TO END
	lda (BLKPTR),Y	; LOOK AT NEXT BYTE
	cmp <RLEPREV
	beq SW2		; SAME AS BEFORE, CONTINUE
SW4:	tya		; DIFFERENCE NOT A ZERO
	jsr PUTC	; SEND NEW ADDRESS
	bne SW1		; AND GO BACK TO MAIN LOOP
	dec PAGECNT+1	; Decrement the page counter
	bne SW0		; Loop if more to do
	lda <CRC	; Send the overall CRC
	jsr PUTC
	lda <CRC+1
	jsr PUTC
	inc BLKPTR+1	; Final update of BLKPTR
	rts		; OR RETURN IF NO MORE BYTES


;---------------------------------------------------------
; SENDFN - Send a file name
;
; Assumes input is at IN_BUF
; Returns:
;   length of name in X
;   accumulated check byte in CHECKBYTE
;---------------------------------------------------------
SENDFN:
	ldx #$00
	stx CHECKBYTE	
FNLOOP:	lda IN_BUF,X
	jsr PUTC
	php
	inx
	eor CHECKBYTE
	sta CHECKBYTE
	plp
	bne FNLOOP
	rts

PPROTO:	.byte $01	; Serial protocol = $01
CHECKBYTE:
	.byte 0
BUFPTR:	.addr 0
XFERLEN:
	.addr 0

PUTC:	jmp $0000	; Pseudo-indirect JSR - self-modified
GETC:	jmp $0000	; Pseudo-indirect JSR - self-modified
