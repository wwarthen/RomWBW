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
	and	$0f
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
;source-doc/base-drv/dev_transfers.c:30: usb_error usbdev_control_transfer(device_config *const device, const setup_packet *const cmd_packet, uint8_t *const buffer) {
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	e, c
	ld	d, b
	inc	de
	inc	de
	inc	de
;source-doc/base-drv/dev_transfers.c:32: }
	pop	hl
	ld	l,c
	ld	h,b
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
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
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	de
	pop	bc
;source-doc/base-drv/dev_transfers.c:34: usb_error usbdev_blk_out_trnsfer(device_config *const dev, const uint8_t *const buffer, const uint16_t buffer_size) {
	ld	a, l
	sub	$02
	jr	NZ,l_usbdev_blk_out_trnsfer_00102
;source-doc/base-drv/dev_transfers.c:35: usb_error result;
	inc	bc
	ld	a, (bc)
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	c, a
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	$07
	push	de
	push	bc
	inc	sp
	ld	h, c
	ld	l,a
	push	hl
	call	_usbtrn_clr_ep_halt
	pop	af
	inc	sp
	pop	de
;source-doc/base-drv/dev_transfers.c:36:
	ex	de, hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:37: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_OUT];
	ld	l,$02
;source-doc/base-drv/dev_transfers.c:43: endpoint->toggle = 0;
l_usbdev_blk_out_trnsfer_00102:
;source-doc/base-drv/dev_transfers.c:44: return USB_ERR_STALL;
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:46:
; ---------------------------------
; Function usbdev_bulk_in_transfer
; ---------------------------------
_usbdev_bulk_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/dev_transfers.c:49: done:
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,$0006
	add	hl, bc
;source-doc/base-drv/dev_transfers.c:51: }
	pop	de
	ld	e,c
	ld	d,b
	ex	de,hl
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
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
;source-doc/base-drv/dev_transfers.c:53: usb_error usbdev_bulk_in_transfer(device_config *const dev, uint8_t *const buffer, uint8_t *const buffer_size) {
	ld	a, l
	sub	$02
	jr	NZ,l_usbdev_bulk_in_transfer_00102
;source-doc/base-drv/dev_transfers.c:54: usb_error result;
	inc	bc
	ld	a, (bc)
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	c, a
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	$07
	push	de
	push	bc
	inc	sp
	ld	h, c
	ld	l,a
	push	hl
	call	_usbtrn_clr_ep_halt
	pop	af
	inc	sp
	pop	de
;source-doc/base-drv/dev_transfers.c:55:
	ex	de, hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:56: endpoint_param *const endpoint = &dev->endpoints[ENDPOINT_BULK_IN];
	ld	l,$02
;source-doc/base-drv/dev_transfers.c:61: usbtrn_clr_ep_halt(endpoint->number, dev->address, dev->max_packet_size);
l_usbdev_bulk_in_transfer_00102:
;source-doc/base-drv/dev_transfers.c:62: endpoint->toggle = 0;
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:64: }
; ---------------------------------
; Function usbdev_dat_in_trnsfer
; ---------------------------------
_usbdev_dat_in_trnsfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/dev_transfers.c:70:
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
	ld	e, a
	ld	a,$00
	adc	a, d
	ld	d, a
;source-doc/base-drv/dev_transfers.c:72: uint8_t *const          buffer,
	pop	hl
	ld	l,c
	ld	h,b
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
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
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
	pop	de
	pop	bc
;source-doc/base-drv/dev_transfers.c:74: const usb_endpoint_type endpoint_type) {
	ld	a, l
	sub	$02
	jr	NZ,l_usbdev_dat_in_trnsfer_00102
;source-doc/base-drv/dev_transfers.c:75: usb_error result;
	inc	bc
	ld	a, (bc)
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	c, a
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	$07
	push	de
	push	bc
	inc	sp
	ld	h, c
	ld	l,a
	push	hl
	call	_usbtrn_clr_ep_halt
	pop	af
	inc	sp
	pop	de
;source-doc/base-drv/dev_transfers.c:76:
	ex	de, hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:77: endpoint_param *const endpoint = &device->endpoints[endpoint_type];
	ld	l,$02
;source-doc/base-drv/dev_transfers.c:82: usbtrn_clr_ep_halt(endpoint->number, device->address, device->max_packet_size);
l_usbdev_dat_in_trnsfer_00102:
;source-doc/base-drv/dev_transfers.c:83: endpoint->toggle = 0;
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/dev_transfers.c:85: }
; ---------------------------------
; Function usbdev_dat_in_trnsfer_0
; ---------------------------------
_usbdev_dat_in_trnsfer_0:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/dev_transfers.c:88: done:
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	e, c
	ld	d, b
	inc	de
	inc	de
	inc	de
;source-doc/base-drv/dev_transfers.c:90: }
	pop	hl
	ld	l,c
	ld	h,b
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	l,(ix+8)
	ld	h,$00
	push	bc
	push	de
	push	de
	push	af
	inc	sp
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
;source-doc/base-drv/dev_transfers.c:92: usb_error usbdev_dat_in_trnsfer_0(device_config *const device, uint8_t *const buffer, const uint8_t buffer_size) {
	ld	a, l
	sub	$02
	jr	NZ,l_usbdev_dat_in_trnsfer_0_00102
;source-doc/base-drv/dev_transfers.c:93: usb_error result;
	inc	bc
	ld	a, (bc)
	ld	b, a
	pop	hl
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	$0f
	ld	c, a
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	$07
	push	de
	push	bc
	inc	sp
	ld	h, c
	ld	l,a
	push	hl
	call	_usbtrn_clr_ep_halt
	pop	af
	inc	sp
	pop	de
;source-doc/base-drv/dev_transfers.c:94:
	ex	de, hl
	res	0, (hl)
;source-doc/base-drv/dev_transfers.c:95: endpoint_param *const endpoint = &device->endpoints[0];
	ld	l,$02
;source-doc/base-drv/dev_transfers.c:98:
l_usbdev_dat_in_trnsfer_0_00102:
;source-doc/base-drv/dev_transfers.c:99: if (result == USB_ERR_STALL) {
	ld	sp, ix
	pop	ix
	ret
