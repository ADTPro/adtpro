;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2023 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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

; Tiger Learning Computer (Joystick serial bitbanger) bootstrapper grub
;
; This is the stripped-bare, minimal grub to read data from the joystick port.
; Custom serial-to-joystick cable is required.  RS-232 settings are 9600 bps,
; no parity, 8 data bits, 1 stop bit; 1ms pacing seems to be required.

;
; Process:
;  * Put up a little prompt to show we're alive
;  * Poll the joystick port for data
;  * Once we see a "T" on the port, pull two more bytes (MSB, LSB) of length
;    and start reading that many bytes into $0800
;  * After reading, jump to $0800
;

; This would need to be typed into the monitor (boot the TLC, go to BASIC,
; CALL -151, type it in) and then run (300G).  If it bails out (back) to the
; monitor, it's becaus of noise on the line and a framing error occurred.
; Restarting with 300G and re-sending will effectively retry.  If it gets stuck
; (i.e. an undetected error slips in... there is no other error checking) then
; unplug the cable and hit ctrl-reset.  If the cable is still plugged in, it
; will have the effect of holding the open-apple key down and you'll reboot 
; (rather than just break) if you do a ctrl-reset.

          .org $300

          PB0 = $C061   ; Paddle 0 PushButton: HIGH/ON if > 127, LOW/OFF if < 128.

; Zero page variables (unused by DOS, BASIC and Monitor)
          PAGES = $06
          BUF_P = $08

Entry:
; Set up our pointers
          lda #$00
          tay           ; Clean out Y reg
          sta BUF_P
          lda #$08
          sta BUF_P+1   ; Code goes into $0800

; Say we're active in the upper-right hand corner
          ldx #$C8      ; "H"
          stx $0424
          inx           ; "I"
          stx $0425

; Poll the port until we get a magic incantation
Poll:
          jsr pb0_recv  ; Pull a byte from PB0
          cmp #$54      ; First character of payload will be "T"
          bne Poll

; We got the magic signature; start reading data
          jsr pb0_recv  ; Pull a byte
          sta size      ;   payload LSB
          jsr pb0_recv  ; Pull a byte
          sta size+1    ;   payload MSB

Read:
          jsr pb0_recv  ; Pull a byte
          bcc Entry+1   ; We know we have a framing error so branch to a $00 somewhere
          sta (BUF_P),y ; Save it
          sta $0427     ; Print it in the status area
          iny
          bne :+
          inc BUF_P+1   ; Bump pointer for next page
          dec size+1    ; 
:         cpy size      ; Is LSB of progress the same as requested?
          bne Read      ; No, swing around for more
          lda size+1    ; LSB is the same; is MSB zero?
          bne Read      ; No, swing around for more

; Call bootstrap entry point
          rts ; for now
          jmp $0800     ; Payload entry point

pb0_recv:
; State is currently unknown
          lda #$09      ; We'll be watching for 8 bits plus one stop bit
          sta bits
          clc

poll_for_1:
; Sample PB0's state
          lda PB0
          bpl poll_for_1 ; if not negative, branch to poll_for_1

; State is now 1

poll_for_0:
; Sample PB0's state
          lda PB0
          bmi poll_for_0 ; if negative, branch to poll_for_0

; State just became 0 (start bit)

; Wait 1.5 bit times (104.2 + 52.1 = 156.3us at 9600 bps) to get into the middle of the first bit
; Approximately 152.8 ($99) CPU cycles
; When falling through to here, the above branch was not taken - consuming 2 cycles to get here
          ldx #$1D      ; 2  loop count
:         dex           ; 2 \  = 5 * loop count - 1
          bne :-        ; 3 /  final exit of the loop only adds 2, branch not taken
;                       $94 cycles to get here
          bit $00       ; 3 don't care about results
;                       $97 cycles to get here; final 2 will be consumed by clc below 
pull_byte:
; We now have one bit time (104.2us at 9600 bps) to process this bit
; Approximately 101.8 ($66) CPU cycles
          clc           ; 2
          lda PB0       ; 4
          bmi :+        ; 2 if positive, 3 if negative
          jmp push_bit  ; 3
:         sec           ; 2 bit was low/negative
push_bit: ; We now have a bit in the carry
          dec bits      ; 6
          beq byte_complete ; Have we read all 8 bits?  Then this bit is the stop bit; leave with carry set
                        ; 2 (in the case we care about, i.e. more bits to read)
          lda ring      ; 4
          ror           ; 2
          sta ring      ; 4
;                       $1D cycles to get here (since center of bit time)
; We are now done with processing that bit; we need to cool our heels for the rest ($66 - $1D = $49) of the
; bit time in order to get into the middle of the next bit
          ldx #$0E      ; 2  loop count
:         dex           ; 2 \  = 5 * loop count - 1
          bne :-        ; 3 /  final exit of the loop only adds 2, branch not taken
;                       $47 cycles to get here
          jmp pull_byte ; 3 Loop around for another bit - we actually burn $4A cycles
;                       $67
byte_complete:
          ; Carry now holds stop bit (clear/0 indicates framing error, because we end with set/1)
          lda ring      ; Exit with the assembled byte in A
          rts

; Variable space that doesn't need to be initialized (or typed in, for that matter)
bits:     .byte $00
ring:     .byte $00
size:     .word $0000
