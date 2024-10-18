;
; Generated from source-doc/keyboard/./kyb-init.c.asm -- not to be modify directly
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
;source-doc/keyboard/./kyb-init.c:8: void keyboard_init(void) {
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
;source-doc/keyboard/./kyb-init.c:10: uint8_t index = 1;
;source-doc/keyboard/./kyb-init.c:11: do {
	ld	bc,0x0101
l_keyboard_init_00105:
;source-doc/keyboard/./kyb-init.c:12: device_config_keyboard *const keyboard_config = (device_config_keyboard *)get_usb_device_config(index);
	push	bc
	ld	a, b
	call	_get_usb_device_config
	pop	bc
;source-doc/keyboard/./kyb-init.c:14: if (keyboard_config == NULL)
	ld	a, d
	or	e
	jr	Z,l_keyboard_init_00107
;source-doc/keyboard/./kyb-init.c:17: const usb_device_type t = keyboard_config->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/keyboard/./kyb-init.c:19: if (t == USB_IS_KEYBOARD) {
	sub	0x04
	jr	NZ,l_keyboard_init_00106
;source-doc/keyboard/./kyb-init.c:20: print_string("\r\nUSB: KEYBOARD @ $");
	push	bc
	push	de
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	de
	pop	bc
;source-doc/keyboard/./kyb-init.c:21: print_uint16(index);
	ld	h,0x00
	push	de
	ld	l, c
	call	_print_uint16
	ld	hl,kyb_init_str_1
	call	_print_string
	pop	de
;source-doc/keyboard/./kyb-init.c:25: hid_set_protocol(keyboard_config, 1);
	push	de
	ld	a,0x01
	push	af
	inc	sp
	ex	de,hl
	call	_hid_set_protocol
	pop	de
;source-doc/keyboard/./kyb-init.c:26: hid_set_idle(keyboard_config, 0x80);
	ld	a,0x80
	push	af
	inc	sp
	ex	de, hl
	call	_hid_set_idle
;source-doc/keyboard/./kyb-init.c:27: return;
	jr	l_keyboard_init_00108
l_keyboard_init_00106:
;source-doc/keyboard/./kyb-init.c:29: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	b
	ld	a,b
	ld	c,a
	sub	0x07
	jr	NZ,l_keyboard_init_00105
l_keyboard_init_00107:
;source-doc/keyboard/./kyb-init.c:31: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	ld	hl,kyb_init_str_2
	jp	_print_string
l_keyboard_init_00108:
;source-doc/keyboard/./kyb-init.c:32: }
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
