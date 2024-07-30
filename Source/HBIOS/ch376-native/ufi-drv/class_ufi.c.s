;
; Generated from source-doc/ufi-drv/./class_ufi.c.asm -- not to be modify directly
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
;source-doc/ufi-drv/./class_ufi.c:14: uint8_t wait_for_device_ready(device_config *const storage_device, uint8_t timeout_counter) {
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
;source-doc/ufi-drv/./class_ufi.c:18: do {
	ld	c,(ix+6)
l_wait_for_device_ready_00105:
;source-doc/ufi-drv/./class_ufi.c:19: memset(&sense, 0, sizeof(sense));
	push	bc
	ld	hl,2
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x12
	push	hl
	call	_memset_callee
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
;source-doc/ufi-drv/./class_ufi.c:22: if ((result == USB_ERR_OK && sense.sense_key == 0) || timeout_counter-- == 0)
	or	a
	jr	NZ,l_wait_for_device_ready_00104
	ld	hl,2
	add	hl, sp
	ld	a, (hl)
	and	0x0f
	jr	Z,l_wait_for_device_ready_00107
l_wait_for_device_ready_00104:
	ld	a, c
	dec	c
	or	a
	jr	Z,l_wait_for_device_ready_00107
;source-doc/ufi-drv/./class_ufi.c:25: delay_medium();
	push	bc
	call	_delay_medium
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:27: } while (true);
	jr	l_wait_for_device_ready_00105
l_wait_for_device_ready_00107:
;source-doc/ufi-drv/./class_ufi.c:29: return result | sense.sense_key;
	ld	hl,2
	add	hl, sp
	ld	a, (hl)
	and	0x0f
	or	b
	ld	l, a
;source-doc/ufi-drv/./class_ufi.c:30: }
	ld	sp, ix
	pop	ix
	ret
__ufi_cmd_request_sense:
	DEFB +0x03
	DEFB 0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x12
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
__ufi_cmd_read_format_capacitie:
	DEFB +0x23
	DEFB 0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x0c
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
__ufi_cmd_inquiry:
	DEFB +0x12
	DEFB 0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x24
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
__ufi_cmd_format:
	DEFB +0x04
	DEFB 0x17
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
__ufi_cmd_send_diagnostic:
	DEFB +0x1d
	DEFB 0x04
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
	DEFB +0x00
;source-doc/ufi-drv/./class_ufi.c:32: usb_error ufi_test_unit_ready(device_config *const storage_device, ufi_request_sense_response const *response) {
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
;source-doc/ufi-drv/./class_ufi.c:35: memset(&ufi_cmd_request_test_unit_ready, 0, sizeof(ufi_test_unit_ready_command));
	ld	hl,0
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x0c
	push	hl
	call	_memset_callee
;source-doc/ufi-drv/./class_ufi.c:37: usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_request_test_unit_ready, false, 0, NULL, NULL);
	ld	hl,0x0000
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
;source-doc/ufi-drv/./class_ufi.c:40: ufi_cmd_request_sense = _ufi_cmd_request_sense;
	ld	hl,12
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,0x000c
	ld	hl,__ufi_cmd_request_sense
	ldir
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:43: (uint8_t *)response, NULL);
	ld	e,(ix+6)
	ld	d,(ix+7)
;source-doc/ufi-drv/./class_ufi.c:42: result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_request_sense, false, sizeof(ufi_request_sense_response),
	ld	hl,0x0000
	push	hl
	push	de
	ld	l,0x12
	push	hl
	xor	a
	push	af
	inc	sp
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:45: RETURN_CHECK(result);
;source-doc/ufi-drv/./class_ufi.c:46: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:48: usb_error ufi_request_sense(device_config *const storage_device, ufi_request_sense_response const *response) {
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
;source-doc/ufi-drv/./class_ufi.c:50: ufi_cmd_request_sense = _ufi_cmd_request_sense;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,0x000c
	ld	hl,__ufi_cmd_request_sense
	ldir
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:52: usb_error result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_request_sense, false, sizeof(ufi_request_sense_response),
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	hl,0x0000
	push	hl
	push	de
	ld	l,0x12
	push	hl
	xor	a
	push	af
	inc	sp
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:55: RETURN_CHECK(result);
;source-doc/ufi-drv/./class_ufi.c:56: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:58: usb_error ufi_read_frmt_caps(device_config *const storage_device, ufi_format_capacities_response const *response) {
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
;source-doc/ufi-drv/./class_ufi.c:62: ufi_cmd_read_format_capacities = _ufi_cmd_read_format_capacities;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,__ufi_cmd_read_format_capacitie
	ldir
;source-doc/ufi-drv/./class_ufi.c:63: result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_read_format_capacities, false, 12, (uint8_t *)response, NULL);
	ld	c,(ix+6)
	ld	b,(ix+7)
	push	bc
	ld	hl,0x0000
	push	hl
	push	bc
	ld	l,0x0c
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
	ld	iy,11
	add	iy, sp
	ld	sp, iy
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:66: CHECK(result);
	ld	a, l
	or	a
	jr	NZ,l_ufi_read_frmt_caps_00103
;source-doc/ufi-drv/./class_ufi.c:68: const uint8_t available_length = response->capacity_list_length;
	ld	l,(ix+6)
	ld	h,(ix+7)
	inc	hl
	inc	hl
	inc	hl
	ld	e, (hl)
;source-doc/ufi-drv/./class_ufi.c:70: const uint8_t max_length =
	ld	a,0x24
	sub	e
	jr	NC,l_ufi_read_frmt_caps_00105
	ld	e,0x24
l_ufi_read_frmt_caps_00105:
;source-doc/ufi-drv/./class_ufi.c:74: memcpy(&cmd, &ufi_cmd_read_format_capacities, sizeof(cmd));
	push	bc
	push	de
	ld	hl,16
	add	hl, sp
	push	hl
	ld	hl,6
	add	hl, sp
	push	hl
	ld	hl,0x000c
	push	hl
	call	_memcpy_callee
	pop	de
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:75: cmd.allocation_length[1] = max_length;
	ld	(ix-4),e
;source-doc/ufi-drv/./class_ufi.c:77: result = usb_execute_cbi(storage_device, (uint8_t *)&cmd, false, max_length, (uint8_t *)response, NULL);
	ld	hl,0x0000
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
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:80: RETURN_CHECK(result);
l_ufi_read_frmt_caps_00103:
;source-doc/ufi-drv/./class_ufi.c:81: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:83: usb_error ufi_inquiry(device_config *const storage_device, ufi_inquiry_response const *response) {
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
;source-doc/ufi-drv/./class_ufi.c:85: ufi_cmd_inquiry = _ufi_cmd_inquiry;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,0x000c
	ld	hl,__ufi_cmd_inquiry
	ldir
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:87: usb_error result =
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	hl,0x0000
	push	hl
	push	de
	ld	l,0x24
	push	hl
	xor	a
	push	af
	inc	sp
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:90: RETURN_CHECK(result);
;source-doc/ufi-drv/./class_ufi.c:91: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:93: usb_error ufi_read_write_sector(device_config *const storage_device,
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
;source-doc/ufi-drv/./class_ufi.c:100: memset(&cmd, 0, sizeof(cmd));
	ld	hl,0
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x0c
	push	hl
	call	_memset_callee
;source-doc/ufi-drv/./class_ufi.c:101: cmd.operation_code     = send ? 0x2A : 0x28;
	bit	0,(ix+6)
	jr	Z,l_ufi_read_write_sector_00103
	ld	bc,0x002a
	jr	l_ufi_read_write_sector_00104
l_ufi_read_write_sector_00103:
	ld	bc,0x0028
l_ufi_read_write_sector_00104:
	ld	(ix-12),c
;source-doc/ufi-drv/./class_ufi.c:102: cmd.lba[2]             = sector_number >> 8;
	ld	a,(ix+8)
	ld	(ix-8),a
;source-doc/ufi-drv/./class_ufi.c:103: cmd.lba[3]             = sector_number & 0xFF;
	ld	a,(ix+7)
	ld	(ix-7),a
;source-doc/ufi-drv/./class_ufi.c:104: cmd.transfer_length[1] = sector_count;
;source-doc/ufi-drv/./class_ufi.c:106: usb_error result = usb_execute_cbi(storage_device, (uint8_t *)&cmd, send, 512 * sector_count, (uint8_t *)buffer, sense_codes);
	ld	a,(ix+9)
	ld	(ix-4),a
	add	a, a
	ld	c,0x00
	ld	l,(ix+12)
	ld	h,(ix+13)
	push	hl
	ld	l,(ix+10)
	ld	h,(ix+11)
	push	hl
	ld	b, a
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
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:108: RETURN_CHECK(result);
;source-doc/ufi-drv/./class_ufi.c:109: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:118: usb_error ufi_format(device_config *const                        storage_device,
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
;source-doc/ufi-drv/./class_ufi.c:125: memset(&parameter_list, 0, sizeof(parameter_list));
	ld	hl,2
	add	hl, sp
	push	hl
	ld	hl,0x0000
	push	hl
	ld	l,0x0c
	push	hl
	call	_memset_callee
;source-doc/ufi-drv/./class_ufi.c:128: cmd = _ufi_cmd_format;
	ld	hl,14
	add	hl, sp
	ex	de, hl
	ld	bc,0x000c
	ld	hl,__ufi_cmd_format
	ldir
;source-doc/ufi-drv/./class_ufi.c:131: cmd.track_number             = track_number;
	ld	a,(ix+7)
	ld	(ix-10),a
;source-doc/ufi-drv/./class_ufi.c:132: cmd.interleave[1]            = 0;
	ld	(ix-8),0x00
;source-doc/ufi-drv/./class_ufi.c:133: cmd.parameter_list_length[1] = sizeof(parameter_list);
	ld	(ix-4),0x0c
;source-doc/ufi-drv/./class_ufi.c:135: parameter_list.defect_list_header.side                   = side;
	ld	hl,2+1
	add	hl, sp
	ex	de, hl
	ld	a,(ix+6)
	and	0x01
	ld	c, a
	ld	a, (de)
	and	0xfe
	or	c
	ld	(de), a
;source-doc/ufi-drv/./class_ufi.c:136: parameter_list.defect_list_header.immediate              = 0;
	ld	l, e
	ld	h, d
	res	1, (hl)
;source-doc/ufi-drv/./class_ufi.c:137: parameter_list.defect_list_header.reserved2              = 0;
	ld	c, e
	ld	b, d
	ld	a, (bc)
	and	0xf3
	ld	(bc), a
;source-doc/ufi-drv/./class_ufi.c:138: parameter_list.defect_list_header.single_track           = 1;
	ld	l, e
	ld	h, d
	set	4, (hl)
;source-doc/ufi-drv/./class_ufi.c:139: parameter_list.defect_list_header.dcrt                   = 1;
	ld	l, e
	ld	h, d
	set	5, (hl)
;source-doc/ufi-drv/./class_ufi.c:140: parameter_list.defect_list_header.extend                 = 0;
	ld	l, e
	ld	h, d
	res	6, (hl)
;source-doc/ufi-drv/./class_ufi.c:141: parameter_list.defect_list_header.fov                    = 1;
	ld	a, (de)
	or	0x80
	ld	(de), a
;source-doc/ufi-drv/./class_ufi.c:142: parameter_list.defect_list_header.defect_list_length_msb = 0;
	ld	(ix-22),0x00
;source-doc/ufi-drv/./class_ufi.c:143: parameter_list.defect_list_header.defect_list_length_lsb = 8;
	ld	(ix-21),0x08
;source-doc/ufi-drv/./class_ufi.c:144: memcpy(&parameter_list.format_descriptor, (void *)format, sizeof(ufi_format_capacity_descriptor));
	ld	c,(ix+8)
	ld	b,(ix+9)
	ld	hl,6
	add	hl, sp
	push	hl
	push	bc
	ld	hl,0x0008
	push	hl
	call	_memcpy_callee
;source-doc/ufi-drv/./class_ufi.c:146: usb_error result = usb_execute_cbi(storage_device, (uint8_t *)&cmd, true, sizeof(parameter_list), (uint8_t *)&parameter_list,
	ld	hl,0
	add	hl, sp
	push	hl
	ld	hl,4
	add	hl, sp
	push	hl
	ld	hl,0x000c
	push	hl
	ld	a,0x01
	push	af
	inc	sp
	ld	hl,21
	add	hl, sp
	push	hl
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:151: RETURN_CHECK(result);
;source-doc/ufi-drv/./class_ufi.c:152: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:154: usb_error ufi_send_diagnostics(device_config *const storage_device) {
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
;source-doc/ufi-drv/./class_ufi.c:158: ufi_cmd_send_diagnostic = _ufi_cmd_send_diagnostic;
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
	push	hl
	ld	bc,0x000c
	ld	hl,__ufi_cmd_send_diagnostic
	ldir
	pop	bc
;source-doc/ufi-drv/./class_ufi.c:160: result = usb_execute_cbi(storage_device, (uint8_t *)&ufi_cmd_send_diagnostic, true, 0, NULL, NULL);
	ld	hl,0x0000
	push	hl
	push	hl
	push	hl
	ld	a,0x01
	push	af
	inc	sp
	push	bc
	ld	l,(ix+4)
	ld	h,(ix+5)
	push	hl
	call	_usb_execute_cbi
	ld	iy,11
	add	iy, sp
;source-doc/ufi-drv/./class_ufi.c:162: RETURN_CHECK(result);
;source-doc/ufi-drv/./class_ufi.c:163: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/ufi-drv/./class_ufi.c:165: uint32_t convert_from_msb_first(const uint8_t *const buffer) {
; ---------------------------------
; Function convert_from_msb_first
; ---------------------------------
_convert_from_msb_first:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/ufi-drv/./class_ufi.c:167: uint8_t       *p_output = ((uint8_t *)&result);
	ld	hl,0
	add	hl, sp
	ex	de, hl
;source-doc/ufi-drv/./class_ufi.c:168: const uint8_t *p_input  = buffer + 3;
	ld	c,(ix+4)
	ld	b,(ix+5)
	inc	bc
	inc	bc
	inc	bc
;source-doc/ufi-drv/./class_ufi.c:170: *p_output++ = *p_input--;
	ld	a, (bc)
	dec	bc
	ld	(de), a
	inc	de
;source-doc/ufi-drv/./class_ufi.c:171: *p_output++ = *p_input--;
	ld	a, (bc)
	dec	bc
	ld	(de), a
	inc	de
;source-doc/ufi-drv/./class_ufi.c:172: *p_output++ = *p_input--;
	ld	a, (bc)
	dec	bc
	ld	(de), a
	inc	de
;source-doc/ufi-drv/./class_ufi.c:173: *p_output   = *p_input--;
	ld	a, (bc)
	ld	(de), a
;source-doc/ufi-drv/./class_ufi.c:175: return result;
	pop	hl
	push	hl
	ld	e,(ix-2)
	ld	d,(ix-1)
;source-doc/ufi-drv/./class_ufi.c:176: }
	ld	sp, ix
	pop	ix
	ret
