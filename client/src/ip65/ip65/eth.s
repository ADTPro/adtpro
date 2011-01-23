; Common ethernet driver code (independant of host computer or ethernet chipset)

.include "../inc/common.i"

	.export eth_set_broadcast_dest
	.export eth_set_my_mac_src
	.export eth_set_proto

	.exportzp eth_proto_ip
	.exportzp eth_proto_arp
	.exportzp eth_dest
	.exportzp eth_src
	.exportzp eth_type
	.exportzp eth_data
	.exportzp eth_packet

	.export eth_outp
	.export eth_outp_len
	.export eth_inp
	.export eth_inp_len

	.import cfg_mac

	.segment "IP65ZP" : zeropage

eth_packet:	.res 2		; Packet pointer

	.bss

; input and output buffers
eth_inp_len:	.res 2		; input packet length
eth_inp:	.res 1518	; space for input packet
eth_outp_len:	.res 2		; output packet length
eth_outp:	.res 1518	; space for output packet



; ethernet packet offsets
eth_dest	= 0		; offset of destination address in ethernet packet
eth_src		= 6		; offset of source address in ethernet packet
eth_type	= 12		; offset of packet type in ethernet packet
eth_data	= 14		; offset of packet data in ethernet packet

; protocols

eth_proto_ip	= 0
eth_proto_arp	= 6

	.code
;set the destination address in the packet under construction to be the ethernet
;broadcast address (FF:FF:FF:FF:FF:FF)
;inputs:
; eth_outp: buffer in which outbound ethernet packet is being constructed
;outputs: none
eth_set_broadcast_dest:
	ldx #5
	lda #$ff
:	sta eth_outp,x
	dex
	bpl :-
	rts

;set the source address in the packet under construction to be local mac address
;inputs:
; eth_outp: buffer in which outbound ethernet packet is being constructed
;outputs: none
eth_set_my_mac_src:
	ldx #5
:	lda cfg_mac,x
	sta eth_outp + 6,x
	dex
	bpl :-
	rts

;set the 'protocol' field in the packet under construction
;inputs: 
;   A = protocol number (per 'eth_proto_*' constants)
;outputs: none
eth_set_proto:
	sta eth_outp + eth_type + 1
	lda #8
	sta eth_outp + eth_type
	rts



;-- LICENSE FOR eth.s --
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
