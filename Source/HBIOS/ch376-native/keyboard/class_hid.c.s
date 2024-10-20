;
; Generated from source-doc/keyboard/./class_hid.c.asm -- not to be modify directly
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
;source-doc/keyboard/./class_hid.c:6: usb_error hid_set_protocol(const device_config_keyboard *const dev, const uint8_t protocol) __sdcccall(1) {
; ---------------------------------
; Function hid_set_protocol
; ---------------------------------
_hid_set_protocol:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	push	af
	ex	de, hl
;source-doc/keyboard/./class_hid.c:8: cmd = cmd_hid_set;
	push	de
	ex	de, hl
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_hid_set
	ld	bc,0x0008
	ldir
	pop	de
;source-doc/keyboard/./class_hid.c:10: cmd.bRequest  = HID_SET_PROTOCOL;
	ld	(ix-7),0x0b
;source-doc/keyboard/./class_hid.c:11: cmd.bValue[0] = protocol;
	ld	a,(ix+4)
	ld	(ix-6),a
;source-doc/keyboard/./class_hid.c:13: return usb_control_transfer(&cmd, NULL, dev->address, dev->max_packet_size);
	ld	l, e
	ld	h, d
	inc	hl
	ld	c, (hl)
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	h, c
	push	hl
	inc	sp
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/keyboard/./class_hid.c:14: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
_cmd_hid_set:
	DEFB +0x21
	DEFB +0x0b
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0000
;source-doc/keyboard/./class_hid.c:16: usb_error hid_set_idle(const device_config_keyboard *const dev, const uint8_t duration) __sdcccall(1) {
; ---------------------------------
; Function hid_set_idle
; ---------------------------------
_hid_set_idle:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	push	af
	ex	de, hl
;source-doc/keyboard/./class_hid.c:18: cmd = cmd_hid_set;
	push	de
	ex	de, hl
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_hid_set
	ld	bc,0x0008
	ldir
	pop	de
;source-doc/keyboard/./class_hid.c:20: cmd.bRequest  = HID_SET_IDLE;
	ld	(ix-7),0x0a
;source-doc/keyboard/./class_hid.c:21: cmd.bValue[0] = duration;
	ld	a,(ix+4)
	ld	(ix-6),a
;source-doc/keyboard/./class_hid.c:23: return usb_control_transfer(&cmd, NULL, dev->address, dev->max_packet_size);
	ld	l, e
	ld	h, d
	inc	hl
	ld	c, (hl)
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	h, c
	push	hl
	inc	sp
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/keyboard/./class_hid.c:24: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
;source-doc/keyboard/./class_hid.c:26: usb_error hid_get_input_report(const device_config_keyboard *const dev, uint8_t const *report) __sdcccall(1) {
; ---------------------------------
; Function hid_get_input_report
; ---------------------------------
_hid_get_input_report:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
	ld	hl, -9
	add	hl, sp
	ld	sp, hl
	ld	l, c
	ld	h, b
;source-doc/keyboard/./class_hid.c:28: cmd = cmd_hid_set;
	push	de
	push	hl
	ex	de, hl
	ld	hl,4
	add	hl, sp
	ex	de, hl
	ld	hl,_cmd_hid_set
	ld	bc,0x0008
	ldir
	pop	bc
	pop	de
;source-doc/keyboard/./class_hid.c:30: cmd.bmRequestType = 0xA1;
	ld	(ix-9),0xa1
;source-doc/keyboard/./class_hid.c:31: cmd.bValue[0]     = 1;
	ld	(ix-7),0x01
;source-doc/keyboard/./class_hid.c:32: cmd.bValue[1]     = 1;
	ld	(ix-6),0x01
;source-doc/keyboard/./class_hid.c:33: cmd.bRequest      = HID_GET_REPORT;
	ld	(ix-8),0x01
;source-doc/keyboard/./class_hid.c:34: cmd.wLength       = 8;
	ld	(ix-3),0x08
	xor	a
	ld	(ix-2),a
;source-doc/keyboard/./class_hid.c:36: return usb_control_transfer(&cmd, report, dev->address, dev->max_packet_size);
	ld	l, c
	ld	h, b
	inc	hl
	ld	a, (hl)
	ld	(ix-1),a
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	h,(ix-1)
	push	hl
	inc	sp
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
	ld	a, l
;source-doc/keyboard/./class_hid.c:37: }
	ld	sp, ix
	pop	ix
	ret
