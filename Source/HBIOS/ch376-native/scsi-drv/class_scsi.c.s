;
; Generated from source-doc/scsi-drv/class_scsi.c.asm -- not to be modify directly
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
	
_scsi_command_block_wrapper:
	DEFS 15
_next_tag:
	DEFS 2
_csw:
	DEFS 13
_scsi_read_capacity:
	DEFS 12
_scsi_packet_inquiry:
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
;source-doc/scsi-drv/class_scsi.c:12: usb_error                    do_scsi_cmd(device_config_storage *const       dev,
; ---------------------------------
; Function do_scsi_cmd
; ---------------------------------
_do_scsi_cmd:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -6
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:17: cbw->dCBWTag[0] = next_tag++;
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,0x0004
	add	hl, bc
	ex	(sp), hl
	ld	de,(_next_tag)
	ld	hl, (_next_tag)
	inc	hl
	ld	(_next_tag), hl
	pop	hl
	push	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/scsi-drv/class_scsi.c:19: if (!send)
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00102
;source-doc/scsi-drv/class_scsi.c:20: cbw->bmCBWFlags = 0x80;
	ld	hl,0x000c
	add	hl, bc
	ld	(hl),0x80
l_do_scsi_cmd_00102:
;source-doc/scsi-drv/class_scsi.c:22: critical_begin();
	push	bc
	call	_critical_begin
	pop	bc
;source-doc/scsi-drv/class_scsi.c:25: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	a,(ix+4)
	ld	(ix-4),a
	ld	a,(ix+5)
	ld	(ix-3),a
	ld	a,(ix-4)
	add	a,0x03
	ld	(ix-2),a
	ld	a,(ix-3)
	adc	a,0x00
	ld	(ix-1),a
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	e,(ix+6)
	ld	d,(ix+7)
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	af
	inc	sp
	ld	hl,0x001f
	push	hl
	push	de
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	bc
	ld	a, l
	ld	(_result), a
	ld	a,(_result)
	or	a
	jp	NZ, l_do_scsi_cmd_00120
;source-doc/scsi-drv/class_scsi.c:27: if (cbw->dCBWDataTransferLength != 0) {
	ld	hl,8
	add	hl, bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	hl
	ld	c, (hl)
	inc	hl
	ld	a, (hl)
	or	c
	or	d
	or	e
	jr	Z,l_do_scsi_cmd_00113
;source-doc/scsi-drv/class_scsi.c:30: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	c,(ix+8)
	ld	b,(ix+9)
;source-doc/scsi-drv/class_scsi.c:28: if (!send) {
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00110
;source-doc/scsi-drv/class_scsi.c:30: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix-4)
	add	a,0x06
	ld	(ix-2),a
	ld	a,(ix-3)
	adc	a,0x00
	ld	(ix-1),a
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	af
	inc	sp
	push	de
	push	bc
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
;source-doc/scsi-drv/class_scsi.c:34: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	af
	inc	sp
	push	de
	push	bc
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
;source-doc/scsi-drv/class_scsi.c:39: usb_data_in_transfer((uint8_t *)&csw, sizeof(_scsi_command_status_wrapper), dev->address, &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix-4)
	add	a,0x06
	ld	e, a
	ld	a,(ix-3)
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
;source-doc/scsi-drv/class_scsi.c:41: if (csw.bCSWStatus != 0 && csw.dCSWTag[0] != cbw->dCBWTag[0])
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
;source-doc/scsi-drv/class_scsi.c:42: result = USB_ERR_FAIL;
	ld	hl,_result
	ld	(hl),0x0e
	jr	l_do_scsi_cmd_00120
l_do_scsi_cmd_00117:
;source-doc/scsi-drv/class_scsi.c:44: result = USB_ERR_OK;
	ld	hl,_result
	ld	(hl),0x00
;source-doc/scsi-drv/class_scsi.c:46: done:
l_do_scsi_cmd_00120:
;source-doc/scsi-drv/class_scsi.c:47: critical_end();
	call	_critical_end
;source-doc/scsi-drv/class_scsi.c:48: return result;
	ld	hl,(_result)
;source-doc/scsi-drv/class_scsi.c:49: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:53: usb_error get_scsi_read_capacity(device_config_storage *const dev, scsi_read_capacity_result *cap_result) {
; ---------------------------------
; Function get_scsi_read_capacity
; ---------------------------------
_get_scsi_read_capacity:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -27
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:55: cbw_scsi.cbw           = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:56: cbw_scsi.read_capacity = scsi_read_capacity;
	ld	hl,15
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_read_capacity
	ldir
;source-doc/scsi-drv/class_scsi.c:58: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:59: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_read_capacity);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:60: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_read_capacity_result);
	ld	(ix-19),0x08
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/class_scsi.c:62: return do_scsi_cmd(dev, &cbw_scsi.cbw, cap_result, false);
	ld	c,(ix+6)
	ld	b,(ix+7)
	xor	a
	push	af
	inc	sp
	push	bc
	ld	hl,3
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:63: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:67: usb_error scsi_inquiry(device_config_storage *const dev, scsi_inquiry_result *inq_result) {
; ---------------------------------
; Function scsi_inquiry
; ---------------------------------
_scsi_inquiry:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -27
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:69: cbw_scsi.cbw     = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:70: cbw_scsi.inquiry = scsi_packet_inquiry;
	ld	hl,15
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_inquiry
	ldir
;source-doc/scsi-drv/class_scsi.c:72: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:73: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_inquiry);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:74: cbw_scsi.cbw.dCBWDataTransferLength = 0x24;
	ld	(ix-19),0x24
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/class_scsi.c:76: return do_scsi_cmd(dev, &cbw_scsi.cbw, inq_result, false);
	ld	c,(ix+6)
	ld	b,(ix+7)
	xor	a
	push	af
	inc	sp
	push	bc
	ld	hl,3
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:77: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:79: usb_error scsi_test(device_config_storage *const dev) {
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
;source-doc/scsi-drv/class_scsi.c:81: cbw_scsi.cbw = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:82: memset(&cbw_scsi.test, 0, sizeof(_scsi_packet_test));
	ld	hl,15
	add	hl, sp
	ld	b,0x06
l_scsi_test_00103:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_scsi_test_00103
;source-doc/scsi-drv/class_scsi.c:84: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:85: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_test);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:86: cbw_scsi.cbw.dCBWDataTransferLength = 0;
	ld	hl,8
	add	hl, sp
	xor	a
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
;source-doc/scsi-drv/class_scsi.c:88: return do_scsi_cmd(dev, &cbw_scsi.cbw, 0, false);
	xor	a
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	ld	hl,3
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:89: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:93: usb_error scsi_request_sense(device_config_storage *const dev, scsi_sense_result *const sens_result) {
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
;source-doc/scsi-drv/class_scsi.c:95: cbw_scsi.cbw           = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:96: cbw_scsi.request_sense = scsi_packet_request_sense;
	ld	hl,15
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_request_sense
	ldir
;source-doc/scsi-drv/class_scsi.c:98: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/class_scsi.c:99: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_request_sense);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/class_scsi.c:100: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_sense_result);
	ld	(ix-19),0x12
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/class_scsi.c:102: return do_scsi_cmd(dev, &cbw_scsi.cbw, sens_result, false);
	ld	c,(ix+6)
	ld	b,(ix+7)
	xor	a
	push	af
	inc	sp
	push	bc
	ld	hl,3
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:103: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:105: usb_error scsi_sense_init(device_config_storage *const dev) {
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
;source-doc/scsi-drv/class_scsi.c:109: critical_begin();
	call	_critical_begin
;source-doc/scsi-drv/class_scsi.c:110: while ((result = scsi_test(dev)) && --counter > 0)
	ld	c,0x03
l_scsi_sense_init_00102:
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_scsi_test
	pop	af
	ld	a, l
	pop	bc
	ld	(_result),a
	or	a
	jr	Z,l_scsi_sense_init_00104
	dec	c
	jr	Z,l_scsi_sense_init_00104
;source-doc/scsi-drv/class_scsi.c:111: scsi_request_sense(dev, &response);
	ld	hl,0
	add	hl, sp
	push	bc
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_scsi_request_sense
	pop	af
	pop	af
	pop	bc
	jr	l_scsi_sense_init_00102
l_scsi_sense_init_00104:
;source-doc/scsi-drv/class_scsi.c:112: critical_end();
	call	_critical_end
;source-doc/scsi-drv/class_scsi.c:114: return result;
	ld	hl,(_result)
;source-doc/scsi-drv/class_scsi.c:115: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:119: usb_error scsi_read(device_config_storage *const dev, uint8_t *const buffer) {
; ---------------------------------
; Function scsi_read
; ---------------------------------
_scsi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/class_scsi.c:120: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	hl,_cbw
	ld	(hl),0x00
	ld	e, l
	ld	d, h
	inc	de
	ld	bc,0x001a
	ldir
;source-doc/scsi-drv/class_scsi.c:121: cbw.cbw = scsi_command_block_wrapper;
	ld	de,_cbw
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:123: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),0x00
;source-doc/scsi-drv/class_scsi.c:124: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),0x0c
;source-doc/scsi-drv/class_scsi.c:125: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/class_scsi.c:127: cbw.scsi_cmd.operation_code  = 0x28; // read operation
	ld	hl,_cbw + 15
	ld	(hl),0x28
;source-doc/scsi-drv/class_scsi.c:128: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),0x01
;source-doc/scsi-drv/class_scsi.c:129: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,0x000c
	add	hl, bc
	pop	af
	push	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 17)),a
;source-doc/scsi-drv/class_scsi.c:130: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
	pop	hl
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 18)),a
;source-doc/scsi-drv/class_scsi.c:131: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	pop	hl
	push	hl
	inc	hl
	ld	a,(hl)
	ld	((_cbw + 19)),a
;source-doc/scsi-drv/class_scsi.c:132: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	pop	hl
	ld	a,(hl)
	push	hl
	ld	((_cbw + 20)),a
;source-doc/scsi-drv/class_scsi.c:134: result = do_scsi_cmd(dev, &cbw.cbw, buffer, false);
	ld	e,(ix+6)
	ld	d,(ix+7)
	xor	a
	push	af
	inc	sp
	push	de
	ld	hl,_cbw
	push	hl
	push	bc
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	ld	(_result), a
;source-doc/scsi-drv/class_scsi.c:136: if (result == USB_ERR_OK)
	ld	a,(_result)
	or	a
	jr	NZ,l_scsi_read_00102
;source-doc/scsi-drv/class_scsi.c:137: dev->current_lba++;
	pop	hl
	ld	c,(hl)
	push	hl
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	c
	jr	NZ,l_scsi_read_00112
	inc	b
	jr	NZ,l_scsi_read_00112
	inc	de
l_scsi_read_00112:
	pop	hl
	push	hl
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
l_scsi_read_00102:
;source-doc/scsi-drv/class_scsi.c:138: return result;
	ld	hl,(_result)
;source-doc/scsi-drv/class_scsi.c:139: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:141: usb_error scsi_write(device_config_storage *const dev, uint8_t *const buffer) {
; ---------------------------------
; Function scsi_write
; ---------------------------------
_scsi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/class_scsi.c:142: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	hl,_cbw
	ld	(hl),0x00
	ld	e, l
	ld	d, h
	inc	de
	ld	bc,0x001a
	ldir
;source-doc/scsi-drv/class_scsi.c:143: cbw.cbw = scsi_command_block_wrapper;
	ld	de,_cbw
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:145: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),0x00
;source-doc/scsi-drv/class_scsi.c:146: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),0x0c
;source-doc/scsi-drv/class_scsi.c:147: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/class_scsi.c:149: cbw.scsi_cmd.operation_code  = 0x2A; // write operation
	ld	hl,_cbw + 15
	ld	(hl),0x2a
;source-doc/scsi-drv/class_scsi.c:150: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),0x01
;source-doc/scsi-drv/class_scsi.c:151: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,0x000c
	add	hl, bc
	pop	af
	push	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 17)),a
;source-doc/scsi-drv/class_scsi.c:152: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
	pop	hl
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 18)),a
;source-doc/scsi-drv/class_scsi.c:153: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	pop	hl
	push	hl
	inc	hl
	ld	a,(hl)
	ld	((_cbw + 19)),a
;source-doc/scsi-drv/class_scsi.c:154: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	pop	hl
	ld	a,(hl)
	push	hl
	ld	((_cbw + 20)),a
;source-doc/scsi-drv/class_scsi.c:156: result = do_scsi_cmd(dev, &cbw.cbw, buffer, true);
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	a,0x01
	push	af
	inc	sp
	push	de
	ld	hl,_cbw
	push	hl
	push	bc
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	ld	(_result), a
;source-doc/scsi-drv/class_scsi.c:158: if (result == USB_ERR_OK)
	ld	a,(_result)
	or	a
	jr	NZ,l_scsi_write_00102
;source-doc/scsi-drv/class_scsi.c:159: dev->current_lba++;
	pop	hl
	ld	c,(hl)
	push	hl
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	inc	c
	jr	NZ,l_scsi_write_00112
	inc	b
	jr	NZ,l_scsi_write_00112
	inc	de
l_scsi_write_00112:
	pop	hl
	push	hl
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
l_scsi_write_00102:
;source-doc/scsi-drv/class_scsi.c:160: return result;
	ld	hl,(_result)
;source-doc/scsi-drv/class_scsi.c:161: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:163: usb_error scsi_eject(device_config_storage *const dev) {
; ---------------------------------
; Function scsi_eject
; ---------------------------------
_scsi_eject:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -21
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:165: cbw_scsi.cbw = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/class_scsi.c:167: memset(&cbw_scsi.eject, 0, sizeof(_scsi_packet_eject));
	ld	hl,15
	add	hl, sp
	ld	b,0x03
l_scsi_eject_00103:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_scsi_eject_00103
;source-doc/scsi-drv/class_scsi.c:169: cbw_scsi.eject.operation_code = 0x1B;
	ld	(ix-6),0x1b
;source-doc/scsi-drv/class_scsi.c:170: cbw_scsi.eject.loej           = 1;
	ld	hl,19
	add	hl, sp
	set	1, (hl)
;source-doc/scsi-drv/class_scsi.c:172: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-8),0x00
;source-doc/scsi-drv/class_scsi.c:173: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_eject);
	ld	(ix-7),0x06
;source-doc/scsi-drv/class_scsi.c:174: cbw_scsi.cbw.dCBWDataTransferLength = 0;
	ld	hl,8
	add	hl, sp
	xor	a
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(hl),a
;source-doc/scsi-drv/class_scsi.c:176: return do_scsi_cmd(dev, &cbw_scsi.cbw, 0, false);
	xor	a
	push	af
	inc	sp
	ld	hl,0x0000
	push	hl
	ld	hl,3
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:177: }
	ld	sp,ix
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
_scsi_read_capacity:
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
_scsi_packet_inquiry:
	DEFB +0x12
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x24
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
