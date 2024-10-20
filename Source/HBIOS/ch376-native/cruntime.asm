
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


; ; ===============================================================
; ; Stefano Bodrato
; ; aralbrec: accommodate nmos z80 bug
; ; ===============================================================
; ;
; ; void z80_push_di(void)
; ;
; ; Save the current ei/di status on the stack and disable ints.
; ;
; ; ===============================================================

; ____sdcc_cpu_push_di:

;    ; exit  : stack = ei_di_status
;    ;
;    ; uses  : af

;    ex (sp),hl
;    push hl
       
;    ld a,i
   
;    di
   
;    push af
;    pop hl                      ; hl = ei_di status
   
;    pop af                      ; af = ret
;    ex (sp),hl                  ; restore hl, push ei_di_status
   
;    push af

;    ret


; ; ===============================================================
; ; Stefano Bodrato
; ; ===============================================================
; ;
; ; void z80_pop_ei(void)
; ;
; ; Pop the ei_di_status from the stack and restore the di/ei
; ; state to what it was previously when a push was called.
; ;
; ; The "ei" in the function name has no bearing on what the
; ; function does; the name is meant to balance "z80_push_di".
; ;
; ; ===============================================================

; ____sdcc_cpu_pop_ei:

;    ; enter  : stack = ei_di_status, ret
;    ;
;    ; uses  : af

;    ex (sp),hl
;    pop af                      ; af = old hl
   
;    ex (sp),hl                  ; hl = ei_di_status
;    push af
   
;    ex (sp),hl                  ; hl restored

; ____sdcc_cpu_pop_ei_jp:
;    ; enter : stack = ret, ei_di_status
;    ;
;    ; uses  : af

;    pop af                      ; af = ei_di_status

;    jp PO, di_state

; ei_state:
;    ei
;    ret

; di_state:
;    di
;    ret
