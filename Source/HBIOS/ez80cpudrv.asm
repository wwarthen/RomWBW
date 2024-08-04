;
;==================================================================================================
; EZ80 50/60HZ TIMER TICK DRIVER
;==================================================================================================
;
; Communicate with on-chip eZ80 firmware to:
; 1. Exchange platform version numbers
; 2. Configure memory banking type
; 3. Retrieve CPU Frequency
; 4. Set Memory and I/O Bus Timings
; 5. Set Timer Tick Frequency
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
	; TODO CHECK RETURNED VERSION AND WARN IF NOT GOOD
	; EXPECT A VERSION NUMBER > 0.1.0.0

	LD	C, MEMMGR
	LD	HL, ROMSIZE
	LD	DE, RAMSIZE
	EZ80_UTIL_BNK_HLP()		; INSTAL HIGH PERFORMANCE BANK SWITCHER
	; TODO CHECK RESULT AND USE STANDARD BANK SWITCHER IF NZ RETURNED
	; OTHERWISE USE RST.L  %18 FOR BANK SWITCH HELPER

	EZ80_UTIL_GET_CPU_FQ()
	LD	A, E
	LD	(CB_CPUMHZ), A
	LD	(CB_CPUKHZ), HL
	LD	(HB_CPUOSC), HL

#IF (EZ80_ASSIGN == 1)
	LD	H, EZ80_MEM_CYCLES
	LD	L, EZ80_IO_CYCLES
	EZ80_UTIL_SET_BUSTM()
#ELSE
	LD	HL, EZ80_MEM_FREQ
	LD	DE, EZ80_IO_FREQ
	EXX
	LD	HL, EZ80_MEM_MINCYC << 8 | EZ80_IO_MINCYC
	EXX
	EZ80_UTIL_SET_BUSFQ()
#ENDIF
	LD	A, H
	LD	(EZ80_PLT_C3CYL), A
	LD	A, L
	LD	(EZ80_PLT_C2CYL), A

	LD	C, TICKFREQ
	EZ80_TMR_SET_FREQTICK

	LD	A, 5			; HB_CPUTYPE = 5 FOR eZ80
	LD	(HB_CPUTYPE),A
	RET

EZ80_RPT_TIMINGS:
	LD	A,(EZ80_PLT_C3CYL)
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" MEM B/C, $"

	LD	A,(EZ80_PLT_C2CYL)
	CALL	PRTDECB
	CALL	PRTSTRD
	.TEXT	" I/O B/C$"
	RET

EZ80_PLT_C3CYL:
	.DB	EZ80_MEM_CYCLES
EZ80_PLT_C2CYL:
	.DB	EZ80_IO_CYCLES
