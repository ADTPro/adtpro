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

; Serial bootstrapper grub
;
; After learning enough information about the serial hardware, put up a 
; message and start listening on our best-guess port for data.

	.include "grub_vsdrive_main.asm"
	.include "../findslot.asm"
	.include "../iigsscc.asm"
	.include "../ssc.asm"
	.include "../timer.asm"