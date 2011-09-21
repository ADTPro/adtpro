;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2011 by David Schmidt
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
	lda #<DEVICES
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	ldx DUMP_INDEX
dumploop:
	jsr PRT1VOL
	inc DUMP_INDEX
	lda DUMP_INDEX	; Redundant?  Can't remember if inc loads accumulator or sets flags...
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
	CALLOS OS_D_INFO, D_INFO_PARMS
	bne SCAN_NEXT			; Skip it if we got an OS call error
	bit DEVMODE			; Check which kinds of devices we're looking for
	bvs :+				; Looking for formatters?  Branch if so.
	lda D_INFO_OPTION+2
	bpl SCAN_NEXT			; Skip it if it isn't a block device
	jmp SV				; Otherwise, check it out...
:
	lda D_INFO_OPTION+2
	asl				; Add to the list of formattable things
	asl
	asl
	bpl SCAN_NEXT
SV:	jsr SCAN_VOLUME
SCAN_NEXT:
	iny
	cpy #$19
	bne SCAN_DEVICE_LOOP
ODONE:
	lda LASTVOL
	sta LASTVOLZERO
	dec LASTVOLZERO
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
	bit DEVMODE
	bvs SV_NEW_NAME			; Looking for formatters?  Branch if so.
:	CALLOS OS_ONL, VOLUME_PARMS	; Retrieve the volume name
	beq SV_NEW_NAME
	cmp #DISKSW			; If we get a "disk switched" error, retry 
	bne SV_NONE
	jmp :-
SV_NEW_NAME:
	ldx LASTVOL
	jsr POINT_AT
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
	cmp #VNFERR
	bne :+
	jmp SV_DONE		; Volume not found - don't keep it
:	cmp #NOTNATIVE
	beq DEVMSG1		; Not an SOS volume - "<NO NAME>"
	jmp DEVMSG2		; Punt - generic I/O error

; DEVMSG - Add message in Y to the "Volume name" area of the device
DEVMSG:
	lda D_INFO_OPTION+5
	bne :+
	lda D_INFO_OPTION+6
	bne :+
	jmp SV_DONE		; Skip it if it has zero blocks
	lda MSGTBL,Y		; Y has an index into the messages table
	sta UTILPTR2
	lda MSGTBL+1,Y
	sta UTILPTR2+1
	tya	
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
	ldy #PMNONAME
	jsr DEVMSG
	jmp SV_NEW_NAME

; DEVMSG2 - Add "<I/O ERROR>" to the "Volume name"
DEVMSG2:
	ldy #PMIOERR
	jsr DEVMSG
	jmp SV_NEW_NAME

;---------------------------------------------------------
; INTERPRET_ONLINE
;
; Input: the row "enter" was hit on in A
; Output: (side effects; sets): 
;   UNITNBR, NonDiskII, NUMBLKS; *NOT* pdsoftx, pdslot, pdrive as in the ProDOS version
;---------------------------------------------------------
INTERPRET_ONLINE:
	tax
	jsr POINT_AT
	ldy #$00
	lda (UTILPTR),Y
	sta UNITNBR		; Save off the device (unit) number
	iny
	lda (UTILPTR),Y		; Extract unit capacity lo
	sta NUMBLKS
	iny
	lda (UTILPTR),Y		; Extract unit capacity hi
	sta NUMBLKS+1
	lda #$00
	sta NonDiskII		; Assume _no_ Disk II selected
	rts

;---------------------------------------------------------
; POINT_AT - Move the UTILPTR to the Xth item in the DEVICES structure
;
; Input:
;   X - The item to point at (0-indexed)
;
;---------------------------------------------------------
POINT_AT:
	lda #<DEVICES
	sta UTILPTR
	lda #>DEVICES
	sta UTILPTR+1
	cpx #$00
	beq POINT_DONE
POINT_ADD_ONE:
	jsr POINT_NEXT			; Add ONE_DEVICE_COSTS*LASTVOL to UTILPTR
	dex
	bne POINT_ADD_ONE
POINT_DONE:
	rts

;---------------------------------------------------------
; POINT_NEXT - Move the UTILPTR one item forward in the DEVICES structure
;
; Input:
;   UTILPTR - already ponting at the DEVICES structure somewhere
;
;---------------------------------------------------------
POINT_NEXT:
	clc				; Add ONE_DEVICE_COSTS*LASTVOL to UTILPTR
	lda UTILPTR
	adc #ONE_DEVICE_COSTS
	sta UTILPTR			; Move pointer ONE_DEVICE_COSTS bytes for each entry already existing
	bcc :+
	inc UTILPTR+1
:	rts

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
;
; Outputs:
;   Screen updated with one line of volume information from the current cursor position
;   UTILPTR points to the next device in the DEVICES table
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
	jsr PRD			; Print the block size

	jsr CROUT
	
	lda PRT1PTR+1
	sta UTILPTR+1
	lda PRT1PTR
	sta UTILPTR
	jsr POINT_NEXT		; Point UTILPTR at the next device

	rts

;---------------------------------------------------------
; CLEARVOLUMES - invalidate the volume cache
;---------------------------------------------------------
CLEARVOLFORMAT:
	lda #$40
	sta DEVMODE	; We want formatters
	jmp CV2
CLEARVOLUMES:
	lda #$00
	sta DEVMODE	; We want block devices
CV2:	lda #$00
	sta VCURROW
	sta LASTVOL
	rts


PRT1PTR: .res $02

LASTVOL:	.byte $00
DEVMODE:	.byte $00	; Device mode: $00 means block devices, $40 means format-capable devices

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