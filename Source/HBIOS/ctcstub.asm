;___CTC________________________________________________________________________________________________________________
;
; Z80 CTC STUB
;
;   DISPLAY CONFIGURATION DETAILS
;______________________________________________________________________________________________________________________
;
CTC_INIT:				; MINIMAL INIT
CTC_PRTCFG:
	; ANNOUNCE PORT
	CALL	NEWLINE			; FORMATTING
	PRTS("CTC$")			; FORMATTING
;	LD	A,(IY)			; DEVICE NUM
;	CALL	PRTDECB			; PRINT DEVICE NUM
	PRTS(": IO=0x$")		; FORMATTING
	LD	A,CTCBASE		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT
;
	XOR	A
	RET
