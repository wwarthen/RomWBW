'' This object generates a 640x480 VGA signal which contains 80 columns x 30
'' rows of 8x8 double scan characters. Each character can have a unique forground
'' and background color combination and each character can be inversed and highlit.
'' There are also two cursors which can be independently controlled (ie. mouse
'' and keyboard). A sync indicator signals each time the screen is refreshed
'' (you may ignore).
''
'' You must provide buffers for the screen, cursors, and sync. Once started,
'' all interfacing is done via memory. To this object, all buffers are
'' read-only, with the exception of the sync indicator which gets written with
'' -1. You may freely write all buffers to affect screen appearance. Have fun!
''

CON

' 640 x 480 @ 69Hz settings: 80 x 30 characters

	hp = 640	' horizontal pixels
	vp = 480	' vertical pixels
	hf = 24		' horizontal front porch pixels
	hs = 40		' horizontal sync pixels
	hb = 128	' horizontal back porch pixels
	vf = 20		' vertical front porch lines
	vs = 3		' vertical sync lines
	vb = 17		' vertical back porch lines
	hn = 1		' horizontal normal sync state (0|1)
	vn = 1		' vertical normal sync state (0|1)
	pr = 30		' pixel rate in MHz at 80MHz system clock (5MHz granularity)

' columns and rows

	cols = hp / 8
	rows = vp / 16


VAR long cog[2]

PUB start(BasePin, ScreenPtr, CursorPtr, SyncPtr) : okay | i, j

'' Start VGA driver - starts two COGs
'' returns false if two COGs not available
''
''	BasePin = VGA starting pin (0, 8, 16, 24, etc.)
''
''	ScreenPtr = Pointer to 80x30 words containing Latin-1 codes and colors for
''		each of the 80x30 screen characters. The lower byte of the word
''              contains the Latin-1 code to display. The upper byte contains
''		the foreground colour in bits 11..8 and the background colour in
''              bits 15..12.
''
''		screen word example: %00011111_01000001 = "A", white on blue
''
''	CursorPtr = Pointer to 6 bytes which control the cursors:
''
''		bytes 0,1,2: X, Y, and MODE of cursor 0
''		bytes 3,4,5: X, Y, and MODE of cursor 1
''
''		X and Y are in terms of screen characters
''		(left-to-right, top-to-bottom)
''
''		MODE uses three bottom bits:
''
''			%x00 = cursor off
''			%x01 = cursor on
''			%x10 = cursor on, blink slow
''			%x11 = cursor on, blink fast
''			%0xx = cursor is solid block
''			%1xx = cursor is underscore
''
''		cursor example: 127, 63, %010 = blinking block in lower-right
''
''	SyncPtr = Pointer to long which gets written with -1 upon each screen
''		refresh. May be used to time writes/scrolls, so that chopiness
''		can be avoided. You must clear it each time if you want to see
''		it re-trigger.

	' if driver is already running, stop it
	stop

	' implant pin settings
	reg_vcfg := $200000FF + (BasePin & %111000) << 6
	i := $FF << (BasePin & %011000)
	j := BasePin & %100000 == 0
	reg_dira := i & j
	reg_dirb := i & !j

	' implant CNT value to sync COGs to
	sync_cnt := cnt + $10000

	' implant pointers
	longmove(@screen_base, @ScreenPtr, 2)
	font_base := @font

	' implant unique settings and launch first COG
	vf_lines.byte := vf
	vb_lines.byte := vb
	font_part := 1
	cog[1] := cognew(@entry, SyncPtr) + 1

	' allow time for first COG to launch
	waitcnt($2000 + cnt)

	' differentiate settings and launch second COG
	vf_lines.byte := vf+8
	vb_lines.byte := vb-8
	font_part := 0
	cog[0] := cognew(@entry, SyncPtr) + 1

	' if both COGs launched, return true
	if cog[0] and cog[1]
		return 0

	' else, stop any launched COG and return false
	stop


PUB stop | i

'' Stop VGA driver - frees two COGs

	repeat i from 0 to 1
	if cog[i]
	cogstop(cog[i]~ - 1)


CON
	hv_inactive = (hn << 1 + vn) * $0101			'H,V inactive states


DAT

'*****************************************************
'* Assembly language VGA high-resolution text driver *
'*****************************************************

' This program runs concurrently in two different COGs.
'
' Each COG's program has different values implanted for front-porch lines and
' back-porch lines which surround the vertical sync pulse lines. This allows
' timed interleaving of their active display signals during the visible portion
' of the field scan. Also, they are differentiated so that one COG displays
' even four-line groups while the other COG displays odd four-line groups.
'
' These COGs are launched in the PUB 'start' and are programmed to synchronize
' their PLL-driven video circuits so that they can alternately prepare sets of
' four scan lines and then display them. The COG-to-COG switchover is seemless
' due to two things: exact synchronization of the two video circuits and the
' fact that all COGs' driven output states get OR'd together, allowing one COG
' to output lows during its preparatory state while the other COG effectively
' drives the pins to create the visible and sync portions of its scan lines.
' During non-visible scan lines, both COGs output together in unison.
'
			org	0				' set origin to $000 for start of program
entry
' Initialization code and data - after execution, space gets reused as scanbuff

			' Init I/O registers and sync COGs' video circuits

			mov	dira, reg_dira			' set pin directions
			mov	dirb, reg_dirb
			movi	frqa, #(pr / 5) << 2		' set pixel rate
			mov	vcfg, reg_vcfg			' set video configuration
			mov	vscl, #1		 	' set video to reload on every pixel
			waitcnt sync_cnt, colormask		' wait for start value in cnt, add ~1ms
			movi	ctra, #%00001_110		' COGs in sync! enable PLLs now - NCOs locked!
			waitcnt sync_cnt, #0			' wait ~1ms for PLLs to stabilize - PLLs locked!
			mov	vscl, #100			' insure initial WAITVIDs lock cleanly

' Main loop, display field - each COG alternately builds and displays four scan lines

vsync			mov	x, #vs				' do vertical sync lines
			call	#blank_vsync

vb_lines		mov	x, #vb				' do vertical back porch lines (# set at runtime)
			call	#blank_vsync

			mov	screen_ptr, screen_base		' reset screen pointer to upper-left character
			mov	row, #0				' reset row counter for cursor insertion
			mov	fours, #rows			' set number of 4-line builds for whole screen

			' Build four scan lines into scanbuff

fourline		mov	font_ptr, font_part		' get address of appropriate font section
			shl	font_ptr, #7+2
			add	font_ptr, font_base

			movd	:pixa, #scanbuff-1		' reset scanbuff address (pre-decremented)
			movd	:pixb, #scanbuff-1		' reset scanbuff address (pre-decremented)
			movd	:cola, #colorbuff-1		' reset colorbuff address (pre-decremented)
			movd	:colb, #colorbuff-1

			mov	y, #4				' must build scanbuff in four sections because
			mov	vscl, vscl_line2x		' ..pixel counter is limited to twelve bits

:halfrow		waitvid underscore, #0			' output lows to let other COG drive VGA pins
			mov	x, #cols/4			' ..for 2 scan lines, ready for a quarter row

:column		 	rdword	z, screen_ptr			' get character and colors from screen memory
			mov	bg, z
			ror	z, #7
			shr	z, #32 - 9		wc
			add	z, font_ptr			' add font section address to point to 8*4 pixels
			add	:pixa, d0			' increment scanbuff destination addresses
			add	:pixb, d0			' increment scanbuff destination addresses
			add	screen_ptr, #2			' increment screen memory address
			cmp	font_part, #1		wz
:pixa			rdlong	scanbuff, z			' read pixel long (8*4) into scanbuff
:pixb	if_c_and_z	or	scanbuff, underline

			ror	bg, #12				' background color in bits 3..0
			mov	fg, bg				' foreground color in bits 31..28
			shr	fg, #28				' bits 3..0
			add	fg, #fg_clut			' + offset to foreground CLUT
			movs	:cola, fg
			add	:cola, d0
			add	bg, #bg_clut			' + offset to background CLUT
			movs	:colb, bg
			add	:colb, d0
:cola			mov	colorbuff, 0-0
:colb			or	colorbuff, 0-0

			djnz	x, #:column			' another character in this half-row?
			djnz	y, #:halfrow			' loop to do 2nd half-row, time for 2nd WAITVID

			' Insert cursors into scanbuff

			mov	z, #2				' ready for two cursors

:cursor			rdbyte	x, cursor_base			' x in range?
			add	cursor_base, #1
			cmp	x, #cols	wc

			rdbyte	y, cursor_base			' y match?
			add	cursor_base, #1
			cmp	y, row		wz

			rdbyte	y, cursor_base			' get cursor mode
			add	cursor_base, #1

	if_nc_or_nz	jmp	#:nocursor			' if cursor not in scanbuff, no cursor

			add	x, #scanbuff			' cursor in scanbuff, set scanbuff address
			movd	:xor, x

			test	y, #%010	wc		' get mode bits into flags
			test	y, #%001	wz
	if_nc_and_z	jmp	#:nocursor			' if cursor disabled, no cursor

	if_c_and_z	test	slowbit, cnt	wc		' if blink mode, get blink state
	if_c_and_nz	test	fastbit, cnt	wc

			test	y, #%100	wz		' get box or underscore cursor piece
	if_z		mov	x, longmask
	if_nz		mov	x, underscore
	if_nz		cmp	font_part, #1	wz		' if underscore, must be last font section

:xor	if_nc_and_z	xor	scanbuff, x			' conditionally xor cursor into scanbuff

:nocursor		djnz	z, #:cursor			' second cursor?

			sub	cursor_base, #3*2		' restore cursor base

			' Display four scan lines from scanbuff

			mov	y, #4				' ready for four scan lines
scanline
			mov	x, #2		wc		' clear carry and set sweep count
sweep
			mov	vscl, vscl_chr
			waitvid	colorbuff+ 0, scanbuff+ 0
		if_c	ror	scanbuff+ 0, #8
			waitvid	colorbuff+ 1, scanbuff+ 1
		if_c	ror	scanbuff+ 1, #8
			waitvid	colorbuff+ 2, scanbuff+ 2
		if_c	ror	scanbuff+ 2, #8
			waitvid	colorbuff+ 3, scanbuff+ 3
		if_c	ror	scanbuff+ 3, #8
			waitvid	colorbuff+ 4, scanbuff+ 4
		if_c	ror	scanbuff+ 4, #8
			waitvid	colorbuff+ 5, scanbuff+ 5
		if_c	ror	scanbuff+ 5, #8
			waitvid	colorbuff+ 6, scanbuff+ 6
		if_c	ror	scanbuff+ 6, #8
			waitvid	colorbuff+ 7, scanbuff+ 7
		if_c	ror	scanbuff+ 7, #8

			waitvid	colorbuff+ 8, scanbuff+ 8
		if_c	ror	scanbuff+ 8, #8
			waitvid	colorbuff+ 9, scanbuff+ 9
		if_c	ror	scanbuff+ 9, #8
			waitvid	colorbuff+10, scanbuff+10
		if_c	ror	scanbuff+10, #8
			waitvid	colorbuff+11, scanbuff+11
		if_c	ror	scanbuff+11, #8
			waitvid	colorbuff+12, scanbuff+12
		if_c	ror	scanbuff+12, #8
			waitvid	colorbuff+13, scanbuff+13
		if_c	ror	scanbuff+13, #8
			waitvid	colorbuff+14, scanbuff+14
		if_c	ror	scanbuff+14, #8
			waitvid	colorbuff+15, scanbuff+15
		if_c	ror	scanbuff+15, #8

			waitvid	colorbuff+16, scanbuff+16 
		if_c	ror	scanbuff+16, #8
			waitvid	colorbuff+17, scanbuff+17 
		if_c	ror	scanbuff+17, #8
			waitvid	colorbuff+18, scanbuff+18
		if_c	ror	scanbuff+18, #8
			waitvid	colorbuff+19, scanbuff+19
		if_c	ror	scanbuff+19, #8
			waitvid	colorbuff+20, scanbuff+20
		if_c	ror	scanbuff+20, #8
			waitvid	colorbuff+21, scanbuff+21
		if_c	ror	scanbuff+21, #8
			waitvid	colorbuff+22, scanbuff+22
		if_c	ror	scanbuff+22, #8
			waitvid	colorbuff+23, scanbuff+23
		if_c	ror	scanbuff+23, #8

			waitvid	colorbuff+24, scanbuff+24
		if_c	ror	scanbuff+24, #8
			waitvid	colorbuff+25, scanbuff+25
		if_c	ror	scanbuff+25, #8
			waitvid	colorbuff+26, scanbuff+26
		if_c	ror	scanbuff+26, #8
			waitvid	colorbuff+27, scanbuff+27
		if_c	ror	scanbuff+27, #8
			waitvid	colorbuff+28, scanbuff+28
		if_c	ror	scanbuff+28, #8
			waitvid	colorbuff+29, scanbuff+29
		if_c	ror	scanbuff+29, #8
			waitvid	colorbuff+30, scanbuff+30
		if_c	ror	scanbuff+30, #8
			waitvid	colorbuff+31, scanbuff+31
		if_c	ror	scanbuff+31, #8

			waitvid	colorbuff+32, scanbuff+32
		if_c	ror	scanbuff+32, #8
			waitvid	colorbuff+33, scanbuff+33
		if_c	ror	scanbuff+33, #8
			waitvid	colorbuff+34, scanbuff+34
		if_c	ror	scanbuff+34, #8
			waitvid	colorbuff+35, scanbuff+35
		if_c	ror	scanbuff+35, #8
			waitvid	colorbuff+36, scanbuff+36
		if_c	ror	scanbuff+36, #8
			waitvid	colorbuff+37, scanbuff+37
		if_c	ror	scanbuff+37, #8
			waitvid	colorbuff+38, scanbuff+38
		if_c	ror	scanbuff+38, #8
			waitvid	colorbuff+39, scanbuff+39
		if_c	ror	scanbuff+39, #8

			waitvid	colorbuff+40, scanbuff+40
		if_c	ror	scanbuff+40, #8
			waitvid	colorbuff+41, scanbuff+41
		if_c	ror	scanbuff+41, #8
			waitvid	colorbuff+42, scanbuff+42
		if_c	ror	scanbuff+42, #8
			waitvid	colorbuff+43, scanbuff+43
		if_c	ror	scanbuff+43, #8
			waitvid	colorbuff+44, scanbuff+44
		if_c	ror	scanbuff+44, #8
			waitvid	colorbuff+45, scanbuff+45
		if_c	ror	scanbuff+45, #8
			waitvid	colorbuff+46, scanbuff+46
		if_c	ror	scanbuff+46, #8
			waitvid	colorbuff+47, scanbuff+47
		if_c	ror	scanbuff+47, #8

			waitvid	colorbuff+48, scanbuff+48
		if_c	ror	scanbuff+48, #8
			waitvid	colorbuff+49, scanbuff+49
		if_c	ror	scanbuff+49, #8
			waitvid	colorbuff+50, scanbuff+50
		if_c	ror	scanbuff+50, #8
			waitvid	colorbuff+51, scanbuff+51
		if_c	ror	scanbuff+51, #8
			waitvid	colorbuff+52, scanbuff+52
		if_c	ror	scanbuff+52, #8
			waitvid	colorbuff+53, scanbuff+53
		if_c	ror	scanbuff+53, #8
			waitvid	colorbuff+54, scanbuff+54
		if_c	ror	scanbuff+54, #8
			waitvid	colorbuff+55, scanbuff+55
		if_c	ror	scanbuff+55, #8

			waitvid	colorbuff+56, scanbuff+56
		if_c	ror	scanbuff+56, #8
			waitvid	colorbuff+57, scanbuff+57
		if_c	ror	scanbuff+57, #8
			waitvid	colorbuff+58, scanbuff+58
		if_c	ror	scanbuff+58, #8
			waitvid	colorbuff+59, scanbuff+59
		if_c	ror	scanbuff+59, #8
			waitvid	colorbuff+60, scanbuff+60
		if_c	ror	scanbuff+60, #8
			waitvid	colorbuff+61, scanbuff+61
		if_c	ror	scanbuff+61, #8
			waitvid	colorbuff+62, scanbuff+62
		if_c	ror	scanbuff+62, #8
			waitvid	colorbuff+63, scanbuff+63
		if_c	ror	scanbuff+63, #8

			waitvid	colorbuff+64, scanbuff+64
		if_c	ror	scanbuff+64, #8
			waitvid	colorbuff+65, scanbuff+65
		if_c	ror	scanbuff+65, #8
			waitvid	colorbuff+66, scanbuff+66
		if_c	ror	scanbuff+66, #8
			waitvid	colorbuff+67, scanbuff+67
		if_c	ror	scanbuff+67, #8
			waitvid	colorbuff+68, scanbuff+68
		if_c	ror	scanbuff+68, #8
			waitvid	colorbuff+69, scanbuff+69
		if_c	ror	scanbuff+69, #8
			waitvid	colorbuff+70, scanbuff+70
		if_c	ror	scanbuff+70, #8
			waitvid	colorbuff+71, scanbuff+71
		if_c	ror	scanbuff+71, #8

			waitvid	colorbuff+72, scanbuff+72
		if_c	ror	scanbuff+72, #8
			waitvid	colorbuff+73, scanbuff+73
		if_c	ror	scanbuff+73, #8
			waitvid	colorbuff+74, scanbuff+74
		if_c	ror	scanbuff+74, #8
			waitvid	colorbuff+75, scanbuff+75
		if_c	ror	scanbuff+75, #8
			waitvid	colorbuff+76, scanbuff+76
		if_c	ror	scanbuff+76, #8
			waitvid	colorbuff+77, scanbuff+77
		if_c	ror	scanbuff+77, #8
			waitvid	colorbuff+78, scanbuff+78
		if_c	ror	scanbuff+78, #8
			waitvid	colorbuff+79, scanbuff+79

			mov	vscl, #hf			' do horizontal front porch pixels
			waitvid hvsync, #0			' #0 makes hsync inactive
			mov	vscl, #hs			' do horizontal sync pixels
			waitvid hvsync, #1			' #1 makes hsync active
			mov	vscl, #hb			' do horizontal back porch pixels
			waitvid hvsync, #0			' #0 makes hsync inactive
		if_c	ror	scanbuff+79, #8
			test	x, #2			wc	' set carry
			djnz	x, #sweep
			djnz	y, #scanline			' another scan line?

			' Next group of four scan lines

			add	row, #1				' if new row, increment row counter
			djnz	fours, #fourline	 	' another 4-line build/display?

			' Visible section done, do vertical sync front porch lines

			wrlong	longmask,par			' write -1 to refresh indicator

vf_lines		mov	x,#vf				' do vertical front porch lines (# set at runtime)
			call	#blank

			jmp	#vsync				' new field, loop to vsync

			' Subroutine - do blank lines

blank_vsync		xor	hvsync,#$101			' flip vertical sync bits

blank			mov	vscl, hx		 	' do blank pixels
			waitvid hvsync, #0
			mov	vscl, #hf			' do horizontal front porch pixels
			waitvid hvsync, #0
			mov	vscl, #hs			' do horizontal sync pixels
			waitvid hvsync, #1
			mov	vscl, #hb			' do horizontal back porch pixels
			waitvid hvsync, #0
			djnz	x, #blank			' another line?
blank_ret
blank_vsync_ret
			ret

			' Data

screen_base		long	0				' set at runtime (3 contiguous longs)
cursor_base		long	0				' set at runtime

font_base		long	0				' set at runtime
font_part		long	0				' set at runtime

hx			long	hp				' visible pixels per scan line
vscl_line2x		long	(hp + hf + hs + hb) * 2 	' total number of pixels per 2 scan lines
vscl_chr		long	1 << 12 + 8			' 1 clock per pixel and 8 pixels per set
colormask		long	$fcfc				' mask to isolate R,G,B bits from H,V
longmask		long	$ffffffff			' all bits set
slowbit			long	1 << 25				' cnt mask for slow cursor blink
fastbit			long	1 << 24				' cnt mask for fast cursor blink
underscore		long	$ffff0000			' underscore cursor pattern
underline		long	$ff000000
hv			long	hv_inactive			' -H,-V states
hvsync			long	hv_inactive ^ $200		' +/-H,-V states
d0			long	1 << 9
d0s0			long	1 << 9 + 1
d1			long	1 << 10
reg_dira		long	0				' set at runtime
reg_dirb		long	0				' set at runtime
reg_vcfg		long	0				' set at runtime
sync_cnt		long	0				' set at runtime

bg_clut			long	%00000011_00000011		' black
			long	%00000011_00001011		' dark blue
			long	%00000011_00100011		' dark green
			long	%00000011_00101011		' dark cyan
			long	%00000011_10000011		' dark red
			long	%00000011_10001011		' dark magenta
			long	%00000011_10100011		' brown
			long	%00000011_10101011		' light gray
			long	%00000011_01010111		' dark gray
			long	%00000011_00001111		' light blue
			long	%00000011_00110011		' light green
			long	%00000011_00111111		' light cyan
			long	%00000011_11000011		' light red
			long	%00000011_11001111		' light magenta
			long	%00000011_11110011		' light yellow
			long	%00000011_11111111		' white

fg_clut			long	%00000011_00000011		' black
			long	%00000111_00000011		' dark blue
			long	%00010011_00000011		' dark green
			long	%00010111_00000011		' dark cyan
			long	%01000011_00000011		' dark red
			long	%01000111_00000011		' dark magenta
			long	%01010011_00000011		' brown
			long	%10101011_00000011		' light gray
			long	%01010111_00000011		' dark gray
			long	%00001011_00000011		' blue
			long	%00100011_00000011		' green
			long	%00101011_00000011		' cyan
			long	%10000011_00000011		' red
			long	%10001011_00000011		' magenta
			long	%10100011_00000011		' yellow
			long	%11111111_00000011		' white

			' Uninitialized data

screen_ptr		res	1
font_ptr		res	1

x			res	1
y			res	1
z			res	1
fg			res	1
bg			res	1

row			res	1
fours			res	1

scanbuff		res	80
colorbuff		res	80

			fit	$1f0

' 8 x 12 font - characters 0..127
'
' Each long holds four scan lines of a single character. The longs are arranged into
' groups of 128 which represent all characters (0..127). There are four groups which
' each contain a vertical part of all characters. They are ordered top, middle, and
' bottom.

font	long
  long $00000000,$0f0f0f0f,$f0f0f0f0,$ffffffff,$00000000,$0f0f0f0f,$f0f0f0f0,$ffffffff
  long $00000000,$0f0f0f0f,$f0f0f0f0,$ffffffff,$00000000,$0f0f0f0f,$f0f0f0f0,$ffffffff
  long $7e5a3c00,$7e3c1800,$7e7e2400,$7e3c1800,$f8000000,$1f000000,$f8181818,$1f181818
  long $18181818,$ff000000,$1f181818,$f8181818,$ff181818,$ff000000,$ff181818,$aa55aa55
  long $00000000,$18181800,$66666600,$66ff6600,$3c067c18,$18366600,$1c386c38,$18181800
  long $0c0c1830,$3030180c,$ff3c6600,$7e181800,$00000000,$7e000000,$00000000,$18306000
  long $76663c00,$181c1800,$30663c00,$18307e00,$3c383000,$3e067e00,$3e063c00,$30607e00
  long $3c663c00,$7c663c00,$18180000,$18180000,$0c183060,$007e0000,$30180c06,$30663c00
  long $76663c00,$663c1800,$3e663e00,$06663c00,$66361e00,$3e067e00,$3e067e00,$06067c00
  long $7e666600,$18187e00,$60606000,$1e366600,$06060600,$feeec600,$7e6e6600,$66663c00
  long $66663e00,$66663c00,$66663e00,$3c063c00,$18187e00,$66666600,$66666600,$d6c6c600
  long $3c666600,$3c666600,$18307e00,$0c0c0c3c,$0c060200,$3030303c,$c66c3810,$00000000
  long $30180c00,$603c0000,$3e060600,$063c0000,$7c606000,$663c0000,$7c187000,$667c0000
  long $3e060600,$1c001800,$60006000,$36060600,$18181c00,$fe660000,$663e0000,$663c0000
  long $663e0000,$667c0000,$663e0000,$067c0000,$187e1800,$66660000,$66660000,$d6c60000
  long $3c660000,$66660000,$307e0000,$0c181830,$18181800,$3018180c,$0000366c,$142a142a

  long $00000000,$00000000,$00000000,$00000000,$0f0f0f0f,$0f0f0f0f,$0f0f0f0f,$0f0f0f0f
  long $f0f0f0f0,$f0f0f0f0,$f0f0f0f0,$f0f0f0f0,$ffffffff,$ffffffff,$ffffffff,$ffffffff
  long $007e187e,$007e187e,$00183c7e,$00183c7e,$181818f8,$1818181f,$000000f8,$0000001f
  long $18181818,$000000ff,$1818181f,$181818f8,$000000ff,$181818ff,$181818ff,$aa55aa55
  long $00000000,$00180018,$00000000,$0066ff66,$00183e60,$0062660c,$00dc66f6,$00000000
  long $30180c0c,$0c183030,$0000663c,$00001818,$0c181800,$00000000,$00181800,$0002060c
  long $003c666e,$007e1818,$007e0c18,$003c6630,$00307e36,$003c6660,$003c6666,$000c0c18
  long $003c6666,$001c3060,$00181800,$0c181800,$00603018,$00007e00,$00060c18,$00180018
  long $007c0676,$00667e66,$003e6666,$003c6606,$001e3666,$007e0606,$00060606,$007c6676
  long $00666666,$007e1818,$003c6660,$0066361e,$007e0606,$00c6c6d6,$0066767e,$003c6666
  long $0006063e,$006c3666,$0066363e,$003c6060,$00181818,$007e6666,$00183c66,$00c6eefe
  long $0066663c,$00181818,$007e060c,$3c0c0c0c,$00603018,$3c303030,$00000000,$ff000000
  long $00000000,$007c667c,$003e6666,$003c0606,$007c6666,$003c067e,$00181818,$3e607c66
  long $00666666,$003c1818,$3c606060,$0066361e,$003c1818,$00c6d6fe,$00666666,$003c6666
  long $06063e66,$60607c66,$00060606,$003e603c,$00701818,$007c6666,$00183c66,$006c7cfe
  long $00663c18,$1e307c66,$007e0c18,$00301818,$00181818,$000c1818,$00000000,$002a142a


{{
+------------------------------------------------------------------------------------------------------------------------------+
|				    TERMS OF USE: Parallax Object Exchange License					       |
+------------------------------------------------------------------------------------------------------------------------------+
|Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation    | |files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,    |
|modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software|
|is furnished to do so, subject to the following conditions:                                                                   |
|                                                                                                                              |
|The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.|
|                                                                                                                              |
|THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE	       |
|WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR         |
|COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,   |
|ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                         |
+------------------------------------------------------------------------------------------------------------------------------+
}}
