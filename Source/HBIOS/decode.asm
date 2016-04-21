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
DECODE:
	LD	A,H			; SET TO TEST
	LD	C,$FF			; PRESUME ERROR CONDITION
	OR	A			; TEST FOR ZERO
	JR	NZ,DECODE9		; NOT AN ENCODED VALUE
	LD	A,L			; GET LOW ORDER 5 BITS
	CP	32			; TEST FOR ERROR
	JR	NC,DECODE9		; ERROR RETURN IF NOT BELOW
	; ARGUMENT HL IS VALIDATED
	LD	H,D
	LD	L,E			; COPY TO HL
	CP	16	
	JR	C,DECODE2		; IF < 16, NO 3 FACTOR
	ADD	HL,DE			; INTRODUCE FACTOR OF 3
	ADD	HL,DE			; **
DECODE2:	
	LD	DE,0			; ZERO THE HIGH ORDER
	AND	15			; MASK TO 4 BITS
	JR	Z,DECODE8		; GOOD EXIT
	LD	C,B			; SAVE B-REG
	LD	B,A			;
DECODE3:	
	ADD	HL,HL			; SHIFT LEFT BY 1, SET CARRY
	RL	E	
	RL	D			; **
	DJNZ	DECODE3	
	LD	B,C			; RESTORE B-REG
DECODE8:	
	LD	C,0			; SIGNAL GOOD RETURN
DECODE9:	
	LD	A,C			; ERROR CODE TEST
	OR	A			; ERROR CODE IN REG-C AND Z-FLAG
	RET
