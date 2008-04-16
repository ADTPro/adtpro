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

.global CAPBLKS, DEVICES, PARMBUF, BLKLO, BLKHI, BIGBUF, CRCTBLL, CRCTBLH
.global NUMBLKS, HOSTBLX, UNITNBR
.global PARMS, PSSC, PSPEED, PSOUND, PSAVE, PGSSLOT, SR_WR_C, SLOWA, SLOWX, SLOWY
.global PCCRC, COLDSTART, BAUD, NonDiskII, SendType

.globalzp ZP, UTILPTR, COL_SAV, RLEPREV, UNUSED1, CRC, BLKPTR, Buffer

.include "vars.asm"

;----------------------------------------------------
; Zero page usage
;----------------------------------------------------
ZP	= $20		; ($01 byte)
UTILPTR	= $21		; ($02 bytes) Used for printing messages
COL_SAV	= $23		; ($01 byte)
RLEPREV = $24		; ($01 byte)
UDPI	= $25		; ($01 byte) Used by UDP SEND and RECEIVE
BLKPTR	= $26		; ($02 bytes) Used by SEND and RECEIVE
synccnt	= $28		; ($02 bytes) Used by nibble/halftrack
CRC	= $2a		; ($02 bytes) Used by ONLINE, SEND and RECEIVE
Buffer  = $2c 		; ($02 bytes) Address pointer for FORMAT data
CRCY	= $2e		; ($01 byte) Used by UDP SEND
TMOT    = $2f		; ($01 byte) Timeout indicator
NIBPCNT	= $30		; ($01 byte) Counts nibble pages

CRCTBLL:	.res $100	; CRC LOW TABLE  ($100 Bytes)
CRCTBLH:	.res $100	; CRC HIGH TABLE ($100 Bytes)

;----------------------------------------------------
; Operating System Call Tables
;----------------------------------------------------

; Table for open

OPEN_PARMS:	.byte 4
OPEN_NAME:	.addr CONSOLE
OPEN_REF:	.byte $ff
OPEN_OPT_PTR:	.addr 0
OPEN_LEN:	.byte 0

CONSOLE:	.byte CONSOLE_END-CONSOLE_BODY
CONSOLE_BODY:	.byte ".CONSOLE"
CONSOLE_END:

; Table for write string

WRITE_PARMS:	.byte 3
WRITE_REF:	.byte $FF
WRITE_DATA_PTR:	.word UTILPTR	; UTILPTR will always be our pointer to data to write
WRITE_LEN:	.word $0000

; Table for write one character

WRITE1_PARMS:	.byte 3
WRITE1_REF:	.byte $FF
WRITE1_DATA_PTR:
		.word WRITE1_DATA
WRITE1_LEN:	.word $0001
WRITE1_DATA:	.byte $00

; Table for console read

CONSREAD_PARMS:	.byte $04
CONSREAD_REF:	.byte $00
		.word CONSREAD_INPUT
CONSREAD_COUNT:	.word $0001
CONSREAD_XFERCT:.word $0000
CONSREAD_INPUT:	.byte $00

; Table for get device number

GET_DEV_NUM_PARMS:
		.byte $02
GET_DEV_NUM_NAME:
		.addr CONSOLE
GET_DEV_NUM_REF:
		.byte $00

; Table for device status

D_STATUS_PARMS:	.byte $03
D_STATUS_NUM:	.byte $01
D_STATUS_CODE:	.byte $00
D_STATUS_LIST:	.addr D_STATUS_DATA
D_STATUS_DATA:	.res $02, $00
