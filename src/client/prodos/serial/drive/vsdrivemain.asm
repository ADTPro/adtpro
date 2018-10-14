;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 - 2013 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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

READFAIL:
	jsr	RESETIO
	bit	$c010
	sec
	rts

; READ
READBLK:
	lda	#$03		; Read command w/time request - command will be either 3 or 5
	clc
	adc	UNIT2		; Command will be #$05 for unit 2
	sta	CURCMD
; SEND COMMAND TO PC
	jsr	COMMAND_ENVELOPE
; Pull and verify command envelope from host
	jsr	GETC		; Command envelope begin
	cmp	#CHR_E
	bne	READFAIL
	jsr	GETC		; Read command
	cmp	CURCMD
	bne	READFAIL
	jsr	GETC		; LSB of requested block
	cmp	BLKLO
	bne	READFAIL
	jsr	GETC		; MSB of requested block
	cmp	BLKHI
	bne	READFAIL
	jsr	GETC		; LSB of time
	sta	TEMPDT
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	GETC		; MSB of time
	sta	TEMPDT+1
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	GETC		; LSB of date
	sta	TEMPDT+2
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	GETC		; MSB of date
	sta	TEMPDT+3
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	GETC		; Checksum of command envelope
	cmp	CHECKSUM
	bne	WRITEFAIL	; Just need a nearby failure
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
	ldx	#$00
	ldy	#$00
	stx	SCRN_THROB
RDLOOP:
	jsr	GETC
	bcs	WRITEFAIL
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

	jsr	GETC	; Checksum
	bcs	WRITEFAIL
	pha		; Push checksum for now
	ldx	#$00
	jsr	CALC_CHECKSUM
	pla	
	cmp	CHECKSUM
	bne	WRITEFAIL	; Just need a failure exit nearby

	lda	#$00
	clc
	rts

WRITEFAIL:
	jsr	RESETIO
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
	ldx	#$00
	stx	CHECKSUM
WRBKLOOP:
	ldy	#$00
WRLOOP:
	lda	(BUFLO),Y
	jsr	PUTC
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
	jsr	PUTC

; READ ECHO'D COMMAND AND VERIFY
	jsr	GETC
	bcs	WRITEFAIL
	cmp	#CHR_E		; S/B Command envelope
	bne	WRITEFAIL
	jsr	GETC
	bcs	WRITEFAIL
	cmp	CURCMD		; S/B Write
	bne	WRITEFAIL
	jsr	GETC		; Read LSB of requested block
	bcs	WRITEFAIL
	cmp	BLKLO
	bne	WRITEFAIL
	jsr	GETC		; Read MSB of requested block
	bcs	WRITEFAIL
	cmp	BLKHI
	bne	WRITEFAIL
	jsr	GETC		; Checksum of block - not the command envelope
	bcs	WRITEFAIL
	cmp	CHECKSUM
	bne	WRITEFAIL
	lda	#$00
	clc
	rts

COMMAND_ENVELOPE:
		; Send a command envelope (read/write) with the command in the accumulator
	pha			; Hang on to the command for a sec...
	lda	#CHR_E
	jsr	PUTC		; Envelope
	sta	CHECKSUM
	pla			; Pull the command back off the stack
	jsr	PUTC		; Send command
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKLO
	jsr	PUTC		; Send LSB of requested block
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKHI
	jsr	PUTC		; Send MSB of requested block
	eor	CHECKSUM
	sta	CHECKSUM
	jsr	PUTC		; Send envelope checksum
	rts

;---------------------------------------------------------
; PUTC - SEND ACC OVER THE SERIAL LINE (AXY UNCHANGED)
;---------------------------------------------------------
PUTC:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; GETC - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
;---------------------------------------------------------
GETC:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; RESETIO - clean up the I/O device
;---------------------------------------------------------
RESETIO:
	jsr	$0000	; Pseudo-indirect JSR to reset the I/O device
	rts

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
PSPEED:
	.byte	BPS1152K	; Current speed offset
COMMSLOT:
DEFAULT:
	.byte	$ff	; Start with -1 for a slot number so we can tell when we find no slot
TEMPDT:	.res	4
CURCMD: .res	1