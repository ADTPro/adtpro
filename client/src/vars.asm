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

.global CAPBLKS, DEVICES, PARMBUF, BLKLO, BLKHI, BIGBUF, CRCTBLL, CRCTBLH
.global NUMBLKS, HOSTBLX, UNITNBR
.global PARMS, PSSC, PSPEED, PSOUND, PSAVE, PGSSLOT, SR_WR_C, SLOWA, SLOWX, SLOWY
.global PCCRC, COLDSTART, BAUD, NonDiskII, SendType

.globalzp ZP, UTILPTR, COL_SAV, RLEPREV, UNUSED1, BLKPTR, CRC

;------------------------------------
; Variables - memory written to
;------------------------------------

DEVICES = BIGBUF	; ($100 bytes)
CAPBLKS = DEVICES + $100; ($20 bytes)
PARMBUF:
	.res $10, $00
BLKLO	= PARMBUF+$04	; Part of PARMBUF structure
BLKHI	= PARMBUF+$05	; Part of PARMBUF structure

BIGBUF	= $6C00		; The place where all the action happens
CRCTBLL	= $BC00		; CRC LOW TABLE  ($100 Bytes)
CRCTBLH	= $BD00		; CRC HIGH TABLE ($100 Bytes)
NUMBLKS:
	.byte $00, $00	; Number of blocks of a chosen volume
HOSTBLX:
	.byte $00, $00	; Number of blocks in a host image
UNITNBR:
	.byte $00	; Unit number of chosen volume

;------------------------------------
; Zero page locations (all unused by ProDOS,
; Applesoft, Disk Drivers and the Monitor)
;------------------------------------

; $6-$9, $19-$1e are free
ZP	= $06		; ($01 byte)
UTILPTR	= $07		; ($02 bytes) Used for printing messages
COL_SAV	= $09		; ($01 byte)
RLEPREV = $19		; ($01 byte)
UDPI	= $1a		; ($01 byte) Used by UDP SEND and RECEIVE
BLKPTR	= $1b		; ($02 bytes) Used by SEND and RECEIVE
synccnt	= $1d		; ($02 bytes) Used by nibble/halftrack
CRC	= $1d		; ($02 bytes) Used by ONLINE, SEND and RECEIVE
CRCY	= $8a		; ($01 byte) Used by UDP SEND
TMOT    = $8b		; ($01 byte) Timeout indicator
NIBPCNT	= $8c		; ($01 byte) Counts nibble pages

SR_WR_C:
	.byte $00	; A place to save the send/receive/read/write character
SLOWA:	.byte $00	; A place to save the Accumulator, speed is not important
SLOWX:	.byte $00	; A place to save the X register, speed is not important
SLOWY:	.byte $00	; A place to save the Y register, speed is not important
iobtrk:
PCCRC:	.byte $00
maxtrk:
PCCRC2:	.byte $00	; CRC received from PC

pdslot:	.byte $06
pdrive:	.byte $00
pdsoftx:
	.byte $00

top_stack:	.byte $00

;---------------------------------------------------------
; Default SCC baud rate
;---------------------------------------------------------
BAUD:	.byte 6	;1=300, 2=1200, 3=2400
		;4=4800, 5=9600, 6=19200
		;7=38400, 8=57600.

;---------------------------------------------------------
; DiskII flag: did the user ask for a Disk II device?
;---------------------------------------------------------
NonDiskII:	.byte $00	; $00 = We do _not_ have a Disk II
				; $01 = We _have_ a Disk II
SendType:	.byte CHR_P	; CHR_P = Normal Put
				; CHR_N = Nibble send
				; CHR_H = Half track send