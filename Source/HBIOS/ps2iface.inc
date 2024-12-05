;__________________________________________________________________________________________________
; HARDWARE INTERFACE FOR POLLED AND INTERRUPT DRIVEN PS2 KEYBOARD.
;
; IN POLLED MODE THE KEYBOARD DEVICE IS IDENTIFIED BY THE TABLE POINTED TO BY IY
; IN INTERRUPT MODE THE KEYBOARD DEVICE IS UNKNOWN SO PREDEFINED PORT VALUES ARE USED.
;
; REQUIRES INTERRUPT JUMPER TO BE SET
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & INTPS2KBD))

#IF (TMSENABLE)
KBDPORTD	.DB	TMS_KBDDATA	; KBD CTLR DATA PORT
KBDPORTS	.DB	TMS_KBDST	; KBD CTLR STATUS/CMD PORT	
#ELSE

#IF (GDCENABLE)
KBDPORTD	.DB	GDC_KBDDATA	; KBD CTLR DATA PORT
KBDPORTS	.DB	GDC_KBDST	; KBD CTLR STATUS/CMD PORT
#ELSE

#IF (CVDUENABLE)
KBDPORTD	.DB	CVDU_KBDDATA	; KBD CTLR DATA PORT
KBDPORTS	.DB	CVDU_KBDST	; KBD CTLR STATUS/CMD PORT
#ELSE

#IF (VRCENABLE)
KBDPORTD	.DB	VRC_KBDDATA	; KBD CTLR DATA PORT
KBDPORTS	.DB	VRC_KBDST	; KBD CTLR STATUS/CMD PORT
#ELSE

#IF (VGAENABLE)
KBDPORTD	.DB	VGA_KBDDATA	; KBD CTLR DATA PORT
KBDPORTS	.DB	VGA_KBDST	; KBD CTLR STATUS/CMD PORT
#ENDIF

#ENDIF
#ENDIF
#ENDIF
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD QUEUE FOR INTERRUPTS
;__________________________________________________________________________________________________
;
;
KBDQSIZ		.EQU	16		; MUST BE POWER OF TWO, <=128
KBDQGETX	.DB	0		; QUEUE INDEX
KBDQPUTX	.DB	0		; QUEUE INDEX
		.DB	$55		; GUARD BYTE FOR DEBUGGING
KBDQ		.FILL	KBDQSIZ,0	; CIRCULAR KEYBOARD BUFFER
		.DB	$AA		; GUARD BYTE FOR DEBUGGING

;__________________________________________________________________________________________________
; RESET THE QUEUE TO EMPTY
;__________________________________________________________________________________________________
;
KBDQINIT: 
	XOR	A
	LD	(KBDQGETX),A
	LD	(KBDQPUTX),A
	RET
;
;__________________________________________________________________________________________________
; KEYBOARD INTERRUPT VECTOR
;__________________________________________________________________________________________________
;
KBD_INT:
;	CALL	KBDQDBG
	LD	A,(KBDPORTS)		; READ CONTROLLER STATUS
	LD	C,A
	IN	A,(C)
	AND	1
	RET	Z
	LD	A,(KBDPORTD)		; GET THE RESPONSE
	LD	C,A
	IN	A,(C)
;	CALL	KBDQPUSH		; SAVE KEYBOARD SCAN CODE
;	RET
;
;__________________________________________________________________________________________________
; ADD A BYTE TO THE KEYBOARD QUEUE
;__________________________________________________________________________________________________
;
KBDQPUSH:				; ADD A SCAN CODE TO THE QUEUE
	PUSH	AF
	CALL	KBDQFULL
	JR	Z,KBDQISF		; EXIT IF THE QUEUE IS FULL
;
	LD	HL,KBDQPUTX	
	LD	A,(HL)			; CREATE QUEUE INDEX
	AND	KBDQSIZ-1
	INC	(HL)			; UPDATE INDEX
;
	LD	HL,KBDQ			; INDEX INTO THE QUEUE
	LD	B,0
	LD	C,A
	ADD	HL,BC
	POP	AF
	LD	(HL),A			; SAVE THE CHARACTER IN THE QUEUE
;	CALL	KBDQDBG
;
	RET
;
KBDQISF:POP	AF
	RET

KBDQFULL:				; RETURN Z IF QUEUE IS FULL
	CALL	KBDQLEN			; RETURN NZ IF STILL SPACE IN QUEUE
	SUB	KBDQSIZ
	RET
#ENDIF
;__________________________________________________________________________________________________
; KEYBOARD READ
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & INTPS2KBD))
;
; 	RETURN A BYTE TO FROM KEYBOARD QUEUE
;	NOTE THE QUEUE INDEX'S NEVER DECREASE IN SIZE.
;
KBD_IN:
KBDQPOP:
	CALL	KBDQLEN
	RET	Z			; EXIT IF THE QUEUE IS EMPTY
;
	LD	HL,KBDQGETX
	LD	A,(HL)			; CREATE QUEUE INDEX
	AND	KBDQSIZ-1
	INC	(HL)			; UPDATE INDEX
;
	LD	HL,KBDQ			; INDEX INTO THE QUEUE
	LD	B,0
	LD	C,A
	ADD	HL,BC
	LD	A,(HL)			; GET THE CHARACTER FROM THE QUEUE
;	LD	(HL),B			; DEBUG - CLEAN QUEUE
;
	RET
;
#ELSE
;
;	RETURN A BYTE FROM THE KEYBOARD PORT
;
KBD_IN:
	IN	A,(C)			; GET THE DATA VALUE
	LD	C,(IY+KBD_DAT)		; DATA PORT
	EZ80_IO
	IN	A,(C)			; GET THE DATA VALUE
	RET
#ENDIF
;
;__________________________________________________________________________________________________
; KEYBOARD INPUT STATUS
;__________________________________________________________________________________________________
;
#IF ((INTMODE == 2) & INTPS2KBD))
KBD_IST:
KBDQLEN:				; EXIT WITH NUMBER OF CHARACTERS IN QUEUE
	LD	A,(KBDQPUTX)		; Z STATUS AND ZERO IF NONE 
	LD	HL,KBDQGETX
	SUB	(HL)
	RET
#ELSE
KBD_IST:				; A=0, Z SET FOR NOTHING PENDING, OTHERWISE DATA PENDING
	LD	C,(IY+KBD_ST)		; STATUS PORT
	EZ80_IO
	IN	A,(C)			; GET STATUS
	AND	$01			; ISOLATE INPUT PENDING BIT
	RET
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
#IF ((INTMODE == 2) & INTPS2KBD & 0)
KBDQDBG:
	PUSH	HL
	PUSH	DE
	PUSH	BC
	PUSH	AF

	CALL	NEWLINE			; PRINT QUEUE CONTENTS WITH PRE AND POST GUARD BYTES
	LD	B,KBDQSIZ+2
	LD	HL,KBDQ-1
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
