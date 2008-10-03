;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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
; This is the stripped-bare, minimal grub to read data from the serial port.
; The idea is to get just enough started to read in a bigger, more robust
; bootstrap loader.
;
; Process:
;  * Set up just enough of the environment to run
;  * Put up a little prompt to show we're alive
;  * Poll the serial port for data
;  * Once we see a "B" on the port, start reading $100 more bytes into $a100
;  * After reading $100 bytes, jump to $a100 (we don't count the initial "B")
;
; That's it!  The loader that gets sent into $a100 is a more robust
; version that does some more environment preparation and pulls in the
; whole (serial adapted) kernel, and executes it.  The Kernel then boots
; normally, except that the interp (ADTPro) and driver files are pulled
; from the serial port rather than the disk.

; This would need to be typed into the monitor (ctrl-OA-reset) and then
; run (A000G).  Alternatively, you can test this by inserting the assembled
; code into sector zero (block zero) of a diskette and booting it.
; The /// ROM will pull it into $a000 and execute it.

	.org $a000

E_REG		:= $ffdf
BUF_P		:= $7e		; Just a random, hopefully unused zero page pointer

ACIADR		:= $c0f0	; Data register. $c0f0 for ///, $c088+S0 for SSC
ACIASR		:= $c0f1	; Status register. $c0f1 for ///, $c089+S0 for SSC
ACIAMR		:= $c0f2	; Command mode register. $c0f2 for ///, $c08a+S0 for SSC
ACIACR		:= $c0f3	; Control register.  $c0f3 for ///, $c08b+S0 for SSC

Entry:	sei
	cld
	lda	#$40
	sta	$ffca		; Disable interrupts
; Set up the environment
	lda	E_REG		; Read the environment register
	ora	#$f2		; Set 1MHz switch, Video + I/O space
	sta	E_REG		; Write the environment register
; Set up the serial port
	lda	#$0b		; No parity, etc.
	sta	ACIAMR		; Store via ACIA mode register.
	lda	#$1e		; $16=300, $1e=9600, $1f=19200, $10=115k
	sta	ACIACR		; Store via ACIA control register.
; Set up our pointers
	lda	#$00
	tay			; Clean out Y reg
	sta	BUF_P
	lda	#$a1
	sta	BUF_P+1		; Loader goes into $a100

; Say we're active in the upper-right hand corner
	ldx	#$48		; "H"
	stx	$0424
	inx			; "I"
	stx	$0425

; Poll the port until we get a magic incantation
Poll:
	jsr	IIIGet
	cmp	#$47		; First character will be "B" from bigger bootstrap loader
	bne	Poll

; We got the magic signature; start reading data
Read:	
	jsr	IIIGet		; Pull a byte
	sta	(BUF_P),y	; Save it
	sta	$0427		; Print it in the status area
	iny
	bne	Read		; Only going to pull $100 bytes

; Call bootstrap entry point
	jmp	$a100		; Bigger Booter Entry point

IIIGet:
	lda	ACIASR	; Check status bits via ACIA status register
	and	#$68
	cmp	#$08
	bne	IIIGet	; Input register empty, loop
	lda	ACIADR	; Get character via ACIA data register
	rts

;.align	256
;.assert	* = $a100, error, "Code got too big to fit in a block!  C'mon, someone is supposed to be able to type this into the monitor!"
