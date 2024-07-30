;
; Generated from source-doc/base-drv/./enumerate.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.3.0 #14210 (Linux)
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
;source-doc/base-drv/./enumerate.c:13: void parse_endpoint_keyboard(device_config_keyboard *const keyboard_config, const endpoint_descriptor const *pEndpoint)
; ---------------------------------
; Function parse_endpoint_keyboard
; ---------------------------------
_parse_endpoint_keyboard:
;source-doc/base-drv/./enumerate.c:15: endpoint_param *const ep = &keyboard_config->endpoints[0];
	inc	hl
	inc	hl
	inc	hl
	push	hl
	pop	iy
;source-doc/base-drv/./enumerate.c:16: ep->number               = pEndpoint->bEndpointAddress;
	push	iy
	pop	bc
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	a, (hl)
	rlca
	and	0x0e
	ld	l, a
	ld	a, (bc)
	and	0xf1
	or	l
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:17: ep->toggle               = 0;
	push	iy
	pop	hl
	res	0, (hl)
;source-doc/base-drv/./enumerate.c:18: ep->max_packet_sizex     = calc_max_packet_sizex(pEndpoint->wMaxPacketSize);
	push	iy
	pop	bc
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
	ld	l,a
	ld	a, (bc)
	and	0xfc
	or	l
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:19: }
	ret
;source-doc/base-drv/./enumerate.c:21: usb_device_type identify_class_driver(_working *const working) {
; ---------------------------------
; Function identify_class_driver
; ---------------------------------
_identify_class_driver:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./enumerate.c:22: const interface_descriptor *const p = (const interface_descriptor *)working->ptr;
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,27
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/./enumerate.c:23: if (p->bInterfaceClass == 2)
	push	bc
	pop	iy
	ld	e,(iy+5)
	ld	a, e
	sub	0x02
	jr	NZ,l_identify_class_driver_00102
;source-doc/base-drv/./enumerate.c:24: return USB_IS_CDC;
	ld	l,0x03
	jr	l_identify_class_driver_00118
l_identify_class_driver_00102:
;source-doc/base-drv/./enumerate.c:26: if (p->bInterfaceClass == 8 && (p->bInterfaceSubClass == 6 || p->bInterfaceSubClass == 5) && p->bInterfaceProtocol == 80)
	ld	a, e
	sub	0x08
	jr	NZ,l_identify_class_driver_00177
	ld	a,0x01
	jr	l_identify_class_driver_00178
l_identify_class_driver_00177:
	xor	a
l_identify_class_driver_00178:
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
;source-doc/base-drv/./enumerate.c:27: return USB_IS_MASS_STORAGE;
	ld	l,0x02
	jr	l_identify_class_driver_00118
l_identify_class_driver_00104:
;source-doc/base-drv/./enumerate.c:29: if (p->bInterfaceClass == 8 && p->bInterfaceSubClass == 4 && p->bInterfaceProtocol == 0)
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
;source-doc/base-drv/./enumerate.c:30: return USB_IS_FLOPPY;
	ld	l,0x01
	jr	l_identify_class_driver_00118
l_identify_class_driver_00109:
;source-doc/base-drv/./enumerate.c:32: if (p->bInterfaceClass == 9 && p->bInterfaceSubClass == 0 && p->bInterfaceProtocol == 0)
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
;source-doc/base-drv/./enumerate.c:33: return USB_IS_HUB;
	ld	l,0x0f
	jr	l_identify_class_driver_00118
l_identify_class_driver_00113:
;source-doc/base-drv/./enumerate.c:35: if (p->bInterfaceClass == 3)
	ld	a, e
	sub	0x03
	jr	NZ,l_identify_class_driver_00117
;source-doc/base-drv/./enumerate.c:36: return USB_IS_KEYBOARD;
	ld	l,0x04
	jr	l_identify_class_driver_00118
l_identify_class_driver_00117:
;source-doc/base-drv/./enumerate.c:38: return USB_IS_UNKNOWN;
	ld	l,0x06
l_identify_class_driver_00118:
;source-doc/base-drv/./enumerate.c:39: }
	pop	ix
	ret
;source-doc/base-drv/./enumerate.c:41: usb_error op_interface_next(_working *const working) __z88dk_fastcall {
; ---------------------------------
; Function op_interface_next
; ---------------------------------
_op_interface_next:
	ex	de, hl
;source-doc/base-drv/./enumerate.c:42: if (--working->interface_count == 0)
	ld	hl,0x0016
	add	hl, de
	ld	a, (hl)
	dec	a
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:43: return USB_ERR_OK;
	or	a
	jr	NZ,l_op_interface_next_00102
	ld	l,a
	jr	l_op_interface_next_00103
l_op_interface_next_00102:
;source-doc/base-drv/./enumerate.c:45: return op_id_class_drv(working);
	ex	de, hl
	call	_op_id_class_drv
	ld	l, a
l_op_interface_next_00103:
;source-doc/base-drv/./enumerate.c:46: }
	ret
;source-doc/base-drv/./enumerate.c:48: usb_error op_endpoint_next(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_endpoint_next
; ---------------------------------
_op_endpoint_next:
	ex	de, hl
;source-doc/base-drv/./enumerate.c:49: if (--working->endpoint_count > 0) {
	ld	hl,0x0017
	add	hl, de
	ld	a, (hl)
	dec	a
	ld	(hl), a
	or	a
	jr	Z,l_op_endpoint_next_00102
;source-doc/base-drv/./enumerate.c:50: working->ptr += ((endpoint_descriptor *)working->ptr)->bLength;
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
;source-doc/base-drv/./enumerate.c:51: return op_parse_endpoint(working);
	ex	de, hl
	jp	_op_parse_endpoint
	jr	l_op_endpoint_next_00103
l_op_endpoint_next_00102:
;source-doc/base-drv/./enumerate.c:54: return op_interface_next(working);
	ex	de, hl
	call	_op_interface_next
	ld	a, l
l_op_endpoint_next_00103:
;source-doc/base-drv/./enumerate.c:55: }
	ret
;source-doc/base-drv/./enumerate.c:57: usb_error op_parse_endpoint(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_parse_endpoint
; ---------------------------------
_op_parse_endpoint:
;source-doc/base-drv/./enumerate.c:58: const endpoint_descriptor *endpoint = (endpoint_descriptor *)working->ptr;
	ld	c,l
	ld	b,h
	ld	hl,27
	add	hl,bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	de
	pop	iy
;source-doc/base-drv/./enumerate.c:59: device_config *const       device   = working->p_current_device;
	ld	hl,29
	add	hl,bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
;source-doc/base-drv/./enumerate.c:61: switch (working->usb_device) {
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
;source-doc/base-drv/./enumerate.c:63: case USB_IS_MASS_STORAGE: {
l_op_parse_endpoint_00102:
;source-doc/base-drv/./enumerate.c:64: parse_endpoints(device, endpoint);
	push	bc
	push	iy
	push	de
	call	_parse_endpoints
	pop	af
	pop	af
	pop	bc
;source-doc/base-drv/./enumerate.c:65: break;
	jr	l_op_parse_endpoint_00104
;source-doc/base-drv/./enumerate.c:68: case USB_IS_KEYBOARD: {
l_op_parse_endpoint_00103:
;source-doc/base-drv/./enumerate.c:69: parse_endpoint_keyboard((device_config_keyboard *)device, endpoint);
	ex	de, hl
	push	bc
	push	iy
	pop	de
	call	_parse_endpoint_keyboard
	pop	bc
;source-doc/base-drv/./enumerate.c:72: }
l_op_parse_endpoint_00104:
;source-doc/base-drv/./enumerate.c:74: return op_endpoint_next(working);
	ld	l, c
	ld	h, b
;source-doc/base-drv/./enumerate.c:75: }
	jp	_op_endpoint_next
;source-doc/base-drv/./enumerate.c:78: configure_device(const _working *const working, const interface_descriptor *const interface, device_config *const dev_cfg) {
; ---------------------------------
; Function configure_device
; ---------------------------------
_configure_device:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/./enumerate.c:79: dev_cfg->interface_number = interface->bInterfaceNumber;
	ld	e,(ix+8)
	ld	d,(ix+9)
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	ld	l,(ix+6)
	ld	h,(ix+7)
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:80: dev_cfg->max_packet_size  = working->desc.bMaxPacketSize0;
	ld	hl,0x0001
	add	hl, de
	ex	(sp), hl
	push	iy
	ex	(sp), hl
	ld	l,(ix+4)
	ex	(sp), hl
	ex	(sp), hl
	ld	h,(ix+5)
	ex	(sp), hl
	pop	iy
	push	iy
	pop	bc
	ld	hl,10
	add	hl, bc
	ld	a, (hl)
	pop	hl
	push	hl
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:81: dev_cfg->address          = working->current_device_address;
	ld	c, e
	ld	b, d
	push	iy
	pop	hl
	ld	a,+((0x0018) & 0xFF)
	add	a,l
	ld	l,a
	ld	a,+((0x0018) / 256)
	adc	a,h
	ld	h,a
	ld	a, (hl)
	add	a, a
	add	a, a
	add	a, a
	add	a, a
	ld	l, a
	ld	a, (bc)
	and	0x0f
	or	l
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:82: dev_cfg->type             = working->usb_device;
	ld	c, e
	ld	b, d
	push	iy
	pop	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	and	0x0f
	ld	l, a
	ld	a, (bc)
	and	0xf0
	or	l
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:84: return usbtrn_set_configuration(dev_cfg->address, dev_cfg->max_packet_size, working->config.desc.bConfigurationvalue);
	push	iy
	pop	bc
	ld	hl,36
	add	hl, bc
	ld	c, (hl)
	pop	hl
	ld	b,(hl)
	push	hl
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	h, c
	ld	l,b
	push	hl
	push	af
	inc	sp
	call	_usbtrn_set_configuration
;source-doc/base-drv/./enumerate.c:85: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/./enumerate.c:87: usb_error op_capture_hub_driver_interface(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_capture_hub_driver_interface
; ---------------------------------
_op_capture_hub_driver_interfac:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	iy, -7
	add	iy, sp
	ld	sp, iy
;source-doc/base-drv/./enumerate.c:88: const interface_descriptor *const interface = (interface_descriptor *)working->ptr;
	push	hl
	ex	de,hl
	pop	iy
	ld	c,(iy+28)
	ld	a,(iy+27)
	ld	(ix-4),a
	ld	(ix-3),c
;source-doc/base-drv/./enumerate.c:92: working->hub_config = &hub_config;
	ld	hl,0x0019
	add	hl, de
	ld	(ix-2),l
	ld	(ix-1),h
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	l,(ix-2)
	ld	b,h
	ld	h,(ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
;source-doc/base-drv/./enumerate.c:94: hub_config.type = USB_IS_HUB;
	ld	hl,0
	add	hl, sp
	ld	a, (hl)
	or	0x0f
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:95: CHECK(configure_device(working, interface, (device_config *const)&hub_config));
	push	de
	ld	hl,2
	add	hl, sp
	push	hl
	ld	l,(ix-4)
	ld	h,(ix-3)
	push	hl
	push	de
	call	_configure_device
	pop	af
	pop	af
	pop	af
	ld	a, l
	pop	de
	or	a
	jr	NZ,l_op_capture_hub_driver_interfa
;source-doc/base-drv/./enumerate.c:96: RETURN_CHECK(configure_usb_hub(working));
	ex	de, hl
	call	_configure_usb_hub
	ld	a, l
l_op_capture_hub_driver_interfa:
;source-doc/base-drv/./enumerate.c:97: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./enumerate.c:99: usb_error op_cap_drv_intf(_working *const working) __z88dk_fastcall {
; ---------------------------------
; Function op_cap_drv_intf
; ---------------------------------
_op_cap_drv_intf:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	iy, -16
	add	iy, sp
	ld	sp, iy
;source-doc/base-drv/./enumerate.c:102: const interface_descriptor *const interface = (interface_descriptor *)working->ptr;
	ld	(ix-2),l
	ld	(ix-1),h
	ld	de,0x001b
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	ld	c, e
	ld	b, d
;source-doc/base-drv/./enumerate.c:104: working->ptr += interface->bLength;
	ld	a, (bc)
	add	a, e
	ld	e, a
	ld	a,0x00
	adc	a, d
	ld	(hl), e
	inc	hl
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:105: working->endpoint_count   = interface->bNumEndpoints;
	ld	a,(ix-2)
	add	a,0x17
	ld	e, a
	ld	a,(ix-1)
	adc	a,0x00
	ld	d, a
	push	bc
	pop	iy
	ld	a,(iy+4)
	ld	(de), a
;source-doc/base-drv/./enumerate.c:106: working->p_current_device = NULL;
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	de,0x001d
	add	hl,de
	ld	(ix-4),l
	ld	(ix-3),h
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:108: switch (working->usb_device) {
	ld	e,(ix-2)
	ld	d,(ix-1)
	inc	de
	inc	de
	ld	a, (de)
	cp	0x06
	jr	Z,l_op_cap_drv_intf_00104
	sub	0x0f
	jr	NZ,l_op_cap_drv_intf_00107
;source-doc/base-drv/./enumerate.c:110: CHECK(op_capture_hub_driver_interface(working))
	ld	l,(ix-2)
	ld	h,(ix-1)
	call	_op_capture_hub_driver_interfac
	or	a
	jr	Z,l_op_cap_drv_intf_00112
	ld	l, a
	jr	l_op_cap_drv_intf_00115
;source-doc/base-drv/./enumerate.c:114: case USB_IS_UNKNOWN: {
l_op_cap_drv_intf_00104:
;source-doc/base-drv/./enumerate.c:116: memset(&unkown_dev_cfg, 0, sizeof(device_config));
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x0c
	push	hl
	call	_memset_callee
	pop	bc
;source-doc/base-drv/./enumerate.c:117: working->p_current_device = &unkown_dev_cfg;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/base-drv/./enumerate.c:118: CHECK(configure_device(working, interface, &unkown_dev_cfg));
	ld	hl,0
	add	hl, sp
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
	jr	l_op_cap_drv_intf_00115
;source-doc/base-drv/./enumerate.c:122: default: {
l_op_cap_drv_intf_00107:
;source-doc/base-drv/./enumerate.c:123: device_config *dev_cfg = find_first_free();
	push	bc
	call	_find_first_free
;source-doc/base-drv/./enumerate.c:124: if (dev_cfg == NULL)
	pop	bc
	ld	a,h
	or	l
	ex	de,hl
	jr	NZ,l_op_cap_drv_intf_00109
;source-doc/base-drv/./enumerate.c:125: return USB_ERR_OUT_OF_MEMORY;
	ld	l,0x83
	jr	l_op_cap_drv_intf_00115
l_op_cap_drv_intf_00109:
;source-doc/base-drv/./enumerate.c:126: working->p_current_device = dev_cfg;
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/base-drv/./enumerate.c:127: CHECK(configure_device(working, interface, dev_cfg));
	push	de
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
;source-doc/base-drv/./enumerate.c:130: }
	jr	NZ,l_op_cap_drv_intf_00115
l_op_cap_drv_intf_00112:
;source-doc/base-drv/./enumerate.c:132: CHECK(op_parse_endpoint(working));
	ld	l,(ix-2)
	ld	h,(ix-1)
	call	_op_parse_endpoint
	or	a
	jr	Z,l_op_cap_drv_intf_00114
	ld	l, a
	jr	l_op_cap_drv_intf_00115
l_op_cap_drv_intf_00114:
;source-doc/base-drv/./enumerate.c:134: return result;
	ld	l, a
l_op_cap_drv_intf_00115:
;source-doc/base-drv/./enumerate.c:135: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./enumerate.c:137: usb_error op_id_class_drv(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_id_class_drv
; ---------------------------------
_op_id_class_drv:
;source-doc/base-drv/./enumerate.c:139: const interface_descriptor *const ptr = (const interface_descriptor *)working->ptr;
	push	hl
	ex	de,hl
	pop	iy
	ld	l,(iy+27)
	ld	h,(iy+28)
;source-doc/base-drv/./enumerate.c:141: working->usb_device = ptr->bLength > 5 ? identify_class_driver(working) : 0;
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	ld	l, (hl)
	ld	a,0x05
	sub	l
	jr	NC,l_op_id_class_drv_00105
	push	bc
	push	de
	push	de
	call	_identify_class_driver
	pop	af
	ld	a, l
	pop	de
	pop	bc
	ld	l,0x00
	jr	l_op_id_class_drv_00106
l_op_id_class_drv_00105:
	xor	a
	ld	l, a
l_op_id_class_drv_00106:
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:143: CHECK(op_cap_drv_intf(working));
	ex	de, hl
	call	_op_cap_drv_intf
	ld	a, l
	or	a
	ret	NZ
;source-doc/base-drv/./enumerate.c:145: return result;
;source-doc/base-drv/./enumerate.c:146: }
	ret
;source-doc/base-drv/./enumerate.c:148: usb_error op_get_cfg_desc(_working *const working) __sdcccall(1) {
; ---------------------------------
; Function op_get_cfg_desc
; ---------------------------------
_op_get_cfg_desc:
	ex	de, hl
;source-doc/base-drv/./enumerate.c:151: memset(working->config.buffer, 0, MAX_CONFIG_SIZE);
	ld	iy,0x001f
	add	iy, de
	push	iy
	pop	bc
	push	de
	push	iy
	push	bc
	ld	hl,0x0000
	push	hl
	ld	l,0x8c
	push	hl
	call	_memset_callee
	pop	iy
	pop	de
;source-doc/base-drv/./enumerate.c:153: const uint8_t max_packet_size = working->desc.bMaxPacketSize0;
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	inc	bc
	ld	hl,7
	add	hl, bc
	ld	a, (hl)
;source-doc/base-drv/./enumerate.c:156: working->config.buffer));
	ld	c, e
	ld	b, d
	ld	hl,24
	add	hl, bc
	ld	b, (hl)
	ld	l, e
	ld	h, d
	push	bc
	ld	bc,0x0015
	add	hl, bc
	pop	bc
	ld	c, (hl)
	push	de
	push	iy
	push	iy
	ld	h,0x8c
	ld	l,a
	push	hl
	push	bc
	call	_usbtrn_gfull_cfg_desc
	pop	af
	pop	af
	pop	af
	ld	a, l
	pop	iy
	pop	de
	or	a
	ret	NZ
;source-doc/base-drv/./enumerate.c:158: working->ptr             = (working->config.buffer + sizeof(config_descriptor));
	ld	hl,0x001b
	add	hl, de
	ld	a, e
	add	a,0x1f
	ld	c, a
	ld	a, d
	adc	a,0x00
	ld	b, a
	ld	a, c
	add	a,0x09
	ld	c, a
	ld	a, b
	adc	a,0x00
	ld	(hl), c
	inc	hl
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:159: working->interface_count = working->config.desc.bNumInterfaces;
	ld	hl,0x0016
	add	hl, de
	ld	c, l
	ld	b, h
	push	iy
	pop	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(bc), a
;source-doc/base-drv/./enumerate.c:161: CHECK(op_id_class_drv(working));
	ex	de, hl
	call	_op_id_class_drv
	or	a
	ret	NZ
;source-doc/base-drv/./enumerate.c:163: return result;
;source-doc/base-drv/./enumerate.c:164: }
	ret
;source-doc/base-drv/./enumerate.c:166: usb_error read_all_configs(enumeration_state *const state) {
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
;source-doc/base-drv/./enumerate.c:171: memset(&working, 0, sizeof(_working));
	ld	hl,0
	add	hl, sp
	push	hl
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0xab
	push	hl
	call	_memset_callee
;source-doc/base-drv/./enumerate.c:172: working.state = state;
	pop	hl
	ld	e,l
	ld	d,h
	ld	a,(ix+4)
	ld	(hl), a
	inc	hl
	ld	a,(ix+5)
	ld	(hl), a
;source-doc/base-drv/./enumerate.c:174: CHECK(usbtrn_get_descriptor(&working.desc));
	push	de
	ld	hl,5
	add	hl, sp
	push	hl
	call	_usbtrn_get_descriptor
	pop	af
	pop	de
	ld	a, l
	or	a
	jr	NZ,l_read_all_configs_00111
;source-doc/base-drv/./enumerate.c:176: state->next_device_address++;
	ld	l,(ix+4)
	ld	h,(ix+5)
	ld	c, (hl)
	inc	c
	ld	(hl), c
;source-doc/base-drv/./enumerate.c:177: working.current_device_address = state->next_device_address;
	ld	hl,0x0018
	add	hl, de
	ld	(hl), c
;source-doc/base-drv/./enumerate.c:178: CHECK(usbtrn_set_address(working.current_device_address));
	push	de
	ld	l, c
	call	_usbtrn_set_address
	pop	de
	ld	a, l
;source-doc/base-drv/./enumerate.c:180: for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
	or	a
	jr	NZ,l_read_all_configs_00111
	ld	c,a
l_read_all_configs_00109:
	ld	hl,20+0
	add	hl, sp
	ld	b, (hl)
	ld	a, c
	sub	b
	jr	NC,l_read_all_configs_00107
;source-doc/base-drv/./enumerate.c:181: working.config_index = config_index;
	ld	hl,0x0015
	add	hl, de
	ld	(hl), c
;source-doc/base-drv/./enumerate.c:183: CHECK(op_get_cfg_desc(&working));
	push	bc
	push	de
	ld	hl,4
	add	hl, sp
	call	_op_get_cfg_desc
	pop	de
	pop	bc
	or	a
	jr	Z,l_read_all_configs_00110
	ld	l, a
	jr	l_read_all_configs_00111
l_read_all_configs_00110:
;source-doc/base-drv/./enumerate.c:180: for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
	inc	c
	jr	l_read_all_configs_00109
l_read_all_configs_00107:
;source-doc/base-drv/./enumerate.c:186: return USB_ERR_OK;
	ld	l,0x00
l_read_all_configs_00111:
;source-doc/base-drv/./enumerate.c:187: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./enumerate.c:189: usb_error enumerate_all_devices(void) {
; ---------------------------------
; Function enumerate_all_devices
; ---------------------------------
_enumerate_all_devices:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/./enumerate.c:190: _usb_state *const work_area = get_usb_work_area();
;source-doc/base-drv/./enumerate.c:192: memset(&state, 0, sizeof(enumeration_state));
	ld	hl,0
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x01
	push	hl
	call	_memset_callee
;source-doc/base-drv/./enumerate.c:193: state.next_device_address = 0;
	ld	(ix-1),0x00
;source-doc/base-drv/./enumerate.c:195: usb_error result = read_all_configs(&state);
	ld	hl,0
	add	hl, sp
	push	hl
	call	_read_all_configs
	pop	af
;source-doc/base-drv/./enumerate.c:197: work_area->count_of_detected_usb_devices = state.next_device_address;
	ld	a,(ix-1)
	ld	c,l
	ld	((_x + 1)),a
;source-doc/base-drv/./enumerate.c:199: CHECK(result);
	ld	a, c
	or	a
	jr	Z,l_enumerate_all_devices_00102
	ld	l, c
	jr	l_enumerate_all_devices_00103
l_enumerate_all_devices_00102:
;source-doc/base-drv/./enumerate.c:201: return result;
	ld	l, c
l_enumerate_all_devices_00103:
;source-doc/base-drv/./enumerate.c:202: }
	inc	sp
	pop	ix
	ret
