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
	ld	b, l
;source-doc/base-drv/ch376_init.c:5: uint16_t r = state;
	ld	e, b
;source-doc/base-drv/ch376_init.c:7: for (uint8_t i = 0; i < loop_counter; i++) {
	ld	d,0x00
	ld	c,d
l_wait_for_state_00108:
	ld	a, c
	sub	(ix-1)
	jr	NC,l_wait_for_state_00106
;source-doc/base-drv/ch376_init.c:8: if (state == desired_state)
	ld	a,(ix+4)
	sub	b
	jr	Z,l_wait_for_state_00106
;source-doc/base-drv/ch376_init.c:11: if (i & 1)
	bit	0, c
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
	push	bc
	inc	sp
	call	_usb_init
	inc	sp
	ex	de, hl
	pop	bc
;source-doc/base-drv/ch376_init.c:17: state = r & 255;
	ld	b, e
;source-doc/base-drv/ch376_init.c:7: for (uint8_t i = 0; i < loop_counter; i++) {
	inc	c
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
;source-doc/base-drv/ch376_init.c:23: static void _chnative_init(bool forced) {
; ---------------------------------
; Function _chnative_init
; ---------------------------------
__chnative_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/ch376_init.c:26: const uint8_t loop_counter = forced ? 40 : 5;
	bit	0,(ix+4)
	jr	Z,l__chnative_init_00113
	ld	a,0x28
	jr	l__chnative_init_00114
l__chnative_init_00113:
	ld	a,0x05
l__chnative_init_00114:
	ld	(ix-1),a
;source-doc/base-drv/ch376_init.c:28: print_string("\r\nCH376: *$");
	ld	hl,ch376_init_str_2
	call	_print_string
;source-doc/base-drv/ch376_init.c:30: r     = wait_for_state(loop_counter, state, 1);
	ld	a,0x01
	push	af
	inc	sp
	ld	l,0x00
	ld	a,(ix-1)
	call	_wait_for_state
	ld	b, e
;source-doc/base-drv/ch376_init.c:31: state = r & 255;
;source-doc/base-drv/ch376_init.c:33: print_string("\bPRESENT (VER $");
	push	bc
	ld	hl,ch376_init_str_3
	call	_print_string
;source-doc/base-drv/ch376_init.c:35: r     = usb_init(state);
	inc	sp
	call	_usb_init
	inc	sp
	ex	de, hl
;source-doc/base-drv/ch376_init.c:36: state = r & 255;
	ld	c, e
;source-doc/base-drv/ch376_init.c:37: if (state != 2) {
	ld	a, c
	sub	0x02
	jr	Z,l__chnative_init_00102
;source-doc/base-drv/ch376_init.c:38: print_string("\rCH376: $");
	ld	hl,ch376_init_str_4
	call	_print_string
;source-doc/base-drv/ch376_init.c:39: print_string("VERSION FAILURE\r\n$");
	ld	hl,ch376_init_str_5
	call	_print_string
;source-doc/base-drv/ch376_init.c:40: return;
	jr	l__chnative_init_00111
l__chnative_init_00102:
;source-doc/base-drv/ch376_init.c:43: print_hex(r >> 8);
	push	bc
	ld	l, d
	call	_print_hex
;source-doc/base-drv/ch376_init.c:44: print_string("); $");
	ld	hl,ch376_init_str_6
	call	_print_string
;source-doc/base-drv/ch376_init.c:46: print_string("USB: *$");
	ld	hl,ch376_init_str_7
	call	_print_string
	pop	bc
;source-doc/base-drv/ch376_init.c:48: r     = wait_for_state(loop_counter, state, 3);
	ld	a,0x03
	push	af
	inc	sp
	ld	l, c
	ld	a,(ix-1)
	call	_wait_for_state
	ld	b, e
;source-doc/base-drv/ch376_init.c:49: state = r & 255;
;source-doc/base-drv/ch376_init.c:51: if (state == 2) {
	ld	a, b
	sub	0x02
	jr	NZ,l__chnative_init_00104
;source-doc/base-drv/ch376_init.c:52: print_string("\bDISCONNECTED$");
	ld	hl,ch376_init_str_8
	call	_print_string
;source-doc/base-drv/ch376_init.c:53: return;
	jr	l__chnative_init_00111
l__chnative_init_00104:
;source-doc/base-drv/ch376_init.c:56: print_string("\bCONNECTED$");
	push	bc
	ld	hl,ch376_init_str_9
	call	_print_string
;source-doc/base-drv/ch376_init.c:59: r     = usb_init(state);
	inc	sp
	call	_usb_init
	inc	sp
	ex	de, hl
;source-doc/base-drv/ch376_init.c:60: state = r & 255;
	ld	b, e
;source-doc/base-drv/ch376_init.c:62: for (uint8_t i = 0; i < loop_counter; i++) {
	ld	c,0x00
l__chnative_init_00109:
	ld	a, c
	sub	(ix-1)
	jr	NC,l__chnative_init_00111
;source-doc/base-drv/ch376_init.c:63: if (r >> 8 != 0)
	ld	a,0x00
	or	d
	jr	NZ,l__chnative_init_00111
;source-doc/base-drv/ch376_init.c:66: print_string(".$");
	push	bc
	ld	hl,ch376_init_str_10
	call	_print_string
	pop	bc
;source-doc/base-drv/ch376_init.c:67: r     = usb_init(state);
	push	bc
	push	bc
	inc	sp
	call	_usb_init
	inc	sp
	ex	de, hl
	pop	bc
;source-doc/base-drv/ch376_init.c:68: state = r & 255;
	ld	b, e
;source-doc/base-drv/ch376_init.c:62: for (uint8_t i = 0; i < loop_counter; i++) {
	inc	c
	jr	l__chnative_init_00109
l__chnative_init_00111:
;source-doc/base-drv/ch376_init.c:70: }
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
	DEFM "); $"
	DEFB 0x00
ch376_init_str_7:
	DEFM "USB: *$"
	DEFB 0x00
ch376_init_str_8:
	DEFB 0x08
	DEFM "DISCONNECTED$"
	DEFB 0x00
ch376_init_str_9:
	DEFB 0x08
	DEFM "CONNECTED$"
	DEFB 0x00
ch376_init_str_10:
	DEFM ".$"
	DEFB 0x00
;source-doc/base-drv/ch376_init.c:72: void chnative_init_force(void) { _chnative_init(true); }
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
;source-doc/base-drv/ch376_init.c:74: void chnative_init(void) { _chnative_init(false); }
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
