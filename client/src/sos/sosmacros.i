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
	and #$DF	; Conver to upper case
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

.macro LDX_BIGBUF_ADDR_HI
	ldx FIND_SEG_BASE+1
.endmacro

.macro LDA_CH
	txa
	pha
	tya
	pha
	jsr READPOSN
	stx CH
	pla
	tay
	pla
	tax
	lda CH
.endmacro

.macro SET_HTAB
	jsr HTAB
.endmacro

.macro GO_SLOW
	lda $FFDF			; Read the environment register
	ora #$80			; Set 1MHz switch
	sta $FFDF			; Write the environment register
.endmacro

.macro GO_FAST
	lda $FFDF			; Read the environment register
	and #$7f			; Set 2MHz switch
	sta $FFDF			; Write the environment register
.endmacro

.macro CONDITION_CR
	cmp #$8d			; If the character is $8d, strip off $80
	bne :+
	lda #$0d
	:				; Need a place to go
.endmacro

.macro JSR_GET_PREFIX
; Nothing to see here...
.endmacro

.define	NRM_BLOCK $11,$20
.define	INV_BLOCK $12,$20,$11
