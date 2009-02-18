	.include "applechr.i"

;--------------------------------
; Apple Disk Transfer
; By Paul Guertin
; pg@sff.net
; DISTRIBUTE FREELY
;--------------------------------
	.LIST	ON

; Overview
; --------
; This program transfers a 16-sector disk
; to a 140K MS-DOS file and back.  The file
; format (dos-ordered, .dsk) is compatible
; with most Apple II emulators.
; SSC, IIgs or compatible hardware is required.

; Protocol
; --------
; This program initiates any data exchange with the host, which typically
; runs on a PC or Macintosh computer.
;
; The first byte transmited is always a command code:
; - R to receive a disk image
; - S to send a disk in sector form
; - N to send a disk in nibble form
; - V to send a disk in nibble form, using half-tracks
; - D to get a directory listing of the hosts's working directory
;
; The protocol for each of the commands is described below.
; 
; Initial protocol negotiation
; ----------------------------
; In the case of the R, S, N, or V command code, ADT sends three bytes 
; to negotiate a protocol:
; - High-order byte of a protocol number (range 0x01 to 0x1F)
; - Low-order byte of a protcol number (range 0x01 to 0xFF)
; - A null byte
; The protocol number identifies the exact protocol that will
; be used. It allows the host to decide whether it supports this
; protocol or not. ADT waits for an answer:
; - ACK (0x06) means the host supports this protocol
; - NAK (0x15) means the host does not support this protocol
; - Any other answers means the host is incompatible.
; Currently, the only supported protocol version is 0x0101.
;
; In the case of an ACK response, ADT continues by sending the
; file name of the disk image file the host is supposed to save 
; (in the case of S, N or V command) or read (in the case of the 
; R) command. The file name is terminated by a 0-byte.
; It is up to the host how to interpret the file name. The host
; probably considers it relative to a working directory, the
; same as used in the D command.
; ADT then waits for an answer from the host, being one byte:
; - 0x00 means OK, file name is accepted
; - 0x1A means the file name is invalid (any command) or the file doesn't 
;   exist on the host (R command only)
; - 0x1C (S, N or V command only) means the file already exists on the host
; - 0x1E (R command only) means the file exists on the host, but is not a 
;   valid disk image file
;
; Any response other than 0x00 aborts the operation.
; When the response is 0x00, different things occur for the different 
; commands.
;
; The R command
; -------------
; In the case of the R command (after the initial negotiation described 
; above), ADT starts by sending ACK to the host, to indicate it is ready 
; to receive. ADT then expects to receive the 560 sectors of a diskette, 
; starting at track 0 sector 0. 
; Each track is sent in increasing order of DOS logical sector numbers. 
; The data is compressed with RLE (see below). Each sector is followed by 
; a 2-byte checksum (which does not take part in the RLE compression), 
; and is acknowledged by ADT. The possible answers are:
; - ACK : checksum matches; please send next sector
; - NAK : checksum does not match; please resend same sector
; After receiving the entire disk (all 560 sectors), ADT send a final
; byte with the overall result: 0 is success, any non-0 value is an error.
; When the user interrupts the transfer, the host is not notified; adt 
; just stops reading the input. The transfer at the host side must be 
; stopped manually in whatever way the host software provides.
;
; The S command
; -------------
; After the initial protocol negotiation described above, ADT starts
; by sending ACK to the host, to indicate it is ready to send. It then 
; sends the 560 disk sectors exactly as described for the R command, with
; the roles of ADT and host reversed.
; After sending the entire disk, ADT sends a final byte with the overall 
; result: 0 is success, any non-0 value is an error.
; When the user interrupts the transfer, the host is not notified; ADT
; just stops sending bytes The transfer at the host side must be stopped
; manually in whatever way the host software provides.
;
; The N and V commands
; --------------------
; After the initial protocol negotiation described above, ADT starts by
; sending ACK. It then sends either 35 tracks (N command) or 70 tracks
; (V command). Each track is handled as follows.
; ADT sends 52 blocks of 256 bytes each. The bytes are raw disk nibbles,
; and these 13312 bytes (about 2 full disk rotations) give the host enough
; raw material to analyze the data. 
; It is guaranteed that ADT starts each track with a nibble that comes right
; after a gap.
; Each of the 256-byte blocks is sent as follows:
; - 1 byte block number within the track (starting at 0)
; - 1 byte track number (N command) or half-track number (V command)
; - 1 byte with fixed value 0x02
; - 256 data bytes, compressed with RLE (see below)
; - 2 bytes checksum over the 256 data bytes
; The host must either confirm (ACK) or reject (NAK) the block, just as in
; the S command.
; After sending the entire track, ADT waits for a response byte from the host:
; - ACK: analysis was successful; please proceed with the next track
; - NAK: analysis failed; abort the operation
; - CAN (0x18): analysis failed, but please continue with next track
; - ENQ (0x05): analysis was inconclusive; please re-read the
;               same track and send the newly read data
; After sending all tracks, ADT sends a final status code, which is always
; 0x00 (success).
; Note that the host plays an important role in controlling the process.
; For example, it is up to the host to decide how many times to request
; for a track re-read, and also to decide when continuing the transfer is
; useless.
;
; The D command
; -------------
; No preliminary protocol negotiation takes place.
; The host starts sending text to be displayed on the Apple II screen. The 
; layout is completely up to the host. The text is plain ASCII, not Apple II
; "high" ASCII. It might contain \r end-of-line characters. The host must
; make sure the text does not exceed one screen on the Apple II.
; The last character of the screen text sent is 0x00. After that, the host
; sends a continuation byte:
; - 0x01 to indicate more screens are to follow
; - 0x00 to indicate this was the last screen; this ends the Dir command
; If the continuation character is 0x01, ADT has two options:
; - Send 0x00 to abort the Dir command (this ends the command), or
; - Send any other byte to have the host send the next screen.

; RLE compression
; ---------------
; The 256 byte blocks sent over the line are compressed with a form of
; run length encoding. Refer to the source for details on the exact
; operation.

; Checksum calculation
; --------------------
; The 16-bit checksum is based on the exclusive or of two items:
; - The data bytes before RLE is applied
; - The bytes form a crc table, indexed with the data bytes
; Refer to the source code for details.

; Version History:
; ----------------

; Version 2.3 February 2009
; - Add slot scan for Apple /// computers

; Version 2.2 January 2008
; David Schmidt
; - Nibble disk send by Gerard Putter
; - Half track disk send by Eric Neilson 
; - Fix slot scan for IIc computers

; Version 1.33 July 2007
; David Schmidt
; - Support Laser 128-style serial port via Pascal
;   entry points

; Version 1.32 June 2007
; David Schmidt
; - Scan slots for initial/default comms device
; - Managed interrupt disabling/enabling correctly

; Version 1.31 December 2006
; David Schmidt
; - Added self-save feature, removed BASIC configuration
; - Included bug fixes from Joe Oswald:
;   . Mask interrupts
;   . Recover from host NAKs

; Version 1.30 November 2006 - Only released with ADTPro
; David Schmidt
; - Added native IIgs (Zilog SCC) support

; Version 1.23 November 2005
; Knut Roll-Lund and Ed Eastman
; - Added 115200b rate for SSC card
; - Added additional baud rates to
;   Windows and DOS verisons
; - added buffering to DIR handling
;   so it works on higher baudrates

; Version 1.22 CHANGES "ABOUT" MSG

; Version 1.21 FILLS UNREADABLE SECTORS WITH ZEROS

; Version 1.20
; - HAS A CONFIGURATION MENU
; - HAS A DIRECTORY FUNCTION
; - ABORTS INSTANTLY IF USER PUSHES ESCAPE
; - FIXES THE "256 RETRIES" BUG
; - HAS MORE EFFICIENT CRC ROUTINES

; Version 1.11 SETS IOBVOL TO 0 BEFORE CALLING RWTS

; Version 1.10 ADDS THESE ENHANCEMENTS:
; - DIFFERENTIAL RLE COMPRESSION TO SPEED UP TRANSFER
; - 16-BIT CRC ERROR DETECTION
; - AUTOMATIC RE-READS OF BAD SECTORS

; Version 1.01 CORRECTS THE FOLLOWING BUGS:
; - INITIALIZATION ROUTINE CRASHED WITH SOME CARDS
; - FULL 8.3 MS-DOS FILENAMES NOW ACCEPTED

; Version 1.00 - FIRST PUBLIC RELEASE

; The version number as a macro. Must not be more than 7 characters.
.define		version_no	"2.3"

; Protocol number. Note it must be assigned a higher value when the protcol is
; modified, and must never be < $0101 or > $01FF
protono		= $0101

; CONSTANTS

esc		= $9b		; ESCAPE KEY
ack		= $06		; ACKNOWLEDGE
nak		= $15		; NEGATIVE ACKNOWLEDGE
parmnum 	= 9		; NUMBER OF CONFIGURABLE PARMS
nibpages	= $34		; Number of nibble pages to send
enq		= $05		; Request to re-read track
can		= $18		; Track not accepted at host

; ZERO PAGE LOCATIONS (ALL UNUSED BY DOS, BASIC & MONITOR)

msgptr		= $6		; POINTER TO MESSAGE TEXT (2B)
secptr		= $8		; POINTER TO SECTOR DATA  (2B)

nibptr		= $8		; Pointer to nibble data  (2B)
hlftrk		= $18		; Half track send enabled (1B)
nibpcnt		= $1e		; Counts nibble pages     (1B)
trkcnt		= $1e		; COUNTS SEVEN TRACKS     (1B)
synccnt		= $eb		; Count bytes during sync (2B)
crc		= $eb		; TRACK CRC-16            (2B)
prev		= $ed		; PREVIOUS BYTE FOR RLE   (1B)
ysave		= $ee		; TEMP STORAGE            (1B)
xsave		= $ef		; Temp storage for X reg  (1B)

; BIG FILES

tracks		= $2000		; 7 TRACKS AT 2000-8FFF (28KB)
crctbll		= $9000		; CRC LOW TABLE         (256B)
crctblh		= $9100		; CRC HIGH TABLE        (256B)

; MONITOR STUFF
	
ch		= $24		; CURSOR HORIZONTAL POSITION
cv		= $25		; CURSOR VERTICAL POSITION
basl		= $28		; BASE LINE ADDRESS
invflg		= $32		; INVERSE FLAG
clreol		= $fc9c		; CLEAR TO END OF LINE
clreop		= $fc42		; CLEAR TO END OF SCREEN
home		= $fc58		; CLEAR WHOLE SCREEN
tabv		= $fb5b		; SET BASL FROM A
vtab		= $fc22		; SET BASL FROM CV
rdkey		= $fd0c		; CHARACTER INPUT
nxtchar		= $fd75		; LINE INPUT
cout		= $fded		; Monitor output
cout1		= $fdf0		; CHARACTER OUTPUT
crout		= $fd8e		; OUTPUT RETURN

; MESSAGES. These numbers are byte offsets into msgtbl

mtitle		= 0		; TITLE SCREEN
mconfig		= 2		; CONFIGURATION TOP OF SCREEN
mconfg2		= 4		; CONFIGURATION BOTTOM OF SCREEN
mprompt		= 6		; MAIN PROMPT
mdircon		= 8		; CONTINUED DIRECTORY PROMPT
mdirend		= 10		; END OF DIRECTORY PROMPT
mfrecv		= 12		; FILE TO RECEIVE:_
mfsend		= 14		; FILE TO SEND:_
mrecv		= 16		; RECEIVING FILE_    (_ = SPACE)
msend		= 18		; SENDING FILE_
mconfus		= 20		; NONSENSE FROM HOST
mnot16		= 22		; NOT A 16 SECTOR DISK
merror		= 24		; ERROR: FILE_
mcant		= 26		; |CAN'T BE OPENED.     (| = CR)
mexists		= 28		; |ALREADY EXISTS.
mnot140		= 30		; |IS NOT A 140K IMAGE.
mfull		= 32		; |DOESN'T FIT ON DISK.
manykey		= 34		; __ANY KEY:_
mdont		= 36		; <- DO NOT CHANGE
mabout		= 38		; ABOUT ADT...
mtest		= 40		; TESTING DISK FORMAT
mpcans		= 42		; AWAITING ANSWER FROM HOST
mpause		= 44		; HIT ANY KEY TO CONTINUE...
mdoserr		= 46		; DOS ERROR:_
mdos0a		= 48		; FILE LOCKED
mdos04		= 50		; WRITE PROTECTED
mdos08		= 52		; I/O ERROR
mnibsend	= 54		; Sending nibble file_
mnodiskc	= 56		; Slot has no disk card
manalys		= 58		; Host could not analyze the disk
mhlfsend	= 60		; Sending halftrack/nibble file
msendtype	= 62		; Type of send
mproterr	= 64		; Incompatible host

;*********************************************************

	.ORG	$803

jmp start			; Skip early stuff
; Next few functions contain loops that must be within a
; page for correct timing, so place them at the start.
;---------------------------------------------------------
; calibrat - calibrate the disk arm to track #0
; the code is essentially like in the disk ii card
;---------------------------------------------------------
calibrat:
	jsr	slot2x		; a = x = slot * 16
	sta	xsave		; store slot * 16 in memory
	lda	$c08e,x		; prepare latch for input
	lda	$c08c,x		; strobe data latch for i/o
	lda	pdrive		; is 0 for drive 1
	beq	caldriv1
	inx
caldriv1:
	lda	$c08a,x		; engage drive 1 or 2
	lda	xsave
	tax			; restore x
	lda	$c089,x		; motor on
	ldy	#$50		; number of half-tracks
caldriv3:
	lda	$c080,x		; stepper motor phase n off
	tya
	and	#$03		; make phase from count in y
	asl			; times 2
	ora	xsave		; make index for i/o address
	tax
	lda	$c081,x		; stepper motor phase n on
	lda	#$56		; param for wait loop
	jsr	$fca8		; wait specified time units
	dey			; decrement count
	bpl	caldriv3	; jump back while y >= 0
	rts

;---------------------------------------------------------
; rdnibtr - read track as nibbles into tracks buffer.
; total bytes read is nibpages * 256, or about twice
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
	sta	nibptr		; set running ptr (lo) to 0
	lda	#>tracks	; tracks address high
	sta	nibptr+1	; set running ptr (hi)
	lda	#nibpages
	sta	nibpcnt		; page counter
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
	sta	(nibptr),y	; store in buffer (6c)
	iny			; (2c)
	bne	rdnibtr7	; 256 bytes done? (2 / 3c)
	inc	nibptr+1	; next page (5c)
	dec	nibpcnt		; count (5c)
	bne	rdnibtr7	; and back (3c)
	rts

;---------------------------------------------------------
; seekabs - copy of standard dos seekabs at b9a0.
; by copying it we are independent on the dos version, 
; while still avoiding rwts in the nibble copy function.
; on entry, x is slot * 16; a is desired half-track;
; $478 is current half-track
;---------------------------------------------------------
seekabs:
	stx	$2b
	sta	$2a
	cmp	$0478
	beq	seekabs9
	lda	#$00
	sta	$26
seekabs1:
	lda	$0478
	sta	$27
	sec
	sbc	$2a
	beq	seekabs6
	bcs	seekabs2
	eor	#$ff
	inc	$0478
	bcc	seekabs3
seekabs2:
	adc	#$fe
	dec	$0478
seekabs3:
	cmp	$26
	bcc	seekabs4
	lda	$26
seekabs4:
	cmp	#$0c
	bcs	seekabs5
	tay   
seekabs5:
	sec   
	jsr	seekabs7
	lda	delaytb1,y
	jsr	armdelay
	lda	$27
	clc
	jsr	seekabs8
	lda	delaytb2,y
	jsr	armdelay
	inc	$26
	bne	seekabs1
seekabs6:
	jsr	armdelay
	clc
seekabs7:
	lda	$0478
seekabs8:
	and	#$03
	rol
	ora	$2b
	tax
	lda	$c080,x
	ldx	$2b
seekabs9:
	rts

;---------------------------------------------------------
; armdelay - copy of standard dos armdelay at $ba00
;---------------------------------------------------------
armdelay:
	ldx	#$11
armdela1:
	dex
	bne	armdela1
	inc	$46
	bne	armdela3
	inc	$47
armdela3:
	sec
	sbc	#$01
	bne	armdelay
	rts

;---------------------------------------------------------
; next are two tables used in the arm movements. they must
; also lie in one page.
;---------------------------------------------------------
delaytb1:
	.byte $01,$30,$28,$24,$20,$1e 
	.byte $1d,$1c,$1c,$1c,$1c,$1c

delaytb2:
	.byte $70,$2c,$26,$22,$1f,$1e
	.byte $1d,$1c,$1c,$1c,$1c,$1c

; End of the page-bound stuff.

;---------------------------------------------------------
; START - MAIN PROGRAM
;---------------------------------------------------------
start:
	sei			; Turn off interrupts
	cld			; Binary mode
	jsr	$fe84		; Normal text
	jsr	$fb2f		; Text mode, full window
	jsr	$fe89		; Input from keyboard
	lda	#$15
	jsr	cout		; Switch to 40 columns
	lda	#$00
	sta	secptr		; secptr is always page-aligned
	sta	stddos		; Assume standard DOS initially
	sta	hlftrk		; Init hlftrk global to zero
	lda	$b92e		; Save contents of DOS
	sta	dosbyte		; Checksum bytes
	cmp	#$13
	beq	dosok1		; Decrement stddos (making
	dec	stddos		; it non-zero) if the correct
dosok1: lda	$b98a		; bytes aren't there
	sta	dosbyte+1
	cmp	#$b7
	beq	dosok2
	dec	stddos
dosok2:
	jsr	maketbl		; MAKE CRC-16 TABLES
	jsr	parmdft		; RESET PARAMETERS TO DEFAULTS
	jsr	parmint		; INTERPRET PARAMETERS

redraw: jsr	title		; DRAW TITLE SCREEN

mainlup:
	lda	#0		; Turn hlftrk flag back off
	sta	hlftrk
	ldy	#mprompt	; SHOW MAIN PROMPT
mainl:
resetio:
	jsr	$0000		; Pseudo-indirect JSR to reset the IO device
	jsr	showmsg		; AT BOTTOM OF SCREEN
	jsr	rdkey		; GET ANSWER
	and	#$df		; CONVERT TO UPPERCASE

	cmp	#_'S'		; SEND?
	bne	krecv		; Nope, try receive
	ldy	#msendtype
	jsr	showmsg
sendtype:
	jsr	rdkey		; GET ANSWER
	and	#$df		; CONVERT TO UPPERCASE
	cmp	#_'H'		; Half?
	bne	:+
	lda	#1		; set hlftrk flag on
	sta	hlftrk
	jsr	sendhlf		; yes, do halftrack/nib send
	jmp	redraw		; changed the screen, so restore
:
	cmp	#_'N'		; Nibble?	
	bne	:+
	jsr	sendnib		; yes, do send nibble disk
	jmp	redraw		; changed the screen, so restore
:
	cmp	#_'S'		; SEND?
	bne	:+		; Nope, invalid input
	jsr	send		; YES, DO SEND ROUTINE
:
	cmp	#esc
	beq	mainlup
	jmp	sendtype

krecv:	cmp	#_'R'		; RECEIVE?
	bne	kdir		; NOPE, TRY DIR
	jsr	receive		; YES, DO RECEIVE ROUTINE
	jmp	mainlup

kdir:	cmp	#_'D'		; DIR?
	bne	kconf		; NOPE, TRY CONFIGURE
	jsr	dir		; YES, DO DIR ROUTINE
	jmp	redraw

kconf:	cmp	#_'C'		; CONFIGURE?
	beq	:+
	cmp	#_'G'		; Yeah, so, G is as good as C.
	bne	kabout		; NOPE, TRY ABOUT
:	jsr	config		; YES, DO CONFIGURE ROUTINE
	jsr	parmint		; AND INTERPRET PARAMETERS
	jmp	redraw

kabout: cmp	#$9f		; ABOUT MESSAGE? ("?" KEY)
	bne	kquit		; NOPE, TRY QUIT
	jsr home
	ldy	#mabout		; YES, SHOW MESSAGE, WAIT
	jsr	showm1		; FOR KEY, AND RETURN
	jsr	rdkey
	jmp	redraw

kquit:	cmp	#_'Q'		; QUIT?
	bne	mainlup		; NOPE, WAS A BAD KEY
	lda	dosbyte		; YES, RESTORE DOS CHECKSUM CODE
	sta	$b92e
	lda	dosbyte+1
	sta	$b98a
	cli			; Restore interrupts
	jsr	home		; Clear screen
	jmp	$3d0		; AND QUIT TO DOS


;---------------------------------------------------------
; DIR - GET DIRECTORY FROM THE HOST AND PRINT IT
; HOST SENDS 0,1 AFTER PAGES 1..N-1, 0,0 AFTER LAST PAGE
;---------------------------------------------------------
dir:
	ldy	#mpcans
	jsr	showmsg
	lda	#_'D'		; SEND DIR COMMAND TO HOST
	jsr	putc

	lda	#>tracks	; GET BUFFER POINTER HIGHBYTE
	sta	secptr+1	; SET SECTOR BUFFER POINTER
	ldy	#0		; COUNTER
dirbuff:
	jsr	getc		; GET SERIAL CHARACTER
	php			; SAVE FLAGS
	sta	(secptr),y	; STORE BYTE
	iny			; BUMP
	bne	dirnext		; SKIP
	inc	secptr+1	; NEXT 256 BYTES
dirnext:
	plp			; RESTORE FLAGS
	bne	dirbuff		; LOOP UNTIL ZERO

	jsr	getc		; GET CONTINUATION CHARACTER
	sta	(secptr),y	; STORE CONTINUATION BYTE TOO
	jsr	home		; CLEAR SCREEN

	lda	#>tracks	; GET BUFFER POINTER HIGHBYTE
	sta	secptr+1	; SET SECTOR BUFFER POINTER
	ldy	#0		; COUNTER
dirdisp:
	lda	(secptr),y	; GET BYTE FROM BUFFER
	php			; SAVE FLAGS
	iny			; BUMP
	bne	dirmore		; SKIP
	inc	secptr+1	; NEXT 256 BYTES
dirmore:
	plp			; RESTORE FLAGS
	beq	dirpage		; PAGE OR DIR END
	ora	#$80
	jsr	cout1		; DISPLAY
	jmp	dirdisp		; LOOP

dirpage:
	lda	(secptr),y	; GET BYTE FROM BUFFER
	bne	dircont

	ldy	#mdirend	; NO MORE FILES, WAIT FOR KEY
	jsr	showmsg		; AND RETURN
	jsr	rdkey
	rts

dircont:
	ldy	#mdircon	; SPACE TO CONTINUE, ESC TO STOP
	jsr	showmsg
	jsr	rdkey
	eor	#esc		; NOT ESCAPE, CONTINUE NORMALLY
	bne	dir		; BY SENDING A "D" TO HOST
	jmp	putc		; ESCAPE, SEND 00 AND RETURN

;---------------------------------------------------------
; FindSlot - Find a comms device
;---------------------------------------------------------
FindSlot:
	lda	#$00
	sta	msgptr		; Borrow msgptr
	sta	TempSlot
	sta	TempIIgsSlot
	ldx	#$07		; Slot number - start high
FindSlotLoop:
	clc
	txa
	adc	#$c0
	sta	msgptr+1
	ldy	#$05		; Lookup offset
	lda	(msgptr),y
	cmp	#$38		; Is $Cn05 == $38?
	bne	FindSlotNext
	ldy	#$07		; Lookup offset
	lda	(msgptr),y
	cmp	#$18		; Is $Cn07 == $18?
	bne	FindSlotNext
	ldy	#$0b		; Lookup offset
	lda	(msgptr),y
	cmp	#$01		; Is $Cn0B == $01?
	bne	FindSlotMaybeIII
	ldy	#$0c		; Lookup offset
	lda	(msgptr),y
	cmp	#$31		; Is $Cn0C == $31?
	bne	FindSlotNext
; Ok, we have a set of signature bytes for a comms card (or IIc/IIgs, or Laser).
; Remove more specific models/situations first.
	ldy	#$1b		; Lookup offset
	lda	(msgptr),y
	cmp	#$eb		; Do we have a goofy XBA instruction in $C01B?
	bne	FoundNotIIgs	; If not, it's not an IIgs.
	cpx	#$02		; Only bothering to check IIgs Modem slot (2)
	bne	FindSlotNext
	lda	#$07		; We found the IIgs modem port, so store it
	sta	TempIIgsSlot
	jmp	FindSlotNext
FoundNotIIgs:
	ldy	#$00
	lda	(msgptr),y
	cmp	#$da		; Is $Cn00 == $DA?
	bne	NotLaser	; If not, it's not a Laser 128.
	cpx	#$02
	bne	FindSlotNext
	lda	#$09		; Ok, this is a Laser 128.
	sta	TempSlot
	lda	pspeed		; Were we trying to go too fast (115.2k)?
	cmp	#$06
	bne	:+
	lda	#$05		; Yes, slow it down to 19200.
	sta	pspeed
	sta	default+3	; And make that the default.
:
	jmp	FindSlotNext
NotLaser:
	ldy	#$0a
	lda	(msgptr),y
	cmp	#$0e		; Is this a newer IIc - $Cn0a == $0E?
	beq	ProcessIIc
NotNewIIc:
	cmp	#$25		; Is this an older IIc - $Cn0a == $25?
	bne	GenericSSC
ProcessIIc:
	cpx	#$02		; Only bothering to check IIc Modem slot (2)
	bne	FindSlotNext
	stx	TempSlot
	jmp	FindSlotBreak	; Don't check port #1 on an IIc - we don't care
GenericSSC:
	stx	TempSlot	; Nope, nothing special.  Just a Super Serial card.

FindSlotNext:
	dex
	bne	FindSlotLoop
; All done now, so clean up
FindSlotBreak:
	ldx	TempSlot
	beq	:+
	dex			; Subtract 1 to match slot# to parm index
	stx	pssc
	stx	default+2	; Store the slot number discovered as default
	rts
:	lda	TempIIgsSlot
	beq	FindSlotDone	; Didn't find anything in particular
	sta	pssc
	sta	default+2	; Store the slot number discovered as default
FindSlotDone:
	rts

FindSlotMaybeIII:
	cmp	#$08		; Is $Cn0B == $08?
	bne	FindSlotNext
	ldy	#$0c		; Lookup offset
	lda	(msgptr),y
	cmp	#$48		; Is $Cn0C == $48?
	bne	FindSlotNext
	jmp	GenericSSC	; It's an Apple /// SSC-like thing.

TempSlot:	.byte 0
TempIIgsSlot:	.byte 0

;---------------------------------------------------------
; CONFIG - ADT CONFIGURATION
;---------------------------------------------------------
config:
	jsr	home		; CLEAR SCREEN
				; No matter what, we put in the default value for 
				; 'save' - always turn it off when showing the config screen.
	lda	#$01		; Index for 'NO' save
	sta	psave
	ldy	#mconfig	; SHOW CONFIGURATION SCREEN
	jsr	showm1
	ldy	#mconfg2
	jsr	showmsg		; IN 2 PARTS BECAUSE >256 CHARS

	ldy	#parmnum-1	; SAVE PREVIOUS PARAMETERS
savparm:
	lda	parms,y		; IN CASE OF ESCAPE
	sta	oldparm,y
	dey
	bpl	savparm

;--------------- FIRST PART: DISPLAY SCREEN --------------

refresh:
	lda	pssc
	cmp	#$08		; Are we talking about the Laser/Pascal Entry Points?
	bmi	restore		; No, go on ahead
	lda	pspeed		; Yes - so check baudrate
	cmp	#$06		; Is it too fast?
	bne	refnext		; No, go on ahead
	sta	svspeed
	lda	#$05		; Yes - so slow it down
	sta	pspeed
	jmp	refnext 
restore:
	lda	svspeed		; Did we have speed previously re-set by Laser?
	beq	refnext		; No, go on ahead
	sta	pspeed		; Yes - so restore it now
	lda	#$00
	sta	svspeed		; Forget about resetting speed until we roll through Laser again
refnext:
	lda	#3		; FIRST PARAMETER IS ON LINE 3
	jsr	tabv
	ldx	#0		; PARAMETER NUMBER
	ldy	#$ff		; OFFSET INTO PARAMETER TEXT

nxtline:
	stx	linecnt		; SAVE CURRENT LINE
	lda	#15
	sta	ch
	clc
	lda	parmsiz,x	; GET CURRENT VALUE (NEGATIVE:
	sbc	parms,x		; LAST VALUE HAS CURVAL=0)
	sta	curval
	lda	parmsiz,x	; X WILL BE EACH POSSIBLE VALUE
	tax			; STARTING WITH THE LAST ONE
	dex

valloop:
	cpx	curval		; X EQUAL TO CURRENT VALUE?
	beq	printit		; YES, PRINT IT
skipchr:
	iny			; NO, SKIP IT
	lda	parmtxt,y
	bne	skipchr
	beq	endval

printit:
	lda	linecnt		; IF WE'RE ON THE ACTIVE LINE,
	cmp	curparm		; THEN PRINT VALUE IN INVERSE
	bne	prtval		; ELSE PRINT IT NORMALLY
	lda	#$3f
	sta	invflg

prtval: lda	#$a0		; SPACE BEFORE & AFTER VALUE
	jsr	cout1
prtloop:
	iny			; PRINT VALUE
	lda	parmtxt,y
	beq	endprt
	jsr	cout1
	jmp	prtloop
endprt: lda	#$a0
	jsr	cout1
	lda	#$ff		; BACK TO NORMAL
	sta	invflg
endval: dex
	bpl	valloop		; PRINT REMAINING VALUES
	sty	ysave		; CLREOL USES Y
	jsr	clreol		; REMOVE GARBAGE AT EOL

	lda	#$a0		; Add an extra space to output
	jsr	cout		; Without it, the crout will
	jsr	crout		; sometimes cause the disk to
				; spin!  Strange but true!

	ldy	ysave
	ldx	linecnt		; INCREMENT CURRENT LINE
	inx
	cpx	#parmnum
	bcc	nxtline		; Loop parmnum times

	lda	stddos		; IF NON-STANDARD DOS, WRITE
	beq	getcmd		;"DO NOT CHANGE" ON SCREEN
	lda	#9		; NEXT TO THE CHECKSUMS OPTION
	jsr	tabv
	ldy	#23
	sty	ch
	ldy	#mdont
	jsr	showm1

;--------------- SECOND PART: CHANGE VALUES --------------

getcmd: lda	$c000		; Wait for next command
	bpl	getcmd
	bit	$c010
	ldx	curparm		; Current parameter in X

	cmp	#$88
	bne	notleft
	dec	parms,x		; Left arrow hit
	bpl	leftok		; Decrement current value
	lda	parmsiz,x
	sbc	#1
	sta	parms,x
leftok: jmp	refresh

notleft:
	cmp	#$95
	bne	notrgt
	lda	parms,x		; Right arrow hit
	adc	#0		; Increment current value
	cmp	parmsiz,x
	bcc	rightok
	lda	#0
rightok:
	sta	parms,x
	jmp	refresh

notrgt: cmp	#$8b
	bne	notup
	dex			; Up arrow hit
	bpl	upok		; Decrement parameter
	ldx	#parmnum-1
upok:	stx	curparm
	jmp	refresh

notup:	cmp	#$8a
	beq	isdown
	cmp	#$a0
	bne	notdown
isdown: inx			; Down arrow or space hit
	cpx	#parmnum	; Increment parameter
	bcc	downok
	ldx	#0
downok: stx	curparm
	jmp	refresh

notdown:
	cmp	#$84
	bne	notctld
	jsr	parmdft		; Ctrl-D pushed, restore default
notesc: jmp	refresh		; parameters

notctld:
	cmp	#$8d
	beq	endcfg		; Return hit, stop configuration

	cmp	#esc
	bne	notesc
	ldy	#parmnum-1	; Escape pushed; restore old
parmrst:
	lda	oldparm,y	; parameters and continue
	sta	parms,y
	dey
	bpl	parmrst
endcfg:
	jsr	chekslot	; Verify if slot has disk card
	bcs	getcmd		; Don't accept slot

	lda	#$01
	sta	configyet
	lda	psave		; Did they ask to save parms?
	bne	nosave

	lda	#$01		; Index for 'NO' save
	sta	psave

	ldy	#parmnum-1	; Save previous parameters
savparm2:
	lda	parms,y
	sta	default,y
	dey
	bpl	savparm2
	lda	#$00
	sta	curparm
	jsr	bsave
nosave:
	rts

linecnt:
	.byte	$00		; Current line number
curparm:
	.byte	$00		; Active parameter
curval: .byte	$00		; Value of active parameter
default:
	.byte	5,0,1,6,1,0,0,0,1 ; DEFAULT PARM VALUES
oldparm:
	.res	parmnum		; Old parameters saved here
svspeed:
	.byte	$06		; Storage for speed setting

;---------------------------------------------------------
; bsave - Save a copy of ADT in memory
;---------------------------------------------------------
bsave:
	lda	length+1	; Convert 16-bit length to a hex string
	pha
	jsr	tochrhi		; Hi nybble, hi byte
	sta	nybble1
	pla
	jsr	tochrlo		; Lo nybble, hi byte
	sta	nybble2
	lda	length
	pha
	jsr	tochrhi		; Hi nybble, lo byte
	sta	nybble3
	pla
	jsr	tochrlo		; Lo nybble, lo byte
	sta	nybble4

patch:				; Patch in our "error handler:"
	lda	#$85		; It saves the DOS error code in $DE
	sta	$A6D2
	lda	#$DE		; sta $DE
	sta	$A6D3
	lda	#$60		; rts - return from error
	sta	$A6D4

	ldx	#$00
	stx	$DE

cmdloop:			; Send BSAVE command to DOS
	lda	command,X
	beq	:+
	jsr	cout
	inx
	jmp	cmdloop
:
	lda	$DE		; Everything cool?
	beq	bsavedone	; All done
err:
	ldy	#mdoserr
	jsr	showm1
	cmp	#$0a		; File locked?
	bne	:+
	ldy	#mdos0a
	jmp	ermsg
:	cmp	#$04		; Write protected?
	bne	:+
	ldy	#mdos04
	jmp	ermsg
:	ldy	#mdos08		; Catch-all: I/O error
ermsg:	jsr	showm1

bsavedone:
	jsr	pause
	rts

;---------------------------------------------------------
; tochrlo/hi:
; Convert a nybble in A to a character representing its
; hex value, returned in A
;---------------------------------------------------------
tochrlo:
	and	#$0f
	jmp	tochrgo
tochrhi:
	lsr
	lsr
	lsr
	lsr
tochrgo:
	clc
	cmp	#$09
	bcc	gt9		; A is greater than 9
	adc	#$B6
	jmp	tochrdone
gt9:
	ora	#$B0
tochrdone:
	rts

command:
	.byte $8d,$84
	asc "BSAVE ADT,A$0803,L$"
nybble1:
	.byte $00
nybble2:
	.byte $00
nybble3:
	.byte $00
nybble4:
	.byte $00
	.byte $8D,$00
length:	.word endasm-start

;---------------------------------------------------------
; PAUSE - print 'PRESS A KEY TO CONTINUE...' and wait
;---------------------------------------------------------
pause:
	lda	#$00
	sta	ch
	lda	#$17
	jsr	tabv
	jsr	clreop
	ldy	#mpause
	jsr	showmsg
	jsr	rdkey
	cmp	#$9B
	beq	pauseesc
	clc
	rts
pauseesc:
	sec
	rts

;---------------------------------------------------------
; checkslot - see if chosen slot has a disk card
; the check is identical to what is in the autoboot rom
;---------------------------------------------------------
chekslot:
	ldy	pdslot		;get slot# (0..6)
	iny			;now 1..7
	tya
	ora	#$c0		;a now has page address of slot
	sta	secptr+1	;abuse this pointer
	lda	#0
	sta	secptr		;secptr now points to firmware
	ldy	#7
checksl1:
	lda	(secptr),y	;get firmware byte
	cmp	diskid-1,y	;byte ok?
	bne	checksl3	;no: report error
	dey
	dey
	bpl	checksl1	;until 4 bytes checked
	bmi	checksl7	;jump always
checksl3:
	jsr	awbeep
	ldy	#mnodiskc	;error message number
	jsr	showmsg		;and show message
checksl5: 
	jsr	rdkey		;get answer
	and	#$df		;convert to uppercase
	cmp	#'Y'
	beq	checksl7	;user agrees
	cmp	#'N'
	bne	checksl5	;wrong answer
	ldy	#mconfg2
	jsr	showmsg		;restore default text
	sec			;indicate error
	rts
checksl7:
	clc			;indicate: no error
checksl9:
	rts

; Define diskid ourselves, to be independent of ROM
diskid:	.byte $20,$ff,$00,$ff,$03,$ff,$3c

;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
parmint:
	ldy	pdslot		; GET SLOT# (0..6)
	iny			; NOW 1..7
	tya
	ora	#_'0'		; CONVERT TO ASCII AND PUT
	sta	mtslt		; INTO TITLE SCREEN
	tya
	asl
	asl
	asl
	asl			; NOW $S0
	sta	iobslt		; STORE IN IOB
	adc	#$89		; NOW $89+S0
	sta	mod5+1		; SELF-MOD FOR "DRIVES ON"

	ldy	pdrive		; GET DRIVE# (0..1)
	iny			; NOW 1..2
	sty	iobdrv		; STORE IN IOB
	tya
	ora	#_'0'		; CONVERT TO ASCII AND PUT
	sta	mtdrv		; INTO TITLE SCREEN

	ldy	pssc		; GET SSC SLOT# (0..6)
	iny			; NOW 1..7
	tya
	ora	#_'0'		; CONVERT TO ASCII AND PUT
	sta	mtssc		; INTO TITLE SCREEN
	tya
	asl
	asl
	asl
	asl			; NOW $S0
	adc	#$88
	tax
	ldy	pspeed		; CONTROL: 8 DATA BITS, 1 STOP
	tya			; GET SPEED (0..6)
	asl
	asl
	adc	pspeed		; 6*SPEED IN Y, NOW COPY
	tay			; FIVE CHARACTERS INTO
	ldx	#4		; TITLE SCREEN
putspd: lda	spdtxt,y
	sta	mtspd,x
	iny
	dex
	bpl	putspd

	ldy	#1		; CONVERT RETRIES FROM 0..7
trylup: ldx	pretry,y	; TO 0..5,10,128
	lda	trytbl,x
	sta	realtry,y
	dey
	bpl	trylup

	ldx	#0		; IF PCKSUM IS 'NO', WE PATCH
	ldy	#0		; DOS TO IGNORE ADDRESS AND
	lda	pcksum		; DATA CHECKSUM ERRORS
	bne	rwtsmod
	ldx	dosbyte+1
	ldy	dosbyte
rwtsmod:
	stx	$b98a		; IS THERE AN APPLE II TODAY
	sty	$b92e		; THAT DOESN'T HAVE >=48K RAM?
				;(YES)
	ldy	pssc		; GET SLOT# (0..6)
	iny			; NOW 1..7
	tya
	cmp	#$08
	bpl	drivers
	jmp	initssc		; Y holds slot number
drivers:
	cmp	#$09
	bpl	laser
	jmp	initzgs
laser:
	jmp	initpas
	rts

spdtxt: asc	"  003 0021 0042 0084 006900291 K511"
bpsctrl:
	.byte	$16,$18,$1a,$1c,$1e,$1f,$10
trytbl: .byte	0,1,2,3,4,5,10,99

;---------------------------------------------------------
; GETNAME - GET FILENAME AND SEND TO HOST
; When an acceptable file name has been entered, the function
; sends the command letter to the host.
; This function also does the protocol negotiation, because
; that has to happen after sending the command letter.
; When the host accepts the protocol, the function sends
; the entered file name and waits for the host's response.
;---------------------------------------------------------
getname:
	stx	directn		; TFR DIRECTION (0=RECV, 1=SEND)
	ldy	prmptbl,x
	jsr	showmsg		; ASK FILENAME
	ldx	#0		; GET ANSWER AT $200
	jsr	nxtchar
	lda	#0		; NULL-TERMINATE IT
	sta	$200,x
	txa
	bne	fnameok
	jmp	abort		; ABORT IF NO FILENAME

fnameok:
	ldy	#mtest		;"TESTING THE DISK"
	jsr	showmsg
	lda	#>tracks	; READ TRACK 1 SECTOR 1
	sta	iobbuf+1	; TO SEE IF THERE'S A 16-SECTOR
	lda	#1		; DISK IN THE DRIVE
	sta	iobcmd
	sta	iobtrk
	sta	iobsec
	lda	#>iob
	ldy	#<iob
	jsr	$3d9
	bcc	diskok		; READ SUCCESSFUL

	ldy	#mnot16		; NOT 16-SECTOR DISK
	jsr	showmsg
	ldy	#manykey	; APPEND PROMPT
	jsr	showm1
	jsr	awbeep
	jsr	rdkey		; WAIT FOR KEY
	jmp	abort		; AND ABORT

diskok: ldy	#mpcans		;"AWAITING ANSWER FROM HOST"
	jsr	showmsg
	lda	#_'R'		; LOAD ACC WITH "R" OR "S"
	adc	directn		; Rather tricky way to change R into S.
	jsr	putc		; AND SEND TO HOST
	jsr	initprot
	bcc	:+		; Protocol accepted
	jmp	abort		; Exit via abort
:	ldx	#0
fnloop: lda	$200,x		; SEND FILENAME TO HOST
	jsr	putc
	beq	getans		; STOP AT NULL
	inx
	bne	fnloop

getans: jsr	getc		; ANSWER FROM HOST SHOULD BE 0
	bne	pcerror		; THERE'S A PROBLEM

	jsr	title		; CLEAR STATUS
	ldx	directn
	ldy	tfrtbl,x
	jsr	showmsg		; SHOW TRANSFER MESSAGE

showfn: lda	#2		; AND ADD FILENAME
	sta	msgptr+1
	lda	#0
	sta	msgptr
	tay
	jmp	msgloop		; AND RETURN THROUGH SHOWMSG

pcerror:
	pha			; SAVE ERROR NUMBER
	ldy	#merror		; SHOW "ERROR: FILE "
	jsr	showmsg		; SHOW FILENAME
	jsr	showfn
	pla
	tay
	jsr	showm1		; SHOW ERROR MESSAGE
	ldy	#manykey	; APPEND PROMPT
	jsr	showm1
	jsr	awbeep
	jsr	rdkey		; WAIT FOR KEY
	jmp	abort		; AND RESTART

directn:
	.byte	$00
prmptbl:
	.byte	mfrecv,mfsend
tfrtbl: .byte	mrecv,msend

;---------------------------------------------------------
; initprot - Negotiate the protocol. Return carry clear
; if successful, carry set otherwise. Displays an error
; message if the host does not accept the protocol.
;---------------------------------------------------------
initprot:
	lda	#>protono	; High order byte
	jsr	putc		; Send to host
	lda	#<protono	; Low order byte
	jsr	putc		; Send to host
	lda	#0
	jsr	putc		; Delimiter
	jsr	getc		; Read response from host
	cmp	#ack
	bne	:+		; Not ack, so invalid protocol or host
	clc
	rts			; Exit with OK status
:	ldy	#mproterr	; Erroneous protocol negotiation
	jsr	showmsg		; Display appropriate error message
	jsr	awbeep		; This error deserves some attention
	jsr	rdkey		; Wait for key
	sec			; Error status
	rts

;---------------------------------------------------------
; RECEIVE - MAIN RECEIVE ROUTINE
;---------------------------------------------------------
receive:
	ldx	#0		; DIRECTION = HOST-->APPLE
	jsr	getname		; ASK FOR FILENAME & SEND TO HOST
	lda	#ack		; 1ST MESSAGE ALWAYS ACK
	sta	message
	lda	#0		; START ON TRACK 0
	sta	iobtrk
	sta	errors		; NO DISK ERRORS YET

recvlup:
	sta	savtrk		; SAVE CURRENT TRACK
	ldx	#1
	jsr	sr7trk		; RECEIVE 7 TRACKS FROM HOST
	ldx	#2
	jsr	rw7trk		; WRITE 7 TRACKS TO DISK
	lda	iobtrk
	cmp	#$23		; REPEAT UNTIL TRACK $23
	bcc	recvlup
	lda	message		; SEND LAST ACK
	jsr	putc
	lda	errors
	jsr	putc		; SEND ERROR FLAG TO HOST
	jmp	awbeep		; BEEP AND END


;---------------------------------------------------------
; SEND - MAIN SEND ROUTINE
;---------------------------------------------------------
send:
	ldx	#1		; DIRECTION = APPLE-->HOST
	jsr	getname		; ASK FOR FILENAME & SEND TO HOST
	lda	#ack		; SEND INITIAL ACK
	jsr	putc
	lda	#0		; START ON TRACK 0
	sta	iobtrk
	sta	errors		; NO DISK ERRORS YET

sendlup:
	sta	savtrk		; SAVE CURRENT TRACK
	ldx	#1
	jsr	rw7trk		; READ 7 TRACKS FROM DISK
	ldx	#0
	jsr	sr7trk		; SEND 7 TRACKS TO HOST
	lda	iobtrk
	cmp	#$23		; REPEAT UNTIL TRACK $23
	bcc	sendlup
	lda	errors
	jsr	putc		; SEND ERROR FLAG TO HOST
	jmp	awbeep		; BEEP AND END


;---------------------------------------------------------
; SR7TRK - SEND (X=0) OR RECEIVE (X=1) 7 TRACKS
;---------------------------------------------------------
sr7trk: stx	what2do		; X=0 FOR SEND, X=1 FOR RECEIVE
	lda	#7		; DO 7 TRACKS
	sta	trkcnt
	lda	#>tracks	; STARTING HERE
	sta	secptr+1
	jsr	homecur		; RESET CURSOR POSITION

s7trk:	lda	#$f		; COUNT SECTORS FROM F TO 0
	sta	iobsec
s7sec:	ldx	what2do		; PRINT STATUS CHARACTER
	lda	srchar,x
	jsr	chrover

	lda	what2do		; EXECUTE SEND OR RECEIVE
	bne	dorecv		; ROUTINE

;------------------------ SENDING ------------------------

	jsr	sendsec		; SEND CURRENT SECTOR
	lda	crc		; FOLLOWED BY CRC
	jsr	putc
	lda	crc+1
	jsr	putc
	jsr	getc		; GET RESPONSE FROM HOST
	cmp	#ack		; IS IT ACK?
	beq	srokay		; YES, ALL RIGHT
	cmp	#nak		; IS IT NAK?
	beq	s7sec		; YES, SEND AGAIN

	ldy	#mconfus	; SOMETHING IS WRONG
	jsr	showmsg		; TELL BAD NEWS
	ldy	#manykey	; APPEND PROMPT
	jsr	showm1
	jsr	awbeep
	jsr	rdkey		; WAIT FOR KEY
	jmp	abort		; AND ABORT

;----------------------- RECEIVING -----------------------

dorecv: ldy	#0		; CLEAR NEW SECTOR
	tya
clrloop:
	sta	(secptr),y
	iny
	bne	clrloop

	lda	message		; SEND RESULT OF PREV SECTOR
	jsr	putc
	jsr	recvsec		; RECEIVE SECTOR
	jsr	getc
	sta	pccrc		; AND CRC
	jsr	getc
	sta	pccrc+1
	jsr	undiff		; UNCOMPRESS SECTOR

	lda	crc		; CHECK RECEIVED CRC VS
	cmp	pccrc		; CALCULATED CRC
	bne	recverr
	lda	crc+1
	cmp	pccrc+1
	beq	srokay

recverr:
	lda	#nak		; CRC ERROR, ASK FOR RESEND
	sta	message
	bne	s7sec

;------------------ BACK TO COMMON LOOP ------------------

srokay:
	lda	#ack		; WAS SUCCESSFUL
	sta	message		; SEND ACK 
	jsr	chrrest		; RESTORE PREVIOUS STATUS CHAR
	inc	secptr+1	; NEXT SECTOR
	dec	iobsec
	bpl	s7sec		; TRACK NOT FINISHED
	lda	trkcnt
	cmp	#2		; STARTING LAST TRACK, TURN
	bne	notone		; DRIVE ON, EXCEPT IN THE LAST
	lda	savtrk		; BLOCK
	cmp	#$1c
	beq	notone
mod5:	bit	$c089

notone: dec	trkcnt
	beq	srend
	jmp	s7trk		; LOOP UNTIL 7 TRACKS DONE
srend:	rts

srchar: asc	"OI"		; STATUS CHARACTERS: OUT/IN
what2do:
	.byte	$00


;---------------------------------------------------------
; SENDSEC - SEND CURRENT SECTOR WITH RLE
; CRC IS COMPUTED BUT NOT SENT
;---------------------------------------------------------
sendsec:
	ldy	#0		; START AT FIRST BYTE
	sty	crc		; ZERO CRC
	sty	crc+1
	sty	prev		; NO PREVIOUS CHARACTER
ss1:	lda	(secptr),y	; GET BYTE TO SEND
	jsr	updcrc		; UPDATE CRC
	tax			; KEEP A COPY IN X
	sec			; SUBTRACT FROM PREVIOUS
	sbc	prev
	stx	prev		; SAVE PREVIOUS BYTE
	jsr	putc		; SEND DIFFERENCE
	beq	ss3		; WAS IT A ZERO?
	iny			; NO, DO NEXT BYTE
	bne	ss1		; LOOP IF MORE TO DO
	rts			; ELSE RETURN

ss2:	jsr	updcrc
ss3:	iny			; ANY MORE BYTES?
	beq	ss4		; NO, IT WAS 00 UP TO END
	lda	(secptr),y	; LOOK AT NEXT BYTE
	cmp	prev
	beq	ss2		; SAME AS BEFORE, CONTINUE
ss4:	tya			; DIFFERENCE NOT A ZERO
	jsr	putc		; SEND NEW ADDRESS
	bne	ss1		; AND GO BACK TO MAIN LOOP
	rts			; OR RETURN IF NO MORE BYTES


;---------------------------------------------------------
; RECVSEC - RECEIVE SECTOR WITH RLE (NO TIME TO UNDIFF)
;---------------------------------------------------------
recvsec:
	ldy	#0		; START AT BEGINNING OF BUFFER
rc1:	jsr	getc		; GET DIFFERENCE
	beq	rc2		; IF ZERO, GET NEW INDEX
	sta	(secptr),y	; ELSE PUT CHAR IN BUFFER
	iny			; AND INCREMENT INDEX
	bne	rc1		; LOOP IF NOT AT BUFFER END
	rts			; ELSE RETURN
rc2:	jsr	getc		; GET NEW INDEX
	tay			; IN Y REGISTER
	bne	rc1		; LOOP IF INDEX <> 0
	rts			; ELSE RETURN


;---------------------------------------------------------
; UNDIFF -  FINISH RLE DECOMPRESSION AND UPDATE CRC
;---------------------------------------------------------
undiff: ldy	#0
	sty	crc		; CLEAR CRC
	sty	crc+1
	sty	prev		; INITIAL BASE IS ZERO
udloop: lda	(secptr),y	; GET NEW DIFFERENCE
	clc
	adc	prev		; ADD TO BASE
	jsr	updcrc		; UPDATE CRC
	sta	prev		; THIS IS THE NEW BASE
	sta	(secptr),y	; STORE REAL BYTE
	iny
	bne	udloop		; REPEAT 256 TIMES
	rts


;---------------------------------------------------------
; RW7TRK - READ (X=1) OR WRITE (X=2) 7 TRACKS
; USES A,X,Y. IF ESCAPE, CALLS ABORT
;---------------------------------------------------------
rw7trk: stx	iobcmd		; X=1 FOR READ, X=2 FOR WRITE
	lda	#7		; COUNT 7 TRACKS
	sta	trkcnt
	lda	#>tracks	; START AT BEGINNING OF BUFFER
	sta	iobbuf+1
	jsr	homecur		; RESET CURSOR POSITION

nexttrk:
	lda	#$f		; START AT SECTOR F (READ IS
	sta	iobsec		; FASTER THIS WAY)
nextsec:
	ldx	iobcmd		; GET MAX RETRIES FROM
	lda	realtry-1,x	; PARAMETER DATA
	sta	retries
	lda	rwchar-1,x	; PRINT STATUS CHARACTER
	jsr	chrover

rwagain:
	lda	$c000		; CHECK KEYBOARD
	cmp	#esc		; ESCAPE PUSHED?
	bne	rwcont		; NO, CONTINUE
	jmp	babort		; YES, ABORT

rwcont: lda	#>iob		; GET IOB ADDRESS IN REGISTERS
	ldy	#<iob
	jsr	$3d9		; CALL RWTS THROUGH VECTOR
	lda	#_'.'		; CARRY CLEAR MEANS NO ERROR
	bcc	sectok		; NO ERROR: PUT . IN STATUS
	dec	retries		; ERROR: SOME PATIENCE LEFT?
	bpl	rwagain		; YES, TRY AGAIN
	rol	errors		; NO, SET ERRORS TO NONZERO
	jsr	clrsect		; FILL SECTOR WITH ZEROS
	lda	#_I'*'		; AND PUT INVERSE * IN STATUS

sectok: jsr	chradv		; PRINT SECTOR STATUS & ADVANCE
	inc	iobbuf+1	; NEXT PAGE IN BUFFER
	dec	iobsec		; NEXT SECTOR
	bpl	nextsec		; LOOP UNTIL END OF TRACK
	inc	iobtrk		; NEXT TRACK
	dec	trkcnt		; LOOP UNTIL 7 TRACKS DONE
	bne	nexttrk
	rts

rwchar: asc	"RW"		; STATUS CHARACTERS: READ/WRITE
retries:
	.byte	$00
realtry:
	.byte	$00,$00		; REAL NUMBER OF RETRIES


;---------------------------------------------------------
; CLRSECT - CLEAR CURRENT SECTOR
;---------------------------------------------------------
clrsect:
	lda	iobbuf+1	; POINT TO CORRECT SECTOR
	sta	csloop+2
	ldy	#0		; AND FILL 256 ZEROS
	tya
csloop: sta	$ff00,y
	iny
	bne	csloop
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
	jsr	nibtitle	; adjust screen
	jsr	initshlf	; ask for filename & send to pc
	jsr	nibblank	; clear progress to all blanks
	jsr	calibrat	; calibrate the disk

	lda	#ack		; send initial ack
	jsr	putc

	lda	#0		; don't actually use rwts...
	sta	iobtrk		;  ...so use this as just memory

shlfloop:
	lda	#_'R'
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
	jsr	putc		; send (no) error flag to pc
	jsr	motoroff	; we're finished with the drive
	jmp	awbeep		; beep and end

;---------------------------------------------------------
; initshlf - init send halftrack/nibble disk
; ask for a filename, then send "V" command and filename
; to the other side and await an acknowledgement.
; note we do not check for a valid disk in the drive;
; basically any disk will do. if there is no disk present,
; bad luck (behaves the same as when booting).
;---------------------------------------------------------
initshlf:
	ldy	#mfsend
	jsr	showmsg		; Ask for filename
	ldx	#0		; Get answer at $200
	jsr	nxtchar		; Input the line (Apple ROM)
	lda	#0		; Null-terminate it
	sta	$200,x
	txa
	bne	hlfnamok
	jmp	abort		; Abort if no filename

hlfnamok:
	ldy	#mpcans		; "awaiting answer from host"
	jsr	showmsg
	lda	#_'V'		; Load acc with command code
	jsr	putc		;  ...and send to host
	jsr	initprot	; Protocol negotiation
	bcc	:+		; Protocol accepted
	jmp	abort		; Exit via abort
:	ldx	#0
hfloop2:
	lda	$200,x		; Send filename to host
	jsr	putc
	beq	gethans2	; Stop at null
	inx
	bne	hfloop2

gethans2:
; for test only: activate next and deactivate line after
;	lda	#0		; simulate ok
	jsr	getc		; answer from host should be 0
	beq	initsh2
	jmp	pcerror		; error; exit via pcerror

initsh2:
	ldy	#mhlfsend
	jsr	showmsg		; show transfer message
	jmp	showfn		; exit via showfn

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
	jsr	nibtitle	; Adjust screen
	jsr	initsnib	; Ask for filename & send to pc
	jsr	nibblank	; Clear progress to all blanks
	jsr	calibrat	; Calibrate the disk

	lda	#ack		; Send initial ack
	jsr	putc

	lda	#0		; Don't actually use rwts...
	sta	iobtrk		; ...so use this as just memory

snibloop:
	lda	#_'R'
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
	jsr	putc		; Send (no) error flag to pc

	jsr	motoroff	; We're finished with the drive
	jmp	awbeep		; Beep and end


;---------------------------------------------------------
; nibblank - clear progress to all blanks
;---------------------------------------------------------
nibblank:
	lda	cv
	pha			; Save current vertical pos
	lda	#5		; Fixed vertical position
	jsr	tabv		; Calculate basl from a
	ldy	#2		; Initial horizontal position
	lda	#_' '		; The character to display
nibblnk1:
	sta	(basl),y	; Put on screen
	iny			; Next horizontal position
	cpy	#37		; At the end?
	bcc	nibblnk1	; If not, jump back
	pla
	jsr	tabv		; Restore cv
	rts

;---------------------------------------------------------
; nibshow - show character in a at current track
; support for haltracking added
;---------------------------------------------------------
nibshow:
	tay			; Character in y
	lda	cv
	pha			; Save cv on stack
	tya			; accum now contains char
	pha			; Save char on stack
	lda	#5		; Fixed vertical position
	jsr	tabv		; Calculate basl from accum
	lda	hlftrk 		; Check to see if we're in halftrk
	cmp	#1		;  mode
	bne	nibnorm		; No hlftrk, continue normally
	lda	iobtrk
	cmp	#0		; Track zero always treated the same
	beq	nibnorm
	lsr			; Is track odd or even?
	bcc	nibeven		; Track is even, continue normally
	lda	#6		; Increment vertical position
	jsr	tabv		; Calculate basl from accum
nibeven:
	lda	iobtrk		; Current track
	lsr			; Ccalc horiz pos by
	clc			;  dividing by two and
	adc	#2		;  adding 2
	jmp	nibdisp
nibnorm:
	lda	iobtrk		; Current track
	clc
	adc	#2		; Calculate horizontal pos
nibdisp:
	tay			; Index value in y
	pla			; Restore character to show
	sta	(basl),y
	pla
	jsr	tabv		; Restore cv
	rts


;---------------------------------------------------------
; initsnib - init send nibble disk
; ask for a filename, then send "N" command and filename
; to the other side and await an acknowldgement.
; note we do not check for a valid disk in the drive;
; basically any disk will do. if there is no disk present,
; bad luck (behaves the same as when booting).
;---------------------------------------------------------
initsnib:
	ldy	#mfsend
	jsr	showmsg		; Ask filename
	ldx	#0		; Get answer at $200
	jsr	nxtchar		; Input the line (Apple ROM)
	lda	#0		; Null-terminate it
	sta	$200,x
	txa
	bne	nibnamok
	jmp	abort		; Abort if no filename

nibnamok:
	ldy	#mpcans		; "awaiting answer from host"
	jsr	showmsg
	lda	#_'N'		; Load acc with command code
	jsr	putc		;  and send to pc
	jsr	initprot	; Protocol negotiation
	bcc	:+		; Protocol accepted
	jmp	abort		; Exit via abort
:	ldx	#0
fnloop2:
	lda	$200,x		; Send filename to pc
	jsr	putc
	beq	getans2		; Stop at null
	inx
	bne	fnloop2

getans2:  
; for test only: activate next and deactivate line after
;	lda	#0		; Simulate ok
	jsr	getc		; Answer from host should be 0
	beq	initsn2
	jmp	pcerror		; Error; exit via pcerror

initsn2:
	ldy	#mnibsend
	jsr	showmsg		; Show transfer message
	jmp	showfn		; Exit via showfn

;---------------------------------------------------------
; snibtrak - send nibble track to the other side
; and wait for acknowledgement. each 256 byte page is
; followed by a 16-bit crc.
; we know the buffer is set up at "tracks", and is
; nibpages * 256 bytes long. tracks is at page boundary.
; when the pc answers ack, clear carry. when it answers
; enq, set carry. when it answers anything else, abort
; the operation with the appropriate error message.
;---------------------------------------------------------
snibtrak:
	lda	#0		; a = 0
	sta	iobsec		; Reset sector counter
	sta	nibptr		; Init running ptr
	lda	#>tracks	; Tracks address high
	sta	nibptr+1
	lda	#nibpages
	sta	nibpcnt		; Page counter
	lda	#_'O'
	jsr	nibshow		; Show 'O' at current track
snibtr1:
	jsr	snibpage
	lda	crc		; followed by crc
	jsr	putc
	lda	crc+1
	jsr	putc
; for test only: activate next and deactivate line after
;	lda	#ack		; Simulate response.
	jsr	getc		; Get response from host
	cmp	#ack		; Is it ack?
	beq	snibtr5		; Yes, all right
	pha			; Save on stack
	lda	#_I'!'		; Error during send
	jsr	nibshow		; Show status of current track
	pla			; Restore response
	cmp	#nak		; Is it nak?
	beq	snibtr1		; Yes, send again
snibtr2:
	ldy	#mconfus	; Something is wrong
snibtr3:
	jsr	showmsg		; Tell bad news
	jsr	motoroff	; Transfer ended in error
	ldy	#manykey	; Append prompt
	jsr	showm1
	jsr	awbeep
	jsr	rdkey		; Wait for key
	jmp	abort		;  and abort
         
snibtr5:
	lda	#_'O'
	jsr	nibshow		; Show 'O' at current track
	inc	nibptr+1	; Next page
	inc	iobsec		; Increment sector counter
	dec	nibpcnt		; Count
	bne	snibtr1		; and back if more pages
; for test only: activate next and deactivate line after
;	lda	#ack		; Simulate response
	jsr	getc		; Get response from pc
	cmp	#ack		; Is it ack?
	beq	snibtr7		; Ok
	cmp	#can		; Is it can (unreadable trk)?
	beq	snibtr8		; Ok
	cmp	#nak		; Was it nak?
	beq	snibtr6		; We will abort
	cmp	#enq
	bne	snibtr2		; Host is confused; abort
	sec			; Let caller know what goes on
	rts
snibtr6:
	ldy	#manalys	; Host could not analyze the track
	bpl	snibtr3		; Branch always
snibtr7:
	lda	#_'.'		; Entire track transferred ok
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
; crc. nibptr points to first byte to send.
;---------------------------------------------------------
snibpage:
	ldy	#0		; Start index
	sty	crc		; Zero crc
	sty	crc+1
	sty 	prev		; No previous character
	lda	iobsec
	jsr	putc		; Send the sector number
	lda	iobtrk
	jsr	putc		; Send the track number
	lda	#$02
	jsr	putc		; Send a protocol filler

snibpag1:
	lda	(nibptr),y	; Load byte to send
	jsr	updcrc		; Update crc
	tax			; Keep a copy in x
	sec			; Subtract from previous
	sbc	prev
	stx	prev		; Save previous byte
	jsr	putc		; Send difference
	beq	snibpag3	; Was it a zero?
	iny			; No, do next byte
	bne	snibpag1	; Loop if more in this page
	rts
         
snibpag2:
	jsr	updcrc
snibpag3:
	iny			; Any more bytes?
	beq	snibpag4	; No, it was 00 up to end
	lda	(nibptr),y	; Look at next byte
	cmp	prev
	beq	snibpag2	; Same as before, continue
snibpag4:
	tya			; Difference not a zero
	jsr	putc		; Send new address
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
; motoroff - turn disk drive motor off
; preserves y. doesn't hurt if motor is already off.
;---------------------------------------------------------
motoroff:
	jsr	slot2x		; a = x = slot * 16
	lda	$c088,x		; turn motor off
	rts


;---------------------------------------------------------
; slot2x - sets configured slot * 16 in x and in a
;---------------------------------------------------------
slot2x:	ldx	pdslot
	inx			; now 1..7
	txa
	asl
	asl
	asl
	asl			; a now contans slot * 16
	tax			; store in x
	rts

;---------------------------------------------------------
; nibsync - synchronize on first byte after gap
; this function is only used from rdnibtr, but i had to
; make it a separate function to keep other stuff in one
; page (because of instriuction timings).
; this function is always fast enough to process the
; nibbles, no matter how it is laid out in memory.
; it always returns the first nibble after a gap, provided
; the track has a gap at all. if we don't find a gap, we
; probably have to do with an unformatted track. in that 
; case, just return any byte as the first, so the process
; can continue.
; on entry, x must contain slot * 16. the disk must spin,
; and we must be in read mode and on the right track.
; on exit, the zero flag is 0, and a contains the byte.
; x and y are preserved.
; note we check the number of bytes read only when 
; starting a new sequence; the check takes so long we
; loose any byte sync we might have (> 32 cycles).
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
; HOMECUR - RESET CURSOR POSITION TO 1ST SECTOR
; CHRREST - RESTORE PREVIOUS CONTENTS & ADVANCE CURSOR
; CHRADV  - WRITE NEW CONTENTS & ADVANCE CURSOR
; ADVANCE - JUST ADVANCE CURSOR
; CHROVER - JUST WRITE NEW CONTENTS
;---------------------------------------------------------
homecur:
	ldy	savtrk
	iny			; CURSOR ON 0TH COLUMN
	sty	ch
	jsr	topnext		; TOP OF 1ST COLUMN
	jmp	chrsave		; SAVE 1ST CHARACTER

chrrest:
	lda	savchr		; RESTORE OLD CHARACTER
chradv: jsr	chrover		; OVERWRITE STATUS CHAR
	jsr	advance		; ADVANCE CURSOR
chrsave:
	ldy	ch
	lda	(basl),y	; SAVE NEW CHARACTER
	sta	savchr
	rts

advance:
	inc	cv		; CURSOR DOWN
	lda	cv
	cmp	#21		; STILL IN DISPLAY?
	bcc	nowrap		; YES, WE'RE DONE
topnext:
	inc	ch		; NO, GO TO TOP OF NEXT
	lda	#5		; COLUMN
nowrap: jmp	tabv		; VALIDATE BASL,H

chrover:
	ldy	ch
	sta	(basl),y
	rts


;---------------------------------------------------------
; UPDCRC - UPDATE CRC WITH CONTENTS OF ACCUMULATOR
;---------------------------------------------------------
updcrc: pha
	eor	crc+1
	tax
	lda	crc
	eor	crctblh,x
	sta	crc+1
	lda	crctbll,x
	sta	crc
	pla
	rts


;---------------------------------------------------------
; MAKETBL - MAKE CRC-16 TABLES
;---------------------------------------------------------
maketbl:
	ldx	#0
	ldy	#0
crcbyte:
	stx	crc		; LOW BYTE = 0
	sty	crc+1		; HIGH BYTE = INDEX

	ldx	#8		; FOR EACH BIT
crcbit: lda	crc
crcbit1:
	asl			; SHIFT CRC LEFT
	rol	crc+1
	bcs	crcflip
	dex			; HIGH BIT WAS CLEAR, DO NOTHING
	bne	crcbit1
	beq	crcsave
crcflip:
	eor	#$21		; HIGH BIT WAS SET, FLIP BITS
	sta	crc		;0, 5, AND 12
	lda	crc+1
	eor	#$10
	sta	crc+1
	dex
	bne	crcbit

	lda	crc		; STORE CRC IN TABLES
crcsave:
	sta	crctbll,y
	lda	crc+1
	sta	crctblh,y
	iny
	bne	crcbyte		; DO NEXT BYTE
	rts


;---------------------------------------------------------
; PARMDFT - RESET PARAMETERS TO DEFAULT VALUES (USES AX)
;---------------------------------------------------------
parmdft:
	lda	configyet
	bne	warmer		; If no manual config yet, scan the slots
	jsr	FindSlot
warmer:
	ldx	#parmnum-1
dftloop:
	lda	default,x
	sta	parms,x
	dex
	bpl	dftloop
	rts


;---------------------------------------------------------
; AWBEEP - CUTE TWO-TONE BEEP (USES AXY)
;---------------------------------------------------------
awbeep: lda	psound		; IF SOUND OFF, RETURN NOW
	bne	nobeep
	lda	#$80		; STRAIGHT FROM APPLE WRITER ][
	jsr	beep1		;(CANNIBALISM IS THE SINCEREST
	lda	#$a0		; FORM OF FLATTERY)
beep1:	ldy	#$80
beep2:	tax
beep3:	dex
	bne	beep3
	bit	$c030		; WHAP SPEAKER
	dey
	bne	beep2
nobeep: rts


;---------------------------------------------------------
; PUTC - SEND ACC OVER THE SERIAL LINE (AXY UNCHANGED)
;---------------------------------------------------------
putc:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; GETC - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
;---------------------------------------------------------
getc:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; ABORT - STOP EVERYTHING (CALL babort TO BEEP ALSO)
;---------------------------------------------------------
babort: jsr	awbeep		; BEEP
abort:	ldx	#$ff		; POP GOES THE STACKPTR
	txs
	jsr	motoroff	; Turn potentially active drive off
	bit	$c010		; STROBE KEYBOARD
	jmp	redraw		; AND RESTART


;---------------------------------------------------------
; TITLE - SHOW TITLE SCREEN
;---------------------------------------------------------
title:	jsr	home		; CLEAR SCREEN
	ldy	#mtitle
	jsr	showm1		; SHOW TOP PART OF TITLE SCREEN

	ldx	#15		; SHOW SECTOR NUMBERS
	lda	#5		; IN DECREASING ORDER
	sta	cv		; FROM TOP TO BOTTOM
showsec:
	jsr	vtab
	lda	#$20
	ldy	#38
	sta	(basl),y
	ldy	#0
	sta	(basl),y
	lda	hexnum,x
	iny
	sta	(basl),y
	ldy	#37
	sta	(basl),y
	inc	cv
	dex
	bpl	showsec
showundm: 
	lda	#_'_'		; SHOW LINE OF UNDERLINES
	ldx	#38		; ABOVE INVERSE TEXT
showund:
	sta	$500,x
	dex
	bpl	showund
	rts

;---------------------------------------------------------
; nibtitle - show title screen for nibble disk transfer
;---------------------------------------------------------
nibtitle:
	jsr	home		; clear screen
	ldy	#mtitle
	jsr	showm1		; show top part of title screen
	lda	#5		; show one block left and right
	sta	cv		; on line 5
	jsr	vtab
	lda	#_I' '		; inverse space char
	ldy	#38		; at end of line
	sta	(basl),y
	ldy	#0		; at start of line
	sta	(basl),y
	lda	#_I'>'		; inverse character!
	iny			; next position in line
	sta	(basl),y
	lda	#_I'<'		; inverse character!
	ldy	#37		; one-but-last position in line
	sta	(basl),y
	lda	hlftrk		; check to see if we need to
	cmp	#1		; display halftrack line
	bne	nibtdone
	lda	#6		; move one line down
	sta	cv
	jsr	vtab
	lda	#_I'.'		; put an inverse . on screen
	ldy	#0		;  at horiz pos 0
	sta	(basl),y
	lda	#'5'		; and now put a 5 so we see
	ldy	#1		;  .5 which means halftrk
	sta	(basl),y
	lda	#_I' '		; put 2 inverse spaces at the end
	ldy	#37
	sta	(basl),y
	iny
	sta	(basl),y

nibtdone:
	bne	showundm	; exit via title

;---------------------------------------------------------
; SHOWMSG - SHOW NULL-TERMINATED MESSAGE #Y AT BOTTOM OF
; SCREEN.  CALL SHOWM1 TO SHOW ANYWHERE WITHOUT ERASING.
; THE MESSAGE CAN HAVE ANY LENGTH THAT FITS THE SCREEN.
;---------------------------------------------------------
showmsg:
	sty	ysave		; CLREOP USES Y
	lda	#0
	sta	ch		; COLUMN 0
	lda	#22		; LINE 22
	jsr	tabv
	jsr	clreop		; CLEAR MESSAGE AREA
	ldy	ysave

showm1: lda	msgtbl,y	; CALL HERE TO SHOW ANYWHERE
	sta	msgptr
	lda	msgtbl+1,y
	sta	msgptr+1

	ldy	#0
msgloop:
	lda	(msgptr),y
	beq	msgend
	jsr	cout1
	iny
	bne	msgloop
	inc	msgptr+1
	jmp	msgloop
msgend: rts


;------------------------ MESSAGES -----------------------

msgtbl: .addr	msg01,msg02,msg03,msg04,msg05,msg06,msg07
	.addr	msg08,msg09,msg10,msg11,msg12,msg13,msg14
	.addr	msg15,msg16,msg17,msg18,msg19,msg20,msg21
	.addr	msg22,msg23,msg24,msg25,msg26,msg27,msg28
	.addr	msg29,msg30,msg31,msg32,msg33

msg01:	asc	"COM:S"
mtssc:	asc	" ,"
mtspd:	asc	"     "
; Define as many space characters as required to fill line
; while the version number stays in the middle.
	.repeat	5-(.strlen(version_no)/2)
	.byte	$A0
	.endrep
	inv	" ADT "
	inv	version_no
	inv	" "
	.repeat	6-((.strlen(version_no)+1)/2)
	.byte	$A0
	.endrep
	asc	"DISK:S"
mtslt:	asc	" ,D"
mtdrv:	asc	" "
	.byte	$8d,$8d,$8d
	invcr	"  00000000000000001111111111111111222  "
	inv	"  "
hexnum: inv	"0123456789ABCDEF0123456789ABCDEF012  "
	.byte	$8d,$00

msg02:	inv	" ADT CONFIGURATION "
	.byte	$8d,$8d,$8d
	asccr	"DISK SLOT"
	asccr	"DISK DRIVE"
	asccr	"COMMS DEVICE"
	asccr	"COMMS SPEED"
	asccr	"READ RETRIES"
	asccr	"WRITE RETRIES"
	asccr	"USE CHECKSUMS"
	asccr	"ENABLE SOUND"
	ascz	"SAVE CONFIG"

msg03:	asccr	"USE ARROWS AND SPACE TO CHANGE VALUES,"
	ascz	"RETURN TO ACCEPT, CTRL-D FOR DEFAULTS."

msg04:	inv	"S"
	asc	"END, "
	inv	"R"
	asc	"ECEIVE, "
	inv	"D"
	asc	"IR, "
	inv	"C"
	asc	"ONFIGURE, "
	inv	"Q"
	asc	"UIT, "
	inv	"?"
	.byte	00
msg05:	ascz	"SPACE TO CONTINUE, ESC TO STOP: "
msg06:	ascz	"END OF DIRECTORY, TYPE SPACE: "

msg07:	ascz	"FILE TO RECEIVE: "
msg08:	ascz	"FILE TO SEND: "

msg09:	ascz	"RECEIVING FILE "
msg10:	ascz	"SENDING FILE "

msg11:	inv	"ERROR:"
	ascz	" NONSENSE FROM HOST."

msg12:	inv	"ERROR:"
	ascz	" NOT A 16-SECTOR DISK."

msg13:	inv	"ERROR:"
	ascz	" FILE "

msg14:	.byte	$8d
	ascz	"CAN'T BE OPENED."

msg15:	.byte	$8d
	ascz	"ALREADY EXISTS."

msg16:	.byte	$8d
	ascz	"IS NOT A 140K IMAGE."

msg17:	.byte	$8d
	ascz	"DOESN'T FIT ON DISK."

msg18:	ascz	"  ANY KEY: "

msg19:	ascz	"<- DO NOT CHANGE"

msg20:	inv	"ADT "
	invcr	version_no
	.byte	$8d
	asccr	"ORIGINAL PROGRAM BY PAUL GUERTIN"
	.byte	$8d
	asccr	"SEND NIBBLE DISK ADDED BY GERARD PUTTER"
	.byte	$8d
	asccr	"HALFTRACK SEND ADDED BY ERIC NEILSON"
	.byte	$8d
	asccr	"IIGS,LASER,/// SUPPORT BY DAVID SCHMIDT"
	.byte	$8d
	asc	"----------------------------------------"
	asccr	"SENDS / RECEIVES APPLE II DISK IMAGES"
	asccr	"VIA A SERIAL CONNECTION."
	asccr	"REQUIRES A COMPATIBLE COMPANION PROGRAM"
	asccr	"AT THE HOST SIDE."
	.byte	$8d
	asccr	"SSC, IIGS, IIC, LASER & /// COMPATIBLE."
	asccr	"----------------------------------------"
	ascz	"PRESS ANY KEY"

msg21:	ascz	"TESTING DISK FORMAT."

msg22:	ascz	"AWAITING ANSWER FROM HOST."

msg23:	ascz	"HIT ANY KEY TO CONTINUE..."

msg24:	ascz	"DISK ERROR: "

msg25:	ascz	"FILE LOCKED"

msg26:	ascz	"WRITE PROTECTED"

msg27:	ascz	"I/O ERROR"

msg28:	ascz	"SENDING NIBBLE FILE "

msg29:	ascz	"NO DISK CARD IN SELECTED SLOT."
	.byte	$8d
	ascz	"ARE YOU SURE (Y/N)? "

msg30:	inv	"ERROR:"
	ascz	" CANNOT ANALYZE TRACK."

msg31:	ascz	"SENDING HALFTRACK FILE "

msg32:	inv	"S"
	asc	"IMPLE, "
	inv	"N"
	asc	"IBBLE, "
	inv	"H"
	ascz	"ALF TRACKS ?"
	
msg33:	inv	"ERROR:"
	ascz	" INCOMPATIBLE HOST SOFTWARE"

;----------------------- PARAMETERS ----------------------

configyet:
	.byte	0		; Has the user configged yet?
parmsiz:
	.byte	7,2,9,7,8,8,2,2,2 ;#OPTIONS OF EACH PARM
parmtxt:
	.byte	_'1',0,_'2',0,_'3',0,_'4',0,_'5',0,_'6',0,_'7',0
	.byte	_'1',0,_'2',0
	ascz "SSC SLOT 1"
	ascz "SSC SLOT 2"
	ascz "SSC SLOT 3"
	ascz "SSC SLOT 4"
	ascz "SSC SLOT 5"
	ascz "SSC SLOT 6"
	ascz "SSC SLOT 7"
	ascz "IIGS MODEM"
	ascz "LASER MODEM"
	ascz "300"
	ascz "1200"
	ascz "2400"
	ascz "4800"
	ascz "9600"
	ascz "19200"
	ascz "115K"
	.byte _'0',0,_'1',0,_'2',0,_'3',0,_'4',0,_'5',0,_'1',_'0',0,_'9',_'9',0
	.byte _'0',0,_'1',0,_'2',0,_'3',0,_'4',0,_'5',0,_'1',_'0',0,_'9',_'9',0
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

parms:
pdslot: .byte	5		; DISK SLOT (6)
pdrive: .byte	0		; DISK DRIVE (1)
pssc:	.byte	1		; COMMS SLOT (2)
pspeed: .byte	6		; COMMS SPEED (115k)
pretry: .byte	1,0		; READ/WRITE MAX RETRIES (1,0)
pcksum: .byte	0		; USE RWTS CHECKSUMS? (Y)
psound: .byte	0		; SOUND AT END OF TRANSFER? (Y)
psave:	.byte	1		; SAVE? (N)

;-------------------------- IOB --------------------------

iob:	.byte	$01		; IOB TYPE
iobslt: .byte	$60		; SLOT*$10
iobdrv: .byte	$01		; DRIVE
	.byte	$00		; VOLUME
iobtrk: .byte	$00		; TRACK
iobsec: .byte	$00		; SECTOR
	.addr	dct		; DEVICE CHAR TABLE POINTER
iobbuf: .addr	tracks		; SECTOR BUFFER POINTER
	.byte	$00,$00		; UNUSED
iobcmd: .byte	$01		; COMMAND (1=READ, 2=WRITE)
	.byte	$00		; ERROR CODE
	.byte	$fe		; ACTUAL VOLUME
	.byte	$60		; PREVIOUS SLOT
	.byte	$01		; PREVIOUS DRIVE
dct:	.byte	$00,$01,$ef,$d8 ; DEVICE CHARACTERISTICS TABLE

;-------------------------- MISC -------------------------

dosbyte:
	.byte	$00,$00		; DOS BYTES CHANGED BY ADT
stddos: .byte	$00		; ZERO IF "STANDARD" DOS
savtrk: .byte	$00		; FIRST TRACK OF SEVEN
savchr: .byte	$00		; CHAR OVERWRITTEN WITH STATUS
message:
	.byte	$00		; SECTOR STATUS SENT TO HOST
pccrc:	.byte	$00,$00		; CRC RECEIVED FROM HOST
errors: .byte	$00		; NON-0 IF AT LEAST 1 DISK ERROR

; Inline source for IIgs Serial Communications Controller (SCC)
	.include "iigsscc.s"

; Inline source for Super Serial Controller (SSC)
	.include "ssc.s"

; Inline source for Pascal entry points
	.include "pascalep.s"

				; End of assembly; used to calculate
endasm:				; length to BSAVE							
