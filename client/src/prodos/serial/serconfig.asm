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

	lda #$07	; Column
	sta <CH
	lda #$00	; Row
	jsr TABV
	ldy #PMSG24	; 'CONFIGURE ADTPRO PARAMETERS'
	jsr WRITEMSG

	lda #$08	; Column
	sta <CH
	lda #$03	; Row
	jsr TABV
	lda #<MSG26	; 'COMMS DEVICE'
	sta UTILPTR
	lda #>MSG26
	sta UTILPTR+1
	jsr WRITEMSGRAW

	lda #$08	; Column
	sta <CH
	lda #$04	; Row
	jsr TABV
	lda #<MSG27	; 'BAUD RATE'
	sta UTILPTR
	lda #>MSG27
	sta UTILPTR+1
	jsr WRITEMSGRAW

	lda #$08	; Column
	sta <CH
	lda #$05	; Row
	jsr TABV
	ldy #PMSG28	; 'ENABLE SOUND'
	jsr WRITEMSG

	lda #$08	; Column
	sta <CH
	lda #$06	; Row
	jsr TABV
	ldy #PMSG28a	; 'SAVE CONFIGURATION'
	jsr WRITEMSG

	lda #$04	; Column
	sta <CH
	lda #$14	; Row
	jsr TABV
	ldy #PMSG25	; 'CHANGE PARAMETERS WITH ARROW KEYS'
	jsr WRITEMSG

	lda #$05	; Column
	sta <CH
	lda #$15	; Row
	jsr TABV
	ldy #PMSG23a	; 'SELECT WITH RETURN, ESC CANCELS'
	jsr WRITEMSG

REFRESH:
	lda PARMS
	cmp #$08	; Are we talking about the Laser/Pascal Entry Points?
	bmi RESTORE		; No, go on ahead
	lda PSPEED	; Yes - so check baudrate
	cmp #$03	; Is it too fast?
	bne REFNEXT		; No, go on ahead
	sta SVSPEED
	lda #$02	; Yes - so slow it down
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
	lda #$15	; Start printing config parms in this column
	sta <CH
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
	lda #$3F
	sta <INVFLG

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
	lda #$FF	; BACK TO NORMAL
	sta <INVFLG
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
	lda $C000         ;WAIT FOR NEXT COMMAND
	bpl GETCMD
	bit $C010
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
	cmp #$A0
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
	jmp NOSAVE
ENDCFG:
	lda #$01
	sta CONFIGYET
	lda PSAVE	; Did they ask to save?
	bne NOSAVE

	ldy #PARMNUM-1	; Save previous parameters
SAVPARM2:
	lda PARMS,Y
	sta DEFAULT,Y
	dey
	bpl SAVPARM2
	lda #$00
	sta CURPARM
	jsr BSAVE
NOSAVE:
	rts

LINECNT:	.byte 00		; CURRENT LINE NUMBER
CURPARM:	.byte 00		; ACTIVE PARAMETER
CURVAL:		.byte 00		; VALUE OF ACTIVE PARAMETER
OLDPARM:	.byte $00,$00,$00,$00	; There must be PARMNUM bytes here...


;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
PARMINT:
	ldy PSSC	; Get parm index# (0..7)
	iny		; Now slot# = 1..8 (where 8=IIgs)
	tya
	cmp #$08
	bpl DRIVERS
	jmp INITSSC	; Y holds slot number
DRIVERS:
	cmp #$09
	bpl LASER
	jmp INITZGS
LASER:
	jmp INITPAS

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
; FindSlot - Find a comms device
;---------------------------------------------------------
FindSlot:
	lda #$00
	sta UTILPTR
	sta TempSlot
	sta TempIIgsSlot
	ldx #$07 ; Slot number
FindSlotLoop:
	clc
	txa
	adc #$c0
	sta UTILPTR+1
	ldy #$05		; Lookup offset
	lda (UTILPTR),y
	cmp #$38		; Is $Cn05 == $38?
	bne FindSlotNext
	ldy #$07		; Lookup offset
	lda (UTILPTR),y
	cmp #$18		; Is $Cn07 == $18?
	bne FindSlotNext
	ldy #$0b		; Lookup offset
	lda (UTILPTR),y
	cmp #$01		; Is $Cn0B == $01?
	bne FindSlotNext
	ldy #$0c		; Lookup offset
	lda (UTILPTR),y
	cmp #$31		; Is $Cn0C == $31?
	bne FindSlotNext
; Ok, we have a set of signature bytes for a comms card (or IIc/IIgs, or Laser).
; Remove more specific models/situations first.
	ldy #$1b		; Lookup offset
	lda (UTILPTR),y
	cmp #$eb		; Do we have a goofy XBA instruction in $C01B?
	bne FoundNotIIgs	; If not, it's not an IIgs.
	cpx #$02		; Only bothering to check IIgs Modem slot (2)
	bne FindSlotNext
	lda #$07		; We found the IIgs modem port, so store it
	sta TempIIgsSlot
	jmp FindSlotNext
FoundNotIIgs:
	ldy #$00
	lda (UTILPTR),y
	cmp #$da		; Is $Cn00 == $DA?
	bne NotLaser		; If not, it's not a Laser 128.
	cpx #$02
	bne FindSlotNext
	lda #$09		; Ok, this is a Laser 128.
	sta TempSlot
	lda PSPEED		; Were we trying to go too fast (115.2k)?
	cmp #$03
	bne :+
	lda #$02		; Yes, slow it down to 19200.
	sta PSPEED
	sta DEFAULT+1		; And make that the default.
:
	jmp FindSlotNext
NotLaser:
	ldy #$0a
	lda (UTILPTR),y
	cmp #$0e		; Is this a newer IIc - $Cn0a == $0E?
	beq ProcessIIc
NotNewIIc:
	cmp #$25		; Is this an older IIc - $Cn0a == $25?
	bne GenericSSC
ProcessIIc:
	cpx #$02		; Only bothering to check IIc Modem slot (2)
	bne FindSlotNext
	stx TempSlot
	jmp FindSlotBreak	; Don't check port #1 on an IIc - we don't care
GenericSSC:
	stx TempSlot		; Nope, nothing special.  Just a Super Serial card.

FindSlotNext:
	dex
	bne FindSlotLoop
; All done now, so clean up
FindSlotBreak:
	ldx TempSlot
	beq :+
	dex			; Subtract 1 to match slot# to parm index
	stx PSSC
	stx DEFAULT		; Store the slot number discovered as default
	rts
:	lda TempIIgsSlot
	beq FindSlotDone	; Didn't find anything in particular
	sta PSSC
	sta DEFAULT		; Store the slot number discovered as default
FindSlotDone:
	rts
TempSlot:	.byte 0
TempIIgsSlot:	.byte 0

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $04		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 9,4,2,2	; Number of options for each parm

PARMTXT:
	ascz "SSC SLOT 1"
	ascz "SSC SLOT 2"
	ascz "SSC SLOT 3"
	ascz "SSC SLOT 4"
	ascz "SSC SLOT 5"
	ascz "SSC SLOT 6"
	ascz "SSC SLOT 7"
	ascz "IIGS MODEM"
	ascz "LASER MODEM"
	ascz "300"
	ascz "9600"
	ascz "19200"
	ascz "115200"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

MSG26:	ascz "COMMS DEVICE"
MSG27:	ascz "BAUD RATE"

YSAVE:		.byte $00

CONFIG_FILE_NAME:	.byte 11
			.byte "ADTPRO.CONF"

PARMS:
PSSC:	.byte 1		; Comms slot (2)
PSPEED:	.byte 3		; Comms speed (115200)
PSOUND:	.byte 0		; Sounds? (YES)
PSAVE:	.byte 1		; Save parms? (NO)
DEFAULT:	.byte 1,3,0,1	; Default parm indices
SVSPEED:	.byte 3		; Storage for speed setting
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND: