;======================================================================
;
;	AY-3-8910 / YM2149 SOUND DRIVER
;
;======================================================================
;
#IF (AYMODE == AYMODE_SCG)
AY_RSEL		.EQU	$9A
AY_RDAT		.EQU	$9B
AY_ACR		.EQU	$9C
#ENDIF
;
#IF (AYMODE == AYMODE_N8)
AY_RSEL		.EQU	$9C
AY_RDAT		.EQU	$9D
AY_ACR		.EQU	N8_DEFACR
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ80)
AY_RSEL		.EQU	$D8
AY_RDAT		.EQU	$D0
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ180)
AY_RSEL		.EQU	$68
AY_RDAT		.EQU	$60
#ENDIF
;
;======================================================================
;
;	REGISTERS
;
AY_R2CHBP	.EQU	$02
AY_R3CHBP	.EQU	$03
AY_R7ENAB	.EQU	$07
AY_R8AVOL	.EQU	$08
;
;======================================================================
;
;	DRIVER FUNCTION TABLE AND INSTANCE DATA
;
AY_FNTBL:
	.DW	AY_RESET
	.DW	AY_VOLUME
	.DW	AY_PERIOD
	.DW	AY_NOTE
	.DW	AY_PLAY
	.DW	AY_QUERY

#IF (($ - AY_FNTBL) != (SND_FNCNT * 2))
	.ECHO	"*** INVALID SND FUNCTION TABLE ***\n"
	!!!!!
#ENDIF
;
AY_IDAT	.EQU	0			; NO INSTANCE DATA ASSOCIATED WITH THIS DEVICE
;
;======================================================================
;
;	DEVICE CAPABILITIES AND CONFIGURATION
;
SBCV2004	.EQU	1		; USE SBC-V2-004 HALF CLOCK DIVIDER	
;
AY_TONECNT	.EQU	3		; COUNT NUMBER OF TONE CHANNELS
AY_NOISECNT	.EQU	1		; COUNT NUMBER OF NOISE CHANNELS
;
AY_PHICLK	.EQU	3579500
AY_CLKDIV	.EQU	2
AY_CLK		.EQU	AY_PHICLK / AY_CLKDIV
;
#INCLUDE "audio.inc"
;
;======================================================================
;
;	DRIVER INITIALIZATION (THERE IS NO PRE-INITIALIZATION)
;
;	ANNOUNCE DEVICE ON CONSOLE. ACTIVATE DEVICE IF REQUIRED.
;	SETUP FUNCTION TABLES. SETUP THE DEVICE.
;	ANNOUNCE DEVICE WITH BEEP. SET VOLUME OFF.
;	RETURN INITIALIZATION STATUS
;
AY38910_INIT:
	CALL	NEWLINE			; ANNOUNCE
	PRTS("AY: IO=0x$")
	LD	A,AY_RSEL
	CALL	PRTHEXBYTE
;
#IF ((AYMODE == AYMODE_SCG) | (AYMODE == AYMODE_N8))
					; ACTIVATE DEVICE
	LD	A,$FF			; BIT 4 IS AY RESET CONTROL, BIT 3 IS ACTIVE LED
	OUT	(AY_ACR),A		; SET INIT AUX CONTROL REG
#ENDIF
;
	LD	IY, AY_IDAT		; SETUP FUNCTION TABLE
	LD	BC, AY_FNTBL		; POINTER TO INSTANCE DATA
	LD	DE, AY_IDAT		; BC := FUNCTION TABLE ADDRESS
	CALL	SND_ADDENT		; DE := INSTANCE DATA PTR
;
	CALL	AY_INIT			; SET DEFAULT CHIP CONFIGURATION
;
	LD	E,$07			; SET VOLUME TO 50%
	CALL	AY_SETV			; ON ALL CHANNELS
;
	LD	D,AY_R2CHBP		; BEEP ON CHANNEL B (CENTER)
	LD	E,$55
	CALL	AY_WRTPSG		; R02 = $55 = 01010101
	LD	D,AY_R3CHBP
	LD	E,$00
	CALL	AY_WRTPSG		; R03 = $00 = XXXX0000
;  
	CALL	LDELAY			; HALF SECOND 
;
	LD	E,$00			; SET VOLUME OFF
	CALL	AY_SETV			; ON ALL CHANNELS	
;
;	RET
;
;======================================================================
;	INITIALIZE DEVICE
;======================================================================
;
AY_INIT:
	LD	D,AY_R7ENAB		; SET MIXER CONTROL / IO ENABLE
	LD	E,$F8			; $F8 - 11 111 000
	CALL	AY_WRTPSG		; I/O PORTS = OUTPUT, NOISE CHANNEL C, B, A DISABLE, TONE CHANNEL C, B, A ENABLE
	RET
;
;======================================================================
;	SET VOLUME ALL CHANNELS
;======================================================================
;
AY_SETV:
	LD	B,AY_TONECNT		; NUMBER OF CHANNELS		
	LD	D,AY_R8AVOL		; BASE REGISTER FOR VOLUME
AY_SV:	CALL	AY_WRTPSG		; CYCLING THROUGH ALL CHANNELS
	INC	D
	DJNZ	AY_SV
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - RESET
;
;	INITIALIZE DEVICE. SET VOLUME OFF. RESET VOLUME AND TONE VARIABLES.
;
;======================================================================
;
AY_RESET:
	AUDTRACE(TRACE_INIT)
;
	CALL	AY_INIT			; SET DEFAULT CHIP CONFIGURATION
;
	AUDTRACE(TRACE_VOLUME_OFF)
	LD	E,0			; SET VOLUME OFF
	CALL	AY_SETV			; ON ALL CHANNELS
;
	XOR	A			; SIGNAL SUCCESS
	LD	(PENDING_VOLUME),A	; SET VOLUME TO ZERO
	LD	H,A
	LD	L,A
	LD	(PENDING_PERIOD),HL	; SET TONE PERIOD TO ZERO
;	
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - VOLUME
;======================================================================
;
AY_VOLUME:
	AUDDEBUG("AY3VOL ")
	AUDTRACE_L
	AUDDEBUG("\r\n")
	LD	A,L			; SAVE VOLUME
	LD	(PENDING_VOLUME), A
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - PERIOD
;======================================================================
;
AY_PERIOD:
	AUDDEBUG("AY3PRD ")
	AUDTRACE_HL
	AUDDEBUG("\r\n")

	LD	A, H			; MAXIMUM TONE PERIOD IS 12-BITS
	CP	$10			; ALLOWED RANGE IS 0001-0FFF (4095)
	JP	NC, AY_QUERY_PERIOD1	; RETURN NZ IF NUMBER TOO LARGE

	LD	(PENDING_PERIOD), HL	; SAVE AND 
	XOR	A			; SIGNAL SUCCESS
	RET

AY_QUERY_PERIOD1:
	LD	L, $FF
	LD	H, L			; REQUESTED PERIOD IS LARGER 
	LD	(PENDING_PERIOD), HL	; THAN THE DEVICE CAN SUPPORT
	OR	L			; SO SIGNAL FAILURE
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - NOTE
;======================================================================
;
AY_NOTE:
	AUDDEBUG("AY3NOT ")
	AUDTRACE_L
	AUDDEBUG("\r\n")

	ADD	HL, HL			; SHIFT RIGHT (MULT 2) -INDEX INTO AY3NOTETBL TABLE OF WORDS
					; TEST IF HL IS LARGER THAN AY3NOTETBL SIZE
	OR	A			; CLEAR CARRY FLAG
	LD	DE, SIZ_AY3NOTETBL
	SBC	HL, DE
	JR	NC, AY_NOTE1		; INCOMING HL DOES NOT MAP INTO AY3NOTETBL

	ADD	HL, DE			; RESTORE HL
	LD	E, L			; HL = AY3NOTETBL + HL
	LD	D, H
	LD	HL, AY3NOTETBL
	ADD	HL, DE

	LD	A, (HL)			; RETRIEVE PERIOD COUNT FROM AY3NOTETBL
	INC	HL
	LD	H, (HL)
	LD	L, A

	JR	AY_PERIOD		; APPLY NOTE PERIOD

AY_NOTE1:
	OR	$FF			; NOT IMPLEMENTED YET
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - PLAY
;======================================================================
;
AY_PLAY:
	AUDDEBUG("AY3PLY ")
	AUDTRACE_D
	AUDDEBUG("\r\n")
;
	LD	A, (PENDING_PERIOD + 1)	; CHECK THE HIGH BYTE OF THE PERIOD
	CP	$FF
	JR	Z, AY_PLAY1		; PERIOD IS TOO LARGE, UNABLE TO PLAY
	CALL	AY_APPLY_VOL
	CALL	AY_APPLY_PRD
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
AY_PLAY1:				; TURN CHANNEL VOL TO OFF AND STOP PLAYING
	LD	A, (PENDING_VOLUME)
	PUSH	AF
	XOR	A
	LD	(PENDING_VOLUME), A
	CALL	AY_APPLY_VOL
	POP	AF
	LD	(PENDING_VOLUME), A
;
	OR	$FF			; SIGNAL FAILURE
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - QUERY AND SUBFUNCTIONS
;======================================================================
;
AY_QUERY:
	LD	A, E
	CP	BF_SNDQ_CHCNT		; SUB FUNCTION 01
	JR	Z, AY_QUERY_CHCNT
;
	CP	BF_SNDQ_VOLUME		; SUB FUNCTION 02
	JR	Z, AY_QUERY_VOLUME
;
	CP	BF_SNDQ_PERIOD		; SUB FUNCTION 03
	JR	Z, AY_QUERY_PERIOD
;
	CP	BF_SNDQ_DEV		; SUB FUNCTION 04
	JR	Z, AY_QUERY_DEV
;
	OR	$FF			; SIGNAL FAILURE
	RET
;
AY_QUERY_CHCNT:
	LD	B, AY_TONECNT		; RETURN NUMBER OF
	LD	C, AY_NOISECNT		; TONE AND NOISE 
	XOR	A			; CHANNELS IN BC
	RET
;
AY_QUERY_PERIOD:
	LD	HL, (PENDING_PERIOD)	; RETURN 16-BIT PERIOD
	XOR	A			; IN HL REGISTER
	RET
;
AY_QUERY_VOLUME:
	LD	A, (PENDING_VOLUME)	; RETURN 8-BIT VOLUME
	LD	L, A			; IN L REGISTER
	XOR	A
	LD	H, A
	RET
;
AY_QUERY_DEV:
	LD	B, BF_SND_AY38910		; RETURN DEVICE IDENTIFIER
	LD	DE, (AY_RSEL*256)+AY_RDAT	; AND ADDRESS AND DATA PORT
	XOR	A
	RET
;
;======================================================================
;	APPLY VOLUME TO CHANNEL IN D REGISTER
;======================================================================
;
AY_APPLY_VOL:
	PUSH	DE
	PUSH	BC
	PUSH	AF
;
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,AY_R8AVOL		; CHANNEL VOLUME
	LD	D,A			; REGISTER
;
	AUDTRACE(TRACE_REG_WR)
	AUDTRACE_A
	AUDTRACE(TRACE_NEWLINE)
;
	LD	A, (PENDING_VOLUME)	; MAP THE VOLUME
	RRCA				; FROM 00-FF
	RRCA				; TO 00-0F
	RRCA
	RRCA
	AND	$0F
	LD	E,A
;
	CALL	AY_WRTPSG		; SET VOL (E) IN CHANNEL REG (D)
;
	POP	AF
	POP	BC
	POP	DE
	RET
;
;======================================================================
;	APPLY PERIOD TO CHANNEL IN D REGISTER
;======================================================================
;
AY_APPLY_PRD:
	PUSH	DE
	PUSH	BC
	PUSH	AF
;
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,A			; CHANNEL REGISTER
	LD	D,A			; FOR THE TONE PERIOD
;
	AUDTRACE(TRACE_REG_WR)
	AUDTRACE_A
	AUDTRACE(TRACE_NEWLINE)
;
	LD	HL,(PENDING_PERIOD)	; WRITE THE LOWER
	LD	E,L			; 8-BITS OF THE TONE PERIOD
	CALL	AY_WRTPSG
	INC	D
	LD	E,H			; WRITE THE UPPER
	CALL	AY_WRTPSG       	; 8-BITS OF THE TONE PERIOD
;
	POP	AF
	POP	BC
	POP	DE
	RET
;
;======================================================================
;	
; 	WRITE DATA IN E REGISTER TO DEVICE REGISTER D
;	INTERRUPTS DISABLE DURING WRITE. WRITE IN SLOW MODE IF Z180 CPU.
; 
;======================================================================
;
AY_WRTPSG:
	HB_DI
#IF (SBCV2004)
	LD	A,8			; SBC-V2-004 CHANGE
	OUT	(112),A			; TO HALF CLOCK SPEED
#ENDIF
#IF (CPUFAM == CPU_Z180)
	IN0	A,(Z180_DCNTL)		; GET WAIT STATES
	PUSH	AF			; SAVE VALUE
	OR	%00110000		; FORCE SLOW OPERATION (I/O W/S=3)
	OUT0	(Z180_DCNTL),A		; AND UPDATE DCNTL
#ENDIF
	LD	A,D			; SELECT THE REGISTER WE 
	OUT	(AY_RSEL),A		; WANT TO WRITE TO
	LD	A,E			; WRITE THE VALUE TO
	OUT	(AY_RDAT),A		; THE SELECTED REGISTER
#IF (CPUFAM == CPU_Z180)
	POP	AF			; GET SAVED DCNTL VALUE
	OUT0	(Z180_DCNTL),A		; AND RESTORE IT
#ENDIF
#IF (SBCV2004)
	LD	A,0			; SBC-V2-004 CHANGE TO
	OUT	(112),A			; NORMAL CLOCK SPEED
#ENDIF
	HB_EI
	RET
;
;======================================================================
;
PENDING_PERIOD		.DW	0	; PENDING PERIOD (12 BITS)
PENDING_VOLUME		.DB	0	; PENDING VOL (8 BITS)

#IF AUDIOTRACE
TRACE_INIT		.DB	"\r\nAY_INIT CALLED\r\n$"
TRACE_VOLUME_OFF	.DB	"\r\nAY_VOLUME_OFF\r\n$"
TRACE_VOLUME_SET	.DB	"\r\nAY_VOLUME_SET CH: $"
TRACE_PLAY		.DB	"\r\nPLAY\r\n$"
TRACE_VOLUME		.DB	", VOL: $"
TRACE_REG_WR		.DB	"\r\nOUT AY-3-8910 $"
TRACE_PERIOD_SET	.DB	"\r\nAY_PERIOD_SET CH: $"
TRACE_PERIOD		.DB	", PERIOD: $"
TRACE_NEWLINE		.DB	"\r\n$"
#ENDIF
;
; THE FREQUENCY BY QUARTER TONE STARTING AT A1#
;
;======================================================================
;	FREQUENCY TONE TABLE
;======================================================================
;
;		PERIOD	OCTAVE	NOTE	MIDI#
;
AY3NOTETBL:
;	.DW	6842	;0		12
;	.DW	6458	;0		13
;	.DW	6096	;0		14
;	.DW	5751	;0		15
;	.DW	5430	;0		16
;	.DW	5124	;0		17
;	.DW	4838	;0		18
;	.DW	4566	;0		19
;	.DW	4309	;0		20
	.DW	4068	;0	A0	21
	.DW	3839	;0		22
	.DW	3624	;0		23
	.DW	3421	;1		24
	.DW	3228 	;1		25
	.DW	3047 	;1		26
	.DW	2876 	;1		27
	.DW	2715 	;1		28
	.DW	2563 	;1		29
	.DW	2419 	;1		30
	.DW	2283 	;1		31
	.DW	2155 	;1		32
	.DW	2034 	;1		33
	.DW	1920 	;1		34
	.DW	1812	;1		35
	.DW	1710	;2		36
	.DW	1614 	;2		37
	.DW	1524 	;2		38
	.DW	1438 	;2		39
	.DW	1357 	;2		40
	.DW	1281 	;2		41
	.DW	1209 	;2		42
	.DW	1141 	;2		43
	.DW	1077 	;2		44
	.DW	1017 	;2		45
	.DW	960  	;2		46
	.DW	906	;2		47
	.DW	855	;3		48
	.DW	807 	;3		49
	.DW	762 	;3		50
	.DW	719 	;3		51
	.DW	679 	;3		52
	.DW	641 	;3		53
	.DW	605 	;3		54
	.DW	571 	;3		55
	.DW	539 	;3		56
	.DW	508 	;3		57
	.DW	480 	;3		58
	.DW	453	;3		59
	.DW	428	;4		60
	.DW	404 	;4		61
	.DW	381 	;4		62
	.DW	360 	;4		63
	.DW	339 	;4		64
	.DW	320 	;4		65
	.DW	302 	;4		66
	.DW	285 	;4		67
	.DW	269 	;4		68
	.DW	254 	;4		69
	.DW	240 	;4		70
	.DW	226	;4		71
	.DW	214	;5		72
	.DW	202 	;5		73
	.DW	190 	;5		74
	.DW	180 	;5		75
	.DW	170 	;5		76
	.DW	160 	;5		77
	.DW	151 	;5		78
	.DW	143 	;5		79
	.DW	135 	;5		80
	.DW	127 	;5		81
	.DW	120 	;5		82
	.DW	113	;5		83
	.DW	107	;6		84
	.DW	101 	;6		85
	.DW	95  	;6		86
	.DW	90  	;6		87
	.DW	85  	;6		88
	.DW	80  	;6		89
	.DW	76  	;6		90
	.DW	71  	;6		91
	.DW	67  	;6		92
	.DW	64  	;6		93
	.DW	60  	;6		94
	.DW	57	;6		95
	.DW	53	;7		96
	.DW	50 	;7		97
	.DW	48 	;7		98
	.DW	45 	;7		99
	.DW	42 	;7		100
	.DW	40 	;7		101
	.DW	38 	;7		102
	.DW	36 	;7		103
	.DW	34 	;7		104
	.DW	32 	;7		105
	.DW	30 	;7		106
	.DW	28	;7		107
	.DW	27	;8		108
	.DW	25 	;8		109
	.DW	24 	;8		110
	.DW	22 	;8		111
	.DW	21 	;8		112
	.DW	20 	;8		113
	.DW	19 	;8		114
	.DW	18 	;8		115
	.DW	17 	;8		116
	.DW	16 	;8		117
	.DW	15 	;8		118
	.DW	14	;8		119
	.DW	13	;9		120
	.DW	13	;9		121
	.DW	12	;9		122
	.DW	11	;9		123
	.DW	11	;9		124
	.DW	10	;9		125
	.DW	9 	;9		126
	.DW	9 	;9		127
	.DW	8 	;9		128

SIZ_AY3NOTETBL	.EQU	$ - AY3NOTETBL
		.ECHO	"AY-3-8910 approx "
		.ECHO	SIZ_AY3NOTETBL / 2 / 12
		.ECHO	" Octaves.  Last note index supported: "

		.ECHO SIZ_AY3NOTETBL / 2
		.ECHO "\n"
