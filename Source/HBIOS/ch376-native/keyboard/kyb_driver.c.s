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
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
#IF 0
	
; .area _INITIALIZED removed by z88dk
	
_caps_lock_engaged:
	DEFS 1
_keyboard_config:
	DEFS 2
_buffer:
	DEFS 8
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
	ld	b,$08
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
	ld	a,$01
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
	ld	b,$00
	ld	hl,+(_report + 2)
	add	hl, bc
;source-doc/keyboard/kyb_driver.c:38: static void keyboard_buf_put(const uint8_t indx) __sdcccall(1) {
	ld	a,(hl)
	ld	e,a
	sub	$80
	jr	NC,l_keyboard_buf_put_00112
	ld	a, e
	or	a
;source-doc/keyboard/kyb_driver.c:39: const uint8_t key_code = report.keyCode[indx];
	jr	Z,l_keyboard_buf_put_00112
;source-doc/keyboard/kyb_driver.c:42:
	ld	b,$00
	ld	hl,+(_previous + 2)
	add	hl, bc
	ld	a, (hl)
	sub	e
;source-doc/keyboard/kyb_driver.c:43: // if already reported, just skip it
	jr	Z,l_keyboard_buf_put_00112
;source-doc/keyboard/kyb_driver.c:45: return;
	ld	a, e
	sub	$39
	jr	NZ,l_keyboard_buf_put_00107
;source-doc/keyboard/kyb_driver.c:46:
	ld	hl,_caps_lock_engaged
	ld	a, (hl)
	xor	$01
	ld	(hl), a
;source-doc/keyboard/kyb_driver.c:47: if (key_code == KEY_CODE_CAPS_LOCK) {
	jr	l_keyboard_buf_put_00112
l_keyboard_buf_put_00107:
;source-doc/keyboard/kyb_driver.c:50: }
	ld	a,(_report)
	ld	hl,_caps_lock_engaged
	ld	h, (hl)
	push	hl
	inc	sp
	ld	l, e
	call	_scancode_to_char
	ld	b, a
;source-doc/keyboard/kyb_driver.c:52: const unsigned char c = scancode_to_char(report.bModifierKeys, key_code, caps_lock_engaged);
	or	a
;source-doc/keyboard/kyb_driver.c:53:
	ret	Z
;source-doc/keyboard/kyb_driver.c:55: return;
	ld	a, (_write_index)
	inc	a
	and	$07
	ld	c, a
;source-doc/keyboard/kyb_driver.c:56:
	ld	hl,_read_index
	ld	a, (hl)
	sub	c
	ret	Z
;source-doc/keyboard/kyb_driver.c:57: uint8_t next_write_index = (write_index + 1) & KEYBOARD_BUFFER_SIZE_MASK;
	ld	hl,(_write_index)
	ld	h,$00
	ld	de,_buffer
	add	hl,de
	ld	a,b
	ld	(hl),a
	ld	hl,_write_index
;source-doc/keyboard/kyb_driver.c:58: if (next_write_index != read_index) { // Check if buffer is not full
	ld	(hl), c
l_keyboard_buf_put_00112:
;source-doc/keyboard/kyb_driver.c:60: write_index         = next_write_index;
	ret
;source-doc/keyboard/kyb_driver.c:62: }
; ---------------------------------
; Function usb_kyb_status
; ---------------------------------
_usb_kyb_status:
;source-doc/keyboard/kyb_driver.c:63:
	DI
;source-doc/keyboard/kyb_driver.c:67: uint8_t size;
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	C,l_usb_kyb_status_00102
;source-doc/keyboard/kyb_driver.c:68:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	l_usb_kyb_status_00103
l_usb_kyb_status_00102:
;source-doc/keyboard/kyb_driver.c:70: size = write_index - read_index;
	ld	hl, (_read_index)
	ld	a,$08
	sub	l
	ld	hl, (_write_index)
	add	a, l
l_usb_kyb_status_00103:
;source-doc/keyboard/kyb_driver.c:72: size = KEYBOARD_BUFFER_SIZE - read_index + write_index;
	EI
;source-doc/keyboard/kyb_driver.c:73:
;source-doc/keyboard/kyb_driver.c:74: EI;
	ret
;source-doc/keyboard/kyb_driver.c:76: }
; ---------------------------------
; Function usb_kyb_read
; ---------------------------------
_usb_kyb_read:
;source-doc/keyboard/kyb_driver.c:77:
	ld	a,(_write_index)
	ld	hl,_read_index
	sub	(hl)
	jr	NZ,l_usb_kyb_read_00102
;source-doc/keyboard/kyb_driver.c:78: uint16_t usb_kyb_read() {
	ld	hl,$ff00
	jr	l_usb_kyb_read_00103
l_usb_kyb_read_00102:
;source-doc/keyboard/kyb_driver.c:80: return $FF00;               // H = -1, L = 0
	DI
;source-doc/keyboard/kyb_driver.c:81:
	ld	hl,(_read_index)
	ld	h,$00
	ld	bc,_buffer
	add	hl,bc
	ld	a,(hl)
	ld	c,l
	ld	b,h
	ld	hl,_read_index
	ld	l, a
;source-doc/keyboard/kyb_driver.c:82: DI;
	ld	a, (_read_index)
	inc	a
	and	$07
	ld	(_read_index), a
;source-doc/keyboard/kyb_driver.c:83: const uint8_t c = buffer[read_index];
	EI
;source-doc/keyboard/kyb_driver.c:86:
	ld	h,$00
l_usb_kyb_read_00103:
;source-doc/keyboard/kyb_driver.c:87: /* H = 0, L = ascii char */
	ret
;source-doc/keyboard/kyb_driver.c:89: }
; ---------------------------------
; Function usb_kyb_flush
; ---------------------------------
_usb_kyb_flush:
;source-doc/keyboard/kyb_driver.c:90:
	DI
;source-doc/keyboard/kyb_driver.c:91: uint8_t usb_kyb_flush() __sdcccall(1) {
	xor	a
	ld	(_read_index),a
	ld	(_write_index),a
;source-doc/keyboard/kyb_driver.c:94:
	ld	de,_previous+0
;source-doc/keyboard/kyb_driver.c:95: uint8_t  i = sizeof(previous);
;source-doc/keyboard/kyb_driver.c:96: uint8_t *a = (uint8_t *)previous;
	ld	b,$08
	ld	hl,_report
l_usb_kyb_flush_00101:
;source-doc/keyboard/kyb_driver.c:97: uint8_t *b = (uint8_t *)report;
	xor	a
	ld	(de), a
	inc	de
;source-doc/keyboard/kyb_driver.c:98: do {
	ld	(hl),$00
	inc	hl
;source-doc/keyboard/kyb_driver.c:99: *a++ = 0;
	djnz	l_usb_kyb_flush_00101
;source-doc/keyboard/kyb_driver.c:101: } while (--i != 0);
	EI
;source-doc/keyboard/kyb_driver.c:103: EI;
	xor	a
;source-doc/keyboard/kyb_driver.c:104:
	ret
;source-doc/keyboard/kyb_driver.c:106: }
; ---------------------------------
; Function usb_kyb_tick
; ---------------------------------
_usb_kyb_tick:
;source-doc/keyboard/kyb_driver.c:109: usb_error result;
	ld	hl,_in_critical_usb_section
	ld	a, (hl)
	or	a
;source-doc/keyboard/kyb_driver.c:110:
	jr	NZ,l_usb_kyb_tick_00112
;././source-doc/base-drv//ch376.h:108: #define TRACE_USB_ERROR(result)
	ld	l,$0b
	call	_ch_command
;././source-doc/base-drv//ch376.h:109:
	ld	a,$25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;././source-doc/base-drv//ch376.h:110: #endif
	ld	a,$1f
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/keyboard/kyb_driver.c:113:
	ld	bc,_report+0
	ld	hl, (_keyboard_config)
	ld	a,$08
	push	af
	inc	sp
	push	bc
	push	hl
	call	_usbdev_dat_in_trnsfer_0
	pop	af
	pop	af
	inc	sp
;././source-doc/base-drv//ch376.h:108: #define TRACE_USB_ERROR(result)
	push	hl
	ld	l,$0b
	call	_ch_command
	pop	hl
;././source-doc/base-drv//ch376.h:109:
	ld	a,$25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;././source-doc/base-drv//ch376.h:110: #endif
	ld	a,$df
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/keyboard/kyb_driver.c:115: result = usbdev_dat_in_trnsfer_0((device_config *)keyboard_config, (uint8_t *)&report, 8);
	ld	a, l
	or	a
	jr	NZ,l_usb_kyb_tick_00112
;source-doc/keyboard/kyb_driver.c:116: ch_configure_nak_retry_3s();
	call	_report_diff
	or	a
	jr	Z,l_usb_kyb_tick_00112
;source-doc/keyboard/kyb_driver.c:118: if (report_diff()) {
	ld	b,$06
l_usb_kyb_tick_00103:
;source-doc/keyboard/kyb_driver.c:119: uint8_t i = 6;
	ld	a, b
	dec	a
	push	bc
	call	_keyboard_buf_put
	pop	bc
;source-doc/keyboard/kyb_driver.c:120: do {
	djnz	l_usb_kyb_tick_00103
;source-doc/keyboard/kyb_driver.c:121: keyboard_buf_put(i - 1);
	ld	de,_previous
	ld	bc,$0008
	ld	hl,_report
	ldir
l_usb_kyb_tick_00112:
;source-doc/keyboard/kyb_driver.c:124: }
	ret
;source-doc/keyboard/kyb_driver.c:126: }
; ---------------------------------
; Function usb_kyb_init
; ---------------------------------
_usb_kyb_init:
;source-doc/keyboard/kyb_driver.c:127:
	call	_get_usb_device_config
	ex	de, hl
	ld	(_keyboard_config), hl
;source-doc/keyboard/kyb_driver.c:129: keyboard_config = (device_config_keyboard *)get_usb_device_config(dev_index);
	ld	hl,_keyboard_config + 1
	ld	a, (hl)
	dec	hl
	or	(hl)
;source-doc/keyboard/kyb_driver.c:130:
	ret	Z
;source-doc/keyboard/kyb_driver.c:132: return;
	ld	a,$01
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_protocol
;source-doc/keyboard/kyb_driver.c:133:
	ld	a,$80
	push	af
	inc	sp
	ld	hl, (_keyboard_config)
	call	_hid_set_idle
;source-doc/keyboard/kyb_driver.c:134: hid_set_protocol(keyboard_config, 1);
	ret
_caps_lock_engaged:
	DEFB +$01
_keyboard_config:
	DEFW +$0000
_buffer:
	DEFB +$00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
_write_index:
	DEFB +$00
_read_index:
	DEFB +$00
_report:
	DEFB +$00
	DEFB +$00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
_previous:
	DEFB +$00
	DEFB +$00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
