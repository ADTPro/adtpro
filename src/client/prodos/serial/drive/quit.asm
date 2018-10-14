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
	lda $3f2	; Where does our reset vector point?
	bne @Quit	; Not BASIC
	lda $3f3
	cmp #$be
	bne @Quit	; Not BASIC
	rts		; Yay - BASIC!

@Quit:			; Return to ProDOS
	CALLOS OS_QUIT, QUIT_PARMS

; Parameters for quit

QUIT_PARMS:	.byte 4
		.addr 0		; six bytes of zeroes follow
		.addr 0
		.addr 0

