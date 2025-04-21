;
; Generated from source-doc/ufi-drv/ufi-init.c.asm -- not to be modify directly
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
;source-doc/ufi-drv/ufi-init.c:8: void chufi_init(void) {
; ---------------------------------
; Function chufi_init
; ---------------------------------
_chufi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	dec	sp
;source-doc/ufi-drv/ufi-init.c:11: do {
	ld	(ix-1),0x01
l_chufi_init_00103:
;source-doc/ufi-drv/ufi-init.c:12: usb_device_type t = get_usb_device_type(index);
	ld	a,(ix-1)
	push	af
	inc	sp
	call	_get_usb_device_type
	inc	sp
;source-doc/ufi-drv/ufi-init.c:14: if (t == USB_IS_FLOPPY) {
	dec	l
	jr	NZ,l_chufi_init_00104
;source-doc/ufi-drv/ufi-init.c:15: const uint8_t dev_index = find_storage_dev(); // dev_index == -1 (no more left) should never happen
	call	_find_storage_dev
;source-doc/ufi-drv/ufi-init.c:17: hbios_usb_storage_devices[dev_index].drive_index = dev_index + 1;
	ld	(ix-3),l
	ld	(ix-2),0x00
	ld	a,l
	ld	c,l
	ld	b,0x00
	add	a, a
	rl	b
	add	a, +((_hbios_usb_storage_devices) & 0xFF)
	ld	e, a
	ld	a, b
	adc	a, +((_hbios_usb_storage_devices) / 256)
	ld	d, a
	ld	l, e
	ld	h, d
	inc	c
	ld	(hl), c
;source-doc/ufi-drv/ufi-init.c:18: hbios_usb_storage_devices[dev_index].usb_device  = index;
	ld	c, e
	ld	b, d
	inc	bc
	ld	a,(ix-1)
	ld	(bc), a
;source-doc/ufi-drv/ufi-init.c:20: print_string("\r\nUSB: FLOPPY @ $");
	push	de
	ld	hl,ufi_init_str_0
	call	_print_string
	pop	de
;source-doc/ufi-drv/ufi-init.c:21: print_uint16(index);
	ld	l,(ix-1)
	ld	h,0x00
	push	de
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:22: print_string(":$");
	ld	hl,ufi_init_str_1
	call	_print_string
	pop	de
;source-doc/ufi-drv/ufi-init.c:23: print_uint16(dev_index + 1);
	pop	hl
	push	hl
	inc	hl
	push	de
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:24: print_string(" $");
	ld	hl,ufi_init_str_2
	call	_print_string
	pop	de
;source-doc/ufi-drv/ufi-init.c:25: dio_add_entry(ch_ufi_fntbl, &hbios_usb_storage_devices[dev_index]);
	ld	hl,_ch_ufi_fntbl
	call	_dio_add_entry
l_chufi_init_00104:
;source-doc/ufi-drv/ufi-init.c:28: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_chufi_init_00103
;source-doc/ufi-drv/ufi-init.c:29: }
	ld	sp, ix
	pop	ix
	ret
ufi_init_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "USB: FLOPPY @ $"
	DEFB 0x00
ufi_init_str_1:
	DEFM ":$"
	DEFB 0x00
ufi_init_str_2:
	DEFM " $"
	DEFB 0x00
