;
;==================================================================================================
; RCBUS EZ80 CPU DRIVER
;==================================================================================================
;
; Driver code designed for the RCBus eZ80 CPU Module.  
; The driver expects the eZ80 firmware to manage the initial booting of the system.
; Details for the platform and the software for the on-chip firmware can be found at:
; https://github.com/dinoboards/ez80-for-rc
;
; Although the eZ80 firmware is booted before HBIOS, the eZ80 CPU driver is still required
; to communicate with the firmware to perform a number of initialisation tasks.
; See also the associated ez80 platform drivers (ez80rtc, ez80systmr, ez80uart).
;
; The driver 'exports' the following:
; 1. EZ80_PREINIT - This function is called by the HBIOS boot code to initialise the eZ80 firmware.
; 2. EZ80_RPT_TIMINGS - This function is called by the HBIOS boot code to report the platform timings.
; 3. DELAY - pause for approx 17us
; 4. VDELAY - pause for approx 17us * DE
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

	LD	(EZ80_PLT_VERSION), HL
	LD	(EZ80_PLT_VERSION+2), DE

	; need version 0.4.x.x at miniumum
	LD 	HL, 4-1
	XOR	A
	SBC	HL, DE
	
	JR 	c, EZ80_VEROK
	CPL

EZ80_VEROK:
	LD	(EZ80_VER_WARNING), A

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
	LD	L, EZ80_MEM_CYCLES | $80
	EZ80_UTIL_MEMTM_SET()
	LD	A, L
	LD	(EZ80_PLT_MEMBC), A

	LD	L, EZ80_IO_CYCLES | $80
	EZ80_UTIL_IOTM_SET()
	LD	A, L
	LD	(EZ80_PLT_IOBC), A

	RET
#ENDIF

#IF (EZ80_WSMD_TYP == EZ80WSMD_CALC)
	LD	HL, EZ80_MEM_MIN_NS
	LD	E, 0
	EZ80_CPY_EHL_TO_UHL
	LD	E, EZ80_MEM_MIN_BC | $80
	EZ80_UTIL_MEMTMFQ_SET
	LD	A, L
	LD	(EZ80_PLT_MEMBC), A

	LD	HL, EZ80_IO_MIN_NS
	LD	E, 0
	EZ80_CPY_EHL_TO_UHL
	LD	E, EZ80_IO_MIN_BC
	EZ80_UTIL_IOTMFQ_SET

	LD	A, L
	LD	(EZ80_PLT_IOBC), A
#ENDIF

	LD	C, TICKFREQ
	EZ80_TMR_SET_FREQTICK

	RET
;
; --------------------------------
; eZ80 CPU DRIVER REPORT TIMINGS
; --------------------------------
EZ80_RPT_TIMINGS:
	LD	A, (EZ80_PLT_MEMBC)
	AND	$7F
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" MEM B/C, $"

EZ80_RPT_IOTIMING:
	LD	A, (EZ80_PLT_IOBC)
	AND	$7F
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" I/O B/C, $"

EZ80_RPT_FSH_TIMINGS:
	LD	A, (EZ80_PLT_FLSHWS)
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" FSH W/S$";

;--------------------------------------------------------------------------------------------------
; DELAY LOOP TEST CALIBRATION
;--------------------------------------------------------------------------------------------------
;
; IF ENABLED, THE GPIO PCBx PINS OF THE EZ80 WILL BE TOGGLED AT 'DELAY' RATE * 16 
; CAN BE USED TO VERIFY DELAY WORKS SUFFICIENT FOR DIFFERENT EZ80 CLOCK SPEEDS
; AND BUS CYCLES
;
#IF FALSE

;   7.3728 MHZ -- 1 MEM W/S, 6 I/O W/S, 0 FSH W/S - 428 - 26.7us
;  18.4320 MHZ -- 2 MEM W/S, 6 I/O W/S, 1 FSH W/S - 284 - 17.8us
;  20.0000 MHZ -- 2 MEM W/S, 6 I/O W/S, 1 FSH W/S - 281 - 17.6us
;  25.0000 MHZ -- 2 MEM W/S, 3 I/O B/C, 1 FSH W/S - 271 - 16.9us
;  32.0000 MHZ -- 3 MEM W/S, 4 I/O B/C, 2 FSH W/S - 289 - 18.0us


PC_DR:		.equ	$009E
PC_DDR:		.equ	$009F
	DI

	; ENABLE PC5 GPIO AS OUTPUT
	LD	BC, PC_DDR
	XOR	A
	OUT	(C), A
	PUSH	AF

	LD	BC, PC_DR
LOOP:

	POP	AF
	OUT	(C), A
	CPL
	PUSH	AF

	CALL	DELAY
	CALL	DELAY
	CALL	DELAY
	CALL	DELAY

	CALL	DELAY
	CALL	DELAY
	CALL	DELAY
	CALL	DELAY

	CALL	DELAY
	CALL	DELAY
	CALL	DELAY
	CALL	DELAY

	CALL	DELAY
	CALL	DELAY
	CALL	DELAY
	CALL	DELAY

	JR	LOOP
#ENDIF
	RET

DELAY:
	EZ80_DELAY
	EZ80_DELAY
	EZ80_DELAY
	RET

VDELAY:
	EZ80_DELAY
	EZ80_DELAY
	EZ80_DELAY
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ, VDELAY
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

	LD	A, (EZ80_VER_WARNING)
	OR      A
	RET     Z
	CALL    PRTSTRD
	.TEXT   " (WARN-VER-OOD)$"

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

EZ80_PLT_MEMBC:
	.DB	EZ80_MEM_CYCLES
EZ80_PLT_IOBC:
	.DB	EZ80_IO_CYCLES
EZ80_PLT_FLSHWS:
	.DB	EZ80_FLSH_WS

EZ80_PLT_VERSION:
	.DB	0, 0, 0, 0

EZ80_VER_WARNING:
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

; set the upper byte (u of DE) to MB.
_EZ80_EXTN_DE_TO_MB_DE:
	.DB	$49, $D5				; PUSH.L 	DE
	.DB	$5B, $FD, $21, $00, $00, $00		; LD.LIL 	IY, 0
	.DB	$49, $FD, $39				; ADD.L		IY, SP
	.DB	$ED, $6E              			; LD 		A, MB
	.DB	$5B, $FD, $77, $02			; LD.LIL 	(IY+2), A
	.DB	$49, $D1				; POP.L		DE
	RET

; set the upper byte (u of IY) to MB.
_EZ80_EXTN_IY_TO_MB_IY:
	.DB	$49, $FD, $E5				; PUSH.L	IY
	.DB	$5B, $FD, $21, $00, $00, $00		; LD.LIL	IY, 0
	.DB	$49, $FD, $39				; ADD.L		IY, SP
	.DB	$ED, $6E				; LD		A, MB
	.DB	$5B, $FD, $77, $02			; LD.LIL	(IY+2), A
	.DB	$49, $FD, $E1				; POP.L		IY
	RET
