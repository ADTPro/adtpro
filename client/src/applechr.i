;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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

; Define an ASCII charcter with no attributes (high bit set).
.define _(char) char | $80

; Define an ASCII character with the inverse attribute
.define _I(char) char & $3f

; Define an ASCII string with no attributes
.macro  asc Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
.endmacro

.define asc2(Arg)  asc Arg

.macro  ascz Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
        .byte   $00
.endmacro

.macro  asccr Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
        .byte   $8d
.endmacro

; Define an ASCII string with the inverse attribute
.macro  inv   Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) & $3f
        .endrep
.endmacro

.macro  invcr   Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) & $3f
        .endrep
        .byte $8d
.endmacro
