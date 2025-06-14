;
;==================================================================================================
; CENTRONICS (LPT) INTERFACE DRIVER
;==================================================================================================
;
; CENTRONICS-STYLE PARALLEL PRINTER DRIVER.
;
; IMPLEMENTED AS A ROMWBW CHARACTER DEVICE.  CURRENTLY HANDLES OUPUT
; ONLY.
;
;==================================================================================================
;
;  IBM PC STANDARD PARALLEL PORT (SPP):
;  - NHYODYNE PRINT MODULE
;
;  PORT 0 (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | PD7   | PD6   | PD5   | PD4   | PD3   | PD2   | PD1   | PD0   |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  PORT 1 (INPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | /BUSY | /ACK  | POUT  | SEL   | /ERR  | 0     | 0     | 0     |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  PORT 2 (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | STAT1 | STAT0 | ENBL  | PINT  | SEL   | RES   | LF    | STB   |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;==================================================================================================
;
;  MG014 STYLE INTERFACE:
;  - RCBUS MG014 MODULE
;
;  PORT 0 (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | PD7   | PD6   | PD5   | PD4   | PD3   | PD2   | PD1   | PD0   |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  PORT 1 (INPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     |       |       |       | /ERR  | SEL   | POUT  | BUSY  | /ACK  |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  PORT 2 (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | LED   |	      |	      |	      | /SEL  | /RES  | /LF   | /STB  |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;==================================================================================================
;
;  S100 STYLE INTERFACE:
;  - S100 FPGA Z80
;
;  BASE I/O PORT (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | PD7   | PD6   | PD5   | PD4   | PD3   | PD2   | PD1   | PD0   |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  STATUS PORT (INPUT, BASE I/O - 1):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     |       |       |       |       |       |       | BUSY  | /ACK  |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  CONTROL PORT (OUTPUT, BASE I/O - 1):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     |       |       |       |       |       |       |       | /STB  |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;==================================================================================================
;
LPT_INIT:
	LD	B,LPT_CFGCNT		; LOOP CONTROL
	XOR	A			; ZERO TO ACCUM
	LD	(LPT_DEV),A		; CURRENT DEVICE NUMBER
	LD	IY,LPT_CFG		; POINT TO START OF CFG TABLE
LPT_INIT0:
	PUSH	BC			; SAVE LOOP CONTROL
	CALL	LPT_PRTCFG		; PRINT CONFIG
	CALL	LPT_INITUNIT		; HAND OFF TO UNIT INIT CODE
	POP	BC			; RESTORE LOOP CONTROL
;
	JR	Z,LPT_INIT1		; IF DETECTED, CONTINUE INIT
	CALL	PC_SPACE		; FORMATTING
	LD	DE,LPT_STR_NOLPT	; NO LPT MESSAGE
	CALL	WRITESTR		; DISPLAY IT
	JR	LPT_INIT2		; AND LOOP AS NEEDED
;
LPT_INIT1:
	LD	A,(IY+1)		; GET THE LPT TYPE
	OR	A			; SET FLAGS
	JR	Z,LPT_INIT2		; SKIP IT IF NOTHING FOUND
;
	PUSH	BC			; SAVE LOOP CONTROL
	PUSH	IY			; CFG ENTRY ADDRESS
	POP	DE			; ... TO DE
	LD	BC,LPT_FNTBL		; BC := FUNCTION TABLE ADDRESS
	CALL	NZ,CIO_ADDENT		; ADD ENTRY IF LPT FOUND, BC:DE
	POP	BC			; RESTORE LOOP CONTROL
;
LPT_INIT2:
	LD	DE,LPT_CFGSIZ		; SIZE OF CFG ENTRY
	ADD	IY,DE			; BUMP IY TO NEXT ENTRY
	DJNZ	LPT_INIT0		; LOOP UNTIL DONE
;
LPT_INIT3:
	XOR	A			; SIGNAL SUCCESS
	RET				; AND RETURN
;
; LPT INITIALIZATION ROUTINE
;
LPT_INITUNIT:
	CALL	LPT_DETECT		; DETERMINE LPT TYPE
	RET	NZ			; ABORT IF NOTHING THERE
;
	; UPDATE WORKING LPT DEVICE NUM
	LD	HL,LPT_DEV		; POINT TO CURRENT DEVICE NUM
	LD	A,(HL)			; PUT IN ACCUM
	INC	(HL)			; INCREMENT IT (FOR NEXT LOOP)
	LD	(IY),A			; UPDATE UNIT NUM
;
	; SET DEFAULT CONFIG
	LD	DE,-1			; LEAVE CONFIG ALONE
	JP	LPT_INITDEV		; IMPLEMENT IT AND RETURN
;
; DRIVER FUNCTION TABLE
;
LPT_FNTBL:
	.DW	LPT_IN
	.DW	LPT_OUT
	.DW	LPT_IST
	.DW	LPT_OST
	.DW	LPT_INITDEV
	.DW	LPT_QUERY
	.DW	LPT_DEVICE
#IF (($ - LPT_FNTBL) != (CIO_FNCNT * 2))
	.ECHO	"*** INVALID LPT FUNCTION TABLE ***\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
; BYTE INTPUT
;
LPT_IN:
	; INPUT NOT SUPPORTED - RETURN NULL BYTE
	LD	E,0			; NULL BYTE
	XOR	A			; SIGNAL SUCCESS
	RET
;
; BYTE OUTPUT
;
LPT_OUT:
	CALL	LPT_OST			; READY TO SEND?
	JR	Z,LPT_OUT		; LOOP IF NOT
	LD	C,(IY+3)		; PORT 0 (DATA)
	EZ80_IO
	OUT	(C),E			; OUTPUT DATA TO PORT
#IF (LPTMODE == LPTMODE_SPP)
	LD	A,%00001101		; SELECT & STROBE, LEDS OFF
#ENDIF
#IF (LPTMODE == LPTMODE_MG014)
	LD	A,%00000100		; SELECT & STROBE, LED OFF
#ENDIF
#IF (LPTMODE == LPTMODE_S100)
	LD	A,%00000000		; STROBE
#ENDIF
#IF ((LPTMODE == LPTMODE_SPP) | (LPTMODE == LPTMODE_MG014))
	INC	C			; PUT CONTROL PORT IN C
	INC	C
#ENDIF
#IF (LPTMODE == LPTMODE_S100)
	DEC	C			; PUT CONTROL PORT IN C
#ENDIF
	EZ80_IO
	OUT	(C),A			; OUTPUT DATA TO PORT
	CALL	DELAY
#IF (LPTMODE == LPTMODE_SPP)
	LD	A,%00001100		; SELECT, LEDS OFF
#ENDIF
#IF (LPTMODE == LPTMODE_MG014)
	LD	A,%00000101		; SELECT, LED OFF
#ENDIF
#IF (LPTMODE == LPTMODE_S100)
	LD	A,%11111111		; STROBE
#ENDIF
	EZ80_IO
	OUT	(C),A			; OUTPUT DATA TO PORT
	CALL	DELAY
	XOR	A			; SIGNAL SUCCESS
	RET
;
; INPUT STATUS
;
LPT_IST:
	; INPUT NOT SUPPORTED - RETURN NOT READY
	XOR	A			; ZERO BYTES AVAILABLE
	RET				; DONE
;
; OUTPUT STATUS
;
LPT_OST:
	LD	C,(IY+3)		; BASE PORT
#IF ((LPTMODE == LPTMODE_SPP) | (LPTMODE == LPTMODE_MG014))
	INC	C			; SELECT STATUS PORT
#ENDIF
#IF (LPTMODE == LPTMODE_S100)
	DEC	C			; SELECT STATUS PORT
#ENDIF
	EZ80_IO
	IN	A,(C)			; GET STATUS INFO
#IF (LPTMODE == LPTMODE_SPP)
	AND	%10000000		; ISOLATE /BUSY
#ENDIF
#IF (LPTMODE == LPTMODE_MG014)
	AND	%00000010		; ISOLATE BUSY
	XOR	%00000010		; INVERT TO READY
#ENDIF
	RET				; DONE
;
; INITIALIZE DEVICE
;
LPT_INITDEV:
	; INTERRUPTS DISABLED DURING INIT
	; ??? IS THIS NEEDED?
	HB_DI				; AVOID CONFLICTS
	CALL	LPT_INITDEV0		; DO THE REAL WORK
	HB_EI				; INTS BACK ON
	RET				; DONE
;
; THIS ENTRY POINT BYPASSES DISABLING/ENABLING INTS WHICH IS REQUIRED BY
; PREINIT ABOVE.  PREINIT IS NOT ALLOWED TO ENABLE INTS!
;
LPT_INITDEV0:
;
#IF (LPTMODE == LPTMODE_SPP)
;
	LD	C,(IY+3)		; PORT 0 (DATA)
	XOR	A			; CLEAR ACCUM
	EZ80_IO
	OUT	(C),A			; SEND IT
	INC	C			; BUMP TO
	INC	C			; ... PORT 2
	LD	A,%00001000		; SELECT AND ASSERT RESET, LEDS OFF
	EZ80_IO
	OUT	(C),A			; SEND IT
	CALL	LDELAY			; HALF SECOND DELAY
	LD	A,%00001100		; SELECT AND DEASSERT RESET, LEDS OFF
	EZ80_IO
	OUT	(C),A			; SEND IT
	XOR	A			; SIGNAL SUCCESS
	RET				; RETURN
;
#ENDIF
;
#IF (LPTMODE == LPTMODE_MG014)
	LD	A,(IY+3)		; BASE PORT
	ADD	A,3			; BUMP TO CONTROL PORT
	LD	C,A			; MOVE TO C FOR I/O
	LD	A,$82			; CONFIG A OUT, B IN, C OUT
	EZ80_IO
	OUT	(C),A			; DO IT
	DEC	C			; OUTPUT PORT
	LD	A,$81			; STROBE OFF, SELECT ON, RES ON, LED ON
	EZ80_IO
	OUT	(C),A			; SEND IT
	CALL	LDELAY			; HALF SECOND DELAY
	LD	A,$05			; STROBE OFF, SELECT ON, RES OFF, LED OFF
	EZ80_IO
	OUT	(C),A			; SEND IT
	XOR	A			; SIGNAL SUCCESS
	RET				; RETURN
#ENDIF
;
#IF (LPTMODE == LPTMODE_S100)
	LD	C,(IY+3)		; BASE PORT
	DEC	C			; DEC TO CONTROL PORT
	LD	A,$FF			; INIT VALUE
	EZ80_IO
	OUT	(C),A			; DO IT
	RET				; RETURN
#ENDIF
;
;
;
LPT_QUERY:
	LD	E,(IY+4)		; FIRST CONFIG BYTE TO E
	LD	D,(IY+5)		; SECOND CONFIG BYTE TO D
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;
;
LPT_DEVICE:
	LD	D,CIODEV_LPT		; D := DEVICE TYPE
	LD	E,(IY)			; E := PHYSICAL UNIT
	LD	C,$40			; C := DEVICE TYPE, 0x40 IS PIO
	LD	H,(IY+1)		; H := MODE
	LD	L,(IY+3)		; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
; LPT DETECTION ROUTINE
;
#IF (LPTMODE == LPTMODE_NONE)
;
LPT_DETECT:
	LD	A,LPTMODE_NONE		; NOTHING TO DETECT
	RET
;
#ENDIF
;
#IF (LPTMODE == LPTMODE_SPP)
;
LPT_DETECT:
	LD	C,(IY+3)		; BASE PORT ADDRESS
	JR	LPT_DETECT2		; CHECK IT
;
LPT_DETECT2:
	; LOOK FOR LPT AT BASE PORT ADDRESS IN C
	INC	C			; PORT C FOR I/O
	INC	C			; ...
	XOR	A			; DEFAULT VALUE (TRI-STATE OFF)
	EZ80_IO
	OUT	(C),A			; SEND IT
;
	;IN	A,(C)			; READ IT
	;AND	%11000000		; ISOLATE STATUS BITS
	;CP	%00000000		; CORRECT VALUE?
	;RET	NZ			; IF NOT, RETURN
	;LD	A,%11000000		; STATUS BITS ON (LEDS OFF)
	;OUT	(C),A			; SEND IT
	;IN	A,(C)			; READ IT
	;AND	%11000000		; ISOLATE STATUS BITS
	;CP	%11000000		; CORRECT VALUE?
;
	DEC	C			; BACK TO BASE PORT
	DEC	C			; ...
	LD	A,$A5			; TEST VALUE
	EZ80_IO
	OUT	(C),A			; SEND IT
	EZ80_IO
	IN	A,(C)			; READ IT BACK
	CP	$A5			; CORRECT?
	RET				; RETURN (ZF SET CORRECTLY)
;
#ENDIF
;
#IF (LPTMODE == LPTMODE_MG014)
LPT_DETECT:
;
	; TEST FOR PPI EXISTENCE
	; WE SETUP THE PPI TO WRITE, THEN WRITE A VALUE OF $A5
	; TO PORT A (DATALO), THEN READ IT BACK.  IF THE PPI IS THERE
	; THEN THE BUS HOLD CIRCUITRY WILL READ BACK THE $A5. SINCE
	; WE ARE IN WRITE MODE, AN IDE CONTROLLER WILL NOT BE ABLE TO
	; INTERFERE WITH THE VALUE BEING READ.
;
	LD	A,(IY+3)		; BASE IO ADDRESS
	ADD	A,3			; BUMP TO CONTROL PORT
	LD	C,A			; PUT IN C
	LD	A,$80			; SET PORT A TO WRITE
	EZ80_IO
	OUT	(C),A			; WRITE IT
;
	LD	C,(IY+3)		; PPI PORT A
	LD	A,$A5			; TEST VALUE
	EZ80_IO
	OUT	(C),A			; PUSH VALUE TO PORT
	EZ80_IO
	IN	A,(C)			; GET PORT VALUE
  #IF (LPTTRACE >= 3)
	CALL	PC_SPACE
	CALL	PRTHEXBYTE
  #ENDIF
	CP	$A5			; CHECK FOR TEST VALUE
	RET				; ZF SET IF DETECTED
#ENDIF
;
#IF (LPTMODE == LPTMODE_S100)
LPT_DETECT:
	; PORT ALWAYS EXISTS ON FPGA
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
#ENDIF
;
;
;
LPT_PRTCFG:
	; ANNOUNCE PORT
	CALL	NEWLINE			; FORMATTING
	PRTS("LPT$")			; FORMATTING
	LD	A,(IY+2)		; DEVICE NUM
	CALL	PRTDECB			; PRINT DEVICE NUM
	PRTS(": IO=0x$")		; FORMATTING
	LD	A,(IY+3)		; GET BASE PORT
	CALL	PRTHEXBYTE		; PRINT BASE PORT

	; PRINT THE LPT TYPE
	PRTS(" MODE=$")			; FORMATTING
	LD	A,(IY+1)		; GET LPT TYPE BYTE
	RLCA				; MAKE IT A WORD OFFSET
	LD	HL,LPT_TYPE_MAP		; POINT HL TO TYPE MAP TABLE
	CALL	ADDHLA			; HL := ENTRY
	LD	E,(HL)			; DEREFERENCE
	INC	HL			; ...
	LD	D,(HL)			; ... TO GET STRING POINTER
	CALL	WRITESTR		; PRINT IT
;
	; ALL DONE IF NO LPT WAS DETECTED
	LD	A,(IY+1)		; GET LPT TYPE BYTE
	OR	A			; SET FLAGS
	RET	Z			; IF ZERO, NOT PRESENT
;
	; *** ADD MORE DEVICE INFO??? ***
;
	XOR	A
	RET
;
;
;
LPT_TYPE_MAP:
		.DW	LPT_STR_NONE
		.DW	LPT_STR_SPP
		.DW	LPT_STR_MG014
		.DW	LPT_STR_S100
;
LPT_STR_NONE	.DB	"???$"
LPT_STR_SPP	.DB	"SPP$"
LPT_STR_MG014	.DB	"MG014$"
LPT_STR_S100	.DB	"S100$"
;
LPT_STR_NOLPT	.DB	"NOT PRESENT$"
;
; WORKING VARIABLES
;
LPT_DEV		.DB	0		; DEVICE NUM USED DURING INIT
;
; LPT DEVICE CONFIGURATION TABLE
;
LPT_CFG:
;
LPT0_CFG:
	; LPT MODULE A CONFIG
	.DB	0			; DEVICE NUMBER (SET DURING INIT)
	.DB	LPTMODE			; LPT MODE
	.DB	0			; MODULE ID
	.DB	LPT0BASE		; BASE PORT
	.DW	0			; LINE CONFIGURATION
;
	DEVECHO	"LPT: MODE="
  #IF (LPTMODE == LPTMODE_SPP)
	DEVECHO	"SPP"
  #ENDIF
  #IF (LPTMODE == LPTMODE_MG014)
	DEVECHO	"MG014"
  #ENDIF
  #IF (LPTMODE == LPTMODE_S100)
	DEVECHO	"S100"
  #ENDIF
	DEVECHO	", IO="
	DEVECHO	LPT0BASE
	DEVECHO	"\n"
;
LPT_CFGSIZ	.EQU	$ - LPT_CFG	; SIZE OF ONE CFG TABLE ENTRY
;
#IF (LPTCNT >= 2)
;
LPT1_CFG:
	; LPT MODULE B CONFIG
	.DB	0			; DEVICE NUMBER (SET DURING INIT)
	.DB	LPTMODE			; LPT MODE
	.DB	1			; MODULE ID
	.DB	LPT1BASE		; BASE PORT
	.DW	0			; LINE CONFIGURATION
;
	DEVECHO	"LPT: MODE="
  #IF (LPTMODE == LPTMODE_SPP)
	DEVECHO	"SPP"
  #ENDIF
  #IF (LPTMODE == LPTMODE_MG014)
	DEVECHO	"MG014"
  #ENDIF
  #IF (LPTMODE == LPTMODE_S100)
	DEVECHO	"S100"
  #ENDIF
	DEVECHO	", IO="
	DEVECHO	LPT1BASE
	DEVECHO	"\n"
;
#ENDIF
;
LPT_CFGCNT	.EQU	($ - LPT_CFG) / LPT_CFGSIZ
