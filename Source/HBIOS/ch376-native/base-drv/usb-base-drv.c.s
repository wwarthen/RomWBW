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
;source-doc/base-drv/usb-base-drv.c:7: static usb_error usb_host_bus_reset(void) {
; ---------------------------------
; Function usb_host_bus_reset
; ---------------------------------
_usb_host_bus_reset:
;source-doc/base-drv/usb-base-drv.c:8: ch_cmd_set_usb_mode(CH_MODE_HOST);
	ld	l,$06
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb-base-drv.c:9: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/usb-base-drv.c:11: ch_cmd_set_usb_mode(CH_MODE_HOST_RESET);
	ld	l,$07
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb-base-drv.c:12: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/usb-base-drv.c:14: ch_cmd_set_usb_mode(CH_MODE_HOST);
	ld	l,$06
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/usb-base-drv.c:15: delay_20ms();
	call	_delay_20ms
;source-doc/base-drv/ch376.h:108: #define TRACE_USB_ERROR(result)
	ld	l,$0b
	call	_ch_command
;source-doc/base-drv/ch376.h:109:
	ld	a,$25
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.h:110: #endif
	ld	a,$df
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:19: return USB_ERR_OK;
	ld	l,$00
;source-doc/base-drv/usb-base-drv.c:20: }
	ret
;source-doc/base-drv/usb-base-drv.c:24: uint16_t usb_init(uint8_t state) __z88dk_fastcall {
; ---------------------------------
; Function usb_init
; ---------------------------------
_usb_init:
;source-doc/base-drv/usb-base-drv.c:27: USB_MODULE_LEDS = $03;
	ld	a,$03
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:29: if (state == 0) {
	ld	a, l
	or	a
	jr	NZ,l_usb_init_00104
;source-doc/base-drv/usb-base-drv.c:30: ch_cmd_reset_all();
	call	_ch_cmd_reset_all
;source-doc/base-drv/usb-base-drv.c:31: delay_short();
	call	_delay_short
;source-doc/base-drv/usb-base-drv.c:33: if (!ch_probe()) {
	call	_ch_probe
	ld	a, l
;source-doc/base-drv/usb-base-drv.c:34: USB_MODULE_LEDS = $00;
	or	a
	jr	NZ,l_usb_init_00102
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:35: return $FF00;
	ld	hl,$ff00
	jp	l_usb_init_00113
l_usb_init_00102:
;source-doc/base-drv/usb-base-drv.c:37: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:38: return 1;
	ld	hl,$0001
	jr	l_usb_init_00113
l_usb_init_00104:
;source-doc/base-drv/usb-base-drv.c:41: if (state == 1) {
	ld	a, l
	dec	a
	jr	NZ,l_usb_init_00106
;source-doc/base-drv/usb-base-drv.c:42: r = ch_cmd_get_ic_version();
	call	_ch_cmd_get_ic_version
;source-doc/base-drv/usb-base-drv.c:44: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:45: return (uint16_t)r << 8 | 2;
	xor	a
	ld	h, l
	ld	l,$02
	jr	l_usb_init_00113
l_usb_init_00106:
;source-doc/base-drv/usb-base-drv.c:48: if (state == 2) {
	ld	a, l
	sub	$02
	jr	NZ,l_usb_init_00159
	ld	a,$01
	jr	l_usb_init_00160
l_usb_init_00159:
	xor	a
l_usb_init_00160:
	ld	c,a
	or	a
	jr	Z,l_usb_init_00110
;source-doc/base-drv/usb-base-drv.c:49: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb-base-drv.c:51: r = ch_very_short_status();
	call	_ch_very_short_status
	ld	a, l
;source-doc/base-drv/usb-base-drv.c:53: if (r != USB_INT_CONNECT) {
	sub	$81
	jr	Z,l_usb_init_00108
;source-doc/base-drv/usb-base-drv.c:54: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:55: return 2;
	ld	hl,$0002
	jr	l_usb_init_00113
l_usb_init_00108:
;source-doc/base-drv/usb-base-drv.c:58: return 3;
	ld	hl,$0003
	jr	l_usb_init_00113
l_usb_init_00110:
;source-doc/base-drv/usb-base-drv.c:61: memset(get_usb_work_area(), 0, sizeof(_usb_state));
	ld	b,$32
	ld	hl,_x
	jr	l_usb_init_00163
l_usb_init_00162:
	ld	(hl),$00
	inc	hl
l_usb_init_00163:
	ld	(hl),$00
	inc	hl
	djnz	l_usb_init_00162
;source-doc/base-drv/usb-base-drv.c:62: if (state != 2) {
	bit	0, c
	jr	NZ,l_usb_init_00112
;source-doc/base-drv/usb-base-drv.c:63: usb_host_bus_reset();
	call	_usb_host_bus_reset
;source-doc/base-drv/usb-base-drv.c:64: delay_medium();
	call	_delay_medium
l_usb_init_00112:
;source-doc/base-drv/usb-base-drv.c:66: enumerate_all_devices();
	call	_enumerate_all_devices
;source-doc/base-drv/usb-base-drv.c:67: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/usb-base-drv.c:68: return (uint16_t)count_of_devices() << 8 | 4;
	call	_count_of_devices
	ld	h, a
	xor	a
	ld	l,$04
l_usb_init_00113:
;source-doc/base-drv/usb-base-drv.c:69: }
	ret
;source-doc/base-drv/usb-base-drv.c:71: usb_error usb_scsi_seek(const uint16_t dev_index, const uint32_t lba) {
; ---------------------------------
; Function usb_scsi_seek
; ---------------------------------
_usb_scsi_seek:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/usb-base-drv.c:72: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/base-drv/usb-base-drv.c:74: dev->current_lba = lba;
	ld	hl,$000c
	add	hl, de
	ex	de, hl
	ld	hl,6
	add	hl, sp
	ld	bc,$0004
	ldir
;source-doc/base-drv/usb-base-drv.c:75: return USB_ERR_OK;
	ld	l,$00
;source-doc/base-drv/usb-base-drv.c:76: }
	pop	ix
	ret
