;
; Generated from source-doc/base-drv/./dev_transfers.c.asm -- not to be modify directly
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
;source-doc/base-drv/./dev_transfers.c:28: usb_error usbdev_control_transfer(device_config *const device, const setup_packet *const cmd_packet, uint8_t *const buffer) {
; ---------------------------------
; Function usbdev_control_transfer
; ---------------------------------
_usbdev_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./dev_transfers.c:29: return usb_control_transfer(cmd_packet, buffer, device->address, device->max_packet_size);
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	l, e
	ld	h, d
	inc	hl
	ld	b, (hl)
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	e,(ix+8)
	ld	d,(ix+9)
	push	bc
	inc	sp
	push	af
	inc	sp
	push	de
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/./dev_transfers.c:30: }
	pop	ix
	ret
;source-doc/base-drv/./dev_transfers.c:32: usb_error usbdev_blk_out_trnsfer(device_config *const dev, const uint8_t *const buffer, const uint16_t buffer_size) {
; ---------------------------------
; Function usbdev_blk_out_trnsfer
; ---------------------------------
_usbdev_blk_out_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/./dev_transfers.c:36: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_OUT];
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,0x0003
	add	hl, bc
	ex	(sp), hl
;source-doc/base-drv/./dev_transfers.c:38: result = usb_data_out_transfer(buffer, buffer_size, dev->address, endpoint);
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	bc
	pop	de
	pop	hl
	push	hl
	push	de
	push	hl
	push	af
	inc	sp
	ld	l,(ix+8)
	ld	h,(ix+9)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	d, l
	pop	bc
;source-doc/base-drv/./dev_transfers.c:40: if (result == USB_ERR_STALL) {
	ld	a, d
	sub	0x02
	jr	NZ,l_usbdev_blk_out_trnsfer_00102
;source-doc/base-drv/./dev_transfers.c:41: usbtrn_clear_endpoint_halt(endpoint->number, dev->address, dev->max_packet_size);
	ld	l, c
	ld	h, b
	inc	hl
	ld	d, (hl)
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	push	hl
	ld	a, (hl)
	rrca
	and	0x07
	push	de
	inc	sp
	push	bc
	inc	sp
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/./dev_transfers.c:42: endpoint->toggle = 0;
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/./dev_transfers.c:43: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_blk_out_trnsfer_00103
l_usbdev_blk_out_trnsfer_00102:
;source-doc/base-drv/./dev_transfers.c:46: RETURN_CHECK(result);
	ld	l, d
l_usbdev_blk_out_trnsfer_00103:
;source-doc/base-drv/./dev_transfers.c:47: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./dev_transfers.c:49: usb_error usbdev_bulk_in_transfer(device_config *const dev, uint8_t *const buffer, uint8_t *const buffer_size) {
; ---------------------------------
; Function usbdev_bulk_in_transfer
; ---------------------------------
_usbdev_bulk_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/./dev_transfers.c:53: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_IN];
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,0x0006
	add	hl, bc
	ex	(sp), hl
;source-doc/base-drv/./dev_transfers.c:55: result = usb_data_in_transfer_n(buffer, buffer_size, dev->address, endpoint);
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	bc
	pop	de
	pop	hl
	push	hl
	push	de
	push	hl
	push	af
	inc	sp
	ld	l,(ix+8)
	ld	h,(ix+9)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	call	_usb_data_in_transfer_n
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	d, l
	pop	bc
;source-doc/base-drv/./dev_transfers.c:57: if (result == USB_ERR_STALL) {
	ld	a, d
	sub	0x02
	jr	NZ,l_usbdev_bulk_in_transfer_00102
;source-doc/base-drv/./dev_transfers.c:58: usbtrn_clear_endpoint_halt(endpoint->number, dev->address, dev->max_packet_size);
	ld	l, c
	ld	h, b
	inc	hl
	ld	d, (hl)
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	push	hl
	ld	a, (hl)
	rrca
	and	0x07
	push	de
	inc	sp
	push	bc
	inc	sp
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/./dev_transfers.c:59: endpoint->toggle = 0;
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/./dev_transfers.c:60: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_bulk_in_transfer_00103
l_usbdev_bulk_in_transfer_00102:
;source-doc/base-drv/./dev_transfers.c:63: RETURN_CHECK(result);
	ld	l, d
l_usbdev_bulk_in_transfer_00103:
;source-doc/base-drv/./dev_transfers.c:64: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./dev_transfers.c:66: usb_error usbdev_dat_in_trnsfer(device_config *const    device,
; ---------------------------------
; Function usbdev_dat_in_trnsfer
; ---------------------------------
_usbdev_dat_in_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/./dev_transfers.c:73: endpoint_param *const endpoint = &device->endpoints[endpoint_type];
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	e, c
	ld	d, b
	inc	de
	inc	de
	inc	de
	push	de
	ld	a,(ix+10)
	ld	e, a
	add	a, a
	add	a, e
	pop	de
	add	a, e
	ld	(ix-2),a
	ld	a,0x00
	adc	a, d
	ld	(ix-1),a
;source-doc/base-drv/./dev_transfers.c:75: result = usb_data_in_transfer(buffer, buffer_size, device->address, endpoint);
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	bc
	pop	de
	pop	hl
	push	hl
	push	de
	push	hl
	push	af
	inc	sp
	ld	l,(ix+8)
	ld	h,(ix+9)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	d, l
	pop	bc
;source-doc/base-drv/./dev_transfers.c:77: if (result == USB_ERR_STALL) {
	ld	a, d
	sub	0x02
	jr	NZ,l_usbdev_dat_in_trnsfer_00102
;source-doc/base-drv/./dev_transfers.c:78: usbtrn_clear_endpoint_halt(endpoint->number, device->address, device->max_packet_size);
	ld	l, c
	ld	h, b
	inc	hl
	ld	d, (hl)
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	push	hl
	ld	a, (hl)
	rrca
	and	0x07
	push	de
	inc	sp
	push	bc
	inc	sp
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/./dev_transfers.c:79: endpoint->toggle = 0;
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/./dev_transfers.c:80: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_dat_in_trnsfer_00103
l_usbdev_dat_in_trnsfer_00102:
;source-doc/base-drv/./dev_transfers.c:83: RETURN_CHECK(result);
	ld	l, d
l_usbdev_dat_in_trnsfer_00103:
;source-doc/base-drv/./dev_transfers.c:84: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./dev_transfers.c:86: usb_error usbdev_dat_in_trnsfer_0(device_config *const device, uint8_t *const buffer, const uint8_t buffer_size) __sdcccall(1) {
; ---------------------------------
; Function usbdev_dat_in_trnsfer_0
; ---------------------------------
_usbdev_dat_in_trnsfer_0:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	ld	c, l
	ld	b, h
	ld	(ix-2),e
	ld	(ix-1),d
;source-doc/base-drv/./dev_transfers.c:90: endpoint_param *const endpoint = &device->endpoints[0];
	ld	hl,0x0003
	add	hl, bc
	ex	(sp), hl
;source-doc/base-drv/./dev_transfers.c:92: result = usb_data_in_transfer(buffer, buffer_size, device->address, endpoint);
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	e,(ix+4)
	ld	d,0x00
	push	bc
	ld	l,(ix-4)
	ld	h,(ix-3)
	push	hl
	push	af
	inc	sp
	push	de
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	d, l
	pop	bc
;source-doc/base-drv/./dev_transfers.c:94: if (result == USB_ERR_STALL) {
	ld	a, d
	sub	0x02
	jr	NZ,l_usbdev_dat_in_trnsfer_0_00102
;source-doc/base-drv/./dev_transfers.c:95: usbtrn_clear_endpoint_halt(endpoint->number, device->address, device->max_packet_size);
	ld	l, c
	ld	h, b
	inc	hl
	ld	d, (hl)
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	push	hl
	ld	a, (hl)
	rrca
	and	0x07
	push	de
	inc	sp
	push	bc
	inc	sp
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/./dev_transfers.c:96: endpoint->toggle = 0;
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/./dev_transfers.c:97: return USB_ERR_STALL;
	ld	a,0x02
	jr	l_usbdev_dat_in_trnsfer_0_00103
l_usbdev_dat_in_trnsfer_0_00102:
;source-doc/base-drv/./dev_transfers.c:100: RETURN_CHECK(result);
	ld	a, d
l_usbdev_dat_in_trnsfer_0_00103:
;source-doc/base-drv/./dev_transfers.c:101: }
	ld	sp, ix
	pop	ix
	pop	hl
	inc	sp
	jp	(hl)
