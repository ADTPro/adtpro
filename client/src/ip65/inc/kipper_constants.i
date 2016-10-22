; constants for accessing the KPR API file
; to use this file under CA65 add ".define EQU =" to your code before this file is included.

KPR_API_VERSION_NUMBER EQU $01

KPR_CART_SIGNATURE             EQU $8009
KPR_DISPATCH_VECTOR            EQU $800f
KPR_PERIODIC_PROCESSING_VECTOR EQU $8012

; function numbers
; to make a function call:
; Y  EQU function number
; AX  EQU pointer to parameter buffer (for functions that take parameters)
; then JSR KPR_DISPATCH_VECTOR
; on return, carry flag is set if there is an error, or clear otherwise
; some functions return results in AX directly, others will update the parameter buffer they were called with.
; any register not specified in outputs will have an undefined value on exit

KPR_INITIALIZE             EQU $01 ; no inputs or outputs - initializes IP stack, also sets IRQ chain to call KPR_VBL_VECTOR at @ 60hz
KPR_GET_IP_CONFIG          EQU $02 ; no inputs, outputs AX=pointer to IP configuration structure
KPR_DEACTIVATE             EQU $0F ; inputs: none, outputs: none (removes call to KPR_VBL_VECTOR on IRQ chain)

KPR_UDP_ADD_LISTENER       EQU $10 ; inputs: AX points to a UDP listener parameter structure, outputs: none
KPR_GET_INPUT_PACKET_INFO  EQU $11 ; inputs: AX points to a UDP/TCP packet parameter structure, outputs: UDP/TCP packet structure filled in
KPR_SEND_UDP_PACKET        EQU $12 ; inputs: AX points to a UDP packet parameter structure, outputs: none packet is sent
KPR_UDP_REMOVE_LISTENER    EQU $13 ; inputs: AX contains UDP port number that listener will be removed from

KPR_TCP_CONNECT            EQU $14 ; inputs: AX points to a TCP connect parameter structure, outputs: none
KPR_SEND_TCP_PACKET        EQU $15 ; inputs: AX points to a TCP send parameter structure, outputs: none packet is sent
KPR_TCP_CLOSE_CONNECTION   EQU $16 ; inputs: none outputs: none

KPR_TFTP_SET_SERVER        EQU $20 ; inputs: AX points to a TFTP server parameter structure, outputs: none
KPR_TFTP_DOWNLOAD          EQU $22 ; inputs: AX points to a TFTP transfer parameter structure, outputs: TFTP param structure updated with
                                   ; KPR_TFTP_POINTER updated to reflect actual load address (if load address $0000 originally passed in)
KPR_TFTP_CALLBACK_DOWNLOAD EQU $23 ; inputs: AX points to a TFTP transfer parameter structure, outputs: none
KPR_TFTP_UPLOAD            EQU $24 ; upload: AX points to a TFTP transfer parameter structure, outputs: none
KPR_TFTP_CALLBACK_UPLOAD   EQU $25 ; upload: AX points to a TFTP transfer parameter structure, outputs: none

KPR_DNS_RESOLVE            EQU $30 ; inputs: AX points to a DNS parameter structure, outputs: DNS param structure updated with
                                   ; KPR_DNS_HOSTNAME_IP updated with IP address corresponding to hostname.
KPR_DOWNLOAD_RESOURCE      EQU $31 ; inputs: AX points to a URL download structure, outputs: none
KPR_PING_HOST              EQU $32 ; inputs: AX points to destination IP address for ping, outputs: AX=time (in milliseconds) to get response

KPR_FILE_LOAD              EQU $40 ; inputs: AX points to a file access parameter structure, outputs: none

KPR_HTTPD_START            EQU $50 ; inputs: AX points to a routine to call for each inbound request, outputs: none
KPR_HTTPD_GET_VAR_VALUE    EQU $52 ; inputs: A=variable to get value for ($01 to get method, $02 to get path)

KPR_PRINT_ASCIIZ           EQU $80 ; inputs: AX=pointer to null terminated string to be printed to screen, outputs: none
KPR_PRINT_HEX              EQU $81 ; inputs: A=byte digit to be displayed on screen as (zero padded) hex digit, outputs: none
KPR_PRINT_DOTTED_QUAD      EQU $82 ; inputs: AX=pointer to 4 bytes that will be displayed as a decimal dotted quad (e.g. 192.168.1.1)
KPR_PRINT_IP_CONFIG        EQU $83 ; no inputs, no outputs, prints to screen current IP configuration
KPR_PRINT_INTEGER          EQU $84 ; inputs: AX=16 byte number that will be printed as an unsigned decimal

KPR_INPUT_STRING           EQU $90 ; no inputs, outputs: AX = pointer to null terminated string
KPR_INPUT_HOSTNAME         EQU $91 ; no inputs, outputs: AX = pointer to hostname (which may be IP address).
KPR_INPUT_PORT_NUMBER      EQU $92 ; no inputs, outputs: AX = port number entered ($0000..$FFFF)

KPR_BLOCK_COPY             EQU $A0 ; inputs: AX points to a block copy structure, outputs: none
KPR_PARSER_INIT            EQU $A1 ; inputs: AX points to a null terminated string, outputs: none
KPR_PARSER_SKIP_NEXT       EQU $A2 ; inputs: AX points to a null terminated substring, outputs: AX points to
                                   ; previously loaded string that is just past the next occurance of substring

KPR_GET_LAST_ERROR         EQU $FF ; no inputs, outputs A  EQU error code (from last function that set the global error value, not necessarily the
                                   ; last function that was called)

; offsets in IP configuration structure (used by KPR_GET_IP_CONFIG)
KPR_CFG_MAC         EQU $00     ; 6 byte MAC address
KPR_CFG_IP          EQU $06     ; 4 byte local IP address (will be overwritten by DHCP)
KPR_CFG_NETMASK     EQU $0A     ; 4 byte local netmask (will be overwritten by DHCP)
KPR_CFG_GATEWAY     EQU $0E     ; 4 byte local gateway (will be overwritten by DHCP)
KPR_CFG_DNS_SERVER  EQU $12     ; 4 byte IP address of DNS server (will be overwritten by DHCP)
KPR_CFG_DHCP_SERVER EQU $16     ; 4 byte IP address of DHCP server (will only be set by DHCP initialisation)
KPR_DRIVER_NAME     EQU $1A     ; 2 byte pointer to name of driver

; offsets in TFTP transfer parameter structure (used by KPR_TFTP_DOWNLOAD, KPR_TFTP_CALLBACK_DOWNLOAD,  KPR_TFTP_UPLOAD, KPR_TFTP_CALLBACK_UPLOAD)
KPR_TFTP_FILENAME   EQU $00     ; 2 byte pointer to asciiz filename (or filemask)
KPR_TFTP_POINTER    EQU $02     ; 2 byte pointer to memory location data to be stored in OR address of callback function
KPR_TFTP_FILESIZE   EQU $04     ; 2 byte file length (filled in by KPR_TFTP_DOWNLOAD, must be passed in to KPR_TFTP_UPLOAD)

; offsets in TFTP Server parameter structure (used by KPR_TFTP_SET_SERVER)
KPR_TFTP_SERVER_IP  EQU $00     ; 4 byte IP address of TFTP server

; offsets in DNS parameter structure (used by KPR_DNS_RESOLVE)
KPR_DNS_HOSTNAME    EQU $00     ; 2 byte pointer to asciiz hostname to resolve (can also be a dotted quad string)
KPR_DNS_HOSTNAME_IP EQU $00     ; 4 byte IP address (filled in on succesful resolution of hostname)

; offsets in UDP listener parameter structure
KPR_UDP_LISTENER_PORT     EQU $00 ; 2 byte port number
KPR_UDP_LISTENER_CALLBACK EQU $02 ; 2 byte address of routine to call when UDP packet arrives for specified port

; offsets in block copy  parameter structure
KPR_BLOCK_SRC       EQU $00     ; 2 byte address of start of source block
KPR_BLOCK_DEST      EQU $02     ; 2 byte address of start of destination block
KPR_BLOCK_SIZE      EQU $04     ; 2 byte length of block to be copied (in bytes

; offsets in TCP connect parameter structure
KPR_TCP_REMOTE_IP   EQU $00     ; 4 byte IP address of remote host (0.0.0.0 means wait for inbound i.e. server mode)
KPR_TCP_PORT        EQU $04     ; 2 byte port number (to listen on, if ip address was 0.0.0.0, or connect to otherwise)
KPR_TCP_CALLBACK    EQU $06     ; 2 byte address of routine to be called whenever a new packet arrives

; offsets in TCP send parameter structure
KPR_TCP_PAYLOAD_LENGTH  EQU $00 ; 2 byte length of payload of packet (after all ethernet,IP,UDP/TCP headers)
KPR_TCP_PAYLOAD_POINTER EQU $02 ; 2 byte pointer to payload of packet (after all headers)


; offsets in TCP/UDP packet parameter structure
KPR_REMOTE_IP       EQU $00     ; 4 byte IP address of remote machine (src of inbound packets, dest of outbound packets)
KPR_REMOTE_PORT     EQU $04     ; 2 byte port number of remote machine (src of inbound packets, dest of outbound packets)
KPR_LOCAL_PORT      EQU $06     ; 2 byte port number of local machine (src of outbound packets, dest of inbound packets)
KPR_PAYLOAD_LENGTH  EQU $08     ; 2 byte length of payload of packet (after all ethernet,IP,UDP/TCP headers)
                                ; in a TCP connection, if the length is $FFFF, this actually means "end of connection"
KPR_PAYLOAD_POINTER EQU $0A     ; 2 byte pointer to payload of packet (after all headers)

; offsets in URL download structure
; inputs:
KPR_URL                        EQU $00 ; 2 byte pointer to null terminated URL (NB - must be ASCII not "native" string)
KPR_URL_DOWNLOAD_BUFFER        EQU $02 ; 2 byte pointer to buffer that resource specified by URL will be downloaded into
KPR_URL_DOWNLOAD_BUFFER_LENGTH EQU $04 ; 2 byte length of buffer (download will truncate when buffer is full)

; offsets in file access  parameter structure (used by KPR_FILE_LOAD)
KPR_FILE_ACCESS_FILENAME EQU $00 ; 2 byte pointer to asciiz filename (or filemask)
KPR_FILE_ACCESS_POINTER  EQU $02 ; 2 byte pointer to memory location data to be stored in OR address of callback function
KPR_FILE_ACCESS_FILESIZE EQU $04 ; 2 byte file length (filled in by KPR_FILE_ACCESS)
KPR_FILE_ACCESS_DEVICE   EQU $06 ; 1 byte device number (set to $00 to use last accessed device)

; error codes (as returned by KPR_GET_LAST_ERROR)
KPR_ERROR_PORT_IN_USE                   EQU $80
KPR_ERROR_TIMEOUT_ON_RECEIVE            EQU $81
KPR_ERROR_TRANSMIT_FAILED               EQU $82
KPR_ERROR_TRANSMISSION_REJECTED_BY_PEER EQU $83
KPR_ERROR_INPUT_TOO_LARGE               EQU $84
KPR_ERROR_DEVICE_FAILURE                EQU $85
KPR_ERROR_ABORTED_BY_USER               EQU $86
KPR_ERROR_LISTENER_NOT_AVAILABLE        EQU $87
KPR_ERROR_NO_SUCH_LISTENER              EQU $88
KPR_ERROR_CONNECTION_RESET_BY_PEER      EQU $89
KPR_ERROR_CONNECTION_CLOSED             EQU $8A
KPR_ERROR_TOO_MANY_ERRORS               EQU $8B
KPR_ERROR_FILE_ACCESS_FAILURE           EQU $90
KPR_ERROR_MALFORMED_URL                 EQU $A0
KPR_ERROR_DNS_LOOKUP_FAILED             EQU $A1
KPR_ERROR_OPTION_NOT_SUPPORTED          EQU $FE
KPR_ERROR_FUNCTION_NOT_SUPPORTED        EQU $FF



; -- LICENSE FOR kipper_constants.i --
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
