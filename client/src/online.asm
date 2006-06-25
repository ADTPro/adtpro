*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

*---------------------------------------------------------
* Code
*---------------------------------------------------------
ONLINE
	LDA #$00
	sta LASTVOL

	tax
O.CLEAN	sta CAPBLKS,X	Clear out capacity-in-blocks table
	inx
	cpx #$20
	bne O.CLEAN

	LDA #$02	MLI call: ONLINE status
	STA PARMBUF
	LDA #$00
	STA PARMBUF+1
	LDA #DEVICES
	STA PARMBUF+2
	LDA /DEVICES
	STA PARMBUF+3
	JSR MLI
	.db PD_ONL
	.da PARMBUF
	BNE O.ERROR

	ldx #$00	X is our index into the device table
loop.1	lda devices,x
	cmp #$00
	beq done

	and #$0F	Extract name length
	beq OL.SK1	If zero - skip to HOWBIG
	jsr HOWBIG2
	bcs OL.SK3	We found a size - skip to next step
OL.SK1	lda devices,x
	and #$F0	Extract unit number in the high nybble
	jsr HOWBIG
OL.SK3	lda devices,x
	and #$0F	Extract name length
	bne skip
OL.SK2	lda devices+1,x
	cmp #$52	Not Pro-DOS
	bne OL.1
	jsr DEVMSG1
	jmp skip
OL.1	cmp #$27	I/O Error
	bne OL.2
	jsr DEVMSG2
	jmp skip
OL.2	cmp #$28	No device connected
	bne OL.3
	jsr DEVMSG3
	jmp skip
OL.3	cmp #$2F	Empty (typical of slot 5)
	bne skip
	jsr DEVMSG3

skip
	jsr prt1vol
	inc LASTVOL
	txa
	clc
	adc #$10
	tax
	bcc loop.1
DONE	dec LASTVOL	Save off the last volume number (index)
	RTS

O.ERROR	sta parmbuf
	LDA #$FF
	STA PARMBUF+1
	RTS
abt	brk

* DEVMSG - Add a message to the "Volume name" area of the device
DEVMSG
	txa		Preserve X
	pha

	clc
	adc #DEVICES
	sta <UTILPTR
	lda /DEVICES
	sta <UTILPTR+1	UTILPTR now holds DEVICES + X
	
	ldy #$00
DMLOOP
	lda MNONAME,Y
	cmp #$00
	beq DMDONE
	iny
	sta (UTILPTR),Y
	jmp DMLOOP
DMDONE
	tya
	ldy #$00
	ora (UTILPTR),Y
	sta (UTILPTR),Y

	pla
	tax
	rts

* DEVMSG1 - Add "<NO NAME>" to the "Volume name"
DEVMSG1
	lda #MNONAME
	sta DMLOOP+1
	lda /MNONAME
	sta DMLOOP+2
	jsr DEVMSG
	rts

* DEVMSG2 - Add "<I/O ERROR>" to the "Volume name"
DEVMSG2
	lda #MIOERR
	sta DMLOOP+1
	lda /MIOERR
	sta DMLOOP+2
	jsr DEVMSG
	rts

* DEVMSG3 - Add "<NO DISK>" to the "Volume name"
DEVMSG3
	lda #MNODISK
	sta DMLOOP+1
	lda /MNODISK
	sta DMLOOP+2
	jsr DEVMSG
	rts

*---------------------------------------------------------
* WHATUNIT - Which unit number is this index?
*
* Input:
*   A - index into the device table
*
* Returns:
*   A - unit number
*   X - unharmed
*---------------------------------------------------------
WHATUNIT
	stx <ZP		Preserve X
	beq WU.READY
	tax		Send the index to the X register
	lda #$00	Now clear A out - need it for some arithmatic
WU.MORE	clc
	adc #$10
	dex
	cpx #$00
	bne WU.MORE
WU.READY
	tax
	lda devices,x
	and #$F0	Extract unit number
	ldx <ZP		Restore X
	rts

*---------------------------------------------------------
* HOWBIG - How big is this volume?
*
* Input: 
*   A holds first byte of device list
*   X holds index into device list
* 
* Returns:
*   X unharmed
*   Updated capacity block table for index X/8
*
*---------------------------------------------------------

HOWBIG
	stx <ZP		Preserve X

	and #$F0
	sta onlineUnit
	and #$70
	lsr
	lsr
	lsr
	lsr
	ora #$C0
	sta BLKPTR+1

	lda #$01	1st ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	cmp #$20
	beq Ok1
	jmp ProStatus

Ok1
	lda #$03	2nd ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	beq Ok2
	jmp ProStatus

Ok2
	lda #$05	3rd ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	cmp #$03
	beq BlockDev
	jmp ProStatus

* We have a block device of some sort here.

BlockDev
	lda #$FF
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	bne NotDiskII

* It's a Disk ][ so hard code its size to 280 ($0118) blocks.

	lda #$01
	sta DevSize+1
	lda #$18
	sta DevSize
	jsr SAVSIZE
	jmp h.exit

NotDiskII 

	lda #$07	         4th ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	beq Smartport
	jmp ProStatus

Smartport 

* We have a Smartport device so get it's blocksize from $FC and $FD offset.
* If this value is zeros then we must do a Smartport status call to get size.

	lda #$FC
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	sta DevSize
	inc BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	sta DevSize+1
	ora DevSize
	bne GoodSize
	jmp SmartStatus

GoodSize
	jsr SAVSIZE
	jmp h.exit

* Do a ProDOS driver status call to retrieve device block size.

ProStatus

	lda onlineUnit	Compute slot/drive offset by dividing
	lsr a		unit number by 16.
	lsr a
	lsr a
	tax		Move offset to index.

	lda MLIADDR,x	Get low byte of ProDOS driver address
	sta BLKPTR
	inx
	lda MLIADDR,x	Get high byte of ProDOS driver address
	sta BLKPTR+1

	php		Save status
	sei		Interrupts off

	lda #0
	sta $42		Status call

	lda onlineUnit
	sta $43		Unit number
	lda #$00
	sta $44
	lda #$00
	sta $45

	lda #0
	sta $46
	sta $47

	lda $C08B	Read and write enable the language card
	lda $C08B	with bank 1 on.

	jsr CallDriver	Call ProDOS driver.

	bit $C082	Put ROM back on-line
	bcs Error

OkError

	stx DevSize	Save device size.
	sty DevSize+1

NoMessage
	plp		Restore status
	jsr SAVSIZE
	jmp h.exit

CallDriver

	jmp  (BLKPTR)

Error

	cmp #$2B	Write protect error is ok.
	beq OKError
	cmp #$2F	Disk offline error
	beq OKError

	lda #$00
	sta DevSize	Unknown size
	sta DevSize+1

	cmp #$28	Device not connected error
	beq NoMessage	(This error shouldn't happen here)

	plp		Restore status

	jsr SAVSIZE
	jmp h.exit

	rts

* Do a Smartport status call to retrieve device block size

Smartstatus

	lda #$FF	Setup Smartport dispatch address in BLKPTR
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	sta BLKPTR

	clc
	lda BLKPTR
	adc #3
	sta BLKPTR

	lda onlineUnit	Is this drive 1 or 2?
	bmi SPD2

SPD1
	lda #1
	sta SPUnitNo
	jmp CallSP

SPD2
	lda #2
	sta SPUnitNo

CallSP
	jsr Dispatch	This dispatch call is what crashes kegswin...

CmdNum     .db $00
CmdList    .da SPParms

	bcs SPError
	lda DSB+3
	beq DSBSizeOk

	lda #$FF
	sta DevSize
	sta DevSize+1
	jsr SAVSIZE
	jmp h.exit

DSBSizeOk
	lda DSB+1	Do we still have a zero byte device?
	ora DSB+2
	beq CheckType	Yes, check device type for Disk3.5

	lda DSB+1	Save size.
	sta DevSize
	lda DSB+2
	sta DevSize+1

	jsr SAVSIZE
	jmp h.exit

CheckType 

	lda DSB+21	If we have a 1 here then this is a
	cmp #1		Disk 3.5 (or Unidisk) so set default
	beq Disk35	value.

	lda #$00
	sta DevSize	Not a Disk35 so I don't know what type
	sta DevSize+1	of device we have so set size to zero.

	jsr SAVSIZE
	jmp h.exit

Disk35    

	lda #$40	Set Disk 3.5 default to 1600 ($0640)
	sta DevSize	blocks.
	lda #$06
	sta DevSize+1

	jsr SAVSIZE
	jmp h.exit


Dispatch
	jmp (BLKPTR)

SPError

	lda #$00
	sta DevSize
	sta DevSize+1

	tay
	lsr a
	lsr a
	lsr a
	lsr a
	tax
	jsr SAVSIZE
	jmp h.exit

h.exit	ldx <ZP		Restore X
	rts

SAVSIZE
	lda <ZP		Grab the original X
	beq s.next	Get ready to divide if not 0
	lsr		\
	lsr		 Divide by 8
	lsr		/
s.next	tax		X is now the index into blocks table
	lda DevSize
	sta capblks,x
	lda DevSize+1
	sta capblks+1,x
	rts

*---------------------------------------------------------
* HOWBIG2 - How big is this ProDOS volume?
*
* Input: 
*   A holds first byte of device list
*   X holds index into device list
* 
* Returns:
*   X unharmed
*   Updated capacity block table for index X/8
*
*---------------------------------------------------------
HOWBIG2
	clc
	adc #$01	Add one for the leading "/"
	and #$0f
	sta volname	Store total name length
	txa		Preserve X
	pha		by pushing it onto the stack
	lda #"/"
	sta volname+1
	ldy #$01
h2.loop	inx
	iny
	lda devices,x
	sta volname,y
	cpy volname
	bne h2.loop

h2.name	LDA #$0A	MLI call: FILE-INFO
	STA PARMBUF
	LDA #VOLNAME
	STA PARMBUF+1
	LDA /VOLNAME
	STA PARMBUF+2
	JSR MLI
	.db PD_INFO
	.da PARMBUF
	BNE h2.error
	pla		Grab the original X
	pha		back off the stack, put it in A
	beq h2.next	Get ready to divide if not 0
	lsr		\
	lsr		 Divide by 8
	lsr		/
h2.next	tax		X is now the index into blocks table
	lda parmbuf+5
*	lda #$01	UNIT TESTING - remove me
	sta capblks,x
	lda parmbuf+6
*	lda #$00	UNIT TESTING - remove me
	sta capblks+1,x
	sec
	jmp H2.EXIT

h2.ERROR		* Add an indication?
	sta parmbuf
	lda #$FF
	sta PARMBUF+1
	jmp H2.EXITNO

H2.EXITNO
	clc

H2.EXIT
	pla
	tax
	rts


*volname .db $00,'/LONGESTVOLUMENM                            '
*	.db '                               '
volname .db $00,'/LONGESTVOLUMENM '
* < = BC
* > = BE
MNODISK	.as -'<NO DISK>'
		.db $00
MIOERR	.as -'<I/O ERROR>'
		.db $00
MNONAME	.as -'<NO NAME>'
		.db $00

LASTVOL	.db $00
onlineUnit	.db $00
DevSize .dw $0000

SPParms
SPCount   .db $03
SPUnitNo  .db $00
SPListPtr .da DSB
SPCode    .db $03
DSB	.db $00,$00,$00,$00,$00,$00,$00,$00  Probably way too much space, but you never know...
	.db $00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00
	.db $00,$00,$00,$00,$00,$00,$00,$00
