;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2012 by David Schmidt
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

; Zero page variables (all unused by DOS, BASIC and Monitor)
UTILPTR		= $6
b_p		= $8

; Apple constants
CHR_ESC		= $9b		; ESCAPE KEY
home		= $fc58		; CLEAR WHOLE SCREEN
cout		= $fded		; Output character
delay		= $fca8		; Monitor delay: # cycles = (5*A*A + 27*A + 26)/2
rdkey		= $fd0c		; CHARACTER INPUT

; Local constants
slotnumloc	= $058b		; Location on screen of slot number
mliupdateloc	= $060d		; Location on screen of mli update progress
adtproupdateloc	= $0610		; Location on screen of ADTPro update progress

.org	$7000	; Make the listing more legible

init:
	jmp	main

fail:
INITPAS:
	jsr	msg
	.byte	" NO SERIAL SLOT.",$00
	rts

main:
	jsr	home
	jsr	msg
	.byte	$8d,"ADTPRO SERIAL BOOTSTRAPPER",$8d,$8d,"FOUND",$00
	jsr	FindSlot	; Sniff out a likely comm slot
	lda	COMMSLOT
	bmi	fail
	clc
	adc	#$b1		; Make number printable; also increment (zero-indexed slot)
	sta	slotnumloc	; Show the discovered slot number
	jsr	msg
	.byte	" SLOT",$8d,$00
	jsr	PARMINT
	jsr	RESETIO

	ldx	#$08
SitAround:			; Delay a little bit after resetting the I/O
	lda	#$ff
	jsr	delay
	dex
	bne	SitAround

	jsr	msg
	.byte	"LOADING ",$00
	lda	next_task
	beq	PullMLI
	jmp	PullClient

PullMLI:
	jsr	msg
	.byte	"MLI:",$00
PullMLICmd:
	bit	$c010		; Clear the keyboard strobe
	lda	#$B2		; Ask for the ProDOS MLI
	jsr	PUTC		; Send a "2" to trigger the PD download

; Poll the port until we get a magic incantation
	ldy	#$20		; Prepare to store MLI at $2000
	sty	b_p+1
	ldy	#$00		; Prep y reg with zero for pointer ops later
	sty	b_p
Poll:
	jsr	GETC
	cmp	#$50		; First character will be "P" for ProDOS
	beq	PullMLIGo
	lda	$c000		; Check for keypress
	cmp	#CHR_ESC
	beq	PullMLICmd
	jmp	Poll
PullMLIGo:
	jsr	GETC		; LSB of length
	sta	size
	jsr	GETC		; MSB of length
	beq	Poll		; Better not be zero
	sta	size+1		; We're ready to read everything else now

ReadMLI:			; We got the magic signature; start reading data
	jsr	GETC		; Pull a byte
	sta	(b_p),y		; Save it
	sta	mliupdateloc	; Print it in the status area
	iny
	cpy	size		; Is y equal to the LSB of our target?
	bne	:+		; No... check for next pageness
	lda	size+1		; LSB is equal; is MSB?
	beq	ReadMLIDone	; Yes... so done
:	cpy	#$00
	bne	ReadMLI		; Check for page increment
	inc	b_p+1		; Increment another page
	dec	size+1
	jmp	ReadMLI		; Go back for more

ReadMLIDone:
	lda	#$01
	sta	next_task	; Once MLI is done, re-entry should pull the client
	jmp	$2000		; Fire up the MLI

PullClient:
	jsr	msg
	.byte	"ADTPRO:",$00
PullClientCmd:
	bit	$c010		; Clear the keyboard strobe
	lda	#$B6		; Ask for the Serial client
	jsr	PUTC		; Send a "6" to trigger the ADTPro serial client download

; Poll the port until we get a magic incantation
	ldy	#$08		; Store ADTPro at $0800
	sty	b_p+1
	ldy	#$00
	sty	b_p
PollC:
	jsr	GETC
	cmp	#$41		; First character will be "A" for ADTPro
	beq	PollCGo
	lda	$c000		; Check for keypress
	cmp	#CHR_ESC
	beq	PullClientCmd
	jmp	PollC
PollCGo:
	jsr	GETC		; LSB of length
	sta	size
	jsr	GETC		; MSB of length
	beq	PollC		; MSB better not be zero
	sta	size+1		; We're ready to read everything else now

ReadClient:			; We got the magic signature; start reading data
	jsr	GETC		; Pull a byte
	sta	(b_p),y		; Save it
	sta	adtproupdateloc	; Print it in the status area
	iny
	cpy	size		; Is y equal to the LSB of our target?
	bne	:+			; No... check for next pageness
	lda	size+1		; LSB is equal; is MSB?
	beq	ReadClientDone	; Yes... so done
:	cpy	#$00
	bne	ReadClient	; Check for page increment
	inc	b_p+1		; Increment another page
	dec	size+1
	jmp	ReadClient	; Go back for more

ReadClientDone:
	lda	#$00
	sta	next_task	; In case we come back around... set up to re-pull MLI
	jmp	$0800		; Fire up ADTPro


;***********************************************
;
; msg -- print an in-line message
;
msg:	pla
	sta	UTILPTR
	pla
	sta	UTILPTR+1
	ldy	#0
msg1:	inc	UTILPTR
	bne	:+
	inc	UTILPTR+1
:	lda	(UTILPTR),y
	beq	msgx
	ora	#%10000000
	jsr	cout
	jmp	msg1
msgx:	lda	UTILPTR+1
	pha
	lda	UTILPTR
	pha
	rts

;---------------------------------------------------------
; PUTC - SEND ACC OVER THE SERIAL LINE (AXY UNCHANGED)
;---------------------------------------------------------
PUTC:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; GETC - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
;---------------------------------------------------------
GETC:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; RESETIO - clean up the I/O device
;---------------------------------------------------------
RESETIO:
	jsr	$0000	; Pseudo-indirect JSR to reset the I/O device
	rts

;---------------------------------------------------------
; abort - stop everything
;---------------------------------------------------------
PABORT:	ldx	#$ff		; POP GOES THE STACKPTR
	txs
	jmp	main		; Let next_task sort 'em out

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
size:	.res	2	; Size of file to transfer (in bytes)
PSPEED:
	.byte	3	; 0 = 300, 1 = 9600, 2 = 19200, 3 = 115200
COMMSLOT:
DEFAULT:
	.byte	$ff	; Start with -1 for a slot number so we can tell when we find no slot
next_task:
	.byte	$00	; Tasks:
			; 00 = Initial startup, need to seek the serial hardware and wait for ProDOS
			; 01 = Load ADTPro client
