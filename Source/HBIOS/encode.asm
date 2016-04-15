;
;==================================================================================================
; FUNCTIONS TO ENCODE/DECODE 32-BIT VALUES TO/FROM A 5-BIT SHIFT-ENCODED VALUE
;==================================================================================================
;
; THE FUNCTIONS IN THIS FILE ARE BASED ON LIKE FUNCTIONS CREATED BY JOHN COFFMAN
; IN HIS UNA BIOS PROJECT.  THEY ARE INCLUDED HERE BASED ON GPLV3 PERMISSIBLE USE.
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
ENCODE:
	; *** MAKE SURE INCOMING VALUE IS NOT ZERO???
	CALL	ENCODE6			; TEST DE:HL FOR ZERO
	JR	Z,ENCODE4		; IF NOT ZERO, GO TO FAILURE
	; APPLY ENCODING DIVISOR
	CALL	DIV32X8			; DE:HL / C (REMAINDER IN A)
	OR	A			; SET FLAGS TO TEST FOR ZERO
	RET	NZ			; ERROR IF NOT EVENLY DIVISIBLE
	; APPLY DIV 3 IF POSSIBLE
	LD	BC,ENCODE_TMP		; SAVE WORKING VALUE
	CALL	ST32			; ... IN TEMP
	LD	C,3			; ATTEMPT DIVIDE
	CALL	DIV32X8			; ... BY 3
	OR	A			; SET FLAGS TO TEST FOR ZERO
	JR	Z,ENCODE1		; JUMP IF IT WORKED
	LD	HL,ENCODE_TMP		; FAILED, RESTORE
	CALL	LD32			; ... PRIOR WORKING VALUE
	LD	C,0			; INIT RESULT IN C W/O DIV 3 FLAG
	JR	ENCODE2
ENCODE1:
	LD	C,$10			; INIT RESULT IN C W/ DIV 3 FLAG
ENCODE2:
	; LOOP TO DETERMINE POWER OF 2
	LD	B,32
ENCODE3:
	SRL	D
	RR	E
	RR	H
	RR	L
	JR	C,ENCODE5		; DONE, C HAS RESULT
	INC	C			; BUMP THE RESULT VALUE
	DJNZ	ENCODE3
ENCODE4:
	OR	$FF			; SIGNAL ERROR
	RET				; AND DONE
ENCODE5:
	CALL	ENCODE6			; TEST FOR ZERO
	RET	NZ			; ERROR IF DE:HL NOT ZERO NOW
	; RETURN SUCCESS W/ VALUE IN C
	XOR	A			; SIGNAL SUCCESS
	RET				; AND DONE
;
ENCODE6:
	; SUBROUTINE TO TEST DE:HL FOR ZERO (SETS ZF, CLOBBERS A)
	LD	A,H
	OR	L
	RET	NZ
	LD	A,D
	OR	E
	RET
;
ENCODE_TMP	.FILL	4,0		; TEMP DWORD VALUE
