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
;
; 12/1/2011 dwg - 
DRIVES	.EQU	1	; control diskmap display function
;
	.ORG	8400H
;
	; SETUP OUR STACK
	LD	SP,BL_STACK	; SET UP LOADER STACK
	
	; SETUP CBIOS IOBYTE
	LD	A,DEFIOBYTE		; LOAD DEFAULT IOBYTE
	LD	(IOBYTE),A		; STORE IT
	
#IF (PLATFORM != PLT_N8)
	IN	A,(RTC)		; RTC PORT, BIT 6 HAS STATE OF CONFIG JUMPER
;	LD	A,40H		; *DEBUG* SIMULATE JUMPER OPEN
;	LD	A,00H		; *DEBUG* SIMULATE JUMPER SHORTED
	AND	40H		; ISOLATE BIT 6
	JR	Z,INIT1		; IF BIT6=0, SHORTED, USE ALT IOBYTE
	LD	A,DEFIOBYTE	; LOAD DEF IOBYTE VALUE
	JR	INIT2		; CONTINUE
INIT1:
	LD	A,ALTIOBYTE	; LOAD ALT IOBYTE VALUE
INIT2:	
	LD	(IOBYTE),A	; SET THE ACTIVE IOBYTE
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
;	LD	DE,STR_BANNER
;	CALL	WRITESTR

	CALL	LISTDRIVES
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
#IF (UARTENABLE | VDUENABLE | (PRPENABLE & PRPCONENABLE) | (PPPENABLE & PPPCONENABLE))
	CALL	CST
	OR	A
	JR	Z,DB_CONEND
	CALL	CINUC
	CP	'S'			; SETUP
	JR	Z,GOSETUP
	CP	'M'			; MONITOR
	JR	Z,GOMONUART
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
	JR	Z,GOMONUART
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
GOMONUART:
	LD	DE,STR_BOOTMON
	CALL	WRITESTR
	JP	MON_UART
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
	
	; SAVE BOOT DEVICE/SLICE
	CALL	CBIOS_GETDSK
	LD	A,B
	LD	(BL_BOOTDEVICE),A
	LD	(BL_BOOTLU),DE
	
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
	CALL	WRITESTR		; label is there as wellm even if spaces.
NO_LABEL:				;

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
	LD	HL,BL_LDLOC
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
;	LD	BC,BL_LDLOC
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
	LD	HL,BL_LDLOC
	ADD	HL,DE
	DEC	HL			; HL = PTR TO SRC (TOP)
	POP	DE			; RECOVER DEST PTR
	LD	BC,(BL_LDSIZ)		; BC = BYTES TO COPY
	LDDR

	; PATCH BOOT DRIVE INFO INTO CONFIG DATA
	LD	A,1
	CALL	RAMPG
	LD	HL,$020D		; LOCATION OF BOOTINFO IN SYSCFG IN RAM PAGE 0
	CALL	PATBI
	CALL	RAMPGZ

	; JUMP TO COLD BOOT ENTRY
	LD	HL,(BL_CPMENT)
	JP	(HL)

PATBI:
	; PATCH BOOT DRIVE INFO AT ADDRESS SPECIFIED BY HL
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
; DISPLAY LIST OF DRIVES
;
LISTDRIVES:
#IF (DRIVES)
	call	NEWLINE

	ld	c,0		; start with drive 0
	ld	b,16		; loop through 16 drives
dmloop:
	push	bc		; preserve drive and loop counter
	ld	a,c		; drive letter into a
	add	a,'A'		; convert to alpha version of drive letter
	ld	(BL_TMPDRV),a	; save it for printing if needed
	call	CBIOS_GETDSK	; get drive into, c still has drive number
	or	a		; set flags on result
	jr	nz,dmdone	; error, skip this drive
	ld	(BL_TMPLU),de	; save lu for later
	ld	a,b		; device/unit into a for matching below
	
	ld	de,str_devrom
	cp	DIODEV_MD+0	; ROM
	jr	z,dmprt
	
	ld	de,str_devram
	cp	DIODEV_MD+1	; RAM
	jr	z,dmprt
	
	and	$f0		; after ram/rom, compare on high nibble only

	ld	de,str_devfd
	cp	DIODEV_FD	; floppy disk
	jr	z,dmprt
	
	ld	de,str_devide
	cp	DIODEV_IDE	; IDE
	jr	z,dmprt
	
	ld	de,str_devatapi
	cp	DIODEV_ATAPI	; ATAPI
	jr	z,dmprt
	
	ld	de,str_devppide
	cp	DIODEV_PPIDE	; PPIDE
	jr	z,dmprt
	
	ld	de,str_devsd
	cp	DIODEV_SD	; Generic SD
	jr	z,dmprt
	
	ld	de,str_devprpsd
	cp	DIODEV_PRPSD	; PropIO SD
	jr	z,dmprt
	
	ld	de,str_devpppsd
	cp	DIODEV_PPPSD	; ParPortProp SD
	jr	z,dmprt

	ld	de,str_devhdsk
	cp	DIODEV_HDSK	; SIMH HDSK
	jr	z,dmprt

	jr	dmdone

dmprt:
	ld	a,(BL_TMPDRV)		; recover drive letter
	call	COUT			; print it
	ld	a,'='			; load equal sign
	call	COUT			; print it
	call	WRITESTR		; print device name now (str ptr in de)
	ld	a,b			; a = device/unit
	and	$f0			; isolate device
	jr	z,dmprt1		; bypass unit printing for mem disk
	ld	a,b			; a = device/unit
	and	$0f			; remove device nibble
	add	a,'0'			; convert to alpha
	call	COUT			; print unit number
	ld	a,h			; load slice max msb
	or	l			; compare to lsb
	jr	z,dmprt1		; if zero, no lu support
	ld	a,'-'			; slice prefix
	call	COUT			; print slice prefix
	ld	de,(BL_TMPLU)		; recover LU
	ld	a,e			; ignore msb, load lsb in a
	call	PRTHEXBYTE		; print it

dmprt1:
	call	PC_SPACE		; padding

dmdone:
	pop	bc			; recover drive num and loop counter
	inc	c			; increment drive number
	dec	b			; decrement loop counter
	jp	nz,dmloop		; loop if more drives to check
	ret				; done
#ENDIF
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
	.DB	" (", VARIANT, "-", TIMESTAMP, ")\r\n\r\n"
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
#DEFINE	CIOMODE_CBIOS
#DEFINE	DSKY_KBD
#INCLUDE "util.asm"
;
#INCLUDE "memmgr.asm"
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
BL_LDLOC	.EQU	100H		; LOAD IMAGE HERE BEFORE RELOCATING
;
#IF (DRIVES)
str_devrom	.DB	"ROM$"
str_devram	.DB	"RAM$"
str_devfd	.DB	"FD$"
str_devide	.DB	"IDE$"
str_devatapi	.DB	"ATAPI$"
str_devppide	.DB	"PPIDE$"
str_devsd	.DB	"SD$"
str_devprpsd	.DB	"PRPSD$"
str_devpppsd	.DB	"PPPSD$"
str_devhdsk	.DB	"HDSK$"
#ENDIF
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
