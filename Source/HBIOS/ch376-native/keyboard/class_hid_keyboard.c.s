;
; Generated from source-doc/keyboard/class_hid_keyboard.c.asm -- not to be modify directly
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
_scancodes_shift_table:
	DEFS 128
_scancodes_table:
	DEFS 128
	
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
;source-doc/keyboard/class_hid_keyboard.c:337: };
; ---------------------------------
; Function char_with_caps_lock
; ---------------------------------
_char_with_caps_lock:
	ld	c, a
;source-doc/keyboard/class_hid_keyboard.c:338:
	ld	hl,_caps_lock_engaged
	bit	0, (hl)
	jr	NZ,l_char_with_caps_lock_00102
;source-doc/keyboard/class_hid_keyboard.c:339: char char_with_caps_lock(const char c) __sdcccall(1) {
	ld	a, c
	jr	l_char_with_caps_lock_00109
l_char_with_caps_lock_00102:
;source-doc/keyboard/class_hid_keyboard.c:341: return c;
	ld	a, c
	sub	0x41
	jr	C,l_char_with_caps_lock_00104
	ld	a,0x5a
	sub	c
	jr	C,l_char_with_caps_lock_00104
;source-doc/keyboard/class_hid_keyboard.c:342:
	ld	a, c
	add	a,0x20
	jr	l_char_with_caps_lock_00109
l_char_with_caps_lock_00104:
;source-doc/keyboard/class_hid_keyboard.c:344: return c - 'A' + 'a';
	ld	a, c
	sub	0x61
	jr	C,l_char_with_caps_lock_00107
	ld	a,0x7a
	sub	c
	jr	C,l_char_with_caps_lock_00107
;source-doc/keyboard/class_hid_keyboard.c:345:
	ld	a, c
	add	a,0xe0
	jr	l_char_with_caps_lock_00109
l_char_with_caps_lock_00107:
;source-doc/keyboard/class_hid_keyboard.c:347: return c - 'a' + 'A';
	ld	a, c
l_char_with_caps_lock_00109:
;source-doc/keyboard/class_hid_keyboard.c:348:
	ret
;source-doc/keyboard/class_hid_keyboard.c:350: }
; ---------------------------------
; Function scancode_to_char
; ---------------------------------
_scancode_to_char:
	ld	c, a
;source-doc/keyboard/class_hid_keyboard.c:351:
	ld	a,l
	ld	e,l
	sub	0x80
	jr	C,l_scancode_to_char_00102
;source-doc/keyboard/class_hid_keyboard.c:352: char scancode_to_char(const uint8_t modifier_keys, const uint8_t code) __sdcccall(1) {
	xor	a
	jr	l_scancode_to_char_00123
l_scancode_to_char_00102:
;source-doc/keyboard/class_hid_keyboard.c:354: return 0;
	ld	a, c
	and	0x11
	jr	Z,l_scancode_to_char_00120
;source-doc/keyboard/class_hid_keyboard.c:355:
	ld	a, e
	sub	0x04
	jr	C,l_scancode_to_char_00104
	ld	a,0x1d
	sub	e
	jr	C,l_scancode_to_char_00104
;source-doc/keyboard/class_hid_keyboard.c:356: if ((modifier_keys & (KEY_MOD_LCTRL | KEY_MOD_RCTRL))) {
	ld	a, e
	add	a,0xfd
	jr	l_scancode_to_char_00123
l_scancode_to_char_00104:
;source-doc/keyboard/class_hid_keyboard.c:358: return code - 3;
	ld	a,e
	cp	0x1f
	jr	Z,l_scancode_to_char_00106
	sub	0x2c
	jr	NZ,l_scancode_to_char_00107
l_scancode_to_char_00106:
;source-doc/keyboard/class_hid_keyboard.c:359:
	xor	a
	jr	l_scancode_to_char_00123
l_scancode_to_char_00107:
;source-doc/keyboard/class_hid_keyboard.c:361: return 0;
	ld	a, e
	sub	0x2f
	jr	NZ,l_scancode_to_char_00110
;source-doc/keyboard/class_hid_keyboard.c:362:
	ld	a,0x1b
	jr	l_scancode_to_char_00123
l_scancode_to_char_00110:
;source-doc/keyboard/class_hid_keyboard.c:364: return 27;
	ld	a, e
	sub	0x31
	jr	NZ,l_scancode_to_char_00112
;source-doc/keyboard/class_hid_keyboard.c:365:
	ld	a,0x1c
	jr	l_scancode_to_char_00123
l_scancode_to_char_00112:
;source-doc/keyboard/class_hid_keyboard.c:367: return 28;
	ld	a, e
	sub	0x30
	jr	NZ,l_scancode_to_char_00114
;source-doc/keyboard/class_hid_keyboard.c:368:
	ld	a,0x1d
	jr	l_scancode_to_char_00123
l_scancode_to_char_00114:
;source-doc/keyboard/class_hid_keyboard.c:370: return 29;
	ld	a, e
	sub	0x23
	jr	NZ,l_scancode_to_char_00116
;source-doc/keyboard/class_hid_keyboard.c:371:
	ld	a,0x1e
	jr	l_scancode_to_char_00123
l_scancode_to_char_00116:
;source-doc/keyboard/class_hid_keyboard.c:373: return 30;
	ld	a, e
	sub	0x2d
	jr	NZ,l_scancode_to_char_00120
;source-doc/keyboard/class_hid_keyboard.c:374:
	ld	a,0x1f
	jr	l_scancode_to_char_00123
l_scancode_to_char_00120:
;source-doc/keyboard/class_hid_keyboard.c:377: }
	ld	a, c
	and	0x22
	jr	Z,l_scancode_to_char_00122
;source-doc/keyboard/class_hid_keyboard.c:378:
	ld	d,0x00
	ld	hl,_scancodes_shift_table
	add	hl, de
	ld	a,(hl)
	ld	c,a
	jp	_char_with_caps_lock
l_scancode_to_char_00122:
;source-doc/keyboard/class_hid_keyboard.c:380: return char_with_caps_lock(scancodes_shift_table[code]);
	ld	d,0x00
	ld	hl,_scancodes_table
	add	hl, de
	ld	a,(hl)
	ld	c,a
	jp	_char_with_caps_lock
l_scancode_to_char_00123:
;source-doc/keyboard/class_hid_keyboard.c:381:
	ret
_caps_lock_engaged:
	DEFB +0x01
_scancodes_shift_table:
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x41
	DEFB +0x42
	DEFB +0x43
	DEFB +0x44
	DEFB +0x45
	DEFB +0x46
	DEFB +0x47
	DEFB +0x48
	DEFB +0x49
	DEFB +0x4a
	DEFB +0x4b
	DEFB +0x4c
	DEFB +0x4d
	DEFB +0x4e
	DEFB +0x4f
	DEFB +0x50
	DEFB +0x51
	DEFB +0x52
	DEFB +0x53
	DEFB +0x54
	DEFB +0x55
	DEFB +0x56
	DEFB +0x57
	DEFB +0x58
	DEFB +0x59
	DEFB +0x5a
	DEFB +0x21
	DEFB +0x40
	DEFB +0x23
	DEFB +0x24
	DEFB +0x25
	DEFB +0x5e
	DEFB +0x26
	DEFB +0x2a
	DEFB +0x28
	DEFB +0x29
	DEFB +0x0d
	DEFB +0x1b
	DEFB +0x08
	DEFB +0x09
	DEFB +0x20
	DEFB +0x5f
	DEFB +0x2b
	DEFB +0x7b
	DEFB +0x7d
	DEFB +0x7c
	DEFB +0x7e
	DEFB +0x3a
	DEFB +0x22
	DEFB +0x7e
	DEFB +0x3c
	DEFB +0x3e
	DEFB +0x3f
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x2f
	DEFB +0x2a
	DEFB +0x2d
	DEFB +0x2b
	DEFB +0x0d
	DEFB +0x31
	DEFB +0x32
	DEFB +0x33
	DEFB +0x34
	DEFB +0x35
	DEFB +0x36
	DEFB +0x37
	DEFB +0x38
	DEFB +0x39
	DEFB +0x30
	DEFB +0x2e
	DEFB +0x5c
	DEFB +0x00
	DEFB +0x00
	DEFB +0x3d
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
_scancodes_table:
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x61
	DEFB +0x62
	DEFB +0x63
	DEFB +0x64
	DEFB +0x65
	DEFB +0x66
	DEFB +0x67
	DEFB +0x68
	DEFB +0x69
	DEFB +0x6a
	DEFB +0x6b
	DEFB +0x6c
	DEFB +0x6d
	DEFB +0x6e
	DEFB +0x6f
	DEFB +0x70
	DEFB +0x71
	DEFB +0x72
	DEFB +0x73
	DEFB +0x74
	DEFB +0x75
	DEFB +0x76
	DEFB +0x77
	DEFB +0x78
	DEFB +0x79
	DEFB +0x7a
	DEFB +0x31
	DEFB +0x32
	DEFB +0x33
	DEFB +0x34
	DEFB +0x35
	DEFB +0x36
	DEFB +0x37
	DEFB +0x38
	DEFB +0x39
	DEFB +0x30
	DEFB +0x0d
	DEFB +0x1b
	DEFB +0x08
	DEFB +0x09
	DEFB +0x20
	DEFB +0x2d
	DEFB +0x3d
	DEFB +0x5b
	DEFB +0x5d
	DEFB +0x5c
	DEFB +0x23
	DEFB +0x3b
	DEFB +0x27
	DEFB +0x60
	DEFB +0x2c
	DEFB +0x2e
	DEFB +0x2f
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x2f
	DEFB +0x2a
	DEFB +0x2d
	DEFB +0x2b
	DEFB +0x0d
	DEFB +0x31
	DEFB +0x32
	DEFB +0x33
	DEFB +0x34
	DEFB +0x35
	DEFB +0x36
	DEFB +0x37
	DEFB +0x38
	DEFB +0x39
	DEFB +0x30
	DEFB +0x2e
	DEFB +0x5c
	DEFB +0x00
	DEFB +0x00
	DEFB +0x3d
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
