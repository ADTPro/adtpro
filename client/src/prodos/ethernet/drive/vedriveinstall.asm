;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 - 2016 by David Schmidt
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

DESTPAGE	= $76		; The destination page of the driver code; must match .org $xx00 in vedrive.asm
COPYLEN		= $24		; The number of pages to copy - how big the driver is, including BSS not in image on disk

	.org $2000

; INITIALIZE DRIVER
init:
; Find a likely place to install the driver in the device list.
; Is there already a driver in slot x, drive 1?
scanslots:
	inc	slotcnt
	lda	slotcnt
	sta	VE_SLOT
	cmp	#$08
	beq	full
	asl
	asl
	asl
	asl
	sta	VE_SLOT_DEV1
	clc
	adc	#$80
	sta	VE_SLOT_DEV2
	ldx	DEVCNT
checkdev:
	lda	DEVLST,X	; Grab an active device number
	cmp	VE_SLOT_DEV1	; Slot x, drive 1?
	beq	scanslots	; Yes, someone already home - go to next slot
	cmp	VE_SLOT_DEV2	; Slot x, drive 2?
	beq	scanslots	; Yes, someone already home - go to next slot
	dex
	bpl	checkdev	; Swing around until no more in list
	jmp	instdev
full:
	jsr	msg
	.byte	"NO SLOT AVAILALBE FOR DRIVER.",$00
	jmp	alldone

instdev:
; We now know that VE_SLOT is open if we need it.
; But the question remains: are we already resident somewhere?
	lda	DRIVER+$03
	cmp	#$63
	beq	resident
	jmp	ready	
resident:
	jsr	msg
	.byte	"DRIVER ALREADY RESIDENT.",$00
	jmp	alldone

; All ready to go - install away!
ready:
	lda	VE_SLOT
	clc
	adc	#$b0
	sta	FIXUP03
	lda	VE_SLOT
	asl
	tax
	lda	#<DRIVER
	sta	DEVADR01,x
	sta	DEVADR02,x
	inx
	lda	#>DRIVER
	sta	DEVADR01,x
	sta	DEVADR02,x
; Add to device list
	inc	DEVCNT
	ldy	DEVCNT
	lda	VE_SLOT_DEV1	; Slot x, drive 1
	sta	DEVLST,Y
	inc	DEVCNT
	iny
	lda	VE_SLOT_DEV2	; Slot x, drive 2
	sta	DEVLST,Y

moveit:
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
test:
	jsr	INITIO
	bcs	fail
	jmp	report

nomem:
	jsr	FREEBUFR
nomem2:
	jsr	msg
	.byte	"MEMORY NOT AVAILABLE.",$00
	jmp	alldone

fail:
INITPAS:
	jsr	msg
	.byte	"NO COMMS DEVICE FOUND.",$00
	jmp	alldone

report:	jsr	msg
	.byte	"VEDRIVE: ",$00
	lda	COMMSLOT
	bmi	fail
	pha
	jsr	msg
	.byte	"DRIVES S"
FIXUP03:
	.byte	$b0
	.byte	",D1/2 ON COMM SLOT ",$00
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

VE_SLOT:
	.byte	$01
VE_SLOT_DEV1:
	.byte	$00
VE_SLOT_DEV2:
	.byte	$00
slotcnt:
	.byte	$00

;---------------------------------------------------------
; FindSlot - Find an uther card
;---------------------------------------------------------
FindSlot:
	ldx #$00	; Slot number - start at min and work up
FindSlotLoop:
	stx TempSlot
	inx		; One-indexed slot number for a2_set_slot
	txa
	jsr a2_set_slot
	jsr ip65_init
	ldx TempSlot
	bcc FoundSlot
	inx
	cpx #MAXSLOT
	bne FindSlotLoop
	rts
FoundSlot:
	stx COMMSLOT
	rts

TempSlot:	.byte 0

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

alldone:
	;
	; What to do next (rts vs. jmp) is set in the enveloping assembly.
	; This allows us to use this same code to install and quit on 
	; a boot disk, or install and continue in BASIC.
	;