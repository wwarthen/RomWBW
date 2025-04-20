;
; Generated from source-doc/base-drv/enumerate.c.asm -- not to be modify directly
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
;source-doc/base-drv/enumerate.c:13: void parse_endpoint_keyboard(device_config_keyboard *const keyboard_config, const endpoint_descriptor const *pEndpoint)
; ---------------------------------
; Function parse_endpoint_keyboard
; ---------------------------------
_parse_endpoint_keyboard:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/enumerate.c:15: endpoint_param *const ep = &keyboard_config->endpoints[0];
	inc	hl
	inc	hl
	inc	hl
;source-doc/base-drv/enumerate.c:16: ep->number               = pEndpoint->bEndpointAddress;
	ld	c,l
	ld	b,h
	ex	(sp),hl
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	a, (hl)
	pop	hl
	push	hl
	rlca
	and	0x0e
	push	bc
	ld	c, a
	ld	a, (hl)
	and	0xf1
	or	c
	ld	(hl), a
;source-doc/base-drv/enumerate.c:17: ep->toggle               = 0;
	pop	hl
	ld	c,l
	ld	b,h
	res	0, (hl)
;source-doc/base-drv/enumerate.c:18: ep->max_packet_sizex     = calc_max_packet_sizex(pEndpoint->wMaxPacketSize);
	inc	bc
	ld	hl,4
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	a, (hl)
	and	0x03
	ld	d, a
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	and	0x03
	ld	l, a
	ld	a, (bc)
	and	0xfc
	or	l
	ld	(bc), a
;source-doc/base-drv/enumerate.c:19: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:21: usb_device_type identify_class_driver(_working *const working) {
; ---------------------------------
; Function identify_class_driver
; ---------------------------------
_identify_class_driver:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/enumerate.c:22: const interface_descriptor *const p = (const interface_descriptor *)working->ptr;
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,27
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/enumerate.c:23: if (p->bInterfaceClass == 2)
	ld	hl,5
	add	hl,bc
	ld	a,(hl)
	ld	e,a
	sub	0x02
	jr	NZ,l_identify_class_driver_00102
;source-doc/base-drv/enumerate.c:24: return USB_IS_CDC;
	ld	l,0x03
	jr	l_identify_class_driver_00118
l_identify_class_driver_00102:
;source-doc/base-drv/enumerate.c:26: if (p->bInterfaceClass == 8 && (p->bInterfaceSubClass == 6 || p->bInterfaceSubClass == 5) && p->bInterfaceProtocol == 80)
	ld	a, e
	sub	0x08
	jr	NZ,l_identify_class_driver_00199
	ld	a,0x01
	jr	l_identify_class_driver_00200
l_identify_class_driver_00199:
	xor	a
l_identify_class_driver_00200:
	ld	d,a
	or	a
	jr	Z,l_identify_class_driver_00104
	ld	hl,0x0006
	add	hl,bc
	ld	a, (hl)
	cp	0x06
	jr	Z,l_identify_class_driver_00107
	sub	0x05
	jr	NZ,l_identify_class_driver_00104
l_identify_class_driver_00107:
	ld	hl,0x0007
	add	hl,bc
	ld	a, (hl)
	sub	0x50
	jr	NZ,l_identify_class_driver_00104
;source-doc/base-drv/enumerate.c:27: return USB_IS_MASS_STORAGE;
	ld	l,0x02
	jr	l_identify_class_driver_00118
l_identify_class_driver_00104:
;source-doc/base-drv/enumerate.c:29: if (p->bInterfaceClass == 8 && p->bInterfaceSubClass == 4 && p->bInterfaceProtocol == 0)
	ld	a, d
	or	a
	jr	Z,l_identify_class_driver_00109
	ld	hl,0x0006
	add	hl,bc
	ld	a, (hl)
	sub	0x04
	jr	NZ,l_identify_class_driver_00109
	ld	hl,0x0007
	add	hl,bc
	ld	a, (hl)
	or	a
	jr	NZ,l_identify_class_driver_00109
;source-doc/base-drv/enumerate.c:30: return USB_IS_FLOPPY;
	ld	l,0x01
	jr	l_identify_class_driver_00118
l_identify_class_driver_00109:
;source-doc/base-drv/enumerate.c:32: if (p->bInterfaceClass == 9 && p->bInterfaceSubClass == 0 && p->bInterfaceProtocol == 0)
	ld	a, e
	sub	0x09
	jr	NZ,l_identify_class_driver_00113
	ld	hl,0x0006
	add	hl,bc
	ld	a, (hl)
	or	a
	jr	NZ,l_identify_class_driver_00113
	ld	hl,7
	add	hl, bc
	ld	a, (hl)
	or	a
	jr	NZ,l_identify_class_driver_00113
;source-doc/base-drv/enumerate.c:33: return USB_IS_HUB;
	ld	l,0x0f
	jr	l_identify_class_driver_00118
l_identify_class_driver_00113:
;source-doc/base-drv/enumerate.c:35: if (p->bInterfaceClass == 3)
	ld	a, e
	sub	0x03
	jr	NZ,l_identify_class_driver_00117
;source-doc/base-drv/enumerate.c:36: return USB_IS_KEYBOARD;
	ld	l,0x04
	jr	l_identify_class_driver_00118
l_identify_class_driver_00117:
;source-doc/base-drv/enumerate.c:38: return USB_IS_UNKNOWN;
	ld	l,0x06
l_identify_class_driver_00118:
;source-doc/base-drv/enumerate.c:39: }
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:41: usb_error op_interface_next(_working *const working) __z88dk_fastcall {
; ---------------------------------
; Function op_interface_next
; ---------------------------------
_op_interface_next:
	ex	de, hl
;source-doc/base-drv/enumerate.c:42: if (--working->interface_count == 0)
	ld	hl,0x0016
	add	hl, de
	ld	a, (hl)
	dec	a
	ld	(hl), a
;source-doc/base-drv/enumerate.c:43: return USB_ERR_OK;
	or	a
	jr	NZ,l_op_interface_next_00102
	ld	l,a
	jr	l_op_interface_next_00103
l_op_interface_next_00102:
;source-doc/base-drv/enumerate.c:45: return op_id_class_drv(working);
	ex	de, hl
	call	_op_id_class_drv
	ld	l, a
l_op_interface_next_00103:
;source-doc/base-drv/enumerate.c:46: }
	ret
;source-doc/base-drv/enumerate.c:48: usb_error op_endpoint_next(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_endpoint_next
; ---------------------------------
_op_endpoint_next:
	ex	de, hl
;source-doc/base-drv/enumerate.c:49: if (working->endpoint_count != 0 && --working->endpoint_count > 0) {
	ld	hl,0x0017
	add	hl, de
	ld	a, (hl)
	or	a
	jr	Z,l_op_endpoint_next_00102
	dec	a
	ld	(hl), a
	or	a
	jr	Z,l_op_endpoint_next_00102
;source-doc/base-drv/enumerate.c:50: working->ptr += ((endpoint_descriptor *)working->ptr)->bLength;
	ld	hl,0x001b
	add	hl, de
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	dec	hl
	ld	a, (bc)
	add	a, c
	ld	c, a
	ld	a,0x00
	adc	a, b
	ld	(hl), c
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:51: return op_parse_endpoint(working);
	ex	de, hl
	jp	_op_parse_endpoint
	jr	l_op_endpoint_next_00104
l_op_endpoint_next_00102:
;source-doc/base-drv/enumerate.c:54: return op_interface_next(working);
	ex	de, hl
	call	_op_interface_next
	ld	a, l
l_op_endpoint_next_00104:
;source-doc/base-drv/enumerate.c:55: }
	ret
;source-doc/base-drv/enumerate.c:57: usb_error op_parse_endpoint(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_parse_endpoint
; ---------------------------------
_op_parse_endpoint:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/enumerate.c:58: const endpoint_descriptor *endpoint = (endpoint_descriptor *)working->ptr;
	ld	de,0x001c
	ld	c,l
	ld	b,h
	add	hl, de
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	(ix-2),l
	ld	(ix-1),a
;source-doc/base-drv/enumerate.c:59: device_config *const       device   = working->p_current_device;
	ld	hl,29
	add	hl,bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
;source-doc/base-drv/enumerate.c:61: switch (working->usb_device) {
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	a, (hl)
	cp	0x01
	jr	Z,l_op_parse_endpoint_00102
	cp	0x02
	jr	Z,l_op_parse_endpoint_00102
	sub	0x04
	jr	Z,l_op_parse_endpoint_00103
	jr	l_op_parse_endpoint_00104
;source-doc/base-drv/enumerate.c:63: case USB_IS_MASS_STORAGE: {
l_op_parse_endpoint_00102:
;source-doc/base-drv/enumerate.c:64: parse_endpoints((device_config_storage *)device, endpoint);
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	de
	call	_parse_endpoints
	pop	af
	pop	af
	pop	bc
;source-doc/base-drv/enumerate.c:65: break;
	jr	l_op_parse_endpoint_00104
;source-doc/base-drv/enumerate.c:68: case USB_IS_KEYBOARD: {
l_op_parse_endpoint_00103:
;source-doc/base-drv/enumerate.c:69: parse_endpoint_keyboard((device_config_keyboard *)device, endpoint);
	ex	de, hl
	push	bc
	ld	e,(ix-2)
	ld	d,(ix-1)
	call	_parse_endpoint_keyboard
	pop	bc
;source-doc/base-drv/enumerate.c:72: }
l_op_parse_endpoint_00104:
;source-doc/base-drv/enumerate.c:74: return op_endpoint_next(working);
	ld	l, c
	ld	h, b
	call	_op_endpoint_next
;source-doc/base-drv/enumerate.c:75: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:78: configure_device(const _working *const working, const interface_descriptor *const interface, device_config *const dev_cfg) {
; ---------------------------------
; Function configure_device
; ---------------------------------
_configure_device:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/enumerate.c:79: dev_cfg->interface_number = interface->bInterfaceNumber;
	ld	c,(ix+8)
	ld	b,(ix+9)
	ld	e, c
	ld	d, b
	inc	de
	inc	de
	ld	l,(ix+6)
	ld	h,(ix+7)
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(de), a
;source-doc/base-drv/enumerate.c:80: dev_cfg->max_packet_size  = working->desc.bMaxPacketSize0;
	ld	hl,0x0001
	add	hl, bc
	ex	(sp), hl
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,0x000a
	add	hl,de
	ld	a, (hl)
	pop	hl
	push	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:81: dev_cfg->address          = working->current_device_address;
	ld	(ix-2),c
	ld	(ix-1),b
	ld	l, e
	ld	h, d
	ld	a,+((0x0018) & 0xFF)
	add	a,l
	ld	l,a
	ld	a,+((0x0018) / 256)
	adc	a,h
	ld	h,a
	ld	a, (hl)
	ld	l,(ix-2)
	ld	h,(ix-1)
	add	a, a
	add	a, a
	add	a, a
	add	a, a
	push	bc
	ld	c, a
	ld	a, (hl)
	and	0x0f
	or	c
	ld	(hl), a
	pop	bc
;source-doc/base-drv/enumerate.c:82: dev_cfg->type             = working->usb_device;
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	a, (hl)
	and	0x0f
	ld	l, a
	ld	a, (bc)
	and	0xf0
	or	l
	ld	(bc), a
;source-doc/base-drv/enumerate.c:84: return usbtrn_set_configuration(dev_cfg->address, dev_cfg->max_packet_size, working->config.desc.bConfigurationvalue);
	ld	hl,36
	add	hl, de
	ld	b, (hl)
	pop	hl
	ld	d,(hl)
	push	hl
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	c, d
	push	bc
	push	af
	inc	sp
	call	_usbtrn_set_configuration
;source-doc/base-drv/enumerate.c:85: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:87: usb_error op_capture_hub_driver_interface(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_capture_hub_driver_interface
; ---------------------------------
_op_capture_hub_driver_interfac:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	dec	sp
	ex	de, hl
;source-doc/base-drv/enumerate.c:88: const interface_descriptor *const interface = (interface_descriptor *)working->ptr;
	ld	hl,0x001c
	add	hl,de
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	(ix-2),l
	ld	(ix-1),a
;source-doc/base-drv/enumerate.c:92: working->hub_config = &hub_config;
	ld	hl,0x0019
	add	hl, de
	ld	c, l
	ld	b, h
	ld	hl,0
	add	hl, sp
	ld	a, l
	ld	(bc), a
	inc	bc
	ld	a, h
	ld	(bc), a
;source-doc/base-drv/enumerate.c:94: hub_config.type = USB_IS_HUB;
	ld	hl,0
	add	hl, sp
	ld	a, (hl)
	or	0x0f
	ld	(hl), a
;source-doc/base-drv/enumerate.c:95: CHECK(configure_device(working, interface, (device_config *const)&hub_config));
	push	de
	ld	hl,2
	add	hl, sp
	push	hl
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	de
	call	_configure_device
	pop	af
	pop	af
	pop	af
	pop	de
	ld	a, l
	inc	l
	dec	l
	jr	NZ,l_op_capture_hub_driver_interfa
;source-doc/base-drv/enumerate.c:96: RETURN_CHECK(configure_usb_hub(working));
	ex	de, hl
	call	_configure_usb_hub
	ld	a, l
;source-doc/base-drv/enumerate.c:97: done:
l_op_capture_hub_driver_interfa:
;source-doc/base-drv/enumerate.c:98: return result;
;source-doc/base-drv/enumerate.c:99: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:101: usb_error op_cap_drv_intf(_working *const working) __z88dk_fastcall {
; ---------------------------------
; Function op_cap_drv_intf
; ---------------------------------
_op_cap_drv_intf:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
	ld	hl, -14
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/enumerate.c:104: const interface_descriptor *const interface = (interface_descriptor *)working->ptr;
	ld	(ix-2),c
	ld	l, c
	ld	(ix-1),b
	ld	h,b
	ld	de,0x001b
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	ld	c, e
	ld	b, d
;source-doc/base-drv/enumerate.c:106: working->ptr += interface->bLength;
	ld	a, (bc)
	add	a, e
	ld	e, a
	ld	a,0x00
	adc	a, d
	ld	(hl), e
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:107: working->endpoint_count   = interface->bNumEndpoints;
	ld	a,(ix-2)
	add	a,0x17
	ld	e, a
	ld	a,(ix-1)
	adc	a,0x00
	ld	d, a
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(de), a
;source-doc/base-drv/enumerate.c:108: working->p_current_device = NULL;
	ld	a,(ix-2)
	add	a,0x1d
	ld	e, a
	ld	a,(ix-1)
	adc	a,0x00
	ld	d, a
	ld	l, e
	ld	h, d
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:110: switch (working->usb_device) {
	ld	l,(ix-2)
	ld	h,(ix-1)
	inc	hl
	inc	hl
	ld	a, (hl)
	cp	0x06
	jr	Z,l_op_cap_drv_intf_00104
	sub	0x0f
	jr	NZ,l_op_cap_drv_intf_00107
;source-doc/base-drv/enumerate.c:112: CHECK(op_capture_hub_driver_interface(working))
	ld	l,(ix-2)
	ld	h,(ix-1)
	call	_op_capture_hub_driver_interfac
	or	a
	jr	Z,l_op_cap_drv_intf_00112
	jr	l_op_cap_drv_intf_00113
;source-doc/base-drv/enumerate.c:116: case USB_IS_UNKNOWN: {
l_op_cap_drv_intf_00104:
;source-doc/base-drv/enumerate.c:118: memset(&unkown_dev_cfg, 0, sizeof(device_config));
	push	bc
	ld	hl,2
	add	hl, sp
	ld	b,0x06
l_op_cap_drv_intf_00154:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_op_cap_drv_intf_00154
	pop	bc
;source-doc/base-drv/enumerate.c:119: working->p_current_device = &unkown_dev_cfg;
	ld	hl,0
	add	hl, sp
	ld	a, l
	ld	(de), a
	inc	de
	ld	a, h
	ld	(de), a
;source-doc/base-drv/enumerate.c:120: CHECK(configure_device(working, interface, &unkown_dev_cfg));
	push	hl
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_configure_device
	pop	af
	pop	af
	pop	af
	ld	a, l
	or	a
	jr	Z,l_op_cap_drv_intf_00112
	jr	l_op_cap_drv_intf_00113
;source-doc/base-drv/enumerate.c:124: default: {
l_op_cap_drv_intf_00107:
;source-doc/base-drv/enumerate.c:125: device_config *dev_cfg = find_first_free();
	push	bc
	push	de
	call	_find_first_free
	pop	de
	pop	bc
;source-doc/base-drv/enumerate.c:126: if (dev_cfg == NULL)
	ld	a, h
	or	l
	jr	NZ,l_op_cap_drv_intf_00109
;source-doc/base-drv/enumerate.c:127: return USB_ERR_OUT_OF_MEMORY;
	ld	l,0x83
	jr	l_op_cap_drv_intf_00114
l_op_cap_drv_intf_00109:
;source-doc/base-drv/enumerate.c:128: working->p_current_device = dev_cfg;
	ld	a, l
	ld	(de), a
	inc	de
	ld	a, h
	ld	(de), a
;source-doc/base-drv/enumerate.c:129: CHECK(configure_device(working, interface, dev_cfg));
	push	hl
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_configure_device
	pop	af
	pop	af
	pop	af
	ld	a, l
	or	a
	jr	NZ,l_op_cap_drv_intf_00113
;source-doc/base-drv/enumerate.c:132: }
l_op_cap_drv_intf_00112:
;source-doc/base-drv/enumerate.c:134: result = op_parse_endpoint(working);
	ld	l,(ix-2)
	ld	h,(ix-1)
	call	_op_parse_endpoint
;source-doc/base-drv/enumerate.c:136: done:
l_op_cap_drv_intf_00113:
;source-doc/base-drv/enumerate.c:137: return result;
	ld	l, a
l_op_cap_drv_intf_00114:
;source-doc/base-drv/enumerate.c:138: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:140: usb_error op_id_class_drv(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_id_class_drv
; ---------------------------------
_op_id_class_drv:
	ex	de, hl
;source-doc/base-drv/enumerate.c:141: const interface_descriptor *const ptr = (const interface_descriptor *)working->ptr;
	ld	hl,27
	add	hl,de
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/enumerate.c:143: working->usb_device = ptr->bLength > 5 ? identify_class_driver(working) : 0;
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	a, (bc)
	cp	0x06
	jr	C,l_op_id_class_drv_00103
	push	hl
	push	de
	push	de
	call	_identify_class_driver
	pop	af
	ld	a, l
	pop	de
	pop	hl
	jr	l_op_id_class_drv_00104
l_op_id_class_drv_00103:
	xor	a
l_op_id_class_drv_00104:
	ld	(hl), a
;source-doc/base-drv/enumerate.c:145: return op_cap_drv_intf(working);
	ex	de, hl
	call	_op_cap_drv_intf
	ld	a, l
;source-doc/base-drv/enumerate.c:146: }
	ret
;source-doc/base-drv/enumerate.c:148: usb_error op_get_cfg_desc(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_get_cfg_desc
; ---------------------------------
_op_get_cfg_desc:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
	ld	c, l
	ld	b, h
;source-doc/base-drv/enumerate.c:149: memset(working->config.buffer, 0, MAX_CONFIG_SIZE);
	ld	hl,0x001f
	add	hl, bc
	push	bc
	ld	b,0x46
l_op_get_cfg_desc_00113:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_op_get_cfg_desc_00113
	pop	bc
;source-doc/base-drv/enumerate.c:151: const uint8_t max_packet_size = working->desc.bMaxPacketSize0;
	ld	e,c
	ld	d,b
	ld	hl,10
	add	hl,bc
	ld	a, (hl)
	ld	(ix-1),a
;source-doc/base-drv/enumerate.c:154: working->config.buffer));
	ld	hl,0x001f
	add	hl, bc
	ex	de, hl
	ld	hl,0x0018
	add	hl,bc
	ld	a, (hl)
	ld	hl,0x0015
	add	hl,bc
	ld	h, (hl)
	push	bc
	push	de
	ld	d,0x8c
	push	de
	inc	sp
	ld	d,(ix-1)
	push	de
	inc	sp
	ld	l,h
	ld	h,a
	push	hl
	call	_usbtrn_gfull_cfg_desc
	pop	af
	pop	af
	pop	af
	pop	bc
	ld	a, l
	ld	(_result), a
	ld	hl,_result
	ld	a, (hl)
	or	a
	jr	NZ,l_op_get_cfg_desc_00103
;source-doc/base-drv/enumerate.c:156: working->ptr             = (working->config.buffer + sizeof(config_descriptor));
	ld	hl,0x001b
	add	hl, bc
	ld	a, c
	add	a,0x28
	ld	e, a
	ld	a, b
	adc	a,0x00
	ld	(hl), e
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:157: working->interface_count = working->config.desc.bNumInterfaces;
	ld	hl,0x0016
	add	hl, bc
	ex	de, hl
	ld	hl,0x0023
	add	hl,bc
	ld	a, (hl)
	ld	(de), a
;source-doc/base-drv/enumerate.c:159: return op_id_class_drv(working);
	ld	l, c
	ld	h, b
	call	_op_id_class_drv
	jr	l_op_get_cfg_desc_00104
;source-doc/base-drv/enumerate.c:160: done:
l_op_get_cfg_desc_00103:
;source-doc/base-drv/enumerate.c:161: return result;
	ld	a, (_result)
l_op_get_cfg_desc_00104:
;source-doc/base-drv/enumerate.c:162: }
	inc	sp
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:164: usb_error read_all_configs(enumeration_state *const state) {
; ---------------------------------
; Function read_all_configs
; ---------------------------------
_read_all_configs:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -171
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/enumerate.c:169: memset(&working, 0, sizeof(_working));
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	ld	b,0x56
	jr	l_read_all_configs_00150
l_read_all_configs_00149:
	ld	(hl),0x00
	inc	hl
l_read_all_configs_00150:
	ld	(hl),0x00
	inc	hl
	djnz	l_read_all_configs_00149
;source-doc/base-drv/enumerate.c:170: working.state = state;
	ld	l, e
	ld	h, d
	ld	a,(ix+4)
	ld	(hl), a
	inc	hl
	ld	a,(ix+5)
	ld	(hl), a
;source-doc/base-drv/enumerate.c:172: CHECK(usbtrn_get_descriptor(&working.desc));
	push	de
	ld	hl,5
	add	hl, sp
	push	hl
	call	_usbtrn_get_descriptor
	pop	af
	ld	a, l
	pop	de
	or	a
	jr	NZ,l_read_all_configs_00108
;source-doc/base-drv/enumerate.c:174: state->next_device_address++;
	ld	b,(ix+5)
	ld	a,(ix+4)
	ld	l, a
	ld	h, b
	ld	c, (hl)
	inc	c
	ld	l, a
	ld	h, b
	ld	(hl), c
;source-doc/base-drv/enumerate.c:175: working.current_device_address = state->next_device_address;
	ld	hl,0x0018
	add	hl, de
	ld	(hl), c
;source-doc/base-drv/enumerate.c:176: CHECK(usbtrn_set_address(working.current_device_address));
	push	de
	ld	l, c
	call	_usbtrn_set_address
	ld	a, l
	pop	de
;source-doc/base-drv/enumerate.c:178: for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
	or	a
	jr	NZ,l_read_all_configs_00108
	ld	c,a
l_read_all_configs_00110:
	ld	hl,20
	add	hl, sp
	ld	b, (hl)
	ld	a, c
	sub	b
	jr	NC,l_read_all_configs_00107
;source-doc/base-drv/enumerate.c:179: working.config_index = config_index;
	ld	hl,0x0015
	add	hl, de
	ld	(hl), c
;source-doc/base-drv/enumerate.c:181: CHECK(op_get_cfg_desc(&working));
	ld	l, e
	ld	h, d
	push	bc
	push	de
	call	_op_get_cfg_desc
	pop	de
	pop	bc
	or	a
	jr	NZ,l_read_all_configs_00108
;source-doc/base-drv/enumerate.c:178: for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
	inc	c
	jr	l_read_all_configs_00110
l_read_all_configs_00107:
;source-doc/base-drv/enumerate.c:184: return USB_ERR_OK;
	ld	l,0x00
	jr	l_read_all_configs_00112
;source-doc/base-drv/enumerate.c:185: done:
l_read_all_configs_00108:
;source-doc/base-drv/enumerate.c:186: return result;
	ld	l, a
l_read_all_configs_00112:
;source-doc/base-drv/enumerate.c:187: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:189: static uint8_t count_storage_devs(enumeration_state *state) {
; ---------------------------------
; Function count_storage_devs
; ---------------------------------
_count_storage_devs:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/enumerate.c:192: do {
	ld	c,0x01
l_count_storage_devs_00106:
;source-doc/base-drv/enumerate.c:193: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	push	bc
	ld	a, c
	call	_get_usb_device_config
	pop	bc
;source-doc/base-drv/enumerate.c:195: if (storage_device == NULL)
	ld	a, d
	or	e
	jr	Z,l_count_storage_devs_00108
;source-doc/base-drv/enumerate.c:198: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/base-drv/enumerate.c:200: if (t == USB_IS_FLOPPY || t == USB_IS_MASS_STORAGE)
	cp	0x01
	jr	Z,l_count_storage_devs_00103
	sub	0x02
	jr	NZ,l_count_storage_devs_00107
l_count_storage_devs_00103:
;source-doc/base-drv/enumerate.c:201: storage_device->drive_index = state->storage_count++;
	ld	hl,0x0010
	add	hl, de
	ex	de, hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	inc	hl
	ld	a, (hl)
	ld	b, a
	inc	b
	ld	(hl), b
	ld	(de), a
l_count_storage_devs_00107:
;source-doc/base-drv/enumerate.c:203: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	c
	ld	a, c
	sub	0x07
	jr	NZ,l_count_storage_devs_00106
l_count_storage_devs_00108:
;source-doc/base-drv/enumerate.c:205: return state->storage_count;
	ld	l,(ix+4)
	ld	h,(ix+5)
	inc	hl
	ld	l, (hl)
;source-doc/base-drv/enumerate.c:206: }
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:208: usb_error enumerate_all_devices(void) {
; ---------------------------------
; Function enumerate_all_devices
; ---------------------------------
_enumerate_all_devices:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/enumerate.c:209: _usb_state *const work_area = get_usb_work_area();
;source-doc/base-drv/enumerate.c:211: memset(&state, 0, sizeof(enumeration_state));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:213: usb_error result = read_all_configs(&state);
	ld	hl,0
	add	hl, sp
	push	hl
	push	hl
	call	_read_all_configs
	pop	af
	ld	c, l
	pop	hl
;source-doc/base-drv/enumerate.c:215: count_storage_devs(&state);
	push	bc
	push	hl
	call	_count_storage_devs
	pop	af
	pop	bc
;source-doc/base-drv/enumerate.c:217: work_area->count_of_detected_usb_devices = state.next_device_address;
	ld	a,(ix-2)
	ld	((_x + 1)),a
;source-doc/base-drv/enumerate.c:220: return result;
	ld	l, c
;source-doc/base-drv/enumerate.c:221: }
	ld	sp, ix
	pop	ix
	ret
