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
;source-doc/keyboard/class_hid_keyboard.c:333: };
; ---------------------------------
; Function scancode_to_char
; ---------------------------------
_scancode_to_char:
	ld	c, a
;source-doc/keyboard/class_hid_keyboard.c:334:
	ld	a,l
	ld	e,l
	sub	0x80
	jr	C,l_scancode_to_char_00102
;source-doc/keyboard/class_hid_keyboard.c:335: char scancode_to_char(const uint8_t modifier_keys, const uint8_t code) __sdcccall(1) {
	xor	a
	jr	l_scancode_to_char_00105
l_scancode_to_char_00102:
;source-doc/keyboard/class_hid_keyboard.c:337: return 0;
	ld	a, c
	and	0x22
	jr	Z,l_scancode_to_char_00104
;source-doc/keyboard/class_hid_keyboard.c:338:
	ld	d,0x00
	ld	hl,_scancodes_shift_table
	add	hl, de
	ld	a, (hl)
	jr	l_scancode_to_char_00105
l_scancode_to_char_00104:
;source-doc/keyboard/class_hid_keyboard.c:340: return scancodes_shift_table[code];
	ld	d,0x00
	ld	hl,_scancodes_table
	add	hl, de
	ld	a, (hl)
l_scancode_to_char_00105:
;source-doc/keyboard/class_hid_keyboard.c:341:
	ret
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
