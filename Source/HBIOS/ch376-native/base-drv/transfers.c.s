;
; Generated from source-doc/base-drv/./transfers.c.asm -- not to be modify directly
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
;source-doc/base-drv/./transfers.c:21: usb_error usb_ctrl_trnsfer_ext(const setup_packet *const cmd_packet,
; ---------------------------------
; Function usb_ctrl_trnsfer_ext
; ---------------------------------
_usb_ctrl_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:25: if ((uint16_t)cmd_packet < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00102
;source-doc/base-drv/./transfers.c:26: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00102:
;source-doc/base-drv/./transfers.c:28: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+7)
	or	(ix+6)
	jr	Z,l_usb_ctrl_trnsfer_ext_00104
	ld	a,(ix+7)
	sub	0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00104
;source-doc/base-drv/./transfers.c:29: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00104:
;source-doc/base-drv/./transfers.c:31: return usb_control_transfer(cmd_packet, buffer, device_address, max_packet_size);
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
;source-doc/base-drv/./transfers.c:32: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:44: usb_error usb_control_transfer(const setup_packet *const cmd_packet,
; ---------------------------------
; Function usb_control_transfer
; ---------------------------------
_usb_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/./transfers.c:49: endpoint_param endpoint = {1, 0, max_packet_size};
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
;source-doc/base-drv/./transfers.c:51: const uint8_t transferIn = (cmd_packet->bmRequestType & 0x80);
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	a, (bc)
	and	0x80
;source-doc/base-drv/./transfers.c:53: if (transferIn && buffer == 0)
	ld	(ix-1),a
	or	a
	jr	Z,l_usb_control_transfer_00102
	ld	a,(ix+7)
	or	(ix+6)
	jr	NZ,l_usb_control_transfer_00102
;source-doc/base-drv/./transfers.c:54: return USB_ERR_OTHER;
	ld	l,0x0f
	jp	l_usb_control_transfer_00113
l_usb_control_transfer_00102:
;source-doc/base-drv/./transfers.c:56: ch_set_usb_address(device_address);
	push	bc
	ld	l,(ix+8)
	call	_ch_set_usb_address
	pop	bc
;source-doc/base-drv/./transfers.c:58: ch_write_data((const uint8_t *)cmd_packet, sizeof(setup_packet));
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
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/./transfers.c:62: const uint16_t length = cmd_packet->wLength;
	ld	hl,6
	add	hl, bc
	ld	c, (hl)
	inc	hl
;source-doc/base-drv/./transfers.c:65: ? (transferIn ? ch_data_in_transfer(buffer, length, &endpoint) : ch_data_out_transfer(buffer, length, &endpoint))
	ld	a,(hl)
	ld	b,a
	or	c
	jr	Z,l_usb_control_transfer_00115
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00117
	ld	hl,0
	add	hl, sp
	push	hl
	push	bc
	push	de
	call	_ch_data_in_transfer
	pop	af
	pop	af
	pop	af
	jr	l_usb_control_transfer_00118
l_usb_control_transfer_00117:
	ld	hl,0
	add	hl, sp
	push	hl
	push	bc
	push	de
	call	_ch_data_out_transfer
	pop	af
	pop	af
	pop	af
l_usb_control_transfer_00118:
	jr	l_usb_control_transfer_00116
l_usb_control_transfer_00115:
;source-doc/base-drv/./transfers.c:66: : USB_ERR_OK;
	ld	hl,0x0000
l_usb_control_transfer_00116:
;source-doc/base-drv/./transfers.c:68: CHECK(result)
	ld	a, l
	or	a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/./transfers.c:70: if (transferIn) {
	ld	a,(ix-1)
	or	a
	jr	Z,l_usb_control_transfer_00112
;source-doc/base-drv/./transfers.c:71: ch_command(CH_CMD_WR_HOST_DATA);
	ld	l,0x2c
	call	_ch_command
;source-doc/base-drv/./transfers.c:72: CH376_DATA_PORT = 0;
	ld	a,0x00
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/./transfers.c:73: delay();
	call	_delay
;source-doc/base-drv/./transfers.c:74: ch_issue_token_out_ep0();
	call	_ch_issue_token_out_ep0
;source-doc/base-drv/./transfers.c:75: result = ch_long_wait_int_and_get_status(); /* sometimes we get STALL here - seems to be ok to ignore */
	call	_ch_long_wait_int_and_get_statu
	ld	a, l
;source-doc/base-drv/./transfers.c:77: if (result == USB_ERR_OK || result == USB_ERR_STALL)
	or	a
	jr	Z,l_usb_control_transfer_00108
	cp	0x02
	jr	NZ,l_usb_control_transfer_00109
l_usb_control_transfer_00108:
;source-doc/base-drv/./transfers.c:78: return USB_ERR_OK;
	ld	l,0x00
	jr	l_usb_control_transfer_00113
l_usb_control_transfer_00109:
;source-doc/base-drv/./transfers.c:80: RETURN_CHECK(result);
	ld	l, a
	jr	l_usb_control_transfer_00113
l_usb_control_transfer_00112:
;source-doc/base-drv/./transfers.c:83: ch_issue_token_in_ep0();
	call	_ch_issue_token_in_ep0
;source-doc/base-drv/./transfers.c:84: result = ch_long_wait_int_and_get_status();
	call	_ch_long_wait_int_and_get_statu
;source-doc/base-drv/./transfers.c:86: RETURN_CHECK(result);
l_usb_control_transfer_00113:
;source-doc/base-drv/./transfers.c:87: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:90: usb_dat_in_trnsfer_ext(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_dat_in_trnsfer_ext
; ---------------------------------
_usb_dat_in_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:91: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	or	(ix+4)
	jr	Z,l_usb_dat_in_trnsfer_ext_00102
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00102
;source-doc/base-drv/./transfers.c:92: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00102:
;source-doc/base-drv/./transfers.c:94: if ((uint16_t)endpoint < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+10)
	sub	0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00105
;source-doc/base-drv/./transfers.c:95: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00105:
;source-doc/base-drv/./transfers.c:97: return usb_data_in_transfer(buffer, buffer_size, device_address, endpoint);
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
;source-doc/base-drv/./transfers.c:98: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:101: usb_dat_in_trns_n_ext(uint8_t *buffer, uint16_t *buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_dat_in_trns_n_ext
; ---------------------------------
_usb_dat_in_trns_n_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:102: if (buffer != 0 && ((uint16_t)buffer & 0xC000) == 0)
	ld	a,(ix+5)
	or	(ix+4)
	jr	Z,l_usb_dat_in_trns_n_ext_00102
	ld	a,(ix+5)
	and	0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00102
;source-doc/base-drv/./transfers.c:103: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00102:
;source-doc/base-drv/./transfers.c:105: if (((uint16_t)endpoint & 0xC000) == 0)
	ld	a,(ix+10)
	and	0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00105
;source-doc/base-drv/./transfers.c:106: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00105:
;source-doc/base-drv/./transfers.c:108: if (((uint16_t)buffer_size & 0xC000) == 0)
	ld	a,(ix+7)
	and	0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00107
;source-doc/base-drv/./transfers.c:109: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00107:
;source-doc/base-drv/./transfers.c:111: return usb_data_in_transfer_n(buffer, buffer_size, device_address, endpoint);
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
;source-doc/base-drv/./transfers.c:112: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:124: usb_data_in_transfer(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_data_in_transfer
; ---------------------------------
_usb_data_in_transfer:
;source-doc/base-drv/./transfers.c:125: ch_set_usb_address(device_address);
	ld	iy,6
	add	iy, sp
	ld	l,(iy+0)
	call	_ch_set_usb_address
;source-doc/base-drv/./transfers.c:127: return ch_data_in_transfer(buffer, buffer_size, endpoint);
	ld	iy,7
	add	iy, sp
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	dec	iy
	dec	iy
	dec	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	dec	iy
	dec	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	call	_ch_data_in_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/./transfers.c:128: }
	ret
;source-doc/base-drv/./transfers.c:140: usb_data_in_transfer_n(uint8_t *buffer, uint8_t *const buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_data_in_transfer_n
; ---------------------------------
_usb_data_in_transfer_n:
;source-doc/base-drv/./transfers.c:141: ch_set_usb_address(device_address);
	ld	iy,6
	add	iy, sp
	ld	l,(iy+0)
	call	_ch_set_usb_address
;source-doc/base-drv/./transfers.c:143: return ch_data_in_transfer_n(buffer, buffer_size, endpoint);
	ld	iy,7
	add	iy, sp
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	dec	iy
	dec	iy
	dec	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	dec	iy
	dec	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	call	_ch_data_in_transfer_n
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/./transfers.c:144: }
	ret
;source-doc/base-drv/./transfers.c:147: usb_dat_out_trns_ext(const uint8_t *buffer, uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_dat_out_trns_ext
; ---------------------------------
_usb_dat_out_trns_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./transfers.c:149: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	or	(ix+4)
	jr	Z,l_usb_dat_out_trns_ext_00102
	ld	a,(ix+5)
	sub	0x80
	jr	NC,l_usb_dat_out_trns_ext_00102
;source-doc/base-drv/./transfers.c:150: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_out_trns_ext_00106
l_usb_dat_out_trns_ext_00102:
;source-doc/base-drv/./transfers.c:152: if ((uint16_t)endpoint < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+10)
	sub	0x80
	jr	NC,l_usb_dat_out_trns_ext_00105
;source-doc/base-drv/./transfers.c:153: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_out_trns_ext_00106
l_usb_dat_out_trns_ext_00105:
;source-doc/base-drv/./transfers.c:155: return usb_data_out_transfer(buffer, buffer_size, device_address, endpoint);
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
	call	_usb_data_out_transfer
	pop	af
	pop	af
	pop	af
	inc	sp
l_usb_dat_out_trns_ext_00106:
;source-doc/base-drv/./transfers.c:156: }
	pop	ix
	ret
;source-doc/base-drv/./transfers.c:168: usb_data_out_transfer(const uint8_t *buffer, uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
; ---------------------------------
; Function usb_data_out_transfer
; ---------------------------------
_usb_data_out_transfer:
;source-doc/base-drv/./transfers.c:169: ch_set_usb_address(device_address);
	ld	iy,6
	add	iy, sp
	ld	l,(iy+0)
	call	_ch_set_usb_address
;source-doc/base-drv/./transfers.c:171: return ch_data_out_transfer(buffer, buffer_size, endpoint);
	ld	iy,7
	add	iy, sp
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	dec	iy
	dec	iy
	dec	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	dec	iy
	dec	iy
	ld	l,(iy+0)
	ld	h,(iy+1)
	push	hl
	call	_ch_data_out_transfer
	pop	af
	pop	af
	pop	af
;source-doc/base-drv/./transfers.c:172: }
	ret
