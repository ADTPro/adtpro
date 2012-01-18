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

; Serial bootstrapper grub
;
; After learning enough information about the serial hardware, put up a 
; message and start listening on our best-guess port for data.


; ZERO PAGE LOCATIONS (ALL UNUSED BY DOS, BASIC & MONITOR)
msgptr		= $6		; POINTER TO MESSAGE TEXT (2B)
b_p		= $8

; Escape key definition
esc		= $9b		; ESCAPE KEY

home		= $fc58		; CLEAR WHOLE SCREEN
cout		= $fded		; Output character

slotnumloc	= $058b		; Location on screen of slot number
mliupdateloc	= $058b		; Location on screen of mli update progress

.org	$7000

init:
	lda	next_task
	beq	main
	cmp	#$01
	jmp	PullClient
 
fail:
	jsr	msg
	.byte	" NO SERIAL SLOT.",$00
	rts

main:
	jsr	home
	jsr	msg
	.byte	$8d,"ADTPRO SERIAL BOOTSTRAPPER",$8d,$8d,"FOUND",$00
	jsr	FindSlot	; Sniff out a likely comm slot
	lda	comm_slot
	bmi	fail
	clc
	adc	#$b1		; Make number printable; also increment (zero-indexed slot)
	sta	slotnumloc	; Show the discovered slot number
				; in the upper-left corner of the screen, for now
	jsr	msg
	.byte	" SLOT",$8d,$00

;---------------------------------------------------------
; PARMINT - INTERPRET PARAMETERS
;---------------------------------------------------------
parmint:
	ldy	comm_slot	; Get parm index# (0..7)
	iny			; Now slot# = 1..8 (where 8=IIgs, 9=Pascal entry points)
	tya
	cmp	#$08
	bpl	drivers
	jsr	initssc		; Y holds slot number
	jmp	configged
drivers:
	cmp	#$09
	bpl	pascalep
	jsr 	initzgs
	jmp	configged
pascalep:
	jsr	initssc

configged:
	jsr	resetio

PullMLI:
	jsr	msg
	.byte	"REQUESTED MLI: ",$00
	lda	#$B2		; Ask for the ProDOS MLI
	jsr	putc		; Send a "2" to trigger the PD download

; Poll the port until we get a magic incantation
	lda	#$20		; Store MLI at $2000
	sta	b_p+1
	ldy	#$00
	sty	b_p
Poll:
	jsr	getc
	cmp	#$50		; First character will be "P" for ProDOS
	bne	Poll
	jsr	getc		; LSB of length
	sta	size
	jsr	getc		; MSB of length
	beq	Poll		; Better not be zero
	sta	size+1		; We're ready to read everything else now

ReadMLI:			; We got the magic signature; start reading data
	jsr	getc		; Pull a byte
	sta	(b_p),y		; Save it
	;sta	mliupdateloc	; Print it in the status area
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
	jmp	$2000		; Fire up the MLI

PullClient:
	jsr	msg
	.byte	$8d,"REQUESTED ADTPRO:",$00
	lda	#$B6		; Ask for the Serial client
	jsr	putc		; Send a "2" to trigger the PD download

; Poll the port until we get a magic incantation
	lda	#$08		; Store ADTPro at $0800
	sta	b_p+1
	ldy	#$00
	sty	b_p
PollC:
	jsr	getc
	cmp	#$41		; First character will be "A" for ADTPro
	bne	PollC
	jsr	getc		; LSB of length
	sta	size
	jsr	getc		; MSB of length
	beq	PollC		; MSB better not be zero
	sta	size+1		; We're ready to read everything else now

ReadClient:			; We got the magic signature; start reading data
	jsr	getc		; Pull a byte
	sta	(b_p),y		; Save it
	sta	$0410		; Print it in the status area
	iny
	cpy	size		; Is y equal to the LSB of our target?
	bne	:+			; No... check for next pageness
	lda	size+1		; LSB is equal; is MSB?
	beq	ReadClientDone	; Yes... so done
:	cpy	#$00
	bne	ReadClient		; Check for page increment
	inc	b_p+1		; Increment another page
	dec	size+1
	jmp	ReadClient		; Go back for more

ReadClientDone:
	jmp	$0800		; Fire up ADTPro

next_task:
	.byte	$00	; Tasks:
			; 00 = Initial startup, need to seek the serial hardware and wait for ProDOS
			; 01 = Load ADTPro client

resetio:
	jsr	$0000		; Pseudo-indirect JSR to reset the IO device
	rts

;***********************************************
;
; msg -- print an in-line message
;
msg:	pla
	sta msgptr
	pla
	sta msgptr+1
	ldy #0
msg1:	inc msgptr
	bne :+
	inc msgptr+1
:	lda (msgptr),y
	beq msgx
	ora #%10000000
	jsr cout
	jmp msg1
msgx:	lda msgptr+1
	pha
	lda msgptr
	pha
	rts

;---------------------------------------------------------
; PUTC - SEND ACC OVER THE SERIAL LINE (AXY UNCHANGED)
;---------------------------------------------------------
putc:	jmp	$0000	; Pseudo-indirect JSR - self-modified

;---------------------------------------------------------
; GETC - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
;---------------------------------------------------------
getc:	jmp	$0000	; Pseudo-indirect JSR - self-modified

size:	.res	2