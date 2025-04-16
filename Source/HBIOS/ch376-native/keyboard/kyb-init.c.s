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
_alt_write_index:
	DEFS 1
_alt_read_index:
	DEFS 1
_reports:
	DEFS 64
_queued_report:
	DEFS 2
_report:
	DEFS 8
_previous:
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
;source-doc/keyboard/kyb-init.c:27:
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
;source-doc/keyboard/kyb-init.c:28: uint8_t keyboard_init(void) __sdcccall(1) {
	ld	c,0x01
;source-doc/keyboard/kyb-init.c:29: uint8_t index   = 1;
	ld	hl,0x0000
	ld	(_keyboard_config),hl
;source-doc/keyboard/kyb-init.c:31:
	ld	b,0x01
l_keyboard_init_00105:
;source-doc/keyboard/kyb-init.c:32: do {
	push	bc
	ld	a, b
	call	_get_usb_device_config
	ex	de, hl
	pop	bc
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb-init.c:34:
	ld	hl,(_keyboard_config)
	ld	a,h
	or	l
	jr	Z,l_keyboard_init_00107
;source-doc/keyboard/kyb-init.c:37:
	ld	hl, (_keyboard_config)
	ld	a, (hl)
	and	0x0f
;source-doc/keyboard/kyb-init.c:39:
	sub	0x04
	jr	NZ,l_keyboard_init_00106
;source-doc/keyboard/kyb-init.c:40: if (t == USB_IS_KEYBOARD) {
	push	bc
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	bc
;source-doc/keyboard/kyb-init.c:41: print_string("\r\nUSB: KEYBOARD @ $");
	ld	h,0x00
	ld	l, c
	call	_print_uint16
;source-doc/keyboard/kyb-init.c:42: print_uint16(index);
	ld	hl,kyb_init_str_1
	call	_print_string
;source-doc/keyboard/kyb-init.c:44:
	ld	a,0x01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
;source-doc/keyboard/kyb-init.c:45: hid_set_protocol(keyboard_config, 1);
	ld	a,0x80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
;source-doc/keyboard/kyb-init.c:46: hid_set_idle(keyboard_config, 0x80);
	ld	a,0x01
	jr	l_keyboard_init_00108
l_keyboard_init_00106:
;source-doc/keyboard/kyb-init.c:48: }
	inc	b
	ld	a,b
	ld	c,b
	sub	0x07
	jr	NZ,l_keyboard_init_00105
l_keyboard_init_00107:
;source-doc/keyboard/kyb-init.c:50:
	ld	hl,kyb_init_str_2
	call	_print_string
;source-doc/keyboard/kyb-init.c:51: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	xor	a
l_keyboard_init_00108:
;source-doc/keyboard/kyb-init.c:52: return 0;
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
;source-doc/keyboard/kyb-init.c:54:
; ---------------------------------
; Function report_diff
; ---------------------------------
_report_diff:
;source-doc/keyboard/kyb-init.c:55: static uint8_t report_diff() __sdcccall(1) {
	ld	de,_report+0
;source-doc/keyboard/kyb-init.c:56: uint8_t *a = (uint8_t *)&report;
;source-doc/keyboard/kyb-init.c:59: uint8_t i = sizeof(report);
	ld	b,0x08
	ld	hl,_previous
l_report_diff_00103:
;source-doc/keyboard/kyb-init.c:60: do {
	ld	a, (de)
	inc	de
	ld	c, (hl)
	inc	hl
	sub	c
	jr	Z,l_report_diff_00104
;source-doc/keyboard/kyb-init.c:61: if (*a++ != *b++)
	ld	a,0x01
	jr	l_report_diff_00106
l_report_diff_00104:
;source-doc/keyboard/kyb-init.c:62: return true;
	djnz	l_report_diff_00103
;source-doc/keyboard/kyb-init.c:64:
	xor	a
l_report_diff_00106:
;source-doc/keyboard/kyb-init.c:65: return false;
	ret
;source-doc/keyboard/kyb-init.c:67:
; ---------------------------------
; Function report_put
; ---------------------------------
_report_put:
;source-doc/keyboard/kyb-init.c:68: static void report_put() {
	ld	a, (_alt_write_index)
	inc	a
	and	0x07
	ld	c, a
;source-doc/keyboard/kyb-init.c:70:
	ld	a,(_alt_read_index)
	sub	c
	ret	Z
;source-doc/keyboard/kyb-init.c:71: if (next_write_index != alt_read_index) { // Check if buffer is not full
	ld	de,_reports+0
	ld	hl, (_alt_write_index)
	ld	h,0x00
	add	hl, hl
	add	hl, hl
	add	hl, hl
	add	hl, de
	ex	de, hl
	push	bc
	ld	bc,0x0008
	ld	hl,_report
	ldir
	pop	bc
;source-doc/keyboard/kyb-init.c:72: reports[alt_write_index] = report;
	ld	hl,_alt_write_index
	ld	(hl), c
;source-doc/keyboard/kyb-init.c:74: }
	ret
;source-doc/keyboard/kyb-init.c:76:
; ---------------------------------
; Function keyboard_buf_put
; ---------------------------------
_keyboard_buf_put:
	ld	c, a
;source-doc/keyboard/kyb-init.c:77: static void keyboard_buf_put(const uint8_t indx) __sdcccall(1) {
	ld	b,0x00
	ld	hl,+(_report + 2)
	add	hl, bc
;source-doc/keyboard/kyb-init.c:78: const uint8_t key_code = report.keyCode[indx];
	ld	a,(hl)
	ld	c,a
	cp	0x80
	jr	NC,l_keyboard_buf_put_00111
	or	a
;source-doc/keyboard/kyb-init.c:79: if (key_code >= 0x80 || key_code == 0)
	jr	Z,l_keyboard_buf_put_00111
;source-doc/keyboard/kyb-init.c:83: uint8_t  i = 6;
;source-doc/keyboard/kyb-init.c:84: uint8_t *a = previous.keyCode;
	ld	b,0x06
	ld	hl,+(_previous + 2)
l_keyboard_buf_put_00106:
;source-doc/keyboard/kyb-init.c:85: do {
	ld	a, (hl)
	inc	hl
	sub	c
;source-doc/keyboard/kyb-init.c:86: if (*a++ == key_code)
	ret	Z
;source-doc/keyboard/kyb-init.c:87: return;
	djnz	l_keyboard_buf_put_00106
;source-doc/keyboard/kyb-init.c:89:
	ld	a, (_write_index)
	inc	a
	and	0x07
	ld	b, a
;source-doc/keyboard/kyb-init.c:90: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	a,(_read_index)
	sub	b
	ret	Z
;source-doc/keyboard/kyb-init.c:91: if (next_write_index != read_index) { // Check if buffer is not full
	ld	de,_buffer+0
	ld	hl, (_write_index)
	ld	h,0x00
	add	hl, hl
	add	hl, de
	ex	de, hl
	ld	hl,(_report)
	xor	a
	xor	a
	ld	a, c
	ld	(de), a
	inc	de
	ld	a, l
	ld	(de), a
;source-doc/keyboard/kyb-init.c:92: buffer[write_index] = (uint16_t)report.bModifierKeys << 8 | (uint16_t)key_code;
	ld	hl,_write_index
	ld	(hl), b
l_keyboard_buf_put_00111:
;source-doc/keyboard/kyb-init.c:94: }
	ret
;source-doc/keyboard/kyb-init.c:96:
; ---------------------------------
; Function keyboard_buf_size
; ---------------------------------
_keyboard_buf_size:
;source-doc/keyboard/kyb-init.c:100:
	ld	a,(_alt_write_index)
	ld	hl,_alt_read_index
	sub	(hl)
	jr	C,l_keyboard_buf_size_00102
;source-doc/keyboard/kyb-init.c:101: if (alt_write_index >= alt_read_index)
	ld	a,(_alt_write_index)
	ld	hl,_alt_read_index
	sub	(hl)
	ld	d, a
	jr	l_keyboard_buf_size_00103
l_keyboard_buf_size_00102:
;source-doc/keyboard/kyb-init.c:103: else
	ld	hl, (_alt_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_alt_write_index)
	add	a, l
	ld	d, a
l_keyboard_buf_size_00103:
;source-doc/keyboard/kyb-init.c:105:
	ld	a, d
	or	a
	jr	Z,l_keyboard_buf_size_00105
;source-doc/keyboard/kyb-init.c:106: if (alt_size != 0)
	ld	a, (_alt_read_index)
	inc	a
	and	0x07
	ld	(_alt_read_index),a
l_keyboard_buf_size_00105:
;source-doc/keyboard/kyb-init.c:108:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_keyboard_buf_size_00107
;source-doc/keyboard/kyb-init.c:109: if (write_index >= read_index)
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	ld	e, a
	jr	l_keyboard_buf_size_00108
l_keyboard_buf_size_00107:
;source-doc/keyboard/kyb-init.c:111: else
	ld	hl, (_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_write_index)
	add	a, l
	ld	e, a
l_keyboard_buf_size_00108:
;source-doc/keyboard/kyb-init.c:113:
	xor	a
	xor	a
	ex	de, hl
;source-doc/keyboard/kyb-init.c:114: return (uint16_t)alt_size << 8 | (uint16_t)size;
	ret
;source-doc/keyboard/kyb-init.c:116:
; ---------------------------------
; Function keyboard_buf_get_next
; ---------------------------------
_keyboard_buf_get_next:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/keyboard/kyb-init.c:117: uint32_t keyboard_buf_get_next() {
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_keyboard_buf_get_next_00102
;source-doc/keyboard/kyb-init.c:118: if (write_index == read_index) // Check if buffer is empty
	ld	hl,0xff00
	ld	e, l
	ld	d, l
	jr	l_keyboard_buf_get_next_00103
l_keyboard_buf_get_next_00102:
;source-doc/keyboard/kyb-init.c:120:
	ld	bc,_buffer+0
	ld	hl, (_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/keyboard/kyb-init.c:121: const uint8_t modifier_key = buffer[read_index] >> 8;
;source-doc/keyboard/kyb-init.c:122: const uint8_t key_code     = buffer[read_index] & 255;
	ld	a, (_read_index)
	inc	a
	and	0x07
	ld	(_read_index),a
;source-doc/keyboard/kyb-init.c:129:
	push	bc
	ld	l, c
	ld	a, b
	call	_scancode_to_char
	ld	e, a
	pop	bc
;source-doc/keyboard/kyb-init.c:131: /* D = modifier, e-> char, H = 0, L=>code */
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
;source-doc/keyboard/kyb-init.c:132: return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
	ld	sp, ix
	pop	ix
	ret
;source-doc/keyboard/kyb-init.c:134:
; ---------------------------------
; Function keyboard_buf_flush
; ---------------------------------
_keyboard_buf_flush:
;source-doc/keyboard/kyb-init.c:135: void keyboard_buf_flush() {
	xor	a
	ld	(_alt_read_index),a
	ld	(_alt_write_index),a
	xor	a
	ld	(_read_index),a
	ld	(_write_index),a
;source-doc/keyboard/kyb-init.c:138: uint8_t  i = sizeof(previous);
	ld	de,_previous+0
;source-doc/keyboard/kyb-init.c:139: uint8_t *a = (uint8_t *)previous;
;source-doc/keyboard/kyb-init.c:140: uint8_t *b = (uint8_t *)report;
	ld	b,0x08
	ld	hl,_report
l_keyboard_buf_flush_00101:
;source-doc/keyboard/kyb-init.c:141: do {
	xor	a
	ld	(de), a
	inc	de
;source-doc/keyboard/kyb-init.c:142: *a++ = 0;
	ld	(hl),0x00
	inc	hl
;source-doc/keyboard/kyb-init.c:143: *b++ = 0;
	djnz	l_keyboard_buf_flush_00101
;source-doc/keyboard/kyb-init.c:144: } while (--i != 0);
	ret
;source-doc/keyboard/kyb-init.c:146:
; ---------------------------------
; Function keyboard_tick
; ---------------------------------
_keyboard_tick:
;source-doc/keyboard/kyb-init.c:147: void keyboard_tick(void) {
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb-init.c:148: if (is_in_critical_section())
	jr	NZ,l_keyboard_tick_00112
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
;source-doc/keyboard/kyb-init.c:151: ch_configure_nak_retry_disable();
	ld	bc,_report+0
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
;source-doc/keyboard/kyb-init.c:153: ch_configure_nak_retry_3s();
	ld	hl,_result
	ld	a, (hl)
	or	a
	jr	NZ,l_keyboard_tick_00112
;source-doc/keyboard/kyb-init.c:154: if (result == 0) {
	call	_report_diff
	or	a
	jr	Z,l_keyboard_tick_00112
;source-doc/keyboard/kyb-init.c:155: if (report_diff()) {
	call	_report_put
;source-doc/keyboard/kyb-init.c:157: uint8_t i = 6;
	ld	b,0x06
l_keyboard_tick_00103:
;source-doc/keyboard/kyb-init.c:158: do {
	ld	a, b
	dec	a
	push	bc
	call	_keyboard_buf_put
	pop	bc
;source-doc/keyboard/kyb-init.c:159: keyboard_buf_put(i-1);
	djnz	l_keyboard_tick_00103
;source-doc/keyboard/kyb-init.c:160: } while (--i != 0);
	ld	de,_previous
	ld	bc,0x0008
	ld	hl,_report
	ldir
l_keyboard_tick_00112:
;source-doc/keyboard/kyb-init.c:163: }
	ret
_keyboard_config:
	DEFW +0x0000
_buffer:
	DEFW +0x0000
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
_alt_write_index:
	DEFB +0x00
_alt_read_index:
	DEFB +0x00
_reports:
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
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
_queued_report:
	DEFW +0x0000
_report:
	DEFB +0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
_previous:
	DEFB +0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
