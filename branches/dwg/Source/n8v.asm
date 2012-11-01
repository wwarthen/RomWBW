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
;__________________________________________________________________________________________________
; BOARD INITIALIZATION
;__________________________________________________________________________________________________
;
N8V_INIT:
        CALL    VDP_CLR16K	; clear the first 16K of TMS9918 video ram to zeroes
        CALL    VDP_SETREGS	; set TMS9918 into Text Mode
        CALL    VDP_MODES	; set TMS9918 into 40-column mode
        CALL    VDP_PNT		; set TMS9918 Pattern Name Table Pointer
        CALL    VDP_PGT		; set TMS9918 Pattern Generator Table Pointer
        CALL    VDP_COLORS	; set TMS9918 foreground(white) background(black)
        CALL    VDP_LOAD2       ; set TMS9918 character bitmaps
 	CALL	VDP_SINE	; display initialization message on composite video;
;	CALL	PANIC
	CALL	PPK_INIT
	XOR	A
	RET


;
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

	JR	Z,N8V_VDAINI
	DEC	A
	JR	Z,N8V_VDAQRY
	DEC	A
	JR	Z,N8V_VDARES
	DEC	A
	JR	Z,N8V_VDASCS
	DEC	A
	JR	Z,N8V_VDASCP
	DEC	A
	JR	Z,N8V_VDASAT
	DEC	A
	JR	Z,N8V_VDASCO
	DEC	A
	JR	Z,N8V_VDAWRC
	DEC	A
	JR	Z,N8V_VDAFIL
	DEC	A
	JR	Z,N8V_VDASCR
	DEC	A
	JP	Z,PPK_STAT
	DEC	A
	JP	Z,PPK_FLUSH
	DEC	A
	JP	Z,PPK_READ
	CALL	PANIC

N8V_VDAINI:
	XOR	A
	RET

N8V_VDAQRY:
	CALL	PANIC
	
N8V_VDARES:
	JR	N8V_INIT
	
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

VDP_MODES:
        LD      C,CMDP
        LD      A,80
        OUT     (C),A           ; out(CMDP,80);
	NOP
        LD      A,129
        OUT     (C),A           ; out(CMDP,129);
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

VDP_LOADSET:

        LD      C,CMDP
        LD      A,0
        OUT     (C),A           ; out(CMDP,0);
	NOP
        LD      A,72
        OUT     (C),A           ; out(CMDP,72);

        LD      HL,CHARSET      ; set memory ptr to start of bitmaps
	LD	DE,2048
	LD	C,DATAP
VDP_LOADLOOP:
        LD      A,(HL)
	OUT	(C),A
	INC	HL
	DEC	DE
	LD	A,D
	OR	E
	JR	NZ,VDP_LOADLOOP
        RET

;-------------------------------------------------

VDP_LOAD2:

        LD      C,CMDP
        LD      A,0
        OUT     (C),A           ; out(CMDP,0);
	NOP
        LD      A,72
        OUT     (C),A           ; out(CMDP,72);
	NOP

        LD      HL,CHARSET      ; set memory ptr to start of bitmaps
        LD      DE,256
	LD	C,DATAP
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
	LD	HL,0
	CALL	VDP_WRVRAM

;        LD      HL,VDP_HELLO
;        LD      B,52
;        LD      C,DATAP
;        OTIR

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
	OUT	(C),H

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

;__________________________________________________________________________________________________
; IMBED COMMON PRALLEL PORT KEYBOARD DRIVER
;__________________________________________________________________________________________________
;
#INCLUDE "ppk.asm"
;
;__________________________________________________________________________________________________
; LOCAL DRIVER DATA
;__________________________________________________________________________________________________
;

VDP_LINE	.DB	0
VDP_COL		.DB	0
VDP_ATTR	.DB	240	; default to white on black
VDP_HELLO       .TEXT   "   N8-2312 TMS9918 Text Mode Init Done!!"
VDP_HELLOLEN	.DB	$-VDP_HELLO

;BYTE           .DB     0
BYTE2           .DB     0
BYTE3           .DB     0
BYTE4           .DB     0
BYTE5           .DB     0
BYTE6           .DB     0
BYTE7           .DB     0
BYTE8           .DB     0

CHARSET:
#INCLUDE "n8chars.inc"
