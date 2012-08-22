;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2012 by David Schmidt
; david__schmidt at users.sourceforge.net
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

;---------------------------------------------------------
; sendnib - send entire disk as nibbles
; 
; we don't want to depend on any disk formatting, not even
; on the track and sector numbers. so don't use rwts; just
; calibrate the arm to track 0, and send all 35 tracks. we
; do _not_ support half-tracks. each track is read about
; twice its length, to give the other side enough data to
; make the analysis. each track must be acknowledged 
; before we proceed with the next track.
;---------------------------------------------------------
sendnib:
	jsr nibtitle
	jsr calibrat		; Calibrate the disk
	jsr PUTINITIALACK
	lda SendType
	cmp #CHR_N		; Are we sending full nibble tracks?
	beq :+
	lda #$46		; No, halftracks - so do 70
	jmp @snext
:	lda #$23		; Yes - so do 35
@snext:
	sta maxtrk

	lda #0			; Don't actually use rwts...
	sta iobtrk		; ...so use this as just memory
	sta BLKHI

snibloop:
	lda #$00
	sta BLKLO		; Reset "sector" number using BLKLO
	lda #CHR_V
	jsr nibshow		; Show and "V" at current track
	jsr rdnibtr		; Read track as nibbles
	jsr snibtrak		; Send nibbles to other side
	lda <ZP
	bne snibloop		; Re-read same track if not zero
	inc iobtrk		; Next trackno
	lda iobtrk
	cmp maxtrk		; Repeat while trackno < max
	bcs snibfin		; Jump if ready
	inc BLKHI		; Increment track number using BLKHI
	lda SendType
	cmp #CHR_N		; Are we nibbles?
	bne :+			; No, half tracks
	jsr nibnextt		; Go to next track
	jmp snibloop
:
	jsr hlfnextt		; Go to next half track
	jmp snibloop

snibfin:
	lda #0			; No errors encountered
	sta ECOUNT
	jsr PUTFINALACK		; Send (no) error flag to pc

	jsr motoroff		; We're finished with the drive
	jmp COMPLETE		; Finish using sr.asm's completion code


;---------------------------------------------------------
; rnibtrak - receive a nibble track
; Track number is set in BLKHI
; Each 256 byte page is followed by a 16-bit crc.
; we know the buffer is set up at "BIGBUF", and is
; NIBPAGES * 256 bytes long. BIGBUF is at page boundary.
;---------------------------------------------------------
rnibtrak:
	lda #0			; a = 0
	sta BLKPTR		; Init running ptr
	sta BLKLO
	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
	sta BLKPTR+1		; We will be storing stuff at BIGBUF
	lda #$1A		; Only run for 26 (decimal) pages
	sta NIBPCNT		; Page counter
	lda #CHR_R
	jsr nibshow		; Show "R" at current track
rnibtr1:
	lda #$02
	sta <ZP
	lda #CHR_ACK
rnib2:
	tax
	ldy #$00	; Clear out the new chunk
	tya
rnib3:
	sta (BLKPTR),Y
	iny
	bne rnib3
	txa
	jsr RECVNIBCHUNK
	bcs rnib4	; Error during receive?
	jsr UNDIFF

	lda <CRC
	cmp PCCRC
	bne rnib4
	lda <CRC+1
	cmp PCCRC+1
	bne rnib4

	inc <BLKPTR+1	; Get next 256 bytes
	inc BLKLO	; Increment chunk number
	lda BLKLO
	cmp NIBPCNT	; Have we done all nibble pages?
	beq rnibdone
	lda #CHR_ACK
	jmp rnib2
rnibdone:
	lda #CHR_BLK		; Entire track transferred ok
	jsr nibshow		; Show status of current track
	lda #$00
	rts

rnib4:
	lda #_I'!'		; Error during receive
	jsr nibshow		; Show status of current track
	lda #CHR_NAK	; CRC error, ask for a resend
	jmp rnib2


;---------------------------------------------------------
; snibtrak - send nibble track to the other side
; and wait for acknowledgement. each 256 byte page is
; followed by a 16-bit crc.
; we know the buffer is set up at "BIGBUF", and is
; NIBPAGES * 256 bytes long. BIGBUF is at page boundary.
; when the host answers ack, clear carry. when it answers
; enq, set carry. when it answers anything else, abort
; the operation with the appropriate error message.
;---------------------------------------------------------
snibtrak:
	lda #0			; a = 0
	sta BLKPTR		; Init running ptr
	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
	sta BLKPTR+1
	lda #NIBPAGES
	sta NIBPCNT		; Page counter
	lda #CHR_S
	jsr nibshow		; Show "S" at current track
snibtr1:
	jsr SENDNIBPAGE
	jsr GETREPLY		; Get ack for this page
	cmp #CHR_ACK		; Is it ack?
	beq snibtr5		; Yes, all right
	pha			; Save on stack
	lda #_I'!'		; Error during send
	jsr nibshow		; Show status of current track
	pla			; Restore response
	cmp #CHR_NAK		; Is it nak?
	beq snibtr1		; Yes, send again
	cmp #PHMTIMEOUT		; Is it host timeout?
	beq snibtr1		; Yes, send again
snibtr2:
	ldy #PHMGBG		; Something is wrong
snibtr3:
	jsr SHOWHM1		; Tell bad news
	jsr motoroff		; Transfer ended in error
	jsr PAUSE		; Wait for key
	jmp ABORT		;  and abort
         
snibtr5:
	inc BLKPTR+1		; Next page
	inc BLKLO		; Increment "sector" counter using BLKLO
	dec NIBPCNT		; Count
	bne snibtr1		; and back if more pages
snibtrdloop:
	jsr PUTINITIALACK	; Ready to go again
; for test only: activate next and deactivate line after
;	lda #CHR_ACK		; Simulate response
	jsr GETREPLY2		; Get response from host for whole track
	cmp #CHR_ACK		; Is it ack?
	beq snibtr7		; Ok - go ahead after marking track ok
	cmp #CHR_CAN		; Is it CAN (unreadable trk)?
	beq snibtr8		; Ok - go ahead after marking track unreadable
	cmp #CHR_NAK		; Was it NAK?  Might be because host lost our ACK
	beq snibtr7		; Ok - go ahead after marking track ok
	cmp #PHMTIMEOUT		; Is it host timeout?
	beq snibtrdloop		; Resend track done message
	cmp #CHR_ENQ		; Need to re-send whole track?
	bne snibtr2		; Host is confused; abort
	lda #$01		; Reset counter and swing around again
	sta <ZP
	sec			; Let caller know what goes on
	rts
snibtr6:
	ldy #PMANALYSIS		; Host could not analyze the track
	bpl snibtr3		; Branch always
snibtr7:
	lda #CHR_BLK		; Entire track transferred ok
	jsr  nibshow		; Show status of current track
	lda #$00
	sta <ZP
	clc			; Indicate success to caller
	rts
snibtr8:
	lda #_I'U'		; Entire track was unreadable
	jsr nibshow		; Probably a half track
	lda #$00
	sta <ZP
	clc			; Indicate success to caller
	rts

;---------------------------------------------------------
; nibnextt - goto next track. we know there is still room
; to move further. next track is in iobtrk.
; use copy of dos function seekabs.
;---------------------------------------------------------
nibnextt:
	ldx pdsoftx		; x = slot * 16
	lda iobtrk		; a = desired track
	asl a			; a now contains half-track
	pha 			; save on stack
	sec 			; prepare subtract
	sbc #2			; a now contains current track
	sta $478		; seekabs expects this
	pla 			; desired track in a
	jsr seekabs		; let dos function do its thing
	rts

;---------------------------------------------------------
; nibsync - Synchronize on first byte after gap
; this function is only used from rdnibtr, but I had to
; make it a separate function to keep other stuff in one
; page (because of instriuction timings).
; This function is always fast enough to process the
; nibbles, no matter how it is laid out in memory.
; It always returns the first nibble after a gap, provided
; the track has a gap at all.  If we don't find a gap, we
; probably have to do with an unformatted track.  In that 
; case, just return any byte as the first, so the process
; can continue.
; On entry, x must contain slot * 16.  The disk must spin,
; and we must be in read mode and on the right track.
; On exit, the zero flag is 0, and a contains the byte.
; X and Y are preserved.
; Note we check the number of bytes read only when 
; starting a new sequence; the check takes so long we
; lose any byte sync we might have (> 32 cycles).
;---------------------------------------------------------
nibsync:
	tya
	pha			; save y on the stack
	lda #0
	tay			; y=0 (counter)
	sta synccnt
	sta synccnt+1		; init number of bytes
nibsync0:
	jsr chekscnt
	bcs nibsync5		; accept any byte
nibsync1:
	lda $c08c,x		; wait for complete byte
	bpl nibsync1
	iny			; count byte
	cmp #$ff		; is it a gap byte?
	bne nibsync0
nibsync2:
	lda $c08c,x		; next byte
	bpl nibsync2
	iny			; count byte
	cmp #$ff		; is it a gap byte?
	bne nibsync0		; only 1 gap byte
nibsync3:
	lda $c08c,x		; next byte
	bpl nibsync3
	iny			; count byte
	cmp #$ff		; is it a gap byte?
	bne nibsync0		; only 2 gap bytes
nibsync4:
	lda $c08c,x		; next byte
	bpl nibsync4
	iny			; count byte
	cmp #$ff		; is it a gap byte?
	bne nibsync0		; only 3 gap bytes
; At this point, we encountered 4 consecutive gap bytes.
; so now wait for the first non-gap byte.
nibsync5:
	pla
	tay			; restore y
nibsync6:
	lda $c08c,x		; next byte
	bpl nibsync6
	cmp #$ff		; is it a gap byte?
	beq nibsync6		; go read next byte
	jmp rdnibtr8		; avoid rts; save some cycles

;---------------------------------------------------------
; rdnibtr - read track as nibbles into tracks buffer.
; This code must not cross a page boundary.
;
; total bytes read is NIBPAGES * 256, or about twice
; the track length.
; the drive has been calibrated, so we know we are in read
; mode, the motor is running, and and the correct drive 
; number is engaged.
; we wait until we encounter a first nibble after a gap.
; for this purpose, a gap is at least 4 ff nibbles in a 
; row. note this is not 100% fool proof; the ff nibble
; can occur as a regular nibble instead of autosync.
; but this is conform beneath apple dos, so is
; probably ok.
;---------------------------------------------------------
rdnibtr:
	ldx pdsoftx		; Load drive index into X
	lda #0			; a = 0
	tay			; y = 0 (index)
	sta BLKPTR		; set running ptr (lo) to 0
	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
	sta BLKPTR+1		; set running ptr (hi)
	lda #NIBPAGES
	sta NIBPCNT		; page counter
; use jmp, not jsr, to perform nibsync. that way we
; have a bit more breathing room, cycle-wise. the
; "function" returns with a jmp to rdnibtr8.
	jmp	nibsync		; find first post-gap byte
; the read loop must be fast enough to read 1 byte every
; 32 cycles. it appears the interval is 17 cycles within
; one data page, and 29 cycles when crossing a data page.
; these numbers are based on code that does not cross
; a page boundary.
rdnibtr7:
	lda $c08c,x		; read (4 cycles)
	bpl rdnibtr7		; until byte complete (2c)
rdnibtr8:
	sta (BLKPTR),y		; store in buffer (6c)
	iny			; (2c)
	bne rdnibtr7		; 256 bytes done? (2 / 3c)
	inc BLKPTR+1		; next page (5c)
	dec NIBPCNT		; count (5c)
	bne rdnibtr7		; and back (3c)
	rts

;---------------------------------------------------------
; chekscnt - check if we have to continue syncing
; add y to synccnt (16 bit), and reset y to 0. when
; synccnt reaches $3400, return carry set, else clear.
; $3400 is twice the max number of bytes in one track.
;---------------------------------------------------------
chekscnt:
	clc			; add y to 16-bit synccnt
	tya
	adc synccnt		; lo-order part
	sta synccnt
	lda #0
	tay			; reset y to 0
	adc synccnt+1		; high-order part
	sta synccnt+1
	cmp #$34		; sets carry when a >= data
	rts

;---------------------------------------------------------
; nibblank - clear progress to all blanks
;---------------------------------------------------------
nibblank:
	lda CV
	pha			; Save current vertical pos
	lda #$0e		; Fixed vertical position
	jsr TABV		; Calculate BASL from a
	lda #2			; Initial horizontal position
	jsr HTAB
	lda #CHR_SP		; The character to display
nibblnk1:
	jsr COUT		; Put on screen
	iny			; Next horizontal position
	cpy #37			; At the end?
	bcc nibblnk1		; If not, jump back
	pla
	jsr TABV		; Restore cv
	rts

;---------------------------------------------------------
; nibshow - show character in a at current track
; support for haltracking added
;---------------------------------------------------------
nibshow:
	tay		; CHARACTER IN Y
	lda CV
	pha		; SAVE CV ON STACK
	tya		; A NOW CONTAINS CHAR
	pha		; Save char on stack
	lda #$0e	; Fixed vertical position
	jsr TABV	; Calculate BASL from A
	lda SendType	; Check to see if we're in half track
	cmp #CHR_N	;   or Nibble mode
	beq NIBNORM	; Nibble - branch there
	lda iobtrk
	cmp #0		; TRACK ZERO ALWAYS TREATED THE SAME
	beq NIBNORM
	lsr		; IS TRACK ODD OR EVEN?
	bcc NIBEVEN	; TRACK IS EVEN, CONTINUE NORMALLY
	lda #$0f	; INCREMENT VERTICAL POSITION
	jsr TABV	; CALCULATE BASL FROM A
NIBEVEN:
	lda iobtrk	; CURRENT TRACK
	lsr		; CALC HORIZ POS BY
	clc		; DIVIDING BY TWO AND
	adc #2		; ADDING 2
	jmp NIBDISP
NIBNORM:
	lda iobtrk	; CURRENT TRACK
	clc
	adc #2		; CALCULATE HORIZONTAL POS
NIBDISP:
	tay		; INDEX VALUE IN Y
	pla		; RESTORE CHARACTER TO SHOW
	jsr COUT
	pla
	jsr TABV	; RESTORE CV
	rts


;---------------------------------------------------------
; hlfnextt - goto next halftrack. we know there is still room
; to move further. next track is in iobtrk.
; use copy of dos function seekabs.
;---------------------------------------------------------
hlfnextt:
	ldx pdsoftx		; x = slot * 16
	lda iobtrk		; a = desired halftrack
	pha			; save on stack
	sec			; prepare subtract
	sbc #1			; a now contains current track
	sta $478		; seekabs expects this
	pla			; desired track in a
	jsr seekabs		; let dos function do its thing
	rts
