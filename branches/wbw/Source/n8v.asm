; ../RomWBW/Source/n8v.asm 11/16/2012 dwg - N8V_VDAQRY now working
; ../RomWBW/Source/n8v.asm 11/15/2012 dwg - vdaini and vdaqry retcodes ok
; ../RomWBW/Source/n8v.asm 10/28/2012 dwg - add n8v_modes
; ../RomWBW/Source/n8v.asm 10/27/2012 dwg - begin enhancement


;__N8VDRIVER_______________________________________________________________________________________
;
;	N8 VIDEO DRIVER FOR ROMWBW
;
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
; DATA CONSTANTS
;__________________________________________________________________________________________________
;
;_________________________________________________________________________
; BOARD INITIALIZATION
;_________________________________________________________________________

;
; This routine is called from bnk1.asm to init the TMS9918
; If HL is non-zero, it specifies the character bitmaps to load
N8V_VDAINI:

	LD	A,C
	LD	(VDP_DEVUNIT),A
	LD	A,E
	LD	(VDP_MODE),A
	PUSH	HL
    CALL    VDP_CLR16K	; clear first 16K of TMS9918 video ram to zeroes
    CALL    VDP_SETREGS	; set TMS9918 into Text Mode
    CALL    VDP_MODES	; set TMS9918 into 40-column mode
    CALL    VDP_PNT		; set TMS9918 Pattern Name Table Pointer
    CALL    VDP_PGT		; set TMS9918 Pattern Generator Table Pointer
    CALL    VDP_COLORS	; set TMS9918 foreground(white) background(black)
	POP		HL
	LD		A,L
	OR		H
	JP		Z,N8V_NOLOAD
    CALL    VDP_LOAD2   ; set TMS9918 character bitmaps
N8V_NOLOAD:
 	CALL	VDP_SINE	; display init message on composite video
	CALL	PPK_INIT
	XOR	A
	RET

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




N8V_VDAQRY:

	LD	A,H
	OR	L
	JP	Z,N8V_QDONE
		
	; read bitmaps and 
        LD      C,CMDP
        LD      A,0
        OUT     (C),A           ; out(CMDP,0);
	CALL	RECOVER
        LD      A,72
        OUT     (C),A           ; out(CMDP,72);
	CALL	RECOVER

	LD	DE,256
	LD	C,DATAP
	IN	A,(C)					; read status
	CALL	RECOVER
VDP_QLOOP:
	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE8),A

	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE7),A

	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE6),A

	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE5),A

	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE4),A

	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE3),A

	IN	A,(C)
	CALL	RECOVER
	LD	(BYTE2),A

	IN	A,(C)
	CALL	RECOVER
;	LD	(BYTE1),A

	LD	(HL),A
	INC	HL

	LD	A,(BYTE2)
	LD	(HL),A
	INC	HL
	
	LD	A,(BYTE3)
	LD	(HL),A
	INC	HL

	LD	A,(BYTE4)
	LD	(HL),A
	INC	HL

	LD	A,(BYTE5)
	LD	(HL),A
	INC	HL

	LD	A,(BYTE6)
	LD	(HL),A
	INC	HL

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
	
N8V_VDARES:
	LD	HL,CHARSET
	JP	N8V_VDAINI
	
N8V_VDASCS:
	CALL	PANIC
	
N8V_VDASCP:
	XOR	A
	RET
	
N8V_VDASAT:
	CALL	PANIC
	
N8V_VDASCO:
	CALL	PANIC
	
N8V_VDAWRC:
	XOR	A
	RET
	
N8V_VDAFIL:
	XOR	A
	RET
	
N8V_VDASCR:
  	XOR	A
	RET

;-------------------------------------------------

BASE:   .EQU    128
CMDP:   .EQU    BASE+25
DATAP:  .EQU    BASE+24

VDP_CLR16K:
        LD      C,CMDP
        LD      A,$00
        OUT     (C),A           ; out(CMDP,0);
        LD      A,64
        OUT     (C),A           ; out(CMDP,64);

	LD	C,DATAP
	LD	HL,16384
CLR16LOOP:
	LD	A,0
	OUT	(C),A
	DEC	HL
	LD	A,H
	OR	L
	JR	NZ,CLR16LOOP

        RET

;-------------------------------------------------

VDP_SETREGS:
        LD      C,CMDP
        LD      A,0
        OUT     (C),A           ; out(CMDP,0);
	NOP
        LD      A,128
        OUT     (C),A           ; out(CMDP,128);
        RET

;-------------------------------------------------

; The only TMS9918 mode available right now is "text mode".

VDP_MODES:
        LD      C,CMDP
        LD      A,80
        OUT     (C),A           ; out(CMDP,80);
		CALL	RECOVER
        LD      A,129
        OUT     (C),A           ; out(CMDP,129);
		CALL	RECOVER

	;; text mode is 24x40
	LD	A,0
	LD	(VDP_MODE),a
	LD	a,40
	LD	(VDP_COLS),a
	LD	a,24
	LD	(VDP_ROWS),A

        RET

;-------------------------------------------------

VDP_PNT:
        LD      C,CMDP
        LD      A,0
        OUT     (C),A           ; out(CMDP,0);
	NOP
        LD      A,130
        OUT     (C),A           ; out(CMDP,130);
        RET

;-------------------------------------------------

VDP_PGT:
        LD      C,CMDP
        LD      A,1
        OUT     (C),A           ; out(CMDP,1);
	NOP
        LD      A,132
        OUT     (C),A           ; out(CMDP,132);
        RET

;-------------------------------------------------

VDP_COLORS:
        LD      C,CMDP
        LD      A,(VDP_ATTR)
;       LD      A,240
        OUT     (C),A           ; out(CMDP,240); 240 is 0xF0 - 1111 0000 LSB=background MSB=foreground
	NOP
        LD      A,135
        OUT     (C),A           ; out(CMDP,135);
        RET

;-------------------------------------------------

;-------------------------------------------------

VDP_LOAD2:

        LD      C,CMDP
        LD      A,0

        OUT     (C),A           ; out(CMDP,0);
		CALL	RECOVER
        LD      A,72
        OUT     (C),A           ; out(CMDP,72);
		CALL	RECOVER

;		LD		A,H
;		OR		L
;		JP		NZ,NOLOAD2
;		LD		HL,CHARSET
;NOLOAD2:

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
        RET

;-------------------------------------------------





VDP_SINE:

	; N8-2312 TMS9918 Text Mode Init Done!
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

	; n8 z180 sbc, floppy (autosize), ppide..
	PUSH	HL
	LD	HL,40+40+40+40+40+40+3
	CALL	VDP_WRVRAM
	POP	HL

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

        RET


N8V_FILL:
	; out(CMDP,0);
	; out(CMDP,64);
	; d=0;
	; for(c=0;c<(40*24);c++) {
	; 	out(DATAP,d);
	;	d++;
	;	if(128 == d) d=0;
	; }
	RET

VDP_WRVRAM:
	; HL -> points to ram location

	; vdp_wrvram(o)
	; {
	; 	byte1 = o & 255;
	;	byte2 = (o >> 8) | 0x40;
	;	out(CMDP,byte1);
	;	out(CMDP,byte2);
	; }

	LD	C,CMDP
	OUT	(C),L
	CALL	RECOVER
	OUT	(C),H
	CALL	RECOVER
	RET


N8V_DISPLAY:
	; vdp_display(line,column,string)
	; {
	;	vdp_wrvram(GUTTER+(line*40)+column);
	;	for(index=0;index<strlen(string);index++) {
	;		out(DATAP,string[index]);
	;	}
	; }	
	RET

RECOVER:
	PUSH	BC
	PUSH	DE
	PUSH	HL
	POP	HL
	POP	DE
	POP	BC
	RET

;
;__________________________________________________________________________________________________
; LOCAL DRIVER DATA
;__________________________________________________________________________________________________
;

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
