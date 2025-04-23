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
;source-doc/keyboard/kyb-init.c:6: void keyboard_init(void) __sdcccall(1) {
; ---------------------------------
; Function keyboard_init
; ---------------------------------
_keyboard_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/keyboard/kyb-init.c:9: do {
	ld	(ix-1),0x01
l_keyboard_init_00103:
;source-doc/keyboard/kyb-init.c:10: usb_device_type t = usb_get_device_type(index);
	ld	l,(ix-1)
	ld	h,0x00
	push	hl
	push	hl
	call	_usb_get_device_type
	pop	af
	ld	a, l
	pop	hl
;source-doc/keyboard/kyb-init.c:12: if (t == USB_IS_KEYBOARD) {
	sub	0x04
	jr	NZ,l_keyboard_init_00104
;source-doc/keyboard/kyb-init.c:13: print_string("\r\nUSB: KEYBOARD @ $");
	push	hl
	ld	hl,kyb_init_str_0
	call	_print_string
	pop	hl
;source-doc/keyboard/kyb-init.c:14: print_uint16(index);
	call	_print_uint16
;source-doc/keyboard/kyb-init.c:15: print_string(" $");
	ld	hl,kyb_init_str_1
	call	_print_string
;source-doc/keyboard/kyb-init.c:17: usb_kyb_init(index);
	ld	a,(ix-1)
	call	_usb_kyb_init
l_keyboard_init_00104:
;source-doc/keyboard/kyb-init.c:19: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_keyboard_init_00103
;source-doc/keyboard/kyb-init.c:21: print_string("\r\nUSB: KEYBOARD: NOT FOUND$");
	ld	hl,kyb_init_str_2
	call	_print_string
;source-doc/keyboard/kyb-init.c:22: }
	inc	sp
	pop	ix
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
