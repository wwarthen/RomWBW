;
;=======================================================================
; PS/2 Keyboard/Mouse Information Utility (PS2INFO)
;=======================================================================
;
; Simple utility that performs simple tests of an 8242 PS/2 controller,
; keyboard, and mouse.
;
; WBW 2022-03-28: Add menu driven port selection
;                 Add support for RHYOPHYRE
; WBW 2022-04-01: Add menu for test functions
; WBW 2022-04-02: Fix prtchr register saving/recovery
;
;=======================================================================
;
; PS/2 Keyboard/Mouse controller port addresses (adjust as needed)
;
; MBC:
iocmd_mbc	.equ	$E3	; PS/2 controller command port address
iodat_mbc	.equ	$E2	; PS/2 controller data port address
; RPH:
iocmd_rph	.equ	$8D	; PS/2 controller command port address
iodat_rph	.equ	$8C	; PS/2 controller data port address
;
cpumhz	.equ	8	; for time delay calculations (not critical)
;
; General operational equates (should not requre adjustment)
;
stksiz	.equ	$40			; Working stack size
;
ltimout	.equ	0			; 256*10ms = 2.56s
stimout	.equ	10			; 10*10ms = 100ms
;
restart	.equ	$0000			; CP/M restart vector
bdos	.equ	$0005			; BDOS invocation vector
;
;=======================================================================
;
	.org	$100	; standard CP/M executable
;
;
	; setup stack (save old value)
	ld	(stksav),sp		; save stack
	ld	sp,stack		; set new stack
;
	call	crlf
	ld	de,str_banner		; banner
	call	prtstr
;
	call	setup
;
	call	main			; do the real work
;
exit:
	call	crlf2
	ld	de,str_exit
	call	prtstr

	; clean up and return to command processor
	call	crlf			; formatting
	ld	sp,(stksav)		; restore stack
	jp	restart			; return to CP/M via restart
;
;=======================================================================
; Select and setup for hardware
;=======================================================================
;
setup:
	call	crlf2
	ld	de,str_hwmenu
	call	prtstr
setup1:
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	0
	jr	z,setup1
	call	upcase
	call	prtchr
	cp	'1'			; MBC
	jr	z,setup_mbc
	cp	'2'			; RHYOPHYRE
	jr	z,setup_rph
	cp	'X'
	jr	z,exit
	jr	setup
;
setup_mbc:
	ld	a,iocmd_mbc
	ld	(iocmd),a
	ld	a,iodat_mbc
	ld	(iodat),a
	ld	de,str_mbc
	jr	setup2
;
setup_rph:
	ld	a,iocmd_rph
	ld	(iocmd),a
	ld	a,iodat_rph
	ld	(iodat),a
	ld	de,str_rph
	jr	setup2
;
setup2:
	call	prtstr
	call	crlf2
	ld	de,str_cmdport
	call	prtstr
	;ld	a,iocmd
	ld	a,(iocmd)
	call	prthex
	call	crlf
	ld	de,str_dataport
	call	prtstr
	;ld	a,iodat
	ld	a,(iodat)
	call	prthex
;
	xor	a
	ret
;
;=======================================================================
; Main Program
;=======================================================================
;
main:
	call	crlf2
	ld	de,str_menu
	call	prtstr
main1:
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	0
	jr	z,main1
	call	upcase
	call	prtchr
	cp	'X'
	jp	z,exit
	call	main2
	jr	main
;
main2:
	; Dispatch to test functions
	cp	'C'			; Test Controller
	jp	z,test_ctlr
	cp	'K'			; Test Keyboard
	jp	z,test_kbd
	cp	'M'			; Test Mouse
	jp	z,test_mse
	cp	'B'			; Test Both
	jp	z,test_kbdmse
	ret
;
; Test 8242 PS/2 Controller
;
test_ctlr:
	call	crlf2
	ld	de,str_ctlr
	call	prtstr
;
	call	ctlr_test
	ret	nz
;
	call	ctlr_test_p1
;
	call	ctlr_test_p2
;
	ret
;
; Test Keyboard
;
test_kbd:
;
; First, we attempt to contact the controller and keyboard, then
; print the keyboard identity and scan codes supported
;
	call	crlf2
	ld	de,str_basic
	call	prtstr
;
	call	ctlr_test
	jr	nz,test_kbd_fail
;
	call	test_kbd_basic
	jr	nz,test_kbd_fail
;
; We make two passes through the test series with different controller
; setup values.  The first time is with scan code translation off and
; the second time with it on.
;
	; Run test series with translation off
	call	crlf2
	ld	de,str_trans_off
	call	prtstr
;
	ld	a,$20			; kbd enabled, xlat disabled, mouse disabled, no ints
	ld	(ctlr_cfgval),a
	call	test_kbd_keys
;
	; Run test series with translation on
	call	crlf2
	ld	de,str_trans_on
	call	prtstr
;
	ld	a,$60			; kbd enabled, xlat enabled, mouse disabled, no ints
	ld	(ctlr_cfgval),a
	call	test_kbd_keys
;
	ret
;
test_kbd_fail:
	ld	de,str_kbd_failed
	call	crlf2
	call	prtstr
	ret
;
; Test Mouse
;
test_mse:
	call	crlf2
	ld	de,str_basic_mse
	call	prtstr
;
	call	ctlr_test
	jr	nz,test_mse_fail
;
	ld	a,$10			; kbd disabled, mse enabled, no ints
	call	ctlr_setup
	jr	nz,test_mse_fail
;
	call	mse_reset
	jr	nz,test_mse_fail
;
	call	mse_ident
	jr	nz,test_mse_fail
;
	call	mse_stream
	jr	nz,test_mse_fail
;
	call	mse_echo
;	
	xor	a			; signal success
	ret
;
test_mse_fail:
	ld	de,str_mse_failed
	call	crlf2
	call	prtstr
	ret
;
; Test Everything
;
test_kbdmse:
	call	crlf2
	ld	de,str_kbdmse
	call	prtstr
;
	call	ctlr_test
	jr	nz,test_kbdmse_fail
;
	ld	a,$00			; kbd enabled, mse enabled, no ints
	call	ctlr_setup
	jr	nz,test_kbdmse_fail
;
	call	kbd_reset
	jr	nz,test_kbdmse_fail
;
	ld	a,2
	call	kbd_setsc
;
	call	mse_reset
	jr	nz,test_kbdmse_fail
;
	call	mse_stream
	jr	nz,test_kbdmse_fail
;
	call	kbdmse_echo
;	
	xor	a			; signal success
	ret
;
test_kbdmse_fail:
	ld	de,str_kbdmse_failed
	call	crlf2
	call	prtstr
	ret
;
; Perform basic keyboard tests, display keyboard identity, and
; inventory the supported scan code sets.
;
test_kbd_basic:
	ld	a,$20			; Xlat off for this checking
	call	ctlr_setup
	ret	nz
;
	call	kbd_reset
	ret	nz
;
	call	kbd_ident
	;ret	nz
;
	ld	b,3			; Loop control, 3 scan code sets
	ld	c,1			; Current scan code number
test_kbd_basic1:
	ld	a,c			; Scan code set to A
	push	bc
	call	kbd_setsc		; Attempt to set it
	pop	bc
	push	af			; save result
	call	crlf2
	ld	de,str_sc_tag
	call	prtstr
	ld	a,c
	call	prtdecb
	pop	af			; restore result
	ld	de,str_sc_ok
	jr	z,test_kbd_basic2
	ld	de,str_sc_fail
test_kbd_basic2:
	call	prtstr
	inc	c
	djnz	test_kbd_basic1
;
	xor	a			; signal success
	ret
;
; This routine runs a series of controller and keyboard tests.  The
; desired controller setup value should be placed in ctlr_cfgval
; prior to invoking this routine.
;
test_kbd_keys:
	ld	a,(ctlr_cfgval)
	call	ctlr_setup
	ret	nz
;
	call	kbd_reset
	ret	nz
;
	call	kbd_ident
	;ret	nz
;
	ld	a,2
	call	kbd_setsc
	;ret	nz
;
	call	kbd_dispsc
	;ret	nz
;
	call	kbd_echo
	;ret	nz
;
	xor	a			; signal success
	ret
;
;=======================================================================
; Controller/Keyboard/Mouse Test Routines
;=======================================================================
;
; Attempt self-test command on PS/2 controller
;
;   PS/2 controller should respond with an 0x55 on data port
;   after being sent a 0xAA on the command port.
;
ctlr_test:
	call	crlf2
	ld	de,str_ctlr_test
	call	prtstr
	ld	a,$aa			; self-test command
	call	put_cmd_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$55			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctlr_test_ok
	call	prtstr
	xor	a
	ret
;
; Attempt self-test of first port of controller
;
ctlr_test_p1:
	call	crlf2
	ld	de,str_ctlr_test_p1
	call	prtstr
	ld	a,$ab			; self-test first port
	call	put_cmd_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test_p1	; handle self-test error
	call	crlf
	ld	de,str_ctlr_test_p1_ok
	call	prtstr
	xor	a
	ret
;
; Attempt self-test of second port of controller
;
ctlr_test_p2:
	call	crlf2
	ld	de,str_ctlr_test_p2
	call	prtstr
	ld	a,$a9			; self-test second port
	call	put_cmd_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test_p2	; handle self-test error
	call	crlf
	ld	de,str_ctlr_test_p2_ok
	call	prtstr
	xor	a
	ret
;
; PS/2 controller setup
;
;   Set controller command register to value in A
;
ctlr_setup:
	push	af			; save incoming value
	call	crlf2
	ld	de,str_ctlr_setup
	call	prtstr
	ld	a,$60			; write to command register 0
	call	put_cmd_dbg
	pop	bc			; recover incoming to B
	jp	c,err_ctlr_to		; handle controller error
	ld	a,b
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	xor	a
	ret
;
; Perform a keyboard reset
;
kbd_reset:
	call	crlf2
	ld	de,str_kbd_reset
	call	prtstr
	ld	a,$ff			; Keyboard reset
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_reset
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$aa			; Success?
	jp	nz,err_kbd_reset
	call	crlf
	ld	de,str_kbd_reset_ok
	call	prtstr
	xor	a
	ret
;
; Identify keyboard
;
kbd_ident:
	call	crlf2
	ld	de,str_kbd_ident
	call	prtstr
	ld	a,$f2			; Identify keyboard command
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_ident
	; Now we need to receive 0-2 bytes.  There is no way to know
	; how many are coming, so we receive bytes until there is a
	; timeout error.  Timeout is shortened here so that we don't
	; have to wait seconds for the routine to complete normally.
	; A short timeout is more than sufficient here.
	ld	ix,workbuf
	ld	a,(timeout)		; save current timeout
	push	af
	ld	a,stimout		; set a short timeout
	ld	(timeout),a
	ld	b,8			; buf max
	ld	c,0			; buf len
kbd_ident1:
	push	bc
	call	get_data_dbg
	pop	bc
	jr	c,kbd_ident2
	ld	(ix),a
	inc	ix
	inc	c
	djnz	kbd_ident1
kbd_ident2:
	pop	af			; restore original timeout
	ld	(timeout),a
	call	crlf
	ld	de,str_kbd_ident_disp
	call	prtstr
	ld	a,'['
	call	prtchr
	ld	ix,workbuf
	ld	a,c			; bytes to print
	or	a			; check for zero
	jr	z,kbd_ident4		; handle zero
	ld	b,a			; setup loop counter
	jr	kbd_ident3a
kbd_ident3:
	ld	a,','
	call	prtchr
kbd_ident3a:
	ld	a,(ix)
	call	prthex
	inc	ix
	djnz	kbd_ident3
kbd_ident4:
	ld	a,']'
	call	prtchr
	xor	a
	ret
;
; Display keyboard active scan code set being used
;
kbd_dispsc:
	call	crlf2
	ld	de,str_kbd_getsc
	call	prtstr
	ld	a,$f0			; Keyboard get/set scan code
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_getsc
	ld	a,$00			; Get active scan code set
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_getsc
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	push	af
	call	crlf
	ld	de,str_kbd_dispsc
	call	prtstr
	pop	af
	call	prtdecb
	xor	a
	ret
;
; Set keyboard active scan code set to value in A
;
kbd_setsc:
	ld	(kbd_setsc_val),a	; Save incoming value
	call	crlf2
	ld	de,str_kbd_setsc
	call	prtstr
	call	prtdecb
	ld	a,$f0			; Keyboard get/set scan code
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_setsc
	ld	a,(kbd_setsc_val)	; Recover scan code set value
	call	put_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_setsc
	xor	a
	ret
;
kbd_setsc_val	.db	0
;
; Read and display raw scan codes
;
kbd_echo:
	call	crlf2
	ld	de,str_disp_scan_codes
	call	prtstr
read_loop:
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	$1B			; Escape key?
	ret	z
	call	check_read_kbd
	jr	nz,read_loop
	call	get_data
	jp	c,err_ctlr_to		; handle controller error
	push	af
	ld	a,' '
	call	prtchr
	ld	a,'['
	call	prtchr
	pop	af
	call	prthex
	ld	a,']'
	call	prtchr
	jr	read_loop
;
; Reset Mouse
;
mse_reset:
	call	crlf2
	ld	de,str_mse_reset
	call	prtstr
	ld	a,$f2			; Identify mouse command
	call	put_data_mse_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$fa			; Is it an ack as expected?
	jp	nz,err_mse_reset
	call	crlf
	ld	de,str_mse_reset_ok
	call	prtstr
	xor	a
	ret
;
; Identify Mouse
;
mse_ident:
	call	crlf2
	ld	de,str_mse_ident
	call	prtstr
	ld	a,$f2			; Identify mouse command
	call	put_data_mse_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$fa			; Is it an ack as expected?
	jp	nz,err_mse_ident
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	push	af
	call	crlf
	ld	de,str_mse_ident_disp
	call	prtstr
	pop	af
	call	prtdecb
	xor	a
	ret
;
; Enable mouse packet streaming
;
mse_stream:
	call	crlf2
	ld	de,str_mse_stream
	call	prtstr
	ld	a,$f4			; Stream packets cmd
	call	put_data_mse_dbg
	jp	c,err_ctlr_to		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_to		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_mse_stream
	xor	a
	ret
;
; Read and display raw mouse packets
;
mse_echo:
	call	crlf2
	ld	de,str_disp_mse_pkts
	call	prtstr
	call	mse_track_disp		; show mouse status
	xor	a
	ld	(msebuflen),a
mse_echo1:
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	$1B			; Escape key?
	ret	z
	call	check_read_mse
	jr	nz,mse_echo1
	call	get_data
	jp	c,err_ctlr_to		; handle controller error
	push	af
	ld	a,(msebuflen)		; current bytes in buf
	ld	hl,msebuf		; start of buf
	call	addhla			; point to next buf pos
	pop	af
	ld	(hl),a			; save byte in buf
	ld	a,(msebuflen)
	inc	a
	ld	(msebuflen),a		; inc buf len
	cp	3			; got 3 bytes?
	jr	nz,mse_echo1	; if not, get some more
	call	mse_track
	call	mse_track_disp
	jr	mse_echo1		; and loop
;
; Read and display data from keyboard and mouse
;
kbdmse_echo:
	call	crlf2
	ld	de,str_disp_kbdmse
	call	prtstr
	xor	a
	ld	(msebuflen),a
	call	kbdmse_track_disp
;
kbdmse_echo1:
	; Check for user abort
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	$1B			; Escape key?
	ret	z
;	
	call	kbdmse_echo2
	call	kbdmse_echo3
	jr	kbdmse_echo1
;
kbdmse_echo2:
	; Check & handle keyboard data
	call	check_read_kbd
	ret	nz
	call	get_data
	ld	(kbd_byte),a
	call	kbdmse_track_disp
	ret
;
kbdmse_echo3:
	; Check & handle mouse data
	call	check_read_mse
	ret	nz
	call	get_data
	jp	c,err_ctlr_to		; handle controller error
	push	af
	ld	a,(msebuflen)		; current bytes in buf
	ld	hl,msebuf		; start of buf
	call	addhla			; point to next buf pos
	pop	af
	ld	(hl),a			; save byte in buf
	ld	a,(msebuflen)
	inc	a
	ld	(msebuflen),a		; inc buf len
	cp	3			; full packet?
	ret	nz			; if not, loop
	call	mse_track
	call	kbdmse_track_disp
	ret
;
; Update mouse tracking stuff
; This routine assumes that msebuf has been filled with a complete
; 3 byte mouse packet.
;
mse_track:
	; Buttons...
	ld	a,(msebuf)
	ld	(mse_stat),a
;
	; X Coordinate
	ld	a,(msebuf+1)
	ld	e,a
	ld	d,0
	ld	a,(msebuf)
	and	%00010000		; sign bit
	jr	z,mse_track_x
	ld	d,$ff			; sign extend
mse_track_x:
	ld	hl,(mse_x)
	add	hl,de
	ld	(mse_x),hl		; save result
;
	; Y Coordinate
	ld	a,(msebuf+2)
	ld	e,a
	ld	d,0
	ld	a,(msebuf)
	and	%00100000		; sign bit
	jr	z,mse_track_y
	ld	d,$ff			; sign extend
mse_track_y:
	ld	hl,(mse_y)
	add	hl,de
	ld	(mse_y),hl		; save result
;
	; Reset mouse buffer
	xor	a
	ld	(msebuflen),a
	ret
;
; Display current mouse tracking info (buttons and coordinates)
;
mse_track_disp:
	ld	a,13			; CR only
	call	prtchr
	ld	de,str_msestat1		; "L="
	call	prtstr
	ld	a,(mse_stat)
	and	%00000001
	call	updown
	ld	de,str_msestat2		; ", M="
	call	prtstr
	ld	a,(mse_stat)
	and	%00000100
	call	updown
	ld	de,str_msestat3		; ", R="
	call	prtstr
	ld	a,(mse_stat)
	and	%00000010
	call	updown
;
	ld	de,str_msestat4		; ", X="
	call	prtstr
	ld	hl,(mse_x)		; save result
	call	prthexword
;
	ld	de,str_msestat5		; ", Y="
	call	prtstr
	ld	hl,(mse_y)		; save result
	call	prthexword
;
	ret
;
updown:
	jr	nz,updown1
	ld	de,str_up
	jr	updown2
updown1:
	ld	de,str_down
updown2:
	call	prtstr
	ret
;
; Display all keyboard and mouse tracking
;
kbdmse_track_disp:
	call	mse_track_disp
	ld	a,' '
	call	prtchr
	ld	a,'['
	call	prtchr
	ld	a,(kbd_byte)
	call	prthex
	ld	a,']'
	call	prtchr
	ret
;
;=======================================================================
; PS/2 Controller I/O Routines
;=======================================================================
;
wait_write:
;
; Wait for controller to be ready for a write
;   A=0 indicates success (ZF set)
;
	ld	a,(timeout)		; setup timeout constant
	ld	b,a
wait_write1:
	ld	a,(iocmd)		; cmd port
	ld	c,a			; ... to C
	in	a,(c)			; get status
	ld	c,a			; save status
	and	$02			; isolate input buf status bit
	ret	z			; 0 means ready, all done
	call	delay			; wait a bit
	djnz	wait_write1		; loop until counter exhausted
;	ld	de,str_timeout_write	; write timeout message
;	call	crlf
;	call	prtstr
;	ld	a,c			; recover last status value
;	call	prthex
	or	$ff			; signal error
	ret
;
wait_read:
;
; Wait for controller to be ready to read a byte
;   A=0 indicates success (ZF set)
;
	ld	a,(timeout)		; setup timeout constant
	ld	b,a
wait_read1:
	ld	a,(iocmd)		; cmd port
	ld	c,a			; ... to C
	in	a,(c)			; get status
	ld	c,a			; save status
	and	$01			; isolate input buf status bit
	xor	$01			; invert so 0 means ready
	ret	z			; if 0, all done
	call	delay			; wait a bit
	djnz	wait_read1		; loop until counter exhausted
;	ld	de,str_timeout_read	; write timeout message
;	call	crlf
;	call	prtstr
;	ld	a,c			; recover last status value
;	call	prthex
	or	$ff			; signal error
	ret
;
check_read:
;
; Check for data ready to read
;   A=0 indicates data available (ZF set)
;
	ld	a,(iocmd)		; cmd port
	ld	c,a			; ... to C
	in	a,(c)			; get status
	and	$01			; isolate input buf status bit
	xor	$01			; invert so 0 means ready
	ret
;
check_read_kbd:
;
; Check for keyboard data ready to read
;   A=0 indicates data available (ZF set)
;
	ld	a,(iocmd)		; cmd port
	ld	c,a			; ... to C
	in	a,(c)			; get status
	and	%00100001		; isolate input buf status bit
	cp	%00000001		; data ready, not mouse
	ret
;
check_read_mse:
;
; Check for mouse data ready to read
;   A=0 indicates data available (ZF set)
;
	ld	a,(iocmd)		; cmd port
	ld	c,a			; ... to C
	in	a,(c)			; get status
	and	%00100001		; isolate input buf status bit
	cp	%00100001		; data ready, is mouse
	ret
;
put_cmd:
;
; Put a cmd byte from A to the controller with timeout
; CF set indicates timeout error
;
	ld	e,a			; save incoming value
	call	wait_write		; wait for controller ready
	jr	z,put_cmd1		; if ready, move on
	scf				; else, signal timeout error
	ret				; and bail out
put_cmd1:
	ld	a,(iocmd)		; cmd port
	ld	c,a			; ... to C
	ld	a,e			; recover value to write
	out	(c),a			; write it
	or	a			; clear CF for success
	ret
;
put_cmd_dbg:
	call	put_cmd
	ret	c
	push	af

	call	crlf
	ld	de,str_put_cmd
	call	prtstr
	call	prthex

	pop	af
	ret
;	
put_data:
;
; Put a data byte from A to the controller interface with timeout
; CF set indicates timeout error
;
	ld	e,a			; save incoming value
	call	wait_write		; wait for controller ready
	jr	z,put_data1		; if ready, move on
	scf				; else, signal timeout error
	ret				; and bail out
put_data1:
	ld	a,(iodat)		; data port
	ld	c,a			; ... to C
	ld	a,e			; recover value to write
	out	(c),a			; write it
	or	a			; clear CF for success
	ret
;
put_data_dbg:
	call	put_data
	ret	c
	push	af

	call	crlf
	ld	de,str_put_data
	call	prtstr
	call	prthex

	pop	af
	ret

;	
put_data_mse:
;
; Put a data byte from A to the mouse interface with timeout
; CF set indicates timeout error
;
	ld	e,a			; save incoming value
	push	de
	
	ld	a,$d4			; mouse channel prefix
	call	put_cmd
	pop	de
	ret	c
	
	ld	a,e			; recover value
	call	put_data
	ret
;
put_data_mse_dbg:
	ld	e,a			; save incoming value
	push	de
	
	ld	a,$d4			; mouse channel prefix
	call	put_cmd_dbg
	pop	de
	ret	c
	
	ld	a,e			; recover value
	call	put_data_dbg
	ret
;
; Get a data byte from the controller interface to A with timeout
; CF set indicates timeout error
;
get_data:
	call	wait_read		; wait for byte to be ready
	jr	z,get_data1		; if readym, move on
	scf				; else signal timeout error
	ret				; and bail out
get_data1:
	ld	a,(iodat)		; data port
	ld	c,a			; ... to C
	in	a,(c)			; get data byte
	or	a			; clear CF for success
	ret
;
get_data_dbg:
	call	get_data
	ret	c
	push	af

	call	crlf
	ld	de,str_get_data
	call	prtstr
	call	prthex

	pop	af
	ret
;
; Error Handlers
;
err_ctlr_to:
	ld	de,str_err_ctlr_to
	jr	err_ret
;
err_ctlr_test:
	ld	de,str_err_ctlr_test
	jr	err_ret
;
err_ctlr_test_p1:
	ld	de,str_err_ctlr_test_p1
	jr	err_ret
;
err_ctlr_test_p2:
	ld	de,str_err_ctlr_test_p2
	jr	err_ret
;
err_kbd_reset:
	ld	de,str_err_kbd_reset
	jr	err_ret
;
err_kbd_getsc:
	ld	de,str_err_kbd_getsc
	jr	err_ret
;
err_kbd_setsc:
	ld	de,str_err_kbd_setsc
	jr	err_ret
;
err_kbd_ident:
	ld	de,str_err_kbd_ident
	jr	err_ret
;
err_mse_reset:
	ld	de,str_err_mse_reset
	jr	err_ret
;
err_mse_ident:
	ld	de,str_err_mse_ident
	jr	err_ret
;
err_mse_stream:
	ld	de,str_err_mse_stream
	jr	err_ret
;
err_ret:
	call	crlf2
	call	prtstr
	or	$ff			; signal error
	ret
;
;=======================================================================
; Utility Routines
;=======================================================================
;
; Print character in A without destroying any registers
;
prtchr:
	push	af		; save registers
	push	bc
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	pop	af
	ret
;
prtdot:
;
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,'.'		; load dot char
	call	prtchr		; print it
	pop	af		; restore af
	ret			; done
;
; Uppercase character in A
;
upcase:
	cp	'a'			; below 'a'?
	ret	c			; if so, nothing to do
	cp	'z'+1			; above 'z'?
	ret	nc			; if so, nothing to do
	and	~$20			; convert character to lower
	ret				; done
;
; Print a zero terminated string at (de) without destroying any registers
;
prtstr:
	push	af
	push	de
;
prtstr1:
	ld	a,(de)		; get next char
	or	a
	jr	z,prtstr2
	call	prtchr
	inc	de
	jr	prtstr1
;
prtstr2:
	pop	de		; restore registers
	pop	af
	ret
;
; Print a hex value prefix "0x"
;
prthexpre:
	push	af
	ld	a,'0'
	call	prtchr
	ld	a,'x'
	call	prtchr
	pop	af
	ret
;
; Print the value in A in hex without destroying any registers
;
prthex:
	call	prthexpre
prthex1:
	push	af		; save AF
	push	de		; save DE
	call	hexascii	; convert value in A to hex chars in DE
	ld	a,d		; get the high order hex char
	call	prtchr		; print it
	ld	a,e		; get the low order hex char
	call	prtchr		; print it
	pop	de		; restore DE
	pop	af		; restore AF
	ret			; done
;
; print the hex word value in hl
;
prthexword:
	call	prthexpre
prthexword1:
	push	af
	ld	a,h
	call	prthex1
	ld	a,l
	call	prthex1 
	pop	af
	ret
;
; print the hex dword value in de:hl
;
prthex32:
	call	prthexpre
	push	bc
	push	de
	pop	bc
	call	prthexword1
	push	hl
	pop	bc
	call	prthexword1
	pop	bc
	ret
;
; Convert binary value in A to ascii hex characters in DE
;
hexascii:
	ld	d,a		; save A in D
	call	hexconv		; convert low nibble of A to hex
	ld	e,a		; save it in E
	ld	a,d		; get original value back
	rlca			; rotate high order nibble to low bits
	rlca
	rlca
	rlca
	call	hexconv		; convert nibble
	ld	d,a		; save it in D
	ret			; done
;
; Convert low nibble of A to ascii hex
;
hexconv:
	and	$0F	     	; low nibble only
	add	a,$90
	daa	
	adc	a,$40
	daa	
	ret
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
prtdecb:
	push	hl
	ld	h,0
	ld	l,a
	call	prtdecw		; print it
	pop	hl
	ret
;
prtdecw:
	push	af
	push	bc
	push	de
	push	hl
	call	prtdec0
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
prtdec0:
	ld	e,'0'
	ld	bc,-10000
	call	prtdec1
	ld	bc,-1000
	call	prtdec1
	ld	bc,-100
	call	prtdec1
	ld	c,-10
	call	prtdec1
	ld	e,0
	ld	c,-1
prtdec1:
	ld	a,'0' - 1
prtdec2:
	inc	a
	add	hl,bc
	jr	c,prtdec2
	sbc	hl,bc
	cp	e
	ret	z
	ld	e,0
	call	prtchr
	ret
;
; Start a new line
;
crlf2:
	call	crlf		; two of them
crlf:
	push	af		; preserve AF
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	call	prtchr		; print it
	pop	af		; restore AF
	ret
;
; Add hl,a
;
;   A register is destroyed!
;
addhla:
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret
;
; Delay ~10ms
;
delay:
	push	af
	push	de
	ld	de,625			; 10000us/16us
delay0:
	ld	a,(cpuscl)
delay1:
	dec	a
	jr	nz,delay1
	dec	de
	ld	a,d
	or	e
	jp	nz,delay0
	pop	de
	pop	af
	ret
;
;
;
;=======================================================================
; Constants
;=======================================================================
;
str_banner		.db	"PS/2 Keyboard/Mouse Information v0.6a, 2-Apr-2022",0
str_hwmenu		.db	"PS/2 Controller Port Options:\r\n\r\n"
			.db	"  1 - MBC\r\n"
			.db	"  2 - RHYOPHYRE\r\n"
			.db	"  X - Exit Application\r\n"
			.db	"\r\nSelection? ",0
str_mbc			.db	"MBC",0
str_rph			.db	"RHYOPHYRE",0
str_menu		.db	"PS/2 Testing Options:\r\n\r\n"
			.db	"  C - Test PS/2 Controller\r\n"
			.db	"  K - Test PS/2 Keyboard\r\n"
			.db	"  M - Test PS/2 Mouse\r\n"
			.db	"  B - Test Both PS/2 Keyboard and Mouse Together\r\n"
			.db	"  X - Exit Application\r\n"
			.db	"\r\nSelection? ",0
str_exit		.db	"Done, Thank you for using PS/2 Keyboard/Mouse Information!",0
str_cmdport		.db	"Controller Command Port: ",0
str_dataport		.db	"Controller Data Port: ",0
str_err_ctlr_to		.db	"Controller I/O Timeout",0
str_err_ctlr_test	.db	"Controller Self-Test Failed",0
str_put_cmd		.db	"  Sent Command ",0
str_put_data		.db	"  Sent Data ",0
str_get_data		.db	"  Got Data ",0
str_ctlr_test		.db	"Attempting Controller Self-Test",0
str_ctlr_test_ok	.db	"Controller Self-Test OK",0
str_ctlr_test_p1	.db	"Attempting Self-Test of First Controller Port",0
str_ctlr_test_p1_ok	.db	"Controller First Port Self-Test OK",0
str_err_ctlr_test_p1	.db	"Controller First Port Self-Test Failed",0
str_ctlr_test_p2	.db	"Attempting Self-Test of Second Controller Port",0
str_ctlr_test_p2_ok	.db	"Controller Second Port Self-Test OK",0
str_err_ctlr_test_p2	.db	"Controller Second Port Self-Test Failed",0
str_ctlr_setup		.db	"Performing Controller Setup",0
str_ctlr		.db	"***** Basic 8242 PS/2 Controller Tests *****",0
str_basic		.db	"***** Basic Keyboard Checks and Scan Code Inventory *****",0
str_trans_off		.db	"***** Testing Keyboard with Scan Code Translation DISABLED *****",0
str_trans_on		.db	"***** Testing Keyboard with Scan Code Translation ENABLED *****",0
str_basic_mse		.db	"***** Basic Mouse Tests *****",0
str_kbdmse			.db	"***** Test All Devices Combined *****",0
str_kbd_reset		.db	"Attempting Keyboard Reset",0
str_kbd_reset_ok	.db	"Keyboard Reset OK",0
str_err_kbd_reset	.db	"Keyboard Reset Failed",0
str_mse_reset		.db	"Attempting Mouse Reset",0
str_mse_reset_ok	.db	"Mouse Reset OK",0
str_err_mse_reset	.db	"Mouse Reset Failed",0
str_kbd_getsc		.db	"Requesting Active Scan Code Set from Keyboard",0
str_kbd_dispsc		.db	"Active Keyboard Scan Code Set is #",0
str_err_kbd_getsc	.db	"Error getting Active Keyboard Scan Code Set",0
str_kbd_setsc		.db	"Setting Active Keyboard Scan Code Set to #",0
str_err_kbd_setsc	.db	"Error setting Active Keyboard Scan Code Set",0
str_kbd_ident		.db	"Keyboard Identification",0
str_kbd_ident_disp	.db	"Keyboard Identity: ",0
str_mse_ident		.db	"Mouse Identification",0
str_mse_ident_disp	.db	"Mouse Identity: ",0
str_mse_stream		.db	"Enable Mouse Packet Streaming",0
str_err_mse_stream	.db	"Error enabling Mouse Packet Streaming",0
str_msestat1		.db	"L=",0
str_msestat2		.db	", M=",0
str_msestat3		.db	", R=",0
str_msestat4		.db	", X=",0
str_msestat5		.db	", Y=",0
str_up			.db	"UP",0
str_down		.db	"DN",0
str_sc_tag		.db	"Scan Code Set #",0
str_sc_ok		.db	" IS supported",0
str_sc_fail		.db	" IS NOT supported",0
str_err_kbd_ident	.db	"Error performing Keyboard Identification",0
str_err_mse_ident	.db	"Error performing Mouse Identification",0
str_disp_scan_codes	.db	"Displaying Raw Scan Codes",13,10
			.db	"  Press keys on test keyboard to display scan codes",13,10
			.db	"  Press <esc> on CP/M console to end",13,10,13,10,0
str_disp_mse_pkts	.db	"Displaying Mouse Packets",13,10
			.db	"  Move mouse and click mouse buttons",13,10
			.db	"  Press <esc> on CP/M console to end",13,10,13,10,0
str_disp_kbdmse		.db	"Displaying Keyboard & Mouse Activity",13,10
			.db	"  Press keys on test keyboard to display scan codes",13,10
			.db	"  Move mouse and click mouse buttons",13,10
			.db	"  Press <esc> on CP/M console to end",13,10,13,10,0
str_kbd_failed		.db	"***** KEYBOARD HARDWARE ERROR *****",13,10,13,10
			.db	"A basic hardware or configuration issue prevented",13,10
			.db	"the completion of the full set of keyboard tests.",13,10
			.db	"Check your hardware and verify the port",13,10
			.db	"addresses being used for the controller",0
str_mse_failed		.db	"***** MOUSE HARDWARE ERROR *****",13,10,13,10
			.db	"A basic hardware or configuration issue prevented",13,10
			.db	"the completion of the full set of mouse tests.",13,10
			.db	"Check your hardware and verify the port",13,10
			.db	"addresses being used for the controller",0
str_kbdmse_failed	.db	"***** KEYBOARD/MOUSE HARDWARE ERROR *****",13,10,13,10
			.db	"A basic hardware or configuration issue prevented",13,10
			.db	"the completion of the full set of keyboard/mouse tests.",13,10
			.db	"Check your hardware and verify the port",13,10
			.db	"addresses being used for the controller",0
;
;=======================================================================
; Working data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
iocmd		.db	0
iodat		.db	0
;
workbuf		.fill	8
workbuf_len	.db	0
;
msebuf		.fill	5,0
msebuflen	.db	0
;
mse_stat	.db	0
mse_x		.dw	0
mse_y		.dw	0
;
kbd_byte	.db	0
;
ctlr_cfgval	.db	0		; Value for controller cmd reg 0
;
cpuscl		.db	cpumhz - 2
timeout		.db	ltimout
;
;=======================================================================
;
	.end