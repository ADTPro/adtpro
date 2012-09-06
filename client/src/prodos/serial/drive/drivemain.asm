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
; VIRTUAL HARD DRIVE VIA SERIAL PORT TO PC
; (C)2001 TERENCE J. BOLDT

; Zero page variables (all unused by DOS, BASIC and Monitor)
UTILPTR		= $6

; Apple constants
CHR_ESC	= $9b	; ESCAPE KEY
CHR_A	= $c1	; Character 'A' 

; PRODOS GLOBAL PAGE VALUES
DEV2S1	= $BF14 ; POINTER FOR SLOT 2 DRIVE 1 DRIVER
DEVCNT	= $BF31 ; DEVICE COUNT -1
DEVLST	= $BF32 ; DEVICE LIST

; PRODOS ZERO PAGE VALUES
COMMAND	= $42 ; PRODOS COMMAND
UNIT	= $43 ; PRODOS SLOT/DRIVE
BUFLO	= $44 ; LOW BUFFER
BUFHI	= $45 ; HI BUFFER
BLKLO	= $46 ; LOW BLOCK
BLKHI	= $47 ; HI BLOCK

; PRODOS ERROR CODES
IOERR	= $27
NODEV	= $28
WPERR	= $2B

; ROM Locations
COUT	= $fded		; Output character

; Activity screen location
SCRN_THROB	= $0427

	.ORG	$1800

	jmp init

CHECKSUM:
	.byte	$00
fail:
INITPAS:
	jsr	msg
	.byte	"NO SERIAL DEVICE FOUND.",$00
	rts

; INITIALIZE DRIVER
init:
; Find a serial device
	jsr	msg
	.byte	"VSDRIVE: ",$00
	jsr 	FindSlot	; Sniff out a likely comm slot
	lda	COMMSLOT
	bmi	fail
	pha
	jsr	PARMINT
	jsr	RESETIO
	jsr	msg
	.byte	"USING COMM SLOT ",$00
	pla
	clc
	adc	#$B1	; Add '1' to the found comm slot number for reporting
	jsr	COUT	; Tell 'em which one we're using

; ADD POINTER TO DRIVER
	lda	#<DRIVER
	sta	DEV2S1
	lda	#>DRIVER
	sta	DEV2S1+1
; ADD TO DEVICE LIST
	inc	DEVCNT
	ldy	DEVCNT
	lda	#$20 ; SLOT 2 DRIVE 1
	sta	DEVLST,Y
	rts

; DRIVER CODE
DRIVER:
	cld
; CHECK THAT WE HAVE THE RIGHT DRIVE
	lda	UNIT
	cmp	#$20 ; SLOT 2 DRIVE 1
	beq	DOCMD ; YEP, DO COMMAND
	sec	; NOPE, FAIL
	lda	#NODEV
	rts

; CHECK WHICH COMMAND IS REQUESTED
DOCMD:
	lda	COMMAND
	bne	NOTSTAT ; 0 IS STATUS
	jmp	GETSTAT
NOTSTAT:
	cmp	#$01
	bne	NOREAD ; 1 IS READ
	jmp	READBLK
NOREAD:
	cmp	#$02
	bne	NOWRITE ; 2 IS WRITE
	jmp	WRITEBLK
NOWRITE:
	lda	#$00 ; CLEAR ERROR
	clc
	rts

; STATUS
GETSTAT:
	lda	#$00
	ldx	#$FF
	ldy	#$FF
	clc
	rts

READFAIL:
	; increment failure count
	; retry if not too bad
	jsr	RESETIO
	jsr	CALC_CHECKSUM	; Waste some time
	jsr	RESETIO
	jsr	CALC_CHECKSUM	; Waste some more time
	lda	#$00
	sta	CHECKSUM
	jsr	PARMINT		; Re-interpret comms parameters	
	sec
	rts

; READ
READBLK:
; SEND COMMAND TO PC
	lda	#$01		; Read command
	jsr	COMMAND_ENVELOPE
; READ ECHO'D COMMAND AND VERIFY
	jsr	GETC		; Command envelope begin
	cmp	#CHR_A
	bne	READFAIL
	jsr	GETC		; Read command
	cmp	#$01
	bne	READFAIL
	jsr	GETC		; LSB of requested block
	cmp	BLKLO
	bne	READFAIL
	jsr	GETC		; MSB of requested block
	cmp	BLKHI
	bne	READFAIL
	jsr	GETC		; Checksum of command envelope
	cmp	CHECKSUM
	bne	READFAIL

; Grab the screen contents, remember it
	lda	SCRN_THROB
	sta	SCREEN_CONTENTS

; READ BLOCK AND VERIFY
	ldx	#$00
	ldy	#$00
	stx	SCRN_THROB
RDLOOP:
	jsr	GETC
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
	pha		; Push checksum for now
	jsr	CALC_CHECKSUM
	pla	
	cmp	CHECKSUM
	bne	READFAIL
	lda	#$00
	clc
	rts

WRITEFAIL:
	; increment failure count
	; retry if not too bad
	jsr	RESETIO
	jsr	CALC_CHECKSUM	; Waste some time
	jsr	RESETIO
	jsr	CALC_CHECKSUM	; Waste some more time
	lda	#$00
	sta	CHECKSUM
	jsr	PARMINT		; Re-interpret comms parameters	
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
	cmp	#CHR_A		; S/B Command envelope
	bne	WRITEFAIL
	jsr	GETC
	cmp	#$02		; S/B Write
	bne	WRITEFAIL
	jsr	GETC		; Read LSB of requested block
	cmp	BLKLO
	bne	WRITEFAIL
	jsr	GETC		; Read MSB of requested block
	cmp	BLKHI
	bne	WRITEFAIL
	jsr	GETC		; Checksum of block - not the command envelope
	cmp	CHECKSUM
	bne	WRITEFAIL

	lda	#$00
	clc
	rts

COMMAND_ENVELOPE:
		; Send a command envelope (read/write) with the command in the accumulator
	pha			; Hang on to the command for a sec...
	lda	#CHR_A
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

CALC_CHECKSUM:			; Calculate the checksum of the block at BLKLO/BLKHI
	lda	#$00		; Clean everyone out
	tax
	tay
CC_LOOP:
	eor	(BUFLO),Y	; Exclusive-or accumulator with what's at (BUFLO),Y
	sta	CHECKSUM	; Save that tally in CHECKSUM as we go
	iny
	bne	CC_LOOP
	inc	BUFHI		; Y just turned over to zero; bump MSB of buffer
	inx			; Keep track of trips through the loop - we need two of them
	cpx	#$02		; The second time X is incremented, this will signfiy twice through the loop
	bne	CC_LOOP

	dec	BUFHI		; BUFHI got bumped twice, so back it back down
	dec	BUFHI
	rts

;***********************************************
;
; msg -- print an in-line message
;
msg:	pla
	sta	UTILPTR
	pla
	sta	UTILPTR+1
	ldy	#0
msg1:	inc	UTILPTR
	bne	:+
	inc	UTILPTR+1
:	lda	(UTILPTR),y
	beq	msgx
	ora	#%10000000
	jsr	COUT
	jmp	msg1
msgx:	lda	UTILPTR+1
	pha
	lda	UTILPTR
	pha
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
; abort - stop everything
;---------------------------------------------------------
PABORT:
	sec
	rts		; Not implemented

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
PSPEED:
	.byte	3	; 0 = 300, 1 = 9600, 2 = 19200, 3 = 115200
COMMSLOT:
DEFAULT:
	.byte	$ff	; Start with -1 for a slot number so we can tell when we find no slot
SCREEN_CONTENTS:
	.byte	$00	; Storage for the character on screen when throbbing