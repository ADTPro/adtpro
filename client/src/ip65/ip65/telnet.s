;minimal telnet implementation (dumb terminal emulation only)
;to use:
;set the following variables - telnet_use_native_charset,telnet_port,telnet_ip
;then call telnet_connect
;you must also define (and export) these function
; telnet_menu - called whenever the F1 key is pressed.
; telnet_on_connection - called after succesful connection

.include "../inc/common.i"

  .import tcp_connect
  .import tcp_callback
  .import tcp_connect_ip
  .import tcp_listen
  .importzp KEYCODE_F1
  .import tcp_inbound_data_ptr
  .import tcp_inbound_data_length
  .import tcp_send
  .import tcp_send_data_len
  .import tcp_close
  .import print_a
  .import print_cr
  .import vt100_init_terminal
  .import vt100_process_inbound_char
  .import vt100_transform_outbound_char
  .import tcp_send_keep_alive
  .import timer_read

  .import ip65_process
  .import get_key_if_available
  .import get_filtered_input
  .import check_for_abort_key
  .import ok_msg
  .import failed_msg
  .import print
  .import print_errorcode
  .import native_to_ascii
  .import ascii_to_native

.export telnet_connect
.export telnet_use_native_charset
.export telnet_port
.export telnet_ip

.import telnet_menu
.import telnet_on_connection

.segment "IP65ZP" : zeropage

; pointer for moving through buffers
buffer_ptr:	.res 2			; source pointer

.code

;connect to a remote telnet server
;inputs:
;telnet_use_native_charset: set to 0 if remote server uses standard ASCII, 1 if remote server uses the 'native' charset (i.e. PETSCII)
;telnet_port: port number to connect to
;telnet_ip: ip address of remote server
telnet_connect:
  lda telnet_use_native_charset
  bne :+
  jsr vt100_init_terminal
:  
  ldax #telnet_callback
  stax tcp_callback
  ldx #3
@copy_dest_ip:
  lda telnet_ip,x
  sta tcp_connect_ip,x
  dex  
  bpl @copy_dest_ip
  
  ldax telnet_port
  jsr tcp_connect

  bcc @connect_ok 
  jsr print_cr
  ldax #failed_msg
  jsr print
  jsr print_cr
  jsr print_errorcode
  rts
@connect_ok:
  
  jsr telnet_on_connection
  
  ldax #ok_msg
  jsr print
  jsr print_cr
  lda #0
  sta connection_closed
  sta iac_response_buffer_length      
    
@main_polling_loop:

  jsr check_for_abort_key
  bcc	@no_abort
  jsr	tcp_close
  jmp 	@disconnected
  
@no_abort:
  jsr timer_read
  txa
  adc #$20  ;32 x 1/4 = ~ 8seconds
  sta telnet_timeout
@wait_for_keypress:  
  jsr timer_read
  cpx telnet_timeout
  bne @no_timeout
  jsr tcp_send_keep_alive
  jmp @main_polling_loop
@no_timeout:  
  jsr ip65_process
  lda connection_closed
  beq @not_disconnected
@disconnected:  
  ldax #disconnected
  jsr print
  rts
@not_disconnected:
  lda iac_response_buffer_length  
  beq @no_iac_response
  ldx #0
  stax tcp_send_data_len
  stx iac_response_buffer_length  
  ldax  #iac_response_buffer
  jsr tcp_send
@no_iac_response:
  
  
  
  jsr get_key_if_available
  beq @wait_for_keypress

  cmp #KEYCODE_F1
  bne @not_telnet_menu
  jsr telnet_menu
  jmp @main_polling_loop
@not_telnet_menu:

  ldx #0
  stx tcp_send_data_len
  stx tcp_send_data_len+1

  ldx telnet_use_native_charset
  bne @no_conversion_required
  
  
  jsr vt100_transform_outbound_char

  sta temp_a
  tya
  bne :+ 
  jmp @main_polling_loop  ;Y=0 means nothing to send
:  
  
  cmp #2
  beq :+
  lda temp_a
  jmp @no_conversion_required
:  


  lda temp_a
  stax buffer_ptr
  ldy #0  
:
  lda (buffer_ptr),y
  beq @send_char
  sta scratch_buffer,y
  inc tcp_send_data_len
  iny
  bne :-  
  jmp @send_char
  
@no_conversion_required:
  ldy tcp_send_data_len
  sta scratch_buffer,y
  inc tcp_send_data_len
  
@send_char:

  ldax  #scratch_buffer
  jsr tcp_send
  bcs @error_on_send
  jmp @main_polling_loop

@error_on_send:
  ldax #transmission_error
  jsr print
  jmp print_errorcode
 

;tcp callback - will be executed whenever data arrives on the TCP connection
telnet_callback:
  
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne @not_eof
  lda #1
  sta connection_closed
  rts
@not_eof:
  
  ldax tcp_inbound_data_ptr
  stax buffer_ptr
  lda tcp_inbound_data_length
  sta buffer_length
  lda tcp_inbound_data_length+1
  sta buffer_length+1
  
@next_byte:
  ldy #0
  lda (buffer_ptr),y
  tax
  lda telnet_use_native_charset
  beq :+
  jmp  @no_conversion_req
:

;if we get here, we are in ASCII 'char at a time' mode,  so look for (and process) Telnet style IAC bytes
  lda telnet_state
  cmp #telnet_state_got_command
  bne :+
  jmp @waiting_for_option
:  
  cmp #telnet_state_got_iac
  beq @waiting_for_command
  cmp #telnet_state_got_suboption
  beq @waiting_for_suboption_end
; we must be in 'normal' mode
  txa
  cmp #255
  beq :+
  jmp @not_iac
:  
  lda #telnet_state_got_iac
  sta telnet_state
  jmp @byte_processed

@waiting_for_suboption_end:
  txa 
  
  ldx iac_suboption_buffer_length  
  sta iac_suboption_buffer,x
  inc iac_suboption_buffer_length
  cmp #$f0  ;SE - suboption end
  bne @exit_suboption

  lda #telnet_state_normal  
  sta telnet_state
  lda iac_suboption_buffer
  cmp #$18
  bne @not_terminal_type

  ldx #0
:  
  lda terminal_type_response,x
  ldy iac_response_buffer_length
  inc iac_response_buffer_length
  sta iac_response_buffer,y
  inx 
  txa
  cmp #terminal_type_response_length
  bne :-
  
@not_terminal_type:

@exit_suboption:
  jmp @byte_processed
@waiting_for_command:
  txa
  sta telnet_command
  cmp #$fa ; SB - suboption begin
  beq @suboption
  cmp #$fb ;WILL 
  beq @option
  cmp #$fc ;WONT
  beq @option
  cmp #$fd ; DO
  beq @option
  cmp #$fe ;DONT
  beq @option
;we got a command we don't understand - just ignore it  
  lda #telnet_state_normal  
  sta telnet_state
  jmp @byte_processed
@suboption:
  
  lda #telnet_state_got_suboption
  sta telnet_state
  lda #0
  sta iac_suboption_buffer_length
  jmp @byte_processed
  
@option:
  lda #telnet_state_got_command
  sta telnet_state
  jmp @byte_processed

@waiting_for_option:
;we have now got IAC, <command>, <option>
  txa 
  sta telnet_option  
  lda telnet_command
  
  cmp #$fb
  beq @iac_will

  cmp #$fc
  beq @iac_wont

  cmp #$fe
  beq @iac_dont

  ;if we get here, then it's a "do" 
  
  
  lda telnet_option
  
  cmp #$18  ;terminal type
  beq @do_terminaltype
  
  cmp #$1f
  beq @do_naws


  ;if we get here, then it's a "do" command we don't honour

@iac_dont:
  lda #$fc ;wont
@add_iac_response:  
  ldx iac_response_buffer_length
  sta iac_response_buffer+1,x
  lda #255
  sta iac_response_buffer,x
  lda telnet_option
  sta iac_response_buffer+2,x

  inc iac_response_buffer_length
  inc iac_response_buffer_length
  inc iac_response_buffer_length
@after_set_iac_response:  
  lda #telnet_state_normal
  sta telnet_state
  jmp @byte_processed
@iac_will:
  lda telnet_option
  cmp #$01 ;ECHO
  beq @will_echo  
  cmp #$03 ;DO SUPPRESS GA
  beq @will_suppress_ga

@iac_wont:  
  lda #$fe ;dont
  jmp @add_iac_response
  
@will_echo:
  lda #$fd ;DO
  jmp @add_iac_response
  
@will_suppress_ga:
  lda #$fd ;DO
  jmp @add_iac_response

@do_naws:  
  ldx #0
:  
  lda naws_response,x
  ldy iac_response_buffer_length
  inc iac_response_buffer_length
  sta iac_response_buffer,y
  inx 
  txa
  cmp #naws_response_length
  bne :-
    
  jmp @after_set_iac_response

@do_terminaltype:
  lda #$fb ;WILL
  jmp @add_iac_response


@not_iac:
@convert_to_native:
  txa  
  jsr vt100_process_inbound_char
  jmp @byte_processed
@no_conversion_req:
  txa  
  jsr print_a
@byte_processed:  
  inc buffer_ptr
  bne :+
  inc buffer_ptr+1
:  
  lda buffer_length+1
  beq @last_page
  lda buffer_length
  bne @not_end_of_page
  dec buffer_length+1
@not_end_of_page:  
  dec buffer_length  
  jmp @next_byte
@last_page:
  dec buffer_length
  beq @finished
  
  jmp @next_byte

@finished:  
  
  rts
  
;constants
closing_connection: .byte "CLOSING CONNECTION",13,0
disconnected: .byte 13,"CONNECTION CLOSED",13,0
transmission_error: .byte "ERROR WHILE SENDING ",0

;initial_telnet_options:
;  .byte $ff,$fb,$1F   ;IAC WILL NAWS
;  .byte $ff,$fb,$18   ;IAC WILL TERMINAL TYPE
  
;initial_telnet_options_length=*-initial_telnet_options

terminal_type_response:
  .byte $ff ; IAC
  .byte $fa; SB
  .byte  $18 ; TERMINAL TYPE
  .byte $0 ; IS
  .byte "vt100" ;what we pretend to be
  .byte $ff ; IAC
  .byte $f0 ; SE
terminal_type_response_length=*-terminal_type_response


naws_response:
  .byte $ff,$fb,$1F   ;IAC WILL NAWS
  .byte $ff ; IAC
  .byte $fa; SB
  .byte  $1F ; NAWS
  .byte $00 ;  width (high byte)
  .byte 40 ;  width (low byte)
  .byte $00 ;  height (high byte)
  .byte 25 ;  height (low byte)
  
  .byte $ff ; IAC
  .byte $f0 ; SE

naws_response_length=*-naws_response


;variables
.segment "APP_SCRATCH" 
telnet_ip:  .res 4  ;ip address of remote server
telnet_port: .res 2 ;port number to connect to
telnet_timeout: .res 1
connection_closed: .res 1
telnet_use_native_charset: .res 1 ; 0 means all data is translated to/from NVT ASCII 
buffer_offset: .res 1
telnet_command: .res 1
telnet_option: .res 1

telnet_state_normal = 0
telnet_state_got_iac = 1
telnet_state_got_command = 2
telnet_state_got_suboption=3

buffer_length: .res 2

telnet_state: .res 1
temp_a: .res 1
iac_response_buffer: .res 64
iac_response_buffer_length: .res 1
scratch_buffer : .res 40
iac_suboption_buffer: .res 64
iac_suboption_buffer_length: .res 1


;-- LICENSE FOR telnet.s --
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
