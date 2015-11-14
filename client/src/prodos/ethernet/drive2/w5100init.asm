.feature c_comments

/******************************************************************************

Copyright (c) 2014, Oliver Schmidt
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the <organization> nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL OLIVER SCHMIDT BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

******************************************************************************/

.export w5100_init

;------------------------------------------------------------------------------

w5100_init:
; Input
;       AX: Address of ip_parms (serverip, cfg_ip, cfg_netmask, cfg_gateway)
; Output
;       None
; Remark
;       The ip_parms are only accessed during this function.

        ; Set ip_parms pointer
        sta <w5100_ptr
        stx <w5100_ptr+1

        ; S/W Reset
        lda #$80
        sta w5100_mode
:       lda w5100_mode
        bmi :-

        ; Indirect Bus I/F mode, Address Auto-Increment
        lda #$03
        sta w5100_mode

        ; Gateway IP Address Register: IP address of router on local network
        ldx #$00                ; Hibyte
        ldy #$01                ; Lobyte
        jsr set_addr
        ldy #3*4                ; ip_parms::cfg_gateway
        jsr set_ipv4value

        ; Subnet Mask Register: Netmask of local network
        ; -> addr is already set
        ldy #2*4                ; ip_parms::cfg_netmask
        jsr set_ipv4value

        ; Source Hardware Address Register: MAC Address
        ; -> addr is already set
        ldx #$00
:       lda mac,x
        sta w5100_data
        inx
        cpx #$06
        bcc :-

        ; Source IP Address Register: IP address of local machine
        ; -> addr is already set
        ldy #1*4                ; ip_parms::cfg_ip
        jsr set_ipv4value

        ; RX Memory Size Register: Assign 4KB each to sockets 0 and 1
        ldx #$00                ; Hibyte
        ldy #$1A                ; Lobyte
        jsr set_addr
        lda #$0A
        sta w5100_data

        ; TX Memory Size Register: Assign 4KB each to sockets 0 and 1
        ; -> addr is already set
        ; -> A is still $0A
        sta w5100_data

        ; Socket 1 Source Port Register: 6502
        ldy #$04
        jsr set_addrsocket1
        jsr set_data6502

        ; Socket 1 Destination IP Address Register: Destination IP address
        ; This has to be the last call to set_ipv4value because it writes
        ; as a side effect to 'hdr' and it is the destination IP address
        ; that has to be present in 'hdr' after initialization
        ldy #$0C
        jsr set_addrsocket1
        ldy #0*4                ; ip_parms::serverip
        jsr set_ipv4value

        ; Socket 1 Destination Port Register: 6502
        ; -> addr is already set
        jsr set_data6502

        ; Socket 1 Mode Register: UDP
        ldy #$00
        jsr set_addrsocket1
        lda #$02
        sta w5100_data

        ; Socket 1 Command Register: OPEN
        ; -> addr is already set
        lda #$01
        sta w5100_data
        rts

;------------------------------------------------------------------------------

set_ipv4value:
        ldx #$03
:       lda (w5100_ptr),y
        iny
        sta w5100_data
        sta hdr+2,x
        dex
        bpl :-
        rts

;------------------------------------------------------------------------------

set_data6502:
        lda #<6502
        ldx #>6502
        stx w5100_data                ; Hibyte
        sta w5100_data                ; Lobyte
        rts

;------------------------------------------------------------------------------

set_addrphysical:
        lda w5100_data                ; Hibyte
        ldy w5100_data                ; Lobyte
        sty w5100_ptr
        sta w5100_ptr+1
        and #>$0FFF             ; Socket Mask Address (hibyte)
        stx w5100_bas                 ; Socket Base Address (hibyte)
        ora w5100_bas
        tax
        ora #>$F000             ; Move sha/sha+1 to $F000-$FFFF
        sty w5100_sha
        sta w5100_sha+1

set_addr:
        stx w5100_addr                ; Hibyte
        sty w5100_addr+1              ; Lobyte
        rts

;------------------------------------------------------------------------------

set_addrcmdreg1:
        ldy #$01                ; Socket Command Register

set_addrsocket1:
        ldx #>$0500             ; Socket 1 register base address
        bne set_addr            ; Always

;------------------------------------------------------------------------------

set_addrbase:
        ldx <w5100_bas          ; Socket Base Address (hibyte)
        ldy #<$0000             ; Socket Base Address (lobyte)
        beq set_addr            ; Always

;------------------------------------------------------------------------------

;.rodata

mac:    .byte $00, $08, $DC     ; OUI of WIZnet
        .byte $11, $11, $11

;------------------------------------------------------------------------------

;.data

COMMSLOT:
	.byte $02	; Zero-indexed comms slot (3)
PDHCP:	.byte 0		; DHCP Configuration? (YES)

; Need to write this where w5100io can access it...
hdr:    .word 6502              ; Destination Port
	.byte 01,02,03,04
;        .res  4                 ; Destination IP Address
