;===============================================================================
; TIMER - Display system timer value
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   TIMER [/C] [/?]
;     ex: TIMER		(display current timer value)
;         TIMER /?	(display version and usage)
;         TIMER /C	(display timer value continuously)
;
; Operation:
;   Reads and displays system timer value.
;_______________________________________________________________________________
;
; Change Log:
;   2018-01-14 [WBW] Initial release
;   2018-01-17 [WBW] Add HBIOS check
;   2019-11-08 [WBW] Add seconds support
;_______________________________________________________________________________
;
; ToDo:
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
ident	.equ	$FFFE		; loc of RomWBW HBIOS ident ptr
;
rmj	.equ	3		; intended CBIOS version - major
rmn	.equ	1		; intended CBIOS version - minor
;
bf_sysver	.equ	$F1	; BIOS: VER function
bf_sysget	.equ	$F8	; HBIOS: SYSGET function
bf_sysset	.equ	$F9	; HBIOS: SYSGET function
bf_sysgettimer	.equ	$D0	; TIMER subfunction
bf_syssettimer	.equ	$D0	; TIMER subfunction
bf_sysgetsecs	.equ	$D1	; SECONDS subfunction
bf_syssetsecs	.equ	$D1	; SECONDS subfunction
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
	call	crlf		; formatting
	ld	de,msgban	; point to version message part 1
	call	prtstr		; print it
;
	call	idbio		; identify active BIOS
	cp	1		; check for HBIOS
	jp	nz,errbio	; handle BIOS error
;
	ld	a,rmj << 4 | rmn	; expected HBIOS ver
	cp	d		; compare with result above
	jp	nz,errbio	; handle BIOS error
;
initx
	; initialization complete
	xor	a		; signal success
	ret			; return
;
; Process
;
process:
	; look for start of parms
	ld	hl,$81		; point to start of parm area (past len byte)
;
process00:
	call	nonblank	; skip to next non-blank char
	jp	z,process0	; no more parms, go to display
;
	; check for option, introduced by a "/"
	cp	'/'		; start of options?
	jp	nz,usage	; yes, handle option
	call	option		; do option processing
	ret	nz		; done if non-zero return
	jr	process00	; continue looking for options
;
process0:
;
	; Test of API function to set seconds value
	;ld	b,bf_sysset	; HBIOS SYSGET function
	;ld	c,bf_syssetsecs	; SECONDS subfunction
	;ld	de,0		; set seconds value
	;ld	hl,1000		; ... to 1000
	;rst	08		; call HBIOS, DE:HL := seconds value
;
	; get and print seconds value
	call	crlf2		; formatting
;
process1:
	ld	b,bf_sysget	; HBIOS SYSGET function
	ld	c,bf_sysgettimer	; TIMER subfunction
	rst	08		; call HBIOS, DE:HL := timer value
	
	ld	a,(first)
	or	a
	ld	a,0
	ld	(first),a
	jr	nz,process1a
	
	; test for new value
	ld	a,(last)	; last LSB value to A
	cp	l		; compare to current LSB
	jr	z,process2	; if equal, bypass display

process1a:	
	; save and print new value
	ld	a,l		; new LSB value to A
	ld	(last),a	; save as last value
	call	prtcr		; back to start of line
	;call	nz,prthex32	; display it
	call	prthex32	; display it
	ld	de,strtick	; tag
	call	prtstr		; display it

	; get and print seconds value
	ld	b,bf_sysget	; HBIOS SYSGET function
	ld	c,bf_sysgetsecs	; SECONDS subfunction
	rst	08		; call HBIOS, DE:HL := seconds value
	call	prthex32	; display it
	ld	a,'.'		; fraction separator
	call	prtchr		; print it
	ld	a,c		; get fractional component
	call	prthex		; print it
	ld	de,strsec	; tag
	call	prtstr		; display it
;
process2:
	ld	a,(cont)	; continuous display?
	or	a		; test for true/false
	jr	z,process3	; if false, get out
;
	ld	c,6		; BDOS: direct console I/O
	ld	e,$FF		; input char
	call	bdos		; call BDOS, A := char
	or	a		; test for zero
	jr	z,process1	; loop until char pressed
;
process3:
	xor	a		; signal success
	ret
;
; Handle special options
;
option:
;
	inc	hl		; next char
	ld	a,(hl)		; get it
	or	a		; zero terminator?
	ret	z		; done if so
	cp	' '		; blank?
	ret	z		; done if so
	cp	'?'		; is it a '?'?
	jp	z,usage		; yes, display usage
	cp	'C'		; is it a 'C', continuous?
	jp	z,setcont	; yes, set continuous display
	jp	errprm		; anything else is an error
;
usage:
;
	jp	erruse		; display usage and get out
;
setcont:
;
	or	$FF		; set A to true
	ld	(cont),a	; and set continuous flag
	jr	option		; check for more option letters
;
; Identify active BIOS.  RomWBW HBIOS=1, UNA UBIOS=2, else 0
;
idbio:
;
	; Check for UNA (UBIOS)
	ld	a,($FFFD)	; fixed location of UNA API vector
	cp	$C3		; jp instruction?
	jr	nz,idbio1	; if not, not UNA
	ld	hl,($FFFE)	; get jp address
	ld	a,(hl)		; get byte at target address
	cp	$FD		; first byte of UNA push ix instruction
	jr	nz,idbio1	; if not, not UNA
	inc	hl		; point to next byte
	ld	a,(hl)		; get next byte
	cp	$E5		; second byte of UNA push ix instruction
	jr	nz,idbio1	; if not, not UNA, check others
;
	ld	bc,$04FA	; UNA: get BIOS date and version
	rst	08		; DE := ver, HL := date
;
	ld	a,2		; UNA BIOS id = 2
	ret			; and done
;
idbio1:
	; Check for RomWBW (HBIOS)
	ld	hl,($FFFE)	; HL := HBIOS ident location
	ld	a,'W'		; First byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
	inc	hl		; Next byte of ident
	ld	a,~'W'		; Second byte of ident
	cp	(hl)		; Compare
	jr	nz,idbio2	; Not HBIOS
;
	ld	b,bf_sysver	; HBIOS: VER function
	ld	c,0		; required reserved value
	rst	08		; DE := version, L := platform id
;	
	ld	a,1		; HBIOS BIOS id = 1
	ret			; and done
;
idbio2:
	; No idea what this is
	xor	a		; Setup return value of 0
	ret			; and done
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
prtcr:
;
	; shortcut to print a dot preserving all regs
	push	af		; save af
	ld	a,13		; load CR value
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
	ld	a,(hl)		; load next character
	or	a		; string ends with a null
	ret	z		; if null, return pointing to null
	cp	' '		; check for blank
	ret	nz		; return if not blank
	inc	hl		; if blank, increment character pointer
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
errbio:	; invalid BIOS or version
	ld	de,msgbio
	jr	err
;
err:	; print error string and return error signal
	call	crlf2		; print newline
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
last	.db	0		; last LSB of timer value
cont	.db	0		; non-zero indicates continuous display
first	.db	$FF		; first pass flag (true at start)
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
msgban	.db	"TIMER v1.1, 10-Nov-2019",13,10
	.db	"Copyright (C) 2019, Wayne Warthen, GNU GPL v3",0
msguse	.db	"Usage: TIMER [/C] [/?]",13,10
	.db	"  ex. TIMER           (display current timer value)",13,10
	.db	"      TIMER /?        (display version and usage)",13,10
	.db	"      TIMER /C        (display timer value continuously)",0
msgprm	.db	"Parameter error (TIMER /? for usage)",0
msgbio	.db	"Incompatible BIOS or version, "
	.db	"HBIOS v", '0' + rmj, ".", '0' + rmn, " required",0
strtick	.db	" Ticks, ",0
strsec	.db	" Seconds",0
;
	.end
