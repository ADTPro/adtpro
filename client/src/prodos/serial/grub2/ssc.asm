;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 by David Schmidt
; david__schmidt at users.sourceforge.net
;
; This program is free software; you can redistribute it and/or modify it 
; under the terms of the GNU General Public License as published by the 
; Free Software Foundation; either version 2 of the License, or (at your 
; option) any later version.
;
; This program is distributed in the hope that it will be useful, but 
; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
; for more details.
;
; You should have received a copy of the GNU General Public License along 
; with this program; if not, write to the Free Software Foundation, Inc., 
; 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
;

;---------------------------------------------------------
; INITSSC - Initialize the SSC
; Y holds the desired slot number
;---------------------------------------------------------
initssc:
	tya
	asl
	asl
	asl
	asl		; NOW $S0
	adc #$88
	tax
	lda #$0B	; COMMAND: NO PARITY, RTS ON,
	sta $C002,X	; DTR ON, NO INTERRUPTS
	ldy comm_speed	; CONTROL: 8 DATA BITS, 1 STOP
	lda bpsctrl,Y	; BIT, BAUD RATE DEPENDS ON
	sta $C003,X	; comm_speed
	stx mod0+1	; SELF-MODS FOR $C088+S0
	stx mod2+1	; IN MAIN LOOP
	stx mod4+1	; AND IN sscget AND sscput
	inx
	stx mod1+1	; SELF-MODdS FOR $C089+S0
	stx mod3+1	; IN sscget AND sscput
	jsr patchssc
	rts

;---------------------------------------------------------
; ABORT - STOP EVERYTHING
;---------------------------------------------------------
abort:	ldx	#$ff		; POP GOES THE STACKPTR
	txs
	jmp	init		; Let next_task sort 'em out

;---------------------------------------------------------
; sscput - Send accumulator out the serial line
;---------------------------------------------------------
sscput:
	pha		; Push A onto the stack
putc1:	lda $C000
	cmp #esc	; Escape = abort
	beq pabort

mod1:	lda $C089	; Check status bits
mod5:	and #$50	; Mask for DSR (must ignore for Laser 128)
	cmp #$10
	bne putc1	; Output register is full, so loop
	pla
mod2:	sta $C088	; Put character
	rts

pabort:	jmp abort

;---------------------------------------------------------
; sscget - Get a character from Super Serial Card (XY unchanged)
;---------------------------------------------------------
sscget:
	lda $C000
	cmp #esc	; Escape = abort
	beq pabort
mod3:	lda $C089	; Check status bits
mod6:	and #$68
	cmp #$8
	bne sscget	; Input register empty, loop
mod4:	lda $C088	; Get character
	rts

;---------------------------------------------------------
; resetssc - Clean up SSC
;---------------------------------------------------------
resetssc:
mod0:	bit $C088	; CLEAR SSC INPUT REGISTER
	rts

;---------------------------------------------------------
; PATCHSSC - Patch the entry points of SSC processing
;---------------------------------------------------------
patchssc:
	lda #<sscput
	sta putc+1
	lda #>sscput
	sta putc+2

	lda #<sscget
	sta getc+1
	lda #>sscget
	sta getc+2

	lda #<resetssc
	sta resetio+1
	lda #>resetssc
	sta resetio+2

	rts

bpsctrl:
	.byte	$16,$18,$1a,$1c,$1e,$1f,$10
