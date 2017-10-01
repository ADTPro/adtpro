;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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

	.segment "FORMAT"

FormatEntry:
	jsr CLEARVOLFORMAT	; Clean out the volume display - prepare for formatters
FormatReEntry:
	ldy #PMFORMAT		; Format title line
	jsr PICKVOL		; A now has index into DEVICES table; UNITNBR holds chosen unit
				;   UNITNBR
				;   NUMBLKS
				;   NUMBLKS+1
	bmi MExit		; User wanted to abandon the format operation.
	sta SLOWA		; Hang on to that accumulator
	lda #$15
	jsr TABV
	ldy #PMTheOld
	jsr WRITEMSGLEFT	; Ready to format (Y/N)?
	jsr YNLOOP
	beq Again		; 0 = No

	lda UNITNBR		; Pull the device number requested
	sta FMT_CONTROL_DEV_NUM
	jsr OSFormat		; Ask the formatter to do its thing

Again:
	lda #$17
	jsr TABV
	ldy #PMNuther
	jsr WRITEMSGLEFT
	jsr YNLOOP		; Get a Yes or No answer
	beq MExit		; Answer was No...
	jmp FormatReEntry	; Format another disk
MExit:
	lda #$00
	jsr CLEARVOLUMES 
	rts

; Some things that main.asm expects to see as part of the normal format:
Died:
Done:
SlotF:
	.byte 00

; Device call: D_CONTROL
;
; 0: $83 (OS_D_CONTROL)
; 1: dev_num
; 2: $FE
; 3: Buffer MSB
; 4: Buffer LSB
;
;       Error codes returned:   $00 : good completion
;                               $27 : Unable to format (usually bad media)
;                               $28 : Write-Protected <-- Actually, it's $2B!
;                               $33 : Drive too SLOW                  /RRA82237/
;                               $34 : Drive too FAST                  /RRA82237/


OSFormat:
	CALLOS OS_D_CONTROL, FMT_CONTROL_PARMS	; Format, baby!
	clc
	beq OSFormatOk
	cmp #IOERROR
	bne :+
	ldy #PMDead
	jmp OSFormatDead
:	cmp #NOWRITE
	bne :+
	ldy #PMProtect
	jmp OSFormatDead
:	cmp #$33	; Device-specific return code: drive too slow
	bne :+
	jsr CROUT
	ldax #FMTMsg01
	ldy FMT_MSG_LEN_TBL
	jsr IPShowMsg
	jmp OSFormatOk
:	cmp #$34	; Device-specific return code: drive too fast
	bne :+
	jsr CROUT
	ldax #FMTMsg02
	ldy FMT_MSG_LEN_TBL+1
	jsr IPShowMsg
	jmp OSFormatOk
:	pha
	ldy #PMUnRecog
	jsr WRITEMSGAREA
	pla			; Retrieve error code from the stack
	jsr PRBYTE		; Print the MLI error code
OSFormatOk:
	rts
OSFormatDead:
	jsr WRITEMSGAREA
	rts

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
VolLen:	.res 1			; $F0 + length of Volume Name
VOLnam:	.res 15			; Volume Name

; SOS formatter messages
FMTMsg01: asc	"DRIVE TOO SLOW! ADJUST CLOCKWISE."
FMTMsg01_END =*
FMTMsg02: asc	"DRIVE TOO FAST! ADJUST ANTI-CLOCKWISE."
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
