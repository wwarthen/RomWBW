;
; Generated from source-doc/base-drv/usb-base-drv.c.asm -- not to be modify directly
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
;source-doc/base-drv/usb-base-drv.c:3: uint8_t chnative_seek(const uint32_t lba, device_config_storage *const storage_device) __sdcccall(1) {
; ---------------------------------
; Function chnative_seek
; ---------------------------------
_chnative_seek:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
;source-doc/base-drv/usb-base-drv.c:4: storage_device->current_lba = lba;
	ld	h,(ix+5)
	ld	a,(ix+4)
	add	a,0x0c
	ld	l, a
	jr	NC,l_chnative_seek_00103
	inc	h
l_chnative_seek_00103:
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(hl), c
	inc	hl
	ld	(hl), b
;source-doc/base-drv/usb-base-drv.c:5: return 0;
	xor	a
;source-doc/base-drv/usb-base-drv.c:6: }
	pop	ix
	pop	hl
	pop	bc
	jp	(hl)
