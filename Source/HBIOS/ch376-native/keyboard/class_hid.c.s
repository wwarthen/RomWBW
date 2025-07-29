;
; Generated from source-doc/keyboard/class_hid.c.asm -- not to be modify directly
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
;source-doc/keyboard/class_hid.c:6: usb_error hid_set_protocol(const device_config_keyboard *const dev, const uint8_t protocol) __sdcccall(1) {
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
;source-doc/keyboard/class_hid.c:8: cmd = cmd_hid_set;
	push	hl
	ex	de,hl
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_hid_set
	ldir
	pop	de
;source-doc/keyboard/class_hid.c:10: cmd.bRequest  = HID_SET_PROTOCOL;
	ld	(ix-7),$0b
;source-doc/keyboard/class_hid.c:11: cmd.bValue[0] = protocol;
	ld	a,(ix+4)
	ld	(ix-6),a
;source-doc/keyboard/class_hid.c:13: return usb_control_transfer(&cmd, NULL, dev->address, dev->max_packet_size);
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
	and	$0f
	ld	c,a
	push	bc
	ld	hl,$0000
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/keyboard/class_hid.c:14: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
_cmd_hid_set:
	DEFB +$21
	DEFB +$0b
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFW +$0000
;source-doc/keyboard/class_hid.c:16: usb_error hid_set_idle(const device_config_keyboard *const dev, const uint8_t duration) __sdcccall(1) {
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
;source-doc/keyboard/class_hid.c:18: cmd = cmd_hid_set;
	push	hl
	ex	de,hl
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	bc,$0008
	ld	hl,_cmd_hid_set
	ldir
	pop	de
;source-doc/keyboard/class_hid.c:20: cmd.bRequest  = HID_SET_IDLE;
	ld	(ix-7),$0a
;source-doc/keyboard/class_hid.c:21: cmd.bValue[0] = duration;
	ld	a,(ix+4)
	ld	(ix-6),a
;source-doc/keyboard/class_hid.c:23: return usb_control_transfer(&cmd, NULL, dev->address, dev->max_packet_size);
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
	and	$0f
	ld	c,a
	push	bc
	ld	hl,$0000
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/keyboard/class_hid.c:24: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
