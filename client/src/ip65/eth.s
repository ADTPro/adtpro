; Common ethernet driver code


	.include "common.i"


	.export eth_set_broadcast_dest
	.export eth_set_my_mac_src
	.export eth_set_proto

	.export eth_inp_len	; input packet length
	.export eth_inp		; space for input packet
	.export eth_outp_len	; output packet length
	.export eth_outp	; space for output packet

	.export eth_dest	; destination address
	.export eth_src		; source address
	.export eth_type	; packet type
	.export eth_data	; packet data

	.exportzp eth_packet
	.exportzp eth_proto_ip
	.exportzp eth_proto_arp

	.import cfg_mac


; ethernet packet offsets
eth_dest	= 0		; destination address
eth_src		= 6		; source address
eth_type	= 12		; packet type
eth_data	= 14		; packet data

; protocols
eth_proto_ip	= 0
eth_proto_arp	= 6

	.segment "IP65ZP" : zeropage

eth_packet:	.res 2		; Packet pointer

	.bss

; input and output buffers
eth_inp_len:	.res 2		; input packet length
eth_inp:	.res 1518	; space for input packet
eth_outp_len:	.res 2		; output packet length
eth_outp:	.res 1518	; space for output packet

	.code

eth_set_broadcast_dest:
	ldx #5
	lda #$ff
:	sta eth_outp,x
	dex
	bpl :-
	rts


eth_set_my_mac_src:
	ldx #5
:	lda cfg_mac,x
	sta eth_outp + 6,x
	dex
	bpl :-
	rts


eth_set_proto:
	sta eth_outp + eth_type + 1
	lda #8
	sta eth_outp + eth_type
	rts
