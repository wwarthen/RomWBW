;
; Generated from source-doc/base-drv/ch376_init.c.asm -- not to be modify directly
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
;source-doc/base-drv/ch376_init.c:4: static uint16_t wait_for_state(const uint8_t loop_counter, uint8_t state, const uint8_t desired_state) __sdcccall(1) {
; ---------------------------------
; Function wait_for_state
; ---------------------------------
_wait_for_state:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
	ld	(ix-1),a
;source-doc/base-drv/ch376_init.c:5: uint16_t r = state;
	ld	c,l
	ld	e,l
;source-doc/base-drv/ch376_init.c:7: for (uint8_t i = 0; i < loop_counter; i++) {
	ld	d,0x00
	ld	b,d
l_wait_for_state_00108:
	ld	a, b
	sub	(ix-1)
	jr	NC,l_wait_for_state_00106
;source-doc/base-drv/ch376_init.c:8: if (state == desired_state)
	ld	a,(ix+4)
	sub	c
	jr	Z,l_wait_for_state_00106
;source-doc/base-drv/ch376_init.c:11: if (i & 1)
	bit	0, b
	jr	Z,l_wait_for_state_00104
;source-doc/base-drv/ch376_init.c:12: print_string("\b $");
	push	bc
	ld	hl,ch376_init_str_0
	call	_print_string
	pop	bc
	jr	l_wait_for_state_00105
l_wait_for_state_00104:
;source-doc/base-drv/ch376_init.c:14: print_string("\b*$");
	push	bc
	ld	hl,ch376_init_str_1
	call	_print_string
	pop	bc
l_wait_for_state_00105:
;source-doc/base-drv/ch376_init.c:16: r     = usb_init(state);
	push	bc
	ld	l, c
	call	_usb_init
	ex	de, hl
	pop	bc
;source-doc/base-drv/ch376_init.c:17: state = r & 255;
	ld	c, e
;source-doc/base-drv/ch376_init.c:7: for (uint8_t i = 0; i < loop_counter; i++) {
	inc	b
	jr	l_wait_for_state_00108
l_wait_for_state_00106:
;source-doc/base-drv/ch376_init.c:20: return r;
;source-doc/base-drv/ch376_init.c:21: }
	inc	sp
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
ch376_init_str_0:
	DEFB 0x08
	DEFM " $"
	DEFB 0x00
ch376_init_str_1:
	DEFB 0x08
	DEFM "*$"
	DEFB 0x00
;source-doc/base-drv/ch376_init.c:25: static void _chnative_init(bool forced) {
; ---------------------------------
; Function _chnative_init
; ---------------------------------
__chnative_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/ch376_init.c:28: const uint8_t loop_counter = forced ? 40 : 5;
	bit	0,(ix+4)
	jr	Z,l__chnative_init_00113
	ld	a,0x28
	jr	l__chnative_init_00114
l__chnative_init_00113:
	ld	a,0x05
l__chnative_init_00114:
	ld	(ix-1),a
;source-doc/base-drv/ch376_init.c:30: print_string("\r\nCH376: *$");
	ld	hl,ch376_init_str_2
	call	_print_string
;source-doc/base-drv/ch376_init.c:32: r     = wait_for_state(loop_counter, state, 1);
	ld	a,0x01
	push	af
	inc	sp
	ld	l,0x00
	ld	a,(ix-1)
	call	_wait_for_state
;source-doc/base-drv/ch376_init.c:33: state = r & 255;
;source-doc/base-drv/ch376_init.c:35: print_string("\bPRESENT (VER $");
	push	de
	ld	hl,ch376_init_str_3
	call	_print_string
	pop	de
;source-doc/base-drv/ch376_init.c:37: r     = usb_init(state);
	ld	l, e
	call	_usb_init
	ex	de, hl
;source-doc/base-drv/ch376_init.c:38: state = r & 255;
	ld	c, e
;source-doc/base-drv/ch376_init.c:39: if (state != 2) {
	ld	a, c
	sub	0x02
	jr	Z,l__chnative_init_00102
;source-doc/base-drv/ch376_init.c:40: print_string("\rCH376: $");
	ld	hl,ch376_init_str_4
	call	_print_string
;source-doc/base-drv/ch376_init.c:41: print_string("VERSION FAILURE\r\n$");
	ld	hl,ch376_init_str_5
	call	_print_string
;source-doc/base-drv/ch376_init.c:42: return;
	jr	l__chnative_init_00111
l__chnative_init_00102:
;source-doc/base-drv/ch376_init.c:45: print_hex(r >> 8);
	push	bc
	ld	l, d
	call	_print_hex
;source-doc/base-drv/ch376_init.c:46: print_string(ch376_driver_version);
	ld	hl,_ch376_driver_version
	call	_print_string
;source-doc/base-drv/ch376_init.c:48: print_string("USB: *$");
	ld	hl,ch376_init_str_6
	call	_print_string
	pop	bc
;source-doc/base-drv/ch376_init.c:50: r     = wait_for_state(loop_counter, state, 3);
	ld	a,0x03
	push	af
	inc	sp
	ld	l, c
	ld	a,(ix-1)
	call	_wait_for_state
;source-doc/base-drv/ch376_init.c:51: state = r & 255;
;source-doc/base-drv/ch376_init.c:53: if (state == 2) {
	ld	a, e
	sub	0x02
	jr	NZ,l__chnative_init_00104
;source-doc/base-drv/ch376_init.c:54: print_string("\bDISCONNECTED$");
	ld	hl,ch376_init_str_7
	call	_print_string
;source-doc/base-drv/ch376_init.c:55: return;
	jr	l__chnative_init_00111
l__chnative_init_00104:
;source-doc/base-drv/ch376_init.c:58: print_string("\bCONNECTED$");
	push	de
	ld	hl,ch376_init_str_8
	call	_print_string
	pop	de
;source-doc/base-drv/ch376_init.c:61: r     = usb_init(state);
	ld	l, e
	call	_usb_init
	ex	de, hl
;source-doc/base-drv/ch376_init.c:62: state = r & 255;
	ld	c, e
;source-doc/base-drv/ch376_init.c:64: for (uint8_t i = 0; i < loop_counter; i++) {
	ld	b,0x00
l__chnative_init_00109:
	ld	a, b
	sub	(ix-1)
	jr	NC,l__chnative_init_00111
;source-doc/base-drv/ch376_init.c:65: if (r >> 8 != 0)
	ld	a,0x00
	or	d
	jr	NZ,l__chnative_init_00111
;source-doc/base-drv/ch376_init.c:68: print_string(".$");
	push	bc
	ld	hl,ch376_init_str_9
	call	_print_string
	pop	bc
;source-doc/base-drv/ch376_init.c:69: r     = usb_init(state);
	push	bc
	ld	l, c
	call	_usb_init
	ex	de, hl
	pop	bc
;source-doc/base-drv/ch376_init.c:70: state = r & 255;
	ld	c, e
;source-doc/base-drv/ch376_init.c:64: for (uint8_t i = 0; i < loop_counter; i++) {
	inc	b
	jr	l__chnative_init_00109
l__chnative_init_00111:
;source-doc/base-drv/ch376_init.c:72: }
	inc	sp
	pop	ix
	ret
ch376_init_str_2:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "CH376: *$"
	DEFB 0x00
ch376_init_str_3:
	DEFB 0x08
	DEFM "PRESENT (VER $"
	DEFB 0x00
ch376_init_str_4:
	DEFB 0x0d
	DEFM "CH376: $"
	DEFB 0x00
ch376_init_str_5:
	DEFM "VERSION FAILURE"
	DEFB 0x0d
	DEFB 0x0a
	DEFM "$"
	DEFB 0x00
ch376_init_str_6:
	DEFM "USB: *$"
	DEFB 0x00
ch376_init_str_7:
	DEFB 0x08
	DEFM "DISCONNECTED$"
	DEFB 0x00
ch376_init_str_8:
	DEFB 0x08
	DEFM "CONNECTED$"
	DEFB 0x00
ch376_init_str_9:
	DEFM ".$"
	DEFB 0x00
;source-doc/base-drv/ch376_init.c:74: void chnative_init_force(void) { _chnative_init(true); }
; ---------------------------------
; Function chnative_init_force
; ---------------------------------
_chnative_init_force:
	ld	a,0x01
	push	af
	inc	sp
	call	__chnative_init
	inc	sp
	ret
;source-doc/base-drv/ch376_init.c:76: void chnative_init(void) { _chnative_init(false); }
; ---------------------------------
; Function chnative_init
; ---------------------------------
_chnative_init:
	xor	a
	push	af
	inc	sp
	call	__chnative_init
	inc	sp
	ret
