; Uthernet driver

	.export cs_packet_page
	.export cs_packet_data
	.export cs_rxtx_data
	.export cs_tx_cmd
	.export cs_tx_len
  
cs_rxtx_data	= $c0b0 ;address of 'receive/transmit data' port on Uthernet
cs_tx_cmd	= $c0b4;address of 'transmit command' port on Uthernet
cs_tx_len	= $c0b6;address of 'transmission length' port on Uthernet
cs_packet_page	= $c0ba;address of 'packet page' port on Uthernet
cs_packet_data	= $c0bc;address of 'packet data' port on Uthernet

	.code

;-- LICENSE FOR uthernet.s --
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
