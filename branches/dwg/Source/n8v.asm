; ../RomWBW/Source/n8v.asm 11/22/2012 dwg - best so far
; ../RomWBW/Source/n8v.asm 11/19/2012 dwg - add snippets into video scheme
; ../RomWBW/Source/n8v.asm 11/16/2012 dwg - N8V_VDAQRY now working
; ../RomWBW/Source/n8v.asm 11/15/2012 dwg - vdaini and vdaqry retcodes ok
; ../RomWBW/Source/n8v.asm 10/28/2012 dwg - add n8v_modes
; ../RomWBW/Source/n8v.asm 10/27/2012 dwg - begin enhancement

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; N8 VIDEO DRIVER FOR ROMWBW ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor I/O Addresses for the TMS9918 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
BASE:   .EQU    128
CMDP:   .EQU    BASE+25
DATAP:  .EQU    BASE+24

;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
;_________________________________________________________________________
; BOARD INITIALIZATION
;_________________________________________________________________________

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This routine is called from bnk1.asm to init the TMS9918		;
; If HL is non-zero, it specifies the character bitmaps to load ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
N8V_VDAINI:
	LD	A,C
	LD	(VDP_DEVUNIT),A
	LD	A,E
	LD	(VDP_MODE),A
	PUSH	HL
	; Fall through...

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; clear first 16K of TMS9918 video ram to zeroes ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LD      C,CMDP
    LD      A,$00
    OUT     (C),A           ; out(CMDP,0);
	CALL	RECOVER
    LD      A,64
    OUT     (C),A           ; out(CMDP,64);
	CALL	RECOVER
	;
	LD	C,DATAP
	LD	HL,16384
CLR16LOOP:
	LD	A,0
	OUT	(C),A
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,CLR16LOOP

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Set TMS9918 into Text Mode ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    LD      C,CMDP
    LD      A,0
    OUT     (C),A           ; out(CMDP,0);
	CALL	RECOVER
    LD      A,128
    OUT     (C),A           ; out(CMDP,128);
	CALL	RECOVER

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; Set TMS9918 into 40-column mode ;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	LD      C,CMDP
    LD      A,80
    OUT     (C),A           ; out(CMDP,80);
	CALL	RECOVER
    LD      A,129
    OUT     (C),A           ; out(CMDP,129);
	CALL	RECOVER
	;
	;; text mode is 24x40
	LD		A,0
	LD		(VDP_MODE),a
	LD		a,40
	LD		(VDP_COLS),a
	LD		a,24
	LD		(VDP_ROWS),A

;;    CALL    VDP_PNT		; set TMS9918 Pattern Name Table Pointer
;VDP_PNT:
	LD      C,CMDP
    LD      A,0
    OUT     (C),A           ; out(CMDP,0);
	CALL	RECOVER
    LD      A,130
    OUT     (C),A           ; out(CMDP,130);
    CALL	RECOVER

;;    CALL    VDP_PGT		; set TMS9918 Pattern Generator Table Pointer
;VDP_PGT:
	LD      C,CMDP
    LD      A,1
    OUT     (C),A           ; out(CMDP,1);
	CALL	RECOVER
	LD      A,132
    OUT     (C),A           ; out(CMDP,132);
	CALL	RECOVER

;;    CALL    VDP_COLORS	; set TMS9918 foreground(white) background(black)
;VDP_COLORS:
	LD      C,CMDP
    LD      A,(VDP_ATTR)
;       LD      A,240
    OUT     (C),A           ; out(CMDP,240); 240 is 0xF0 - 1111 0000 LSB=background MSB=foreground
	CALL	RECOVER
    LD      A,135
    OUT     (C),A           ; out(CMDP,135);
    CALL	RECOVER


	POP		HL
	LD		A,L
	OR		H
	JP		Z,N8V_NOLOAD
;;    CALL    VDP_LOAD2   ; set TMS9918 character bitmaps
;VDP_LOAD2:
        LD      C,CMDP
        LD      A,0
        OUT     (C),A           ; out(CMDP,0);
		CALL	RECOVER
        LD      A,72
        OUT     (C),A           ; out(CMDP,72);
		CALL	RECOVER
        LD      DE,256
		LD		C,DATAP
VDP_LOAD2LOOP:
        LD      A,(HL)
        LD      (BYTE8),A
        INC     HL
        LD      A,(HL)
        LD      (BYTE7),A
        INC     HL
        LD      A,(HL)
        LD      (BYTE6),A
        INC     HL
        LD      A,(HL)
        LD      (BYTE5),A
        INC     HL
        LD      A,(HL)
        LD      (BYTE4),A
        INC     HL
        LD      A,(HL)
        LD      (BYTE3),A
        INC     HL
        LD      A,(HL)
        LD      (BYTE2),A
        INC     HL
        LD      A,(HL)
        INC     HL
        OUT     (C),A
		CALL	RECOVER
        LD      A,(BYTE2)
		OUT	(C),A
		CALL	RECOVER
        LD      A,(BYTE3)
        OUT     (C),A
		CALL	RECOVER
        LD      A,(BYTE4)
        OUT     (C),A
		CALL	RECOVER
        LD      A,(BYTE5)
        OUT     (C),A
		CALL	RECOVER
        LD      A,(BYTE6)
        OUT     (C),A
		CALL	RECOVER
        LD      A,(BYTE7)
        OUT     (C),A
		CALL	RECOVER
		LD      A,(BYTE8)
        OUT     (C),A
		CALL	RECOVER
        DEC	DE
		LD	A,D
		OR	E
        JR      NZ,VDP_LOAD2LOOP
N8V_NOLOAD:
; fall through...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Display init message on composite video ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	; Output "N8-2312 TMS9918 Text Mode Init Done!"
	LD	HL,0
	CALL	VDP_WRVRAM
    LD      HL,VDP_HELLO
    LD      DE,39
    LD      C,DATAP
HELLO_LOOP:
    LD      A,(HL)
    OUT     (C),A
    INC     HL
    DEC     DE
    LD      A,D
    OR      E
    JR      NZ,HELLO_LOOP
	;
	; N8VEM HBIOS v2.2 B3
	LD	HL,40+40+40+40+3
	CALL	VDP_WRVRAM
	LD	HL,STR_BANNER
	LD	C,DATAP
	LD	DE,20
BAN_LOOP:
	LD	A,(HL)
	CP	'('
	JP	Z,BAN_DONE
	OUT	(C),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,BAN_LOOP
BAN_DONE:
	;
	; (rOMwbw-DOUG-121113t0113) <BLANK>
	LD	HL,40+40+40+40+40+3
	CALL	VDP_WRVRAM
	;
	LD	HL,STR_BANNER + 20
	LD	C,DATAP
	;
	LD	DE,27
BAN_LOOP2:
	LD	A,(HL)
	CP	' '
	JP	Z,BAN_DONE2
	OUT	(C),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,BAN_LOOP2
	LD	A,'|'
	OUT	(C),A
	CALL	RECOVER
BAN_DONE2:
	;
	; n8 z180 sbc, floppy (autosize), ppide..
	PUSH	HL
	LD	HL,40+40+40+40+40+40+3
	CALL	VDP_WRVRAM
	POP	HL
	;
	LD	C,DATAP
	LD	DE,60
BAN_LOOP3:
	LD	A,(HL)
	CP	'$'
	JP	Z,BAN_DONE3
	OUT	(C),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JP	NZ,BAN_LOOP3
BAN_DONE3:
; fall through...

	CALL	PPK_INIT
	; fall through...

	XOR	A
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This is the end of the init routine ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;__________________________________________________________________________________________________
; CHARACTER I/O (CIO) DISPATCHER
;__________________________________________________________________________________________________
;
N8V_DISPCIO:
	LD	A,B	; GET REQUESTED FUNCTION
	AND	$0F	; ISOLATE SUB-FUNCTION
	JP	Z,PPK_READ
	DEC	A
	JR	Z,N8V_CIOOUT
	DEC	A
	JP	Z,PPK_STAT
	DEC	A
	JR	Z,N8V_CIOOST
	CALL	PANIC
;
N8V_CIOOUT:
	JP	N8V_VDAWRC
;
N8V_CIOOST:
	XOR	A
	INC	A
	RET
;	
;__________________________________________________________________________________________________
; VIDEO DISPLAY ADAPTER (VDA) DISPATCHER
;__________________________________________________________________________________________________
;
N8V_DISPVDA:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F		; ISOLATE SUB-FUNCTION

	JP	Z,N8V_VDAINI
	DEC	A
	JP	Z,N8V_VDAQRY
	DEC	A
	JP	Z,N8V_VDARES
	DEC	A
	JP	Z,N8V_VDASCS
	DEC	A
	JP	Z,N8V_VDASCP
	DEC	A
	JP	Z,N8V_VDASAT
	DEC	A
	JP	Z,N8V_VDASCO
	DEC	A
	JP	Z,N8V_VDAWRC
	DEC	A
	JP	Z,N8V_VDAFIL
	DEC	A
	JP	Z,N8V_VDASCR
	DEC	A
	JP	Z,PPK_STAT
	DEC	A
	JP	Z,PPK_FLUSH
	DEC	A
	JP	Z,PPK_READ
	CALL	PANIC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Query ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
N8V_VDAQRY:
	LD	A,H
	OR	L
	JP	Z,N8V_QDONE
	;	
	; read bitmaps and 
    LD      C,CMDP
    LD      A,0
    OUT     (C),A           ; out(CMDP,0);
	CALL	RECOVER
    LD      A,72
    OUT     (C),A           ; out(CMDP,72);
	CALL	RECOVER
	;
	LD	DE,256
	LD	C,DATAP
	IN	A,(C)					; read status
	CALL	RECOVER
VDP_QLOOP:
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE8),A
	;
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE7),A
	;
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE6),A
	;
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE5),A
	;
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE4),A
	;
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE3),A
	;
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE2),A
	;
	IN	A,(C)
	CALL	RECOVER
;	LD	(BYTE1),A
	;
	LD	(HL),A
	INC	HL
	;
	LD	A,(BYTE2)
	LD	(HL),A
	INC	HL
	;
	LD	A,(BYTE3)
	LD	(HL),A
	INC	HL
	;
	LD	A,(BYTE4)
	LD	(HL),A
	INC	HL
	;
	LD	A,(BYTE5)
	LD	(HL),A
	INC	HL
	;	
	LD	A,(BYTE6)
	LD	(HL),A
	INC	HL
	;
	LD	A,(BYTE7)
	LD	(HL),A
	INC	HL

	LD	A,(BYTE8)
	LD	(HL),A
	INC	HL

	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,VDP_QLOOP
N8V_QDONE:
	LD	A,(VDP_MODE)
	LD	C,A
	LD	A,(VDP_ROWS)
	LD	D,A
	LD	A,(VDP_COLS)
	LD	E,A

	LD	A,0		; return SUCCESS
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Reset	;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
N8V_VDARES:
	LD	HL,CHARSET
	JP	N8V_VDAINI

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; Video Display Processor Set Cursor Style ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
N8V_VDASCS:
	CALL	PANIC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; Video Display Processor Set Cursor Position ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
N8V_VDASCP:
	LD		(VDP_SCP_COL),A		; keep private copy of column
	LD		A,C
	LD		(VDP_SCP_DEV),A		; keep private copy of dev/unit
	LD		A,D
	LD		(VDP_SCP_ROW),A		; keep private copy of row
	XOR	A
	RET
VDP_SCP_DEV	.DB	0
VDP_SCP_ROW	.DB	0
VDP_SCP_COL	.DB	0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Set Character Attributes ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
N8V_VDASAT:
	CALL	PANIC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Set Color Color ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
N8V_VDASCO:
	CALL	PANIC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Write Character ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
N8V_VDAWRC:
	XOR	A
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Fill ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
N8V_VDAFIL:
	XOR	A
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	
; Video Display Processor Scroll ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
N8V_VDASCR:
  	XOR	A
	RET

;-------------------------------------------------

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Write the VRAM address registers ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
VDP_WRVRAM:
	; HL -> points to ram location
	LD	C,CMDP
	OUT	(C),L
	CALL	RECOVER
	OUT	(C),H
	CALL	RECOVER
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Recovery-time delay routine - Conservatively long delay ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
RECOVER:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	POP		HL
	POP		DE
	POP		BC
	RET

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Video Display Processor Local Driver Data ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VDP_DEVUNIT	.DB	0
VDP_ROW		.DB	0	; row number 0-23
VDP_COL		.DB	0	; col number 0-39
VDP_ROWS	.DB	24	; number of rows
VDP_COLS	.DB	40	;
VDP_MODE	.DB	0
VDP_ATTR	.DB	240	; default to white on black
VDP_HELLO       .TEXT   "   N8-2312 TMS9918 Text Mode Init Done!!"
VDP_HELLOLEN	.DB	$-VDP_HELLO

BYTE1           .DB     0
BYTE2           .DB     0
BYTE3           .DB     0
BYTE4           .DB     0
BYTE5           .DB     0
BYTE6           .DB     0
BYTE7           .DB     0
BYTE8           .DB     0

CHARSET:
#INCLUDE "n8chars.inc"

;;;;;;;;;;;;;;;;;
; eof - n8v.asm ;
;;;;;;;;;;;;;;;;;
