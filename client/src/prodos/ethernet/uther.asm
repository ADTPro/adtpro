;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2015 by David Schmidt
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

	.import ip65_init
	.import ip65_process
	.import dhcp_init

	.import a2_set_slot

	.import udp_add_listener
	.import udp_callback
	.import udp_send

	.import udp_inp
	.import udp_outp

	.importzp udp_data
	.importzp udp_len
	.importzp udp_src_port
	.importzp udp_dest_port

	.import udp_send_dest
	.import udp_send_src_port
	.import udp_send_dest_port
	.import udp_send_len

	.importzp ip_src
	.import ip_inp

;---------------------------------------------------------
; INITUTHER - Initialize Uther card
; Returns with carry clear on success, carry set on failure 
;---------------------------------------------------------
INITUTHER:
	jsr PATCHUTHER
	GO_SLOW				; Slow down for SOS
	ldx COMMSLOT
	inx
	txa
	jsr a2_set_slot
	jsr ip65_init
	bcc @UTHEROK
	jsr PATCHNULL
	GO_FAST				; Speed back up for SOS
	sec
	rts
@UTHEROK:
	lda PDHCP
	bne @UTHEROK2
	jsr dhcp_init
	bcc @UTHEROK2
	jsr PATCHNULL
	GO_FAST				; Speed back up for SOS
	sec
	rts
@UTHEROK2:
	ldax #UDPDISPATCH
	stax udp_callback
	ldax #6502
	jsr udp_add_listener

	ldx #3
:	lda serverip,x			; set destination
	sta udp_send_dest,x
	dex
	bpl :-

	ldax #6502			; set source port
	stax udp_send_src_port

	ldax #6502			; set destination port
	stax udp_send_dest_port

	GO_FAST				; Speed back up for SOS
	clc
	rts

;---------------------------------------------------------
; PATCHUTHER - Patch in Uthernet entry points
;---------------------------------------------------------
PATCHUTHER:
	lda #<RESETUTHER
	sta RESETIO+1
	lda #>RESETUTHER
	sta RESETIO+2
	lda #$A9
	sta RECEIVE_LOOP	; First byte: #$A9 (lda)
	lda #$8D
	sta PUTC		; First byte: #$8D (sta)
	rts

;---------------------------------------------------------
; PATCHNULL - Patch in null comms routines
;---------------------------------------------------------
PATCHNULL:
	lda #<NULLUTHER
	sta RESETIO+1		; No-op the reset routine
	lda #>NULLUTHER
	sta RESETIO+2
	lda #$60		; No-op the rx/tx routines
	sta PUTC
	sta RECEIVE_LOOP
	rts

;---------------------------------------------------------
; NULLUTHER - Do-nothing "reset" routine
;---------------------------------------------------------
NULLUTHER:
	rts

;---------------------------------------------------------
; RESETUTHER - Clean up Uther every time we hit the main loop
;---------------------------------------------------------
RESETUTHER:
	GO_SLOW				; Slow down for SOS
	jsr ip65_process
	GO_FAST				; Speed back up for SOS
	rts

cnt:		.res 1
replyaddr:	.res 4
replyport:	.res 2
state:		.res 2
