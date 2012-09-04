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
RESETC8	= $CFFF
COUT	= $fded		; Output character

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
	LDA	#<DRIVER
	STA	DEV2S1
	LDA	#>DRIVER
	STA	DEV2S1+1
; ADD TO DEVICE LIST
	INC	DEVCNT
	LDY	DEVCNT
	LDA	#$20 ; SLOT 2 DRIVE 1
	STA	DEVLST,Y
	RTS

; DRIVER CODE
DRIVER:
	cld
; CHECK THAT WE HAVE THE RIGHT DRIVE
	LDA	UNIT
	CMP	#$20 ; SLOT 2 DRIVE 1
	BEQ	DOCMD ; YEP, DO COMMAND
	SEC	; NOPE, FAIL
	LDA	#NODEV
	RTS

; CHECK WHICH COMMAND IS REQUESTED
DOCMD:
	LDA	COMMAND
	BNE	NOTSTAT ; 0 IS STATUS
	JMP	GETSTAT
NOTSTAT:
	CMP	#$01
	BNE	NOREAD ; 1 IS READ
	JMP	READBLK
NOREAD:
	CMP	#$02
	BNE	NOWRITE ; 2 IS WRITE
	JMP	WRITEBLK
NOWRITE:
	LDA	#$00 ; CLEAR ERROR
	CLC
	RTS

; STATUS
GETSTAT:
	LDA	#$00
	LDX	#$FF
	LDY	#$FF
	CLC
	RTS

READFAIL:
	; increment failure count
	; retry if not too bad
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

; READ BLOCK AND VERIFY
	LDX	#$00
RDBKLOOP:
	LDY	#$00
RDLOOP:
	jsr	GETC
	STA	(BUFLO),Y
	INY
	BNE	RDLOOP

	INC	BUFHI
	INX
	CPX	#$02
	BNE	RDBKLOOP

	DEC	BUFHI

	jsr	GETC	; Checksum
	pha		; Push checksum for now
	jsr	CALC_CHECKSUM
	pla	
	cmp	CHECKSUM
	bne	READFAIL
	LDA	#$00
	CLC
	RTS

WRITEFAIL:
	; increment failure count
	; retry if not too bad
	sec
	rts

; WRITE
WRITEBLK:
; SEND COMMAND TO PC
	lda	#$02		; Write command
	jsr	COMMAND_ENVELOPE

; WRITE BLOCK AND CHECKSUM
	LDX	#$00
	stx	CHECKSUM
WRBKLOOP:
	LDY	#$00
WRLOOP:
	LDA	(BUFLO),Y
	jsr	PUTC
	eor	CHECKSUM
	sta	CHECKSUM
	INY
	BNE	WRLOOP

	INC	BUFHI
	INX
	CPX	#$02
	BNE	WRBKLOOP

	DEC	BUFHI

	LDA	CHECKSUM	; Checksum
	jsr	PUTC

; READ ECHO'D COMMAND AND VERIFY
	jsr	GETC
	cmp	#CHR_A		; S/B Command envelope
	bne	WRITEFAIL
	jsr	GETC
	cmp	#$02		; S/B Write
	bne	WRITEFAIL
	jsr	GETC		; LSB of requested block
	cmp	BLKLO
	bne	WRITEFAIL
	jsr	GETC		; MSB of requested block
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
	pha
	lda	#CHR_A
	sta	CHECKSUM
	pla
	pha
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKLO
	eor	CHECKSUM
	sta	CHECKSUM
	lda	BLKHI
	eor	CHECKSUM
	sta	CHECKSUM

	lda	#CHR_A	; Envelope
	jsr	PUTC
	pla		; Command
	jsr	PUTC
	lda	BLKLO
	jsr	PUTC
	lda	BLKHI
	jsr	PUTC
	lda	CHECKSUM
	jsr	PUTC
	
	rts

CALC_CHECKSUM:	; Calculate the checksum of the block at BLKLO/BLKHI
	ldx	#$00
	stx	CHECKSUM
CC_OUTER_LOOP:
	ldy	#$00
CC_INNER_LOOP:
	lda	(BUFLO),Y
	eor	CHECKSUM
	sta	CHECKSUM
	iny
	bne	CC_INNER_LOOP	
	inc	BUFHI
	inx
	cpx	#$02
	bne	CC_OUTER_LOOP

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
PABORT:	rts		; Not implemented

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
PSPEED:
	.byte	3	; 0 = 300, 1 = 9600, 2 = 19200, 3 = 115200
COMMSLOT:
DEFAULT:
	.byte	$ff	; Start with -1 for a slot number so we can tell when we find no slot
