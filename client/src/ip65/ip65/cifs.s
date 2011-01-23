;a simple NETBIOS over TCP server
;aka "Common Internet File System"
;
; refs: RFC1001, RFC1002, "Implementing CIFS" - http://ubiqx.org/cifs/

.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

DEFAULT_CIFS_CMD_BUFFER = $6800
.export cifs_l1_encode
.export cifs_l1_decode
.export cifs_start

.import copymem
.importzp copy_src
.importzp copy_dest

.import cfg_ip
.import output_buffer
.importzp udp_data
.import udp_send
.import udp_inp
.importzp udp_data
.import udp_send_dest
.import udp_send_src_port
.import udp_send_dest_port
.import udp_send_len
.importzp ip_src
.import ip_data
.import ip_inp
.import tcp_close
.import tcp_listen
.import tcp_callback
.import tcp_inbound_data_length
.import tcp_inbound_data_ptr
.import tcp_send
.import tcp_send_data_len

.import ip65_process
.import udp_add_listener
.import udp_callback

nbns_txn_id = 0
nbns_opcode=2
nbns_flags_rcode=3
nbns_qdcount=4
nbns_ancount=6
nbns_nscount=8
nbns_arcount=10
nbns_question_name=12
nbns_service_type=43
nbns_ttl=56
nbns_additional_record_flags=62
nbns_my_ip=64
nbns_registration_message_length=68


;given an ASCII (or PETSCII) hostname, convert to
;canonical 'level 1 encoded' form.
;
;only supports the default scope (' ' : 0x20)
;inputs: 
; AX: pointer to null terminated hostname to be encoded
;outputs:
; AX: pointer to decoded hostname
cifs_l1_encode:
	stax copy_src
	lda #0
	tax
	sta hostname_buffer+32
@empty_buffer_loop:	
	lda	#$43
	sta	hostname_buffer,x
	inx
	lda #$41
	sta	hostname_buffer,x
	inx
	cpx	#$20
	bmi	@empty_buffer_loop
	ldy	#0
	ldx	#0
@copy_loop:

	lda	(copy_src),y
	beq	@done
	lsr
	lsr
	lsr
	lsr
	clc
	adc #$41
	sta	hostname_buffer,x

	inx
	lda	(copy_src),y
	and #$0F
	clc
	adc #$41
	sta	hostname_buffer,x
	inx
	iny
	cpx	#$1D	
	bmi	@copy_loop
@done:	
	ldax #hostname_buffer
	rts
	
;given a 'level 1 encoded' hostname, decode to ASCII .
;
;inputs: 
; AX: pointer to encoded hostname to be decoded
;outputs:
; AX: pointer to decoded hostname (will be 16 byte hostname, right padded with spaces, nul terminated)
cifs_l1_decode:
	stax copy_src
	ldy	#0
	ldx	#0
@decode_loop:
	lda	(copy_src),y
	sec
	sbc	#$41
	asl
	asl
	asl
	asl
	sta hi_nibble
	iny
	lda	(copy_src),y
	sec
	sbc	#$41
	clc
	adc	hi_nibble
	sta	hostname_buffer,x
	iny
	inx
	cpx	#$10
	bmi	@decode_loop
	lda	#0
	sta	hostname_buffer,x
	ldax #hostname_buffer
	rts


;start a CIFS (SMB) server process, and advertise the specified hostname on the local LAN
;
;inputs:
;AX = ptr to hostname to be used
;outputs:
; none
cifs_start:
  
  ;save the hostname in 'raw' form
  stax  copy_src
  ldax  #raw_local_hostname
  stax  copy_dest
  ldax  #$0f
  stx raw_local_hostname+15
  jsr copymem

  ;set up callbacks
  ldax #nbns_callback
  stax udp_callback
  ldax  #137  
  jsr udp_add_listener

  ldax #nbns_callback
  stax udp_callback
  ldax  #137  
  jsr udp_add_listener

  ldax  #raw_local_hostname
  jsr cifs_l1_encode
  ldx #0
@copy_hostname_loop:  
  lda hostname_buffer,x
  sta local_hostname,x
  inx
  cpx #$21
  bmi @copy_hostname_loop
 
  jsr cifs_advertise_hostname
  jsr cifs_advertise_hostname


  ldax  #nb_session_callback
  stax  tcp_callback
@listen:

  ldax  #-4                 ;start at -4, to skip the NBT header length
  stax cifs_cmd_length
  
  
  ldax   cifs_cmd_buffer
  stax  cifs_cmd_buffer_ptr
  ldax  #139
  stx connection_closed  

  jsr tcp_listen  

@loop:
  jsr ip65_process
  lda connection_closed
  beq @loop
  
  jmp @listen
  rts
  

;broadcast a Name Registration Request message to the local LAN
cifs_advertise_hostname:
    
  ; advertise the 'server' service for own hostname
  ;overwrite the hostname in 'DNS compressed form'
  ;we assume this hostname ends with <20>
  lda #$20  ;indicates what follows is a netbios name
  sta output_buffer+nbns_question_name
  
  ldx #0
@copy_hostname_loop:
  lda local_hostname,x
  sta registration_request_servername+1,x
  inx
  cpx #$21
  bmi @copy_hostname_loop  
  
  jsr  @send_nbns_message  
  
  
  ;copy our encode hostname to the host announcment
  ldax #local_hostname
  stax  copy_src
  ldax #host_announce_hostname
  stax  copy_dest
  ldax #$20
  jsr copymem

  ;copy our encode hostname to the host announcment
  ldax #raw_local_hostname
  stax  copy_src
  ldax #host_announce_servername
  stax  copy_dest
  ldax #$10
  jsr copymem
  

;copy the local IP address to the 'sender' field of the host announcment
  ldx #03
@copy_sending_address_loop:
  lda  cfg_ip,x
  sta host_announce_my_ip,x
  dex
  bpl @copy_sending_address_loop


  ldax  #138
  stax  udp_send_dest_port
  stax  udp_send_src_port
  
  ldax  #host_announce_message_length
  stax  udp_send_len
  
  ldax  #host_announce_message
  jsr udp_send
  rts
  
  
@send_nbns_message:
;copy the local IP address
  ldx #03
@copy_my_address_loop:
  lda  cfg_ip,x
  sta nbns_my_ip,x
  dex
  bpl @copy_my_address_loop
    
  ;send to the broadcast address
  lda #$ff
  ldx #03
@copy_broadcast_address_loop:
  sta  udp_send_dest,x
  dex
  bpl @copy_broadcast_address_loop

  ldax  #137
  stax  udp_send_dest_port
  stax  udp_send_src_port
  
  ldax  #nbns_registration_message_length
  stax  udp_send_len
  
  ldax  #registration_request
  jsr udp_send
  
    
  rts
        
        
        
nbns_callback: 

  lda udp_inp+udp_data+nbns_opcode  
  and #$f8    ;mask the lower three bits
  beq @name_request
  rts
@name_request:  

  ;this is a NB NAME REQUEST.
  ;is it looking for our local hostname?
  ldax  #udp_inp+udp_data+nbns_question_name+1
  stax  copy_src
  ldy #0
@cmp_loop: 
  lda (copy_src),y
  cmp local_hostname,y
  bne @not_us
  iny
  cpy #30
  bne @cmp_loop
  
  ;this is a request for our name!
  ;we will overwrite the input message to make our response
  
  ;set the opcode & flags to make this a response
  lda #$85
  ldx #$00
  sta  udp_inp+udp_data+nbns_opcode
  stx  udp_inp+udp_data+nbns_opcode+1
  
  ;set the question count to 0
  stx  udp_inp+udp_data+nbns_qdcount+1

  ;set the answer count to 1
  inx
  stx  udp_inp+udp_data+nbns_ancount+1

;set the sender & recipients IP address
  ldx #03
@copy_address_loop:
  lda  ip_inp+ip_src,x
  sta  udp_send_dest,x
  lda  cfg_ip,x
  sta udp_inp+udp_data+nbns_my_ip-6,x
  dex
  bpl @copy_address_loop



;set the answers

  ldax #nbns_ttl_etc
  stax copy_src
  ldax #udp_inp+udp_data+nbns_ttl-6
  stax  copy_dest
  ldax  #08
  jsr copymem
  
  ldax  #137
  stax  udp_send_dest_port
  stax  udp_send_src_port
  
  ldax  #nbns_registration_message_length-6
  stax  udp_send_len
    
  ldax  #udp_inp+udp_data
  jmp udp_send

  
@not_us: 
  rts


nb_session_callback:

  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
@eof:
  inc connection_closed
@done:  
  rts
@not_eof:
  
;copy this chunk to our input buffer
  ldax cifs_cmd_buffer_ptr  
  stax copy_dest
  ldax tcp_inbound_data_ptr
  stax copy_src
  ldax tcp_inbound_data_length
  jsr copymem

;increment the pointer into the input buffer  
  clc
  lda cifs_cmd_buffer_ptr
  adc tcp_inbound_data_length
  sta cifs_cmd_buffer_ptr
  lda cifs_cmd_buffer_ptr+1
  adc tcp_inbound_data_length+1
  sta cifs_cmd_buffer_ptr+1  
  
;increment the cmd buffer length
  clc
  lda cifs_cmd_length
  adc tcp_inbound_data_length
  sta cifs_cmd_length  
  lda cifs_cmd_length+1
  adc tcp_inbound_data_length+1
  sta cifs_cmd_length+1  

;have we got a complete message?
  ldax  cifs_cmd_buffer
  stax  copy_src
  ldy #3
  lda (copy_src),y
  cmp cifs_cmd_length
  bne @not_got_full_message
  dey
  lda (copy_src),y
  cmp cifs_cmd_length+1
  bne @not_got_full_message
  
  ;we have a complete message!
  ldy #0
  lda (copy_src),y  ;get the message type
  cmp #$81    ;is it a session request?
  bne @not_session_request
  ldax  #positive_session_response_packet_length
  stax  tcp_send_data_len
  ldax  #positive_session_response_packet
  jsr tcp_send
  
  jmp @message_handled
  @not_session_request:
  cmp #$00    ;is it a session message?  
  bne @not_session_message

  ;this SHOULD be a SMB - best check the header
  
  ldy #4
  lda (copy_src),y  ;get the message data
  cmp #$FF    ;start of SMB header
  bne @not_smb
  iny
  lda (copy_src),y  ;get the message data
  cmp #'S'    ;start of SMB header
  bne @not_smb
  
  jsr smb_handler
  
  jmp @message_handled
  
  ;this doesn't look like a NBT session message or SMB, so give up
  @not_session_message:
  @not_smb:
  
   jsr tcp_close
  jmp @eof
  
@message_handled:  
  ;reset ready for next message on this connection
  ldax  #-4                 ;start at -4, to skip the NBT header length
  stax cifs_cmd_length
  
  
  ldax   cifs_cmd_buffer
  stax  cifs_cmd_buffer_ptr  
  
  
  
  @not_got_full_message:
  .import print_hex
  lda cifs_cmd_length+1 
  jsr print_hex
  lda cifs_cmd_length
  jsr print_hex
  rts
  

smb_handler:
;  at this point, copy_src points to an SMB block encapsulated in an NBT session header
  
  ldy #8
  lda (copy_src),y  ;get the SMB type
  cmp #$72
  beq @negotiate_protcol
;unknown SMB
  
  rts
@negotiate_protcol:
;copy the request TID,PID,UID,MID into the response
  ldy #28 ;offset of TID from start of message
  ldx #0
:  
  lda (copy_src),y
  sta negotiate_protocol_response_tid,x
  inx
  iny
  cpx #8
  bne :-
  

  lda  #$ff
  sta dialect_index
  sta dialect_index+1
  clc
  lda cifs_cmd_buffer
  adc #$26
  sta copy_src
  lda cifs_cmd_buffer+1
  adc #$00
  sta copy_src+1

  ldy #$0
@dialect_scan_loop:
  iny
  bmi @end_of_dialects ;if we go to offset $80, we have gone too far
  lda dialect_index
  cmp #$10    ;if we've scanned more than $10 dialects, something is wrong
  beq @end_of_dialects
  lda (copy_src),y
  cmp #$02
  bne @test_dialect
  inc dialect_index
  jmp @dialect_scan_loop
@test_dialect:
  
  tya
  clc
  adc copy_src
  sta copy_src
  bcc :+
  inc copy_src+1
:
  ldy #0
  
@test_dialect_loop:  
  lda (copy_src),y
  cmp preferred_dialect_id,y
  bne @dialect_scan_loop
  iny
  cpy #preferred_dialect_id_length
  bne @test_dialect_loop
  inc dialect_index+1
  jmp @found_preferred_dialect
    
@end_of_dialects:
  lda #$ff
  sta dialect_index
    
 @found_preferred_dialect:
  
  ldax #negotiate_protocol_response_message_length
  stax tcp_send_data_len
  ldax #negotiate_protocol_response_message
  jsr tcp_send

  rts

.data

negotiate_protocol_response_message:
  .byte $00 ;message type = session message
  .byte $00,$00,negotiate_protocol_response_message_length-4  ;NBT header
  .byte $FF,"SMB"  ;SMB header
  .byte $72   ;command = negotiate protocol
  .byte $00,$00,$00,$00 ;status = OK
  .byte $82   ;flags : oplocks not supported, paths are case sensitive
  .byte $01,$00 ;flags 2 - long file names allowed
  .byte $00, $00 ;PID HIGH
  .byte $00,$00,$00,$00,$00,$00,$00,$00 ; signature
  .byte $00, $00 ;reserved
negotiate_protocol_response_tid:  
  .byte $00,$00 ;tree ID
  .byte $98,$76  ;PID - to be overwritten
  .byte $65,$64 ;USER ID - to be overwritten
  .byte $ab,$cd ;multiplex ID - to be overwritten
  .byte $11 ;word count 
dialect_index: .res 2 ;index of selected dialect
  .byte $00 ;security mode: share, no encryption
  .byte $01,$00 ;Max MPX count
  .byte $01,$00 ;Max VCs count
  .byte $00,$08,$00,$00 ;max buffer size
  .byte $00,$08,$00,$00 ;max raw size
  .byte $12,$34,$56,$78 ;session key
  .byte $00,$00,$00,$00 ;capabilities
  .byte $00,$00,$00,$00 ;server time low
  .byte $00,$00,$00,$00 ;server time high
  .byte $00,$00 ;server GMT offset
  .byte $00 ;encryption key length
  .word negotiate_protocol_response_message_data_length ;data length
negotiate_protocol_response_message_data:
  .byte "WORKGROUP",0
  .byte "SERVERNAME",0

negotiate_protocol_response_message_length=*-negotiate_protocol_response_message  
negotiate_protocol_response_message_data_length=*-negotiate_protocol_response_message_data
  
host_announce_message:
  .byte $11 ;message type = direct group datagram
  .byte $02 ;no more fragments, this is first fragment, node type = B
  .byte $ab,$cd  ;txn id
host_announce_my_ip:
  .byte $0,0,0,0  ;source IP
  .byte $0,138    ;source port
  .byte $00,<(host_announce_message_length-4) ;datagram length
  .byte $00,$00 ;packet offset
  .byte $20       ;hostname length
host_announce_hostname:
  .res 32           ;hostname
  .byte $0          ;nul at end of hostname
  ;now WORKGROUP<1D> encoded
  
  .byte $20, $46, $48, $45, $50, $46, $43, $45, $4c, $45, $48, $46, $43, $45, $50, $46
  .byte $46, $46, $41, $43, $41, $43, $41, $43, $41, $43, $41, $43, $41, $43, $41, $42, $4E, $00
  
  .byte $ff,"SMB" ;Server Message Block header
  .byte $25 ;SMB command = Transaction
  .byte $00 ;error class = success
  .byte $00 ;reserved
  .byte $00,$00 ;no error
  .byte $00 ;flags
  .byte $00,$00 ;flags2
  .byte $00,$00 ;PID high
  .byte $00,$00,$00,$00,$00,$00,$00,$00 ;Signature
  .byte $00,$00 ;reserved
  .byte $00,$00 ;tree ID
  .byte $00,$00 ;process ID
  .byte $00,$00 ;user ID
  .byte $00,$00 ;multiplex ID
  .byte $11 ;txn word count
  .byte $00,$00 ;txn paramater count
  .byte $21,$00 ;txn total data count
  .byte $00,$00 ;txn max paramater count
  .byte $00,$00 ;txn max data count
  .byte $00 ;txn max setup count
  .byte $00 ;reserved
  .byte $00,$00 ;flags
  .byte $ed,$03,$00,$00 ;timeout = 1 second
  .byte $00,$00 ;reserved  
  .byte $00,$00 ;paramater count
  .byte $00,$00 ;paramater offset
  .byte $21,$00 ;data count
  .byte $56,$00 ;data offset
  .byte $03 ;setup count
  .byte $00 ;reserved
  
  .byte $01,$00 ;opcode = WRITE MAIL SLOT
  .byte $00,$00 ;priority 0
  .byte $02,$00 ;class = unreliable & broadcast
  .byte $32,$00 ;byte count  
  .byte "\MAILSLOT\BROWSE", 0
  .byte $01 ;command - HOST ANNOUNCEMENT
  .byte $0  ;update count 0
  .byte $80,$fc,03,00 ;update period 
  host_announce_servername:
  .res 16
  .byte $01 ;OS major version
  .byte $64 ;OS minor version
  .byte $03,$02,$0,$0 ;advertise as a workstation, server & print host
  .byte $0F ;browser major version
  .byte $01 ;browser minor version
  .byte $55,$aa ;signature
  .byte $0    ;host comment
  host_announce_message_length=*-host_announce_message  

  
registration_request:

  .byte $0c, $64  ;txn ID
  .byte $29,$10   ;Registration Request opcode & flags
  .byte $00,$01   ;questions = 1
  .byte $00,$00   ;answers = 0
  .byte $00,$00   ;authority records = 0
  .byte $00,$01   ;additional records = 1
registration_request_servername:  
  ;now WORKGROUP<00> encoded
  .byte $20, $46, $48, $45, $50, $46, $43, $45, $4c, $45, $48, $46, $43, $45, $50, $46
  .byte $46, $46, $41, $43, $41, $43, $41, $43, $41, $43, $41, $43, $41, $43, $41, $41, $41, $00

  .byte $00,$20   ;question_type = NB
  .byte $00,$01   ;question_class = IN
  .byte $c0,$0c   ;additional record name : ptr to string in QUESTION NAME
  .byte $00,$20   ;question_type = NB
  .byte $00,$01   ;question_class = IN
nbns_ttl_etc:  
  .byte $00,$00,$01,$40 ; TTL = 64 seconds
  .byte $00,$06 ;data length
  .byte $00,$00 ;FLAGS = B-NODE, UNIQUE NAME

.rodata
preferred_dialect_id: .byte "NT LM 0.12"
preferred_dialect_id_length=*-preferred_dialect_id

positive_session_response_packet:
  .byte $82     ;packet type = Positive session response
  .byte $00     ;flags
  .byte $00, $00  ;message length
positive_session_response_packet_length=*-positive_session_response_packet

.bss
hostname_buffer:	.res 33
  
  
local_hostname:		.res 33

raw_local_hostname:	
	.res 16

hi_nibble: .res 1

connection_closed: .res 1

cifs_cmd_buffer_ptr: .res 2
cifs_cmd_length: .res 2

.data 

cifs_cmd_buffer: .word DEFAULT_CIFS_CMD_BUFFER

;-- LICENSE FOR cifs.s --
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

