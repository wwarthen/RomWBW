;
; Generated from source-doc/base-drv/ch376.c.asm -- not to be modify directly
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
;source-doc/base-drv/ch376.c:6: void ch_command(const uint8_t command) __z88dk_fastcall {
; ---------------------------------
; Function ch_command
; ---------------------------------
_ch_command:
;source-doc/base-drv/ch376.c:8: while ((CH376_COMMAND_PORT & PARA_STATE_BUSY) && --counter != 0)
	ld	b,$ff
l_ch_command_00102:
	ld	a, +((_CH376_COMMAND_PORT) / 256)
	in	a, (((_CH376_COMMAND_PORT) & $FF))
	bit	4, a
	jr	Z,l_ch_command_00104
	djnz	l_ch_command_00102
l_ch_command_00104:
;source-doc/base-drv/ch376.c:19: CH376_COMMAND_PORT = command;
	ld	a, l
	ld	bc,_CH376_COMMAND_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:20: }
	ret
;source-doc/base-drv/ch376.c:24: usb_error ch_long_get_status(void) { return ch_wait_and_get_status(5000); }
; ---------------------------------
; Function ch_long_get_status
; ---------------------------------
_ch_long_get_status:
	ld	hl,$1388
	jp	_ch_wait_and_get_status
;source-doc/base-drv/ch376.c:26: usb_error ch_short_get_status(void) { return ch_wait_and_get_status(100); }
; ---------------------------------
; Function ch_short_get_status
; ---------------------------------
_ch_short_get_status:
	ld	hl,$0064
	jp	_ch_wait_and_get_status
;source-doc/base-drv/ch376.c:28: usb_error ch_very_short_status(void) { return ch_wait_and_get_status(10); }
; ---------------------------------
; Function ch_very_short_status
; ---------------------------------
_ch_very_short_status:
	ld	hl,$000a
	jp	_ch_wait_and_get_status
;source-doc/base-drv/ch376.c:30: usb_error ch_get_status(void) {
; ---------------------------------
; Function ch_get_status
; ---------------------------------
_ch_get_status:
;source-doc/base-drv/ch376.c:31: ch_command(CH_CMD_GET_STATUS);
	ld	l,$22
	call	_ch_command
;source-doc/base-drv/ch376.c:32: uint8_t ch_status = CH376_DATA_PORT;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & $FF))
;source-doc/base-drv/ch376.c:34: if (ch_status >= USB_FILERR_MIN && ch_status <= USB_FILERR_MAX)
	cp	$41
	jr	C,l_ch_get_status_00102
	cp	$b5
	jr	NC,l_ch_get_status_00102
;source-doc/base-drv/ch376.c:35: return ch_status;
	ld	l, a
	jr	l_ch_get_status_00126
l_ch_get_status_00102:
;source-doc/base-drv/ch376.c:37: if (ch_status == CH_CMD_RET_SUCCESS)
	cp	$51
	jr	NZ,l_ch_get_status_00105
;source-doc/base-drv/ch376.c:38: return USB_ERR_OK;
	ld	l,$00
	jr	l_ch_get_status_00126
l_ch_get_status_00105:
;source-doc/base-drv/ch376.c:40: if (ch_status == CH_USB_INT_SUCCESS)
	cp	$14
	jr	NZ,l_ch_get_status_00107
;source-doc/base-drv/ch376.c:41: return USB_ERR_OK;
	ld	l,$00
	jr	l_ch_get_status_00126
l_ch_get_status_00107:
;source-doc/base-drv/ch376.c:43: if (ch_status == CH_USB_INT_CONNECT)
	cp	$15
	jr	NZ,l_ch_get_status_00109
;source-doc/base-drv/ch376.c:44: return USB_INT_CONNECT;
	ld	l,$81
	jr	l_ch_get_status_00126
l_ch_get_status_00109:
;source-doc/base-drv/ch376.c:46: if (ch_status == CH_USB_INT_DISK_READ)
	cp	$1d
	jr	NZ,l_ch_get_status_00111
;source-doc/base-drv/ch376.c:47: return USB_ERR_DISK_READ;
	ld	l,$1d
	jr	l_ch_get_status_00126
l_ch_get_status_00111:
;source-doc/base-drv/ch376.c:49: if (ch_status == CH_USB_INT_DISK_WRITE)
	cp	$1e
	jr	NZ,l_ch_get_status_00113
;source-doc/base-drv/ch376.c:50: return USB_ERR_DISK_WRITE;
	ld	l,$1e
	jr	l_ch_get_status_00126
l_ch_get_status_00113:
;source-doc/base-drv/ch376.c:52: if (ch_status == CH_USB_INT_DISCONNECT) {
	cp	$16
	jr	NZ,l_ch_get_status_00115
;source-doc/base-drv/ch376.c:53: ch_cmd_set_usb_mode(5);
	ld	l,$05
	call	_ch_cmd_set_usb_mode
;source-doc/base-drv/ch376.c:54: return USB_ERR_NO_DEVICE;
	ld	l,$05
	jr	l_ch_get_status_00126
l_ch_get_status_00115:
;source-doc/base-drv/ch376.c:57: if (ch_status == CH_USB_INT_BUF_OVER)
	cp	$17
	jr	NZ,l_ch_get_status_00117
;source-doc/base-drv/ch376.c:58: return USB_ERR_DATA_ERROR;
	ld	l,$04
	jr	l_ch_get_status_00126
l_ch_get_status_00117:
;source-doc/base-drv/ch376.c:60: ch_status &= $2F;
	and	$2f
;source-doc/base-drv/ch376.c:62: if (ch_status == $2A)
	cp	$2a
	jr	NZ,l_ch_get_status_00119
;source-doc/base-drv/ch376.c:63: return USB_ERR_NAK;
	ld	l,$01
	jr	l_ch_get_status_00126
l_ch_get_status_00119:
;source-doc/base-drv/ch376.c:65: if (ch_status == $2E)
	cp	$2e
	jr	NZ,l_ch_get_status_00121
;source-doc/base-drv/ch376.c:66: return USB_ERR_STALL;
	ld	l,$02
	jr	l_ch_get_status_00126
l_ch_get_status_00121:
;source-doc/base-drv/ch376.c:68: ch_status &= $23;
	and	$23
;source-doc/base-drv/ch376.c:70: if (ch_status == $20)
	cp	$20
	jr	NZ,l_ch_get_status_00123
;source-doc/base-drv/ch376.c:71: return USB_ERR_TIMEOUT;
	ld	l,$03
	jr	l_ch_get_status_00126
l_ch_get_status_00123:
;source-doc/base-drv/ch376.c:73: if (ch_status == $23)
	sub	$23
	jr	NZ,l_ch_get_status_00125
;source-doc/base-drv/ch376.c:74: return USB_TOKEN_OUT_OF_SYNC;
	ld	l,$07
	jr	l_ch_get_status_00126
l_ch_get_status_00125:
;source-doc/base-drv/ch376.c:76: return USB_ERR_UNEXPECTED_STATUS_FROM_;
	ld	l,$08
l_ch_get_status_00126:
;source-doc/base-drv/ch376.c:77: }
	ret
;source-doc/base-drv/ch376.c:79: void ch_cmd_reset_all(void) { ch_command(CH_CMD_RESET_ALL); }
; ---------------------------------
; Function ch_cmd_reset_all
; ---------------------------------
_ch_cmd_reset_all:
	ld	l,$05
	jp	_ch_command
;source-doc/base-drv/ch376.c:98: uint8_t ch_probe(void) {
; ---------------------------------
; Function ch_probe
; ---------------------------------
_ch_probe:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/ch376.c:100: do {
	ld	(ix-1),$05
l_ch_probe_00103:
;source-doc/base-drv/ch376.c:83: ch_command(CH_CMD_CHECK_EXIST);
	ld	l,$06
	call	_ch_command
;source-doc/base-drv/ch376.c:84: CH376_DATA_PORT = (uint8_t)~$55;
	ld	a,$aa
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:85: delay();
	call	_delay
;source-doc/base-drv/ch376.c:86: complement = CH376_DATA_PORT;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & $FF))
;source-doc/base-drv/ch376.c:87: return complement == $55;
	sub	$55
	jr	NZ,l_ch_probe_00102
;source-doc/base-drv/ch376.c:101: if (ch_cmd_check_exist())
;source-doc/base-drv/ch376.c:102: return true;
	ld	l,$01
	jr	l_ch_probe_00107
l_ch_probe_00102:
;source-doc/base-drv/ch376.c:104: delay_short();
	call	_delay_short
;source-doc/base-drv/ch376.c:105: } while (--i != 0);
	dec	(ix-1)
	jr	NZ,l_ch_probe_00103
;source-doc/base-drv/ch376.c:107: return false;
	ld	l,$00
l_ch_probe_00107:
;source-doc/base-drv/ch376.c:108: }
	inc	sp
	pop	ix
	ret
;source-doc/base-drv/ch376.c:110: usb_error ch_cmd_set_usb_mode(const uint8_t mode) __z88dk_fastcall {
; ---------------------------------
; Function ch_cmd_set_usb_mode
; ---------------------------------
_ch_cmd_set_usb_mode:
	ld	c, l
;source-doc/base-drv/ch376.c:111: uint8_t result = 0;
	ld	b,$00
;source-doc/base-drv/ch376.c:113: CH376_COMMAND_PORT = CH_CMD_SET_USB_MODE;
	ld	a,$15
	push	bc
	ld	bc,_CH376_COMMAND_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:114: delay();
	call	_delay
	pop	bc
;source-doc/base-drv/ch376.c:115: CH376_DATA_PORT = mode;
	ld	a, c
	push	bc
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:116: delay();
	call	_delay
	pop	bc
;source-doc/base-drv/ch376.c:120: while (result != CH_CMD_RET_SUCCESS && result != CH_CMD_RET_ABORT && --count != 0) {
	ld	c,$7f
l_ch_cmd_set_usb_mode_00103:
	ld	a, b
	sub	$51
	jr	NZ,l_ch_cmd_set_usb_mode_00146
	ld	a,$01
	jr	l_ch_cmd_set_usb_mode_00147
l_ch_cmd_set_usb_mode_00146:
	xor	a
l_ch_cmd_set_usb_mode_00147:
	ld	e,a
	bit	0,a
	jr	NZ,l_ch_cmd_set_usb_mode_00105
	ld	a, b
	sub	$5f
	jr	Z,l_ch_cmd_set_usb_mode_00105
	dec	c
	jr	Z,l_ch_cmd_set_usb_mode_00105
;source-doc/base-drv/ch376.c:121: result = CH376_DATA_PORT;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & $FF))
	ld	b, a
;source-doc/base-drv/ch376.c:122: delay();
	push	bc
	call	_delay
	pop	bc
	jr	l_ch_cmd_set_usb_mode_00103
l_ch_cmd_set_usb_mode_00105:
;source-doc/base-drv/ch376.c:125: return (result == CH_CMD_RET_SUCCESS) ? USB_ERR_OK : USB_ERR_FAIL;
	ld	a, e
	or	a
	jr	Z,l_ch_cmd_set_usb_mode_00108
	ld	l,$00
	jr	l_ch_cmd_set_usb_mode_00109
l_ch_cmd_set_usb_mode_00108:
	ld	l,$0e
l_ch_cmd_set_usb_mode_00109:
;source-doc/base-drv/ch376.c:126: }
	ret
;source-doc/base-drv/ch376.c:128: uint8_t ch_cmd_get_ic_version(void) {
; ---------------------------------
; Function ch_cmd_get_ic_version
; ---------------------------------
_ch_cmd_get_ic_version:
;source-doc/base-drv/ch376.c:129: ch_command(CH_CMD_GET_IC_VER);
	ld	l,$01
	call	_ch_command
;source-doc/base-drv/ch376.c:130: return CH376_DATA_PORT & $1f;
	ld	a, +((_CH376_DATA_PORT) / 256)
	in	a, (((_CH376_DATA_PORT) & $FF))
	and	$1f
	ld	l, a
;source-doc/base-drv/ch376.c:131: }
	ret
;source-doc/base-drv/ch376.c:133: void ch_issue_token(const uint8_t toggle_bit, const uint8_t endpoint, const ch376_pid pid) {
; ---------------------------------
; Function ch_issue_token
; ---------------------------------
_ch_issue_token:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/ch376.c:134: ch_command(CH_CMD_ISSUE_TKN_X);
	ld	l,$4e
	call	_ch_command
;source-doc/base-drv/ch376.c:135: CH376_DATA_PORT = toggle_bit;
	ld	a,(ix+4)
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:136: CH376_DATA_PORT = endpoint << 4 | pid;
	ld	a,(ix+5)
	add	a, a
	add	a, a
	add	a, a
	add	a, a
	or	(ix+6)
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:137: }
	pop	ix
	ret
;source-doc/base-drv/ch376.c:139: void ch_issue_token_in(const endpoint_param *const endpoint) __z88dk_fastcall {
; ---------------------------------
; Function ch_issue_token_in
; ---------------------------------
_ch_issue_token_in:
;source-doc/base-drv/ch376.c:140: ch_issue_token(endpoint->toggle ? $80 : $00, endpoint->number, CH_PID_IN);
	ld	e,l
	ld	d,h
	ld	a, (hl)
	rrca
	and	$07
	ld	b, a
	ex	de, hl
	ld	a, (hl)
	and	$01
	jr	Z,l_ch_issue_token_in_00103
	ld	a,$80
	jr	l_ch_issue_token_in_00104
l_ch_issue_token_in_00103:
	xor	a
l_ch_issue_token_in_00104:
	ld	h,$09
	ld	l,b
	push	hl
	push	af
	inc	sp
	call	_ch_issue_token
	pop	af
	inc	sp
;source-doc/base-drv/ch376.c:141: }
	ret
;source-doc/base-drv/ch376.c:143: void ch_issue_token_out(const endpoint_param *const endpoint) __z88dk_fastcall {
; ---------------------------------
; Function ch_issue_token_out
; ---------------------------------
_ch_issue_token_out:
;source-doc/base-drv/ch376.c:144: ch_issue_token(endpoint->toggle ? $40 : $00, endpoint->number, CH_PID_OUT);
	ld	e,l
	ld	d,h
	ld	a, (hl)
	rrca
	and	$07
	ld	b, a
	ex	de, hl
	ld	a, (hl)
	and	$01
	jr	Z,l_ch_issue_token_out_00103
	ld	a,$40
	jr	l_ch_issue_token_out_00104
l_ch_issue_token_out_00103:
	xor	a
l_ch_issue_token_out_00104:
	ld	h,$01
	ld	l,b
	push	hl
	push	af
	inc	sp
	call	_ch_issue_token
	pop	af
	inc	sp
;source-doc/base-drv/ch376.c:145: }
	ret
;source-doc/base-drv/ch376.c:147: void ch_issue_token_out_ep0(void) { ch_issue_token($40, 0, CH_PID_OUT); }
; ---------------------------------
; Function ch_issue_token_out_ep0
; ---------------------------------
_ch_issue_token_out_ep0:
	ld	a,$01
	push	af
	inc	sp
	xor	a
	ld	d,a
	ld	e,$40
	push	de
	call	_ch_issue_token
	pop	af
	inc	sp
	ret
;source-doc/base-drv/ch376.c:149: void ch_issue_token_in_ep0(void) { ch_issue_token($80, 0, CH_PID_IN); }
; ---------------------------------
; Function ch_issue_token_in_ep0
; ---------------------------------
_ch_issue_token_in_ep0:
	ld	a,$09
	push	af
	inc	sp
	xor	a
	ld	d,a
	ld	e,$80
	push	de
	call	_ch_issue_token
	pop	af
	inc	sp
	ret
;source-doc/base-drv/ch376.c:151: void ch_issue_token_setup(void) { ch_issue_token(0, 0, CH_PID_SETUP); }
; ---------------------------------
; Function ch_issue_token_setup
; ---------------------------------
_ch_issue_token_setup:
	ld	a,$0d
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
;source-doc/base-drv/ch376.c:153: usb_error ch_data_in_transfer(uint8_t *buffer, int16_t buffer_size, endpoint_param *const endpoint) {
; ---------------------------------
; Function ch_data_in_transfer
; ---------------------------------
_ch_data_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/ch376.c:157: if (buffer_size == 0)
	ld	a,(ix+7)
	or	(ix+6)
	jr	NZ,l_ch_data_in_transfer_00102
;source-doc/base-drv/ch376.c:158: return USB_ERR_OK;
	ld	l,$00
	jp	l_ch_data_in_transfer_00111
l_ch_data_in_transfer_00102:
;source-doc/base-drv/ch376.c:160: USB_MODULE_LEDS = $01;
	ld	a,$01
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:161: do {
	ld	c,(ix+8)
	ld	b,(ix+9)
l_ch_data_in_transfer_00107:
;source-doc/base-drv/ch376.c:162: ch_issue_token_in(endpoint);
	ld	l,c
	ld	h,b
	push	hl
	call	_ch_issue_token_in
;source-doc/base-drv/ch376.c:164: result = ch_long_get_status();
	call	_ch_long_get_status
	ld	a, l
	pop	bc
	ld	l, a
;source-doc/base-drv/ch376.c:165: CHECK(result);
	or	a
	jr	NZ,l_ch_data_in_transfer_00110
;source-doc/base-drv/ch376.c:167: endpoint->toggle = !endpoint->toggle;
	ld	e, c
	ld	d, b
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$01
	xor	$01
	and	$01
	ld	l, a
	ld	a, (de)
	and	$fe
	or	l
	ld	(de), a
;source-doc/base-drv/ch376.c:169: count = ch_read_data(buffer);
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	call	_ch_read_data
	ld	e, a
	pop	bc
;source-doc/base-drv/ch376.c:171: if (count == 0) {
	ld	a, e
;source-doc/base-drv/ch376.c:172: USB_MODULE_LEDS = $00;
	or	a
	jr	NZ,l_ch_data_in_transfer_00106
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:173: return USB_ERR_DATA_ERROR;
	ld	l,$04
	jr	l_ch_data_in_transfer_00111
l_ch_data_in_transfer_00106:
;source-doc/base-drv/ch376.c:176: buffer += count;
	ld	a,(ix+4)
	add	a, e
	ld	(ix+4),a
	jr	NC,l_ch_data_in_transfer_00148
	inc	(ix+5)
l_ch_data_in_transfer_00148:
;source-doc/base-drv/ch376.c:177: buffer_size -= count;
	ld	d,$00
	ld	a,(ix+6)
	sub	e
	ld	(ix+6),a
	ld	a,(ix+7)
	sbc	a, d
	ld	(ix+7),a
;source-doc/base-drv/ch376.c:178: } while (buffer_size > 0);
	xor	a
	cp	(ix+6)
	sbc	a,(ix+7)
	jp	PO, l_ch_data_in_transfer_00149
	xor	$80
l_ch_data_in_transfer_00149:
	jp	M, l_ch_data_in_transfer_00107
;source-doc/base-drv/ch376.c:180: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:181: return USB_ERR_OK;
	ld	l,$00
	jr	l_ch_data_in_transfer_00111
;source-doc/base-drv/ch376.c:183: done:
l_ch_data_in_transfer_00110:
;source-doc/base-drv/ch376.c:184: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:185: return result;
l_ch_data_in_transfer_00111:
;source-doc/base-drv/ch376.c:186: }
	pop	ix
	ret
;source-doc/base-drv/ch376.c:189: usb_error ch_data_in_transfer_n(uint8_t *const buffer, uint8_t *const buffer_size, endpoint_param *const endpoint) {
; ---------------------------------
; Function ch_data_in_transfer_n
; ---------------------------------
_ch_data_in_transfer_n:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/ch376.c:193: USB_MODULE_LEDS = $01;
	ld	a,$01
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:195: ch_issue_token_in(endpoint);
	ld	l,(ix+8)
	ld	h,(ix+9)
	call	_ch_issue_token_in
;source-doc/base-drv/ch376.c:197: CHECK(ch_long_get_status());
	call	_ch_long_get_status
	ld	a,l
	or	a
	jr	NZ,l_ch_data_in_transfer_n_00103
;source-doc/base-drv/ch376.c:199: endpoint->toggle = !endpoint->toggle;
	ld	l,(ix+8)
	ld	h,(ix+9)
	ld	a, (hl)
	and	$01
	xor	$01
	and	$01
	ld	c, a
	ld	a, (hl)
	and	$fe
	or	c
	ld	(hl), a
;source-doc/base-drv/ch376.c:201: count = ch_read_data(buffer);
	ld	l,(ix+4)
	ld	h,(ix+5)
	call	_ch_read_data
;source-doc/base-drv/ch376.c:203: *buffer_size = count;
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	(bc), a
;source-doc/base-drv/ch376.c:205: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:207: return USB_ERR_OK;
	ld	l,$00
	jr	l_ch_data_in_transfer_n_00104
;source-doc/base-drv/ch376.c:208: done:
l_ch_data_in_transfer_n_00103:
;source-doc/base-drv/ch376.c:209: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:210: return result;
l_ch_data_in_transfer_n_00104:
;source-doc/base-drv/ch376.c:211: }
	pop	ix
	ret
;source-doc/base-drv/ch376.c:213: usb_error ch_data_out_transfer(const uint8_t *buffer, int16_t buffer_length, endpoint_param *const endpoint) {
; ---------------------------------
; Function ch_data_out_transfer
; ---------------------------------
_ch_data_out_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	dec	sp
;source-doc/base-drv/ch376.c:216: const uint8_t max_packet_size = calc_max_packet_size(endpoint->max_packet_sizex);
	ld	c,(ix+8)
	ld	b,(ix+9)
	ld	e, c
	ld	d, b
	inc	de
	ld	a, (de)
	ld	(ix-1),a
;source-doc/base-drv/ch376.c:218: USB_MODULE_LEDS = $02;
	ld	a,$02
	push	bc
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
	pop	bc
;source-doc/base-drv/ch376.c:220: while (buffer_length > 0) {
l_ch_data_out_transfer_00103:
	xor	a
	cp	(ix+6)
	sbc	a,(ix+7)
	jp	PO, l_ch_data_out_transfer_00139
	xor	$80
l_ch_data_out_transfer_00139:
	jp	P, l_ch_data_out_transfer_00105
;source-doc/base-drv/ch376.c:221: const uint8_t size = max_packet_size < buffer_length ? max_packet_size : buffer_length;
	ld	d,(ix-1)
	ld	e,$00
	ld	a, d
	sub	(ix+6)
	ld	a, e
	sbc	a,(ix+7)
	jp	PO, l_ch_data_out_transfer_00140
	xor	$80
l_ch_data_out_transfer_00140:
	jp	P, l_ch_data_out_transfer_00109
	jr	l_ch_data_out_transfer_00110
l_ch_data_out_transfer_00109:
	ld	d,(ix+6)
	ld	e,(ix+7)
l_ch_data_out_transfer_00110:
;source-doc/base-drv/ch376.c:222: buffer             = ch_write_data(buffer, size);
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
;source-doc/base-drv/ch376.c:223: buffer_length -= size;
	ld	e,$00
	ld	a,(ix+6)
	sub	d
	ld	(ix+6),a
	ld	a,(ix+7)
	sbc	a, e
	ld	(ix+7),a
;source-doc/base-drv/ch376.c:224: ch_issue_token_out(endpoint);
	ld	l,c
	ld	h,b
	push	hl
	call	_ch_issue_token_out
;source-doc/base-drv/ch376.c:226: CHECK(ch_long_get_status());
	call	_ch_long_get_status
	ld	a, l
	pop	bc
	ld	l, a
	or	a
	jr	NZ,l_ch_data_out_transfer_00106
;source-doc/base-drv/ch376.c:228: endpoint->toggle = !endpoint->toggle;
	ld	e, c
	ld	d, b
	ld	l, e
	ld	h, d
	ld	a, (hl)
	and	$01
	xor	$01
	and	$01
	ld	l, a
	ld	a, (de)
	and	$fe
	or	l
	ld	(de), a
	jr	l_ch_data_out_transfer_00103
l_ch_data_out_transfer_00105:
;source-doc/base-drv/ch376.c:231: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:232: return USB_ERR_OK;
	ld	l,$00
	jr	l_ch_data_out_transfer_00107
;source-doc/base-drv/ch376.c:234: done:
l_ch_data_out_transfer_00106:
;source-doc/base-drv/ch376.c:235: USB_MODULE_LEDS = $00;
	ld	a,$00
	ld	bc,_USB_MODULE_LEDS
	out	(c), a
;source-doc/base-drv/ch376.c:236: return result;
l_ch_data_out_transfer_00107:
;source-doc/base-drv/ch376.c:237: }
	inc	sp
	pop	ix
	ret
;source-doc/base-drv/ch376.c:239: void ch_set_usb_address(const uint8_t device_address) __z88dk_fastcall {
; ---------------------------------
; Function ch_set_usb_address
; ---------------------------------
_ch_set_usb_address:
;source-doc/base-drv/ch376.c:240: ch_command(CH_CMD_SET_USB_ADDR);
	push	hl
	ld	l,$13
	call	_ch_command
	pop	hl
;source-doc/base-drv/ch376.c:241: CH376_DATA_PORT = device_address;
	ld	a, l
	ld	bc,_CH376_DATA_PORT
	out	(c), a
;source-doc/base-drv/ch376.c:242: }
	ret
