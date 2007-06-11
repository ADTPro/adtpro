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

;---------------------------------------------------------
; CONFIG - ADTPro Configuration
;---------------------------------------------------------
CONFIG:
	jsr HOME	; Clear screen
	lda #$00
	sta LINECNT
	sta CURPARM

; No matter what, we put in the default value for 
; 'save' - always turn it off when we start up.
	lda #$01	; Index for 'NO' save
	sta PARMS+BSAVEP

	ldy #PARMNUM-1	; Save previous parameters
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
	jsr SHOWMSG

	lda #$05	; Column
	sta <CH
	lda #$03	; Row
	jsr TABV
	lda #<MSG26	; 'UTHER SLOT'
	ldy #>MSG26
	jsr STROUT

	lda #$05	; Column
	sta <CH
	lda #$04	; Row
	jsr TABV
	ldy #PMSG28	; 'ENABLE SOUND'
	jsr SHOWMSG

	lda #$05	; Column
	sta <CH
	lda #$05	; Row
	jsr TABV
	ldy #PMSG28a	; 'SAVE CONFIGURATION'
	jsr SHOWMSG

	lda #$05
	sta <CH
	lda #$07
	jsr TABV
	ldax #IPMsg01
	jsr IPShowMsg	; 'SERVER IP ADDR'

	lda #$05
	sta <CH
	lda #$08
	jsr TABV
	ldax #IPMsg02
	jsr IPShowMsg	; 'LOCAL IP ADDR'
	
	lda #$05
	sta <CH
	lda #$09
	jsr TABV
	ldax #IPMsg03
	jsr IPShowMsg	; 'NETMASK'
	
	lda #$05
	sta <CH
	lda #$0a
	jsr TABV
	ldax #IPMsg04
	jsr IPShowMsg	; 'GATEWAY ADDR'
	
	lda #$04	; Column
	sta <CH
	lda #$14	; Row
	jsr TABV
	ldy #PMSG25	; 'CHANGE PARAMETERS WITH ARROW KEYS'
	jsr SHOWMSG

	lda #$05	; Column
	sta <CH
	lda #$15	; Row
	jsr TABV
	ldy #PMSG23	; 'SELECT WITH RETURN, ESC CANCELS'
	jsr SHOWMSG

	jsr IPConfig	
	jsr REFRESH

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
	jsr REFRESH
	jmp GETCMD

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
	jsr REFRESH
	jmp GETCMD

NOTRGT:
	cmp #$8B
	bne NOTUP
	dex		; Up arrow pressed
	bpl UPOK	; Decrement parameter
	stx CURPARM
	jsr REFRESH
	jsr IPConfigBottomEntry
	bmi PARMRST	; Escape coming from IP Config
	cmp #$04
	beq ENDCFG	; Return pressed, all done
UPOK:	stx CURPARM
	jsr REFRESH
	jmp GETCMD
NOTUP:
	cmp #$8A
	beq ISDOWN
	cmp #$A0
	bne NOTDOWN
ISDOWN:
	inx		; Down arrow or space pressed
	cpx #PARMNUM	; Increment prarameter
	bcc DOWNOK
	stx CURPARM
	jsr REFRESH
	jsr IPConfigTopEntry
	bmi PARMRST	; Escape coming from IP Config
	cmp #$04
	beq ENDCFG	; Return pressed, all done
DOWNOK:
	stx CURPARM
	jsr REFRESH
	jmp GETCMD

NOTDOWN:
	cmp #$84
	bne NOTCTLD
	jsr PARMDFT	; CTRL-D pressed, resore previous values
NOTESC:	jsr REFRESH
	jmp GETCMD


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
	; Save off IP parms
	ldy #ip_parms_temp-ip_parms-1
:	lda ip_parms_temp,y
	sta ip_parms,y
	dey
	bpl :-
	lda #$01
	sta CONFIGYET

	lda PARMS+BSAVEP	; Did they ask to save?
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

;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
PARMINT:
	lda CONFIGYET
	beq NOPE
	jsr INITUTHER
	jsr PINGREQUEST
	jsr PINGREQUEST
	jmp :+
NOPE:	jsr PATCHNULL
:	rts

;---------------------------------------------------------
; PARMDFT - Set parameters to last saved values (uses A,X)
; Called with the desired operation in A:
;   00 - defaults last saved by user
;   01 - defaults set at the factory
; This becomes important when a user saves off a copy of
; parms that are incompatible with a machine and (as once
; happened in my case) it hangs during initialization.
;---------------------------------------------------------
PARMDFT:
	bne FACTORYLOOP
	lda CONFIGYET
	bne WARMER	; If no manual config yet, scan the slots
	jsr FindSlot	; Seems to be failing on emulators?
WARMER:
	ldx #PARMNUM-1
DFTLOOP:
	lda DEFAULT,X
	sta PARMS,X
	dex
	bpl DFTLOOP
	jmp PARMDFTNEXT

FACTORYLOOP:
	lda #$00		; Don't touch the Uther until
	sta CONFIGYET		; user confirms settings
	lda FACTORY,X
	sta PARMS,X
	dex
	bpl FACTORYLOOP

PARMDFTNEXT:
; No matter what, we put in the default value for 
; 'save' - always turn it off when we restore defaults.
	lda #$01	; Index for 'NO' save
	sta PARMS+BSAVEP
	rts

;---------------------------------------------------------
; IPShowMsg
;---------------------------------------------------------
IPShowMsg:
	sta UTILPTR
	stx UTILPTR+1
	ldy #$00
@MSGLOOP:
	lda (UTILPTR),Y
	beq @MSGEND
	jsr COUT1
	iny
	bne @MSGLOOP
@MSGEND:	rts

;
;
;
REFRESH:
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
	rts

;---------------------------------------------------------
; FindSlot - Find an uther card
;---------------------------------------------------------
FindSlot:
	lda PSSC
	sta TempSlot
	ldx #$00	; Slot number - start at index 0 and work up
FindSlotLoop:
	stx PSSC	; ip65_init looks for PSSC to be the index
	clc
	jsr ip65_init
	bcc FoundSlot
	ldx PSSC
	inx
	stx PSSC
	cpx #$07
	bne FindSlotLoop
	jmp FindSlotDone
FoundSlot:
	lda PSSC
	sta TempSlot
FindSlotDone:
; All done now, so clean up
	ldx TempSlot
	stx PSSC
	stx DEFAULT
	rts
TempSlot:	.byte 0

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $03		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 7,2,2	; Number of options for each parm
LINECNT:	.byte 00		; CURRENT LINE NUMBER
CURPARM:	.byte 00		; ACTIVE PARAMETER
CURVAL:		.byte 00		; VALUE OF ACTIVE PARAMETER
OLDPARM:	.byte $00,$00,$00	; There must be PARMNUM bytes here...

PARMTXT:
	ascz "1"
	ascz "2"
	ascz "3"
	ascz "4"
	ascz "5"
	ascz "6"
	ascz "7"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

PARMS:
PSSC:	.byte 2		; Comms slot (3)
PSOUND:	.byte 0		; Sounds? (YES)
PSAVE:	.byte 1		; Save parms? (NO)

IPMsg01:	ascz "SERVER IP ADDR"
IPMsg02:	ascz "LOCAL IP ADDR"
IPMsg03:	ascz "NETMASK"
IPMsg04:	ascz "GATEWAY ADDR"
MSG26:	ascz "UTHER SLOT"

DEFAULT:	.byte 2,0,1	; Default parm indices
FACTORY:	.byte 2,0,1	; Factory default parm indices
CONFIGYET:	.byte 0		; Has the user configged yet?
YSAVE:	.byte $00
BSAVEP	= $02		; Index to the 'Save parameters' parameter
