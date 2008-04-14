;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 by David Schmidt
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
	iny
	iny
	lda $C212		; PASCAL CONTROL ENTRY POINT
	rts

;---------------------------------------------------------
; INITSLOT - Initialize the slot firmware
;---------------------------------------------------------
INITSLOT:
	ldx #$C2		; $CN, N=SLOT
	ldy #$20		; $N0, N=SLOT
	lda #0
	stx MSLOT
MODINIT:
	jsr $C245		; PASCAL INIT ENTRY POINT
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
	ldy #$b4		; Start with ascii "4"
	lda PSPEED
	bne :+			; Is speed set to low (300)?
	lda #$b0		; Load up ascii "0"
	sta BAUDR+1
	lda #$b6		; Load up ascii "6"
	sta BAUDR+2
	jmp INITFOUNDSPEED
:
	cmp #$02		; Is PSPEED set to 19200?
	bne :+
	iny			; Yes, bump "4" to "5"
:	sty BAUDR+2
	ldy #$b1		; Load up ascii "1"
	sty BAUDR+1		; We now have "Ctrl-A1[4|5]B"
INITFOUNDSPEED:
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
	.byte $01,$d8,$c4	; ctrl-A X D - disable XON/XOFF
	.byte $01,$c3,$c4	; ctrl-A C D - disable auto CR
	.byte $01,$c6,$c4	; ctrl-A F D - suppress keyboard
	.byte $01,$cb		; ctrl-A K - disable auto LF after CR
BAUDR:
	.byte $01,$b1,$b5,$c2	; ctrl-A 1n B - set baud rate
	.byte $01,$da		; ctrl-A Z - disable firmware control chars
	.byte $00		; terminate string

;---------------------------------------------------------
; RESETPAS - Clean up every time we hit the main loop
;---------------------------------------------------------
RESETPAS:
	rts

;---------------------------------------------------------
; PUTCPAS - Send accumulator out the serial port
;---------------------------------------------------------
PUTCPAS:
	.byte $DA		; PHX
	.byte $5A		; PHY
	pha
K8D8:
	lda $C000
	cmp #CHR_ESC		; Escape = abort
	bne OK8E2
	jmp PABORT
OK8E2:
	ldx #$C2		; $CN, N=SLOT
	ldy #$20		; $N0
	lda #0			; READY FOR OUTPUT?
MODSTAT1:
	jsr $C248		; PASCAL STATUS ENTRY POINT
	bcc K8D8		; CC MEANS NOT READY
	ldx #$C2		; $CN
	ldy #$20		; $N0
	pla			; RETRIEVE CHAR
	pha			; MUST SAVE FOR RETURN
MODWRITE:
	jsr $C247		; PASCAL WRITE ENTRY POINT
	pla
	.byte $7A		; PLY
	.byte $FA		; PLX
	and #$FF
	rts

;---------------------------------------------------------
; GETCPAS - Get a character from the serial port (XY unchanged)
;---------------------------------------------------------
GETCPAS:
	.byte $DA		; PHX
	.byte $5A		; PHY
K902:
	lda $C000
	cmp #CHR_ESC		; Escape = abort
	bne OK90C
	jmp PABORT
OK90C:
	ldx #$C2		; $CN, N=SLOT
	ldy #$20		; $N0
	lda #1			; INPUT READY?
MODSTAT2:
	jsr $C248		; PASCAL STATUS ENTRY POINT
	bcc K902		; CC MEANS NO INPUT READY
	ldx #$C2		; $CN
	ldy #$20		; $N0
MODREAD:
	jsr $C246		; PASCAL READ ENTRY POINT
	.byte $7A		; PLY
	.byte $FA		; PLX
	and #$FF
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