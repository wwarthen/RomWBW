;
; TERMQRY - terminal probe and configuration tool for RomWBW consoles
;
; Default mode probes terminal query/response behavior.
; -config mode edits TUNE.CFG for later use by TUNE and other apps.
;
	.org	$100

restart		.equ	$0000
bdos		.equ	$0005
cmdtail		.equ	$0080
dma_default	.equ	$0080
esc		.equ	27

BF_CIO		.equ	$00
BF_CIOIN	.equ	BF_CIO + 0
BF_CIOOUT	.equ	BF_CIO + 1
BF_CIOIST	.equ	BF_CIO + 2
CIO_CONSOLE	.equ	$80

CFGF_ANSI	.equ	$01

TERM_PLAIN	.equ	0
TERM_VTXXX	.equ	1
TERM_ANSI	.equ	2

CFGVER		.equ	1
CFG_DFL_ROWS	.equ	24
CFG_DFL_COLS	.equ	80
CFG_MIN_ROWS	.equ	8
CFG_MAX_ROWS	.equ	99
CFG_MIN_COLS	.equ	20
CFG_MAX_COLS	.equ	160
TUNE_ORG_ROW	.equ	5
TUNE_ORG_COL	.equ	5

	ld	(stksav),sp
	ld	sp,stack

	call	cfg_defaults
	call	cfg_load
	call	parse_args

	call	crlf2
	ld	de,msg_banner
	call	prtstr
	call	crlf
	ld	de,msg_note
	call	prtstr
	call	crlf2

	ld	a,(mode_config)
	or	a
	jr	z,run_probe
	call	config_mode
	jr	app_exit

run_probe:
	call	show_cfg_status
	call	probe_mode

app_exit:
	ld	sp,(stksav)
	jp	restart

; ------------------------------------------------------------
; Probe mode
; ------------------------------------------------------------

probe_mode:
	call	flush_input

	ld	de,msg_q1
	call	prtstr
	call	crlf
	call	flush_input
	ld	de,msg_send
	call	prtstr
	call	crlf
	ld	hl,seq_da
	call	send_seq
	ld	de,msg_wait
	call	prtstr
	call	crlf
	ld	de,buf_da
	ld	b,63
	ld	a,'c'
	call	read_reply
	jr	c,probe_da_timeout
	ld	de,msg_reply
	call	prtstr
	ld	hl,buf_da
	call	prtbufhex
	call	crlf
	ld	hl,buf_da
	call	parse_da
	jr	probe_da_done

probe_da_timeout:
	xor	a
	ld	(flag_ansi),a
	ld	(flag_vt),a
	ld	de,msg_no_reply
	call	prtstr
	call	crlf

probe_da_done:
	ld	de,msg_q2
	call	prtstr
	call	crlf
	call	flush_input
	ld	de,msg_send
	call	prtstr
	call	crlf
	ld	hl,seq_move_br
	call	send_seq
	ld	hl,seq_cpr
	call	send_seq
	ld	de,msg_wait
	call	prtstr
	call	crlf
	ld	de,buf_cpr
	ld	b,63
	ld	a,'R'
	call	read_reply
	jr	c,probe_cpr_timeout
	ld	de,msg_reply
	call	prtstr
	ld	hl,buf_cpr
	call	prtbufhex
	call	crlf
	ld	hl,buf_cpr
	call	parse_cpr
	jr	probe_cpr_done

probe_cpr_timeout:
	xor	a
	ld	(flag_dim),a
	ld	de,msg_no_reply
	call	prtstr
	call	crlf

probe_cpr_done:
	call	crlf2
	ld	de,msg_sum
	call	prtstr
	call	crlf

	ld	de,msg_vt
	call	prtstr
	ld	a,(flag_vt)
	call	prtyn
	call	crlf

	ld	de,msg_ansi
	call	prtstr
	ld	a,(flag_ansi)
	call	prtyn
	call	crlf

	ld	de,msg_dims
	call	prtstr
	ld	a,(flag_dim)
	or	a
	jr	z,probe_dims_na
	ld	a,(col_val)
	call	prtdec
	ld	a,' '
	call	prtchr
	ld	a,'x'
	call	prtchr
	ld	a,' '
	call	prtchr
	ld	a,(row_val)
	call	prtdec
	ld	de,msg_rc
	call	prtstr
	jr	probe_dims_done
probe_dims_na:
	ld	de,msg_unknown
	call	prtstr
probe_dims_done:
	call	crlf2
	ld	de,msg_hint
	call	prtstr
	call	crlf2
	ret

; ------------------------------------------------------------
; Config mode
; ------------------------------------------------------------

config_mode:
	ld	de,msg_cfg_mode
	call	prtstr
	call	crlf2

	call	show_cfg_status
	call	ask_term_type
	call	ask_ansi

	ld	a,(cfg_term)
	or	a
	jr	nz,config_tune
	ld	a,(cfg_flags)
	and	CFGF_ANSI
	jr	z,config_save

config_tune:
	call	size_tune

config_save:
	call	cfg_save
	ld	a,(cfg_term)
	or	a
	jr	nz,config_save_clear
	ld	a,(cfg_flags)
	and	CFGF_ANSI
	jr	z,config_save_show
config_save_clear:
	call	ansi_clear_home
config_save_show:
	ld	de,msg_cfg_saved
	call	prtstr
	call	crlf
	call	show_cfg_summary
	call	crlf2
	ret

ask_term_type:
ask_term_type0:
	ld	de,msg_term_menu
	call	prtstr
	call	crlf
	ld	de,msg_term_prompt
	call	prtstr
	call	show_term_name
	ld	de,msg_prompt_end
	call	prtstr
	call	conin_block
	cp	13
	jr	z,ask_term_type_keep
	push	af
	call	prtchr
	call	crlf
	pop	af
	call	upcase
	cp	'P'
	jr	z,ask_term_type_plain
	cp	'V'
	jr	z,ask_term_type_vt
	cp	'A'
	jr	z,ask_term_type_ansi
	jr	ask_term_type0
ask_term_type_keep:
	call	crlf
	ret
ask_term_type_plain:
	xor	a
	ld	(cfg_term),a
	ret
ask_term_type_vt:
	ld	a,TERM_VTXXX
	ld	(cfg_term),a
	ret
ask_term_type_ansi:
	ld	a,TERM_ANSI
	ld	(cfg_term),a
	ret

ask_ansi:
ask_ansi0:
	ld	de,msg_ansi_prompt
	call	prtstr
	ld	a,(cfg_flags)
	and	CFGF_ANSI
	call	prtyn
	ld	de,msg_prompt_end
	call	prtstr
	call	conin_block
	cp	13
	jr	z,ask_ansi_keep
	push	af
	call	prtchr
	call	crlf
	pop	af
	call	upcase
	cp	'Y'
	jr	z,ask_ansi_yes
	cp	'N'
	jr	z,ask_ansi_no
	jr	ask_ansi0
ask_ansi_keep:
	call	crlf
	ret
ask_ansi_yes:
	ld	a,(cfg_flags)
	or	CFGF_ANSI
	ld	(cfg_flags),a
	ret
ask_ansi_no:
	ld	a,(cfg_flags)
	and	0FFh - CFGF_ANSI
	ld	(cfg_flags),a
	ret

size_tune:
size_tune0:
	call	ansi_clear_home
	ld	de,msg_tune_title
	call	prtstr
	call	crlf
	ld	de,msg_tune_keys
	call	prtstr
	call	crlf
	ld	de,msg_tune_curr
	call	prtstr
	ld	a,(cfg_cols)
	call	prtdec
	ld	a,' '
	call	prtchr
	ld	a,'x'
	call	prtchr
	ld	a,' '
	call	prtchr
	ld	a,(cfg_rows)
	call	prtdec
	call	crlf2
	call	size_draw_grid

	ld	b,4
	ld	c,1
	call	ansi_at
	call	conin_block
	cp	27
	jr	z,size_tune_exit
	cp	'c'
	jp	z,size_cols_dec
	cp	'C'
	jp	z,size_cols_inc
	cp	'r'
	jp	z,size_rows_dec
	cp	'R'
	jp	z,size_rows_inc
	jp	size_tune0

size_tune_exit:
	call	flush_input
	call	ansi_clear_home
	ret

size_cols_dec:
	ld	a,(cfg_cols)
	cp	CFG_MIN_COLS
	jp	z,size_tune0
	dec	a
	ld	(cfg_cols),a
	call	flush_input
	jp	size_tune0

size_cols_inc:
	ld	a,(cfg_cols)
	cp	CFG_MAX_COLS
	jp	z,size_tune0
	inc	a
	ld	(cfg_cols),a
	call	flush_input
	jp	size_tune0

size_rows_dec:
	ld	a,(cfg_rows)
	cp	CFG_MIN_ROWS
	jp	z,size_tune0
	dec	a
	ld	(cfg_rows),a
	call	flush_input
	jp	size_tune0

size_rows_inc:
	ld	a,(cfg_rows)
	cp	CFG_MAX_ROWS
	jp	z,size_tune0
	inc	a
	ld	(cfg_rows),a
	call	flush_input
	jp	size_tune0

size_draw_grid:
	push	af
	push	bc
	push	de
	push	hl

	ld	b,TUNE_ORG_ROW
	ld	c,TUNE_ORG_COL
	call	ansi_at
	ld	a,'+'
	call	prtchr

	ld	d,2
size_hline_loop:
	ld	a,(cfg_cols)
	cp	d
	jr	c,size_hline_done
	ld	b,TUNE_ORG_ROW
	ld	a,d
	add	a,TUNE_ORG_COL - 1
	ld	c,a
	call	ansi_at
	ld	a,'-'
	call	prtchr
	inc	d
	jr	size_hline_loop
size_hline_done:

	ld	d,2
size_vline_loop:
	ld	a,(cfg_rows)
	cp	d
	jr	c,size_vline_done
	ld	a,d
	add	a,TUNE_ORG_ROW - 1
	ld	b,a
	ld	c,TUNE_ORG_COL
	call	ansi_at
	ld	a,'|'
	call	prtchr
	inc	d
	jr	size_vline_loop
size_vline_done:
	ld	b,TUNE_ORG_ROW - 1
	ld	c,TUNE_ORG_COL
	call	ansi_at
	ld	a,'1'
	call	prtchr

	ld	b,TUNE_ORG_ROW
	ld	c,TUNE_ORG_COL - 1
	call	ansi_at
	ld	a,'1'
	call	prtchr

	ld	d,10
size_top_scale_loop:
	ld	a,(cfg_cols)
	cp	d
	jr	c,size_top_scale_done
	ld	b,TUNE_ORG_ROW - 1
	ld	a,d
	add	a,TUNE_ORG_COL - 1
	ld	c,a
	call	ansi_at
	ld	a,d
	push	de
	call	prtdec
	pop	de
	ld	a,d
	add	a,10
	jr	c,size_top_scale_done
	ld	d,a
	jr	size_top_scale_loop
size_top_scale_done:

	ld	d,10
size_left_scale_loop:
	ld	a,(cfg_rows)
	cp	d
	jr	c,size_left_scale_done
	ld	a,d
	add	a,TUNE_ORG_ROW - 1
	ld	b,a
	ld	c,1
	call	ansi_at
	ld	a,d
	push	de
	call	prtdec
	pop	de
	ld	a,d
	add	a,10
	jr	c,size_left_scale_done
	ld	d,a
	jr	size_left_scale_loop
size_left_scale_done:

	ld	b,TUNE_ORG_ROW
	ld	a,(cfg_cols)
	add	a,TUNE_ORG_COL - 1
	ld	c,a
	call	ansi_at
	ld	a,'C'
	call	prtchr

	ld	a,(cfg_rows)
	add	a,TUNE_ORG_ROW - 1
	ld	b,a
	ld	c,TUNE_ORG_COL
	call	ansi_at
	ld	a,'R'
	call	prtchr

	ld	a,(cfg_rows)
	add	a,TUNE_ORG_ROW - 1
	ld	b,a
	ld	a,(cfg_cols)
	add	a,TUNE_ORG_COL - 1
	ld	c,a
	call	ansi_at
	ld	a,'X'
	call	prtchr

	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

; ------------------------------------------------------------
; Config file handling
; ------------------------------------------------------------

#include "../../lib/termcfg.inc"

show_cfg_status:
	ld	a,(cfg_found)
	or	a
	jr	z,show_cfg_status_default
	ld	de,msg_cfg_found
	call	prtstr
	call	crlf
	jr	show_cfg_status_sum
show_cfg_status_default:
	ld	de,msg_cfg_default
	call	prtstr
	call	crlf
show_cfg_status_sum:
	call	show_cfg_summary
	call	crlf2
	call	flush_input
	ret

show_cfg_summary:
	ld	de,msg_cfg_term
	call	prtstr
	call	show_term_name
	call	crlf
	ld	de,msg_cfg_ansi
	call	prtstr
	ld	a,(cfg_flags)
	and	CFGF_ANSI
	call	prtyn
	call	crlf
	ld	de,msg_cfg_size
	call	prtstr
	ld	a,(cfg_cols)
	call	prtdec
	ld	a,' '
	call	prtchr
	ld	a,'x'
	call	prtchr
	ld	a,' '
	call	prtchr
	ld	a,(cfg_rows)
	call	prtdec
	ret

show_term_name:
	ld	a,(cfg_term)
	cp	TERM_VTXXX
	jr	z,show_term_vt
	cp	TERM_ANSI
	jr	z,show_term_ansi
	ld	de,msg_term_plain
	jr	show_term_emit
show_term_vt:
	ld	de,msg_term_vt
	jr	show_term_emit
show_term_ansi:
	ld	de,msg_term_ansi
show_term_emit:
	jp	prtstr

; ------------------------------------------------------------
; Command tail parsing
; ------------------------------------------------------------

parse_args:
	ld	a,(cmdtail)
	or	a
	ret	z
	ld	b,a
	ld	hl,cmdtail+1
parse_args_skip:
	ld	a,b
	or	a
	ret	z
	ld	a,(hl)
	cp	' '
	jr	nz,parse_args_chk
	inc	hl
	dec	b
	jr	parse_args_skip
parse_args_chk:
	cp	'-'
	jr	z,parse_args_opt
	cp	'/'
	ret	nz
parse_args_opt:
	inc	hl
	dec	b
	ld	de,str_config
parse_args_cmp:
	ld	a,(de)
	or	a
	jr	z,parse_args_yes
	ld	a,b
	or	a
	ret	z
	ld	a,(hl)
	call	upcase
	ld	c,a
	ld	a,(de)
	cp	c
	ret	nz
	inc	hl
	inc	de
	dec	b
	jr	parse_args_cmp
parse_args_yes:
	ld	a,$FF
	ld	(mode_config),a
	ret

; ------------------------------------------------------------
; Parse helpers
; ------------------------------------------------------------

parse_da:
	xor	a
	ld	(flag_ansi),a
	ld	(flag_vt),a
	call	find_csi
	ret	c
	ld	a,$FF
	ld	(flag_ansi),a
	ld	a,(hl)
	cp	'?'
	ret	nz
	ld	a,$FF
	ld	(flag_vt),a
	ret

parse_cpr:
	xor	a
	ld	(flag_dim),a
	call	find_csi
	ret	c
	call	parse_u8
	ret	c
	ld	(row_val),a
	ld	a,(hl)
	cp	3Bh
	ret	nz
	inc	hl
	call	parse_u8
	ret	c
	ld	(col_val),a
	ld	a,(hl)
	cp	'R'
	ret	nz
	ld	a,$FF
	ld	(flag_dim),a
	ret

find_csi:
fcsi0:
	ld	a,(hl)
	or	a
	jr	z,fcsi_fail
	cp	esc
	jr	nz,fcsi_next
	inc	hl
	ld	a,(hl)
	cp	'['
	jr	z,fcsi_hit
	jr	fcsi0
fcsi_next:
	inc	hl
	jr	fcsi0
fcsi_hit:
	inc	hl
	or	a
	ret
fcsi_fail:
	scf
	ret

parse_u8:
	ld	e,0
	ld	b,0
pu80:
	ld	a,(hl)
	cp	'0'
	jr	c,pu8done
	cp	':'
	jr	nc,pu8done
	inc	b
	ld	a,e
	add	a,a
	ld	d,a
	add	a,a
	add	a,a
	add	a,d
	ld	e,a
	ld	a,(hl)
	sub	'0'
	add	a,e
	ld	e,a
	inc	hl
	jr	pu80
pu8done:
	ld	a,b
	or	a
	jr	z,pu8fail
	ld	a,e
	or	a
	ret
pu8fail:
	scf
	ret

upcase:
	cp	'a'
	ret	c
	cp	'z'+1
	ret	nc
	sub	20h
	ret

; ------------------------------------------------------------
; Console and ANSI helpers
; ------------------------------------------------------------

send_seq:
ss0:
	ld	a,(hl)
	or	a
	ret	z
	call	prtchr
	inc	hl
	jr	ss0

read_reply:
	ld	(term_chr),a
	ld	a,b
	or	a
	jr	z,rr_fail
	ld	h,$40
	ld	l,$00
rr_wait:
	call	conin_nb
	or	a
	jr	nz,rr_got
	dec	hl
	ld	a,h
	or	l
	jr	nz,rr_wait
	scf
	jr	rr_done
rr_got:
	ld	(last_chr),a
	ld	(de),a
	inc	de
	dec	b
	ld	a,(last_chr)
	ld	c,a
	ld	a,(term_chr)
	cp	c
	jr	z,rr_ok
	ld	a,b
	or	a
	jr	z,rr_ok
	ld	h,$10
	ld	l,$00
	jr	rr_wait
rr_ok:
	xor	a
	ld	(de),a
	or	a
rr_done:
	ret
rr_fail:
	scf
	ret

flush_input:
fi0:
	call	conin_nb
	or	a
	ret	z
	jr	fi0

conin_nb:
	push	bc
	push	de
	push	hl
	ld	c,CIO_CONSOLE
	ld	b,BF_CIOIST
	rst	08
	or	a
	jr	z,conin_nb_none
	ld	c,CIO_CONSOLE
	ld	b,BF_CIOIN
	rst	08
	ld	a,e
	jr	conin_nb_done
conin_nb_none:
	xor	a
conin_nb_done:
	pop	hl
	pop	de
	pop	bc
	ret

conin_block:
	push	bc
	push	de
	push	hl
	ld	c,CIO_CONSOLE
	ld	b,BF_CIOIN
	rst	08
	ld	a,e
	pop	hl
	pop	de
	pop	bc
	ret

ansi_clear_home:
	ld	hl,seq_cls
	jp	send_seq

ansi_at:
	push	af
	push	bc
	push	de
	push	hl
	ld	a,esc
	call	prtchr
	ld	a,'['
	call	prtchr
	push	bc
	ld	a,b
	call	prtdec
	ld	a,3Bh
	call	prtchr
	pop	bc
	ld	a,c
	call	prtdec
	ld	a,'H'
	call	prtchr
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

prtchr:
	push	bc
	push	de
	push	hl
	ld	e,a
	ld	c,$02
	call	bdos
	pop	hl
	pop	de
	pop	bc
	ret

prtstr:
	ld	a,(de)
	or	a
	ret	z
	call	prtchr
	inc	de
	jr	prtstr

crlf:
	ld	a,13
	call	prtchr
	ld	a,10
	jp	prtchr

crlf2:
	call	crlf
	jp	crlf

prthex:
	push	af
	rrca
	rrca
	rrca
	rrca
	call	hexnyb
	pop	af
	call	hexnyb
	ret

hexnyb:
	and	$0F
	add	a,'0'
	cp	':'
	jr	c,hexnyb1
	add	a,7
hexnyb1:
	jp	prtchr

prtbufhex:
	ld	a,'['
	call	prtchr
pbh0:
	ld	a,(hl)
	or	a
	jr	z,pbh1
	call	prthex
	ld	a,' '
	call	prtchr
	inc	hl
	jr	pbh0
pbh1:
	ld	a,']'
	jp	prtchr

prtyn:
	or	a
	jr	z,prtyn_no
	ld	de,msg_yes
	jp	prtstr
prtyn_no:
	ld	de,msg_no
	jp	prtstr

prtdec:
	ld	b,0
pd_hund:
	cp	100
	jr	c,pd_tens
	sub	100
	inc	b
	jr	pd_hund
pd_tens:
	ld	c,0
pd_tens1:
	cp	10
	jr	c,pd_ones
	sub	10
	inc	c
	jr	pd_tens1
pd_ones:
	ld	d,a
	ld	a,b
	or	a
	jr	z,pd_tens2
	add	a,'0'
	call	prtchr
pd_tens2:
	ld	a,c
	or	a
	jr	nz,pd_tens3
	ld	a,b
	or	a
	jr	z,pd_ones1
	ld	a,'0'
	call	prtchr
	jr	pd_ones1
pd_tens3:
	ld	a,c
pd_tens4:
	add	a,'0'
	call	prtchr
pd_ones1:
	ld	a,d
	add	a,'0'
	jp	prtchr

; ------------------------------------------------------------
; Data
; ------------------------------------------------------------

seq_da:
	.db	esc,'[','c',0
seq_cpr:
	.db	esc,'[','6','n',0
seq_move_br:
	.db	esc,'[','9','9','9',3Bh,'9','9','9','H',0
seq_cls:
	.db	esc,'[','2','J',esc,'[','H',0

str_config:	.db	"CONFIG",0

msg_banner:	.db	"TERMQRY v0.8 - RC2014 terminal tool",0
msg_note:	.db	"Default mode probes replies. Use -config to edit TUNE.CFG.",0
msg_q1:		.db	"Q1: Device Attributes (ESC[c)",0
msg_q2:		.db	"Q2: Window size via CPR after ESC[999;999H",0
msg_send:	.db	"  sent query",0
msg_wait:	.db	"  waiting for reply...",0
msg_reply:	.db	"  reply bytes: ",0
msg_no_reply:	.db	"  no reply (timeout)",0
msg_sum:	.db	"Summary:",0
msg_vt:		.db	"  VTxxx DA response: ",0
msg_ansi:	.db	"  ANSI CSI response: ",0
msg_dims:	.db	"  Detected terminal size: ",0
msg_unknown:	.db	"unknown",0
msg_rc:		.db	" (cols x rows)",0
msg_hint:	.db	"Tip: if no replies, terminal or path likely strips escape responses.",0
msg_cfg_mode:	.db	"Configuration mode (-config)",0
msg_cfg_found:	.db	"Loaded existing TUNE.CFG:",0
msg_cfg_default:	.db	"No TUNE.CFG found, using built-in defaults:",0
msg_cfg_term:	.db	"  Term type: ",0
msg_cfg_ansi:	.db	"  ANSI enabled: ",0
msg_cfg_size:	.db	"  Size: ",0
msg_cfg_saved:	.db	"Saved TUNE.CFG",0
msg_term_menu:	.db	"Term type? P=plain, V=VTxxx, A=ANSI",0
msg_term_prompt:	.db	"Choice [Enter keeps ",0
msg_ansi_prompt:	.db	"ANSI support? Y/N [Enter keeps ",0
msg_prompt_end:	.db	"]: ",0
msg_term_plain:	.db	"plain",0
msg_term_vt:	.db	"VTxxx",0
msg_term_ansi:	.db	"ANSI",0
msg_tune_title:	.db	"Adjust visible limits until C, R, and X are just visible.",0
msg_tune_keys:	.db	"Keys: c/C dec/inc cols, r/R dec/inc rows, Esc save+quit",0
msg_tune_curr:	.db	"Current size:",0
msg_yes:	.db	"yes",0
msg_no:		.db	"no",0

stksav:		.dw	0
mode_config:	.db	0
term_chr:	.db	0
last_chr:	.db	0
flag_vt:	.db	0
flag_ansi:	.db	0
flag_dim:	.db	0
row_val:	.db	0
col_val:	.db	0
buf_da:		.fill	64,0
buf_cpr:	.fill	64,0

	.fill	64,0
stack	.equ	$

	.end