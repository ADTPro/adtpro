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

;---------------------------------------------------------
; FindSlot - Find a comms device
;---------------------------------------------------------
FindSlot:
	lda	#$00
	sta	msgptr		; Borrow msgptr
	sta	TempSlot
	sta	TempIIgsSlot
	ldx	#$07		; Slot number - start high
FindSlotLoop:
	clc
	txa
	adc	#$c0
	sta	msgptr+1
	ldy	#$05		; Lookup offset
	lda	(msgptr),y
	cmp	#$38		; Is $Cn05 == $38?
	bne	FindSlotNext
	ldy	#$07		; Lookup offset
	lda	(msgptr),y
	cmp	#$18		; Is $Cn07 == $18?
	bne	FindSlotNext
	ldy	#$0b		; Lookup offset
	lda	(msgptr),y
	cmp	#$01		; Is $Cn0B == $01?
	bne	FindSlotMaybeIII
	ldy	#$0c		; Lookup offset
	lda	(msgptr),y
	cmp	#$31		; Is $Cn0C == $31?
	bne	FindSlotNext
; Ok, we have a set of signature bytes for a comms card (or IIc/IIgs, or Laser).
; Remove more specific models/situations first.
	ldy	#$1b		; Lookup offset
	lda	(msgptr),y
	cmp	#$eb		; Do we have a goofy XBA instruction in $C01B?
	bne	FoundNotIIgs	; If not, it's not an IIgs.
	cpx	#$02		; Only bothering to check IIgs Modem slot (2)
	bne	FindSlotNext
	lda	#$07		; We found the IIgs modem port, so store it
	sta	TempIIgsSlot
	jmp	FindSlotNext
FoundNotIIgs:
	ldy	#$00
	lda	(msgptr),y
	cmp	#$da		; Is $Cn00 == $DA?
	bne	NotLaser	; No - it's not a Laser 128
	lda	#$10		; Yes - it's a Laser 128.  Set SSCPUT to ignore DSR.
	sta	mod5+1
	lda	#$08		; Set SSCGET to ignore DSR and DCD.
	sta	mod6+1
	jmp	ProcessIIc	; Now treat it like a IIc.
NotLaser:
	ldy	#$0a
	lda	(msgptr),y
	cmp	#$0e		; Is this a newer IIc - $Cn0a == $0E?
	beq	ProcessIIc
NotNewIIc:
	cmp	#$25		; Is this an older IIc - $Cn0a == $25?
	beq	ProcessIIc	; Yes - treat it like a IIc.
NotOldIIc:
	ldy	#$01
	lda	(msgptr),y
	cmp	#$a7		; Is this a Franklin Ace 500 - $Cn01 == $A7?
	bne	GenericSSC	; No - call it a generic SSC.  Yes - treat it like a IIc.
ProcessIIc:
	cpx	#$02		; Only bothering to check IIc Modem slot (2)
	bne	FindSlotNext
	stx	TempSlot
	jmp	FindSlotBreak	; Don't check port #1 on an IIc - we don't care
GenericSSC:
	stx	TempSlot	; Nope, nothing special.  Just a Super Serial card.
	lda	#$50		; Make sure we can watch for DSR
	sta	mod5+1
	lda	#$68		; Make sure we can watch for DSR and DCD
	sta	mod6+1

FindSlotNext:
	dex
	bne	FindSlotLoop
; All done now, so clean up
FindSlotBreak:
	ldx	TempSlot
	beq	:+
	dex			; Subtract 1 to match slot# to parm index
	stx	comm_slot
	rts
:	lda	TempIIgsSlot
	beq	FindSlotDone	; Didn't find anything in particular
	sta	comm_slot
FindSlotDone:
	rts

FindSlotMaybeIII:
	cmp	#$08		; Is $Cn0B == $08?
	bne	FindSlotNext
	ldy	#$0c		; Lookup offset
	lda	(msgptr),y
	cmp	#$48		; Is $Cn0C == $48?
	bne	FindSlotNext
	lda	#$10		; Yes - it's a Laser 128.  Set SSCPUT to ignore DSR.
	sta	mod5+1
	lda	#$08		; Set SSCGET to ignore DSR and DCD.
	sta	mod6+1
	jmp	FindSlotNext	; It's an Apple /// SSC-like thing.

TempSlot:	.byte 0
TempIIgsSlot:	.byte 0
comm_slot:	.byte	$ff		; COMMS SLOT
comm_speed: .byte	6		; COMMS SPEED (115k)
