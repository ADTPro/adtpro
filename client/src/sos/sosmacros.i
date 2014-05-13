;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2014 by David Schmidt
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

.include "macros.i"

.macro  CALLOS Arg1, Arg2
        .byte $00
        .byte Arg1
        .addr Arg2
.endmacro

.macro CALLOS_CHECK_POS
	beq :+		; Branch on success
.endmacro

.macro CALLOS_CHECK_NEG
	bne :+		; Branch on failure
.endmacro

.macro CONDITION_KEYPRESS
	and #$DF	; Convert to upper case
	ora #$80	; Turn high bit on
.endmacro

.macro LDA_BIGBUF_ADDR_HI
	lda FIND_SEG_BASE+1	; Was lda #>BIGBUF (the high part of the address)
	sec
	sbc #$20
	clc
.endmacro

.macro LDA_BIGBUF_ADDR_LO
	lda #$00
.endmacro

.macro GO_SLOW
	jsr GO_SLOW_SOS		; Defined in conio.asm
.endmacro

.macro GO_FAST
	jsr GO_FAST_SOS		; Defined in conio.asm
.endmacro

.macro CONDITION_CR
	cmp #$8d		; If the character is $8d, strip off $80
	bne :+
	lda #$0d
	:			; Need a place to go
.endmacro

.macro JSR_GET_PREFIX
; Nothing to see here...
.endmacro

.macro GO_MONITOR
	lda Z_REG
	sta USER_Z_REG
	lda E_REG
	sta USER_E_REG
	ora #$05		; Set ROM on, stack to alternate
	and #$FB
	sta E_REG
	lda #$03		; Use true zero page
	sta Z_REG
	jmp $F901		; Jump to the monitor
.endmacro

.macro GO_USER
	lda USER_E_REG
	sta E_REG		; Restore Environment register
	lda USER_Z_REG
	sta Z_REG		; Restore zero page
.endmacro
