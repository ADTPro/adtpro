;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 - 2016 by David Schmidt
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
			; Receiving a block read reply?
	cmp #STATE_BLKREAD
	bne :+
	jmp BLKREAD_REPLY1
			; Receiving a block write reply?
:	cmp #STATE_BLKWRITE
	bne :+
	jmp BLKWRITE_REPLY1
			; Receiving an envelope reply?
:	cmp #STATE_ENVELOPE
	bne :+
	jmp ENVELOPE_REPLY
:			; fallthrough	
UDPSKIP:
	rts

;---------------------------------------------------------
; RECEIVE_LOOP - Wait for an incoming packet to come along
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
	bne @keyb
	jmp PABORT
@keyb:	bit $c010	; Strobe the keyboard
	inc TIMEOUT	; Increment our counter
	bne :+
	inc TMOT
	sec
	rts

:	lda state
	cmp #STATE_IDLE		; Are we done/idle now?
	bne RECEIVE_LOOP_PAUSE	; No, so pause a bit then retry
	clc
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
	jsr MYDELAY	; Wait!

	lda #$00
	sta $c05b	; Enable ZipChip

	lda #$a5
	sta $c05a	; Lock ZipChip

	lda #$00	; Enable TransWarp
	sta $C074

	jmp RECEIVE_LOOP_WARM

TIMEOUT:	.res 1

udp_fail:
READFAIL:
	GO_SLOW			; Slow down for SOS
	jsr	ip65_process
	jsr	ip65_process	; Get the hammer out... drain the UDP pipe
	jsr	ip65_process
	GO_FAST			; Speed back up for SOS
	sec
	rts

;---------------------------------------------------------
; READBLK - Read a block
;---------------------------------------------------------
READBLK:
; SEND COMMAND TO PC
; Grab the screen contents, remember it
	lda	SCRN_THROB
	sta	SCREEN_CONTENTS
	lda	#$03		; Read command w/time request - command will be either 3 or 5
	clc
	adc	UNIT2		; Command will be #$05 for unit 2
	sta	OS_COMMAND
	jsr	COMMAND_ENVELOPE
	bcs	READFAIL

; READ BLOCK AND VERIFY
	ldax	#udp_inp + udp_data + 10	; Point past the command envelope
	stax	UTILPTR
	ldx	#$00
	ldy	#$00
	stx	SCRN_THROB
RDLOOP:
	lda	(UTILPTR),Y
	sta	(BUFLO),Y
	iny
	bne	RDLOOP

	inc	BUFHI
	inc	UTILPTR+1
	inx
	stx	SCRN_THROB
	cpx	#$02
	bne	RDLOOP

	dec	BUFHI
	dec	BUFHI	; Bring BUFHI back down to where it belongs

	lda	SCREEN_CONTENTS	; Restore screen contents
	sta	SCRN_THROB

	lda	(UTILPTR),Y	; Checksum
	pha		; Push checksum for now
	jsr	CALC_CHECKSUM
	pla	
	cmp	CHECKSUM
	bne	READFAIL
	lda	#$00
	clc
	rts

;---------------------------------------------------------
; WRITEBLK - Write a block
;---------------------------------------------------------
WRITEBLK:
; SEND COMMAND TO PC
; Grab the screen contents, remember it
	lda	SCRN_THROB
	sta	SCREEN_CONTENTS

	lda	#$02		; Write command
	clc
	adc	UNIT2
	sta	OS_COMMAND

	jsr	COMMAND_ENVELOPE
	bcs	WRITEFAIL

	lda	SCREEN_CONTENTS	; Restore screen contents
	sta	SCRN_THROB

	clc
	rts

WRITEFAIL:
	jmp	udp_fail

;---------------------------------------------------------
; COMMAND_ENVELOPE - Send a command envelope (read/write) with the command in the accumulator
;---------------------------------------------------------
COMMAND_ENVELOPE:
	pha			; Hang on to the command for a sec...
	ldy	#$00
	sty	SCRN_THROB
	sty	udp_send_len
	sty	udp_send_len+1
	ldax	#udp_outp + udp_data
	stax	UTILPTR
	lda	#CHR_E
	jsr	BUFBYTE		; Envelope
	sta	CHECKSUM
	pla			; Pull the command back off the stack
	jsr	BUFBYTE		; Send command
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKLO
	jsr	BUFBYTE		; Send LSB of requested block
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKHI
	jsr	BUFBYTE		; Send MSB of requested block
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	BUFBYTE		; Send envelope checksum
	lda	OS_COMMAND	; Depending on read or write...
	cmp	#$03
	beq	ENV_DONE	; We have a read request, so move past the write
	cmp	#$05
	beq	ENV_DONE	; We have a read request, so move past the write

; Copy in the block to write
	ldx	#$00
	ldy	#$00
WRLOOP:
	lda	(BUFLO),Y
	sta	(UTILPTR),Y
	iny
	bne	WRLOOP

	inc	BUFHI
	inc	UTILPTR+1
	inx
	stx	SCRN_THROB
	cpx	#$02
	bne	WRLOOP

	inc	udp_send_len+1	; Since we're sending 512 more bytes,
	inc	udp_send_len+1	; bump the send length MSB twice

	dec	BUFHI
	dec	BUFHI	; Bring BUFHI back down to where it belongs

	jsr	CALC_CHECKSUM
	jsr	BUFBYTE			; Send the checksum byte

ENV_DONE:
	jsr	udp_send_internal
	lda	#STATE_ENVELOPE	; Set up for an envelope reply
	sta	state
	jsr	RECEIVE_LOOP_FAST
	clc
	rts

;---------------------------------------------------------
; ENVELOPE_REPLY - Received a reply to command envelope
;---------------------------------------------------------
ENVELOPE_REPLY:
; READ ECHO'D COMMAND AND VERIFY
	lda	TMOT
	bne	env_fail
	lda	udp_inp + udp_data + 1	; Check the Envelope byte
	cmp	#CHR_E			; Envelope command
	bne	env_fail
	lda	udp_inp + udp_data + 2	; Check the command byte
	cmp	OS_COMMAND		; Local storage for command type
	bne	env_fail
	lda	udp_inp + udp_data + 3	; Pick up the LSB of the requested block
	cmp	BLKLO
	bne	env_fail
	lda	udp_inp + udp_data + 4	; Pick up the MSB of the requested block
	cmp	BLKHI
	bne	env_fail
	lda	OS_COMMAND
	cmp	#$03			; Is the command to read?
	beq	pull_time		; Then pull the time out too
	cmp	#$05			; Is the command to read?
	beq	pull_time		; Then pull the time out too
	lda	udp_inp + udp_data + 5	; Pick up the checksum 
	cmp	CHECKSUM		; Compare to what we calculated outgoing
	bne	env_fail		; Not equal?  Fail!
env_done:
	lda	#$00
	clc
	rts	
env_fail:
	jmp	udp_fail

pull_time:
	lda	udp_inp + udp_data + 5	; LSB of time
	sta	TEMPDT
	eor	CHECKSUM
	sta	CHECKSUM
	lda	udp_inp + udp_data + 6	; MSB of time
	sta	TEMPDT+1
	eor	CHECKSUM
	sta	CHECKSUM
	lda	udp_inp + udp_data + 7	; LSB of date
	sta	TEMPDT+2
	eor	CHECKSUM
	sta	CHECKSUM
	lda	udp_inp + udp_data + 8	; MSB of date
	sta	TEMPDT+3
	eor	CHECKSUM
	sta	CHECKSUM
	lda	udp_inp + udp_data + 9	; Pick up the checksum 
	cmp	CHECKSUM
	bne	env_fail
	lda	TEMPDT			; Copy in the date and time
	sta	TIME			;   since it had the correct checksum
	lda	TEMPDT+1
	sta	TIME+1
	lda	TEMPDT+2
	sta	DATE
	lda	TEMPDT+3
	sta	DATE+1
	jmp	env_done	

;---------------------------------------------------------
; BLKREAD_REPLY - Reply to block read request
;---------------------------------------------------------
BLKREAD_REPLY1:
	lda TMOT
	bne @Repl1
	lda udp_inp + udp_data + 1	; Pick up the data byte
	jmp @Repl2
@Repl1:	; Load up timeout indicator
@Repl2:	sta QUERYRC
BLKREAD_REPLY:
	lda QUERYRC
	rts

BLKREAD_REPLY2:
	lda #STATE_BLKREAD	; Set up for BLKREAD_REPLY1 callback
	sta state
	jsr RECEIVE_LOOP_FAST
	lda QUERYRC
	rts	

;---------------------------------------------------------
; BLKWRITE_REPLY - Reply to block write request
;---------------------------------------------------------
BLKWRITE_REPLY1:
	lda TMOT
	bne @Repl1
	lda udp_inp + udp_data + 1	; Pick up the data byte
	jmp @Repl2
@Repl1:	; Load up timeout indicator
@Repl2:	sta QUERYRC
BLKWRITE_REPLY:
	lda QUERYRC
	rts

BLKWRITE_REPLY2:
	lda #STATE_BLKWRITE	; Set up for BLKWRITE_REPLY1 callback
	sta state
	jsr RECEIVE_LOOP_FAST
	lda QUERYRC
	rts	

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
; MYDELAY - a copy of the 1MHz delay timer; won't work for GS or accelerated machines
;---------------------------------------------------------
MYDELAY:
	sec
@fca9:	pha
@fcaa:	sbc #$01
	bne @fcaa
	pla
	sbc #$01
	bne @fca9
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
; Constants
;---------------------------------------------------------
STATE_IDLE	= 0
STATE_BLKREAD	= 1
STATE_BLKWRITE	= 2
STATE_ENVELOPE	= 3

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
OS_COMMAND:
	.byte $00
QUERYRC:
	.byte $00
PUTCMSG:
	.byte $00
PUTCMSGEND:
PREVPACKET:
	.byte $00
TEMPDT:	.res 4
