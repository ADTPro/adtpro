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

.include "macros.i"

.macro 	CALLOS Arg1, Arg2
	clc
	jsr PRODOS_MLI	; Which ought to be $BF00
	.byte Arg1
	.addr Arg2
.endmacro

.macro CALLOS_CHECK_POS
	bcc :+		; Branch on success
.endmacro

.macro CALLOS_CHECK_NEG
	bcs :+		; Branch on failure
.endmacro

.macro CONDITION_KEYPRESS
	and #$DF	; Convert to upper case
.endmacro

.define	INV_BLOCK $20	; ASCII for an inverse space - is differernt on SOS
.define	NRM_BLOCK $A0	; ASCII for a normal space - is different on SOS
.define INV_OFF   	; Nothing to do for ProDOS
