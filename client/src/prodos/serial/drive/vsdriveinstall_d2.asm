;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 - 2013 by David Schmidt
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
; Based on ideas from Terence J. Boldt

	.org $2000

	lda	#$d0		; Destination location = $d000
	sta	UTILPTR+1
	lda	#$00
	tay
	sta	UTILPTR
	lda	#>asm_begin
	sta	BLKPTR+1
	lda	#<asm_begin
	sta	BLKPTR
	lda	LC1WR
	lda	LC1WR		; Enable Language Card write RAM
	ldx	#$04		; Copy four pages
copydriver:
	lda	(BLKPTR),Y
	sta	(UTILPTR),Y
	iny
	bne	copydriver
	inc	BLKPTR+1
	inc	UTILPTR+1
	dex
	bne	copydriver
	lda	ROMONLY2	; Disable all Language Card RAM	
	jmp	init

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

; INITIALIZE DRIVER
init:
; Find a likely place to install the driver in the device list.
; Is there already a driver in slot 2, drive 1?
	ldx	DEVCNT
checkdev:
	lda	DEVLST,X	; Grab an active device number
	cmp	#$a0		; Slot 2, drive 1?
	beq	present		; Yes, check if it's our driver
	dex
	bpl	checkdev	; Swing around until no more in list
instdev:
; All ready to go - install away!
	lda	#<DRIVER
	sta	DEVADR21
	sta	DEVADR22
	lda	#>DRIVER
	sta	DEVADR21+1
	sta	DEVADR22+1
; Add to device list
	inc	DEVCNT
	ldy	DEVCNT
	lda	#$20 ; Slot 2, drive 1
	sta	DEVLST,Y
	inc	DEVCNT
	iny
	lda	#$A0 ; Slot 2, drive 2
	sta	DEVLST,Y
	jmp	findser

full:
	jsr	msg
	.byte	"SLOT 2 DRIVE ALREADY RESIDENT.",$00
	rts

fail:
INITPAS:
	jsr	msg
	.byte	"NO SERIAL DEVICE FOUND.",$00
	rts

present:
	lda	DEVADR21
	cmp	#<DRIVER
	bne	full
	lda	DEVADR21+1
	cmp	#>DRIVER
	bne	full

; Find a serial device
findser:
	jsr	msg
	.byte	"VSDRIVE: ",$00
	lda	LC1RW		; Turn RAM on R/W in LC
	lda	LC1RW
	jsr 	FindSlot	; Sniff out a likely comm slot
	lda	COMMSLOT
	pha
	lda	ROMONLY2	; Turn ROM back on in LC
	pla
	bmi	fail
	pha
	lda	LC1RW		; Turn RAM on R/W in LC
	lda	LC1RW
	jsr	PARMINT
	jsr	RESETIO
	lda	ROMONLY2	; Turn ROM back on in LC
	jsr	msg
	.byte	"SERVING S2,D1/D2 WITH COMM SLOT ",$00
	pla
	clc
	adc	#$B1	; Add '1' to the found comm slot number for reporting
	jsr	COUT	; Tell 'em which one we're using

	;
	; What to do next (rts vs. jmp) is set in the enveloping assembly.
	; This allows us to use this same code to install and quit on 
	; a boot disk, or install and continue to load BASIC as part of 
	; serial bootstrapping operations.
	;