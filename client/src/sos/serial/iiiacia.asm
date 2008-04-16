;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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
; INITIII - Initialize the /// ACIA
;---------------------------------------------------------
INITIII:
	tya
	asl
	asl
	asl
	asl		; NOW $S0
	adc #$88
	tax
	lda #$0B	; COMMAND: NO PARITY, RTS ON,
	sta $C002,X	; DTR ON, NO INTERRUPTS
	ldy PSPEED	; CONTROL: 8 DATA BITS, 1 STOP
	lda BPSCTRL,Y	; BIT, BAUD RATE DEPENDS ON
	sta $C003,X	; PSPEED
	stx IIIMOD0+1	; SELF-MODS FOR $C088+S0
	stx IIIMOD2+1	; IN MAIN LOOP
	stx IIIMOD4+1	; AND IN IIIGET AND IIIPUT
	inx
	stx IIIMOD1+1	; SELF-MODS FOR $C089+S0
	stx IIIMOD3+1	; IN IIIGET AND IIIPUT
	jsr PATCHIII
	rts

;---------------------------------------------------------
; IIIPUT - Send accumulator out the serial line
;---------------------------------------------------------
IIIPUT:
	pha		; Push A onto the stack
IIIPUTC1:
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	beq IIIABORT

IIIMOD1:	lda $C089	; Check status bits
	and #$70
	cmp #$10
	bne IIIPUTC1	; Output register is full, so loop
	pla
IIIMOD2:	sta $C088	; Put character
	rts

IIIABORT:
	jmp ABORT

;---------------------------------------------------------
; IIIGET - Get a character from the ACIA (XY unchanged)
;---------------------------------------------------------
IIIGET:
	lda $C000
	cmp #CHR_ESC	; Escape = abort
	beq IIIABORT
IIIMOD3:	lda $C089	; Check status bits
	and #$68
	cmp #$8
	bne IIIGET	; Input register empty, loop
IIIMOD4:	lda $C088	; Get character
	rts

;---------------------------------------------------------
; RESETIII - Clean up ///
;---------------------------------------------------------
RESETIII:
IIIMOD0:	bit $C088	; CLEAR ACIA INPUT REGISTER
	rts

;---------------------------------------------------------
; PATCHIII - Patch the entry points of III processing
;---------------------------------------------------------
PATCHIII:
	lda #<IIIPUT
	sta PUTC+1
	lda #>IIIPUT
	sta PUTC+2

	lda #<IIIGET
	sta GETC+1
	lda #>IIIGET
	sta GETC+2

	lda #<RESETIII
	sta RESETIO+1
	lda #>RESETIII
	sta RESETIO+2

	rts
