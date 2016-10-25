;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 - 2013, 2016 by David Schmidt
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
; Virtual disk drive based on ideas from Terence J. Boldt

V_SLOT	= 1   ; Slot to occupy

; PRODOS ZERO PAGE VALUES
COMMAND	= $42 ; PRODOS COMMAND
UNIT	= $43 ; PRODOS SLOT/DRIVE
BUFLO	= $44 ; LOW BUFFER
BUFHI	= $45 ; HI BUFFER
BLKLO	= $46 ; LOW REQUESTED BLOCK
BLKHI	= $47 ; HI REQUESTED BLOCK

; PRODOS ERROR CODES
IOERR	= $27
NODEV	= $28
WPERR	= $2B

; Activity screen location
SCRN_THROB	= $0427

; DRIVER CODE
DRIVER:
	cld
	tsx			; Hang on to the stack pointer
	stx	STACKPTR	;   in case we need to beat a hasty retreat
; CHECK THAT WE HAVE THE RIGHT DRIVE
	lda	UNIT
	cmp	#(V_SLOT << 4)		; SLOT x DRIVE 1
	beq	DOCMD1		; YEP, DO COMMAND
	cmp	#(V_SLOT << 4) + $80; SLOT x DRIVE 2
	beq	DOCMD2		; YEP, DO COMMAND
	sec	; NOPE, FAIL
	lda	#NODEV
	rts

; CHECK WHICH COMMAND IS REQUESTED
DOCMD1:
	lda	#$00
	sta	UNIT2
	beq	DOCOMMAND	; Branch always
DOCMD2:
	lda	#$02		; Add 2 for unit 2
	sta	UNIT2
DOCOMMAND:
	lda	COMMAND
	beq	GETSTAT		; 0 IS STATUS
NOTSTAT:
	cmp	#$01
	bne	NOREAD		; 1 IS READ
	jmp	READBLK
NOREAD:
	cmp	#$02
	bne	@NOWRITE	; 2 IS WRITE
	jmp	WRITEBLK
@NOWRITE:
	lda	#$00		; CLEAR ERROR
	clc
	rts

; STATUS
GETSTAT:
	lda	#$00
	ldx	#$FF
	ldy	#$FF
	clc
	rts

CALC_CHECKSUM:			; Calculate the checksum of the block at BUFLO/BUFHI
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

;---------------------------------------------------------
; abort - stop everything
;---------------------------------------------------------
PABORT:
	lda	SCREEN_CONTENTS	; Replace the throb contents
	sta	SCRN_THROB
	ldx	STACKPTR	; Pop! goes the stack pointer
	txs
	sec
	rts

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
SCREEN_CONTENTS:
	.byte	$00	; Storage for the character on screen when throbbing
CHECKSUM:
	.byte	$00
STACKPTR:		; Storage for the stack pointer to unwind call stack
	.res	$01
UNIT2:	.res	1