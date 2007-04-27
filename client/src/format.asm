;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 by David Schmidt
; david__schmidt at users.sourceforge.net
;
; This program is free software; you can redistribute it and/or modify it 
; under the terms of the GNU General Public License as published by the 
; Free Software Foundation; either version 2 of the License,$ or (at your 
; option) any later version.
;
; This program is distributed in the hope that it will be useful,$ but 
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
; for more details.
;
; You should have received a copy of the GNU General Public License along 
; with this program; if not,$ write to the Free Software Foundation,$ Inc.,$ 
; 59 Temple Place,$ Suite 330,$ Boston,$ MA 02111-1307 USA
;

.include "applechr.i"

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
;* credit for developing them.     *  Please don't use this for any  *
;*                                 * SmartPort volumes bigger than   *
;*       Updated on: 23Aug85       * 2.1 Meg. Look under Hyper-FORMAT*
;*                                 * in you local BB Library for the *
;*********************************** original code for Hyper-FORMAT  *
;                                 *                                 *
;        Keep   HypeForm          *      Updated on: 22Dec89        *
;        65816 off                *                                 *
;        65C02 off                ***********************************

Home     =  $FC58                    ;Monitor clear screen and home cursor
DevCnt   =  $BF31                    ;Prodos device count
DevList  =  $BF32                    ;List of devices for ProDOS
DevAdr   =  $BF10                    ;Given slot this is the address of driver
Buffer   =  $0                       ;Address pointer for FORMAT data
CH       =  $24                      ;Storage for Horizontal Cursor value
IN       =  $200                     ;Keyboard input buffer
WARMDOS  =  $BE00                    ;BASIC Warm-start vector
MLI      =  $BF00                    ;ProDOS Machine Language Interface
LAST     =  $BF30                    ;Last device accessed by ProDOS
STROUT   =  $DB3A                    ;Applesoft's string printer
WAIT     =  $FCA8                    ;Delay routine
CLRLN    =  $FC9C                    ;Clear Line routine
RDKEY    =  $FD0C                    ;Character input routine  (read keyboard)
PRBYTE   =  $FDDA                    ;Print Byte routine (HEX value)
COUT     =  $FDED                    ;Character output routine (print to screen)
Step0    =  $C080                    ;Drive stepper motor positions
Step1    =  $C081                    ;  |      |      |       |
Step2    =  $C082                    ;  |      |      |       |
Step4    =  $C084                    ;  |      |      |       |
Step6    =  $C086                    ;  |      |      |       |
DiskOFF  =  $C088                    ;Drive OFF  softswitch
DiskON   =  $C089                    ;Drive ON   softswitch
Select   =  $C08A                    ;Starting offset for target device
DiskRD   =  $C08C                    ;Disk READ  softswitch
DiskWR   =  $C08D                    ;Disk WRITE softswitch
ModeRD   =  $C08E                    ;Mode READ  softswitch
ModeWR   =  $C08F                    ;Mode WRITE softswitch
;**********************************************************
; Equates
;**********************************************************
         .Org   $5000
HypForm:
         tsx
         stx   Stack
         LDA   LAST                     ;Store current slot/drive # in Slot
         STA   QSlot                    ;Save Prodos's last device accessed
         JSR   Home                     ;Clears screen
         jsr   MLI
         .byte $42
         .addr NetParms                 ;Call for Appletalk which isn't wanted
         bcc   NotError
         cmp   #$01                     ;Even though everyone said that this
         beq   Reentry                  ; should happen I never could get it.
         cmp   #$04                     ;Got this but don't try to change the
         beq   Reentry                  ; parameter count to 1 or #$%@&*^()
NotError:
         lda   NetDev
         jsr   HexDec
         LDA   #<Appletalk               ;Prompt to continue or not
         LDY   #>Appletalk               ;because Appletalk is installed
         JSR   STROUT
         jsr   GetYN
         beq   Reentry
         jmp   MExit
Reentry:
         JSR   Home                     ;Clears screen
         LDA   #<TargSlt                ;Prompt for slot
         LDY   #>TargSlt
         JSR   STROUT
LSlot:
         JSR   RDKEY                    ;Get a keypress
         CMP   #$B0                     ;Less than slot #1?
         BCC   LSlot
         CMP   #$B8                     ;Greater than slot #7?
         BCS   LSlot
         STA   Buffer                   ;Store SLOT number in Buffer
         JSR   COUT                     ;Print it on the screen
         LDA   #<TargDrv                 ;Prompt for drive
         LDY   #>TargDrv
         JSR   STROUT
LDrive:
         JSR   RDKEY                    ;Get a keypress
         CMP   #$B1                     ;Drive #1?
         BEQ   LConvert
         CMP   #$B2                     ;Drive #2?
         BNE   LDrive
LConvert:
         STA   Buffer+1                 ;Store DRIVE number in Buffer+1
         JSR   COUT                     ;Print it on the screen
         JSR   DOTWO                    ;Print two carriage returns
         LDA   Buffer                   ;Fetch the SLOT number
         AND   #$0F                     ;Mask off the upper 4 bits
         rol   a                        ;Move lower 4 bits to upper 4 bits
         rol   a
         rol   a
         rol   a
         STA   Slot                     ;Store result in FORMAT slot
         tax
         LDA   Buffer+1                 ;Fetch the DRIVE number
         CMP   #$B1                     ;Does Slot need conditioning?
         Beq   Jump5                    ;Nope
Jump1:
         LDA   Slot                     ;Fetch FORMAT slot
         ORA   #$80                     ;Set MSB to indicate drive #2
         sta   Slot
         tax
Jump5:
         ldy   DevCnt                   ;Load how many devices
FLoop:
         lda   DevList,y                ; since this isn't a sequential
         sta   ListSlot                 ; list then must go through each one
         and   #$F0                     ; must also store what is there for later
         cmp   Slot
         beq   ItIsNum
         dey
         bpl   FLoop
         jmp   NoUnit                   ;Used to be bmi
ItIsNum:
         txa                            ;Make the slot the indexed register
         lsr   a                        ; for getting device drive controller
         lsr   a
         lsr   a
         tay
         lda   DevAdr,y                 ;Get it
         sta   Addr                     ; and save it
         lda   DevAdr+1,y
         sta   Addr+1
         tay
         and   #$F0                     ;Next see if it begins with a C0
         cmp   #$C0
         beq   YesSmart                 ; and if it does is a very smart device
         txa
         cmp   #$B0                     ;If it isn't smart test for /Ram
         beq   YesRam3
         clc
         ror   a
         ror   a
         ror   a
         ror   a
         and   #$07
         ora   #$C0
         sta   Addr+1                   ;if it isn't either then treat it as
         jmp   YesSmart1                ; smart and save what bank it is in.

YesRam3:
         lda   Addr+1                   ;If you think it is a /Ram then check
         cmp   #$FF                     ; the bits that tell you so.
         beq   Loop7                    ; Does the Address pointer start with FF
         jmp   NoUnit
Loop7:
         lda   Addr                     ; And end with 00
         cmp   #$00
         beq   Loop8
         jmp   NoUnit
Loop8:
         lda   ListSlot
         and   #$F3
         cmp   #$B3
         beq   Loop9
         jmp   NoUnit
Loop9:
         LDA   #<ItIsRam3                ;Tell the preson that you think it is a
         LDY   #>ItIsRam3               ; /Ram and if they want to continue
         JSR   STROUT
         jsr   GetYN
         Bne   Jump2
         jsr   OldName
         jsr   Ram3Form
Jump2:
         jmp   Again
YesSmart:
         tya
         and   #$0F
         rol   a                        ;Move lower 4 bits to upper 4 bits
         rol   a
         rol   a
         rol   a
         STA   Slot                     ;Store result in FORMAT slot
YesSmart1:
         lda   Addr+1                   ;Check signiture bytes in the Cn page
         sta   Buffer+1                 ; for a smart device.
         lda   #$00
         sta   Buffer
         ldy   #$01
         lda   (Buffer),y
         cmp   #$20
         bne   NoUnit
         ldy   #$03
         lda   (Buffer),y
         bne   NoUnit
         ldy   #$05
         lda   (Buffer),y
         cmp   #$03
         bne   NoUnit
         ldy   #$FF
         lda   (Buffer),y
         cmp   #$00                     ;Apples DiskII
         beq   DiskII
         cmp   #$FF                     ;Wrong DiskII
         beq   NoUnit                   ; must be a smart device.
         ldy   #$07                     ;Test last signiture byte for the
         lda   (Buffer),y               ; Protocol Converter.
         cmp   #$00
         bne   NoUnit                   ;It isn't so its no device I know.
         LDA   #<ItIsSmart               ;Tell them you think it is a SmartPort
         LDY   #>ItIsSmart              ; device. and ask if they want to Format.
         JSR   STROUT
         jsr   GetYN
         Bne   Jump3
         jsr   OldName                  ;Show old name and ask if proper Disk
         jsr   LName                    ;Get New name
         jsr   SmartForm                ;Jump too routine to format Smart Drive
         lda   ListSlot
         and   #$F0
         sta   Slot
         jsr   CodeWr                   ;Jump to routine to produce Bit map
         JMP   Catalog                  ;Write Directory information to the disk
Jump3:   jmp   Again


NoUnit:  LDA   #<UnitNone                ;Prompt to continue or not Because
         LDY   #>UnitNone               ;There is no unit number like that
         JSR   STROUT
         jsr   GetYN
         Bne   Jump4
         jmp   Reentry
Jump4:   jmp   MExit

DiskII:
         LDA   #<ItsaII                  ;Tell them you think it is a DiskII
         LDY   #>ItsaII
         JSR   STROUT
         jsr   GetYN
         Bne   Jump3
         LDA   #$18                     ;Set VolBlks to 280 ($118)
         LDX   #$01                     ; Just setting default settings
         ldy   #$00
         STA   VolBlks
         STX   VolBlks+1
         STY   VolBlks+2
         jsr   OldName                  ;Prompt for proper disk.
         jsr   LName                    ;Get new name
         jmp   DIIForm                  ;Format DiskII

LName:   LDA   #<VolName
         LDY   #>VolName
         JSR   STROUT
LRdname: LDA   #$0E                     ;Reset CH to 14
         STA   CH
         LDX   #$00
         BEQ   LInput                   ;Always taken
LBackup: CPX   #0                       ;Handle backspaces
         BEQ   LRdname
         DEX
         LDA   #$88                     ;<--
         JSR   COUT
LInput:  JSR   RDKEY                    ;Get a keypress
         CMP   #$88                     ;Backspace?
         BEQ   LBackup
         CMP   #$FF                     ;Delete?
         BEQ   LBackup
         CMP   #$8D                     ;C/R is end of input
         BEQ   LFormat
         CMP   #$AE                     ;(periods are ok...)
         BEQ   LStore
         CMP   #$B0                     ;Less than '0'?
         BCC   LInput
         CMP   #$BA                     ;Less than ':'?
         BCC   LStore                   ;Valid. Store the keypress
         AND   #$DF                     ;Force any lower case to upper case
         CMP   #$C0                     ;Less than 'A'?
         BEQ   LInput
         CMP   #$DB                     ;Greater than 'Z'?
         BCS   LInput
LStore:  JSR   COUT                     ;Print keypress on the screen
         AND   #$7F                     ;Clear MSB
         STA   VOLnam,x                 ;Store character in VOLnam
         INX
         CPX   #$0E                     ;Have 15 characters been entered?
         BCC   LInput
LFormat: TXA                            ;See if default VOLUME_NAME was taken
         BNE   LSetLEN
WLoop:   LDA   Blank,x                  ;Transfer 'BLANK' to VOLnam
         AND   #$7F                     ;Clear MSB
         STA   VOLnam,x
         INX
         CPX   #$05                     ;End of transfer?
         BCC   WLoop
         LDA   #$13                     ;Reset CH to 19
         STA   CH
LSetLEN: JSR   CLRLN                    ;Erase the rest of the line
         CLC
         TXA                            ;Add $F0 to Volume Name length
         ADC   #$F0                     ;Create STORAGE_TYPE,$ NAME_LENGTH byte
         STA   VolLen
         rts

DIIForm: JSR   Format                   ;Format the disk
         jsr   CodeWr                   ;Form Bitmap
         LDA   #<Verif                   ;Ask if you want to Verify the Disk
         LDY   #>Verif
         JSR   STROUT
         JSR   GetYN                    ;Get a Yes or No answer to 'Verify?'
         Bne   BIIForm1
         jmp   Verify                   ;Answer was yes...
BIIForm1:
         JMP   Catalog                  ;Write Directory information to the disk

CodeWr:  LDA   #$81                     ;Set Opcode to WRITE
         STA   Opcode
;**********************************
;*                                *
;* Write Block0 to disk           *
;*                                *
;**********************************
AskBlk0: LDA   #<BootCode                ;Set MLIbuf to BootCode
         LDY   #>BootCode
         STA   MLIbuf
         STY   MLIbuf+1
         LDA   #$00                     ;Set MLIBlk to 0
         STA   MLIBlk
         STA   MLIBlk+1
         JSR   CallMLI                  ;Write block #0 to target disk
;**************************************
;*                                    *
;* Fill buffer $6800-$69FF with zeros *
;* and prepare BitMap and Link blocks *
;* for writing to disk                *
;*                                    *
;**************************************
Fill:
         lda   #$05                     ;Block 5 on Disk
         sta   MLIBlk
         LDA   #$00                     ;Set Buffer,$ MLIbuf to $6800
         LDX   #$68
         STA   MLIbuf
         STA   Buffer
         STX   MLIbuf+1
         STX   Buffer+1
         TAY                            ;Fill $6800-$69FF with zeros
         LDX   #$01                     ;Fill 2 pages of 256 bytes
LZero:   STA   (Buffer),y
         INY
         BNE   LZero
         INC   Buffer+1
         DEX
         BPL   LZero
         LDA   #$68                     ;Reset Buffer to $6800
         STA   Buffer+1
         LDA   #$05                     ;Length of DirTbl
         STA   Count
LLink:   LDX   Count
         LDA   DirTbl,x                 ;Move Directory Link values into Buffer
         STA   $6802                    ;Store next Directory block #
         DEX
         LDA   DirTbl,x                 ;Fetch another # from DirTbl
         STA   $6800                    ;Store previous Directory block #
         DEX
         STX   Count
         JSR   CallMLI                  ;Write Directory Link values to disk
LDec:    DEC   MLIBlk                   ;Decrement MLI block number
         LDA   MLIBlk                   ;See if MLIBlk = 2
         CMP   #$02
         BNE   LLink                    ;Process another Link block
;**********************************
;*                                *
;* Calculate BitMap Size and cndo *
;*                                *
;**********************************
BlkCount:
         lda   VolBlks+1                ;Where # of blocks are stored
         ldx   VolBlks
         ldy   VolBlks+2                ;Can't deal with block devices this big
         bne   Jump10
         stx   Count+1                  ;Devide the # of blocks by 8 for bitmap
         lsr   a                        ; calculation
         ror   Count+1
         lsr   a
         ror   Count+1
         lsr   a
         ror   Count+1
         sta   Count+2
         jmp   BitMapCode
Jump10:  pla                            ;Remove the address that the routine
         pla                            ; would have returned to
         lda   #$4D                     ;Make error Block size to large
         jmp   Died
BitMapCode:
         lda   #%00000001               ;Clear first 7 blocks
         sta   (Buffer),y
         ldy   Count+1                  ;Original low block count value
         bne   Jump11                   ;if it is 0 then make FF
         dey                            ;Make FF
         dec   Count+2                  ;Make 256 blocks less one
         sty   Count+1                  ;Make FF new low block value
Jump11:
         ldx   Count+2                  ;High Block Value
         bne   Jump15                   ;If it isn't equal to 0 then branch
         ldy   Count+1
         jmp   Jump19

Jump15:
         lda   #$69                     ;Set the adress of the upper part of
         sta   Buffer+1                 ; Block in bitmap being created
         lda   #%11111111
         ldy   Count+1                  ;Using the low byte count
Jump20:
         dey
         sta   (Buffer),y               ;Store them
         beq   Jump17
         jmp   Jump20
Jump17:
         dey                            ;Fill in first part of block
         lda   #$68
         sta   Buffer+1
Jump19:  lda   #%11111111
         dey
         sta   (Buffer),y
         cpy   #$01                     ;Except the first byte.
         beq   Jump18
         jmp   Jump19
Jump18:  rts


;*************************************
;*                                   *
;* VERIFY - Verify each block on the *
;* disk,$ and flag bad ones in BITMAP *
;*                                   *
;*************************************
Verify:
         LDA   #$80                     ;Set Opcode to $80 (READ)
         STA   Opcode
         LDA   #$60                     ;Change Error to an RTS instruction
         STA   Error
         LDA   #$00                     ;Reset MLIbuf to $1000
         LDX   #$10
         STA   MLIbuf
         STX   MLIbuf+1
         STA   Count                    ;Set Count and Pointer to 0
         STA   Pointer
         STA   LBad                     ;Set bad block counter to 0
         STA   MLIBlk                   ;Reset MLIBlk to 0
         STA   MLIBlk+1
LRead:   JSR   CallMLI                  ;Read a block
         BCS   LError                   ;Update BitMap if error occurs
LIncBlk: CLC                            ;Add 1 to MLIBlk
         INC   MLIBlk
         BNE   LCheck
         INC   MLIBlk+1
LCheck:  INC   Count                    ;Add 1 to BitMap counter
         LDA   Count                    ;If Count > 7 then add 1 to Pointer
         CMP   #$08
         BCC   MDone
         LDA   #$00                     ;Reset Count to 0
         STA   Count
         INC   Pointer                  ;Add 1 to Pointer offset value
MDone:   LDX   MLIBlk                   ;See if we've read 280 blocks yet
         LDA   MLIBlk+1
         BEQ   LRead
         CPX   #$18                     ;Greater than $118 (280) blocks read?
         BEQ   LResult                  ;Finished. Display results of VERIFY
         BNE   LRead                    ;Go get another block
LError:  LDX   Count                    ;Use Count as offset into MapTbl
         LDA   BitTbl,x                 ;Fetch value for bad block number
         LDY   Pointer                  ;Use Pointer as offset into Buffer
         AND   (Buffer),y               ;Mask value against BitMap value
         STA   (Buffer),y               ;Store new BitMap value in Buffer
         CLC
         DEC   VolBlks                  ;Decrement # of blocks available
         BNE   LIncBad
         DEC   VolBlks+1
LIncBad: INC   LBad                     ;Add 1 to # of bad blocks found
         JMP   LIncBlk                  ;Get the next block on the disk
LResult: LDA   #$EA                     ;Change Error back to a : instruction
         STA   Error
         LDA   LBad                     ;Find out if there were any bad blocks
         BEQ   LGood
         JSR   HexDec                   ;Convert hex number into decimal
         LDX   #$00
BLoop:   LDA   IN,x                     ;Print the decimal gequivalent of LBad
         CMP   #$31                     ;Don't print zeros...
         BCC   MNext
         JSR   COUT
MNext:   INX
         CPX   #$03                     ;End of number?
         BCC   BLoop
         LDA   #<Bad
         LDY   #>Bad
         JSR   STROUT
         JMP   Catalog                  ;Write BitMap and Links to the disk
LGood:   LDA   #<Good
         LDY   #>Good
         JSR   STROUT
         JMP   Catalog
LBad:    .res 1                         ;Number of bad blocks found

;*************************************
;*                                   *
;* Catalog - Build a Directory Track *
;*                                   *
;*************************************
Catalog:

         LDA   #$81                     ;Change Opcode to $81 (WRITE)
         STA   Opcode
         LDA   #$00                     ;Reset MLIbuf to $6800
         LDX   #$68
         STA   MLIbuf
         STX   MLIbuf+1
         LDX   #$06                     ;Write Buffer (BitMap) to block #6 on the disk
         STX   MLIBlk
         STA   MLIBlk+1
         JSR   Call2MLI                  ; Call for time and date
         jsr   MLI
         .byte $82
         .addr 0000
         lda   $BF90                    ; Get them and save them into the
         sta   Datime                   ; Directory to be written.
         lda   $BF91
         sta   Datime+1
         lda   $BF92
         sta   Datime+2
         lda   $BF93
         sta   Datime+3
         LDY   #$2A                     ;Move Block2 information to $6800
CLoop:   LDA   Block2,y
         STA   (Buffer),y
         DEY
         BPL   CLoop
         LDA   #$02                     ;Write block #2 to the disk
         STA   MLIBlk
         JSR   Call2MLI
Again:
         LDA   #<Nuther                  ;Display 'Format another' string
         LDY   #>Nuther
         JSR   STROUT
         JSR   GetYN                    ;Get a Yes or No answer
         BNE   MExit                    ;Answer was No...
         JMP   Reentry                  ;Format another disk
MExit:   JSR   DOTWO                    ;Two final carriage returns...
         lda   QSlot
         sta   LAST
         ldx   Stack                    ;Just because I am human to and might
         txs                            ;have messed up also.
         JMP   WARMDOS                  ;Exit to BASIC
Call2MLI:
         jsr   CallMLI
         rts
;***************************
;*                         *
;* GetYN - Get a Yes or No *
;* answer from the user    *
;*                         *
;***************************
GetYN:

         JSR   RDKEY                    ;Get a keypress
         AND   #$DF                     ;Mask lowercase
         CMP   #$D9                     ;is it a Y?
         BEQ   LShow
         LDA   #$BE                     ;Otherwise default to "No"
LShow:   JSR   COUT                     ;Print char,$ Z flag contains status
         CMP   #$D9                     ;Condition flag
         RTS
;*************************************
;*                                   *
;* CallMLI - Call the MLI Read/Write *
;* routines to transfer blocks to or *
;* from memory                       *
;*                                   *
;*************************************
CallMLI:

         JSR   MLI                      ;Call the ProDOS Machine Langauge Interface
Opcode:  .byte $81                      ;Default MLI opcode = $81 (WRITE)
         .addr Parms
         BCS   Error
         RTS
Error:                                  ;(this will be changed to RTS by VERIFY)
         pla
         pla
         pla
         pla
         JMP   Died
;**************************************
;*                                    *
;* DOTWO - Print two carriage returns *
;*                                    *
;**************************************

DOTWO:
         LDA   #$8D                     ;(we don't need an explanation,$ do we?)
         JSR   COUT
         JSR   COUT
         RTS
;***********************************
;*                                 *
;* HexDec - Convert HEX to decimal *
;*                                 *
;***********************************

HexDec:
         STA   IN+20                    ;Store number in Keyboard Input Buffer
         LDA   #$00
         STA   IN+21
         LDY   #$02                     ;Result will be three digits long
DLoop:   LDX   #$11                     ;16 bits to process
         LDA   #$00
         CLC
LDivide: ROL   a
         CMP   #$0A                     ;Value > or = to 10?
         BCC   LPlus
         SBC   #$0A                     ;Subtract 10 from the value
LPlus:   ROL   IN+20                    ;Shift values in IN+20,$ IN+21 one bit left
         ROL   IN+21
         DEX
         BNE   LDivide
         ORA   #$B0                     ;Convert value to high ASCII character
         STA   IN,y                     ;Store it in the input buffer
         sta   NetNum,y
         DEY
         BPL DLoop
         RTS
;***********************************
;*                                 *
;* FORMAT - Format the target disk *
;*                                 *
;***********************************

Format:
         php
         sei
         LDA   Slot                     ;Fetch target drive SLOTNUM value
         PHA                            ;Store it on the stack
         AND   #$70                     ;Mask off bit 7 and the lower 4 bits
         STA   SlotF                    ;Store result in FORMAT slot storage
         TAX                            ;Assume value of $60 (drive #1)
         PLA                            ;Retrieve value from the stack
         BPL   LDrive1                  ;If < $80 the disk is in drive #1
         INX                            ;Set X offset to $61 (drive #2)
LDrive1: LDA   Select,x                 ;Set softswitch for proper drive
         LDX   SlotF                    ;Set X offset to FORMAT slot/drive
         LDA   DiskON,x                 ;Turn the drive on
         LDA   ModeRD,x                 ;Set Mode softswitch to READ
         LDA   DiskRD,x                 ;Read a byte
         LDA   #$23                     ;Assume head is on track 35
         STA   TRKcur
         LDA   #$00                     ;Destination is track 0
         STA   TRKdes
         JSR   Seek                     ;Move head to track 0
         LDX   SlotF                    ;Turn off all drive phases
         LDA   Step0,x
         LDA   Step2,x
         LDA   Step4,x
         LDA   Step6,x
         LDA   TRKbeg                   ;Move TRKbeg value (0) to Track
         STA   Track
         JSR   Build                    ;Build a track in memory at $6700

;*******************************
;*                             *
;* WRITE - Write track to disk *
;*                             *
;*******************************
Write:
         JSR   Calc                     ;Calculate new track/sector/checksum values
         JSR   Trans                    ;Transfer track in memory to disk
         BCS   DiedII                   ;If carry set,$ something died
MInc:    INC   Track                    ;Add 1 to Track value
         LDA   Track                    ;Is Track > ending track # (TRKend)?
         CMP   TRKend
         BEQ   LNext                    ;More tracks to FORMAT
         BCS   Done                     ;Finished.  Exit FORMAT routine
LNext:   STA   TRKdes                   ;Move next track to FORMAT to TRKdes
         JSR   Seek                     ;Move head to that track
         JMP   Write                    ;Write another track
Done:    LDX   SlotF                    ;Turn the drive off
         LDA   DiskOFF,x
         plp
         RTS                            ;FORMAT is finished. Return to calling routine
DiedII:  PHA                            ;Save MLI error code on the stack
         JSR   Done
         PLA                            ;Retrieve error code from the stack
         JMP   Died                     ;Prompt for another FORMAT...

;**************************************
;*                                    *
;* Died - Something awful happened to *
;* the disk or drive. Die a miserable *
;* death...                           *
;*                                    *
;**************************************
Died:
         cmp   #$4D                     ;Save MLI error code on the stack
         beq   RangeError
         cmp   #$27
         beq   DriveOpen
         cmp   #$2F
         beq   DiskError
         cmp   #$2B
         beq   Protected
         jmp   NoDied
RangeError:
         LDA   #<TooLarge
         LDY   #>TooLarge
         jmp   DiedOut
DiskError:
         LDA   #<NoDisk
         LDY   #>NoDisk
         jmp   DiedOut
DriveOpen:
         LDA   #<Dead
         LDY   #>Dead
         jmp   DiedOut
Protected:
         LDA   #<Protect
         LDY   #>Protect
         jmp   DiedOut
NoDied:  PHA                            ;Save MLI error code on the stack
         LDA   #<UnRecog
         LDY   #>UnRecog
         JSR   STROUT
         PLA                            ;Retrieve error code from the stack
         JSR   PRBYTE                   ;Print the MLI error code
         jmp   Again
DiedOut: JSR   STROUT
         JMP   Again                    ;Prompt for another FORMAT...

;************************************
;*                                  *
;* TRANS - Transfer track in memory *
;* to target device                 *
;*                                  *
;************************************

Trans:
         LDA   #$00                     ;Set Buffer to $6700
         LDX   #$67
         STA   Buffer
         STX   Buffer+1
         LDY   #$32                     ;Set Y offset to 1st sync byte (max=50)
         LDX   SlotF                    ;Set X offset to FORMAT slot/drive
         SEC                            ;(assum the disk is write protected)
         LDA   DiskWR,x                 ;Write something to the disk
         LDA   ModeRD,x                 ;Reset Mode softswitch to READ
         BMI   LWRprot                  ;If > $7F then disk was write protected
         LDA   #$FF                     ;Write a sync byte to the disk
         STA   ModeWR,x
         CMP   DiskRD,x
         NOP                            ;(kill some time for WRITE sync...)
         JMP   LSync2
LSync1:  EOR   #$80                     ;Set MSB,$ converting $7F to $FF (sync byte)
         NOP                            ;(kill time...)
         NOP
         JMP   MStore
LSync2:  PHA                            ;(kill more time... [ sheesh! ])
         PLA
LSync3:  LDA   (Buffer),y               ;Fetch byte to WRITE to disk
         CMP   #$80                     ;Is it a sync byte? ($7F)
         BCC   LSync1                   ;Yep. Turn it into an $FF
         NOP
MStore:  STA   DiskWR,x                 ;Write byte to the disk
         CMP   DiskRD,x                 ;Set Read softswitch
         INY                            ;Increment Y offset
         BNE   LSync2
         INC   Buffer+1                 ;Increment Buffer by 255
         BPL   LSync3                   ;If < $8000 get more FORMAT data
         LDA   ModeRD,x                 ;Restore Mode softswitch to READ
         LDA   DiskRD,x                 ;Restore Read softswitch to READ
         CLC
         RTS
LWRprot: CLC                            ;Disk is write protected! (Nerd!)
         JSR   Done                     ;Turn the drive off
         lda   #$2B
         pla
         pla
         pla
         pla
         JMP   Died                     ;Prompt for another FORMAT...
;************************************
;*                                  *
;* BUILD - Build GAP1 and 16 sector *
;* images between $6700 and $8000   *
;*                                  *
;************************************
Build:

         LDA   #$10                     ;Set Buffer to $6710
         LDX   #$67
         STA   Buffer
         STX   Buffer+1
         LDY   #$00                     ;(Y offset always zero)
         LDX   #$F0                     ;Build GAP1 using $7F (sync byte)
         LDA   #$7F
         STA   LByte
         JSR   LFill                    ;Store sync bytes from $6710 to $6800
         LDA   #$10                     ;Set Count for 16 loops
         STA   Count
LImage:  LDX   #$00                     ;Build a sector image in the Buffer area
ELoop:   LDA   LAddr,x                  ;Store Address header,$ info & sync bytes
         BEQ   LInfo
         STA   (Buffer),y
         JSR   LInc                     ;Add 1 to Buffer offset address
         INX
         BNE   ELoop
LInfo:   LDX   #$AB                     ;Move 343 bytes into data area
         LDA   #$96                     ;(4&4 encoded version of hex $00)
         STA   LByte
         JSR   LFill
         LDX   #$AC
         JSR   LFill
         LDX   #$00
YLoop:   LDA   LData,x                  ;Store Data Trailer and GAP3 sync bytes
         BEQ   LDecCnt
         STA   (Buffer),y
         JSR   LInc
         INX
         BNE   YLoop
LDecCnt: CLC
         DEC   Count
         BNE   LImage
         RTS                            ;Return to write track to disk (WRITE)
LFill:   LDA   LByte
         STA   (Buffer),y               ;Move A register to Buffer area
         JSR   LInc                     ;Add 1 to Buffer offset address
         DEX
         BNE   LFill
         RTS
LInc:    CLC
         INC   Buffer                   ;Add 1 to Buffer address vector
         BNE   LDone
         INC   Buffer+1
LDone:   RTS
;***********************************
;*                                 *
;* CALC - Calculate Track,$ Sector,$ *
;* and Checksum values of the next *
;* track using 4&4 encoding        *
;*                                 *
;***********************************
Calc:

         LDA   #$03                     ;Set Buffer to $6803
         LDX   #$68
         STA   Buffer
         STX   Buffer+1
         LDA   #$00                     ;Set Sector to 0
         STA   Sector
ZLoop:   LDY   #$00                     ;Reset Y offset to 0
         LDA   #$FE                     ;Set Volume # to 254 in 4&4 encoding
         JSR   LEncode
         LDA   Track                    ;Set Track,$ Sector to 4&4 encoding
         JSR   LEncode
         LDA   Sector
         JSR   LEncode
         LDA   #$FE                     ;Calculate the Checksum using 254
         EOR   Track
         EOR   Sector
         JSR   LEncode
         CLC                            ;Add 385 ($181) to Buffer address
         LDA   Buffer
         ADC   #$81
         STA   Buffer
         LDA   Buffer+1
         ADC   #$01
         STA   Buffer+1
         INC   Sector                   ;Add 1 to Sector value
         LDA   Sector                   ;If Sector > 16 then quit
         CMP   #$10
         BCC   ZLoop
         RTS                            ;Return to write track to disk (WRITE)
LEncode: PHA                            ;Put value on the stack
         LSR   a                        ;Shift everything right one bit
         ORA   #$AA                     ;OR it with $AA
         STA   (Buffer),y               ;Store 4&4 result in Buffer area
         INY
         PLA                            ;Retrieve value from the stack
         ORA   #$AA                     ;OR it with $AA
         STA   (Buffer),y               ;Store 4&4 result in Buffer area
         INY
         RTS
;*************************************
;*                                   *
;* Seek - Move head to desired track *
;*                                   *
;*************************************
Seek:

         LDA   #$00                     ;Set InOut flag to 0
         STA   LInOut
         LDA   TRKcur                   ;Fetch current track value
         SEC
         SBC   TRKdes                   ;Subtract destination track value
         BEQ   LExit                    ;If = 0 we're done
         BCS   LMove
         EOR   #$FF                     ;Convert resulting value to a positive number
         ADC   #$01
LMove:   STA   Count                    ;Store track value in Count
         ROL   LInOut                   ;Condition InOut flag
         LSR   TRKcur                   ;Is track # odd or even?
         ROL   LInOut                   ;Store result in InOut
         ASL   LInOut                   ;Shift left for .Table offset
         LDY   LInOut
ALoop:   LDA   LTable,y                 ;Fetch motor phase to turn on
         JSR   Phase                    ;Turn on stepper motor
         LDA   LTable+1,y               ;Fetch next phase
         JSR   Phase                    ;Turn on stepper motor
         TYA
         EOR   #$02                     ;Adjust Y offset into LTable
         TAY
         DEC   Count                    ;Subtract 1 from track count
         BNE   ALoop
         LDA   TRKdes                   ;Move current track location to TRKcur
         STA   TRKcur
LExit:   RTS                            ;Return to calling routine
;**********************************
;*                                *
;* PHASE - Turn the stepper motor *
;* on and off to move the head    *
;*                                *
;**********************************

Phase:
         ORA   SlotF                    ;OR Slot value to PHASE
         TAX
         LDA   Step1,x                  ;PHASE on...
         LDA   #$56                     ;20 ms. delay
         JSR   WAIT
         LDA   Step0,x                  ;PHASE off...
         RTS
;**********************************
;*                                *
;* Format a Ram3 device.          *
;*                                *
;**********************************
Ram3Form:
         php
         sei
         lda   #3                       ;Format Request number
         sta   $42
         Lda   Slot                     ;Slot of /Ram
         sta   $43
         lda   #$00                     ;Buffer space if needed Low byte
         sta   $44
         lda   #$67                     ; and high byte
         sta   $45

         lda   $C08B                    ;Read and write Ram,$ using Bank 1
         lda   $C08B

         jsr   Ram3Dri
         bit   $C082                    ;Read ROM,$ use Bank 2(Put back on line)
         bcs   Ram3Err
         plp
         rts

Ram3Dri: jmp   (Addr)
Ram3Err:
         tax
         plp
         pla
         pla
         txa
         jmp   Died
;**********************************
;*                                *
;* Format a SmartPort Device      *
;*                                *
;**********************************
SmartForm:
         Php
         sei
         lda   #0                       ;Request Protocol converter for a Status
         sta   $42
         Lda   ListSlot                 ;Give it the ProDOS Slot number
         and   #$F0
         sta   $43
         lda   #$00                     ;Give it a buffer may not be needed by
         sta   $44                      ; give it to it anyways
         lda   #$68
         sta   $45
         lda   #$03                     ;The Blocks of Device
         sta   $46
         jsr   SmartDri
         txa                            ;Low in X register
         STA   VolBlks                  ; Save it
         tya                            ; High in Y register
         STa   VolBlks+1                ; Save it
         LDa   #$00
         STa   VolBlks+2
         lda   #3                       ;Give Protocol Converter a Format Request
         sta   $42                      ;Give it Slot number
         Lda   ListSlot
         and   #$F0
         sta   $43
         lda   #$00                     ;Give a buffer which probably won't be
         sta   $44                      ; used.
         lda   #$68
         sta   $45

         jsr   SmartDri
         bcs   SmartErr
         plp
         rts

SmartDri:
         jmp   (Addr)
SmartErr:
         tax
         plp
         pla
         pla
         txa
         jmp   Died

;**********************************
;*                                *
;* Is there an old name?          *
;*                                *
;**********************************
OldName:
         lda   ListSlot
         and   #$F0
         STA   Info+1
         jsr   MLI
         .byte $C5
         .addr Info
         lda   VolLen
         and   #$0F
         bne   OldName1
         lda   VolLen+1
         cmp   #$28
         bne   OldError
         pla
         pla
         jmp   NoUnit
OldName1:
         sta   VolLen
         LDA   #<TheOld1
         LDY   #>TheOld1
         JSR   STROUT
         lda   #<VolLen                  ;Get Name Length
         ldy   #>VolLen
         jsr   STROUT                   ;Print old name
         LDA   #<TheOld2
         LDY   #>TheOld2
         JSR   STROUT
         jsr   GetYN
         beq   OldError
         pla
         pla
         jmp   Again
OldError:
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
Parms:   .byte $03                  ;Parameter count = 3
Slot:    .byte $60                  ;Default to S6,$D1
MLIbuf:  .addr BootCode             ;Default buffer address
MLIBlk:  .byte $00,$00          ;Default block number of 0
QSlot:   .byte   1              ;Quit Slot number
ListSlot: .byte    1             ;Saving the slot total from the list
Addr:    .res 2
NetParms:
         .byte $00
         .byte $2F                  ;Command for FIListSessions
         .addr $0000                ;Appletalk Result Code returned here
         .addr $0100                ;Length of string
         .addr $6700                ;Buffer low word
         .addr $0000                ;Buffer High word
NetDev:  .byte $00                  ;Number of entries returned here
LByte:   .byte 1                    ;Storage for byte value used in Fill
LAddr:   .byte $D5,$AA,$96 ; dc    H'D5 AA 96'              ;Address header
         .byte $AA,$AA,$AA,$AA,$AA,$AA,$AA,$AA ;dc    8i1'$AA'                 ;Volume #,$ Track,$ Sector,$ Checksum
         .byte $DE,$AA,$EB            ;Address trailer
         .byte $7f,$7f,$7f,$7f,$7f,$7f ; dc    6i1'$7F'                 ;GAP2 sync bytes
         .byte $D5,$AA,$AD            ;Buffer header
         .byte $00                      ;End of Address information
LData:   .byte $DE,$AA,$EB            ;Data trailer
         .byte $7F,$7F,$7F,$7F,$7F,$7F  ;GAP3 sync bytes
         .byte $00                          ;End of Data information

LInOut:  .res 1                        ;Inward/Outward phase for stepper motor
LTable:  .byte $02,$04,$06,$00              ;Phases for moving head inward
         .byte $06,$04,$02,$00              ;   |    |    |      |  outward

TargSlt: .byte $8D,$8D
         ascz "Format disk in SLOT "
TargDrv: ascz " DRIVE "
VolName: .byte $8d
         asc "Volume name: /"
Blank:   asc "BLANK"
         ascz "__________"
Verif:   .byte $8d,$8d
         asc "Certify disk and mark any bad blocks in "
         ascz "the Volume BitMap as unusable? (Y/N): "
TheOld1: .byte $8d
         asc "Do You Want To Write Over"
         .byte $8D,$A0,$AF,$00
TheOld2: .byte $A0,$BF
         ascz " (Y/N)"
UnRecog: .byte $8D
         ascz "Unrecognizable ERROR = "
Dead:    .byte $8D
         ascz "-- Check disk or drive door --"
Protect: .byte $8D
         ascz "Disk is write protected"
Bad:     .byte $8d,$8d
         ascz " bad block(s) marked"
Good:    .byte $8d,$8d
         ascz "Disk is error-free"
NoDisk:  .byte $8D
         ascz "No Disk in the drive"
Nuther:  .byte $8d,$8d
         ascz "Format another disk? (Y/N): "
TooLarge: .byte $8D
         ascz "Unit Size Is To Large For this Program"
UnitNone: .byte $8d
         asccr "No Unit in that slot and drive"
         ascz  "Format another disk? (Y/N): "
ItIsRam3: .byte $8d
         asccr "This is a Ram3 disk"
         ascz  "Continue with Format? (Y/N): "
ItsaII:  .byte $8D
         asc "This is a Disk II"
         .byte $8D
         ascz "Continue with Format? (Y/N): "
ItIsSmart: .byte $8D
         asccr "This is a SmartPort device"
         ascz  "Continue with Format? (Y/N): "
Appletalk:
         .byte $8D
         asc "Number of Appletalk devices is = "
NetNum:  .byte $00,$00,$00,$8D
         asccr "AppleTalk is installed this Program may"
         asccr "not work properly do you want to"
         ascz  "Continue (Y/N)"
Block2:  .byte $00,$00,$03,$00
VolLen:  .byte 1                        ;$F0 + length of Volume Name
VOLnam:  .res 15 ; .byte 15, 28 ; DS    15           28          ;Volume Name,$ Reserved,$ Creation,$ Version
Reserved: .res 6
UpLowCase: .byte $00,$00
Datime:   .res 4
Version: .byte 01
         .byte $00,$C3,$27,$0D
         .byte $00,$00,$06,$00
VolBlks: .res 3                         ;Number of blocks available
DirTbl:  .byte $02,$04,$03             ;Link list for directory blocks
         .byte $05,$04,$00
BitTbl:  .byte $7f ; dc    B'01111111'   ;BitMap mask for bad blocks
         .byte $bf ; dc    B'10111111'
         .byte $df ; dc    B'11011111'
         .byte $ef ; dc    B'11101111'
         .byte $f7 ; dc    B'11110111'
         .byte $fb ; dc    B'11111011'
         .byte $fd ; dc    B'11111101'
         .byte $fe ; dc    B'11111110'
Stack:   .res 1                        ;Entrance stack pointer
Count:   .res 3                        ;General purpose counter/storage byte
Pointer: .res 2                        ;Storage for track count (8 blocks/track)
Track:   .res 2                        ;Track number being FORMATted
Sector:  .res 2                        ;Current sector number (max=16)
SlotF:   .res 2                        ;Slot/Drive of device to FORMAT
TRKcur:  .res 2                        ;Current track position
TRKdes:  .res 2                        ;Destination track position
TRKbeg:  .byte 03                   ;Starting track number
TRKend:  .byte 35                   ;Ending track number
BootCode:
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