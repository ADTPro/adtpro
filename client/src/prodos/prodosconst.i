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

.include "const.i"

;--------------------------------------------------------- 
; ProDOS specific stuff
;--------------------------------------------------------- 
OS_CALL_OFFSET = 3	; Offset to the MLI call type/opcode byte

;---------------------------------------------------------
; Passive addresses (not written to)
;---------------------------------------------------------
PRODOS_MLI	= $BF00
MLIADDR		= $BF10
BITMAP		= $BF58 ; bitmap of low 48k of memory
DEVICE		= $BF30 ; last drive+slot used, DSSS0000
DEVCNT		= $BF31 ; Count (minus 1) of active devices
DEVLST		= $BF32 ; List of active devices (Slot, drive, id =DSSSIIII)

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
; Equates from imported formatting code
;---------------------------------------------------------
Home     = $FC58		; Monitor clear screen and home cursor
DevCnt   = $BF31		; Prodos device count
DevList  = $BF32		; List of devices for ProDOS
DevAdr   = $BF10		; Given slot this is the address of driver
IN       = $200			; Keyboard input buffer
WARMDOS  = $BE00		; BASIC Warm-start vector
LAST     = $BF30		; Last device accessed by ProDOS
WAIT     = $FCA8		; Delay routine
CLRLN    = $FC9C		; Clear Line routine
PRBYTE   = $FDDA		; Print Byte routine (HEX value)
COUT     = $FDED		; Character output routine (print to screen)

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