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
CHR_ESC		= $9b		; ESCAPE KEY
cout		= $fded		; Output character

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

	.ORG $1800

	jmp init
fail:
INITPAS:
	jsr	msg
	.byte	"NO SERIAL SLOT.",$00
	rts

; INITIALISE DRIVER
init:
; Find a serial device
	jsr FindSlot	; Sniff out a likely comm slot
	lda COMMSLOT
	bmi fail

; ADD POINTER TO DRIVER
	LDA >DRIVER
	STA DEV2S1+1
	LDA <DRIVER
	STA DEV2S1
; ADD TO DEVICE LIST
	INC DEVCNT
	LDY DEVCNT
	LDA #$20 ; SLOT 2 DRIVE 1
	STA DEVLST,Y
	RTS

; DRIVER CODE
DRIVER:
; CHECK THAT WE HAVE THE RIGHT DRIVE
	LDA UNIT
	CMP #$20 ; SLOT 2 DRIVE 1
	BEQ DOCMD ; YEP, DO COMMAND
	SEC ; NOPE, FAIL
	LDA #NODEV
	RTS

; CHECK WHICH COMMAND IS REQUESTED
DOCMD:
	LDA COMMAND
	BNE NOTSTAT ; 0 IS STATUS
	JMP GETSTAT
NOTSTAT:
	CMP #$01
	BNE NOREAD ; 1 IS READ
	JMP READBLK
NOREAD:
	CMP #$02
	BNE NOWRITE ; 2 IS WRITE
	JMP WRITEBLK
NOWRITE:
	LDA #$00 ; CLEAR ERROR
	CLC
	RTS


; STATUS
GETSTAT:
	LDA #$00
	LDX #$FF
	LDY #$FF
	CLC
	RTS

; READ
READBLK:
; SEND COMMAND TO PC
	LDA #$01	; READ COMMAND
	JSR PUTC
	LDA BLKLO
	JSR PUTC
	LDA BLKHI
	JSR PUTC
	LDA #$00	; CHECKSUM
	JSR PUTC
; READ ECHO'D COMMAND AND VERIFY
	JSR GETC
	JSR GETC
	JSR GETC
	JSR GETC

; READ BLOCK AND VERIFY
	LDX #$00
RDBKLOOP:
	LDY #$00
RDLOOP:
	JSR GETC
	STA (BUFLO),Y
	INY
	BNE RDLOOP

	INC BUFHI
	INX
	CPX #$02
	BNE RDBKLOOP

	DEC BUFHI

	JSR GETC	; Checksum

	LDA #$00
	CLC
	RTS

; WRITE
WRITEBLK:
; SEND COMMAND TO PC
	LDA #$02	; WRITE COMMAND
	JSR PUTC
	LDA BLKLO
	JSR PUTC
	LDA BLKHI
	JSR PUTC
	LDA #$00 ; CHECKSUM
	JSR PUTC

; WRITE BLOCK AND CHECKSUM
	LDX #$00
WRBKLOOP:
	LDY #$00
WRLOOP:
	LDA (BUFLO),Y
	JSR PUTC
	INY
	BNE WRLOOP

	INC BUFHI
	INX
	CPX #$02
	BNE WRBKLOOP

	DEC BUFHI

	LDA #$00	; Checksum
	JSR PUTC

; READ ECHO'D COMMAND AND VERIFY
	JSR GETC
	JSR GETC
	JSR GETC
	JSR GETC

	LDA #$00
	CLC
	RTS

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
	jsr	cout
	jmp	msg1
msgx:	lda	UTILPTR+1
	pha
	lda	UTILPTR
	pha
	rts

;---------------------------------------------------------
; PUTC - SEND ACC OVER THE SERIAL LINE (AXY UNCHANGED)
;---------------------------------------------------------
PUTC:	jmp $0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; GETC - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
;---------------------------------------------------------
GETC:	jmp $0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; RESETIO - clean up the I/O device
;---------------------------------------------------------
RESETIO:
	jsr $0000	; Pseudo-indirect JSR to reset the I/O device
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
