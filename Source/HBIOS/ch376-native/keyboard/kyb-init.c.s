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
;source-doc/keyboard/kyb-init.c:30:
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
;source-doc/keyboard/kyb-init.c:31: uint8_t keyboard_init(void) __sdcccall(1) {
	ld	c,0x01
;source-doc/keyboard/kyb-init.c:32: uint8_t index   = 1;
	ld	hl,0x0000
	ld	(_keyboard_config),hl
;source-doc/keyboard/kyb-init.c:34:
	ld	b,0x01
l_keyboard_init_00105:
;source-doc/keyboard/kyb-init.c:35: do {
	push	bc
	ld	a, b
	call	_get_usb_device_config
	ex	de, hl
	pop	bc
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb-init.c:37:
	ld	hl,(_keyboard_config)
	ld	a,h
	or	l
	jr	Z,l_keyboard_init_00107
;source-doc/keyboard/kyb-init.c:40:
	ld	hl, (_keyboard_config)
	ld	a, (hl)
	and	0x0f
;source-doc/keyboard/kyb-init.c:42:
	sub	0x04
	jr	NZ,l_keyboard_init_00106
;source-doc/keyboard/kyb-init.c:43: if (t == USB_IS_KEYBOARD) {
	push	bc
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	bc
;source-doc/keyboard/kyb-init.c:44: print_string("\r\nUSB: KEYBOARD @ $");
	ld	h,0x00
	ld	l, c
	call	_print_uint16
;source-doc/keyboard/kyb-init.c:45: print_uint16(index);
	ld	hl,kyb_init_str_1
	call	_print_string
;source-doc/keyboard/kyb-init.c:47:
	ld	a,0x01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
;source-doc/keyboard/kyb-init.c:48: hid_set_protocol(keyboard_config, 1);
	ld	a,0x80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
;source-doc/keyboard/kyb-init.c:49: hid_set_idle(keyboard_config, 0x80);
	ld	a,0x01
	jr	l_keyboard_init_00108
l_keyboard_init_00106:
;source-doc/keyboard/kyb-init.c:51: }
	inc	b
	ld	a,b
	ld	c,b
	sub	0x07
	jr	NZ,l_keyboard_init_00105
l_keyboard_init_00107:
;source-doc/keyboard/kyb-init.c:53:
	ld	hl,kyb_init_str_2
	call	_print_string
;source-doc/keyboard/kyb-init.c:54: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	xor	a
l_keyboard_init_00108:
;source-doc/keyboard/kyb-init.c:55: return 0;
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
;source-doc/keyboard/kyb-init.c:57:
; ---------------------------------
; Function report_diff
; ---------------------------------
_report_diff:
;source-doc/keyboard/kyb-init.c:58: static uint8_t report_diff() __sdcccall(1) {
	ld	de,_report+0
;source-doc/keyboard/kyb-init.c:59: uint8_t *a = (uint8_t *)&report;
;source-doc/keyboard/kyb-init.c:62: uint8_t i = sizeof(report);
	ld	b,0x08
	ld	hl,_previous
l_report_diff_00103:
;source-doc/keyboard/kyb-init.c:63: do {
	ld	a, (de)
	inc	de
	ld	c, (hl)
	inc	hl
	sub	c
	jr	Z,l_report_diff_00104
;source-doc/keyboard/kyb-init.c:64: if (*a++ != *b++)
	ld	a,0x01
	jr	l_report_diff_00106
l_report_diff_00104:
;source-doc/keyboard/kyb-init.c:65: return true;
	djnz	l_report_diff_00103
;source-doc/keyboard/kyb-init.c:67:
	xor	a
l_report_diff_00106:
;source-doc/keyboard/kyb-init.c:68: return false;
	ret
;source-doc/keyboard/kyb-init.c:70:
; ---------------------------------
; Function report_put
; ---------------------------------
_report_put:
;source-doc/keyboard/kyb-init.c:71: static void report_put() {
	ld	a, (_alt_write_index)
	inc	a
	and	0x07
	ld	c, a
;source-doc/keyboard/kyb-init.c:73:
	ld	a,(_alt_read_index)
	sub	c
	ret	Z
;source-doc/keyboard/kyb-init.c:74: if (next_write_index != alt_read_index) { // Check if buffer is not full
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
;source-doc/keyboard/kyb-init.c:75: reports[alt_write_index] = report;
	ld	hl,_alt_write_index
	ld	(hl), c
;source-doc/keyboard/kyb-init.c:77: }
	ret
;source-doc/keyboard/kyb-init.c:79:
; ---------------------------------
; Function keyboard_buf_put
; ---------------------------------
_keyboard_buf_put:
	ld	c, a
;source-doc/keyboard/kyb-init.c:80: static void keyboard_buf_put(const uint8_t modifier_keys, const uint8_t key_code) __sdcccall(1) {
	ld	a,l
	ld	e,l
	cp	0x80
	jr	NC,l_keyboard_buf_put_00111
	or	a
;source-doc/keyboard/kyb-init.c:81: if (key_code >= 0x80 || key_code == 0)
	jr	Z,l_keyboard_buf_put_00111
;source-doc/keyboard/kyb-init.c:85: uint8_t  i = 6;
;source-doc/keyboard/kyb-init.c:86: uint8_t *a = previous.keyCode;
	ld	b,0x06
	ld	hl,+(_previous + 2)
l_keyboard_buf_put_00106:
;source-doc/keyboard/kyb-init.c:87: do {
	ld	a, (hl)
	inc	hl
	sub	e
;source-doc/keyboard/kyb-init.c:88: if (*a++ == key_code)
	ret	Z
;source-doc/keyboard/kyb-init.c:89: return;
	djnz	l_keyboard_buf_put_00106
;source-doc/keyboard/kyb-init.c:91:
	ld	a, (_write_index)
	inc	a
	and	0x07
	ld	d, a
;source-doc/keyboard/kyb-init.c:92: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	a,(_read_index)
	sub	d
	ret	Z
;source-doc/keyboard/kyb-init.c:93: if (next_write_index != read_index) { // Check if buffer is not full
	ld	hl, (_write_index)
	ld	h,0x00
	add	hl, hl
	ld	a,+((_buffer) & 0xFF)
	add	a,l
	ld	l,a
	ld	a,+((_buffer) / 256)
	adc	a,h
	ld	h,a
	ld	(hl), c
;source-doc/keyboard/kyb-init.c:94: buffer[write_index].modifier_keys = modifier_keys;
	ld	hl, (_write_index)
	ld	h,0x00
	add	hl, hl
	ld	bc,_buffer
	add	hl, bc
	inc	hl
	ld	(hl), e
;source-doc/keyboard/kyb-init.c:95: buffer[write_index].key_code      = key_code;
	ld	hl,_write_index
	ld	(hl), d
l_keyboard_buf_put_00111:
;source-doc/keyboard/kyb-init.c:97: }
	ret
;source-doc/keyboard/kyb-init.c:99:
; ---------------------------------
; Function keyboard_buf_size
; ---------------------------------
_keyboard_buf_size:
;source-doc/keyboard/kyb-init.c:103:
	ld	a,(_alt_write_index)
	ld	hl,_alt_read_index
	sub	(hl)
	jr	C,l_keyboard_buf_size_00102
;source-doc/keyboard/kyb-init.c:104: if (alt_write_index >= alt_read_index)
	ld	a,(_alt_write_index)
	ld	hl,_alt_read_index
	sub	(hl)
	ld	d, a
	jr	l_keyboard_buf_size_00103
l_keyboard_buf_size_00102:
;source-doc/keyboard/kyb-init.c:106: else
	ld	hl, (_alt_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_alt_write_index)
	add	a, l
	ld	d, a
l_keyboard_buf_size_00103:
;source-doc/keyboard/kyb-init.c:108:
	ld	a, d
	or	a
	jr	NZ,l_keyboard_buf_size_00105
;source-doc/keyboard/kyb-init.c:109: if (alt_size == 0)
	ld	hl,0x0000
	ld	(_queued_report),hl
	jr	l_keyboard_buf_size_00106
l_keyboard_buf_size_00105:
;source-doc/keyboard/kyb-init.c:111: else {
	ld	hl, (_alt_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, hl
	add	hl, hl
	ld	bc,_reports
	add	hl, bc
	ld	(_queued_report), hl
;source-doc/keyboard/kyb-init.c:112: queued_report  = &reports[alt_read_index];
	ld	a, (_alt_read_index)
	inc	a
	and	0x07
	ld	(_alt_read_index),a
l_keyboard_buf_size_00106:
;source-doc/keyboard/kyb-init.c:115:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_keyboard_buf_size_00108
;source-doc/keyboard/kyb-init.c:116: if (write_index >= read_index)
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	ld	e, a
	jr	l_keyboard_buf_size_00109
l_keyboard_buf_size_00108:
;source-doc/keyboard/kyb-init.c:118: else
	ld	hl, (_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_write_index)
	add	a, l
	ld	e, a
l_keyboard_buf_size_00109:
;source-doc/keyboard/kyb-init.c:120:
	xor	a
	xor	a
	ex	de, hl
;source-doc/keyboard/kyb-init.c:121: return (uint16_t)alt_size << 8 | (uint16_t)size;
	ret
;source-doc/keyboard/kyb-init.c:123:
; ---------------------------------
; Function keyboard_buf_get_next
; ---------------------------------
_keyboard_buf_get_next:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/keyboard/kyb-init.c:124: uint32_t keyboard_buf_get_next() {
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_keyboard_buf_get_next_00102
;source-doc/keyboard/kyb-init.c:125: if (write_index == read_index) // Check if buffer is empty
	ld	hl,0xff00
	ld	e, l
	ld	d, l
	jr	l_keyboard_buf_get_next_00103
l_keyboard_buf_get_next_00102:
;source-doc/keyboard/kyb-init.c:127:
	ld	bc,_buffer+0
	ld	hl, (_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, bc
	ld	b, (hl)
;source-doc/keyboard/kyb-init.c:128: const uint8_t modifier_key = buffer[read_index].modifier_keys;
	inc	hl
	ld	c, (hl)
;source-doc/keyboard/kyb-init.c:129: const uint8_t key_code     = buffer[read_index].key_code;
	ld	a, (_read_index)
	inc	a
	and	0x07
	ld	(_read_index),a
;source-doc/keyboard/kyb-init.c:136:
	push	bc
	ld	l, c
	ld	a, b
	call	_scancode_to_char
	ld	e, a
	pop	bc
;source-doc/keyboard/kyb-init.c:138: /* D = modifier, e-> char, H = 0, L=>code */
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
;source-doc/keyboard/kyb-init.c:139: return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
	ld	sp, ix
	pop	ix
	ret
;source-doc/keyboard/kyb-init.c:141:
; ---------------------------------
; Function keyboard_buf_flush
; ---------------------------------
_keyboard_buf_flush:
;source-doc/keyboard/kyb-init.c:142: void keyboard_buf_flush() {
	xor	a
	ld	(_alt_read_index),a
	ld	(_alt_write_index),a
	xor	a
	ld	(_read_index),a
	ld	(_write_index),a
;source-doc/keyboard/kyb-init.c:145: uint8_t  i = sizeof(previous);
	ld	de,_previous+0
;source-doc/keyboard/kyb-init.c:146: uint8_t *a = (uint8_t *)previous;
;source-doc/keyboard/kyb-init.c:147: uint8_t *b = (uint8_t *)report;
	ld	b,0x08
	ld	hl,_report
l_keyboard_buf_flush_00101:
;source-doc/keyboard/kyb-init.c:148: do {
	xor	a
	ld	(de), a
	inc	de
;source-doc/keyboard/kyb-init.c:149: *a++ = 0;
	ld	(hl),0x00
	inc	hl
;source-doc/keyboard/kyb-init.c:150: *b++ = 0;
	djnz	l_keyboard_buf_flush_00101
;source-doc/keyboard/kyb-init.c:151: } while (--i != 0);
	ret
;source-doc/keyboard/kyb-init.c:153:
; ---------------------------------
; Function keyboard_tick
; ---------------------------------
_keyboard_tick:
;source-doc/keyboard/kyb-init.c:154: void keyboard_tick(void) {
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb-init.c:155: if (is_in_critical_section())
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
;source-doc/keyboard/kyb-init.c:158: ch_configure_nak_retry_disable();
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
;source-doc/keyboard/kyb-init.c:160: ch_configure_nak_retry_3s();
	ld	hl,_result
	ld	a, (hl)
	or	a
	jr	NZ,l_keyboard_tick_00112
;source-doc/keyboard/kyb-init.c:161: if (result == 0) {
	call	_report_diff
	or	a
	jr	Z,l_keyboard_tick_00112
;source-doc/keyboard/kyb-init.c:162: if (report_diff()) {
	call	_report_put
;source-doc/keyboard/kyb-init.c:164: uint8_t i = 6;
	ld	b,0x06
l_keyboard_tick_00103:
;source-doc/keyboard/kyb-init.c:165: do {
	ld	l, b
	dec	l
	ld	h,0x00
	ld	de, +(_report + 2)
	add	hl, de
	ld	c, (hl)
	ld	a,(_report)
	push	bc
	ld	l, c
	call	_keyboard_buf_put
	pop	bc
;source-doc/keyboard/kyb-init.c:166: keyboard_buf_put(report.bModifierKeys, report.keyCode[i-1]);
	djnz	l_keyboard_tick_00103
;source-doc/keyboard/kyb-init.c:167: } while (--i != 0);
	ld	de,_previous
	ld	bc,0x0008
	ld	hl,_report
	ldir
l_keyboard_tick_00112:
;source-doc/keyboard/kyb-init.c:170: }
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
