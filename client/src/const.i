;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006, 2007 by David Schmidt
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
BISLOT	= $BE3C
BIDRIVE	= $BE3D
BITMAP	= $BF58 ; bitmap of low 48k of memory
DEVICE	= $BF30 ; last drive+slot used, DSSS0000
DEVCNT	= $BF31 ; Count (minus 1) of active devices
DEVLST	= $BF32 ; List of active devices (Slot, drive, id =DSSSIIII)

;---------------------------------------------------------
; ProDOS equates
;---------------------------------------------------------
PD_QUIT	= $65
PD_READBLOCK	= $80
PD_WRITE	= $81
PD_INFO	= $C4
PD_ONL	= $C5
PD_SET_PREFIX	= $C6
PD_GET_PREFIX	= $C7
PD_OPEN	= $C8
PD_READFILE	= $CA
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
CLREOL	= $FC9C	; Clear to end of line
CLREOP	= $FC42	; Clear to end of screen
HOME	= $FC58	; Clear screen
TABV	= $FB5B	; Set BASL from Accumulator
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
DRVSM0OFF	= $C0E0 ; Phase 0 off  Stepper motor
DRVSM1OFF	= $C0E2 ; Phase 1 off
DRVSM2OFF	= $C0E4 ; Phase 2 off
DRVSM3OFF	= $C0E6 ; Phase 3 off
DRVSM0ON	= $C0E1 ; Phase 0 on   Stepper motor
DRVSM1ON	= $C0E3 ; Phase 1 on
DRVSM2ON	= $C0E5 ; Phase 2 on
DRVSM3ON	= $C0E7 ; Phase 3 on
DRVOFF		= $C0E8 ; drive off
DRVON		= $C0E9 ; drive on
DRVSL1		= $C0EA ; drive selection
DRVRD		= $C0EC ; Strobe input
DRVRDM		= $C0EE ; switch on READ mode

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
