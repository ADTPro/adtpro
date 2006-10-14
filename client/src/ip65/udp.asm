;	.include "common.i"

;	.import dbg_dump_udp_header

;	.export udp_init
;	.export udp_process
;	.export udp_add_listener
;	.export udp_remove_listener
;	.export udp_send

;	.export udp_callback

;	.export udp_inp
;	.export udp_outp

;	.exportzp udp_src_port
;	.exportzp udp_dest_port
;	.exportzp udp_len
;	.exportzp udp_cksum
;	.exportzp udp_data
;
;	.export udp_send_dest
;	.export udp_send_src_port
;	.export udp_send_dest_port
;	.export udp_send_len

;	.import ip_calc_cksum
;	.import ip_send
;	.import ip_create_packet
;	.import ip_inp
;	.import ip_outp
;	.importzp ip_cksum_ptr
;	.importzp ip_header_cksum
;	.importzp ip_src
;	.importzp ip_dest
;	.importzp ip_data
;	.importzp ip_proto
;	.importzp ip_proto_udp
;	.importzp ip_id
;	.importzp ip_len
;
;	.import copymem
;	.importzp copy_src
;	.importzp copy_dest

;	.import cfg_ip

;	.bss

; argument for udp_add_listener
udp_callback:	.res 2

; arguments for udp_send
udp_send_dest:		.res 4
udp_send_src_port:	.res 2
udp_send_dest_port:	.res 2
udp_send_len:		.res 2

; udp listener callbacks
udp_cbmax	= 4
udp_cbtmp:	.res 3			; temporary vector
udp_cbveclo:	.res udp_cbmax		; table of listener vectors (lsb)
udp_cbvechi:	.res udp_cbmax		; table of listener vectors (msb)
udp_cbportlo:	.res udp_cbmax		; table of ports (lsb)
udp_cbporthi:	.res udp_cbmax		; table of ports (msb)
udp_cbcount:	.res 1			; number of active listeners

; udp packet offsets
udp_inp		= ip_inp + ip_data
udp_outp	= ip_outp + ip_data
udp_src_port	= 0
udp_dest_port	= 2
udp_len		= 4
udp_cksum	= 6
udp_data	= 8

; virtual header
udp_vh		= udp_outp - 12
udp_vh_src	= 0
udp_vh_dest	= 4
udp_vh_zero	= 8
udp_vh_proto	= 9
udp_vh_len	= 10


; temp for port comparison
port:   	.res 2


;	.code

; initialize udp
udp_init:
	lda #0
	sta udp_cbcount
	lda #$4c			; jmp addr
	sta udp_cbtmp
	rts


; process incoming udp packet
udp_process:
	lda udp_cbcount			; any installed udp listeners?
	beq @drop

	tax				; check ports
	dex
@checkport:
	lda udp_cbportlo,x
	cmp udp_inp + udp_dest_port + 1
	bne :+
	lda udp_cbporthi,x
	cmp udp_inp + udp_dest_port
	beq @handle
:	dex
	bpl @checkport

@drop:
	sec
	rts

@handle:
	lda udp_cbveclo,x		; copy vector
	sta udp_cbtmp + 1
	lda udp_cbvechi,x
	sta udp_cbtmp + 2
	jsr udp_cbtmp			; call listener
	clc
	rts


; add an udp listener
; udp port in A/X, vector in udp_callback
udp_add_listener:
	sta port
	stx port + 1

	ldy udp_cbcount			; any listeners at all?
	beq @add
	cpy #udp_cbmax			; max?
	beq @full
	ldy #0
@check:
	lda udp_cbportlo,y		; check if port is already handled
	cmp port
	bne :+
	lda udp_cbporthi,y
	cmp port + 1
	beq @busy
:	iny
	cpy udp_cbcount
	bne @check
@add:
	inc udp_cbcount			; increase counter
	sta udp_cbportlo,y		; add port
	txa
	sta udp_cbporthi,y		; add port
	lda udp_callback		; and vector
	sta udp_cbveclo,y
	lda udp_callback + 1
	sta udp_cbvechi,y

	clc
	rts
@full:
@busy:
	sec
	rts


; remove an udp listener
; udp port in A/X
udp_remove_listener:
	sta port
	stx port + 1

	ldy udp_cbcount			; any listeners installed?
	beq @notfound
@check:
	lda udp_cbportlo,y		; check if port is handled
	cmp port
	bne :+	
	lda udp_cbporthi,y
	cmp port + 1
	beq @remove
:	iny
	cpy udp_cbcount
	bne @check
@notfound:
	sec
	rts
@remove:
	tya				; number of listeners below
	eor #$ff
	clc
	adc udp_cbcount
	beq @done
@move:
	tax				; number of items to move
:	lda udp_cbportlo + 1,y		; move ports
	sta udp_cbportlo,y
	lda udp_cbporthi + 1,y
	sta udp_cbporthi,y
	lda udp_cbveclo + 1,y		; move vectors
	sta udp_cbveclo,y
	lda udp_cbvechi + 1,y
	sta udp_cbvechi,y
	iny
	dex
	bne :-
@done:
	dec udp_cbcount		; decrement counter
	clc
	rts


; send udp packet
;
; but first:
;
; set destination address
; set source port
; set destination port
; set length
udp_send:
	stax copy_src			; copy data to output buffer
	ldax #udp_outp + udp_data
	stax copy_dest
	ldax udp_send_len
	jsr copymem

udp_send_nocopy:
	ldx #3				; copy virtual header addresses
:	lda udp_send_dest,x
	sta udp_vh + udp_vh_dest,x	; set virtual header destination
	lda cfg_ip,x
	sta udp_vh + udp_vh_src,x	; set virtual header source
	dex
	bpl :-

	lda udp_send_src_port		; copy source port
	sta udp_outp + udp_src_port + 1
	lda udp_send_src_port + 1
	sta udp_outp + udp_src_port

	lda udp_send_dest_port		; copy destination port
	sta udp_outp + udp_dest_port + 1
	lda udp_send_dest_port + 1
	sta udp_outp + udp_dest_port

	lda #ip_proto_udp
	sta udp_vh + udp_vh_proto

	lda #0				; clear checksum
	sta udp_outp + udp_cksum
	sta udp_outp + udp_cksum + 1
	sta udp_vh + udp_vh_zero	; clear virtual header zero byte

	ldax #udp_vh			; checksum pointer to virtual header
	stax ip_cksum_ptr

	lda udp_send_len		; copy length + 8
	clc
	adc #8
	sta udp_outp + udp_len + 1	; lsb for udp header
	sta udp_vh + udp_vh_len + 1	; lsb for virtual header
	tay
	lda udp_send_len + 1
	adc #0
	sta udp_outp + udp_len		; msb for udp header
	sta udp_vh + udp_vh_len		; msb for virtual header

	tax				; length to A/X
	tya

	clc				; add 12 bytes for virtual header
	adc #12
	bcc :+
	inx
:
	jsr ip_calc_cksum		; calculate checksum
	stax udp_outp + udp_cksum

	ldx #3				; copy addresses
:	lda udp_send_dest,x
	sta ip_outp + ip_dest,x		; set ip destination address
	dex
	bpl :-

	jsr ip_create_packet		; create ip packet template

	lda udp_outp + udp_len + 1	; ip len = udp len + 20
	ldx udp_outp + udp_len
	clc
	adc #20
	bcc :+
	inx
:	sta ip_outp + ip_len + 1	; set length
	stx ip_outp + ip_len

	ldax #$1234    			; set ID
	stax ip_outp + ip_id

	lda #ip_proto_udp		; set protocol
	sta ip_outp + ip_proto

	;jsr dbg_dump_udp_header

	jmp ip_send			; send packet, sec on error
