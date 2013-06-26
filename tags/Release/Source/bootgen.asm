;___BOOTGEN___________________________________________________________________________________________________________
;
;  COPY THE SYSTEM TO THE BOOT SECTORS OF AN IDE HDD
;
;  CREATED BY : 	DAN WERNER 09 12.2009
;
;
;
;
;__CONSTANTS_________________________________________________________________________________________________________________________ 
;	
CR:		 .EQU	0DH		; ASCII CARRIAGE RETURN CHARACTER
LF:		 .EQU	0AH		; ASCII LINE FEED CHARACTER
ESC:		 .EQU	1BH		; ASCII ESCAPE CHARACTER
BS:		 .EQU	08H		; ASCII BACKSPACE CHARACTER

;
;
;
;__MAIN_PROGRAM_____________________________________________________________________________________________________________________ 
;
	 .ORG	00100h			; FOR DEBUG IN CP/M (AS .COM)
	
	
	LD	HL,(0001H)		; GET WBOOT ADDRESS
	LD	BC,1603H		; GET CP/M TOP
	SBC	HL,BC			;
	LD	(CPMSTART),HL		; SET IT
	DEC	HL			;
	LD	SP,HL			; SETUP STACK
	
	
; PARSE COMMAND LINE
	LD	HL,0081H		; SET INDEX POINTER
	LD	B,(0080H)		; NUMBER OF BYTES
PARSECMD:
	LD	A,(HL)			; GET DRIVE LETTER ON COMMAND LINE
	INC	HL
	CP	20H			; IS SPACE?
	JP	NZ,PARSEGOT		; JUMP ON NON-BLANK
	DJNZ	PARSECMD		; LOOP
PARSEERR:	
	LD	DE,MSG_VALID		;
	LD	C,09H			; CP/M WRITE START STRING TO CONSOLE CALL
	CALL	0005H
	JP	EXIT			; EXIT
PARSEGOT:
	SUB	'A'			; TURN IT INTO A NUMERIC	
	JP	C,PARSEERR		;
	CP	16			; VALID CP/M DRIVE?
	JP	P,PARSEERR		;
	LD	(DEVICENUMBER),A	; DEVICE ID
					; GET NUMBER OF SECTORS PER TRACK
	LD	L,A			; L=DISK NUMBER 0,1,2,3,4
	LD	H,0			; HIGH ORDER ZERO
	ADD	HL,HL			; *2
	ADD	HL,HL			; *4
	ADD	HL,HL			; *8
	ADD	HL,HL			; *16 (SIZE OF EACH HEADER)
	PUSH	HL			;
	POP	DE
	LD	HL,(0001H)		;
	LD	BC,0058			;
	ADD	HL,BC			;
	ADD	HL,DE			; HL= DPBASE(DISKNO*16)
	EX	DE,HL			;
	LD	A,(DE)			;
	LD	L,A			;
	INC	DE			;
	LD	A,(DE)			;
	LD	H,A			;
	EX	DE,HL			;
	LD	A,(DE)			;
	LD	(SECTRACK),A		;
	INC	DE			;
	LD	A,(DE)			;
	LD	(SECTRACK+1),A		;
	
	LD	DE,DRIVE_MSG		;
	LD	C,09H			; CP/M WRITE START STRING TO CONSOLE CALL
	CALL	0005H
	LD	A,(DEVICENUMBER)	;					
	ADD	A,'A'			;
	CALL	COUT			;
	LD	A,':'			;
	CALL	COUT			;
	CALL	CRLF			;

	
	LD	DE,BASE_MSG		;
	LD	C,09H			; CP/M WRITE START STRING TO CONSOLE CALL
	CALL	0005H
	LD	HL,(CPMSTART)		;
	CALL	PHL			;
	LD	DE,END_MSG		;
	LD	C,09H			; CP/M WRITE START STRING TO CONSOLE CALL
	CALL	0005H
	LD	HL,(CPMEND)		;
	CALL	PHL			;
	CALL	CRLF			;
	
	LD	DE,SECTOR_MSG		;
	LD	C,09H			; CP/M WRITE START STRING TO CONSOLE CALL
	CALL	0005H
	LD	HL,(SECTRACK)		;
	CALL	PHL			;
	CALL	CRLF			;
 				

; RUN WITH GOOD OUTPUT
		
	LD	A,(DEVICENUMBER)	; SET DEVICE NUMBER
	LD	C,A
	CALL	SELDSK			; SELECT DISK
	
	LD	HL,000CH		; SET INITIAL SECTOR
	LD	(CURSECTOR),HL

	LD	HL,0000H		; SET INITIAL TRACK
	LD	(CURTRACK),HL		;
	
	LD	HL,(CPMSTART)		; SET BEGINNING OF CPM
	LD	(CURADDRESS),HL		;
	
	LD	BC,(DMAAD)		; SETUP THE DMA AREA
	CALL	SETDMA			;

LOOP:
	LD	BC,(CURSECTOR)		; SET SECTOR
	CALL	SETSEC			;
	LD	BC,(CURTRACK)		;
	CALL	SETTRK			;
	CALL	COPYTODMA		; COPY BYTES TO DMA
	CALL	WRITE			; WRITE SECTOR

	LD	HL,(CURADDRESS)		; IF IX>CPMEND, EXIT PROGRAM
	LD	BC,(CPMEND)		;
	LD	A,H			;
	CP	B			;
	JP	NZ,CONTINUE		;
	LD	A,L			;
	CP	C			;
	JP	M,ENDLOOP		; 
CONTINUE:
	LD	HL,(CURSECTOR)		; GET NEXT TRACK & SECTOR
	INC	HL			;
	LD	(CURSECTOR),HL		;
	LD	BC,(SECTRACK)		;
	LD	A,H			;
	CP	B			;
	JP	NZ,LOOP			;
	LD	A,L			;
	CP	C			;
	JP	NZ,LOOP			;
	
	LD	HL,(CURTRACK)		;
	INC	HL			;
	LD	(CURTRACK),HL		;
	LD	HL,0000H		;
	LD	(CURSECTOR),HL		;
	JP	LOOP			;

ENDLOOP:	
; WRITE CP/M BOOT START AND END ADDRESSES IN LAST TWO WORDS OF MEDIA INFO SECTOR	
	LD	BC,000BH		; SET SECTOR
	CALL	SETSEC			;
	LD	BC,0000H		;
	CALL	SETTRK			;
	CALL	READ			;
	LD	HL,(DMAAD)		; SET ADDRESS IN BUFFER TO LAST TWO WORDS
	LD	BC,122			; 
	ADD	HL,BC			;
	LD	A,(CPMSTART)		;
	LD	(HL),A			;
	LD	A,(CPMSTART+1)		;
	INC	HL
	LD	(HL),A			;
	LD	A,(CPMEND)		;
	INC	HL
	LD	(HL),A			;
	LD	A,(CPMEND+1)		;
	INC	HL
	LD	(HL),A			;
	LD	A,(0001H)		;
	DEC	A			;
	DEC	A			;
	DEC	A			;
	INC	HL
	LD	(HL),A			;
	LD	A,(0002H)		;
	INC	HL
	LD	(HL),A			;	
	CALL	WRITE			; WRITE SECTOR

EXIT:	
	
	LD	DE,MSG_END		;
	LD	C,09H			; CP/M WRITE END STRING TO CONSOLE CALL
	CALL	0005H			;
					;
	LD	C,00H			; CP/M SYSTEM RESET CALL
	CALL	0005H			; RETURN TO PROMPT

	
	
		
	
;___COPYTODMA_____________________________________________________________________________________
;
;	COPY CURRENT ADDRESS BLOCK TO DMA
;_________________________________________________________________________________________________			
COPYTODMA:
	LD	HL,(DMAAD)		; LOAD HL WITH DMA ADDRESS
	LD	E,L			;
	LD	D,H			; GET IT INTO DE
	LD	HL,(CURADDRESS)		; GET RAM ADDRESS TO COPY
	LD	BC,128			; BC IS COUNTER FOR FIXED SIZE TRANSFER (128 BYTES)
	LDIR				; TRANSFER
	LD	HL,(CURADDRESS)		; INCREMENT ADDRESS POINTER BY COPY SIZE
	LD	BC,128			; 
	ADD	HL,BC			;
	LD	(CURADDRESS),HL		;
	RET


	
	

		
		
;__HXOUT_________________________________________________________________________________________________________________________ 
;
;	PRINT THE ACCUMULATOR CONTENTS AS HEX DATA ON THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
HXOUT:
	PUSH	BC			; SAVE BC
	LD	B,A			;
	RLC	A			; DO HIGH NIBBLE FIRST  
	RLC	A			;
	RLC	A			;
	RLC	A			;
	AND	0FH			; ONLY THIS NOW
	ADD	A,30H			; TRY A NUMBER
	CP	3AH			; TEST IT
	JR	C,OUT1			; IF CY SET PRINT 'NUMBER'
	ADD	A,07H			; MAKE IT AN ALPHA
OUT1:
	CALL	COUT			; SCREEN IT
	LD	A,B			; NEXT NIBBLE
	AND	0FH			; JUST THIS
	ADD	A,30H			; TRY A NUMBER
	CP	3AH			; TEST IT
	JR	C,OUT2			; PRINT 'NUMBER'
	ADD	A,07H			; MAKE IT ALPHA
OUT2:
	CALL	COUT			; SCREEN IT
	POP	BC			; RESTORE BC
	RET				;


;__SPACE_________________________________________________________________________________________________________________________ 
;
;	PRINT A SPACE CHARACTER ON THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
SPACE:
	PUSH	AF			; STORE AF
	LD	A,20H			; LOAD A "SPACE"
	CALL	COUT			; SCREEN IT
	POP	AF			; RESTORE AF
	RET				; DONE

;__CRLF_________________________________________________________________________________________________________________________ 
;
;	PRINT A CR/LF
;________________________________________________________________________________________________________________________________
;
CRLF:
	PUSH	AF			; STORE AF
	LD	A,0DH			; LOAD A "SPACE"
	CALL	COUT			; SCREEN IT
	LD	A,0AH			; LOAD A "SPACE"
	CALL	COUT			; SCREEN IT
	POP	AF			; RESTORE AF
	RET				; DONE

;__COUT_________________________________________________________________________________________________________________________ 
;
;	PRINT CONTENTS OF A 
;________________________________________________________________________________________________________________________________
;
COUT:
	PUSH	BC			;
	PUSH	AF			;
	PUSH	HL			;
	PUSH	DE			;
		
	LD	(COUT_BUFFER),A		;
	LD	DE,COUT_BUFFER		;
	LD	C,09H			; CP/M WRITE START STRING TO CONSOLE CALL
	CALL	0005H
	POP	DE			;
	POP	HL			;
	POP	AF			;
	POP	BC			;
	RET				; DONE




;__PHL_________________________________________________________________________________________________________________________ 
;
;	PRINT THE HL REG ON THE SERIAL PORT
;________________________________________________________________________________________________________________________________
;
PHL:
	LD	A,H			; GET HI BYTE
	CALL	HXOUT			; DO HEX OUT ROUTINE
	LD	A,L			; GET LOW BYTE
	CALL	HXOUT			; HEX IT
	CALL	SPACE			; 
	RET				; DONE  

COUT_BUFFER:
	 .DB	00
	 .DB	"$"

BASE_MSG:	
	 .TEXT 	"CP/M IMAGE="
	 .db  	"$"
END_MSG:	
	 .TEXT	"TO "
	 .db  	"$"	
SECTOR_MSG:
	 .TEXT	"SECTORS/TRACK="
	 .db  	"$"

DRIVE_MSG:
	 .TEXT	"DRIVE="
	 .db  	"$"
	
	
;__CBIOS_________________________________________________________________________________________________________________________ 
;
;	CBIOS JUMP TABLE
;________________________________________________________________________________________________________________________________
;

SELDSK:					;SELECT DISK
	PUSH 	BC			;
	LD	HL,(0001H)		;
	LD	BC,0024			;
	ADD	HL,BC			;
	POP	BC			;
	JP	(HL)			;
SETTRK:					;SET DISK TRACK ADDR
	PUSH 	BC			;
	LD	HL,(0001H)		;
	LD	BC,0027			;
	ADD	HL,BC			;
	POP	BC			;
	JP	(HL)			;
SETSEC:					;SET DISK SECTOR ADDR
	PUSH 	BC			;
	LD	HL,(0001H)		;
	LD	BC,0030			;
	ADD	HL,BC			;
	POP	BC			;
	JP	(HL)			;
SETDMA:					;SET DMA BUFFER ADDR
	PUSH 	BC			;
	LD	HL,(0001H)		;
	LD	BC,0033			;
	ADD	HL,BC			;
	POP	BC			;
	JP	(HL)			;
READ:				    	;READ SECTOR
	PUSH 	BC			;
	LD	HL,(0001H)		;
	LD	BC,0036			;
	ADD	HL,BC			;
	POP	BC			;
	JP	(HL)			;
WRITE:				       	;WRITE SECTOR
	PUSH 	BC			;
	LD	HL,(0001H)		;
	LD	BC,0039			;
	ADD	HL,BC			;
	POP	BC			;
	JP	(HL)			;


	
CURTRACK:	 .DW	0		; CURRENT TRACK
CURSECTOR:	 .DW	0		; CURRENT SECTOR	
CURADDRESS:	 .DW	0		; CURRENT CP/M ADDRESS
DMAAD:		 .DW 	5000H		; DIRECT MEMORY ADDRESS

CPMEND:		 .DW	0FDFFH		; END OF CP/M
SECTRACK:	 .DW	0100H		; SECTORS PER TRACK
CPMSTART:	 .DW	0D000H		; START OF CP/M
DEVICENUMBER:	 .DB	2		; DEVICE ID

	

MSG_END:
	 .DB	LF, CR			; LINE FEED AND CARRIAGE RETURN
	 .TEXT 	"BOOTGEN COMPLETED."
	 .DB	LF, CR			; LINE FEED AND CARRIAGE RETURN
	 .DB	"$"			; LINE TERMINATOR
MSG_VALID:
	 .DB	LF, CR			; LINE FEED AND CARRIAGE RETURN
	 .TEXT	"USAGE: BOOTGEN (DRIVE):"
	 .DB	LF, CR			; LINE FEED AND CARRIAGE RETURN
	 .TEXT	"(DRIVE) IS ANY VALID CP/M DRIVE:"
	 .DB	LF, CR			; LINE FEED AND CARRIAGE RETURN
	 .DB	"$"			; LINE TERMINATOR

	 
	 .END
	 
	 
	 