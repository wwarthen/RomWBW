;
;==================================================================================================
; ENCODE 32-BIT VALUES TO A 5-BIT SHIFT-ENCODED VALUE
;==================================================================================================
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; An encoded value (V) is defined as V = C * 2^X * 3^Y
; where C is a prearranged constant, X is 0 or 1 and Y is 0-15
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
	; *** MAKE SURE INCOMING VALUE IS NOT ZERO???
	CALL	ENCODE5			; TEST DE:HL FOR ZERO
	JR	Z,ENCODE4		; IF ZERO, FAILURE RETURN
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
;
ENCODE5:
	; TEST DE:HL FOR ZERO (SETS ZF, CLOBBERS A)
	LD	A,H
	OR	L
	OR	D
	OR	E
	RET				; RET W/ Z SET IF SUCCESSFUL
;
ENCODE_TMP	.FILL	4,0		; TEMP DWORD VALUE
