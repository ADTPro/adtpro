; ARP address resolution


	.include "common.i"


	.export arp_init
	.export arp_lookup
	.export arp_process
	.export arp_add

	.export arp_ip
	.export arp_mac
	.export arp_cache

	.export fix_eth_tx_00
	.export fix_eth_tx_01

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len
	.import eth_set_broadcast_dest
	.import eth_set_my_mac_src
	.import eth_set_proto
	.importzp eth_proto_arp

	.import cfg_mac
	.import cfg_ip
	.import cfg_netmask
	.import cfg_gateway

	.import timer_read
	.import timer_timeout


	.segment "IP65ZP" : zeropage

ap:		.res 2


	.bss

; arp state machine
arp_idle	= 1		; idling
arp_wait	= 2		; waiting for reply
arp_state:	.res 1		; current activity

; arguments for lookup and add 
arp:				; ptr to mac/ip pair
arp_mac:	.res 6		; result is delivered here
arp_ip:		.res 4		; set ip before calling lookup

; arp cache
ac_size		= 8		; lookup cache
ac_ip		= 6  		; offset for ip
ac_mac		= 0		; offset for mac
arp_cache:	.res (6+4)*ac_size

; offsets for arp packet generation
ap_hw		= 14		; hw type (eth = 0001)
ap_proto	= 16		; protocol (ip = 0800)
ap_hwlen	= 18		; hw addr len (eth = 06)
ap_protolen	= 19		; proto addr len (ip = 04)
ap_op		= 20		; request = 0001, reply = 0002
ap_shw		= 22		; sender hw addr
ap_sp		= 28		; sender proto addr
ap_thw		= 32		; target hw addr
ap_tp		= 38		; target protoaddr
ap_packlen	= 42		; total length of packet

; gateway handling
gw_mask:	.res 4		; inverted netmask
gw_test:	.res 4		; gateway ip or:d with inverted netmask
gw_last:	.res 1		; netmask length - 1

; timeout
arptimeout:	.res 2		; time when we will have timed out


	.code

; initialize arp
arp_init:
	lda #0

	ldx #(6+4)*ac_size - 1	; clear cache
:	sta arp_cache,x
	dex
	bpl :-

	lda #$ff		; counter for netmask length - 1
	sta gw_last

	ldx #3
@gw:
	lda cfg_netmask,x
	eor #$ff
	cmp #$ff
	bne :+
	inc gw_last
:	sta gw_mask,x
	ora cfg_gateway,x
	sta gw_test,x
	dex
	bpl @gw

	lda #arp_idle		; start out idle
	sta arp_state

	rts


; lookup an ip
; clc = mac returned in ap_mac
; sec = request sent, call again for result
arp_lookup:
	ldx gw_last		; check if address is on our subnet
:	lda arp_ip,x
	ora gw_mask,x
	cmp gw_test,x
	bne @notlocal
	dex
	bpl :-
	bmi @local

@notlocal:
	ldx #3			; copy gateway's ip address
:	lda cfg_gateway,x
	sta arp_ip,x
	dex
	bpl :-

@local:
	jsr findip
	bcs @cachemiss

	ldy #ac_ip - 1		; copy mac
:	lda (ap),y
	sta arp,y
	dey
	bpl :-
	rts

@cachemiss:
	lda arp_state		; are we already waiting for a reply?
	cmp #arp_idle
	beq @sendrequest	; yes, send request

	ldax arptimeout		; check if we've timed out
	jsr timer_timeout
	bcs al_notimeout		; no, don't send

@sendrequest:			; send out arp request
	jsr eth_set_broadcast_dest
	jsr eth_set_my_mac_src

	jsr makearppacket	; add arp, eth, ip, hwlen, protolen

	lda #0			; set opcode (request = 0001)
	sta eth_outp + ap_op
	lda #1
	sta eth_outp + ap_op + 1

	ldx #5
:	lda cfg_mac,x		; set source mac addr
	sta eth_outp + ap_shw,x
	lda #0			; set target mac addr
	sta eth_outp + ap_thw,x
	dex
	bpl :-

	ldx #3
:	lda cfg_ip,x		; set source ip addr
	sta eth_outp + ap_sp,x
	lda arp_ip,x		; set target ip addr
	sta eth_outp + ap_tp,x
	dex
	bpl :-

	lda #<ap_packlen	; set packet length
	sta eth_outp_len
	lda #>ap_packlen
	sta eth_outp_len + 1

fix_eth_tx_00:
	jsr $0000		; send packet

	lda #arp_wait		; waiting for reply
	sta arp_state

	jsr timer_read		; read current timer value
	clc
	adc #<1000		; set timeout to now + 1000 ms
	sta arptimeout
	txa
	adc #>1000
	sta arptimeout + 1

al_notimeout:
	sec 			; set carry to indicate that
	rts			; no result is availble


; find arp_ip in the cache
; clc returns pointer to entry in (ap)
findip:
	ldax #arp_cache
	stax ap

	ldx #ac_size
@compare:			; compare cache entry
	ldy #ac_ip
	lda (ap),y
	beq @notfound
:	lda (ap),y
	cmp arp,y
	bne @next
	iny
	cpy #ac_ip + 4
	bne :-

	clc			; return
	rts

@next:				; next entry
	lda ap
	clc
	adc #10
	sta ap
	bcc :+
	inc ap + 1
:	dex
	bne @compare

@notfound:
	sec
	rts


; handle incoming arp packets
arp_process:

	lda eth_inp + ap_op	; should be 0
	bne ap_badpacket
	lda eth_inp + ap_op + 1	; check opcode
	cmp #1			; request?
	beq ap_request
	cmp #2			; reply?
	beq ap_reply

ap_badpacket:
	sec
	rts

ap_request:
	ldx #3
:	lda eth_inp + ap_tp,x	; check if they're asking for
	cmp cfg_ip,x		; my address
	bne ap_done
	dex
	bpl :-

	ldax #eth_inp + ap_shw
	jsr ac_add_source	; add them to arp cache

	ldx #5			; send reply
:	lda eth_inp + ap_shw,x
	sta eth_outp,x		; set sender packet dest
	sta eth_outp + ap_thw,x	; and as target
	lda cfg_mac,x		; me as source
	sta eth_outp + ap_shw,x
	dex
	bpl :-

	jsr eth_set_my_mac_src	; me as packet source

	jsr makearppacket	; add arp, eth, ip, hwlen, protolen

	lda #0			; set opcode (reply = 0002)
	sta eth_outp + ap_op
	lda #2
	sta eth_outp + ap_op + 1

	ldx #3
:	lda eth_inp + ap_sp,x	; sender as target addr
	sta eth_outp + ap_tp,x
	lda cfg_ip,x		; my ip as source addr
	sta eth_outp + ap_sp,x
	dex
	bpl :-

	lda #<ap_packlen	; set packet length
	sta eth_outp_len
	lda #>ap_packlen
	sta eth_outp_len + 1

fix_eth_tx_01:
	jsr $0000		; send packet

ap_done:
	clc
	rts

ap_reply:
	lda arp_state
	cmp #arp_wait		; are we waiting for a reply?
	bne ap_badpacket

	ldax #eth_inp + ap_shw
	jsr ac_add_source	; add to cache

	lda #arp_idle
	sta arp_state

	rts


; add arp_mac and arp_ip to the cache
arp_add:
	jsr findip		; check if ip is already in cache
	bcs @add

	ldy #9			; update old entry
:	lda arp,y		; move to top as well?
	sta (ap),y
	dey
	bpl :-
	rts

@add:
	ldax #arp		; add


; add source to cache
ac_add_source:
	stax ap

;	ldx #0
;:	lda addmsg,x
;	beq :+
;	jsr $ffd2
;	inx
;	bne :-
;:

	ldx #9			; make space in the arp cache
:
;	lda arp_cache + 140,x
;	sta arp_cache + 150,x
;	lda arp_cache + 130,x
;	sta arp_cache + 140,x
;	lda arp_cache + 120,x
;	sta arp_cache + 130,x

;	lda arp_cache + 110,x
;	sta arp_cache + 120,x
;	lda arp_cache + 100,x
;	sta arp_cache + 110,x
;	lda arp_cache + 90,x
;	sta arp_cache + 100,x
;	lda arp_cache + 80,x
;	sta arp_cache + 90,x

;	lda arp_cache + 70,x
;	sta arp_cache + 80,x
	lda arp_cache + 60,x
	sta arp_cache + 70,x
	lda arp_cache + 50,x
	sta arp_cache + 60,x
	lda arp_cache + 40,x
	sta arp_cache + 50,x

	lda arp_cache + 30,x
	sta arp_cache + 40,x
	lda arp_cache + 20,x
	sta arp_cache + 30,x
	lda arp_cache + 10,x
	sta arp_cache + 20,x
	lda arp_cache,x
	sta arp_cache + 10,x

	dex
	bpl :-

	ldy #9
:	lda (ap),y		; copy source
	sta arp_cache,y
	dey
	bpl :-

	rts


; adds proto = arp, hw = eth, and proto = ip to outgoing packet
makearppacket:
	lda #eth_proto_arp
	jsr eth_set_proto

	lda #0			; set hw type (eth = 0001)
	sta eth_outp + ap_hw
	lda #1
	sta eth_outp + ap_hw + 1

	lda #8			; set protcol (ip = 0800)
	sta eth_outp + ap_proto
	lda #0
	sta eth_outp + ap_proto + 1

	lda #6			; set hw addr len (eth = 06)
	sta eth_outp + ap_hwlen
	lda #4			; set proto addr len (eth = 04)
	sta eth_outp + ap_protolen

	rts
