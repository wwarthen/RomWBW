;__________________________________________________________________________________________________
; HARDWARE INTERFACE FOR POLLED AND INTERRUPT DRIVEN PS2 KEYBOARD.
;
; IN POLLED MODE THE CONTROLLER PORT VALUES ARE KNOWN BY THE CALLING DRIVER.
; IN INTERRUPT MODE THE DEVICES PORTS ARE UNKNOWN SO PREDEFINED PORT VALUES ARE USED.
;
; REQUIRES AN APPROPRIATE INTERRUPT JUMPER TO BE SET. 
; CURRENTLY CONFIGURED FOR INT #2 ON DUODYNE WITH I/O MULTI BOARD.
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & KBDINTS))
;
;__________________________________________________________________________________________________
; KEYBOARD QUEUE FOR INTERRUPTS
;__________________________________________________________________________________________________
;
;
KBDQSIZ		.EQU	32		; MUST BE POWER OF TWO, <=128
KBDQGETX	.DB	0		; QUEUE INDEX
KBDQPUTX	.DB	0		; QUEUE INDEX
;		.DB	$55		; GUARD BYTE FOR DEBUGGING ; NOTE THAT SCAN CODES ARE BEING
KBDQ		.FILL	KBDQSIZ,0	; CIRCULAR KEYBOARD BUFFER ; BUFFERED. ONE KEY PRESS CAN
;		.DB	$AA		; GUARD BYTE FOR DEBUGGING ; GENERATE SEVERAL SCAN CODES
;
;__________________________________________________________________________________________________
; RESET THE QUEUE TO EMPTY
;__________________________________________________________________________________________________
;
;KBDQINIT: 
;	XOR	A
;	LD	(KBDQGETX),A
;	LD	(KBDQPUTX),A
;	RET
;
;__________________________________________________________________________________________________
; KEYBOARD INTERRUPT VECTOR
;__________________________________________________________________________________________________
;
KBD_INT:
;	CALL	KBDQDBG
	LD	IY,(KBD_IDAT)		; POINT TO INSTANCE DATA
;
	CALL	KBD_IST_P		; READ CONTROLLER STATUS
	RET	Z			; EXIT IF NOTHINGTO READ
	LD	C,(IY+KBD_DAT)
	EZ80_IO				; IF SOMETHING PENDING
	IN	A,(C)			; READ THE BYTE IN
	LD	B,A			; AND SAVE IT
;
	CALL	KBDQLEN			; CHECK IF 
	SUB	KBDQSIZ			; QUEUE IS FULL
	RET	Z			; EXIT IF THE QUEUE IS FULL
;
	LD	HL,KBDQPUTX		; CREATE QUEUE INDEX
	CALL	KBD_Q_IDX		; POINTER IN HL
;
	LD	(HL),A			; SAVE THE CHARACTER IN THE QUEUE
;	CALL	KBDQDBG
;
	RET
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD READ
;__________________________________________________________________________________________________
;
; READ DIRECT FROM PORT
;
KBD_IN_P:
	LD	C,(IY+KBD_DAT)		; DATA PORT
	EZ80_IO
	IN	A,(C)			; GET THE DATA VALUE
	RET
;
; READ FROM INTERRUPT QUEUE
;
#IF ((INTMODE == 2) & KBDINTS))
;
KBD_IN_Q:
KBDQPOP:
	CALL	KBDQLEN
	RET	Z			; EXIT IF THE QUEUE IS EMPTY
;
	LD	HL,KBDQGETX		; CREATE QUEUE INDEX
	CALL	KBD_Q_IDX		; POINTER IN HL
;
	LD	A,(HL)			; GET THE CHARACTER FROM THE QUEUE
;	LD	(HL),B			; DEBUG - CLEAN QUEUE
;
	RET

KBD_Q_IDX:
	LD	A,(HL)			; CREATE QUEUE INDEX
	AND	KBDQSIZ-1
	INC	(HL)			; UPDATE INDEX
	LD	HL,KBDQ			; INDEX INTO THE QUEUE
	LD	C,A
	LD	A,B			; NOTE THE QUEUE GET
	LD	B,0			; AND PUT INDEXES
	ADD	HL,BC			; NEVER DECREASE
	RET
;
#ENDIF
;
#IF ((INTMODE == 2) & KBDINTS))
KBD_IN	.EQU	KBD_IN_Q
#ELSE
KBD_IN	.EQU	KBD_IN_P
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD INPUT STATUS
;__________________________________________________________________________________________________
;
; DIRECT PORT STATUS READ
;
KBD_IST_P:
	LD	C,(IY+KBD_ST)		; STATUS PORT
	EZ80_IO
	IN	A,(C)			; GET STATUS
	AND	$01			; ISOLATE INPUT PENDING BIT
	RET
;
; STATUS FROM INTERRUPT QUEUE
;
#IF ((INTMODE == 2) & KBDINTS))
;
KBD_IST_Q:
KBDQLEN:				; EXIT WITH NUMBER OF CHARACTERS IN QUEUE
	LD	A,(KBDQPUTX)		; Z STATUS AND ZERO IF NONE 
	LD	HL,KBDQGETX
	SUB	(HL)
	RET
;
#ENDIF
;
; 	RETURN INDICATION OF KEYBOARD DATA READY
;
#IF ((INTMODE == 2) & KBDINTS))
KBD_IST	.EQU	KBD_IST_Q
#ELSE
KBD_IST	.EQU	KBD_IST_P
#ENDIF
;
;__________________________________________________________________________________________________
; OUTPUT TO KEYBOARD COMMAND PORT
;__________________________________________________________________________________________________
;
KBD_CMDOUT:
	LD	C,(IY+KBD_CMD)		; COMMAND PORT
	EZ80_IO
	OUT	(C),A	
	RET
;__________________________________________________________________________________________________
; OUTPUT TO KEYBOARD COMMAND DATA
;__________________________________________________________________________________________________
;
KBD_DTAOUT:
	LD	C,(IY+KBD_DAT)		; DATA PORT
	EZ80_IO
	OUT	(C),A
	RET
;__________________________________________________________________________________________________
; KEYBOARD OUTPUT STATUS - A=0, Z SET FOR NOT READY, OTHERWISE READY TO WRITE
;__________________________________________________________________________________________________
;
KBD_OST:
	LD	C,(IY+KBD_ST)		; STATUS PORT
	EZ80_IO
	IN	A,(C)			; GET STATUS
	AND	$02			; ISOLATE OUTPUT EMPTY BIT
	XOR	$02			; FLIP IT FOR APPROPRIATE RETURN VALUES
	RET
;
;__________________________________________________________________________________________________
; DEBUG QUEUE
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & KBDINTS & 0)
KBDQDBG:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF

	CALL	NEWLINE			; PRINT QUEUE CONTENTS
	LD	B,KBDQSIZ		; +2 PRE AND POST GUARD BYTES
	LD	HL,KBDQ			; -1 PRE AND POST GUARD BYTES
KBDQPRT:
	LD	A,(HL)
	CALL	PRTHEXBYTE
	INC	HL
	DJNZ	KBDQPRT

	LD	A,' '			; PRINT QUEUE INDEX
	CALL	COUT
	LD	A,(KBDQGETX)
	AND	KBDQSIZ-1
	CALL	PRTHEXBYTE

	LD	A,' '			; PRINT QUEUE INDEX
	CALL	COUT
	LD	A,(KBDQPUTX)
	AND	KBDQSIZ-1
	CALL	PRTHEXBYTE

	LD	A,' '			; PRINT # SCAN CODES IN QUEUE
	CALL	COUT
	CALL	KBDQLEN
	CALL	PRTHEXBYTE
	CALL	NEWLINE

	POP	AF
	POP	BC
	POP	DE
	POP	HL
	RET
#ENDIF
