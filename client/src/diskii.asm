;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2007 - 2011 by David Schmidt
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

	.segment "STARTUP"

;---------------------------------------------------------
; The routines here come largely from the FASTDSK program:
; http://boutillon.free.fr/Underground/Docs/Fastdsk/Fastdsk_en.html
;---------------------------------------------------------
NBUF2	= $AA
ZBUFFER	= $44 ; and $45 : 256 bytes buffer addr
RD_ERR	= $42 ; read data field err code
CHECKSUM	= $3A ; sector checksum

;************************************
;*                                  *
;* TRANS - Transfer track in memory *
;* to target device                 *
;*                                  *
;* Note - this needs to keep within *
;* a single page of memory.         *
;************************************
Trans:
	lda #$00		; Set Buffer to $6700
	ldx #$67
	sta Buffer
	stx Buffer+1
Trans2:
; Trans2 entry point preconditions:
;   Buffer set to the start of nibble page to write (with leading sync bytes)
	ldy #$32		; Set Y offset to 1st sync byte (max=50)
	ldx SlotF		; Set X offset to FORMAT slot/drive
	sec			; (assume the disk is write protected)
	lda DiskWR,x		; Write something to the disk
	lda ModeRD,x		; Reset Mode softswitch to READ
	bmi LWRprot		; If > $7F then disk was write protected
	lda #$FF		; Write a sync byte to the disk
	sta ModeWR,x
	cmp DiskRD,x
	nop			; (kill some time for WRITE sync...)
	jmp LSync2
LSync1:
	eor #$80		; Set MSB, converting $7F to $FF (sync byte)
	nop			; (kill time...)
	nop
	jmp MStore
LSync2:
	pha			; (kill more time... [ sheesh! ])
	pla
LSync3:
	lda (Buffer),y		; Fetch byte to WRITE to disk
	cmp #$80		;  Is it a sync byte? ($7F)
	bcc LSync1		;  Yep. Turn it into an $FF
	nop
MStore:
	sta DiskWR,x		; Write byte to the disk
	cmp DiskRD,x		; Set Read softswitch
	iny			; Increment Y offset
	bne LSync2
	inc Buffer+1		; Increment Buffer by one page
; We may have to let everybody use the $6600 buffer space after all.
; That lets us avoid the extra boundary checking, and just use the 'bpl' 
; method of waiting for the pointer to go above $7f to page $80.
	bpl LSync3		; If < $8000 get more FORMAT data
	lda ModeRD,x		; Restore Mode softswitch to READ
	lda DiskRD,x		; Restore Read softswitch to READ
	clc
	rts
LWRprot:
	pla
	pla			; Pop a return address off the stack
	lda #$2B	; Disk is write protected
	sec
	rts

;---------------------------------------------------------
; Two tables used in the arm movements. They must
; lie in one page.
;---------------------------------------------------------
delaytb1:
	.byte $01,$30,$28,$24,$20,$1e 
	.byte $1d,$1c,$1c,$1c,$1c,$1c

delaytb2:
	.byte $70,$2c,$26,$22,$1f,$1e
	.byte $1d,$1c,$1c,$1c,$1c,$1c


;---------------------------------------------------------
; calibrat - Calibrate the disk arm to track #0
; The code is essentially like in the Disk ][ card
;---------------------------------------------------------
calibrat:
	ldx pdsoftx		; Get soft switch offset
	lda	$c08e,x		; prepare latch for input
	lda	$c08c,x		; strobe data latch for i/o
	lda	pdrive		; is 0 for drive 1
	beq	caldriv1
	inx
caldriv1:
	lda	$c08a,x		; engage drive 1 or 2
	ldx pdsoftx
	lda	$c089,x		; motor on
	ldy	#$50		; number of half-tracks
caldriv3:
	lda	$c080,x		; stepper motor phase n off
	tya
	and	#$03		; make phase from count in y
	asl			; times 2
	ora	pdsoftx		; make index for i/o address
	tax
	lda	$c081,x		; stepper motor phase n on
	lda	#$56		; param for wait loop
	jsr	DELAY		; wait specified time units
	dey			; decrement count
	bpl	caldriv3	; jump back while y >= 0
	rts

;---------------------------------------------------------
; rdnibtr - read track as nibbles into tracks buffer.
; total bytes read is NIBPAGES * 256, or about twice
; the track length.
; the drive has been calibrated, so we know we are in read
; mode, the motor is running, and and the correct drive 
; number is engaged.
; we wait until we encounter a first nibble after a gap.
; for this purpose, a gap is at least 4 ff nibbles in a 
; row. note this is not 100% fool proof; the ff nibble
; can occur as a regular nibble instead of autosync.
; but this is conform beneath apple dos, so is
; probably ok.
;---------------------------------------------------------
;readtrk:
;rdnibtr:
;	ldx pdsoftx		; Load drive index into X
;	lda #0			; a = 0
;	tay			; y = 0 (index)
;	sta BLKPTR		; set running ptr (lo) to 0
;	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
;	sta BLKPTR+1		; set running ptr (hi)
;	lda #NIBPAGES
;	sta NIBPCNT		; page counter
; use jmp, not jsr, to perform nibsync. that way we
; have a bit more breathing room, cycle-wise. the
; "function" returns with a jmp to rdnibtr8.
;	jmp	nibsync		; find first post-gap byte
; the read loop must be fast enough to read 1 byte every
; 32 cycles. it appears the interval is 17 cycles within
; one data page, and 29 cycles when crossing a data page.
; these numbers are based on code that does not cross
; a page boundary.
;rdnibtr7:
;	lda $c08c,x		; read (4 cycles)
;	bpl rdnibtr7		; until byte complete (2c)
;rdnibtr8:
;	sta (BLKPTR),y		; store in buffer (6c)
;	iny			; (2c)
;	bne rdnibtr7		; 256 bytes done? (2 / 3c)
;	inc BLKPTR+1		; next page (5c)
;	dec NIBPCNT		; count (5c)
;	bne rdnibtr7		; and back (3c)
;	rts

;---------------------------------------------------------
; Read a full track, marking long and short self-sync nibbles
;
; By: Stephen Thomas
; See: http://groups.google.com/group/comp.sys.apple2/browse_frm/thread/39e58a5f3b931906/bc1732d9d6b53e0a
;      http://groups.google.com/group/comp.emulators.apple2/browse_frm/thread/76c414b1ee96eda1/#
; Hacked to self-modify disk read hardware address
;---------------------------------------------------------
rdnibtr:
;readtrk:
	lda #0			; a = 0
	tay			; y = 0 (index)
	sta BLKPTR		; set running ptr (lo) to 0
	LDA_BIGBUF_ADDR_HI	; BIGBUF address high
	sta BLKPTR+1		; set running ptr (hi)
	lda pdsoftx		; Get soft switch offset
	clc
	adc #$8c		; Build the LSB of Disk HW address
	sta dpll+1		; Self-modify in the places used
	sta rt04+1
	sta rt08+1
	sta rt15+1
	ldx #$7F

dpll:	lda DRVRD	; check for data at rt=0
rt01:	bpl rt04	; if none, check again at rt=7
rt03:	bmi rt08	; if found, cut 2cy from loop

data40:	and #$7F	; (was: and #$FE) b0=0 marks 40cy selfsync
data36:	and #$7F	; b7=0 marks selfsync
data32:	sta (BLKPTR),y
	iny
	bne dpll
	inc BLKPTR+1
	bmi rtdone

rt04:	lda DRVRD	; check for data at rt=7
rt08:	cpx DRVRD	; still valid at rt=11?
rt15:	bit DRVRD	; still valid at rt=15?
	bcs data32	; gone by rt=11 -> 32cy data
	bpl data36	; gone by rt=15 -> 36cy selfsync
	bmi data40	; else it's a 40cy selfsync

rtdone:
	rts 

;---------------------------------------------------------
; seekabs - copy of standard dos seekabs at $B9A0.
; By copying it we are independent on the dos version, 
; while still avoiding rwts in the nibble copy function.
; On entry, x is slot * 16; A is desired half-track;
; $478 is current half-track
;---------------------------------------------------------
seekabs:
	stx	$2b
	sta	$2a
	cmp	$0478
	beq	seekabs9
	lda	#$00
	sta	$26
seekabs1:
	lda	$0478
	sta	$27
	sec
	sbc	$2a
	beq	seekabs6
	bcs	seekabs2
	eor	#$ff
	inc	$0478
	bcc	seekabs3
seekabs2:
	adc	#$fe
	dec	$0478
seekabs3:
	cmp	$26
	bcc	seekabs4
	lda	$26
seekabs4:
	cmp	#$0c
	bcs	seekabs5
	tay   
seekabs5:
	sec   
	jsr	seekabs7
	lda	delaytb1,y
	jsr	armdelay
	lda	$27
	clc
	jsr	seekabs8
	lda	delaytb2,y
	jsr	armdelay
	inc	$26
	bne	seekabs1
seekabs6:
	jsr	armdelay
	clc
seekabs7:
	lda	$0478
seekabs8:
	and	#$03
	rol
	ora	$2b
	tax
	lda	$c080,x
	ldx	$2b
seekabs9:
	rts

;---------------------------------------------------------
; armdelay - Copy of standard dos armdelay at $BA00
;---------------------------------------------------------
armdelay:
	ldx	#$11
armdela1:
	dex
	bne	armdela1
	inc	$46
	bne	armdela3
	inc	$47
armdela3:
	sec
	sbc	#$01
	bne	armdelay
	rts

;---------------------------------------------------------
; slot2x - Sets configured slot * 16 in x and in a
;---------------------------------------------------------
slot2x:	ldx	pdslot
	inx			; now 1..7
	txa
	asl
	asl
	asl
	asl			; a now contains slot * 16
	tax			; store in x
	rts

;==============================*
;                              *
; INIT DISK II DRIVE FOR READ  *
;                              *
;==============================*

INIT_DISKII:
	ldx pdsoftx		; x = slot * 16

	txa			; Store some self-modifying bytes
	clc			; Since I'm not sure how timing-sensitive
	adc #$8C		;   they really are.
	sta DRVRD_MOD1+1
	sta DRVRD_MOD2+1
	sta DRVRD_MOD3+1
	sta DRVRD_MOD4+1
	sta DRVRD_MOD5+1
	sta DRVRD_MOD6+1
	sta DRVRD_MOD7+1
	sta DRVRD_MOD8+1
	sta DRVRD_MOD9+1
	sta DRVRD_MOD10+1
	sta DRVRD_MOD11+1
	sta DRVRD_MOD12+1
	sta DRVRD_MOD13+1
	sta DRVRD_MOD14+1

	lda pdrive		; select drive (1 or 2)
	beq :+
	inx
:	LDA DRVSEL,x
	ldx pdsoftx
	LDA DRVON,x		; drive on
	LDA DRVRDM,x		; set mode to:
	LDA DRVRD,x		; read

	LDA DRVSM0OFF,x		; set all stepper motor phases to off
	LDA DRVSM1OFF,x
	LDA DRVSM2OFF,x
	LDA DRVSM3OFF,x

	LDY #4			; wait for 300 rpm
:	LDA #0
	JSR WAIT_SPEED
	DEY
	BNE :-
	RTS

WAIT_SPEED:
	SEC
SPEED_1:
	PHA
SPEED_2:
	SBC #1
	BNE SPEED_2
	PLA
	SBC #1
	BNE SPEED_1
	RTS


;---------------------------------------------------------
; motoroff - Turn disk drive motor off
; Preserves y.  Doesn't hurt if motor is already off.
;---------------------------------------------------------
motoroff:
	ldx	pdsoftx		; x = slot * 16
	beq	:+		; Skip it if it's zero...
	lda	$c088,x		; turn motor off
:	rts

;==============================*
;                              *
;  PUT READ HEAD ON TRACK $00  *
;                              *
;==============================*

GO_TRACK0:
	LDA #0			; init MOVE_ARM values
	STA CURHTRK
	STA GOHTRK

	JSR READ_ADDR_FD	; read current T/S under R/W head
	BCC TRACK0_1		; no err -> known track

				; unable to read current track which is unknown
	LDA #80			; Force 80 "tracks" recalibration
	STA RS_TRACK		; (=40 dos 3.3 tracks)

TRACK0_1:
	LDA RS_TRACK		; already on track 0?
	BEQ TRACK0_3		; yes

				; go to track 0
	LDA RS_TRACK		; from current track
TRACK0_2:
	ASL			; translate to half track
	STA CURHTRK
	LDA #0			; to track 0
	JSR MOVE_ARM		; move r/w head on the target track
	JSR READ_ADDR_FD	; check if good track
	BCS TRACK0_3		; can't read but can't do more.

	LDA RS_TRACK		; track 0?
	BNE TRACK0_2		; no, retry

TRACK0_3:
	RTS


;==============================*
;                              *
; READ THE FIRST ADDRESS FIELD *
; UNDER THE R/W HEAD AND GET   *
; TRACK AND SECTOR NUMBERS     *
;                              *
;==============================*

; Out: Carry      = 0 -> no err and:
;      RS_VOLUME  Volume found
;      RS_TRACK   Track found (DOS 3.3)
;      RS_PHYSEC  Physical sector found
;      RS_LOGSEC  Logicial sector found
;
;      Carry      = 1 -> err
;      Acc        = err num
;      ERRNUM     = err num
;	          1 = no addr header marker
;	          2 = bad sector

READ_ADDR_FD:
	LDX #0			; init low/high max counter (10*256 nibbles)
	LDY #10
	JMP ADDR_FD_1		; start research

ADDR_FD_2:
	INX			; read nibble isn't a marker. Add 1 to counter
	BNE ADDR_FD_1		; and search again
	DEY
	BNE ADDR_FD_1
				; counter=max. Stop and set error
	LDA #1			; error : no addr field headers
	STA ERRNUM
	SEC
	RTS

ADDR_FD_1:
DRVRD_MOD1:
	LDA DRVRD		; read nibble
	BPL ADDR_FD_1
				; Check D5 (1st addr field marker D5 AA 96)
	CMP PARM_ADDR_H1
	BNE ADDR_FD_2		; bad nibble -> next

ADDR_FD_3:
DRVRD_MOD2:
	LDA DRVRD		; read nibble
	BPL ADDR_FD_3
				; Check AA (2nd addr field marker D5 AA 96)
	CMP PARM_ADDR_H2
	BNE ADDR_FD_2		; bad nibble -> next

ADDR_FD_4:
DRVRD_MOD3:
	LDA DRVRD		; read nibble
	BPL ADDR_FD_4
				; Check 96 (3rd addr field marker D5 AA 96)
	CMP PARM_ADDR_H3
	BNE ADDR_FD_2		; bad nibble -> next

; Ok header markers found. Now read addr informations.
; Read 6 nibbles and get 3 bytes (volume/track/sector)

	LDY #0			; Y[0,2] * 2 = 6 nibbles (counter)
ADDR_FD_5:
DRVRD_MOD4:
	LDA DRVRD		; read 1st nibble
	BPL ADDR_FD_5

	STA RS_TEMP		; save first nibble (format: 1A1B1C1D)

ADDR_FD_6:
DRVRD_MOD5:
	LDA DRVRD		; read 2nd nibble
	BPL ADDR_FD_6
				; acc=1E1F1G1H
	SEC			; 4-4 decoding
	ROL RS_TEMP		; mask AND: RS_TEMP=A1B1C1D1
	AND RS_TEMP		; result acc=ABCDEFGH
	STA RS_INFOS,Y		; save byte
	INY			; read next 2 nibbles
	CPY #3
	BNE ADDR_FD_5

	LDX RS_PHYSEC		; check sector
	BMI ADDR_FD_7		; >127 -> bad
	CPX #16
	BPL ADDR_FD_7		; >15 -> bad

	LDA TSECT,X		; skewing to get and
	STA RS_LOGSEC		; save logical sector number
	CLC			; no err
	RTS

ADDR_FD_7:
	LDA #2			; error : bad sector
	STA ERRNUM
	SEC
	RTS


RS_TEMP:
	.BYTE 0			; building byte (work aera)
RS_INFOS:			; Sector informations (read)
RS_VOLUME:
	.BYTE 0			; volume number
RS_TRACK:
	.BYTE 0			; track number
RS_PHYSEC:
	.BYTE 0			; physical sector number
RS_LOGSEC:
	.BYTE 0			; sector number
				; skewing
TSECT:	.byte $0, $8, $1, $9, $2, $a, $3, $b, $4, $c, $5, $d, $6, $e, $7, $f
;             0l  0h  1l  1h  2l  2h  3l  3h  4l  4h  5l  5h  6l  6h  7l  7h

;==============================*
;                              *
; MOVE ARM TO A "WANTED" TRACK *
;                              *
;==============================*

; In : CURHTRK  "from" current half track [0,68]
;      Acc     "to"   dos 3.3 track [0,34]
;
; Assume slot * 16 is in pdsoftx
;
; E.g 1: from T$22 (half=$44) to T$20 (half=$40)  >> DESC <<
;        GOHTRK :$40
;        CURHTRK:$44    CURHTRK > GOHTRK ==> do -1
;                    low 2 bits * 2 + softswitch -> phase on/off
;        CURHTRK:$44-1=$43 -> 3*2 +$C0E1 = $C0E7 -> phase 3 on
;        SAVHTRK:$44       -> 0*2 +$C0E0 = $C0E0 -> phase 0 off
;        CURHTRK:$43-1=$42 -> 2*2 +$C0E1 = $C0E5 -> phase 2 on
;        SAVHTRK:$43       -> 3*2 +$C0E0 = $C0E6 -> phase 3 off
;        CURHTRK:$42-1=$41 -> 1*2 +$C0E1 = $C0E3 -> phase 1 on
;        SAVHTRK:$42       -> 2*2 +$C0E0 = $C0E4 -> phase 2 off
;        CURHTRK:$41-1=$40 -> 0*2 +$C0E1 = $C0E1 -> phase 0 on
;        SAVHTRK:$41       -> 1*2 +$C0E0 = $C0E2 -> phase 1 off
;        CURHTRK:$40 = GOHTRK ==> END
;
; E.g 2: from T$10 (half=$20) to T$11 (half=$22)  >> ASC <<
;        GOHTRK :$22
;        CURHTRK:$20    CURHTRK < GOHTRK ==> do +1
;                    low 2 bits * 2 + softswitch -> phase on/off
;        CURHTRK:$20+1=$21 -> 1*2 +$C0E1 = $C0E3 -> phase 1 on
;        SAVHTRK:$20       -> 0*2 +$C0E0 = $C0E0 -> phase 0 off
;        CURHTRK:$21+1=$22 -> 2*2 +$C0E1 = $C0E5 -> phase 2 on
;        SAVHTRK:$21       -> 1*2 +$C0E0 = $C0E2 -> phase 1 off
;        CURHTRK:$22 = GOHTRK ==> END

MOVE_ARM:
	ASL		; *2 (dos 3.3 track -> half track)
	STA GOHTRK	; wanted half track

ARM_1:	LDA CURHTRK	; start from current half track
	STA SAVHTRK	; save current half track

	SEC		; current half track - wanted half track
	SBC GOHTRK
	BEQ ARM_OK	; we're on it -> end

	BCS ARM_2	; CURHTRK > GOHTRK

			; track ASC, phase ASC
	INC CURHTRK	; position to next half track
	BCC ARM_3
			; track DESC, phase DESC
ARM_2:	DEC CURHTRK	; position to previous half track

ARM_3:	JSR SEEK1	; first phase (=current half track +/- 1)
	JSR WAIT_ARM	; delay
	LDA SAVHTRK	; saved track : 2nd phase (=current track)
	AND #%00000011	; reduce half track to phase 0 or 1 or 2 or 3
	ASL		; *2: now 0 or 2 or 4 or 6. Ready for softswitch
	clc
	adc pdsoftx
	TAX
	LDA DRVSM0OFF,X	; phase off
			; $C0x0 or $C0x2 or $C0x4 or $C0x6
	JSR WAIT_ARM	; delay
	BEQ ARM_1	; always

SEEK1:	LDA CURHTRK	; use next/previous half track
	AND #%00000011	; reduce half track to phase 0 or 1 or 2 or 3
	ASL		; *2: now 0 or 2 or 4 or 6
	clc
	adc pdsoftx
	TAX		; use it as index
	LDA DRVSM0ON,X	; for phase on: 1 or 3 or 5 or 7
			; $C0x1 or $C0x3 or $C0x5 or $C0x7
ARM_OK:	RTS

WAIT_ARM:
	LDA #$28	; delay (stepper motor)
	SEC
ARM_1_2:
	PHA
ARM_2_2:
	SBC #1		; first loop
	BNE ARM_2_2

	PLA
	SBC #1		; second loop
	BNE ARM_1_2

	RTS		; acc=0

CURHTRK:
	.BYTE 0		; from current half track
SAVHTRK:
	.BYTE 0		;  saved current half track
GOHTRK:	.BYTE 0		; to "wanted" half track


;==============================*
;                              *
;         LOAD 5 TRACKS        *
;                              *
;==============================*

; In : acc = first track

LOAD_TRACKS:
	sta TRK		; first track
	ldx #$00
	stx RELTRK
	clc
	adc #$05
	sta TRACKS_3+1	; last track+1
	lda TRK		; Fetch that first track again

; Move arm

	CMP #0		; track 0?
	BEQ READY_L5TRK	; arm already on it

TRACKS_5:
	lda $C000
	cmp #CHR_ESC	; ESCAPE = ABORT
	beq TRKABORT
	LDA GOHTRK	; from current half track
	STA CURHTRK
	LDA TRK		; to dos 3.3 track
	JSR MOVE_ARM	; move r/w head on the target track

; Calculate HI address where loaded sectors are stored

READY_L5TRK:

        jsr UpdateTrackNumber

	ldx RELTRK	; Track counter, 0-4
	LDY #$0F	; init sector #

TRACKS_1:
	TYA		; sector # in Y reg
	CLC
	ADC ADR_TRK,X	; add first HI addr
	STA SKT_BUF,Y	; load to this HI addr
	STA SKT_BUF2,Y	; idem
	DEY
	BPL TRACKS_1

	LDA RWCHR	; print R on track read status
	jsr CHROVER

	LDA RWCHROK	; default=no err
	STA ERR_READ_TRK

	JSR LOAD_TRACK	; load 1 track

	LDA ERR_READ_TRK
	ORA #%10000000
	CMP RWCHROK
	BEQ TRACKS_4

	PHA		; save track status
	INC ERR_READ	; a read error occurs
	JSR FILLZ	; fill bad sectors with 0
	PLA		; restore track status

TRACKS_4:
	inc RELTRK
	LDX TRK		; print final track read status
	INX		; next track
	STX TRK
TRACKS_3:
	CPX #$FF	; last track?
	BNE TRACKS_5
	RTS

TRKABORT:
	jsr motoroff
	jmp BABORT

TRK:	.BYTE 0		; current track
RELTRK:	.byte 0		; Current track count
SKT_BUF:
	.RES  16	; HI addr of the 16 sectors (working)
SKT_BUF2:
	.RES  16	; idem (don't change)
ADR_TRK:
	.BYTE >BIGBUF,>BIGBUF+$10,>BIGBUF+$20,>BIGBUF+$30,>BIGBUF+$40
ERR_READ:		; read error flag
	.BYTE 0

UpdateTrackNumber:
	clc
	lda BLKLO	; Increment the 16-bit block number
	adc #$08
	sta NUM
	sta BLKLO
	lda BLKHI
	adc #$00
	tax
	stx BLKHI
ShowTrackNumber:
	lda CH
	sta <COL_SAV
	lda #V_MSG	; start printing at first number spot
	jsr TABV
	lda #H_NUM1
	sta CH

	lda NUM
	ldx BLKHI
	ldy #CHR_0
	jsr PRD		; Print block number in decimal

	lda COL_SAV	; Reposition cursor to previous
	sta CH		; buffer row
	lda #V_BUF
	jsr TABV
	rts

;==============================*
;                              *
;        LOAD A TRACK          *
;                              *
;==============================*

; Out: ERR_READ_TRK   "." = no err
;                     "*" = err
;      SKT_RCOUNT DS 16    "." sector ok
;                          '*' bad sector

LOAD_TRACK:
	LDY #15			; init counter for each sector
	LDA #'0'
@1:	STA SKT_RCOUNT,Y
	DEY
	BPL @1

	LDA #16
	STA CNT_BAD		; init bad sector number counter (read addr field)
	STA CNT_OK		; init correct sector count (read data field)

	LDA #32			; 16 sectors * 2
	STA CNT_RAF		; init read counter of already done sectors
				; before stop track process

@15:	DEC CNT_RAF
	BNE @3

	JMP @14			; remaining sectors are bad (can't find addr field)

@3:	JSR READ_ADDR_FD	; read current T/S under R/W head
	BCC @19			; no err

	JMP @2			; err

@19:	LDX RS_LOGSEC		; logical sector
	LDY SKT_BUF,X		; HI addr
	BEQ @15			; already read, try another one

	LDA #32			; 16 sectors * 2
	STA CNT_RAF		; init read counter of already done sectors
				; before stop track process

	JSR READ_SEC_DATA	; read sector
	BCS @5			; error

	LDX RS_LOGSEC
	LDA SKT_RCOUNT,X	; first read?
	CMP #'0'
	BEQ @21			; yes
				; keep current read number
	.byte $2C		; false BIT
@21:	LDA #'.'		; ok

@13:	LDA #0			; set sector=ok read
	STA SKT_BUF,X
	LDA RWCHR		; sector status
	STA SKT_RCOUNT,X
	LDY TRK
	LDA RWCHR

@9:	DEC CNT_OK		; -1 sector to do
	BNE @3			; not finished

	lda #CHR_BLK
	ldx #$08
:	jsr COUT1
	dex
	bne :-

	RTS			; keep default ERR_READ_TRK

; Error while reading data field

@5:
	TAY			; save err num

	LDX RS_LOGSEC
	INC SKT_RCOUNT,X	; +1 time
	LDA SKT_RCOUNT,X
	CMP #'@'
	BNE @7

	CPY #5			; checksum?
	BNE @11			; no

@11:	LDA #'*'
	STA SKT_RCOUNT,X
	STA ERR_READ_TRK

@7:	LDY TRK
	LDA SKT_RCOUNT,X	; Write sector status on screen
	CMP #'*'
	BEQ @20

	JMP @3

@20:	LDA #0			; set sector=ok read
	STA SKT_BUF,X
	BEQ @9

; Error while reading addr field

@2:	CMP #1			; no markers
	BEQ @4

				; bad sector number
	DEC CNT_BAD
	BEQ @4			; full track is bad

	JMP @3			; not yet 16 errors

; Bad Track

@4:	LDX TRK

	lda #$01
	sta ECOUNT
	lda #CHR_X
	ldx #$08
:	jsr COUT1
	dex
	bne :-

	LDY #15			; init counter for each sector
	LDA #'*'		; sector status=error
@10:	STA SKT_RCOUNT,Y
	DEY
	BPL @10

	LDA #'*'		; bad track
	STA ERR_READ_TRK
	RTS

; Remaining sectors are bad (can't find their addr field)

@14:	LDX #15
	LDA #'*'		; sector status=error

@17:	LDY SKT_BUF,X		; sector ok
	BEQ @16

	STA SKT_RCOUNT,X	; bad sector
	LDY TRK

@16:	DEX
	BPL @17

	LDA #'*'		; bad track
	STA ERR_READ_TRK

	lda #$01
	sta ECOUNT
	lda #CHR_X
	ldx #$08
:	jsr COUT1
	dex
	bne :-

	RTS


ERR_READ_TRK:		; read error flag for an entire track
	.BYTE 0

SKT_RCOUNT:
	.RES 16		; sector $00 to $0F
CNT_BAD:
	.BYTE 0		; [0=end,16]
CNT_OK:	.BYTE 0		; [0=end,16]
CNT_RAF:
	.BYTE 0		; counter: nbr of read for address field before err


;==============================*
;                              *
; SAVE/RESTORE PAGE0 FOR NBUF2 *
;                              *
;==============================*

; Save

SAV_NBUF2:
	LDX #$AA
:	LDA NBUF2-$AA,X
	STA SAV_P0_NBUF2-$AA,X
	INX
	BNE :-
	RTS

; Restore

RST_NBUF2:
	LDX #$AA
:	LDA SAV_P0_NBUF2-$AA,X
	STA NBUF2-$AA,X
	INX
	BNE :-
	RTS

SAV_P0_NBUF2:
	.RES 86      ; save page 0 (before denibblizing)


;==============================*
;                              *
; FILL BAD SECTORS WITH ZEROS  *
;                              *
;==============================*

FILLZ:
	LDA $EC			; save used addr page 0
	STA FILLZ_SV
	LDA $ED
	STA FILLZ_SV+1

FILLZ2:
	LDX #$0F		; begin with sector $0F
FILLZ_2:
	LDA SKT_RCOUNT,X	; sector status
	CMP #'*'		; err?
	BNE FILLZ_1		; no, skip this sector

	                 ; prepare pointer for write
	LDA SKT_BUF2,X ; HI
	STA $ED
	LDA #0         ; LO
	STA $EC
	                 ; acc=0
	TAY              ; Y=0
FILLZ_3:
	STA ($EC),Y    ; fill with 0
	INY
	BNE FILLZ_3

FILLZ_1:
	DEX              ; previous sector
	BPL FILLZ_2         ; not finished

	RTS

FILLZ_SV:
	.BYTE 0,0        ; page 0 backup


;*******************************
;                              *
; READ DATA FIELD OF A SECTOR  *
; AND POSTNIBBLIZE ON THE FLY  *
;                              *
;*******************************

; In : Y          = high buffer 256 bytes
;
; Out: carry     = 0 -> ok, datas loaded
;
;      carry     = 1 -> err
;      acc       = err code
;          04 : no D5 AA AD headers after reading $20 nibbles
;          05 : bad checksum
;          06 : next nibble after checksum isn't trailer DE
;
; NOTES BEFORE CALLING THIS SUB-ROUTINE:
;  - CHECK ADDR FIELD HEADERS
;  - FILL DATA FIELD HEADERS + FIRST TRAILER (MARKER_* ENT)
;    WITH PROPER USER PARMS
;  - UPDATE MA_STA CODE PART CORRECTLY (MAIN/AUX MEMORY)
;
;*******************************
;
; Content of a data field:
; =======================
;
; D5 AA AD data field header markers
;                                  Nibble index
; 86/$56 nibbles (6&2 complement)  $0000-$0055 (000-085)
; 86/$56 nibbles (bottom third)    $0056-$00AB (086-171)
; 86/$56 nibbles (middle third)    $00AC-$0101 (172-257)
; 84/$54 nibbles (top third)       $0102-$0155 (258-341)
; xx checksum
; DE AA EB data field trailer markers
;
; The 256 bytes buffer in memory where datas are loaded
; (ZBUFFER) is cut in 3 parts:
;
;   ZBUFFER                    Written   Y    e.g. buffer
;   offset                     with           = $1000
; +-------------------------+--------+-----+-------------------+
; ! $00                     !        ! $AA ! first Y=$AB       !
; ! ... bottom third buffer ! STORE1 ! ... ! STA $0F55,Y       !
; ! $55                     !        ! $FF ! last: PLA+STA,$55 !
; +-------------------------+--------+-----+-------------------+
; ! $56                     !        ! $AA !                   !
; ! ... middle third buffer ! STORE2 ! ... ! STA $0FAC,Y       !
; ! $AB                     !        ! $FF !                   !
; +-------------------------+--------+-----+-------------------+
; ! $AC                     !        ! $AC !                   !
; ! ... top third buffer    ! STORE3 ! ... ! STA $1000,Y       !
; ! $FF                     !        ! $FF !                   !
; +-------------------------+--------+-----+-------------------+
;
; There are 4 loops in the program:
; - 1 loop to read the 6&2 complement bits in the
;   auxiliary buffer NBUF2 (86 nibbles)
; - 1 loop to read 86 nibbles, build the final bytes with NBUF2
;   and store them in the bottom third buffer.
; - 1 loop to read 86 nibbles, build the final bytes with NBUF2
;   and store them in the middle third buffer.
; - 1 loop to read 84 nibbles, build the final bytes with NBUF2
;   and store them in the top third buffer.
;
; About the last 3 loops:
; Each loop uses the Y register to store each byte:
;   STORE1  STA bottom third buffer-$AB,Y [$AB,$FF]
;   STORE2  STA middle third buffer-$AA,Y [$AA,$FF]
;   STORE3  STA top third buffer-$AC,Y    [$AC,$FF]
; With the following equivalence:
;   Bottom third buffer = ZBUFFER
;   Middle third buffer = ZBUFFER+$56
;   Top third Buffer    = ZBUFFER+$AC
; The STA addresses are as follow:
;   STORE1 -> STA ZBUFFER-$AB,Y
;   STORE2 -> STA ZBUFFER+$56-$AA,Y = ZBUFFER-$54,Y
;   STORE3 -> STA ZBUFFER,Y
;
; A big part of this sub-routine comes from Apple ProDOS.
; I've done only small changes:
; - The 6&2 complementary buffer is located in page 0.
; - Added a more accurate returned error value if one occurs.
; - Write decoded datas in a selected aux memory bank.

;-------------------------------

;        DS    \	; start at the beginning of a new page

READ_SEC_DATA:
			; Get data buffer pointers
	STY STORE3+2	; +4c. Provides access to top 3rd of buffer
	DEY		; +2c.
	STY STORE2+2	; +4c. Provides access to middle 3rd of buffer
	STY STORE1+2	; +4c. Provides access to bottom 3rd of buffer

;-------------------------------
; Data field identification
;-------------------------------

	LDY #$20	; +2c. Initialize must find count at $20
			; search data headers
SEARCH_DH:
	DEY		; +2c. Decrement count - more to do?
	BEQ EXIT_ERR	; (+2c). No, then exit

RDNIBLOOP1:
DRVRD_MOD6:
	LDA DRVRD	; +4c. Read a nibble
	BPL RDNIBLOOP1

MARKER_DH1:
	EOR #$D5	; +2c. Is it 1st header mark?
	BNE SEARCH_DH	; (+2c). No, try again

	LDA #5		; +2c. Init err # (checksum err)
	STA RD_ERR	; +3c.

RDNIBLOOP2:
DRVRD_MOD7:
	LDA DRVRD	; +4c. Read a nibble
	BPL RDNIBLOOP2

MARKER_DH2:
	CMP #$AA	; +2c. Is it 2nd header mark?
	BNE MARKER_DH1	; (+2c). No, see if it is 1st header mark

	LDY STORE3+2	; +4c.
	STY ZBUFFER+1	; +3c. high
	LDA #0		; +2c.
	STA ZBUFFER	; +3c. low

RDNIBLOOP3:
DRVRD_MOD8:
	LDA DRVRD	; +4. Read a nibble
	BPL RDNIBLOOP3

MARKER_DH3:
	CMP #$AD	; +2c. Is it 3rd header mark?
	BNE MARKER_DH1	; (+2c). No, see if it is 1st header mark

;-------------------------------
; A running checksum is initialized
;-------------------------------

	LDY #$AA	; +2c. Y [$AA,$FF] = $56 nibbles to read
	LDA #0		; +2c. Init checksum
READ1:	STA CHECKSUM	; +3c.

;-------------------------------
; 86 disk words (6&2 complement nibbles) are read,
; decoded to XXXXXX00 format and stored in the
; auxiliary buffer
;-------------------------------

RDNIBLOOP4:
DRVRD_MOD9:
	LDX DRVRD	; +4c. Read a nibble [$96-$FF]
	BPL RDNIBLOOP4

	LDA NIB_2_6BB-$96,X	; +4c. Translate to 6-bits byte XXXXXX00
			; $96 is the first valid nibble value
			; Y [$AA,$FF]
	STA NBUF2-$AA,Y	; +5c. And store it.
	EOR CHECKSUM	; +3c. Compute running checksum
	INY		; +2c. Next nibble
	BNE READ1	; (+2c). Not finished

;-------------------------------
; The bottom third, middle third, and top third of the
; 256-byte buffer are read from disk and decoded to XXXXXX00
; format, then ORed with 000000XX data which is postnibblized
; on the fly from the auxiliary buffer XXXXXX00 data.
; The combined XXXXXXXX data which is stored to the 256-byte
; buffer is true 8-bit data, just as it resided in a 256-byte
; buffer before it was stored on disk.
;-------------------------------

; ATTN: reading loops -> less than 30 cycles because of the
;       disk speed variation + speed variation due to disk
;       flutter (read "Understanding the Apple IIe", Jim Sather,
;       Chapt 9, page 9-45).

; Read 86 nibbles (bottom third)

	LDY #$AA	; +2c. Y [$AA,$FF] = $56 nibble to read
	BNE RDNIBLOOP5	; +2c. Branch always taken

EXIT_ERR:
	LDA #4		; +2c. Init err #
	STA RD_ERR	; +3c.
	SEC		; set carry flag indicating error
	BCS LDA_RD_ERR	; return to caller

			; first loop Y=$AB. Last loop Y=$FF.
STORE1:	STA $FF55,Y	; +5c. Store byte in bottom third


RDNIBLOOP5:
DRVRD_MOD10:
	LDX DRVRD	; +4c. Read a nibble
	BPL RDNIBLOOP5

			; acc used as running checksum
	EOR NIB_2_6BB-$96,X	; +4c. Translate nibble to 6-bit byte+checksum
	LDX NBUF2-$AA,Y	; +4c. Bits from auxiliary buffer
	EOR BIT_PAIR_TBL,X	; +4c. Merge in
	INY		; +2c. Next nibble
	BNE STORE1	; (+2c). Not finished

	PHA		; +3c. Save last byte for later, no time now
	AND #$FC	; +2c. Trip off last two bits XXXXXX00

; Read 86 nibbles (middle third)

	LDY #$AA	; +2c. Y [$AA,$FF] = $56 nibbles to read

RDNIBLOOP6:
DRVRD_MOD11:
	LDX DRVRD	; +4c. Read a nibble
	BPL RDNIBLOOP6

	EOR NIB_2_6BB-$96,X	; +4c. Translate nibble to 6-bit byte+checksum
	LDX NBUF2-$AA,Y	; +4c. Bits from auxiliary buffer
	EOR BIT_PAIR_TBL+1,X	; +4c. Merge in
STORE2:
	STA $FFAC,Y	; +5c. Store byte in middle third
	INY		; +2c. Next nibble
	BNE RDNIBLOOP6	; (+2c). Not finished

; Read 84 nibbles (top third)
			; Y=0
RDNIBLOOP7:
DRVRD_MOD12:
	LDX DRVRD	; +4c. Read 1st nibble
	BPL RDNIBLOOP7

	AND #$FC	; +2c. Strip off last two bits XXXXXX00

	LDY #$AC	; +2c. Y [$AC,$FF] = $54 nibbles to read
DECODE:
	EOR NIB_2_6BB-$96,X	; +4c. Translate nibble to 6-bit byte+checksum
	LDX $FE,Y ;NBUF2-$AC,Y	; +4c. Bits from auxiliary buffer
	EOR BIT_PAIR_TBL+2,X	; +4c. Merge in
STORE3:
	STA $FF00,Y	; +5c. Store byte in top third

RDNIBLOOP8:
DRVRD_MOD13:
	LDX DRVRD	; +4c. Read nibble
	BPL RDNIBLOOP8

	INY		; +2c. Next nibble
	BNE DECODE	; (+2c). Not finished

; Last nibble read = checksum

	AND #$FC	; +2c. Strip off last two bits XXXXXX00
	EOR NIB_2_6BB-$96,X	; +4c. Translate nibble to 6-bit byte+checksum
	BNE ERROR	; (+2c). Checksum not valid

; Check 1st trailing mark

RDNIBLOOP9:
DRVRD_MOD14:
	LDA DRVRD	; +4c. Read nibble
	BPL RDNIBLOOP9

MARKER_DT1:
	CMP #$DE	; +2c. Check 1st trailing mark
	CLC		; +2c.
	BEQ OK		; (+2c). Yes, trailer ok

	INC RD_ERR	; +5c. 5+1=6 (trailer err)

ERROR:	SEC		; +2c. Set carry flag indicating error
OK:	PLA		; +4c. Set byte we stored away, we have time now
	LDY #$55	; +2c. Set proper offset
	STA (ZBUFFER),Y	; +6c. Store byte
LDA_RD_ERR:
	LDA RD_ERR	; +3c. acc=err code
	RTS		; +6c. Return to caller


;==============================*
;                              *
;    Denibblizing table #1     *
;    Nibble to 6-bits byte     *
;      translation table       *
;         (XXXXXX00)           *
;                              *
;===============================

; Translate a valid nibble to 6-bits byte XXXXXX00.
;
; 1 nibble: value from $96 to $FF (=$6A=106 disk bytes) but
;           only $40=64 disk bytes are valids. They have to
;           respect the rules:
;           - bit 7 (high bit) on
;           - at least 2 adjacent bits set excluding bit 7
;           - not a reserved byte ($AA, $D5)
;           - no more than 2 consecutive zero bits
; 6 bits are required to have $40 values.

;	DS    \          ; start at the beginning of a new page

NIB_2_6BB:

;               Index           <== disk byte
;              %XXXXXX00

	.BYTE %00000000  ; $00 <== $96
	.BYTE %00000100  ; $04 <== $97
	.BYTE 0          ;     <== $98 invalid
	.BYTE 0          ;     <== $99 invalid
	.BYTE %00001000  ; $08 <== $9A
	.BYTE %00001100  ; $0C <== $9B
	.BYTE 0          ;     <== $9C invalid
	.BYTE %00010000  ; $10 <== $9D
	.BYTE %00010100  ; $14 <== $9E
	.BYTE %00011000  ; $18 <== $9F
	.BYTE 0          ;     <== $A0 invalid
	.BYTE 0          ;     <== $A1 invalid
	.BYTE 0          ;     <== $A2 invalid
	.BYTE 0          ;     <== $A3 invalid
	.BYTE 0          ;     <== $A4 invalid
	.BYTE 0          ;     <== $A5 invalid
	.BYTE %00011100  ; $1C <== $A6
	.BYTE %00100000  ; $20 <== $A7
	.BYTE 0          ;     <== $A8 invalid
	.BYTE 0          ;     <== $A9 invalid
	.BYTE 0          ;     <== $AA invalid
	.BYTE %00100100  ; $24 <== $AB
	.BYTE %00101000  ; $28 <== $AC
	.BYTE %00101100  ; $2C <== $AD
	.BYTE %00110000  ; $30 <== $AE
	.BYTE %00110100  ; $34 <== $AF
	.BYTE 0          ;     <== $B0 invalid
	.BYTE 0          ;     <== $B1 invalid
	.BYTE %00111000  ; $38 <== $B2
	.BYTE %00111100  ; $3C <== $B3
	.BYTE %01000000  ; $40 <== $B4
	.BYTE %01000100  ; $44 <== $B5
	.BYTE %01001000  ; $48 <== $B6
	.BYTE %01001100  ; $4C <== $B7
	.BYTE 0          ;     <== $B8 invalid
	.BYTE %01010000  ; $50 <== $B9
	.BYTE %01010100  ; $54 <== $BA
	.BYTE %01011000  ; $58 <== $BB
	.BYTE %01011100  ; $5C <== $BC
	.BYTE %01100000  ; $60 <== $BD
	.BYTE %01100100  ; $64 <== $BE
	.BYTE %01101000  ; $68 <== $BF
	.BYTE 0          ;     <== $C0 invalid
	.BYTE 0          ;     <== $C1 invalid
	.BYTE 0          ;     <== $C2 invalid
	.BYTE 0          ;     <== $C3 invalid
	.BYTE 0          ;     <== $C4 invalid
	.BYTE 0          ;     <== $C5 invalid
	.BYTE 0          ;     <== $C6 invalid
	.BYTE 0          ;     <== $C7 invalid
	.BYTE 0          ;     <== $C8 invalid
	.BYTE 0          ;     <== $C9 invalid
	.BYTE 0          ;     <== $CA invalid
	.BYTE %01101100  ; $6C <== $CB
	.BYTE 0          ;     <== $CC invalid
	.BYTE %01110000  ; $70 <== $CD
	.BYTE %01110100  ; $74 <== $CE
	.BYTE %01111000  ; $78 <== $CF
	.BYTE 0          ;     <== $D0 invalid
	.BYTE 0          ;     <== $D1 invalid
	.BYTE 0          ;     <== $D2 invalid
	.BYTE %01111100  ; $7C <== $D3
	.BYTE 0          ;     <== $D4 invalid
	.BYTE 0          ;     <== $D5 invalid
	.BYTE %10000000  ; $80 <== $D6
	.BYTE %10000100  ; $84 <== $D7
	.BYTE 0          ;     <== $D8 invalid
	.BYTE %10001000  ; $88 <== $D9
	.BYTE %10001100  ; $8C <== $DA
	.BYTE %10010000  ; $90 <== $DB
	.BYTE %10010100  ; $94 <== $DC
	.BYTE %10011000  ; $98 <== $DD
	.BYTE %10011100  ; $9C <== $DE
	.BYTE %10100000  ; $A0 <== $DF
	.BYTE 0          ;     <== $E0 invalid
	.BYTE 0          ;     <== $E1 invalid
	.BYTE 0          ;     <== $E2 invalid
	.BYTE 0          ;     <== $E3 invalid
	.BYTE 0          ;     <== $E4 invalid
	.BYTE %10100100  ; $A4 <== $E5
	.BYTE %10101000  ; $A8 <== $E6
	.BYTE %10101100  ; $AC <== $E7
	.BYTE 0          ;     <== $E8 invalid
	.BYTE %10110000  ; $B0 <== $E9
	.BYTE %10110100  ; $B4 <== $EA
	.BYTE %10111000  ; $B8 <== $EB
	.BYTE %10111100  ; $BC <== $EC
	.BYTE %11000000  ; $C0 <== $ED
	.BYTE %11000100  ; $C4 <== $EE
	.BYTE %11001000  ; $C8 <== $EF
	.BYTE 0          ;     <== $F0 invalid
	.BYTE 0          ;     <== $F1 invalid
	.BYTE %11001100  ; $CC <== $F2
	.BYTE %11010000  ; $D0 <== $F3
	.BYTE %11010100  ; $D4 <== $F4
	.BYTE %11011000  ; $D8 <== $F5
	.BYTE %11011100  ; $DC <== $F6
	.BYTE %11100000  ; $E0 <== $F7
	.BYTE 0          ;     <== $F8 invalid
	.BYTE %11100100  ; $E4 <== $F9
	.BYTE %11101000  ; $E8 <== $FA
	.BYTE %11101100  ; $EC <== $FB
	.BYTE %11110000  ; $F0 <== $FC
	.BYTE %11110100  ; $F4 <== $FD
	.BYTE %11111000  ; $F8 <== $FE
	.BYTE %11111100  ; $FC <== $FF


;==============================*
;                              *
;    Denibblizing table #2     *
; Postnibblize bit mask table  *
;                              *
;==============================*

; This table is filled with 0/1/2/3 values (2 bits).
; Only the 3 first values of each line are used.
;
; Index value: $00 to $3F.
; Format: XXefcdab (XX=unused bits).
; Content of BIT.PAIR tables:
;  BIT.PAIR.LEFT   -> ba
;  BIT.PAIR.MIDDLE -> dc
;  BIT.PAIR.RIGHT  -> fe

;         DS    \          ; start at the beginning of a new page

BIT_PAIR_TBL:

;		LEFT     MIDDLE    RIGHT         VALUE
	.BYTE %00000000,%00000000,%00000000,0 ; XX000000
	.BYTE %00000010,%00000000,%00000000,0 ; XX000001
	.BYTE %00000001,%00000000,%00000000,0 ; XX000010
	.BYTE %00000011,%00000000,%00000000,0 ; XX000011

	.BYTE %00000000,%00000010,%00000000,0 ; XX000100
	.BYTE %00000010,%00000010,%00000000,0 ; XX000101
	.BYTE %00000001,%00000010,%00000000,0 ; XX000110
	.BYTE %00000011,%00000010,%00000000,0 ; XX000111

	.BYTE %00000000,%00000001,%00000000,0 ; XX001000
	.BYTE %00000010,%00000001,%00000000,0 ; XX001001
	.BYTE %00000001,%00000001,%00000000,0 ; XX001010
	.BYTE %00000011,%00000001,%00000000,0 ; XX001011

	.BYTE %00000000,%00000011,%00000000,0 ; XX001100
	.BYTE %00000010,%00000011,%00000000,0 ; XX001101
	.BYTE %00000001,%00000011,%00000000,0 ; XX001110
	.BYTE %00000011,%00000011,%00000000,0 ; XX001111

	.BYTE %00000000,%00000000,%00000010,0 ; XX010000
	.BYTE %00000010,%00000000,%00000010,0 ; XX010001
	.BYTE %00000001,%00000000,%00000010,0 ; XX010010
	.BYTE %00000011,%00000000,%00000010,0 ; XX010011

	.BYTE %00000000,%00000010,%00000010,0 ; XX010100
	.BYTE %00000010,%00000010,%00000010,0 ; XX010101
	.BYTE %00000001,%00000010,%00000010,0 ; XX010110
	.BYTE %00000011,%00000010,%00000010,0 ; XX010111

	.BYTE %00000000,%00000001,%00000010,0 ; XX011000
	.BYTE %00000010,%00000001,%00000010,0 ; XX011001
	.BYTE %00000001,%00000001,%00000010,0 ; XX011010
	.BYTE %00000011,%00000001,%00000010,0 ; XX011011

	.BYTE %00000000,%00000011,%00000010,0 ; XX011100
	.BYTE %00000010,%00000011,%00000010,0 ; XX011101
	.BYTE %00000001,%00000011,%00000010,0 ; XX011110
	.BYTE %00000011,%00000011,%00000010,0 ; XX011111

	.BYTE %00000000,%00000000,%00000001,0 ; XX100000
	.BYTE %00000010,%00000000,%00000001,0 ; XX100001
	.BYTE %00000001,%00000000,%00000001,0 ; XX100010
	.BYTE %00000011,%00000000,%00000001,0 ; XX100011

	.BYTE %00000000,%00000010,%00000001,0 ; XX100100
	.BYTE %00000010,%00000010,%00000001,0 ; XX100101
	.BYTE %00000001,%00000010,%00000001,0 ; XX100110
	.BYTE %00000011,%00000010,%00000001,0 ; XX100111

	.BYTE %00000000,%00000001,%00000001,0 ; XX101000
	.BYTE %00000010,%00000001,%00000001,0 ; XX101001
	.BYTE %00000001,%00000001,%00000001,0 ; XX101010
	.BYTE %00000011,%00000001,%00000001,0 ; XX101011

	.BYTE %00000000,%00000011,%00000001,0 ; XX101100
	.BYTE %00000010,%00000011,%00000001,0 ; XX101101
	.BYTE %00000001,%00000011,%00000001,0 ; XX101110
	.BYTE %00000011,%00000011,%00000001,0 ; XX101111

	.BYTE %00000000,%00000000,%00000011,0 ; XX110000
	.BYTE %00000010,%00000000,%00000011,0 ; XX110001
	.BYTE %00000001,%00000000,%00000011,0 ; XX110010
	.BYTE %00000011,%00000000,%00000011,0 ; XX110011

	.BYTE %00000000,%00000010,%00000011,0 ; XX110100
	.BYTE %00000010,%00000010,%00000011,0 ; XX110101
	.BYTE %00000001,%00000010,%00000011,0 ; XX110110
	.BYTE %00000011,%00000010,%00000011,0 ; XX110111

	.BYTE %00000000,%00000001,%00000011,0 ; XX111000
	.BYTE %00000010,%00000001,%00000011,0 ; XX111001
	.BYTE %00000001,%00000001,%00000011,0 ; XX111010
	.BYTE %00000011,%00000001,%00000011,0 ; XX111011

	.BYTE %00000000,%00000011,%00000011,0 ; XX111100
	.BYTE %00000010,%00000011,%00000011,0 ; XX111101
	.BYTE %00000001,%00000011,%00000011,0 ; XX111110
	.BYTE %00000011,%00000011,%00000011,0 ; XX111111

	ERRNUM:	.byte 0
PARM_ADDR_H1:	.byte $D5
PARM_ADDR_H2:	.byte $AA
PARM_ADDR_H3:	.byte $96
