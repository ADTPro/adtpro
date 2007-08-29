;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 by David Schmidt
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
;	jsr	nibtitle	; Adjust screen
	jsr	initsnib	; Ask for filename & send to pc
	jsr	nibblank	; Clear progress to all blanks
	jsr	calibrat	; Calibrate the disk

	lda	#CHR_ACK	; Send initial ack
	jsr	PUTC

	lda	#0		; Don't actually use rwts...
	sta	iobtrk		; ...so use this as just memory

snibloop:
	lda	#CHR_R
	jsr	nibshow		; Show 'R' at current track
	jsr	rdnibtr		; Read track as nibbles
	jsr	snibtrak	; Send nibbles to other side
	bcs	snibloop	; Re-read same track
	inc	iobtrk		; Next trackno
	lda	iobtrk
	cmp	#$23		; Repeat while trackno < 35
	bcs	snibfin		; Jump if ready
	jsr	nibnextt	; Go to next track
	jmp	snibloop

snibfin:
	lda	#0		; No errors encountered
	jsr	PUTC		; Send (no) error flag to pc

	jsr	motoroff	; We're finished with the drive
	jmp	AWBEEP		; Beep and end

;---------------------------------------------------------
; initsnib - init send nibble disk
; ask for a filename, then send "N" command and filename
; to the other side and await an acknowldgement.
; note we do not check for a valid disk in the drive;
; basically any disk will do. if there is no disk present,
; bad luck (behaves the same as when booting).
;---------------------------------------------------------
initsnib:
	ldy	#PMSG13
	jsr	WRITEMSG	; Ask filename
	ldx	#0		; Get answer at $200
	jsr	NXTCHAR		; Input the line (Apple ROM)
	lda	#0		; Null-terminate it
	sta	$200,x
	txa
	bne	nibnamok
	jmp	ABORT		; Abort if no filename

nibnamok:
	ldy	#PMWAIT		; "awaiting answer from host"
	jsr	WRITEMSG
	lda	#CHR_N		; Load acc with command code
	jsr	PUTC		;  and send to pc
	ldx	#0
fnloop2:
	lda	$200,x		; Send filename to pc
	jsr	PUTC
	beq	getans2		; Stop at null
	inx
	bne	fnloop2

getans2:  
; for test only: activate next and deactivate line after
;	lda	#0		; Simulate ok
	jsr	GETREPLY	; Answer from host should be 0
	beq	initsn2
	jmp	PCERROR		; Error; exit via getname

initsn2:
	rts

;---------------------------------------------------------
; rdnibtr - read track as nibbles into tracks buffer.
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
	jsr	slot2x		; a = x = slot * 16
	lda	#0		; a = 0
	tay			; y = 0 (index)
	sta	NIBPTR		; set running ptr (lo) to 0
	lda	#>BIGBUF	; BIGBUF address high
	sta	NIBPTR+1	; set running ptr (hi)
	lda	#NIBPAGES
	sta	NIBPCNT		; page counter
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
	lda	$c08c,x		; read (4 cycles)
	bpl	rdnibtr7	; until byte complete (2c)
rdnibtr8:
	sta	(NIBPTR),y	; store in buffer (6c)
	iny			; (2c)
	bne	rdnibtr7	; 256 bytes done? (2 / 3c)
	inc	NIBPTR+1	; next page (5c)
	dec	NIBPCNT		; count (5c)
	bne	rdnibtr7	; and back (3c)
	rts

;---------------------------------------------------------
; snibtrak - send nibble track to the other side
; and wait for acknowledgement. each 256 byte page is
; followed by a 16-bit crc.
; we know the buffer is set up at "BIGBUF", and is
; NIBPAGES * 256 bytes long. BIGBUF is at page boundary.
; when the pc answers ack, clear carry. when it answers
; enq, set carry. when it answers anything else, abort
; the operation with the appropriate error message.
;---------------------------------------------------------
snibtrak:
	lda	#0		; a = 0
	sta	NIBPTR		; Init running ptr
	lda	#>BIGBUF	; BIGBUF address high
	sta	NIBPTR+1
	lda	#NIBPAGES
	sta	NIBPCNT		; Page counter
	lda	#CHR_O
	jsr	nibshow		; Show 'O' at current track
snibtr1:
	jsr	snibpage
	lda	CRC		; followed by crc
	jsr	PUTC
	lda	CRC+1
	jsr	PUTC
; for test only: activate next and deactivate line after
;	lda	#CHR_ACK	; Simulate response.
	jsr	GETREPLY	; Get response from host
	cmp	#CHR_ACK	; Is it ack?
	beq	snibtr5		; Yes, all right
	pha			; Save on stack
	lda	#_I'!'		; Error during send
	jsr	nibshow		; Show status of current track
	pla			; Restore response
	cmp	#CHR_NAK	; Is it nak?
	beq	snibtr1		; Yes, send again
snibtr2:
	ldy	#PHMGBG		; Something is wrong
snibtr3:
	jsr	SHOWHMSG	; Tell bad news
	jsr	motoroff	; Transfer ended in error
	ldy	#PMSG16		; Append prompt
	jsr	WRITEMSGAREA
	jsr	AWBEEP
	jsr	RDKEY		; Wait for key
	jmp	ABORT		;  and abort
         
snibtr5:
	lda	#CHR_O
	jsr	nibshow		; Show 'O' at current track
	inc	NIBPTR+1	; Next page
	dec	NIBPCNT		; Count
	bne	snibtr1		; and back if more pages
; for test only: activate next and deactivate line after
;	lda	#CHR_ACK	; Simulate response
	jsr	GETREPLY	; Get response from host
	cmp	#CHR_ACK	; Is it ack?
	beq	snibtr7		; Ok
	cmp	#CHR_CAN	; Is it can (unreadable trk)?
	beq	snibtr8		; Ok
	cmp	#CHR_NAK	; Was it nak?
	beq	snibtr6		; We will abort
	cmp	#CHR_ENQ
	bne	snibtr2		; Host is confused; abort
	sec			; Let caller know what goes on
	rts
snibtr6:
	ldy	#PMANALYSIS	; Host could not analyze the track
	bpl	snibtr3		; Branch always
snibtr7:
	lda	#CHR_DOT	; Entire track transferred ok
	jsr	nibshow		; Show status of current track
	clc			; Indicate success to caller
	rts
snibtr8:
	lda	#_I'U'		; Entire track was unreadable
	jsr	nibshow		; Probably a half track
	clc			; Indicate success to caller
	rts

;---------------------------------------------------------
; snibpage - send one page with nibble data and calculate
; crc. NIBPTR points to first byte to send.
;---------------------------------------------------------
snibpage:
	ldy	#0		; Start index
	sty	CRC		; Zero crc
	sty	CRC+1
	sty 	RLEPREV		; No previous character
snibpag1:
	lda	(NIBPTR),y	; Load byte to send
	jsr	UPDCRC		; Update crc
	tax			; Keep a copy in x
	sec			; Subtract from previous
	sbc	RLEPREV
	stx	RLEPREV		; Save previous byte
	jsr	PUTC		; Send difference
	beq	snibpag3	; Was it a zero?
	iny			; No, do next byte
	bne	snibpag1	; Loop if more in this page
	rts
         
snibpag2:
	jsr	UPDCRC
snibpag3:
	iny			; Any more bytes?
	beq	snibpag4	; No, it was 00 up to end
	lda	(NIBPTR),y	; Look at next byte
	cmp	RLEPREV
	beq	snibpag2	; Same as before, continue
snibpag4:
	tya			; Difference not a zero
	jsr	PUTC		; Send new address
	bne	snibpag1	;  and go back to main loop
	rts			; Or return if no more bytes

;---------------------------------------------------------
; nibnextt - goto next track. we know there is still room
; to move further. next track is in iobtrk.
; use copy of dos function seekabs.
;---------------------------------------------------------
nibnextt:
	jsr	slot2x		; a = x = slot * 16
	lda	iobtrk		; a = desired track
	asl	a		; a now contains half-track
	pha			; save on stack
	sec			; prepare subtract
	sbc	#2		; a now contains current track
	sta	$478		; seekabs expects this
	pla			; desired track in a
	jsr	seekabs		; let dos function do its thing
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
	lda	#0
	tay			; y=0 (counter)
	sta	synccnt
	sta	synccnt+1	; init number of bytes
nibsync0:
	jsr	chekscnt
	bcs	nibsync5	; accept any byte
nibsync1:
	lda	$c08c,x		; wait for complete byte
	bpl	nibsync1
	iny			; count byte
	cmp	#$ff		; is it a gap byte?
	bne	nibsync0
nibsync2:
	lda	$c08c,x		; next byte
	bpl	nibsync2
	iny			; count byte
	cmp	#$ff		; is it a gap byte?
	bne	nibsync0	; only 1 gap byte
nibsync3:
	lda	$c08c,x		; next byte
	bpl	nibsync3
	iny			; count byte
	cmp	#$ff		; is it a gap byte?
	bne	nibsync0	; only 2 gap bytes
nibsync4:
	lda	$c08c,x		; next byte
	bpl	nibsync4
	iny			; count byte
	cmp	#$ff		; is it a gap byte?
	bne	nibsync0	; only 3 gap bytes
; at this point, we encountered 4 consecutive gap bytes.
; so now wait for the first non-gap byte.
nibsync5:
	pla
	tay			; restore y
nibsync6:
	lda	$c08c,x		; next byte
	bpl	nibsync6
	cmp	#$ff		; is it a gap byte?
	beq	nibsync6	; go read next byte
	jmp	rdnibtr8	; avoid rts; save some cycles

;---------------------------------------------------------
; chekscnt - check if we have to continue syncing
; add y to synccnt (16 bit), and reset y to 0. when
; synccnt reaches $3400, return carry set, else clear.
; $3400 is twice the max number of bytes in one track.
;---------------------------------------------------------
chekscnt:
	clc			; add y to 16-bit synccnt
	tya
	adc	synccnt		; lo-order part
	sta	synccnt
	lda	#0
	tay			; reset y to 0
	adc	synccnt+1	; high-order part
	sta	synccnt+1
	cmp	#$34		; sets carry when a >= data
	rts

;---------------------------------------------------------
; nibblank - clear progress to all blanks
;---------------------------------------------------------
nibblank:
	lda	CV
	pha			; Save current vertical pos
	lda	#5		; Fixed vertical position
	jsr	$fb5b		; Calculate BASL from a
	ldy	#2		; Initial horizontal position
	lda	#CHR_SP		; The character to display
nibblnk1:
	sta	(BASL),y	; Put on screen
	iny			; Next horizontal position
	cpy	#37		; At the end?
	bcc	nibblnk1	; If not, jump back
	pla
	jsr	$fb5b		; Restore cv
	rts

;---------------------------------------------------------
; nibshow - show character in a at current track
; support for haltracking added
;---------------------------------------------------------
nibshow:
	rts

;---------------------------------------------------------
; sendhlf - send entire disk as nibbles with halftracking 
;
; this routine is essentially the same as sendnib except
; the stepper motor is increased only two phases instead
; of four and there are 70 halftracks instead of the normal
; 35. file format is .v2h
;---------------------------------------------------------
sendhlf:
;	jsr	nibtitle	; adjust screen
	jsr	initshlf	; ask for filename & send to pc
	jsr	nibblank	; clear progress to all blanks
	jsr	calibrat	; calibrate the disk

	lda	#CHR_ACK	; send initial ack
	jsr	PUTC

	lda	#0		; don't actually use rwts...
	sta	iobtrk		;  ...so use this as just memory

shlfloop:
	lda	#CHR_R
	jsr	nibshow		; show "R" at current track
	jsr	rdnibtr		; read track as nibbles
	jsr	snibtrak	; send nibbles to other side
	bcs	shlfloop	; re-read same track
	inc	iobtrk		; next trackno
	lda	iobtrk
	cmp	#$46		; repeat while trackno < 70
	bcs	shlffin		; jump if ready
	jsr	hlfnextt	; goto next half track
	jmp	shlfloop

shlffin:
	lda	#0		; no errors encountered
	jsr	PUTC		; send (no) error flag to pc
	jsr	motoroff	; we're finished with the drive
	jmp	AWBEEP		; beep and end

;---------------------------------------------------------
; initshlf - init send halftrack/nibble disk
; ask for a filename, then send "V" command and filename
; to the other side and await an acknowldgement.
; note we do not check for a valid disk in the drive;
; basically any disk will do. if there is no disk present,
; bad luck (behaves the same as when booting).
;---------------------------------------------------------
initshlf:
	ldy	#PMSG13
	jsr	WRITEMSG	; Ask for filename
	ldx	#0		; Get answer at $200
	jsr	NXTCHAR		; Input the line (Apple ROM)
	lda	#0		; Null-terminate it
	sta	$200,x
	txa
	bne	hlfnamok
	jmp	ABORT		; Abort if no filename

hlfnamok:
	ldy	#PMWAIT		; "awaiting answer from host"
	jsr	WRITEMSG
	lda	#CHR_V		; Load acc with command code
	jsr	PUTC		;  ...and send to host
	ldx	#0
hfloop2:
	lda	$200,x		; Send filename to host
	jsr	PUTC
	beq	gethans2	; Stop at null
	inx
	bne	hfloop2

gethans2:
; for test only: activate next and deactivate line after
;	lda	#0		; simulate ok
	jsr	GETREPLY	; answer from host should be 0
	beq	initsh2
	jmp	PCERROR		; error; exit via getname

initsh2:
	rts

;---------------------------------------------------------
; hlfnextt - goto next halftrack. we know there is still room
; to move further. next track is in iobtrk.
; use copy of dos function seekabs.
;---------------------------------------------------------
hlfnextt:
	jsr	slot2x		; a = x = slot * 16
	lda	iobtrk		; a = desired halftrack
	pha			; save on stack
	sec			; prepare subtract
	sbc	#1		; a now contains current track
	sta	$478		; seekabs expects this
	pla			; desired track in a
	jsr	seekabs		; let dos function do its thing
	rts

