;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2010 by David Schmidt
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

	.segment "STARTUP"
	.org $0800	; After relocation, this orgs at $0800 

ASMBEGIN:

;---------------------------------------------------------
; Kill the reset vector
;---------------------------------------------------------
	lda #$69		; Vector reset to the monitor
	sta $03f2
	lda #$ff
	sta $03f3	; $ff69, aka CALL -151
	eor #$a5
	sta $03f4	; Fixup powerup byte
	
	jmp entrypoint