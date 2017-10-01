;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2012 by David Schmidt
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
	.include "ip65/inc/common.i"
	.include "diskii.asm"				; Contains positionally dependent format code

;---------------------------------------------------------
; Pull in all the rest of the code
;---------------------------------------------------------
	.include "main.asm"
	.include "about.asm"
	.include "prodos/prodosvars.asm"		; Variables
	.include "prodos/serial/sermessages.asm"	; Messages
	.include "prodos/conio.asm"		; Console I/O
	.include "print.asm"
	.include "prodos/serial/serproto.asm"
	.include "prodos/online.asm"
	.include "prodos/rw.asm"
	.include "sr.asm"
	.include "prodos/serial/findslot.asm"
	.include "prodos/serial/ssc.asm"
	.include "prodos/serial/iigsscc.asm"
	.include "prodos/serial/timer.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "prodos/serial/serconfigpro.asm"
	.include "hostfns.asm"
	.include "nibble.asm"
	.include "prodos/serial/pascalep.asm"	; Note: includes PASCALEP segment
	.include "prodos/format.asm"		; Note: includes FORMAT segment
	.include "bsave.asm"

	.segment "DATA"
	