;
;=======================================================================
; HBIOS CPU Speed Selection Tool
;=======================================================================
;
; Simple utility that sets CPU speed on RomWBW systems that support
; software speed selection.
;
;=======================================================================
;
#include "../../HBIOS/hbios.inc"
;
; General operational equates (should not requre adjustment)
;
stksiz		.equ	$40		; Working stack size
;
cpumhz		.equ	30		; for time delay calculations (not critical)
;
rtc_port	.equ	$70		; RTC latch port adr
;
restart		.equ	$0000		; CP/M restart vector
bdos		.equ	$0005		; BDOS invocation vector
;
ident		.equ	$FFFE		; loc of RomWBW HBIOS ident ptr
;
rmj		.equ	3		; intended CBIOS version - major
rmn		.equ	1		; intended CBIOS version - minor
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
	; initialization
	call	init			; initialize
	jr	nz,exit			; abort if init fails
;
	call	main			; do the real work
;
exit:
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
;
; Initialization
;
init:
	; check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,initwbw	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,initwbw	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,initwbw	; if not, not UNA
	jp	err_una		; UNA not supported
;
initwbw:
	; get location of config data and verify integrity
	ld	hl,(ident)	; HL := adr or RomWBW HBIOS ident
	ld	a,(hl)		; get first byte of RomWBW marker
	cp	'W'		; match?
	jp	nz,err_inv	; abort with invalid config block
	inc	hl		; next byte (marker byte 2)
	ld	a,(hl)		; load it
	cp	~'W'		; match?
	jp	nz,err_inv	; abort with invalid config block
	inc	hl		; next byte (major/minor version)
	ld	a,(hl)		; load it
	cp	rmj << 4 | rmn	; match?
	jp	nz,err_ver	; abort with invalid os version
;
initz:
	; initialization complete
	xor	a		; signal success
	ret			; return
;
;
;
main:
	; skip to start of first parm
	ld	ix,$81		; point to start of parm area (past len byte)
	call	nonblank	; skip to next non-blank char
	jp	z,show_spd	; no parms, show current settings
;
main1:
	; process options (if any)
	cp	'/'		; option prefix?
	jr	nz,main2	; not an option, continue
	call	option		; process option
	ret	nz		; some options mean we are done (e.g., "/?")
	inc	ix		; skip option character
	call 	nonblank	; skip whitespace
	jr	main1		; continue option checking
;
main2:
	ret	z		; if end, nothing to do
	cp	','		; no new speed?
	jr	z,main2a	; go to wait states
	; parse speed string (half, full, double)
	call	getalpha	; extract speed ("HALF", "FULL", "DOUBLE")
	call	parse_spd	; parse to numeric
	jp	c,err_parm	; if invalid, abort
	ld	(new_cpu_spd),a	; save it
	call	nonblank	; skip whitespace
	jp	z,set_spd	; if nothing else, set new speed
	cp	','		; parm separator
	jp	nz,err_parm	; invalid format, show usage and abort
main2a:
	inc	ix		; pass separator
	call	nonblank	; skip whitespace
	jp	z,set_spd	; if nothing else, set new speed
	call	isnum		; start of parm?
	jr	c,main3		; nope, try skipping this parm
	call	getnum		; get memory wait states
	jp	c,err_parm	; if overflow, show usage and abort
	ld	(new_ws_mem),a	; save memory wait states
;
main3:
	call	nonblank	; skip whitespace
	jp	z,set_spd	; if nothing else, set new speed
	cp	','		; parm separator
	jp	nz,err_parm	; invalid format, show usage and abort
	inc	ix		; pass separator
	call	nonblank	; skip whitespace
	jp	z,set_spd	; if nothing else, set new speed
	call	getnum		; get I/O wait states
	jp	c,err_parm	; if overflow, show usage and abort
	ld	(new_ws_io),a	; save memory wait states
;
	call	nonblank	; skip whitespace
	jp	nz,err_parm	; invalid format, show usage and abort
	jp	set_spd		; set new speed and return
;
parse_spd:
	ld	a,(tmpstr)		; first byte of string
	ld	c,0			; assume half speed
	cp	'H'			; check it
	jr	z,parse_spd1		; if equal, done
	ld	c,1			; assume full speed
	cp	'F'			; check it
	jr	z,parse_spd1		; if equal, done
	ld	c,2			; assume double speed
	cp	'D'			; check it
	jr	z,parse_spd1		; if equal, done
	or	a			; clear CF
	ccf				; set CF to indicate error
	ret
parse_spd1:
	ld	a,c			; result to a
	or	a			; clear CF
	ret
;
set_spd:
	call	delay
	ld	b,BF_SYSSET
	ld	c,BF_SYSSET_CPUSPD
	ld	a,(new_cpu_spd)
	ld	l,a
	ld	a,(new_ws_mem)
	ld	d,a
	ld	a,(new_ws_io)
	ld	e,a
	rst	08
	jp	nz,err_not_sup
	call	show_spd
	xor	a
	ret
;
show_spd:
	ld	b,BF_SYSGET
	ld	c,BF_SYSGET_CPUINFO
	rst	08
	jp	nz,err_not_sup
	call	crlf2
	push	de			; save CPU speed for now
	push	bc			; Oscillator speed to HL
	pop	hl
	ld	de,str_spacer
	call	prtstr
	call	prtd3m			; print it
	ld	de,str_oscspd
	call	prtstr
	ld	b,BF_SYSGET
	ld	c,BF_SYSGET_CPUSPD
	rst	08
	jp	nz,err_not_sup
	push	de
	ld	a,l
	ld	de,str_slow
	cp	0
	jr	z,show_spd1
	ld	de,str_full
	cp	1
	jr	z,show_spd1
	ld	de,str_dbl
	cp	2
	jr	z,show_spd1
	jp	err_invalid
show_spd1:
	call	crlf
	call	prtstr
	pop	bc			; recover wait states
	pop	hl			; recover CPU speed
	push	bc			; resave wait states
	call	prtd3m
	ld	de,str_cpuspd
	call	prtstr
	pop	hl
	ld	a,h			; memory wait states
	cp	$FF
	jr	z,show_spd2
	call	crlf
	ld	de,str_spacer
	call	prtstr
	call	prtdecb
	ld	de,str_memws
	call	prtstr
;
show_spd2:
	ld	a,l
	cp	$FF
	jr	z,show_spd3
	call	crlf
	ld	de,str_spacer
	call	prtstr
	call	prtdecb
	ld	de,str_iows
	call	prtstr
;
show_spd3:
	ret
;
; Handle special options
;
option:
;
	inc	ix		; next char
	ld	a,(ix)		; get it
	cp	'?'		; is it a '?' as expected?
	jp	z,usage		; yes, display usage
	jp	err_parm	; anything else is an error

usage:
	call	crlf2
	ld	de,str_usage
	call	prtstr
	or	$FF
	ret
;
; Error Handlers
;
err_una:
	ld	de,str_err_una
	jr	err_ret
err_inv:
	ld	de,str_err_inv
	jr	err_ret
err_ver:
	ld	de,str_err_ver
	jr	err_ret
err_parm:
	ld	de,str_err_parm
	jr	err_ret
err_not_sup:
	ld	de,str_err_not_sup
	jr	err_ret
err_invalid:
	ld	de,str_err_invalid
	jr	err_ret
;
err_ret:
	call	crlf2
	call	prtstr
	or	$FF			; signal error
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
	push	af
	push	bc		; save registers
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
; Print a dot character without destroying any registers
;
prtdot:
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
; Print value of HL as thousandths, ie. 0.000
;
prtd3m:
	push	bc
	push	de
	push	hl
	ld	e,'0'
	ld	bc,-10000
	call	prtd3m1
	ld	e,0
	ld	bc,-1000
	call	prtd3m1
	call	prtdot
	ld	bc,-100
	call	prtd3m1
	ld	c,-10
	call	prtd3m1
	ld	c,-1
	call	prtd3m1
	pop	hl
	pop	de
	pop	bc
	ret
prtd3m1:
	ld	a,'0' - 1
prtd3m2:
	inc	a
	add	hl,bc
	jr	c,prtd3m2
	sbc	hl,bc
	cp	e
	jr	z,prtd3m3
	ld	e,0
	call	prtchr
prtd3m3:
	ret



;
; Get the next non-blank character from (HL).
;
nonblank:
	ld	a,(ix)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	ix		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Get alpha chars and save in tmpstr
; Length of string returned in A
;
getalpha:
;
	ld	hl,tmpstr	; location to save chars
	ld	b,8		; length counter (tmpstr max chars)
	ld	c,0		; init character counter
;
getalpha1:
	ld	a,(ix)		; get active char
	call	ucase		; lower case -> uppper case, if needed
	cp	'A'		; check for start of alpha range
	jr	c,getalpha2	; not alpha, get out
	cp	'Z' + 1		; check for end of alpha range
	jr	nc,getalpha2	; not alpha, get out
	; handle alpha char
	ld	(hl),a		; save it
	inc	c		; bump char count
	inc	hl		; inc string pointer
	inc	ix		; increment buffer ptr
	djnz	getalpha1	; if space, loop for more chars
;
getalpha2:	; non-alpha, clean up and return
	ld	(hl),0		; terminate string
	ld	a,c		; string length to A
	or	a		; set flags
	ret			; and return
;
; Determine if byte in A is a numeric '0'-'9'
; Return with CF clear if it is numeric
;
isnum:
	cp	'0'
	jr	c,isnum1	; too low
	cp	'9' + 1
	jr	nc,isnum1	; too high
	or	a		; clear CF
	ret
isnum1:
	or	a		; clear CF
	ccf			; set CF
	ret
	
;
; Get numeric chars and convert to number returned in A
; Carry flag set on overflow
;
getnum:
	ld	c,0		; C is working register
getnum1:
	ld	a,(ix)		; get the active char
	cp	'0'		; compare to ascii '0'
	jr	c,getnum2	; abort if below
	cp	'9' + 1		; compare to ascii '9'
	jr	nc,getnum2	; abort if above
;
	; valid digit, add new digit to C
	ld	a,c		; get working value to A
	rlca			; multiply by 10
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	add	a,c		; ...
	ret	c		; overflow, return with carry set
	rlca			; ...
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
	ld	a,(ix)		; get new digit
	sub	'0'		; make binary
	add	a,c		; add in working value
	ret	c		; overflow, return with carry set
	ld	c,a		; back to C
;
	inc	ix		; bump to next char
	jr	getnum1		; loop
;
getnum2:	; return result
	ld	a,c		; return result in A
	or	a		; with flags set, CF is cleared
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
; Convert character in A to uppercase
;
ucase:
	cp	'a'		; if below 'a'
	ret	c		; ... do nothing and return
	cp	'z' + 1		; if above 'z'
	ret	nc		; ... do nothing and return
	res	5,a		; clear bit 5 to make lower case -> upper case
	ret			; and return
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
	ld	a,cpumhz - 2
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
;=======================================================================
; Constants
;=======================================================================
;
str_banner		.db	"RomWBW CPU Speed Selector v0.5, 2-Feb-2022",0
str_spacer		.db	"  ",0
str_oscspd		.db	" MHz Oscillator",0
str_slow		.db	"  CPU speed is HALF (",0
str_full		.db	"  CPU speed is FULL (",0
str_dbl			.db	"  CPU speed is DOUBLE (",0
str_cpuspd		.db	" MHz)",0
str_memws		.db	" Memory Wait State(s)",0
str_iows		.db	" I/O Wait State(s)",0
str_err_una		.db	"  ERROR: UNA not supported by application",0
str_err_inv		.db	"  ERROR: Invalid BIOS (signature missing)",0
str_err_ver		.db	"  ERROR: Unexpected HBIOS version",0
str_err_parm		.db	"  ERROR: Parameter error (CPUSPD /? for usage)",0
str_err_not_sup		.db	"  ERROR: Platform or configuration not supported!",0
str_err_invalid		.db	"  ERROR: Invalid configuration!",0
str_usage		.db	"  Usage: CPUSPD <cpuspd>,<memws>,<iows>\r\n"
			.db	"\r\n"
			.db	"         <cpuspd>: \"Half\", \"Full\", or \"Double\"\r\n"
			.db	"         <memws>:  Memory wait states\r\n"
			.db	"         <iows>:   I/O wait states\r\n"
			.db	"\r\n"
			.db	"         Any parameter may be omitted\r\n"
			.db	"         Ability to set values varies by system\r\n",0
;
;=======================================================================
; Working data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
;
tmpstr		.fill	9,0		; temp string (8 chars, 0 term)
new_cpu_spd	.db	$FF		; new CPU speed
new_ws_mem	.db	$FF		; new memory wait states
new_ws_io	.db	$FF		; new I/O wait states


;
;=======================================================================
;
	.end