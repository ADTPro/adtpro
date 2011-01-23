;routines for parsing a URL, and downloading an URL


.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

TIMEOUT_SECONDS=15

.import output_buffer
.importzp copy_src
.importzp copy_dest
.import copymem
.import timer_read
.import ip65_error
.import ip65_process
.import parser_init
.import parser_skip_next
.import dns_set_hostname
.import dns_resolve
.import parse_integer
.import dns_ip
.import tcp_connect
.import tcp_send_string
.import tcp_send_data_len
.import tcp_callback
.import tcp_close
.import tcp_connect_ip
.import tcp_inbound_data_length
.import tcp_inbound_data_ptr


.export  url_ip
.export  url_port
.export  url_selector
.export url_resource_type
.export url_parse
.export url_download
.export url_download_buffer
.export url_download_buffer_length
.export resource_download

target_string=copy_src
search_string=copy_dest
selector_buffer=output_buffer

.segment "TCP_VARS"

  url_string: .res 2 
  url_ip: .res 4    ;will be set with ip address of host in url
  url_port: .res 2 ;will be set with port number of url
  url_selector: .res 2 ;will be set with address of selector part of URL
  url_type: .res 1
  url_resource_type: .res 1
  url_type_unknown=0
  url_type_gopher=1
  url_type_http=2
  
  src_ptr: .res 1
  dest_ptr: .res 1
  timeout_counter: .res 1
  url_download_buffer: .res 2 ; points to a buffer that url will be downloaded into
  url_download_buffer_length: .res 2  ;length of buffer that url will be downloaded into

  temp_buffer: .res 2  
  temp_buffer_length: .res 2  

  download_flag: .res 1


.code


;parses a URL into a form that makes it easy to retrieve the specified resource
;inputs: 
;AX = address of URL string
;any control character (i.e. <$20) is treated as 'end of string', e.g. a CR or LF, as well as $00
;outputs:
; sec if a malformed url, otherwise:
; url_ip = ip address of host in url
; url_port = port number of url
; url_selector= address of selector part of URL
url_parse:
  stax url_string
  ldy #0
  sty url_type
  sty url_port
  sty url_port+1
  sty url_resource_type

  jsr skip_to_hostname
  bcc :+
  ldax url_string
  jmp @no_protocol_specifier
:  
  ldax url_string
  stax  search_string

  lda (search_string),y
  cmp  #'g'
  beq @gopher
  cmp  #'G'
  beq @gopher
  cmp  #'h'
  beq @http
  cmp  #'H'
  beq @http
@exit_with_error:  
  lda #KPR_ERROR_MALFORMED_URL 
  sta ip65_error
@exit_with_sec:  
  sec
  rts
@http:
  lda #url_type_http
  sta url_type
  lda #80
  sta url_port
  jmp @protocol_set
@gopher:
lda #url_type_gopher
  sta url_type
  lda #70
  sta url_port
@protocol_set:
  jsr skip_to_hostname
  ;now pointing at hostname
  bcs @exit_with_error
@no_protocol_specifier:  
  jsr dns_set_hostname
  bcs @exit_with_sec
  jsr dns_resolve
  bcc :+
  lda #KPR_ERROR_DNS_LOOKUP_FAILED
  sta ip65_error
  jmp @exit_with_sec
  :
  ;copy IP address
  ldx #3
:
  lda dns_ip,x
  sta url_ip,x
  dex
  bpl :-

  jsr skip_to_hostname
  
  ;skip over next colon
  ldax #colon
  jsr parser_skip_next
  bcs @no_port_in_url
  ;AX now point at first thing past a colon - should be a number:
  jsr  parse_integer
  stax url_port
@no_port_in_url:  
  ;skip over next slash
  ldax #slash
  jsr parser_skip_next
  ;AX now pointing at selector
  stax copy_src
  ldax #selector_buffer
  stax copy_dest
  lda #0
  sta src_ptr
  sta dest_ptr
  lda url_type
  
  cmp #url_type_gopher
  bne @not_gopher  
  ;first byte after / in a gopher url is the resource type  
  ldy src_ptr  
  lda (copy_src),y
  beq @start_of_selector  
  sta url_resource_type
  inc src_ptr  
  jmp @start_of_selector
@not_gopher:  
  cmp #url_type_http
  beq @build_http_request
  jmp @done ; if it's not gopher or http, we don't know how to build a selector
@build_http_request:  
  ldy #get_length-1
  sty dest_ptr
:
  lda get,y
  sta (copy_dest),y
  dey
  bpl :-  
  
@start_of_selector: 
  lda #'/'
  inc dest_ptr  
  jmp @save_first_byte_of_selector
@copy_one_byte:
  ldy src_ptr  
  lda (copy_src),y
  cmp #$20
  bcc @end_of_selector  ;any control char (including CR,LF, and $00) should be treated as end of URL
  inc src_ptr  
@save_first_byte_of_selector:  
  ldy dest_ptr  
  sta (copy_dest),y  
  inc dest_ptr
  bne @copy_one_byte
@end_of_selector:


  ldx #1 ;number of CRLF at end of gopher request
  lda url_type
  
  cmp #url_type_http
  bne @final_crlf
    
  ;now the HTTP version number & Host: field
  ldx #0
:
  lda http_preamble,x
  beq :+
  ldy dest_ptr
  inc dest_ptr
  sta (copy_dest),y  
  inx
  bne :-  
:

  
  ;now copy the host field
  jsr skip_to_hostname
  ;AX now pointing at hostname
  stax copy_src
  ldax #selector_buffer
  stax copy_dest

  lda #0
  sta src_ptr
  
@copy_one_byte_of_hostname:
  ldy src_ptr  
  lda (copy_src),y
  beq @end_of_hostname
  cmp #':'
  beq @end_of_hostname
  cmp #'/'
  beq @end_of_hostname
  inc src_ptr  
  ldy dest_ptr  
  sta (copy_dest),y  
  inc dest_ptr  
  bne @copy_one_byte_of_hostname
@end_of_hostname:
   
  ldx #2 ;number of CRLF at end of HTTP request
  
@final_crlf:
  ldy dest_ptr
  lda #$0d
  sta (copy_dest),y
  iny
  lda #$0a
  sta (copy_dest),y
  iny
  sty dest_ptr
  dex
  bne @final_crlf

@done:  
  lda #$00
  sta (copy_dest),y
  ldax #selector_buffer
  stax url_selector
  clc
  
  rts
  
skip_to_hostname:
  ldax url_string
  jsr parser_init
  ldax #colon_slash_slash
  jmp parser_skip_next
  


;download a resource specified by an URL
;inputs: 
;AX = address of URL string
; url_download_buffer - points to a buffer that url will be downloaded into
; url_download_buffer_length - length of buffer
;outputs:
; sec if an error occured, else buffer pointed at by url_download_buffer is filled with contents 
; of specified resource (with an extra 2 null bytes at the end),
; AX = length of resource downloaded.
url_download:
  jsr url_parse  
  bcc resource_download
  rts

;download a resource specified by ip,port & selector
;inputs: 
; url_ip = ip address of host to connect to
; url_port = port number of to connect to
; url_selector= address of selector to send to host after connecting
; url_download_buffer - points to a buffer that url will be downloaded into
; url_download_buffer_length - length of buffer
;outputs:
; sec if an error occured, else buffer pointed at by url_download_buffer is filled with contents 
; of specified resource (with an extra 2 null bytes at the end),
; AX = length of resource downloaded.
resource_download:
 
  ldax url_download_buffer
  stax temp_buffer
  ldax url_download_buffer_length
  stax temp_buffer_length
  jsr put_zero_at_end_of_dl_buffer
  
  ldx #3        ; save IP address just retrieved
: lda url_ip,x
  sta tcp_connect_ip,x
  dex
  bpl :-
  ldax #url_download_callback
  stax tcp_callback

  ldax url_port  
  jsr tcp_connect
  bcs @error

  ;connected, now send the selector
  ldx #0
  stx download_flag
  ldax url_selector
  
  jsr tcp_send_string
  jsr timer_read
  txa
  adc #TIMEOUT_SECONDS*4 ;what value should trigger the timeout?
  sta timeout_counter
  ;now loop until we're done
@download_loop:
  jsr ip65_process
  jsr timer_read
  cpx timeout_counter
  beq @timeout
  lda download_flag
  beq @download_loop
@timeout:  
  jsr tcp_close
  clc
@error:
  rts


  lda #KPR_ERROR_FILE_ACCESS_FAILURE
  sta ip65_error
  sec  
  rts
  
  
  url_download_callback:
  
  lda tcp_inbound_data_length+1
  cmp #$ff
  bne not_end_of_file
@end_of_file:  
  lda #1
  sta download_flag

put_zero_at_end_of_dl_buffer:
  ;put a zero byte at the end of the file 
  ldax temp_buffer  
  stax copy_dest
  lda #0  
  tay
  sta (copy_dest),y  
  rts
  
not_end_of_file:
;copy this chunk to our input buffer
  ldax temp_buffer
  stax copy_dest
  ldax tcp_inbound_data_ptr
  stax copy_src
  sec
  lda temp_buffer_length
  sbc tcp_inbound_data_length
  pha
  lda temp_buffer_length+1
  sbc tcp_inbound_data_length+1
  bcc @would_overflow_buffer
  sta temp_buffer_length+1
  pla 
  sta temp_buffer_length
  ldax tcp_inbound_data_length
  jsr  copymem  
;increment the pointer into the input buffer  
  clc
  lda temp_buffer
  adc tcp_inbound_data_length
  sta temp_buffer
  lda temp_buffer+1
  adc tcp_inbound_data_length+1
  sta temp_buffer+1  
  jmp put_zero_at_end_of_dl_buffer

@would_overflow_buffer:
  pla ;clean up the stack
  ldax temp_buffer_length
  jsr  copymem 
  lda temp_buffer
  adc temp_buffer_length
  sta temp_buffer
  lda temp_buffer+1
  adc temp_buffer_length+1
  sta temp_buffer+1  
  lda #0
  sta temp_buffer_length
  sta temp_buffer_length+1
  jmp put_zero_at_end_of_dl_buffer
  
  .rodata
  get: .byte "GET "
  get_length=4
  http_preamble: 
    .byte " HTTP/1.0",$0d,$0a
    .byte "User-Agent: IP65/"
    .include "../inc/version.i"
    .byte $0d,$0a
    .byte "Connection: close",$0d,$0a
    .byte  "Host: ",0
  
  colon_slash_slash: .byte ":/"
  slash: .byte "/",0
  colon: .byte ":",0
  
  


;-- LICENSE FOR url.s --
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
