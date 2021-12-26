;
;=======================================================================
; Keyboard Information Utility (KBDINFO)
;=======================================================================
;
; Simple utility that attempts to determine the type of keyboard you
; have attached to an 8242 keyboard controller.
;
;=======================================================================
;
; Keyboard controller port addresses (adjust as needed)
;
iocmd	.equ	$E3	; keyboard controller command port address
iodat	.equ	$E2	; keyboard controller data port address
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
	call	main			; do the real work
	jr	z,exit			; completed all tests
	ld	de,str_run_failed
	call	crlf2
	call	prtstr
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
;
;=======================================================================
; Main Program
;=======================================================================
;
main:
;
; Display active keyboard controller port addresses
;
	call	crlf2
	ld	de,str_cmdport
	call	prtstr
	ld	a,iocmd
	call	prthex
	call	crlf
	ld	de,str_dataport
	call	prtstr
	ld	a,iodat
	call	prthex
;
; First, we attempt to contact the controller and keyboard, then
; print the keyboard identity and scan codes scupported
;
	; Run test series with translation off
	call	crlf2
	ld	de,str_basic
	call	prtstr
;
	call	do_basic
	ret	nz
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
	ld	a,$20			; xlat disabled, mouse disabled, no ints
	ld	(ctlr_cfgval),a
	call	do_tests
;
	; Run test series with translation on
	call	crlf2
	ld	de,str_trans_on
	call	prtstr
;
	ld	a,$60			; xlat enabled, mouse disabled, no ints
	ld	(ctlr_cfgval),a
	call	do_tests
	
	xor	a			; signal success
	ret
;
; Perform basic keyboard tests, display keyboard identity, and
; inventory the supported scan code sets.
;
do_basic:
	call	ctlr_test
	ret	nz
;
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
do_basic1:
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
	jr	z,do_basic2
	ld	de,str_sc_fail
do_basic2:
	call	prtstr
	inc	c
	djnz	do_basic1
;
	xor	a			; signal success
	ret
;
; This routine runs a series of controller and keyboard tests.  The
; desired controller setup value should be placed in ctlr_cfgval
; prior to invoking this routine.
;
do_tests:
	call	ctlr_test
	ret	nz
;
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
	call	kbd_showkeys
	;ret	nz
;
	xor	a			; signal success
	ret
;
;=======================================================================
; Keyboard/Controller Test Routines
;=======================================================================
;
; Attempt self-test command on keyboard controller
;
;   Keyboard controller should respond with an 0x55 on data port
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
; Keyboard controller setup
;
;   Set keyboard controller command register to value in A
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
	cp	$AA			; Success?
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
; Display active scan code set being used
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
; Set active scan code set to value in A
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
;
; Read and display raw scan codes
;
kbd_showkeys:
	call	crlf2
	ld	de,str_disp_scan_codes
	call	prtstr
read_loop:
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	$1B			; Escape key?
	ret	z
	call	check_read
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
;=======================================================================
; Keyboard Controller I/O Routines
;=======================================================================
;
wait_write:
;
; Wait for keyboard controller to be ready for a write
;   A=0 indicates success (ZF set)
;
	ld	a,(timeout)		; setup timeout constant
	ld	b,a
wait_write1:
	in	a,(iocmd)		; get status
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
; Wait for keyboard controller to be ready to read a byte
;   A=0 indicates success (ZF set)
;
	ld	a,(timeout)		; setup timeout constant
	ld	b,a
wait_read1:
	in	a,(iocmd)		; get status
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
	in	a,(iocmd)		; get status
	and	$01			; isolate input buf status bit
	xor	$01			; invert so 0 means ready
	ret
;
put_cmd:
;
; Put a cmd byte from A to the keyboard interface with timeout
; CF set indicates timeout error
;
	ld	e,a			; save incoming value
	call	wait_write		; wait for controller ready
	jr	z,put_cmd1		; if ready, move on
	scf				; else, signal timeout error
	ret				; and bail out
put_cmd1:
	ld	a,e			; recover value to write
	out	(iocmd),a		; write it
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

;	ld	de,str_prefix		; "  "
;	call	prtstr
;	call	prthex
;	ld	de,str_cmdout		; "->(CMD)"
;	call	prtstr

	pop	af
	ret
;	
put_data:
;
; Put a data byte from A to the keyboard interface with timeout
; CF set indicates timeout error
;
	ld	e,a			; save incoming value
	call	wait_write		; wait for controller ready
	jr	z,put_data1		; if ready, move on
	scf				; else, signal timeout error
	ret				; and bail out
put_data1:
	ld	a,e			; recover value to write
	out	(iodat),a		; write it
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

;	ld	de,str_prefix		; "  "
;	call	prtstr
;	call	prthex
;	ld	de,str_dataout		; "->(DATA)"
;	call	prtstr

	pop	af
	ret

;
; Get a data byte from the keyboard interface to A with timeout
; CF set indicates timeout error
;
get_data:
	call	wait_read		; wait for byte to be ready
	jr	z,get_data1		; if readym, move on
	scf				; else signal timeout error
	ret				; and bail out
get_data1:
	in	a,(iodat)		; get data byte
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

;	ld	de,str_datain		; "  (DATA)->"
;	call	prtstr
;	call	prthex

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
;
; Print character in A without destroying any registers
;
prtchr:
	push	bc		; save registers
	push	de
	push	hl
	ld	e,a		; character to print in E
	ld	c,$02		; BDOS function to output a character
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
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
str_banner		.db	"Keyboard Information v0.2, 23-Dec-2021",0
str_exit		.db	"Done, Thank you for using Keyboard Information!",0
str_cmdport		.db	"Keyboard Controller Command Port: ",0
str_dataport		.db	"Keyboard Controller Data Port: ",0
;str_prefix		.db	"  ",0
;str_cmdout		.db	"->(CMD)",0
;str_dataout		.db	"->(DATA)",0
;str_datain		.db	"  (DATA)->",0
;str_timeout_write	.db	"Keyboard Controller Write Timeout, Status: ",0
;str_timeout_read	.db	"Keyboard Controller Read Timeout, Status: ",0
str_err_ctlr_to		.db	"Keyboard Controller I/O Timeout",0
str_err_ctlr_test	.db	"Keyboard Controller Self-Test Failed",0
str_put_cmd		.db	"  Sent Command ",0
str_put_data		.db	"  Sent Data ",0
str_get_data		.db	"  Got Data ",0
str_ctlr_test		.db	"Attempting Controller Self-Test",0
str_ctlr_test_ok	.db	"Controller Self-Test OK",0
str_ctlr_setup		.db	"Performing Controller Setup",0
str_basic		.db	"***** Basic Keyboard Checks and Scan Code Inventory *****",0
str_trans_off		.db	"***** Testing with Scan Code Translation DISABLED *****",0
str_trans_on		.db	"***** Testing with Scan Code Translation ENABLED *****",0
str_kbd_reset		.db	"Attempting Keyboard Reset",0
str_kbd_reset_ok	.db	"Keyboard Reset OK",0
str_err_kbd_reset	.db	"Keyboard Reset Failed",0
str_kbd_getsc		.db	"Requesting Active Scan Code Set from Keyboard",0
str_kbd_dispsc		.db	"Active Keyboard Scan Code Set is #",0
str_err_kbd_getsc	.db	"Error getting Active Keyboard Scan Code Set",0
str_kbd_setsc		.db	"Setting Active Keyboard Scan Code Set to #",0
str_err_kbd_setsc	.db	"Error setting Active Keyboard Scan Code Set",0
str_kbd_ident		.db	"Keyboard Identification",0
str_kbd_ident_disp	.db	"Keyboard Identity: ",0
str_sc_tag		.db	"Scan Code Set #",0
str_sc_ok		.db	" IS supported",0
str_sc_fail		.db	" IS NOT supported",0
str_err_kbd_ident	.db	"Error performing Keyboard Identification",0
str_disp_scan_codes	.db	"Displaying Raw Scan Codes",13,10
			.db	"  Press keys on test keyboard to display scan codes",13,10
			.db	"  Press <esc> on CP/M console to end",13,10,13,10,0
str_run_failed		.db	"***** HARDWARE ERROR *****",13,10,13,10
			.db	"A basic hardware or configuration issue prevented",13,10
			.db	"Keyboard Information from completing the full set",13,10
			.db	"of tests.  Check your hardware and verify the port",13,10
			.db	"addresses being used for the keyboard controller",0
;
;=======================================================================
; Working data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
workbuf		.fill	8
workbuf_len	.db	0
;
ctlr_cfgval	.db	0		; Value for controller cmd reg 0
;
cpuscl		.db	cpumhz - 2
timeout		.db	ltimout
;
;=======================================================================
;
	.end