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
; General operational equates (should not requre adjustment)
;
stksiz	.equ	$40			; Working stack size
;
timeout	.equ	$00			; Controller timeout constant
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
;
exit:
	call	crlf2
	ld	de,str_exit
	call	prtstr
	;call	crlf

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
; Attempt self-test command on keyboard controller
;
;   Keyboard controller should respond with an 0x55 on data port
;   after being sent a 0xAA on the command port.
;
	call	crlf2
	ld	de,str_ctrl_test
	call	prtstr
	ld	a,$aa			; self-test command
	call	put_cmd_dbg
	jp	c,err_ctlr_io		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	cp	$55			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr
;
; Disable translation on keyboard controller to get raw scan codes!
;
	call	crlf2
	ld	de,str_trans_off
	call	prtstr
	ld	a,$60			; write to command register 0
	call	put_cmd_dbg
	jp	c,err_ctlr_io		; handle controller error
	ld	a,$20			; xlat disabled, mouse disabled, no ints
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
;
;
;
	call	test2
;
; Enable translation on keyboard controller
;
	call	crlf2
	ld	de,str_trans_on
	call	prtstr
	ld	a,$60			; write to command register 0
	call	put_cmd_dbg
	jp	c,err_ctlr_io		; handle controller error
	ld	a,$60			; xlat disabled, mouse disabled, no ints
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
;
	; fall thru
;
test2:
;
; Perform a keyboard reset
;
	call	crlf2
	ld	de,str_kbd_reset
	call	prtstr
	ld	a,$ff			; Keyboard reset
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_reset
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	cp	$AA			; Success?
	jp	nz,err_kbd_reset
	call	crlf
	ld	de,str_kbd_reset_ok
	call	prtstr
;
; Identify keyboard
;
	call	crlf2
	ld	de,str_kbd_ident
	call	prtstr
	ld	a,$f2			; Identify keyboard command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_ident
	; Now we need to receive 0-2 bytes.  There is no way to know
	; how many are coming, so we receive bytes until there is a
	; timeout error.
	ld	ix,workbuf
	ld	iy,workbuf_len
	xor	a
	ld	(iy),a
ident_loop:	
	call	get_data_dbg
	jr	c,ident_done
	ld	(ix),a
	inc	ix
	inc	(iy)
	jr	ident_loop
ident_done:
	call	crlf
	ld	de,str_kbd_ident_disp
	call	prtstr
	ld	a,'['
	call	prtchr
	ld	ix,workbuf
	ld	b,(iy)
	xor	a
	cp	b
	jr	z,ident_done2
ident_done1:
	ld	a,(ix)
	call	prthex
	inc	ix
	djnz	ident_done1
ident_done2:
	ld	a,']'
	call	prtchr
;
; Get active scan code set being used
;
	call	crlf2
	ld	de,str_kbd_getsc
	call	prtstr
	ld	a,$f0			; Keyboard get/set scan code
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_getsc
	ld	a,$00			; Get active scan code set
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	cp	$FA			; Is it an ack as expected?
	jp	nz,err_kbd_getsc
	call	get_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	push	af
	call	crlf
	ld	de,str_kbd_dispsc
	call	prtstr
	pop	af
	call	prtdecb
;;;;
;;;; Set active scan code set to 2
;;;;
;;;	call	crlf2
;;;	ld	de,str_kbd_setsc
;;;	call	prtstr
;;;	ld	a,$f0			; Keyboard get/set scan code
;;;	call	put_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	call	get_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	cp	$FA			; Is it an ack as expected?
;;;	jp	nz,err_kbd_getsc
;;;	ld	a,$02			; Set scan code set to 2
;;;	call	put_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	call	get_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	cp	$FA			; Is it an ack as expected?
;;;	jp	nz,err_kbd_getsc
;;;;
;;;; Get active scan code set being used
;;;;
;;;	call	crlf2
;;;	ld	de,str_kbd_getsc
;;;	call	prtstr
;;;	ld	a,$f0			; Keyboard get/set scan code
;;;	call	put_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	call	get_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	cp	$FA			; Is it an ack as expected?
;;;	jp	nz,err_kbd_getsc
;;;	ld	a,$00			; Get active scan code set
;;;	call	put_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	call	get_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	cp	$FA			; Is it an ack as expected?
;;;	jp	nz,err_kbd_getsc
;;;	call	get_data_dbg
;;;	jp	c,err_ctlr_io		; handle controller error
;;;	push	af
;;;	call	crlf
;;;	ld	de,str_kbd_dispsc
;;;	call	prtstr
;;;	pop	af
;;;	and	$0f
;;;	call	prtdecb
;
; Read and display raw scan codes
;
	call	crlf2
	ld	de,str_disp_scan_codes
	call	prtstr
read_loop:
	ld	c,$06			; BDOS direct console I/O
	ld	e,$FF			; Subfunction = read
	call	bdos
	cp	$1B			; Escape key?
	jp	z,done
	call	check_read
	jr	nz,read_loop
	call	get_data
	jp	c,err_ctlr_io		; handle controller error
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

done:
	ret
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
	ld	b,timeout		; setup timeout constant
wait_write1:
	in	a,(iocmd)		; get status
	ld	c,a			; save status
	and	$02			; isolate input buf status bit
	ret	z			; 0 means ready, all done
	call	delay			; wait a bit
	djnz	wait_write1		; loop until counter exhausted
	ld	de,str_timeout_write	; write timeout message
	call	crlf
	call	prtstr
	ld	a,c			; recover last status value
	call	prthex
	or	$ff			; signal error
	ret
;
wait_read:
;
; Wait for keyboard controller to be ready to read a byte
;   A=0 indicates success (ZF set)
;
	ld	b,timeout		; setup timeout constant
wait_read1:
	in	a,(iocmd)		; get status
	ld	c,a			; save status
	and	$01			; isolate input buf status bit
	xor	$01			; invert so 0 means ready
	ret	z			; if 0, all done
	call	delay			; wait a bit
	djnz	wait_read1		; loop until counter exhausted
	ld	de,str_timeout_read	; write timeout message
	call	crlf
	call	prtstr
	ld	a,c			; recover last status value
	call	prthex
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
	pop	af
	ret
;
; Error Handlers
;
err_ctlr_io:
	ld	de,str_err_ctrl_io
	jr	err_ret
;
err_ctlr_test:
	ld	de,str_err_ctrl_test
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
; Print the value in A in hex without destroying any registers
;
prthex:
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
	push	af
	ld	a,h
	call	prthex
	ld	a,l
	call	prthex 
	pop	af
	ret
;
; print the hex dword value in de:hl
;
prthex32:
	push	bc
	push	de
	pop	bc
	call	prthexword
	push	hl
	pop	bc
	call	prthexword
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
; Brief delay
;
delay:
	push	bc
	ld	b,0
delay1:
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	ex	(sp),hl
	djnz	delay1
	pop	bc
	ret
;
;=======================================================================
; Constants
;=======================================================================
;
str_banner		.db	"Keyboard Information, v0.1",0
str_exit		.db	"Done, Thank you for using KBDINFO!",0
str_cmdport		.db	"Keyboard Controller Command Port: 0x",0
str_dataport		.db	"Keyboard Controller Data Port: 0x",0
str_timeout_write	.db	"Keyboard Controller Write Timeout, Status: 0x",0
str_timeout_read	.db	"Keyboard Controller Read Timeout, Status: 0x",0
str_err_ctrl_io		.db	"Keyboard Controller I/O Failure",0
str_err_ctrl_test	.db	"Keyboard Controller Self-Test Failed",0
str_put_cmd		.db	"Sent Command 0x",0
str_put_data		.db	"Sent Data 0x",0
str_get_data		.db	"Got Data 0x",0
str_ctrl_test		.db	"Attempting Controller Self-Test",0
str_ctrl_test_ok	.db	"Controller Self-Test OK",0
str_trans_off		.db	"Disabling Controller Translation",0
str_trans_on		.db	"Enabling Controller Translation",0
str_kbd_reset		.db	"Attempting Keyboard Reset",0
str_kbd_reset_ok	.db	"Keyboard Reset OK",0
str_err_kbd_reset	.db	"Keyboard Reset Failed",0

str_kbd_getsc		.db	"Requesting Active Scan Code Set from Keyboard",0
str_kbd_dispsc		.db	"Active Keyboard Scan Code Set is ",0
str_err_kbd_getsc	.db	"Error getting active keyboard scan code set",0
str_kbd_setsc		.db	"Setting Active Keyboard Scan Code Set",0
str_err_kbd_setsc	.db	"Error setting keyboard scan code set",0
str_kbd_ident		.db	"Keyboard Identification",0
str_kbd_ident_disp	.db	"Keyboard Identify: ",0
str_err_kbd_ident	.db	"Error performing Keyboard Identification",0
str_disp_scan_codes	.db	"Displaying Raw Scan Codes",13,10
			.db	"  Press keys on keyboard to display scan codes",13,10
			.db	"  Press <esc> on CP/M console to end",13,10,13,10,0
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
;=======================================================================
;
	.end