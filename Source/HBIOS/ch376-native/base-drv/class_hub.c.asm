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
	GLOBAL _cmd_get_hub_descriptor
	GLOBAL _hub_get_descriptor
;--------------------------------------------------------
; Externals used
;--------------------------------------------------------
	GLOBAL _get_usb_device_config
	GLOBAL _find_device_config
	GLOBAL _next_device_config
	GLOBAL _first_device_config
	GLOBAL _find_first_free
	GLOBAL _usbtrn_clear_endpoint_halt
	GLOBAL _usbtrn_set_address
	GLOBAL _usbtrn_set_configuration
	GLOBAL _usbtrn_gfull_cfg_desc
	GLOBAL _usbtrn_get_config_descriptor
	GLOBAL _usbtrn_get_descriptor2
	GLOBAL _usbtrn_get_descriptor
	GLOBAL _usbdev_dat_in_trnsfer_0
	GLOBAL _usbdev_dat_in_trnsfer
	GLOBAL _usbdev_bulk_in_transfer
	GLOBAL _usbdev_blk_out_trnsfer
	GLOBAL _usbdev_control_transfer
	GLOBAL _usb_data_out_transfer
	GLOBAL _usb_data_in_transfer_n
	GLOBAL _usb_data_in_transfer
	GLOBAL _usb_control_transfer
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
;source-doc/base-drv/class_hub.c:7: usb_error hub_get_descriptor(const device_config_hub *const hub_config, hub_descriptor *const hub_description) __sdcccall(1) {
;	---------------------------------
; Function hub_get_descriptor
; ---------------------------------
_hub_get_descriptor:
;source-doc/base-drv/class_hub.c:8: return usb_control_transfer(&cmd_get_hub_descriptor, hub_description, hub_config->address, hub_config->max_packet_size);
	ld	a,l
	ld	c,h
	inc	hl
	ld	b, (hl)
	ld	l, a
	ld	h, c
	ld	a, (hl)
	rlca
	rlca
	rlca
	rlca
	and	a,0x0f
	ld	c, a
	push	bc
	push	de
	ld	hl,_cmd_get_hub_descriptor
	push	hl
	call	_usb_control_transfer
	pop	af
	pop	af
	pop	af
	ld	a, l
;source-doc/base-drv/class_hub.c:9: }
	ret
	SECTION rodata_compiler
_cmd_get_hub_descriptor:
	DEFB +0xa0
	DEFB +0x06
	DEFB +0x00
	DEFB +0x29
	DEFB +0x00
	DEFB +0x00
	DEFW +0x0008
	SECTION IGNORE
