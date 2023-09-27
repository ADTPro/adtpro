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

; Tiger Learning Computer bootstrapper grub
;
; This is the stripped-bare, minimal grub to read data from the joystick port.
; The idea is to get just enough started to read in a bigger, more robust
; bootstrap loader.  Custom serial-to-joystick cable is required.  RS-232
; settings are 9600 bps, no parity, 8 data bits, 1 stop bit.

;
; Process:
;  * Put up a little prompt to show we're alive
;  * Poll the joystick port for data
;  * Once we see a "T" on the port, start reading $100 byte blocks into $2000
;  * After reading $300 bytes, jump to $2000 (we don't count the initial "T")
;

; This would need to be typed into the monitor (boot the TLC, go to BASIC,
; CALL -151, type it in) and then run (300G).

          .org $300

          PB0 = $C061   ; Paddle 0 PushButton: HIGH/ON if > 127, LOW/OFF if < 128.

; Zero page variables (all unused by DOS, BASIC and Monitor)
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
          ldx #$46      ; Page total
          stx PAGES
Read:	
          jsr pb0_recv  ; Pull a byte
          bcc Forget_it ; We know we have a framing error
          sta (BUF_P),y ; Save it
          sta $0427     ; Print it in the status area
          iny
          bne Read      ; Pull in a full page
          inc BUF_P+1   ; Bump pointer for next page
          dec PAGES
          bne Read      ; Go back for another page

; Call bootstrap entry point
          rts ; for now
          jmp $0800     ; Payload entry point

Forget_it:
          brk

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

; Wait 1.5 bit times (104.2 + 52.1 = 156.3us at 9600 baud) to get into the middle of the first bit
; Approximately 152.8 ($99) CPU cycles
; When falling through to here, the above branch was not taken - consuming 2 cycles to get here
          ldx #$14      ; 2  loop count
:         nop           ; 2 \
          dex           ; 2  |-- 7 * loop count - 1
          bne :-        ; 3 /  final exit of the loop adds 2, branch not taken
;                       $8F cycles to get here
          beq :+        ; 3 burn
:         beq :+        ; 3 baby
:         nop           ; 2 burn
;                       $97 cycles to get here; final 2 will be consumed by clc below 
pull_byte:
; We now have one bit time (104.2us at 9600 baud) to process this bit
; Approximately 106.6 ($6B) CPU cycles
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
; We are now done with processing that bit; we need to cool our heels for the rest ($6B - $1D = $4E) of the
; bit time in order to get into the middle of the next bit
          ldx #$0A      ; 2  loop count
:         nop           ; 2 \
          dex           ; 2  |-- 7 * loop count - 1
          bne :-        ; 3 /  final exit of the loop adds 2, branch not taken
;                         $47 cycles to get here, burn $07 more (includes our jump back to top of loop)
          nop           ; 2
          nop           ; 2
          jmp pull_byte ; 3 Loop around for another bit - we burned $4E cycles
;                         $6A
byte_complete:
          ; Carry now holds stop bit (clear/0 indicates framing error, because we end with set/1)
          lda ring      ; Exit with the assembled byte in A
          rts
bits:     .byte $00
ring:     .byte $55
