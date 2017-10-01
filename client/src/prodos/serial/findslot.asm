;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2012 by David Schmidt
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

;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
PARMINT:
	ldy COMMSLOT	; Get parm index# (0..8)
	iny		; Now slot# = 1..9 (where 8=IIgs, 9=Pascal entry points)
	tya
	cmp #$08
	bpl DRIVERS
	jmp INITSSC	; Y holds slot number
DRIVERS:
	cmp #$09
	bpl PASCALEP
	jmp INITZGS
PASCALEP:
	jmp INITPAS

;---------------------------------------------------------
; FindSlot - Find a comms device
;---------------------------------------------------------
FindSlot:
	lda #$00
	sta UTILPTR
	sta TempSlot
	sta TempIIgsSlot
	ldx #$07 ; Slot number
FindSlotLoop:
	clc
	txa
	adc #$c0
	sta UTILPTR+1
	ldy #$05		; Lookup offset
	lda (UTILPTR),y
	cmp #$38		; Is $Cn05 == $38?
	bne FindSlotNext
	ldy #$07		; Lookup offset
	lda (UTILPTR),y
	cmp #$18		; Is $Cn07 == $18?
	bne FindSlotNext
	ldy #$0b		; Lookup offset
	lda (UTILPTR),y
	cmp #$01		; Is $Cn0B == $01?
	bne FindSlotNext
	ldy #$0c		; Lookup offset
	lda (UTILPTR),y
	cmp #$31		; Is $Cn0C == $31?
	bne FindSlotNext
; Ok, we have a set of signature bytes for a comms card (or IIc/IIgs, or Laser).
; Remove more specific models/situations first.
	ldy #$1b		; Lookup offset
	lda (UTILPTR),y
	cmp #$eb		; Do we have a goofy XBA instruction in $C01B?
	bne FoundNotIIgs	; If not, it's not a IIgs.
	cpx #$02		; Only bothering to check IIgs Modem slot (2)
	bne FindSlotNext
	lda #$07		; We found the IIgs modem port, so store it
	sta TempIIgsSlot
	jmp FindSlotNext
FoundNotIIgs:
	ldy #$00
	lda (UTILPTR),y
	cmp #$da		; Is $Cn00 == $DA?
	bne NotLaser		; No - it's not a Laser 128
	lda #$10		; Yes - it's a Laser 128.  Set SSCPUT to ignore DSR.
	sta MOD5+1
	lda #$08		; Ignore DSR and DCD
	sta MOD6+1
	jmp ProcessIIc		; Now treat it like a IIc.
NotLaser:
	ldy #$0a
	lda (UTILPTR),y
	cmp #$0e		; Is this a newer IIc - $Cn0a == $0E?
	beq ProcessIIc
NotNewIIc:
	cmp #$25		; Is this an older IIc - $Cn0a == $25?
	beq ProcessIIc
NotOldIIc:
	ldy #$01
	lda (UTILPTR),y
	cmp #$a7		; Is this a Franklin Ace 500 - $Cn01 == $A7?
	bne GenericSSC		; No - call it a generic SSC.  Yes - treat it like a IIc.
ProcessIIc:
	cpx #$02		; Only bothering to check IIc Modem slot (2)
	bne FindSlotNext
	stx TempSlot
	jmp FindSlotBreak	; Don't check port #1 on an IIc - we don't care
GenericSSC:
	stx TempSlot		; Nope, nothing special.  Just a Super Serial card.
	lda #$50		; Make sure we can watch for DSR
	sta MOD5+1
	lda #$68		; Make sure we can watch for DSR and DCD
	sta MOD6+1

FindSlotNext:
	dex
	bne FindSlotLoop
; All done now, so clean up
FindSlotBreak:
	ldx TempSlot
	beq :+
	dex			; Subtract 1 to match slot# to parm index
	stx COMMSLOT
	stx DEFAULT		; Store the slot number discovered as default
	rts
:	lda TempIIgsSlot
	beq FindSlotDone	; Didn't find anything in particular
	sta COMMSLOT
	sta DEFAULT		; Store the slot number discovered as default
FindSlotDone:
	rts
TempSlot:	.byte 0
TempIIgsSlot:	.byte 0
