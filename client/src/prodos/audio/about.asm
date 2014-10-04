;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2014 by David Schmidt
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

; Audio 'about' message - send out test 'home' messages to the server for
; audio level debug
ABOUT:
	lda #$15
	jsr TABV
	ldy #PMSG17	; "About" message
	jsr WRITEMSGLEFT

LEVEL_SEND:
	ldax #AUD_BUFFER
	stax UTILPTR
	stax A1L
	stax A2L	; Set everyone up to talk to the AUD_BUFFER

; Sending beacon

	lda #CHR_A	; Envelope
	jsr BUFBYTE
	lda #$00	; Zero byte payload
	jsr BUFBYTE
	jsr BUFBYTE
	lda #CHR_X	; Go Home
	jsr BUFBYTE
	lda #$19	; Pre-calculted check byte
	jsr BUFBYTE

	ldax UTILPTR
	stax A2L
	jsr aud_send
	ldx #$03
:	lda #$ff
	jsr DELAY
	lda $C000
	bmi ADONE
	dex
	bne :-
	lda $C000
	bpl LEVEL_SEND

ADONE:	rts