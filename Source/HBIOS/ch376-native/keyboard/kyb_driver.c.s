;
; Generated from source-doc/keyboard/kyb_driver.c.asm -- not to be modify directly
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
;source-doc/keyboard/kyb_driver.c:26:
; ---------------------------------
; Function report_diff
; ---------------------------------
_report_diff:
;source-doc/keyboard/kyb_driver.c:27: static uint8_t report_diff() __sdcccall(1) {
	ld	de,_report+0
;source-doc/keyboard/kyb_driver.c:28: uint8_t *a = (uint8_t *)&report;
;source-doc/keyboard/kyb_driver.c:31: uint8_t i = sizeof(report);
	ld	b,0x08
	ld	hl,_previous
l_report_diff_00103:
;source-doc/keyboard/kyb_driver.c:32: do {
	ld	a, (de)
	inc	de
	ld	c, (hl)
	inc	hl
	sub	c
	jr	Z,l_report_diff_00104
;source-doc/keyboard/kyb_driver.c:33: if (*a++ != *b++)
	ld	a,0x01
	jr	l_report_diff_00106
l_report_diff_00104:
;source-doc/keyboard/kyb_driver.c:34: return true;
	djnz	l_report_diff_00103
;source-doc/keyboard/kyb_driver.c:36:
	xor	a
l_report_diff_00106:
;source-doc/keyboard/kyb_driver.c:37: return false;
	ret
;source-doc/keyboard/kyb_driver.c:39:
; ---------------------------------
; Function report_put
; ---------------------------------
_report_put:
;source-doc/keyboard/kyb_driver.c:40: static void report_put() {
	ld	a, (_alt_write_index)
	inc	a
	and	0x07
	ld	c, a
;source-doc/keyboard/kyb_driver.c:42:
	ld	a,(_alt_read_index)
	sub	c
	ret	Z
;source-doc/keyboard/kyb_driver.c:43: if (next_write_index != alt_read_index) { // Check if buffer is not full
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
;source-doc/keyboard/kyb_driver.c:44: reports[alt_write_index] = report;
	ld	hl,_alt_write_index
	ld	(hl), c
;source-doc/keyboard/kyb_driver.c:46: }
	ret
;source-doc/keyboard/kyb_driver.c:48:
; ---------------------------------
; Function keyboard_buf_put
; ---------------------------------
_keyboard_buf_put:
	ld	c, a
;source-doc/keyboard/kyb_driver.c:49: static void keyboard_buf_put(const uint8_t indx) __sdcccall(1) {
	ld	b,0x00
	ld	hl,+(_report + 2)
	add	hl, bc
;source-doc/keyboard/kyb_driver.c:50: const uint8_t key_code = report.keyCode[indx];
	ld	a,(hl)
	ld	c,a
	cp	0x80
	jr	NC,l_keyboard_buf_put_00111
	or	a
;source-doc/keyboard/kyb_driver.c:51: if (key_code >= 0x80 || key_code == 0)
	jr	Z,l_keyboard_buf_put_00111
;source-doc/keyboard/kyb_driver.c:55: uint8_t  i = 6;
;source-doc/keyboard/kyb_driver.c:56: uint8_t *a = previous.keyCode;
	ld	b,0x06
	ld	hl,+(_previous + 2)
l_keyboard_buf_put_00106:
;source-doc/keyboard/kyb_driver.c:57: do {
	ld	a, (hl)
	inc	hl
	sub	c
;source-doc/keyboard/kyb_driver.c:58: if (*a++ == key_code)
	ret	Z
;source-doc/keyboard/kyb_driver.c:59: return;
	djnz	l_keyboard_buf_put_00106
;source-doc/keyboard/kyb_driver.c:61:
	ld	a, (_write_index)
	inc	a
	and	0x07
	ld	b, a
;source-doc/keyboard/kyb_driver.c:62: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	a,(_read_index)
	sub	b
	ret	Z
;source-doc/keyboard/kyb_driver.c:63: if (next_write_index != read_index) { // Check if buffer is not full
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
;source-doc/keyboard/kyb_driver.c:64: buffer[write_index] = (uint16_t)report.bModifierKeys << 8 | (uint16_t)key_code;
	ld	hl,_write_index
	ld	(hl), b
l_keyboard_buf_put_00111:
;source-doc/keyboard/kyb_driver.c:66: }
	ret
;source-doc/keyboard/kyb_driver.c:68:
; ---------------------------------
; Function usb_kyb_buf_size
; ---------------------------------
_usb_kyb_buf_size:
;source-doc/keyboard/kyb_driver.c:72:
	ld	a,(_alt_write_index)
	ld	hl,_alt_read_index
	sub	(hl)
	jr	C,l_usb_kyb_buf_size_00102
;source-doc/keyboard/kyb_driver.c:73: if (alt_write_index >= alt_read_index)
	ld	a,(_alt_write_index)
	ld	hl,_alt_read_index
	sub	(hl)
	ld	d, a
	jr	l_usb_kyb_buf_size_00103
l_usb_kyb_buf_size_00102:
;source-doc/keyboard/kyb_driver.c:75: else
	ld	hl, (_alt_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_alt_write_index)
	add	a, l
	ld	d, a
l_usb_kyb_buf_size_00103:
;source-doc/keyboard/kyb_driver.c:77:
	ld	a, d
	or	a
	jr	Z,l_usb_kyb_buf_size_00105
;source-doc/keyboard/kyb_driver.c:78: if (alt_size != 0)
	ld	a, (_alt_read_index)
	inc	a
	and	0x07
	ld	(_alt_read_index),a
l_usb_kyb_buf_size_00105:
;source-doc/keyboard/kyb_driver.c:80:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_usb_kyb_buf_size_00107
;source-doc/keyboard/kyb_driver.c:81: if (write_index >= read_index)
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	ld	e, a
	jr	l_usb_kyb_buf_size_00108
l_usb_kyb_buf_size_00107:
;source-doc/keyboard/kyb_driver.c:83: else
	ld	hl, (_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_write_index)
	add	a, l
	ld	e, a
l_usb_kyb_buf_size_00108:
;source-doc/keyboard/kyb_driver.c:85:
	xor	a
	xor	a
	ex	de, hl
;source-doc/keyboard/kyb_driver.c:86: return (uint16_t)alt_size << 8 | (uint16_t)size;
	ret
;source-doc/keyboard/kyb_driver.c:88:
; ---------------------------------
; Function usb_kyb_buf_get_next
; ---------------------------------
_usb_kyb_buf_get_next:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/keyboard/kyb_driver.c:89: uint32_t usb_kyb_buf_get_next() {
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_usb_kyb_buf_get_next_00102
;source-doc/keyboard/kyb_driver.c:90: if (write_index == read_index) // Check if buffer is empty
	ld	hl,0xff00
	ld	e, l
	ld	d, l
	jr	l_usb_kyb_buf_get_next_00103
l_usb_kyb_buf_get_next_00102:
;source-doc/keyboard/kyb_driver.c:92:
	ld	bc,_buffer+0
	ld	hl, (_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/keyboard/kyb_driver.c:93: const uint8_t modifier_key = buffer[read_index] >> 8;
;source-doc/keyboard/kyb_driver.c:94: const uint8_t key_code     = buffer[read_index] & 255;
	ld	a, (_read_index)
	inc	a
	and	0x07
	ld	(_read_index),a
;source-doc/keyboard/kyb_driver.c:101:
	push	bc
	ld	l, c
	ld	a, b
	call	_scancode_to_char
	ld	e, a
	pop	bc
;source-doc/keyboard/kyb_driver.c:103: /* D = modifier, e-> char, H = 0, L=>code */
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
l_usb_kyb_buf_get_next_00103:
;source-doc/keyboard/kyb_driver.c:104: return (uint32_t)modifier_key << 24 | (uint32_t)c << 16 | key_code;
	ld	sp, ix
	pop	ix
	ret
;source-doc/keyboard/kyb_driver.c:106:
; ---------------------------------
; Function usb_kyb_flush
; ---------------------------------
_usb_kyb_flush:
;source-doc/keyboard/kyb_driver.c:107: void usb_kyb_flush() {
	xor	a
	ld	(_alt_read_index),a
	ld	(_alt_write_index),a
	xor	a
	ld	(_read_index),a
	ld	(_write_index),a
;source-doc/keyboard/kyb_driver.c:110: uint8_t  i = sizeof(previous);
	ld	de,_previous+0
;source-doc/keyboard/kyb_driver.c:111: uint8_t *a = (uint8_t *)previous;
;source-doc/keyboard/kyb_driver.c:112: uint8_t *b = (uint8_t *)report;
	ld	b,0x08
	ld	hl,_report
l_usb_kyb_flush_00101:
;source-doc/keyboard/kyb_driver.c:113: do {
	xor	a
	ld	(de), a
	inc	de
;source-doc/keyboard/kyb_driver.c:114: *a++ = 0;
	ld	(hl),0x00
	inc	hl
;source-doc/keyboard/kyb_driver.c:115: *b++ = 0;
	djnz	l_usb_kyb_flush_00101
;source-doc/keyboard/kyb_driver.c:116: } while (--i != 0);
	ret
;source-doc/keyboard/kyb_driver.c:118:
; ---------------------------------
; Function usb_kyb_tick
; ---------------------------------
_usb_kyb_tick:
;source-doc/keyboard/kyb_driver.c:119: void usb_kyb_tick(void) {
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb_driver.c:120: if (is_in_critical_section())
	jr	NZ,l_usb_kyb_tick_00112
;././source-doc/base-drv//ch376.h:111:
	ld	l,0x0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:112: #endif
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;././source-doc/base-drv//ch376.h:113:
	ld	a,0x1f
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/keyboard/kyb_driver.c:123: ch_configure_nak_retry_disable();
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
;././source-doc/base-drv//ch376.h:111:
	ld	l,0x0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:112: #endif
	ld	a,0x25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;././source-doc/base-drv//ch376.h:113:
	ld	a,0xdf
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/keyboard/kyb_driver.c:125: ch_configure_nak_retry_3s();
	ld	hl,_result
	ld	a, (hl)
	or	a
	jr	NZ,l_usb_kyb_tick_00112
;source-doc/keyboard/kyb_driver.c:126: if (result == 0) {
	call	_report_diff
	or	a
	jr	Z,l_usb_kyb_tick_00112
;source-doc/keyboard/kyb_driver.c:127: if (report_diff()) {
	call	_report_put
;source-doc/keyboard/kyb_driver.c:129: uint8_t i = 6;
	ld	b,0x06
l_usb_kyb_tick_00103:
;source-doc/keyboard/kyb_driver.c:130: do {
	ld	a, b
	dec	a
	push	bc
	call	_keyboard_buf_put
	pop	bc
;source-doc/keyboard/kyb_driver.c:131: keyboard_buf_put(i - 1);
	djnz	l_usb_kyb_tick_00103
;source-doc/keyboard/kyb_driver.c:132: } while (--i != 0);
	ld	de,_previous
	ld	bc,0x0008
	ld	hl,_report
	ldir
l_usb_kyb_tick_00112:
;source-doc/keyboard/kyb_driver.c:135: }
	ret
;source-doc/keyboard/kyb_driver.c:137:
; ---------------------------------
; Function usb_kyb_init
; ---------------------------------
_usb_kyb_init:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/keyboard/kyb_driver.c:139: uint8_t result;
	ld	a,(ix+4)
	call	_get_usb_device_config
	ex	de, hl
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb_driver.c:141:
	ld	hl,_keyboard_config + 1
	ld	a, (hl)
	dec	hl
	or	(hl)
	jr	NZ,l_usb_kyb_init_00102
;source-doc/keyboard/kyb_driver.c:142: if (keyboard_config == NULL)
	ld	l,0x0f
	jr	l_usb_kyb_init_00106
l_usb_kyb_init_00102:
;source-doc/keyboard/kyb_driver.c:144:
	ld	a,0x01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
	ld	l, a
	or	a
	jr	NZ,l_usb_kyb_init_00105
;source-doc/keyboard/kyb_driver.c:145: CHECK(hid_set_protocol(keyboard_config, 1));
	ld	a,0x80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
	ld	l, a
;source-doc/keyboard/kyb_driver.c:147:
;source-doc/keyboard/kyb_driver.c:148: done:
l_usb_kyb_init_00105:
l_usb_kyb_init_00106:
;source-doc/keyboard/kyb_driver.c:149: return result;
	pop	ix
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
