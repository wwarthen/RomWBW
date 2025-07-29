;
; Generated from source-doc/scsi-drv/scsi-init.c.asm -- not to be modify directly
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
;source-doc/scsi-drv/scsi-init.c:9: void chscsi_init(void) {
; ---------------------------------
; Function chscsi_init
; ---------------------------------
_chscsi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	dec	sp
;source-doc/scsi-drv/scsi-init.c:11: do {
	ld	(ix-1),$01
l_chscsi_init_00103:
;source-doc/scsi-drv/scsi-init.c:12: usb_device_type t = usb_get_device_type(index);
	ld	a,(ix-1)
	ld	(ix-3),a
	ld	(ix-2),$00
	pop	hl
	push	hl
	push	hl
	call	_usb_get_device_type
	pop	af
	ld	a, l
;source-doc/scsi-drv/scsi-init.c:14: if (t == USB_IS_MASS_STORAGE) {
	sub	$02
	jr	NZ,l_chscsi_init_00104
;source-doc/scsi-drv/scsi-init.c:15: const uint8_t dev_index = find_storage_dev(); // index == -1 (no more left) should never happen
	call	_find_storage_dev
;source-doc/scsi-drv/scsi-init.c:17: hbios_usbstore_devs[dev_index].drive_index = dev_index + 1;
	ld	a, l
	ld	c,$00
	add	a, a
	rl	c
	add	a, +((_hbios_usbstore_devs) & $FF)
	ld	e, a
	ld	a, c
	adc	a, +((_hbios_usbstore_devs) / 256)
	ld	d, a
	ld	c, e
	ld	b, d
	ld	a, l
	inc	a
	ld	(bc), a
;source-doc/scsi-drv/scsi-init.c:18: hbios_usbstore_devs[dev_index].usb_device  = index;
	ld	c, e
	ld	b, d
	inc	bc
	ld	a,(ix-1)
	ld	(bc), a
;source-doc/scsi-drv/scsi-init.c:20: print_string("\r\nUSB: MASS STORAGE @ $");
	push	hl
	push	de
	ld	hl,scsi_init_str_0
	call	_print_string
;source-doc/scsi-drv/scsi-init.c:21: print_uint16(index);
	ld	l,(ix-3)
	ld	h,$00
	call	_print_uint16
;source-doc/scsi-drv/scsi-init.c:22: print_string(":$");
	ld	hl,scsi_init_str_1
	call	_print_string
	pop	de
	pop	hl
;source-doc/scsi-drv/scsi-init.c:23: print_uint16(dev_index);
	ld	h,$00
	push	de
	call	_print_uint16
;source-doc/scsi-drv/scsi-init.c:24: print_string(" $");
	ld	hl,scsi_init_str_2
	call	_print_string
;source-doc/scsi-drv/scsi-init.c:25: usb_scsi_init(index);
	ld	l,(ix-3)
	ld	h,$00
	push	hl
	call	_usb_scsi_init
	pop	af
	pop	de
;source-doc/scsi-drv/scsi-init.c:26: dio_add_entry(ch_scsi_fntbl, &hbios_usbstore_devs[dev_index]);
	ld	hl,_ch_scsi_fntbl
	call	_dio_add_entry
l_chscsi_init_00104:
;source-doc/scsi-drv/scsi-init.c:29: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	$07
	jr	NZ,l_chscsi_init_00103
;source-doc/scsi-drv/scsi-init.c:30: }
	ld	sp, ix
	pop	ix
	ret
scsi_init_str_0:
	DEFB $0d
	DEFB $0a
	DEFM "USB: MASS STORAGE @ $"
	DEFB $00
scsi_init_str_1:
	DEFM ":$"
	DEFB $00
scsi_init_str_2:
	DEFM " $"
	DEFB $00
