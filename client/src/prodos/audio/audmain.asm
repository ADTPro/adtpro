;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2008 by David Schmidt
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

	.include "prodos/interp.asm"			; Interpreter header
	.include "prodos/prodosmacros.i"		; OS macros
	.include "prodos/prodosconst.i"			; OS equates, characters, etc.
	.include "prodos/prodosvars.asm"
	.include "prodos/serial/sermessages.asm"	; Messages
	.include "ip65/common.i"
	.include "main.asm"

;---------------------------------------------------------
; Pull in all the rest of the code
;---------------------------------------------------------
	.include "prodos/conio.asm"		; Console I/O
	.include "print.asm"
	.include "prodos/audio/audproto.asm"
	.include "prodos/online.asm"
	.include "rw.asm"
	.include "sr.asm"
	.include "prodos/audio/audio.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "prodos/audio/audconfig.asm"
	.include "hostfns.asm"
	.include "diskii.asm"
	.include "nibble.asm"
	.include "format.asm"
	.include "prodos/bsave.asm"

PEND:
	.segment "DATA"
