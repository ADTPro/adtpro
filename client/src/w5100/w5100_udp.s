ptr := $06         ; 2 byte pointer value
tmp := $08         ; 1 byte temporary value
bas := $09         ; 1 byte socket 1 Base Address (hibyte)
sha := $19         ; 2 byte physical addr shadow ($F000-$FFFF)
len := $1B         ; 2 byte frame length
adv := $1D         ; 2 byte pointer register advancement

mode := $C0C4
addr := $C0C5
data := $C0C7

.export init
.export recv_init, recv_byte, recv_done
.export send_init, send_byte, send_done

;------------------------------------------------------------------------------
init_error:
	sec
	rts

init:
	jsr w5100_self_modify
        ; Set ip_parms pointer
        sta ptr
        stx ptr+1

        ; S/W Reset
        lda #$80
fixw01:	sta mode
fixw02:	lda mode
        bne init_error

        ; Indirect Bus I/F mode, Address Auto-Increment
        lda #$03
fixw03:	sta mode

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
imac:	lda w5100_mac,x
fixw06:	sta data
        inx
        cpx #$06
        bcc imac

        ; Source IP Address Register: IP address of local machine
        ; -> addr is already set
        ldy #1*4                ; ip_parms::cfg_ip
        jsr set_ipv4value

        ; RX Memory Size Register: Assign 4KB each to sockets 0 and 1
        ldx #$00                ; Hibyte
        ldy #$1A                ; Lobyte
        jsr set_addr
        lda #$0A
fixw07:	sta data

        ; TX Memory Size Register: Assign 4KB each to sockets 0 and 1
        ; -> addr is already set
        ; -> A is still $0A
fixw08:	sta data

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

        ; Socket 1 Source Port Register: 6502
        ldy #$04
        jsr set_addrsocket1
        jsr set_data6502

        ; Socket 1 Mode Register: UDP
        ldy #$00
        jsr set_addrsocket1
        lda #$02
fixw09:	sta data

        ; Socket 1 Command Register: OPEN
        ; addr is already set
        lda #$01
fixw10:	sta data
        rts

;------------------------------------------------------------------------------

set_ipv4value:
        ldx #$03
simore:	lda (ptr),y
        iny
fixw11:	sta data
        sta hdr+2,x
        dex
        bpl simore
        rts

;------------------------------------------------------------------------------

set_data6502:
        lda #<6502
        ldx #>6502
fixw12:	stx data                ; Hibyte
fixw13:	sta data                ; Lobyte
        rts

;------------------------------------------------------------------------------

recv_init:
        ; Socket 1 RX Received Size Register: 0 or volatile ?
        lda #$26                ; Socket RX Received Size Register
        jsr prolog
        bcs :+++

        ; Socket 0 RX Read Pointer Register
        ; -> addr already set

        ; Calculate and set pyhsical address
        ldx #>$7000             ; Socket 1 RX Base Address
        jsr set_addrphysical

        ; Compare peer IP addr and peer port with expected values
        ; in 'hdr' and set C(arry flag) if there's a mismatch
        clc
        ldx #$05
        stx tmp
:       jsr recv_byte           ; Doesn't trash C
        ldx tmp
        eor hdr,x               ; Doesn't trash C
        beq :+
        sec
:       dec tmp
        bpl :--
        php                     ; Save C

        ; Read data length
        jsr recv_byte           ; Hibyte
        sta len+1
        jsr recv_byte           ; Lobyte
        sta len

        ; Add 8 byte header to set pointer advancement
        clc
        adc #<$0008
        sta adv
        lda len+1
        adc #>$0008
        sta adv+1

        ; Skip frame if it doesn't originate from our
        ; expected communicaion peer
        plp                     ; Restore C
        bcs recv_done

        ; Return success with data length
        lda len
        ldx len+1
        clc
:       rts

;------------------------------------------------------------------------------

send_init:
        ; Set pointer advancement
        sta adv
        stx adv+1

        ; Socket 1 TX Free Size Register: 0 or volatile ?
        lda #$20                ; Socket TX Free Size Register
        jsr prolog
        bcs :+

        ; Socket 1 TX Free Size Register: < advancement ?
        cpx adv                 ; Lobyte
        sbc adv+1               ; Hibyte
        bcc rts_cs

        ; Socket 1 TX Write Pointer Register
        ldy #$24
        jsr set_addrsocket1

        ; Calculate and set pyhsical address
        ldx #>$5000             ; Socket 1 TX Base Address
        jsr set_addrphysical

        ; Return success
        clc
:       rts

;------------------------------------------------------------------------------

prolog:
        ; Check for completion of previous command
        ; Socket 1 Command Register: 0 ?
        jsr set_addrcmdreg1
fixw14:	ldx data
        bne rts_cs              ; Not completed -> error

        ; Socket Size Register: not 0 ?
        tay                     ; Select Size Register
        jsr get_wordsocket1
        stx ptr                 ; Lobyte
        sta ptr+1               ; Hibyte
        ora ptr
        bne :+
rts_cs: sec                     ; Error (size == 0)
        rts

        ; Socket Size Register: volatile ?
:       jsr get_wordsocket1
        cpx ptr                 ; Lobyte
        bne rts_cs              ; Volatile size -> error
        cmp ptr+1               ; Hibyte
        bne rts_cs              ; Volatile size -> error
        clc                     ; Sucess (size != 0)
        rts

;------------------------------------------------------------------------------

recv_byte:
        ; Read byte
fixw15:	lda data

        ; Increment physical addr shadow lobyte
        inc sha
        beq incsha
        rts

;------------------------------------------------------------------------------

send_byte:
        ; Write byte
fixw16:	sta data

        ; Increment physical addr shadow lobyte
        inc sha
        beq incsha
        rts

        ; Increment physical addr shadow hibyte
incsha: inc sha+1
        beq set_addrbase
        rts

;------------------------------------------------------------------------------

recv_done:
        ; Set parameters for commit code
        lda #$40                ; RECV
        ldy #$28                ; Socket RX Read Pointer Register
        bne epilog              ; Always

;------------------------------------------------------------------------------

send_done:
        ; Set parameters for commit code
        lda #$20                ; SEND
        ldy #$24                ; Socket TX Write Pointer Register

        ; Advance pointer register
epilog: jsr set_addrsocket1
        tay                     ; Save command
        clc
        lda ptr
        adc adv
        tax
        lda ptr+1
        adc adv+1
fixw17:	sta data                ; Hibyte
fixw18:	stx data                ; Lobyte

        ; Set command register
        tya                     ; Restore command
        jsr set_addrcmdreg1
fixw19:	sta data
        sec                     ; When coming from _recv_init -> error
        rts

;------------------------------------------------------------------------------

set_addrphysical:
fixw20:	lda data                ; Hibyte
fixw21:	ldy data                ; Lobyte
        sty ptr
        sta ptr+1
        and #>$0FFF             ; Socket Mask Address (hibyte)
        stx bas                 ; Socket Base Address (hibyte)
        ora bas
        tax
        ora #>$F000             ; Move sha/sha+1 to $F000-$FFFF
        sty sha
        sta sha+1
set_addr:
fixw04:	stx addr                ; Hibyte
fixw05:	sty addr+1              ; Lobyte
        rts

;------------------------------------------------------------------------------

set_addrcmdreg1:
        ldy #$01                ; Socket Command Register
set_addrsocket1:
        ldx #>$0500             ; Socket 1 register base address
        bne set_addr            ; Always

;------------------------------------------------------------------------------

set_addrbase:
        ldx bas                 ; Socket Base Address (hibyte)
        ldy #<$0000             ; Socket Base Address (lobyte)
        beq set_addr            ; Always

;------------------------------------------------------------------------------

get_wordsocket1:
        jsr set_addrsocket1
fixw22:	lda data                ; Hibyte
fixw23:	ldx data                ; Lobyte
        rts

; w5100_self_modify - make all entry points variable so we can move the
;   hardware addresses around in the Apple
;
w5100_self_modify:
	ldy COMMSLOT	; GET SLOT# (0..6)
	iny		; NOW 1..7
	tya
	asl
	asl
	asl
	asl
	clc
	adc #$84	; Now $84+S0 ($c0b0)
	; Make the accumulator contain slot number plus $80
	;   i.e. Slot 1 = $94
	;   i.e. Slot 2 = $A4
	;   i.e. Slot 3 = $B4
	;   i.e. Slot 4 = $C4
	;   i.e. Slot 5 = $D4
	;   i.e. Slot 6 = $E4
	;   i.e. Slot 7 = $F4
; $c0s4 - WIZNET_MODE_REG - save off all references to mode
	sta fixw01 + 1
	sta fixw02 + 1
	sta fixw03 + 1
; $c0s5 - WIZNET_ADDR_HI
	adc #$01
	sta fixw04 + 1
; $c0s6 - WIZNET_ADDR_LO
	adc #$01
	sta fixw05 + 1
; $c0s7 - WIZNET_DATA_REG
	adc #$01
	sta fixw06 + 1
	sta fixw07 + 1
	sta fixw08 + 1
	sta fixw09 + 1
	sta fixw10 + 1
	sta fixw11 + 1
	sta fixw12 + 1
	sta fixw13 + 1
	sta fixw14 + 1
	sta fixw15 + 1
	sta fixw16 + 1
	sta fixw17 + 1
	sta fixw18 + 1
	sta fixw19 + 1
	sta fixw20 + 1
	sta fixw21 + 1
	sta fixw22 + 1
	sta fixw23 + 1

	rts

;------------------------------------------------------------------------------

.rodata

w5100_mac:    .byte $00, $08, $DC     ; OUI of WIZnet
        .byte $11, $11, $11

;------------------------------------------------------------------------------

.data

hdr:    .word 6502              ; Destination Port
        .res  4                 ; Destination IP Address