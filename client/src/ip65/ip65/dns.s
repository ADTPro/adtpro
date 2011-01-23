; minimal dns implementation - requires a DNS server that supports recursion

  MAX_DNS_MESSAGES_SENT=8     ;timeout after sending 8 messages will be about 7 seconds (1+2+3+4+5+6+7+8)/4

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

  .export dns_set_hostname
  .export dns_resolve
  .export dns_ip
  .export dns_status
  .import ip65_error
  .import cfg_dns
  
  .import parse_dotted_quad
  .import dotted_quad_value
  
	.import ip65_process
  
	.import udp_add_listener
  .import udp_remove_listener

	.import udp_callback
	.import udp_send

	.import udp_inp
  .import output_buffer
	.importzp udp_data

	.import udp_send_dest
	.import udp_send_src_port
	.import udp_send_dest_port
	.import udp_send_len
  .import check_for_abort_key
  .import timer_read
  
	.segment "IP65ZP" : zeropage

  dns_hostname: .res 2
  
	.bss

; dns packet offsets
dns_inp		= udp_inp + udp_data
dns_id  = 0
dns_flags=2
dns_qdcount=4
dns_ancount=6
dns_nscount=8
dns_arcount=10
dns_qname=12

dns_server_port=53
dns_client_port_low_byte: .res 1

dns_ip: .res 4  ;will be contain ip address of hostname after succesful exection of dns_resolve

dns_msg_id: .res 2

dns_current_label_length: .res 1
dns_current_label_offset: .res 1

dns_message_sent_count: .res 1

dns_packed_hostname: .res 128

; dns state machine
dns_initializing	= 1		    ; initial state
dns_query_sent	= 2		  ; sent a query, waiting for a response
dns_complete = 3        ; got a good response
dns_failed = 4        ; got either a 'no such name' or 'recursion declined' response

dns_state:	.res 1		; flag indicating the current stage in the dns resolution process
dns_timer:  .res 1
dns_loop_count: .res 1
dns_break_polling_loop: .res 1

dns_status: .res 2  ; for debugging purposes only (behaviour not garuanteed)

hostname_copied:  .res 1

questions_in_response: .res 1

hostname_was_dotted_quad: .res 1

	.code
  
; sets up for resolution of a hostname to an ip address
; inputs:
;   AX = pointer to null terminated string that contains either a dns hostname
;     (e.g. "host.example.com",0) or an address in "dotted quad" format,
;     (e.g. "192.168.1.0",0)
; outputs: 
;   carry flag is set on error (i.e. hostname too long), clear otherwise
dns_set_hostname:  
  stax  dns_hostname
                                      ;copy the hostname into  a buffer suitable to copy directly into the qname field
                                      ;we need to split on dots

  jsr parse_dotted_quad      ; if we are passed an IP address instead of a hostname, don't bother looking it up in dns
  bcs @wasnt_dotted_quad
                             ;if the string was a dotted quad, then copy the parsed 4 bytes in to dns_ip
  lda #1
  sta hostname_was_dotted_quad
  ldx #3				; set destination address
: lda dotted_quad_value,x
	sta dns_ip,x
	dex
	bpl :-
  
  rts     ;done!
  
@wasnt_dotted_quad:
  
  
  ldy #0                            ;input pointer
  ldx #1                            ;output pointer (start at 1, to skip first length offset, which will be filled in later)
  
  sty hostname_was_dotted_quad
  sty dns_current_label_length
  sty dns_current_label_offset
  sty hostname_copied
  
@next_hostname_byte:  
  lda (dns_hostname),y          ;get next char in hostname
  beq @end_of_hostname
  cmp #'/'                           ; allow hostnames to be terminated by "/" or ":" to help with URL parsing
  beq @end_of_hostname
  cmp #':'
  bne :+
@end_of_hostname:  
  inc hostname_copied
  bne @set_length_of_last_label
:

  cmp #'.'                         ;do we need to split the labels?
  bne @not_a_dot
@set_length_of_last_label:  
  txa
  pha 
  lda dns_current_label_length  
  ldx dns_current_label_offset
  sta  dns_packed_hostname,x
  lda #0
  sta dns_current_label_length
  pla
  tax
  stx dns_current_label_offset
  lda hostname_copied
  beq @update_counters 
  jmp @hostname_done
@not_a_dot:
  sta dns_packed_hostname,x
  inc dns_current_label_length
  
@update_counters:  
  iny  
  inx
  bmi @hostname_too_long    ;don't allow a hostname of more than 128 bytes
  jmp @next_hostname_byte

@hostname_done:
  
  lda dns_packed_hostname-1,x    ;get the last byte we wrote out
  beq :+                            ;was it a zero?
  lda #0
  sta dns_packed_hostname,x      ;write a trailing zero (i.e. a zero length label)  
  inx
:    
  clc   ;no error
  
  rts

@hostname_too_long:
  lda #KPR_ERROR_INPUT_TOO_LARGE
  sta ip65_error
  sec
  rts

; resolve a string containing a hostname (or a dotted quad) to an ip address
; inputs:
;   cfg_dns must point to a DNS server that supports recursion
;   dns_set_hostname must have been called to load the string to be resolved
; outputs: 
;   carry flag is set if there was an error, clear otherwise 
;   dns_ip: set to the  ip address of the hostname (if no error)
dns_resolve:  
  lda hostname_was_dotted_quad
  beq @hostname_not_dotted_quad
  clc
  rts     ;we already set dns_ip when copying the hostname
@hostname_not_dotted_quad:
  ldax #dns_in
	stax udp_callback 
  lda #53
  inc dns_client_port_low_byte    ;each call to resolve uses a different client address
	ldx dns_client_port_low_byte    ;so we don't get confused by late replies to a previous call
	jsr udp_add_listener
  
	bcc :+
	rts
:
  
  lda #dns_initializing
  sta dns_state
  lda #0  ;reset the "message sent" counter
  sta dns_message_sent_count
  
  jsr send_dns_query
  
@dns_polling_loop:
  lda dns_message_sent_count
  adc #1
  sta dns_loop_count       ;we wait a bit longer between each resend  
@outer_delay_loop: 
  lda #0
  sta dns_break_polling_loop
  jsr timer_read
  stx dns_timer            ;we only care about the high byte  
  
@inner_delay_loop:  
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  rts
@no_abort:  
  
  lda dns_state
  cmp #dns_complete
  beq @complete
  cmp #dns_failed
  beq @failed
   
  lda #0
  cmp dns_break_polling_loop
  bne @break_polling_loop
  jsr timer_read
  cpx dns_timer            ;this will tick over after about 1/4 of a second
  beq @inner_delay_loop
  
  dec dns_loop_count
  bne @outer_delay_loop  

@break_polling_loop:
  jsr send_dns_query  
	inc dns_message_sent_count
  lda dns_message_sent_count
  cmp #MAX_DNS_MESSAGES_SENT-1
  bpl @too_many_messages_sent
  jmp @dns_polling_loop
  
@complete:

  lda #53
	ldx dns_client_port_low_byte    
	jsr udp_remove_listener  
  rts

@too_many_messages_sent:
@failed:
  lda #53
  ldx dns_client_port_low_byte    
	jsr udp_remove_listener
  lda #KPR_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error  
  sec             ;signal an error
  rts

send_dns_query:  
  ldax  dns_msg_id
  inx
  adc #0
  stax  dns_msg_id
  stax  output_buffer+dns_id

  ldax #$0001          ;QR =0 (query), opcode=0 (query), AA=0, TC=0,RD=1,RA=0,Z=0,RCODE=0
  stax output_buffer+dns_flags
  ldax #$0100          ;we ask 1 question 
  stax output_buffer+dns_qdcount
  ldax #$0000                 
  stax output_buffer+dns_ancount     ;we send no answers
  stax output_buffer+dns_nscount     ;we send no name servers
  stax output_buffer+dns_arcount     ;we send no authorative records
  
  ldx #0
:  
  lda dns_packed_hostname,x
  sta output_buffer+dns_qname,x
  inx
  bpl  @hostname_still_ok
  lda #KPR_ERROR_INPUT_TOO_LARGE
  sta ip65_error
  jmp @error_on_send                ;if we got past 128 bytes, there's a problem
@hostname_still_ok:  
  cmp #0
  bne :-                                  ;keep looping until we have a zero byte.
  
  lda #0
  sta output_buffer+dns_qname,x        ;high byte of QTYPE=1 (A)
  sta output_buffer+dns_qname+2,x     ;high byte of QLASS=1 (IN)
  lda #1
  sta output_buffer+dns_qname+1,x     ;low byte of QTYPE=1 (A)
  sta output_buffer+dns_qname+3,x     ;low byte of QLASS=1 (IN)
  
  txa
  clc
  adc #(dns_qname+4)
  ldx #0
  stax udp_send_len
  
  lda #53
	ldx dns_client_port_low_byte    
	stax udp_send_src_port

  ldx #3				; set destination address
: lda cfg_dns,x
	sta udp_send_dest,x
	dex
	bpl :-

	ldax #dns_server_port			; set destination port
	stax udp_send_dest_port
  ldax #output_buffer
	jsr udp_send  
  bcs @error_on_send
  lda #dns_query_sent
  sta dns_state

  rts
@error_on_send:  
  sec
  rts
  
dns_in:
  lda dns_inp+dns_flags+1 ;
  and #$0f   ;get the RCODE
  cmp #0    
  beq @not_an_error_response
  
  sta dns_status      ;anything non-zero is a permanent error (invalid domain, server doesn't support recursion etc)
  sta dns_status+1
  lda #dns_failed
  sta dns_state
  rts
@not_an_error_response:
  lda dns_inp+dns_qdcount+1
  sta questions_in_response
  cmp #1                          ;should be exactly 1 Q in the response (i.e. the one we sent)  
  beq :+
  jmp @error_in_response
:  
  lda dns_inp+dns_ancount+1
  bne :+
  jmp @error_in_response    ;should be at least 1 answer in response  
:                                      ;we need to skip over the question (we will assume it's the question we just asked)
  ldx #dns_qname              
:  
  lda dns_inp,x     ;get next length byte in question
  beq :+                            ; we're done if length==0
  clc
  txa
  
  adc dns_inp,x ;add length of next label to ptr
  adc #1                          ;+1 for the length byte itself
  tax
  bcs @error_in_response  ;if we overflowed x, then message is too big
  bcc :-
: 
  inx                               ;skip past the nul byte
  lda dns_inp+1,x
  cmp #1                          ;QTYPE should 1
  lda dns_inp+3,x
  cmp #1                          ;QCLASS should 1
  bne @error_in_response  
          
  inx                                 ;skip past the QTYPE/QCLASS
  inx
  inx
  inx

                                      ;x now points to the start of the answers
                                      
  lda  dns_inp,x
  bpl @error_in_response    ;we are expecting the high bit to be set (we assume the server will send us back the answer to the question we just asked)
  inx                               ;skip past the compression
  inx
                                    ;we are now pointing at the TYPE field
  lda  dns_inp+1,x            ;
    
  cmp #5                        ; is this a CNAME?
  bne @not_a_cname
  
  
  txa
  clc
  adc #10                       ;skip 2 bytes TYPE, 2 bytes CLASS, 4 bytes TTL, 2 bytes RDLENGTH
  tax
                                    ;we're now pointing at the CNAME record
  ldy #0                         ;start of CNAME hostname
:
  lda dns_inp,x
  beq @last_byte_of_cname
  bmi @found_compression_marker  
  sta dns_packed_hostname,y
  inx
  iny
  bmi @error_in_response  ;if we go past 128 bytes, something is wrong
  bpl :-                          ;go get next byte
  @last_byte_of_cname:
  sta dns_packed_hostname,y
  
  lda #$ff                       ;set a status marker so we know whats going on
  sta dns_status
  stx dns_status+1
  
  lda #1
  sta dns_break_polling_loop
  
  rts                              ; finished processing - the main dns polling loop should now resend a query, this time for the hostname from the CNAME record
  
@found_compression_marker:
  lda dns_inp+1,x
  tax
  jmp :-
  
@not_a_cname:  
  cmp #1                        ; should be 1 (A record)
  bne @error_in_response
  txa
  clc
  adc #10                       ;skip 2 bytes TYPE, 2 bytes CLASS, 4 bytes TTL, 2 bytes RDLENGTH
  tax
                                    ;we're now pointing at the answer!
  lda  dns_inp,x
  sta dns_ip

  lda  dns_inp+1,x
  sta dns_ip+1
  
  lda  dns_inp+2,x
  sta dns_ip+2
  
  lda  dns_inp+3,x
  sta dns_ip+3


  lda #dns_complete
  sta dns_state
  
  lda #1
  sta dns_break_polling_loop

@error_in_response:
  
  sta dns_status
  stx dns_status+1
  rts





;-- LICENSE FOR dns.s --
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
