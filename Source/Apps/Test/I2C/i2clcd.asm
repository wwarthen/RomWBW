;==================================================================================================
; PCF8584 HD44780  I2C LCD UTILITY
;
; SOME GENERAL INFORMATION ON LCDS CAN BE SEEN HERE : FOCUSLCDS.COM/PRODUCT-CATEGORY/CHARACTER-LCD/
;
;==================================================================================================
;
	.ECHO	"i2clcd\n"
;
#INCLUDE "pcfi2c.inc"
;
; LCD COMMANDS
;
LCDFSET .EQU 	00100000B ; 20H
LCD4BIT .EQU 	00000000B ; 00H
LCD2LIN .EQU 	00001000B ; 08H
LCDDON  .EQU 	00000100B ; 04H
LCDDMOV .EQU 	00001000B ; 07H
LCDSGRA .EQU 	01000000B ; 04H
LCDSDRA .EQU 	10000000B ; 80H
LCDEMS  .EQU 	00000100B ; 04H 
LCDELFT .EQU 	00000010B ; 03H
;
LCDPINE .EQU 	00000100B ; PIN 2
LCDPIND .EQU 	00000001B ; PIN O
;
;
; STANDARD FORMATS - 8X1, 8X2, 16X1, 16X2, 16X4, 20X1, 20X2, 20X4, 24X2, 40X1, 40X2, 40X4
;
TIMEOUT	.EQU    255

	.ORG	100H

;INIT:   CALL    PCF_INIT
;
	LD     A,0
        LD     (DEBUGF),A
;
	CALL    LCDINIT		; SETUP THE LCD THROUGH THE PCF8574 

	LD	HL,LCDDATA	; DISPLAY TEXT AT HL
	PUSH	HL
	CALL	LCDSTR
	POP	HL

	CALL	STOP		; CLOSE I2C CONNECTION
;
	RET

;-----------------------------------------------------------------------------
;
LCDLITE	.DB   00001000B  
;
LCDINIT: 
;        CALL	DEBUG
;
        LD	A,I2CLCDW	; SET SLAVE ADDRESS
        OUT	(REGS0),A
;
        LD	A,0C5H		; GENERATE START CONDITION
        OUT	(REGS1),A	; AND ISSUE THE SLAVE ADDRESS
        CALL	CHKPIN
;
;       CALL   DEBUG
;    
        LD 	HL,LCDINIT1
        LD   	B,2
        CALL 	WLN
;
        CALL     DELAY
;
        LD 	HL,LCDINIT2
        LD   	B,2
        CALL 	WLN
;
        CALL  DELAY 
;
;	NOW WE ARE IN 4 BIT MODE
;
	LD	A,+(LCDFSET | LCD4BIT | LCD2LIN)
	CALL	LCDCMD
	LD	A,+(LCDDON | LCDDMOV)
	CALL	LCDCMD
	LD	A,+(LCDEMS | LCDELFT)
	CALL	LCDCMD
	LD	A,LCDSDRA
	CALL	LCDCMD
;
	RET
;
;-----------------------------------------------------------------------------
;
WLN:    LD     A,(HL)
        OUT    (REGS0),A    	; PUT DATA ON BUS
        CALL   CHKPIN
        INC    HL
        DJNZ   WLN       
        RET
;
;-----------------------------------------------------------------------------
; DISPLAY STRING AT HL, TERMINATED BY 0
;
LCDSTR:	POP	BC		; GET THE POINTER OF 
	POP	HL		; THE TEXT TO DISPLAY
	PUSH	HL		; OFF THE STACK AND 
	PUSH	BC		; PUT IT IN HL.
;
LCDST0:	LD	A,(HL)		; GET NEXT CHARACTER TO
	OR	A		; DISPLAY BUT RETURN
	RET	Z		; WHEN TERMINATOR REACHED
	PUSH	HL
;	
	CALL	LCDATA		; OUTPUT TO LCD
	POP	HL
;	RET	C		; POINT TO NEXT 
	INC	HL		; AND REPEAT
	JR	LCDST0	
;
;-----------------------------------------------------------------------------
; SEND BYTE IN A TO LCD IN 4-BIT MODE 
;
LCDATA: PUSH   DE
	LD     D,A
        LD     A,(LCDLITE)    
        OR     +(LCDPINE | LCDPIND) 
        JP     LCDSND
LCDCMD: PUSH   DE
        LD     D,A
        LD     A,(LCDLITE)
        OR     LCDPINE
LCDSND: LD     E,A
        LD     A,D
        PUSH   BC
        LD     C,11110000B
        AND    C
        OR     E   
        LD     (LCDBUF),A
        AND    ~LCDPINE
        LD     (LCDBUF+1),A
        LD     A,D
        RLC    A  
        RLC    A
        RLC    A
        RLC    A
        AND    C
        OR     E
        LD     (LCDBUF+2),A
        AND    ~LCDPINE
        LD     (LCDBUF+3),A
;
        LD   HL,LCDBUF		; OUTPUT 1 BYTE WHICH
        LD   B,4		; REQUIRES A FOUR
        CALL WLN		; BYTE SEQUENCE
;
        POP     BC
        POP     DE
        RET
;     
LCDDATA:
     .DB   "TEST HOW BIG IS THIS LINE DOES IT WRAP",0
;
LCDINIT1:
     .DB   00110100B
     .DB   00011000B
;
LCDINIT2:
     .DB   00100100B
     .DB   00100000B
;
LCDBUF:	
     .DB   0, 0, 0, 0		; BUFFER TO HOLD 4 BYTE SEQUENCE

; FLASH DEVICE READ
;

DEVMADR	.EQU	0

READR:	LD	B,255
DLY1:	DJNZ	DLY1
;
        LD	A,D	       	; SET SLAVE ADDRESS
        OUT	(REGS0),A
;
        LD	A,0C5H		; GENERATE START CONDITION
        OUT	(REGS1),A	; AND ISSUE THE SLAVE ADDRESS
        CALL	CHKPIN
;
        LD   A,+(DEVMADR/256)
        OUT  (REGS0),A    	; PUT ADDRESS MSB ON BUS
        CALL CHKPIN
;
        LD   A,+(DEVMADR&$00FF)
        OUT  (REGS0),A    	; PUT ADDRESS LSB ON BUS
        CALL	CHKPIN
;
	LD	A,045H       	; START
	OUT	(REGS1),A
;
        LD	A,E	  	; ISSUE CONTROL BYTE + READ
        OUT	(REGS0),A
;
	CALL	READI2C		; DUMMY READ
	JR	NZ,ERREXT
;
READLP1:CALL	READI2C
;	JR	Z,ERREXT
	CP	1AH
	PUSH    AF
	CALL    COUT
	POP     AF
	JR	NZ,READLP1
;          
	LD	A,PCF_ES0
	OUT	(REGS1),A          
	CALL	CHKPIN
	IN	A,(REGS0)  
        CALL      READI2C
	CALL STOP
;
        CALL   NEWLINE
;
	RET
;
;-----------------------------------------------------------------------------
;-----------------------------------------------------------------------------
RESET:	LD	A,0C2H		; STOP
	OUT	(REGS1),A
	LD	B,255
DLY2:	DJNZ	DLY2
	LD	A,0C1H
	OUT	(REGS1),A
	RET


RDSTAT:	LD	BC,-1
STATLP:	IN	A,(REGS1)
	AND	1
	RET	Z
	LD	A,B
	OR	C
	DEC	BC
	JR	NZ,STATLP
	LD	A,'T'
	JP	ERREXTT
;
ERREXT: LD	A,'Q' 
	JR	ERR
 
ERREXTT: POP	HL
ERR:	CALL	COUT
        CALL   STOP  
	CALL	RESET
        RET
;
STOP:   LD   A,0C3H
        OUT  (REGS1),A
        RET
;
DELAY:  PUSH HL
        LD   HL,-1
DLOOP:  LD   A,H
        OR   L
        DEC  HL
        JR   NZ,DLOOP
        POP  HL
        RET
;
CHKPIN: IN   A,(REGS1)	; POLL FOR
        BIT  7,A		; TRANSMISSION
        JP   NZ,CHKPIN	; TO FINISH

;	IN	A,(REGS1)	; CHECK FOR
        BIT  3,A		; SLAVE
        RET  Z		; ACKNOWLEDGMENT
	LD	A,'A'
        JP   ERREXTT
;
; READ ONE BYTE FROM I2C
; RETURNS DATA IN A
; Z flag set is acknowledge received (correct operation)
;
READI2C:
	IN	A,(REGS1)	; READ S1 REGISTER
	BIT	7,A		; CHECK PIN STATUS
	JP	NZ,READI2C
	BIT	3,A		; CHECK LRB=0
	RET	NZ
	IN	A,(REGS0)	; GET DATA
	RET
;
DEBUG:  PUSH AF
        PUSH DE
	LD	A,'['
	CALL	COUT
	LD	HL,DEBUGF
	LD	A,(HL)
	INC	(HL)
	CALL	HBTHE
	LD	A,']'
	CALL	COUT
        POP  DE
        POP  AF
	RET
DEBUGF:	.DB	00H
;
;-----------------------------------------------------------------------------
;
; LINUX DRIVER BASED CODE
;
;	I2C_INB		= IN A,(REGS0)
;	I2C_OUTB	= LD A,* | OUT (REGS0),A
;	SET_PCF		= LD A,* | OUT (REGS1),A
;	GET_PCF		= IN A,(REGS1)
;	
;-----------------------------------------------------------------------------
I2C_START:
        LD     A,PCF_START_ 
	OUT    (REGS1),A
	RET
;
;-----------------------------------------------------------------------------
I2C_REPSTART:
        LD     A,PCF_START_  
	OUT    (REGS1),A
	RET
;
;-----------------------------------------------------------------------------
I2C_STOP:
        LD     A,PCF_STOP_  
	OUT    (REGS1),A
	RET
;
;-----------------------------------------------------------------------------
HANDLE_LAB:

LABDLY  .EQU    0F000H  

        LD     A,PCF_PIN  
	OUT    (REGS1),A        
        LD     A,PCF_ES0  
	OUT    (REGS1),A
;
        LD     HL,LABDLY
LABLP   LD     A,H
        OR     L
        DEC    HL  
        JR     NZ,LABLP
;
        IN     A,(REGS1)
        RET
;
;-----------------------------------------------------------------------------
WAIT_FOR_BB:
;
BBTIMO  .EQU    255
;
        LD     HL,BBTIMO
BBNOTO  IN     A,(REGS1)
        AND    PCF_BB
        RET    Z
        DEC    HL
        LD     A,H
        OR     A
        JR     NZ,BBNOTO
        CPL                 ; RET NZ IF TIMEOUT  
BBNOTB  RET                 ; RET Z IF BUS IS BUSY
;
;-----------------------------------------------------------------------------
WAIT_FOR_PIN:
;
; RETURN A=00/Z  IF SUCCESSFULL
; RETURN A=FF/NZ IF TIMEOUT
; RETURN A=01/NZ IF LOST ARBITRATION
;
PINTIMO .EQU    16000
;
        LD      HL,PINTIMO
PINNOTO IN      A,(REGS1)
	LD	(STATUS),A
	LD	B,A
        AND     PCF_PIN
        RET     Z
        DEC     HL
        LD      A,H
        OR      A
        JR      NZ,PINNOTO
        CPL                 ; RET NZ IF TIMEOUT  
PINNOTB RET                 ; RET Z IF BUS IS BUSY
;
	LD	B,A
	AND	PCF_LAB
	CALL	HANDLE_LAB
	LD	(STATUS),A
	XOR	A
	INC	A
	RET
;
STATUS	.DB	00H
;
;-----------------------------------------------------------------------------
PCF_INIT:
       LD       A,PCF_PIN   ; S1=80H: S0 SELECTED, SERIAL 
       OUT     (REGS1),A    ; INTERFACE OFF
       NOP
       IN      A,(REGS1)    ; CHECK TO SEE S1 NOW USED AS R/W
       AND     07FH         ; CTRL. PCF8584 DOES THAT WHEN ESO
       JR      NZ,INIERR    ; IS ZERO
;
       LD      A,PCF_OWN    ; LOAD OWN ADDRESS IN S0,     
       OUT     (REGS0),A    ; EFFECTIVE ADDRESS IS (OWN <<1)
       NOP
       IN      A,(REGS0)    ; CHECK IT IS REALLY WRITTEN
       CP      PCF_OWN
       JR      NZ,SETERR
;
       LD      A,+(PCF_PIN | PCF_ES1) ; S1=0A0H
       OUT     (REGS1),A               ; NEXT BYTE IN S2
       NOP
       IN      A,(REGS1)
       AND     07FH
       CP      PCF_ES1
       JR      NZ,REGERR
;
       LD      A,PCF_CLK    ; LOAD CLOCK REGISTER S2
       OUT     (REGS0),A
       NOP
       IN      A,(REGS0)    ; CHECK IT'S REALLY WRITTEN, ONLY
       AND     1FH          ; THE LOWER 5 BITS MATTER
       CP      PCF_CLK
       JR      NZ,CLKERR
;
       LD      A,PCF_IDLE_
       OUT     (REGS1),A  
       NOP
       IN      A,(REGS1)  
       CP      +(PCF_PIN | PCF_BB)
       JR      NZ,IDLERR

       RET
;
;-----------------------------------------------------------------------------
PCF_SENDBYTES: 			; HL POINTS TO DATA, BC = COUNT, A = 0 LAST A=1 NOT LAST
				; 
	LD	(LASTB),A
;
SB0:	LD	A,(HL)
	OUT	(REGS0),A
	CALL	WAIT_FOR_PIN
	JR	Z,SB1

	CP	01H		; EXIT IF ARBITRATION ERROR
	RET	Z

	CALL	I2C_STOP		; MUST BE TIMEOUT
	LD	A,055H		; ERROR
	RET

SB1:	LD	A,(STATUS)
	AND	PCF_LRB
	JR	NZ,SB2
	LD	A,055H
;
SB2:	LD	A,B
	OR	C
	INC	HL
	JR	NZ,SB0		; CHECK IF FINISHED
;	
SBGOOD:	LD	A,(LASTB)
	OR	A
	JR	NZ,DB3
	CALL	I2C_STOP
	RET
DB3:	CALL	I2C_REPSTART
	RET
;
LASTB	.DB	00H
;

;	I2C_INB		= IN A,(REGS0)
;	I2C_OUTB	= LD A,* | OUT (REGS0),A
;	SET_PCF		= LD A,* | OUT (REGS1),A
;	GET_PCF		= IN A,(REGS1)


;
;-----------------------------------------------------------------------------

INIERR LD      HL,NOPCF
       CALL    PRTSTR
       RET
;
SETERR LD      HL,WRTFAIL
       CALL    PRTSTR
       RET
REGERR LD      HL,REGFAIL
       CALL    PRTSTR
       RET
;
CLKERR LD      HL,CLKFAIL
       CALL    PRTSTR
       RET
;
IDLERR LD      HL,IDLFAIL
       CALL    PRTSTR
       RET   
;
NOPCF	.DB	"NO DEVICE FOUND",CR,LF,"$"
WRTFAIL .DB     "SETTING DEVICE ID FAILED",CR,LF,"$"
REGFAIL .DB     "CLOCK REGISTER SELECT ERROR",CR,LF,"$" 
CLKFAIL .DB     "CLOCK SET FAIL",CR,LF,"$"
IDLFAIL .DB     "BUS IDLE FAILED",CR,LF,"$"
;
#INCLUDE "i2ccpm.inc"
;
BUFFER:	.DS	256
;
        .END
