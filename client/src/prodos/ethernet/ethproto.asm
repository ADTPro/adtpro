;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2015 by David Schmidt
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

	.import udp_send
	.import udp_send_internal
	.import udp_send_len
	.import ip_inp
	.import udp_inp
	.import udp_outp

	.importzp ip_src
	.importzp udp_src_port
	.importzp udp_data


;---------------------------------------------------------
; Constants
;---------------------------------------------------------
STATE_IDLE	= 0
STATE_DIR	= 1
STATE_QUERY	= 5
STATE_RECVBLKS	= 6
STATE_WAITING_ONE_BYTE_REPLY = 8


;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	lda #$03
	sta RS_TEMP	; Count of retries	
CDREQUEST_Warm:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #CHR_C			; Ask host to Change Directory
	jsr FNREQUEST
	lda CHECKBYTE
	jsr BUFBYTE
	lda #STATE_WAITING_ONE_BYTE_REPLY
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	bcc :+
	lda TMOT
	beq :+
	dec RS_TEMP
	bne CDREQUEST_Warm
	sec
:	rts


;---------------------------------------------------------
; CDREPLY - Reply to current directory change
; PUTREPLY - Reply from send an image to the host
; BATCHREPLY - Reply from send multiple images to the host
; GETREPLY - Reply from requesting an image be sent from the host
; One-byte replies
;---------------------------------------------------------
ONE_BYTE_REPLY:
PUTREPLY1:
BATCHREPLY1:
GETREPLY2:
	lda #STATE_IDLE
	sta state
	lda TMOT
	bne @Repl1
	lda udp_inp + udp_data + 1	; Pick up the data byte from incoming buffer
	jmp @Repl2
@Repl1:	lda #PHMTIMEOUT			; Load up timeout indicator
@Repl2:	sta QUERYRC
CDREPLY:
PUTREPLY:
BATCHREPLY:
GETREPLY:
	clc
	lda TMOT
	beq @Ok
	sec
@Ok:	lda QUERYRC
	rts


;---------------------------------------------------------
; HOMEREQUEST - Client is entering home state, server should too
;---------------------------------------------------------
HOMEREQUEST:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #CHR_A			; Ask host to Go Home
	jsr BUFBYTE
	lda #$00
	jsr BUFBYTE
	jsr BUFBYTE
	lda #CHR_X			; Ask host to Go Home
	jsr BUFBYTE
	lda #$19			; Pre-calculated checkbyte
	jsr BUFBYTE
	lda #STATE_IDLE
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	rts


;---------------------------------------------------------
; DIRREQUEST - Request current directory contents
; NIBPCNT contains the page number to request
;---------------------------------------------------------
DIRREQUEST:
	lda #$03
	sta RS_TEMP	; Count of retries
	sta QUERYRC	; No success yet
DIRREQUEST_Warm:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP outgoing buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #STATE_DIR	; Set up for DIRREPLY1 callback
	sta state

	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta BLKPTR+1
	; clear out 1k of memory at (BLKPTR) - we don't generally
	; have time to do this between request and reply
	ldx #$04
	LDA_BIGBUF_ADDR_LO	; Connect the block pointer to the
	sta BLKPTR		; Big Buffer(TM), 1k * NIBPCNT
	tay
:	sta (BLKPTR),y
	iny
	bne :-
	inc BLKPTR+1
	dex
	bne :-

	lda #CHR_D	; Send "DIR" command to PC
	jsr FNREQUEST
	lda NIBPCNT
	jsr BUFBYTE
	eor CHECKBYTE
	jsr BUFBYTE
	GO_SLOW			; Slow down for SOS
	jsr udp_send_internal
	GO_FAST			; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST	; Run through DIRREPLY1 callback
	bcc :+
	dec RS_TEMP
	bne DIRREQUEST_Warm
	sec			; Indicate failure
:	rts


;---------------------------------------------------------
; DIRREPLY - serial compatibility and UDP callback entry points
; NIBPCNT contains the page number that was requested - which is 1k-worth of transmission (4 256byte pages, 2 blocks, 2BAO)
; Returns with QUERYRC set to $80 on CRC failure (should retry - nak sent)
; Returns TMOT > 0 on timeout (should not retry)
;---------------------------------------------------------
DIRREPLY1:
	lda #STATE_IDLE
	sta state
	lda TMOT
	bne @DirRetry	
	ldy #$00
	sty PAGECNT
	LDA_BIGBUF_ADDR_LO	; Connect the block pointer to the
	sta BLKPTR		; Big Buffer(TM), 1k * NIBPCNT
	lda #$04
	sta PAGECNT+1
	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta BLKPTR+1

	jsr RECVWIDE_REPLY
	bcs @DirRetry	; Really any failure... time out or garbage received
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
	sta BLKPTR		; Big Buffer(TM), 1k * NIBPCNT again
	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta BLKPTR+1
	lda #$00
	sta QUERYRC
	clc		; Indicate success
	rts

@DirRetry:
	ldx #CHR_NAK
	jsr PUTACKBLK
	sec		; Indicate failure
	rts 

DIRREPLY:
	lda QUERYRC
	clc
	beq :+
	sec
:	rts


;---------------------------------------------------------
; FNREQUEST - Request something with a file name
; Assumes ready to load buffer with BUFBYTE
;---------------------------------------------------------
FNREQUEST:
	pha
	lda #CHR_A	; Envelope
	sta CHECKBYTE
	jsr BUFBYTE
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
	jsr BUFBYTE	; Payload length - lsb
	eor CHECKBYTE
	sta CHECKBYTE
	lda #$00
	jsr BUFBYTE	; Payload length - msb
			; No need to update checksum... eor with 0 makes no change
	pla		; Pull the request byte
	jsr BUFBYTE
	eor CHECKBYTE
	sta CHECKBYTE
	jsr BUFBYTE	; Send the check byte for envelope
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
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda SendType
	jsr FNREQUEST
	lda NUMBLKS	; Send the total block size
	jsr BUFBYTE
	eor CHECKBYTE
	sta CHECKBYTE
	lda NUMBLKS+1
	jsr BUFBYTE
	eor CHECKBYTE
	jsr BUFBYTE	; Send check byte
	lda #STATE_WAITING_ONE_BYTE_REPLY
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	rts


;---------------------------------------------------------
; PUTACKBLK - Send acknowlegedment packet
; X contains the acknowledgement type
;---------------------------------------------------------
PUTACKBLK:
	stx SLOWX
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #CHR_A	; Envelope
	jsr BUFBYTE
	lda #$03	; Three byte payload
	jsr BUFBYTE
	lda #$00
	jsr BUFBYTE
	lda #CHR_K	; Acknowledgement packet
	jsr BUFBYTE	; Send ack type
	lda #$09	; Pre-calculted check byte
	jsr BUFBYTE	; Send check byte
	lda SLOWX	; Grab the ack type 
	jsr BUFBYTE
	sta CHECKBYTE
	lda BLKLO	; Send the current block number LSB
	jsr BUFBYTE
	eor CHECKBYTE
	sta CHECKBYTE
	lda BLKHI	; Send the current block number MSB
	jsr BUFBYTE
	eor CHECKBYTE
	jsr BUFBYTE	; Send check byte
	GO_SLOW		; Slow down for SOS
	jsr udp_send_internal
	GO_FAST		; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	rts


;---------------------------------------------------------
; PUTFINALACK - Send error count for requests
;---------------------------------------------------------
PUTFINALACK:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #CHR_A
	jsr BUFBYTE	; Wide protocol - 'A'
	lda #$01
	jsr BUFBYTE	; Wide protocol - lsb of bytes to expect
	lda #$00
	jsr BUFBYTE	; Wide protocol - msb of bytes to expect
	lda #CHR_Y	; Wide protocol - 'Y'
	jsr BUFBYTE
	lda #$19
	jsr BUFBYTE
	lda ECOUNT	; Errors during send?
	jsr BUFBYTE
	jsr BUFBYTE	; Check byte will be the same thing
	lda #STATE_IDLE	; Not requiring a reply
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	rts


;---------------------------------------------------------
; GETREQUEST -
;---------------------------------------------------------
GETREQUEST:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #CHR_G	; Tell host we are Getting/Receiving
	jsr FNREQUEST
	lda BAOCNT
	jsr BUFBYTE	; Express number of blocks at once (BAOCNT)
	eor CHECKBYTE
	jsr BUFBYTE	; Send check byte
	lda #STATE_WAITING_ONE_BYTE_REPLY
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
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
; QUERYFNREQUEST
;---------------------------------------------------------
QUERYFNREQUEST:
	lda #$03
	sta RS_TEMP	; Count of retries
QUERYFNREQUEST_Warm:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP outgoing data buffer
	stax UTILPTR
	lda #$00
	sta udp_send_len
	sta udp_send_len+1
	lda #CHR_Z		; Ask host for file size
	jsr FNREQUEST
	lda CHECKBYTE
	jsr BUFBYTE
	lda #STATE_QUERY	; Set up for the QUERYFNREPLY1 callback
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	bcc :+
	lda TMOT
	beq :+
	dec RS_TEMP
	bne QUERYFNREQUEST_Warm
	sec
:	rts


;---------------------------------------------------------
; QUERYFNREPLY -
;---------------------------------------------------------
QUERYFNREPLY1:
	lda #STATE_IDLE
	sta state
	lda TMOT
	bne :+
	lda udp_inp + udp_data + 1	; File size lsb
	sta HOSTBLX
	lda udp_inp + udp_data + 2	; File size msb
	sta HOSTBLX+1
	lda udp_inp + udp_data + 3	; Return code/message
	sta QUERYRC			; Just some temp storage
	jmp QFNOk
:	lda #PHMTIMEOUT
	sta QUERYRC
QUERYFNREPLY:
	lda TMOT
	beq QFNOk
	sec
	jmp QFNDone
QFNOk:	clc
QFNDone:
	lda QUERYRC
QUERYFNREPLYDONE:
	rts


;---------------------------------------------------------
; RECVBLKS - Receive blocks with RLE
;
; BLKPTR points to starting block to receive - updated here
;---------------------------------------------------------
RECVBLKS:
	lda #$03
	sta RS_TEMP	; Count of retries
	sta QUERYRC	; No success yet
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

	ldy #$00
	sty TMOT	; Clear timeout processing
	lda #STATE_RECVBLKS	; Set up to be called back at RECVWIDE_REPLY
	sta state
	jsr PUTACKBLK	; Send ack/nak packet for blocks; callback runs through RECVWIDE_REPLY
	lda QUERYRC
	bne RECVERR
	lda <CRC
	cmp PCCRC
	bne RECVERR
	lda <CRC+1
	cmp PCCRC+1
	bne RECVERR
	clc		; Indicate success
	rts

RECVERR:
	dec RS_TEMP	; Retry if we have retries left
	bne :+
	sec		; No retries remain - indicate failure and return
	rts
:	ldx #CHR_NAK	; CRC error, ask for a resend
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
	lda #$03
	sta RS_TEMP	; Count of retries
	lda BLKPTR+1
	sta SCOUNT	; Stash the msb of BLKPTR, which SENDWIDE trashes
@S2:	lda #$00
	sta PAGECNT
	lda BAOCNT
	asl		; Convert blocks to pages
	sta PAGECNT+1
@SendAgain:
	lda SCOUNT	; Restore BLKPTR msb when looping
	sta BLKPTR+1
	jsr SENDWIDE	; Pushes blocks out and runs callback ONE_BYTE_REPLY
	jsr PUTREPLY	; Retrieve results from ONE_BYTE_REPLY
	bcs @SendTimeout
	cmp #CHR_ACK	; Is it ACK?  Loop back if NAK.
	bne @SendTimeout
	clc
	rts
@SendTimeout:
	dec RS_TEMP
	lda RS_TEMP
	bne @S2
	sec		; Indicate failure
	rts


;---------------------------------------------------------
; RECVWIDE - Receive a chunk of data
; BLKPTR - in - points at buffer to save to
; PAGECNT is used as 2-byte value of length to ultimately receive
; CRC is computed and stored
;---------------------------------------------------------
RECVWIDE_REPLY:
	lda #STATE_IDLE
	sta state
	ldax #udp_inp + udp_data + 1	; Point Buffer at the incoming UDP data buffer
	stax <A1L
	ldx #$00
	lda (<A1L,X)
	cmp #CHR_A	; Get protocol - must be an 'A'
	bne RWERR
	jsr BumpA1
	lda (<A1L,X)	; Get payload length, LSB
	sta PAGECNT
	sta XFERLEN
	jsr BumpA1
	lda (<A1L,X)	; Get payload length, MSB
	sta PAGECNT+1
	sta XFERLEN+1
	jsr BumpA1
	lda (<A1L,X)	; Get protocol - must be an 'S'
	cmp #CHR_S
	beq RWSOK	; 'S' it is... go ahead
	cmp #CHR_X	; Told to go home?
	bne RWERR	; No... retry because of generic error
	jmp BABORT	; Go home!
RWSOK:	jsr BumpA1
	lda (<A1L,X)	; Get protocol - check byte (discarded for the moment)
	jsr BumpA1	; Block number, LSB
	lda (<A1L,X)
	sta HOSTBLX
	jsr BumpA1	; Block number, MSB
	lda (<A1L,X)
	sta HOSTBLX+1
	lda BLKPTR
	sta BUFPTR
	lda BLKPTR+1
	sta BUFPTR+1
	ldy #$00

RW1:
	jsr BumpA1	; Increment the pointer to data we're reading
	lda (<A1L,X)	; Get difference
	beq RW2		; If zero, get new index
	sta (BLKPTR),Y	; else put char in buffer
	iny		; ...and increment index to data we're writing
	bne RW1		; Loop if not at end of buffer
	beq RWNext	; Branch always

RW2:
	jsr BumpA1	; Increment the pointer to data we're reading
	lda (<A1L,X)	; Get new index ...
	tay		; ... in the Y register
	bne RW1		; Loop if index <> 0
			; ...else check for more or return

RWNext:	dec PAGECNT+1
	beq RWDone	; Done?
	inc BLKPTR+1	; Get ready for another page
	lda BLKPTR+1
	cmp #$c0
	beq RWERR	; Protect ourselves from buffer overrun
	jmp RW1
RWERR:
	sec
	rts

RWDone:
	jsr BumpA1	; Increment the pointer to data we're reading
	lda (<A1L,X)	; Done - get CRC lsb
	sta PCCRC
	jsr BumpA1	; Increment the pointer to data we're reading
	lda (<A1L,X)	; Done - get CRC msb
	sta PCCRC+1
	lda XFERLEN+1
	sta PAGECNT+1
	lda BUFPTR
	sta BLKPTR
	lda BUFPTR+1
	sta BLKPTR+1
	jsr UNDIFFWide
	lda #$00
	sta QUERYRC
	clc
	rts


;---------------------------------------------------------
; SENDWIDE - Send a chunk of data
;   BLKLO/BLKHI - in - block number to start with
;   BLKPTR points to data to send
;   PAGECNT holds the number of bytes to send
;---------------------------------------------------------
SENDWIDE:
	ldax #udp_outp + udp_data	; Point UTILPTR at the UDP data buffer
	stax UTILPTR
	ldy #$00	; Start at first byte
	sty <CRC	; Clean out CRC
	sty <CRC+1
	sty <RLEPREV
	sty udp_send_len
	sty udp_send_len+1
	lda #CHR_A
	jsr BUFBYTE	; Wide protocol - 'A'
	sta CHECKBYTE
	lda PAGECNT
	jsr BUFBYTE	; Wide protocol - lsb of bytes to expect
	eor CHECKBYTE
	sta CHECKBYTE
	lda PAGECNT+1
	jsr BUFBYTE	; Wide protocol - msb of bytes to expect
	eor CHECKBYTE
	sta CHECKBYTE
	lda #CHR_S	; Wide protocol - 'S'
	jsr BUFBYTE
	eor CHECKBYTE
	jsr BUFBYTE	; Send check byte of envelope
	lda BLKLO
	jsr BUFBYTE	; Send the block number (LSB)
	lda BLKHI
	jsr BUFBYTE	; Send the block number (MSB)
	dec BLKPTR+1	; Pre-decrement since the top of the loop increments the block pointer

SW0:	inc BLKPTR+1
SW1:	lda (BLKPTR),Y	; GET BYTE TO SEND
	jsr UPDCRC	; UPDATE CRC
	tax		; KEEP A COPY IN X
	sec		; SUBTRACT FROM PREVIOUS
	sbc <RLEPREV
	stx <RLEPREV	; SAVE PREVIOUS BYTE
	jsr BUFBYTE	; SEND DIFFERENCE
	beq SW3		; WAS IT A ZERO?
	iny		; NO, DO NEXT BYTE
	bne SW1		; LOOP IF MORE TO DO
	dec PAGECNT+1	; Decrement the page counter
	bne SW0		; Loop if more to do
	lda <CRC	; Send the overall CRC
	jsr BUFBYTE
	lda <CRC+1
	jsr BUFBYTE
	inc BLKPTR+1	; Final update of BLKPTR
	jmp SWGo

SW2:	jsr UPDCRC
SW3:	iny		; ANY MORE BYTES?
	beq SW4		; NO, IT WAS 00 UP TO END
	lda (BLKPTR),Y	; LOOK AT NEXT BYTE
	cmp <RLEPREV
	beq SW2		; SAME AS BEFORE, CONTINUE
SW4:	tya		; DIFFERENCE NOT A ZERO
	jsr BUFBYTE	; SEND NEW ADDRESS
	bne SW1		; AND GO BACK TO MAIN LOOP
	dec PAGECNT+1	; Decrement the page counter
	bne SW0		; Loop if more to do
	lda <CRC	; Send the overall CRC
	jsr BUFBYTE
	lda <CRC+1
	jsr BUFBYTE
	inc BLKPTR+1	; Final update of BLKPTR

SWGo:	lda #STATE_WAITING_ONE_BYTE_REPLY ; Set up to be called back with a single byte reply
	sta state
	GO_SLOW				; Slow down for SOS
	jsr udp_send_internal
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	rts


;---------------------------------------------------------
; BUFBYTE
; Add accumulator to the outgoing packet
; UTILPTR points to the next byte we're going to save - and keeps a running total
;---------------------------------------------------------
BUFBYTE:
	php
	sty UDPI	; Store Y for safe keeping
	ldy #$00
	sta (UTILPTR),Y
	inc UTILPTR
	bne :+
	inc UTILPTR+1
:	inc udp_send_len
	bne :+
	inc udp_send_len+1
:	ldy UDPI	; Restore Y
	plp
	rts



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
	jsr BUFBYTE
	php
	inx
	eor CHECKBYTE
	sta CHECKBYTE
	plp
	bne FNLOOP
	rts


;---------------------------------------------------------
; PUTC - Send a single byte as a packet
;---------------------------------------------------------
PUTC:
				; Note: the first byte of
				; this routine needs to be
				; kept in sync with the
				; byte kept in uther.asm,
	sta PUTCMSG		; PATCHUTHER.
	ldax #PUTCMSGEND-PUTCMSG
	stax udp_send_len
	ldax #PUTCMSG
	jsr udp_send
	rts


;---------------------------------------------------------
; PINGREQUEST
;---------------------------------------------------------
PINGREQUEST:
	rts


;---------------------------------------------------------
; COPYINPUT - Copy data from input area to (UTILPTR);
; Y is assumed to point to the next available byte
; after (UTILPTR); Y will point to the next byte on exit
;---------------------------------------------------------
COPYINPUT:
	ldx #$00
@LOOP:	lda IN_BUF,X
	sta (UTILPTR),Y
	php
	inx
	iny
	plp
	beq @Done
	bne @LOOP
@Done:	rts


;---------------------------------------------------------
; UDPDISPATCH - Dispatch the UDP packet to the receiver
;---------------------------------------------------------
UDPDISPATCH:
	lda state
	cmp #STATE_IDLE		; Do we care at all?
	beq UDPSKIP

	lda TMOT
	bne TIMEOUTENTRY	; Skip packet processing if timeout occurred

	lda udp_inp + udp_data	; Grab the packet number
	cmp PREVPACKET
	beq UDPSKIP		; We received a duplicate packet.  Bail.
	sta PREVPACKET

	lda udp_inp + udp_src_port + 1
	sta replyport
	lda udp_inp + udp_src_port
	sta replyport + 1

	ldx #3
:	lda ip_inp + ip_src,x
	sta replyaddr,x
	dex
	bpl :-

TIMEOUTENTRY:
	lda state
;	php
;	ldx #STATE_IDLE	; Set state back to idle
;	stx state
;	plp

			; Receiving a DIR reply?
	cmp #STATE_DIR
	bne :+
	jmp DIRREPLY1
			; Receiving a one-byte reply?
:	cmp #STATE_WAITING_ONE_BYTE_REPLY
	bne :+
	jmp ONE_BYTE_REPLY
			; Receiving a QUERY FN reply - multiple bytes?
:	cmp #STATE_QUERY
	bne :+
	jmp QUERYFNREPLY1
			; Receiving block data - tons of bytes?
:	cmp #STATE_RECVBLKS
	bne :+
	jmp RECVWIDE_REPLY
:			; fallthrough	
UDPSKIP:
	rts


;---------------------------------------------------------
; RECEIVE_LOOP - Wait for an incoming packet to come along
; 
;---------------------------------------------------------
RECEIVE_LOOP_FAST:
	lda #$1f
	sta PauseValue+1	; Short pause
	lda #$00
	jmp RECEIVE_LOOP_ENTRY2

RECEIVE_LOOP:
				; Note: the first byte of
				; this routine needs to be
				; kept in sync with the
				; byte kept in uther.asm,
	lda #$00		; PATCHUTHER.
	sta PauseValue+1	; Long pause
RECEIVE_LOOP_ENTRY2:
	sta TIMEOUT
	sta TMOT

RECEIVE_LOOP_WARM:
	GO_SLOW		; Slow down for SOS
	jsr ip65_process
	GO_FAST		; Speed back up for SOS
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	bne :+
	jmp BABORT
:	bit $c010	; Strobe the keyboard
	inc TIMEOUT	; Increment our counter
	bne :+
	inc TMOT
	jsr UDPDISPATCH
	rts

:	lda state
	cmp #STATE_IDLE		; Are we done/idle now?
	bne RECEIVE_LOOP_PAUSE	; No, so pause a bit then retry
	rts

RECEIVE_LOOP_PAUSE:
	lda #$5a
	sta $c05a
	sta $c05a
	sta $c05a
	sta $c05a	; Unlock ZipChip

	lda #$00
	sta $c05a	; Disable ZipChip	

	lda #$01
	sta $C074	; Disable TransWarp

PauseValue:
	lda #$7f
	jsr DELAY	; Wait!

	lda #$00
	sta $c05b	; Enable ZipChip

	lda #$a5
	sta $c05a	; Lock ZipChip

	lda #$00	; Enable TransWarp
	sta $C074

	jmp RECEIVE_LOOP_WARM


;---------------------------------------------------------
; DEBUGMSG - Handy debug routine to print and scroll "you are here"
; messages
;---------------------------------------------------------
;DEBUGMSG:
;	sty SLOWY
;	stx SLOWX
;	pha		; Save the byte to print
;	lda CH
;	sta CH_SAV
;	lda CV
;	sta CV_SAV
;
;	ldy #$00
; :
;	; Scroll messages
;	lda $0480,y	; Line 2
;	sta $0400,y	; Line 1
;	lda $0500,y	; Line 3
;	sta $0480,y	; Line 2
;	lda $0580,y	; Line 4
;	sta $0500,y	; Line 3
;	lda $0600,y	; Line 5
;	sta $0580,y	; Line 4
;	lda $0680,y	; Line 6
;	sta $0600,y	; Line 5
;	lda $0700,y	; Line 7
;	sta $0680,y	; Line 6
;	lda $0780,y	; Line 8
;	sta $0700,y	; Line 7
;	lda $0428,y	; Line 9
;	sta $0780,y	; Line 8
;	lda $04a8,y	; Line 10
;	sta $0428,y	; Line 9
;	lda $0528,y	; Line 11
;	sta $04a8,y	; Line 10
;	lda $05a8,y	; Line 12
;	sta $0528,y	; Line 11
;	lda $0628,y	; Line 13
;	sta $05a8,y	; Line 12
;	; break for progress bar here - five lines
;	lda $0550,y	; Line 19
;	sta $0628,y	; Line 13
;	lda $05d0,y	; Line 20
;	sta $0550,y	; Line 19
;	lda $0650,y	; Line 21
;	sta $05d0,y	; Line 20
;	lda $06d0,y	; Line 22
;	sta $0650,y	; Line 21
;	lda $0750,y	; Line 23
;	sta $06d0,y	; Line 22
;	lda $07d0,y	; Line 24
;	sta $0750,y	; Line 23
;
;	iny
;	cpy #$06
;	bne :-
;
;	lda #$00
;	sta CH
;	lda #$17
;	jsr TABV
;
;	pla		; Retrieve the "you are here" byte to print
;	jsr PRBYTE
;	lda #CHR_SP
;	jsr COUT1
;	lda state	; Retrieve the state
;	jsr PRBYTE
;
;	lda CH_SAV
;	sta CH
;	lda CV_SAV
;	sta CV
;	jsr TABV
;	ldy SLOWY
;	ldx SLOWX
;	rts
;
;CH_SAV:	.byte $00
;CV_SAV:	.byte $00

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
PPROTO:	.byte $03	; Ethernet protocol = $03
CHECKBYTE:
	.byte $00
QUERYRC:
	.byte $00
PUTCMSG:
	.byte $00
PUTCMSGEND:
PREVPACKET:
	.byte $00
BUFPTR:	.addr 0
XFERLEN:
	.addr 0
TIMEOUT:	.res 1
