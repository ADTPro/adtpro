;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2008 by David Schmidt
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
	ldy PSSC	; Get parm index# (0..7)
	iny		; Now slot# = 1..8 (where 8=IIgs)
	tya
	cmp #$08
	bpl DRIVERS
	jmp INITSSC	; Y holds slot number
DRIVERS:
	cmp #$09
	bpl LASER
	jmp INITZGS
LASER:
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
	bne FoundNotIIgs	; If not, it's not an IIgs.
	cpx #$02		; Only bothering to check IIgs Modem slot (2)
	bne FindSlotNext
	lda #$07		; We found the IIgs modem port, so store it
	sta TempIIgsSlot
	jmp FindSlotNext
FoundNotIIgs:
	ldy #$00
	lda (UTILPTR),y
	cmp #$da		; Is $Cn00 == $DA?
	bne NotLaser		; If not, it's not a Laser 128.
	cpx #$02
	bne FindSlotNext
	lda #$09		; Ok, this is a Laser 128.
	sta TempSlot
	lda PSPEED		; Were we trying to go too fast (115.2k)?
	cmp #$03
	bne :+
	lda #$02		; Yes, slow it down to 19200.
	sta PSPEED
	sta DEFAULT+1		; And make that the default.
:
	jmp FindSlotNext
NotLaser:
	ldy #$0a
	lda (UTILPTR),y
	cmp #$0e		; Is this a newer IIc - $Cn0a == $0E?
	beq ProcessIIc
NotNewIIc:
	cmp #$25		; Is this an older IIc - $Cn0a == $25?
	bne GenericSSC
ProcessIIc:
	cpx #$02		; Only bothering to check IIc Modem slot (2)
	bne FindSlotNext
	stx TempSlot
	jmp FindSlotBreak	; Don't check port #1 on an IIc - we don't care
GenericSSC:
	stx TempSlot		; Nope, nothing special.  Just a Super Serial card.

FindSlotNext:
	dex
	bne FindSlotLoop
; All done now, so clean up
FindSlotBreak:
	ldx TempSlot
	beq :+
	dex			; Subtract 1 to match slot# to parm index
	stx PSSC
	stx DEFAULT		; Store the slot number discovered as default
	rts
:	lda TempIIgsSlot
	beq FindSlotDone	; Didn't find anything in particular
	sta PSSC
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
	ascz "LASER MODEM"
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
PSSC:	.byte 1		; Comms slot (2)
PSPEED:	.byte 3		; Comms speed (115200)
PSOUND:	.byte 0		; Sounds? (YES)
PSAVE:	.byte 1		; Save parms? (NO)
DEFAULT:	.byte 1,3,0,1	; Default parm indices
SVSPEED:	.byte 3		; Storage for speed setting
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND: