;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2014 by David Schmidt
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

; Serial bootstrap loader
;
; This code is sent by the ADTPro GUI at the user's request to a (hopefully)
; waiting Apple /// that has typed in the Grub loader.  The Grub loads this
; into $a100 and executes it, pulling in the (serial modified) SOS kernel,
; driver, then interp (ADTPro itself).

KBDSTROBE	:= $c010
E_REG		:= $ffdf
BANK_REG	:= $ffef
BUF_P		:= $7e

ACIADR		:= $c0f0	; Data register. $c0f0 for ///, $c088+S0 for SSC
ACIASR		:= $c0f1	; Status register. $c0f1 for ///, $c089+S0 for SSC
ACIAMR		:= $c0f2	; Command mode register. $c0f2 for ///, $c08a+S0 for SSC
ACIACR		:= $c0f3	; Control register.  $c0f3 for ///, $c08b+S0 for SSC

GrubIIIGet	:= $a040	; Borrow the Grub's IIIGet routine

Signature:
	.byte	$47		; The first byte that grub will see: a "G" character
	.org	$a100
Entry:
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

; Set up our pointers
	lda	#$00
	sta	BUF_P
	lda	#$1e		; SOS.KERNEL initially occupies $1e00 to $73ff
	sta	BUF_P+1

; Say we're active
	ldx	#<message_1
	jsr	Message

; Ask for the kernel
	lda	#$b3		; Send "3", kernel request
	jsr	SendEnvelope

; Poll the port until we get a magic incantation
	ldy	#$00
Poll:
	jsr	GrubIIIGet
	cmp	#$53		; First character will be "S" from "SOS" in SOS.KERNEL
	bne	Poll
	sta	(BUF_P),y	; Save that first "S"
	iny

; We got the magic signature; start reading data
Read:	
	jsr	GrubIIIGet	; Pull a byte
	sta	(BUF_P),y	; Save it
	sta	$0410		; Print it in the status area
	iny
	bne	Read
	inc	BUF_P+1		; Increment another page
	lda	BUF_P+1
	cmp	#$74		; Are we done? (SOS.KERNEL v1.3 is $56 pages long; $1E+$56=$74)
	bne	Read		; If not... go back for more

; Go fast again
	lda	E_REG	; Read the environment register
	and	#$7f	; Set 2MHz switch
	sta	E_REG	; Write the environment register

; Say we're done
	ldx	#<message_4
	jsr	Message

; Call SOSLDR entry point
	jmp	$1e70	; SOSLDR v1.3 Entry point

ACIAInit:
; Set up the environment
	lda	E_REG		; Read the environment register
	ora	#$f2		; Set 1MHz switch, Video + I/O space
	sta	E_REG		; Write the environment register
; Set up the serial port
	lda	#$0b		; No parity, etc.
	sta	ACIAMR		; Store via ACIA mode register.
	lda	#$1e		; $16=300, $1e=9600, $1f=19200, $10=115k
	sta	ACIACR		; Store via ACIA control register.
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
	ldy	#$0e
SelfMod:
	lda	message_1,y
	sta	$400,y
	dey
	bpl	SelfMod
	rts

RESTORE:
	lda	#$32
	sta	E_REG
	rts

message_1:
	.byte	"LOADING KERNEL:"

message_2:
	.byte	"LOADING INTERP:"

message_3:
	.byte	"LOADING DRIVER:"

message_4:
	.byte	$cf, $cb, $a1, $a0, $a0, $a0, $a0, $a0	; "OK!"
	.byte	$a0, $a0, $a0, $a0, $a0, $a0, $a0

Envelope:
	.byte $c1, $01, $00, $c6, $06
Payload:	; This will be a bootstrap file request - this last byte is sent twice (x eor x = x)
	.byte $00

.align	256
	.byte	$00
.assert	* = $a200, error, "Code got too big to fit in a block!"
