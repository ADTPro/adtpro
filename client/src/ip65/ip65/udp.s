;UDP (user datagram protocol) functions

.include "../inc/common.i"
.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

	;.import dbg_dump_udp_header

  .import ip65_error

	.export udp_init
	.export udp_process
	.export udp_add_listener
	.export udp_remove_listener
	.export udp_send
	.export udp_send_nocopy

	.export udp_callback

	.export udp_inp
	.export udp_outp

	.exportzp udp_src_port
	.exportzp udp_dest_port
	.exportzp udp_len
	.exportzp udp_cksum
	.exportzp udp_data

	.export udp_send_dest
	.export udp_send_src_port
	.export udp_send_dest_port
	.export udp_send_len


	.import ip_calc_cksum
	.import ip_send
	.import ip_create_packet
	.import ip_inp
	.import ip_outp
	.importzp ip_cksum_ptr
	.importzp ip_header_cksum
	.importzp ip_src
	.importzp ip_dest
	.importzp ip_data
	.importzp ip_proto
	.importzp ip_proto_udp
	.importzp ip_id
	.importzp ip_len

	.import copymem
	.importzp copy_src
	.importzp copy_dest

	.import cfg_ip
  
  .data
  udp_cbtmp:	jmp $ffff			; temporary vector - gets filled in later


	.bss

; argument for udp_add_listener
udp_callback:	.res 2  ;vector to routine to be called when a udp packet arrives

; arguments for udp_send
udp_send_dest:		.res 4  ;set to ip address that udp packet will be sent to
udp_send_src_port:	.res 2 ;set to port that udp packet will be sent from
udp_send_dest_port:	.res 2 ;set to port that udp packet will be sent to
udp_send_len:		.res 2 ;set to length of data to be sent in udp packet (excluding ethernet,ip & udp headers)

; udp listener callbacks
udp_cbmax	= 4
udp_cbveclo:	.res udp_cbmax		; table of listener vectors (lsb)
udp_cbvechi:	.res udp_cbmax		; table of listener vectors (msb)
udp_cbportlo:	.res udp_cbmax		; table of ports (lsb)
udp_cbporthi:	.res udp_cbmax		; table of ports (msb)
udp_cbcount:	.res 1			; number of active listeners

; udp packet offsets
udp_inp		= ip_inp + ip_data  ;pointer to udp packet inside inbound ethernet frame
udp_outp	= ip_outp + ip_data ;pointer to udp packet inside outbound ethernet frame
udp_src_port	= 0 ;offset of source port field in udp packet
udp_dest_port	= 2 ;offset of destination port field in udp packet
udp_len		= 4 ;offset of length field in udp packet
udp_cksum	= 6 ;offset of checksum field in udp packet
udp_data	= 8 ;offset of data in udp packet

; virtual header
udp_vh		= udp_outp - 12
udp_vh_src	= 0
udp_vh_dest	= 4
udp_vh_zero	= 8
udp_vh_proto	= 9
udp_vh_len	= 10


; temp for port comparison
port:   	.res 2


	.code

; initialize udp
; inputs: none
; outputs: none
udp_init:
	lda #0
	sta udp_cbcount
	rts


;process incoming udp packet
;inputs:
; eth_inp: should contain an ethernet frame encapsulating an inbound udp packet
;outputs:
; carry flag set if any error occured (including if no handler for specified port
;  was found)
; carry flag clear if no error
; if handler was found, an outbound message may be created, overwriting eth_outp

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
  lda #KPR_ERROR_NO_SUCH_LISTENER
  sta  ip65_error
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


;add a udp listener
;inputs:
; udp_callback: vector to call when udp packet arrives on specified port
; AX: set to udp port to listen on
;outputs:
; carry flag set if too may listeners already installed, clear otherwise
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
  lda #KPR_ERROR_LISTENER_NOT_AVAILABLE
  sta  ip65_error
  sec
	sec
	rts


; remove an udp listener
; inputs:
; AX = port to stop listening on
; outputs:
; carry flag clear of handler found and removed
; carry flag set if handler for specified port not found
udp_remove_listener:
	sta port
	stx port + 1

	ldy udp_cbcount			; any listeners installed?
	beq @notfound
  dey
@check:
	lda udp_cbportlo,y		; check if port is handled
	cmp port
	bne :+	
	lda udp_cbporthi,y
	cmp port + 1
	beq @remove
:	dey
	bpl @check
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


;send udp packet
;inputs:
;   udp_send_dest:  destination ip address (4 bytes)
;   udp_send_dest_port: destination port (2 bytes)
;   udp_send_src_port: source port (2 bytes)
;   udp_send_len: length of data to send (exclusive of any headers)
;   AX: pointer to buffer containing data to be sent
;outputs:
;   carry flag is set if an error occured, clear otherwise
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



;-- LICENSE FOR udp.s --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
; 
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
; 
; The Original Code is ip65.
; 
; The Initial Developer of the Original Code is Per Olofsson,
; MagerValp@gmail.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Per Olofsson. All Rights Reserved.  
; -- LICENSE END --
