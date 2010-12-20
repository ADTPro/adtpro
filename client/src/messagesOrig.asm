;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2010 by David Schmidt
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
; Host messages
;---------------------------------------------------------

HMSGTBL:
	.addr HMGBG,HMFIL,HMFMT,HMDIR,HMTIMEOUT

HMGBG:	asc "GARBAGE RECEIVED FROM HOST"
	.byte CHR_RETURN
HMGBG_END =*

HMFIL:	asc "UNABLE TO OPEN FILE"
	.byte CHR_RETURN
HMFIL_END =*

HMFMT:	asc "FILE FORMAT NOT RECOGNIZED"
	.byte CHR_RETURN
HMFMT_END =*

HMDIR:	asc "UNABLE TO CHANGE DIRECTORY"
	.byte CHR_RETURN
HMDIR_END =*

HMTIMEOUT:
	asc "HOST TIMEOUT"
	.byte CHR_RETURN
HMTIMEOUT_END =*

;---------------------------------------------------------
; Host message lengths
;---------------------------------------------------------
HMSGLENTBL:
	.byte HMGBG_END-HMGBG
	.byte HMFIL_END-HMFIL
	.byte HMFMT_END-HMFMT
	.byte HMDIR_END-HMDIR
	.byte HMTIMEOUT_END-HMTIMEOUT

;---------------------------------------------------------
; Host message equates
;---------------------------------------------------------

PHMGBG	= $00
PHMFIL	= $02
PHMFMT	= $04
PHMDIR	= $06
PHMTIMEOUT	= $08
PHMMAX	= $0a		; This must be two greater than the largest host message

;---------------------------------------------------------
; Console messages
;---------------------------------------------------------
	MSG01:	asc "%ADTPRO_VERSION%"
	MSG01_END =*

	MSG02:	asc "(S)END (R)ECEIVE (D)IR (B)ATCH (C)D"
		.byte CHR_RETURN,CHR_RETURN
	MSG02_END =*

	MSG03:	asc "(V)OLUMES CONFI(G) (F)ORMAT (?) (Q)UIT:"
	MSG03_END =*

	MSG04:	asc "(S)TANDARD OR (N)IBBLE?"
	MSG04_END =*

	MSG05:	asc "RECEIVING"
	MSG05_END =*

	MSG06:	asc "  SENDING"
	MSG06_END =*

	MSG07:	asc "  READING"
	MSG07_END =*

	MSG08:	asc "  WRITING"
	MSG08_END =*

	MSG09:	asc "BLOCK 00000 OF"
	MSG09_END =*

	;MSG10 - defined locally
	;MSG11 - defined locally
	;MSG12 - defined locally

	MSG13:	asc "FILENAME: "
	MSG13_END =*

	MSG14:	asc "COMPLETE"
	MSG14_END =*

	MSG15:	asc " - WITH ERRORS"
	MSG15_END =*

	MSG16:	asc "PRESS A KEY TO CONTINUE..."
	MSG16_END =*

	MSG17:	asc "ADTPRO BY DAVID SCHMIDT. BASED ON WORKS "
		asc "    BY PAUL GUERTIN AND MANY OTHERS.    "
		asc "  VISIT: HTTP://ADTPRO.SOURCEFORGE.NET "
	MSG17_END =*

	MSGSOU:	asc "   SELECT SOURCE VOLUME"
	MSGSOU_END =*

	MSGDST:	asc "SELECT DESTINATION VOLUME"
	MSGDST_END =*

	MSG19:	asc "VOLUMES CURRENTLY ON-LINE:"
	MSG19_END =*

	;MSG20 - defined locally
	;MSG21 - defined locally

	MSG22:	asc "CHANGE SELECTION WITH ARROW KEYS&RETURN "
	MSG22_END =*

	MSG23:	asc " (R) TO RE-SCAN DRIVES, ESC TO CANCEL"
	MSG23_END =*

	MSG23a:	asc "SELECT WITH RETURN, ESC CANCELS"
	MSG23a_END =*

	MSG24:	asc "CONFIGURE ADTPRO PARAMETERS"
	MSG24_END =*

	MSG25:	asc "CHANGE PARAMETERS WITH ARROW KEYS"
	MSG25_END =*

	;MSG26 - defined locally
	;MSG27 - defined locally

	MSG28: asc "ENABLE SOUND"
	MSG28_END =*

	MSG28a:	asc "SAVE CONFIG"
	MSG28a_END =*

	MSG29:	asc "ANY KEY TO CONTINUE, ESC TO STOP: "
	MSG29_END =*

	MSG30:	asc "END OF DIRECTORY.  HIT A KEY: "
	MSG30_END =*

	MNONAME:
		asc "<NO NAME>"
	MNONAME_END =*

	MIOERR:	asc "<I/O ERROR>"
	MIOERR_END =*

	MSG34:	asc "FILE EXISTS"
	MSG34_END =*

	MSG35:	asc "IMAGE/DRIVE SIZE MISMATCH!"
		.byte CHR_RETURN
	MSG35_END =*

	MLOGO1:	.byte NRM_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,CHR_RETURN
	MLOGO1_END =*

	MLOGO2:	.byte INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,CHR_RETURN
	MLOGO2_END =*

	MLOGO3:	.byte INV_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,CHR_RETURN
	MLOGO3_END =*

	MLOGO4:	.byte INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,CHR_RETURN
	MLOGO4_END =*

	MLOGO5:	.byte INV_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK,INV_BLOCK,INV_BLOCK,INV_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,NRM_BLOCK,INV_BLOCK,NRM_BLOCK
		asc	"PRO"
		.byte	CHR_RETURN
	MLOGO5_END =*

	MWAIT:	asc "WAITING FOR HOST REPLY, ESC CANCELS"
	MWAIT_END =*

	MCDIR:	asc "DIRECTORY: "
	MCDIR_END =*

	MFORC:	asc "COPY IMAGE DATA ANYWAY? (Y/N):"
	MFORC_END =*

	MFEX:	asc "FILE ALREADY EXISTS AT HOST."
	MFEX_END =*

	MUTHBAD:
		asc "UTHERNET INIT FAILED; PLEASE RUN CONFIG."
	MUTHBAD_END =*

	MPREFIX:
		asc "FILENAME PREFIX: "
	MPREFIX_END =*

	MINSERTDISK:
		asc "INSERT THE NEXT DISK TO SEND."
	MINSERTDISK_END =*

	MFORMAT:
		asc " CHOOSE VOLUME TO FORMAT"
	MFORMAT_END =*

	MANALYSIS:
		asc "HOST UNABLE TO ANALYZE TRACK."
	MANALYSIS_END =*

	MNOCREATE:
		asc "UNABLE TO CREATE CONFIG FILE."
	MNOCREATE_END =*

	; Messages from formatter routine
	MVolName:
		asc "VOLUME NAME: /"
	MBlank:	asc "BLANK          "	; Note - these two are really one continuous message.
	MVolName_END =*

	MTheOld:
		asc "READY TO FORMAT? (Y/N):"
	MTheOld_END =*

	MUnRecog:
		asc "UNRECOGNIZED ERROR = "
	MUnRecog_END =*

	MDead:	asc "CHECK DISK OR DRIVE DOOR!"
	MDead_END =*

	MProtect:
		asc "DISK IS WRITE PROTECTED!"
	MProtect_END =*

	MNoDisk:
		asc "NO DISK IN THE DRIVE!"
	MNoDisk_END =*
	
	MNuther:
		asc "FORMAT ANOTHER? (Y/N):"
	MNuther_END =*
	
	MUnitNone:
		asc "NO UNIT IN THAT SLOT AND DRIVE"
	MUnitNone_END =*

	MNIBTOP:
		asc "  00000000000000001111111111111111222  "
		.byte CHR_RETURN
		inv "  0123456789ABCDEF0123456789ABCDEF012  "
		.byte CHR_RETURN
	MNIBTOP_END =*

	MNULL:	.byte $00
	MNULL_END =*
	



;---------------------------------------------------------
; Message pointer table
;---------------------------------------------------------

MSGTBL:
	.addr MSG01,MSG02,MSG03,MSG04,MSG05,MSG06,MSG07,MSG08
	.addr MSG09,MSG10,MSG11,MSG12,MSG13,MSG14,MSG15,MSG16
	.addr MSG17,MSGSOU,MSGDST,MSG19,MSG20,MSG21,MSG22,MSG23,MSG23a,MSG24
	.addr MSG25,MSG26,MSG27,MSG28,MSG28a,MSG29,MSG30,MNONAME,MIOERR
	.addr MSG34,MSG35
	.addr MLOGO1,MLOGO2,MLOGO3,MLOGO4,MLOGO5,MWAIT,MCDIR,MFORC,MFEX
	.addr MUTHBAD, MPREFIX, MINSERTDISK, MFORMAT, MANALYSIS, MNOCREATE
	.addr MVolName, MTheOld, MUnRecog, MDead
	.addr MProtect, MNoDisk, MNuther, MUnitNone, MNIBTOP
	.addr MNULL

;---------------------------------------------------------
; Message length table
;---------------------------------------------------------

MSGLENTBL:
	.byte MSG01_END-MSG01
	.byte MSG02_END-MSG02
	.byte MSG03_END-MSG03
	.byte MSG04_END-MSG04
	.byte MSG05_END-MSG05
	.byte MSG06_END-MSG06
	.byte MSG07_END-MSG07
	.byte MSG08_END-MSG08
	.byte MSG09_END-MSG09
	.byte MSG10_END-MSG10
	.byte MSG11_END-MSG11
	.byte MSG12_END-MSG12
	.byte MSG13_END-MSG13
	.byte MSG14_END-MSG14
	.byte MSG15_END-MSG15
	.byte MSG16_END-MSG16
	.byte MSG17_END-MSG17
	.byte MSGSOU_END-MSGSOU
	.byte MSGDST_END-MSGDST
	.byte MSG19_END-MSG19
	.byte MSG20_END-MSG20
	.byte MSG21_END-MSG21
	.byte MSG22_END-MSG22
	.byte MSG23_END-MSG23
	.byte MSG23a_END-MSG23a
	.byte MSG24_END-MSG24
	.byte MSG25_END-MSG25
	.byte MSG26_END-MSG26
	.byte MSG27_END-MSG27
	.byte MSG28_END-MSG28
	.byte MSG28a_END-MSG28a
	.byte MSG29_END-MSG29
	.byte MSG30_END-MSG30
	.byte MNONAME_END-MNONAME
	.byte MIOERR_END-MIOERR
	.byte MSG34_END-MSG34
	.byte MSG35_END-MSG35
	.byte MLOGO1_END-MLOGO1
	.byte MLOGO2_END-MLOGO2
	.byte MLOGO3_END-MLOGO3
	.byte MLOGO4_END-MLOGO4
	.byte MLOGO5_END-MLOGO5
	.byte MWAIT_END-MWAIT
	.byte MCDIR_END-MCDIR
	.byte MFORC_END-MFORC
	.byte MFEX_END-MFEX
	.byte MUTHBAD_END-MUTHBAD
	.byte MPREFIX_END-MPREFIX
	.byte MINSERTDISK_END-MINSERTDISK
	.byte MFORMAT_END-MFORMAT
	.byte MANALYSIS_END-MANALYSIS
	.byte MNOCREATE_END-MNOCREATE
	.byte MVolName_END-MVolName
	.byte MTheOld_END-MTheOld
	.byte MUnRecog_END-MUnRecog
	.byte MDead_END-MDead
	.byte MProtect_END-MProtect
	.byte MNoDisk_END-MNoDisk
	.byte MNuther_END-MNuther
	.byte MUnitNone_END-MUnitNone
	.byte MNIBTOP_END-MNIBTOP
	.byte $00	; MNULL - null message has no length.

;---------------------------------------------------------
; Message equates
;---------------------------------------------------------

PMSG01		= $00
PMSG02		= $02
PMSG03		= $04
PMSG04		= $06
PMSG05		= $08
PMSG06		= $0a
PMSG07		= $0c
PMSG08		= $0e
PMSG09		= $10
PMSG10		= $12
PMSG11		= $14
PMSG12		= $16
PMSG13		= $18
PMSG14		= $1a
PMSG15		= $1c
PMSG16		= $1e
PMSG17		= $20
PMSGSOU		= $22
PMSGDST		= $24
PMSG19		= $26
PMSG20		= $28
PMSG21		= $2a
PMSG22		= $2c
PMSG23		= $2e
PMSG23a		= $30
PMSG24		= $32
PMSG25		= $34
PMSG26		= $36
PMSG27		= $38
PMSG28		= $3a
PMSG28a		= $3c
PMSG29		= $3e
PMSG30		= $40
PMNONAME	= $42
PMIOERR		= $44
PMSG34		= $46
PMSG35		= $48
PMLOGO1		= $4a
PMLOGO2		= $4c
PMLOGO3		= $4e
PMLOGO4		= $50
PMLOGO5		= $52
PMWAIT		= $54
PMCDIR		= $56
PMFORC		= $58
PMFEX		= $5a
PMUTHBAD	= $5c
PMPREFIX	= $5e
PMINSERTDISK	= $60
PMFORMAT	= $62
PMANALYSIS	= $64
PMNOCREATE	= $66
PMVolName	= $68
PMTheOld	= $6a
PMUnRecog	= $6c
PMDead		= $6e
PMProtect	= $70
PMNoDisk	= $72
PMNuther	= $74
PMUnitNone	= $76
PMNIBTOP	= $78
PMNULL		= $7a
