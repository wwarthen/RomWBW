;===============================================================================
; STARTUP - Application run automatically at OS startup
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   MODE [/?]
;
; Operation:
;   Determines if STARTUP.CMD exists on startup drive, user 0.  If it is
;   found, it is run via SUBMIT.
;_______________________________________________________________________________
;
; Change Log:
;   2017-12-01 [WBW] Initial release
;_______________________________________________________________________________
;
; ToDo:
;  1) Detect OS type (CP/M or ZSYS) and run different batch files as a result.
;_______________________________________________________________________________
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
ident	.equ	$FFFC		; loc of RomWBW HBIOS ident ptr
;
rmj	.equ	2		; intended CBIOS version - major
rmn	.equ	9		; intended CBIOS version - minor
;
bf_cioinit	.equ	$04	; HBIOS: CIOINIT function
bf_cioquery	.equ	$05	; HBIOS: CIOQUERY function
bf_ciodevice	.equ	$06	; HBIOS: CIODEVICE function
bf_sysget	.equ	$F8	; HBIOS: SYSGET function
;
;===============================================================================
; Code Section
;===============================================================================
;
	.org	$100
;
	; setup stack (save old value)
	ld	(stksav),sp	; save stack
	ld	sp,stack	; set new stack
;
	; initialization
	call	init		; initialize
	jr	nz,exit		; abort if init fails
;
	; process
	call 	process		; do main processing
	jr	nz,exit		; abort on error
;
exit:	; clean up and return to command processor
	call	crlf		; formatting
	ld	sp,(stksav)	; restore stack
	;jp	restart		; return to CP/M via restart
	ret			; return to CP/M w/o restart
;
; Initialization
;
init:
;
initx
	; initialization complete
	xor	a		; signal success
	ret			; return
;
; Process
;
process:
	; skip to start of first parm
	ld	ix,$81		; point to start of parm area (past len byte)
	call	nonblank	; skip to next non-blank char
	jp	z,runcmd	; no parms, do command processing
;
process1:
	; process options (if any)
	cp	'/'		; option prefix?
	jp	nz,erruse	; invalid option introducer
	call	option		; process option
	ret	nz		; some options mean we are done (e.g., "/?")
	inc	ix		; skip option character
	call 	nonblank	; skip whitespace
	jr	nz,process1	; continue option checking
	jp	runcmd		; end of parms, do cmd processing
;
;
;
runcmd:
	call	ldfil		; load executable
	ret	nz		; abort on error
;
	xor	a
	ret
;
; Load file for execution
;
ldfil:
	ld	c,15		; BDOS function: Open File
	ld	de,fcb		; pointer to FCB
	call	bdos		; do it
	inc	a		; check for err, 0xFF --> 0x00
	jp	z,errfil	; handle file not found err
;
	ld	c,16		; BDOS function: Close File
	ld	de,fcb		; pointer to FCB
	call	bdos		; do it
	inc	a		; check for err, 0xFF --> 0x00
	jp	z,errfil	; handle file close err
;
	xor	a		; signal success
	ret			; done

	
;
; Handle options
;
option:
;
	inc	ix		; next char
	ld	a,(ix)		; get it
	cp	'?'		; is it a '?' as expected?
	jp	z,usage		; yes, display usage
	jp	errprm		; anything else is an error
;
; Display usage
;
usage:
;
	call	crlf		; formatting
	ld	de,msgban	; point to version message part 1
	call	prtstr		; print it
	call	crlf2		; blank line
	ld	de,msguse	; point to usage message
	call	prtstr		; print it
	or	$FF		; signal no action performed
	ret			; and return
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
; print the hex word value in bc
;
prthexword:
	push	af
	ld	a,b
	call	prthex
	ld	a,c
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
; Add the value in A to HL (HL := HL + A)
;
addhl:
	add	a,l		; A := A + L
	ld	l,a		; Put result back in L
	ret	nc		; if no carry, we are done
	inc	h		; if carry, increment H
	ret			; and return
;
; Jump indirect to address in HL
;
jphl:
	jp	(hl)
;
; Errors
;
erruse:	; command usage error (syntax)
	ld	de,msguse
	jr	err
;
errprm:	; command parameter error (syntax)
	ld	de,msgprm
	jr	err
;
errfil:	; STARTUP.CMD file not present
	ld	de,msgfil
	jr	err
;
err:	; print error string and return error signal
	call	crlf		; print newline
;
err1:	; without the leading crlf
	call	prtstr		; print error string
;
err2:	; without the string
;	call	crlf		; print newline
	or	$FF		; signal error
	ret			; done
;
;===============================================================================
; Storage Section
;===============================================================================
;
fcb	.db	0		; Drive code, 0 = current drive
	.db	"START   "	; File name, 8 chars
	.db	"COM"		; File type, 3 chars
	.fill	36-($-fcb),0	; zero fill remainder of fcb
;
cmdblk	.db	cmdlen		; length
cmdtxt	.db	"        B:SUBMIT START"
	.db	0		; null terminator
cmdlen	.equ	$ - cmdtxt
cmdend	.equ	$
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
msgban	.db	"STARTUP v1.0, 01-Dec-2017",13,10
	.db	"Copyright (C) 2017, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: STARTUP [/?]",0
msgprm	.db	"Parameter error (STARTUP /? for usage)",0
msgfil	.db	"STARTUP.CMD file missing",0
;
	.end
