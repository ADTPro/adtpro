;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2014 by David Schmidt
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
TIMEY	= $8a
DONE	= $1a
NXTA1	= $FCBA
HEADR	= $FCC9
LASTIN	= $2f
TAPEIN	= $C060
TAPEOUT	= $C020


;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
	stax A2L	; Set everyone up to talk to the AUD_BUFFER
	lda #CHR_C	; Ask host to Change Directory
	jsr FNREQUEST
	lda CHECKBYTE
	jsr BUFBYTE
	ldax UTILPTR
	stax A2L
	jsr aud_send
	rts


;---------------------------------------------------------
; DIRREQUEST - Request current directory contents
; NIBPCNT contains the page number to request
;---------------------------------------------------------
DIRREQUEST:
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
	stax A2L	; Set everyone up to talk to the AUD_BUFFER
	lda #CHR_D	; Send "DIR" command to PC
	jsr FNREQUEST
	lda NIBPCNT
	jsr BUFBYTE
	eor CHECKBYTE
	jsr BUFBYTE
	ldax UTILPTR
	stax A2L
	jsr aud_send
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

	; Borrow Buffer ponter for a minute
	ldax BLKPTR
	stax Buffer 
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
; QUERYFNREQUEST
;---------------------------------------------------------
QUERYFNREQUEST:
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
	lda #CHR_Z	; Ask host for file size
	jsr FNREQUEST
	lda CHECKBYTE
	jsr BUFBYTE
	ldax UTILPTR
	stax A2L
	jsr aud_send
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
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L	; Set everyone up to talk to the AUD_BUFFER
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
	ldax UTILPTR
	stax A2L
	jsr aud_send
	rts


;---------------------------------------------------------
; PUTACKBLK - Send acknowlegedment packet
; X contains the acknowledgement type
;---------------------------------------------------------
PUTACKBLK:
	stx SLOWX
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
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
	ldax UTILPTR
	stax A2L
	jsr aud_send
	rts


;---------------------------------------------------------
; PUTFINALACK - Send error count for requests
;---------------------------------------------------------
PUTFINALACK:
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
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
	ldax UTILPTR
	stax A2L
	jsr aud_send
	rts


;---------------------------------------------------------
; GETREQUEST - Request an image be sent from the host
;---------------------------------------------------------
GETREQUEST:
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
	lda #CHR_G	; Tell host we are Getting/Receiving
	jsr FNREQUEST
	lda BAOCNT
	jsr BUFBYTE	; Express number of blocks at once (BAOCNT)
	eor CHECKBYTE
	jsr BUFBYTE	; Send check byte
	ldax UTILPTR
	stax A2L
	jsr aud_send
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
GETREPLY2:
	jsr GETC
	rts


;---------------------------------------------------------
; BATCHREQUEST - Request to send multiple images to the host
;---------------------------------------------------------
BATCHREQUEST:
	ldax #AUD_BUFFER
	stax BLKPTR
	stax A1L
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

	jsr PUTACKBLK	; Send ack/nak packet for blocks
	jsr RECVWIDE
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
	jsr SENDWIDE
	jsr GETC	; Receive reply
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
	ldy #$00
	sty TMOT	; Clear timeout processing
	ldax #AUD_BUFFER
	stax A1L
	stax UTILPTR

	jsr aud_receive

	ldax #AUD_BUFFER
	stax A1L
	ldx #$00
	lda (A1L,X)
	cmp #CHR_A	; Get protocol - must be an 'A'
	bne RWERR
	jsr NXTA1
	lda (A1L,X)	; Get payload length, LSB
	sta PAGECNT
	sta XFERLEN
	jsr NXTA1
	lda (A1L,X)	; Get payload length, MSB
	sta PAGECNT+1
	sta XFERLEN+1
	jsr NXTA1
	lda (A1L,X)	; Get protocol - must be an 'S'
	cmp #CHR_S
	bne RWERR
	jsr NXTA1
	lda (A1L,X)	; Get protocol - check byte (discarded for the moment)
	jsr NXTA1	; Block number, LSB
	jsr NXTA1	; Block number, MSB
			; TODO - probably should save/check the block number is the one we need...
	lda BLKPTR
	sta BUFPTR
	lda BLKPTR+1
	sta BUFPTR+1
	ldy #$00

RW1:
	jsr NXTA1	; Increment the pointer to data we're reading
	lda (A1L,X)	; Get difference
	beq RW2		; If zero, get new index
	sta (BLKPTR),Y	; else put char in buffer
	iny		; ...and increment index to data we're writing
	bne RW1		; Loop if not at end of buffer
	beq RWNext	; Branch always

RW2:
	jsr NXTA1	; Increment the pointer to data we're reading
	lda (A1L,X)	; Get new index ...
	tay		; ... in the Y register
	bne RW1		; Loop if index <> 0
			; ...else check for more or return

RWNext:	dec PAGECNT+1
	beq @Done	; Done?
	inc BLKPTR+1	; Get ready for another page
	lda BLKPTR+1
	cmp #$c0
	beq RWERR	; Protect ourselves from buffer overrun
	jmp RW1
@Done:
	jsr NXTA1	; Increment the pointer to data we're reading
	lda (A1L,X)	; Done - get CRC
	sta PCCRC
	jsr NXTA1	; Increment the pointer to data we're reading
	lda (A1L,X)	; Done - get CRC
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
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
	ldy #$00	; Start at first byte
	sty <CRC	; Clean out CRC
	sty <CRC+1
	sty <RLEPREV
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
	ldax UTILPTR
	stax A2L
	jsr aud_send
	rts

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
	ldax UTILPTR
	stax A2L
	jsr aud_send
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
	jsr BUFBYTE
	php
	inx
	eor CHECKBYTE
	sta CHECKBYTE
	plp
	bne FNLOOP
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
	ldax #AUD_BUFFER
	stax A1L
	jsr aud_receive
	lda AUD_BUFFER	; Send back whatever we received
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
:	ldy UDPI	; Restore Y
	plp
	rts

;---------------------------------------------------------
; aud_send - Send a packet out the cassette port
;---------------------------------------------------------
aud_send:
	lda #$02	; Only train for a little while - not 10 seconds!
	JSR HEADR	;WRITE 10-SEC HEADER
; Write loop.  Continue until A1 reaches A2.
	LDY #$27
WR1:	LDX #$00
	EOR (A1L,X)
	PHA
	LDA (A1L,X)
	JSR WRBYTE
	JSR NXTA1
	LDY #$1D
	PLA
	BCC WR1
; Write checksum byte, then beep the speaker.
	LDY   #$22
	JSR   WRBYTE
	rts

; Write one byte (8 bits, or 16 half-cycles).
; On exit, Z-flag is set.
WRBYTE:	LDX   #$10
WRBYT2:	ASL
	JSR   WRBIT
	BNE   WRBYT2
	RTS
; Write one bit.  Called from WRITE with Y=$27.
WRBIT:	JSR   ZERDLY     ;WRITE TWO HALF CYCLES
	INY              ;  OF 250 USEC ('0')
	INY              ;  OR 500 USEC ('0')
; Delay for '0'.  X typically holds a bit count or half-cycle count.
; Y holds delay period in 5-usec increments:
;   (carry clear) $21=165us  $27=195us  $2C=220 $4B=375us
;   (carry set) $21=165+250=415us  $27=195+250=445us  $4B=375+250=625us
;   Remember that TOTAL delay, with all other instructions, must equal target
; On exit, Y=$2C, Z-flag is set if X decremented to zero.  The 2C in Y
;  is for WRBYTE, which is in a tight loop and doesn't need much padding.
ZERDLY:	DEY
	BNE   ZERDLY
	BCC   WRTAPE     ;Y IS COUNT FOR
; Additional delay for '1' (always 250us).
	LDY   #$32       ;  TIMING LOOP
ONEDLY:	DEY
	BNE   ONEDLY
; Write a transition to the tape.
WRTAPE:	LDY   TAPEOUT
	LDY   #$2C
	DEX
	RTS

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
; Variables
;---------------------------------------------------------
PPROTO:	.byte $00	; Audio protocol = $00
CHECKBYTE:
	.byte $00
AUD_BUFFER:
	.res  3000,0	; Enough for up to 5 blocks at once
QUERYRC:
	.byte $00
PUTCMSG:
	.byte $00
BUFPTR:	.addr 0
XFERLEN:
	.addr 0