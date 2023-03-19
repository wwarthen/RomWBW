;__CVDUTEST________________________________________________________________________________________
;
;	CVDUTEST   COLOR VDU TEST
;
;	WRITTEN BY: DAN WERNER -- 11/4/2011
;__________________________________________________________________________________________________
;

; DATA CONSTANTS
;__________________________________________________________________________________________________
;IDE REGISTER		IO PORT		; FUNCTION
M8563Status 	.EQU	$E4
M8563Register 	.EQU	$E4
M8563Data 	.EQU	$E5

I8242Status 	.EQU	$E3
I8242Command	.EQU 	$E3
I8242Data 	.EQU	$E2


	.ORG	$0100
;__________________________________________________________________________________________________
; MAIN PROGRAM BEGINS HERE
;__________________________________________________________________________________________________
INITVDU:
    	CALL	VDU_INIT		; INIT VDU
	CALL 	KB_INITIALIZE		; INIT KB

    	CALL	DSPMATRIX		; DISPLAY INIT MATRIX SCREEN
	CALL	WAIT_KBHIT		; WAIT FOR A KEYSTROKE

LOOP1:
	CALL	GET_KEY
	LD	C,14
	CP	13
	JP	Z,LOOP2
	CP	27
	JP	Z,LOOP3
	CP	'6'
	JP	Z,LOOP4
	CALL 	VDU_PutChar		; DUMP CHAR TO DISPLAY
	JP	LOOP1
LOOP2:
    	LD  	A,0			; YES, WRAP TO NEXT LINE
    	LD	(TERM_X),A		; STORE X
    	LD	A,(TERM_Y)		; A= Y COORD
    	INC 	A			; INC Y COORD
    	LD	(TERM_Y),A		; STORE Y
    	CALL 	GOTO_XY 	       	; YES, HANDLE SCROLLING
	JP	LOOP1
LOOP3:
	LD	C,00H			; CP/M SYSTEM RESET CALL
	CALL	0005H			; RETURN TO PROMPT
	RET
LOOP4:
	CALL	REVERSE_SCROLL
	JP	LOOP1


;__DO_SCROLL_______________________________________________________________________________________
;
; 	SCROLL THE SCREEN UP ONE LINE
;__________________________________________________________________________________________________			
DO_SCROLL:
	PUSH	AF			; STORE AF	
DO_SCROLLE1:
	PUSH	HL			; STORE HL
	PUSH	BC			; STORE BC
	
    	LD 	B, 24			; GET REGISTER 24	
	CALL	VDU_GREG		;
	OR	80H			; TURN ON COPY BIT
       	LD	D,A			; PARK IT
     	
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	E,23			;
DO_SCROLL1:	
    	LD 	B, 18			; SET UPDATE(DEST) POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE(DEST) POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	LD	BC,0050H		;
	ADD	HL,BC			;
       	LD 	B, 32			; SET SOURCE POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 33			; SET SOURCE POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	
    	LD 	B, 24			; SET COPY
    	LD	A,D			;
    	CALL	VDU_WREG		; WRITE IT
 	    	
    	LD 	B, 30			; SET AMOUNT TO COPY
    	LD	A,050H			;
    	CALL	VDU_WREG		; WRITE IT
	DEC	A
    	LD	A,E			;
    	CP	00H			;
      	JP	NZ,DO_SCROLL1		; LOOP TILL DONE
      	
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	BC,0820H		;
	ADD	HL,BC			;
	LD	E,23
DO_SCROLL2:	
    	LD 	B, 18			; SET UPDATE(DEST) POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE(DEST) POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	LD	BC,0050H		;
	ADD	HL,BC			;
       	LD 	B, 32			; SET SOURCE POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 33			; SET SOURCE POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	
    	LD 	B, 24			; SET COPY
    	LD	A,D			;
    	CALL	VDU_WREG		; WRITE IT
 	    	
    	LD 	B, 30			; SET AMOUNT TO COPY
    	LD	A,050H			;
    	CALL	VDU_WREG		; WRITE IT
	DEC	E
    	LD	A,E			;
    	CP	00H			;
      	JP	NZ,DO_SCROLL2		; LOOP TILL DONE      	

    	
    	LD	A,23			; SET CURSOR TO BEGINNING OF LAST LINE
    	LD	(TERM_Y),A		;
    	LD	A,(TERM_X)		;
    	PUSH	AF			; STORE X COORD
    	LD	A,0			;
    	LD	(TERM_X),A		;
    	CALL	GOTO_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
	POP	AF			; RESTORE X COORD
    	POP	BC			; RESTORE BC	
    	CALL	PERF_ERASE_EOL		; ERASE SCROLLED LINE
	LD	(TERM_X),A		;
   	CALL	GOTO_XY			; SET CURSOR POSITION
    	POP	HL			; RESTORE HL
    	POP	AF			; RESTORE AF
    	RET				;
    	
;__REVERSE_SCROLL__________________________________________________________________________________
;
; 	SCROLL THE SCREEN DOWN ONE LINE
;__________________________________________________________________________________________________			
REVERSE_SCROLL:
	PUSH	AF			; STORE AF	
	PUSH	HL			; STORE HL
	PUSH	BC			; STORE BC
	
    	LD 	B, 24			; GET REGISTER 24	
	CALL	VDU_GREG		;
	OR	80H			; TURN ON COPY BIT
       	LD	E,A			; PARK IT
     	
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	BC,0730H		;
	ADD  	HL,BC
	LD	D,23			;
REVERSE_SCROLL1:	
    	LD 	B, 18			; SET UPDATE(DEST) POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE(DEST) POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	LD	BC,0FFB0H		;
	ADD	HL,BC			;
       	LD 	B, 32			; SET SOURCE POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 33			; SET SOURCE POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	
    	LD 	B, 24			; SET COPY
    	LD	A,E			;
    	CALL	VDU_WREG		; WRITE IT
 	    	
    	LD 	B, 30			; SET AMOUNT TO COPY
    	LD	A,050H			;
    	CALL	VDU_WREG		; WRITE IT

	DEC	D
    	LD	A,D			;
    	CP	00H			;
      	JP	NZ,REVERSE_SCROLL1	; LOOP TILL DONE

     	
	LD 	HL, (VDU_DISPLAY_START)	; GET UP START OF DISPLAY
	LD	BC,0F50H		;
	ADD	HL,BC
	LD	D,23			;
REVERSE_SCROLL2:	
    	LD 	B, 18			; SET UPDATE(DEST) POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE(DEST) POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	LD	BC,0FFB0H		;
	ADD	HL,BC			;
       	LD 	B, 32			; SET SOURCE POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 33			; SET SOURCE POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	
    	LD 	B, 24			; SET COPY
    	LD	A,E			;
    	CALL	VDU_WREG		; WRITE IT
 	    	
    	LD 	B, 30			; SET AMOUNT TO COPY
    	LD	A,050H			;
    	CALL	VDU_WREG		; WRITE IT

	DEC	D
    	LD	A,D			;
    	CP	00H			;
      	JP	NZ,REVERSE_SCROLL2	; LOOP TILL DONE    	
    	LD	A,0			; SET CURSOR TO BEGINNING OF FIRST LINE
    	LD	(TERM_Y),A		;
    	LD	A,(TERM_X)		;
   	PUSH	AF			; STORE X COORD
    	LD	A,0			;
    	LD	(TERM_X),A		;
    	CALL	GOTO_XY			; SET CURSOR POSITION TO BEGINNING OF LINE
    	POP	AF			; RESTORE AF
    	POP	BC			; RESTORE BC
    	CALL	PERF_ERASE_EOL		; ERASE SCROLLED LINE
	LD	(TERM_X),A		;
   	CALL	GOTO_XY			; SET CURSOR POSITION
    	POP	HL			; RESTORE HL
    	POP	AF			; RESTORE AF
    	RET				;
	
	

;__VDU_INIT_________________________________________________________________________________________
;
; 	INITIALIZE VDU
;__________________________________________________________________________________________________			
VDU_INIT:
	PUSH 	AF			; STORE AF
	PUSH 	DE			; STORE DE
	PUSH 	HL			; STORE HL
	PUSH	BC			; STORE BC

	CALL 	VDU_CRTInit		; INIT 8563 VDU CHIP	
	CALL	VDU_LOADFONT		;
	CALL	PERF_CURSOR_HOME	; CURSOR HOME
	LD	C,14			;	
	CALL	PERF_ERASE_EOS		; CLEAR SCREEN
    	CALL 	VDU_CursorOn		; TURN ON CURSOR

    	POP	BC			;
       	POP 	HL			;
	POP 	DE			;
	POP 	AF			;

   	RET	
	
;__PERF_CURSOR_HOME________________________________________________________________________________
;
; 	PERFORM CURSOR HOME
;__________________________________________________________________________________________________	
PERF_CURSOR_HOME:
	LD	A,0			; LOAD 0 INTO A
	LD	(TERM_X),A		; SET X COORD
	LD	(TERM_Y),A		; SET Y COORD
	JP	GOTO_XY			; MOVE CURSOR TO POSITION

;__PERF_ERASE_EOS__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF SCREEN
;       C= DEFAULT COLOR
;__________________________________________________________________________________________________	
PERF_ERASE_EOS:	
	PUSH	HL
	PUSH	AF
	PUSH	BC

    	LD 	HL, (VDU_DisplayPos)	; GET CURRENT DISPLAY ADDRESS
    	LD 	B, 18			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT   		
	CALL	GOTO_XY			; MOVE CURSOR 
	LD	DE,0820H		; SET SCREEN SIZE INTO HL
PERF_ERASE_EOS_LOOP:		
    	LD 	A, ' '           	; MOVE SPACE CHARACTER INTO A
	LD	B,31			;
       	CALL	VDU_WREG	 	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
      	DEC	DE			; DEC COUNTER
    	LD 	A,D			; IS COUNTER 0 YET?
    	OR 	E			;
    	JP 	NZ,PERF_ERASE_EOS_LOOP	; NO, LOOP
	LD	DE,0820H		; SET SCREEN SIZE INTO HL
PERF_ERASE_EOS_CLOOP:		
    	LD 	A, C	           	; MOVE COLOR INTO A
	LD	B,31			;
       	CALL	VDU_WREG	 	; WRITE IT TO SCREEN, VDU WILL AUTO INC TO NEXT ADDRESS
      	DEC	DE			; DEC COUNTER
    	LD 	A,D			; IS COUNTER 0 YET?
    	OR 	E			;
    	JP 	NZ,PERF_ERASE_EOS_CLOOP	; NO, LOOP
    	
	CALL	GOTO_XY			; YES, MOVE CURSOR BACK TO ORIGINAL POSITION
	POP	BC
	POP	AF
	POP	HL
	RET	

;__PERF_ERASE_EOL__________________________________________________________________________________
;
; 	PERFORM ERASE FROM CURSOR POS TO END OF LINE
;       C=DEFAULT COLOR
;__________________________________________________________________________________________________	
PERF_ERASE_EOL:	
	PUSH	HL
	PUSH	AF
	PUSH	BC

	LD	A,(TERM_X)		; GET CURRENT CURSOR X COORD
	LD	D,A			; STORE IT IN C
	LD	A,80			; MOVE CURRENT LINE WIDTH INTO A
	SUB	D			; GET REMAINING POSITIONS ON CURRENT LINE
	LD	B,A			; MOVE IT INTO B
PERF_ERASE_EOL_LOOP:		
    	LD 	A, ' '           	; MOVE SPACE CHARACTER INTO A
	CALL	VDU_PutCharRAW		;
	DJNZ    PERF_ERASE_EOL_LOOP	; LOOP UNTIL DONE
	CALL	GOTO_XY			; MOVE CURSOR BACK TO ORIGINAL POSITION
	POP	BC
	POP	AF
	POP	HL
	RET
		
;__DSPMATRIX_______________________________________________________________________________________
;
; 	DISPLAY INTRO SCREEN
;__________________________________________________________________________________________________			
DSPMATRIX:
	CALL	PERF_CURSOR_HOME	; RESET CURSOR TO HOME POSITION
    	LD	HL,TESTMATRIX		; SET HL TO SCREEN IMAGE
	LD 	DE, 1919   		; SET IMAGE SIZE
	LD	C,00000011B		; SET COLOR
DSPMATRIX_LOOP:    	
    	LD 	A,(HL)			; GET NEXT CHAR FROM IMAGE
    	call 	VDU_PutChar		; DUMP CHAR TO DISPLAY
    	INC	HL			; INC POINTER
	DEC	DE			; DEC COUNTER
    	LD 	A,D			; IS COUNTER ZERO?
    	OR 	E			;
    	JP 	NZ,DSPMATRIX_LOOP	; NO, LOOP
	CALL	PERF_CURSOR_HOME	; YES, RESET CURSOR TO HOME POSITION
	RET

TESTMATRIX:
 .TEXT "0         1         2         3         4         5         6         7         "
 .TEXT "01234567890123456789012345678901234567890123456789012345678901234567890123456789"
 .TEXT "2                                                                               "
 .TEXT "3                                                                               "
 .TEXT "4               =====================================================           "
 .TEXT "5                                                                               "
 .TEXT "6                 ****   *     *  ****    *    *        ****   *  *             "
 .TEXT "7                *    *  *     *  *   *   *    *       *    *  * *              "
 .TEXT "8                *       *     *  *    *  *    *       *    *  **               "
 .TEXT "9                *        *   *   *    *  *    *       *    *  **               "
 .TEXT "10               *    *    * *    *   *   *    *       *    *  * *              "
 .TEXT "11                ****      *     ****     ****         ****   *  *             "
 .TEXT "12                                                                              "
 .TEXT "13              =====================================================           "
 .TEXT "14                                                                              "
 .TEXT "15                         VDU TEST V0.1   VT-52 EMULATION                      "
 .TEXT "16                                                                              "
 .TEXT "17                  **  PRESS ANY KEY TO ENTER TERMINAL MODE **                 "
 .TEXT "18                                                                              "
 .TEXT "19                                                                              "
 .TEXT "21                                                                              "
 .TEXT "22                                                                              "
 .TEXT "23                                                                              "
 .TEXT "24                                                                              "
 

;__VDU_WREG________________________________________________________________________________________
;
; 	WRITE VALUE IN A TO REGISTER IN B
;	B: REGISTER TO UPDATE
;	A: VALUE TO WRITE
;__________________________________________________________________________________________________			
VDU_WREG:
	PUSH 	AF			; STORE AF
VDU_WREG_1:	
	IN 	A,(M8563Status)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,VDU_WREG_1	  	; wait for ready
	LD	A,B			;
       	OUT 	(M8563Register),A      	; select register 
VDU_WREG_2:	
	IN 	A,(M8563Status)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,VDU_WREG_2	  	; wait for ready
	POP	AF			;
       	OUT 	(M8563Data),A      	; PUT DATA
    	RET


;__VDU_GREG________________________________________________________________________________________
;
; 	GET VALUE FROM REGISTER IN B PLACE IN A
;	B: REGISTER TO GET
;	A: VALUE 
;__________________________________________________________________________________________________			
VDU_GREG:
	IN 	A,(M8563Status)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,VDU_GREG	  	; wait for ready
	LD	A,B			;
       	OUT 	(M8563Register) , A    	; select register 
VDU_GREG_1:	
	IN 	A,(M8563Status)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,VDU_GREG_1	  	; wait for ready
       	IN 	A,(M8563Data)       	; GET DATA 
    	RET



VDU_Init8563:
    .DB		126,80,102,73,32,224,25,29,252,231,160,231,0,0,7,128
    .DB		18,23,15,208,8,32,120,232,32,71,240,0,47,231,79,7,15,208,125,100,245	
 
;__VDU_CRTInit_____________________________________________________________________________________
;
; 	INIT VDU CHIP
;__________________________________________________________________________________________________			   	
VDU_CRTInit:
    	PUSH 	AF			; STORE AF
    	PUSH 	BC			; STORE BC
    	PUSH 	HL			; STORE HL
    	
    	LD 	B,$00	        	; B = 0 
    	LD 	HL,VDU_Init8563  	; HL = pointer to the default values
    	XOR 	A               	; A = 0
VDU_CRTInitLoop:
	LD	A,(HL)			; GET VALUE
	CALL	VDU_WREG		; WRITE IT
	INC	HL
	INC	B			; 
	LD	A,B			;
	CP	37			;
	JR	NZ,VDU_CRTInitLoop	; LOOP UNTIL DONE
    	POP 	HL			; RESTORE HL
    	POP	BC			; RESTORE BC
    	POP	AF			; RESTORE AF
    	RET


;__VDU_CursorOn____________________________________________________________________________________
;
; 	TURN ON CURSOR
;__________________________________________________________________________________________________			   	
VDU_CursorOn:
    	PUSH 	AF			; STORE AF
    	LD 	A, $60			; SET CURSOR VALUE
    	JP 	VDU_CursorSet		;

;__VDU_CursorOff___________________________________________________________________________________
;
; 	TURN OFF CURSOR
;__________________________________________________________________________________________________			   	   	
VDU_CursorOff:
    	PUSH 	AF			; STORE AF
    	LD 	A, $20			; SET CURSOR VALUE
VDU_CursorSet:
	PUSH 	BC			; STORE BC
	LD	B,10
	CALL	VDU_WREG		; WRITE IT
    	POP 	BC			; RESTORE BC
    	POP 	AF			; RESTORE AF
    	RET

;__GOTO_XY_________________________________________________________________________________________
;
; 	MOVE CURSOR TO POSITON IN TERM_X AND TERM_Y
;__________________________________________________________________________________________________			
GOTO_XY:
	PUSH	AF			; STORE AF

	LD	A,(TERM_Y)		; PLACE Y COORD IN A
	CP	24			; IS 24?
	JP	Z,DO_SCROLLE1		; YES, MUST SCROLL

    	PUSH 	BC			; STORE BC
    	PUSH 	DE			; STORE DE
	LD	A,(TERM_X)		;
	LD	H,A			;
    	LD	A,(TERM_Y)		;
    	LD	L,A			;    	
    	PUSH 	HL			; STORE HL
    	LD 	B, A             	; B = Y COORD
    	LD 	DE, 80			; MOVE LINE LENGTH INTO DE
    	LD 	HL, 0			; MOVE 0 INTO HL
    	LD 	A, B             	; A=B
    	CP 	0			; Y=0?
    	JP 	Z, VDU_YLoopEnd  	; THEN DO NOT MULTIPLY BY 80
VDU_YLoop:              		; HL = 80 * Y
    	ADD 	HL, DE			; HL=HL+DE
    	DJNZ 	VDU_YLoop		; LOOP 
VDU_YLoopEnd:				;
    	POP 	DE              	; DE = org HL
    	LD 	E, D             	; E = X
    	LD 	D, 0             	; D = 0
    	ADD 	HL, DE          	; HL = HL + X
    	LD 	(VDU_DisplayPos), HL	;
	PUSH	HL			;
	POP	DE			;
	LD	HL,(VDU_DISPLAY_START)	;
	ADD	HL,DE			;    		
    	LD 	B, 18			; SET UPDATE ADDRESS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE ADDRESS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	
    	LD 	B, 14			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 15			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	POP 	DE			; RESTORE DE
   	POP 	BC			; RESTORE BC
    	POP 	AF			; RESTORE AF
    	RET

;__VDU_PutChar______________________________________________________________________________________
;
; 	PLACE CHARACTER ON SCREEN
;	A: CHARACTER TO OUTPUT
;	C: COLOR
;__________________________________________________________________________________________________			   	   	
VDU_PutChar:
	PUSH	DE			; STORE DE
    	PUSH 	AF			; STORE AF
    	PUSH	HL			; STORE HL
    	LD	D,A			; STORE CHAR IN D
    	LD	A,(TERM_X)		; PLACE X COORD IN A
    	INC	A			; INC X COORD
    	LD	(TERM_X),A		; STORE IN A
    	CP	80			; IS 80?
    	JP	NZ,VDU_PutChar1		; NO, PLACE CHAR ON DISPLAY
    	LD  	A,0			; YES, WRAP TO NEXT LINE
    	LD	(TERM_X),A		; STORE X
    	LD	A,(TERM_Y)		; A= Y COORD
    	INC 	A			; INC Y COORD
    	LD	(TERM_Y),A		; STORE Y
    	CP	24			; IS PAST END OF SCREEN?
    	CALL 	Z,GOTO_XY        	; YES, HANDLE SCROLLING
VDU_PutChar1:				;
					;
    	LD 	HL, (VDU_DisplayPos)	; GET CURRENT DISPLAY ADDRESS
    	LD 	B, 18			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT   	
       	LD	A,D			; RESTORE CHAR
    	LD	B,31			;
    	CALL	VDU_WREG		; WRITE IT
	PUSH	HL			;
	LD	DE,$0820		;
    	ADD    	HL,DE			;
    	LD 	B, 18			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT   	
       	LD	A,C			; GET COLOR
    	LD	B,31			;
    	CALL	VDU_WREG		; WRITE IT
	POP	HL			; RESTORE ADDRESS
    	INC 	HL			; INCREMENT IT
    	LD 	(VDU_DisplayPos), HL	; STORE CURRENT DISPLAY ADDRESS
    	PUSH	HL			; MOVE HL TO DE
    	POP	DE			;
    	LD	HL,(VDU_DISPLAY_START)	;
    	ADD	HL,DE			;    	
    	LD 	B, 14			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 15			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT
    	
    	POP 	HL			; RESTORE HL
    	POP 	AF			; RESTORE AF
    	POP	DE			; RESTORE DE
    	RET

VDU_PutCharRAW:	
	PUSH	BC			;
	LD	D,A			;
    	LD 	HL, (VDU_DisplayPos)	; GET CURRENT DISPLAY ADDRESS
    	LD 	B, 18			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT   	
       	LD	A,D			; RESTORE CHAR
    	LD	B,31			;
    	CALL	VDU_WREG		; WRITE IT
	PUSH	HL			;
	LD	DE,$0820		;
    	ADD    	HL,DE			;
    	LD 	B, 18			; SET UPDATE CSR POS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE CSR POS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT   	
       	LD	A,C			; GET COLOR
    	LD	B,31			;
    	CALL	VDU_WREG		; WRITE IT
	POP	HL			; RESTORE ADDRESS
    	INC 	HL			; INCREMENT IT
    	LD 	(VDU_DisplayPos), HL	; STORE CURRENT DISPLAY ADDRESS
    	POP	BC
	RET
	   	
;__VDU_LOADFONT____________________________________________________________________________________
;
; 	LOAD SCREEN FONT
;__________________________________________________________________________________________________			   	   	
VDU_LOADFONT:
	PUSH 	AF
	PUSH	BC
	
	LD	HL,$2000		; SET FONT LOCATION
					;
   	LD 	B, 18			; SET UPDATE ADDRESS IN VDU
    	LD	A,H			;
    	CALL	VDU_WREG		; WRITE IT
    	LD 	B, 19			; SET UPDATE ADDRESS IN VDU
    	LD	A,L			;
    	CALL	VDU_WREG		; WRITE IT

    	LD	B,$00			; FONT SIZE
    	LD	C,$20			; FONT SIZE
	LD	HL,FONT			; FONT DATA
VDU_LOADFONT_LOOP:
	IN 	A,(M8563Status)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,VDU_LOADFONT_LOOP  	; wait for ready
	LD	A,31			;
       	OUT 	(M8563Register) , A    	; select register 
VDU_LOADFONT_LOOP_1:	
	IN 	A,(M8563Status)         ; read address/status register
    	BIT 	7,A             	; if bit 7 = 1 than an update strobe has been occured
    	JR 	Z,VDU_LOADFONT_LOOP_1  	; wait for ready
	LD	A,(HL)			;
       	OUT 	(M8563Data) , A      	; PUT DATA
       	INC	HL
       	DJNZ	VDU_LOADFONT_LOOP	;
	DEC	C			;
	JP	NZ,VDU_LOADFONT_LOOP	;	
       	POP	BC
       	POP	AF
       	RET    		

;__KB_INITIALIZE___________________________________________________________________________________
;
; 	INIT KEYBOARD CONTROLLER
;__________________________________________________________________________________________________
KB_INITIALIZE:
	LD	C,0aaH			; SELF TEST
	CALL	I8242CommandPut		;
	LD	C,060H			; SET COMMAND REGISTER
	CALL	I8242CommandPut		;
	LD	C,$60			; XLAT ENABLED, MOUSE DISABLED, NO INTS
	CALL	I8242DataPut		;
	LD	C,0a7H			; DISABLE MOUSE
	CALL	I8242CommandPut		;
	LD	C,0aeH			; ENABLE KEYBOARD
	CALL	I8242CommandPut		;
	LD	A,0			; EMPTY KB QUEUE
	LD	(KB_QUEUE_PTR),A	; 
	RET

;__I8242CommandPut_________________________________________________________________________________
;
; 	WRITE VALUE IN A TO 8242
;	C: VALUE TO WRITE
;__________________________________________________________________________________________________	
I8242CommandPut:
	IN 	A,(I8242Status)         ; read status register
    	BIT 	1,A             	; if bit 1 = 1 
    	JR 	NZ,I8242CommandPut  	; wait for ready
	LD	A,C			;
       	OUT 	(I8242Command),A      	; select register 
	RET

;__I8242DataPut____________________________________________________________________________________
;
; 	WRITE VALUE IN A TO 8242
;	C: VALUE TO WRITE
;__________________________________________________________________________________________________	
I8242DataPut:
	IN 	A,(I8242Status)         ; read status register
    	BIT 	1,A             	; if bit 1 = 1 
    	JR 	NZ,I8242DataPut  	; wait for ready
	LD	A,C			;
       	OUT 	(I8242Data),A      	; select register 
	RET

;__WAIT_KBHIT______________________________________________________________________________________
;
; 	WAIT FOR A KEY PRESS
;__________________________________________________________________________________________________			
WAIT_KBHIT:
	CALL 	KB_PROCESS		; call keyboard routine
	LD	A,(KB_QUEUE_PTR)	; IS QUEUE EMPTY?
	OR 	A			; set flags
	JP 	Z,WAIT_KBHIT		; if no keys waiting, try again
	RET
	
;__IS_KBHIT________________________________________________________________________________________
;
; 	WAS A KEY PRESSED?
;__________________________________________________________________________________________________			
IS_KBHIT:
	CALL 	KB_PROCESS		; call keyboard routine
	LD 	A,(KB_QUEUE_PTR)	; ask if keyboard has key waiting
	RET
	
				
;__GET_KEY_________________________________________________________________________________________
;
; 	GET KEY PRESS VALUE
;__________________________________________________________________________________________________			
GET_KEY:
	CALL	WAIT_KBHIT		; WAIT FOR A KEY
	LD	A,(KB_QUEUE_PTR)	; GET QUEUE POINTER
	OR	A			;
	RET	Z			; ABORT IF QUEUE EMPTY
	PUSH	BC			; STORE BC
	LD	B,A			; STORE QUEUE COUNT FOR LATER
	PUSH	HL			; STORE HL
	LD	A,(KB_QUEUE)		; GET TOP BYTE FROM QUEUE
	PUSH 	AF			; STORE IT
	LD	HL,KB_QUEUE		; GET POINTER TO QUEUE
GET_KEY_LOOP:				;
	INC	HL			; POINT TO NEXT VALUE IN QUEUE
	LD	A,(HL)			; GET VALUE
	DEC 	HL			;
	LD	(HL),A			; MOVE IT UP ONE
	INC	HL			;
	DJNZ	GET_KEY_LOOP		; LOOP UNTIL DONE
	LD	A,(KB_QUEUE_PTR)	; DECREASE QUEUE POINTER BY ONE	
	DEC	A			;
	LD	(KB_QUEUE_PTR),A	;
	POP	AF			; RESTORE VALUE
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	RET		
	

;__KB_PROCESS______________________________________________________________________________________
;
;  a=0 if want to know if a byte is available, and a=1 to ask for the byte
;__________________________________________________________________________________________________			   	   	
KB_PROCESS:	
	IN 	A,(I8242Status)         ; read status register
    	BIT 	0,A             	; if bit 0 = 0 
    	RET 	Z		 	; EXIT
	IN	A,(I8242Data)		; GET BYTE
	call 	KB_decodechar		; returns char or 0 for things like keyup, some return directly to cp/m
	ret				; return to cp/m

;__KB_waitbyte______________________________________________________________________________________
;
;  WAIT FOR byte TO BE available
;__________________________________________________________________________________________________			   	   	
KB_waitbyte:	
	IN 	A,(I8242Status)         ; read status register
    	BIT 	0,A             	; if bit 0 = 0 
    	jp 	Z,KB_waitbyte		; LOOP
    	IN	A,(I8242Data)		; GET BYTE
	RET


	
;__KB_decodechar____________________________________________________________________________________
;
; decode character pass a and prints out the char
; on the LCD screen
;__________________________________________________________________________________________________			   	   	
KB_decodechar:
	cp	0		; is it zero
	ret	z		; return if a zero - no need to do anything

	ld 	c,a		;
	cp	0AAh		; shift (down, because up would be trapped by 0F above)
	jp 	z,shiftup	;
	cp	0B6h		; other shift key
	jp 	z,shiftup	;
	cp	9Dh		; control key
	jp 	z,controlup	;
	AND 	80H             ; if bit 7 = 1 
	RET 	nz		; ignore char up
	ld 	a,C		;
	cp 	0E0h		; TWO BYTE
	JP	Z,twobyte	;
	cp 	03Ah		; caps lock so toggle
	jp 	z,capstog	;
	cp	2Ah		; shift (down, because up would be trapped by 0F above)
	jp 	z,shiftdown	;
	cp	36h		; other shift key
	jp 	z,shiftdown	;
	cp	01Dh		; control key
	jp 	z,controldown	;
	ld 	c,a		;
	ld 	b,0		; add bc to hl
	ld 	hl,normalkeys	; offset to add
	add 	hl,bc		;	
	ld 	a,(ctrl)	;
	cp 	0		; is control being held down?
	jR	z,dc1		; no so go back to test caps lock on
	ld	a,(hl)		; get the letter, should be smalls 
	sub	96		; a=97 so subtract 96 a=1=^A
	JP	KB_ENQUEUE	; STORE ON KB QUEUE
dc1:	ld 	a,(capslock)	;
	cp 	0		; is it 0, if so then don't add the caps offset
	jr 	z,dc2		;
	ld 	c,080h		; add another 50h to smalls to get caps
	add 	hl,bc		;
dc2:	ld 	a,(hl)		;
	JP	KB_ENQUEUE	; STORE ON KB QUEUE
twobyte:; already got EO so get the next character
	call 	KB_waitbyte
	cp	053h		; delete
	jp	z,deletekey	;
	cp	01Ch		; return on number pad
	jp	z,returnkey	;
	cp	050h		;
	jp	z,downarrow	;
	cp	04Dh		;
	jp	z,rightarrow	;
	cp	04Bh		;
	jp	z,leftarrow	;
	cp	048h		;
	jp	z,uparrow	;
	cp	052h		;
	jp	z,insert	;
	cp	049h		;
	jp	z,pageup	;
	cp	051h		;
	jp	z,pagedown	;
	cp	047h		;
	jp	z,home		;
	cp	04Fh		;
	jp	z,end		;
	ld 	a,0		; returns nothing
	ret
home:				;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'w'		; w
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
end:				;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'q'		; q
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
downarrow:			;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'B'		; B
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
rightarrow:			;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'C'		; C
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
leftarrow:			;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'D'		; D
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
uparrow:			;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld 	a,'A'		; A
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;	
insert:				;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'p'		; p
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
pageup:				;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'y'		; y
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
pagedown:			;
	ld	a,1BH		; ESC
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'?'		; ?
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ld	a,'s'		; s
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
controldown:			; same code as shiftdown but diff location
	ld 	a,0ffh		;
	ld	(ctrl),a	; control down
	ld	a,0		;
	ret			;
controlup:			; control key up see shift for explanation
	ld	a,0		;
	ld 	(ctrl),a	;
	ld 	a,0		;
	ret			;
returnkey:			;
	ld 	a,13		;
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
deletekey:			;
	ld 	a,07fh		; delete key value that cp/m uses
	CALL	KB_ENQUEUE	; STORE ON KB QUEUE
	ret			;
capstog:			;
  	ld 	a,(capslock)	;
	xor 	11111111B	; swap all the bits
	ld 	(capslock),a	;
	ld	a,0		; returns nothing
	ret			;
shiftdown:			; shift is special - hold it down and it autorepeats
				; so once it is down, turn caps on and ignore all further shifts
				; only an F0+shift turns caps lock off again
	ld 	a,0ffh		;
	ld 	(capslock),a	;
	ld 	a,0		; returns nothing
	ret			;
shiftup:			; shiftup turns off caps lock definitely
	ld 	a,0		;
	ld 	(capslock),a	;
	ld 	a,0		; returns nothing
	ret			;

;__KB_ENQUEUE______________________________________________________________________________________
;
;  STORE A BYTE IN THE KEYBOARD QUEUE 
;  A: BYTE TO ENQUEUE
;__________________________________________________________________________________________________			   	   		
KB_ENQUEUE:
	PUSH	DE		; STORE DE
	PUSH	HL		; STORE HL	
	PUSH	AF		; STORE VALUE
	LD	A,(KB_QUEUE_PTR); PUT QUEUE POINTER IN A
	CP	15		; IS QUEUE FULL
	JP	P,KB_ENQUEUE_AB	; YES, ABORT	
	LD	HL,KB_QUEUE	; GET QUEUE POINTER
	PUSH	HL		; MOVE HL TO BC
	POP	BC		; 
	LD	H,0		; ZERO OUT H
	LD	L,A		; PLACE QUEUE POINTER IN L
	ADD	HL,BC		; POINT HL AT THE NEXT LOACTION TO ADD VALUE
	POP	AF		; RESTORE VALUE
	LD	(HL),A		; ENQUEUE VALUE
	LD	A,(KB_QUEUE_PTR); GET QUEUE POINTER
	INC	A		; INC IT
	LD	(KB_QUEUE_PTR),A; STORE QUEUE POINTER
KB_ENQUEUE_AB:
	POP	HL		; RESTORE HL
	POP	DE		; RESTORE DE
	RET
	
	

	
normalkeys: ; The TI character codes, offset from label by keyboard scan code
		.db 000,027,"1","2","3","4","5","6","7","8","9","0","-","=",008,009			;00-0F
		.DB "q","w","e","r","t","y","u","i","o","p","[","]",013,000,"a","s"			;10-1F
		.DB "d","f","g","h","j","k","l",";",27H,60H,000,092,"z","x","c","v"			;20-2F
		.DB "b","n","m",",",".","/",000,000,000," ",000,000,000,000,000,000			;30-3F
		.DB 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;40-4F
		.db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;50-5F
		.db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;60-6F
		.db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000			;70-7F
		.db 000,027,"!","@","#","$","%","^","&","*","(",")","_","+",008,009
		.DB "Q","W","E","R","T","Y","U","I","O","P","{","}",013,000,"A","S"
		.DB "D","F","G","H","J","K","L",":",034,"~",000,"|","Z","X","C","V"
		.DB "B","N","M","<",">","?",000,000,000," ",000,000,000,000,000,000
		.db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
		.DB 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
		.db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
		.db 000,000,000,000,000,000,000,000,000,000,000,000,000,000,000,000
		
		
;		.DB	  0,"*",  0,"*","*","*","*","*",  0,"*","*","*","*",09H,"`",00H
;		.DB   	  0,  0,  0,  0,  0,"q","1",  0,  0,  0,"z","s","a","w","2",0
;		.DB   	  0,"c","x","d","e","4","3",  0,  0," ","v","f","t","r","5",0
;		.DB   	  0,"n","b","h","g","y","6",  0,  0,  0,"m","j","u","7","8",0
;		.DB   	  0,",","k","i","o","0","9",  0,  0,".","/","l",";","p","-",0
;		.DB   	  0,  0,27H,  0,"[","=",  0,  0,  0,  0,0DH,"]",  0,5CH,  0,0
;		.DB   	  0,  0,  0,  0,  0,  0,08H,  0,  0,11H,  0,13H,10H,  0,  0,  0
;		.DB 	0BH,7FH,03H,15H,04H,05H,1BH,00H,"*",02H,18H,16H,0CH,17H,"*",0
;		.DB   	  0,  0,  0,"*",  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0

	
 .include "font.asm"	

;__________________________________________________________________________________________________
;
; 	RAM STORAGE AREAS
;__________________________________________________________________________________________________			

ALT_KEYPAD	.DB	0		; ALT KEYPAD ENABLED?	
GR_MODE		.DB	0		; GRAPHICS MODE ENABLED?
TERM_X:		.DB	0		; CURSOR X
TERM_Y:		.DB	0		; CURSOR Y
TERMSTATE:	.DB	0		; TERMINAL STATE
					; 0 = NORMAL
					; 1 = ESC RCVD
VDU_DisplayPos:	.DW  	0		; CURRENT DISPLAY POSITION
VDU_DISPLAY_START:
		.DW  	0		; CURRENT DISPLAY POSITION
capslock	.DB  	0		; location for caps lock, either 00000000 or 11111111
ctrl		.DB  	0		; location for ctrl on or off 00000000 or 11111111
numlock		.DB  	0		; location for num lock
skipcount	.DB	0		; only check some calls, speeds up a lot of cp/m

KB_QUEUE	.DB	0,0,0,0,0,0,0,0 ; 16 BYTE KB QUEUE
		.DB	0,0,0,0,0,0,0,0
KB_QUEUE_PTR	.DB	0		; POINTER TO QUEUE			
PARKSTACK	.DW	0000		; SAVE STACK POINTER 

		.DB	0,0,0,0,0,0,0,0 ;
		.DB	0,0,0,0,0,0,0,0	;
		.DB	0,0,0,0,0,0,0,0 ;
		.DB	0,0,0,0,0,0,0,0	;
		.DB	0,0,0,0,0,0,0,0 ;
		.DB	0,0,0,0,0,0,0,0	;
		.DB	0,0,0,0,0,0,0,0 ;
		.DB	0,0,0,0,0,0,0,0	;
		.DB	0,0,0,0,0,0,0,0 ;
		.DB	0,0,0,0,0,0,0,0	;
		.DB	0,0,0,0,0,0,0,0 ;
		.DB	0,0,0,0,0,0,0,0	;
TERMSTACK:	.DB	0		;


	.end
