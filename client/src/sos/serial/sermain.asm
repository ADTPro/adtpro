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
	.include "about.asm"
	.include "sos/rawio.asm"	; Apple II-like I/O stand-in
	.include "sos/conio.asm"	; Console I/O
	.include "print.asm"
	.include "prodos/serial/serproto.asm"
	.include "sos/online.asm"
	.include "sos/rw.asm"
	.include "sr.asm"
	.include "prodos/serial/ssc.asm"
	.include "sos/serial/iiiacia.asm"
	.include "prodos/serial/timer.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "sos/serial/serconfigsos.asm"
	.include "hostfns.asm"
	.include "sos/format.asm"			; Note: includes FORMAT segment
	.include "bsave.asm"

; From Nibble code:
; Note: we could use all of the Disk II functions if we resolve the BIGBUF references 
; in diskii.asm, specifically ADR_TRK.  Also, there are some page boundary requirements
; that would have to be respected. 
motoron:
motoroff:
INIT_DISKII:
GO_TRACK0:
sendnib:
	rts
; Stubs:
ROM:
;BSAVE:
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
