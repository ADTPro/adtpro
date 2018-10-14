; timer routines
;
; the timer should be a 16-bit counter that's incremented by about
; 1000 units per second. it doesn't have to be particularly accurate,
; if you're working with e.g. a 60 Hz VBLANK IRQ, adding 17 to the
; counter every frame would be just fine.
;
; this is generic timer routines, machine specific code goes in drivers/<machinename>timer.s
	.include "../inc/common.i"


	.export timer_timeout
  .import timer_read

	.bss

time:		.res 2


	.code

;check if specified period of time has passed yet
;inputs: AX - maximum number of milliseconds we are willing to wait for
;outputs: carry flag set if timeout occured, clear otherwise
timer_timeout:
	pha
  txa
  pha
  jsr timer_read
  stax time
  pla
  tax
	pla
	sec			; subtract current value
	sbc time
	txa
	sbc time + 1
	rts			; clc = timeout, sec = no timeout



;-- LICENSE FOR timer.s --
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
