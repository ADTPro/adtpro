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
; DIRREQUEST - Request current directory contents
;---------------------------------------------------------
DIRREQUEST:
	jsr ip65_process
	ldax #DIREND-DIRMSG
	stax udp_send_len
	ldax #DIRMSG
	jsr udp_send
	rts

;---------------------------------------------------------
; DIRREPLY - Reply from current directory contents request
;---------------------------------------------------------
DIRREPLY:
; TODO
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	lda #$00
	ldy #$00
:	sta (BLKPTR),Y
	iny
	cpy #$ff
	bne :-
	rts

;---------------------------------------------------------
; DIRABORT - Abort current directory contents
;---------------------------------------------------------
DIRABORT:
	jsr ip65_process
	ldax #ABORTEND-ABORTMSG
	stax udp_send_len
	ldax #ABORTMSG
	jsr udp_send
	rts

;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	jsr ip65_process
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_C
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	tya			; Max CD request wil be 255 bytes
	ldx #$00		; It's unlikely the $200 buffer is
	stax udp_send_len	; much bigger than that anyway...
	ldax BLKPTR
	jsr udp_send
	rts

;---------------------------------------------------------
; CDREPLY - Reply to current directory change
;---------------------------------------------------------
CDREPLY:
; TODO
	lda #$00
	rts

PUTREQUEST:
	jsr ip65_process
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
	ldax BLKPTR
	jsr udp_send
	rts

PUTREPLY:
; TODO
	rts

PUTINITIALACK:
	jsr ip65_process
	ldax #ACKEND-ACKMSG
	stax udp_send_len
	ldax #ACKMSG
	jsr udp_send
	rts

PUTFINALACK:
	jsr ip65_process
	lda #$00
	ldx #$01
	stax udp_send_len
	ldax #ECOUNT	; Errors during send?
	jsr udp_send
	rts

GETREQUEST:
	jsr ip65_process
	lda #<BIGBUF	; Connect the block pointer to the
	sta BLKPTR	; beginning of the Big Buffer(TM)
	lda #>BIGBUF
	sta BLKPTR+1
	ldy #$00
	lda #CHR_G	; Ask host for file size
	sta (BLKPTR),Y
	iny
	jsr COPYINPUT
	tya
	ldx #$00
	stax udp_send_len
	ldax BLKPTR
	jsr udp_send
	rts

GETREPLY:
; TODO
	rts

GETFINALACK:
	jsr ip65_process
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
	ldax BLKPTR
	jsr udp_send
	rts

;---------------------------------------------------------
; QUERYFNREQUEST/REPLY
;---------------------------------------------------------
QUERYFNREQUEST:
	jsr ip65_process
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
	ldax BLKPTR
	jsr udp_send
	rts

QUERYFNREPLY:
; TODO
	lda #$00
	rts

SENDBLK:
; TODO
	rts
RECVBLK:
; TODO
	rts

;---------------------------------------------------------
; COPYINPUT - Copy data from input area to (BLKPTR);
; Y is assumed to point to the next available byte
; in (BLKPTR)
;---------------------------------------------------------
COPYINPUT:
	ldx #$00
@LOOP:	lda $0200,X
	sta (BLKPTR),Y
	beq @Done
	inx
	iny
	bne @LOOP
@Done:	rts

;---------------------------------------------------------
; Variables
;---------------------------------------------------------

DIRMSG:
	.byte CHR_D		; Verb
DIREND:
ABORTMSG:
	.byte $00
ABORTEND:
ACKMSG:
	.byte CHR_ACK
ACKEND: