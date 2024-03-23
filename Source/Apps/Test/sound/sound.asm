;
;=======================================================================
; RomWBW HBIOS Sound Device Test Tool (SOUND)
;=======================================================================
;
; Simple utility that can exercise a sound device in RomWBW.  It can
; play a single tone, sliding scale, or sliding volume.
;
; I'm not actually sure who wrote the original version of this, but I
; suspect it was Phil Summers.
;
; WBW 2024-03-21: Control test function by command line
;		  Add (T)one function
;
;=======================================================================
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
		LD	DE,TXT_BANNER
		CALL	PRTSTR
;
;------------------------------------------------------------------------------
; PARSE COMMAND LINE
;------------------------------------------------------------------------------
;
		LD	HL,FCB+1		; POINT TO FCB CHARS
		LD	B,8			; PARSE 8 CHARS
PARSE:
		PUSH	BC
		LD	A,(HL)			; GET NEXT CHAR
;
		; IF NUMBER, SET DEVICE ID
		CP	'0'
		JR	C,PARSE1		; IF < 0, SKIP
		CP	'9'+ 1
		JR	NC,PARSE1		; IF > 9, SKIP
		SUB	'0'			; MAKE BINARY
		LD	(DEVICE),A		; SAVE DEVICE NUM
		JR	PARSE2			; CONTINUE LOOP
PARSE1:
		; IF LETTER, SET RUN OPTION
		CP	'A'
		JR	C,PARSE2		; IF < A, SKIP
		CP	'Z'+ 1
		JR	NC,PARSE1		; IF > Z, SKIP
		LD	(OPTION),A		; SAVE RUN OPTION
		JR	PARSE2			; CONTINUE LOOP
;
PARSE2:	
		INC	HL			; BUMP PTR
		DJNZ	PARSE
;
		LD	A,(OPTION)		; GET OPTION
		CP	' '			; HAVE OPTION?
		JR	NZ,RUN			; IF SO, RUN
		LD	DE,TXT_USAGE		; ELSE GET USAGE
		CALL	PRTSTR			; AND DISPLAY IT
		JP	EXIT			; AND GET OUT
;
;------------------------------------------------------------------------------
; DISPLAY DEVICE AND NUMBER OF CHANNELS
;------------------------------------------------------------------------------
;
RUN:
		LD	DE,TXT_DEV		; DEVICE:
		CALL	PRTSTR
		LD	A,(DEVICE)
		CALL	PRTDECB
		LD	C,A			; GET DEVICE ID
		LD	A,':'
		CALL	PRTCHR
;
		LD	B,$55			; HBIOS SND QUERY
		LD	A,(DEVICE)
		LD	C,A
;
		PUSH	BC			; SAVE FUNC AND ID
		LD	E,4			; HBIOS SNDQ DEV
		RST	08
		LD	A,B
		;RRCA \ RRCA \ RRCA \ RRCA
		LD	DE,TXT_NAME
		CALL	PRTIDXDEA		; SHOW NAME
;
		LD	DE,TXT_CH
		CALL	PRTSTR
		POP	BC			; RESTORE FUNC AND ID
		LD	E,1			; HBIOS SNDQ_CHCNT
		RST	08
		LD	A,B			; NUMBER OF CHANNELS IS IN B
		LD	(CHANNELS),A		; SAVE IT
		CALL	PRTDECB			; PRINT IT
		CALL	CRLF
;
;------------------------------------------------------------------------------
; LOOP THROUGH EACH CHANNEL 
;------------------------------------------------------------------------------
;
		LD	A,(DEVICE)		; GET DEVICE
		LD	C,A			; INTO C
		PUSH	BC			; SAVE IT
		LD	B,$50			; RESET SND DEVICE
		RST	08			; DO IT
		POP	BC			; RECOVER DEVICE
		LD	B,$51			; SET VOLUME
		LD	L,$FF			; TO MAX
		RST	08			; DO IT
;
		LD	A,(CHANNELS)
		LD	B,A			; B IS LOOP COUNTER
		LD	C,0			; C IS CHANNEL INDEX
;
CH_LOOP:
		PUSH	BC			; SAVE LOOP CTL
		LD	A,C			; CHANNEL
		LD	(CHANNEL),A		; TO STORAGE
		CALL	CH_RUN			; DO CHANNEL
		PUSH	AF
		LD	A,(DEVICE)
		LD	C,A
		LD	B,50H			; RESET
		RST	08
		POP	AF
		POP	BC			; RECOVER LOOP CTL
		JR	NZ,EXIT			; HANDLE ERROR/ABORT
		INC	C			; NEXT CHANNEL
		DJNZ	CH_LOOP			; LOOP AS NEEDED
;
		LD	A,(DEVICE)		; GET DEVICE
		LD	C,A			; TO C
		LD	B,50H			; RESET DEVICE
		RST	08			; DO IT
		JR	EXIT			; DONE
;
CH_RUN:
		LD	A,(OPTION)		; RUN OPTION
		CP	'S'			; SCALES?
		JP	Z,TST_SCALES		; IF SO, DO SCALES
		CP	'V'			; VOLUME?
		JP	Z,TST_VOLUME		; IF SO, DO VOLUME
		CP	'T'			; TONE
		JP	Z,TST_TONE		; IF SO, DO TONE
		RET
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
TST_SCALES:	LD	A,(DEVICE)	; SETUP DEVICE FOR BELOW
		LD	C,A
;
		LD	HL,380		; START NOTE
		LD	(NOTE),HL	; Top of Octave 7 is 343

		LD	B,51H		; VOLUME HIGH
		LD	L,0FFH		; MAX
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
SKIP:
		PUSH	BC
		LD      C, 6		; CHECK FOR KEYPRESS
		LD      E,0FFH
		CALL    BDOS
		POP	BC
		OR      A		; SET RESULT
		RET	NZ		; RETURN IF ABORT

		LD	HL,(NOTE)
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
;
		XOR      A		; SET RESULT
		RET
;
FAILMSG:	PUSH	BC
		CALL	PRTSTR
		CALL	CRLF
		POP	BC
		RET
;
;------------------------------------------------------------------------------
; CONSTANT TONE ON ALL CHANNELS, SCALE VOLUME
;------------------------------------------------------------------------------
;
TST_VOLUME:
;	LD	HL,332+48		; TONE
	LD	HL,244			; ~1000 HZ
	LD	(NOTE),HL
;
	LD	DE,TXT_TSTCH		; DISPLAY CHANNEL
	CALL	PRTSTR
	LD	A,(CHANNEL)
	CALL	PRTDECB

	LD	A,(DEVICE)
	LD	C,A

	LD	B,50H		; RESET
	PUSH	BC
	RST	08
	POP	BC
;
NEXT1:
	LD	B,51H		; VOLUME
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

	PUSH	BC
	LD      C, 6			; KEYPRESS 
        LD      E, 0FFH
        CALL    BDOS
	POP	BC			; RECOVER LOOP CTRL
	OR	A			; KEY PRESSED?
	RET	NZ			; BAIL OUT IF SO
;
	LD	A,(VOLUME)
	DEC	A
	LD	(VOLUME),A
	JR	NZ,NEXT1
;
	CALL	CRLF
;
	RET
;
;------------------------------------------------------------------------------
; 1 KHZ TONE ON CHANNEL, PLAY TILL KEYPRESS
;------------------------------------------------------------------------------
;
TST_TONE:
	LD	HL,244			; ~1000 HZ
	LD	(NOTE),HL
;
	LD	DE,TXT_TSTCH		; DISPLAY CHANNEL
	CALL	PRTSTR
	LD	A,(CHANNEL)
	CALL	PRTDECB
;
	LD	A,(DEVICE)
	LD	C,A
;
	LD	B,50H		; RESET
	PUSH	BC
	RST	08
	POP	BC
;
	LD	B,51H		; VOLUME
	LD	A,$FF		; MAX
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
TST_TONE1:
;
	LD	B,54H		; PLAY
	LD	A,(CHANNEL)
	LD	D,A
	PUSH	BC
	RST	08
	POP	BC
;
	;CALL	DELAY
;
	PUSH	BC
	LD      C, 6			; KEYPRESS 
        LD      E, 0FFH
        CALL    BDOS
	OR	A			; KEY PRESSED?
	POP	BC
	JR	Z,TST_TONE1
	CALL	CRLF
	XOR	A
	RET				; RETURN ON KEYPRESS
;
;------------------------------------------------------------------------------
; LONG DELAY
;------------------------------------------------------------------------------
;
;DELAY:	LD	HL,-1
DELAY:	LD	HL,1000
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
TXT_BANNER	.DB	13,10,"RomWBW HBIOS Sound Tool v1.0, 21-Mar-2024",13,10,13,10,0
TXT_USAGE	.DB	"Usage:",13,10
		.DB	"SOUND <d><o>",13,10
		.DB	"",13,10
		.DB	"  <d> is number of sound device",13,10
		.DB	"  <o> is option to run:",13,10
		.DB	"      'T': play a 1 KHz tone on each channel until keypress",13,10
		.DB	"      'S': play a scale of notes on each channel",13,10
		.DB	"      'V': play a 1 KHz tone at all volumes on each channel",13,10
		.DB	"",13,10
		.DB	"Examples:",13,10
		.DB	"SOUND 1T    - play a tone on all channels of sound device unit #1",13,10
		.DB	"SOUND 0S    - play a scale on all channels of sound device unit #0",13,10,0
TXT_CH		.DB	"CHANNELS=",0
TXT_TSTCH	.DB	"CHANNEL: ",0
TXT_BAD_N	.DB	" BAD NOTE",0
TXT_BAD_P	.DB	" PLAY ERROR",0
TXT_NOTE	.DB	" NOTE: ",0
TXT_VOL		.DB	" VOLUME: ",0
TXT_DEV		.DB	"DEVICE: ",0
TXT_NAME	.DB	"SN76489 ",0
		.DB	"AY-3-8910 ",0
		.DB	"I/O PORT ",0
		.DB	"YM2612 ",0





MODE		.DB	0		; scales mode or volume mode
DEVICE		.DB	0
OPTION		.DB	' '		; run scales
NOTE		.DW	128
VOLUME		.DB	0
CHANNEL		.DB	0
CHANNELS	.DB	0
OLDSTACK        .DW     0		; original stack pointer
                .DS     40H		; space for stack
STACK					; top of stack
;
	.END
