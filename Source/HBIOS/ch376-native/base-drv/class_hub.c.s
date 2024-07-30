;
; Generated from source-doc/base-drv/./class_hub.c.asm -- not to be modify directly
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
;source-doc/base-drv/./class_hub.c:7: usb_error hub_get_descriptor(const device_config_hub *const hub_config, hub_descriptor *const hub_description) __sdcccall(1) {
; ---------------------------------
; Function hub_get_descriptor
; ---------------------------------
_hub_get_descriptor:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/./class_hub.c:8: return usb_control_transfer(&cmd_get_hub_descriptor, hub_description, hub_config->address, hub_config->max_packet_size);
	ld	c,l
	ld	b,h
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
	ld	b, a
	ld	a,(ix-1)
	ld	c,b
	ld	b,a
	push	bc
	push	de
	ld	hl,_cmd_get_hub_descriptor
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/base-drv/./class_hub.c:9: }
	inc	sp
	pop	ix
	ret
_cmd_get_hub_descriptor:
	DEFB +0xa0
	DEFB +0x06
	DEFB +0x00
	DEFB +0x29
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0008
