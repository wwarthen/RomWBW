;
; Generated from source-doc/base-drv/./usb_state.c.asm -- not to be modify directly
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
;source-doc/base-drv/./usb_state.c:13: device_config *find_device_config(const usb_device_type requested_type) {
; ---------------------------------
; Function find_device_config
; ---------------------------------
_find_device_config:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./usb_state.c:14: _usb_state *const p = get_usb_work_area();
;source-doc/base-drv/./usb_state.c:16: const device_config *p_config = first_device_config(p);
	ld	hl,_x
	call	_first_device_config
;source-doc/base-drv/./usb_state.c:17: while (p_config) {
l_find_device_config_00103:
	ld	a, d
	or	e
	jr	Z,l_find_device_config_00105
;source-doc/base-drv/./usb_state.c:18: const uint8_t type = p_config->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	ld	c, a
;source-doc/base-drv/./usb_state.c:20: if (type == requested_type)
	ld	a,(ix+4)
	sub	c
	jr	NZ,l_find_device_config_00102
;source-doc/base-drv/./usb_state.c:21: return (device_config *)p_config;
	ex	de, hl
	jr	l_find_device_config_00106
l_find_device_config_00102:
;source-doc/base-drv/./usb_state.c:23: p_config = next_device_config(p, p_config);
	ld	hl,_x
	call	_next_device_config
	jr	l_find_device_config_00103
l_find_device_config_00105:
;source-doc/base-drv/./usb_state.c:26: return NULL;
	ld	hl,0x0000
l_find_device_config_00106:
;source-doc/base-drv/./usb_state.c:27: }
	pop	ix
	ret
_device_config_sizes:
	DEFB +0x00
	DEFB +0x11
	DEFB +0x11
	DEFB +0x0c
	DEFB +0x06
	DEFB 0x00
	DEFB 0x00
;source-doc/base-drv/./usb_state.c:30: device_config *find_first_free(void) {
; ---------------------------------
; Function find_first_free
; ---------------------------------
_find_first_free:
;source-doc/base-drv/./usb_state.c:31: _usb_state *const boot_state = get_usb_work_area();
;source-doc/base-drv/./usb_state.c:34: device_config *p = first_device_config(boot_state);
	ld	hl,_x
	call	_first_device_config
;source-doc/base-drv/./usb_state.c:35: while (p) {
l_find_first_free_00103:
	ld	a, d
	or	e
	jr	Z,l_find_first_free_00105
;source-doc/base-drv/./usb_state.c:36: if (p->type == 0)
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	jr	NZ,l_find_first_free_00102
;source-doc/base-drv/./usb_state.c:37: return p;
	ex	de, hl
	jr	l_find_first_free_00106
l_find_first_free_00102:
;source-doc/base-drv/./usb_state.c:39: p = next_device_config(boot_state, p);
	ld	hl,_x
	call	_next_device_config
	jr	l_find_first_free_00103
l_find_first_free_00105:
;source-doc/base-drv/./usb_state.c:42: return NULL;
	ld	hl,0x0000
l_find_first_free_00106:
;source-doc/base-drv/./usb_state.c:43: }
	ret
;source-doc/base-drv/./usb_state.c:45: device_config *first_device_config(const _usb_state *const p) __sdcccall(1) { return (device_config *)&p->device_configs[0]; }
; ---------------------------------
; Function first_device_config
; ---------------------------------
_first_device_config:
	ex	de, hl
	inc	de
	inc	de
	ret
;source-doc/base-drv/./usb_state.c:47: device_config *next_device_config(const _usb_state *const usb_state, const device_config *const p) __sdcccall(1) {
; ---------------------------------
; Function next_device_config
; ---------------------------------
_next_device_config:
	ld	c, l
	ld	b, h
;source-doc/base-drv/./usb_state.c:48: if (p->type == 0)
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	jr	NZ,l_next_device_config_00102
;source-doc/base-drv/./usb_state.c:49: return NULL;
	ld	de,0x0000
	jr	l_next_device_config_00105
l_next_device_config_00102:
;source-doc/base-drv/./usb_state.c:51: const uint8_t size = device_config_sizes[p->type];
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	add	a, +((_device_config_sizes) & 0xFF)
	ld	l, a
	ld	a,0x00
	adc	a, +((_device_config_sizes) / 256)
	ld	h, a
	ld	l, (hl)
;source-doc/base-drv/./usb_state.c:58: const uint8_t       *_p     = (uint8_t *)p;
;source-doc/base-drv/./usb_state.c:59: device_config *const result = (device_config *)(_p + size);
	ld	h,0x00
	add	hl, de
	ex	de, hl
;source-doc/base-drv/./usb_state.c:61: if (result >= (device_config *)&usb_state->device_configs_end)
	ld	hl,0x0068
	add	hl, bc
	ld	a, e
	sub	l
	ld	a, d
	sbc	a, h
	ret	C
;source-doc/base-drv/./usb_state.c:62: return NULL;
	ld	de,0x0000
;source-doc/base-drv/./usb_state.c:64: return result;
l_next_device_config_00105:
;source-doc/base-drv/./usb_state.c:65: }
	ret
;source-doc/base-drv/./usb_state.c:68: device_config *get_usb_device_config(const uint8_t device_index) __sdcccall(1) {
; ---------------------------------
; Function get_usb_device_config
; ---------------------------------
_get_usb_device_config:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	ld	(ix-1),a
;source-doc/base-drv/./usb_state.c:69: const _usb_state *const usb_state = get_usb_work_area();
;source-doc/base-drv/./usb_state.c:71: uint8_t counter = 1;
	ld	(ix-2),0x01
;source-doc/base-drv/./usb_state.c:73: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	ld	hl,_x
	call	_first_device_config
	ld	c,0x01
l_get_usb_device_config_00112:
	ld	a, d
	or	e
	jr	Z,l_get_usb_device_config_00105
;source-doc/base-drv/./usb_state.c:74: if (p->type == USB_IS_FLOPPY) {
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	dec	a
	jr	NZ,l_get_usb_device_config_00113
;source-doc/base-drv/./usb_state.c:75: if (counter == device_index)
	ld	a,(ix-1)
	sub	c
;source-doc/base-drv/./usb_state.c:76: return p;
	jr	Z,l_get_usb_device_config_00117
;source-doc/base-drv/./usb_state.c:77: counter++;
	inc	c
	ld	(ix-2),c
l_get_usb_device_config_00113:
;source-doc/base-drv/./usb_state.c:73: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	push	bc
	ld	hl,_x
	call	_next_device_config
	pop	bc
	jr	l_get_usb_device_config_00112
l_get_usb_device_config_00105:
;source-doc/base-drv/./usb_state.c:81: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	ld	hl,_x
	call	_first_device_config
	ld	c,(ix-2)
l_get_usb_device_config_00115:
	ld	a, d
	or	e
	jr	Z,l_get_usb_device_config_00110
;source-doc/base-drv/./usb_state.c:82: if (p->type == USB_IS_MASS_STORAGE) {
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	sub	0x02
	jr	NZ,l_get_usb_device_config_00116
;source-doc/base-drv/./usb_state.c:83: if (counter == device_index)
	ld	a,(ix-1)
	sub	c
;source-doc/base-drv/./usb_state.c:84: return p;
	jr	Z,l_get_usb_device_config_00117
;source-doc/base-drv/./usb_state.c:85: counter++;
	inc	c
l_get_usb_device_config_00116:
;source-doc/base-drv/./usb_state.c:81: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	push	bc
	ld	hl,_x
	call	_next_device_config
	pop	bc
	jr	l_get_usb_device_config_00115
l_get_usb_device_config_00110:
;source-doc/base-drv/./usb_state.c:89: return NULL; // is not a usb device
	ld	de,0x0000
l_get_usb_device_config_00117:
;source-doc/base-drv/./usb_state.c:90: }
	ld	sp, ix
	pop	ix
	ret
