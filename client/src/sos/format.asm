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

	.segment "FORMAT"

FormatEntry:
	ldx #$00
	ldy #$15
	jsr GOTOXY
	lda #NO_FORMAT_MESSAGE_END-NO_FORMAT_MESSAGE
	sta WRITE_LEN
	lda #<NO_FORMAT_MESSAGE
	sta UTILPTR
	lda #>NO_FORMAT_MESSAGE
	sta UTILPTR+1
	jsr WRITEMSG_RAW
	jsr PAUSE
	rts
	
NO_FORMAT_MESSAGE:	asc "SORRY, FORMAT NOT SUPPORTED ON SOS."
NO_FORMAT_MESSAGE_END:

; Some things that main.asm expects to see as part of the normal format:
Died:
Done:
SlotF:
	.byte 00