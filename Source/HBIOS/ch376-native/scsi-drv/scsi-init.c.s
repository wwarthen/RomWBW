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
;source-doc/scsi-drv/scsi-init.c:14: void chscsi_init(void) {
; ---------------------------------
; Function chscsi_init
; ---------------------------------
_chscsi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -5
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/scsi-init.c:16: do {
	ld	(ix-1),0x01
l_chscsi_init_00105:
;source-doc/scsi-drv/scsi-init.c:17: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	ld	a,(ix-1)
	call	_get_usb_device_config
;source-doc/scsi-drv/scsi-init.c:19: if (storage_device == NULL)
	ld	a, d
	or	e
	jp	Z, l_chscsi_init_00108
;source-doc/scsi-drv/scsi-init.c:22: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/scsi-drv/scsi-init.c:24: if (t == USB_IS_MASS_STORAGE) {
	sub	0x02
	jr	NZ,l_chscsi_init_00106
;source-doc/scsi-drv/scsi-init.c:25: const uint8_t dev_index = find_storage_dev();  //index == -1 (no more left) should never happen
	push	de
	call	_find_storage_dev
	ld	c, l
	pop	de
;source-doc/scsi-drv/scsi-init.c:26: hbios_usb_storage_devices[dev_index].storage_device = storage_device;
	ld	(ix-5),c
	ld	(ix-4),0x00
	pop	hl
	push	hl
	add	hl, hl
	add	hl, hl
	ld	a, l
	add	a, +((_hbios_usb_storage_devices) & 0xFF)
	ld	(ix-3),a
	ld	l,a
	ld	a,h
	adc	a,+((_hbios_usb_storage_devices) / 256)
	ld	(ix-2),a
	ld	h,a
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/scsi-drv/scsi-init.c:27: hbios_usb_storage_devices[dev_index].drive_index = dev_index + 1;
	ld	l,(ix-3)
	ld	h,(ix-2)
	inc	hl
	inc	hl
	inc	c
	ld	(hl), c
;source-doc/scsi-drv/scsi-init.c:28: hbios_usb_storage_devices[dev_index].usb_device = index;
	ld	c,(ix-3)
	ld	b,(ix-2)
	inc	bc
	inc	bc
	inc	bc
	ld	a,(ix-1)
	ld	(bc), a
;source-doc/scsi-drv/scsi-init.c:30: print_string("\r\nUSB: MASS STORAGE @ $");
	push	de
	ld	hl,scsi_init_str_0
	call	_print_string
	pop	de
;source-doc/scsi-drv/scsi-init.c:31: print_uint16(index);
	ld	l,(ix-1)
	ld	h,0x00
	push	de
	call	_print_uint16
;source-doc/scsi-drv/scsi-init.c:32: print_string(":$");
	ld	hl,scsi_init_str_1
	call	_print_string
	pop	de
;source-doc/scsi-drv/scsi-init.c:33: print_uint16(dev_index + 1);
	pop	hl
	push	hl
	inc	hl
	push	de
	call	_print_uint16
;source-doc/scsi-drv/scsi-init.c:34: print_string(" $");
	ld	hl,scsi_init_str_2
	call	_print_string
;source-doc/scsi-drv/scsi-init.c:35: scsi_sense_init(storage_device);
	call	_scsi_sense_init
	pop	af
;source-doc/scsi-drv/scsi-init.c:36: dio_add_entry(ch_scsi_fntbl, &hbios_usb_storage_devices[dev_index]);
	ld	e,(ix-3)
	ld	d,(ix-2)
	ld	hl,_ch_scsi_fntbl
	call	_dio_add_entry
l_chscsi_init_00106:
;source-doc/scsi-drv/scsi-init.c:39: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jp	NZ,l_chscsi_init_00105
l_chscsi_init_00108:
;source-doc/scsi-drv/scsi-init.c:40: }
	ld	sp, ix
	pop	ix
	ret
scsi_init_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "USB: MASS STORAGE @ $"
	DEFB 0x00
scsi_init_str_1:
	DEFM ":$"
	DEFB 0x00
scsi_init_str_2:
	DEFM " $"
	DEFB 0x00
