; Configuration


	.export cfg_mac
;	.export cfg_ip
;	.export cfg_netmask
;	.export cfg_gateway
;	.export cfg_dns

	.segment "CODE"

cfg_mac:	.byte $00, $80, $10, $6d, $76, $30
;cfg_ip:		.byte 192, 168, 0, 64
;cfg_netmask:	.byte 255, 255, 255, 0
;cfg_gateway:	.byte 192, 168, 0, 1
;cfg_dns:	.byte 192, 168, 0, 1
