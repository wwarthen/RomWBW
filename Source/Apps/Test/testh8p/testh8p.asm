;===============================================================================
; H8 Panel Test
;===============================================================================
;
;	AUTHOR:  WAYNE WARTHEN (wwarthen@gmail.com)
;_______________________________________________________________________________
;
;
; Trivial utility to test the register pair display functionality of the
; Heath H8 Front Panel.
;
; Program will display a set of known register values on the console,
; then go into an infinite loop.  The H8 panel can then be checked to
; see if the correct values are displayed.
;
; There is no way to exit this program.  You must reset your system.
;
;===============================================================================
; Definitions
;===============================================================================
;
stksiz	.equ	$40		; Working stack size
;
restart	.equ	$0000		; CP/M restart vector
bdos	.equ	$0005		; BDOS invocation vector
;
regA	.equ	$11
regBC	.equ	$2233
regDE	.equ	$4455
regHL	.equ	$6677
;
;===============================================================================
; Code Section
;===============================================================================
;
;
	.org	$100
;
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
;
	ld	de,str_prefix
	call	prtstr
;
	ld	de,str_A
	ld	hl,regA
	call	prtreg
	ld	de,str_BC
	ld	hl,regBC
	call	prtreg
	ld	de,str_DE
	ld	hl,regDE
	call	prtreg
	ld	de,str_HL
	ld	hl,regHL
	call	prtreg
	ld	de,str_SP
	ld	hl,regSP
	call	prtreg
	ld	de,str_PC
	ld	hl,regPC
	call	prtreg
;
	ld	a,regA
	ld	bc,regBC
	ld	de,regDE
	ld	hl,regHL
regPC:	jr	$
;
;
;
prtreg:
	call	prtstr		; print label
	ld	a,h		; first byte
	call	prtoctbyte	; print it
	ld	a,'.'		; separator
	call	prtchr		; print it
	ld	a,l		; second byte
	call	prtoctbyte	; print it
	ret
;
;
;
prtoctbyte:
	rlca			; 2 ms bits
	rlca
	push	af
	and	%00000011	; isolate
	add	a,'0'		; make char
	call	prtchr		; show it
	pop	af
	rlca			; next 3 bits
	rlca
	rlca
	push	af
	and	%00000111	; isolate
	add	a,'0'		; make char
	call	prtchr		; show it
	pop	af
	rlca			; next 3 bits
	rlca
	rlca
	push	af
	and	%00000111	; isolate
	add	a,'0'		; make char
	call	prtchr		; show it
	pop	af
	ret
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
; Print a zero terminated string at (DE) without destroying any registers
;
prtstr:
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
;===============================================================================
; Storage Section
;===============================================================================
;
rtcbuf	.fill	6,$FF		; RTC data buffer
;
str_prefix	.db	"\r\n\r\nRegisters: ",0
;
str_A		.db	"A=",0
str_BC		.db	", BC=",0
str_DE		.db	", DE=",0
str_HL		.db	", HL=",0
str_SP		.db	", SP=",0
str_PC		.db	", PC=",0
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
regSP:
;
	.end
