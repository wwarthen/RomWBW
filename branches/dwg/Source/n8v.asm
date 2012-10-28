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
	; INIT TMS9918 HERE...
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
;

N8V_MODES:
	; outp(CMDP,80);
	; outp(CMDP,129);
	RET

N8V_PNT:
	; outp(CMDP,0);
	; outp(CMDP,130);
	RET

N8V_PGT:
	; outp(CMDP,1);
	; outp(CMDP,132);
	RET

N8V_COLORS:
	; outp(CMDP,240);
	; outp(CMDP,135);
	RET

N8V_LOADCHARS:
	; out(CMDP,0);
	; out(CMDP,72);
	; index=0;
	; for(c=0;c<256;c++P) {
	; 	for(d=0;d<8;d++) {
	;		out(DATAP,charset[index++]);
	;	}
	; }
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

N8V_WRVRAM:
	; vdp_wrvram(o)
	; {
	; 	byte1 = o & 255;
	;	byte2 = (o >> 8) | 0x40;
	;	out(CMDP,byte1);
	;	out(CMDP,byte2);
	; }
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

CHARSET:
#INCLUDE "n8chars.inc"
