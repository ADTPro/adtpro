;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2014 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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

; Note - code in findslot, and then the serial drivers in
; ssc, pascalep, and iigsscc complete this functional unit. 

;---------------------------------------------------------
; CONFIG - ADTPro Configuration
;---------------------------------------------------------
CONFIG:
	jsr HOME	; Clear screen
; No matter what, we put in the default value for 
; 'save' - always turn it off when we start up.
	lda #$01	; Index for 'NO' save parameter
	sta PSAVE

	ldy #PARMNUM-1	; Save incoming parameters
SAVPARM:
	lda PARMS,Y	; in case of abort
	sta OLDPARM,Y
	dey
	bpl SAVPARM

;--------------- FIRST PART: DISPLAY SCREEN --------------

	ldx #$07	; Column
	ldy #$00	; Row
	jsr GOTOXY
	ldy #PMSG24	; 'CONFIGURE ADTPRO PARAMETERS'
	jsr WRITEMSG

	ldx #$08	; Column
	ldy #$03	; Row
	jsr GOTOXY
	ldy #PMSG26	; 'COMMS DEVICE'
	jsr WRITEMSG

	ldx #$08	; Column
	ldy #$04	; Row
	jsr GOTOXY
	ldy #PMSG27	; 'BAUD RATE'
	jsr WRITEMSG

	ldx #$08	; Column
	ldy #$05	; Row
	jsr GOTOXY
	ldy #PMBlocksAtonce ; 'BLOCKS AT ONCE'
	jsr WRITEMSG

	ldx #$08	; Column
	ldy #$06	; Row
	jsr GOTOXY
	ldy #PMSG28	; 'ENABLE SOUND'
	jsr WRITEMSG

	ldx #$08	; Column
	ldy #$07	; Row
	jsr GOTOXY
	ldy #PMEnableNibbles ; 'ENABLE NIBBLES'
	jsr WRITEMSG

	ldx #$08	; Column
	ldy #$08	; Row
	jsr GOTOXY
	ldy #PMSG28a	; 'SAVE CONFIGURATION'
	jsr WRITEMSG

	ldx #$04	; Column
	ldy #$14	; Row
	jsr GOTOXY
	ldy #PMSG25	; 'CHANGE PARAMETERS WITH ARROW KEYS'
	jsr WRITEMSG

	ldx #$05	; Column
	ldy #$15	; Row
	jsr GOTOXY
	ldy #PMSG23a	; 'SELECT WITH RETURN, ESC CANCELS'
	jsr WRITEMSG

REFRESH:
	lda PARMS
	cmp #$08	; Are we talking about the Laser/Pascal Entry Points?
	bmi RESTORE		; No, go on ahead
	lda PSPEED	; Yes - so check baudrate
	cmp #BPS1152K	; Is it too fast?
	bne REFNEXT		; No, go on ahead
	sta SVSPEED
	lda #BPS192K	; Yes - so slow it down
	sta PSPEED
	jmp REFNEXT 
RESTORE:
	lda SVSPEED	; Did we have speed previously re-set by Laser?
	beq REFNEXT	; No, go on ahead
	sta PSPEED	; Yes - so restore it now
	lda #$00
	sta SVSPEED	; Forget about resetting speed until we roll through Laser again
REFNEXT:
	lda #3		; FIRST PARAMETER IS ON LINE 3
	jsr TABV
	ldx #0		; PARAMETER NUMBER
	ldy #$FF	; OFFSET INTO PARAMETER TEXT

NXTLINE:
	stx LINECNT	; SAVE CURRENT LINE
	lda #$16	; Start printing config parms in this column
	SET_HTAB	; sta <CH
	clc
	lda PARMSIZ,X	; GET CURRENT VALUE (NEGATIVE:
	sbc PARMS,X	; LAST VALUE HAS CURVAL=0)
	sta CURVAL
	lda PARMSIZ,X	; X WILL BE EACH POSSIBLE VALUE
	tax		; STARTING WITH THE LAST ONE
	dex

VALLOOP:
	cpx CURVAL	; X EQUAL TO CURRENT VALUE?
	beq PRINTIT	; YES, PRINT IT
SKIPCHR:
	iny		; NO, SKIP IT
	lda PARMTXT,Y
	bne SKIPCHR
	beq ENDVAL

PRINTIT:
	lda LINECNT	; IF WE'RE ON THE ACTIVE LINE,
	cmp CURPARM	; THEN PRINT VALUE IN INVERSE
	bne PRTVAL	; ELSE PRINT IT NORMALLY
	jsr SET_INVERSE

PRTVAL:	lda #$A0	; SPACE BEFORE & AFTER VALUE
	jsr COUT1
PRTLOOP:
	iny		; PRINT VALUE
	lda PARMTXT,Y
	beq ENDPRT
	jsr COUT1
	jmp PRTLOOP
ENDPRT:	lda #$A0
	jsr COUT1
	jsr SET_NORMAL
ENDVAL:	dex
	bpl VALLOOP	; PRINT REMAINING VALUES

	sty YSAVE	; CLREOL USES Y
	jsr CLREOL	; REMOVE GARBAGE AT EOL
	jsr CROUT
	ldy YSAVE
	ldx LINECNT	; INCREMENT CURRENT LINE
	inx
	cpx #PARMNUM
	bcc NXTLINE	; Loop PARMNUM times

;--------------- SECOND PART: CHANGE VALUES --------------

GETCMD:
	jsr READ_CHAR
	CONDITION_KEYPRESS

	ldx CURPARM       ;CURRENT PARAMETER IN X

	cmp #$88
	bne NOTLEFT
	dec PARMS,X       ;LEFT ARROW PUSHED
	bpl LEFTOK        ;DECREMENT CURRENT VALUE
	lda PARMSIZ,X
	sbc #1
	sta PARMS,X
LEFTOK:
	jmp REFRESH

NOTLEFT:
	cmp #$95
	bne NOTRGT
	lda PARMS,X       ;RIGHT ARROW PUSHED
	adc #0            ;INCREMENT CURRENT VALUE
	cmp PARMSIZ,X
	bcc RIGHTOK
	lda #0
RIGHTOK:
	sta PARMS,X
	jmp REFRESH

NOTRGT:
	cmp #$8B
	bne NOTUP
	dex		; Up arrow pressed
	bpl UPOK	; Decrement parameter
	ldx #PARMNUM-1
UPOK:	stx CURPARM
	jmp REFRESH

NOTUP:
	cmp #$8A
	beq ISDOWN
	cmp #$80	; Space chracter, after CONDITION_KEYPRESS... A0->80
	bne NOTDOWN
ISDOWN:
	inx		; Down arrow or space pressed
	cpx #PARMNUM	; Increment prarameter
	bcc DOWNOK
	ldx #0
DOWNOK:
	stx CURPARM
	jmp REFRESH

NOTDOWN:
	cmp #$84
	bne NOTCTLD
	jsr PARMDFT	; CTRL-D pressed, resore previous values
NOTESC:	jmp REFRESH

NOTCTLD:
	cmp #$8D
	beq ENDCFG	; Return pressed, all done

	cmp #CHR_ESC
	bne NOTESC
	ldy #PARMNUM-1	; Escape pressed, restore previous values
PARMRST:
	lda OLDPARM,Y	; PARAMETERS AND STOP CONFIGURE
	sta PARMS,Y
	dey
	bpl PARMRST
	sec
	jmp NOSAVE
ENDCFG:
	lda #$01
	sta CONFIGYET
	lda PSAVE	; Did they ask to save?
	bne NOSAVE2

	ldy #PARMNUM-1	; Save previous parameters
SAVPARM2:
	lda PARMS,Y
	sta DEFAULT,Y
	dey
	bpl SAVPARM2
	lda #$00
	sta CURPARM
	jsr BSAVE
NOSAVE2:
	clc
NOSAVE:
	rts

LINECNT:	.byte 00		; CURRENT LINE NUMBER
CURPARM:	.byte 00		; ACTIVE PARAMETER
CURVAL:		.byte 00		; VALUE OF ACTIVE PARAMETER
					; There must be PARMNUM bytes here...
OLDPARM:	.byte $00, $00, $00, $00, $00, $00

;---------------------------------------------------------
; PARMDFT - Set parameters to last saved values (uses A,X)
;---------------------------------------------------------
PARMDFT:
	lda CONFIGYET
	bne WARMER	; If no manual config yet, scan the slots
	jsr FindSlot
WARMER:
	ldx #PARMNUM-1
DFTLOOP:
	lda DEFAULT,X
	sta PARMS,X
	dex
	bpl DFTLOOP
	jmp PARMDFTNEXT

PARMDFTNEXT:
; No matter what, we put in the default value for 
; 'save' - always turn it off when we restore defaults.
	lda #$01	; Index for 'NO' save
	sta PSAVE
	rts

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $06		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 9,2,6,2,2,2	; Number of options for each parm

PARMTXT:
	ascz "SSC SLOT 1"
	ascz "SSC SLOT 2"
	ascz "SSC SLOT 3"
	ascz "SSC SLOT 4"
	ascz "SSC SLOT 5"
	ascz "SSC SLOT 6"
	ascz "SSC SLOT 7"
	ascz "IIGS MODEM"
	ascz "GENERIC SLOT 2"
	ascz "19200"
	ascz "115200"
	ascz "1"
	ascz "2"
	ascz "5"
	ascz "10"
	ascz "20"
	ascz "40"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

YSAVE:		.byte $00

CONFIG_FILE_NAME:
		.byte 11
		.byte "ADTPRO.CONF"

PARMS:
COMMSLOT:	.byte 1		; Comms slot (2)
PSPEED:		.byte BPS1152K	; Comms speed (115200)
PBAO:		.byte 1		; Blocks at once (2)
PSOUND:		.byte 0		; Sounds? (YES)
PNIBBL:		.byte 1		; Enable nibbles: (NO)
PSAVE:		.byte 1		; Save parms? (NO)
DEFAULT:	.byte 1,BPS1152K,1,0,1,1	; Default parm indices
SVSPEED:	.byte BPS1152K	; Storage for speed setting
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND:

BAOTbl:		.byte 1,2,5,10,20,40