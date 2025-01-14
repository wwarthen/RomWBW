;
; Generated from source-doc/base-drv/usb-init.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.4.0 #14648 (Linux)
;--------------------------------------------------------
; Processed by Z88DK
;--------------------------------------------------------
	

;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
;--------------------------------------------------------
; Externals used
;--------------------------------------------------------
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
_CH376_DATA_PORT	.EQU	0xff88
_CH376_COMMAND_PORT	.EQU	0xff89
_USB_MODULE_LEDS	.EQU	0xff8a
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
#IF 0
	
; .area _INITIALIZED removed by z88dk
	
	
#ENDIF
	
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
;--------------------------------------------------------
; Home
;--------------------------------------------------------
;--------------------------------------------------------
; code
;--------------------------------------------------------
;source-doc/base-drv/usb-init.c:8: static usb_error usb_host_bus_reset(void) {
; ---------------------------------
; Function usb_host_bus_reset
; ---------------------------------
_usb_host_bus_reset:
;source-doc/base-drv/usb-init.c:9: ch_cmd_set_usb_mode(CH_MODE_HOST);
	ld	l,0x06
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb-init.c:10: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/usb-init.c:12: ch_cmd_set_usb_mode(CH_MODE_HOST_RESET);
	ld	l,0x07
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb-init.c:13: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/usb-init.c:15: ch_cmd_set_usb_mode(CH_MODE_HOST);
	ld	l,0x06
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb-init.c:16: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/ch376.h:110: #endif
	ld	l,0x0b
	call	_ch_command
;source-doc/base-drv/ch376.h:111:
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/ch376.h:112: #define calc_max_packet_sizex(packet_size) (packet_size & 0x3FF)
	ld	a,0xdf
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/usb-init.c:20: return USB_ERR_OK;
	ld	l,0x00
;source-doc/base-drv/usb-init.c:21: }
	ret
;source-doc/base-drv/usb-init.c:25: void chnative_init(void) {
; ---------------------------------
; Function chnative_init
; ---------------------------------
_chnative_init:
;source-doc/base-drv/usb-init.c:26: memset(get_usb_work_area(), 0, sizeof(_usb_state));
	ld	hl,_x
	ld	(hl),0x00
	ld	e, l
	ld	d, h
	inc	de
	ld	bc,0x0068
	ldir
;source-doc/base-drv/usb-init.c:28: ch_cmd_reset_all();
	call	_ch_cmd_reset_all
;source-doc/base-drv/usb-init.c:30: delay_medium();
	call	_delay_medium
;source-doc/base-drv/usb-init.c:32: if (!ch_probe()) {
	call	_ch_probe
	ld	a, l
	or	a
	jr	NZ,l_chnative_init_00102
;source-doc/base-drv/usb-init.c:33: print_string("\r\nCH376: NOT PRESENT$");
;source-doc/base-drv/usb-init.c:34: return;
	ld	hl,usb_init_str_0
	jp	_print_string
l_chnative_init_00102:
;source-doc/base-drv/usb-init.c:37: print_string("\r\nCH376: PRESENT (VER $");
	ld	hl,usb_init_str_1
	call	_print_string
;source-doc/base-drv/usb-init.c:38: print_hex(ch_cmd_get_ic_version());
	call	_ch_cmd_get_ic_version
	call	_print_hex
;source-doc/base-drv/usb-init.c:39: print_string("); $");
	ld	hl,usb_init_str_2
	call	_print_string
;source-doc/base-drv/usb-init.c:41: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb-init.c:43: for (uint8_t i = 0; i < 4; i++) {
	ld	c,0x00
l_chnative_init_00107:
	ld	a, c
	sub	0x04
	jr	NC,l_chnative_init_00105
;source-doc/base-drv/usb-init.c:44: const uint8_t r = ch_very_short_wait_int_and_get_();
	push	bc
	call	_ch_very_short_wait_int_and_get
	ld	a, l
	pop	bc
;source-doc/base-drv/usb-init.c:46: if (r == USB_INT_CONNECT) {
	sub	0x81
	jr	NZ,l_chnative_init_00108
;source-doc/base-drv/usb-init.c:47: print_string("USB: CONNECTED$");
	ld	hl,usb_init_str_3
	call	_print_string
;source-doc/base-drv/usb-init.c:49: enumerate_all_devices();
	jp	_enumerate_all_devices
;source-doc/base-drv/usb-init.c:51: return;
	jr	l_chnative_init_00109
l_chnative_init_00108:
;source-doc/base-drv/usb-init.c:43: for (uint8_t i = 0; i < 4; i++) {
	inc	c
	jr	l_chnative_init_00107
l_chnative_init_00105:
;source-doc/base-drv/usb-init.c:55: print_string("USB: DISCONNECTED$");
	ld	hl,usb_init_str_4
	jp	_print_string
l_chnative_init_00109:
;source-doc/base-drv/usb-init.c:56: }
	ret
usb_init_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: NOT PRESENT$"
	DEFB 0x00
usb_init_str_1:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: PRESENT (VER $"
	DEFB 0x00
usb_init_str_2:
	DEFM "); $"
	DEFB 0x00
usb_init_str_3:
	DEFM "USB: CONNECTED$"
	DEFB 0x00
usb_init_str_4:
	DEFM "USB: DISCONNECTED$"
	DEFB 0x00
