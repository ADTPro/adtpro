;routines for parsing a HTTP request
;to use - first call http_parse_request, then call http_get_value to get method name, path, and variable values
;NB - this routine uses the same buffer space and zero page locations as many other ip65 routines. so do not call
;other ip65 routines between the http_parse_request & http_get_value else odd things will happen.

.include "../inc/common.i"

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif


.export http_parse_request
.export http_get_value
.export http_variables_buffer

.importzp copy_src
.importzp copy_dest
.import output_buffer
.import parse_hex_digits
;reuse the copy_src zero page var
string_ptr = copy_src
table_ptr=copy_dest


.bss
var_name: .res 1
hex_digit: .res 1

.data
http_variables_buffer: .word $2800  ;work area for storing variables extracted from query string


.code


;split a HTTP request into method (e.g. GET or POST), the path, and any querystring variables
;NB only the first letter in a variable name is significant. i.e.  if a querystring contains variables 'a','alpha' & 'alabama', only the first one in will be retreivable.
;the method is stored in var $01
;the path is stored in var $02
;for example, parsing "GET /goober?a=foo&alpha=beta" would result in:
;value of A when calling http_get_value              value returned by http_get_value
;        #$01                                        "GET"
;        #$02                                        "/goober"
;        #'a'                                        "foo"
;        #'A'                                        (error)
;inputs: 
;AX = pointer to HTTP request
;outputs:
; none - but values can be retrieved through subsequent calls to http_get_value
http_parse_request:
  stax string_ptr
  
  ldax http_variables_buffer
  
  stax  table_ptr

  lda #1  ;start of method
  ldy #0  
  jsr put_byte
  lda (string_ptr),y
  cmp #'/'
  beq @gopher
  jsr @check_end_of_string
  bcs @gopher
  lda (string_ptr),y
@extract_method:
  
  cmp #' '
  beq @end_of_method
  jsr @check_end_of_string
  bcc :+
  jmp  @done
:  
  jsr put_byte
  jsr get_next_byte_in_source
  jmp @extract_method

@gopher:
  jsr @output_end_of_method
  lda #'/' 
  jmp @got_path_char
@output_end_of_method:  
  lda #0  ;end of method
  jsr put_byte
  lda #2  ;start of path
  jmp put_byte

@end_of_method:
  jsr @output_end_of_method
  
@extract_path:
  jsr get_next_byte_in_source
  jsr @check_end_of_string
  bcs @done
  cmp #'?'
  beq @end_of_path
  cmp #'&'
  beq @end_of_path
@got_path_char:  
  jsr put_byte
  jmp @extract_path
@end_of_path:  
  lda #0  ;end of path
  jsr put_byte
  
@next_var:

  jsr get_next_byte_in_source
  jsr @check_end_of_string
  bcs @done
  jsr put_byte
  
  
  @skip_to_equals:
  jsr get_next_byte_in_source
  jsr @check_end_of_string
  bcs @done
  cmp #'?'
  beq @next_var
  cmp #'&'
  beq @next_var  
  cmp #'='
  beq @got_var
  jmp @skip_to_equals
  
@got_var:

  jsr get_next_byte_in_source
  jsr @check_end_of_string
  bcs @done
  cmp #'?'
  beq @end_of_var
  cmp #'&'
  beq @end_of_var
  
  cmp #'%'
  beq @get_percent_encoded_byte
  cmp #'+'
  bne :+
  lda #' '
:
@got_byte:
  jsr put_byte    
  jmp @got_var

@end_of_var:  
  lda #0
  jsr put_byte
  jmp @next_var
  
  
@done:
  lda #0
  jsr put_byte
  jsr put_byte
  rts

@check_end_of_string:
  cmp #0
  beq @end_of_string
  cmp #' '
  beq @end_of_string
  cmp #$0a
  beq @end_of_string
  cmp #$0d
  beq @end_of_string
  clc
  rts
@end_of_string:
  sec
  rts
  
@get_percent_encoded_byte:
  jsr get_next_byte_in_source
  tax
  jsr get_next_byte_in_source
  jsr parse_hex_digits
  jmp @got_byte
  
put_byte:
  sta (table_ptr),y
  inc table_ptr
  bne :+
  inc table_ptr+1
:
  rts

;retrieve the value of a variable defined in the previously parsed HTTP request.
;inputs: 
;A = variable to retrieve. 
; to get the method (GET/POST/HEAD), pass A=$01. 
; to get the path (everything between the method and the first '?'), pass A=$02. 
;outputs:
; if variable exists in HTTP request, carry flag will be clear and AX points to value (null terminated string)
; if variable did not exist, carry flag will be set.
http_get_value:
  sta var_name
  ldax http_variables_buffer
  stax string_ptr
  ldy #0

lda (string_ptr),y
@check_next_var:
  beq @end_of_vars
  cmp var_name
  beq @got_var
  ;not the var we want, so skip over till next byte
@skip_till_null_byte:
  jsr get_next_byte_in_source  
  bne @skip_till_null_byte
  jsr get_next_byte_in_source  
  bne @check_next_var
  
@end_of_vars:
  sec
  rts

@got_var:
  jsr get_next_byte_in_source
  ldax string_ptr
  clc
  rts
  
  
get_next_byte_in_source:
  inc string_ptr
  bne :+
  inc string_ptr+1
:
  lda (string_ptr),y
  rts




;-- LICENSE FOR http.s --
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
