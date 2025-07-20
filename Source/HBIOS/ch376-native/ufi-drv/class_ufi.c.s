;
; Generated from source-doc/ufi-drv/class_ufi.c.asm -- not to be modify directly
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
;source-doc/ufi-drv/class_ufi.c:14: uint8_t wait_for_device_ready(device_config *const storage_device, uint8_t timeout_counter) {
; ---------------------------------
; Function wait_for_device_ready
; ---------------------------------
_wait_for_device_ready:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -18
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:18: do {
	ld	c,(ix+6)
l_wait_for_device_ready_00105:
;source-doc/ufi-drv/class_ufi.c:19: memset(&sense, 0, sizeof(sense));
	ld	hl,0
	add	hl, sp
	ld	b,$09
l_wait_for_device_ready_00132:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_wait_for_device_ready_00132
;source-doc/ufi-drv/class_ufi.c:20: result = ufi_test_unit_ready(storage_device, &sense);
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_ufi_test_unit_ready
	pop	af
	pop	af
	ld	a, l
	pop	bc
	ld	b, a
;source-doc/ufi-drv/class_ufi.c:22: if ((result == USB_ERR_OK && (sense.sense_key & 15) == 0) || timeout_counter-- == 0)
	or	a
	jr	NZ,l_wait_for_device_ready_00104
	ld	a,(ix-16)
	and	$0f
	jr	Z,l_wait_for_device_ready_00107
l_wait_for_device_ready_00104:
	ld	a, c
	dec	c
	or	a
	jr	Z,l_wait_for_device_ready_00107
;source-doc/ufi-drv/class_ufi.c:25: delay_medium();
	push	bc
	call	_delay_medium
	pop	bc
;source-doc/ufi-drv/class_ufi.c:27: } while (true);
	jr	l_wait_for_device_ready_00105
l_wait_for_device_ready_00107:
;source-doc/ufi-drv/class_ufi.c:29: return result | (sense.sense_key & 15);
	ld	a,(ix-16)
	and	$0f
	or	b
	ld	l, a
;source-doc/ufi-drv/class_ufi.c:30: }
	ld	sp, ix
	pop	ix
	ret
__ufi_cmd_request_sense:
	DEFB +$03
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$12
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
__ufi_cmd_rd_fmt_caps:
	DEFB +$23
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$0c
	DEFB +$00
	DEFB +$00
	DEFB +$00
__ufi_cmd_inquiry:
	DEFB +$12
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$24
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
__ufi_cmd_format:
	DEFB +$04
	DEFB +$17
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
__ufi_cmd_send_diag:
	DEFB +$1d
	DEFB +$04
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
	DEFB +$00
;source-doc/ufi-drv/class_ufi.c:32: usb_error ufi_test_unit_ready(device_config *const storage_device, ufi_request_sense_response const *response) {
; ---------------------------------
; Function ufi_test_unit_ready
; ---------------------------------
_ufi_test_unit_ready:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -24
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:35: memset(&ufi_cmd_request_test_unit_ready, 0, sizeof(ufi_test_unit_ready_command));
	ld	hl,0
	add	hl, sp
	ld	b,$06
l_ufi_test_unit_ready_00104:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_ufi_test_unit_ready_00104
;source-doc/ufi-drv/class_ufi.c:37: usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_request_test_unit_ready, false, 0, NULL, NULL);
	ld	hl,$0000
	push	hl
	push	hl
	push	hl
	xor	a
	push	af
	inc	sp
	ld	hl,7
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	ld	hl,11
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:40: ufi_cmd_request_sense = _ufi_cmd_request_sense;
	ld	hl,12
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,__ufi_cmd_request_sense
	ldir
;source-doc/ufi-drv/class_ufi.c:43: (uint8_t *)response, NULL);
	ld	c,(ix+6)
	ld	b,(ix+7)
;source-doc/ufi-drv/class_ufi.c:42: result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_request_sense, false, sizeof(ufi_request_sense_response),
	ld	hl,$0000
	push	hl
	push	bc
	ld	l,$12
	push	hl
	xor	a
	push	af
	inc	sp
	ld	hl,19
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
;source-doc/ufi-drv/class_ufi.c:46: return result;
;source-doc/ufi-drv/class_ufi.c:47: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:49: usb_error ufi_request_sense(device_config *const storage_device, ufi_request_sense_response const *response) {
; ---------------------------------
; Function ufi_request_sense
; ---------------------------------
_ufi_request_sense:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -12
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:51: ufi_cmd_request_sense = _ufi_cmd_request_sense;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,__ufi_cmd_request_sense
	ldir
;source-doc/ufi-drv/class_ufi.c:53: usb_error result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_request_sense, false, sizeof(ufi_request_sense_response),
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,$0000
	push	hl
	push	bc
	ld	l,$12
	push	hl
	xor	a
	push	af
	inc	sp
	ld	hl,7
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
;source-doc/ufi-drv/class_ufi.c:58: return result;
;source-doc/ufi-drv/class_ufi.c:59: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:61: usb_error ufi_read_frmt_caps(device_config *const storage_device, ufi_format_capacities_response const *response) {
; ---------------------------------
; Function ufi_read_frmt_caps
; ---------------------------------
_ufi_read_frmt_caps:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -24
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:65: ufi_cmd_read_format_capacities = _ufi_cmd_rd_fmt_caps;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,__ufi_cmd_rd_fmt_caps
	ldir
;source-doc/ufi-drv/class_ufi.c:66: result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_read_format_capacities, false, 12, (uint8_t *)response, NULL);
	ld	c,(ix+6)
	ld	b,(ix+7)
	push	bc
	ld	hl,$0000
	push	hl
	push	bc
	ld	l,$0c
	push	hl
	xor	a
	push	af
	inc	sp
	ld	hl,9
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	pop	af
	pop	af
	pop	af
	pop	af
	pop	af
	inc	sp
	ld	a, l
	pop	bc
	ld	l, a
;source-doc/ufi-drv/class_ufi.c:69: CHECK(result);
	or	a
	jr	NZ,l_ufi_read_frmt_caps_00103
;source-doc/ufi-drv/class_ufi.c:71: const uint8_t available_length = response->capacity_list_length;
	ld	l,(ix+6)
	ld	h,(ix+7)
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
;source-doc/ufi-drv/class_ufi.c:73: const uint8_t max_length =
	cp	$25
	jr	C,l_ufi_read_frmt_caps_00106
	ld	e,$24
	jr	l_ufi_read_frmt_caps_00107
l_ufi_read_frmt_caps_00106:
	ld	e, a
l_ufi_read_frmt_caps_00107:
;source-doc/ufi-drv/class_ufi.c:77: memcpy(&cmd, &ufi_cmd_read_format_capacities, sizeof(cmd));
	push	de
	push	bc
	ld	hl,16
	add	hl, sp
	ex	de, hl
	ld	hl,4
	add	hl, sp
	ld	bc,$000c
	ldir
	pop	bc
	pop	de
;source-doc/ufi-drv/class_ufi.c:78: cmd.allocation_length[1] = max_length;
	ld	(ix-4),e
;source-doc/ufi-drv/class_ufi.c:80: result = usb_execute_cbi(storage_device, (uint8_t *)&cmd, false, max_length, (uint8_t *)response, NULL);
	ld	hl,$0000
	ld	d,l
	push	hl
	push	bc
	push	de
	xor	a
	push	af
	inc	sp
	ld	hl,19
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	pop	af
	pop	af
	pop	af
	pop	af
	pop	af
	inc	sp
;source-doc/ufi-drv/class_ufi.c:84: done:
l_ufi_read_frmt_caps_00103:
;source-doc/ufi-drv/class_ufi.c:85: return result;
;source-doc/ufi-drv/class_ufi.c:86: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:88: usb_error ufi_inquiry(device_config *const storage_device, ufi_inquiry_response const *response) {
; ---------------------------------
; Function ufi_inquiry
; ---------------------------------
_ufi_inquiry:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -12
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:90: ufi_cmd_inquiry = _ufi_cmd_inquiry;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,__ufi_cmd_inquiry
	ldir
;source-doc/ufi-drv/class_ufi.c:92: usb_error result =
	ld	c,(ix+6)
	ld	b,(ix+7)
	ld	hl,$0000
	push	hl
	push	bc
	ld	l,$24
	push	hl
	xor	a
	push	af
	inc	sp
	ld	hl,7
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
;source-doc/ufi-drv/class_ufi.c:97: return result;
;source-doc/ufi-drv/class_ufi.c:98: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:100: usb_error ufi_read_write_sector(device_config *const storage_device,
; ---------------------------------
; Function ufi_read_write_sector
; ---------------------------------
_ufi_read_write_sector:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -12
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:107: memset(&cmd, 0, sizeof(cmd));
	ld	hl,0
	add	hl, sp
	ld	b,$06
l_ufi_read_write_sector_00113:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_ufi_read_write_sector_00113
;source-doc/ufi-drv/class_ufi.c:108: cmd.operation_code     = send ? $2A : $28;
	bit	0,(ix+6)
	jr	Z,l_ufi_read_write_sector_00104
	ld	a,$2a
	jr	l_ufi_read_write_sector_00105
l_ufi_read_write_sector_00104:
	ld	a,$28
l_ufi_read_write_sector_00105:
	ld	(ix-12),a
;source-doc/ufi-drv/class_ufi.c:109: cmd.lba[2]             = sector_number >> 8;
	ld	a,(ix+8)
	ld	(ix-8),a
;source-doc/ufi-drv/class_ufi.c:110: cmd.lba[3]             = sector_number & $FF;
	ld	a,(ix+7)
	ld	(ix-7),a
;source-doc/ufi-drv/class_ufi.c:111: cmd.transfer_length[1] = sector_count;
;source-doc/ufi-drv/class_ufi.c:113: usb_error result = usb_execute_cbi(storage_device, (uint8_t *)&cmd, send, 512 * sector_count, (uint8_t *)buffer, sense_codes);
	ld	a,(ix+9)
	ld	(ix-4),a
	add	a, a
	ld	b, a
	ld	c,$00
	ld	l,(ix+12)
	ld	h,(ix+13)
	push	hl
	ld	l,(ix+10)
	ld	h,(ix+11)
	push	hl
	push	bc
	ld	a,(ix+6)
	push	af
	inc	sp
	ld	hl,7
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
;source-doc/ufi-drv/class_ufi.c:117: return result;
;source-doc/ufi-drv/class_ufi.c:118: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:123: * HD     | 93h              | 1.25 MB  | 77     | 2     | 8             | 1232 04D0h   | 1024 0400h   |
; ---------------------------------
; Function ufi_format
; ---------------------------------
_ufi_format:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -26
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:130: const ufi_format_capacity_descriptor *const format) {
	ld	hl,2
	add	hl, sp
	ld	b,$06
l_ufi_format_00104:
	xor	a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_ufi_format_00104
;source-doc/ufi-drv/class_ufi.c:133: ufi_format_parameter_list parameter_list;
	ld	hl,14
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,__ufi_cmd_format
	ldir
;source-doc/ufi-drv/class_ufi.c:136: ufi_format_command cmd;
	ld	a,(ix+7)
	ld	(ix-10),a
;source-doc/ufi-drv/class_ufi.c:137: cmd = _ufi_cmd_format;
	ld	(ix-8),$00
;source-doc/ufi-drv/class_ufi.c:138: // memcpy(&cmd, &_ufi_cmd_format, sizeof(cmd));
	ld	(ix-4),$0c
;source-doc/ufi-drv/class_ufi.c:140: cmd.track_number             = track_number;
;source-doc/ufi-drv/class_ufi.c:141: cmd.interleave[1]            = 0;
	ld	a,(ix+6)
	and	$01
	or	$b0
	ld	(ix-23),a
;source-doc/ufi-drv/class_ufi.c:142: cmd.parameter_list_length[1] = sizeof(parameter_list);
	ld	(ix-22),$00
;source-doc/ufi-drv/class_ufi.c:143:
	ld	(ix-21),$08
;source-doc/ufi-drv/class_ufi.c:144: parameter_list.defect_list_header.status =
	ld	hl,6
	add	hl, sp
	ex	de, hl
	ld	l,(ix+8)
	ld	h,(ix+9)
	ld	bc,$0008
	ldir
;source-doc/ufi-drv/class_ufi.c:146: parameter_list.defect_list_header.defect_list_length_msb = 0;
	ld	hl,0
	add	hl, sp
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	ld	hl,$000c
	push	hl
	ld	a,$01
	push	af
	inc	sp
	ld	hl,21
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
;source-doc/ufi-drv/class_ufi.c:153: // trace_printf("ufi_format: %d, %02X %02X (len: %d)\r\n", result, sense_codes.bASC, sense_codes.bASCQ, sizeof(parameter_list));
;source-doc/ufi-drv/class_ufi.c:154:
	ld	sp,ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:156: done:
; ---------------------------------
; Function ufi_send_diagnostics
; ---------------------------------
_ufi_send_diagnostics:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -12
	add	hl, sp
	ld	sp, hl
;source-doc/ufi-drv/class_ufi.c:159:
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,$000c
	ld	hl,__ufi_cmd_send_diag
	ldir
;source-doc/ufi-drv/class_ufi.c:161: ufi_send_diagnostic_command ufi_cmd_send_diagnostic;
	ld	hl,$0000
	push	hl
	push	hl
	push	hl
	ld	a,$01
	push	af
	inc	sp
	ld	hl,7
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
;source-doc/ufi-drv/class_ufi.c:162:
	ld	sp,ix
	pop	ix
	ret
;source-doc/ufi-drv/class_ufi.c:164:
; ---------------------------------
; Function convert_from_msb_first
; ---------------------------------
_convert_from_msb_first:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/ufi-drv/class_ufi.c:166: }
	ld	hl,0
	add	hl, sp
	ex	de, hl
;source-doc/ufi-drv/class_ufi.c:167:
	ld	l,(ix+4)
	ld	h,(ix+5)
	inc	hl
	inc	hl
	inc	hl
;source-doc/ufi-drv/class_ufi.c:169: uint32_t       result;
	ld	a, (hl)
	dec	hl
	ld	(de), a
	inc	de
;source-doc/ufi-drv/class_ufi.c:170: uint8_t       *p_output = ((uint8_t *)&result);
	ld	a, (hl)
	dec	hl
	ld	(de), a
	inc	de
;source-doc/ufi-drv/class_ufi.c:171: const uint8_t *p_input  = buffer + 3;
	ld	a, (hl)
	ld	(de), a
	inc	de
;source-doc/ufi-drv/class_ufi.c:172:
	dec	hl
	ld	a, (hl)
	ld	(de), a
;source-doc/ufi-drv/class_ufi.c:174: *p_output++ = *p_input--;
	pop	hl
	push	hl
	ld	e,(ix-2)
	ld	d,(ix-1)
;source-doc/ufi-drv/class_ufi.c:175: *p_output++ = *p_input--;
	ld	sp, ix
	pop	ix
	ret
