; timer routines
;
; unfortunately the standard Apple 2 has no CIA or VBI, so for the moment, we will
; make each call to 'timer_read' delay for a little while
; this kludge will make the polling loops work at least
; 
; timer_read is meant to return a counter with millisecond resolution

	.include "../inc/common.i"

	.export timer_init
	.export timer_read

  .bss
  current_time_value: .res 2

	.code

;reset timer to 0
;inputs: none
;outputs: none
timer_init:
  ldax  #0
  stax current_time_value
	rts

;this SHOULD just read the current timer value 
;but since a standard apple 2 has no dedicated timing circuit,
;each call to this function actually delays a while, then updates the current value
; inputs: none
; outputs: AX = current timer value (roughly equal to number of milliseconds since the last call to 'timer_init')
timer_read:
  lda #111
  jsr $fca8 ;wait for about 33ms
  clc
  lda #33
  adc current_time_value
  sta current_time_value
  bcc :+
  inc current_time_value+1
:
  ldax  current_time_value
  rts


;-- LICENSE FOR a2timer.s --
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
