w5100_ptr  := $06         ; 2 byte pointer value
w5100_sha  := $08         ; 2 byte physical addr shadow ($F000-$FFFF)
w5100_adv  := $EB         ; 2 byte pointer register advancement
w5100_len  := $ED         ; 2 byte frame length
w5100_tmp  := $FA         ; 1 byte temporary value
w5100_bas  := $FB         ; 1 byte socket 1 Base Address (hibyte)

w5100_mode := $C0B4
w5100_addr := $C0B5
w5100_data := $C0B7

w5100_ip_parms := $7000 ; w5100 driver load address