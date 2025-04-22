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
;source-doc/base-drv/transfers.c:22:
; ---------------------------------
; Function usb_ctrl_trnsfer_ext
; ---------------------------------
_usb_ctrl_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:26: const uint8_t             max_packet_size) {
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00102
;source-doc/base-drv/transfers.c:27: if ((uint16_t)cmd_packet < LOWER_SAFE_RAM_ADDRESS)
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00102:
;source-doc/base-drv/transfers.c:29:
	ld	a,(ix+7)
	or	(ix+6)
	jr	Z,l_usb_ctrl_trnsfer_ext_00104
	ld	a,(ix+7)
	sub	0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00104
;source-doc/base-drv/transfers.c:30: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00104:
;source-doc/base-drv/transfers.c:32:
	ld	h,(ix+9)
	ld	l,(ix+8)
	push	hl
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
l_usb_ctrl_trnsfer_ext_00106:
;source-doc/base-drv/transfers.c:33: return usb_control_transfer(cmd_packet, buffer, device_address, max_packet_size);
	pop	ix
	ret
;source-doc/base-drv/transfers.c:37: * @brief Perform a USB control transfer (in or out)
; ---------------------------------
; Function usb_control_transfer
; ---------------------------------
_usb_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/transfers.c:42: * @param device_address usb device address
	ld	hl,0
	add	hl, sp
	set	0, (hl)
	ld	hl,0
	add	hl, sp
	ld	a, (hl)
	and	0xf1
	ld	(hl), a
	ld	c,(ix+9)
	ld	b,0x00
	ld	hl,1
	add	hl, sp
	ld	(hl), c
	inc	hl
	ld	a, b
	and	0x03
	ld	e, a
	ld	a, (hl)
	and	0xfc
	or	e
	ld	(hl), a
;source-doc/base-drv/transfers.c:44: * @return usb_error USB_ERR_OK if all good, otherwise specific error code
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	a, (bc)
	and	0x80
;source-doc/base-drv/transfers.c:46: usb_error usb_control_transfer(const setup_packet *const cmd_packet,
	ld	(ix-1),a
	or	a
	jr	Z,l_usb_control_transfer_00102
	ld	a,(ix+7)
	or	(ix+6)
	jr	NZ,l_usb_control_transfer_00102
;source-doc/base-drv/transfers.c:47: void *const               buffer,
	ld	l,0x0f
	jp	l_usb_control_transfer_00114
l_usb_control_transfer_00102:
;source-doc/base-drv/transfers.c:49: const uint8_t             max_packet_size) {
	push	bc
	call	_critical_begin
;source-doc/base-drv/transfers.c:51: endpoint_param endpoint = {1, 0, max_packet_size};
	ld	l,(ix+8)
	call	_ch_set_usb_address
	pop	bc
;source-doc/base-drv/transfers.c:53: const uint8_t transferIn = (cmd_packet->bmRequestType & 0x80);
	ld	e,(ix+4)
	ld	d,(ix+5)
	push	bc
	ld	a,0x08
	push	af
	inc	sp
	push	de
	call	_ch_write_data
	pop	af
	inc	sp
;source-doc/base-drv/transfers.c:54:
	call	_ch_issue_token_setup
;source-doc/base-drv/transfers.c:55: if (transferIn && buffer == 0)
	call	_ch_short_wait_int_and_get_stat
	pop	bc
;source-doc/base-drv/transfers.c:56: return USB_ERR_OTHER;
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:58: critical_begin();
	ld	hl,6
	add	hl, bc
	ld	c, (hl)
	inc	hl
;source-doc/base-drv/transfers.c:61:
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
;source-doc/base-drv/transfers.c:62: ch_write_data((const uint8_t *)cmd_packet, sizeof(setup_packet));
	ld	l,0x00
l_usb_control_transfer_00117:
;source-doc/base-drv/transfers.c:64: result = ch_short_wait_int_and_get_statu();
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:66:
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00112
;source-doc/base-drv/transfers.c:67: const uint16_t length = cmd_packet->wLength;
	ld	l,0x2c
	call	_ch_command
;source-doc/base-drv/transfers.c:68:
	ld	a,0x00
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/transfers.c:69: result = length != 0
	call	_ch_issue_token_out_ep0
;source-doc/base-drv/transfers.c:70: ? (transferIn ? ch_data_in_transfer(buffer, length, &endpoint) : ch_data_out_transfer(buffer, length, &endpoint))
	call	_ch_long_wait_int_and_get_statu
;source-doc/base-drv/transfers.c:72:
	ld	a,l
	or	a
	jr	Z,l_usb_control_transfer_00108
	sub	0x02
	jr	NZ,l_usb_control_transfer_00113
l_usb_control_transfer_00108:
;source-doc/base-drv/transfers.c:73: CHECK(result)
	ld	l,0x00
;source-doc/base-drv/transfers.c:74:
	jr	l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:77: CH376_DATA_PORT = 0;
l_usb_control_transfer_00112:
;source-doc/base-drv/transfers.c:80:
	call	_ch_issue_token_in_ep0
;source-doc/base-drv/transfers.c:81: if (result == USB_ERR_OK || result == USB_ERR_STALL) {
	call	_ch_long_wait_int_and_get_statu
;source-doc/base-drv/transfers.c:85:
l_usb_control_transfer_00113:
;source-doc/base-drv/transfers.c:86: RETURN_CHECK(result);
	push	hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/transfers.c:87: }
l_usb_control_transfer_00114:
;source-doc/base-drv/transfers.c:88:
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/transfers.c:91:
; ---------------------------------
; Function usb_dat_in_trnsfer_ext
; ---------------------------------
_usb_dat_in_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:92: RETURN_CHECK(result);
	ld	a,(ix+5)
	or	(ix+4)
	jr	Z,l_usb_dat_in_trnsfer_ext_00102
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00102
;source-doc/base-drv/transfers.c:93:
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00102:
;source-doc/base-drv/transfers.c:95: critical_end();
	ld	a,(ix+10)
	sub	0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00105
;source-doc/base-drv/transfers.c:96: return result;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00105:
;source-doc/base-drv/transfers.c:98:
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	a,(ix+8)
	push	af
	inc	sp
	ld	l,(ix+6)
	ld	h,(ix+7)
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_data_in_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
l_usb_dat_in_trnsfer_ext_00106:
;source-doc/base-drv/transfers.c:99: usb_error
	pop	ix
	ret
;source-doc/base-drv/transfers.c:104: if ((uint16_t)endpoint < LOWER_SAFE_RAM_ADDRESS)
; ---------------------------------
; Function usb_data_in_transfer
; ---------------------------------
_usb_data_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:105: return USB_BAD_ADDRESS;
	call	_critical_begin
;source-doc/base-drv/transfers.c:107: return usb_data_in_transfer(buffer, buffer_size, device_address, endpoint);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:109:
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
	pop	af
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/transfers.c:111: * @brief Perform a USB data in on the specififed endpoint
	call	_critical_end
;source-doc/base-drv/transfers.c:113: * @param buffer the buffer to receive the data
	ld	hl, (_result)
;source-doc/base-drv/transfers.c:114: * @param buffer_size the maximum size of data to be received
	pop	ix
	ret
;source-doc/base-drv/transfers.c:119: usb_error
; ---------------------------------
; Function usb_data_in_transfer_n
; ---------------------------------
_usb_data_in_transfer_n:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:120: usb_data_in_transfer(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
	call	_critical_begin
;source-doc/base-drv/transfers.c:122:
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:124:
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
	pop	af
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/transfers.c:126:
	call	_critical_end
;source-doc/base-drv/transfers.c:128:
	ld	hl, (_result)
;source-doc/base-drv/transfers.c:129: return result;
	pop	ix
	ret
;source-doc/base-drv/transfers.c:134: *
; ---------------------------------
; Function usb_data_out_transfer
; ---------------------------------
_usb_data_out_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:135: * @param buffer the buffer to receive the data - must be 62 bytes
	call	_critical_begin
;source-doc/base-drv/transfers.c:137: * @param device_address the usb address of the device
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:139: * @return usb_error USB_ERR_OK if all good, otherwise specific error code
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
	pop	af
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/transfers.c:141: usb_error
	call	_critical_end
;source-doc/base-drv/transfers.c:143: critical_begin();
	ld	hl, (_result)
;source-doc/base-drv/transfers.c:144:
	pop	ix
	ret
