;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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
	.include "online.asm"
	.include "rw.asm"
	.include "sr.asm"
	.include "ethernet/uther.asm"
	.include "crc.asm"
	.include "pickvol.asm"
	.include "input.asm"
	.include "ethernet/ethconfig.asm"
	.include "hostfns.asm"
	.include "ethernet/ethbsave.asm"
	.include "ethernet/ethproto.asm"
	.include "ethernet/ipconfig.asm"
	