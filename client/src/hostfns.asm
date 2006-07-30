*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

*---------------------------------------------------------
* Host command functions
* DIR, CD
*---------------------------------------------------------

*---------------------------------------------------------
* DIR - GET DIRECTORY FROM THE PC AND PRINT IT
* PC SENDS 0,1 AFTER PAGES 1..N-1, 0,0 AFTER LAST PAGE
*---------------------------------------------------------
DIR
	ldy #PMWAIT
	jsr SHOWM1

	lda #"D"	Send "DIR" command to PC
	jsr PUTC

	lda /BIGBUF	Get buffer pointer high byte
	sta <BLKPTR+1	Set block buffer pointer
	ldy #$00	Counter
DIRBUFF
	jsr GETC	Get character from serial port
	php		Save flags
	sta (BLKPTR),Y	Store byte
	iny		Bump counter
	bne DIRNEXT	Skip
	inc <BLKPTR+1	Next 256 bytes
DIRNEXT
	plp		Restore flags
	bne DIRBUFF	Loop until zero

	jsr GETC	Get continuation character
	sta (BLKPTR),Y 	Store continuation byte too

	lda /BIGBUF	Get buffer pointer high byte
	sta <BLKPTR+1	Set block buffer pointer
	ldy #0		Reset counter
	jsr HOME	Clear screen

DIRDISP
	lda (BLKPTR),Y	Get byte from buffer
	php		Save flags
	iny		Bump
	bne DIRMORE	Skip
	inc <BLKPTR+1	Next 256 bytes
DIRMORE
	plp		Restore flags
	beq DIRPAGE	Page or dir end?
	ora #$80
	jsr COUT1	Display
	jmp DIRDISP	Loop back around

DIRPAGE
	lda (BLKPTR),Y	Get byte from buffer
	bne DIRCONT

	ldy #PMSG30	No more files, wait for a key
	jsr SHOWM1 	... and return
	jsr RDKEY
	rts

DIRLOOP1
	jsr HOME	Clear screen
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

DIRCONT
	ldy #PMSG29	"space to continue, esc to stop"
	jsr SHOWMSG
	jsr RDKEY
	eor #CHR_ESC	NOT ESCAPE, CONTINUE NORMALLY
	bne DIR		BY SENDING A "D" TO PC
	jmp PUTC	ESCAPE, SEND 00 AND RETURN


*---------------------------------------------------------
* CD - Change directory
*---------------------------------------------------------

CD
	jsr GETFN1
	bne CD.START
	jmp CD.DONE

CD.START
	ldy #PMWAIT
	jsr SHOWM1	Tell user to have patience
	lda #CHR_C	Ask host to Change Directory
	jsr PUTC
	jsr SENDFN	Send directory name
	jsr GETC	Get response from host
	bne CD.ERROR
	ldy #PMSG14
	jsr SHOWM1
	jsr PAUSE

CD.DONE
	rts

CD.ERROR
	tay
	jsr SHOWHM1
	jsr PAUSE
	jmp ABORT
