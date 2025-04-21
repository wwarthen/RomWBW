;
; Generated from source-doc/scsi-drv/scsi_driver.c.asm -- not to be modify directly
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
	
_scsi_packet_read_capacity:
	DEFS 12
_cbw:
	DEFS 27
	
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
;source-doc/scsi-drv/scsi_driver.c:8: usb_error usb_scsi_init(const uint16_t dev_index) {
; ---------------------------------
; Function usb_scsi_init
; ---------------------------------
_usb_scsi_init:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -18
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/scsi_driver.c:9: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/scsi-drv/scsi_driver.c:14: critical_begin();
	push	de
	call	_critical_begin
	pop	de
;source-doc/scsi-drv/scsi_driver.c:15: while ((result = scsi_test(dev)) && --counter > 0)
	ld	c,0x03
l_usb_scsi_init_00102:
	push	bc
	push	de
	push	de
	call	_scsi_test
	pop	af
	ld	a, l
	pop	de
	pop	bc
	ld	(_result),a
	or	a
	jr	Z,l_usb_scsi_init_00104
	dec	c
	jr	Z,l_usb_scsi_init_00104
;source-doc/scsi-drv/scsi_driver.c:16: scsi_request_sense(dev, &response);
	ld	hl,0
	add	hl, sp
	push	bc
	push	de
	push	hl
	push	de
	call	_scsi_request_sense
	pop	af
	pop	af
	pop	de
	pop	bc
	jr	l_usb_scsi_init_00102
l_usb_scsi_init_00104:
;source-doc/scsi-drv/scsi_driver.c:17: critical_end();
	call	_critical_end
;source-doc/scsi-drv/scsi_driver.c:19: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/scsi_driver.c:20: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/scsi_driver.c:24: usb_error usb_scsi_read_capacity(const uint16_t dev_index, scsi_read_capacity_result *cap_result) {
; ---------------------------------
; Function usb_scsi_read_capacity
; ---------------------------------
_usb_scsi_read_capacity:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -27
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/scsi_driver.c:25: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/scsi-drv/scsi_driver.c:28: cbw_scsi.cbw           = scsi_command_block_wrapper;
	push	de
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
	pop	de
;source-doc/scsi-drv/scsi_driver.c:29: cbw_scsi.read_capacity = scsi_packet_read_capacity;
	push	de
	ld	hl,17
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_read_capacity
	ldir
	pop	de
;source-doc/scsi-drv/scsi_driver.c:31: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/scsi_driver.c:32: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_read_capacity);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/scsi_driver.c:33: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_read_capacity_result);
	ld	(ix-19),0x08
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/scsi_driver.c:35: return do_scsi_cmd(dev, &cbw_scsi.cbw, cap_result, false);
	ld	c,(ix+6)
	ld	b,(ix+7)
	xor	a
	push	af
	inc	sp
	push	bc
	ld	hl,3
	add	hl, sp
	push	hl
	push	de
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
;source-doc/scsi-drv/scsi_driver.c:36: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/scsi_driver.c:56: usb_error usb_scsi_read(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function usb_scsi_read
; ---------------------------------
_usb_scsi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/scsi_driver.c:57: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	pop	bc
	push	de
;source-doc/scsi-drv/scsi_driver.c:59: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	de,_cbw
	ld	l, e
	ld	h, d
	ld	b,0x0e
	jr	l_usb_scsi_read_00113
l_usb_scsi_read_00112:
	ld	(hl),0x00
	inc	hl
l_usb_scsi_read_00113:
	ld	(hl),0x00
	inc	hl
	djnz	l_usb_scsi_read_00112
;source-doc/scsi-drv/scsi_driver.c:60: cbw.cbw = scsi_command_block_wrapper;
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/scsi_driver.c:62: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),0x00
;source-doc/scsi-drv/scsi_driver.c:63: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),0x0c
;source-doc/scsi-drv/scsi_driver.c:64: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/scsi_driver.c:66: cbw.scsi_cmd.operation_code  = 0x28; // read operation
	ld	hl,_cbw + 15
	ld	(hl),0x28
;source-doc/scsi-drv/scsi_driver.c:67: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),0x01
;source-doc/scsi-drv/scsi_driver.c:68: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	bc,0x000c
	add	hl,bc
	ld	c,l
	ld	b,h
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 17)),a
;source-doc/scsi-drv/scsi_driver.c:69: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
;source-doc/scsi-drv/scsi_driver.c:70: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	ld	a,(hl)
	ld	((_cbw + 18)),a
	dec	hl
	ld	e, (hl)
	ld	hl, +(_cbw + 19)
	ld	(hl), e
;source-doc/scsi-drv/scsi_driver.c:71: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	a, (bc)
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/scsi_driver.c:73: result = do_scsi_cmd(dev, &cbw.cbw, buffer, false);
	ld	e,(ix+6)
	ld	d,(ix+7)
	push	bc
	xor	a
	push	af
	inc	sp
	push	de
	ld	hl,_cbw
	push	hl
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	bc
	ld	a, l
	ld	(_result), a
;source-doc/scsi-drv/scsi_driver.c:75: if (result == USB_ERR_OK)
	ld	a,(_result)
	or	a
	jr	NZ,l_usb_scsi_read_00102
;source-doc/scsi-drv/scsi_driver.c:76: dev->current_lba++;
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	inc	e
	jr	NZ,l_usb_scsi_read_00114
	inc	d
	jr	NZ,l_usb_scsi_read_00114
	inc	hl
l_usb_scsi_read_00114:
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	ld	(bc), a
	inc	bc
	ld	a, l
	ld	(bc), a
	inc	bc
	ld	a, h
	ld	(bc), a
l_usb_scsi_read_00102:
;source-doc/scsi-drv/scsi_driver.c:77: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/scsi_driver.c:78: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/scsi_driver.c:80: usb_error usb_scsi_write(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function usb_scsi_write
; ---------------------------------
_usb_scsi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/scsi_driver.c:81: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	pop	bc
	push	de
;source-doc/scsi-drv/scsi_driver.c:83: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	de,_cbw
	ld	l, e
	ld	h, d
	ld	b,0x0e
	jr	l_usb_scsi_write_00113
l_usb_scsi_write_00112:
	ld	(hl),0x00
	inc	hl
l_usb_scsi_write_00113:
	ld	(hl),0x00
	inc	hl
	djnz	l_usb_scsi_write_00112
;source-doc/scsi-drv/scsi_driver.c:84: cbw.cbw = scsi_command_block_wrapper;
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/scsi_driver.c:86: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),0x00
;source-doc/scsi-drv/scsi_driver.c:87: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),0x0c
;source-doc/scsi-drv/scsi_driver.c:88: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/scsi_driver.c:90: cbw.scsi_cmd.operation_code  = 0x2A; // write operation
	ld	hl,_cbw + 15
	ld	(hl),0x2a
;source-doc/scsi-drv/scsi_driver.c:91: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),0x01
;source-doc/scsi-drv/scsi_driver.c:92: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	bc,0x000c
	add	hl,bc
	ld	c,l
	ld	b,h
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 17)),a
;source-doc/scsi-drv/scsi_driver.c:93: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
;source-doc/scsi-drv/scsi_driver.c:94: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	ld	l,c
	ld	h,b
	inc	hl
	inc	hl
	ld	a,(hl)
	ld	((_cbw + 18)),a
	dec	hl
	ld	e, (hl)
	ld	hl, +(_cbw + 19)
	ld	(hl), e
;source-doc/scsi-drv/scsi_driver.c:95: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	a, (bc)
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/scsi_driver.c:97: result = do_scsi_cmd(dev, &cbw.cbw, buffer, true);
	ld	e,(ix+6)
	ld	d,(ix+7)
	push	bc
	ld	a,0x01
	push	af
	inc	sp
	push	de
	ld	hl,_cbw
	push	hl
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	bc
	ld	a, l
	ld	(_result), a
;source-doc/scsi-drv/scsi_driver.c:99: if (result == USB_ERR_OK)
	ld	a,(_result)
	or	a
	jr	NZ,l_usb_scsi_write_00102
;source-doc/scsi-drv/scsi_driver.c:100: dev->current_lba++;
	ld	l, c
	ld	h, b
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	inc	e
	jr	NZ,l_usb_scsi_write_00114
	inc	d
	jr	NZ,l_usb_scsi_write_00114
	inc	hl
l_usb_scsi_write_00114:
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	ld	(bc), a
	inc	bc
	ld	a, l
	ld	(bc), a
	inc	bc
	ld	a, h
	ld	(bc), a
l_usb_scsi_write_00102:
;source-doc/scsi-drv/scsi_driver.c:101: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/scsi_driver.c:102: }
	ld	sp, ix
	pop	ix
	ret
_scsi_packet_read_capacity:
	DEFB +0x25
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
_cbw:
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB +0x00,0x00, +0x00, +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
