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
; Based on ideas from Terence J. Boldt

DESTPAGE	= $78		; The destination page of the driver code
COPYLEN		= $22		; The number of pages to copy - how big the driver is, including BSS not in image on disk

	.org $1800
	lda	serverip-(DESTPAGE*256)+asm_begin	; The config code uses this address to figure out where to patch the server IP address
	lda	RSHIMEM
	cmp	#DESTPAGE
	bne	:+
	jmp	checkdev
:	lda	#COPYLEN
	jsr	GETBUFR
	bcs	nomem2
	cmp	#DESTPAGE
	bne	nomem
	sta	UTILPTR+1
	sta	RSHIMEM		; Make sure nobody else's FREEBUFR removes us
	lda	#$00
	tay
	sta	UTILPTR
	lda	#>asm_begin
	sta	BLKPTR+1
	lda	#<asm_begin
	sta	BLKPTR
	ldx	#COPYLEN	; Copy pages of code
copydriver:
	lda	(BLKPTR),Y
	sta	(UTILPTR),Y
	iny
	bne	copydriver
	inc	BLKPTR+1
	inc	UTILPTR+1
	dex
	bne	copydriver

	jmp	init
nomem:
	jsr	FREEBUFR
	jmp	init
nomem2:
	jsr	msg
	.byte	"MEMORY NOT AVAILABLE.",$00
	rts

full:
	jsr	msg
	.byte	"SLOT 2 DRIVE 1 ALREADY RESIDENT.",$00
	rts

fail:
INITPAS:
	jsr	msg
	.byte	"NO COMMS DEVICE FOUND.",$00
	rts

; INITIALIZE DRIVER
init:
; Find a likely place to install the driver in the device list.
; Is there already a driver in slot 2, drive 1?
	ldx	DEVCNT
checkdev:
	lda	DEVLST,X	; Grab an active device number
	cmp	#$20		; Slot 2, drive 1?
	beq	present		; Yes, check if it's our driver
	dex
	bpl	checkdev	; Swing around until no more in list
instdev:
; All ready to go - install away!
	lda	#<DRIVER
	sta	DEVADR21
	lda	#>DRIVER
	sta	DEVADR21+1
; Add to device list
	inc	DEVCNT
	ldy	DEVCNT
	lda	#$20 ; Slot 2, drive 1
	sta	DEVLST,Y
	jsr	INITIO
	bcs	fail
	jmp	report

present:
	lda	DEVADR21
	cmp	#<DRIVER
	bne	full
	lda	DEVADR21+1
	cmp	#>DRIVER
	bne	full
	jsr	PINGS
	bcs	fail
report:	jsr	msg
	.byte	"VEDRIVE: ",$00
	lda	COMMSLOT
	bmi	fail
	pha
	jsr	msg
	.byte	"SERVING S2D1 WITH COMM SLOT ",$00
	pla
	clc
	adc	#$B1	; Add '1' to the found comm slot number for reporting
	jsr	COUT	; Tell 'em which one we're using
	rts

INITIO:
	jsr	FindSlot
	jsr	INITUTHER
	bcc	PINGS
	rts
PINGS:	ldx	#$08
	stx	RESETIO	; Counter - number of times we go through this loop
:	lda	#$ff
	jsr	DELAY
	lda	#$ff
	jsr	DELAY
	jsr	PINGREQUEST
	dec	RESETIO
	bne	:-
	clc
	rts

;---------------------------------------------------------
; FindSlot - Find an uther card
;---------------------------------------------------------
FindSlot:
	lda COMMSLOT
	sta TempSlot
	ldx #$00	; Slot number - start at min and work up
FindSlotLoop:
	stx COMMSLOT	; ip65_init looks for COMMSLOT to be the index
	clc
	jsr ip65_init
	bcc FoundSlot
	ldx COMMSLOT
	inx
	stx COMMSLOT
	cpx #MAXSLOT
	bne FindSlotLoop
	jmp FindSlotDone
FoundSlot:
	lda COMMSLOT
	sta TempSlot
FindSlotDone:
; All done now, so clean up
	ldx TempSlot
	stx COMMSLOT
	rts

TempSlot:	.byte 0

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

