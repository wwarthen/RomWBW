;===============================================================================
;
; INTTEST - Test HBIOS interrupt API functions
;
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;_______________________________________________________________________________
;
; Usage:
;   INTTEST
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
bf_sysint	.equ	$FC	; INT function
;
bf_sysintinfo	.equ	$00	; INT INFO subfunction
bf_sysintget	.equ	$10	; INT GET subfunction
bf_sysintset	.equ	$20	; INT SET subfunction
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
	; relocate handler
	ld	hl,reladr
	ld	de,$8000
	ld	bc,hsiz
	ldir
;
initx
	; initialization complete
	xor	a		; signal success
	ret			; return
;
; Process
;
process:
;
; Get info
;
	call	crlf2
	ld	de,msginfo	; message
	call	prtstr
;
	ld	b,bf_sysint	; INT function
	ld	c,bf_sysintinfo	; INFO subfunction
	rst	08
	ld	a,d
	ld	(intmod),a	; save int mode
	ld	a,e
	ld	(veccnt),a	; save vector count
;
	push	de
	call	crlf
	ld	de,msgmode	; mode
	call	prtstr
	pop	de
	push	de
	ld	a,d		; interrupt mode
	call	prtdecb
	call	crlf
	ld	de,msgcnt	; count of vectors
	call	prtstr
	pop	de
	ld	a,e
	call	prtdecb
;
; Done if int mode is 0
;
	ld	a,(intmod)
	or	a
	ret	z
;
; List vectors
;
	call	crlf2
	ld	de,msglst	
	call	prtstr
	ld	a,(veccnt)	; get count of vectors
	or	a
	jr	z,estidx	; bypass if nothing to list
	ld	b,a		; make it the loop counter
	ld	c,0		; vector entry index
;
lstlp:
	push	bc
	call	crlf
	ld	a,' '
	call	prtchr
	call	prtchr
	ld	a,c
	call	prthex
	ld	a,':'
	call	prtchr
	ld	e,c
	ld	b,bf_sysint
	ld	c,bf_sysintget
	rst	08
	push	hl
	pop	bc
	call	prthexword
	pop	bc
	inc	c
	djnz	lstlp
;
; Establish interrupt vector index to hook
;
estidx:
	call	crlf2
	ld	de,msgvec
	call	prtstr
	call	getbuf
	ld	hl,lnbuf+1
	ld	a,(hl)		; get line length
	or	a		; set flags
	jr	z,estidx	; nothing entered
	ld	b,a		; set b to line length
	inc	hl
	call	hexbyt
	jr	c,estidx
	ld	(vecidx),a
	ld	hl,veccnt	; check index against valid range
	cp	(hl)
	jr	nc,estidx	; vector index out of bounds
;
; Hook vector
;
	call	crlf2
	ld	de,msghk1
	call	prtstr
	ld	a,(vecidx)
	call	prthex
	ld	de,msghk2
	call	prtstr
	ld	a,$ff
	ld	(count),a	; set counter to max value
;	
	ld	a,(intmod)
	cp	1
	jr	z,hkim
	cp	2
	jr	z,hkim
	ret
;
; Setup interrupt handler
;
hkim:
	ld	hl,int		; pointer to my interrupt handler
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	a,(vecidx)	; get vector idx
	ld	e,a		; put in E
	di
	rst	08		; do it
	ld	(chain),hl	; save the chain address
	ei			; interrupts back on
	jr	start
;
; Wait for counter to countdown to zero
;
start:
	call	crlf2
	ld	de,msgrun	; message
	call	prtstr
	call	crlf2
	ld	a,(count)
	ld	e,a
	call 	prthex		; print it
	ld	a,13
	call	prtchr
loop:
	call	getchr		; check console
	cp	$1B		; <esc> to exit
	jr	z,unhook	; if so, bail out
	ld	a,(count)	; get current count value
	cp	e
	jr	z,loop
	ld	e,a
	push	af
	call 	prthex		; print it
	ld	a,13
	call	prtchr
	pop	af
	or	a		; set flags
	jr	z,unhook	; done
	jr	loop		; and loop
;
; Unhook
;
unhook:
	call	crlf2
	ld	de,msgunhk
	call	prtstr
	ld	hl,(chain)	; original vector
	ld	b,bf_sysint
	ld	c,bf_sysintset	; set new vector
	ld	a,(vecidx)	; get vector idx
	ld	e,a		; put in E
	di
	rst	08		; do it
	ei			; interrupts back on
;
	xor	a		; signal success
	ret			; done
;
; Get a character from console, return in A
; returs zero if nothing available
;
getchr:
	push	bc		; save registers
	push	de
	push	hl
	ld	e,$FF		; read a character
	ld	c,$06		; BDOS direct i/o function
	call	bdos		; do it
	pop	hl		; restore registers
	pop	de
	pop	bc
	ret
;
; Get console buffer
;
getbuf:
	push	bc
	push	de
	push	hl
	ld	de,lnbuf
	ld	c,$0A
	call	bdos
	pop	hl
	pop	de
	pop	bc
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
; Convert hex chars to a byte value.
; Enter with HL pointing to buffer with chars to convert
; and B containing number of chars.  Returns value in A.
; CF set to indicate error (overflow or invalid char).
;
hexbyt:
	ld	c,0		; working value starts at zero
hexbyt1:
	sla	c		; rotate low nibble to high
	ret	c
	sla	c
	ret	c
	sla	c
	ret	c
	sla	c
	ret	c
	ld	a,(hl)		; load next char
	call	hexnibl		; convert to binary
	ret	c		; abort on error
	or	c		; combine w/ working value
	ld	c,a		; and put back in c
	inc	hl		; next position
	djnz	hexbyt1		; next character
	ld	a,c		; ret val to a
	or	a		; clear carry
	ret
;
; Convert hex character at (HL) to binary value
; Set CF to indicate invalid character
;
hexnibl:
	; handle '0'-'9'
	cp	'0'
	jr	c,hexnibl1		; if < '0', out of range
	cp	'9'+1
	jr	nc,hexnibl1		; if > '9', out of range
	and	$0F			; convert to binary value
	ret				; and done
hexnibl1:	
	; handle 'A'-'F'
	call	ucase			; force upper case
	cp	'A'
	jr	c,hexnibl2		; if < 'A', out of range
	cp	'F'+1
	jr	nc,hexnibl2		; if > 'F', out of range
	and	$0F			; convert to binary value
	add	a,9			; 
	ret				; and done
hexnibl2:
	; invalid character
	scf				; signal error
	ret
;
;===============================================================================
; Storage Section
;===============================================================================
;
intmod	.db	0		; active interrupt mode
veccnt	.db	0		; count of ingterrupt vectors
vecidx	.db	0		; vector index to hook
lnbuf	.db	10,0		; 10 char BDOS line input buffer
	.fill	10
;
stksav	.dw	0		; stack pointer saved at start
	.fill	stksiz,0	; stack
stack	.equ	$		; stack top
;
; Messages
;
msgban	.db	"INTTEST v1.2, 15-May-2019",13,10
	.db	"Copyright (C) 2019, Wayne Warthen, GNU GPL v3",0
msginfo	.db	"Interrupt information request...",0
msgmode	.db	"  Active interrupt mode: ",0
msgcnt	.db	"  Vector entries in use: ",0
msglst	.db	"Interrupt vector address list:",0
msghk1	.db	"Hooking vector ",0
msghk2	.db	"...",0
msgunhk	.db	"Unhooking vector...",0
msgrun	.db	"Interrupt countdown (press <esc> to exit)...",0
msgvec	.db	"Enter vector to hook (hex): ",0
;
;===============================================================================
; Interrupt Handler
;===============================================================================
;
reladr	.equ	$		; relocation start adr
;
	.org	$8000		; code will run here
;
int:
	; count down to zero
	ld	a,(count)	; get current count value
	or	a               ; test for zero
	jr	z,int1		; if zero, leave it alone
	dec	a               ; decrement
	ld	(count),a       ; and save
int1:
	xor	a		; signal int has NOT been handled
	; follow the chain...
	ld	hl,(chain)	; get chain adr
	jp	(hl)		; go there
;	ret
;
chain	.dw	$0000		; chain address
count	.db	0		; counter
;
hsiz	.equ	$ - $8000	; size of handler to relocate
	.end
