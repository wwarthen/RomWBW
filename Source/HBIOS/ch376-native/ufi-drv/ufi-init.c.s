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
	ld	l, e
;source-doc/ufi-drv/ufi-init.c:18: if (storage_device == NULL)
	ld	a,d
	ld	h,a
	or	e
	jr	Z,l_chufi_init_00108
;source-doc/ufi-drv/ufi-init.c:21: const usb_device_type t = storage_device->type;
	ld	a, (hl)
	and	0x0f
;source-doc/ufi-drv/ufi-init.c:23: if (t == USB_IS_FLOPPY) {
	dec	a
	jr	NZ,l_chufi_init_00106
;source-doc/ufi-drv/ufi-init.c:24: const uint8_t dev_index                          = find_storage_dev(); // dev_index == -1 (no more left) should never happen
	call	_find_storage_dev
;source-doc/ufi-drv/ufi-init.c:25: hbios_usb_storage_devices[dev_index].drive_index = dev_index + 1;
	ld	(ix-3),l
	ld	(ix-2),0x00
	ld	c,l
	pop	hl
	push	hl
	add	hl, hl
	ld	de,_hbios_usb_storage_devices
	add	hl, de
	ld	e,l
	ld	d,h
	inc	c
	ld	(hl), c
;source-doc/ufi-drv/ufi-init.c:26: hbios_usb_storage_devices[dev_index].usb_device  = index;
	ld	c, e
	ld	b, d
	inc	bc
	ld	a,(ix-1)
	ld	(bc), a
;source-doc/ufi-drv/ufi-init.c:28: print_string("\r\nUSB: FLOPPY @ $");
	push	de
	ld	hl,ufi_init_str_0
	call	_print_string
	pop	de
;source-doc/ufi-drv/ufi-init.c:29: print_uint16(index);
	ld	l,(ix-1)
	ld	h,0x00
	push	de
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:30: print_string(":$");
	ld	hl,ufi_init_str_1
	call	_print_string
	pop	de
;source-doc/ufi-drv/ufi-init.c:31: print_uint16(dev_index + 1);
	pop	hl
	push	hl
	inc	hl
	push	de
	call	_print_uint16
;source-doc/ufi-drv/ufi-init.c:32: print_string(" $");
	ld	hl,ufi_init_str_2
	call	_print_string
	pop	de
;source-doc/ufi-drv/ufi-init.c:33: dio_add_entry(ch_ufi_fntbl, &hbios_usb_storage_devices[dev_index]);
	ld	hl,_ch_ufi_fntbl
	call	_dio_add_entry
l_chufi_init_00106:
;source-doc/ufi-drv/ufi-init.c:36: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_chufi_init_00105
l_chufi_init_00108:
;source-doc/ufi-drv/ufi-init.c:37: }
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
;source-doc/ufi-drv/ufi-init.c:39: uint32_t chufi_get_cap(const uint16_t dev_index) {
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
;source-doc/ufi-drv/ufi-init.c:40: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi-init.c:43: memset(&response, 0, sizeof(ufi_format_capacities_response));
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
;source-doc/ufi-drv/ufi-init.c:45: wait_for_device_ready(dev, 25);
	push	de
	ld	a,0x19
	push	af
	inc	sp
	push	de
	call	_wait_for_device_ready
	pop	af
	inc	sp
	pop	de
;source-doc/ufi-drv/ufi-init.c:49: ufi_inquiry(dev, &inquiry);
	push	de
	ld	hl,38
	add	hl, sp
	push	hl
	push	de
	call	_ufi_inquiry
	pop	af
	pop	af
	pop	de
;source-doc/ufi-drv/ufi-init.c:51: wait_for_device_ready(dev, 15);
	push	de
	ld	a,0x0f
	push	af
	inc	sp
	push	de
	call	_wait_for_device_ready
	pop	af
	inc	sp
	pop	de
;source-doc/ufi-drv/ufi-init.c:53: const usb_error result = ufi_read_frmt_caps(dev, &response);
	ld	hl,0
	add	hl, sp
	push	hl
	push	de
	call	_ufi_read_frmt_caps
	pop	af
	pop	af
	ld	a, l
;source-doc/ufi-drv/ufi-init.c:54: if (result != USB_ERR_OK)
	or	a
	jr	Z,l_chufi_get_cap_00102
;source-doc/ufi-drv/ufi-init.c:55: return 0;
	ld	hl,0x0000
	ld	e, l
	ld	d, l
	jr	l_chufi_get_cap_00103
l_chufi_get_cap_00102:
;source-doc/ufi-drv/ufi-init.c:57: return convert_from_msb_first(response.descriptors[0].number_of_blocks);
	ld	hl,4
	add	hl, sp
	push	hl
	call	_convert_from_msb_first
	pop	af
l_chufi_get_cap_00103:
;source-doc/ufi-drv/ufi-init.c:58: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/ufi-init.c:60: uint8_t chufi_read(const uint16_t dev_index, uint8_t *const buffer) {
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
;source-doc/ufi-drv/ufi-init.c:61: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi-init.c:63: if (wait_for_device_ready((device_config *)dev, 20) != 0)
	push	de
	ld	c,e
	ld	b,d
	push	de
	ld	a,0x14
	push	af
	inc	sp
	push	bc
	call	_wait_for_device_ready
	pop	af
	inc	sp
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	Z,l_chufi_read_00102
;source-doc/ufi-drv/ufi-init.c:64: return -1; // Not READY!
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00102:
;source-doc/ufi-drv/ufi-init.c:69: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/ufi-init.c:71: if (ufi_read_write_sector((device_config *)dev, false, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes) != USB_ERR_OK)
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
;source-doc/ufi-drv/ufi-init.c:72: return -1; // general error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00104:
;source-doc/ufi-drv/ufi-init.c:75: memset(&response, 0, sizeof(response));
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
;source-doc/ufi-drv/ufi-init.c:77: if ((result = ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK)
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
;source-doc/ufi-drv/ufi-init.c:78: return -1; // error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00106:
;source-doc/ufi-drv/ufi-init.c:82: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/ufi-init.c:84: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_read_00108
;source-doc/ufi-drv/ufi-init.c:85: return -1;
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00108:
;source-doc/ufi-drv/ufi-init.c:87: return USB_ERR_OK;
	ld	l,0x00
l_chufi_read_00109:
;source-doc/ufi-drv/ufi-init.c:88: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/ufi-init.c:90: usb_error chufi_write(const uint16_t dev_index, uint8_t *const buffer) {
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
;source-doc/ufi-drv/ufi-init.c:91: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi-init.c:93: if (wait_for_device_ready((device_config *)dev, 20) != 0)
	push	de
	ld	c,e
	ld	b,d
	push	de
	ld	a,0x14
	push	af
	inc	sp
	push	bc
	call	_wait_for_device_ready
	pop	af
	inc	sp
	ld	a, l
	pop	de
	pop	bc
	or	a
	jr	Z,l_chufi_write_00102
;source-doc/ufi-drv/ufi-init.c:94: return -1; // Not READY!
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00102:
;source-doc/ufi-drv/ufi-init.c:98: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/ufi-init.c:99: if ((ufi_read_write_sector((device_config *)dev, true, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes)) != USB_ERR_OK) {
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
;source-doc/ufi-drv/ufi-init.c:100: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00104:
;source-doc/ufi-drv/ufi-init.c:104: memset(&response, 0, sizeof(response));
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
;source-doc/ufi-drv/ufi-init.c:106: if ((ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK) {
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
;source-doc/ufi-drv/ufi-init.c:107: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00106:
;source-doc/ufi-drv/ufi-init.c:112: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/ufi-init.c:114: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_write_00108
;source-doc/ufi-drv/ufi-init.c:115: return -1;
	ld	l,0xff
	jr	l_chufi_write_00109
l_chufi_write_00108:
;source-doc/ufi-drv/ufi-init.c:117: return USB_ERR_OK;
	ld	l,0x00
l_chufi_write_00109:
;source-doc/ufi-drv/ufi-init.c:118: }
	ld	sp, ix
	pop	ix
	ret
