
;==================================================================================================
; Benchmark BQ4845P RTC Driver
;==================================================================================================


;  Register Addresses (HEX / BCD):

;  +---+-----+--------------+-------------------+------------------+----------------+
;  |ADR|  D7 | D6 | D5 | D4 | D3 | D2 | D1 | D0 | RANGE            | REGISTER       |
;  +---+-----+--------------+-------------------+------------------+----------------+
;  | 0 |  0  |    10-Second |          1-Second |            00-59 | Seconds        |
;  +---+-----+----+---------+-------------------+------------------+----------------+
;  |   | ALM1|ALM2|         |                   |                  |                |
;  | 1 |     |    10-Second |          1-Second |            00-59 | Seconds Alarm  |
;  +---+-----+--------------+-------------------+------------------+----------------+
;  | 2 |  0  |    10-Minute |          1-Minute |            00-59 | Minutes        |
;  +---+-----+----+---------+-------------------+------------------+----------------+
;  |   | ALM1|ARM0|         |                   |                  |                |
;  | 3 |     |    10-Minute |          1-Minute |            00-59 | Minutes Alarm  |
;  +---+-----+----+---------+-------------------+------------------+----------------+
;  | 4 |PM/AM|  0 | 10-Hour |            1-Hour |01-12 AM/81-92 PM | Hours          |
;  +---+-----+----+----+----+-------------------+------------------+----------------+
;  |   | ALM1|    |         |                   |                  |                |
;  | 5 |PM/AM|ALM0| 10-Hour |            1-Hour |01-12 AM/81-92 PM | Hours Alarm    |
;  +---+-----+----+----+----+-------------------+------------------+----------------+
;  | 6 |  0  |  0 |  10-Day |             1-Day |            01-31 | Day            |
;  +---+-----+----+----+----+-------------------+------------------+----------------+
;  | 7 | ALM1|ALM0|  10-day |             1-Day |            01-31 | Day Alarm      |
;  +---+-----+----+----+----+----+--------------+------------------+----------------+
;  | 8 |  0  |  0 |  0 |  0 |  0 |  Day Of Week |            01-07 | Day Of Week    |
;  +---+-----+----+----+----+----+--------------+------------------+----------------+
;  | 9 |  0  |  0 |  0 |10Mo|           1-Month |            01-12 | Month          |
;  +---+-----+----+----+----+-------------------+------------------+----------------+
;  | A |            10-Year |            1-Year |            00-99 | Year           |
;  +---+-----+----+----+----+----+----+----+----+------------------+----------------+
;  | B |  *  | WD2| WD1| WD0| RS3| RS2| RS1| RS0|                  | Rates          |
;  +---+-----+----+----+----+----+----+----+----+------------------+----------------+
;  | C |  *  |  * |  * |  * | AIE| PIE|PWRE| ABE|                  | Interrupt      |
;  +---+-----+----+----+----+----+----+----+----+------------------+----------------+
;  | D |  *  |  * |  * |  * | AF | PF |PWRF| BVF|                  | Flags          |
;  +---+-----+----+----+----+----+----+----+----+------------------+----------------+
;  | E |  *  |  * |  * |  * | UTI|STOP|2412| DSE|                  | Control        |
;  +---+-----+----+----+----+----+----+----+----+------------------+----------------+
;  | F |  *  |  * |  * |  * |  * |  * |  * |  * |                  | Unused         |
;  +---+-----+----+----+----+----+----+----+----+------------------+----------------+

;  * = Unused bits; unwritable and read as 0.
;  0 = should be set to 0 for valid time/calendar range.
;  Clock calendar data is BCD. Automatic leap year adjustment.
;  PM/AM = 1 for PM; PM/AM = 0 for AM.
;  DSE = 1 enable daylight savings adjustment.
;  24/12 = 1 enable 24-hour data representation; 24/12 = 0 enables 12-hour data representation.
;  Day-Of-Week coded as Sunday = 1 through Saturday = 7.
;  BVF = 1 for valid battery.
;  STOP = 1 turns the RTC on; STOP = 0 stops the RTC in back-up mode.

; Constants

BQRTC_SEC	.EQU	BQRTC_BASE + $00
BQRTC_SEC_ALM	.EQU	BQRTC_BASE + $01
BQRTC_MIN	.EQU	BQRTC_BASE + $02
BQRTC_MIN_ALM	.EQU	BQRTC_BASE + $03
BQRTC_HOUR	.EQU	BQRTC_BASE + $04
BQRTC_HOUR_ALM	.EQU	BQRTC_BASE + $05
BQRTC_DAY	.EQU	BQRTC_BASE + $06
BQRTC_DAY_ALM	.EQU	BQRTC_BASE + $07
BQRTC_WEEK_DAY	.EQU	BQRTC_BASE + $08
BQRTC_MONTH	.EQU	BQRTC_BASE + $09
BQRTC_YEAR	.EQU	BQRTC_BASE + $0A
BQRTC_RATE	.EQU	BQRTC_BASE + $0B
BQRTC_INTERRUPT	.EQU	BQRTC_BASE + $0C
BQRTC_FLAGS	.EQU	BQRTC_BASE + $0D
BQRTC_CONTROL	.EQU	BQRTC_BASE + $0E
BQRTC_UNUSED	.EQU	BQRTC_BASE + $0F

BQRTC_HIGH	.EQU	%11110000
BQRTC_LOW	.EQU	%00001111
BQRTC_WD	.EQU	%01110000
BQRTC_RS	.EQU	%00001111

BQRTC_BVF	.EQU	%00000001
BQRTC_PWRF	.EQU	%00000010
BQRTC_PF	.EQU	%00000100
BQRTC_AF	.EQU	%00001000

BQRTC_DSE	.EQU	%00000001
BQRTC_2412	.EQU	%00000010
BQRTC_STOP	.EQU	%00000100
BQRTC_UTI	.EQU	%00001000

BQRTC_BUFSIZE	.EQU	6		; 6 BYTE BUFFER (YYMMDDHHMMSS)

; RTC Device Initialization Entry

BQRTC_INIT:
	LD	A,(RTC_DISPACT)		; RTC DISPATCHER ALREADY SET?
	OR	A			; SET FLAGS
	RET	NZ			; IF ALREADY ACTIVE, ABORT
;
	CALL	NEWLINE				; Formatting
	PRTS("BQRTC: IO=0x$")
	LD	A, BQRTC_BASE
	CALL	PRTHEXBYTE

	LD	A, BQRTC_DSE | BQRTC_2412 | BQRTC_STOP | BQRTC_UTI
	OUT0	(BQRTC_CONTROL), A		; Enable Daylight Savings and 24 Hour
	
	XOR	A				; Zero A
	OUT0	(BQRTC_RATE), A			; Disable Periodic Interrupt Rate
	OUT0	(BQRTC_INTERRUPT), A		; Disable Interrupts

	CALL	BQRTC_LOAD
	; DISPLAY CURRENT TIME
	PRTS("  $")
	LD	A, (BQRTC_BUF_MON)
	CALL	PRTHEXBYTE
	PRTS("/$")
	LD	A, (BQRTC_BUF_DAY)
	CALL	PRTHEXBYTE
	PRTS("/$")
	LD	A, (BQRTC_BUF_YEAR)
	CALL	PRTHEXBYTE
	PRTS(" $")
	LD	A, (BQRTC_BUF_HOUR)
	CALL	PRTHEXBYTE
	PRTS(":$")
	LD	A, (BQRTC_BUF_MIN)
	CALL	PRTHEXBYTE
	PRTS(":$")
	LD	A, (BQRTC_BUF_SEC)
	CALL	PRTHEXBYTE

	LD	BC,BQRTC_DISPATCH
	CALL	RTC_SETDISP

	XOR	A				; Signal success
	RET
	
; RTC Device Function Dispatch Entry
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   B: Function (IN)

BQRTC_DISPATCH:
	LD	A, B				; Get requested function
	AND	$0F				; Isolate Sub-Function
	JP	Z, BQRTC_GETTIM			; Get Time
	DEC	A
	JP	Z, BQRTC_SETTIM			; Set Time 
	DEC	A
	JP	Z, BQRTC_GETBYT			; Get NVRAM Byte Value
	DEC	A
	JP	Z, BQRTC_SETBYT			; Set NVRAM Byte Value
	DEC	A
	JP	Z, BQRTC_GETBLK			; Get NVRAM Data Block Value
	DEC	A
	JP	Z, BQRTC_SETBLK			; Set NVRAM Data Block Value 
	DEC	A
	JP	Z, BQRTC_GETALM			; Get Alarm
	DEC	A
	JP	Z, BQRTC_SETALM			; Set Alarm
	DEC	A
	JP	Z, BQRTC_DEVICE			; Report RTC device info
	SYSCHKERR(ERR_NOFUNC)
	RET
	
;
; NVRAM FUNCTIONS ARE NOT AVAILABLE
;
BQRTC_GETBYT:
BQRTC_SETBYT:
BQRTC_GETBLK:
BQRTC_SETBLK:
	SYSCHKERR(ERR_NOTIMPL)
	RET
	
; RTC Get Time
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   HL: Date/Time Buffer (OUT)
; Buffer format is BCD: YYMMDDHHMMSS
; 24 hour time format is assumed
;
BQRTC_GETTIM:
	EX	DE, HL
	CALL	BQRTC_LOAD	
	; Now copy to read destination (Interbank Save)
	LD	A, BID_BIOS			; Copy from BIOS bank
	LD	(HB_SRCBNK), A			; Set it 
	LD	A, (HB_INVBNK)			; Copy to current user bank
	LD	(HB_DSTBNK), A			; Set it
	LD	BC, BQRTC_BUFSIZE		; Length is 6 bytes
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
;
	; CLEAN UP AND RETURN
	XOR	A				; SIGNAL SUCCESS
	RET					; AND RETURN
;
; RTC Set Time
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   HL: Date/Time Buffer (IN)
; Buffer Format is BCD: YYMMDDHHMMSS
; 24 hour time format is assumed
;
BQRTC_SETTIM:
;
	; Copy incoming time data to our time buffer
	LD	A, (HB_INVBNK)			; Copy from current user bank
	LD	(HB_SRCBNK), A			; Set it
	LD	A, BID_BIOS			; Copy to BIOS bank
	LD	(HB_DSTBNK), A			; Set it
	LD	DE, BQRTC_BUF			; Destination Address
	LD	BC, BQRTC_BUFSIZE		; Length is 6 bytes
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
	; Write to clock
	LD	HL, BQRTC_BUF
	CALL	BQRTC_SUSPEND
	LD	A, (HL)
	OUT0	(BQRTC_YEAR), A			; Write Year
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_MONTH), A		; Write Month
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_DAY), A			; Write Day
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_HOUR), A			; Write Hour
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_MIN), A			; Write Minute
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_SEC), A			; Write Second
	CALL	BQRTC_RESUME
	; clean up and return
	XOR	A				; Signal success
	RET					; And return
	
; RTC Get Alarm
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   HL: Date/Time Buffer (OUT)
; Buffer format is BCD: YYMMDDHHMMSS
; 24 hour time format is assumed
;
BQRTC_GETALM:
	EX	DE, HL	
	LD	HL, BQRTC_BUF
	PUSH	HL				; Save address of source buffer
	CALL	BQRTC_SUSPEND
	XOR	A
	LD	(HL), A				; Read Year
	INC	HL
	LD	(HL), A				; Read Month
	INC	HL
	IN0	A, (BQRTC_DAY_ALM)		; Read Day
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_HOUR_ALM)		; Read Hour
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_MIN_ALM)		; Read Minute
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_SEC_ALM)		; Read Second
	LD	(HL), A
	CALL	BQRTC_RESUME
	POP	HL				; Restore address of source buffer
	; Now copy to read destination (Interbank Save)
	LD	A, BID_BIOS			; Copy from BIOS bank
	LD	(HB_SRCBNK), A			; Set it 
	LD	A, (HB_INVBNK)			; Copy to current user bank
	LD	(HB_DSTBNK), A			; Set it
	LD	BC, BQRTC_BUFSIZE		; Length is 6 bytes
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
;
	; CLEAN UP AND RETURN
	XOR	A				; SIGNAL SUCCESS
	RET					; AND RETURN
;
; RTC Set Alarm
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   HL: Date/Time Buffer (IN)
; Buffer Format is BCD: YYMMDDHHMMSS
; 24 hour time format is assumed
;
BQRTC_SETALM:
	; Copy incoming time data to our time buffer
	LD	A, (HB_INVBNK)			; Copy from current user bank
	LD	(HB_SRCBNK), A			; Set it
	LD	A, BID_BIOS			; Copy to BIOS bank
	LD	(HB_DSTBNK), A			; Set it
	LD	DE, BQRTC_BUF			; Destination Address
	LD	BC, BQRTC_BUFSIZE		; Length is 6 bytes
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
	; Write to clock
	LD	HL, BQRTC_BUF_DAY
	CALL	BQRTC_SUSPEND
	LD	A, (HL)
	OUT0	(BQRTC_DAY_ALM), A		; Write Day
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_HOUR_ALM), A		; Write Hour
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_MIN_ALM), A		; Write Minute
	INC	HL
	LD	A, (HL)
	OUT0	(BQRTC_SEC_ALM), A		; Write Second
	CALL	BQRTC_RESUME
	; clean up and return
	XOR	A				; Signal success
	RET					; And return
;
; REPORT RTC DEVICE INFO
;
BQRTC_DEVICE:
	LD	D,RTCDEV_BQ		; D := DEVICE TYPE
	LD	E,0			; E := PHYSICAL DEVICE NUMBER
	LD	H,0			; H := 0, DRIVER HAS NO MODES
	LD	L,BQRTC_BASE		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET

BQRTC_SUSPEND:
	IN0	A, (BQRTC_CONTROL)		; Suspend Clock
	OR	BQRTC_UTI
	OUT0	(BQRTC_CONTROL), A
	RET

BQRTC_RESUME:
	IN0	A, (BQRTC_CONTROL)		; Resume Clock
	AND	~BQRTC_UTI
	OUT0	(BQRTC_CONTROL), A
	RET
	
BQRTC_LOAD:
	LD	HL, BQRTC_BUF
	PUSH	HL				; Save address of source buffer
	CALL	BQRTC_SUSPEND
	IN0	A, (BQRTC_YEAR)			; Read Year
	LD	(HL), A	
	INC	HL
	IN0	A, (BQRTC_MONTH)		; Read Month
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_DAY)			; Read Day
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_HOUR)			; Read Hour
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_MIN)			; Read Minute
	LD	(HL), A
	INC	HL
	IN0	A, (BQRTC_SEC)			; Read Second
	LD	(HL), A
	CALL	BQRTC_RESUME
	POP	HL				; Restore address of source buffer
	RET

; Working Variables

BQRTC_BUF:
BQRTC_BUF_YEAR:	.DB	0		; Year
BQRTC_BUF_MON:	.DB	0		; Month 
BQRTC_BUF_DAY:	.DB	0		; Day
BQRTC_BUF_HOUR:	.DB	0		; Hour
BQRTC_BUF_MIN:	.DB	0		; Minute
BQRTC_BUF_SEC:	.DB	0		; Second
