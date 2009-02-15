;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2009 by David Schmidt
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
	ldx #$00
OCLEAN:
	sta CAPBLKS,X	; Clear out capacity-in-blocks table
	inx
	cpx #$20
	bne OCLEAN

	LDA #$02	; MLI call: ONLINE status
	STA PARMBUF
	LDA #$00
	STA PARMBUF+1
	LDA #<DEVICES
	STA PARMBUF+2
	LDA #>DEVICES
	STA PARMBUF+3
	CALLOS OS_ONL, PARMBUF
	BNE OERROR

	ldx #$00	; X is our index into the device table
	stx LASTVOL
OLLOOP:
	lda $C000
	cmp #CHR_ESC
	bne :+
	lda #$00
	sta LASTVOL	; Remember we aborted - so make sure to re-read next time
	jmp ABORT
:	lda DEVICES,x
	cmp #$00
	beq ODONE

	and #$0F	; Extract name length
	beq @SK1	; If zero - skip to HOWBIG
	jsr HOWBIG2
	bcs @SK3	; We found a size - skip to next step
@SK1:	lda DEVICES,x
	and #$F0	; Extract unit number in the high nybble
	jsr HOWBIG
@SK3:	lda DEVICES,x
	and #$0F	; Extract name length
	bne skip
@SK2:	lda DEVICES+1,x
	cmp #$52	; Not Pro-DOS
	bne @1
	jsr DEVMSG1
	jmp skip
@1:	cmp #$27	; I/O Error
	bne @2
	jsr DEVMSG2
	jmp skip
@2:	cmp #$28	; No device connected
	bne @3
	jsr DEVMSG3
	jmp skip
@3:	cmp #$2F	; Empty (typical of slot 5)
	bne skip
	jsr DEVMSG3

skip:
	jsr PRT1VOL
	inc LASTVOL
	txa
	clc
	adc #$10
	tax
	bcc OLLOOP
ODONE:
	rts

OERROR:
	sta PARMBUF
	LDA #$FF
	STA PARMBUF+1
	RTS

; DEVMSG - Add a message to the "Volume name" area of the device
DEVMSG:
	stx XSTASH	; Preserve X - the index into DEVICES structure
	lda MSGTBL,Y	; Y has an index into the messages table
	sta UTILPTR
	lda MSGTBL+1,Y
	sta UTILPTR+1
	tya
	clc
	ror		; Divide Y by 2 to get the message length out of the message length table
	tay
	lda MSGLENTBL,Y
	sta SLOWY	; Store the message length
	tay		; Y now holds the message length
	dey
	lda XSTASH	; Grab the index into the DEVICES structure
	sec
	adc #<DEVICES
	sta BLKPTR
	lda #>DEVICES
	sta BLKPTR+1	; BLKPTR now holds DEVICES + X
DMLOOP:
	lda (UTILPTR),Y
	sta (BLKPTR),Y	; Copy the message over
	dey
	cpy #$ff	; Copy the zeroeth byte, too
	bne DMLOOP
DMDONE:
	dec BLKPTR
	ldy #$00
	lda SLOWY	; Get our message length back
	ora (BLKPTR),Y
	sta (BLKPTR),Y	; Prepend the message length

	ldx XSTASH	; Get X back
	rts

XSTASH:	.byte $00

; DEVMSG1 - Add "<NO NAME>" to the "Volume name"
DEVMSG1:
	ldy #PMNONAME
	jsr DEVMSG
	rts

; DEVMSG2 - Add "<I/O ERROR>" to the "Volume name"
DEVMSG2:
	ldy #PMIOERR
	jsr DEVMSG
	rts

; DEVMSG3 - Add "<NO DISK>" to the "Volume name"
DEVMSG3:
	ldy #PMNODISK
	jsr DEVMSG
	rts

;---------------------------------------------------------
; INTERPRET_ONLINE
;
; Input: the row "enter" was hit in A
; Output: (side effects, sets): 
;   UNITNBR, pdsoftx, pdslot, pdrive, NonDiskII, NUMBLKS
;---------------------------------------------------------
INTERPRET_ONLINE:
	jsr WHATUNIT
	sta UNITNBR
	and #$70	; Mask off just slot
	lsr
	lsr
	lsr
	lsr
	sta pdslot	; Save default slot
	dec pdslot
	jsr slot2x
	sta pdsoftx	; Save slot * 16 for soft switches
	inc pdslot
	lda #$00
	sta pdrive	; Save default drive number
	lda UNITNBR
	and #$80	; Wait, was that drive 2?
	beq :+
	inc pdrive
:	lda VCURROW	; Extract unit capacity
	clc
	rol		; Multiply by 2
	tax		; X is now the index into blocks table
	lda #$00
	sta NonDiskII	; Assume _no_ Disk II selected
	lda CAPBLKS,X
	sta NUMBLKS
	lda CAPBLKS+1,X
	sta NUMBLKS+1
	cmp #$01	; Do we have a Disk II selected?
	bne :+
	lda NUMBLKS
	cmp #$18	; $180 blocks; assume so
	bne :+
	lda #$01
	sta NonDiskII	; $01 = We _have_ a Disk II
:
	rts

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
	jsr Mult16
	lda DEVICES,x
	and #$F0	; Extract unit number
	ldx SLOWX	; Restore X
	rts

;---------------------------------------------------------
; Mult16 - Multiply A by 16, return in X
;
; Input:
;   A - number to multiply by 16 (0x10)
;
; Returns:
;   X - A multipled by 16 (0x10
;---------------------------------------------------------
Mult16:
	beq @Done
	tax
	lda #$00
:	clc
	adc #$10
	dex
	cpx #$00
	bne :-
@Done:	tax
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

HOWBIG:
	stx SLOWX	; Preserve X

	and #$F0
	sta onlineUnit
	and #$70
	lsr
	lsr
	lsr
	lsr
	ora #$C0
	sta BLKPTR+1

	lda #$01	; 1st ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	cmp #$20
	beq Ok1
	jmp ProStatus

Ok1:
	lda #$03	; 2nd ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	beq Ok2
	jmp ProStatus

Ok2:
	lda #$05	; 3rd ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	cmp #$03
	beq BlockDev
	jmp ProStatus

; We have a block device of some sort here.

BlockDev:
	lda #$FF
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	bne NotDiskII

; It's a Disk ][ so hard code its size to 280 ($0118) blocks.

	lda #$01
	sta DevSize+1
	lda #$18
	sta DevSize
	jsr SAVSIZE
	jmp HOWEXIT

NotDiskII:

	lda #$07	; 4th ID byte
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	beq Smartport
	jmp ProStatus

Smartport:

; We have a Smartport device so get it's blocksize from $FC and $FD offset.
; If this value is zeros then we must do a Smartport status call to get size.

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
	jmp SMARTSTATUS

GoodSize:
	jsr SAVSIZE
	jmp HOWEXIT

; Do a ProDOS driver status call to retrieve device block size.

ProStatus:

	lda onlineUnit	; Compute slot/drive offset by dividing
	lsr a		; unit number by 16.
	lsr a
	lsr a
	tax		; Move offset to index.

	lda MLIADDR,x	; Get low byte of ProDOS driver address
	sta BLKPTR
	inx
	lda MLIADDR,x	; Get high byte of ProDOS driver address
	sta BLKPTR+1

	php		; Save status
	sei		; Interrupts off

	lda #0
	sta $42		; Status call

	lda onlineUnit
	sta $43		; Unit number
	lda #$00
	sta $44
	lda #$00
	sta $45

	lda #0
	sta $46
	sta $47

	lda $C08B	; Read and write enable the language card
	lda $C08B	; with bank 1 on.

	jsr CallDriver	; Call ProDOS driver.

	bit $C082	; Put ROM back on-line
	bcs Error

OKERROR:
	stx DevSize	; Save device size.
	sty DevSize+1

NoMessage:
	plp		; Restore status
	jsr SAVSIZE
	jmp HOWEXIT

CallDriver:
	jmp  (BLKPTR)

Error:
	cmp #$2B	; Write protect error is ok.
	beq OKERROR
	cmp #$2F	; Disk offline error
	beq OKERROR

	lda #$00
	sta DevSize	; Unknown size
	sta DevSize+1

	cmp #$28	; Device not connected error
	beq NoMessage	; (This error shouldn't happen here)

	plp		; Restore status

	jsr SAVSIZE
	jmp HOWEXIT

	rts

; Do a Smartport status call to retrieve device block size

SMARTSTATUS:
	lda #$FF	; Setup Smartport dispatch address in BLKPTR
	sta BLKPTR
	ldx #$00
	lda (BLKPTR,X)
	sta BLKPTR

	clc
	lda BLKPTR
	adc #3
	sta BLKPTR

	lda onlineUnit	; Is this drive 1 or 2?
	bmi SPD2

SPD1:
	lda #1
	sta SPUnitNo
	jmp CallSP

SPD2:
	lda #2
	sta SPUnitNo

CallSP:
	jsr Dispatch	; This dispatch call is what crashes kegswin...

CmdNum:		.byte $00
CmdList:	.addr SPParms
	bcs SPError
	lda DSB+3
	beq DSBSizeOk

	lda #$FF
	sta DevSize
	sta DevSize+1
	jsr SAVSIZE
	jmp HOWEXIT

DSBSizeOk:
	lda DSB+1	; Do we still have a zero byte device?
	ora DSB+2
	beq CheckType	; Yes, check device type for Disk3.5

	lda DSB+1	; Save size.
	sta DevSize
	lda DSB+2
	sta DevSize+1

	jsr SAVSIZE
	jmp HOWEXIT

CheckType:

	lda DSB+21	; If we have a 1 here then this is a
	cmp #1		; Disk 3.5 (or Unidisk) so set default
	beq Disk35	; value.

	lda #$00
	sta DevSize	; Not a Disk35 so I don't know what type
	sta DevSize+1	; of device we have so set size to zero.

	jsr SAVSIZE
	jmp HOWEXIT

Disk35:  

	lda #$40	; Set Disk 3.5 default to 1600 ($0640)
	sta DevSize	; blocks.
	lda #$06
	sta DevSize+1

	jsr SAVSIZE
	jmp HOWEXIT


Dispatch:
	jmp (BLKPTR)

SPError:

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
	jmp HOWEXIT

HOWEXIT:	ldx SLOWX	; Restore X
	rts

SAVSIZE:
	lda SLOWX	; Grab the original X
	beq @SNEXT	; Get ready to divide if not 0
	lsr		; \
	lsr		;  Divide by 8
	lsr		; /
@SNEXT:	tax		; X is now the index into blocks table
	lda DevSize
	sta CAPBLKS,x
	lda DevSize+1
	sta CAPBLKS+1,x
	rts

;---------------------------------------------------------
; HOWBIG2 - How big is this ProDOS volume?
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
HOWBIG2:
	and #$0f	; Lop off the high nybble
	clc
	adc #$01	; Add one for the leading "/"
	sta VOLNAME	; Store total name length
	txa			; Preserve X
	pha			; by pushing it onto the stack
	lda #'/'
	sta VOLNAME+1
	ldy #$01
@H2LOOP:
	inx
	iny
	lda DEVICES,x
	sta VOLNAME,y
	cpy VOLNAME
	bne @H2LOOP

@H2NAME:
	LDA #$0A	; MLI call: FILE-INFO
	STA PARMBUF
	LDA #<VOLNAME
	STA PARMBUF+1
	LDA #>VOLNAME
	STA PARMBUF+2
	CALLOS OS_GET_FILE_INFO, PARMBUF
	BNE @H2ERROR
	pla		; Grab the original X
	pha		; back off the stack, put it in A
	beq @next	; Get ready to divide if not 0
	lsr		; \
	lsr		;  Divide by 8
	lsr		; /
@next:	tax		; X is now the index into blocks table
	lda PARMBUF+5
	sta CAPBLKS,x
	lda PARMBUF+6
	sta CAPBLKS+1,x
	sec
	jmp @H2EXIT

@H2ERROR:		; Add an indication?
	sta PARMBUF
	lda #$FF
	sta PARMBUF+1
	jmp @H2EXITNO

@H2EXITNO:
	clc

@H2EXIT:
	pla
	tax
	rts

;---------------------------------------------------------
; DRAWBDR
; 
; Draws the volume picker decorative border
; Y holds the top line message number
;---------------------------------------------------------
DRAWBDR:
	lda #$07
	sta CH
	lda #$00
	jsr TABV
	jsr WRITEMSG	; Y holds the top line message number

	lda #$07	; Column
	sta CH
	lda #$02	; Row
	jsr TABV
	ldy #PMSG19	; 'VOLUMES CURRENTLY ON-LINE:'
	jsr WRITEMSG

	lda #H_SL	; "Slot" starting column
	sta CH
	lda #$03	; Row
	jsr TABV
	ldy #PMSG20	; 'SLOT  DRIVE  VOLUME NAME      BLOCKS'
	jsr WRITEMSG

	lda #H_SL	; "Slot" starting column
	sta CH
	lda #$04	; Row
	jsr TABV
	ldy #PMSG21	; '----  -----  ---------------  ------'
	jsr WRITEMSG
VOLINSTRUCT:
	lda #$14	; Row
	jsr TABV
	ldy #PMSG22	; 'CHANGE VOLUME/SLOT/DRIVE WITH ARROW KEYS'
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
;   X register holds the index to the device table
;   Y register is preserved
; Prints one volume's worth of information
; Called from ONLINE
;---------------------------------------------------------
PRT1VOL:
	tya
	pha
	stx SLOWX

	lda #H_SL	; "Slot" starting column
	sta CH

	lda DEVICES,X
	and #$70	; Mask off length nybble
	lsr
	lsr
	lsr
	lsr		; Acc now holds the slot number
	clc
	adc #$B0
	sta PRTSVA
	jsr COUT1

	lda #H_DR	; "Drive" starting column
	sta CH
	lda DEVICES,X
	and #$80
	cmp #$80
	beq PRDR2
	lda #$B1
	jmp PROUT
PRDR2:	lda #$B2
PROUT:	jsr COUT1

	lda #H_VO	; "Volume" starting column
	sta CH
	lda DEVICES,X
	and #$0f
	sta PRTSVA
	beq PRVODONE
	ldy #$00
PRLOOP:
	lda DEVICES+1,X
	ora #$80
	jsr COUT1
	inx
	iny
	cpy PRTSVA
	bne PRLOOP

	lda #H_SZ	; "Size" starting column
	sta CH

	lda SLOWX	; Get a copy of original X into Acc

	beq PRnum
	lsr
	lsr
	lsr
PRnum:	tax
	lda CAPBLKS+1,X
	sta FILL
	lda CAPBLKS,X
	ldx FILL
	ldy #CHR_SP
	jsr PRD

PRVODONE:
	jsr CROUT

	ldx SLOWX
	pla
	tay
	rts

PRTSVA:	.byte $00

;---------------------------------------------------------
; Local variables
;---------------------------------------------------------
VOLNAME:	.res 17,$00		; One byte for length
					; One byte for leading slash
					; 15 bytes for name

LASTVOL:	.byte $00		; The number of volumes currently in the table
onlineUnit:	.byte $00
DevSize:	.word $0000

SPParms:
SPCount:	.byte $03
SPUnitNo:	.byte $00
SPListPtr:	.addr DSB
SPCode:		.byte $03
DSB:		.res $28,$00		; Probably way too much space, but you never know...
