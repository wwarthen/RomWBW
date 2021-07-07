;
;==================================================================================================
; ENCODE 32-BIT VALUES TO A 5-BIT SHIFT-ENCODED VALUE
;==================================================================================================
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; An encoded value (V) is defined as V = C * 2^X * 3^Y
; where C is a prearranged constant, Y is 0 or 1 and X is 0-15
; The encoded value is stored as 5 bits: YXXXX
; At present, C=75 for baud rate encoding and C=3 for CPU OSC encoding
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  ENCODE
;
; Enter with:
;	DE:HL	=  dword value to be encoded
;	C	=  divisor (0 < C < 256)
;		   encode divisor OSC_DIV = 3, or BAUD_DIV = 75
;
; Exit with:
;	C	=  encoded value
;       A	=  non-zero on error
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
encode:
	; incoming value of zero is a failure
	call	encode5			; test DE:HL for zero
	jr	z,encode4		; if zero, failure return
;
	; apply encoding divisor
	call	div32x8			; DE:HL / C (remainder in A)
	or	a			; set flags to test for zero
	ret	nz			; error if not evenly divisible
;
	; test divide by 3 to see if it is possible
	push	de			; save working
	push	hl			; ... value
	ld	c,3			; divide by 3
	call	div32x8			; ... test
	pop	hl			; restore working
	pop	de			; ... value
;
	; implmement divide by 3 if possible
	ld	c,$00			; init result in c w/ div 3 flag clear
	or	a			; set flags to test for remainder
	jr	nz,encode2		; jump if it failed
;
	; if divide by 3 worked, do it again for real
	ld	c,3			; setup to divide by 3 again
	call	div32x8			; do it
	ld	c,$10			; init result in c w/ div 3 flag set
;
encode2:
	; loop to determine power of 2
	ld	b,16			; can only represent up to 2^15
encode3:
	srl	d			; right shift de:hl into carry
	rr	e			; ...
	rr	h			; ...
	rr	l			; ...
	jr	c,encode5		; if carry, then done, c has result
	inc	c			; bump the result value
	djnz	encode3			; keep shifting if possible
encode4:
	or	$ff			; signal error
	ret				; and done
;
encode5:
	; test de:hl for zero (sets zf, clobbers a)
	ld	a,h
	or	l
	or	d
	or	e
	ret				; ret w/ Z set if DE:HL == 0
