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

;------------------------------------
; Variables - memory written to
;------------------------------------

DEVICES:		; DEVICES and CAPBLKS used to share space
	.res $100	; with BIGBUF, but we're storing them now
CAPBLKS:		; for faster volume selection.
	.res $20
PARMBUF:
	.res $20, $00
BLKLO	= PARMBUF+$04	; Part of PARMBUF structure
BLKHI	= PARMBUF+$05	; Part of PARMBUF structure

BIGBUF	= $6600		; The place where all the action happens
; Note: we now have 6 pages of free space between $B600 and $BC00.
CRCTBLL	= $BC00		; CRC LOW TABLE  ($100 Bytes)
CRCTBLH	= $BD00		; CRC HIGH TABLE ($100 Bytes)

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
; Variables from BLOAD/BSAVE code
;---------------------------------------------------------
ZDEVCNT:	.byte 0

; Online

TBL_ONLINE:
         .byte 2
UNIT:    .byte 0          ; unit
         .addr CUR_PFX+1  ; 16 bytes buffer for a specific unit

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

FILE_OP:	.byte 3
FILE_NAME:	.addr CONFIG_FILE_NAME	; addr len+name
FILE_BUF_PTR:	.addr BIGBUF+1024	; 1024 bytes buffer
FILE_OPN:	.byte 0		; opened file number

; Table for create

FILE_CR:	.byte $07
		.addr CONFIG_FILE_NAME	; addr len+name
		.byte $C3		; Full access
		.byte $06		; BIN file
		.addr $FFFF		; Aux data - load addr
		.byte $01			; Standard seedling file
		.byte $00, $00		; Creation date
		.byte $00, $00		; Creation time

; Table for read

FILE_RD:	.byte 4
FILE_RDN:	.byte 0			; opened file number
FILE_RADR:	.addr PARMS		; loading addr
FILE_RLEN:	.addr PARMSEND-PARMS	; max len
FILE_RALEN:	.addr $FFFF		; real len of loaded file

; Table for write

FILE_WR:	.byte 4
FILE_WRN:	.byte 0			; opened file number
FILE_WADR:	.addr PARMS		; loading addr
FILE_WLEN:	.addr PARMSEND-PARMS	; max len
FILE_WALEN:	.byte 0,0		; real len of loaded file

; Table for close

FILE_CL:	.byte 1
FILE_END:
FILE_CLN:	.byte 0			; opened file number