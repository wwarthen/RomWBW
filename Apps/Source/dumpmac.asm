; dumpmac.asm 2/1/2012 dwg - dump macro, declaration and implementation 

	maclib	portab
	maclib	globals
	maclib	hardware
	maclib	z80
	maclib	cpmbdos
	maclib	printers

	cseg

; e=char on entry
	public	x$pr$vis
x$pr$vis:
	enter
	lxi	h,x$visibool
	mvi	d,0
	dad	d
	mov	a,m
	cpi	0
	jz	do$dot
	mvi	c,2
	call	BDOS
	jmp	x$pr$fini
do$dot:
	conout	'.'
x$pr$fini:
	leave
	ret

	public	x$dump
x$dump:	shld	x$dump$tmp
	call	pr$h$word
	conout	':'
	conout	' '
	mvi	b,16
x$d$lp1:
	mov	a,m
	inx	h
	xchg
	mov	l,a
	call	pr$h$byte
	conout	' '
	xchg
	dcr	b
	jnz	x$d$lp1
	conout	' '
	conout	' '
	mvi	b,16
	lhld	x$dump$tmp
x$d$lp2:
	mov	a,m
	inx	h	
	mov	e,a
	call	x$pr$vis
	dcr	b
	jnz	x$d$lp2
	conout	CR
	conout	LF
	lhld	x$dump$tmp
	ret


; display a number of lines of sixteen bytes in hex with leading address
; and ascii
	public	x$dump$multi
x$dump$multi:
	push	h	; save display address in case x$dump changes it
	call	x$dump	; call actual dump routine for 16 bytes
	pop	h	; restore display address
	lxi	d,16	; get ready to increment it by 16 bytes
	dad	d	; here we go, HL = new load address
	dcr	c	; decrement line counter
	jnz	x$dump$multi	; do more as necessary
	ret


	dseg

x$dump$tmp	ds	2

	public	x$visibool
x$visibool:
;               0 1 2 3 4 5 6 7 8 9 A B C D E F
;               - - - - - - - - - - - - - - - -
vb$00	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$10	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$20	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;  "#$%&'()*+,-./
vb$30	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;0123456789:;<=>?
vb$40	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;@ABCDEFGHIJKLMNO
vb$50	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;PQRSTUVWXYZ[\]^_
vb$60	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1		;`abcdefghijklmno
vb$70	db	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0		;pqrstuvwxyz{|}~
vb$80	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$90	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$a0	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$b0	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$c0	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$d0	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$e0	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
vb$f0	db	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

; eof - dumpmac.asm




