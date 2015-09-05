;
;==================================================================================================
;   RAM FLOPPY DISK DRIVER
;==================================================================================================
;
;
;
RF_U0IO		.EQU	$A0
RF_U1IO		.EQU	$A4
;
; IO PORT OFFSETS
;
RF_DAT		.EQU	0
RF_AL		.EQU	1
RF_AH		.EQU	2
RF_ST		.EQU	3
;
;
;
RF_DISPATCH:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F
	JR	Z,RF_READ
	DEC	A
	JR	Z,RF_WRITE
	DEC	A
	JR	Z,RF_STATUS
	DEC	A
	JR	Z,RF_MEDIA
	CALL	PANIC
;
; RF_MEDIA
;
RF_MEDIA:
	LD	A,C		; GET THE DEVICE/UNIT
	AND	$0F		; ISOLATE UNIT
	CP	RFCNT		; NUM UNITS
	LD	A,MID_RF	; ASSUME WE ARE OK
	RET	C		; RETURN
	XOR	A		; NO MEDIA
	RET			; AND RETURN
;
;
;
RF_INIT:
	PRTS("RF: UNITS=$")
	LD	A,RFCNT
	CALL	PRTDECB
;
	XOR	A		; INIT SUCCEEDED
	RET			; RETURN
;
;
;
RF_STATUS:
	XOR	A		; STATUS ALWAYS OK
	RET
;
;
;
RF_READ:
	CALL	RF_SETIO
	CALL	RF_SETADR
	LD	HL,(DIOBUF)
	LD	B,0
	LD	A,(RF_IO)
	OR	RF_DAT
	LD	C,A
	INIR
	INIR
	XOR	A
	RET
;
;
;
RF_WRITE:
	CALL	RF_SETIO
	LD	A,(RF_IO)
	OR	RF_ST
	LD	C,A
	IN	A,(C)
	BIT	0,A			; CHECK WRITE PROTECT
	LD	A,1			; PREPARE TO RETURN FALSE (ERROR)
	RET	NZ			; WRITE PROTECTED!
	CALL	RF_SETADR
	LD	HL,(DIOBUF)
	LD	B,0
	LD	A,(RF_IO)
	OR	RF_DAT
	LD	C,A
	OTIR
	OTIR
	XOR	A
	RET
;
;
;
RF_SETIO:
	LD	A,(HSTDSK)	; GET DEVICE/UNIT
	AND	$0F		; ISOLATE UNIT NUM
	JR	NZ,RF_SETIO1
	LD	A,RF_U0IO
	JR	RF_SETIO3
RF_SETIO1:
	DEC	A
	JR	NZ,RF_SETIO2
	LD	A,RF_U1IO
	JR	RF_SETIO3
RF_SETIO2:
	CALL	PANIC		; INVALID UNIT
RF_SETIO3:
	LD	(RF_IO),A
	RET
;
;
;
RF_SETADR:
	LD	A,(RF_IO)
	OR	RF_AL
	LD	C,A
	LD	A,(HSTLBALO)
	OUT	(C),A
	LD	A,(HSTLBALO+1)
	INC	C
	OUT	(C),A
	RET
;
;
;
RF_IO	.DB	0