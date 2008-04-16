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

	.include "sos/interp.asm"	; Interpreter header
	.include "sos/sosmacros.i"	; OS macros
	.include "sos/sosconst.i"	; OS equates, characters, etc.
	.include "sos/sosvars.asm"
	.include "sos/conio.asm"	; Console I/O
	.include "sos/serial/sermessages.asm"	; Messages
	.include "ip65/common.i"	; More macros - ldax, for example

	.include "sos/interimmain.asm"

; Stubs:
PRD:
ROM:
DELAY:
motoroff:
CH:
FormatEntry:
PICKVOL:
CD:
DIR:
BLOAD:
GET_PREFIX:
Died:
Done:
SlotF:
NUM:
CHROVER:
WRITING:
PICKVOL2:
ReceiveNib:
READING:
PREPPRG:
GO_TRACK0:
INIT_DISKII:
sendnib:
SHOWHM1:
YN:
GETFN:
PAUSE:
GetSendType:
GETFN2:
BIGBUF:
BLKHI:
BLKLO:
PARMBUF:
INVFLG:
	rts

;---------------------------------------------------------
; Pull in all the rest of the code
;---------------------------------------------------------
;	.include "print.asm"
	.include "prodos/serial/serproto.asm"
;	.include "online.asm"
;	.include "rw.asm"
	.include "sr.asm"
	.include "prodos/serial/ssc.asm"
	.include "sos/serial/iiiacia.asm"
	.include "crc.asm"
;	.include "pickvol.asm"
;	.include "input.asm"
	.include "sos/serial/serconfigsos.asm"
;	.include "hostfns.asm"
;	.include "diskii.asm"
;	.include "nibble.asm"
;	.include "format.asm"			; Note: includes FORMAT segment
;	.include "bsave.asm"

	.segment "DATA"
