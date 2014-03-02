; memory.asm 2/1/2012 dwg - memory library implementation
	maclib	z80

;memcpy	macro	h=src,d==dst,bc=size
	public	x$memcpy
x$memcpy:
	ldir
	ret

; memset	macro	h=dst,a=data,c=siz
	public	x$memset
x$memset:
	push	psw
x$ms$loop:
	pop	psw
	mov	m,a
	inx	h
	dcx	b
	push	psw
	mov	a,b
	ora	c
	jnz	x$ms$loop
	pop	psw
	ret

; eof - memory.asm
