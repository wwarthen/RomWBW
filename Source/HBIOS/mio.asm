;___MIO________________________________________________________________________________________________________________
;
; MEMORY MAPPED I/O
;
;   PROVIDES AN INTERFACE TO BUFFER OUTPUT FROM PRE-INITIALIZATION 
;   FUNCTIONS PRIOR TO OTHER OUTPUT METHODS BEING AVAILABLE
;______________________________________________________________________________________________________________________
;
; $ CODE NOT STRICTLY REQUIRED.
;
MIOOUTPTR	.EQU	BNKTOP
;
MIO_INIT:				; MINIMAL INIT
	PUSH	HL
	LD	HL,MIOOUTPTR+2
	LD	(MIOOUTPTR),HL
	LD	(HL),'$'
	POP	HL
	RET
;
MIO_OUTC:	; OUTPUT BYTE IN A
	PUSH	HL
	PUSH	DE
	LD	HL,MIOOUTPTR
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	H,D
	LD	L,E
	LD	(HL),A
	INC	HL
	LD	(MIOOUTPTR),HL
	LD	(HL),'$'
	POP	DE
	POP	HL
	RET
;
; NOT USED AT THE MOMENT
;
MIO_INC:	; INPUT BYTE TO A
	LD	A,'$'
	RET
;
;
MIO_IST:	; INPUT STATUS TO A (NUM CHARS WAITING)
	LD	A,1
	OR	A
	RET				; DONE
;