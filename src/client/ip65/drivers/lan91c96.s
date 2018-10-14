; Ethernet driver for SMC LAN91C96 chip 
;

.ifndef KPR_API_VERSION_NUMBER
  .define EQU     =
  .include "../inc/kipper_constants.i"
.endif

.include "../inc/common.i"

	.export lan_mac
	.export lan_init
	.export lan_rx
	.export lan_tx

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.import fix_eth_tx
	.import fix_eth_rx

	.import COMMSLOT
	.import cfg_mac

	.importzp eth_packet

	.data

; LANceGS hardware addresses
ethbsr		:= $c00E	; Bank select register             R/W (2B)

; Register bank 0
ethtcr		:= $c000	; Transmission control register    R/W (2B)
ethephsr	:= $c002	; EPH status register              R/O (2B)
ethrcr		:= $c004	; Receive control register         R/W (2B)
ethecr		:= $c006	; Counter register                 R/O (2B)
ethmir		:= $c008	; Memory information register      R/O (2B)
ethmcr		:= $c00A	; Memory Config. reg.    +0 R/W +1 R/O (2B)

; Register bank 1
ethcr		:= $c000	; Configuration register           R/W (2B)
ethbar		:= $c002	; Base address register            R/W (2B)
ethiar		:= $c004	; Individual address register      R/W (6B)
ethgpr		:= $c00A	; General address register         R/W (2B)
ethctr		:= $c00C	; Control register                 R/W (2B)

; Register bank 2
ethmmucr	:= $c000	; MMU command register             W/O (1B)
ethautotx	:= $c001	; AUTO TX start register           R/W (1B)
ethpnr		:= $c002	; Packet number register           R/W (1B)
etharr		:= $c003	; Allocation result register       R/O (1B)
ethfifo		:= $c004	; FIFO ports register              R/O (2B)
ethptr		:= $c006	; Pointer register                 R/W (2B)
ethdata		:= $c008	; Data register                    R/W (4B)
ethist		:= $c00C	; Interrupt status register        R/O (1B)
ethack		:= $c00C	; Interrupt acknowledge register   W/O (1B)
ethmsk		:= $c00D	; Interrupt mask register          R/W (1B)

; Register bank 3
ethmt		:= $c000	; Multicast table                  R/W (8B)
ethmgmt		:= $c008	; Management interface             R/W (2B)
ethrev		:= $c00A	; Revision register                R/W (2B)
ethercv		:= $c00C	; Early RCV register               R/W (2B)

;initialize the Ethernet adaptor
;inputs: none
;outputs: carry flag is set if there was an error, clear otherwise
lan_init:
	jsr lan_self_modify
	lda #$01
fixlan00:
	sta ethbsr		; Select register bank 1
fixlan01:
	lda ethcr		; Read bytes 0, 2, and 3 should be $31, $67, $18
	cmp #$31
	bne lanerror
fixlan03:
	lda ethbar
	cmp #$67
	bne lanerror
fixlan04:
	lda ethbar+1
	cmp #$18
	bne lanerror
	; we have the magic signature

	; Reset chip
	lda #$00		; Bank 0
fixlan05:
	sta ethbsr
	lda #%10000000		; Software reset
fixlan06:
	sta ethrcr+1

	ldy #$00
fixlan07:
	sty ethrcr
fixlan08:
	sty ethrcr+1

	; Delay
:	cmp ($FF,x)		; 6 cycles
	cmp ($FF,x)		; 6 cycles
	iny			; 2 cycles
	bne :-			; 3 cycles
				; 17 * 256 = 4352 -> 4,4 ms

	; Enable transmit and receive
	lda #%10000001		; Enable transmit TXENA, PAD_EN
	ldx #%00000011		; Enable receive, strip CRC ???
fixlan09:
	sta ethtcr
fixlan10:
	stx ethrcr+1

	lda #$01		; Bank 1
fixlan11:
	sta ethbsr
	
fixlan12:
	lda ethcr+1
	ora #%00010000		; No wait (IOCHRDY)
fixlan13:
	sta ethcr+1

	lda #%00001001		; Auto release
fixlan14:
	sta ethctr+1
  
	; Set MAC address
	lda cfg_mac
	ldx cfg_mac + 1
fixlan15:
	sta ethiar
fixlan16:
	stx ethiar + 1
	lda cfg_mac + 2
	ldx cfg_mac + 3
fixlan17:
	sta ethiar + 2
fixlan18:
	stx ethiar + 3
	lda cfg_mac + 4
	ldx cfg_mac + 5
fixlan19:
	sta ethiar + 4
fixlan20:
	stx ethiar + 5

	; Set interrupt mask
	lda #$02		; Bank 2
fixlan21:
	sta ethbsr
	
	lda #%00000000		; No interrupts
fixlan22:
	sta ethmsk
	clc
	rts

lanerror:
	sec
	rts
	

; send a packet
;inputs:
; eth_outp: packet to send
; eth_outp_len: length of packet to send
;outputs:
; if there was an error sending the packet then carry flag is set
; otherwise carry flag is cleared
lan_tx:
	lda eth_outp_len + 1
	ora #%00100000
fixlan23:
	sta ethmmucr	; Allocate memory for transmission
fixlan24:
	lda ethist
	and #%00001000	; Allocation interrupt
	bne :+
	sec
	rts		; Not able to allocate; bail

:	lda #%00001000
fixlan25:
	sta ethack	; Acknowledge interrupt

fixlan26:
	lda etharr
fixlan27:
	sta ethpnr	; Set packet number

	lda #$00
	ldx #%01000000	; Auto increment
fixlan28:
	sta ethptr
fixlan29:
	stx ethptr + 1

	lda #$00	; Status written by CSMA
fixlan30:
	sta ethdata
fixlan31:
	sta ethdata

	lda eth_outp_len
	eor #$01
	lsr
	lda eth_outp_len
	adc #$05	; Actually will be 5 or 6 depending on carry
fixlan32:
	sta ethdata
	lda eth_outp_len + 1
	adc #$00
fixlan33:
	sta ethdata

	lda #<eth_outp	; Send the packet
	ldx #>eth_outp
	sta eth_packet
	stx eth_packet + 1
	ldx eth_outp_len + 1
	ldy #$00
lanwrite:
	lda (eth_packet),y
fixlan34:
	sta ethdata
	iny
	bne :+
	inc eth_packet + 1
:	cpy eth_outp_len
	bne lanwrite
	dex
	bpl lanwrite

	lda eth_outp_len	; Odd packet length?
	lsr
	bcc :+

	lda #%001000000	; Yes, Odd
	bne fixlan36	; Always

:	lda #$00	; No
fixlan35:
	sta ethdata	; Fill byte
fixlan36:
	sta ethdata	; Control byte
	lda #%11000000	; Enqueue packet - transmit
fixlan37:
	sta ethmmucr

	clc
	rts

;receive a packet
;inputs: none
;outputs:
; if there was an error receiving the packet (or no packet was ready) then carry flag is set
; if packet was received correctly then carry flag is clear, 
; eth_inp contains the received packet, 
; and eth_inp_len contains the length of the packet
lan_rx:
fixlan38:
	lda ethist
	and #%00000001	; Check receive interrupt
	bne :+
	sec		; No packet available
	rts
	
:	lda #$00
	ldx #%11100000	; Receive, Auto Increment, Read
fixlan39:
	sta ethptr
fixlan40:
	stx ethptr + 1

	; Last word contains 'last data byte' and $60 or 'fill byte' and $40 
fixlan41:
	lda ethdata	; Status word
fixlan42:
	lda ethdata	; Only need high byte

	; Move ODDFRM bit into carry:
	; - Even packet length -> carry clear -> subtract 6 bytes
	; - Odd packet length  -> carry set   -> subtract 5 bytes
	lsr
	lsr
	lsr
	lsr
	lsr

	; The packet contains 3 extra words
fixlan43:
	lda ethdata		; Total number of bytes
	sbc #$05		; Actually 5 or 6 depending on carry
	sta eth_inp_len
fixlan44:
	lda ethdata
	sbc #$00
	sta eth_inp_len+1

	; Read bytes into buffer
	lda #<eth_inp
	ldx #>eth_inp
	sta eth_packet
	stx eth_packet+1
  	ldx eth_inp_len+1
  	ldy #$00
lanread:
fixlan46:
	lda ethdata
	sta (eth_packet),y
	iny
	bne :+
	inc eth_packet+1
:	cpy eth_inp_len
	bne lanread
	dex
	bpl lanread
  
	; Remove and release RX packet from the FIFO
	lda #%10000000
fixlan47:
	sta ethmmucr

	clc
	rts
	

;
; lan_self_modify - make all entry points variable so we can move the
;   hardware addresses around in the Apple
;
lan_self_modify:

	ldax #lan_tx		; Fixup transmit addresses in the stack
	jsr fix_eth_tx

	ldax #lan_rx		; Fixup receive addresses in the stack
	jsr fix_eth_rx

	ldy COMMSLOT	; GET SLOT# (0..6)
	iny		; NOW 1..7
	tya
	asl
	asl
	asl
	asl
	clc
	adc #$80	; Now $80+S0 ($c0b0)
	; Make the accumulator contain slot number plus $80
	;   i.e. Slot 1 = $90
	;   i.e. Slot 2 = $A0
	;   i.e. Slot 3 = $B0
	;   i.e. Slot 4 = $C0
	;   i.e. Slot 5 = $D0
	;   i.e. Slot 6 = $E0
	;   i.e. Slot 7 = $F0
; $C0s0: Save off all ethtcr, ethcr, ethmmucr, and ethmt mods
	sta fixlan01 + 1
	sta fixlan09 + 1
	sta fixlan23 + 1
	sta fixlan37 + 1
;	sta fixlan45 + 1	; Removed
	sta fixlan47 + 1

; $C0s1: Save off all ethtcr+1, ethcr+1, ethmmucr+1, and ethmt+1 mods
	adc #$01
;	sta fixlan02 + 1	; Removed
	sta fixlan12 + 1
	sta fixlan13 + 1

; $C0s2: Save off all ethephsr, ethbar, and ethpnr mods
	adc #$01
	sta fixlan03 + 1
	sta fixlan27 + 1

; $C0s3: Save off all ethephsr+1, ethbar+1, ethpnr+1, and etharr mods
	adc #$01
	sta fixlan04 + 1
	sta fixlan26 + 1

; $C0s4: Save off all ethrcr, ethiar, and ethfifo mods
	adc #$01
	sta fixlan07 + 1
	sta fixlan15 + 1

; $C0s5: Save off all ethrcr+1, ethiar+1, and ethfifo+1 mods
	adc #$01
	sta fixlan06 + 1
	sta fixlan08 + 1
	sta fixlan10 + 1
	sta fixlan16 + 1

; $C0s6: Save off all ethecr, ethptr, and ethiar+2 mods
	adc #$01
	sta fixlan17 + 1
	sta fixlan28 + 1
	sta fixlan39 + 1

; $C0s7: Save off all ethecr+1, ethptr+1, and ethiar+3 mods
	adc #$01
	sta fixlan18 + 1
	sta fixlan29 + 1
	sta fixlan40 + 1

; $C0s8: Save off all ethmir, ethdata, ethmgmt, and ethiar+4 mods
	adc #$01
	sta fixlan19 + 1
	sta fixlan30 + 1
	sta fixlan31 + 1
	sta fixlan32 + 1
	sta fixlan33 + 1
	sta fixlan34 + 1
	sta fixlan35 + 1
	sta fixlan36 + 1
	sta fixlan41 + 1
	sta fixlan42 + 1
	sta fixlan43 + 1
	sta fixlan44 + 1
	sta fixlan46 + 1

; $C0s9: Save off all ethmir+1, ethdata+1, ethmgmt+1, and ethiar+5 mods
	adc #$01
	sta fixlan20 + 1

; $C0sA: Save off all ethmcr, ethgpr, and ethrev mods
; $C0sB: Save off all ethmcr+1, ethgpr+1, and ethrev+1 mods
	; None

; $C0sC: Save off all ethctr, ethist, ethack, and ethercv mods
	adc #$03	; Because there were no a or b mods
	sta fixlan24 + 1
	sta fixlan25 + 1
	sta fixlan38 + 1

; $C0sD: Save off all ethmsk, ethctr+1 mods
	adc #$01
	sta fixlan14 + 1
	sta fixlan22 + 1

; $C0sE: Save off all ethbsr mods
	adc #$01
	sta fixlan00 + 1
	sta fixlan05 + 1
	sta fixlan11 + 1
	sta fixlan21 + 1

; Copy over the mac
	ldx #$03
:	lda lan_mac,x
	sta cfg_mac+2,x
	dex
	bpl :-

	rts


lan_mac:
	.byte $0f, $10, $18, $67

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
; The Initial Developer of the Original Code is David Schmidt
; Portions created by the Initial Developer is Copyright (C) 2011
; All Rights Reserved.  
; -- LICENSE END --
