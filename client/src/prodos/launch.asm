;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2010 by David Schmidt
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

	.include "prodos/prodosmacros.i"	; OS macros
	.include "prodos/prodosconst.i"	; OS equates, characters, etc.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                                                                               ;
; Apple][ ProDOS 8 loader adapted from Oliver Schmidt's LOADER.SYSTEM           ;
;                                                                               ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	.import	__CODE_0300_SIZE__, __DATA_0300_SIZE__
	.import	__CODE_0300_LOAD__, __CODE_0300_RUN__

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment	"DATA_2000"

GET_FILE_INFO_PARAM:
	.byte	$0A		;PARAM_COUNT
	.addr	KEYBUFF	;KEYBUFF
	.byte	$00		;ACCESS
	.byte	$00		;FILE_TYPE
FILE_INFO_ADDR:	.word	$0000		;AUX_TYPE
	.byte	$00		;STORAGE_TYPE
	.word	$0000		;BLOCKS_USED
	.word	$0000		;MOD_DATE
	.word	$0000		;MOD_TIME
	.word	$0000		;CREATE_DATE
	.word	$0000		;CREATE_TIME

OPEN_PARAM:
	.byte	$03		;PARAM_COUNT
	.addr	KEYBUFF	;KEYBUFF
	.addr	PRODOS_MLI - 1024	;IO_BUFFER
OPEN_REF:	.byte	$00		;REF_NUM

LOADING:
	.byte	$0D
	.asciiz	"STARTING "

ELLIPSES:
	.byte	"...", $8D, $8D, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment	"DATA_0300"

READ_PARAM:
	.byte	$04		;PARAM_COUNT
READ_REF:
	.byte	$00		;REF_NUM
READ_ADDR:
	.addr	$0000		;DATA_BUFFER
	.word	$FFFF		;REQUEST_COUNT
	.word	$0000		;TRANS_COUNT

CLOSE_PARAM:
	.byte	$01		;PARAM_COUNT
CLOSE_REF:
	.byte	$00		;REF_NUM

QUIT_PARAM:
	.byte	$04		;PARAM_COUNT
	.byte	$00		;QUIT_TYPE
	.word	$0000		;RESERVED
	.byte	$00		;RESERVED
	.word	$0000		;RESERVED

FILE_NOT_FOUND:
	.asciiz	"... FILE NOT FOUND"
				
ERROR_NUMBER:
	.asciiz	"... ERROR $"

PRESS_ANY_KEY:
	.asciiz	" - PRESS ANY KEY "

SUFFIX:
	.asciiz ".BIN"

SYSTEM:
	.asciiz ".SYSTEM"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment	"CODE_2000"

STARTUP:
	; Reset stack
	ldx #$FF
	txs

	; Relocate CODE_0300 and DATA_0300
	ldx #<(__CODE_0300_SIZE__ + __DATA_0300_SIZE__)
:	lda __CODE_0300_LOAD__ - 1,x
	sta __CODE_0300_RUN__ - 1,x
	dex
	bne :-

	; Check for .SYSTEM suffix
	lda KEYBUFF
	ldy #$07
	tax
	inx
:
	dex
	dey
	bmi :+
	lda KEYBUFF,x
	cmp SYSTEM,y
	beq :-
	bne ADD	; bra
:
	; Remove .SYSTEM if it's there
	lda KEYBUFF
	sec
	sbc #$07
	sta KEYBUFF	

ADD:
	; Add ".BIN" to suffix
	lda KEYBUFF
	tax
	clc
	adc #$04
	sta KEYBUFF 

	ldy #$ff
:	inx
	iny
	lda SUFFIX,y
	sta KEYBUFF,x	; Copy over suffix, including null terminator
	bne :-

	; Provide some user feedback
	lda #$00
	sta CV
	sta CH
	jsr CLREOP	; Clear the screen
	lda #$01
	sta CV
	jsr TABV
	lda #<LOADING
	ldx #>LOADING
	jsr PRINT
	lda #<(KEYBUFF + 1)
	ldx #>(KEYBUFF + 1)
	jsr PRINT
	lda #<ELLIPSES
	ldx #>ELLIPSES
	jsr PRINT

	jsr PRODOS_MLI
	.byte	OS_GET_FILE_INFO
	.word	GET_FILE_INFO_PARAM
	bcc :+
	jmp ERROR

:	jsr PRODOS_MLI
	.byte	OS_OPEN
	.word	OPEN_PARAM
	bcc :+
	jmp ERROR

	; Copy file reference number
:	lda OPEN_REF
	sta READ_REF
	sta CLOSE_REF

	; Get load address from aux-type
	lda FILE_INFO_ADDR
	ldx FILE_INFO_ADDR + 1
	sta READ_ADDR
	stx READ_ADDR + 1

	; It's high time to leave this place
	jmp __CODE_0300_RUN__

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment "CODE_0300"

	jsr PRODOS_MLI
	.byte	OS_READFILE
	.word	READ_PARAM
	bcs ERROR

	jsr PRODOS_MLI
	.byte	OS_CLOSE
	.word	CLOSE_PARAM
	bcs ERROR

	; Go for it ...
	jmp (READ_ADDR)

PRINT:
	sta A1L
	stx A1H
	ldy #$00
PrintNext:
	lda (A1L),y
	beq PrintDone
	ora #$80
	jsr COUT
	iny
	bne PrintNext	; bra
PrintDone:
	rts

ERROR:
	cmp #FNFERR
	bne :+
	lda #<FILE_NOT_FOUND
	ldx #>FILE_NOT_FOUND
	jsr PRINT
	beq :++		; bra
:	pha
	lda #<ERROR_NUMBER
	ldx #>ERROR_NUMBER
	jsr PRINT
	pla
	jsr PRBYTE
:	lda #<PRESS_ANY_KEY
	ldx #>PRESS_ANY_KEY
	jsr PRINT
	jsr RDKEY
	jsr PRODOS_MLI
	.byte	OS_QUIT
	.word	QUIT_PARAM
