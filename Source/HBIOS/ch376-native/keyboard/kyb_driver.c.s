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
;source-doc/keyboard/kyb_driver.c:23: #define EI __asm__("EI")
; ---------------------------------
; Function report_diff
; ---------------------------------
_report_diff:
;source-doc/keyboard/kyb_driver.c:24:
	ld	de,_report+0
;source-doc/keyboard/kyb_driver.c:25: static uint8_t report_diff() __sdcccall(1) {
;source-doc/keyboard/kyb_driver.c:28:
	ld	b,0x08
	ld	hl,_previous
l_report_diff_00103:
;source-doc/keyboard/kyb_driver.c:29: uint8_t i = sizeof(report);
	ld	a, (de)
	inc	de
	ld	c, (hl)
	inc	hl
	sub	c
	jr	Z,l_report_diff_00104
;source-doc/keyboard/kyb_driver.c:30: do {
	ld	a,0x01
	jr	l_report_diff_00106
l_report_diff_00104:
;source-doc/keyboard/kyb_driver.c:31: if (*a++ != *b++)
	djnz	l_report_diff_00103
;source-doc/keyboard/kyb_driver.c:33: } while (--i != 0);
	xor	a
l_report_diff_00106:
;source-doc/keyboard/kyb_driver.c:34:
	ret
;source-doc/keyboard/kyb_driver.c:36: }
; ---------------------------------
; Function keyboard_buf_put
; ---------------------------------
_keyboard_buf_put:
	ld	c, a
;source-doc/keyboard/kyb_driver.c:37:
	ld	b,0x00
	ld	hl,+(_report + 2)
	add	hl, bc
;source-doc/keyboard/kyb_driver.c:38: static void keyboard_buf_put(const uint8_t indx) __sdcccall(1) {
	ld	a,(hl)
	ld	c,a
	cp	0x80
	jr	NC,l_keyboard_buf_put_00111
	or	a
;source-doc/keyboard/kyb_driver.c:39: const uint8_t key_code = report.keyCode[indx];
	jr	Z,l_keyboard_buf_put_00111
;source-doc/keyboard/kyb_driver.c:43: // if already reported, just skip it
;source-doc/keyboard/kyb_driver.c:44: uint8_t  i = 6;
	ld	b,0x06
	ld	hl,+(_previous + 2)
l_keyboard_buf_put_00106:
;source-doc/keyboard/kyb_driver.c:45: uint8_t *a = previous.keyCode;
	ld	a, (hl)
	inc	hl
	sub	c
;source-doc/keyboard/kyb_driver.c:46: do {
	ret	Z
;source-doc/keyboard/kyb_driver.c:47: if (*a++ == key_code)
	djnz	l_keyboard_buf_put_00106
;source-doc/keyboard/kyb_driver.c:49: } while (--i != 0);
	ld	a, (_write_index)
	inc	a
	and	0x07
	ld	b, a
;source-doc/keyboard/kyb_driver.c:50:
	ld	a,(_read_index)
	sub	b
	ret	Z
;source-doc/keyboard/kyb_driver.c:51: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
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
;source-doc/keyboard/kyb_driver.c:52: if (next_write_index != read_index) { // Check if buffer is not full
	ld	hl,_write_index
	ld	(hl), b
l_keyboard_buf_put_00111:
;source-doc/keyboard/kyb_driver.c:54: write_index         = next_write_index;
	ret
;source-doc/keyboard/kyb_driver.c:56: }
; ---------------------------------
; Function usb_kyb_status
; ---------------------------------
_usb_kyb_status:
;source-doc/keyboard/kyb_driver.c:57:
	DI
;source-doc/keyboard/kyb_driver.c:61: uint8_t size;
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_usb_kyb_status_00102
;source-doc/keyboard/kyb_driver.c:62:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	l_usb_kyb_status_00103
l_usb_kyb_status_00102:
;source-doc/keyboard/kyb_driver.c:64: size = write_index - read_index;
	ld	hl, (_read_index)
	ld	a,0x08
	sub	l
	ld	hl, (_write_index)
	add	a, l
l_usb_kyb_status_00103:
;source-doc/keyboard/kyb_driver.c:66: size = KEYBOARD_BUFFER_SIZE - read_index + write_index;
	EI
;source-doc/keyboard/kyb_driver.c:67:
;source-doc/keyboard/kyb_driver.c:68: EI;
	ret
;source-doc/keyboard/kyb_driver.c:70: }
; ---------------------------------
; Function usb_kyb_read
; ---------------------------------
_usb_kyb_read:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/keyboard/kyb_driver.c:71:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_usb_kyb_read_00102
;source-doc/keyboard/kyb_driver.c:72: uint32_t usb_kyb_read() {
	ld	hl,0xff00
	ld	e, l
	ld	d, l
	jr	l_usb_kyb_read_00103
l_usb_kyb_read_00102:
;source-doc/keyboard/kyb_driver.c:74: return 0x0000FF00;           // H = -1, D, E, L = 0
	DI
;source-doc/keyboard/kyb_driver.c:75:
	ld	bc,_buffer+0
	ld	hl, (_read_index)
	ld	h,0x00
	add	hl, hl
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/keyboard/kyb_driver.c:76: DI;
;source-doc/keyboard/kyb_driver.c:77: const uint8_t modifier_key = buffer[read_index] >> 8;
	ld	a, (_read_index)
	inc	a
	and	0x07
	ld	hl,_read_index
	ld	(hl), a
;source-doc/keyboard/kyb_driver.c:78: const uint8_t key_code     = buffer[read_index] & 255;
	EI
;source-doc/keyboard/kyb_driver.c:84: // L: KeyCode aka scan code
	push	bc
	ld	l, c
	ld	a, b
	call	_scancode_to_char
	ld	e, a
	pop	bc
;source-doc/keyboard/kyb_driver.c:87: /* D = modifier, e-> char, H = 0, L=>code */
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
l_usb_kyb_read_00103:
;source-doc/keyboard/kyb_driver.c:88:
	ld	sp, ix
	pop	ix
	ret
;source-doc/keyboard/kyb_driver.c:90: }
; ---------------------------------
; Function usb_kyb_flush
; ---------------------------------
_usb_kyb_flush:
;source-doc/keyboard/kyb_driver.c:91:
	DI
;source-doc/keyboard/kyb_driver.c:92: uint8_t usb_kyb_flush() __sdcccall(1) {
	xor	a
	ld	(_read_index),a
	ld	(_write_index),a
;source-doc/keyboard/kyb_driver.c:95:
	ld	de,_previous+0
;source-doc/keyboard/kyb_driver.c:96: uint8_t  i = sizeof(previous);
;source-doc/keyboard/kyb_driver.c:97: uint8_t *a = (uint8_t *)previous;
	ld	b,0x08
	ld	hl,_report
l_usb_kyb_flush_00101:
;source-doc/keyboard/kyb_driver.c:98: uint8_t *b = (uint8_t *)report;
	xor	a
	ld	(de), a
	inc	de
;source-doc/keyboard/kyb_driver.c:99: do {
	ld	(hl),0x00
	inc	hl
;source-doc/keyboard/kyb_driver.c:100: *a++ = 0;
	djnz	l_usb_kyb_flush_00101
;source-doc/keyboard/kyb_driver.c:102: } while (--i != 0);
	EI
;source-doc/keyboard/kyb_driver.c:104: EI;
	xor	a
;source-doc/keyboard/kyb_driver.c:105:
	ret
;source-doc/keyboard/kyb_driver.c:107: }
; ---------------------------------
; Function usb_kyb_tick
; ---------------------------------
_usb_kyb_tick:
;source-doc/keyboard/kyb_driver.c:108:
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb_driver.c:109: void usb_kyb_tick(void) {
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
;source-doc/keyboard/kyb_driver.c:112:
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
;source-doc/keyboard/kyb_driver.c:114: result = usbdev_dat_in_trnsfer_0((device_config *)keyboard_config, (uint8_t *)&report, 8);
	ld	hl,_result
	ld	a, (hl)
	or	a
	jr	NZ,l_usb_kyb_tick_00112
;source-doc/keyboard/kyb_driver.c:115: ch_configure_nak_retry_3s();
	call	_report_diff
	or	a
	jr	Z,l_usb_kyb_tick_00112
;source-doc/keyboard/kyb_driver.c:117: if (report_diff()) {
	ld	b,0x06
l_usb_kyb_tick_00103:
;source-doc/keyboard/kyb_driver.c:118: uint8_t i = 6;
	ld	a, b
	dec	a
	push	bc
	call	_keyboard_buf_put
	pop	bc
;source-doc/keyboard/kyb_driver.c:119: do {
	djnz	l_usb_kyb_tick_00103
;source-doc/keyboard/kyb_driver.c:120: keyboard_buf_put(i - 1);
	ld	de,_previous
	ld	bc,0x0008
	ld	hl,_report
	ldir
l_usb_kyb_tick_00112:
;source-doc/keyboard/kyb_driver.c:123: }
	ret
;source-doc/keyboard/kyb_driver.c:125: }
; ---------------------------------
; Function usb_kyb_init
; ---------------------------------
_usb_kyb_init:
;source-doc/keyboard/kyb_driver.c:126:
	call	_get_usb_device_config
	ex	de, hl
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb_driver.c:128: keyboard_config = (device_config_keyboard *)get_usb_device_config(dev_index);
	ld	hl,_keyboard_config + 1
	ld	a, (hl)
	dec	hl
	or	(hl)
;source-doc/keyboard/kyb_driver.c:129:
	ret	Z
;source-doc/keyboard/kyb_driver.c:131: return;
	ld	a,0x01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
;source-doc/keyboard/kyb_driver.c:132:
	ld	a,0x80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
;source-doc/keyboard/kyb_driver.c:133: hid_set_protocol(keyboard_config, 1);
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
