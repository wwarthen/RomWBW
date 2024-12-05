;
; Generated from source-doc/base-drv/usb-base-drv.c.asm -- not to be modify directly
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
	
_storage_count:
	DEFS 1
	
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
;source-doc/base-drv/usb-base-drv.c:6: uint8_t chnative_seek(const uint32_t lba, device_config_storage *const storage_device) __sdcccall(1) {
; ---------------------------------
; Function chnative_seek
; ---------------------------------
_chnative_seek:
	push	ix
;source-doc/base-drv/usb-base-drv.c:7: storage_device->current_lba = lba;
	ld	ix,0
	add	ix,sp
	ld	c,(ix+4)
	ld	b,(ix+5)
	push	bc
	ld	a,(ix-2)
	add	a,0x0c
	ld	c,l
	ld	b,h
	ld	l, a
	ld	a,(ix-1)
	adc	a,0x00
	ld	h, a
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(hl), c
	inc	hl
	ld	(hl), b
;source-doc/base-drv/usb-base-drv.c:8: return 0;
	xor	a
;source-doc/base-drv/usb-base-drv.c:9: }
	ld	sp, ix
	pop	ix
	pop	hl
	pop	bc
	jp	(hl)
_storage_count:
	DEFB +0x00
