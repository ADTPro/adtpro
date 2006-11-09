;
; ADTPro - Apple Disk Transfer ProDOS
; Copyright (C) 2006 by David Schmidt
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

;---------------------------------------------------------
; Passive addresses (not written to)
;---------------------------------------------------------
MLI	= $BF00
MLIADDR	= $BF10

;---------------------------------------------------------
; ProDOS equates
;---------------------------------------------------------
PD_ONL	= $C5
PD_READ	= $80
PD_WRIT	= $81
PD_INFO	= $C4

;---------------------------------------------------------
; Monitor equates
;---------------------------------------------------------
CH	= $24		; Character horizontal position
CV	= $25		; Character vertical position
BASL	= $28		; Base Line Address
INVFLG	= $32		; Inverse flag
CLREOL	= $FC9C	; Clear to end of line
CLREOP	= $FC42	; Clear to end of screen
HOME	= $FC58	; Clear screen
TABV	= $FB5B	; Set BASL from Accumulator
RDKEY	= $FD0C	; Character input
NXTCHAR	= $FD75	; Line input
COUT1	= $FDF0	; Character output
CROUT	= $FD8E	; Output return character
PRDEC	= $ED24	; Print pointer as decimal

;---------------------------------------------------------
; Horizontal tabs for volume display
;---------------------------------------------------------
H_SL	= $02
H_DR	= $08
H_VO	= $0f
H_SZ	= $21

;---------------------------------------------------------
; Horizontal tabs for buffer display
;---------------------------------------------------------
H_BUF	= $05
H_BLK	= $0f
H_NUM1	= $15

;---------------------------------------------------------
; Veritcal tab for buffer display
;---------------------------------------------------------
V_MSG	= $0b
V_BUF	= $0f

;---------------------------------------------------------
; Characters
;---------------------------------------------------------
CHR_BLK	= $20
CHR_SP	= ' ' | $80
CHR_DOT = '.' | $80
CHR_C	= 'C' | $80
CHR_D	= 'D' | $80
CHR_F	= 'F' | $80
CHR_G	= 'G' | $80
CHR_I	= 'I' | $80
CHR_O	= 'O' | $80	; The letter O
CHR_P	= 'P' | $80
CHR_Q	= 'Q' | $80
CHR_R	= 'R' | $80
CHR_S	= 'S' | $80
CHR_V	= 'V' | $80
CHR_W	= 'W' | $80
CHR_X	= 'X' | $80
CHR_Z	= 'Z' | $80
CHR_0	= '0' | $80	; Zero
CHR_1	= '1' | $80
CHR_2	= '2' | $80
CHR_3	= '3' | $80
CHR_4	= '4' | $80
CHR_5	= '5' | $80
CHR_6	= '6' | $80
CHR_7	= '7' | $80
CHR_8	= '8' | $80
CHR_9	= '9' | $80
CHR_ESC	= $9b
CHR_ACK	= $06
CHR_NAK	= $15

;---------------------------------------------------------
; Apple IIgs SCC Z8530 registers and constants
;---------------------------------------------------------

GSCMDB	=	$C038
GSDATAB	=	$C03A

GSCMDA	=	$C039
GSDATAA	=	$C03B

RESETA	=	%11010001	; constant to reset Channel A
RESETB	=	%01010001	; constant to reset Channel B
WR11A	=	%11010000	; init wr11 in Ch A
WR11BXTAL	=	%00000000	; init wr11 in Ch B - use external clock
WR11BBRG	=	%01010000	; init wr11 in Ch B - use baud rate generator

;---------------------------------------------------------
; Apple II character mapping - turn that high-bit on!
;---------------------------------------------------------

.charmap	$20, $A0
.charmap	$21, $A1
.charmap	$22, $A2
.charmap	$23, $A3
.charmap	$24, $A4
.charmap	$25, $A5
.charmap	$26, $A6
.charmap	$27, $A7
.charmap	$28, $A8
.charmap	$29, $A9
.charmap	$2a, $Aa
.charmap	$2b, $Ab
.charmap	$2c, $Ac
.charmap	$2d, $AD
.charmap	$2e, $Ae
.charmap	$2f, $Af

.charmap	$30, $b0
.charmap	$31, $b1
.charmap	$32, $b2
.charmap	$33, $b3
.charmap	$34, $b4
.charmap	$35, $b5
.charmap	$36, $b6
.charmap	$37, $b7
.charmap	$38, $b8
.charmap	$39, $b9
.charmap	$3a, $ba
.charmap	$3b, $bb
.charmap	$3c, $bc
.charmap	$3d, $bd
.charmap	$3e, $be
.charmap	$3f, $bf

