;
; Generated from source-doc/base-drv/usb_init.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.5.0 #15248 (Linux)
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
;source-doc/base-drv/usb_init.c:7: static usb_error usb_host_bus_reset(void) {
; ---------------------------------
; Function usb_host_bus_reset
; ---------------------------------
_usb_host_bus_reset:
;source-doc/base-drv/usb_init.c:8: ch_cmd_set_usb_mode(CH_MODE_HOST);
	ld	l,0x06
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb_init.c:9: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/usb_init.c:11: ch_cmd_set_usb_mode(CH_MODE_HOST_RESET);
	ld	l,0x07
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb_init.c:12: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/usb_init.c:14: ch_cmd_set_usb_mode(CH_MODE_HOST);
	ld	l,0x06
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb_init.c:15: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/ch376.h:110: #endif
	ld	l,0x0b
	call	_ch_command
;source-doc/base-drv/ch376.h:111:
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.h:112: #define calc_max_packet_sizex(packet_size) (packet_size & 0x3FF)
	ld	a,0xdf
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/usb_init.c:19: return USB_ERR_OK;
	ld	l,0x00
;source-doc/base-drv/usb_init.c:20: }
	ret
;source-doc/base-drv/usb_init.c:24: uint16_t usb_init(uint8_t state) __z88dk_fastcall {
; ---------------------------------
; Function usb_init
; ---------------------------------
_usb_init:
;source-doc/base-drv/usb_init.c:27: USB_MODULE_LEDS = 0x03;
	ld	a,0x03
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb_init.c:29: if (state == 0) {
	ld	a, l
	or	a
	jr	NZ,l_usb_init_00104
;source-doc/base-drv/usb_init.c:30: ch_cmd_reset_all();
	call	_ch_cmd_reset_all
;source-doc/base-drv/usb_init.c:31: delay_medium();
	call	_delay_medium
;source-doc/base-drv/usb_init.c:33: if (!ch_probe()) {
	call	_ch_probe
	ld	a, l
;source-doc/base-drv/usb_init.c:34: USB_MODULE_LEDS = 0x00;
	or	a
	jr	NZ,l_usb_init_00102
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb_init.c:35: return 0xFF00;
	ld	hl,0xff00
	jp	l_usb_init_00113
l_usb_init_00102:
;source-doc/base-drv/usb_init.c:37: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb_init.c:38: return 1;
	ld	hl,0x0001
	jr	l_usb_init_00113
l_usb_init_00104:
;source-doc/base-drv/usb_init.c:41: if (state == 1) {
	ld	a, l
	dec	a
	jr	NZ,l_usb_init_00106
;source-doc/base-drv/usb_init.c:42: r = ch_cmd_get_ic_version();
	call	_ch_cmd_get_ic_version
;source-doc/base-drv/usb_init.c:44: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb_init.c:45: return (uint16_t)r << 8 | 2;
	xor	a
	ld	h, l
	ld	l,0x02
	jr	l_usb_init_00113
l_usb_init_00106:
;source-doc/base-drv/usb_init.c:48: if (state == 2) {
	ld	a, l
	sub	0x02
	jr	NZ,l_usb_init_00159
	ld	a,0x01
	jr	l_usb_init_00160
l_usb_init_00159:
	xor	a
l_usb_init_00160:
	ld	c,a
	or	a
	jr	Z,l_usb_init_00110
;source-doc/base-drv/usb_init.c:49: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb_init.c:51: r = ch_very_short_wait_int_and_get_();
	call	_ch_very_short_wait_int_and_get
	ld	a, l
;source-doc/base-drv/usb_init.c:53: if (r != USB_INT_CONNECT) {
	sub	0x81
	jr	Z,l_usb_init_00108
;source-doc/base-drv/usb_init.c:54: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb_init.c:55: return 2;
	ld	hl,0x0002
	jr	l_usb_init_00113
l_usb_init_00108:
;source-doc/base-drv/usb_init.c:58: return 3;
	ld	hl,0x0003
	jr	l_usb_init_00113
l_usb_init_00110:
;source-doc/base-drv/usb_init.c:61: memset(get_usb_work_area(), 0, sizeof(_usb_state));
	ld	b,0x32
	ld	hl,_x
	jr	l_usb_init_00163
l_usb_init_00162:
	ld	(hl),0x00
	inc	hl
l_usb_init_00163:
	ld	(hl),0x00
	inc	hl
	djnz	l_usb_init_00162
;source-doc/base-drv/usb_init.c:62: if (state != 2) {
	bit	0, c
	jr	NZ,l_usb_init_00112
;source-doc/base-drv/usb_init.c:63: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb_init.c:64: delay_medium();
	call	_delay_medium
l_usb_init_00112:
;source-doc/base-drv/usb_init.c:66: enumerate_all_devices();
	call	_enumerate_all_devices
;source-doc/base-drv/usb_init.c:67: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb_init.c:68: return (uint16_t)count_of_devices() << 8 | 4;
	call	_count_of_devices
	ld	h, a
	xor	a
	ld	l,0x04
l_usb_init_00113:
;source-doc/base-drv/usb_init.c:69: }
	ret
