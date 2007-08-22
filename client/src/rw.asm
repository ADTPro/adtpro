;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006, 2007 by David Schmidt
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

;---------------------------------------------------------
; READING/WRITING
;
; Read or write from zero to 40 ($28) blocks - inside
; a 64k Apple ][ buffer
;
; Input:
;   Y: Count of blocks
;   PARMBUF+1: unit number
;   BLKLO: starting block (lo)
;   BLKHI: starting block (hi)
;---------------------------------------------------------
READING:
	lda #PMSG07
	sta SR_WR_C
	lda #PD_READBLOCK
	sta RWDIR
	lda #CHR_R
	sta RWCHR
	lda #CHR_BLK
	sta RWCHROK
	jmp RW_COMN

WRITING:
	lda #PMSG08
	sta SR_WR_C
	lda #PD_WRITEBLOCK
	sta RWDIR
	lda #CHR_W
	sta RWCHR
	lda #CHR_SP
	sta RWCHROK

RW_COMN:
	sty BCOUNT
	lda #H_BUF	; Column - r/w/s/r
	sta <CH
	lda #V_MSG	; Message row
	jsr TABV
	ldy SR_WR_C
	jsr WRITEMSG

	lda #$00	; Reposition cursor to beginning of
	sta <CH		; buffer row
	lda #V_BUF
	jsr TABV

	lda NonDiskII	; Do we have a Disk II?
	beq :+		; No, branch to the block entry point
	lda RWCHR	; Are we writing?
	cmp #CHR_W
	beq :+		; Yes, branch to the block entry point
	jsr READTRAX	; Ok, we're reading a Disk II - so go fast.
	rts
:	jsr RWBLOX
	rts

;------------------------------------
; READTRAX
;
; Read five tracks starting from BIGBUF
;
; Input:
;   PARMBUF+1: unit number
;   BLKLO: starting block (lo)
;   BLKHI: starting block (hi)
;------------------------------------

READTRAX:
	jsr INIT_DISKII
	lda #$00
	sta ERR_READ
;	sta ERR_WRITE

	jsr SAV_NBUF2  ; save page 0 space used by denibblizing

; Load five tracks into memory
	lda BLKHI
	clc
	ror		; Shift low bit into carry (only care if it's a 1)
	lda BLKLO
	ror
	lsr
	lsr		; Divide by eight
	jsr LOAD_TRACKS
	jsr motoroff	; drive off
	jsr RST_NBUF2	; restore page 0 space used by NBUF2
	rts

;------------------------------------
; RWBLOX
;
; Read or write from zero to 40 ($28) blocks
; starting from BIGBUF
;
; Input:
;   PARMBUF+1: unit number
;   BLKLO: starting block (lo)
;   BLKHI: starting block (hi)
;------------------------------------

RWBLOX:
	stx SLOWX
	sty SLOWY
	lda #$03	; Set up MLI call - 3 parameters
	sta PARMBUF

	lda #<BIGBUF	; Point to the start of the big buffer
	sta PARMBUF+2
	lda #>BIGBUF
	sta PARMBUF+3

RWCALL:
	lda $C000
	cmp #CHR_ESC	; ESCAPE = ABORT

	beq RABORT
	lda RWCHR
	jsr CHROVER

	lda <CH
	sta <COL_SAV

	lda #V_MSG	; start printing at first number spot
	jsr TABV
	lda #H_NUM1
	sta <CH

	clc
	lda BLKLO	; Increment the 16-bit block number
	adc #$01
	sta NUM
	lda BLKHI
	adc #$00
	tax
	lda NUM
	ldy #CHR_0
	jsr PRD		; Print block number in decimal

	lda <COL_SAV	; Reposition cursor to previous
	sta <CH		; buffer row
	lda #V_BUF
	jsr TABV

	jsr MLI		; MLI call: READ/WRITE
RWDIR:	.byte PD_READBLOCK
	.addr PARMBUF
	bne RWBAD
	lda RWCHROK
	jsr COUT1
	jmp RWOK
RWBAD:
	lda #$01
	sta ECOUNT
	lda #CHR_X
	jsr COUT1
RWOK:	inc PARMBUF+3	; Advance buffer $100 bytes
	inc PARMBUF+3	; Advance buffer another $100 bytes
	inc BLKLO	; Advance block counter by one (word width)
	bne RWNOB
	inc BLKHI
RWNOB:	dec BCOUNT
	bne RWCALL
	ldy SLOWY
	ldx SLOWX
	rts

RABORT:	jmp BABORT

RWCHR:	.byte CHR_R	; Character to notify what we're doing
RWCHROK:	.byte CHR_BLK	; Character to write when things are OK
BCOUNT:	.byte $00
