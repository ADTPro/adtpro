;	.import ip65_init
;	.import ip65_process

;	.import udp_add_listener
;	.import udp_callback
;	.import udp_send

;	.import udp_inp
;	.import udp_outp

;	.importzp udp_data
;	.importzp udp_len
;	.importzp udp_src_port
;	.importzp udp_dest_port

;	.import udp_send_dest
;	.import udp_send_src_port
;	.import udp_send_dest_port
;	.import udp_send_len

;	.importzp ip_src
;	.import ip_inp

udp_in:
	lda udp_inp + udp_src_port + 1
	sta replyport
	lda udp_inp + udp_src_port
	sta replyport + 1

	ldx #3
:	lda ip_inp + ip_src,x
	sta replyaddr,x
	dex
	bpl :-

	lda udp_inp + udp_len + 1
	sec
	sbc #8
	sta cnt
	ldax #udp_inp + udp_data
	stax UTILPTR
	ldy #0
@print:
	lda (UTILPTR),y
	cmp #10
	bne :+
	lda #13
:	jsr putchar
	iny
	cpy cnt
	bne @print

	rts

;---------------------------------------------------------
; INITUTHER - Initialize Uther card
;---------------------------------------------------------
INITUTHER:
	jsr PATCHUTHER
	jsr ip65_init
	bcc @UTHEROK
	ldy #PMUTHBAD
	jsr SHOWM1
@UTHEROK:
	ldax #udp_in
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

	rts

;---------------------------------------------------------
; PATCHUTHER - Patch in Uthernet entry points
;---------------------------------------------------------
PATCHUTHER:
	lda #<RESETUTHER
	sta RESETIO+1
	lda #>RESETUTHER
	sta RESETIO+2

	rts

;---------------------------------------------------------
; RESETUTHER - Clean up Uther every time we hit the main loop
;---------------------------------------------------------
RESETUTHER:
	jsr ip65_process
	rts

print:
	sta UTILPTR
	stx UTILPTR + 1
	ldy #0
:	lda (UTILPTR),y
	beq :+
	jsr putchar
	iny
	bne :-
:	rts

putchar:
	cmp	#$60	; lowercase ?
        bcc	:+
        and	#$5F	; -> uppercase
:	ora	#$80
	jsr	COUT1
  rts


cnt:		.res 1
replyaddr:	.res 4
replyport:	.res 2
idle		= 1
recv		= 2
resend		= 3

serverip:
;	.byte 192, 168, 0, 2
;	.byte 192 ,168, 0, 15
	.byte 192 ,168, 0, 42
;	.byte 127, 0, 0, 1
