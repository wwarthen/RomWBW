;	***********************************************************
;
;         	DISASSEMBLY OF CONSOLE COMMAND PROCESSOR
;			FOR CP/M VERSION 2.2
;
;	*********************************************************** 
;		     LAST REVISION: 23 DEC 1981
;	***********************************************************
;
;	LEGAL NOTICE:
;
;	This assembly listing is not the product of Digital
;	Research Inc. and as such cannot be guaranteed for
;	accuracy or completeness. The assignment of labels,
;	comments and interpretation of the code is thought
;	to be appropriate, but may not be what was originally
;	intended. This disclaimer renounces and ignores all
;	other claims and disclaimers regardless of source.
;	No warrantee is made as to the merchantability or
;	fitness for any purpose. Similarity between this
;	program listing and any other program living or dead
;	is purely coincidental.
;
;	EQUATES
;
MSIZE:	EQU	56	;CPM SIZE IN KILOBYTES
;
;START:	EQU	(MSIZE - 20) * 1024 + 2D00H
START:	EQU	0D000H
;
BDOS:	EQU	0005H	;Link to operating system
IOBYTE:	EQU	0003H	;I/O assigment byte for transient programs
LOGIN:	EQU	0004H	;User number and disk number for transient programs
DFCB:	EQU	005CH	;Default file control block
TPA:	EQU	0100H	;Start of transient program area
DDMA:	EQU	0080H	;Default DMA block
SECLEN:	EQU	0080H	;Sector length := 128 bytes.
FBASE:	EQU	START + 0800H	;Start of operating system &
			;location of BDOS serial numbers.
;
;	SERIAL NUMBERS
;
VER:	EQU	2	;CPM VERSION
REL	EQU	2	;CPM RELEASE
REV:	EQU	00	;USER REVISION
SNH	EQU	00	;SERIAL NUMBER, HIGH
SNL	EQU	00	;SERIAL NUMBER, LOW
;
;	NOTE:
;		USER MUST INSERT CORRECT SERIAL NUMBER
;		IN THE FORMAT HH-LLLL, WHERE HH IS TWO
;		DIGITS & LLLL IS FOUR DIGITS. IF THE
;		SERIAL NUMBERS IN CCP/CPM AND BDOS/CPM
;		DO NOT MATCH, YOU WILL BOMB OUT WHEN
;		LOADING A TRANSIENT PROGRAM.
;
;
	ORG	START	;SET PROGRAM START
;
;	NOTE:
;		On entry (C) contains the user number in the
;		upper 4 bits, and the current logged in disk
;		number in to lower 4 bits. This is why you log
;		back to disk B: if you rebooted while logged
;		into B:
;
ORIGIN:	JMP	CCP1	;JUMP TO START OF CONSOLE COMMAND PROGRAM
;
	JMP	CCP0	;JUMP TO START OF CCP W/ CLEARING OF INPUT BUFFER COUNTER
;
;	INPUT BUFFER WITH COPYRIGHT MESSAGE THROWN IN
;
INPB:	DB	127	;MAXIMUM LENGTH OF INPUT BUFFER
INBLEN:	DB	0	;CURRENT LENGTH OF INPUT BUFFER
BUFFER:	DB	'                '
	DB	'COPYRIGHT (C) 1979, '
	DB	'DIGITAL RESEARCH  '
	DS	BUFFER+128-$
;
;	POINTERS TO INPUT BUFFER
;
BPTR1:	DW	BUFFER	;Pointer to input buffer used while parsing input line
BPTR2:	DW	0000H	;Pointer to start of current command inn input buffer.
			;Used by WHAT for error prompt.
;	***************
;	SUBROUTINE AREA
;	***************
;
;	TIES TO BDOS VIA VECTOR IN 0005H
;
;	NOTE:
;		The code in this section could be cleaned up
;		shortened by rearranging things to have the
;		code flow from one segment to the next
;		instead of jumping back.
;
OUTPUT:	MOV	E,A	;OUTPUT 1 BYTE TO CONSOLE
	MVI	C,02H	;
	JMP	BDOS	;
;
;	NOTE:
;		Why not include OUTPUT inside of PCHAR and
;		thus eliminate an- extra call?
;		The only other call to OUTPUT is in PMSG,
;		which should be changed anyway.
;
;PCHAR:	PUSH	B	;
;	MOV	E,A	;
;	MVI	C,02H	;
;	CALL	BDOS	;
;	POP	B	;
;	RET		;
;
PCHAR:	PUSH	B	;PRINT A CHARACTER ON THE CONSOLE
	CALL	OUTPUT	;
	POP	B	;
	RET		;
;
PCRLF:	MVI	A,0DH	;PRINT A CARRIAGE RETURN & LINE FEED
	CALL	PCHAR	;
	MVI	A,0AH	;
	JMP	PCHAR	;
;
SPACE:	MVI	A,20H	;PRINT A SPACE
	JMP	PCHAR	;
;
CRMSG:	PUSH	B	;PRINT A STRING PRECEDED BY A CR/LF
	CALL	PCRLF	;
	POP	H	;
;
;	This code could be shortened by terminating the
;	error code strings with a '$' and using BDOS
;	command 9.
;
PMSG:	MOV	A,M	;PRINT A STRING TERMINATED BY A NULL
	ORA	A	;
	RZ		;
	INX	H	;
	PUSH	H	;
	CALL	OUTPUT	;
	POP	H	;
	JMP	PMSG	;
;
RESET:	MVI	C,0DH	;RESET THE DISK SYSTEM
	JMP	BDOS	;
;
SELDSK:	MOV	E,A	;SELECT DISK
	MVI	C,0EH	;
	JMP	BDOS	;
;
BDOS1:	CALL	BDOS	; CALL TO BDOS W/ RETURN VALUE SAVED
	STA	RETVAL	;
	INR	A	;Set the ZFLAG for error condition
	RET		;
;
OPENF:	MVI	C,0FH	;OPEN DISK FILE FOR READING OR WRITING
	JMP	BDOS1	; CALL TO BDOS W/ RETURN VALUE
;
OPENF1:	XRA	A	;OPEN FILE @ FCB, AND ZERO RECORD COUNTER
	STA	FCB+32	;
	LXI	D,FCB	;
	JMP	OPENF	;
;
CLOSEF:	MVI	C,10H	;CLOSE FILE AFTER READING OR WRITING
	JMP	BDOS1	; CALL TO BDOS W/ RETURN VALUE
;
SRCHF:	MVI	C,11H	;SEARCH FOR FIRST OCCURENCE OF FILE NAME
	JMP	BDOS1	; CALL TO BDOS W/ RETURN VALUE
;
SRCHNX:	MVI	C,12H	;SEARCH FOR NEXT OCCURENCE OF FILE NAME
	JMP	BDOS1	; CALL TO BDOS W/ RETURN VALUE
;
SRCHF1:	LXI	D,FCB	;SEARCH FOR FIRST OCCURENCE OF FILE
	JMP	SRCHF	; NAME USING (FCB).
;
DELETF:	MVI	C,13H	;DELETE FILE FROM DIRECTORY
	JMP	BDOS	;
;
BDOS2:	CALL	BDOS	; CALL TO BDOS W/ RETURN VALUE
	ORA	A	;
	RET		;
;
READF:	MVI	C,14H	;READ ONE SECTOR FROM DISK
	JMP	BDOS2	; CALL TO BDOS W/ RETURN VALUE
;
READ1:	LXI	D,FCB	;READ ONE SECTOR USING 'FCB'
	JMP	READF	;
;
WRITEF:	MVI	C,15H	;WRITE ONE SECTOR TO DISK
	JMP	BDOS2	; CALL TO BDOS W/ RETURN VALUE
;
CREATE:	MVI	C,16H	;CREATE A NEW FILE NAME IN DISK DIRECTORY
	JMP	BDOS1	; CALL TO BDOS W/ RETURN VALUE
;
RENAME:	MVI	C,17H	;RENAME EXISTING FILE IN DISK DIRECTORY
	JMP	BDOS	;
;
GETUSR:	MVI	E,0FFH	;GET CURRENT USER NUMBER
;
;	SET USER NUMBER TO VALUE IN (E), EXCEPT IF
;	VALUE IS 0FFH.
;
SETUSR:	MVI	C,20H	;
	JMP	BDOS	;
;
;	Set log-in byte for transient program with current
;	user number in upper 4 bits and current drive in
;	lower 4 bits.
;
SETLOG:	CALL	GETUSR	; SET LOG-IN BYTE W/ CURRENT DRIVE & USER NUMBER
	ADD	A	;
	ADD	A	;
	ADD	A	;
	ADD	A	;Shift user number to upper nibble
	LXI	H,CURDSK	;
	ORA	M	;Combine with disk number
	STA	LOGIN	;Place where transient programs
	RET		;  can find it.
;
;	LOG IN CURRENT DISK
;	Place current drive number in log-in byte without
;	including user number.
;
LOGCUR:	LDA	CURDSK	;
	STA	LOGIN	;
	RET		;
;
;	CONVERT lower case INPUT TO UPPER CASE
;
LCUC:	CPI	61H	;'a'
	RC		;
	CPI	7BH	;'z'+1
	RNC		;
	ANI	5FH	;MASK OFF BIT 5
	RET		;
;
;	COMMAND INPUT
;
;	IF SUBMIT FLAG <> 0 THEN INPUT FROM SUBMIT FILE\
;		ELSE INPUT FROM KEYBOARD INPUT BUFFER
;
CMNDIN:	LDA	SUBFL	;CHECK SUBMIT FILE FLAG
	ORA	A	;
	JZ	LINEIN	;FLAG RESET: GET INPUT FROM KEYBOARD
;
;	NOTE ABOUT SUBMIT FILES:
;
;	When the command SUBMIT <filename>
;	is given, a file named $$$.SUB is compiled with
;	one command line per record in the file.
;	the file is unusual in that the commands are stored
;	in reverse order. This makes it simple for the
;	following code to pull one command off at a time,
;	erasing as it goes. Note that the sector counter is
;	decremented and the file closed each time.
;	When the last command has been executed, or if an
;	error is encountered, the $$$.SUB file is erased
;	and control reverts to the keyboard for input.
;
	LDA	CURDSK	;FLAG SET: GET INPUT FROM SUBMIT FILE ON CURRENT DISK
	ORA	A	;
	MVI	A,00H	;
	CNZ	SELDSK	;Set to disk 0 if not there already
	LXI	D,SUBFCB	; Point to submit file's file control block
	CALL	OPENF	; Open the submit file for reading
	JZ	LINEIN	;Go to console on Open File Error
	LDA	SUBFCB+15	;Get top sector number
	DCR	A	;Decrement? Yes $$$.SUB files are backwards
	STA	SUBFCB+32	;Put number in Next Sector slot
	LXI	D,SUBFCB	;
	CALL	READF	;Read sector into buffer
	JNZ	LINEIN	;Go to console on read error
	LXI	D,INBLEN	;Point to start of keyboard buffer
	LXI	H,DDMA	;Point to start of default buffer
	MVI	B,SECLEN	;Set counter
	CALL	BLKMOV	;Move line into keyboard buffer
	LXI	H,SUBFCB+14	;
	MVI	M,00H	;
	INX	H	;
	DCR	M	;Decrement sector count
	LXI	D,SUBFCB	;close the file
	CALL	CLOSEF	;
	JZ	LINEIN	;Go to console on close error
	LDA	CURDSK	;
	ORA	A	;
	CNZ	SELDSK	;Set to current disk if not so already
	LXI	H,BUFFER	;
	CALL	PMSG	;Echo the $$$.SUB line to console
	CALL	KSTAT	;Check for a keyboard break
	JZ	LINP1	;NO BREAK- Continue
	CALL	EXITSB	; BREAK- Close off submit mode
	JMP	NXTCMD	;This leaves the return address on the
			;stack, but NXTCMD re-initializes stack
;
;	Get the input from the Console Device
;
LINEIN:	CALL	EXITSB	;RESET SUBMIT MODE FLAGS< ETC
	CALL	SETLOG	; SET LOG-IN BYTE W/ CURRENT DRIVE & USER NUMBER
	MVI	C,0AH	;BDOS COMMAND 10 ::= READ INPUT BUFFER
	LXI	D,INPB	;POINT TO START OF INPUT BUFFER
	CALL	BDOS	;GET A LINE FROM THE CONSOLE
	CALL	LOGCUR	;
LINP1:	LXI	H,INBLEN	;
	MOV	B,M	;Move the line byte count into (B)
LINP2:	INX	H	;Step through buffer changing lower
	MOV	A,B	;case into upper case.
	ORA	A	;
	JZ	LINP3	;Exit when (B)=0
	MOV	A,M	;
	CALL	LCUC	;Convert lower case to UPPER CASE
	MOV	M,A	;
	DCR	B	;
	JMP	LINP2	;Loop
;
LINP3:	MOV	M,A	;Poke a zero into end of line to mark end
	LXI	H,BUFFER	;Save command starting address
	SHLD	BPTR1	; for later use.
	RET		;
;
;	KEYBOARD STATUS CHECK
;	Return with ZFLAG set is no key pressed
;	Else return with character in accumulator
;
KSTAT:	MVI	C,0BH	;
	CALL	BDOS	;
	ORA	A	;
	RZ		;
	MVI	C,01H	;
	CALL	BDOS	;
	ORA	A	;
	RET		;
;
;	INTEROGATE THE DISK
;
INTDSK:	MVI	C,19H	;
	JMP	BDOS	;
;
;	SET THE DMA ADDRESS
;
SETDMA:	LXI	D,DDMA	;
STDMA1:	MVI	C,1AH	;
	JMP	BDOS	;
;
;	EXIT THE SUBMIT MODE
;	Check to see if the Submit flag is set
;	and reset it, along with the disk selection
;	Erase any $$$.SUB file that may be in the directory
;
EXITSB:	LXI	H,SUBFL	;SUBMIT FILE FLAG
	MOV	A,M	;
	ORA	A	;
	RZ		;Not in submit mode, exit
	MVI	M,00H	;Reset submit flag
	XRA	A	;
	CALL	SELDSK	;Select correct disk
	LXI	D,SUBFCB	;
	CALL	DELETF	;Delete the $$$.SUB file from disk
	LDA	CURDSK	;
	JMP	SELDSK	;Restore current disk and exit
;
;	COMPARE SERIAL NUMBERS
;	Serial numbers of CCP and BDOS are
;	compared. If there is no match, you
;	are banished to Digital Siberia.
;	This S/R is called before a transient
;	program is loaded into the TPA.
;
CMPSER:	LXI	D,SERNO	;Point to serial no in CCP
	LXI	H,FBASE	;Point to serial no in BDOS
	MVI	B,6	;Number of bytes to compared
CMPSN1:	LDAX	D	;
	CMP	M	;
	JNZ	FATAL	; OK, you've had it. You are locked out.
	INX	D	;
	INX	H	;
	DCR	B	;
	JNZ	CMPSN1	;
	RET		; Good comparison. You are home free
;
;	GENERAL PURPOSE ERROR HANDLING ROUTINE
;	Anything that you do wrong in entering a
;	command lands you here. The command line
;	is typed back at you for your edification
;	and embarrassment. After you have been shown
;	a '?', you are put back in the command mode.
;
WHAT:	CALL	PCRLF	;
	LHLD	BPTR2	; Point to the offending command
WHAT1:	MOV	A,M	; and print until a space or null is found
	CPI	' '	;
	JZ	WHAT2	;
	ORA	A	;
	JZ	WHAT2	;
	PUSH	H	;
	CALL	OUTPUT	;
	POP	H	;
	INX	H	;
	JMP	WHAT1	;
;
WHAT2:	MVI	A,'?'	; OK, what did you have in mind?
	CALL	OUTPUT	;
	CALL	PCRLF	;
	CALL	EXITSB	;
	JMP	NXTCMD	; Back for another command.
;
;	SPECIAL CHARACTER CHECK
;	Returns with ZFLAG set if any of the special
;	characters is found, or bombs you out if a
;	control character is found. Contains a useless
;	byte.
;
CHRCHK:	LDAX	D	;
	ORA	A	;
	RZ		;Exit on null
	CPI	' '	;
	JC	WHAT	;Bomb out on control character
	RZ		;
	CPI	'='	;
	RZ		;
	CPI	'_'	;
	RZ		;
	CPI	'.'	;
	RZ		;
	CPI	':'	;
	RZ		;
	CPI	';'	;
	RZ		;
	CPI	'<'	;
	RZ		;
	CPI	'>'	;
	RZ		; This command is redundant!
	RET		;
;
;	STEP (DE) UNTIL A NULL OR NON-SPACE IS FOUND
;	Return with the character in the accumulator.
;
STEP:	LDAX	D	;
	ORA	A	;
	RZ		;
	CPI	20H	;' '
	RNZ		;
	INX	D	;
	JMP	STEP	;
;
;	ADD THE ACCUMULATOR TO (HL)
;	Return with the result in (HL)
;
ADDAH:	ADD	L	; (HL) <-  (HL) + (A)
	MOV	L,A	;
	RNC		;
	INR	H	;
	RET		;
;
;	TRANSFER FILE CONTROL BLOCK
;	This is a key subroutine that handles all
;	of the setting up of file control blocks
;	and of moving around the control buffer.
;
;	No entry parameters are passed in registers
;	On exit (A) contains a count of the number of
;	'?' wildcards in file control block and ZFLAG
;	is set if this count =0 and FCB contains the
;	file block. The input buffer pointer has been
;	advanced to one beyond end of information used.
;
;	This subroutine is not only used to set up
;	file control blocks, but also the numbers
;	for SAVE and USER.
;
TRFCB:	MVI	A,00H	;Initial offset=0, primary entry point
TRFCB1:	LXI	H,FCB	;(Alternate entry point, offset in (A))
	CALL	ADDAH	;Point to current character in FCB
	PUSH	H	;
	PUSH	H	;Save pointer twice.
	XRA	A	;
	STA	TRDISK	;
	LHLD	BPTR1	;Get current pointer to the input buffer
	XCHG		;
	CALL	STEP	;Get first non-blank character
	XCHG		;
	SHLD	BPTR2	;Save pointer in case of error
	XCHG		;
	POP	H	;Get FCB pointer
	LDAX	D	;
	ORA	A	;Check for null command
	JZ	TRFCB2	;
	SBI	40H	;Remove ASCII bias.
	MOV	B,A	;Save possible disk number in (B)
	INX	D	;
	LDAX	D	;
	CPI	':'	; This means that this is a disk number.
	JZ	TRFCB3	; Go set transient disk.
	DCX	D	; Get current logged in disk number.
TRFCB2:	LDA	CURDSK	;
	MOV	M,A	;
	JMP	TRFCB4	;
;
TRFCB3:	MOV	A,B	; Set transient disk number.
	STA	TRDISK	;
	MOV	M,B	; Put disk number into head of File Control Block.
	INX	D	;
;
;	Move file name of up to 8 characters into bytes
;	1 through 8 of FCB. Exit at reaching a special
;	character or a null. Pad excess with blanks.
;	If a '*' is found, fill the rest of the name block
;	with '?'
;
TRFCB4:	MVI	B,08H	; Move file name of up to 8 Characters.
TRFCB5:	CALL	CHRCHK	; Exit if a special character is found.
	JZ	TRFCB9	; Go pad the rest of the block w/ ' '
	INX	H	;
	CPI	'*'	;This is a Wild card match
	JNZ	TRFCB6	;
	MVI	M,'?'	;This is an 'anything match'.
	JMP	TRFCB7	;
;
TRFCB6:	MOV	M,A	;
	INX	D	;
TRFCB7:	DCR	B	;
	JNZ	TRFCB5	;
;
TRFCB8:	CALL	CHRCHK	;Check for special character
	JZ	TRFC10	;
	INX	D	;
	JMP	TRFCB8	;
;
TRFCB9:	INX	H	; Pad the rest of the file name with blanks.
	MVI	M,' '	;
	DCR	B	;
	JNZ	TRFCB9	;
;
;	Move the file extention into bytes 9 through 11 of
;	FCB. Pad excess with blancks, and fill with '?'
;	in the same manner as the filename.
;
TRFC10:	MVI	B,03H	; Move a file type of up to 3 Characters.
	CPI	'.'	;A period is the only legal special character in this case.
	JNZ	TRFC15	;
	INX	D	;
TRFC11:	CALL	CHRCHK	; Check for special characters.
	JZ	TRFC15	;
	INX	H	;
	CPI	'*'	;Wild card match- Pad the 3 bytes with ???
	JNZ	TRFC12	;
	MVI	M,'?'	;
	JMP	TRFC13	;
;
TRFC12:	MOV	M,A	;Put the character into FCB
	INX	D	;Advance FCB pointer
TRFC13:	DCR	B	;Decrement character counter
	JNZ	TRFC11	;Loop until counter is zero
TRFC14:	CALL	CHRCHK	;Step buffer until special character,
	JZ	TRFC16	;     or null is found.
	INX	D	;
	JMP	TRFC14	;
;
TRFC15:	INX	H	;Pad the rest of the extent with ' '
	MVI	M,' '	;
	DCR	B	;
	JNZ	TRFC15	;
;
TRFC16:	MVI	B,03H	;Zero out bytes 12 through 14
TRFC17:	INX	H	;
	MVI	M,00H	;
	DCR	B	;
	JNZ	TRFC17	;
;
	XCHG		;
	SHLD	BPTR1	;Save the input buffer pointer
	POP	H	;(HL) = FCB
	LXI	B,11	;Set counter
TRFC18:	INX	H	;Count number of '?' in filename.ext
	MOV	A,M	;
	CPI	'?'	;
	JNZ	TRFC19	;Skip if not'?'
	INR	B	;
TRFC19:	DCR	C	;
	JNZ	TRFC18	;
	MOV	A,B	;Move '?' count into (A)
	ORA	A	;Set flags to indicate ambigous filename
	RET		;
;
;	COMMAND NAME LIST
;
CMNDL:	DB	'DIR '	;Read directory
	DB	'ERA '	;Erase file
	DB	'TYPE'	;Output named file to console
	DB	'SAVE'	;Save named file on disk
	DB	'REN '	;Rename file
	DB	'USER'	;Set user number
;
;	SERIAL NUMBERS
;
SERNO:	DB	SNH	;
	DB	VER*10+REL	;2.2 IS 16H
	DW	REV	;
	DB	SNL/256	;
	DB	SNL MOD 256	;
;
;	COMMAND SEARCH
;
;	Try to match command name starting at FCB + 1
;	with those in the intrinsic command list.
;	Exit with command number (0 to 5) in (A) if a
;	match has been made, else exit with a 6 in (A)
;	signifying that this may be a transient command.
;
CSRCH:	LXI	H,CMNDL	; Point to start of command list.
	MVI	C,00H	; Zero out command counter.
CSRCH1:	MOV	A,C	; Check counter for maximum number of tries.
	CPI	6	;(There are 6 intrinsic commands + transients)
	RNC		; Return is no match in six tries. It is a transient command.
	LXI	D,FCB+1	; Point to start of command to be matched.
	MVI	B,04H	; Maximum number of characters in command name.
CSRCH2:	LDAX	D	;
	CMP	M	;
	JNZ	CSRCH3	; No match- exit loop.
	INX	D	;
	INX	H	;
	DCR	B	;
	JNZ	CSRCH2	; Back for another match.
	LDAX	D	; Found the command, now check for a separating space.
	CPI	' '	;
	JNZ	CSRCH4	; No space, try for something else.
	MOV	A,C	; Put command count in accumulator.
	RET		; Exit routine with command number.
;
CSRCH3:	INX	H	; Step forwards to that start of the next command name.
	DCR	B	;
	JNZ	CSRCH3	;
CSRCH4:	INR	C	; Bump command counter by one.
	JMP	CSRCH1	; Back for another try.
;
;	******************************
;	MAIN OPERATING ROUTINE FOR CCP
;	******************************
;
;	Entry point number 1
;	Input buffer counter is zeroed out so no imbedded
;	command can be executed on initial boot up.
;
CCP0:	XRA	A	;
	STA	INBLEN	;
;
;
;	Entry point number 2
;	Entry a this point allows commands inbedded in
;	input buffer to be automatically executed
;	on initial boot up.
;
;	On entry (C) has user number in the high nibble
;	and the disk drive in the lower nibble
;
CCP1:	LXI	SP,STACK	;Set up loacal stack
	PUSH	B	;Save entry parameter
	MOV	A,C	;
	RAR		;Move upper 4 bits down
	RAR		;
	RAR		;
	RAR		;
	ANI	0FH	;Extract user number from input parameter
	MOV	E,A	;
	CALL	SETUSR	;Put user number in its place
	CALL	RESET	;Reset disk system
	STA	SUBFL	;SUBMIT FILE FLAG
	POP	B	;Get back entry parameter
	MOV	A,C	;
	ANI	0FH	;Extract disk drive number from input parameter
	STA	CURDSK	;Set to correct disk drive
	CALL	SELDSK	;
	LDA	INBLEN	;
	ORA	A	;Check to see if there is anything in the input buffer
	JNZ	CCP2	;There is, so don't bother with input.
;
;	RE-ENTRY POINT FOR NEXT COMMAND
;
NXTCMD:	LXI	SP,STACK	; Reset stack, and put out a prompt so
				; that you know what disk you are operating on.
	CALL	PCRLF	;
	CALL	INTDSK	;Get drive number
	ADI	'A'	;Add  ASCII bias
	CALL	OUTPUT	;
	MVI	A,'>'	;Prompt character
	CALL	OUTPUT	;
	CALL	CMNDIN	; Input the next command line from the console or submit file.
CCP2:	LXI	D,DDMA	;Set to the default DMA (0080H)
	CALL	STDMA1	;
	CALL	INTDSK	;Check disk drive
	STA	CURDSK	;
	CALL	TRFCB	;Put command name in FCB
	CNZ	WHAT	;Ambigous filename.ext No good
	LDA	TRDISK	;
	ORA	A	;
	JNZ	TRANS	;Transient command
	CALL	CSRCH	;Find command in command list
	LXI	H,CMNDT	;Point to command vector table
	MOV	E,A	;Put command number in (DE)
	MVI	D,00H	;
	DAD	D	;
	DAD	D	;(HL) <-- CMNDT + 2 * Command number
	MOV	A,M	;Move command vector into (HL)
	INX	H	;
	MOV	H,M	;
	MOV	L,A	;
	PCHL		;Go forth and execute the command.
;
;	COMMAND VECTOR TABLE
;
CMNDT:	DW	DIR	;Display directory
	DW	ERA	;Erase file
	DW	TYPE	;Type file to console
	DW	SAVE	;Save file on disk
	DW	REN	;Rename file
	DW	USER	;Set user number
	DW	TRANS	;Load and execute transient command
;
;	OK- You were warned about the serial numbers, but
;	you went ahead anyway. Now you must pay the penalty
;
FATAL:	LXI	H,76F3H	;STUFF A DI  & HLT
	SHLD	ORIGIN	;AT THE HEAD OF CCP
	LXI	H,ORIGIN	;
	PCHL		;HANG UP THERE UNTIL RESET
;
;	FILE READ ERROR
;
RDERR:	LXI	B,MSG1	;Load pointer to message
	JMP	CRMSG	;Display message & return
;
MSG1:	DB	'READ ERROR',0
;
;	FILE NOT FOUND ERROR
;
NFERR:	LXI	B,MSG2	;Load pointer to message
	JMP	CRMSG	;Display message & return
;
MSG2:	DB	'NO FILE',0
;
;	DECIMAL TO BINARY CONVERSION
;	Used by SAVE and USER
;
;	NOTE:
;
;	There is some inefficient code in this subroutine
;	TRFCB will move the numbers into FCB and pad the
;	rest of the block with ' '. The number can be 3
;	digits long at most, so that the elaborate stepping
;	past blanks, etc is not needed. Code that can be
;	revised is marked by '*'
;
DECIML:	CALL	TRFCB	;Move numbers into FCB
	LDA	TRDISK	;
	ORA	A	;
	JNZ	WHAT	;
	LXI	H,FCB+1	;
	LXI	B,11	;8 NUMBER FILE NAME & 3 CHAR EXT
DEC1:	MOV	A,M	;
	CPI	' '	;
	JZ	DEC2	;
	INX	H	;
	SUI	'0'	;REMOVE ASCII BIAS
	CPI	10	;
	JNC	WHAT	;
	MOV	D,A	;
	MOV	A,B	;*
	ANI	0E0H	;*
	JNZ	WHAT	;*
	MOV	A,B	;*
	RLC		;MULTIPLY BY 10
	RLC		;
	RLC		;
	ADD	B	;
	JC	WHAT	;Overflow
	ADD	B	;
	JC	WHAT	;Overflow
	ADD	D	;
	JC	WHAT	;Overflow
	MOV	B,A	;
	DCR	C	;*
	JNZ	DEC1	;* Should be JMP DEC1
	RET		;*
;
DEC2:	MOV	A,M	;*Step over blanks to end of block
	CPI	' '	;*
	JNZ	WHAT	;*
	INX	H	;*
	DCR	C	;*
	JNZ	DEC2	;*
	MOV	A,B	;Return with binary value in (A)
	RET		;
;
;	BLOCK MOVE
;	Source      :: ((HL))
;	Destination :: ((DE))
;	Count       ::  (B)
;
MOVE3:	MVI	B,03H	;3 byte move
BLKMOV:	MOV	A,M	;Source
	STAX	D	;Destination
	INX	H	;
	INX	D	;
	DCR	B	;Counter
	JNZ	BLKMOV	;
	RET		;
;
;	SET DIRECTORY POINTER
;	Point to (DDMA) + (C) + (A)
;	Return with character in (A)
;
;	On entry (C) contains directory entry offset
;	i.e. 00H, 20H, 40H, or 60H.
;	Accumulator (A) contains number of the byte
;	within the directory that the pointer is to
;	be set to.
;
DIRPTR:	LXI	H,DDMA	;Point to start of directory sector
	ADD	C	;Add byte number to directory offset
	CALL	ADDAH	;  then add the result to (HL)
	MOV	A,M	;  and get the byte pointed to.
	RET		;
;
;	SET TO TRANSIENT DISK
;	Set the disk specified by (TRDISK) for
;	reading or writing. If (TRDISK) = (CURDISK), you
;	are already on the right disk, so no change is needed
;
SETTRD:	XRA	A	;
	STA	FCB	;Set first byte of FCB to 0
	LDA	TRDISK	;
	ORA	A	;Check to see if transient disk= 0
	RZ		;OK- no change needed
	DCR	A	;
	LXI	H,CURDSK	;Now check current disk
	CMP	M	;
	RZ		;OK- no change needed
	JMP	SELDSK	;Disk different, so go get right one
;
;	SET CURRENT DISK
;	Restore the current logged-in disk as the read/write
;	disk. If already on the proper disk, no action is required
;
SETCUR:	LDA	TRDISK	;
	ORA	A	;
	RZ		;OK- On log-in disk, no change
	DCR	A	;
	LXI	H,CURDSK	;
	CMP	M	;
	RZ		;OK
	LDA	CURDSK	;On different disk.
	;(NOTE: Change  this command to MOV  A,M and save 2 bytes)
	JMP	SELDSK	;  so go make change
;
;	START OF INTRINSIC COMMANDS
;
;	*******************************
;	DIR SEARCHES FILE DIRECTORY FOR
;	FILES BY FILE NAME OR FILE TYPE
;	     ? MATCHES ANY LETTER
;	* MATCHES THE WHOLE FILENAME OR
;	          FILETYPE
;	*******************************
;
;	NOTE ON SYSTEM FILES:
;	'System' type files are rendered invisible to the
;	DIR command because the MSB of the second byte of
;	the file ext is set. A minor change in the following
;	code could make these files listable in the Directory
;
DIR:	CALL	TRFCB	; TRANSFER THE COMMAND LINE INTO 005CH.
	CALL	SETTRD	; SET TO TRANSIENT DISK
	LXI	H,FCB+1	; POINT TO START OF FILE NAME
	MOV	A,M	; CHECK FOR A BLANK
	CPI	20H	;' '
	JNZ	DIR1	; NOT BLANK, GO FIND WHAT IS WANTED.
;
	MVI	B,11	; BLANK ::= DISPLAY ENTIRE DIRECTORY
DIR0:	MVI	M,3FH	; FILL ENTIRE FILENAME/TYPE ARE WITH WILDCARD [?]'?'
	INX	H	;
	DCR	B	;
	JNZ	DIR0	;
;
DIR1:	MVI	E,00H	; SEARCH FOR FILE.
	PUSH	D	;
	CALL	SRCHF1	;
	CZ	NFERR	; <NOT FOUND> ERROR
DIR2:	JZ	DIR10	;
	LDA	RETVAL	;Get directory entry number
	RRC		;Convert to directory block pointer
	RRC		;by multiplying by 32 and masking off
	RRC		;the excess
	ANI	60H	;
	MOV	C,A	;Stash block pointer
	MVI	A,10	;
	CALL	DIRPTR	;Get character @ DDMA + block pointer + 10 = Second char of ext
	RAL		;Check for MSB set :: SYSTEM file
	JC	DIR9	;Skip- System files are not listed by DIR
	POP	D	;
	MOV	A,E	;
	INR	E	;
	PUSH	D	;
	ANI	03H	;Check for every 4th directory item
	PUSH	PSW	;
	JNZ	DIR3	;Not the 4th
	CALL	PCRLF	; 4th, so start new line and mark
	PUSH	B	; with disk drive letter
	CALL	INTDSK	;Get disk number
	POP	B	;
	ADI	'A'	;Print the disk number & colon at the
	CALL	PCHAR	;start of each directory print line
	MVI	A,':'	;
	CALL	PCHAR	;
	JMP	DIR4	;
;
DIR3:	CALL	SPACE	;Print a space/colon/space between
	MVI	A,':'	;directory items
	CALL	PCHAR	;
DIR4:	CALL	SPACE	;
	MVI	B,01H	;
;
;	The code in this area is somewhat tangled
;	Space could be saved by redoing some of the
;	ways that pointers are set up. Currently the
;	pointer to the directory entry is recomputed
;	for each byte. Why not just load (HL) once
;	and increment?
;
DIR5:	MOV	A,B	;Print the filename.ext to the console
	CALL	DIRPTR	;Point to byte and reurn w/ byte in (A)
	ANI	7FH	;
	CPI	' '	;
	JNZ	DIR7	;
	POP	PSW	;
	PUSH	PSW	;
	CPI	03H	;Chack for file ext end
	JNZ	DIR6	;
	MVI	A,09H	;Check for file name end
	CALL	DIRPTR	;
	ANI	7FH	;
	CPI	' '	;Check for no file ext
	JZ	DIR8	;
DIR6:	MVI	A,' '	;Separator between filename & ext
DIR7:	CALL	PCHAR	;
	INR	B	;
	MOV	A,B	;
	CPI	12	;File ext end +1
	JNC	DIR8	;
	CPI	9	;File name end +1
	JNZ	DIR5	;
	CALL	SPACE	;
	JMP	DIR5	;
;
DIR8:	POP	PSW	;
DIR9:	CALL	KSTAT	;CHECK KEY BOARD, ANY KEY BREAKS
	JNZ	DIR10	;Exit on break
	CALL	SRCHNX	;Look for another directory item
	JMP	DIR2	;Loop back for more
;
DIR10:	POP	D	;
	JMP	COMEND	;EXIT
;
;	******************************************************
;	ERASE FILES FROM DISK
;
;	'*' and '?' can be used the same as in 'DIR'
;	Does not actually wipe out information from the disk,
;	but merely has the first byte of the file control block
;	set to 0E5H. This routine in CCP merely sets up the
;	file names to be erased; the real work is done by BDOS
;	******************************************************
;
ERA:	CALL	TRFCB	;Set up the file control block
	CPI	11	;If 11 '?' are in the FCB then you are
	JNZ	ERA1	;asking to erase the whole disk. *.*
	LXI	B,MSG3	;Ask for verification before proceeding
	CALL	CRMSG	;
	CALL	CMNDIN	;Get keyboard entry
	LXI	H,INBLEN	;check for return without entry
	DCR	M	;
	JNZ	NXTCMD	;Abort on empty line
	INX	H	;
	MOV	A,M	;
	CPI	'Y'	;Yes, proceed with erasing everything
	JNZ	NXTCMD	;Chickened out
	INX	H	;
	SHLD	BPTR1	;
ERA1:	CALL	SETTRD	;set the transient disk
	LXI	D,FCB	;Point to the file control block
	CALL	DELETF	;Call the routine that calls th e BDOS erase
	INR	A	;Check the return parameter
	CZ	NFERR	;Warn if item not found
	JMP	COMEND	;EXIT
;
MSG3:	DB	'ALL (Y/N)?',0
;
;	***********************************
;	OUTPUT NAMED FILE TO THE CONSOLE
;	File name.ext must be unconditional
;	***********************************
;
TYPE:	CALL	TRFCB	;Set up file name in FCB
	JNZ	WHAT	;Badly formed filename: ambigous
	CALL	SETTRD	;Set the disk
	CALL	OPENF1	;Open the file for reading
	JZ	TYPE4	;Error on opening
	CALL	PCRLF	;
	LXI	H,TYPCTR	;Initiate counter
	MVI	M,0FFH	;
TYPE1:	LXI	H,TYPCTR	;
	MOV	A,M	;Get the buffer counter
	CPI	80H	;Check for end of buffer
	JC	TYPE2	;Not at end, get character from buffer
;
;	At end of buffer- Read from disk
;
	PUSH	H	;Read a sector from disk to the buffer
	CALL	READ1	;
	POP	H	;
	JNZ	TYPE3	;RETURN VALUE <> 0. End of file or bad read
	XRA	A	;
	MOV	M,A	;Zero (TYPCTR)
TYPE2:	INR	M	;
	LXI	H,DDMA	;
	CALL	ADDAH	;Point to character
	MOV	A,M	;Get the character
	CPI	1AH	;Check for end of file
	JZ	COMEND	;EXIT
	CALL	OUTPUT	;Not EOF, output the byte to the console
	CALL	KSTAT	;Check for keyboard break
	JNZ	COMEND	;EXIT ON ANY KEY
	JMP	TYPE1	;Back for the next letter
;
;	(A) = 1	:: End of file
;	(A) = 2	:: Read error
;
TYPE3:	DCR	A	;
	JZ	COMEND	;EXIT AT END OF FILE
	CALL	RDERR	;
TYPE4:	CALL	SETCUR	;This piece of code can be used to
	JMP	WHAT	;replace REN4 and TRANS8
;
;	**********************************
;	SAVE CREATES DISK FILE FROM MEMORY
;	STARTING AT 0100H.  256 BYTE PAGES
;	  FILENAME MUST BE UNCONDITIONAL
;	IF A FILE OF THE SAME NAME & TYPE
;	  ALREADY EXISTS, IT IS ERASED.
;	**********************************
;
SAVE:	CALL	DECIML	;GET THE NUMBER OF PAGES TO BE SAVED
	PUSH	PSW	;
	CALL	TRFCB	;SET UP THE FILE NAME
	JNZ	WHAT	;Cannot be ambigous file
	CALL	SETTRD	;SET UP DISK
	LXI	D,FCB	;
	PUSH	D	;
	CALL	DELETF	;DELETE OLD FILE OF SAME NAME
	POP	D	;
	CALL	CREATE	;CREATE A NEW FILE IN DIRECTORY
	JZ	SAVE3	;
	XRA	A	;
	STA	FCB+32	;ZERO OUT SECTOR COUNTER
	POP	PSW	;
	MOV	L,A	;
	MVI	H,00H	;CHECK PAGE COUNTER
	DAD	H	;
	LXI	D,TPA	;
SAVE1:	MOV	A,H	;CHECK PAGE COUNTER
	ORA	L	;
	JZ	SAVE2	;EXIT, LAST PAGE HAS BEEN WRITTEN
	DCX	H	;
	PUSH	H	;SAVE COUNTER
	LXI	H,SECLEN	;ADVANCE DMA LOCATION
	DAD	D	;BY ONE SECTOR
	PUSH	H	;
	CALL	STDMA1	;SET THE DMA ADDRESS
	LXI	D,FCB	;
	CALL	WRITEF	;WRITE THE SECTOR TO DISK
	POP	D	;
	POP	H	;
	JNZ	SAVE3	;ERROR CONDITION
	JMP	SAVE1	;LOOP BACK TO WRITE ANOTHER SECTOR
;
SAVE2:	LXI	D,FCB	;CLOSE THE FILE TO MAKE IT OFFICIAL
	CALL	CLOSEF	;
	INR	A	;CHECK FOR GOOD CLOSING
	JNZ	SAVE4	;OK
SAVE3:	LXI	B,MSG4	;<NO SPACE> ERROR
	CALL	CRMSG	;
SAVE4:	CALL	SETDMA	;
	JMP	COMEND	;EXIT
;
MSG4:	DB	'NO SPACE',0
;
;	*******************************************
;	RENAME A FILE		      THE FORMAT IS
;	<NEW FILENAME>.<TYPE>=<OLD FILENAME>.<TYPE>
;	    A '_' may be substituted for the '='
;	*******************************************
;
REN:	CALL	TRFCB	;Put new filename into FCB
	JNZ	WHAT	;Cannot be ambigous filename
	LDA	TRDISK	;Get the disk number
	PUSH	PSW	;
	CALL	SETTRD	;Log into the correct disk
	CALL	SRCHF1	;Check to see if such a name exists
	JNZ	FEERR	;ERROR- File name already used
	LXI	H,FCB	;Move new filename to upper half of FCB
	LXI	D,FCB+16	;
	MVI	B,10H	;
	CALL	BLKMOV	;
	LHLD	BPTR1	;Back to input buffer
	XCHG		;
	CALL	STEP	;
	CPI	'='	;Check for proper separator
	JZ	REN1	;OK
	CPI	'_'	;
	JNZ	REN4	;NO GOOD
REN1:	XCHG		;
	INX	H	;Step over separartor
	SHLD	BPTR1	;Store pointer for TRFCB to use
	CALL	TRFCB	;Move name.type of Old file into place
	JNZ	REN4	;Error- cannot be ambigous
	POP	PSW	;Get back disk number
	MOV	B,A	;
	LXI	H,TRDISK	;
	MOV	A,M	;
	ORA	A	;
	JZ	REN2	;OK- current disk=transient disk
	CMP	B	;Check disk number
	MOV	M,B	;Save back into TRDISK
	JNZ	REN4	;Error
REN2:	MOV	M,B	;
	XRA	A	;
	STA	FCB	;Zero in FCB :: Logged in disk
	CALL	SRCHF1	;Does old file exist?
	JZ	REN3	;NO- <NO FILE> Error
	LXI	D,FCB	;OK- Rename it
	CALL	RENAME	;	via call to BDOS
	JMP	COMEND	;EXIT
;
REN3:	CALL	NFERR	;<NO FILE> Error
	JMP	COMEND	;EXIT
;
;	This piece of code can be deleted, and jumps
;	to it rerouted to TYPE4
;
REN4:	CALL	SETCUR	;Return to current disk
	JMP	WHAT	;??????????
;
;	FILE EXISTS ERROR
;
FEERR:	LXI	B,MSG6	;Load error message pointer
	CALL	CRMSG	;Display maessage
	JMP	COMEND	;EXIT
;
;	NOTE:
;	If these error messages ended with '$' instead of
;	a null, then  the BDOS string output command could
;	be used instead of the PMSG subroutine.
;
MSG6:	DB	'FILE EXISTS',0
;
;	************************************
;	SET THE USER NUMBER FROM THE CONSOLE
;	  Nobody uses this in one-user CP/M
;	************************************
;
USER:	CALL	DECIML	;Convert number to binary
	CPI	10H	;Must be 0 to 15
	JNC	WHAT	;Out of range
	MOV	E,A	;Set in place for BDOS call
	LDA	FCB+1	;Check for blank 'filename'
	CPI	' '	;
	JZ	WHAT	;Error
	CALL	SETUSR	;Set via BDOS
	JMP	CMEND1	;EXIT
;
;	*************************************************
;	TRANS LOADS A PROGRAM INTO THE TPA IF IT IS NOT A
;	COMMAND NAME,  AND A PROPER  <FILENAME>.COM  FILE
;		  EXISTS ON THE TRANSIENT DISK.
;	*************************************************
;
TRANS:	CALL	CMPSER	; CHECK FOR A KOSHER SERIAL NUMBER. BOMB OUT IF NO GOOD.
	LDA	FCB+1	; SPACE ::= NO FILE NAME PRESENT.
	CPI	' '	;
	JNZ	TRANS1	;OK- Filename present
	LDA	TRDISK	;NG- Just clean things up and leave
	ORA	A	;
	JZ	CMEND1	;EXIT IF ON THE LOGIN DISK
	DCR	A	;
	STA	CURDSK	;OTHERWISE LOG BACK TO THE LOGIN DISK
	CALL	LOGCUR	;
	CALL	SELDSK	;
	JMP	CMEND1	;AND GO BACK FOR ANOTHER COMMAND
;
TRANS1:	LXI	D,FCB+9	; CHECK THE FILE TYPE.
	LDAX	D	;
	CPI	' '	;
	JNZ	WHAT	; YOU'RE NOT SUPPOSED TO HAVE A FILE TYPE W/ A TRANSIENT.
	PUSH	D	;
	CALL	SETTRD	; SET TO TRANSIENT DRIVE.
	POP	D	;
	LXI	H,COM	; MOVE FILE TYPE "COM" INTO FCB.
	CALL	MOVE3	;
	CALL	OPENF1	; OPEN FILE FOR READING.
	JZ	TRANS8	; ERROR CONDITION, FILE NOT FOUND.
	LXI	H,TPA	; STARTING POINT FOR PROGRAM LOADING.
	;
TRANS2:	PUSH	H	; MOVE PROGRAM INTO TPA SECTOR BY SECTOR.
	XCHG		;
	CALL	STDMA1	; POINT TO LOADING LOCATION.
	LXI	D,FCB	;
	CALL	READF	; READ 1 SECTOR INTO MEMORY.
	JNZ	TRANS3	; ZFLAG RESET ::= GOOD READ, GO AROUND FOR MORE.
	POP	H	;
	LXI	D,SECLEN	;
	DAD	D	; ADVANCE POINTER FOR NEXT SECTOR.
	LXI	D,ORIGIN	; CHECK FOR PROGRAM OVERLAPPING CCP AREA.
	MOV	A,L	;
	SUB	E	;
	MOV	A,H	;
	SBB	D	;
	JNC	LDERR	; ERROR CONDITION, PROGRAM TOO BIG FOR MEMORY.
	JMP	TRANS2	; BACK FOR NEXT SECTOR.
;
TRANS3:	POP	H	; CLEAR STACK.
	DCR	A	; 1 ::= END OF FILE (GOOD) OR 2 ::= READ ERROR (BAD).
	JNZ	LDERR	; READ ERROR.
	CALL	SETCUR	; SET BACK TO CURRENT DRIVE.
	CALL	TRFCB	; MOVE ANY FURTHER FCB'S AT 005CH AND 006CH.
	LXI	H,TRDISK	;
	PUSH	H	;
	MOV	A,M	;Put transient disk number into
	STA	FCB	;  first byte of file control block.
	MVI	A,16	;Set offset for TRFCB to upper half of FCB
	CALL	TRFCB1	;Move seconf file name into FCB + 16
	POP	H	;
	MOV	A,M	;Get transient disk number of second FN
	STA	FCB+16	;  and insert it into FCB + 16
	XRA	A	;Zero out sector counter
	STA	FCB+32	;
	LXI	D,DFCB	;Move filenames to default FCB
	LXI	H,FCB	;
	MVI	B,33	;File control block & sector counter
	CALL	BLKMOV	;
;
	LXI	H,BUFFER	;Start at the head of buffer
TRANS4:	MOV	A,M	;Step until blank or null found
	ORA	A	; i.e. step over transient name
	JZ	TRANS5	;
	CPI	' '	;
	JZ	TRANS5	;
	INX	H	;
	JMP	TRANS4	;Loop
;
TRANS5:	MVI	B,00H	;Command line byte counter
	LXI	D,DDMA+1	;
TRANS6:	MOV	A,M	;Move command line into default buffer
	STAX	D	;
	ORA	A	;Exit on null
	JZ	TRANS7	;
	INR	B	;Bump counter
	INX	H	;
	INX	D	;
	JMP	TRANS6	;
;
TRANS7:	MOV	A,B	;Put buffer counter at start
	STA	DDMA	; of default buffer
	CALL	PCRLF	;
	CALL	SETDMA	;Set DMA to default buffer
	CALL	SETLOG	; SET LOG-IN BYTE W/ CURRENT DRIVE & USER NUMBER
	CALL	TPA	; GO OUT AND RUN THE PROGRAM.
	LXI	SP,STACK	; RESTORE STACK ON RETURN.
	CALL	LOGCUR	;Log back to the current disk
	CALL	SELDSK	;
	JMP	NXTCMD	; READY FOR ANOTHER ASSIGNMENT.
;
;	Redundant code:
;			This can be deleted, and jumps to this
;			point changed to TYPE4
;
TRANS8:	CALL	SETCUR	;Error exit
	JMP	WHAT	;
;
;	LOAD ERROR
;
LDERR:	LXI	B,MSG7	;Load the error pointer
	CALL	CRMSG	;Display the message
	JMP	COMEND	;EXIT
;
MSG7:	DB	'BAD LOAD',0
;
COM:	DB	'COM'	; FILE TYPE FOR TRANSIENT COMMANDS.
;
;	COMMAND END
;		CLEAN-UP AND EXIT POINT FOR ALL COMMANDS
;		EXCEPT TRANSIENT COMMANDS.
;
COMEND:	CALL	SETCUR	;PRIMARY EXIT POINT
CMEND1:	CALL	TRFCB	;SECONDARY EXIT POINT
	LDA	FCB+1	; CHECK FOR FURTHER COMMANDS.
	SUI	' '	;
	LXI	H,TRDISK	;
	ORA	M	;
	JNZ	WHAT	;
	JMP	NXTCMD	; BACK TO THE  RATRACE.
;
;	END OF THE PROGRAM AREA
;
;	START OF PARAMETER STORAGE AREA
;
	DS	16	;STACK AREA
STACK:	EQU	$	;CCP STACK
;
SUBFL:	DS	1	; SUBMIT FLAG. FLAG SET WHEN COMMANDS COME FROM $$$.SUB FILE.
SUBFCB:	DB	0,'$$$     SUB',0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
FCB:	DS	33	;FILE CONTROL BLOCK FOR CCP READ/WRITE
RETVAL:	DS	1	; VALUE RETURNED IN (A) FROM CALLS TO BDOS.
CURDSK:	DS	1	; CURRENT LOGGED IN DISK.
TRDISK:	DS	1	; CURRENT TRANSIENT DISK.
TYPCTR:	DS	1	; INPUT BUFFER COUNTER USED BY 'TYPE' TO KEEP TRACK
			; OF INPUT DISK BUFFER.
;
FINISH: END	ORIGIN	;END OF SOURCE CODE
