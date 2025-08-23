;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2015 by David Schmidt
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

.import ip65_init
.import dhcp_init
.import _w5100_name

init_entry:
	ldx #$07		; Start looking for a slot from the top
	stx TEMPSLOT
another:
	dec TEMPSLOT		; Decrement first, as we are zero-indexing
	bmi nonefound
	jsr INITETHERNET
	bcs another		; Not found?  Branch around for another
found:
	lda TEMPSLOT
	clc
	adc #$b0
	sta $0400
	lda _w5100_name+$0a	; Check for Uthernet II (byte 'I')
	cmp #$49
	beq isUthernetII	; Uthernet II detected
	sec
	rts

nonefound:
	lda #$b0
	sta $401
	sec
	rts

isUthernetII:
	sta $402
	; Load up the W5100 driver (handled by uthernet2.s)
	clc
	rts

;---------------------------------------------------------
; INITETHERNET - Attempt to initialize the Ethernet card in TEMPSLOT
; Returns with carry clear on success, carry set on failure
;---------------------------------------------------------
INITETHERNET:
	GO_SLOW			; Slow down for SOS
	ldx TEMPSLOT
	inx
	txa			; Slot number (1-7) in A for ip65_init
	jsr ip65_init
	bcc @UTHEROK
	GO_FAST			; Speed back up for SOS
	sec
	rts
@UTHEROK:
	jsr dhcp_init
	bcc @UTHEROK2
	GO_FAST			; Speed back up for SOS
	sec
	rts
@UTHEROK2:
	GO_FAST			; Speed back up for SOS
	lda TEMPSLOT
	sta COMMSLOT
	clc
	rts

TEMPSLOT:
	.res 1
