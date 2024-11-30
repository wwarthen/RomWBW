;
;==================================================================================================
; DECODE 32-BIT VALUES FROM A 5-BIT SHIFT-ENCODED VALUE
;==================================================================================================
;
;   Copyright (C) 2014 John R. Coffman.  All rights reserved.
;   Provided for hobbyist use on the Z180 SBC Mark IV board.
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; THE FUNCTION(S) IN THIS FILE ARE BASED ON LIKE FUNCTIONS CREATED BY JOHN COFFMAN
; IN HIS UNA BIOS PROJECT.  THEY ARE INCLUDED HERE BASED ON GPLV3 PERMISSIBLE USE.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; An encoded value (V) is defined as V = C * 2^X * 3^Y
; where C is a prearranged constant, X is 0 or 1 and Y is 0-15
; The encoded value is stored as 5 bits: YXXXX
; At present, C=75 for baud rate encoding and C=3 for CPU OSC encoding
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  DECODE
;
; Enter with:
;	HL	=  word to be decoded (5-bits)    FXXXX
;		   F=extra 3 factor, XXXX=shift factor, reg H must be zero
;	DE	=  encode divisor OSC_DIV = 3, or BAUD_DIV = 75
;
; Exit with:
;	DE:HL	=  decoded value
;       A	=  non-zero on error
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
decode:
	ld	a,h			; set to test
	ld	c,$ff			; presume error condition
	or	a			; test for zero
	jr	nz,decode9		; not an encoded value
	ld	a,l			; get low order 5 bits
	cp	32			; test for error
	jr	nc,decode9		; error return if not below
	; argument hl is validated
	ld	h,d
	ld	l,e			; copy to hl
	cp	16	
	jr	c,decode2		; if < 16, no 3 factor
	add	hl,de			; introduce factor of 3
	add	hl,de			; **
decode2:	
	ld	de,0			; zero the high order
	and	15			; mask to 4 bits
	jr	z,decode8		; good exit
	ld	c,b			; save b-reg
	ld	b,a			;
decode3:	
	add	hl,hl			; shift left by 1, set carry
	rl	e	
	rl	d			; **
	djnz	decode3	
	ld	b,c			; restore b-reg
decode8:	
	ld	c,0			; signal good return
decode9:	
	ld	a,c			; error code test
	or	a			; error code in reg-c and z-flag
	ret
