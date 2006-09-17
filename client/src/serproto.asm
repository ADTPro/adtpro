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

;---------------------------------------------------------
; DIRREQUEST - Request current directory contents
;---------------------------------------------------------
DIRREQUEST:
	lda #CHR_D	; Send "DIR" command to PC
	jsr PUTC
	rts

;---------------------------------------------------------
; DIRREPLY - Reply to current directory contents
;---------------------------------------------------------
DIRREPLY:
	jsr GETC	; Get character from serial port
	php		; Save flags
	sta (BLKPTR),Y	; Store byte
	iny		; Bump counter
	bne DIRNEXT	; Skip
	inc <BLKPTR+1	; Next 256 bytes
DIRNEXT:
	plp		; Restore flags
	bne DIRREPLY	; Loop until zero

	jsr GETC	; Get continuation character
	sta (BLKPTR),Y 	; Store continuation byte too

;---------------------------------------------------------
; DIRABORT - Abort current directory contents
;---------------------------------------------------------
DIRABORT:
	lda #$00
	jmp PUTC	; ESCAPE, SEND 00 AND RETURN
	rts

;---------------------------------------------------------
; CDREQUEST - Request current directory change
;---------------------------------------------------------
CDREQUEST:
	lda #CHR_C	; Ask host to Change Directory
	jsr PUTC
	jsr SENDFN	; Send directory name
	rts

;---------------------------------------------------------
; CDREPLY - Reply to current directory change
;---------------------------------------------------------
CDREPLY:
	jsr GETC	; Get response from host
	rts

