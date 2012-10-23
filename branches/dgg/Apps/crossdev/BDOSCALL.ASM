; bdoscall.asm 3/10/2012 dwg - bdos binding for Aztec C

	global	drega_,1
	global	dregbc_,2
	global	dregde_,2
	global	dreghl_,2

	PUBLIC lurst_
lurst_:	

	push	b
	push	d
	push	h
	push	psw

	mvi	c,37
	lxi	d,127
	lxi	b,127
	call	5

	pop	psw
	pop	h
	pop	d
	pop	b

	RET


	PUBLIC bdoscall_
bdoscall_:	

	push	b
	push	d
	push	h
	push	psw

	lhld	dregbc_
	mov	b,h
	mov	c,l

	lhld	dregde_
	mov	d,h
	mov	e,l

	lhld	dreghl_

	lda	drega_

	call	5
	
	sta	drega_

	shld	dreghl_

	mov	l,e
	mov	h,d
	shld	dregde_

	mov	l,c
	mov	h,b
	shld	dregbc_
	
	pop	psw
	pop	h
	pop	d
	pop	b

	RET

	END
