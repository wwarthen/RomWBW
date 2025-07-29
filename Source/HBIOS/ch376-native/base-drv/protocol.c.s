;
; Generated from source-doc/base-drv/protocol.c.asm -- not to be modify directly
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
;source-doc/base-drv/protocol.c:25: *
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
;source-doc/base-drv/protocol.c:28: */
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_get_dev_descriptr
	ldir
;source-doc/base-drv/protocol.c:29: usb_error usbtrn_get_descriptor(device_descriptor *const buffer) {
	ld	(ix-2),$08
	xor	a
	ld	(ix-1),a
;source-doc/base-drv/protocol.c:31: setup_packet cmd;
	ld	c,(ix+4)
	ld	b,(ix+5)
	push	bc
	push	bc
	ld	e,c
	ld	d,b
	ld	a,$08
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	push	de
	ld	hl,8
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	ld	l, a
;source-doc/base-drv/protocol.c:33: cmd.wLength = 8;
	or	a
	jr	NZ,l_usbtrn_get_descriptor_00103
;source-doc/base-drv/protocol.c:35: result = usb_control_transfer(&cmd, (uint8_t *)buffer, 0, 8);
	push	de
	push	bc
	ld	hl,4
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_get_dev_descriptr
	ldir
	pop	bc
	pop	de
;source-doc/base-drv/protocol.c:36:
	ld	(ix-2),$12
	xor	a
	ld	(ix-1),a
;source-doc/base-drv/protocol.c:37: CHECK(result);
	ld	hl,7
	add	hl, bc
	ld	a, (hl)
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	push	de
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/protocol.c:41: result      = usb_control_transfer(&cmd, (uint8_t *)buffer, 0, buffer->bMaxPacketSize0);
l_usbtrn_get_descriptor_00103:
;source-doc/base-drv/protocol.c:42:
;source-doc/base-drv/protocol.c:43: RETURN_CHECK(result);
	ld	sp, ix
	pop	ix
	ret
_cmd_get_dev_descriptr:
	DEFB +$80
	DEFB +$06
	DEFB +$00
	DEFB +$01
	DEFB +$00
	DEFB +$00
	DEFW +$0008
;source-doc/base-drv/protocol.c:47: }
; ---------------------------------
; Function usbtrn_get_descriptor2
; ---------------------------------
_usbtrn_get_descriptor2:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/protocol.c:51: *
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_get_dev_descriptr
	ldir
;source-doc/base-drv/protocol.c:52: * @param buffer the buffer to store the device descriptor in
	ld	(ix-2),$08
	xor	a
	ld	(ix-1),a
;source-doc/base-drv/protocol.c:54: */
	ld	c,(ix+4)
	ld	b,(ix+5)
	push	bc
	push	bc
	ld	e,c
	ld	d,b
	ld	h,$08
	ld	l,(ix+6)
	push	hl
	push	de
	ld	hl,8
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
	pop	de
	pop	bc
	ld	l, a
;source-doc/base-drv/protocol.c:56: usb_error result;
	or	a
	jr	NZ,l_usbtrn_get_descriptor2_00103
;source-doc/base-drv/protocol.c:58: setup_packet cmd;
	push	de
	push	bc
	ld	hl,4
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_get_dev_descriptr
	ldir
	pop	bc
	pop	de
;source-doc/base-drv/protocol.c:59: cmd         = cmd_get_dev_descriptr;
	ld	(ix-2),$12
	xor	a
	ld	(ix-1),a
;source-doc/base-drv/protocol.c:60: cmd.wLength = 8;
	ld	hl,7
	add	hl, bc
	ld	h,(hl)
	ld	l,(ix+6)
	push	hl
	push	de
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/protocol.c:61:
l_usbtrn_get_descriptor2_00103:
;source-doc/base-drv/protocol.c:62: result = usb_control_transfer(&cmd, (uint8_t *)buffer, device_address, 8);
;source-doc/base-drv/protocol.c:63:
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/protocol.c:69: done:
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
;source-doc/base-drv/protocol.c:71: }
	push	bc
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_set_device_address
	ldir
	pop	bc
;source-doc/base-drv/protocol.c:72:
	ld	(ix-6),c
;source-doc/base-drv/protocol.c:74:
	xor	a
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	ld	hl,$0000
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
;source-doc/base-drv/protocol.c:75: /**
	ld	sp,ix
	pop	ix
	ret
_cmd_set_device_address:
	DEFB +$00
	DEFB +$05
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFW +$0000
;source-doc/base-drv/protocol.c:81: usb_error usbtrn_set_address(const uint8_t device_address) __z88dk_fastcall {
; ---------------------------------
; Function usbtrn_set_config
; ---------------------------------
_usbtrn_set_config:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/protocol.c:83: cmd           = cmd_set_device_address;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$0008
	ld	hl,_cmd_set_configuration
	ldir
	pop	bc
;source-doc/base-drv/protocol.c:84: cmd.bValue[0] = device_address;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/protocol.c:86: return usb_control_transfer(&cmd, 0, 0, 0);
	ld	h,(ix+5)
	ld	l,(ix+4)
	push	hl
	ld	hl,$0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/protocol.c:87: }
	ld	sp,ix
	pop	ix
	ret
_cmd_set_configuration:
	DEFB +$00
	DEFB +$09
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFW +$0000
;source-doc/base-drv/protocol.c:93: *
; ---------------------------------
; Function usbtrn_get_config_desc
; ---------------------------------
_usbtrn_get_config_desc:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/protocol.c:99: cmd           = cmd_set_configuration;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$0008
	ld	hl,_cmd_get_config_desc
	ldir
	pop	bc
;source-doc/base-drv/protocol.c:100: cmd.bValue[0] = configuration;
	ld	a,(ix+6)
	ld	(ix-6),a
;source-doc/base-drv/protocol.c:101:
	ld	hl,$0006
	add	hl, bc
	ld	e,(ix+7)
	xor	a
	ld	(hl), e
	inc	hl
	ld	(hl), a
;source-doc/base-drv/protocol.c:103: }
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	h,(ix+9)
	ld	l,(ix+8)
	push	hl
	push	de
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/protocol.c:104:
	ld	sp,ix
	pop	ix
	ret
_cmd_get_config_desc:
	DEFB +$80
	DEFB +$06
	DEFB +$00
	DEFB +$02
	DEFB +$00
	DEFB +$00
	DEFW +$0000
;source-doc/base-drv/protocol.c:106:
; ---------------------------------
; Function usbtrn_gfull_cfg_desc
; ---------------------------------
_usbtrn_gfull_cfg_desc:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/protocol.c:114: * @param max_packet_size the max packet size for control transfers (endpoint 0)
	ld	c,(ix+8)
	ld	b,(ix+9)
	push	bc
	ld	a,(ix+6)
	push	af
	inc	sp
	ld	d,(ix+5)
	ld	e,$09
	push	de
	ld	a,(ix+4)
	push	af
	inc	sp
	push	bc
	call	_usbtrn_get_config_desc
	pop	af
	pop	af
	pop	af
	pop	bc
	ld	a, l
	or	a
	jr	NZ,l_usbtrn_gfull_cfg_desc_00107
;source-doc/base-drv/protocol.c:116: */
	ld	l,(ix+8)
	ld	h,(ix+9)
	inc	hl
	inc	hl
	ld	d, (hl)
;source-doc/base-drv/protocol.c:117: usb_error usbtrn_get_config_desc(config_descriptor *const buffer,
	ld	a,(ix+7)
	sub	d
	jr	NC,l_usbtrn_gfull_cfg_desc_00104
;source-doc/base-drv/protocol.c:118: const uint8_t            config_index,
	ld	d,(ix+7)
l_usbtrn_gfull_cfg_desc_00104:
;source-doc/base-drv/protocol.c:120: const uint8_t            device_address,
	ld	h,(ix+6)
	ld	l,(ix+5)
	push	hl
	ld	e,(ix+4)
	push	de
	push	bc
	call	_usbtrn_get_config_desc
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/base-drv/protocol.c:122: setup_packet cmd;
	or	a
	jr	NZ,l_usbtrn_gfull_cfg_desc_00107
	ld	l,a
;source-doc/base-drv/protocol.c:123: cmd           = cmd_get_config_desc;
;source-doc/base-drv/protocol.c:124: cmd.bValue[0] = config_index;
l_usbtrn_gfull_cfg_desc_00107:
;source-doc/base-drv/protocol.c:125: cmd.wLength   = (uint16_t)buffer_size;
	pop	ix
	ret
;source-doc/base-drv/protocol.c:129:
; ---------------------------------
; Function usbtrn_clr_ep_halt
; ---------------------------------
_usbtrn_clr_ep_halt:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/protocol.c:131: const uint8_t  device_address,
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$0008
	ld	hl,_usb_cmd_clr_ep_halt
	ldir
	pop	bc
;source-doc/base-drv/protocol.c:132: const uint8_t  max_packet_size,
	ld	a,(ix+4)
	ld	(ix-4),a
;source-doc/base-drv/protocol.c:134: uint8_t *const buffer) {
	ld	h,(ix+6)
	ld	l,(ix+5)
	push	hl
	ld	hl,$0000
	push	hl
	push	bc
	call	_usb_control_transfer
;source-doc/base-drv/protocol.c:135: usb_error result;
	ld	sp,ix
	pop	ix
	ret
_usb_cmd_clr_ep_halt:
	DEFB +$02
	DEFB +$01
	DEFB +$00
	DEFB +$00
	DEFB +$ff
	DEFB +$00
	DEFW +$0000
