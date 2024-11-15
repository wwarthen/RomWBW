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
	GLOBAL _op_get_cfg_desc
	GLOBAL _op_cap_drv_intf
	GLOBAL _op_capture_hub_driver_interface
	GLOBAL _configure_device
	GLOBAL _op_endpoint_next
	GLOBAL _op_interface_next
	GLOBAL _identify_class_driver
	GLOBAL _parse_endpoint_keyboard
	GLOBAL _op_parse_endpoint
	GLOBAL _op_id_class_drv
	GLOBAL _read_all_configs
	GLOBAL _enumerate_all_devices
;--------------------------------------------------------
; Externals used
;--------------------------------------------------------
	GLOBAL _print_uint16
	GLOBAL _print_string
	GLOBAL _print_hex
	GLOBAL _ffsll_callee
	GLOBAL _ffsll
	GLOBAL _strxfrm_callee
	GLOBAL _strxfrm
	GLOBAL _strupr_fastcall
	GLOBAL _strupr
	GLOBAL _strtok_r_callee
	GLOBAL _strtok_r
	GLOBAL _strtok_callee
	GLOBAL _strtok
	GLOBAL _strstrip_fastcall
	GLOBAL _strstrip
	GLOBAL _strstr_callee
	GLOBAL _strstr
	GLOBAL _strspn_callee
	GLOBAL _strspn
	GLOBAL _strsep_callee
	GLOBAL _strsep
	GLOBAL _strrstrip_fastcall
	GLOBAL _strrstrip
	GLOBAL _strrstr_callee
	GLOBAL _strrstr
	GLOBAL _strrspn_callee
	GLOBAL _strrspn
	GLOBAL _strrev_fastcall
	GLOBAL _strrev
	GLOBAL _strrcspn_callee
	GLOBAL _strrcspn
	GLOBAL _strrchr_callee
	GLOBAL _strrchr
	GLOBAL _strpbrk_callee
	GLOBAL _strpbrk
	GLOBAL _strnlen_callee
	GLOBAL _strnlen
	GLOBAL _strnicmp_callee
	GLOBAL _strnicmp
	GLOBAL _strndup_callee
	GLOBAL _strndup
	GLOBAL _strncpy_callee
	GLOBAL _strncpy
	GLOBAL _strncmp_callee
	GLOBAL _strncmp
	GLOBAL _strnchr_callee
	GLOBAL _strnchr
	GLOBAL _strncat_callee
	GLOBAL _strncat
	GLOBAL _strncasecmp_callee
	GLOBAL _strncasecmp
	GLOBAL _strlwr_fastcall
	GLOBAL _strlwr
	GLOBAL _strlen_fastcall
	GLOBAL _strlen
	GLOBAL _strlcpy_callee
	GLOBAL _strlcpy
	GLOBAL _strlcat_callee
	GLOBAL _strlcat
	GLOBAL _stricmp_callee
	GLOBAL _stricmp
	GLOBAL _strerror_fastcall
	GLOBAL _strerror
	GLOBAL _strdup_fastcall
	GLOBAL _strdup
	GLOBAL _strcspn_callee
	GLOBAL _strcspn
	GLOBAL _strcpy_callee
	GLOBAL _strcpy
	GLOBAL _strcoll_callee
	GLOBAL _strcoll
	GLOBAL _strcmp_callee
	GLOBAL _strcmp
	GLOBAL _strchrnul_callee
	GLOBAL _strchrnul
	GLOBAL _strchr_callee
	GLOBAL _strchr
	GLOBAL _strcat_callee
	GLOBAL _strcat
	GLOBAL _strcasecmp_callee
	GLOBAL _strcasecmp
	GLOBAL _stpncpy_callee
	GLOBAL _stpncpy
	GLOBAL _stpcpy_callee
	GLOBAL _stpcpy
	GLOBAL _memswap_callee
	GLOBAL _memswap
	GLOBAL _memset_wr_callee
	GLOBAL _memset_wr
	GLOBAL _memset_callee
	GLOBAL _memset
	GLOBAL _memrchr_callee
	GLOBAL _memrchr
	GLOBAL _memmove_callee
	GLOBAL _memmove
	GLOBAL _memmem_callee
	GLOBAL _memmem
	GLOBAL _memcpy_callee
	GLOBAL _memcpy
	GLOBAL _memcmp_callee
	GLOBAL _memcmp
	GLOBAL _memchr_callee
	GLOBAL _memchr
	GLOBAL _memccpy_callee
	GLOBAL _memccpy
	GLOBAL _ffsl_fastcall
	GLOBAL _ffsl
	GLOBAL _ffs_fastcall
	GLOBAL _ffs
	GLOBAL __strrstrip__fastcall
	GLOBAL __strrstrip_
	GLOBAL __memupr__callee
	GLOBAL __memupr_
	GLOBAL __memstrcpy__callee
	GLOBAL __memstrcpy_
	GLOBAL __memlwr__callee
	GLOBAL __memlwr_
	GLOBAL _rawmemchr_callee
	GLOBAL _rawmemchr
	GLOBAL _strnset_callee
	GLOBAL _strnset
	GLOBAL _strset_callee
	GLOBAL _strset
	GLOBAL _rindex_callee
	GLOBAL _rindex
	GLOBAL _index_callee
	GLOBAL _index
	GLOBAL _bzero_callee
	GLOBAL _bzero
	GLOBAL _bcopy_callee
	GLOBAL _bcopy
	GLOBAL _bcmp_callee
	GLOBAL _bcmp
	GLOBAL _get_number_of_usb_drives
	GLOBAL _parse_endpoints
	GLOBAL _configure_usb_hub
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
	GLOBAL _x
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
;source-doc/base-drv/enumerate.c:13: void parse_endpoint_keyboard(device_config_keyboard *const keyboard_config, const endpoint_descriptor const *pEndpoint)
;	---------------------------------
; Function parse_endpoint_keyboard
; ---------------------------------
_parse_endpoint_keyboard:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/enumerate.c:15: endpoint_param *const ep = &keyboard_config->endpoints[0];
	inc	hl
	inc	hl
	inc	hl
;source-doc/base-drv/enumerate.c:16: ep->number               = pEndpoint->bEndpointAddress;
	ld	c,l
	ld	b,h
	ex	(sp),hl
	ld	l, e
	ld	h, d
	inc	hl
	inc	hl
	ld	a, (hl)
	pop	hl
	push	hl
	rlca
	and	a,0x0e
	push	bc
	ld	c, a
	ld	a, (hl)
	and	a,0xf1
	or	a, c
	ld	(hl), a
;source-doc/base-drv/enumerate.c:17: ep->toggle               = 0;
	pop	hl
	ld	c,l
	ld	b,h
	res	0, (hl)
;source-doc/base-drv/enumerate.c:18: ep->max_packet_sizex     = calc_max_packet_sizex(pEndpoint->wMaxPacketSize);
	inc	bc
	ld	hl,4
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	a, (hl)
	and	a,0x03
	ld	d, a
	ld	a, e
	ld	(bc), a
	inc	bc
	ld	a, d
	and	a,0x03
	ld	l,a
	ld	a, (bc)
	and	a,0xfc
	or	a, l
	ld	(bc), a
;source-doc/base-drv/enumerate.c:19: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:21: usb_device_type identify_class_driver(_working *const working) {
;	---------------------------------
; Function identify_class_driver
; ---------------------------------
_identify_class_driver:
	push	ix
	ld	ix,0
	add	ix,sp
;source-doc/base-drv/enumerate.c:22: const interface_descriptor *const p = (const interface_descriptor *)working->ptr;
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,27
	add	hl, bc
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
;source-doc/base-drv/enumerate.c:23: if (p->bInterfaceClass == 2)
	ld	hl,5
	add	hl,bc
	ld	a,(hl)
	ld	e,a
	sub	a,0x02
	jr	NZ,l_identify_class_driver_00102
;source-doc/base-drv/enumerate.c:24: return USB_IS_CDC;
	ld	l,0x03
	jr	l_identify_class_driver_00118
l_identify_class_driver_00102:
;source-doc/base-drv/enumerate.c:26: if (p->bInterfaceClass == 8 && (p->bInterfaceSubClass == 6 || p->bInterfaceSubClass == 5) && p->bInterfaceProtocol == 80)
	ld	a, e
	sub	a,0x08
	jr	NZ,l_identify_class_driver_00199
	ld	a,0x01
	jr	l_identify_class_driver_00200
l_identify_class_driver_00199:
	xor	a,a
l_identify_class_driver_00200:
	ld	d,a
	or	a, a
	jr	Z,l_identify_class_driver_00104
	ld	hl,0x0006
	add	hl,bc
	ld	a, (hl)
	cp	a,0x06
	jr	Z,l_identify_class_driver_00107
	sub	a,0x05
	jr	NZ,l_identify_class_driver_00104
l_identify_class_driver_00107:
	ld	hl,0x0007
	add	hl,bc
	ld	a, (hl)
	sub	a,0x50
	jr	NZ,l_identify_class_driver_00104
;source-doc/base-drv/enumerate.c:27: return USB_IS_MASS_STORAGE;
	ld	l,0x02
	jr	l_identify_class_driver_00118
l_identify_class_driver_00104:
;source-doc/base-drv/enumerate.c:29: if (p->bInterfaceClass == 8 && p->bInterfaceSubClass == 4 && p->bInterfaceProtocol == 0)
	ld	a, d
	or	a, a
	jr	Z,l_identify_class_driver_00109
	ld	hl,0x0006
	add	hl,bc
	ld	a, (hl)
	sub	a,0x04
	jr	NZ,l_identify_class_driver_00109
	ld	hl,0x0007
	add	hl,bc
	ld	a, (hl)
	or	a, a
	jr	NZ,l_identify_class_driver_00109
;source-doc/base-drv/enumerate.c:30: return USB_IS_FLOPPY;
	ld	l,0x01
	jr	l_identify_class_driver_00118
l_identify_class_driver_00109:
;source-doc/base-drv/enumerate.c:32: if (p->bInterfaceClass == 9 && p->bInterfaceSubClass == 0 && p->bInterfaceProtocol == 0)
	ld	a, e
	sub	a,0x09
	jr	NZ,l_identify_class_driver_00113
	ld	hl,0x0006
	add	hl,bc
	ld	a, (hl)
	or	a, a
	jr	NZ,l_identify_class_driver_00113
	ld	hl,7
	add	hl, bc
	ld	a, (hl)
	or	a, a
	jr	NZ,l_identify_class_driver_00113
;source-doc/base-drv/enumerate.c:33: return USB_IS_HUB;
	ld	l,0x0f
	jr	l_identify_class_driver_00118
l_identify_class_driver_00113:
;source-doc/base-drv/enumerate.c:35: if (p->bInterfaceClass == 3)
	ld	a, e
	sub	a,0x03
	jr	NZ,l_identify_class_driver_00117
;source-doc/base-drv/enumerate.c:36: return USB_IS_KEYBOARD;
	ld	l,0x04
	jr	l_identify_class_driver_00118
l_identify_class_driver_00117:
;source-doc/base-drv/enumerate.c:38: return USB_IS_UNKNOWN;
	ld	l,0x06
l_identify_class_driver_00118:
;source-doc/base-drv/enumerate.c:39: }
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:41: usb_error op_interface_next(_working *const working) __z88dk_fastcall {
;	---------------------------------
; Function op_interface_next
; ---------------------------------
_op_interface_next:
	ex	de, hl
;source-doc/base-drv/enumerate.c:42: if (--working->interface_count == 0)
	ld	hl,0x0016
	add	hl, de
	ld	a, (hl)
	dec	a
	ld	(hl), a
;source-doc/base-drv/enumerate.c:43: return USB_ERR_OK;
	or	a,a
	jr	NZ,l_op_interface_next_00102
	ld	l,a
	jr	l_op_interface_next_00103
l_op_interface_next_00102:
;source-doc/base-drv/enumerate.c:45: return op_id_class_drv(working);
	ex	de, hl
	call	_op_id_class_drv
	ld	l, a
l_op_interface_next_00103:
;source-doc/base-drv/enumerate.c:46: }
	ret
;source-doc/base-drv/enumerate.c:48: usb_error op_endpoint_next(_working *const working) __sdcccall(1) {
;	---------------------------------
; Function op_endpoint_next
; ---------------------------------
_op_endpoint_next:
	ex	de, hl
;source-doc/base-drv/enumerate.c:49: if (--working->endpoint_count > 0) {
	ld	hl,0x0017
	add	hl, de
	ld	a, (hl)
	dec	a
	ld	(hl), a
	or	a, a
	jr	Z,l_op_endpoint_next_00102
;source-doc/base-drv/enumerate.c:50: working->ptr += ((endpoint_descriptor *)working->ptr)->bLength;
	ld	hl,0x001b
	add	hl, de
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	dec	hl
	ld	a, (bc)
	add	a, c
	ld	c, a
	ld	a,0x00
	adc	a, b
	ld	(hl), c
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:51: return op_parse_endpoint(working);
	ex	de, hl
	jp	_op_parse_endpoint
	jr	l_op_endpoint_next_00103
l_op_endpoint_next_00102:
;source-doc/base-drv/enumerate.c:54: return op_interface_next(working);
	ex	de, hl
	call	_op_interface_next
	ld	a, l
l_op_endpoint_next_00103:
;source-doc/base-drv/enumerate.c:55: }
	ret
;source-doc/base-drv/enumerate.c:57: usb_error op_parse_endpoint(_working *const working) __sdcccall(1) {
;	---------------------------------
; Function op_parse_endpoint
; ---------------------------------
_op_parse_endpoint:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
;source-doc/base-drv/enumerate.c:58: const endpoint_descriptor *endpoint = (endpoint_descriptor *)working->ptr;
	ld	de,0x001c
	ld	c,l
	ld	b,h
	add	hl, de
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	(ix-2),l
	ld	(ix-1),a
;source-doc/base-drv/enumerate.c:59: device_config *const       device   = working->p_current_device;
	ld	hl,29
	add	hl,bc
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
;source-doc/base-drv/enumerate.c:61: switch (working->usb_device) {
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	a, (hl)
	cp	a,0x01
	jr	Z,l_op_parse_endpoint_00102
	cp	a,0x02
	jr	Z,l_op_parse_endpoint_00102
	sub	a,0x04
	jr	Z,l_op_parse_endpoint_00103
	jr	l_op_parse_endpoint_00104
;source-doc/base-drv/enumerate.c:63: case USB_IS_MASS_STORAGE: {
l_op_parse_endpoint_00102:
;source-doc/base-drv/enumerate.c:64: parse_endpoints(device, endpoint);
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	push	de
	call	_parse_endpoints
	pop	af
	pop	af
	pop	bc
;source-doc/base-drv/enumerate.c:65: break;
	jr	l_op_parse_endpoint_00104
;source-doc/base-drv/enumerate.c:68: case USB_IS_KEYBOARD: {
l_op_parse_endpoint_00103:
;source-doc/base-drv/enumerate.c:69: parse_endpoint_keyboard((device_config_keyboard *)device, endpoint);
	ex	de, hl
	push	bc
	ld	e,(ix-2)
	ld	d,(ix-1)
	call	_parse_endpoint_keyboard
	pop	bc
;source-doc/base-drv/enumerate.c:72: }
l_op_parse_endpoint_00104:
;source-doc/base-drv/enumerate.c:74: return op_endpoint_next(working);
	ld	l, c
	ld	h, b
	call	_op_endpoint_next
;source-doc/base-drv/enumerate.c:75: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:78: configure_device(const _working *const working, const interface_descriptor *const interface, device_config *const dev_cfg) {
;	---------------------------------
; Function configure_device
; ---------------------------------
_configure_device:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
;source-doc/base-drv/enumerate.c:79: dev_cfg->interface_number = interface->bInterfaceNumber;
	ld	a,(ix+8)
	ld	(ix-4),a
	ld	a,(ix+9)
	ld	(ix-3),a
	pop	bc
	push	bc
	inc	bc
	inc	bc
	ld	e,(ix+6)
	ld	d,(ix+7)
	inc	de
	inc	de
	ld	a, (de)
	ld	(bc), a
;source-doc/base-drv/enumerate.c:80: dev_cfg->max_packet_size  = working->desc.bMaxPacketSize0;
	ld	a,(ix-4)
	add	a,0x01
	ld	(ix-2),a
	ld	a,(ix-3)
	adc	a,0x00
	ld	(ix-1),a
	ld	c,(ix+4)
	ld	b,(ix+5)
	ld	hl,10
	add	hl,bc
	ld	a, (hl)
	pop	de
	pop	hl
	push	hl
;source-doc/base-drv/enumerate.c:81: dev_cfg->address          = working->current_device_address;
	ld	(hl),a
	push	de
	ld	hl,0x0018
	add	hl,bc
	ld	a, (hl)
	add	a, a
	add	a, a
	add	a, a
	add	a, a
	ld	l, a
	ld	a, (de)
	and	a,0x0f
	or	a, l
	ld	(de), a
;source-doc/base-drv/enumerate.c:82: dev_cfg->type             = working->usb_device;
	pop	de
	push	de
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	ld	a, (hl)
	and	a,0x0f
	ld	l, a
	ld	a, (de)
	and	a,0xf0
	or	a, l
	ld	(de), a
;source-doc/base-drv/enumerate.c:84: return usbtrn_set_configuration(dev_cfg->address, dev_cfg->max_packet_size, working->config.desc.bConfigurationvalue);
	ld	hl,36
	add	hl, bc
	ld	b, (hl)
	ld	l,(ix-2)
	ld	h,(ix-1)
	ld	d, (hl)
	pop	hl
	ld	a,(hl)
	push	hl
	rlca
	rlca
	rlca
	rlca
	and	a,0x0f
	ld	c, d
	push	bc
	push	af
	inc	sp
	call	_usbtrn_set_configuration
;source-doc/base-drv/enumerate.c:85: }
	ld	sp,ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:87: usb_error op_capture_hub_driver_interface(_working *const working) __sdcccall(1) {
;	---------------------------------
; Function op_capture_hub_driver_interface
; ---------------------------------
_op_capture_hub_driver_interface:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	push	af
	push	af
	dec	sp
	ex	de, hl
;source-doc/base-drv/enumerate.c:88: const interface_descriptor *const interface = (interface_descriptor *)working->ptr;
	ld	hl,0x001c
	add	hl,de
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
	ld	(ix-4),l
	ld	(ix-3),a
;source-doc/base-drv/enumerate.c:92: working->hub_config = &hub_config;
	ld	hl,0x0019
	add	hl, de
	ld	(ix-2),l
	ld	(ix-1),h
	ld	hl,0
	add	hl, sp
	ld	c, l
	ld	l,(ix-2)
	ld	b,h
	ld	h,(ix-1)
	ld	(hl), c
	inc	hl
	ld	(hl), b
;source-doc/base-drv/enumerate.c:94: hub_config.type = USB_IS_HUB;
	ld	hl,0
	add	hl, sp
	ld	a, (hl)
	or	a,0x0f
	ld	(hl), a
;source-doc/base-drv/enumerate.c:95: CHECK(configure_device(working, interface, (device_config *const)&hub_config));
	push	de
	ld	hl,2
	add	hl, sp
	push	hl
	ld	l,(ix-4)
	ld	h,(ix-3)
	push	hl
	push	de
	call	_configure_device
	pop	af
	pop	af
	pop	af
	pop	de
	ld	a, l
	inc	l
	dec	l
	jr	NZ,l_op_capture_hub_driver_interface_00103
;source-doc/base-drv/enumerate.c:96: RETURN_CHECK(configure_usb_hub(working));
	ex	de, hl
	call	_configure_usb_hub
	ld	a, l
;source-doc/base-drv/enumerate.c:97: done:
l_op_capture_hub_driver_interface_00103:
;source-doc/base-drv/enumerate.c:98: return result;
;source-doc/base-drv/enumerate.c:99: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:101: usb_error op_cap_drv_intf(_working *const working) __z88dk_fastcall {
;	---------------------------------
; Function op_cap_drv_intf
; ---------------------------------
_op_cap_drv_intf:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	c, l
	ld	b, h
	ld	hl, -16
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/enumerate.c:104: const interface_descriptor *const interface = (interface_descriptor *)working->ptr;
	ld	(ix-2),c
	ld	l, c
	ld	(ix-1),b
	ld	h,b
	ld	de,0x001b
	add	hl, de
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	dec	hl
	ld	c, e
	ld	b, d
;source-doc/base-drv/enumerate.c:106: working->ptr += interface->bLength;
	ld	a, (bc)
	add	a, e
	ld	e, a
	ld	a,0x00
	adc	a, d
	ld	(hl), e
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:107: working->endpoint_count   = interface->bNumEndpoints;
	ld	a,(ix-2)
	add	a,0x17
	ld	e, a
	ld	a,(ix-1)
	adc	a,0x00
	ld	d, a
	ld	l, c
	ld	h, b
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(de), a
;source-doc/base-drv/enumerate.c:108: working->p_current_device = NULL;
	ld	a,(ix-2)
	add	a,0x1d
	ld	(ix-4),a
	ld	l,a
	ld	a,(ix-1)
	adc	a,0x00
	ld	(ix-3),a
	ld	h,a
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:110: switch (working->usb_device) {
	ld	l,(ix-2)
	ld	h,(ix-1)
	inc	hl
	inc	hl
	ld	a, (hl)
	cp	a,0x06
	jr	Z,l_op_cap_drv_intf_00104
	sub	a,0x0f
	jr	NZ,l_op_cap_drv_intf_00107
;source-doc/base-drv/enumerate.c:112: CHECK(op_capture_hub_driver_interface(working))
	ld	l,(ix-2)
	ld	h,(ix-1)
	call	_op_capture_hub_driver_interface
	or	a, a
	jr	Z,l_op_cap_drv_intf_00112
	jr	l_op_cap_drv_intf_00113
;source-doc/base-drv/enumerate.c:116: case USB_IS_UNKNOWN: {
l_op_cap_drv_intf_00104:
;source-doc/base-drv/enumerate.c:118: memset(&unkown_dev_cfg, 0, sizeof(device_config));
	push	bc
	ld	hl,2
	add	hl, sp
	ld	b,0x06
l_op_cap_drv_intf_00154:
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_op_cap_drv_intf_00154
	pop	bc
;source-doc/base-drv/enumerate.c:119: working->p_current_device = &unkown_dev_cfg;
	ld	hl,0
	add	hl, sp
	ex	de, hl
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/base-drv/enumerate.c:120: CHECK(configure_device(working, interface, &unkown_dev_cfg));
	ld	hl,0
	add	hl, sp
	push	hl
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_configure_device
	pop	af
	pop	af
	pop	af
	ld	a, l
	or	a, a
	jr	Z,l_op_cap_drv_intf_00112
	jr	l_op_cap_drv_intf_00113
;source-doc/base-drv/enumerate.c:124: default: {
l_op_cap_drv_intf_00107:
;source-doc/base-drv/enumerate.c:125: device_config *dev_cfg = find_first_free();
	push	bc
	call	_find_first_free
;source-doc/base-drv/enumerate.c:126: if (dev_cfg == NULL)
	pop	bc
	ld	a,h
	or	a,l
	ex	de,hl
	jr	NZ,l_op_cap_drv_intf_00109
;source-doc/base-drv/enumerate.c:127: return USB_ERR_OUT_OF_MEMORY;
	ld	l,0x83
	jr	l_op_cap_drv_intf_00114
l_op_cap_drv_intf_00109:
;source-doc/base-drv/enumerate.c:128: working->p_current_device = dev_cfg;
	ld	l,(ix-4)
	ld	h,(ix-3)
	ld	(hl), e
	inc	hl
	ld	(hl), d
;source-doc/base-drv/enumerate.c:129: CHECK(configure_device(working, interface, dev_cfg));
	push	de
	push	bc
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	call	_configure_device
	pop	af
	pop	af
	pop	af
	ld	a, l
	or	a, a
	jr	NZ,l_op_cap_drv_intf_00113
;source-doc/base-drv/enumerate.c:132: }
l_op_cap_drv_intf_00112:
;source-doc/base-drv/enumerate.c:134: result = op_parse_endpoint(working);
	ld	l,(ix-2)
	ld	h,(ix-1)
	call	_op_parse_endpoint
;source-doc/base-drv/enumerate.c:136: done:
l_op_cap_drv_intf_00113:
;source-doc/base-drv/enumerate.c:137: return result;
	ld	l, a
l_op_cap_drv_intf_00114:
;source-doc/base-drv/enumerate.c:138: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:140: usb_error op_id_class_drv(_working *const working) __sdcccall(1) {
;	---------------------------------
; Function op_id_class_drv
; ---------------------------------
_op_id_class_drv:
	ex	de, hl
;source-doc/base-drv/enumerate.c:141: const interface_descriptor *const ptr = (const interface_descriptor *)working->ptr;
	ld	hl,0x001c
	add	hl,de
	ld	a, (hl)
	dec	hl
	ld	l, (hl)
;source-doc/base-drv/enumerate.c:143: working->usb_device = ptr->bLength > 5 ? identify_class_driver(working) : 0;
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	ld	h, a
	ld	l, (hl)
	ld	a,0x05
	sub	a, l
	jr	NC,l_op_id_class_drv_00103
	push	bc
	push	de
	push	de
	call	_identify_class_driver
	pop	af
	ld	a, l
	pop	de
	pop	bc
	jr	l_op_id_class_drv_00104
l_op_id_class_drv_00103:
	xor	a, a
l_op_id_class_drv_00104:
	ld	(bc), a
;source-doc/base-drv/enumerate.c:145: return op_cap_drv_intf(working);
	ex	de, hl
	call	_op_cap_drv_intf
	ld	a, l
;source-doc/base-drv/enumerate.c:146: }
	ret
;source-doc/base-drv/enumerate.c:148: usb_error op_get_cfg_desc(_working *const working) __sdcccall(1) {
;	---------------------------------
; Function op_get_cfg_desc
; ---------------------------------
_op_get_cfg_desc:
	push	ix
	ld	ix,0
	add	ix,sp
	push	af
	ex	de, hl
;source-doc/base-drv/enumerate.c:149: memset(working->config.buffer, 0, MAX_CONFIG_SIZE);
	ld	hl,0x001f
	add	hl, de
	pop	af
	push	hl
	ld	b,0x46
l_op_get_cfg_desc_00113:
	xor	a, a
	ld	(hl), a
	inc	hl
	ld	(hl), a
	inc	hl
	djnz	l_op_get_cfg_desc_00113
;source-doc/base-drv/enumerate.c:151: const uint8_t max_packet_size = working->desc.bMaxPacketSize0;
	ld	c, e
	ld	b, d
	inc	bc
	inc	bc
	inc	bc
	ld	hl,7
	add	hl, bc
	ld	a, (hl)
;source-doc/base-drv/enumerate.c:154: working->config.buffer));
	ld	c, e
	ld	b, d
	ld	hl,24
	add	hl, bc
	ld	b, (hl)
	ld	l, e
	ld	h, d
	push	bc
	ld	bc,0x0015
	add	hl, bc
	pop	bc
	ld	c, (hl)
	push	de
	ld	l,(ix-2)
	ld	h,(ix-1)
	push	hl
	ld	h,0x8c
	ld	l,a
	push	hl
	push	bc
	call	_usbtrn_gfull_cfg_desc
	pop	af
	pop	af
	pop	af
	pop	de
	ld	a, l
	ld	(_result), a
	ld	a,(_result)
	or	a, a
	jr	NZ,l_op_get_cfg_desc_00103
;source-doc/base-drv/enumerate.c:156: working->ptr             = (working->config.buffer + sizeof(config_descriptor));
	ld	hl,0x001b
	add	hl, de
	ld	a, e
	add	a,0x1f
	ld	c, a
	ld	a, d
	adc	a,0x00
	ld	b, a
	ld	a, c
	add	a,0x09
	ld	c, a
	ld	a, b
	adc	a,0x00
	ld	(hl), c
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:157: working->interface_count = working->config.desc.bNumInterfaces;
	ld	hl,0x0016
	add	hl, de
	ld	c, l
	ld	b, h
	pop	hl
	push	hl
	inc	hl
	inc	hl
	inc	hl
	inc	hl
	ld	a, (hl)
	ld	(bc), a
;source-doc/base-drv/enumerate.c:159: return op_id_class_drv(working);
	ex	de, hl
	call	_op_id_class_drv
	jr	l_op_get_cfg_desc_00104
;source-doc/base-drv/enumerate.c:160: done:
l_op_get_cfg_desc_00103:
;source-doc/base-drv/enumerate.c:161: return result;
	ld	hl,_result
	ld	a, (hl)
l_op_get_cfg_desc_00104:
;source-doc/base-drv/enumerate.c:162: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:164: usb_error read_all_configs(enumeration_state *const state) {
;	---------------------------------
; Function read_all_configs
; ---------------------------------
_read_all_configs:
	push	ix
	ld	ix,0
	add	ix,sp
	ld	hl, -171
	add	hl, sp
	ld	sp, hl
;source-doc/base-drv/enumerate.c:169: memset(&working, 0, sizeof(_working));
	ld	hl,0
	add	hl, sp
	ld	(hl),0x00
	ld	e, l
	ld	d, h
	inc	de
	ld	bc,0x00aa
	ldir
;source-doc/base-drv/enumerate.c:170: working.state = state;
	ld	a,(ix+4)
	ld	hl,0
	add	hl, sp
	ld	(hl), a
	ld	a,(ix+5)
	inc	hl
	ld	(hl), a
;source-doc/base-drv/enumerate.c:172: CHECK(usbtrn_get_descriptor(&working.desc));
	ld	hl,3
	add	hl, sp
	push	hl
	call	_usbtrn_get_descriptor
	pop	af
	ld	a, l
	or	a, a
	jr	NZ,l_read_all_configs_00108
;source-doc/base-drv/enumerate.c:174: state->next_device_address++;
	ld	e,(ix+4)
	ld	d,(ix+5)
	ld	a, (de)
	inc	a
	ld	c,a
	ld	(de), a
;source-doc/base-drv/enumerate.c:175: working.current_device_address = state->next_device_address;
	ld	hl,24
	add	hl, sp
	ld	(hl), c
;source-doc/base-drv/enumerate.c:176: CHECK(usbtrn_set_address(working.current_device_address));
	ld	l, c
	call	_usbtrn_set_address
	ld	a, l
;source-doc/base-drv/enumerate.c:178: for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
	or	a,a
	jr	NZ,l_read_all_configs_00108
	ld	c,a
l_read_all_configs_00110:
	ld	hl,20
	add	hl, sp
	ld	b, (hl)
	ld	a, c
	sub	a, b
	jr	NC,l_read_all_configs_00107
;source-doc/base-drv/enumerate.c:179: working.config_index = config_index;
	inc	hl
	ld	(hl), c
;source-doc/base-drv/enumerate.c:181: CHECK(op_get_cfg_desc(&working));
	push	bc
	ld	hl,2
	add	hl, sp
	call	_op_get_cfg_desc
	pop	bc
	or	a, a
	jr	NZ,l_read_all_configs_00108
;source-doc/base-drv/enumerate.c:178: for (uint8_t config_index = 0; config_index < working.desc.bNumConfigurations; config_index++) {
	inc	c
	jr	l_read_all_configs_00110
l_read_all_configs_00107:
;source-doc/base-drv/enumerate.c:184: return USB_ERR_OK;
	ld	l,0x00
	jr	l_read_all_configs_00112
;source-doc/base-drv/enumerate.c:185: done:
l_read_all_configs_00108:
;source-doc/base-drv/enumerate.c:186: return result;
	ld	l, a
l_read_all_configs_00112:
;source-doc/base-drv/enumerate.c:187: }
	ld	sp, ix
	pop	ix
	ret
;source-doc/base-drv/enumerate.c:189: usb_error enumerate_all_devices(void) {
;	---------------------------------
; Function enumerate_all_devices
; ---------------------------------
_enumerate_all_devices:
	push	ix
	dec	sp
;source-doc/base-drv/enumerate.c:190: _usb_state *const work_area = get_usb_work_area();
;source-doc/base-drv/enumerate.c:192: memset(&state, 0, sizeof(enumeration_state));
	ld	hl,0
	add	hl, sp
	ld	e,l
	ld	d,h
;source-doc/base-drv/enumerate.c:193: state.next_device_address = 0;
	xor	a,a
	ld	(hl),a
	ld	(de), a
;source-doc/base-drv/enumerate.c:195: usb_error result = read_all_configs(&state);
	push	de
	push	de
	call	_read_all_configs
	pop	af
	ld	c, l
	pop	de
;source-doc/base-drv/enumerate.c:197: work_area->count_of_detected_usb_devices = state.next_device_address;
	ld	a, (de)
	ld	((_x + 1)),a
;source-doc/base-drv/enumerate.c:200: return result;
	ld	l, c
;source-doc/base-drv/enumerate.c:201: }
	inc	sp
	pop	ix
	ret
	SECTION IGNORE
