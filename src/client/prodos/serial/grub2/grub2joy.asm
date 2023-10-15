;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2023 by ADTPro contributors
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
; no parity, 8 data bits, 1 stop bit.

;
; Process:
;  * Put up a little prompt to show we're alive
;  * Poll the joystick port for data
;  * Once we see a "T" on the port, pull two more bytes (MSB, LSB) of length
;    and start reading that many bytes starting at $0800
;  * After reading, jump to $0800
;

; This would need to be typed into the monitor (boot the TLC, go to BASIC,
; CALL -151, type it in) and then run (300G).  If it bails out (back) to the
; monitor, it's because of noise on the line and a framing error occurred.
; Restarting with 300G and re-sending will effectively retry.  If it gets stuck
; (i.e. an undetected error slips in... there is no other error checking) then
; unplug the cable and hit ctrl-reset and retry.  If the cable is still plugged
; in, it will have the effect of holding the open-apple key down and you'll
; reboot (rather than just break) if you do a ctrl-reset.

PB0  =  $c061
size =  $07 ; and $08

    .org $300
Entry:
    jsr $fc58   ; HOME

    ldx #$c8
    stx $424
    inx
    stx $425

poll:
    jsr get_byte
    cmp #$54
    bne read_patch+1    ; Hit a BRK

; Got signature, read data
    ldx #$fe
get_size:
    jsr get_byte
    sta size+2,x
    inx
    bne get_size

read:
    jsr get_byte
read_patch:
    sta $800,x
    sta $427
    inx
    bne skip_inc
    inc read_patch+2
    dec size+1
skip_inc:
    lda size+1
    bne read
    cpx size
    bcc read
    jmp $800


get_byte:
; The serial line must be idle (PB0 must have it high bit set)
; We simply must wait for the beginning of the start bit (PB0 high bit clear)
wait_for_start:
    lda PB0
    bmi wait_for_start  ; 2

; We got the start sometime in the last 3-10 clocks.  Wait 1.5 bit times so
; grab the bits in the middle of the bit times.  There are 106 CPU cycles in
; one bit time.  So 1.5 bit times = 159 cycles
    ldy #29     ; 2
    lda #$80        ; 2
    .byte  $2c     ; 4 (and skip ldx #19)

read_bit:
    ldy #19 ; 2
read_bit2:
    dey     
    bne read_bit2   ; Total cycles: X*5 - 1 = 89
    asl PB0 ; 6 (4 cycles to the read, 2 more cycle to shift and wr)
    ror     ; 2
    bcc read_bit ; 3
; Above overhead, not counting read_bit2 loop, is 2+6+2+3=13 clocks
; We need the wait to take 93 clocks (so 93+13=106), but we actually wait 94.
; We'll just slip one cycle, it's fine
; Delay from wait_for_start to lda PB0 in read_bit2 is: 4+2+2+2+4+144=158

; If we get here, we have the byte in acc.  We are 2+2+2+2 cycles past
; the middle of the last bit, and we want to wait about 90 clocks total
; before returning.
    ldy #13     ;2
wait_stop:
    dey
    bne wait_stop   ; 64: Total = X*5 - 1
    rts

; from last lda PB0 to the fastest call back (count just the jsr):
; 2+2+2 + 2+64+6+6=84.  We are solidly in the middle of the stop bit.
; Code should call back get_byte within 60 clocks.