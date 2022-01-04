;
;=======================================================================
; Mouse Information Utility (MSEINFO)
;=======================================================================
;
; Simple utility that attempts to determine the status of the mouse you
; have attached to an 8242 keyboard controller.
;
; Based on Wayne Warthen's KBDINFO program, Thanks to his great work
; on RomWBW and support to the Retrobrewcomputers community at large
;
; Additional help from these websites
;   https://isdaman.com/alsos/hardware/mouse/ps2interface.htm
;
; Second PS/2 write data port info from 
;   https://wiki.osdev.org/%228042%22_PS/2_Controller#Second_PS.2F2_Port
;
; PS/2 Mouse initialization code in C
;   http://bos.asmhackers.net/docs/mouse/snippet_2/mouse.inc
;
;=======================================================================
;
; Mouse controller port addresses (adjust as needed)
;
iocmd	.equ	$E3	; keyboard controller command port address
iodat	.equ	$E2	; keyboard controller data port address
;
; General operational equates (should not requre adjustment)
;
stksiz	.equ	$40	; Working stack size
;
timeout	.equ	$00	; Controller timeout constant
;
restart	.equ	$0000	; CP/M restart vector
bdos	  .equ	$0005	; BDOS invocation vector
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
; Display active mouse controller port addresses
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
; Attempt self-test command on mouse controller
;
;   Mouse controller should respond with an 0x55 on data port
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
;   Send 0xA8 Mouse Enable command to 8242 controller
;
	call	crlf2
	ld	de,str_enable_mouse
	call	prtstr
	
	ld	a,$a8			; Send Mouse Enable command to 8242
	call	put_cmd_dbg
	jp	c,err_ctlr_io		; handle controller error

	call	get_data_dbg		; Read Mouse for self-test status
	jp	c,err_ctlr_io		; handle controller error
	cp	$AA			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	

	
;
; Disable translation on keyboard controller to get raw scan codes!  Enable Mouse
;
;	call	crlf2
;	ld	de,str_trans_off
;	call	prtstr
;	ld	a,$60			; write to command register 0
;	call	put_cmd_dbg
;	jp	c,err_ctlr_io		; handle controller error
;	ld	a,$00			; xlat disabled, mouse enabled, no ints
;	call	put_cmd_dbg
;	jp	c,err_ctlr_io		; handle controller error

; Attempt four reset commands on mouse controller
;
	call	crlf2
	ld	de,str_mse_init
	call	prtstr
	
; Reset Pass #1	
	ld	a,$ff			; Send Mouse Reset command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr
	
	call	get_data_dbg		; Read Mouse for self-test status
	jp	c,err_ctlr_io		; handle controller error
	cp	$AA			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
; Reset Pass #2
	ld	a,$ff			; Send Mouse Reset command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr
	
	call	get_data_dbg		; Read Mouse for self-test status
	jp	c,err_ctlr_io		; handle controller error
	cp	$AA			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
; Reset Pass #3
	ld	a,$ff			; Send Mouse Reset command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	call	get_data_dbg		; Read Mouse for self-test status
	jp	c,err_ctlr_io		; handle controller error
	cp	$AA			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
; Reset Pass #4
	ld	a,$ff			; Send Mouse Reset command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr
	
	call	get_data_dbg		; Read Mouse for self-test status
	jp	c,err_ctlr_io		; handle controller error
	cp	$AA			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$00			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
; Begin setting mouse parameters, Request Microsoft Scrolling Mouse Mode

	ld	a,$f3			; Send Set Sample Rate command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$c8			; Send Decimal 200 command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$f3			; Send Set Sample Rate command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$64			; Send Decimal 100 command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$f3			; Send Set Sample Rate command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$50			; Send Decimal 80 command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$f2			; Send Read Device Type command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$03			; detect MS Intellimouse/Microsoft Scrolling Mouse
	jp	z,Intellimouse	
	cp	$00			; expected value? ($00 if Regular PS/2 Mouse)
	jp	z,ReadMouseID
Intellimouse:	
	call	crlf
	ld	de,str_intellimouse_ok
	call	prtstr
ReadMouseID:
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	
	ld	a,$f3			; Send Set Sample Rate command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$0a			; Send Decimal 10 command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$f2			; Send Read Device Type command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	cp	$03			; detect MS Intellimouse/Microsoft Scrolling Mouse
	jp	z,Intellimouse2	
	cp	$00			; expected value? ($00 if Regular PS/2 Mouse)
	jp	z,ReadMouseID2
Intellimouse2:	
	call	crlf
	ld	de,str_intellimouse_ok
	call	prtstr
ReadMouseID2:
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf

	ld	a,$e8			; Send Set Resolution command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$03			; Send 8 Counts/mm command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$e6			; Send Set Scaling 1:1 command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$f3			; Send Set Sample Rate command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$28			; Send Decimal 40 command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

	ld	a,$f4			; Send Enable command
	call	put_data_dbg
	jp	c,err_ctlr_io		; handle controller error
	
	call	get_data_dbg		; Read Mouse for Acknowledge
	jp	c,err_ctlr_io		; handle controller error
	cp	$fa			; expected value?
	jp	nz,err_ctlr_test	; handle self-test error
	call	crlf
	ld	de,str_ctrl_test_ok
	call	prtstr

; Initialization Complete

ReadMousePackets:

;	call	check_read
;	jp	nz, ReadMousePackets

	call	get_data_dbg		; Read Mouse for self-test status
	jp	c,err_ctlr_io		; handle controller error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	call	crlf
	
	call	get_data_dbg		; Read Mouse for Mouse ID
	jp	c,err_ctlr_io		; handle controller error
	call	crlf
	
	call	crlf
	
	jp	ReadMousePackets

;
done:
	ret

;
;=======================================================================
; Mouse Controller I/O Routines
;=======================================================================
;
wait_write:
;
; Wait for mouse controller to be ready for a write
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
; Wait for mouse controller to be ready to read a byte
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
; Put a cmd byte from A to the mouse interface with timeout
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
; Put a data byte from A to the mouse interface with timeout
; CF set indicates timeout error
;
; note: direct data to second PS/2 port, send $d4 to 8242 command register
; different than keyboard which uses first PS/2 port

	push	af			; save contents of a
	ld	e,a			; save incoming value
	call	wait_write		; wait for controller ready
	jr	z,put_data0		; if ready, move on
	scf				; else, signal timeout error
	ret				; and bail out
put_data0:
	ld	a,$d4			; direct to second PS/2 port for mouse
	out	(iocmd),a		; send second port command to 8242
	pop	af

; rest of put_data is the same as for PS/2 keyboard

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
; Get a data byte from the mouse interface to A with timeout
; CF set indicates timeout error
;
get_data:
;
	call	wait_read		; wait for byte to be ready
	jr	z,get_data1		; if ready, move on
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
err_mse_reset:
	ld	de,str_err_mse_reset
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
str_banner		.db	"Mouse Information, v0.1",0
str_exit		.db	"Done, Thank you for using MSEINFO!",0
str_cmdport		.db	"Mouse Controller Command Port: 0x",0
str_dataport		.db	"Mouse Controller Data Port: 0x",0
str_timeout_write	.db	"Mouse Controller Write Timeout, Status: 0x",0
str_timeout_read	.db	"Mouse Controller Read Timeout, Status: 0x",0
str_err_ctrl_io		.db	"Mouse Controller I/O Failure",0
str_err_ctrl_test	.db	"Mouse Controller Self-Test Failed",0
str_put_cmd		.db	"Sent Command 0x",0
str_put_data		.db	"Sent Data 0x",0
str_get_data		.db	"Got Data 0x",0
str_ctrl_test		.db	"Attempting Controller Self-Test",0
str_mse_init		.db	"Attempting Mouse Initialization",0
str_enable_mouse	.db	"Enabling Mouse in 8242 Controller",0
str_ctrl_test_ok	.db	"Controller Self-Test OK",0
str_intellimouse_ok	.db	"MS Intellimouse OK",0
str_trans_off		.db	"Disabling Controller Translation",0
str_mse_reset		.db	"Attempting Mouse Reset",0
str_mse_reset_ok	.db	"Mouse Reset OK",0
str_err_mse_reset	.db	"Mouse Reset Failed",0
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
	
