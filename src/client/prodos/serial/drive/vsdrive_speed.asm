;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2013 by David Schmidt
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
; Virtual drive over the serial port based on ideas by Terence J. Boldt

	.include "prodos/prodosmacros.i"		; OS macros
	.include "prodos/prodosconst.i"			; OS equates, characters, etc.

	.include "prodos/serial/drive/vsdriveinstall_high.asm"
	jmp $7000					; When done, head back to the bootstrapper
	.include "prodos/serial/findslot.asm"

asm_begin:
.segment "DRIVER"
.org $d000
	.include "prodos/vdrive.asm"
	.include "prodos/serial/drive/vsdrivemain.asm"
	.include "prodos/serial/iigsscc.asm"
	.include "prodos/serial/ssc.asm"
	.include "prodos/serial/timer.asm"
