	.include "applechr.i"

;--------------------------------
; Apple Disk Transfer
; By Paul Guertin
; pg@sff.net
; DISTRIBUTE FREELY
;--------------------------------
	.LIST	ON

; This program transfes a 16-sector disk
; to a 140K MS-DOS file and back.  The file
; format (dos-ordered, .dsk) is compatible
; with most Apple II emulators.
; SSC, IIgs or compatible hardware is required.

; Version History:

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


; CONSTANTS

esc	= $9b			; ESCAPE KEY
ack	= $06			; ACKNOWLEDGE
nak	= $15			; NEGATIVE ACKNOWLEDGE
parmnum	= 9			; NUMBER OF CONFIGURABLE PARMS

; ZERO PAGE LOCATIONS (ALL UNUSED BY DOS, BASIC & MONITOR)

msgptr	= $6			; POINTER TO MESSAGE TEXT (2B)
secptr	= $8			; POINTER TO SECTOR DATA  (2B)
trkcnt	= $1e			; COUNTS SEVEN TRACKS     (1B)
crc	= $eb			; TRACK CRC-16            (2B)
prev	= $ed			; PREVIOUS BYTE FOR RLE   (1B)
ysave	= $ee			; TEMP STORAGE            (1B)

; BIG FILES

tracks	= $2000			; 7 TRACKS AT 2000-8FFF (28KB)
crctbll	= $9000			; CRC LOW TABLE         (256B)
crctblh	= $9100			; CRC HIGH TABLE        (256B)

; MONITOR STUFF

ch	= $24			; CURSOR HORIZONTAL POSITION
cv	= $25			; CURSOR VERTICAL POSITION
basl	= $28			; BASE LINE ADDRESS
invflg	= $32			; INVERSE FLAG
clreol	= $fc9c			; CLEAR TO END OF LINE
clreop	= $fc42			; CLEAR TO END OF SCREEN
home	= $fc58			; CLEAR WHOLE SCREEN
tabv	= $fb5b			; SET BASL FROM A
vtab	= $fc22			; SET BASL FROM CV
rdkey	= $fd0c			; CHARACTER INPUT
nxtchar	= $fd75			; LINE INPUT
cout	= $fded			; Monitor output
cout1	= $fdf0			; CHARACTER OUTPUT
crout	= $fd8e			; OUTPUT RETURN

; MESSAGES

mtitle	= 0			; TITLE SCREEN
mconfig	= 2			; CONFIGURATION TOP OF SCREEN
mconfg2	= 4			; CONFIGURATION BOTTOM OF SCREEN
mprompt	= 6			; MAIN PROMPT
mdircon	= 8			; CONTINUED DIRECTORY PROMPT
mdirend	= 10			; END OF DIRECTORY PROMPT
mfrecv	= 12			; FILE TO RECEIVE:_
mfsend	= 14			; FILE TO SEND:_
mrecv	= 16			; RECEIVING FILE_    (_ = SPACE)
msend	= 18			; SENDING FILE_
mconfus	= 20			; NONSENSE FROM PC
mnot16	= 22			; NOT A 16 SECTOR DISK
merror	= 24			; ERROR: FILE_
mcant	= 26			; |CAN'T BE OPENED.     (| = CR)
mexists	= 28			; |ALREADY EXISTS.
mnot140	= 30			; |IS NOT A 140K IMAGE.
mfull	= 32			; |DOESN'T FIT ON DISK.
manykey	= 34			; __ANY KEY:_
mdont	= 36			; <- DO NOT CHANGE
mabout	= 38			; ABOUT ADT...
mtest	= 40			; TESTING DISK FORMAT
mpcans	= 42			; AWAITING ANSWER FROM PC
mpause	= 44			; HIT ANY KEY TO CONTINUE...
mdoserr	= 46			; DOS ERROR:_
mdos0a	= 48			; FILE LOCKED
mdos04	= 50			; WRITE PROTECTED
mdos08	= 52			; I/O ERROR

;*********************************************************

	.ORG	$803

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
	ldy	#mprompt	; SHOW MAIN PROMPT
mainl:
resetio:
	jsr	$0000		; Pseudo-indirect JSR to reset the IO device
	jsr	showmsg		; AT BOTTOM OF SCREEN
	jsr	rdkey		; GET ANSWER
	and	#$df		; CONVERT TO UPPERCASE

	cmp	#_'S'		; SEND?
	bne	krecv		; NOPE, TRY RECEIVE
	jsr	send		; YES, DO SEND ROUTINE
	jmp	mainlup

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
	ldy	#mabout		; YES, SHOW MESSAGE, WAIT
	jsr	showmsg		; FOR KEY, AND RETURN
	jsr	rdkey
	jmp	mainlup

kquit:	cmp	#_'Q'		; QUIT?
	bne	mainlup		; NOPE, WAS A BAD KEY
	lda	dosbyte		; YES, RESTORE DOS CHECKSUM CODE
	sta	$b92e
	lda	dosbyte+1
	sta	$b98a
	cli			; Restore interrupts
	jmp	$3d0		; AND QUIT TO DOS


;---------------------------------------------------------
; DIR - GET DIRECTORY FROM THE PC AND PRINT IT
; PC SENDS 0,1 AFTER PAGES 1..N-1, 0,0 AFTER LAST PAGE
;---------------------------------------------------------
dir:
	ldy	#mpcans
	jsr	showmsg
	lda	#_'D'		; SEND DIR COMMAND TO PC
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
	bne	dir		; BY SENDING A "D" TO PC
	jmp	putc		; ESCAPE, SEND 00 AND RETURN

;---------------------------------------------------------
; FindSlot - Find a comms device
;---------------------------------------------------------
FindSlot:
	lda #$00
	sta msgptr		; Borrow msgptr
	sta TempSlot
	sta TempIIgsSlot
	ldx #$07		; Slot number - start high
FindSlotLoop:
	clc
	txa
	adc #$c0
	sta msgptr+1
	ldy #$05		; Lookup offset
	lda (msgptr),y
	cmp #$38		; Is $Cn05 == $38?
	bne FindSlotNext
	ldy #$07		; Lookup offset
	lda (msgptr),y
	cmp #$18		; Is $Cn07 == $18?
	bne FindSlotNext
	ldy #$0b		; Lookup offset
	lda (msgptr),y
	cmp #$01		; Is $Cn0B == $01?
	bne FindSlotNext
	ldy #$0c		; Lookup offset
	lda (msgptr),y
	cmp #$31		; Is $Cn0C == $31?
	bne FindSlotNext
; Ok, we have a set of signature bytes for a comms card (or IIgs).
	ldy #$1b		; Lookup offset
	lda (msgptr),y
	cmp #$eb		; Do we have a goofy XBA instruction?
	bne FoundSSC		; If not, it's an SSC.
	cpx #$02		; Only bothering to check IIgs Modem slot (2)
	bne FindSlotNext
	lda #$07		; We found the IIgs modem port, so store it
	sta TempIIgsSlot
	jmp FindSlotNext
FoundSSC:
	stx TempSlot
FindSlotNext:
	dex
	bne FindSlotLoop
; All done now, so clean up
	ldx TempSlot
	beq :+
	dex			; Subtract 1 to match slot# to parm index
	stx pssc
	stx default+2		; Store the slot number discovered as default
	rts
:	lda TempIIgsSlot
	beq FindSlotDone	; Didn't find either SSC or IIgs Modem
	sta pssc
	sta default+2		; Store the slot number discovered as default
FindSlotDone:
	rts
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
	lda #$00
	sta ch
	lda #$17
	jsr tabv
	jsr clreop
	ldy #mpause
	jsr showmsg
	jsr rdkey
	cmp #$9B
	beq pauseesc
	clc
	rts
pauseesc:
	sec
	rts

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
	bpl	iigs
	jmp	initssc		; Y holds slot number

iigs:
	jmp	initzgs
	rts

spdtxt: asc	"  003 0021 0042 0084 006900291 K511"
bpsctrl:
	.byte	$16,$18,$1a,$1c,$1e,$1f,$10
trytbl: .byte	0,1,2,3,4,5,10,99

;---------------------------------------------------------
; GETNAME - GET FILENAME AND SEND TO PC
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

diskok: ldy	#mpcans		;"AWAITING ANSWER FROM PC"
	jsr	showmsg
	lda	#_'R'		; LOAD ACC WITH "R" OR "S"
	adc	directn
	jsr	putc		; AND SEND TO PC
	ldx	#0
fnloop: lda	$200,x		; SEND FILENAME TO PC
	jsr	putc
	beq	getans		; STOP AT NULL
	inx
	bne	fnloop

getans: jsr	getc		; ANSWER FROM PC SHOULD BE 0
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
; RECEIVE - MAIN RECEIVE ROUTINE
;---------------------------------------------------------
receive:
	ldx	#0		; DIRECTION = PC-->APPLE
	jsr	getname		; ASK FOR FILENAME & SEND TO PC
	lda	#ack		; 1ST MESSAGE ALWAYS ACK
	sta	message
	lda	#0		; START ON TRACK 0
	sta	iobtrk
	sta	errors		; NO DISK ERRORS YET

recvlup:
	sta	savtrk		; SAVE CURRENT TRACK
	ldx	#1
	jsr	sr7trk		; RECEIVE 7 TRACKS FROM PC
	ldx	#2
	jsr	rw7trk		; WRITE 7 TRACKS TO DISK
	lda	iobtrk
	cmp	#$23		; REPEAT UNTIL TRACK $23
	bcc	recvlup
	lda	message		; SEND LAST ACK
	jsr	putc
	lda	errors
	jsr	putc		; SEND ERROR FLAG TO PC
	jmp	awbeep		; BEEP AND END


;---------------------------------------------------------
; SEND - MAIN SEND ROUTINE
;---------------------------------------------------------
send:	ldx	#1		; DIRECTION = APPLE-->PC
	jsr	getname		; ASK FOR FILENAME & SEND TO PC
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
	jsr	sr7trk		; SEND 7 TRACKS TO PC
	lda	iobtrk
	cmp	#$23		; REPEAT UNTIL TRACK $23
	bcc	sendlup
	lda	errors
	jsr	putc		; SEND ERROR FLAG TO PC
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
	jsr	getc		; GET RESPONSE FROM PC
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
putc:	jmp $0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; GETC - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
;---------------------------------------------------------
getc:	jmp $0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; ABORT - STOP EVERYTHING (CALL SABORT TO BEEP ALSO)
;---------------------------------------------------------
babort: jsr	awbeep		; BEEP
abort:	ldx	#$ff		; POP GOES THE STACKPTR
	txs
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

	lda	#_'_'		; SHOW LINE OF UNDERLINES
	ldx	#38		; ABOVE INVERSE TEXT
showund:
	sta	$500,x
	dex
	bpl	showund
	rts


;---------------------------------------------------------
; SHOWMSG - SHOW NULL-TERMINATED MESSAGE #Y AT BOTTOM OF
; SCREEN.  CALL SHOWM1 TO SHOW ANYWHERE WITHOUT ERASING
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
msgend: rts


;------------------------ MESSAGES -----------------------

msgtbl: .addr	msg01,msg02,msg03,msg04,msg05,msg06,msg07
	.addr	msg08,msg09,msg10,msg11,msg12,msg13,msg14
	.addr	msg15,msg16,msg17,msg18,msg19,msg20,msg21
	.addr	msg22,msg23,msg24,msg25,msg26,msg27

msg01:	asc	"SSC:S"
mtssc:	asc	" ,"
mtspd:	asc	"        "
	inv	" ADT 1.32 "
	asc	"    DISK:S"
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

msg04:	ascz	"SEND, RECEIVE, DIR, CONFIGURE, QUIT? "
msg05:	ascz	"SPACE TO CONTINUE, ESC TO STOP: "
msg06:	ascz	"END OF DIRECTORY, TYPE SPACE: "

msg07:	ascz	"FILE TO RECEIVE: "
msg08:	ascz	"FILE TO SEND: "

msg09:	ascz	"RECEIVING FILE "
msg10:	ascz	"SENDING FILE "

msg11:	inv	"ERROR:"
	ascz	" NONSENSE FROM PC."

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

msg20:	asccr	"APPLE DISK TRANSFER 1.32      2007-6-1"
	ascz	"PAUL GUERTIN (SSC AND IIGS COMPATIBLE)"

msg21:	ascz	"TESTING DISK FORMAT."

msg22:	ascz	"AWAITING ANSWER FROM PC."

msg23:	ascz	"HIT ANY KEY TO CONTINUE..."

msg24:	ascz	"DISK ERROR: "

msg25:	ascz	"FILE LOCKED"

msg26:	ascz	"WRITE PROTECTED"

msg27:	ascz	"I/O ERROR"

;----------------------- PARAMETERS ----------------------

configyet:
	.byte	0		; Has the user configged yet?
parmsiz:
	.byte	7,2,8,7,8,8,2,2,2 ;#OPTIONS OF EACH PARM
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
	.byte	$00		; SECTOR STATUS SENT TO PC
pccrc:	.byte	$00,$00		; CRC RECEIVED FROM PC
errors: .byte	$00		; NON-0 IF AT LEAST 1 DISK ERROR

; Inline source for IIgs Serial Communications Controller (SCC)
	.include "iigsscc.s"

; Inline source for Super Serial Controller (SSC)
	.include "ssc.s"

				; End of assembly; used to calculate
endasm:				; length to BSAVE							
