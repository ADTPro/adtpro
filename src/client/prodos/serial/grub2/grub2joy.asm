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
; no parity, 8 data bits, 1 stop bit; 1ms pacing seems to be required.

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

RCVBYTE  =  $06
size     =  $07 ; and $08

    .org    $300
Entry:
    jsr $fc58   ; HOME

    ldx #$c8
    stx $424
    inx

    stx $425

poll:
    jsr get_byte
    cmp #$54
    bne poll

; Got signature, read data
    jsr get_byte
    sta size
    jsr get_byte
    sta size+1
    ldy #0

read:
    jsr get_byte
read_patch:
    sta $800,y
    sta $427
    iny
    bne skip_inc
    inc read_patch+2
    dec size+1
skip_inc:
    lda size+1
    bne read
    cpy size
    bcc read
    jmp $800


get_byte:
; The serial line must be idle (PB0 must have it high bit set)
; We simply must wait for the beginning of the start bit (PB0 high bit clear)
    lda #$80
    sta RCVBYTE
wait_for_start:
    bit PB0 ; 4
    bmi wait_for_start  ; 2

; We got the start sometime in the last 3-10 clocks.  Wait 1.5 bit times so
; grab the bits in the middle of the bit times.  There are $6a CPU cycles in
; one bit time.  So 1.5 bit times = $9f cycles.
    ldx #$1d        ; 2
    bne read_bit2   ; 3

read_bit:
    ldx #$12    ; 2
read_bit2:
    dex     ; 2
    bne read_bit2   ; Total cycles: X*5 - 1 = $90 (for first bit)
    lda PB0 ; 4
    asl     ; 2
    ror RCVBYTE ; 5
    bcc read_bit ; 3
; Above overhead, not counting read_bit2 loop, is 2+4+2+5+3=$10 clocks
; We need the wait to take $5a clocks (so $5a+$10=$6a), but we actually wait $59.
; We'll just slip one cycle, it's fine
; Delay from wait_for_start to lda PB0 in read_bit2 is: 4+2+2+3+$90=$9b

; If we get here, we have the byte in RCVBYTE.  We are 2+2+5+2 cycles past
; the middle of the last bit, and we want to wait about $5a clocks total
; before returning.
    ldx #$0d        ;2
wait_stop:
    dex             ; 2
    bne wait_stop   ; $40: Total = X*5 - 1
    lda RCVBYTE  ; 2
    nop          ; 2
    rts

; from last lda PB0 to the fastest call back (count just the jsr):
; 2+5+2 + 2+$40+2+2+6+6=$5e.  We are solidly in the middle of the stop bit.
; Code should call back get_byte within $3c clocks.