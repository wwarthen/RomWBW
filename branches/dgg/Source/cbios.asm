;__________________________________________________________________________________________________
;
;	CBIOS FOR N8VEM
;
;	BY ANDREW LYNCH, WITH INPUT FROM MANY SOURCES
;	ROMWBW ADAPTATION BY WAYNE WARTHEN
;__________________________________________________________________________________________________
;
; cbios.asm  6/04/2012 dwg - added BOOTLU
; cbios.asm  5/21/2012 dwg - added peek and poke for bank 1 frame 0
; cbios.asm  5/16/2012 dwg - new architecture for 2.0.0.0 Beta 3 
;

; The std.asm file contains the majority of the standard equates
; that describe data sructures, magic values and bit fields used 
; by the CBIOS.
 
#INCLUDE "std.asm"
;
#INCLUDE "syscfg.exp"
;
     		.ORG   CBIOS_LOC	; DEFINED IN STD.ASM
;
;==================================================================================================
;	CP/M JUMP VECTOR TABLE FOR INDIVIDUAL SUBROUTINES
;==================================================================================================
; These jumps are defined in the CP/M-80 v2.2 system guide and comprise
; the invariant part of the BIOS.
;
	JP	BOOT			; #0  - COLD START
WBOOTE	JP	WBOOT			; #1  - WARM START
	JP	CONST			; #2  - CONSOLE STATUS
	JP	CONIN			; #3  - CONSOLE CHARACTER IN
	JP	CONOUT			; #4  - CONSOLE CHARACTER OUT
	JP	LIST			; #5  - LIST CHARACTER OUT
	JP	PUNCH			; #6  - PUNCH CHARACTER OUT
	JP	READER			; #7  - READER CHARACTER OUT
	JP	HOME			; #8  - MOVE HEAD TO HOME POSITION
	JP	SELDSK			; #9  - SELECT DISK
	JP	SETTRK			; #10 - SET TRACK NUMBER
	JP	SETSEC			; #11 - SET SECTOR NUMBER
	JP	SETDMA			; #12 - SET DMA ADDRESS
	JP	READ			; #13 - READ DISK
	JP	WRITE			; #14 - WRITE DISK
	JP	LISTST			; #15 - RETURN LIST STATUS
	JP	SECTRN			; #16 - SECTOR TRANSLATE
;
;------------------------------------------------------------------------
; These jumps are enhancements, added for the benefit of the RomWBW BIOS
; and are located following the invariant jump table so they can be
; easily located by external programs. They transfger control to routines
; that are located somewhere within the main section of the CBIOS.
;
	JP	BNKSEL			; #17 - SEL. RAM BANK FOR LOW32K (obsolete, use HBIOS)
	JP	GETDSK			; #18 - Get Disk Info (device/unit/lu)
	JP	SETDSK			; #19 - Set Disk Into (device/unit/lu)
	JP	GETINFO			; #20 - Get BIOS Info Base Ptr
;
;------------------------------------------------------------------------
; Expansion area for future enhancements - In order not to shift the
; subsequent data and break local and external code, space is set aside for
; four additional jumps.  Until implemented, an invocation will result in
; a system panic.
;
	CALL	PANIC			; #21 - reserved for JP <new function>
	CALL	PANIC			; #22 - reserved for JP <new function>
	CALL	PANIC			; #23 - reserved for JP <new function>
	CALL	PANIC			; #24 - reserved for JP <new function>
;
;==================================================================================================
;   CONFIGURATION DATA
;==================================================================================================
;
; The following RomWBW specific configuration data is located at this
; offset so they can be located by code in the CBIOS. The declarations
; are based on the selected configuration file used at build-time. The
; data is included from an external file so as to not clutter the main
; BIOS code. The size of the configuration data is available by virtue
; of the SIZ_CNFGDATA equate (see below).

ORG_INFOLIST	.EQU	$

		.DB	RMJ
		.DB	RMN
		.DB	RUP
		.DB	RTP

#INCLUDE "infolist.inc"

SIZ_INFOLIST	.EQU	$ - ORG_INFOLIST											   ;
		.ECHO	"INFOLIST occupies "
		.ECHO	SIZ_INFOLIST
		.ECHO	" bytes.\n"
;
;==================================================================================================
;   BIOS FUNCTIONS
;==================================================================================================
;
;__________________________________________________________________________________________________			
BOOT:
	JP	INIT	; GO TO COLD BOOT CODE
;
;__________________________________________________________________________________________________			
WBOOT:
	DI
	IM	1
;
	LD	SP,ISTACK	; STACK FOR INITIALIZATION
;	
	; RELOAD COMMAND PROCESSOR FROM CACHE
	LD	A,1		; SELECT RAM BANK 1
	CALL	RAMPG		; DO IT
	LD	HL,0800H	; LOCATION IN RAM BANK 1 OF COMMAND PROCESSOR CACHE
	LD	DE,CPM_LOC	; LOCATION OF ACTIVE COMMAND PROCESSOR
	LD	BC,CCPSIZ	; SIZE OF COMMAND PROCESSOR
	LDIR			; COPY
	CALL	RAMPGZ		; RESTORE RAM PAGE 0
;
	; FALL THRU TO INVOKE CP/M
;
;__________________________________________________________________________________________________			
GOCPM:
	; SETUP DISK XFR BUFFER LOCATION
	LD	HL,SECBUF
	LD	(BUFADR),HL
	LD	B,BF_DIOSETBUF
	RST	08
;
	LD	A,0C3H			; LOAD A WITH 'JP' INSTRUCTION (USED BELOW)
;
	; CPU RESET / RST 0 -> WARM START CP/M
	LD	($0000),A		; JP OPCODE GOES HERE
	LD	HL,WBOOTE		; GET WARM BOOT ENTRY ADDRESS
	LD	($0001),HL		; PUT IT AT $0001

;	; INT / RST 38 -> INVOKE MONITOR
;	LD	(0038H),A
;	LD	HL,GOMON
;	LD	(0039H),HL

;	; INT / RST 38 -> PANIC
;	LD	(0038H),A
;	LD	HL,PANIC		; PANIC ROUTINE ADDRESS
;	LD	(0039H),HL		; POKE IT
	
	; CALL 5 -> INVOKE BDOS
	LD	(0005H),A		; JP OPCODE AT $0005
	LD	HL,BDOS			; GET BDOS ENTRY ADDRESS
	LD	(0006H),HL		; PUT IT AT $0006

	; RESET (DE)BLOCKING ALGORITHM
	CALL	BLKRES

	; DEFAULT DMA ADDRESS
	LD	BC,80H			; DEFAULT DMA ADDRESS IS $0080
	CALL	SETDMA			; SET IT

	; ENSURE VALID DISK AND JUMP TO CCP
	LD	A,(CDISK)		; GET CURRENT USER/DISK
	AND	0FH			; ISOLATE DISK PART
	LD	C,A			; SETUP C WITH CURRENT USER/DISK, ASSUME IT IS OK
	CALL	DSK_STATUS		; CHECK DISK STATUS
	JR	Z,CURDSK		; ZERO MEANS OK
	LD	A,(DEFDRIVE)		; CURRENT DRIVE NOT READY, USE DEFAULT
	JR	GOCCP			; JUMP TO COMMAND PROCESSOR
CURDSK:
	LD	A,(CDISK)		; GET CURRENT USER/DISK
GOCCP:
	LD	C,A			; SETUP C WITH CURRENT USER/DISK, ASSUME IT IS OK
	JP	CCP			; JUMP TO COMMAND PROCESSOR
;
;__________________________________________________________________________________________________			
GOMON:
	CALL	PANIC
;
;	DI
;	IM	1
;
;	LD	SP,STACK
;
;	; RELOAD MONITOR INTO RAM (IN CASE IT HAS BEEN OVERWRITTEN)
;	CALL	ROMPGZ
;	LD	HL,MON_IMG
;	LD	DE,MON_LOC
;	LD	BC,MON_SIZ
;	LDIR
;	CALL	RAMPGZ
	
;	; JUMP TO MONITOR WARM ENTRY
;	JP	MON_UART
;
;__________________________________________________________________________________________________
CONST:
; CONSOLE STATUS, RETURN 0FFH IF CHARACTER READY, 00H IF NOT
;
	LD	B,BF_CIOIST	; B = FUNCTION
	LD	HL,CIOST	; HL = ADDRESS OF COMPLETION ROUTINE
	JR	CONIO
;
;__________________________________________________________________________________________________			
CONIN:
; CONSOLE CHARACTER INTO REGISTER A
;
	LD	B,BF_CIOIN	; B = FUNCTION
	LD	HL,CIOIN	; HL = ADDRESS OF COMPLETION ROUTINE
	JR	CONIO

;__________________________________________________________________________________________________			
CONOUT:
; CONSOLE CHARACTER OUTPUT FROM REGISTER C
;
	LD	B,BF_CIOOUT	; B = FUNCTION
	LD	HL,CIOOUT	; HL = ADDRESS OF COMPLETION ROUTINE
	LD	E,C		; E = CHARACTER TO SEND
;	JR	CONIO		; COMMENTED OUT, FALL THROUGH OK
;
;__________________________________________________________________________________________________			
CONIO:
;
	LD	A,(IOBYTE)	; GET IOBYTE
	AND	$03		; ISOLATE RELEVANT IOBYTE BITS FOR CONSOLE
	OR	$00		; PUT LOGICAL DEVICE IN BITS 2-3 (CON:=$00, RDR:=$04, PUN:=$08, LST:=$0C
	JP	CIO_DISP
;
;__________________________________________________________________________________________________			
LIST:					
; LIST CHARACTER FROM REGISTER C
;
	LD	B,BF_CIOOUT	; B = FUNCTION
	LD	HL,CIOOUT	; HL = ADDRESS OF COMPLETION ROUTINE
	LD	E,C		; E = CHARACTER TO SEND
	JR	LISTIO
;
;__________________________________________________________________________________________________			
LISTST:
; RETURN LIST STATUS (0 IF NOT READY, 1 IF READY)
;
	LD	B,BF_CIOOST	; B = FUNCTION
	LD	HL,CIOST	; HL = ADDRESS OF COMPLETION ROUTINE
;	JR	LISTIO		; COMMENTED OUT, FALL THROUGH OK
;
;__________________________________________________________________________________________________			
LISTIO:
;
	LD	A,(IOBYTE)	; GET IOBYTE
	RLCA			; SHIFT RELEVANT BITS TO BITS 0-1
	RLCA
	AND	$03		; ISOLATE RELEVANT IOBYTE BITS FOR LST:
	OR	$0C		; PUT LOGICAL DEVICE IN BITS 2-3 (CON:=$00, RDR:=$04, PUN:=$08, LST:=$0C
	JP	CIO_DISP
;
;__________________________________________________________________________________________________			
PUNCH:
; PUNCH CHARACTER FROM REGISTER C
;
	LD	B,BF_CIOOUT	; B = FUNCTION
	LD	HL,CIOOUT	; HL = ADDRESS OF COMPLETION ROUTINE
	LD	E,C		; E = CHARACTER TO SEND
;	JR	PUNCHIO		; COMMENTED OUT, FALL THROUGH OK
;
;__________________________________________________________________________________________________			
PUNCHIO:
;
	LD	A,(IOBYTE)	; GET IOBYTE
	RLCA			; SHIFT RELEVANT BITS TO BITS 0-1
	RLCA
	RLCA
	RLCA
	AND	$03		; ISOLATE RELEVANT IOBYTE BITS FOR PUN:
	OR	$08		; PUT LOGICAL DEVICE IN BITS 2-3 (CON:=$00, RDR:=$04, PUN:=$08, LST:=$0C
	JP	CIO_DISP
;
;__________________________________________________________________________________________________			
READER:
; READ CHARACTER INTO REGISTER A FROM READER DEVICE
;
	LD	B,BF_CIOIN	; B = FUNCTION
	LD	HL,CIOIN	; HL = ADDRESS OF COMPLETION ROUTINE
	JR	READERIO
;
;__________________________________________________________________________________________________			
READERST:
; RETURN READER STATUS (0 IF NOT READY, 1 IF READY)
;
	LD	B,BF_CIOIST	; B = FUNCTION
	LD	HL,CIOST	; HL = ADDRESS OF COMPLETION ROUTINE
;	JR	READERIO	; COMMENTED OUT, FALL THROUGH OK
;
;__________________________________________________________________________________________________			
READERIO:
;
	LD	A,(IOBYTE)	; GET IOBYTE
	RRCA			; SHIFT RELEVANT BITS TO BITS 0-1
	RRCA
	AND	$03		; ISOLATE RELEVANT IOBYTE BITS FOR RDR:
	OR	$04		; PUT LOGICAL DEVICE IN BITS 2-3 (CON:=$00, RDR:=$04, PUN:=$08, LST:=$0C
	JP	CIO_DISP
;
;__________________________________________________________________________________________________			
CIOIN:
; COMPLETION ROUTINE FOR CHARACTER INPUT FUNCTIONS
;
	LD	A,E		; MOVE CHARACTER RETURNED TO A
;	RET			; FALL THRU
;
;__________________________________________________________________________________________________			
CIOOUT:
; COMPLETION ROUTINE FOR CHARACTER OUTPUT FUNCTIONS
;
	RET
;
;__________________________________________________________________________________________________			
CIOST:
; COMPLETION ROUTINE FOR CHARACTER STATUS FUNCTIONS (IST/OST)
;
	OR	A		; SET FLAGS
	RET	Z		; NO CHARACTERS WAITING (IST) OR OUTPUT BUF FULL (OST)
	OR	$FF		; $FF SIGNALS READY TO READ (IST) OR WRITE (OST)
	RET
;__________________________________________________________________________________________________
SELDSK:
; SELECT DISK NUMBER FOR SUBSEQUENT DISK OPS
#IF DSKTRACE
	CALL	PRTSELDSK	; *DEBUG*
#ENDIF
;
	JP	DSK_SELECT
;
;__________________________________________________________________________________________________	
HOME:
; SELECT TRACK 0 (BC = 0) AND FALL THRU TO SETTRK
#IF DSKTRACE
	CALL	PRTHOME		; *DEBUG*
#ENDIF
;	
	LD	A,(HSTWRT)	; CHECK FOR PENDING WRITE
	OR	A		; SET FLAGS
	JR	NZ,HOMED	; BUFFER IS DIRTY
	LD	(HSTACT),A	; CLEAR HOST ACTIVE FLAG
;
HOMED:
	LD	BC,0
;
;__________________________________________________________________________________________________
SETTRK:
; SET TRACK GIVEN BY REGISTER BC
	LD	(SEKTRK),BC
	RET
;
;__________________________________________________________________________________________________
SETSEC:
; SET SECTOR GIVEN BY REGISTER BC
	LD	(SEKSEC),BC
	RET
;
;__________________________________________________________________________________________________
SECTRN:
; SECTOR TRANSLATION FOR SKEW, HARD CODED 1:1, NO SKEW IMPLEMENTED
	LD	H,B
	LD	L,C
	RET
;
;__________________________________________________________________________________________________
SETDMA:
	LD	(DMAADR),BC
	RET
;
;__________________________________________________________________________________________________
READ:
	LD	A,DOP_READ
	JR	READWRITE
;
;__________________________________________________________________________________________________
WRITE:
	LD	A,C
	LD	(WRTYPE),A	; SAVE WRITE TYPE
	LD	A,DOP_WRITE
	JR	READWRITE
;
;__________________________________________________________________________________________________			
BNKSEL:
;
	LD	A,C
	JP	RAMPG
;
;__________________________________________________________________________________________________			
GETDSK:
;
; INPUT:	C=DRIVE # (0=A, 1=B, ... P=16)
; OUTPUT:	A=RESULT (0=OK, 1=INVALID DRIVE #)
;		B=DEVICE/UNIT
;		DE=CURRENT LU
;		HL=LU COUNT SUPPORTED ON DEVICE/UNIT (0 = NO SUPPORT)
;
	; C HAS CPM DRIVE, LOOKUP DPH (INCLUDES INVALID DRIVE CHECK)
	CALL	DSK_GETDPH	; HL = DPH (0 IF INVALID DRIVE)
	RET	NZ		; A=1 AND NZ SET IF INVALID DRIVE
	
	; HL HAS DPH POINTER, LOOKUP LU INFO (ERROR IF NO LU SUPPORT)
	CALL	DSK_GETLU	; HL = ADDRESS OF START OF LU DATA
	JR	NZ,GETDSK1	; NO LU SUPPORT, BAIL OUT
	
	; HL POINTS TO START OF LU DATA, FILL IN LU VALUES
	LD	E,(HL)
	INC	HL
	LD	D,(HL)		; DE NOW HAS CURRENT SLICE NUMBER
	INC	HL
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A		; HL NOW HAS SLICE COUNT FOR DEVICE

GETDSK1:
	XOR	A		; A=0 FOR SUCCESS (EVEN IF NO LU SUPPORT)
	RET
;
;__________________________________________________________________________________________________			
SETDSK:
;
; INPUT:	C=DRIVE # (0=A, 1=B, ... P=16)
;		B=DEVICE/UNIT
;		DE=CURRENT LU
;		HL=LU COUNT SUPPORTED ON DEVICE/UNIT
; OUTPUT:	A=RESULT (0=OK, 1=INVALID DRIVE #)
;		B=DEVICE/UNIT
;		DE=CURRENT LU
;		HL=LU COUNT SUPPORTED ON DEVICE/UNIT (0 = NO SUPPORT)
;		
; NOTES:
;   PARMS ARE NOT VALUE CHECKED.  A NON-EXISTENT DEVICE/UNIT/LU COULD
;   BE SET AS A RESULT.  CALLER IS RESPONSIBLE FOR THIS.
;
	; SAVE INCOMING LU VALUES FOR LATER
	PUSH	BC
	PUSH	HL
	PUSH	DE
	
	; MAKE SURE NEW DEVICE/UNIT IS A MASS STORAGE DEVICE
	LD	A,B		; LOAD THE REQEUSTED DEVICE/UNIT
	CP	$20		; MASS STORAGE DEVICES START AT DEV/UNIT $20
	JR	C,SETDSK2	; IF NOT, BAIL OUT
	
	; C HAS CPM DRIVE, LOOKUP DPH (INCLUDES INVALID DRIVE CHECK)
	PUSH	BC
	CALL	DSK_GETDPH	; HL = DPH (0 IF INVALID DRIVE)
	POP	BC
	JR	NZ,SETDSK2	; A=1 AND NZ SET IF INVALID DRIVE
	
	; UPDATE DEVICE/UNIT (CHECK NEW DEVICE IS VALID)
	DEC	HL		; POINT TO DEVICE/UNIT BYTE
	LD	A,(HL)		; LOAD CURRENT DEVICE/UNIT
	CP	$20		; MASS STORAGE DEVICES START AT DEV/UNIT $20
	JR	C,SETDSK2	; IF NOT, BAIL OUT
	LD	A,B		; LOAD NEW DEVICE/UNIT VALUE
	LD	(HL),A		; SAVE IT
	INC	HL		; POINT HL BACK TO START OF DPH
	
	; HL HAS DPH POINTER, LOOKUP LU INFO (ERROR IF NO LU SUPPORT)
	CALL	DSK_GETLU	; HL = ADDRESS OF START OF LU DATA
	
	; RECOVER THE NEW SLICE AND SLICE COUNT
	POP	DE		; DE = NEW SLICE
	POP	BC		; BC = NEW SLICE COUNT
	
	; CHECK IF DRIVE IS LU CAPABLE, BYPASS LU SETTING IF NOT
	JR	NZ,SETDSK1
	
	; PLUG IN THE NEW VALUES
	LD	(HL),E
	INC	HL
	LD	(HL),D		; CURRENT SLICE NOW SET TO DE
	INC	HL		; POINT TO SLICE COUNT
	LD	(HL),C
	INC	HL
	LD	(HL),B		; SLICE COUNT NOW SET TO HL

SETDSK1:
	; SUCCESS EXIT (USE GETDSK TO RETURN DATA)
	CALL	BLKRES		; RESET (DE)BLOCKING ALGORITHM FOR SAFETY
	POP	BC
	JR	GETDSK
	
SETDSK2:
	; ERROR EXIT
	POP	DE
	POP	HL
	POP	BC
	XOR	A
	INC	A
	RET
;
;__________________________________________________________________________________________________			
GETINFO:
;
; The purpose of the GETINFO BIOS entry point is to return a
; base pointer to a table of pointers. These pointers are used
; by utility programs to locate BIOS internals that are not able
; to be located by normal means specified in the system guide.
;
; The pointers are defined in an included file so as to not clutter
; the main code. The contents are used by external utilties and are
; not used in any manner by the CBIOS code specifically.
;
	LD	HL,INFOLIST
	RET
;
;__________________________________________________________________________________________________
READWRITE:
	LD	(DSKOP),A		; SET THE ACTIVE DISK OPERATION
#IF DSKTRACE
	CALL	PRTDSKOP		; *DEBUG*
#ENDIF
	LD	A,(SEKDU)		; GET DEVICE/UNIT
	AND	0F0H			; ISOLATE DEVICE NIBBLE
	JR	Z,DIRRW			; DEVICE = 0 = MD, SO DIRECT R/W
	JP	BLKRW			; OTHERWISE, (DE)BLOCKING R/W

;
;==================================================================================================
;   DIRECT READ/WRITE (NO (DE)BLOCKING, NO BUFFERING, 128 BYTE SECTOR)
;==================================================================================================
;
DIRRW:
	CALL	BLKFLSH		; FLUSH ANY PENDING WRITES SO WE CAN USE SEC BUF
	RET	NZ		; RETURN ON ERROR

	CALL	BLKRES		; RESET (DE)BLOCKING ALG, BUF IS NO LONGER VALID
	
	; AT THIS POINT THE ACCESS IS HARDCODED TO POINT TO MEMORY DISK DRIVER
	; SINCE THERE IS NO OTHER DIRECT READ/WRITE DEVICE
	
	LD	A,(DSKOP)
	
	CP	DOP_READ
	JP	Z,MD_READ
	
	CP	DOP_WRITE
	JP	Z,MD_WRITE
	
	CALL	PANIC
;
;==================================================================================================
;   BLOCKED READ/WRITE (BLOCK AND BUFFER FOR 512 BYTE SECTOR)
;==================================================================================================
;
;__________________________________________________________________________________________________
;
; RESET (DE)BLOCKING ALGORITHM - JUST MARK BUFFER INVALID
; NOTE: BUFFER CONTENTS INVALIDATED, BUT RETAIN ANY PENDING WRITE
;
BLKRES:
	XOR	A
	LD	(HSTACT),A	; BUFFER NO LONGER VALID
	LD	(UNACNT),A	; CLEAR UNALLOC COUNT
	
	RET

;__________________________________________________________________________________________________
;
; FLUSH (DE)BLOCKING ALGORITHM - DO PENDING WRITES
;
BLKFLSH:
	; CHECK FOR BUFFER WRITTEN (DIRTY)
	LD	A,(HSTWRT)	; GET BUFFER WRITTEN FLAG
	OR	A
	RET	Z		; NOT DIRTY, RETURN WITH A=0 AND Z SET

	; CLEAR THE BUFFER WRITTEN FLAG (EVEN IF A WRITE ERROR OCCURS)
	XOR	A		; Z = 0
	LD	(HSTWRT),A	; SAVE IT

	; DO THE WRITE AND RETURN RESULT
	JP	DSK_WRITE

#IF WRTCACHE

WRT_ALC	.EQU	0			; WRITE TO ALLOCATED
WRT_DIR	.EQU	1			; WRITE TO DIRECTORY
WRT_UNA	.EQU	2			; WRITE TO UNALLOCATED

;
;__________________________________________________________________________________________________
;
; (DE)BLOCKING READ/WRITE ROUTINE.  MANAGES PHYSICAL DISK BUFFER AND CALLS
; PHYSICAL READ/WRITE ROUTINES APPROPRIATELY.
;
BLKRW:
	; FIX!!! WE ABORT ON FIRST ERROR, DRI SEEMS TO PASS ERROR STATUS TO THE END!!!

	; IF WRITE OPERATION, GO TO SPECIAL WRITE PROCESSING
	LD	A,(DSKOP)	; GET REQUESTED OPERATION
	CP	DOP_WRITE	; WRITE
	JR	Z,BLKRW1	; GO TO WRITE PROCESSING

	; OTHERWISE, CLEAR OUT ANY SEQUENTIAL, UNALLOC WRITE PROCESSING
	; AND GO DIRECTLY TO MAIN I/O
	XOR	A		; ZERO TO A
	LD	(WRTYPE),A	; SET WRITE TYPE = 0 (WRT_ALC) TO ENSURE READ OCCURS
	LD	(UNACNT),A	; SET UNACNT TO ABORT SEQ WRITE PROCESSING
	
	JR	BLKRW4		; GO TO I/O

BLKRW1:
	; WRITE PROCESSING
	; CHECK FOR FIRST WRITE TO UNALLOCATED BLOCK
	LD	A,(WRTYPE)	; GET WRITE TYPE
	CP	WRT_UNA		; IS IT WRITE TO UNALLOC?
	JR	NZ,BLKRW2	; NOPE, BYPASS
	
	; INITIALIZE START OF SEQUENTIAL WRITING TO UNALLOCATED BLOCK
	; AND THEN TREAT SUBSEQUENT PROCESSING AS A NORMAL WRITE
	CALL	UNA_INI		; INITIALIZE SEQUENTIAL WRITE TRACKING
	XOR	A		; A = 0 = WRT_ALC
	LD	(WRTYPE),A	; NOW TREAT LIKE WRITE TO ALLOCATED

BLKRW2:
	; IF WRTYPE = WRT_ALC AND SEQ WRITE, GOTO BLKRW7 (SKIP READ)
	OR	A		; NOTE: A WILL ALREADY HAVE THE WRITE TYPE HERE
	JR	NZ,BLKRW3	; NOT TYPE = 0 = WRT_ALC, SO MOVE ON

	CALL	UNA_CHK		; CHECK FOR CONTINUATION OF SEQ WRITES TO UNALLOCATED BLOCK
	JR	NZ,BLKRW3	; NOPE, ABORT
	
	; WE MATCHED EVERYTHING, TREAT AS WRITE TO UNALLOCATED BLOCK
	LD	A,WRT_UNA	; WRITE TO UNALLOCATED
	LD	(WRTYPE),A	; SAVE WRITE TYPE
	
	CALL	UNA_INC		; INCREMENT SEQUENTIAL WRITE TRACKING
	JR	BLKRW4		; PROCEED TO I/O PROCESSING

BLKRW3:
	; NON-SEQUENTIAL WRITE DETECTED, STOP ANY FURTHER CHECKING
	XOR	A		; ZERO
	LD	(UNACNT),A	; CLEAR UNALLOCATED WRITE COUNT

	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; IS A FLUSH NEEDED HERE???
	; FLUSH CURRENT BUFFER CONTENTS IF NEEDED
	;CALL	BLKFLSH		; FLUSH PENDING WRITES
	;RET	NZ		; ABORT ON ERROR
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

BLKRW4:
	; START OF ACTUAL I/O PROCESSING
	CALL	BLK_XLT		; DO THE LOGICAL TO PHYSICAL MAPPING: SEK... -> XLT...
	CALL	BLK_CMP		; IS THE DESIRED PHYSICAL BLOCK IN BUFFER?
	JR	Z,BLKRW6	; BLOCK ALREADY IN ACTIVE BUFFER, NO READ REQUIRED

	; AT THIS POINT, WE KNOW WE NEED TO READ THE TARGET PHYSICAL SECTOR
	; IT MAY ACTUALLY BE A PREREAD FOR A SUBSEQUENT WRITE, BUT THAT IS OK

	; FIRST, FLUSH CURRENT BUFFER CONTENTS
	CALL	BLKFLSH		; FLUSH PENDING WRITES
	RET	NZ		; ABORT ON ERROR

	; IMPLEMENT THE TRANSLATED VALUES
	CALL	BLK_SAV		; SAVE XLAT VALUES: XLT... -> HST...
	
	; IF WRITE TO UNALLOC BLOCK, BYPASS READ, LEAVES BUFFER UNDEFINED
	LD	A,(WRTYPE)
	CP	2
	JR	Z,BLKRW6
	
	; DO THE ACTUAL READ
	CALL	DSK_READ	; READ PHYSICAL SECTOR INTO BUFFER
	JR	Z,BLKRW6	; GOOD READ, CONTINUE
	
	; IF READ FAILED, RESET (DE)BLOCKING ALGORITHM AND RETURN ERROR
	PUSH	AF		; SAVE ERROR STATUS
	CALL	BLKRES		; INVALIDATE (DE)BLOCKING BUFFER
	POP	AF		; RECOVER ERROR STATUS
	RET			; ERROR RETURN

BLKRW6:
	; CHECK TYPE OF OPERATIONS, IF WRITE, THEN GO TO WRITE PROCESSING
	LD	A,(DSKOP)	; GET PENDING OPERATION
	CP	DOP_WRITE	; IS IT A WRITE?
	JR	Z,BLKRW7	; YES, GO TO WRITE PROCESSING

	; THIS IS A READ OPERATION, WE ALREADY DID THE I/O, NOW JUST DEBLOCK AND RETURN
	CALL	BLK_DEBLOCK	; EXTRACT DATA FROM BLOCK
	XOR	A		; NO ERROR
	RET			; ALL DONE
	
BLKRW7:
	; THIS IS A WRITE OPERATION, INSERT DATA INTO BLOCK
	CALL	BLK_BLOCK	; INSERT DATA INTO BLOCK

	; MARK THE BUFFER AS WRITTEN
	LD	A,TRUE		; BUFFER DIRTY = TRUE
	LD	(HSTWRT),A	; SAVE IT
	
	; CHECK WRITE TYPE, IF WRT_DIR, FORCE THE PHYSICAL WRITE
	LD	A,(WRTYPE)	; GET WRITE TYPE
	CP	WRT_DIR		; 1 = DIRECTORY WRITE
	JP	Z,BLKFLSH	; FLUSH PENDING WRITES AND RETURN STATUS

	XOR	A		; ALL IS WELL, SET RETURN CODE 0
	RET			; RETURN
;
;__________________________________________________________________________________________________
;
; INITIALIZE TRACKING OF SEQUENTIAL WRITES INTO UNALLOCATED BLOCK
; SETUP UNA... VARIABLES
;
UNA_INI:
	; COPY SEKDSK/TRK/SEC TO UNA...
	LD	HL,SEK
	LD	DE,UNA
	LD	BC,UNASIZ
	LDIR

	; SETUP UNACNT AND UNASPT
	LD	HL,(SEKDPH)	; HL POINTS TO DPH
	LD	DE,10		; OFFSET OF DPB ADDRESS IN DPH
	ADD	HL,DE		; DPH POINTS TO DPB ADDRESS
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A		; HL POINTS TO DPB
	LD	C,(HL)
	INC	HL
	LD	B,(HL)		; BC HAS SPT
	LD	(UNASPT),BC	; SAVE SECTORS PER TRACK
	DEC	HL
	DEC	HL		; HL POINTS TO RECORDS PER BLOCK (BYTE IN FRONT OF DPB)
	LD	A,(HL)		; GET IT
	LD	(UNACNT),A	; SAVE IT
	
	RET
;
;__________________________________________________________________________________________________
;
; CHECK FOR CONTINUATION OF SEQUENTIAL WRITES TO UNALLOCATED BLOCK
; SEE IF UNACNT > 0 AND UNA... VARIABLES MATCH SEK... VARIABLES
;
UNA_CHK:
	LD	A,(UNACNT)	; GET THE COUNTER
	OR	A
	JR	NZ,UNA_CHK1	; IF NOT DONE WITH BLOCK, KEEP CHECKING

	; CNT IS NOW ZERO, EXHAUSTED RECORDS IN ONE BLOCK!
	DEC	A		; HACK TO SET NZ
	RET			; RETURN WITH NZ

UNA_CHK1:
	; COMPARE UNA... VARIABLES WITH SEK... VARIABLES
	LD	HL,SEK
	LD	DE,UNA
	LD	B,UNASIZ
	JR	BLK_CMPLOOP
;
;__________________________________________________________________________________________________
;
; INCREMENT THE SEQUENTIAL WRITE TRACKING VARIABLES
; TO REFLECT THE NEXT RECORD (TRK/SEC) WE EXPECT
;
UNA_INC:
	; DECREMENT THE BLOCK RECORD COUNT
	LD	HL,UNACNT
	DEC	(HL)
	
	; INCREMENT THE SECTOR
	LD	DE,(UNASEC)
	INC	DE
	LD	(UNASEC),DE
	
	; CHECK FOR END OF TRACK
	LD	HL,(UNASPT)
	XOR	A
	SBC	HL,DE
	RET	NZ
	
	; HANDLE END OF TRACK
	LD	(UNASEC),HL	; SECTOR BACK TO 0 (NOTE: HL=0 AT THIS POINT)
	LD	HL,(UNATRK)	; GET CURRENT TRACK
	INC	HL		; BUMP IT
	LD	(UNATRK),HL	; SAVE IT
	
	RET
#ELSE
;
;__________________________________________________________________________________________________
;
; (DE)BLOCKING READ/WRITE ROUTINE.  MANAGES PHYSICAL DISK BUFFER AND CALLS
; PHYSICAL READ/WRITE ROUTINES APPROPRIATELY.
;
BLKRW:
	CALL	BLK_XLT		; SECTOR XLAT: SEK... -> XLT...
	CALL	BLK_CMP		; IN BUFFER?
	JR	Z,BLKRW1	; YES, BYPASS READ
	CALL	BLK_SAV		; SAVE XLAT VALUES: XLT... -> HST...
	LD	A,FALSE		; ASSUME FAILURE, INVALIDATE BUFFER
	LD	(HSTACT),A	; SAVE IT
	CALL	DSK_READ	; READ PHYSICAL SECTOR INTO BUFFER
	RET	NZ		; BAIL OUT ON ERROR

BLKRW1:
	LD	A,(DSKOP)	; GET PENDING OPERATION
	CP	DOP_WRITE	; IS IT A WRITE?
	JR	Z,BLKRW2	; YES, GO TO WRITE ROUTINE

	CALL	BLK_DEBLOCK	; EXTRACT DATA FROM BLOCK
	XOR	A		; NO ERROR
	RET			; ALL DONE
	
BLKRW2:
	CALL	BLK_BLOCK	; INSERT DATA INTO BLOCK
	CALL	DSK_WRITE	; WRITE PHYSICAL SECTOR FROM BUFFER
	RET	NZ		; BAIL OUT ON ERROR
	
	LD	A,TRUE		; BUFFER IS NOW VALID
	LD	(HSTACT),A	; SAVE IT
	
	XOR	A		; ALL IS WELL, SET RETURN CODE 0
	RET			; RETURN
#ENDIF
;
;__________________________________________________________________________________________________
;
; TRANSLATE FROM CP/M DSK/TRK/SEC TO PHYSICAL
; SEK... -> XLT...
;
BLK_XLT:
	; FIRST, DO A BYTE COPY OF SEK... TO XLT...
	LD	HL,SEK
	LD	DE,XLT
	LD	BC,XLTSIZ
	LDIR

	; NOW UPDATE XLTSEC BASED ON (DE)BLOCKING FACTOR (ALWAYS 4:1)
	LD	BC,(SEKSEC)		; SECTOR IS FACTORED DOWN (4:1) DUE TO BLOCKING
	SRL	B			; 16 BIT RIGHT SHIFT TWICE TO DIVIDE BY 4
	RR	C
	SRL	B
	RR	C
	LD	(XLTSEC),BC

	RET
;
;__________________________________________________________________________________________________
;
; SAVE RESULTS OF TRANSLATION: XLT... -> HST...
; IMPLICITLY SETS HSTACT TO TRUE!
;
BLK_SAV:
	LD	HL,XLT
	LD	DE,HST
	LD	BC,XLTSIZ
	LDIR
	RET
;
;__________________________________________________________________________________________________
;
; COMPARE RESULTS OF TRANSLATION TO CURRENT BUF (XLT... TO HST...)
; NOTE THAT HSTACT IS COMPARED TO XLTACT IMPLICITLY!  XLTACT IS ALWAYS TRUE, SO
; HSTACT MUST BE TRUE FOR COMPARE TO SUCCEED.
;
BLK_CMP:
	LD	HL,XLT
	LD	DE,HST
	LD	B,XLTSIZ
BLK_CMPLOOP:
	LD	A,(DE)
	CP	(HL)
	RET	NZ			; BAD COMPARE, RETURN WITH NZ
	INC	HL
	INC	DE
	DJNZ	BLK_CMPLOOP
	RET				; RETURN WITH Z
;
;__________________________________________________________________________________________________
;
; BLOCK DATA - INSERT CPM DMA BUF INTO PROPER PART OF PHYSICAL SECTOR BUFFER
;
BLK_BLOCK:
	CALL		BLK_SETUP	; SETUP SOURCE AND DESTINATION
	EX		DE,HL		; SWAP HL/DE FOR BLOCK OPERATION
	LD		BC,128		; DMA BUFFER SIZE
	LDIR				; COPY THE DATA
	RET
;
;__________________________________________________________________________________________________
;
; DEBLOCK DATA - EXTRACT DESIRED CPM DMA BUF FROM PHYSICAL SECTOR BUFFER
;
BLK_DEBLOCK:
	CALL		BLK_SETUP	; SETUP SOURCE AND DESTINATION
	LD		BC,128		; DMA BUFFER SIZE
	LDIR				; COPY THE DATA
	RET
;
;__________________________________________________________________________________________________
;
; SETUP SOURCE AND DESTINATION POINTERS FOR BLOCK COPY OPERATION
; AT EXIT, HL = ADDRESS OF DESIRED BLOCK IN SECTOR BUFFER, DE = DMA
;
BLK_SETUP:	
	LD		BC,(SEKSEC)
	LD		A,C
	AND		3		; A = INDEX OF CPM BUF IN SEC BUF
	RRCA				; MULTIPLY BY 64
	RRCA
	LD		E,A		; INTO LOW ORDER BYTE OF DESTINATION
	LD		D,0		; HIGH ORDER BYTE IS ZERO
	LD		HL,(BUFADR)	; HL = START OF SEC BUF
	ADD		HL,DE		; ADD IN COMPUTED OFFSET
	ADD		HL,DE		; HL NOW = INDEX * 128 (SOURCE)
	LD		DE,(DMAADR)	; DE = DESTINATION = DMA BUF
	RET
;
;==================================================================================================
;   CHARACTER DEVICE INTERFACE
;==================================================================================================
;
; ROUTING FOR CHARACTER DEVICE FUNCTIONS
;   A = INDEX INTO CIO_MAP BASED ON IOBYTE BIOS REQUEST
;   B = FUNCTION REQUESTED: BF_CIO(IN/OUT/IST/OST)
;   E = CHARACTER (IF APPLICABLE TO FUNCTION)
;   HL = ADDRESS OF COMPLETION ROUTINE
;
CIO_DISP:
	PUSH	HL		; PUT COMPLETION ROUTINE ON STACK

	; LOOKUP IOBYTE MAPPED DEVICE CODE
	; WARNING: CIO_MAP MUST NOT CROSS PAGE BOUNDARY!!!
	AND	0FH		; ISOLATE INDEX INTO CIO_MAP

	LD	HL,CIO_MAP	; HL = ADDRESS OF CIO_MAP
	ADD	A,L		; ADD LOW BYTE TO OFFSET
	LD	L,A		; GET RESULT BACK TO L
	
	LD	A,(HL)		; LOOKUP DEVICE CODE
	LD	C,A		; SAVE IN C FOR BIOS USAGE

	CP	CIODEV_BAT	; CHECK FOR SPECIAL DEVICE (BAT, NUL)
	JR	NC,CIO_DISP1	; HANDLE SPECIAL DEVICE
	RST	08		; OTHERWISE HANDLE VIA HBIOS
	RET			; RETURN VIA COMPLETION ROUTINE SET AT START
	
CIO_DISP1:
	; HANDLE SPECIAL DEVICES
	AND	0F0H		; ISOLATE DEVICE
	CP	CIODEV_BAT	; BAT: ?
	JR	Z,CIO_BAT	; YES, GO TO BAT DEVICE HANDLER
	CP	CIODEV_NUL	; NUL: ?
	JR	Z,CIO_NUL	; YES, GO TO NUL DEVICE HANDLER
	CALL	PANIC		; SOMETHING BAD HAPPENED
;
; BAT: IS A PSEUDO DEVICE REDIRECTING INPUT TO READER AND OUTPUT TO LIST
;
CIO_BAT:
	LD	C,E		; PUT CHAR BACK IN C
	LD	A,B		; GET REQUESTED FUNCTION
	CP	BF_CIOIN	; INPUT?
	JP	Z,READER	; -> READER
	CP	BF_CIOIST	; INPUT STATUS?
	JP	Z,READERST	; -> READER
	CP	BF_CIOOUT	; OUTPUT?
	JP	Z,LIST		; -> LIST
	CP	BF_CIOOST	; OUTPUT STATUS?
	JP	Z,LISTST	; -> LIST
	CALL	PANIC
;
; NUL: IS A DUMMY DEVICE THAT DOES NOTHING
;
CIO_NUL:
	LD	A,B		; FUNCTION
	CP	BF_CIOIN
	JR	Z,NUL_IN
	CP	BF_CIOIST
	JR	Z,NUL_IST
	CP	BF_CIOOUT
	JR	Z,NUL_OUT
	CP	BF_CIOOST
	JR	Z,NUL_OST
	CALL	PANIC
;
NUL_IN:
	LD	E,$1B		; RETURN EOF
NUL_OUT:
	RET
;
NUL_IST:
NUL_OST:
	OR	$FF		; A=$FF & NZ SET
	RET
;
;==================================================================================================
; PHYSICAL DISK INTERFACE
;==================================================================================================
;
DSK_DISP:
	LD	A,C		; GET DEVICE/UNIT TO A
	AND	0F0H		; ISOLATE DEVICE
	CP	DIODEV_MD	; MEMORY DISK? (RAM/ROM)
	JP	Z,MD_DISPATCH	; YES, GO TO MEMORY DISK DISPATCH
	
	RST	08		; OTHERWISE, HANDLE IN HBIOS
	RET			; AND RETURN
;
; LOOKUP DPH BASED ON CPM DRIVE NUMBER
;   ENTER WITH C=CPM DRIVE NUMBER
;   RETURNS WITH HL = DPH ADDRESS (0 ON ERROR)
;   A=0 ON SUCCESS, A=1 ON ERROR
;   NOTE: DE IS NOT MODIFIED!!!
;
DSK_GETDPH:
	; CHECK FOR INVALID DRIVE NUMBER
	LD	A,C		; A = CPM DRIVE NUMBER
	CP	DPH_CNT		; COMPARE TO NUMBER OF DRIVES CONFIGURED
	JR	C,DSK_GETDPH1	; IN RANGE, CONTINUE
	XOR	A		; ZERO ACCUMULATOR
	LD	H,A		; HL = 0 FOR FAILURE
	LD	L,A		; HL = 0 FOR FAILURE
	INC	A		; A = 1, NZ SET FOR INVALID DRIVE
	RET			; FAILURE RETURN

	; LOOKUP DPH FOR CPM DRIVE
	; WARNING: DPH_MAP MUST NOT CROSS PAGE BOUNDARY!!!
DSK_GETDPH1:
	LD	A,C		; GET CPM DRIVE NUMBER BACK
	LD	HL,DPH_MAP	; POINT TO START OF DPH_MAP
	RLCA			; DOUBLE A TO USE AS OFFSET INTO DPH_MAP
	ADD	A,L		; ADD LOW BYTE TO OFFSET
	LD	L,A		; HL = ADDRESS OF DESIRED ENTRY IN DPH_MAP
	LD	A,(HL)		; DEREFERENCE
	INC	HL		; HL
	LD	H,(HL)		; TO GET
	LD	L,A		; DPHADR IN HL
	
	; FILL IN DEVICE/UNIT
	DEC	HL		; POINT TO DEVICE CODE (BYTE IN FRONT OF DPH)
	LD	B,(HL)		; B = DEVICE/UNIT
	INC	HL		; HL = DPH AGAIN
	
	; RETURN SUCCESS
	XOR	A		; A=0, Z SET
	RET			; SUCCESS RETURN
;
; SET HL TO START OF LU DATA FOR DRIVE GIVEN DRIVE DPH POINTER IN HL
;   ENTER WITH HL=POINTER TO DPH OF DRIVE
;   RETURNS WITH HL = LU DATA ADDRESS (0 ON NO SUPPORT)
;   Z SET IF LU SUPPORT, NZ IF NOT
;
DSK_GETLU:
	; CHECK FOR LU SUPPORT
	LD	DE,16		; DPH + 16 IS "LU' MARKER LOCATION
	ADD	HL,DE		; HL POINTS TO MARKER LOCATION NOW
	LD	A,(HL)		; LOAD FIRST BYTE
	INC	HL		; POINT TO NEXT BYTE
	CP	'L'		; IS IT 'L'
	JR	NZ,DSK_GETLU1	; NOPE, BAIL OUT
	LD	A,(HL)		; LOAD SECOND BYTE
	INC	HL		; POINT TO NEXT BYTE
	CP	'U'		; IS SECOND BYTE 'U'?
	JR	NZ,DSK_GETLU1	; NOPE, BAIL OUT
	RET			; SUCCESS, EXIT WITH Z SET

DSK_GETLU1:	
	LD	HL,0		; OTHERWISE, HL=0
	RET			; AND RETURN WITH NZ SET
;
;
;
DSK_SELECT:
	; C HAS CPM DRIVE, SAVE IT
	LD	A,C
	LD	(SEKDSK),A

	; LOOKUP DPH (INCLUDES INVALID DRIVE CHECK)
	CALL	DSK_GETDPH	; HL = DPH (0 IF INVALID DRIVE)
	RET	NZ		; A=1 AND NZ SET IF INVALID DRIVE
	
	; FIX: WE COULD RETURN DUE TO INVALID DRIVE WITH ALL OF THE
	; REMAINING SEK... VARS SET TO PREVIOUS DRIVE?
	
	; SAVE CURRENT DEVICE/UNIT AND DPH ADDRESS
	LD	A,B		; A = DEVIE/UNIT
	LD	(SEKDU),A	; SAVE DEVICE/UNIT
	LD	(SEKDPH),HL	; SAVE DPH POINTER
	
	; SETUP IX AS INDEX INTO DPH
	PUSH	IX		; SAVE IX
	LD	IX,(SEKDPH)	; IX=DPH ADDRESS

	; CHECK IF THIS IS LOGIN, IF NOT, BYPASS MEDIA DETECTION
	; FIX: WHAT IF PREVIOUS MEDIA DETECTION FAILED???
	BIT	0,E		; TEST DRIVE LOGIN BIT
	JR	NZ,DSK_SELECT2	; BYPASS MEDIA DETECTION
;
DSK_SELECT1:
	; DETERMINE MEDIA IN DRIVE
	LD	A,(SEKDU)	; GET DEVICE/UNIT
	LD	C,A		; STORE IN C
	LD	B,BF_DIOMED	; DRIVER FUNCTION = DISK MEDIA
	CALL	DSK_DISP	; CALL DRIVER, RETURNS WITH A=MEDIA ID
	
	; CHECK FOR NO MEDIA
	LD	HL,0		; ASSUME NO MEDIA FAILURE, HL = 0
	OR	A		; SET FLAGS
	JR	Z,DSK_SELECT4	; IF Z, NO MEDIA, BAIL OUT WITH HL=0

	; A HAS MEDIA ID, SET HL TO CORRESPONDING DPB_MAP ENTRY
	LD	HL,DPB_MAP	; HL = DPB_MAP
	RLCA			; DPB_MAP ENTRIES ARE 2 BYTES EACH
	ADD	A,L		; ADD LOW BYTE TO OFFSET
	LD	L,A		; GET RESULT BACK TO L

	; LOOKUP THE ACTUAL DPB ADDRESS NOW
	LD	E,(HL)		; DEREFERENCE HL...
	INC	HL		; INTO DE...
	LD	D,(HL)		; DE = ADDRESS OF DESIRED DPB
	
	; PLUG APPROPRIATE DPB INTO THE ACTIVE DPH
	LD	(IX+10),E	; DPH.DPB := DPB ADDRESS (LSB)
	LD	(IX+11),D	; DPH.DPB := DPB ADDRESS (MSB)

DSK_SELECT2:
	; CHECK FOR SLICE SUPPORT, BYPASS LU OFFSET CALC IF NOT
	LD	HL,(SEKDPH)	; LOAD DPH
	CALL	DSK_GETLU	; CHECK FOR LU SUPPORT
	JR	NZ,DSK_SELECT3	; IF NOT (NZ), BYPASS LU OFFSET CALC

	; RECOMPUTE TRACK OFFSET BASED ON SLICE NUMBER
	LD	E,65		; FIX: FIXME!!!  HARDCODED!!! E = TRACKS PER SLICE
	LD	H,(IX+18)	; H = SLICE VALUE
	CALL	MULT8		; HL = TOTAL OFFSET

DSK_SELECT3:
	LD	(SEKOFF),HL	; SAVE LU TRACK OFFSET
	LD	HL,(SEKDPH)	; HL = DPH ADDRESS FOR CP/M	
	
DSK_SELECT4:
	POP	IX		; RESTORE IX
	RET
;
;
;
DSK_STATUS:
	; C HAS CPM DRIVE, LOOKUP DEVICE/UNIT AND CHECK FOR INVALID DRIVE
	CALL	DSK_GETDPH	; B = DEVICE/UNIT
	RET	NZ		; INVALID DRIVE ERROR
	
	; VALID DRIVE, DISPATCH TO DRIVER
	LD	C,B		; C=DEVICE/UNIT
	LD	B,BF_DIOST	; SET B = FUNCTION: STATUS
	JP	DSK_DISP	; DISPATCH
;
;
;
DSK_READ:
	; SET B = FUNCTION: READ
	LD	B,BF_DIORD
	JR	DSK_IO
;
;
;
DSK_WRITE:
	; SET B = FUNCTION: WRITE
	LD	B,BF_DIOWR
	JR	DSK_IO
;
;
;
DSK_IO:
	; SET HL=TRACK (ADD IN TRACK OFFSET)
	LD	DE,(HSTOFF)	; DE = TRACK OFFSET FOR LU SUPPORT
	LD	HL,(HSTTRK)	; HL = TRACK #
	ADD	HL,DE		; HL = TRACK # TO READ TAKING LU SUPPORT INTO ACCOUNT
	; SET DE=SECTOR
	LD	DE,(HSTSEC)	; DE = SECTOR #
	; SET C = DEVICE/UNIT
	LD	A,(HSTDU)	; LOAD DEVICE/UNIT VALUE
	LD	C,A		; SAVE IN C
	; DISPATCH TO DRIVER
	CALL	DSK_DISP	; CALL DRIVER
	OR	A		; SET FLAGS BASED ON RESULT
	RET
;
;==================================================================================================
;   IN MEMORY DISK DRIVERS (ROM/RAM)
;==================================================================================================
;
; USES ROM/RAM STORAGE NOT USED BY SYSTEM/OS FOR DISK STORAGE
; ROM DRIVE:
;   FIRST 32KB OF ROM RESERVED FOR SYSTEM BOOT AREA.  REMAINDER IS ALLOCATED
;   AS READ-ONLY DISK STORAGE.
; RAM DRIVE:
;   FIRST AND LAST 32KB OF RAM IS RESERVED AND MAPPED TO FIRST AND LAST 32KB
;   OF CPU MEMORY SPACE (FOR 64KB TOTAL).  EVERYTHING ELSE IS ALLOCATED AS
;   READ/WRITE DISK STORAGE.
; ROUTINES BELOW TRANSLATE REQUESTS FOR RAM/ROM STORAGE ACCESS BY CP/M BY
; TEMPORARILY MAPPING RAM/ROM INTO LOWER 32KB OF CPU MEMORY SPACE AND COPYING
; THE REQUESTED 128 BYTE BLOCK INTO THE CP/M DMA BUFFER.
;
MD_DISPATCH:
	LD	A,B		; GET REQUESTED FUNCTION
	AND	$0F
	JR	Z,MD_READ
	DEC	A
	JR	Z,MD_WRITE
	DEC	A
	JR	Z,MD_READY
	DEC	A
	JR	Z,MD_SELECT
	CALL	PANIC
;
;__________________________________________________________________________________________________
MD_INIT:
;
; INITIALIZE RAM DISK BY FILLING DIRECTORY WITH 'E5' BYTES
; FILL FIRST 8K OF RAM DISK TRACK 1 WITH 'E5'
;
#IF (CLRRAMDISK != CLR_NEVER)
	LD	A,2			; START OF RAM DISK (SECOND 32KB)
	CALL	RAMPG			; SELECT RAM DISK

#IF (CLRRAMDISK == CLR_AUTO)
	; CHECK FIRST 32 DIRECTORY ENTRIES.  IF ANY START WITH AN INVALID
	; VALUE, INIT THE RAM DISK.  VALID ENTRIES ARE E5 (EMPTY ENTRY) OR
	; 0-15 (USER NUMBER).
	LD	HL,0
	LD	DE,32
	LD	B,32
CLRRAM0:
	LD	A,(HL)
	CP	0E5H
	JR	Z,CLRRAM1		; E5 IS VALID
	CP	16
	JR	C,CLRRAM1		; 0-15 IS ALSO VALID
	JR	CLRRAM2			; INVALID ENTRY! JUMP TO INIT
CLRRAM1:
	ADD	HL,DE			; LOOP FOR 32 ENTRIES
	DJNZ	CLRRAM0
;	JR	CLRRAM2			; *DEBUG*
	JR	CLRRAM3			; ALL ENTRIES VALID, BYPASS INIT
CLRRAM2:
#ENDIF
	CALL	RAMPGZ
	LD	DE,STR_INITRAMDISK
	CALL	WRITESTR
	LD	A,2
	CALL	RAMPG

	LD	HL,0			; SOURCE OF FILL IN HL
	LD	BC,2000H - 1		; LENGTH OF FILL - 1
	LD	A,0E5H			; FILL VALUE IN A
	LD	E,L			; DE = HL
	LD	D,H			; "
	INC	DE			; THEN OFFSET BY ONE
	LD	(HL),A			; FILL INITIAL BYTE
	LDIR				; COMPLETE THE FILL
CLRRAM3:
	CALL	RAMPGZ
#ENDIF
	RET
;
;__________________________________________________________________________________________________
MD_READY:
	LD	A,TRUE
	RET
;
;__________________________________________________________________________________________________
MD_SELECT:
	LD	A,C
	AND	0FH
	ADD	A,MID_MDROM
	RET
;
;__________________________________________________________________________________________________
MD_READ:
	CALL	MD_PGSEL		; SET PAGER BASED ON DRIVE AND TRACK
	LD	DE,(BUFADR)		; SETUP SECTOR BUF AS DESTINATION
	CALL	MD_SECADR		; SETUP RAM/ROM PAGE ADDRESS IN HL
	CALL	MD_DMACPY		; MOVE SECTOR TO SECBUF
	CALL	RAMPGZ			; RESTORE NORMAL 32K LOWER CPU RAM
	LD	DE,(DMAADR)		; SETUP FOR COPY TO DMA ADDRESS
	LD	HL,(BUFADR)		; FROM BUFFER
	CALL	MD_DMACPY		; COPY FROM BUF TO DMA
	LD	A,00H			; SIGNAL SUCCESS
	RET
;
;__________________________________________________________________________________________________
MD_WRITE:
	; CHECK FOR WRITE ACCESS TO ROM
	LD	A,(SEKDU)		; GET DRIVE
	OR	A			; DEVICE = 0, UNIT = 0 MEANS ROM DISK (READ ONLY!)
	JR	Z,MD_RDONLY

	LD	DE,(BUFADR)		; GET SECTOR BUF ADDRESS
	LD	HL,(DMAADR)		; GET DMA BUF ADDRESS
	CALL	MD_DMACPY		; MOVE FROM DMA BUF TO SECTOR BUF
	CALL	MD_PGSEL		; SET PAGER BASED ON DRIVE AND TRACK
	CALL	MD_SECADR		; SETUP PAGE ADDRESS IN HL
	LD	DE,(BUFADR)		; SECTOR BUF ADDRESS IN DE
	EX	DE,HL			; REVERSE THEM TO...
	CALL	MD_DMACPY		; COPY FROM SECTOR BUF TO RAM PAGE
	CALL	RAMPGZ			; RESTORE NORMAL 32K LOWER CPU RAM
	LD	A,00H			; SIGNAL SUCCESS
	RET
	
MD_RDONLY:
	LD	DE,STR_READONLY		; SET DE TO START OF ERROR MESSAGE
	CALL	WRITESTR		; PRINT ERROR MESSAGE
	LD	A,1			; SEND BAD SECTOR ERROR BACK
	RET				; BDOS WILL ALSO PRINT ITS OWN ERROR MESSAGE
;
;__________________________________________________________________________________________________
MD_SECADR:
; DETERMINE MEMORY ADDRESS CORRESPONDING TO CURRENT SECTOR
; SECTOR SIZE = 128, SO JUST MULTIPLY BY 128
; RETURNS ADDRESS IN HL
	LD	HL,(SEKSEC)		; GET SECTOR INTO HL
	LD	B,7
MD_SECADR1:
	ADD	HL,HL
	DJNZ	MD_SECADR1
	RET
;__________________________________________________________________________________________________
MD_PGSEL:
; SELECT MEMORY PAGE BASED ON DRIVE AND TRACK
; DRIVE UNIT 0 = ROM, OTHERWISE RAM

	LD	A,(SEKTRK)
	INC	A			; OFFSET PAST RESERVED 32KB SYSTEM AREA OF RAM/ROM!
	INC	A			; OFFSET ANOTHER 32K PAST DRIVER BANK
	LD	C,A
	LD	A,(SEKDU)
	OR	A
	LD	A,C
	JP	Z,ROMPG			; DEVICE/UNIT = 0?  YES, ROM PAGE
	JP	RAMPG			; ELSE RAM PAGE
;
;__________________________________________________________________________________________________
MD_DMACPY:
; COPIES ONE CPM SECTOR FROM ONE MEMORY ADDRESS TO ANOTHER
; INPUT DE=SOURCE ADDRESS, HL=TARGET ADDRESS, USES BC
	LD	BC,128			; BC IS COUNTER FOR FIXED SIZE TRANSFER (128 BYTES)
	LDIR				; TRANSFER
	RET
;
#INCLUDE "memmgr.asm"
;
;==================================================================================================
; UTILITY FUNCTIONS
;==================================================================================================
;
#DEFINE	CIOMODE_CBIOS
ORG_UTIL	.EQU	$
#INCLUDE "util.asm"
SIZ_UTIL	.EQU	$ - ORG_UTIL
		.ECHO	"UTIL occupies "
		.ECHO	SIZ_UTIL
		.ECHO	" bytes.\n"
;
;==================================================================================================
; DIAGNOSTICS
;==================================================================================================
;
#IF DSKTRACE
;__________________________________________________________________________________________________
PRTSELDSK:
	CALL	NEWLINE
	PUSH	BC
	PUSH	DE
	LD	B,E
	LD	DE,STR_SELDSK
	CALL	WRITESTR
	CALL	PC_SPACE
	LD	DE,STR_DSK
	LD	A,C
	CALL	PRTHEXBYTE
	CALL	PC_SPACE
	CALL	PC_LBKT
	LD	A,B
	CALL	PRTHEXBYTE
	CALL	PC_RBKT
	POP	DE
	POP	BC
	RET
;
;__________________________________________________________________________________________________
PRTHOME:
	CALL	NEWLINE
	LD	DE,STR_HOME
	CALL	WRITESTR
	RET
;
;__________________________________________________________________________________________________
PRTDSKOP:

	LD	(XSTKSAV),SP
	LD	SP,XSTK
	
	CALL	NEWLINE
	LD	A,(DSKOP)
	LD	DE,STR_READ
	CP	DOP_READ
	CALL	Z,WRITESTR
	LD	DE,STR_WRITE
	CP	DOP_WRITE
	CALL	Z,WRITESTR
	LD	A,C
	CALL	Z,PRTHEXBYTE
	LD	DE,STR_DSK
	CALL	WRITESTR
	LD	A,(SEKDSK)
	CALL	PRTHEXBYTE
	LD	DE,STR_TRK
	CALL	WRITESTR
	LD	BC,(SEKTRK)
	CALL	PRTHEXWORD
	LD	DE,STR_SEC
	CALL	WRITESTR
	LD	BC,(SEKSEC)
	CALL	PRTHEXWORD
	
	LD	SP,(XSTKSAV)

	RET

	RET
	
XSTKSAV	.DW	0
	.FILL	$20
XSTK	.EQU	$
;
STR_SELDSK	.DB	"SELDSK$"
STR_HOME	.DB	"HOME$"
STR_READ	.DB	"READ$"
STR_WRITE	.DB	"WRITE$"
STR_DSK		.DB	" DSK=$"
STR_TRK		.DB	" TRK=$"
STR_SEC		.DB	" SEC=$"
;
#ENDIF
;
;==================================================================================================
; DATA
;==================================================================================================
;
STR_BANNER	.DB	OSLBL, " for ", PLATFORM_NAME, " (CBIOS v", BIOSVER, ")$"
VAR_LOC		.DB	VARIANT
TST_LOC		.DB	TIMESTAMP
;
STR_INITRAMDISK	.DB	"\r\nFormatting RAMDISK...$"
STR_READONLY	.DB 	"\r\nCBIOS Err: Read Only Drive$"
STR_STALE	.DB 	"\r\nCBIOS Err: Stale Drive$"
;
SECADR:		.DW 	0		; ADDRESS OF SECTOR IN ROM/RAM PAGE
DEFDRIVE	.DB	0		; DEFAULT DRIVE
;
; DOS DISK VARIABLES
;
DSKOP:		.DB	0		; DISK OPERATION (DOP_READ/DOP_WRITE)
WRTYPE:		.DB 	0		; WRITE TYPE (0=NORMAL, 1=DIR (FORCE), 2=FIRST RECORD OF BLOCK)
DMAADR:		.DW 	0		; DIRECT MEMORY ADDRESS
HSTWRT:		.DB	0		; TRUE = BUFFER IS DIRTY
BUFADR:		.DW	$8000		; ADDRESS OF PHYSICAL SECTOR BUFFER (DEFAULT MATCHES HBIOS)
;
; DISK I/O REQUEST PENDING
;
SEK:
SEKDSK:		.DB 	0		; DISK NUMBER 0-15
SEKTRK:		.DW 	0		; TWO BYTES FOR TRACK # (LOGICAL)
SEKSEC:		.DW 	0		; TWO BYTES FOR SECTOR # (LOGICAL)
SEKDU:		.DB 	0		; DEVICE/UNIT
SEKDPH:		.DW	0		; ADDRESS OF ACTIVE (SELECTED) DPH
SEKOFF:		.DW	0		; TRACK OFFSET IN EFFECT FOR LU
SEKACT:		.DB	TRUE		; ALWAYS TRUE!
;
; RESULT OF TRANSLATION CPM TO PHYSICAL TRANSLATION
;
XLT:
XLTDSK		.DB	0
XLTTRK		.DW	0
XLTSEC		.DW	0
XLTDU		.DB	0
XLTDPH		.DW	0
XLTOFF:		.DW	0
XLTACT		.DB	TRUE		; ALWAYS TRUE!
;
XLTSIZ		.EQU	$ - XLT
;
; DSK/TRK/SEC IN BUFFER (VALID WHEN HSTACT=TRUE)
;
HST:
HSTDSK		.DB	0		; DISK IN BUFFER
HSTTRK		.DW	0		; TRACK IN BUFFER
HSTSEC		.DW	0		; SECTOR IN BUFFER
HSTDU		.DB	0		; DEVICE/UNIT IN BUFFER
HSTDPH		.DW	0		; CURRENT DPH ADDRESS
HSTOFF		.DW	0		; TRACK OFFSET IN EFFECT FOR LU
HSTACT		.DB	0		; TRUE = BUFFER HAS VALID DATA
;
; SEQUENTIAL WRITE TRACKING FOR UNALLOCATED BLOCK
;
UNA:
UNADSK:		.DB 	0		; DISK NUMBER 0-15
UNATRK:		.DW 	0		; TWO BYTES FOR TRACK # (LOGICAL)
UNASEC:		.DW 	0		; TWO BYTES FOR SECTOR # (LOGICAL)
;
UNASIZ		.EQU	$ - UNA
;
UNACNT:		.DB	0		; COUNT DOWN UNALLOCATED RECORDS IN BLOCK
UNASPT:		.DW	0		; SECTORS PER TRACK
;
DIRBF:		.FILL 	128,00H		; SCRATCH DIRECTORY AREA
;
; DRIVER STORAGE
;
; MEMORY DISK 00: ROM DISK
;
ROMBLKS	.EQU	((ROMSIZE - 64) / 2)
;
		.DB	DIODEV_MD + 0
MDDPH0 	 	.DW 	0000,0000
	 	.DW 	0000,0000
	 	.DW 	DIRBF,DPB_ROM
	 	.DW 	MDCSV0,MDALV0
;
CKS_ROM	.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_ROM	.EQU	((ROMBLKS + 7) / 8)	; ALS: BLKS / 8 (ROUNDED UP)
;
; MEMORY DISK 01: RAM DISK
;
RAMBLKS	.EQU	((RAMSIZE - 96) / 2)
;
		.DB	DIODEV_MD + 1
MDDPH1	 	.DW 	0000,0000
	 	.DW 	0000,0000
	 	.DW 	DIRBF,DPB_RAM
	 	.DW 	MDCSV1,MDALV1
;
CKS_RAM	.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_RAM	.EQU	((RAMBLKS + 7) / 8)	; ALS: BLKS / 8 (ROUNDED UP)
;
MDCSV0:		.FILL	0		; NO DIRECTORY CHECKSUM, NON-REMOVABLE DRIVE
MDALV0:		.FILL	ALS_ROM,00H	; MAX OF 512 DATA BLOCKS
MDCSV1:		.FILL	0		; NO DIRECTORY CHECKSUM, NON-REMOVABLE DRIVE
MDALV1:		.FILL	ALS_RAM,00H	; MAX OF 256 DATA BLOCKS
;
#IF (FDENABLE)
ORG_FD_DPH	.EQU	$
  #INCLUDE "fd_dph.asm"
SIZ_FD_DPH	.EQU	$ - ORG_FD_DPH
		.ECHO	"FD DPH occupies "
		.ECHO	SIZ_FD_DPH
		.ECHO	" bytes.\n"
#ENDIF

#IF (IDEENABLE)
ORG_IDE_DPH	.EQU	$
  #INCLUDE "ide_dph.asm"
SIZ_IDE_DPH	.EQU	$ - ORG_IDE_DPH
		.ECHO	"IDE DPH occupies "
		.ECHO	SIZ_IDE_DPH
		.ECHO	" bytes.\n"
#ENDIF

#IF (PPIDEENABLE)
ORG_PPIDE_DPH	.EQU	$
  #INCLUDE "ppide_dph.asm"
SIZ_PPIDE_DPH	.EQU	$ - ORG_PPIDE_DPH
		.ECHO	"PPIDE DPH occupies "
		.ECHO	SIZ_PPIDE_DPH
		.ECHO	" bytes.\n"
#ENDIF

#IF (SDENABLE)
ORG_SD_DPH	.EQU	$
  #INCLUDE "sd_dph.asm"
SIZ_SD_DPH	.EQU	$ - ORG_SD_DPH
		.ECHO	"SD DPH occupies "
		.ECHO	SIZ_SD_DPH
		.ECHO	" bytes.\n"
#ENDIF

#IF (PRPENABLE & PRPSDENABLE)
ORG_PRPSD_DPH	.EQU	$
  #INCLUDE "prp_dph.asm"
SIZ_PRPSD_DPH	.EQU	$ - ORG_PRPSD_DPH
		.ECHO	"PRPSD DPH occupies "
		.ECHO	SIZ_PRPSD_DPH
		.ECHO	" bytes.\n"
#ENDIF
#IF (PPPENABLE & PPPSDENABLE)
ORG_PPPSD_DPH	.EQU	$
  #INCLUDE "ppp_dph.asm"
SIZ_PPPSD_DPH	.EQU	$ - ORG_PPPSD_DPH
		.ECHO	"PPPSD DPH occupies "
		.ECHO	SIZ_PPPSD_DPH
		.ECHO	" bytes.\n"
#ENDIF
#IF (HDSKENABLE)
ORG_HDSK_DPH	.EQU	$
  #INCLUDE "hdsk_dph.asm"
SIZ_HDSK_DPH	.EQU	$ - ORG_HDSK_DPH
		.ECHO	"HDSK DPH occupies "
		.ECHO	SIZ_HDSK_DPH
		.ECHO	" bytes.\n"
#ENDIF
;
; DISK PARAMETER BLOCKS
;
; BLS		BSH	BLM	EXM (DSM<256)	EXM (DSM>255)
; ----------	---	---	-------------	-------------
; 1,024		3	7	0		N/A
; 2,048 	4	15	1		0
; 4,096 	5	31	3		1
; 8,192 	6	63	7		3
; 16,384 	7	127	15		7
;
; AL0/1: EACH BIT SET ALLOCATES A BLOCK OF DIR ENTRIES.  EACH DIR ENTRY
;        IS 32 BYTES.  BIT COUNT = (((DRM + 1) * 32) / BLS)
;
; CKS = (DIR ENT / 4), ZERO FOR NON-REMOVABLE MEDIA
;
; ALS = TOTAL BLKS (DSM + 1) / 8
;__________________________________________________________________________________________________
;
; ROM DISK: 256 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; ROM DISK SIZE = TOTAL ROM - 32K RESERVED FOR SYSTEM USE
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_ROM:
	.DW  	256		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
#IF (ROMBLKS < 256)
	.DB  	1		; EXM: EXTENT MASK
#ELSE
	.DB  	0		; EXM: EXTENT MASK
#ENDIF
	.DW	ROMBLKS - 1	; DSM: TOTAL STORAGE IN BLOCKS - 1
	.DW  	255		; DRM: DIR ENTRIES - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	0		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW  	0		; OFF: ROM DISK HAS NO SYSTEM AREA
;__________________________________________________________________________________________________
;
; RAM DISK: 256 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; RAM DISK SIZE = TOTAL RAM - 64K RESERVED FOR SYSTEM USE
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_RAM:
	.DW  	256		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
#IF (RAMBLKS < 256)
	.DB  	1		; EXM: EXTENT MASK
#ELSE
	.DB  	0		; EXM: EXTENT MASK
#ENDIF
	.DW	RAMBLKS - 1	; DSM: TOTAL STORAGE IN BLOCKS - 1
	.DW  	255		; DRM: DIR ENTRIES - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	0		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW  	0		; OFF: RESERVED TRACKS = 0 TRK
;__________________________________________________________________________________________________
;
; 8MB HARD DISK DRIVE, 65 TRKS, 1024 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 4K, DIRECTORY ENTRIES = 128
; SEC/TRK ENGINEERED SO THAT AFTER DEBLOCKING, SECTOR NUMBER OCCUPIES 1 BYTE (0-255)
;
	.DB	(4096 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_HD:
	.DW  	1024		; SPT: SECTORS PER TRACK
	.DB  	5		; BSH: BLOCK SHIFT FACTOR
	.DB  	31		; BLM: BLOCK MASK
	.DB  	1		; EXM: EXTENT MASK
	.DW  	2047		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((8MB - 128K OFF) / 4K BLS) - 1 = 2047
	.DW  	511		; DRM: DIR ENTRIES - 1 = 512 - 1 = 511
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	0		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	1		; OFF: RESERVED TRACKS = 1 TRKS * (512 B/SEC * 1024 SEC/TRK) = 128K
;__________________________________________________________________________________________________
;
; IBM 720KB 3.5" FLOPPY DRIVE, 80 TRKS, 36 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 128
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD720:
	.DW  	36		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	350		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((720K - 18K OFF) / 2K BLS) - 1 = 350
	.DW  	127		; DRM: DIR ENTRIES - 1 = 128 - 1 = 127
	.DB  	11000000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	32		; CKS: DIRECTORY CHECK VECTOR SIZE = 128 / 4
	.DW  	4		; OFF: RESERVED TRACKS = 4 TRKS * (512 B/SEC * 36 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 1.44MB 3.5" FLOPPY DRIVE, 80 TRKS, 72 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD144:
	.DW  	72		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	710		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,440K - 18K OFF) / 2K BLS) - 1 = 710
	.DW  	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 72 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 360KB 5.25" FLOPPY DRIVE, 40 TRKS, 9 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 128
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD360:
	.DW  	36		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	170		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((360K - 18K OFF) / 2K BLS) - 1 = 170
	.DW  	127		; DRM: DIR ENTRIES - 1 = 128 - 1 = 127
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	32		; CKS: DIRECTORY CHECK VECTOR SIZE = 128 / 4
	.DW  	4		; OFF: RESERVED TRACKS = 4 TRKS * (512 B/SEC * 36 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 1.20MB 5.25" FLOPPY DRIVE, 80 TRKS, 60 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD120:
	.DW  	60		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	591		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,200K - 15K OFF) / 2K BLS) - 1 = 591
	.DW  	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 60 SEC/TRK) = 15K
;__________________________________________________________________________________________________
;
; IBM 1.11MB 8" FLOPPY DRIVE, 74 TRKS, 60 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD111:
	.DW  	60		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	546		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,110K - 15K OFF) / 2K BLS) - 1 = 546
	.DW  	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 60 SEC/TRK) = 15K
;
;==================================================================================================
; START OF HIMEM AREA
;==================================================================================================
;
; THE FOLLOWING DATA STRUCTURES MUST NOT CROSS A PAGE BOUNDARY DUE TO OPTIMIZATION OF
; LOOKUP CODE.  SO, HERE WE ORG SO THAT THERE IS JUST ENOUGH SPACE AT THE TOP OF THE
; CBIOS FOR THE DATA STRUCTURES.  OBVIOUSLY, FOR THIS TO WORK, CBIOS MUST BE SET TO
; END AT A PAGE BOUNDARY, WHICH IS INTENDED
;
SLACK		.EQU	(CBIOS_END - $ - 32 - 32 - 16 - 512)
		.FILL	SLACK,00H
;
		.ECHO	"CBIOS space remaining: "
		.ECHO	SLACK
		.ECHO	" bytes.\n"
;
;==================================================================================================
; DPB MAPPING TABLE
;==================================================================================================
;
; MAP MEDIA ID'S TO APPROPRIATE DPB ADDRESSEES
; THE ENTRIES IN THIS TABLE MUST CONCIDE WITH THE VALUES
; OF THE MEDIA ID'S (SAME SEQUENCE, NO GAPS)
;
DPB_MAP:
	.DW	0		; MID_NONE (NO MEDIA)
	.DW	DPB_ROM		; MID_MDROM
	.DW	DPB_RAM		; MID_MDRAM
	.DW	DPB_HD		; MID_HD
	.DW	DPB_FD720	; MID_FD720
	.DW	DPB_FD144	; MID_FD144
	.DW	DPB_FD360	; MID_FD360
	.DW	DPB_FD120	; MID_FD120
	.DW	DPB_FD111	; MID_FD111
;
DPB_CNT	.EQU	($ - DPB_MAP) / 2
;
;==================================================================================================
; DRIVE LETTER MAPPING TABLE
;==================================================================================================
;
; THE DISK MAP TABLE BELOW MAPS DRIVE LETTERS TO PHYSICAL STORAGE DEVICES.
; CP/M DRIVE LETTERS ARE ASSIGNED BASED ON THE ORDER OF ENTRIES IN THE TABLE,
; SO THE FIRST ENTRY IS A:, THE SECOND ENTRY IS B:, ETC.
; EACH ENTRY IS A COMBINATION (OR) OF THE DEVICE AND THE UNIT.
;   DIODEV_MD = MEMORY DISKS (ROM/RAM) (UNIT 0 = ROM, UNIT 1 = RAM)
;   DIODEV_FD = FLOPPY DISKS (TWO UNITS (0/1) SUPPORTED)
;   DIODEV_IDE = IDE DISKS (TWO UNITS (0/1) MASTER/SLAVE SUPPORTED)
;   DIODEV_PPIDE = PPIDE DISKS (TWO UNITS (0/1) MASTER/SLAVE SUPPORTED)
;   DIODEV_SD = SD CARD (ONE UNIT SUPPORTED)
;   DIODEV_PRPSD = PROPIO SD CARD (ONE UNIT SUPPORTED)
;   DIODEV_PPPSD = PROPIO SD CARD (ONE UNIT SUPPORTED)
;   DIODEV_HDDSK = SIMH HARD DISK (TWO UNITS SUPPORTED)
;
; DRIVE LETTERS ARE ASSIGNED SEQUENTIALLY.
;
; ALTERNATIVELY, YOU CAN DEFINE A MACRO CALLED CUSTOM_DPHMAP THAT
; DEFINES AN ENTIRELY CUSTOM MAPPING
;
DPH_MAP:
#IFDEF CUSTOM_DPHMAP
	CUSTOM_DPHMAP
#ELSE
  #IF (DSKMAP == DM_ROM)
	.DW	MDDPH0
  #ENDIF
  #IF (DSKMAP == DM_RAM)
	.DW	MDDPH1
  #ENDIF
  #IF (DSKMAP == DM_FD)
	.DW	FDDPH0
	.DW	FDDPH1
  #ENDIF
  #IF (DSKMAP == DM_IDE)
	.DW	IDEDPH0
	.DW	IDEDPH1
	.DW	IDEDPH2
	.DW	IDEDPH3
  #ENDIF
  #IF (DSKMAP == DM_PPIDE)
	.DW	PPIDEDPH0
	.DW	PPIDEDPH1
	.DW	PPIDEDPH2
	.DW	PPIDEDPH3
  #ENDIF
  #IF (DSKMAP == DM_SD)
	.DW	SDDPH0
	.DW	SDDPH1
	.DW	SDDPH2
	.DW	SDDPH3
  #ENDIF
  #IF (DSKMAP == DM_PRPSD)
	.DW	PRPSDDPH0
	.DW	PRPSDDPH1
	.DW	PRPSDDPH2
	.DW	PRPSDDPH3
  #ENDIF
  #IF (DSKMAP == DM_PPPSD)
	.DW	PPPSDDPH0
	.DW	PPPSDDPH1
	.DW	PPPSDDPH2
	.DW	PPPSDDPH3
  #ENDIF
  #IF (DSKMAP == DM_HDSK)
	.DW	HDSKDPH0
	.DW	HDSKDPH1
	.DW	HDSKDPH2
	.DW	HDSKDPH3
  #ENDIF
  #IF (DSKMAP != DM_ROM)
	.DW	MDDPH0
  #ENDIF
  #IF (DSKMAP != DM_RAM)
	.DW	MDDPH1			; was MDDHP1
  #ENDIF
  #IF ((DSKMAP != DM_FD) & FDENABLE)
	.DW	FDDPH0
	.DW	FDDPH1
  #ENDIF
  #IF ((DSKMAP != DM_IDE) & IDEENABLE)
	.DW	IDEDPH0
	.DW	IDEDPH1
	.DW	IDEDPH2
	.DW	IDEDPH3
  #ENDIF
  #IF ((DSKMAP != DM_PPIDE) & PPIDEENABLE)
	.DW	PPIDEDPH0
	.DW	PPIDEDPH1
	.DW	PPIDEDPH2
	.DW	PPIDEDPH3
  #ENDIF
  #IF ((DSKMAP != DM_SD) & SDENABLE)
	.DW	SDDPH0
	.DW	SDDPH1
	.DW	SDDPH2
	.DW	SDDPH3
  #ENDIF
  #IF ((DSKMAP != DM_PRPSD) & PRPENABLE & PRPSDENABLE)
	.DW	PRPSDDPH0
	.DW	PRPSDDPH1
	.DW	PRPSDDPH2
	.DW	PRPSDDPH3
  #ENDIF
  #IF ((DSKMAP != DM_PPPSD) & PPPENABLE & PPPSDENABLE)
	.DW	PPPSDDPH0
	.DW	PPPSDDPH1
	.DW	PPPSDDPH2
	.DW	PPPSDDPH3
  #ENDIF
  #IF ((DSKMAP != DM_HDSK) & HDSKENABLE)
	.DW	HDSKDPH0
	.DW	HDSKDPH1
	.DW	HDSKDPH2
	.DW	HDSKDPH3
  #ENDIF
#ENDIF	; CUSTOM_DPHMAP
;
DPH_CNT	.EQU	($ - DPH_MAP) / 2
	.FILL	(16 - DPH_CNT) * 2,0FFH
DSK_CNT	.EQU	DPH_CNT
;
;==================================================================================================
; CHARACTER DEVICE MAPPING
;==================================================================================================
;
;	MAP LOGICAL TO PHYSICAL DEVICES
;
LD_TTY	.EQU	CIODEV_UART
LD_CRT	.EQU	CIODEV_CRT
LD_BAT	.EQU	CIODEV_BAT
LD_UC1	.EQU	CIODEV_UART
LD_PTR	.EQU	CIODEV_UART
LD_UR1	.EQU	CIODEV_UART
LD_UR2	.EQU	CIODEV_UART
LD_PTP	.EQU	CIODEV_UART
LD_UP1	.EQU	CIODEV_UART
LD_UP2	.EQU	CIODEV_UART
LD_LPT	.EQU	CIODEV_UART
LD_UL1	.EQU	CIODEV_UART
;
#IF (PLATFORM == PLT_N8)
LD_UC1	.SET	CIODEV_UART + 1
#ENDIF
;
#IF (VDUENABLE)
LD_CRT	.SET	CIODEV_CRT
#ENDIF
#IF (N8VENABLE)
LD_CRT	.SET	CIODEV_CRT
#ENDIF
#IF (PRPENABLE & PRPCONENABLE)
LD_CRT	.SET	CIODEV_PRPCON
#ENDIF
#IF (PPPENABLE & PPPCONENABLE)
LD_CRT	.SET	CIODEV_PPPCON
#ENDIF
;
CIO_MAP:
;
	; CONSOLE
	.DB	LD_TTY			; CON:=TTY: (IOBYTE XXXXXX00)
	.DB	LD_CRT			; CON:=CRT: (IOBYTE XXXXXX01)
	.DB	LD_BAT			; CON:=BAT: (IOBYTE XXXXXX10)
	.DB	LD_UC1			; CON:=UC1: (IOBYTE XXXXXX11)
	; READER
	.DB	LD_TTY			; RDR:=TTY: (IOBYTE XXXX00XX)
	.DB	LD_PTR			; RDR:=PTR: (IOBYTE XXXX01XX)
	.DB	LD_UR1			; RDR:=UR1: (IOBYTE XXXX10XX)
	.DB	LD_UR2			; RDR:=UR2: (IOBYTE XXXX11XX)
	; PUNCH
	.DB	LD_TTY			; PUN:=TTY: (IOBYTE XX00XXXX)
	.DB	LD_PTP			; PUN:=PTP: (IOBYTE XX01XXXX)
	.DB	LD_UP1			; PUN:=UP1: (IOBYTE XX10XXXX)
	.DB	LD_UP2			; PUN:=UP2: (IOBYTE XX11XXXX)
	; LIST
	.DB	LD_TTY			; LST:=TTY: (IOBYTE 00XXXXXX)
	.DB	LD_CRT			; LST:=CRT: (IOBYTE 01XXXXXX)
	.DB	LD_LPT			; LST:=LPT: (IOBYTE 10XXXXXX)
	.DB	LD_UL1			; LST:=UL1: (IOBYTE 11XXXXXX)
;
;==================================================================================================
; SECTOR AND CONFIG BUFFER;
;==================================================================================================
;
;  A 512 AREA IS ALLOCATED AT FD00 AND IS USED FOR TWO PURPOSES:
;    1) AS THE DISK SECTOR BUFFER AFTER CBIOS COLD INIT IS DONE
;    2) FOR CBIOS INIT CODE THAT CAN BE DISCARDED AFTER INITIALIZTION:
;       A) SYSTEM CONFIGURATION DATA BUFFER
;       B) CBIOS INIT CODE THAT CAN BE DISCARDED AFTER INIT
;
	.FILL	0FD00H - $,00H		; MAKE SURE SEC/CFGBUF STARTS AT FD00
;
SECBUF:					; START OF 512 BYTE DISK SECTOR
CFGBUF:					; START OF 256 BYTE CONFIG BUFFER
	.FILL	256,0
;
INIT:
	DI
	IM	1
	
	; SETUP A TEMP STACK IN UPPER 32K
	LD	SP,ISTACK		; STACK FOR INITIALIZATION
			
	; ENSURE RAM PAGE ZERO ACTIVE
	CALL	RAMPGZ
	
	; THIS INIT CODE WILL BE OVERLAID, SO WE ARE GOING
	; TO MODIFY THE BOOT ENTRY POINT TO CAUSE A PANIC
	; TO EASILY IDENTIFY IF SOMETHING TRIES TO INVOKE
	; THE BOOT ENTRY POINT AFTER INIT IS DONE.
	LD	A,0CDH			; "CALL" INSTRUCTION
	LD	(BOOT),A		; STORE IT BOOT ENTRY POINT
	LD	HL,PANIC		; ADDRESS OF PANIC ROUTINE
	LD	(BOOT+1),HL		; STORE IT AT BOOT ENTRY + 1
	
	; PARAMETER INITIALIZATION
	LD	A,DEFIOBYTE		; LOAD DEFAULT IOBYTE
	LD	(IOBYTE),A		; STORE IT
	
#IF ((PLATFORM != PLT_N8) & (PLATFORM != PLT_S100))
	IN	A,(RTC)			; RTC PORT, BIT 6 HAS STATE OF CONFIG JUMPER
	BIT	6,A			; BIT 6 HAS CONFIG JUMPER STATE
	LD	A,DEFIOBYTE		; ASSUME WE WANT DEFAULT IOBYTE VALUE
	JR	NZ,INIT1		; IF BIT6=1, NOT SHORTED, CONTINUE WITH DEFAULT
	LD	A,ALTIOBYTE		; LOAD ALT IOBYTE VALUE
INIT1:	
	LD	(IOBYTE),A		; SET THE ACTIVE IOBYTE
#ENDIF
	
	; DEFAULT DRIVE
	CALL	DEFDRV			; DETERMINE DEFAULT DRIVE
	LD	A,(DEFDRIVE)		; GET DEFAULT DRIVE
	LD	(CDISK),A		; SETUP CDISK
	
	; STARTUP MESSAGE
	CALL	NEWLINE
	LD	DE,STR_BANNER
	CALL	WRITESTR
	CALL	NEWLINE
	
	; SAVE COMMAND PROCESSOR TO CACHE IN RAM1
	LD	A,1
	CALL	RAMPG
	LD	HL,CPM_LOC		; LOCATION OF ACTIVE COMMAND PROCESSOR
	LD	DE,0800H		; LOCATION IN RAM 1 OF COMMAND PROCESSOR CACHE
	LD	BC,CCPSIZ		; SIZE OF COMMAND PROCESSOR
	LDIR
	CALL	RAMPGZ

	; SYSTEM INITIALIZATION
	CALL	BLKRES			; RESET DISK (DE)BLOCKING ALGORITHM
	CALL	MD_INIT			; INITIALIZE MEMORY DISK DRIVER (RAM/ROM)

	CALL	NEWLINE

	; STARTUP CPM
	JP	GOCPM
;
DEFDRV:
	; START BY ASSUMING DRIVE 0 IS DEFAULT
	XOR	A			; ZERO
	LD	(DEFDRIVE),A		; STORE IT
	
	; GET CONFIG INFO (STORE IN CFGBUF)
	LD	BC,$F000
	LD	DE,CFGBUF
	RST	08

	; IF NOT A DISK DEVICE BOOT, BAIL OUT, NOTHING MORE TO DO
	LD	A,(CFGBUF+DISKBOOT)	; DID WE BOOT FROM A DISK DEVICE?
	OR	A			; SET FLAGS
	RET	Z

	; SCAN DRIVES TO MATCH BOOTDEVICE/LU AND STORE DEFDRIVE
	LD	C,-1			; INIT CURRENT DRIVE FOR LOOP
DEFDRV1:
	INC	C			; NEXT DRIVE
	LD	A,C			; A = C
	CP	16			; MAX DRIVE IS 15, PAST IT?
	RET	Z			; NO MATCHES, BAIL OUT
	CALL	DSK_GETDPH		; GET POINTER TO DPH INTO HL
	OR	A			; SET FLAGS
	JR	NZ,DEFDRV1		; INVALID DRIVE, BYPASS IT
	DEC	HL			; POINT TO DEVICE/UNIT
	LD	E,(HL)			; E = DEVICE/UNIT BYTE
	LD	A,(CFGBUF+BOOTDEVICE)	; A = BOOTDEVICE
	CP	E			; MATCH BOOTDEVICE?
	JR	NZ,DEFDRV1		; NOPE, NEXT DRIVE
	INC	HL			; POINT HL BACK TO START OF DPH
	CALL	DSK_GETLU		; GET POINTER TO LU DATA IN HL
	JR	NZ,DEFDRV2		; NO LU SUPPORT, DEVICE ALREADY MATCHED, WE ARE DONE
	LD	E,(HL)			; E = LU LSB
	LD	A,(CFGBUF+BOOTLU)	; A = BOOT LU LSB
	CP	E			; MATCH LSB?
	JR	NZ,DEFDRV1		; NOPE, NEXT DRIVE
	INC	HL			; POINT TO LU MSB
	LD	E,(HL)			; E = LU MSB
	LD	A,(CFGBUF+BOOTLU+1)	; A = BOOT LU MSB
	CP	E			; MATCH MSB?
	JR	NZ,DEFDRV1		; NOPE, NEXT DRIVE

DEFDRV2:
	; WE HAVE A MATCH, RECORD NEW DEFAULT DRIVE
	LD	A,C			; C HAS MATCHING DRIVE, MOVE TO A
	LD	(DEFDRIVE),A		; SAVE IT
;
	RET
;
	.FILL	(256 - ($ - INIT)),0	; FILL REMAINDER OF PAGE
;
ISTACK	.EQU	$			; TEMP STACK SPACE
;
	.END
