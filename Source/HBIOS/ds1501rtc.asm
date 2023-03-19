
;
;==================================================================================================
; Maxim DS1501/DS1511 Y2K-Compliant Watchdog RTC Driver
;==================================================================================================
;
; THIS DRIVER CODE WAS CONTRIBUTED TO ROMWBW BY JPELLETIER 3:59 PM 7/24/2022
;
;  Register Addresses (HEX / BCD):
;
;  +---+-----+---------------+-------------------+------------------+----------------+
;  |ADR|  D7 | D6  | D5 | D4 | D3 | D2 | D1 | D0 | RANGE            | REGISTER       |
;  +---+-----+---------------+-------------------+------------------+----------------+
;  | 0 |  0  |     10-Second |          1-Second |            00-59 | Seconds        |
;  +---+-----+-----+---------+-------------------+------------------+----------------+
;  | 1 |  0  |     10-Minute |          1-Minute |            00-59 | Minutes        |
;  +---+-----+-----+---------+-------------------+------------------+----------------+
;  | 2 |  0  |  0  | 10-Hour |            1-Hour |            00-23 | Hours          |
;  +---+-----+-----+----+----+-------------------+------------------+----------------+
;  | 3 |  0  |  0  |  0 |  0 |  0 |  Day Of Week |            01-07 | Day Of Week    |
;  +---+-----+-----+----+----+----+--------------+------------------+----------------+
;  | 4 |  0  |  0  | 10-Date |            1-Date |            01-31 | Date           |
;  +---+-----+-----+----+----+-------------------+------------------+----------------+
;  | 5 |/EOSC|/E32K|BB32|10Mo|           1-Month |            01-12 | Month          |
;  +---+-----+-----+----+----+-------------------+------------------+----------------+
;  | 6 |             10-Year |            1-Year |            00-99 | Year           |
;  +---+-----+-----+----+----+----+----+----+----+------------------+----------------+
;  | 7 |          10-Century |         1-Century |            00-39 | Century        |
;  +---+-----+-----+----+----+----+----+----+----+------------------+----------------+
;  | 8 |  AM1|     10-Second |          1-Second |            00-59 | Seconds Alarm  |
;  +---+-----+---------------+-------------------+------------------+----------------+
;  | 9 |  AM2|     10-Minute |          1-Minute |            00-59 | Minutes Alarm  |
;  +---+-----+-----+---------+-------------------+------------------+----------------+
;  | A |  AM3|  0  | 10-Hour |            1-Hour |            00-23 | Hours Alarm    |
;  +---+-----+-----+----+----+-------------------+------------------+----------------+
;  | B |  AM4|DY/DT| 10-date |          Day/Date |        1-7/01-31 | Day/Date Alarm |
;  +---+-----+-----+----+----+----+--------------+------------------+----------------+
;  | C |          0.1-Second |       0.01-Second |            00-99 | Watchdog       |
;  +---+-----+-----+---------+-------------------+------------------+----------------+
;  | D |           10-Second |          1-Second |            00-99 | Watchdog       |
;  +---+-----+-----+---------+-------------------+------------------+----------------+
;  | E | BLF1| BLF2| PRS| PAB| TDF| KSF| WDF|IRQF|                  | ControlA       |
;  +---+-----+-----+----+----+----+----+----+----+------------------+----------------+
;  | F |   TE|   CS| BME| TPE| TIE| KIE| WDE| WDS|                  | ControlB       |
;  +---+-----+-----+----+----+----+----+----+----+------------------+----------------+
;  |10 |           Extended RAM Address          |            00-FF | RAM Address    |
;  +---+-----+-----+----+----+----+----+----+----+------------------+----------------+
;  |11 |                 Reserved                |                  |                |
;  +---+-----+-----+----+----+----+----+----+----+------------------+----------------+
;  |12 |                 Reserved                |                  |                |
;  +---+--+--+-----+----+----+----+----+----+----+------------------+----------------+
;  |13 |             Extended RAM Data           |            00-FF | RAM Data       |
;  +---+--+--+-----+----+----+----+----+----+----+------------------+----------------+
;  |14-1F |              Reserved                |                  |                |
;  +------+--+-----+----+----+----+----+----+----+------------------+----------------+

;  * = Unused bits; unwritable and read as 0.
;  0 = should be set to 0 for valid time/calendar range.
;  Clock calendar data is BCD. Automatic leap year adjustment.
;  Day-Of-Week coded as Sunday = 1 through Saturday = 7.

; Constants

;By defining 2 bases, this allows some flexibility for address decoding
DS1501NVM_BASE      .EQU    DS1501RTC_BASE + $10

DS1501RTC_SEC	    .EQU	DS1501RTC_BASE + $00
DS1501RTC_MIN	    .EQU	DS1501RTC_BASE + $01
DS1501RTC_HOUR	    .EQU	DS1501RTC_BASE + $02
DS1501RTC_WEEK_DAY	.EQU	DS1501RTC_BASE + $03
DS1501RTC_DAY	    .EQU	DS1501RTC_BASE + $04
DS1501RTC_MONTH	    .EQU	DS1501RTC_BASE + $05
DS1501RTC_YEAR	    .EQU	DS1501RTC_BASE + $06
DS1501RTC_CENT      .EQU	DS1501RTC_BASE + $07
DS1501RTC_SEC_ALM	.EQU	DS1501RTC_BASE + $08
DS1501RTC_MIN_ALM	.EQU	DS1501RTC_BASE + $09
DS1501RTC_HOUR_ALM	.EQU	DS1501RTC_BASE + $0A
DS1501RTC_DAY_ALM	.EQU	DS1501RTC_BASE + $0B
DS1501RTC_WDOG1     .EQU	DS1501RTC_BASE + $0C
DS1501RTC_WDOG2 	.EQU	DS1501RTC_BASE + $0D
DS1501RTC_CONTROLA	.EQU	DS1501RTC_BASE + $0E
DS1501RTC_CONTROLB	.EQU	DS1501RTC_BASE + $0F

DS1501RTC_RAMADDR	.EQU	DS1501NVM_BASE + $00
DS1501RTC_RAMDATA	.EQU	DS1501NVM_BASE + $03

DS1501RTC_HIGH	.EQU	%11110000
DS1501RTC_LOW	.EQU	%00001111

;ControlA bit masks
;BLF1| BLF2| PRS| PAB| TDF| KSF| WDF|IRQF
DS1501RTC_IRQF	.EQU	%00000001
DS1501RTC_WDF	.EQU	%00000010
DS1501RTC_KSF	.EQU	%00000100
DS1501RTC_TDF	.EQU	%00001000
DS1501RTC_PAB	.EQU	%00010000
DS1501RTC_PRS 	.EQU	%00100000
DS1501RTC_BLF2  .EQU	%01000000
DS1501RTC_BLF1	.EQU	%10000000

;ControlB bit masks
;TE| CS| BME| TPE| TIE| KIE| WDE| WDS|
DS1501RTC_WDS 	.EQU	%00000001
DS1501RTC_WDE	.EQU	%00000010
DS1501RTC_KIE	.EQU	%00000100
DS1501RTC_TIE	.EQU	%00001000
DS1501RTC_TPE	.EQU	%00010000
DS1501RTC_BME 	.EQU	%00100000
DS1501RTC_CS    .EQU	%01000000
DS1501RTC_TE	.EQU	%10000000

DS1501RTC_BUFSIZE	.EQU	6		; 6 BYTE BUFFER (YYMMDDHHMMSS)

; RTC Device Initialization Entry

DS1501RTC_INIT:
	CALL	NEWLINE				; Formatting
	PRTS("DS1501RTC: IO=0x$")
	LD	A, DS1501RTC_BASE
	CALL	PRTHEXBYTE

	CALL	NEWLINE				; Formatting
	PRTS("DS1501NVM: IO=0x$")
	LD	A, DS1501NVM_BASE
	CALL	PRTHEXBYTE

    IN	A,(DS1501RTC_CONTROLB)      ;clear any pending interrupt flags

	XOR	A				; Zero A
    OR      DS1501RTC_TE            ;enable time updates
    OUT	(DS1501RTC_CONTROLB), A

	CALL	DS1501RTC_LOAD
	; DISPLAY CURRENT TIME
	PRTS("  $")
	LD	A, (DS1501RTC_BUF_MON)
	CALL	PRTHEXBYTE
	PRTS("/$")
	LD	A, (DS1501RTC_BUF_DAY)
	CALL	PRTHEXBYTE
	PRTS("/$")
	LD	A, (DS1501RTC_BUF_YEAR)
	CALL	PRTHEXBYTE
	PRTS(" $")
	LD	A, (DS1501RTC_BUF_HOUR)
	CALL	PRTHEXBYTE
	PRTS(":$")
	LD	A, (DS1501RTC_BUF_MIN)
	CALL	PRTHEXBYTE
	PRTS(":$")
	LD	A, (DS1501RTC_BUF_SEC)
	CALL	PRTHEXBYTE

	LD	BC,DS1501RTC_DISPATCH
	CALL	RTC_SETDISP

	XOR	A				; Signal success
	RET

; RTC Device Function Dispatch Entry
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   B: Function (IN)

DS1501RTC_DISPATCH:
	LD	A, B				; Get requested function
	AND	$0F				; Isolate Sub-Function
	JP	Z, DS1501RTC_GETTIM			; Get Time
	DEC	A
	JP	Z, DS1501RTC_SETTIM			; Set Time
	DEC	A
	JP	Z, DS1501RTC_GETBYT			; Get NVRAM Byte Value
	DEC	A
	JP	Z, DS1501RTC_SETBYT			; Set NVRAM Byte Value
	DEC	A
	JP	Z, DS1501RTC_GETBLK			; Get NVRAM Data Block Value
	DEC	A
	JP	Z, DS1501RTC_SETBLK			; Set NVRAM Data Block Value
	DEC	A
	JP	Z, DS1501RTC_GETALM			; Get Alarm
	DEC	A
	JP	Z, DS1501RTC_SETALM			; Set Alarm
;
; NVRAM FUNCTIONS ARE NOT IMPLEMENTED YET
;
DS1501RTC_GETBYT:
DS1501RTC_SETBYT:
DS1501RTC_GETBLK:
DS1501RTC_SETBLK:
	CALL	PANIC

; RTC Get Time
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   HL: Date/Time Buffer (OUT)
; Buffer format is BCD: YYMMDDHHMMSS
; 24 hour time format is assumed
;
DS1501RTC_GETTIM:
	EX	DE, HL
	CALL	DS1501RTC_LOAD
	; Now copy to read destination (Interbank Save)
	LD	A, BID_BIOS			; Copy from BIOS bank
	LD	(HB_SRCBNK), A			; Set it
	LD	A, (HB_INVBNK)			; Copy to current user bank
	LD	(HB_DSTBNK), A			; Set it
	LD	BC, DS1501RTC_BUFSIZE		; Length is 6 bytes
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
DS1501RTC_SETTIM:
;
	; Copy incoming time data to our time buffer
	LD	A, (HB_INVBNK)			; Copy from current user bank
	LD	(HB_SRCBNK), A			; Set it
	LD	A, BID_BIOS			; Copy to BIOS bank
	LD	(HB_DSTBNK), A			; Set it
	LD	DE, DS1501RTC_BUF			; Destination Address
	LD	BC, DS1501RTC_BUFSIZE		; Length is 6 bytes
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
	; Write to clock
	LD	HL, DS1501RTC_BUF
	CALL	DS1501RTC_SUSPEND
	LD	A, (HL)
	OUT	(DS1501RTC_YEAR), A			; Write Year
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_MONTH), A		; Write Month
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_DAY), A			; Write Day
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_HOUR), A			; Write Hour
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_MIN), A			; Write Minute
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_SEC), A			; Write Second
	CALL	DS1501RTC_RESUME
	; clean up and return
	XOR	A				; Signal success
	RET					; And return

; RTC Get Alarm
;   A: Result (OUT), 0=OK, Z=OK, NZ=Error
;   HL: Date/Time Buffer (OUT)
; Buffer format is BCD: YYMMDDHHMMSS
; 24 hour time format is assumed
;
DS1501RTC_GETALM:
	EX	DE, HL
	LD	HL, DS1501RTC_BUF
	PUSH	HL				; Save address of source buffer
	CALL	DS1501RTC_SUSPEND
	XOR	A
	LD	(HL), A				; Read Year
	INC	HL
	LD	(HL), A				; Read Month
	INC	HL
	IN	A, (DS1501RTC_DAY_ALM)		; Read Day
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_HOUR_ALM)		; Read Hour
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_MIN_ALM)		; Read Minute
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_SEC_ALM)		; Read Second
	LD	(HL), A
	CALL	DS1501RTC_RESUME
	POP	HL				; Restore address of source buffer
	; Now copy to read destination (Interbank Save)
	LD	A, BID_BIOS			; Copy from BIOS bank
	LD	(HB_SRCBNK), A			; Set it
	LD	A, (HB_INVBNK)			; Copy to current user bank
	LD	(HB_DSTBNK), A			; Set it
	LD	BC, DS1501RTC_BUFSIZE		; Length is 6 bytes
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
DS1501RTC_SETALM:
	; Copy incoming time data to our time buffer
	LD	A, (HB_INVBNK)			; Copy from current user bank
	LD	(HB_SRCBNK), A			; Set it
	LD	A, BID_BIOS			; Copy to BIOS bank
	LD	(HB_DSTBNK), A			; Set it
	LD	DE, DS1501RTC_BUF			; Destination Address
	LD	BC, DS1501RTC_BUFSIZE		; Length is 6 bytes
#IF (INTMODE == 1)
	DI
#ENDIF
	CALL	HB_BNKCPY			; Copy the clock data
#IF (INTMODE == 1)
	EI
#ENDIF
	; Write to clock
	LD	HL, DS1501RTC_BUF_DAY
	CALL	DS1501RTC_SUSPEND
	LD	A, (HL)
	OUT	(DS1501RTC_DAY_ALM), A		; Write Day
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_HOUR_ALM), A		; Write Hour
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_MIN_ALM), A		; Write Minute
	INC	HL
	LD	A, (HL)
	OUT	(DS1501RTC_SEC_ALM), A		; Write Second
	CALL	DS1501RTC_RESUME
	; clean up and return
	XOR	A				; Signal success
	RET					; And return

DS1501RTC_SUSPEND:
	IN	A, (DS1501RTC_CONTROLB)		; Suspend Clock
	AND	~DS1501RTC_TE
	OUT	(DS1501RTC_CONTROLB), A
	RET

DS1501RTC_RESUME:
	IN	A, (DS1501RTC_CONTROLB)		; Resume Clock
	OR	DS1501RTC_TE
	OUT	(DS1501RTC_CONTROLB), A
	RET

DS1501RTC_LOAD:
	LD	HL, DS1501RTC_BUF
	PUSH	HL				; Save address of source buffer
	CALL	DS1501RTC_SUSPEND
	IN	A, (DS1501RTC_YEAR)			; Read Year
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_MONTH)		; Read Month
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_DAY)			; Read Day
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_HOUR)			; Read Hour
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_MIN)			; Read Minute
	LD	(HL), A
	INC	HL
	IN	A, (DS1501RTC_SEC)			; Read Second
	LD	(HL), A
	CALL	DS1501RTC_RESUME
	POP	HL				; Restore address of source buffer
	RET

; Working Variables

DS1501RTC_BUF:
DS1501RTC_BUF_YEAR:	.DB	0		; Year
DS1501RTC_BUF_MON:	.DB	0		; Month
DS1501RTC_BUF_DAY:	.DB	0		; Day
DS1501RTC_BUF_HOUR:	.DB	0		; Hour
DS1501RTC_BUF_MIN:	.DB	0		; Minute
DS1501RTC_BUF_SEC:	.DB	0		; Second
