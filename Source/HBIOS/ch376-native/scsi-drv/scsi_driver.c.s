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
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
#IF 0
	
; .area _INITIALIZED removed by z88dk
	
_scsi_pkt_read_cap:
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
;source-doc/scsi-drv/scsi_driver.c:11: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/scsi-drv/scsi_driver.c:16: critical_begin();
	push	de
	call	_critical_begin
	pop	de
;source-doc/scsi-drv/scsi_driver.c:17: while ((result = scsi_test(dev)) && --counter > 0)
	ld	c,$03
l_usb_scsi_init_00102:
	push	bc
	push	de
	push	de
	call	_scsi_test
	pop	af
	ld	a, l
	pop	de
	pop	bc
	ld	l, a
	or	a
	jr	Z,l_usb_scsi_init_00104
	dec	c
	jr	Z,l_usb_scsi_init_00104
;source-doc/scsi-drv/scsi_driver.c:18: scsi_request_sense(dev, &response);
	push	bc
	push	de
	ld	hl,4
	add	hl, sp
	push	hl
	push	de
	call	_scsi_request_sense
	pop	af
	pop	af
	pop	de
	pop	bc
	jr	l_usb_scsi_init_00102
l_usb_scsi_init_00104:
;source-doc/scsi-drv/scsi_driver.c:19: critical_end();
	push	hl
	call	_critical_end
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:21: return result;
;source-doc/scsi-drv/scsi_driver.c:22: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/scsi_driver.c:26: usb_error usb_scsi_read_capacity(const uint16_t dev_index, scsi_read_capacity_result *cap_result) {
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
;source-doc/scsi-drv/scsi_driver.c:27: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
;source-doc/scsi-drv/scsi_driver.c:30: cbw_scsi.cbw           = scsi_cmd_blk_wrap;
	push	de
	ld	hl,2
	add	hl, sp
	ex	de, hl
	ld	bc,$000f
	ld	hl,_scsi_cmd_blk_wrap
	ldir
	pop	de
;source-doc/scsi-drv/scsi_driver.c:31: cbw_scsi.read_capacity = scsi_pkt_read_cap;
	push	de
	ld	hl,17
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,_scsi_pkt_read_cap
	ldir
	pop	de
;source-doc/scsi-drv/scsi_driver.c:33: cbw_scsi.cbw.bCBWLUN                = 0;
	ld	(ix-14),$00
;source-doc/scsi-drv/scsi_driver.c:34: cbw_scsi.cbw.bCBWCBLength           = sizeof(_scsi_read_capacity);
	ld	(ix-13),$0c
;source-doc/scsi-drv/scsi_driver.c:35: cbw_scsi.cbw.dCBWDataTransferLength = sizeof(scsi_read_capacity_result);
	ld	(ix-19),$08
	xor	a
	ld	(ix-18),a
	ld	(ix-17),a
	ld	(ix-16),a
;source-doc/scsi-drv/scsi_driver.c:37: return do_scsi_cmd(dev, &cbw_scsi.cbw, cap_result, false);
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
;source-doc/scsi-drv/scsi_driver.c:38: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/scsi_driver.c:58: usb_error usb_scsi_read(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function usb_scsi_read
; ---------------------------------
_usb_scsi_read:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/scsi_driver.c:61: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	pop	bc
	push	de
;source-doc/scsi-drv/scsi_driver.c:63: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	de,_cbw
	ld	l, e
	ld	h, d
	ld	b,$0e
	jr	l_usb_scsi_read_00113
l_usb_scsi_read_00112:
	ld	(hl),$00
	inc	hl
l_usb_scsi_read_00113:
	ld	(hl),$00
	inc	hl
	djnz	l_usb_scsi_read_00112
;source-doc/scsi-drv/scsi_driver.c:64: cbw.cbw = scsi_cmd_blk_wrap;
	ld	bc,$000f
	ld	hl,_scsi_cmd_blk_wrap
	ldir
;source-doc/scsi-drv/scsi_driver.c:66: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),$00
;source-doc/scsi-drv/scsi_driver.c:67: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),$0c
;source-doc/scsi-drv/scsi_driver.c:68: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,$0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/scsi_driver.c:70: cbw.scsi_cmd.operation_code  = $28; // read operation
	ld	hl,_cbw + 15
	ld	(hl),$28
;source-doc/scsi-drv/scsi_driver.c:71: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),$01
;source-doc/scsi-drv/scsi_driver.c:72: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
	pop	hl
	push	hl
	ld	de,$000c
	add	hl, de
	push	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 17)),a
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:73: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 18)),a
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:74: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	push	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 19)),a
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:75: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	bc,_cbw + 20
	ld	a, (hl)
	ld	(bc), a
;source-doc/scsi-drv/scsi_driver.c:77: result = do_scsi_cmd(dev, &cbw.cbw, buffer, false);
	ld	c,(ix+6)
	ld	b,(ix+7)
	push	hl
	xor	a
	push	af
	inc	sp
	push	bc
	ld	de,_cbw
	push	de
	ld	e,(ix-2)
	ld	d,(ix-1)
	push	de
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	hl
	ld	(ix-1),a
;source-doc/scsi-drv/scsi_driver.c:79: if (result == USB_ERR_OK)
	or	a
	jr	NZ,l_usb_scsi_read_00102
;source-doc/scsi-drv/scsi_driver.c:80: dev->current_lba++;
	ld	c,(hl)
	push	hl
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	pop	hl
	inc	c
	jr	NZ,l_usb_scsi_read_00114
	inc	b
	jr	NZ,l_usb_scsi_read_00114
	inc	de
l_usb_scsi_read_00114:
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
l_usb_scsi_read_00102:
;source-doc/scsi-drv/scsi_driver.c:81: return result;
	ld	l,(ix-1)
;source-doc/scsi-drv/scsi_driver.c:82: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/scsi-drv/scsi_driver.c:84: usb_error usb_scsi_write(const uint16_t dev_index, uint8_t *const buffer) {
; ---------------------------------
; Function usb_scsi_write
; ---------------------------------
_usb_scsi_write:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/scsi-drv/scsi_driver.c:86: device_config_storage *const dev = (device_config_storage *)get_usb_device_config(dev_index);
	ld	a,(ix+4)
	call	_get_usb_device_config
	pop	bc
	push	de
;source-doc/scsi-drv/scsi_driver.c:88: memset(&cbw, 0, sizeof(cbw_scsi_read_write));
	ld	de,_cbw
	ld	l, e
	ld	h, d
	ld	b,$0e
	jr	l_usb_scsi_write_00113
l_usb_scsi_write_00112:
	ld	(hl),$00
	inc	hl
l_usb_scsi_write_00113:
	ld	(hl),$00
	inc	hl
	djnz	l_usb_scsi_write_00112
;source-doc/scsi-drv/scsi_driver.c:89: cbw.cbw = scsi_cmd_blk_wrap;
	ld	bc,$000f
	ld	hl,_scsi_cmd_blk_wrap
	ldir
;source-doc/scsi-drv/scsi_driver.c:91: cbw.cbw.bCBWLUN                = 0;
	ld	hl,_cbw + 13
	ld	(hl),$00
;source-doc/scsi-drv/scsi_driver.c:92: cbw.cbw.bCBWCBLength           = sizeof(_scsi_packet_read_write);
	ld	hl,_cbw + 14
	ld	(hl),$0c
;source-doc/scsi-drv/scsi_driver.c:93: cbw.cbw.dCBWDataTransferLength = 512;
	ld	hl,$0200
	ld	(_cbw + 8),hl
	ld	h, l
	ld	(_cbw + 8 + 2),hl
;source-doc/scsi-drv/scsi_driver.c:95: cbw.scsi_cmd.operation_code  = $2A; // write operation
	ld	hl,_cbw + 15
	ld	(hl),$2a
;source-doc/scsi-drv/scsi_driver.c:96: cbw.scsi_cmd.transfer_len[1] = 1;
	ld	hl,_cbw + 23
	ld	(hl),$01
;source-doc/scsi-drv/scsi_driver.c:97: cbw.scsi_cmd.lba[0]          = dev->current_lba >> 24;
	pop	hl
	push	hl
	ld	de,$000c
	add	hl, de
	push	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 17)),a
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:98: cbw.scsi_cmd.lba[1]          = dev->current_lba >> 16;
	push	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 18)),a
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:99: cbw.scsi_cmd.lba[2]          = dev->current_lba >> 8;
	push	hl
	inc	hl
	ld	a, (hl)
	ld	((_cbw + 19)),a
	pop	hl
;source-doc/scsi-drv/scsi_driver.c:100: cbw.scsi_cmd.lba[3]          = dev->current_lba;
	ld	bc,_cbw + 20
	ld	a, (hl)
	ld	(bc), a
;source-doc/scsi-drv/scsi_driver.c:102: result = do_scsi_cmd(dev, &cbw.cbw, buffer, true);
	ld	c,(ix+6)
	ld	b,(ix+7)
	push	hl
	ld	a,$01
	push	af
	inc	sp
	push	bc
	ld	de,_cbw
	push	de
	ld	e,(ix-2)
	ld	d,(ix-1)
	push	de
	call	_do_scsi_cmd
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	hl
	ld	(ix-1),a
;source-doc/scsi-drv/scsi_driver.c:104: if (result == USB_ERR_OK)
	or	a
	jr	NZ,l_usb_scsi_write_00102
;source-doc/scsi-drv/scsi_driver.c:105: dev->current_lba++;
	ld	c,(hl)
	push	hl
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	pop	hl
	inc	c
	jr	NZ,l_usb_scsi_write_00114
	inc	b
	jr	NZ,l_usb_scsi_write_00114
	inc	de
l_usb_scsi_write_00114:
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
l_usb_scsi_write_00102:
;source-doc/scsi-drv/scsi_driver.c:106: return result;
	ld	l,(ix-1)
;source-doc/scsi-drv/scsi_driver.c:107: }
	ld	sp, ix
	pop	ix
	ret
_scsi_pkt_read_cap:
	DEFB +$25
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
_cbw:
	DEFB +$00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB +$00,$00, +$00, +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB $00
	DEFB +$00
	DEFB $00
	DEFB $00
	DEFB +$00
	DEFB $00
	DEFB $00
