;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2010 by David Schmidt
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

.export DELAY

MAXSLOT = $07	; The largest slot number we're likely to encounter (one-indexed)

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
RSHIMEM		= $BEFB
GETBUFR		= $BEF5
FREEBUFR	= $BEF8
PRODOS_MLI	= $BF00
MLIADDR		= $BF10
DEVADR01	= $BF10	; Slot 0 reserved
DEVADR11	= $BF12	; Slot 1, drive 1
DEVADR21	= $BF14	; Slot 2, drive 1
DEVADR31	= $BF16	; Slot 3, drive 1
DEVADR41	= $BF18	; Slot 4, drive 1
DEVADR51	= $BF1A	; Slot 5, drive 1
DEVADR61	= $BF1C	; Slot 6, drive 1
DEVADR71	= $BF1E	; Slot 7, drive 1
DEVADR02	= $BF20	; Slot 0 reserved
DEVADR12	= $BF22	; Slot 1, drive 2
DEVADR22	= $BF24	; Slot 2, drive 2
DEVADR32	= $BF26	; Slot 3, drive 2
DEVADR42	= $BF28	; Slot 4, drive 2
DEVADR52	= $BF2A	; Slot 5, drive 2
DEVADR62	= $BF2C	; Slot 6, drive 2
DEVADR72	= $BF2E	; Slot 7, drive 2
DEVICE		= $BF30 ; last drive+slot used, DSSS0000
DEVCNT		= $BF31 ; Count (minus 1) of active devices
DEVLST		= $BF32 ; List of active devices (Slot, drive, id =DSSSIIII)
BITMAP		= $BF58 ; bitmap of low 48k of memory
DATE		= $BF90 ; Date storage
TIME		= $BF92 ; Time storage

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
BASCALC	= $FBC1 ; Calculate screen line
CLREOL	= $FC9C	; Clear to end of line
CLREOP	= $FC42	; Clear to end of screen
HOME	= $FC58	; Clear screen
NXTA1	= $FCBA	; Increment A1, compare to A2
TABV	= $FB5B	; Set BASL from Accumulator
VTAB	= $FC22	; SET BASL FROM CV
RDKEY	= $FD0C	; Character input
NXTCHAR	= $FD75	; Line input
COUT1	= $FDF0	; Character output
CROUT	= $FD8E	; Output return character
PRDEC	= $ED24	; Print pointer as decimal
DELAY	= $FCA8 ; Monitor delay: # cycles = (5*A*A + 27*A + 26)/2
MEMMOVE	= $FE2C	; Perform memory move: A1-A2 TO A4
VERSION	= $FBB3 ; Version byte 
ROM		= $C082 ; Enables rom

;---------------------------------------------------------
; Equates from imported formatting code
;---------------------------------------------------------
Home     = $FC58		; Monitor clear screen and home cursor
DevCnt   = $BF31		; Prodos device count
DevList  = $BF32		; List of devices for ProDOS
DevAdr   = $BF10		; Given slot this is the address of driver
IN_BUF	 = $200			; Keyboard input buffer
WARMDOS  = $BE00		; BASIC Warm-start vector
LAST     = $BF30		; Last device accessed by ProDOS
CLRLN    = $FC9C		; Clear Line routine
PRBYTE   = $FDDA		; Print Byte routine (HEX value)
COUT     = $FDED		; Character output routine (print to screen)

CASSLOT		= $08	; Selection number for cassette transport
