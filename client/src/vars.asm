;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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
.global PCCRC, L0EF8, COLDSTART, BAUD

.globalzp ZP, UTILPTR, COL_SAV, RLEPREV, UNUSED1, BLKPTR, CRC

;------------------------------------
; Variables - memory written to
;------------------------------------

CAPBLKS:
	.res $20, $00
DEVICES:
	.res $100, $00	; ($100 bytes)
PARMBUF:
	.res $100, $00
BLKLO	= PARMBUF+$04	; Part of PARMBUF structure
BLKHI	= PARMBUF+$05	; Part of PARMBUF structure

BIGBUF	= $4400		; The place where all the action happens
CRCTBLL	= $9400		; CRC LOW TABLE  ($100 Bytes)
CRCTBLH	= $9500		; CRC HIGH TABLE ($100 Bytes)
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
UNUSED1	= $1a		; ($01 byte)
BLKPTR	= $1b		; ($02 bytes) Used by SEND and RECEIVE
CRC	= $1d		; ($02 bytes) Used by ONLINE, SEND and RECEIVE

SR_WR_C:
	.byte $00	; A place to save the send/receive/read/write character
SLOWA:	.byte $00	; A place to save the Accumulator, speed is not important
SLOWX:	.byte $00	; A place to save the X register, speed is not important
SLOWY:	.byte $00	; A place to save the Y register, speed is not important
PCCRC:	.byte $00,$00	; CRC received from PC
L0EF8:	.byte $05,$07,$09
	.byte $0B,$0D,$0E,$00,$00

COLDSTART:
	.byte $00

;---------------------------------------------------------
; Default SCC baud rate
;---------------------------------------------------------
BAUD:	.byte 6	;1=300, 2=1200, 3=2400
		;4=4800, 5=9600, 6=19200
		;7=38400, 8=57600.

