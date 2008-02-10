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
; Passive addresses (not written to)
;---------------------------------------------------------
MLI	= $BF00
MLIADDR	= $BF10
BITMAP	= $BF58 ; bitmap of low 48k of memory
DEVICE	= $BF30 ; last drive+slot used, DSSS0000
DEVCNT	= $BF31 ; Count (minus 1) of active devices
DEVLST	= $BF32 ; List of active devices (Slot, drive, id =DSSSIIII)

;---------------------------------------------------------
; ProDOS equates
;---------------------------------------------------------
PD_QUIT	= $65
PD_READBLOCK	= $80
PD_WRITEBLOCK	= $81
PD_CREATE	= $C0
PD_INFO	= $C4
PD_ONL	= $C5
PD_SET_PREFIX	= $C6
PD_GET_PREFIX	= $C7
PD_OPEN	= $C8
PD_READFILE	= $CA
PD_WRITEFILE	= $CB
PD_CLOSE	= $CC

;---------------------------------------------------------
; Monitor equates
;---------------------------------------------------------
CH	= $24		; Character horizontal position
CV	= $25		; Character vertical position
BASL	= $28		; Base Line Address
INVFLG	= $32		; Inverse flag
A1L	= $3c
A1H	= $3d
A2L	= $3e
A2H	= $3f
A4L	= $42
A4H	= $43
KEYBUFF	= $0280	; Keyboard buffer
MSLOT	= $07f8	; Pascal entry point scrren hole
CLREOL	= $FC9C	; Clear to end of line
CLREOP	= $FC42	; Clear to end of screen
HOME	= $FC58	; Clear screen
TABV	= $FB5B	; Set BASL from Accumulator
VTAB	= $FC22	; SET BASL FROM CV
RDKEY	= $FD0C	; Character input
NXTCHAR	= $FD75	; Line input
COUT1	= $FDF0	; Character output
CROUT	= $FD8E	; Output return character
PRDEC	= $ED24	; Print pointer as decimal
DELAY	= $FCA8 ; Monitor delay: # cycles = (5*A*A + 27*A + 26)/2
MEMMOVE	= $FE2C	; PERFORM MEMORY MOVE A1-A2 TO A4
ROM	= $C082 ; Enables rom

;---------------------------------------------------------
; Disk II soft switches
;---------------------------------------------------------
DRVSM0OFF	= $C080 ; Phase 0 off  Stepper motor
DRVSM1OFF	= $C082 ; Phase 1 off
DRVSM2OFF	= $C084 ; Phase 2 off
DRVSM3OFF	= $C086 ; Phase 3 off
DRVSM0ON	= $C081 ; Phase 0 on   Stepper motor
DRVSM1ON	= $C083 ; Phase 1 on
DRVSM2ON	= $C085 ; Phase 2 on
DRVSM3ON	= $C087 ; Phase 3 on
DRVON		= $C089 ; drive on
DRVSEL		= $C08A ; drive selection
DRVRD		= $C08C ; Strobe input
DRVRDM		= $C08E ; switch on READ mode

;---------------------------------------------------------
; Equates from imported formatting code
;---------------------------------------------------------
Home     =  $FC58		; Monitor clear screen and home cursor
DevCnt   =  $BF31		; Prodos device count
DevList  =  $BF32		; List of devices for ProDOS
DevAdr   =  $BF10		; Given slot this is the address of driver
IN       =  $200		; Keyboard input buffer
WARMDOS  =  $BE00		; BASIC Warm-start vector
LAST     =  $BF30		; Last device accessed by ProDOS
WAIT     =  $FCA8		; Delay routine
CLRLN    =  $FC9C		; Clear Line routine
PRBYTE   =  $FDDA		; Print Byte routine (HEX value)
COUT     =  $FDED		; Character output routine (print to screen)
Step0    =  $C080		; Drive stepper motor positions
Step1    =  $C081		;   |      |      |       |
Step2    =  $C082		;   |      |      |       |
Step4    =  $C084		;   |      |      |       |
Step6    =  $C086		;   |      |      |       |
DiskOFF  =  $C088		; Drive OFF  softswitch
DiskON   =  $C089		; Drive ON   softswitch
Select   =  $C08A		; Starting offset for target device
DiskRD   =  $C08C		; Disk READ  softswitch
DiskWR   =  $C08D		; Disk WRITE softswitch
ModeRD   =  $C08E		; Mode READ  softswitch
ModeWR   =  $C08F		; Mode WRITE softswitch

;---------------------------------------------------------
; Horizontal tabs for volume display
;---------------------------------------------------------
H_SL	= $02
H_DR	= $08
H_VO	= $0f
H_SZ	= $21

;---------------------------------------------------------
; Horizontal tabs for buffer display
;---------------------------------------------------------
H_BUF	= $05
H_BLK	= $0f
H_NUM1	= $15

;---------------------------------------------------------
; Veritcal tab for buffer display
;---------------------------------------------------------
V_MSG	= $0b
V_BUF	= $0f

;---------------------------------------------------------
; Characters
;---------------------------------------------------------
CHR_BLK	= $20
CHR_SP	= _' '
CHR_DOT = _'.'
CHR_A	= _'A'
CHR_B	= _'B'
CHR_C	= _'C'
CHR_D	= _'D'
CHR_E	= _'E'
CHR_F	= _'F'
CHR_G	= _'G'
CHR_H	= _'H'
CHR_I	= _'I'
CHR_J	= _'J'
CHR_K	= _'K'
CHR_L	= _'L'
CHR_M	= _'M'
CHR_N	= _'N'
CHR_O	= _'O'	; The letter O
CHR_P	= _'P'
CHR_Q	= _'Q'
CHR_R	= _'R'
CHR_S	= _'S'
CHR_T	= _'T'
CHR_U	= _'U'
CHR_V	= _'V'
CHR_W	= _'W'
CHR_X	= _'X'
CHR_Y	= _'Y'
CHR_Z	= _'Z'
CHR_0	= _'0'	; Zero
CHR_1	= _'1'
CHR_2	= _'2'
CHR_3	= _'3'
CHR_4	= _'4'
CHR_5	= _'5'
CHR_6	= _'6'
CHR_7	= _'7'
CHR_8	= _'8'
CHR_9	= _'9'
CHR_ESC	= $9b
CHR_ENQ = $05
CHR_ACK	= $06
CHR_NAK	= $15
CHR_CAN = $18

;---------------------------------------------------------
; Nibble/halftrack stuff
;---------------------------------------------------------
NIBPAGES	= $34		; Number of nibble pages to send

;---------------------------------------------------------
; Apple IIgs SCC Z8530 registers and constants
;---------------------------------------------------------

GSCMDB	=	$C038
GSDATAB	=	$C03A

GSCMDA	=	$C039
GSDATAA	=	$C03B

RESETA	=	%11010001	; constant to reset Channel A
RESETB	=	%01010001	; constant to reset Channel B
WR11A	=	%11010000	; init wr11 in Ch A
WR11BXTAL	=	%00000000	; init wr11 in Ch B - use external clock
WR11BBRG	=	%01010000	; init wr11 in Ch B - use baud rate generator

CASSLOT		= $08	; Selection number for cassette transport
