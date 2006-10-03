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

;	.import udp_send
;	.import udp_send_len

;---------------------------------------------------------
; UDPDISPATCH - Dispatch the UDP packet to the receiver
;---------------------------------------------------------
UDPDISPATCH:
	lda state
	cmp #STATE_IDLE	; Do we care at all?
	beq @skip

	lda udp_inp + udp_src_port + 1
	sta replyport
	lda udp_inp + udp_src_port
	sta replyport + 1

	ldx #3
:	lda ip_inp + ip_src,x
	sta replyaddr,x
	dex
	bpl :-

	lda state
	php
	ldx #STATE_IDLE	; Set state back to idle
	stx state
	plp
			; Receiving a DIR reply?
	cmp #STATE_DIR
	bne :+
	jmp DIRREPLY1
			; Receiving a CD reply?
:	cmp #STATE_CD
	bne :+
	jmp CDREPLY1
			; Receiving a PUT reply?
:	cmp #STATE_PUT
	bne :+
	jmp PUTREPLY1
			; Receiving a GET return code reply?
:	cmp #STATE_GET
	bne :+
	jmp GETREPLY1
			; Receiving a QUERY FN reply?
:	cmp #STATE_QUERY
	bne :+
	jmp QUERYFNREPLY1
			; Receiving HBLK data?
:	cmp #STATE_HBLK
	bne :+
	jmp RECVHBLK
			; Receiving HBLK_2 data?
:	cmp #STATE_HBLK_2
	bne :+
	jmp RECVBLK2
	brk
			; fallthrough	
@skip:
	rts

;---------------------------------------------------------
; RECEIVE_LOOP - Wait for an incoming packet to come along
;---------------------------------------------------------
RECEIVE_LOOP:
	jsr ip65_process
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	bne :+
	jmp BABORT
:	lda state
	cmp #STATE_IDLE
	bne RECEIVE_LOOP
	rts

;---------------------------------------------------------
; DIRREQUEST - Request current directory contents
;---------------------------------------------------------
DIRREQUEST:
	lda #STATE_DIR	; Set up for DIRREPLY1 callback
	sta state
	lda #CHR_D
	jsr PUTC
	jmp RECEIVE_LOOP

;---------------------------------------------------------
; DIRREPLY - serial compatibility and UDP callback entry points
;---------------------------------------------------------
DIRREPLY1:
	ldax #udp_inp + udp_data
	stax BLKPTR
DIRREPLY:
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
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_C
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	tya			; Max CD request will be 255 bytes
	ldx #$00		; It's unlikely the $200 buffer is
	stax udp_send_len	; much bigger than that anyway...
	lda #STATE_CD
	sta state
	ldax #BIGBUF
	jsr udp_send
	jmp RECEIVE_LOOP

;---------------------------------------------------------
; CDREPLY - Reply to current directory change
; PUTREPLY - Reply from send an image to the host
; GETREPLY - Reply from requesting an image be sent from the host
; One-byte replies
;---------------------------------------------------------
CDREPLY1:
PUTREPLY1:
GETREPLY1:
	lda udp_inp + udp_data	; Pick up the data byte
	sta QUERYRC
CDREPLY:
PUTREPLY:
GETREPLY:
	lda QUERYRC
	rts

;---------------------------------------------------------
; PUTREQUEST -
;---------------------------------------------------------
PUTREQUEST:
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_P		; Tell host we are Putting/Sending
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	iny
	lda NUMBLKS	; Send the total block size
	sta (BLKPTR),Y
	iny
	lda NUMBLKS+1
	sta (BLKPTR),Y
	tya
	ldx #$00
	stax udp_send_len
	lda #STATE_PUT
	sta state
	ldax #BIGBUF
	jsr udp_send
	jmp RECEIVE_LOOP

;---------------------------------------------------------
; PUTINITIALACK -
;---------------------------------------------------------
PUTINITIALACK:
	ldax #ACKEND-ACKMSG
	stax udp_send_len
	ldax #ACKMSG
	jsr udp_send
	rts

;---------------------------------------------------------
; PUTFINALACK -
;---------------------------------------------------------
PUTFINALACK:
	lda #$00
	ldx #$01
	stax udp_send_len
	ldax #ECOUNT	; Errors during send?
	jsr udp_send
	rts

;---------------------------------------------------------
; GETREQUEST -
;---------------------------------------------------------
GETREQUEST:
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_G	; Ask host to send the file
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	tya
	ldx #$00
	stax udp_send_len
	lda #STATE_GET	; Set up for GETREPLY1 callback
	sta state
	ldax #BIGBUF
	jsr udp_send
	jmp RECEIVE_LOOP

;---------------------------------------------------------
; GETFINALACK -
;---------------------------------------------------------
GETFINALACK:
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_ACK	; Send last ACK
	sta (BLKPTR),Y
	iny
	lda ECOUNT	; Errors during send?
	sta (BLKPTR),Y
	iny
	tya
	ldx #$00
	stax udp_send_len
	ldax #BIGBUF
	jsr udp_send
	rts

;---------------------------------------------------------
; QUERYFNREQUEST
;---------------------------------------------------------
QUERYFNREQUEST:
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_Z	; Ask host for file size
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	tya
	ldx #$00
	stax udp_send_len
	lda #STATE_QUERY	; Set up for the QUERYFNREPLY callback
	sta state
	ldax #BIGBUF
	jsr udp_send
	jmp RECEIVE_LOOP

;---------------------------------------------------------
; QUERYFNREPLY -
;---------------------------------------------------------
QUERYFNREPLY1:
	lda udp_inp + udp_data		; File size lsb
	sta HOSTBLX
	lda udp_inp + udp_data + 1	; File size msb
	sta HOSTBLX+1
	lda udp_inp + udp_data + 2	; Return code/message
	sta QUERYRC			; Just some temp storage
QUERYFNREPLY:
	lda QUERYRC
	rts

;---------------------------------------------------------
; SENDBLK -
;---------------------------------------------------------
SENDBLK:
; TODO
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

	lda #STATE_HBLK	; Set up callback to RECVHBLK
	sta state
	jmp RECEIVE_LOOP

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
	jmp RECVMORE

ACK_CHAR: .byte CHR_ACK

;---------------------------------------------------------
; RECVHBLK - Receive half a block with RLE
;
; CRC is computed and stored
;---------------------------------------------------------
RECVHBLK:
	ldax #udp_inp + udp_data
	stax UTILPTR	; Connect UTILPTR to UDP packet buffer
	ldx #00		; Start input at beginning of UTILPTR buffer
	ldy #00		; Start output at beginning of BLKPTR buffer
RC1:
	lda (UTILPTR,X)	; Get next byte out of UDP packet buffer
	beq RC2		; If zero, get new index
	sta (BLKPTR),Y	; else put char in buffer
	iny		; ...and increment index
	inx		; ...and increment index
	bne RC1		; Loop if not at end of buffer
	jmp RCVEND	; ...else done
RC2:
	inx		; ...and increment index
	lda (UTILPTR,X)	; Get next byte out of UDP packet buffer - the next index
	tay		; in the Y register
	bne RC1		; Loop if index <> 0
			; ...else done
RCVEND:
	cpx #$00
	bne :+
	inc UTILPTR+1	; Point at next 256 bytes
:	lda (UTILPTR,X)	; Get next byte out of UDP packet buffer
	sta PCCRC	; Receive the CRC of that block
	inx
	cpx #$00
	bne :+
	inc UTILPTR+1	; Point at next 256 bytes
:	lda (UTILPTR,X)	; Get next byte out of UDP packet buffer
	sta PCCRC+1
	lda STATE_HBLK_2; Set up callback to RECVBLK2
	sta state
	jmp RECEIVE_LOOP

;---------------------------------------------------------
; PUTC - Send a single byte as a packet
;---------------------------------------------------------
PUTC:
	sta PUTCMSG
	ldax #PUTCMSGEND-PUTCMSG
	stax udp_send_len
	ldax #PUTCMSG
	jsr udp_send
	rts

;---------------------------------------------------------
; COPYINPUT - Copy data from input area to (BLKPTR);
; Y is assumed to point to the next available byte
; after (BLKPTR)
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
; Constants
;---------------------------------------------------------
STATE_IDLE	= 0
STATE_DIR	= 1
STATE_CD	= 2
STATE_PUT	= 3
STATE_GET	= 4
STATE_QUERY	= 6
STATE_HBLK	= 8
STATE_HBLK_2	= 9

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
QUERYRC:
	.byte $00
PUTCMSG:
	.byte $00
PUTCMSGEND:
ABORTMSG:
	.byte $00
ABORTEND:
ACKMSG:
	.byte CHR_ACK
ACKEND: