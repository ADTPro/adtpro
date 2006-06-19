*---------------------------------------------------------
* Host command functions
* DIR, CD
*---------------------------------------------------------

*---------------------------------------------------------
* DIR - GET DIRECTORY FROM THE PC AND PRINT IT
* PC SENDS 0,1 AFTER PAGES 1..N-1, 0,0 AFTER LAST PAGE
*---------------------------------------------------------
DIR	jsr HOME	Clear screen
	lda #"D"	Send "DIR" command to PC
	jsr PUTC

	lda PSPEED
	cmp #6
	bne DIRLOOP

	lda /BIGBUF	Get buffer pointer high byte
	sta <BLKPTR+1	Set block buffer pointer
	ldy #$00	Counter
DIRBUFF	jsr GETC	Get character from serial port
	php		Save flags
	sta (BLKPTR),Y	Store byte
	iny		Bump counter
	bne DIRNEXT	Skip
	inc <BLKPTR+1	Next 256 bytes
DIRNEXT	plp		Restore flags
	bne DIRBUFF	Loop until zero

	jsr GETC	Get continuation character
	sta (BLKPTR),Y 	Store continuation byte too

	lda /BIGBUF	Get buffer pointer high byte
	sta <BLKPTR+1	Set block buffer pointer
	ldy #0		Reset counter
DIRDISP	lda (BLKPTR),Y	Get byte from buffer
	php		Save flags
	iny		Bump
	bne DIRMORE	Skip
	inc <BLKPTR+1	Next 256 bytes
DIRMORE	plp		Restore flags
	beq DIRPAGE	Page or dir end?
	ora #$80
	jsr COUT1	Display
	jmp DIRDISP	Loop back around

DIRPAGE	lda (BLKPTR),Y	Get byte from buffer
	bne DIRCONT

	ldy #PMSG30	No more files, wait for a key
	jsr SHOWM1 	... and return
	jsr RDKEY
	rts

DIRLOOP
	jsr GETC	Print PC output exactly as
	beq DIRSTOP	it arrives (PC is responsible
	ora #$80	for formatting), until a zero
	jsr COUT1	is received
	jmp DIRLOOP

DIRSTOP
	jsr GETC	Get continuation character
	bne DIRCONT	Not 00; there's more

	ldy #PMSG30	no more files, wait for a key
	jsr SHOWM1	... and return
	jsr RDKEY
	rts

DIRCONT	ldy #PMSG29	"space to continue, esc to stop"
	jsr SHOWMSG
	jsr RDKEY
	eor #CHR_ESC	NOT ESCAPE, CONTINUE NORMALLY
	bne DIR		BY SENDING A "D" TO PC
	jmp PUTC	ESCAPE, SEND 00 AND RETURN

*---------------------------------------------------------
* CD - Change directory
*---------------------------------------------------------

CD
	jsr GETFN
	bne CD.START
	jmp CD.DONE

CD.START
	lda #CHR_C	Ask host to Change Directory
	jsr PUTC
	jsr SENDFN	Send directory name
	jsr GETC	Get response from host
	bne CD.ERROR
*	jsr DIR

CD.DONE
	rts

CD.ERROR
	tay
	jsr SHOWMSG
	jsr PAUSE
	jmp ABORT
