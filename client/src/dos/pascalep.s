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

;---------------------------------------------------------
; initpas - Do all the Pascal entry point setup stuff
;---------------------------------------------------------
initpas:
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
	lda pspeed
	cmp #$06
	bpl SILOOP
	asl
	tay
	lda BaudStrings,y
	sta BAUDR+1
	lda BaudStrings+1,y
	sta BAUDR+2
	ldy #0
SILOOP:
	lda INITSTRING,Y
	BEQ SIDONE		; ZERO terminates
	jsr putcpas		; preserves Y
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
	.byte $01,$b1,$b5,$c2	; ctrl-A nn B - set baud rate
	.byte $01,$da		; ctrl-A Z - disable firmware control chars
	.byte $00		; terminate string
BaudStrings:
	.byte $b0, $b6		; "06" (300 baud)
	.byte $b0, $b8		; "08" (1200 baud)
	.byte $b1, $b0		; "10" (2400 baud)
	.byte $b1, $b2		; "12" (4800 baud)
	.byte $b1, $b4		; "14" (9600 baud)
	.byte $b1, $b5		; "15" (19200 baud)

;---------------------------------------------------------
; RESETPAS - Clean up every time we hit the main loop
;---------------------------------------------------------
RESETPAS:
	rts

;---------------------------------------------------------
; putcpas - Send accumulator out the serial port
;---------------------------------------------------------
putcpas:
	.byte $DA		; PHX
	.byte $5A		; PHY
	pha
K8D8:
	lda $C000
	cmp #esc		; Escape = abort
	bne OK8E2
	jmp pabort
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
; getcpas - Get a character from the serial port (XY unchanged)
;---------------------------------------------------------
getcpas:
	.byte $DA		; PHX
	.byte $5A		; PHY
K902:
	lda $C000
	cmp #esc		; Escape = abort
	bne OK90C
	jmp pabort
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
; PATCHPAS - Patch the entry point of putc and getc over
;            to the Pascal versions
;---------------------------------------------------------
PATCHPAS:
	lda #<putcpas
	sta putc+1
	lda #>putcpas
	sta putc+2

	lda #<getcpas
	sta getc+1
	lda #>getcpas
	sta getc+2

	lda #<RESETPAS
	sta resetio+1
	lda #>RESETPAS
	sta resetio+2

	rts