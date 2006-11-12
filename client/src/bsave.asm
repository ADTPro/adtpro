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
; BSAVE - Save a copy of ADTPro in memory
;---------------------------------------------------------
BSAVE:
	ldx #$00
:	lda COMMAND,X
	sta $0200,X
	inx
	cpx CMDEND-COMMAND
	bne :-
	lda #$00
	sta $BE0F	; Clear ProDOS error code
	jsr $BE03	; Execute the input buffer

	lda #$00	; Prepare to print ProDOS error message
	sta <CH
	lda #$15
	jsr TABV

	lda $BE0F	; Grab the error code out of ProDOS
	beq BSAVEOK	; If no problem - exit
	jsr $BE0C	; Print ProDOS error message
	jmp BSAVEDONE
BSAVEOK:
	lda #$16
	jsr TABV
	ldy #PMSG14
	jsr SHOWMSG
BSAVEDONE:
	jsr PAUSE
	rts

; Note - the device-specific bsave routine is appended here, depending
;        on what type of device we're talking to (serial vs. ethernet).
; See: ethernet/ethbsave.asm, serial/serbsave.asm