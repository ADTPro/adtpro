;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2008 by David Schmidt
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

entrypoint:

;---------------------------------------------------------
; Start us up
;---------------------------------------------------------
	sei
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

;---------------------------------------------------------
; KBDLUP
;
; Keyboard handler, dispatcher
;---------------------------------------------------------
KBDLUP:
	jsr RDKEY	; GET ANSWER
	CONDITION_KEYPRESS	; Convert to upper case, etc.  OS dependent.

KSEND:	cmp #CHR_S	; SEND?
	bne :+		; Nope
	lda #$06
        ldx #$02
	ldy #$0e
	jsr INVERSE
	jsr SEND	; YES, DO SEND ROUTINE
	jmp MAINLUP
:
KRECV:	cmp #CHR_R	; RECEIVE?
	bne :+		; Nope
	lda #$09
	ldx #$09
	ldy #$0e
	jsr INVERSE
	jsr RECEIVE
	jmp MAINLUP
:
KDIR:	cmp #CHR_D	; DIR?
	bne :+		; Nope, try CD
	lda #$05
	ldx #$13
	ldy #$0e
	jsr INVERSE
	jsr DIR	  	; Yes, do DIR routine
	jmp MAINLUP
:
KBATCH:
	cmp #CHR_B	; Batch processing?
	bne :+		; Nope
	ldy #PMNULL	; No title line
	lda #$07
        ldx #$19
	ldy #$0e
	jsr INVERSE
	jsr BATCH	; Set up batch processing
	jmp MAINLUP
:
KCD:	cmp #CHR_C	; CD?
	bne :+		; Nope
	lda #$04
        ldx #$21
	ldy #$0e
	jsr INVERSE
	jsr CD	  	; Yes, do CD routine
	jmp MAINLUP
:
KCONF:	cmp #CHR_G	; Configure?
	bne :+		; Nope
	jsr CONFIG      ; YES, DO CONFIGURE ROUTINE
	jsr HOME	; Clear screen; PARMINT may leave a complaint
	jsr PARMINT     ; AND INTERPRET PARAMETERS
	jmp MAINL

:
KABOUT:	cmp #$9F	; ABOUT MESSAGE? ("?" KEY)
	bne :+		; Nope
	lda #$03
        ldx #$1C
	ldy #$10
	jsr INVERSE
	lda #$15
	jsr TABV
	ldy #PMSG17	; "About" message
	jsr WRITEMSGLEFT
	jsr RDKEY
	jmp MAINLUP	; Clear and start over
:
KVOLUMS:
	cmp #CHR_V	; Volumes online?
	bne :+		; Nope
	ldy #PMNULL	; No title line
	jsr PICKVOL	; Pick a volume - A has index into DEVICES table
	jmp MAINLUP
:
KFORMAT:
	cmp #CHR_F	; Format?
	bne :+		; Nope
	jsr FormatEntry	; Run formatter
	jmp MAINLUP
:
KQUIT:
	cmp #CHR_Q	; Quit?
	bne FORWARD	; No, it was an unknown key
	cli
	jmp QUIT	; Head into ProDOS oblivion

FORWARD:
	jmp MAINL


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
	ldx #$0d	; Tone isn't quite the same as
	jsr BEEP1	; Apple Writer ][, but at least
	ldx #$0f	; it's the same on all CPU speeds.
BEEP1:	ldy #$85
BEEP2:	txa
BEEP3:	jsr DELAY
	bit $C030	; WHAP SPEAKER
	dey
	bne BEEP2
NOBEEP:	rts
