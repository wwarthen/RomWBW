;
	.ECHO	"i2cscan\n"
;
; I2C BUS SCANNER
; MARCO MACCAFERRI, HTTPS://WWW.MACCASOFT.COM
; HBIOS VERSION BY PHIL SUMMERS (B1ACKMAILER) DIFFICULTLEVELHIGH@GMAIL.COM
;
; SHARED BODY, NOT BUILT DIRECTLY. EACH i2cscan<board>.asm LAUNCHER SETS
; PCFECB/PCFDUO/PCFPYCIO/P8X180/SC126/SC137 THEN #INCLUDEs THIS FILE.
;
#IF (PCFECB)
I2C_BASE 	.EQU  	0F0H
PCF_ID   	.EQU  	0AAH
CPU_CLK	 	.EQU  	12
;
PCF_RS0  	.EQU  	I2C_BASE
PCF_RS1  	.EQU  	PCF_RS0+1
PCF_OWN	 	.EQU  	(PCF_ID >> 1)        	; PCF'S ADDRESS IN SLAVE MODE
#ENDIF
;
#IF (PCFPYCIO)
I2C_BASE 	.EQU  	040H		; T.PYCIO MODULE, THIS BOARD'S REAL PCF8584 PORT
PCF_ID   	.EQU  	0AAH
CPU_CLK	 	.EQU  	12
;
PCF_RS0  	.EQU  	I2C_BASE
PCF_RS1  	.EQU  	PCF_RS0+1
PCF_OWN	 	.EQU  	(PCF_ID >> 1)        	; PCF'S ADDRESS IN SLAVE MODE
#ENDIF
;
#IF (PCFDUO)
I2C_BASE 	.EQU  	056H
PCF_ID   	.EQU  	0AAH
CPU_CLK	 	.EQU  	12
;
PCF_RS0  	.EQU  	I2C_BASE
PCF_RS1  	.EQU  	PCF_RS0+1
PCF_OWN	 	.EQU  	(PCF_ID >> 1)        	; PCF'S ADDRESS IN SLAVE MODE
#ENDIF
;
#IF (P8X180)
I2C_BASE	.EQU	0A0h
_sda		.EQU	0
_scl		.EQU	1
_idle		.EQU	00000011B
#ENDIF
;
#IF (SC126)
I2C_BASE	.EQU	0Ch
_sda		.EQU	7
_scl		.EQU	0
_idle		.EQU	10001101B
#ENDIF
;
#IF (SC137)
I2C_BASE	.EQU	20h
_sda		.EQU	7
_scl		.EQU	0
_idle		.EQU	10000001B
#ENDIF
;
;-----------------------------------------------------------------------------
;
	.org	100h

	ld	sp,stack

	ld	hl,signon
	call	_strout

	ld	c,' '
	call	_cout
	call	_cout
	call	_cout

; SELF-CONTAINED INIT, NO ERROR-CHECKING (DIAGNOSTIC TOOL, NOT PRODUCTION CODE).
;
#IF (PCFECB | PCFDUO | PCFPYCIO)
	CALL	PCF_INIT
#ENDIF

; display x axis header 00-0F

	xor	a
	ld	(x),a
	ld	b, 16
lp1:	ld	c,' '
	call	_cout
	ld	a,(x)
	ld	c,a
	inc	a
	ld	(x),a
	call	_hexout
	djnz	lp1
	call	_eolout

; start of line loop 00-07

	xor	a		; display
	ld	(y),a		; y-axis
	ld	(addr),a	; prefix
	ld	d,8
lp3b:	ld	a,(y)
	ld	c,a
	add	a,10h
	ld	(y),a
	call	_hexout
	ld	c,':'
	call	_cout

; set up x axis loop

	xor	a
	ld	(x),a
	ld	e,16
lp2b:	push	de

	ld	c,' '
	call	_cout

; i2c challenge
; . issue device start command
; . write address to device
; . issue device stop command.
; . delay
; . display response

	CALL	PCF_WAIT_FOR_BB
	JP	NZ,PCF_BBERR
;
; IF I2CPCF_MULTIMASTER, ARM ESO BEFORE WRITING THE ADDRESS BYTE TO RS0.
; WHILE ESO=0, RS0 IS REDIRECTED TO S0'/S2 INSTEAD OF THE REAL SHIFT REGISTER
; (DATASHEET TABLE 5), SO THE ADDRESS BYTE IS SILENTLY MISDIRECTED. MUST MATCH
; WHATEVER THE ACTUAL ROM ON THE BUS WAS BUILT WITH. BITBANG HAS NO SUCH QUIRK.
;
#IF (PCFECB | PCFDUO | PCFPYCIO)
  #IF (I2CPCF_MULTIMASTER)
	LD	A,PCF_IDLE_
	OUT	(PCF_RS1),A
  #ENDIF
	LD	A,(addr)
	OUT	(PCF_RS0),A
#ELSE
	LD	A,(addr)
	LD	(SC_XMIT),A
#ENDIF
	CALL	PCF_START	; GENERATE START CONDITION
;
	ld	bc,100		; delay
lp6:	nop
	dec	bc
	ld	a,c
	or	b
	jr	nz,lp6

	CALL	PCF_WAIT_FOR_ACK; AND ISSUE THE SLAVE ADDRESS
	PUSH	AF		; SAVE ACK/NACK RESULT ACROSS THE STOP BELOW

	ld	a,(addr)	; CAPTURE THE ADDRESS JUST PROBED, REAL 7-BIT FORM --
	srl	a		; USED BOTH FOR DISPLAY BELOW AND BY PCF_BUSSTUCK IF
	ld	(curaddr),a	; THIS TRANSACTION'S STOP FAILS
	ld	a,(addr)	; ADVANCE TO NEXT ADDRESS NOW, BEFORE STOP/PRINTING
	add	a,2		; adjust for
	ld	(addr),a	; 7-bit

; CLOSE OUR OWN TRANSACTION (RELEASE THE BUS) BEFORE PRINTING ANYTHING.
; PRINTING PUMPS BDOS -> HBIOS'S CONSOLE OUTPUT -> IDLE, WHICH CAN FIRE A
; COMPETING I2C TRANSACTION WHILE WE'RE STILL HOLDING THE BUS. STOP MUST
; HAPPEN BEFORE ANY PRINT, EVERY TIME.
	CALL	PCF_STOP

	ld	a,(PCF_STOPFAIL)
	or	a
	jp	nz,PCF_BUSSTUCK	; scl never came back -- stop scanning now,
				; not 127 more addresses against a dead bus

	POP	AF		; RESTORE ACK/NACK RESULT
	or	a
	jp	nz,lp4f

	ld	c,'-'		; display no
	call	_cout		; response
	call	_cout
	jp	lp5f

lp4f:	ld	a,(curaddr)	; DISPLAY THE ADDRESS ALREADY CAPTURED ABOVE
	ld	c,a
	call	_hexout

lp5f:	pop	de		; check if
	dec	e		; reached end
	jp	nz,lp2b		; of line
	call	_eolout

	dec	d		; loop until
	jp	nz,lp3b		; all done

	jp	0

; something on the bus is holding scl low and never released it after
; the last transaction. no further probe on this bus can do anything
; useful until whatever is holding it releases scl on its own -- say so
; plainly and stop, instead of continuing to hammer a bus already known
; to be dead and printing results that don't mean anything.
PCF_BUSSTUCK:
	pop	de		; discard outer loop counters, we are aborting
	ld	hl,PCF_STUCKMSG1
	call	_strout
	ld	a,(curaddr)	; RELOAD AFTER _STROUT -- ITS OWN LOOP CLOBBERS C
	ld	c,a		; (AND A) WHILE PRINTING, SAME BUG CLASS AS PCFSTAT'S FIX
	call	_hexout
	ld	hl,PCF_STUCKMSG2
	call	_strout
	call	_eolout
	jp	0

PCF_STUCKMSG1	.DB	"BUS ERROR: SCL STUCK LOW AFTER ADDRESS $"
PCF_STUCKMSG2	.DB	" ABORTING SCAN, NOT PROBING FURTHER$"

signon:	.db	"I2C Bus Scanner"
#IF (PCFECB)
	.DB	" - PCF8584 (ECB)"
#ENDIF
#IF (PCFPYCIO)
	.DB	" - PCF8584 (Pycio, 0x40)"
#ENDIF
#IF (PCFDUO)
	.DB	" - PCF8584 (Duodyne)"
#ENDIF
#IF (P8X180)
	.DB	" - P8X180"
#ENDIF
#IF (SC126)
	.DB	" - SC126"
#ENDIF
#IF (SC137)
	.DB	" - SC137"
#ENDIF
	.db	"\r\n\r\n",0,"$"

_strout:
st1:	ld	a,(hl)		; display
	CP	'$'		; zero
	ret	z		; terminated
	ld	c,a		; string
	call	_cout
	inc	hl
	jp	st1

_hexout:			; display
	ld	a,c		; A in hex
	srl	a
	srl	a
	srl	a
	srl	a
	add	a,30h
	cp	3Ah
	jp	c,h1
	add	a,7
h1:	ld	h,a
	ld	a,c
	and	0Fh
	add	a,30h
	cp	3Ah
	jp	c,h2
	add	a,7
h2:	ld	l,a
	ld	c,h
	call	_cout
	ld	c,l
	call	_cout
	ret

_eolout:			; newline
	ld	c,13
	call	_cout
	ld	c,10
	call	_cout
	ret

_cout:				; character
	push	af		; output
	push	bc
	push	de
	push	hl
	ld	e,c
	ld	c,02h
	call	5
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret

;-----------------------------------------------------------------------------
#IF (PCFECB | PCFDUO | PCFPYCIO)
;
; SAME SEQUENCE AS THE REAL HBIOS DRIVER'S I2CPCF_INITDEV. LEAVES ESO ON
; REGARDLESS OF I2CPCF_MULTIMASTER, WHICH ONLY EVER DISARMS IT LATER, NOT HERE.
;
PCF_INIT:
	LD	A,PCF_PIN		; S1=80H: SERIAL INTERFACE OFF
	OUT	(PCF_RS1),A
	LD	A,PCF_OWN		; OWN ADDRESS INTO S0'
	OUT	(PCF_RS0),A
	LD	A,PCF_PIN | PCF_ES1	; SELECT S2 (CLOCK REGISTER) FOR NEXT BYTE
	OUT	(PCF_RS1),A
	LD	A,$1C			; CLOCK: 12MHZ BASE / 90KHZ TRANSFER
	OUT	(PCF_RS0),A
	LD	A,PCF_IDLE_
	OUT	(PCF_RS1),A
	RET
;
_i2c_start:
PCF_START:
        LD     A,PCF_START_
	OUT    (PCF_RS1),A
	RET
#ELSE
;_i2c_start:
PCF_START:
	ld	a,_idle		; issue
	out	(I2C_BASE),a	; start
				; command
	res	_sda,a
	out	(I2C_BASE),a
	nop
	nop
	res	_scl,a
	out	(I2C_BASE),a

	ld	(oprval),a
	ret
#ENDIF
;
;-----------------------------------------------------------------------------
;
; CONTROL REGISTER BITS
;
PCF_PIN  	.EQU  10000000B
PCF_ES0  	.EQU  01000000B
PCF_ES1  	.EQU  00100000B
PCF_ES2  	.EQU  00010000B
PCF_EN1  	.EQU  00001000B
PCF_STA  	.EQU  00000100B
PCF_STO  	.EQU  00000010B
PCF_ACK  	.EQU  00000001B
;
; STATUS REGISTER BITS
;
;PCF_PIN  	.EQU  10000000B
PCF_INI   	.EQU  01000000B   ; 1 if not initialized
PCF_STS   	.EQU  00100000B
PCF_BER   	.EQU  00010000B
PCF_AD0   	.EQU  00001000B
PCF_LRB   	.EQU  00001000B
PCF_AAS   	.EQU  00000100B
PCF_LAB   	.EQU  00000010B
PCF_BB    	.EQU  00000001B
;
PCF_START_    	.EQU  (PCF_PIN | PCF_ES0 | PCF_STA | PCF_ACK)
PCF_STOP_     	.EQU  (PCF_PIN | PCF_ES0 | PCF_STO | PCF_ACK)
PCF_IDLE_	.EQU  (PCF_PIN | PCF_ES0 | PCF_ACK)
PCF_IDLEOFF_	.EQU  (PCF_PIN | PCF_ACK)
;
; TIMEOUT AND DELAY VALUES (ARBITRARY)
;
PCF_PINTO	.EQU	65000
PCF_ACKTO	.EQU	65000
PCF_BBTO	.EQU	65000
PCF_LABDLY	.EQU	65000
;
PCF_STATUS	.DB	00H
PCF_STOPFAIL	.DB	0	; SET BY THE BITBANG PCF_STOP IF SCL NEVER
				; RELEASED, ALWAYS 0 ON THE PCF8584 BACKEND
				; (STOP IS AUTONOMOUS THERE, NEVER STICKS)
;
;--------------------------------------------------------------------------------
;
; RETURN NZ/FF IF TIMEOUT ERROR
; RETURN NZ/01 IF FAILED TO RECEIVE ACKNOWLEDGE
; RETURN Z/00  IF RECEIVED ACKNOWLEDGE
;
#IF (PCFECB | PCFDUO | PCFPYCIO)
PCF_WAIT_FOR_ACK:
	PUSH	HL
	LD	HL,PCF_ACKTO
;
PCF_WFA0:
	IN      A,(PCF_RS1)	; READ PIN
        LD	(PCF_STATUS),A	; STATUS
        LD	B,A
;
        DEC	HL		; SEE IF WE HAVE TIMED
        LD	A,H		; OUT WAITING FOR PIN
        OR	L		; EXIT IF
        JR	Z,PCF_WFA1	; WE HAVE
;
        LD	A,B		; OTHERWISE KEEP LOOPING
        AND     PCF_PIN		; UNTIL WE GET PIN
        JR	NZ,PCF_WFA0	; OR TIMEOUT
;
	LD	A,B		; WE GOT PIN SO NOW
	AND	PCF_LRB		; CHECK WE HAVE
	LD	A,1
	JR	Z,PCF_WFA2	; RECEIVED ACKNOWLEDGE
	XOR	A
	JR	PCF_WFA2
PCF_WFA1:
	CPL			; TIMOUT ERROR
PCF_WFA2:
	POP	HL		; EXIT WITH NZ = FF
	RET
#ELSE
PCF_WAIT_FOR_ACK:
	CALL	SC_SHIFTOUT	; SHIFTS OUT SC_XMIT, SAMPLES ACK INTO SC_STATUS
	LD	A,(SC_STATUS)	; SC_STATUS: 0=ACK/1=NACK
	XOR	1		; FLIP TO THIS FILE'S OWN CONVENTION: A=1 ACK/A=0 NACK
	RET
#ENDIF
;
;-----------------------------------------------------------------------------
;
; POLL THE BUS BUSY BIT TO DETERMINE IF BUS IS FREE.
; RETURN WITH A=00H/Z STATUS IF BUS IS FREE
; RETURN WITH A=FFH/NZ STATUS IF BUS IS BUSY
;
; AFTER RESET THE BUS BUSY BIT WILL BE SET TO 1 I.E. NOT BUSY
;
#IF (PCFECB | PCFDUO | PCFPYCIO)
PCF_WAIT_FOR_BB:
  #IF (I2CPCF_MULTIMASTER)
; ARM ESO FIRST, WHILE ESO=0, READING S1 RETURNS STALE CONTROL BITS, NOT
; REAL BUS STATUS (TABLE 5 IN THE DATASHEET), SO BB CAN'T BE MEANINGFULLY
; CHECKED OTHERWISE.
	LD	A,PCF_IDLE_
	OUT	(PCF_RS1),A
  #ENDIF
        LD     HL,PCF_BBTO
PCF_WFBB0:
	IN     A,(PCF_RS1)
        AND    PCF_BB
        JR     Z,PCF_WFBBCONT	; BB=0 MEANS BUSY
	CP	A
	RET
PCF_WFBBCONT:
        DEC    HL
        LD     A,H
        OR     L
        JR     NZ,PCF_WFBB0	; REPEAT IF NOT TIMED OUT
        CPL                	; RET NZ IF TIMEOUT
	RET
#ELSE
PCF_WAIT_FOR_BB:
	XOR	A		; SINGLE MASTER BITBANG, ALWAYS FREE
	RET
#ENDIF
;
;-----------------------------------------------------------------------------
; DISPLAY ERROR MESSAGES
;
PCF_RDERR:
	PUSH	HL
	LD	HL,PCF_RDFAIL
	JR	PCF_PRTERR
;
PCF_INIERR:
	PUSH	HL
	LD      HL,PCF_NOPCF
	JR	PCF_PRTERR
;
PCF_SETERR:
	PUSH	HL
	LD      HL,PCF_WRTFAIL
	JR	PCF_PRTERR
;
PCF_REGERR:
	PUSH	HL
	LD      HL,PCF_REGFAIL
	JR	PCF_PRTERR
;
PCF_CLKERR:
	PUSH	HL
	LD      HL,PCF_CLKFAIL
	JR	PCF_PRTERR
;
PCF_IDLERR:
	PUSH	HL
	LD      HL,PCF_IDLFAIL
	JR	PCF_PRTERR
;
PCF_ACKERR:
	PUSH	HL
	LD      HL,PCF_ACKFAIL
	JR	PCF_PRTERR
;
PCF_RDBERR:
	PUSH	HL
	LD	HL,PCF_RDBFAIL
	JR	PCF_PRTERR
;
PCF_TOERR:
	PUSH	HL
	LD	HL,PCF_TOFAIL
	JR	PCF_PRTERR
;
PCF_ARBERR:
	PUSH	HL
	LD	HL,PCF_ARBFAIL
	JR	PCF_PRTERR
;
PCF_PINERR:
	PUSH	HL
	LD	HL,PCF_PINFAIL
	JR	PCF_PRTERR
;
PCF_BBERR:
	PUSH	HL
	LD	HL,PCF_BBFAIL
	JR	PCF_PRTERR
;
PCF_PRTERR:
	CALL	_strout
	CALL	_eolout
	POP	HL
	RET
;
PCF_NOPCF	.DB	"NO DEVICE FOUND$"
PCF_WRTFAIL	.DB     "SETTING DEVICE ID FAILED$"
PCF_REGFAIL 	.DB     "CLOCK REGISTER SELECT ERROR$"
PCF_CLKFAIL 	.DB     "CLOCK SET FAIL$"
PCF_IDLFAIL 	.DB     "BUS IDLE FAILED$"
PCF_ACKFAIL 	.DB	"FAILED TO RECEIVE ACKNOWLEDGE$"
PCF_RDFAIL	.DB	"READ FAILED$"
PCF_RDBFAIL	.DB	"READBYTES FAILED$"
PCF_TOFAIL	.DB	"TIMEOUT ERROR$"
PCF_ARBFAIL 	.DB	"LOST ARBITRATION$"
PCF_PINFAIL 	.DB	"PIN FAIL$"
PCF_BBFAIL	.DB	"BUS BUSY$"
;
;-----------------------------------------------------------------------------
#IF (PCFECB | PCFDUO | PCFPYCIO)
_i2c_stop:
PCF_STOP:
	LD   	A,PCF_STOP_	; issue
        OUT  	(PCF_RS1),A     ; stop
					; command
  #IF (I2CPCF_MULTIMASTER)
; TURN ESO BACK OFF, ONLY IF THE REAL ROM ON THIS BUS WAS ALSO BUILT
; WITH I2CPCF_MULTIMASTER.
	LD	A,PCF_IDLEOFF_
	OUT	(PCF_RS1),A
  #ENDIF
	RET
#ELSE
;_i2c_stop:
PCF_STOP:
	ld	a,(oprval)
	res	_scl,a
	res	_sda,a
	out	(I2C_BASE),a

	ld	a,(oprval)
	set	_scl,a		; release scl, own bit only
	res	_sda,a
	out	(I2C_BASE),a
	ld	(oprval),a

; wait for scl to read back high before generating the stop, scl is
; open-drain, wired-and, so a stretching slave wins regardless of what we do.
	ld	b,0
PCF_STOPWAIT:
	in	a,(I2C_BASE)
	bit	_scl,a
	jr	nz,PCF_STOPOK
	djnz	PCF_STOPWAIT
	; timed out, scl never released. do not pretend a stop happened, raising
	; sda now would not be a real stop by the i2c spec. report the failure.
	ld	a,1
	ld	(PCF_STOPFAIL),a
	ret

PCF_STOPOK:
	xor	a
	ld	(PCF_STOPFAIL),a
	ld	a,(oprval)
	set	_sda,a		; release sda while scl is confirmed high: real stop
	out	(I2C_BASE),a

	ld	(oprval),a
	ret
;
; shift out SC_XMIT (8 bits, msb first), sample ack on the 9th clock.
; enter/exit with sda=0/scl=0. SC_STATUS: 0=ack received, 1=nack.
; ported from Source/HBIOS/i2cbit.asm's I2CBIT_SHIFTOUT.
;
SC_SHIFTOUT:
	push	bc
	push	de
	ld	a,(SC_XMIT)
	ld	c,a
	ld	d,1 << _scl
	ld	e,~(1 << _scl) & $FF
	ld	b,8
SC_SO_LP:
	rl	c
	jr	c,SC_SO_HI
	xor	a
	jr	SC_SO_CLK
SC_SO_HI:
	ld	a,1 << _sda
SC_SO_CLK:
	out	(I2C_BASE),a
	or	d
	out	(I2C_BASE),a
	and	e
	out	(I2C_BASE),a
	djnz	SC_SO_LP
;
	ld	a,1 << _sda
	out	(I2C_BASE),a
	or	d
	out	(I2C_BASE),a
	in	a,(I2C_BASE)
	ld	e,a
	ld	a,1 << _sda
	out	(I2C_BASE),a
	xor	a
	out	(I2C_BASE),a
;
	ld	a,0
	bit	_sda,e
	jr	z,SC_SO_ACKD
	ld	a,1
SC_SO_ACKD:
	ld	(SC_STATUS),a
	pop	de
	pop	bc
	ret
;
SC_XMIT:	.DB	0
SC_STATUS:	.DB	0
#ENDIF
;
oprval:	.db	0
x:	.db	0
y:	.db	0
addr:	.db	0
curaddr: .db	0
rc:	.db	0

	.fill	128
stack:
	.end
