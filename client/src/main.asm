;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2011 by David Schmidt
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

; Indices into menu highlighting coordinate table
MENU_SEND	= $00
MENU_RECEIVE	= $03
MENU_DIR	= $06
MENU_BATCH	= $09
MENU_CD		= $0c
MENU_VOLUMES	= $0f
MENU_CONFIG	= $12
MENU_FORMAT	= $15
MENU_ABOUT	= $18
MENU_QUIT	= $1b

entrypoint:

;---------------------------------------------------------
; Start us up
;---------------------------------------------------------
	;sei
	cld

	tsx		; Get a handle to the stackptr
	stx top_stack	; Save it for full pops during aborts

	jsr INIT_SCREEN	; Sets up the screen for behaviors we expect
	jsr MAKETBL	; Prepare our CRC tables
	jsr PARMDFT	; Set up parameters
	JSR_GET_PREFIX	; Get our current prefix (ProDOS only)
	jsr BLOAD	; Load up user parameters, if any
	jsr HOME	; Clear screen
	jsr PARMINT	; Interpret parameters - may leave a complaint
	jmp MAINL	; And off we go!

;---------------------------------------------------------
; Main loop
;---------------------------------------------------------
MAINLUP:
	jsr HOME	; Clear screen

MAINL:
RESETIO:
	jsr $0000	; Pseudo-indirect JSR to reset the IO device
	jsr MainScreen
	lda CUR_MENU
	jsr HILIGHT_ABSOLUTE	; Start menu highlighting

;---------------------------------------------------------
; KBDLUP
;
; Keyboard handler, dispatcher
;---------------------------------------------------------
KBDLUP:
	jsr READ_CHAR	; GET ANSWER
	CONDITION_KEYPRESS	; Convert to upper case, etc.  OS dependent.

KSEND:	cmp #CHR_S	; SEND?
	bne KRECV	; Nope
KSENDENTRY:
	lda #MENU_SEND
	jsr HILIGHT_MENU
	jsr SEND	; YES, DO SEND ROUTINE
	jmp MAINLUP

KRECV:	cmp #CHR_R	; RECEIVE?
	bne KDIR	; Nope
KRECVENTRY:
	lda #MENU_RECEIVE
	jsr HILIGHT_MENU
	jsr RECEIVE
	jmp MAINLUP

KDIR:	cmp #CHR_D	; DIR?
	bne KBATCH		; Nope, try CD
KDIRENTRY:
	lda #MENU_DIR
	jsr HILIGHT_MENU
	jsr DIR	  	; Yes, do DIR routine
	jmp MAINLUP

KBATCH:
	cmp #CHR_B	; Batch processing?
	bne KCD		; Nope
KBATCHENTRY:
	ldy #PMNULL	; No title line
	lda #MENU_BATCH
	jsr HILIGHT_MENU
	jsr BATCH	; Set up batch processing
	jmp MAINLUP

KCD:	cmp #CHR_C	; CD?
	bne KCONF	; Nope
KCDENTRY:
	lda #MENU_CD
	jsr HILIGHT_MENU
	jsr CD	  	; Yes, do CD routine
	jmp MAINLUP

KCONF:	cmp #CHR_G	; Configure?
	bne KABOUT	; Nope
KCONFENTRY:
	lda #MENU_CONFIG
	jsr HILIGHT_MENU
	jsr CONFIG      ; YES, DO CONFIGURE ROUTINE
	jsr HOME	; Clear screen; PARMINT may leave a complaint
	jsr PARMINT     ; AND INTERPRET PARAMETERS
	jmp MAINL


KABOUT:	cmp #$9F	; ABOUT MESSAGE? ("?" KEY)
	bne KVOLUMS	; Nope
KABOUTENTRY:
	lda #MENU_ABOUT
	jsr HILIGHT_MENU
	lda #$15
	jsr TABV
	ldy #PMSG17	; "About" message
	jsr WRITEMSGLEFT
	jsr READ_CHAR
	jmp MAINLUP	; Clear and start over

KVOLUMS:
	cmp #CHR_V	; Volumes online?
	bne KFORMAT	; Nope
KVOLUMSENTRY:
	lda #MENU_VOLUMES
	jsr HILIGHT_MENU
	ldy #PMNULL	; No title line
	jsr PICKVOL	; Pick a volume - A has index into DEVICES table
	jmp MAINLUP

KFORMAT:
	cmp #CHR_F	; Format?
	bne KQUIT	; Nope
KFORMATENTRY:
	lda #MENU_FORMAT
	jsr HILIGHT_MENU
	jsr FormatEntry	; Run formatter
	jmp MAINLUP

KQUIT:
	cmp #CHR_Q	; Quit?
	bne KLEFT	; Nope
KQUITENTRY:
	lda #MENU_QUIT
	jsr HILIGHT_MENU
	jmp QUIT	; Head into OS oblivion

KLEFT:
	cmp #$88	; Left?
	bne KRIGHT
	ldx CUR_MENU
	dex
	dex
	dex
	txa
	bpl :+
	lda #MENU_QUIT
:	jsr HILIGHT_MENU
	jmp KBDLUP

KRIGHT:
	cmp #$95	; Right?
	bne KUP
	ldx CUR_MENU
	inx
	inx
	inx
	cpx #MENU_QUIT+3
	bne :+
	ldx #MENU_SEND
:	txa
	jsr HILIGHT_MENU
	jmp KBDLUP

KUP:	cmp #$8b	; Up?
	bne KDOWN
	lda CUR_MENU
	cmp #$0d	; Are we on the top row?
	bpl :+
	clc
	adc #$0f
	jmp @UpGo
:	sec
	sbc #$0f
@UpGo:	jsr HILIGHT_MENU
	jmp KBDLUP

KDOWN:	cmp #$8a	; Down?
	bne KRETURN
	lda CUR_MENU
	cmp #$0f	; Are we on the bottom row?
	bmi :+
	sec
	sbc #$0f
	jmp @DnGo
:	clc
	adc #$0f
@DnGo:	jsr HILIGHT_MENU
	jmp KBDLUP

KRETURN:
	cmp #$8d	; Return?
	bne FORWARD
	lda CUR_MENU	; Execute the function that is currently highlit
	cmp #MENU_SEND
	bne :+
	jmp KSENDENTRY
:	cmp #MENU_RECEIVE
	bne :+
	jmp KRECVENTRY
:	cmp #MENU_DIR
	bne :+
	jmp KDIRENTRY
:	cmp #MENU_BATCH
	bne :+
	jmp KBATCHENTRY
:	cmp #MENU_CD
	bne :+
	jmp KCDENTRY
:	cmp #MENU_VOLUMES
	bne :+
	jmp KVOLUMSENTRY
:	cmp #MENU_CONFIG
	bne :+
	jmp KCONFENTRY
:	cmp #MENU_FORMAT
	bne :+
	jmp KFORMATENTRY
:	cmp #MENU_ABOUT
	bne :+
	jmp KABOUTENTRY
:	cmp #MENU_QUIT
	bne FORWARD	; Should not occur
	jmp KQUITENTRY
FORWARD:
	jmp KBDLUP


;---------------------------------------------------------
; MainScreen - Show the main screen
;---------------------------------------------------------
MainScreen:
	jsr SHOWLOGO
	ldx #$02
	ldy #$0e
	jsr GOTOXY
	ldy #PMSG02	; Prompt line 1
	jsr WRITEMSG
	ldy #PMSG03	; Prompt line 2
	jsr WRITEMSG
	rts

;---------------------------------------------------------
; ABORT - STOP EVERYTHING (CALL BABORT TO BEEP ALSO)
;---------------------------------------------------------
BABORT:	jsr AWBEEP	; Beep!
ABORT:	ldx top_stack	; Pop goes the stackptr
	txs
	jsr motoroff	; Turn potentially active drive off
	bit $C010	; Strobe the keyboard
	jmp MAINLUP	; ... and restart

;---------------------------------------------------------
; AWBEEP - CUTE TWO-TONE BEEP (USES AXY)
;---------------------------------------------------------
AWBEEP:
	lda PSOUND	; IF SOUND OFF, RETURN NOW
	bne NOBEEP
	GO_SLOW		; Slow SOS down for this
	ldx #$0d	; Tone isn't quite the same as
	jsr BEEP1	; Apple Writer ][, but at least
	ldx #$0f	; it's the same on all CPU speeds.
BEEP1:	ldy #$85
BEEP2:	txa
BEEP3:	jsr DELAY
	bit $C030	; WHAP SPEAKER
	dey
	bne BEEP2
	GO_FAST		; Speed SOS back up
NOBEEP:	rts

;---------------------------------------------------------
; HILIGHT_MENU - highlights the current menu item, erases previous menu item
; Called with new menu in accumulator
;---------------------------------------------------------
HILIGHT_ABSOLUTE:
	tay
	jmp HI_GO
HILIGHT_MENU:
	cmp CUR_MENU	; If the new menu selection didn't change... don't do anything
	beq HI_DONE
	ldy CUR_MENU
	sty PREV_MENU
	sta CUR_MENU
	lda PREV_MENU
	cmp #$ff	; Skip if prev menu was undefined
	beq :+
	jsr HI_2
:	ldy CUR_MENU
HI_GO:	jsr HI_2
HI_DONE:
	rts

HI_2:	ldx #$03
:	lda MENUHITBL,y
	pha
	iny
	dex
	bne :-
	pla		; Pull Y, X, A for INVERSE operations
	tay
	pla
	tax
	pla
	jsr INVERSE
	rts

MOVE_MENU:
	rts

;---------------------------------------------------------
; Table of menu highlighting coordinates
; Length, Column, Row
;---------------------------------------------------------
MENUHITBL:
	.byte $06, $02, $0e ; Send
	.byte $09, $09, $0e ; Receive
	.byte $05, $13, $0e ; Dir
	.byte $07, $19, $0e ; Batch
	.byte $04, $21, $0e ; CD
	.byte $09, $00, $10 ; Volumes
	.byte $08, $0a, $10 ; Config
	.byte $08, $13, $10 ; Format
	.byte $03, $1c, $10 ; About
	.byte $06, $20, $10 ; Quit

CUR_MENU:
	.byte MENU_CONFIG
PREV_MENU:
	.byte $ff