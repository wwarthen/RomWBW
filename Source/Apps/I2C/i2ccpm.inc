;==================================================================================================
; GENERIC CP/M ROUTINES
;==================================================================================================
;
BDOS	.EQU 5		;ENTRY BDOS
BS	.EQU 8		;BACKSPACE
TAB	.EQU 9		;TABULATOR
LF	.EQU 0AH	;LINE-FEED
CR	.EQU 0DH	;CARRIAGE-RETURN
;
CLIARGS		.EQU	$81
RESTART		.EQU	$0000		; CP/M restart vector
FCB		.EQU	$5C		; Location of default FCB
;
; OUTPUT TEXT AT HL
;
PRTSTR:	LD	A,(HL)
	CP	'$'
	RET	Z
	CALL	COUT
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
	LD E,CR
	CALL PCHAR
	LD E,LF
	CALL PCHAR
	RET
;
;Output ASCII-Character
;**********************
;
COUT:	PUSH AF
	LD E,A
	CALL PCHAR
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
