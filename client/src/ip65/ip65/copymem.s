; utility routine to copy memory


	.export copymem
	.exportzp copy_src
	.exportzp copy_dest


	.segment "IP65ZP" : zeropage

; pointers for copying
copy_src:	.res 2			; source pointer
copy_dest:	.res 2			; destination pointer


	.bss

end:		.res 1


	.code

;copy memory
;inputs:
; copy_src is address of buffer to copy from
; copy_dest is address of buffer to copy to
; AX = number of bytes to copy
;outputs: none
copymem:
	sta end
	ldy #0

	cpx #0
	beq @tail

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	bne :-
  inc copy_src+1    ;next page
  inc copy_dest+1  ;next page
	dex
	bne :-

@tail:
	lda end
	beq @done

:	lda (copy_src),y
	sta (copy_dest),y
	iny
	cpy end
	bne :-

@done:
	rts



;-- LICENSE FOR copymem.s --
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
; The Initial Developer of the Original Code is Per Olofsson,
; MagerValp@gmail.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Per Olofsson. All Rights Reserved.  
; -- LICENSE END --
