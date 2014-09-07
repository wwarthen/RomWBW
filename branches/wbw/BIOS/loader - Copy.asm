;
;==================================================================================================
;   LOADER
;==================================================================================================
;
;  FIX!!!  NEED TO SWITCH FROM CBIOS CALLS TO HBIOS CALLS!!!
;
; INCLUDE GENERIC STUFF
;
#INCLUDE "std.asm"
#INCLUDE "syscfg.exp"
;
LDLOC	.EQU	$100		; LOAD IMAGE HERE BEFORE RELOCATING
STAMP	.EQU	$40		; LOC OF ROMWBW CBIOS ZERO PAGE STAMP
;
	.ORG	$8400
;
	; SETUP OUR STACK
	LD	SP,BL_STACK	; SET UP LOADER STACK
	
	; INITIALIZE IOBYTE(0x03) AND CURRENT DRIVE (0x04)
	LD	A,DEFIOBYTE
	LD	(3),A
	XOR	A
	LD	(4),A

;	; CALL CBIOS COLD BOOT WITH SPECIAL VALUE IN HL
;	; WHICH CAUSES IT TO RETURN HERE INSTEAD OF GOING TO CCP
	LD	H,'W'
	LD	L,~'W'
	CALL	CPM_ENT
	
	; BANNER
	CALL	NEWLINE
	LD	DE,STR_BANNER
	CALL	WRITESTR

	; INITIALIZE
#IF (PLATFORM == PLT_UNA)
	CALL	UNAINIT
#ELSE
	CALL	init
	CALL	NZ,PANIC
#ENDIF

	; RUN THE BOOT LOADER MENU
	JP	DOBOOTMENU
;
;__DOBOOT________________________________________________________________________________________________________________________ 
;
; PERFORM BOOT FRONT PANEL ACTION
;________________________________________________________________________________________________________________________________
;
DOBOOTMENU:
	CALL	NEWLINE
	CALL	NEWLINE

#IF (PLATFORM == PLT_UNA)
	CALL	SHOWALL
#ELSE
	CALL	showall
#ENDIF

	LD	DE,STR_BOOTMENU
	CALL	WRITESTR
	
#IF (DSKYENABLE)
	LD	HL,BOOT			; POINT TO BOOT MESSAGE	
	CALL 	SEGDISPLAY		; DISPLAY MESSAGE
#ENDIF

#IF (BOOTTYPE == BT_AUTO)
	LD	BC,1000 * BOOT_TIMEOUT
	LD	(BL_TIMEOUT),BC
#ENDIF

DB_BOOTLOOP:
;
; CHECK FOR CONSOLE BOOT KEYPRESS
;
#IF (UARTENABLE | ASCIENABLE | VDUENABLE | (PRPENABLE & PRPCONENABLE) | (PPPENABLE & PPPCONENABLE))
	CALL	CST
	OR	A
	JR	Z,DB_CONEND
	CALL	CINUC
	CP	'S'			; SETUP
	JR	Z,GOSETUP
	CP	'M'			; MONITOR
	JR	Z,GOMON
	CP	'R'			; ROM BOOT
	JR	Z,GOROM
	CP	'A'			; A-P, DISK BOOT
	JR	C,DB_INVALID
	CP	'P' + 1			; HMMM... 'M' DRIVE CONFLICTS WITH MONITOR SELECTION
	JR	NC,DB_INVALID
	SUB	'A'
	JR	GOBOOTDISK
DB_CONEND:
#ENDIF
;
; CHECK FOR DSKY BOOT KEYPRESS
;
#IF (DSKYENABLE)
	CALL	KY_STAT			; GET KEY FROM KB INTO A
	OR	A
	JR	Z,DB_DSKYEND
	CALL	KY_GET
	CP	KY_GO			; GO = MONITOR
	JR	Z,GOMONDSKY 
	CP	KY_BO			; BO = BOOT ROM
	JR	Z,GOROM
	CP	0AH			; A-F, DISK BOOT
	JR	C,DB_INVALID
	CP	0FH + 1
	JR	NC,DB_INVALID
	SUB	0AH
	JR	GOBOOTDISK
;	LD	HL,BOOT			; POINT TO BOOT MESSAGE
;	LD	A,00H			; BLANK OUT SELECTION,IT WAS INVALID
;	LD	(HL),A			; STORE IT IN DISPLAY BUFFER
;	CALL	SEGDISPLAY		; DISPLAY THE BUFFER
DB_DSKYEND:
#ENDIF
;
; IF CONFIGURED, CHECK FOR AUTOBOOT TIMEOUT
;
#IF (BOOTTYPE == BT_AUTO)
	
	; DELAY FOR 1MS TO MAKE TIMEOUT CALC EASY
	LD	DE,40
	CALL	VDELAY

	; CHECK/INCREMENT TIMEOUT
	LD	BC,(BL_TIMEOUT)
	DEC	BC
	LD	(BL_TIMEOUT),BC
	LD	A,B
	OR	C
	JR	NZ,DB_BOOTLOOP

	; TIMEOUT EXPIRED, PERFORM DEFAULT BOOT ACTION
	LD	A,BOOT_DEFAULT
	CP	'M'			; MONITOR
	JR	Z,GOMON
	CP	'R'			; ROM BOOT
	JR	Z,GOROM
	CP	'A'			; A-P, DISK BOOT
	JR	C,DB_INVALID
	CP	'P' + 1			; HMMM... DRIVE M CONFLICTS WITH "MONITOR" SELECTION
	JR	NC,DB_INVALID
	SUB	'A'
	JR	GOBOOTDISK
#ENDIF

	JP	DB_BOOTLOOP
;
; BOOT OPTION PROCESSING
;
DB_INVALID:
	LD	DE,STR_INVALID
	CALL	WRITESTR
	JP	DOBOOTMENU
;
GOSETUP:
	LD	DE,STR_SETUP
	CALL	WRITESTR
	JP	DOSETUPMENU
;
GOMON:
	LD	DE,STR_BOOTMON
	CALL	WRITESTR
	JP	MON_SERIAL
;
GOMONDSKY:
	LD	DE,STR_BOOTMON
	CALL	WRITESTR
	JP	MON_DSKY
;
GOROM:
	LD	DE,STR_BOOTROM
	CALL	WRITESTR
	JP	CPM_ENT
;
GOBOOTDISK:
	LD	C,A
	LD	DE,STR_BOOTDISK
	CALL	WRITESTR
	JP	BOOTDISK
;
; BOOT FROM DISK DRIVE
;
BOOTDISK:
	LD	DE,STR_BOOTDISK1
	CALL	WRITESTR

	; SAVE BOOT DRIVE
	LD	A,C
	LD	(BL_BOOTDRIVE),A
	
;	; SAVE BOOT DEVICE/SLICE
;	CALL	CBIOS_GETDSK
;	LD	A,B
;	LD	(BL_BOOTDEVICE),A
;	LD	(BL_BOOTLU),DE
	
	; SELECT THE REQUESTED DRIVE
	LD	A,(BL_BOOTDRIVE)	; GET CBIOS BOOT DRIVE BACK
	LD	C,A			; MOVE TO C
	LD	E,0			; BIT0=0 IN E MEANS FIRST SELECT
	CALL	CBIOS_SELDSK		; CALL CBIOS DSKSEL TO GET DPH ADDRESS

	; IF HL=0, SELDSK FAILED!  SELECTED DRIVE IS NOT AVAILABLE
	LD	A,H
	OR	L
	JP	Z,DB_NODISK

;	; *DEBUG* PRINT DPH ADDRESS
;	CALL	NEWLINE
;	PUSH	HL
;	POP	BC
;	CALL	PRTHEXWORD
	
	; BUMP HL TO POINT TO DPB AND LOAD IT
	LD	DE,10
	ADD	HL,DE			; HL = ADDRESS OF ADDRESS OF DPB
	LD	A,(HL)			; DEREFERENCE
	INC	HL
	LD	H,(HL)
	LD	L,A			; NOW HL = ADDRESS OF DPB

;	; *DEBUG* PRINT DPB ADDRESS
;	CALL	PC_SPACE
;	PUSH	HL
;	POP	BC
;	CALL	PRTHEXWORD

	; FIRST WORD OF DPB IS SECTORS PER TRACK, SAVE IT
	LD	C,(HL)
	INC	HL
	LD	B,(HL)			; NOW BC = SECTORS PER TRACK
;	LD	BC,36			; *DEBUG*
	LD	(BL_LDSPT),BC		; SAVE IT

	LD	DE,12			; POINT TO DPB OFFSET FIELD
	ADD	HL,DE
	LD	A,(HL)
	INC	HL
	OR	(HL)
	JP	Z,DB_NOBOOT		; IF OFFSET = ZERO, THERE IS NO BOOT AREA!!!
	
;	; *DEBUG* PRINT SECTORS PER TRACK
;	CALL	PC_SPACE
;	CALL	PRTHEXWORD
	
	; SETUP TO LOAD METADATA
	LD	BC,BL_METABUF
	CALL	CBIOS_SETDMA
	LD	BC,0
	CALL	CBIOS_SETTRK
	LD	BC,11
	CALL	CBIOS_SETSEC

	; READ META DATA
	CALL	CBIOS_READ
	OR	A
	JP	NZ,DB_ERR
	
;	; PRINT SIGNATURE
;	CALL	NEWLINE
;	LD	DE,STR_SIG
;	CALL	WRITESTR
;	LD	BC,(BL_SIG)
;	CALL	PRTHEXWORD
	
	; CHECK SIGNATURE
	LD	BC,(BL_SIG)
	LD	A,$A5
	CP	B
	JP	NZ,DB_NOBOOT
	LD	A,$5A
	CP	C
	JP	NZ,DB_NOBOOT

	; PRINT CPMLOC VALUE
	CALL	NEWLINE
	LD	DE,STR_CPMLOC
	CALL	WRITESTR
	LD	BC,(BL_CPMLOC)
	CALL	PRTHEXWORD

	; PRINT CPMEND VALUE
	CALL	PC_SPACE
	LD	DE,STR_CPMEND
	CALL	WRITESTR
	LD	BC,(BL_CPMEND)
	CALL	PRTHEXWORD
	
	; PRINT CPMENT VALUE
	CALL	PC_SPACE
	LD	DE,STR_CPMENT
	CALL	WRITESTR
	LD	BC,(BL_CPMENT)
	CALL	PRTHEXWORD
	CALL	PC_SPACE

	LD	DE,STR_LABEL
	CALL	WRITESTR
	LD	A,(BL_TERM)		; Display Disk Label if Present
	CP	'$'			; (dwg 2/7/2012)
	JP	NZ,NO_LABEL		; pick up string terminator for label
	LD	DE,BL_LABEL 		; if it is there, then a printable
	CALL	WRITESTR		; label is there as well even if spaces.
NO_LABEL:

;
; SETUP BL_CPM... STUFF
;
	; COMPUTE BL_SIZ
	LD	HL,(BL_CPMEND)
	LD	DE,(BL_CPMLOC)
	SCF
	CCF
	SBC	HL,DE
	LD	(BL_LDSIZ),HL
	
	; SETUP FOR DATA LOAD
	LD	HL,LDLOC
	LD	(BL_LDCLOC),HL
	LD	DE,(BL_LDSIZ)
	ADD	HL,DE
	LD	(BL_LDEND),HL
	LD	BC,0
	LD	(BL_LDCTRK),BC
	LD	BC,12
	LD	(BL_LDCSEC),BC

;	; *DEBUG* PRINT SPT, SEC, TRK, SIZ, END
;	CALL	NEWLINE
;	LD	BC,(BL_LDSPT)
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_LDCSEC)
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_LDCTRK)
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_LDSIZ)
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_LDEND)
;	CALL	PRTHEXWORD

	; LOADING MESSAGE
	CALL	NEWLINE
	LD	DE,STR_LOADING
	CALL	WRITESTR
;
; LOADING LOOP
;
DB_LOOP:
	; SETUP TO READ SECTOR
	LD	BC,(BL_LDCTRK)
;	CALL	NEWLINE		; *DEBUG*
;	CALL	PRTHEXWORD	; *DEBUG*
	CALL	CBIOS_SETTRK

	LD	BC,(BL_LDCSEC)
;	CALL	PC_SPACE	; *DEBUG*
;	CALL	PRTHEXWORD	; *DEBUG*
	CALL	CBIOS_SETSEC
	LD	BC,(BL_LDCLOC)
;	CALL	PC_SPACE	; *DEBUG*
;	CALL	PRTHEXWORD	; *DEBUG*
	CALL	CBIOS_SETDMA

	; READ IT
	CALL	CBIOS_READ
	OR	A
	JP	NZ,DB_ERR
	CALL	PC_PERIOD
	
;	; *DEBUG* PRINT FIRST WORD OF DATA LOADED
;	CALL	PC_SPACE
;	LD	HL,(BL_LDCLOC)
;	LD	A,(HL)
;	INC	HL
;	LD	B,(HL)
;	LD	C,A
;	CALL	PRTHEXWORD

	; INCREMENT MEMORY POINTER
	LD	HL,(BL_LDCLOC)
	LD	DE,128
	ADD	HL,DE
	LD	(BL_LDCLOC),HL
	
	; CHECK TO SEE IF WE ARE DONE
	LD	DE,(BL_LDEND)
	LD	A,H
	CP	D
	JR	NZ,DB_CONT
	LD	A,L
	CP	E
	JR	NZ,DB_CONT
	
	JP	DB_DONE

DB_CONT:
	; INCREMENT SECTOR
	LD	BC,(BL_LDCSEC)
	INC	BC
	LD	(BL_LDCSEC),BC

	; TEST FOR END OF TRACK (LDCSEC/BC == LDSPT/DE)
	LD	DE,(BL_LDSPT)
	LD	A,C
	CP	E
	JR	NZ,DB_LOOP	; B != D, NOT AT EOT
	LD	A,B
	CP	D
	JR	NZ,DB_LOOP	; C != E, NOT AT EOT

	; END OF TRACK, RESET SECTOR & INCREMENT TRACK
	LD	BC,0
	LD	(BL_LDCSEC),BC
	LD	BC,(BL_LDCTRK)
	INC	BC
	LD	(BL_LDCTRK),BC

	JP	DB_LOOP
	
DB_NODISK:
	; SELDSK DID NOT LIKE DRIVE SELECTION
	LD	DE,STR_NODISK
	CALL	WRITESTR
	JP	DOBOOTMENU

DB_NOBOOT:
	; DISK IS NOT BOOTABLE
	LD	DE,STR_NOBOOT
	CALL	WRITESTR
	JP	DOBOOTMENU

DB_ERR:
	; I/O ERROR DURING BOOT ATTEMPT
	LD	DE,STR_BOOTERR
	CALL	WRITESTR
	JP	DOBOOTMENU

DB_DONE:
	CALL	NEWLINE
;	; *DEBUG*
;	CALL	NEWLINE
;	LD	BC,LDLOC
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_CPMLOC)
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_LDSIZ)
;	CALL	PRTHEXWORD
;	CALL	PC_SPACE
;	LD	BC,(BL_CPMENT)
;	CALL	PRTHEXWORD

;	JP	DOBOOTMENU		; *DEBUG*

	; ALL DONE, NOW RELOCATE IMAGE BY COPYING
	LD	DE,(BL_LDSIZ)		; BYTES TO MOVE
	LD	HL,(BL_CPMLOC)
	ADD	HL,DE
	DEC	HL			; HL = PTR TO DEST (TOP)
	PUSH	HL			; SAVE IT
	LD	HL,LDLOC
	ADD	HL,DE
	DEC	HL			; HL = PTR TO SRC (TOP)
	POP	DE			; RECOVER DEST PTR
	LD	BC,(BL_LDSIZ)		; BC = BYTES TO COPY
	LDDR

;	; PATCH BOOT DRIVE INFO INTO CONFIG DATA
;	LD	A,BID_HB
;	CALL	HB_SETBNK
;	CALL	PATBI
;	LD	A,BID_USR
;	CALL	HB_SETBNK

	; JUMP TO COLD BOOT ENTRY
	LD	HL,(BL_CPMENT)
	JP	(HL)

PATBI:
	; PATCH BOOT DRIVE INFO INTO CONFIG DATA
	LD	HL,$200 + DISKBOOT	; LOCATION OF BOOTINFO IN SYSCFG IN RAM PAGE 1
	LD	A,TRUE			; BOOT FROM DISK = TRUE
	LD	(HL),A			; SAVE IT
	INC	HL
	LD	A,(BL_BOOTDEVICE)	; GET BOOT DEVICE/UNIT
	LD	(HL),A			; SAVE IT
	INC	HL
	LD	DE,(BL_BOOTLU)		; GET BOOT LU
	LD	(HL),E			; SAVE LSB
	INC	HL
	LD	(HL),D			; SAVE MSB
	RET
;
;
;
DOSETUPMENU:
	LD	DE,STR_SETUPMENU
	CALL	WRITESTR
	CALL	CINUC

	CP	'F'			; FORMAT RAM DISK
	JP	Z,FMTRAMDSK
	CP	'X'			; EXIT
	JP	Z,DOBOOTMENU
	JP	DOSETUPMENU		; NO VALID KEY, LOOP	
;
FMTRAMDSK:
	JP	DOSETUPMENU
;
#IF (DSKYENABLE)
;
;	
;__SEGDISPLAY________________________________________________________________________________________
;
;  DISPLAY CONTENTS OF DISPLAYBUF IN DECODED HEX BITS 0-3 ARE DISPLAYED DIG, BIT 7 IS DP     
;____________________________________________________________________________________________________
;
SEGDISPLAY:
	PUSH	AF			; STORE AF
	PUSH	BC			; STORE BC
	PUSH	HL			; STORE HL
	LD	BC,0007H	
	ADD	HL,BC
	LD	B,08H			; SET DIGIT COUNT
	LD	A,40H | 30H		; SET CONTROL PORT 7218 TO OFF
	OUT	(PPIC),A		; OUTPUT
	CALL 	DELAY			; WAIT
	LD	A,0F0H			; SET CONTROL TO 1111 (DATA COMING, HEX DECODE,NO DECODE, NORMAL)

SEGDISPLAY1:				;
	OUT	(PPIA),A		; OUTPUT TO PORT
	LD	A,80H | 30H		; STROBE WRITE PULSE WITH CONTROL=1
	OUT	(PPIC),A		; OUTPUT TO PORT
	CALL 	DELAY			; WAIT
	LD	A,40H | 30H		; SET CONTROL PORT 7218 TO OFF
	OUT	(PPIC),A		; OUTPUT

SEGDISPLAY_LP:		
	LD	A,(HL)			; GET DISPLAY DIGIT
	OUT	(PPIA),A		; OUT TO PPIA
	LD	A,00H | 30H		; SET WRITE STROBE
	OUT	(PPIC),A		; OUT TO PPIC
	CALL	DELAY			; DELAY
	LD	A,40H | 30H		; SET CONTROL PORT OFF
	OUT	(PPIC),A		; OUT TO PPIC
	CALL	DELAY			; WAIT
	DEC	HL			; INC POINTER
	DJNZ	SEGDISPLAY_LP		; LOOP FOR NEXT DIGIT
	POP	HL			; RESTORE HL
	POP	BC			; RESTORE BC
	POP	AF			; RESTORE AF
	RET
#ENDIF
;
;__TEXT_STRINGS_________________________________________________________________________________________________________________ 
;
;	STRINGS
;_____________________________________________________________________________________________________________________________
;
STR_BOOTDISK	.DB	"BOOT FROM DISK\r\n$"
STR_BOOTDISK1	.DB	"\r\nReading disk information...$"
STR_BOOTMON	.DB	"START MONITOR\r\n$"
STR_BOOTROM	.DB	"BOOT FROM ROM\r\n$"
STR_INVALID	.DB	"INVALID SELECTION\r\n$"
STR_SETUP	.DB	"SYSTEM SETUP\r\n$"
STR_SIG		.DB	"SIGNATURE=$"
STR_CPMLOC	.DB	"LOC=$"
STR_CPMEND	.DB	"END=$"
STR_CPMENT	.DB	"ENT=$"
STR_LABEL	.DB	"LABEL=$"
STR_LOADING	.DB	"\r\nLoading$"
STR_NODISK	.DB	"\r\nNo disk!$"
STR_NOBOOT	.DB	"\r\nDisk not bootable!$"
STR_BOOTERR	.DB	"\r\nBoot failure!$"
;
STR_BANNER	.DB	"\r\n", PLATFORM_NAME, " Boot Loader$"
STR_BOOTMENU	.DB	"\r\nBoot: (M)onitor, (R)OM, or Drive Letter ===> $"
;
STR_SETUPMENU:
	.DB	"\r\n\r\n", PLATFORM_NAME, " Setup & Configuration v", BIOSVER
	.DB	" (", BIOSBLD, "-", TIMESTAMP, ")\r\n\r\n"
;	.DB	"(F)ormat RAM Disk\r\n"
	.DB	"e(X)it Setup\r\n"
	.DB  	"\r\n===> $"
;
	.IF DSKYENABLE
BOOT:
;		  .    .               t     o    o      b
	.DB 	00H, 00H, 80H, 80H, 094H, 09DH, 09DH, 09FH
	.ENDIF
;
#DEFINE CIOMODE_HBIOS
#DEFINE	DSKY_KBD
#INCLUDE "util.asm"
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

#IF (PLATFORM == PLT_UNA)

UNAINIT:

	CALL	NEWLINE
	PRTS("UNA $")

	; UNA BIOS INFORMATION
	LD	C,$FA			; UNA FUNC GET BIOS INFO
	LD	B,4			; UNA SUBFUNC BIOS DATE AND VER
	CALL	$FFFD			; CALL UNA

	PUSH	DE
	PUSH	BC
	LD	A,D
	CALL	PRTDECB
	CALL	PC_PERIOD
	LD	A,E
	AND	$$7F
	CALL	PRTDECB
	CALL	PC_PERIOD
	POP	BC
	LD	A,B
	CALL	PRTDECB
	POP	DE
	BIT	7,E
	JR	Z,NOALPHA
	PRTS(" Alpha$")
NOALPHA:
	CALL	PC_SPACE
	CALL	PC_LPAREN
	PUSH	HL
	POP	BC
	CALL	PRTHEXWORD
	CALL	PC_RPAREN
	
	; UNA DISK INFORMATION
	CALL	NEWLINE
	CALL	NEWLINE
	LD	B,0		; INITIAL UNIT NUM
	LD	C,$48
	CALL	$FFFD		; GET INFO
	LD	C,L		; SAVE UNIT COUNT IN C
	
DSKINF1:
	LD	A,B		; LOAD UNIT
	CP	C		; UNIT = COUNT?
	JR	Z,DSKINFX	; EXIT IF DONE
	PUSH	BC		; SAVE CUR UNIT AND UNIT COUNT
	CALL	DSKINF2		; DISPLAY UNIT INFO
	POP	BC		; RECOVER UNIT AND COUNT
	INC	B		; NEXT UNIT
	JR	DSKINF1		; LOOP

DSKINF2:
	PUSH	BC		; SAVE CURRENT UNIT NUM
	
	PRTS("   Unit $")
	LD	A,B
	CALL	PRTHEXBYTE
	CALL	PC_COLON
	CALL	PC_SPACE

	; GET INFO
	LD	C,$48		; GET INFO
	CALL	$FFFD		; DO IT
	CALL	PC_LBKT
	LD	A,D
	CALL	PRTHEXBYTE
	CALL	PC_SPACE
	LD	A,E
	CALL	PRTHEXBYTE
	CALL	PC_SPACE
	LD	A,L
	CALL	PRTHEXBYTE
	CALL	PC_SPACE
	LD	A,H
	CALL	PRTHEXBYTE
	CALL	PC_RBKT
	CALL	PC_SPACE
	
	; GET CAPACITY
	POP	BC		; RESTORE CURRENT UNIT NUM
	LD	C,$45
	LD	DE,$9000
	CALL	$FFFD
	PUSH	HL
	PUSH	DE
	LD	A,B
	CALL	PRTHEXBYTE
	CALL	PC_COLON
	POP	BC
	CALL	PRTHEXWORD
	POP	BC
	CALL	PRTHEXWORD

	CALL	NEWLINE
	RET

DSKINFX:
	RET
	
SHOWALL:
	RET

#ELSE
;
; Initialization
;
init:
;
;	; locate cbios function table address
;	ld	hl,(restart+1)	; load address of CP/M restart vector
;	ld	de,-3		; adjustment for start of table
;	add	hl,de		; HL now has start of table
;	ld	(cbftbl),hl	; save it
;
	; get location of config data and verify integrity
	ld	hl,STAMP	; HL := adr of RomWBW zero page stamp
	ld	a,(hl)		; get first byte of RomWBW marker
	cp	'W'		; match?
	jp	nz,errinv	; abort with invalid config block
	inc	hl		; next byte (marker byte 2)
	ld	a,(hl)		; load it
	cp	~'W'		; match?
	jp	nz,errinv	; abort with invalid config block
	inc	hl		; next byte (major/minor version)
	ld	a,(hl)		; load it
	cp	RMJ << 4 | RMN	; match?
	jp	nz,errver	; abort with invalid os version
	inc	hl		; bump past
	inc	hl		; ... version info
;
	; dereference HL to point to CBIOS extension data
	ld	a,(hl)		; dereference HL
	inc	hl		;   ... to point to
	ld	h,(hl)		;   ... ROMWBW config data block
	ld	l,a		;   ... in CBIOS
;
	; get location of drive map
	inc	hl		; bump two bytes
	inc	hl		; ... to drive map address
	ld	a,(hl)		; dereference HL
	inc	hl		;   ... to point to
	ld	h,(hl)		;   ... drivemap data
	ld	l,a		;   ... in CBIOS
	ld	(maploc),hl	; and save it
;	
 	; return success
	xor	a		; signal success
	ret			; return
;
; Display all active drive letter assignments
;
showall:
	ld	hl,(maploc)	; HL = address of drive map
	dec	hl		; point to prior byte with map entry count
	ld	b,(hl)		; put it in b for loop counter
	ld	c,0		; map index (drive letter)
;
	ld	a,b		; load count
	or	a		; set flags
	ret	z		; bail out if zero
;
showall1:	; loop
	ld	a,c
	push	bc
	call	showone
	pop	bc
	inc	c
	djnz	showall1
	ret
;
; Display drive letter assignment for the drive num in A
;
showone:
;
	push	af		; save the incoming drive num
;
	PRTX(indent)
;
	; setup HL to point to desired entry in table
	pop	af
	push	af
	ld	hl,(maploc)	; HL = address of drive map
	rlca
	rlca
	call	ADDHLA		; HL = address of drive map table entry
	pop	af
;
	; render the drive letter based on table index
	add	a,'A'		; convert to alpha
	call	COUT		; print it
	ld	a,':'		; conventional color after drive letter
	call	COUT		; print it
	ld	a,'='		; use '=' to represent assignment
	call 	COUT		; print it
;
	; render the map entry
	ld	a,(hl)		; load device/unit
	rrca			; isolate high nibble (device)
	rrca			;   ...
	rrca			;   ...
	rrca			;   ... into low nibble
	and	$0F		; mask out undesired bits
	call	prtdev		; print device mnemonic
	ld	a,(hl)		; load device/unit again
	and	$0F		; isolate unit num
	call	prtdecb		; print it
	inc	hl		; point to slice num
	ld	a,':'		; colon to separate slice
	call	COUT		; print it
	ld	a,(hl)		; load slice num
	call	prtdecb		; print it
;
	call	NEWLINE
;
	ret
;
; Print device mnemonic based on device number in A
;
prtdev:
	push	hl		; save HL
	add	a,a		; multiple A by two for word table
	ld	hl,devtbl	; point to start of device name table
	call	ADDHLA		; add A to hl to point to table entry
	ld	a,(hl)		; dereference hl to loc of device name string
	inc	hl		;   ...
	ld	d,(hl)		;   ...
	ld	e,a		;   ...
	ex	de,hl
	call	PRTSTR		; print the device nmemonic
	ex	de,hl
	pop	hl		; restore HL
	ret			; done
;
; Print value of A or HL in decimal with leading zero suppression
; Use prtdecb for A or prtdecw for HL
;
prtdecb:
	push	hl
	ld	h,0
	ld	l,a
	call	PRTDEC		; print it
	pop	hl
	ret
;
; Errors
;
errinv:	; invalid CBIOS, zp signature not found
	ld	de,msginv
	jr	err
;
errver:	; CBIOS version is not as expected
	ld	de,msgver
	jr	err
;
errdrv:	; CBIOS version is not as expected
	push	af
	PRTX(msgdrv1)
	pop	af
	add	a,'A'
	call	COUT
	ld	de,msgdrv2
	jr	err1
;
errdev:	; invalid device name
	ld	de,msgdev
	jr	err
;
errnum:	; invalid number parsed, overflow
	ld	de,msgnum
	jr	err
;
err:	; print error string and return error signal
	call	NEWLINE		; print newline
	call	NEWLINE		; print newline
;
err1:	; without the leading crlf
	ld	hl,msgerr
	call	PRTSTR
	ex	de,hl
	call	PRTSTR
;
err2:	; without the string
	call	NEWLINE		; print newline
	or	$FF		; signal error
	ret			; done
;
; Messages
;
indent	.db	"    $"
msgerr	.db	"ERROR: $"
msginv	.db	"Unexpected CBIOS (signature missing)$"
msgver	.db	"Unexpected CBIOS version$$"
msgdrv1	.db	"Invalid drive letter ($"
msgdrv2	.db	":)$"
msgdev	.db	"Invalid device name$"
msgnum	.db	"Unit or slice number invalid$"
;
; Data
;
maploc	.dw	0		; location of drive map
;
;
devtbl:				; device table
	.dw	dev00, dev01, dev02, dev03
	.dw	dev04, dev05, dev06, dev07
	.dw	dev08, dev09, dev10, dev11
	.dw	dev12, dev13, dev14, dev15
;
devunk	.db	"?$"
dev00	.db	"MD$"
dev01	.db	"FD$"
dev02	.db	"RAMF$"
dev03	.db	"IDE$"
dev04	.db	"ATAPI$"
dev05	.db	"PPIDE$"
dev06	.db	"SD$"
dev07	.db	"PRPSD$"
dev08	.db	"PPPSD$"
dev09	.db	"HDSK$"
dev10	.equ	devunk
dev11	.equ	devunk
dev12	.equ	devunk
dev13	.equ	devunk
dev14	.equ	devunk
dev15	.equ	devunk

#ENDIF

;
;==================================================================================================
;   WORKING DATA STORAGE
;==================================================================================================
;
; WE USE A 256 BYTE AREA JUST AT THE START OF RAM (TOP 32KB)
; FOR WORKING DATA STORAGE.  THE FIRST 128 BYTES ARE RESERVED
; TO LOAD THE BLOCK CONTAINING THE BOOT LOAD METADATA.  THE
; METADATA IS IN THE LAST 6 BYTES OF THIS BLOCK.
;
;__________________________________________________________________________________________________
;
BL_METABUF	.EQU	$
BL_SIG		.DW	0	; SIGNATURE (WILL BE 0A55AH IF SET)
BL_PLATFORM	.DB	0	; Formatting Platform
BL_DEVICE	.DB	0	; Formatting Device
BL_FORMATTER	.FILL	8,0	; Formatting Program
BL_DRIVE	.DB	0	; Physical Disk Drive #
BL_LU		.DW	0	; Logical Unit (slice)
;
		.FILL	(BL_METABUF + 128) - $ - 32
BL_PROTECT	.DB	0	; write protect boolean
BL_UPDATES	.DW	0	; update counter
BL_RMJ		.DB	0	; RMJ Major Version Number
BL_RMN		.DB	0	; RMN Minor Version Number
BL_RUP		.DB	0	; RUP Update Number
BL_RTP		.DB	0	; RTP Patch Level
BL_LABEL	.FILL	16,0	; 16 Character Drive Label
BL_TERM		.DB	0	; LABEL TERMINATOR ('$')
BL_BILOC	.DW	0	; LOC TO PATCH BOOT DRIVE INFO TO (IF NOT ZERO)
BL_CPMLOC	.DW	0	; FINAL RAM DESTINATION FOR CPM/CBIOS
BL_CPMEND	.DW	0	; END ADDRESS FOR LOAD
BL_CPMENT	.DW	0	; CP/M ENTRY POINT (CBIOS COLD BOOT)
;
; WORKING STORAGE STARTS HERE
;
BL_STACKSIZ	.EQU	40H
		.FILL	BL_STACKSIZ,0
BL_STACK	.EQU	$
;
BL_LDSPT	.DW	0		; SECTORS PER TRACK FOR LOAD DEVICE
BL_LDCTRK	.DW	0		; CURRENT TRACK FOR LOAD
BL_LDCSEC	.DW	0		; CURRENT SECTOR FOR LOAD
BL_LDCLOC	.DW	0		; CURRENT MEM LOC BEING LOADED
BL_LDEND	.DW	0		; RAM LOCATION TO STOP LOAD
BL_LDSIZ	.DW	0		; SIZE OF CPM/CBIOS IMAGE TO LOAD
BL_TIMEOUT	.DW	0		; AUTOBOOT TIMEOUT COUNTDOWN COUNTER
BL_BOOTDRIVE	.DB	0		; TEMPORARY STORAGE FOR BOOT DRIVE
BL_BOOTDEVICE	.DB	0		; TEMPORARY STORAGE FOR BOOT DEVICE/UNIT
BL_BOOTLU	.DW	0		; TEMPORARY STORAGE FOR BOOT LU
BL_TMPDRV	.DB	0		; TEMP STORAGE FOR DRIVE LETTER
BL_TMPLU	.DW	0		; TEMP STORAGE FOR LU
;
;==================================================================================================
;   FILL REMAINDER OF BANK
;==================================================================================================
;
SLACK:		.EQU	(9000H - $)
		.FILL	SLACK
;
		.ECHO	"LOADER space remaining: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"
	.END
