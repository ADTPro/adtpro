;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 by David Schmidt
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
; Virtual drive over ethernet based on ideas by Terence J. Boldt

	.include "prodos/prodosmacros.i"		; OS macros
	.include "prodos/prodosconst.i"			; OS equates, characters, etc.
	.include "ip65/inc/common.i"

.segment "INSTALL"
	.include "prodos/ethernet/drive/vedriveinstall.asm"

asm_begin:
.segment "CODE"
.org $7800
	.include "prodos/vdrive.asm"
	.include "prodos/ethernet/drive/vedrivemain.asm"
	.include "prodos/ethernet/drive/ethproto.asm"
	.include "prodos/ethernet/uther.asm"