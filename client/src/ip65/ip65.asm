; ip65 main routines

;	.include "common.i"


;	.export ip65_init
;	.export ip65_process
;
;	.export ip65_ctr
;	.export ip65_ctr_arp
;	.export ip65_ctr_ip

;	.import eth_init
;	.import timer_init
;	.import arp_init
;	.import ip_init
;
;	.import eth_inp
;	.import eth_rx
;
;	.import ip_process
;	.import arp_process
;
;	.importzp eth_proto_arp


;	.bss

ip65_ctr:	.res 1		; incremented for every incoming packet
ip65_ctr_arp:	.res 1		; incremented for every incoming arp packet
ip65_ctr_ip:	.res 1		; incremented for every incoming ip packet


;	.code

; initialize stack
ip65_init:
	jsr eth_init		; initialize ethernet driver
	bcs @fail
	jsr timer_init		; initialize timer
	jsr arp_init		; initialize arp
	jsr ip_init		; initialize ip, icmp, udp, and tcp
	clc
@fail:
	rts


; maintenance routine
; polls for packets, and dispatches to listeners
ip65_process:
	jsr eth_rx		; check for incoming packets
	bcs @done

	lda eth_inp + 12	; type should be 08xx
	cmp #8
	bne @done

	lda eth_inp + 13
;	cmp #eth_proto_ip	; ip = 00
	beq @ip
	cmp #eth_proto_arp	; arp = 06
	beq @arp
@done:
	rts

@arp:
	inc ip65_ctr_arp
	jmp arp_process

@ip:
	inc ip65_ctr_ip
	jmp ip_process
