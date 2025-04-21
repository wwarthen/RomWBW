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
;source-doc/base-drv/usb_state.c:13: uint8_t count_of_devices(void) __sdcccall(1) {
; ---------------------------------
; Function count_of_devices
; ---------------------------------
_count_of_devices:
;source-doc/base-drv/usb_state.c:14: _usb_state *const p = get_usb_work_area();
;source-doc/base-drv/usb_state.c:18: const device_config *p_config = first_device_config(p);
	ld	hl,_x
	call	_first_device_config
;source-doc/base-drv/usb_state.c:19: while (p_config) {
	ld	c,0x00
l_count_of_devices_00104:
	ld	a, d
	or	e
	jr	Z,l_count_of_devices_00106
;source-doc/base-drv/usb_state.c:20: const uint8_t type = p_config->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/base-drv/usb_state.c:22: if (type != USB_IS_HUB && type)
	cp	0x0f
	jr	Z,l_count_of_devices_00102
	or	a
	jr	Z,l_count_of_devices_00102
;source-doc/base-drv/usb_state.c:23: count++;
	inc	c
l_count_of_devices_00102:
;source-doc/base-drv/usb_state.c:26: p_config = next_device_config(p, p_config);
	push	bc
	ld	hl,_x
	call	_next_device_config
	pop	bc
	jr	l_count_of_devices_00104
l_count_of_devices_00106:
;source-doc/base-drv/usb_state.c:29: return count;
	ld	a, c
;source-doc/base-drv/usb_state.c:30: }
	ret
_device_config_sizes:
	DEFB +0x00
	DEFB +0x10
	DEFB +0x10
	DEFB +0x0c
	DEFB +0x06
	DEFB 0x00
	DEFB 0x00
;source-doc/base-drv/usb_state.c:33: device_config *find_first_free(void) {
; ---------------------------------
; Function find_first_free
; ---------------------------------
_find_first_free:
;source-doc/base-drv/usb_state.c:34: _usb_state *const boot_state = get_usb_work_area();
;source-doc/base-drv/usb_state.c:37: device_config *p = first_device_config(boot_state);
	ld	hl,_x
	call	_first_device_config
;source-doc/base-drv/usb_state.c:38: while (p) {
l_find_first_free_00103:
	ld	a, d
	or	e
	jr	Z,l_find_first_free_00105
;source-doc/base-drv/usb_state.c:39: if (p->type == 0)
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	jr	NZ,l_find_first_free_00102
;source-doc/base-drv/usb_state.c:40: return p;
	ex	de, hl
	jr	l_find_first_free_00106
l_find_first_free_00102:
;source-doc/base-drv/usb_state.c:42: p = next_device_config(boot_state, p);
	ld	hl,_x
	call	_next_device_config
	jr	l_find_first_free_00103
l_find_first_free_00105:
;source-doc/base-drv/usb_state.c:45: return NULL;
	ld	hl,0x0000
l_find_first_free_00106:
;source-doc/base-drv/usb_state.c:46: }
	ret
;source-doc/base-drv/usb_state.c:48: device_config *first_device_config(const _usb_state *const p) __sdcccall(1) { return (device_config *)&p->device_configs[0]; }
; ---------------------------------
; Function first_device_config
; ---------------------------------
_first_device_config:
	ex	de, hl
	inc	de
	inc	de
	ret
;source-doc/base-drv/usb_state.c:50: device_config *next_device_config(const _usb_state *const usb_state, const device_config *const p) __sdcccall(1) {
; ---------------------------------
; Function next_device_config
; ---------------------------------
_next_device_config:
	ld	c, l
	ld	b, h
;source-doc/base-drv/usb_state.c:51: if (p->type == 0)
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	jr	NZ,l_next_device_config_00102
;source-doc/base-drv/usb_state.c:52: return NULL;
	ld	de,0x0000
	jr	l_next_device_config_00105
l_next_device_config_00102:
;source-doc/base-drv/usb_state.c:54: const uint8_t size = device_config_sizes[p->type];
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	add	a, +((_device_config_sizes) & 0xFF)
	ld	l, a
	ld	a,0x00
	adc	a, +((_device_config_sizes) / 256)
	ld	h, a
	ld	a, (hl)
;source-doc/base-drv/usb_state.c:61: const uint8_t       *_p     = (uint8_t *)p;
;source-doc/base-drv/usb_state.c:62: device_config *const result = (device_config *)(_p + size);
	add	a, e
	ld	e, a
	ld	a,0x00
	adc	a, d
	ld	d, a
;source-doc/base-drv/usb_state.c:64: if (result >= (device_config *)&usb_state->device_configs_end)
	ld	hl,0x0062
	add	hl, bc
	ld	a, e
	sub	l
	ld	a, d
	sbc	a, h
	ret	C
;source-doc/base-drv/usb_state.c:65: return NULL;
	ld	de,0x0000
;source-doc/base-drv/usb_state.c:67: return result;
l_next_device_config_00105:
;source-doc/base-drv/usb_state.c:68: }
	ret
;source-doc/base-drv/usb_state.c:71: device_config *get_usb_device_config(const uint8_t device_index) __sdcccall(1) {
; ---------------------------------
; Function get_usb_device_config
; ---------------------------------
_get_usb_device_config:
	ld	c, a
;source-doc/base-drv/usb_state.c:72: const _usb_state *const usb_state = get_usb_work_area();
;source-doc/base-drv/usb_state.c:76: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	push	bc
	ld	hl,_x
	call	_first_device_config
	pop	bc
	ld	b,0x01
l_get_usb_device_config_00107:
	ld	a, d
	or	e
	jr	Z,l_get_usb_device_config_00105
;source-doc/base-drv/usb_state.c:77: if (p->type != USB_NOT_SUPPORTED) {
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
	jr	Z,l_get_usb_device_config_00108
;source-doc/base-drv/usb_state.c:78: if (counter == device_index)
	ld	a, c
	sub	b
;source-doc/base-drv/usb_state.c:79: return p;
	jr	Z,l_get_usb_device_config_00109
;source-doc/base-drv/usb_state.c:80: counter++;
	inc	b
l_get_usb_device_config_00108:
;source-doc/base-drv/usb_state.c:76: for (device_config *p = first_device_config(usb_state); p; p = next_device_config(usb_state, p)) {
	push	bc
	ld	hl,_x
	call	_next_device_config
	pop	bc
	jr	l_get_usb_device_config_00107
l_get_usb_device_config_00105:
;source-doc/base-drv/usb_state.c:84: return NULL; // is not a usb device
	ld	de,0x0000
l_get_usb_device_config_00109:
;source-doc/base-drv/usb_state.c:85: }
	ret
