;
; Generated from source-doc/base-drv/dev_transfers.c.asm -- not to be modify directly
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
;source-doc/base-drv/dev_transfers.c:31: usb_error usbdev_control_transfer(device_config *const device, const setup_packet *const cmd_packet, uint8_t *const buffer) {
; ---------------------------------
; Function usbdev_control_transfer
; ---------------------------------
_usbdev_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/dev_transfers.c:32: return usb_control_transfer(cmd_packet, buffer, device->address, device->max_packet_size);
	ld	l,(ix+4)
	ld	h,(ix+5)
	ld	e,l
	ld	d,h
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
	ld	c,a
	push	bc
	push	de
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/dev_transfers.c:33: }
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:35: usb_error usbdev_blk_out_trnsfer(device_config *const dev, const uint8_t *const buffer, const uint16_t buffer_size) {
; ---------------------------------
; Function usbdev_blk_out_trnsfer
; ---------------------------------
_usbdev_blk_out_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/dev_transfers.c:37: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_OUT];
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	inc	bc
;source-doc/base-drv/dev_transfers.c:39: result = usb_data_out_transfer(buffer, buffer_size, dev->address, endpoint);
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	bc
	push	de
	push	bc
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
	pop	de
	pop	bc
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:41: if (result == USB_ERR_STALL) {
	ld	a,(_result)
	sub	0x02
	jr	NZ,l_usbdev_blk_out_trnsfer_00102
;source-doc/base-drv/dev_transfers.c:42: usbtrn_clear_endpoint_halt(endpoint->number, dev->address, dev->max_packet_size);
	ld	l, e
	ld	h, d
	inc	hl
	ld	a, (hl)
	ld	(ix-1),a
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	d, a
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rrca
	and	0x07
	push	bc
	ld	h,(ix-1)
	ld	l,d
	push	hl
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
	pop	bc
;source-doc/base-drv/dev_transfers.c:43: endpoint->toggle = 0;
	ld	a, (bc)
	and	0xfe
	ld	(bc), a
;source-doc/base-drv/dev_transfers.c:44: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_blk_out_trnsfer_00104
l_usbdev_blk_out_trnsfer_00102:
;source-doc/base-drv/dev_transfers.c:47: RETURN_CHECK(result);
;source-doc/base-drv/dev_transfers.c:50: return result;
	ld	hl,(_result)
l_usbdev_blk_out_trnsfer_00104:
;source-doc/base-drv/dev_transfers.c:51: }
	inc	sp
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:53: usb_error usbdev_bulk_in_transfer(device_config *const dev, uint8_t *const buffer, uint8_t *const buffer_size) {
; ---------------------------------
; Function usbdev_bulk_in_transfer
; ---------------------------------
_usbdev_bulk_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/dev_transfers.c:54: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_IN];
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,0x0006
	add	hl, bc
;source-doc/base-drv/dev_transfers.c:56: result = usb_data_in_transfer_n(buffer, buffer_size, dev->address, endpoint);
	ld	e,c
	ld	d,b
	ex	de,hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	bc
	push	de
	push	de
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
	pop	de
	pop	bc
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:58: if (result == USB_ERR_STALL) {
	ld	a,(_result)
	sub	0x02
	jr	NZ,l_usbdev_bulk_in_transfer_00102
;source-doc/base-drv/dev_transfers.c:59: usbtrn_clear_endpoint_halt(endpoint->number, dev->address, dev->max_packet_size);
	ld	l, c
	ld	h, b
	inc	hl
	ld	a, (hl)
	ld	(ix-1),a
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	0x07
	push	de
	ld	h,(ix-1)
	ld	l,b
	push	hl
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
	pop	de
;source-doc/base-drv/dev_transfers.c:60: endpoint->toggle = 0;
	ex	de, hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:61: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_bulk_in_transfer_00104
l_usbdev_bulk_in_transfer_00102:
;source-doc/base-drv/dev_transfers.c:64: RETURN_CHECK(result);
;source-doc/base-drv/dev_transfers.c:66: return result;
	ld	hl,(_result)
l_usbdev_bulk_in_transfer_00104:
;source-doc/base-drv/dev_transfers.c:67: }
	inc	sp
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:69: usb_error usbdev_dat_in_trnsfer(device_config *const    device,
; ---------------------------------
; Function usbdev_dat_in_trnsfer
; ---------------------------------
_usbdev_dat_in_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/dev_transfers.c:74: endpoint_param *const endpoint = &device->endpoints[endpoint_type];
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	inc	bc
	push	de
	ld	a,(ix+10)
	ld	e, a
	add	a, a
	add	a, e
	pop	de
	add	a, c
	ld	c, a
	ld	a,0x00
	adc	a, b
	ld	b, a
;source-doc/base-drv/dev_transfers.c:76: result = usb_data_in_transfer(buffer, buffer_size, device->address, endpoint);
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	push	bc
	push	de
	push	bc
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
	pop	de
	pop	bc
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:78: if (result == USB_ERR_STALL) {
	ld	a,(_result)
	sub	0x02
	jr	NZ,l_usbdev_dat_in_trnsfer_00102
;source-doc/base-drv/dev_transfers.c:79: usbtrn_clear_endpoint_halt(endpoint->number, device->address, device->max_packet_size);
	ld	l, e
	ld	h, d
	inc	hl
	ld	a, (hl)
	ld	(ix-1),a
	ex	de, hl
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	d, a
	ld	l, c
	ld	h, b
	ld	a, (hl)
	rrca
	and	0x07
	push	bc
	ld	h,(ix-1)
	ld	l,d
	push	hl
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
	pop	bc
;source-doc/base-drv/dev_transfers.c:80: endpoint->toggle = 0;
	ld	a, (bc)
	and	0xfe
	ld	(bc), a
;source-doc/base-drv/dev_transfers.c:81: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_dat_in_trnsfer_00104
l_usbdev_dat_in_trnsfer_00102:
;source-doc/base-drv/dev_transfers.c:84: RETURN_CHECK(result);
;source-doc/base-drv/dev_transfers.c:86: return result;
	ld	hl,(_result)
l_usbdev_dat_in_trnsfer_00104:
;source-doc/base-drv/dev_transfers.c:87: }
	inc	sp
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:89: usb_error usbdev_dat_in_trnsfer_0(device_config *const device, uint8_t *const buffer, const uint8_t buffer_size) {
; ---------------------------------
; Function usbdev_dat_in_trnsfer_0
; ---------------------------------
_usbdev_dat_in_trnsfer_0:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/dev_transfers.c:90: endpoint_param *const endpoint = &device->endpoints[0];
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,0x0003
	add	hl, de
	ex	(sp), hl
;source-doc/base-drv/dev_transfers.c:92: result = usb_data_in_transfer(buffer, buffer_size, device->address, endpoint);
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	c,(ix+8)
	ld	b,0x00
	push	de
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	af
	inc	sp
	push	bc
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	de
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:94: if (result == USB_ERR_STALL) {
	ld	a,(_result)
	sub	0x02
	jr	NZ,l_usbdev_dat_in_trnsfer_0_00102
;source-doc/base-drv/dev_transfers.c:95: usbtrn_clear_endpoint_halt(endpoint->number, device->address, device->max_packet_size);
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
	ld	d, a
	pop	hl
	ld	a,(hl)
	push	hl
	rrca
	and	0x07
	ld	c, d
	push	bc
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/dev_transfers.c:96: endpoint->toggle = 0;
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:97: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_usbdev_dat_in_trnsfer_0_00103
l_usbdev_dat_in_trnsfer_0_00102:
;source-doc/base-drv/dev_transfers.c:100: return result;
	ld	hl,(_result)
l_usbdev_dat_in_trnsfer_0_00103:
;source-doc/base-drv/dev_transfers.c:101: }
	ld	sp, ix
	pop	ix
	ret
