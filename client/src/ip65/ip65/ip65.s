; ip65 main routines

.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

	.export ip65_init
	.export ip65_process
	.export ip65_random_word
	.export ip65_ctr
	.export ip65_ctr_arp
	.export ip65_ctr_ip
	.export fix_eth_rx_00

	.export ip65_error
   
	.import uth_init
	.import lan_init
	.import timer_init
	.import arp_init
	.import ip_init
	.import timer_read

	.import eth_inp
	.import eth_outp

	.import ip_process
	.import arp_process

	.importzp eth_proto_arp

  .export ip65_random_word
  
	.bss


ip65_ctr:	.res 1		; incremented for every incoming packet
ip65_ctr_arp:	.res 1		; incremented for every incoming arp packet
ip65_ctr_ip:	.res 1		; incremented for every incoming ip packet

ip65_error: .res 1  ;last error code

	.code

;generate a 'random' 16 bit word
;entropy comes from the last ethernet frame, counters, and timer
;inputs: none
;outputs: AX set to a pseudo-random 16 bit number
ip65_random_word:
  jsr timer_read ;sets AX
  adc $9004 ;on a VIC 20, this is the raster register
  adc $d41b; on a c64, this is a 'random' number from the SID
  pha
  adc ip65_ctr_arp
  ora #$08    ;make sure we grab at least 8 bytes from eth_inp
  tax   
:  
  adc eth_inp,x
  adc eth_outp,x
  dex
  bne :-
  tax
  pla
  adc ip65_ctr
  eor ip65_ctr_ip
  rts

; initialise the IP stack
; this calls the individual protocol & driver initialisations, so this is
; the only *_init routine that must be called by a user application,
; except for dhcp_init which must also be called if the application
; is using dhcp rather than hardcoded ip configuration
; inputs: none
; outputs: none
ip65_init:
	jsr uth_init		; initialize Uthernet driver
	bcc @ok
	jsr lan_init
	bcc @ok
	lda #KPR_ERROR_DEVICE_FAILURE
	sta ip65_error
	rts
@ok:
	jsr timer_init		; initialize timer
	jsr arp_init		; initialize arp
	jsr ip_init		; initialize ip, icmp, udp, and tcp
	clc
	rts


;main ip polling loop
;this routine should be periodically called by an application at any time
;that an inbound packet needs to be handled.
;it is 'non-blocking', i.e. it will return if there is no packet waiting to be
;handled. any inbound packet will be handed off to the appropriate handler.
;inputs: none
;outputs: carry flag set if no packet was waiting, or packet handling caused error.
;  since the inbound packet may trigger generation of an outbound, eth_outp 
;  and eth_outp_len may be overwriiten. 
ip65_process:
fix_eth_rx_00:
	jsr $0000		; jsr eth_rx check for incoming packets
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



;-- LICENSE FOR ip65.s --
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
