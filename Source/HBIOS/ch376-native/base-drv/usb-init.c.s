;
; Generated from source-doc/base-drv/usb-init.c.asm -- not to be modify directly
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
	out	(c), a
;source-doc/base-drv/ch376.h:112: #define calc_max_packet_sizex(packet_size) (packet_size & 0x3FF)
	ld	a,0xdf
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/usb-init.c:20: return USB_ERR_OK;
	ld	l,0x00
;source-doc/base-drv/usb-init.c:21: }
	ret
;source-doc/base-drv/usb-init.c:25: uint16_t ch376_init(uint8_t state) {
; ---------------------------------
; Function ch376_init
; ---------------------------------
_ch376_init:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/usb-init.c:28: USB_MODULE_LEDS = 0x03;
	ld	a,0x03
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-init.c:30: if (state == 0) {
	ld	a,(ix+4)
	or	a
	jr	NZ,l_ch376_init_00104
;source-doc/base-drv/usb-init.c:31: ch_cmd_reset_all();
	call	_ch_cmd_reset_all
;source-doc/base-drv/usb-init.c:32: delay_medium();
	call	_delay_medium
;source-doc/base-drv/usb-init.c:34: if (!ch_probe()) {
	call	_ch_probe
	ld	a, l
;source-doc/base-drv/usb-init.c:35: USB_MODULE_LEDS = 0x00;
	or	a
	jr	NZ,l_ch376_init_00102
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-init.c:36: return 0xFF00;
	ld	hl,0xff00
	jp	l_ch376_init_00113
l_ch376_init_00102:
;source-doc/base-drv/usb-init.c:38: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-init.c:39: return 1;
	ld	hl,0x0001
	jr	l_ch376_init_00113
l_ch376_init_00104:
;source-doc/base-drv/usb-init.c:42: if (state == 1) {
	ld	a,(ix+4)
	dec	a
	jr	NZ,l_ch376_init_00106
;source-doc/base-drv/usb-init.c:43: r = ch_cmd_get_ic_version();
	call	_ch_cmd_get_ic_version
;source-doc/base-drv/usb-init.c:45: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-init.c:46: return (uint16_t)r << 8 | 2;
	xor	a
	ld	h, l
	ld	l,0x02
	jr	l_ch376_init_00113
l_ch376_init_00106:
;source-doc/base-drv/usb-init.c:49: if (state == 2) {
	ld	a,(ix+4)
	sub	0x02
	jr	NZ,l_ch376_init_00159
	ld	a,0x01
	jr	l_ch376_init_00160
l_ch376_init_00159:
	xor	a
l_ch376_init_00160:
	ld	c,a
	or	a
	jr	Z,l_ch376_init_00110
;source-doc/base-drv/usb-init.c:50: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb-init.c:52: r = ch_very_short_wait_int_and_get_();
	call	_ch_very_short_wait_int_and_get
	ld	a, l
;source-doc/base-drv/usb-init.c:54: if (r != USB_INT_CONNECT) {
	sub	0x81
	jr	Z,l_ch376_init_00108
;source-doc/base-drv/usb-init.c:55: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-init.c:56: return 2;
	ld	hl,0x0002
	jr	l_ch376_init_00113
l_ch376_init_00108:
;source-doc/base-drv/usb-init.c:59: return 3;
	ld	hl,0x0003
	jr	l_ch376_init_00113
l_ch376_init_00110:
;source-doc/base-drv/usb-init.c:62: memset(get_usb_work_area(), 0, sizeof(_usb_state));
	ld	b,0x35
	ld	hl,_x
	jr	l_ch376_init_00163
l_ch376_init_00162:
	ld	(hl),0x00
	inc	hl
l_ch376_init_00163:
	ld	(hl),0x00
	inc	hl
	djnz	l_ch376_init_00162
;source-doc/base-drv/usb-init.c:63: if (state != 2) {
	bit	0, c
	jr	NZ,l_ch376_init_00112
;source-doc/base-drv/usb-init.c:64: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb-init.c:65: delay_medium();
	call	_delay_medium
l_ch376_init_00112:
;source-doc/base-drv/usb-init.c:67: enumerate_all_devices();
	call	_enumerate_all_devices
;source-doc/base-drv/usb-init.c:68: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-init.c:69: return (uint16_t)count_of_devices() << 8 | state + 1;
	call	_count_of_devices
	ld	c,(ix+4)
	ld	b,0x00
	inc	bc
	or	b
	ld	h, a
	ld	l, c
l_ch376_init_00113:
;source-doc/base-drv/usb-init.c:70: }
	pop	ix
	ret
;source-doc/base-drv/usb-init.c:72: static uint16_t wait_for_state(const uint8_t loop_counter, uint8_t state, const uint8_t desired_state) __sdcccall(1) {
; ---------------------------------
; Function wait_for_state
; ---------------------------------
_wait_for_state:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
	ld	(ix-1),a
	ld	b, l
;source-doc/base-drv/usb-init.c:73: uint16_t r = state;
	ld	e, b
;source-doc/base-drv/usb-init.c:75: for (uint8_t i = 0; i < loop_counter; i++) {
	ld	d,0x00
	ld	c,d
l_wait_for_state_00108:
	ld	a, c
	sub	(ix-1)
	jr	NC,l_wait_for_state_00106
;source-doc/base-drv/usb-init.c:76: if (state == desired_state)
	ld	a,(ix+4)
	sub	b
	jr	Z,l_wait_for_state_00106
;source-doc/base-drv/usb-init.c:79: if (i & 1)
	bit	0, c
	jr	Z,l_wait_for_state_00104
;source-doc/base-drv/usb-init.c:80: print_string("\b $");
	push	bc
	ld	hl,usb_init_str_0
	call	_print_string
	pop	bc
	jr	l_wait_for_state_00105
l_wait_for_state_00104:
;source-doc/base-drv/usb-init.c:82: print_string("\b*$");
	push	bc
	ld	hl,usb_init_str_1
	call	_print_string
	pop	bc
l_wait_for_state_00105:
;source-doc/base-drv/usb-init.c:84: r     = ch376_init(state);
	push	bc
	push	bc
	inc	sp
	call	_ch376_init
	inc	sp
	ex	de, hl
	pop	bc
;source-doc/base-drv/usb-init.c:85: state = r & 255;
	ld	b, e
;source-doc/base-drv/usb-init.c:75: for (uint8_t i = 0; i < loop_counter; i++) {
	inc	c
	jr	l_wait_for_state_00108
l_wait_for_state_00106:
;source-doc/base-drv/usb-init.c:88: return r;
;source-doc/base-drv/usb-init.c:89: }
	inc	sp
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
usb_init_str_0:
	DEFB 0x08
	DEFM " $"
	DEFB 0x00
usb_init_str_1:
	DEFB 0x08
	DEFM "*$"
	DEFB 0x00
;source-doc/base-drv/usb-init.c:91: void _chnative_init(bool forced) {
; ---------------------------------
; Function _chnative_init
; ---------------------------------
__chnative_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/usb-init.c:94: const uint8_t loop_counter = forced ? 40 : 5;
	bit	0,(ix+4)
	jr	Z,l__chnative_init_00113
	ld	a,0x28
	jr	l__chnative_init_00114
l__chnative_init_00113:
	ld	a,0x05
l__chnative_init_00114:
	ld	(ix-1),a
;source-doc/base-drv/usb-init.c:96: print_string("\r\nCH376: *$");
	ld	hl,usb_init_str_2
	call	_print_string
;source-doc/base-drv/usb-init.c:98: r     = wait_for_state(loop_counter, state, 1);
	ld	a,0x01
	push	af
	inc	sp
	ld	l,0x00
	ld	a,(ix-1)
	call	_wait_for_state
	ld	b, e
;source-doc/base-drv/usb-init.c:99: state = r & 255;
;source-doc/base-drv/usb-init.c:101: print_string("\bPRESENT (VER $");
	push	bc
	ld	hl,usb_init_str_3
	call	_print_string
;source-doc/base-drv/usb-init.c:103: r     = ch376_init(state);
	inc	sp
	call	_ch376_init
	inc	sp
	ex	de, hl
;source-doc/base-drv/usb-init.c:104: state = r & 255;
	ld	c, e
;source-doc/base-drv/usb-init.c:105: if (state != 2) {
	ld	a, c
	sub	0x02
	jr	Z,l__chnative_init_00102
;source-doc/base-drv/usb-init.c:106: print_string("\rCH376: $");
	ld	hl,usb_init_str_4
	call	_print_string
;source-doc/base-drv/usb-init.c:107: print_string("VERSION FAILURE\r\n$");
	ld	hl,usb_init_str_5
	call	_print_string
;source-doc/base-drv/usb-init.c:108: return;
	jr	l__chnative_init_00111
l__chnative_init_00102:
;source-doc/base-drv/usb-init.c:111: print_hex(r >> 8);
	push	bc
	ld	l, d
	call	_print_hex
;source-doc/base-drv/usb-init.c:112: print_string("); $");
	ld	hl,usb_init_str_6
	call	_print_string
;source-doc/base-drv/usb-init.c:114: print_string("USB: *$");
	ld	hl,usb_init_str_7
	call	_print_string
	pop	bc
;source-doc/base-drv/usb-init.c:116: r     = wait_for_state(loop_counter, state, 3);
	ld	a,0x03
	push	af
	inc	sp
	ld	l, c
	ld	a,(ix-1)
	call	_wait_for_state
	ld	b, e
;source-doc/base-drv/usb-init.c:117: state = r & 255;
;source-doc/base-drv/usb-init.c:119: if (state == 2) {
	ld	a, b
	sub	0x02
	jr	NZ,l__chnative_init_00104
;source-doc/base-drv/usb-init.c:120: print_string("\bDISCONNECTED$");
	ld	hl,usb_init_str_8
	call	_print_string
;source-doc/base-drv/usb-init.c:121: return;
	jr	l__chnative_init_00111
l__chnative_init_00104:
;source-doc/base-drv/usb-init.c:124: print_string("\bCONNECTED$");
	push	bc
	ld	hl,usb_init_str_9
	call	_print_string
;source-doc/base-drv/usb-init.c:127: r     = ch376_init(state);
	inc	sp
	call	_ch376_init
	inc	sp
	ex	de, hl
;source-doc/base-drv/usb-init.c:128: state = r & 255;
	ld	b, e
;source-doc/base-drv/usb-init.c:130: for (uint8_t i = 0; i < loop_counter; i++) {
	ld	c,0x00
l__chnative_init_00109:
	ld	a, c
	sub	(ix-1)
	jr	NC,l__chnative_init_00111
;source-doc/base-drv/usb-init.c:131: if (r >> 8 != 0)
	ld	a,0x00
	or	d
	jr	NZ,l__chnative_init_00111
;source-doc/base-drv/usb-init.c:134: print_string(".$");
	push	bc
	ld	hl,usb_init_str_10
	call	_print_string
	pop	bc
;source-doc/base-drv/usb-init.c:135: r     = ch376_init(state);
	push	bc
	push	bc
	inc	sp
	call	_ch376_init
	inc	sp
	ex	de, hl
	pop	bc
;source-doc/base-drv/usb-init.c:136: state = r & 255;
	ld	b, e
;source-doc/base-drv/usb-init.c:130: for (uint8_t i = 0; i < loop_counter; i++) {
	inc	c
	jr	l__chnative_init_00109
l__chnative_init_00111:
;source-doc/base-drv/usb-init.c:138: }
	inc	sp
	pop	ix
	ret
usb_init_str_2:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: *$"
	DEFB 0x00
usb_init_str_3:
	DEFB 0x08
	DEFM "PRESENT (VER $"
	DEFB 0x00
usb_init_str_4:
	DEFB 0x0d
	DEFM "CH376: $"
	DEFB 0x00
usb_init_str_5:
	DEFM "VERSION FAILURE"
	DEFB 0x0d
	DEFB 0x0a
	DEFM "$"
	DEFB 0x00
usb_init_str_6:
	DEFM "); $"
	DEFB 0x00
usb_init_str_7:
	DEFM "USB: *$"
	DEFB 0x00
usb_init_str_8:
	DEFB 0x08
	DEFM "DISCONNECTED$"
	DEFB 0x00
usb_init_str_9:
	DEFB 0x08
	DEFM "CONNECTED$"
	DEFB 0x00
usb_init_str_10:
	DEFM ".$"
	DEFB 0x00
;source-doc/base-drv/usb-init.c:140: void chnative_init_force(void) { _chnative_init(true); }
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
;source-doc/base-drv/usb-init.c:142: void chnative_init(void) { _chnative_init(false); }
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
