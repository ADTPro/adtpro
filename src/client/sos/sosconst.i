;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2008 - 2014 by David Schmidt
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

.include "applechr.i"		; ASCII string productions
.include "const.i"		; ProDOS/SOS, CHR equates

;---------------------------------------------------------
; Horizontal tabs for volume display
;---------------------------------------------------------
H_SL	= $01
H_VO	= $08
H_SZ	= $21
VOL_LINE_LEN = $26

;--------------------------------------------------------- 
; SOS specific stuff
;--------------------------------------------------------- 
OS_CALL_OFFSET	= 1	; Offset to the SOS call type byte
CHR_RETURN	= $8d	; Carriage return
IN_BUF		= $1e00	; Must match the value that's set in rawio.asm at INBUF
ALLOCSIR	= $1913
DEALCSIR	= $1916

;--------------------------------------------------------- 
; Apple /// hardware stuff
;--------------------------------------------------------- 
MAXSLOT		= $04	; The largest slot number we're likely to encounter (one-indexed)
E_REG		= $FFDF	; Environment register
B_REG		= $FFEF	; Bank register
Z_REG		= $FFD0	; Zero-page register

INV_CHR_L	= $4c
INV_BLOCK	= $20
NRM_BLOCK	= $a0