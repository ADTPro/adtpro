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

.export recv_init, recv_byte, recv_done
.export send_init, send_byte, send_done

;------------------------------------------------------------------------------

recv_init:
; Input
;       None
; Output
;       C:  Clear if ready to receive
;       AX: If C is clear then number of bytes to receive
; Remark
;       To be called before recv_byte.

        ; Socket 1 RX Received Size Register: 0 or volatile ?
        lda #$26                ; Socket RX Received Size Register
        jsr prolog
        bcs :+++

        ; Socket 1 RX Read Pointer Register
        ; -> addr already set

        ; Calculate and set pyhsical address
        ldx #>$7000             ; Socket 1 RX Base Address
        jsr set_addrphysical2

        ; Compare peer IP addr and peer port with expected values
        ; in 'hdr' and set C(arry flag) if there's a mismatch
        clc
        ldx #$05
        stx w5100_tmp
:       jsr recv_byte           ; Doesn't trash C
        ldx w5100_tmp
        eor hdr_from_init,x               ; Doesn't trash C
        beq :+
        sec
:       dec w5100_tmp
        bpl :--
        php                     ; Save C

        ; Read data length
        jsr recv_byte           ; Hibyte
        sta w5100_len+1
        jsr recv_byte           ; Lobyte
        sta w5100_len

        ; Add 8 byte header to set pointer advancement
        clc
        adc #<$0008
        sta w5100_adv
        lda w5100_len+1
        adc #>$0008
        sta w5100_adv+1

        ; Skip frame if it doesn't originate from our
        ; expected communicaion peer
        plp                     ; Restore C
        bcs recv_done

        ; Return success with data length
        lda w5100_len
        ldx w5100_len+1
        clc
:       rts

;------------------------------------------------------------------------------

send_init:
; Input
;       AX: Number of bytes to send
; Output
;       C: Clear if ready to send
; Remark
;       To be called before send_byte.

        ; Set pointer advancement
        sta w5100_adv
        stx w5100_adv+1

        ; Socket 1 TX Free Size Register: 0 or volatile ?
        lda #$20                ; Socket TX Free Size Register
        jsr prolog
        bcs :+

        ; Socket 1 TX Free Size Register: < advancement ?
        cpx w5100_adv                 ; Lobyte
        sbc w5100_adv+1               ; Hibyte
        bcc sec_rts             ; Not enough free size -> error

        ; Socket 1 TX Write Pointer Register
        ldy #$24
        jsr set_addrsocket12

        ; Calculate and set pyhsical address
        ldx #>$5000             ; Socket 1 TX Base Address
        jsr set_addrphysical2

        ; Return success
        clc
:       rts

;------------------------------------------------------------------------------

prolog:
        ; Check for completion of previous command
        ; Socket 1 Command Register: 0 ?
        jsr set_addrcmdreg12
        ldx w5100_data
        bne sec_rts             ; Not completed -> error

        ; Socket Size Register: not 0 ?
        tay                     ; Select Size Register
        jsr get_wordsocket1
        stx w5100_ptr                 ; Lobyte
        sta w5100_ptr+1               ; Hibyte
        ora w5100_ptr
        bne :+

sec_rts:
        sec                     ; Error (size == 0)
        rts

        ; Socket Size Register: volatile ?
:       jsr get_wordsocket1
        cpx w5100_ptr                 ; Lobyte
        bne sec_rts             ; Volatile size -> error
        cmp w5100_ptr+1               ; Hibyte
        bne sec_rts             ; Volatile size -> error
        clc                     ; Success (size != 0)
        rts

;------------------------------------------------------------------------------

recv_byte:
; Input
;       None
; Output
;       A: Byte received
; Remark
;       May be called as often as indicated by recv_init.

        ; Read byte
        lda w5100_data

        ; Increment physical addr shadow lobyte
        inc w5100_sha
        beq incsha
        rts

;------------------------------------------------------------------------------

send_byte:
; Input
;       A: Byte to send
; Output
;       None
; Remark
;       Should be called as often as indicated to send_init.

        ; Write byte
        sta w5100_data

        ; Increment physical addr shadow lobyte
        inc w5100_sha
        beq incsha
        rts

incsha:
        ; Increment physical addr shadow hibyte
        inc w5100_sha+1
        beq set_addrbase2
        rts

;------------------------------------------------------------------------------

recv_done:
; Input
;       None
; Output
;       None
; Remark
;       Mark data indicated by recv_init as processed (independently from how
;       often recv_byte was called), if not called then next call of recv_init
;       will just indicate the very same data again.

        ; Set parameters for commit code
        lda #$40                ; RECV
        ldy #$28                ; Socket RX Read Pointer Register
        bne epilog              ; Always

;------------------------------------------------------------------------------

send_done:
; Input
;       None
; Output
;       None
; Remark
;       Actually send data indicated to send_init (independently from how often
;       send_byte was called), if not called then send_init (and send_byte) are
;       just NOPs.

        ; Set parameters for commit code
        lda #$20                ; SEND
        ldy #$24                ; Socket TX Write Pointer Register

epilog:
        ; Advance pointer register
        jsr set_addrsocket12
        tay                     ; Save command
        clc
        lda w5100_ptr
        adc w5100_adv
        tax
        lda w5100_ptr+1
        adc w5100_adv+1
        sta w5100_data                ; Hibyte
        stx w5100_data                ; Lobyte

        ; Set command register
        tya                     ; Restore command
        jsr set_addrcmdreg12
        sta w5100_data
        sec                     ; When coming from recv_init -> error
        rts

;------------------------------------------------------------------------------

set_addrphysical2:
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

set_addr2:
        stx w5100_addr                ; Hibyte
        sty w5100_addr+1              ; Lobyte
        rts

;------------------------------------------------------------------------------

set_addrcmdreg12:
        ldy #$01                ; Socket Command Register

set_addrsocket12:
        ldx #>$0500             ; Socket 1 register base address
        bne set_addr2            ; Always

;------------------------------------------------------------------------------

set_addrbase2:
        ldx w5100_bas                 ; Socket Base Address (hibyte)
        ldy #<$0000             ; Socket Base Address (lobyte)
        beq set_addr2            ; Always

;------------------------------------------------------------------------------

get_wordsocket1:
        jsr set_addrsocket12
        lda w5100_data                ; Hibyte
        ldx w5100_data                ; Lobyte
        rts

hdr_from_init:
	.word 6502              ; Destination Port
	.res  4                 ; Destination IP Address
