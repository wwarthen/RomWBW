; diagnose.asm 5/23/2012 dwg - diagnose binding for Aztec C

	global	hrega_,1
	global	hregbc_,2
	global	hregde_,2
	global	hreghl_,2


	public	diagnose_
diagnose:
	push	psw
	push	b
	push	d
	push	h

	lhld	hregbc_
	mov	b,h
	mov	c,l

	lhld	hregde_
	mov	d,h
	mov	e,l

	lhld	hreghl_

	lda	hrega_

  	db 0cfh	;  rst 8
	
	sta	hrega_
	shld	hreghl_

	mov	l,e
	mov	h,d
	shld	hregde_

	mov	l,c
	mov	h,b
	shld	hregbc_

	pop	h
	pop	d
	pop	b
	pop	psw

	RET

	END
