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
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
#IF 0
	
; .area _INITIALIZED removed by z88dk
	
_scsi_cmd_blk_wrap:
	DEFS 15
_next_tag:
	DEFS 2
	
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
;source-doc/scsi-drv/class_scsi.c:11: usb_error do_scsi_cmd(device_config_storage *const       dev,
; ---------------------------------
; Function do_scsi_cmd
; ---------------------------------
_do_scsi_cmd:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -21
	add	hl, sp
	ld	sp, hl
;source-doc/scsi-drv/class_scsi.c:17: _scsi_command_status_wrapper csw = {{{0}}};
	ld	a,$00
	ld	(ix-21),a
	ld	(ix-20),a
	ld	(ix-19),a
	ld	(ix-18),a
	xor	a
	ld	(ix-17),a
	ld	(ix-16),a
	xor	a
	ld	(ix-15),a
	ld	(ix-14),a
	ld	a,$00
	ld	(ix-13),a
	ld	(ix-12),a
	ld	(ix-11),a
	ld	(ix-10),a
	ld	(ix-9),$00
;source-doc/scsi-drv/class_scsi.c:19: cbw->dCBWTag[0] = next_tag++;
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,$0004
	add	hl, bc
	ld	(ix-8),l
	ld	(ix-7),h
	ld	a, (_next_tag)
	ld	e, a
	ld	hl,_next_tag + 1
	ld	d, (hl)
	ld	hl, (_next_tag)
	inc	hl
	ld	(_next_tag), hl
	ld	l,(ix-8)
	ld	h,(ix-7)
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/scsi-drv/class_scsi.c:21: if (!send)
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00102
;source-doc/scsi-drv/class_scsi.c:22: cbw->bmCBWFlags = $80;
	ld	hl,$000c
	add	hl, bc
	ld	(hl),$80
l_do_scsi_cmd_00102:
;source-doc/scsi-drv/class_scsi.c:24: critical_begin();
	push	bc
	call	_critical_begin
	pop	bc
;source-doc/scsi-drv/class_scsi.c:27: &dev->endpoints[ENDPOINT_BULK_OUT]));
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
	and	$0f
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	bc
	push	de
	push	de
	push	af
	inc	sp
	push	hl
	ld	hl,$001f
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
	or	a
	jp	NZ, l_do_scsi_cmd_00120
;source-doc/scsi-drv/class_scsi.c:29: if (cbw->dCBWDataTransferLength != 0) {
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
;source-doc/scsi-drv/class_scsi.c:32: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	(ix-2),c
	ld	(ix-1),b
	ld	c,(ix+8)
	ld	b,(ix+9)
;source-doc/scsi-drv/class_scsi.c:30: if (!send) {
	bit	0,(ix+10)
	jr	NZ,l_do_scsi_cmd_00110
;source-doc/scsi-drv/class_scsi.c:32: &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix-6)
	add	a,$06
	ld	e, a
	ld	a,(ix-5)
	adc	a,$00
	ld	d, a
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	push	de
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
	or	a
	jr	Z,l_do_scsi_cmd_00113
	jr	l_do_scsi_cmd_00120
l_do_scsi_cmd_00110:
;source-doc/scsi-drv/class_scsi.c:36: &dev->endpoints[ENDPOINT_BULK_OUT]));
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	push	de
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
	or	a
	jr	NZ,l_do_scsi_cmd_00120
l_do_scsi_cmd_00113:
;source-doc/scsi-drv/class_scsi.c:41: usb_data_in_transfer((uint8_t *)&csw, sizeof(_scsi_command_status_wrapper), dev->address, &dev->endpoints[ENDPOINT_BULK_IN]));
	ld	a,(ix-6)
	add	a,$06
	ld	c, a
	ld	a,(ix-5)
	adc	a,$00
	ld	b, a
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	d, a
	push	bc
	push	de
	inc	sp
	ld	hl,$000d
	push	hl
	ld	hl,5
	add	hl, sp
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	or	a
	jr	NZ,l_do_scsi_cmd_00120
;source-doc/scsi-drv/class_scsi.c:43: if (csw.bCSWStatus != 0 || csw.dCSWTag[0] != cbw->dCBWTag[0])
	ld	a,(ix-9)
	or	a
	jr	NZ,l_do_scsi_cmd_00116
	ld	c,(ix-17)
	ld	b,(ix-16)
	ld	l,(ix-8)
	ld	h,(ix-7)
	ld	a, (hl)
	inc	hl
	ld	h, (hl)
	ld	l, a
	xor	a
	sbc	hl,bc
	jr	Z,l_do_scsi_cmd_00117
l_do_scsi_cmd_00116:
;source-doc/scsi-drv/class_scsi.c:44: result = USB_ERR_FAIL;
	ld	l,$0e
	jr	l_do_scsi_cmd_00120
l_do_scsi_cmd_00117:
;source-doc/scsi-drv/class_scsi.c:46: result = USB_ERR_OK;
	ld	l,$00
;source-doc/scsi-drv/class_scsi.c:48: done:
l_do_scsi_cmd_00120:
;source-doc/scsi-drv/class_scsi.c:49: critical_end();
	push	hl
	call	_critical_end
	pop	hl
;source-doc/scsi-drv/class_scsi.c:50: return result;
;source-doc/scsi-drv/class_scsi.c:51: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:53: usb_error scsi_test(device_config_storage *const dev) {
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
;source-doc/scsi-drv/class_scsi.c:55: cbw_scsi.cbw = scsi_cmd_blk_wrap;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$000f
	ld	hl,_scsi_cmd_blk_wrap
	ldir
;source-doc/scsi-drv/class_scsi.c:56: memset(&cbw_scsi.test, 0, sizeof(_scsi_packet_test));
	ld	hl,17
	add	hl, sp
	ld	b,$06
l_scsi_test_00103:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_scsi_test_00103
	pop	bc
;source-doc/scsi-drv/class_scsi.c:58: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),$00
;source-doc/scsi-drv/class_scsi.c:59: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_test);
	ld	(ix-13),$0c
;source-doc/scsi-drv/class_scsi.c:60: cbw_scsi.cbw.dCBWDataTransferLength = 0;
	ld	hl,$0008
	add	hl, bc
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/class_scsi.c:62: return do_scsi_cmd(dev, &cbw_scsi.cbw, 0, false);
	xor	a
	push	af
	inc	sp
	ld	hl,$0000
	push	hl
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_do_scsi_cmd
;source-doc/scsi-drv/class_scsi.c:63: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/scsi-drv/class_scsi.c:67: usb_error scsi_request_sense(device_config_storage *const dev, scsi_sense_result *const sens_result) {
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
;source-doc/scsi-drv/class_scsi.c:69: cbw_scsi.cbw           = scsi_cmd_blk_wrap;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,$000f
	ld	hl,_scsi_cmd_blk_wrap
	ldir
;source-doc/scsi-drv/class_scsi.c:70: cbw_scsi.request_sense = scsi_pckt_req_sense;
	ld	hl,17
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,_scsi_pckt_req_sense
	ldir
	pop	bc
;source-doc/scsi-drv/class_scsi.c:72: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),$00
;source-doc/scsi-drv/class_scsi.c:73: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_packet_request_sense);
	ld	(ix-13),$0c
;source-doc/scsi-drv/class_scsi.c:74: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_sense_result);
	ld	hl,$0008
	add	hl, bc
	ld	(hl),$12
	inc	hl
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/scsi-drv/class_scsi.c:76: return do_scsi_cmd(dev, &cbw_scsi.cbw, sens_result, false);
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
;source-doc/scsi-drv/class_scsi.c:77: }
	ld	sp,ix
	pop	ix
	ret
_scsi_pckt_req_sense:
	DEFB +$03
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$12
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
_scsi_cmd_blk_wrap:
	DEFB +$55
	DEFB +$53
	DEFB +$42
	DEFB +$43
	DEFW +$0000
	DEFW +$0000
	DEFB +$00,$00, +$00, +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
_next_tag:
	DEFW +$0000
