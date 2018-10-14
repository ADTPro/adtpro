;TCP (transmission control protocol) functions
;NB to use these functions, you must pass "-DTCP" to ca65 when assembling "ip.s"
;otherwise inbound tcp packets won't get passed in to tcp_process 
;currently only a single outbound (client) connection is supported
;to use, first call "tcp_connect" to create a connection. to send data on that connection, call "tcp_send". 
;whenever data arrives, a call will be made to the routine pointed at by tcp_callback.


MAX_TCP_PACKETS_SENT=8     ;timeout after sending 8 messages will be about 7 seconds (1+2+3+4+5+6+7+8)/4

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.import ip65_error

.export tcp_init
.export tcp_process
.export tcp_connect
.export tcp_callback
.export tcp_connect_ip
.export tcp_send_data_len
.export tcp_send
.export tcp_send_string
.export tcp_close
.export tcp_listen
.export tcp_send_keep_alive
.export tcp_connect_remote_port
.export tcp_remote_ip
.export tcp_state
.export tcp_inbound_data_ptr
.export tcp_inbound_data_length


.import ip_calc_cksum
.import ip_send
.import ip_create_packet
.import ip_inp
.import ip_outp
.import ip65_process

.import check_for_abort_key
.import timer_read
.import ip65_random_word

.importzp acc32
.importzp op32
.importzp acc16

.import add_32_32
.import add_16_32
.import cmp_32_32
.import cmp_16_16
.import sub_16_16



.importzp ip_cksum_ptr
.importzp ip_header_cksum
.importzp ip_src
.importzp ip_dest
.importzp ip_data
.importzp ip_proto
.importzp ip_proto_tcp
.importzp ip_id
.importzp ip_len

.import copymem
.importzp copy_src
.importzp copy_dest

.import cfg_ip

tcp_cxn_state_closed      = 0 
tcp_cxn_state_listening   = 1  ;(waiting for an inbound SYN)
tcp_cxn_state_syn_sent    = 2  ;(waiting for an inbound SYN/ACK)
tcp_cxn_state_established = 3  ;  

; tcp packet offsets
tcp_inp		= ip_inp + ip_data  ;pointer to tcp packet inside inbound ethernet frame
tcp_outp	= ip_outp + ip_data ;pointer to tcp packet inside outbound ethernet frame
tcp_src_port	= 0 ;offset of source port field in tcp packet
tcp_dest_port	= 2 ;offset of destination port field in tcp packet
tcp_seq		= 4 ;offset of sequence number field in tcp packet
tcp_ack	= 8 ;offset of acknowledgement field in tcp packet
tcp_header_length	= 12 ;offset of header length field in tcp packet
tcp_flags_field	= 13 ;offset of flags field in tcp packet
tcp_window_size = 14 ; offset of window size field in tcp packet
tcp_checksum = 16 ; offset of checksum field in tcp packet
tcp_urgent_pointer = 18 ; offset of urgent pointer field in tcp packet
tcp_data=20   ;offset of data in tcp packet 

; virtual header
tcp_vh		= tcp_outp - 12
tcp_vh_src	= 0
tcp_vh_dest	= 4
tcp_vh_zero	= 8
tcp_vh_proto	= 9
tcp_vh_len	= 10

;
tcp_flag_FIN  =1
tcp_flag_SYN  =2
tcp_flag_RST  =4
tcp_flag_PSH  =8
tcp_flag_ACK  =16
tcp_flag_URG  =32




.segment "TCP_VARS"
tcp_state:  .res 1
tcp_local_port: .res 2
tcp_remote_port: .res 2
tcp_remote_ip: .res 4
tcp_sequence_number: .res 4
tcp_ack_number: .res 4
tcp_data_ptr: .res 2
tcp_data_len: .res 2
tcp_send_data_ptr: .res 2
tcp_send_data_len: .res 2 ;length (in bytes) of data to be sent over tcp connection
tcp_callback: .res 2 ;vector to routine to be called when data is received over tcp connection
tcp_flags: .res 1
tcp_fin_sent: .res 1

tcp_listen_port: .res 2

tcp_inbound_data_ptr: .res 2 ;pointer to data just recieved over tcp connection
tcp_inbound_data_length: .res 2 ;length of data just received over tcp connection
;(if this is $ffff, that means "end of file", i.e. remote end has closed connection)
tcp_connect_sequence_number: .res 4   ;the seq number we will next send out
tcp_connect_expected_ack_number: .res 4 ;what we expect to see in the next inbound ack
tcp_connect_ack_number: .res 4 ;what we will next ack
tcp_connect_last_received_seq_number: .res 4 ;the seq field in the last inbound packet for this connection
tcp_connect_last_ack: .res 4 ;ack field in the last inbound packet for this connection
tcp_connect_local_port: .res 2 ;
tcp_connect_remote_port: .res 2
tcp_connect_ip: .res 4 ;ip address of remote server to connect to


tcp_timer:  .res 1
tcp_loop_count: .res 1
tcp_packet_sent_count: .res 1


.code

; initialize tcp
;called automatically by ip_init if "ip.s" was compiled with -DTCP
; inputs: none
; outputs: none
tcp_init:
  
  rts


jmp_to_callback:
  jmp (tcp_callback)

;listen for an inbound tcp connection
;this is a 'blocking' call, i.e. it will not return until a connection has been made
;inputs:
; AX: destination port (2 bytes)
; tcp_callback: vector to call when data arrives on this connection
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_listen:
  stax  tcp_listen_port
  lda #tcp_cxn_state_listening
  sta tcp_state
  lda #0  ;reset the "packet sent" counter
  sta tcp_packet_sent_count
  sta tcp_fin_sent
  
  ;set the low word of seq number to $0000, high word to something random
  sta tcp_connect_sequence_number
  sta tcp_connect_sequence_number+1
  jsr ip65_random_word
  stax  tcp_connect_sequence_number+2
  jsr set_expected_ack;       ;due to various ugly hacks, the 'expected ack' value is now what is put into the 'SEQ' field in outbound packets 
@listen_loop:
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  rts
@no_abort:  
  lda #tcp_cxn_state_listening  
  cmp tcp_state
  beq @listen_loop
    
  jmp tcp_connection_established
  rts

;make outbound tcp connection
;inputs:
; tcp_connect_ip:  destination ip address (4 bytes)
; AX: destination port (2 bytes)
; tcp_callback: vector to call when data arrives on this connection
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_connect:
  stax  tcp_connect_remote_port
  jsr ip65_random_word
  stax  tcp_connect_local_port
  lda #tcp_cxn_state_syn_sent
  sta tcp_state
  lda #0  ;reset the "packet sent" counter
  sta tcp_packet_sent_count
  sta tcp_fin_sent
  
  ;set the low word of seq number to $0000, high word to something random
  sta tcp_connect_sequence_number
  sta tcp_connect_sequence_number+1
  jsr ip65_random_word
  stax  tcp_connect_sequence_number+2
  
  
@tcp_polling_loop:

  ;create a SYN packet
  lda #tcp_flag_SYN
  sta tcp_flags
  lda  #0
  sta  tcp_data_len
  sta  tcp_data_len+1
  
	ldx #3				; 
:	lda tcp_connect_ip,x
	sta tcp_remote_ip,x
  lda tcp_connect_sequence_number,x
  sta tcp_sequence_number,x
	dex
	bpl :-
  ldax  tcp_connect_local_port
  stax  tcp_local_port  
  ldax  tcp_connect_remote_port
  stax  tcp_remote_port
  
  jsr tcp_send_packet
  lda tcp_packet_sent_count
  adc #1
  sta tcp_loop_count       ;we wait a bit longer between each resend  
@outer_delay_loop: 
  jsr timer_read
  stx tcp_timer            ;we only care about the high byte  
@inner_delay_loop:  
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  rts
@no_abort:  
  lda tcp_state  
  cmp #tcp_cxn_state_syn_sent
  bne @got_a_response

  jsr timer_read
  cpx tcp_timer            ;this will tick over after about 1/4 of a second
  beq @inner_delay_loop
  
  dec tcp_loop_count
  bne @outer_delay_loop  

  
	inc tcp_packet_sent_count
  lda tcp_packet_sent_count
  cmp #MAX_TCP_PACKETS_SENT-1
  bpl @too_many_messages_sent
  jmp @tcp_polling_loop

@too_many_messages_sent:
@failed:
  lda #tcp_cxn_state_closed
  sta tcp_state
  lda #KPR_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error  
  sec             ;signal an error
  rts
@got_a_response:
  lda tcp_state  
  cmp #tcp_cxn_state_closed
  bne @was_accepted
  sec     ;if we got here, then the other side sent a RST or FIN, so signal an error to the caller
  rts
@was_accepted:
tcp_connection_established:
;inc the sequence number to cover the SYN we have sent
  ldax  #tcp_connect_sequence_number
  stax  acc32
  ldax  #$01
  jsr add_16_32

set_expected_ack:
;set the expected ack number with current seq number
	ldx #3				; 
:	lda tcp_connect_sequence_number,x
  sta tcp_connect_expected_ack_number,x
	dex
	bpl :-

  clc
  rts

tcp_close:
;close the current connection
;inputs:
;   none
;outputs:
;   carry flag is set if an error occured, clear otherwise


	lda tcp_state
  cmp #tcp_cxn_state_established
  beq :+
@connection_closed:  
  lda #tcp_cxn_state_closed
  sta tcp_state
  clc
  rts
:  
  ;increment the expected sequence number for the SYN we are about to send
  ldax #tcp_connect_expected_ack_number
  stax acc32
  ldax #1
  sta tcp_fin_sent
  jsr add_16_32


@send_fin_loop:
  lda #tcp_flag_FIN+tcp_flag_ACK
  sta tcp_flags
  ldax  #0
  stax  tcp_data_len
	ldx #3				; 
:	lda tcp_connect_ip,x
	sta tcp_remote_ip,x
  lda tcp_connect_ack_number,x
  sta tcp_ack_number,x
  lda tcp_connect_sequence_number,x
  sta tcp_sequence_number,x
	dex
	bpl :-
  ldax  tcp_connect_local_port
  stax  tcp_local_port  
  ldax  tcp_connect_remote_port
  stax  tcp_remote_port  
  
  jsr tcp_send_packet

  lda tcp_packet_sent_count
  adc #1
  sta tcp_loop_count       ;we wait a bit longer between each resend  
@outer_delay_loop: 
  jsr timer_read
  stx tcp_timer            ;we only care about the high byte  
@inner_delay_loop:  
  jsr ip65_process
  lda tcp_state
  cmp #tcp_cxn_state_established
  bne @connection_closed

  jsr timer_read
  cpx tcp_timer            ;this will tick over after about 1/4 of a second
  beq @inner_delay_loop
  
  dec tcp_loop_count
  bne @outer_delay_loop  
  
	inc tcp_packet_sent_count
  lda tcp_packet_sent_count
  cmp #MAX_TCP_PACKETS_SENT-1
  bpl @too_many_messages_sent
  jmp @send_fin_loop
@too_many_messages_sent:
@failed:
  lda #tcp_cxn_state_closed
  sta tcp_state
  lda #KPR_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error  
  sec             ;signal an error
  rts



;send a string over the current tcp connection
;inputs:
;   tcp connection should already be opened
;   AX: pointer to buffer - data up to (but not including)
; the first nul byte will be sent. max of 255 bytes will be sent.
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_send_string:
  stax tcp_send_data_ptr
  stax copy_src
  lda #0
  tay
  sta tcp_send_data_len
  sta tcp_send_data_len+1
  lda (copy_src),y
  bne @find_end_of_string
  rts ; if the string is empty, don't send anything!
@find_end_of_string:  
  lda (copy_src),y
  beq @done  
  inc tcp_send_data_len
  iny
  bne @find_end_of_string
@done:  
  ldax tcp_send_data_ptr
  ;now we can fall through into tcp_send
  

;send tcp data
;inputs:
;   tcp connection should already be opened
;   tcp_send_data_len: length of data to send (exclusive of any headers)
;   AX: pointer to buffer containing data to be sent
;outputs:
;   carry flag is set if an error occured, clear otherwise  
tcp_send:

  stax tcp_send_data_ptr
  
	lda tcp_state
  cmp #tcp_cxn_state_established
  beq @connection_established
  lda #KPR_ERROR_CONNECTION_CLOSED
  sta ip65_error
  sec
  rts
  lda #0  ;reset the "packet sent" counter
  sta tcp_packet_sent_count

@connection_established:
  ;increment the expected sequence number
  ldax #tcp_connect_expected_ack_number
  stax acc32
  ldax tcp_send_data_len
  jsr add_16_32
  

@tcp_polling_loop:

  ;create a data packet
  lda #tcp_flag_ACK+tcp_flag_PSH
  sta tcp_flags
  ldax tcp_send_data_len
  stax tcp_data_len
  
  ldax tcp_send_data_ptr
  stax tcp_data_ptr
  
	ldx #3				; 
:	lda tcp_connect_ip,x
	sta tcp_remote_ip,x
  lda tcp_connect_sequence_number,x
  sta tcp_sequence_number,x

	dex
	bpl :-
  ldax  tcp_connect_local_port
  stax  tcp_local_port  
  ldax  tcp_connect_remote_port
  stax  tcp_remote_port
  
	
  jsr tcp_send_packet
  lda tcp_packet_sent_count
  adc #1
  sta tcp_loop_count       ;we wait a bit longer between each resend  
@outer_delay_loop: 
  jsr timer_read
  stx tcp_timer            ;we only care about the high byte  
@inner_delay_loop:  
  jsr ip65_process
  jsr check_for_abort_key
  bcc @no_abort
  lda #KPR_ERROR_ABORTED_BY_USER
  sta ip65_error
  lda #tcp_cxn_state_closed
  sta tcp_state
  
  rts
@no_abort:  
  ldax #tcp_connect_last_ack
  stax acc32
  ldax #tcp_connect_expected_ack_number
  stax op32
  jsr cmp_32_32
  beq @got_ack

  jsr timer_read
  cpx tcp_timer            ;this will tick over after about 1/4 of a second
  beq @inner_delay_loop
  
  dec tcp_loop_count
  bne @outer_delay_loop  

  
	inc tcp_packet_sent_count
  lda tcp_packet_sent_count
  cmp #MAX_TCP_PACKETS_SENT-1
  bpl @too_many_messages_sent
  jmp @tcp_polling_loop

@too_many_messages_sent:
@failed:

  lda #tcp_cxn_state_closed
  sta tcp_state
  lda #KPR_ERROR_TIMEOUT_ON_RECEIVE
  sta ip65_error  
  sec             ;signal an error
  rts
@got_ack: 
  ;finished - now we need to advance the sequence number for the data we just sent
  ldax #tcp_connect_sequence_number
  stax acc32
  ldax tcp_send_data_len
  jsr add_16_32

  clc
  rts


;send a single tcp packet 
;inputs:
; tcp_remote_ip: IP address of destination server
; tcp_remote_port: destination tcp port 
; tcp_local_port: source tcp port
; tcp_flags: 6 bit flags
; tcp_data_ptr: pointer to data to include in this packet
; tcp_data_len: length of data pointed at by tcp_data_ptr
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_send_packet:
  ldax  tcp_data_ptr
  stax copy_src			; copy data to output buffer
	ldax #tcp_outp + tcp_data
	stax copy_dest
	ldax tcp_data_len
	jsr copymem

	ldx #3				; copy virtual header addresses
:	lda tcp_remote_ip,x
	sta tcp_vh + tcp_vh_dest,x	; set virtual header destination
	lda cfg_ip,x
	sta tcp_vh + tcp_vh_src,x	; set virtual header source
	dex
	bpl :-

	lda tcp_local_port		; copy source port
	sta tcp_outp + tcp_src_port + 1
	lda tcp_local_port + 1
	sta tcp_outp + tcp_src_port

	lda tcp_remote_port		; copy destination port
	sta tcp_outp + tcp_dest_port + 1
	lda tcp_remote_port + 1
	sta tcp_outp + tcp_dest_port

  ldx #3				; copy sequence and ack (if ACK flag set) numbers (in reverse order)
  ldy #0
:	lda tcp_sequence_number,x
	sta tcp_outp + tcp_seq,y
  lda #tcp_flag_ACK
  bit tcp_flags
  bne @ack_set 
  lda #0
  beq @sta_ack
  @ack_set:
	lda tcp_ack_number,x
  @sta_ack:
	sta tcp_outp + tcp_ack,y
  iny
	dex
	bpl :-

  lda #$50    ;4 bit header length in 32bit words + 4 bits of zero
  sta tcp_outp+tcp_header_length
  lda tcp_flags
  sta tcp_outp+tcp_flags_field
  
	lda #ip_proto_tcp
	sta tcp_vh + tcp_vh_proto

  ldax  #$0010  ;$1000 in network byte order
  stax  tcp_outp+tcp_window_size

	lda #0				; clear checksum
	sta tcp_outp + tcp_checksum
	sta tcp_outp + tcp_checksum + 1
	sta tcp_vh + tcp_vh_zero	; clear virtual header zero byte

	ldax #tcp_vh			; checksum pointer to virtual header
	stax ip_cksum_ptr

	lda tcp_data_len		; copy length + 20
	clc
	adc #20
	sta tcp_vh + tcp_vh_len + 1	; lsb for virtual header
	tay
	lda tcp_data_len + 1
	adc #0
	sta tcp_vh + tcp_vh_len		; msb for virtual header

	tax				; length to A/X
	tya

	clc				; add 12 bytes for virtual header
	adc #12
	bcc :+
	inx
:
	jsr ip_calc_cksum		; calculate checksum
	stax tcp_outp + tcp_checksum

	ldx #3				; copy addresses
:	lda tcp_remote_ip,x
	sta ip_outp + ip_dest,x		; set ip destination address
	dex
	bpl :-

	jsr ip_create_packet		; create ip packet template

	lda tcp_data_len 	; ip len = tcp data length +20 byte ip header + 20 byte tcp header
	ldx tcp_data_len +1
	clc
	adc #40 
	bcc :+
	inx
:	sta ip_outp + ip_len + 1	; set length
	stx ip_outp + ip_len

	ldax #$1234    			; set ID
	stax ip_outp + ip_id

	lda #ip_proto_tcp		; set protocol
	sta ip_outp + ip_proto

	jmp ip_send			; send packet, sec on error



check_current_connection:
;see if the ip packet we just got is for a valid (non-closed) tcp connection
;inputs:
; eth_inp: should contain an ethernet frame encapsulating an inbound tcp packet
;outputs:
; carry flag clear if inbound tcp packet part of existing connection

  
  lda tcp_state
  cmp #tcp_cxn_state_closed
  bne @connection_not_closed
  sec
  rts
@connection_not_closed:  
  ldax  #ip_inp+ip_src
  stax  acc32
  ldax  #tcp_connect_ip
  stax  op32
  jsr   cmp_32_32
  beq @remote_ip_matches
  
  sec
  rts
@remote_ip_matches:
  ldax  tcp_inp+tcp_src_port
  stax  acc16
  lda   tcp_connect_remote_port+1 ;this value in reverse byte order to how it is presented in the TCP header
  ldx   tcp_connect_remote_port 
  jsr   cmp_16_16
  beq @remote_port_matches
  sec
  rts
@remote_port_matches:
  ldax  tcp_inp+tcp_dest_port
  stax  acc16
  lda   tcp_connect_local_port+1 ;this value in reverse byte order to how it is presented in the TCP header
  ldx   tcp_connect_local_port 
  jsr   cmp_16_16
  beq   @local_port_matches
  sec
  rts
@local_port_matches:
  clc
  rts
  
;process incoming tcp packet
;called automatically by ip_process if "ip.s" was compiled with -DTCP
;inputs:
; eth_inp: should contain an ethernet frame encapsulating an inbound tcp packet
;outputs:
; none but if connection was found, an outbound message may be created, overwriting eth_outp
; also tcp_state and other tcp variables may be modified
tcp_process:
  
  lda #tcp_flag_RST
  bit tcp_inp+tcp_flags_field
  beq @not_reset
  jsr check_current_connection
  bcs @not_current_connection_on_rst  
  ;for some reason, search.twitter.com is sending RSTs with ID=$1234 (i.e. echoing the inbound ID)
  ;but then keeps the connection open and ends up sending the file.
  ;so lets ignore a reset with ID=$1234
  lda ip_inp+ip_id
  cmp #$34
  bne @not_invalid_reset
  lda ip_inp+ip_id+1
  cmp #$12  
  bne @not_invalid_reset
  jmp @send_ack
@not_invalid_reset:
  ;connection has been reset so mark it as closed    
  lda #tcp_cxn_state_closed
  sta tcp_state
  lda #KPR_ERROR_CONNECTION_RESET_BY_PEER
  sta ip65_error
  
  lda #$ff
  sta tcp_inbound_data_length
  sta tcp_inbound_data_length+1
  jsr jmp_to_callback   ;let the caller see the connection has closed
  
@not_current_connection_on_rst:
  ;if we get a reset for a closed or nonexistent connection, then ignore it  
  rts
@not_reset:
  lda tcp_inp+tcp_flags_field
  cmp #tcp_flag_SYN+tcp_flag_ACK
  bne @not_syn_ack
  
  ;it's a SYN/ACK
  jsr check_current_connection
  bcc @current_connection_on_syn_ack
  ;if we get a SYN/ACK for something that aint the connection we're expecting, 
  ;terminate with extreme prejudice
  jmp @send_rst 
@current_connection_on_syn_ack:  
  lda tcp_state
  cmp #tcp_cxn_state_syn_sent
  bne @not_expecting_syn_ack
  ;this IS the syn/ack we are waiting for :-)
  ldx #3				; copy sequence number to ack (in reverse order)
  ldy #0
:	lda tcp_inp + tcp_seq,y
	sta tcp_connect_ack_number,x
  iny
	dex
	bpl :-

  ldax #tcp_connect_ack_number
  stax acc32
  ldax  #$0001  ;
  jsr add_16_32 ;increment the ACK counter by 1, for the SYN we just received


  lda #tcp_cxn_state_established
  sta tcp_state
  
@not_expecting_syn_ack:   
;we get a SYN/ACK for the current connection,
;but we're not expecting it, it's probably
;a retransmist - just ACK it
  jmp @send_ack
  
  
@not_syn_ack:  

;is it an ACK - alone or with PSH/URGENT but not a SYN/ACK?
  lda #tcp_flag_ACK
  bit tcp_inp+tcp_flags_field
  bne @ack
  jmp @not_ack
@ack:  
  ;is this the current connection?
  jsr check_current_connection
  bcc @current_connection_on_ack
  ;if we get an ACK for something that is not the current connection
  ;we should send a RST
  jmp @send_rst
@current_connection_on_ack:
  ;if it's an ACK, then record the last ACK (reorder the bytes in the process)
  ldx #3				; copy seq & ack fields (in reverse order)
  ldy #0
:	lda tcp_inp + tcp_ack,y
  sta tcp_connect_last_ack,x
  lda tcp_inp + tcp_seq,y
  sta tcp_connect_last_received_seq_number,x
  iny
	dex
	bpl :-
  
  ;was this the next sequence number we're waiting for?
  ldax  #tcp_connect_ack_number
  stax  acc32
  ldax  #tcp_connect_last_received_seq_number
  stax  op32
  jsr   cmp_32_32
  
  bne   @not_expected_seq_number


  
  ;what is the size of data in this packet?
  lda ip_inp+ip_len+1 ;payload length (lo byte)
  sta acc16
  lda ip_inp+ip_len ;payload length (hi byte)
  sta acc16+1
  lda tcp_inp+tcp_header_length   ;high 4 bits is header length in 32 bit words
  lsr ; A=A/2
  lsr ; A=A/2
  clc ; A now equal to tcp header length in bytes
  adc #20 ;add 20 bytes for IP header. this gives length of IP +TCP headers
  ldx #0
  sta tcp_header_length
  jsr sub_16_16
  
  ;acc16 now contains the length of data in this TCP packet
  
  lda acc16
  sta tcp_inbound_data_length
  lda acc16+1
  sta tcp_inbound_data_length+1
  bne @not_empty_packet
  lda acc16
  bne @not_empty_packet
  jmp @empty_packet  
@not_empty_packet:
  
  
  ;calculate ptr to tcp data
  clc
  lda tcp_header_length
  adc #<ip_inp
  sta tcp_inbound_data_ptr
  lda #>ip_inp
  adc #0
  sta tcp_inbound_data_ptr+1
  
  ;  do a callback
  jsr jmp_to_callback
  
    
  ; move ack ptr along
  ldax #tcp_connect_ack_number
  stax acc32
  ldax tcp_inbound_data_length
  jsr add_16_32 
  
  
@not_expected_seq_number: ;send an ACK with the sequence number we expect  

  ;send the ACK for any data in this packet, then return to check for FIN flag
  jsr @send_ack 

@not_ack: 
@empty_packet:  

;is it a FIN?  
  lda #tcp_flag_FIN
  bit tcp_inp+tcp_flags_field
  bne @fin
  jmp @not_fin
@fin:  
  ;is this the current connection?
  jsr check_current_connection
  bcc :+
  jmp @send_rst ;reset if not current connection
:  
  ldx #3				; copy seq field (in reverse order)
  ldy #0
:	lda tcp_inp + tcp_seq,y
  sta tcp_connect_last_received_seq_number,x
  iny
	dex
	bpl :-
  
  ;was this the next sequence number we're waiting for?
  ldax  #tcp_connect_ack_number
  stax  acc32
  ldax  #tcp_connect_last_received_seq_number
  stax  op32
  jsr   cmp_32_32
  
  beq :+
  rts ;bail if not expected sequence number
:  

  ;set the length to $ffff
  lda #$ff
  sta tcp_inbound_data_length
  sta tcp_inbound_data_length+1
  jsr jmp_to_callback   ;let the caller see the connection has closed   
    

  lda #tcp_cxn_state_closed
  sta tcp_state

  ;send a FIN/ACK
  ; move ack ptr along for the inbound FIN
  ldax #tcp_connect_ack_number
  stax acc32
  ldax #$01
  sta  tcp_fin_sent
  jsr add_16_32

  ;if we've already sent a FIN then just send back an ACK 
  lda tcp_fin_sent
  beq @send_fin_ack
;if we get here, we've sent a FIN, and just received an inbound FIN.
;when we sent the fin, we didn't update the sequence number, since
;we want to use the old sequence on every resend of that FIN
;now that our fin has been ACKed, we need to inc the sequence number
;and then send another ACK.

  ldax #tcp_connect_sequence_number
  stax acc32
  ldax  #$0001  ;
  jsr add_16_32 ;increment the SEQ counter by 1, for the FIN we have been sending

  lda #tcp_flag_ACK  
  jmp @send_packet
  
@send_fin_ack:  
 
  lda #tcp_flag_FIN+tcp_flag_ACK
  
  jmp @send_packet

  
@not_fin:

  lda tcp_inp+tcp_flags_field
  cmp #tcp_flag_SYN
  beq @syn 
  jmp @not_syn
@syn:  
  
  ;is this the port we are listening on?
  lda tcp_inp+tcp_dest_port+1
	cmp tcp_listen_port
  bne @decline_syn_with_reset
  lda tcp_inp+tcp_dest_port
	cmp tcp_listen_port+1
  bne @decline_syn_with_reset
  
  ;it's the right port - are we actually waiting for a connecting?
  lda #tcp_cxn_state_listening  
  cmp tcp_state  
  beq @this_is_connection_we_are_waiting_for
  ;is this the current connection? that would mean our ACK got lost, so resend
  jsr check_current_connection
  bcc @this_is_connection_we_are_waiting_for
  
  rts ;if we've currently got a connection open, then ignore any new requests
      ;the sender will timeout and resend the SYN, by which time we may be
      ;ready to accept it again.
  
@this_is_connection_we_are_waiting_for:

  ; copy sequence number to ack (in reverse order) and remote IP
  ldx #3				
  ldy #0
:	lda tcp_inp + tcp_seq,y
	sta tcp_connect_ack_number,x
  lda ip_inp+ip_src,x
  sta tcp_connect_ip,x
  iny
	dex
	bpl :-

  ;copy ports
  ldax tcp_listen_port
  stax tcp_connect_local_port
  
  lda tcp_inp+tcp_src_port+1
  sta tcp_connect_remote_port
  lda tcp_inp+tcp_src_port
  sta tcp_connect_remote_port+1

  lda #tcp_cxn_state_established
  sta tcp_state

  ldax #tcp_connect_ack_number 
  stax acc32
  ldax  #$0001  ;
  jsr add_16_32 ;increment the ACK counter by 1, for the SYN we just received
  lda #tcp_flag_SYN+tcp_flag_ACK
  jmp @send_packet
  
@decline_syn_with_reset:
;create a RST packet
  ldx #3				; copy sequence number to ack (in reverse order)
  ldy #0
:	lda tcp_inp + tcp_seq,y
	sta tcp_ack_number,x
  iny
	dex
	bpl :-

  ldax #tcp_ack_number 
  stax acc32
  ldax  #$0001  ;
  jsr add_16_32 ;increment the ACK counter by 1, for the SYN we just received
  
@send_rst:
  
  lda #tcp_flag_RST+tcp_flag_ACK
  sta tcp_flags
  ldax  #0
  stax  tcp_data_len
	ldx #3				; 
:	lda ip_inp+ip_src,x
	sta tcp_remote_ip,x
	dex
	bpl :-
  
  ;copy src/dest ports in inverted byte order
  lda tcp_inp+tcp_src_port
	sta tcp_remote_port+1
  lda tcp_inp+tcp_src_port+1
	sta tcp_remote_port
  
  lda tcp_inp+tcp_dest_port
	sta tcp_local_port+1
  lda tcp_inp+tcp_dest_port+1
	sta tcp_local_port
  
  jsr tcp_send_packet
  rts

@not_syn:
  rts

@send_ack:

;create an ACK packet
  lda #tcp_flag_ACK
  
@send_packet:  
  sta tcp_flags
  ldax  #0
  stax  tcp_data_len
	ldx #3				; 
:	lda tcp_connect_ip,x
	sta tcp_remote_ip,x
  lda tcp_connect_ack_number,x
  sta tcp_ack_number,x
;if we have just sent a packet out, we may not yet have updated tcp_connect_sequence_number yet
;so use current value of tcp_connect_expected_ack_number as outbound sequence number instead
  lda tcp_connect_expected_ack_number,x   
  sta tcp_sequence_number,x
	dex
	bpl :-
  ldax  tcp_connect_local_port
  stax  tcp_local_port  
  ldax  tcp_connect_remote_port
  stax  tcp_remote_port
  
  
  jmp tcp_send_packet


;send an empty ACK packet on the current connection
;inputs:
;   none
;outputs:
;   carry flag is set if an error occured, clear otherwise
tcp_send_keep_alive=@send_ack

;-- LICENSE FOR tcp.s --
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
