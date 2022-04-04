.import console_printf

.macro printfargs arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
.ifnblank arg1
    .addr arg1
    printfargs arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
.endif
.endmacro

.macro printf str, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
  .local arglist
  .local string
  pha
.ifpc02
    phx
    phy
.else
    txa
    pha
    tya
    pha
.endif
  ldax #arglist
  jsr console_printf
.ifpc02
    ply
    plx
.else
    pla
    tay
    pla
    tax
.endif
  pla
.pushseg
.rodata
.if (.match(str, ""))
  string:  .asciiz str
  arglist: .addr string
.else
  arglist: .addr str
.endif
  printfargs arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9
.popseg
.endmacro



; -- LICENSE FOR printf.inc --
; The contents of this file are subject to the Mozilla Public License
; Version 1.1 (the "License"); you may not use this file except in
; compliance with the License. You may obtain a copy of the License at
; http://www.mozilla.org/MPL/
;
; Software distributed under the License is distributed on an "AS IS"
; basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See the
; License for the specific language governing rights and limitations
; under the License.
;
; The Original Code is ip65.
;
; The Initial Developer of the Original Code is Jonno Downes,
; jonno@jamtronix.com.
; Portions created by the Initial Developer are Copyright (C) 2009
; Jonno Downes. All Rights Reserved.
; -- LICENSE END --
