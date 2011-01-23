;routines for dumping debug information

.include "../inc/common.i"
.include "../inc/printf.i"


	.export dbgout16
	.export dbg_dump_eth_header
	.export dbg_dump_ip_header
	.export dbg_dump_udp_header

	.export console_out
	.export console_strout


	.import eth_outp, eth_outp_len
	.import ip_outp
	.import udp_outp


	.segment "IP65ZP" : zeropage

cptr:	.res 2


	.code


;prints out the header  of ethernet packet that is ready to be sent;
; inputs: 
; eth_outp: pointer to ethernet packet
; eth_outp_len: length of ethernet packet
; outputs: none
dbg_dump_eth_header:
	pha
	txa
	pha
	tya
	pha

	printf "\rethernet header:\r"
	printf "len: %04x\r", eth_outp_len
	printf "dest: %04x:%04x:%04x\r", eth_outp, eth_outp + 2, eth_outp + 4
	printf "src: %04x:%04x:%04x\r", eth_outp + 6, eth_outp + 8, eth_outp + 10
	printf "type: %04x\r", eth_outp + 12

	pla
	tay
	pla
	tax
	pla
	rts

;prints out the header  of ip packet that is ready to be sent;
; inputs: 
; eth_outp: pointer to ethernet packet containing an ip packet
; eth_outp_len: length of ethernet packet
; outputs: none
dbg_dump_ip_header:
	pha
	txa
	pha
	tya
	pha

	printf "\rip header:\r"
	printf "ver,ihl,tos: %04x\r", ip_outp
	printf "len: %04x\r", ip_outp + 2
	printf "id: %04x\r", ip_outp + 4
	printf "frag: %04x\r", ip_outp + 6
	printf "ttl: %02x\r", ip_outp + 8
	printf "proto: %02x\r", ip_outp + 9
	printf "cksum: %04x\r", ip_outp + 10
	printf "src: %04x%04x\r", ip_outp + 12, ip_outp + 14
	printf "dest: %04x%04x\r", ip_outp + 16, ip_outp + 18

	pla
	tay
	pla
	tax
	pla
	rts

;prints out the header  of udp packet that is ready to be sent;
; inputs: 
; eth_outp: pointer to ethernet packet containing a udp packet
; eth_outp_len: length of ethernet packet
; outputs: none
dbg_dump_udp_header:
	pha
	txa
	pha
	tya
	pha

	printf "\rudp header:\r"
	printf "srcport: %04x\r", ip_outp
	printf "destport: %04x\r", ip_outp + 2
	printf "len: %04x\r", ip_outp + 4
	printf "cksum: %04x\r", ip_outp + 6

	pla
	tay
	pla
	tax
	pla
	rts


console_out	= $ffd2

;print a string to the console
;inputs: AX = address of (null terminated) string to print
;outputs: none
console_strout:
	stax cptr

	pha
	txa
	pha
	tya
	pha
	ldy #0
:	lda (cptr),y
	beq @done
	jsr console_out
	iny
	bne :-
@done:
	pla
	tay
	pla
	tax
	pla
	rts

;print a 32 bit number as 4 hex digits
;inputs: AX = 32 bit number to print
;outputs: none
dbgout16:
	stax val16	
	printf "%04x", val16
	rts


	.bss

val16:	.res 2



;-- LICENSE FOR debug.s --
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
