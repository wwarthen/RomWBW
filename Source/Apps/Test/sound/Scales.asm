;
;------------------------------------------------------------------------------
; PLAY SCALES USING HBIOS
;------------------------------------------------------------------------------
;
FCB		.EQU	$5C			; Location of default FCB
BDOS		.EQU	$0005
;
		.ORG	$0100
;
                LD      (OLDSTACK),SP		; save old stack pointer
                LD      SP,STACK		; set new stack pointer
;
;------------------------------------------------------------------------------
; GET DEVICE # FROM COMMAND LINE
;------------------------------------------------------------------------------
;
		LD	A,(FCB+1)		; GET FIRST CHAR 
		SUB	' '
		JR	Z,NO_ARG
		SUB	'0'-' '
		JP	C,EXIT
;
;------------------------------------------------------------------------------
; DISPLAY DEVICE AND NUMBER OF CHANNELS
;------------------------------------------------------------------------------
;
NO_ARG:		LD	(DEVICE),A		; 	
		LD	DE,TXT_DEV		; DEVICE:
		CALL	PRTSTR
		CALL	PRTDECB
		LD	C,A			; GET DEVICE ID
		LD	A,':'
		CALL	PRTCHR
		LD	B,$55
		PUSH	BC
		LD	E,4
		RST	08
		LD	DE,TXT_NAME
		LD	A,B
		RRCA \ RRCA \ RRCA \ RRCA
		CALL	PRTIDXDEA		; SHOW NAME
		LD	DE,TXT_CH
		CALL	PRTSTR
;
		POP	BC			; GET & DISPLAY # CHANNELS
		LD	E,1
		RST	08
		LD	A,B		
		CALL	PRTDECB
		CALL	CRLF			; NUMBER OF CHANNELS IS IN B
;
;------------------------------------------------------------------------------
; LOOP THROUGH EACH CHANNEL 
;------------------------------------------------------------------------------

CH__TONE:	LD	A,(DEVICE)	; C CONTAINS DEVICE
		LD	C,A		; THROUGH THIS LOOP
;
		PUSH	BC
		LD	B,50H		; RESET DEVICE
		RST	08
		POP	BC
;
		PUSH	BC
		LD	B,51H		; VOLUME FULL
		LD	L,0FFH
		RST	08
		POP	BC
;
		LD	A,B
TST_TONE_LP:	DEC	A
		LD	(CHANNEL),A	; SAVE CURRENT CHANNEL
		CALL	TST_SCALES	; SCALES TEST
;		CALL	TST_VOLUME	; VOLUME TEST
		CALL	CRLF
		DJNZ	TST_TONE_LP
;
		PUSH	BC
		LD	B,50H		; RESET DEVICE
		RST	08
		POP	BC
;
;------------------------------------------------------------------------------
; RESTORE STACK & EXIT
;------------------------------------------------------------------------------
;
EXIT:		LD      SP, (OLDSTACK)		; Exit to CP/M
		RST     00H
		DI
		HALT
;
;------------------------------------------------------------------------------
; PLAY SCALES FROM HIGHEST HBIOS NOTE TO LOWEST
;------------------------------------------------------------------------------
;
TST_SCALES:	PUSH	BC		
		PUSH	AF
;
		LD	HL,380		; START NOTE
		LD	(NOTE),HL	; Top of Octave 7 is 343

		LD	B,51H		; VOLUME HIGH
		LD	L,0FFH
		PUSH	BC
		RST	08
		POP	BC
;
NEXT0:		PUSH	BC
;
		LD	DE,TXT_TSTCH	; DISPLAY CHANNEL 
		CALL	PRTSTR
		LD	A,(CHANNEL)
		CALL	PRTDECB
;
		LD	DE,TXT_NOTE	; DISPLAY NOTE
		CALL	PRTSTR
		LD	HL,(NOTE)
		CALL	PRTDECW
		POP	BC
;
		LD	B,53H		; SET NOTE
		LD	HL,(NOTE)
		PUSH	BC
		RST	08
		POP	BC

		OR	A		; DID DRIVER FAIL
		JR	Z,NEXT4		; THIS NOTE ?

		LD	DE,TXT_BAD_N
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
		JR	Z,NEXT2		; TO PLAY ?

		LD	DE,TXT_BAD_N
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
		LD	L,00H		; OFF
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
		LD      E,0FFH
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
		PUSH	BC
		CALL	PRTSTR
		CALL	CRLF
		POP	BC
		POP	AF
		RET
;
;------------------------------------------------------------------------------
; CONSTANT TONE ON ALL CHANNELS, SCALE VOLUME
;------------------------------------------------------------------------------
;
TST_VOLUME:
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
; LONG DELAY
;------------------------------------------------------------------------------
;
DELAY:	LD	HL,-1
DELAY1:	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,DELAY1
	RET
;
;------------------------------------------------------------------------------
; PRINT THE nTH STRING IN A LIST OF STRINGS WHERE EACH IS TERMINATED BY 0
; A REGISTER DEFINES THE nTH STRING IN THE LIST TO PRINT AND DE POINTS
; TO THE START OF THE STRING LIST.
;------------------------------------------------------------------------------
;
PRTIDXDEA:	LD	C,A
		OR	A
PRTIDXDEA1:	JR	Z,PRTIDXDEA3		; FOUND TARGET SO EXIT 
PRTIDXDEA2:	LD	A,(DE)			; LOOP UNIT
		INC	DE			; WE REACH
		OR	A			; END OF STRING
		JR	NZ,PRTIDXDEA2
		DEC	C			; AT STRING END. SO GO
		JR	PRTIDXDEA1		; CHECK FOR INDEX MATCH
PRTIDXDEA3:	CALL	PRTSTR			; DISPLAY THE STRING
		RET
;
#INCLUDE "printing.inc"
;
TXT_CH		.DB	"CHANNELS: ",0
TXT_TSTCH	.DB	"CHANNEL: ",0
TXT_BAD_N	.DB	" BAD NOTE",0
TXT_BAD_P	.DB	" PLAY ERROR",0
TXT_NOTE	.DB	" NOTE: ",0
TXT_DEV		.DB	"DEVICE: ",0
TXT_NAME	.DB	"SN76489 ",0
		.DB	"AY-3-8910 ",0
		.DB	"I/O PORT ",0
		.DB	"YM2612 ",0
MODE		.DB	0		; scales mode or volume mode
DEVICE		.DB	0
NOTE		.DW	128
VOLUME		.DB	0
CHANNEL		.DB	0
OLDSTACK        .DW     0		; original stack pointer
                .DS     40H		; space for stack
STACK					; top of stack
;
	.END
