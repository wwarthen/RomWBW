;===============================================================================
; TIMER - Display system timer value
; Version 1.31 24-July-2024
;===============================================================================
;
;	Author:  Wayne Warthen (wwarthen@gmail.com)
;	Updated: MartinR (July 2024) - A user of uppercase mnemonics
;_______________________________________________________________________________
;
; Usage:
;   TIMER [/C] [/?]
;     ex: TIMER		(display current timer value)
;         TIMER /?	(display version and usage)
;         TIMER /C	(display timer value continuously)
;
; Operation:
;   Reads and displays system timer value.
;
; This code will only execute on a Z80 CPU (or derivitive)
;
; This source code assembles with TASM V3.2 under Windows-11 using the
; following command line:
;	tasm -80 -g3 -l TIMER.ASM TIMER.COM
;	ie: Z80 CPU; output format 'binary' named .COM (rather than .OBJ)
;	and includes a symbol table as part of the listing file.
;_______________________________________________________________________________
;
; Change Log:
;   2018-01-14 [WBW] Initial release
;   2018-01-17 [WBW] Add HBIOS check
;   2019-11-08 [WBW] Add seconds support
;   2024-06-30 [MR ] Display values in decimal rather than hexadecimal
;   2024-07-24 [MR ] Also display value in Hours-Mins-Secs format
;_______________________________________________________________________________
;
; Includes binary-to-decimal subroutine by Alwin Henseler
; Located at: https://www.msx.org/forum/development/msx-development/32-bit-long-ascii
;_______________________________________________________________________________
;
; Includes division subroutines from: https://wikiti.brandonw.net/
;;_______________________________________________________________________________
;
#include "../../ver.inc"		; Used for building RomWBW
;#include "ver.inc"			; Used for testing purposes during code development
;
;===============================================================================
; Definitions
;===============================================================================
;
STKSIZ		.EQU	$40		; Working stack size
;
RESTART		.EQU	$0000		; CP/M restart vector
BDOS		.EQU	$0005		; BDOS invocation vector
;
IDENT		.EQU	$FFFE		; loc of RomWBW HBIOS ident ptr
;
BF_SYSVER	.EQU	$F1		; BIOS: VER function
BF_SYSGET	.EQU	$F8		; HBIOS: SYSGET function
BF_SYSSET	.EQU	$F9		; HBIOS: SYSSET function
BF_SYSGETTIMER	.EQU	$D0		; TIMER subfunction
BF_SYSSETTIMER	.EQU	$D0		; TIMER subfunction
BF_SYSGETSECS	.EQU	$D1		; SECONDS subfunction
BF_SYSSETSECS	.EQU	$D1		; SECONDS subfunction
;
;ASCII Control Characters
LF		.EQU 	00AH		; Line Feed
CR		.EQU 	00DH		; Carriage Return
;
;===============================================================================
; Code Section
;===============================================================================
;
	.ORG	$100
;
	; setup stack (save old value)
	LD	(STKSAV),SP		; save stack
	LD	SP,STACK		; set new stack
;
	; initialization
	CALL	INIT			; initialize
	JR	NZ,EXIT			; abort if init fails
;
	; process
	CALL 	PROCESS			; do main processing
	JR	NZ,EXIT			; abort on error
;
EXIT:	; clean up and return to command processor
	CALL	CRLF			; formatting
	LD	SP,(STKSAV)		; restore stack
	;JP	RESTART			; return to CP/M via restart
	RET				; return to CP/M w/o restart
;
; Initialization
;
INIT:
	CALL	CRLF			; formatting
	LD	DE,MSGBAN		; point to version message part 1
	CALL	PRTSTR			; print it
;
	CALL	IDBIO			; identify active BIOS
	CP	1				; check for HBIOS
	JP	NZ,ERRBIO		; handle BIOS error
;
	LD	A,RMJ << 4 | RMN	; expected HBIOS ver
	CP	D			; compare with result above
	JP	NZ,ERRBIO		; handle BIOS error
;
INITX:
	; initialization complete
	XOR	A			; signal success
	RET				; return
;
; Process
;
PROCESS:
	; look for start of parms
	LD	HL,$81			; point to start of parm area (past len byte)
;
PROCESS00:
	CALL	NONBLANK		; skip to next non-blank char
	JP	Z,PROCESS0		; no more parms, go to display
;
	; check for option, introduced by a "/"
	CP	'/'			; start of options?
	JP	NZ,USAGE		; yes, handle option
	CALL	OPTION			; do option processing
	RET	NZ			; done if non-zero return
	JR	PROCESS00		; continue looking for options
;
PROCESS0:
;
	; Test of API function to set seconds value
	;LD	B,BF_SYSSET		; HBIOS SYSGET function
	;LD	C,BF_SYSSETSECS		; SECONDS subfunction
	;LD	DE,0			; set seconds value
	;LD	HL,1000			; ... to 1000
	;RST	08			; call HBIOS, DE:HL := seconds value
;
	; get and print seconds value
	CALL	CRLF2			; formatting
;
PROCESS1:
	LD	B,BF_SYSGET		; HBIOS SYSGET function
	LD	C,BF_SYSGETTIMER	; TIMER subfunction
	RST	08			; call HBIOS, DE:HL := timer value

	LD	A,(FIRST)
	OR	A
	LD	A,0
	LD	(FIRST),A
	JR	NZ,PROCESS1A

	; TEST FOR NEW VALUE
	LD	A,(LAST)		; last LSB value to A
	CP	L			; compare to current LSB
	JP	Z,PROCESS2		; if equal, bypass display

;*******************************************************************************
;*******************************************************************************

; Formatting code added/amended to print values in decimal and Hours-Mins-Secs
; MartinR June & July-2024

PROCESS1A:
; Save and print new value
	LD	A,L			; new LSB value to A
	LD	(LAST),A		; save as last value
	CALL	PRTCR			; back to start of line

	CALL	B2D32			; Convert DE:HL into ASCII; Start of ASCII buffer returned in HL
	EX	DE,HL
	CALL	PRTSTR			; Display the value

	LD	DE,STRTICK		; "Ticks" message
	CALL	PRTSTR			; Display it

; Get and print seconds value in decimal

	LD	B,BF_SYSGET		; HBIOS SYSGET function
	LD	C,BF_SYSGETSECS		; SECONDS subfunction
	RST	08			; Call HBIOS; DE:HL := seconds value; C := fractional part

	LD	(SEC_MS),DE		; Store the most significant part of the 'seconds' value
	LD	(SEC_LS),HL		; And the less significant......
	LD	A,C			; And also the fractional part
	SLA	A			; But double the 50Hz 'ticks' value to give 1/100ths of a second
	LD	(SEC_FR),A

	CALL	B2D32			; Convert DE:HL into ASCII; Start of ASCII buffer returned in HL
	EX	DE,HL
	CALL	PRTSTR			; Display the value

	CALL	PRTDOT			; Print a '.' seperator

	LD	A,(SEC_FR)		; Retrieve fractional part (1/100ths second)
	CALL	B2D8			; Convert into ASCII - up to 3 digits. Umber of digits returned C
	CALL	PRT_LEAD0		; Print a leading zero if there is exactly 1 character in the string
	EX	DE,HL			; Start of ASCII buffer returned in HL
	CALL	PRTSTR			; Display fractional part of the value

	LD	DE,STRSEC		; "Seconds" message
	CALL	PRTSTR			; Display it

; Now print the seconds value as HMS

	LD	BC,(SEC_MS)		; Retrive the 'seconds' value into AC:IX
	LD	A,B
	LD	IX,(SEC_LS)
	LD	DE,3600			; 3600 seconds in an hour
	CALL	DIV32BY16		; AC:IX divided by DE; Answer in AC:IX; Remainder in HL

	PUSH	HL			; Preserve the remainder on the stack

	LD	D,A			; Shuffle registers around ready for conversion to ASCII
	LD	A,C			; AC:IX into DE:HL
	LD	E,A
	PUSH	IX
	POP	HL

	CALL	B2D32			; Convert DE:HL into ASCII; Start of ASCII buffer returned in HL
	EX	DE,HL
	CALL	PRTSTR			; Display the hours value

	CALL	PRTCOLON		; Print a ':' seperator

	POP	HL			; Retrive the remainder (seconds)

	LD	C,60			; 60 seconds in a minute
	CALL	DIV_HL_C		; HL divided by C; Answer in HL; Remainder in A

	PUSH	AF			; Preserve the remainder (seconds) on the stack

	CALL	B2D16			; Convert HL into ASCII; Start of ASCII buffer returned in HL; Count in C
	CALL	PRT_LEAD0		; Print a leading zero if there is exactly 1 character in the string
	EX	DE,HL
	CALL	PRTSTR			; Display the minutes value

	CALL	PRTCOLON		; Print a ':' seperator

	POP	AF			; Retrive the remainder (seconds)

	CALL	B2D8			; Convert A into ASCII; Start of ASCII buffer returned in HL; Count in C
	CALL	PRT_LEAD0		; Print a leading zero if there is exactly 1 character in the string
	EX	DE,HL
	CALL	PRTSTR			; Display the seconds value

	CALL	PRTDOT			; Print a '.' seperator

	LD	A,(SEC_FR)		; Retrieve the fractional part (1/100ths) of the seconds
	CALL	B2D8			; Convert A into ASCII; Start of ASCII buffer returned in HL
	CALL	PRT_LEAD0		; Print a leading zero if there is exactly 1 character in the string
	EX	DE,HL
	CALL	PRTSTR			; Display the value

	LD	DE,STRHMS		; Print "HH:MM:SS" message
	CALL	PRTSTR

;*******************************************************************************
;*******************************************************************************

PROCESS2:
	LD	A,(CONT)		; continuous display?
	OR	A			; test for true/false
	JR	Z,PROCESS3		; if false, get out
;
	LD	C,6			; BDOS: direct console I/O
	LD	E,$FF			; input char
	CALL	BDOS			; call BDOS, A := char
	OR	A			; test for zero
	JP	Z,PROCESS1		; loop until char pressed
;
PROCESS3:
	XOR	A			; signal success
	RET
;
; Handle special options
;
OPTION:
	INC	HL			; next char
	LD	A,(HL)			; get it
	OR	A			; zero terminator?
	RET	Z			; done if so
	CP	' '			; blank?
	RET	Z			; done if so
	CP	'?'			; is it a '?'?
	JP	Z,USAGE			; yes, display usage
	CP	'C'			; is it a 'C', continuous?
	JP	Z,SETCONT		; yes, set continuous display
	JP	ERRPRM			; anything else is an error
;
USAGE:
	JP	ERRUSE			; display usage and get out
;
SETCONT:
;
	OR	$FF			; SET A TO TRUE
	LD	(CONT),A		; AND SET CONTINUOUS FLAG
	JR	OPTION			; CHECK FOR MORE OPTION LETTERS
;
; Identify active BIOS.  RomWBW HBIOS=1, UNA UBIOS=2, else 0
;
IDBIO:
;
	; CHECK FOR UNA (UBIOS)
	LD	A,($FFFD)		; fixed location of UNA API vector
	CP	$C3			; jp instruction?
	JR	NZ,IDBIO1		; if not, not UNA
	LD	HL,($FFFE)		; get jp address
	LD	A,(HL)			; get byte at target address
	CP	$FD			; first byte of UNA push ix instruction
	JR	NZ,IDBIO1		; if not, not UNA
	INC	HL			; point to next byte
	LD	A,(HL)			; get next byte
	CP	$E5			; second byte of UNA push ix instruction
	JR	NZ,IDBIO1		; if not, not UNA, check others
;
	LD	BC,$04FA		; UNA: get BIOS date and version
	RST	08			; DE := ver, HL := date
;
	LD	A,2			; UNA BIOS id = 2
	RET				; and done
;
IDBIO1:
	; Check for RomWBW (HBIOS)
	LD	HL,($FFFE)		; HL := HBIOS ident location
	LD	A,'W'			; First byte of ident
	CP	(HL)			; Compare
	JR	NZ,IDBIO2		; Not HBIOS
	INC	HL				; Next byte of ident
	LD	A,~'W'			; Second byte of ident
	CP	(HL)			; Compare
	JR	NZ,IDBIO2		; Not HBIOS
;	
	LD	B,BF_SYSVER		; HBIOS: VER function
	LD	C,0			; required reserved value
	RST	08			; DE := version, L := platform id
;
	LD	A,1			; HBIOS BIOS id = 1
	RET				; and done
;
IDBIO2:
	; No idea what this is
	XOR	A			; Setup return value of 0
	RET				; and done
;
; Print character in A without destroying any registers
;
PRTCHR:
	PUSH	BC			; save registers
	PUSH	DE
	PUSH	HL
	LD	E,A			; character to print in E
	LD	C,$02			; BDOS function to output a character
	CALL	BDOS			; do it
	POP	HL			; restore registers
	POP	DE
	POP	BC
	RET
;
; Print a 0 if C=1
;
PRT_LEAD0:
	DEC	C			; Decrement C, and a value of 1 becomee zero
	RET	NZ			; If C wasn't 1, then no leading space required
	LD	A,'0'			; Print the leading zero
	JR	Z,PRTCHR
;
PRTDOT:
;
	; shortcut to print a dot preserving all regs
	PUSH	AF			; save af
	LD	A,'.'			; load dot char
	CALL	PRTCHR			; print it
	POP	AF			; restore af
	RET				; done
;
PRTCOLON:
;
	; shortcut to print a colon preserving all regs
	PUSH	AF			; save af
	LD	A,':'			; load colon char
	CALL	PRTCHR			; print it
	POP	AF			; restore af
	RET				; done
;
PRTCR:
;
	; shortcut to print a CR preserving all regs
	PUSH	AF			; save af
	LD	A,13			; load CR value
	CALL	PRTCHR			; print it
	POP	AF			; restore af
	RET				; done
;
; Print a zero terminated string at (DE) without destroying any registers
;
PRTSTR:
	PUSH	DE
;
PRTSTR1:
	LD	A,(DE)			; get next char
	OR	A
	JR	Z,PRTSTR2
	CALL	PRTCHR
	INC	DE
	JR	PRTSTR1
;
PRTSTR2:
	POP	DE			; restore registers
	RET
;
; Print the value in A in hex without destroying any registers
;
PRTHEX:
	PUSH	AF			; save AF
	PUSH	DE			; save DE
	CALL	HEXASCII		; convert value in A to hex chars in DE
	LD	A,D			; get the high order hex char
	CALL	PRTCHR			; print it
	LD	A,E			; get the low order hex char
	CALL	PRTCHR			; print it
	POP	DE			; restore DE
	POP	AF			; restore AF
	RET				; done
;
; print the hex word value in bc
;
PRTHEXWORD:
	PUSH	AF
	LD	A,B
	CALL	PRTHEX
	LD	A,C
	CALL	PRTHEX
	POP	AF
	RET
;
; print the hex dword value in de:hl
;
PRTHEX32:
	PUSH	BC
	PUSH	DE
	POP	BC
	CALL	PRTHEXWORD
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD
	POP	BC
	RET
;
; Convert binary value in A to ascii hex characters in DE
;
HEXASCII:
	LD	D,A			; save A in D
	CALL	HEXCONV			; convert low nibble of A to hex
	LD	E,A			; save it in E
	LD	A,D			; get original value back
	RLCA				; rotate high order nibble to low bits
	RLCA
	RLCA
	RLCA
	CALL	HEXCONV			; convert nibble
	LD	D,A			; save it in D
	RET				; done
;
; Convert low nibble of A to ascii hex
;
HEXCONV:
	AND	$0F			; low nibble only
	ADD	A,$90
	DAA
	ADC	A,$40
	DAA
	RET
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
PRTDECB:
	PUSH	HL
	LD	H,0
	LD	L,A
	CALL	PRTDECW			; print it
	POP	HL
	RET
;
PRTDECW:
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	CALL	PRTDEC0
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
PRTDEC0:
	LD	E,'0'
	LD	BC,-10000
	CALL	PRTDEC1
	LD	BC,-1000
	CALL	PRTDEC1
	LD	BC,-100
	CALL	PRTDEC1
	LD	C,-10
	CALL	PRTDEC1
	LD	E,0
	LD	C,-1
PRTDEC1:
	LD	A,'0' - 1
PRTDEC2:
	INC	A
	ADD	HL,BC
	JR	C,PRTDEC2
	SBC	HL,BC
	CP	E
	RET	Z
	LD	E,0
	CALL	PRTCHR
	RET
;
; Start a new line
;
CRLF2:
	CALL	CRLF			; two of them
CRLF:
	PUSH	AF			; preserve AF
	LD	A,CR
	CALL	PRTCHR			; print CR
	LD	A,LF
	CALL	PRTCHR			; print LF
	POP	AF			; restore AF
	RET
;
; Get the next non-blank character from (HL).
;
NONBLANK:
	LD	A,(HL)			; load next character
	OR	A			; string ends with a null
	RET	Z			; if null, return pointing to null
	CP	' '			; check for blank
	RET	NZ			; return if not blank
	INC	HL			; if blank, increment character pointer
	JR	NONBLANK		; and loop
;
; Convert character in A to uppercase
;
UCASE:
	CP	'a'			; if below 'a'
	RET	C			; ... do nothing and return
	CP	'z' + 1			; if above 'z'
	RET	NC			; ... do nothing and return
	RES	5,A			; clear bit 5 to make lower case -> upper case
	RET				; and return
;
; Add the value in A to HL (HL := HL + A)
;
ADDHL:
	ADD	A,L			; A := A + L
	LD	L,A			; Put result back in L
	RET	NC			; if no carry, we are done
	INC	H			; if carry, increment H
	RET				; and return
;
; Jump indirect to address in HL
;
JPHL:
	JP	(HL)
;
; Errors
;
ERRUSE:	; command usage error (syntax)
	LD	DE,MSGUSE
	JR	ERR
;
ERRPRM:	; command parameter error (syntax)
	LD	DE,MSGPRM
	JR	ERR
;
ERRBIO:	; invalid BIOS or version
	LD	DE,MSGBIO
	JR	ERR
;
ERR:	; print error string and return error signal
	CALL	CRLF2			; print newline
;
ERR1:	; without the leading crlf
	CALL	PRTSTR			; print error string
;
ERR2:	; without the string
;	CALL	CRLF			; print newline
	OR	$FF			; signal error
	RET				; done
;
;
;===============================================================================
; Subroutine to print decimal numbers
;===============================================================================
;
; Combined routine for conversion of different sized binary numbers into
; directly printable ASCII(Z)-string
; Input value in registers, number size and -related to that- registers to fill
; is selected by calling the correct entry:
;
;  entry  inputregister(s)  decimal value 0 to:
;   B2D8             A                    255  (3 digits)
;   B2D16           HL                  65535   5   "
;   B2D24         E:HL               16777215   8   "
;   B2D32        DE:HL             4294967295  10   "
;   B2D48     BC:DE:HL        281474976710655  15   "
;   B2D64  IX:BC:DE:HL   18446744073709551615  20   "
;
; The resulting string is placed into a small buffer attached to this routine,
; this buffer needs no initialization and can be modified as desired.
; The number is aligned to the right, and leading 0's are replaced with spaces.
; On exit HL points to the first digit, (B)C = number of decimals
; This way any re-alignment / postprocessing is made easy.
; Changes: AF,BC,DE,HL,IX
;
; by Alwin Henseler
; https://msx.org/forum/topic/who-who/dutch-hardware-guy-pops-back-sort
;
; Found at:
; https://www.msx.org/forum/development/msx-development/32-bit-long-ascii
;
; Tweaked to assemble using TASM 3.2 by MartinR 23June2024
;
B2D8:	LD	H,0
	LD	L,A
B2D16:	LD	E,0
B2D24:	LD	D,0
B2D32:	LD	BC,0
B2D48:	LD	IX,0			; zero all non-used bits
B2D64:	LD	(B2DINV),HL
	LD	(B2DINV+2),DE
	LD	(B2DINV+4),BC
	LD	(B2DINV+6),IX		; place full 64-bit input value in buffer
	LD	HL,B2DBUF
	LD	DE,B2DBUF+1
	LD	(HL),' '
B2DFILC	.EQU $-1			; address of fill-character
	LD	BC,18
	LDIR				; fill 1st 19 bytes of buffer with spaces
	LD	(B2DEND-1),BC		; set BCD value to "0" & place terminating 0
	LD	E,1			; no. of bytes in BCD value
	LD	HL,B2DINV+8		; (address MSB input)+1
	LD	BC,00909H
	XOR	A
B2DSKP0:DEC	B
	JR	Z,B2DSIZ		; all 0: continue with postprocessing
	DEC	HL
	OR	(HL)			; find first byte <>0
	JR	Z,B2DSKP0
B2DFND1:DEC	C
	RLA
	JR	NC,B2DFND1		; determine no. of most significant 1-bit
	RRA
	LD	D,A			; byte from binary input value
B2DLUS2:PUSH	HL
	PUSH	BC
B2DLUS1:LD	HL,B2DEND-1		; address LSB of BCD value
	LD	B,E			; current length of BCD value in bytes
	RL	D			; highest bit from input value -> carry
B2DLUS0:LD	A,(HL)
	ADC	A,A
	DAA
	LD	(HL),A			; double 1 BCD byte from intermediate result
	DEC	HL
	DJNZ	B2DLUS0			; and go on to double entire BCD value (+carry!)
	JR	NC,B2DNXT
	INC	E			; carry at MSB -> BCD value grew 1 byte larger
	LD	(HL),1			; initialize new MSB of BCD value
B2DNXT:	DEC	C
	JR	NZ,B2DLUS1		; repeat for remaining bits from 1 input byte
	POP	BC			; no. of remaining bytes in input value
	LD	C,8			; reset bit-counter
	POP	HL			; pointer to byte from input value
	DEC	HL
	LD	D,(HL)			; get next group of 8 bits
	DJNZ	B2DLUS2			; and repeat until last byte from input value
B2DSIZ:	LD	HL,B2DEND		; address of terminating 0
	LD	C,E			; size of BCD value in bytes
	OR	A
	SBC	HL,BC			; calculate address of MSB BCD
	LD	D,H
	LD	E,L
	SBC	HL,BC
	EX	DE,HL			; HL=address BCD value, DE=start of decimal value
	LD	B,C			; no. of bytes BCD
	SLA	C			; no. of bytes decimal (possibly 1 too high)
	LD	A,'0'
	RLD				; shift bits 4-7 of (HL) into bit 0-3 of A
	CP	'0'			; (HL) was > 9h?
	JR	NZ,B2DEXPH		; if yes, start with recording high digit
	DEC	C			; correct number of decimals
	INC	DE			; correct start address
	JR	B2DEXPL			; continue with converting low digit
B2DEXP:	RLD				; shift high digit (HL) into low digit of A
B2DEXPH:LD	(DE),A			; record resulting ASCII-code
	INC	DE
B2DEXPL:RLD
	LD	(DE),A
	INC	DE
	INC	HL			; next BCD-byte
	DJNZ	B2DEXP			; and go on to convert each BCD-byte into 2 ASCII
	SBC	HL,BC			; return with HL pointing to 1st decimal
	RET

B2DINV:	.FILL	8			; space for 64-bit input value (LSB first)
B2DBUF:	.FILL	20			; space for 20 decimal digits
B2DEND:	.DB	000H			; space for terminating character

;*******************************************************************************

; The following routine divides AC:IX by DE and places the quotient
; in AC:IX and the remainder in HL

; https://wikiti.brandonw.net/

; IN:	ACIX=dividend, DE=divisor
; OUT:	ACIX=quotient, DE=divisor, HL=remainder, B=0

DIV32BY16:
	LD	HL,0
	LD	B,32
DIV32BY16_LOOP:
	ADD	IX,IX
	RL	C
	RLA
	ADC	HL,HL
	JR	C,DIV32BY16_OVERFLOW
	SBC	HL,DE
	JR	NC,DIV32BY16_SETBIT
	ADD	HL,DE
	DJNZ	DIV32BY16_LOOP
	RET
DIV32BY16_OVERFLOW:
	OR	A
	SBC	HL,DE
DIV32BY16_SETBIT:
	INC	IX
	DJNZ	DIV32BY16_LOOP
	RET

;*******************************************************************************

; The following routine divides HL by C and places the quotient in HL
; and the remainder in A

; https://wikiti.brandonw.net/

DIV_HL_C:
	XOR	A
	LD	B, 16

LOOPDIV1:
	ADD	HL, HL
	RLA
	JR	C, $+5
	CP	C
	JR	C, $+4

	SUB	C
	INC	L

	DJNZ	LOOPDIV1

	RET

;===============================================================================
; Messages Section
;===============================================================================

MSGBAN	.DB	"TIMER v1.31, 24-Jul-2024",CR,LF
	.DB	"Copyright (C) 2019, Wayne Warthen, GNU GPL v3",CR,LF
	.DB	"Updated by MartinR 2024",0
MSGUSE	.DB	"Usage: TIMER [/C] [/?]",CR,LF
	.DB	"  ex. TIMER           (display current timer value)",CR,LF
	.DB	"      TIMER /?        (display version and usage)",CR,LF
	.DB	"      TIMER /C        (display timer value continuously)",0
MSGPRM	.DB	"Parameter error (TIMER /? for usage)",0
MSGBIO	.DB	"Incompatible BIOS or version, "
	.DB	"HBIOS v", '0' + rmj, ".", '0' + rmn, " required",0
STRTICK	.DB	" Ticks   ",0
STRSEC	.DB	" Seconds   ",0
STRHMS	.DB	" HH:MM:SS",0

;===============================================================================
; Storage Section
;===============================================================================

SEC_MS	.DW	0			; Storage space to preserve the seconds value as
SEC_LS	.DW	0			; most and less significant parts
SEC_FR	.DB	0			; And the fractional part (1/100s of a second)

LAST	.DB	0			; last LSB of timer value
CONT	.DB	0			; non-zero indicates continuous display
FIRST	.DB	$FF			; first pass flag (true at start)

STKSAV	.DW	0			; stack pointer saved at start
	.FILL STKSIZ,0			; stack
STACK	.EQU $				; new stack top

	.END
