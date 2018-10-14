;
; Stackmods - any time a tx or rx request is made in the stack,
; this module should be fixing up the calling address to point
; to the correct tx or rx code in the driver in use.  So, each
; driver should be making a call to fix_eth_tx and fix_eth_rx
; upon its initialization.
;

.include "../inc/common.i"

	.global fix_eth_tx
	.export fix_eth_rx

	.import fix_eth_tx_00	; from ip.s
	.import fix_eth_tx_01	; from icmp.s
	.import fix_eth_tx_02	; from arp.s
	.import fix_eth_tx_03	; from arp.s

	.import fix_eth_rx_00	; from ip65.s

	.code
;
; fix_eth_tx - Fix up the stack to point to a driver's entry points
; Inputs: A/X hold low/high addresses of transmit address 
;
fix_eth_tx:
	sta fix_eth_tx_00 +1
	stx fix_eth_tx_00 +2
	sta fix_eth_tx_01 +1
	stx fix_eth_tx_01 +2
	sta fix_eth_tx_02 +1
	stx fix_eth_tx_02 +2
	sta fix_eth_tx_03 +1
	stx fix_eth_tx_03 +2
	rts

;
; fix_eth_rx - Fix up the stack to point to a driver's entry points
; Inputs: A/X hold low/high addresses of receive address 
;
fix_eth_rx:
	sta fix_eth_rx_00 + 1
	stx fix_eth_rx_00 + 2
	rts