;  SYSTEM SEGMENT:  DEBUG.RCP
;  SYSTEM:  ARIES-1
;  CUSTOMIZED BY:  RICHARD CONN

;
;  PROGRAM:  DEBUGRCP.ASM
;  AUTHOR:  RICHARD CONN
;  VERSION:  1.0
;  DATE:  30 JUNE 84
;  PREVIOUS VERSIONS:  NONE
;
VERS	EQU	10
RCPID	EQU	'A'

;
;	DEBUGRCP is a resident debug command package for ZCPR3.  As with
; all resident command processors, DEBUGRCP performs the following functions:
;
;		1.  Assuming that the EXTFCB contains the name of the
;			command, DEBUGRCP looks to see if the first character
;			of the file name field in the EXTFCB is a question
;			mark; if so, it returns with the Zero Flag Set and
;			HL pointing to the internal routine which prints
;			its list of commands
;		2.  The resident command list in DEBUGRCP is scanned for
;			the entry contained in the file name field of
;			EXTFCB; if found, DEBUGRCP returns with the Zero Flag
;			Set and HL pointing to the internal routine which
;			implements the function; if not found, DEBUGRCP returns
;			with the Zero Flag Reset (NZ)
;

;
;  Global Library which Defines Addresses for DEBUGRCP
;
	MACLIB	Z3BASE

;
CTRLC	EQU	'C'-'@'
BS	EQU	08H
TAB	EQU	09H
LF	EQU	0AH
FF	EQU	0CH
CR	EQU	0DH
CTRLX	EQU	'X'-'@'
;
WBOOT	EQU	BASE+0000H		;CP/M WARM BOOT ADDRESS
UDFLAG	EQU	BASE+0004H		;USER NUM IN HIGH NYBBLE, DISK IN LOW
BDOS	EQU	BASE+0005H		;BDOS FUNCTION CALL ENTRY PT
TFCB	EQU	BASE+005CH		;DEFAULT FCB BUFFER
FCB1	EQU	TFCB			;1st and 2nd FCBs
FCB2	EQU	TFCB+16
TBUFF	EQU	BASE+0080H		;DEFAULT DISK I/O BUFFER
TPA	EQU	BASE+0100H		;BASE OF TPA
;
;  SYSTEM Entry Point
;
	org	rcp		; passed for Z3BASE

	db	'Z3RCP'		; Flag for Package Loader
;
;  **** Command Table for RCP ****
;	This table is RCP-dependent!
;
;	The command name table is structured as follows:
;
;	ctable:
;		DB	'CMNDNAME'	; Table Record Structure is
;		DW	cmndaddress	; 8 Chars for Name and 2 Bytes for Adr
;		...
;		DB	0	; End of Table
;
cnsize	equ	4		; NUMBER OF CHARS IN COMMAND NAME
	db	cnsize	; size of text entries
ctab:
	db	'H   '	; Help for RCP
	dw	clist
ctab1:
	db	'MU  '	; Memory Utility
	dw	mu
;
	db	0
;
;  BANNER NAME OF RCP
;
rcp$name:
	db	'DEBUG '
	db	(vers/10)+'0','.',(vers mod 10)+'0'
	db	RCPID
	db	0

;
;  Command List Routine
;
clist:
	lxi	h,rcp$name	; print RCP Name
	call	print1
	lxi	h,ctab1		; print table entries
	mvi	c,1		; set count for new line
clist1:
	mov	a,m		; done?
	ora	a
	rz
	dcr	c		; count down
	jnz	clist1a
	call	crlf		; new line
	mvi	c,4		; set count
clist1a:
	lxi	d,entryname	; copy command name into message buffer
	mvi	b,cnsize	; number of chars
clist2:
	mov	a,m		; copy
	stax	d
	inx	h		; pt to next
	inx	d
	dcr	b
	jnz	clist2
	inx	h		; skip to next entry
	inx	h
	push	h		; save ptr
	lxi	h,entrymsg	; print message
	call	print1
	pop	h		; get ptr
	jmp	clist1
;
;  Print String (terminated in 0 or MSB Set) at Return Address
;
vprint:
eprint:
	xthl			; get address
	call	print1
	xthl			; put address
	ret
;
;  Print String (terminated in 0 or MSB Set) pted to by HL
;
print1:
	mov	a,m		; done?
	inx	h		; pt to next
	ora	a		; 0 terminator
	rz
	cpi	dim		; standout?
	jz	print1d
	cpi	bright		; standend?
	jz	print1b
	call	cout		; print char
	ora	a		; set MSB
	rm			; MSB terminator
	jmp	print1
print1d:
	call	stndout		; dim
	jmp	print1
print1b:
	call	stndend		; bright
	jmp	print1
;
;  New Line
;
crlf:
	mvi	a,cr
	call	cout
	mvi	a,lf	;fall thru
;
;  Character Output
;
cout:
	push	psw
	push	b
	push	d
	push	h
	mov	e,a
	mvi	c,2		; use BDOS
	call	bdos
	pop	h
	pop	d
	pop	b
	pop	psw
	ret
;
;  Get char in A
;
cin:
	push	h
	push	d
	push	b
	mvi	c,1
	call	bdos
	ani	7fh
	push	psw
	mvi	a,bs	;overwrite
	call	cout
	pop	psw
	pop	b
	pop	d
	pop	h
	ret
;
;  CLIST Messages
;
entrymsg:
	db	'  '		; command name prefix
entryname:
	ds	cnsize	; command name
	db	0	; terminator

;
;  General Equates
;
bel	equ	07h
bs	equ	08h
cr	equ	0dh
lf	equ	0ah
fcb	equ	5ch

DIM	EQU	1
BRIGHT	EQU	2

EOLCH	EQU	0	;END OF LINE CHAR
SEPCH	EQU	','	;SEPARATOR CHAR
EROW	EQU	6	;FIRST ROW OF EDITOR DISPLAY
ECOL	EQU	4	;FIRST COL OF EDITOR DISPLAY
ECOLC	EQU	ECOL+16*3+8	;FIRST COL OF EDITOR CHAR DISPLAY
ECURS	EQU	'>'	;EDITOR CURSOR
PRROW	EQU	22	;PROMPT ROW
PRCOL	EQU	10	;PROMPT COLUMN
PRCOLI	EQU	PRCOL+15	;PROMPT INPUT COL
ERROW	EQU	23	;ERROR MESSAGE ROW
ERCOL	EQU	15	;ERROR MESSAGE COLUMN

;
; DEFINE FREE SPACE
;
MU:
	LXI	H,TBUFF	;DETERMINE ADDRESS
	MVI	M,126	;126 CHARS INPUT ALLOWED
	SHLD	BUFFER	;SET PTR
;
; SET UP ARROW KEYS
;
	LXI	H,Z3ENV	;PT TO ENVIRONMENT DESCRIPTOR
	LXI	D,80H+10H	;PT TO ARROW KEY INFO
	DAD	D
	LXI	D,EDCURT	;PT TO CURSOR TABLE
	MVI	B,4	;4 ARROW KEYS
ARROW:
	MOV	A,M	;GET CHAR
	STAX	D	;STORE CHAR
	INX	H	;PT TO NEXT
	INX	D	;PT TO NEXT ENTRY
	INX	D
	INX	D
	DCR	B	;COUNT DOWN
	JNZ	ARROW
;
; Initialize Terminal
;
	call	tinit
;
; Check for Command Line Parameter
;
	lxi	h,fcb+1	;pt to first char
	mov	a,m	;get char
	cpi	' '	;no param?
	jnz	pcheck
	lxi	h,tpa	;pt to TPA
	jmp	mu3
;
; We have a parameter
;
pcheck:
	call	hexin	;convert to binary
	xchg		;HL=value
	jmp	mu3
;
; Erase to EOL
;  If fct not supported, send out B spaces and B backspaces
;
vereol:
	call	ereol	;try erase
	rnz
	push	b	;save B
	mvi	a,' '	;send spaces
	call	vereol1
	pop	b	;get B
	mvi	a,bs	;send backspaces
vereol1:
	call	cout	;send char in A
	dcr	b
	jnz	vereol1
	ret
;
; Clear Screen
;  If fct not supported, write 24 CRLFs
;
vcls:
	call	cls	;try clear
	rnz
	push	b	;save B
	mvi	b,24	;count
vcls1:
	call	crlf
	dcr	b
	jnz	vcls1
	pop	b
	ret
;
; Run MU3
;	HL contains starting address
;
mu3:
	SHLD	BLOCK	;SAVE PTR TO BLOCK
;
; REFRESH EDIT SCREEN
;
EDIT0:
	CALL	VCLS	;NEW SCREEN
	CALL	AT
	DB	2,35	;ROW 2, COL 35
	CALL	VPRINT	;BANNER
	DB	'MU RCP '
	DB	(VERS/10)+'0','.',(VERS MOD 10)+'0',RCPID
	DB	0
;
; REENTER MU3 WITH PTRS RESET
;
MU3R:
	XRA	A	;A=0
	STA	EINDEX	;SET INDEX TO 0 (FIRST ELEMENT)
	CALL	EDPLOT	;PLOT BUFFER DATA
;
; INPUT EDITOR COMMAND
;
EDITCMD:
	CALL	PRMSG	;POSITION AT PROMPT MESSAGE
	DB	'MU Command?',0
	CALL	PRINP	;POSITION AT PROMPT INPUT
	DB	0
	CALL	CIN	;GET CHAR
	CALL	CAPS	;CAPITALIZE
	MOV	B,A	;COMMAND IN B
	LXI	H,EDCURT	;PROCESS CURSOR COMMANDS FIRST
	CALL	CMD	;PROCESS COMMAND
	LXI	H,ECMDTBL	;EDITOR COMMAND TABLE
	CALL	CMD	;PROCESS COMMAND
	CALL	VPRINT	;ERROR MESSAGE
	DB	BEL,0
	JMP	EDITCMD
;
; Position at Prompt Message and Print it
;
PRMSG:
	CALL	AT	;POSITION
	DB	PRROW,PRCOL
	JMP	VPRINT	;PRINT IT
;
; Position at Prompt Input and Print Prompt
;
PRINP:
	CALL	AT	;POSITION
	DB	PRROW,PRCOLI
	JMP	VPRINT	;PRINT IT
;
;INPUT ERROR
;
WHAT:
	CALL	VPRINT
	DB	BEL,0
	JMP	EDITCMD
;
;Command Table Search and Execute
;
CMD:
	MOV	A,M	;CHECK FOR END OF TABLE
	ORA	A
	RZ		;COMMAND NOT FOUND
	CMP	B	;MATCH?
	JZ	CMDRUN
	INX	H	;SKIP TO NEXT ENTRY IN TABLE
	INX	H
	INX	H
	JMP	CMD
;
;RUN COMMAND
;
CMDRUN:
	INX	H	;PT TO LOW ADDRESS
	MOV	E,M
	INX	H	;PT TO HIGH ADDRESS
	MOV	D,M
	XCHG
	POP	PSW	;CLEAR STACK
	PCHL		;RUN ROUTINE
;
;PLOT BUFFER DATA
;
EDPLOT:
	MVI	H,EROW-1	;SET ROW
	MVI	L,ECOL	;SET COLUMN
	CALL	GOTOXY	;POSITION CURSOR
	CALL	VPRINT
	DB	DIM
	DB	'       0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F'
	DB	BRIGHT,0
	INR	H	;NEXT ROW
	CALL	GOTOXY	;POSITION CURSOR
	XCHG		;POSITION IN DE
	LHLD	BLOCK	;PT TO DATA
	MVI	B,8	;8 LINES
;
;Print Next Line on Screen
;
EDIT00:
	CALL	STNDOUT	;GO DIM
	MOV	A,H	;OUTPUT ADDRESS
	CALL	PA2HC
	MOV	A,L
	CALL	PA2HC
	CALL	VPRINT
	DB	':',BRIGHT,' ',0
	MVI	C,16	;16 ELEMENTS
EDIT01:
	MOV	A,M	;GET BYTE
	CALL	PA2HC	;PRINT AS HEX
	CALL	SPACE	;PRINT 1 SPACE
	INX	H	;PT TO NEXT
	DCR	C	;COUNT DOWN
	JNZ	EDIT01
	XCHG		;POSITION AGAIN
	INR	H	;NEXT ROW
	CALL	GOTOXY
	XCHG
	DCR	B	;COUNT DOWN
	JNZ	EDIT00
	MVI	H,EROW	;RESET ROW
	MVI	L,ECOLC	;RESET COL
	CALL	GOTOXY	;POSITION CURSOR
	XCHG		;POSITION IN DE
	LHLD	BLOCK	;PT TO DATA
	MVI	B,8	;8 LINES
EDIT02:
	CALL	BAR	;PRINT BAR
	MVI	C,16	;16 ELEMENTS
EDIT03:
	MOV	A,M	;GET BYTE
	ANI	7FH	;MASK MSB
	CPI	7FH	;DON'T PRINT 7FH
	JZ	EDIT7F
	CPI	' '	;SPACE OR MORE?
	JNC	EDIT04
EDIT7F:
	MVI	A,'.'	;PRINT DOT
EDIT04:
	CALL	COUT	;PRINT BYTE
	INX	H	;PT TO NEXT
	DCR	C	;COUNT DOWN
	JNZ	EDIT03
	CALL	BAR	;PRINT ENDING BAR
	XCHG		;POSITION AGAIN
	INR	H	;NEXT ROW
	CALL	GOTOXY
	XCHG
	DCR	B	;COUNT DOWN
	JNZ	EDIT02
	CALL	EDCUR	;POSITION CURSOR
	RET
;
;EDITOR COMMAND TABLE
;
ECMDTBL:
	DB	CR	;NOP
	DW	EDITCMD
	DB	'C'-'@'	;^C = EXIT MU3
	DW	EDCC
	DB	'R'-'@'	;^R = REFRESH
	DW	EDIT0
	DB	'E'-'@'	;^E=UP
	DW	EDUP
	DB	'X'-'@'	;^X=DOWN
	DW	EDDOWN
	DB	'D'-'@'	;^D=RIGHT
	DW	EDRIGHT
	DB	'S'-'@'	;^S=LEFT
	DW	EDLEFT
	DB	' '	;NOP
	DW	EDITCMD
	DB	'+'	;ADVANCE
	DW	EDITPLUS
	DB	'-'	;BACKUP
	DW	EDITMINUS
	DB	'A'	;ADDRESS
	DW	EDITADR
	DB	'C'	;COMMAND LINE
	DW	EDITCL
	DB	'N'	;CHANGE NUMBERS
	DW	EDITHEX
	DB	'T'	;CHANGE TEXT
	DW	EDITALP
	DB	0	;END OF TABLE
;
;  ARROW KEY DEFINITONS FROM TCAP
;
EDCURT:
	DB	0	;0 INDICATES NO ARROW KEYS
	DW	EDUP
	DB	0
	DW	EDDOWN
	DB	0
	DW	EDRIGHT
	DB	0
	DW	EDLEFT
	DB	0	;END OF TABLE
;
;Enter Command Line
;
EDITCL:
	CALL	VPRINT	;PROMPT INPUT
	DB	CR,LF,'Command Line? ',0
	CALL	RDBUF	;INPUT TEXT
	CALL	PUTCL	;STORE COMMAND LINE
	JMP	CRLF	;NEW LINE
;
; STORE COMMAND LINE
;
PUTCL:
	XCHG		;PTR TO NEW LINE IN DE
	CALL	GETCL1	;GET COMMAND LINE DATA
	MOV	B,A	;CHAR COUNT IN B
	XCHG		;HL PTS TO NEW LINE
	PUSH	H	;SAVE PTR TO NEXT LINE
PCL1:
	MOV	A,M	;GO TO END OF LINE
	ORA	A	;AT END?
	JZ	PCL2
	INX	H	;PT TO NEXT
	DCR	B	;COUNT DOWN
	JNZ	PCL1
	POP	H	;CLEAR STACK
	RET		;COMMAND LINE TOO LONG - ABORT
;
; AT END OF NEW COMMAND LINE
;	PTR TO FIRST CHAR OF NEW COMMAND LINE ON STACK
;	HL PTS TO ENDING 0 OF NEW COMMAND LINE
;	B = NUMBER OF CHARS REMAINING BEFORE COMMAND LINE OVERFLOW
;
PCL2:
	XCHG		;DE PTS TO LAST BYTE
	PUSH	D	;SAVE PTR IN CASE OF ERROR
	CALL	GETCL2	;PT TO TAIL OF COMMAND LINE BUFFER
	MOV	A,M	;GET FIRST CHAR OF TAIL
	CPI	';'	;CONTINUATION?
	JZ	PCL3
	ORA	A	;DONE?
	JZ	PCL3
	MVI	A,';'	;SET CONTINUATION CHAR
	STAX	D
	INX	D
	DCR	B	;COUNT DOWN
	JZ	PCL4	;OVERFLOW
;
; COPY TAIL ONTO END OF NEW COMMAND LINE
;
PCL3:
	MOV	A,M	;GET NEXT CHAR
	STAX	D	;STORE IT
	INX	H	;PT TO NEXT
	INX	D
	ORA	A	;DONE?
	JZ	PCL5
	DCR	B	;COUNT DOWN
	JNZ	PCL3
;
; COMMAND LINE TOO LONG
;
PCL4:
	POP	H	;GET PTR TO END OF OLD LINE
	MVI	M,0	;STORE ENDING 0
	POP	PSW	;CLEAR STACK
	RET
;
; NEW COMMAND LINE OK
;
PCL5:
	POP	PSW	;CLEAR STACK
	CALL	GETCL1	;GET PTR TO BUFFER
	LXI	D,4	;PT TO FIRST CHAR IN BUFFER
	XCHG
	DAD	D
	XCHG
	MOV	M,E	;STORE ADDRESS
	INX	H
	MOV	M,D
	POP	H	;HL PTS TO FIRST CHAR OF NEW LINE
;
; COPY COMMAND LINE INTO BUFFER
;
PCL6:
	MOV	A,M	;COPY
	STAX	D
	INX	H
	INX	D
	ORA	A	;DONE?
	JNZ	PCL6
	RET
;
; GETCL1
;
GETCL1:
	LHLD	Z3ENV+18H	;GET ADDRESS OF COMMAND LINE BUFFER
	PUSH	H	;SAVE IT
	INX	H	;GET SIZE IN A
	INX	H
	MOV	A,M
	POP	H
	RET
;
; GETCL2
;
GETCL2:
	LHLD	Z3ENV+18H	;GET ADDRESS OF COMMAND LINE BUFFER
	MOV	A,M		;GET ADDRESS OF NEXT CHAR
	INX	H
	MOV	H,M
	MOV	L,A		;HL PTS TO NEXT CHAR
	MOV	A,M		;GET IT
	RET

;
;Enter ASCII Chars
;
EDITALP:
	CALL	PRINP	;PROMPT INPUT
	DB	DIM,'Enter Text',BRIGHT
	DB	CR,LF,' --> ',0
	CALL	RDBUF	;INPUT TEXT WITHOUT PROMPT
	CALL	EDPRCL	;CLEAR PROMPT LINE
	LDA	EINDEX	;PT TO POSITION
	XCHG
	LHLD	BLOCK	;COMPUTE OFFSET
	XCHG
	ADD	E
	MOV	E,A
	MOV	A,D
	ACI	0
	MOV	D,A	;DE PTS TO BYTE, HL PTS TO TEXT
EDITA1:
	MOV	A,M	;GET CHAR
	CPI	EOLCH	;EOL?
	JZ	EDITA2	;REFRESH SCREEN
	CALL	GETAHV	;GET ASCII OR <HEX> VALUE
	STAX	D	;UPDATE BYTE
	INX	H	;PT TO NEXT INPUT CHAR
	INR	E	;PT TO NEXT BUFFER BYTE
	JNZ	EDITA1
EDITA2:
	CALL	EDPLOT	;REPLOT
	JMP	EDITCMD	;DONE-REFRESH SCREEN
;
;Enter Numbers
;
EDITHEX:
	CALL	PRINP	;PROMPT INPUT
	DB	DIM,'Enter Hex Numbers'
	DB	BRIGHT
	DB	CR,LF,' --> ',0
	CALL	RDBUF	;INPUT TEXT WITHOUT PROMPT
	CALL	EDPRCL	;CLEAR PROMPT LINE
	LDA	EINDEX	;PT TO POSITION
	XCHG
	LHLD	BLOCK	;COMPUTE OFFSET
	XCHG
	ADD	E
	MOV	E,A
	MOV	A,D
	ACI	0
	MOV	D,A	;DE PTS TO BYTE, HL PTS TO TEXT
EDITH1:
	MOV	A,M	;GET HEX DIGIT
	CPI	EOLCH	;EOL?
	JZ	EDITA2	;REFRESH SCREEN
	CPI	' '	;SKIP SPACES
	JNZ	EDITH2
	INX	H	;SKIP SPACE
	JMP	EDITH1
EDITH2:
	PUSH	D	;SAVE PTR
	CALL	HEXIN	;GET VALUE AND POSITION HL
	MOV	A,E	;... IN A
	POP	D	;GET PTR
	STAX	D	;PUT BYTE
	INR	E	;ADVANCE TO NEXT BYTE
	JNZ	EDITH1
	JMP	EDITA2	;DONE-REFRESH
;
;CLEAR PROMPT LINE
;
EDPRCL:
	CALL	PRINP	;PROMPT LINE
	DB	0
	MVI	B,40	;40 POSITIONS
	CALL	VEREOL	;CLEAR TO EOL OR 40 CHARS
	CALL	AT	;USER INPUT
	DB	ERROW,1
	MVI	B,79	;79 POSITIONS
	JMP	VEREOL
;
;Input Address
;
EDITADR:
	CALL	VPRINT
	DB	'Address? ',0
	CALL	RDBUF	;GET USER INPUT
	CALL	SKSP	;SKIP LEADING SPACES
	MOV	A,M	;EMPTY LINE?
	ORA	A
	JZ	EDIT0
	CALL	HEXIN	;CONVERT FROM HEX
	XCHG		;HL = ADDRESS
	SHLD	BLOCK
	JMP	EDIT0	;REENTER
;
;Advance to Next Block
;
EDITPLUS:
	LHLD	BLOCK	;ADVANCE TO NEXT BLOCK
	LXI	D,128	;128 BYTES
	DAD	D
	SHLD	BLOCK
	JMP	MU3R
;
;Backup to Last Block
;
EDITMINUS:
	LHLD	BLOCK	;BACKUP TO LAST BLOCK
	LXI	D,-128	;128 BYTES
	DAD	D
	SHLD	BLOCK
	JMP	MU3R
;
;Exit MU3
;
EDCC:
	CALL	DINIT	;DEINIT TERM
	JMP	CRLF	;NEW LINE
;
;EDIT MOVE: UP
;
EDUP:
	CALL	EDCCUR	;CLEAR CURSOR
	LDA	EINDEX	;BACKUP INDEX BY 16
	SUI	16
;
;Common EDIT MOVE Routine - on input, A=new index
;
EDMOVE:
	ANI	7FH	;MOD 128
	STA	EINDEX
	CALL	EDCUR	;SET CURSOR
	JMP	EDITCMD
;
;EDIT MOVE: DOWN
;
EDDOWN:
	CALL	EDCCUR	;CLEAR CURSOR
	LDA	EINDEX	;INCREMENT INDEX BY 16
	ADI	16
	JMP	EDMOVE	;COMMON ROUTINE
;
;EDIT MOVE: RIGHT
;
EDRIGHT:
	CALL	EDCCUR	;CLEAR CURSOR
	LDA	EINDEX	;INCREMENT INDEX BY 1
	INR	A
	JMP	EDMOVE	;COMMON ROUTINE
;
;EDIT MOVE: LEFT
;
EDLEFT:
	CALL	EDCCUR	;CLEAR CURSOR
	LDA	EINDEX	;DECREMENT INDEX BY 1
	DCR	A
	JMP	EDMOVE	;COMMON ROUTINE
;
;EDIT SUBROUTINE: EDCUR
; Position Editor Cursor at EINDEX
;EDIT SUBROUTINE: EDCCUR
; Clear Editor Cursor at EINDEX
;
EDCUR:
	PUSH	H	;SAVE HL
	MVI	C,ECURS	;CURSOR CHAR
	CALL	EDSETCUR
	CALL	AT	;UPDATE DATA
	DB	3,74
	LDA	EINDEX	;PT TO BYTE AT CURSOR
	LHLD	BLOCK
	ADD	L
	MOV	L,A
	MOV	A,H
	ACI	0
	MOV	H,A	;HL PTS TO BYTE AT CURSOR
	MOV	A,M	;GET BYTE
	CALL	PA2HC	;PRINT AS HEX
	CALL	SPACE
	MOV	A,M	;GET BYTE
	POP	H	;RESTORE HL
	ANI	7FH	;MASK
	CPI	7FH	;7FH AS DOT
	JZ	EDC7F
	CPI	' '	;OUTPUT CHAR OR DOT
	JNC	COUT
EDC7F:
	MVI	A,'.'	;DOT
	JMP	COUT
EDCCUR:
	MVI	C,' '	;CLEAR CURSOR
EDSETCUR:
	CALL	EDROW	;COMPUTE ROW
	ANI	0FH	;COMPUTE COL MOD 16
	MOV	B,A	;RESULT IN B
	ADD	A	;*2
	ADD	B	;*3
	ADI	ECOL+6	;ADD IN COL
	DCR	A	;SUBTRACT 1
	MOV	L,A	;COL POSITION SET
	CALL	GOTOXY	;POSITION CURSOR
	MOV	A,C	;OUTPUT CHAR
	JMP	COUT
;
;Compute Row from EINDEX
;
EDROW:
	LDA	EINDEX	;GET INDEX
	MOV	B,A	;SAVE IN B
	RRC		;DIVIDE BY 16
	RRC
	RRC
	RRC
	ANI	0FH	;MASK FOR LSB ONLY
	ADI	EROW	;COMPUTE ROW
	MOV	H,A	;ROW SET
	MOV	A,B	;GET INDEX
	RET

;
;PRINT A SPACE
;
SPACE:
	MVI	A,' '
	JMP	COUT
;
;PRINT AN BARISK IN REV VIDEO
;
BAR:
	CALL	VPRINT
	DB	DIM,'|',BRIGHT,0
	RET
;
;Get value from input buffer
;
GETAHV:
	MOV	A,M	;GET NEXT CHAR
	CPI	'<'	;HEX ESCAPE?
	RNZ		;NO, RETURN
;"<<" means one "<"
	INX	H
	MOV	A,M
	CPI	'<'
	RZ
;Got hex
	PUSH	D
	CALL	HEXIN	;GET VALUE
	CPI	'>'	;PROPER DELIM?
	MOV	A,E	;GET VALUE
	POP	D
	RZ
;
;ERROR CONDITION IN SUBROUTINE - CLEAR STACK AND FLAG ERROR
;
SERR:
	POP	PSW	;CLEAR STACK
	JMP	WHAT	;ERROR
;
;Input Number from Command Line -- Assume it to be Hex
;  Number returned in DE
;
HEXIN:
	LXI	D,0	;INIT VALUE
	MOV	A,M
	CPI	'#'	;DECIMAL?
	JZ	HDIN	;MAKE DECIMAL
;
HINLP:
	MOV	A,M	;GET CHAR
	CALL	CAPS	;CAPITALIZE
	CPI	CR	;EOL?
	RZ
	CPI	EOLCH	;EOL?
	RZ
	CPI	SEPCH
	RZ
	CPI	' '	;SPACE?
	RZ
	CPI	'-'	;'THRU'?
	RZ
	CPI	'>'
	RZ
	INX	H	;PT TO NEXT CHAR
	CPI	'0'	;RANGE?
	JC	SERR
	CPI	'9'+1	;RANGE?
	JC	HINNUM
	CPI	'A'	;RANGE?
	JC	SERR
	CPI	'F'+1	;RANGE?
	JNC	SERR
	SUI	7	;ADJUST FROM A-F TO 10-15
;
HINNUM:
	SUI	'0'	;CONVERT FROM ASCII TO BINARY
	XCHG
	DAD	H	;MULT PREVIOUS VALUE BY 16
	DAD	H
	DAD	H
	DAD	H
	ADD	L	;ADD IN NEW DIGIT
	MOV	L,A
	XCHG
	JMP	HINLP
;
HDIN:
	INX	H	;SKIP '#'
;
;Input Number in Command Line as Decimal
;  Number is returned in DE
;
DECIN:
	LXI	D,0
	MOV	A,M	; GET 1ST CHAR
	CPI	'#'	; HEX?
	JNZ	DINLP
	INX	H	; PT TO DIGIT
	JMP	HINLP	; DO HEX PROCESSING
;
DINLP:
	MOV	A,M	;GET DIGIT
	CALL	CAPS	;CAPITALIZE
	CPI	'0'	;RANGE?
	RC
	CPI	'9'+1	;RANGE?
	RNC
	SUI	'0'	;CONVERT TO BINARY
	INX	H	;PT TO NEXT
	PUSH	H
	MOV	H,D
	MOV	L,E
	DAD	H	;X2
	DAD	H	;X4
	DAD	D	;X5
	DAD	H	;X10
	ADD	L	;ADD IN DIGIT
	MOV	L,A
	MOV	A,H
	ACI	0
	MOV	H,A
	XCHG		;RESULT IN DE
	POP	H
	JMP	DINLP
;
; READ LINE FROM USER INTO INPUT LINE BUFFER
;
RDBUF:
	LHLD	BUFFER	;PT TO BUFFER
	XCHG		;SET DE AS PTR TO BUFFER
	MVI	C,10	;BDOS READLN
	PUSH	D	;SAVE PTR
	CALL	BDOS
	POP	H	;PT TO CHAR COUNT
	INX	H
	MOV	E,M	;GET CHAR COUNT
	MVI	D,0
	INX	H	;PT TO FIRST CHAR
	PUSH	H	;SAVE PTR
	DAD	D	;PT TO AFTER LAST CHAR
	MVI	M,0	;STORE ENDING 0
	POP	H	;PT TO FIRST CHAR
	RET

;
; Capitalize char in A
;
caps:
	ani	7fh
	cpi	'a'	;range?
	rc
	cpi	'z'+1
	rnc
	ani	5fh	;mask to caps
	ret
;
; CLEAR SCREEN ON TERMINAL
;
cls:
	push	h	;save regs
	push	d
	lxi	h,z3env+80H	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	clserr
	lxi	d,14h	;pt to cls delay
	dad	d
	mov	d,m	;get it
	inx	h	;pt to cls string
	inx	h
	inx	h
	mov	a,m	;get first char of string
	ora	a	;if no string, error
	jz	clserr
	call	vidout	;output string with delay
	pop	d	;done
	pop	h
	xra	a	;return NZ
	dcr	a
	ret
clserr:
	pop	d	;done
	pop	h
	xra	a	;return Z
	ret

;
; Erase to End of Line
;	Return with A=0 and Zero Flag Set if not done
;
ereol:
	push	b	;save regs
	push	d
	push	h
	lxi	h,z3env+80h	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	err
	lxi	d,16h	;pt to ereol delay
	dad	d
	mov	d,m	;get it
	inx	h	;pt to cls string
	call	vidskp	;skip over it
	call	vidskp	;skip over CM string
	mov	a,m	;get first char of ereol string
	ora	a	;if no string, error
	jz	err
	call	vidout	;output string with delay
	jmp	noerr

;
; GOTO XY
;	HL = Row/Col, with Home=1/1
;	Return with A=0 and Zero Flag Set if not done
;
gotoxy:
	push	b	;save regs
	push	d
	push	h
	lxi	h,z3env+80h	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	err
	lxi	d,15h	;pt to CM delay
	dad	d
	mov	a,m	;get it
	sta	cmdelay	;save it
	inx	h	;pt to CL string
	inx	h
	call	vidskp	;skip CL string
	mov	a,m	;get first char of CM string
	ora	a	;if no string, error
	jz	err
	xchg		;DE=address of CM string
	pop	h	;get coordinates in HL
	push	h
	call	gxy	;output xy string with delay
	lda	cmdelay	;pause
	call	videlay
noerr:
	pop	h	;done
	pop	d
	pop	b
	xra	a	;return NZ
	dcr	a
	ret
err:
	pop	h	;done
	pop	d
	pop	b
	xra	a	;return Z
	ret

;
; Position Cursor at Location Specified by Return Address
; Usage:
;	call	at
;	db	row,col	;location
;
at:
	xthl		;pt to address
	push	d	;save DE
	mov	d,m	;get row
	inx	h
	mov	e,m
	inx	h	;HL pts to return byte
	xchg		;DE pts to return byte, HL contains screen loc
	call	gotoxy	;position cursor
	xchg		;HL pts to return byte
	pop	d	;restore registers
	xthl		;restore stack ptr
	ret

;
; GOTOXY
;   On input, H=Row and L=Column to Position To (1,1 is Home)
;   On input, DE=address of CM string
;
gxy:
	dcr	h	;adjust to 0,0 for home
	dcr	l
	xra	a	;set row/column
	sta	rcorder	;row before column
	sta	rcbase	;add 0 to base
;
; Cycle thru string
;
gxyloop:
	ldax	d	;get next char
	inx	d	;pt to next
	ora	a	;done?
	rz
	cpi	'%'	;command?
	jz	gxycmd
	cpi	'\'	;escape?
	jz	gxyesc
	call	cout	;send char
	jmp	gxyloop

;
; Escape - output following byte literally
;
gxyesc:
	ldax	d	;get next char
	call	cout	;output literally
	inx	d	;pt to next
	jmp	gxyloop
;
; Interpret next character as a command character
;
gxycmd:
	ldax	d	;get command char
	inx	d	;pt to next
	cpi	'd'	;%d
	jz	gxyout1
	cpi	'2'	;%2
	jz	gxyout2
	cpi	'3'	;%3
	jz	gxyout3
	cpi	'.'	;%.
	jz	gxyout4
	cpi	'+'	;%+v
	jz	gxyout5
	cpi	'>'	;%>xy
	jz	gxygt
	cpi	'r'	;%r
	jz	gxyrev
	cpi	'i'	;%i
	jz	gxyinc
	call	cout	;output char if nothing else
	jmp	gxyloop
;
; Set row/col home to 1,1 rather than 0,0
;
gxyinc:
	mvi	a,1	;set rcbase to 1
	sta	rcbase
	jmp	gxyloop
;
; Reverse order of output to column then row (default is row then column)
;
gxyrev:
	mvi	a,1	;set column and row order
	sta	rcorder
	jmp	gxyloop
;
; Command: >xy
;   If value of row/col is greater than x, add y to it
;
gxygt:
	call	getval	;get value
	mov	c,a	;save value
	ldax	d	;get value to test
	inx	d	;pt to next
	cmp	c	;if carry, value>x
	jnc	gxygt1
	ldax	d	;get value to add
	add	c
	call	putval	;put value back
gxygt1:
	inx	d	;pt to next
	jmp	gxyloop	;resume
;
; Command: +n
;   Add n to next value and output
;
gxyout5:
	ldax	d	;get value to add
	inx	d	;pt to next
	mov	b,a	;save in B
	call	getval	;get value
	add	b	;add in B
	call	cout	;output value
rcmark:
	lda	rcorder	;mark output
	ori	80h
	sta	rcorder
	jmp	gxyloop
;
; Command: .
;   Output next value
;
gxyout4:
	call	getval	;get value
	call	cout	;output value
	jmp	rcmark
;
; Command: 3
;   Output next value as 3 decimal digits
;
gxyout3:
	call	getval	;get value
	mvi	b,100	;output 100's
	mvi	c,1	;leading zeroes
	call	digout
gxyot3:
	mvi	b,10	;output 10's
	mvi	c,1	;leading zeroes
gxyot2:
	call	digout
	adi	'0'	;output 1's
	call	cout
	jmp	rcmark
;
; Command: 2
;   Output next value as 2 decimal digits
;
gxyout2:
	call	getval	;get value
	jmp	gxyot3
;
; Command: d
;   Output next value as n decimal digits with no leading zeroes
;
gxyout1:
	call	getval	;get value
	mvi	b,100	;output 100's
	mvi	c,0	;no leading zeroes
	call	digout
	mvi	b,10	;output 10's
	mvi	c,0	;no leading zeroes
	jmp	gxyot2
;
; Return next value in A
;
getval:
	lda	rcorder	;get order flag
	ora	a	;already output the first value?
	jm	getval2
	ani	1	;look at lsb
	jz	getvalr	;if 0, row first
getvalc:
	lda	rcbase	;get base offset
	add	l	;get column
	ret
getvalr:
	lda	rcbase	;get base offset
	add	h	;get row
	ret
getval2:
	ani	1	;look at lsb
	jz	getvalc
	jmp	getvalr
;
; Store A as next value
;
putval:
	mov	c,a	;save value
	lda	rcorder	;get order flag
	ora	a	;already output the first value?
	jm	putval2
	ani	1	;look at lsb
	jz	putvalr	;if 0, row first
putvalc:
	mov	l,c	;set column
	ret
putvalr:
	mov	h,c	;set row
	ret
putval2:
	ani	1	;look at lsb
	jz	putvalc
	jmp	putvalr
;
; Output A as decimal digit char
;   B=Quantity to Subtract from A, C=0 if no leading zero
;
digout:
	push	d	;save DE
	mvi	d,'0'	;char
decot1:
	sub	b	;subtract
	jc	decot2
	inr	d	;increment char
	jmp	decot1
decot2:
	add	b	;add back in
	push	psw	;save result
	mov	a,d	;get digit
	cpi	'0'	;zero?
	jnz	decot3
	mov	a,c	;get zero flag
	ora	a	;0=no zero
	jz	decot4
decot3:
	mov	a,d	;get digit
	call	cout	;print it
decot4:
	pop	psw	;get A
	pop	d	;restore DE
	ret
;
; GXY Buffers
;
rcorder:
	ds	1	;0=row/col, else col/row
rcbase:
	ds	1	;0=org is 0,0, else org is 1,1
cmdelay:
	ds	1	;number of milliseconds to delay for CM

;
; Begin Standout Mode
;	Return with A=0 and Zero Flag Set if not done
;
stndout:
	push	b
	push	d
	push	h	;save regs
	lxi	h,z3env+80h	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	err
	lxi	d,17h	;pt to cls string
	dad	d
	mvi	d,0	;no delay
	call	vidskp	;skip over CL string
	call	vidskp	;skip over CM string
	call	vidskp	;skip over CE string
	mov	a,m	;get first char of SO string
	ora	a	;if no string, error
	jz	err
	call	vidout	;output string with delay
	jmp	noerr

;
; Terminate Standout Mode
;	Return with A=0 and Zero Flag Set if not done
;
stndend:
	push	b
	push	d
	push	h	;save regs
	lxi	h,z3env+80h	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	err
	lxi	d,17h	;pt to cls string
	dad	d
	mvi	d,0	;no delay
	call	vidskp	;skip over CL string
	call	vidskp	;skip over CM string
	call	vidskp	;skip over CE string
	call	vidskp	;skip over SO string
	mov	a,m	;get first char of SE string
	ora	a	;if no string, error
	jz	err
	call	vidout	;output string with delay
	jmp	noerr

;
; Initialize Terminal
;	Affect No Registers
;
tinit:
	push	h	;save regs
	push	d
	push	psw
	lxi	h,z3env+80h	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	tid
	lxi	d,17h	;pt to cls string
	dad	d
	mvi	d,0	;no delay
	call	vidskp	;skip over CL string
	call	vidskp	;skip over CM string
	call	vidskp	;skip over CE string
	call	vidskp	;skip over SO string
	call	vidskp	;skip over SE string
	mov	a,m	;get first char of TI string
	ora	a	;if no string, error
	jz	tid
	call	vidout	;output string with delay
tid:
	pop	psw	;done
	pop	d
	pop	h
	ret

;
; De-Initialize Terminal
;	Affect No Registers
;
dinit:
	push	h	;save regs
	push	d
	push	psw
	lxi	h,z3env+80h	;pt to environment
	mov	a,m	;no terminal?
	cpi	' '+1
	jc	tid
	lxi	d,17h	;pt to cls string
	dad	d
	mvi	d,0	;no delay
	call	vidskp	;skip over CL string
	call	vidskp	;skip over CM string
	call	vidskp	;skip over CE string
	call	vidskp	;skip over SO string
	call	vidskp	;skip over SE string
	call	vidskp	;skip over TI string
	mov	a,m	;get first char of TE string
	ora	a	;if no string, error
	jz	tid
	call	vidout	;output string with delay
	jmp	tid

;
;  VIDOUT - Output video string pted to by HL
;	Output also a delay contained in the D register
;
vidout:
	mov	a,m	;get next char
	ora	a	;done if zero
	jz	vid2
	inx	h	;pt to next
	cpi	'\'	;literal value?
	jnz	vid1
	mov	a,m	;get literal char
	inx	h	;pt to after it
vid1:
	call	cout	;output char
	jmp	vidout
vid2:
	mov	a,d	;output delay and fall thru to VIDELAY

;
;	VIDELAY pauses for the number of milliseconds indicated by the A
; register.  VIDELAY assumes a ZCPR3 environment and uses it to determine
; processor speed.
;
videlay:
	push	psw	;save regs
	push	b
	push	d
	push	h
	mov	c,a	;save count in C
	ora	a	;no delay?
	jz	done
	lxi	h,z3env	;pt to environment
	lxi	d,2Bh	;offset to processor speed
	dad	d
	mov	a,m	;get processor speed
	ora	a	;zero?
	jnz	vidl1
	mvi	a,4	;assume 4 MHz
vidl1:
	mov	b,a	;processor speed in B
vidl2:
	push	b	;delay 1 ms
	call	delay
	pop	b
	dcr	c	;count down
	jnz	vidl2
done:
	pop	h	;restore regs
	pop	d
	pop	b
	pop	psw
	ret
;
;  Delay 1 ms at Clock speed
;
delay:
	call	del1	;delay 1 ms at 1MHz
	dcr	b	;count down clock speed
	jnz	delay
	ret
;
;  Delay 1 ms at 1MHz
;
del1:
	mvi	c,20	;20 loops of 51 cycles each ~ 1000 cycles
del1a:
	xthl		;18 cycles
	xthl		;+18 = 36 cycles
	dcr	c	;+ 5 = 41 cycles
	jnz	del1a	;+10 = 51 cycles
	ret

;
;  VIDSKP - Skip over video string pted to by HL; pt to byte after string
;
vidskp:
	mov	a,m	;get next char
	inx	h	;pt to next
	ora	a	;done if zero
	rz
	cpi	'\'	;literal value?
	jnz	vidskp	;continue if not
	inx	h	;pt to after literal value
	jmp	vidskp

;
; Print A as 2 Hex Chars
;
pa2hc:
	push	psw
	push	b
	mov	b,a	;value in B
	rlc
	rlc
	rlc
	rlc
	call	pa2hc1
	mov	a,b	;get value
	call	pa2hc1
	pop	b
	pop	psw
	ret
pa2hc1:
	ani	0fh
	adi	'0'	;to ASCII
	cpi	'9'+1
	jc	pa2hc2
	adi	7	;to letter
pa2hc2:
	jmp	cout

;
; Skip Spaces
;
sksp:
	mov	a,m	;skip to non-space
	cpi	' '
	rnz
	inx	h
	jmp	sksp

;
;EDITOR BUFFERS
;
BLOCK:
	DS	2	;ADDRESS OF CURRENT BLOCK
BUFFER:
	DS	2	;PTR TO FREE SPACE
EINDEX:
	DS	1	;INDEX ENTRY
EDRUN:
	DS	1	;FLAG SAYING THAT EDITOR IS RUNNING

	end
