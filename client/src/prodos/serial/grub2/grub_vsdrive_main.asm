;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2013 by David Schmidt
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
	.byte	$8d,"VSDRIVE SERIAL BOOTSTRAPPER",$8d,$8d,"FOUND",$00
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

	jsr	msg
	.byte	"LOADING ",$00

	lda	NextTask
	beq	GoMLI		; Zero?  GoMLI
	cmp	#$01
	bne	:+
	jmp	GoDriver	; One? GoDriver
:	cmp	#$02
	bne	:+
	jmp	GoBASIC		; Two? GoBASIC
:	jsr	home
	jsr	RESETIO		; Else? All done!
	jmp	$E000		; BASIC 

GoMLI:
	jsr	msg
	.byte	"MLI:",$00
	lda	#$0d		; Update location for MLI
	sta	UpdateLoc+1
	lda	#$B2		; Ask for MLI ("2")
	sta	Desired+1
	lda	#$50		; First character will be "P"	
	sta	FirstChar+1
	jmp	PullFile
GoDriver:
	jsr	msg
	.byte	"VSDRIVE:",$00
	lda	#$11		; Update location for driver
	sta	UpdateLoc+1	
	lda	#$B7		; Ask for Driver ("7")
	sta	Desired+1	
	lda	#$56		; First character will be "V" for VSDRIVE
	sta	FirstChar+1	
	jmp	PullFile
GoBASIC:
	jsr	msg
	.byte	"BASIC:",$00
	lda	#$0f		; Update location for BASIC
	sta	UpdateLoc+1	
	lda	#$B8		; Ask for BASIC ("8")
	sta	Desired+1
	lda	#$42		; First character will be "B" for BASIC
	sta	FirstChar+1	
	jmp	PullFile

PullFile:
	bit	$c010		; Clear the keyboard strobe
Desired:
	lda	#$00		; Ask for the file
	jsr	PUTC		; Trigger the download

; Poll the port until we get a magic incantation
	ldy	#$20		; Prepare to store file at $2000
	sty	b_p+1
	ldy	#$00		; Prep y reg with zero for pointer ops later
	sty	b_p
Poll:
	jsr	GETC
	bcs	PullFile
FirstChar:
	cmp	#$00		; Compare to the desired first character
	beq	PullGo
	jmp	Poll
PullGo:
	jsr	GETC		; LSB of length
	bcs	PullFile
	sta	size
	jsr	GETC		; MSB of length
	bcs	PullFile
	beq	Poll		; Better not be zero
	sta	size+1		; We're ready to read everything else now

ReadFile:			; We got the magic signature; start reading data
	jsr	GETC		; Pull a byte
	bcs	PullFile
	sta	(b_p),y		; Save it
UpdateLoc:			; Print it in the status area
	sta	$0600		; (self-modifying)
	iny
	cpy	size		; Is y equal to the LSB of our target?
	bne	:+		; No... check for next pageness
	lda	size+1		; LSB is equal; is MSB?
	beq	ReadDone	; Yes... so done
:	cpy	#$00
	bne	ReadFile	; Check for page increment
	inc	b_p+1		; Increment another page
	dec	size+1
	jmp	ReadFile	; Go back for more

ReadDone:
	inc	NextTask	; Get ready for the next task when we swing back around
	jmp	$2000		; Fire up the file


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
	jmp	main		; Let NextTask sort 'em out

;---------------------------------------------------------
; Variables
;---------------------------------------------------------
size:	.res	2	; Size of file to transfer (in bytes)
PSPEED:
	.byte	3	; 0 = 300, 1 = 9600, 2 = 19200, 3 = 115200
COMMSLOT:
DEFAULT:
	.byte	$ff	; Start with -1 for a slot number so we can tell when we find no slot
NextTask:
	.byte	$00	; Tasks:
			; 00 = Initial startup, need to seek the serial hardware and wait for ProDOS
			; 01 = Load VSDrive client
			; 02 = Load BASIC interpreter
