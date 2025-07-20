;
; Generated from source-doc/base-drv/usb_state.c.asm -- not to be modify directly
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
;source-doc/base-drv/usb_state.c:17: uint8_t count_of_devices(void) __sdcccall(1) {
; ---------------------------------
; Function count_of_devices
; ---------------------------------
_count_of_devices:
;source-doc/base-drv/usb_state.c:18: _usb_state *const p = get_usb_work_area();
;source-doc/base-drv/usb_state.c:22: const device_config *p_config = first_device_config(p);
	ld	hl,_x
	call	_first_device_config
;source-doc/base-drv/usb_state.c:23: while (p_config) {
	ld	c,$00
l_count_of_devices_00104:
	ld	a, d
	or	e
	jr	Z,l_count_of_devices_00106
;source-doc/base-drv/usb_state.c:24: const uint8_t type = p_config->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$0f
;source-doc/base-drv/usb_state.c:26: if (type != USB_IS_HUB && type)
	cp	$0f
	jr	Z,l_count_of_devices_00102
	or	a
	jr	Z,l_count_of_devices_00102
;source-doc/base-drv/usb_state.c:27: count++;
	inc	c
l_count_of_devices_00102:
;source-doc/base-drv/usb_state.c:30: p_config = next_device_config(p, p_config);
	push	bc
	ld	hl,_x
	call	_next_device_config
	pop	bc
	jr	l_count_of_devices_00104
l_count_of_devices_00106:
;source-doc/base-drv/usb_state.c:33: return count;
	ld	a, c
;source-doc/base-drv/usb_state.c:34: }
	ret
_device_config_sizes:
	DEFB +$00
	DEFB +$10
	DEFB +$10
	DEFB +$0c
	DEFB +$06
	DEFB $00
	DEFB $00
;source-doc/base-drv/usb_state.c:37: device_config *find_first_free(void) {
; ---------------------------------
; Function find_first_free
; ---------------------------------
_find_first_free:
;source-doc/base-drv/usb_state.c:38: _usb_state *const boot_state = get_usb_work_area();
;source-doc/base-drv/usb_state.c:41: device_config *p = first_device_config(boot_state);
	ld	hl,_x
	call	_first_device_config
;source-doc/base-drv/usb_state.c:42: while (p) {
l_find_first_free_00103:
	ld	a, d
	or	e
	jr	Z,l_find_first_free_00105
;source-doc/base-drv/usb_state.c:43: if (p->type == 0)
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$0f
	jr	NZ,l_find_first_free_00102
;source-doc/base-drv/usb_state.c:44: return p;
	ex	de, hl
	jr	l_find_first_free_00106
l_find_first_free_00102:
;source-doc/base-drv/usb_state.c:46: p = next_device_config(boot_state, p);
	ld	hl,_x
	call	_next_device_config
	jr	l_find_first_free_00103
l_find_first_free_00105:
;source-doc/base-drv/usb_state.c:49: return NULL;
	ld	hl,$0000
l_find_first_free_00106:
;source-doc/base-drv/usb_state.c:50: }
	ret
;source-doc/base-drv/usb_state.c:52: device_config *first_device_config(const _usb_state *const p) __sdcccall(1) { return (device_config *)&p->device_configs[0]; }
; ---------------------------------
; Function first_device_config
; ---------------------------------
_first_device_config:
	ex	de, hl
	inc	de
	inc	de
	ret
;source-doc/base-drv/usb_state.c:54: device_config *next_device_config(const _usb_state *const usb_state, const device_config *const p) __sdcccall(1) {
; ---------------------------------
; Function next_device_config
; ---------------------------------
_next_device_config:
	ld	c, l
	ld	b, h
;source-doc/base-drv/usb_state.c:55: if (p->type == 0)
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$0f
	jr	NZ,l_next_device_config_00102
;source-doc/base-drv/usb_state.c:56: return NULL;
	ld	de,$0000
	jr	l_next_device_config_00105
l_next_device_config_00102:
;source-doc/base-drv/usb_state.c:58: const uint8_t size = device_config_sizes[p->type];
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$0f
	add	a, +((_device_config_sizes) & $FF)
	ld	l, a
	ld	a,$00
	adc	a, +((_device_config_sizes) / 256)
	ld	h, a
	ld	a, (hl)
;source-doc/base-drv/usb_state.c:65: const uint8_t       *_p     = (uint8_t *)p;
;source-doc/base-drv/usb_state.c:66: device_config *const result = (device_config *)(_p + size);
	add	a, e
	ld	e, a
	ld	a,$00
	adc	a, d
	ld	d, a
;source-doc/base-drv/usb_state.c:68: if (result >= (device_config *)&usb_state->device_configs_end)
	ld	hl,$0062
	add	hl, bc
	ld	a, e
	sub	l
	ld	a, d
	sbc	a, h
	ret	C
;source-doc/base-drv/usb_state.c:69: return NULL;
	ld	de,$0000
;source-doc/base-drv/usb_state.c:71: return result;
l_next_device_config_00105:
;source-doc/base-drv/usb_state.c:72: }
	ret
;source-doc/base-drv/usb_state.c:74: device_config *get_usb_device_config(const uint8_t device_index) __sdcccall(1) {
; ---------------------------------
; Function get_usb_device_config
; ---------------------------------
_get_usb_device_config:
	ld	c, a
;source-doc/base-drv/usb_state.c:75: const _usb_state *const usb_state = get_usb_work_area();
;source-doc/base-drv/usb_state.c:79: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	push	bc
	ld	hl,_x
	call	_first_device_config
	pop	bc
	ld	b,$01
l_get_usb_device_config_00107:
	ld	a, d
	or	e
	jr	Z,l_get_usb_device_config_00105
;source-doc/base-drv/usb_state.c:80: if (p->type != USB_NOT_SUPPORTED) {
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$0f
	jr	Z,l_get_usb_device_config_00108
;source-doc/base-drv/usb_state.c:81: if (counter == device_index)
	ld	a, c
	sub	b
;source-doc/base-drv/usb_state.c:82: return p;
	jr	Z,l_get_usb_device_config_00109
;source-doc/base-drv/usb_state.c:83: counter++;
	inc	b
l_get_usb_device_config_00108:
;source-doc/base-drv/usb_state.c:79: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	push	bc
	ld	hl,_x
	call	_next_device_config
	pop	bc
	jr	l_get_usb_device_config_00107
l_get_usb_device_config_00105:
;source-doc/base-drv/usb_state.c:87: return NULL; // is not a usb device
	ld	de,$0000
l_get_usb_device_config_00109:
;source-doc/base-drv/usb_state.c:88: }
	ret
;source-doc/base-drv/usb_state.c:90: usb_device_type usb_get_device_type(const uint16_t dev_index) {
; ---------------------------------
; Function usb_get_device_type
; ---------------------------------
_usb_get_device_type:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/usb_state.c:91: const device_config *dev = get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	ld	l, e
;source-doc/base-drv/usb_state.c:93: if (dev == NULL)
	ld	a,d
	ld	h,a
	or	e
	jr	NZ,l_usb_get_device_type_00102
;source-doc/base-drv/usb_state.c:94: return -1;
	ld	l,$ff
	jr	l_usb_get_device_type_00103
l_usb_get_device_type_00102:
;source-doc/base-drv/usb_state.c:96: return dev->type;
	ld	a, (hl)
	and	$0f
	ld	l, a
l_usb_get_device_type_00103:
;source-doc/base-drv/usb_state.c:97: }
	pop	ix
	ret
