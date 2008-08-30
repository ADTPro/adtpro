;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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

.include "applechr.i"		; ASCII string productions
.include "const.i"

MINSLOT = $00	; The smallest slot number we're likely to encounter (zero-indexed)
MAXSLOT = $06	; The largest slot number we're likely to encounter (zero-indexed)

;---------------------------------------------------------
; Horizontal tabs for volume display
;---------------------------------------------------------
H_SL	= $02
H_DR	= $08
H_VO	= $0f
H_SZ	= $21
VOL_LINE_LEN = $24

;---------------------------------------------------------
; Zero page locations (all unused by ProDOS,
; Applesoft, Disk Drivers and the Monitor)
;---------------------------------------------------------

; $6-$9, $19-$1e are free
ZP	= $06		; ($01 byte)
UTILPTR	= $07		; ($02 bytes) Used for printing messages
COL_SAV	= $09		; ($01 byte)
RLEPREV = $19		; ($01 byte)
UDPI	= $1a		; ($01 byte) Used by UDP SEND and RECEIVE
BLKPTR	= $1b		; ($02 bytes) Used by SEND and RECEIVE
synccnt	= $1d		; ($02 bytes) Used by nibble/halftrack
CRC	= $1d		; ($02 bytes) Used by ONLINE, SEND and RECEIVE
Buffer  = $1d 		; ($02 bytes) Address pointer for FORMAT data
CRCY	= $8a		; ($01 byte) Used by UDP SEND
TMOT    = $8b		; ($01 byte) Timeout indicator
NIBPCNT	= $8c		; ($01 byte) Counts nibble pages

;--------------------------------------------------------- 
; ProDOS specific stuff
;--------------------------------------------------------- 
OS_CALL_OFFSET	= 4	; Offset to the MLI call type/opcode byte
CHR_RETURN	= $8d	; Carriage return

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
BASL	= $28		; Base Line Address Lo
BASH	= $28		; Base Line Address Hi
INVFLG	= $32		; Inverse flag
A1L	= $3c
A1H	= $3d
A2L	= $3e
A2H	= $3f
A4L	= $42
A4H	= $43
KEYBUFF	= $0280	; Keyboard buffer
MSLOT	= $07f8	; Pascal entry point scrren hole
BASCALC	= $FBC1 ; Calculate screen line
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
INPUT_BUFFER = $200
WARMDOS  = $BE00		; BASIC Warm-start vector
LAST     = $BF30		; Last device accessed by ProDOS
CLRLN    = $FC9C		; Clear Line routine
PRBYTE   = $FDDA		; Print Byte routine (HEX value)
COUT     = $FDED		; Character output routine (print to screen)

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
