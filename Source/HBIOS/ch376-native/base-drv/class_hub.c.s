;
; Generated from source-doc/base-drv/class_hub.c.asm -- not to be modify directly
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
;source-doc/base-drv/class_hub.c:7: usb_error hub_get_descriptor(const device_config_hub *const hub_config, hub_descriptor *const hub_description) __sdcccall(1) {
; ---------------------------------
; Function hub_get_descriptor
; ---------------------------------
_hub_get_descriptor:
;source-doc/base-drv/class_hub.c:8: return usb_control_transfer(&cmd_get_hub_descriptor, hub_description, hub_config->address, hub_config->max_packet_size);
	ld	a,l
	ld	c,h
	inc	hl
	ld	b, (hl)
	ld	l, a
	ld	h, c
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	c, a
	push	bc
	push	de
	ld	hl,_cmd_get_hub_descriptor
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/base-drv/class_hub.c:9: }
	ret
_cmd_get_hub_descriptor:
	DEFB +$a0
	DEFB +$06
	DEFB +$00
	DEFB +$29
	DEFB +$00
	DEFB +$00
	DEFW +$0008
