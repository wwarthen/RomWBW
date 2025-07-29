;
; Generated from source-doc/keyboard/class_hid_keyboard.c.asm -- not to be modify directly
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
;source-doc/keyboard/class_hid_keyboard.c:334: };
; ---------------------------------
; Function char_with_caps_lock
; ---------------------------------
_char_with_caps_lock:
;source-doc/keyboard/class_hid_keyboard.c:335:
	bit	0, l
;source-doc/keyboard/class_hid_keyboard.c:336: static char char_with_caps_lock(const char c, const bool caps_lock_engaged) __sdcccall(1) {
	jr	Z,l_char_with_caps_lock_00109
;source-doc/keyboard/class_hid_keyboard.c:338: return c;
	cp	$41
	jr	C,l_char_with_caps_lock_00104
	cp	$5b
	jr	NC,l_char_with_caps_lock_00104
;source-doc/keyboard/class_hid_keyboard.c:339:
	add	a,$20
	jr	l_char_with_caps_lock_00109
l_char_with_caps_lock_00104:
;source-doc/keyboard/class_hid_keyboard.c:341: return c - 'A' + 'a';
	cp	$61
	ret	C
	cp	$7b
	ret	NC
;source-doc/keyboard/class_hid_keyboard.c:342:
	add	a,$e0
;source-doc/keyboard/class_hid_keyboard.c:344: return c - 'a' + 'A';
l_char_with_caps_lock_00109:
;source-doc/keyboard/class_hid_keyboard.c:345:
	ret
;source-doc/keyboard/class_hid_keyboard.c:347: }
; ---------------------------------
; Function scancode_to_char
; ---------------------------------
_scancode_to_char:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/keyboard/class_hid_keyboard.c:348:
	ld	c,a
	ld	e,l
	and	$11
	jr	Z,l_scancode_to_char_00118
;source-doc/keyboard/class_hid_keyboard.c:349: char scancode_to_char(const uint8_t modifier_keys, const uint8_t code, const bool caps_lock_engaged) __sdcccall(1) {
	ld	a, e
	sub	$04
	jr	C,l_scancode_to_char_00102
	ld	a,$1d
	sub	e
	jr	C,l_scancode_to_char_00102
;source-doc/keyboard/class_hid_keyboard.c:350: if ((modifier_keys & (KEY_MOD_LCTRL | KEY_MOD_RCTRL))) {
	ld	a, e
	add	a,$fd
	jr	l_scancode_to_char_00121
l_scancode_to_char_00102:
;source-doc/keyboard/class_hid_keyboard.c:352: return code - 3;
	ld	a,e
	cp	$1f
	jr	Z,l_scancode_to_char_00104
	sub	$2c
	jr	NZ,l_scancode_to_char_00105
l_scancode_to_char_00104:
;source-doc/keyboard/class_hid_keyboard.c:353:
	xor	a
	jr	l_scancode_to_char_00121
l_scancode_to_char_00105:
;source-doc/keyboard/class_hid_keyboard.c:355: return 0;
	ld	a, e
	sub	$2f
	jr	NZ,l_scancode_to_char_00108
;source-doc/keyboard/class_hid_keyboard.c:356:
	ld	a,$1b
	jr	l_scancode_to_char_00121
l_scancode_to_char_00108:
;source-doc/keyboard/class_hid_keyboard.c:358: return 27;
	ld	a, e
	sub	$31
	jr	NZ,l_scancode_to_char_00110
;source-doc/keyboard/class_hid_keyboard.c:359:
	ld	a,$1c
	jr	l_scancode_to_char_00121
l_scancode_to_char_00110:
;source-doc/keyboard/class_hid_keyboard.c:361: return 28;
	ld	a, e
	sub	$30
	jr	NZ,l_scancode_to_char_00112
;source-doc/keyboard/class_hid_keyboard.c:362:
	ld	a,$1d
	jr	l_scancode_to_char_00121
l_scancode_to_char_00112:
;source-doc/keyboard/class_hid_keyboard.c:364: return 29;
	ld	a, e
	sub	$23
	jr	NZ,l_scancode_to_char_00114
;source-doc/keyboard/class_hid_keyboard.c:365:
	ld	a,$1e
	jr	l_scancode_to_char_00121
l_scancode_to_char_00114:
;source-doc/keyboard/class_hid_keyboard.c:367: return 30;
	ld	a, e
	sub	$2d
	jr	NZ,l_scancode_to_char_00118
;source-doc/keyboard/class_hid_keyboard.c:368:
	ld	a,$1f
	jr	l_scancode_to_char_00121
l_scancode_to_char_00118:
;source-doc/keyboard/class_hid_keyboard.c:371: }
	ld	a, c
	and	$22
	jr	Z,l_scancode_to_char_00120
;source-doc/keyboard/class_hid_keyboard.c:372:
	ld	d,$00
	ld	hl,_scancodes_shift_table
	add	hl, de
	ld	a, (hl)
	ld	l,(ix+4)
	call	_char_with_caps_lock
	jr	l_scancode_to_char_00121
l_scancode_to_char_00120:
;source-doc/keyboard/class_hid_keyboard.c:374: return char_with_caps_lock(scancodes_shift_table[code], caps_lock_engaged);
	ld	d,$00
	ld	hl,_scancodes_table
	add	hl, de
	ld	a, (hl)
	ld	l,(ix+4)
	call	_char_with_caps_lock
l_scancode_to_char_00121:
;source-doc/keyboard/class_hid_keyboard.c:375:
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
_scancodes_shift_table:
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$41
	DEFB +$42
	DEFB +$43
	DEFB +$44
	DEFB +$45
	DEFB +$46
	DEFB +$47
	DEFB +$48
	DEFB +$49
	DEFB +$4a
	DEFB +$4b
	DEFB +$4c
	DEFB +$4d
	DEFB +$4e
	DEFB +$4f
	DEFB +$50
	DEFB +$51
	DEFB +$52
	DEFB +$53
	DEFB +$54
	DEFB +$55
	DEFB +$56
	DEFB +$57
	DEFB +$58
	DEFB +$59
	DEFB +$5a
	DEFB +$21
	DEFB +$40
	DEFB +$23
	DEFB +$24
	DEFB +$25
	DEFB +$5e
	DEFB +$26
	DEFB +$2a
	DEFB +$28
	DEFB +$29
	DEFB +$0d
	DEFB +$1b
	DEFB +$08
	DEFB +$09
	DEFB +$20
	DEFB +$5f
	DEFB +$2b
	DEFB +$7b
	DEFB +$7d
	DEFB +$7c
	DEFB +$7e
	DEFB +$3a
	DEFB +$22
	DEFB +$7e
	DEFB +$3c
	DEFB +$3e
	DEFB +$3f
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$2f
	DEFB +$2a
	DEFB +$2d
	DEFB +$2b
	DEFB +$0d
	DEFB +$31
	DEFB +$32
	DEFB +$33
	DEFB +$34
	DEFB +$35
	DEFB +$36
	DEFB +$37
	DEFB +$38
	DEFB +$39
	DEFB +$30
	DEFB +$2e
	DEFB +$5c
	DEFB +$00
	DEFB +$00
	DEFB +$3d
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
_scancodes_table:
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$61
	DEFB +$62
	DEFB +$63
	DEFB +$64
	DEFB +$65
	DEFB +$66
	DEFB +$67
	DEFB +$68
	DEFB +$69
	DEFB +$6a
	DEFB +$6b
	DEFB +$6c
	DEFB +$6d
	DEFB +$6e
	DEFB +$6f
	DEFB +$70
	DEFB +$71
	DEFB +$72
	DEFB +$73
	DEFB +$74
	DEFB +$75
	DEFB +$76
	DEFB +$77
	DEFB +$78
	DEFB +$79
	DEFB +$7a
	DEFB +$31
	DEFB +$32
	DEFB +$33
	DEFB +$34
	DEFB +$35
	DEFB +$36
	DEFB +$37
	DEFB +$38
	DEFB +$39
	DEFB +$30
	DEFB +$0d
	DEFB +$1b
	DEFB +$08
	DEFB +$09
	DEFB +$20
	DEFB +$2d
	DEFB +$3d
	DEFB +$5b
	DEFB +$5d
	DEFB +$5c
	DEFB +$23
	DEFB +$3b
	DEFB +$27
	DEFB +$60
	DEFB +$2c
	DEFB +$2e
	DEFB +$2f
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$2f
	DEFB +$2a
	DEFB +$2d
	DEFB +$2b
	DEFB +$0d
	DEFB +$31
	DEFB +$32
	DEFB +$33
	DEFB +$34
	DEFB +$35
	DEFB +$36
	DEFB +$37
	DEFB +$38
	DEFB +$39
	DEFB +$30
	DEFB +$2e
	DEFB +$5c
	DEFB +$00
	DEFB +$00
	DEFB +$3d
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
