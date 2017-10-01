;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2008 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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
; DiskII flag: did the user ask for a Disk II device?
;---------------------------------------------------------
NonDiskII:	.byte $00	; $00 = We do _not_ have a Disk II
				; $01 = We _have_ a Disk II
SendType:	.byte CHR_P	; CHR_P = Normal Put
				; CHR_N = Nibble send
				; CHR_H = Half track send

;---------------------------------------------------------
; Variables - memory written to
;---------------------------------------------------------
NUMBLKS:
	.byte $00, $00	; Number of blocks of a chosen volume
HOSTBLX:
	.byte $00, $00	; Number of blocks in a host image
UNITNBR:
	.byte $00	; Unit number of chosen volume

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
