;
; Generated from source-doc/base-drv/./ch376.c.asm -- not to be modify directly
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
	
_result:
	DEFS 1
	
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
;source-doc/base-drv/./ch376.c:8: void ch_command(const uint8_t command) __z88dk_fastcall {
; ---------------------------------
; Function ch_command
; ---------------------------------
_ch_command:
;source-doc/base-drv/./ch376.c:10: while ((CH376_COMMAND_PORT & PARA_STATE_BUSY) && --counter != 0)
	ld	c,0xff
l_ch_command_00102:
	ld	a, +((_CH376_COMMAND_PORT) / 256)
	in	a, (((_CH376_COMMAND_PORT) & 0xFF))
	bit	4, a
	jr	Z,l_ch_command_00104
	dec	c
	jr	NZ,l_ch_command_00102
l_ch_command_00104:
;source-doc/base-drv/./ch376.c:21: CH376_COMMAND_PORT = command;
	ld	a, l
	ld	bc,_CH376_COMMAND_PORT
	out	(c),a
;source-doc/base-drv/./ch376.c:22: }
	ret
;source-doc/base-drv/./ch376.c:26: usb_error ch_long_wait_int_and_get_status(void) { return ch_wait_int_and_get_status(5000); }
; ---------------------------------
; Function ch_long_wait_int_and_get_status
; ---------------------------------
_ch_long_wait_int_and_get_statu:
	ld	hl,0x1388
	jp	_ch_wait_int_and_get_status
;source-doc/base-drv/./ch376.c:28: usb_error ch_short_wait_int_and_get_statu(void) { return ch_wait_int_and_get_status(100); }
; ---------------------------------
; Function ch_short_wait_int_and_get_statu
; ---------------------------------
_ch_short_wait_int_and_get_stat:
	ld	hl,0x0064
	jp	_ch_wait_int_and_get_status
;source-doc/base-drv/./ch376.c:30: usb_error ch_very_short_wait_int_and_get_(void) { return ch_wait_int_and_get_status(10); }
; ---------------------------------
; Function ch_very_short_wait_int_and_get_
; ---------------------------------
_ch_very_short_wait_int_and_get:
	ld	hl,0x000a
	jp	_ch_wait_int_and_get_status
;source-doc/base-drv/./ch376.c:32: usb_error ch_get_status(void) {
; ---------------------------------
; Function ch_get_status
; ---------------------------------
_ch_get_status:
;source-doc/base-drv/./ch376.c:33: ch_command(CH_CMD_GET_STATUS);
	ld	l,0x22
	call	_ch_command
;source-doc/base-drv/./ch376.c:34: uint8_t ch_status = CH376_DATA_PORT;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & 0xFF))
;source-doc/base-drv/./ch376.c:36: if (ch_status >= USB_FILERR_MIN && ch_status <= USB_FILERR_MAX)
	ld	l,a
	sub	0x41
	jr	C,l_ch_get_status_00102
	ld	a,0xb4
	sub	l
;source-doc/base-drv/./ch376.c:37: return ch_status;
	jr	NC,l_ch_get_status_00126
l_ch_get_status_00102:
;source-doc/base-drv/./ch376.c:39: if (ch_status == CH_CMD_RET_SUCCESS)
	ld	a, l
;source-doc/base-drv/./ch376.c:40: return USB_ERR_OK;
	sub	0x51
	jr	NZ,l_ch_get_status_00105
	ld	l,a
	jr	l_ch_get_status_00126
l_ch_get_status_00105:
;source-doc/base-drv/./ch376.c:42: if (ch_status == CH_USB_INT_SUCCESS)
	ld	a, l
;source-doc/base-drv/./ch376.c:43: return USB_ERR_OK;
	sub	0x14
	jr	NZ,l_ch_get_status_00107
	ld	l,a
	jr	l_ch_get_status_00126
l_ch_get_status_00107:
;source-doc/base-drv/./ch376.c:45: if (ch_status == CH_USB_INT_CONNECT)
	ld	a, l
	sub	0x15
	jr	NZ,l_ch_get_status_00109
;source-doc/base-drv/./ch376.c:46: return USB_INT_CONNECT;
	ld	l,0x81
	jr	l_ch_get_status_00126
l_ch_get_status_00109:
;source-doc/base-drv/./ch376.c:48: if (ch_status == CH_USB_INT_DISK_READ)
	ld	a, l
	sub	0x1d
	jr	NZ,l_ch_get_status_00111
;source-doc/base-drv/./ch376.c:49: return USB_ERR_DISK_READ;
	ld	l,0x1d
	jr	l_ch_get_status_00126
l_ch_get_status_00111:
;source-doc/base-drv/./ch376.c:51: if (ch_status == CH_USB_INT_DISK_WRITE)
	ld	a, l
	sub	0x1e
	jr	NZ,l_ch_get_status_00113
;source-doc/base-drv/./ch376.c:52: return USB_ERR_DISK_WRITE;
	ld	l,0x1e
	jr	l_ch_get_status_00126
l_ch_get_status_00113:
;source-doc/base-drv/./ch376.c:54: if (ch_status == CH_USB_INT_DISCONNECT) {
	ld	a, l
	sub	0x16
	jr	NZ,l_ch_get_status_00115
;source-doc/base-drv/./ch376.c:55: ch_cmd_set_usb_mode(5);
	ld	l,0x05
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/./ch376.c:56: return USB_ERR_NO_DEVICE;
	ld	l,0x05
	jr	l_ch_get_status_00126
l_ch_get_status_00115:
;source-doc/base-drv/./ch376.c:59: if (ch_status == CH_USB_INT_BUF_OVER)
	ld	a, l
	sub	0x17
	jr	NZ,l_ch_get_status_00117
;source-doc/base-drv/./ch376.c:60: return USB_ERR_DATA_ERROR;
	ld	l,0x04
	jr	l_ch_get_status_00126
l_ch_get_status_00117:
;source-doc/base-drv/./ch376.c:62: ch_status &= 0x2F;
	ld	a, l
	and	0x2f
;source-doc/base-drv/./ch376.c:64: if (ch_status == 0x2A)
	cp	0x2a
	jr	NZ,l_ch_get_status_00119
;source-doc/base-drv/./ch376.c:65: return USB_ERR_NAK;
	ld	l,0x01
	jr	l_ch_get_status_00126
l_ch_get_status_00119:
;source-doc/base-drv/./ch376.c:67: if (ch_status == 0x2E)
	cp	0x2e
	jr	NZ,l_ch_get_status_00121
;source-doc/base-drv/./ch376.c:68: return USB_ERR_STALL;
	ld	l,0x02
	jr	l_ch_get_status_00126
l_ch_get_status_00121:
;source-doc/base-drv/./ch376.c:70: ch_status &= 0x23;
	and	0x23
;source-doc/base-drv/./ch376.c:72: if (ch_status == 0x20)
	cp	0x20
	jr	NZ,l_ch_get_status_00123
;source-doc/base-drv/./ch376.c:73: return USB_ERR_TIMEOUT;
	ld	l,0x03
	jr	l_ch_get_status_00126
l_ch_get_status_00123:
;source-doc/base-drv/./ch376.c:75: if (ch_status == 0x23)
	sub	0x23
	jr	NZ,l_ch_get_status_00125
;source-doc/base-drv/./ch376.c:76: return USB_TOKEN_OUT_OF_SYNC;
	ld	l,0x07
	jr	l_ch_get_status_00126
l_ch_get_status_00125:
;source-doc/base-drv/./ch376.c:78: return USB_ERR_UNEXPECTED_STATUS_FROM_;
	ld	l,0x08
l_ch_get_status_00126:
;source-doc/base-drv/./ch376.c:79: }
	ret
;source-doc/base-drv/./ch376.c:81: void ch_cmd_reset_all(void) { ch_command(CH_CMD_RESET_ALL); }
; ---------------------------------
; Function ch_cmd_reset_all
; ---------------------------------
_ch_cmd_reset_all:
	ld	l,0x05
	jp	_ch_command
;source-doc/base-drv/./ch376.c:100: uint8_t ch_probe(void) {
; ---------------------------------
; Function ch_probe
; ---------------------------------
_ch_probe:
;source-doc/base-drv/./ch376.c:102: do {
	ld	c,0x05
l_ch_probe_00103:
;source-doc/base-drv/./ch376.c:85: ch_command(CH_CMD_CHECK_EXIST);
	push	bc
	ld	l,0x06
	call	_ch_command
	pop	bc
;source-doc/base-drv/./ch376.c:86: CH376_DATA_PORT = (uint8_t)~0x55;
	ld	a,0xaa
	push	bc
	ld	bc,_CH376_DATA_PORT
	out	(c),a
	call	_delay
	pop	bc
;source-doc/base-drv/./ch376.c:88: complement = CH376_DATA_PORT;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & 0xFF))
;source-doc/base-drv/./ch376.c:89: return complement == 0x55;
	sub	0x55
	jr	NZ,l_ch_probe_00102
;source-doc/base-drv/./ch376.c:103: if (ch_cmd_check_exist())
;source-doc/base-drv/./ch376.c:104: return true;
	ld	l,0x01
	jr	l_ch_probe_00107
l_ch_probe_00102:
;source-doc/base-drv/./ch376.c:106: delay_medium();
	push	bc
	call	_delay_medium
	pop	bc
;source-doc/base-drv/./ch376.c:107: } while (--i != 0);
	dec	c
	jr	NZ,l_ch_probe_00103
;source-doc/base-drv/./ch376.c:109: return false;
	ld	l,0x00
l_ch_probe_00107:
;source-doc/base-drv/./ch376.c:110: }
	ret
;source-doc/base-drv/./ch376.c:112: uint8_t ch_cmd_set_usb_mode(const uint8_t mode) __z88dk_fastcall {
; ---------------------------------
; Function ch_cmd_set_usb_mode
; ---------------------------------
_ch_cmd_set_usb_mode:
	ld	c, l
;source-doc/base-drv/./ch376.c:113: uint8_t result = 0;
	ld	b,0x00
;source-doc/base-drv/./ch376.c:115: CH376_COMMAND_PORT = CH_CMD_SET_USB_MODE;
	ld	a,0x15
	push	bc
	ld	bc,_CH376_COMMAND_PORT
	out	(c),a
	call	_delay
	pop	bc
;source-doc/base-drv/./ch376.c:117: CH376_DATA_PORT = mode;
	ld	a, c
	push	bc
	ld	bc,_CH376_DATA_PORT
	out	(c),a
	call	_delay
	pop	bc
;source-doc/base-drv/./ch376.c:122: while (result != CH_CMD_RET_SUCCESS && result != CH_CMD_RET_ABORT && --count != 0) {
	ld	c,0x7f
l_ch_cmd_set_usb_mode_00103:
	ld	a, b
	sub	0x51
	jr	NZ,l_ch_cmd_set_usb_mode_00146
	ld	a,0x01
	jr	l_ch_cmd_set_usb_mode_00147
l_ch_cmd_set_usb_mode_00146:
	xor	a
l_ch_cmd_set_usb_mode_00147:
	ld	e, a
	bit	0, e
	jr	NZ,l_ch_cmd_set_usb_mode_00105
	ld	a, b
	sub	0x5f
	jr	Z,l_ch_cmd_set_usb_mode_00105
	dec	c
	jr	Z,l_ch_cmd_set_usb_mode_00105
;source-doc/base-drv/./ch376.c:123: result = CH376_DATA_PORT;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & 0xFF))
	ld	b, a
;source-doc/base-drv/./ch376.c:124: delay();
	push	bc
	call	_delay
	pop	bc
	jr	l_ch_cmd_set_usb_mode_00103
l_ch_cmd_set_usb_mode_00105:
;source-doc/base-drv/./ch376.c:127: return (result == CH_CMD_RET_SUCCESS) ? USB_ERR_OK : USB_ERR_FAIL;
	ld	a, e
	or	a
	jr	Z,l_ch_cmd_set_usb_mode_00108
	ld	l,0x00
	jr	l_ch_cmd_set_usb_mode_00109
l_ch_cmd_set_usb_mode_00108:
	ld	l,0x0e
l_ch_cmd_set_usb_mode_00109:
;source-doc/base-drv/./ch376.c:128: }
	ret
;source-doc/base-drv/./ch376.c:130: uint8_t ch_cmd_get_ic_version(void) {
; ---------------------------------
; Function ch_cmd_get_ic_version
; ---------------------------------
_ch_cmd_get_ic_version:
;source-doc/base-drv/./ch376.c:131: ch_command(CH_CMD_GET_IC_VER);
	ld	l,0x01
	call	_ch_command
;source-doc/base-drv/./ch376.c:132: return CH376_DATA_PORT & 0x1f;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & 0xFF))
	and	0x1f
	ld	l, a
;source-doc/base-drv/./ch376.c:133: }
	ret
;source-doc/base-drv/./ch376.c:135: void ch_issue_token(const uint8_t toggle_bit, const uint8_t endpoint, const ch376_pid pid) {
; ---------------------------------
; Function ch_issue_token
; ---------------------------------
_ch_issue_token:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./ch376.c:136: ch_command(CH_CMD_ISSUE_TKN_X);
	ld	l,0x4e
	call	_ch_command
;source-doc/base-drv/./ch376.c:137: CH376_DATA_PORT = toggle_bit;
	ld	a,(ix+4)
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/./ch376.c:138: CH376_DATA_PORT = endpoint << 4 | pid;
	ld	a,(ix+5)
	add	a, a
	add	a, a
	add	a, a
	add	a, a
	or	(ix+6)
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/./ch376.c:139: }
	pop	ix
	ret
;source-doc/base-drv/./ch376.c:141: void ch_issue_token_in(const endpoint_param *const endpoint) __z88dk_fastcall {
; ---------------------------------
; Function ch_issue_token_in
; ---------------------------------
_ch_issue_token_in:
	ex	de, hl
;source-doc/base-drv/./ch376.c:142: ch_issue_token(endpoint->toggle ? 0x80 : 0x00, endpoint->number, CH_PID_IN);
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	0x07
	ld	b, a
	ex	de, hl
	ld	a, (hl)
	and	0x01
	jr	Z,l_ch_issue_token_in_00103
	ld	a,0x80
	jr	l_ch_issue_token_in_00104
l_ch_issue_token_in_00103:
	xor	a
l_ch_issue_token_in_00104:
	ld	h,0x09
	push	hl
	inc	sp
	push	bc
	inc	sp
	push	af
	inc	sp
	call	_ch_issue_token
	pop	af
	inc	sp
;source-doc/base-drv/./ch376.c:143: }
	ret
;source-doc/base-drv/./ch376.c:145: void ch_issue_token_out(const endpoint_param *const endpoint) __z88dk_fastcall {
; ---------------------------------
; Function ch_issue_token_out
; ---------------------------------
_ch_issue_token_out:
	ex	de, hl
;source-doc/base-drv/./ch376.c:146: ch_issue_token(endpoint->toggle ? 0x40 : 0x00, endpoint->number, CH_PID_OUT);
	ld	l, e
	ld	h, d
	ld	a, (hl)
	rrca
	and	0x07
	ld	b, a
	ex	de, hl
	ld	a, (hl)
	and	0x01
	jr	Z,l_ch_issue_token_out_00103
	ld	a,0x40
	jr	l_ch_issue_token_out_00104
l_ch_issue_token_out_00103:
	xor	a
l_ch_issue_token_out_00104:
	ld	h,0x01
	push	hl
	inc	sp
	push	bc
	inc	sp
	push	af
	inc	sp
	call	_ch_issue_token
	pop	af
	inc	sp
;source-doc/base-drv/./ch376.c:147: }
	ret
;source-doc/base-drv/./ch376.c:149: void ch_issue_token_out_ep0(void) { ch_issue_token(0x40, 0, CH_PID_OUT); }
; ---------------------------------
; Function ch_issue_token_out_ep0
; ---------------------------------
_ch_issue_token_out_ep0:
	ld	a,0x01
	push	af
	inc	sp
	xor	a
	ld	d,a
	ld	e,0x40
	push	de
	call	_ch_issue_token
	pop	af
	inc	sp
	ret
;source-doc/base-drv/./ch376.c:151: void ch_issue_token_in_ep0(void) { ch_issue_token(0x80, 0, CH_PID_IN); }
; ---------------------------------
; Function ch_issue_token_in_ep0
; ---------------------------------
_ch_issue_token_in_ep0:
	ld	a,0x09
	push	af
	inc	sp
	xor	a
	ld	d,a
	ld	e,0x80
	push	de
	call	_ch_issue_token
	pop	af
	inc	sp
	ret
;source-doc/base-drv/./ch376.c:153: void ch_issue_token_setup(void) { ch_issue_token(0, 0, CH_PID_SETUP); }
; ---------------------------------
; Function ch_issue_token_setup
; ---------------------------------
_ch_issue_token_setup:
	ld	a,0x0d
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	xor	a
	push	af
	inc	sp
	call	_ch_issue_token
	pop	af
	inc	sp
	ret
;source-doc/base-drv/./ch376.c:155: usb_error ch_data_in_transfer(uint8_t *buffer, int16_t buffer_size, endpoint_param *const endpoint) {
; ---------------------------------
; Function ch_data_in_transfer
; ---------------------------------
_ch_data_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/./ch376.c:158: if (buffer_size == 0)
	ld	a,(ix+7)
	or	(ix+6)
	jr	NZ,l_ch_data_in_transfer_00102
;source-doc/base-drv/./ch376.c:159: return USB_ERR_OK;
	ld	l,0x00
	jp	l_ch_data_in_transfer_00111
l_ch_data_in_transfer_00102:
;source-doc/base-drv/./ch376.c:161: USB_MODULE_LEDS = 0x01;
	ld	a,0x01
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/./ch376.c:162: do {
	ld	c,(ix+8)
	ld	b,(ix+9)
	inc	sp
	inc	sp
	push	bc
l_ch_data_in_transfer_00107:
;source-doc/base-drv/./ch376.c:163: ch_issue_token_in(endpoint);
	push	bc
	ld	l, c
	ld	h, b
	call	_ch_issue_token_in
	call	_ch_long_wait_int_and_get_statu
	pop	bc
	ld	a, l
	ld	(_result), a
;source-doc/base-drv/./ch376.c:166: CHECK(result);
	ld	a,(_result)
	or	a
	jr	NZ,l_ch_data_in_transfer_00110
;source-doc/base-drv/./ch376.c:168: endpoint->toggle = !endpoint->toggle;
	ld	e, c
	ld	d, b
	pop	hl
	push	hl
	ld	a, (hl)
	and	0x01
	xor	0x01
	and	0x01
	ld	l, a
	ld	a, (de)
	and	0xfe
	or	l
	ld	(de), a
;source-doc/base-drv/./ch376.c:170: count = ch_read_data(buffer);
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	call	_ch_read_data
	ld	e, a
	pop	bc
;source-doc/base-drv/./ch376.c:172: if (count == 0) {
	ld	a, e
;source-doc/base-drv/./ch376.c:173: USB_MODULE_LEDS = 0x00;
	or	a
	jr	NZ,l_ch_data_in_transfer_00106
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/./ch376.c:174: return USB_ERR_DATA_ERROR;
	ld	l,0x04
	jr	l_ch_data_in_transfer_00111
l_ch_data_in_transfer_00106:
;source-doc/base-drv/./ch376.c:177: buffer += count;
	ld	a,(ix+4)
	add	a, e
	ld	(ix+4),a
	jr	NC,l_ch_data_in_transfer_00148
	inc	(ix+5)
l_ch_data_in_transfer_00148:
;source-doc/base-drv/./ch376.c:178: buffer_size -= count;
	ld	d,0x00
	ld	a,(ix+6)
	sub	e
	ld	(ix+6),a
	ld	a,(ix+7)
	sbc	a, d
	ld	(ix+7),a
;source-doc/base-drv/./ch376.c:179: } while (buffer_size > 0);
	xor	a
	cp	(ix+6)
	sbc	a,(ix+7)
	jp	PO, l_ch_data_in_transfer_00149
	xor	0x80
l_ch_data_in_transfer_00149:
	jp	M, l_ch_data_in_transfer_00107
;source-doc/base-drv/./ch376.c:181: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/./ch376.c:183: return USB_ERR_OK;
	ld	l,0x00
	jr	l_ch_data_in_transfer_00111
;source-doc/base-drv/./ch376.c:184: done:
l_ch_data_in_transfer_00110:
;source-doc/base-drv/./ch376.c:185: return result;
	ld	hl,_result
	ld	l, (hl)
l_ch_data_in_transfer_00111:
;source-doc/base-drv/./ch376.c:186: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./ch376.c:188: usb_error ch_data_in_transfer_n(uint8_t *const buffer, int8_t *const buffer_size, endpoint_param *const endpoint) {
; ---------------------------------
; Function ch_data_in_transfer_n
; ---------------------------------
_ch_data_in_transfer_n:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/./ch376.c:192: USB_MODULE_LEDS = 0x01;
	ld	a,0x01
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/./ch376.c:194: ch_issue_token_in(endpoint);
	ld	l,(ix+8)
	ld	h,(ix+9)
	call	_ch_issue_token_in
;source-doc/base-drv/./ch376.c:196: CHECK(ch_long_wait_int_and_get_status());
	call	_ch_long_wait_int_and_get_statu
	ld	a, l
	ld	b,a
	or	a
	jr	NZ,l_ch_data_in_transfer_n_00103
;source-doc/base-drv/./ch376.c:198: endpoint->toggle = !endpoint->toggle;
	ld	e,(ix+8)
	ld	d,(ix+9)
	ld	c, e
	ld	b, d
	ex	de, hl
	ld	a, (hl)
	and	0x01
	xor	0x01
	and	0x01
	ld	e, a
	ld	a, (bc)
	and	0xfe
	or	e
	ld	(bc), a
;source-doc/base-drv/./ch376.c:200: count = ch_read_data(buffer);
	ld	l,(ix+4)
	ld	h,(ix+5)
	call	_ch_read_data
;source-doc/base-drv/./ch376.c:202: *buffer_size = count;
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	(bc), a
;source-doc/base-drv/./ch376.c:204: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/./ch376.c:206: return USB_ERR_OK;
	ld	l,0x00
	jr	l_ch_data_in_transfer_n_00104
;source-doc/base-drv/./ch376.c:207: done:
l_ch_data_in_transfer_n_00103:
;source-doc/base-drv/./ch376.c:208: return result;
	ld	l, b
l_ch_data_in_transfer_n_00104:
;source-doc/base-drv/./ch376.c:209: }
	pop	ix
	ret
;source-doc/base-drv/./ch376.c:211: usb_error ch_data_out_transfer(const uint8_t *buffer, int16_t buffer_length, endpoint_param *const endpoint) {
; ---------------------------------
; Function ch_data_out_transfer
; ---------------------------------
_ch_data_out_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	dec	sp
;source-doc/base-drv/./ch376.c:214: const uint8_t max_packet_size = calc_max_packet_size(endpoint->max_packet_sizex);
	ld	c,(ix+8)
	ld	b,(ix+9)
	ld	e, c
	ld	d, b
	inc	de
	ld	a, (de)
	ld	(ix-3),a
;source-doc/base-drv/./ch376.c:216: USB_MODULE_LEDS = 0x02;
	ld	a,0x02
	push	bc
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
	pop	bc
;source-doc/base-drv/./ch376.c:218: while (buffer_length > 0) {
	ld	(ix-2),c
	ld	(ix-1),b
l_ch_data_out_transfer_00103:
	xor	a
	cp	(ix+6)
	sbc	a,(ix+7)
	jp	PO, l_ch_data_out_transfer_00139
	xor	0x80
l_ch_data_out_transfer_00139:
	jp	P, l_ch_data_out_transfer_00105
;source-doc/base-drv/./ch376.c:219: const uint8_t size = max_packet_size < buffer_length ? max_packet_size : buffer_length;
	ld	d,(ix-3)
	ld	e,0x00
	ld	a, d
	sub	(ix+6)
	ld	a, e
	sbc	a,(ix+7)
	jp	PO, l_ch_data_out_transfer_00140
	xor	0x80
l_ch_data_out_transfer_00140:
	jp	P, l_ch_data_out_transfer_00109
	jr	l_ch_data_out_transfer_00110
l_ch_data_out_transfer_00109:
	ld	d,(ix+6)
l_ch_data_out_transfer_00110:
;source-doc/base-drv/./ch376.c:220: buffer             = ch_write_data(buffer, size);
	push	bc
	push	de
	push	de
	inc	sp
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ch_write_data
	pop	af
	inc	sp
	pop	de
	pop	bc
	ld	(ix+4),l
	ld	(ix+5),h
;source-doc/base-drv/./ch376.c:221: buffer_length -= size;
	ld	e,0x00
	ld	a,(ix+6)
	sub	d
	ld	(ix+6),a
	ld	a,(ix+7)
	sbc	a, e
	ld	(ix+7),a
;source-doc/base-drv/./ch376.c:222: ch_issue_token_out(endpoint);
	push	bc
	ld	l, c
	ld	h, b
	call	_ch_issue_token_out
	call	_ch_long_wait_int_and_get_statu
	ld	a, l
	pop	bc
	ld	l, a
	or	a
	jr	NZ,l_ch_data_out_transfer_00106
;source-doc/base-drv/./ch376.c:226: endpoint->toggle = !endpoint->toggle;
	ld	e, c
	ld	d, b
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	a, (hl)
	and	0x01
	xor	0x01
	and	0x01
	ld	l, a
	ld	a, (de)
	and	0xfe
	or	l
	ld	(de), a
	jr	l_ch_data_out_transfer_00103
l_ch_data_out_transfer_00105:
;source-doc/base-drv/./ch376.c:229: USB_MODULE_LEDS = 0x00;
	ld	a,0x00
	ld	bc,_USB_MODULE_LEDS
	out	(c),a
;source-doc/base-drv/./ch376.c:231: return USB_ERR_OK;
	ld	l,0x00
;source-doc/base-drv/./ch376.c:232: done:
;source-doc/base-drv/./ch376.c:233: return result;
l_ch_data_out_transfer_00106:
;source-doc/base-drv/./ch376.c:234: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/./ch376.c:236: void ch_set_usb_address(const uint8_t device_address) __z88dk_fastcall {
; ---------------------------------
; Function ch_set_usb_address
; ---------------------------------
_ch_set_usb_address:
;source-doc/base-drv/./ch376.c:237: ch_command(CH_CMD_SET_USB_ADDR);
	push	hl
	ld	l,0x13
	call	_ch_command
	pop	hl
;source-doc/base-drv/./ch376.c:238: CH376_DATA_PORT = device_address;
	ld	a, l
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/./ch376.c:239: }
	ret
_result:
	DEFB +0x00
