;
; Generated from source-doc/scsi-drv/./class_scsi.c.asm -- not to be modify directly
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
;source-doc/scsi-drv/./class_scsi.c:11: usb_error                    do_scsi_cmd(device_config_storage *const       dev,
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
;source-doc/scsi-drv/./class_scsi.c:16: cbw->dCBWTag[0] = next_tag++;
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,0x0004
	add	hl, bc
	ex	(sp), hl
	ld	de, (_next_tag)
	ld	hl, (_next_tag)
	inc	hl
	ld	(_next_tag), hl
	pop	hl
	push	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/scsi-drv/./class_scsi.c:18: if (!send)
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00102
;source-doc/scsi-drv/./class_scsi.c:19: cbw->bmCBWFlags = 0x80;
	ld	hl,0x000c
	add	hl, bc
	ld	(hl),0x80
l_do_scsi_cmd_00102:
;source-doc/scsi-drv/./class_scsi.c:22: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,0x0003
	add	hl, de
	ld	(ix-4),l
	ld	(ix-3),h
	ld	l, e
	ld	h, d
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
	push	hl
	ld	l,(ix-4)
	ld	h,(ix-3)
	ex	(sp), hl
	push	af
	inc	sp
	ld	iy,0x001f
	push	iy
	push	hl
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	de
	pop	bc
	ld	(_result+0),a
	or	a
	jr	Z,l_do_scsi_cmd_00104
	ld	l, a
	jp	l_do_scsi_cmd_00119
l_do_scsi_cmd_00104:
;source-doc/scsi-drv/./class_scsi.c:24: if (cbw->dCBWDataTransferLength != 0) {
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
;source-doc/scsi-drv/./class_scsi.c:27: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	(ix-2),c
	ld	(ix-1),b
	ld	c,(ix+8)
	ld	b,(ix+9)
;source-doc/scsi-drv/./class_scsi.c:25: if (!send) {
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00110
;source-doc/scsi-drv/./class_scsi.c:27: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	iy,0x0006
	add	iy, de
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	de
	push	iy
	push	af
	inc	sp
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	bc
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	de
	ld	(_result+0),a
	or	a
	jr	Z,l_do_scsi_cmd_00113
	ld	l, a
	jr	l_do_scsi_cmd_00119
l_do_scsi_cmd_00110:
;source-doc/scsi-drv/./class_scsi.c:31: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	de
	ld	l,(ix-4)
	ld	h,(ix-3)
	push	hl
	push	af
	inc	sp
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	bc
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	de
	ld	(_result+0),a
	or	a
	jr	Z,l_do_scsi_cmd_00113
	ld	l, a
	jr	l_do_scsi_cmd_00119
l_do_scsi_cmd_00113:
;source-doc/scsi-drv/./class_scsi.c:36: usb_data_in_transfer((uint8_t *)&csw, sizeof(_scsi_command_status_wrapper), dev->address, &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	hl,0x0006
	add	hl, de
	ex	de,hl
	ld	c,e
	ld	b,d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	d, a
	push	bc
	push	de
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
	ld	(_result+0),a
	or	a
	jr	Z,l_do_scsi_cmd_00115
	ld	l, a
	jr	l_do_scsi_cmd_00119
l_do_scsi_cmd_00115:
;source-doc/scsi-drv/./class_scsi.c:38: if (csw.bCSWStatus != 0 && csw.dCSWTag[0] != cbw->dCBWTag[0])
	ld	a, (_csw + 12)
	or	a
	jr	Z,l_do_scsi_cmd_00117
	ld	bc, (_csw + 4)
	pop	hl
	ld	e,(hl)
	push	hl
	inc	hl
	ld	h, (hl)
	ld	l, e
	xor	a
	sbc	hl,bc
	jr	Z,l_do_scsi_cmd_00117
;source-doc/scsi-drv/./class_scsi.c:39: return USB_ERR_FAIL;
	ld	l,0x0e
	jr	l_do_scsi_cmd_00119
l_do_scsi_cmd_00117:
;source-doc/scsi-drv/./class_scsi.c:41: return USB_ERR_OK;
	ld	l,0x00
l_do_scsi_cmd_00119:
;source-doc/scsi-drv/./class_scsi.c:42: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:46: usb_error get_scsi_read_capacity(device_config_storage *const dev, scsi_read_capacity_result *cap_result) {
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
;source-doc/scsi-drv/./class_scsi.c:48: cbw_scsi.cbw           = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:49: cbw_scsi.read_capacity = scsi_read_capacity;
	ld	hl,15
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_read_capacity
	ldir
;source-doc/scsi-drv/./class_scsi.c:51: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/./class_scsi.c:52: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_read_capacity);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/./class_scsi.c:53: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_read_capacity_result);
	ld	(ix-19),0x08
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/./class_scsi.c:55: return do_scsi_cmd(dev, &cbw_scsi.cbw, cap_result, false);
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
;source-doc/scsi-drv/./class_scsi.c:56: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:60: usb_error scsi_inquiry(device_config_storage *const dev, scsi_inquiry_result *inq_result) {
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
;source-doc/scsi-drv/./class_scsi.c:62: cbw_scsi.cbw     = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:63: cbw_scsi.inquiry = scsi_packet_inquiry;
	ld	hl,15
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_inquiry
	ldir
;source-doc/scsi-drv/./class_scsi.c:65: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/./class_scsi.c:66: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_inquiry);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/./class_scsi.c:67: cbw_scsi.cbw.dCBWDataTransferLength = 0x24;
	ld	(ix-19),0x24
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/./class_scsi.c:69: return do_scsi_cmd(dev, &cbw_scsi.cbw, inq_result, false);
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
;source-doc/scsi-drv/./class_scsi.c:70: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:72: usb_error scsi_test(device_config_storage *const dev) {
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
;source-doc/scsi-drv/./class_scsi.c:74: cbw_scsi.cbw = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:75: memset(&cbw_scsi.test, 0, sizeof(_scsi_packet_test));
	ld	hl,15
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x0c
	push	hl
	call	_memset_callee
;source-doc/scsi-drv/./class_scsi.c:77: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/./class_scsi.c:78: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_test);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/./class_scsi.c:79: cbw_scsi.cbw.dCBWDataTransferLength = 0;
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
;source-doc/scsi-drv/./class_scsi.c:81: return do_scsi_cmd(dev, &cbw_scsi.cbw, 0, false);
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
;source-doc/scsi-drv/./class_scsi.c:82: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:86: usb_error scsi_request_sense(device_config_storage *const dev, scsi_sense_result *const sens_result) {
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
;source-doc/scsi-drv/./class_scsi.c:88: cbw_scsi.cbw           = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:89: cbw_scsi.request_sense = scsi_packet_request_sense;
	ld	hl,15
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,_scsi_packet_request_sense
	ldir
;source-doc/scsi-drv/./class_scsi.c:91: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),0x00
;source-doc/scsi-drv/./class_scsi.c:92: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_request_sense);
	ld	(ix-13),0x0c
;source-doc/scsi-drv/./class_scsi.c:93: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_sense_result);
	ld	(ix-19),0x12
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/./class_scsi.c:95: return do_scsi_cmd(dev, &cbw_scsi.cbw, sens_result, false);
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
;source-doc/scsi-drv/./class_scsi.c:96: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:98: usb_error scsi_sense_init(device_config_storage *const dev) {
; ---------------------------------
; Function scsi_sense_init
; ---------------------------------
_scsi_sense_init:
	ld	hl, -18
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/./class_scsi.c:102: while ((result = scsi_test(dev)) && --counter > 0)
	ld	c,0x03
l_scsi_sense_init_00102:
	push	bc
	ld	hl,22
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	push	bc
	call	_scsi_test
	pop	af
	ld	a, l
	pop	bc
	ld	(_result+0), a
	or	a
	jr	Z,l_scsi_sense_init_00104
	dec c
	jr	Z,l_scsi_sense_init_00104
;source-doc/scsi-drv/./class_scsi.c:103: scsi_request_sense(dev, &response);
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	hl,24
	add	hl, sp
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	push	bc
	call	_scsi_request_sense
	pop	af
	pop	af
	pop	bc
	jr	l_scsi_sense_init_00102
l_scsi_sense_init_00104:
;source-doc/scsi-drv/./class_scsi.c:105: return result;
	ld	a, (_result+0)
	ld	l, a
;source-doc/scsi-drv/./class_scsi.c:106: }
	ld	iy,18
	add	iy, sp
	ld	sp, iy
	ret
;source-doc/scsi-drv/./class_scsi.c:110: usb_error scsi_read(device_config_storage *const dev, uint8_t *const buffer) {
; ---------------------------------
; Function scsi_read
; ---------------------------------
_scsi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/./class_scsi.c:111: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	hl,_cbw
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x1b
	push	hl
	call	_memset_callee
;source-doc/scsi-drv/./class_scsi.c:112: cbw.cbw = scsi_command_block_wrapper;
	ld	de,_cbw
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:114: cbw.cbw.bCBWLUN                = 0;
;source-doc/scsi-drv/./class_scsi.c:115: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,0x0c00
	ld	((_cbw + 13)),hl
;source-doc/scsi-drv/./class_scsi.c:116: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/./class_scsi.c:118: cbw.scsi_cmd.operation_code  = 0x28; // read operation
	ld	hl, +(_cbw + 15)
	ld	(hl),0x28
;source-doc/scsi-drv/./class_scsi.c:119: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl, +(_cbw + 23)
	ld	(hl),0x01
;source-doc/scsi-drv/./class_scsi.c:120: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
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
;source-doc/scsi-drv/./class_scsi.c:121: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
	pop	hl
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 18)),a
;source-doc/scsi-drv/./class_scsi.c:122: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	pop	hl
	push	hl
	inc	hl
	ld	a,(hl)
	ld	((_cbw + 19)),a
;source-doc/scsi-drv/./class_scsi.c:123: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	de,_cbw + 20
	pop	hl
	ld	a,(hl)
	push	hl
	ld	(de), a
;source-doc/scsi-drv/./class_scsi.c:125: result = do_scsi_cmd(dev, &cbw.cbw, buffer, false);
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
;source-doc/scsi-drv/./class_scsi.c:127: if (result == USB_ERR_OK)
	ld	(_result+0),a
	or	a
	jr	NZ,l_scsi_read_00102
;source-doc/scsi-drv/./class_scsi.c:128: dev->current_lba++;
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
	jr	NZ,l_scsi_read_00110
	inc	b
	jr	NZ,l_scsi_read_00110
	inc	de
l_scsi_read_00110:
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
;source-doc/scsi-drv/./class_scsi.c:129: return result;
	ld	a, (_result+0)
	ld	l, a
;source-doc/scsi-drv/./class_scsi.c:130: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:132: usb_error scsi_write(device_config_storage *const dev, uint8_t *const buffer) {
; ---------------------------------
; Function scsi_write
; ---------------------------------
_scsi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/./class_scsi.c:133: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	hl,_cbw
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x1b
	push	hl
	call	_memset_callee
;source-doc/scsi-drv/./class_scsi.c:134: cbw.cbw = scsi_command_block_wrapper;
	ld	de,_cbw
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:136: cbw.cbw.bCBWLUN                = 0;
;source-doc/scsi-drv/./class_scsi.c:137: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,0x0c00
	ld	((_cbw + 13)),hl
;source-doc/scsi-drv/./class_scsi.c:138: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,0x0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/./class_scsi.c:140: cbw.scsi_cmd.operation_code  = 0x2A; // write operation
	ld	hl, +(_cbw + 15)
	ld	(hl),0x2a
;source-doc/scsi-drv/./class_scsi.c:141: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl, +(_cbw + 23)
	ld	(hl),0x01
;source-doc/scsi-drv/./class_scsi.c:142: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
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
;source-doc/scsi-drv/./class_scsi.c:143: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
	pop	hl
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 18)),a
;source-doc/scsi-drv/./class_scsi.c:144: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	pop	hl
	push	hl
	inc	hl
	ld	a,(hl)
	ld	((_cbw + 19)),a
;source-doc/scsi-drv/./class_scsi.c:145: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	de,_cbw + 20
	pop	hl
	ld	a,(hl)
	push	hl
	ld	(de), a
;source-doc/scsi-drv/./class_scsi.c:147: result = do_scsi_cmd(dev, &cbw.cbw, buffer, true);
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
;source-doc/scsi-drv/./class_scsi.c:149: if (result == USB_ERR_OK)
	ld	(_result+0),a
	or	a
	jr	NZ,l_scsi_write_00102
;source-doc/scsi-drv/./class_scsi.c:150: dev->current_lba++;
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
	jr	NZ,l_scsi_write_00110
	inc	b
	jr	NZ,l_scsi_write_00110
	inc	de
l_scsi_write_00110:
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
;source-doc/scsi-drv/./class_scsi.c:151: return result;
	ld	a, (_result+0)
	ld	l, a
;source-doc/scsi-drv/./class_scsi.c:152: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/./class_scsi.c:154: usb_error scsi_eject(device_config_storage *const dev) {
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
;source-doc/scsi-drv/./class_scsi.c:156: cbw_scsi.cbw = scsi_command_block_wrapper;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000f
	ld	hl,_scsi_command_block_wrapper
	ldir
;source-doc/scsi-drv/./class_scsi.c:158: memset(&cbw_scsi.eject, 0, sizeof(_scsi_packet_eject));
	ld	hl,15
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x06
	push	hl
	call	_memset_callee
;source-doc/scsi-drv/./class_scsi.c:160: cbw_scsi.eject.operation_code = 0x1B;
	ld	(ix-6),0x1b
;source-doc/scsi-drv/./class_scsi.c:161: cbw_scsi.eject.loej           = 1;
	ld	hl,19
	add	hl, sp
	set	1, (hl)
;source-doc/scsi-drv/./class_scsi.c:163: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-8),0x00
;source-doc/scsi-drv/./class_scsi.c:164: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_eject);
	ld	(ix-7),0x06
;source-doc/scsi-drv/./class_scsi.c:165: cbw_scsi.cbw.dCBWDataTransferLength = 0;
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
;source-doc/scsi-drv/./class_scsi.c:167: return do_scsi_cmd(dev, &cbw_scsi.cbw, 0, false);
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
;source-doc/scsi-drv/./class_scsi.c:168: }
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
