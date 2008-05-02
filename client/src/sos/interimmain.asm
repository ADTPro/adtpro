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

	.segment "STARTUP"

;---------------------------------------------------------
; calibrat - Calibrate the disk arm to track #0
; The code is essentially like in the Disk ][ card
;---------------------------------------------------------
calibrat:
	ldx pdsoftx		; Get soft switch offset
	lda	$c08e,x		; prepare latch for input
	lda	$c08c,x		; strobe data latch for i/o
	lda	pdrive		; is 0 for drive 1
	beq	caldriv1
	inx
caldriv1:
	lda	$c08a,x		; engage drive 1 or 2
	ldx pdsoftx
	lda	$c089,x		; motor on
	ldy	#$50		; number of half-tracks
caldriv3:
	lda	$c080,x		; stepper motor phase n off
	tya
	and	#$03		; make phase from count in y
	asl			; times 2
	ora	pdsoftx		; make index for i/o address
	tax
	lda	$c081,x		; stepper motor phase n on
	lda	#$56		; param for wait loop
	jsr	$fca8		; wait specified time units
	dey			; decrement count
	bpl	caldriv3	; jump back while y >= 0
	rts

;---------------------------------------------------------
; rdnibtr - read track as nibbles into tracks buffer.
; total bytes read is NIBPAGES * 256, or about twice
; the track length.
; the drive has been calibrated, so we know we are in read
; mode, the motor is running, and and the correct drive 
; number is engaged.
; we wait until we encounter a first nibble after a gap.
; for this purpose, a gap is at least 4 ff nibbles in a 
; row. note this is not 100% fool proof; the ff nibble
; can occur as a regular nibble instead of autosync.
; but this is conform beneath apple dos, so is
; probably ok.
;---------------------------------------------------------
;readtrk:
;rdnibtr:
;	ldx pdsoftx		; Load drive index into X
;	lda #0			; a = 0
;	tay			; y = 0 (index)
;	sta BLKPTR		; set running ptr (lo) to 0
;	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
;	sta BLKPTR+1		; set running ptr (hi)
;	lda #NIBPAGES
;	sta NIBPCNT		; page counter
; use jmp, not jsr, to perform nibsync. that way we
; have a bit more breathing room, cycle-wise. the
; "function" returns with a jmp to rdnibtr8.
;	jmp	nibsync		; find first post-gap byte
; the read loop must be fast enough to read 1 byte every
; 32 cycles. it appears the interval is 17 cycles within
; one data page, and 29 cycles when crossing a data page.
; these numbers are based on code that does not cross
; a page boundary.
;rdnibtr7:
;	lda $c08c,x		; read (4 cycles)
;	bpl rdnibtr7		; until byte complete (2c)
;rdnibtr8:
;	sta (BLKPTR),y		; store in buffer (6c)
;	iny			; (2c)
;	bne rdnibtr7		; 256 bytes done? (2 / 3c)
;	inc BLKPTR+1		; next page (5c)
;	dec NIBPCNT		; count (5c)
;	bne rdnibtr7		; and back (3c)
;	rts

;---------------------------------------------------------
; Read a full track, marking long and short self-sync nibbles
;
; By: Stephen Thomas
; See: http://groups.google.com/group/comp.sys.apple2/browse_frm/thread/39e58a5f3b931906/bc1732d9d6b53e0a
;      http://groups.google.com/group/comp.emulators.apple2/browse_frm/thread/76c414b1ee96eda1/#
; Hacked to self-modify disk read hardware address
;---------------------------------------------------------
rdnibtr:
;readtrk:
	lda #0			; a = 0
	tay			; y = 0 (index)
	sta BLKPTR		; set running ptr (lo) to 0
	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
	sta BLKPTR+1		; set running ptr (hi)
	lda pdsoftx		; Get soft switch offset
	clc
	adc #$8c		; Build the LSB of Disk HW address
	sta dpll+1		; Self-modify in the places used
	sta rt04+1
	sta rt08+1
	sta rt15+1
	ldx #$7F

dpll:	lda DRVRD	; check for data at rt=0
rt01:	bpl rt04	; if none, check again at rt=7
rt03:	bmi rt08	; if found, cut 2cy from loop

data40:	and #$7F	; (was: and #$FE) b0=0 marks 40cy selfsync
data36:	and #$7F	; b7=0 marks selfsync
data32:	sta (BLKPTR),y
	iny
	bne dpll
	inc BLKPTR+1
	bmi rtdone

rt04:	lda DRVRD	; check for data at rt=7
rt08:	cpx DRVRD	; still valid at rt=11?
rt15:	bit DRVRD	; still valid at rt=15?
	bcs data32	; gone by rt=11 -> 32cy data
	bpl data36	; gone by rt=15 -> 36cy selfsync
	bmi data40	; else it's a 40cy selfsync

rtdone:
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


;************************************
;*                                  *
;* TRANS - Transfer track in memory *
;* to target device                 *
;*                                  *
;* Note - this needs to keep within *
;* a single page of memory.         *
;************************************
Trans:
	lda #$00		; Set Buffer to $6700
	ldx #$67
	sta Buffer
	stx Buffer+1
Trans2:
; Trans2 entry point preconditions:
;   Buffer set to the start of nibble page to write (with leading sync bytes)
	ldy #$32		; Set Y offset to 1st sync byte (max=50)
	ldx SlotF		; Set X offset to FORMAT slot/drive
	sec			; (assume the disk is write protected)
	lda DiskWR,x		; Write something to the disk
	lda ModeRD,x		; Reset Mode softswitch to READ
	bmi LWRprot		; If > $7F then disk was write protected
	lda #$FF		; Write a sync byte to the disk
	sta ModeWR,x
	cmp DiskRD,x
	nop			; (kill some time for WRITE sync...)
	jmp LSync2
LSync1:
	eor #$80		; Set MSB, converting $7F to $FF (sync byte)
	nop			; (kill time...)
	nop
	jmp MStore
LSync2:
	pha			; (kill more time... [ sheesh! ])
	pla
LSync3:
	lda (Buffer),y		; Fetch byte to WRITE to disk
	cmp #$80		;  Is it a sync byte? ($7F)
	bcc LSync1		;  Yep. Turn it into an $FF
	nop
MStore:
	sta DiskWR,x		; Write byte to the disk
	cmp DiskRD,x		; Set Read softswitch
	iny			; Increment Y offset
	bne LSync2
	inc Buffer+1		; Increment Buffer by one page
; We may have to let everybody use the $6600 buffer space after all.
; That lets us avoid the extra boundary checking, and just use the 'bpl' 
; method of waiting for the pointer to go above $7f to page $80.
	bpl LSync3		; If < $8000 get more FORMAT data
	lda ModeRD,x		; Restore Mode softswitch to READ
	lda DiskRD,x		; Restore Read softswitch to READ
	clc
	rts
LWRprot:
	clc			; Disk is write protected
	jsr Done		; Turn the drive off
	lda #$2B
	pla
	pla
	pla
	pla
	jmp Died		; Prompt for another FORMAT...


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
;	jsr GET_PREFIX	; Get our current ProDOS prefix
;	jsr BLOAD	; Load up user parameters, if any
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
	jsr HOME	; Pseudo-indirect JSR to reset the IO device
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
	jsr WRITEMSGLEFT
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

;---------------------------------------------------------
; Quit to ProDOS
;---------------------------------------------------------

QUIT:
	sta ROM
	CALLOS OS_QUIT, QUITL

QUITL:
	.byte	4
        .byte	$00,$00,$00,$00,$00,$00