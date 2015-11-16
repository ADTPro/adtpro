;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2015 by David Schmidt
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
; Based on ideas from Terence J. Boldt

w5100_ptr  := $06         ; 2 byte pointer value
w5100_sha  := $08         ; 2 byte physical addr shadow ($F000-$FFFF)
w5100_adv  := $EB         ; 2 byte pointer register advancement
w5100_len  := $ED         ; 2 byte frame length
w5100_tmp  := $FA         ; 1 byte temporary value
w5100_bas  := $FB         ; 1 byte socket 1 Base Address (hibyte)

; Hardware addresses of w5100 - $C0xy, where x is slot number + 8
w5100_mode := $C0B4
w5100_addr := $C0B5
w5100_data := $C0B7

w5100_ip_parms := $7000 ; w5100 driver load address