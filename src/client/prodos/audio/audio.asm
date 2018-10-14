;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2014 by David Schmidt
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

;---------------------------------------------------------
; INITAUDIO - Initialize audio processing
;---------------------------------------------------------
INITAUDIO:
	jsr PATCHAUDIO
	rts

;---------------------------------------------------------
; RESETAUDIO - Clean up
;---------------------------------------------------------
RESETAUDIO:
	rts

;---------------------------------------------------------
; PATCHAUDIO - Patch the entry points of SSC processing
;---------------------------------------------------------
PATCHAUDIO:
	lda #<RESETAUDIO
	sta RESETIO+1
	lda #>RESETAUDIO
	sta RESETIO+2
	rts
