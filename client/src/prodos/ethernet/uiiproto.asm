;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2014 by David Schmidt
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
	ldax #$0009
	jsr send_init
	lda #CHR_C		; Ask host to Change Directory
	GO_SLOW			; Slow down for SOS
	jsr FNREQUEST
	lda CHECKBYTE
	jsr send_byte
	GO_FAST			; Speed up for SOS
	jsr send_done
	rts


GETREPLY2:
	rts


CDREPLY:
	jsr recv_init
	ldax len
	brk
	jsr recv_byte
	clc
	rts


DIRREPLY:
	rts
DIRREQUEST:
	rts
PINGREQUEST:
	ldax #$0001
	jsr send_init
	lda #CHR_Y
	jsr send_byte
	jsr send_done
	rts
RECVBLKS:
	rts
SENDBLKS:
	rts
PUTACKBLK:
	rts
GETREPLY:
	rts


;---------------------------------------------------------
; FNREQUEST - Request something with a file name
; Assumes SOS has been slowed down already
;---------------------------------------------------------
FNREQUEST:
	pha
	lda #CHR_A	; Envelope
	sta CHECKBYTE
	jsr send_byte
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
	pha
	jsr send_byte	; Payload length - lsb
	pla
	eor CHECKBYTE
	sta CHECKBYTE
	lda #$00
	jsr send_byte	; Payload length - msb
			; No need to update checksum... eor with 0 makes no change
	pla		; Pull the request byte
	pha
	jsr send_byte
	pla
	eor CHECKBYTE
	sta CHECKBYTE
	jsr send_byte	; Send the check byte for envelope
	jsr SENDFN	; Send requested name
	rts


GETREQUEST:
	rts
PUTFINALACK:
	rts
QUERYFNREPLY:
	rts
QUERYFNREQUEST:
	rts
PUTREQUEST:
	rts
PUTREPLY:
	rts
BATCHREQUEST:
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
	pha
	jsr send_byte
	pla
	php
	inx
	eor CHECKBYTE
	sta CHECKBYTE
	plp
	bne FNLOOP
	rts

PPROTO:	.byte $03	; Ethernet protocol = $03
CHECKBYTE:
	.byte 0
	