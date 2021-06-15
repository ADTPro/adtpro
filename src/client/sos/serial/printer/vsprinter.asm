; VSPrinter

; 0.01A - Initial release

;         .TITLE "Apple /// Virtual Serial Printer Driver"
          .PROC  VSPRINTER

                .setcpu "6502"
                .reloc

DriverVersion   :=   $0010           ; Version number
DriverMfgr      :=   $4453           ; Driver Manufacturer - DS

;
; SOS Equates
;
ExtPG     :=   $1401                 ; Driver extended bank address offset
AllocSIR  :=   $1913                 ; Allocate system internal resource
SysErr    :=   $1928                 ; Report error to system
EReg      :=   $FFDF                 ; Environment register
ReqCode   :=   $C0                   ; Request code
SOS_Unit  :=   $C1                   ; Unit number
SosBuf    :=   $C2                   ; SOS buffer pointer (2 bytes)
ReqCnt    :=   $C4                   ; Requested byte count
CtlStat   :=   $C2                   ; Control/status code
CSList    :=   $C3                   ; Control/status list pointer
SosBlk    :=   $C6                   ; Starting block number
QtyRead   :=   $C8                   ; Pointer to bytes read returned by D_READ

;
; Our temps in zero page
;
Count     :=   $CE                   ; 2 bytes
Timer     :=   $D0                   ; 2 bytes
NumBlks   :=   $D2                   ; 2 bytes lb,hb
DataBuf   :=   $D4                   ; 2 bytes
EnvCmd    :=   $D6                   ; 1 byte envelope command
Checksum  :=   $D7                   ; 1 byte checksum calc

;
; Communications hardware constants
;
ACIADR    :=   $c0f0                 ; ACIA Data register
ACIASR    :=   $c0f1                 ; ACIA Status register
ACIACMD   :=   $c0f2                 ; ACIA Command mode register
ACIACTL   :=   $c0f3                 ; ACIA Control register

;
; SOS Error Codes
;
XDNFERR   :=   $10                   ; Device not found
XBADDNUM  :=   $11                   ; Invalid device number
XREQCODE  :=   $20                   ; Invalid request code
XCTLCODE  :=   $21                   ; Invalid control/status code
XCTLPARAM :=   $22                   ; Invalid control/status parameter
XNOTOPEN  :=   $23                   ; Device not open
XNORESRC  :=   $25                   ; Resources not available
XBADOP    :=   $26                   ; Invalid operation
XIOERROR  :=   $27                   ; I/O error
XNODRIVE  :=   $28                   ; Drive not connected
XBYTECNT  :=   $2C                   ; Byte count not a multiple of 512
XBLKNUM   :=   $2D                   ; Block number to large
XDISKSW   :=   $2E                   ; Disk switched
XNORESET  :=   $33                   ; Device reset failed

;
; Switch Macro
;
                 .MACRO  SWITCH index,bounds,adrs_table,noexec      ;See SOS Reference
                 .IFNBLANK index        ;If PARM1 is present,
                 LDA     index          ; load A with switch index
                 .ENDIF
                 .IFNBLANK bounds       ;If PARM2 is present,
                 CMP     #bounds+1      ; perform bounds checking
                 BCS     @110           ; on switch index
                 .ENDIF
                 ASL     A              ;Multiply by 2 for table index
                 TAY
                 LDA     adrs_table+1,Y ;Get switch address from table
                 PHA                    ; and push onto Stack
                 LDA     adrs_table,Y
                 PHA
                 .IFBLANK noexec
                 RTS                    ; exit to code
                 .ENDIF
@110:
                 .ENDMACRO

;
; GoSlow macro - slow down via E-Register
;
          .MACRO GoSlow
          PHA
          LDA EReg
          ORA #$80                   ; Set 1MHz switch
          STA EReg
          PLA
          .ENDMACRO

;
; GoFast macro - speed up via E-Register
;
          .MACRO GoFast
          PHA
          LDA EReg
          AND #$7f
          STA EReg                   ; Whatever it was - set it back
          PLA
          .ENDMACRO

          .SEGMENT "TEXT"

;
; Comment Field of driver
;
          .WORD  $FFFF ; Signal that we have a comment
          .WORD  COMMENT_END - COMMENT ; Length of comment field
COMMENT:  .BYTE "Apple /// Virtual Serial Printer Driver by David Schmidt 2021"
COMMENT_END:

;------------------------------------
;
; Device identification Block (DIB) - VSPRINTER
;
;------------------------------------

DIB_0:
          .WORD     $0000            ; Link pointer
          .WORD     Entry            ; Entry pointer
          .BYTE     $08              ; Name length byte
          .BYTE     ".VSPRINTER     "; Device name
          .BYTE     $80              ; Active, no page alignment
          .BYTE     $00              ; Slot number
          .BYTE     $00              ; Unit number
          .BYTE     $41              ; Type
          .BYTE     $04              ; Subtype
          .BYTE     $00              ; Filler
DIB0_Blks:
          .WORD     $0000            ; # Blocks (none, character device)
          .WORD     DriverMfgr       ; Manufacturer
          .WORD     DriverVersion    ; Driver version
          .WORD     $0000            ; DCB length followed by DCB

;------------------------------------
;
; Local storage locations
;
;------------------------------------

SIRAddr:  .WORD     SIRTbl
SIRTbl:   .BYTE     $01              ; ACIA resource
          .BYTE     $00
          .WORD     $FEC4            ; Do-nothing interrupt vector
          .BYTE     $00              ; Bank register
SIRLen    :=        *-SIRTbl
StackPtr: .BYTE     $00
DCB_Idx:  .BYTE     $00                  ; DCB 0's blocks
OPENFLG:  .BYTE     $00

;------------------------------------
;
; Driver request handlers
;
;------------------------------------

Entry:
          JSR Dispatch               ; Call the dispatcher
          LDX SOS_Unit               ; Get drive number for this unit
          LDA ReqCode                ; Keep request around for D_REPEAT
          LDA #$00
          RTS
;
; The Dispatcher.  Note that if we came in on a D_INIT call,
; we do a branch to Dispatch normally.  
; Dispatch is called as a subroutine!
;
DoTable:
          .WORD     DRead-1          ; 0 Read request
          .WORD     DWrite-1         ; 1 Write request
          .WORD     DStatus-1        ; 2 Status request
          .WORD     DControl-1       ; 3 Control request
          .WORD     BadReq-1         ; 4 Unused
          .WORD     BadReq-1         ; 5 Unused
          .WORD     DOpen-1          ; 6 Open
          .WORD     DClose-1         ; 7 Close
          .WORD     DInit-1          ; 8 Init request
Dispatch: SWITCH    ReqCode,9,DoTable ; Serve the request

;
; Dispatch errors
;
BadReq:   LDA #XREQCODE              ; Bad request code!
          JSR SysErr                 ; Return to SOS with error in A
BadOp:    LDA #XBADOP                ; Invalid operation!
          JSR SysErr                 ; Return to SOS with error in A
NotOpen:  LDA #XNOTOPEN              ; Device not open
          JSR SysErr                 ; Return to SOS with error in A
NoDevice: LDA #XDNFERR               ; Device not found
          JSR SysErr                 ; Return to SOS with error in A

;
; D_READ call processing
;
DRead:
          BIT OPENFLG
          BMI :+
          JMP NotOpen
:         LDA #XBADOP
          JSR SysErr

ReadExit: RTS                        ; Exit read routines

;
; D_WRITE call processing
;
DWrite:
          RTS

;
; D_STATUS call processing
;
DStatus:
          LDA CtlStat                ; Which status code to run?
          BNE DSWhat
          LDY #$00                   ; $00 - Driver status, return zero
          STA (CSList),Y
          CLC
          RTS
DSWhat:   LDA #XCTLCODE              ; Control/status code no good
          JSR SysErr                 ; Return to SOS with error in A

;
; D_CONTROL call processing
;  $00 = Reset device
;  $FE = Perform media formatting
;
DControl:
          LDA CtlStat                ; Control command
          BEQ CReset
          JMP DCWhat                 ; Control code no good!
CReset:   GoSlow
          BIT ACIADR                 ; Clear ACIA Data register
          GoFast
DCDone:   RTS          
DCNoReset:
          LDA #XNORESET              ; Things went bad after reset
          JSR SysErr                 ; Return to SOS with error in A
DCWhat:   LDA #XCTLCODE              ; Control/status code no good
          JSR SysErr                 ; Return to SOS with error in A

DClose:
DOpen:
          CLC
          RTS
;
; D_INIT call processing - called at initialization
;
DInit:
          LDA #SIRLen
          LDX SIRAddr
          LDY SIRAddr+1
          JSR AllocSIR               ; Allocate the ACIA
          BCS NoACIA

          PHP
          SEI                        ; Disable system interrupts
          GoSlow                     ; Set up the communications environment
          LDA #$0b                   ; No parity, no interrupts
          STA ACIACMD                ; Store via ACIA command register
          LDA #$10                   ; $16=300, $1e=9600, $1f=19200, $10=115k
          STA ACIACTL                ; Store via ACIA control register
          LDA ACIASR                 ; Clear any prior ACIA interrupts
          GoFast
          PLP                        ; Re-enable system interrupt state

DInitDone:
          CLC
          RTS
NoACIA:
          LDA #XNORESRC
          JSR SysErr                 ; Return to SOS with error in A

;------------------------------------
;
; Utility routines
;
;------------------------------------


;
; SendEnvelope - send the command envelope
;
SendEnvelope:                        ; Send a command envelope
          LDA #$00
          STA Checksum 
          LDA #$c5                   ; "E"
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
; PUTCC - Put a byte to the ACIA, adding to the checksum
;
PUTCC:    PHA
          EOR Checksum
          STA Checksum
          JMP PUTC0
;
; PUTC - Put a byte to the ACIA
;
PUTC:
          PHA                        ; Push 'character to send' onto the stack
PUTC0:    LDA #$00
          STA Timer
          STA Timer+1
          GoSlow
PUTC1:
          LDA ACIASR                 ; Check status bits
          AND #$70
          CMP #$10
          BNE PUTC1                  ; Output register is full, no timeout; so loop
          PLA                        ; Pull 'character to send' back off the stack
          STA ACIADR                 ; Put character
          GoFast
          RTS

; Fix up the buffer pointer to correct for addressing
; anomalies.  We just need to do the initial checking
; for two cases:
; 00xx bank N -> 80xx bank N-1
; 20xx bank 8F if N was 0
; FDxx bank N -> 7Dxx bank N+1
; If pointer is adjusted, return with carry set
;
FixUp:    LDA DataBuf+1              ; Look at msb
          BEQ @1                     ; That's one!
          CMP #$FD                   ; Is it the other one?
          BCS @2                     ; Yep. fix it!
          RTS                        ; Pointer unchanged, return carry clear.
@1:       LDA #$80                   ; 00xx -> 80xx
          STA DataBuf+1
          DEC DataBuf+ExtPG          ; Bank N -> band N-1
          LDA DataBuf+ExtPG          ; See if it was bank 0
          CMP #$7F                   ; (80) before the DEC.
          BNE @3                     ; Nope! all fixed.
          LDA #$20                   ; If it was, change both
          STA DataBuf+1              ; Msb of address and
          LDA #$8F
          STA DataBuf+ExtPG          ; Bank number for bank 8F
          RTS                        ; Return carry set
@2:       AND #$7F                   ; Strip off high bit
          STA DataBuf+1              ; FDxx ->7Dxx
          INC DataBuf+ExtPG          ; Bank N -> bank N+1
@3:       RTS                        ; Return carry set

CkUnit:
          CLC
          RTS

         .ENDPROC
         .END
