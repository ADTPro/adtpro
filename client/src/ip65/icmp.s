	.include "common.i"


	.export icmp_init
	.export icmp_process
	.export icmp_add_listener
	.export icmp_remove_listener

	.export icmp_callback

	.export icmp_inp
	.export icmp_outp

	.export fix_eth_tx_01

	.exportzp icmp_type
	.exportzp icmp_code
	.exportzp icmp_cksum
	.exportzp icmp_data

	.import ip_calc_cksum
	.import ip_inp
	.import ip_outp
	.import ip_broadcast
	.importzp ip_cksum_ptr
	.importzp ip_header_cksum
	.importzp ip_src
	.importzp ip_dest
	.importzp ip_data

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len


	.bss

; argument for icmp_add_listener
icmp_callback:	.res 2

; icmp callbacks
icmp_cbmax	= 4
icmp_cbtmp:	.res 3			; temporary vector
icmp_cbveclo:	.res icmp_cbmax		; table of listener vectors (lsb)
icmp_cbvechi:	.res icmp_cbmax		; table of listener vectors (msb)
icmp_cbtype:	.res icmp_cbmax		; table of listener types
icmp_cbcount:	.res 1			; number of active listeners

; icmp packet offsets
icmp_inp	= ip_inp + ip_data
icmp_outp	= ip_outp + ip_data
icmp_type	= 0
icmp_code	= 1
icmp_cksum	= 2
icmp_data	= 4

; icmp echo packet offsets
icmp_echo_id	= 4
icmp_echo_seq	= 6
icmp_echo_data	= 8


	.code

; initialize icmp
icmp_init:
	lda #0
	sta icmp_cbcount
	lda #$4c			; jmp addr
	sta icmp_cbtmp
	rts


; process incoming icmp packet
icmp_process:
	lda icmp_inp + icmp_type
	cmp #8				; ping
	beq @echo

	lda icmp_cbcount		; any installed icmp listeners?
	beq @drop

	ldx icmp_cbcount		; check listened types
	dex
:	lda icmp_cbtype,x
	cmp icmp_inp + icmp_type
	beq @handle			; found a match
	dex
	bpl :-

@drop:
	sec
	rts

@handle:
	lda icmp_cbveclo,x		; copy vector
	sta icmp_cbtmp + 1
	lda icmp_cbvechi,x
	sta icmp_cbtmp + 2
	jsr icmp_cbtmp			; call listener
	clc
	rts

@echo:
	lda ip_broadcast		; check if packet is broadcast
	beq @notbc
	sec				; don't reply to broadcast pings
	rts
@notbc:
	ldx #5
:	lda eth_inp,x			; swap dest and src mac
	sta eth_outp + 6,x
	lda eth_inp + 6,x
	sta eth_outp,x
	dex
	bpl :-

	ldx #12				; copy the packet
:	lda eth_inp,x
	sta eth_outp,x
	inx
	cpx eth_inp_len
	bne :-

	ldx #3
:	lda ip_inp + ip_src,x		; swap dest and src ip
	sta ip_outp + ip_dest,x
	lda ip_inp + ip_dest,x
	sta ip_outp + ip_src,x
	dex
	bpl :-

	lda #0				; change type to reply
	sta icmp_outp + icmp_type

	lda icmp_inp + icmp_cksum	; recalc checksum
	clc
	adc #8
	sta icmp_outp + icmp_cksum
	bcc :+
	inc icmp_outp + icmp_cksum + 1
:
	lda eth_inp_len			; copy length
	sta eth_outp_len
	lda eth_inp_len + 1
	sta eth_outp_len + 1

	lda #0				; clear checksum
	sta ip_outp + ip_header_cksum
	sta ip_outp + ip_header_cksum + 1
	ldax #ip_outp			; calculate ip header checksum
	stax ip_cksum_ptr
	ldax #20
	jsr ip_calc_cksum
	stax ip_outp + ip_header_cksum

fix_eth_tx_01:
	jsr $0000			; jsr eth_tx send packet

	clc
	rts


; add an icmp listener
; icmp type in A, vector in icmp_callback
icmp_add_listener:
	ldx icmp_cbcount		; any listeners at all?
	beq @add
	cpx #icmp_cbmax			; max?
	beq @full
	ldx #0
:	cmp icmp_cbtype,x		; check if type is already listened
	beq @busy
	inx
	cpx icmp_cbcount
	bne :-
@add:
	inc icmp_cbcount		; increase counter
	sta icmp_cbtype,x		; add type
	lda icmp_callback		; and vector
	sta icmp_cbveclo,x
	lda icmp_callback + 1
	sta icmp_cbvechi,x

	clc
	rts
@full:
@busy:
	sec
	rts


; remove an icmp listener
; icmp type in A
icmp_remove_listener:
	ldx icmp_cbcount		; any listeners installed?
	beq @notfound
:	cmp icmp_cbtype,x		; check if type is listened
	beq @remove
	inx
	cpx icmp_cbcount
	bne :-
@notfound:
	sec
	rts
@remove:
	txa				; number of listeners below
	eor #$ff
	clc
	adc icmp_cbcount
	beq @done
@move:
	tay				; number of items to move
:	lda icmp_cbtype + 1,x		; move type
	sta icmp_cbtype,x
	lda icmp_cbveclo + 1,x		; move vector lsb
	sta icmp_cbveclo,x
	lda icmp_cbvechi + 1,x		; move vector msb
	sta icmp_cbvechi,x
	inx
	dey
	bne :-
@done:
	dec icmp_cbcount		; decrement counter
	clc
	rts
