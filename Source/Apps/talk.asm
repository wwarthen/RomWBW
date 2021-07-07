;===============================================================================
; Talk - Bare minimum terminal interface
;
; Console talks to designated character device.
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   TALK TTY:|CRT:|BAT:|UC1:
;_______________________________________________________________________________
;
; Change Log:
;_______________________________________________________________________________
;
; ToDo:
;   1) Handle ZCPR devices somehow
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
iobyte	.equ	$0003		; IOBYTE address
;
const	.equ	$06		; CBIOS CONST function dispatch table offset
conin	.equ	$09		; CBIOS CONIN function dispatch table offset
conout	.equ	$0C		; CBIOS CONOUT function dispatch table offset
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
	ld	de,msghel	; hello message
	call	prtstr		; print it
;
	; save active iobyte (console)
	ld	a,(iobyte)	; get active IOBYTE
	ld	(iobcon),a	; save it to iobcon
;
	; parse command line
	call	parse		; parse command line
	jr	nz,exit		; abort if parse fails
;
	; startup message
;
	ld	de,msgtlk1	; message prefix
	call	prtstr		; print it
	call	prtstrz		; print dev name at HL
	ld	de,msgtlk2	; message suffix
	call	prtstr		; print it
;
	; do the real work 
	call	talk		; do the real work
;
	; restore original iobyte
	ld	a,(iobcon)	; load original iobyte
	ld	(iobyte),a
;
	ld	de,msgbye	; goodbye message
	call	prtstr		; print it
;
exit:	; clean up and return to command processor
;
	call	crlf		; formatting
;
	ld	sp,(stksav)	; restore stack
	ret			; return to CP/M w/o reset
;
; Initialization
;
init:
	; add check for RomWBW?
;
	; locate cbios function table address
	ld	hl,(restart+1)	; load address of CP/M restart vector
	ld	de,-3		; adjustment for start of table
	add	hl,de		; HL now has start of table
	ld	(cbftbl),hl	; save it
 	; return success
	xor	a
	ret
;
; Parse command line
; If success, Z set and HL points to device name string (zero terminated)
; ... else NZ set.
;
parse:
;
	ld	hl,$81		; point to start of command tail (after length byte)
	call	nonblank	; skip blanks
	jp	z,erruse	; no parms
;
	ld	c,0		; current table entry
	ex	de,hl		; point to parm with de
	ld	hl,devtbl	; point to device table with hl
;
parse0:	; compare loop
	push	bc
	push	de
	push	hl
	call	strcmp		; compare strings
	pop	hl
	pop	de
	pop	bc
	jr	z,parse1	; if Z, we have a match
	inc	c		; increment table entry
	ld	a,5		; bump hl by
	call	addhl		; ... table entry size
	ld	a,c		; get the table entry num to A
	cp	4		; past end of table?
	jr	nz,parse0	; loop till done
	jp	errprm		; handle parm error
;
parse1:	; handle match
	ld	a,c		; device num to A
	ld	(iobcom),a	; save as com device iobyte
	; return success
	xor	a		; signal error
	ret			; and return
;
; Main routine
;
talk:	; CON: --> UC1:
;
	ld	a,(iobcon)	; setup iobyte to read from CON:
	ld	(iobyte),a
;
	call	cbios		; check for char pending using cbios
	.db	const		; ... const function
	or	a		; set flags
	jr	z,next		; no char ready
	call	cbios		; read char using cbios
	.db	conin		; ... conin function
	cp	$1A		; check for exit request (ctrl+z)
	ret	z		; if so, bail out
;
	push	af		; save the char we read
	ld	a,(iobcom)	; setup iobyte to read from UC1:
	ld	(iobyte),a
	pop	af		; recover the character
;
	ld	c,a		; move it to C
	call	cbios		; write char using cbios
	.db	conout		; ... conout function
;
next:	; UC1: --> CON: 
;
	ld	a,(iobcom)	; setup iobyte to read from com device
	ld	(iobyte),a
;
	call	cbios		; check for char pending using cbios
	.db	const		; ... const function
	or	a		; set flags
	jr	z,talk		; no char ready
	call	cbios		; read char using cbios
	.db	conin		; ... conin function
;
	push	af		; save the char we read
	ld	a,(iobcon)	; setup iobyte to read from CON:
	ld	(iobyte),a
	pop	af		; recover the character
;
	ld	c,a		; move it to C
	call	cbios		; write char using cbios
	.db	conout		; ... conout function
;
	jr	talk		; loop
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
; Print a '$' terminated string at (DE) without destroying any registers
;
prtstr:
	push	bc		; save registers
	push	de
	push	hl
	ld	c,$09		; BDOS function to output a '$' terminated string
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	ret
;
; Print a zero terminated string at (HL) without destroying any registers
;
prtstrz:
	push	hl
;
prtstrz1:
	ld	a,(hl)		; get next char
	or	a
	jr	z,prtstrz2
	call	prtchr
	inc	hl
	jr	prtstrz1
;
prtstrz2:
	pop	hl		; restore registers
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
; Start a new line
;
crlf:
	ld	a,13		; <CR>
	call	prtchr		; print it
	ld	a,10		; <LF>
	jr	prtchr		; print it
;
; Get the next non-blank character from (HL).
;
nonblank:
	ld	a,(hl)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	hl		; if blank, increment character pointer
	jr	nonblank	; and loop
;
; Check character at (DE) for delimiter.
;
delim:	or	a
	ret	z
	cp	' '		; blank
	ret	z
	jr	c,delim1	; handle control characters
	cp	'='		; equal
	ret	z
	cp	'_'		; underscore
	ret	z
	cp	'.'		; period
	ret	z
	cp	':'		; colon
	ret	z
	cp	$3b		; semicolon
	ret	z
	cp	'<'		; less than
	ret	z
	cp	'>'		; greater than
	ret
delim1:
	; treat control chars as delimiters
	xor	a		; set Z
	ret			; return
;
; Compare $ terminated strings at HL & DE
; If equal return with Z set, else NZ
;
strcmp:
;
	ld	a,(de)		; get current source char
	cp	(hl)		; compare to current dest char
	ret	nz		; compare failed, return with NZ
	or	a		; set flags
	ret	z		; end of string, match, return with Z set
	inc	de		; point to next char in source
	inc	hl		; point to next char in dest
	jr	strcmp		; loop till done
;
; Invoke CBIOS function
; The CBIOS function offset must be stored in the byte
; following the call instruction.  ex:
;	call	cbios
;	.db	$0C		; offset of CONOUT CBIOS function
;
cbios:
	ex	(sp),hl
	ld	a,(hl)		; get the function offset
	inc	hl		; point past value following call instruction
	ex	(sp),hl		; put address back at top of stack and recover HL
	ld	hl,(cbftbl)	; address of CBIOS function table to HL
	call	addhl		; determine specific function address
	jp	(hl)		; invoke CBIOS
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
; Errors
;
erruse:	; command usage error (syntax)
	ld	de,msguse
	jr	err
errprm:	; command parameter error (syntax)
	ld	de,msgprm
	jr	err
err:	; print error string and return error signal
	call	crlf		; print newline
	call	prtstr		; print error string
	or	$FF		; signal error
	ret			; done
errdos:	; handle BDOS errors
	push	af		; save return code
	call	crlf		; newline
	ld	de,msgdos	; load
	call	prtstr		; and print error string
	pop	af		; recover return code
	call	prthex		; print error code
	or	$FF		; signal error
	ret			; done
;
;===============================================================================
; Storage Section
;===============================================================================
;
cbftbl	.dw	0		; address of CBIOS function table
;
iobcon	.db	0		; iobyte value for console
iobcom	.db	0		; iobyte value for com device
;
devtbl:				; device table
	.db	"TTY:",0
	.db	"CRT:",0
	.db	"BAT:",0
	.db	"UC1:",0
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
msghel	.db	13,10,"Talk v1.0",13,10,"$"
msgbye	.db	13,10,13,10,"*** Finished talking ***","$"
msgtlk1	.db	13,10,"Talking on device $"
msgtlk2	.db	" (press <Ctrl+Z> to exit)...",13,10,13,10,"$"
msguse	.db	"Usage: TALK TTY:|CRT:|BAT:|UC1:$"
msgprm	.db	"Parameter error$"
msgdos	.db	"DOS error, return code=0x$"
;
	.end