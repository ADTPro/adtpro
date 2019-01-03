; VSDrive

; 0.01A - Initial release
; 0.02B - Fill in block sizes, implement reset control action
; 1.26  - More bounds checking for block writes, remove underscrores from
;         names, clean up module name, synchronize version number with ADTPro release 
; 1.28  - Use newer time-transporting protocol, add second drive as .VSDRIVE2
; 1.31  - Add null interrupt handler for ACIA

          .TITLE "Apple /// Virtual Serial Drive Driver"
          .PROC  VSDRIVE

DriverVersion   .EQU 1310            ; Version number
DriverMfgr      .EQU 4453            ; Driver Manufacturer - DS

;
; SOS Equates
;
ExtPG     .EQU 1401                  ; Driver extended bank address offset
AllocSIR  .EQU 1913                  ; Allocate system internal resource
SysErr    .EQU 1928                  ; Report error to system
EReg      .EQU 0FFDF                 ; Environment register
ReqCode   .EQU 0C0                   ; Request code
SOS_Unit  .EQU 0C1                   ; Unit number
SosBuf    .EQU 0C2                   ; SOS buffer pointer (2 bytes)
ReqCnt    .EQU 0C4                   ; Requested byte count
CtlStat   .EQU 0C2                   ; Control/status code
CSList    .EQU 0C3                   ; Control/status list pointer
SosBlk    .EQU 0C6                   ; Starting block number
QtyRead   .EQU 0C8                   ; Pointer to bytes read returned by D_READ

;
; Our temps in zero page
;
Count     .EQU 0CE                   ; 2 bytes
Timer     .EQU 0D0                   ; 2 bytes
NumBlks   .EQU 0D2                   ; 2 bytes lb,hb
DataBuf   .EQU 0D4                   ; 2 bytes
EnvCmd    .EQU 0D6                   ; 1 byte envelope command
Checksum  .EQU 0D7                   ; 1 byte checksum calc
;
; Communications hardware constants
;
ACIADR    .EQU 0c0f0                 ; ACIA Data register
ACIASR    .EQU 0c0f1                 ; ACIA Status register
ACIACMD   .EQU 0c0f2                 ; ACIA Command mode register
ACIACTL   .EQU 0c0f3                 ; ACIA Control register
;
; SOS Error Codes
;
XDNFERR   .EQU 010                   ; Device not found
XBADDNUM  .EQU 011                   ; Invalid device number
XREQCODE  .EQU 020                   ; Invalid request code
XCTLCODE  .EQU 021                   ; Invalid control/status code
XCTLPARAM .EQU 022                   ; Invalid control/status parameter
XNORESRC  .EQU 025                   ; Resources not available
XBADOP    .EQU 026                   ; Invalid operation
XIOERROR  .EQU 027                   ; I/O error
XNODRIVE  .EQU 028                   ; Drive not connected
XBYTECNT  .EQU 02C                   ; Byte count not a multiple of 512
XBLKNUM   .EQU 02D                   ; Block number to large
XDISKSW   .EQU 02E                   ; Disk switched
XNORESET  .EQU 033                   ; Device reset failed
;
; Switch Macro
;
          .MACRO    switch
          .IF       "%1" <> ""       ; If parameter 1 is present
          LDA       %1               ; Load A with switch index
          .ENDC
          CMP       #%2+1            ; Do bounds check
          BCS       $010
          ASL       A
          TAY
          LDA       %3+1,Y           ; Get switch index from table
          PHA
          LDA       %3,Y
          PHA
          .IF       "%4" <> "*"      ; If parameter 4 omitted,
          RTS                        ;   then go to code
          .ENDC
$010      .ENDM

;
; GoSlow macro - slow down via E-Register
;
          .MACRO GoSlow
          PHA
          LDA EReg
          ORA #080                   ; Set 1MHz switch
          STA EReg
          PLA
          .ENDM

;
; GoFast macro - speed up via E-Register
;
          .MACRO GoFast
          PHA
          LDA EReg
          AND #07f
          STA EReg                   ; Whatever it was - set it back
          PLA
          .ENDM

;
; Comment Field of driver
;
          .WORD  0FFFF ; Signal that we have a comment
          .WORD  66. ; Length of comment field... entered manually.
                     ; The Pascal Assembler can't count forward references.
                     ; SCP only shows 78 characters' worth of information.
          .ASCII "Apple /// Virtual Serial Drive Driver by"
          .ASCII " David Schmidt 2012 - 2014"
;                          1         2         3         4
;                 1234567890123456789012345678901234567890

;------------------------------------
;
; Device identification Block (DIB) - VSDRIVE
;
;------------------------------------

DIB_0     .WORD     DIB_1            ; Link pointer
          .WORD     Entry            ; Entry pointer
          .BYTE     008              ; Name length byte
          .ASCII    ".VSDRIVE       "; Device name
          .BYTE     080              ; Active, no page alignment
          .BYTE     000              ; Slot number
          .BYTE     000              ; Unit number
          .BYTE     0E1              ; Type
          .BYTE     010              ; Subtype
          .BYTE     000              ; Filler
DIB0_Blks .WORD     0000             ; # Blocks in device
          .WORD     DriverMfgr       ; Manufacturer
          .WORD     DriverVersion    ; Driver version
          .WORD     0000             ; DCB length followed by DCB

;------------------------------------
;
; Device identification Block (DIB) - VSDRIVE2
;
;------------------------------------

DIB_1     .WORD     0000             ; Link pointer
          .WORD     Entry            ; Entry pointer
          .BYTE     009              ; Name length byte
          .ASCII    ".VSDRIVE2      "; Device name
          .BYTE     080              ; Active, no page alignment
          .BYTE     000              ; Slot number
          .BYTE     001              ; Unit number
          .BYTE     0E1              ; Type
          .BYTE     010              ; Subtype
          .BYTE     000              ; Filler
DIB1_Blks .WORD     0000             ; # Blocks in device
          .WORD     DriverMfgr       ; Manufacturer
          .WORD     DriverVersion    ; Driver version
          .WORD     0000             ; DCB length followed by DCB

;------------------------------------
;
; Local storage locations
;
;------------------------------------

LastOP    .BLOCK    002, 0FF         ; Last operation for D_REPEAT calls
SIRAddr   .WORD     SIRTbl
SIRTbl    .BYTE     001              ; ACIA resource
          .BYTE     000
          .WORD     0FEC4            ; Do-nothing interrupt vector
          .BYTE     000              ; Bank register
SIRLen    .EQU      *-SIRTbl
RdBlkProc .WORD     0000
WrBlkProc .WORD     0000
StackPtr  .BYTE     000
DCB_Idx   .BYTE     000                  ; DCB 0's blocks
          .BYTE     DIB1_Blks-DIB0_Blks  ; DCB 1's blocks

;------------------------------------
;
; Driver request handlers
;
;------------------------------------

Entry     JSR Dispatch               ; Call the dispatcher
          LDX SOS_Unit               ; Get drive number for this unit
          LDA ReqCode                ; Keep request around for D_REPEAT
          STA LastOP,X               ; Keep track of last operation
          LDA #000
          RTS
;
; The Dispatcher.  Note that if we came in on a D_INIT call,
; we do a branch to Dispatch normally.  
; Dispatch is called as a subroutine!
;
DoTable   .WORD     DRead-1          ; 0 Read request
          .WORD     DWrite-1         ; 1 Write request
          .WORD     DStatus-1        ; 2 Status request
          .WORD     DControl-1       ; 3 Control request
          .WORD     BadReq-1         ; 4 Unused
          .WORD     BadReq-1         ; 5 Unused
          .WORD     BadOp-1          ; 6 Open - valid for character devices
          .WORD     BadOp-1          ; 7 Close - valid for character devices
          .WORD     DInit-1          ; 8 Init request
          .WORD     DRepeat-1        ; 9 Repeat last read or write request
Dispatch  SWITCH    ReqCode,9,DoTable ; Serve the request

;
; Dispatch errors
;
BadReq    LDA #XREQCODE              ; Bad request code!
          JSR SysErr                 ; Return to SOS with error in A
BadOp     LDA #XBADOP                ; Invalid operation!
          JSR SysErr                 ; Return to SOS with error in A

;
; D_REPEAT - repeat the last D_READ or D_WRITE call
;
DRepeat   LDX SOS_Unit
          LDA LastOP,X               ; Recall the last thing we did
          CMP #002                   ; Looking for operation < 2
          BCS BadOp                  ; Can only repeat a read or write
          STA ReqCode
          JMP Dispatch

NoDevice  LDA #XDNFERR               ; Device not found
          JSR SysErr                 ; Return to SOS with error in A

;
; D_INIT call processing - called at initialization
;
DInit
          LDA SOS_Unit               ; Check if we're initting the zeroeth unit
          BNE DInitDone              ; If not - skip the serial setup
          LDA #SIRLen
          LDX SIRAddr
          LDY SIRAddr+1
          JSR AllocSIR               ; Allocate the ACIA
          BCS NoACIA

          PHP
          SEI                        ; Disable system interrupts
          GoSlow                     ; Set up the communications environment
          LDA #00b                   ; No parity, no interrupts
          STA ACIACMD                ; Store via ACIA command register
          LDA #010                   ; $16=300, $1e=9600, $1f=19200, $10=115k
          STA ACIACTL                ; Store via ACIA control register
          LDA ACIASR                 ; Clear any prior ACIA interrupts
          GoFast
          PLP                        ; Re-enable system interrupt state

DInitDone
          CLC
          RTS
NoACIA
          LDA #XNORESRC
          JSR SysErr                 ; Return to SOS with error in A

;
; D_READ call processing
;
DRead
          TSX
          STX StackPtr               ; Hang on to the stack pointer for hasty exits
          JSR CkCnt                  ; Checks for validity, aborts if not
          JSR CkUnit                 ; Checks for unit below unit max
          LDA #000                   ; Zero # bytes read
          STA Count                  ; Local count of bytes read
          STA Count+1
          TAY
          STA (QtyRead),Y            ; Userland count of bytes read
          INY
          STA (QtyRead),Y            ; Msb of userland bytes read
          LDA NumBlks                ; Check for NumBlks greater than zero
          ORA NumBlks+1
          BEQ ReadExit
          JSR FixUp                  ; Correct for addressing anomalies
          JSR ReadBlock              ; Transfer a block to/from the disk
          LDY #000
          LDA Count                  ; Local count of bytes read
          STA (QtyRead),y            ; Update # of bytes actually read
          INY
          LDA Count+1
          STA (QtyRead),y
          BCS IOError                ; An error occurred
ReadExit  RTS                        ; Exit read routines
IOError   LDA #XIOERROR              ; I/O error
          JSR SysErr                 ; Return to SOS with error in A

;
; D_WRITE call processing
;
DWrite
          TSX
          STX StackPtr               ; Hang on to the stack pointer for hasty exits
          JSR CkCnt                  ; Checks for validity
          JSR CkUnit                 ; Checks for unit below unit max
          LDA NumBlks                ; Check for NumBlks greater than zero
          ORA NumBlks+1
          BEQ WriteExit              ; Quantity to write is zero - so done
          JSR FixUp
          JSR WriteBlock
          BCS IOError
WriteExit RTS

;
; D_STATUS call processing
;  $00 = Driver Status
;  $01 = Report drive size
;  $FE = Return preferred bitmap location ($FFFF)
;
DStatus
          LDA CtlStat                ; Which status code to run?
          BNE DS0
          LDY #000                   ; 000 - Driver status, return zero
          STA (CSList),Y
          CLC
          RTS
DS0       CMP #0FE
          BNE DSWhat
          LDY #000                   ; Return preferred bit map locations.
          LDA #0FF                   ; We return FFFF, don't care
          STA (CSList),Y
          INY
          STA (CSList),Y       
          CLC
          RTS
DSWhat    LDA #XCTLCODE              ; Control/status code no good
          JSR SysErr                 ; Return to SOS with error in A

;
; D_CONTROL call processing
;  $00 = Reset device
;  $FE = Perform media formatting
;
DControl
          LDA CtlStat                ; Control command
          BEQ CReset
          JMP DCWhat                 ; Control code no good!
CReset    GoSlow
          BIT ACIADR                 ; Clear ACIA Data register
          GoFast
DCDone    RTS          
DCNoReset LDA #XNORESET              ; Things went bad after reset
          JSR SysErr                 ; Return to SOS with error in A
DCWhat    LDA #XCTLCODE              ; Control/status code no good
          JSR SysErr                 ; Return to SOS with error in A

;------------------------------------
;
; Utility routines
;
;------------------------------------

;
; ReadBlock - Read requested blocks from device into memory
;
ReadBlock
          LDA SosBuf                 ; Copy out buffer pointers
          STA DataBuf
          LDA SosBuf+1
          STA DataBuf+1
          LDA SosBuf+ExtPG
          STA DataBuf+ExtPG

          LDA #003                   ; Read request with current time information
          CLC
          ADC SOS_Unit               ; Add two to the request if this is the second unit
          ADC SOS_Unit
          STA EnvCmd
ReadSend
          JSR SendEnvelope
          JSR DTReceiveEnvelope
          BCS ReadFail

          LDY #000
          STY Checksum
RdBlk2    JSR GETC
          BCS ReadFail
          STA (DataBuf),Y
          EOR Checksum
          STA Checksum
          INY
          BNE RdBlk2
          JSR IncrAdr
RdBlk3    JSR GETC
          BCS ReadFail
          STA (DataBuf),Y
          EOR Checksum
          STA Checksum
          INY
          BNE RdBlk3
          JSR IncrAdr
          JSR GETC                   ; Pull Checksum
          BCS ReadFail
          CMP Checksum
          BNE ReadFail

          DEC NumBlks                ; Did we get what was asked for?
          BNE RdMore
          DEC NumBlks+1
          BPL RdMore
          
          LDA SosBlk
          CMP #002                   ; Is this block #2 (lsb=2)?
          BNE RdDone
          LDA SosBlk+1
          BNE RdDone                 ; Is this block #2 (msb=0)?

          LDY #029                   ; Yes - store off the disk size
          LDA (SosBuf),Y
          PHA
          INY
          LDA (SosBuf),Y
          PHA
          LDX SOS_Unit               ; Get the stats on this unit
          LDY DCB_Idx,X
          PLA
          STA DIB0_Blks+1,Y
          PLA
          STA DIB0_Blks,Y
          
RdDone    CLC
          RTS

RdMore    INC SosBlk
          BNE ReadSend
          INC SosBlk+1
          JMP ReadSend

;
; ReadFail - Complain with an OS I/O error
;
ReadFail
          LDX StackPtr
          TXS                        ; Pop! Goes the stack pointer
          LDA #XIOERROR              ; Nearby branch point
          JSR SysErr                 ; Return to SOS with error in A

;
; WriteBlock - write memory out to requested blocks
;
WriteBlock
          LDA SosBuf                 ; Copy out buffer pointers
          STA DataBuf
          LDA SosBuf+1
          STA DataBuf+1
          LDA SosBuf+ExtPG
          STA DataBuf+ExtPG

          LDA #002                   ; Write request
          CLC
          ADC SOS_Unit               ; Add two to the request if this is the second unit
          ADC SOS_Unit
          STA EnvCmd
WriteSend
          JSR SendEnvelope
          LDX #000
          STX Checksum
WrBkLoop
          LDY #000
WRLOOP:
          LDA (DataBuf),Y
          JSR PUTCC
          INY
          BNE WRLOOP

          JSR IncrAdr
          INX
          CPX #002
          BNE WRBKLOOP

          LDA Checksum               ; Checksum
          JSR PUTC

          JSR ReceiveEnvelope
          BCS WriteFail

          DEC NumBlks                ; Did we put what was asked for?
          BNE WrMore                 ; Not done yet... go around again
          DEC NumBlks+1              ; (16 bit decrement)
          BPL WrMore                 ; Not done yet... go around again
          CLC
          RTS                        ; We're done

WrMore    INC SosBlk
          BNE WriteSend
          INC SosBlk+1
          JMP WriteSend

;
; WriteFail - Complain with an OS I/O error
;
WriteFail
          LDX StackPtr
          TXS                        ; Pop! Goes the stack pointer
          LDA #XIOERROR
          JSR SysErr                 ; Return to SOS with error in A

;
; SendEnvelope - send the command envelope
;
SendEnvelope                         ; Send a command envelope
          LDA #000
          STA Checksum 
          LDA #0c5                   ; "E"
          JSR PUTCC                  ; Envelope
          LDA EnvCmd
          JSR PUTCC                  ; Send command
          LDA SosBlk
          JSR PUTCC                  ; Send LSB of requested block
          LDA SosBlk+1
          JSR PUTCC                  ; Send MSB of requested block
          LDA Checksum
          JSR PUTC                   ; Send envelope Checksum
          RTS                        ; Carry is clear, return

;
; DTReceiveEnvelope - receive the command envelope back from host, with time data
;
; Note that we can't set the date and time through a SOS call, since device drivers
; are not allowed to make SOS calls.
;
DTReceiveEnvelope
          LDA #000
          STA Checksum
          JSR GETC
          BCS DTEnvelopeFail
          CMP #0c5                   ; "E" - S/B Command envelope
          BNE DTEnvelopeFail
          EOR Checksum
	  STA Checksum
          JSR GETC
          BCS DTEnvelopeFail
          CMP EnvCmd                 ; Command requested
          BNE DTEnvelopeFail
          EOR Checksum
	  STA Checksum
          JSR GETC                   ; Read LSB of requested block
          BCS DTEnvelopeFail
          CMP SosBlk
          BNE DTEnvelopeFail
          EOR Checksum
	  STA Checksum
          JSR GETC                   ; Read MSB of requested block
          BCS DTEnvelopeFail
          CMP SosBlk+1
          BNE DTEnvelopeFail
          EOR Checksum
	  STA Checksum
	  LDX #004                   ; Pull the four date/time bytes
DTRETime  JSR GETC                   ; Ignore except for checksum calculations
          BCS DTEnvelopeFail
          EOR Checksum
	  STA Checksum
	  DEX
	  BNE DTRETime
          JSR GETC                   ; Checksum
          BCS DTEnvelopeFail
          CMP Checksum
          BNE DTEnvelopeFail
          LDA #000
          CLC
          RTS
DTEnvelopeFail
          SEC
          RTS

;
; ReceiveEnvelope - receive the command envelope back from host
;
ReceiveEnvelope
          JSR GETC
          BCS EnvelopeFail
          CMP #0c5                   ; "E" - S/B Command envelope
          BNE EnvelopeFail
          JSR GETC
          BCS EnvelopeFail
          CMP EnvCmd                 ; Command requested
          BNE EnvelopeFail
          JSR GETC                   ; Read LSB of requested block
          BCS EnvelopeFail
          CMP SosBlk
          BNE EnvelopeFail
          JSR GETC                   ; Read MSB of requested block
          BCS EnvelopeFail
          CMP SosBlk+1
          BNE EnvelopeFail
          JSR GETC                   ; Checksum
          BCS EnvelopeFail
          CMP Checksum
          BNE EnvelopeFail
          LDA #000
          CLC
          RTS
EnvelopeFail
          SEC
          RTS

;
; CalcChecksum - Calculate the checksum of the block at DataBuf
;
CalcChecksum                         ; Calculate the checksum
          LDA SosBuf                 ; Copy out buffer pointers again
          STA DataBuf
          LDA SosBuf+1
          STA DataBuf+1

          LDA #000                   ; Clean everyone out
          TAX
          TAY
CCLoop:
          EOR (DataBuf),Y
          STA Checksum               ; Save that tally in CHECKSUM
          INY
          BNE CCLoop
          JSR IncrAdr                ; Y just wrapped; bump buffer MSB
          INX                        ; Need two loops
          CPX #002                   ; Second loop?
          BNE CCLoop

          RTS

;
; GETC - Get a byte from the ACIA
;
; Carry set on timeout, clear on data (returned in Accumulator)
;
GETC
          LDA #000
          STA Timer
          STA Timer+1
          GoSlow
GETC1     LDA ACIASR                 ; Check status bits via ACIA status register
          AND #068
          CMP #008
          BEQ GETIT                  ; Data is ready, go get it
          INC TIMER
          BNE GETC1                  ; Input register empty, no timeout; loop
          INC TIMER+1
          BNE GETC1                  ; Input register empty, no timeout; loop
          GoFast
          SEC                        ; Timeout; return to caller
          RTS
GETIT
          LDA ACIADR                 ; Get character via ACIA data register
          GoFast
          CLC
          RTS

;
; PUTCC - Put a byte to the ACIA, adding to the checksum
;
PUTCC     PHA
          EOR Checksum
          STA Checksum
          JMP PUTC0
;
; PUTC - Put a byte to the ACIA
;
PUTC
          PHA                        ; Push 'character to send' onto the stack
PUTC0     LDA #000
          STA Timer
          STA Timer+1
          GoSlow
PUTC1
          LDA ACIASR                 ; Check status bits
          AND #070
          CMP #010
          BNE PUTC1                  ; Output register is full, no timeout; so loop
          PLA                        ; Pull 'character to send' back off the stack
          STA ACIADR                 ; Put character
          GoFast
          RTS

;
; Check ReqCnt to ensure it's a multiple of 512.
;
CkCnt     LDA ReqCnt                 ; Look at the lsb of bytes requested
          BNE $1                     ; No good!  lsb should be 00
          STA NumBlks+1              ; Zero out the high byte of blocks
          LDA ReqCnt+1               ; Look at the msb
          LSR A                      ; Put bottom bit into carry, 0 into top
          STA NumBlks                ; Convert bytes to number of blks to xfer
          BCC CvtBlk                 ; Carry is set from LSR to mark error.
$1        LDA #XBYTECNT
          JSR SysErr                 ; Return to SOS with error in A

;
; Test for valid block number; abort on error
;
CvtBlk    LDX SOS_Unit
          LDY DCB_Idx,X
          SEC
          LDA DIB0_Blks+1,Y          ; Blocks on unit msb
          SBC SosBlk+1               ; User requested block number msb
          BVS BlkErr                 ; Not enough blocks on device for request
          BEQ $1		     ; Equal msb; check lsb.
          RTS                        ; Greater msb; we're ok.
$1        LDA DIB0_Blks,Y            ; Blocks on unit lsb
          SBC SosBlk                 ; User requested block number lsb
          BVS BlkErr                 ; Not enough blocks on device for request
          RTS                        ; Equal or greater msb; we're ok.
BlkErr    LDA #XBLKNUM
          JSR SysErr                 ; Return to SOS with erorr in A


IncrAdr
          INC Count+1                ; Increment byte count MSB
          INC DataBuf+1              ; Increment DataBuf MSB in userland
;
; Fix up the buffer pointer to correct for addressing
; anomalies.  We just need to do the initial checking
; for two cases:
; 00xx bank N -> 80xx bank N-1
; 20xx bank 8F if N was 0
; FDxx bank N -> 7Dxx bank N+1
; If pointer is adjusted, return with carry set
;
FixUp     LDA DataBuf+1              ; Look at msb
          BEQ $1                     ; That's one!
          CMP #0FD                   ; Is it the other one?
          BCS $2                     ; Yep. fix it!
          RTS                        ; Pointer unchanged, return carry clear.
$1        LDA #080                   ; 00xx -> 80xx
          STA DataBuf+1
          DEC DataBuf+ExtPG          ; Bank N -> band N-1
          LDA DataBuf+ExtPG          ; See if it was bank 0
          CMP #07F                   ; (80) before the DEC.
          BNE $3                     ; Nope! all fixed.
          LDA #020                   ; If it was, change both
          STA DataBuf+1              ; Msb of address and
          LDA #08F
          STA DataBuf+ExtPG          ; Bank number for bank 8F
          RTS                        ; Return carry set
$2        AND #07F                   ; Strip off high bit
          STA DataBuf+1              ; FDxx ->7Dxx
          INC DataBuf+ExtPG          ; Bank N -> bank N+1
$3        RTS                        ; Return carry set

CkUnit
          CLC
          RTS

         .END
