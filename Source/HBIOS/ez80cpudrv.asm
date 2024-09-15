;
;==================================================================================================
; RCBUS EZ80 CPU DRIVER
;==================================================================================================
;
; Driver code designed for the RCBus eZ80 CPU Module.  
; The driver expects the eZ80 firmware to manage the initial booting of the system.
; Details for the platform and the software for the on-chip firmware can be found at:
; https://github.com/dinoboards/rc2014-ez80
;
; Although the eZ80 firmware is booted before HBIOS, the eZ80 CPU driver is still required
; to communicate with the firmware to perform a number of initialisation tasks.
; See also the associated ez80 platform drivers (ez80rtc, ez80systmr, ez80uart).
;
; The driver 'exports' two key functions:
; 1. EZ80_PREINIT - This function is called by the HBIOS boot code to initialise the eZ80 firmware.
; 2. EZ80_RPT_TIMINGS - This function is called by the HBIOS boot code to report the platform timings.
;
; EZ80_PREINIT performs the following:
; 1. Exchange platform version numbers
; 2. Retrieve CPU Frequency
; 3. Set Memory and I/O Bus Timings
; 4. Set Timer Tick Frequency
;

EZ80_PREINIT:
	EZ80_TMR_INT_DISABLE()

	; PROVIDE THE EZ80 FIRMWARE WITH PLATFORM CONFIGUATIONS
	LD	C, 1			; RomWBW'S ASSIGNED CODE
	LD	D, RMJ
	LD	E, RMN
	LD	H, RUP
	LD	L, RTP

	EZ80_UTIL_VER_EXCH()
	; TODO: MAP THE FIRMWARE CPU TO HBIOS (eZ80 ONLY HAS ONE CPU TYPE AS OF NOW)
	LD	A, 5
	LD	(HB_CPUTYPE),A

	; DETECT IF USING ALT-FIRMWARE
	LD	A, C
	AND	$80
	LD	(EZ80_ALT_FIRM), A
	LD	(EZ80_PLT_VERSION), HL
	LD	(EZ80_PLT_VERSION+2), DE

	EXX
	LD	A, C
	LD	(EZ80_BUILD_DATE), A		; DAY
	LD	A, D
	LD	(EZ80_BUILD_DATE+1), A		; MONTH
	LD	A, E
	LD	(EZ80_BUILD_DATE+2), A		; YEAR

	EZ80_UTIL_GET_CPU_FQ()
	LD	A, E
	LD	(CB_CPUMHZ), A
	LD	(CB_CPUKHZ), HL
	LD	(HB_CPUOSC), HL

#IF (EZ80_FWSMD_TYP == EZ80WSMD_WAIT)
	LD	L, EZ80_FLSH_WS
	EZ80_UTIL_FLSHWS_SET()
	LD	A, L
	LD	(EZ80_PLT_FLSHWS), A
#ENDIF

#IF (EZ80_FWSMD_TYP == EZ80WSMD_CALC)
	LD	HL, EZ80_FLSH_MIN_NS
	LD	E, 0
	EZ80_CPY_EHL_TO_UHL
	EZ80_UTIL_FLSHFQ_SET()
	LD	A, L
	LD	(EZ80_PLT_FLSHWS), A
#ENDIF


#IF (EZ80_WSMD_TYP == EZ80WSMD_CYCLES)
	LD	L, EZ80_MEM_CYCLES
	OR	$80
	EZ80_UTIL_MEMTM_SET()
	LD	A, L
	LD	(EZ80_PLT_MEMWS), A

	LD	L, EZ80_IO_CYCLES
	OR	$80
	EZ80_UTIL_IOTM_SET()
	LD	A, L
	LD	(EZ80_PLT_IOWS), A

	RET
#ENDIF

#IF (EZ80_WSMD_TYP == EZ80WSMD_CALC)
	LD	HL, EZ80_MEM_MIN_NS
	LD	E, 0
	EZ80_CPY_EHL_TO_UHL
	LD	E, EZ80_MEM_MIN_WS
	EZ80_UTIL_MEMTMFQ_SET
	LD	A, L
	LD	(EZ80_PLT_MEMWS), A

	LD	HL, EZ80_IO_MIN_NS
	LD	E, 0
	EZ80_CPY_EHL_TO_UHL
	LD	E, EZ80_IO_MIN_WS
	EZ80_UTIL_IOTMFQ_SET

	LD	A, L
	LD	(EZ80_PLT_IOWS), A
#ENDIF
#IF (EZ80_WSMD_TYP == EZ80WSMD_WAIT)
	LD	L, EZ80_MEM_WS
	EZ80_UTIL_MEMTM_SET()
	LD	A, L
	LD	(EZ80_PLT_MEMWS), A

	LD	L, EZ80_IO_WS
	EZ80_UTIL_IOTM_SET()
	LD	A, L
	LD	(EZ80_PLT_IOWS), A
#ENDIF

	LD	C, TICKFREQ
	EZ80_TMR_SET_FREQTICK

	RET

EZ80_RPT_TIMINGS:
	LD	A, (EZ80_PLT_MEMWS)
	BIT	7, A
	JR	NZ, EZ80_RPT_MCYC

	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" MEM W/S, $"
	JR	EZ80_RPT_IOTIMING

EZ80_RPT_MCYC:
	AND	$7F
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" MEM B/C, $"

EZ80_RPT_IOTIMING:
	LD	A, (EZ80_PLT_IOWS)
	BIT	7, A
	JR	NZ, EZ80_RPT_ICYC

	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" I/O W/S, $"
	JR	EZ80_RPT_FSH_TIMINGS

EZ80_RPT_ICYC:
	AND	$7F
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" I/O B/C, $"

EZ80_RPT_FSH_TIMINGS:
	LD	A, (EZ80_PLT_FLSHWS)
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" FSH W/S$"
	RET

EZ80_RPT_FIRMWARE:
	CALL	PRTSTRD
	.TEXT	"\r\neZ80 Firmware: $"

	LD	A, (EZ80_PLT_VERSION+3) 	; MAJOR VERSION NUMBER
	CALL	PRTDECB
	CALL	PC_PERIOD
	LD	A, (EZ80_PLT_VERSION+2) 	; MINOR VERSION NUMBER
	CALL	PRTDECB
	CALL	PC_PERIOD
	LD	A, (EZ80_PLT_VERSION+1) 	; REVISION NUMBER
	CALL	PRTDECB
	CALL	PC_PERIOD
	LD	A, (EZ80_PLT_VERSION) 		; PATCH NUMBER
	CALL	PRTDECB

	CALL	PRTSTRD
	.TEXT	" 20$"
	LD	A, (EZ80_BUILD_DATE+2)		; YEAR
	CALL	PRTDECB
	CALL	PC_DASH
	LD	A, (EZ80_BUILD_DATE+1)		; MONTH
	CALL	PC_LEADING_ZERO
	CALL	PRTDECB
	CALL	PC_DASH
	LD	A, (EZ80_BUILD_DATE)		; DAY
	CALL	PC_LEADING_ZERO
	CALL	PRTDECB

	LD	A, (EZ80_ALT_FIRM)
	OR	A
	RET	Z
	CALL	PRTSTRD
	.TEXT	" (ALT)$"
	RET

PC_LEADING_ZERO:
	CP	10
	RET	NC

	PUSH	AF
	LD 	A, '0'
	JP	PC_PRTCHR

PC_DASH:
	PUSH	AF
	LD	A, '-'
	JP	PC_PRTCHR

EZ80_PLT_MEMWS:
	.DB	EZ80_MEM_WS
EZ80_PLT_IOWS:
	.DB	EZ80_IO_WS
EZ80_PLT_FLSHWS:
	.DB	EZ80_FLSH_WS

EZ80_PLT_VERSION:
	.DB	0, 0, 0, 0

EZ80_ALT_FIRM:
	.DB	0

EZ80_BUILD_DATE:
	.DB	0, 0, 0					; DAY, MONTH, YEAR

; ez80 helper functions/instructions

_EZ80_CPY_EHL_TO_UHL:
	PUSH	IX
	PUSH	AF
	.DB 	$5B, $DD, $21, $00, $00, $00		; LD.LIL	IX, 0
	.DB 	$49, $DD, $39				; ADD.L		IX, SP
	.DB 	$49, $E5				; PUSH.L	HL
	.DB 	$5B, $DD, $73, $FF			; LD.LIL	(IX-1), E
	.DB 	$49, $E1				; POP.L		HL
	POP	AF
	POP	IX
	RET

_EZ80_CPY_UHL_TO_EHL:
	PUSH	IX
	.DB	$5B, $DD, $21, $00, $00, $00		; LD.LIL	IX, 0
	.DB	$49, $DD, $39				; ADD.L		IX, SP
	.DB	$49, $E5				; PUSH.L	HL
	.DB	$5B, $DD, $5E, $FF			; LD.LIL	E, (IX-1)
	.DB	$49, $E1				; POP.L		HL
	POP	IX
	RET
