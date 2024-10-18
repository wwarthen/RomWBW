
	; HL = unsigned 16 bit number to write out
	; call CHPUT to write a single ascii character (in A)
_print_uint16:
	ld	a, h
	or	l
	jr	z, print_zero
	ld	e, 0
	ld	bc, -10000
	call	num1
	ld	bc, -1000
	call	num1
	ld	bc, -100
	call	num1
	ld	c, -10
	call	num1
	ld	c, b

num1:	ld	a, '0'-1
num2:	inc	a
	add	hl, bc
	jr	c, num2
	sbc	hl, bc

	cp	'0'
	jr	nz, num3

	ld	a, e
	cp	1
	ret	nz
	ld	a, '0'

num3:
	ld	e, 1
	jp	COUT

print_zero
	ld	a, '0'
	jp	COUT
