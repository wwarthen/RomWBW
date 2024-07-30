;
; Generated from source-doc/ufi-drv/./ufi-init.c.asm -- not to be modify directly
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
;source-doc/ufi-drv/./ufi-init.c:11: void chufi_init(void) {
; ---------------------------------
; Function chufi_init
; ---------------------------------
_chufi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/ufi-drv/./ufi-init.c:14: do {
	ld	(ix-1),0x01
l_chufi_init_00105:
;source-doc/ufi-drv/./ufi-init.c:15: device_config_storage *const storage_device = (device_config_storage *)get_usb_device_config(index);
	ld	a,(ix-1)
	call	_get_usb_device_config
;source-doc/ufi-drv/./ufi-init.c:17: if (storage_device == NULL)
	ld	a, d
	or	e
	jr	Z,l_chufi_init_00107
;source-doc/ufi-drv/./ufi-init.c:20: const usb_device_type t = storage_device->type;
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	0x0f
;source-doc/ufi-drv/./ufi-init.c:22: if (t == USB_IS_FLOPPY) {
	dec	a
	jr	NZ,l_chufi_init_00106
;source-doc/ufi-drv/./ufi-init.c:23: storage_device->drive_index = storage_count++;
	ld	hl,0x0010
	add	hl, de
	ld	a,(_storage_count+0)
	ld	(ix-2),a
	ld	c,l
	ld	b,h
	ld	hl,_storage_count+0
	inc	(hl)
	ld	a,(ix-2)
	ld	(bc), a
;source-doc/ufi-drv/./ufi-init.c:25: dio_add_entry(ch_ufi_fntbl, storage_device);
	ld	hl,_ch_ufi_fntbl
	call	_dio_add_entry
l_chufi_init_00106:
;source-doc/ufi-drv/./ufi-init.c:28: } while (++index != MAX_NUMBER_OF_DEVICES + 1);
	inc	(ix-1)
	ld	a,(ix-1)
	sub	0x07
	jr	NZ,l_chufi_init_00105
l_chufi_init_00107:
;source-doc/ufi-drv/./ufi-init.c:30: if (storage_count == 0)
;source-doc/ufi-drv/./ufi-init.c:31: return;
;source-doc/ufi-drv/./ufi-init.c:33: print_device_mounted(" FLOPPY DRIVE$", storage_count);
	ld	a,(_storage_count+0)
	or	a
	jr	Z,l_chufi_init_00110
	push	af
	inc	sp
	ld	hl,ufi_init_str_0
	push	hl
	call	_print_device_mounted
	pop	af
	inc	sp
l_chufi_init_00110:
;source-doc/ufi-drv/./ufi-init.c:34: }
	ld	sp, ix
	pop	ix
	ret
ufi_init_str_0:
	DEFM " FLOPPY DRIVE$"
	DEFB 0x00
;source-doc/ufi-drv/./ufi-init.c:36: uint32_t chufi_get_cap(device_config *const dev) {
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
;source-doc/ufi-drv/./ufi-init.c:38: memset(&response, 0, sizeof(ufi_format_capacities_response));
	ld	hl,0
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x24
	push	hl
	call	_memset_callee
;source-doc/ufi-drv/./ufi-init.c:40: wait_for_device_ready(dev, 25);
	ld	a,0x19
	push	af
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_wait_for_device_ready
	pop	af
	inc	sp
;source-doc/ufi-drv/./ufi-init.c:44: ufi_inquiry(dev, &inquiry);
	ld	hl,36
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ufi_inquiry
	pop	af
;source-doc/ufi-drv/./ufi-init.c:46: wait_for_device_ready(dev, 15);
	ld	h,0x0f
	ex	(sp),hl
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_wait_for_device_ready
	pop	af
	inc	sp
;source-doc/ufi-drv/./ufi-init.c:48: const usb_error result = ufi_read_frmt_caps(dev, &response);
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
;source-doc/ufi-drv/./ufi-init.c:49: if (result != USB_ERR_OK)
	or	a
	jr	Z,l_chufi_get_cap_00102
;source-doc/ufi-drv/./ufi-init.c:50: return 0;
	ld	hl,0x0000
	ld	e, l
	ld	d, l
	jr	l_chufi_get_cap_00103
l_chufi_get_cap_00102:
;source-doc/ufi-drv/./ufi-init.c:53: return convert_from_msb_first(response.descriptors[0].number_of_blocks);
	ld	hl,4
	add	hl, sp
	push	hl
	call	_convert_from_msb_first
	pop	af
l_chufi_get_cap_00103:
;source-doc/ufi-drv/./ufi-init.c:63: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./ufi-init.c:65: uint8_t chufi_read(device_config_storage *const dev, uint8_t *const buffer) {
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
;source-doc/ufi-drv/./ufi-init.c:67: if (wait_for_device_ready((device_config *)dev, 20) != 0)
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
;source-doc/ufi-drv/./ufi-init.c:68: return -1; // Not READY!
	ld	l,0xff
	jp	l_chufi_read_00109
l_chufi_read_00102:
;source-doc/ufi-drv/./ufi-init.c:73: memset(&sense_codes, 0, sizeof(sense_codes));
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x02
	push	hl
	call	_memset_callee
	pop	bc
;source-doc/ufi-drv/./ufi-init.c:75: if (ufi_read_write_sector((device_config *)dev, false, dev->current_lba, 1, buffer, (uint8_t *)&sense_codes) != USB_ERR_OK)
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
	ld	iy,10
	add	iy, sp
	ld	sp, iy
	ld	a, l
	pop	bc
	or	a
	jr	Z,l_chufi_read_00104
;source-doc/ufi-drv/./ufi-init.c:76: return -1; // general error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00104:
;source-doc/ufi-drv/./ufi-init.c:79: memset(&response, 0, sizeof(response));
	push	bc
	ld	hl,4
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x12
	push	hl
	call	_memset_callee
	pop	bc
;source-doc/ufi-drv/./ufi-init.c:81: if ((result = ufi_request_sense((device_config *)dev, &response)) != USB_ERR_OK)
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
;source-doc/ufi-drv/./ufi-init.c:82: return -1; // error
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00106:
;source-doc/ufi-drv/./ufi-init.c:86: const uint8_t sense_key = response.sense_key;
	ld	hl,4
	add	hl, sp
	ld	a, (hl)
;source-doc/ufi-drv/./ufi-init.c:88: if (sense_key != 0)
	and	0x0f
	jr	Z,l_chufi_read_00108
;source-doc/ufi-drv/./ufi-init.c:89: return -1;
	ld	l,0xff
	jr	l_chufi_read_00109
l_chufi_read_00108:
;source-doc/ufi-drv/./ufi-init.c:91: return USB_ERR_OK;
	ld	l,0x00
l_chufi_read_00109:
;source-doc/ufi-drv/./ufi-init.c:92: }
	ld	sp, ix
	pop	ix
	ret
