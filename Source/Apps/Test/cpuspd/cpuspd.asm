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
#include "../../../HBIOS/hbios.inc"
;
; General operational equates (should not requre adjustment)
;
stksiz		.equ	$40		; Working stack size
;
rtc_port	.equ	$70		; RTC latch port adr
;
restart		.equ	$0000		; CP/M restart vector
bdos		.equ	$0005		; BDOS invocation vector
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
; Get HBIOS platform ID
;
	; Use first char of FCB for speed selection
	ld	a,($5D)
	cp	' '
	jr	z,show_spd
	and	$5F		; make upper case
	cp	'D'		; double
	jr	z,set_dbl
	cp	'F'		; full
	jr	z,set_full
	cp	'H'		; half
	jr	z,set_half
	jr	usage
;
set_half:
	ld	l,0
	jr	new_spd
;
set_full:
	ld	l,1
	jr	new_spd
;
set_dbl:
	ld	l,2
	jr	new_spd
;
new_spd:
	ld	b,BF_SYSSET
	ld	c,BF_SYSSET_CPUSPD
	rst	08
	jp	nz,err_not_sup
	call	show_spd
	xor	a
	ret
;
show_spd:
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
	call	crlf2
	call	prtstr
	pop	hl
;
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
usage:
	call	crlf2
	ld	de,str_usage
	call	prtstr
	or	$FF
	ret
;
; Error Handlers
;
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
;
;=======================================================================
; Constants
;=======================================================================
;
str_banner		.db	"RomWBW CPU Speed Selector v0.2, 26-Jan-2022",0
str_spacer		.db	"  ",0
str_slow		.db	"  CPU speed is HALF",0
str_full		.db	"  CPU speed is FULL",0
str_dbl			.db	"  CPU speed is DOUBLE",0
str_memws		.db	" Memory Wait State(s)",0
str_iows		.db	" I/O Wait State(s)",0
str_err_not_sup		.db	"  ERROR: Platform or configuration not supported!",0
str_err_invalid		.db	"  ERROR: Invalid configuration!",0
str_usage		.db	"  Usage: CPUSPD [Half|Full|Double]",0
;
;=======================================================================
; Working data
;=======================================================================
;
stksav		.dw	0		; stack pointer saved at start
		.fill	stksiz,0	; stack
stack		.equ	$		; stack top
;
;=======================================================================
;
	.end