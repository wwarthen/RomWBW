;
; Generated from source-doc/scsi-drv/./scsi-init.c.asm -- not to be modify directly
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
;source-doc/scsi-drv/./scsi-init.c:13: void chscsi_init(void) {
; ---------------------------------
; Function chscsi_init
; ---------------------------------
_chscsi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/./scsi-init.c:15: do {
	ld	(ix-1),0x01
l_chscsi_init_00105:
;source-doc/scsi-drv/./scsi-init.c:16: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	ld	a,(ix-1)
	call	_get_usb_device_config
;source-doc/scsi-drv/./scsi-init.c:18: if (storage_device == NULL)
	ld	a, d
	or	e
	jr	Z,l_chscsi_init_00107
;source-doc/scsi-drv/./scsi-init.c:21: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/scsi-drv/./scsi-init.c:23: if (t == USB_IS_MASS_STORAGE) {
	sub	0x02
	jr	NZ,l_chscsi_init_00106
;source-doc/scsi-drv/./scsi-init.c:24: storage_device->drive_index = storage_count++;
	ld	hl,0x0010
	add	hl, de
	ld	c, l
	ld	b, h
	ld	hl,_storage_count
	ld	a, (hl)
	ld	(ix-2),a
	inc	(hl)
	ld	a,(ix-2)
	ld	(bc), a
;source-doc/scsi-drv/./scsi-init.c:25: scsi_sense_init(storage_device);
	push	de
	push	de
	call	_scsi_sense_init
	pop	af
	pop	de
;source-doc/scsi-drv/./scsi-init.c:26: dio_add_entry(ch_scsi_fntbl, storage_device);
	ld	hl,_ch_scsi_fntbl
	call	_dio_add_entry
l_chscsi_init_00106:
;source-doc/scsi-drv/./scsi-init.c:29: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_chscsi_init_00105
l_chscsi_init_00107:
;source-doc/scsi-drv/./scsi-init.c:31: if (storage_count == 0)
	ld	hl,_storage_count
	ld	a, (hl)
	or	a
;source-doc/scsi-drv/./scsi-init.c:32: return;
	jr	Z,l_chscsi_init_00110
;source-doc/scsi-drv/./scsi-init.c:34: print_device_mounted(" STORAGE DEVICE$", storage_count);
	ld	a,(_storage_count)
	push	af
	inc	sp
	ld	hl,scsi_init_str_0
	push	hl
	call	_print_device_mounted
	pop	af
	inc	sp
l_chscsi_init_00110:
;source-doc/scsi-drv/./scsi-init.c:35: }
	ld	sp, ix
	pop	ix
	ret
scsi_init_str_0:
	DEFM " STORAGE DEVICE$"
	DEFB 0x00
