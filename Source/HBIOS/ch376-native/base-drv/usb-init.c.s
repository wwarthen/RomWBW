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
;source-doc/base-drv/usb-init.c:25: void _chnative_init(bool forced) {
; ---------------------------------
; Function _chnative_init
; ---------------------------------
__chnative_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/usb-init.c:26: memset(get_usb_work_area(), 0, sizeof(_usb_state));
	ld	hl,_x
	ld	(hl),0x00
	ld	e, l
	ld	d, h
	inc	de
	ld	bc,0x0068
	ldir
;source-doc/base-drv/usb-init.c:28: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:30: ch_cmd_reset_all();
	call	_ch_cmd_reset_all
;source-doc/base-drv/usb-init.c:32: delay_medium();
	call	_delay_medium
;source-doc/base-drv/usb-init.c:34: if (forced) {
	bit	0,(ix+4)
	jr	Z,l__chnative_init_00110
;source-doc/base-drv/usb-init.c:35: bool indicator = true;
	ld	(ix-1),0x01
;source-doc/base-drv/usb-init.c:36: print_string("\r\nCH376: *$");
	ld	hl,usb_init_str_0
	call	_print_string
;source-doc/base-drv/usb-init.c:37: while (!ch_probe()) {
l__chnative_init_00104:
	call	_ch_probe
	ld	a, l
	or	a
	jr	NZ,l__chnative_init_00106
;source-doc/base-drv/usb-init.c:38: if (indicator) {
	bit	0,(ix-1)
	jr	Z,l__chnative_init_00102
;source-doc/base-drv/usb-init.c:39: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:40: print_string("\b $");
	ld	hl,usb_init_str_1
	call	_print_string
	jr	l__chnative_init_00103
l__chnative_init_00102:
;source-doc/base-drv/usb-init.c:42: USB_MODULE_LEDS = 0x03;
	ld	a,0x03
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:43: print_string("\b*$");
	ld	hl,usb_init_str_2
	call	_print_string
l__chnative_init_00103:
;source-doc/base-drv/usb-init.c:46: delay_medium();
	call	_delay_medium
;source-doc/base-drv/usb-init.c:47: indicator = !indicator;
	ld	a,(ix-1)
	xor	0x01
	ld	(ix-1),a
	jr	l__chnative_init_00104
l__chnative_init_00106:
;source-doc/base-drv/usb-init.c:50: print_string("\bPRESENT (VER $");
	ld	hl,usb_init_str_3
	call	_print_string
	jr	l__chnative_init_00111
l__chnative_init_00110:
;source-doc/base-drv/usb-init.c:52: if (!ch_probe()) {
	call	_ch_probe
	ld	a, l
;source-doc/base-drv/usb-init.c:53: USB_MODULE_LEDS = 0x00;
	or	a
	jr	NZ,l__chnative_init_00108
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:54: print_string("\r\nCH376: NOT PRESENT$");
	ld	hl,usb_init_str_4
	call	_print_string
;source-doc/base-drv/usb-init.c:55: return;
	jr	l__chnative_init_00118
l__chnative_init_00108:
;source-doc/base-drv/usb-init.c:58: print_string("\r\nCH376: PRESENT (VER $");
	ld	hl,usb_init_str_5
	call	_print_string
l__chnative_init_00111:
;source-doc/base-drv/usb-init.c:61: USB_MODULE_LEDS = 0x01;
	ld	a,0x01
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:63: print_hex(ch_cmd_get_ic_version());
	call	_ch_cmd_get_ic_version
	call	_print_hex
;source-doc/base-drv/usb-init.c:64: print_string("); $");
	ld	hl,usb_init_str_6
	call	_print_string
;source-doc/base-drv/usb-init.c:66: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb-init.c:68: for (uint8_t i = 0; i < (forced ? 10 : 5); i++) {
	ld	c,0x00
l__chnative_init_00116:
	bit	0,(ix+4)
	jr	Z,l__chnative_init_00120
	ld	de,0x000a
	jr	l__chnative_init_00121
l__chnative_init_00120:
	ld	de,0x0005
l__chnative_init_00121:
	ld	b, c
	ld	l,0x00
	ld	a, b
	sub	e
	ld	a, l
	sbc	a, d
	jp	PO, l__chnative_init_00185
	xor	0x80
l__chnative_init_00185:
	jp	P, l__chnative_init_00114
;source-doc/base-drv/usb-init.c:69: const uint8_t r = ch_very_short_wait_int_and_get_();
	push	bc
	call	_ch_very_short_wait_int_and_get
	ld	a, l
	pop	bc
;source-doc/base-drv/usb-init.c:71: if (r == USB_INT_CONNECT) {
	sub	0x81
	jr	NZ,l__chnative_init_00117
;source-doc/base-drv/usb-init.c:72: print_string("USB: CONNECTED$");
	ld	hl,usb_init_str_7
	call	_print_string
;source-doc/base-drv/usb-init.c:74: enumerate_all_devices();
	call	_enumerate_all_devices
;source-doc/base-drv/usb-init.c:76: USB_MODULE_LEDS = 0x03;
	ld	a,0x03
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:77: return;
	jr	l__chnative_init_00118
l__chnative_init_00117:
;source-doc/base-drv/usb-init.c:68: for (uint8_t i = 0; i < (forced ? 10 : 5); i++) {
	inc	c
	jr	l__chnative_init_00116
l__chnative_init_00114:
;source-doc/base-drv/usb-init.c:81: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/usb-init.c:82: print_string("USB: DISCONNECTED$");
	ld	hl,usb_init_str_8
	call	_print_string
l__chnative_init_00118:
;source-doc/base-drv/usb-init.c:83: }
	inc	sp
	pop	ix
	ret
usb_init_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: *$"
	DEFB 0x00
usb_init_str_1:
	DEFB 0x08
	DEFM " $"
	DEFB 0x00
usb_init_str_2:
	DEFB 0x08
	DEFM "*$"
	DEFB 0x00
usb_init_str_3:
	DEFB 0x08
	DEFM "PRESENT (VER $"
	DEFB 0x00
usb_init_str_4:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: NOT PRESENT$"
	DEFB 0x00
usb_init_str_5:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: PRESENT (VER $"
	DEFB 0x00
usb_init_str_6:
	DEFM "); $"
	DEFB 0x00
usb_init_str_7:
	DEFM "USB: CONNECTED$"
	DEFB 0x00
usb_init_str_8:
	DEFM "USB: DISCONNECTED$"
	DEFB 0x00
;source-doc/base-drv/usb-init.c:85: void chnative_init_force(void) { _chnative_init(true); }
; ---------------------------------
; Function chnative_init_force
; ---------------------------------
_chnative_init_force:
	ld	a,0x01
	push	af
	inc	sp
	call	__chnative_init
	inc	sp
	ret
;source-doc/base-drv/usb-init.c:87: void chnative_init(void) { _chnative_init(false); }
; ---------------------------------
; Function chnative_init
; ---------------------------------
_chnative_init:
	xor	a
	push	af
	inc	sp
	call	__chnative_init
	inc	sp
	ret
