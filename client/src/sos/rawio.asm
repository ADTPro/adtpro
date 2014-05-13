;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2014 by David Schmidt
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

KBDATA		:= $57
LMARGIN		:= $0058
RMARGIN		:= $0059
WINTOP		:= $005A
WINBTM		:= $005B
CH		:= $005C
CV		:= $005D
BAS4L		:= $005E
BASL		:= BAS4L	; Compatibility with II ROM
BAS4H		:= $005F
BASH		:= BAS4H	; Compatibility with II ROM
BAS8L		:= $0060
BAS8H		:= $0061
TBAS4L		:= $0062
TBAS4H		:= $0063
TBAS8L		:= $0064
TBAS8H		:= $0065
FORGND		:= $0066
BKGND		:= $0067
MODES		:= $0068
CURSOR		:= $0069
STACK		:= $006A
PROMPT		:= $006B
TEMPX		:= $006C
TEMPY		:= $006D
CSWL		:= $006E
CSWH		:= $006F
KSWL		:= $0070
KSWH		:= $0071
PCL		:= $0072
PCH		:= $0073
A1L		:= $0074
A1H		:= $0075
A2L		:= $0076
A2H		:= $0077
A3L		:= $0078
A3H		:= $0079
A4L		:= $007A
A4H		:= $007B
STATE		:= $007C
YSAV		:= $007D
INBUF		:= $007E
TWOMEG		:= $007F
HRDERRS		:= $0080
RDTEMP		:= $0080
L03F8		:= $03F8
Q6L		:= $C08C
Q6H		:= $C08D
Q7L		:= $C08E
ACIASTAT	:= $C0F1

SETUP:	cld
	ldx #$03
@Loop:	lda HOOKS,x
	sta CSWL,x
	lda VBOUNDS,x
	sta LMARGIN,x
	dex
	bpl @Loop
	lda #$00
	sta INBUF
	lda #$1e
	sta INBUF+1
	lda #$BF
	sta MODES
	rts
ENTRY:	tsx
	stx STACK
MON:	cld
	jsr BELL
MONZ:	ldx STACK
	txs
	lda #$DF
	sta PROMPT
	jsr GETLN
SCAN:	jsr ZSTATE
NXTINP:	jsr GETNUM
	sty YSAV
	ldy #$12
CMDSRCH:
	dey
	bmi MON
	cmp CMDTAB,y
	bne CMDSRCH
	jsr TOSUB
	ldy YSAV
	jmp NXTINP
GETNUM:	ldx #$00
	stx A2L
	stx A2H
NXTCHR:	lda (INBUF),y
	iny
	eor #$B0
	cmp #$0A
	bcc DIGIT
	adc #$88
	cmp #$FA
	bcc DIGRET
DIGIT:	ldx #$03
	asl a
	asl a
	asl a
	asl a
NXTBIT:	asl a
	rol A2L
	rol A2H
	dex
	bpl NXTBIT
NXTBAS:	lda STATE
	bne NXTBS2
	lda A2H,x
	sta A1H,x
	sta A3H,x
NXTBS2:	inx
	beq NXTBAS
	bne NXTCHR
TOSUB:	lda #$FA
	pha
	lda CMDVEC,y
	pha
	lda STATE
ZSTATE:	ldy #$00
	sty STATE
DIGRET:	rts
CMDTAB:	.byte $00,$03,$06,$EB,$EC,$EE,$EF,$F0
	.byte $F1,$99,$9B,$A0,$93,$A7,$A8,$95
	.byte $C6
CMDVEC:	.byte $90,$8E,$3F,$D3,$08,$8B,$4E,$D6
	.byte $2C,$B7,$1A,$1C,$CB,$CB,$AD,$A4
	.byte $39
NXTA4:	inc A4L
	bne NXTA1
	inc A4H
NXTA1:	inc A1L
	bne TSTA1
	inc A1H
	sec
	beq RETA1
TSTA1:	lda A1L
	sec
	sbc A2L
	sta HRDERRS
	lda A1H
	sbc A2H
	ora HRDERRS
	bne RETA1
	clc
RETA1:  rts
PRBYTE: pha
	lsr a
	lsr a
	lsr a
	lsr a
	jsr PRHEXZ
	pla
PRHEX:  and #$0F
PRHEXZ: ora #$B0
	cmp #$BA
	bcc PRHEX2
	adc #$06
PRHEX2: jmp COUT
PRBYCOL:jsr PRBYTE
PRCOLON:lda #$BA
	bne PRHEX2
TST80WID:
	lda #$07
	bit MODES
	bvc SVMASK
	lda #$0F
SVMASK:	sta CURSOR
	rts
A1PC:	txa
	beq OLDPC
A1PC1:	lda A1L,x
	sta PCL,x
	dex
	bpl A1PC1
OLDPC:  rts
ASCII1: sta CURSOR
ASCII2: ldy YSAV
	lda (INBUF),y
	inc YSAV
	ldy #$00
	cmp #$A2
	bne ASCII3
	lda CURSOR
	bpl BITON
	rts
ASCII3: cmp #$A7
	bne CRCHK
	lda CURSOR
	bmi BITOFF
	rts
CRCHK:  cmp #$8D	; Carriage Return Check
	beq ASCDONE
	and CURSOR
	jsr STOR1
	bne ASCII2
ASCDONE:rts
SEARCH: lda (A1L),y
	cmp A4L
	bne SRCH1
	jsr PRINTA1
	jsr CROUT
SRCH1:  jsr NXTA1
	bcc SEARCH
	rts
ASCII:  sec
	.byte   $90
ASCII0: clc
CKMDE:  tax
	stx STATE
	eor #$BA
	bne MON_ERROR
BITON:  lda #$FF
	bcs ASCII1
BITOFF: lda #$7F
	bpl ASCII1
REPEAT: bit $C000
	bpl REPEAT1
	jmp KEYIN
REPEAT1:pla
LFA36:  pla
	jmp SCAN
CRMON:  jsr BL1
	jmp MONZ
MOVE:   jsr TSTA1
	bcs MON_ERROR
MOVNXT: lda (A1L),y
	sta (A4L),y
	jsr NXTA4
	bcc MOVNXT
	rts
VRFY:   jsr TSTA1
	bcs MON_ERROR
VRFY1:  lda (A1L),y
	cmp (A4L),y
	beq VRFY2
	jsr MISMATCH
	jsr CROUT
VRFY2:  jsr NXTA4
	bcc VRFY1
	rts
MISMATCH:
	lda A4H
	jsr PRBYTE
	lda A4L
	jsr PRBYCOL
	lda (A4L),y
	jsr PRBYTSP
PRINTA1:jsr PRSPC
	lda A1H
	jsr PRBYTE
	lda A1L
	jsr PRBYCOL
PRA1BYTE:
	lda (A1L),y
PRBYTSP:jsr PRBYTE
PRSPC:  lda #$A0
	jmp COUT
USER:   jmp L03F8
JUMP:   pla
	pla
GO: jsr A1PC
	jmp (PCL)
RWERROR:jsr PRBYTE
	lda #$A1
	jsr COUT
ERROR2: jsr NOSTOP
MON_ERROR:
	jmp MON
DEST:   lda A2L
	sta A4L
	lda A2H
	sta A4H
	rts
SEP:    jsr SPCE
	tya
	beq SETMDZ
BL1:    dec YSAV
	beq DUMP8
SPCE:   dex
	bne SETMDZ
	cmp #$BA
	bne TSTDUMP
STOR:   sta STATE
	lda A2L
STOR1:  sta (A3L),y
	inc A3L
	bne DUMMY
	inc A3H
DUMMY:  rts
SETMODE:ldy YSAV
	dey
	lda (INBUF),y
SETMDZ: sta STATE
	rts
READ:   lda #$01
	.byte   $2C
WRTE:	rts
DUMP8:  lda A1H
	sta A2H
	jsr TST80WID
	ora A1L
	sta A2L
	bne DUMP0
TSTDUMP:lsr a
ERROR1: bcs MON_ERROR
DUMP:   jsr TST80WID
DUMP0:  lda A1L
	sta A4L
	lda A1H
	sta A4H
	jsr TSTA1
	bcs ERROR1
DUMP1:  jsr PRINTA1
DUMP2:  jsr NXTA1
	bcs DUMPASC
	lda A1L
	and CURSOR
	bne DUMP3
	jsr DUMPASC
	bne DUMP1
DUMP3:  jsr PRA1BYTE
	bne DUMP2
DUMPASC:lda A4L
	sta A1L
	lda A4H
	sta A1H
	jsr PRSPC
ASC1:   ldy #$00
	lda (A1L),y
	ora #$80
	cmp #$A0
	bcs ASC2
	lda #$AE
ASC2:   jsr COUT
	jsr NXTA4
	bcs ASC3
	lda A1L
	and CURSOR
	bne ASC1
ASC3:   jmp CROUT
COL80:  sec
	lda $C053
	bcs SET80
COL40:  clc
	lda $C052
SET80:  lda MODES
	ora #$40
	bcs SET80A
	and #$BF
SET80A: sta MODES
	ora #$7F
	and #$A0
	sta FORGND
	bcs SET80B
	lda #$F0
SET80B: sta BKGND
HOME:
CLSCRN: lda LMARGIN
	sta CH
	lda WINTOP
	sta CV
CLREOP:
CLEOP:  lda CH
	pha
	lda CV
	pha
	jsr SETCV
CLEOP1: jsr CLEOL
	lda LMARGIN
	sta CH
	jsr CURDOWN
	bcc CLEOP1
	pla
	tay
	pla
	sta CH
	tya
	bcs SETCV
CLREOL:
CLEOL:  lda CH
	jmp CLEOL1
CONTROL:cmp #$80
	bcc DISPLAYX
TSTCR:  cmp #$8D
	bne TSTBACK
CARRAGE:
	jsr CLEOL
	jsr SETCHZ
	jmp NXTLIN
CURUP:  lda CV
	dec CV
	cmp WINTOP
	bne CURUP1
	lda WINBTM
CURUP1: sec
	sbc #$01
TABV:
SETCV:  sta CV
BASCALC:lda CV
	bpl BASCALC1
CURIGHT:inc CH
	lda CH
	cmp RMARGIN
SETCHZ: lda LMARGIN
	bcc CTRLRET
SETCVH: sta CH
CURDOWN:inc CV
	lda CV
	cmp WINBTM
	bcc BASCALC
	lda WINTOP
	bcs SETCV
TSTBACK:cmp #$88
	bne TSTBELL
CURLEFT:dec CH
	bmi LEFTUP
	lda CH
	cmp LMARGIN
	bpl CTRLRET
LEFTUP: jsr CURUP
	lda RMARGIN
	sta CH
	bne CURLEFT
COUT2:  cmp #$A0
	bcc CONTROL
	bit MODES
	bmi DISPLAYX
	and #$7F
DISPLAYX:
	jsr DISPLAY
INCHORZ:jsr CURIGHT
NXTLIN: bcs SCROLL
	rts
BASCALC1:
	php
	pha
	lsr a
	and #$03
	ora #$04
	sta BAS4H
	eor #$0C
	sta BAS8H
	pla
	and #$18
	bcc BSCLC2
	adc #$7F
BSCLC2: sta BAS4L
	asl a
	asl a
	ora BAS4L
	sta BAS4L
	sta BAS8L
	plp
CTRLRET:rts
COUT:   pha
	sty TEMPY
	stx TEMPX
	jsr COUT1
	ldy TEMPY
	ldx TEMPX
	pla
	rts
COUT1:  jmp (CSWL)
TSTBELL:cmp #$87
	bne LNFD
BELL:   ldx $C040
	rts
LNFD:   cmp #$8A
	bne CTRLRET
	jsr CURDOWN
	bcc CTRLRET
SCROLL: lda WINTOP
	pha
	jsr SETCV
SCRL1:  ldx #$03
SCRL2:  lda BAS4L,x
	sta TBAS4L,x
	dex
	bpl SCRL2
	pla
	clc
	adc #$01
	cmp WINBTM
	bcs LASTLN
	pha
	jsr SETCV
	lda RMARGIN
	lsr a
	tay
SCRL3:  dey
	bmi SCRL1
	lda (BAS4L),y
	sta (TBAS4L),y
	lda (BAS8L),y
	sta (TBAS8L),y
	bcc SCRL3
LASTLN: lda LMARGIN
CLEOL1:
	tay
	lda FORGND
	sta (BAS4L),y
	iny
	tya
	cmp RMARGIN
	bcc CLEOL1
	rts
DISPLAY:
	pha
	lda CH
	tay
	pla
	sta (BAS4L),y
	rts
NOTCR:	lda (INBUF),y
	jsr COUT
	cmp #$88
	beq BKSPCE
	cmp #$98
	beq CANCEL
	inc RDTEMP
	lda RDTEMP
	cmp #$28
	bne NXTCHAR
CANCEL: lda #$DC
	jsr COUT
	jsr CROUT
GETLN:  lda PROMPT	; Get a line of input (with prompt)
	jsr COUT
GETLN2:	ldy #$01	; Get a line of input (without prompt)
	sty RDTEMP
BKSPCE: ldy RDTEMP
	beq GETLN2
	dec RDTEMP
NXTCHAR:jsr RDCHAR
	ldy RDTEMP
	sta (INBUF),y
	cmp #$8D	; Carriage Return Check
	bne NOTCR
CROUT:  bit $C000
	bpl NOSTOP
	jsr KEYIN3
	cmp #$A0
	beq STOPLST
	cmp #$89
	bne NOSTOP
	jmp ERROR2
STOPLST:lda $C000
	bpl STOPLST
NOSTOP: lda #$8D	; Carriage Return Check
	jmp COUT
RDKEY:  jmp (KSWL)
KEYIN:  lda #$7F
	sta TBAS4H
	jsr PICK
KEYIN1: pha
	jsr KEYWAIT
	bcs KEYIN2
	lda CURSOR
	jsr DISPLAY
	jsr KEYWAIT
KEYIN2: pla
	php
	pha
	jsr DISPLAY
	pla
	plp
	bcc KEYIN1
KEYIN3: lda $C000
	sta KBDATA
	lda $C008
	and #$0a	; Mask off all but the shift and alpha lock buttons
	cmp #$08	; Is shift off and alpha lock off?
	bne @Shift
	lda KBDATA	; Yes - then move to lowercase
	cmp #$C1
	bmi @Shift
	cmp #$DB
	bpl @Shift
	clc
	adc #$20
	sta KBDATA
@Shift:	lda KBDATA
KEYIN4: bit $C010
	rts
KEYWAIT:inc TBAS4L
	bne KWAIT2
	inc TBAS4H
	lda #$7F
	clc
	and TBAS4H
	beq KEYRET
KWAIT2: asl $C000
	bcc KEYWAIT
KEYRET: rts
ESC3:   jsr GOESC
ESCAPE: lda MODES
	and #$80
	eor #$AB
	sta CURSOR
ESC1:   jsr RDKEY
	ldy #$08
ESC2:   cmp ESCTABL,y
	beq ESC3
	dey
	bpl ESC2
RDCHAR:	lda #$20
	sta CURSOR
	jsr RDKEY
	cmp #$9B
	beq ESCAPE
	cmp #$95
	bne KEYRET
	jsr PICK
	ora #$80
	rts
GOESC:  lda #$FB
	pha
	lda ESCVECT,y
	pha
	rts
ESCVECT:.byte   $A1,$84,$7C,$62,$5C,$EC,$CA,$DC
	.byte   $B7
PICK:   lda CH
	tay
	lda (BAS4L),y
	rts
ESCTABL:.byte   $CC,$D0,$D3,$B4,$B8,$88,$95,$8A
	.byte   $8B,$00
HOOKS:  .addr   COUT2
	.addr   KEYIN
VBOUNDS:.byte   $00,$28,$00,$18
