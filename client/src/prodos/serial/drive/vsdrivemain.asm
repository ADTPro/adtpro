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
; Virtual drive over the serial port based on ideas by Terence J. Boldt

READFAIL:
	jsr	RESETIO
	bit	$c010
	sec
	rts

; READ
READBLK:
; SEND COMMAND TO PC
	lda	#$03		; Read command w/time request
	jsr	COMMAND_ENVELOPE
; Pull and verify command envelope from host
	ldx	#$00
@Pull:	jsr	GETC
	bcs	READFAIL
	sta	Envelope,x
	inx
	cpx	#$09
	bne	@Pull
	jsr 	CALC_Envelope	; Calculate the checksum of the envelope

	lda	Envelope	
	cmp	#CHR_E
	bne	READFAIL
	lda	Envelope+1
	cmp	#$03
	bne	READFAIL
	lda	Envelope+2
	cmp	BLKLO
	bne	READFAIL
	lda	Envelope+3
	cmp	BLKHI
	bne	READFAIL
	lda	Envelope+8	; Checksum of command envelope
	cmp	CHECKSUM
	bne	WRITEFAIL	; Just need a nearby failure
	lda	Envelope+4	; LSB of time	
	sta	TIME
	lda	Envelope+5	; MSB of time
	sta	TIME+1
	lda	Envelope+6	; LSB of date
	sta	DATE
	lda	Envelope+7	; MSB of date
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
	lda	#$02		; Write command
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
	cmp	#$02		; S/B Write
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

CALC_Envelope:			; Calculate the checksum of the envelope
	lda	#$00		; Clean everyone out
	tay
	sta	CHECKSUM
@CE_LOOP:
	eor	Envelope,Y	; Exclusive-or accumulator with what's at Envelope,Y
	sta	CHECKSUM	; Save that tally in CHECKSUM as we go
	iny
	cpy	#$08		; $8 bytes to eor (zero through seven)
	bne	@CE_LOOP
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
	.byte	3	; 0 = 300, 1 = 9600, 2 = 19200, 3 = 115200
COMMSLOT:
DEFAULT:
	.byte	$ff	; Start with -1 for a slot number so we can tell when we find no slot
Envelope:
	.res	9