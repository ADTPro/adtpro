.include "../inc/common.i"

;helper routines for arithmetic on 32 bit numbers 

;reuse the copy_* zero page locations as pointers for 32bit addition
.importzp copy_src
.importzp copy_dest

acc32 =copy_src       ;32bit accumulater (pointer)
op32 =copy_dest       ;32 bit operand (pointer)

acc16 =acc32       ;16bit accumulater (value, NOT pointer)

.bss
temp_ax: .res 2
.code
;no 16bit operand as can just use AX    
.exportzp acc32
.exportzp op32
.exportzp acc16

.export add_32_32
.export add_16_32

.export sub_16_16   

.export cmp_32_32
.export cmp_16_16

.export mul_8_16

;compare 2 32bit numbers
;on exit, zero flag clear iff acc32==op32
cmp_32_32:
  ldy #0
  lda (op32),y
  cmp (acc32),y
  bne @exit
  iny  
  lda (op32),y
  cmp (acc32),y
  bne @exit
  iny
  lda (op32),y
  cmp (acc32),y
  bne @exit
  iny
  lda (op32),y
  cmp (acc32),y
@exit:  
  rts

;compare 2 16bit numbers
;on exit, zero flag clear iff acc16==AX
cmp_16_16:
  cmp acc16
  bne @exit
  txa
  cmp acc16+1
@exit:  
  rts
  
;subtract 2 16 bit numbers
;acc16=acc16-AX
sub_16_16:
  stax  temp_ax
  sec
  lda acc16
  sbc temp_ax
  sta acc16
  lda acc16+1
  sbc temp_ax+1
  sta acc16+1
  rts
  
;add a 32bit operand to the 32 bit accumulater
;acc32=acc32+op32
add_32_32:
  clc
  ldy #0
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
  iny
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
  iny
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
  iny
  lda (op32),y
  adc (acc32),y
  sta (acc32),y  
    
  rts
  

;add a 16bit operand to the 32 bit accumulater
;acc32=acc32+AX
add_16_32:
  clc
  ldy #0
  adc (acc32),y
  sta (acc32),y  
  iny
  txa
  adc (acc32),y
  sta (acc32),y  
  iny
  lda #0
  adc (acc32),y
  sta (acc32),y
  iny
  lda #0
  adc (acc32),y
  sta (acc32),y
  rts
  
;multiply a 16 bit number by an 8 bit number
;acc16=acc16*a
mul_8_16:
  tax
  beq @operand_is_zero
  lda  acc16
  sta  temp_ax
  lda  acc16+1
  sta  temp_ax+1
  
@addition_loop:
  dex
  beq @done
  clc
  lda acc16
  adc temp_ax
  sta acc16
  lda acc16+1
  adc temp_ax+1
  sta acc16+1
  jmp @addition_loop  
  
@done:

  rts  
@operand_is_zero:
  sta acc16
  sta acc16+1  
  rts



;-- LICENSE FOR arithmetic.s --
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
