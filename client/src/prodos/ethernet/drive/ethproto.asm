;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 by David Schmidt
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

	.import udp_send_nocopy
	.import udp_send
	.import udp_send_len
	.import udp_send_len
	.import ip_inp
	.import udp_inp
	.import udp_outp

	.importzp ip_src
	.importzp udp_src_port
	.importzp udp_data

; Stuff that doesn't have a home yet
	.export output_buffer
BABORT:
	rts

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
	php
	ldx #STATE_IDLE	; Set state back to idle
	stx state
	plp
			; Receiving a CD reply?
	cmp #STATE_CD
	bne :+
;	jmp UPDSKIP
;			; Receiving a PUT reply?
;:	cmp #STATE_PUT
;	bne :+
;	jmp PUTREPLY1
;			; Receiving a GET return code reply?
;:	cmp #STATE_GET
;	bne :+
;	jmp GETREPLY1
;			; Receiving a QUERY FN reply?
;:	cmp #STATE_QUERY
;	bne :+
;	jmp QUERYFNREPLY1
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

TIMEOUT:	.res 1

;---------------------------------------------------------
; PINGREQUEST - Send out a ping
;---------------------------------------------------------
PINGREQUEST:
	lda #STATE_IDLE	; Don't want any reply
	sta state
	lda #CHR_Y
	jsr PUTC
	jsr RECEIVE_LOOP_FAST
	rts

;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	ldax #udp_inp + udp_data + 1	; Point Buffer at the UDP data buffer
	stax Buffer
	ldy #$00
	lda #CHR_C
	sta (Buffer),Y
	iny
	jsr COPYINPUT
	tya			; Max CD request will be 255 bytes
	ldx #$00		; It's unlikely the $200 buffer is
	stax udp_send_len	; much bigger than that anyway...
	lda #STATE_CD
	sta state
	GO_SLOW				; Slow down for SOS
	ldax Buffer
	jsr udp_send
	GO_FAST				; Speed back up for SOS
	jsr RECEIVE_LOOP_FAST
	rts

;---------------------------------------------------------
; CDREPLY - Reply to current directory change
; PUTREPLY - Reply from send an image to the host
; BATCHREPLY - Reply from send multiple images to the host
; GETREPLY - Reply from requesting an image be sent from the host
; One-byte replies
;---------------------------------------------------------
CDREPLY1:
PUTREPLY1:
BATCHREPLY1:
GETREPLY1:
	lda TMOT
	bne @Repl1
	lda udp_inp + udp_data + 1	; Pick up the data byte
	jmp @Repl2
@Repl1:	; Load up timeout indicator
@Repl2:	sta QUERYRC
CDREPLY:
PUTREPLY:
BATCHREPLY:
GETREPLY:
	lda QUERYRC
	rts

GETREPLY2:
	lda #STATE_GET	; Set up for GETREPLY1 callback
	sta state
	jsr RECEIVE_LOOP_FAST
	lda QUERYRC
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
:	inc udp_send_len
	bne :+
	inc udp_send_len+1
:	ldy UDPI	; Restore Y
	plp
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
	GO_SLOW			; Slow down for SOS
	ldax #PUTCMSG
	jsr udp_send
	GO_FAST			; Speed back up for SOS
	rts

;---------------------------------------------------------
; COPYINPUT - Copy data from input area to (Buffer);
; Y is assumed to point to the next available byte
; after (Buffer); Y will point to the next byte on exit
;---------------------------------------------------------
COPYINPUT:
	ldx #$00
@LOOP:	lda IN_BUF,X
	sta (Buffer),Y
	php
	inx
	iny
	plp
	beq @Done
	bne @LOOP
@Done:	rts

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
; Constants
;---------------------------------------------------------
STATE_IDLE	= 0
STATE_DIR	= 1
STATE_CD	= 2
STATE_PUT	= 3
STATE_GET	= 4
STATE_QUERY	= 5
STATE_RECVHBLK	= 6
STATE_SENDHBLK	= 7
STATE_BATCH	= 8

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
QUERYRC:
	.byte $00
PUTCMSG:
	.byte $00
PUTCMSGEND:
PREVPACKET:
	.byte $00
output_buffer:
	.res $0100