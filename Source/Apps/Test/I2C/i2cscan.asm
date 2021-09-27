;
	.ECHO	"i2cscan\n"
;
; I2C BUS SCANNER
; MARCO MACCAFERRI, HTTPS://WWW.MACCASOFT.COM
; HBIOS VERSION BY PHIL SUMMERS (B1ACKMAILER) DIFFICULTLEVELHIGH@GMAIL.COM
;
PCF	.EQU	1
P8X180	.EQU	0
SC126	.EQU	0
SC137	.EQU	0
;
#IF (PCF)
I2C_BASE 	.EQU  	0F0H
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

;	call	_i2c_start
;	ld	a,(addr)
;	ld	c,a
;	call	_i2c_write
;	ld	(rc),a
;	call	_i2c_stop

	CALL	PCF_WAIT_FOR_BB
	JP	NZ,PCF_BBERR
;	
	LD	A,(addr)
        OUT	(PCF_RS0),A
        CALL	PCF_START	; GENERATE START CONDITION
;
	ld	bc,100		; delay
lp6:	nop
	dec	bc
	ld	a,c
	or	b
	jr	nz,lp6

	CALL	PCF_WAIT_FOR_ACK; AND ISSUE THE SLAVE ADDRESS
	or	a
	jp	nz,lp4f

	ld	c,'-'		; display no
	call	_cout		; response
	call	_cout
	jp	lp5f

lp4f:	ld	a,(addr)	; adjust address
	ld	c,a		; and display it
	srl	c
	call	_hexout

lp5f:	ld	a,(addr)	; next address
	add	a,2		; adjust for 
	ld	(addr),a	; 7-bit

	CALL	PCF_STOP

	pop	de		; check if
	dec	e		; reached end
	jp	nz,lp2b		; of line
	call	_eolout
	
	dec	d		; loop until
	jp	nz,lp3b		; all done

	jp	0

signon:	.db	"I2C Bus Scanner"
#IF (PCF)
	.DB	" - PCF8584"
#ENDIF
#IF (SC126)
	.DB	" - SC126"
#ENDIF
#IF (SC137)
	.DB	" - SC137"
#ENDIF
	.db	13, 10, 13, 10, 0, "$"8

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
#IF (PCF)
_i2c_start:
PCF_START:
        LD     A,PCF_START_  
	OUT    (PCF_RS1),A
	RET
#ELSE
;_i2c_start:
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
;
; TIMEOUT AND DELAY VALUES (ARBITRARY)
;
PCF_PINTO	.EQU	65000
PCF_ACKTO	.EQU	65000
PCF_BBTO	.EQU	65000
PCF_LABDLY	.EQU	65000
;
PCF_STATUS	.DB	00H
;
;--------------------------------------------------------------------------------
;
; RETURN NZ/FF IF TIMEOUT ERROR
; RETURN NZ/01 IF FAILED TO RECEIVE ACKNOWLEDGE
; RETURN Z/00  IF RECEIVED ACKNOWLEDGE
;
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
;
;-----------------------------------------------------------------------------
;
; POLL THE BUS BUSY BIT TO DETERMINE IF BUS IS FREE.
; RETURN WITH A=00H/Z STATUS IF BUS IS FREE
; RETURN WITH A=FFH/NZ STATUS IF BUS
;
; AFTER RESET THE BUS BUSY BIT WILL BE SET TO 1 I.E. NOT BUSY
;
PCF_WAIT_FOR_BB:
        LD     HL,PCF_BBTO
PCF_WFBB0:
	IN     A,(PCF_RS1)
        AND    PCF_BB
        RET    Z		; BUS IS FREE RETURN ZERO
        DEC    HL
        LD     A,H
        OR     L
        JR     NZ,PCF_WFBB0	; REPEAT IF NOT TIMED OUT
        CPL                	; RET NZ IF TIMEOUT  
	RET 
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
#IF (PCF)
_i2c_stop:  
PCF_STOP: 
	LD   	A,PCF_STOP_	; issue 
        OUT  	(PCF_RS1),A     ; stop
        RET                     ; command
#ELSE
;_i2c_stop:			
	ld	a,(oprval)	
	res	_scl,a		
	res	_sda,a
	out	(I2C_BASE),a

	set	_scl,a
	out	(I2C_BASE),a
	nop
	nop
	set	_sda,a
	out	(I2C_BASE),a

	ld	(oprval),a
	ret
;
_i2c_write:			; write
	ld	a,(oprval)	; to i2c
				; bus
	ld	b,8
i2c1:	res	_sda,a
	rl	c
	jr	nc,i2c2
	set	_sda,a
i2c2:	out	(I2C_BASE),a
	set	_scl,a
	out	(I2C_BASE),a

#IF	(SC126=0)
	ld	d,a
i2c3:	in	a,(I2C_BASE)
	bit	_scl,a
	jr	z,i2c3
	ld	a,d
#ENDIF
	res	_scl,a
	out	(I2C_BASE),a
	djnz	i2c1

	set	_sda,a
	out	(I2C_BASE),a
	set	_scl,a
	out	(I2C_BASE),a

	ld	d,a
i2c4:	in	a,(I2C_BASE)
#IF	(SC126=0)
	bit	_scl,a
	jr	z,4b
#ENDIF
	ld	c,a
	ld	a,d

	res	_scl,a
	out	(I2C_BASE),a
	ld	(oprval),a
	
	xor	a
	bit	_sda,c
	ret	z
	inc	a

	ret
#ENDIF
oprval:	.db	0
x:	.db	0
y:	.db	0
addr:	.db	0
rc:	.db	0

	.fill	128
stack:
	.end
