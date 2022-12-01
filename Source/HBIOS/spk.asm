;======================================================================
;
;	BIT MODE SOUND DRIVER FOR SBC V2 USING BIT 0 OF RTC DRIVER
;
;======================================================================
;
;	LIMITATIONS -	CPU FREQUENCY ADJUSTMENT LIMITED TO 1MHZ RESOLUTION
;			QUARTER TONES NOT SUPPORTED
;			DURATION FIXED TO 1 SECOND.
;			NO VOLUME ADJUSTMENT DUE TO HARDWARE LIMITATION
;======================================================================
;
;	DRIVER FUNCTION TABLE AND INSTANCE DATA
;
SP_FNTBL:
	.DW	SP_STUB			; SP_RESET
	.DW	SP_STUB			; SP_VOLUME
	.DW	SP_PERIOD
	.DW	SP_NOTE
	.DW	SP_PLAY
	.DW	SP_QUERY
	.DW	SP_DURATION
	.DW	SP_DEVICE
;
#IF (($ - SP_FNTBL) != (SND_FNCNT * 2))
	.ECHO	"*** INVALID SND FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
SP_IDAT	.EQU	0			; NO INSTANCE DATA ASSOCIATED WITH THIS DEVICE
;
SP_TONECNT	.EQU	1		; COUNT NUMBER OF TONE CHANNELS
SP_NOISECNT	.EQU	0		; COUNT NUMBER OF NOISE CHANNELS
;
SP_RTCIOMSK	.EQU	00000100B
;
; FOR OTHER DRIVERS, THE PERIOD VALUE FOR THE TONE IS STORED AT PENDING_PERIOD
; FOR THE SPK DRIVER THE ADDRESS IN THE TONE TABLE IS STORED IN PENDING_PERIOD
;
SP_PENDING_PERIOD	.DW	SP_NOTE_C8	; PENDING PERIOD (16 BITS)
SP_PENDING_VOLUME	.DB	$FF		; PENDING VOL (8 BITS)
SP_PENDING_DURATION	.DW	0		; PENDING DURATION (16 BITS)
;
;======================================================================
;	DRIVER INITIALIZATION
;======================================================================
;
SP_INIT:
	LD	IY, SP_IDAT		; SETUP FUNCTION TABLE
	LD	BC, SP_FNTBL		; POINTER TO INSTANCE DATA
	LD	DE, SP_IDAT		; BC := FUNCTION TABLE ADDRESS
	CALL	SND_ADDENT		; DE := INSTANCE DATA PTR
;
	CALL	NEWLINE			; ANNOUNCE DEVICE
	PRTS("SPK: IO=0x$")
	LD	A,RTCIO
	CALL	PRTHEXBYTE
	CALL	SP_SETTBL		; SETUP TONE TABLE
	CALL	SP_PLAY			; PLAY DEFAULT NOTE
	XOR	A
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - RESET
;======================================================================
;
;SP_RESET:
;	XOR	A			; SUCCESSFULL RESET
;	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - VOLUME
;======================================================================
;
;SP_VOLUME:
;	XOR	A			; SIGNAL SUCCESS
;	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - PERIOD
;======================================================================
;
SP_PERIOD:
	LD	(SP_PENDING_PERIOD), HL	; SAVE AND RETURN SUCCESSFUL
SP_STUB:
	XOR	A
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - NOTE
;======================================================================
;
SP_NOTE:
;	CALL	PRTHEXWORDHL
;	CALL	PC_COLON
	PUSH	HL
	PUSH	DE			; ON ENTRY HL IS A NOTE INDEX
	LD	A,L			; CONVERT THIS NOTE INDEX
	AND	00000011B		; TO THE ASSOCIATED ENTRY
	JR	Z,SP_NOTE1		; IN THE TUNE TABLE.
;
	LD	HL,$FFFF		; QUARTER NOTES
	JR	SP_NOTE2		; NOT SUPPORTED
;
SP_NOTE1:
	LD	DE,SP_TUNTBL		; SAVE THIS ADDRESS AS
	ADD	HL,DE			; THE PERIOD
SP_NOTE2:
;	CALL	PRTHEXWORDHL
;	CALL	NEWLINE
	LD	(SP_PENDING_PERIOD),HL
	POP	DE
	POP	HL
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - QUERY AND SUBFUNCTIONS
;======================================================================
;
SP_QUERY:
	LD	A, E
	CP	BF_SNDQ_CHCNT		; SUB FUNCTION 01
	JR	Z, SP_QUERY_CHCNT
;
	CP	BF_SNDQ_VOLUME		; SUB FUNCTION 02
	JR	Z, SP_QUERY_VOLUME
;
	CP	BF_SNDQ_PERIOD		; SUB FUNCTION 03
	JR	Z, SP_QUERY_PERIOD
;
	CP	BF_SNDQ_DEV		; SUB FUNCTION 04
	JR	Z, SP_QUERY_DEV
;
	OR	$FF			; SIGNAL FAILURE
	RET
;
SP_QUERY_CHCNT:
	LD	BC,(SP_TONECNT*256)+SP_NOISECNT		; RETURN NUMBER OF
	XOR	A					; TONE AND NOISE
	RET						; CHANNELS IN BC
;
SP_QUERY_PERIOD:
	LD	HL, (SP_PENDING_PERIOD)	; RETURN 16-BIT PERIOD
	XOR	A			; IN HL REGISTER
	RET
;
SP_QUERY_VOLUME:
	LD	L, 255			; RETURN 8-BIT VOLUME
	XOR	A			; IN L REGISTER
	RET
;
SP_QUERY_DEV:
	LD	B, SNDDEV_BITMODE		; RETURN DEVICE IDENTIFIER
	LD	DE, (RTCIO*256)+SP_RTCIOMSK	; AND ADDRESS AND DATA PORT
	XOR	A
	RET
;
;======================================================================
;	INITIALIZE THE TONE TABLE - ONLY ACCURATE FOR 1MHZ INCREMENTS
;======================================================================
;
SP_SETTBL:
	LD	BC,(CB_CPUMHZ)		; GET MHZ CPU SPEED (IN C).
;	 
SP_SETTBL3:
	LD	B,SP_NOTCNT		; SET NUMBER OF NOTES TO
	LD	HL,SP_TUNTBL+2		; ADJUST AND START POINT
;
SP_SETTBL2:
	PUSH	HL
	LD	E,(HL)			; READ IN
	INC	HL			; THE 1MHZ 
	LD	D,(HL)			; NOTE
;
	PUSH	BC
	LD	B,C
	LD	HL,0			; MULTIPLY 1MHZ
SP_SETTBL1:				; NOTE VALUE BY
	ADD	HL,DE			; SYSTEM MHZ
	JR	NC,SP_SETBL4
	LD	HL,$FFFF		; FOR CPU > 10MHz
	LD	B,1			; HANDLE OVERFLOW 
SP_SETBL4:
	DJNZ	SP_SETTBL1
	POP	BC
;
	LD	DE,15			; ADD OVERHEAD
	ADD	HL,DE			; COMPENSATION
;
	POP	DE			; RECALL NOTE
	EX	DE,HL			; ADDRESS
;
	LD	(HL),E			; SAVE 		
	INC	HL			; THE
	LD	(HL),D			; NEW
	INC	HL			; NOTE
	INC	HL			; AND MOVE
	INC	HL			; TO NEXT
;
	DJNZ	SP_SETTBL2		; NEXT NOTE
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - PLAY
;======================================================================
;
SP_PLAY:
	LD	HL,(SP_PENDING_PERIOD)	; SELECT NOTE
;
	LD	A,$FF			; EXIT WITH ERROR 
	CP	H			; STATUS IF INVALID 
	JR	NZ,SP_PLAY1		; PERIOD ($FFFF)
	CP	L
	RET	Z

SP_PLAY1:
	LD	E,(HL)			; LOAD 1ST ARG
	INC	HL			; IN DE
	LD	D,(HL)
	INC	HL
;
	LD	C,(HL)			; LOAD 2ND ARG
	INC	HL			; IN BC
	LD	B,(HL)
	INC	HL
;
;	LD	A,$FF			; EXIT WITH ERROR 
	CP	B			; STATUS IF INVALID 
	JR	NZ,SP_PLAY2		; NOTE ($FFFF)
	CP	C
	RET	Z
;
SP_PLAY2:
	PUSH	BC			; SETUP ARG IN HL
	POP	HL
;
;	CALL	SP_BEEPER		; PLAY 
;
;	RET
;
;	The following SP_BEEPER routine is a modification of code from 
;	"The Complete SPECTRUM ROM DISSASSEMBLY" by Dr Ian Logan & Dr Frank O’Hara
;
;	https://www.esocop.org/docs/CompleteSpectrumROMDisassemblyThe.pdf
;
;	DE 	Number of passes to make through the sound generation loop
;	HL 	Loop delay parameter
;
SP_BEEPER:
	PUSH	IX
	HB_DI 				; Disable the interrupt for the duration of a 'beep'.
	LD	A,L 			; Save L temporarily.
	SRL	L 			; Each '1' in the L register is to count 4 T states, but take INT (L/4) and count 16 T states instead.
	SRL	L
	CPL 				; Go back to the original value in L and find how many were lost by taking 3-(A mod 4).
	AND	$03
	LD	C,A
	LD	B,$00
	LD	IX,SPK_DLYADJ 		; The base address of the timing loop.
	ADD	IX,BC			; Alter the length of the timing loop. Use an earlier starting point for each '1' lost by taking INT (L/4).
	LD	A,(HB_RTCVAL)		; Fetch the present border colour from BORDCR and move it to bits 2, 1 and 0 of the A register.
;
;	The HL register holds the 'length of the timing loop' with 16 T states being used for each '1' in the L register and 1024 T states for each '1' in the H register.
;
SPK_DLYADJ:
	NOP 				; Add 4 T states for each earlier entry point that is used.
	NOP
	NOP
	INC	B 			; The values in the B and C registers will come from the H and L registers - see below.
	INC	C
BE_H_L_LP:
	DEC	C			; The 'timing loop', i.e. BC*4 T states. (But note that at the half-cycle point, C will be equal to L+1.)
	JR	NZ,BE_H_L_LP
	LD	C,$3F
	DEC	B
	JP	NZ,BE_H_L_LP
;
;	The loudspeaker is now alternately activated and deactivated.
;
	XOR	SP_RTCIOMSK		; Flip bit 2.
	OUT	(RTCIO),A		; Perform the 'OUT' operation, leaving other bits unchanged.
	LD	B,H			; Reset the B register.
	LD	C,A			; Save the A register.
	BIT	4,A 			; Jump if at the half-cycle point.
	JR	NZ,BE_AGAIN
;
;	After a full cycle the DE register pair is tested.
;
	LD	A,D			; Jump forward if the last complete pass has been made already.
	OR	E
	JR	Z,BE_END
	LD	A,C			; Fetch the saved value.
	LD	C,L			; Reset the C register.
	DEC	DE			; Decrease the pass counter.
	JP	(IX)			; Jump back to the required starting location of the loop.
;
;	The parameters for the second half-cycle are set up.
;	
BE_AGAIN:
	LD	C,L			; Reset the C register.
	INC	C 			; Add 16 T states as this path is shorter.
	JP	(IX)			; Jump back.
BE_END:
	HB_EI
	POP	IX
	RET				; ALWAYS EXITS WITH SUCCESS STATUS (A=0)
;
;======================================================================
;	SOUND DRIVER FUNCTION - DURATION
;======================================================================
;
SP_DURATION:
	LD	(SP_PENDING_DURATION),HL; SET TONE PERIOD TO ZERO
	XOR	A
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - DEVICE
;======================================================================
;
SP_DEVICE:
	LD	D,SNDDEV_BITMODE	; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL UNIT
	LD	C,$00			; C := DEVICE TYPE
	LD	H,0			; H := 0, DRIVER HAS NO MODES
	LD	L,RTCIO			; L := BASE I/O ADDRESS
	XOR	A
	RET
;
;======================================================================
;
;	STANDARD ONE SECOND TONE TABLES AT 1MHZ.
;	FOR SP_BEEPER ROUTINE, FIRST WORD LOADED INTO DE, SECOND INTO HL
;
;======================================================================
;
#DEFINE	SP_TONESET(SP_FREQ) .DW SP_FREQ/100, 12500000/SP_FREQ
;
SP_TUNTBL:
	SP_TONESET(1635)		; C0
	SP_TONESET(1732)		;  C
	SP_TONESET(1835)		; D0
	SP_TONESET(1945)		;  D
	SP_TONESET(2060)		; E0
	SP_TONESET(2183)		; F0
	SP_TONESET(2312)		;  F
	SP_TONESET(2450)		; G0
	SP_TONESET(2596)		;  G
	SP_TONESET(2750)		; A0
	SP_TONESET(2914)		;  A
	SP_TONESET(3087)		; B0
	SP_TONESET(3270)		; C1
	SP_TONESET(3465)		;  C
	SP_TONESET(3671)		; D1
	SP_TONESET(3889)		;  D
	SP_TONESET(4120)		; E1
	SP_TONESET(4365)		; F1
	SP_TONESET(4625)		;  F
	SP_TONESET(4900)		; G1
	SP_TONESET(5191)		;  G
	SP_TONESET(5500)		; A1 
	SP_TONESET(5827)		;  A
	SP_TONESET(6174)		; B1
	SP_TONESET(6541)		; C2
	SP_TONESET(6930)		;  C
	SP_TONESET(7342)		; D2
	SP_TONESET(7778)		;  D
	SP_TONESET(8241)		; E2
	SP_TONESET(8731)		; F2
	SP_TONESET(9250)		;  F
	SP_TONESET(9800)		; G2
	SP_TONESET(10383)		;  G
	SP_TONESET(11000)		; A2
	SP_TONESET(11654)		;  A
	SP_TONESET(12347)		; B2
	SP_TONESET(13081)		; C3
	SP_TONESET(13859)		;  C
	SP_TONESET(14683)		; D3
	SP_TONESET(15556)		;  D
	SP_TONESET(16481)		; E3
	SP_TONESET(17461)		; F3
	SP_TONESET(18500)		;  F
	SP_TONESET(19600)		; G3
	SP_TONESET(20765)		;  G
	SP_TONESET(22000)		; A3
	SP_TONESET(23308)		;  A
	SP_TONESET(24694)		; B3
	SP_TONESET(26163)		; C4
	SP_TONESET(27718)		;  C
	SP_TONESET(29366)		; D4
	SP_TONESET(31113)		;  D
	SP_TONESET(32963)		; E4
	SP_TONESET(34923)		; F4
	SP_TONESET(36999)		;  F
	SP_TONESET(39200)		; G4
	SP_TONESET(41530)		;  G
	SP_TONESET(44000)		; A4
	SP_TONESET(46616)		;  A
	SP_TONESET(49388)		; B4
	SP_TONESET(52325)		; C5
	SP_TONESET(55437)		;  C
	SP_TONESET(58733)		; D5
	SP_TONESET(62225)		;  D
	SP_TONESET(65925)		; E5
	SP_TONESET(69846)		; F5
	SP_TONESET(73999)		;  F
	SP_TONESET(78399)		; G5
	SP_TONESET(83061)		;  G
	SP_TONESET(88000)		; A5
	SP_TONESET(93233)		;  A
	SP_TONESET(98777)		; B5
	SP_TONESET(104650)		; C6
	SP_TONESET(110873)		;  C
	SP_TONESET(117466)		; D6
	SP_TONESET(124451)		;  D
	SP_TONESET(131851)		; E6
	SP_TONESET(139691)		; F6
	SP_TONESET(147998)		;  F
	SP_TONESET(156798)		; G6
	SP_TONESET(166122)		;  G
	SP_TONESET(179000)		; A6
	SP_TONESET(186466)		;  A
	SP_TONESET(197553)		; B6
	SP_TONESET(209300)		; C7
	SP_TONESET(221746)		;  C
	SP_TONESET(234932)		; D7
	SP_TONESET(248902)		;  D
	SP_TONESET(263702)		; E7
	SP_TONESET(279383)		; F7
	SP_TONESET(295996)		;  F
	SP_TONESET(313596)		; G7
	SP_TONESET(332244)		;  G
	SP_TONESET(352000)		; A7
	SP_TONESET(372931)		;  A
	SP_TONESET(395107)		; B7
SP_NOTE_C8:
	SP_TONESET(418601)		; C8
	SP_TONESET(443492)		;  C
	SP_TONESET(469863)		; D8
	SP_TONESET(497803)		;  D
	SP_TONESET(527404)		; E8
	SP_TONESET(558765)		; F8
	SP_TONESET(591991)		;  F
	SP_TONESET(627193)		; G8
	SP_TONESET(664488)		;  G
	SP_TONESET(704000)		; A8
	SP_TONESET(745862)		;  A
	SP_TONESET(790213)		; B8 
;
SP_NOTCNT	.EQU	($-SP_TUNTBL) / 4
;
