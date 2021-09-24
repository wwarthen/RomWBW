;
;=======================================================================
; HDIAG Utility Functions
;=======================================================================
;
; Print string at HL on console, null terminated.
; HL and AF are trashed.
;
prtstr:
	ld	a,(hl)			; get next character
	or	a			; set flags
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	jr	prtstr			; loop till done
;
; Print a string from a lookup table pointed to by HL, index A
; with a prefix string at DE.  HL, DE, and A are trashed.
;
prtstrtbl:
	push	af
	ex	de,hl
	call	prtstr
	ex	de,hl
	pop	af
	rlca
	call	addhla
	ld	a,(hl)
	inc	hl
	ld	h,(hl)
	ld	l,a
	call	prtstr
	ret
;
; Print the hex byte value in A
;
prthex8:
	push	af
	push	de
	call	hexascii
	ld	a,d
	call	cout
	ld	a,e
	call	cout
	pop	de
	pop	af
	ret
;
; Print the hex word value in BC
;
prthex16:
	push	af
	ld	a,b
	call	prthex8
	ld	a,c
	call	prthex8
	pop	af
	ret
;
; Print the hex dword value in DE:HL
;
prthex32:
	push	bc
	push	de
	pop	bc
	call	prthex16
	push	hl
	pop	bc
	call	prthex16
	pop	bc
	ret
;
; Convert binary value in A to ASCII hex characters in DE
;
hexascii:
	ld	d,a
	call	hexconv
	ld	e,a
	ld	a,d
	rlca
	rlca
	rlca
	rlca
	call	hexconv
	ld	d,a
	ret
;
; Convert low nibble of A to ASCII hex
;
hexconv:
	and	$0F	     ; low nibble only
	add	a,$90
	daa
	adc	a,$40
	daa
	ret

;
; Jump to address in HL/IX/IY
;
;   No registers affected
;   Typically used as "call jphl" to call a routine
;   at address in HL register.
;
jphl:
	jp	(hl)
;
jpix:
	jp	(ix)
;
jpiy:
	jp	(iy)
;
; Add hl,a
;
;   A register is destroyed!
;
addhla:
	add	a,l
	ld	l,a
	ret	nc
	inc	h
	ret

