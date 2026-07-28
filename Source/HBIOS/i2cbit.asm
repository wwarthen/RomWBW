;==================================================================================================
; BITBANGED I2C BUS MASTER
; BASED ON THE WORK OF STEPHEN C COUSINS
; https://smallcomputercentral.com/scm-apps/scm-app-i2c-demo-version-2-2/
;
; DROP IN REPLACEMENT FOR PCF.ASM ON BOARDS WITH NO REAL PCF8584 CHIP
; SC137 "I2C BUS MASTER MODULE (RC2014)"
; SC608 "RCBUS I2C BUS MASTER"
; SC704 "RCBUS I2C BUS MASTER"
; SELECTED VIA I2CBITENABLE MUTUALLY EXCLUSIVE WITH PCFENABLE
;
; SAME PUBLIC LABELS AS PCF.ASM SO LCDI2C.ASM/DS7RTC.ASM
; RUN UNMODIFIED AGAINST EITHER BACKEND.
;
; NO DELAY WAS USED ANYWHERE AS WITH THE NORMAL CLOCK 7.372MHZ
; THE SCL LIMIT OF 90KHZ OF THE I2C STANDARD IS NOT REACHED
;
; FIXME
; FOR SYSTEMS WITH HIGHER CLOCK SPEEDS A DELAY WILL NEED TO BE ADDED
;
; **********************************************************************
; **********************************************************************
; I2C bus master driver
; Source Stephen C Cousins
; **********************************************************************
; **********************************************************************
;
; I2C transfer sequence
;   +-------+  +---------+  +---------+     +---------+  +-------+
;   | Start |  | Address |  | Data    | ... | Data    |  | Stop  |
;   |       |  | frame   |  | frame 1 |     | frame N |  |       |
;   +-------+  +---------+  +---------+     +---------+  +-------+
;
; Start condition                     Stop condition
; Output by master device             Output by master device
;       ----+                                      +----
; SDA       |                         SDA          |
;           +-------                        -------+
;       -------+                                +-------
; SCL          |                      SCL       |
;              +----                        ----+
;
; Address frame
; Clock and data output from master device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | A 7 | A 6 | A 5 | A 4 | A 3 | A 2 | A 1 | R/W | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;
;
; Data frame 
; Clock output by master device
; Data output by transmitting device
; Receiving device outputs acknowledge 
;        +-----+-----+-----+-----+-----+-----+-----+-----+     +---+
; SDA    | D 7 | D 6 | D 5 | D 4 | D 3 | D 2 | D 1 | D 0 | ACK |   |
;     ---+-----+-----+-----+-----+-----+-----+-----+-----+-----+   +---
;          +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+   +-+
; SCL      | |   | |   | |   | |   | |   | |   | |   | |   | |
;     -----+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---+ +---------
;

I2CBIT_BASE	.EQU	I2CBITBASE
I2CBIT_SDA	.EQU	7		; SDA BIT NUMBER, READ AND WRITE
I2CBIT_SCL	.EQU	0		; SCL BIT NUMBER, READ AND WRITE
I2CBIT_QUIES	.EQU	10000001B	; BOTH LINES IDLE HIGH
;
; SAME BIT POSITION AS THE REAL PCF8584'S LRB
; SO PCF_WAIT_FOR_ACK'S Z/NZ CONTRACT MATCHES PCF.ASM
; NO REAL STATUS REGISTER BEHIND IT HERE
;
PCF_LRB		.EQU	00001000B
;
	DEVECHO	"I2CBIT: IO="
	DEVECHO	I2CBIT_BASE
	DEVECHO	"\n"
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_I2CBIT	.EQU	$
;
	.DW	SIZ_I2CBIT		; MODULE SIZE
	.DW	I2CBIT_INITPHASE	; ADR OF INIT PHASE HANDLER
;
I2CBIT_INITPHASE:
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,PCF_INIT		; DO INIT
	RET				; DONE
;
;-----------------------------------------------------------------------------
; NO REAL CHIP TO PROBE
; TOGGLE SDA BOTH WAYS AND CONFIRM READBACK
; A STATIC COMPARE CAN'T TELL FLOATING FROM WIRED
; SCL STAYS HIGH THROUGHOUT
;
PCF_INIT:
	CALL	NEWLINE
	PRTS("I2CBIT: IO=0x$")
	LD	A,I2CBIT_BASE
	CALL	PRTHEXBYTE
	CALL	PC_SPACE
;
	LD	A,I2CBIT_QUIES
	OUT	(I2CBIT_BASE),A
	CALL	DELAY
;
	RES	I2CBIT_SDA,A		; SDA LOW, SCL STAYS HIGH (A ALREADY QUIES)
	OUT	(I2CBIT_BASE),A
	IN	A,(I2CBIT_BASE)
	BIT	I2CBIT_SDA,A
	JR	NZ,PCF_FAIL		; SDA DIDN'T GO LOW
	LD	A,I2CBIT_QUIES		; SDA HIGH AGAIN, BOTH BACK TO IDLE
	OUT	(I2CBIT_BASE),A
	IN	A,(I2CBIT_BASE)
	BIT	I2CBIT_SDA,A
	JR	Z,PCF_FAIL		; SDA DIDN'T GO HIGH
	XOR	A
	RET
;
PCF_FAIL:
	CALL	PCF_INIERR
	LD	A,ERR_NOHW
	LD	(PCF_FAIL_FLAG),A
	RET
;
PCF_FAIL_FLAG:
	.DB	0
;
;-----------------------------------------------------------------------------
; GENERATE START CONDITION AND SHIFT THE ADDRESS BYTE (A ON ENTRY)
; REAL PCF8584 DOES THIS AUTONOMOUSLY AFTER S0/S1 ARE WRITTEN
; BITBANGED, BOTH HALVES HAPPEN HERE, SYNCHRONOUSLY
;
PCF_START_ADDR:
	LD	(PCF_XMIT),A
PCF_START:
	LD	A,I2CBIT_QUIES		; ENSURE BOTH IDLE HIGH FIRST, REGARDLESS OF
	OUT	(I2CBIT_BASE),A		; PRIOR STATE (SAME RESULT AS SDA_HI THEN SCL_HI)
	RES	I2CBIT_SDA,A		; START: SDA FALLS WHILE SCL STAYS HIGH
	OUT	(I2CBIT_BASE),A
	RES	I2CBIT_SCL,A		; SCL FALLS TOO, BOTH LOW NOW
	OUT	(I2CBIT_BASE),A
	LD	A,(PCF_XMIT)		; SHIFT WHATEVER'S BUFFERED, MATCHES REAL
	JP	PCF_SHIFTOUT		; HARDWARE'S "RESEND LAST S0 BYTE" BEHAVIOR
;
;-----------------------------------------------------------------------------
; REPEATED START, NO BYTE SHIFT
;
PCF_REPSTART:
	LD	A,1
	LD	(PCF_RD_DUMMY),A
	LD	A,I2CBIT_QUIES
	OUT	(I2CBIT_BASE),A
	RES	I2CBIT_SDA,A		; REPEATED START: SDA FALLS WHILE SCL STAYS HIGH
	OUT	(I2CBIT_BASE),A
	RES	I2CBIT_SCL,A
	OUT	(I2CBIT_BASE),A
	RET
;
;-----------------------------------------------------------------------------
; STOP CONDITION
;
PCF_STOP:
	XOR	A			; SDA=0, SCL=0, SCL ALREADY LOW HERE
	OUT	(I2CBIT_BASE),A
	SET	I2CBIT_SCL,A
	OUT	(I2CBIT_BASE),A
	SET	I2CBIT_SDA,A		; STOP: SDA RISES WHILE SCL STAYS HIGH
	OUT	(I2CBIT_BASE),A
	RET
;
;-----------------------------------------------------------------------------
; PUT ONE BYTE ON THE BUS, NO ACK CHECK
;
PCF_PUTBYTE:
	JP	PCF_SHIFTOUT
;
;-----------------------------------------------------------------------------
; PUT ONE BYTE, FALLS THROUGH TO PCF_WAIT_FOR_PIN
;
PCF_PUTBYTE_PIN:
	CALL	PCF_SHIFTOUT
;
; NO SHIFT REGISTER TO POLL, FALLS INTO THE REAL ACK CHECK
;
PCF_WAIT_FOR_PIN:
	JR	PCF_WAIT_FOR_ACK
;
;-----------------------------------------------------------------------------
; PUT ONE BYTE, FALLS THROUGH TO THE ACK CHECK
;
PCF_PUTBYTE_ACK:
	CALL	PCF_SHIFTOUT
;	FALLS THROUGH
;
; RETURN Z/A=0 IF ACK RECEIVED, NZ/A=1 IF NOT.
;
PCF_WAIT_FOR_ACK:
	LD	A,(PCF_STATUS)
	AND	PCF_LRB
	RET	Z
	LD	A,1
	OR	A
	RET
;
;-----------------------------------------------------------------------------
; NO REAL BUS BUSY REGISTER ON A BITBANGED SINGLE MASTER BUS, ALWAYS FREE.
;
PCF_WAIT_FOR_BB:
	XOR	A
	RET
;
;-----------------------------------------------------------------------------
; READ PATH
; PCF_GETBYTE AND PCF_READI2C SHARE ONE BODY, SAME COLLAPSE AS
; PCF_PUTBYTE_PIN ABOVE
;
PCF_GETBYTE:
PCF_READI2C:
	LD	A,(PCF_RD_DUMMY)	; DUMMY READ ARMED BY PCF_REPSTART?
	OR	A
	JR	Z,PCF_CLOCKIN
	XOR	A			; YES, CONSUME IT, NO BUS ACTIVITY
	LD	(PCF_RD_DUMMY),A
	RET
;
; CLOCK IN ONE BYTE, MSB FIRST
; SENDS ACK UNLESS PCF_NACKPEND IS SET, CONSUMED HERE
; RETURNS BYTE IN A, Z ALWAYS SET
; SDA IS RELEASED ONCE BEFORE THE LOOP AND STAYS HIGH FOR ALL 8 BITS
;
PCF_CLOCKIN:
	PUSH	BC
	PUSH	DE
	LD	D,1 << I2CBIT_SCL		; D = OR-MASK: SCL HIGH
	LD	E,~(1 << I2CBIT_SCL) & $FF	; E = AND-MASK: SCL LOW
	LD	A,1 << I2CBIT_SDA		; RELEASE SDA ONCE, STAYS HIGH THE WHOLE
	OUT	(I2CBIT_BASE),A			; RECEIVE PHASE, SLAVE PULLS IT LOW TO SEND A 1
	LD	C,0				; C = ACCUMULATED BYTE
	LD	B,8				; B = DJNZ COUNTER
PCF_CI_LP:
	OR	D				; SCL HIGH, SLAVE'S BIT IS VALID NOW
	OUT	(I2CBIT_BASE),A
	IN	A,(I2CBIT_BASE)			; SAMPLE WHILE SCL HIGH
	RL	C				; SHIFT ACCUMULATOR, MSB FIRST
	BIT	I2CBIT_SDA,A
	JR	Z,PCF_CI_B0
	SET	0,C
PCF_CI_B0:
	LD	A,1 << I2CBIT_SDA		; SCL LOW AGAIN, SDA STILL RELEASED HIGH
	OUT	(I2CBIT_BASE),A
	DJNZ	PCF_CI_LP
;
	LD	A,(PCF_NACKPEND)
	OR	A
	JR	NZ,PCF_CI_NACK
	XOR	A				; ACK: SDA=0 (LOW), SCL=0
	JR	PCF_CI_STROBE
PCF_CI_NACK:
	XOR	A
	LD	(PCF_NACKPEND),A		; ONE-SHOT, CONSUMED
	LD	A,1 << I2CBIT_SDA		; NACK: LEAVE SDA HIGH (RELEASED), SCL=0
PCF_CI_STROBE:
	OUT	(I2CBIT_BASE),A			; COMMIT ACK/NACK BIT
	OR	D				; SCL HIGH, STROBE
	OUT	(I2CBIT_BASE),A
	AND	E				; SCL LOW AGAIN
	OUT	(I2CBIT_BASE),A
	LD	A,1 << I2CBIT_SDA		; RELEASE SDA, READY FOR NEXT BYTE/STOP
	OUT	(I2CBIT_BASE),A
;
	LD	A,C				; RETURN THE RECEIVED BYTE
	POP	DE
	POP	BC
	CP	A				; FORCE Z (ALWAYS SUCCEEDS BITBANGED)
	RET
;
PCF_RD_DUMMY:
	.DB	0
PCF_NACKPEND:
	.DB	0
;
;-----------------------------------------------------------------------------
; PREP NACK FOR THE LAST BYTE OF A READ
; NO STATUS REGISTER TO PRESET, JUST A FLAG PCF_CLOCKIN CONSUMES NEXT
;
PCF_PREPNACK:
	LD	A,1
	LD	(PCF_NACKPEND),A
	RET
;
; SHIFT OUT 8 BITS (A), MSB FIRST, SAMPLE ACK ON THE 9TH CLOCK
; ENTER/EXIT WITH SCL=LOW, SDA=LOW
; UPDATES PCF_STATUS (PCF_LRB: 0=ACK, 1=NACK)
;
; PURE OUT WITHOUT DELAYS IS REALLY STILL TOO SLOW ON 7.372MHZ
; USING OR/AND AGAINST TWO MASKS PRELOADED IN D/E
;
PCF_SHIFTOUT:
	PUSH	BC
	PUSH	DE
	LD	C,A				; C = BYTE BEING SHIFTED
	LD	D,1 << I2CBIT_SCL		; D = OR-MASK: SCL HIGH
	LD	E,~(1 << I2CBIT_SCL) & $FF	; E = AND-MASK: SCL LOW
	LD	B,8				; B = DJNZ COUNTER
PCF_SO_LP:
	RL	C
	JR	C,PCF_SO_HI
	XOR	A				; SDA=0, SCL=0, SCL ALWAYS LOW
	JR	PCF_SO_CLK			; ENTERING A BIT, NO SHADOW NEEDED
PCF_SO_HI:
	LD	A,1 << I2CBIT_SDA		; SDA=1, SCL=0
PCF_SO_CLK:
	OUT	(I2CBIT_BASE),A			; SDA SETTLED, SCL LOW
	OR	D				; SCL HIGH, SLAVE SAMPLES SDA
	OUT	(I2CBIT_BASE),A
	AND	E				; SCL LOW, READY FOR NEXT BIT
	OUT	(I2CBIT_BASE),A
	DJNZ	PCF_SO_LP
;
; 9TH CLOCK, RELEASE SDA AND SAMPLE THE SLAVE'S ACK
; INLINE LIKE THE 8 DATA BITS, AS A CALL THIS ONE BIT COST AS MUCH AS ALL 8
;
	LD	A,1 << I2CBIT_SDA	; RELEASE SDA (DRIVE HIGH), SCL STAYS LOW
	OUT	(I2CBIT_BASE),A
	OR	D			; SCL HIGH, SLAVE MAY PULL SDA LOW TO ACK
	OUT	(I2CBIT_BASE),A
	IN	A,(I2CBIT_BASE)		; SAMPLE ACK BIT WHILE SCL HIGH
	LD	E,A			; SAVE SAMPLED BYTE
	LD	A,1 << I2CBIT_SDA	; SCL LOW AGAIN, KEEP DRIVING SDA HIGH
	OUT	(I2CBIT_BASE),A
	XOR	A			; SDA LOW, SCL LOW, DOCUMENTED EXIT STATE
	OUT	(I2CBIT_BASE),A		; ALSO DOUBLES AS DEFAULT (ACK) STATUS VALUE
;
	BIT	I2CBIT_SDA,E
	JR	Z,PCF_SO_ACKD
	LD	A,PCF_LRB
PCF_SO_ACKD:
	LD	(PCF_STATUS),A
	POP	DE
	POP	BC
	RET
;
PCF_STATUS:	.DB	0
PCF_XMIT:	.DB	0
;
;-----------------------------------------------------------------------------
; DISPLAY ERROR MESSAGES
; ONLY WHAT DS7RTC.ASM CALLS DIRECTLY
;
PCF_INIERR:
	PUSH	HL
	LD	HL,PCF_NOPCF
	JR	PCF_PRTERR
;
PCF_ACKERR:
	PUSH	HL
	LD	HL,PCF_ACKFAIL
	JR	PCF_PRTERR
;
PCF_BBERR:
	PUSH	HL
	LD	HL,PCF_BBFAIL
	JR	PCF_PRTERR
;
PCF_PINERR:
	PUSH	HL
	LD	HL,PCF_PINFAIL
;	FALLS THROUGH
;
PCF_PRTERR:
	CALL	PRTSTR
	POP	HL
	; FORCE NZ THIS IS THE ERROR PATH
	OR	$FF
	RET
;
PCF_NOPCF	.DB	"NOT PRESENT$"
PCF_ACKFAIL 	.DB	"FAILED TO RECEIVE ACKNOWLEDGE$"
PCF_PINFAIL 	.DB	"PIN FAIL$"
PCF_BBFAIL	.DB	"BUS BUSY$"
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_I2CBIT	.EQU	$
SIZ_I2CBIT	.EQU	END_I2CBIT - ORG_I2CBIT
;
	MEMECHO	"I2CBIT occupies "
	MEMECHO	SIZ_I2CBIT
	MEMECHO	" bytes.\n"
