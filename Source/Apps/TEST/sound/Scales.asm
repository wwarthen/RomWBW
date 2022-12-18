;
;------------------------------------------------------------------------------
; Play Scales using HBIOS
;------------------------------------------------------------------------------
;
FCB		.EQU	$5C			; Location of default FCB
BDOS		.EQU	$0005

STEP		.EQU	4			; NOTE STEP I.E. 1 SEMITONE

		.ORG	$0100
;
                LD      (OLDSTACK),SP		; save old stack pointer
                LD      SP,STACK		; set new stack pointer
;
		LD	A,(FCB+1)		; GET FIRST CHAR 
		CP	'/'			; IS IT INDICATING AN ARGUMENT
		LD	A,0			; ASSUME DEVICE 0
		JR	NZ,NO_ARG		; 
		LD	A,(FCB+2)		; GET NEXT CHARACTER
		SUB	'0'			; CALCULATE DEVICE #
		LD	(DEVICE),A		; 

NO_ARG:		LD	C,A			; GET & DISPLAY # CHANNELS
		LD	B,$55
		LD	E,1
		RST	08
		LD	A,B		
		CALL	PRTHEX
		call	CRLF

		LD	B,1
;
		CALL	TST_TONE
;		CALL	TST_VOL
;
EXIT:		LD      SP, (OLDSTACK)		; Exit to CP/M
		RST     00H
		DI
		HALT

;------------------------------------------------------------------------------
; FOR EACH CHANNEL PLAY SCALES FROM HIGHEST TO LOWEST. B = # CHANNELS
;------------------------------------------------------------------------------

TST_TONE:	LD	A,(DEVICE)	; C CONTAINS DEVICE
		LD	C,A		; THROUGH THIS LOOP
;
		PUSH	BC
		LD	B,50H		; RESET DEVICE
		RST	08
		POP	BC
;
		PUSH	BC
		LD	B,51H		; VOLUME HALF
		LD	L,80H
		RST	08
		POP	BC
;
		LD	A,B
TST_TONE_LP:	DEC	A
		LD	(CHANNEL),A	; SAVE CURRENT CHANNEL
		CALL	SCALES		; PLAY SCALE
		DJNZ	TST_TONE_LP
;
		PUSH	BC
		LD	B,50H		; RESET DEVICE
		RST	08
		POP	BC
;
		RET
;
;------------------------------------------------------------------------------
;
SCALES:		PUSH	BC		
		PUSH	AF

		LD	HL,380		; START NOTE
		LD	(NOTE),HL	; Top of Octave 7 is 343
;
NEXT0:		PUSH	BC
		LD	BC,(NOTE)
		CALL	PRTHEXWORD
		CALL	PRTDOT
		POP	BC
;
		LD	B,53H		; NOTE
		LD	HL,(NOTE)
		PUSH	BC
		RST	08
		POP	BC

		OR	A		; DID DRIVER FAIL
		JR	Z,NEXT4		; THIS NOTE ?

		LD	A,'n'
		CALL	FAILMSG
		JR	SKIP
;
NEXT4:		LD	B,57H		; DURATION
		LD	HL,1000
		PUSH	BC
		RST	08
		POP	BC

		LD	B,54H		; PLAY
		LD	A,(CHANNEL)
		LD	D,A
		PUSH	BC
		RST	08
		POP	BC
;
		OR	A		; DID DRIVER FAIL
		JR	Z,NEXT2		; THIS NOTE ?

		LD	A,'p'
		CALL	FAILMSG
		JR	SKIP
;
NEXT2:		CALL	DELAY
		CALL	CRLF
;
SKIP:		LD	HL,(NOTE)
		DEC	HL
		LD	(NOTE),HL

		INC	HL
		LD	A,H
		OR	L
		DEC	HL
		JR	NZ,NEXT0
;
		LD	B,51H		; VOLUME
		LD	L,00H
		PUSH	BC
		RST	08
		POP	BC
;
		LD	B,54H		; PLAY
		LD	A,(CHANNEL)
		LD	D,A
		PUSH	BC
		RST	08
		POP	BC

		PUSH	BC
		LD      C, 6		; check for keypress
		LD      E, 0FFH
		CALL    BDOS
		POP	BC
		OR      A
		JP	NZ,EXIT

		POP	AF
		POP	BC
;
		RET
;
FAILMSG:	PUSH	AF
		PUSH	BC		; YES SO DISPLAY
		CALL	PRTCHR
		CALL	CRLF
		POP	BC
		POP	AF
		RET
;
;------------------------------------------------------------------------------
;	CONSTANT TONE ON ALL CHANNELS, SCALE VOLUME
;------------------------------------------------------------------------------
TST_VOL:
	LD	HL,332+48		; TONE
	LD	(NOTE),HL
;
	LD	B,3
NEXTCH1	LD	A,B
	DEC	A
	LD	(CHANNEL),A
	PUSH	BC		; ACROSS
	CALL	TONE		; ALL

	LD      C, 6		; KEYPRESS 
        LD      E, 0FFH
        CALL    BDOS
	POP	BC		; CHANNELS

        OR      A
        JP	NZ,EXIT

	DJNZ	NEXTCH1

	RET

TONE:	LD	A,(DEVICE)
	LD	C,A

	LD	B,50H		; RESET
	PUSH	BC
	RST	08
	POP	BC
;
NEXT1:	LD	B,51H		; VOLUME
	LD	A,(VOLUME)
	LD	L,A
	PUSH	BC
	RST	08
	POP	BC
;
	LD	B,53H		; NOTE
	LD	HL,(NOTE)
	PUSH	BC
	RST	08
	POP	BC
;
	LD	B,54H		; PLAY
	LD	A,(CHANNEL)
	LD	D,A
	PUSH	BC
	RST	08
	POP	BC
;
	CALL	DELAY
;
	LD	A,(VOLUME)
	DEC	A
	LD	(VOLUME),A
	JR	NZ,NEXT1
;
	LD	B,51H		; VOLUME
	LD	L,00H
	PUSH	BC
	RST	08
	POP	BC
;
	LD	B,54H		; PLAY
	PUSH	BC
	LD	A,(CHANNEL)
	LD	D,A
	POP	BC
	RST	08
;
	RET
;;
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------

DELAY:	LD	HL,-1
DELAY1:	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,DELAY1
	RET
;
#INCLUDE "printing.inc"
;
BADFLAG		.DB	'*','$'
DEVICE		.DB	0
NOTE		.DW	128
VOLUME		.DB	0
CHANNEL		.DB	0
OLDSTACK        .DW     0		; original stack pointer
                .DS     40H		; space for stack
STACK					; top of stack
;
	.END

