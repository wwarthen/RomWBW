;___BOOTAPP____________________________________________________________________________________________________________
;
; APPLICATION BOOT MANAGER
;
;   USED TO LOAD AN APPLICATION IMAGE BASED COPY OF THE SYSTEM
;   REFER TO BANKEDBIOS.TXT FOR MORE INFORMATION.
;______________________________________________________________________________________________________________________
;
; MEMORY MAP
;
;   LOC   LEN   DESC
;   ----- ----- --------------
;   $0000 $1000 BOOTAPP CODE
;   $1000 $1000 DBGMON IMAGE
;   $2000 $3000 CPM IMAGE
;   $5000 $3000 ZSYS IMAGE
;   $8000 *** END ***
; 
#INCLUDE "std.asm"
;
	.ORG	$100
;
	DI			; NO INTERRUPTS
	IM	1		; INTERRUPT MODE 1
	LD	SP,STACK	; PRIVATE STACK
;
	; BANNER
	CALL	NEWLINE
	LD	DE,STR_BANNER
	CALL	WRITESTR
;
MENU:
	CALL	NEWLINE
	CALL	NEWLINE
	LD	DE,STR_BOOTMENU
	CALL	WRITESTR
	CALL	CINUC
	CP	'M'			; MONITOR
	JP	Z,GOMON
	CP	'C'			; CP/M BOOT FROM ROM
	JP	Z,GOCPM
	CP	'Z'			; ZSYSTEM BOOT FROM ROM
	JP	Z,GOZSYS
;
	LD	DE,STR_INVALID
	CALL	WRITESTR
	JR	MENU
;
GOMON:
	LD	DE,STR_BOOTMON
	CALL	WRITESTR
	LD	HL,$1000
	LD	DE,$C000
	LD	BC,$1000
	LDIR
	JP	MON_SERIAL
;
GOCPM:
	LD	DE,STR_BOOTCPM
	CALL	WRITESTR
	LD	HL,$2000
	LD	DE,CPM_LOC
	LD	BC,$3000 - $400
	LDIR
#IF (PLATFORM == PLT_UNA)
	LD	DE,$0100	; BOOT DEV/UNIT/LU=0 (ROM DRIVE) 
#ELSE
	LD	DE,$0000	; BOOT DEV/UNIT/LU=0 (ROM DRIVE) 
#ENDIF
	JP	CPM_ENT
;
GOZSYS:
	LD	DE,STR_BOOTZSYS
	CALL	WRITESTR
	LD	HL,$5000
	LD	DE,CPM_LOC
	LD	BC,$3000 - $400
	LDIR
#IF (PLATFORM == PLT_UNA)
	LD	DE,$0100	; BOOT DEV/UNIT/LU=0 (ROM DRIVE) 
#ELSE
	LD	DE,$0000	; BOOT DEV/UNIT/LU=0 (ROM DRIVE) 
#ENDIF
	JP	CPM_ENT
;
; READ A CONSOLE CHARACTER AND CONVERT TO UPPER CASE
;
CINUC:
	CALL	CIN
	AND	7FH			; STRIP HI BIT
	CP	'A'			; KEEP NUMBERS, CONTROLS
	RET	C			; AND UPPER CASE
	CP	7BH			; SEE IF NOT LOWER CASE
	RET	NC
	AND	5FH			; MAKE UPPER CASE
	RET
;
#DEFINE CIOMODE_HBIOS
#INCLUDE "util.asm"
;
;	STRINGS
;_____________________________________________________________________________________________________________________________
;
STR_BOOTMON	.DB	"START MONITOR\r\n$"
STR_BOOTCPM	.DB	"BOOT CPM FROM ROM\r\n$"
STR_BOOTZSYS	.DB	"BOOT ZSYSTEM FROM ROM\r\n$"
STR_INVALID	.DB	"INVALID SELECTION\r\n$"
;
STR_BANNER	.DB	"\r\n", PLATFORM_NAME, " Boot Loader$"
STR_BOOTMENU	.DB	"\r\nBoot: (C)PM, (Z)System, (M)onitor,\r\n"
		.DB	"      (L)ist devices, or Device ID ===> $"
;
;______________________________________________________________________________________________________________________
;
; PAD OUT REMAINDER
;
	.FILL	$1000 - $,$FF	; PAD OUT REMAINDER
;
STACK	.EQU	$		; STACK IN SLACK SPACE
;
	.END
