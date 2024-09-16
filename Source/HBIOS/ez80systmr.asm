;
;==================================================================================================
; EZ80 50/60HZ TIMER TICK DRIVER
;==================================================================================================
;
; Configuration options:
; EZ80TIMER:
;   0 -> No timer tick interrupts MARSHALLED to HBIOS.
;	 HBIOS System calls SYS_GETTIMER, SYS_GETSECS, SYS_SETTIMER, SYS_SETSECS are implemented here and DELEGATED to eZ80 firmware functions
;   1 -> Timer tick interrupts MARSHALLED to HBIOS.
;	 HBIOS System calls SYS_GETTIMER, SYS_GETSECS, SYS_SETTIMER, SYS_SETSECS are implemented within HBIOS
;

#IF (EZ80TIMER == EZ80TMR_INT)
EZ80_TMR_INIT:
	CALL	NEWLINE			; FORMATTING
	CALL	PRTSTRD
	.TEXT	"EZ80 TIMER: INTERRUPTS ENABLED$"

	LD	HL,EZ80_TMR_INT		; GET INT VECTOR
	CALL	HB_ADDIM1		; ADD TO IM1 CALL LIST

	EZ80_TMR_INT_ENABLE()		; INSTALL TIMER HOOK
	RET

EZ80_TMR_INT:
	EZ80_TMR_IS_TICK_ISR()
	RET	Z			; NOT A EZ80 TIMER TICK

	CALL	HB_TIMINT		; RETURN NZ - HANDLED
	OR	$FF
	RET
#ENDIF
#IF (EZ80TIMER == EZ80TMR_FIRM)

EZ80_TMR_INIT:
	CALL	NEWLINE			; FORMATTING
	CALL	PRTSTRD
	.TEXT	"EZ80 TIMER: FIRMWARE$"
	RET
; -----------------------------------------------
; Implementation of HBIOS SYS TIMER functions to
; delegate to eZ80 firmware functions

; GET TIMER
;   RETURNS:
;     DE:HL: TIMER VALUE (32 BIT)
;
SYS_GETTIMER:
	EZ80_TMR_GET_TICKS()
	RET
;
; GET SECONDS
;   RETURNS:
;     DE:HL: SECONDS VALUE (32 BIT)
;     C: NUM TICKS WITHIN CURRENT SECOND
;
SYS_GETSECS:
	EZ80_TMR_GET_SECONDS()

	EZ80_CPY_UHL_TO_EHL		; E:HL{15:0} <- HL{23:0}
	LD	D, 0
	RET
;
; SET TIMER
;   ON ENTRY:
;     DE:HL: TIMER VALUE (32 BIT)
;
SYS_SETTIMER:
	EZ80_CPY_EHL_TO_UHL		; HL{23:0} <- E:HL{15:0}
	EZ80_TMR_SET_TICKS()
	RET
;
; SET SECS
;   ON ENTRY:
;     DE:HL: SECONDS VALUE (32 BIT)
;
SYS_SETSECS:
	EZ80_CPY_EHL_TO_UHL		; HL{23:0} <- E:HL{15:0}

	EZ80_TMR_SET_SECONDS()
	RET

#ENDIF
#IF (EZ80TIMER == EZ80TMR_NONE)
EZ80_TMR_INIT:
	RET
#ENDIF
