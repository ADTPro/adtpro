;.TITLE "Apple /// Virtual Serial Printer Driver by David Schmidt 2021"

;-----------------------------------------------------------------------
;
; SOS Virtual Serial Printer Driver
;
; Copyright (C) 2021 by David Schmidt
; Released to the public domain
;
;
; Revisions:
;
; 0.01 - Initial release
;
;-----------------------------------------------------------------------

DEVTYPE		= $41
SUBTYPE		= $04
DriverMfgr	= $4453	; Driver Manufacturer - David Schmidt (DS)
RELEASE		= $0010	; Version number

;-----------------------------------------------------------------------
;
; The macro SWITCH performs an N way branch based on a switch index. The
; maximum value of the switch index is 127 with bounds checking provided
; as an option. The macro uses the A and Y registers and alters the C,
; Z, and N flags of the status register, but the X register is unchanged.
;
; SWITCH [index], [bounds], adrs_table, [*]
;
; index This is the variable that is to be used as the switch index.
; If omitted, the value in the accumulator is used.
;
; bounds This is the maximum allowable value for index. If index
; exceeds this value, the carry bit will be set and execution
; will continue following the macro. If bounds is omitted,
; no bounds checking will be performed.
;
; adrs_table This is a table of addresses (low byte first) used by the
; switch. The first entry corresponds to index zero.
;
; * If an asterisk is supplied as the fourth parameter, the
; macro will push the switch address but will not exit to
; it; execution will continue following the macro. The
; program may then load registers or set the status before
; exiting to the switch address.
;
;-----------------------------------------------------------------------
;
.MACRO		SWITCH	index,bounds,adrs_table,noexec      ;See SOS Reference
.IFNBLANK	index										;If PARM1 is present,
	LDA		index										; load A with switch index
.ENDIF
.IFNBLANK	bounds										;If PARM2 is present,
	CMP		#bounds+1									; perform bounds checking
	BCS		@110										; on switch index
.ENDIF
	ASL		A											;Multiply by 2 for table index
	TAY
	LDA		adrs_table+1,Y								;Get switch address from table
	PHA													; and push onto Stack
	LDA		adrs_table,Y
	PHA
.IFBLANK	noexec
	RTS													; exit to code
.ENDIF
@110:
.ENDMACRO

.SEGMENT "TEXT"
;.PROC SERPRNT
.WORD $FFFF
.WORD COMMENT_END - COMMENT ; Length of comment field
COMMENT:
.BYTE "Apple /// Virtual Serial Printer Driver by David Schmidt 2021"
COMMENT_END:

.SEGMENT "DATA"

;----------------------------------------------------------------------
;
; Device Handler Identification Block
;
;----------------------------------------------------------------------

IDBLK:
.WORD $0000 ;Link to next device handler
.WORD SP_MAIN ;Entry point address
.BYTE $0a ;Length of device name
.BYTE ".VSPRINTER     "
.BYTE $80,$00,$00 ;Device, Slot & Unit numbers
.BYTE DEVTYPE
.BYTE SUBTYPE
.BYTE $00
.WORD $0000
.WORD DriverMfgr
.WORD RELEASE

;----------------------------------------------------------------------
;
; Device Handler Configuration Block
;
;----------------------------------------------------------------------

.WORD $05				;Configuration block length
DRATE:		.BYTE $0e	;Data Rate
DFORMAT:	.BYTE $00	;Data Format
CRDELAY:	.BYTE $00	;Carriage return delay
LFDELAY:	.BYTE $00	;Line feed delay
FFDELAY:	.BYTE $00	;Form feed delay

;----------------------------------------------------------------------
;
; SOS Global Data & Subroutines
;
;----------------------------------------------------------------------

ALLOCSIR	= $1913
DEALCSIR	= $1916
SYSERR		= $1928

;----------------------------------------------------------------------
;
; SOS Error Codes
;
;----------------------------------------------------------------------

XREQCODE	= $20 ;Invalid request code
XCTLCODE	= $21 ;Invalid control/status code
XNOTOPEN	= $23 ;Device not open
XNOTAVIL	= $24 ;Device not available
XNORESRC	= $25 ;Resource not available
XBADOP		= $26 ;Invalid operation for device


;----------------------------------------------------------------------
;
; Hardware I/O Addresses
;
;----------------------------------------------------------------------

ACIADATA	= $C0F0 ;ACIA data register
ACIASTAT	= $C0F1 ;ACIA status register
ACIACMD		= $C0F2 ;ACIA command register
ACIACTL		= $C0F3 ;ACIA control register
E_REG		= $FFDF ;Environment register
B_REG		= $FFEF ;Bank register


;----------------------------------------------------------------------
;
; Miscellaneous Equates
;
;----------------------------------------------------------------------

TRUE	= $80
FALSE	= $00
ASC_LF	= $0A
ASC_FF	= $0C
ASC_CR	= $0D
BITON4	= $10
BITON7	= $80

;-----------------------------------------------------------------------
;
; SOS Device Handler Interface
;
;-----------------------------------------------------------------------

SOSINT	= $C0
REQCODE	= SOSINT+0 ;SOS request code
BUFFER	= SOSINT+2 ;Buffer pointer
REQCNT	= SOSINT+4 ;Requested count
CTLSTAT	= SOSINT+2 ;Control/status code
CSLIST	= SOSINT+3 ;Control/status list pointer

;-----------------------------------------------------------------------
;
; Zero Page Storage
;
;-----------------------------------------------------------------------

ZPGSAVE	= SOSINT+$0A ;Saved zero page storage
ZPGTEMP	= ZPGSAVE+$00 ;Temporary zero page storage
MOVCNT	= ZPGTEMP+$00

;-----------------------------------------------------------------------
;
; Private Variable Storage
;
;-----------------------------------------------------------------------

SIRADDR:
.WORD SIRTABLE
SIRTABLE:
.BYTE $01,$00 ;ACIA resource
.WORD ACIAMIH
MIHBANK:
.BYTE $00
SIRCOUNT = *-SIRTABLE
OPENFLG: .BYTE FALSE ;Device open flag
XMIT: .BYTE FALSE ;XMIT in progress flag
DLYCNT: .BYTE $00 ;Delay count for MIH
BUFCNT: .BYTE $00 ;Local buffer byte count
BUFHEAD: .BYTE $00 ;Local buffer head index
BUFTAIL: .BYTE $00 ;Local buffer tail index
BUFSIZE = $6e ;110. ;Local buffer size
LOCBUF: ;Local buffer
.BYTE "Copyright (C) 2021 by David Schmidt."
CPYRGHTSIZ = *-LOCBUF
.RES BUFSIZE-CPYRGHTSIZ,0

;-----------------------------------------------------------------------
;
; Serial Printer Driver -- Main entry point
;
;-----------------------------------------------------------------------

SP_MAIN:
SWITCH REQCODE,8,SP_REQSW

BADREQ: LDA #XREQCODE	;Invalid request code
JSR SYSERR


NOTOPEN: LDA #XNOTOPEN	;Device not open
JSR SYSERR

SP_REQSW:				;Serial Printer request switch
.WORD SP_READ-1
.WORD SP_WRITE-1
.WORD SP_STAT-1
.WORD SP_CNTL-1
.WORD BADREQ-1
.WORD BADREQ-1
.WORD SP_OPEN-1
.WORD SP_CLOSE-1
.WORD SP_INIT-1

;----------------------------------------------------------------------
;
; Serial Printer Driver -- Initialization Request
;
;----------------------------------------------------------------------

SP_INIT:
LDA #FALSE
STA OPENFLG
LDA DRATE	;Validate data rate
AND #$0F
STA DRATE
TAX
LDA DFORMAT	;Validate data format
AND #$EE
ORA #$10
CPX #$03	;If data rate is 110 baud
BNE @010
ORA #$80	; force two stop bits
@010: STA DFORMAT
CLC
RTS

;----------------------------------------------------------------------
;
; Serial Printer Driver -- Open Request
;
;----------------------------------------------------------------------

SP_OPEN:
BIT OPENFLG		;Serial Printer open?
BPL @010		; No
LDA #XNOTAVIL
JSR SYSERR

@010:
LDA B_REG
AND #$0F
STA MIHBANK		;Set interrupt handler bank
LDA #SIRCOUNT
LDX SIRADDR
LDY SIRADDR+1
JSR ALLOCSIR	;Allocate the ACIA
BCS @020

LDA #FALSE
STA XMIT
JSR CNTL00		;Set up ACIA
LDA #TRUE
STA OPENFLG		;Set serial printer open
RTS

@020:
LDA #XNORESRC
JSR SYSERR

;----------------------------------------------------------------------
;
; Serial Printer Driver -- Close Request
;
;----------------------------------------------------------------------

SP_CLOSE:
ASL OPENFLG		;Serial Printer open?
BCS @010		; Yes
JMP NOTOPEN
@010:
BIT XMIT		;Wait for write completion
BMI @010
PHP
SEI
LDA E_REG
TAX
ORA #BITON7
STA E_REG		;Switch to 1 MHz
STA ACIASTAT	;Reset the ACIA
STX E_REG
PLP
LDA #SIRCOUNT
LDX SIRADDR
LDY SIRADDR+1
JSR DEALCSIR	;Deallocate the ACIA
RTS

;-----------------------------------------------------------------------
;
; Serial Printer Driver -- Read Request
;
;-----------------------------------------------------------------------

SP_READ:
BIT OPENFLG	;Serial Printer open?
BMI @010
JMP NOTOPEN
@010:
LDA #XBADOP
JSR SYSERR

;-----------------------------------------------------------------------
;
; Serial Printer Driver -- Write Request
;
;-----------------------------------------------------------------------

SP_WRITE:
BIT OPENFLG
BMI @010
JMP NOTOPEN
@010:
LDA #BUFSIZE/2		;Set MOVCNT to the lesser
LDY REQCNT+1		; of BUFSIZE/2 and REQCNT.
BNE @020
CMP REQCNT
BCC @020
LDA REQCNT
BNE @020
RTS					;Count = zero -- all done!
@020:
STA MOVCNT

LDA BUFFER+1		;Check for buffer
CMP #$FF			; address overflow
BCC @030
SBC #$80
STA BUFFER+1
INC $1401+BUFFER

@030: SEC
LDA #BUFSIZE
SBC MOVCNT
@040: CMP BUFCNT	;Wait for room in buffer
BCC @040

LDY #$00
LDX BUFTAIL
@050:
LDA (BUFFER),Y		;Move data to local buffer
STA LOCBUF,X
INX
CPX #BUFSIZE
BCC @060
LDX #$00
@060:
INY
CPY MOVCNT
BCC @050
STX BUFTAIL

PHP
SEI					;Shut down interrupts
CLC
LDA BUFCNT
ADC MOVCNT			;Bump buffer count
STA BUFCNT

BIT XMIT			;Already transmitting?
BVS @070			; Yes
LDA #$C0
STA XMIT			;Set transmitting flag
LDA E_REG
PHA
ORA #BITON7			;Switch to 1 MHz
STA E_REG
LDY ACIASTAT		;Fake an interrupt to start
JSR ACIAMIH			; the interrupt handler.
PLA
STA E_REG			;Switch back to 2 MHz
@070: PLP

CLC
LDA BUFFER
ADC MOVCNT			;Fix up buffer pointer
STA BUFFER
BCC @080
INC BUFFER+1

@080:
SEC
LDA REQCNT
SBC MOVCNT			;Fix up requested count
STA REQCNT
BCS @010
DEC REQCNT+1
JMP @010			;Loop back for more

;-----------------------------------------------------------------------
;
; ACIA Master Interrupt Handler
;
;-----------------------------------------------------------------------

ACIAMIH:
LDA E_REG
ORA #BITON7		;Set 1 MHz mode
STA E_REG

TYA				;Check DSR and DCD status
AND #$60		; bits for printer hand shake
BNE @080

TYA				;Check transmit register
AND #BITON4		; empty status bit
BEQ @060

LDA DLYCNT		;Any transmit delay in progress?
BEQ @010		; no
DEC DLYCNT
JMP @060

@010:
LDA BUFCNT		;Any data to transmit?
BEQ @070		; no -- wait for completion
LDX BUFHEAD
LDA LOCBUF,X
STA ACIADATA	;Transmit one character
INX
CPX #BUFSIZE
BCC @020
LDX #$00
@020:
STX BUFHEAD		;Update buffer index
DEC BUFCNT		; and count

CMP #ASC_CR		;Check for any delay
BEQ @040
BCS @060
CMP #ASC_LF
BNE @030
LDA LFDELAY
BCS @050
@030:
CMP #ASC_FF
BNE @060
LDA FFDELAY
BCS @050
@040:
LDA CRDELAY
@050:
STA DLYCNT
@060:
LDA ACIACMD
AND #$E0		;Enable transmit interrupt
ORA #$07
STA ACIACMD
RTS

@070:
ASL XMIT
BMI @060		;Still not done

@080:
LDA ACIACMD
AND #$E0		;Disable transmit interrupt
ORA #$0B
STA ACIACMD
RTS

;----------------------------------------------------------------------
;
; Serial Printer Driver -- Status Request
;
;----------------------------------------------------------------------

SP_STAT:
BIT OPENFLG		;Serial Printer open?
BMI @010
JMP NOTOPEN
@010:
SWITCH CTLSTAT,2,STATSW


BADCTL:
LDA #XCTLCODE	;Invalid control code
JSR SYSERR


STATSW:
.WORD STAT00-1
.WORD STAT01-1
.WORD STAT02-1


STAT00:
RTS				;0 -- NOP


STAT01:
LDY #0			;1 -- Status Table
LDA #0
STA (CSLIST),Y
RTS


STAT02:
LDY #0			;2 -- New Line
LDA #FALSE
STA (CSLIST),Y
RTS

;----------------------------------------------------------------------
;
; Serial Printer Driver -- Control Request
;
;----------------------------------------------------------------------

SP_CNTL:
BIT OPENFLG		;Serial Printer open?
BMI @010		; Ok
JMP NOTOPEN
@010:
SWITCH CTLSTAT,2,CNTLSW
JMP BADCTL

CNTLSW:
.WORD CNTL00-1
.WORD CNTL01-1
.WORD CNTL02-1

CNTL00:			;0 -- Reset
@010:
BIT XMIT		;Wait for write completion
BMI @010
LDA #$00
STA BUFHEAD
STA BUFTAIL
PHP
SEI
LDA E_REG
TAX
ORA #BITON7
STA E_REG		;Switch to 1 MHz
STA ACIASTAT	;Reset ACIA
LDA DFORMAT
AND #$F0
ORA DRATE
STA ACIACTL		;Set up ACIA control register
LDA DFORMAT
ASL A
ASL A
ASL A
ASL A
ORA #$0B
STA ACIACMD		;Set up ACIA command register
STX E_REG		;Switch back to 2 MHz
PLP
RTS

CNTL01:			;1 -- Serial Printer Status Table
RTS

CNTL02:			;2 -- New Line
RTS