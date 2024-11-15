;--------------------------------------------------------
; File Created by SDCC : free open source ISO C Compiler
; Version 4.4.0 #14648 (Linux)
;--------------------------------------------------------
; Processed by Z88DK
;--------------------------------------------------------
	
	EXTERN __divschar
	EXTERN __divschar_callee
	EXTERN __divsint
	EXTERN __divsint_callee
	EXTERN __divslong
	EXTERN __divslong_callee
	EXTERN __divslonglong
	EXTERN __divslonglong_callee
	EXTERN __divsuchar
	EXTERN __divsuchar_callee
	EXTERN __divuchar
	EXTERN __divuchar_callee
	EXTERN __divuint
	EXTERN __divuint_callee
	EXTERN __divulong
	EXTERN __divulong_callee
	EXTERN __divulonglong
	EXTERN __divulonglong_callee
	EXTERN __divuschar
	EXTERN __divuschar_callee
	EXTERN __modschar
	EXTERN __modschar_callee
	EXTERN __modsint
	EXTERN __modsint_callee
	EXTERN __modslong
	EXTERN __modslong_callee
	EXTERN __modslonglong
	EXTERN __modslonglong_callee
	EXTERN __modsuchar
	EXTERN __modsuchar_callee
	EXTERN __moduchar
	EXTERN __moduchar_callee
	EXTERN __moduint
	EXTERN __moduint_callee
	EXTERN __modulong
	EXTERN __modulong_callee
	EXTERN __modulonglong
	EXTERN __modulonglong_callee
	EXTERN __moduschar
	EXTERN __moduschar_callee
	EXTERN __mulint
	EXTERN __mulint_callee
	EXTERN __mullong
	EXTERN __mullong_callee
	EXTERN __mullonglong
	EXTERN __mullonglong_callee
	EXTERN __mulschar
	EXTERN __mulschar_callee
	EXTERN __mulsuchar
	EXTERN __mulsuchar_callee
	EXTERN __muluchar
	EXTERN __muluchar_callee
	EXTERN __muluschar
	EXTERN __muluschar_callee
	EXTERN __rlslonglong
	EXTERN __rlslonglong_callee
	EXTERN __rlulonglong
	EXTERN __rlulonglong_callee
	EXTERN __rrslonglong
	EXTERN __rrslonglong_callee
	EXTERN __rrulonglong
	EXTERN __rrulonglong_callee
	EXTERN ___mulsint2slong
	EXTERN ___mulsint2slong_callee
	EXTERN ___muluint2ulong
	EXTERN ___muluint2ulong_callee
	EXTERN ___sdcc_call_hl
	EXTERN ___sdcc_call_iy
	EXTERN ___sdcc_enter_ix
	EXTERN banked_call
	EXTERN _banked_ret
	EXTERN ___fs2schar
	EXTERN ___fs2schar_callee
	EXTERN ___fs2sint
	EXTERN ___fs2sint_callee
	EXTERN ___fs2slong
	EXTERN ___fs2slong_callee
	EXTERN ___fs2slonglong
	EXTERN ___fs2slonglong_callee
	EXTERN ___fs2uchar
	EXTERN ___fs2uchar_callee
	EXTERN ___fs2uint
	EXTERN ___fs2uint_callee
	EXTERN ___fs2ulong
	EXTERN ___fs2ulong_callee
	EXTERN ___fs2ulonglong
	EXTERN ___fs2ulonglong_callee
	EXTERN ___fsadd
	EXTERN ___fsadd_callee
	EXTERN ___fsdiv
	EXTERN ___fsdiv_callee
	EXTERN ___fseq
	EXTERN ___fseq_callee
	EXTERN ___fsgt
	EXTERN ___fsgt_callee
	EXTERN ___fslt
	EXTERN ___fslt_callee
	EXTERN ___fsmul
	EXTERN ___fsmul_callee
	EXTERN ___fsneq
	EXTERN ___fsneq_callee
	EXTERN ___fssub
	EXTERN ___fssub_callee
	EXTERN ___schar2fs
	EXTERN ___schar2fs_callee
	EXTERN ___sint2fs
	EXTERN ___sint2fs_callee
	EXTERN ___slong2fs
	EXTERN ___slong2fs_callee
	EXTERN ___slonglong2fs
	EXTERN ___slonglong2fs_callee
	EXTERN ___uchar2fs
	EXTERN ___uchar2fs_callee
	EXTERN ___uint2fs
	EXTERN ___uint2fs_callee
	EXTERN ___ulong2fs
	EXTERN ___ulong2fs_callee
	EXTERN ___ulonglong2fs
	EXTERN ___ulonglong2fs_callee
	EXTERN ____sdcc_2_copy_src_mhl_dst_deix
	EXTERN ____sdcc_2_copy_src_mhl_dst_bcix
	EXTERN ____sdcc_4_copy_src_mhl_dst_deix
	EXTERN ____sdcc_4_copy_src_mhl_dst_bcix
	EXTERN ____sdcc_4_copy_src_mhl_dst_mbc
	EXTERN ____sdcc_4_ldi_nosave_bc
	EXTERN ____sdcc_4_ldi_save_bc
	EXTERN ____sdcc_4_push_hlix
	EXTERN ____sdcc_4_push_mhl
	EXTERN ____sdcc_lib_setmem_hl
	EXTERN ____sdcc_ll_add_de_bc_hl
	EXTERN ____sdcc_ll_add_de_bc_hlix
	EXTERN ____sdcc_ll_add_de_hlix_bc
	EXTERN ____sdcc_ll_add_de_hlix_bcix
	EXTERN ____sdcc_ll_add_deix_bc_hl
	EXTERN ____sdcc_ll_add_deix_hlix
	EXTERN ____sdcc_ll_add_hlix_bc_deix
	EXTERN ____sdcc_ll_add_hlix_deix_bc
	EXTERN ____sdcc_ll_add_hlix_deix_bcix
	EXTERN ____sdcc_ll_asr_hlix_a
	EXTERN ____sdcc_ll_asr_mbc_a
	EXTERN ____sdcc_ll_copy_src_de_dst_hlix
	EXTERN ____sdcc_ll_copy_src_de_dst_hlsp
	EXTERN ____sdcc_ll_copy_src_deix_dst_hl
	EXTERN ____sdcc_ll_copy_src_deix_dst_hlix
	EXTERN ____sdcc_ll_copy_src_deixm_dst_hlsp
	EXTERN ____sdcc_ll_copy_src_desp_dst_hlsp
	EXTERN ____sdcc_ll_copy_src_hl_dst_de
	EXTERN ____sdcc_ll_copy_src_hlsp_dst_de
	EXTERN ____sdcc_ll_copy_src_hlsp_dst_deixm
	EXTERN ____sdcc_ll_lsl_hlix_a
	EXTERN ____sdcc_ll_lsl_mbc_a
	EXTERN ____sdcc_ll_lsr_hlix_a
	EXTERN ____sdcc_ll_lsr_mbc_a
	EXTERN ____sdcc_ll_push_hlix
	EXTERN ____sdcc_ll_push_mhl
	EXTERN ____sdcc_ll_sub_de_bc_hl
	EXTERN ____sdcc_ll_sub_de_bc_hlix
	EXTERN ____sdcc_ll_sub_de_hlix_bc
	EXTERN ____sdcc_ll_sub_de_hlix_bcix
	EXTERN ____sdcc_ll_sub_deix_bc_hl
	EXTERN ____sdcc_ll_sub_deix_hlix
	EXTERN ____sdcc_ll_sub_hlix_bc_deix
	EXTERN ____sdcc_ll_sub_hlix_deix_bc
	EXTERN ____sdcc_ll_sub_hlix_deix_bcix
	EXTERN ____sdcc_load_debc_deix
	EXTERN ____sdcc_load_dehl_deix
	EXTERN ____sdcc_load_debc_mhl
	EXTERN ____sdcc_load_hlde_mhl
	EXTERN ____sdcc_store_dehl_bcix
	EXTERN ____sdcc_store_debc_hlix
	EXTERN ____sdcc_store_debc_mhl
	EXTERN ____sdcc_cpu_pop_ei
	EXTERN ____sdcc_cpu_pop_ei_jp
	EXTERN ____sdcc_cpu_push_di
	EXTERN ____sdcc_outi
	EXTERN ____sdcc_outi_128
	EXTERN ____sdcc_outi_256
	EXTERN ____sdcc_ldi
	EXTERN ____sdcc_ldi_128
	EXTERN ____sdcc_ldi_256
	EXTERN ____sdcc_4_copy_srcd_hlix_dst_deix
	EXTERN ____sdcc_4_and_src_mbc_mhl_dst_deix
	EXTERN ____sdcc_4_or_src_mbc_mhl_dst_deix
	EXTERN ____sdcc_4_xor_src_mbc_mhl_dst_deix
	EXTERN ____sdcc_4_or_src_dehl_dst_bcix
	EXTERN ____sdcc_4_xor_src_dehl_dst_bcix
	EXTERN ____sdcc_4_and_src_dehl_dst_bcix
	EXTERN ____sdcc_4_xor_src_mbc_mhl_dst_debc
	EXTERN ____sdcc_4_or_src_mbc_mhl_dst_debc
	EXTERN ____sdcc_4_and_src_mbc_mhl_dst_debc
	EXTERN ____sdcc_4_cpl_src_mhl_dst_debc
	EXTERN ____sdcc_4_xor_src_debc_mhl_dst_debc
	EXTERN ____sdcc_4_or_src_debc_mhl_dst_debc
	EXTERN ____sdcc_4_and_src_debc_mhl_dst_debc
	EXTERN ____sdcc_4_and_src_debc_hlix_dst_debc
	EXTERN ____sdcc_4_or_src_debc_hlix_dst_debc
	EXTERN ____sdcc_4_xor_src_debc_hlix_dst_debc

;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	GLOBAL _usb_dat_in_trns_n_ext
	GLOBAL _usb_dat_in_trnsfer_ext
	GLOBAL _usb_ctrl_trnsfer_ext
	GLOBAL _usb_control_transfer
	GLOBAL _usb_data_in_transfer
	GLOBAL _usb_data_in_transfer_n
	GLOBAL _usb_data_out_transfer
;--------------------------------------------------------
; Externals used
;--------------------------------------------------------
	GLOBAL _critical_end
	GLOBAL _critical_begin
	GLOBAL _print_uint16
	GLOBAL _print_string
	GLOBAL _print_hex
	GLOBAL _ch_issue_token_in_ep0
	GLOBAL _ch_issue_token_out_ep0
	GLOBAL _ch_issue_token_setup
	GLOBAL _ch_data_out_transfer
	GLOBAL _ch_data_in_transfer_n
	GLOBAL _ch_data_in_transfer
	GLOBAL _ch_control_transfer_set_config
	GLOBAL _ch_control_transfer_set_address
	GLOBAL _ch_control_transfer_request_descriptor
	GLOBAL _ch_set_usb_address
	GLOBAL _ch_write_data
	GLOBAL _ch_cmd_get_ic_version
	GLOBAL _ch_cmd_set_usb_mode
	GLOBAL _ch_probe
	GLOBAL _ch_cmd_reset_all
	GLOBAL _ch_read_data
	GLOBAL _ch_very_short_wait_int_and_get_status
	GLOBAL _ch_short_wait_int_and_get_status
	GLOBAL _ch_long_wait_int_and_get_status
	GLOBAL _ch_get_status
	GLOBAL _ch_command
	GLOBAL _delay_medium
	GLOBAL _delay_short
	GLOBAL _delay_20ms
	GLOBAL _printf
	GLOBAL _delay
	GLOBAL _ulltoa_callee
	GLOBAL _ulltoa
	GLOBAL _strtoull_callee
	GLOBAL _strtoull
	GLOBAL _strtoll_callee
	GLOBAL _strtoll
	GLOBAL _lltoa_callee
	GLOBAL _lltoa
	GLOBAL _llabs_callee
	GLOBAL _llabs
	GLOBAL __lldivu__callee
	GLOBAL __lldivu_
	GLOBAL __lldiv__callee
	GLOBAL __lldiv_
	GLOBAL _atoll_callee
	GLOBAL _atoll
	GLOBAL _realloc_unlocked_callee
	GLOBAL _realloc_unlocked
	GLOBAL _malloc_unlocked_fastcall
	GLOBAL _malloc_unlocked
	GLOBAL _free_unlocked_fastcall
	GLOBAL _free_unlocked
	GLOBAL _calloc_unlocked_callee
	GLOBAL _calloc_unlocked
	GLOBAL _aligned_alloc_unlocked_callee
	GLOBAL _aligned_alloc_unlocked
	GLOBAL _realloc_callee
	GLOBAL _realloc
	GLOBAL _malloc_fastcall
	GLOBAL _malloc
	GLOBAL _free_fastcall
	GLOBAL _free
	GLOBAL _calloc_callee
	GLOBAL _calloc
	GLOBAL _aligned_alloc_callee
	GLOBAL _aligned_alloc
	GLOBAL _utoa_callee
	GLOBAL _utoa
	GLOBAL _ultoa_callee
	GLOBAL _ultoa
	GLOBAL _system_fastcall
	GLOBAL _system
	GLOBAL _strtoul_callee
	GLOBAL _strtoul
	GLOBAL _strtol_callee
	GLOBAL _strtol
	GLOBAL _strtof_callee
	GLOBAL _strtof
	GLOBAL _strtod_callee
	GLOBAL _strtod
	GLOBAL _srand_fastcall
	GLOBAL _srand
	GLOBAL _rand
	GLOBAL _quick_exit_fastcall
	GLOBAL _quick_exit
	GLOBAL _qsort_callee
	GLOBAL _qsort
	GLOBAL _ltoa_callee
	GLOBAL _ltoa
	GLOBAL _labs_fastcall
	GLOBAL _labs
	GLOBAL _itoa_callee
	GLOBAL _itoa
	GLOBAL _ftoh_callee
	GLOBAL _ftoh
	GLOBAL _ftog_callee
	GLOBAL _ftog
	GLOBAL _ftoe_callee
	GLOBAL _ftoe
	GLOBAL _ftoa_callee
	GLOBAL _ftoa
	GLOBAL _exit_fastcall
	GLOBAL _exit
	GLOBAL _dtoh_callee
	GLOBAL _dtoh
	GLOBAL _dtog_callee
	GLOBAL _dtog
	GLOBAL _dtoe_callee
	GLOBAL _dtoe
	GLOBAL _dtoa_callee
	GLOBAL _dtoa
	GLOBAL _bsearch_callee
	GLOBAL _bsearch
	GLOBAL _atol_fastcall
	GLOBAL _atol
	GLOBAL _atoi_fastcall
	GLOBAL _atoi
	GLOBAL _atof_fastcall
	GLOBAL _atof
	GLOBAL _atexit_fastcall
	GLOBAL _atexit
	GLOBAL _at_quick_exit_fastcall
	GLOBAL _at_quick_exit
	GLOBAL _abs_fastcall
	GLOBAL _abs
	GLOBAL _abort
	GLOBAL __strtou__callee
	GLOBAL __strtou_
	GLOBAL __strtoi__callee
	GLOBAL __strtoi_
	GLOBAL __random_uniform_xor_8__fastcall
	GLOBAL __random_uniform_xor_8_
	GLOBAL __random_uniform_xor_32__fastcall
	GLOBAL __random_uniform_xor_32_
	GLOBAL __random_uniform_cmwc_8__fastcall
	GLOBAL __random_uniform_cmwc_8_
	GLOBAL __shellsort__callee
	GLOBAL __shellsort_
	GLOBAL __quicksort__callee
	GLOBAL __quicksort_
	GLOBAL __insertion_sort__callee
	GLOBAL __insertion_sort_
	GLOBAL __ldivu__callee
	GLOBAL __ldivu_
	GLOBAL __ldiv__callee
	GLOBAL __ldiv_
	GLOBAL __divu__callee
	GLOBAL __divu_
	GLOBAL __div__callee
	GLOBAL __div_
	GLOBAL _in_critical_usb_section
	GLOBAL _result
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
defc _CH376_DATA_PORT	=	0xff88
defc _CH376_COMMAND_PORT	=	0xff89
defc _USB_MODULE_LEDS	=	0xff8a
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	SECTION bss_compiler
;--------------------------------------------------------
; ram data
;--------------------------------------------------------
	
IF 0
	
; .area _INITIALIZED removed by z88dk
	
	
ENDIF
	
;--------------------------------------------------------
; absolute external ram data
;--------------------------------------------------------
	SECTION IGNORE
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	SECTION code_crt_init
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	SECTION IGNORE
;--------------------------------------------------------
; code
;--------------------------------------------------------
	SECTION code_compiler
;source-doc/base-drv/transfers.c:24: usb_error usb_ctrl_trnsfer_ext(const setup_packet *const cmd_packet,
;	---------------------------------
; Function usb_ctrl_trnsfer_ext
; ---------------------------------
_usb_ctrl_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:28: if ((uint16_t)cmd_packet < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	sub	a,0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00102
;source-doc/base-drv/transfers.c:29: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00102:
;source-doc/base-drv/transfers.c:31: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+7)
	or	a,(ix+6)
	jr	Z,l_usb_ctrl_trnsfer_ext_00104
	ld	a,(ix+7)
	sub	a,0x80
	jr	NC,l_usb_ctrl_trnsfer_ext_00104
;source-doc/base-drv/transfers.c:32: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_ctrl_trnsfer_ext_00106
l_usb_ctrl_trnsfer_ext_00104:
;source-doc/base-drv/transfers.c:34: return usb_control_transfer(cmd_packet, buffer, device_address, max_packet_size);
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
;source-doc/base-drv/transfers.c:35: }
	pop	ix
	ret
;source-doc/base-drv/transfers.c:47: usb_error usb_control_transfer(const setup_packet *const cmd_packet,
;	---------------------------------
; Function usb_control_transfer
; ---------------------------------
_usb_control_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/transfers.c:52: endpoint_param endpoint = {1, 0, max_packet_size};
	ld	hl,0
	add	hl, sp
	set	0, (hl)
	ld	hl,0
	add	hl, sp
	ld	a, (hl)
	and	a,0xf1
	ld	(hl), a
	ld	c,(ix+9)
	ld	b,0x00
	ld	hl,1
	add	hl, sp
	ld	(hl), c
	inc	hl
	ld	a, b
	and	a,0x03
	ld	e,a
	ld	a, (hl)
	and	a,0xfc
	or	a, e
	ld	(hl), a
;source-doc/base-drv/transfers.c:54: const uint8_t transferIn = (cmd_packet->bmRequestType & 0x80);
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	a, (bc)
	and	a,0x80
;source-doc/base-drv/transfers.c:56: if (transferIn && buffer == 0)
	ld	(ix-1),a
	or	a, a
	jr	Z,l_usb_control_transfer_00102
	ld	a,(ix+7)
	or	a,(ix+6)
	jr	NZ,l_usb_control_transfer_00102
;source-doc/base-drv/transfers.c:57: return USB_ERR_OTHER;
	ld	l,0x0f
	jp	l_usb_control_transfer_00114
l_usb_control_transfer_00102:
;source-doc/base-drv/transfers.c:59: critical_begin();
	push	bc
	call	_critical_begin
	ld	l,(ix+8)
	call	_ch_set_usb_address
	pop	bc
;source-doc/base-drv/transfers.c:63: ch_write_data((const uint8_t *)cmd_packet, sizeof(setup_packet));
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
	call	_ch_short_wait_int_and_get_status
	pop	bc
;source-doc/base-drv/transfers.c:66: CHECK(result);
	ld	a, l
	or	a, a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:68: const uint16_t length = cmd_packet->wLength;
	ld	hl,6
	add	hl, bc
	ld	c, (hl)
	inc	hl
;source-doc/base-drv/transfers.c:71: ? (transferIn ? ch_data_in_transfer(buffer, length, &endpoint) : ch_data_out_transfer(buffer, length, &endpoint))
	ld	a,(hl)
	ld	b,a
	or	a, c
	jr	Z,l_usb_control_transfer_00116
	ld	e,(ix+6)
	ld	d,(ix+7)
	ld	a,(ix-1)
	or	a, a
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
;source-doc/base-drv/transfers.c:72: : USB_ERR_OK;
	ld	l,0x00
l_usb_control_transfer_00117:
;source-doc/base-drv/transfers.c:74: CHECK(result)
	ld	a, l
	or	a, a
	jr	NZ,l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:76: if (transferIn) {
	ld	a,(ix-1)
	or	a, a
	jr	Z,l_usb_control_transfer_00112
;source-doc/base-drv/transfers.c:77: ch_command(CH_CMD_WR_HOST_DATA);
	ld	l,0x2c
	call	_ch_command
;source-doc/base-drv/transfers.c:78: CH376_DATA_PORT = 0;
	ld	a,0x00
	ld	bc,_CH376_DATA_PORT
	out	(c),a
;source-doc/base-drv/transfers.c:79: ch_issue_token_out_ep0();
	call	_ch_issue_token_out_ep0
;source-doc/base-drv/transfers.c:80: result = ch_long_wait_int_and_get_status(); /* sometimes we get STALL here - seems to be ok to ignore */
	call	_ch_long_wait_int_and_get_status
;source-doc/base-drv/transfers.c:82: if (result == USB_ERR_OK || result == USB_ERR_STALL) {
	ld	a,l
	or	a, a
	jr	Z,l_usb_control_transfer_00108
	sub	a,0x02
	jr	NZ,l_usb_control_transfer_00113
l_usb_control_transfer_00108:
;source-doc/base-drv/transfers.c:83: result = USB_ERR_OK;
	ld	l,0x00
;source-doc/base-drv/transfers.c:84: goto done;
	jr	l_usb_control_transfer_00113
;source-doc/base-drv/transfers.c:87: RETURN_CHECK(result);
l_usb_control_transfer_00112:
;source-doc/base-drv/transfers.c:90: ch_issue_token_in_ep0();
	call	_ch_issue_token_in_ep0
;source-doc/base-drv/transfers.c:91: result = ch_long_wait_int_and_get_status();
	call	_ch_long_wait_int_and_get_status
;source-doc/base-drv/transfers.c:95: done:
l_usb_control_transfer_00113:
;source-doc/base-drv/transfers.c:96: critical_end();
	push	hl
	call	_critical_end
	pop	hl
;source-doc/base-drv/transfers.c:97: return result;
l_usb_control_transfer_00114:
;source-doc/base-drv/transfers.c:98: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/transfers.c:101: usb_dat_in_trnsfer_ext(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
;	---------------------------------
; Function usb_dat_in_trnsfer_ext
; ---------------------------------
_usb_dat_in_trnsfer_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:102: if (buffer != 0 && (uint16_t)buffer < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+5)
	or	a,(ix+4)
	jr	Z,l_usb_dat_in_trnsfer_ext_00102
	ld	a,(ix+5)
	sub	a,0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00102
;source-doc/base-drv/transfers.c:103: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00102:
;source-doc/base-drv/transfers.c:105: if ((uint16_t)endpoint < LOWER_SAFE_RAM_ADDRESS)
	ld	a,(ix+10)
	sub	a,0x80
	jr	NC,l_usb_dat_in_trnsfer_ext_00105
;source-doc/base-drv/transfers.c:106: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trnsfer_ext_00106
l_usb_dat_in_trnsfer_ext_00105:
;source-doc/base-drv/transfers.c:108: return usb_data_in_transfer(buffer, buffer_size, device_address, endpoint);
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
;source-doc/base-drv/transfers.c:109: }
	pop	ix
	ret
;source-doc/base-drv/transfers.c:112: usb_dat_in_trns_n_ext(uint8_t *buffer, uint16_t *buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
;	---------------------------------
; Function usb_dat_in_trns_n_ext
; ---------------------------------
_usb_dat_in_trns_n_ext:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:113: if (buffer != 0 && ((uint16_t)buffer & 0xC000) == 0)
	ld	a,(ix+5)
	or	a,(ix+4)
	jr	Z,l_usb_dat_in_trns_n_ext_00102
	ld	a,(ix+5)
	and	a,0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00102
;source-doc/base-drv/transfers.c:114: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00102:
;source-doc/base-drv/transfers.c:116: if (((uint16_t)endpoint & 0xC000) == 0)
	ld	a,(ix+10)
	and	a,0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00105
;source-doc/base-drv/transfers.c:117: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00105:
;source-doc/base-drv/transfers.c:119: if (((uint16_t)buffer_size & 0xC000) == 0)
	ld	a,(ix+7)
	and	a,0xc0
	jr	NZ,l_usb_dat_in_trns_n_ext_00107
;source-doc/base-drv/transfers.c:120: return USB_BAD_ADDRESS;
	ld	l,0x82
	jr	l_usb_dat_in_trns_n_ext_00108
l_usb_dat_in_trns_n_ext_00107:
;source-doc/base-drv/transfers.c:122: return usb_data_in_transfer_n(buffer, buffer_size, device_address, endpoint);
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
;source-doc/base-drv/transfers.c:123: }
	pop	ix
	ret
;source-doc/base-drv/transfers.c:135: usb_data_in_transfer(uint8_t *buffer, const uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
;	---------------------------------
; Function usb_data_in_transfer
; ---------------------------------
_usb_data_in_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:136: critical_begin();
	call	_critical_begin
;source-doc/base-drv/transfers.c:138: ch_set_usb_address(device_address);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:140: result = ch_data_in_transfer(buffer, buffer_size, endpoint);
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
;source-doc/base-drv/transfers.c:142: critical_end();
	call	_critical_end
;source-doc/base-drv/transfers.c:144: return result;
	ld	hl,(_result)
;source-doc/base-drv/transfers.c:145: }
	pop	ix
	ret
;source-doc/base-drv/transfers.c:157: usb_data_in_transfer_n(uint8_t *buffer, uint8_t *const buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
;	---------------------------------
; Function usb_data_in_transfer_n
; ---------------------------------
_usb_data_in_transfer_n:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:158: critical_begin();
	call	_critical_begin
;source-doc/base-drv/transfers.c:160: ch_set_usb_address(device_address);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:162: result = ch_data_in_transfer_n(buffer, buffer_size, endpoint);
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
;source-doc/base-drv/transfers.c:164: critical_end();
	call	_critical_end
;source-doc/base-drv/transfers.c:166: return result;
	ld	hl,(_result)
;source-doc/base-drv/transfers.c:167: }
	pop	ix
	ret
;source-doc/base-drv/transfers.c:179: usb_data_out_transfer(const uint8_t *buffer, uint16_t buffer_size, const uint8_t device_address, endpoint_param *const endpoint) {
;	---------------------------------
; Function usb_data_out_transfer
; ---------------------------------
_usb_data_out_transfer:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/transfers.c:180: critical_begin();
	call	_critical_begin
;source-doc/base-drv/transfers.c:182: ch_set_usb_address(device_address);
	ld	l,(ix+8)
	call	_ch_set_usb_address
;source-doc/base-drv/transfers.c:184: result = ch_data_out_transfer(buffer, buffer_size, endpoint);
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
;source-doc/base-drv/transfers.c:186: critical_end();
	call	_critical_end
;source-doc/base-drv/transfers.c:188: return result;
	ld	hl,(_result)
;source-doc/base-drv/transfers.c:189: }
	pop	ix
	ret
	SECTION IGNORE
