; Common Registers
W5100_MR = $0000 ; Mode Register

W5100_GAR0 = $0001 ; Gateway Address Byte 0
W5100_GAR1 = $0002 ; Gateway Address Byte 1
W5100_GAR2 = $0003 ; Gateway Address Byte 2
W5100_GAR3 = $0004 ; Gateway Address Byte 3

W5100_SUBR0 = $0005 ; Subnet Mask Address 0
W5100_SUBR1 = $0006 ; Subnet Mask Address 1
W5100_SUBR2 = $0007 ; Subnet Mask Address 2
W5100_SUBR3 = $0008 ; Subnet Mask Address 3

W5100_SHAR0 = $0009 ; Local MAC Address 0
W5100_SHAR1 = $000A ; Local MAC Address 1
W5100_SHAR2 = $000B ; Local MAC Address 2
W5100_SHAR3 = $000C ; Local MAC Address 3
W5100_SHAR4 = $000D ; Local MAC Address 4
W5100_SHAR5 = $000E ; Local MAC Address 5

W5100_SIPR0 = $000F ; Source IP Address 0
W5100_SIPR1 = $0010 ; Source IP Address 0
W5100_SIPR2 = $0011 ; Source IP Address 0
W5100_SIPR3 = $0012 ; Source IP Address 0

W5100_IR = $0015 ; Interrupt
W5100_IMR = $0016 ; Interrupt Mask

W5100_RTR0 = $0017 ; Retry Time High Byte
W5100_RTR1 = $0018 ; Retry Time Low Byte

W5100_RCR = $0019 ; Retry Count

W5100_RMSR = $001A ; RX Memory Size (per socket)
W5100_TMSR = $001B ; TX Memory Size (per socket)

W5100_PATR0 = $001C ; PPPoE Auth Type High
W5100_PART1 = $001D ; PPPoE Auth Type Low

W5100_PTIMER = $0028 ; PPP LCP Request Timer
W5100_PMAGIC = $0029 ; PPP LCP Magic Number

W5100_UIPR0 = $002A ; Unreachable IP Address 0
W5100_UIPR1 = $002B ; Unreachable IP Address 1
W5100_UIPR2 = $002C ; Unreachable IP Address 2
W5100_UIPR3 = $002D ; Unreachable IP Address 3

W5100_UPORT0 = $002E ; Unreachable Port High
W5100_UPORT1 = $002F ; Unreachable Port Low

; Socket Registers
W5100_S0_BASE = $0400 ; Base for socket 0
W5100_S0_MR = $0400 ; Socket 0 Mode
W5100_S0_CR = $0401 ; Socket 0 Command
W5100_S0_IR = $0402 ; Socket 0 Interrupt
W5100_S0_SR = $0403 ; Socket 0 Status
W5100_S0_PORT0 = $0404 ; Socket 0 Source Port High
W5100_S0_PORT1 = $0405 ; Socket 0 Source Port Low
W5100_S0_DHAR0 = $0406 ; Socket 0 Dest Mac 0
W5100_S0_DHAR1 = $0407 ; Socket 0 Dest Mac 1
W5100_S0_DHAR2 = $0408 ; Socket 0 Dest Mac 2
W5100_S0_DHAR3 = $0409 ; Socket 0 Dest Mac 3
W5100_S0_DHAR4 = $040A ; Socket 0 Dest Mac 4
W5100_S0_DHAR5 = $040B ; Socket 0 Dest Mac 5
W5100_S0_DIPR0 = $040C ; Socket 0 Dest IP 0
W5100_S0_DIPR1 = $040D ; Socket 0 Dest IP 1
W5100_S0_DIPR2 = $040E ; Socket 0 Dest IP 2
W5100_S0_DIPR3 = $040F ; Socket 0 Dest IP 3
W5100_S0_DPORT0 = $0410 ; Socket 0 Dest Port High
W5100_S0_DPORT1 = $0411 ; Socket 0 Dest Port Low
W5100_S0_MSSR0 = $0412 ; Socket 0 Max Segment High
W5100_S0_MSSR1 = $0413 ; Socket 0 Max Segment Low
W5100_S0_PROTO = $0414 ; Socket 0 Protocol (Raw Mode)
W5100_S0_TOS = $0415 ; Socket 0 IP TOS
W5100_S0_TTL = $0416 ; Socket 0 IP TTL
W5100_S0_TX_FSR0 = $0420 ; Socket 0 TX Free Size High
W5100_S0_TX_FSR1 = $0421 ; Socket 0 TX Free Size Low
W5100_S0_TX_RD0 = $0422 ; Socket 0 TX Read Pointer High
W5100_S0_TX_RD1 = $0423 ; Socket 0 TX Read Pointer Low
W5100_S0_TX_WR0 = $0424 ; Socket 0 TX Write Pointer High
W5100_S0_TX_WR1 = $0425 ; Socket 0 TX Write Pointer Low
W5100_S0_RX_RSR0 = $0426 ; Socket 0 RX Received Size High
W5100_S0_RX_RSR1 = $0427 ; Socket 0 RX Received Size Low
W5100_S0_RX_RD0 = $0428 ; Socket 0 RX Read Pointer High
W5100_S0_RX_RD1 = $0429 ; Socket 0 RX Read Pointer Low

W5100_S1_BASE = $0500 ; Base for socket 1
W5100_S1_MR = $0500 ; Socket 1 Mode
W5100_S1_CR = $0501 ; Socket 1 Command
W5100_S1_IR = $0502 ; Socket 1 Interrupt
W5100_S1_SR = $0503 ; Socket 1 Status
W5100_S1_PORT0 = $0504 ; Socket 1 Source Port High
W5100_S1_PORT1 = $0505 ; Socket 1 Source Port Low
W5100_S1_DHAR0 = $0506 ; Socket 1 Dest Mac 0
W5100_S1_DHAR1 = $0507 ; Socket 1 Dest Mac 1
W5100_S1_DHAR2 = $0508 ; Socket 1 Dest Mac 2
W5100_S1_DHAR3 = $0509 ; Socket 1 Dest Mac 3
W5100_S1_DHAR4 = $050A ; Socket 1 Dest Mac 4
W5100_S1_DHAR5 = $050B ; Socket 1 Dest Mac 5
W5100_S1_DIPR0 = $050C ; Socket 1 Dest IP 0
W5100_S1_DIPR1 = $050D ; Socket 1 Dest IP 1
W5100_S1_DIPR2 = $050E ; Socket 1 Dest IP 2
W5100_S1_DIPR3 = $050F ; Socket 1 Dest IP 3
W5100_S1_DPORT0 = $0510 ; Socket 1 Dest Port High
W5100_S1_DPORT1 = $0511 ; Socket 1 Dest Port Low
W5100_S1_MSSR0 = $0512 ; Socket 1 Max Segment High
W5100_S1_MSSR1 = $0513 ; Socket 1 Max Segment Low
W5100_S1_PROTO = $0514 ; Socket 1 Protocol (Raw Mode)
W5100_S1_TOS = $0515 ; Socket 1 IP TOS
W5100_S1_TTL = $0516 ; Socket 1 IP TTL
W5100_S1_TX_FSR0 = $0520 ; Socket 1 TX Free Size High
W5100_S1_TX_FSR1 = $0521 ; Socket 1 TX Free Size Low
W5100_S1_TX_RD0 = $0522 ; Socket 1 TX Read Pointer High
W5100_S1_TX_RD1 = $0523 ; Socket 1 TX Read Pointer Low
W5100_S1_TX_WR0 = $0524 ; Socket 1 TX Write Pointer High
W5100_S1_TX_WR1 = $0525 ; Socket 1 TX Write Pointer Low
W5100_S1_RX_RSR0 = $0526 ; Socket 1 RX Received Size High
W5100_S1_RX_RSR1 = $0527 ; Socket 1 RX Received Size Low
W5100_S1_RX_RD0 = $0528 ; Socket 1 RX Read Pointer High
W5100_S1_RX_RD1 = $0529 ; Socket 1 RX Read Pointer Low

W5100_S2_BASE = $0600 ; Base for socket 2
W5100_S2_MR = $0600 ; Socket 2 Mode
W5100_S2_CR = $0601 ; Socket 2 Command
W5100_S2_IR = $0602 ; Socket 2 Interrupt
W5100_S2_SR = $0603 ; Socket 2 Status
W5100_S2_PORT0 = $0604 ; Socket 2 Source Port High
W5100_S2_PORT1 = $0605 ; Socket 2 Source Port Low
W5100_S2_DHAR0 = $0606 ; Socket 2 Dest Mac 0
W5100_S2_DHAR1 = $0607 ; Socket 2 Dest Mac 1
W5100_S2_DHAR2 = $0608 ; Socket 2 Dest Mac 2
W5100_S2_DHAR3 = $0609 ; Socket 2 Dest Mac 3
W5100_S2_DHAR4 = $060A ; Socket 2 Dest Mac 4
W5100_S2_DHAR5 = $060B ; Socket 2 Dest Mac 5
W5100_S2_DIPR0 = $060C ; Socket 2 Dest IP 0
W5100_S2_DIPR1 = $060D ; Socket 2 Dest IP 1
W5100_S2_DIPR2 = $060E ; Socket 2 Dest IP 2
W5100_S2_DIPR3 = $060F ; Socket 2 Dest IP 3
W5100_S2_DPORT0 = $0610 ; Socket 2 Dest Port High
W5100_S2_DPORT1 = $0611 ; Socket 2 Dest Port Low
W5100_S2_MSSR0 = $0612 ; Socket 2 Max Segment High
W5100_S2_MSSR1 = $0613 ; Socket 2 Max Segment Low
W5100_S2_PROTO = $0614 ; Socket 2 Protocol (Raw Mode)
W5100_S2_TOS = $0615 ; Socket 2 IP TOS
W5100_S2_TTL = $0616 ; Socket 2 IP TTL
W5100_S2_TX_FSR0 = $0620 ; Socket 2 TX Free Size High
W5100_S2_TX_FSR1 = $0621 ; Socket 2 TX Free Size Low
W5100_S2_TX_RD0 = $0622 ; Socket 2 TX Read Pointer High
W5100_S2_TX_RD1 = $0623 ; Socket 2 TX Read Pointer Low
W5100_S2_TX_WR0 = $0624 ; Socket 2 TX Write Pointer High
W5100_S2_TX_WR1 = $0625 ; Socket 2 TX Write Pointer Low
W5100_S2_RX_RSR0 = $0626 ; Socket 2 RX Received Size High
W5100_S2_RX_RSR1 = $0627 ; Socket 2 RX Received Size Low
W5100_S2_RX_RD0 = $0628 ; Socket 2 RX Read Pointer High
W5100_S2_RX_RD1 = $0629 ; Socket 2 RX Read Pointer Low

W5100_S3_BASE = $0700 ; Base for socket 3
W5100_S3_MR = $0700 ; Socket 3 Mode
W5100_S3_CR = $0701 ; Socket 3 Command
W5100_S3_IR = $0702 ; Socket 3 Interrupt
W5100_S3_SR = $0703 ; Socket 3 Status
W5100_S3_PORT0 = $0704 ; Socket 3 Source Port High
W5100_S3_PORT1 = $0705 ; Socket 3 Source Port Low
W5100_S3_DHAR0 = $0706 ; Socket 3 Dest Mac 0
W5100_S3_DHAR1 = $0707 ; Socket 3 Dest Mac 1
W5100_S3_DHAR2 = $0708 ; Socket 3 Dest Mac 2
W5100_S3_DHAR3 = $0709 ; Socket 3 Dest Mac 3
W5100_S3_DHAR4 = $070A ; Socket 3 Dest Mac 4
W5100_S3_DHAR5 = $070B ; Socket 3 Dest Mac 5
W5100_S3_DIPR0 = $070C ; Socket 3 Dest IP 0
W5100_S3_DIPR1 = $070D ; Socket 3 Dest IP 1
W5100_S3_DIPR2 = $070E ; Socket 3 Dest IP 2
W5100_S3_DIPR3 = $070F ; Socket 3 Dest IP 3
W5100_S3_DPORT0 = $0710 ; Socket 3 Dest Port High
W5100_S3_DPORT1 = $0711 ; Socket 3 Dest Port Low
W5100_S3_MSSR0 = $0712 ; Socket 3 Max Segment High
W5100_S3_MSSR1 = $0713 ; Socket 3 Max Segment Low
W5100_S3_PROTO = $0714 ; Socket 3 Protocol (Raw Mode)
W5100_S3_TOS = $0715 ; Socket 3 IP TOS
W5100_S3_TTL = $0716 ; Socket 3 IP TTL
W5100_S3_TX_FSR0 = $0720 ; Socket 3 TX Free Size High
W5100_S3_TX_FSR1 = $0721 ; Socket 3 TX Free Size Low
W5100_S3_TX_RD0 = $0722 ; Socket 3 TX Read Pointer High
W5100_S3_TX_RD1 = $0723 ; Socket 3 TX Read Pointer Low
W5100_S3_TX_WR0 = $0724 ; Socket 3 TX Write Pointer High
W5100_S3_TX_WR1 = $0725 ; Socket 3 TX Write Pointer Low
W5100_S3_RX_RSR0 = $0726 ; Socket 3 RX Received Size High
W5100_S3_RX_RSR1 = $0727 ; Socket 3 RX Received Size Low
W5100_S3_RX_RD0 = $0728 ; Socket 3 RX Read Pointer High
W5100_S3_RX_RD1 = $0729 ; Socket 3 RX Read Pointer Low

; Commands
W5100_CMD_OPEN = $01
W5100_CMD_LISTEN = $02
W5100_CMD_CONNECT = $04
W5100_CMD_DISCONNECT = $08
W5100_CMD_CLOSE = $10
W5100_CMD_SEND = $20
W5100_CMD_SEND_MAC = $21
W5100_CMD_SEND_KEEP = $22
W5100_CMD_RECV = $40

; Modes
W5100_MODE_CLOSED = $00
W5100_MODE_TCP = $01
W5100_MODE_UDP = $02
W5100_MODE_IP_RAW = $03
W5100_MODE_MAC_RAW = $04
W5100_MODE_PPPOE = $05

; Status
W5100_STATUS_SOCK_CLOSED = $00
W5100_STATUS_SOCK_INIT = $13
W5100_STATUS_SOCK_LISTEN = $14
W5100_STATUS_SOCK_SYNSENT = $15
W5100_STATUS_SOCK_SYNRECV = $16
W5100_STATUS_SOCK_ESTABLISHED = $17
W5100_STATUS_SOCK_FIN_WAIT = $18
W5100_STATUS_SOCK_CLOSING = $1A
W5100_STATUS_SOCK_TIME_WAIT = $1B
W5100_STATUS_SOCK_CLOSE_WAIT = $1C
W5100_STATUS_SOCK_LAST_ACK = $1D
W5100_STATUS_SOCK_UDP = $22
W5100_STATUS_SOCK_IPRAW = $32
W5100_STATUS_SOCK_MACRAW = $42
W5100_STATUS_SOCK_PPPOE = $5F