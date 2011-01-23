
 .import dns_ip
 .import dns_resolve
 .import dns_set_hostname
.import cfg_default_drive
.bss
  temp_ax: .res 2
.code

configuration_menu:  
  jsr cls  
@show_config_menu:
  ldax  #menu_header_msg
  jsr print_ascii_as_native
  ldax  #config_menu_msg
  jsr print_ascii_as_native
  jsr print_ip_config
  jsr print_default_drive
  jsr print_cr
@get_key_config_menu:  
  jsr get_key_ip65
  cmp #KEYCODE_ABORT
  bne @not_abort
  rts
@not_abort:  
  cmp #KEYCODE_F1
  bne @not_ip
  ldax #new
  jsr print_ascii_as_native
  ldax #ip_address_msg
  jsr print_ascii_as_native
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_ip_address_entered
  jsr parse_dotted_quad  
  bcc @no_ip_resolve_error  
  jmp configuration_menu
@no_ip_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_ip
  stax copy_dest
  ldax #4
  jsr copymem
@no_ip_address_entered:  
  jmp configuration_menu
  
@not_ip:
  cmp #KEYCODE_F2
  bne @not_netmask
  ldax #new
  jsr print_ascii_as_native
  ldax #netmask_msg
  jsr print_ascii_as_native
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_netmask_entered
  jsr parse_dotted_quad  
  bcc @no_netmask_resolve_error  
  jmp configuration_menu
@no_netmask_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_netmask
  stax copy_dest
  ldax #4
  jsr copymem
@no_netmask_entered:  
  jmp configuration_menu
  
@not_netmask:
  cmp #KEYCODE_F3
  bne @not_gateway
  ldax #new
  jsr print_ascii_as_native
  ldax #gateway_msg
  jsr print_ascii_as_native
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_gateway_entered
  jsr parse_dotted_quad  
  bcc @no_gateway_resolve_error  
  jmp configuration_menu
@no_gateway_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_gateway
  stax copy_dest
  ldax #4
  jsr copymem
  jsr arp_calculate_gateway_mask                ;we have modified our netmask, so we need to recalculate gw_test
@no_gateway_entered:  
  jmp configuration_menu
  
  
@not_gateway:
  cmp #KEYCODE_F4
  bne @not_dns_server
  ldax #new
  jsr print_ascii_as_native
  ldax #dns_server_msg
  jsr print_ascii_as_native
  jsr print_cr
  ldax #filter_ip
  ldy #20
  jsr get_filtered_input
  bcs @no_dns_server_entered
  jsr parse_dotted_quad  
  bcc @no_dns_resolve_error  
  jmp configuration_menu
@no_dns_resolve_error:  
  ldax #dotted_quad_value
  stax copy_src
  ldax #cfg_dns
  stax copy_dest
  ldax #4
  jsr copymem
@no_dns_server_entered:  
  
  jmp configuration_menu
  
@not_dns_server:
  cmp #KEYCODE_F5
  bne @not_tftp_server
  ldax #new
  jsr print_ascii_as_native
  ldax #tftp_server_msg
  jsr print_ascii_as_native
  jsr print_cr
  ldax #filter_dns
  ldy #40
  jsr get_filtered_input
  bcs @no_server_entered
  stax temp_ax
  jsr print_cr  
  ldax #resolving
  jsr print_ascii_as_native
  ldax temp_ax
  jsr dns_set_hostname 
  bcs @resolve_error  
  jsr dns_resolve
  bcs @resolve_error  

  ldax #dns_ip
  stax copy_src
  ldax #cfg_tftp_server
  stax copy_dest
  ldax #4
  jsr copymem
@no_server_entered:  
  jmp configuration_menu
  
@not_tftp_server:


cmp #KEYCODE_F6
  bne @not_reset
  jsr ip65_init ;this will reset everything
  jmp configuration_menu
@not_reset:  
cmp #KEYCODE_F7
  bne @not_main_menu
  jmp main_menu
  
@not_main_menu:

cmp #'+'
  bne @not_plus
  inc cfg_default_drive
  jmp @show_config_menu
@not_plus:

cmp #'-'
  bne @not_minus
  dec cfg_default_drive
  jmp @show_config_menu
  
@not_minus:

  jmp @get_key_config_menu
    
@resolve_error:
  print_failed
  jsr wait_for_keypress
  jmp configuration_menu


print_default_drive:
  ldax #default_drive
	jsr print_ascii_as_native
  lda cfg_default_drive
  jsr print_hex
  jmp print_cr

.rodata

config_menu_msg:
.byte 10,"Configuration",10,10
.byte "F1: IP Address  F2: Netmask",10
.byte "F3: Gateway     F4: DNS Server",10
.byte "F5: TFTP Server F6: Reset To Default",10
.byte "F7: Main Menu   +/- Drive #",10,10
.byte 0

default_drive:
.byte "Use Drive # : $",0
