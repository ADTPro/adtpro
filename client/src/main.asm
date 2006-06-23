*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

	.or $0803
	.cr 6502
	.tf adtpro,bin

*------------------------------------
* Code
*------------------------------------
	cld

	* Prepare the system for our expecations -
	* Basic, 64k Apple ][.  That's all it should
	* take.

	jsr $FE84	NORMAL TEXT
	jsr $FB2F	TEXT MODE, FULL WINDOW
	jsr $FE89	INPUT FROM KEYBOARD
	jsr $FE93	OUTPUT TO 40-COL SCREEN
	jsr MAKETBL	Prepare our CRC tables
	jsr PARMDFT	RESET PARAMETERS TO DEFAULTS
	jsr PARMINT	INTERPRET PARAMETERS

	* And off we go!

	jsr MAINLUP
	rts


*------------------------------------
* Main loop
*------------------------------------
MAINLUP
	jsr HOME	Clear screen
MAINL
MOD0	bit $C088	CLEAR SSC INPUT REGISTER

	lda #$0d
	sta <CH
	lda #$03
	jsr TABV

	ldy #PMSG10a	Main title - Line 1
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMSG10b	Main title - line 2
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMSG10c	Main title - line 3
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMSG10d	Main title - line 4
	jsr SHOWMSG

    	lda #$0d
	sta <CH
	ldy #PMSG10e	Main title - line 5
	jsr SHOWMSG

	jsr CROUT
    	lda #$13
	sta <CH
	ldy #PMSG01	Version number
	jsr SHOWMSG

    	lda #$07
	sta <CH
	lda #$0e
	jsr TABV
	ldy #PMSG02	Prompt line 1
	jsr SHOWMSG

    	lda #$08
	sta <CH
	ldy #PMSG03	Prompt line 2
	jsr SHOWMSG

*------------------------------------
* KBDLUP
*
* Keyboard handler, dispatcher
*------------------------------------
KBDLUP
	jsr RDKEY	GET ANSWER
	AND #$DF	CONVERT TO UPPERCASE

	cmp #"S"	SEND?
	bne KRECV	NOPE, TRY RECEIVE
	lda #$06
        ldx #$07
	ldy #$0e
	jsr INVERSE
	jsr SEND	YES, DO SEND ROUTINE
	jmp MAINLUP

KRECV	cmp #"R"	RECEIVE?
	bne KDIR	NOPE, TRY DIR
	lda #$09
        ldx #$0e
	ldy #$0e
	jsr INVERSE
	jsr RECEIVE
	jmp MAINLUP

KDIR	cmp #"D"	DIR?
	bne KCD		Nope, try CD
	jsr DIR	  	Yes, do DIR routine
	jmp MAINLUP

KCD	cmp #"C"	CD?
	bne KCONF	Nope, try Configure
	lda #$04
        ldx #$1e
	ldy #$0e
	jsr INVERSE
	jsr CD	  	Yes, do CD routine
	jmp MAINLUP

KCONF	cmp #CHR_G	Configure?
	bne KABOUT      NOPE, TRY ABOUT
	jsr CONFIG      YES, DO CONFIGURE ROUTINE
	jsr PARMINT     AND INTERPRET PARAMETERS
	jmp MAINLUP

KABOUT	cmp #$9F	ABOUT MESSAGE? ("?" KEY)
	bne KVOLUMS	NOPE, TRY VOLUMES
	lda #$08
        ldx #$11
	ldy #$10
	jsr INVERSE
    	lda #$00
	sta <CH
	lda #$15
	jsr TABV
	ldy #PMSG17	"About" message
	jsr SHOWMSG
	jsr RDKEY
	jmp MAINLUP	Clear and start over

KVOLUMS	cmp #"V"	Volumes online?
	bne KQUIT1	NOPE, TRY Escape
	jsr PICKVOL	Pick a volume - A has index into DEVICES table
	jmp MAINLUP

KQUIT1	cmp #$9B	Escape?
	bne KQUIT	NOPE, TRY QUIT
	jsr CLEANUP
	jmp $03d0	Bail allllllllllll the way out

KQUIT	cmp #"Q"	Quit?
	bne FORWARD	No, it was an unknown key
	jsr CLEANUP
	jmp $03d0	Bail allllllllllll the way out

FORWARD	jmp MAINL

*------------------------------------
* Final message, cleanup
*------------------------------------
CLEANUP
	jsr home
	ldy #PMSG04	Goodbye, and thanks for all the fish!
	jsr SHOWMSG
	rts

*---------------------------------------------------------
* ABORT - STOP EVERYTHING (CALL BABORT TO BEEP ALSO)
*---------------------------------------------------------
BABORT	jsr AWBEEP	Beep!
ABORT	ldx #$FF	Pop goes the stackptr
	txs
	bit $C010	Strobe the keyboard
	jmp MAINLUP	... and restart

*---------------------------------------------------------
* AWBEEP - CUTE TWO-TONE BEEP (USES AXY)
*---------------------------------------------------------
AWBEEP
	lda PSOUND        ;IF SOUND OFF, RETURN NOW
	bne NOBEEP
	lda #$80          ;STRAIGHT FROM APPLE WRITER ][
	jsr BEEP1         ;(CANNIBALISM IS THE SINCEREST
	lda #$A0          ;FORM OF FLATTERY)
BEEP1	ldy #$80
BEEP2	tax
BEEP3	dex
	bne BEEP3
	bit $C030         ;WHAP SPEAKER
	dey
	bne BEEP2
NOBEEP	rts



*------------------------------------
* Pull in all the rest of the code
*------------------------------------
	.in online.asm
	.in print.asm
	.in rw.asm
	.in sr.asm
	.in crc.asm
	.in pickvol.asm
	.in input.asm
	.in config.asm
	.in hostfns.asm
	.in vars.asm
	.in const.asm


