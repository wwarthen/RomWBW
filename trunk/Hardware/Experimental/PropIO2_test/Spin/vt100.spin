'******************************************************************************
'*  vt100.spin - DEC VT100 terminal emulation
'*
'*  (c) Juergen Buchmueller <pullmoll@t-online.de>
'*
'* $Id: vt100.spin,v 1.6 2010-04-17 13:48:13 pm Exp $
'******************************************************************************
CON
	attr_highlite		=	%00000001
	attr_underline		=	%00000010
	attr_inverse		=	%00000100
	attr_blinking		=	%00001000

	flag_deccm		=	%0_00000001		' DEC cursor mode (0: off, 1: on)
	flag_decim		=	%0_00000010		' DEC insert mode
	flag_decom		=	%0_00000100		' DEC origin mode
	flag_deccr		=	%0_00001000		' DEC send CRLF or LF (0: LF, 1: CRLF)
	flag_decck		=	%0_00010000		' DEC send cursor keys
	flag_decawm		=	%0_00100000		' DEC auto wrap mode
	flag_decarm		=	%0_01000000		' DEC auto repeat mode
	flag_meta		=	%0_10000000		' meta character toggle
	flag_ctrl		=	%1_00000000		' display control characters
	flag_decrm		=	1<<10			' DEC report mouse

VAR
	long	cog

PUB start(params) : okay
	stop
	okay := cog := COGNEW(@entry, params) + 1

PUB stop : okay
	if cog
		COGSTOP(cog~~ - 1)

DAT
		org	0
entry
command_ptr	mov	t1, PAR
cmd		rdlong	command_ptr, t1		' parameter 0
screen_ptr	add	t1, #4
screen_end	rdlong	screen_ptr, t1		' parameter 1
cursor_ptr	add	t1, #4
vsync_ptr	rdlong	cursor_ptr, t1		' parameter 2
screen_w	add	t1, #4
screen_w2	rdlong	vsync_ptr, t1		' parameter 3
screen_h	add	t1, #4
cur_ptr 	rdlong	screen_w, t1		' parameter 4
scroll_top	add	t1, #4
scroll_bot	rdlong	screen_h, t1		' parameter 5
dst 		mov	screen_w2, screen_w
src 		shr	screen_w2, #1		' screen width / 2
end		mov	t1, screen_w
data		mov	t2, screen_h
cols		call	#mul16x16
rows	      	mov	screen_end, t2		' result in t2
lmm_pc		add	screen_end, t2		' * 2
cur_x_save	add	screen_end, screen_ptr
cur_y_save	mov	scroll_top, #0
new_x_save	mov	scroll_bot, screen_h
attr_save	mov	cur_delay, CNT
		jmp	#startup
control_ptr	long	@@@control_table
csi_cmds_ptr	long	@@@csi_cmds
x00200020	long	$00200020
cur_block	long	$5f

inverse		long	0
cur_x		long	0
new_x		long	0
cur_y		long	0
attr		long	0			' attribute mode
flags		long	flag_decom | flag_decawm
cur_char	long	0
cur_delay	long	0
fgcol		long	%0111			' foreground color
bgcol		long	%0000			' background color
color		long	%00000111_00000000	' composed fore- and background
esc_mode	long	0
csi_mode	long	0
csi_argc	long	0
csi_argf	long	0
csi_args	long	0,0,0,0,0,0,0,0
question_mark	long	0

t1		long	0
t2		long	0
t3		long	0

goto_xay
		' TODO: check origin mode flag
		add	cur_y, scroll_top
validate_cursor
		mov	cur_x, cur_x		WC	' negative x?
	if_c	mov	cur_x, #0			' yes, clip to 0
		cmp	cur_x, screen_w		WZ, WC
	if_ae	mov	cur_x, screen_w			' stay inside the boundaries
	if_ae	sub	cur_x, #1
		mov	new_x, cur_x
		mov	cur_y, cur_y		WC	' negative y?
	if_c	mov	cur_y, #0			' yes, clip to 0
		cmp	cur_y, screen_h		WZ, WC
	if_ae	mov	cur_y, screen_h			' stay inside the boundaries
	if_ae	sub	cur_y, #1
cmdloop
		mov	cmd, #0
		wrlong	cmd, command_ptr
startup
:loop		tjz	cursor_ptr, #:cursor		' skip if cursor_ptr is null
		wrbyte	new_x, cursor_ptr		' write the (new) cursor position
		add	cursor_ptr, #1
		wrbyte	cur_y, cursor_ptr		' and the cursor row, too
		sub	cursor_ptr, #1
		call	#calc_cursor
		jmp	#:check_cmd
:cursor		mov	t1, cur_delay			' software cursor
		sub	t1, CNT
		cmps	t1, #0			WZ, WC
	if_ae	jmp	#:check_cmd
		rdlong	t1, #0				' get clkfreq
		shr	t1, #2				' / 4
		add	cur_delay, t1			' next cursor flash event
		call	#calc_cursor
		cmp	new_x, screen_w		WZ, WC	' new_x beyond last column?
	if_ae	jmp	#:check_cmd
		mov	t1, cur_char		WZ	' get saved character
	if_z	rdbyte	cur_char, cur_ptr		' none: save character under cursor
	if_z	wrbyte	cur_block, cur_ptr		' display a cursor block
	if_nz	mov	cur_char, #0			' reset saved character
	if_nz	wrbyte	t1, cur_ptr			' restore saved character in screen buffer
:check_cmd	rdlong	cmd, command_ptr	WZ
	if_z	jmp	#:loop

		mov	t1, cur_char		WZ	' get saved character
	if_nz	cmp	cur_ptr, screen_end	WC
 if_nz_and_c	mov	cur_char, #0			' reset saved character
 if_nz_and_c	wrbyte	t1, cur_ptr			' restore saved character in screen buffer

		and	cmd, #$ff
		tjnz	csi_mode, #csi			' go to CSI decoding if enabled
		tjnz	esc_mode, #esc			' go to ESC decoding if enabled
		cmp	cmd, #$20		WZ, WC	' other control characters?
	if_ae	jmp	#do_emit			' no, just emit to the screen buffer
		shl	cmd, #1
		add	cmd, control_ptr
		rdword	cmd, cmd
		jmp	cmd				' dispatch on control_table

do_emit		call	#emit
		jmp	#cmdloop

do_nul		' NUL - null character
do_soh		' SOH - start of header
do_stx		' STX - start of text
do_etx		' ETX - end of text
do_eot		' EOT - end of transmission
do_enq		' ENQ - enquiry
do_ack		' ACK - acknowledgement
do_bel		' BEL - bell
do_dle		' DLE - data link escape
do_dc1		' DC1 - device control 1 (XON)
do_dc2		' DC2 - device control 2
do_dc3		' DC3 - device control 3 (XOFF)
do_dc4		' DC4 - device control 4
do_nak		' NAK - negative acknowledgement
do_syn		' SYN - synchronous idle
do_etb		' ETB - end of transmission block
do_em		' EM  - end of medium
do_sub		' SUB - substitute
do_fs		' FS  - file separator
do_gs		' GS  - group separator
do_rs		' RS  - request to send
do_us		' US  - unit separator
		jmp	#cmdloop

do_cr		call	#cr
		jmp	#cmdloop

do_bs		call	#bs
		jmp	#cmdloop

do_ht		call	#ht
		jmp	#cmdloop

do_lf		call	#lf
		jmp	#cmdloop

do_vt		call	#vt
		jmp	#cmdloop

do_ff		call	#ff
		jmp	#cmdloop

do_so		' ???
		jmp	#cmdloop

do_si		' ???
		jmp	#cmdloop

do_can		' CAN - cancel
		call	#can
		jmp	#cmdloop
do_esc
		mov	esc_mode, #1
		jmp	#cmdloop
esc
		mov	esc_mode, #0
		cmp	cmd, #"["		WZ
	if_z	jmp	#:csi
		' TODO: non-CSI escape sequences
		jmp	#cmdloop
:csi
		mov	csi_mode, #1			' start CSI mode
		mov	csi_argc, #0			' argument count = 0
		mov	csi_argf, #0			' argument flag = 0
		mov	csi_args, #0			' first argument = 0
		jmp	#cmdloop

csi
		cmp	csi_mode, #1		WZ	' first character after "["?
	if_nz	jmp	#:not_question			' no, check arguments
		mov	csi_mode, #2			' skip this test in the future
		cmp	cmd, #"?"		WZ	' "<ESC>[?" mode?
		muxz	question_mark, #1
	if_z	jmp	#cmdloop

:not_question
		cmp	cmd, #"0"		WZ, WC
	if_b	jmp	#:not_numeric
		cmp	cmd, #"9"		WZ, WC
	if_a	jmp	#:not_numeric
		mov	t1, csi_argc
		add	t1, #csi_args
		movs	:get_arg, t1
		movd	:put_arg, t1
		mov	csi_argf, #1			' set the "seen arguments" flag
:get_arg	mov	t1, 0-0				' get csi_args[csi_argc]
		mov	t2, t1				' to t2 also
		shl	t1, #2				' * 4
		add	t1, t2				' * 5
		shl	t1, #1				' * 10
		add	t1, cmd				' + digit
		sub	t1, #"0"			' - ASCII for "0"
:put_arg	mov	0-0, t1				' put csi_args[csi_argc]
		jmp	#cmdloop

:not_numeric
		cmp	cmd, #";"		WZ	' next argument delimiter?
	if_nz	jmp	#:not_delimiter
		cmp	csi_argc, #7		WZ	' reached maximum number of arguments?
	if_nz	add	csi_argc, #1			' no, use next slot
		mov	t1, csi_argc
		add	t1, #csi_args
		movd	:clr_arg, t1
		nop
:clr_arg	mov	0-0, #0				' preset csi_args[csi_argc] to 0
		jmp	#cmdloop

:not_delimiter
		mov	csi_mode, #0			' end CSI mode
		add	csi_argc, csi_argf		' incr. argument count, if any arguments were specified

		cmp	cmd, #"@"		WZ, WC	' below @?
	if_b	jmp	#cmdloop
		cmp	cmd, #"z"		WZ, WC	' above z?
	if_ae	jmp	#cmdloop
		sub	cmd, #"@"
		shl	cmd, #1				' function word index
		add	cmd, csi_cmds_ptr
		rdword	cmd, cmd			' get function pointer
		testn	cmd, #$1ff		WZ	' any bits outside the cog?
	if_z	jmp	cmd				' cog function
		mov	lmm_pc, cmd			' otherwise it's an LMM address
		jmp	#lmm_loop			' execute LMM code

'********************************************************************************************
' non_zero_args - make sure the first argument is at least 1
'
non_zero_args
		tjnz	csi_args, #non_zero_args_ret
		add	csi_args, #1
non_zero_args_ret
		ret

'********************************************************************************************
' shift_csi_args - remove the first value from the list of arguments, pad with 0
'
shift_csi_args
		mov	csi_args, csi_args + 1
		mov	csi_args + 1, csi_args + 2
		mov	csi_args + 2, csi_args + 3
		mov	csi_args + 3, csi_args + 4
		mov	csi_args + 4, csi_args + 5
		mov	csi_args + 5, csi_args + 6
		mov	csi_args + 6, csi_args + 7
		mov	csi_args + 7, #0
shift_csi_args_ret
		ret

'********************************************************************************************
' cr - carriage return
'
cr
		mov	cur_x, #0
		mov	new_x, #0
cr_ret
		ret

'********************************************************************************************
' bs - back space
'
bs
		cmp	new_x, #0		WZ
	if_nz	sub	new_x, #1
	if_nz	jmp	#bs_ret
		mov	new_x, screen_w
		sub	new_x, #1
		call	#vt
bs_ret
		ret

'********************************************************************************************
' fs - forward space
'
fs
		add	cur_x, #1
		cmp	cur_x, screen_w		WZ
	if_z	sub	cur_x, #1				' stay in last column
fs_ret
		ret

'********************************************************************************************
' ht - horizontal tabulator
'
ht
		mov	cmd, #$20
		call	#emit
		test	new_x, #7		WZ
	if_nz	jmp	#ht
ht_ret
		ret
'********************************************************************************************
' lf - line feed
'
lf
		add	cur_y, #1
		test	flags, #flag_decom	WZ		' origin mode enabled?
	if_nz	jmp	#:origin				' yes, check cursor in scroll range

:screen		cmp	cur_y, screen_h		WZ, WC		' no, check cursor in screen range
	if_b	jmp	#lf_ret
		mov	cur_y, screen_h
		sub	cur_y, #1
		mov	dst, screen_ptr				' destination = screen buffer
		mov	src, screen_ptr				' source = dito
		mov	rows, screen_h				' screen height
		jmp	#scroll_up_1				' scroll the entire screen

:origin		cmp	cur_y, scroll_bot	WZ, WC
	if_b	jmp	#lf_ret
		mov	cur_y, scroll_bot
		sub	cur_y, #1
scroll_up
		mov	t1, scroll_top
		mov	t2, screen_w
		call	#mul16x16
		shl	t2, #1
		add	t2, screen_ptr
		mov	dst, t2					' destination = scroll_top of screen buffer
		mov	src, t2					' source = dito
		mov	rows, scroll_bot			' scroll range height
		sub	rows, scroll_top
scroll_up_1
		add	src, screen_w				' copy from one line below
		add	src, screen_w
		sub	rows, #1		WZ, WC		' - 1 rows to move
	if_be	jmp	#:fill					' nothing left to scroll?
:rows		mov	cols, screen_w2				' columns = screen width / 2
:cols		rdlong	data, src
		add	src, #4
		wrlong	data, dst
		add	dst, #4
		djnz	cols, #:cols
		djnz	rows, #:rows
:fill		mov	cols, screen_w2				' columns = screen width / 2
		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:blank		wrlong	t1, dst					' fill 4 spaces
		add	dst, #4
		djnz	cols, #:blank
scroll_up_ret
lf_ret
		ret

'********************************************************************************************
' vt - vertical tab (inverse line feed)
'
vt
		sub	cur_y, #1
		test	flags, #flag_decom	WZ		' origin mode enabled?
	if_nz	jmp	#:origin				' yes, check cursor in scroll range

:screen								' no, check cursor in screen range
		cmps	cur_y, #0		WZ, WC		' < 0?
	if_ae	jmp	#vt_ret					' in range
		mov	cur_y, #0				' stay in line 0
		mov	src, screen_end
		mov	dst, screen_end
		mov	rows, screen_h
		jmp	#scroll_down_1
:origin
		cmps	cur_y, scroll_top	WZ, WC
	if_ae	jmp	#vt_ret
		mov	cur_y, scroll_top
scroll_down
		mov	t1, scroll_bot
		mov	t2, screen_w
		call	#mul16x16
		shl	t2, #1
		add	t2, screen_ptr
		mov	dst, t2					' destination = end of scroll range buffer
		mov	src, t2					' source = last row of scroll range buffer
		mov	rows, scroll_bot			' scroll range height
		sub	rows, scroll_top
scroll_down_1
		sub	src, screen_w
		sub	src, screen_w
		sub	rows, #1		WZ, WC		' - 1 rows to move
	if_be	jmp	#:fill					' nothing left to scroll?
:rows		mov	cols, screen_w2				' columns = screen width / 2
:cols		sub	src, #4					' pre decrement source
		rdlong	data, src
		sub	dst, #4					' pre decrement destination
		wrlong	data, dst
		djnz	cols, #:cols				' for all columns
		djnz	rows, #:rows				' for all rows
:fill		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
		mov	cols, screen_w2				' columns = screen width / 2
:blank		sub	dst, #4
		wrlong	t1, dst
		djnz	cols, #:blank
scroll_down_ret
vt_ret
		ret

'********************************************************************************************
' ff - form feed (clear screen)
'
ff
		mov	dst, screen_ptr
		mov	rows, screen_h				' screen height rows
		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:rows		mov	cols, screen_w2				' columns = screen width / 2
:cols		wrlong	t1, dst					' fill with 4 blanks
		add	dst, #4
		djnz	cols, #:cols				' for all columns
		djnz	rows, #:rows				' for all rows
		call	#home
ff_ret
		ret

'********************************************************************************************
' home - cursor home
'
home
		mov	cur_x, #0
		mov	new_x, #0
		mov	cur_y, #0
home_ret
		ret

'********************************************************************************************
' can - clear from cursor to end of line
'
can
		mov	dst, cur_ptr
		mov	cols, screen_w
		sub	cols, new_x		WZ, WC
	if_be	jmp	#can_ret
		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:fill		wrword	t1, dst
		add	dst, #2
		djnz	cols, #:fill
can_ret
		ret

'********************************************************************************************
' emit - emit character to cursor and advance cursor position
'
emit
		cmp	new_x, screen_w		WZ, WC		' reached end of line?
	if_b	jmp	#:in_bounds
		test	flags, #flag_decawm	WZ		' auto wrap mode active?
	if_z	jmp	#emit_ret				' no, don't emit character
		call	#cr
		call	#lf		
:in_bounds	mov	cur_x, new_x
		call	#calc_cursor
		or	cmd, color
		test	attr, #attr_underline	WZ
		muxnz	cmd, #$80
		wrword	cmd, cur_ptr				' write character to screen RAM
		mov	new_x, cur_x
		add	new_x, #1
		add	cur_ptr, #2
emit_ret
		ret

'********************************************************************************************
' calc_cursor - compute cursor address in cur_ptr
'
calc_cursor
		mov	t1, cur_y				' cursor row
		mov	t2, screen_w				' * screen width
		call	#mul16x16
		mov	cur_ptr, t2				' product in cur_ptr
		add	cur_ptr, new_x				' + new cursor column
		shl	cur_ptr, #1				' * 2
		add	cur_ptr, screen_ptr			' + screen buffer address
calc_cursor_ret
		ret

'********************************************************************************************
' enable_cursor - enable or disable the cursor depending on the deccm flag
'
enable_cursor
		tjz	cursor_ptr, #cmdloop
		test	flags, #flag_deccm	WZ		' cursor enabled?
	if_z	mov	t1, #%000				' cursor off
	if_nz	mov	t1, #%110				' cursor on, blink slow
		add	cursor_ptr, #2				' cursor control
		wrbyte	t1, cursor_ptr
		sub	cursor_ptr, #2
		jmp	#cmdloop

'********************************************************************************************
' set_color - combine background and foreground color and write the table
'
set_color
		test	attr, #attr_inverse	WZ
	if_z	jmp	#:default
:inverse
		mov	color, fgcol				' compose inverse color
		shl	color, #4
		or	color, bgcol
		jmp	#:cont
:default
		mov	color, bgcol				' compose default color
		shl	color, #4
		or	color, fgcol
:cont
		test	attr, #attr_highlite	WZ
		muxnz	color, #$08
		test	attr, #attr_blinking	WZ
		muxnz	color, #$80
		shl	color, #8				' in bits 15..8
		jmp	#cmdloop

'********************************************************************************************
' mul16x16 - multiply 16 bits in t1 by 16 bits in t2, result in t2
'
mul16x16
		shl	t1, #16					' multiplicand in bits 31..16
		mov	t3, #16					' loop 16 times
		shr	t2, #1			WC		' get initial multiplier bit in carry
:loop	if_c	add	t2, t1			WC		' if carry set, add multiplicand to product
		rcr	t2, #1			WC		' next multiplier bit to carry, shift product
		djnz	t3, #:loop				' until done
mul16x16_ret
		ret

lmm_loop
		rdlong	:op1, lmm_pc
		add	lmm_pc, #4
:op1		nop
		rdlong	:op2, lmm_pc
		add	lmm_pc, #4
:op2		nop
		rdlong	:op3, lmm_pc
		add	lmm_pc, #4
:op3		nop
		rdlong	:op4, lmm_pc
		add	lmm_pc, #4
:op4		nop
		jmp	#lmm_loop

		fit	$1f0

control_table	word	do_nul, do_soh, do_stx, do_etx, do_eot, do_enq, do_ack, do_bel
		word	do_bs,  do_ht,  do_lf,  do_vt,  do_ff,  do_cr,  do_so,  do_si
		word	do_dle, do_dc1, do_dc2, do_dc3, do_dc4, do_nak, do_syn, do_etb
		word	do_can, do_em,  do_sub, do_esc, do_fs,  do_gs,  do_rs,  do_us

csi_cmds	word	@@@do_insert_char			' <ESC>[...@
		word	@@@do_cursor_up				' <ESC>[...A
		word	@@@do_cursor_down			' <ESC>[...B
		word	@@@do_cursor_left			' <ESC>[...C
		word	@@@do_cursor_right			' <ESC>[...D
		word	@@@do_rows_up				' <ESC>[...E
		word	@@@do_rows_down				' <ESC>[...F
		word	@@@do_cursor_column			' <ESC>[...G
		word	@@@do_cursor_address			' <ESC>[...H
		word	cmdloop					' I unused?
		word	@@@do_clear_screen			' <ESC>[...J
		word	@@@do_clear_row				' <ESC>[...K
		word	@@@do_insert_line			' <ESC>[...L
		word	@@@do_delete_line			' <ESC>[...M
		word	cmdloop					' N unused?
		word	cmdloop					' O unused?
		word	@@@do_delete_char			' P unused?
		word	cmdloop					' Q unused?
		word	cmdloop					' R unused?
		word	cmdloop					' S unused?
		word	cmdloop					' T unused?
		word	cmdloop					' U unused?
		word	cmdloop					' V unused?
		word	cmdloop					' W unused?
		word	@@@do_blank_chars			' <ESC>[...X
		word	cmdloop					' Y unused?
		word	cmdloop					' Z unused?
		word	cmdloop					' [ unused
		word	cmdloop					' \ unused
		word	cmdloop					' ] unused
		word	cmdloop					' ^ unused
		word	cmdloop					' _ unused
		word	@@@do_cursor_column			' <ESC>[...` alternate form for <ESC>[...G
		word	cmdloop					' a unused?
		word	cmdloop					' b unused?
		word	cmdloop					' c unused?
		word	cmdloop					' d unused?
		word	cmdloop					' e unused?
		word	@@@do_cursor_address			' <ESC>[...f alternate form for <ESC>[...H
		word	cmdloop					' g unused?
		word	@@@do_flag_set				' h unused?
		word	cmdloop					' i unused?
		word	cmdloop					' j unused?
		word	cmdloop					' k unused?
		word	@@@do_flag_res				' h unused?
		word	@@@do_mode_attributes			' <ESC>[...m
		word	cmdloop					' n unused?
		word	cmdloop					' o unused?
		word	cmdloop					' p unused?
		word	cmdloop					' q unused?
		word	@@@do_scroll_range			' <ESC>[...r
		word	@@@do_save_cursor			' <ESC>[?...s
		word	cmdloop					' t unused?
		word	@@@do_restore_cursor			' <ESC>[?...u
		word	cmdloop					' v unused?
		word	cmdloop					' w unused?
		word	cmdloop					' x unused?
		word	cmdloop					' y unused?
		word	cmdloop					' z unused?

'********************************************************************************************
'
' LMM code fragments following
'
'********************************************************************************************

'********************************************************************************************
' <ESC>[...@ - insert n spaces at the cursor position
'
do_insert_char
		call	#non_zero_args
		cmp	new_x, screen_w		WZ, WC
	if_ae	jmp	#cmdloop
:loop		mov	t1, cur_y
		mov	t2, screen_w
		call	#mul16x16
		add	t2, new_x
		shl	t2, #1
		add	t2, screen_ptr
		mov	dst, t2
		add	dst, #2
		mov	src, t2
		mov	cols, screen_w
		sub	cols, new_x
		sub	cols, #1		WZ, WC
	if_be	add	lmm_pc, #4*(:blank - $ - 1)
:insert		rdword	data, src
		add	src, #2
		wrword	data, dst
		add	dst, #2
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :insert)
		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:blank		wrword	t1, t2
		sub	csi_args, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...A - cursor up
'
do_cursor_up
		call	#non_zero_args
:loop		call	#vt
		sub	csi_args, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...B - cursor down
'
do_cursor_down
		call	#non_zero_args
:loop		call	#lf
		djnz	csi_args, #:loop
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...C - cursor left
'
do_cursor_left
		call	#non_zero_args
		mov	cur_x, new_x
		sub	cur_x, csi_args		WC
	if_c	mov	cur_x, #0
		jmp	#validate_cursor

'********************************************************************************************
' <ESC>[...D - cursor right
'
do_cursor_right
		call	#non_zero_args
		mov	cur_x, new_x
		add	cur_x, csi_args
		jmp	#validate_cursor

'********************************************************************************************
' <ESC>[...E - rows up, cursor column = 0
'
do_rows_up
		call	#non_zero_args
		mov	cur_x, #0
		mov	new_x, #0
		sub	cur_y, csi_args		WC
	if_c	mov	cur_y, #0
		jmp	#validate_cursor

'********************************************************************************************
' <ESC>[...F - rows down, cursor column = 0
'
do_rows_down
		call	#non_zero_args
		mov	cur_x, #0
		mov	new_x, #0
		add	cur_y, csi_args
		jmp	#validate_cursor

'********************************************************************************************
' <ESC>[...H - cursor address - row, column
'
do_cursor_address
		cmp	csi_argf, #0		WZ		' nor arguments at all?
	if_z	call	#home
	if_z	jmp	#cmdloop
		call	#non_zero_args
		mov	cur_y, csi_args
		sub	cur_y, #1
		cmp	csi_argc, #1		WZ, WC		' the caller specified just a row?
	if_be	jmp	#validate_cursor
		call	#shift_csi_args
		' fall through
'********************************************************************************************
' <ESC>[...G - cursor column
'
do_cursor_column
		call	#non_zero_args
		mov	cur_x, csi_args
		sub	cur_x, #1
		jmp	#validate_cursor

'********************************************************************************************
' <ESC>[...J - clear screen
'
do_clear_screen
		call	#calc_cursor
		cmp	csi_args, #0		WZ		' cursor to end of screen?
	if_nz	add	lmm_pc, #4*(:not_0 - $ - 1)
		mov	dst, cur_ptr
		mov	end, screen_end
		add	lmm_pc, #4*(:fill - $ - 1)
:not_0		cmp	csi_args, #1		WZ		' start of screen to cursor?
	if_nz	add	lmm_pc, #4*(:not_1 - $ - 1)
		mov	dst, screen_ptr
		mov	end, cur_ptr
		add	lmm_pc, #4*(:fill - $ - 1)
:not_1		cmp	csi_args, #2		WZ		' entire screen?
	if_nz	jmp	#cmdloop				' invalid argument
		mov	dst, screen_ptr				' default = entire screen
		mov	end, screen_end
:fill		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:loop		wrword	t1, dst					' fill a word
		add	dst, #2
		cmp	dst, end		WZ, WC
	if_b	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...K - clear cursor row
'
do_clear_row
		call	#calc_cursor
		cmp	csi_args, #0		WZ		' cursor to end of row?
	if_nz	add	lmm_pc, #4*(:not_0 - $ - 1)
		mov	dst, cur_ptr				' default = cursor to end of row
		mov	end, cur_ptr
		sub	end, new_x
		add	end, screen_w				' end of row
		add	lmm_pc, #4*(:fill - $ - 1)
:not_0		cmp	csi_args, #1		WZ		' start of row to cursor?
	if_nz	add	lmm_pc, #4*(:not_1 - $ - 1)
		mov	dst, cur_ptr
		sub	dst, new_x				' start of row
		mov	end, cur_ptr				' to cursor
		add	lmm_pc, #4*(:fill - $ - 1)
:not_1		cmp	csi_args, #2		WZ		' entire row?
	if_nz	jmp	#cmdloop				' invalid argument
		mov	dst, cur_ptr
		sub	dst, new_x				' start of row
		mov	end, dst
		add	end, screen_w				' end of row
:fill		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:loop		wrword	t1, dst					' fill a word
		add	dst, #2
		cmp	dst, end		WZ, WC
	if_b	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...L - insert line(s)
'
do_insert_line
		call	#non_zero_args
:loop		mov	dst, screen_end
		mov	src, screen_end
		sub	src, screen_w
		mov	rows, screen_h				' screen rows
		sub	rows, cur_y				' - cursor row
		sub	rows, #1		WZ, WC		' - 1
	if_be	add	lmm_pc, #4*(:fill - $ - 1)		' nothing left to move?
:rows		mov	cols, screen_w2				' columns = screen width / 2
:cols		sub	src, #4
		rdlong	data, src
		sub	dst, #4
		wrlong	data, dst
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :cols)
		sub	rows, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :rows)
:fill		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
		mov	cols, screen_w2				' columns = screen width / 2
:blank		sub	dst, #4
		wrlong	t1, dst
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :blank)		' for all columns
		sub	csi_args, #1		WZ		' more lines to insert?
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...M - delete line(s)
'
do_delete_line
		call	#non_zero_args
:loop		mov	t1, cur_y
		mov	t2, screen_w
		call	#mul16x16
		shl	t2, #1
		add	t2, screen_ptr				' cursor row address
		mov	dst, t2
		mov	src, t2
		add	src, screen_w				' one row down
		add	src, screen_w
		mov	rows, screen_h				' screen rows
		sub	rows, cur_y				' - cursor row
		sub	rows, #1		WZ, WC		' - 1
	if_be	add	lmm_pc, #4*(:fill - $ - 1)		' nothing left to move?
:rows		mov	cols, screen_w2				' columns = screen width / 2
:cols		rdlong	data, src
		add	src, #4
		wrlong	data, dst
		add	dst, #4
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :cols)
		sub	rows, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :rows)
:fill		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
		mov	cols, screen_w2				' columns = screen width / 2
:blank		wrlong	t1, dst
		add	dst, #4
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :blank)		' for all columns
		sub	csi_args, #1		WZ		' more lines to insert?
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...P - delete n characters at the cursor position
'
do_delete_char
		call	#non_zero_args
		cmp	new_x, screen_w		WZ, WC
	if_ae	jmp	#cmdloop				' can't delete beyond last column
:loop		mov	t1, cur_y
		mov	t2, screen_w
		call	#mul16x16
		add	t2, new_x
		shl	t2, #1
		add	t2, screen_ptr
		mov	dst, t2
		mov	src, t2
		add	src, #2
		mov	cols, screen_w
		sub	cols, new_x
		sub	cols, #1		WZ, WC
	if_be	add	lmm_pc, #4*(:blank - $ - 1)		' new_x is beyond the last column
:insert		rdword	data, src
		add	src, #2
		wrword	data, dst
		add	dst, #2
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :insert)
:blank		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
		wrword	t1, dst					' clear the last character in the row
		sub	csi_args, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...X - blank characters
'
do_blank_chars
		call	#non_zero_args
		mov	dst, cur_ptr
		mov	cols, screen_w
		sub	cols, new_x		WZ, WC
	if_be	jmp	#cmdloop
		mov	t1, x00200020
		or	t1, color
		rol	t1, #16
		or	t1, color
:fill		wrword	t1, dst
		add	dst, #2
		sub	csi_args, #1		WZ
	if_z	jmp	#cmdloop
		sub	cols, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :fill)
		jmp	#cmdloop

'********************************************************************************************
' <ESC>[...h - set flag(s)
'
do_flag_set
:loop
		mov	cmd, csi_args
		cmp	question_mark, #1	WZ		' <ESC>[? sequence?
	if_z	add	lmm_pc, #4*(:ques - $ - 1)
		cmp	cmd, #3			WZ		' <ESC>[3h - display control characters
	if_z	or	flags, #flag_ctrl
		cmp	cmd, #4			WZ		' <ESC>[4h - set insert mode
	if_z	or	flags, #flag_decim
		cmp	cmd, #20		WZ		' <ESC>[20h - set auto CR mode
	if_z	or	flags, #flag_deccr
		add	lmm_pc, #4*(:next - $ - 1)
:ques
		cmp	cmd, #1			WZ		' <ESC>[?1h - enable cursor keys
	if_z	or	flags, #flag_decck
'		cmp	cmd, #2			WZ		' <ESC>[?2h - enable 132 column mode
'	if_z	or	flags, #flag_decck
		cmp	cmd, #5			WZ		' <ESC>[?5h - inverse terminal on
	if_z	or	inverse, #1
		cmp	cmd, #6			WZ		' <ESC>[?6h - enable origin mode
	if_z	or	flags, #flag_decom
		cmp	cmd, #7			WZ		' <ESC>[?7h - enable auto wrap mode
	if_z	or	flags, #flag_decawm
		cmp	cmd, #8			WZ		' <ESC>[?8h - enable auto repeat mode
	if_z	or	flags, #flag_decarm
'		cmp	cmd, #9			WZ		' <ESC>[?9h - enable report mouse mode
'	if_z	or	flags, #flag_decrm
		cmp	cmd, #25		WZ		' <ESC>[?25h - enable cursor
	if_z	or	flags, #flag_deccm
:next
		cmp	csi_argf, #0		WZ		' no arguments specified?
	if_z	jmp	#cmdloop

		call	#shift_csi_args
		sub	csi_argc, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#enable_cursor

'********************************************************************************************
' <ESC>[...l - reset flag(s)
'
do_flag_res
:loop
		mov	cmd, csi_args
		cmp	question_mark, #1	WZ		' <ESC>[? sequence?
	if_z	add	lmm_pc, #4*(:ques - $ - 1)
		cmp	cmd, #3			WZ		' <ESC>[3l - don't display control characters
	if_z	andn	flags, #flag_ctrl
		cmp	cmd, #4			WZ		' <ESC>[4l - reset insert mode
	if_z	andn	flags, #flag_decim
		cmp	cmd, #20		WZ		' <ESC>[20l - reset auto CR mode
	if_z	andn	flags, #flag_deccr
		add	lmm_pc, #4*(:next - $ - 1)
:ques
		cmp	cmd, #1			WZ		' <ESC>[?1l - disable cursor keys
	if_z	andn	flags, #flag_decck
'		cmp	cmd, #2			WZ		' <ESC>[?2l - disable 132 column mode
'	if_z	andn	flags, #flag_decck
		cmp	cmd, #5			WZ		' <ESC>[?5l - inverse terminal off
	if_z	andn	inverse, #1
		cmp	cmd, #6			WZ		' <ESC>[?6l - disable origin mode
	if_z	andn	flags, #flag_decom
		cmp	cmd, #7			WZ		' <ESC>[?7l - disable auto wrap mode
	if_z	andn	flags, #flag_decawm
		cmp	cmd, #8			WZ		' <ESC>[?8l - disable auto repeat mode
	if_z	andn	flags, #flag_decarm
'		cmp	cmd, #9			WZ		' <ESC>[?9l - disable report mouse mode
'	if_z	andn	flags, #flag_decrm
		cmp	cmd, #25		WZ		' <ESC>[?25l - disable cursor
	if_z	andn	flags, #flag_deccm
:next
		cmp	csi_argf, #0		WZ		' no arguments specified?
	if_z	jmp	#cmdloop

		call	#shift_csi_args
		sub	csi_argc, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :loop)
		jmp	#enable_cursor


'********************************************************************************************
' <ESC>[...m - set mode attributes
'
do_mode_attributes
:get_arg	mov	cmd, csi_args				' get next argument
		cmp	cmd, #0			WZ		' 0 = reset all attributes
	if_z	mov	attr, #0
	if_z	mov	bgcol, #%0000
	if_z	mov	fgcol, #%0111
		cmp	cmd, #1			WZ		' 1 = highlight on
	if_z	or	attr, #attr_highlite
		cmp	cmd, #2			WZ		' 2 = highlight off
	if_z	andn	attr, #attr_highlite
		cmp	cmd, #4			WZ		' 4 = underline on
	if_z	or	attr, #attr_underline
		cmp	cmd, #5			WZ		' 5 = blinking on
	if_z	or	attr, #attr_blinking
		cmp	cmd, #7			WZ		' 7 = inverse on
	if_z	or	attr, #attr_inverse
		cmp	cmd, #10		WZ		' 10 = primary font, no ctrl, no meta
	if_z	andn	flags, #flag_ctrl
	if_z	andn	flags, #flag_meta
		cmp	cmd, #11		WZ		' 11 = alternate font, ctrl chars, low half, meta off
	if_z	or	flags, #flag_ctrl
	if_z	andn	flags, #flag_meta
		cmp	cmd, #12		WZ		' 12 = alternate font, ctrl chars, low half, meta on
	if_z	or	flags, #flag_ctrl
	if_z	or	flags, #flag_meta
		cmp	cmd, #21		WZ		' 21 = highlight on
	if_z	or	attr, #attr_highlite
		cmp	cmd, #22		WZ		' 22 = highlight on
	if_z	or	attr, #attr_highlite
		cmp	cmd, #24		WZ		' 24 = underline off
	if_z	andn	attr, #attr_underline
		cmp	cmd, #25		WZ		' 25 = blinking off
	if_z	andn	attr, #attr_blinking
		cmp	cmd, #27		WZ		' 27 = inverse off
	if_z	andn	attr, #attr_inverse
		cmp	cmd, #30		WZ		' 30 = foreground color 0
	if_z	mov	fgcol, #%0000
		cmp	cmd, #31		WZ		' 31 = foreground color 1
	if_z	mov	fgcol, #%0001
		cmp	cmd, #32		WZ		' 32 = foreground color 2
	if_z	mov	fgcol, #%0010
		cmp	cmd, #33		WZ		' 33 = foreground color 3
	if_z	mov	fgcol, #%0011
		cmp	cmd, #34		WZ		' 34 = foreground color 4
	if_z	mov	fgcol, #%0100
		cmp	cmd, #35		WZ		' 35 = foreground color 5
	if_z	mov	fgcol, #%0101
		cmp	cmd, #36		WZ		' 36 = foreground color 6
	if_z	mov	fgcol, #%0110
		cmp	cmd, #37		WZ		' 37 = foreground color 7
	if_z	mov	fgcol, #%0111
		cmp	cmd, #38		WZ		' 38 = default color and underline on
	if_z	mov	fgcol, #%0111
	if_z	or	attr, #attr_underline
		cmp	cmd, #39		WZ		' 39 = default color and underline off
	if_z	mov	fgcol, #%0111
	if_z	andn	attr, #attr_underline
		cmp	cmd, #40		WZ		' 40 = default background
	if_z	mov	bgcol, #%0000				' black
		cmp	cmd, #41		WZ		' 41 = background color 1
	if_z	mov	bgcol, #%0001
		cmp	cmd, #42		WZ		' 42 = background color 2
	if_z	mov	bgcol, #%0010
		cmp	cmd, #43		WZ		' 43 = background color 3
	if_z	mov	bgcol, #%0011
		cmp	cmd, #44		WZ		' 44 = background color 4
	if_z	mov	bgcol, #%0100
		cmp	cmd, #45		WZ		' 45 = background color 5
	if_z	mov	bgcol, #%0101
		cmp	cmd, #46		WZ		' 46 = background color 6
	if_z	mov	bgcol, #%0110
		cmp	cmd, #47		WZ		' 47 = background color 7
	if_z	mov	bgcol, #%0111
		cmp	cmd, #49		WZ		' 49 = default background
	if_z	mov	bgcol, #%0000				' black

		cmp	csi_argf, #0		WZ		' no arguments specified?
	if_z	jmp	#cmdloop

		call	#shift_csi_args
		sub	csi_argc, #1		WZ
	if_nz	sub	lmm_pc, #4*($ + 1 - :get_arg)
		jmp	#set_color

'********************************************************************************************
' <ESC>[...r - set scroll range
'
do_scroll_range
		cmp	csi_argc, #2		WZ, WC		' 2 arguments specified?
	if_ae	add	lmm_pc, #4*(:set_range - $ - 1)
		mov	scroll_top, #1
		mov	scroll_bot, screen_h
		add	lmm_pc, #4*(:bottom_ok - $ - 1)
:set_range
		mov	scroll_top, csi_args
		mov	scroll_bot, csi_args + 1
		cmp	scroll_top, scroll_bot	WZ, WC		' bottom => top?
	if_be	add	lmm_pc, #4*(:order_ok - $ - 1)
		mov	scroll_top, #1
		mov	scroll_bot, screen_h
		add	lmm_pc, #4*(:bottom_ok - $ - 1)
:order_ok
		cmp	scroll_bot, screen_h	WZ, WC		' bottom > screen height?
	if_be	add	lmm_pc, #4*(:bottom_ok - $ - 1)
		mov	scroll_top, #1
		mov	scroll_bot, screen_h
:bottom_ok
		sub	scroll_top, #1
		mov	cur_x, #0
		mov	cur_y, #0
		jmp	#goto_xay

'********************************************************************************************
' <ESC>[?...s - save cursor position and attributes
'
do_save_cursor
		mov	cur_x_save, cur_x
		mov	new_x_save, new_x
		mov	cur_y_save, cur_y
		mov	attr_save, attr
		jmp	#cmdloop


'********************************************************************************************
' <ESC>[?...u - restore cursor position and attributes
'
do_restore_cursor
		mov	cur_x, cur_x_save
		mov	new_x, new_x_save
		mov	cur_y, cur_y_save
		mov	attr, attr_save
		jmp	#cmdloop
