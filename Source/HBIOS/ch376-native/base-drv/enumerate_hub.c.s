;
; Generated from source-doc/base-drv/./enumerate_hub.c.asm -- not to be modify directly
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
;source-doc/base-drv/./enumerate_hub.c:13: usb_error hub_set_feature(const device_config_hub *const hub_config, const uint8_t feature, const uint8_t index) {
; ---------------------------------
; Function hub_set_feature
; ---------------------------------
_hub_set_feature:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./enumerate_hub.c:15: set_feature = cmd_set_feature;
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	b, h
	ld	e, c
	ld	d, b
	push	bc
	ld	hl,_cmd_set_feature
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./enumerate_hub.c:17: set_feature.bValue[0] = feature;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/./enumerate_hub.c:18: set_feature.bIndex[0] = index;
	ld	a,(ix+7)
	ld	(ix-4),a
;source-doc/base-drv/./enumerate_hub.c:19: return usb_control_transfer(&set_feature, 0, hub_config->address, hub_config->max_packet_size);
	ld	a,(ix+4)
	ld	d,(ix+5)
	ld	l, a
	ld	h, d
	inc	hl
	ld	e, (hl)
	ld	l, a
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	h, e
	push	hl
	inc	sp
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/./enumerate_hub.c:20: }
	ld	sp,ix
	pop	ix
	ret
_cmd_set_feature:
	DEFB +0x23
	DEFB +0x03
	DEFB +0x08
	DEFB +0x00
	DEFB +0x01
	DEFB +0x00
	DEFW +0x0000
_cmd_clear_feature:
	DEFB +0x23
	DEFB +0x01
	DEFB +0x08
	DEFB +0x00
	DEFB +0x01
	DEFB +0x00
	DEFW +0x0000
_cmd_get_status_port:
	DEFB +0xa3
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x01
	DEFB +0x00
	DEFW +0x0004
;source-doc/base-drv/./enumerate_hub.c:22: usb_error hub_clear_feature(const device_config_hub *const hub_config, const uint8_t feature, const uint8_t index) {
; ---------------------------------
; Function hub_clear_feature
; ---------------------------------
_hub_clear_feature:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./enumerate_hub.c:24: clear_feature = cmd_clear_feature;
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	b, h
	ld	e, c
	ld	d, b
	push	bc
	ld	hl,_cmd_clear_feature
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./enumerate_hub.c:26: clear_feature.bValue[0] = feature;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/./enumerate_hub.c:27: clear_feature.bIndex[0] = index;
	ld	a,(ix+7)
	ld	(ix-4),a
;source-doc/base-drv/./enumerate_hub.c:28: return usb_control_transfer(&clear_feature, 0, hub_config->address, hub_config->max_packet_size);
	ld	a,(ix+4)
	ld	d,(ix+5)
	ld	l, a
	ld	h, d
	inc	hl
	ld	e, (hl)
	ld	l, a
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	h, e
	push	hl
	inc	sp
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/./enumerate_hub.c:29: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/./enumerate_hub.c:31: usb_error hub_get_status_port(const device_config_hub *const hub_config, const uint8_t index, hub_port_status *const port_status) {
; ---------------------------------
; Function hub_get_status_port
; ---------------------------------
_hub_get_status_port:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./enumerate_hub.c:33: get_status_port = cmd_get_status_port;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_get_status_port
	ld	bc,0x0008
	ldir
;source-doc/base-drv/./enumerate_hub.c:35: get_status_port.bIndex[0] = index;
	ld	a,(ix+6)
	ld	(ix-4),a
;source-doc/base-drv/./enumerate_hub.c:36: return usb_control_transfer(&get_status_port, port_status, hub_config->address, hub_config->max_packet_size);
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	l, e
	ld	h, d
	inc	hl
	ld	b, (hl)
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	e,(ix+7)
	ld	d,(ix+8)
	ld	hl,0
	add	hl, sp
	push	bc
	inc	sp
	push	af
	inc	sp
	push	de
	push	hl
	call	_usb_control_transfer
;source-doc/base-drv/./enumerate_hub.c:37: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/./enumerate_hub.c:39: usb_error configure_usb_hub(_working *const working) __z88dk_fastcall {
; ---------------------------------
; Function configure_usb_hub
; ---------------------------------
_configure_usb_hub:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
	ld	hl, -15
	add	hl, sp
	ld	sp, hl
	ld	(ix-3),c
	ld	(ix-2),b
;source-doc/base-drv/./enumerate_hub.c:45: const device_config_hub *const hub_config = working->hub_config;
	ld	c,(ix-3)
	ld	b,(ix-2)
	ld	hl,25
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/./enumerate_hub.c:47: CHECK(hub_get_descriptor(hub_config, &hub_description));
	push	bc
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	l, c
	ld	h, b
	call	_hub_get_descriptor
	ld	e, a
	pop	bc
	ld	a, e
	or	a
	jr	Z,l_configure_usb_hub_00102
	ld	l, e
	jp	l_configure_usb_hub_00129
l_configure_usb_hub_00102:
;source-doc/base-drv/./enumerate_hub.c:49: uint8_t i = hub_description.bNbrPorts;
	ld	a,(ix-13)
	ld	(ix-1),a
;source-doc/base-drv/./enumerate_hub.c:50: do {
l_configure_usb_hub_00126:
;source-doc/base-drv/./enumerate_hub.c:51: CHECK(hub_clear_feature(hub_config, FEAT_PORT_POWER, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x08
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jp	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:53: CHECK(hub_set_feature(hub_config, FEAT_PORT_POWER, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x08
	push	de
	push	bc
	call	_hub_set_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jp	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:55: hub_clear_feature(hub_config, FEAT_PORT_RESET, i);
	push	bc
	ld	d,(ix-1)
	ld	e,0x04
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	bc
;source-doc/base-drv/./enumerate_hub.c:57: CHECK(hub_set_feature(hub_config, FEAT_PORT_RESET, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x04
	push	de
	push	bc
	call	_hub_set_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jp	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:59: CHECK(hub_get_status_port(hub_config, i, &port_status));
	push	bc
	ld	hl,10
	add	hl, sp
	push	hl
	ld	a,(ix-1)
	push	af
	inc	sp
	push	bc
	call	_hub_get_status_port
	pop	af
	pop	af
	inc	sp
	pop	bc
	ld	a, l
	or	a
	jp	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:61: if (port_status.wPortStatus.port_connection) {
	ld	hl,8
	add	hl, sp
	ld	a, (hl)
	and	0x01
	jr	Z,l_configure_usb_hub_00124
;source-doc/base-drv/./enumerate_hub.c:62: CHECK(hub_clear_feature(hub_config, HUB_FEATURE_PORT_CONNECTION_CHA, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x10
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:64: CHECK(hub_clear_feature(hub_config, FEAT_PORT_ENABLE_CHANGE, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x11
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:66: CHECK(hub_clear_feature(hub_config, FEAT_PORT_RESET_CHANGE, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x14
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:67: delay_short();
	push	bc
	call	_delay_short
	pop	bc
;source-doc/base-drv/./enumerate_hub.c:69: CHECK(hub_get_status_port(hub_config, i, &port_status));
	push	bc
	ld	hl,10
	add	hl, sp
	push	hl
	ld	a,(ix-1)
	push	af
	inc	sp
	push	bc
	call	_hub_get_status_port
	pop	af
	pop	af
	inc	sp
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/./enumerate_hub.c:70: delay_short();
	push	bc
	call	_delay_short
	pop	bc
;source-doc/base-drv/./enumerate_hub.c:72: CHECK(read_all_configs(working->state));
	ld	l,(ix-3)
	ld	h,(ix-2)
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	bc
	push	de
	call	_read_all_configs
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	Z,l_configure_usb_hub_00127
	jr	l_configure_usb_hub_00129
l_configure_usb_hub_00124:
;source-doc/base-drv/./enumerate_hub.c:75: CHECK(hub_clear_feature(hub_config, FEAT_PORT_POWER, i));
	push	bc
	ld	d,(ix-1)
	ld	e,0x08
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_configure_usb_hub_00129
l_configure_usb_hub_00127:
;source-doc/base-drv/./enumerate_hub.c:77: } while (--i != 0);
	dec	(ix-1)
	jp	NZ, l_configure_usb_hub_00126
;source-doc/base-drv/./enumerate_hub.c:79: return USB_ERR_OK;
	ld	l,0x00
l_configure_usb_hub_00129:
;source-doc/base-drv/./enumerate_hub.c:80: }
	ld	sp, ix
	pop	ix
	ret
