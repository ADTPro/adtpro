*---------------------------------------------------------
* UPDCRC - Update CRC with contents of accumulator
*---------------------------------------------------------
UPDCRC
	pha
	eor <CRC+1
	tax
	lda <CRC
	eor CRCTBLH,X
	sta <CRC+1
	lda CRCTBLL,X
	sta <CRC
	pla
	rts


*---------------------------------------------------------
* MAKETBL - MAKE CRC-16 TABLES
*---------------------------------------------------------
MAKETBL	ldx #0
	ldy #0
CRCBYTE stx <CRC	LOW BYTE = 0
	sty <CRC+1	HIGH BYTE = INdex

	ldx #8		FOR EACH BIT
CRCBIT  lda <CRC
CRCBIT1 asl		SHIFT CRC LEFT
	rol <CRC+1
	bcs CRCFLIP
	dex		HIGH BIT WAS CLEAR, DO NOTHING
	bne CRCBIT1
	beq CRCSAVE
CRCFLIP eor #$21	HIGH BIT WAS SET, FLIP BITS
	sta <CRC	0, 5, AND 12
	lda <CRC+1
	eor #$10
	sta <CRC+1
	dex
	bne CRCBIT

	lda <CRC	STORE CRC IN TABLES
CRCSAVE sta CRCTBLL,Y
	lda <CRC+1
	sta CRCTBLH,Y
	iny
	bne CRCBYTE	DO NEXT BYTE
	rts
