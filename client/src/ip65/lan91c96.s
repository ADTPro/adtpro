; Ethernet driver for LAN91C96
;
; By David Schmidt
; Based on Contiki source by Adam Dunkels, Josef Soucek and Oliver Schmidt

	.include "common.i"

	.export lan_init
	.export lan_rx
	.export lan_tx

	.import eth_inp
	.import eth_inp_len
	.import eth_outp
	.import eth_outp_len

	.import fix_eth_tx_00	; from ip.s
	.import fix_eth_tx_01	; from icmp.s
	.import fix_eth_tx_02	; from arp.s
	.import fix_eth_tx_03	; from arp.s

	.import fix_eth_rx_00	; from ip65.s
	.import fix_eth_rx_01	; from ip65.s

	.import PSSC	; From mainline code
	.import cfg_mac

	.importzp eth_packet

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

	.code

; initialize, return clc on success
lan_init:
	jsr lan_self_modify
	lda #$01
fixlan00:
	sta ethbsr			; Select register bank 1
fixlan01:
	lda ethcr			; Read first four bytes - $31, $20, $67, $18
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

	; Reset ETH card
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
lan_tx:
	lda eth_outp_len + 1	;
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


; receive a packet
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
;   LANceGS card around in the Apple
;
lan_self_modify:

	ldax #lan_tx		; Fixup transmit addresses
	sta fix_eth_tx_00 +1
	stx fix_eth_tx_00 +2
	sta fix_eth_tx_01 +1
	stx fix_eth_tx_01 +2
	sta fix_eth_tx_02 +1
	stx fix_eth_tx_02 +2
	sta fix_eth_tx_03 +1
	stx fix_eth_tx_03 +2

	ldax #lan_rx		; Fixup receive addresses
	sta fix_eth_rx_00 + 1
	stx fix_eth_rx_00 + 2
	sta fix_eth_rx_01 + 1
	stx fix_eth_rx_01 + 2

	ldy PSSC	; GET SLOT# (0..6)
	iny		; NOW 1..7
	tya
	asl
	asl
	asl
	asl
	clc
	adc #$80	; Now $80+S0 ($c0b0)
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
