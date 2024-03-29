;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2015 by David Schmidt
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
; Virtual drive over ethernet based on ideas by Terence J. Boldt

	.include "prodos/prodosmacros.i"		; OS macros
	.include "prodos/prodosconst.i"			; OS equates, characters, etc.
	.include "../../build/lib/ip65/inc/common.inc"

.segment "INSTALL"
	.include "prodos/ethernet/drive/vedriveinstall.asm"
	.include "prodos/serial/drive/quit.asm"

asm_begin:
.segment "CODE"
.org $7600
	.include "prodos/vdrive.asm"
	.include "prodos/ethernet/drive/vedrivemain.asm"
	.include "prodos/ethernet/drive/ethproto.asm"
	.include "prodos/ethernet/uther.asm"
