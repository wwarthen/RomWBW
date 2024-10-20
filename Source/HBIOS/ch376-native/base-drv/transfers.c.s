;
; Generated from source-doc/base-drv/./transfers.c.asm -- not to be modify directly
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
;source-doc/base-drv/./transfers.c:24: usb_error usb_ctrl_trnsfer_ext(const setup_packet *const cmd_packet,
; ---------------------------------
; Function usb_ctrl_trnsfer_ext
; ---------------------------------
_usb_ctrl_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:28: if ((uint16_t)cmd_packet < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00102
;source-doc/base-drv/./transfers.c:29: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00102:
;source-doc/base-drv/./transfers.c:31: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+7)
	or	(ix+6)
	jr	Z,l_usb_ctrl_trnsfer_ext_00104
	ld	a,(ix+7)
	sub	0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00104
;source-doc/base-drv/./transfers.c:32: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00104:
;source-doc/base-drv/./transfers.c:34: return usb_control_transfer(cmd_packet, buffer, device_address, max_packet_size);
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
;source-doc/base-drv/./transfers.c:35: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:47: usb_error usb_control_transfer(const setup_packet *const cmd_packet,
; ---------------------------------
; Function usb_control_transfer
; ---------------------------------
_usb_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/./transfers.c:52: endpoint_param endpoint = {1, 0, max_packet_size};
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
	ld	e,a
	ld	a, (hl)
	and	0xfc
	or	e
	ld	(hl), a
;source-doc/base-drv/./transfers.c:54: const uint8_t transferIn = (cmd_packet->bmRequestType & 0x80);
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	a, (bc)
	and	0x80
;source-doc/base-drv/./transfers.c:56: if (transferIn && buffer == 0)
	ld	(ix-1),a
	or	a
	jr	Z,l_usb_control_transfer_00102
	ld	a,(ix+7)
	or	(ix+6)
	jr	NZ,l_usb_control_transfer_00102
;source-doc/base-drv/./transfers.c:57: return USB_ERR_OTHER;
	ld	l,0x0f
	jp	l_usb_control_transfer_00114
l_usb_control_transfer_00102:
;source-doc/base-drv/./transfers.c:59: critical_begin();
	push	bc
	call	_critical_begin
	ld	l,(ix+8)
	call	_ch_set_usb_address
	pop	bc
;source-doc/base-drv/./transfers.c:63: ch_write_data((const uint8_t *)cmd_packet, sizeof(setup_packet));
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
	call	_ch_issue_token_setup
	call	_ch_short_wait_int_and_get_stat
	pop	bc
;source-doc/base-drv/./transfers.c:66: CHECK(result);
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/./transfers.c:68: const uint16_t length = cmd_packet->wLength;
	ld	hl,6
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/./transfers.c:71: ? (transferIn ? ch_data_in_transfer(buffer, length, &endpoint) : ch_data_out_transfer(buffer, length, &endpoint))
	ld	a, b
	or	c
	jr	Z,l_usb_control_transfer_00116
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00118
	ld	hl,0
	add	hl, sp
	push	hl
	push	bc
	push	de
	call	_ch_data_in_transfer
	pop	af
	pop	af
	pop	af
	jr	l_usb_control_transfer_00119
l_usb_control_transfer_00118:
	ld	hl,0
	add	hl, sp
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
;source-doc/base-drv/./transfers.c:72: : USB_ERR_OK;
	ld	l,0x00
l_usb_control_transfer_00117:
;source-doc/base-drv/./transfers.c:74: CHECK(result)
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/./transfers.c:76: if (transferIn) {
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00112
;source-doc/base-drv/./transfers.c:77: ch_command(CH_CMD_WR_HOST_DATA);
	ld	l,0x2c
	call	_ch_command
;source-doc/base-drv/./transfers.c:78: CH376_DATA_PORT = 0;
	ld	a,0x00
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/./transfers.c:79: ch_issue_token_out_ep0();
	call	_ch_issue_token_out_ep0
;source-doc/base-drv/./transfers.c:80: result = ch_long_wait_int_and_get_status(); /* sometimes we get STALL here - seems to be ok to ignore */
	call	_ch_long_wait_int_and_get_statu
;source-doc/base-drv/./transfers.c:82: if (result == USB_ERR_OK || result == USB_ERR_STALL) {
	ld	a, l
	or	a
	jr	Z,l_usb_control_transfer_00108
	ld	a, l
	sub	0x02
	jr	NZ,l_usb_control_transfer_00113
l_usb_control_transfer_00108:
;source-doc/base-drv/./transfers.c:83: result = USB_ERR_OK;
	ld	l,0x00
;source-doc/base-drv/./transfers.c:84: goto done;
	jr	l_usb_control_transfer_00113
;source-doc/base-drv/./transfers.c:87: RETURN_CHECK(result);
l_usb_control_transfer_00112:
;source-doc/base-drv/./transfers.c:90: ch_issue_token_in_ep0();
	call	_ch_issue_token_in_ep0
;source-doc/base-drv/./transfers.c:91: result = ch_long_wait_int_and_get_status();
	call	_ch_long_wait_int_and_get_statu
;source-doc/base-drv/./transfers.c:95: done:
l_usb_control_transfer_00113:
;source-doc/base-drv/./transfers.c:96: critical_end();
	push	hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/./transfers.c:97: return result;
l_usb_control_transfer_00114:
;source-doc/base-drv/./transfers.c:98: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:101: usb_dat_in_trnsfer_ext(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_dat_in_trnsfer_ext
; ---------------------------------
_usb_dat_in_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:102: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	or	(ix+4)
	jr	Z,l_usb_dat_in_trnsfer_ext_00102
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00102
;source-doc/base-drv/./transfers.c:103: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00102:
;source-doc/base-drv/./transfers.c:105: if ((uint16_t)endpoint < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+10)
	sub	0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00105
;source-doc/base-drv/./transfers.c:106: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00105:
;source-doc/base-drv/./transfers.c:108: return usb_data_in_transfer(buffer, buffer_size, device_address, endpoint);
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
;source-doc/base-drv/./transfers.c:109: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:112: usb_dat_in_trns_n_ext(uint8_t *buffer, uint16_t *buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_dat_in_trns_n_ext
; ---------------------------------
_usb_dat_in_trns_n_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:113: if (buffer != 0 && ((uint16_t)buffer & 0xC000) == 0)
	ld	a,(ix+5)
	or	(ix+4)
	jr	Z,l_usb_dat_in_trns_n_ext_00102
	ld	a,(ix+5)
	and	0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00102
;source-doc/base-drv/./transfers.c:114: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00102:
;source-doc/base-drv/./transfers.c:116: if (((uint16_t)endpoint & 0xC000) == 0)
	ld	a,(ix+10)
	and	0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00105
;source-doc/base-drv/./transfers.c:117: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00105:
;source-doc/base-drv/./transfers.c:119: if (((uint16_t)buffer_size & 0xC000) == 0)
	ld	a,(ix+7)
	and	0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00107
;source-doc/base-drv/./transfers.c:120: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00107:
;source-doc/base-drv/./transfers.c:122: return usb_data_in_transfer_n(buffer, buffer_size, device_address, endpoint);
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	l,(ix+9)
	ld	h,(ix+10)
	push	hl
	ld	a,(ix+8)
	push	af
	inc	sp
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_data_in_transfer_n
	pop	af
	pop	af
	pop	af
	inc	sp
l_usb_dat_in_trns_n_ext_00108:
;source-doc/base-drv/./transfers.c:123: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:135: usb_data_in_transfer(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_data_in_transfer
; ---------------------------------
_usb_data_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:136: critical_begin();
	call	_critical_begin
;source-doc/base-drv/./transfers.c:138: ch_set_usb_address(device_address);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/./transfers.c:140: result = ch_data_in_transfer(buffer, buffer_size, endpoint);
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
;source-doc/base-drv/./transfers.c:142: critical_end();
	call	_critical_end
;source-doc/base-drv/./transfers.c:144: return result;
	ld	hl,_result
	ld	l, (hl)
;source-doc/base-drv/./transfers.c:145: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:157: usb_data_in_transfer_n(uint8_t *buffer, uint8_t *const buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_data_in_transfer_n
; ---------------------------------
_usb_data_in_transfer_n:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:158: critical_begin();
	call	_critical_begin
;source-doc/base-drv/./transfers.c:160: ch_set_usb_address(device_address);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/./transfers.c:162: result = ch_data_in_transfer_n(buffer, buffer_size, endpoint);
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
;source-doc/base-drv/./transfers.c:164: critical_end();
	call	_critical_end
;source-doc/base-drv/./transfers.c:166: return result;
	ld	hl,_result
	ld	l, (hl)
;source-doc/base-drv/./transfers.c:167: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:179: usb_data_out_transfer(const uint8_t *buffer, uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_data_out_transfer
; ---------------------------------
_usb_data_out_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:180: critical_begin();
	call	_critical_begin
;source-doc/base-drv/./transfers.c:182: ch_set_usb_address(device_address);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/./transfers.c:184: result = ch_data_out_transfer(buffer, buffer_size, endpoint);
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
;source-doc/base-drv/./transfers.c:186: critical_end();
	call	_critical_end
;source-doc/base-drv/./transfers.c:188: return result;
	ld	hl,_result
	ld	l, (hl)
;source-doc/base-drv/./transfers.c:189: }
	pop	ix
	ret
