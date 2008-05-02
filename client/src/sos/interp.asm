;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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

; Header for SOS interpreter

	.import ASMEND

	.segment "STARTUP"

	.ORG  $2000-14      ; START ADDRESS

	.BYTE $53,$4f,$53,$20,$4e,$54,$52,$50	; "SOS NTRP"
	.ADDR $0000	; No extra header
	.ADDR ASMBEGIN	; Tell 'em where it starts
	.ADDR ASMEND	; Tell 'em where it ends

ASMBEGIN:
	jmp entrypoint	; Start it up!