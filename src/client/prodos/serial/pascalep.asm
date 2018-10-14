;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2013 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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

	.segment "PASCALEP"

;---------------------------------------------------------
; INITPAS - Do all the Pascal entry point setup stuff
;---------------------------------------------------------
INITPAS:
	sta $CFFF		; Initialize the bus
	jsr SELFMOD
	jsr INITSLOT
	jsr INITSEND
	jsr PATCHPAS
	rts

;---------------------------------------------------------
; SELFMOD - Set up all self-modifying addresses
;---------------------------------------------------------
SELFMOD:
	cld
	lda $C20D		; PASCAL INIT ENTRY POINT
	sta MODINIT+1		; MOD CODE!!
	iny
	lda $C20E		; PASCAL READ ENTRY POINT
	sta MODREAD+1		; MOD CODE!!
	iny
	lda $C20F		; PASCAL WRITE ENTRY POINT
	sta MODWRITE+1		; MOD CODE!!
	iny
	lda $C210		; PASCAL STATUS ENTRY POINT
	sta MODSTAT1+1		; MOD CODE!!
	sta MODSTAT2+1		; MOD CODE!!
	rts

;---------------------------------------------------------
; INITSLOT - Initialize the slot firmware
;---------------------------------------------------------
INITSLOT:
	ldx #$C2		; $CN, N=SLOT
	ldy #$20		; $N0, N=SLOT
	lda #0
MODINIT:
	jsr $C200		; PASCAL INIT ENTRY POINT
	rts

;---------------------------------------------------------
; INITSEND - initialization string for serial port
;---------------------------------------------------------
; The serial port initially accepts control-commands
; in its output stream. This means the port is not
; fully 8-bit transparent. We must first send a
; control sequence to prevent the firmware from
; interpreting any of the binary data.
;
INITSEND:
; Remove options - only setting up as 19200/BPS192K.
;	ldy CHR_5		; Start with ascii "5"
;	sty BAUDR+2
;	ldy CHR_1		; Load up ascii "1"
;	sty BAUDR+1		; We now have "Ctrl-A1[4|5]B"
	ldy #0
SILOOP:
	lda INITSTRING,Y
	BEQ SIDONE		; ZERO terminates
	jsr PUTCPAS		; preserves Y
	iny
	bne SILOOP
SIDONE:
	rts

INITSTRING:
	.byte $01,CHR_X, CHR_SP, CHR_D	; ctrl-A X D - disable XON/XOFF
	.byte $01,CHR_F, CHR_SP, CHR_D	; ctrl-A F D - suppress keyboard
BAUDR:
	.byte $01,CHR_1, CHR_5, CHR_B	; ctrl-A 1n B - set baud rate
	.byte $01,CHR_Z			; ctrl-A Z - disable firmware control chars
	.byte $00			; terminate string

;---------------------------------------------------------
; RESETPAS - Clean up every time we hit the main loop
;---------------------------------------------------------
RESETPAS:
	rts

;---------------------------------------------------------
; PUTCPAS - Send accumulator out the serial port
;---------------------------------------------------------
PUTCPAS:
	stx SLOWX		; PHX
	sty SLOWY		; PHY
	pha
PPASLOOP:
	lda $C000
	cmp #CHR_ESC		; Escape = abort
	bne :+
	jmp PABORT
:
	ldx #$C2		; $CN, N=SLOT
	ldy #$20		; $N0
	lda #0			; READY FOR OUTPUT?
MODSTAT1:
	jsr $C200		; PASCAL STATUS ENTRY POINT
	bcc PPASLOOP		; CC MEANS NOT READY
	ldx #$C2		; $CN
	ldy #$20		; $N0
	pla			; RETRIEVE CHAR
	pha			; MUST SAVE FOR RETURN
MODWRITE:
	jsr $C200		; PASCAL WRITE ENTRY POINT
	pla
	ldy SLOWY		; PLY
	ldx SLOWX		; PLX
	and #$FF
	rts

;---------------------------------------------------------
; GETCPAS - Get a character from the serial port (XY unchanged)
;---------------------------------------------------------
GETCPAS:
	stx SLOWX		; PHX
	sty SLOWY		; PHY
	lda #$00
	sta Timer
	sta Timer+1
	lda $C000	; Check for escape once in a while
	cmp #CHR_ESC	; Escape = abort
	bne GPASLOOP
	jmp PABORT
GPASLOOP:
	ldx #$C2		; $CN, N=SLOT
	ldy #$20		; $N0
	lda #1			; INPUT READY?
MODSTAT2:
	jsr $C200		; PASCAL STATUS ENTRY POINT
	bcs @GetIt		; Carry means input is ready
	lda $C000	; Check for escape once in a while
	cmp #CHR_ESC	; Escape = abort
	bne @TimerInc
	jmp PABORT
@TimerInc:
	inc Timer
	bne GPASLOOP	; Timer non-zero, loop
	inc Timer+1
	bne GPASLOOP	; Timer non-zero, loop
	sec
	rts	

@GetIt:	ldx #$C2		; $CN
	ldy #$20		; $N0
MODREAD:
	jsr $C200		; PASCAL READ ENTRY POINT
	ldy SLOWY		; PLY
	ldx SLOWX		; PLX
	and #$FF
	clc
	rts

;---------------------------------------------------------
; PATCHPAS - Patch the entry point of PUTC and GETC over
;            to the Pascal versions
;---------------------------------------------------------
PATCHPAS:
	lda #<PUTCPAS
	sta PUTC+1
	lda #>PUTCPAS
	sta PUTC+2

	lda #<GETCPAS
	sta GETC+1
	lda #>GETCPAS
	sta GETC+2

	lda #<RESETPAS
	sta RESETIO+1
	lda #>RESETPAS
	sta RESETIO+2

	rts