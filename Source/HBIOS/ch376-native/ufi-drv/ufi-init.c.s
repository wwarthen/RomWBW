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
;source-doc/ufi-drv/ufi-init.c:11: do {
	ld	(ix-1),$01
l_chufi_init_00103:
;source-doc/ufi-drv/ufi-init.c:12: usb_device_type t = usb_get_device_type(index);
	ld	e,(ix-1)
	ld	d,$00
	push	de
	push	de
	call	_usb_get_device_type
	pop	af
	pop	de
;source-doc/ufi-drv/ufi-init.c:14: if (t == USB_IS_FLOPPY) {
	dec	l
	jr	NZ,l_chufi_init_00104
;source-doc/ufi-drv/ufi-init.c:15: const uint8_t dev_index = find_storage_dev(); // dev_index == -1 (no more left) should never happen
	push	de
	call	_find_storage_dev
	ld	(ix-2),l
	pop	de
;source-doc/ufi-drv/ufi-init.c:17: hbios_usbstore_devs[dev_index].drive_index = dev_index + 1;
	ld	l,(ix-2)
	ld	h,$00
	add	hl, hl
	ld	bc,_hbios_usbstore_devs
	add	hl, bc
	ld	a,(ix-2)
	inc	a
	ld	(hl),a
;source-doc/ufi-drv/ufi-init.c:18: hbios_usbstore_devs[dev_index].usb_device  = index;
	inc	hl
	ld	a,(ix-1)
	ld	(hl),a
	dec	hl
;source-doc/ufi-drv/ufi-init.c:20: print_string("\r\nUSB: FLOPPY @ $");
	push	hl
	push	de
	ld	hl,ufi_init_str_0
	call	_print_string
	pop	de
	pop	hl
;source-doc/ufi-drv/ufi-init.c:21: print_uint16(index);
	push	hl
	ex	de, hl
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:22: print_string(":$");
	ld	hl,ufi_init_str_1
	call	_print_string
	pop	hl
;source-doc/ufi-drv/ufi-init.c:23: print_uint16(dev_index);
	ld	e,(ix-2)
	ld	d,$00
	push	hl
	ex	de, hl
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:24: print_string(" $");
	ld	hl,ufi_init_str_2
	call	_print_string
	pop	hl
;source-doc/ufi-drv/ufi-init.c:25: dio_add_entry(ch_ufi_fntbl, &hbios_usbstore_devs[dev_index]);
	ex	de, hl
	ld	hl,_ch_ufi_fntbl
	call	_dio_add_entry
l_chufi_init_00104:
;source-doc/ufi-drv/ufi-init.c:28: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	$07
	jr	NZ,l_chufi_init_00103
;source-doc/ufi-drv/ufi-init.c:29: }
	ld	sp, ix
	pop	ix
	ret
ufi_init_str_0:
	DEFB $0d
	DEFB $0a
	DEFM "USB: FLOPPY @ $"
	DEFB $00
ufi_init_str_1:
	DEFM ":$"
	DEFB $00
ufi_init_str_2:
	DEFM " $"
	DEFB $00
