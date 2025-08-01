;======================================================================
;
;	AY-3-8910 / YM2149 SOUND DRIVER
;
; UPDATED BY: DAN WERNER -- 2/11/2024 - DUODYNE SUPPORT
;======================================================================
;
; AY-3-8910 & YM2149 PSG CHIPS NEED AN INPUT CLOCK FREQUENCY OF
; NO MORE THAN 2 MHZ.  THE CLOSEST THING THERE IS TO A STANDARD
; IS THE MSX FREQ OF 1.7897725 MHZ.
;
; @1.7897725 OCTAVE RANGE IS 2 - 7 (Bb2/A#2 .. A7)
; @2.0000000 OCTAVE RANGE IS 2 - 7 (B2 .. A7)
;
; DIFFENCES BETWEEN AY-3-8910 AND YM2149
;  THE AY-3-8910 HAS 16 ENVELOPE LEVELS, YM2149 HAS 32.
;  THIS AFFECTS AUDIO OUTPUT ONLY. THERE IS NO PROGRAMMING IMPACT.
;  UNUSED BITS IN REGISTERS ARE READ AS ZERO ON AY-3-8910.
;  UNUSED BITS CAN BE READ BACK AND WRITTEN ON YM.
;  VOLTAGE LEVEL OUTPUT ON A AY-3-8910 IS LOW AND AROUND 2V ON YM2149.
;
; THERE ARE TWO VARIANTS OF AY-3-8910 SOUND CARDS THAT HAVE BEEN
; PRODUCED FOR THE RCBUS.  THE ONE PRODUCED BY ED BRINDLEY (EB) USES
; THE SAME PORT FOR REGISTER SELECT (RSEL) AND REGISTER IN (RIN).
; THE ONE PRODUCED BY MARTEN FELDTMANN (MF) USES THE PORT FOLLOWING
; REGISTER SELECT (RSEL) FOR THE REGISTER IN (RIN) PORT.  THE FOLLOWING
; EQUATE MUST BE SET CORRECTLY FOR THE HARDWARE BEING USED.  THIS
; HAS NOT BEEN MOVED TO A CONFIG VARIABLE BECAUSE THE MF MODULE IS
; RARELY ENCOUNTERED IN THE WILD.
;
AY_RCSND	.EQU	0		; 0 = EB MODULE, 1=MF MODULE
;
	DEVECHO	"AY38910: MODE="
;
#IF (AYMODE == AYMODE_SCG)
AY_RSEL		.EQU	$9A
AY_RDAT		.EQU	$9B
AY_RIN		.EQU	AY_RSEL
AY_ACR		.EQU	$9C
		DEVECHO	"SCG"
#ENDIF
;
#IF (AYMODE == AYMODE_N8)
AY_RSEL		.EQU	$9C
AY_RDAT		.EQU	$9D
AY_RIN		.EQU	AY_RSEL
AY_ACR		.EQU	N8_ACR
		DEVECHO	"N8"
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ80)
AY_RSEL		.EQU	$D8
AY_RDAT		.EQU	$D0
AY_RIN		.EQU	AY_RSEL+AY_RCSND
		DEVECHO	"RCZ80"
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ180)
AY_RSEL		.EQU	$68
AY_RDAT		.EQU	$60
AY_RIN		.EQU	AY_RSEL+AY_RCSND
		DEVECHO	"RCZ180"
#ENDIF
;
#IF (AYMODE == AYMODE_MSX)
AY_RSEL		.EQU	$A0
AY_RDAT		.EQU	$A1
AY_RIN		.EQU	$A2
		DEVECHO	"MSX"
#ENDIF
;
#IF (AYMODE == AYMODE_LINC)
AY_RSEL		.EQU	$33
AY_RDAT		.EQU	$32
AY_RIN		.EQU	$32
		DEVECHO	"LINC"
#ENDIF
;
#IF (AYMODE == AYMODE_MBC)
AY_RSEL		.EQU	$A0
AY_RDAT		.EQU	$A1
AY_RIN		.EQU	AY_RSEL
AY_ACR		.EQU	$A2
		DEVECHO	"MBC"
#ENDIF
;
#IF (AYMODE == AYMODE_DUO)
AY_RSEL		.EQU	$A4
AY_RDAT		.EQU	$A5
AY_RIN		.EQU	AY_RSEL
AY_ACR		.EQU	$A6
		DEVECHO	"DUO"
#ENDIF
;
#IF (AYMODE == AYMODE_NABU)
AY_RSEL		.EQU	$41
AY_RDAT		.EQU	$40
AY_RIN		.EQU	$40
		DEVECHO	"NABU"
#ENDIF
;
	DEVECHO	", IO="
	DEVECHO	AY_RSEL
	DEVECHO	", CLOCK="
	DEVECHO	AY_CLK
	DEVECHO	" HZ\n"
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
	.DW	AY_DURATION
	.DW	AY_DEVICE
	.DW	AY_BEEP
;
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
AY_TONECNT	.EQU	3		; COUNT NUMBER OF TONE CHANNELS
AY_NOISECNT	.EQU	1		; COUNT NUMBER OF NOISE CHANNELS
;;
;#IF (AY_CLK > 3579545)			; DEPENDING ON THE
;AY_SCALE	.EQU	2		; INPUT CLOCK FREQUENCY
;#ELSE					; PRESCALE THE TONE PERIOD
;AY_SCALE	.EQU	3		; DATA TO MAINTAIN MAXIMUM
;#ENDIF					; RANGE AND ACCURACY
;
#INCLUDE "audio.inc"
;
;======================================================================
;
;	DRIVER INITIALIZATION (THERE IS NO PRE-INITIALIZATION)
;
;	ANNOUNCE DEVICE ON CONSOLE. ACTIVATE DEVICE IF REQUIRED.
;	SETUP FUNCTION TABLES. SETUP THE DEVICE.
;	RETURN INITIALIZATION STATUS
;
AY38910_INIT:
	CALL	NEWLINE			; ANNOUNCE
	PRTS("AY:$")
;
#IF (AYMODE == AYMODE_SCG)
	PRTS(" MODE=SCG$")
#ENDIF
;
#IF (AYMODE == AYMODE_N8)
	PRTS(" MODE=N8$")
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ80)
	PRTS(" MODE=RCZ80$")
#ENDIF
;
#IF (AYMODE == AYMODE_RCZ180)
	PRTS(" MODE=RCZ180$")
#ENDIF
;
#IF (AYMODE == AYMODE_MSX)
	PRTS(" MODE=MSX$")
#ENDIF
;
#IF (AYMODE == AYMODE_MBC)
	PRTS(" MODE=MBC$")
#ENDIF
;
#IF (AYMODE == AYMODE_DUO)
	PRTS(" MODE=DUO$")
#ENDIF
;
#IF (AYMODE == AYMODE_LINC)
	PRTS(" MODE=LINC$")
#ENDIF
;
	PRTS(" IO=0x$")
	LD	A,AY_RSEL
	CALL	PRTHEXBYTE
;
#IF ((AYMODE == AYMODE_SCG) | (AYMODE == AYMODE_N8) | (AYMODE == AYMODE_MBC))
	LD	A,$FF			; ACTIVATE DEVICE BIT 4 IS AY RESET CONTROL, BIT 3 IS ACTIVE LED
	OUT	(AY_ACR),A		; SET INIT AUX CONTROL REG
#ENDIF
;
#IF ((AYMODE == AYMODE_DUO))
	LD	A,$FE			;
	OUT	(AY_ACR),A		; SET INIT AUX CONTROL REG
#ENDIF
;
#IF (!AY_FORCE)
	LD	DE,(AY_R2CHBP*256)+$55	; SIMPLE HARDWARE PROBE
	CALL	AY_WRTPSG		; WRITE AND
	CALL	AY_RDPSG		; READ TO A
	LD	A,$55			; SOUND CHANNEL
	CP	E			; REGISTER
	JR	Z,AY_FND
;
	CALL	PRTSTRD \ .TEXT " NOT PRESENT$"
;
	LD	A,$FF			; UNSUCCESSFULL INIT
	RET
;
#ENDIF
;
AY_FND:
	LD	IY, AY_IDAT		; SETUP FUNCTION TABLE
	LD	BC, AY_FNTBL		; POINTER TO INSTANCE DATA
	LD	DE, AY_IDAT		; BC := FUNCTION TABLE ADDRESS
	CALL	SND_ADDENT		; DE := INSTANCE DATA PTR
;
	CALL	AY_RESET		; SET DEFAULT CHIP CONFIGURATION
	XOR	A			; SUCCESSFULL INIT
	RET
;
;======================================================================
;	INITIALIZE DEVICE
;======================================================================
;
AY_INIT:
	; HANDLE R7 SPECIAL
#IF (AYMODE == AYMODE_NABU)
	; I/O B=INPUT, I/O A=OUTPUT, NOISE CHANNEL C, B, A DISABLE, TONE CHANNEL C, B, A ENABLE
	LD	DE,(AY_R7ENAB*256)+$78	; SET MIXER CONTROL / IO ENABLE.  $78 - 01 111 000
#ELSE
	; I/O PORTS = OUTPUT, NOISE CHANNEL C, B, A DISABLE, TONE CHANNEL C, B, A ENABLE
	LD	DE,(AY_R7ENAB*256)+$F8	; SET MIXER CONTROL / IO ENABLE.  $F8 - 11 111 000
#ENDIF
	CALL	AY_WRTPSG		; SETUP R7
;
	; THEN JUST SET ALL OTHER REGISTERS TO ZERO
	LD	E,0			; VALUE ZERO
	LD	D,0			; START W/ R0
	LD	B,7			; DO 7 REGISTERS (R0-R6)
	CALL	AY_INIT1		; DO IT
	INC	D			; SKIP R7
	LD	B,6			; DO 6 MORE REGISTERS (R8-R13)
	; FALL THRU TO DO IT
;	
AY_INIT1:
	CALL	AY_WRTPSG		; WRITE REGISTER
	INC	D			; BUMP TO NEXT
	DJNZ	AY_INIT1		; LOOP
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
	AUDTRACE(AYT_INIT)
	CALL	AY_INIT			; SET DEFAULT CHIP CONFIGURATION
;
	; RESET DEFAULTS IN CASE OF AN IN-PLACE HBIOS RESTART
	LD	HL,0
	LD	(AY_PENDING_PERIOD),HL	; SET TONE PERIOD TO ZERO
	LD	(AY_PENDING_DURATION),HL; SET DURATION TO ZERO
	XOR	A			; SIGNAL SUCCESS
	LD	(AY_PENDING_VOLUME),A	; SET VOLUME TO ZERO
	RET				; DONE, A=0 ABOVE
;
;======================================================================
;	SOUND DRIVER FUNCTION - VOLUME
;======================================================================
;
AY_VOLUME:
	AUDTRACE(AYT_VOL)
	AUDTRACE_L
	AUDTRACE_CR

	LD	A,L			; SAVE VOLUME
	LD	(AY_PENDING_VOLUME), A
;
	XOR	A			; SIGNAL SUCCESS
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - NOTE
;======================================================================
;
AY_NOTE:
	LD	DE, AY3NOTETBL
	CALL	AUD_NOTE		; RETURNS PERIOD IN HL, FALL THRU
;
;======================================================================
;	SOUND DRIVER FUNCTION - PERIOD
;======================================================================
;
AY_PERIOD:
	AUDTRACE(AYT_PERIOD)
	AUDTRACE_HL
	AUDTRACE_CR
;
	LD	A,H			; IF ZERO - ERROR
	OR	L
	JR	Z,AY_PERIOD1
;
	LD	A,H			; MAXIMUM TONE PERIOD IS 12-BITS
	AND	11110000B		; ALLOWED RANGE IS 0001-0FFF (4095)
	JR	NZ,AY_PERIOD1		; RETURN NZ IF NUMBER TOO LARGE
	LD	(AY_PENDING_PERIOD),HL	; SAVE AND RETURN SUCCESSFUL
	XOR	A			; SET SUCCESS
	RET
;
AY_PERIOD1:
	LD	HL,$FFFF		; REQUESTED PERIOD IS LARGER
	LD	(AY_PENDING_PERIOD),HL	; THAN PSG CAN SUPPORT, SO
	OR	$FF			; SET PERIOD TO $FFFF
	RET				; AND RETURN FAILURE
;
;======================================================================
;	SOUND DRIVER FUNCTION - PLAY
;	B = FUNCTION
;	C = AUDIO DEVICE
;	D = CHANNEL
;	A = EXIT STATUS
;======================================================================
;
AY_PLAY:
	AUDTRACE(AYT_PLAY)
	AUDTRACE_D
	AUDTRACE_CR
;
	LD	A, (AY_PENDING_PERIOD + 1)	; CHECK THE HIGH BYTE OF THE PERIOD
	INC	A
	JR	NZ, AY_PLAY1		; PERIOD IS OK, CONTINUE
	OR	$FF			; ELSE TOO LARGE, SIGNAL FAILURE
	RET				; AND RETURN
;
AY_PLAY1:
	PUSH	HL
	PUSH	DE
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,A			; CHANNEL REGISTER
	LD	D,A			; FOR THE TONE PERIOD
;
	AUDTRACE(AYT_REGWR)
	AUDTRACE_A
	AUDTRACE_CR
;
	LD	HL,AY_PENDING_PERIOD	; WRITE THE LOWER
	LD	E,(HL)			; 8-BITS OF THE TONE PERIOD
	CALL	AY_WRTPSG
	INC	D			; NEXT REGISTER
	INC	HL			; NEXT BYTE
	LD	E,(HL)			; WRITE THE UPPER
	CALL	AY_WRTPSG       	; 8-BITS OF THE TONE PERIOD
;
	POP	DE			; RECALL CHANNEL
	PUSH	DE			; SAVE CHANNEL
;
	LD	A,D			; LIMIT CHANNEL 0-2
	AND	$3			; AND INDEX TO THE
	ADD	A,AY_R8AVOL		; CHANNEL VOLUME
	LD	D,A			; REGISTER
;
	AUDTRACE(AYT_REGWR)
	AUDTRACE_A
	AUDTRACE_CR
;
	INC	HL			; NEXT BYTE
	LD	A,(HL)			; PENDING VOLUME
	RRCA				; MAP THE VOLUME
	RRCA				; FROM 00-FF
	RRCA				; TO 00-0F
	RRCA
	AND	$0F
	LD	E,A
	CALL	AY_WRTPSG		; SET VOL (E) IN CHANNEL REG (D)
;
	POP	DE			; RECALL CHANNEL
	POP	HL
;
	XOR	A			; SIGNAL SUCCESS
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
	LD	BC,(AY_TONECNT*256)+AY_NOISECNT		; RETURN NUMBER OF
	XOR	A					; TONE AND NOISE
	RET						; CHANNELS IN BC
;
AY_QUERY_PERIOD:
	LD	HL, (AY_PENDING_PERIOD)	; RETURN 16-BIT PERIOD
	XOR	A			; IN HL REGISTER
	RET
;
AY_QUERY_VOLUME:
	LD	A, (AY_PENDING_VOLUME)	; RETURN 8-BIT VOLUME
	LD	L, A			; IN L REGISTER
	XOR	A
;	LD	H, A
	RET
;
AY_QUERY_DEV:
	LD	B, SNDDEV_AY38910		; RETURN DEVICE IDENTIFIER
	LD	DE, (AY_RSEL*256)+AY_RDAT	; AND ADDRESS AND DATA PORT
	XOR	A
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - DURATION
;======================================================================
;
AY_DURATION:
	LD	(AY_PENDING_DURATION),HL	; SET TONE DURATION
	XOR	A
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - DEVICE
;======================================================================
;
AY_DEVICE:
	LD	D,SNDDEV_AY38910	; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL UNIT
	LD	C,$00			; C := DEVICE TYPE
	LD	H,AYMODE		; H := MODE
	LD	L,AY_RSEL		; L := BASE I/O ADDRESS
	XOR	A
	RET
;
;======================================================================
;	SOUND DRIVER FUNCTION - BEEP
;======================================================================
;
AY_BEEP:
	JP	SND_BEEP		; DEFER TO GENERIC CODE IN HBIOS
;
;======================================================================
;
; 	WRITE DATA IN E REGISTER TO DEVICE REGISTER D
;	INTERRUPTS DISABLE DURING WRITE. WRITE IN SLOW MODE IF Z180 CPU.
;
;======================================================================
;
AY_WRTPSG:
#IFDEF SBCV2004
	LD	A,(HB_RTCVAL)		; GET CURRENT RTC LATCH VALUE
	OR	%00001000		; SBC-V2-004 CHANGE
	OUT	(RTCIO),A		; TO HALF CLOCK SPEED
#ENDIF
#IF (CPUFAM == CPU_Z180)
	IN0	A,(Z180_DCNTL)		; GET WAIT STATES
	PUSH	AF			; SAVE VALUE
	OR	%00110000		; FORCE SLOW OPERATION (I/O W/S=3)
	OUT0	(Z180_DCNTL),A		; AND UPDATE DCNTL
#ENDIF
	LD	A,D			; SELECT THE REGISTER WE
	EZ80_IO
	OUT	(AY_RSEL),A		; WANT TO WRITE TO
	LD	A,E			; WRITE THE VALUE TO
	EZ80_IO
	OUT	(AY_RDAT),A		; THE SELECTED REGISTER
#IF (CPUFAM == CPU_Z180)
	POP	AF			; GET SAVED DCNTL VALUE
	OUT0	(Z180_DCNTL),A		; AND RESTORE IT
#ENDIF
#IFDEF SBCV2004
	LD	A,(HB_RTCVAL)		; SBC-V2-004 CHANGE TO
	OUT	(RTCIO),A		; NORMAL CLOCK SPEED
#ENDIF
	RET
;
;======================================================================
;
;	READ FROM REGISTER D AND RETURN WITH RESULT IN E
;
AY_RDPSG:
#IFDEF SBCV2004
	LD	A,(HB_RTCVAL)		; GET CURRENT RTC LATCH VALUE
	OR	%00001000		; SBC-V2-004 CHANGE
	OUT	(RTCIO),A		; TO HALF CLOCK SPEED
#ENDIF
#IF (CPUFAM == CPU_Z180)
	IN0	A,(Z180_DCNTL)		; GET WAIT STATES
	PUSH	AF			; SAVE VALUE
	OR	%00110000		; FORCE SLOW OPERATION (I/O W/S=3)
	OUT0	(Z180_DCNTL),A		; AND UPDATE DCNTL
#ENDIF
	LD	A,D			; SELECT THE REGISTER WE
	EZ80_IO
	OUT	(AY_RSEL),A		; WANT TO READ
	EZ80_IO
	IN	A,(AY_RIN)		; READ SELECTED REGISTER
	LD	E,A
#IF (CPUFAM == CPU_Z180)
	POP	AF			; GET SAVED DCNTL VALUE
	OUT0	(Z180_DCNTL),A		; AND RESTORE IT
#ENDIF
#IFDEF SBCV2004
	LD	A,(HB_RTCVAL)		; SBC-V2-004 CHANGE TO
	OUT	(RTCIO),A		; NORMAL CLOCK SPEED
#ENDIF
	RET
;
;======================================================================
;
AY_PENDING_PERIOD	.DW	0	; PENDING PERIOD (12 BITS)	; ORDER
AY_PENDING_VOLUME	.DB	0	; PENDING VOL (8 BITS)		; SIGNIFICANT
AY_PENDING_DURATION	.DW	0	; PENDING DURATION (16 BITS)
;
#IF AUDIOTRACE
AYT_INIT		.DB	"\r\nAY_INIT\r\n$"
AYT_VOLOFF		.DB	"\r\nAY_VOLUME OFF\r\n$"
AYT_VOL			.DB	"\r\nAY_VOLUME: $"
AYT_NOTE		.DB	"\r\nAY_NOTE: $"
AYT_PERIOD		.DB	"\r\nAY_PERIOD $"
AYT_PLAY		.DB	"\r\nAY_PLAY CH: $"
AYT_REGWR		.DB	"\r\nOUT AY-3-8910 $"
#ENDIF
;
;======================================================================
;	EIGHTH TONE FREQUENCY TABLE
;======================================================================
;
; THE FOLLOWING TABLE MAPS A FULL OCTAVE OF EIGHTH-TONES
; STARTING AT A# IN OCTAVE 0 TO THE CORRESPONDING PERIOD
; VALUE TO USE ON THE PSG TO ACHIEVE THE DESIRED NOTE FREQUENCY.
;
; THE FREQUENCY PRODUCED BY THE AY-3-8910 IS:
; FREQ = CLOCK / 16 / PERIOD
;
; SO, TO MAP A DESIRED FREQUENCY TO A PERIOD, WE USE:
; PERIOD = CLOCK / 16 / FREQ
;
; IN ORDER TO IMPROVE THE RESOLUTION OF THE FREQUENCY
; VALUE USED, WE ALSO MULTPLY BOTH SIDES OF THE EQUATION
; BY 100:
; PERIOD * 100 = (CLOCK / 16 / FREQ) * 100
;
; THE RESULTING PERIOD VALUE CAN BE REPEATEDLY HALVED
; TO TO JUMP UP AS MANY OCTAVES AS DESIRED.
;
; THE FINAL VALUE IS SHIFTED BY AUD_SCALE BITS
; IN ORDER TO IMPROVE THE RESOLUTION.  THIS FINAL SHIFT
; IS REMOVED WHEN IN THE AY_NOTE ROUTINE.
;
; ASSUMING A CLOCK OF 1.7897725 MHZ, THE FIRST PLAYABLE
; NOTE WILL BE A0#/B0b (HBIOS NOTE CODE 0).
;
AY_RATIO	.EQU	(AY_CLK * 100) / (16 >> AUD_SCALE)
;
AY3NOTETBL:
	.DW	AY_RATIO / 2913		; A0#/B0b	178977250 / 2913 = 61440; PROOF: 61440 >> 3 = 7680, 3579545 / 7680 / 16 = 29.13
	.DW	AY_RATIO / 2956		;
	.DW	AY_RATIO / 2999		;
	.DW	AY_RATIO / 3042		;
	.DW	AY_RATIO / 3086		; B0
	.DW	AY_RATIO / 3131		;
	.DW	AY_RATIO / 3177		;
	.DW	AY_RATIO / 3223		;
	.DW	AY_RATIO / 3270		; C1
	.DW	AY_RATIO / 3318		;
	.DW	AY_RATIO / 3366		;
	.DW	AY_RATIO / 3415		;
	.DW	AY_RATIO / 3464		; C1#/D1b
	.DW	AY_RATIO / 3515		;
	.DW	AY_RATIO / 3566		;
	.DW	AY_RATIO / 3618		;
	.DW	AY_RATIO / 3670		; D1
	.DW	AY_RATIO / 3724		;
	.DW	AY_RATIO / 3778		;
	.DW	AY_RATIO / 3833		;
	.DW	AY_RATIO / 3889		; D1#/E1b
	.DW	AY_RATIO / 3945		;
	.DW	AY_RATIO / 4003		;
	.DW	AY_RATIO / 4061		;
	.DW	AY_RATIO / 4120		; E1
	.DW	AY_RATIO / 4180		;
	.DW	AY_RATIO / 4241		;
	.DW	AY_RATIO / 4302		;
	.DW	AY_RATIO / 4365		; F1
	.DW	AY_RATIO / 4428		;
	.DW	AY_RATIO / 4493		;
	.DW	AY_RATIO / 4558		;
	.DW	AY_RATIO / 4624		; F1#/G1b
	.DW	AY_RATIO / 4692		;
	.DW	AY_RATIO / 4760		;
	.DW	AY_RATIO / 4829		;
	.DW	AY_RATIO / 4899		; G1
	.DW	AY_RATIO / 4971		;
	.DW	AY_RATIO / 5043		;
	.DW	AY_RATIO / 5116		;
	.DW	AY_RATIO / 5191		; G1#/A1b
	.DW	AY_RATIO / 5266		;
	.DW	AY_RATIO / 5343		;
	.DW	AY_RATIO / 5421		;
	.DW	AY_RATIO / 5499		; A1
	.DW	AY_RATIO / 5579		;
	.DW	AY_RATIO / 5661		;
	.DW	AY_RATIO / 5743		;
