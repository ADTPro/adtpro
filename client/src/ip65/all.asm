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

; The include order here is kind of important as the assembler doesn't
; like redefinitions of imports.
	.include "ip65/cs8900a.i"
	.include "ip65/arp.asm"
	.include "ip65/config.asm"
	.include "ip65/copymem.asm"
	.include "ip65/cs8900a.asm"
	.include "ip65/eth.asm"
	.include "ip65/icmp.asm"
	.include "ip65/ip.asm"
	.include "ip65/ip65.asm"
	.include "ip65/tfe.asm"
	.include "ip65/timer.asm"
	.include "ip65/udp.asm"