;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2014 by David Schmidt
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
; Host command functions
; DIR, CD
;---------------------------------------------------------

;---------------------------------------------------------
; DIR - get directory from the host and print it
; Modes: 
;  - Plain directory display; pages up and down
;  - Chooser display; pages up and down, hitting return selects one (input buffer will hold chosen name)
; BLKPTR should be set to the beginning of the receive buffer
;---------------------------------------------------------
HOSTTIMEOUT:
	ldy #PHMTIMEOUT
	jsr SHOWHM1
	jsr PAUSE
	rts

DIR:
	jsr GETFN
DIR1:	lda #$00	; Screen page number zero
	sta NIBPCNT	; Borrow NIBPCNT for that purpose
	sta NDUHIGHWATER
	sta NDUCANCONT
	sta NDULASTPAGE
	sta NDULASTROW
	ldy #$03
	sty COL_SAV	; Borrow COL_SAV as vertical position counter

DIRWARM:
	ldy #PMWAIT
	jsr WRITEMSGAREA

:	jsr DIRREQUEST
	jsr DIRREPLY
	bcs :-
	ldy TMOT
	bne HOSTTIMEOUT

DIRDISP0:
	jsr HOME	; Clear screen
	ldy #$00	; Reset counter

DIRDISP:
	lda (Buffer),Y	; Get byte from buffer
	php		; Save flags
	iny		; Bump
	bne DIRMORE	; Skip
	inc Buffer+1	; Next 256 bytes
DIRMORE:
	plp		; Restore flags
	beq DIRPAGE	; Page or dir end?
	ora #$80
	CONDITION_CR	; SOS needs to fix up the carriage return
	jsr COUT1	; Display
	jmp DIRDISP	; Loop back around

DIRPAGE:
	lda (Buffer),Y	; Get byte from buffer
	sta NDUCANCONT	; Save that off
	bne @NewUI
	LDA_CV
	sta NDULASTROW	; Save that off
	dec NDULASTROW
	lda NIBPCNT
	sta NDULASTPAGE

@NewUI:	lda NDULASTROW
	cmp #$02
	bne :+
	jmp CDMSG
:	ldy #PMSG23a		; SELECT WITH RETURN, ESC CANCELS
	jsr WRITEMSGAREA

NDURedraw:
	jsr NDUInvertCurrentLine
NDUNavLoop:
	jsr READ_CHAR		; Wait for input
	CONDITION_KEYPRESS	; Convert to upper case, etc.  OS dependent.
	sta ZP			; Borrow ZP for remembering keypress
	cmp #CHR_A
	bne @TryUp
	jmp NDUPageUp	
@TryUp:
	cmp #$8b		; Up?
	beq @IsUp
	cmp #$88		; Left?
	beq @IsUp
	bne @TryDown
@IsUp:	lda COL_SAV
	cmp #$03		; Are we at the top of the page?
	bne @RoomForUp
	jmp NDUPageUp
@RoomForUp:
	jsr NDUUnInvertCurrentLine
	dec COL_SAV
	jmp NDURedraw
@TryDown:
	cmp #CHR_Z
	bne :+
	jmp NDUPageDown
:	cmp #$8a		; Down?
	beq @IsDown
	cmp #$95		; Right?
	beq @IsDown
	bne @TryReturn
@IsDown:
	lda NIBPCNT
	cmp NDULASTPAGE		; Are we on the last page?
	bne :+			; No - go for it
	LDA_CV
	cmp NDULASTROW		; Yes - are we on the last line?
	bne :+			; No - go for it
	jmp NDUNavLoop		; Yes - nowhere to go, so forget it
:	lda COL_SAV
	cmp #$14
	bne @RoomForDown
	jmp NDUPageDown
@RoomForDown:
	jsr NDUUnInvertCurrentLine
	inc COL_SAV
	jmp NDURedraw
@TryReturn:
	cmp #$8d		; Return?
	bne :+
	jsr NDUUnInvertCurrentLine	; Un-invert currentline
	jsr SCRAPE		; Scrape the line contents
	clc
	rts
:	cmp #CHR_ESC
	beq :+
	jmp NDUNavLoop
:	sec			; Escaped out
	rts

NDUPageUp:
	lda NIBPCNT
	bne @Top
	jmp NDUNavLoop
@Top:	dec NIBPCNT
	LDA_BIGBUF_ADDR_LO	; Re-connect the block pointer to the
	sta Buffer		; Big Buffer(TM), 1k * NIBPCNT again
	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta Buffer+1
	lda ZP
	cmp #CHR_A		; was it page up?
	bne :+			; No, so branch forward and put the cursor at the bottom of the screen
	lda #$03		; Yes, so put the cursor at the top of the screen.
	jmp @Sta
:	lda #$14
@Sta:	sta COL_SAV
	jmp DIRDISP0

NDUPageDown:
	lda NIBPCNT
	cmp #$13		; Are we at the end of our buffer space?
	bne :+			; No - go for it
	jmp NDUNavLoop		; Yes - nothing to do
:	lda NDUCANCONT		; Are we on the last page?
	bne :+			; No - go for it
	jmp NDUNavLoop		; Yes - nothing to do
:	lda #$03
	sta COL_SAV
	lda NIBPCNT
	cmp NDUHIGHWATER	; Have we been to this page already?
	bpl @NeedIt		; No - go get it
	jmp @AlreadyHaveIt	; Yes - show it from memory
; Ready to ask for another page...
@NeedIt:
	inc NIBPCNT
	inc NDUHIGHWATER
	jmp DIRWARM
@AlreadyHaveIt:
	inc NIBPCNT
	LDA_BIGBUF_ADDR_LO	; Re-connect the block pointer to the
	sta Buffer		; Big Buffer(TM), 1k * NIBPCNT again
	LDA_BIGBUF_ADDR_HI
	clc
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	adc NIBPCNT
	sta Buffer+1
	lda #$03
	sta COL_SAV
	jmp DIRDISP0

NDUUnInvertCurrentLine:
	SET_INVERSE_SOS
	jmp NDUInvertGo
NDUInvertCurrentLine:
	SET_UNINVERSE_SOS
NDUInvertGo:
	ldy COL_SAV
	ldx #$00
	lda #$28
	jsr INV_GO
	rts

NDUCANCONT:
	.byte $00
NDULASTPAGE:
	.byte $00
NDULASTROW:
	.byte $00
NDUHIGHWATER:
	.byte $00
;---------------------------------------------------------
; CD - Change directory
;---------------------------------------------------------

CD:
	jsr GETFN1
	bne CDSTART
	jmp CDDONE

CDSTART:
	ldy #PMWAIT
	jsr WRITEMSGAREA	; Tell user to have patience
	jsr CDREQUEST
	jsr CDREPLY
	bcs CDTIMEOUT
	bne CDERROR
CDMSG:	ldy #PMSG14
	jsr WRITEMSGAREA
	jsr PAUSE

CDDONE:
	rts

CDTIMEOUT:
	lda #PHMTIMEOUT
CDERROR:
	tay
	jsr SHOWHM1
	jsr PAUSE
	jmp ABORT
