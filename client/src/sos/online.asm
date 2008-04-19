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

;---------------------------------------------------------
; Code
;---------------------------------------------------------
ONLINE:
	jsr DRAWBDR
	lda #$00
	sta DUMP_INDEX	; Haven't dumped anybody out yet
	lda LASTVOL	; Have we already done an online?
	bne dumpem	; Yes - dump 'em out
	jmp OSTART	; No - spend the time to scan drives
dumpem:			; Spit out what we discovered
dumploop:
	lda #<DEVICES
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	ldx DUMP_INDEX
	beq dump_PTR_DONE
dump_ADD_ONE:
	clc				; Add ONE_DEVICE_COSTS*LASTVOL to UTILPTR
	lda UTILPTR
	adc #ONE_DEVICE_COSTS
	sta UTILPTR			; Move pointer ONE_DEVICE_COSTS bytes for each entry already existing
	bcc :+
	inc UTILPTR+1
:	dex
	bne dump_ADD_ONE
dump_PTR_DONE:
	jsr PRT1VOL
	inc DUMP_INDEX
	lda DUMP_INDEX
	cmp LASTVOL
	bne dumploop
	rts

OSTART:
	lda #<DEVICES
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	ldy #$00
	lda #$00
	ldy #$01			; SOS devices are numbered $1-$18
SCAN_DEVICE_LOOP:
	sty D_INFO_NUM
	lda #$00
	ldx #D_INFO_OPTION_END-D_INFO_NAME
:	sta D_INFO_NAME-1,x		; Clean out D_INFO_NAME data
	dex
	bne :-
	clc
	CALLOS OS_D_INFO, D_INFO_PARMS
	jsr ERRORCK
	bcs :+
	lda D_INFO_NAME			; Skip it if it doesn't have a name
	beq :+
	lda D_INFO_OPTION+2		; Skip it if it isn't a block device
	bpl :+
	jsr SCAN_VOLUME
:	iny
	cpy #$19
	bne SCAN_DEVICE_LOOP
ODONE:
	rts

DUMP_INDEX:	.byte $00

;---------------------------------------------------------
; SCAN_VOLUME
;
; Given a device name, gets the volume name
; Output: adds an entry to the DEVICES table, updates LASTVOL, prints the volume info
;---------------------------------------------------------
SCAN_VOLUME:
	sty SLOWY
	lda #<D_INFO_NAME
	sta VOLUME_DEV_PTR
	lda #>D_INFO_NAME
	sta VOLUME_DEV_PTR+1
	ldx #$10
	lda #$00
:	dex
	sta VOLUME_NAME,X		; Clear out the volume name space
	bne :-
	clc
	CALLOS OS_ONL, VOLUME_PARMS	; Retrieve the volume name
	bne SV_NONE
SV_NEW_NAME:
	lda #<DEVICES			; Start by pointing at head of DEVICES table
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	ldx LASTVOL
	beq SV_PTR_DONE
SV_ADD_ONE:
	clc				; Add ONE_DEVICE_COSTS*LASTVOL to UTILPTR
	lda UTILPTR
	adc #ONE_DEVICE_COSTS
	sta UTILPTR			; Move pointer ONE_DEVICE_COSTS bytes for each entry already existing
	bcc :+
	inc UTILPTR+1
:	dex
	bne SV_ADD_ONE
SV_PTR_DONE:
	inc LASTVOL			; Count another volume as used

	ldy #$00
	lda D_INFO_NUM
	sta (UTILPTR),Y			; Copy in the device number
	iny

	lda D_INFO_OPTION+5
	sta (UTILPTR),Y			; Copy in the capacity in blocks lo
	iny
	lda D_INFO_OPTION+6
	sta (UTILPTR),Y			; Copy in the capacity in blocks hi
	iny

	ldx #$01			; Skip the length byte
SV_DEV_NAME_LOOP:
	lda D_INFO_NAME,X		; Copy in the device name
	bne :+
	lda #$20			; Swap spaces for zeroes
:	sta (UTILPTR),Y
	inx
	iny
	cpx #$10
	bne SV_DEV_NAME_LOOP

	ldx #$01			; Skip the length byte
SV_VOL_NAME_LOOP:
	lda VOLUME_NAME,X		; Copy in the volume name
	bne :+
	lda #$20			; Swap spaces for zeroes
:	sta (UTILPTR),Y
	inx
	iny
	cpx #$10
	bne SV_VOL_NAME_LOOP
	jsr PRT1VOL
SV_DONE:
	ldy SLOWY
	rts

SV_NONE:
	jsr DEVMSG2
	jmp SV_NEW_NAME

; DEVMSG - Add a message to the "Volume name" area of the device
DEVMSG:
	clc
	ror
	tax			; Message length table lookup - need to cut the index in half
	lda MSGLENTBL,X		; Look up message length
	tax
	ldy #$00
:	lda (UTILPTR2),Y
	iny
	sta VOLUME_NAME,Y
	dex
	bne :-
	rts

; DEVMSG1 - Add "<NO NAME>" to the "Volume name"
DEVMSG1:
	lda #<MNONAME
	sta UTILPTR2
	lda #>MNONAME
	sta UTILPTR2+1
	jsr DEVMSG
	rts

; DEVMSG2 - Add "<I/O ERROR>" to the "Volume name"
DEVMSG2:
	lda #<MIOERR
	sta UTILPTR2
	lda #>MIOERR
	sta UTILPTR2+1
	lda #PMIOERR
	jsr DEVMSG
	rts

; DEVMSG3 - Add "<NO DISK>" to the "Volume name"
DEVMSG3:
	lda #<MNODISK
	sta UTILPTR2
	lda #>MNODISK
	sta UTILPTR2+1
	jsr DEVMSG
	rts

;---------------------------------------------------------
; INTERPRET_ONLINE
;
; Input: the row "enter" was hit on in A
; Output: (side effects; sets): 
;   UNITNBR, pdsoftx, pdslot, pdrive, NonDiskII, NUMBLKS
;---------------------------------------------------------
INTERPRET_ONLINE:
	rts

;---------------------------------------------------------
; DRAWBDR
; 
; Draws the volume picker decorative border
; Y holds the top line message number
;---------------------------------------------------------
DRAWBDR:
	sty ZP
	ldx #$07
	ldy #$00
	jsr GOTOXY
	ldy ZP
	jsr WRITEMSG	; Y holds the top line message number

	ldx #$07	; Column
	ldy #$02	; Row
	jsr GOTOXY 
	ldy #PMSG19	; 'VOLUMES CURRENTLY ON-LINE:'
	jsr WRITEMSG

	ldx #$00	; Starting column
	ldy #$03	; Row
	jsr GOTOXY
	ldy #PMSG20	; 'DEVICE NAME      VOLUME NAME     BLOCKS'
	jsr WRITEMSG

	ldx #$00	; Starting column
	ldy #$04	; Row
	jsr GOTOXY
	ldy #PMSG21	; '---------------- --------------- ------'
	jsr WRITEMSG
VOLINSTRUCT:
	lda #$14	; Row
	jsr TABV
	ldy #PMSG22	; 'CHANGE SELECTION WITH ARROW KEYS&RETURN'
	jsr WRITEMSGLEFT

	lda #$15	; Row
	jsr TABV
	ldy #PMSG23	; 'SELECT WITH RETURN, ESC CANCELS'
	jsr WRITEMSGLEFT

	lda #$05	; starting row for slot/drive entries
	jsr TABV
	rts

;---------------------------------------------------------
; PRT1VOL
;
; Inputs:
;   UTILPTR points to the device to display in the DEVICES table
;---------------------------------------------------------
PRT1VOL:
	lda #$1e		; Set the cursor at the left edge
	jsr COUT
	lda #$20		; One space over
	jsr COUT

	lda UTILPTR
	sta PRT1PTR		; Save a pointer to the beginning of the structure
	lda UTILPTR+1
	sta PRT1PTR+1

	clc
	inc UTILPTR		; Move past the Device Number in the DEVICES structure
	bcc :+
	inc UTILPTR+1
:	ldy #$00
	lda (UTILPTR),Y
	sta NUMBLKS
	iny
	lda (UTILPTR),Y
	sta NUMBLKS+1		; Hang on to block capacity

	clc
	lda UTILPTR		; Move past the Volume Blocks in the DEVICES structure
	adc #$02
	sta UTILPTR
	bcc :+
	inc UTILPTR+1
:
	lda #$0f
	sta WRITE_LEN
	jsr WRITEMSG_RAW	; Write the device name

	lda #$20
	jsr COUT		; Space between Device Name and Volume Name

	clc
	lda PRT1PTR+1
	sta UTILPTR+1
	lda PRT1PTR
	adc #$12		; Move past the Device Number, Volume Blocks and Device Name in the DEVICES structure
	sta UTILPTR
	bcc :+
	inc UTILPTR+1
:
	lda #$0f
	sta WRITE_LEN
	jsr WRITEMSG_RAW	; Write the volume name

	lda #$20
	jsr COUT		; Space between Volume Name and Volume Blocks
	lda #$20
	jsr COUT		; Double space between Volume Name and Volume Blocks

	lda NUMBLKS
	ldx NUMBLKS+1
	ldy #CHR_SP
	jsr PRD		; Print the block size

	jsr CROUT
	rts

PRT1PTR: .res $02

;---------------------------------------------------------
; WHATUNIT - Which unit number is this index?
;
; Input:
;   A - index into the device table
;
; Returns:
;   A - unit number
;   X - unharmed
;---------------------------------------------------------
WHATUNIT:
	stx SLOWX	; Preserve X
	beq @READY
	tax		; Send the index to the X register
	lda #$00	; Now clear A out - need it for some arithmatic
@MORE:
	clc
	adc #$10
	dex
	cpx #$00
	bne @MORE
@READY:
	tax
	lda DEVICES,x
	and #$F0	; Extract unit number
	ldx SLOWX	; Restore X
	rts

;---------------------------------------------------------
; HOWBIG - How big is this volume?
;
; Input: 
;   A holds first byte of device list
;   X holds index into device list
; 
; Returns:
;   X unharmed
;   Updated capacity block table for index X/8
;
;---------------------------------------------------------

LASTVOL:	.byte $00

; DEVICES structure:
;
; Device Number	.byte
; Volume Blocks	.word
; Device Name	.res $0f
; Volume Name	.res $0f
;               ======
;               $21 bytes per entry; $18 possible entries
ONE_DEVICE_COSTS	=$21
DEVICES:	.res ONE_DEVICE_COSTS*$18, $ff
DEVICES_END	=*