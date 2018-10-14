.ifndef SCREEN_WIDTH
  SCREEN_WIDTH = 40
.endif

.ifndef KPR_API_VERSION_NUMBER
  .define EQU =
  .include "zeropage.inc"
  .include "../inc/kipper_constants.i"
.endif

.export print_hex
.export print_ip_config
.export dhcp_msg
.export ok_msg
.export failed_msg
.export init_msg
.export print
.export print_ascii_as_native
.export print_integer
.export print_dotted_quad
.export mac_address_msg
.export ip_address_msg
.export netmask_msg
.export gateway_msg
.export dns_server_msg
.export tftp_server_msg
.import ip65_error
.export print_errorcode
.export press_a_key_to_continue

.import ascii_to_native

.import eth_driver_name
.import eth_driver_io_base
.importzp copy_src
.import cfg_mac
.import cfg_ip
.import cfg_netmask
.import cfg_gateway
.import cfg_dns
.import dhcp_server
.import cfg_tftp_server

pptr = ptr1


.bss

temp_bin: .res 2
temp_bcd: .res 3
temp_ptr: .res 2


.code

.macro print_hex_double arg
  lda #>(.right (.tcount (arg)-1, arg))
  jsr print_hex
  lda #<(.right (.tcount (arg)-1, arg))
  jsr print_hex
.endmacro

.macro print_driver_init
  ldax #eth_driver_name
  jsr print_ascii_as_native
  lda #'('
  jsr print_a
  lda #'$'
  jsr print_a
  lda eth_driver_io_base+1
  jsr print_hex
  lda eth_driver_io_base
  jsr print_hex
  lda #')'
  jsr print_a
  ldax #init_msg
  jsr print_ascii_as_native
.endmacro

.macro print_dhcp_init
  ldax #dhcp_msg
  jsr print_ascii_as_native
  ldax #init_msg
  jsr print_ascii_as_native
.endmacro

.macro print_failed
  ldax #failed_msg
  jsr print_ascii_as_native
  jsr print_cr
.endmacro

.macro print_ok
  ldax #ok_msg
  jsr print_ascii_as_native
  jsr print_cr
.endmacro


.code

.import print_a
.import print_cr
.import eth_driver_name

print_ip_config:
  ldax #interface_type
  jsr print_ascii_as_native

  ldax #eth_driver_name
  jsr print_ascii_as_native
  jsr print_cr

  ldax #mac_address_msg
  jsr print_ascii_as_native
  ldax #cfg_mac
  jsr print_mac
  jsr print_cr

  ldax #ip_address_msg
  jsr print_ascii_as_native
  ldax #cfg_ip
  jsr print_dotted_quad
  jsr print_cr

  ldax #netmask_msg
  jsr print_ascii_as_native
  ldax #cfg_netmask
  jsr print_dotted_quad
  jsr print_cr

  ldax #gateway_msg
  jsr print_ascii_as_native
  ldax #cfg_gateway
  jsr print_dotted_quad
  jsr print_cr

  ldax #dns_server_msg
  jsr print_ascii_as_native
  ldax #cfg_dns
  jsr print_dotted_quad
  jsr print_cr

  ldax #tftp_server_msg
  jsr print_ascii_as_native
  ldax #cfg_tftp_server
  jsr print_dotted_quad
  jsr print_cr

  ldax #dhcp_server_msg
  jsr print_ascii_as_native
  ldax #dhcp_server
  jsr print_dotted_quad
  jsr print_cr
  rts

print:
  sta pptr
  stx pptr + 1

@print_loop:
  ldy #0
  lda (pptr),y
  beq @done_print
  jsr print_a
  inc pptr
  bne @print_loop
  inc pptr+1
  bne @print_loop               ; if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts

print_ascii_as_native:
  sta pptr
  stx pptr + 1

@print_loop:
  ldy #0
  lda (pptr),y
  beq @done_print
  jsr ascii_to_native
  jsr print_a
  inc pptr
  bne @print_loop
  inc pptr+1
  bne @print_loop               ; if we ever get to $ffff, we've probably gone far enough ;-)
@done_print:
  rts

; print the 4 bytes pointed at by AX as dotted decimals
print_dotted_quad:
  sta pptr
  stx pptr + 1
  lda #0
@print_one_byte:
  pha
  tay
  lda (pptr),y
  ldx #0
  jsr print_integer
  pla
  cmp #3
  beq @done
  clc
  adc #1
  pha
  lda #'.'
  jsr print_a
  pla
  bne @print_one_byte
@done:
  rts

; print 6 bytes printed at by AX as a MAC address
print_mac:
  stax pptr
  ldy #0
@one_mac_digit:
  tya                           ; just to set the Z flag
  pha
  beq @dont_print_colon
  lda #':'
  jsr print_a
@dont_print_colon:
  pla
  tay
  lda (pptr),y
  jsr print_hex
  iny
  cpy #06
  bne @one_mac_digit
  rts

print_integer:                  ; print 16 bit number in AX as a decimal number

  ; hex to bcd routine taken from Andrew Jacob's code at http://www.6502.org/source/integers/hex2dec-more.htm
  stax temp_bin
  sed                           ; Switch to decimal mode
  lda #0                        ; Ensure the result is clear
  sta temp_bcd
  sta temp_bcd+1
  sta temp_bcd+2
  ldx #16                       ; The number of source bits
: asl temp_bin+0                ; Shift out one bit
  rol temp_bin+1
  lda temp_bcd+0                ; And add into result
  adc temp_bcd+0
  sta temp_bcd+0
  lda temp_bcd+1                ; propagating any carry
  adc temp_bcd+1
  sta temp_bcd+1
  lda temp_bcd+2                ; ... thru whole result
  adc temp_bcd+2
  sta temp_bcd+2

  dex                           ; And repeat for next bit
  bne :-

  stx temp_bin+1                ; x is now zero - reuse temp_bin as a count of non-zero digits
  cld                           ; back to binary
  ldx #2
  stx temp_bin+1                ; reuse temp_bin+1 as loop counter
@print_one_byte:
  ldx temp_bin+1
  lda temp_bcd,x
  pha
  lsr
  lsr
  lsr
  lsr
  jsr @print_one_digit
  pla
  and #$0f
  jsr @print_one_digit
  dec temp_bin+1
  bpl @print_one_byte
  rts
@print_one_digit:
  cmp #0
  beq @this_digit_is_zero
  inc temp_bin                  ; increment count of non-zero digits
@ok_to_print:
  clc
  adc #'0'
  jsr print_a
  rts
@this_digit_is_zero:
  ldx temp_bin                  ; how many non-zero digits have we printed?
  bne @ok_to_print
  ldx temp_bin+1                ; how many digits are left to print?
  bne @this_is_not_last_digit
  inc temp_bin                  ; to get to this point, this must be the high nibble of the last byte.
                                ; by making 'count of non-zero digits' to be >0, we force printing of the last digit
@this_is_not_last_digit:
  rts

print_hex:
  pha
  pha
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexdigits,x
  jsr print_a
  pla
  and #$0F
  tax
  lda hexdigits,x
  jsr print_a
  pla
  rts

print_errorcode:
  ldax #error_code
  jsr print_ascii_as_native
  lda ip65_error
  jsr print_hex
  jmp print_cr


.rodata

hexdigits:
  .byte "0123456789ABCDEF"

.if SCREEN_WIDTH >= 30

interface_type:
  .byte "Interface   : ",0
mac_address_msg:
  .byte "MAC Address : ",0
ip_address_msg:
  .byte "IP Address  : ",0
netmask_msg:
  .byte "Netmask     : ",0
gateway_msg:
  .byte "Gateway     : ",0
dns_server_msg:
  .byte "DNS Server  : ",0
dhcp_server_msg:
  .byte "DHCP Server : ",0
tftp_server_msg:
  .byte "TFTP Server : ",0

.else                           ; for small width screens e.g. VIC 20

interface_type:
  .byte "Interface",  10,0
mac_address_msg:
  .byte "MAC Address",10,0
ip_address_msg:
  .byte "IP Address", 10,0
netmask_msg:
  .byte "Netmask",    10,0
gateway_msg:
  .byte "Gateway",    10,0
dns_server_msg:
  .byte "DNS Server", 10,0
dhcp_server_msg:
  .byte "DHCP Server",10,0
tftp_server_msg:
  .byte "TFTP Server",10,0

.endif

dhcp_msg:
  .byte "DHCP",0

init_msg:
  .byte 10,"Initializing ",0

failed_msg:
  .byte "failed",0

ok_msg:
  .byte "OK",0

dns_lookup_failed_msg:
  .byte "DNS LOOKUP FAILED",0

error_code:
  .asciiz "error code: "

press_a_key_to_continue:
  .byte "Press a key to continue",10,0



; -- LICENSE FOR commonprint.i --
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
