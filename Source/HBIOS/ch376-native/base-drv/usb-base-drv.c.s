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
;source-doc/base-drv/usb-base-drv.c:4: uint8_t scsi_seek(const uint16_t dev_index, const uint32_t lba) {
; ---------------------------------
; Function scsi_seek
; ---------------------------------
_scsi_seek:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/usb-base-drv.c:5: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/base-drv/usb-base-drv.c:7: dev->current_lba = lba;
	ld	hl,0x000c
	add	hl, de
	ex	de, hl
	ld	hl,6
	add	hl, sp
	ld	bc,0x0004
	ldir
;source-doc/base-drv/usb-base-drv.c:8: return 0;
	ld	l,0x00
;source-doc/base-drv/usb-base-drv.c:9: }
	pop	ix
	ret
