;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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

	.segment "FORMAT"

FormatAbortPause:
	jsr PAUSE

FormatAbort:
	rts

FormatEntry:
	ldy #PMFORMAT	; Format title line
	jsr PICKVOL	; A now has index into DEVICES table; UNITNBR holds chosen unit
			;   UNITNBR
			;   NUMBLKS
			;   NUMBLKS+1
	bmi FormatAbort	; User wanted to abandon the format operation.

	ldx #$18		; Check for a floppy and its formatter device driver
	cpx NUMBLKS
	bne HighLevelFormat	; If it's not $118 blocks, it's not a .FMTDx-able device
	ldx #$01
	cpx NUMBLKS+1
	bne HighLevelFormat	; If it's not $118 blocks, it's not a .FMTDx-able device
	tax			; Let's look at the item they selected in more detail
	jsr POINT_AT		; UTILPTR now points at the item in DEVICES table
	ldy #$04
	lda (UTILPTR),y		; Device+4 is where the device name starts (after the period)
	cmp #$44
	bne HighLevelFormat
	iny
	iny
	lda (UTILPTR),y		; Device+6 is after the drive number; should be blank
	cmp #$20
	bne HighLevelFormat
	dey
	lda (UTILPTR),y		; Device+5 is the drive number, so look for FMTD[A]
	and #$0F		; Read the bottom nybble [1-4]
	tay
	dey			; Make it zero-indexed [0-3]
	lda FMTDX,y		; Load the device number for the formatter associated with this drive
	sta FMT_CONTROL_DEV_NUM
	jsr FloppyLLFormat	; Ask the formatter to low-level format the floppy
	bcs FormatAbortPause

HighLevelFormat:
	jsr PAUSE
	rts

; Some things that main.asm expects to see as part of the normal format:
Died:
Done:
SlotF:
	.byte 00

;
; Strategy:
;
;   If it's a Disk II device, go for "low level formatting" and try to associate
;   the .FMTDx driver to the chosen device.
; 
;   If not, then just write basic SOS boot block and directory structure stuff.
;
; Device call: D_CONTROL
;
; 0: $83 (OS_D_CONTROL)
; 1: dev_num (.FMTDx devices)
; 2: $FE
; 3: Buffer MSB
; 4: Buffer LSB
;
; Table for device control
;
; D_CONTROL_PARMS:	.byte $03
; D_CONTROL_DEV_NUM:	.byte $01
; D_CONTROL_CODE:	.byte $00
; D_CONTROL_LIST:	.addr D_CONTROL_DATA
; D_CONTROL_DATA:	.byte $00, $00

;       Error codes returned:   $00 : good completion
;                               $27 : Unable to format (usually bad media)
;                               $28 : Write-Protected
;                               $33 : Drive too SLOW                  /RRA82237/
;                               $34 : Drive too FAST                  /RRA82237/


FloppyLLFormat:
	CALLOS OS_D_CONTROL, FMT_CONTROL_PARMS	; Format, baby!
	clc
	beq FloppyLLFormatOk
	cmp #$27
	bne :+
	ldy #PMDead
	jmp FloppyLLFormatDead
:	cmp #$28
	bne :+
	ldy #PMProtect
	jmp FloppyLLFormatDead
:	cmp #$33
	bne :+
	jsr CROUT
	ldax #FMTMsg01
	ldy FMT_MSG_LEN_TBL
	jsr IPShowMsg
	jmp FloppyLLFormatOk
:	cmp #$34
	bne :+
	jsr CROUT
	ldax #FMTMsg02
	ldy FMT_MSG_LEN_TBL
	jsr IPShowMsg
	jmp FloppyLLFormatOk
:	pha
	ldy #PMUnRecog
	jsr WRITEMSGAREA
	pla			; Retrieve error code from the stack
	jsr PRBYTE		; Print the MLI error code
	rts
FloppyLLFormatDead:
	jsr WRITEMSGAREA
	sec
FloppyLLFormatOk:
	rts

; SOS formatter messages
FMTMsg01: asc	"DRIVE TOO SLOW!"
FMTMsg01_END =*
FMTMsg02: asc	"DRIVE TOO FAST!"
FMTMsg02_END =*

FMT_MSG_LEN_TBL:
	.byte FMTMsg01_END-FMTMsg01
	.byte FMTMsg02_END-FMTMsg02

FMT_MSGTBL:
	.addr FMTMsg01,FMTMsg02

FMT_CONTROL_PARMS:	.byte $03
FMT_CONTROL_DEV_NUM:	.byte $01
FMT_CONTROL_CODE:	.byte $FE
FMT_CONTROL_LIST:	.addr D_CONTROL_DATA
FMT_CONTROL_DATA:	.res    256, $00	; Page of null dater
