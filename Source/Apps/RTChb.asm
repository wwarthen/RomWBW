;==================================================================================================
; GENERIC HBIOS DATE AND TIME
;==================================================================================================
;
;	HBIOS FORMAT  = YYMMDDHHMMSS
;
;-----------------------------------------------------------------------------
; GENERIC CP/M STUFF
;
BS	.EQU 	8			; BACKSPACE
TAB	.EQU 	9			; TABULATOR
LF	.EQU 	0AH			; LINE-FEED
CR	.EQU 	0DH			; CARRIAGE-RETURN
CLIARGS	.EQU	$81
RESTART	.EQU	$0000			; CP/M restart vector
BDOS	.EQU	$0005			; BDOS invocation vector
FCB	.EQU	$5C			; Location of default FCB
;
;-----------------------------------------------------------------------------
;
        .ORG  100H
;
HBC_START:
	LD	A,(FCB+1)		; GET FIRST CHAR 
	CP	' '			; COMPARE TO BLANK. IF SO NO
	JR	Z,HBC_ST0		; ARGUMENTS SO DISLAY TIME AND DATE
;
	LD	A,(FCB+1)		; GET FIRST CHAR 
	CP	'/'			; IS IT INDICATING AN ARGUMENT
	JR	NZ,HBC_ST0		; 
;
	LD	A,(FCB+2)		; GET NEXT CHARACTER
	CP	'D'			; 
	JR	NZ,HBC_ST1		; 
;
;	/D SET DATE DDMMYY
;
	LD	B,$21			; WRITE CLOCK DATA INTO BUFFER 
	LD	HL,HBC_BUF1
	RST	08
;
	LD	HL,FCB+3
;
	LD	A,(HL)
	CP	0
;	JP	HBC_ST4			; EXIT IF END OF BUFFER
	LD	B,6




	JP	HBC_ST0
;
HBC_ST1:
	LD	A,(FCB+2)		; GET NEXT CHARACTER
	CP	'T'			; 
	JR	NZ,HBC_ST2		; 
;
;	/T SET TIME HHMMSS
;
	LD	B,$21			; WRITE CLOCK DATA INTO BUFFER 
	LD	HL,HBC_BUF1
	RST	08
	JP	HBC_ST0
;
HBC_ST2:
	LD	A,(FCB+2)		; GET NEXT CHARACTER
	CP	'S'			; 
	JR	NZ,HBC_ST3		; 
;
;	/S SET TIME AND DATE
;
	JP	HBC_ST0
;
HBC_ST3:
;
;	UNREGOGNIZED ARGUMENT
;
	RET
;
HBC_ST0:
	LD	B,$20			; READ CLOCK DATA INTO BUFFER 
	LD	HL,HBC_BUF
	RST	08
;
#IF (0)
	LD	A,6
	LD	DE,HBC_BUF		; DISLAY DATA READ
;	CALL	PRTHEXBUF
	CALL   	NEWLINE
#ENDIF
;
        CALL   HBC_DISP         
	RET
;
HBC_BUF1:
	.DB	099H
	.DB	011H
	.DB	022H
	.DB	008H
	.DB	031H
	.DB	000H
;
HBC_BUF	.FILL	6,0
;
;-----------------------------------------------------------------------------
; DISPLAY CLOCK INFORMATION FROM DATA STORED IN BUFFER
;
HBC_DISP:
	LD	HL,HBC_CLKTBL
HBC_CLP:LD	C,(HL)
	INC	HL
	LD	D,(HL)
	CALL	HBC_BCD
	INC	HL
	LD	A,(HL)
	OR      A
	RET	Z
        CALL	COUT
	INC	HL
	JR	HBC_CLP
	RET
;
HBC_CLKTBL:
	.DB	02H, 00111111B, '/'
	.DB	01H, 00011111B, '/'
	.DB	00H, 11111111B, ' '
	.DB	03H, 00011111B, ':'
	.DB	04H, 01111111B, ':'
	.DB	05H, 01111111B, 00H
;
HBC_BCD:PUSH	HL
	LD      HL,HBC_BUF     	; READ VALUE FROM
	LD      B,0           	; BUFFER, INDEXED BY A 
	ADD     HL,BC
	LD      A,(HL)
	AND     D             	; MASK OFF UNNEEDED
	SRL     A
	SRL     A
	SRL     A
	SRL     A      
	ADD     A,30H
	CALL    COUT
	LD      A,(HL)    
	AND     00001111B
	ADD     A,30H
	CALL    COUT
	POP	HL
	RET
;
;-----------------------------------------------------------------------------
; DISPLAY ERROR

HBC_ERR:
	PUSH	HL
	LD	HL,HBC_FAIL
	JR	HBC_PRTERR
;
HBC_PRTERR:
	CALL	PRTSTR
	CALL	NEWLINE
	POP	HL	
	RET
;
HBC_FAIL	.DB	"ERROR$"
;
;-----------------------------------------------------------------------------
; GENERIC CP/M ROUTINES
;
; OUTPUT TEXT AT HL
;
PRTSTR:	LD	A,(HL)
	OR	A
	RET	Z
	CALL	PRINP
	INC	HL
	JR	PRTSTR
;
;Output WORD
;***********
;
;PARAMETER: Entry WORD IN HL
;*********
;
OUTW:	LD A,H
	CALL OUTB
	LD A,L
	CALL OUTB
	RET
;
;Output BYTE
;***********
;
;PARAMETER: Entry BYTE IN A
;*********
;
OUTB:	PUSH AF
	RRCA
	RRCA
	RRCA
	RRCA
	AND 0FH
	CALL HBTHE	;Change Half-BYTE
	POP AF
	AND 0FH
	CALL HBTHE
	RET
;
;Output HALF-BYTE
;****************
;
;PARAMETER: Entry Half-BYTE IN A (BIT 0 - 3)
;*********
;
HBTHE:	CP 0AH
	JR C,HBTHE1
	ADD A,7		;Character to Letter
HBTHE1:	ADD A,30H
	LD E,A
	CALL PCHAR
	RET
;
;
;Output on Screen
;****************
;
PRBS:	LD E,BS
	CALL PCHAR
	RET
;
;Output CR+LF on Screen
;**********************
;
NEWLINE:
CRLF:	LD E,CR
	CALL PCHAR
	LD E,LF
	CALL PCHAR
	RET
;
;Output ASCII-Character
;**********************
;
COUT:
PRINP:	PUSH AF
        PUSH DE
	LD E,A
	CALL PCHAR
        POP DE
	POP AF
	RET
;
;CALL BDOS with Register Save
;****************************
;
INCHA:	LD C,1		;INPUT CHARACTER TO A
	JR BDO
PCHAR:	LD C,2		;PRINT CHARACTER IN E
	JR BDO
PSTRIN:	LD C,9		;PRINT STRING
	JR BDO
INBUFF:	LD C,10		;READ CONSOLE-BUFFER
	JR BDO
CSTS:	LD C,11		;CONSOLE-STATUS
	JR BDO
OPEN:	LD C,15		;OPEN FILE
	JR BDO
CLOSE:	LD C,16		;CLOSE FILE
	JR BDO
DELETE:	LD C,19		;DELETE FILE
	JR BDO
READS:	LD C,20		;READ SEEK
	JR BDO
WRITES:	LD C,21		;WRITE SEEK
	JR BDO
MAKE:	LD C,22		;MAKE FILE
	JR BDO
SETDMA:	LD C,26		;SET DMA-ADDRESS
BDO:	PUSH HL
	PUSH DE
	PUSH BC
	PUSH IX
	PUSH IY
	CALL BDOS
	POP IY
	POP IX
	POP BC
	POP DE
	POP HL
	RET
;
        .END
