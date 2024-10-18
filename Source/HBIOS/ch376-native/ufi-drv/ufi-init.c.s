;
; Generated from source-doc/ufi-drv/./ufi-init.c.asm -- not to be modify directly
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
;source-doc/ufi-drv/./ufi-init.c:11: void chufi_init(void) {
; ---------------------------------
; Function chufi_init
; ---------------------------------
_chufi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/ufi-drv/./ufi-init.c:14: do {
	ld	(ix-1),0x01
l_chufi_init_00105:
;source-doc/ufi-drv/./ufi-init.c:15: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	ld	a,(ix-1)
	call	_get_usb_device_config
;source-doc/ufi-drv/./ufi-init.c:17: if (storage_device == NULL)
	ld	a, d
	or	e
	jr	Z,l_chufi_init_00108
;source-doc/ufi-drv/./ufi-init.c:20: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/ufi-drv/./ufi-init.c:22: if (t == USB_IS_FLOPPY) {
	dec	a
	jr	NZ,l_chufi_init_00106
;source-doc/ufi-drv/./ufi-init.c:23: print_string("\r\nUSB: FLOPPY @ $");
	push	de
	ld	hl,ufi_init_str_0
	call	_print_string
	pop	de
;source-doc/ufi-drv/./ufi-init.c:24: print_uint16(index);
	ld	l,(ix-1)
	ld	h,0x00
	push	de
	call	_print_uint16
	ld	hl,ufi_init_str_1
	call	_print_string
	pop	de
;source-doc/ufi-drv/./ufi-init.c:26: dio_add_entry(ch_ufi_fntbl, storage_device);
	ld	hl,_ch_ufi_fntbl
	call	_dio_add_entry
l_chufi_init_00106:
;source-doc/ufi-drv/./ufi-init.c:29: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_chufi_init_00105
l_chufi_init_00108:
;source-doc/ufi-drv/./ufi-init.c:30: }
	inc	sp
	pop	ix
	ret
ufi_init_str_0:
	DEFB 0x0d
	DEFB 0x0a
	DEFM "USB: FLOPPY @ $"
	DEFB 0x00
ufi_init_str_1:
	DEFM " $"
	DEFB 0x00
;source-doc/ufi-drv/./ufi-init.c:32: uint32_t chufi_get_cap(device_config *const dev) {
; ---------------------------------
; Function chufi_get_cap
; ---------------------------------
_chufi_get_cap:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -72
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/./ufi-init.c:34: memset(&response, 0, sizeof(ufi_format_capacities_response));
	ld	hl,0
	add	hl, sp
	ld	b,0x24
l_chufi_get_cap_00112:
	ld	(hl),0x00
	inc	hl
	djnz	l_chufi_get_cap_00112
;source-doc/ufi-drv/./ufi-init.c:36: wait_for_device_ready(dev, 25);
	ld	a,0x19
	push	af
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_wait_for_device_ready
	pop	af
	inc	sp
;source-doc/ufi-drv/./ufi-init.c:40: ufi_inquiry(dev, &inquiry);
	ld	hl,36
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ufi_inquiry
	pop	af
;source-doc/ufi-drv/./ufi-init.c:42: wait_for_device_ready(dev, 15);
	ld	h,0x0f
	ex	(sp),hl
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_wait_for_device_ready
	pop	af
	inc	sp
;source-doc/ufi-drv/./ufi-init.c:44: const usb_error result = ufi_read_frmt_caps(dev, &response);
	ld	hl,0
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ufi_read_frmt_caps
	pop	af
	pop	af
	ld	a, l
;source-doc/ufi-drv/./ufi-init.c:45: if (result != USB_ERR_OK)
	or	a
	jr	Z,l_chufi_get_cap_00102
;source-doc/ufi-drv/./ufi-init.c:46: return 0;
	ld	hl,0x0000
	ld	e, l
	ld	d, l
	jr	l_chufi_get_cap_00103
l_chufi_get_cap_00102:
;source-doc/ufi-drv/./ufi-init.c:48: return convert_from_msb_first(response.descriptors[0].number_of_blocks);
	ld	hl,4
	add	hl, sp
	push	hl
	call	_convert_from_msb_first
	pop	af
l_chufi_get_cap_00103:
;source-doc/ufi-drv/./ufi-init.c:49: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./ufi-init.c:51: uint8_t chufi_read(device_config_storage *const dev, uint8_t *const buffer) {
; ---------------------------------
; Function chufi_read
; ---------------------------------
_chufi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -20
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/./ufi-init.c:53: if (wait_for_device_ready((device_config *)dev, 20) != 0)
	ld	c,(ix+4)
	ld	b,(ix+5)
	push	bc
	ld	a,0x14
	push	af
	inc	sp
	push	bc
	call	_wait_for_device_ready
	pop	af
	inc	sp
	ld	e, l
	pop	bc
	ld	a, e
	or	a
	jr	Z,l_chufi_read_00102
;source-doc/ufi-drv/./ufi-init.c:54: return -1; // Not READY!
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00102:
;source-doc/ufi-drv/./ufi-init.c:59: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/./ufi-init.c:61: if (ufi_read_write_sector((device_config *)dev, false, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes) != USB_ERR_OK)
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,12
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	a,0x01
	push	af
	inc	sp
	push	de
	xor	a
	push	af
	inc	sp
	push	bc
	call	_ufi_read_write_sector
	pop	af
	pop	af
	pop	af
	pop	af
	pop	af
	ld	a, l
	pop	bc
	or	a
	jr	Z,l_chufi_read_00104
;source-doc/ufi-drv/./ufi-init.c:62: return -1; // general error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00104:
;source-doc/ufi-drv/./ufi-init.c:65: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	ld	b,0x12
l_chufi_read_00139:
	ld	(hl),0x00
	inc	hl
	djnz	l_chufi_read_00139
	pop	bc
;source-doc/ufi-drv/./ufi-init.c:67: if ((result = ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK)
	ld	hl,2
	add	hl, sp
	push	hl
	push	bc
	call	_ufi_request_sense
	pop	af
	pop	af
	ld	a, l
	or	a
	jr	Z,l_chufi_read_00106
;source-doc/ufi-drv/./ufi-init.c:68: return -1; // error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00106:
;source-doc/ufi-drv/./ufi-init.c:72: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/./ufi-init.c:74: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_read_00108
;source-doc/ufi-drv/./ufi-init.c:75: return -1;
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00108:
;source-doc/ufi-drv/./ufi-init.c:77: return USB_ERR_OK;
	ld	l,0x00
l_chufi_read_00109:
;source-doc/ufi-drv/./ufi-init.c:78: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./ufi-init.c:80: usb_error chufi_write(device_config_storage *const dev, uint8_t *const buffer) {
; ---------------------------------
; Function chufi_write
; ---------------------------------
_chufi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -20
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/./ufi-init.c:82: if (wait_for_device_ready((device_config *)dev, 20) != 0)
	ld	c,(ix+4)
	ld	b,(ix+5)
	push	bc
	ld	a,0x14
	push	af
	inc	sp
	push	bc
	call	_wait_for_device_ready
	pop	af
	inc	sp
	ld	e, l
	pop	bc
	ld	a, e
	or	a
	jr	Z,l_chufi_write_00102
;source-doc/ufi-drv/./ufi-init.c:83: return -1; // Not READY!
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00102:
;source-doc/ufi-drv/./ufi-init.c:87: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/./ufi-init.c:88: if ((ufi_read_write_sector((device_config *)dev, true, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes)) != USB_ERR_OK) {
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,12
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	a,0x01
	push	af
	inc	sp
	push	de
	ld	a,0x01
	push	af
	inc	sp
	push	bc
	call	_ufi_read_write_sector
	pop	af
	pop	af
	pop	af
	pop	af
	pop	af
	ld	a, l
	pop	bc
	or	a
	jr	Z,l_chufi_write_00104
;source-doc/ufi-drv/./ufi-init.c:89: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00104:
;source-doc/ufi-drv/./ufi-init.c:93: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	ld	b,0x12
l_chufi_write_00139:
	ld	(hl),0x00
	inc	hl
	djnz	l_chufi_write_00139
	pop	bc
;source-doc/ufi-drv/./ufi-init.c:95: if ((ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK) {
	ld	hl,2
	add	hl, sp
	push	hl
	push	bc
	call	_ufi_request_sense
	pop	af
	pop	af
	ld	a, l
	or	a
	jr	Z,l_chufi_write_00106
;source-doc/ufi-drv/./ufi-init.c:96: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00106:
;source-doc/ufi-drv/./ufi-init.c:101: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/./ufi-init.c:103: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_write_00108
;source-doc/ufi-drv/./ufi-init.c:104: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00108:
;source-doc/ufi-drv/./ufi-init.c:106: return USB_ERR_OK;
	ld	l,0x00
l_chufi_write_00109:
;source-doc/ufi-drv/./ufi-init.c:107: }
	ld	sp, ix
	pop	ix
	ret
