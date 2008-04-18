;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 by David Schmidt
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

.include "messages.asm"
.include "prodos/prodosmessages.asm"

	MSG10: .byte	$20,$20,$20,$A0,$A0,$20,$20,$20,$A0,$A0,$20,$A0,$A0,$A0,$20,$8D
	MSG10_END =*
	MSG11: .byte	$20,$A0,$A0,$20,$A0,$20,$A0,$A0,$20,$A0,$A0,$20,$A0,$20,$8D
	MSG11_END =*
	MSG12: .byte	$20,$A0,$A0,$20,$A0,$20,$A0,$A0,$20,$A0,$A0,$A0,$20,$8D
	MSG12_END =*
	MSG26: asc	"UTHER SLOT"
	MSG26_END =*
	MSG27:
	MSG27_END =*			; Note - no message 27 in ethernet.

	IPMsg01: asc	"SERVER IP ADDR"
	IPMsg01_END =*
	IPMsg02: asc	"LOCAL IP ADDR"
	IPMsg02_END =*
	IPMsg03: asc	"NETMASK"
	IPMsg03_END =*
	IPMsg04: asc	"GATEWAY ADDR"
	IPMsg04_END =*

IP_MSG_LEN_TBL:
	.byte IPMsg01_END-IPMsg01
	.byte IPMsg02_END-IPMsg02
	.byte IPMsg03_END-IPMsg03
	.byte IPMsg04_END-IPMsg04

IP_MSGTBL:
	.addr IPMsg01,IPMsg02,IPMsg03,IPMsg04
