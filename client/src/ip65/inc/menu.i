
;REQUIRES KEYCODES TO BE DEFINED

OPTIONS_PER_PAGE = $10
.bss

number_of_options: .res 2
current_option: .res 2
temp_option_counter: .res 2

first_option_this_page: .res 2
options_shown_this_page: .res 1
options_table_pointer: .res 2
jump_to_prefix: .res 1
last_page_flag: .res 1

get_current_byte: .res 4

convert_to_native: .res 1


.code


;on entry, AX should point to the list of null terminated option strings to be selected from
;Y should be 1 if menu items are in ASCII, 0 if they are in native char format
;on exit, AX points to the selected string
;carry is set of QUIT was selected, clear otherwise
select_option_from_menu:
  sty convert_to_native
  stax options_table_pointer
  stax get_current_byte+1
;set the 'LDA' and RTS' opcodes for the 'get current byte' subroutine, which is self-modified-code, hence must be located in RAM not ROM
  lda #$ad  ;opcode for LDA absolute
  sta get_current_byte
  lda #$60  ;opcode for RTS
  sta get_current_byte+3  

  lda #0
  sta current_option
  sta current_option+1
  sta number_of_options
  sta number_of_options+1


;count the number of options. this is done by scanning till we find a double zero, incrementing the count on each single zero
@count_strings:
  jsr @skip_past_next_null_byte
  inc number_of_options
  bne :+
  inc number_of_options+1
:
  jsr get_current_byte
  bne @count_strings 

 jmp @display_first_page_of_options

@skip_past_next_null_byte:
  jsr @move_to_next_byte
  jsr get_current_byte
  bne @skip_past_next_null_byte  
  jsr @move_to_next_byte
  rts
  

@move_to_next_byte:
  inc get_current_byte+1
  bne :+
  inc get_current_byte+2
:  
  rts

;move the ptr along till it's pointing at the whatever is the value of current_option
@move_to_current_option:
  ldax  options_table_pointer
  stax get_current_byte+1
  lda #0
  sta temp_option_counter
  sta temp_option_counter+1

@skip_over_strings:
  lda temp_option_counter
  cmp current_option
  bne  @not_at_current_option
  lda temp_option_counter+1
  cmp current_option+1
  bne @not_at_current_option
  rts
@not_at_current_option:    
  jsr @skip_past_next_null_byte

  inc temp_option_counter
  bne :+
  inc temp_option_counter+1
:    
  jmp @skip_over_strings  




  
@display_first_page_of_options:
  lda   #0
  sta   first_option_this_page
  sta   first_option_this_page+1
  

@print_current_page:
  lda   first_option_this_page  
  sta   current_option
  lda   first_option_this_page+1
  sta   current_option+1
  lda   #0
  sta   last_page_flag
  
  jsr   @move_to_current_option
  
  
  jsr   cls
  
  ldax  #select_from_following_options
  jsr   print_ascii_as_native
  
  
  jsr   print_cr
  lda   #0
  sta   options_shown_this_page

@print_loop:
  
  lda   options_shown_this_page 
  clc
  adc   #'A'
  jsr print_a
  
  lda  #')'
  jsr print_a

  lda  #' '
  jsr print_a
 
  lda get_current_byte+1
  ldx get_current_byte+2
  ldy convert_to_native
  beq :+
  jsr print_ascii_as_native
  jmp @printed
:
  jsr print
@printed:

  jsr print_cr
  jsr @skip_past_next_null_byte
  inc current_option
  bne :+
  inc current_option+1
:  
  lda current_option
  cmp number_of_options
  bne :+
  lda current_option+1
  cmp number_of_options+1
  bne :+
  inc last_page_flag
  jmp @print_instructions_and_get_keypress
:  
  inc options_shown_this_page
  lda options_shown_this_page
  cmp #OPTIONS_PER_PAGE
  beq @print_instructions_and_get_keypress
  jmp @print_loop

@jump_to:
  jsr print_cr
  ldax #jump_to_prompt
  jsr print_ascii_as_native
  lda #'?'
  
  jsr get_key
  ora #$80      ;set the high bit
  
  
  sta jump_to_prefix
  ldax  options_table_pointer
  stax get_current_byte+1
  lda #0
  sta current_option
  sta current_option+1
  
@check_if_at_jump_to_prefix:  
  jsr get_current_byte
  ora #$80      ;set high bit
  cmp jump_to_prefix
  beq @at_prefix
  jsr @skip_past_next_null_byte
  inc  current_option
  bne :+
  inc  current_option+1
:  
  jsr get_current_byte
  bne @check_if_at_jump_to_prefix
  jsr beep  ;if we got to the end of the options table without finding the char we want, then sound a beep
  jmp @jump_to_finished
@at_prefix:
  lda current_option
  sta first_option_this_page
  lda current_option+1
  sta first_option_this_page+1
@jump_to_finished:  
   jmp  @print_current_page  


@print_instructions_and_get_keypress:
  lda   number_of_options+1
  bne   @navigation_instructions
  lda   number_of_options
  cmp   #OPTIONS_PER_PAGE
  bcc   :+
@navigation_instructions:  
  ldax  #navigation_instructions
  jsr   print_ascii_as_native
:  
@get_keypress:
  lda #'?'

  jsr get_key

;  jsr print_hex
;  @fixme:
;    jmp @fixme

  cmp #KEYCODE_ABORT
  beq @quit
  cmp #KEYCODE_SLASH
  beq @jump_to
  cmp #KEYCODE_RIGHT
  beq @forward_one_page
  cmp #KEYCODE_DOWN
  beq @forward_one_page
  cmp #KEYCODE_UP
  beq @back_one_page
  cmp #KEYCODE_LEFT
  beq @back_one_page
  
  ora #$e0      ;make it a lower case letter with high bit set
  sec
  sbc #$e1
  bcc @get_keypress ;if we have underflowed, it wasn't a valid option
  
  
  cmp #OPTIONS_PER_PAGE-1
  beq @got_valid_option
  bpl @get_keypress ;if we have underflowed, it wasn't a valid option


@got_valid_option:
  clc
  adc first_option_this_page
  sta  current_option
  lda #0
  adc first_option_this_page+1

  sta  current_option+1

  jsr  @move_to_current_option
  ldax get_current_byte+1
  clc
  rts

@quit:
  sec
  rts
  
@forward_one_page:  
  clc
  lda last_page_flag
  beq :+
@back_to_first_page:  
  jmp @display_first_page_of_options
:  
  lda first_option_this_page
  adc #OPTIONS_PER_PAGE
  sta first_option_this_page
  bcc :+
  inc first_option_this_page+1
:

  jmp @print_current_page

@back_one_page:  
  sec
  lda first_option_this_page
  sbc #OPTIONS_PER_PAGE
  sta first_option_this_page
  lda first_option_this_page+1
  sbc #0
  sta first_option_this_page+1    
  bmi @show_last_page_of_options
  
  jmp @print_current_page
@show_last_page_of_options:
  sec
  lda number_of_options  
  sbc #OPTIONS_PER_PAGE
  sta first_option_this_page
  lda number_of_options+1
  sbc #0
  sta first_option_this_page+1
  bmi @back_to_first_page
  jmp @print_current_page

.rodata

select_from_following_options: .byte "Select one of the following options:",10,0
navigation_instructions: .byte 10,"Arrow keys navigate between menu pages",10
.byte "/ to jump or "
.byte KEYNAME_ABORT
.byte " to quit",10,0

jump_to_prompt: .byte "jump to:",0



;-- LICENSE FOR menu.i --
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
