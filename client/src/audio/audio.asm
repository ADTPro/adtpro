;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 by David Schmidt
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

;---------------------------------------------------------
; INITAUDIO - Initialize audio processing
;---------------------------------------------------------
INITAUDIO:
	jsr PATCHAUDIO
	rts

;---------------------------------------------------------
; AUDIOPUT - Send accumulator out the cassette port
;---------------------------------------------------------
AUDIOPUT:
	rts


;---------------------------------------------------------
; AUDIOGET - Get a character from Super Serial Card (XY unchanged)
;---------------------------------------------------------
AUDIOGET:
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	bne AUDIOGETNEXT
	jmp PABORT

AUDIOGETNEXT:
			; Get character
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
	;lda #<AUDIOPUT
	;sta PUTC+1
	;lda #>AUDIOPUT
	;sta PUTC+2

	;lda #<AUDIOGET
	;sta GETC+1
	;lda #>AUDIOGET
	;sta GETC+2

	lda #<RESETAUDIO
	sta RESETIO+1
	lda #>RESETAUDIO
	sta RESETIO+2

	rts
