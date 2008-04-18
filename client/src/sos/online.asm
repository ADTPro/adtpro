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
	lda LASTVOL	; Have we already done an online?
	beq OSTART	; No - spend the time to scan drives

dumpem:			; Just spit out what we already discovered
	tay
	iny
	ldx #$00
dumploop:
	jsr PRT1VOL
	txa
	clc
	adc #$10
	tax
	dey
	bne dumploop
	rts

OSTART:
	lda #<DEVICES
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	ldy #$00
	lda #$00
OCLEAN:
	ldx #$03
OPAGE:	sta (UTILPTR),Y	; Clear out devices table
	iny
	bne OPAGE
	clc
	inc UTILPTR
	bcc :+
	inc UTILPTR+1
:	dex		; Need to do this 3 times... $318 bytes in that table!
	bne OPAGE

:	sta (UTILPTR),Y	; Clear out remainder of devices table
	iny
	cpy #<DEVICES_END-DEVICES
	bne :-

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
	bcs :+
	lda D_INFO_NAME
	beq :+
	jsr SCAN_VOLUME
:	iny
	cpy #$19
	bne SCAN_DEVICE_LOOP
ODONE:
	rts

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
	bcs SV_DONE
	lda #<DEVICES			; Start by pointing at head of DEVICES table
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	ldx LASTVOL
	beq SV_PTR_DONE
SV_ADD_ONE:
	clc
	lda UTILPTR
	adc #ONE_DEVICE_COSTS
	sta UTILPTR			; Move pointer ONE_DEVICE_COSTS bytes for each entry already existing
	bcc :+
	inc UTILPTR+1
:	dex
	bne SV_ADD_ONE
SV_PTR_DONE:
	inc LASTVOL			; Count another volume used
	ldy #$00
	lda D_INFO_NUM
	sta (UTILPTR),Y			; Copy in the device number
	iny

	ldx #$01			; Skip the length byte
SV_DVR_NAME_LOOP:
	lda D_INFO_NAME,X		; Copy in the driver name
	bne :+
	lda #$20			; Swap spaces for zeroes
:	sta (UTILPTR),Y
	inx
	iny
	cpx #$10
	bne SV_DVR_NAME_LOOP

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

	lda D_INFO_OPTION+5
	sta (UTILPTR),Y
	iny
	lda D_INFO_OPTION+6
	sta (UTILPTR),Y
	jsr PRT1VOL
SV_DONE:
	ldy SLOWY
	rts

; DEVMSG - Add a message to the "Volume name" area of the device
DEVMSG:
	txa		; Preserve X
	pha

	clc
	adc #<DEVICES
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1	; UTILPTR now holds DEVICES + X
	
	ldy #$00
DMLOOP:
	lda MNONAME,Y
	cmp #$00
	beq DMDONE
	iny
	sta (UTILPTR),Y
	jmp DMLOOP
DMDONE:
	tya
	ldy #$00
	ora (UTILPTR),Y
	sta (UTILPTR),Y

	pla
	tax
	rts

; DEVMSG1 - Add "<NO NAME>" to the "Volume name"
DEVMSG1:
	lda #<MNONAME
	sta DMLOOP+1
	lda #>MNONAME
	sta DMLOOP+2
	jsr DEVMSG
	rts

; DEVMSG2 - Add "<I/O ERROR>" to the "Volume name"
DEVMSG2:
	lda #<MIOERR
	sta DMLOOP+1
	lda #>MIOERR
	sta DMLOOP+2
	jsr DEVMSG
	rts

; DEVMSG3 - Add "<NO DISK>" to the "Volume name"
DEVMSG3:
	lda #<MNODISK
	sta DMLOOP+1
	lda #>MNODISK
	sta DMLOOP+2
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
;   UTILPTR points to the device to dump in the DEVICES table
;---------------------------------------------------------
PRT1VOL:
	lda #UTILPTR
	sta PRT1PTR
	lda #UTILPTR+1
	sta PRT1PTR

	clc
	inc UTILPTR
	bcc :+
	inc UTILPTR+1
:	lda #$f
	sta WRITE_LEN
	jsr WRITEMSG_RAW
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
; Driver Name	.res $0f
; Volume Name	.res $0f
; Volume Blocks	.word
;               ======
;               $21 bytes per entry; $18 possible entries
ONE_DEVICE_COSTS	=$21
DEVICES:	.res ONE_DEVICE_COSTS*$18
DEVICES_END	=*