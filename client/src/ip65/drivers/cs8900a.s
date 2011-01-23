; Ethernet driver for CS8900A chip (as used in RR-NET and Uthernet adapters)
;
; Based on Doc Bacardi's tftp source


.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"
.include "cs8900a.i"

	.export uth_init
	.export uth_rx
	.export uth_tx

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.import fix_eth_tx_00	; from ip.s
	.import fix_eth_tx_01	; from icmp.s
	.import fix_eth_tx_02	; from arp.s
	.import fix_eth_tx_03	; from arp.s

	.import fix_eth_rx_00	; from ip65.s

	.importzp eth_dest
	.importzp eth_src
	.importzp eth_type
	.importzp eth_data
	.importzp eth_packet

	.import cs_init
	.import cs_packet_page
	.import cs_packet_data
	.import cs_rxtx_data
	.import cs_tx_cmd
	.import cs_tx_len

	.import ip65_error

	.import cfg_mac
	.import COMMSLOT

	.macro write_page page, value
	lda #page/2
	ldx #<value
	ldy #>value
	jsr cs_write_page
	.endmacro

	.code

;initialize the Ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise
uth_init:
;	jsr cs_init
	jsr cs_self_modify

	lda #0			; check magic signature
	jsr cs_read_page
	cpx #$0e
	bne @notfound
	cpy #$63
	bne @notfound

	lda #1
	jsr cs_read_page
	cpx #0
	bne @notfound
	; y contains chip rev

	write_page pp_self_ctl, $0055	; $0114, reset chip

	write_page pp_rx_ctl, $0d05	; $0104, accept individual and broadcast packets

	lda #pp_ia/2			; $0158, write mac address
	ldx cfg_mac
	ldy cfg_mac + 1
	jsr cs_write_page

	lda #pp_ia/2 + 1
	ldx cfg_mac + 2
	ldy cfg_mac + 3
	jsr cs_write_page

	lda #pp_ia/2 + 2
	ldx cfg_mac + 4
	ldy cfg_mac + 5
	jsr cs_write_page

	write_page pp_line_ctl, $00d3	; $0112, enable rx and tx

	clc
	rts

@notfound:
	sec
	rts


;receive a packet
;inputs: none
;outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear, 
; eth_inp contains the received packet, 
; and eth_inp_len contains the length of the packet
uth_rx:
	lda #$24			; check rx status
EMOD30:	sta cs_packet_page
	lda #$01
EMOD34:	sta cs_packet_page + 1

EMOD43:	lda cs_packet_data + 1
	and #$0d
	bne EMOD6

	sec				; no packet ready
	rts

EMOD6:	lda cs_rxtx_data + 1		; ignore status
EMOD0:	lda cs_rxtx_data

EMOD7:	lda cs_rxtx_data + 1		; read packet length
	sta eth_inp_len + 1
	tax				; save
EMOD1:	lda cs_rxtx_data
	sta eth_inp_len

	lda #<eth_inp			; set packet pointer
	sta eth_packet
	lda #>eth_inp
	sta eth_packet + 1

	ldy #0
	cpx #0				; < 256 bytes left?
	beq cs_tail1

cs_get256:
EMOD2:	lda cs_rxtx_data
	sta (eth_packet),y
	iny
EMOD8:	lda cs_rxtx_data + 1
	sta (eth_packet),y
	iny
	bne cs_get256
	inc eth_packet + 1
	dex
	bne cs_get256

cs_tail1:
	lda eth_inp_len			; bytes left / 2, round up
	lsr
	adc #0
	beq cs_done1
	tax

cs_get:
EMOD3:	lda cs_rxtx_data
	sta (eth_packet),y
	iny
EMOD9:	lda cs_rxtx_data + 1
	sta (eth_packet),y
	iny
	dex
	bne cs_get

cs_done1:
	clc
	rts


; send a packet
;inputs:
; eth_outp: packet to send
; eth_outp_len: length of packet to send
;outputs:
; if there was an error sending the packet then carry flag is set
; otherwise carry flag is cleared
uth_tx:
	
	lda #$c9			; ask for buffer space
EMOD10:	sta cs_tx_cmd
	lda #0
EMOD11:	sta cs_tx_cmd + 1

	lda eth_outp_len		; set length
EMOD20:	sta cs_tx_len
	lda eth_outp_len + 1
EMOD21:	sta cs_tx_len + 1
	cmp #6
  bmi :+
  lda #KPR_ERROR_INPUT_TOO_LARGE
  sta ip65_error
	sec				; oversized packet
	rts

:	lda #<pp_bus_status		; select bus status register
EMOD31:	sta cs_packet_page
	lda #>pp_bus_status
EMOD35:	sta cs_packet_page + 1

waitspace:
EMOD44:	lda cs_packet_data + 1		; wait for space
EMOD40:	ldx cs_packet_data
	lsr
	bcs @gotspace
	jsr cs_done2			; polling too fast doesn't work, delay some
	jmp waitspace
@gotspace:
	ldax #eth_outp			; send packet
	stax eth_packet

	ldy #0
	ldx eth_outp_len + 1
	beq cs_tail2

cs_send256:
	lda (eth_packet),y
EMOD4:	sta cs_rxtx_data
	iny
	lda (eth_packet),y
EMODA:	sta cs_rxtx_data + 1
	iny
	bne cs_send256
	inc eth_packet + 1	; DLS
	dex
	bne cs_send256

cs_tail2:
	ldx eth_outp_len
	beq cs_done2

cs_send:
	lda (eth_packet),y
EMOD5:	sta cs_rxtx_data
	dex
	beq cs_done2
	iny
	lda (eth_packet),y
EMODB:	sta cs_rxtx_data + 1
	iny
	dex
	bne cs_send

cs_done2:
	clc
	rts


; read X/Y from page A * 2
cs_read_page:
	asl
EMOD32:	sta cs_packet_page
	lda #0
	rol
EMOD36:	sta cs_packet_page + 1
EMOD41:	ldx cs_packet_data
EMOD45:	ldy cs_packet_data + 1
	rts

; write X/Y to page A * 2
cs_write_page:
	asl
EMOD33:	sta cs_packet_page
	lda #0
	rol
EMOD37:	sta cs_packet_page + 1
EMOD42:	stx cs_packet_data
EMOD46:	sty cs_packet_data + 1
	rts

;
; cs_self_modify - make all entry points variable so we can move the
;   uther card around in the Apple
;
cs_self_modify:

	ldax #uth_tx		; Fixup transmit addresses
	sta fix_eth_tx_00 +1
	stx fix_eth_tx_00 +2
	sta fix_eth_tx_01 +1
	stx fix_eth_tx_01 +2
	sta fix_eth_tx_02 +1
	stx fix_eth_tx_02 +2
	sta fix_eth_tx_03 +1
	stx fix_eth_tx_03 +2

	ldax #uth_rx		; Fixup receive addresses
	sta fix_eth_rx_00 + 1
	stx fix_eth_rx_00 + 2

	ldy COMMSLOT	; GET SLOT# (0..6)
	iny		; NOW 1..7
	tya
	asl
	asl
	asl
	asl
	clc
	adc #$80	; Now $80+S0 ($c0b0)
	; Make the accumulator contain slot number plus $80
	;   i.e. Slot 1 = $90
	;   i.e. Slot 2 = $A0
	;   i.e. Slot 3 = $B0
	;   i.e. Slot 4 = $C0
	;   i.e. Slot 5 = $D0
	;   i.e. Slot 6 = $E0
	;   i.e. Slot 7 = $F0
; Save off all cs_rxtx_data mods
	sta EMOD0+1
	sta EMOD1+1
	sta EMOD2+1
	sta EMOD3+1
	sta EMOD4+1
	sta EMOD5+1
	clc
	adc #$01	; $c0b1
	sta EMOD6+1
	sta EMOD7+1
	sta EMOD8+1
	sta EMOD9+1
	sta EMODA+1
	sta EMODB+1
; save off all cs_tx_cmd mods
	clc
	adc #$03	; $c0b4
	sta EMOD10+1
	clc
	adc #$01	; $c0b5
	sta EMOD11+1
; save off all cs_tx_len mods
	clc
	adc #$01	; $c0b6
	sta EMOD20+1
	clc
	adc #$01	; $c0b7
	sta EMOD21+1
; save off all cs_packet_page mods
	clc
	adc #$03	; $c0ba
	sta EMOD30+1
	sta EMOD31+1
	sta EMOD32+1
	sta EMOD33+1
	clc
	adc #$01	; $c0bb
	sta EMOD34+1
	sta EMOD35+1
	sta EMOD36+1
	sta EMOD37+1
; save off all cs_packet_data mods
	clc
	adc #$01	; $c0bc
	sta EMOD40+1
	sta EMOD41+1
	sta EMOD42+1
	clc
	adc #$01	; $c0bd
	sta EMOD43+1
	sta EMOD44+1
	sta EMOD45+1
	sta EMOD46+1

; Copy over the mac
	ldx #$03
:	lda uth_mac,x
	sta cfg_mac+2,x
	dex
	bpl :-

	rts

uth_mac:
	.byte $10, $6d, $76, $30

;-- LICENSE FOR cs8900a.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Per Olofsson,
; MagerValp@gmail.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Per Olofsson. All Rights Reserved.  
; -- LICENSE END --
