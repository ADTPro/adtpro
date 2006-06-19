*---------------------------------------------------------
* GETFN - Get filename
*---------------------------------------------------------
GETFN
    	lda #$00
	sta <CH
	lda #$15
	jsr TABV
	ldy #PMSG13
	jsr SHOWMSG
	ldx #0		GET ANSWER AT $200
	jsr NXTCHAR
	lda #0		NULL-TERMINATE IT
	sta $200,X
	txa
	rts

*---------------------------------------------------------
* PAUSE - print 'PRESS A KEY TO CONTINUE...' and wait
*---------------------------------------------------------
PAUSE
	lda #$00
	sta <CH
	lda #$17
	jsr TABV
	jsr CLREOP
	ldy #PMSG16
	jsr SHOWMSG
	jsr RDKEY
	rts
