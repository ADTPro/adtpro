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

.global CAPBLKS, PARMBUF, BLKLO, BLKHI, CRCTBLL, CRCTBLH
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
BASL	= $28
BASH	= $29
synccnt	= $2a		; ($02 bytes) Used by nibble/halftrack
CRC	= $2c		; ($02 bytes) Used by ONLINE, SEND and RECEIVE
Buffer  = $2e 		; ($02 bytes) Address pointer for FORMAT data
CRCY	= $30		; ($01 byte) Used by UDP SEND
TMOT    = $31		; ($01 byte) Timeout indicator
NIBPCNT	= $32		; ($01 byte) Counts nibble pages
UTILPTR2	= $33		; ($02 bytes) Used for printing messages too
BIGBUF_ADDR_LO	= $35		; ($01 byte) points to big buffer low in 
BIGBUF_ADDR_HI	= $36		; ($01 byte) points to big buffer high
BIGBUF_XBYTE	= $1635		; XByte address for our bank
CRCTBLL:	.res $100	; CRC LOW TABLE  ($100 Bytes)
CRCTBLH:	.res $100	; CRC HIGH TABLE ($100 Bytes)
BLKHI:		.byte $01
BLKLO:		.byte $01

;----------------------------------------------------
; Operating System Call Tables
;----------------------------------------------------

PARMBUF:	.res $04

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
CONSREAD_INPUT:	.res $100, $00

; Table for get device number

GET_DEV_NUM_PARMS:
		.byte $02
GET_DEV_NUM_NAME:
		.addr CONSOLE
GET_DEV_NUM_REF:
		.byte $00

; Table for device status

D_STATUS_PARMS:	.byte $03
D_STATUS_NUM:	.byte $00
D_STATUS_CODE:	.byte $00
D_STATUS_LIST:	.addr D_STATUS_DATA
D_STATUS_DATA:	.byte $00

; Table for device control

D_CONTROL_PARMS:
		.byte $03
D_CONTROL_NUM:	.byte $01
D_CONTROL_CODE:	.byte $00
D_CONTROL_LIST:	.addr D_CONTROL_DATA
D_CONTROL_DATA:	.byte $00, $00

; Table for dev_info query

D_INFO_PARMS:	.byte $04
D_INFO_NUM:	.byte $01
D_INFO_NAME_PTR:
		.addr D_INFO_NAME
D_INFO_OPTION_PTR:
		.addr D_INFO_OPTION
D_INFO_LENGTH:	.byte $07

D_INFO_NAME:	.res 16
D_INFO_OPTION:	.res $07
D_INFO_OPTION_END = *

; Table for massive block read (rw.asm)

D_RW_PARMS:	.byte $05	; 5 for Read, 4 for Write
D_RW_DEV_NUM:	.byte $00
D_RW_BUFFER_PTR:
		.addr $0000	; In
D_RW_BYTE_COUNT:
		.word $0000	; In; $5000 is 20k, the full boat (but we calculate it anyway)
D_RW_BLOCK:	.word $0000	; In
D_RW_BYTES_READ:
		.word $0000	; Out (only used for Write)
D_RW_END:

; Table for volume query

VOLUME_PARMS:	.byte $04
VOLUME_DEV_PTR:	.addr D_INFO_NAME
VOLUME_NAME_PTR:
		.addr VOLUME_NAME
VOLUME_BLOCKS:	.res 2
VOLUME_FREE:	.res 2

VOLUME_NAME:	.res $10

MEM_REQ_PARMS:	.byte $06	; Six parameters
MEM_REQ_MODE:	.byte $00	; In - cross no 32k boundaries
MEM_REQ_SEG:	.byte $10	; In - our segment "label"
MEM_REQ_PAGES:	.addr $0050	; In/Out - number of pages
MEM_REQ_BASE:	.addr $0000	; Out - origin segment addr
MEM_REQ_LIMIT:	.addr $0000	; Out - last segment addr
MEM_REQ_NUM:	.byte $00	; Out - segment "number"
