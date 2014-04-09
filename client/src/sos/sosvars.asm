;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2014 by David Schmidt
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

.export output_buffer

.global CAPBLKS, PARMBUF, BLKLO, BLKHI, BIGBUF, CRCTBLL, CRCTBLH
.global NUMBLKS, HOSTBLX, UNITNBR
.global PARMS, COMMSLOT, PSPEED, PSOUND, PSAVE, PGSSLOT, SR_WR_C, SLOWA, SLOWX, SLOWY
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
BIGBUF_ADDR_LO	= $26
BIGBUF_ADDR_HI	= $27
BIGBUF_XBYTE	= $1627		; XByte address for our bank
BASL	= $28
BASH	= $29
synccnt	= $2a		; ($02 bytes) Used by nibble/halftrack
CRC	= $2c		; ($02 bytes) Used by ONLINE, SEND and RECEIVE
Buffer  = $2e 		; ($02 bytes) Address pointer for FORMAT data
CRCY	= $30		; ($01 byte) Used by UDP SEND
TMOT    = $31		; ($01 byte) Timeout indicator
NIBPCNT	= $32		; ($01 byte) Counts nibble pages
UTILPTR2	= $33		; ($02 bytes) Used for printing messages too
A1L	= $35		; ($02 bytes) Used in ethernet transport buffer movement
CRCTBLL:	.res $100	; CRC LOW TABLE  ($100 Bytes)
CRCTBLH:	.res $100	; CRC HIGH TABLE ($100 Bytes)
BLKHI:		.byte $01
BLKLO:		.byte $01
output_buffer:	.res 520	; For ip65 buffer space

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
D_STATUS_DATA:	.byte $00, $00

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

FIND_SEG_PARMS:	.byte $06	; Six parameters
FIND_SEG_MODE:	.byte $00	; In - don't cross 32k boundaries
FIND_SEG_LABEL:	.byte $10	; In - our segment "label"
FIND_SEG_PAGES:	.addr $0050	; In/Out - number of pages
FIND_SEG_BASE:	.addr $0000	; Out - origin segment addr
FIND_SEG_LIMIT:	.addr $0000	; Out - last segment addr
FIND_SEG_NUM:	.byte $00	; Out - segment "number"

; Set Prefix

TBL_SET_PFX:
         .byte 1
         .addr CUR_PFX    ; addr of pathname

CUR_PFX:	.res 64

; Get Prefix

GET_PFX_PLIST:
	.byte 1
	.addr CUR_PFX

; Table for open

FILE_OP:	.byte 4
FILE_NAME:	.addr CONFIG_FILE_NAME	; addr len+name
FILE_OPN:	.byte $00		; file reference number
FILE_OPTION:	.addr $0000		; No options
FILE_OPTIONS:	.byte $00		; No options

; Table for create

FILE_CR:	.byte $03
		.addr CONFIG_FILE_NAME	; addr len+name
		.addr FILE_CR_OPTIONS	; Option list
		.byte $01		; Only file type option exists

FILE_CR_OPTIONS:
		.byte $06		; BIN file

; Table for read

FILE_RD:	.byte 4
FILE_RDN:	.byte 0			; opened file number
FILE_RADR:	.addr PARMS		; loading addr
FILE_RLEN:	.addr PARMSEND-PARMS	; max len
FILE_RALEN:	.addr $FFFF		; real len of loaded file

; Table for write

FILE_WR:	.byte 3
FILE_WRN:	.byte 0			; opened file number
FILE_WADR:	.addr PARMS		; loading addr
FILE_WLEN:	.addr PARMSEND-PARMS	; max len

; Table for close

FILE_CL:	.byte 1
FILE_END:
FILE_CLN:	.byte 0			; opened file number