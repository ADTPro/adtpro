;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2012 by David Schmidt
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
	lda #$0B	; COMMAND: NO PARITY, RTS ON,
	sta $C0F2	; DTR ON, NO INTERRUPTS (Command mode register)
	ldy PSPEED	; CONTROL: 8 DATA BITS, 1 STOP
	lda BPSCTRL,Y	; BIT, BAUD RATE DEPENDS ON
	sta $C0F3	; PSPEED (Control register)
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

	lda $C0F1	; Check status bits
	and #$70
	cmp #$10
	bne IIIPUTC1	; Output register is full, so loop
	pla
	sta $C0F0	; Put character
	rts

IIIABORT:
	sta $C040
	jmp ABORT

;---------------------------------------------------------
; IIIGET - Get a character from the ACIA (XY unchanged)
;          Carry set on timeout, clear on data (returned in Accumulator)
;---------------------------------------------------------
IIIGET:
	lda #$00
	sta Timer
	sta Timer+1
	lda $C000	; Check for escape at first
	cmp #CHR_ESC	; Escape = abort
	bne IIIGETLoop
	jmp PABORT
IIIGETLoop:
	lda $C0F1	; Check status bits
	and #$68
	cmp #$8
	beq @GetIt	; Input register has data
	lda $C000	; Check for escape once in a while
	cmp #CHR_ESC	; Escape = abort
	bne @TimerInc
	jmp PABORT
@TimerInc:
	inc Timer
	bne IIIGETLoop	; Timer non-zero, loop
	inc Timer+1
	bne IIIGETLoop	; Timer non-zero, loop
	sec
	rts		; Timeout	
@GetIt:	lda $C0F0	; Get character
	clc
	rts

;---------------------------------------------------------
; RESETIII - Clean up ///
;---------------------------------------------------------
RESETIII:
	bit $C0F0	; CLEAR ACIA INPUT REGISTER
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

; C0F0 ($C088):  ACIADR  Data register.
; C0F1 ($C089):  ACIASR  Status register.
; C0F2 ($C08A):  ACIAMR  Command mode register.
; C0F3 ($C08B):  ACIACR  Control register.
