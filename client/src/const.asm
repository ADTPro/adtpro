*
* ADTPro - Apple Disk Transfer ProDOS
* Copyright (C) 2006 by David Schmidt
* david__schmidt at users.sourceforge.net
*
* This program is free software; you can redistribute it and/or modify it 
* under the terms of the GNU General Public License as published by the 
* Free Software Foundation; either version 2 of the License, or (at your 
* option) any later version.
*
* This program is distributed in the hope that it will be useful, but 
* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
* or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License 
* for more details.
*
* You should have received a copy of the GNU General Public License along 
* with this program; if not, write to the Free Software Foundation, Inc., 
* 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*

*---------------------------------------------------------
* Passive addresses (not written to)
*---------------------------------------------------------
MLI	.eq $BF00
MLIADDR	.eq $BF10

*---------------------------------------------------------
* ProDOS equates
*---------------------------------------------------------
PD_ONL	.eq $C5
PD_READ	.eq $80
PD_WRIT	.eq $81
PD_INFO	.eq $C4

*---------------------------------------------------------
* Monitor equates
*---------------------------------------------------------
ch	.eq $24		Character horizontal position
cv	.eq $25		Character vertical position
BASL	.eq $28		Base Line Address
INVFLG	.eq $32		Inverse flag
CLREOL	.eq $FC9C	Clear to end of line
CLREOP	.eq $FC42	Clear to end of screen
HOME	.eq $FC58	Clear screen
TABV	.eq $FB5B	Set BASL from Accumulator
RDKEY	.eq $FD0C	Character input
NXTCHAR	.eq $FD75	Line input
COUT1	.eq $FDF0	Character output
CROUT	.eq $FD8E	Output return character
PRDEC   .eq $ED24	Print pointer as decimal

*---------------------------------------------------------
* Horizontal tabs for volume display
*---------------------------------------------------------
H_SL	.eq $02
H_DR	.eq $08
H_VO	.eq $0f
H_SZ	.eq $21

*---------------------------------------------------------
* Horizontal tabs for buffer display
*---------------------------------------------------------
H_BUF	.eq $05
H_BLK	.eq $0f
H_NUM1	.eq $15

*---------------------------------------------------------
* Veritcal tab for buffer display
*---------------------------------------------------------
V_MSG	.eq $0b
V_BUF	.eq $0f

*---------------------------------------------------------
* Characters
*---------------------------------------------------------
CHR_BLK	.eq $20
CHR_SP	.eq " "
CHR_C	.eq "C"
CHR_G	.eq "G"
CHR_I	.eq "I"
CHR_O	.eq "O"		The letter O
CHR_P	.eq "P"
CHR_R	.eq "R"
CHR_S	.eq "S"
CHR_V	.eq "V"
CHR_W	.eq "W"
CHR_X	.eq "X"
CHR_Z	.eq "Z"
CHR_0	.eq "0"		Zero
CHR_ESC	.eq $9b
CHR_ACK	.eq $06
CHR_NAK	.eq $15

*---------------------------------------------------------
* Apple IIgs SCC Z8530 registers and constants
*---------------------------------------------------------

GSCMDB	.eq	$C038
GSDATAB	.eq	$C03A

GSCMDA	.eq	$C039
GSDATAA	.eq	$C03B

RESETA	.eq	%11010001	constant to reset Channel A
RESETB	.eq	%01010001	constant to reset Channel B
WR11A	.eq	%11010000	init wr11 in Ch A
WR11B	.eq	%01010000	init wr11 in Ch B

