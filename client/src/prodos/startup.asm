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
FILE_INFO_ADDR:
	.word	$0000	;AUX_TYPE
	.byte	$00		;STORAGE_TYPE
	.word	$0000	;BLOCKS_USED
	.word	$0000	;MOD_DATE
	.word	$0000	;MOD_TIME
	.word	$0000	;CREATE_DATE
	.word	$0000	;CREATE_TIME

OPEN_PARAM:
	.byte	$03		;PARAM_COUNT
	.addr	KEYBUFF	;KEYBUFF
	.addr	PRODOS_MLI - 1024	;IO_BUFFER
OPEN_REF:	.byte	$00	;REF_NUM

NAME_SERIAL:
	.asciiz	"ADTPRO.BIN"
NAME_ETHERNET:
	.asciiz	"ADTPROETH.BIN"
NAME_AUDIO:
	.asciiz	"ADTPROAUD.BIN"

NEWLINE:
	.byte $04

MSG1:
	asc		"WELCOME TO THE ADTPRO DISTRIBUTION!"
	.byte $8d, $8d
	asc	"PLEASE SELECT WHICH PROGRAM TO START:"
	.byte $8d, $8d
SerialLine:
	asc	"(S)ERIAL   : SSC OR IIGS/IIC MODEM PORT"
SerialLineEnd:
	.byte $8d
AudioLine:
	asc	"(A)UDIO    : CASSETTE/AUDIO PORTS"
AudioLineEnd:
	.byte $8d
EthernetLine:
	asc "(E)THERNET : A2RETROSYSTEMS UTHERNET"
EthernetLineEnd:
	.byte $00

LOADING:
	.byte $8d
	asc "STARTING "
	.byte $00

ELLIPSES:
	.byte	"...", $8d, $8d, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment	"DATA_0300"

READ_PARAM:
	.byte	$04		;PARAM_COUNT
READ_REF:
	.byte	$00		;REF_NUM
READ_ADDR:
	.addr	$0000	;DATA_BUFFER
	.word	$FFFF	;REQUEST_COUNT
	.word	$0000	;TRANS_COUNT

CLOSE_PARAM:
	.byte	$01		;PARAM_COUNT
CLOSE_REF:
	.byte	$00		;REF_NUM

QUIT_PARAM:
	.byte	$04		;PARAM_COUNT
	.byte	$00		;QUIT_TYPE
	.word	$0000	;RESERVED
	.byte	$00		;RESERVED
	.word	$0000	;RESERVED

FILE_NOT_FOUND:
	.asciiz	"... FILE NOT FOUND"
				
ERROR_NUMBER:
	.asciiz	"... ERROR $"

PRESS_ANY_KEY:
	.asciiz	" - PRESS ANY KEY "

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment	"CODE_2000"

; Reset stack
	ldx	#$FF
	txs

	; Relocate CODE_0300 and DATA_0300
	ldx	#<(__CODE_0300_SIZE__ + __DATA_0300_SIZE__)
:	lda	__CODE_0300_LOAD__ - 1,x
	sta	__CODE_0300_RUN__ - 1,x
	dex
	bne	:-

	jsr $FE84	; NORMAL TEXT
	jsr $FB2F	; TEXT MODE, FULL WINDOW
	jsr $FE89	; INPUT FROM KEYBOARD
	jsr $FE93	; OUTPUT TO 40-COL SCREEN
	lda #$00
	sta CH
	sta CV
	jsr CLREOP

	lda	#<MSG1
	ldx	#>MSG1
	jsr	PRINT

	lda #$00
	sta CH
	lda #$04
	sta CV
	jsr ToggleLine

KbdLoop:
	lda #$01
	sta CH 
	jsr RDKEY		; Read a key
	and #$DF		; Convert to upper case

	cmp #CHR_S	; Serial?
	bne :+
	lda #$04
	sta NEWLINE
	jmp KbdDone	

:	cmp #CHR_A	; Audio?
	bne :+
	lda #$05
	sta NEWLINE
	jmp KbdDone	
	
:	cmp #CHR_E	; Ethernet?
 	bne :+
	lda #$06
	sta NEWLINE
	jmp KbdDone	

:	cmp #$8d		; Return?
	bne :+
	jmp KbdDone 
	
:	cmp #$88		; Left?
	beq IsLeft
	cmp #$8b		; Up?
	bne NotLeft
IsLeft:
	lda CV
	cmp #$04
	beq LeftWrap
	sec
	sbc #$01
	sta NEWLINE
LeftGo:
	jsr HighlightLine
	jmp KbdLoop
LeftWrap:
	lda #$06
	sta NEWLINE
	jmp LeftGo

NotLeft:
	cmp #$95		; Right?
	beq IsRight
	cmp #$8a		; Down?
	bne NotRight
IsRight:
	lda CV
	cmp #$06
	beq RightWrap
	clc
	adc #$01
	sta NEWLINE
RightGo:
	jsr HighlightLine
	jmp KbdLoop
RightWrap:
	lda #$04
	sta NEWLINE
	jmp RightGo

NotRight:
	cmp #$0d
	jmp KbdLoop

KbdDone:
	jsr HighlightLine
	lda #$08
	sta CV
	jsr TABV

	; Provide some user feedback
	lda	#<LOADING
	ldx	#>LOADING
	jsr	PRINT
	lda	#<(KEYBUFF + 1)
	ldx	#>(KEYBUFF + 1)
	jsr	PRINT
	lda	#<ELLIPSES
	ldx	#>ELLIPSES
	jsr	PRINT

	jsr	PRODOS_MLI
	.byte	OS_GET_FILE_INFO
	.word	GET_FILE_INFO_PARAM
	bcc	:+
	jmp	ERROR

:	jsr	PRODOS_MLI
	.byte	OS_OPEN
	.word	OPEN_PARAM
	bcc	:+
	jmp	ERROR

	; Copy file reference number
:	lda	OPEN_REF
	sta	READ_REF
	sta	CLOSE_REF

	; Get load address from aux-type
	lda	FILE_INFO_ADDR
	ldx	FILE_INFO_ADDR + 1
	sta	READ_ADDR
	stx	READ_ADDR + 1

	; It's high time to leave this place
	jmp	__CODE_0300_RUN__

HighlightLine:
	jsr ToggleLine
	lda NEWLINE
	sta CV
	jsr ToggleLine
	rts

ToggleLine:
	lda CV
Line4:
	cmp #$04
	bne Line5
	tay
	lda #SerialLineEnd-SerialLine
	jsr INVERSE
	ldx #$ff
:	inx
	lda NAME_SERIAL,x
	sta KEYBUFF+1,x
	bne :-
	stx KEYBUFF
	rts
Line5:
	cmp #$05
	bne Line6
	tay
	lda #AudioLineEnd-AudioLine
	jsr INVERSE
	ldx #$ff
:	inx
	lda NAME_AUDIO,x
	sta KEYBUFF+1,x
	bne :-
	stx KEYBUFF
	rts
Line6:
	tay
	lda #EthernetLineEnd-EthernetLine
	jsr INVERSE
	ldx #$ff
:	inx
	lda NAME_ETHERNET,x
	sta KEYBUFF+1,x
	bne :-
	stx KEYBUFF
	rts

;---------------------------------------------------------
; INVERSE - Invert/highlight the characters on the screen
;
; Inputs:
;   A - number of bytes to process
;   Y - starting y coordinate
;---------------------------------------------------------
INVERSE:
	clc
	sta INUM
	lda #$00
	sta CH		; Set cursor to first position
	adc INUM
	sta INUM
	tya
	jsr TABV
	ldy CH
INV1:
	lda (BASL),Y
	and #$BF
	eor #$80
	sta (BASL),Y
	iny
	cpy INUM
	bne INV1
	rts

INUM:
	.byte $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.segment	"CODE_0300"

	jsr	PRODOS_MLI
	.byte	OS_READFILE
	.word	READ_PARAM
	bcs	ERROR

	jsr	PRODOS_MLI
	.byte	OS_CLOSE
	.word	CLOSE_PARAM
	bcs	ERROR

	; Go for it ...
	jmp	(READ_ADDR)

PRINT:
	sta	A1L
	stx	A1H
	ldx	VERSION
	ldy	#$00
PrintNext:
	lda	(A1L),y
	beq	PrintDone
	ora #$80
	jsr	COUT
	iny
	bne	PrintNext	; bra
PrintDone:
	rts

ERROR:
	cmp	#FNFERR
	bne	:+
	lda	#<FILE_NOT_FOUND
	ldx	#>FILE_NOT_FOUND
	jsr	PRINT
	beq	:++		; bra
:	pha
	lda	#<ERROR_NUMBER
	ldx	#>ERROR_NUMBER
	jsr	PRINT
	pla
	jsr	PRBYTE
:	lda	#<PRESS_ANY_KEY
	ldx	#>PRESS_ANY_KEY
	jsr	PRINT
	jsr	RDKEY
	jsr	PRODOS_MLI
	.byte	OS_QUIT
	.word	QUIT_PARAM
