;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2012 by David Schmidt
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
; GETFN - Get filename
;---------------------------------------------------------
GETFN:
	ldy #PMSG13
	jmp GETFN2
GETFN1:
	ldy #PMCDIR
GETFN2:
	lda #$15
	jsr TABV
	jsr WRITEMSGLEFT
	jsr READ_LINE
	rts

;---------------------------------------------------------
; GetSendType - Get 5.25" disk send type
;---------------------------------------------------------
GetSendType:
	lda PNIBBL		; Enable Nibbles?  eq if yes, ne if no.
	bne GetSendFold
	jsr CLRMSGAREA
	ldy #PMSG04
	jsr WRITEMSG
	; (S)TANDARD (N)IBBLE:
GetSendLoop:
	jsr READ_CHAR
	CONDITION_KEYPRESS	; Convert to upper case
	cmp #CHR_S
	beq GetSendFold	; Fold to "P"
	cmp #CHR_N
	beq GetSendOk
;	cmp #CHR_H	; Uncomment when half tracks are ready...
;	beq GetSendOk
	cmp #CHR_ESC	; ESCAPE = No
	beq GetSendCancel
	jmp GetSendLoop
GetSendCancel:
	sec
	lda #CHR_P
	sta SendType
	rts
GetSendFold:
	lda #CHR_P
GetSendOk:
	clc
	sta SendType
	rts

;---------------------------------------------------------
; PAUSE - print 'PRESS A KEY TO CONTINUE...' and wait
;---------------------------------------------------------
PAUSE:
	lda #$17
	jsr TABV
	jsr CLREOP
	ldy #PMSG16
	jsr WRITEMSGLEFT
	jsr READ_CHAR
	cmp #$9B
	beq PAUSEESC
	clc
	rts
PAUSEESC:
	sec
	rts

;---------------------------------------------------------
; YN - print a prompt message, wait for Y/N
; A 'Y' response leaves a 1 in the accumulator
; A 'N' response leaves a 0 in the accumulator
;---------------------------------------------------------
YN:
	jsr WRITEMSGAREA
YNLOOP:
	jsr READ_CHAR
	CONDITION_KEYPRESS	; Convert to upper case
	cmp #CHR_Y
	beq YNYES
	cmp #CHR_N
	beq YNNO
	cmp #CHR_ESC	; ESCAPE = No
	beq YNNO
	jmp YNLOOP
YNYES:
	lda #$01
	jmp YNDONE
YNNO:
	lda #$00
YNDONE:
	rts
