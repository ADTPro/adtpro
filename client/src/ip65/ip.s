	.include "common.i"


	;.import dbg_dump_ip_header


	.export ip_init
	.export ip_process
	.export ip_calc_cksum
	.export ip_create_packet
	.export ip_send

	.export ip_inp
	.export ip_outp
	.export ip_broadcast
	.exportzp ip_cksum_ptr
	.exportzp ip_ver_ihl
	.exportzp ip_tos
	.exportzp ip_len
	.exportzp ip_id
	.exportzp ip_frag
	.exportzp ip_ttl
	.exportzp ip_proto
	.exportzp ip_header_cksum
	.exportzp ip_src
	.exportzp ip_dest
	.exportzp ip_data

	.exportzp ip_proto_icmp
	.exportzp ip_proto_tcp
	.exportzp ip_proto_udp


	.import cfg_mac
	.import cfg_ip

	.import eth_tx
	.import eth_set_proto
	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.importzp eth_dest
	.importzp eth_src
	.importzp eth_type
	.importzp eth_data
	.importzp eth_proto_ip
	.importzp eth_proto_arp

	.import arp_lookup
	.import arp_mac
	.import arp_ip

	.import icmp_init
	.import icmp_process

	.import udp_init
	.import udp_process

	.importzp copy_src


	.segment "ZP" : zeropage

; checksum
ip_cksum_ptr:	.res 2		; data pointer


	.bss

ip_cksum_len:	.res 2		; length of data

; ip packets start at ethernet packet + 14
ip_inp		= eth_inp + eth_data
ip_outp		= eth_outp + eth_data

; temp storage for size calculation
len:		.res 2

; flag for incoming broadcast packets
ip_broadcast:	.res 1

; ip packet offsets
ip_ver_ihl	= 0
ip_tos		= 1
ip_len		= 2
ip_id		= 4
ip_frag		= 6
ip_ttl		= 8
ip_proto	= 9
ip_header_cksum	= 10
ip_src		= 12
ip_dest		= 16
ip_data		= 20

; ip protocols
ip_proto_icmp	= 1
ip_proto_tcp	= 6
ip_proto_udp	= 17


; temp for calculating checksum
cksum:		.res 3

; bad packet counters
bad_header:	.res 2
bad_addr:	.res 2


	.code

; initialize ip routines
ip_init:
	lda #0
	sta bad_header
	sta bad_header + 1
	sta bad_addr
	sta bad_addr + 1

	jsr icmp_init
	jsr udp_init
;	jsr tcp_init

	rts


; process an incoming packet
ip_process:
	jsr verifyheader		; ver, ihl, len, frag, checksum
	bcc @ok
@badpacket:
	sec
	rts
@ok:
	jsr checkaddr			; make sure it's meant for us
	bcs @badpacket

	lda ip_inp + ip_proto
	cmp #ip_proto_icmp
	bne :+
	jmp icmp_process		; jump to icmp handler
:	cmp #ip_proto_tcp
	bne :+
	jmp tcp_process			; jump to tcp handler
:	cmp #ip_proto_udp
	bne :+
	jmp udp_process			; jump to udp handler
:
tcp_process:
	sec				; unknown protocol
	rts


; verify that header contains what we expect
verifyheader:
	lda ip_inp + ip_ver_ihl		; IPv4 and no IP options
	cmp #$45
	bne @badpacket

;	lda ip_inp + ip_tos		; ignore ToS

	lda ip_inp + ip_len + 1		; ip + 14 bytes ethernet header
	clc
	adc #14
	sta len
	lda ip_inp + ip_len
	adc #0
	sta len + 1

	lda eth_inp_len			; check if advertised length is shorter
	sec				; than actual length
	sbc len
	lda eth_inp_len + 1
	sbc len + 1
	bmi @badpacket

	lda ip_inp + ip_frag		; check for fragmentation
	beq :+
	cmp #$40
	bne @badpacket
:	lda ip_inp + ip_frag + 1
	bne @badpacket

	ldax #ip_inp			; verify checksum
	stax ip_cksum_ptr
	ldax #20
	jsr ip_calc_cksum
	cmp #0
	bne @badpacket
	cpx #0
	bne @badpacket

	clc
	rts
@badpacket:
	inc bad_header
	bne :+
	inc bad_header + 1
:	sec
	rts


; check that this packet was addressed to us
checkaddr:
	lda #0
	sta ip_broadcast
	lda ip_inp + ip_dest		; compare ip address
	cmp cfg_ip
	bne @broadcast
	lda ip_inp + ip_dest + 1
	cmp cfg_ip + 1
	bne @broadcast
	lda ip_inp + ip_dest + 2
	cmp cfg_ip + 2
	bne @broadcast
	lda ip_inp + ip_dest + 3
	cmp cfg_ip + 3
	bne @broadcast
@ok:	clc
	rts
@broadcast:
	inc ip_broadcast
	lda ip_inp + ip_dest		; check for broadcast
	and ip_inp + ip_dest + 1
	and ip_inp + ip_dest + 2
	and ip_inp + ip_dest + 3
	cmp #$ff
	beq @ok
	inc bad_addr
	bne :+
	inc bad_addr + 1
:	sec
	rts


; create a packet template
ip_create_packet:
	lda #$45			; set IP version and header length
	sta ip_outp + ip_ver_ihl

	lda #0				; set type of service
	sta ip_outp + ip_tos

	; skip length

	; skip ID

	lda #$40			; don't fragment - or should we not care?
	sta ip_outp + ip_frag
	lda #0
	sta ip_outp + ip_frag + 1

	lda #$40			; set time to live
	sta ip_outp + ip_ttl

	; skip protocol

	lda #0				; clear checksum
	sta ip_outp + ip_header_cksum
	sta ip_outp + ip_header_cksum + 1

	ldx #3				; copy source address
:	lda cfg_ip,x
	sta ip_outp + ip_src,x
	dex
	bpl :-

	; skip destination address

	rts


; send an IP packet
;
; but first:
;
; call ip_create_packet
; set length
; set ID
; set protocol
; set destination address
ip_send:
	ldx #3				; get mac addr from ip
:	lda ip_outp + ip_dest,x
	sta arp_ip,x
	dex
	bpl :-

	jsr arp_lookup
	bcc :+
	rts				; packet buffer nuked, fail
:
	ldax #ip_outp			; calculate ip header checksum
	stax ip_cksum_ptr
	ldax #20
	jsr ip_calc_cksum
	stax ip_outp + ip_header_cksum

	ldx #5
:	lda arp_mac,x			; copy destination mac address
	sta eth_outp + eth_dest,x
	lda cfg_mac,x			; copy my mac address
	sta eth_outp + eth_src,x
	dex
	bpl :-

	lda #eth_proto_ip		; set type to IP
	jsr eth_set_proto

	lda ip_outp + ip_len + 1	; set packet length
	lsr
	bcc @dontpad

	rol				; pad with 0
	;clc
	adc #<ip_outp
	sta copy_src			; borrow copymem zp...
	lda ip_outp + ip_len
	adc #>ip_outp
	sta copy_src + 1
	ldy #0
	tya
	sta (copy_src),y

	sec				; round up to even number
@dontpad:
	lda ip_outp + ip_len + 1
	adc #eth_data
	sta eth_outp_len
	lda ip_outp + ip_len
	adc #0
	sta eth_outp_len + 1

	;jsr dbg_dump_ip_header

	jmp eth_tx			; send packet and return status


; calculate checksum for ip header
ip_calc_cksum:
	sta ip_cksum_len		; save length
	stx ip_cksum_len + 1

	lda #0
	sta cksum
	sta cksum + 1
	sta cksum + 2

	cpx #0
	beq @tail

:	ldx #$80			; number of bytes / 2
	jsr @calc
	inc ip_cksum_ptr + 1
	dec ip_cksum_len + 1
	bne :-

@tail:
	lda ip_cksum_len		; divide length by 2
	lsr
	php				; save carry for odd size
	tax

	jsr @calc

	plp
	bcc @done

	clc
	lda (ip_cksum_ptr),y
	adc cksum
	sta cksum
	bcc @done
	inc cksum + 1
	bne @done
	inc cksum + 2

@done:
	lda cksum + 2			; add carries back in
	clc
	adc cksum
	pha
	lda cksum + 1
	adc #0
	eor #$ff			; return inverted result
	tax
	pla
	eor #$ff

	rts

@calc:
	ldy #0				; 1's complement 16-bit sum
@next:
	clc
	lda (ip_cksum_ptr),y
	adc cksum
	sta cksum
	iny
	lda (ip_cksum_ptr),y
	adc cksum + 1
	sta cksum + 1
	bcc :+
	inc cksum + 2
:	iny
	dex
	bne @next
	rts
