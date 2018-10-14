;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2018 by David Schmidt
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

	.export cfg_ip
	.export cfg_netmask
	.export cfg_gateway
	.export cfg_dns
	.export dhcp_server
	.export cfg_tftp_server
	.export cfg_mac

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
	sta PSAVE

	ldy #PARMNUM-1	; Save previous parameters
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

	ldx #$05	; Column
	ldy #$03	; Row
	jsr GOTOXY
	ldy #PMSG26	; 'ETHERNET SLOT'
	jsr WRITEMSG

	ldx #$05	; Column
	ldy #$04	; Row
	jsr GOTOXY
	ldy #PMBlocksAtonce ; 'BLOCKS AT ONCE'
	jsr WRITEMSG

	ldx #$05	; Column
	ldy #$05	; Row
	jsr GOTOXY
	ldy #PMSG28	; 'ENABLE SOUND'
	jsr WRITEMSG

	ldx #$05	; Column
	ldy #$06	; Row
	jsr GOTOXY
	ldy #PMEnableNibbles ; 'ENABLE NIBBLES'
	jsr WRITEMSG

	ldx #$05	; Column
	ldy #$07	; Row
	jsr GOTOXY
	ldy #PMSG28a	; 'SAVE CONFIGURATION'
	jsr WRITEMSG

	ldx #$05	; Column
	ldy #$08	; Row
	jsr GOTOXY
	ldy #PMSG27	; 'DHCP CONFIGURATION'
	jsr WRITEMSG

	ldx #$05
	ldy #$0a
	jsr GOTOXY
	ldax #IPMsg01
	ldy IP_MSG_LEN_TBL
	jsr IPShowMsg	; 'SERVER IP ADDR'

	ldx #$05
	ldy #$0b
	jsr GOTOXY
	ldax #IPMsg02
	ldy IP_MSG_LEN_TBL+1
	jsr IPShowMsg	; 'LOCAL IP ADDR'
	
	ldx #$05
	ldy #$0c
	jsr GOTOXY
	ldax #IPMsg03
	ldy IP_MSG_LEN_TBL+2
	jsr IPShowMsg	; 'NETMASK'
	
	ldx #$05
	ldy #$0d
	jsr GOTOXY
	ldax #IPMsg04
	ldy IP_MSG_LEN_TBL+3
	jsr IPShowMsg	; 'GATEWAY ADDR'
	
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
PARMRST:
	ldy #PARMNUM-1	; Escape pressed, restore previous values
@PR1:
	lda OLDPARM,Y	; Restore prior parameters and stop configuration
	sta PARMS,Y
	dey
	bpl @PR1
	sec
	jmp NOSAVE
ENDCFG:
	; Save off IP parms
	ldy #ip_parms_temp_done-ip_parms_temp-1
:	lda ip_parms_temp,y
	sta ip_parms,y
	dey
	bpl :-
	lda #$01
	sta CONFIGYET

	ldy #PARMNUM-1	; Save current parms as default
SAVPARM2:
	lda PARMS,Y
	sta DEFAULT,Y
	dey
	bpl SAVPARM2
	lda #$00
	sta CURPARM

	lda PSAVE	; Did they ask to save?
	bne NOSAVE2
	jsr BSAVE
NOSAVE2:
	clc
NOSAVE:
	rts

;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
PARMINT:
	lda CONFIGYET
	beq NOPE
	jsr INITUTHER
	bcc :+
	ldy #PMUTHBAD
	jsr WRITEMSGAREA
:	lda #$a0
	jsr DELAY
	jsr PINGREQUEST	; Do a couple of ping requests to prime the pump
	lda #$10
	jsr DELAY
	jsr PINGREQUEST	; Do a couple of ping requests to prime the pump
	rts
NOPE:	jsr PATCHNULL
	rts

;---------------------------------------------------------
; PARMDFT - Set parameters to last saved values (uses A,X)
;---------------------------------------------------------
PARMDFT:
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

PARMDFTNEXT:
; No matter what, we put in the default value for 
; 'save' - always turn it off when we restore defaults.
	lda #$01	; Index for 'NO' save
	sta PSAVE
	rts

REFRESH:
	lda #3		; FIRST PARAMETER IS ON LINE 3
	jsr TABV
	ldx #0		; PARAMETER NUMBER
	ldy #$FF	; OFFSET INTO PARAMETER TEXT

NXTLINE:
	stx LINECNT	; SAVE CURRENT LINE
	lda #$15	; Start printing config parms in this column
	jsr HTAB	; sta <CH
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
	rts

;---------------------------------------------------------
; FindSlot - Find an uther card
;---------------------------------------------------------
FindSlot:
	ldx #$00	; Slot number - start at min and work up
FindSlotLoop:
	stx TempSlot
	inx		; One-indexed slot number for a2_set_slot
	txa
	jsr DisqualifyCards
	bcs Bump
	jsr a2_set_slot
	jsr ip65_init
	ldx TempSlot
	bcc FoundSlot
Bump:
	clc
	inx
	cpx #MAXSLOT
	bne FindSlotLoop
	rts
FoundSlot:
	stx COMMSLOT
	stx DEFAULT
	rts

TempSlot:	.byte 0


;---------------------------------------------------------
; DisqualifyCards - Eliminate cards from scan consideration based on firmware clues
; On entry: A=X=slot
; On exit:A=X=slot, carry set if card is disqualified
;---------------------------------------------------------
DisqualifyCards:
	clc
	adc #$c0
	sta UTILPTR + 1
	lda #$00
	sta UTILPTR
	ldy #$26
	lda (UTILPTR),y
	cmp #$e2	; Check some values
	bne NotDisqualified
	ldy #$4d
	lda (UTILPTR),y
	cmp #$fb	; Check some values
	bne NotDisqualified
	sec
	bcs DisqualifyDone
NotDisqualified:
	clc
DisqualifyDone:
	txa
	rts


;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $06		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 7,2,2,2,2,2	; Number of options for each parm
LINECNT:	.byte 00		; CURRENT LINE NUMBER
CURPARM:	.byte 00		; ACTIVE PARAMETER
CURVAL:		.byte 00		; VALUE OF ACTIVE PARAMETER
OLDPARM:	.res PARMNUM,$00		; There must be PARMNUM bytes here...

PARMTXT:
	ascz "1"
	ascz "2"
	ascz "3"
	ascz "4"
	ascz "5"
	ascz "6"
	ascz "7"
	ascz "1"
	ascz "2"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

CONFIG_FILE_NAME:	.byte 14
			asc "ADTPROETH.CONF"

YSAVE:	.byte $00

PARMS:
COMMSLOT:
	.byte 2		; Zero-indexed comms slot (3)
PBAO:	.byte 0		; Blocks at once (1)
PSOUND:	.byte 0		; Sounds? (YES)
PNIBBL:	.byte 1		; Enable nibbles? (NO)
PSAVE:	.byte 1		; Save parms? (NO)
PDHCP:	.byte 0		; DHCP Configuration? (YES)

ip_parms:
serverip:	.byte 192, 168,   1,  18
cfg_ip:		.byte   0,   0,   0,   0 ; ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask:	.byte   0,   0,   0,   0 ; netmask of local network (will be overwritten if dhcp_init is called)
cfg_gateway:	.byte   0,   0,   0,   0 ; ip address of router on local network (will be overwritten if dhcp_init is called)

DEFAULT:	.byte 2,0,0,1,1,0	; Default parm indices
CONFIGYET:	.byte 0			; Has the user configged yet?
PARMSEND:
cfg_dns:	.byte   0,   0,   0,   0 ; ip address of dns server to use (will be overwritten if dhcp_init is called)
dhcp_server:	.byte   0,   0,   0,   0 ; will be set address of dhcp server that configuration was obtained from
cfg_tftp_server:
		.byte   0,   0,   0,   0 ; ip address of server to send tftp requests to (can be a broadcast address)
cfg_mac:	.byte   0,   0,   0,   0,   0,   0 ; mac address of local machine (will be overwritten if ip65_init is called)

BAOTbl:		.byte 1,2
