;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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
   	lda #$00
	sta CH
	lda #$15
	jsr TABV
	jsr SHOWMSG
	ldx #0		; Get answer from $200
	jsr NXTCHAR
	lda #0		; Null terminate it
	sta $200,X
	txa
	rts

;---------------------------------------------------------
; PAUSE - print 'PRESS A KEY TO CONTINUE...' and wait
;---------------------------------------------------------
PAUSE:
	lda #$00
	sta CH
	lda #$17
	jsr TABV
	jsr CLREOP
	ldy #PMSG16
	jsr SHOWMSG
	jsr RDKEY
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
	jsr SHOWM1
YNLOOP:
	jsr RDKEY
	and #$DF	; Convert to upper case
	cmp #'Y'
	beq YNYES
	cmp #'N'
	beq YNNO
	cmp CHR_ESC	; ESCAPE = No
	beq YNNO
	jmp YNLOOP
YNYES:
	lda #$01
	jmp YNDONE
YNNO:
	lda #$00
YNDONE:
	rts
