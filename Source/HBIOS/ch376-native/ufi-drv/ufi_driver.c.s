;
; Generated from source-doc/ufi-drv/ufi_driver.c.asm -- not to be modify directly
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
;source-doc/ufi-drv/ufi_driver.c:6: uint32_t usb_ufi_get_cap(const uint16_t dev_index) {
; ---------------------------------
; Function usb_ufi_get_cap
; ---------------------------------
_usb_ufi_get_cap:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -72
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/ufi_driver.c:7: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi_driver.c:10: memset(&response, 0, sizeof(ufi_format_capacities_response));
	ld	hl,0
	add	hl, sp
	ld	b,$12
l_usb_ufi_get_cap_00112:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_usb_ufi_get_cap_00112
;source-doc/ufi-drv/ufi_driver.c:12: wait_for_device_ready(dev, 25);
	push	de
	ld	a,$19
	push	af
	inc	sp
	push	de
	call	_wait_for_device_ready
	pop	af
	inc	sp
	pop	de
;source-doc/ufi-drv/ufi_driver.c:16: ufi_inquiry(dev, &inquiry);
	push	de
	ld	hl,38
	add	hl, sp
	push	hl
	push	de
	call	_ufi_inquiry
	pop	af
	pop	af
	pop	de
;source-doc/ufi-drv/ufi_driver.c:18: wait_for_device_ready(dev, 15);
	push	de
	ld	a,$0f
	push	af
	inc	sp
	push	de
	call	_wait_for_device_ready
	pop	af
	inc	sp
	pop	de
;source-doc/ufi-drv/ufi_driver.c:20: const usb_error result = ufi_read_frmt_caps(dev, &response);
	ld	hl,0
	add	hl, sp
	push	hl
	push	de
	call	_ufi_read_frmt_caps
	pop	af
	pop	af
	ld	a, l
;source-doc/ufi-drv/ufi_driver.c:21: if (result != USB_ERR_OK)
	or	a
	jr	Z,l_usb_ufi_get_cap_00102
;source-doc/ufi-drv/ufi_driver.c:22: return 0;
	ld	hl,$0000
	ld	e, l
	ld	d, l
	jr	l_usb_ufi_get_cap_00103
l_usb_ufi_get_cap_00102:
;source-doc/ufi-drv/ufi_driver.c:24: return convert_from_msb_first(response.descriptors[0].number_of_blocks);
	ld	hl,4
	add	hl, sp
	push	hl
	call	_convert_from_msb_first
	pop	af
l_usb_ufi_get_cap_00103:
;source-doc/ufi-drv/ufi_driver.c:25: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/ufi_driver.c:27: usb_error usb_ufi_read(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function usb_ufi_read
; ---------------------------------
_usb_ufi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -20
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/ufi_driver.c:28: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi_driver.c:30: if (wait_for_device_ready((device_config *)dev, 20) != 0)
	push	de
	ld	c,e
	ld	b,d
	push	de
	ld	a,$14
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
	jr	Z,l_usb_ufi_read_00102
;source-doc/ufi-drv/ufi_driver.c:31: return -1; // Not READY!
	ld	l,$ff
	jr	l_usb_ufi_read_00109
l_usb_ufi_read_00102:
;source-doc/ufi-drv/ufi_driver.c:36: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/ufi_driver.c:38: if (ufi_read_write_sector((device_config *)dev, false, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes) != USB_ERR_OK)
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
	ld	a,$01
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
	jr	Z,l_usb_ufi_read_00104
;source-doc/ufi-drv/ufi_driver.c:39: return -1; // general error
	ld	l,$ff
	jr	l_usb_ufi_read_00109
l_usb_ufi_read_00104:
;source-doc/ufi-drv/ufi_driver.c:42: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	ld	b,$09
l_usb_ufi_read_00139:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_usb_ufi_read_00139
	pop	bc
;source-doc/ufi-drv/ufi_driver.c:44: if ((result = ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK)
	ld	hl,2
	add	hl, sp
	push	hl
	push	bc
	call	_ufi_request_sense
	pop	af
	pop	af
	ld	a, l
	or	a
	jr	Z,l_usb_ufi_read_00106
;source-doc/ufi-drv/ufi_driver.c:45: return -1; // error
	ld	l,$ff
	jr	l_usb_ufi_read_00109
l_usb_ufi_read_00106:
;source-doc/ufi-drv/ufi_driver.c:49: const uint8_t sense_key = response.sense_key & 15;
	ld	a,(ix-16)
	and	$0f
	jr	Z,l_usb_ufi_read_00108
;source-doc/ufi-drv/ufi_driver.c:51: if (sense_key != 0)
;source-doc/ufi-drv/ufi_driver.c:52: return -1;
	ld	l,$ff
	jr	l_usb_ufi_read_00109
l_usb_ufi_read_00108:
;source-doc/ufi-drv/ufi_driver.c:54: return USB_ERR_OK;
	ld	l,$00
l_usb_ufi_read_00109:
;source-doc/ufi-drv/ufi_driver.c:55: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/ufi_driver.c:57: usb_error usb_ufi_write(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function usb_ufi_write
; ---------------------------------
_usb_ufi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -20
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/ufi_driver.c:58: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/ufi-drv/ufi_driver.c:60: if (wait_for_device_ready((device_config *)dev, 20) != 0)
	push	de
	ld	c,e
	ld	b,d
	push	de
	ld	a,$14
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
	jr	Z,l_usb_ufi_write_00102
;source-doc/ufi-drv/ufi_driver.c:61: return -1; // Not READY!
	ld	l,$ff
	jr	l_usb_ufi_write_00109
l_usb_ufi_write_00102:
;source-doc/ufi-drv/ufi_driver.c:65: memset(&sense_codes, 0, sizeof(sense_codes));
	ld	hl,0
	add	hl, sp
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/ufi-drv/ufi_driver.c:66: if ((ufi_read_write_sector((device_config *)dev, true, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes)) != USB_ERR_OK) {
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
	ld	a,$01
	push	af
	inc	sp
	push	de
	ld	a,$01
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
	jr	Z,l_usb_ufi_write_00104
;source-doc/ufi-drv/ufi_driver.c:67: return -1;
	ld	l,$ff
	jr	l_usb_ufi_write_00109
l_usb_ufi_write_00104:
;source-doc/ufi-drv/ufi_driver.c:71: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	ld	b,$09
l_usb_ufi_write_00139:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_usb_ufi_write_00139
	pop	bc
;source-doc/ufi-drv/ufi_driver.c:73: if ((ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK) {
	ld	hl,2
	add	hl, sp
	push	hl
	push	bc
	call	_ufi_request_sense
	pop	af
	pop	af
	ld	a, l
	or	a
	jr	Z,l_usb_ufi_write_00106
;source-doc/ufi-drv/ufi_driver.c:74: return -1;
	ld	l,$ff
	jr	l_usb_ufi_write_00109
l_usb_ufi_write_00106:
;source-doc/ufi-drv/ufi_driver.c:79: const uint8_t sense_key = response.sense_key & 15;
	ld	a,(ix-16)
	and	$0f
	jr	Z,l_usb_ufi_write_00108
;source-doc/ufi-drv/ufi_driver.c:81: if (sense_key != 0)
;source-doc/ufi-drv/ufi_driver.c:82: return -1;
	ld	l,$ff
	jr	l_usb_ufi_write_00109
l_usb_ufi_write_00108:
;source-doc/ufi-drv/ufi_driver.c:84: return USB_ERR_OK;
	ld	l,$00
l_usb_ufi_write_00109:
;source-doc/ufi-drv/ufi_driver.c:85: }
	ld	sp, ix
	pop	ix
	ret
