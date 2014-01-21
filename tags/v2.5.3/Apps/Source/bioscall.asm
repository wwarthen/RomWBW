; bioscall.asm 3/10/2012 dwg - bios binding for Aztec C

	global	irega_,1
	global	iregbc_,2
	global	iregde_,2
	global	ireghl_,2


	public	getmeta_
getmeta_:
	push	psw
	push	b
	push	d
	push	h

	lxi	b,4
	lxi	d,0
	call	0e61bh

	lxi	d,0
	call	0e61eh

	lxi	d,11
	call	0e621h

	lxi	d,80h
	call	0e624h

	call	0e627h

	pop	h
	pop	d
	pop	b
	pop	psw
	ret

	PUBLIC bioscall_
bioscall_:	

	push	b
	push	d
	push	h
	push	psw

	lhld	iregbc_
	mov	b,h
	mov	c,l

	lhld	iregde_
	mov	d,h
	mov	e,l

	lhld	ireghl_
	shld	mycall+1

	lda	irega_

mycall:	call	5
	
	sta	irega_

	shld	ireghl_

	mov	l,e
	mov	h,d
	shld	iregde_

	mov	l,c
	mov	h,b
	shld	iregbc_
	
	pop	psw
	pop	h
	pop	d
	pop	b

	RET

	END
