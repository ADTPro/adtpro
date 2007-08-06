;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 by David Schmidt
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

	.include "main.asm"

;---------------------------------------------------------
; Pull in all the rest of the code
;---------------------------------------------------------
	.include "vars.asm"
	.include "print.asm"
	.include "audio/audproto.asm"
	.include "online.asm"
	.include "rw.asm"
	.include "audio/sr.asm"
	.include "audio/audio.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "audio/audconfig.asm"
	.include "hostfns.asm"
	.include "diskii.asm"
	.include "nibble.asm"
	.include "bsave.asm"
	.include "format.asm"

PEND:
	.segment "DATA"
