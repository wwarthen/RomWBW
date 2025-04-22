;
; Generated from source-doc/base-drv/dev_transfers.c.asm -- not to be modify directly
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
;source-doc/base-drv/dev_transfers.c:23: * See https://www.beyondlogic.org/usbnutshell/usb4.shtml for a description of the USB control transfer
; ---------------------------------
; Function usbdev_control_transfer
; ---------------------------------
_usbdev_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/dev_transfers.c:24: *
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
;source-doc/base-drv/dev_transfers.c:25: * @param device the usb device
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:27: * @param buffer Pointer of data to send or receive into
; ---------------------------------
; Function usbdev_blk_out_trnsfer
; ---------------------------------
_usbdev_blk_out_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/dev_transfers.c:29: */
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,0x0003
	add	hl, de
	ex	(sp), hl
;source-doc/base-drv/dev_transfers.c:31: return usb_control_transfer(cmd_packet, buffer, device->address, device->max_packet_size);
	ld	(ix-2),e
	ld	(ix-1),d
	pop	bc
	pop	hl
	ld	a,(hl)
	push	hl
	push	bc
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
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:33:
	ld	hl,_result
	ld	a, (hl)
	sub	0x02
	jr	NZ,l_usbdev_blk_out_trnsfer_00102
;source-doc/base-drv/dev_transfers.c:34: usb_error usbdev_blk_out_trnsfer(device_config *const dev, const uint8_t *const buffer, const uint16_t buffer_size) {
	ex	de, hl
	inc	hl
	ld	d, (hl)
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rrca
	and	0x07
	ld	e,b
	push	de
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/dev_transfers.c:35:
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:36: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_OUT];
	ld	l,0x02
	jr	l_usbdev_blk_out_trnsfer_00104
l_usbdev_blk_out_trnsfer_00102:
;source-doc/base-drv/dev_transfers.c:39:
;source-doc/base-drv/dev_transfers.c:42: endpoint->toggle = 0;
	ld	hl, (_result)
l_usbdev_blk_out_trnsfer_00104:
;source-doc/base-drv/dev_transfers.c:43: return USB_ERR_STALL;
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:45:
; ---------------------------------
; Function usbdev_bulk_in_transfer
; ---------------------------------
_usbdev_bulk_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/dev_transfers.c:46: RETURN_CHECK(result);
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,0x0006
	add	hl, de
	ex	(sp), hl
;source-doc/base-drv/dev_transfers.c:48: done:
	ld	(ix-2),e
	ld	(ix-1),d
	pop	bc
	pop	hl
	ld	a,(hl)
	push	hl
	push	bc
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
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:50: }
	ld	hl,_result
	ld	a, (hl)
	sub	0x02
	jr	NZ,l_usbdev_bulk_in_transfer_00102
;source-doc/base-drv/dev_transfers.c:51:
	ex	de, hl
	inc	hl
	ld	d, (hl)
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rrca
	and	0x07
	ld	e,b
	push	de
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/dev_transfers.c:52: usb_error usbdev_bulk_in_transfer(device_config *const dev, uint8_t *const buffer, uint8_t *const buffer_size) {
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:53: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_IN];
	ld	l,0x02
	jr	l_usbdev_bulk_in_transfer_00104
l_usbdev_bulk_in_transfer_00102:
;source-doc/base-drv/dev_transfers.c:56:
;source-doc/base-drv/dev_transfers.c:58: usbtrn_clear_endpoint_halt(endpoint->number, dev->address, dev->max_packet_size);
	ld	hl, (_result)
l_usbdev_bulk_in_transfer_00104:
;source-doc/base-drv/dev_transfers.c:59: endpoint->toggle = 0;
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:61: }
; ---------------------------------
; Function usbdev_dat_in_trnsfer
; ---------------------------------
_usbdev_dat_in_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/dev_transfers.c:66: }
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
	ld	(ix-4),a
	ld	a,0x00
	adc	a, b
	ld	(ix-3),a
;source-doc/base-drv/dev_transfers.c:68: usb_error usbdev_dat_in_trnsfer(device_config *const    device,
	ld	(ix-2),e
	ld	(ix-1),d
	pop	bc
	pop	hl
	ld	a,(hl)
	push	hl
	push	bc
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
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/dev_transfers.c:70: const uint16_t          buffer_size,
	ld	hl,_result
	ld	a, (hl)
	sub	0x02
	jr	NZ,l_usbdev_dat_in_trnsfer_00102
;source-doc/base-drv/dev_transfers.c:71: const usb_endpoint_type endpoint_type) {
	ex	de, hl
	inc	hl
	ld	d, (hl)
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rrca
	and	0x07
	ld	e,b
	push	de
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/dev_transfers.c:72:
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:73: endpoint_param *const endpoint = &device->endpoints[endpoint_type];
	ld	l,0x02
	jr	l_usbdev_dat_in_trnsfer_00104
l_usbdev_dat_in_trnsfer_00102:
;source-doc/base-drv/dev_transfers.c:76:
;source-doc/base-drv/dev_transfers.c:78: usbtrn_clear_endpoint_halt(endpoint->number, device->address, device->max_packet_size);
	ld	hl, (_result)
l_usbdev_dat_in_trnsfer_00104:
;source-doc/base-drv/dev_transfers.c:79: endpoint->toggle = 0;
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:81: }
; ---------------------------------
; Function usbdev_dat_in_trnsfer_0
; ---------------------------------
_usbdev_dat_in_trnsfer_0:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/dev_transfers.c:82:
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	hl,0x0003
	add	hl, de
	ex	(sp), hl
;source-doc/base-drv/dev_transfers.c:84: done:
	ld	(ix-2),e
	ld	(ix-1),d
	pop	bc
	pop	hl
	ld	a,(hl)
	push	hl
	push	bc
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	c,(ix+8)
	ld	b,0x00
	push	de
	ld	l,(ix-4)
	ld	h,(ix-3)
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
;source-doc/base-drv/dev_transfers.c:86: }
	ld	hl,_result
	ld	a, (hl)
	sub	0x02
	jr	NZ,l_usbdev_dat_in_trnsfer_0_00102
;source-doc/base-drv/dev_transfers.c:87:
	ex	de, hl
	inc	hl
	ld	d, (hl)
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	0x0f
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rrca
	and	0x07
	ld	e,b
	push	de
	push	af
	inc	sp
	call	_usbtrn_clear_endpoint_halt
	pop	af
	inc	sp
;source-doc/base-drv/dev_transfers.c:88: usb_error usbdev_dat_in_trnsfer_0(device_config *const device, uint8_t *const buffer, const uint8_t buffer_size) {
	pop	hl
	push	hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:89: endpoint_param *const endpoint = &device->endpoints[0];
	ld	l,0x02
	jr	l_usbdev_dat_in_trnsfer_0_00103
l_usbdev_dat_in_trnsfer_0_00102:
;source-doc/base-drv/dev_transfers.c:92:
	ld	hl, (_result)
l_usbdev_dat_in_trnsfer_0_00103:
;source-doc/base-drv/dev_transfers.c:93: if (result == USB_ERR_STALL) {
	ld	sp, ix
	pop	ix
	ret
