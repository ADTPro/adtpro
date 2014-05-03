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

	.org $a000	; Make the listing legible
ClearScreen:
	lda #$a0
	ldy #$78
	jsr Fill1
	ldy #$78
	jsr Fill2
	rts
Fill1:	dey
	sta $400,y
	sta $480,y
	sta $500,y
	sta $580,y
	bne Fill1
	rts
Fill2:	dey
	sta $600,y
	sta $680,y
	sta $700,y
	sta $780,y
	bne Fill2

	ldx #<message_1
	ldy #$00
	jsr Message
	ldx #<message_2
	ldy #$80
	jsr Message
:	bcc :-

Message:
	stx SelfMod1+1
	sty SelfMod2+1
	ldy #39
SelfMod1:
	lda message_1,y
SelfMod2:
	sta $78f,y
	dey
	bpl SelfMod1
	clc
	rts

message_1:
	asc "THIS DISK WILL NOT BOOT ON AN APPLE ///."

message_2:
	asc "PLEASE INSERT ANOTHER DISK AND REBOOT.  "

Filler:
	.res $a100-Filler,$00