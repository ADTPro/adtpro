;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2014 by David Schmidt
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
; BootSector
;
; This code is to be planted in sector 1 of an Apple II boot disk so as to
; give the /// user a notice that the wrong disk is booted.  The Apple ///
; will pull in a whole block, thus giving us the second half (256 bytes) to run.
; Note sector 0 will need to be of the dual-boot variety.
; Looking at a dump of a disk in a hex editor, this code is copied to $d00-$dff.
; The Apple /// will then pull this code in to $a000 and run it. 
; 
; All this code really does is to clear the screen and put up a message saying
; it won't boot on an Apple ///, and the user should boot something else.
;

; Define an ASCII string with no attributes
	.macro  asc Arg
		.repeat .strlen(Arg), I
		.byte   .strat(Arg, I) | $80
		.endrep
	.endmacro

; Define an inverse ASCII string
	.macro  inv Arg
		.repeat .strlen(Arg), I
		.byte   .strat(Arg, I)
		.endrep
	.endmacro

	.org $a000	; Make the listing legible
	lda #$03
	sta $ffd0	; Use the monitor's zero page
	jsr $fb7d	; Call the ROM's clear screen routine
	lda #$05
	jsr $FBC5	; Set CV
	lda #$00
	sta $5c		; Set CH
	jsr Message
:	jmp :-

Message:
	tay
	lda #<message_1
	sta $fe
	lda #>message_1
	sta $ff
@MLoop:	lda ($fe),y
@MDone:	beq @MDone 
	jsr $FC39	; COUT
	iny
	jmp @MLoop

	
message_1:
	asc "WELCOME TO YOUR "
	inv "APPLE ///"
	asc "! THIS DISK IS "
	asc "PART OF THE ADTPRO DISTRIBUTION, BUT IT "
	asc "IS INTENDED FOR THE "
	inv "APPLE ]["
	asc ". PLEASE"
	.byte $8d
	asc "BOOT THE "
	inv "SOS"
	asc"-SPECIFIC DISK INSTEAD."
	.byte $8d, $8d
	asc "COOL /// FACT: CTRL-OPENAPPLE-RESET"
	.byte $8d
	asc "STARTS A MINI-MONITOR."
	.byte $00

Filler:
	.res $a100-Filler,$00