; Copyright (C) 2007 - 2011 by David Schmidt
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

;*********************************************************************
;*                                 *            Movie:               *
;*       ProDOS Hyper-FORMAT       *     ProDOS Hyper-FORMAT II      *
;*                                 *           The Return            *
;*     created by Jerry Hewett     *   Modified by Gary Desrochers   *
;*         copyright  1985         *                                 *
;*     Living Legends Software     *        Tryll Software           *
;*                                 *                                 *
;* A Public Domain disk formatting * A Puplic Domain Disk Formatting *
;* routine for the ProDOS Disk Op- * You know the same as -------|   *
;* erating System.  These routines *<----------------------------|   *
;* can be included within your own * Except it now includes code for *
;* software as long as you give us * the 3.5 Disk and the Ram3 Disk. *
;* credit for developing them.     * (Please don't use this for any  *
;*                                 * SmartPort volumes bigger than   *
;*       Updated on: 23Aug85       * 2.1 Meg.) - fixed to a certain  *
;*                                 * extent in ADTPro integration    *
;***********************************                                 *
;                                  *      Updated on: 22Dec89        *
;                                  *                                 *
;                                  ***********************************

FormatDone:
	rts
AgainCloser:
	jmp Again
FormatEntry:
	ldy #PMFORMAT	; Format title line
	jsr PICKVOL	; A now has index into DEVICES table; UNITNBR holds chosen unit
	bmi FormatDone
	sta DevIndex	; Hang on to that DEVICES index
	ldy #PMNULL
	jsr WRITEMSG
	lda UNITNBR
	sta Slot
	tax
	lda NUMBLKS
	sta VolBlks
	lda NUMBLKS+1
	sta VolBlks+1
	lda #$00
	sta VolBlks+2
HypForm:
LSlot:
	ldy DevCnt		; Load how many devices
FLoop:
	lda DevList,y		;  since this isn't a sequential
	sta ListSlot		;  list then must go through each one
	and #$F0		;  must also store what is there for later
	cmp Slot
	beq ItIsNum
	dey
	bpl FLoop
	jmp NoUnit		; Used to be bmi
ItIsNum:
	txa			; Make the slot the indexed register
	lsr a			;  for getting device drive controller
	lsr a
	lsr a
	tay
	lda DevAdr,y		; Get it
	sta Addr		;  and save it
	lda DevAdr+1,y
	sta Addr+1
	tay
	and #$F0		; Next see if it begins with a C0
	cmp #$C0
	beq YesSmart		;  and if it does is a very smart device
	txa
	cmp #$B0		; If it isn't smart test for /Ram
	beq YesRam3
	clc
	ror a
	ror a
	ror a
	ror a
	and #$07
	ora #$C0
	sta Addr+1		; if it isn't either then treat it as
	jmp YesSmart1		;  smart and save what bank it is in.

YesRam3:
	lda Addr+1		; If you think it is a /Ram then check
	cmp #$FF		;  the bits that tell you so.
	beq Loop7		;  Does the Address pointer start with FF
	jmp NoUnit
Loop7:
	lda Addr		; And end with 00
	cmp #$00
	beq Loop8
	jmp NoUnit
Loop8:
	lda ListSlot
	and #$F3
	cmp #$B3
	beq Loop9
	jmp NoUnit
Loop9:
	lda #$13
	jsr TABV
	ldy #PMNULL
	jsr WRITEMSGLEFT
	jsr OldName
	jsr Ram3Form
Jump2:
	jmp Again
YesSmart:
	tya
	and #$0F
	rol a			; Move lower 4 bits to upper 4 bits
	rol a
	rol a
	rol a
	sta Slot		; Store result in FORMAT slot
YesSmart1:
	lda Addr+1		; Check signiture bytes in the Cn page
	sta Buffer+1		;  for a smart device.
	lda #$00
	sta Buffer
	ldy #$01
	lda (Buffer),y
	cmp #$20
	bne NoUnit
	ldy #$03
	lda (Buffer),y
	bne NoUnit
	ldy #$05
	lda (Buffer),y
	cmp #$03
	bne NoUnit
	ldy #$FF
	lda (Buffer),y
	cmp #$00		; Apples DiskII
	beq DiskII
	cmp #$FF		; Wrong DiskII
	beq NoUnit		;  must be a smart device.
	ldy #$07		; Test last signiture byte for the
	lda (Buffer),y		;  Protocol Converter.
	cmp #$3C
	beq YesSmart2		; Found a hard drive, CFFA, etc.
	cmp #$55
	beq YesSmart2		; Found a ProFile
	cmp #$00
	bne NoUnit		; It isn't so it's no device I know.
YesSmart2:
	jsr LName		; Get New name
	jsr OldName		; Ask if ready
	ldy #$FE
	lda (Buffer),y
	and #$08
	sta ShouldLLFormat	; Skip the test for low level format capability
	jsr SmartForm		; Jump to routine to format Smart Drive
	lda ListSlot
	and #$F0
	sta Slot
	jsr CodeWr		; Jump to routine to produce Bit map
	jmp Catalog		; Write Directory information to the disk
Jump3:	jmp Again

NoUnit:
	ldy #PMUnitNone		; Prompt to continue or not Because
	jsr WRITEMSGAREA	; There is no unit number like that
	jmp Again

DiskII:
	jsr LName		; Get new name
	jsr OldName		; Ask if ready
	jmp DIIForm		; Format DiskII

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
	sta CH
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
	sta CH
LSetLEN:
	jsr CLRLN		; Erase the rest of the line
	clc
	txa			; Add $F0 to Volume Name length
	adc #$F0		; Create STORAGE_TYPE, NAME_LENGTH byte
	sta VolLen
	rts
LAbort:
	pla			; Pop return address off the stack
	pla
	jmp Again

DIIForm:
	jsr REPLACEVOLNAME	; Replace the volume name
	jsr Format		; Format the disk
	jsr CodeWr		; Form Bitmap
	jmp Catalog		; Write Directory information to the disk

;**********************************
;*                                *
;* Write Block0, Block1 to disk   *
;*                                *
;**********************************
CodeWr:	lda #$81		; Set Opcode to WRITE
	sta CallMLI+OS_CALL_OFFSET
	lda #$00		; Set MLIBlk to 0
	sta MLIBlk
	sta MLIBlk+1
	lda #<BootCode		; Set MLIbuf to BootCode
	ldy #>BootCode
	sta MLIbuf
	sty MLIbuf+1
	jsr CallMLI		; Write block #0 to target disk
	jsr ZeroFill6800
	lda #$01		; Set MLIBlk to 1
	sta MLIBlk
	jsr CallMLI		; Write block #1 to target disk	

;**************************************
;*                                    *
;* Prepare BitMap and Link blocks     *
;* for writing to disk                *
;*                                    *
;**************************************
Fill:
	lda #$05		; Block 5 on Disk
	sta MLIBlk
	jsr ZeroFill6800
	lda #$05		; Length of DirTbl
	sta Count
LLink:
	ldx Count
	lda DirTbl,x		; Move Directory Link values into Buffer
	sta $6802		; Store next Directory block #
	dex
	lda DirTbl,x		; Fetch another # from DirTbl
	sta $6800		; Store previous Directory block #
	dex
	stx Count
	jsr CallMLI		; Write Directory Link values to disk
LDec:
	dec MLIBlk		; Decrement MLI block number
	lda MLIBlk		; See if MLIBlk = 2
	cmp #$02
	bne LLink		; Process another Link block

;**********************************
;*                                *
;* Calculate BitMap Size and cndo *
;*                                *
;**********************************
BlkCount:
; Fill full pages first, then do remainder page
	lda #$06		; First block to deal with: $06
	sta MLIBlk
	clc
	lda VolBlks+1
	sta FullPages
	lda VolBlks+2
	beq :+
	sec
:	ror FullPages		; VolBlks is now divided by 512 (we've already dropped byte 0)
	lsr FullPages		; ... by 1024
	lsr FullPages		; ... by 2048
	lsr FullPages		; ... by 4096

	beq LastBlock		; No full blocks?  Skip to remainder part.

	jsr FFFill6800		; Set up to fill pages
	lda #$81		; Change Opcode to $81 (WRITE)
	sta CallMLI+OS_CALL_OFFSET
	lda #$00		; Reset MLIbuf to $6800
	ldx #$68
	sta MLIbuf
	stx MLIbuf+1
	sta MLIBlk+1
	lda #$00		; Mark first blocks as used
	sta $6800
	sta $6801
	lda #$03
	sta $6802

	lda #$00
	sta Curblk

:	jsr Call2MLI		; Write Buffer (BitMap) to block on the disk
	lda #$ff		; Mark first blocks as unused again
	sta $6800
	sta $6801
	sta $6802
	inc MLIBlk
	inc Curblk
	lda Curblk
	cmp FullPages
	bne :-

LastBlock:
	jsr BlkRemainder
	jsr Call2MLI
	rts

BlkRemainder:
	jsr ZeroFill6800
	lda VolBlks+1		; Where # of blocks are stored
	ldx VolBlks
	ldy VolBlks+2		; Can't deal with block devices this big
	stx Count+1		; Divide the # of blocks by 8 for bitmap
	lsr a			;  calculation
	ror Count+1
	lsr a
	ror Count+1
	lsr a
	ror Count+1
	sta Count+2
BitMapCode:
	lda FullPages		; Only tick off 7 blks if this is the only page in the BAM
	bne BitMapNotFirst
	lda #%00000001		; Clear first 7 blocks
	sta (Buffer),y
	jmp BitMapGo
BitMapNotFirst:
	lda #$ff
	sta (Buffer),y
BitMapGo:
	ldy Count+1		; Original low block count value
	bne Jump11		; if it is 0 then make FF
	dey			; Make FF
	dec Count+2		; Make 256 blocks less one
	sty Count+1		; Make FF new low block value
Jump11:
	ldx Count+2		; High Block Value
	bne Jump15		; If it isn't equal to 0 then branch
	ldy Count+1
	jmp Jump19

Jump15:
	lda #$69		; Set the adress of the upper part of
	sta Buffer+1		;  Block in bitmap being created
	lda #%11111111
	ldy Count+1		; Using the low byte count
Jump20:
	dey
	sta (Buffer),y		; Store them
	beq Jump17
	jmp Jump20
Jump17:
	dey			; Fill in first part of block
	lda #$68
	sta Buffer+1
Jump19:
	lda #%11111111
	dey
	sta (Buffer),y
	cpy #$01		; Except the first byte.
	beq Jump18
	jmp Jump19
Jump18:
	rts

Curblk:	.res 1

;*************************************
;*                                   *
;* Catalog - Build a Directory Track *
;*                                   *
;*************************************
Catalog:
	lda #$81		; Change Opcode to $81 (WRITE)
	sta CallMLI+OS_CALL_OFFSET
	clc
	lda #$06
	adc FullPages
	sta MLIBlk
	lda #$00		; Reset MLIbuf to $6800
	ldx #$68
	sta MLIbuf
	stx MLIbuf+1
	sta MLIBlk+1
	jsr Call2MLI		; Write Buffer (BitMap) to block #6 on the disk
	CALLOS OS_GET_TIME, 0		; Call for time and date
	lda $BF90		; Get them and save them into the
	sta Datime		; Directory to be written.
	lda $BF91
	sta Datime+1
	lda $BF92
	sta Datime+2
	lda $BF93
	sta Datime+3
	jsr ZeroFill6800
	ldy #$2A		; Move Block2 information to $6800
CLoop:
	lda Block2,y
	sta (Buffer),y
	dey
	bpl CLoop
	lda #$02		; Write block #2 to the disk
	sta MLIBlk
	jsr Call2MLI
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
Call2MLI:
	jsr CallMLI
	rts

;*************************************
;*                                   *
;* CallMLI - Call the MLI Read/Write *
;* routines to transfer blocks to or *
;* from memory                       *
;*                                   *
;*************************************
CallMLI:
	CALLOS OS_WRITEBLOCK, Parms
	bcs MLIError
	rts
MLIError:
	sta ZP
	pla
	pla
	pla
	pla
	lda ZP
	jmp Died

;***********************************
;*                                 *
;* FORMAT - Format the target disk *
;*                                 *
;***********************************
Format:
	lda Slot		; Fetch target drive SLOTNUM value
	pha			; Store it on the stack
	and #$70		; Mask off bit 7 and the lower 4 bits
	sta SlotF		; Store result in FORMAT slot storage
	tax			; Assume value of $60 (drive #1)
	pla			; Retrieve value from the stack
	bpl LDrive1		; If < $80 the disk is in drive #1
	inx			; Set X offset to $61 (drive #2)
LDrive1:
	lda Select,x		; Set softswitch for proper drive
	ldx SlotF		; Set X offset to FORMAT slot/drive
	lda DiskON,x		; Turn the drive on
	lda ModeRD,x		; Set Mode softswitch to READ
	lda DiskRD,x		; Read a byte
	lda #$23		; Assume head is on track 35
	sta TRKcur
	lda #$00		; Destination is track 0
	sta TRKdes
	jsr Seek		; Move head to track 0
	ldx SlotF		; Turn off all drive phases
	lda Step0,x
	lda Step2,x
	lda Step4,x
	lda Step6,x
	lda TRKbeg		; Move TRKbeg value (0) to Track
	sta Track
	jsr Build		; Build a track in memory at $6700

;*******************************
;*                             *
;* WRITE - Write track to disk *
;*                             *
;*******************************
Write:
	jsr Calc		; Calculate new track/sector/checksum values
	jsr Trans		; Transfer track in memory to disk
	bcs DiedII		; If carry set, something died
MInc:
	inc Track		; Add 1 to Track value
	lda Track		; Is Track > ending track # (TRKend)?
	cmp TRKend
	beq LNext		; More tracks to FORMAT
	bcs Done		; Finished.  Exit FORMAT routine
LNext:
	sta TRKdes		; Move next track to FORMAT to TRKdes
	jsr Seek		; Move head to that track
	jmp Write		; Write another track
Done:
	ldx SlotF		; Turn the drive off
	lda DiskOFF,x
	rts			; FORMAT is finished. Return to calling routine
DiedII:
	pha			; Save MLI error code on the stack
	jsr Done
	pla			; Retrieve error code from the stack
	jmp Died		; Prompt for another FORMAT...


;
; Note - the routine named Trans: and entrypoint named Trans2:
; have moved to the main.asm in order to keep it within a
; page boundary.
;


;**************************************
;*                                    *
;* Died - Something awful happened to *
;* the disk or drive. Die a miserable *
;* death...                           *
;*                                    *
;**************************************
Died:
	cmp #$27
	beq DriveOpen
	cmp #$28
	beq DriveOpen
	cmp #$2F
	beq DiskError
	cmp #$2B
	beq Protected
	jmp NoDied
DiskError:
	ldy #PMNoDisk
	jmp DiedOut
DriveOpen:
	ldy #PMDead
	jmp DiedOut
Protected:
	ldy #PMProtect
	jmp DiedOut
NoDied:
	pha			; Save MLI error code on the stack
	ldy #PMUnRecog
	jsr WRITEMSGAREA
	pla			; Retrieve error code from the stack
	jsr PRBYTE		; Print the MLI error code
	jmp Again
DiedOut:
	jsr WRITEMSGAREA
	jmp Again		; Prompt for another FORMAT...

;************************************
;*                                  *
;* BUILD - Build GAP1 and 16 sector *
;* images between $6700 and $8000   *
;*                                  *
;************************************
Build:
	lda #$10		; Set Buffer to $6710
	ldx #$67
	sta Buffer
	stx Buffer+1
	ldy #$00		; (Y offset always zero)
	ldx #$F0		; Build GAP1 using $7F (sync byte)
	lda #$7F
	sta LByte
	jsr LFill		; Store sync bytes from $6710 to $6800
	lda #$10		; Set Count for 16 loops
	sta Count
LImage:
	ldx #$00		; Build a sector image in the Buffer area
ELoop:
	lda LAddr,x		; Store Address header, info & sync bytes
	beq LInfo
	sta (Buffer),y
	jsr LInc		; Add 1 to Buffer offset address
	inx
	bne ELoop
LInfo:
	ldx #$AB		; Move 343 bytes into data area
	lda #$96		; (4&4 encoded version of hex $00)
	sta LByte
	jsr LFill
	ldx #$AC
	jsr LFill
	ldx #$00
YLoop:
	lda LData,x 		; Store Data Trailer and GAP3 sync bytes
	beq LDecCnt
	sta (Buffer),y
	jsr LInc
	inx
	bne YLoop
LDecCnt:
	clc
	dec Count
	bne LImage
	rts			; Return to write track to disk (WRITE)
LFill:
	lda LByte
	sta (Buffer),y		; Move A register to Buffer area
	jsr LInc		; Add 1 to Buffer offset address
	dex
	bne LFill
	rts
LInc:
	clc
	inc Buffer		; Add 1 to Buffer address vector
	bne LDone
	inc Buffer+1
LDone:	rts

;***********************************
;*                                 *
;* CALC - Calculate Track, Sector, *
;* and Checksum values of the next *
;* track using 4&4 encoding        *
;*                                 *
;***********************************
Calc:
	lda #$03		; Set Buffer to $6803
	ldx #$68
	sta Buffer
	stx Buffer+1
	lda #$00		; Set Sector to 0
	sta Sector
ZLoop:
	ldy #$00		; Reset Y offset to 0
	lda #$FE		; Set Volume # to 254 in 4&4 encoding
	jsr LEncode
	lda Track		; Set Track, Sector to 4&4 encoding
	jsr LEncode
	lda Sector
	jsr LEncode
	lda #$FE		; Calculate the Checksum using 254
	eor Track
	eor Sector
	jsr LEncode
	clc			; Add 385 ($181) to Buffer address
	lda Buffer
	adc #$81
	sta Buffer
	lda Buffer+1
	adc #$01
	sta Buffer+1
	inc Sector		; Add 1 to Sector value
	lda Sector		; If Sector > 16 then quit
	cmp #$10
	bcc ZLoop
	rts			; Return to write track to disk (WRITE)
LEncode:
	pha			; Put value on the stack
	lsr a   		; Shift everything right one bit
	ora #$AA		; OR it with $AA
	sta (Buffer),y		; Store 4&4 result in Buffer area
	iny
	pla			; Retrieve value from the stack
	ora #$AA		; OR it with $AA
	sta(Buffer),y		; Store 4&4 result in Buffer area
	iny
	rts

;*************************************
;*                                   *
;* Seek - Move head to desired track *
;*                                   *
;*************************************
Seek:
	lda #$00		; Set InOut flag to 0
	sta LInOut
	lda TRKcur		; Fetch current track value
	SEC
	SBC TRKdes		; Subtract destination track value
	beq LExit		; If = 0 we're done
	bcs LMove
	eor #$FF		; Convert resulting value to a positive number
	adc #$01
LMove:
	sta Count		; Store track value in Count
	rol LInOut		; Condition InOut flag
	lsr TRKcur		; Is track # odd or even?
	rol LInOut		; Store result in InOut
	asl LInOut		; Shift left for .Table offset
	ldy LInOut
ALoop:
	lda LTable,y		; Fetch motor phase to turn on
	jsr Phase		; Turn on stepper motor
	lda LTable+1,y		; Fetch next phase
	jsr Phase		; Turn on stepper motor
	tya
	eor #$02		; Adjust Y offset into LTable
	tay
	dec Count		; Subtract 1 from track count
	bne ALoop
	lda TRKdes		; Move current track location to TRKcur
	sta TRKcur
LExit:
	rts			; Return to calling routine

;**********************************
;*                                *
;* PHASE - Turn the stepper motor *
;* on and off to move the head    *
;*                                *
;**********************************
Phase:
	ora SlotF		; OR Slot value to PHASE
	tax
	lda Step1,x		; PHASE on...
	lda #$56		; 20 ms. delay
	jsr DELAY
	lda Step0,x		; PHASE off...
	rts

;**********************************
;*                                *
;* Format a Ram3 device.          *
;*                                *
;**********************************
Ram3Form:
	lda #3			; Format Request number
	sta $42
	lda Slot		; Slot of /Ram
	sta $43
	lda #$00		; Buffer space if needed Low byte
	sta $44
	lda #$67		;  and high byte
	sta $45

	lda $C08B		; Read and write Ram, using Bank 1
	lda $C08B

	jsr Ram3Dri
	bit $C082		; Read ROM, use Bank 2(Put back on line)
	bcs Ram3Err
	rts

Ram3Dri:
	jmp (Addr)
Ram3Err:
	tax
	pla
	pla
	txa
	jmp Died

;**********************************
;*                                *
;* Format a SmartPort Device      *
;*                                *
;**********************************
SmartForm:
	lda ShouldLLFormat	; Will be $08 if so
	beq SmartFormDone
	lda #3  		; Give Protocol Converter a Format Request
	sta $42 		; Give it Slot number
	lda ListSlot
	and #$F0
	sta $43
	lda #$00		; Give a buffer which probably won't be
	sta $44 		;  used.
	lda #$68
	sta $45

	jsr SmartDri
	bcs SmartErr		; Skip the test for successful low level formatting
	clc
SmartFormDone:
	jsr REPLACEVOLNAME	; Replace the volume name
	rts

SmartDri:
	jmp (Addr)
SmartErr:
	tax
	pla
	pla
	txa
	jmp Died

ShouldLLFormat:
	.res 1

;**********************************
;*                                *
;* Is there an old name?          *
;*                                *
;**********************************
OldName:
	lda #$15
	jsr TABV
	ldy #PMTheOld
	jsr WRITEMSGLEFT
	jsr YNLOOP
	bne OldDone
	pla
	pla
	jmp Again
OldDone:
	rts

;***********************************
;*                                 *
;* Fill6800: clear buffer at $6800 *
;*                                 *
;***********************************
FFFill6800:
	lda #$FF
	pha
	jmp Fill6800Go
ZeroFill6800:
	lda #$00
	pha
Fill6800Go:
	lda #$00		; Set Buffer, MLIbuf to $6800
	ldx #$68
	sta MLIbuf
	sta Buffer
	stx MLIbuf+1
	stx Buffer+1
	tay			; Fill $6800-$69FF with zeros
	ldx #$01		; Fill 2 pages of 256 bytes
	pla
LZero:
	sta (Buffer),y
	iny
	bne LZero
	inc Buffer+1
	dex
	bpl LZero
	lda #$00
	sta Buffer
	lda #$68		; Reset Buffer to $6800
	sta Buffer+1
	rts

REPLACEVOLNAME:
	lda DevIndex
	asl
	asl
	asl
	asl
	tax
	;jsr Mult16		; Set x to the start of the DEVICES table
	lda #>DEVICES
	sta UTILPTR+1
	lda #<DEVICES
	sta UTILPTR
	txa
	clc
	adc UTILPTR
	sta UTILPTR
	bcc :+
	inc UTILPTR+1
:
	lda VolLen
	and #$0f
	sta Util
	tay			; Set y to the number of digits to transfer
:
	lda VOLnam-1,y
	sta (UTILPTR),y
	dey
	bne :-

	ldy #$00
	lda (UTILPTR),y		; Load the length of the dev name in DEVICES
	and #$f0
	sta (UTILPTR),y
	clc
	adc Util
	sta (UTILPTR),y
	rts

;*************************
;*                       *
;* Variable Storage Area *
;*                       *
;*************************
Info:
	.byte $02
	.res 1
	.addr VolLen
Parms:	.byte $03		; Parameter count = 3
Slot:	.byte $60		; Default to S6,D1
MLIbuf:	.addr BootCode		; Default buffer address
MLIBlk:	.byte $00,$00		; Default block number of 0
QSlot:	.res 1			; Quit Slot number
ListSlot:
	.res 1			; Saving the slot total from the list
Addr:	.res 2			; Address for indirect jump
LByte:	.res 1			; Storage for byte value used in Fill
LAddr:
	.byte $D5,$AA,$96	; Address header
	.byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ; Volume #, Track, Sector, Checksum
	.byte $DE,$AA,$EB	; Address trailer
	.byte $7f,$7f,$7f,$7f,$7f,$7f	; GAP2 sync bytes
	.byte $D5,$AA,$AD	; Buffer header
	.byte $00		; End of Address information
LData:
	.byte $DE,$AA,$EB	; Data trailer
	.byte $7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f,$7f  ;GAP3 sync bytes
	.byte $00     		; End of Data information

LInOut:	.res 1   		; Inward/Outward phase for stepper motor
LTable:
	.byte $02,$04,$06,$00	; Phases for moving head inward
	.byte $06,$04,$02,$00	;    |    |    |      |  outward

Block2:	.byte $00,$00,$03,$00
VolLen:	.res 1			; $F0 + length of Volume Name
VOLnam:	.res 15			; Volume Name
Reserved:
	.res 6
UpLowCase:
	.byte $00,$00
Datime:
	.res 4
Version:
	.byte 01
	.byte $00,$C3,$27,$0D
	.byte $00,$00,$06,$00
VolBlks:
	.res 3			; Number of blocks available
DirTbl:
	.byte $02,$04,$03	; Linked list for directory blocks
	.byte $05,$04,$00
BitTbl:
	.byte $7f ; dc B'01111111'	; BitMap mask for bad blocks
	.byte $bf ; dc B'10111111'
	.byte $df ; dc B'11011111'
	.byte $ef ; dc B'11101111'
	.byte $f7 ; dc B'11110111'
	.byte $fb ; dc B'11111011'
	.byte $fd ; dc B'11111101'
	.byte $fe ; dc B'11111110'
Count:	.res 3	 		; General purpose counter/storage byte
Pointer:
	.res 2	 		; Storage for track count (8 blocks/track)
Track:	.res 2	 		; Track number being FORMATted
Sector:	.res 2			; Current sector number (max=16)
SlotF:	.res 2			; Slot/Drive of device to FORMAT
TRKcur:	.res 2			; Current track position
TRKdes:	.res 2 			; Destination track position
TRKbeg:	.byte 00		; Starting track number
TRKend:	.byte 35		; Ending track number
FullPages:
	.byte 00		; Number of BAM pages to fill
DevIndex:
	.byte 00		; Storage for index into DEVICES table
Util:	.byte 00
BootCode:
; Floppy boot code at block 0; block 1 is zeroed out
	.byte $01,$38,$B0,$03,$4C,$32,$A1,$86,$43,$C9,$03,$08,$8A,$29,$70,$4A,$4A,$4A,$4A,$09,$C0,$85,$49,$A0
	.byte $FF,$84,$48,$28,$C8,$B1,$48,$D0,$3A,$B0,$0E,$A9,$03,$8D,$00,$08,$E6,$3D,$A5,$49,$48,$A9,$5B,$48
	.byte $60,$85,$40,$85,$48,$A0,$63,$B1,$48,$99,$94,$09,$C8,$C0,$EB,$D0,$F6,$A2,$06,$BC,$1D,$09,$BD,$24
	.byte $09,$99,$F2,$09,$BD,$2B,$09,$9D,$7F,$0A,$CA,$10,$EE,$A9,$09,$85,$49,$A9,$86,$A0,$00,$C9,$F9,$B0
	.byte $2F,$85,$48,$84,$60,$84,$4A,$84,$4C,$84,$4E,$84,$47,$C8,$84,$42,$C8,$84,$46,$A9,$0C,$85,$61,$85
	.byte $4B,$20,$12,$09,$B0,$68,$E6,$61,$E6,$61,$E6,$46,$A5,$46,$C9,$06,$90,$EF,$AD,$00,$0C,$0D,$01,$0C
	.byte $D0,$6D,$A9,$04,$D0,$02,$A5,$4A,$18,$6D,$23,$0C,$A8,$90,$0D,$E6,$4B,$A5,$4B,$4A,$B0,$06,$C9,$0A
	.byte $F0,$55,$A0,$04,$84,$4A,$AD,$02,$09,$29,$0F,$A8,$B1,$4A,$D9,$02,$09,$D0,$DB,$88,$10,$F6,$29,$F0
	.byte $C9,$20,$D0,$3B,$A0,$10,$B1,$4A,$C9,$FF,$D0,$33,$C8,$B1,$4A,$85,$46,$C8,$B1,$4A,$85,$47,$A9,$00
	.byte $85,$4A,$A0,$1E,$84,$4B,$84,$61,$C8,$84,$4D,$20,$12,$09,$B0,$17,$E6,$61,$E6,$61,$A4,$4E,$E6,$4E
	.byte $B1,$4A,$85,$46,$B1,$4C,$85,$47,$11,$4A,$D0,$E7,$4C,$00,$20,$4C,$3F,$09,$26,$50,$52,$4F,$44,$4F
	.byte $53,$20,$20,$20,$20,$20,$20,$20,$20,$20,$A5,$60,$85,$44,$A5,$61,$85,$45,$6C,$48,$00,$08,$1E,$24
	.byte $3F,$45,$47,$76,$F4,$D7,$D1,$B6,$4B,$B4,$AC,$A6,$2B,$18,$60,$4C,$BC,$09,$A9,$9F,$48,$A9,$FF,$48
	.byte $A9,$01,$A2,$00,$4C,$79,$F4,$20,$58,$FC,$A0,$1C,$B9,$50,$09,$99,$AE,$05,$88,$10,$F7,$4C,$4D,$09
	.byte $AA,$AA,$AA,$A0,$D5,$CE,$C1,$C2,$CC,$C5,$A0,$D4,$CF,$A0,$CC,$CF,$C1,$C4,$A0,$D0,$D2,$CF,$C4,$CF
	.byte $D3,$A0,$AA,$AA,$AA,$A5,$53,$29,$03,$2A,$05,$2B,$AA,$BD,$80,$C0,$A9,$2C,$A2,$11,$CA,$D0,$FD,$E9
	.byte $01,$D0,$F7,$A6,$2B,$60,$A5,$46,$29,$07,$C9,$04,$29,$03,$08,$0A,$28,$2A,$85,$3D,$A5,$47,$4A,$A5
	.byte $46,$6A,$4A,$4A,$85,$41,$0A,$85,$51,$A5,$45,$85,$27,$A6,$2B,$BD,$89,$C0,$20,$BC,$09,$E6,$27,$E6
	.byte $3D,$E6,$3D,$B0,$03,$20,$BC,$09,$BC,$88,$C0,$60,$A5,$40,$0A,$85,$53,$A9,$00,$85,$54,$A5,$53,$85
	.byte $50,$38,$E5,$51,$F0,$14,$B0,$04,$E6,$53,$90,$02,$C6,$53,$38,$20,$6D,$09,$A5,$50,$18,$20,$6F,$09
	.byte $D0,$E3,$A0,$7F,$84,$52,$08,$28,$38,$C6,$52,$F0,$CE,$18,$08,$88,$F0,$F5,$BD,$8C,$C0,$10,$FB,$00
	.byte $00,$00,$00,$00,$00,$00,$00,$00
