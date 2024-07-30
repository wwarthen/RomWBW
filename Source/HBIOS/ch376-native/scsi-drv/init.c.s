;
; Generated from source-doc/scsi-drv/./init.c.asm -- not to be modify directly
;
; 
;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.3.0 #14210 (Linux)
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
;source-doc/scsi-drv/./init.c:13: uint8_t chscsi_seek(const uint32_t lba, device_config_storage *const storage_device) __sdcccall(1) {
; ---------------------------------
; Function chscsi_seek
; ---------------------------------
_chscsi_seek:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
;source-doc/scsi-drv/./init.c:14: storage_device->current_lba = lba;
	ld	a,(ix+4)
	ld	h,(ix+5)
	add	a,0x0c
	ld	l, a
	jr	NC,l_chscsi_seek_00103
	inc	h
l_chscsi_seek_00103:
	ld	(hl), e
	inc	hl
	ld	(hl), d
	inc	hl
	ld	(hl), c
	inc	hl
	ld	(hl), b
;source-doc/scsi-drv/./init.c:15: return 0;
	xor	a
;source-doc/scsi-drv/./init.c:16: }
	pop	ix
	pop	hl
	pop	bc
	jp	(hl)
;source-doc/scsi-drv/./init.c:18: void chscsi_init(void) {
; ---------------------------------
; Function chscsi_init
; ---------------------------------
_chscsi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/scsi-drv/./init.c:21: do {
	ld	c,0x00
	ld	(ix-1),0x01
l_chscsi_init_00105:
;source-doc/scsi-drv/./init.c:22: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	push	bc
	ld	a,(ix-1)
	call	_get_usb_device_config
	pop	bc
;source-doc/scsi-drv/./init.c:24: if (storage_device == NULL)
	ld	a, d
	or	e
	jr	Z,l_chscsi_init_00107
;source-doc/scsi-drv/./init.c:27: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/scsi-drv/./init.c:29: if (t == USB_IS_MASS_STORAGE) {
	sub	0x02
	jr	NZ,l_chscsi_init_00106
;source-doc/scsi-drv/./init.c:30: storage_device->drive_index = storage_count++;
	ld	hl,0x0010
	add	hl, de
	ld	(hl), c
	inc	c
;source-doc/scsi-drv/./init.c:31: scsi_sense_init(storage_device);
	push	bc
	push	de
	push	de
	call	_scsi_sense_init
	pop	af
	pop	de
	ld	hl,_ch_scsi_fntbl
	call	_dio_add_entry
	pop	bc
l_chscsi_init_00106:
;source-doc/scsi-drv/./init.c:35: } while (++index != MAX_NUMBER_OF_STORAGE_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x05
	jr	NZ,l_chscsi_init_00105
l_chscsi_init_00107:
;source-doc/scsi-drv/./init.c:37: if (storage_count == 0)
	ld	a, c
	or	a
;source-doc/scsi-drv/./init.c:38: return;
	jr	Z,l_chscsi_init_00110
;source-doc/scsi-drv/./init.c:40: print_string("  $");
	push	bc
	ld	hl,init_str_0
	call	_print_string
	pop	bc
;source-doc/scsi-drv/./init.c:41: print_uint16(storage_count);
	ld	h,0x00
	ld	l, c
	call	_print_uint16
;source-doc/scsi-drv/./init.c:42: print_string(" STORAGE DEVICES$");
	ld	hl,init_str_1
	call	_print_string
l_chscsi_init_00110:
;source-doc/scsi-drv/./init.c:43: }
	inc	sp
	pop	ix
	ret
init_str_0:
	DEFM "  $"
	DEFB 0x00
init_str_1:
	DEFM " STORAGE DEVICES$"
	DEFB 0x00
