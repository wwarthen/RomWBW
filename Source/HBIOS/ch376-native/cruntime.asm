
_memset_callee:
	pop	af	; return address
	pop	bc	; address to be set
	pop	de	; value to be set
	pop	hl	; number of bytes to set
	push	af	; restore return address

	ld	a, b
	or	c
	ret	z

	ld	a, e
	push	hl
	pop	de
	ret	z

	ld	(hl), a
	inc	de
	dec	bc
	ld	a, b
	or	c
	ret	z

	push	hl
	ldir
	pop	hl
	ret

_memcpy_callee:

	pop	af
	pop	bc
	pop	hl
	pop	de
	push	af


   ; enter : bc = size_t n
   ;         hl = void *s2 = src
   ;         de = void *s1 = dst
   ;
   ; exit  : hl = void *s1 = dst
   ;         de = ptr in s1 to one byte past last byte copied
   ;         bc = 0
   ;         carry reset
   ;
   ; uses  : af, bc, de, hl

	ld	a, b
	or	c
	jr	z, zero_n

asm0_memcpy:
	push	de
	ldir
	pop	hl
	or	a
	ret

zero_n:
	push	de
	pop	hl
	ret
