@rem
@rem "Makefile" for ADTPro client
@rem
@rem We expect to be able to find "sbasm" (SB Assembler)
@rem (http://www.xs4all.nl/~sbp/sbasm/sbasm.htm)
@rem and "ac" (AppleCommander Java invocation)
@rem (http://applecommander.sourceforge.net/) on the
@rem command line.
@rem
@rem Parameters:
@rem   diskname - the name of the Apple ][ disk to modify
@rem
@rem Need to know where sbasm is...
@rem
@path=%PATH%;C:\dev\xassm\sbasm\2.06
@call sbasm main.asm 2> ..\..\build\asm.out
@copy adtpro ..\..\build
@cd ..\..\build
@type asm.out | grep "in assembly"
@copy /y ADTProBase.dsk %1.dsk
@rem @call ac -d adtpro %1.dsk
@type adtpro | ac -p adtpro bin 2051 %1.dsk
