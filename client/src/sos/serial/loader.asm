;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2014 by David Schmidt
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

; Serial bootstrap loader
;
; This code is sent by the ADTPro GUI at the user's request to a (hopefully)
; waiting Apple /// that has typed in the Grub loader.  The Grub loads this
; into $a100 and executes it, pulling in the (serial modified) SOS kernel,
; driver, then interp (ADTPro itself).
;
; THE KERNEL RELIES ON HARD-CODED ADDRESSES IN THIS MODULE.  IF CHANGES ARE
; MADE HERE - TAKE A LOOK AT kernel.asm AND CHANGE ALL LDR* ADDRESSES ACCORDINGLY.
;

	.include "sos/serial/loader.i"

KBDSTROBE	:= $c010
ENV_REG		:= $ffdf
BANK_REG	:= $ffef
Z_REG		:= $ffd0

size		:= $30
b_p		:= $32
BUF_P		:= $7e
UTILPTR		:= $82
ZP		:= $84

ACIADR		:= $c0f0	; Data register. $c0f0 for ///, $c088+S0 for SSC
ACIASR		:= $c0f1	; Status register. $c0f1 for ///, $c089+S0 for SSC
ACIAMR		:= $c0f2	; Command mode register. $c0f2 for ///, $c08a+S0 for SSC
ACIACR		:= $c0f3	; Control register.  $c0f3 for ///, $c08b+S0 for SSC

GrubIIIGet	:= $A040	; Borrow the Grub's IIIGet routine

KRNLRequestDriverWarm := $20FF	; Kernel (re-)request driver download  
KRNLReceiveDriverDone := $2144	; Kernel return point

Signature:
	.byte	$47		; The first byte that grub will see: a "G" character; not executed
	.org	$a100
Entry:
	jsr	COL40		; Clear screen, 40 column mode
	ldx	#$fb
	txs			; Some nonsense about .CONSOLE mucking with the stack
	bit	KBDSTROBE
	lda	#$40
	sta	$ffca		; Disable interrupts
	lda	#$07
	sta	BANK_REG
	ldx	#$00
BankTest:			; Find and use the highest writable bank
	dec	BANK_REG
	stx	$2000
	lda	$2000
	bne	BankTest

	jsr	ACIAInit	; Get the environment all set up

;---------------------------------------------------------
; SHOWLOGO
; 
; Prints the logo on the screen
;---------------------------------------------------------
SHOWLOGO:
	jsr CROUT
	jsr CROUT
	lda #PMLOGO1	; Start with MLOGO1 message
	sta ZP
	tay
LogoLoop:
    	lda #$02	; Get ready to HTAB $02 chars over
	sta CH
	jsr WRITEMSG
	inc ZP
	inc ZP		; Get next logo message
	ldy ZP
	cpy #PMLOGO6+2	; Stop at MLOGO6 message
	bne LogoLoop

; Set up our pointers
	lda	#$1e		; SOS.KERNEL initially occupies $1e00 to $73ff
	sta	BUF_P+1
	lda	#$00
	sta	BUF_P

; Say we're active
	ldx	#<message_1
	jsr	Message

; Ask for the kernel
RequestKernel:
	lda	#$b3		; Send "3", kernel request
	jsr	SendEnvelope

; Poll the port until we get a magic incantation
	ldy	#$00
	
Poll:
	jsr	IIIGet
	bcs	RequestKernel	; Timeout?  Request again
	cmp	#$53		; First character will be "S" from "SOS" in SOS.KERNEL
	bne	Poll
	sta	(BUF_P),y	; Save that first "S"
	iny

; We got the magic signature; start reading data
Read:	
	jsr	IIIGet	; Pull a byte - start over if we run out of bytes or time out
	bcs	RequestKernel
	sta	(BUF_P),y	; Save it
	sta	$07c5		; Print our throbber in the status area
	iny
	bne	Read
	inc	BUF_P+1		; Increment another page
	lda	BUF_P+1
	cmp	#$74		; Are we done? (SOS.KERNEL v1.3 is $56 pages long; $1E+$56=$74)
	bne	Read		; If not... go back for more

; Go fast again
	lda	ENV_REG	; Read the environment register
	and	#$7f	; Set 2MHz switch
	sta	ENV_REG	; Write the environment register

; Say we're done
	ldx	#<message_4
	jsr	Message

; Call SOSLDR entry point
	jmp	$1e70	; SOSLDR v1.3 Entry point

;---------------------------------------------------------
; IIIGet - Get a character from Super Serial Card (XY unchanged)
;          Carry set on timeout, clear on data (returned in Accumulator)
;---------------------------------------------------------
IIIGet:
	lda	#$00
	sta	Timer
	sta	Timer+1
IIIGetLoop:
	lda	ACIASR	; Check status bits
	and	#$68
	cmp	#$8
	beq	IIIGot	; Byte exists; go get it
@TimerInc:
	inc	Timer
	bne	IIIGetLoop	; Timer non-zero, loop
	inc	Timer+1
	bne	IIIGetLoop	; Timer non-zero, loop
	sec
	rts		; Timeout	
IIIGot:	lda	ACIADR	; Get character
	clc
	rts

ACIAInit:
; Set up the environment
	lda	ENV_REG		; Read the environment register
	ora	#$f2		; Set 1MHz switch, Video + I/O space
	sta	ENV_REG		; Write the environment register
; Set up the serial port
	lda	#$0b		; No parity, etc.
	sta	ACIAMR		; Store via ACIA mode register.
	lda	#$10		; $16=300, $1e=9600, $1f=19200, $10=115k
	sta	ACIACR		; Store via ACIA control register.
	bit	ACIADR		; Clear the data register
	rts

; Send an enveloped byte
SendEnvelope:
	sta	Payload		; Send accumulator as a bootstrap file request
	ldx	#$00
:	lda	Envelope,x
	jsr	IIIPut		; Send the command envelope & payload
	inx
	cpx	#$06
	bne	:-
	jsr	IIIPut		; The final byte of payload is repeated
	rts

IIIPut:
	pha			; Push 'character to send' onto the stack
IIIPutC1:
	lda	ACIASR		; Check status bits
	and	#$70
	cmp	#$10
	bne	IIIPutC1	; Output register is full, so loop
	pla			; Pull 'character to send' back off the stack
	sta	ACIADR		; Put character
	rts

Message:
	stx	SelfMod+1
	ldy	#$14
SelfMod:
	lda	message_1,y
	sta	$7b1,y
	dey
	bpl	SelfMod
	rts

RESTORE:
	lda	#$32
	sta	ENV_REG
	rts

	MLOGO1:	.byte NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,INV_CHR_L,INV_CHR_L,INV_CHR_L
		.byte CHR_RETURN
	MLOGO1_END =*

	MLOGO2:	.byte NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,INV_CHR_L,NRM_BLOCK,NRM_BLOCK,INV_CHR_L,INV_CHR_L
		.byte CHR_RETURN
	MLOGO2_END =*

	MLOGO3:	.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,INV_CHR_L,NRM_BLOCK,NRM_BLOCK,INV_CHR_L,INV_CHR_L,NRM_BLOCK
		.byte NRM_BLOCK,INV_CHR_L,INV_CHR_L,NRM_BLOCK
		.byte NRM_BLOCK,INV_CHR_L,INV_CHR_L
		.byte CHR_RETURN
	MLOGO3_END =*

	MLOGO4:	.byte INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,INV_CHR_L,INV_CHR_L,INV_CHR_L,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,NRM_BLOCK,NRM_BLOCK,INV_CHR_L
		.byte CHR_RETURN
	MLOGO4_END =*

	MLOGO5:	.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,INV_CHR_L,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,NRM_BLOCK,NRM_BLOCK,INV_CHR_L
		.byte CHR_RETURN
	MLOGO5_END =*

	MLOGO6:	.byte INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK
		.byte INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,INV_CHR_L,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte INV_CHR_L,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK
		.byte NRM_BLOCK,INV_CHR_L,INV_CHR_L
		.byte CHR_RETURN
	MLOGO6_END =*

message_1:
	.byte	" LOADING SOS KERNEL:"

message_2:
	.byte	"   LOADING ADTPRO  :"

message_3:
	.byte	"LOADING SOS DRIVERS:"

message_4:
	.byte	"   ///   OK   ///   "


;---------------------------------------------------------
; Logo message tables
;---------------------------------------------------------

PMLOGO1 = $00
PMLOGO2 = $02
PMLOGO3 = $04
PMLOGO4 = $06
PMLOGO5 = $08
PMLOGO6 = $0a

MSGTBL:	.addr MLOGO1,MLOGO2,MLOGO3,MLOGO4,MLOGO5,MLOGO6
MSGLENTBL:
	.byte MLOGO1_END-MLOGO1
	.byte MLOGO2_END-MLOGO2
	.byte MLOGO3_END-MLOGO3
	.byte MLOGO4_END-MLOGO4
	.byte MLOGO5_END-MLOGO5
	.byte MLOGO6_END-MLOGO6

;---------------------------------------------------------
; WRITEMSG - Print null-terminated message number in Y
;---------------------------------------------------------
; Entry - print message at current cursor pos
WRITEMSG:
	lda MSGTBL,Y
	sta <UTILPTR
	lda MSGTBL+1,Y
	sta <UTILPTR+1
; Entry - print message at current cursor pos
;         set UTILPTR to point to message
WRITEMSG_RAW:
	clc
	tya
	ror		; Divide Y by 2 to get the message length out of the table
	tay
	lda MSGLENTBL,Y
	beq WRITEMSGEND	; Bail if length is zero (i.e. MNULL)
	sta WRITEMSGLEN
	ldy #$00
WRITEMSGLOOP:
	lda (UTILPTR),Y
	jsr COUT
	iny
	cpy WRITEMSGLEN
	bne WRITEMSGLOOP
WRITEMSGEND:
	rts

WRITEMSGLEN:	.byte $00

Envelope:
	.byte	$c1, $01, $00, $c6, $06
Payload:	; This will be a bootstrap file request - this last byte is sent twice (x eor x = x)
	.byte	$00

ReadDriver:			; We got the magic signature; start reading data
	jsr IIIGet		; Pull a byte
	bcs ReadAgain
	sta (b_p),y		; Save it
	sta $07c5		; Print throbber in the status area
	iny
	cpy size		; Is y equal to the LSB of our target?
	bne :+			; No... check for next pageness
	lda size+1		; LSB is equal; is MSB?
	beq ReadDone		; Yes... so done
:	cpy #$00		; Check for page increment
	bne ReadDriver
	inc b_p+1		; Increment another page
	dec size+1
	jmp ReadDriver		; Branch always - go back for more
ReadDone:
	jsr RESTORE
	jmp KRNLReceiveDriverDone
ReadAgain:
	jmp KRNLRequestDriverWarm 
;GoMonitor:			; Handy dandy debug routine to jump directly into the monitor
;	lda ENV_REG
;	ora #$05		; Set ROM on, stack to alternate
;	and #$FB
;	sta ENV_REG
;	lda #$03		; Use true zero page
;	sta Z_REG
;	jmp $F901		; Jump to the monitor
Timer:	.word	$0000
Pad:
	.res	$a3ff-*,$00
.assert	* = $a3ff, error, "Code got too big to fit!"
	.byte	$00