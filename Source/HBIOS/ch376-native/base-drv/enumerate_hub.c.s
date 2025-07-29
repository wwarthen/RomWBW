;
; Generated from source-doc/base-drv/enumerate_hub.c.asm -- not to be modify directly
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
;source-doc/base-drv/enumerate_hub.c:13: usb_error hub_set_feature(const device_config_hub *const hub_config, const uint8_t feature, const uint8_t index) {
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
;source-doc/base-drv/enumerate_hub.c:15: set_feature = cmd_set_feature;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$0008
	ld	hl,_cmd_set_feature
	ldir
	pop	bc
;source-doc/base-drv/enumerate_hub.c:17: set_feature.bValue[0] = feature;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/enumerate_hub.c:18: set_feature.bIndex[0] = index;
	ld	a,(ix+7)
	ld	(ix-4),a
;source-doc/base-drv/enumerate_hub.c:19: return usb_control_transfer(&set_feature, 0, hub_config->address, hub_config->max_packet_size);
	ld	e,(ix+5)
	ld	a,(ix+4)
	ld	l, a
	ld	h, e
	inc	hl
	ld	d, (hl)
	ld	l, a
	ld	h, e
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	e,a
	push	de
	ld	hl,$0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/enumerate_hub.c:20: }
	ld	sp,ix
	pop	ix
	ret
_cmd_set_feature:
	DEFB +$23
	DEFB +$03
	DEFB +$08
	DEFB +$00
	DEFB +$01
	DEFB +$00
	DEFW +$0000
_cmd_clear_feature:
	DEFB +$23
	DEFB +$01
	DEFB +$08
	DEFB +$00
	DEFB +$01
	DEFB +$00
	DEFW +$0000
_cmd_get_status_port:
	DEFB +$a3
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$01
	DEFB +$00
	DEFW +$0004
;source-doc/base-drv/enumerate_hub.c:22: usb_error hub_clear_feature(const device_config_hub *const hub_config, const uint8_t feature, const uint8_t index) {
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
;source-doc/base-drv/enumerate_hub.c:24: clear_feature = cmd_clear_feature;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$0008
	ld	hl,_cmd_clear_feature
	ldir
	pop	bc
;source-doc/base-drv/enumerate_hub.c:26: clear_feature.bValue[0] = feature;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/enumerate_hub.c:27: clear_feature.bIndex[0] = index;
	ld	a,(ix+7)
	ld	(ix-4),a
;source-doc/base-drv/enumerate_hub.c:28: return usb_control_transfer(&clear_feature, 0, hub_config->address, hub_config->max_packet_size);
	ld	e,(ix+5)
	ld	a,(ix+4)
	ld	l, a
	ld	h, e
	inc	hl
	ld	d, (hl)
	ld	l, a
	ld	h, e
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	e,a
	push	de
	ld	hl,$0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/enumerate_hub.c:29: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/enumerate_hub.c:31: usb_error hub_get_status_port(const device_config_hub *const hub_config, const uint8_t index, hub_port_status *const port_status) {
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
;source-doc/base-drv/enumerate_hub.c:33: get_status_port = cmd_get_status_port;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$0008
	ld	hl,_cmd_get_status_port
	ldir
	pop	bc
;source-doc/base-drv/enumerate_hub.c:35: get_status_port.bIndex[0] = index;
	ld	a,(ix+6)
	ld	(ix-4),a
;source-doc/base-drv/enumerate_hub.c:36: return usb_control_transfer(&get_status_port, port_status, hub_config->address, hub_config->max_packet_size);
	ld	e,(ix+5)
	ld	a,(ix+4)
	ld	l, a
	ld	h, e
	inc	hl
	ld	d, (hl)
	ld	l, a
	ld	h, e
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	l,(ix+7)
	ld	h,(ix+8)
	ld	e,a
	push	de
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/enumerate_hub.c:37: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/enumerate_hub.c:39: usb_error configure_usb_hub(_working *const working) __z88dk_fastcall {
; ---------------------------------
; Function configure_usb_hub
; ---------------------------------
_configure_usb_hub:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
	ld	hl, -14
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/enumerate_hub.c:45: const device_config_hub *const hub_config = working->hub_config;
	ld	(ix-2),c
	ld	(ix-1),b
	ld	hl,25
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/enumerate_hub.c:47: CHECK(hub_get_descriptor(hub_config, &hub_description));
	push	bc
	ld	hl,2
	add	hl, sp
	ld	e,c
	ld	d,b
	ex	de,hl
	call	_hub_get_descriptor
	pop	bc
	or	a
	jp	NZ, l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:49: uint8_t i = hub_description.bNbrPorts;
	ld	d,(ix-12)
;source-doc/base-drv/enumerate_hub.c:50: do {
l_configure_usb_hub_00126:
;source-doc/base-drv/enumerate_hub.c:51: CHECK(hub_clear_feature(hub_config, FEAT_PORT_POWER, i));
	push	bc
	push	de
	ld	e,$08
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jp	NZ, l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:53: CHECK(hub_set_feature(hub_config, FEAT_PORT_POWER, i));
	push	bc
	push	de
	ld	e,$08
	push	de
	push	bc
	call	_hub_set_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jp	NZ, l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:55: hub_clear_feature(hub_config, FEAT_PORT_RESET, i);
	push	bc
	push	de
	ld	e,$04
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	pop	de
	pop	bc
;source-doc/base-drv/enumerate_hub.c:57: CHECK(hub_set_feature(hub_config, FEAT_PORT_RESET, i));
	push	bc
	push	de
	ld	e,$04
	push	de
	push	bc
	call	_hub_set_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jp	NZ, l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:59: CHECK(hub_get_status_port(hub_config, i, &port_status));
	push	bc
	push	de
	ld	hl,12
	add	hl, sp
	push	hl
	push	de
	inc	sp
	push	bc
	call	_hub_get_status_port
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	de
	pop	bc
	or	a
	jp	NZ, l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:61: if (port_status.wPortStatus & PORT_STAT_CONNECTION) {
	ld	e,(ix-6)
	bit	0, e
	jr	Z,l_configure_usb_hub_00124
;source-doc/base-drv/enumerate_hub.c:62: CHECK(hub_clear_feature(hub_config, HUB_FEATURE_PORT_CONNECTION_CHA, i));
	push	bc
	push	de
	ld	e,$10
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:64: CHECK(hub_clear_feature(hub_config, FEAT_PORT_ENABLE_CHANGE, i));
	push	bc
	push	de
	ld	e,$11
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:66: CHECK(hub_clear_feature(hub_config, FEAT_PORT_RESET_CHANGE, i));
	push	bc
	push	de
	ld	e,$14
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:67: delay_short();
	push	bc
	push	de
	call	_delay_short
	pop	de
	pop	bc
;source-doc/base-drv/enumerate_hub.c:69: CHECK(hub_get_status_port(hub_config, i, &port_status));
	push	bc
	push	de
	ld	hl,12
	add	hl, sp
	push	hl
	push	de
	inc	sp
	push	bc
	call	_hub_get_status_port
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	NZ,l_configure_usb_hub_00129
;source-doc/base-drv/enumerate_hub.c:70: delay_short();
	push	bc
	push	de
	call	_delay_short
	pop	de
	pop	bc
;source-doc/base-drv/enumerate_hub.c:72: CHECK(read_all_configs(working->state));
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	push	bc
	push	de
	push	hl
	call	_read_all_configs
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	Z,l_configure_usb_hub_00127
	jr	l_configure_usb_hub_00129
l_configure_usb_hub_00124:
;source-doc/base-drv/enumerate_hub.c:75: CHECK(hub_clear_feature(hub_config, FEAT_PORT_POWER, i));
	push	bc
	push	de
	ld	e,$08
	push	de
	push	bc
	call	_hub_clear_feature
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	NZ,l_configure_usb_hub_00129
l_configure_usb_hub_00127:
;source-doc/base-drv/enumerate_hub.c:77: } while (--i != 0);
	dec	d
	jp	NZ, l_configure_usb_hub_00126
;source-doc/base-drv/enumerate_hub.c:79: return USB_ERR_OK;
	ld	l,$00
	jr	l_configure_usb_hub_00130
;source-doc/base-drv/enumerate_hub.c:80: done:
l_configure_usb_hub_00129:
;source-doc/base-drv/enumerate_hub.c:81: return result;
	ld	l, a
l_configure_usb_hub_00130:
;source-doc/base-drv/enumerate_hub.c:82: }
	ld	sp, ix
	pop	ix
	ret
