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

	.macro  define_msg	MESSAGE_DATA_LENGTH, d1, d2, d3, d4, d5, d6
	.local	MESSAGE_DATA_START, MESSAGE_DATA_END

MESSAGE_DATA_LENGTH:
	.byte MESSAGE_DATA_END-MESSAGE_DATA_START
MESSAGE_DATA_START:
	.byte d1
	.ifnblank d2
	.byte d2
	.endif
	.ifnblank d3
	.byte d3
	.endif
	.ifnblank d4
	.byte d4
	.endif
	.ifnblank d5
	.byte d5
	.endif
	.ifnblank d6
	.byte d6
	.endif
MESSAGE_DATA_END:
.endmacro