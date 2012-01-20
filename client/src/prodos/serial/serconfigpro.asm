;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2012 by David Schmidt
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

.include "serconfig.asm"

; Note - code in findslot, and then the serial drivers in
; ssc, pascalep, and iigsscc complete this functional unit. 

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $04		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 9,4,2,2	; Number of options for each parm

PARMTXT:
	ascz "SSC SLOT 1"
	ascz "SSC SLOT 2"
	ascz "SSC SLOT 3"
	ascz "SSC SLOT 4"
	ascz "SSC SLOT 5"
	ascz "SSC SLOT 6"
	ascz "SSC SLOT 7"
	ascz "IIGS MODEM"
	ascz "GENERIC SLOT 2"
	ascz "300"
	ascz "9600"
	ascz "19200"
	ascz "115200"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

YSAVE:		.byte $00

CONFIG_FILE_NAME:
		.byte 11
		.byte "ADTPRO.CONF"

PARMS:
COMMSLOT:	.byte 1		; Comms slot (2)
PSPEED:		.byte 3		; Comms speed (115200)
PSOUND:		.byte 0		; Sounds? (YES)
PSAVE:		.byte 1		; Save parms? (NO)
DEFAULT:	.byte 1,3,0,1	; Default parm indices
SVSPEED:	.byte 3		; Storage for speed setting
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND: