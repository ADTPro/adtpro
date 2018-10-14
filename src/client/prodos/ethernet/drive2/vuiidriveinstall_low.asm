;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2015 by David Schmidt
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
; Based on ideas from Terence J. Boldt

DESTPAGE	= $70		; The destination page of the driver code; must match .org $xx00 in vedrive.asm
;COPYLEN	= $03		; The number of pages to copy - how big the driver is, including BSS not in image on disk
COPYLEN		= driver_end - driver_begin + $100

	.org $2000
	jsr	init_entry
	bcc	:+
	jmp	nouII		; No Uthernet II card
:	ldax	#ip_parms
	jsr	w5100_init	; There is no error indication from this - we need to be sure by now we have a UII by now
	lda	#DESTPAGE
	sta	UTILPTR+1
	sta	RSHIMEM		; Should only do this if it succeeds... Make sure nobody else's FREEBUFR removes us
	lda	#>COPYLEN
	jsr	GETBUFR
	bcs	nomem2
;	cmp	#DESTPAGE
;	bne	nomem		; Already loaded - re-init?

	; Copy hdr data to hdr_from_init
	ldx	#$05
:	lda	hdr,x
	sta	driver_reloc - driver_begin + hdr_from_init,x	; Memory in driver space, to be relocated
	dex
	bpl	:-

	lda	#$00
	tay
	sta	UTILPTR
	lda	#>driver_reloc
	sta	BLKPTR+1
	lda	#<driver_reloc
	sta	BLKPTR
	ldx	#>COPYLEN	; Copy pages of code
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

nomem:	jsr	FREEBUFR
	jmp	init

nomem2:	jsr	msg
	.byte	"MEMORY NOT AVAILABLE.",$00
	rts

nouII:	jsr	msg
	.byte	"NO UTHERNET II CARD FOUND.",$00
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
	jmp	report

full:
	jsr	msg
	.byte	"SLOT 2 DRIVE 1 ALREADY RESIDENT.",$00
	rts

present:
	lda	DEVADR21
	cmp	#<DRIVER
	bne	full
	lda	DEVADR21+1
	cmp	#>DRIVER
	bne	full
report:	jsr	msg
	.byte	"VEDRIVE2: ",$00
	lda	COMMSLOT
	pha
	jsr	msg
	.byte	"DRIVES S2,D1/2 ON COMM SLOT ",$00
	pla
	clc
	adc	#$B1	; Add '1' to the found comm slot number for reporting
	jsr	COUT	; Tell 'em which one we're using
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
