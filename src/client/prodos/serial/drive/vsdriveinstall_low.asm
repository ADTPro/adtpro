;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 - 2016 by David Schmidt
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

	.org $2000

; INITIALIZE DRIVER
init:
; Find a likely place to install the driver in the device list.
; Is there already a driver in slot x, drive 1?
scanslots:
	inc	slotcnt
	lda	slotcnt
	sta	VS_SLOT
	cmp	#$08
	beq	full
	asl
	asl
	asl
	asl
	sta	VS_SLOT_DEV1
	clc
	adc	#$80
	sta	VS_SLOT_DEV2
	ldx	DEVCNT
checkdev:
	lda	DEVLST,X	; Grab an active device number
    and #$f0        ; Ignore low nibble as suggested by ProDOS TN#21
	cmp	VS_SLOT_DEV1	; Slot x, drive 1?
	beq	scanslots	; Yes, someone already home - go to next slot
	cmp	VS_SLOT_DEV2	; Slot x, drive 2?
	beq	scanslots	; Yes, someone already home - go to next slot
	dex
	bpl	checkdev	; Swing around until no more in list
	jmp	instdev
full:
	jsr	msg
	.byte	"NO SLOT AVAILALBE FOR DRIVER.",$00
	jmp	alldone

instdev:
; We now know that VS_SLOT is open if we need it.
; But the question remains: are we already resident somewhere?
	;bit	$C088
	lda	DRIVER+$03
	;bit	$C08A
	cmp	#$63
	beq	resident
	jmp	ready	
resident:
	jsr	msg
	.byte	"DRIVER ALREADY RESIDENT.",$00
	jmp	alldone

; All ready to go - install away!
ready:
	lda	VS_SLOT
	clc
	adc	#$b0
	sta	FIXUP03
	lda	VS_SLOT
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
	lda	VS_SLOT_DEV1	; Slot x, drive 1
	sta	DEVLST,Y
	inc	DEVCNT
	iny
	lda	VS_SLOT_DEV2	; Slot x, drive 2
	sta	DEVLST,Y

moveit:
	lda	#$4
	jsr	GETBUFR
	bcs	nomem2
	cmp	#$96
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
	lda	VS_SLOT_DEV1
	sta	FIXUP01+1
	lda	VS_SLOT_DEV2
	sta	FIXUP02+1
	jmp	findser

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

nomem:
	jsr	FREEBUFR
	jmp	init
nomem2:
	jsr	msg
	.byte	"MEMORY NOT AVAILABLE.",$00
	rts

fail:
INITPAS:
	jsr	msg
	.byte	"NO SERIAL DEVICE FOUND.",$00
	jmp	alldone

VS_SLOT:
	.byte	$01
VS_SLOT_DEV1:
	.byte	$00
VS_SLOT_DEV2:
	.byte	$00
slotcnt:
	.byte	$00

; Find a serial device
findser:
	jsr	msg
	.byte	"VSDRIVE: ",$00
	jsr 	FindSlot	; Sniff out a likely comm slot
	lda	COMMSLOT
	bmi	fail
	pha
	jsr	PARMINT
	jsr	RESETIO
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
alldone:
	;
	; What to do next (rts vs. jmp) is set in the enveloping assembly.
	; This allows us to use this same code to install and quit on 
	; a boot disk, or install and continue to load BASIC as part of 
	; serial bootstrapping operations.
	;
