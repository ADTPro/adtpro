; Define an ASCII charcter with no attributes (high bit set).
.define _(char) char | $80

; Define an ASCII character with the inverse attribute
.define _I(char) char & $3f

; Define as ASCII string with no attributes
.macro  asc Arg
        .repeat .strlen(Arg), I
        .byte   .strat(Arg, I) | $80
        .endrep
.endmacro

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
