
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
	ret	Z

	push	hl
	ldir
	pop	hl
	ret

; _strlen_fastcall:

;    ; enter: hl = char *s
;    ;
;    ; exit : hl = length
;    ;        bc = -(length + 1)
;    ;         a = 0
;    ;        z flag set if 0 length
;    ;        carry reset
;    ;
;    ; uses : af, bc, hl

;    xor a
;    ld c,a
;    ld b,a
;    cpir
;    ld hl,$ffff
;    sbc hl,bc

;    ret

_memcpy_callee:

   pop af
   pop bc
   pop hl
   pop de
   push af


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

   ld a,b
   or c
   jr Z,zero_n

asm0_memcpy:
   push de
   ldir
   pop hl
   or a
   ret

zero_n:
	push	de
	pop	hl
   ret

; _strcat_callee:

;    pop hl
;    pop de
;    ex (sp),hl

   
;    ; enter : hl = char *s2 = src
;    ;         de = char *s1 = dst
;    ;
;    ; exit  : hl = char *s1 = dst
;    ;         de = ptr in s1 to terminating 0
;    ;
;    ; uses  : af, bc, de, hl

;    push de                     ; save dst

;    ex de,hl
;    call __str_locate_nul       ; a = 0
;    ex de,hl

; loop:                          ; append s2 to s1
;    cp (hl)
;    ldi
;    jr NZ,loop

; ENDIF

;    pop hl                      ; hl = dst
;    dec de
;    ret

; __str_locate_nul:
;    ; enter : hl = char *s
;    ;
;    ; exit  : hl = ptr in s to terminating 0
;    ;         bc = -(strlen + 1)
;    ;          a = 0
;    ;         carry reset
;    ;
;    ; uses  : af, bc, hl

;    xor a
;    ld c,a
;    ld b,a
;    cpir
;    dec hl
;    ret
