; identity.asm 2/17/2012 dwg - Program Identity Declarations

	maclib	portab
	maclib	globals
	maclib	stdlib
	maclib	cpmbios
	maclib	cpmbdos
	maclib	memory
	maclib	printers

	public	x$ident
x$ident:
	shld	lfcbptr		; save pointer to fcb

	mvi	c,FOPEN
	lhld	lfcbptr
	xchg
	call	BDOS
	cpi	255
	jnz	openok

;;;	memcpy	lname,file1fcb+1,8
	mvi	c,8
	lxi	d,lname
	lhld	lfcbptr
	inx	h
	call	x$memcpy

	mvi	a,','
	sta	ldot

;;;	memcpy	lext,file1fcb+9,3
	mvi	c,3
	lhld	lfcbptr
	lxi	d,9
	dad	d
	lxi	d,lext
	call	x$memcpy


	mvi	a,'$'
	sta	lterm
	print	lname
	printf	' -- File Not Found'
	mvi	a,FAILURE
	jmp	fini
openok:

	mvi	c,SETDMA
	lxi	d,buffer
	call	BDOS

	mvi	c,READSEQ
	lhld	lfcbptr
	xchg
	call	BDOS


	mvi	c,SETDMA
	lxi	d,buffer+128
	call	BDOS

	mvi	c,READSEQ
	lhld	lfcbptr
	xchg
	call	BDOS

	mvi	c,FCLOSE
	lhld	lfcbptr
	xchg
	call	BDOS

	lxi	d,d$prog
	mvi	c,9
	call	BDOS

	conout	','
	conout	' '
	lda	p$rmj
	mov	l,a
	mvi	h,0
	call	pr$d$word
	conout	'.'
	lda	p$rmn
	mov	l,a
	call	pr$d$word
	conout	'.'
	lda	p$rup
	mov	l,a
	call	pr$d$word
	conout	'.'
	lda	p$rtp
	mov	l,a
	call	pr$d$word
	conout	','
	conout	' '

	lda	p$mon
	mov	l,a
	call	pr$d$word
	conout	'/'
	lda	p$day
	mov	l,a
	call	pr$d$word
	conout	'/'
	lhld	p$year
	call	pr$d$word
	conout	','
	conout	' '

	lxi	d,d$prod
	mvi	c,9
	call	BDOS
	conout	','
	conout	' '

	lxi	d,d$orig
	mvi	c,9
	call	BDOS
	conout	','
	conout	' '

	lxi	d,d$ser
	mvi	c,9
	call	BDOS
	conout	','
	conout 	' '

	lda	d$term2
	cpi	'$'
	jnz	do$name
	conout	' '
	lxi	d,d$uuid+19
	jmp	do$any
do$name:
	lxi	d,d$name
do$any:
	mvi	c,9
	call	BDOS

	mvi	a,SUCCESS	; set return code
fini:
	ret

lfcbptr	ds	2
ldrive	ds	1
lcolon	ds	1
lname	ds	8
ldot	ds	1
lext	ds	3
lterm	ds	1

	db	'buffer-->'
buffer	ds	1
p$start	ds	2
p$hexrf	ds	16
p$sig	ds	2
p$rmj	ds	1
p$rmn	ds	1
p$rup	ds	1
p$rtp	ds	1
p$mon	ds	1
p$day	ds	1
p$year	ds	2
p$argv	ds	2
p$e5	ds	1
p$pr$st	ds	2
p$code1	ds	3		; begin: lxi h,0
p$code2	ds	1		;   dad sp
p$code3	ds	3		;   shld pre$stk
p$code4	ds	3		;    lxi sp,stack$top
p$code5	ds	1		;    nop
p$code6	ds	3		;    jmp around$bandata
p$prog	ds	2		;   dw prog
p$dat	ds	2		;   dw dat
p$prod	ds	2		;   dw prod
p$orig	ds	2		;   dw orig
p$ser	ds	2		;   dw ser
p$nam	ds	2		;   dw nam
p$term	ds	2		;   dw 0
d$prog	ds	8+1+3+1		;   db '12345678.123$'
d$date	ds	2+1+2+1+4+1	;   db ' 2/11/2012$'
d$ser	ds	6+1		;   db '654321$'
d$prod	ds	5+1		;   db 'CPM80$'
d$orig	ds	3+1		;   db 'DWG$'
d$name	ds	1+7+1+1+1+1+7+1	;   db ' Douglas W. Goodall$'
d$uuid	ds	36		; unique user identification
d$term2	ds	1		; can be set to zero or dollar sign
p$len	equ	$-buffer
p$rsvd	ds	256-p$len
	db	'<--buffer'
	dw	p$len
crlf	db	CR,LF,'$'

; eof - identity.asm
