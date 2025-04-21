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
;source-doc/ufi-drv/ufi-init.c:12: void chufi_init(void) {
; ---------------------------------
; Function chufi_init
; ---------------------------------
_chufi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	dec	sp
;source-doc/ufi-drv/ufi-init.c:15: do {
	ld	(ix-1),0x01
l_chufi_init_00105:
;source-doc/ufi-drv/ufi-init.c:16: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	ld	a,(ix-1)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi-init.c:18: if (storage_device == NULL)
	ld	a, d
	or	e
	jr	Z,l_chufi_init_00108
;source-doc/ufi-drv/ufi-init.c:21: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/ufi-drv/ufi-init.c:23: if (t == USB_IS_FLOPPY) {
	dec	a
	jr	NZ,l_chufi_init_00106
;source-doc/ufi-drv/ufi-init.c:24: const uint8_t dev_index = find_storage_dev();  //dev_index == -1 (no more left) should never happen
	push	de
	call	_find_storage_dev
	ld	c, l
	pop	de
;source-doc/ufi-drv/ufi-init.c:25: hbios_usb_storage_devices[dev_index].storage_device = storage_device;
	ld	(ix-3),c
	ld	(ix-2),0x00
	pop	hl
	push	hl
	add	hl, hl
	add	hl, hl
	ld	a,+((_hbios_usb_storage_devices) & 0xFF)
	add	a,l
	ld	l,a
	ld	a,+((_hbios_usb_storage_devices) / 256)
	adc	a,h
	ld	h,a
	ld	(hl), e
	inc	hl
	ld	(hl), d
	dec	hl
;source-doc/ufi-drv/ufi-init.c:26: hbios_usb_storage_devices[dev_index].drive_index = dev_index + 1;
	ld	e, l
	ld	d, h
	inc	de
	inc	de
	ld	a, c
	inc	a
	ld	(de), a
;source-doc/ufi-drv/ufi-init.c:27: hbios_usb_storage_devices[dev_index].usb_device = index;
	ld	c, l
	ld	b, h
	inc	bc
	inc	bc
	inc	bc
	ld	a,(ix-1)
	ld	(bc), a
;source-doc/ufi-drv/ufi-init.c:29: print_string("\r\nUSB: FLOPPY @ $");
	push	hl
	ld	hl,ufi_init_str_0
	call	_print_string
	pop	hl
;source-doc/ufi-drv/ufi-init.c:30: print_uint16(index);
	ld	e,(ix-1)
	ld	d,0x00
	push	hl
	ex	de, hl
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:31: print_string(":$");
	ld	hl,ufi_init_str_1
	call	_print_string
	pop	hl
;source-doc/ufi-drv/ufi-init.c:32: print_uint16(dev_index + 1);
	pop	de
	push	de
	inc	de
	push	hl
	ex	de, hl
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:33: print_string(" $");
	ld	hl,ufi_init_str_2
	call	_print_string
	pop	hl
;source-doc/ufi-drv/ufi-init.c:34: dio_add_entry(ch_ufi_fntbl, &hbios_usb_storage_devices[dev_index]);
	ex	de, hl
	ld	hl,_ch_ufi_fntbl
	call	_dio_add_entry
l_chufi_init_00106:
;source-doc/ufi-drv/ufi-init.c:37: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_chufi_init_00105
l_chufi_init_00108:
;source-doc/ufi-drv/ufi-init.c:38: }
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
;source-doc/ufi-drv/ufi-init.c:40: uint32_t chufi_get_cap(device_config *const dev) {
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
;source-doc/ufi-drv/ufi-init.c:42: memset(&response, 0, sizeof(ufi_format_capacities_response));
	ld	hl,0
	add	hl, sp
	ld	b,0x12
l_chufi_get_cap_00112:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_chufi_get_cap_00112
;source-doc/ufi-drv/ufi-init.c:44: wait_for_device_ready(dev, 25);
	ld	a,0x19
	push	af
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_wait_for_device_ready
	pop	af
	inc	sp
;source-doc/ufi-drv/ufi-init.c:48: ufi_inquiry(dev, &inquiry);
	ld	hl,36
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ufi_inquiry
	pop	af
;source-doc/ufi-drv/ufi-init.c:50: wait_for_device_ready(dev, 15);
	ld	h,0x0f
	ex	(sp),hl
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_wait_for_device_ready
	pop	af
	inc	sp
;source-doc/ufi-drv/ufi-init.c:52: const usb_error result = ufi_read_frmt_caps(dev, &response);
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
;source-doc/ufi-drv/ufi-init.c:53: if (result != USB_ERR_OK)
	or	a
	jr	Z,l_chufi_get_cap_00102
;source-doc/ufi-drv/ufi-init.c:54: return 0;
	ld	hl,0x0000
	ld	e, l
	ld	d, l
	jr	l_chufi_get_cap_00103
l_chufi_get_cap_00102:
;source-doc/ufi-drv/ufi-init.c:56: return convert_from_msb_first(response.descriptors[0].number_of_blocks);
	ld	hl,4
	add	hl, sp
	push	hl
	call	_convert_from_msb_first
	pop	af
l_chufi_get_cap_00103:
;source-doc/ufi-drv/ufi-init.c:57: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/ufi-init.c:59: uint8_t chufi_read(device_config_storage *const dev, uint8_t *const buffer) {
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
;source-doc/ufi-drv/ufi-init.c:61: if (wait_for_device_ready((device_config *)dev, 20) != 0)
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
	ld	a, l
	pop	bc
	or	a
	jr	Z,l_chufi_read_00102
;source-doc/ufi-drv/ufi-init.c:62: return -1; // Not READY!
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00102:
;source-doc/ufi-drv/ufi-init.c:67: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/ufi-init.c:69: if (ufi_read_write_sector((device_config *)dev, false, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes) != USB_ERR_OK)
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
;source-doc/ufi-drv/ufi-init.c:70: return -1; // general error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00104:
;source-doc/ufi-drv/ufi-init.c:73: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	ld	b,0x09
l_chufi_read_00139:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_chufi_read_00139
	pop	bc
;source-doc/ufi-drv/ufi-init.c:75: if ((result = ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK)
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
;source-doc/ufi-drv/ufi-init.c:76: return -1; // error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00106:
;source-doc/ufi-drv/ufi-init.c:80: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/ufi-init.c:82: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_read_00108
;source-doc/ufi-drv/ufi-init.c:83: return -1;
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00108:
;source-doc/ufi-drv/ufi-init.c:85: return USB_ERR_OK;
	ld	l,0x00
l_chufi_read_00109:
;source-doc/ufi-drv/ufi-init.c:86: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/ufi-init.c:88: usb_error chufi_write(device_config_storage *const dev, uint8_t *const buffer) {
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
;source-doc/ufi-drv/ufi-init.c:90: if (wait_for_device_ready((device_config *)dev, 20) != 0)
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
	ld	a, l
	pop	bc
	or	a
	jr	Z,l_chufi_write_00102
;source-doc/ufi-drv/ufi-init.c:91: return -1; // Not READY!
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00102:
;source-doc/ufi-drv/ufi-init.c:95: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/ufi-init.c:96: if ((ufi_read_write_sector((device_config *)dev, true, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes)) != USB_ERR_OK) {
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
;source-doc/ufi-drv/ufi-init.c:97: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00104:
;source-doc/ufi-drv/ufi-init.c:101: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	ld	b,0x09
l_chufi_write_00139:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_chufi_write_00139
	pop	bc
;source-doc/ufi-drv/ufi-init.c:103: if ((ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK) {
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
;source-doc/ufi-drv/ufi-init.c:104: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00106:
;source-doc/ufi-drv/ufi-init.c:109: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/ufi-init.c:111: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_write_00108
;source-doc/ufi-drv/ufi-init.c:112: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00108:
;source-doc/ufi-drv/ufi-init.c:114: return USB_ERR_OK;
	ld	l,0x00
l_chufi_write_00109:
;source-doc/ufi-drv/ufi-init.c:115: }
	ld	sp, ix
	pop	ix
	ret
