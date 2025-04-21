;
; Generated from source-doc/scsi-drv/class_scsi.c.asm -- not to be modify directly
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
	
_scsi_command_block_wrapper:
	DEFS 15
_next_tag:
	DEFS 2
_csw:
	DEFS 13
_scsi_packet_read_capacity:
	DEFS 12
_scsi_packet_request_sense:
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
;source-doc/scsi-drv/class_scsi.c:13: usb_error do_scsi_cmd(device_config_storage *const       dev,
; ---------------------------------
; Function do_scsi_cmd
; ---------------------------------
_do_scsi_cmd:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -8
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:18: cbw->dCBWTag[0] = next_tag++;
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,0x0004
	add	hl, bc
	ex	(sp), hl
	ld	a, (_next_tag)
	ld	e, a
	ld	hl,_next_tag + 1
	ld	d, (hl)
	ld	hl, (_next_tag)
	inc	hl
	ld	(_next_tag), hl
	pop	hl
	push	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/scsi-drv/class_scsi.c:20: if (!send)
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00102
;source-doc/scsi-drv/class_scsi.c:21: cbw->bmCBWFlags = 0x80;
	ld	hl,0x000c
	add	hl, bc
	ld	(hl),0x80
l_do_scsi_cmd_00102:
;source-doc/scsi-drv/class_scsi.c:23: critical_begin();
	push	bc
	call	_critical_begin
	pop	bc
;source-doc/scsi-drv/class_scsi.c:26: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	a,(ix+4)
	ld	(ix-6),a
	ld	e, a
	ld	a,(ix+5)
	ld	(ix-5),a
	ld	d,a
	inc	de
	inc	de
	inc	de
	ld	a,(ix-6)
	ld	(ix-4),a
	ld	l, a
	ld	a,(ix-5)
	ld	(ix-3),a
	ld	h,a
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	bc
	push	de
	push	de
	push	af
	inc	sp
	push	hl
	ld	hl,0x001f
	ex	(sp), hl
	push	hl
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	de
	pop	bc
	ld	a, l
	ld	(_result), a
	ld	a,(_result)
	or	a
	jp	NZ, l_do_scsi_cmd_00120
;source-doc/scsi-drv/class_scsi.c:28: if (cbw->dCBWDataTransferLength != 0) {
	ld	hl,8
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	inc	hl
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	or	l
	or	b
	or	c
	jr	Z,l_do_scsi_cmd_00113
;source-doc/scsi-drv/class_scsi.c:31: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix+8)
	ld	(ix-2),a
	ld	a,(ix+9)
	ld	(ix-1),a
;source-doc/scsi-drv/class_scsi.c:29: if (!send) {
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00110
;source-doc/scsi-drv/class_scsi.c:31: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix-6)
	add	a,0x06
	ld	e, a
	ld	a,(ix-5)
	adc	a,0x00
	ld	d, a
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	de
	push	af
	inc	sp
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	ld	(_result), a
	ld	a,(_result)
	or	a
	jr	Z,l_do_scsi_cmd_00113
	jp	l_do_scsi_cmd_00120
l_do_scsi_cmd_00110:
;source-doc/scsi-drv/class_scsi.c:35: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	de
	push	af
	inc	sp
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	ld	(_result), a
	ld	a,(_result)
	or	a
	jr	NZ,l_do_scsi_cmd_00120
l_do_scsi_cmd_00113:
;source-doc/scsi-drv/class_scsi.c:40: usb_data_in_transfer((uint8_t *)&csw, sizeof(_scsi_command_status_wrapper), dev->address, &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix-6)
	add	a,0x06
	ld	e, a
	ld	a,(ix-5)
	adc	a,0x00
	ld	d, a
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	push	de
	push	bc
	inc	sp
	ld	hl,0x000d
	push	hl
	ld	hl,_csw
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	ld	(_result), a
	ld	a,(_result)
	or	a
	jr	NZ,l_do_scsi_cmd_00120
;source-doc/scsi-drv/class_scsi.c:42: if (csw.bCSWStatus != 0 && csw.dCSWTag[0] != cbw->dCBWTag[0])
	ld	a, (_csw + 12)
	or	a
	jr	Z,l_do_scsi_cmd_00117
	ld	bc, (_csw + 4)
	pop	hl
	ld	a,(hl)
	push	hl
	inc	hl
	ld	h, (hl)
	ld	l, a
	xor	a
	sbc	hl,bc
	jr	Z,l_do_scsi_cmd_00117
;source-doc/scsi-drv/class_scsi.c:43: result = USB_ERR_FAIL;
	ld	hl,_result
	ld	(hl),0x0e
	jr	l_do_scsi_cmd_00120
l_do_scsi_cmd_00117:
;source-doc/scsi-drv/class_scsi.c:45: result = USB_ERR_OK;
	xor	a
	ld	(_result),a
;source-doc/scsi-drv/class_scsi.c:47: done:
l_do_scsi_cmd_00120:
;source-doc/scsi-drv/class_scsi.c:48: critical_end();
	call	_critical_end
;source-doc/scsi-drv/class_scsi.c:49: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/class_scsi.c:50: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:54: usb_error scsi_read_capacity(const uint16_t dev_index, scsi_read_capacity_result *cap_result) {
; ---------------------------------
; Function scsi_read_capacity
; ---------------------------------
_scsi_read_capacity:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -27
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:55: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/scsi-drv/class_scsi.c:58: cbw_scsi.cbw           = scsi_command_block_wrapper;
	push	de
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
	pop	de
;source-doc/scsi-drv/class_scsi.c:59: cbw_scsi.read_capacity = scsi_packet_read_capacity;
	push	de
	ld	hl,17
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_read_capacity
	ldir
	pop	de
;source-doc/scsi-drv/class_scsi.c:61: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:62: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_read_capacity);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:63: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_read_capacity_result);
	ld	(ix-19),0x08
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/class_scsi.c:65: return do_scsi_cmd(dev, &cbw_scsi.cbw, cap_result, false);
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
;source-doc/scsi-drv/class_scsi.c:66: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:84: static usb_error scsi_test(device_config_storage *const dev) {
; ---------------------------------
; Function scsi_test
; ---------------------------------
_scsi_test:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -27
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:86: cbw_scsi.cbw = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:87: memset(&cbw_scsi.test, 0, sizeof(_scsi_packet_test));
	ld	hl,17
	add	hl, sp
	ld	b,0x06
l_scsi_test_00103:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_scsi_test_00103
	pop	bc
;source-doc/scsi-drv/class_scsi.c:89: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:90: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_test);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:91: cbw_scsi.cbw.dCBWDataTransferLength = 0;
	ld	hl,0x0008
	add	hl, bc
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/class_scsi.c:93: return do_scsi_cmd(dev, &cbw_scsi.cbw, 0, false);
	xor	a
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:94: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:98: static usb_error scsi_request_sense(device_config_storage *const dev, scsi_sense_result *const sens_result) {
; ---------------------------------
; Function scsi_request_sense
; ---------------------------------
_scsi_request_sense:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -27
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:100: cbw_scsi.cbw           = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:101: cbw_scsi.request_sense = scsi_packet_request_sense;
	ld	hl,17
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_request_sense
	ldir
	pop	bc
;source-doc/scsi-drv/class_scsi.c:103: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:104: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_request_sense);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:105: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_sense_result);
	ld	hl,0x0008
	add	hl, bc
	ld	(hl),0x12
	inc	hl
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/class_scsi.c:107: return do_scsi_cmd(dev, &cbw_scsi.cbw, sens_result, false);
	ld	e,(ix+6)
	ld	d,(ix+7)
	xor	a
	push	af
	inc	sp
	push	de
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:108: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:110: usb_error scsi_sense_init(const uint16_t dev_index) {
; ---------------------------------
; Function scsi_sense_init
; ---------------------------------
_scsi_sense_init:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -18
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:111: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/scsi-drv/class_scsi.c:116: critical_begin();
	push	de
	call	_critical_begin
	pop	de
;source-doc/scsi-drv/class_scsi.c:117: while ((result = scsi_test(dev)) && --counter > 0)
	ld	c,0x03
l_scsi_sense_init_00102:
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
	jr	Z,l_scsi_sense_init_00104
	dec	c
	jr	Z,l_scsi_sense_init_00104
;source-doc/scsi-drv/class_scsi.c:118: scsi_request_sense(dev, &response);
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
	jr	l_scsi_sense_init_00102
l_scsi_sense_init_00104:
;source-doc/scsi-drv/class_scsi.c:119: critical_end();
	call	_critical_end
;source-doc/scsi-drv/class_scsi.c:121: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/class_scsi.c:122: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:126: usb_error scsi_read(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function scsi_read
; ---------------------------------
_scsi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/class_scsi.c:127: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	pop	bc
	push	de
;source-doc/scsi-drv/class_scsi.c:129: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	de,_cbw
	ld	l, e
	ld	h, d
	ld	b,0x0e
	jr	l_scsi_read_00113
l_scsi_read_00112:
	ld	(hl),0x00
	inc	hl
l_scsi_read_00113:
	ld	(hl),0x00
	inc	hl
	djnz	l_scsi_read_00112
;source-doc/scsi-drv/class_scsi.c:130: cbw.cbw = scsi_command_block_wrapper;
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:132: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),0x00
;source-doc/scsi-drv/class_scsi.c:133: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),0x0c
;source-doc/scsi-drv/class_scsi.c:134: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/class_scsi.c:136: cbw.scsi_cmd.operation_code  = 0x28; // read operation
	ld	hl,_cbw + 15
	ld	(hl),0x28
;source-doc/scsi-drv/class_scsi.c:137: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),0x01
;source-doc/scsi-drv/class_scsi.c:138: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
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
;source-doc/scsi-drv/class_scsi.c:139: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
;source-doc/scsi-drv/class_scsi.c:140: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
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
;source-doc/scsi-drv/class_scsi.c:141: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	a, (bc)
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/class_scsi.c:143: result = do_scsi_cmd(dev, &cbw.cbw, buffer, false);
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
;source-doc/scsi-drv/class_scsi.c:145: if (result == USB_ERR_OK)
	ld	a,(_result)
	or	a
	jr	NZ,l_scsi_read_00102
;source-doc/scsi-drv/class_scsi.c:146: dev->current_lba++;
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
	jr	NZ,l_scsi_read_00114
	inc	d
	jr	NZ,l_scsi_read_00114
	inc	hl
l_scsi_read_00114:
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
l_scsi_read_00102:
;source-doc/scsi-drv/class_scsi.c:147: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/class_scsi.c:148: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:150: usb_error scsi_write(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function scsi_write
; ---------------------------------
_scsi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/class_scsi.c:151: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	pop	bc
	push	de
;source-doc/scsi-drv/class_scsi.c:153: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	de,_cbw
	ld	l, e
	ld	h, d
	ld	b,0x0e
	jr	l_scsi_write_00113
l_scsi_write_00112:
	ld	(hl),0x00
	inc	hl
l_scsi_write_00113:
	ld	(hl),0x00
	inc	hl
	djnz	l_scsi_write_00112
;source-doc/scsi-drv/class_scsi.c:154: cbw.cbw = scsi_command_block_wrapper;
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:156: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),0x00
;source-doc/scsi-drv/class_scsi.c:157: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),0x0c
;source-doc/scsi-drv/class_scsi.c:158: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/class_scsi.c:160: cbw.scsi_cmd.operation_code  = 0x2A; // write operation
	ld	hl,_cbw + 15
	ld	(hl),0x2a
;source-doc/scsi-drv/class_scsi.c:161: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),0x01
;source-doc/scsi-drv/class_scsi.c:162: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
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
;source-doc/scsi-drv/class_scsi.c:163: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
;source-doc/scsi-drv/class_scsi.c:164: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
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
;source-doc/scsi-drv/class_scsi.c:165: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	a, (bc)
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/class_scsi.c:167: result = do_scsi_cmd(dev, &cbw.cbw, buffer, true);
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
;source-doc/scsi-drv/class_scsi.c:169: if (result == USB_ERR_OK)
	ld	a,(_result)
	or	a
	jr	NZ,l_scsi_write_00102
;source-doc/scsi-drv/class_scsi.c:170: dev->current_lba++;
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
	jr	NZ,l_scsi_write_00114
	inc	d
	jr	NZ,l_scsi_write_00114
	inc	hl
l_scsi_write_00114:
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
l_scsi_write_00102:
;source-doc/scsi-drv/class_scsi.c:171: return result;
	ld	hl, (_result)
;source-doc/scsi-drv/class_scsi.c:172: }
	ld	sp, ix
	pop	ix
	ret
_scsi_command_block_wrapper:
	DEFB +0x55
	DEFB +0x53
	DEFB +0x42
	DEFB +0x43
	DEFW +0x0000
	DEFW +0x0000
	DEFB +0x00,0x00, +0x00, +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
_next_tag:
	DEFW +0x0000
_csw:
	DEFB +0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB 0x00
	DEFB +0x00
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
_scsi_packet_request_sense:
	DEFB +0x03
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x12
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
