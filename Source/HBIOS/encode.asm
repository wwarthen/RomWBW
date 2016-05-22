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
ENCODE:
	; INCOMING VALUE OF ZERO IS A FAILURE
	CALL	ENCODE5			; TEST DE:HL FOR ZERO
	JR	Z,ENCODE4		; IF ZERO, FAILURE RETURN
;
	; APPLY ENCODING DIVISOR
	CALL	DIV32X8			; DE:HL / C (REMAINDER IN A)
	OR	A			; SET FLAGS TO TEST FOR ZERO
	RET	NZ			; ERROR IF NOT EVENLY DIVISIBLE
;
	; TEST DIVIDE BY 3 TO SEE IF IT IS POSSIBLE
	PUSH	DE			; SAVE WORKING
	PUSH	HL			; ... VALUE
	LD	C,3			; DIVIDE BY 3
	CALL	DIV32X8			; ... TEST
	POP	HL			; RESTORE WORKING
	POP	DE			; ... VALUE
;
	; IMPLMEMENT DIVIDE BY 3 IF POSSIBLE
	LD	C,$00			; INIT RESULT IN C W/ DEV 3 FLAG CLEAR
	OR	A			; SET FLAGS TO TEST FOR REMAINDER
	JR	NZ,ENCODE2		; JUMP IF IT FAILED
;
	; IF DIVIDE BY 3 WORKED, DO IT AGAIN FOR REAL
	LD	C,3			; SETUP TO DIVIDE BY 3 AGAIN
	CALL	DIV32X8			; DO IT
	LD	C,$10			; INIT RESULT IN C W/ DIV 3 FLAG SET
;
ENCODE2:
	; LOOP TO DETERMINE POWER OF 2
	LD	B,16			; CAN ONLY REPRESENT UP TO 2^15
ENCODE3:
	SRL	D			; RIGHT SHIFT DE:HL INTO CARRY
	RR	E			; ...
	RR	H			; ...
	RR	L			; ...
	JR	C,ENCODE5		; IF CARRY, THEN DONE, C HAS RESULT
	INC	C			; BUMP THE RESULT VALUE
	DJNZ	ENCODE3			; KEEP SHIFTING IF POSSIBLE
ENCODE4:
	OR	$FF			; SIGNAL ERROR
	RET				; AND DONE
;
ENCODE5:
	; TEST DE:HL FOR ZERO (SETS ZF, CLOBBERS A)
	LD	A,H
	OR	L
	OR	D
	OR	E
	RET				; RET W/ Z SET IF DE:HL == 0
