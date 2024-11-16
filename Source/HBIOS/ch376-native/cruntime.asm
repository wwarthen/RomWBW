
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

.if 0
; required if --optimise-for-size is targetted
; but there appears to be a regression that stop the driver from working
; if optimised for size is selected
___sdcc_enter_ix:
	ex	(sp), ix
	push	ix
	ld	ix, 2
	add	ix, sp
	ret

____sdcc_lib_setmem_hl:
l_setmem_hl:
	ret

____sdcc_load_debc_mhl:
	ld	c, (hl)
	inc	hl
	ld	b, (hl)
	inc	hl
	ld	e, (hl)
	inc	hl
	ld	d, (hl)
	ret

____sdcc_4_push_hlix:
	pop	af
	push	af
	push	af
	push	af

	push	de

	push	ix
	pop	de

	add	hl, de

	ex	de, hl

	ld	hl, 2+2
	add	hl, sp

	ex	de, hl

	ldi
	ldi
	ldi
	ld	a, (hl)
	ld	(de), a

	inc	bc
	inc	bc
	inc	bc

	pop	de
	ret

____sdcc_store_debc_mhl:
	ld	(hl), c
	inc	hl
	ld	(hl), b
	inc	hl
	ld	(hl), e
	inc	hl
	ld	(hl), d
	ret
.endif
