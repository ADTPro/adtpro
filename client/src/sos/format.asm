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
	sta SLOWA		; Hang on to that accumulator
	jsr LName		; Ask for a name
	bcs Again

	ldx #$18		; Check for a floppy and its formatter device driver
	cpx NUMBLKS
	bne HighLevelFormat	; If it's not $118 blocks, it's not a .FMTDx-able device
	ldx #$01
	cpx NUMBLKS+1
	bne HighLevelFormat	; If it's not $118 blocks, it's not a .FMTDx-able device
	ldx SLOWA		; Let's look at the item they selected in more detail
	jsr POINT_AT		; UTILPTR now points at the item in DEVICES table
	ldy #$04
	lda (UTILPTR),y		; Device+4 is where the device name starts (after the period)
	cmp #$44
	bne HighLevelFormat
	iny			; y = 5
	iny			; y = 6
	lda (UTILPTR),y		; Device+6 is after the drive number; should be blank
	cmp #$20
	bne HighLevelFormat
	dey			; y = 5
	lda (UTILPTR),y		; Device+5 is the drive number, so look for FMTD[A]
	;jsr	$1910
	and #$0F		; Read the bottom nybble [1-4]
	tay
	dey			; Make it zero-indexed [0-3]
	lda FMTDX,y		; Load the device number for the formatter associated with this drive
	sta FMT_CONTROL_DEV_NUM
	jsr FloppyLLFormat	; Ask the formatter to low-level format the floppy
	bcs Again

HighLevelFormat:
	jsr PAUSE
	rts

; High-level format here
	jsr HighLevelFormat

Again:
	lda #$17
	jsr TABV
	ldy #PMNuther
	jsr WRITEMSGLEFT
	jsr YNLOOP		; Get a Yes or No answer
	beq MExit		; Answer was No...
	jmp FormatEntry		; Format another disk
MExit:
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
;                               $28 : Write-Protected <-- Actually, it's $2B!
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
:	cmp #$2B
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
	ldy FMT_MSG_LEN_TBL+1
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

;*******************************
;*                             *
;* LName: Prompt for unit name *
;*                             *
;*******************************
LName:
	lda #$14
	jsr TABV
	ldy #PMVolName
	jsr WRITEMSGLEFT
LRdname:
	lda #$0E		; Reset CH to 14
	jsr HTAB
	jsr ECHO_ON
	ldx #$00
	beq LInput		; Always taken
LBackup:
	cpx #0  		; Handle backspaces
	beq LRdname
	dex
	lda #$88		; <--
	jsr COUT
LInput:
	jsr RDKEY		; Get a keypress
	cmp #$88		; Backspace?
	beq LBackup
	cmp #$FF		; Delete?
	beq LBackup
	cmp #$8D		; C/R is end of input
	beq LFormat
	cmp #CHR_ESC		; Escape bails out
	beq LAbort
	cmp #$AE		; (periods are ok...)
	beq LStore
	cmp #$B0		; Less than '0'?
	bcc LInput		; Then it's invalid
	cmp #$BA		; Less than '9'+1?
	bcc LStore		; Then it's a number - store it

	and #$DF		; Force any lower case to upper case
	cmp #$C1		; Less than 'A'?
	bcc LInput		; Then it's invalid
	cmp #$DB		; Less than 'Z'+1?
	bcc LStore		; Then it's a letter - store it

	jmp LInput		; So sorry, try again
LStore:
	jsr COUT		; Print keypress on the screen
	and #$7F		; Clear MSB
	sta VOLnam,x		; Store character in VOLnam
	inx
	cpx #$0F		; Have 15 characters been entered?
	bcc LInput
LFormat:
	txa			; See if default VOLUME_NAME was taken
	bne LSetLEN
WLoop:
	lda MBlank,x		; Transfer 'BLANK' to VOLnam
	and #$7F		; Clear MSB
	sta VOLnam,x
	inx
	cpx #$05		; End of transfer?
	bcc WLoop
	lda #$13		; Reset CH to 19
	jsr HTAB
LSetLEN:
	jsr CLRLN		; Erase the rest of the line
	clc
	txa			; Add $F0 to Volume Name length
	adc #$F0		; Create STORAGE_TYPE, NAME_LENGTH byte
	sta VolLen
	jsr ECHO_OFF
	clc
	rts
LAbort:
	jsr ECHO_OFF
	sec
	rts

;---------------------------------------------------------
; Write boot blocks to disk
;---------------------------------------------------------
BootBlocks:
;	lda #$81		; Set Opcode to WRITE
;	CALLOS OS_D_CONTROL, FMT_CONTROL_PARMS	; Format, baby!
;	sta CallMLI+OS_CALL_OFFSET
;	lda #$00		; Set MLIBlk to 0
;	sta MLIBlk
;	sta MLIBlk+1
;	lda #<BootCode		; Set MLIbuf to BootCode
;	ldy #>BootCode
;	sta MLIbuf
;	sty MLIbuf+1
;	jsr CallMLI		; Write block #0 to target disk
;	jsr ZeroFill6800
;	lda #$01		; Set MLIBlk to 1
;	sta MLIBlk
;	jsr CallMLI		; Write block #1 to target disk	

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
