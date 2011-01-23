;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 - 2010 by David Schmidt
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
	.export cfg_ip
	.export cfg_netmask
	.export cfg_gateway
	.export cfg_dns
	.export dhcp_server
	.export cfg_tftp_server

;---------------------------------------------------------
; Configuration
;---------------------------------------------------------

PARMNUM	= $03		; Number of configurable parms
;			; Note - add bytes to OLDPARM if this is expanded.
PARMSIZ: .byte 7,2,2	; Number of options for each parm
LINECNT:	.byte 00		; CURRENT LINE NUMBER
CURPARM:	.byte 00		; ACTIVE PARAMETER
CURVAL:		.byte 00		; VALUE OF ACTIVE PARAMETER
OLDPARM:	.byte $00,$00,$00	; There must be PARMNUM bytes here...

PARMTXT:
	ascz "1"
	ascz "2"
	ascz "3"
	ascz "4"
	ascz "5"
	ascz "6"
	ascz "7"
	ascz "YES"
	ascz "NO"
	ascz "YES"
	ascz "NO"

CONFIG_FILE_NAME:	.byte 14
			asc "ADTPROETH.CONF"

YSAVE:	.byte $00

PARMS:
COMMSLOT:
	.byte 2		; Comms slot (3)
PSOUND:	.byte 0		; Sounds? (YES)
PSAVE:	.byte 1		; Save parms? (NO)

ip_parms:
serverip:	.byte 192, 168,   0,  12
cfg_ip:		.byte   0,   0,   0,   0 ; ip address of local machine (will be overwritten if dhcp_init is called)
cfg_netmask:	.byte   0,   0,   0,   0 ; netmask of local network (will be overwritten if dhcp_init is called)
cfg_gateway:	.byte   0,   0,   0,   0 ; ip address of router on local network (will be overwritten if dhcp_init is called)

DEFAULT:	.byte 2,0,1	; Default parm indices
CONFIGYET:	.byte 0		; Has the user configged yet?
PARMSEND:
cfg_dns:	.byte   0,   0,   0,   0 ; ip address of dns server to use (will be overwritten if dhcp_init is called)
dhcp_server:	.byte   0,   0,   0,   0 ; will be set address of dhcp server that configuration was obtained from
cfg_tftp_server: .byte   0,   0,   0,   0 ; ip address of server to send tftp requests to (can be a broadcast address)
