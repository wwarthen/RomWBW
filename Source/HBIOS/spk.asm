;
;======================================================================
; I/O BIT DRIVER FOR CONSOLE BELL FOR SBC V2 USING BIT 0 OF RTC DRIVER
;======================================================================
;
SPK_INIT:
	CALL	NEWLINE			; FORMATTING
	PRTS("SPK: IO=0x$")
	LD	A,DSRTC_BASE
	CALL	PRTHEXBYTE
	CALL	SPK_BEEP
	XOR	A
	RET
;
SPK_BEEP:
	PUSH	DE
	PUSH	HL
	LD	HL,400			; CYCLES OF TONE
	;LD	B,%00000100		; D2 MAPPED TO Q0
	;LD	A,DSRTC_RESET
	LD	A,(RTCVAL)		; GET RTC PORT VALUE FROM SHADOW
	OR	%00000100		; D2 MAPPED TO Q0
	LD	B,A
SPK_BEEP1:
	LD	A,B
	OUT	(DSRTC_BASE),A
	XOR	%00000100
	LD	B,A
	LD	DE,17
	CALL	VDELAY
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,SPK_BEEP1
	POP	HL
	POP	DE
	RET
