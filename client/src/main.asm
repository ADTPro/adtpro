;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006, 2007 by David Schmidt
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

.include "applechr.i"
.include "const.i"
.include "ip65/common.i"

	.segment "SYS"
	.org $2000

;---------------------------------------------------------
; Initialization - free ProDOS BASIC Interpreter memory
;---------------------------------------------------------
INIT:
	STA   ROM        ; Swap in ROM
	LDX   #23        ; Initialize bitmap
	LDA   #%00000001 ; $BF00-$BFFF (ProDOS Global Page)
	STA   BITMAP,X
	DEX
	LDA   #0         ; free main memory
:	STA   BITMAP,X
	DEX
	BNE   :-         ; don't touch the $0000-$07FF aera

;---------------------------------------------------------
; Kill the reset vector
;---------------------------------------------------------
	lda #$69		; Vector reset to the monitor
	sta $03f2
	lda #$ff
	sta $03f3	; $ff69, aka CALL -151
	eor #$a5
	sta $03f4	; Fixup powerup byte 

;---------------------------------------------------------
; ProDOS SYS relocators
;---------------------------------------------------------
PRE_MOVER:		; Need to protect relocation code
	lda #<MOVER
	sta A1L
	lda #>MOVER
	sta A1H
	lda #<MOVEREND-1
	sta A2L
	lda #>MOVEREND
	sta A2H
	lda #$00
	sta A4L
	lda #$03
	sta A4H
	ldy #$00
	jsr MEMMOVE
	jmp $0300

MOVER:			; Relocate full program
	lda #<MOVEREND
	sta A1L
	lda #>MOVEREND
	sta A1H
	lda #<(MOVEREND+ASMEND-ASMBEGIN)
	sta A2L
	lda #>(MOVEREND+ASMEND-ASMBEGIN)
	sta A2H
	lda #$00
	sta A4L
	lda #$08
	sta A4H
	ldy #$00
	jsr MEMMOVE
	jmp $0800
MOVEREND:

;---------------------------------------------------------
; Mainline Code
;---------------------------------------------------------

	.segment "STARTUP"
	.org $0800	; After relocation, this orgs at $0800 

ASMBEGIN:
	jmp 	entrypoint

;---------------------------------------------------------
; calibrat - Calibrate the disk arm to track #0
; The code is essentially like in the Disk ][ card
;---------------------------------------------------------
calibrat:
	jsr	slot2x		; a = x = slot * 16
	sta	SLOWX		; store slot * 16 in memory
	lda	$c08e,x		; prepare latch for input
	lda	$c08c,x		; strobe data latch for i/o
	lda	pdrive		; is 0 for drive 1
	beq	caldriv1
	inx
caldriv1:
	lda	$c08a,x		; engage drive 1 or 2
	lda	SLOWX
	tax			; restore x
	lda	$c089,x		; motor on
	ldy	#$50		; number of half-tracks
caldriv3:
	lda	$c080,x		; stepper motor phase n off
	tya
	and	#$03		; make phase from count in y
	asl			; times 2
	ora	SLOWX		; make index for i/o address
	tax
	lda	$c081,x		; stepper motor phase n on
	lda	#$56		; param for wait loop
	jsr	$fca8		; wait specified time units
	dey			; decrement count
	bpl	caldriv3	; jump back while y >= 0
	rts

;---------------------------------------------------------
; seekabs - copy of standard dos seekabs at $B9A0.
; By copying it we are independent on the dos version, 
; while still avoiding rwts in the nibble copy function.
; On entry, x is slot * 16; A is desired half-track;
; $478 is current half-track
;---------------------------------------------------------
seekabs:
	stx	$2b
	sta	$2a
	cmp	$0478
	beq	seekabs9
	lda	#$00
	sta	$26
seekabs1:
	lda	$0478
	sta	$27
	sec
	sbc	$2a
	beq	seekabs6
	bcs	seekabs2
	eor	#$ff
	inc	$0478
	bcc	seekabs3
seekabs2:
	adc	#$fe
	dec	$0478
seekabs3:
	cmp	$26
	bcc	seekabs4
	lda	$26
seekabs4:
	cmp	#$0c
	bcs	seekabs5
	tay   
seekabs5:
	sec   
	jsr	seekabs7
	lda	delaytb1,y
	jsr	armdelay
	lda	$27
	clc
	jsr	seekabs8
	lda	delaytb2,y
	jsr	armdelay
	inc	$26
	bne	seekabs1
seekabs6:
	jsr	armdelay
	clc
seekabs7:
	lda	$0478
seekabs8:
	and	#$03
	rol
	ora	$2b
	tax
	lda	$c080,x
	ldx	$2b
seekabs9:
	rts

;---------------------------------------------------------
; armdelay - Copy of standard dos armdelay at $BA00
;---------------------------------------------------------
armdelay:
	ldx	#$11
armdela1:
	dex
	bne	armdela1
	inc	$46
	bne	armdela3
	inc	$47
armdela3:
	sec
	sbc	#$01
	bne	armdelay
	rts

;---------------------------------------------------------
; Next are two tables used in the arm movements. They must
; also lie in one page.
;---------------------------------------------------------
delaytb1:
	.byte $01,$30,$28,$24,$20,$1e 
	.byte $1d,$1c,$1c,$1c,$1c,$1c

delaytb2:
	.byte $70,$2c,$26,$22,$1f,$1e
	.byte $1d,$1c,$1c,$1c,$1c,$1c

entrypoint:

;---------------------------------------------------------
; Start us up
;---------------------------------------------------------
	sei
	cld

	tsx		; Get a handle to the stackptr
	stx top_stack	; Save it for full pops during aborts
	
	; Prepare the system for our expecations -
	; Basic, 64k Applesoft Apple ][.  That's all it
	; should take.

	jsr $FE84	; NORMAL TEXT
	jsr $FB2F	; TEXT MODE, FULL WINDOW
	jsr $FE89	; INPUT FROM KEYBOARD
	jsr $FE93	; OUTPUT TO 40-COL SCREEN
	jsr MAKETBL	; Prepare our CRC tables
	jsr PARMDFT	; Set up parameters
	jsr GET_PREFIX	; Get our current ProDOS prefix
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

	jsr SHOWLOGO

	lda #$02
	sta <CH
	lda #$0e
	jsr TABV
	ldy #PMSG02	; Prompt line 1
	jsr WRITEMSG

	ldy #PMSG03	; Prompt line 2
	jsr WRITEMSGLEFT


;---------------------------------------------------------
; KBDLUP
;
; Keyboard handler, dispatcher
;---------------------------------------------------------
KBDLUP:
	jsr RDKEY	; GET ANSWER
	and #$DF	; Conver to upper case

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
; ABORT - STOP EVERYTHING (CALL BABORT TO BEEP ALSO)
;---------------------------------------------------------
BABORT:	jsr AWBEEP	; Beep!
ABORT:	ldx top_stack	; Pop goes the stackptr
	txs
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

;---------------------------------------------------------
; Quit to ProDOS
;---------------------------------------------------------

QUIT:
	sta ROM
	jsr MLI
	.byte PD_QUIT
	.addr QUITL

QUITL:
	.byte	4
        .byte	$00,$00,$00,$00,$00,$00