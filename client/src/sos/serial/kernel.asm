        .setcpu "6502"
	.org	$1e00

b_p		:= $32
size		:= $30
GRUBIIIGET	:= $a040	; Borrow Grub's IIIGET
ACIAINIT	:= $A161	; Borrow the Loader's ACIAINIT
LOADERIIIPUT	:= $A174	; Borrow the Loader's IIIPUT
LOADERRESTORE	:= $A192	; Borrow the Loader's RESTORE
LOADERMessage	:= $A183	; Borrow the Loader's Message routine
LOADERmessage_2	:= $A1A7	; Borrow the Loader's message_2
LOADERmessage_3	:= $A1B6	; Borrow the Loader's message_3
ACIADR		:= $c0f0	; Data register. $c0f0 for ///, $c088+S0 for SSC
ACIASR		:= $c0f1	; Status register. $c0f1 for ///, $c089+S0 for SSC
ACIAMR		:= $c0f2	; Command mode register. $c0f2 for ///, $c08a+S0 for SSC
ACIACR		:= $c0f3	; Control register.  $c0f3 for ///, $c08b+S0 for SSC
ZPAGE           := $0000
I_BASE_P        := $0002
RDBUF_P		:= $04
SYSBUF_P	:= $06
D_TPARMX        := $00C0
I               := $00EA
L00FD           := $00FD
SSPAGE          := $0100
L0810           := $0810
SXPAGE          := $1400
L1581           := $1581
CXPAGE          := $1600
SZPAGE          := $1800
SCRNMODE        := $1906
L1981           := $1981
L1985           := $1985
CZPAGE          := $1A00
CSPAGE          := $1B00
LA0A0           := $A0A0
LB801           := $B801
LB81D           := $B81D
LB869           := $B869
LB89D           := $B89D
LB8E6           := $B8E6
LB905           := $B905
LB910           := $B910
LB925           := $B925
LBC00           := $BC00
LBC9C           := $BC9C
LBCD5           := $BCD5
LBCE3           := $BCE3
LBD6F           := $BD6F
LBDD6           := $BDD6
LBE01           := $BE01
LBE75           := $BE75
LBEA0           := $BEA0
LBEA4           := $BEA4
LBF05           := $BF05
LBF0D           := $BF0D
LBF24           := $BF24
LBFD2           := $BFD2
MOTOROFF        := $C088
MOTORON         := $C089
LC09E           := $C09E
LC0CC           := $C0CC
LC0CE           := $C0CE
NOSCROLL        := $C0D8
LC0E9           := $C0E9
ACIASTAT        := $C0F1
LC24F           := $C24F
LC26D           := $C26D
LC2BD           := $C2BD
LC2C4           := $C2C4
LC2D1           := $C2D1
LC2E3           := $C2E3
LC3B4           := $C3B4
LC3C3           := $C3C3
LC3D6           := $C3D6
LC3F0           := $C3F0
LC3FE           := $C3FE
LC461           := $C461
LC465           := $C465
LC480           := $C480
LC485           := $C485
LC493           := $C493
LC4CD           := $C4CD
LC51C           := $C51C
LC5B0           := $C5B0
LC5C0           := $C5C0
LC5D1           := $C5D1
LC62A           := $C62A
LC636           := $C636
LC64D           := $C64D
LC692           := $C692
LC706           := $C706
LC71E           := $C71E
LC762           := $C762
LC7A0           := $C7A0
LC7AA           := $C7AA
LC802           := $C802
LC848           := $C848
LC863           := $C863
LC88F           := $C88F
LC89A           := $C89A
LC8F2           := $C8F2
LC90A           := $C90A
LC91E           := $C91E
LC929           := $C929
LC94C           := $C94C
LC987           := $C987
LC9C3           := $C9C3
LC9F5           := $C9F5
LCA04           := $CA04
LCA6E           := $CA6E
LCA9C           := $CA9C
LCAA5           := $CAA5
LCAB2           := $CAB2
LCB0A           := $CB0A
LCB57           := $CB57
LCB7F           := $CB7F
LCB85           := $CB85
LCBE4           := $CBE4
LCBF8           := $CBF8
LCC10           := $CC10
LCC32           := $CC32
LCC4F           := $CC4F
LCC54           := $CC54
LCC58           := $CC58
LCC6A           := $CC6A
LCC78           := $CC78
LCC7E           := $CC7E
LCC8C           := $CC8C
LCC90           := $CC90
LCCCD           := $CCCD
LCD09           := $CD09
LCE14           := $CE14
LCE32           := $CE32
LCE4A           := $CE4A
LCE54           := $CE54
LCE7B           := $CE7B
LCE84           := $CE84
LCEB5           := $CEB5
LCECA           := $CECA
LCED8           := $CED8
LCEF0           := $CEF0
LCEF6           := $CEF6
LCF0E           := $CF0E
LCF25           := $CF25
LCF3A           := $CF3A
LCF3E           := $CF3E
LCF49           := $CF49
LCF73           := $CF73
LCF84           := $CF84
LCF94           := $CF94
LCFA9           := $CFA9
LD0F6           := $D0F6
LD142           := $D142
LD264           := $D264
LD26B           := $D26B
LD27E           := $D27E
LD2A2           := $D2A2
LD2B3           := $D2B3
LD307           := $D307
LD31E           := $D31E
LD361           := $D361
LD463           := $D463
LD466           := $D466
LD477           := $D477
LD4CB           := $D4CB
LD505           := $D505
LD513           := $D513
LD557           := $D557
LD578           := $D578
LD587           := $D587
LD5BD           := $D5BD
LD61E           := $D61E
LD67F           := $D67F
LD687           := $D687
LD765           := $D765
LD776           := $D776
LD778           := $D778
LD781           := $D781
LD83B           := $D83B
LD83D           := $D83D
LD841           := $D841
LD87B           := $D87B
LDA33           := $DA33
LDA41           := $DA41
LDA52           := $DA52
LDB4F           := $DB4F
LDBE1           := $DBE1
LDBF6           := $DBF6
LDBFC           := $DBFC
LDC33           := $DC33
LDC51           := $DC51
LDC9C           := $DC9C
LDCB6           := $DCB6
LDCD0           := $DCD0
LDCDC           := $DCDC
LDCF4           := $DCF4
LDD0B           := $DD0B
LDD1B           := $DD1B
LDD2F           := $DD2F
LDD9B           := $DD9B
LDDF4           := $DDF4
LDE66           := $DE66
LDF77           := $DF77
LDFA7           := $DFA7
LDFF5           := $DFF5
LE050           := $E050
LE15C           := $E15C
LE1A4           := $E1A4
LE1FC           := $E1FC
LE21D           := $E21D
LE24C           := $E24C
LE28D           := $E28D
LE2CA           := $E2CA
LE352           := $E352
LE3A9           := $E3A9
LE3C2           := $E3C2
LE48B           := $E48B
LE656           := $E656
LE6C9           := $E6C9
LE706           := $E706
LE77C           := $E77C
LE7B5           := $E7B5
LE7C7           := $E7C7
LE877           := $E877
DIB1            := $E899
DIB1b           := $E89A
DIB2            := $E8B9
DIB2b           := $E8BA
DIB3            := $E8D9
DIB3b           := $E8DA
DIB4            := $E8F9
DIB4b           := $E8FA
LE986           := $E986
LE9BC           := $E9BC
LEA55           := $EA55
LEA8B           := $EA8B
LEAA4           := $EAA4
LEAE9           := $EAE9
LEB0E           := $EB0E
LEB35           := $EB35
LEB3A           := $EB3A
LEB46           := $EB46
LEBCC           := $EBCC
LEBD5           := $EBD5
LEBDB           := $EBDB
LEC1D           := $EC1D
LEC6B           := $EC6B
LEC75           := $EC75
LECAC           := $ECAC
LECC8           := $ECC8
LECDC           := $ECDC
LED0A           := $ED0A
LED26           := $ED26
LED3F           := $ED3F
LED57           := $ED57
LED60           := $ED60
LED98           := $ED98
LEDDB           := $EDDB
LEDE8           := $EDE8
LEE17           := $EE17
LEE2A           := $EE2A
LEEC7           := $EEC7
LEECB           := $EECB
MAX_DNUM        := $EED9
BLKDLST         := $EF70
LEF7D           := $EF7D
LF017           := $F017
LF048           := $F048
LF0F6           := $F0F6
LF148           := $F148
LF1AD           := $F1AD
LF1B9           := $F1B9
LF1BD           := $F1BD
LF1E5           := $F1E5
LF216           := $F216
LF256           := $F256
LF259           := $F259
LF264           := $F264
LF2C4           := $F2C4
LF2F5           := $F2F5
LF30F           := $F30F
LF37A           := $F37A
LF400           := $F400
LF428           := $F428
LF44F           := $F44F
LF456           := $F456
LF4A8           := $F4A8
LF4AB           := $F4AB
LF4C3           := $F4C3
LF4F2           := $F4F2
LF517           := $F517
LF531           := $F531
LF53F           := $F53F
LF5C5           := $F5C5
LF622           := $F622
LF686           := $F686
LF6D1           := $F6D1
LF6EC           := $F6EC
LF710           := $F710
LF73D           := $F73D
LF7ED           := $F7ED
LF7F9           := $F7F9
LF810           := $F810
LF840           := $F840
LF851           := $F851
MONITOR		:= $f901
LF952           := $F952
LF981           := $F981
LFA23           := $FA23
LFAB8           := $FAB8
LFB04           := $FB04
LFB31           := $FB31
LFBAD           := $FBAD
LFC03           := $FC03
LFC05           := $FC05
LFC2F           := $FC2F
LFCF9           := $FCF9
LFD48           := $FD48
LFD97           := $FD97
LFDC8           := $FDC8
LFE27           := $FE27
LFE39           := $FE39
LFE67           := $FE67
LFE95           := $FE95
LFEA7           := $FEA7
LFEC2           := $FEC2
LFEEC           := $FEEC
LFF05           := $FF05
LFF1E           := $FF1E
LFF24           := $FF24
LFF76           := $FF76
LFFAA           := $FFAA
Z_REG           := $FFD0
D_DDRB          := $FFD2
D_DDRA          := $FFD3
D_ACR           := $FFDB
D_PCR           := $FFDC
D_IFR           := $FFDD
D_IER           := $FFDE
E_REG           := $FFDF
E_IORB          := $FFE0
E_DDRB          := $FFE2
E_DDRA          := $FFE3
E_ACR           := $FFEB
E_PCR           := $FFEC
E_IFR           := $FFED
E_IER           := $FFEE
B_REG           := $FFEF
NMI_VECTOR      := $FFFA
K_FILE: .byte   $53,$4F,$53,$20,$4B,$52,$4E,$4C
K_HDR_CNT:
        .byte   $62,$00
K_DRIVES:
        .byte   $01
K_FLAGS:.byte   $00
I_PATH: .byte   $0E
I_PATHNM:
        .byte   $2E,$44,$31,$2F,$53,$4F,$53,$2E
        .byte   $49,$4E,$54,$45,$52,$50
I_PATHL:.byte   $AA,$A5,$A0,$F9,$A0,$A0,$A5,$A0
        .byte   $A0,$A5,$A0,$A0,$C5,$A0,$A0,$98
        .byte   $A0
LDR_ADR:.byte   $F0,$A1
LDR_CNT:.byte   $A0,$CC,$A0,$A0,$C5,$A0,$A0,$A0
        .byte   $A0,$A0,$EE,$A0,$A0,$C4
D_PATH: .byte   $0E
D_PATHNM:
        .byte   $2E,$44,$31,$2F,$53,$4F,$53,$2E
        .byte   $44,$52,$49,$56,$45,$52
D_PATHL:.byte   $FF,$9A,$A0,$FF,$9A,$A0,$A0,$A0
        .byte   $A0,$D0,$A0,$A0,$C1,$A0,$A0,$8A
        .byte   $A0,$A0,$F9,$A0,$C1,$E9,$A0,$9E
        .byte   $A1,$A0,$F5,$A0,$A0,$A5,$A0,$A0
        .byte   $88,$00,$00,$88,$0C
SOSLDR:
lda     #$00
        tax
SLDR010:sta     CZPAGE,x
        sta     CXPAGE,x
        sta     CSPAGE,x
        sta     SZPAGE,x
        sta     SXPAGE,x
        sta     SSPAGE,x
        dex
        bne     SLDR010
        lda     #$30
        sta     E_REG
        ldx     #$FB
        txs
        lda     #$1A
        sta     Z_REG
        jsr     SOSLDR1
        lda     E_REG
        and     #$10
        ora     #$28
        sta     E_REG
        ldx     #$FF
        txs
        lda     #$1A
        sta     Z_REG
        lda     $1901
        sta     B_REG
        jmp     (I_BASE_P)
MOVE:   tax
        lda     B_REG
        pha
        stx     B_REG
        lda     $27
        ora     $26
        beq     MOVE_EXIT
        lda     $26
        bne     MOVE010
        dec     $27
MOVE010:dec     $26
        clc
        lda     $23
        adc     $27
        sta     $23
        lda     $25
        adc     $27
        sta     $25
        inc     $27
        ldy     $26
        beq     MOVE020
MOVE_PAGE:
        lda     ($22),y
        sta     ($24),y
        dey
        bne     MOVE_PAGE
MOVE020:lda     ($22),y
        sta     ($24),y
        dey
        dec     $23
        dec     $25
        dec     $27
        bne     MOVE_PAGE
        inc     $23
        inc     $25
MOVE_EXIT:
        pla
        sta     B_REG
        rts
LINK:   clc
        lda     $24
        adc     $10
        sta     $10
        lda     $25
        adc     $11
        sta     $11
        lda     #$00
        sta     $1611
        lda     $18
        sta     B_REG
        ldy     #$00
        lda     $10
        sta     ($2C),y
        iny
        lda     $11
        sta     ($2C),y
        lda     $2A
        sta     B_REG
        lda     $10
        sta     $2C
        lda     $11
        sta     $2D
WALKLINKS:
        jsr     ALLOC_DEV
LINK010:ldy     #$00
        lda     ($2C),y
        iny
        ora     ($2C),y
        beq     LINK100
        lda     ($2C),y
        cmp     $2D
        bne     LINK030
        dey
        lda     ($2C),y
        cmp     $2C
        beq     LINK100
LINK030:ldy     #$00
        lda     ($2C),y
        tax
        iny
        lda     ($2C),y
        stx     $2C
        sta     $2D
        jsr     ALLOC_DEV
        jmp     LINK010
LINK100:ldy     #$00
        tya
        sta     ($2C),y
        iny
        sta     ($2C),y
        dey
        sty     B_REG
        rts
LINK_INIT:
        jsr     SET_DRIVES
        lda     #$00
        sta     MAX_DNUM
        sta     BLKDLST
        sta     $162D
        lda     #$99
        sta     $2C
        lda     #$E8
        sta     $2D
        jmp     WALKLINKS
ALLOC_DEV:
        inc     MAX_DNUM
        ldx     MAX_DNUM
        cpx     #$19
        bcc     L1F8A
        ldx     #$C4
        ldy     #$10
        jsr     ERROR
L1F8A:  lda     B_REG
        sta     $EF3E,x
        clc
        lda     $2C
        adc     #$04
        sta     $EEDA,x
        lda     $2D
        adc     #$00
        sta     $EEF3,x
        sec
        ldy     #$02
        lda     ($2C),y
        sbc     #$01
        sta     $EF0C,x
        iny
        lda     ($2C),y
        sbc     #$00
        sta     $EF25,x
        ldy     #$16
        lda     ($2C),y
        sta     $EF57,x
        ldy     #$17
        lda     ($2C),y
        bpl     L1FD3
        txa
        inc     BLKDLST
        ldx     BLKDLST
        cpx     #$0D
        bcc     L1FD0
        ldx     #$DA
        ldy     #$16
        jsr     ERROR
L1FD0:  sta     BLKDLST,x
L1FD3:  rts
SOSLDR1:ldx     #$1F
LDR010: lda     $0380,x
        sta     SZPAGE,x
        dex
        bpl     LDR010
        lda     #$6C
        sta     $0A
        lda     #$1E
        sta     $0B
        jsr     ADVANCE
        lda     B_REG
        jsr     MOVE
        lda     B_REG
        and     #$0F
        sta     $1901
        asl     a
        clc
        adc     #$04
        sta     $1900
        jsr     ADVANCE
        lda     $24
        sta     ZPAGE
        lda     $25
        sta     $01
        lda     B_REG
        jsr     MOVE
        lda     #$00
        sta     $22
        sta     $24
        lda     #$20
        sta     $23
        sta     $25
        lda     #$8F
        .byte   $8D
        .byte   $25
L2020:  asl     $A9,x
        sed
        sta     $26
        lda     #$0A
        sta     $27
        lda     B_REG
        jsr     MOVE
        lda     #$00
        sta     B_REG
        lda     K_DRIVES
        jsr     LINK_INIT
        jsr     INIT_KRNL
        jsr     WELCOME
        lda     E_REG
        ora     #$03
        sta     E_REG
        lda     LF1B9
        cmp     #$A0
        beq     LDR020
        ldx     #$B4
        ldy     #$25
        jsr     ERROR
LDR020: lda     E_REG
        and     #$F6
        sta     E_REG
ReceiveInterp:
	jsr ACIAINIT		; Slow down to 1MHz, set up ACIA parms
	lda #180
	jsr LOADERIIIPUT	; Send a "4" to trigger the SOS.INTERP download

; Poll the port until we get a magic incantation
PollInterp:
	lda #$00		; #>LDREND-$2000+$400 = $58*00*
	tay
	sta b_p
	sta RDBUF_P
	lda #$58		; #<LDREND-$2000+$400 = $*58*00
	sta b_p+1
	sta RDBUF_P+1
	lda #$80
	sta CXPAGE+b_p+1	; Set XBYTE to $80 - using Xtended addressing
PollInterpNext:
	jsr GRUBIIIGET
	cmp #$53		; Trigger character is an "S"
	bne PollInterpNext
	jsr GRUBIIIGET		; LSB of length
	sta size
	jsr GRUBIIIGET		; MSB of length
	sta size+1		; We're ready to read everything else now

	ldx #<LOADERmessage_2	; Tell 'em we're reading
	jsr LOADERMessage
	ldy #$00
ReadInterp:			; We got the magic signature; start reading data
	jsr GRUBIIIGET		; Pull a byte
	sta (b_p),y		; Save it
	sta $0410		; Print it in the status area
	iny
	cpy size		; Is y equal to the LSB of our target?
	bne :+			; No... check for next pageness
	lda size+1		; LSB is equal; is MSB?
	beq ReadInterpDone	; Yes... so done
:	cpy #$00
	bne ReadInterp		; Check for page increment
	inc b_p+1		; Increment another page
	dec size+1
	jmp ReadInterp		; Go back for more

ReadInterpDone:
	jsr	LOADERRESTORE

ReceiveInterpPadBegin:
	.res	$20c0-ReceiveInterpPadBegin, $ea

ReceiveInterpDone:
        lda     #$06
        sta     $0A
        lda     #$58
        sta     $0B
        lda     #$80
        sta     $160B
        jsr     ADVANCE
        lda     $24
        sta     I_BASE_P
        lda     $25
	sta     $03
        lda     #$00
        sta     $1603
        clc
        lda     $26
        adc     $24
        tax
        lda     $27
        adc     $25
        cpx     ZPAGE
        sbc     $01
        beq     LDR070
        bcc     LDR070
        ldx     #$52
        ldy     #$18
        jsr     ERROR
LDR070:	lda     $1901
	jsr     MOVE

ReceiveDriver:
	jsr ACIAINIT		; Slow down to 1MHz, etc.
	lda #181
	jsr LOADERIIIPUT	; Send a "5" to trigger the SOS.DRIVER download

; Poll the port until we get a magic incantation
Poll:
	lda #$00		; #>LDREND-$2000+$400 = $58*00*
	tay
	sta b_p
	lda #$58		; #<LDREND-$2000+$400 = $*58*00
	sta b_p+1
;	lda #$80
;	sta CXPAGE+b_p+1	; Set XBYTE to $80 - using Xtended addressing
PollNext:
	jsr GRUBIIIGET
	cmp #$53		; Trigger character is an "S"
	bne PollNext
	jsr GRUBIIIGET		; LSB of length
	sta size
	jsr GRUBIIIGET		; MSB of length
	sta size+1		; We're ready to read everything else now

	ldx #<LOADERmessage_3	; Tell 'em we're reading
	jsr LOADERMessage
	ldy #$00
Read:				; We got the magic signature; start reading data
	jsr GRUBIIIGET		; Pull a byte
	sta (b_p),y		; Save it
	sta $0410		; Print it in the status area
	iny
	cpy size		; Is y equal to the LSB of our target?
	bne :+			; No... check for next pageness
	lda size+1		; LSB is equal; is MSB?
	beq ReadDone		; Yes... so done
:	cpy #$00
	bne Read		; Check for page increment
	inc b_p+1		; Increment another page
	dec size+1
	jmp Read		; Go back for more
ReadDone:
	jsr	LOADERRESTORE
ReceiveDriverPad:
	.res	$2144-ReceiveDriverPad, $ea

ReceiveDriverDone:
;MOVE CHARACTER SET TABLE
LDR103:	lda     #$1C		; #$14 ; #>D.CHRSET ; MOVE(SRC.P=D.CHRSET DST.P=$C00 A=0 CNT=$400)
        sta     $22		; SRC.P
        lda     #$58		; #$0F ; #<D.CHRSET
        sta     $23		; SRC.P+1
        lda     #$00
        sta     $24
        lda     #$0C
        sta     $25
        lda     #$00
        sta     $26
        lda     #$04
        sta     $27
        lda     #$00
        jsr     MOVE
; MOVE KEYBOARD TABLE
        lda     #$2c	; #$24		; #>D.KYBD ; MOVE(SRC.P=D.KYBD DST.P=$1700 A=0 CNT=$100.IN)
        sta     $22		; SRC.P
        lda     #$5c	; #$13		; #<D.KYBD
        sta     $23		; SRC.P+1
        lda     #$00
        sta     $24
        lda     #$17
        sta     $25
        lda     #$00
        sta     $26
        lda     #$01
        sta     $27
        lda     #$00
        jsr     MOVE
; RE-INITIALIZE SDT TABLE
        ldy     #$0A		; #>D.DRIVES-D.FILE ; LINK.INIT(A=D.DRIVES DIB1..4.IN, SDT.TBL BLKDLST.IO)
        lda     ($04),y		; (RDBUF.P),Y
        jsr     LINK_INIT	; LINK.INIT
        lda     #$00
        sta     $1625		; CXPAGE+DST.P+1
        sta     $24		; DST.P
        lda     $03		; I.BASE.P+1
        sta     $25		; DST.P+1
        cmp     #$A0		; IF DST.P>=$A000 THEN DST.P:=$A000
        bcc     LDR105
        lda     #$A0
        sta     $25		; DST.P+1
LDR105: lda     $1901		; SYSBANK ; DSTBANK:=SYSBANK
        sta     $2A		; DSTBANK
        jsr     REVERSE		; REVERSE(D.HDR.CNT.IN, WORK.P.OUT)
NEXTDRIVER:
        jsr     DADVANCE
        bcs     LDR140
        jsr     FLAGS
        bvs     NEXTDRIVER
        jsr     GETMEM
        jsr     RELOC
        lda     $2A
        bmi     LDR120
        lda     $1623
        and     #$7F
        sta     $08
        lda     $23
        bpl     LDR110
        inc     $08
LDR110: and     #$7F
        clc
        adc     #$20
        sta     $09
        lda     $24
        cmp     $22
        lda     $25
        sbc     $09
        lda     $2A
        sbc     $08
        bcs     LDR130
LDR120: ldx     #$8F
        ldy     #$15
        jsr     ERROR
LDR130: lda     $2A
        jsr     MOVE
        jsr     LINK
        jmp     NEXTDRIVER
LDR140: jsr     INIT_KRNL
        jsr     ALLOC_SEG
        jsr     ALLOC_DSEG
        lda     #$00
        sta     SCRNMODE
        brk
        dec     $8C
        plp
        cli
        lda     #$00
        sta     $1623
        sta     $1625
        lda     #$04
        sta     $23
        sta     $25
        lda     #$00
        sta     $22
        lda     #$80
        sta     $24
        lda     #$A0
        ldx     #$08
CLEAR0: ldy     #$77
CLEAR1: sta     ($22),y
        sta     ($24),y
        dey
        bpl     CLEAR1
        inc     $23
        inc     $25
        dex
        bne     CLEAR0
WAIT:   inc     $22
        bne     WAIT
        inx
        bne     WAIT
        lda     #$80
        sta     SCRNMODE
        rts
SET_DRIVES:
        tay
        lda     #$B9
        sta     DIB1
        lda     #$E8
        sta     DIB1b
        lda     #$D9
        sta     DIB2
        lda     #$E8
        sta     DIB2b
        lda     #$F9
        sta     DIB3
        lda     #$E8
        sta     DIB3b
        lda     #$00
        cpy     #$02
        bcc     STDR010
        beq     STDR020
        cpy     #$04
        bcc     STDR030
        bcs     STDR040
STDR010:sta     DIB1
        sta     DIB1b
        rts
STDR020:sta     DIB2
        sta     DIB2b
        rts
STDR030:sta     DIB3
        sta     DIB3b
        rts
STDR040:sta     DIB4
        sta     DIB4b
        rts
INIT_KRNL:
        lda     E_REG
        ora     #$44
        sta     E_REG
        lda     #$18
        sta     Z_REG
        jsr     L28F8
        jsr     L298A
        jsr     LB801
        bcs     INITK_ERR
        jsr     L2A05
        jsr     L29F9
        jsr     L2A34
        jsr     L2A20
        jsr     L2A68
        jsr     L29A6
        lda     E_REG
        and     #$BB
        sta     E_REG
        lda     #$1A
        sta     Z_REG
        rts
INITK_ERR:
        ldx     #$08
        ldy     #$09
        jmp     ERROR
ADVANCE:clc
        ldy     #$02
        lda     $0A
        adc     ($0A),y
        tax
        iny
        lda     $0B
        adc     ($0A),y
        pha
        txa
        adc     #$04
        sta     $0A
        pla
        adc     #$00
        sta     $0B
        clc
        lda     $0A
        adc     #$04
        sta     $22
        lda     $0B
        adc     #$00
        sta     $23
        lda     $160B
        sta     $1623
        ldy     #$00
        sty     $1625
        lda     ($0A),y
        sta     $24
        iny
        lda     ($0A),y
        sta     $25
        iny
        lda     ($0A),y
        sta     $26
        iny
        lda     ($0A),y
        sta     $27
        rts
REVERSE:lda     #$08	; #>D.HDR.CNT ; WORK.P:=80:D.HDR.CNT
        sta     $0A
        lda     #$58	; #<D.HDR.CNT ; Looking for memory at $00:0F00, which is $2f00
        sta     $0B
        lda     #$80
        sta     $160B		; XByte on
        clc
        ldy     #$00
        lda     $0A
        adc     ($0A),y
        tax
        iny
        lda     $0B
        adc     ($0A),y
        pha
        txa
        adc     #$02
        sta     $0A
        pla
        adc     #$00
        sta     $0B
        lda     ($0A),y
        dey
        and     ($0A),y
        cmp     #$FF
        bne     REV010
        ldx     #$EB
        ldy     #$11
        jsr     ERROR
REV010:	lda     #$FF
        sta     $0C
        sta     $0D
REV020:	lda     $0C
        pha
        lda     $0D
        pha
        ldy     #$00
        lda     ($0A),y
        sta     $0C
        iny
        lda     ($0A),y
        sta     $0D
        pla
        sta     ($0A),y
        dey
        pla
        sta     ($0A),y
        lda     $0C
        and     $0D
        cmp     #$FF
        beq     REV_EXIT
REV030:	bit     $0D
        bmi     REV040
        clc
        lda     $0A
        adc     $0C
        tax
        lda     $0B
        adc     $0D
        pha
        bcs     REV040
        txa
        adc     #$02
        sta     $0A
        pla
        adc     #$00
        sta     $0B
        bcc     REV020
REV040:	ldx     #$08
        ldy     #$09
        jsr     ERROR
REV_EXIT:
	rts
DADVANCE:
        ldy     #$00
        lda     ($0A),y
        iny
        and     ($0A),y
        cmp     #$FF
        bne     L238B
        sec
        rts
L238B:  lda     $0A
        sta     $1E
        lda     $0B
        sta     $1F
        lda     $160B
        sta     $161F
        jsr     L23C2
        ldy     #$00
        lda     ($0A),y
        sta     $26
        iny
        lda     ($0A),y
        sta     $27
        jsr     L23C2
        clc
        lda     $0A
        adc     #$02
        sta     $22
        lda     $0B
        adc     #$00
        sta     $23
        lda     $160B
        sta     $1623
        jsr     L23C2
        clc
        rts
L23C2:  sec
        ldy     #$00
        lda     $0A
        sbc     ($0A),y
        tax
        iny
        lda     $0B
        sbc     ($0A),y
        pha
        txa
        sbc     #$02
        sta     $0A
        pla
        sbc     #$00
        sta     $0B
        rts
FLAGS:  sec
FLAG010:jsr     NEXT_DIB
        bvc     L23E4
        bcc     FLAG010
        rts
L23E4:  php
        sec
        lda     $14
        sbc     $22
        sta     $10
        lda     $15
        sbc     $23
        sta     $11
        lda     $14
        sta     $12
        lda     $15
        sta     $13
        lda     $1615
        sta     $1613
        plp
        bcs     FLAG100
L2403:  jsr     NEXT_DIB
        php
        ldy     #$00
        bvc     L241C
        sec
        lda     $12
        sbc     $22
        sta     ($12),y
        iny
        lda     $13
        sbc     $23
        sta     ($12),y
        jmp     L2431
L241C:  sec
        lda     $14
        .byte   $E5
L2420:  .byte   $22
        sta     ($12),y
        iny
        lda     $15
        tax
        sbc     $23
        sta     ($12),y
        stx     $13
        lda     $14
        sta     $12
L2431:  plp
        bcc     L2403
FLAG100:clv
        rts
NEXT_DIB:
        ldy     #$00
        bcc     L244F
        sty     $16
        sty     $17
        lda     $22
        sta     $14
        lda     $23
        sta     $15
        lda     $1623
        sta     $1615
        jmp     L245D
L244F:  lda     $22
        adc     ($14),y
        tax
        iny
        lda     $23
        adc     ($14),y
        sta     $15
        stx     $14
L245D:  ldy     #$14
        lda     ($14),y
        bmi     L2468
        bit     NXTD999
        bvs     L247E
L2468:  and     #$40
        beq     L247E
        clc
        lda     #$22
        tay
        dey
        dey
        adc     ($22),y
        sta     $16
        iny
        lda     #$00
        adc     ($22),y
        sta     $17
        clv
L247E:  ldy     #$00
        lda     ($14),y
        iny
        ora     ($14),y
        bne     NXTD998
        sec
        bcs     NXTD999
NXTD998:clc
NXTD999:rts
GETMEM: lda     $2A
        sta     $18
        lda     $24
        sta     $19
        lda     $25
        sta     $1A
        jsr     NEWDST
        lda     $25
        cmp     #$20
        bcc     GETM010
        sec
        lda     $1A
        sbc     $25
        clc
        jsr     BUILD_DSEG
        jmp     GETM_EXIT
GETM010:dec     $2A
        lda     #$00
        sta     $19
        lda     #$A0
        sta     $1A
        jsr     NEWDST
        sec
        lda     $1A
        sbc     $25
        sec
        jsr     BUILD_DSEG
GETM_EXIT:
        rts
NEWDST: sec
        lda     $19
        sbc     #$00
        tax
        lda     $1A
        sbc     #$20
        cpx     $26
        sbc     $27
        bcs     L24DC
        lda     #$00
        sta     $24
        sta     $25
        beq     NEWD_EXIT
L24DC:  sec
        lda     $19
        sbc     $26
        sta     $24
        lda     $1A
        sbc     $27
        sta     $25
        lda     $16
        ora     $17
        beq     NEWD_EXIT
        sec
        lda     #$00
        sbc     $16
        sta     $24
        lda     $25
        sbc     $17
        sta     $25
NEWD_EXIT:
        rts
BUILD_DSEG:
        pha
        bcs     L2505
        lda     L2514
        bpl     L2508
L2505:  inc     L2514
L2508:  ldx     L2514
        clc
        pla
        adc     L2515,x
        sta     L2515,x
        rts
L2514:  .byte   $FF
L2515:  brk
        brk
        brk
        brk
RELOC:  sec
        ldy     #$00
        lda     $1E
        sbc     ($1E),y
        sta     $20
        iny
        lda     $1F
        sbc     ($1E),y
        sta     $21
L2529:  sec
        lda     $1E
        sbc     #$02
        sta     $1E
        lda     $1F
        sbc     #$00
        sta     $1F
        lda     $1E
        cmp     $20
        lda     $1F
        sbc     $21
        bcc     L2569
        ldy     #$00
        clc
        lda     $22
        adc     ($1E),y
        sta     $1C
        iny
        lda     $23
        adc     ($1E),y
        sta     $1D
        lda     $1623
        sta     $161D
        ldy     #$00
        clc
        lda     ($1C),y
        adc     $24
        sta     ($1C),y
        iny
        lda     ($1C),y
        adc     $25
        sta     ($1C),y
        jmp     L2529
L2569:  rts
ALLOC_SEG:
        brk
        rti
        sta     $28
        lda     #$10
        sta     L2886
        sta     L2888
        lda     #$00
        sta     L2887
        ldx     $01
        jsr     L2586
        ldx     $03
        jsr     L2586
        rts
L2586:  inc     L288A
        ldy     L2887
        dey
        sty     L2889
        stx     L2887
        cpx     #$A0
        bcs     L25BB
        lda     L2889
        cmp     #$A0
        bcc     L25BB
        txa
        pha
        ldx     #$A0
        stx     L2887
        brk
        rti
        sta     $28
        pla
        sta     L2887
        lda     #$9F
        sta     L2889
        lda     $1901
        sta     L2886
        sta     L2888
L25BB:  brk
        rti
        sta     $28
        rts
ALLOC_DSEG:
        inc     L2514
        bne     ALDS010
        ldx     #$7A
        ldy     #$13
        jsr     ERROR
ALDS010:ldy     #$FF
ALDS020:iny
        cpy     L2514
        bcs     ALDS_EXIT
        lda     L2515,y
        sta     L287E
        brk
        eor     ($7B,x)
        plp
        jmp     ALDS020
ALDS_EXIT:
        rts
ERROR:  sty     $2E
        sec
        lda     #$28
        sbc     $2E
        lsr     a
        clc
        adc     $2E
        tay
PRNT010:lda     ERR,x
        sta     $07A7,y
        dex
        dey
        dec     $2E
        bne     PRNT010
        lda     #$73
        sta     E_REG
        lda     $C040
DIEDIEDIE:
        jmp     DIEDIEDIE
ERR:    .byte   $49,$2F,$4F,$20,$45,$52,$52,$4F
        .byte   $52,$49,$4E,$54,$45,$52,$50,$52
        .byte   $45,$54,$45,$52,$20,$46,$49,$4C
        .byte   $45,$20,$4E,$4F,$54,$20,$46,$4F
        .byte   $55,$4E,$44,$49,$4E,$56,$41,$4C
        .byte   $49,$44,$20,$49,$4E,$54,$45,$52
        .byte   $50,$52,$45,$54,$45,$52,$20,$46
        .byte   $49,$4C,$45,$49,$4E,$43,$4F,$4D
        .byte   $50,$41,$54,$49,$42,$4C,$45,$20
        .byte   $49,$4E,$54,$45,$52,$50,$52,$45
        .byte   $54,$45,$52,$44,$52,$49,$56,$45
        .byte   $52,$20,$46,$49,$4C,$45,$20,$4E
        .byte   $4F,$54,$20,$46,$4F,$55,$4E,$44
        .byte   $49,$4E,$56,$41,$4C,$49,$44,$20
        .byte   $44,$52,$49,$56,$45,$52,$20,$46
        .byte   $49,$4C,$45,$44,$52,$49,$56,$45
        .byte   $52,$20,$46,$49,$4C,$45,$20,$54
        .byte   $4F,$4F,$20,$4C,$41,$52,$47,$45
        .byte   $52,$4F,$4D,$20,$45,$52,$52,$4F
        .byte   $52,$3A,$20,$20,$50,$4C,$45,$41
        .byte   $53,$45,$20,$4E,$4F,$54,$49,$46
        .byte   $59,$20,$59,$4F,$55,$52,$20,$44
        .byte   $45,$41,$4C,$45,$52,$54,$4F,$4F
        .byte   $20,$4D,$41,$4E,$59,$20,$44,$45
        .byte   $56,$49,$43,$45,$53,$54,$4F,$4F
        .byte   $20,$4D,$41,$4E,$59,$20,$42,$4C
        .byte   $4F,$43,$4B,$20,$44,$45,$56,$49
        .byte   $43,$45,$53,$45,$4D,$50,$54,$59
        .byte   $20,$44,$52,$49,$56,$45,$52,$20
        .byte   $46,$49,$4C,$45
WELCOME:ldy     #$09
WAM010: lda     L2796,y
        sta     $04B6,y
        dey
        bne     WAM010
        clc
        lda     #$28
        adc     #$13
        lsr     a
        tax
        ldy     #$13
WSM010: lda     $198F,y
        ora     #$80
        sta     $05A7,x
        dex
        dey
        bne     WSM010
        brk
        .byte   $63
        .byte   $93
        plp
        lda     L289E
        and     #$0F
        beq     WDM040
        sta     $2F
        asl     a
        adc     $2F
        tax
        ldy     #$03
WDM010: lda     L27B4,x
        sta     L279F,y
        dex
        dey
        bne     WDM010
        lda     L289D
        ldx     L289C
        sta     L27A6
        stx     L27A5
        lda     L289B
        and     #$0F
        ldx     L289A
        cpx     #$31
        bcc     WDM020
        adc     #$09
WDM020: sta     $2F
        asl     a
        adc     $2F
        tax
        ldy     #$03
WDM030: lda     L27C9,x
        sta     L27A7,y
        dex
        dey
        bne     WDM030
        lda     L2899
        ldx     L2898
        sta     L27AD
        stx     L27AC
        lda     L28A0
        ldx     L289F
        sta     L27B1
        stx     L27B0
        lda     L28A2
        ldx     L28A1
        sta     L27B4
        stx     L27B3
        ldy     #$15
WDM050: lda     L279F,y
        ora     #$80
        sta     $06B0,y
        dey
        bne     WDM050
WDM040: ldy     #$28
WCM010: lda     L27ED,y
        sta     $07CF,y
        dey
        bne     WCM010
L2796:  rts
AMSG:   .byte   $C1,$D0,$D0,$CC,$C5,$A0,$AF,$AF
L279F:  .byte   $AF
DMSG:   .byte   $44,$41,$59,$2C,$20
L27A5:  .byte   $44
L27A6:  .byte   $44
L27A7:  .byte   $2D,$4D,$4F,$4E,$2D
L27AC:  .byte   $59
L27AD:  .byte   $59,$20,$20
L27B0:  .byte   $48
L27B1:  .byte   $48,$3A
L27B3:  .byte   $4D
L27B4:  .byte   $4D,$53,$55,$4E,$4D,$4F,$4E,$54
        .byte   $55,$45,$57,$45,$44,$54,$48,$55
        .byte   $46,$52,$49,$53,$41
L27C9:  .byte   $54,$4A,$41,$4E,$46,$45,$42,$4D
        .byte   $41,$52,$41,$50,$52,$4D,$41,$59
        .byte   $4A,$55
L27DB:  .byte   $4E,$4A,$55,$4C,$41,$55,$47,$53
        .byte   $45,$50,$4F,$43,$54,$4E,$4F,$56
        .byte   $44,$45
L27ED:  .byte   $43,$A8,$C3,$A9,$B1,$B9,$B8,$B0
        .byte   $AC,$B1,$B9,$B8,$B1,$AC,$B1,$B9
L27FD:  .byte   $B8,$B2,$A0,$C2,$D9,$A0,$C1,$D0
        .byte   $D0,$CC,$C5,$A0,$C3,$CF,$CD,$D0
        .byte   $D5,$D4,$C5,$D2,$A0,$C9,$CE,$C3
        .byte   $AE
        .byte   $04
        and     ($28,x)
OPEN_REF:
        brk
        ora     $0428,x
        brk
        .byte   $04
        asl     ZPAGE
L2821:  ldy     #$86
        ldy     #$CD
        lda     LA0A0,x
        .byte   $A3
        ldy     #$A0
        txs
        ldy     #$81
        ldy     #$A0
        .byte   $CF
        ldy     #$A0
        sta     ($A0,x)
        ldy     #$95
        ldy     #$A0
        bcc     L27DB
        ldy     #$D0
        ldy     #$85
        ldy     #$A0
        ldy     #$A0
        ldy     #$A5
        ldy     #$A0
        .byte   $83
        ldy     #$A0
        ldy     #$A0
        .byte   $80
        ldy     #$A0
        ldx     LA0A0
        .byte   $F2
        ldy     #$A0
        cmp     ($A0,x)
        ldy     #$85
        ldy     #$A0
        bne     L27FD
        ldy     #$A9
        .byte   $D3
        .byte   $CC
L2861:  .byte   $53
        .byte   $4F
        .byte   $53
        jsr     L544E
        .byte   $52
        .byte   $50
L2869:  .byte   $53
        .byte   $4F
L286B:  .byte   $53
        jsr     L5244
        lsr     $52,x
        .byte   $04
READ_REF:
        brk
        .byte   $04
        brk
        php
        sbc     (ZPAGE),y
        brk
L2879:  .byte   $01
CLOSE_REF:
        brk
        asl     ZPAGE
        .byte   $03
L287E:  brk
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $04
L2886:  .byte   $0F
L2887:  brk
L2888:  .byte   $0F
L2889:  .byte   $1D
L288A:  brk
        brk
        ora     ($8F,x)
        plp
        .byte   $03
        rol     L3144
        ora     ($96,x)
        plp
        .byte   $59
        .byte   $59
L2898:  .byte   $59
L2899:  .byte   $59
L289A:  .byte   $4D
L289B:  .byte   $4D
L289C:  .byte   $44
L289D:  .byte   $44
L289E:  .byte   $57
L289F:  pha
L28A0:  pha
L28A1:  .byte   $4D
L28A2:  eor     L5353
        eor     L4D4D
        ldy     #$CC
        lda     ($A0),y
        sbc     $BF
        ldy     #$CE
        ldy     #$A0
        stx     $A0
        cmp     $A0BD
        ldy     #$A3
        ldy     #$A0
        cmp     $A0
        sta     ($A0,x)
        ldy     #$E5
        ldy     #$A0
        sta     ($A0,x)
        ldy     #$95
        ldy     #$A0
        bcc     L286B
        ldy     #$D0
        ldy     #$85
        ldy     #$A0
        ldy     #$A0
        ldy     #$A5
        ldy     #$A0
        .byte   $83
        ldy     #$A0
        ldy     #$A0
        .byte   $80
        tay
        ldy     #$AE
        ldy     #$A0
        cmp     LA0A0
        cmp     ($A0,x)
        ldy     #$85
        ldy     #$A0
        bne     L289B
        ldy     #$A9
        .byte   $D3
        cpy     $BAA0
        tya
        ldy     #$C6
        stx     $A0
L28F8:  sei
        lda     #$F8
        sta     $DFC4
        lda     E_REG
        pha
        ora     #$C0
        sta     E_REG
        sta     ACIASTAT
        lda     #$FF
        sta     D_DDRB
        sta     D_DDRA
        lda     #$00
        sta     D_ACR
        lda     #$76
        sta     D_PCR
        lda     #$7F
        sta     D_IFR
        sta     D_IER
        lda     #$82
        sta     D_IER
        lda     #$3F
        sta     E_DDRB
        lda     #$0F
        sta     E_DDRA
        lda     #$00
        sta     E_ACR
        lda     #$63
        sta     E_PCR
        lda     #$7F
        sta     E_IFR
        sta     E_IER
        lda     #$FF
        sta     E_IORB
        bit     NOSCROLL
        bit     $C0DA
        bit     $C0DC
        bit     $C0DE
        pla
        sta     E_REG
        lda     #$00
        sta     $1903
        ldy     #$17
L2961:  sta     $DFC5,y
L2964:  dey
        bpl     L2961
        lda     #$80
        sta     $DFCF
        ldx     #$05
L296E:  lda     L297E,x
        sta     NMI_VECTOR,x
        lda     L2984,x
        sta     $FFCA,x
        dex
        bpl     L296E
        rts
L297E:  ldy     $E1
        .byte   $33
        inx
        bvc     L2964
L2984:  jmp     LE1A4
        jmp     LE050
L298A:  ldy     #$2A
        lda     #$00
L298E:  sta     $E025,y
        dey
        bne     L298E
        ldx     #$05
        lda     #$06
        sta     $E028
L299B:  tay
        clc
        adc     #$06
        sta     $E026,y
        dex
        bne     L299B
        rts
L29A6:  lda     #$D0
        sta     $F0
        lda     #$FF
        sta     $F1
        lda     #$8F
        sta     $14F1
        lda     #$A5
        sta     $F2
        ldy     #$00
L29B9:  lda     ($F0),y
        sta     $E4C3,y
        eor     $F2
        sta     $F2
        iny
        cpy     #$0A
        bcc     L29B9
        cmp     ($F0),y
        beq     L29D3
        lda     #$00
L29CD:  dey
        sta     $E4C3,y
        bne     L29CD
L29D3:  lda     E_REG
        pha
        ora     #$80
        sta     E_REG
        lda     #$00
        ldy     Z_REG
        ldx     #$11
        stx     Z_REG
        sta     $C070
        ldx     #$16
        stx     Z_REG
        sta     $C070
        sty     Z_REG
        pla
        sta     E_REG
        rts
L29F9:  lda     #$80
        ldx     #$10
L29FD:  sta     $F358,x
        dex
        bpl     L29FD
        rts
L2A04:  .byte   $C3
L2A05:  ldx     MAX_DNUM
        inc     MAX_DNUM
        stx     L2A04
L2A0E:  lda     #$08
        sta     D_TPARMX
        lda     L2A04
        sta     $C1
        jsr     LEF7D
        dec     L2A04
        bne     L2A0E
        rts
L2A20:  lda     #$FF
        sta     $F56F
        ldx     #$10
        lda     #$80
L2A29:  sta     $F55E,x
        dex
        bne     L2A29
        stx     $F5B3
        clc
        rts
L2A34:  lda     #$00
        sta     $F86F
        lda     #$81
        sta     $F86E
        ldy     #$1F
        lda     #$80
        sta     $F890,y
L2A45:  tya
        ora     #$80
        dey
        sta     $F890,y
        bne     L2A45
        sec
        lda     $1900
        sbc     #$04
        bcc     L2A63
        lsr     a
        lsr     a
        sta     a:$41
        lda     #$FE
        ror     a
        sta     a:$40
        clc
        rts
L2A63:  lda     #$09
        jsr     LEE2A
L2A68:  lda     #$1C
        sta     $BB
        lda     #$1D
        sta     $BD
        lda     #$00
        sta     $BA
        sta     $BC
        sta     $14BB
        sta     $14BD
        tay
L2A7D:  sta     $1000,y
        sta     $1100,y
        sta     ($BA),y
        sta     ($BC),y
        iny
        bne     L2A7D
        ldx     #$3F
L2A8C:  sta     ZPAGE,x
        sta     $DB9F,x
        dex
        bpl     L2A8C
        lda     #$10
        sta     a:$16
        lda     #$1C
        sta     a:$28
        lda     #$B8
        sta     a:$1E
        lda     #$BA
        sta     a:$24
        clc
        rts
        .byte   $8E,$BF,$A0,$CE,$A0,$C5,$86,$A0
        .byte   $CD,$C9,$A0,$A0,$A3,$A0,$A0,$C5
        .byte   $A0,$81,$A0,$A0,$E5,$A0,$A0,$81
        .byte   $A0,$A0,$95,$A0,$A0,$A5,$A0,$A0
        .byte   $D0,$A0,$D1,$A0,$A0,$A0,$A0,$A0
        .byte   $A5,$A0,$A0,$9D,$A0,$A0,$A0,$A0
        .byte   $83,$A8,$A0,$AE,$A0,$A0,$CD,$A0
        .byte   $A0,$C1,$A0,$A0,$85,$A0,$A0,$E0
        .byte   $AE,$A0,$A9,$D3,$99,$A0,$BA,$98
        .byte   $A0,$C6,$86,$A0,$C5,$FD,$00,$19
        .byte   $00,$01,$08,$02,$00,$00,$8F,$19
        .byte   $80,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$4C,$8F,$19,$4C,$CA,$E2
        .byte   $4C,$52,$E3,$4C,$C2,$E3,$4C,$F3
        .byte   $E3,$4C,$1D,$E4,$4C,$A9,$E3,$4C
        .byte   $2A,$EE,$4C,$17,$EE,$4C,$C5,$F5
        .byte   $4C,$86,$F6,$4C,$10,$F7,$4C,$D3
        .byte   $19,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$EA,$68,$68,$60,$4C
        .byte   $10,$19,$4C,$FC,$E3,$00,$4C,$10
        .byte   $E4,$60,$53,$4F,$53,$20,$31,$2E
        .byte   $33,$20,$20,$20,$30,$31,$2D,$4E
        .byte   $4F,$56,$2D,$38,$32,$28,$43,$29
        .byte   $20,$31,$39,$38,$30,$2C,$20,$31
        .byte   $39,$38,$32,$20,$42,$59,$20,$41
        .byte   $50,$50,$4C,$45,$20,$43,$4F,$4D
        .byte   $50,$55,$54,$45,$52,$20,$49,$4E
        .byte   $43,$2E,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$20,$29,$20,$8D
        .byte   $D2,$19,$60,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$B8,$C0,$47,$FE
        inc     $B800
        bmi     L2C19
        jsr     LB89D
        lda     $B89B
        beq     L2C1B
        bcc     L2C19
        jsr     LE3C2
        jsr     LB81D
        inc     $B800
L2C19:  clc
        rts
L2C1B:  sec
        rts
        lda     B_REG
        pha
        lda     $1901
        sta     B_REG
        clc
        lda     $1A02
        adc     #$03
        sta     I
        pha
        lda     $1A03
        adc     #$00
        sta     $EB
        pha
        lda     #$00
        sta     $14EB
        ldy     I
        lda     #$00
        sta     I
        sta     $E8
        jsr     LB869
        pla
        sta     $EB
        pla
        sta     I
        ldy     #$01
        lda     (I),y
        sta     $1A02
        iny
        lda     (I),y
        sta     $1A03
        ldy     #$02
        lda     #$00
L2C5F:  sta     (I),y
        dey
        bpl     L2C5F
        pla
        sta     B_REG
        rts
L2C69:  ldx     #$07
        clc
        lda     $E0
        bpl     L2C71
        sec
L2C71:  rol     $E0,x
        dex
        bpl     L2C71
L2C76:  tya
        and     #$07
        eor     #$02
        tax
        lda     $E0,x
        pha
        and     #$07
        tax
        pla
        clc
        adc     $E8
        clc
        adc     $E0,x
        sta     $E8
        eor     (I),y
        sta     (I),y
        iny
        bne     L2C76
        inc     $EB
        lda     $EB
        cmp     #$B8
        bcc     L2C69
        rts
        .byte   $0B
        sty     $A2
        .byte   $07
        stx     $E9
        ldx     #$60
        lda     MOTORON,x
        lda     E_REG
        ora     #$83
        sta     E_REG
        lda     #$09
        sta     $B89C
        jsr     LED57
L2CB6:  ldx     #$60
        jsr     LB905
        bcs     L2D1A
        lda     $98
        cmp     #$02
        bne     L2CB6
L2CC3:  ldx     #$01
        jsr     LB925
        ldx     $E9
        lda     $9A
        sta     $E0,x
        dec     $E9
        bmi     L2CE6
        inc     $B89C
        lda     $B89C
        ldx     #$60
        jsr     LED57
        ldx     #$60
        jsr     LB905
        bcc     L2CC3
        bcs     L2D1A
L2CE6:  ldx     #$60
        lda     MOTOROFF,x
        lda     E_REG
        and     #$7C
        sta     E_REG
        lda     $98
        cmp     #$06
        bne     L2D01
        lda     $E0
        eor     $E1
        beq     L2D01
        sec
        rts
L2D01:  lda     #$00
        clc
        rts
        jsr     LB910
        bcs     L2D0D
        jmp     LF1B9
L2D0D:  jmp     LF1BD
        lda     LF1B9
        cmp     #$A0
        clc
        beq     L2D19
        sec
L2D19:  rts
L2D1A:  dec     $B89B
        beq     L2D22
        jmp     LB89D
L2D22:  jmp     LB8E6
        ldy     #$00
L2D27:  dey
        bne     L2D27
        dex
        bne     L2D27
        rts
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00,$00,$00,$00,$00,$00,$00
        .byte   $00,$00
        ldx     $A0
        lda     $BCC3,x
        asl     a
        sta     $37
        and     #$3F
        tax
        lda     $BC9F,x
        sta     LDBE1
        lda     $BCA0,x
        sta     $DBE2
        lda     #$11
        sta     $B7
        lda     #$20
        sta     $D957
        ldy     #$0F
        lda     #$00
        sta     $1980
        sta     $D5BB
        sta     $3C
        sta     $C517
        sta     $C51A
        sta     $C51B
L3035:  sta     $14B0,y
        dey
        bpl     L3035
        bcc     L3042
        jsr     LBCD5
        bcs     L3098
L3042:  asl     $37
        bcc     L304B
        jsr     LBE75
        bcs     L3098
L304B:  asl     $37
        bcc     L3054
        ldx     #$38
        jsr     LE656
L3054:  ldx     $A0
        lda     #$E0
        and     $BCC3,x
        beq     L3080
        ldy     #$11
        lda     ($B6),y
        and     #$40
        beq     L3080
        dey
        lda     ($B6),y
        sta     $35
L306A:  jsr     LC90A
        bcc     L3078
        jsr     LDD2F
        bcc     L306A
        lda     #$45
        bne     L3098
L3078:  ldy     #$11
        lda     ($B6),y
        and     #$BF
        sta     ($B6),y
L3080:  jsr     LBC9C
        bcc     L309B
        cmp     #$2E
        bne     L3098
        ldy     #$11
        lda     ($B6),y
        and     #$BF
        bpl     L3093
        ora     #$40
L3093:  sta     ($B6),y
        jmp     LBC00
L3098:  jsr     LEE17
L309B:  rts
        jmp     (LDBE1)
        sbc     (D_TPARMX),y
        adc     ($DA),y
        pla
        cmp     $D910,y
        .byte   $AF
        cld
        dec     $08BF,x
        ldx     $BE3D,y
        bcs     L3080
        .byte   $93
        cld
        .byte   $54
        cmp     ($58),y
        .byte   $D3
        cmp     $D5,x
        eor     #$D6
        .byte   $B2
        cpy     $CC9B
        bcc     L3098
        ror     $A0D8,x
        lda     ($A2,x)
        .byte   $A3
        sty     $05
        asl     $07
        dey
        eor     #$4A
        .byte   $4B
        bit     L4E2D
        .byte   $4F
        bvc     L3126
        lda     $A1
        sta     $B2
        lda     $A2
        sta     $B3
        lda     $14A2
        sta     $14B3
        lda     #$00
        sta     $B0
        sta     $B4
        lda     #$10
        sta     $B1
        sta     $B5
        ldx     #$00
        txa
        sta     ($B0,x)
        tay
        lda     ($B2,x)
        bmi     L316F
        beq     L316F
        sta     $14
        jsr     LBE01
        lda     ($B2,x)
        cmp     #$2F
        beq     L317F
        cmp     #$2E
        bne     L3173
L310A:  lda     ($B2,x)
        cmp     #$2F
        beq     L311C
        iny
        sta     ($B4),y
        jsr     LBE01
        dec     $14
        bne     L310A
        beq     L3121
L311C:  jsr     LBE01
        dec     $14
L3121:  tya
        sta     ($B4,x)
        lda     #$00
L3126:  sta     $C1
        lda     #$10
        sta     $C2
        lda     #$00
        sta     $14C2
        .byte   $20
L3132:  bit     $BF
        bcc     L3141
        cmp     #$45
        bne     L3171
        ldx     $3C
        beq     L3171
        lda     #$57
        rts
L3141:  ldy     #$00
        .byte   $BD
L3144:  brk
        ora     ($99),y
        brk
        .byte   $10
L3149:  inx
        iny
        lda     $1100,x
        sta     $1000,y
        cpy     $1000
        bne     L3149
        ldx     #$00
        stx     $B0
        lda     #$10
        sta     $B1
        lda     $14
        bne     L3166
        clc
        jmp     LBDD6
L3166:  iny
        sty     $B4
        lda     #$00
        ldy     #$10
        bne     L3179
L316F:  lda     #$40
L3171:  sec
        rts
L3173:  lda     a:$15
        ldy     a:$16
L3179:  sta     $B0
        sty     $B1
        bne     L3187
L317F:  dec     $14
        clc
        beq     L31D6
        jsr     LBE01
L3187:  ldy     #$00
        tya
        sta     ($B4,x)
        lda     ($B2,x)
        and     #$7F
        cmp     #$20
        beq     L317F
        cmp     #$5B
        bcc     L319E
        and     #$5F
        cmp     #$5B
        bcs     L316F
L319E:  cmp     #$41
        bcc     L316F
        bcs     L31C6
L31A4:  lda     ($B2,x)
        and     #$7F
        cmp     #$5B
        bcc     L31B2
        and     #$5F
        cmp     #$5B
        bcs     L316F
L31B2:  cmp     #$41
        bcs     L31C6
        cmp     #$3A
        bcs     L31BE
        cmp     #$30
        bcs     L31C6
L31BE:  cmp     #$2F
        beq     L31D6
        cmp     #$2E
        bne     L316F
L31C6:  clc
        iny
        sta     ($B4),y
        dec     $14
        beq     L31D6
        inc     $B2
        bne     L31A4
        inc     $B3
        bne     L31A4
L31D6:  tya
        sta     ($B4,x)
        bcc     L31ED
        cmp     #$10
        bcs     L31FE
        ldy     #$00
        sec
        adc     $B4
        sta     $B4
        bcc     L317F
        lda     #$0E
        jsr     LEE2A
L31ED:  beq     L31F6
        cmp     #$10
        bcs     L31FE
        iny
        lda     #$00
L31F6:  sta     ($B4),y
        lda     ($B0,x)
        beq     L31FE
        clc
        rts
L31FE:  jmp     LBD6F
        inc     $B2
        bne     L3207
        inc     $B3
L3207:  rts
        jsr     LBCD5
        bcc     L321B
        tax
        ldy     #$00
        lda     ($A1),y
        beq     L3216
        txa
        rts
L3216:  sta     a:$15
        clc
        rts
L321B:  lda     $B0
        bne     L31FE
        ldy     $B4
        clc
        lda     ($B0),y
        bne     L322A
        dey
        tya
L3228:  bne     L322D
L322A:  adc     $B4
        tay
L322D:  eor     #$FF
        sta     a:$15
        sta     $B4
L3234:  lda     ($B0),y
        sta     ($B4),y
        dey
        bpl     L3234
        clc
        rts
        clc
        lda     a:$15
        eor     #$FF
        .byte   $69
L3244:  .byte   $02
        cmp     $A3
        bcc     L324C
        lda     #$4F
        rts
L324C:  ldy     #$00
        sta     ($A1),y
        tay
        dey
        beq     L3270
        iny
        ldx     a:$15
        dex
        stx     $B4
        lda     #$10
        sta     $B5
L325F:  lda     #$2F
        sta     ($A1),y
L3263:  dey
        beq     L3273
        lda     ($B4),y
        sta     ($A1),y
        and     #$F0
        beq     L325F
        bne     L3263
L3270:  tya
        sta     ($A1),y
L3273:  clc
        rts
        lda     a:$28
        sta     $BB
        lda     #$00
        sta     $BA
        lda     $29
        sta     $14BB
        ldy     $A1
        bmi     L3301
        dey
        cpy     #$10
        bcs     L32FD
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        bcc     L3296
        inc     $BB
L3296:  sta     $BA
        lda     $A1
        ldy     #$00
        cmp     ($BA),y
        bne     L32F9
        ldy     #$0B
        lda     ($BA),y
        ldx     #$BC
        jsr     LF686
        bcs     L3300
        lda     #$02
        adc     $BD
        sta     $B3
        lda     $BC
        sta     $B2
        lda     $14BD
        sta     $14B3
        ldy     #$01
        lda     ($BA),y
        sta     $DBB4
        sta     $35
        lda     #$00
L32C6:  tax
        lda     $1110,x
        cmp     ($BA),y
        bne     L32EE
        ldy     #$1A
        lda     $111F,x
        cmp     ($BA),y
        bne     L32EC
        lda     $1100,x
        beq     L32EC
        jsr     LBF05
        lda     $111F,x
        beq     L3300
        jsr     LDC51
        bcc     L3300
        lda     #$27
        rts
L32EC:  ldy     #$01
L32EE:  txa
        clc
        adc     #$20
        bcc     L32C6
        lda     #$0A
        jsr     LEE2A
L32F9:  lda     #$00
        sta     ($BA),y
L32FD:  lda     #$43
        sec
L3300:  rts
L3301:  lda     #$58
        sec
        rts
        stx     $B6
        lda     #$11
        sta     $B7
        clc
        rts
        lda     #$E4
        sta     $C3
        lda     #$DB
        sta     $C4
        lda     #$00
        sta     $14C4
        sta     $B7
        lda     #$04
        sta     D_TPARMX
        jsr     LCF3E
        rts
        jsr     LBF0D
        bcs     L337D
        bpl     L3301
        lda     #$00
        sta     $BF78
L3330:  tax
        lda     $1111,x
        bne     L3339
        stx     $BF78
L3339:  lda     $111F,x
        bne     L3346
        lda     $1110,x
        eor     $DBE4
L3344:  beq     L334B
L3346:  lda     $1100,x
        bne     L3393
L334B:  eor     $1100,x
        beq     L3390
        jsr     LBF05
        lda     $1111,x
        bpl     L33A3
        lda     $DBE4
        sta     $35
        txa
        pha
        jsr     LC90A
        bcc     L3379
        cmp     #$45
        beq     L338C
        jsr     LC465
        bcs     L3388
        ldx     #$00
        jsr     LC802
        bcs     L337F
        pla
        ldx     $B6
        rts
        .byte   $A0
L3379:  clc
        pla
        tax
        rts
L337D:  sec
        rts
L337F:  cmp     #$57
        bne     L338C
        tax
        pla
        txa
        sec
        rts
L3388:  pla
        lda     #$52
        rts
L338C:  pla
        jmp     LBFD2
L3390:  jsr     LBF05
L3393:  txa
        clc
        adc     #$20
        bcc     L3330
        ldx     $B7
        bne     L33A3
        ldx     $BF78
        jsr     LBF05
L33A3:  lda     $B7
        beq     L33D2
        lda     $DBE4
        sta     $35
        lda     #$01
        sta     $DBE3
        sta     $36
        lda     #$11
        sta     $B7
        sta     $B1
        lda     #$00
        sta     $14B1
        ldx     $B6
        stx     $B0
        sta     $1100,x
        jsr     LC7AA
        bcs     L33D5
        ldx     $B6
        lda     $1100,x
        beq     L33D2
        rts
L33D2:  lda     #$45
        sec
L33D5:  tax
        lda     $3C
        beq     L33DC
        ldx     #$57
L33DC:  txa
        rts
        lda     $A1
        sta     $C1
        lda     $A2
        sta     $C2
        lda     $14A2
        sta     $14C2
        jsr     LBF0D
        bcc     L33F2
        rts
L33F2:  bmi     L33F9
        lda     #$58
        jmp     LC0CC
L33F9:  lda     $DBE4
        sta     $35
        lda     #$02
        ldx     #$00
        jsr     LC91E
        lda     #$45
        bcc     L340A
        rts
L340A:  lda     #$00
        sta     $B6
        lda     #$11
        sta     $B7
        jsr     LC465
        bcc     L341A
        jmp     LC0CE
L341A:  jsr     LC8F2
        bcc     L3426
        jsr     LC0E9
        bcc     L341A
        bcs     L3457
L3426:  ldy     #$1F
        lda     ($B6),y
        bpl     L343F
        ldy     #$10
        lda     ($B6),y
        cmp     $35
        beq     L3439
        lda     #$57
        jmp     LC0CC
L3439:  jsr     LDC51
        jmp     LC09E
L343F:  ldy     #$10
        lda     ($B6),y
        .byte   $C5
L3444:  and     $F0,x
        .byte   $57
        ldy     #$11
        lda     ($B6),y
        bpl     L3451
        lda     #$57
        bne     L34CC
L3451:  ldy     #$00
        lda     #$00
        sta     ($B6),y
L3457:  lda     $35
        jsr     LDBF6
        bcc     L3461
        lda     #$27
        rts
L3461:  lda     #$00
        sta     $B6
        lda     #$11
        sta     $B7
L3469:  ldy     #$00
        lda     ($B6),y
        beq     L349B
        ldy     #$10
        lda     ($B6),y
        cmp     $35
        bne     L3487
        ldy     #$11
        lda     ($B6),y
        bpl     L349B
        lda     $35
        jsr     LDBF6
        bcc     L3487
        lda     #$27
        rts
L3487:  jsr     LC0E9
        bcc     L3469
L348C:  ldy     #$11
        lda     ($B6),y
        bpl     L349B
        jsr     LC0E9
        bcc     L348C
        lda     #$42
        bne     L34CC
L349B:  jsr     LC88F
L349E:  lda     #$00
        ldy     #$14
        sta     ($B6),y
        iny
        sta     ($B6),y
        sta     $04
        sta     $05
        jsr     LC94C
        ldx     $B6
        ldy     #$00
L34B2:  lda     $1112,x
        sta     ($A5),y
        inx
        iny
        cpy     #$04
        bne     L34B2
        ldy     #$00
        lda     ($B6),y
        tay
L34C2:  lda     ($B6),y
        sta     ($A3),y
        dey
        bpl     L34C2
        clc
        bcc     L34CD
L34CC:  sec
L34CD:  rts
L34CE:  ldy     #$10
        lda     ($B6),y
        cmp     $35
        bne     L34E0
        ldy     #$11
        lda     ($B6),y
        bpl     L34E0
        ora     #$40
        sta     ($B6),y
L34E0:  jsr     LC0E9
        bcc     L34CE
        lda     #$52
        bne     L34CC
        lda     $B6
        clc
        adc     #$20
        sta     $B6
        rts
        inc     $C517
        jsr     LC493
        bcs     L34FD
        lda     #$47
L34FB:  sec
        rts
L34FD:  cmp     #$46
        bne     L34FB
        lda     $0C
        bne     L3509
        lda     #$49
        sec
        rts
L3509:  ldy     #$09
        lda     #$00
L350D:  sta     $A6,y
        dey
        bpl     L350D
        lda     #$01
        sta     $A9
        ldy     $A5
        beq     L352B
        dey
        cpy     #$09
        bcc     L3523
        lda     #$53
        rts
L3523:  lda     ($A3),y
        sta     $A6,y
        dey
        bpl     L3523
L352B:  ldy     #$00
        lda     ($B0),y
        tay
L3530:  lda     ($B0),y
        sta     $DBBA,y
        dey
        bpl     L3530
        lda     $A6
        sta     $DBCA
        lda     $A7
        sta     $DBD9
        lda     $A8
        sta     $DBDA
        lda     #$C3
        sta     $DBD8
        lda     $DBB5
        sta     $DBDF
        lda     $DBB6
        sta     $DBE0
        jsr     LD587
        bcs     L34FB
        lda     $A9
        cmp     #$04
        bcc     L3566
        jmp     LC2E3
L3566:  ldx     #$01
        lda     $AD
        beq     L3570
L356C:  lda     #$48
        sec
        rts
L3570:  lda     $AC
        sta     $DBD1
        lsr     a
        tay
        sta     $01
        lda     $AB
        sta     $DBD0
        ror     a
        sta     ZPAGE
        lda     $AA
        sta     $DBCF
        bne     L358A
        bcc     L3591
L358A:  inc     ZPAGE
        bne     L3591
        iny
        inc     $01
L3591:  tya
        bne     L35A4
        lda     ZPAGE
        bne     L359C
        inc     ZPAGE
        bne     L35B0
L359C:  cmp     #$01
        beq     L35B0
        inx
        iny
        bne     L35B0
L35A4:  inx
        cmp     #$01
        bne     L35AD
        lda     ZPAGE
        beq     L35B0
L35AD:  iny
        inx
        iny
L35B0:  sty     $06
        txa
        asl     a
        asl     a
        asl     a
        asl     a
        ora     $DBBA
        sta     $DBBA
        stx     $07
        tya
        clc
        adc     ZPAGE
        sta     $DBCD
        sta     $04
        lda     $01
        adc     #$00
        sta     $DBCE
        sta     $05
        ldx     $DBB4
        jsr     LC94C
        bcs     L356C
        jsr     LCA9C
        bcs     L3635
        sta     $DBCB
        sta     I_BASE_P
        sty     $DBCC
        sty     $03
        jsr     LC2C4
        jsr     LCB0A
        jsr     LC2D1
        ldx     $07
        dex
        beq     L3640
        dex
        beq     L3637
        ldy     $06
        dey
        sty     $04
        sty     $06
        jsr     LCA6E
        bcs     L3635
        jsr     LCC8C
        bcs     L3635
        lda     #$00
        sta     $0F
L360E:  ldy     $0F
        lda     ($B2),y
        sta     I_BASE_P
        inc     $B3
        lda     ($B2),y
        sta     $03
        dec     $B3
        dec     $06
        beq     L3637
        lda     #$00
        sta     $04
        jsr     LC26D
        bcs     L3635
        jsr     LCC78
        bcs     L3635
        inc     $0F
        jsr     LCC90
        bcc     L360E
L3635:  sec
        rts
L3637:  lda     ZPAGE
        sta     $04
        jsr     LC26D
        bcs     L3635
L3640:  jsr     LCC78
        bcs     L3635
        ldx     #$03
L3647:  lda     $38,x
        sta     $DBD2,x
        dex
        bpl     L3647
        inc     $DBA9
        bne     L3661
        inc     $DBAA
        ldx     #$03
L3659:  lda     $38,x
        sta     $DBDB,x
        dex
        bpl     L3659
L3661:  ldx     $DBB4
        jsr     LCBE4
        bcs     L36E2
        jsr     LC3F0
        rts
        jsr     LC2D1
        lda     $04
        sta     $10
        jsr     LCA6E
        bcs     L3635
        ldy     #$00
        sty     $0E
        lda     ($B2),y
        sta     $C6
        inc     $B3
        lda     ($B2),y
        sta     $C7
        dec     $B3
        jsr     LCC54
        bcs     L3635
        lda     $10
        sta     $04
L3692:  ldy     $0E
        iny
        dec     $04
        beq     L36BC
        sty     $0E
        lda     ($B2),y
        sta     $C6
        inc     $B3
        tax
        bne     L36AD
        cmp     ($B2),y
        bne     L36AD
        lda     #$0C
        jsr     LEE2A
L36AD:  lda     ($B2),y
        sta     $C7
        dec     $B3
        lda     #$12
        sta     $C3
        jsr     LC2BD
        bcc     L3692
L36BC:  rts
        lda     #$09
        sta     D_TPARMX
        jmp     LCF3A
        ldy     #$00
        tya
L36C7:  sta     $1200,y
        sta     $1300,y
        iny
        bne     L36C7
        rts
        ldy     #$00
        tya
L36D4:  sta     ($B2),y
        iny
        bne     L36D4
        inc     $B3
L36DB:  sta     ($B2),y
        iny
        bne     L36DB
        dec     $B3
L36E2:  rts
        cmp     #$0D
        beq     L36EA
        jmp     LC461
L36EA:  lda     $AD
        ora     $AC
        beq     L36F4
L36F0:  lda     #$48
        sec
        rts
L36F4:  lda     $AB
        lsr     a
        tay
        lda     $AA
        bne     L36FE
        bcc     L36FF
L36FE:  iny
L36FF:  tya
        beq     L36FE
        sta     $DBCD
        sta     $04
        asl     a
        sta     $DBD0
        lda     #$00
        sta     $DBCF
        sta     $DBD1
        sta     $05
        jsr     LC94C
        bcs     L36F0
        jsr     LC2C4
        jsr     LCA9C
        bcs     L36E2
        sta     $DBCB
        sta     $10
        sty     $DBCC
        sty     $11
        lda     $C3CF
        sta     $1200
        lda     $C3D0
        sta     $1201
        ldy     #$04
        bne     L3742
L373C:  lda     $DBB7,y
        sta     $1227,y
L3742:  lda     $C3D1,y
        sta     $1220,y
        dey
        bpl     L373C
        lda     $DBA7
        sta     $122A
        lda     $DBBA
        tay
        ora     #$E0
        sta     $1204
        tya
        ora     #$D0
        sta     $DBBA
L3760:  lda     $DBBA,y
        sta     $1204,y
        dey
        bne     L3760
        ldx     #$03
L376B:  lda     $38,x
        sta     $121C,x
        sta     $DBD2,x
        dex
        bpl     L376B
        lda     #$76
        sta     $1214
        dec     $04
        beq     L37AC
        jsr     LC3B4
        bcs     L37CE
        jsr     LC2C4
L3787:  lda     $10
        sta     $1200
        lda     $11
        sta     $1201
        lda     $12
        sta     $10
        lda     $13
        sta     $11
        dec     $04
        beq     L37AC
        jsr     LC3B4
        bcs     L37CE
        lda     #$00
        sta     $1202
        sta     $1203
        beq     L3787
L37AC:  jsr     LC3C3
        bcs     L37CE
        jmp     LC24F
        jsr     LCA9C
        bcs     L37CE
        sta     $1202
        sty     $1203
        sta     $12
        sty     $13
        lda     $10
        sta     $C6
        lda     $11
        sta     $C7
        jmp     LCC54
L37CE:  rts
        brk
        brk
        brk
        brk
        brk
        .byte   $27
        ora     $12A9
        sta     $B5
        lda     #$04
        ldx     $DBB9
L37DF:  clc
L37E0:  dex
        beq     L37EC
        adc     $DBA7
        bcc     L37E0
        inc     $B5
        bcs     L37DF
L37EC:  sta     $B4
        rts
L37EF:  rts
        lda     $38
        beq     L37FE
        ldx     #$03
L37F6:  lda     $38,x
        sta     $DBDB,x
        dex
        bpl     L37F6
L37FE:  lda     $DBD8
        ora     $D957
        sta     $DBD8
        lda     $DBB4
        sta     $35
        lda     $DBB7
        sta     $C6
        lda     $DBB8
        sta     $C7
        jsr     LCC58
        bcs     L37CE
        jsr     LC3D6
        ldy     $DBA7
        dey
L3822:  lda     $DBBA,y
        sta     ($B4),y
        dey
        bpl     L3822
        lda     $DBB5
        cmp     $C6
        bne     L3838
        lda     $DBB6
        cmp     $C7
        beq     L384C
L3838:  jsr     LCC54
        bcs     L37EF
        lda     $DBB5
        sta     $C6
        lda     $DBB6
        sta     $C7
        jsr     LCC58
        bcs     L37EF
L384C:  ldy     #$01
L384E:  lda     $DBA9,y
        sta     $1225,y
        dey
        bpl     L384E
        lda     $DBA6
        sta     $1222
        jsr     LCC54
        rts
        lda     #$4B
L3863:  sec
        rts
        lda     $1200
        cmp     $C3CF
        bne     L3863
        lda     $1201
        cmp     $C3D0
        bne     L3863
        lda     $1204
        and     #$E0
        cmp     #$E0
        bne     L3863
        clc
        rts
        jsr     LC493
        bcs     L3892
        ldy     $DBA7
L3888:  lda     ($B4),y
        sta     $DBBA,y
        dey
        bpl     L3888
        lda     #$00
L3892:  rts
        jsr     LC692
        bcs     L38EF
        ldy     #$00
        lda     ($B0),y
        bne     L38CD
        lda     #$12
        sta     $B5
        lda     #$04
        sta     $B4
        ldy     #$1F
L38A8:  lda     ($B4),y
        sta     $DBBA,y
        dey
        cpy     #$17
        bne     L38A8
L38B2:  lda     $C4B5,y
        sta     $DBBA,y
        dey
        cpy     #$0F
        bne     L38B2
        lda     #$D0
        sta     $DBBA
        lda     #$40
        rts
        brk
        .byte   $02
        brk
        .byte   $04
        brk
        brk
        php
        brk
L38CD:  lda     #$00
        sta     $0C
        sec
L38D2:  lda     #$00
        sta     $08
        jsr     LC64D
        bcc     L38F1
        lda     $09
        sbc     $08
        bcc     L38E9
        bne     L38F4
        cmp     $0A
        beq     L391C
        bne     L38F4
L38E9:  dec     $0A
        bpl     L38F4
L38ED:  lda     #$51
L38EF:  sec
        rts
L38F1:  jmp     LC5D1
L38F4:  sta     $09
        lda     #$12
        sta     $B5
        lda     $1202
        bne     L3904
        cmp     $1203
        beq     L38ED
L3904:  sta     $C6
        lda     $1203
        sta     $C7
        jsr     LCC58
        bcc     L38D2
        rts
L3911:  jmp     LC5B0
L3914:  jmp     LC5C0
        ldy     #$A0
        ldy     #$C7
        .byte   $A0
L391C:  lda     $0C
        bne     L3914
        lda     $1202
        bne     L3911
        cmp     $1203
        bne     L3911
        lda     $C517
        beq     L3914
        lda     $C51A
        ora     $C51B
        beq     L3914
        lda     $CC76
        sta     $10
        lda     $CC77
        sta     $11
        jsr     LC3B4
        bcs     L39C0
        lda     $CC76
        sta     $C518
        lda     $CC77
        sta     $C519
        lda     $1202
        sta     $C6
        lda     $1203
        sta     $C7
        jsr     LC2C4
        lda     $C518
        sta     $1200
        lda     $C519
        sta     $1201
        jsr     LCC54
        bcs     L39CD
        lda     $C51A
        sta     $C6
        ldx     $C51B
        stx     $C7
        jsr     LCC58
        ldy     #$13
        lda     ($AD),y
        sec
        adc     #$00
        sta     ($AD),y
        iny
        lda     ($AD),y
        adc     #$00
        sta     ($AD),y
        ldy     #$16
        lda     ($AD),y
        clc
        adc     #$02
        sta     ($AD),y
        iny
        lda     ($AD),y
        adc     #$00
        sta     ($AD),y
        jsr     LCC54
        lda     $C519
        sta     $C7
        lda     $C518
        sta     $C6
        jsr     LCC58
        jmp     LC51C
        sta     $DBB7
        lda     $1203
        sta     $DBB8
        lda     #$01
        sta     $DBB9
        sta     $0C
L39C0:  ldy     #$00
        lda     ($B0),y
        tay
        iny
        lda     ($B0),y
L39C8:  sec
        beq     L39CE
        lda     #$44
L39CD:  rts
L39CE:  lda     #$46
        rts
        lda     ($B0),y
        sec
        adc     $B0
        tay
        clc
        lda     $1000,y
        beq     L3A36
        sty     $B0
        lda     $B4
        sta     $AD
        lda     $B5
        sta     $AE
        lda     $C6
        sta     $C51A
        lda     $C7
        sta     $C51B
        ldy     #$00
        lda     ($B4),y
        and     #$F0
        cmp     #$D0
        bne     L39C8
        ldy     #$11
        lda     ($B4),y
        sta     $C6
        iny
        sta     $DBB5
        lda     ($B4),y
        sta     $C7
        sta     $DBB6
        jsr     LCC58
        bcs     L3A22
        lda     $1225
        sta     $09
        lda     $1226
        sta     $0A
        lda     $1221
        beq     L3A24
        lda     #$4A
L3A22:  sec
        rts
L3A24:  jsr     LC62A
        jmp     LC4CD
        ldx     #$0A
L3A2C:  lda     $121C,x
        sta     $DBA0,x
        dex
        bpl     L3A2C
        rts
L3A36:  lda     $DBA8
        sec
        sbc     $0B
        adc     #$00
        sta     $DBB9
        lda     $C6
        sta     $DBB7
        lda     $C7
        sta     $DBB8
        clc
        rts
        lda     $DBA8
        sta     $0B
        lda     #$12
        sta     $B5
        lda     #$04
L3A58:  sta     $B4
        bcs     L3A81
        ldy     #$00
        lda     ($B4),y
        bne     L3A6D
        lda     $0C
        bne     L3A81
        jsr     LC636
        inc     $0C
        bne     L3A81
L3A6D:  and     #$0F
        inc     $08
        cmp     ($B0),y
        bne     L3A81
        tay
L3A76:  lda     ($B4),y
        cmp     ($B0),y
        bne     L3A81
        dey
        bne     L3A76
        clc
        rts
L3A81:  dec     $0B
        beq     L3A22
        lda     $DBA7
        clc
        adc     $B4
        bcc     L3A58
        inc     $B5
        clc
        bcc     L3A58
        jsr     LC71E
        bcc     L3A9C
L3A97:  jsr     LC762
        bcs     L3AE8
L3A9C:  lda     #$00
        ldy     #$2A
L3AA0:  sta     $DBB4,y
        dey
        bpl     L3AA0
        ldy     #$10
        lda     ($B6),y
        sta     $35
        sta     $DBB4
        iny
        lda     ($B6),y
        sta     $DB9F
        ldy     #$16
        lda     ($B6),y
        sta     $C6
        sta     $DBB5
        iny
        lda     ($B6),y
        sta     $C7
        sta     $DBB6
        jsr     LCC58
        bcc     L3AD6
        pha
        ldy     #$11
        lda     ($B6),y
        asl     a
        pla
        bcs     L3B05
        bne     L3A97
L3AD6:  jsr     LC706
        beq     L3AE9
        ldy     #$11
        lda     ($B6),y
        bpl     L3A97
        jsr     LDD2F
        bcc     L3A9C
        lda     #$45
L3AE8:  rts
L3AE9:  ldy     #$0F
L3AEB:  lda     $121B,y
        sta     $DB9F,y
        dey
        bne     L3AEB
        lda     $DBA9
        sta     $09
        lda     $DBAA
        sta     $0A
        txa
        sec
        adc     $B0
        sta     $B0
        clc
L3B05:  rts
        ldy     #$00
        lda     ($B0),y
        tay
        tax
        eor     $1204
        and     #$0F
        bne     L3B1D
L3B13:  lda     ($B0),y
        cmp     $1204,y
        bne     L3B1D
        dey
        bne     L3B13
L3B1D:  rts
        lda     #$11
        sta     $B7
        lda     #$00
        sta     $DBB4
        sta     $B6
L3B29:  pha
        tax
        ldy     #$00
        lda     $1100,x
        beq     L3B5B
        cmp     ($B0),y
        bne     L3B5B
        clc
        tay
        txa
        adc     $1100,x
        tax
L3B3D:  lda     ($B0),y
        cmp     $1100,x
        bne     L3B5B
        dex
        dey
        bne     L3B3D
        pla
        sta     $B6
        tax
        lda     $111F,x
        beq     L3B59
        jsr     LDC51
        bcc     L3B59
        lda     #$27
        rts
L3B59:  clc
        rts
L3B5B:  pla
        clc
        adc     #$20
        bcc     L3B29
        rts
        ldx     #$0C
L3B64:  lda     BLKDLST,x
        sta     $DBE3,x
        dex
        bpl     L3B64
        sta     $36
        inx
L3B70:  inx
        stx     $DBE3
        lda     $DBE3,x
        cmp     $DBB4
        beq     L3BD6
        sta     $35
        jsr     LC848
        bcc     L3BB2
        lda     #$00
L3B85:  tax
        lda     $1100,x
        beq     L3BAA
        txa
        clc
        adc     #$20
        bcc     L3B85
        lda     #$00
L3B93:  tax
        lda     $1111,x
        beq     L3BAA
        txa
        clc
        adc     #$20
        bcc     L3B93
        rts
L3BA0:  ldy     #$00
        lda     ($B6),y
        bne     L3B59
        lda     #$57
        sec
        rts
L3BAA:  stx     $B6
        lda     #$02
        ldx     #$00
        beq     L3BC0
L3BB2:  ldy     #$11
        lda     ($B6),y
        bmi     L3BE0
        ldy     #$17
        lda     ($B6),y
        tax
        dey
        lda     ($B6),y
L3BC0:  jsr     LC91E
        bcc     L3BCC
        lda     #$00
        tay
        sta     ($B6),y
        beq     L3BD6
L3BCC:  jsr     LC88F
        bcs     L3BD6
        jsr     LC706
        beq     L3BA0
L3BD6:  ldx     $DBE3
        cpx     $36
        bcc     L3B70
        lda     #$45
        rts
L3BE0:  ldy     #$10
        lda     ($B6),y
        sta     $35
        jsr     LD587
        lda     $D5BB
        beq     L3BD6
        jsr     LC90A
        bcc     L3BD6
        jsr     LC706
        bne     L3BD6
        ldx     #$00
        jsr     LC802
        bcs     L3BD6
        jmp     LC7A0
L3C02:  lda     $1100,x
        beq     L3C0F
        txa
        clc
        adc     #$20
        tax
        bcc     L3C02
        rts
L3C0F:  lda     #$00
        sta     $3C
        stx     $B6
        jsr     LC89A
        bcs     L3C45
        lda     $3C
        bne     L3C41
        ldy     #$1F
        lda     #$01
        sta     ($B6),y
        lda     $35
        jsr     LDBF6
        bcc     L3C2E
        lda     #$27
        rts
L3C2E:  ldy     #$1F
        lda     #$00
        sta     ($B6),y
L3C34:  jsr     LC90A
        bcc     L3C40
        jsr     LDD2F
        bcc     L3C34
        lda     #$45
L3C40:  rts
L3C41:  lda     #$57
        sec
        rts
L3C45:  lda     #$52
        rts
        lda     #$00
L3C4A:  tax
        lda     $1100,x
        beq     L3C5C
        lda     $111F,x
        bne     L3C5C
        lda     $1110,x
        cmp     $35
        beq     L3C82
L3C5C:  txa
        clc
        adc     #$20
        bcc     L3C4A
        rts
        ldx     $B6
        lda     #$00
L3C67:  sta     $B6
        jsr     LC8F2
        bcs     L3C7B
        ldy     #$11
        lda     ($B6),y
        bmi     L3C86
        lda     #$00
        tay
        sta     ($B6),y
        beq     L3C82
L3C7B:  lda     $B6
        clc
        adc     #$20
        bcc     L3C67
L3C82:  clc
L3C83:  stx     $B6
        rts
L3C86:  sta     $3C
        sec
        lda     $B6
        sta     $3E
        bcs     L3C83
        ldy     #$00
        lda     ($B6),y
        beq     L3C9A
        jsr     LC8F2
        bcc     L3CEE
L3C9A:  lda     #$00
        ldy     #$1F
L3C9E:  sta     ($B6),y
        dey
        bpl     L3C9E
        jsr     LC465
        bcs     L3CEE
        jsr     LC863
        bcs     L3CEF
        lda     $1204
        and     #$0F
        tay
        pha
L3CB4:  lda     $1204,y
        sta     ($B6),y
        dey
        bne     L3CB4
        pla
        sta     ($B6),y
        ldy     #$10
        lda     $35
        sta     ($B6),y
        jsr     LCBF8
        lda     $1229
        ldy     #$12
        sta     ($B6),y
        lda     $122A
        iny
        sta     ($B6),y
        ldy     #$16
        lda     $C6
        sta     ($B6),y
        iny
        lda     $C7
        sta     ($B6),y
        ldy     #$1A
        lda     $1227
        sta     ($B6),y
        lda     $1228
        iny
        sta     ($B6),y
        clc
L3CEE:  rts
L3CEF:  jmp     LC929
        lda     $1204
        and     #$0F
        ldy     #$00
        cmp     ($B6),y
        bne     L3D27
        tay
L3CFE:  lda     $1204,y
        cmp     ($B6),y
        bne     L3D27
        dey
        bne     L3CFE
        clc
        rts
        ldx     #$00
        lda     #$02
        jsr     LC91E
        bcs     L3D1B
        jsr     LC8F2
        bcc     L3D1A
        lda     #$00
L3D1A:  rts
L3D1B:  lda     #$45
        rts
        sta     $C6
        stx     $C7
        jsr     LCC58
        bcc     L3D28
L3D27:  sec
L3D28:  rts
        ldx     $B6
        lda     $3E
        sta     $B6
        stx     $3E
        ldy     #$10
        lda     $35
        cmp     ($B6),y
        bne     L3D46
        jsr     LDC51
        lda     #$00
        sta     $3C
        lda     $B6
        sta     $B0
        clc
        rts
L3D46:  lda     $3E
        sta     $B6
        clc
        rts
        ldy     #$15
        lda     ($B6),y
        dey
        ora     ($B6),y
        bne     L3DB1
        dey
        lda     ($B6),y
        tax
        dey
        lda     ($B6),y
        bne     L3D5F
        dex
L3D5F:  txa
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     $0D
        lda     #$00
        sta     $DBE3
        sta     $DBE4
        lda     #$FF
        sta     $0C
        ldy     #$10
        lda     ($B6),y
        tax
        jsr     LCBE4
        bcs     L3DC2
        ldy     #$1A
        lda     ($B6),y
        sta     $C6
        iny
        lda     ($B6),y
        sta     $C7
L3D87:  jsr     LCC58
        bcs     L3DC2
        jsr     LC9C3
        dec     $0D
        bmi     L3D9C
        inc     $C6
        bne     L3D87
        inc     $C7
        jmp     LC987
L3D9C:  ldy     #$1C
        lda     $0C
        bmi     L3DBF
        sta     ($B6),y
        ldy     #$15
        lda     $DBE4
        sta     ($B6),y
        dey
        lda     $DBE3
        sta     ($B6),y
L3DB1:  lda     ($B6),y
        sec
        sbc     $04
        iny
        lda     ($B6),y
        sbc     $05
        bcc     L3DBF
        clc
        rts
L3DBF:  lda     #$48
        sec
L3DC2:  rts
        ldy     #$00
L3DC5:  lda     $1200,y
        beq     L3DCD
        jsr     LC9F5
L3DCD:  lda     $1300,y
        beq     L3DD5
        jsr     LC9F5
L3DD5:  iny
        bne     L3DC5
        bit     $0C
        bpl     L3DF4
        lda     $DBE3
        ora     $DBE4
        beq     L3DF4
        ldy     #$13
        lda     ($B6),y
        sec
        sbc     #$01
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sec
        sbc     $0D
        sta     $0C
L3DF4:  rts
L3DF5:  asl     a
        bcc     L3E00
        inc     $DBE3
        bne     L3E00
        inc     $DBE4
L3E00:  tax
        bne     L3DF5
        rts
        stx     $0D
        pha
        ldx     $B6
        lda     $1113,x
        cmp     $0D
        pla
        bcc     L3E62
        tax
        and     #$07
        tay
        lda     $CA66,y
        sta     $0C
        txa
        lsr     $0D
        ror     a
        lsr     $0D
        ror     a
        lsr     $0D
        ror     a
        sta     $17
        lsr     $0D
        rol     $19
        ldx     $1A
        lda     $21,x
        cmp     $0D
        beq     L3E46
        jsr     LD765
        bcs     L3E61
        lda     $0D
        ldy     #$1C
        sta     ($B6),y
        ldx     $1A
        lda     $1D,x
        jsr     LCC10
        bcs     L3E61
L3E46:  ldy     $17
        lsr     $19
        bcc     L3E4E
        inc     $B9
L3E4E:  lda     $0C
        ora     ($B8),y
        sta     ($B8),y
        bcc     L3E58
        dec     $B9
L3E58:  ldx     $1A
        lda     #$80
        ora     $1C,x
        sta     $1C,x
        clc
L3E61:  rts
L3E62:  lda     #$5A
        sec
        rts
        .byte   $80
        rti
        jsr     L0810
        .byte   $04
        .byte   $02
        ora     ($A9,x)
        brk
        sta     $0E
        jsr     LCA9C
        bcs     L3E95
L3E77:  ldy     $0E
        sta     ($B2),y
        inc     $B3
        lda     $DBE4
        sta     ($B2),y
        dec     $B3
        dec     $04
        beq     L3E9B
        inc     $0E
        ldy     $17
        lda     $19
        bne     L3E96
        jsr     LCAA5
        bcc     L3E77
L3E95:  rts
L3E96:  jsr     LCAB2
        bcc     L3E77
L3E9B:  rts
        jsr     LCB7F
        bcs     L3E95
L3EA1:  ldy     #$00
        sty     $19
L3EA5:  lda     ($B8),y
        bne     L3EC3
        iny
        bne     L3EA5
        inc     $B9
        inc     $19
        inc     $18
L3EB2:  lda     ($B8),y
        bne     L3EC3
        iny
        bne     L3EB2
        dec     $B9
        inc     $18
        jsr     LCB57
        bcc     L3EA1
        rts
L3EC3:  sty     $17
        lda     $18
        sta     $DBE4
        tya
        asl     a
        rol     $DBE4
        asl     a
        rol     $DBE4
        asl     a
        rol     $DBE4
        tax
        lda     ($B8),y
        sec
L3EDB:  rol     a
        bcs     L3EE1
        inx
        bne     L3EDB
L3EE1:  lsr     a
        bcc     L3EE1
        sta     ($B8),y
        stx     $DBE3
        ldx     $1A
        lda     #$80
        ora     $1C,x
        sta     $1C,x
        ldy     #$14
        lda     ($B6),y
        sbc     #$01
        sta     ($B6),y
        bcs     L3F02
        iny
        lda     ($B6),y
        sbc     #$00
        sta     ($B6),y
L3F02:  clc
        lda     $DBE3
        ldy     $DBE4
        rts
L3F0A:  ldy     #$10
        ldx     #$00
        lda     ($B6),y
        cmp     $1D
        beq     L3F1E
        cmp     $23
        beq     L3F20
        jsr     LCB7F
        bcc     L3F0A
        rts
L3F1E:  ldx     #$06
L3F20:  stx     $0C
        ldy     $1C,x
        bpl     L3F33
        stx     $3D
        jsr     LCC4F
        bcs     L3F56
        ldx     $3D
        lda     #$00
        sta     $1C,x
L3F33:  ldx     $0C
        lda     #$00
        sta     $1D,x
        sta     $B2
        sta     $B8
        lda     a:$1E,x
        sta     $B3
        txa
        eor     #$06
        sta     $1A
        tax
        lda     a:$1E,x
        sta     $B9
        lda     $1B
        sta     $14B3
        sta     $14B9
        clc
L3F56:  rts
        ldy     #$13
        lda     ($B6),y
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ldy     #$1C
        cmp     ($B6),y
        beq     L3FB6
        lda     ($B6),y
        clc
        adc     #$01
        sta     ($B6),y
        ldy     #$10
        lda     ($B6),y
        tax
        jsr     LCBE4
        jmp     LCB7F
L3F77:  ldx     #$00
        beq     L3F89
L3F7B:  ldx     #$06
        bne     L3F89
L3F7F:  ldy     #$10
        lda     ($B6),y
        ldx     #$00
        cmp     $1D,x
        bne     L3F95
L3F89:  stx     $1A
        ldy     $1C,x
        bmi     L3F9D
        jsr     LCC10
        bcc     L3F9D
        rts
L3F95:  dex
        bpl     L3FBA
        ldx     #$06
        jmp     LCB85
L3F9D:  ldx     $1A
        ldy     #$1C
        lda     ($B6),y
        asl     a
        sta     $18
        lda     a:$1E,x
        sta     $B9
        lda     $1B
        sta     $14B9
        lda     #$00
        sta     $B8
        clc
        rts
L3FB6:  lda     #$48
        sec
        rts
L3FBA:  sec
        ldx     $1A
        beq     L3FC4
        clc
        bit     $1C
        bpl     L3F77
L3FC4:  bit     $22
        bcc     L3FCE
        bpl     L3F7B
        bit     $1C
        bpl     L3F77
L3FCE:  ldx     #$00
        bcc     L3FD4
        ldx     #$06
L3FD4:  stx     $3D
        jsr     LCC4F
        bcs     L3FE3
        ldx     $3D
        lda     #$00
        sta     $1C,x
        bcc     L3F7F
L3FE3:  rts
        cpx     $1D
        bne     L3FEE
        clc
        bit     $1C
        bmi     L3FCE
        rts
L3FEE:  cpx     $23
        bne     L3FF6
        bit     $22
        bmi     L3FCE
L3FF6:  clc
        rts
        ldy     #$00
        cmp     $1D
        bne     L4005
        bit     $1C
        bmi     L4004
        sty     $1D
L4004:  rts
L4005:  cmp     $23
        bne     L4004
        bit     $22
        bmi     L4004
        sty     $23
        rts
        sta     $1D,x
        lda     a:$1E,x
        sta     $B9
        lda     $1B
        sta     $14B9
        ldy     #$1C
        lda     ($B6),y
        sta     $21,x
        clc
        ldy     #$1A
        adc     ($B6),y
        sta     $1F,x
        iny
        lda     ($B6),y
        adc     #$00
        sta     $20,x
        lda     #$00
        sta     D_TPARMX
        lda     $35
        pha
        lda     $1D,x
        sta     $35
        lda     $1F,x
        sta     $C6
        lda     $20,x
        sta     $C7
        lda     a:$1E,x
        ldx     $1B
        jsr     LCC6A
        pla
        sta     $35
        rts
        lda     #$01
        jmp     LCC32
        lda     #$01
        bne     L405A
        lda     #$00
L405A:  sta     D_TPARMX
        lda     $C6
        sta     $CC76
        lda     $C7
        sta     $CC77
        lda     #$12
        ldx     #$00
        sta     $C3
        stx     $14C3
        lda     #$00
        sta     $C2
        jmp     LCF25
        ldy     #$85
        lda     #$01
        ldx     I_BASE_P
        ldy     $03
        sta     D_TPARMX
        stx     $C6
        sty     $C7
        lda     $B3
        ldx     $14B3
        jmp     LCC6A
        lda     #$01
        bne     L4092
        lda     #$00
L4092:  ldx     $DBCB
        ldy     $DBCC
        jmp     LCC7E
        ldy     #$12
L409D:  lda     ($BA),y
        pha
        iny
        cpy     #$15
        bne     L409D
        lda     #$00
        ldy     #$03
        pha
L40AA:  pla
        sta     ($A2),y
        dey
        bpl     L40AA
        clc
        rts
        jsr     LCCCD
        bcc     L40B8
        rts
L40B8:  ldx     #$02
        ldy     #$17
L40BC:  lda     $2A,x
        cmp     ($BA),y
        bcc     L4109
        bne     L40CA
        dey
        dex
        bpl     L40BC
        bmi     L4109
L40CA:  lda     #$4D
        rts
        lda     $A6
        bne     L40FA
        ldx     #$FD
        ldy     #$12
        lda     $A2
        lsr     a
        bcs     L40EA
        beq     L40FE
L40DC:  lda     ($BA),y
        adc     $A6,x
        sta     $2D,x
        iny
        inx
        bne     L40DC
        bcs     L40FA
        beq     L4107
L40EA:  bne     L40EE
        ldy     #$15
L40EE:  lda     ($BA),y
        sbc     $A6,x
        sta     $2D,x
        iny
        inx
        bne     L40EE
        bcs     L4107
L40FA:  lda     #$4D
        sec
        rts
L40FE:  ldx     #$02
L4100:  lda     $A3,x
        sta     $2A,x
        dex
        bpl     L4100
L4107:  clc
        rts
L4109:  ldy     #$13
        lda     ($BA),y
        and     #$FE
        sta     $DBE3
        iny
        lda     $2B
        sec
        sbc     $DBE3
        sta     $DBE3
        bcc     L412B
        cmp     #$02
        bcs     L412B
        lda     $2C
        cmp     ($BA),y
        bne     L412B
        jmp     LCE54
L412B:  ldy     #$07
        lda     ($BA),y
        beq     L4153
        cmp     #$04
        bcc     L4138
        jmp     LCE84
L4138:  ldy     #$01
        lda     ($BA),y
        sta     $35
        jsr     LD587
        lda     $D5BB
        beq     HELPME
L4146:  jsr     LC90A
        bcc     HELPME
        jsr     LDD2F
        bcc     L4146
        lda     #$45
        rts
L4153:  ldy     #$00
        sta     ($BA),y
        lda     #$43
        sec
        rts
HELPME: ldy     #$07
        lda     ($BA),y
        sta     $07
        ldy     #$08
        lda     ($BA),y
        and     #$40
        beq     L416E
        jsr     LCF84
        bcs     L41CF
L416E:  ldy     #$14
        lda     ($BA),y
        and     #$FE
        sta     $DBE3
        lda     $2C
        sec
        sbc     $DBE3
        bcc     L419B
        cmp     #$02
        bcs     L419B
        ldx     $07
        dex
        bne     L41FD
L4188:  lda     $2B
        lsr     a
        ora     $2C
        bne     L41EB
        ldy     #$0C
        lda     ($BA),y
        sta     $C6
        iny
        lda     ($BA),y
        jmp     LCE4A
L419B:  ldy     #$08
        lda     ($BA),y
        and     #$80
        beq     L41A8
        jsr     LCF94
        bcs     L41CF
L41A8:  ldx     $07
        cpx     #$03
        beq     L41D1
        lda     $2C
        lsr     a
        php
        lda     #$07
        plp
        bne     L4214
        jsr     LCE7B
        dex
        beq     L4188
        jsr     LCEF0
        bcs     L41CF
        ldy     #$0E
        lda     $C6
        sta     ($BA),y
        iny
        lda     $C7
        sta     ($BA),y
        bcc     L41FD
L41CF:  sec
        rts
L41D1:  jsr     LCE7B
        jsr     LCEF0
        bcs     L41CF
        lda     $2C
        lsr     a
        tay
        lda     ($B2),y
        inc     $B3
        cmp     ($B2),y
        bne     L41F0
        cmp     #$00
        bne     L41F0
        dec     $B3
L41EB:  lda     #$03
        jmp     LCE14
L41F0:  sta     $C6
        lda     ($B2),y
        sta     $C7
        dec     $B3
        jsr     LCED8
        bcs     L41CF
L41FD:  lda     $2C
        lsr     a
        lda     $2B
        ror     a
        tay
        lda     ($B2),y
        inc     $B3
        cmp     ($B2),y
        bne     L4244
        cmp     #$00
        bne     L4244
        lda     #$01
        dec     $B3
L4214:  ldy     #$08
        ora     ($BA),y
        sta     ($BA),y
        lsr     a
        lsr     a
        jsr     LCE32
        bcc     L4254
L4221:  sta     ($B2),y
        iny
        bne     L4221
        inc     $B3
L4228:  sta     ($B2),y
        iny
        bne     L4228
        dec     $B3
        jmp     LCE54
        lda     #$00
        tay
L4235:  sta     ($BC),y
        iny
        bne     L4235
        inc     $BD
L423C:  sta     ($BC),y
        iny
        bne     L423C
        dec     $BD
        rts
L4244:  sta     $C6
        lda     ($B2),y
        dec     $B3
        sta     $C7
        jsr     LCECA
        bcs     L4279
        jsr     LCE7B
L4254:  ldy     #$14
        ldx     #$02
L4258:  lda     ($BA),y
        sta     LDBE1,y
        lda     $2A,x
        sta     ($BA),y
        dey
        dex
        bpl     L4258
        clc
        lda     $BC
        sta     $BE
        lda     $2B
        and     #$01
        adc     $BD
        sta     $BF
        lda     $14BD
        sta     $14BF
        rts
L4279:  sec
        rts
        ldy     #$08
        lda     ($BA),y
        and     #$F8
        sta     ($BA),y
        rts
        cmp     #$0D
        beq     L428D
        lda     #$4A
        jsr     LEE17
L428D:  lda     $DBE3
        lsr     a
        sta     $0B
        ldy     #$13
        lda     ($BA),y
        cmp     $2B
        bcc     L42A8
L429B:  ldy     #$00
        jsr     LCEB5
        bcs     L42C4
        inc     $0B
        bpl     L429B
        bmi     L4254
L42A8:  ldy     #$02
        jsr     LCEB5
        bcs     L42C4
        dec     $0B
        bne     L42A8
        beq     L4254
        lda     ($BC),y
        sta     $C6
        iny
        cmp     ($BC),y
        bne     L42C6
        cmp     #$00
        bne     L42C6
        lda     #$4C
L42C4:  sec
        rts
L42C6:  lda     ($BC),y
        sta     $C7
        lda     #$00
        sta     D_TPARMX
        ldx     #$BC
        jsr     LCF0E
        ldy     #$10
        bcc     L42E5
        rts
        lda     #$00
        sta     D_TPARMX
        ldx     #$B2
        jsr     LCF0E
        bcs     L42EF
        ldy     #$0E
L42E5:  lda     $C6
        sta     ($BA),y
        iny
        lda     $C7
        sta     ($BA),y
        clc
L42EF:  rts
        ldx     #$B2
        ldy     #$0C
        lda     #$00
        sta     D_TPARMX
        lda     ($BA),y
        sta     $C6
        iny
        cmp     ($BA),y
        bne     L430A
        cmp     #$00
        bne     L430A
        lda     #$0C
        jsr     LEE2A
L430A:  lda     ($BA),y
        sta     $C7
        lda     ZPAGE,x
        sta     $C2
        jsr     LD5BD
        lda     $01,x
        sta     $C3
        lda     $1401,x
        sta     $14C3
        ldy     #$01
        lda     ($BA),y
        sta     $35
        lda     #$02
        sta     $C5
        sta     $34
        lda     #$67
        sta     $C8
        lda     #$CF
        sta     $C9
        lda     #$00
        sta     $C4
        sta     $14C9
        lda     $35
        sta     $C1
        ldy     #$09
L4340:  lda     D_TPARMX,y
        sta     $CF69,y
        dey
        bpl     L4340
        lda     #$00
        sta     $1980
        .byte   $20
L434F:  adc     $90EF,x
        ora     $C9
        rol     $02F0
        sec
L4358:  rts
L4359:  ldy     #$09
L435B:  lda     $CF69,y
        sta     D_TPARMX,y
        dey
        bpl     L435B
        jmp     LCF49
        .byte   $D4
        cmp     ($A0),y
        sta     $A0
        ldy     #$8D
        ldy     #$80
        ldy     #$A0
        sty     $A0
        ora     ($B1,x)
        tsx
        tax
        jsr     LCBE4
        ldx     #$B2
        ldy     #$0C
        lda     #$01
        jmp     LCEF6
        ldx     #$BC
        ldy     #$10
        lda     #$01
        jsr     LCEF6
        bcs     L43AF
        lda     #$BF
        jmp     LCFA9
        ldy     #$01
        lda     ($BA),y
        tax
        jsr     LCBE4
        ldx     #$B2
        ldy     #$0E
        lda     #$01
        jsr     LCEF6
        bcs     L43AF
        lda     #$7F
        ldy     #$08
        and     ($BA),y
        sta     ($BA),y
L43AF:  rts
        jsr     LC480
        bcc     L43B9
        cmp     #$40
        bne     L43C0
L43B9:  jsr     LD0F6
        bcc     L43C2
L43BE:  lda     #$50
L43C0:  sec
        rts
L43C2:  lda     $BC
        sta     $BA
        lda     $BD
        sta     $BB
        bne     L43D0
        lda     #$42
        sec
        rts
L43D0:  ldy     #$1F
        lda     #$00
L43D4:  sta     ($BA),y
        dey
        bpl     L43D4
        ldy     #$06
L43DB:  lda     $DBB3,y
        sta     ($BA),y
        dey
        bne     L43DB
        lda     $DBBA
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tax
        ldy     #$07
        sta     ($BA),y
        lda     $A7
        beq     L4404
        ldy     #$00
        lda     ($A5),y
        beq     L4404
        and     $DBD8
        cmp     ($A5),y
        beq     L4409
        lda     #$4E
        sec
        rts
L4404:  lda     $DBD8
        and     #$03
L4409:  ldy     #$09
        cpx     #$0D
        bne     L4411
        and     #$01
L4411:  sta     ($BA),y
        and     #$02
        beq     L441B
        lda     $08
        bne     L43BE
L441B:  lda     $DBD7
        beq     L4424
L4420:  lda     #$4A
        sec
        rts
L4424:  cpx     #$04
        bcc     L442C
        cpx     #$0D
        bne     L4420
L442C:  ldy     #$0C
        lda     $DBCB
        sta     ($BA),y
        sta     $C6
        iny
        lda     $DBCC
        sta     ($BA),y
        sta     $C7
        ldy     #$15
L443F:  lda     $DBBA,y
        sta     ($BA),y
        iny
        cpy     #$18
        bne     L443F
        lda     $DBCD
        sta     ($BA),y
        iny
        lda     $DBCE
        sta     ($BA),y
        lda     $A7
        beq     L4480
        cmp     #$01
        beq     L4480
        cmp     #$04
        beq     L4464
        lda     #$53
        sec
        rts
L4464:  ldy     #$01
        lda     ($A5),y
        beq     L4480
        cpx     #$04
        bcc     L4476
        cmp     #$02
        bcs     L447A
L4472:  lda     #$4F
        sec
        rts
L4476:  cmp     #$04
        bcc     L4472
L447A:  jsr     LF622
        bcc     L448D
L447F:  rts
L4480:  lda     #$04
        cpx     #$04
        bcc     L4488
        lda     #$02
L4488:  jsr     LF5C5
        bcs     L447F
L448D:  ldy     #$0B
        sta     ($BA),y
        jsr     LBEA4
        bcs     L44C5
        ldy     #$00
        lda     $0B
        sta     ($BA),y
        ldy     #$1B
        lda     $F2F4
        sta     ($BA),y
        ldy     #$07
        lda     ($BA),y
        cmp     #$04
        bcs     L44D6
        lda     #$FF
        ldy     #$12
L44AF:  sta     ($BA),y
        iny
        cpy     #$15
        bne     L44AF
        ldy     #$02
        lda     #$00
L44BA:  sta     $2A,y
        dey
        bpl     L44BA
        jsr     LCD09
        bcc     L44DB
L44C5:  pha
        ldy     #$0B
        lda     ($BA),y
        jsr     LF710
        ldy     #$00
        lda     #$00
        sta     ($BA),y
        pla
        sec
        rts
L44D6:  jsr     LCECA
        bcs     L44C5
L44DB:  ldy     #$1E
        lda     ($B6),y
        clc
        adc     #$01
        sta     ($B6),y
        ldy     #$11
        lda     ($B6),y
        ora     #$80
        sta     ($B6),y
        ldy     #$00
        lda     ($BA),y
        ldy     #$00
        sta     ($A3),y
        clc
        rts
        lda     a:$28
        sta     $BB
        lda     $29
        sta     $14BB
        lda     #$00
        sta     $BD
        sta     $0B
        sta     $08
L4508:  sta     $BA
        ldx     $BD
        bne     L4510
        inc     $0B
L4510:  ldy     #$00
        lda     ($BA),y
        bne     L4524
        txa
        bne     L4542
        lda     $BA
        sta     $BC
        lda     $BB
        sta     $BD
        jmp     LD142
L4524:  ldy     #$1A
        lda     ($BA),y
        bne     L4542
        ldy     #$06
L452C:  lda     ($BA),y
        cmp     $DBB3,y
        bne     L4542
        dey
        bne     L452C
        inc     $08
        ldy     #$09
        lda     ($BA),y
        and     #$02
        beq     L4542
        sec
        rts
L4542:  lda     $BA
        clc
        adc     #$20
        bcc     L4508
        ldx     $BB
        inc     $BB
        cpx     a:$28
        beq     L4508
        clc
        rts
READ:   clc
        ldy     #$09
        lda     ($BA),y
        and     #$01
        bne     READ1
        lda     #$4E
        sec
        rts
READ1:  ldy     #$12
        lda     ($BA),y
        sta     $2A
        adc     $A4
        sta     $DBE3
        iny
        lda     ($BA),y
        sta     $2B
        adc     $A5
        sta     $DBE4
        iny
        lda     ($BA),y
        sta     $2C
        adc     #$00
        sta     $DBE5
        ldy     #$17
EOFTEST:lda     $DBCE,y
        cmp     ($BA),y
        bcc     READ2
        bne     ADJSTCNT
        dey
        cpy     #$14
        bne     EOFTEST
ADJSTCNT:
        ldy     #$15
        lda     ($BA),y
        sbc     $2A
        sta     $A4
        iny
        lda     ($BA),y
        sbc     $2B
        sta     $A5
        ora     $A4
        bne     READ2
        lda     #$4C
        jsr     LEE17
READ2:  lda     $A4
        sta     $2D
        bne     READ3
        cmp     $A5
        bne     READ3
        sta     $2E
GORDDNE:jmp     LD26B
READ3:  lda     $A5
        sta     $2E
        lda     $A2
        sta     $B0
        ldx     #$A2
        jsr     LD5BD
        sta     $B1
        sty     $14B1
        ldy     #$07
        lda     ($BA),y
        cmp     #$04
        bcc     L45D4
        jmp     LD31E
L45D4:  jsr     LCD09
        bcc     L45DC
        jmp     LD264
L45DC:  jsr     LD27E
        jsr     LD2A2
        bvs     GORDDNE
        bcs     L45D4
        lda     $2E
        lsr     a
        beq     L45D4
        sta     $2F
        ldy     #$08
        lda     ($BA),y
        and     #$40
        bne     L45D4
        sta     $34
        lda     $B0
        sta     $BC
        lda     $B1
        sta     $BD
        lda     $14B1
        sta     $14BD
L4605:  jsr     LCD09
        bcs     L465F
L460A:  inc     $BD
        inc     $BD
        dec     $2E
        dec     $2E
        inc     $2B
        inc     $2B
        bne     L461F
        inc     $2C
        lda     $2C
        eor     #$01
        lsr     a
L461F:  dec     $2F
        bne     L462E
        jsr     LD307
        lda     $2D
        ora     $2E
        beq     READONE
        bne     L45D4
L462E:  bcs     L4605
        lda     $2C
        lsr     a
        lda     $2B
        ror     a
        tay
        lda     ($B2),y
        sta     $C6
        inc     $B3
        cmp     ($B2),y
        bne     L4649
        cmp     #$00
        bne     L4649
        sta     $34
        beq     L464C
L4649:  lda     ($B2),y
        clc
L464C:  dec     $B3
        bcs     L4605
        sta     $C7
        lda     $34
        beq     L4605
        lda     $BD
        sta     $C3
        jsr     LC2BD
        bcc     L460A
L465F:  pha
        jsr     LD307
        pla
        pha
        jsr     LD26B
        pla
        sec
        rts
READONE:ldy     #$00
        sec
        lda     $A4
        sbc     $2D
        sta     ($A6),y
        iny
        lda     $A5
        sbc     $2E
        sta     ($A6),y
        jmp     LCD09
        sec
        lda     $B0
        sbc     $2A
        sta     $B0
        bcs     L4689
        dec     $B1
L4689:  ldy     #$09
        lda     ($BA),y
        and     #$10
        clc
        beq     L4699
        sec
        ldy     #$0A
        lda     ($BA),y
        sta     $30
L4699:  ldy     $2A
        lda     $BC
        sta     $BE
        ldx     $2D
        rts
        txa
        bne     L46AB
        lda     $2E
        beq     L46F0
        dec     $2E
L46AB:  dex
L46AC:  lda     ($BE),y
        sta     ($B0),y
        txa
        beq     L46CC
        bcs     L46DF
L46B5:  dex
        iny
        bne     L46AC
        lda     $BF
        inc     $B1
        inc     $2B
        bne     RDPART3
        inc     $2C
RDPART3:inc     $BF
        eor     $BD
        beq     L46AC
        clv
        bvc     L46F3
L46CC:  lda     $2E
        beq     L46E5
        iny
        bne     L46D9
        lda     $BF
        eor     $BD
        bne     L46DB
L46D9:  dec     $2E
L46DB:  dey
        jmp     LD2B3
L46DF:  lda     ($BE),y
        eor     $30
        bne     L46B5
L46E5:  iny
        bne     L46F0
        inc     $B1
        inc     $2B
        bne     L46F0
        inc     $2C
L46F0:  bit     $D306
L46F3:  sty     $2A
        bvs     L46F8
        inx
L46F8:  stx     $2D
        php
        clc
        tya
        adc     $B0
        sta     $B0
        bcc     L4705
        inc     $B1
L4705:  plp
        rts
        lda     $BC
        sta     $B0
        lda     $BD
        sta     $B1
        lda     $14BD
        sta     $14B1
        ldy     #$0B
        lda     ($BA),y
        ldx     #$BC
        jmp     LF686
L471E:  jsr     LCD09
        bcs     L4755
        jsr     LD27E
        jsr     LD2A2
        bvc     L471E
        jsr     LD26B
        bcc     L4753
        cmp     #$4C
        sec
        bne     L4754
        jsr     LCE54
        jsr     LCE32
        ldy     #$11
        lda     ($BA),y
        pha
        dey
        lda     ($BA),y
        pha
        lda     #$00
        sta     ($BA),y
        iny
        sta     ($BA),y
        tay
        pla
        sta     ($BC),y
        pla
        iny
        sta     ($BC),y
L4753:  clc
L4754:  rts
L4755:  jmp     LD264
        clc
        ldy     #$09
        lda     ($BA),y
        and     #$02
        bne     L4765
        lda     #$4E
        sec
L4764:  rts
L4765:  jsr     LD578
        bcs     L4764
        ldy     #$12
        lda     ($BA),y
        sta     $2A
        adc     $A4
        sta     $DBE3
        iny
        lda     ($BA),y
        sta     $2B
        adc     $A5
        sta     $DBE4
        iny
        lda     ($BA),y
        sta     $2C
        adc     #$00
        sta     $DBE5
        ldy     #$17
L478B:  lda     $DBCE,y
        cmp     ($BA),y
        bcc     L47AB
        bne     L4799
        dey
        cpy     #$14
        bne     L478B
L4799:  clc
        ldy     #$15
L479C:  lda     ($BA),y
        sta     $DBDB,y
        lda     $DBCE,y
        sta     ($BA),y
        iny
        cpy     #$18
        bne     L479C
L47AB:  lda     $A4
        sta     $2D
        bne     L47BA
        cmp     $A5
        bne     L47BA
        sta     $2E
        jmp     LD463
L47BA:  lda     $A5
        sta     $2E
        lda     $A2
        sta     $B0
        lda     $A3
        sta     $B1
        lda     $14A3
        sta     $14B1
        ldy     #$07
        lda     ($BA),y
        cmp     #$04
        bcc     L47D7
        jmp     LD361
L47D7:  jsr     LCD09
        bcs     L4800
        ldy     #$08
        lda     ($BA),y
        and     #$07
        beq     L4856
        ldy     #$00
L47E6:  iny
        lsr     a
        bne     L47E6
        sty     $04
        sta     $05
        jsr     LC94C
        bcs     L4800
        ldy     #$08
        lda     ($BA),y
        and     #$04
        beq     L481E
        jsr     LD4CB
        bcc     L4829
L4800:  pha
        ldy     #$15
L4803:  lda     $DBDB,y
        sta     ($BA),y
        iny
        cpy     #$18
        bne     L4803
        ldy     #$12
L480F:  lda     LDBE1,y
        sta     ($BA),y
        iny
        cpy     #$15
        bne     L480F
        pla
        sec
        rts
L481C:  bvc     L47D7
L481E:  lda     ($BA),y
        and     #$02
        beq     L4829
        jsr     LD505
        bcs     L4800
L4829:  jsr     LD557
        bcs     L4800
        lda     $2C
        lsr     a
        lda     $2B
        ror     a
        tay
        inc     $B3
        lda     $DBE4
        tax
        sta     ($B2),y
        dec     $B3
        lda     $DBE3
        sta     ($B2),y
        ldy     #$10
        sta     ($BA),y
        iny
        txa
        sta     ($BA),y
        ldy     #$08
        lda     ($BA),y
        ora     #$80
        and     #$F8
        sta     ($BA),y
L4856:  ldx     #$B0
        jsr     LD5BD
        jsr     LD27E
        jsr     LD466
        bvc     L481C
        jmp     LCD09
        txa
        bne     L486F
        lda     $2E
        beq     L48AB
        dec     $2E
L486F:  dex
        lda     ($B0),y
        sta     ($BE),y
        txa
        beq     L488D
        iny
        bne     L486F
        lda     $BF
        inc     $B1
        inc     $2B
        bne     L4884
        inc     $2C
L4884:  inc     $BF
        eor     $BD
        beq     L486F
        clv
        bvc     L48AE
L488D:  lda     $2E
        beq     L48A0
        iny
        bne     L489A
        lda     $BF
        eor     $BD
        bne     L489C
L489A:  dec     $2E
L489C:  dey
        jmp     LD477
L48A0:  iny
        bne     L48AB
        inc     $B1
        inc     $2B
        bne     L48AB
        inc     $2C
L48AB:  bit     $D306
L48AE:  sty     $2A
        stx     $2D
        php
        ldy     #$08
        lda     ($BA),y
        ora     #$50
        sta     ($BA),y
        clc
        lda     $2A
        adc     $B0
        sta     $B0
        bcc     L48C6
        inc     $B1
L48C6:  jsr     LDDF4
        plp
        rts
        jsr     LD513
        bcs     L4912
        ldy     #$07
        lda     ($BA),y
        cmp     #$03
        beq     L48DD
        jsr     LD513
        bcs     L4912
L48DD:  jsr     LD557
        bcs     L4912
        lda     $2C
        lsr     a
        tay
        lda     $DBE3
        tax
        sta     ($B2),y
        inc     $B3
        lda     $DBE4
        sta     ($B2),y
        dec     $B3
        ldy     #$0F
        sta     ($BA),y
        txa
        dey
        sta     ($BA),y
        jsr     LCF73
        bcs     L4912
        jmp     LC2D1
        ldy     #$07
        lda     ($BA),y
        cmp     #$01
        beq     L4913
        jsr     LCEF0
        bcc     L48DD
L4912:  rts
L4913:  jsr     LD557
        bcs     L4956
        ldy     #$0C
        lda     ($BA),y
        pha
        lda     $DBE3
        tax
        sta     ($BA),y
        iny
        lda     ($BA),y
        pha
        lda     $DBE4
        sta     ($BA),y
        ldy     #$0F
        sta     ($BA),y
        txa
        dey
        sta     ($BA),y
        ldy     #$00
        inc     $B3
        pla
        sta     ($B2),y
        dec     $B3
        pla
        sta     ($B2),y
        jsr     LCF73
        bcs     L4956
        ldy     #$07
        lda     #$01
        adc     ($BA),y
        sta     ($BA),y
        ldy     #$08
        lda     ($BA),y
        ora     #$08
        sta     ($BA),y
        clc
L4956:  rts
        jsr     LCA9C
        bcs     L4977
        ldy     #$18
        lda     ($BA),y
        clc
        adc     #$01
        sta     ($BA),y
        bcc     L496E
        iny
        lda     ($BA),y
        adc     #$00
        sta     ($BA),y
L496E:  ldy     #$08
        lda     ($BA),y
        ora     #$10
        sta     ($BA),y
        clc
L4977:  rts
        ldy     #$08
        lda     ($BA),y
        and     #$F0
        clc
        bne     L4977
        ldy     #$01
        lda     ($BA),y
        sta     $35
        lda     #$02
        sta     D_TPARMX
        lda     #$00
        sta     $C2
        lda     #$BC
        sta     $C3
        lda     #$D5
        sta     $C4
        lda     #$00
        sta     $14C4
        sta     $1980
        lda     $35
        sta     $C1
        jsr     LEF7D
        bcs     L49B0
        lda     $D5BC
        lsr     a
        lsr     a
        lda     #$2B
        rts
L49B0:  cmp     #$2E
        bne     L49B9
        sta     $D5BB
        clc
        rts
L49B9:  sec
        rts
        sta     $A0
        lda     $01,x
        ldy     $1401,x
        bpl     L49D4
        cmp     #$82
        bcc     L49D4
        cpy     #$8F
        bcs     L49D4
        and     #$7F
        sta     $01,x
        inc     $1401,x
        iny
L49D4:  rts
        lda     $A1
        bne     L4A19
        sta     $D618
        jsr     LD781
L49DF:  lda     #$00
L49E1:  sta     $BA
        ldy     #$1B
        lda     ($BA),y
        cmp     $F2F4
        bcc     L4A00
        ldy     #$00
        lda     ($BA),y
        beq     L4A00
        jsr     LD67F
        bcs     L4A46
        jsr     LD61E
        ldy     $A1
        beq     L4A00
        bcs     L4A46
L4A00:  lda     $BA
        clc
        adc     #$20
        bcc     L49E1
        lda     $BB
        inc     $BB
        cmp     a:$28
        beq     L49DF
        clc
        lda     $D618
        beq     L4A17
        sec
L4A17:  rts
        .byte   $C6
L4A19:  jsr     LD687
        bcs     L4A46
        ldy     #$0B
        lda     ($BA),y
        jsr     LF710
        bcs     L4A46
        lda     #$00
        ldy     #$00
        sta     ($BA),y
        iny
        lda     ($BA),y
        sta     $35
        jsr     LC848
        ldx     $B6
        dec     $111E,x
        bne     L4A44
        lda     $1111,x
        and     #$7F
        sta     $1111,x
L4A44:  clc
        rts
L4A46:  jmp     LD778
        lda     $A1
        bne     L4A87
        sta     $D618
        jsr     LD781
L4A53:  lda     #$00
L4A55:  sta     $BA
        ldy     #$00
        lda     ($BA),y
        beq     L4A64
        jsr     LD67F
        bcs     L4A7C
        bcs     L4A46
L4A64:  lda     $BA
        clc
        adc     #$20
        bcc     L4A55
        lda     $BB
        inc     $BB
        cmp     a:$28
        beq     L4A53
L4A74:  clc
        lda     $D618
        beq     L4A7B
        sec
L4A7B:  rts
L4A7C:  jmp     LD778
        jsr     LBEA0
        bcc     L4A91
        jmp     LD778
L4A87:  lda     #$00
        sta     $D618
        jsr     LBE75
        bcs     L4A7C
L4A91:  ldy     #$09
        lda     ($BA),y
        and     #$02
        beq     L4A74
        ldy     #$1C
        lda     ($BA),y
        bmi     L4AA7
        ldy     #$08
        lda     ($BA),y
        and     #$70
        beq     L4A74
L4AA7:  jsr     LD587
        lda     $D5BB
        beq     L4AB3
        lda     #$2E
        sec
        rts
L4AB3:  ldy     #$08
        lda     ($BA),y
        and     #$40
        beq     L4AC0
        jsr     LCF84
        bcs     L4A7C
L4AC0:  ldy     #$08
        lda     ($BA),y
        and     #$80
        beq     L4ACD
        jsr     LCF94
        bcs     L4A7C
L4ACD:  ldy     #$06
L4ACF:  lda     ($BA),y
        sta     $DBB3,y
        dey
        cpy     #$00
        bne     L4ACF
        lda     $DBB5
        sta     $C6
        lda     $DBB6
        sta     $C7
        lda     $DBB4
        sta     $35
        jsr     LCC58
        bcs     L4A7C
        jsr     LC62A
        lda     $DBB7
        ldy     $DBB8
        cmp     $DBB5
        bne     L4B00
        cpy     $DBB6
        beq     L4B07
L4B00:  sta     $C6
        sty     $C7
        jsr     LCC58
L4B07:  jsr     LC3D6
        jsr     LC485
        ldy     #$18
        lda     ($BA),y
        sta     $DBCD
        iny
        lda     ($BA),y
        sta     $DBCE
        ldy     #$15
L4B1C:  lda     ($BA),y
        sta     $DBBA,y
        iny
        cpy     #$18
        bne     L4B1C
        ldy     #$0C
        lda     ($BA),y
        iny
        sta     $DBCB
        lda     ($BA),y
        sta     $DBCC
        ldy     #$07
        lda     ($BA),y
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $DBE3
        lda     $DBBA
        and     #$0F
        ora     $DBE3
        sta     $DBBA
        jsr     LC3F0
        bcs     L4B78
        ldy     #$1C
        lda     ($BA),y
        and     #$7F
        sta     ($BA),y
        ldx     #$00
        lda     $DBB4
        cmp     $1D
        beq     L4B65
        ldx     #$06
        cmp     $23
        bne     L4B76
L4B65:  lda     $1C,x
        bpl     L4B76
        stx     $1A
        jsr     LCC4F
        bcs     L4B78
        ldx     $1A
        lda     #$00
        sta     $1C,x
L4B76:  clc
        rts
L4B78:  ldx     $A1
        bne     L4B80
        clc
        sta     $D618
L4B80:  rts
        lda     $29
        sta     $14BB
        lda     a:$28
        sta     $BB
        rts
L4B8C:  lda     #$4E
        sec
L4B8F:  rts
        ldy     #$07
        lda     ($BA),y
        cmp     #$04
        bcs     L4B8C
        ldy     #$09
        lda     ($BA),y
        and     #$02
        beq     L4B8C
        jsr     LD578
        bcs     L4B8C
        ldy     #$17
        ldx     #$02
L4BA9:  lda     ($BA),y
        sta     $DBF0,x
        dey
        dex
        bpl     L4BA9
        jsr     LCCCD
        bcs     L4B8F
        ldx     #$02
L4BB9:  lda     $2A,x
        sta     $A3,x
        dex
        bpl     L4BB9
        ldy     #$14
        ldx     #$02
L4BC4:  lda     ($BA),y
        cmp     $A3,x
        bcc     L4BD5
        bne     L4BD0
        dey
        dex
        bpl     L4BC4
L4BD0:  jsr     LCD09
        bcs     L4B8F
L4BD5:  ldx     #$02
        ldy     #$17
L4BD9:  lda     $A3,x
        sta     ($BA),y
        dey
        dex
        bpl     L4BD9
        jsr     LDDF4
        ldx     #$02
L4BE6:  lda     $DBF0,x
        cmp     $A3,x
        bcc     L4BF2
        bne     L4BF8
        dex
        bpl     L4BE6
L4BF2:  jmp     LD776
L4BF5:  jmp     LD87B
L4BF8:  ldy     #$07
        lda     ($BA),y
        cmp     #$01
        beq     L4C3B
        cmp     #$03
        beq     L4BF5
        jsr     LCB7F
        ldx     $2C
        ldy     $2B
        lda     $2A
        bne     L4C19
        cpy     #$00
        bne     L4C18
        cpx     #$00
        beq     L4C19
        dex
L4C18:  dey
L4C19:  txa
        lsr     a
        tya
        ror     a
        jsr     LD83D
        ldy     #$08
        lda     ($BA),y
        ora     #$80
        sta     ($BA),y
        lda     $D879
        clc
        adc     #$02
        ldy     #$18
        sta     ($BA),y
        iny
        lda     #$00
        bcc     L4C39
        lda     #$01
L4C39:  sta     ($BA),y
L4C3B:  clc
        rts
        tay
L4C3E:  sty     $D879
L4C41:  iny
        beq     L4C78
        inc     $B3
        lda     ($B2),y
        tax
        lda     #$00
        sta     ($B2),y
        txa
        dec     $B3
        ora     ($B2),y
        beq     L4C41
        lda     ($B2),y
        pha
        lda     #$00
        sta     ($B2),y
        pla
        sty     $D87A
        jsr     LCA04
        ldy     #$14
        clc
        lda     ($B6),y
        adc     #$01
        sta     ($B6),y
        iny
        lda     ($B6),y
        adc     #$00
        sta     ($B6),y
        ldy     $D87A
        jmp     LD841
L4C78:  rts
        bcc     L4C3E
        jmp     LD83B
        ldy     #$15
        ldx     #$00
L4C82:  lda     ($BA),y
        sta     ($A2,x)
        iny
        cpy     #$18
        beq     L4CAD
        inc     $A2
        bne     L4C82
        inc     $A3
        bne     L4C82
        ldy     #$09
        lda     $A2
        bpl     L4CA7
        lda     #$10
        ora     ($BA),y
        sta     ($BA),y
        ldy     #$0A
        lda     $A3
        sta     ($BA),y
        clc
        rts
L4CA7:  lda     #$EF
        and     ($BA),y
        sta     ($BA),y
L4CAD:  clc
        rts
        jsr     LC480
        bcc     L4CEB
        cmp     #$40
        sec
        bne     L4D0F
        lda     #$F0
        sta     $DBBA
        lda     #$00
        sta     $04
        sta     $05
        jsr     LC94C
        ldy     #$15
        lda     ($B6),y
        sta     $05
        dey
        lda     ($B6),y
        sta     $04
        dey
        lda     ($B6),y
        sta     $DBDA
        tax
        dey
        lda     ($B6),y
        sta     $DBD9
        sec
        sbc     $04
        sta     $DBCD
        txa
        sbc     $05
        sta     $DBCE
L4CEB:  ldy     #$00
L4CED:  lda     $D958,y
        bpl     L4D03
        and     #$7F
        beq     L4D07
        cmp     #$01
        bne     L4D0E
        lda     $DBBA
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        bpl     L4D07
L4D03:  tax
        lda     $DBBA,x
L4D07:  sta     ($A3),y
        iny
        cpy     $A5
        bne     L4CED
L4D0E:  clc
L4D0F:  rts
        jsr     LC480
        bcs     L4D84
        lda     $A5
        beq     L4D3A
        ldy     #$00
        lda     ($A3),y
        and     #$1C
        beq     L4D25
        lda     #$4E
        sec
        rts
L4D25:  lda     $19D2
        sta     $D957
L4D2B:  ldx     $D958,y
        bmi     L4D3D
        lda     ($A3),y
        sta     $DBBA,x
        iny
        cpy     $A5
        bne     L4D2B
L4D3A:  jmp     LC3F0
L4D3D:  ldy     $A5
        cpy     #$0F
        bcc     L4D3A
        ldy     #$0B
L4D45:  ldx     $D958,y
        bmi     L4D54
        lda     ($A3),y
        .byte   $9D
L4D4D:  tsx
        .byte   $DB
        iny
        cpy     $A5
        bne     L4D45
L4D54:  jmp     LC3FE
        ldy     #$1E
        bpl     L4D7A
        jsr     L1581
        asl     $17,x
        .byte   $80
        .byte   $13
        .byte   $14
        and     ($22,x)
        .byte   $23
        bit     $FF
        jsr     LC493
        bcc     L4D9F
        cmp     #$40
        bne     L4DB9
        jsr     LDA41
        bcs     L4DB9
        lda     $B4
        cmp     $B0
L4D7A:  bne     L4DEE
        ldy     #$11
        lda     ($B6),y
        bpl     L4D85
        lda     #$50
L4D84:  rts
L4D85:  ldy     #$00
        lda     ($B4),y
        tay
        ora     #$F0
        jsr     LDA33
        bcs     L4DB9
        ldy     #$00
        lda     ($B4),y
        tay
L4D96:  lda     ($B4),y
        sta     ($B6),y
        dey
        bpl     L4D96
        clc
        rts
L4D9F:  jsr     LDA41
        bcs     L4DB9
        ldy     #$00
        lda     ($B0),y
        tay
L4DA9:  lda     ($B0),y
        cmp     ($B6),y
        bne     L4DEE
        dey
        bpl     L4DA9
        jsr     LC493
        bcs     L4DBB
        lda     #$47
L4DB9:  sec
        rts
L4DBB:  cmp     #$46
        bne     L4DB9
        ldx     #$02
L4DC1:  lda     $DBB4,x
        sta     $31,x
        dex
        bpl     L4DC1
        jsr     LBCD5
        bcs     L4DB9
        jsr     LC480
        bcs     L4DB9
        jsr     LD0F6
        lda     #$50
        bcs     L4DB9
        lda     $DBD8
        and     #$40
        bne     L4DE5
        lda     #$4E
        sec
        rts
L4DE5:  ldx     #$02
L4DE7:  lda     $DBB4,x
        cmp     $31,x
        beq     L4DF2
L4DEE:  lda     #$40
        sec
        rts
L4DF2:  dex
        bpl     L4DE7
        jsr     LDA41
        bcs     L4DB9
        tya
        beq     L4DEE
        dey
L4DFE:  lda     ($B4),y
        sta     $DBBA,y
        dey
        bne     L4DFE
        lda     $DBBA
        and     #$F0
        tax
        ora     ($B4),y
        sta     $DBBA
        cpx     #$D0
        bne     L4E30
        lda     $DBCB
        sta     $C6
        lda     $DBCC
        sta     $C7
        jsr     LCC58
        bcs     L4DB9
        ldy     #$00
        lda     ($B4),y
        tay
        ora     #$E0
        .byte   $20
        .byte   $33
L4E2D:  .byte   $DA
        bcs     L4DB9
L4E30:  jmp     LC3FE
        sta     $1204
L4E36:  lda     ($B4),y
        sta     $1204,y
        dey
        bne     L4E36
        jmp     LCC54
        lda     $A3
        sta     $B2
        lda     $A4
        sta     $B3
        lda     $14A4
        sta     $14B3
        jmp     LBCE3
        ldy     #$00
L4E54:  sty     $0E
        lda     $1200,y
        cmp     $1300,y
        bne     L4E62
        cmp     #$00
        beq     L4E6C
L4E62:  ldx     $1300,y
        jsr     LCA04
        bcs     L4E70
        ldy     $0E
L4E6C:  iny
        bne     L4E54
        clc
L4E70:  rts
        jsr     LC480
        bcs     L4EC1
        jsr     LD0F6
        lda     $08
        beq     L4E81
        lda     #$50
        sec
        rts
L4E81:  lda     #$00
        sta     $04
        sta     $05
        jsr     LC94C
        bcc     L4E91
        cmp     #$48
        sec
        bne     L4EC1
L4E91:  lda     $DBD8
        and     #$80
        bne     L4E9D
        lda     #$4E
        jsr     LEE17
L4E9D:  jsr     LD587
        bcs     L4EC1
        lda     $DBBA
        and     #$F0
        cmp     #$40
        bcc     L4EAE
        jmp     LDB4F
L4EAE:  jsr     LCB0A
        bcs     L4EC1
        lda     $DBBA
        and     #$F0
        cmp     #$30
        bne     L4EC2
        jsr     LCC90
        bcc     L4ED9
L4EC1:  rts
L4EC2:  cmp     #$20
        bne     L4F13
        jsr     LC2D1
        lda     $DBCB
        ldy     #$00
        sta     ($B2),y
        inc     $B3
        lda     $DBCC
        sta     ($B2),y
        dec     $B3
L4ED9:  ldy     #$00
L4EDB:  sty     $0F
        lda     ($B2),y
        inc     $B3
        cmp     ($B2),y
        bne     L4EE9
        cmp     #$00
        beq     L4EF0
L4EE9:  clc
        sta     $C6
        lda     ($B2),y
        sta     $C7
L4EF0:  dec     $B3
        bcs     L4F10
        jsr     LCC58
        bcs     L4EC1
        jsr     LDA52
        bcs     L4EC1
        ldy     $0F
        inc     $B3
        lda     ($B2),y
        tax
        dec     $B3
        lda     ($B2),y
        jsr     LCA04
        bcs     L4EC1
        ldy     $0F
L4F10:  iny
        bne     L4EDB
L4F13:  lda     $DBCB
        ldx     $DBCC
        jsr     LCA04
        bcs     L4EC1
        lda     #$00
        sta     $DBBA
        cmp     $DBA9
        bne     L4F2B
        dec     $DBAA
L4F2B:  dec     $DBA9
        ldx     $1A
        jsr     LD765
        bcs     L4EC1
        ldy     #$14
        lda     $DBCD
        adc     ($B6),y
        sta     ($B6),y
        iny
        lda     $DBCE
        adc     ($B6),y
        sta     ($B6),y
        lda     #$00
        ldy     #$1C
        sta     ($B6),y
        jmp     LC3F0
        cmp     #$D0
        beq     L4F58
        lda     #$4A
        jsr     LEE17
L4F58:  jsr     LCB7F
        bcs     L4F9E
        lda     $DBCB
        sta     $C6
        lda     $DBCC
        sta     $C7
        jsr     LCC58
        bcs     L4F9E
        lda     $1225
        bne     L4F76
        lda     $1226
        beq     L4F7B
L4F76:  lda     #$4E
        jsr     LEE17
L4F7B:  lda     $1202
        cmp     $1203
        bne     L4F87
        cmp     #$00
        beq     L4F13
L4F87:  ldx     $1203
        jsr     LCA04
        bcs     L4F9E
        lda     $1202
        sta     $C6
        lda     $1203
        sta     $C7
        jsr     LCC58
        bcc     L4F7B
L4F9E:  rts
        ldy     #$A0
        ldy     #$F9
        ldy     #$95
        lda     ($AE,x)
        ldy     #$A0
        cpy     $80D3
        ldx     $E5,y
        ldy     #$81
        txs
        ldy     #$D3
        ldy     #$94
        ldy     #$D2
        ldy     #$D5
        dey
        ldy     #$D5
        tya
        ldy     #$F0
        sta     $CCD3,y
        ldy     #$BA
        ldy     #$A0
        dec     $A0
        ldy     #$C5
        ldy     #$CF
        .byte   $D3
        ldy     #$CC
        ldy     #$C9
        ldy     $96
        ldy     #$D3
        ldx     $C8C3
        tax
        ldy     #$A0
        ldy     #$C5
        sta     $A0
        ldy     #$A0
        stx     $BFAE
        ldy     #$A0
        cmp     $C9A0
        cmp     ($A0,x)
        txs
        ldy     #$A0
        .byte   $FF
        sty     $A0
        .byte   $FF
        .byte   $BF
        txs
        ldy     #$CE
        tax
        jsr     LDC9C
        stx     $35
        jsr     LC848
        bcs     L5045
        ldy     #$11
        lda     ($B6),y
        bpl     L504A
        lda     $35
        ldx     #$00
        cmp     $1D,x
        beq     L5018
        ldx     #$06
        cmp     $1D,x
        beq     L5018
        jmp     LDC33
L5018:  lda     $1C,x
        bpl     L5033
L501C:  jsr     LC90A
        bcc     L502E
        jsr     LDD2F
        bcc     L501C
        jsr     LDD9B
        jsr     LDCB6
        sec
        rts
L502E:  ldx     $35
        jsr     LCBE4
L5033:  lda     $B6
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sec
        ora     #$80
        pha
        jsr     LDCD0
        pla
        ldy     #$1F
        sta     ($B6),y
L5045:  jsr     LDCB6
        clc
        rts
L504A:  lda     #$00
        sta     $1100,x
        beq     L5045
        jsr     LDC9C
        ldy     #$00
        lda     ($B6),y
        beq     L5092
        ldy     #$1F
        lda     ($B6),y
        beq     L5092
        ldy     #$10
        lda     ($B6),y
        sta     $35
        pha
        jsr     LDBFC
        pla
        sta     $35
L506D:  jsr     LC90A
        bcc     L507F
        jsr     LDD2F
        bcc     L506D
        jsr     LDD9B
        jsr     LDCB6
        sec
        rts
L507F:  ldy     #$1F
        lda     ($B6),y
        pha
        lda     #$00
        sta     ($B6),y
        pla
        clc
        jsr     LDCD0
        lda     $35
        jsr     LCBF8
L5092:  jsr     LDCB6
        clc
        rts
        ldy     #$A0
        txs
        ldy     #$C9
        lda     $B6
        sta     $DC97
        lda     $B7
        sta     $DC98
        lda     $BA
        sta     $DC99
        lda     $BB
        sta     $DC9A
        lda     $35
        sta     $DC9B
        rts
        lda     $DC97
        sta     $B6
        lda     $DC98
        sta     $B7
        lda     $DC99
        sta     $BA
        lda     $DC9A
        sta     $BB
        lda     $DC9B
        sta     $35
        rts
        tax
        ldy     a:$28
        sty     $BB
        ldy     #$00
        sty     $BA
        bcs     L50F4
        jsr     LDD0B
        bcs     L510A
        ldy     #$1A
        txa
        cmp     ($BA),y
        bne     L50EC
        lda     #$00
        sta     ($BA),y
L50EC:  jsr     LDD1B
        bcs     L510A
        jmp     LDCDC
L50F4:  jsr     LDD0B
        bcs     L510A
        ldy     #$1A
        lda     ($BA),y
        bne     L5102
        txa
        sta     ($BA),y
L5102:  jsr     LDD1B
        bcs     L510A
        jmp     LDCF4
L510A:  rts
L510B:  ldy     #$01
        lda     ($BA),y
        cmp     $35
        bne     L511B
        ldy     #$00
        lda     ($BA),y
        beq     L511B
        clc
        rts
L511B:  lda     $BA
        clc
        adc     #$20
        sta     $BA
        bcc     L510B
        lda     $BB
        inc     $BB
        cmp     a:$28
        beq     L510B
L512D:  sec
        rts
        ldy     #$00
        lda     ($B6),y
        beq     L512D
        ldx     #$0E
        lda     #$00
L5139:  sta     $DE32,x
        sta     $DE13,x
        dex
        bpl     L5139
        lda     #$05
        sta     D_TPARMX
        lda     $35
        sta     $C1
        lda     #$31
        sta     $C2
        lda     #$DE
        sta     $C3
        lda     #$8F
        sta     $14C3
        lda     #$00
        sta     $14C2
        sta     $C4
        sta     $C5
        sta     $C6
        sta     $DE03
        jsr     LCF3E
        lda     #$20
        sta     $DE31
        ldy     #$00
        lda     ($B6),y
        sta     $3D
        lda     #$00
        tax
        ldy     #$01
L5178:  lda     ($B6),y
        sta     $DE13,x
        inx
        iny
        dec     $3D
        bne     L5178
L5183:  ldx     #$04
        ldy     #$DE
        jsr     LDE66
        jsr     LC90A
        bcs     L5190
        rts
L5190:  inc     $DE03
        lda     $DE03
        cmp     #$03
        bcc     L5183
        rts
        ldy     #$10
        lda     ($B6),y
        sta     $35
        ldy     #$1F
        lda     ($B6),y
        sta     $3D
        lda     #$00
        ldy     #$00
        sta     ($B6),y
        ldy     #$1F
        sta     ($B6),y
        ldy     a:$28
        sty     $BB
        ldy     #$00
        sty     $BA
L51BA:  ldy     #$01
        lda     ($BA),y
        cmp     $35
        bne     L51E1
        ldy     #$00
        lda     ($BA),y
        beq     L51E1
        ldy     #$1A
        lda     ($BA),y
        cmp     $3D
        bne     L51E1
        ldy     #$0B
        lda     ($BA),y
        jsr     LF710
        ldy     #$1A
        lda     #$00
        sta     ($BA),y
        ldy     #$00
        sta     ($BA),y
L51E1:  lda     $BA
        clc
        adc     #$20
        sta     $BA
        bcc     L51BA
        lda     $BB
        inc     $BB
        cmp     a:$28
        beq     L51BA
        rts
        sty     $3D
        pha
        ldy     #$1C
        lda     ($BA),y
        ora     #$80
        sta     ($BA),y
        pla
        ldy     $3D
        rts
        cpy     L6E49
        .byte   $73
        adc     $72
        .byte   $74
        jsr     L6F76
        jmp     (L6D75)
        adc     $3A
        jsr     LA0A0
        stx     $A0,y
        ldy     #$9E
        ldy     #$A0
        .byte   $9F
        ldy     #$9D
        .byte   $9E
        dec     $A0A4
        ora     L2020
        jsr     L6920
        ror     L6420
        adc     $76
        adc     #$63
        adc     $3A
        jsr     LA0A0
        ldy     $8EA0
        .byte   $BF
        ldy     #$E8
        ldy     #$A0
        stx     $A0
        ldy     #$C9
        ldy     #$0D
        .byte   $74
        pla
L5244:  adc     $6E
        jsr     L7270
        adc     $73
        .byte   $73
        jsr     L6874
        adc     $20
        eor     ($4C,x)
        bvc     L529D
        eor     ($20,x)
        jmp     L434F
        .byte   $4B
        jsr     L656B
        adc     $7420,y
        .byte   $77
        adc     #$63
        adc     $FF
        php
        sei
        lda     Z_REG
        sta     $02A8
        lda     #$02
        sta     Z_REG
        stx     ZPAGE
        sty     $01
        lda     E_REG
        sta     $A9
        and     #$5F
        ora     #$40
        sta     E_REG
        lda     SCRNMODE
        sta     $AA
        lda     #$00
        sta     SCRNMODE
        bit     $C050
        bit     $C052
        bit     $C054
        bit     $C056
        ldx     E_ACR
        txa
L529D:  and     #$20
        sta     $AB
        txa
        ora     #$20
        sta     E_ACR
        ldx     E_PCR
        txa
        and     #$F0
        sta     $AC
        txa
        and     #$0F
        ora     #$60
        sta     E_PCR
        lda     E_IER
        and     #$38
        sta     E_IER
        sta     $AD
        plp
        ldx     #$03
L52C4:  jsr     LDFA7
        ldy     #$27
L52C9:  lda     ($04),y
        sta     ($06),y
        lda     #$A0
        sta     ($04),y
        dey
        bpl     L52C9
        dex
        bpl     L52C4
        bit     $C040
        ldx     #$00
        stx     I_BASE_P
L52DE:  jsr     LDFA7
        ldy     #$00
        sty     $03
L52E5:  ldy     I_BASE_P
        inc     I_BASE_P
        lda     (ZPAGE),y
        beq     L52E5
        bmi     L5304
        cmp     #$0D
        beq     L52FF
        ldy     $03
        inc     $03
        ora     #$80
        sta     ($04),y
        cpy     #$27
        bcc     L52E5
L52FF:  inx
        cpx     #$04
        bcc     L52DE
L5304:  ldy     #$02
        lda     $C008
        and     #$08
        sta     $AE
L530D:  jsr     LDF77
        lda     $C008
        and     #$08
        cmp     $AE
        beq     L530D
        sta     $AE
        dey
        bne     L530D
        ldx     #$03
L5320:  jsr     LDFA7
        ldy     #$27
L5325:  lda     ($06),y
        sta     ($04),y
        dey
        bpl     L5325
        dex
        bpl     L5320
        php
        sei
        lda     E_ACR
        and     #$DF
        ora     $AB
        sta     E_ACR
        lda     E_PCR
        and     #$0F
        ora     $AC
        sta     E_PCR
        lda     $AD
        ora     #$80
        sta     E_IER
        lda     $AA
        sta     SCRNMODE
        lsr     a
        .byte   $90
L5353:  .byte   $03
        bit     $C051
        lsr     a
        bcc     L535D
        bit     $C053
L535D:  lsr     a
        bcc     L5363
        bit     $C055
L5363:  bit     SCRNMODE
        bvc     L536B
        bit     $C057
L536B:  lda     $A9
        sta     E_REG
        lda     $A8
        sta     Z_REG
        plp
        rts
        lda     E_IFR
        and     #$28
        beq     L53A6
        sta     E_IFR
        and     #$20
        bne     L5397
        lda     #$1F
        sta     $FFE8
        lda     #$00
        sta     $FFE9
        lda     E_REG
        ora     #$20
        sec
        bcs     L539D
L5397:  lda     E_REG
        and     #$DF
        clc
L539D:  sta     E_REG
        lda     #$00
        ror     a
        sta     SCRNMODE
L53A6:  rts
        txa
        lsr     a
        ora     #$04
        sta     $05
        lda     #$00
        ror     a
        sta     $04
        lda     #$00
        sta     $07
        lda     $DFBC,x
        sta     $06
        rts
        php
        bmi     L5417
        .byte   $80
        brk
        .byte   $02
        jsr     LF810
        ldy     #$D9
        ldy     #$A0
        ldy     $A0
        ldy     #$CD
        ldy     #$A0
        sty     $A0,x
L53D1:  ldy     #$E5
        ldy     #$98
        ldy     #$A0
        ldx     #$A0
        ldy     #$84
        ldy     #$A0
        ldx     $D3D3
        ldy     #$C8
        ldy     #$A0
        ldy     $A0
        ldy     #$81
        ldy     #$FF
        lda     ($A0,x)
        .byte   $FF
        .byte   $82
        ldy     #$94
        tax
        ldy     #$90
        ldy     #$A0
        sbc     $A0C5,x
        ldy     #$A5
        ldy     #$A0
        sta     LA0A0
        sbc     $A0
        ldy     #$A5
        ldy     #$95
        ldy     #$A0
        lda     $A0
        ldy     #$F3
        ldy     #$A0
        lda     #$A0
        .byte   $C3
        ldy     #$BD
        ldy     #$A0
        .byte   $8F
        ldy     #$A0
L5417:  sty     $A0,x
        ldy     #$D9
        ldy     #$A0
        .byte   $9B
        ldy     #$A0
        .byte   $9F
        ldy     #$86
        ldy     #$A0
        lda     ($FF),y
        ldx     #$A0
        lda     $AA
        ldy     #$88
        ldy     #$A0
        beq     L53D1
        ldy     #$FD
        dec     $8280
        dec     $89
        txs
        cmp     $C5
        ldy     #$A0
        cmp     $A0
        ldy     #$D3
        ldy     #$BA
        .byte   $D2
        ldy     #$A0
        iny
        ldy     #$A0
        lda     $A0
        dey
        ldy     #$A0
L544E:  lda     $A0
        pha
        txa
        pha
        tya
        pha
        tsx
        cpx     #$FA
        bcc     L545F
        lda     #$06
        jsr     LEE2A
L545F:  ldy     $0104,x
        cld
        lda     E_REG
        tax
        and     #$30
        ora     #$44
        sta     E_REG
        txa
        and     #$04
        bne     L547C
        txa
        tsx
        stx     $01FF
        ldx     #$FE
        txs
        tax
L547C:  txa
        pha
        lda     Z_REG
        pha
        lda     B_REG
        pha
        lda     $DFC0
        pha
        bit     $CFFF
        bit     $C020
        lda     #$00
        sta     $DFC0
        tya
        and     #$10
        beq     L54DA
        tsx
        cpx     #$FA
        beq     L54A4
        lda     #$01
        jsr     LEE2A
L54A4:  lda     E_REG
        and     #$BF
        sta     E_REG
        cli
        jsr     LF0F6
        lda     #$20
        sta     $19D2
        jsr     LF6EC
        sei
        ldx     $01FF
        lda     $01FD
        eor     #$01
        sta     Z_REG
        lda     $1980
        sta     $03,x
        php
        lda     $04,x
        and     #$7D
        sta     $04,x
        pla
        and     #$82
        ora     $04,x
        sta     $04,x
        jmp     LE21D
L54DA:  bit     B_REG
        bpl     L54EA
        inc     $19CB
        bne     L54E7
        inc     $19CC
L54E7:  jmp     LE21D
L54EA:  lda     #$00
        sta     Z_REG
        lda     E_REG
        ora     #$80
        sta     E_REG
        and     #$7F
        ldx     #$01
        ldy     ACIASTAT
        sta     E_REG
        bmi     L555F
        lda     E_IFR
        bpl     L5518
        and     E_IER
        ldy     #$07
        ldx     #$02
L550F:  lsr     a
        bcs     L555F
        inx
        dey
        bne     L550F
        beq     L5530
L5518:  lda     D_IFR
        bpl     L5530
        and     D_IER
        bit     $DFC1
        bne     L5534
        ldy     #$07
        ldx     #$09
L5529:  lsr     a
        bcs     L555F
        inx
        dey
        bne     L5529
L5530:  ldx     #$10
        bne     L5552
L5534:  ldx     #$11
        bit     $C065
        bpl     L555F
        inx
        bit     $C064
        bpl     L555F
        lda     B_REG
        inx
        bit     $DFC2
        beq     L555F
        inx
        bit     $DFC3
        beq     L555F
        ldx     #$0A
L5552:  lda     #$02
        jsr     LEE2A
L5557:  lda     #$03
        jsr     LEE2A
        jmp     (L00FD)
L555F:  lda     $DFC5,x
        bpl     L5552
        lda     $DFDD,x
        sta     L00FD
        ora     $DFF6,x
        beq     L5552
        lda     $DFF6,x
        sta     $FE
        lda     $E00E,x
        sta     B_REG
        lda     $DFC4
        cmp     #$48
        bcc     L5557
        sbc     #$20
        sta     $DFC4
        sta     $FF
        tax
        jsr     LE15C
        sei
        lda     #$00
        sta     Z_REG
        clc
        lda     $DFC4
        adc     #$20
        sta     $DFC4
        sta     $FF
        lda     #$02
        sta     D_IFR
        jmp     LE21D
        pha
        txa
        pha
        tya
        pha
        tsx
        cpx     #$FA
        bcc     L55B3
        lda     #$06
        jsr     LEE2A
L55B3:  cld
        lda     E_REG
        tax
        and     #$30
        ora     #$44
        sta     E_REG
        txa
        and     #$04
        bne     L55CD
        txa
        tsx
        stx     $01FF
        ldx     #$FE
        txs
        tax
L55CD:  txa
        pha
        lda     Z_REG
        pha
        lda     B_REG
        pha
        lda     $DFC0
        pha
        bit     $CFFF
        bit     $C020
        lda     #$00
        sta     $DFC0
        lda     #$00
        sta     Z_REG
        lda     E_IORB
        bmi     L5610
        lda     $DFC5
        bpl     L560B
        jsr     LE1FC
        sei
        jmp     LE21D
        lda     $DFDD
        sta     LDFF5
        lda     $E00E
        sta     B_REG
        jmp     (LDFF5)
L560B:  lda     #$02
        jsr     LEE2A
L5610:  lda     $1901
        sta     B_REG
        jsr     L1985
        sei
        jmp     LE21D
        sei
        lda     E_REG
        ora     #$40
        sta     E_REG
        pla
        jsr     LE3A9
        pla
        sta     B_REG
        pla
        sta     Z_REG
        pla
        ora     #$20
        bit     SCRNMODE
        bmi     L563C
        and     #$DF
L563C:  tay
        and     #$04
        beq     L5646
        sty     E_REG
        bne     L5687
L5646:  pla
        tax
        txs
        sty     E_REG
        lda     $19C8
        ldx     $E026
        cmp     $E027,x
        bcs     L5687
        lda     E_REG
        pha
        lda     Z_REG
        pha
        lda     B_REG
        pha
        lda     $19C8
        pha
        jsr     LE28D
        sei
        pla
        sta     $19C8
        pla
        sta     B_REG
        pla
        sta     Z_REG
        pla
        ora     #$20
        bit     SCRNMODE
        bmi     L5681
        and     #$DF
L5681:  sta     E_REG
        jmp     LE24C
L5687:  pla
        tay
        pla
        tax
        pla
        rti
        ldy     E_REG
        tya
        and     #$F7
        sta     E_REG
        ldx     $E026
        lda     $E026,x
        sta     $E026
        lda     $E028
        sta     $E026,x
        stx     $E028
        lda     $E027,x
        sta     $19C8
        sty     E_REG
        lda     $E02B,x
        sta     B_REG
        lda     $E02A,x
        pha
        lda     $E029,x
        pha
        ldy     $E028,x
        php
        pla
        and     #$82
        pha
        tya
        rti
        sta     ($18,x)
        php
        sei
        sta     $19CA
        lda     E_REG
        sta     $19C9
        ora     #$04
        and     #$F7
        sta     E_REG
        lda     $19C9
        pha
        lda     Z_REG
        pha
        lda     #$00
        sta     Z_REG
        stx     $F9
        sty     $FA
        ldy     #$00
L56F0:  lda     ($F9),y
        cmp     #$18
        tax
        bcs     L572A
        lda     $DFC5,x
        bmi     L572A
        lda     $E2C9
        sta     $DFC5,x
        iny
        sta     ($F9),y
        iny
        lda     ($F9),y
        sta     $DFDD,x
        iny
        lda     ($F9),y
        sta     $DFF6,x
        iny
        lda     ($F9),y
        sta     $E00E,x
        iny
        cpy     $19CA
        bcc     L56F0
        clc
        inc     $E2C9
        bmi     L5742
        lda     #$81
        sta     $E2C9
        bmi     L5742
L572A:  stx     $19C9
L572D:  sec
        tya
        sbc     #$05
        tay
        bcc     L573E
        lda     ($F9),y
        tax
        lda     #$00
        sta     $DFC5,x
        beq     L572D
L573E:  ldx     $19C9
        sec
L5742:  pla
        sta     Z_REG
        pla
        sta     E_REG
        bcc     L5750
        pla
        ora     #$01
        pha
L5750:  plp
        rts
        clc
        php
        sei
        sta     $19CA
        lda     E_REG
        sta     $19C9
        ora     #$04
        and     #$F7
        sta     E_REG
        lda     $19C9
        pha
        lda     Z_REG
        pha
        lda     #$00
        sta     Z_REG
        stx     $F9
        sty     $FA
        ldy     #$00
L5778:  lda     ($F9),y
        tax
        cpx     #$18
        bcs     L57A6
        iny
        lda     $DFC5,x
        bpl     L57A6
        cmp     ($F9),y
        bne     L57A6
        iny
        iny
        iny
        iny
        cpy     $19CA
        bcc     L5778
        ldy     $19CA
L5795:  sec
        tya
        sbc     #$05
        tay
        bcc     L5742
        lda     ($F9),y
        tax
        lda     #$00
        sta     $DFC5,x
        beq     L5795
L57A6:  sec
        bcs     L5742
        cmp     #$05
        bcs     L57C1
        php
        sei
        sta     $DFC0
        ora     #$C0
        sta     $E3BF
        bit     $C020
        bit     $CFFF
        bit     $C0FF
        plp
L57C1:  rts
        ldx     E_REG
        bit     $1903
        bpl     L57EC
        txa
        ora     #$80
        sta     E_REG
        lda     #$00
        sta     $19CD
        sta     $19CE
L57D8:  bit     $1903
        bpl     L57EC
        inc     $19CD
        bne     L57D8
        inc     $19CE
        bne     L57D8
        lda     #$04
        jsr     LEE2A
L57EC:  txa
        and     #$EF
        sta     E_REG
        rts
        lda     E_REG
        ora     #$10
        sta     E_REG
        rts
        tsx
        stx     $198B
        lda     #$03
        sta     Z_REG
        lda     E_REG
        ora     #$03
        sta     E_REG
        jsr     MONITOR
        lda     E_REG
        ora     #$04
        sta     E_REG
        ldx     $198B
        txs
        rts
        clc
        php
        sei
        lda     E_REG
        sta     $19CF
        ora     #$04
        and     #$F7
        sta     E_REG
        lda     $19CF
        pha
        lda     Z_REG
        pha
        lda     #$00
        sta     Z_REG
        stx     $FB
        sty     $FC
        ldy     #$00
        lda     ($FB),y
        beq     L587C
        ldx     $E028
        beq     L5886
        stx     $19D0
        lda     $E026,x
        sta     $E028
        ldy     #$04
L5854:  lda     ($FB),y
        sta     $E02B,x
        dex
        dey
        bpl     L5854
        ldx     $19D0
        ldy     #$00
L5862:  sty     $19D1
        lda     $E026,y
        tay
L5869:  lda     $E027,y
        cmp     $E027,x
        bcs     L5862
        tya
        sta     $E026,x
        txa
        ldy     $19D1
        sta     $E026,y
L587C:  pla
        sta     Z_REG
        pla
        sta     E_REG
        plp
        rts
L5886:  lda     #$05
        jsr     LEE2A
        lda     E_REG
        ora     #$40
        sta     E_REG
        lda     D_TPARMX
        cmp     #$06
        bcs     L58A4
        asl     a
        tax
        lda     $E4AA,x
        pha
        lda     $E4A9,x
        pha
        rts
L58A4:  lda     #$01
        jsr     LEE17
        ldy     $E4,x
        tsx
        cpx     $D9
        cpx     D_TPARMX
        sbc     $1D
        .byte   $E7
        .byte   $32
        inx
        lda     $C1
        sta     $19C8
        rts
        lda     $19C8
        ldy     #$00
        sta     ($C1),y
        rts
        ldy     #$D3
        ldy     #$A0
        bne     L5869
        ldy     #$FE
        ldy     #$A0
        cmp     $08
        .byte   $0B
        .byte   $0B
        .byte   $07
        ora     #$0C
        .byte   $07
        asl     a
        ora     $0B08
        ora     a:$A2
        ldy     #$12
        lda     #$30
        bne     L58E5
L58E2:  inx
        lda     ($C1),y
L58E5:  and     #$0F
        sta     $E4C3,x
        dey
        cpy     #$07
        beq     L58E2
        lda     ($C1),y
        asl     a
        asl     a
        asl     a
        asl     a
        ora     $E4C3,x
        sta     $E4C3,x
        dey
        bpl     L58E2
        lda     $E4CA
        jsr     LE706
        tax
        lda     $E4CB
        jsr     LE706
        tay
        lsr     a
        lsr     a
        sta     $D2
        tya
        and     #$03
        bne     L591A
        cpx     #$03
        bcs     L591A
        dey
L591A:  clc
        tya
        adc     $D2
        adc     $E4CD,x
        sta     $D2
        lda     $E4C9
        jsr     LE706
        clc
        adc     $D2
        sec
L592D:  sbc     #$07
        cmp     #$08
        bcs     L592D
        sta     $E4C8
        lda     #$D0
        sta     $D0
        lda     #$FF
        sta     $D1
        lda     #$8F
        sta     $14D1
        lda     #$A5
        sta     $D3
        ldy     #$00
L5949:  lda     $E4C3,y
        sta     ($D0),y
        eor     $D3
        sta     $D3
        iny
L5953:  cpy     #$0A
        bcc     L5949
        sta     ($D0),y
        lda     Z_REG
        pha
        lda     E_REG
        pha
        ora     #$80
        sta     E_REG
        ldy     #$14
        sty     Z_REG
        lda     $C070
        bmi     L59B8
        ldx     #$12
        stx     Z_REG
        lda     #$FF
        sta     $C070
        sta     $C070
        ldx     #$01
L597F:  inx
        php
        sei
L5982:  stx     Z_REG
        lda     $C070
        lda     $E4C3,x
        sta     $C070
        lda     $C070
        sty     Z_REG
        lda     $C070
        bne     L5982
        plp
        cpx     #$07
        bcc     L597F
        ldx     #$0E
        stx     Z_REG
        lda     $E4CB
        ora     #$CC
        sta     $C070
        inc     Z_REG
        lda     $E4CB
        lsr     a
        lsr     a
        ora     #$CC
        sta     $C070
L59B8:  pla
        sta     E_REG
        pla
        sta     Z_REG
        rts
        lda     Z_REG
        pha
        lda     E_REG
        pha
        ora     #$80
        sta     E_REG
        ldy     #$14
        sty     Z_REG
        lda     $C070
        bmi     L5A1D
        lda     #$10
        sta     $E4CD
L59DD:  ldx     #$08
        php
        sei
L59E1:  dex
        bmi     L59FD
        stx     Z_REG
        lda     $C070
        sta     $18D4,x
        sty     Z_REG
        lda     $C070
        beq     L59E1
        plp
        dec     $E4CD
        bpl     L59DD
        bmi     L5A1D
L59FD:  plp
        ldx     #$0F
        stx     Z_REG
        lda     $C070
        sec
        rol     a
        rol     a
        dec     Z_REG
        and     $C070
        sta     $18DC
        ldx     #$09
L5A14:  lda     $18D4,x
        sta     $E4C3,x
        dex
        bpl     L5A14
L5A1D:  lda     #$19
        sta     $E4CC
        pla
        sta     E_REG
        pla
        sta     Z_REG
        ldy     #$11
        ldx     #$00
L5A2E:  lda     $E4C3,x
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        ora     #$30
        sta     ($C1),y
        inx
        dey
        bmi     L5A4E
L5A3D:  lda     $E4C3,x
        and     #$0F
        ora     #$30
        sta     ($C1),y
        dey
        cpy     #$07
        bne     L5A2E
        inx
        bne     L5A3D
L5A4E:  rts
        brk
        brk
        .byte   $C7
        .byte   $80
        sta     $D0
        .byte   $80
        stx     $E64F
        lda     Z_REG
        pha
        lda     E_REG
        pha
        ora     #$C0
        sta     E_REG
        ldy     #$14
        sty     Z_REG
        lda     $C070
        bmi     L5A95
        lda     #$08
        sta     $E650
L5A75:  ldx     #$08
        php
        sei
L5A79:  dex
        cpx     #$03
        bcc     L5AAE
        stx     Z_REG
        lda     $C070
        sta     $E64E,x
        sty     Z_REG
        lda     $C070
        beq     L5A79
        plp
        dec     $E650
        bpl     L5A75
L5A95:  pla
        sta     E_REG
        pla
        sta     Z_REG
        ldx     #$04
L5A9F:  lda     $E4C6,x
        sta     $E651,x
        dex
        bpl     L5A9F
        ldx     $E4CB
        jmp     LE6C9
L5AAE:  plp
        lda     #$0F
        sta     Z_REG
        lda     $C070
        sec
        rol     a
        rol     a
        dec     Z_REG
        and     $C070
        tax
        pla
        sta     E_REG
        pla
        sta     Z_REG
        txa
        jsr     LE706
        sta     $E653
        lda     $E655
        jsr     LE706
        asl     a
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $E655
        rol     $E653
        lda     $E654
        jsr     LE706
        ora     $E655
        ldx     $E64F
        sta     ZPAGE,x
        lda     $E653
        sta     $01,x
        lda     $E651
        jsr     LE706
        sta     I_BASE_P,x
        lda     $E652
        jsr     LE706
        sta     $03,x
        clc
        rts
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        tay
        pla
        and     #$0F
        clc
        adc     $E714,y
        rts
        brk
        asl     a
        .byte   $14
        asl     L3228,x
        .byte   $3C
        lsr     $50
        .byte   $5A
        lda     $C1
        cmp     #$08
        bcc     L5B29
        lda     #$70
L5B26:  jsr     LEE17
L5B29:  jsr     LE77C
        bcs     L5B26
        lda     $C1
        and     #$04
        bne     L5B3E
        lda     $C062
        ldx     $C060
        ldy     #$01
        bne     L5B46
L5B3E:  lda     $C061
        ldx     $C063
        ldy     #$03
L5B46:  sty     $D0
        and     #$80
        beq     L5B4E
        lda     #$FF
L5B4E:  ldy     #$00
        sta     ($C2),y
        txa
        and     #$80
        beq     L5B59
        lda     #$FF
L5B59:  iny
        sta     ($C2),y
        lsr     $C1
        bcc     L5B69
        lda     $D0
        jsr     LE7C7
        ldy     #$02
        sta     ($C2),y
L5B69:  inc     $D0
        lsr     $C1
        bcc     L5B78
        lda     $D0
        jsr     LE7C7
        ldy     #$03
        sta     ($C2),y
L5B78:  jsr     LE7B5
        rts
        lda     #$0F
        ldx     #$A6
        ldy     #$E7
        jsr     LE2CA
        bcc     L5B8A
        lda     #$25
        rts
L5B8A:  lda     E_REG
        and     #$7F
        ora     #$43
        sta     E_REG
        php
        sei
        lda     D_ACR
        and     #$DF
        sta     D_ACR
        plp
        bit     $C0DC
        bit     $C0DE
        rts
        .byte   $0C
        brk
        brk
        brk
        brk
        ora     a:ZPAGE
        brk
        brk
        asl     a:ZPAGE
        brk
        brk
        lda     E_REG
        and     #$3C
        sta     E_REG
        lda     #$0F
        ldx     #$A6
        ldy     #$E7
        jsr     LE352
        rts
        lsr     a
        bit     $C058
        bcc     L5BD0
        bit     $C059
L5BD0:  lsr     a
        bit     $C05E
        bcc     L5BD9
        bit     $C05F
L5BD9:  lsr     a
        bit     $C05A
        bcc     L5BE2
        bit     $C05B
L5BE2:  php
L5BE3:  cli
        bit     $C05C
        lda     #$F4
        sta     $FFD8
        lda     #$01
        sta     $FFD9
        lda     #$20
L5BF3:  bit     D_IFR
        beq     L5BF3
        sei
        sec
        lda     #$68
        sta     $FFD8
        lda     #$01
        bit     $C05D
        jsr     LF4A8
        bcc     L5C15
L5C09:  cli
        sei
        bit     $C066
        bpl     L5BE3
        jsr     LF4AB
        bcs     L5C09
L5C15:  plp
        eor     #$FF
        bmi     L5C2D
        sta     $D1
        tya
        eor     #$FF
        lsr     $D1
        ror     a
        lsr     $D1
        ror     a
        lsr     $D1
        bne     L5C30
        ror     a
        adc     #$00
        rts
L5C2D:  lda     #$00
        rts
L5C30:  lda     #$FF
        rts
COLDSTRT:
        sei
        lda     #$40
        sta     $FFCA
        lda     #$67
        sta     E_REG
        lda     #$00
        sta     Z_REG
        ldx     $1901
        lda     #$BF
        ldy     #$00
        sty     $C1
L5C4C:  sta     $C2
        stx     B_REG
        lda     #$A0
L5C53:  sta     ($C1),y
        dey
        bne     L5C53
        dec     $C2
        bne     L5C53
        dex
        bpl     L5C4C
        ldy     #$06
L5C61:  sta     $C050,y
        dey
        bpl     L5C61
        ldy     #$1F
L5C69:  lda     $E879,y
        sta     $062B,y
        dey
        bne     L5C69
        lda     #$77
        sta     E_REG
        jmp     LE877
        cmp     #$CE
        .byte   $D3
        cmp     $D2
        .byte   $D4
        ldy     #$D3
        cmp     $D4D3,y
        cmp     $CD
        ldy     #$C4
        cmp     #$D3
        .byte   $CB
        cmp     $D4
        .byte   $D4
        cmp     $A0
        ldx     $A0
        .byte   $D2
        cmp     $C2
        .byte   $CF
        .byte   $CF
        .byte   $D4
        lda     $1DE8,y
        sbc     #$03
        rol     L3144
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        .byte   $80
        brk
        brk
        sbc     ($01,x)
        brk
        clc
        ora     ($01,x)
        brk
        brk
        ora     ($D9),y
        inx
        ora     $03E9,x
        rol     L3244
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        .byte   $80
        brk
        ora     ($E1,x)
        ora     (ZPAGE,x)
        clc
        ora     ($01,x)
        brk
        brk
        ora     ($F9),y
        inx
        ora     $03E9,x
        rol     L3344
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        .byte   $80
        brk
        .byte   $02
        sbc     ($01,x)
        brk
        clc
        ora     ($01,x)
        brk
        brk
        ora     (ZPAGE),y
        brk
        ora     $03E9,x
        rol     L3444
        jsr     L2020
        jsr     L2020
        jsr     L2020
        jsr     L2020
        .byte   $80
        brk
        .byte   $03
        sbc     ($01,x)
        brk
        clc
        ora     ($01,x)
        brk
        brk
        ora     ($01),y
        brk
        brk
        ora     ($AD),y
        .byte   $DF
        .byte   $FF
        and     #$DF
        sta     $EDF2
        lda     E_REG
        and     #$EF
        ora     #$03
        sta     E_REG
        lda     NOSCROLL
        php
        pla
        ror     a
        ror     a
        ror     a
        ror     a
        sta     $DB
        lda     D_TPARMX
        bmi     L5D81
        beq     L5D86
        cmp     #$0A
        bcs     L5D81
        cmp     #$09
        bne     L5D5E
        lda     $EDF0
        cmp     $C1
        bne     L5D7C
        lda     $EDF1
        beq     L5D58
        cmp     #$01
        bne     L5D7C
L5D58:  sta     D_TPARMX
        cmp     #$00
        beq     L5D86
L5D5E:  cmp     #$01
        bne     L5D65
        jmp     LE986
L5D65:  cmp     #$02
        bne     L5D75
        lda     $C2
        beq     L5D72
        lda     #$21
        jmp     LEAE9
L5D72:  jmp     LE9BC
L5D75:  cmp     #$08
        bne     L5D7C
        jmp     LEAA4
L5D7C:  lda     #$26
        jmp     LEAE9
L5D81:  lda     #$20
        jmp     LEAE9
L5D86:  lda     $C7
        beq     L5D99
        cmp     #$02
        bcs     L5D94
        lda     $C6
        cmp     #$18
        bcc     L5D99
L5D94:  lda     #$2D
        jmp     LEAE9
L5D99:  lda     $C4
        bne     L5DB7
        lda     $C5
        lsr     a
        bcs     L5DB7
        sta     $D9
        lda     $D9
        clc
        adc     $C6
        ldx     $C7
        bne     L5DB1
        bcc     L5DBC
        bcs     L5DB3
L5DB1:  bcs     L5DB7
L5DB3:  cmp     #$19
        bcc     L5DBC
L5DB7:  lda     #$2C
        jmp     LEAE9
L5DBC:  lda     D_TPARMX
        sta     $EDF1
        lda     $C1
        sta     $EDF0
        lda     E_REG
        ora     #$80
        sta     E_REG
        jsr     LEC1D
        jsr     LECDC
        bne     L5DF9
        ldx     $C1
        inc     $EE00,x
        inc     $EE00,x
        lda     #$00
        jsr     LED60
        jsr     LECDC
        bne     L5DF4
        lda     #$00
        ldy     $C1
        sta     $EDF8,y
        lda     #$28
        jmp     LEAE9
L5DF4:  lda     #$2E
        jmp     LEAE9
L5DF9:  lda     $C2
        sta     $D2
        lda     $C3
        sta     $D3
        lda     $14C3
        sta     $14D3
        lda     $C6
        sta     $D0
        lda     $C7
        sta     $D1
        lda     D_TPARMX
        cmp     #$02
        bne     L5E18
        jmp     LEA8B
L5E18:  ldy     $D9
        beq     L5E4D
        cmp     #$00
        beq     L5E23
        jmp     LEA55
L5E23:  lda     #$00
        ldy     #$00
        sta     ($C8),y
        iny
        sta     ($C8),y
L5E2C:  jsr     LED98
        jsr     LEB0E
        bcs     L5E52
        inc     $D5
        inc     $D5
        inc     $9C
        jsr     LEB0E
        bcs     L5E52
        ldy     #$01
        lda     ($C8),y
        clc
        adc     #$02
        sta     ($C8),y
        jsr     LEDDB
        bne     L5E2C
L5E4D:  lda     #$00
        jmp     LEAE9
L5E52:  jmp     LEAE9
L5E55:  jsr     LED98
        lda     E_REG
        and     #$7F
        sta     E_REG
        jsr     LF2C4
        jsr     LEB0E
        bcs     L5E88
        inc     $D5
        inc     $D5
        inc     $9C
        lda     E_REG
        and     #$7F
        sta     E_REG
        jsr     LF2C4
        jsr     LEB0E
        bcs     L5E88
        jsr     LEDDB
        bne     L5E55
        lda     #$00
        jmp     LEAE9
L5E88:  jmp     LEAE9
        ldx     #$60
        lda     $C08D,x
        lda     $C08E,x
        asl     a
        lda     $C08C,x
        lda     #$00
        rol     a
        rol     a
        ldy     #$00
        sta     ($C3),y
        lda     #$00
        jmp     LEAE9
        lda     $EDF4
        bmi     L5EE4
        lda     #$60
        sta     $81
        lda     #$FF
        sta     $EDF4
        lda     #$00
        sta     $EDF0
        ldy     #$04
L5EB9:  lda     #$00
        sta     $EDF7,y
        sta     $EDFB,y
        sta     $EDFF,y
        dey
        bne     L5EB9
        lda     E_REG
        ora     #$80
        sta     E_REG
        jsr     LECDC
        beq     L5ED9
        lda     #$08
        sta     $EDFC
L5ED9:  lda     #$01
        sta     $EDF8
        lda     $038C
        sta     $EE00
L5EE4:  lda     #$00
        clc
        bcc     L5EE9
L5EE9:  pha
        lda     D_TPARMX
        cmp     #$02
        bcs     L5EF5
        lda     #$02
        jsr     LED0A
L5EF5:  lda     E_REG
        and     #$20
        ora     $EDF2
        sta     E_REG
        jsr     LEDE8
        lda     $C0E8
        pla
        bne     L5F0B
        clc
        rts
L5F0B:  jsr     LEE17
        lda     #$01
        sta     $D8
        nop
        sta     $1908
        ldy     $C1
        lda     $D4
        cmp     $EE00,y
        beq     L5F3A
        lda     $DA
        beq     L5F35
        lda     #$00
        sta     $DA
        lda     #$04
        jsr     LED0A
        tay
L5F2D:  lda     #$00
        jsr     LF456
        dey
        bne     L5F2D
L5F35:  lda     $D4
        jsr     LED60
L5F3A:  lda     $DB
        sta     $8B
        lda     #$06
        sta     $8F
        lda     #$04
        sta     $D7
        lda     $9A
        bpl     L5F57
        lda     #$01
        jsr     LED0A
        lda     #$00
        jsr     LF456
        jmp     LEB46
L5F57:  php
        sei
        lda     E_IER
        and     #$18
        sta     E_IER
        ora     #$80
        sta     $EDF3
        plp
        jsr     LEBD5
        bcs     L5FA6
        ldx     #$60
        lda     D_TPARMX
        bne     L5F90
        jsr     LF148
        jsr     LEDE8
        lda     $EDF3
        sta     E_IER
        bcs     L5FA0
        lda     E_REG
        and     #$7F
        sta     E_REG
        jsr     LF30F
        bcs     L5FA2
        jmp     LEBCC
L5F90:  jsr     LF216
        jsr     LEDE8
        lda     $EDF3
        sta     E_IER
        bcc     L5FCC
        bvc     L5FC7
L5FA0:  bvs     L5F57
L5FA2:  dec     $D7
        bne     L5F57
L5FA6:  lda     $EDF3
        sta     E_IER
        dec     $D8
        bmi     L5FC2
        jsr     LED26
        ldy     $C1
        lda     $D4
        cmp     $EE00,y
        bne     L5FBF
        jmp     LEB3A
L5FBF:  jmp     LEB35
L5FC2:  lda     #$27
        sec
        bcs     L5FCF
L5FC7:  lda     #$2B
        sec
        bcs     L5FCF
L5FCC:  lda     #$00
        clc
L5FCF:  ldx     #$00
        stx     $1908
        rts
        lda     #$30
        sta     $D6
        lsr     $DC
        ldx     #$60
        jsr     LF1B9
        bcs     L5FFF
        lda     $D4
        cmp     $99
        bne     L6014
        lda     $D5
        cmp     $98
        beq     L600E
        lda     $DC
        bmi     L5FFF
        lda     $D5
        sec
        ror     $DC
        sbc     $98
        and     #$0F
        lsr     a
        jsr     LED0A
L5FFF:  jsr     LEDE8
        dec     $D6
        beq     L6014
        ldy     #$C8
L6008:  dey
        bne     L6008
        jmp     LEBDB
L600E:  lda     #$00
        sta     $9A
        clc
        rts
L6014:  jsr     LEDE8
        lda     #$00
        sta     $9A
        sec
        rts
        ldy     $C1
        lda     #$00
        sta     $DA
        sta     $99
        sta     $9A
        jsr     LECDC
        bne     L603D
        ldx     $C0D5
        lda     #$00
        sta     $EDF8
        sta     $EDFC
        jsr     LECC8
        jmp     LEC6B
L603D:  lda     $EDF8,y
        bne     L605B
        cpy     #$00
        beq     L606B
        lda     #$00
        ora     $EDFB
        ora     $EDFA
        ora     $EDF9
        beq     L606B
        inc     $DA
        jsr     LECC8
        jmp     LEC6B
L605B:  ldx     D_TPARMX
        lda     $EDF5,x
        sec
        sbc     $EDFC,y
        bcs     L6075
        lda     #$00
        jmp     LEC75
L606B:  lda     #$00
        sta     $EDFC,y
        ldx     D_TPARMX
        lda     $EDF5,x
L6075:  sta     $9A
        lda     #$00
        sec
        sbc     $9A
        sta     $9A
        cpy     #$01
        bcs     L608B
        lda     $C0EA
        lda     $C0D4
        jmp     LECAC
L608B:  lda     $C0EB
        cpy     #$02
        bcs     L609B
        lda     $C0D2
        lda     $C0D1
        jmp     LECAC
L609B:  bne     L60A6
        lda     $C0D3
        lda     $C0D0
        jmp     LECAC
L60A6:  lda     $C0D3
        lda     $C0D1
        lda     LC0E9
        lda     #$01
        sta     $EDF8,y
        lda     $9A
        bpl     L60C7
        ldy     #$05
L60BA:  lda     #$64
        jsr     LF456
        dey
        bne     L60BA
        lda     #$02
        jsr     LED0A
L60C7:  rts
        lda     $C0D2
        lda     $C0D0
        ldx     #$03
        lda     #$00
L60D2:  sta     $EDF8,x
        sta     $EDFC,x
        dex
        bne     L60D2
        rts
        ldx     #$03
L60DE:  lda     $C0EC
        cmp     $C0EC
        bne     L6105
        cmp     $C0EC
        bne     L6105
        cmp     $C0EC
        bne     L6105
        cmp     $C0EC
        bne     L6105
        cmp     $C0EC
        bne     L6105
        cmp     $C0EC
        bne     L6105
        cmp     $C0EC
        bne     L6105
        rts
L6105:  dex
        bne     L60DE
        dex
        rts
        pha
        ldy     #$04
L610D:  lda     $EDF7,y
        beq     L6121
        pla
        pha
        clc
        adc     $EDFB,y
        cmp     #$29
        bcc     L611E
        lda     #$28
L611E:  sta     $EDFB,y
L6121:  dey
        bne     L610D
        pla
        rts
        lda     #$02
L6128:  pha
        ldx     #$60
        jsr     LF1B9
        bcc     L613A
        jsr     LF1B9
        bcc     L613A
        lda     #$30
        jmp     LED3F
L613A:  lda     $99
        clc
        adc     #$03
        ldy     $C1
        sta     $EE00,y
        jsr     LEDE8
        lda     #$00
        sta     $9A
        sta     $99
        jsr     LED60
        pla
        tay
        dey
        tya
        bne     L6128
        rts
        ldy     $EDF0
        sty     $C1
        jsr     LED60
        rts
        sta     $9E
        ldy     $C1
        lda     $EE00,y
        asl     a
        sta     $8C
        ldx     #$60
        lda     $9A
        sta     $DC
        php
        sei
        lda     E_IER
        and     #$18
        sta     $EDF3
        sta     E_IER
        plp
        lda     $9E
        sta     $EE00,y
        asl     a
        jsr     LF400
        lda     $EDF3
        ora     #$80
        sta     E_IER
        lda     $9A
        sec
        sbc     $DC
        jsr     LED0A
        rts
        lda     $D1
        ror     a
        lda     $D0
        ror     a
        lsr     a
        lsr     a
        sta     $D4
        lda     $D0
        and     #$07
        tay
        lda     $EDD3,y
        sta     $D5
        lda     $D3
        ldy     $14D3
        cmp     #$82
        bcc     L61C4
        cpy     #$80
        bcc     L61C4
        cpy     #$8F
        beq     L61C4
        and     #$7F
        sta     $D3
        inc     $14D3
L61C4:  lda     $D3
        sta     $9C
        lda     $D2
        sta     $9B
        lda     $14D3
        sta     $149C
        rts
        brk
        .byte   $04
        php
        .byte   $0C
        ora     ($05,x)
        ora     #$0D
        inc     $D3
        inc     $D3
        inc     $D0
        bne     L61E5
        inc     $D1
L61E5:  dec     $D9
        rts
        pha
        lda     $DB
        bmi     L61EE
        cli
L61EE:  pla
        rts
        ldy     #$99
        dec     a:$A0
        php
        .byte   $27
        .byte   $02
        ldy     #$C3
        ldy     #$CC
        ldy     #$A0
        sta     ($A0),y
        cpx     #$99
        ldy     #$AC
        jsr     L5953
        .byte   $53
        .byte   $54
        eor     $4D
        jsr     L4146
        eor     #$4C
        eor     $52,x
        eor     $20
        and     L2420,x
        sta     $1980
        pla
        sta     $19FD
        pla
        sta     $19FE
        sec
        lda     $1980
        bne     L6229
        clc
L6229:  rts
        sta     $19FB
        stx     $19FA
        sty     $19F9
        php
        pla
        sta     $19FC
        tsx
        stx     $19FF
        lda     E_REG
        sta     $19F8
        lda     Z_REG
        sta     $19F7
        lda     B_REG
        sta     $19F6
        pla
        sta     $19FD
        pla
        sta     $19FE
        sei
        cld
        ldx     #$00
SD005:  lda     SSPAGE,x
        sta     $1700,x
        dex
        bne     SD005
        lda     $C059
        lda     $C0DD
        lda     $C0DF
        lda     $C05F
        lda     $C05A
        lda     $C040
        lda     #$74
        sta     E_REG
        lda     $C050
        lda     $C052
        lda     $C056
        lda     $C054
        lda     #$02
        bit     SCRNMODE
        bvs     SD015
        beq     SD015
        lda     $C053
        ldx     #$14
        lda     #$20
SD010:  sta     $0BE3,x
        dex
        bpl     SD010
SD015:  ldx     #$00
SD020:  lda     $EE04,x
        sta     $07E3,x
        inx
        cpx     #$13
        bne     SD020
        lda     $19FB
        clc
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     LEECB
        inx
        lda     $19FB
        and     #$0F
        jsr     LEECB
        lda     #$CA
        sta     NMI_VECTOR
        lda     #$EE
        sta     $FFFB
        jmp     LEEC7
SD100:  rti
        cmp     #$0A
        bcs     L62D3
        adc     #$30
        .byte   $90
L62D2:  .byte   $02
L62D3:  adc     #$36
L62D5:  sta     $07E3,x
        rts
        ldx     $D5
        .byte   $C3
        ldx     $D3A0
        .byte   $D3
        .byte   $89
        ldy     #$A0
        ldy     $A0
        ldy     #$CD
        ldy     #$A0
        ldx     #$A0
        ldy     #$E5
        ldy     #$A7
        ldy     #$A0
        ldx     #$A0
        ldy     #$C7
        lda     $A0
        ldy     #$8D
        ldy     #$C3
        sbc     $A0
        .byte   $D3
        lda     $B3
        .byte   $80
        stx     $C4,y
        .byte   $AF
        bcc     L62D2
        .byte   $F3
        ldy     #$A0
        lda     #$D2
        .byte   $D2
        sta     $CCA0,y
        sta     LA0A0,y
        cmp     #$A0
        .byte   $D2
        dec     $91A0
        sta     $C9
        txa
        ldy     #$A0
        sta     $A0
        cmp     $90,x
        cmp     $B6FF
        .byte   $D3
        ldy     #$A0
        ldy     #$8E
        ldy     #$D3
        ldx     #$A0
        cpy     $A0A2
        ldy     #$D5
        ldy     #$D2
        ldy     #$A0
        lda     ($83),y
        ldy     #$C5
        ldy     #$A0
        .byte   $D4
        ldy     #$D2
        .byte   $FF
        .byte   $D3
        .byte   $FF
        inc     $FFCB,x
        txs
        ldy     #$D2
        txs
        cmp     #$D0
        ldy     #$A0
        cmp     ($AE,x)
        cmp     $C5,x
        cpy     $A0
        sbc     $D5A0,y
        sbc     #$B1
        .byte   $83
        ldy     #$80
        ldy     #$A0
        .byte   $D4
        ldy     #$A0
        stx     $A0
        ldy     #$80
        ldy     #$A0
        ldy     #$A0
        lda     ($A0),y
        ldy     #$A9
        ldy     #$A0
        iny
        ldy     #$00
        ldy     #$E0
        ldy     #$A0
        ldx     $A0
        ldy     #$90
        ldy     #$A0
        lda     $A0
        lda     D_TPARMX
        cmp     #$04
        bcc     L6395
        bne     L6388
        jmp     LF017
L6388:  cmp     #$05
        beq     L63DD
        cmp     #$0A
        bcc     L6395
        lda     #$07
        jsr     LEE2A
L6395:  ldx     $C1
        beq     L639E
        cpx     MAX_DNUM
        bcc     L63A3
L639E:  lda     #$11
        jsr     LEE17
L63A3:  lda     $EF57,x
        sta     $C1
        lda     B_REG
        pha
        lda     #$EF
        pha
        lda     #$C8
        pha
        lda     $EF3E,x
        sta     B_REG
        lda     $EF25,x
        pha
        lda     $EF0C,x
        pha
        lda     E_REG
        ora     #$40
        sta     E_REG
        rts
        lda     E_REG
        and     #$BF
        sta     E_REG
        pla
        sta     B_REG
        sec
        lda     $1980
        bne     L63DC
        clc
L63DC:  rts
L63DD:  ldx     $C1
        beq     L63E6
        cpx     MAX_DNUM
        bcc     L63EB
L63E6:  lda     #$11
        jsr     LEE17
L63EB:  jsr     LF048
        lda     ($D0),y
        tay
L63F1:  lda     ($D0),y
        sta     ($C2),y
        dey
        bpl     L63F1
        lda     #$11
        clc
        adc     $D0
        sta     $D0
        bcc     L6403
        inc     $D1
L6403:  ldy     $C6
        beq     L6415
        dey
        cpy     #$0B
        bcc     L640E
        ldy     #$0A
L640E:  lda     ($D0),y
        sta     ($C4),y
        dey
        bpl     L640E
L6415:  clc
        rts
        ldx     #$01
L6419:  jsr     LF048
        lda     ($D0),y
        cmp     ($C1),y
L6420:  bne     L643D
        tay
L6423:  lda     ($C1),y
        cmp     #$60
        bcc     L642B
        and     #$DF
L642B:  cmp     ($D0),y
        bne     L643D
        dey
        bne     L6423
        txa
        ldy     #$00
        sta     ($C3),y
        ldy     #$13
        lda     ($D0),y
        clc
        rts
L643D:  inx
        cpx     MAX_DNUM
        bcc     L6419
        lda     #$10
        jsr     LEE17
        lda     $EEDA,x
        sta     $D0
        lda     $EEF3,x
        sta     $D1
        lda     $EF3E,x
        sta     B_REG
        ldy     #$00
        sty     $14D1
        rts
        .byte   $03
        eor     a:ZPAGE,x
        ora     ($50,x)
        brk
        brk
        .byte   $02
        eor     ZPAGE,x
        brk
        .byte   $03
        eor     a:ZPAGE,x
        .byte   $03
        eor     a:ZPAGE,x
        .byte   $04
        eor     $99,x
        brk
        ora     ($50,x)
        brk
        brk
        .byte   $02
        bvc     L647D
L647D:  brk
        .byte   $04
        cli
        bne     L6482
L6482:  .byte   $03
        brk
        brk
        brk
        .byte   $04
        ora     $19
        brk
        .byte   $03
        ora     $10
        brk
        ora     (ZPAGE,x)
        brk
        brk
        ora     (ZPAGE,x)
        brk
        brk
        .byte   $03
        brk
        bmi     L649A
L649A:  .byte   $02
        .byte   $0B
        brk
        brk
        .byte   $03
        brk
        bmi     L64A2
L64A2:  .byte   $02
        .byte   $0B
        brk
        brk
        ora     (ZPAGE,x)
        brk
        brk
        ora     ($80,x)
        brk
        brk
        ora     $05
        ora     ($90),y
        .byte   $04
        ora     $11
        brk
        .byte   $03
        brk
        bvc     L64BA
L64BA:  .byte   $03
        brk
        bvc     L64BE
L64BE:  .byte   $02
        cli
        brk
        brk
        .byte   $04
        ora     $D0
        brk
        ora     (ZPAGE,x)
        brk
        brk
        ora     ($80,x)
        brk
        brk
        ora     ($50,x)
        brk
        brk
        ora     ($50,x)
        brk
        brk
        .byte   $02
        .byte   $0B
        brk
        brk
        brk
        brk
        brk
        brk
        .byte   $04
        ora     ($08),y
        brk
        asl     ZPAGE
        sta     $0398,y
        brk
        bcc     L64EA
L64EA:  ora     $09
        sta     $0280,y
        clc
        brk
        brk
        ora     (ZPAGE,x)
        brk
        brk
        lda     #$18
        sta     Z_REG
        lda     #$00
        sta     $14E2
        sta     $1980
        lda     $01FD
        cmp     #$1A
        beq     L650F
        lda     #$02
        jsr     LEE17
L650F:  ldx     $01FF
        lda     $1B06,x
        sta     $E2
        lda     $1B05,x
        sta     $E1
        bne     L6520
        dec     $E2
L6520:  dec     $E1
        clc
        lda     $1B05,x
        adc     #$02
        sta     $1B05,x
        bcc     L6530
        inc     $1B06,x
L6530:  ldy     #$00
        lda     ($E1),y
        cmp     #$FE
        bne     L653B
        jsr     L1981
L653B:  sta     $E0
        iny
        ldx     #$E1
        jsr     LF264
        bcc     L6546
        rts
L6546:  lda     #$20
        bit     $E0
        bpl     L6578
        lda     $E0
        and     #$3F
        sta     $E0
        bvc     L6566
        lda     #$A0
        sta     $E3
        ldx     #$5E
        ldy     #$F0
        lda     #$13
        jsr     LF1AD
        bcs     L65AA
        jmp     LF2F5
L6566:  lda     #$C0
        sta     $E3
        .byte   $A2
L656B:  ldx     $F0A0
        lda     #$05
        jsr     LF1AD
        bcs     L65AA
        jmp     LEF7D
L6578:  bvc     L65A8
        php
        lda     $E0
        and     #$1F
        sta     $E0
        plp
        beq     L6596
        lda     #$C0
        sta     $E3
        ldx     #$C6
        ldy     #$F0
        lda     #$05
        jsr     LF1AD
        bcs     L65AA
        jmp     LE48B
L6596:  lda     #$60
        sta     $E3
        ldx     #$DE
        ldy     #$F0
        lda     #$05
        jsr     LF1AD
        bcs     L65AA
        jmp     LF952
L65A8:  lda     #$01
L65AA:  jsr     LEE17
        stx     $E4
        sty     $E5
        cmp     $E0
        bcs     L65B9
        lda     #$01
        bcc     L65D1
L65B9:  lda     $E0
        asl     a
        asl     a
        sta     $E6
        lda     #$00
        sta     $14E5
        sta     $E7
        tay
        lda     ($E1),y
        ldy     $E6
        cmp     ($E4),y
        beq     L65D4
        lda     #$04
L65D1:  jsr     LEE17
L65D4:  sta     $EB
        inc     $E7
        inc     $E6
        lda     $E0
        ldx     $E3
        sta     ZPAGE,x
        inx
        lda     #$FF
        sta     $E8
        lda     $E8
        eor     #$FF
        sta     $E8
        bne     L65FD
        ldy     $E6
        lda     ($E4),y
        sta     $E9
        and     #$30
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        sta     I
        bpl     L660D
L65FD:  lda     $E9
        tay
        and     #$03
        sta     I
        tya
        asl     a
        asl     a
        asl     a
        asl     a
        sta     $E9
        inc     $E6
L660D:  bit     $E9
        bvs     L6642
        bmi     L6624
        ldy     $E7
L6615:  lda     ($E1),y
        sta     ZPAGE,x
        iny
        inx
        dec     I
        bpl     L6615
        sty     $E7
        jmp     LF259
L6624:  clc
        lda     $E1
        adc     $E7
        sta     ZPAGE,x
        inx
        lda     $E2
        adc     #$00
        sta     ZPAGE,x
        clc
        lda     $E7
        adc     I
        sta     $E7
        lda     $14E2
        sta     SXPAGE,x
        jmp     LF256
L6642:  bpl     L664C
        ldy     $E7
        iny
        iny
        lda     ($E1),y
        beq     L6653
L664C:  ldy     $E7
        jsr     LF264
        bcs     L6663
L6653:  inx
        inc     $E7
        inx
        inc     $E7
        dec     $EB
        beq     L6662
        bmi     L6662
        jmp     LF1E5
L6662:  clc
L6663:  rts
        lda     ($E1),y
        pha
        iny
        lda     ($E1),y
        beq     L6675
        sta     $01,x
        pla
        sta     ZPAGE,x
        ldy     #$00
        beq     L6685
L6675:  pla
        tay
        lda     CZPAGE,y
        sta     ZPAGE,x
        lda     $1A01,y
        sta     $01,x
        lda     $1601,y
        tay
L6685:  lda     $01,x
        cpy     #$8F
        bcc     L6699
        beq     L668F
        bcs     L66EF
L668F:  cmp     #$20
        bcc     L66EA
        cmp     #$B8
        bcs     L66EA
        bcc     L66E2
L6699:  cpy     #$80
        bcc     L66AA
        cmp     #$00
        beq     L66EA
        cmp     #$FF
        bne     L66D3
        iny
        lda     #$7F
        bne     L66E2
L66AA:  cpy     #$00
        bne     L66EF
        cmp     #$20
        bcc     L66EA
        cmp     #$B8
        bcs     L66EA
        cmp     #$A0
        bcs     L66E2
        pha
        lda     $01FC
        and     #$0F
        bne     L66C7
        pla
        ldy     #$8F
        bne     L66E2
L66C7:  ora     #$80
        tay
        pla
        sec
        sbc     #$20
        bne     L66D3
        dey
        lda     #$80
L66D3:  cpy     #$80
        bcc     L66E2
        cmp     #$01
        bne     L66E2
        cpy     #$80
        beq     L66EA
        dey
        lda     #$81
L66E2:  sta     $01,x
        tya
        sta     $1401,x
        clc
        rts
L66EA:  lda     #$05
        jsr     LEE17
L66EF:  lda     #$03
        jsr     LEE17
        ora     ($A5,x)
        ldy     #$C9
        php
        bcc     L670B
        beq     L670E
        cmp     #$0C
        bcc     L672B
        beq     L6732
        cmp     #$12
        beq     L673C
        cmp     #$13
        beq     L674D
L670B:  jmp     LBC00
L670E:  ldy     #$01
        lda     ($A1),y
        cmp     #$2E
        bne     L670B
        jsr     LF37A
        bcc     L6722
        lda     $1980
        cmp     #$46
        beq     L6723
L6722:  rts
L6723:  lda     #$00
        sta     $1980
        jmp     LBC00
L672B:  lda     $A1
L672D:  bpl     L670B
        jmp     LF37A
L6732:  lda     $A1
        bne     L672D
        jsr     LBC00
        jmp     LF37A
L673C:  lda     $A1
        beq     L6748
        cmp     #$04
        bcs     L6748
        sta     $F2F4
        rts
L6748:  lda     #$59
        jsr     LEE17
L674D:  ldy     #$00
        lda     $F2F4
        sta     ($A1),y
        rts
        ldy     #$C6
        ldy     #$A0
        ldy     #$86
        ldy     #$A0
        lda     ($A0,x)
        ldy     #$84
        ldy     #$9D
        lda     ($A0),y
        sty     $A0,x
        ldy     #$F0
        ldy     #$E5
        ldy     #$A7
        ldy     #$A0
        ldx     #$A0
        ldy     #$84
        ldy     #$A0
        stx     $A0,y
        ldy     #$8E
        ldy     #$A5
        ldy     #$C9
        php
        beq     L679B
        cmp     #$09
        beq     L67C6
        cmp     #$0A
        beq     L67F3
        cmp     #$0B
        bne     L678F
        jmp     LF428
L678F:  cmp     #$0C
        bne     L6796
        jmp     LF44F
L6796:  lda     #$01
        jsr     LEE17
L679B:  jsr     LF4C3
        bcs     L67C5
        sta     $C1
        jsr     LF4F2
        bcs     L67C5
        ldx     #$00
        sta     ($A3,x)
        cpy     #$01
        bne     L67B8
        lda     #$06
        sta     D_TPARMX
        jsr     LEF7D
        bcs     L67B9
L67B8:  rts
L67B9:  lda     $1980
        beq     L67B8
        ldx     #$00
        lda     ($A3,x)
        jsr     LF517
L67C5:  rts
L67C6:  lda     #$03
        sta     D_TPARMX
        lda     $A1
        jsr     LF53F
        bcs     L67F2
        sta     $C1
        lda     #$02
        sta     $C2
        lda     #$55
        sta     $C3
        lda     #$F3
        sta     $C4
        lda     #$00
        sta     $14C4
        lda     $A2
        sta     $F355
        lda     $A3
        sta     $F356
        jsr     LEF7D
        rts
L67F2:  rts
L67F3:  lda     #$00
        sta     D_TPARMX
        lda     $A1
        jsr     LF53F
        bcs     L6827
        sta     $C1
        ldx     #$03
L6802:  lda     $A2,x
        sta     $C2,x
        dex
        bpl     L6802
        lda     $A6
        sta     $C8
        lda     $A7
        sta     $C9
        lda     $14A3
        sta     $14C3
        lda     $14A5
        sta     $14C5
        lda     $14A7
        sta     $14C9
        jsr     LEF7D
        rts
L6827:  rts
        lda     #$01
        sta     D_TPARMX
        lda     $A1
        jsr     LF53F
        bcs     L684E
        sta     $C1
        ldx     #$03
L6837:  lda     $A2,x
        sta     $C2,x
        dex
        bpl     L6837
        lda     $14A3
        sta     $14C3
        lda     $14A5
        sta     $14C5
        jsr     LEF7D
        rts
L684E:  rts
        lda     #$07
        sta     D_TPARMX
        lda     $A1
        beq     L6865
        jsr     LF517
        bcs     L6864
        sta     $C1
        tya
        bne     L6864
        jsr     LEF7D
L6864:  rts
L6865:  lda     #$00
        ldx     MAX_DNUM
L686A:  sta     $0200,x
        dex
        bpl     L686A
        ldx     #$10
L6872:  .byte   $BD
        cli
L6874:  .byte   $F3
        tay
        bmi     L6889
        lda     $F369,x
        cmp     $F2F4
        bcc     L6889
        lda     #$80
        sta     $0200,y
        sec
        ror     $F358,x
L6889:  dex
        bne     L6872
        ldx     #$10
L688E:  lda     $F358,x
        tay
        bmi     L6899
        lda     #$00
        sta     $0200,y
L6899:  dex
        bne     L688E
        lda     #$00
        sta     $AF
        ldx     MAX_DNUM
L68A3:  lda     $0200,x
        bpl     L68B8
        txa
        pha
        stx     $C1
        jsr     LEF7D
        pla
        tax
        lda     $1980
        beq     L68B8
        sta     $AF
L68B8:  dex
        bne     L68A3
        lda     $AF
        bne     L68C0
        rts
L68C0:  jsr     LEE17
        lda     #$04
        sta     D_TPARMX
        lda     $A1
        sta     $C1
        lda     $A2
        sta     $C2
        lda     #$57
        sta     $C3
        lda     #$F3
        sta     $C4
        lda     $14A2
        sta     $14C2
        lda     #$00
        sta     $14C4
        jsr     LEF7D
        bcs     L68ED
        bmi     L68ED
        lda     $F357
        rts
L68ED:  lda     #$46
        jsr     LEE17
        ldx     #$10
        tay
L68F5:  lda     $F358,x
        bmi     L6902
        dex
        bne     L68F5
        lda     #$41
        jsr     LEE17
L6902:  tya
        sta     $F358,x
        lda     $F2F4
L6909:  sta     $F369,x
        txa
        pha
        tya
        jsr     LF531
        pla
        ora     #$80
        clc
        rts
        and     #$7F
        cmp     #$11
        bcs     L692C
        tax
        .byte   $BD
        cli
L6920:  .byte   $F3
        bmi     L692C
        sec
        ror     $F358,x
        jsr     LF531
        clc
        rts
L692C:  lda     #$43
        jsr     LEE17
        ldy     #$00
        ldx     #$10
L6935:  cmp     $F358,x
        bne     L693B
        iny
L693B:  dex
        bne     L6935
        rts
        and     #$7F
        cmp     #$11
        bcs     L694D
        tax
        lda     $F358,x
        bmi     L694D
        clc
        rts
L694D:  lda     #$43
        jsr     LEE17
        tax
        ldy     #$A0
        lda     $D0
        ldy     #$8E
        sta     $D2BF,y
        .byte   $C7
        ldy     #$FF
        ldx     #$A0
        lda     $AA
        ldy     #$88
        ldy     #$A0
        beq     L6909
        ldy     #$90
        ldy     #$80
        .byte   $82
        ldy     #$89
        txs
        cmp     $C5
        ldy     #$A0
        cmp     $A0
        .byte   $C3
        .byte   $D3
        ldy     #$D3
        .byte   $D2
        .byte   $D2
        ldy     #$C8
        ldy     #$BA
        sta     ($A0),y
        dey
        ldy     #$A0
        .byte   $87
        ldy     #$A0
        sbc     $A0,x
        ldy     #$91
        ldy     #$A0
        ldx     #$A0
        ldy     #$BF
        ldy     #$85
        ldy     #$A0
        ldy     #$A0
        ldy     #$C6
        ldy     #$A0
        ldy     #$A0
        cmp     $C5,x
        ldx     $C6AA
        ldy     #$85
        ldy     #$A0
        txa
        ldy     #$A0
        ldy     #$A0
        ldy     #$85
        ldy     #$A0
        .byte   $82
        ldy     #$A0
        ldy     #$D2
        ldx     #$A0
        .byte   $C3
        ldx     #$A0
        cpy     $A0D3
        ldy     #$90
        ldy     #$A0
        ldy     #$A0
        ldy     #$A8
        beq     L6A1D
        cpy     #$41
        bcs     L6A1D
        sty     $F559
        jsr     LF840
        bcs     L6A13
        stx     $F55A
        lda     $F559
        jsr     LF7F9
        bcs     L6A18
        ldx     $F55A
        dec     $F559
        lda     $F559
        sta     $F55E,x
        ldx     $F554
        ldy     $F555
        jsr     LF851
        cpx     #$8F
        bne     L69FA
        ldx     #$7F
L69FA:  txa
        ldx     $F55A
        sta     $F56F,x
        tya
        sta     $F580,x
        lda     $F558
        sta     $F591,x
        lda     #$00
        sta     $F5A2,x
        txa
        clc
        rts
L6A13:  lda     #$55
        jsr     LEE17
L6A18:  lda     #$54
        jsr     LEE17
L6A1D:  lda     #$10
        jsr     LEE2A
        tay
        beq     L6A81
        cpy     #$41
        bcs     L6A81
        sty     $F55B
        jsr     LF840
        bcs     L6A77
        stx     $F55C
        ldy     #$03
        lda     ($A5),y
        bne     L6A7C
        dey
        lda     ($A5),y
        tay
        lda     $1601,y
        bpl     L6A7C
        cmp     #$8F
        bcs     L6A7C
        ldx     $F55C
        sta     $F56F,x
        lda     $1A01,y
        beq     L6A7C
        cmp     #$81
        bcc     L6A5B
        inc     $F56F,x
        and     #$7F
L6A5B:  sta     $F580,x
        lda     CZPAGE,y
        sta     $F591,x
        dec     $F55B
        lda     $F55B
        ora     #$40
        sta     $F55E,x
        lda     #$00
        sta     $F5A2,x
        txa
        clc
        rts
L6A77:  lda     #$55
        jsr     LEE17
L6A7C:  lda     #$56
        jsr     LEE17
L6A81:  lda     #$10
        jsr     LEE2A
        tay
        beq     L6ACC
        cpy     #$11
        bcs     L6ACC
        lda     $F55E,y
        bmi     L6ACC
        jsr     LF6D1
        stx     $F5C4
        tya
        ldx     $F5B3
        beq     L6AA6
L6A9E:  cmp     $F5B3,x
        beq     L6AC2
        dex
        bne     L6A9E
L6AA6:  inc     $F5B3
        ldx     $F5B3
        cpx     #$11
        bcs     L6ACC
        sta     $F5B3,x
        lda     $F5A2,y
        beq     L6AC2
        ldx     $F5C4
        lda     (ZPAGE,x)
        cmp     $F5A2,y
        bne     L6ACC
L6AC2:  lda     $F55E,y
        and     #$3F
        clc
        adc     #$01
        clc
        rts
L6ACC:  lda     #$0F
        jsr     LEE2A
        and     #$40
        bne     L6AD9
        lda     #$00
        beq     L6ADC
L6AD9:  lda     $F591,y
L6ADC:  sta     ZPAGE,x
        lda     $F580,y
        sta     $01,x
        lda     $F56F,y
        ora     #$80
        sta     $1401,x
        rts
        ldy     $F5B3
        beq     L6B0F
        lda     #$18
        sta     Z_REG
L6AF6:  ldx     #$70
        lda     $F5B3,y
        tay
        lda     $F55E,y
        jsr     LF6D1
        lda     (ZPAGE,x)
        sta     $F5A2,y
        dec     $F5B3
        ldy     $F5B3
        bne     L6AF6
L6B0F:  rts
        tay
        beq     L6B38
        cpy     #$11
        bcs     L6B38
        lda     $F55E,y
        bmi     L6B38
        ora     #$80
        sta     $F55E,y
        and     #$40
        bne     L6B36
        lda     #$05
        sta     $60
        lda     $F591,y
        sta     $61
        jsr     LF952
        bcs     L6B38
        jsr     LF73D
L6B36:  clc
        rts
L6B38:  lda     #$0F
        jsr     LEE2A
        ldy     #$00
        ldx     #$10
L6B41:  lda     $F55E,x
        and     #$C0
        bne     L6B58
        lda     $F580,x
        cmp     $F580,y
        lda     $F56F,x
        sbc     $F56F,y
        bcs     L6B58
        txa
        tay
L6B58:  dex
        bne     L6B41
        tya
        bne     L6B61
        jmp     LF7ED
L6B61:  sty     $F55D
        lda     $F55E,y
        and     #$3F
        clc
        adc     #$01
        jsr     LF7F9
        bcs     L6BED
        ldx     $F554
        ldy     $F555
        jsr     LF851
        stx     $F554
        sty     $F555
        ldy     $F55D
        lda     $F580,y
        sta     $71
        cmp     $F555
        lda     $F56F,y
        sta     $1471
        sbc     $F554
        bcs     L6BDF
        ldx     $F554
        stx     $1473
        ldy     $F555
        sty     $73
        lda     #$00
        sta     $70
        sta     $72
        tay
        ldx     $F552
L6BAB:  lda     ($70),y
        sta     ($72),y
        dey
        bne     L6BAB
        inc     $71
        inc     $73
        dex
        bne     L6BAB
        ldy     $F55D
        lda     $F554
        sta     $F56F,y
        lda     $F555
        sta     $F580,y
        ldx     $F591,y
        lda     $F558
        sta     $F591,y
        stx     $61
        lda     #$05
        sta     $60
        jsr     LF952
        bcs     L6BF4
        jmp     LF73D
L6BDF:  ldx     $F558
        stx     $61
        lda     #$05
        sta     $60
        jsr     LF952
        bcs     L6BF4
L6BED:  lda     #$00
        sta     $1980
        clc
        rts
L6BF4:  lda     #$0F
        jsr     LEE2A
        sta     $F552
        lda     #$01
        sta     $60
        lda     #$02
        sta     $61
        lda     #$04
        sta     $62
        lda     #$52
        sta     $63
        lda     #$F5
        sta     $64
        lda     #$54
        sta     $65
        lda     #$F5
        sta     $66
        lda     #$56
        sta     $67
        lda     #$F5
        sta     $68
        lda     #$58
        sta     $69
        lda     #$F5
L6C26:  sta     $6A
        lda     #$00
        sta     $F553
        sta     $1464
        sta     $1466
        sta     $1468
        sta     $146A
        .byte   $20
L6C3A:  .byte   $52
        sbc     $52AD,y
        sbc     $60,x
        ldx     #$10
L6C42:  lda     $F55E,x
        bmi     L6C4F
        dex
        bne     L6C42
        lda     #$55
        jsr     LEE17
L6C4F:  clc
        rts
        cpy     #$20
        bne     L6C64
        txa
        bne     L6C5C
        ldx     #$8F
        bmi     L6C6D
L6C5C:  ora     #$80
        tax
        dex
        ldy     #$80
        bmi     L6C6D
L6C64:  txa
        ora     #$80
        tax
        sec
        tya
        sbc     #$20
        tay
L6C6D:  rts
        ldy     #$A0
        lda     #$A0
        cmp     $AF
        ldy     #$A0
        cpx     #$A0
        .byte   $C3
        ldy     #$A0
        tsx
        cmp     $A0,x
        .byte   $D4
        ldy     #$A0
        .byte   $C3
        ldy     #$A0
        bcc     L6C26
L6C86:  ldy     #$9E
        ldy     #$A0
        cpx     #$A0
        sta     $A09E,x
        .byte   $9F
        ldy     #$A0
        .byte   $A7
        ldy     #$A0
        .byte   $80
        .byte   $A0
L6C97:  ldy     #$F0
        ldy     #$D5
        inc     $A0AE
        ldy     #$D3
        ldx     #$A0
        ldy     #$A2
        ldy     #$A0
        ldy     #$A0
        ldy     #$B1
        ldy     #$A0
        .byte   $D3
        ldy     #$A0
        ldy     #$A0
        .byte   $C2
        ldy     #$A0
        lda     $A0
        ldy     #$99
        ldy     #$A0
        iny
        ldy     #$A0
        sbc     $85C7,x
        ldy     #$CD
        sty     $CCA0
        stx     $A0,y
        ldy     #$99
        .byte   $C3
        .byte   $D2
        dec     $C1C3
        .byte   $C7
        cmp     $A08A
        ldy     #$F9
        ldy     #$A0
        sbc     #$A0
        .byte   $80
        .byte   $80
        ldy     #$FF
        ldx     #$A0
        sta     $AA,x
        ldy     #$88
        ldy     #$A0
        beq     L6C86
        .byte   $CF
        bcc     L6C97
        .byte   $80
        .byte   $82
        .byte   $CF
L6CEC:  .byte   $89
        txs
        ldy     #$C5
        ldy     #$A0
        cmp     $A0
        ldy     #$D3
        ldy     #$A0
        .byte   $D2
        ldy     #$80
        iny
        ldy     #$A0
        sta     ($A0),y
        dey
        ldy     #$A0
        .byte   $87
        ldy     #$A0
        sbc     $A0,x
        ldy     #$91
        ldy     #$A0
        ldx     #$A0
        ldy     #$BF
        .byte   $C7
        sta     $A0
        ldy     #$A0
        ldy     #$C9
        .byte   $F4
        ldy     #$A0
        ldy     #$A0
        ldy     #$C5
        ldy     #$AA
        dec     $A0
        sta     $A0
        ldy     #$8A
        ldy     #$A0
        ldy     #$A0
        ldy     #$85
        ldy     #$A0
        .byte   $82
        ldy     #$A6
        ldy     #$A0
        sta     ($A0,x)
        cmp     $9A
        ldy     #$A0
        cpy     $C3AE
        stx     $D3AE
        iny
        ldy     #$A2
        ldy     #$A0
        .byte   $C2
        ldy     #$A0
        .byte   $D3
        ldy     #$A0
        bcc     L6CEC
        ldy     #$CC
        ldy     #$D3
        ldy     #$91
        lda     $60
        beq     L6D6F
        cmp     #$01
        beq     L6D72
        cmp     #$02
        beq     L6D75
        cmp     #$03
        beq     L6D78
        cmp     #$04
        beq     L6D7B
        cmp     #$05
        beq     L6D7E
        lda     #$01
        jsr     LEE17
L6D6F:  jmp     LF981
L6D72:  jmp     LFA23
L6D75:  jmp     LFC2F
L6D78:  jmp     LFDC8
L6D7B:  jmp     LFE27
L6D7E:  jmp     LFE67
        ldx     $61
        ldy     $62
        jsr     LFEC2
        bcc     L6D8B
L6D8A:  rts
L6D8B:  stx     $61
        sty     $62
        sta     $42
        ldx     $63
        ldy     $64
        jsr     LFEC2
        bcs     L6D8A
        stx     $63
        sty     $64
        cmp     $42
        bne     L6E14
        lda     $63
        cmp     $61
        lda     $64
        sbc     $62
        bcc     L6E14
        ldx     #$00
        ldy     $F86F
        beq     L6DED
        lda     $F8F0,y
        cmp     $61
        lda     $F910,y
        sbc     $62
        bcc     L6DED
L6DBF:  tya
        tax
        lda     $F890,y
        tay
        bne     L6DD5
        lda     $63
        cmp     $F8B0,x
        lda     $64
        sbc     $F8D0,x
        bcc     L6DED
        bcs     L6E19
L6DD5:  lda     $63
        cmp     $F8B0,x
        lda     $64
        sbc     $F8D0,x
        bcs     L6E19
        lda     $F8F0,y
        cmp     $61
        lda     $F910,y
        sbc     $62
        bcs     L6DBF
L6DED:  txa
        jsr     LFF76
        bcs     L6E1E
        tax
        lda     $61
        sta     $F8B0,x
        lda     $62
        sta     $F8D0,x
        lda     $63
        sta     $F8F0,x
        lda     $64
        sta     $F910,x
        lda     $65
        sta     $F930,x
        ldy     #$00
        txa
        sta     ($66),y
        clc
        rts
L6E14:  lda     #$E0
        jsr     LEE17
L6E19:  lda     #$E1
        jsr     LEE17
L6E1E:  lda     #$E2
        jsr     LEE17
        ldy     #$00
        lda     ($63),y
        sta     $43
        iny
        lda     ($63),y
        sta     $44
        bne     L6E39
        lda     $43
        bne     L6E39
        lda     #$E7
        jsr     LEE17
L6E39:  lda     #$00
        sta     $45
        lda     $61
        cmp     #$03
        bcc     L6E48
        lda     #$E5
        jsr     LEE17
L6E48:  .byte   $20
L6E49:  sbc     ($FA),y
        lda     #$00
        sta     $55
        sta     $56
L6E51:  jsr     LFB31
        bcc     L6E5F
        lda     #$80
        sta     $45
        ldx     #$00
        jmp     LFAB8
L6E5F:  lda     $55
        cmp     $46
        lda     $56
        sbc     $47
        bcs     L6E72
        ldx     #$06
L6E6B:  lda     $46,x
        sta     $55,x
        dex
        bpl     L6E6B
L6E72:  lda     $55
        cmp     $43
        lda     $56
        sbc     $44
        bcc     L6E51
        lda     $59
        sbc     $43
        sta     $57
        lda     $5A
        sbc     $44
        sta     $58
        inc     $57
        bne     L6E8E
        inc     $58
L6E8E:  lda     $43
        sta     $55
        lda     $44
        sta     $56
        lda     $5B
        jsr     LFF76
        bcc     L6E9E
        rts
L6E9E:  tax
        lda     $62
        sta     $F930,x
        lda     $57
        sta     $F8B0,x
        lda     $58
        sta     $F8D0,x
        lda     $59
        sta     $F8F0,x
        lda     $5A
        sta     $F910,x
        ldy     #$00
        txa
        sta     ($69),y
        lda     $55
        sta     ($63),y
        iny
        lda     $56
        sta     ($63),y
        ldx     $57
        ldy     $58
        jsr     LFF05
        tya
        ldy     #$01
        sta     ($65),y
        dey
        txa
        sta     ($65),y
        ldx     $59
        ldy     $5A
        jsr     LFF05
        tya
        ldy     #$01
        sta     ($67),y
        dey
        txa
        sta     ($67),y
        lda     $45
        bne     L6EEC
        clc
        rts
L6EEC:  lda     #$E1
        jsr     LEE17
        lda     a:$40
        sta     $53
        lda     a:$41
        sta     $54
        lda     #$00
        sta     $52
        ldx     $F86F
        stx     $51
        beq     L6F30
        lda     a:$40
        cmp     $F8F0,x
        lda     a:$41
        sbc     $F910,x
        bcs     L6F1F
        stx     $52
        lda     $F890,x
        tax
        stx     $51
        jmp     LFB04
L6F1F:  lda     $F8F0,x
        cmp     a:$40
        lda     $F910,x
        sbc     a:$41
        bcc     L6F30
        jsr     LFC05
L6F30:  rts
        lda     $54
        bpl     L6F37
        sec
        rts
L6F37:  lda     $52
        sta     $4C
        lda     $53
        sta     $4A
        lda     $54
        sta     $4B
        lda     $51
        bne     L6F4F
        lda     #$00
        sta     $48
        sta     $49
        beq     L6F60
L6F4F:  ldx     $51
        clc
        lda     $F8F0,x
        adc     #$01
        sta     $48
        lda     $F910,x
        adc     #$00
        sta     $49
L6F60:  ldy     $4B
        sty     $4E
        lda     $4A
        and     #$80
        sta     $4D
        sec
        sbc     #$80
        sta     $4F
        tya
        sbc     #$00
        sta     $50
        bcs     L6F7C
L6F76:  lda     #$00
        sta     $4F
        sta     $50
L6F7C:  lda     $48
        cmp     $4D
        lda     $49
        sbc     $4E
        bcs     L6FAD
        lda     $61
        bne     L6F95
        lda     $4D
        sta     $48
        lda     $4E
        sta     $49
        jmp     LFBAD
L6F95:  lda     $48
        cmp     $4F
        lda     $49
        sbc     $50
        bcs     L6FAD
        lda     $61
        cmp     #$01
        bne     L6FAD
        lda     $4F
        sta     $48
        lda     $50
        sta     $49
L6FAD:  sec
        lda     $4A
        sbc     $48
        sta     $46
        lda     $4B
        sbc     $49
        sta     $47
        inc     $46
        bne     L6FC0
        inc     $47
L6FC0:  lda     $61
        cmp     #$01
        bne     L6FDF
        lda     $48
        cmp     $4D
        lda     $49
        sbc     $4E
        bcs     L6FDF
        ldy     $4E
        ldx     $4D
        bne     L6FD7
        dey
L6FD7:  dex
        stx     $53
        sty     $54
        jmp     LFC03
L6FDF:  sec
        lda     $48
        sbc     #$01
        sta     $53
        lda     $49
        sbc     #$00
        sta     $54
        bcc     L7003
        lda     $51
        beq     L7003
        ldx     $51
        lda     $F8F0,x
        cmp     $53
        lda     $F910,x
        sbc     $54
        bcc     L7003
        jsr     LFC05
L7003:  clc
        rts
L7005:  ldx     $51
        sec
        lda     $F8B0,x
        sbc     #$01
        sta     $53
        lda     $F8D0,x
        sbc     #$00
        sta     $54
        bcc     L702E
        stx     $52
        lda     $F890,x
        tax
        stx     $51
        beq     L702E
        lda     $F8F0,x
        cmp     $53
        lda     $F910,x
        sbc     $54
        bcs     L7005
L702E:  rts
        ldy     #$00
        lda     ($63),y
        sta     $5C
        iny
        lda     ($63),y
        sta     $5D
        ldx     $61
        beq     L7047
        cpx     #$20
        bcs     L7047
        lda     $F890,x
        bpl     L704C
L7047:  lda     #$E3
        jsr     LEE17
L704C:  ldy     $62
        cpy     #$01
        bcc     L705F
        beq     L7089
        cpy     #$03
        bcc     L709C
        beq     L70AF
        lda     #$E6
        jsr     LEE17
L705F:  clc
        lda     $F8B0,x
        adc     $5C
        sta     $5E
        lda     $F8D0,x
        adc     $5D
        sta     $5F
        bcs     L707C
        lda     $F8F0,x
        cmp     $5E
        lda     $F910,x
        sbc     $5F
        bcs     L7086
L707C:  lda     $F8F0,x
        sta     $5E
        lda     $F910,x
        sta     $5F
L7086:  jmp     LFD48
L7089:  sec
        lda     $F8B0,x
        sbc     $5C
        sta     $5E
        lda     $F8D0,x
        sbc     $5D
        sta     $5F
        bcs     L70D9
        bcc     L70E6
L709C:  clc
        lda     $F8F0,x
        adc     $5C
        sta     $5E
        lda     $F910,x
        adc     $5D
        sta     $5F
        bcc     L70D9
        bcs     L70E6
L70AF:  sec
        lda     $F8F0,x
        sbc     $5C
        sta     $5E
        lda     $F910,x
        sbc     $5D
        sta     $5F
        bcc     L70CC
        lda     $5E
        cmp     $F8B0,x
        lda     $5F
        sbc     $F8D0,x
        bcs     L70D6
L70CC:  lda     $F8B0,x
        sta     $5E
        lda     $F8D0,x
        sta     $5F
L70D6:  jmp     LFD48
L70D9:  ldx     $5E
        ldy     $5F
        jsr     LFF24
        bcs     L70E6
        bne     L70E6
        beq     L70FD
L70E6:  lda     $62
        cmp     #$01
        bne     L70F3
        ldx     #$00
        ldy     #$00
        jmp     LFCF9
L70F3:  ldx     a:$40
        ldy     a:$41
        stx     $5E
        sty     $5F
L70FD:  ldx     $61
        lda     $62
        cmp     #$01
        bne     L7125
        lda     $F890,x
        beq     L7148
        tay
        lda     $F8F0,y
        tax
        lda     $F910,y
        tay
        inx
        bne     L7117
        iny
L7117:  cpy     $5F
        bcc     L7148
        beq     L711F
        bcs     L7144
L711F:  cpx     $5E
        bcc     L7148
        bcs     L7144
L7125:  lda     $F870,x
        beq     L7148
        tay
        lda     $F8B0,y
        tax
        lda     $F8D0,y
        tay
        txa
        bne     L7137
        dey
L7137:  dex
        cpy     $5F
        bcc     L7144
        beq     L7140
        bcs     L7148
L7140:  cpx     $5E
        bcs     L7148
L7144:  stx     $5E
        sty     $5F
L7148:  ldx     $61
        ldy     #$00
        lda     $62
        cmp     #$01
        bcc     L715A
        beq     L716A
        cmp     #$03
        bcc     L717A
        beq     L718A
L715A:  sec
        lda     $5E
        sbc     $F8B0,x
        sta     ($63),y
        lda     $5F
        sbc     $F8D0,x
        jmp     LFD97
L716A:  sec
        lda     $F8B0,x
        sbc     $5E
        sta     ($63),y
        lda     $F8D0,x
        sbc     $5F
        jmp     LFD97
L717A:  sec
        lda     $5E
        sbc     $F8F0,x
        sta     ($63),y
        lda     $5F
        sbc     $F910,x
        jmp     LFD97
L718A:  sec
        lda     $F8F0,x
        sbc     $5E
        sta     ($63),y
        lda     $F910,x
        sbc     $5F
        iny
        sta     ($63),y
        tax
        dey
        lda     ($63),y
        cmp     $5C
        txa
        sbc     $5D
        bcs     L71AA
        lda     #$E1
        jsr     LEE17
L71AA:  ldx     $61
        lda     $62
        cmp     #$02
        lda     $5E
        ldy     $5F
        bcs     L71BF
        sta     $F8B0,x
        tya
        sta     $F8D0,x
        clc
        rts
L71BF:  sta     $F8F0,x
        tya
        sta     $F910,x
        clc
        rts
        ldx     $61
        beq     L7222
        cpx     #$20
        bcs     L7222
        lda     $F890,x
        bmi     L7222
        ldy     $F8D0,x
        lda     $F8B0,x
        tax
        jsr     LFF05
        tya
        ldy     #$01
        sta     ($62),y
        dey
        txa
        sta     ($62),y
        ldx     $61
        ldy     $F910,x
        lda     $F8F0,x
        tax
        jsr     LFF05
        tya
        ldy     #$01
        sta     ($64),y
        dey
        txa
        sta     ($64),y
        ldx     $61
        lda     $F930,x
        sta     ($68),y
        sec
        lda     $F8F0,x
        sbc     $F8B0,x
        tay
        lda     $F910,x
        sbc     $F8D0,x
        tax
        iny
        bne     L7217
        inx
L7217:  tya
        ldy     #$00
        sta     ($66),y
        iny
        txa
        sta     ($66),y
        clc
        rts
L7222:  lda     #$E3
        jsr     LEE17
        ldx     $61
        ldy     $62
        jsr     LFEC2
        bcs     L7261
        stx     $61
        sty     $62
        lda     $F86F
        beq     L7262
        tax
        lda     $F8F0,x
        cmp     $61
        lda     $F910,x
        sbc     $62
        bcc     L7262
        lda     $61
        cmp     $F8B0,x
        lda     $62
        sbc     $F8D0,x
        bcs     L725A
        lda     $F890,x
        beq     L7262
        jmp     LFE39
L725A:  ldy     #$00
        txa
        sta     ($63),y
        clc
        rts
L7261:  rts
L7262:  lda     #$E4
        jsr     LEE17
        ldx     $61
        .byte   $F0
L726A:  .byte   $0B
        cpx     #$20
        bcs     L72BD
        .byte   $BD
L7270:  bcc     L726A
        bmi     L72BD
        bpl     L7295
L7276:  ldx     $F86F
        beq     L7293
        stx     $61
L727D:  lda     $F930,x
        cmp     #$10
        lda     $F890,x
        pha
        bcc     L728B
        jsr     LFE95
L728B:  pla
        beq     L7293
        sta     $61
        tax
        bne     L727D
L7293:  clc
        rts
L7295:  tay
        lda     $F870,x
        tax
        beq     L72A3
        tya
        sta     $F890,x
        jmp     LFEA7
L72A3:  sty     $F86F
        tya
        beq     L72AD
        txa
        sta     $F870,y
L72AD:  lda     $F86E
        ldx     $61
        sta     $F890,x
        txa
        ora     #$80
        sta     $F86E
        clc
        rts
L72BD:  lda     #$E3
        jsr     LEE17
        tya
        cpx     #$0F
        beq     L72D7
        bcs     L72E1
        cmp     #$20
        bcc     L7300
        cmp     #$A0
        bcs     L7300
        sec
        sbc     #$20
        jmp     LFEEC
L72D7:  cmp     #$20
        bcs     L7300
        clc
        adc     #$80
        jmp     LFEEC
L72E1:  cpx     #$10
        bne     L7300
        cmp     #$A0
        bcc     L7300
        sec
        sbc     #$80
        tay
        txa
        lsr     a
        tax
        tya
        bcc     L72F5
        ora     #$80
L72F5:  pha
        txa
        tay
        pla
        tax
        jsr     LFF24
        bcs     L7300
        rts
L7300:  lda     #$E0
        jsr     LEE17
        txa
        asl     a
        txa
        and     #$7F
        tax
        tya
        rol     a
        tay
        txa
        cpy     #$0F
        beq     L731E
        bcs     L731B
        clc
        adc     #$20
        jmp     LFF1E
L731B:  clc
        adc     #$80
L731E:  pha
        tya
        tax
        pla
        tay
        rts
        stx     $F950
        sty     $F951
        lda     #$7F
        cmp     $F950
        lda     #$08
        sbc     $F951
        bcc     L7374
        lda     $F950
        cmp     #$20
        lda     $F951
        sbc     #$08
        bcc     L7346
        lda     #$02
        bne     L7372
L7346:  lda     #$9F
        cmp     $F950
        lda     #$07
        sbc     $F951
        bcc     L7374
        lda     $F950
        cmp     #$80
        lda     $F951
        sbc     #$07
        bcc     L7362
        lda     #$01
        bne     L7372
L7362:  lda     a:$40
        cmp     $F950
        lda     a:$41
        sbc     $F951
        bcc     L7374
        lda     #$00
L7372:  clc
        rts
L7374:  sec
        rts
        tax
        lda     $F86E
        cmp     #$80
        beq     L73BA
        and     #$7F
        tay
        lda     $F890,y
        sta     $F86E
        cpx     #$00
        bne     L739C
        lda     $F86F
        sta     $F890,y
        lda     #$00
        sta     $F870,y
        sty     $F86F
        jmp     LFFAA
L739C:  lda     $F890,x
        sta     $F890,y
        txa
        sta     $F870,y
        tya
        sta     $F890,x
        lda     $F890,y
        beq     L73B7
        lda     $F890,y
        tax
        tya
        sta     $F870,x
L73B7:  tya
        clc
        rts
L73BA:  lda     #$E2
        jsr     LEE17
FreeSpace:
	.res	$7400-FreeSpace,$00
LDREND	:= *
FILE	:= *-$2000+$400