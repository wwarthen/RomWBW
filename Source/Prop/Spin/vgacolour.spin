''***************************************
''*  VGA High-Res Text Driver v1.0      *
''*  Author: Chip Gracey                *
''*  Copyright (c) 2006 Parallax, Inc.  *
''*  See end of file for terms of use.  *
''***************************************
''
'' This object generates a 640x480 VGA signal which contains 80 columns x 30
'' rows of 8x16 characters. Each character can have a unique forground/background
'' color combination and each character can be inversed and high-lighted.
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

{
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
}
	
'{
' 640 x 480 @ 60Hz settings: 80 x 40 characters

  hp = 640      'horizontal pixels
  vp = 480      'vertical pixels
  hf = 16       'horizontal front porch pixels
  hs = 96       'horizontal sync pixels
  hb = 48      'horizontal back porch pixels
  vf = 10        'vertical front porch lines
  vs = 2        'vertical sync lines
  vb = 33       'vertical back porch lines
  hn = 1        'horizontal normal sync state (0|1)
  vn = 1        'vertical normal sync state (0|1)
  pr = 25       'pixel rate in MHz at 80MHz system clock (5MHz granularity)
'}


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
	cog[1] := cognew(@d0, SyncPtr) + 1

	' allow time for first COG to launch
	waitcnt($2000 + cnt)

	' differentiate settings and launch second COG
	vf_lines.byte := vf+4
	vb_lines.byte := vb-4
	font_part := 0
	cog[0] := cognew(@d0, SyncPtr) + 1

	' if both COGs launched, return true
	if cog[0] and cog[1]
		'return true
		return 0

	' else, stop any launched COG and return false
	stop


PUB stop | i

'' Stop VGA driver - frees two COGs

	repeat i from 0 to 1
	  if cog[i]
	    cogstop(cog[i]~ - 1)


CON

	#1, scanbuff[80], colorbuff[80], scancode[2*80-1+3], maincode	'enumerate COG RAM usage

	main_size = $1F0 - maincode				'size of main program

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
' COG RAM usage:	$000	= d0 - used to inc destination fields for indirection
'		 $001-$050 = scanbuff - longs which hold 4 scan lines
'		 $051-$010 = colorbuff - longs which hold colors for 80 characters
'		 $0a1-$142 = scancode - stacked WAITVID/SHR for fast display
'		 $143-$1EF = maincode - main program loop which drives display

			org	0				' set origin to $000 for start of program

d0			long	1 << 9				' d0 always resides here at $000, executes as NOP


' Initialization code and data - after execution, space gets reused as scanbuff

			' Move main program into maincode area

:move			mov	$1EF, main_begin + main_size - 1
			sub	:move,d0s0			' (do reverse move to avoid overwrite)
			djnz	main_ctr,#:move

			' Build scanbuff display routine into scancode

:waitvid		mov	scancode+0, i0			' org	scancode
:shr			mov	scancode+1, i1			' waitvid colorbuff+0, scanbuff+0
			add	:waitvid, d1			' shr	scanbuff+0,#8
			add	:shr, d1		 	' waitvid colorbuff+1, scanbuff+1
			add	i0, d0s0			' shr	scanbuff+1,#8
			add	i1, d0				' ...
			djnz	scan_ctr, #:waitvid		' waitvid colorbuff+cols-1, scanbuff+cols-1

			mov	scancode+cols*2-1, i2		' mov	vscl,#hf
			mov	scancode+cols*2+0, i3		' waitvid hvsync,#0
			mov	scancode+cols*2+1, i4		' jmp	#scanret

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

			' Jump to main loop

			jmp	#vsync				' jump to vsync - WAITVIDs will now be locked!

			' Data

d0s0			long	1 << 9 + 1
d1			long	1 << 10
main_ctr		long	main_size
scan_ctr		long	cols

i0			waitvid colorbuff+0, scanbuff+0
i1			shr	scanbuff+0, #8
i2			mov	vscl, #hf
i3			waitvid hvsync, #0
i4			jmp	#scanret

reg_dira		long	0				' set at runtime
reg_dirb		long	0				' set at runtime
reg_vcfg		long	0				' set at runtime
sync_cnt		long	0				' set at runtime

			' Directives

			fit	scancode			' make sure initialization code and data fit
main_begin		org	maincode			' main code follows (gets moved into maincode)


' Main loop, display field - each COG alternately builds and displays four scan lines

vsync			mov	x, #vs				' do vertical sync lines
			call	#blank_vsync

vb_lines		mov	x, #vb				' do vertical back porch lines (# set at runtime)
			call	#blank_vsync

			mov	screen_ptr, screen_base		' reset screen pointer to upper-left character
			mov	row, #0				' reset row counter for cursor insertion
			mov	fours, #rows * 4 / 2		' set number of 4-line builds for whole screen

			' Build four scan lines into scanbuff

fourline		mov	font_ptr, font_part		' get address of appropriate font section
			shl	font_ptr, #8+2
			add	font_ptr, font_base

			movd	:pixa, #scanbuff-1		' reset scanbuff address (pre-decremented)
			movd	:cola, #colorbuff-1		' reset colorbuff address (pre-decremented)
			movd	:colb, #colorbuff-1

			mov	y, #2				' must build scanbuff in two sections because
			mov	vscl, vscl_line2x		' ..pixel counter is limited to twelve bits

:halfrow		waitvid underscore, #0			' output lows to let other COG drive VGA pins
			mov	x, #cols/2			' ..for 2 scan lines, ready for half a row

:column		 	rdword	z, screen_ptr			' get character and colors from screen memory
			mov	bg, z
			and	z, #$ff				' mask character code
			shl	z, #2				' * 4
			add	z, font_ptr			' add font section address to point to 8*4 pixels
			add	:pixa, d0			' increment scanbuff destination addresses
			add	screen_ptr, #2			' increment screen memory address
:pixa			rdlong	scanbuff, z			' read pixel long (8*4) into scanbuff

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

			sub	screen_ptr, #2*cols		' back up to start of same row in screen memory

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
	if_nz		cmp	font_part, #3	wz		' if underscore, must be last font section

:xor	if_nc_and_z	xor	scanbuff, x			' conditionally xor cursor into scanbuff

:nocursor		djnz	z, #:cursor			' second cursor?

			sub	cursor_base, #3*2		' restore cursor base

			' Display four scan lines from scanbuff

			mov	y, #4				' ready for four scan lines

scanline		mov	vscl, vscl_chr			' set pixel rate for characters
			jmp	#scancode			' jump to scanbuff display routine in scancode
scanret			 mov	vscl, #hs			' do horizontal sync pixels
			waitvid hvsync, #1			' #1 makes hsync active
			mov	vscl, #hb			' do horizontal back porch pixels
			waitvid hvsync, #0			' #0 makes hsync inactive
			shr	scanbuff+cols-1, #8		' shift last column's pixels right by 8
			djnz	y, #scanline			' another scan line?

			' Next group of four scan lines

			add	font_part, #2			' if font_part + 2 => 4, subtract 4 (new row)
			cmpsub	font_part, #4		wc	' c=0 for same row, c=1 for new row
	if_c		add	screen_ptr, #2*cols		' if new row, advance screen pointer
	if_c		add	row, #1				' if new row, increment row counter
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
			djnz	x,#blank			' another line?
blank_ret
blank_vsync_ret
			ret

			' Data

screen_base		long	0				' set at runtime (3 contiguous longs)
cursor_base		long	0				' set at runtime

font_base		long	0				' set at runtime
font_part		long	0				' set at runtime

hx			long	hp				' visible pixels per scan line
vscl_line		long	hp + hf + hs + hb		' total number of pixels per scan line
vscl_line2x		long	(hp + hf + hs + hb) * 2 	' total number of pixels per 2 scan lines
vscl_chr		long	1 << 12 + 8			' 1 clock per pixel and 8 pixels per set
colormask		long	$FCFC				' mask to isolate R,G,B bits from H,V
longmask		long	$FFFFFFFF			' all bits set
slowbit			long	1 << 25				' cnt mask for slow cursor blink
fastbit			long	1 << 24				' cnt mask for fast cursor blink
underscore		long	$FFFF0000			' underscore cursor pattern
hv			long	hv_inactive			' -H,-V states
hvsync			long	hv_inactive ^ $200		' +/-H,-V states

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


			fit	$1f0

' 8 x 12 font - characters 0..127
'
' Each long holds four scan lines of a single character. The longs are arranged into
' groups of 128 which represent all characters (0..127). There are four groups which
' each contain a vertical part of all characters. They are ordered top, middle, and
' bottom.

font	long
  long $0082ba00,$00000000,$2a552a00,$36360000,$061e0000,$061c0000,$06060000,$3c000000
  long $00000000,$6e660000,$66660000,$18181818,$00000000,$00000000,$18181818,$18181818
  long $0000ffff,$00000000,$00000000,$00000000,$00000000,$18181818,$18181818,$18181818
  long $00000000,$18181818,$60000000,$06000000,$00000000,$00000000,$38000000,$00000000
  long $00000000,$18000000,$36000000,$24000000,$18000000,$4e000000,$1c000000,$18000000
  long $30000000,$0c000000,$00000000,$00000000,$00000000,$00000000,$00000000,$60000000
  long $18000000,$18000000,$3c000000,$7e000000,$60000000,$7e000000,$3c000000,$7e000000
  long $3c000000,$3c000000,$00000000,$00000000,$60000000,$00000000,$06000000,$3c000000
  long $3c000000,$3c000000,$3e000000,$3c000000,$3e000000,$7e000000,$7e000000,$3c000000
  long $66000000,$7e000000,$60000000,$46000000,$06000000,$42000000,$66000000,$3c000000
  long $3e000000,$3c000000,$3e000000,$3c000000,$7e000000,$66000000,$66000000,$66000000
  long $42000000,$66000000,$7e000000,$3c000000,$06000000,$3c000000,$18000000,$00000000
  long $180c0000,$00000000,$06000000,$00000000,$60000000,$00000000,$38000000,$00000000
  long $06000000,$18000000,$60000000,$06000000,$1c000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$38000000,$18000000,$1c000000,$4c000000,$aa55aa55
  long $00000000,$00000000,$2a552a00,$36360000,$061e0000,$061c0000,$06060000,$3c000000
  long $00000000,$6e660000,$66660000,$24242424,$00000000,$00000000,$24242424,$24242424
  long $00ff00ff,$ff000000,$00000000,$00000000,$00000000,$24242424,$24242424,$24242424
  long $00000000,$24242424,$60000000,$06000000,$00000000,$00000000,$38000000,$00000000
  long $00000000,$18000000,$36000000,$24000000,$18000000,$4e000000,$1c000000,$18000000
  long $30000000,$0c000000,$00000000,$00000000,$00000000,$00000000,$00000000,$60000000
  long $18000000,$18000000,$3c000000,$7e000000,$60000000,$7e000000,$3c000000,$7e000000
  long $3c000000,$3c000000,$00000000,$00000000,$60000000,$00000000,$06000000,$3c000000
  long $3c000000,$3c000000,$3e000000,$3c000000,$3e000000,$7e000000,$7e000000,$3c000000
  long $66000000,$7e000000,$60000000,$46000000,$06000000,$42000000,$66000000,$3c000000
  long $3e000000,$3c000000,$3e000000,$3c000000,$7e000000,$66000000,$66000000,$66000000
  long $42000000,$66000000,$7e000000,$3c000000,$06000000,$3c000000,$18000000,$00000000
  long $180c0000,$00000000,$06000000,$00000000,$60000000,$00000000,$38000000,$00000000
  long $06000000,$18000000,$60000000,$06000000,$1c000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$38000000,$18000000,$1c000000,$4c000000,$aa55aa55
  long $82008282,$3c180000,$2a552a55,$0036363e,$0006060e,$001c0606,$001e0606,$003c6666
  long $187e1818,$0066767e,$00183c24,$1f181818,$1f000000,$f8000000,$f8181818,$ff181818
  long $00000000,$0000ffff,$00000000,$00000000,$00000000,$f8181818,$1f181818,$ff181818
  long $ff000000,$18181818,$0c060c30,$3060300c,$667e0000,$187e3030,$3e0c0c6c,$18180000
  long $00000000,$18181818,$00003636,$247e7e24,$3c1a5a3c,$18302e6a,$1c363636,$00181818
  long $0c0c1818,$30301818,$7e182400,$7e181800,$00000000,$00000000,$00000000,$18303060
  long $66666624,$18181a1c,$38606666,$3c183060,$666c7870,$663e0606,$3e060666,$30306060
  long $3c666666,$7c666666,$183c1800,$183c1800,$060c1830,$007e0000,$6030180c,$38606666
  long $6a7a6262,$7e666666,$3e666666,$06060666,$66666666,$3e060606,$3e060606,$76060666
  long $7e666666,$18181818,$60606060,$0e1e3666,$06060606,$667e7e66,$7e6e6e66,$66666666
  long $3e666666,$66666666,$3e666666,$3c060666,$18181818,$66666666,$24246666,$66666666
  long $183c2466,$183c3c66,$18306060,$0c0c0c0c,$180c0c06,$30303030,$0042663c,$00000000
  long $00000030,$603c0000,$663e0606,$663c0000,$667c6060,$663c0000,$1e0c0c6c,$665c0000
  long $663e0606,$181c0018,$60600060,$36660606,$18181818,$fe6a0000,$663e0000,$663c0000
  long $663e0000,$667c0000,$663e0000,$663c0000,$0c3e0c0c,$66660000,$66660000,$66660000
  long $66660000,$66660000,$607e0000,$0c180c0c,$18181818,$30183030,$0000327e,$aa55aa55
  long $00000000,$3c180000,$2a552a55,$0036363e,$0006060e,$001c0606,$001e0606,$003c6666
  long $187e1818,$0066767e,$00183c24,$20272424,$203f0000,$04fc0000,$04e42424,$00e72424
  long $00000000,$0000ff00,$ff000000,$00000000,$00000000,$04e42424,$20272424,$00e72424
  long $00ff0000,$24242424,$0c060c30,$3060300c,$667e0000,$187e3030,$3e0c0c6c,$18180000
  long $00000000,$18181818,$00003636,$247e7e24,$3c1a5a3c,$18302e6a,$1c363636,$00181818
  long $0c0c1818,$30301818,$7e182400,$7e181800,$00000000,$00000000,$00000000,$18303060
  long $66666624,$18181a1c,$38606666,$3c183060,$666c7870,$663e0606,$3e060666,$30306060
  long $3c666666,$7c666666,$183c1800,$183c1800,$060c1830,$007e0000,$6030180c,$38606666
  long $76766666,$7e666666,$3e666666,$06060666,$66666666,$3e060606,$3e060606,$76060666
  long $7e666666,$18181818,$60606060,$0e1e3666,$06060606,$667e7e66,$7e6e6e66,$66666666
  long $3e666666,$66666666,$3e666666,$3c060666,$18181818,$66666666,$24246666,$66666666
  long $183c2466,$183c3c66,$18306060,$0c0c0c0c,$180c0c06,$30303030,$0042663c,$00000000
  long $00000030,$603c0000,$663e0606,$663c0000,$667c6060,$663c0000,$1e0c0c6c,$665c0000
  long $663e0606,$181c0018,$60600060,$36660606,$18181818,$fe6a0000,$663e0000,$663c0000
  long $663e0000,$667c0000,$663e0000,$663c0000,$0c3e0c0c,$66660000,$66660000,$66660000
  long $66660000,$66660000,$607e0000,$0c180c0c,$18181818,$30183030,$0000327e,$aa55aa55
  long $82820082,$00183c7e,$2a552a55,$30303078,$18381878,$58385838,$18381878,$00000000
  long $007e0018,$18181818,$30303078,$0000001f,$1818181f,$181818f8,$000000f8,$181818ff
  long $00000000,$00000000,$0000ffff,$ff000000,$00000000,$181818f8,$1818181f,$000000ff
  long $181818ff,$18181818,$7e006030,$7e00060c,$66666666,$0c0c7e18,$3a6c0c0c,$00000000
  long $00000000,$18180018,$00000000,$24247e7e,$183c5a58,$7256740c,$5c367656,$00000000
  long $3018180c,$0c181830,$0024187e,$0018187e,$18383800,$0000007e,$3c180000,$06060c0c
  long $18246666,$7e181818,$7e06060c,$3c666060,$60607e66,$3c666060,$3c666666,$0c0c1818
  long $3c666666,$3c666060,$3c180000,$18383800,$6030180c,$00007e00,$060c1830,$18180018
  long $3c62027a,$66666666,$3e666666,$3c660606,$3e666666,$7e060606,$06060606,$7c666666
  long $66666666,$7e181818,$3c666060,$4666361e,$7e060606,$66666666,$66667676,$3c666666
  long $06060606,$3c766e66,$4666361e,$3c666060,$18181818,$3c666666,$1818183c,$42667e7e
  long $4266243c,$18181818,$7e06060c,$3c0c0c0c,$60603030,$3c303030,$00000000,$fe000000
  long $00000000,$7c66667c,$3e666666,$3c660606,$7c666666,$3c66067e,$0c0c0c0c,$3c063c66
  long $66666666,$7e181818,$60606060,$66361e1e,$7e181818,$c6c6d6d6,$66666666,$3c666666
  long $063e6666,$607c6666,$06060606,$3c66300c,$386c0c0c,$7c666666,$183c3c66,$247e7e66
  long $66663c3c,$607c6666,$7e060c30,$380c0c18,$18181818,$1c303018,$00000000,$aa55aa55
  long $00000000,$00183c7e,$2a552a55,$30303078,$18381878,$58385838,$18381878,$00000000
  long $007e0018,$18181818,$30303078,$00003f20,$24242720,$2424e404,$0000fc04,$2424e700
  long $00000000,$00000000,$0000ff00,$00ff0000,$00000000,$2424e404,$24242720,$0000ff00
  long $2424e700,$24242424,$7e006030,$7e00060c,$66666666,$0c0c7e18,$3a6c0c0c,$00000000
  long $00000000,$18180018,$00000000,$24247e7e,$183c5a58,$7256740c,$5c367656,$00000000
  long $3018180c,$0c181830,$0024187e,$0018187e,$18383800,$0000007e,$3c180000,$06060c0c
  long $18246666,$7e181818,$7e06060c,$3c666060,$60607e66,$3c666060,$3c666666,$0c0c1818
  long $3c666666,$3c666060,$3c180000,$18383800,$6030180c,$00007e00,$060c1830,$18180018
  long $3c660676,$66666666,$3e666666,$3c660606,$3e666666,$7e060606,$06060606,$7c666666
  long $66666666,$7e181818,$3c666060,$4666361e,$7e060606,$66666666,$66667676,$3c666666
  long $06060606,$3c766e66,$4666361e,$3c666060,$18181818,$3c666666,$1818183c,$42667e7e
  long $4266243c,$18181818,$7e06060c,$3c0c0c0c,$60603030,$3c303030,$00000000,$fe000000
  long $00000000,$7c66667c,$3e666666,$3c660606,$7c666666,$3c66067e,$0c0c0c0c,$3c063c66
  long $66666666,$7e181818,$60606060,$66361e1e,$7e181818,$c6c6d6d6,$66666666,$3c666666
  long $063e6666,$607c6666,$06060606,$3c66300c,$386c0c0c,$7c666666,$183c3c66,$247e7e66
  long $66663c3c,$607c6666,$7e060c30,$380c0c18,$18181818,$1c303018,$00000000,$aa55aa55
  long $00ba8200,$00000000,$00002a55,$00000030,$00000018,$00000058,$00000018,$00000000
  long $00000000,$00000078,$00000030,$00000000,$18181818,$18181818,$00000000,$18181818
  long $00000000,$00000000,$00000000,$000000ff,$ffff0000,$18181818,$18181818,$00000000
  long $18181818,$18181818,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$0000000c,$00000000,$00000018,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000018,$0000000c,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000060,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$000000fe
  long $00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000,$00003c66
  long $00000000,$00000000,$00003c66,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000606,$00006060,$00000000,$00000000,$00000000,$00000000,$00000000,$00000000
  long $00000000,$00003c66,$00000000,$00000000,$00000000,$00000000,$00000000,$aa55aa55
  long $ff000000,$ff000000,$ff002a55,$ff000030,$ff000018,$ff000058,$ff000018,$ff000000
  long $ff000000,$ff000078,$ff000030,$00000000,$24242424,$24242424,$00000000,$24242424
  long $00000000,$00000000,$00000000,$000000ff,$ff00ff00,$24242424,$24242424,$00000000
  long $24242424,$24242424,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff00000c,$ff000000,$ff000018,$ff000000
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000000,$ff000018,$ff00000c,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000060,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff0000fe
  long $ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff003c66
  long $ff000000,$ff000000,$ff003c66,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000606,$ff006060,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000
  long $ff000000,$ff003c66,$ff000000,$ff000000,$ff000000,$ff000000,$ff000000,$ff55aa55


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
