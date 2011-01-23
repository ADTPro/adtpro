;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2011 by David Schmidt
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

	.include "sos/interp.asm"	; Interpreter header
	.include "sos/sosmacros.i"	; OS macros
	.include "sos/sosconst.i"	; OS equates, characters, etc.
	.include "sos/sosvars.asm"
	.include "sos/serial/sermessages.asm"	; Messages
	.include "ip65/inc/common.i"	; More macros - ldax, for example

	.include "main.asm"

;---------------------------------------------------------
; Pull in all the rest of the code
;---------------------------------------------------------
	.include "sos/conio.asm"	; Console I/O
	.include "print.asm"
	.include "prodos/serial/serproto.asm"
	.include "sos/online.asm"
	.include "sos/rw.asm"
	.include "sr.asm"
	.include "prodos/serial/ssc.asm"
	.include "sos/serial/iiiacia.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "sos/serial/serconfigsos.asm"
	.include "hostfns.asm"
	.include "sos/format.asm"			; Note: includes FORMAT segment
	.include "bsave.asm"

; Stubs from Disk II-related stuff
ReceiveNib:
GO_TRACK0:
INIT_DISKII:
sendnib:
motoroff:
	rts

; Stubs:
ROM:
;BSAVE:
CH:
CV:
INVFLG:
DevAdr:
DevList:
DevCnt:
PEND:
TBL_ONLINE:
UNIT:
DEVLST:
DEVICE:
KEYBUFF:
ZDEVCNT:
DEVCNT:
	.segment "DATA"
