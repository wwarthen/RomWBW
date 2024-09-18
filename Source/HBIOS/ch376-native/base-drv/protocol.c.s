;
; Generated from source-doc/base-drv/./protocol.c.asm -- not to be modify directly
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
;source-doc/base-drv/./protocol.c:29: usb_error usbtrn_get_descriptor(device_descriptor *const buffer) {
; ---------------------------------
; Function usbtrn_get_descriptor
; ---------------------------------
_usbtrn_get_descriptor:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./protocol.c:32: cmd         = cmd_get_device_descriptor;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_get_device_descriptor
	ld	bc,0x0008
	ldir
;source-doc/base-drv/./protocol.c:33: cmd.wLength = 8;
	ld	(ix-2),0x08
	xor	a
	ld	(ix-1),a
;source-doc/base-drv/./protocol.c:35: debugger();
	PUSH	AF
	PUSH	BC
	XOR	A
	LD	B, 7
	DEFB		0x49, 0xD7
	POP	BC
	POP	AF
;source-doc/base-drv/./protocol.c:36: result = usb_control_transfer(&cmd, (uint8_t *)buffer, 0, 8);
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	e, c
	ld	d, b
	push	bc
	ld	a,0x08
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	push	de
	ld	hl,6
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	pop	bc
;source-doc/base-drv/./protocol.c:38: CHECK(result);
	ld	a, l
	or	a
	jr	NZ,l_usbtrn_get_descriptor_00103
;source-doc/base-drv/./protocol.c:40: cmd         = cmd_get_device_descriptor;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	push	bc
	ld	hl,_cmd_get_device_descriptor
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./protocol.c:41: cmd.wLength = 18;
	ld	(ix-2),0x12
	xor	a
	ld	(ix-1),a
;source-doc/base-drv/./protocol.c:42: result      = usb_control_transfer(&cmd, (uint8_t *)buffer, 0, buffer->bMaxPacketSize0);
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,7
	add	hl, de
	ld	a, (hl)
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	push	bc
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/./protocol.c:44: RETURN_CHECK(result);
l_usbtrn_get_descriptor_00103:
;source-doc/base-drv/./protocol.c:45: }
	ld	sp, ix
	pop	ix
	ret
_cmd_get_device_descriptor:
	DEFB +0x80
	DEFB +0x06
	DEFB +0x00
	DEFB +0x01
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0008
;source-doc/base-drv/./protocol.c:53: usb_error usbtrn_get_descriptor2(device_descriptor *const buffer, const uint8_t device_address) {
; ---------------------------------
; Function usbtrn_get_descriptor2
; ---------------------------------
_usbtrn_get_descriptor2:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -13
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./protocol.c:56: cmd         = cmd_get_device_descriptor;
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_get_device_descriptor
	ld	bc,0x0008
	ldir
;source-doc/base-drv/./protocol.c:57: cmd.wLength = 8;
	ld	(ix-5),0x08
	xor	a
	ld	(ix-4),a
;source-doc/base-drv/./protocol.c:59: result = usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, 8);
	ld	a,(ix+4)
	ld	(ix-2),a
	ld	a,(ix+5)
	ld	(ix-1),a
	ld	c,(ix-2)
	ld	b,(ix-1)
	ld	a,0x08
	push	af
	inc	sp
	ld	a,(ix+6)
	push	af
	inc	sp
	push	bc
	ld	hl,6
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	(ix-12),l
	ld	(ix-3),l
;source-doc/base-drv/./protocol.c:61: CHECK(result);
	ld	a,(ix-12)
	or	a
	jr	Z,l_usbtrn_get_descriptor2_00102
	ld	l,(ix-3)
	jr	l_usbtrn_get_descriptor2_00103
l_usbtrn_get_descriptor2_00102:
;source-doc/base-drv/./protocol.c:63: cmd         = cmd_get_device_descriptor;
	ex	de, hl
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_get_device_descriptor
	ld	bc,0x0008
	ldir
;source-doc/base-drv/./protocol.c:64: cmd.wLength = 18;
	ld	(ix-5),0x12
	xor	a
	ld	(ix-4),a
;source-doc/base-drv/./protocol.c:65: RETURN_CHECK(usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, buffer->bMaxPacketSize0));
	ld	a,(ix+4)
	ld	(ix-13),a
	ld	a,(ix+5)
	ld	(ix-12),a
	pop	hl
	push	hl
	ld	de,0x0007
	add	hl, de
	ld	a, (hl)
	ld	(ix-3),a
	push	af
	inc	sp
	ld	a,(ix+6)
	push	af
	inc	sp
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	ld	hl,6
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
l_usbtrn_get_descriptor2_00103:
;source-doc/base-drv/./protocol.c:66: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./protocol.c:76: usb_error usbtrn_set_address(const uint8_t device_address) __z88dk_fastcall {
; ---------------------------------
; Function usbtrn_set_address
; ---------------------------------
_usbtrn_set_address:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	push	af
	ld	c, l
;source-doc/base-drv/./protocol.c:78: cmd           = cmd_set_device_address;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	push	bc
	ld	hl,_cmd_set_device_address
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./protocol.c:79: cmd.bValue[0] = device_address;
	ld	(ix-6),c
;source-doc/base-drv/./protocol.c:81: return usb_control_transfer(&cmd, 0, 0, 0);
	xor	a
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
;source-doc/base-drv/./protocol.c:82: }
	ld	sp,ix
	pop	ix
	ret
_cmd_set_device_address:
	DEFB +0x00
	DEFB +0x05
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0000
;source-doc/base-drv/./protocol.c:92: usb_error usbtrn_set_configuration(const uint8_t device_address, const uint8_t max_packet_size, const uint8_t configuration) {
; ---------------------------------
; Function usbtrn_set_configuration
; ---------------------------------
_usbtrn_set_configuration:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./protocol.c:94: cmd           = cmd_set_configuration;
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	b, h
	ld	e, c
	ld	d, b
	push	bc
	ld	hl,_cmd_set_configuration
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./protocol.c:95: cmd.bValue[0] = configuration;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/./protocol.c:97: return usb_control_transfer(&cmd, 0, device_address, max_packet_size);
	ld	h,(ix+5)
	ld	l,(ix+4)
	push	hl
	ld	hl,0x0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/./protocol.c:98: }
	ld	sp,ix
	pop	ix
	ret
_cmd_set_configuration:
	DEFB +0x00
	DEFB +0x09
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0000
;source-doc/base-drv/./protocol.c:112: usb_error usbtrn_get_config_descriptor(config_descriptor *const buffer,
; ---------------------------------
; Function usbtrn_get_config_descriptor
; ---------------------------------
_usbtrn_get_config_descriptor:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./protocol.c:118: cmd           = cmd_get_config_descriptor;
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	b, h
	ld	e, c
	ld	d, b
	push	bc
	ld	hl,_cmd_get_config_descriptor
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./protocol.c:119: cmd.bValue[0] = config_index;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/./protocol.c:120: cmd.wLength   = (uint16_t)buffer_size;
	ld	e,(ix+7)
	ld	(ix-2),e
	ld	(ix-1),0x00
;source-doc/base-drv/./protocol.c:122: RETURN_CHECK(usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, max_packet_size));
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	h,(ix+9)
	ld	l,(ix+8)
	push	hl
	push	de
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/./protocol.c:123: }
	ld	sp,ix
	pop	ix
	ret
_cmd_get_config_descriptor:
	DEFB +0x80
	DEFB +0x06
	DEFB +0x00
	DEFB +0x02
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0000
;source-doc/base-drv/./protocol.c:125: usb_error usbtrn_gfull_cfg_desc(const uint8_t  config_index,
; ---------------------------------
; Function usbtrn_gfull_cfg_desc
; ---------------------------------
_usbtrn_gfull_cfg_desc:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./protocol.c:133: max_packet_size));
	ld	c,(ix+8)
	ld	b,(ix+9)
	push	bc
	ld	a,(ix+6)
	push	af
	inc	sp
	ld	d,(ix+5)
	ld	e,0x09
	push	de
	ld	a,(ix+4)
	push	af
	inc	sp
	push	bc
	call	_usbtrn_get_config_descriptor
	pop	af
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_usbtrn_gfull_cfg_desc_00107
;source-doc/base-drv/./protocol.c:135: uint8_t max_length = ((config_descriptor *)buffer)->wTotalLength;
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	d, (hl)
;source-doc/base-drv/./protocol.c:136: if (max_length > max_buffer_size)
	ld	a,(ix+7)
	sub	d
	jr	NC,l_usbtrn_gfull_cfg_desc_00104
;source-doc/base-drv/./protocol.c:137: max_length = max_buffer_size;
	ld	d,(ix+7)
l_usbtrn_gfull_cfg_desc_00104:
;source-doc/base-drv/./protocol.c:139: CHECK(usbtrn_get_config_descriptor((config_descriptor *)buffer, config_index, max_length, device_address, max_packet_size));
	ld	h,(ix+6)
	ld	l,(ix+5)
	push	hl
	push	de
	inc	sp
	ld	a,(ix+4)
	push	af
	inc	sp
	push	bc
	call	_usbtrn_get_config_descriptor
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/base-drv/./protocol.c:141: return USB_ERR_OK;
	or	a
	jr	NZ,l_usbtrn_gfull_cfg_desc_00107
	ld	l,a
l_usbtrn_gfull_cfg_desc_00107:
;source-doc/base-drv/./protocol.c:142: }
	pop	ix
	ret
;source-doc/base-drv/./protocol.c:146: usb_error usbtrn_clear_endpoint_halt(const uint8_t endpoint_number, const uint8_t device_address, const uint8_t max_packet_size) {
; ---------------------------------
; Function usbtrn_clear_endpoint_halt
; ---------------------------------
_usbtrn_clear_endpoint_halt:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/./protocol.c:148: cmd           = usb_cmd_clear_endpoint_halt;
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	b, h
	ld	e, c
	ld	d, b
	push	bc
	ld	hl,_usb_cmd_clear_endpoint_halt
	ld	bc,0x0008
	ldir
	pop	bc
;source-doc/base-drv/./protocol.c:149: cmd.bIndex[0] = endpoint_number;
	ld	a,(ix+4)
	ld	(ix-4),a
;source-doc/base-drv/./protocol.c:151: usb_error result = usb_control_transfer(&cmd, (uint8_t *)0, device_address, max_packet_size);
	ld	h,(ix+6)
	ld	l,(ix+5)
	push	hl
	ld	hl,0x0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/./protocol.c:153: RETURN_CHECK(result);
;source-doc/base-drv/./protocol.c:154: }
	ld	sp,ix
	pop	ix
	ret
_usb_cmd_clear_endpoint_halt:
	DEFB +0x02
	DEFB +0x01
	DEFB +0x00
	DEFB +0x00
	DEFB +0xff
	DEFB +0x00
	DEFW +0x0000
