;==================================================================================================
; BITBANGED I2C BUS MASTER
; BASED ON THE WORK OF STEPHEN C COUSINS
; https://smallcomputercentral.com/scm-apps/scm-app-i2c-demo-version-2-2/
;
; DROP IN REPLACEMENT FOR I2CPCF.ASM ON BOARDS WITH NO REAL PCF8584 CHIP
; SC137 "I2C BUS MASTER MODULE (RC2014)"
; SC608 "RCBUS I2C BUS MASTER"
; SC704 "RCBUS I2C BUS MASTER"
; SELECTED VIA I2CBITENABLE MUTUALLY EXCLUSIVE WITH I2CPCFENABLE
;
; SAME PUBLIC LABELS AS I2CPCF.ASM SO LCDI2C.ASM/DS7RTC.ASM
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
#IF (I2CPCFENABLE)
	.ECHO	"*** I2CPCF DRIVER CANNOT BE USED WITH I2CBIT DRIVER!!!\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
I2CBIT_BASE	.EQU	I2CBITBASE
I2CBIT_SDA	.EQU	7		; SDA BIT NUMBER, READ AND WRITE
I2CBIT_SCL	.EQU	0		; SCL BIT NUMBER, READ AND WRITE
I2CBIT_QUIES	.EQU	10000001B	; BOTH LINES IDLE HIGH
;
; SAME BIT POSITION AS THE REAL PCF8584'S LRB
; SO I2CBIT_WAIT_FOR_ACK'S Z/NZ CONTRACT MATCHES I2CPCF.ASM
; NO REAL STATUS REGISTER BEHIND IT HERE
;
I2CBIT_LRB	.EQU	00001000B
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
	JP	Z,I2CBIT_INIT		; DO INIT
	RET				; DONE
;
;-----------------------------------------------------------------------------
; NO REAL CHIP TO PROBE
; TOGGLE SDA BOTH WAYS AND CONFIRM READBACK
; A STATIC COMPARE CAN'T TELL FLOATING FROM WIRED
; SCL STAYS HIGH THROUGHOUT
;
I2CBIT_INIT:
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
	JR	NZ,I2CBIT_FAIL		; SDA DIDN'T GO LOW
	LD	A,I2CBIT_QUIES		; SDA HIGH AGAIN, BOTH BACK TO IDLE
	OUT	(I2CBIT_BASE),A
	IN	A,(I2CBIT_BASE)
	BIT	I2CBIT_SDA,A
	JR	Z,I2CBIT_FAIL		; SDA DIDN'T GO HIGH
	XOR	A
	RET
;
I2CBIT_FAIL:
	CALL	I2CBIT_INIERR
	LD	A,ERR_NOHW
	LD	(I2C_FAIL_FLAG),A
	RET
;
I2C_FAIL_FLAG:
	.DB	0
;
;-----------------------------------------------------------------------------
; GENERATE START CONDITION AND SHIFT THE ADDRESS BYTE (A ON ENTRY)
; REAL PCF8584 DOES THIS AUTONOMOUSLY AFTER S0/S1 ARE WRITTEN
; BITBANGED, BOTH HALVES HAPPEN HERE, SYNCHRONOUSLY
;
I2C_START_ADDR:
	LD	(I2CBIT_XMIT),A
I2C_START:
	LD	A,I2CBIT_QUIES		; ENSURE BOTH IDLE HIGH FIRST, REGARDLESS OF
	OUT	(I2CBIT_BASE),A		; PRIOR STATE (SAME RESULT AS SDA_HI THEN SCL_HI)
	RES	I2CBIT_SDA,A		; START: SDA FALLS WHILE SCL STAYS HIGH
	OUT	(I2CBIT_BASE),A
	RES	I2CBIT_SCL,A		; SCL FALLS TOO, BOTH LOW NOW
	OUT	(I2CBIT_BASE),A
	LD	A,(I2CBIT_XMIT)		; SHIFT WHATEVER'S BUFFERED, MATCHES REAL
	JP	I2CBIT_SHIFTOUT		; HARDWARE'S "RESEND LAST S0 BYTE" BEHAVIOR
;
;-----------------------------------------------------------------------------
; REPEATED START, NO BYTE SHIFT
;
I2C_REPSTART:
	LD	A,1
	LD	(I2CBIT_RD_DUMMY),A
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
I2C_STOP:
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
I2C_PUTBYTE:
	JP	I2CBIT_SHIFTOUT
;
;-----------------------------------------------------------------------------
; PUT ONE BYTE, FALLS THROUGH TO I2C_WAIT_FOR_PIN
;
I2C_PUTBYTE_PIN:
	CALL	I2CBIT_SHIFTOUT
;
; NO SHIFT REGISTER TO POLL, FALLS INTO THE REAL ACK CHECK
;
I2C_WAIT_FOR_PIN:
	JR	I2C_WAIT_FOR_ACK
;
;-----------------------------------------------------------------------------
; PUT ONE BYTE, FALLS THROUGH TO THE ACK CHECK
;
I2C_PUTBYTE_ACK:
	CALL	I2CBIT_SHIFTOUT
;	FALLS THROUGH
;
; RETURN Z/A=0 IF ACK RECEIVED, NZ/A=1 IF NOT.
;
I2C_WAIT_FOR_ACK:
	LD	A,(I2CBIT_STATUS)
	AND	I2CBIT_LRB
	RET	Z
	LD	A,1
	OR	A
	RET
;
;-----------------------------------------------------------------------------
; NO REAL BUS BUSY REGISTER ON A BITBANGED SINGLE MASTER BUS, ALWAYS FREE.
;
I2C_WAIT_FOR_BB:
	XOR	A
	RET
;
;-----------------------------------------------------------------------------
; READ PATH
; I2C_GETBYTE AND I2C_READI2C SHARE ONE BODY, SAME COLLAPSE AS
; I2C_PUTBYTE_PIN ABOVE
;
I2C_GETBYTE:
I2C_READI2C:
	LD	A,(I2CBIT_RD_DUMMY)	; DUMMY READ ARMED BY I2C_REPSTART?
	OR	A
	JR	Z,I2CBIT_CLOCKIN
	XOR	A			; YES, CONSUME IT, NO BUS ACTIVITY
	LD	(I2CBIT_RD_DUMMY),A
	RET
;
; CLOCK IN ONE BYTE, MSB FIRST
; SENDS ACK UNLESS I2CBIT_NACKPEND IS SET, CONSUMED HERE
; RETURNS BYTE IN A, Z ALWAYS SET
; SDA IS RELEASED ONCE BEFORE THE LOOP AND STAYS HIGH FOR ALL 8 BITS
;
I2CBIT_CLOCKIN:
	PUSH	BC
	PUSH	DE
	LD	D,1 << I2CBIT_SCL		; D = OR-MASK: SCL HIGH
	LD	E,~(1 << I2CBIT_SCL) & $FF	; E = AND-MASK: SCL LOW
	LD	A,1 << I2CBIT_SDA		; RELEASE SDA ONCE, STAYS HIGH THE WHOLE
	OUT	(I2CBIT_BASE),A			; RECEIVE PHASE, SLAVE PULLS IT LOW TO SEND A 1
	LD	C,0				; C = ACCUMULATED BYTE
	LD	B,8				; B = DJNZ COUNTER
I2CBIT_CI_LP:
	OR	D				; SCL HIGH, SLAVE'S BIT IS VALID NOW
	OUT	(I2CBIT_BASE),A
	IN	A,(I2CBIT_BASE)			; SAMPLE WHILE SCL HIGH
	RL	C				; SHIFT ACCUMULATOR, MSB FIRST
	BIT	I2CBIT_SDA,A
	JR	Z,I2CBIT_CI_B0
	SET	0,C
I2CBIT_CI_B0:
	LD	A,1 << I2CBIT_SDA		; SCL LOW AGAIN, SDA STILL RELEASED HIGH
	OUT	(I2CBIT_BASE),A
	DJNZ	I2CBIT_CI_LP
;
	LD	A,(I2CBIT_NACKPEND)
	OR	A
	JR	NZ,I2CBIT_CI_NACK
	XOR	A				; ACK: SDA=0 (LOW), SCL=0
	JR	I2CBIT_CI_STROBE
I2CBIT_CI_NACK:
	XOR	A
	LD	(I2CBIT_NACKPEND),A		; ONE-SHOT, CONSUMED
	LD	A,1 << I2CBIT_SDA		; NACK: LEAVE SDA HIGH (RELEASED), SCL=0
I2CBIT_CI_STROBE:
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
I2CBIT_RD_DUMMY:
	.DB	0
I2CBIT_NACKPEND:
	.DB	0
;
;-----------------------------------------------------------------------------
; PREP NACK FOR THE LAST BYTE OF A READ
; NO STATUS REGISTER TO PRESET, JUST A FLAG I2CBIT_CLOCKIN CONSUMES NEXT
;
I2C_PREPNACK:
	LD	A,1
	LD	(I2CBIT_NACKPEND),A
	RET
;
; SHIFT OUT 8 BITS (A), MSB FIRST, SAMPLE ACK ON THE 9TH CLOCK
; ENTER/EXIT WITH SCL=LOW, SDA=LOW
; UPDATES I2CBIT_STATUS (I2CBIT_LRB: 0=ACK, 1=NACK)
;
; PURE OUT WITHOUT DELAYS IS REALLY STILL TOO SLOW ON 7.372MHZ
; USING OR/AND AGAINST TWO MASKS PRELOADED IN D/E
;
I2CBIT_SHIFTOUT:
	PUSH	BC
	PUSH	DE
	LD	C,A				; C = BYTE BEING SHIFTED
	LD	D,1 << I2CBIT_SCL		; D = OR-MASK: SCL HIGH
	LD	E,~(1 << I2CBIT_SCL) & $FF	; E = AND-MASK: SCL LOW
	LD	B,8				; B = DJNZ COUNTER
I2CBIT_SO_LP:
	RL	C
	JR	C,I2CBIT_SO_HI
	XOR	A				; SDA=0, SCL=0, SCL ALWAYS LOW
	JR	I2CBIT_SO_CLK			; ENTERING A BIT, NO SHADOW NEEDED
I2CBIT_SO_HI:
	LD	A,1 << I2CBIT_SDA		; SDA=1, SCL=0
I2CBIT_SO_CLK:
	OUT	(I2CBIT_BASE),A			; SDA SETTLED, SCL LOW
	OR	D				; SCL HIGH, SLAVE SAMPLES SDA
	OUT	(I2CBIT_BASE),A
	AND	E				; SCL LOW, READY FOR NEXT BIT
	OUT	(I2CBIT_BASE),A
	DJNZ	I2CBIT_SO_LP
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
	JR	Z,I2CBIT_SO_ACKD
	LD	A,I2CBIT_LRB
I2CBIT_SO_ACKD:
	LD	(I2CBIT_STATUS),A
	POP	DE
	POP	BC
	RET
;
I2CBIT_STATUS:	.DB	0
I2CBIT_XMIT:	.DB	0
;
;-----------------------------------------------------------------------------
; DISPLAY ERROR MESSAGES
; ONLY WHAT DS7RTC.ASM CALLS DIRECTLY
;
I2CBIT_INIERR:
	PUSH	HL
	LD	HL,I2CBIT_NOI2C
	JR	I2CBIT_PRTERR
;
I2CBIT_ACKERR:
	PUSH	HL
	LD	HL,I2CBIT_ACKFAIL
	JR	I2CBIT_PRTERR
;
I2CBIT_BBERR:
	PUSH	HL
	LD	HL,I2CBIT_BBFAIL
	JR	I2CBIT_PRTERR
;
I2CBIT_PINERR:
	PUSH	HL
	LD	HL,I2CBIT_PINFAIL
;	FALLS THROUGH
;
I2CBIT_PRTERR:
	CALL	PRTSTR
	POP	HL
	; FORCE NZ THIS IS THE ERROR PATH
	OR	$FF
	RET
;
I2CBIT_NOI2C	.DB	"NOT PRESENT$"
I2CBIT_ACKFAIL	.DB	"FAILED TO RECEIVE ACKNOWLEDGE$"
I2CBIT_PINFAIL	.DB	"PIN FAIL$"
I2CBIT_BBFAIL	.DB	"BUS BUSY$"
;
I2C_ACKERR	.EQU	I2CBIT_ACKERR
I2C_BBERR	.EQU	I2CBIT_BBERR
I2C_PINERR	.EQU	I2CBIT_PINERR
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
