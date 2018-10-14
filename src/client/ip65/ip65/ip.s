.include "../inc/common.i"

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

	.export fix_eth_tx_00

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

.ifdef TCP
  .import tcp_init
  .import tcp_process
.endif
	.importzp copy_src


	.segment "IP65ZP" : zeropage

; checksum
ip_cksum_ptr:	.res 2		; pointer to data to be checksummed


.bss

ip_cksum_len:	.res 2		; length of data to be checksummed

; ip packets start at ethernet packet + 14
ip_inp		= eth_inp + eth_data    ;pointer to start of IP packet in input ethernet frame
ip_outp		= eth_outp + eth_data ;pointer to start of IP packet in output ethernet frame

; temp storage for size calculation
len:		.res 2

; flag for incoming broadcast packets
ip_broadcast:	.res 1  ;flag set when an incoming IP packet was sent to a broadcast address

; ip packet offsets
ip_ver_ihl	= 0 ;offset of 4 bit "version" field and 4 bit "header length" field in an IP packet header
ip_tos		= 1 ;offset of "type of service" field in an IP packet header
ip_len		= 2 ;offset of "length" field in an IP packet header
ip_id		= 4 ;offset of "identification" field in an IP packet header
ip_frag		= 6 ;offset of "fragmentation offset" field in an IP packet header
ip_ttl		= 8 ;offset of "time to live" field in an IP packet header
ip_proto	= 9 ;offset of "protocol number" field in an IP packet header
ip_header_cksum	= 10 ;offset of "ip header checksum" field in an IP packet header
ip_src		= 12 ;offset of "source address" field in an IP packet header
ip_dest		= 16 ;offset of "destination address" field in an IP packet header
ip_data		= 20 ;offset of data payload in an IP packet

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
; inputs: none
; outputs: none
ip_init:
	lda #0
	sta bad_header
	sta bad_header + 1
	sta bad_addr
	sta bad_addr + 1

	jsr icmp_init
.ifdef TCP
  jsr tcp_init
.endif
	jsr udp_init

	rts


;process an incoming packet & call the appropriate protocol handler 
;inputs:
; eth_inp: should point to the received ethernet packet 
;outputs:
; carry flag - set on any error, clear if OK
; depending on the packet contents and the protocol handler, a response
; message may be generated and sent out (overwriting eth_outp buffer)
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
.ifdef TCP  
:	cmp #ip_proto_tcp
	bne :+
	jmp tcp_process			; jump to tcp handler
.endif  
:	cmp #ip_proto_udp
	bne :+
	jmp udp_process			; jump to udp handler
:
unknown_protocol:
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

	lda ip_inp+10
	bne @has_cksum
	lda ip_inp+11
	bne @has_cksum
	clc
	rts

@has_cksum:
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
;jonno 2011-01-2
;previously this was just checking for 255.255.255.255
;however it is also possible to do a broadcast to a specific subnet, e.g. 10.5.1.255
;this is particularly common with NETBIOS over TCP 
;we really should use the netmask, but as a kludge, just see if last octet is 255.
;this will work on a /24 network
;
	inc ip_broadcast
;	lda ip_inp + ip_dest		; check for broadcast
;	and ip_inp + ip_dest + 1
;	and ip_inp + ip_dest + 2
;	and ip_inp + ip_dest + 3
	lda ip_inp + ip_dest +3		; check for broadcast
	cmp #$ff
	beq @ok
	inc bad_addr
  
	bne :+
	inc bad_addr + 1
:	sec
	rts


; create an IP header (with all the appropriate flags and common fields set) inside an
; ethernet frame
;inputs:
; eth_outp: should point to a buffer in which the ethernet frame is being built
;outputs:
; eth_outp: contains an IP header with version, TTL, flags, src address & IP header 
; checksum fields set.
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
;inputs
; eth_outp: should point to an ethernet frame that has an IP header created (by 
; calling ip_create_packet)
; ip_len: should contain length of IP packet (header + data)
; ip_id: should contain an ID that is unique for each packet
; ip_protocol: should contain protocol ID
; ip_dest: should contain the destination IP address
;outputs:
; eth_outp: ethernet frame updated with correct IP header, then sent out over 
; the wire
; carry flag - set on any error, clear if OK
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

fix_eth_tx_00:
	jmp $0000			; jmp eth_tx send packet and return status


; calculate checksum for a buffer according to the standard IP checksum algorithm
; David Schmidt discovered errors in the original ip65 implementation, and he replaced
; this with an implementation from the contiki project (http://www.sics.se/contiki/)
; when incorporating ip65 into ADTPro (http://adtpro.sourceforge.net/)
; So I have cribbed that version from 
; http://adtpro.cvs.sourceforge.net/viewvc/adtpro/adtpro/client/src/ip65/ip.s
;inputs:
; ip_cksum_ptr: points at buffer to be checksummed
; AX: length of buffer to be checksumed
;outputs:
; AX: checkum of buffer
ip_calc_cksum:
	sta ip_cksum_len		; save length
	stx ip_cksum_len + 1

	lda #0
	sta cksum
	sta cksum+1

	lda ip_cksum_len+1
	beq chksumlast

; If checksum is > 256, do the first runs.
	ldy #0
	clc
chksumloop_256:
	lda (ip_cksum_ptr),y
	adc cksum
	sta cksum
	iny
	lda (ip_cksum_ptr),y
	adc cksum+1
	sta cksum+1
	iny
	bne chksumloop_256
	inc ip_cksum_ptr+1
	dec ip_cksum_len+1
	bne chksumloop_256

chksum_endloop_256:
	lda cksum
	adc #0
	sta cksum
	lda cksum+1
	adc #0
	sta cksum+1
	bcs chksum_endloop_256
  
chksumlast:
	lda ip_cksum_len
	lsr
	bcc chksum_noodd
	ldy ip_cksum_len
	dey
	lda (ip_cksum_ptr),y
	clc
	adc cksum
	sta cksum
	bcc noinc1
	inc cksum+1
	bne noinc1
	inc cksum
noinc1:
	dec ip_cksum_len

chksum_noodd:
	clc
	php
	ldy ip_cksum_len
chksum_loop1:
	cpy #0
	beq chksum_loop1_end
	plp
	dey
	dey
	lda (ip_cksum_ptr),y
	adc cksum
	sta cksum
	iny
	lda (ip_cksum_ptr),y
	adc cksum+1
	sta cksum+1
	dey
	php
	jmp chksum_loop1
chksum_loop1_end:
	plp
  
chksum_endloop:
	lda cksum
	adc #0
	sta cksum
	lda cksum+1
	adc #0
	sta cksum+1
	bcs chksum_endloop
  
	lda cksum+1
	eor #$ff
	tax
	lda cksum
	eor #$ff

	rts



;-- LICENSE FOR ip.s --
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
