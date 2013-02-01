;-------------------------------------------------------------------------------
; Save to Space-Time Productions Z-80 directory on
;  February 22, 2007  and converted terms for TASM
;-------------------------------------------------------------------------------
; 
;-------------------------------------------------------------------------------
; This is an implementation of FORTH for the Z80 that should be easily portable
; to other Z80 systems. It assumes RAM from $9000 to $FFFF and a UART for
; communication with the host or VDU.
;-------------------------------------------------------------------------------
DATA_STACK:	.EQU	$FD80	; Data stack grows down
VOCAB_BASE:	.EQU	$F000	; Dictionary grows up from here
MASS_STORE:	.EQU	$FEA0	; Mass storage buffer (default)
DISK_START:	.EQU	$A000	; Pseudo disk buffer start
DISK_END:		.EQU	$F000	; Pseudo disk buffer end
BLOCK_SIZE:	.EQU	$0200	; Pseudo disk block size
BUFFERS:		.EQU	$0001	; Pseudo disk buffers per block
MONSTART:		.EQU	$0000	; Monitor entry address

SYSTEM:	.EQU	$FE00		; SYSTEM VARIABLES
S0:	.EQU	$FE06		; Initial value of Data SP
R0:	.EQU	$FE08		; Initial value of Return SP
TIB:	.EQU	$FE0A		; Terminal Input Buffer
WIDTH:	.EQU	$FE0C		; Number of letters saved in names
WARNING:	.EQU	$FE0E		; Error message control number
FENCE:	.EQU	$FE10		; Dictionary FORGET
DP:	.EQU	$FE12		; Dictionary Pointer
VOC_LINK:	.EQU	$FE14		; Most recently created vocabulary
BLK:	.EQU	$FE16		; Current block number interpretation
TOIN:	.EQU	$FE18		; Offset in the current input text buffer
OUT:	.EQU	$FE1A		; Offset in the current output text buff
SCR:	.EQU	$FE1C		; Screen number last ref'd by LIST
OFFSET:	.EQU	$FE1E		; Block offset for disk drives
CONTEXT:	.EQU	$FE20		; Pointer to vocabulary within which
				;  dictionary search will first begin
CURRENT:	.EQU	$FE22		; Pointer to the vocabulary within which
				;  new definitions are to be created
STATE:	.EQU	$FE24		; Contains state of compilation
BASE:	.EQU	$FE26		; Current I/O Base Address
DPL:	.EQU	$FE28		; Number of digits to the right of the
				;  decimal point on double integer input
FLD:	.EQU	$FE2A		; Field width for formatted number output
CSP:	.EQU	$FE2C		; Check SP
RHASH:	.EQU	$FE2E		; Location of editor cursor in a txt blk
HLD:	.EQU	$FE30		; Address of current output
FLAST:	.EQU	$FE32		; FORTH vocabulary data initialized
ELAST:	.EQU	$FE38		; Editor vocabulary data
CRFLAG:	.EQU	$FE3E		; Carriage Return flag
PAT:	.EQU	$FE40		; I/O port fetch routine INPUT
PST:	.EQU	$FE43		; I/O port store routine OUTPUT
RPP:	.EQU	$FE46		; Return SP
USE:	.EQU	$FE48		; Mass storage buffer address to use
PREV:	.EQU	$FE4A		; Mass storage buffer address just used
INTFLAG:	.EQU	$FE4C		; Interrupt flag and user byte following
INTVECT:	.EQU	$FE4E		; Interrupt vector
UTERMNL:	.EQU	$FE50		; Code field address of word ?TERMINAL
UKEY:	.EQU	$FE52		; Code field address of word KEY
UEMIT:	.EQU	$FE54		; Code field address of word EMIT
UCR:	.EQU	$FE56		; Code field address of word CR
URW:	.EQU	$FE58		; Code field address of word R/W
UABORT:	.EQU	$FE5A		; Code field address of word ABORT
UCL:	.EQU	$FE5C		; Number of chars per input line
UFIRST:	.EQU	$FE5E		; Start of pseudo disk buffer
ULIMIT:	.EQU	$FE60		; End of pseudo disk buffer
UBBUF:	.EQU	$FE62		; Number of bytes per block
UBSCR:	.EQU	$FE64		; Number of buffers per block
KEYBUF:	.EQU	$FE66		; Double key buffer
RAF:	.EQU	$FE68		; Register AF
RBC:	.EQU	$FE6A		; Register BC
RDE:	.EQU	$FE6C		; Register DE
RHL:	.EQU	$FE6E		; Register HL
RIX:	.EQU	$FE70		; Register IX
RIY:	.EQU	$FE72		; Register IY
RAF2:	.EQU	$FE74		; Register AF'
RBC2:	.EQU	$FE76		; Register BC'
RDE2:	.EQU	$FE78		; Register DE'
RHL2:	.EQU	$FE7A		; Regisetr HL'
JPCODE:	.EQU	$FE7D		; JP code ($C3) for word
JPVECT:	.EQU	$FE7E		; JP vector
;------------------------------------------------------------------------------
FORTH:	.ORG	$8000			; Start of RAM

	XOR	A			; Clear A
	LD	(KEYBUF),A		; Clear buffered key
	JP	X_COLD

BACKSPACE:
	.WORD	$0008			; Backspace chr

WORD1:	.WORD	DATA_STACK
DEF_SYSADDR:
	.WORD	SYSTEM
	.WORD	DATA_STACK
	.WORD	$001F			; Word name length (default 31)
	.WORD	$0000			; Error message control number
	.WORD	VOCAB_BASE		; FORGET protection
	.WORD	VOCAB_BASE+$0B		; Dictionary pointer
	.WORD	E_FORTH			; Most recently created vocab.

START_TABLE:
	.BYTE	$81,$A0
	.WORD	VOCAB_BASE
	.BYTE	$00,$00			; FLAST
	.BYTE	$81,$A0
	.WORD	W_EDITI
	.WORD	E_FORTH			; ELAST
	.BYTE	$00			; CRFLAG
	.BYTE	$00			; Free
	IN	A,($00)			; I/O Port input
	RET				; routine
	OUT	($00),A			; I/O Port output
	RET				; routine
	.WORD	SYSTEM 			; Return stack pointer
	.WORD	MASS_STORE		; Mass storage buffer to use
	.WORD	MASS_STORE		; Storage buffer just used
	.BYTE	$00			; Interrupt flag
	.BYTE	$00			; Free
	.WORD	C_ABORT			; Interrupt vector
	.WORD	CF_UQTERMINAL		; C field address ?TERMINAL
	.WORD	CF_UKEY			; C field address KEY
	.WORD	CF_UEMIT			; C field address EMIT
	.WORD	CF_UCR			; C field address CR
	.WORD	CF_URW			; C field address R/W
	.WORD	CF_UABORT			; C field address ABORT
	.WORD	$0020			; CHRs per input line
	.WORD	DISK_START		; Pseudo disk buf start
	.WORD	DISK_END			; Pseudo disk buf end
	.WORD	BLOCK_SIZE		; Bytes per block
	.WORD	BUFFERS			; Buffers per block

NEXTS2:	PUSH	DE
NEXTS1:	PUSH	HL
NEXT:	LD	A,(INTFLAG)		; Interrupt flag
	BIT	7,A			; Check for interrupt
	JR	Z,NOINT			; No interrupt
	BIT	6,A			; Interrupt enabled ?
	JR	NZ,NOINT			; No interrupt
	LD	HL,(INTVECT)		; Get nterrupt vector
	LD	A,$40			; Clear flag byte
	LD	(INTFLAG),A		; Interrupt flag into HL
	JR	NEXTADDR			; JP (HL)

NOINT:	LD	A,(BC)			; effectively LD HL,(BC)
	INC	BC			; 
	LD	L,A			; 
	LD	A,(BC)			; 
	INC	BC			; BC now points to next vector
	LD	H,A			; HL has addr vector

NEXTADDR:	LD	E,(HL)			; effectively LD HL,(HL)
	INC	HL			; 
	LD	D,(HL) 			; 
	EX	DE,HL 			; 
	JP	(HL) 			; Jump to it

W_LIT:	; Puts next 2 bytes on the stack
	.BYTE	$83,"LI",'T'+$80
	.WORD	$0000			; First word in vocabulary
C_LIT:	.WORD	2+$			; Vector to code
	LD	A,(BC)			; Gets next word from (BC)
	INC	BC			; then increments BC to point
	LD	L,A			; to the next addr. Pushes the
	LD	A,(BC)			; result onto the stack.
	INC	BC			; 
	LD	H,A			; 
	JP	NEXTS1			; Save & NEXT


W_EXECUTE:				; Jump to address on stack
	.BYTE	$87,"EXECUT",'E'+$80
	.WORD	W_LIT
C_EXECUTE:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr off data stack
	JP	NEXTADDR			; Basically JP (HL)


W_BRANCH:					; Add following offset to BC
	.BYTE	$86,"BRANC",'H'+$80
	.WORD	W_EXECUTE
C_BRANCH:	.WORD	2+$			; Vector to code
X_BRANCH:	LD	H,B			; Next pointer into HL
	LD	L,C			; 
	LD	E,(HL)			; Get word offset LD DE,(HL)
	INC	HL			; Incr to point at next byte
	LD	D,(HL)			; 
	DEC	HL 			; Restore HL
	ADD	HL,DE			; Calculate new address
	LD	C,L			; Put it in BC
	LD	B,H			; 
	JP	NEXT			; Go do it


W_0BRANCH:				; Add offset to BC if stack top = 0
	.BYTE	$87,"0BRANC",'H'+$80	; Conditional branch
	.WORD	W_BRANCH
C_0BRANCH:
	.WORD	2+$			; Vector to code
	POP	HL			; Get value off stack
	LD	A,L			; Set flags
	OR	H			; 
	JR	Z,X_BRANCH		; If zero then do the branch
	INC	BC			; Else dump branch address
	INC	BC			; 
	JP	NEXT			; Continue execution

W_LLOOP:					; Increment loop & branch if not done
	.BYTE	$86,"<LOOP",'>'+$80
	.WORD	W_0BRANCH
C_LLOOP:
	.WORD	2+$			; Vector to code
	LD	DE,0001
C_ILOOP:
	LD	HL,(RPP)			; Get return stack pointer
	LD	A,(HL)			; Add DE to value on return stack
	ADD	A,E			; 
	LD	(HL),A			; 
	LD	E,A			; 
	INC	HL			; 
	LD	A,(HL)			; 
	ADC	A,D			; 
	LD	(HL),A			; 
	INC	HL			; HL now points to limit value
	INC	D			; Get Ds sign bit
	DEC	D			; 
	LD	D,A			; Result now in DE
	JP	M,DECR_LOOP		; Decrement loop so check > limit
					; otherwies check < limit
	LD	A,E			; Low byte back
	SUB	(HL)			; Subtract limit low
	LD	A,D			; High byte back
	INC	HL			; Point to limit high
	SBC	A,(HL)			; Subtract it
	JR	TEST_LIMIT		; 
DECR_LOOP:
	LD	A,(HL)			; Get limit low
	SUB	E			; Subtract index low
	INC	HL			; Point to limit high
	LD	A,(HL)			; Get it
	SBC	A,D			; Subtract index high
TEST_LIMIT:
	JP	M,X_BRANCH		; Not reached limit so jump
	INC	HL			; Drop index & limit from return stack
	LD	(RPP),HL			; Save stack pointer
	INC	BC			; Skip branch offset
	INC	BC			; 
	JP	NEXT

W_PLOOP:					; Loop + stack & branch if not done
	.BYTE	$87,"<+LOOP",'>'+$80
	.WORD	W_LLOOP
C_PLOOP:
	.WORD	2+$			; Vector to code
	POP	DE			; Get value from stack
	JR	C_ILOOP			; Go do loop increment

W_LDO:					; Put start & end loop values on RPP
	.BYTE	$84,"<DO",'>'+$80
	.WORD	 W_PLOOP
C_LDO:
	.WORD	 2+$
	LD	HL,(RPP)			; Get return stack pointer
	DEC	HL			; Add space for two values
	DEC	HL			; 
	DEC	HL			; 
	DEC	HL			; 
	LD	(RPP),HL			; Save new stack pointer
	POP	DE			; Get start value &
	LD	(HL),E			; put on return stack top
	INC	HL			; 
	LD	(HL),D			; 
	INC	HL			; 
	POP	DE			; Get end value &
	LD	(HL),E			; put on return stack - 1
	INC	HL			; 
	LD	(HL),D			; 
	JP	NEXT

W_I:					; Copy LOOP index to data stack
	.BYTE	$81,'I'+$80
	.WORD	 W_LDO
C_I:
	.WORD	 2+$
X_I:
	LD	HL,(RPP)			; Get return stack pointer
X_I2:
	LD	E,(HL)			; Get LOOP index off return stack
	INC	HL			; 
	LD	D,(HL)			; 
	PUSH	DE			; Push onto data stack
	JP	NEXT

W_DIGIT:					; Convert digit n2 using base n1
	.BYTE	$85,"DIGI",'T'+$80
	.WORD	 W_I
C_DIGIT:
	.WORD	2+$
	POP	HL			; Get base to use
	POP	DE			; Get char
	LD	A,E			; A = char
	SUB	$30			; Subtract 30h
	JP	M,NDIGIT		
	CP	$0A			; Greater than 9 ?
	JP	M,LESS10			; If not then skip
	SUB	$07			; Convert 'A' to 10
	CP	$0A			; Is it 10?
	JP	M,NDIGIT			; If not an error occured
LESS10:
	CP	L			; L is 1 digit limit
	JP	P,NDIGIT			; Out of range for digit
	LD	E,A			; Result into DE
	LD	HL,0001			; Leave TRUE flag
	JP	NEXTS2			; Save both & NEXT
NDIGIT:
	LD	L,H			; Leave FALSE flag
	JP	NEXTS1			; Save & NEXT

W_FIND:					; Find word & return vector,byte & flag
	.BYTE	$86,"<FIND",'>'+$80
	.WORD	W_DIGIT
C_FIND:
	.WORD	2+$			; Vector to code
	POP	DE			; Get pointer to next vocabulary word
COMPARE:
	POP	HL			; Copy pointer to word we're looking 4
	PUSH	HL			; 
	LD	A,(DE)			; Get 1st vocabulary word letter
	XOR	(HL)			; Compare with what we've got
	AND	$3F			; Ignore start flag
	JR	NZ,NOT_END_CHR		; No match so skip to next word
MATCH_NO_END:
	INC	HL			; Compare next chr
	INC	DE			; 
	LD	A,(DE)			; 
	XOR	(HL)			; 
	ADD	A,A			; Move bit 7 to C flag
	JR	NZ,NO_MATCH		; No match jump
	JR	NC,MATCH_NO_END		; Match & not last, so next chr
	LD	HL,0005			; Offset to start of code
	ADD	HL,DE			; HL now points to code start for word
	EX	(SP),HL			; Swap with value on stack
NOT_WORD_BYTE:
	DEC	DE			; Search back for word type byte
	LD	A,(DE)			; 
	OR	A			; 
	JP	P,NOT_WORD_BYTE		; Not yet so loop
	LD	E,A			; Byte into DE
	LD	D,$00			; 
	LD	HL,0001			; Leave TRUE flag
	JP	NEXTS2			; Save both & NEXT
NO_MATCH:
	JR	C,END_CHR			; If last chr then jump
NOT_END_CHR:
	INC	DE			; Next chr of this vocab word
	LD	A,(DE)			; Get it
	OR	A			; Set flags
	JP	P,NOT_END_CHR		; Loop if not end chr
END_CHR:
	INC	DE			; Now points to next word vector
	EX	DE,HL			; Swap
	LD	E,(HL)			; Vector into DE
	INC	HL			; 
	LD	D,(HL)			; 
	LD	A,D			; Check it's not last (first) word
	OR	E			; 
	JR	NZ,COMPARE		; No error so loop
	POP	HL			; Dump pointer
	LD	HL,0000			; Flag error
	JP	NEXTS1			; Save & NEXT

W_ENCLOSE:
	.BYTE	$87,"ENCLOS",'E'+$80
	.WORD	W_FIND
C_ENCLOSE:
	.WORD	2+$			; Vector to code
	POP	DE			; get delimiter character
	POP	HL			; get address 1
	PUSH	HL			; duplicate it
	LD	A,E			; delimiter char into A
	LD	D,A			; copy to D
	LD	E,$ff			;-1 for offset
	DEC	HL			; to allow for first INCR
J21E6:
	INC	HL			; point to next chr
	INC	E			; next offset
	CP	(HL)			; compare chr with (address)
	JR	Z,J21E6			; loop if = delimiter chr
	LD	A,$0D			; else set CR
	CP	(HL)			; compare with (address)
	LD	A,D			; restore delimiter chr
	JR	Z,J21E6			; loop if it was = CR
	LD	D,$00			; zero high byte
	PUSH	DE			; save offset
	LD	D,A			; restore delimiter chr
	LD	A,(HL)			; get byte from address
	AND	A			; set the flags
	JR	NZ,J2202			; branch if not null
	LD	D,$00			; clear high byte
	INC	E			; point to next addr
	PUSH	DE			; save address
	DEC	E			; point to end
	PUSH	DE			; push address
	JP	NEXT			; done
J2202:
	LD	A,D			; restore delimiter chr
	INC	HL			; increment address
	INC	E			; increment offset
	CP	(HL)			; compare delimiter with (address)
	JR	Z,J2218			; jump if =
	LD	A,$0D			; else get CR
	CP	(HL)			; compare with (address)
	JR	Z,J2218			; jump if =
	LD	A,(HL)			; else get byte
	AND	A			; set the flags
	JR	NZ,J2202			; loop if not null
	LD	D,$00			; clear gigh byte
	PUSH	DE			; save address
	PUSH	DE			; save address
	JP	NEXT			; done
J2218:
	LD	D,$00			; clear high byte
	PUSH	DE			; save address
	INC	E			; increment offset
	PUSH	DE			; save address
	JP	NEXT			; done

W_EMIT:					; Output CHR from stack
	.BYTE	$84,"EMI",'T'+$80
	.WORD	W_ENCLOSE
C_EMIT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UEMIT			; Put UEMIT addr on stack
	.WORD	C_FETCH			; Get UEMIT code field address
	.WORD	C_EXECUTE			; Jump to address on stack
	.WORD	C_1
	.WORD	C_OUT
	.WORD	C_PLUSSTORE
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_KEY:					; Wait for key, value on stack
	.BYTE	$83,"KE",'Y'+$80
	.WORD	W_EMIT
C_KEY:
	.WORD	2+$			; Vector to code
	LD	HL,(UKEY)			; Get the vector
	JP	(HL)			; Jump to it

; 	.WORD	E_COLON			; Interpret following word sequence
; 	.WORD	C_UKEY			; Put UKEY addr on stack
; 	.WORD	C_FETCH			; Get CF_KEY
; 	.WORD	C_EXECUTE			; Jump to CF_KEY
; 	.WORD	C_STOP			; Pop BC from return stack (=next)


W_TERMINAL:
	.BYTE	$89,"?TERMINA",'L'+$80
	.WORD	W_KEY
C_TERMINAL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UTERMINAL
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_EXECUTE			; Jump to address on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CR:					; Output [CR][LF]
	.BYTE	$82,"C",'R'+$80
	.WORD	W_TERMINAL
C_CR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UCR			; Push UCR addr
	.WORD	C_FETCH			; Get UCR code field addr
	.WORD	C_EXECUTE			; Jump to address on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CLS:					; Clear screen
	.BYTE	$83,"CL",'S'+$80
	.WORD	W_CR
C_CLS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Put clear screen code on stack
	.WORD	000Ch			; 
	.WORD	C_EMIT			; Output it
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CMOVE:					; Move block
	.BYTE	$85,"CMOV",'E'+$80
	.WORD	W_CLS
C_CMOVE:
	.WORD	2+$			; Vector to code
	LD	L,C			; Save BC for now
	LD	H,B			; 
	POP	BC			; Get no. of bytes to move
	POP	DE			; Get destination address
	EX	(SP),HL			; Get source address
	LD	A,B			; Check it's not a 0 length block
	OR	C			; 
	JR	Z,NO_BYTES		; If 0 length then do nothing
	LDIR				; Move block
NO_BYTES:
	POP	BC			; Get BC back
	JP	NEXT

W_USTAR:					; Unsigned multiply
	.BYTE	$82,"U",'*'+$80
	.WORD	W_CMOVE
C_USTAR:
	.WORD	2+$			; Vector to code
	POP	DE			; get n2
	POP	HL			; get n1
	PUSH	BC			; save BC for now
	LD	C,H			; save H
	LD	A,L			; low byte to multiply by
	CALL	HALF_TIMES		; HL = A * DE
	PUSH	HL			; save partial result
	LD	H,A			; clear H
	LD	A,C			; high byte to multiply by
	LD	C,H			; clear B
	CALL	HALF_TIMES		; HL = A * DE 
	POP	DE			; get last partial result
	LD	B,C			; add partial results
	LD	C,D			; add partial results
	ADD	HL,BC			; 
	ADC	A,$00			; 
	LD	D,L			; 
	LD	L,H			; 
	LD	H,A			; 
	POP	BC			; get BC back
	JP	NEXTS2			; save 32 bit result & NEXT

HALF_TIMES:				; 
	LD	HL,$0000			; clear partial result
	LD	B,08h			; eight bits to do
NEXT_BIT:
	ADD	HL,HL			; result * 2
	RLA				; multiply bit into C
	JR	NC,NO_MUL			; branch if no multiply
	ADD	HL,DE			; add multiplicand
	ADC	A,$00			; add in any carry
NO_MUL:
	DJNZ	NEXT_BIT			; decr and loop if not done
	RET				; 

W_UMOD:					; Unsigned divide & MOD
	.BYTE	$85,"U/MO",'D'+$80
	.WORD	W_USTAR
C_UMOD:
	.WORD	2+$			; Vector to code
	LD	HL,0004
	ADD	HL,SP 
	LD	E,(HL) 
	LD	(HL),C 
	INC	HL 
	LD	D,(HL) 
	LD	(HL),B 
	POP	BC 
	POP	HL 
	LD	A,L 
	SUB	C 
	LD	A,H 
	SBC	A,B 
	JR	C,J22DB
	LD	HL,$FFFF
	LD	DE,$FFFF
	JR	J2301
J22DB:
	LD	A,10h
J22DD:
	ADD	HL,HL 
	RLA 
	EX	DE,HL 
	ADD	HL,HL 
	JR	NC,J22E5
	INC	DE 
	AND	A 
J22E5:
	EX	DE,HL 
	RRA 
	PUSH	AF 
	JR	NC,J22F2
	LD	A,L 
	SUB	C 
	LD	L,A 
	LD	A,H 
	SBC	A,B 
	LD	H,A 
	JR	J22FC
J22F2:
	LD	A,L 
	SUB	C 
	LD	L,A 
	LD	A,H 
	SBC	A,B 
	LD	H,A 
	JR	NC,J22FC
	ADD	HL,BC 
	DEC	DE 
J22FC:
	INC	DE 
	POP	AF 
	DEC	A 
	JR	NZ,J22DD
J2301:
	POP	BC 
	PUSH	HL 
	PUSH	DE 
	JP	NEXT

W_AND:					; AND
	.BYTE	$83,"AN",'D'+$80
	.WORD	W_UMOD
C_AND:
	.WORD	2+$			; Vector to code
	POP	DE			; Get n1 off stack
	POP	HL			; Get n2 off stack
	LD	A,E			; AND lo bytes
	AND	L			; 
	LD	L,A			; Result in L
	LD	A,D			; AND hi bytes
	AND	H			; 
	LD	H,A			; Result in H
	JP	NEXTS1			; Save & next

W_OR:					; OR
	.BYTE	$82,"O",'R'+$80
	.WORD	W_AND
C_OR:
	.WORD	2+$			; Vector to code
	POP	DE			; Get n1 off stack
	POP	HL			; Get n2 off stack
	LD	A,E			; OR lo bytes
	OR	L			; 
	LD	L,A			; Result in L
	LD	A,D			; OR hi bytes
	OR	H			; 
	LD	H,A			; Result in H
	JP	NEXTS1			; Save & next

W_XOR:					; XOR
	.BYTE	$83,"XO",'R'+$80
	.WORD	W_OR
C_XOR:
	.WORD	2+$			; Vector to code
	POP	DE			; Get n1 off stack
	POP	HL			; Get n2 off stack
	LD	A,E			; XOR lo bytes
	XOR	L			; 
	LD	L,A			; Result in L
	LD	A,D			; XOR hi bytes
	XOR	H			; 
	LD	H,A			; Result in H
	JP	NEXTS1			; Save & NEXT

W_SPFETCH:				; Stack pointer onto stack
	.BYTE	$83,"SP",'@'+$80
	.WORD	W_XOR
C_SPFETCH:
	.WORD	2+$			; Vector to code
	LD	HL,0000			; No offset
	ADD	HL,SP			; Add SP to HL
	JP	NEXTS1			; Save & NEXT

W_SPSTORE:				; Set initial stack pointer value
	.BYTE	$83,"SP",'!'+$80
	.WORD	W_SPFETCH
C_SPSTORE:
	.WORD	2+$			; Vector to code
	LD	HL,(DEF_SYSADDR)		; Get system base addr
	LD	DE,S0-SYSTEM		; Offset to stack pointer value (0006)
	ADD	HL,DE			; Add to base addr
	LD	E,(HL)			; Get SP from ram
	INC	HL			; 
	LD	D,(HL)			; 
	EX	DE,HL			; Put into HL
	LD	SP,HL			; Set SP
	JP	NEXT

W_RPFETCH:				; Get return stack pointer
	.BYTE	$83,"RP",'@'+$80
	.WORD	W_SPSTORE
C_RPFETCH:
	.WORD	2+$			; Vector to code
	LD	HL,(RPP)			; Return stack pointer into HL
	JP	NEXTS1			; Save & NEXT

W_RPSTORE:				; Set initial return stack pointer
	.BYTE	$83,"RP",'!'+$80
	.WORD	W_RPFETCH
C_RPSTORE:
	.WORD	2+$			; Vector to code
	LD	HL,(DEF_SYSADDR)		; Get system base addr
	LD	DE,0008			; Offset to return stack pointer value
	ADD	HL,DE			; Add to base addr
	LD	E,(HL)			; Get SP from ram
	INC	HL			; 
	LD	D,(HL)			; 
	EX	DE,HL			; Put into HL
	LD	(RPP),HL			; Set return SP
	JP	NEXT

W_STOP:					; Pop BC from return stack (=next)
	.BYTE	$82,"; ",'S'+$80
	.WORD	W_RPSTORE
C_STOP:
	.WORD	2+$			; Vector to code
X_STOP:
	LD	HL,(RPP)			; Return stack pointer to HL
	LD	C,(HL)			; Get low byte
	INC	HL			; 
	LD	B,(HL)			; Get high byte
	INC	HL			; 
	LD	(RPP),HL			; Save stack pointer
	JP	NEXT

W_LEAVE:					; Quit loop by making index = limit
	.BYTE	$85,"LEAV",'E'+$80
	.WORD	W_STOP
C_LEAVE:
	.WORD	2+$			; Vector to code
	LD	HL,(RPP)			; Get return stack pointer
	LD	E,(HL)			; Get loop limit low
	INC	HL			; 
	LD	D,(HL)			; Get loop limit high
	INC	HL			; 
	LD	(HL),E			; Set index low to loop limit
	INC	HL			; 
	LD	(HL),D			; Set index high to loop limit
	JP	NEXT

W_MOVER:					; Move from data to return stack
	.BYTE	$82,">",'R'+$80
	.WORD	W_LEAVE
C_MOVER:
	.WORD	2+$			; Vector to code
	POP	DE			; Get value
	LD	HL,(RPP)			; Get return stack pointer
	DEC	HL			; Set new value
	DEC	HL			; 
	LD	(RPP),HL			; Save it
	LD	(HL),E			; Push low byte onto return stack
	INC	HL			; 
	LD	(HL),D			; Push high byte onto return stack
	JP	NEXT

W_RMOVE:					; Move word from return to data stack
	.BYTE	$82,"R",'>'+$80
	.WORD	W_MOVER
C_RMOVE:
	.WORD	2+$			; Vector to code
	LD	HL,(RPP)			; Get return stack pointer	
	LD	E,(HL)			; Pop word off return stack
	INC	HL			; 
	LD	D,(HL)			; 
	INC	HL			; 
	LD	(RPP),HL			; Save new return stack pointer
	PUSH	DE			; Push on data stack
	JP	NEXT

W_RFETCH:					; Return stack top to data stack
	.BYTE	$82,"R",'@'+$80
	.WORD	W_RMOVE
C_RFETCH:
	.WORD	X_I			; Return stack top to data stack


W_0EQUALS:				; =0
	.BYTE	$82,"0",'='+$80
	.WORD	W_RFETCH
C_0EQUALS:
	.WORD	2+$			; Vector to code
X_0EQUALS:
	POP	HL			; Get value from stack
	LD	A,L			; set flags
	OR	H			; 
	LD	HL,0000			; Not = 0 flag
	JR	NZ,NO_ZERO		; 
	INC	HL			; = 0 flag
NO_ZERO:
	JP	NEXTS1			; Save & NEXT

W_NOT:					; Convert flag, same as 0=
	.BYTE	$83,"NO",'T'+$80
	.WORD	W_0EQUALS
C_NOT:
	.WORD	X_0EQUALS

W_0LESS:					; Less than 0
	.BYTE	$82,"0",'<'+$80
	.WORD	W_NOT
C_0LESS:
	.WORD	2+$			; Vector to code
	POP	HL			; Get value
	ADD	HL,HL			; S bit into C
	LD	HL,0000			; Wasn't < 0 flag
	JR	NC,NOT_LT0		; 
	INC	HL			; Was < 0 flag
NOT_LT0:	JP	NEXTS1			; Save & NEXT

W_PLUS:					; n1 + n2
	.BYTE	$81,'+'+$80
	.WORD	W_0LESS
C_PLUS:
	.WORD	2+$			; Vector to code
	POP	DE			; Get n2
	POP	HL			; Get n1
	ADD	HL,DE			; Add them
	JP	NEXTS1			; Save & NEXT

W_DPLUS:					; 32 bit add
	.BYTE	$82,"D",'+'+$80
	.WORD	W_PLUS
C_DPLUS:
	.WORD	2+$			; Vector to code
	LD	HL,0006			; offset to low word
	ADD	HL,SP			; add stack pointer
	LD	E,(HL)			; get d1 low word low byte
	LD	(HL),C			; save BC low byte
	INC	HL			; point to high byte
	LD	D,(HL)			; get d1 low word high byte
	LD	(HL),B			; save BC high byte
	POP	BC			; get high word d2
	POP	HL			; get low word d2
	ADD	HL,DE			; add low words
	EX	DE,HL			; save result low word in DE
	POP	HL			; get d1 high word
	LD	A,L			; copy d1 high word low byte
	ADC	A,C			; add d2 high word low byte
					; + carry from low word add
	LD	L,A			; result from high word low byte into L
	LD	A,H			; copy d1 high word low byte
	ADC	A,B			; add d2 high word low byte
					; + carry from high word low byte add
	LD	H,A			; result from high word high byte into H
	POP	BC			; restore BC
	JP	NEXTS2			; Save 32 bit result & NEXT

W_NEGATE:					; Form 2s complement of n
	.BYTE	$86,"NEGAT",'E'+$80
	.WORD	W_DPLUS
C_NEGATE:
	.WORD	2+$			; Vector to code
	POP	HL			; Get number
	LD	A,L			; Low byte into A
	CPL				; Complement it
	LD	L,A			; Back into L
	LD	A,H			; High byte into A
	CPL				; Complement it
	LD	H,A			; Back into H
	INC	HL			; +1
	JP	NEXTS1			; Save & NEXT

W_DNEGATE:				; Form 2s complement of 32 bit n
	.BYTE	$87,"DNEGAT",'E'+$80
	.WORD	W_NEGATE
C_DNEGATE:
	.WORD	2+$			; Vector to code
	POP	HL			; get high word
	POP	DE			; get low word
	SUB	A			; clear A
	SUB	E			; negate low word low byte
	LD	E,A			; copy back to E
	LD	A,$00			; clear A
	SBC	A,D			; negate low word high byte
	LD	D,A			; copy back to D
	LD	A,$00			; clear A
	SBC	A,L			; negate high word low byte
	LD	L,A			; copy back to L
	LD	A,$00			; clear A
	SBC	A,H			; negate high word high byte
	LD	H,A			; copy back to H
	JP	NEXTS2			; Save 32 bit result & NEXT

W_OVER:					; Copy 2nd down to top of stack
	.BYTE	$84,"OVE",'R'+$80
	.WORD	W_DNEGATE
C_OVER:
	.WORD	2+$			; Vector to code
	POP	DE			; Get top
	POP	HL			; Get next
	PUSH	HL			; Save it back
	JP	NEXTS2			; Save both & NEXT

W_DROP:					; Drop top value from stack
	.BYTE	$84,"DRO",'P'+$80
	.WORD	W_OVER
C_DROP:
	.WORD	2+$			; Vector to code
	POP	HL			; Get top value
	JP	NEXT

W_2DROP:					; Drop top two values from stack
	.BYTE	$85,"2DRO",'P'+$80
	.WORD	W_DROP
C_2DROP:
	.WORD	2+$			; Vector to code
	POP	HL			; Get top value
	POP	HL			; Get top value
	JP	NEXT

W_SWAP:					; Swap top 2 values on stack
	.BYTE	$84,"SWA",'P'+$80
	.WORD	W_2DROP
C_SWAP:
	.WORD	2+$			; Vector to code
	POP	HL			; Get top value
	EX	(SP),HL			; Exchanhe with next down
	JP	NEXTS1			; Save & NEXT

W_DUP:					; Duplicate top value on stack
	.BYTE	$83,"DU",'P'+$80
	.WORD	W_SWAP
C_DUP:
	.WORD	2+$			; Vector to code
	POP	HL			; Get value off stack
	PUSH	HL			; Copy it back
	JP	NEXTS1			; Save & NEXT

W_2DUP:					; Dup top 2 values on stack
	.BYTE	$84,"2DU",'P'+$80
	.WORD	W_DUP
C_2DUP:
	.WORD	2+$			; Vector to code
	POP	HL			; Get top two values from stack
	POP	DE			; 
	PUSH	DE			; Copy them back
	PUSH	HL			; 
	JP	NEXTS2			; Save both & NEXT

W_BOUNDS:					; Convert address & n to start & end
	.BYTE	$86,"BOUND",'S'+$80
	.WORD	W_2DUP
C_BOUNDS:
	.WORD	2+$			; Vector to code
	POP	HL			; get n
	POP	DE			; get addr
	ADD	HL,DE			; add addr to n
	EX	DE,HL			; swap them
	JP	NEXTS2			; save both & NEXT

W_PLUSSTORE:				; Add n1 to addr
	.BYTE	$82,"+",'!'+$80
	.WORD	W_BOUNDS
C_PLUSSTORE:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	POP	DE			; Get DE
	LD	A,(HL)			; Add low bytes
	ADD	A,E			; 
	LD	(HL),A			; Store result
	INC	HL			; Point to high byte
	LD	A,(HL)			; Add high bytes
	ADC	A,D			; 
	LD	(HL),A			; Store result
	JP	NEXT

W_TOGGLE:					; XOR (addr) with byte
	.BYTE	$86,"TOGGL",'E'+$80
	.WORD	W_PLUSSTORE
C_TOGGLE:
	.WORD	2+$			; Vector to code
	POP	DE			; Get byte
	POP	HL			; Get addr
	LD	A,(HL)			; Get byte from addr
	XOR	E			; Toggle it
	LD	(HL),A			; Save result
	JP	NEXT

W_FETCH:					; Get word from addr on stack
	.BYTE	$81,'@'+$80
	.WORD	W_TOGGLE
C_FETCH:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	LD	E,(HL)			; Get low byte
	INC	HL			; 
	LD	D,(HL)			; Get high byte
	PUSH	DE			; Save it
	JP	NEXT

W_CFETCH:					; Get byte from addr on stack
	.BYTE	$82,"C",'@'+$80
	.WORD	W_FETCH
C_CFETCH:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	LD	L,(HL)			; Get byte
	LD	H,$00			; Top byte = 0
	JP	NEXTS1			; Save & NEXT

W_2FETCH:					; Get word from addr+2 and addr
	.BYTE	$82,"2",'@'+$80
	.WORD	W_CFETCH
C_2FETCH:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	LD	DE,0002			; Plus 2 bytes
	ADD	HL,DE			; Get 2nd word first
	LD	E,(HL)			; Low byte
	INC	HL			; 
	LD	D,(HL)			; High byte
	PUSH	DE			; Save it
	LD	DE,$FFFD			; Minus 2 bytes
	ADD	HL,DE			; Get 1st word
	LD	E,(HL)			; Low byte
	INC	HL			; 
	LD	D,(HL)			; High byte
	PUSH	DE			; Save it
	JP	NEXT

W_STORE:					; Store word at addr
	.BYTE	$81,'!'+$80
	.WORD	W_2FETCH
C_STORE:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	POP	DE			; Get word
	LD	(HL),E			; Store low byte
	INC	HL			; 
	LD	(HL),D			; Store high byte
	JP	NEXT

W_CSTORE:					; Store byte at addr
	.BYTE	$82,"C",'!'+$80
	.WORD	W_STORE
C_CSTORE:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	POP	DE			; Get byte
	LD	(HL),E			; Save it
	JP	NEXT

W_2STORE:					; Store 2 words at addr (+2)
	.BYTE	$82,"2",'!'+$80
	.WORD	W_CSTORE
C_2STORE:
	.WORD	2+$			; Vector to code
	POP	HL			; Get addr
	POP	DE			; Get word
	LD	(HL),E			; Save low byte
	INC	HL			; 
	LD	(HL),D			; Save high byte
	INC	HL			; 
	POP	DE			; Get next word
	LD	(HL),E			; Save low byte
	INC	HL			; 
	LD	(HL),D			; Save high byte
	JP	NEXT

W_COLON:
	.BYTE	$81,':'+$80
	.WORD	W_2STORE
C_COLON:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QEXEC			; Error not if not in execute mode
	.WORD	C_CSPSTORE		; Set current stack pointer value
	.WORD	C_CURRENT			; Get CURRENT addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CONTEXT			; Make CONTEXT current vocab
	.WORD	C_STORE			; Store word at addr
	.WORD	C_XXX1			; Puts name into dictionary
	.WORD	C_RIGHTBRKT		; Set STATE to compile
	.WORD	C_CCODE			; Execute following machine code

E_COLON:
	LD	HL,(RPP)			; Get return stack pointer
	DEC	HL			; Put BC on return stack
	LD	(HL),B			; 
	DEC	HL			; 
	LD	(HL),C			; 
	LD	(RPP),HL			; Save new pointer
	INC	DE
	LD	C,E 
	LD	B,D 
	JP	NEXT

W_SEMICOLON:				; Terminate compilation
	.BYTE	$C1,'; '+$80
	.WORD	W_COLON
C_SEMICOLON:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QCOMP			; Check we're allready compiling
	.WORD	C_WHATSTACK		; Check stack pointer, error if not ok
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_STOP			; 
	.WORD	C_SMUDGE			; Smudge bit to O.K.
	.WORD	C_LEFTBRKT		; Set STATE to execute
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CONSTANT:
	.BYTE	$88,"CONSTAN",'T'+$80
	.WORD	W_SEMICOLON
C_CONSTANT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_XXX1
	.WORD	C_SMUDGE
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_CCODE			; Execute following machine code

X_CONSTANT:				; Put next word on stack
	INC	DE			; Adjust pointer
	EX	DE,HL			; Get next word
	LD	E,(HL)			; 
	INC	HL			; 
	LD	D,(HL)			; 
	PUSH	DE			; Put on stack
	JP	NEXT

W_VARIABLE:
	.BYTE	$88,"VARIABL",'E'+$80
	.WORD	W_CONSTANT
C_VARIABLE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_CONSTANT
	.WORD	C_CCODE			; Execute following machine code

X_VARIABLE:
	INC	DE 
	PUSH	DE 
	JP	NEXT

W_USER:
	.BYTE	$84,"USE",'R'+$80
	.WORD	W_VARIABLE
C_USER:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CONSTANT
	.WORD	C_CCODE			; Execute following machine code

X_USER:
	INC	DE			; Adjust to next word
	EX	DE,HL
	LD	E,(HL) 
	INC	HL 
	LD	D,(HL) 
	LD	HL,(DEF_SYSADDR) 
	ADD	HL,DE 
	JP	NEXTS1			; Save & NEXT

W_ZERO:					; Put zero on stack
	.BYTE	$81,'0'+$80
	.WORD	W_USER
C_ZERO:
	.WORD	X_CONSTANT		; Put next word on stack
	.WORD	$0000

W_1:					; Put 1 on stack
	.BYTE	$81,'1'+$80
	.WORD	W_ZERO
C_1:
	.WORD	X_CONSTANT		; Put next word on stack
	.WORD	0001h

W_2:
	.BYTE	$81,'2'+$80
	.WORD	W_1
C_2:
	.WORD	X_CONSTANT		; Put next word on stack
	.WORD	0002h

W_3:
	.BYTE	$81,'3'+$80
	.WORD	W_2
C_3:
	.WORD	X_CONSTANT		; Put next word on stack
	.WORD	0003h

W_BL:					; Leaves ASCII for blank on stack
	.BYTE	$82,"B",'L'+$80
	.WORD	W_3
C_BL:
	.WORD	X_CONSTANT		; Put next word on stack
	.WORD	0020h

W_CL:
	.BYTE	$83,"C/",'L'+$80
	.WORD	W_BL
C_CL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UCL
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_FIRST:
	.BYTE	$85,"FIRS",'T'+$80
	.WORD	W_CL
C_FIRST:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UFIRST			; Put UFIRST addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LIMIT:
	.BYTE	$85,"LIMI",'T'+$80
	.WORD	W_FIRST
C_LIMIT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ULIMIT			; Put ULIMIT on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BBUF:
	.BYTE	$85,"B/BU",'F'+$80
	.WORD	W_LIMIT
C_BBUF:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UBBUF
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BSCR:
	.BYTE	$85,"B/SC",'R'+$80
	.WORD	W_BBUF
C_BSCR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UBSCR			; Number of buffers per block
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_S0:					; Push S0 (initial data stack pointer)
	.BYTE	$82,"S",'0'+$80
	.WORD	W_BSCR
C_S0:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	S0-SYSTEM

W_R0:
	.BYTE	$82,"R",'0'+$80
	.WORD	W_S0
C_R0:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	R0-SYSTEM

W_TIB:
	.BYTE	$83,"TI",'B'+$80
	.WORD	W_R0
C_TIB:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	TIB-SYSTEM

W_WIDTH:
	.BYTE	$85,"WIDT",'H'+$80
	.WORD	W_TIB
C_WIDTH:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	WIDTH-SYSTEM

W_WARNING:				; Put WARNING addr on stack
	.BYTE	$87,"WARNIN",'G'+$80
	.WORD	W_WIDTH
C_WARNING:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	WARNING-SYSTEM

W_FENCE:
	.BYTE	$85,"FENC",'E'+$80
	  	.WORD	W_WARNING
C_FENCE:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	FENCE-SYSTEM

W_DP:					; Dictionary pointer addr on stack
	.BYTE	$82,"D",'P'+$80
	.WORD	W_FENCE
C_DP:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	DP-SYSTEM

W_VOC_LINK:
	.BYTE	$88,"VOC-LIN",'K'+$80
	.WORD	W_DP
C_VOC_LINK:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	VOC_LINK-SYSTEM

W_BLK:
	.BYTE	$83,"BL",'K'+$80
	.WORD	W_VOC_LINK
C_BLK:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	BLK-SYSTEM

W_TOIN:
	.BYTE	$83,">I",'N'+$80
	.WORD	W_BLK
C_TOIN:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	TOIN-SYSTEM

W_OUT:					; Put OUT buffer count addr on stack
	.BYTE	$83,"OU",'T'+$80
	.WORD	W_TOIN
C_OUT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	OUT-SYSTEM

W_SCR:
	.BYTE	$83,"SC",'R'+$80
	.WORD	W_OUT
C_SCR:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	SCR-SYSTEM

W_OFFSET:					; Put disk block offset on stack
	.BYTE	$86,"OFFSE",'T'+$80
	.WORD	W_SCR
C_OFFSET:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	OFFSET-SYSTEM

W_CONTEXT:
	.BYTE	$87,"CONTEX",'T'+$80
	.WORD	W_OFFSET
C_CONTEXT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	CONTEXT-SYSTEM

W_CURRENT:
	.BYTE	$87,"CURREN",'T'+$80
	.WORD	W_CONTEXT
C_CURRENT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	CURRENT-SYSTEM

W_STATE:					; Push STATE addr
	.BYTE	$85,"STAT",'E'+$80
	.WORD	W_CURRENT
C_STATE:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	STATE-SYSTEM

W_BASE:					; Put BASE addr on stack
	.BYTE	$84,"BAS",'E'+$80
	.WORD	W_STATE
C_BASE:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	BASE-SYSTEM

W_DPL:
	.BYTE	$83,"DP",'L'+$80
	.WORD	W_BASE
C_DPL:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	DPL-SYSTEM

W_FLD:
	.BYTE	$83,"FL",'D'+$80
	.WORD	W_DPL
C_FLD:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	FLD-SYSTEM

W_CSP:					; Push check stack pointer addr
	.BYTE	$83,"CS",'P'+$80
	.WORD	W_FLD
C_CSP:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	CSP-SYSTEM

W_RHASH:
	.BYTE	$82,"R",'#'+$80
	.WORD	W_CSP
C_RHASH:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RHASH-SYSTEM

W_HLD:
	.BYTE	$83,"HL",'D'+$80
	.WORD	W_RHASH
C_HLD:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	HLD-SYSTEM

W_UCL:
	.BYTE	$84,"UC/",'L'+$80
	.WORD	W_HLD
C_UCL:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UCL-SYSTEM

W_UFIRST:
	.BYTE	$86,"UFIRS",'T'+$80
	.WORD	W_UCL
C_UFIRST:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UFIRST-SYSTEM

W_ULIMIT:
	.BYTE	$86,"ULIMI",'T'+$80
	.WORD	W_UFIRST
C_ULIMIT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	ULIMIT-SYSTEM

W_UBBUF:
	.BYTE	$86,"UB/BU",'F'+$80
	.WORD	W_ULIMIT
C_UBBUF:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UBBUF-SYSTEM

W_UBSCR:
	.BYTE	$86,"UB/SC",'R'+$80
	.WORD	W_UBBUF
C_UBSCR:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UBSCR-SYSTEM

W_UTERMINAL:
	.BYTE	8Ah,"U?TERMINA",'L'+$80
	.WORD	W_UBSCR
C_UTERMINAL:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UTERMNL-SYSTEM

W_UKEY:					; Put UKEY addr on stack
	.BYTE	$84,"UKE",'Y'+$80
	.WORD	W_UTERMINAL
C_UKEY:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UKEY-SYSTEM

W_UEMIT:					; Put UEMIT addr on stack
	.BYTE	$85,"UEMI",'T'+$80
	.WORD	W_UKEY
C_UEMIT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UEMIT-SYSTEM

W_UCR:					; Push UCR addr
	.BYTE	$83,"UC",'R'+$80
	.WORD	W_UEMIT
C_UCR:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UCR-SYSTEM

W_URW:
	.BYTE	$84,"UR/",'W'+$80
	.WORD	W_UCR
C_URW:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	URW-SYSTEM

W_UABORT:					; Put UABORT on stack
	.BYTE	$86,"UABOR",'T'+$80
	.WORD	W_URW
C_UABORT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	UABORT-SYSTEM

W_RAF:
	.BYTE	$83,"RA",'F'+$80
	.WORD	W_UABORT
C_RAF:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RAF-SYSTEM

W_RBC:
	.BYTE	$83,"RB",'C'+$80
	.WORD	W_RAF
C_RBC:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RBC-SYSTEM

W_RDE:
	.BYTE	$83,"RD",'E'+$80
	.WORD	W_RBC
C_RDE
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RDE-SYSTEM

W_RHL:
	.BYTE	$83,"RH",'L'+$80
	.WORD	W_RDE
C_RHL:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RHL-SYSTEM

W_RIX:
	.BYTE	$83,"RI",'X'+$80
	.WORD	W_RHL
C_RIX:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RIX-SYSTEM

W_RIY:
	.BYTE	$83,"RI",'Y'+$80
	.WORD	W_RIX
C_RIY:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RIY-SYSTEM

W_RAF2:
	.BYTE	$84,"RAF",2Ch+$80
	.WORD	W_RIY
C_RAF2:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RAF2-SYSTEM

W_RBC2:
	.BYTE	$84,"RBC",2Ch+$80
	.WORD	W_RAF2
C_RBC2:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RBC2-SYSTEM

W_RDE2:
	.BYTE	$84,"RDE",2Ch+$80
	.WORD	W_RBC2
C_RDE2:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RDE2-SYSTEM

W_RHL2:
	.BYTE	$84,"RHL",2Ch+$80
	.WORD	W_RDE2
C_RHL2:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RHL2-SYSTEM

W_RA:
	.BYTE	$82,"R",'A'+$80
	.WORD	W_RHL2
C_RA:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RAF+1-SYSTEM

W_RF:
	.BYTE	$82,"R",'F'+$80
	.WORD	W_RA
C_RF:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RAF-SYSTEM

W_RB:
	.BYTE	$82,"R",'B'+$80
	.WORD	W_RF
C_RB:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RBC+1-SYSTEM

W_RC:
	.BYTE	$82,"R",'C'+$80
	.WORD	W_RB
C_RC:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RBC-SYSTEM

W_RD:
	.BYTE	$82,"R",'D'+$80
	.WORD	W_RC
C_RD:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RDE+1-SYSTEM

W_RE:
	.BYTE	$82,"R",'E'+$80
	.WORD	W_RD
C_RE:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RDE-SYSTEM

W_RH:
	.BYTE	$82,"R",'H'+$80
	.WORD	W_RE
C_RH:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RHL+1-SYSTEM

W_RL:
	.BYTE	$82,"R",'L'+$80
	.WORD	W_RH
C_RL:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	RHL-SYSTEM

W_CALL:
	.BYTE	$84,"CAL",'L'+$80
	.WORD	W_RL
C_CALL:
	.WORD	2+$			; Vector to code
	POP	HL			; Address of routine CALLed
	PUSH	DE			; Save register
	PUSH	BC			; Save register
	LD	A,$C3			; Hex code for JMP
	LD	(JPCODE),A		; Save it
	LD	(JPVECT),HL		; Save jump vector
	LD	HL,(RAF)			; Get register AF
	PUSH	HL			; Onto stack
	POP	AF			; POP into AF
	LD	BC,(RBC)			; Get register BC
	LD	DE,(RDE)			; Get register DE
	LD	HL,(RHL)			; Get register HL
	LD	IX,(RIX)			; Get register IX
	LD	IY,(RIY)			; Get register IY
	CALL	JPCODE			; Call jump to code
	LD	(RIY),IY			; Save register IY
	LD	(RIX),IX			; Save register IX
	LD	(RBC),BC			; Save register BC
	LD	(RDE),DE			; Save register DE
	LD	(RHL),HL			; Save register HL
	PUSH	AF			; Save register AF
	POP	HL			; Into HL
	LD	(RAF),HL			; Into memory
	POP	BC			; Restore BC
	POP	DE			; Restore DE
	JP	NEXT			; 

W_1PLUS:					; 1 plus
	.BYTE	$82,"1",'+'+$80
	.WORD	W_CALL
C_1PLUS:
	.WORD	2+$			; Vector to code
	POP	HL			; get n
	INC	HL			; add 1
	JP	NEXTS1			; save result & NEXT

W_2PLUS:					; 2 plus
	.BYTE	$82,"2",'+'+$80
	.WORD	W_1PLUS
C_2PLUS:
	.WORD	2+$			; Vector to code
	POP	HL			; get n
	INC	HL			; add 1
	INC	HL			; add 2
	JP	NEXTS1			; save result & NEXT

W_1MINUS:					; 1 minus
	.BYTE	$82,"1",'-'+$80
	.WORD	W_2PLUS
C_1MINUS:
	.WORD	2+$			; Vector to code
	POP	HL			; get n
	DEC	HL			; add 1
	JP	NEXTS1			; save result & NEXT

W_2MINUS:					; 2 minus
	.BYTE	$82,"2",'-'+$80
	.WORD	W_1MINUS
C_2MINUS:
	.WORD	2+$			; Vector to code
	POP	HL			; get n
	DEC	HL			; subtract 1
	DEC	HL			; subtract 2
	JP	NEXTS1			; save result & NEXT

W_HERE:					; Dictionary pointer onto stack
	.BYTE	$84,"HER",'E'+$80
	.WORD	W_2MINUS
C_HERE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DP			; Dictionary pointer addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ALLOT:
	.BYTE	$85,"ALLO",'T'+$80
	.WORD	W_HERE
C_ALLOT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DP			; Dictionary pointer addr on stack
	.WORD	C_PLUSSTORE		; Add n1 to addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_COMMA:					; Reserve 2 bytes and save n
	.BYTE	$81,','+$80
	.WORD	W_ALLOT
C_COMMA:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_HERE			; Next free dictionary pointer onto stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_2			; 
	.WORD	C_ALLOT			; Move pointer
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CCOMMA:
	.BYTE	$82,"C",','+$80
	.WORD	W_COMMA
C_CCOMMA:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_CSTORE			; Store byte at addr
	.WORD	C_1			; Put 1 on stack
	.WORD	C_ALLOT
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MINUS:
	.BYTE	$81,'-'+$80
	.WORD	W_CCOMMA
C_MINUS:
	.WORD	2+$			; Vector to code
	POP	DE			; get n1
	POP	HL			; get n2
	CALL	MINUS16			; call subtract routine
	JP	NEXTS1			; save & NEXT

MINUS16:
	LD	A,L			; gel low byte
	SUB	E			; subtract low bytes
	LD	L,A			; save low byte result
	LD	A,H			; get high byte
	SBC	A,D			; subtract high bytes
	LD	H,A			; save high byte result
	RET				; 

W_EQUALS:
	.BYTE	$81,'='+$80
	.WORD	W_MINUS
C_EQUALS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MINUS
	.WORD	C_0EQUALS			; =0
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LESSTHAN:
	.BYTE	$81,'<'+$80
	.WORD	W_EQUALS
C_LESSTHAN:
	.WORD	2+$			; Vector to code
	POP	DE 
	POP	HL 
	LD	A,D 
	XOR	H 
	JP	M,J298C 
	CALL	MINUS16 
J298C:
	INC	H 
	DEC	H 
	JP	M,J2997 
	LD	HL,0000 
	JP	NEXTS1			; Save & NEXT
J2997:
	LD	HL,0001 
	JP	NEXTS1			; Save & NEXT

W_ULESS:					; IF stack-1 < stack_top leave true flag
	.BYTE	$82,"U",'<'+$80
	.WORD	W_LESSTHAN
C_ULESS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_2DUP			; Dup top 2 values on stack
	.WORD	C_XOR			; Exclusive OR them
	.WORD	C_0LESS			; Less than 0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0000-$			; 000Ch
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_0LESS			; Less than 0
	.WORD	C_0EQUALS			; =0
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0001-$			; 0006h
B0000:
	.WORD	C_MINUS
	.WORD	C_0LESS			; Less than 0
B0001:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_GREATER:
	.BYTE	$81,'>'+$80
	.WORD	W_ULESS
C_GREATER:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_LESSTHAN
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ROT:					; 3rd valu down to top of stack
	.BYTE	$83,"RO",'T'+$80
	.WORD	W_GREATER
C_ROT:
	.WORD	2+$			; Vector to code
	POP	DE			; Top value
	POP	HL			; Next one down
	EX	(SP),HL			; Exchange with third
	JP	NEXTS2			; Save both & NEXT

W_PICK:
	.BYTE	$84,"PIC",'K'+$80
	.WORD	W_ROT
C_PICK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SPACE:
	.BYTE	$85,"SPAC",'E'+$80
	.WORD	W_PICK
C_SPACE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BL			; Leaves ASCII for space on stack
	.WORD	C_EMIT			; Output CHR from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QUERYDUP:
	.BYTE	$84,"?DU",'P'+$80
	.WORD	W_SPACE
C_QUERYDUP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0002-$			; 0004h
	.WORD	C_DUP			; Duplicate top value on stack
B0002:
	.WORD	C_STOP			; Pop BC from return stack (=next) 

W_TRAVERSE:
	.BYTE	$88,"TRAVERS",'E'+$80
	.WORD	W_QUERYDUP
C_TRAVERSE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SWAP			; Swap top 2 values on stack
B0054:
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	007Fh
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_LESSTHAN
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0054-$			; FFF0h
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LATEST:
	.BYTE	$86,"LATES",'T'+$80
	.WORD	W_TRAVERSE
C_LATEST:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CURRENT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LFA:
	.BYTE	$83,"LF",'A'+$80
	.WORD	W_LATEST
C_LFA:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0004h
	.WORD	C_MINUS
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CFA:
	.BYTE	$83,"CF",'A'+$80
	.WORD	W_LFA
C_CFA:
	.WORD	2+$			; Vector to code
	POP	HL			; get n
	DEC	HL			; subtract 1
	DEC	HL			; subtract 2
	JP	NEXTS1			; save result & NEXT
W_NFA:
	.BYTE	$83,"NF",'A'+$80
	.WORD	W_CFA
C_NFA:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0005h
	.WORD	C_MINUS
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$FFFF
	.WORD	C_TRAVERSE
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_PFA:					; Convert NFA to PFA
	.BYTE	$83,"PF",'A'+$80
	.WORD	W_NFA
C_PFA:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_1			; Traverse up memory
	.WORD	C_TRAVERSE		; End of name on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0005h			; Offset to start of word code
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CSPSTORE:
	.BYTE	$84,"!CS",'P'+$80
	.WORD	W_PFA
C_CSPSTORE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_CSP			; Push check stack pointer addr
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QERROR:
	.BYTE	$86,"?ERRO",'R'+$80
	.WORD	W_CSPSTORE
C_QERROR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_0BRANCH			; Branch if no error
	.WORD	B0003-$			; 0008h
	.WORD	C_ERROR
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0004-$			; 0004h
B0003:
	.WORD	C_DROP			; Drop error no.
B0004:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QCOMP:					; Error if not in compile mode
	.BYTE	$85,"?COM",'P'+$80
	.WORD	W_QERROR
C_QCOMP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0EQUALS			; =0
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0011h			; Error message number
	.WORD	C_QERROR			; Error if state <> 0
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QEXEC:					; Error not if not in execute mode
	.BYTE	$85,"?EXE",'C'+$80
	.WORD	W_QCOMP
C_QEXEC:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0012h			; Error not if not in execute mode
	.WORD	C_QERROR		
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QPAIRS:
	.BYTE	$86,"?PAIR",'S'+$80
	.WORD	W_QEXEC
C_QPAIRS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MINUS
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0013h
	.WORD	C_QERROR
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_WHATSTACK:				; Check stack pointer, error if not ok
	.BYTE	$84,"?CS",'P'+$80
	.WORD	W_QPAIRS
C_WHATSTACK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_CSP			; Push check stack pointer addr
	.WORD	C_FETCH			; Get check stack pointer
	.WORD	C_MINUS			; If ok then result is 0
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0014h			; Error no if not ok
	.WORD	C_QERROR			; Error if stack top -1 <> 0
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QLOADING:
	.BYTE	$88,"?LOADIN",'G'+$80
	.WORD	W_WHATSTACK
C_QLOADING:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0EQUALS			; =0
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0016h
	.WORD	C_QERROR
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_COMPILE:
	.BYTE	$87,"COMPIL",'E'+$80
	.WORD	W_QLOADING
C_COMPILE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QCOMP			; Error if not in compile mode
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_DUP			; Bump return address and put back
	.WORD	C_2PLUS			; 
	.WORD	C_MOVER			; 
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LEFTBRKT:				; Set STATE to execute
	.BYTE	$81,'['+$80
	.WORD	W_COMPILE
C_LEFTBRKT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_STORE			; Store word at addr 
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_RIGHTBRKT:				; Set STATE to compile
	.BYTE	$81,']'+$80
	.WORD	W_LEFTBRKT
C_RIGHTBRKT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	00$C0
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_STORE			; Set STATE to execute
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SMUDGE:
	.BYTE	$86,"SMUDG",'E'+$80
	.WORD	W_RIGHTBRKT
C_SMUDGE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LATEST			; Push top words NFA
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0020h
	.WORD	C_TOGGLE			; XOR (addr) with byte
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_HEX:
	.BYTE	$83,"HE",'X'+$80
	.WORD	W_SMUDGE
C_HEX:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0010h
	.WORD	C_BASE			; Put BASE addr on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DECIMAL:				; Sets decimal mode
	.BYTE	$87,"DECIMA",'L'+$80
	.WORD	W_HEX
C_DECIMAL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	00$0A			; Sets decimal value
	.WORD	C_BASE			; Put BASE addr on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CCODE:					; Stop compillation & terminate word
	.BYTE	$87,"<; CODE",'>'+$80
	.WORD	W_DECIMAL
C_CCODE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_LATEST			; Push top words NFA
	.WORD	C_PFA			; Convert NFA to PFA
	.WORD	C_CFA			; Convert PFA to CFA
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SCCODE:
	.BYTE	$C5,"; COD",'E'+$80
	.WORD	W_CCODE
C_SCCODE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_WHATSTACK		; Check stack pointer, error if not ok
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_CCODE
	.WORD	C_LEFTBRKT		; Set STATE to execute
	.WORD	C_TASK
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CREATE:
	.BYTE	$86,"CREAT",'E'+$80
	.WORD	W_SCCODE
C_CREATE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_CONSTANT
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DOES:
	.BYTE	$85,"DOES",'>'+$80
	.WORD	W_CREATE
C_DOES:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_LATEST			; Push top words NFA
	.WORD	C_PFA			; Convert NFA to PFA
	.WORD	C_STORE			; Store word at addr
	.WORD	C_CCODE			; Execute following machine code

X_DOES:
	LD	HL,(RPP)			; Get return stack pointer
	DEC	HL			; Push next pointer
	LD	(HL),B			; 
	DEC	HL			; 
	LD	(HL),C			; 
	LD	(RPP),HL	
	INC	DE
	EX	DE,HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	JP	NEXTS1			; Save & NEXT

W_COUNT:					; Convert string at addr to addr + length
	.BYTE	$85,"COUN",'T'+$80
	.WORD	W_DOES
C_COUNT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate address
	.WORD	C_1PLUS			; Add 1 (points to string start)
	.WORD	C_SWAP			; Get address back
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_TYPE:					; Output n bytes from addr
	.BYTE	$84,"TYP",'E'+$80
	.WORD	W_COUNT
C_TYPE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QUERYDUP		; Copy length if length <> 0
	.WORD	C_0BRANCH			; Branch if length = 0
	.WORD	B0005-$			; 0018h
	.WORD	C_OVER			; Copy address to stack top
	.WORD	C_PLUS			; Add to length
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B004F:
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_CFETCH			; Get byte from string
	.WORD	C_EMIT			; Output CHR from stack
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	B004F-$			; FFF8h
	.WORD	C_BRANCH			; Done so branch to next
	.WORD	B0006-$			; 0004h
B0005:
	.WORD	C_DROP			; Drop string address
B0006:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_TRAILING:
	.BYTE	$89,"-TRAILIN",'G'+$80
	.WORD	W_TYPE
C_TRAILING:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B0009:
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_1			; Put 1 on stack
	.WORD	C_MINUS
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_BL			; Leaves ASCII for space on stack
	.WORD	C_MINUS
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0007-$			; 0008h
	.WORD	C_LEAVE			; Quit loop by making index = limit
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0008-$			; 0006h
B0007:
	.WORD	C_1			; Put 1 on stack
	.WORD	C_MINUS
B0008:
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	B0009-$			; FFE0h
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CQUOTE:					; Output following string
	.BYTE	$84,"<.",22h,'>'+$80
	.WORD	W_TRAILING
C_CQUOTE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_RFETCH			; Copy return stack top to data stack
	.WORD	C_COUNT			; Convert string at addr to addr + length
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_PLUS			; Add length of string +1
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_TYPE			; Output n bytes from addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QUOTE:					; Accept following text
	.BYTE	$C2,".",$22+$80
	.WORD	W_CQUOTE
C_QUOTE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0022
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B000A-$			; 0012h
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_CQUOTE		
	.WORD	C_WORD
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_ALLOT
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B000B-$			; 0008h
B000A:
	.WORD	C_WORD
	.WORD	C_COUNT			; Convert string at addr to addr + length
	.WORD	C_TYPE			; Output n bytes from addr
B000B:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_EXPECT:
	.BYTE	$86,"EXPEC",'T'+$80
	.WORD	W_QUOTE
C_EXPECT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_OVER			; Copy buffer start addr
	.WORD	C_PLUS			; Add to length to give start,end
	.WORD	C_OVER			; Copy start
	.WORD	C_LDO			; Put start & end loop values on RPP
B0012:
	.WORD	C_KEY			; Wait for key, value on stack
	.WORD	C_DUP			; Duplicate key value
	.WORD	C_LIT			; Push backspace addr
	.WORD	BACKSPACE		
	.WORD	C_FETCH			; Get backspace value
	.WORD	C_EQUALS			; Was it backspace ?
	.WORD	C_0BRANCH			; If not then jump
	.WORD	B000C-$			; 002Ah
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_EQUALS
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_2
	.WORD	C_MINUS
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B000D-$			; 00$0A
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0007h
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B000E-$			; 0006h
B000D:
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0008h
B000E:
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B000F-$			; 0028h
B000C:
	.WORD	C_DUP			; Duplicate key value
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	00$0D			; CR
	.WORD	C_EQUALS			; Was it cariage return
	.WORD	C_0BRANCH			; If not then jump
	.WORD	B0010-$			; 000Eh
	.WORD	C_LEAVE			; Quit loop by making index = limit
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_BL			; Leaves ASCII for space on stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0011-$			; 0004h
B0010:
	.WORD	C_DUP			; Duplicate key value
B0011:
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_CSTORE			; Store byte at addr
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_STORE			; Store word at addr
B000F:
	.WORD	C_EMIT			; Output CHR from stack
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	B0012-$			; FF9Eh
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QUERY:
	.BYTE	$85,"QUER",'Y'+$80
	.WORD	W_EXPECT
C_QUERY:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_TIB			; Put TIB addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0050			; Max line length 50h
	.WORD	C_EXPECT			; Get line
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_NULL:
	.BYTE	$C1,$80
	.WORD	W_QUERY
C_NULL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0013-$			; 002Ah
	.WORD	C_1			; Put 1 on stack
	.WORD	C_BLK
	.WORD	C_PLUSSTORE		; Add n1 to addr
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_STORE			; Store word at addr
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_BSCR			; Number of buffers per block on stack
	.WORD	C_1			; Put 1 on stack
	.WORD	C_MINUS
	.WORD	C_AND			; AND
	.WORD	C_0EQUALS			; =0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0014-$			; 0008h
	.WORD	C_QEXEC			; Error not if not in execute mode
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_DROP			; Drop top value from stack
B0014:
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0015-$			; 0006h
B0013:
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_DROP			; Drop top value from stack
B0015:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_FILL:					; Fill with byte n bytes from addr
	.BYTE	$84,"FIL",'L'+$80
	.WORD	W_NULL
C_FILL:
	.WORD	2+$			; Vector to code
	LD	L,C			; Save BC for now
	LD	H,B			; 
	POP	DE			; get byte
	POP	BC			; get n
	EX	(SP),HL			; get addr and save BC
	EX	DE,HL			; 
NEXT_BYTE:
	LD	A,B			; Test count
	OR	C			; 
	JR	Z,NO_COUNT		; If 0 we're done
	LD	A,L			; Byte into A
	LD	(DE),A			; Save byte
	INC	DE			; Next addr
	DEC	BC			; Decr count
	JR	NEXT_BYTE			; Loop
NO_COUNT:
	POP	BC			; Get BC back
	JP	NEXT

W_ERASE:					; Fill addr & length from stack with 0
	.BYTE	$85,"ERAS",'E'+$80
	.WORD	W_FILL
C_ERASE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_FILL			; Fill with byte n bytes from addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BLANKS:					; Fill addr & length from stack with [SP]
	.BYTE	$86,"BLANK",'S'+$80
	.WORD	W_ERASE
C_BLANKS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BL			; Leaves ASCII for space on stack
	.WORD	C_FILL			; Fill with byte n bytes from addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_HOLD:
	.BYTE	$84,"HOL",'D'+$80
	.WORD	W_BLANKS
C_HOLD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$FFFF
	.WORD	C_HLD
	.WORD	C_PLUSSTORE		; Add n1 to addr
	.WORD	C_HLD
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CSTORE			; Store byte at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_PAD:
	.BYTE	$83,"PA",'D'+$80
	.WORD	W_HOLD
C_PAD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0044h
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_WORD:
	.BYTE	$84,"WOR",'D'+$80
	.WORD	W_PAD
C_WORD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack 
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0016-$			; 000Ch
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_BLOCK
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0017-$			; 0006h
B0016:
	.WORD	C_TIB
	.WORD	C_FETCH			; Get word from addr on stack
B0017:
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_ENCLOSE
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0022h
	.WORD	C_BLANKS
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_PLUSSTORE		; Add n1 to addr
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_MINUS
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_RFETCH			; Return stack top to data stack
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_CSTORE			; Store byte at addr
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_CMOVE			; Move block
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CONVERT:
	.BYTE	$87,"CONVER",'T'+$80
	.WORD	W_WORD
C_CONVERT:
	.WORD	E_COLON			; Interpret following word sequence
B001A:
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_BASE			; Put BASE addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_DIGIT			; Convert digit n2 using base n1
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0018-$			; 002Ch
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_BASE			; Put BASE addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_USTAR
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_ROT			; 3rd value down to top of stack
	.WORD	C_BASE			; Put BASE addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_USTAR
	.WORD	C_DPLUS
	.WORD	C_DPL
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0019-$			; 0008h
	.WORD	C_1			; Put 1 on stack
	.WORD	C_DPL
	.WORD	C_PLUSSTORE		; Add n1 to addr
B0019:
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B001A-$			; FF$C6
B0018:
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_NUMBER:
	.BYTE	$86,"NUMBE",'R'+$80
	.WORD	W_CONVERT
C_NUMBER:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_ROT			; 3rd value down to top of stack
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	002Dh			; '-'
	.WORD	C_EQUALS			; Is first chr = '-'
	.WORD	C_DUP			; Duplicate negative flag
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$FFFF			;-1
B001C:
	.WORD	C_DPL
	.WORD	C_STORE			; Store word at addr
	.WORD	C_CONVERT
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_BL			; Leaves ASCII for space on stack
	.WORD	C_MINUS
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B001B-$			; 0016h
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	002Eh			; '.'
	.WORD	C_MINUS
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_QERROR
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B001C-$			; FFDCh
B001B:
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B001D-$			; 0004h
	.WORD	C_DNEGATE
B001D:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MFIND:
	.BYTE	$85,"-FIN",'D'+$80
	.WORD	W_NUMBER
C_MFIND:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BL			; Leaves ASCII for space on stack
	.WORD	C_WORD
	.WORD	C_CONTEXT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_FIND			; Find word & return vector,byte & flag
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_0EQUALS			; =0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B001E-$			; 00$0A
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_LATEST			; Push top words NFA
	.WORD	C_FIND			; Find word & return vector,byte & flag
B001E:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CABORT:
	.BYTE	$87,"<ABORT",'>'+$80
	.WORD	W_MFIND
C_CABORT:
	.WORD	E_COLON			; Interpret following word sequence	
	.WORD	C_ABORT
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ERROR:
	.BYTE	$85,"ERRO",'R'+$80
	.WORD	W_CABORT
C_ERROR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_WARNING			; Put WARNING addr on stack
	.WORD	C_FETCH			; Get word from addr on stack 
	.WORD	C_0LESS			; Less than 0 leaves true
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B001F-$			; 0004h
	.WORD	C_CABORT
B001F:
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_COUNT			; Convert string at addr to addr + length
	.WORD	C_TYPE			; Output n bytes from addr
	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END7-S_START7
S_START7:
	.BYTE	"? "		
S_END7:
	.WORD	C_MESSAGE			; Output message
	.WORD	C_SPSTORE			; Set initial stack pointer value
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_QUERYDUP
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0020-$			; 0008h
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_SWAP			; Swap top 2 values on stack
B0020:
	.WORD	C_QUIT

W_ID:					; Print definition name from name field addr
	.BYTE	$83,"ID",'.'+$80
	.WORD	W_ERROR
C_ID:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_COUNT			; Convert string at addr to addr + length
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	001Fh			; Max length is 1Fh
	.WORD	C_AND			; AND lenght with 1Fh
	.WORD	C_TYPE			; Output n bytes from addr
	.WORD	C_SPACE			; Output space
	.WORD	C_STOP			; Pop BC from return stack (=next)

C_XXX1:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MFIND			; Find name returns PFA,length,true or false
	.WORD	C_0BRANCH			; Branch if name not found
	.WORD	B0021-$			; 0010h
	.WORD	C_DROP			; Drop length
	.WORD	C_NFA			; Convert PFA to NFA
	.WORD	C_ID			; Print definition name from name field addr
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0004			; Message 4, name defined twice
	.WORD	C_MESSAGE			; Output message
	.WORD	C_SPACE			; Output space
B0021:
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_WIDTH
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_MIN
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_ALLOT			; Which ever is smallest width or namelength
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$00A0
	.WORD	C_TOGGLE			; XOR (addr) with byte
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_1			; Put 1 on stack
	.WORD	C_MINUS
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0080
	.WORD	C_TOGGLE			; XOR (addr) with byte
	.WORD	C_LATEST			; Push top words NFA
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_CURRENT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_2PLUS			; 2 plus
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CCOMPILE:
	.BYTE	$89,"[COMPILE",']'+$80
	.WORD	W_ID
C_CCOMPILE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MFIND
	.WORD	C_0EQUALS			; =0
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_QERROR
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_CFA			; Convert PFA to CFA
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LITERAL:
	.BYTE	$C7,"LITERA",'L'+$80
	.WORD	W_CCOMPILE
C_LITERAL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0022-$			; 0008h
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	C_COMMA			; Reserve 2 bytes and save n
B0022:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DLITERAL:
	.BYTE	$C8,"DLITERA",'L'+$80
	.WORD	W_LITERAL
C_DLITERAL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0023-$			; 0008h
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_LITERAL
	.WORD	C_LITERAL
B0023:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QSTACK:
	.BYTE	$86,"?STAC",'K'+$80
	.WORD	W_DLITERAL
C_QSTACK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SPFETCH			; Stack pointer onto stack 
	.WORD	C_S0			; Push S0 (initial data stack pointer)
	.WORD	C_FETCH			; Get word from addr on stack 
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_ULESS			; IF stack-1 < stack_top leave true flag
	.WORD	C_1			; Put 1 on stack
	.WORD	C_QERROR
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0080
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_ULESS			; IF stack-1 < stack_top leave true flag
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0007
	.WORD	C_QERROR
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_INTERPRET:
	.BYTE	$89,"INTERPRE",'T'+$80
	.WORD	W_QSTACK
C_INTERPRET:
	.WORD	E_COLON			; Interpret following word sequence
B002A:
	.WORD	C_MFIND			; Find name returns PFA,length,true or false
	.WORD	C_0BRANCH			; Branch if name not found
	.WORD	NO_NAME-$		
	.WORD	C_STATE			; STATE addr on stack
	.WORD	C_FETCH			; Get STATE
	.WORD	C_LESSTHAN		; Is it quit compile word ?
	.WORD	C_0BRANCH			; If so then branch
	.WORD	B0025-$			; 
	.WORD	C_CFA			; Convert PFA to CFA
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0026-$			; 
B0025:
	.WORD	C_CFA			; Convert PFA to CFA
	.WORD	C_EXECUTE			; Jump to address on stack
B0026:
	.WORD	C_QSTACK			; Error message if stack underflow
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0027-$			; 
NO_NAME:
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_NUMBER			; Convert string at addr to double
	.WORD	C_DPL			; 
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0028-$			; 
	.WORD	C_DLITERAL
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0029-$			; 
B0028:
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_LITERAL
B0029:
	.WORD	C_QSTACK			; Error message if stack underflow
B0027:
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B002A-$			; FF$C2

W_IMMEDIATE:
	.BYTE	$89,"IMMEDIAT",'E'+$80
	.WORD	W_INTERPRET
C_IMMEDIATE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LATEST			; Push top words NFA
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0040
	.WORD	C_TOGGLE			; XOR (addr) with byte
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_VOCABULARY:
	.BYTE	8Ah,"VOCABULAR",'Y'+$80
	.WORD	W_IMMEDIATE
C_VOCABULARY:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CREATE
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$A081
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_CURRENT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CFA			; Convert PFA to CFA
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_VOC_LINK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_VOC_LINK
	.WORD	C_STORE			; Store word at addr
	.WORD	C_DOES
	.WORD	C_2PLUS			; 2 plus
	.WORD	C_CONTEXT
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

C_LINK:
	.WORD	C_2PLUS			; 2 plus
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CONTEXT
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_FORTH:
	.BYTE	$C5,"FORT",'H'+$80
	.WORD	W_VOCABULARY
C_FORTH:
	.WORD	X_DOES
	.WORD	C_LINK

	.BYTE	$81,' '+$80
	.WORD	FLAST+2
E_FORTH:
	.WORD	$0000

W_DEFINITIONS:				; Set CURRENT as CONTEXT vocabulary
	.BYTE	8Bh,"DEFINITION",'S'+$80
	.WORD	W_FORTH
C_DEFINITIONS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CONTEXT			; Get CONTEXT addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CURRENT			; Get CURRENT addr
	.WORD	C_STORE			; Set CURRENT as the context vocabulary
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_OPENBRKT:
	.BYTE	$C1,'('+$80
	.WORD	W_DEFINITIONS
C_OPENBRKT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0029
	.WORD	C_WORD
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)
;---------------------------------------------------------------------------------------
;  This it the last thing ever executed and is the interpreter
;   outer loop. This NEVER quits.
;---------------------------------------------------------------------------------------
W_QUIT:	.BYTE	$84,"QUI",'T'+$80
	.WORD	W_OPENBRKT
C_QUIT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_BLK			; Get current BLK pointer
	.WORD	C_STORE			; Set BLK to 0
	.WORD	C_LEFTBRKT		; Set STATE to execute
B002C:
	.WORD	C_RPSTORE			; Set initial return stack pointer
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_QUERY			; Get string from input, ends in CR
	.WORD	C_INTERPRET		; Interpret input stream
	.WORD	C_STATE			; Push STATE addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_0EQUALS			; =0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	S_END8-$			; 0007h
	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END8-S_START8
S_START8:
	.BYTE	"OK"
S_END8:
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B002C-$			; FFE7h

W_ABORT:
	.BYTE	$85,"ABOR",'T'+$80
	.WORD	W_QUIT
C_ABORT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UABORT			; Put UABORT on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_EXECUTE			; Jump to address on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

CF_UABORT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SPSTORE			; Set initial stack pointer value
	.WORD	C_DECIMAL			; Sets decimal mode
	.WORD	C_QSTACK			; Error message if stack underflow
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END1-S_START1		; String length
S_START1:
	.BYTE	"* Z80 FORTH *"
S_END1:
	.WORD	C_FORTH
	.WORD	C_DEFINITIONS		; Set CURRENT as CONTEXT vocabulary
	.WORD	C_QUIT

W_WARM:
	.BYTE	$84,"WAR",'M'+$80
	.WORD	W_ABORT
C_WARM:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	WORD1			; Start of detault table
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	S0			; S0 addr
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	START_TABLE-WORD1		; (000Ch) Table length
	.WORD	C_CMOVE			; Move block
	.WORD	C_ABORT

X_COLD:
	LD	HL,START_TABLE		; Copy table to ram
	LD	DE,FLAST			; Where the table's going
	LD	BC,NEXTS2-START_TABLE	; Bytes to copy
	LDIR				; 
	LD	HL,W_TASK			; Copy TASK to ram
	LD	DE,VOCAB_BASE		; Where it's going
	LD	BC,W_TASKEND-W_TASK		; Bytes to copy
	LDIR				; 
	LD	BC,FIRSTWORD		; BC to first forth word
	LD	HL,(WORD1)		; Get stack pointer
	LD	SP,HL			; Set it
	JP	NEXT

FIRSTWORD:
	.WORD	C_COLD

W_COLD:	.BYTE	$84,"COL",'D'+$80
	.WORD	W_WARM
	.WORD	X_COLD
C_COLD:	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_EBUFFERS		; Clear pseudo disk buffer
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_OFFSET			; Put disk block offset on stack
	.WORD	C_STORE			; Clear disk block offset
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	WORD1			; Start of default table
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	S0			; S0 addr
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	START_TABLE-WORD1		; Block length on stack (0010h)
	.WORD	C_CMOVE			; Move block
	.WORD	C_ABORT

W_SINGTODUB:				; Change single number to double
	.BYTE	$84,"S->",'D'+$80
	.WORD	W_COLD
C_SINGTODUB:
	.WORD	2+$			; Vector to code
	POP	DE			; Get number
	LD	HL,$0000			; Assume +ve extend
	LD	A,D			; Check sign
	AND	$80			; 
	JR	Z,IS_POS			; Really +ve so jump
	DEC	HL			; Make -ve extension
IS_POS:
	JP	NEXTS2			; Save both & NEXT

W_PLUSMINUS:
	.BYTE	$82,"+",'-'+$80
	.WORD	W_SINGTODUB
C_PLUSMINUS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_0LESS			; Less than 0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B002D-$			; 0004h
	.WORD	C_NEGATE			; Form 2s complement of n
B002D:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DPLUSMINUS:				; Add sign of n to double
	.BYTE	$83,"D+",'-'+$80
	.WORD	W_PLUSMINUS
C_DPLUSMINUS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_0LESS			; Less than 0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B002E-$			; 0004h
	.WORD	C_DNEGATE
B002E:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ABS:
	.BYTE	$83,"AB",'S'+$80
	.WORD	W_DPLUSMINUS
C_ABS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_PLUSMINUS
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DABS:
	.BYTE	$84,"DAB",'S'+$80
	.WORD	W_ABS
C_DABS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_DPLUSMINUS		; Add sign of n to double
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MIN:
	.BYTE	$83,"MI",'N'+$80
	.WORD	W_DABS
C_MIN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_2DUP			; Dup top 2 values on stack
	.WORD	C_GREATER
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B002F-$			; 0004h
	.WORD	C_SWAP			; Swap top 2 values on stack
B002F:
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MAX:
	.BYTE	$83,"MA",'X'+$80
	.WORD	W_MIN
C_MAX:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_2DUP			; Dup top 2 values on stack
	.WORD	C_LESSTHAN 
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0030-$			; 0004h
	.WORD	C_SWAP			; Swap top 2 values on stack
B0030:
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MTIMES:
	.BYTE	$82,"M",'*'+$80
	.WORD	W_MAX
C_MTIMES:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_2DUP			; Dup top 2 values on stack
	.WORD	C_XOR			; Works out sign of result
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_ABS
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_ABS
	.WORD	C_USTAR
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_DPLUSMINUS		; Add sign of n to double
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MDIV:
	.BYTE	$82,"M",'/'+$80
	.WORD	W_MTIMES
C_MDIV:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_DABS
	.WORD	C_RFETCH			; Return stack top to data stack
	.WORD	C_ABS
	.WORD	C_UMOD			; Unsigned divide & MOD
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_RFETCH			; Return stack top to data stack
	.WORD	C_XOR			; XOR
	.WORD	C_PLUSMINUS
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_PLUSMINUS
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_TIMES:
	.BYTE	$81,'*'+$80
	.WORD	W_MDIV
C_TIMES:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MTIMES
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DIVMOD:
	.BYTE	$84,"/MO",'D'+$80
	.WORD	W_TIMES
C_DIVMOD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_SINGTODUB		; Change single number to double
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_MDIV
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DIV:
	.BYTE	$81,'/'+$80
	.WORD	W_DIVMOD
C_DIV:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DIVMOD
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_DROP			; Drop top value from stack 
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MOD:
	.BYTE	$83,"MO",'D'+$80
	.WORD	W_DIV
C_MOD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DIVMOD
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_TIMESDIVMOD:
	.BYTE	$85,"*/MO",'D'+$80
	.WORD	W_MOD
C_TIMESDIVMOD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_MTIMES
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_MDIV
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_TIMESDIV:
	.BYTE	$82,"*",'/'+$80
	.WORD	W_TIMESDIVMOD
C_TIMESDIV:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_TIMESDIVMOD
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MDIVMOD:
	.BYTE	$85,"M/MO",'D'+$80
	.WORD	W_TIMESDIV
C_MDIVMOD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_RFETCH			; Return stack top to data stack
	.WORD	C_UMOD			; Unsigned divide & MOD
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_UMOD			; Unsigned divide & MOD
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CLINE:
	.BYTE	$86,"<LINE",'>'+$80
	.WORD	W_MDIVMOD
C_CLINE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_CL			; Put characters/line on stack
	.WORD	C_BBUF			; Put bytes per block on stack
	.WORD	C_TIMESDIVMOD
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_BSCR			; Number of buffers per block on stack
	.WORD	C_TIMES
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_BLOCK
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_CL			; Put characters/line on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DOTLINE:
	.BYTE	$85,".LIN",'E'+$80
	.WORD	W_CLINE
C_DOTLINE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CLINE
	.WORD	C_TRAILING
	.WORD	C_TYPE			; Output n bytes from addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_MESSAGE:
	.BYTE	$87,"MESSAG",'E'+$80
	.WORD	W_DOTLINE
C_MESSAGE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_WARNING			; Put WARNING addr on stack
	.WORD	C_FETCH			; Get WARNING value
	.WORD	C_0BRANCH			; If WARNING = 0 output MSG # n
	.WORD	B0031-$			; 001Eh
	.WORD	C_QUERYDUP
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0032-$			; 0014h
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0004
	.WORD	C_OFFSET			; Put disk block offset on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_BSCR			; Number of buffers per block on stack
	.WORD	C_DIV
	.WORD	C_MINUS
	.WORD	C_DOTLINE			; Output line from screen
	.WORD	C_SPACE			; Output space

B0032:	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0033-$			; 00$0D

B0031:	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END2-S_START2
S_START2:	.BYTE	"MSG # "
S_END2:	.WORD	C_DOT
B0033:	.WORD	C_STOP			; Pop BC from return stack (=next)

W_PORTIN:					; Fetch data from port
	.BYTE	$82,"P",'@'+$80
	.WORD	W_MESSAGE
C_PORTIN:
	.WORD	2+$			; Vector to code
	POP	DE			; Get port addr
	LD	HL,PAT+1			; Save in port in code
	LD	(HL),E			; 
	CALL	PAT			; Call port in routine
	LD	L,A			; Save result
	LD	H,$00			; 
	JP	NEXTS1			; Save & NEXT

W_PORTOUT:				; Save data to port
	.BYTE	$82,"P",'!'+$80
	.WORD	W_PORTIN
C_PORTOUT:
	.WORD	2+$			; Vector to code
	POP	DE			; Get port addr
	LD	HL,PST+1			; Save in port out code
	LD	(HL),E			; 
	POP	HL			; 
	LD	A,L			; Byte to A
	CALL	PST			; Call port out routine
	JP	NEXT

W_USE:	.BYTE	$83,"US",'E'+$80
	.WORD	W_PORTOUT
C_USE:	.WORD	X_USER			; Put next word on stack then do next
	.WORD	USE-SYSTEM

W_PREV:	.BYTE	$84,"PRE",'V'+$80
	.WORD	W_USE
C_PREV:	.WORD	X_USER			; Put next word on stack then do next
	.WORD	PREV-SYSTEM

W_PLUSBUF:
	.BYTE	$84,"+BU",'F'+$80
	.WORD	W_PREV
C_PLUSBUF:
	.WORD	NEXT

W_UPDATE:
	.BYTE	$86,"UPDAT",'E'+$80
	.WORD	W_PLUSBUF
C_UPDATE:
	.WORD	NEXT

W_EBUFFERS:				; Clear pseudo disk buffer
	.BYTE	$8D,"EMPTY-BUFFER",'S'+$80
	.WORD	W_UPDATE
C_EBUFFERS:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_FIRST			; Start of pseudo disk onto stack
	.WORD	C_LIMIT			; End of pseudo disk onto stack
	.WORD	C_OVER			; Start to top of stack
	.WORD	C_MINUS			; Work out buffer length
	.WORD	C_ERASE			; Fill addr & length from stack with 0
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BUFFER:
	.BYTE	$86,"BUFFE",'R'+$80
	.WORD	W_EBUFFERS
C_BUFFER:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BLOCK
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BLOCK:					; Put address of block n (+ offset) on stack
	.BYTE	$85,"BLOC",'K'+$80
	.WORD	W_BUFFER
C_BLOCK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	DISK_END/BLOCK_SIZE-DISK_START/BLOCK_SIZE
					; Max number of blocks
	.WORD	C_MOD			; MOD to max number
	.WORD	C_OFFSET			; Put address of disk block offset on stack
	.WORD	C_FETCH			; Get disk block offset
	.WORD	C_PLUS			; Add offset to block #
	.WORD	C_BBUF			; Put bytes per block on stack
	.WORD	C_TIMES			; Bytes times block number
	.WORD	C_FIRST			; Put address of first block on stack
	.WORD	C_PLUS			; Add address of first to byte offset
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_RW:
	.BYTE	$83,"R/",'W'+$80
	.WORD	W_BLOCK
C_RW:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_URW			; 
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_EXECUTE			; Jump to address on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)
CF_URW:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_FLUSH:
	.BYTE	$85,"FLUS",'H'+$80
	.WORD	W_RW
C_FLUSH:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DUMP:
	.BYTE	$84,"DUM",'P'+$80
	.WORD	W_FLUSH
C_DUMP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B0051:
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0005h
	.WORD	C_DDOTR
	.WORD	C_SPACE			; Output space
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0004h
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B0050:
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_CFETCH			; Get byte from addr on stack
	.WORD	C_3
	.WORD	C_DOTR
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	B0050-$			; FFF4h
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_PLOOP			; Loop + stack & branch if not done
	.WORD	B0051-$			; FFD4h
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LOAD:
	.BYTE	$84,"LOA",'D'+$80
	.WORD	W_DUMP
C_LOAD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BLK			; Get current block number (0 = keyboard)
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_MOVER			; Save it for now
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_MOVER			; Save it for now
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_STORE			; Set to zero
	.WORD	C_BSCR			; Number of buffers per block on stack
	.WORD	C_TIMES			; Multiply block to load by buffers/block
	.WORD	C_BLK			; Get BLK pointer
	.WORD	C_STORE			; Make load block current input stream
	.WORD	C_INTERPRET		; Interpret input stream
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_STORE			; Store word at addr
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_BLK			; Current block
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_NEXTSCREEN:
	.BYTE	$C3,"--",'>'+$80
	.WORD	W_LOAD
C_NEXTSCREEN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QLOADING
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_TOIN			; Current input buffer offset
	.WORD	C_STORE			; Store word at addr
	.WORD	C_BSCR			; Number of buffers per block on stack
	.WORD	C_BLK
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_MOD
	.WORD	C_MINUS
	.WORD	C_BLK
	.WORD	C_PLUSSTORE		; Add n1 to addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_TICK:
	.BYTE	$81,$2C+$80
	.WORD	W_NEXTSCREEN
C_TICK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MFIND			; Find name returns PFA,length,true or false
	.WORD	C_0EQUALS			; =0
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_QERROR
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_LITERAL
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_FORGET:
	.BYTE	$86,"FORGE",'T'+$80
	.WORD	W_TICK
C_FORGET:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CURRENT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CONTEXT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_MINUS
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0018h
	.WORD	C_QERROR
	.WORD	C_TICK
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_FENCE
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_LESSTHAN
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0015h
	.WORD	C_QERROR
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_NFA			; Convert PFA to NFA
	.WORD	C_DP			; Dictionary pointer addr on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_LFA
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CONTEXT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BACK:
	.BYTE	$84,"BAC",'K'+$80
	.WORD	W_FORGET
C_BACK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_MINUS
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_BEGIN:
	.BYTE	$C5,"BEGI",'N'+$80
	.WORD	W_BACK
C_BEGIN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QCOMP			; Error if not in compile mode
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_1			; Put 1 on stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ENDIF:
	.BYTE	$C5,"ENDI",'F'+$80
	.WORD	W_BEGIN
C_ENDIF:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QCOMP			; Error if not in compile mode
	.WORD	C_2
	.WORD	C_QPAIRS
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_MINUS
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_THEN:
	.BYTE	$C4,"THE",'N'+$80
	.WORD	W_ENDIF
C_THEN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ENDIF
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DO:
	.BYTE	$C2,"D",'O'+$80
	.WORD	W_THEN
C_DO:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_LDO			; Put start & end loop values on RPP
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_3
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LOOP:
	.BYTE	$C4,"LOO",'P'+$80
	.WORD	W_DO
C_LOOP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_3
	.WORD	C_QPAIRS
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	C_BACK
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_PLUSLOOP:
	.BYTE	$C5,"+LOO",'P'+$80
	.WORD	W_LOOP
C_PLUSLOOP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_3
	.WORD	C_QPAIRS
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_PLOOP			; Loop + stack & branch if not done
	.WORD	C_BACK
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_UNTIL:
	.BYTE	$C5,"UNTI",'L'+$80
	.WORD	W_PLUSLOOP
C_UNTIL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_1			; Put 1 on stack
	.WORD	C_QPAIRS
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	C_BACK
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_END:
	.BYTE	$C3,"EN",'D'+$80
	.WORD	W_UNTIL
C_END:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_UNTIL
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_AGAIN:
	.BYTE	$C5,"AGAI",'N'+$80
	.WORD	W_END
C_AGAIN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_1			; Put 1 on stack
	.WORD	C_QPAIRS
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	C_BACK
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_REPEAT:
	.BYTE	$C6,"REPEA",'T'+$80
	.WORD	W_AGAIN
C_REPEAT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_AGAIN
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_2
	.WORD	C_MINUS
	.WORD	C_ENDIF
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_IF:
	.BYTE	$C2,"I",'F'+$80
	.WORD	W_REPEAT
C_IF:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_2
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ELSE:
	.BYTE	$C4,"ELS",'E'+$80
	.WORD	W_IF
C_ELSE:
	.WORD	E_COLON			; Interpret following word sequence 
	.WORD	C_2
	.WORD	C_QPAIRS
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	C_HERE			; Dictionary pointer onto stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_2
	.WORD	C_ENDIF
	.WORD	C_2
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_WHILE:	.BYTE	$C5,"WHIL",'E'+$80
	.WORD	W_ELSE
C_WHILE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_IF
	.WORD	C_2PLUS			; 2 plus
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SPACES:
	.BYTE	$86,"SPACE",'S'+$80
	.WORD	W_WHILE
C_SPACES:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_MAX
	.WORD	C_QUERYDUP
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0034-$			; 000Ch
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B0035:	.WORD	C_SPACE			; Output space
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	B0035-$			; FFFCh
B0034:	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LESSHARP:
	.BYTE	$82,"<",'#'+$80
	.WORD	W_SPACES
C_LESSHARP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_PAD			; Save intermediate string address
	.WORD	C_HLD
	.WORD	C_STORE			; Store word at addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SHARPGT:
	.BYTE	$82,"#",'>'+$80
	.WORD	W_LESSHARP
C_SHARPGT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_HLD
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_PAD			; Save intermediate string address
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_MINUS
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SIGN:
	.BYTE	$84,"SIG",'N'+$80
	.WORD	W_SHARPGT
C_SIGN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ROT			; 3rd valu down to top of stack
	.WORD	C_0LESS			; Less than 0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0036-$			; 0008h
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	002Dh
	.WORD	C_HOLD
B0036:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SHARP:
	.BYTE	$81,'#'+$80
	.WORD	W_SIGN
C_SHARP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BASE			; Put BASE addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_MDIVMOD
	.WORD	C_ROT			; 3rd valu down to top of stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0009h
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_LESSTHAN
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0037-$			; 0008h
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0007h
	.WORD	C_PLUS			; n1 + n2
B0037:
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0030
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_HOLD
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_SHARPS:
	.BYTE	$82,"#",'S'+$80
	.WORD	W_SHARP
C_SHARPS:
	.WORD	E_COLON			; Interpret following word sequence
B0038:
	.WORD	C_SHARP
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_OR			; OR
	.WORD	C_0EQUALS			; =0
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0038-$			; FFF4h
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DDOTR:
	.BYTE	$83,"D.",'R'+$80
	.WORD	W_SHARPS
C_DDOTR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_DABS
	.WORD	C_LESSHARP
	.WORD	C_SHARPS
	.WORD	C_SIGN
	.WORD	C_SHARPGT
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_OVER			; Copy 2nd down to top of stack
	.WORD	C_MINUS
	.WORD	C_SPACES
	.WORD	C_TYPE			; Output n bytes from addr
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DOTR:
	.BYTE	$82,".",'R'+$80
	.WORD	W_DDOTR
C_DOTR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_SINGTODUB		; Change single number to double
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_DDOTR
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DDOT:
	.BYTE	$82,"D",'.'+$80
	.WORD	W_DOTR
C_DDOT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_DDOTR
	.WORD	C_SPACE			; Output space
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DOT:
	.BYTE	$81,'.'+$80
	.WORD	W_DDOT
C_DOT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_SINGTODUB		; Change single number to double
	.WORD	C_DDOT
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_QUESTION:
	.BYTE	$81,'?'+$80
	.WORD	W_DOT
C_QUESTION:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_DOT
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_UDOT:					; Output as unsigned value
	.BYTE	$82,"U",'.'+$80
	.WORD	W_QUESTION
C_UDOT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_DDOT			; Output double value
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_VLIST:
	.BYTE	$85,"VLIS",'T'+$80
	.WORD	W_UDOT
C_VLIST:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CONTEXT			; Leave vocab pointer on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CR			; Output [CR][LF]
B0039:
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_PFA			; Convert NFA to PFA
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_ID			; Print definition name from name field addr
	.WORD	C_LFA			; Convert param addr to link addr
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_0EQUALS			; =0
	.WORD	C_TERMINAL		; Check for break key
	.WORD	C_OR			; OR
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0039-$			; FFE2h
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_LIST:
	.BYTE	$84,"LIS",'T'+$80
	.WORD	W_VLIST
C_LIST:
	.WORD	E_COLON			; Interpret following word sequence 
	.WORD	C_BASE			; Put BASE addr on stack 
	.WORD	C_FETCH			; Put current base on stack 
	.WORD	C_SWAP			; Get number of list screen to top 
	.WORD	C_DECIMAL			; Sets decimal mode 
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_DUP			; Duplicate top value on stack 
	.WORD	C_SCR			; Set most recently listed
	.WORD	C_STORE			; Store word at addr 
	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END3-S_START3
S_START3:
	.BYTE	"SCR # "
S_END3:
	.WORD	C_DOT			; Output the screen number
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$0010			; 16 lines to do
	.WORD	C_ZERO			; From 0 to 15
	.WORD	C_LDO			; Put start & end loop values on RPP
DO_LINE:
	.WORD	C_CR			; Output [CR][LF] 
	.WORD	C_I			; Line number onto data stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack 
	.WORD	$0003			; Fromat right justified 3 characters
	.WORD	C_DOTR			; Output formatted
	.WORD	C_SPACE			; Output space 
	.WORD	C_I			; Line number onto data stack
	.WORD	C_SCR			; Get screen number
	.WORD	C_FETCH			; Get word from addr on stack 
	.WORD	C_DOTLINE			; Output line from screen
	.WORD	C_TERMINAL		; Check for break key
	.WORD	C_0BRANCH			; Jump if no break key
	.WORD	NO_BRK-$		
	.WORD	C_LEAVE			; Else set loop index to limit (quit loop)
NO_BRK:
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	DO_LINE-$		
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_BASE			; Put BASE addr on stack 
	.WORD	C_STORE			; Restore original base
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_INDEX:
	.BYTE	$85,"INDE",'X'+$80
	.WORD	W_LIST
C_INDEX:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_1PLUS			; 1 plus
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B003D:
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	0003h
	.WORD	C_DOTR
	.WORD	C_SPACE			; Output space
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_DOTLINE			; Output line from screen
	.WORD	C_TERMINAL		; Check for break key
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B003C-$			; 0004h
	.WORD	C_LEAVE			; Quit loop by making index = limit
B003C:
	.WORD	C_LLOOP			; Increment loop & branch if not done
	.WORD	B003D-$			; FFE4h
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_INT:
	.BYTE	$C4,"; IN",'T'+$80
	.WORD	W_INDEX
C_INT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_WHATSTACK		; Check stack pointer, error if not ok
	.WORD	C_COMPILE			; Compile next word into dictionary
	.WORD	X_INT
	.WORD	C_LEFTBRKT		; Set STATE to execute
	.WORD	C_SMUDGE
	.WORD	C_STOP			; Pop BC from return stack (=next)

X_INT:
	.WORD	2+$			; Vector to code
	LD	HL,INTFLAG
	RES	6,(HL)
	EI 
	JP	X_STOP

W_INTFLAG:
	.BYTE	$87,"INTFLA",'G'+$80
	.WORD	W_INT
C_INTFLAG:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	INTFLAG-SYSTEM

W_INTVECT:
	.BYTE	$87,"INTVEC",'T'+$80
	.WORD	W_INTFLAG
C_INTVECT:
	.WORD	X_USER			; Put next word on stack then do next
	.WORD	INTVECT-SYSTEM

W_CPU:
	.BYTE	$84,".CP",'U'+$80
	.WORD	W_INTVECT
C_CPU:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END4-S_START4
S_START4:
	.BYTE	"Z80 "
S_END4:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_2SWAP:
	.BYTE	$85,"2SWA",'P'+$80
	.WORD	W_CPU
C_2SWAP:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ROT			; 3rd valu down to top of stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_ROT			; 3rd valu down to top of stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_2OVER:
	.BYTE	$85,"2OVE",'R'+$80
	.WORD	W_2SWAP
C_2OVER:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_2DUP			; Dup top 2 values on stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_2SWAP
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_EXIT:
	.BYTE	$84,"EXI",'T'+$80
	.WORD	W_2OVER
C_EXIT:
	.WORD	X_STOP

W_J:					; Push outer loop value on stack
	.BYTE	$81,'J'+$80
	.WORD	W_EXIT
C_J:
	.WORD	2+$			; Vector to code
	LD	HL,(RPP)			; Get return stack pointer
	INC	HL			; Skip inner loop values
	INC	HL			; 
	INC	HL			; 
	INC	HL			; 
	JP	X_I2

W_ROLL:
	.BYTE	$84,"ROL",'L'+$80
	.WORD	W_J
C_ROLL:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_GREATER
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B003E-$			; 002Ch
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_MOVER			; Move value from data to return stack
	.WORD	C_PICK
	.WORD	C_RMOVE			; Move word from return to data stack
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_LDO			; Put start & end loop values on RPP
B003F:
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_PLUS			; n1 + n2
	.WORD	C_DUP			; Duplicate top value on stack
	.WORD	C_2MINUS			; 2 minus
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_SWAP			; Swap top 2 values on stack
	.WORD	C_STORE			; Store word at addr
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$FFFF
	.WORD	C_PLOOP			; Loop + stack & branch if not done
	.WORD	B003F-$			; FFE6h
B003E:
	.WORD	C_DROP			; Drop top value from stack
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DEPTH:
	.BYTE	$85,"DEPT",'H'+$80
	.WORD	W_ROLL
C_DEPTH:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_S0			; Push S0 (initial data stack pointer)
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_MINUS
	.WORD	C_2
	.WORD	C_DIV
	.WORD	C_1MINUS			; 1 minus
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DLESSTHAN:
	.BYTE	$82,"D",'<'+$80
	.WORD	W_DEPTH
C_DLESSTHAN:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ROT			; 3rd valu down to top of stack
	.WORD	C_2DUP			; Dup top 2 values on stack
	.WORD	C_EQUALS
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0040-$			; 00$0A
	.WORD	C_2DROP			; Drop top two values from stack
	.WORD	C_ULESS			; IF stack-1 < stack_top leave true flag	
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	B0041-$			; 0008h
B0040:
	.WORD	C_2SWAP
	.WORD	C_2DROP			; Drop top two values from stack
	.WORD	C_GREATER
B0041:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_0GREATER:
	.BYTE	$82,"0",'>'+$80
	.WORD	W_DLESSTHAN
C_0GREATER:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_ZERO			; Put zero on stack
	.WORD	C_GREATER
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_DOTS:
	.BYTE	$82,".",'S'+$80
	.WORD	W_0GREATER
C_DOTS
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CR			; Output [CR][LF]
	.WORD	C_DEPTH
	.WORD	C_0BRANCH			; Add offset to BC if stack top = 0
	.WORD	B0042-$			; 0020h
	.WORD	C_SPFETCH			; Stack pointer onto stack
	.WORD	C_2MINUS			; 2 minus
	.WORD	C_S0			; Push S0 (initial data stack pointer)
	.WORD	C_FETCH			; Get word from addr on stack	
	.WORD	C_2MINUS			; 2 minus
	.WORD	C_LDO			; Put start & end loop values on RPP
B0043:
	.WORD	C_I			; Copy LOOP index to data stack
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_DOT
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$FFFE
	.WORD	C_PLOOP			; Loop + stack & branch if not done
	.WORD	B0043-$			; FFF4h
	.WORD	C_BRANCH			; Add following offset to BC
	.WORD	S_END5-$			; 0011h
B0042:
	.WORD	C_CQUOTE			; Output following string
	.BYTE	S_END5-S_START5
S_START5:
	.BYTE	"STACK EMPTY "
S_END5:
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_CODE:
	.BYTE	$84,"COD",'E'+$80
	.WORD	W_DOTS
C_CODE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_QEXEC			; Error not if not in execute mode
	.WORD	C_XXX1
	.WORD	C_SPSTORE			; Set initial stack pointer value
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_ENDCODE:
	.BYTE	$88,"END-COD",'E'+$80
	.WORD	W_CODE
C_ENDCODE:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_CURRENT
	.WORD	C_FETCH			; Get word from addr on stack
	.WORD	C_CONTEXT
	.WORD	C_STORE			; Store word at addr
	.WORD	C_QEXEC			; Error not if not in execute mode
	.WORD	C_WHATSTACK		; Check stack pointer, error if not ok
	.WORD	C_SMUDGE
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_NEXT:
	.BYTE	$C4,"NEX",'T'+$80
	.WORD	W_ENDCODE
C_NEXT:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	$00C3			; Jump instruction
	.WORD	C_CCOMMA			; Save as 8 bit value
	.WORD	C_LIT			; Puts next 2 bytes on the stack
	.WORD	NEXT			; The address of NEXT
	.WORD	C_COMMA			; Reserve 2 bytes and save n
	.WORD	C_STOP			; Pop BC from return stack (=next)

W_IM2:					; Set interrupt mode 2
	.BYTE	$83,"IM",'2'+$80
	.WORD	W_NEXT
C_IM2:
	.WORD	2+$			; Vector to code
	IM	2			; Mode 2
	JP	NEXT

W_IM1:					; Set interrupt mode 1
	.BYTE	$83,"IM",'1'+$80
	.WORD	W_IM2
C_IM1:
	.WORD	2+$			; Vector to code
	IM	1			; Mode 1
	JP	NEXT

W_IM0:					; Set interrupt mode 0
	.BYTE	$83,"IM",'0'+$80
	.WORD	W_IM1
C_IM0:
	.WORD	2+$			; Vector to code
	IM	0			; Mode 0
	JP	NEXT

W_DI:					; Disable interrupt
	.BYTE	$82,"D",'I'+$80
	.WORD	W_IM0
C_DI:
	.WORD	2+$			; Vector to code
	DI				; Disable interrupt
	JP	NEXT

W_EI:					; Enable interrupt
	.BYTE	$82,"E",'I'+$80
	.WORD	W_DI
C_EI:
	.WORD	2+$			; Vector to code
	EI				; Enable interrupt
	JP	NEXT

W_MON:					; Jump to m/c monitor
	.BYTE	$83,"MO",'N'+$80
	.WORD	W_EI
C_MON:
	.WORD 	2+$
	JP	MONSTART 

W_LLOAD:
	.BYTE	$85,"LLOA",'D'+$80
	.WORD	W_MON
C_LLOAD:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_BLOCK			; Get block address
	.WORD	C_LIT			; Enter loop with null
	.WORD	$0000			; 
LL_BEGIN:
	.WORD	C_DUP			; Dup key
	.WORD	C_0BRANCH			; If null then don't store
	.WORD	LL_NULL-$		
	.WORD	C_DUP			; Dup key again
	.WORD	C_LIT			; Compare to [CR]
	.WORD	$000D			; 
	.WORD	C_EQUALS		
	.WORD	C_0BRANCH			; If not [CR] then jump
	.WORD	LL_STORE-$		; 
	.WORD	C_DROP			; Drop the [CR]
	.WORD	C_CL			; Get characters per line
	.WORD	C_PLUS			; Add to current addr
	.WORD	C_CL			; Make CL MOD value
	.WORD	C_NEGATE			; Form 2s complement of n
	.WORD	C_AND			; Mask out bits
	.WORD	C_BRANCH			; Done this bit so jump
	.WORD	NO_STORE-$
LL_STORE:
	.WORD	C_OVER			; Get address to store at
	.WORD	C_STORE			; Save chr
NO_STORE:
	.WORD	C_1PLUS			; Next addres
	.WORD	C_BRANCH			; Done so jump
	.WORD	LL_CHAR-$		
LL_NULL:
	.WORD	C_DROP			; Was null so drop it
LL_CHAR:
	.WORD	C_KEY			; Get key
	.WORD	C_DUP			; Duplicate it
	.WORD	C_LIT			; Compare with [CTRL] Z
	.WORD	$001A			
	.WORD	C_EQUALS		
	.WORD	C_0BRANCH			; If not EOF then jump
	.WORD	LL_BEGIN-$		; 
	.WORD	C_DROP			; Drop EOF character
	.WORD	C_DROP			; Drop next address
	.WORD	C_STOP			; Pop BC from return stack (=next)
	
W_TASK:
	.BYTE	$84,"TAS",'K'+$80
	.WORD	W_LLOAD
C_TASK:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_STOP			; Pop BC from return stack (=next)
W_TASKEND:

W_EDITI:

W_CLEAR:					; Clear block n
	.BYTE	$85,"CLEA",'R'+$80
	.WORD	W_TASK
C_CLEAR:
	.WORD	E_COLON			; Interpret following word sequence
	.WORD	C_DUP			; Duplicate number
	.WORD	C_SCR			; Get SCR addr
	.WORD	C_STORE			; Store screen number
	.WORD	C_BLOCK			; Get the address of the block
	.WORD	C_BBUF			; Put number of bytes/block on stack
	.WORD	C_ERASE			; Clear the block
	.WORD	C_STOP			; Pop BC from return stack (=next)

CF_UKEY:					; Get key onto stack
	.WORD	2+$			; Vector to code
	CALL	CHR_RD			; User key in routine
	LD	L,A			; Put key on stack
	LD	H,$00			; 
	JP	NEXTS1			; Save & NEXT

CF_UEMIT:					; Chr from stack to output
	.WORD	2+$			; Vector to code
	POP	HL			; Get CHR to output
	LD	A,L			; Put in A
	PUSH	BC			; Save regs
	PUSH	DE			; 
	CALL	CHR_WR			; User output routine
	POP	DE			; Restore regs
	POP	BC			; 
	JP	NEXT			; 

CF_UCR:					; CR output
	.WORD	2+$			; Vector to code
	PUSH	BC			; Save regs
	PUSH	DE			; Just in case
	LD	A,$0D			; Carrage return
	CALL	CHR_WR			; User output routine
	LD	A,$0A			; Line feed
	CALL	CHR_WR			; User output routine
	POP	DE			; Get regs back
	POP	BC			; 
	JP	NEXT			; Next

CF_UQTERMINAL:				; Test for user break
	.WORD	2+$			; Vector to code
	PUSH	BC			; Save regs
	PUSH	DE			; Just in case
	CALL	BREAKKEY			; User break test routine
	POP	DE			; Get regs back
	POP	BC			; 
	LD	H,$00			; Clear H
	LD	L,A			; Result in L
	JP	NEXTS1			; Store it & Next

;------------------------------------------------------------------------------
; SERIAL I/O ROUTINES
;  Change these to suit your target system .....
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; RXA - Receive a byte over SIO/0 Ch A
;------------------------------------------------------------------------------
RXA	CALL	CKSIOA		; Get the status word
	JR	NC,RXA		; Loop until a character arrives
	IN	A,($74)		; Get the character
	RET			; Char ready in A
;------------------------------------------------------------------------------
; TXA - Transmit a byte over SIO/0 Ch A
;------------------------------------------------------------------------------
TXA	PUSH	AF		; Store character
	CALL	CKSIOA		; See if SIO channel A is finished transmitting
	JR	Z,TXA+1		; Loop until SIO flag signals ready
	POP	AF		; Retrieve character
	OUT	($74),A		; Output the character
	RET
;------------------------------------------------------------------------------
; Check SIO Channel A status flag, RX char ready=CY, TX buffer clear=NZ
;------------------------------------------------------------------------------
CKSIOA	XOR	A		; Zeroize A
	OUT	($76),A		; Select Register 0
	IN	A,($76)		; Retrieve Status Word
	RRCA			; RX status into CY flag
	BIT	1,A		; TX Buffer Empty into Z flag
	RET
;------------------------------------------------------------------------------
CHR_RD:	CALL	RXA		; GET A CHARACTER
	CP	$61		; Is UCASE already?
	JR	C,CHR_RD1		; It is, leave it alone
	CP	$7A		; <= "z" ?
	JR	NC,CHR_RD1	; 
	AND	$5F		; It's A-Z, or a-z make it upper case
CHR_RD1	RET	
	
NO_BUF_KEY:
	JP	RXA		; GET A CHARACTER
	
BREAKKEY:	CALL	CKSIOA		; CHECK USART
	JR	NC,NO_KEY		; NOTHING
	IN	A,($74)		; READ THE CHARACTER
	CP	$03		; BREAK?
	JR	Z,WAS_BRK		; YES
	CP	$61		; Is UCASE already?
	JR	C,BRK01		; It is, leave it alone
	CP	$7A		; <= "z" ?
	JR	NC,BRK01
	AND	$5F		; It's A-Z, or a-z make it upper case
BRK01	RET			; ELSE RETURN WITH KEY	

NO_KEY:	XOR	A		; Wasn't break, or no key, so clear
	RET
	
WAS_BRK:	LD	A,$01		; Was break so set flag
	RET

CHR_WR:	RST	08H		; WRITE CHARACTER
	RET
;------------------------------------------------------------------------------		
FINIS	.END
