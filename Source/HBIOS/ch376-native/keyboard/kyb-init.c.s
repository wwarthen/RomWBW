;
; Generated from source-doc/keyboard/kyb-init.c.asm -- not to be modify directly
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
	
_keyboard_config:
	DEFS 2
_buffer:
	DEFS 16
_write_index:
	DEFS 1
_read_index:
	DEFS 1
_previous_keyCodes:
	DEFS 6
_active:
	DEFS 1
_report:
	DEFS 8
	
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
;source-doc/keyboard/kyb-init.c:12: uint8_t keyboard_init(void) __sdcccall(1) {
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
;source-doc/keyboard/kyb-init.c:14: uint8_t index   = 1;
	ld	c,0x01
;source-doc/keyboard/kyb-init.c:15: keyboard_config = NULL;
	ld	hl,0x0000
	ld	(_keyboard_config),hl
;source-doc/keyboard/kyb-init.c:17: do {
	ld	b,0x01
l_keyboard_init_00105:
;source-doc/keyboard/kyb-init.c:18: keyboard_config = (device_config_keyboard *)get_usb_device_config(index);
	push	bc
	ld	a, b
	call	_get_usb_device_config
	ex	de, hl
	pop	bc
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb-init.c:20: if (keyboard_config == NULL)
	ld	hl,(_keyboard_config)
	ld	a,h
	or	l
	jr	Z,l_keyboard_init_00107
;source-doc/keyboard/kyb-init.c:23: const usb_device_type t = keyboard_config->type;
	ld	hl, (_keyboard_config)
	ld	a, (hl)
	and	0x0f
;source-doc/keyboard/kyb-init.c:25: if (t == USB_IS_KEYBOARD) {
	sub	0x04
	jr	NZ,l_keyboard_init_00106
;source-doc/keyboard/kyb-init.c:26: print_string("\r\nUSB: KEYBOARD @ $");
	push	bc
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	bc
;source-doc/keyboard/kyb-init.c:27: print_uint16(index);
	ld	h,0x00
	ld	l, c
	call	_print_uint16
;source-doc/keyboard/kyb-init.c:28: print_string(" $");
	ld	hl,kyb_init_str_1
	call	_print_string
;source-doc/keyboard/kyb-init.c:30: hid_set_protocol(keyboard_config, 1);
	ld	a,0x01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
;source-doc/keyboard/kyb-init.c:31: hid_set_idle(keyboard_config, 0x80);
	ld	a,0x80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
;source-doc/keyboard/kyb-init.c:32: return 1;
	ld	a,0x01
	jr	l_keyboard_init_00108
l_keyboard_init_00106:
;source-doc/keyboard/kyb-init.c:34: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	b
	ld	a,b
	ld	c,b
	sub	0x07
	jr	NZ,l_keyboard_init_00105
l_keyboard_init_00107:
;source-doc/keyboard/kyb-init.c:36: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	ld	hl,kyb_init_str_2
	call	_print_string
;source-doc/keyboard/kyb-init.c:37: return 0;
	xor	a
l_keyboard_init_00108:
;source-doc/keyboard/kyb-init.c:38: }
	ret
kyb_init_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "USB: KEYBOARD @ $"
	DEFB 0x00
kyb_init_str_1:
	DEFM " $"
	DEFB 0x00
kyb_init_str_2:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "USB: KEYBOARD: NOT FOUND$"
	DEFB 0x00
;source-doc/keyboard/kyb-init.c:51:
; ---------------------------------
; Function keyboard_buf_put
; ---------------------------------
_keyboard_buf_put:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/keyboard/kyb-init.c:52: void keyboard_buf_put(const uint8_t modifier_keys, const uint8_t key_code) {
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_keyboard_buf_put_00112
	ld	a,(ix+5)
	or	a
;source-doc/keyboard/kyb-init.c:53: if (key_code >= 0x80 || key_code == 0)
;source-doc/keyboard/kyb-init.c:56: // if already reported, just skip it
	jr	Z,l_keyboard_buf_put_00112
	ld	c,0x00
l_keyboard_buf_put_00110:
	ld	a, c
	sub	0x06
	jr	NC,l_keyboard_buf_put_00106
;source-doc/keyboard/kyb-init.c:57: for (uint8_t i = 0; i < 6; i++)
	ld	b,0x00
	ld	hl,_previous_keyCodes
	add	hl, bc
	ld	a, (hl)
	sub	(ix+5)
;source-doc/keyboard/kyb-init.c:58: if (previous_keyCodes[i] == key_code)
	jr	Z,l_keyboard_buf_put_00112
;source-doc/keyboard/kyb-init.c:56: // if already reported, just skip it
	inc	c
	jr	l_keyboard_buf_put_00110
l_keyboard_buf_put_00106:
;source-doc/keyboard/kyb-init.c:60:
	ld	a, (_write_index)
	inc	a
	and	0x07
	ld	c, a
;source-doc/keyboard/kyb-init.c:61: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	a,(_read_index)
	sub	c
	jr	Z,l_keyboard_buf_put_00112
;source-doc/keyboard/kyb-init.c:62: if (next_write_index != read_index) { // Check if buffer is not full
	ld	de,_buffer+0
	ld	hl, (_write_index)
	ld	h,0x00
	add	hl, hl
	add	hl, de
	ld	a,(ix+4)
	ld	(hl), a
;source-doc/keyboard/kyb-init.c:63: buffer[write_index].modifier_keys = modifier_keys;
	ld	hl, (_write_index)
	ld	h,0x00
	add	hl, hl
	add	hl, de
	inc	hl
	ld	a,(ix+5)
	ld	(hl), a
;source-doc/keyboard/kyb-init.c:64: buffer[write_index].key_code      = key_code;
	ld	hl,_write_index
	ld	(hl), c
l_keyboard_buf_put_00112:
;source-doc/keyboard/kyb-init.c:66: }
	pop	ix
	ret
;source-doc/keyboard/kyb-init.c:68:
; ---------------------------------
; Function keyboard_buf_size
; ---------------------------------
_keyboard_buf_size:
;source-doc/keyboard/kyb-init.c:69: uint8_t keyboard_buf_size() __sdcccall(1) {
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_keyboard_buf_size_00102
;source-doc/keyboard/kyb-init.c:70: if (write_index >= read_index)
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	l_keyboard_buf_size_00103
l_keyboard_buf_size_00102:
;source-doc/keyboard/kyb-init.c:72:
	ld	hl, (_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_write_index)
	add	a, l
l_keyboard_buf_size_00103:
;source-doc/keyboard/kyb-init.c:73: return KEYBOARD_BUFFER_SIZE - read_index + write_index;
	ret
;source-doc/keyboard/kyb-init.c:75:
; ---------------------------------
; Function keyboard_buf_get_next
; ---------------------------------
_keyboard_buf_get_next:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/keyboard/kyb-init.c:76: uint32_t keyboard_buf_get_next() {
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_keyboard_buf_get_next_00102
;source-doc/keyboard/kyb-init.c:77: if (write_index == read_index) // Check if buffer is empty
	ld	hl,0xff00
	ld	e, h
	ld	d, h
	jr	l_keyboard_buf_get_next_00105
l_keyboard_buf_get_next_00102:
;source-doc/keyboard/kyb-init.c:79:
	ld	bc,_buffer+0
	ld	hl, (_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, bc
	ld	b, (hl)
;source-doc/keyboard/kyb-init.c:80: const uint8_t modifier_key = buffer[read_index].modifier_keys;
	inc	hl
	ld	c, (hl)
;source-doc/keyboard/kyb-init.c:81: const uint8_t key_code     = buffer[read_index].key_code;
	ld	a, (_read_index)
	inc	a
	and	0x07
	ld	(_read_index),a
;source-doc/keyboard/kyb-init.c:83:
	ld	a, c
	sub	0x39
	jr	NZ,l_keyboard_buf_get_next_00104
;source-doc/keyboard/kyb-init.c:84: if (key_code == KEY_CODE_CAPS_LOCK) {
	ld	hl,_caps_lock_engaged
	ld	a, (hl)
	xor	0x01
	ld	(hl), a
;source-doc/keyboard/kyb-init.c:85: caps_lock_engaged = !caps_lock_engaged;
	call	_keyboard_buf_get_next
	jr	l_keyboard_buf_get_next_00105
l_keyboard_buf_get_next_00104:
;source-doc/keyboard/kyb-init.c:88:
	push	bc
	ld	l, c
	ld	a, b
	call	_scancode_to_char
	ld	e, a
	pop	bc
;source-doc/keyboard/kyb-init.c:90: /* D = modifier, e-> char, H = 0, L=>code */
	xor	a
	ld	(ix-1),b
	xor	a
	ld	(ix-4),a
	ld	(ix-3),a
	ld	(ix-2),a
	xor	a
	ld	d,(ix-1)
	ld	(ix-4),c
	xor	a
	ld	(ix-3),a
	ld	(ix-2),a
	ld	(ix-1),a
	pop	hl
	push	hl
l_keyboard_buf_get_next_00105:
;source-doc/keyboard/kyb-init.c:91: return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
	ld	sp, ix
	pop	ix
	ret
;source-doc/keyboard/kyb-init.c:93:
; ---------------------------------
; Function keyboard_buf_flush
; ---------------------------------
_keyboard_buf_flush:
;source-doc/keyboard/kyb-init.c:94: void keyboard_buf_flush() {
;source-doc/keyboard/kyb-init.c:95: write_index = 0;
	xor	a
	ld	(_write_index),a
	ld	(_read_index),a
;source-doc/keyboard/kyb-init.c:96: read_index  = 0;
	ret
;source-doc/keyboard/kyb-init.c:102:
; ---------------------------------
; Function keyboard_tick
; ---------------------------------
_keyboard_tick:
;source-doc/keyboard/kyb-init.c:103: void keyboard_tick(void) {
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb-init.c:104: if (is_in_critical_section())
	jr	NZ,l_keyboard_tick_00111
;././source-doc/base-drv//ch376.h:110: #endif
	ld	l,0x0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:111:
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;././source-doc/base-drv//ch376.h:112: #define calc_max_packet_sizex(packet_size) (packet_size & 0x3FF)
	ld	a,0x1f
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/keyboard/kyb-init.c:107: ch_configure_nak_retry_disable();
	ld	bc,_report
	ld	hl, (_keyboard_config)
	ld	a,0x08
	push	af
	inc	sp
	push	bc
	push	hl
	call	_usbdev_dat_in_trnsfer_0
	pop	af
	pop	af
	inc	sp
	ld	a, l
	ld	(_result), a
;././source-doc/base-drv//ch376.h:110: #endif
	ld	l,0x0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:111:
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;././source-doc/base-drv//ch376.h:112: #define calc_max_packet_sizex(packet_size) (packet_size & 0x3FF)
	ld	a,0xdf
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/keyboard/kyb-init.c:109: ch_configure_nak_retry_3s();
	ld	hl,_result
	ld	a, (hl)
;source-doc/keyboard/kyb-init.c:110: if (result == 0)
	or	a
	jr	NZ,l_keyboard_tick_00111
	ld	c,a
l_keyboard_tick_00109:
	ld	a, c
	sub	0x06
	ret	NC
;source-doc/keyboard/kyb-init.c:111: for (uint8_t i = 0; i < 6; i++) {
	ld	a,+((_report+2) & 0xFF)
	add	a, c
	ld	e, a
	ld	a,+((_report+2) / 256)
	adc	a,0x00
	ld	d, a
	ld	a, (de)
	ld	hl,_report
	ld	b, (hl)
	push	bc
	push	de
	ld	c,b
	ld	b,a
	push	bc
	call	_keyboard_buf_put
	pop	af
	pop	de
	pop	bc
;source-doc/keyboard/kyb-init.c:112: keyboard_buf_put(report.bModifierKeys, report.keyCode[i]);
	ld	b,0x00
	ld	hl,_previous_keyCodes
	add	hl, bc
	ld	a, (de)
	ld	(hl), a
;source-doc/keyboard/kyb-init.c:110: if (result == 0)
	inc	c
	jr	l_keyboard_tick_00109
l_keyboard_tick_00111:
;source-doc/keyboard/kyb-init.c:114: }
	ret
_keyboard_config:
	DEFW +0x0000
_buffer:
	DEFB +0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
_write_index:
	DEFB +0x00
_read_index:
	DEFB +0x00
_previous_keyCodes:
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
_active:
	DEFB +0x00
_report:
	DEFB +0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
