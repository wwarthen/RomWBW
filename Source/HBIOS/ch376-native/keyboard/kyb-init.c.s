;
; Generated from source-doc/keyboard/kyb-init.c.asm -- not to be modify directly
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
	
_keyboard_config:
	DEFS 2
_buffer:
	DEFS 16
_write_index:
	DEFS 1
_read_index:
	DEFS 1
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
;source-doc/keyboard/kyb-init.c:11: void keyboard_init(void) {
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
;source-doc/keyboard/kyb-init.c:13: uint8_t index   = 1;
	ld	c,0x01
;source-doc/keyboard/kyb-init.c:14: keyboard_config = NULL;
	ld	hl,0x0000
	ld	(_keyboard_config),hl
;source-doc/keyboard/kyb-init.c:16: do {
	ld	b,0x01
l_keyboard_init_00105:
;source-doc/keyboard/kyb-init.c:17: keyboard_config = (device_config_keyboard *)get_usb_device_config(index);
	push	bc
	ld	a, b
	call	_get_usb_device_config
	ex	de, hl
	pop	bc
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb-init.c:19: if (keyboard_config == NULL)
	ld	hl,(_keyboard_config)
	ld	a,h
	or	l
	jr	Z,l_keyboard_init_00107
;source-doc/keyboard/kyb-init.c:22: const usb_device_type t = keyboard_config->type;
	ld	hl, (_keyboard_config)
	ld	a, (hl)
	and	0x0f
;source-doc/keyboard/kyb-init.c:24: if (t == USB_IS_KEYBOARD) {
	sub	0x04
	jr	NZ,l_keyboard_init_00106
;source-doc/keyboard/kyb-init.c:25: print_string("\r\nUSB: KEYBOARD @ $");
	push	bc
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	bc
;source-doc/keyboard/kyb-init.c:26: print_uint16(index);
	ld	h,0x00
	ld	l, c
	call	_print_uint16
;source-doc/keyboard/kyb-init.c:27: print_string(" $");
	ld	hl,kyb_init_str_1
	call	_print_string
;source-doc/keyboard/kyb-init.c:29: hid_set_protocol(keyboard_config, 1);
	ld	a,0x01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
;source-doc/keyboard/kyb-init.c:30: hid_set_idle(keyboard_config, 0x80);
	ld	a,0x80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
;source-doc/keyboard/kyb-init.c:31: return;
	jr	l_keyboard_init_00108
l_keyboard_init_00106:
;source-doc/keyboard/kyb-init.c:33: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	b
	ld	a,b
	ld	c,b
	sub	0x07
	jr	NZ,l_keyboard_init_00105
l_keyboard_init_00107:
;source-doc/keyboard/kyb-init.c:35: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	ld	hl,kyb_init_str_2
	jp	_print_string
l_keyboard_init_00108:
;source-doc/keyboard/kyb-init.c:36: }
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
;source-doc/keyboard/kyb-init.c:48: void keyboard_buf_put(const uint8_t modifier_keys, const uint8_t key_code) {
; ---------------------------------
; Function keyboard_buf_put
; ---------------------------------
_keyboard_buf_put:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/keyboard/kyb-init.c:49: if (key_code >= 0x80 || key_code == 0)
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_keyboard_buf_put_00106
	ld	a,(ix+5)
	or	a
;source-doc/keyboard/kyb-init.c:50: return; // ignore ???
	jr	Z,l_keyboard_buf_put_00106
;source-doc/keyboard/kyb-init.c:52: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	a,(_write_index)
	inc	a
	and	0x07
	ld	c, a
;source-doc/keyboard/kyb-init.c:53: if (next_write_index != read_index) { // Check if buffer is not full
	ld	a,(_read_index)
	sub	c
	jr	Z,l_keyboard_buf_put_00106
;source-doc/keyboard/kyb-init.c:54: buffer[write_index].modifier_keys = modifier_keys;
	ld	de,_buffer+0
	ld	hl,(_write_index)
	ld	h,0x00
	add	hl, hl
	add	hl, de
	ld	a,(ix+4)
	ld	(hl), a
;source-doc/keyboard/kyb-init.c:55: buffer[write_index].key_code      = key_code;
	ld	hl,(_write_index)
	ld	h,0x00
	add	hl, hl
	add	hl, de
	ex	de, hl
	inc	de
	ld	a,(ix+5)
	ld	(de), a
;source-doc/keyboard/kyb-init.c:56: write_index                       = next_write_index;
	ld	hl,_write_index
	ld	(hl), c
l_keyboard_buf_put_00106:
;source-doc/keyboard/kyb-init.c:58: }
	pop	ix
	ret
;source-doc/keyboard/kyb-init.c:60: uint8_t keyboard_buf_size() __sdcccall(1) {
; ---------------------------------
; Function keyboard_buf_size
; ---------------------------------
_keyboard_buf_size:
;source-doc/keyboard/kyb-init.c:61: if (write_index >= read_index)
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_keyboard_buf_size_00102
;source-doc/keyboard/kyb-init.c:62: return write_index - read_index;
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	l_keyboard_buf_size_00103
l_keyboard_buf_size_00102:
;source-doc/keyboard/kyb-init.c:64: return KEYBOARD_BUFFER_SIZE - read_index + write_index;
	ld	hl,_read_index
	ld	c, (hl)
	ld	a,0x08
	sub	c
	ld	hl,_write_index
	ld	c, (hl)
	add	a, c
l_keyboard_buf_size_00103:
;source-doc/keyboard/kyb-init.c:65: }
	ret
;source-doc/keyboard/kyb-init.c:67: uint32_t keyboard_buf_get_next() {
; ---------------------------------
; Function keyboard_buf_get_next
; ---------------------------------
_keyboard_buf_get_next:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/keyboard/kyb-init.c:68: if (write_index == read_index) // Check if buffer is empty
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_keyboard_buf_get_next_00102
;source-doc/keyboard/kyb-init.c:69: return 255 << 8;
	ld	hl,0xff00
	ld	e, h
	ld	d, h
	jr	l_keyboard_buf_get_next_00103
l_keyboard_buf_get_next_00102:
;source-doc/keyboard/kyb-init.c:71: const uint8_t modifier_key = buffer[read_index].modifier_keys;
	ld	bc,_buffer+0
	ld	hl,(_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, bc
	ld	b, (hl)
;source-doc/keyboard/kyb-init.c:72: const uint8_t key_code     = buffer[read_index].key_code;
	inc	hl
	ld	c, (hl)
;source-doc/keyboard/kyb-init.c:73: read_index                 = (read_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	hl,_read_index
	ld	a, (hl)
	inc	a
	and	0x07
	ld	(hl), a
;source-doc/keyboard/kyb-init.c:74: const unsigned char c      = scancode_to_char(modifier_key, key_code);
	push	bc
	ld	l, c
	ld	a, b
	call	_scancode_to_char
	ld	e, a
	pop	bc
;source-doc/keyboard/kyb-init.c:76: return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
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
l_keyboard_buf_get_next_00103:
;source-doc/keyboard/kyb-init.c:77: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/keyboard/kyb-init.c:79: void keyboard_buf_flush() {
; ---------------------------------
; Function keyboard_buf_flush
; ---------------------------------
_keyboard_buf_flush:
;source-doc/keyboard/kyb-init.c:80: write_index = 0;
	ld	hl,_write_index
	ld	(hl),0x00
;source-doc/keyboard/kyb-init.c:81: read_index  = 0;
	ld	hl,_read_index
	ld	(hl),0x00
;source-doc/keyboard/kyb-init.c:82: }
	ret
;source-doc/keyboard/kyb-init.c:88: void keyboard_tick(void) {
; ---------------------------------
; Function keyboard_tick
; ---------------------------------
_keyboard_tick:
;source-doc/keyboard/kyb-init.c:89: if (is_in_critical_section())
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb-init.c:90: return;
	ret	NZ
;././source-doc/base-drv//ch376.h:163: ch_command(CH_CMD_WRITE_VAR8);
	ld	l,0x0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:164: CH376_DATA_PORT = CH_VAR_RETRY_TIMES;
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;././source-doc/base-drv//ch376.h:165: CH376_DATA_PORT = retry << 6 | (number_of_retries & 0x1F);
	ld	a,0x1f
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/keyboard/kyb-init.c:93: result = usbdev_dat_in_trnsfer_0((device_config *)keyboard_config, (uint8_t *)report, 8);
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
;././source-doc/base-drv//ch376.h:163: ch_command(CH_CMD_WRITE_VAR8);
	ld	l,0x0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:164: CH376_DATA_PORT = CH_VAR_RETRY_TIMES;
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;././source-doc/base-drv//ch376.h:165: CH376_DATA_PORT = retry << 6 | (number_of_retries & 0x1F);
	ld	a,0xdf
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/keyboard/kyb-init.c:95: if (result == 0)
	ld	hl,_result
	ld	a, (hl)
	or	a
	ret	NZ
;source-doc/keyboard/kyb-init.c:96: keyboard_buf_put(report.bModifierKeys, report.keyCode[0]);
	ld	a, (_report + 2)
	ld	hl,_report
	ld	c, (hl)
	ld	b,a
	push	bc
	call	_keyboard_buf_put
	pop	af
;source-doc/keyboard/kyb-init.c:97: }
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
