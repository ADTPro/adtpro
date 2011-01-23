;ICMP implementation
;

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

	.export icmp_init
	.export icmp_process
	.export icmp_add_listener
	.export icmp_remove_listener

	.export icmp_callback

	.export icmp_inp
	.export icmp_outp

	.export fix_eth_tx_01

	.exportzp icmp_type
	.exportzp icmp_code
	.exportzp icmp_cksum
	.exportzp icmp_data

.ifdef TCP
  .export icmp_echo_ip
  .export icmp_send_echo
  .export icmp_ping
.endif



  .import ip65_process
  .import ip65_error

	.import ip_calc_cksum
	.import ip_inp
	.import ip_outp
	.import ip_broadcast
  .import ip_send
  .import ip_create_packet
  .importzp ip_proto
  .importzp ip_proto_icmp

	.importzp ip_cksum_ptr
	.importzp ip_header_cksum
	.importzp ip_src
	.importzp ip_dest
	.importzp ip_data
  .importzp ip_len
  
	.import eth_tx
	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len
  .import timer_read
  .import timer_timeout

.data
  icmp_cbtmp:	jmp $0000			; temporary vector - address filled in later


	.bss

; argument for icmp_add_listener
icmp_callback:	.res 2


; icmp callbacks
icmp_cbmax	= 2
icmp_cbveclo:	.res icmp_cbmax		; table of listener vectors (lsb)
icmp_cbvechi:	.res icmp_cbmax		; table of listener vectors (msb)
icmp_cbtype:	.res icmp_cbmax		; table of listener types
icmp_cbcount:	.res 1			; number of active listeners

; icmp packet offsets
icmp_inp	= ip_inp + ip_data  ;pointer to inbound icmp packet
icmp_outp	= ip_outp + ip_data ;pointer to outbound icmp packet
icmp_type	= 0 ;offset of 'type' field in icmp packet
icmp_code	= 1 ;offset of 'code' field in icmp packet
icmp_cksum	= 2 ;offset of 'checksum' field in icmp packet
icmp_data	= 4;offset of 'data' field in icmp packet

; icmp echo packet offsets
icmp_echo_id	= 4 ;offset of 'id' field in icmp echo request/echo response
icmp_echo_seq	= 6 ;offset of 'sequence' field in icmp echo request/echo response
icmp_echo_data	= 8 ;offset of 'data' field in icmp echo request/echo response

;icmp type codes
icmp_msg_type_echo_reply=0
icmp_msg_type_destination_unreachable=3
icmp_msg_type_source_quench=4
icmp_msg_type_redirect=5
icmp_msg_type_echo_request=8
icmp_msg_type_time_exceeded=11
icmp_msg_type_paramater_problem=12
icmp_msg_type_timestamp=13
icmp_msg_type_timestamp_reply=14
icmp_msg_type_information_request=15
icmp_msg_type_information_reply=16

;ping states
ping_state_request_sent=0
ping_state_response_received=1


.ifdef TCP
.segment "TCP_VARS"
icmp_echo_ip: .res 4 ; destination IP address for echo request ("ping")
icmp_echo_cnt: .res 1  ;ping sequence counter
ping_state: .res 1  
 ping_timer: .res 2 ;
.endif

	.code

; initialize icmp
; inputs: none
; outputs: none
icmp_init:
	lda #0
	sta icmp_cbcount
	rts

;process incoming icmp packet
;inputs:
;   eth_inp points to an ethernet frame containing an icmp packet
;outputs:
;   carry flag - set on any error, clear if OK
;   if inbound packet is a request (e.g. 'echo request') and an icmp listener
;   has been installed, then an appropriate response message will  be 
;   generated and sent out (overwriting the eth_outp buffer)
icmp_process:
	lda icmp_inp + icmp_type
	cmp #icmp_msg_type_echo_request				; ping
	beq @echo

	lda icmp_cbcount		; any installed icmp listeners?
	beq @drop

	ldx icmp_cbcount		; check listened types
	dex
:	lda icmp_cbtype,x
	cmp icmp_inp + icmp_type
	beq @handle			; found a match
	dex
	bpl :-

@drop:
	sec
	rts

@handle:
	lda icmp_cbveclo,x		; copy vector
	sta icmp_cbtmp + 1
	lda icmp_cbvechi,x
	sta icmp_cbtmp + 2
	jsr icmp_cbtmp			; call listener
	clc
	rts

@echo:
	lda ip_broadcast		; check if packet is broadcast
	beq @notbc
	sec				; don't reply to broadcast pings
	rts
@notbc:
	ldx #5
:	lda eth_inp,x			; swap dest and src mac
	sta eth_outp + 6,x
	lda eth_inp + 6,x
	sta eth_outp,x
	dex
	bpl :-

	ldx #12				; copy the packet
:	lda eth_inp,x
	sta eth_outp,x
	inx
	cpx eth_inp_len
	bne :-

	ldx #3
:	lda ip_inp + ip_src,x		; swap dest and src ip
	sta ip_outp + ip_dest,x
	lda ip_inp + ip_dest,x
	sta ip_outp + ip_src,x
	dex
	bpl :-

	lda #0				; change type to reply
	sta icmp_outp + icmp_type

	lda icmp_inp + icmp_cksum	; recalc checksum
	clc
	adc #8
	sta icmp_outp + icmp_cksum
	bcc :+
	inc icmp_outp + icmp_cksum + 1
:
	lda eth_inp_len			; copy length
	sta eth_outp_len
	lda eth_inp_len + 1
	sta eth_outp_len + 1

	lda #0				; clear checksum
	sta ip_outp + ip_header_cksum
	sta ip_outp + ip_header_cksum + 1
	ldax #ip_outp			; calculate ip header checksum
	stax ip_cksum_ptr
	ldax #20
	jsr ip_calc_cksum
	stax ip_outp + ip_header_cksum

fix_eth_tx_01:
	jsr $0000			; jsr eth_tx send packet

	clc
	rts


;add an icmp listener
;inputs:
; A = icmp type
; icmp_callback: vector to call when an icmp packet of specified type arrives
;outputs:
; carry flag - set if error, clear if no error
icmp_add_listener:
	ldx icmp_cbcount		; any listeners at all?
	beq @add
	cpx #icmp_cbmax			; max?
	beq @full
	ldx #0
:	cmp icmp_cbtype,x		; check if type is already listened
	beq @busy
	inx
	cpx icmp_cbcount
	bne :-
@add:
	inc icmp_cbcount		; increase counter
	sta icmp_cbtype,x		; add type
	lda icmp_callback		; and vector
	sta icmp_cbveclo,x
	lda icmp_callback + 1
	sta icmp_cbvechi,x

	clc
	rts
@full:
@busy:
	sec
	rts


;remove an icmp listener
;inputs:
; A = icmp type
;outputs:
; carry flag - set if error (i.e. no listner for this type exists), 
;    clear if no error
icmp_remove_listener:
	ldx icmp_cbcount		; any listeners installed?
	beq @notfound
  dex
:	cmp icmp_cbtype,x		; check if type is listened
	beq @remove
	dex
	bpl :-
@notfound:
	sec
	rts
@remove:
	txa				; number of listeners below
	eor #$ff
	clc
	adc icmp_cbcount
	beq @done
@move:
	tay				; number of items to move
:	lda icmp_cbtype + 1,x		; move type
	sta icmp_cbtype,x
	lda icmp_cbveclo + 1,x		; move vector lsb
	sta icmp_cbveclo,x
	lda icmp_cbvechi + 1,x		; move vector msb
	sta icmp_cbvechi,x
	inx
	dey
	bne :-
@done:
	dec icmp_cbcount		; decrement counter
	clc
	rts

.ifdef TCP

; icmp_send_echo was contributed by Glenn Holmer (ShadowM)

;send an ICMP echo ("ping") request
;inputs:
; icmp_echo_ip: destination IP address
;outputs:
; carry flag - set if error, clear if no error
icmp_send_echo:
  ldy #3
: 
  lda icmp_echo_ip,y
  sta ip_outp + ip_dest,y
  dey
  bpl :-
  

  lda #icmp_msg_type_echo_request
  sta icmp_outp + icmp_type
  lda #0  ;not used for echo packets
  sta icmp_outp + icmp_code
  sta icmp_outp + icmp_cksum        ;clear checksum
  sta icmp_outp + icmp_cksum + 1
  sta icmp_outp + icmp_echo_id      ;set id to 0
  sta icmp_outp + icmp_echo_id + 1
  inc icmp_echo_cnt + 1  ;big-endian
  bne :+
  inc icmp_echo_cnt
: 
  ldax icmp_echo_cnt
  stax icmp_outp + icmp_echo_seq

  ldy #0
: 
  lda ip65_msg,y
  beq @set_ip_len
  sta icmp_outp + icmp_echo_data,y
  iny
  bne :-
@set_ip_len:
  tya
  clc
  adc #28  ;IP header + ICMP type, code, cksum, id, seq
  sta ip_outp + ip_len + 1  ;high byte first
  lda #0  ;will never be >256
  sta ip_outp + ip_len

  ldax #icmp_outp  ;start of ICMP packet
  stax ip_cksum_ptr
  tya
  clc
  adc #8  ;ICMP type, code, cksum, id, seq
  ldx #0  ;AX = length of ICMP data
  jsr ip_calc_cksum
  stax icmp_outp + icmp_cksum
  lda #ip_proto_icmp
  sta ip_outp + ip_proto
  jsr ip_create_packet
  jmp ip_send

;send a ping (ICMP echo request) to a remote host, and wait for a response
;inputs:
; icmp_echo_ip: destination IP address
;outputs:
; carry flag - set if no response, otherwise AX is time (in miliseconds) for host to respond
icmp_ping:
	
  lda #0  ;reset the "packet sent" counter
  sta icmp_echo_cnt
@send_one_message:
  jsr icmp_send_echo
  bcc @message_sent_ok
  ;we couldn't send the message - most likely we needed to do an ARP lookup.
  ;so wait a bit, and retry

	jsr timer_read		; read current timer value
	stax ping_timer
@loop_during_arp_lookup:
	
  jsr ip65_process
  ldax ping_timer
  adc #50		; set timeout to now + 50 ms
  bcc :+
  inx
:  

  jsr timer_timeout
  bcs @loop_during_arp_lookup
  jsr icmp_send_echo  
  bcc @message_sent_ok
  ;still can't send? then give up
  lda #KPR_ERROR_TRANSMIT_FAILED
  sta ip65_error
  rts 
@message_sent_ok:
	jsr timer_read		; read current timer value
	stax ping_timer
  ldax #icmp_ping_callback  
  stax icmp_callback
  lda #icmp_msg_type_echo_reply
  jsr icmp_add_listener
  lda #ping_state_request_sent
  sta ping_state
@loop_till_get_ping_response:
  jsr ip65_process
  
  lda ping_state
  cmp #ping_state_response_received
  beq @got_reply
  ldax ping_timer
  inx   ;x rolls over about 4 times per second
  inx   ;so we will timeout after about 2 seconds
  inx
  inx
  inx
  inx
  inx
  inx
    
  
  jsr timer_timeout
	bcs @loop_till_get_ping_response
  lda #KPR_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error
  lda #icmp_msg_type_echo_reply
  jsr icmp_remove_listener
  sec
  rts
@got_reply:
  lda #icmp_msg_type_echo_reply
  jsr icmp_remove_listener
  jsr timer_read
  sec
  sbc ping_timer
  pha
  txa
  sbc ping_timer+1  
  tax
  pla
  clc
  rts

icmp_ping_callback:
  lda icmp_inp + icmp_echo_seq
  cmp icmp_echo_cnt
  bne @not_what_we_were_waiting_for
  lda #ping_state_response_received
  sta ping_state
@not_what_we_were_waiting_for:
  rts
  
ip65_msg:
  .byte "ip65 - the 6502 IP stack",0
.endif


;-- LICENSE FOR icmp.s --
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
;
;Contributor(s): Jonno Downes, Glenn Holmer
; -- LICENSE END --
