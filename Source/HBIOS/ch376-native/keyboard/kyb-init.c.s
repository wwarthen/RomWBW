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
;source-doc/keyboard/kyb-init.c:6: uint8_t keyboard_init(void) __sdcccall(1) {
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/keyboard/kyb-init.c:7: uint8_t index = 1;
;source-doc/keyboard/kyb-init.c:9: do {
	ld	c,$01
	ld	(ix-1),c
l_keyboard_init_00103:
;source-doc/keyboard/kyb-init.c:10: usb_device_type t = usb_get_device_type(index);
	ld	e, c
	ld	d,$00
	push	bc
	push	de
	push	de
	call	_usb_get_device_type
	pop	af
	ld	a, l
	pop	de
	pop	bc
;source-doc/keyboard/kyb-init.c:12: if (t == USB_IS_KEYBOARD) {
	sub	$04
	jr	NZ,l_keyboard_init_00104
;source-doc/keyboard/kyb-init.c:13: print_string("\r\nUSB: KEYBOARD @ $");
	push	de
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	de
;source-doc/keyboard/kyb-init.c:14: print_uint16(index);
	ex	de, hl
	call	_print_uint16
;source-doc/keyboard/kyb-init.c:15: print_string(" $");
	ld	hl,kyb_init_str_1
	call	_print_string
;source-doc/keyboard/kyb-init.c:17: usb_kyb_init(index);
	ld	a,(ix-1)
	call	_usb_kyb_init
;source-doc/keyboard/kyb-init.c:18: return 1;
	ld	a,$01
	jr	l_keyboard_init_00106
l_keyboard_init_00104:
;source-doc/keyboard/kyb-init.c:20: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	c
	ld	(ix-1),c
	ld	a, c
	sub	$07
	jr	NZ,l_keyboard_init_00103
;source-doc/keyboard/kyb-init.c:22: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	ld	hl,kyb_init_str_2
	call	_print_string
;source-doc/keyboard/kyb-init.c:24: return 0;
	xor	a
l_keyboard_init_00106:
;source-doc/keyboard/kyb-init.c:25: }
	inc	sp
	pop	ix
	ret
kyb_init_str_0:
	DEFB $0d
	DEFB $0a
	DEFM "USB: KEYBOARD @ $"
	DEFB $00
kyb_init_str_1:
	DEFM " $"
	DEFB $00
kyb_init_str_2:
	DEFB $0d
	DEFB $0a
	DEFM "USB: KEYBOARD: NOT FOUND$"
	DEFB $00
