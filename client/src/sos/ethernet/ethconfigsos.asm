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

.include "ethconfig.asm"

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $03		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 4,2,2	; Number of options for each parm
LINECNT:	.byte 00		; CURRENT LINE NUMBER
CURPARM:	.byte 00		; ACTIVE PARAMETER
CURVAL:		.byte 00		; VALUE OF ACTIVE PARAMETER
OLDPARM:	.byte $00,$00,$00	; There must be PARMNUM bytes here...

PARMTXT:
	ascz "1"
	ascz "2"
	ascz "3"
	ascz "4"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

CONFIG_FILE_NAME:	.byte 14
			asc "ADTSOSETH.CONF"

YSAVE:	.byte $00

PARMS:
PSSC:	.byte 2		; Zero-indexed Comms slot (3)
PSOUND:	.byte 0		; Sounds? (YES)
PSAVE:	.byte 1		; Save parms? (NO)

ip_parms:
serverip:	.byte 192, 168,   0,  12
cfg_ip:		.byte 192, 168,   0, 123
cfg_netmask:	.byte 255, 255, 248,   0
cfg_gateway:	.byte 192, 168,   0,   1

DEFAULT:	.byte 2,0,1	; Default parm indices
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND: