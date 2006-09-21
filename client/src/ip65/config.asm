; Configuration


;	.export cfg_mac
;	.export cfg_ip
;	.export cfg_netmask
;	.export cfg_gateway
;	.export cfg_dns


;	.data	; should be bss
cfg_mac:	.byte $00, $80, $10, $6d, $76, $30

cfg_ip:		.byte 192, 168, 0, 123
cfg_netmask:	.byte 255, 255, 248, 0
cfg_gateway:	.byte 192, 168, 0, 1
cfg_dns:	.byte 192, 168, 0, 1
