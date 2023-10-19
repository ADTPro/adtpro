;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2023 by David Schmidt
; 1110325+david-schmidt@users.noreply.github.com
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
; audjoypreamble - preamble for audio/joystick bootstrap
;---------------------------------------------------------
	.segment "PREAMBLE"
    .include "../../applechr.i"
; Message, $28 bytes at $7d0.$7f7
;        ........................................    
    asc "BANG v1 K. Dickey, P. Ferrie, D. Schmidt"
; TLC observed screen holes: $7f8.$7ff
	.byte $00, $7f, $7f, $bd, $e6, $fe, $fd, $ff
