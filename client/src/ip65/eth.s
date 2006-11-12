; Common ethernet driver code


	.include "common.i"


	.export eth_set_broadcast_dest
	.export eth_set_my_mac_src
	.export eth_set_proto

	.exportzp eth_proto_ip
	.exportzp eth_proto_arp

	.import eth_outp

	.import cfg_mac


; ethernet packet offsets
eth_dest	= 0		; destination address
eth_src		= 6		; source address
eth_type	= 12		; packet type
eth_data	= 14		; packet data

; protocols
eth_proto_ip	= 0
eth_proto_arp	= 6


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
