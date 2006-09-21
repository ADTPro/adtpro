	.include "bsave.asm"

COMMAND:	.byte "BSAVE ADTPROETH,A$0803,L$"
NYBBLE1:	.byte $00
NYBBLE2:	.byte $00
NYBBLE3:	.byte $00
NYBBLE4:	.byte $00
CMDEND:	.byte $8D
LENGTH:	.word PEND-PBEGIN
