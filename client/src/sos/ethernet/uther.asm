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

	.import ip65_init
	.import ip65_process

	.import udp_add_listener
	.import udp_callback
	.import udp_send

	.import udp_inp
	.import udp_outp

	.importzp udp_data
	.importzp udp_len
	.importzp udp_src_port
	.importzp udp_dest_port

	.import udp_send_dest
	.import udp_send_src_port
	.import udp_send_dest_port
	.import udp_send_len

	.importzp ip_src
	.import ip_inp

cnt:		.res 1
replyaddr:	.res 4
replyport:	.res 2
state:		.res 2
