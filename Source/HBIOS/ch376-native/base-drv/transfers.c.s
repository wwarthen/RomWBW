;
; Generated from source-doc/base-drv/transfers.c.asm -- not to be modify directly
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
;source-doc/base-drv/transfers.c:23: * See https://www.beyondlogic.org/usbnutshell/usb4.shtml for a description of the USB control transfer
; ---------------------------------
; Function usb_control_transfer
; ---------------------------------
_usb_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/transfers.c:28: * @param max_packet_size Maximum packet size for endpoint
	ld	hl,0
	add	hl, sp
	set	0, (hl)
	ld	hl,0
	add	hl, sp
	ld	a, (hl)
	and	$f1
	ld	(hl), a
	ld	c,(ix+9)
	ld	b,$00
	ld	hl,1
	add	hl, sp
	ld	(hl), c
	inc	hl
	ld	a, b
	and	$03
	ld	e, a
	ld	a, (hl)
	and	$fc
	or	e
	ld	(hl), a
;source-doc/base-drv/transfers.c:30: */
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	a, (bc)
	and	$80
;source-doc/base-drv/transfers.c:32: void *const               buffer,
	ld	(ix-1),a
	or	a
	jr	Z,l_usb_control_transfer_00102
	ld	a,(ix+7)
	or	(ix+6)
	jr	NZ,l_usb_control_transfer_00102
;source-doc/base-drv/transfers.c:33: const uint8_t             device_address,
	ld	l,$0f
	jp	l_usb_control_transfer_00114
l_usb_control_transfer_00102:
;source-doc/base-drv/transfers.c:35: usb_error      result;
	push	bc
	call	_critical_begin
;source-doc/base-drv/transfers.c:37:
	ld	l,(ix+8)
	call	_ch_set_usb_address
	pop	bc
;source-doc/base-drv/transfers.c:39:
	ld	e,(ix+4)
	ld	d,(ix+5)
	push	bc
	ld	a,$08
	push	af
	inc	sp
	push	de
	call	_ch_write_data
	pop	af
	inc	sp
;source-doc/base-drv/transfers.c:40: if (transferIn && buffer == 0)
	call	_ch_issue_token_setup
;source-doc/base-drv/transfers.c:41: return USB_ERR_OTHER;
	call	_ch_short_get_status
	pop	bc
;source-doc/base-drv/transfers.c:42:
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:44:
	ld	hl,6
	add	hl, bc
	ld	c, (hl)
	inc	hl
;source-doc/base-drv/transfers.c:47: ch_write_data((const uint8_t *)cmd_packet, sizeof(setup_packet));
	ld	a,(hl)
	ld	b,a
	or	c
	jr	Z,l_usb_control_transfer_00116
	ld	hl,0
	add	hl, sp
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00118
	push	hl
	push	bc
	push	de
	call	_ch_data_in_transfer
	pop	af
	pop	af
	pop	af
	jr	l_usb_control_transfer_00119
l_usb_control_transfer_00118:
	push	hl
	push	bc
	push	de
	call	_ch_data_out_transfer
	pop	af
	pop	af
	pop	af
l_usb_control_transfer_00119:
	jr	l_usb_control_transfer_00117
l_usb_control_transfer_00116:
;source-doc/base-drv/transfers.c:48: ch_issue_token_setup();
	ld	l,$00
l_usb_control_transfer_00117:
;source-doc/base-drv/transfers.c:50: CHECK(result);
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:52: const uint16_t length = cmd_packet->wLength;
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00112
;source-doc/base-drv/transfers.c:53:
	ld	l,$2c
	call	_ch_command
;source-doc/base-drv/transfers.c:54: result = length != 0
	ld	a,$00
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/transfers.c:55: ? (transferIn ? ch_data_in_transfer(buffer, length, &endpoint) : ch_data_out_transfer(buffer, length, &endpoint))
	call	_ch_issue_token_out_ep0
;source-doc/base-drv/transfers.c:56: : USB_ERR_OK;
	call	_ch_long_get_status
;source-doc/base-drv/transfers.c:58: CHECK(result)
	ld	a,l
	or	a
	jr	Z,l_usb_control_transfer_00108
	sub	$02
	jr	NZ,l_usb_control_transfer_00113
l_usb_control_transfer_00108:
;source-doc/base-drv/transfers.c:59:
	ld	l,$00
;source-doc/base-drv/transfers.c:60: if (transferIn) {
	jr	l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:63: ch_issue_token_out_ep0();
l_usb_control_transfer_00112:
;source-doc/base-drv/transfers.c:66: if (result == USB_ERR_OK || result == USB_ERR_STALL) {
	call	_ch_issue_token_in_ep0
;source-doc/base-drv/transfers.c:67: result = USB_ERR_OK;
	call	_ch_long_get_status
;source-doc/base-drv/transfers.c:71: RETURN_CHECK(result);
l_usb_control_transfer_00113:
;source-doc/base-drv/transfers.c:72: }
	push	hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/transfers.c:73:
l_usb_control_transfer_00114:
;source-doc/base-drv/transfers.c:74: ch_issue_token_in_ep0();
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/transfers.c:79: done:
; ---------------------------------
; Function usb_data_in_transfer
; ---------------------------------
_usb_data_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:81: return result;
	call	_critical_begin
;source-doc/base-drv/transfers.c:83:
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:85: * @brief Perform a USB data in on the specified endpoint
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ch_data_in_transfer
	pop	af
	pop	af
;source-doc/base-drv/transfers.c:87: * @param buffer the buffer to receive the data
	ex	(sp),hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/transfers.c:89: * @param device_address the usb address of the device
;source-doc/base-drv/transfers.c:90: * @param endpoint the usb endpoint to receive from (toggle of endpoint is updated)
	pop	ix
	ret
;source-doc/base-drv/transfers.c:95: usb_error result;
; ---------------------------------
; Function usb_data_in_transfer_n
; ---------------------------------
_usb_data_in_transfer_n:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:98: ch_set_usb_address(device_address);
	call	_critical_begin
;source-doc/base-drv/transfers.c:100: result = ch_data_in_transfer(buffer, buffer_size, endpoint);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:102: critical_end();
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ch_data_in_transfer_n
	pop	af
	pop	af
;source-doc/base-drv/transfers.c:104: return result;
	ex	(sp),hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/transfers.c:106:
;source-doc/base-drv/transfers.c:107: /**
	pop	ix
	ret
;source-doc/base-drv/transfers.c:112: * @param device_address the usb address of the device
; ---------------------------------
; Function usb_data_out_transfer
; ---------------------------------
_usb_data_out_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:114: * @return usb_error USB_ERR_OK if all good, otherwise specific error code
	call	_critical_begin
;source-doc/base-drv/transfers.c:116: usb_error
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:118: usb_error result;
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ch_data_out_transfer
	pop	af
	pop	af
;source-doc/base-drv/transfers.c:120: critical_begin();
	ex	(sp),hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/transfers.c:122: ch_set_usb_address(device_address);
;source-doc/base-drv/transfers.c:123:
	pop	ix
	ret
