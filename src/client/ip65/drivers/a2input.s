.export check_for_abort_key

.include "../inc/common.i"

.code

;check whether the escape key is being pressed
;inputs: none
;outputs: sec if escape pressed, clear otherwise
check_for_abort_key:
lda $c000 ;current key pressed
cmp #$9B
bne :+
bit $c010 ;clear the keyboard strobe
sec
rts
:
clc
rts

;-- LICENSE FOR a2input.s --
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
