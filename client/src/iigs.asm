*---------------------------------------------------------
* INITGS - Do all the IIgs setup stuff
*---------------------------------------------------------
INITGS
	sei		TURN OFF INTERRUPTS
	jsr SELFMOD
	jsr SERINIT
	jsr SENDINIT
	jsr PATCHGS
	rts

*---------------------------------------------------------
* SELFMOD - Set up all self-modifying addresses
*---------------------------------------------------------
SELFMOD
	cld
	lda $C02D
	sta SVC02D
	and #$FB
	sta $C02D
	lda $C20D	PASCAL INIT ENTRY POINT
	sta MODINIT+1	MOD CODE!!
	lda $C20E	PASCAL READ ENTRY POINT
	sta MODREAD+1	MOD CODE!!
	lda $C20F	PASCAL WRITE ENTRY POINT
	sta MODWRITE+1	MOD CODE!!
	lda $C210	PASCAL STATUS ENTRY POINT
	sta MODSTAT1+1	MOD CODE!!
	sta MODSTAT2+1	MOD CODE!!
	lda $C212	PASCAL CONTROL ENTRY POINT
	rts
SVC02D
	.db $84

*---------------------------------------------------------
* SERINIT - Initialize the GS slot firmware
*---------------------------------------------------------
SERINIT
	ldx #$C2	$CN, N=SLOT
	ldy #$20	$N0, N=SLOT
	lda #0
MODINIT
	jsr $C245	PASCAL INIT ENTRY POINT
	rts

*---------------------------------------------------------
* SENDINIT - initialization string for serial port
*---------------------------------------------------------
* The IIgs serial port initially accepts control-commands
* in its output stream. This means the port is not
* fully 8-bit transparent. We must first send a
* control sequence to prevent the firmware from
* interpreting any of the binary data.
*
INITSTRING
	.db $01,$b1,$b4,$c2	ctrl-A 1 4 B set 19200 baud
	.db $01,$d8,$c4	ctrl-A X D disable XON/XOFF
	.db $01,$c3,$c4	ctrl-A C D disable auto CR
	.db $01,$cb	ctrl-A K disable auto LF after CR
	.db $01,$da	ctrl-A Z disable firmware control chars
	.db $00		terminate string
SENDINIT
	ldy #0
SILOOP
	lda INITSTRING,Y
	BEQ SIDONE	ZERO terminates
	jsr PUTCGS	preserves Y
	iny
	bne SILOOP
SIDONE
	rts

*---------------------------------------------------------
* GSSPD -- SET SPEED OF GS PORT
* USES SOME 16-BIT CODE
*---------------------------------------------------------
GSSPD
	clc
	.db $FB           ; xce TO NATIVE MODE
	.db $C2,$30       ; rep #$30 16 BIT M,X
	.db $29,$FF,$00   ; and #$00FF
	tax               ; $AA
	lda L0EF8,X
	.db $29,$FF,$00   ; and #$00FF
	pha               ; $48 ; PARM 1 (2BYTE)
	.db $A9,$12,$00   ; lda #$0012
	pha               ; $48 ; PARM 2 (2BYTE)
	.db $A2,$03,$0B   ; ldx #$0B03 FUNC $B IN TOOL $3
	.db $22,$00,$00,$E1 ; jsl $E10000 ; DISPATCH
	sec
	.db $FB           ; xce TO EMULATION
	rts

*---------------------------------------------------------
* PUTCGS - Send accumulator out the serial line
*---------------------------------------------------------
PUTCGS
	.db $DA           ; PHX
	.db $5A           ; PHY
	pha
K8D8
	lda $C000
	cmp #CHR_ESC	Escape = abort
	bne OK8E2
	jmp PABORT
OK8E2
	ldx #$C2          ; $CN, N=SLOT
	ldy #$20          ; $N0
	lda #0            ; READY FOR OUTPUT?
MODSTAT1
	jsr $C248         ; PASCAL STATUS ENTRY POINT
	bcc K8D8          ; CC MEANS NOT READY
	ldx #$C2          ; $CN
	ldy #$20          ; $N0
	pla               ; RETRIEVE CHAR
	pha               ; MUST SAVE FOR RETURN
MODWRITE
	jsr $C247         ; PASCAL WRITE ENTRY POINT
	pla
	.db $7A           ; PLY
	.db $FA           ; PLX
	and #$FF
	rts

*---------------------------------------------------------
* GETCGS - GET A CHARACTER FROM SERIAL LINE (XY UNCHANGED)
*---------------------------------------------------------
GETCGS
	.db $DA		PHX
	.db $5A		PHY
K902
	lda $C000
	cmp #CHR_ESC	Escape = abort
	bne OK90C
	jmp PABORT
OK90C
	ldx #$C2	$CN, N=SLOT
	ldy #$20	$N0
	lda #1		INPUT READY?
MODSTAT2
	jsr $C248	PASCAL STATUS ENTRY POINT
	bcc K902	CC MEANS NO INPUT READY
	ldx #$C2	$CN
	ldy #$20	$N0
MODREAD
	jsr $C246	PASCAL READ ENTRY POINT
	.db $7A		PLY
	.db $FA		PLX
	and #$FF
	rts

*---------------------------------------------------------
* PATCHGS - Patch the entry point of PUTC and GETC over
*           to the IIgs versions
*---------------------------------------------------------
PATCHGS
	lda PUTC
	sta SVP
	lda PUTC+1
	sta SVP+1
	lda PUTC+2
	sta SVP+2

	lda #$4c
	sta PUTC
	lda #PUTCGS
	sta PUTC+1
	lda /PUTCGS
	sta PUTC+2

	lda GETC
	sta SVG
	lda GETC+1
	sta SVG+1
	lda GETC+2
	sta SVG+2

	lda #$4c
	sta GETC
	lda #GETCGS
	sta GETC+1
	lda /GETCGS
	sta GETC+2

	rts

*---------------------------------------------------------
* PATCHII - Patch the entry point of PUTC and GETC back
*           to the original SSC versions
*---------------------------------------------------------
PATCHII
	lda SVP
	sta PUTC
	lda SVP+1
	sta PUTC+1
	lda SVP+2
	sta PUTC+2

	lda SVG
	sta GETC
	lda SVG+1
	sta GETC+1
	lda SVG+2
	sta GETC+2

	rts

SVP	.db $00,$00,$00
SVG	.db $00,$00,$00
