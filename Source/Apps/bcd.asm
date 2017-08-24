;;
;; make a bcd number from a binary number
;; 32 bit binary number in hl:bc, result stored at (de)
;; de is preserved, all other regs destroyed
;;
;bin2bcd:
;	push	ix		; save ix
;	push	bc		; move bc
;	pop	ix		; ... to ix
;	ld	c,32		; loop for 32 bits of binary dword
;;
;bin2bcd0:
;	; outer loop (once for each bit in binary number)	
;	ld	b,5		; loop for 5 bytes of result
;	push	de		; save de
;	add	ix,ix		; left shift next bit from hl:ix
;	adc	hl,hl		; ... into carry
;;
;bin2bcd1:
;	; inner loop (once for each byte of bcd number)
;	ld	a,(de)		; get it
;	adc	a,a		; double it w/ carry
;	daa			; decimal adjust
;	ld	(de),a		; save it
;	inc	de		; point to next bcd byte
;	djnz	bin2bcd1	; loop thru all bcd bytes
;;
;	; remainder of outer loop
;	pop	de		; recover de
;	dec	c		; dec bit counter
;	jr	nz,bin2bcd0	; loop till done with all bits
;	pop	ix		; restore ix
;
; make a bcd number from a binary number
; 32 bit binary number in de:hl, result stored at (bc)
; on output hl = bcd buf adr
;
bin2bcd:
	push	ix		; save ix
	; convert from de:hl -> (bc) to hl:ix -> (de)
	; hl -> ix, de -> hl, bc -> de
	ex	de,hl
	push	de
	pop	ix
	push	bc
	pop	de
;
	ld	c,32		; loop for 32 bits of binary dword
;
bin2bcd0:
	; outer loop (once for each bit in binary number)	
	ld	b,5		; loop for 5 bytes of result
	push	de		; save de
	add	ix,ix		; left shift next bit from hl:ix
	adc	hl,hl		; ... into carry
;
bin2bcd1:
	; inner loop (once for each byte of bcd number)
	ld	a,(de)		; get it
	adc	a,a		; double it w/ carry
	daa			; decimal adjust
	ld	(de),a		; save it
	inc	de		; point to next bcd byte
	djnz	bin2bcd1	; loop thru all bcd bytes
;
	; remainder of outer loop
	pop	de		; recover de
	dec	c		; dec bit counter
	jr	nz,bin2bcd0	; loop till done with all bits
	ex	de,hl		; hl -> bcd buf
	pop	ix		; restore ix
	ret
;
; print contents of 5 byte bcd number at (hl)
; with leading zero suppression
; all regs destroyed
;
prtbcd:
	inc	hl		; bump hl to point to
	inc	hl		; ...
	inc	hl		; ...
	inc	hl		; ... last byte of bcd
	ld	b,5		; loop for 5 bytes
	ld	c,0		; start by suppressing leading zeroes
;
prtbcd1:
	; loop to print one bcd byte (two digits)
	xor	a		; clear accum
	rld			; rotate first nibble into a
	call	prtbcd2		; print it
	xor	a		; clear accum
	rld			; rotate second nibble into a
	call	prtbcd2		; print it
	dec	hl		; point to prior byte
	djnz	prtbcd1		; loop till done
	ret			; return
;
prtbcd2:
	; subroutine to print a digit in a
	cp	c		; compare incoming to c
	ret	z		; if equal, suppressing, abort
	dec	c		; make c negative to stop suppression
	add	a,'0'		; offset to printable value
	jp	prtchr		; exit via character out
