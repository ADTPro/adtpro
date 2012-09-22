;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2011 by David Schmidt
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
; Horizontal tabs for buffer display
;---------------------------------------------------------
H_BUF	= $05
H_BLK	= $0f
H_NUM1	= $15

;---------------------------------------------------------
; Veritcal tab for buffer display
;---------------------------------------------------------
V_MSG	= $0b
V_BUF	= $0f

;---------------------------------------------------------
; ProDOS/SOS call number equates
;---------------------------------------------------------
OS_REQUEST_SEG		= $40
OS_FIND_SEG		= $41
OS_CHANGE_SEG		= $42
OS_GET_SEG_INFO		= $43
OS_GET_SEG_NUM		= $44
OS_RELEASE_SEG		= $45

OS_QUIT			= $65

OS_READBLOCK		= $80
OS_WRITEBLOCK		= $81
OS_GET_TIME		= $82
OS_D_STATUS		= $82
OS_D_CONTROL		= $83
OS_GET_DEV_NUM		= $84
OS_D_INFO		= $85

OS_CREATE		= $C0
OS_DESTROY		= $C1
OS_RENAME		= $C2
OS_SET_FILE_INFO	= $C3
OS_GET_FILE_INFO	= $C4
OS_ONL			= $C5	; ONLINE call for ProDOS; VOLUME call for SOS
OS_SET_PREFIX		= $C6
OS_GET_PREFIX		= $C7
OS_OPEN			= $C8
OS_NEWLINE		= $C9
OS_READFILE		= $CA
OS_WRITEFILE		= $CB
OS_CLOSE		= $CC
OS_FLUSH		= $CD
OS_SET_MARK		= $CE
OS_GET_MARK		= $CF
OS_SET_EOF		= $D0
OS_GET_EOF		= $D1
OS_SET_LEVEL		= $D2
OS_GET_LEVEL		= $D3

;---------------------------------------------------------
; ProDOS/SOS error numbers
;---------------------------------------------------------
BADSCNUM		= $01
BADCZPAGE		= $02
BADXBYTE		= $03
BADSCPCNT		= $04
BADSCBNDS		= $05

DNFERR			= $10
BADDNUM			= $11
BADREQCODE		= $20
BADCTLCODE		= $21
BADCTLPARM		= $22
NOTOPEN			= $23
NORESRC			= $24
BADOP			= $25
IOERROR			= $27
NOWRITE			= $2B
DISKSW			= $2E

BADPATH			= $40
CFCBFULL		= $41
FCBFULL			= $42
BADREFNUM		= $43
PATHNOTFND		= $44
VNFERR			= $45
FNFERR			= $46
DUPERR			= $47
OVRERR			= $48
DIRFULL			= $49
CPTERR			= $4A
TYPERR			= $4B
EOFERR			= $4C
POSNERR			= $4D
ACCSERR			= $4E
BTSERR			= $4F
FILBUSY			= $50
DIRERR			= $51
NOTNATIVE		= $52	; NOTSOS/NOTPRODOS
BADLSTCNT		= $53
BUFTBLFULL		= $55
BADSYSBUF		= $56
DUPVOL			= $57
NOTBLKDEV		= $58
LVLERR			= $59
BITMAPADR		= $5A

BADBPKG			= $E0
SEGRQDN			= $E1
SEGTBLFULL		= $E2
BADSEGNUM		= $E3
SEGNOTFND		= $E4
BADSRCHMODE		= $E5
BADCHGMODE		= $E6
BADPGCNT		= $E7

;---------------------------------------------------------
; Language card soft switches
;---------------------------------------------------------
LC2RD		= $C080
LC2WR		= $C081	; Read twice to enable write
ROMONLY2	= $C082
LC2RW		= $C083	; Read twice to enable write
LC1WR		= $C089
LC1RW		= $C08B	; Read twice to enable write
;---------------------------------------------------------
; Disk II soft switches
;---------------------------------------------------------
DRVSM0OFF	= $C080 ; Phase 0 off  Stepper motor
DRVSM1OFF	= $C082 ; Phase 1 off
DRVSM2OFF	= $C084 ; Phase 2 off
DRVSM3OFF	= $C086 ; Phase 3 off
DRVSM0ON	= $C081 ; Phase 0 on   Stepper motor
DRVSM1ON	= $C083 ; Phase 1 on
DRVSM2ON	= $C085 ; Phase 2 on
DRVSM3ON	= $C087 ; Phase 3 on
DRVON		= $C089 ; drive on
DRVSEL		= $C08A ; drive selection
DRVRD		= $C08C ; Strobe input
DRVRDM		= $C08E ; switch on READ mode

;---------------------------------------------------------
; Equates from imported formatting code
;---------------------------------------------------------
Step0    = $C080		; Drive stepper motor positions
Step1    = $C081		;   |      |      |       |
Step2    = $C082		;   |      |      |       |
Step4    = $C084		;   |      |      |       |
Step6    = $C086		;   |      |      |       |
DiskOFF  = $C088		; Drive OFF  softswitch
DiskON   = $C089		; Drive ON   softswitch
Select   = $C08A		; Starting offset for target device
DiskRD   = $C08C		; Disk READ  softswitch
DiskWR   = $C08D		; Disk WRITE softswitch
ModeRD   = $C08E		; Mode READ  softswitch
ModeWR   = $C08F		; Mode WRITE softswitch

;---------------------------------------------------------
; Characters
;---------------------------------------------------------
CHR_BLK	= $20
CHR_SP	= _' '
CHR_DOT = _'.'
CHR_A	= _'A'
CHR_B	= _'B'
CHR_C	= _'C'
CHR_D	= _'D'
CHR_E	= _'E'
CHR_F	= _'F'
CHR_G	= _'G'
CHR_H	= _'H'
CHR_I	= _'I'
CHR_J	= _'J'
CHR_K	= _'K'
CHR_L	= _'L'
CHR_M	= _'M'
CHR_N	= _'N'
CHR_O	= _'O'	; The letter O
CHR_P	= _'P'
CHR_Q	= _'Q'
CHR_R	= _'R'
CHR_S	= _'S'
CHR_T	= _'T'
CHR_U	= _'U'
CHR_V	= _'V'
CHR_W	= _'W'
CHR_X	= _'X'
CHR_Y	= _'Y'
CHR_Z	= _'Z'
CHR_0	= _'0'	; Zero
CHR_1	= _'1'
CHR_2	= _'2'
CHR_3	= _'3'
CHR_4	= _'4'
CHR_5	= _'5'
CHR_6	= _'6'
CHR_7	= _'7'
CHR_8	= _'8'
CHR_9	= _'9'
CHR_ESC	= $9b
CHR_ENQ = $05
CHR_ACK	= $06
CHR_NAK	= $15
CHR_CAN = $18

;---------------------------------------------------------
; Nibble/halftrack stuff
;---------------------------------------------------------
NIBPAGES	= $34		; Number of nibble pages to send
