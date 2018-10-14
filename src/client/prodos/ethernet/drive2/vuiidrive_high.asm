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
; Virtual drive over Ethernet based on ideas by Terence J. Boldt

	.include "prodos/prodosmacros.i"		; OS macros
	.include "prodos/prodosconst.i"			; OS equates, characters, etc.
	.include "ip65/inc/common.i"
	.include "prodos/ethernet/drive2/w5100const.i"

.segment "INSTALLER"
.org $2000
	.include "prodos/ethernet/drive2/vuiidriveinstall_high.asm"
	.include "prodos/ethernet/drive2/w5100init.asm"
	.include "prodos/ethernet/drive2/initheavystack.asm"
	.include "prodos/ethernet/drive2/vuiidrivevars.asm"

driver_reloc:
.org $D000
driver_begin:
	.include "prodos/vdrive.asm"
	.include "prodos/ethernet/drive2/vuiidriveio.asm"
	.include "prodos/ethernet/drive2/w5100io.asm"
driver_end:
; The rest of the IP65 lib will fall after this