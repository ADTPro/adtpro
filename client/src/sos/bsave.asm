;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2008 by David Schmidt
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

	.import ASMEND

;---------------------------------------------------------
; BSAVE - Save ADTPro parameters
;---------------------------------------------------------
; Out: carry = 0 -> no err
;      carry = 1 -> a MLI error occured (acc=err)
;
BSAVE:
	CALLOS OS_CREATE, FILE_CR
	CALLOS_CHECK_POS	; Branch + if no error
	cmp #$47		; File exists already?
	beq :+			; Don't care!
	ldy #PMNOCREATE
	jmp BSAVE_MSGEND 
:
	CALLOS OS_OPEN, FILE_OP	; open file
	CALLOS_CHECK_POS	; Branch + if no error
	ldy #PMNOCREATE
	jmp BSAVE_MSGEND 
:
	LDA FILE_OPN		; copy file number
	STA FILE_WRN
	STA FILE_CLN

WRITE:
	CALLOS OS_WRITEFILE, FILE_WR
	CALLOS_CHECK_POS	; Branch + if no error
	ldy #PMNOCREATE
	jmp BSAVE_MSGEND 
:	ldy #PMSG14		; All was OK

BSAVE_MSGEND:
	jsr BLOAD_END		; Close up the file
	jsr WRITEMSGAREA
	jsr PAUSE
	rts

;---------------------------------------------------------
; BLOAD - Load ADTPro parameters
;---------------------------------------------------------
; Out: carry = 0 -> no err
;      carry = 1 -> a MLI error occured (acc=err)
;
BLOAD:
	CALLOS OS_OPEN, FILE_OP
	CALLOS_CHECK_POS	; Branch + if no error
	jmp BLOAD_END
:	lda FILE_OPN		; copy file number
	sta FILE_RDN
	sta FILE_CLN

	CALLOS OS_READFILE, FILE_RD

BLOAD_END:
	CALLOS OS_CLOSE, FILE_CL
	rts

;-------------------------------
; Variables
;-------------------------------

FILE_P0: .byte 0,0		; page 0 : 2 byte backup


; Set Prefix

TBL_SET_PFX:
         .byte 1
         .addr CUR_PFX    ; addr of pathname

CUR_PFX:	.res 64

; Get Prefix

GET_PFX_PLIST:
	.byte 1
	.addr CUR_PFX

; Table for open

FILE_OP:	.byte 3
FILE_NAME:	.addr CONFIG_FILE_NAME	; addr len+name
;FILE_BUF_PTR:	.addr BIGBUF+1024	; 1024 bytes buffer
FILE_OPN:	.byte 0		; opened file number

; Table for create

FILE_CR:	.byte $07
		.addr CONFIG_FILE_NAME	; addr len+name
		.byte $C3		; Full access
		.byte $06		; BIN file
		.addr $FFFF		; Aux data - load addr
		.byte $01			; Standard seedling file
		.byte $00, $00		; Creation date
		.byte $00, $00		; Creation time

; Table for read

FILE_RD:	.byte 4
FILE_RDN:	.byte 0			; opened file number
FILE_RADR:	.addr PARMS		; loading addr
FILE_RLEN:	.addr PARMSEND-PARMS	; max len
FILE_RALEN:	.addr $FFFF		; real len of loaded file

; Table for write

FILE_WR:	.byte 4
FILE_WRN:	.byte 0			; opened file number
FILE_WADR:	.addr PARMS		; loading addr
FILE_WLEN:	.addr PARMSEND-PARMS	; max len
FILE_WALEN:	.byte 0,0		; real len of loaded file

; Table for close

FILE_CL:	.byte 1
FILE_END:
FILE_CLN:	.byte 0			; opened file number