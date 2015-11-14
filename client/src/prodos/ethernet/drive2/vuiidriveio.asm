;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2015 by David Schmidt
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
; Virtual drive over the serial port based on ideas by Terence J. Boldt

;---------------------------------------------------------
; recv_fail1 - Local re-branch to real fail routine
;---------------------------------------------------------
recv_fail1:
	jmp recv_fail

; READ
READBLK:
	lda	#$03		; Read command w/time request - command will be either 3 or 5
	clc
	adc	UNIT2		; Command will be #$05 for unit 2
	sta	CURCMD
; SEND COMMAND TO PC
	jsr	COMMAND_ENVELOPE
; Pull and verify command envelope from host
	ldax	#$09		; 9 bytes in the envelope
	jsr	recv_init
	jsr	recv_byte	; Command envelope begin
	cmp	#CHR_E
	bne	recv_fail1
	jsr	recv_byte	; Read command
	cmp	CURCMD
	bne	recv_fail1
	jsr	recv_byte	; LSB of requested block
	cmp	BLKLO
	bne	recv_fail1
	jsr	recv_byte	; MSB of requested block
	cmp	BLKHI
	bne	recv_fail1
	jsr	recv_byte	; LSB of time
	sta	TEMPDT
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	recv_byte	; MSB of time
	sta	TEMPDT+1
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	recv_byte	; LSB of date
	sta	TEMPDT+2
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	recv_byte	; MSB of date
	sta	TEMPDT+3
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	recv_byte	; Checksum of command envelope
	cmp	CHECKSUM
	bne	recv_fail
	jsr	recv_done
	lda	TEMPDT
	sta	TIME
	lda	TEMPDT+1
	sta	TIME+1
	lda	TEMPDT+2
	sta	DATE
	lda	TEMPDT+3
	sta	DATE+1
; Grab the screen contents, remember it
	lda	SCRN_THROB
	sta	SCREEN_CONTENTS
; READ BLOCK AND VERIFY
	ldax	#$0201
	jsr	recv_init
	ldx	#$00
	ldy	#$00
	stx	SCRN_THROB
RDLOOP:
	jsr	recv_byte
	bcs	recv_fail
	sta	(BUFLO),Y
	iny
	bne	RDLOOP

	inc	BUFHI
	inx
	stx	SCRN_THROB
	cpx	#$02
	bne	RDLOOP

	dec	BUFHI
	dec	BUFHI	; Bring BUFHI back down to where it belongs

	lda	SCREEN_CONTENTS	; Restore screen contents
	sta	SCRN_THROB

	jsr	recv_byte	; Checksum
	bcs	recv_fail
	pha		; Push checksum for now
	ldx	#$00
	jsr	CALC_CHECKSUM
	pla	
	cmp	CHECKSUM
	bne	recv_fail

	jsr	recv_done
	lda	#$00
	clc
	rts

;---------------------------------------------------------
; recv_fail - Receive failed, so reset receive buffer
;---------------------------------------------------------
recv_fail:
	jsr	recv_done
	bit	$c010
	sec
	rts

; WRITE
WRITEBLK:
; SEND COMMAND TO PC
	lda	#$02		; Write command - command will be either 2 or 4
	clc
	adc	UNIT2		; Command will be #$05 for unit 2
	sta	CURCMD
	jsr	COMMAND_ENVELOPE

; WRITE BLOCK AND CHECKSUM
	ldax	#$0201
	jsr	send_init
	ldx	#$00
	stx	CHECKSUM
WRBKLOOP:
	ldy	#$00
WRLOOP:
	lda	(BUFLO),Y
	jsr	send_byte
	iny
	bne	WRLOOP

	inc	BUFHI
	inx
	cpx	#$02
	bne	WRBKLOOP

	dec	BUFHI
	dec	BUFHI

	jsr	CALC_CHECKSUM
	lda	CHECKSUM	; Checksum
	jsr	send_byte
	jsr	send_done	; Do it!

; READ ECHO'D COMMAND AND VERIFY
	ldax	#$05
	jsr	recv_init
	jsr	recv_byte
	bcs	recv_fail
	cmp	#CHR_E		; S/B Command envelope
	bne	recv_fail
	jsr	recv_byte
	bcs	recv_fail
	cmp	CURCMD		; S/B Write
	bne	recv_fail
	jsr	recv_byte	; Read LSB of requested block
	bcs	recv_fail
	cmp	BLKLO
	bne	recv_fail
	jsr	recv_byte	; Read MSB of requested block
	bcs	recv_fail
	cmp	BLKHI
	bne	recv_fail
	jsr	recv_byte	; Checksum of block - not the command envelope
	bcs	recv_fail
	cmp	CHECKSUM
	bne	recv_fail
	lda	#$00
	jsr	recv_done
	clc
	rts

COMMAND_ENVELOPE:
		; Send a command envelope (read/write) with the command in the accumulator
	pha			; Hang on to the command for a sec...
	ldax	#$05		; Get ready to send 5 bytes to W5100
	jsr	send_init
	lda	#CHR_E
	jsr	send_byte	; Envelope
	sta	CHECKSUM
	pla			; Pull the command back off the stack
	jsr	send_byte	; Send command
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKLO
	jsr	send_byte	; Send LSB of requested block
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKHI
	jsr	send_byte	; Send MSB of requested block
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	send_byte	; Send envelope checksum
	jsr 	send_done	; Do it!
	rts

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
TEMPDT:	.res	4
CURCMD: .res	1