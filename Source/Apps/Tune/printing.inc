;
; Print character in A without destroying any registers
;
PRTCHR:
	PUSH	BC		; save registers
	PUSH	DE
	PUSH	HL
	LD	E,A		; character to print in E
	LD	C,$02		; BDOS function to output a character
	CALL	BDOS		; do it
	POP	HL		; restore registers
	POP	DE
	POP	BC
	RET
;
PRTDOT:
;
	; shortcut to print a dot preserving all regs
	PUSH	AF		; save af
	LD	A,'.'		; load dot char
	CALL	PRTCHR		; print it
	POP	AF		; restore af
	RET			; done
;
PRTCR:
;
	; shortcut to print a carriage return preserving all regs
	PUSH	AF		; save af
	LD	A,13		; load CR value
	CALL	PRTCHR		; print it
	POP	AF		; restore af
	RET			; done
;
; Print a zero terminated string at (DE) without destroying any registers
;
PRTSTR:
	PUSH	AF
	PUSH	DE
;
PRTSTR1:
	LD	A,(DE)		; get next char
	OR	A
	JR	Z,PRTSTR2
	CALL	PRTCHR
	INC	DE
	JR	PRTSTR1
;
PRTSTR2:
	POP	DE		; restore registers
	POP	AF
	RET
;
; Print the value in A in hex without destroying any registers
;
PRTHEX:
	PUSH	AF		; save AF
	PUSH	DE		; save DE
	CALL	HEXASCII	; convert value in A to hex chars in DE
	LD	A,D		; get the high order hex char
	CALL	PRTCHR		; print it
	LD	A,E		; get the low order hex char
	CALL	PRTCHR		; print it
	POP	DE		; restore DE
	POP	AF		; restore AF
	RET			; done
;
; print the hex word value in bc
;
PRTHEXWORD:
	PUSH	AF
	LD	A,B
	CALL	PRTHEX
	LD	A,C
	CALL	PRTHEX
	POP	AF
	RET
;
; print the hex dword value in de:hl
;
PRTHEX32:
	PUSH	BC
	PUSH	DE
	POP	BC
	CALL	PRTHEXWORD
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD
	POP	BC
	RET
;
; Convert binary value in A to ascii hex characters in DE
;
HEXASCII:
	LD	D,A		; save A in D
	CALL	HEXCONV		; convert low nibble of A to hex
	LD	E,A		; save it in E
	LD	A,D		; get original value back
	RLCA			; rotate high order nibble to low bits
	RLCA
	RLCA
	RLCA
	CALL	HEXCONV		; convert nibble
	LD	D,A		; save it in D
	RET			; done

;
; Convert low nibble of A to ascii hex
;
HEXCONV:
	AND	$0F	     	; low nibble only
	ADD	A,$90
	DAA
	ADC	A,$40
	DAA
	RET

;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
PRTDECB:
	PUSH	HL
	LD	H,0
	LD	L,A
	CALL	PRTDECW		; print it
	POP	HL
	RET
;
PRTDECW:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	PRTDEC0
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
PRTDEC0:
	LD	E,'0'
	LD	BC,-10000
	CALL	PRTDEC1
	LD	BC,-1000
	CALL	PRTDEC1
	LD	BC,-100
	CALL	PRTDEC1
	LD	C,-10
	CALL	PRTDEC1
	LD	E,0
	LD	C,-1
PRTDEC1:
	LD	A,'0' - 1
PRTDEC2:
	INC	A
	ADD	HL,BC
	JR	C,PRTDEC2
	SBC	HL,BC
	CP	E
	RET	Z
	LD	E,0
	CALL	PRTCHR
	RET
;
; Start a new line
;
CRLF2:
	CALL	CRLF		; two of them
CRLF:
	PUSH	AF		; preserve AF
	LD	A,13		; <CR>
	CALL	PRTCHR		; print it
	LD	A,10		; <LF>
	CALL	PRTCHR		; print it
	POP	AF		; restore AF
	RET
