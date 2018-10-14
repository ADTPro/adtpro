; minimal dhcp implementation - ip addresses are requested from a dhcp server
; (aka 'leased') but are not renewed or released. although this is not correct 
; behaviour according to the DHCP RFC, this works fine in practice in a typical
; home network environment.
; 
; cfg_ip,cfg_netmask,cfg_gateway and cfg_dns variables are all overwritten,
; therefore, these values must be stored in RAM not ROM
; 

MAX_DHCP_MESSAGES_SENT=12     ;timeout after sending 12 messages will be about 15 seconds (1+2+3...)/4

  .include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif
  
  .export dhcp_init
  .import dhcp_server 
  .export dhcp_state  
  
  .import ip65_error
  .import cfg_mac
  .import cfg_ip
  .import cfg_netmask
  .import cfg_gateway
  .import cfg_dns

  .import arp_calculate_gateway_mask

	.import ip65_process

	.import udp_add_listener
  .import udp_remove_listener

	.import udp_callback
	.import udp_send

	.import udp_inp

	.importzp udp_data
  
  .import output_buffer
  
	.import udp_send_dest
	.import udp_send_src_port
	.import udp_send_dest_port
	.import udp_send_len
  .import check_for_abort_key
  .import timer_read
  
	.bss

; dhcp packet offsets
dhcp_inp		= udp_inp + udp_data

dhcp_op = 0
dhcp_htype = 1
dhcp_hlen = 2
dhcp_hops = 3
dhcp_xid = 4
dhcp_secs = 8
dhcp_flags = 10
dhcp_ciaddr = 12
dhcp_yiaddr = 16
dhcp_siaddr = 20
dhcp_giaddr = 24
dhcp_chaddr =28
dhcp_sname = 44
dhcp_file=108
dhcp_cookie=236
dhcp_options=240

dhcp_server_port=67
dhcp_client_port=68


; dhcp state machine
dhcp_initializing	= 1		        ; initial state
dhcp_selecting	= 2		; sent a DHCPDISCOVER, waiting for a DHCPOFFER
dhcp_ready_to_request = 3 ; got a DHCPOFFER, ready to send a DHCPREQUEST
dhcp_requesting = 4   ; sent a DHCPREQUEST, waiting for a DHCPACK
dhcp_bound = 5         ; we have been allocated an IP address

;flag indicating current state of dhcp initialization.
dhcp_state:	.res 1		

dhcp_message_sent_count: .res 1
dhcp_timer:  .res 1
dhcp_loop_count: .res 1
dhcp_break_polling_loop: .res 1



;DHCP constants
BOOTREQUEST   =1
BOOTREPLY     =2

DHCPDISCOVER  =1 
DHCPOFFER     =2 
DHCPREQUEST   =3
DHCPDECLINE   =4
DHCPACK       =5
DHCPNAK       =6
DHCPRELEASE   =7
DHCPINFORM    =8


	.code
;
;inputs: none (although ip65_init should be called first)
;outputs:
; carry flag clear means IP config has been sucesfully obtained and
; cfg_ip, cfg_netmask, cfg_gateway and cfg_dns will be set per response from dhcp server.
; dhcp_server will be set to address of server that provided configuration
; if carry flag is set there was an error.
; in either case, dhcp_state will indicate where dhcp initialization ended (to help debug)
; possible values for dhcp_state are:
;     1	- initial state
;     2	- sent a DHCPDISCOVER, waiting for a DHCPOFFER
;     3 - got a DHCPOFFER, ready to send a DHCPREQUEST
;     4 - sent a DHCPREQUEST, waiting for a DHCPACK
;     5 - we have been allocated an IP address
dhcp_init:

	ldx #3				; rewrite ip address
  lda #0
:	sta cfg_ip,x
	dex
	bpl :-
	
  lda #dhcp_initializing
  sta dhcp_state
  
	ldax #dhcp_in
	stax udp_callback
	ldax #dhcp_client_port
	jsr udp_add_listener
	bcc :+
	rts
:
  lda #0  ;reset the "message sent" counter
  sta dhcp_message_sent_count
  jsr send_dhcpdiscover
  
@dhcp_polling_loop:

  lda dhcp_message_sent_count
  adc #1
  sta dhcp_loop_count       ;we wait a bit longer between each resend  
  
@outer_delay_loop: 
  lda #0
  sta dhcp_break_polling_loop
  jsr timer_read
  stx dhcp_timer            ;we only care about the high byte  

@inner_delay_loop:  
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  rts
@no_abort:  
  lda #0
  cmp dhcp_break_polling_loop
  bne @break_polling_loop
  jsr timer_read
  cpx dhcp_timer            ;this will tick over after about 1/4 of a second
  beq @inner_delay_loop
  
  dec dhcp_loop_count
  bne @outer_delay_loop  

@break_polling_loop:
  
	inc dhcp_message_sent_count
  lda dhcp_message_sent_count
  cmp #MAX_DHCP_MESSAGES_SENT-1
  bpl @too_many_messages_sent
	lda dhcp_state
  cmp #dhcp_initializing
  beq @initializing
  cmp #dhcp_selecting
  beq @selecting
  cmp #dhcp_ready_to_request
  beq @ready_to_request
  cmp #dhcp_bound  
	beq @bound
  jmp @dhcp_polling_loop
@initializing:
@selecting:
  jsr send_dhcpdiscover
  jmp @dhcp_polling_loop

@ready_to_request:
  jsr send_dhcprequest
  jmp @dhcp_polling_loop
  
@bound:
	ldax #dhcp_client_port
	jsr udp_remove_listener  
  rts

@too_many_messages_sent:
  lda #KPR_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error
  jsr @bound   ;to remove the listener ( thanks to ShadowM for bug report)
  sec             ;signal an error
  rts
  
dhcp_create_request_msg:
  lda #BOOTREQUEST  
  sta output_buffer+dhcp_op
  lda #1                                ;htype 1 = "10 MB ethernet"
  sta output_buffer+dhcp_htype
  lda #6                                ;ethernet MACs are 6 bytes
  sta output_buffer+dhcp_hlen
  lda #0                                ;hops = 0
  sta output_buffer+dhcp_hops
  ldx #3                                ;set xid to be "1234"
  clc
: txa
  adc #01
  sta output_buffer+dhcp_xid,x
  dex
  bpl :-
  
  lda #0                              ;secs =00
  sta output_buffer+dhcp_secs
  sta output_buffer+dhcp_secs+1
                                        ;initially turn off all flags 
  sta output_buffer+dhcp_flags  
  sta output_buffer+dhcp_flags+1
  
  ldx #$0F                          ;set ciaddr to 0.0.0.0
                                    ;set yiaddr to 0.0.0.0
                                    ;set siaddr to 0.0.0.0
                                    ;set giaddr to 0.0.0.0
: sta output_buffer+dhcp_ciaddr,x
  dex
  bpl :-
  
  ldx #5                          ;set chaddr to mac  
:	lda cfg_mac,x
  sta output_buffer+dhcp_chaddr,x
  dex
  bpl :-

  ldx #192                          ;set sname & file both to null
  lda #0
:	sta output_buffer+dhcp_sname-1,x
  dex
  bne :-
  
        
  lda #$63                      ;copy the magic cookie
  sta output_buffer+dhcp_cookie+0
  lda #$82
  sta output_buffer+dhcp_cookie+1
  lda #$53
  sta output_buffer+dhcp_cookie+2
  lda #$63
  sta output_buffer+dhcp_cookie+3
  
	ldax #dhcp_client_port			; set source port
	stax udp_send_src_port

	ldax #dhcp_server_port			; set destination port
	stax udp_send_dest_port

  rts

send_dhcpdiscover:
  lda #dhcp_initializing
	sta dhcp_state

  jsr dhcp_create_request_msg

  lda #$80                           ;broadcast flag =1, all other bits 0
  sta output_buffer+dhcp_flags
  

  ldx #dhcp_discover_options_length				; set destination address  
:
  lda dhcp_discover_options,x
  sta output_buffer+dhcp_options,x
	dex
	bpl :-

  ldx #3				; set destination address
  lda #$FF      ; des = 255.255.255.255 (broadcast)
:	sta udp_send_dest,x
	dex
	bpl :-

  ldax #dhcp_options+dhcp_discover_options_length
  stax udp_send_len
  ldax #output_buffer
	jsr udp_send
	bcc :+
  rts
  
: lda #dhcp_selecting
	sta dhcp_state
  rts

dhcp_discover_options:
.byte 53 ;option 53 - DHCP message type
.byte  1 ;option length =1 
.byte DHCPDISCOVER ; message type
.byte 55 ; option 55 - Parameter Request List
.byte 3  ;option length
.byte 1 ; subnet mask
.byte 3 ; router (gateway)
.byte 6 ; DNS server
.byte $FF ; end of options

dhcp_discover_options_length=*-dhcp_discover_options

;got a message on port 68
dhcp_in:
    
  lda dhcp_inp+dhcp_op  
  cmp #BOOTREPLY
  beq :+
  rts                       ;it's not what we were expecting  
:    

  lda #0
  cmp dhcp_inp+dhcp_yiaddr  ;is the first byte in the assigned address 0?
  bne :+
  rts                                 ;if so, it's a bogus response - ignore
:  
  ldx #4                          ;copy the our new IP address
:	
  lda dhcp_inp+dhcp_yiaddr,x
  sta cfg_ip,x
  dex
  bpl :-

  ldx #0
@unpack_dhcp_options:
  lda dhcp_inp+dhcp_options,x
  cmp #$ff
  bne :+
  jmp @finished_unpacking_dhcp_options
:  
  cmp #53                 ;is this field DHCP message type?  
  bne @not_dhcp_message_type
  jmp @get_next_option
  lda dhcp_inp+dhcp_options+2,x
  cmp #DHCPOFFER          ;if it's not a DHCP OFFER message, then stop processing
  beq :+
  rts   
: jmp @get_next_option 

@not_dhcp_message_type:
  
  cmp #1                ;option 1 is netmask
  bne @not_netmask
  lda dhcp_inp+dhcp_options+2,x
  sta cfg_netmask
  lda dhcp_inp+dhcp_options+3,x
  sta cfg_netmask+1
  lda dhcp_inp+dhcp_options+4,x
  sta cfg_netmask+2
  lda dhcp_inp+dhcp_options+5,x
  sta cfg_netmask+3  
  jmp @get_next_option 
  
@not_netmask:

  cmp #3               ;option 3 is gateway
  bne @not_gateway
  lda dhcp_inp+dhcp_options+2,x
  sta cfg_gateway
  lda dhcp_inp+dhcp_options+3,x
  sta cfg_gateway+1
  lda dhcp_inp+dhcp_options+4,x
  sta cfg_gateway+2
  lda dhcp_inp+dhcp_options+5,x
  sta cfg_gateway+3
  jmp @get_next_option 
  
@not_gateway:

  cmp #6               ;option 6 is dns server
  bne @not_dns_server
  lda dhcp_inp+dhcp_options+2,x
  sta cfg_dns
  lda dhcp_inp+dhcp_options+3,x
  sta cfg_dns+1
  lda dhcp_inp+dhcp_options+4,x
  sta cfg_dns+2
  lda dhcp_inp+dhcp_options+5,x
  sta cfg_dns+3
  jmp @get_next_option 
  
@not_dns_server:

  cmp #54               ;option 54 is DHCP server
  bne @not_server
  lda dhcp_inp+dhcp_options+2,x
  sta dhcp_server
  lda dhcp_inp+dhcp_options+3,x
  sta dhcp_server+1
  lda dhcp_inp+dhcp_options+4,x
  sta dhcp_server+2
  lda dhcp_inp+dhcp_options+5,x
  sta dhcp_server+3
  jmp @get_next_option 
  
@not_server:


@get_next_option:
  txa
  clc
  adc #02
  adc dhcp_inp+dhcp_options+1,x
  bcs @finished_unpacking_dhcp_options   ; if we overflow, then we're done
  tax
  jmp @unpack_dhcp_options


@finished_unpacking_dhcp_options:
  jsr arp_calculate_gateway_mask                ;we have modified our netmask, so we need to recalculate gw_test
  lda dhcp_state
  cmp #dhcp_bound
  beq :+
  lda #dhcp_ready_to_request
  sta dhcp_state
: 
  lda #1
  sta dhcp_break_polling_loop
  
  rts

send_dhcprequest:
  jsr dhcp_create_request_msg
  lda #53                           ;option 53 - DHCP message type
  sta output_buffer+dhcp_options+0
  lda #1                            ;option length is 1  
  sta output_buffer+dhcp_options+1
  lda #DHCPREQUEST
  sta output_buffer+dhcp_options+2

  lda #50                           ;option 50 - requested IP address
  sta output_buffer+dhcp_options+3
  ldx #4                               ;option length is 4  
  stx output_buffer+dhcp_options+4
  dex
: lda cfg_ip,x
  sta output_buffer+dhcp_options+5,x
  dex
  bpl :-

  lda #54                           ;option 54 - DHCP server
  sta output_buffer+dhcp_options+9
  ldx #4                            ;option length is 4  
  stx output_buffer+dhcp_options+10
  dex

: lda dhcp_server,x
  sta output_buffer+dhcp_options+11,x
  lda #$ff ;bugfix by ShadowM - DHCP request should be broadcast
  sta udp_send_dest,x
  dex
  bpl :-

  ;A still = option FF = end of options 
  
  sta output_buffer+dhcp_options+15

  ldax #dhcp_options+16
  stax udp_send_len

  ldax #output_buffer
	jsr udp_send
  bcs :+            ;if we didn't send the message we probably need to wait for an ARP reply to come back.
  lda #dhcp_bound   ;technically, we should wait till we get a DHCPACK message. but we'll assume success
	sta dhcp_state  
:	rts


;-- LICENSE FOR dhcp.s --
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
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.  
; -- LICENSE END --
