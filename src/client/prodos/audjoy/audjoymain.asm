;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2023 by David Schmidt
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

	.include "prodos/interp.asm"			; Interpreter header
	.include "prodos/prodosmacros.i"		; OS macros
	.include "prodos/prodosconst.i"			; OS equates, characters, etc.
	.include "../../build/lib/ip65/inc/common.inc"
	.include "diskii.asm"					; Contains positionally dependent format code

;---------------------------------------------------------
; Pull in all the rest of the code
;---------------------------------------------------------
	.include "main.asm"
	.include "prodos/audjoy/about.asm"		; Test tone generation in addition to 'about' message
	.include "prodos/prodosvars.asm"		; Variables
	.include "prodos/serial/sermessages.asm"	; Messages
	.include "prodos/conio.asm"		; Console I/O
	.include "print.asm"
	.include "prodos/audjoy/audjoyproto.asm"
	.include "prodos/online.asm"
	.include "prodos/rw.asm"
	.include "sr.asm"
	.include "prodos/audjoy/audjoy.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "prodos/audjoy/audjoyconfig.asm"
	.include "hostfns.asm"
	.include "prodos/format.asm"
	.include "bsave.asm"

; Stubs from nibble-related stuff
ReceiveNib:
sendnib:
	rts

PEND:
	.segment "DATA"
