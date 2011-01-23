;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2010 by David Schmidt
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

.include "serconfig.asm"

;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
PARMINT:
	ldy COMMSLOT	; Get parm index# (0..7)
	iny		; Now slot# = 1..8 (where 8=IIgs, 9=Pascal entry points)
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

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $04		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 9,4,2,2	; Number of options for each parm

PARMTXT:
	ascz "SSC SLOT 1"
	ascz "SSC SLOT 2"
	ascz "SSC SLOT 3"
	ascz "SSC SLOT 4"
	ascz "SSC SLOT 5"
	ascz "SSC SLOT 6"
	ascz "SSC SLOT 7"
	ascz "IIGS MODEM"
	ascz "GENERIC SLOT 2"
	ascz "300"
	ascz "9600"
	ascz "19200"
	ascz "115200"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

YSAVE:		.byte $00

CONFIG_FILE_NAME:	.byte 11
			.byte "ADTPRO.CONF"

PARMS:
COMMSLOT:	.byte 1		; Comms slot (2)
PSPEED:	.byte 3		; Comms speed (115200)
PSOUND:	.byte 0		; Sounds? (YES)
PSAVE:	.byte 1		; Save parms? (NO)
DEFAULT:	.byte 1,3,0,1	; Default parm indices
SVSPEED:	.byte 3		; Storage for speed setting
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND: