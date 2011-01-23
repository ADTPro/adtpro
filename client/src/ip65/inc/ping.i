.import icmp_ping
.import icmp_echo_ip

NUM_PING_RETRIES=3
.bss
ping_retries: .res 1

.code
ping_loop:
  ldax #remote_host
  jsr print_ascii_as_native
  kippercall #KPR_INPUT_HOSTNAME
  bcc @host_entered
  ;if no host entered, then bail.
  rts
@host_entered:
  stax kipper_param_buffer
  jsr print_cr
  ldax #resolving
  jsr print_ascii_as_native
  ldax kipper_param_buffer
  kippercall #KPR_PRINT_ASCIIZ
  jsr print_cr
  ldax #kipper_param_buffer
  kippercall #KPR_DNS_RESOLVE
  bcc @resolved_ok
@failed:  
  print_failed
  jsr print_cr
  jsr print_errorcode
  jmp ping_loop
@resolved_ok:

  lda #NUM_PING_RETRIES
  sta ping_retries  
@ping_once:
  ldax #pinging
  jsr print_ascii_as_native
  ldax #kipper_param_buffer
  jsr print_dotted_quad
  lda #' '
  jsr print_a
  lda #':'
  jsr print_a
  lda #' '
  jsr print_a

  ldax #kipper_param_buffer
  kippercall #KPR_PING_HOST

bcs @ping_error
  jsr print_integer
  ldax #ms
  jsr print_ascii_as_native
@check_retries:  
  dec ping_retries
  bpl @ping_once
  jmp ping_loop
  
@ping_error:
  jsr print_errorcode
  jmp @check_retries

  
ms: .byte " ms",10,0
pinging: .byte "pinging ",0



;-- LICENSE FOR ping.i --
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
