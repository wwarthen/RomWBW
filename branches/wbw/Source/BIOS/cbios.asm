;__________________________________________________________________________________________________
;
;	CBIOS FOR SBC
;
;	BY ANDREW LYNCH, WITH INPUT FROM MANY SOURCES
;	ROMWBW ADAPTATION BY WAYNE WARTHEN
;__________________________________________________________________________________________________
;
; The std.asm file contains the majority of the standard equates
; that describe data structures, magic values and bit fields used 
; by the CBIOS.
;
#INCLUDE "std.asm"
;
     	.ORG	CBIOS_LOC		; DEFINED IN STD.ASM
;
STACK	.EQU	CBIOS_END		; USE SLACK SPACE FOR STACK AS NEEDED
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
	JP	READER			; #7  - READER CHARACTER IN
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
;==================================================================================================
;   CBIOS STAMP FOR ROMWBW
;==================================================================================================
;
; RomWBW CBIOS places the following stamp data into page zero
; at address $40.  The address range $40-$4F is reserved by CP/M
; as a scratch area for CBIOS.  This data below is copied there at
; every warm start.  It allows applications to identify RomWBW CBIOS.
; Additionally, it contains a pointer to additional CBIOS extension
; data (CBX) specific to RomWBW CBIOS.
;
; RomWBW CBIOS page zero stamp starts at $40
; $40-$41: Marker ('W', ~'W')
; $42-$43: Version bytes: major/minor, update/patch
; $44-$45: CBIOS Extension Info address
;
STPLOC	.EQU	$40
STPIMG:	.DB	'W',~'W'		; MARKER
	.DB	RMJ << 4 | RMN		; FIRST BYTE OF VERSION INFO
	.DB	RUP << 4 | RTP		; SECOND BYTE OF VERSION INFO
	.DW	CBX			; ADDRESS OF CBIOS EXT DATA
STPSIZ	.EQU	$ - STPIMG
;
; The following section contains key information and addresses for the
; RomWBW CBIOS.  A pointer to the start of this section is stored with
; with the ZPX data in page zero at $44 (see above).
;
CBX:
DEVMAPADR	.DW	DEVMAP		; DEVICE MAP ADDRESS
DRVMAPADR	.DW	0		; DRIVE MAP ADDRESS (FILLED IN LATER)
DPBMAPADR	.DW	DPBMAP		; DPB MAP ADDRESS
;
CBXSIZ	.EQU	$ - CBX
	.ECHO	"CBIOS extension info occupies "
	.ECHO	CBXSIZ
	.ECHO	" bytes.\n"
;
;==================================================================================================
; CHARACTER DEVICE MAPPING
;==================================================================================================
;
;	MAP LOGICAL CHARACTER DEVICES TO PHYSICAL CHARACTER DEVICES
;
; IOBYTE (0003H)
; ==============
;
;      Device         LST:    PUN:    RDR:    CON:
; Bit position        7 6     5 4     3 2     1 0
;
; Dec   Binary
;
;  0      00          TTY:    TTY:    TTY:    TTY:
;  1      01          CRT:    PTP:    PTR:    CRT:
;  2      10          LPT:    UP1:    UR1:    BAT:
;  3      11          UL1:    UP2:    UR2:    UC1:
;
; TTY:	Teletype device (slow speed console)
; CRT:	Cathode ray tube device (high speed console)
; BAT:	Batch processing (input from RDR:, output to LST:)
; UC1:	User-defined console
; PTR:	Paper tape reader (high speed reader)
; UR1:	User-defined reader #1
; UR2:	User-defined reader #2
; PTP:	Paper tape punch (high speed punch)
; UP1:	User-defined punch #1
; UP2:	User-defined punch #2
; LPT:	Line printer
; UL1:	User-defined list device #1
;
#IF (PLATFORM == PLT_UNA)

LD_TTY	.EQU	0		; -> COM0:
LD_CRT	.EQU	0		; -> COM14:
LD_BAT	.EQU	CIODEV_BAT
LD_UC1	.EQU	0		; -> COM1:
LD_PTR	.EQU	0		; -> COM1:
LD_UR1	.EQU	0		; -> COM2:
LD_UR2	.EQU	0		; -> COM3:
LD_PTP	.EQU	0		; -> COM1:
LD_UP1	.EQU	0		; -> COM2:
LD_UP2	.EQU	0		; -> COM3:
LD_LPT	.EQU	0		; -> LPT0:
LD_UL1	.EQU	0		; -> LPT1:

#ELSE

#IF ((PLATFORM == PLT_N8) | (PLATFORM == PLT_MK4))
TTYDEV	.EQU	CIODEV_ASCI
#ELSE
TTYDEV	.EQU	CIODEV_UART
#ENDIF
;
LD_TTY	.EQU	TTYDEV		; -> COM0:
LD_CRT	.EQU	TTYDEV		; -> COM14:
LD_BAT	.EQU	CIODEV_BAT
LD_UC1	.EQU	TTYDEV		; -> COM1:
LD_PTR	.EQU	TTYDEV		; -> COM1:
LD_UR1	.EQU	TTYDEV		; -> COM2:
LD_UR2	.EQU	TTYDEV		; -> COM3:
LD_PTP	.EQU	TTYDEV		; -> COM1:
LD_UP1	.EQU	TTYDEV		; -> COM2:
LD_UP2	.EQU	TTYDEV		; -> COM3:
LD_LPT	.EQU	TTYDEV		; -> LPT0:
LD_UL1	.EQU	TTYDEV		; -> LPT1:
;
#IF ((PLATFORM == PLT_N8) | (PLATFORM == PLT_MK4))
LD_UC1	.SET	CIODEV_ASCI + 1
LD_PTR	.SET	CIODEV_ASCI + 1
LD_PTP	.SET	CIODEV_ASCI + 1
#ENDIF
;
#IF (UARTENABLE & (UARTCNT >= 2))
LD_UC1	.SET	CIODEV_UART + 1
LD_PTR	.SET	CIODEV_UART + 1
LD_PTP	.SET	CIODEV_UART + 1
#ENDIF
;
#IF (VDUENABLE | CVDUENABLE | N8VENABLE)
LD_CRT	.SET	CIODEV_CRT
#ENDIF
#IF (PRPENABLE & PRPCONENABLE)
LD_CRT	.SET	CIODEV_PRPCON
#ENDIF
#IF (PPPENABLE & PPPCONENABLE)
LD_CRT	.SET	CIODEV_PPPCON
#ENDIF

#ENDIF
;
	.DB	DEVCNT
DEVMAP:
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
DEVCNT	.EQU	($ - DEVMAP)
	.ECHO	DEVCNT
	.ECHO	" Input/Output devices defined.\n"
;
;==================================================================================================
;   DRIVE MAPPING TABLE
;==================================================================================================
;
; Disk mapping is done using a drive map table (DRVMAP) which is built
; dynamically at cold boot.  See the DRV_INIT routine.  This table is
; made up of entries as documented below.  The table is prefixed with one
; byte indicating the number of entries.  The index of the entry indicates
; the drive letter, so the first entry is A:, the second entry is B:, etc.
;
;	BYTE: DEVICE/UNIT (OR JUST UNIT FOR UNA)
;	BYTE: SLICE
;	WORD: ADDRESS OF DPH FOR THE DRIVE
;
;==================================================================================================
; DPB MAPPING TABLE
;==================================================================================================
;
; MAP MEDIA ID'S TO APPROPRIATE DPB ADDRESSEES
; THE ENTRIES IN THIS TABLE MUST CONCIDE WITH THE VALUES
; OF THE MEDIA ID'S (SAME SEQUENCE, NO GAPS)
;
	.DB	DPBCNT
;
DPBMAP:
	.DW	0		; MID_NONE (NO MEDIA)
	.DW	DPB_ROM		; MID_MDROM
	.DW	DPB_RAM		; MID_MDRAM
	.DW	DPB_RF		; MID_RF
	.DW	DPB_HD		; MID_HD
	.DW	DPB_FD720	; MID_FD720
	.DW	DPB_FD144	; MID_FD144
	.DW	DPB_FD360	; MID_FD360
	.DW	DPB_FD120	; MID_FD120
	.DW	DPB_FD111	; MID_FD111
;
DPBCNT	.EQU	($ - DPBMAP) / 2
;
;==================================================================================================
;   BIOS FUNCTIONS
;==================================================================================================
;
;__________________________________________________________________________________________________

BOOT:
	; STANDARD BOOT INVOCATION
	DI
	IM	1
	LD	SP,STACK	; STACK FOR INITIALIZATION
;
	CALL	INIT		; EXECUTE COLD BOOT CODE ROUTINE
;
	LD	SP,$100		; MOVE STACK SO WE CAN INIT BUFFER AREA
	LD	HL,INIT		; INIT BUFFERS AREA
	LD	BC,CBIOS_END - INIT	; SIZE OF BUFFER SPACE
	CALL	FILL		; DO IT
;
	LD	SP,STACK	; PUT STACK BACK WHERE IT BELONGS
	JR	GOCPM		; THEN OFF TO CP/M WE GO...
;
;__________________________________________________________________________________________________
WBOOT:
	DI
	IM	1
;
	LD	SP,STACK	; STACK FOR INITIALIZATION
;
#IF (PLATFORM == PLT_UNA)
	; RESTORE COMMAND PROCESSOR FROM UNA BIOS CACHE
	LD	BC,$01FB	; UNA FUNC = SET BANK
	LD	DE,BID_BIOS	; UBIOS_PAGE (SEE PAGES.INC)
	RST	08		; DO IT
	PUSH	DE		; SAVE PREVIOUS BANK
	
	LD	HL,(CCPBUF)	; ADDRESS OF CCP BUF IN BIOS MEM
	LD	DE,CPM_LOC	; ADDRESS IN HI MEM OF CCP
	LD	BC,CCP_SIZ	; SIZE OF CCP
	LDIR			; DO IT

	LD	BC,$01FB	; UNA FUNC = SET BANK
	POP	DE		; RECOVER OPERATING BANK
	RST	08		; DO IT
#ELSE
	; RESTORE COMMAND PROCESSOR FROM CACHE IN HB BANK
	LD	B,BF_SYSXCPY	; HBIOS FUNC: SYSTEM EXTENDED COPY
	LD	D,BID_USR	; D = DEST BANK = USR BANK = TPA
	LD	E,BID_BIOS	; E = SRC BANK = HB BANK
	RST	08		; SET BANKS FOR INTERBANK COPY
	LD	B,BF_SYSCPY	; HBIOS FUNC: SYSTEM COPY
	LD	HL,(CCPBUF)	; COPY FROM FIXED LOCATION IN HB BANK
	LD	DE,CPM_LOC	; TO CCP LOCATION IN USR BANK
	LD	IX,CCP_SIZ	; COPY CONTENTS OF COMMAND PROCESSOR
	RST	08		; DO IT
#ENDIF
;
	; SOME APPLICATIONS STEAL THE BDOS SERIAL NUMBER STORAGE
	; AREA (FIRST 6 BYTES OF BDOS) ASSUMING IT WILL BE RESTORED
	; AT WARM BOOT BY RELOADING OF BDOS.  WE DON'T WANT TO RELOAD
	; BDOS, SO INSTEAD THE SERIAL NUMBER STORAGE IS FIXED HERE
	; SO THAT THE DRI SERIAL NUMBER VERIFICATION DOES NOT FAIL
	LD	HL,BDOS_LOC
	LD	B,6
WBOOT1:	LD	(HL),0
	INC	HL
	DJNZ	WBOOT1
;	
	; FALL THRU TO INVOKE CP/M
;
;__________________________________________________________________________________________________			
GOCPM:
#IF (PLATFORM == PLT_UNA)
	; USE A DEDICATED BUFFER FOR UNA PHYSICAL DISK I/O
	LD	HL,SECBUF		; ADDRESS OF PHYSICAL SECTOR BUFFER
	LD	(BUFADR),HL		; SAVE IT IN BUFADR FOR LATER
#ELSE
	; CALL BF_DIOSETBUF WITH A PARM OF ZERO TO CAUSE IT TO RESET
	; THE PHYSICAL DISK BUFFER TO THE DEFAULT LOCATION PRE-ALLOCATED
	; INSIDE OF THE HBIOS BANK.  THE ADDRESS IS RETURNED IN HL AND SAVED.
	LD	B,BF_DIOSETBUF		; GET DISK BUFFER ADR IN HBIOS DRIVER BANK
	LD	HL,0
	RST	08			; MAKE HBIOS CALL
	LD	(BUFADR),HL		; RECORD THE BUFFER ADDRESS
#ENDIF
;
	LD	A,$C3			; LOAD A WITH 'JP' INSTRUCTION (USED BELOW)
;
	; CPU RESET / RST 0 / JP 0 -> WARM START CP/M
	LD	($0000),A		; JP OPCODE GOES HERE
	LD	HL,WBOOTE		; GET WARM BOOT ENTRY ADDRESS
	LD	($0001),HL		; AND PUT IT AT $0001

;	; INT / RST 38 -> INVOKE MONITOR
;	LD	($0038),A
;	LD	HL,GOMON
;	LD	($0039),HL

;	; INT / RST 38 -> PANIC
;	LD	($0038),A
;	LD	HL,PANIC		; PANIC ROUTINE ADDRESS
;	LD	($0039),HL		; POKE IT
	
	; CALL 5 -> INVOKE BDOS
	LD	($0005),A		; JP OPCODE AT $0005
	LD	HL,BDOS_LOC + 6		; GET BDOS ENTRY ADDRESS
	LD	($0006),HL		; PUT IT AT $0006
;
	; INSTALL ROMWBW CBIOS PAGE ZERO STAMP AT $40
	LD	HL,STPIMG		; FORM STAMP DATA IMAGE
	LD	DE,STPLOC		; TO IT'S LOCATION IN PAGE ZERO
	LD	BC,STPSIZ		; SIZE OF BLOCK TO COPY
	LDIR				; DO IT
;
	; RESET (DE)BLOCKING ALGORITHM
	CALL	BLKRES
;
	; DEFAULT DMA ADDRESS
	LD	BC,$80			; DEFAULT DMA ADDRESS IS $80
	CALL	SETDMA			; SET IT
;
	; ENSURE VALID DISK AND JUMP TO CCP
	LD	A,(CDISK)		; GET CURRENT USER/DISK
	AND	$0F			; ISOLATE DISK PART
	LD	C,A			; SETUP C WITH CURRENT USER/DISK, ASSUME IT IS OK
	CALL	DSK_STATUS		; CHECK DISK STATUS
	JR	Z,CURDSK		; ZERO MEANS OK
	LD	A,(DEFDRIVE)		; CURRENT DRIVE NOT READY, USE DEFAULT
	JR	GOCCP			; JUMP TO COMMAND PROCESSOR
CURDSK:
	LD	A,(CDISK)		; GET CURRENT USER/DISK
GOCCP:
	LD	C,A			; SETUP C WITH CURRENT USER/DISK, ASSUME IT IS OK
	JP	CCP_ENT			; JUMP TO COMMAND PROCESSOR
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
;
;==================================================================================================
;   CHARACTER BIOS FUNCTIONS
;==================================================================================================
;
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
CONST:
; CONSOLE STATUS, RETURN $FF IF CHARACTER READY, $00 IF NOT
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
	POP	HL		; NO COMPLETION ROUTINE, SETUP DIRECT RETURN TO CALLER
	LD	E,C		; E = CHARACTER TO SEND
;	JR	CONIO		; COMMENTED OUT, FALL THROUGH OK
;
;__________________________________________________________________________________________________			
CONIO:
;
	LD	A,(IOBYTE)	; GET IOBYTE
	AND	$03		; ISOLATE RELEVANT IOBYTE BITS FOR CONSOLE
;	OR	$00		; PUT LOGICAL DEVICE IN BITS 2-3 (CON:=$00, RDR:=$04, PUN:=$08, LST:=$0C
	JR	CIO_DISP
;
;__________________________________________________________________________________________________			
LIST:					
; LIST CHARACTER FROM REGISTER C
;
	LD	B,BF_CIOOUT	; B = FUNCTION
	POP	HL		; NO COMPLETION ROUTINE, SETUP DIRECT RETURN TO CALLER
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
	JR	CIO_DISP
;
;__________________________________________________________________________________________________			
PUNCH:
; PUNCH CHARACTER FROM REGISTER C
;
	LD	B,BF_CIOOUT	; B = FUNCTION
	POP	HL		; NO COMPLETION ROUTINE, SETUP DIRECT RETURN TO CALLER
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
	JR	CIO_DISP
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
	JR	CIO_DISP
;
;__________________________________________________________________________________________________			
CIOIN:
; COMPLETION ROUTINE FOR CHARACTER INPUT FUNCTIONS
;
	LD	A,E		; MOVE CHARACTER RETURNED TO A
	RET			; FALL THRU
;;
;;__________________________________________________________________________________________________			
;CIOOUT:
;; COMPLETION ROUTINE FOR CHARACTER OUTPUT FUNCTIONS
;;
	RET
;
;__________________________________________________________________________________________________			
CIOST:
; COMPLETION ROUTINE FOR CHARACTER STATUS FUNCTIONS (IST/OST)
;
#IF (PLATFORM == PLT_UNA)
	LD	A,E
#ENDIF
	OR	A		; SET FLAGS
	RET	Z		; NO CHARACTERS WAITING (IST) OR OUTPUT BUF FULL (OST)
	OR	$FF		; $FF SIGNALS READY TO READ (IST) OR WRITE (OST)
	RET
;
;==================================================================================================
;   CHARACTER DEVICE INTERFACE
;==================================================================================================
;
; ROUTING FOR CHARACTER DEVICE FUNCTIONS
;   A = INDEX INTO DEVICE MAP BASED ON IOBYTE BIOS REQUEST
;   B = FUNCTION REQUESTED: BF_CIO(IN/OUT/IST/OST)
;   E = CHARACTER (IF APPLICABLE TO FUNCTION)
;   HL = ADDRESS OF COMPLETION ROUTINE
;
CIO_DISP:
	PUSH	HL		; PUT COMPLETION ROUTINE ON STACK

	; LOOKUP IOBYTE MAPPED DEVICE CODE
	AND	$0F		; ISOLATE INDEX INTO DEVICE MAP

	LD	HL,DEVMAP	; HL = ADDRESS OF DEVICE MAP
	CALL	ADDHLA		; ADD OFFSET
	
	LD	A,(HL)		; LOOKUP DEVICE CODE
#IF (PLATFORM == PLT_UNA)
	LD	C,B		; MOVE FUNCTION TO C
	LD	B,A		; DEVICE GOES IN B
#ELSE
	LD	C,A		; SAVE IN C FOR BIOS USAGE
#ENDIF

	CP	CIODEV_BAT	; CHECK FOR SPECIAL DEVICE (BAT, NUL)
	JR	NC,CIO_DISP1	; HANDLE SPECIAL DEVICE
	RST	08		; RETURN VIA COMPLETION ROUTINE SET AT START
	RET

CIO_DISP1:
	; HANDLE SPECIAL DEVICES
	AND	$F0		; ISOLATE DEVICE
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
	JR	Z,READER	; -> READER
	CP	BF_CIOIST	; INPUT STATUS?
	JR	Z,READERST	; -> READER
	CP	BF_CIOOUT	; OUTPUT?
	JR	Z,LIST		; -> LIST
	CP	BF_CIOOST	; OUTPUT STATUS?
	JR	Z,LISTST	; -> LIST
	CALL	PANIC		; SOMETHING BAD HAPPENED
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
	RET			; SWALLOW CHARACTER
;
NUL_IST:
NUL_OST:
	OR	$FF		; A=$FF & NZ (READY)
	RET
;
;==================================================================================================
;   DISK BIOS FUNCTIONS
;==================================================================================================
;
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
READWRITE:
	LD	(DSKOP),A		; SET THE ACTIVE DISK OPERATION
	JR	BLKRW
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
#IF DSKTRACE
	CALL	PRTDSKOP		; *DEBUG*
#ENDIF

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
#IF DSKTRACE
	CALL	PRTDSKOP	; *DEBUG*
#ENDIF

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
#IF (PLATFORM == PLT_UNA)
	CALL	BLK_SETUP
	EX	DE,HL
	LD	BC,128
	LDIR
	RET
#ELSE
	LD	B,BF_SYSXCPY	; HBIOS FUNC: SYSTEM EXTENDED COPY
	LD	E,BID_USR	; E=SRC=USER BANK=TPA
	LD	D,BID_BIOS	; D=DEST=HBIOS
	RST	08		; SET BANKS FOR INTERBANK COPY
	CALL	BLK_SETUP	; SETUP SOURCE AND DESTINATION
	LD	B,BF_SYSCPY	; HBIOS FUNC: SYSTEM COPY
	EX	DE,HL		; SWAP HL/DE FOR BLOCK OPERATION
	PUSH	IX		; SAVE IX
	LD	IX,128		; DMA BUFFER SIZE
	RST	08		; DO IT
	POP	IX		; RESTORE IX
	RET
#ENDIF
;
;__________________________________________________________________________________________________
;
; DEBLOCK DATA - EXTRACT DESIRED CPM DMA BUF FROM PHYSICAL SECTOR BUFFER
;
BLK_DEBLOCK:
#IF (PLATFORM == PLT_UNA)
	CALL	BLK_SETUP
	LD	BC,128
	LDIR
	RET
#ELSE
	LD	B,BF_SYSXCPY	; HBIOS FUNC: SYSTEM EXTENDED COPY
	LD	E,BID_BIOS	; C=SRC=HBIOS
	LD	D,BID_USR	; B=DEST=USER BANK=TPA
	RST	08		; DO IT
	CALL	BLK_SETUP	; SETUP SOURCE AND DESTINATION
	LD	B,BF_SYSCPY	; HBIOS FUNC: SYSTEM COPY
	PUSH	IX		; SAVE IX
	LD	IX,128		; DMA BUFFER SIZE
	RST	08		; DO IT
	POP	IX		; RESTORE IX
	RET
#ENDIF
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
; PHYSICAL DISK INTERFACE
;==================================================================================================
;
; LOOKUP DISK INFORMATION BASED ON CPM DRIVE IN C
; ON RETURN, D=DEVICE/UNIT, E=SLICE, HL=DPH ADDRESS
;
DSK_GETINF:
	LD	HL,(DRVMAPADR)	; HL := START OF UNA DRIVE MAP
	DEC	HL		; POINT TO DRIVE COUNT
	LD	A,C		; A := CPM DRIVE
	CP	(HL)		; COMPARE TO NUMBER OF DRIVES CONFIGURED
	JR	NC,DSK_GETINF1	; IF OUT OF RANGE, GO TO ERROR RETURN
	INC	HL		; POINT TO START OF DRIVE MAP
;
	RLCA			; MULTIPLY A BY 4...
	RLCA			; TO USE AS OFFSET INTO ???? MAP
	CALL	ADDHLA		; ADD OFFSET
	LD	D,(HL)		; D := DEVICE/UNIT
	INC	HL		; BUMP TO SLICE
	LD	E,(HL)		; E := SLICE
	INC	HL		; POINT TO DPH LSB
	LD	A,(HL)		; A := DPH LSB
	INC	HL		; POINT TO DPH MSB
	LD	H,(HL)		; H := DPH MSB
	LD	L,A		; L := DPH LSB
	LD	A,H		; TEST FOR INVALID DPH
	OR	L		; ... BY CHECKING FOR ZERO VALUE
	JR	Z,DSK_GETINF1	; HANDLE ZERO DPH, DRIVE IS INVALID
	XOR	A		; SET SUCCESS
	RET
;
DSK_GETINF1:	; ERROR RETURN
	XOR	A
	LD	H,A
	LD	L,A
	LD	D,A
	LD	E,A
	INC	A
	RET
;
;
;
DSK_SELECT:
	LD	B,E		; SAVE E IN B FOR NOW
	CALL	DSK_GETINF	; GET D=DEVICE/UNIT, E=SLICE, HL=DPH ADDRESS
	RET	NZ		; RETURN IF INVALID DRIVE (A=1, NZ SET, HL=0)
	PUSH	BC		; WE NEED  B LATER, SAVE ON STACK
;
	; SAVE ALL THE NEW STUFF
	LD	A,C		; A := CPM DRIVE NO
	LD	(SEKDSK),A	; SAVE IT
	LD	A,D		; A := DEVICE/UNIT
	LD	(SEKDU),A	; SAVE DEVICE/UNIT
	LD	(SEKDPH),HL	; SAVE DPH POINTER
;
	; UPDATE OFFSET FOR ACTIVE SLICE
	; A TRACK IS ASSUMED TO BE 16 SECTORS
	; THE OFFSET REPRESENTS THE NUMBER OF BLOCKS * 256
	;   TO USE AS THE OFFSET
	LD	H,65		; H = TRACKS PER SLICE, E = SLICE NO
	CALL	MULT8		; HL := H * E (TOTAL TRACK OFFSET)
	LD	(SEKOFF),HL	; SAVE NEW TRACK OFFSET
;
	; RESTORE DE TO BC (FOR ACCESS TO DRIVE LOGIN BIT)
	POP	BC		; GET ORIGINAL E INTO B
;
#IF (PLATFORM != PLT_UNA)
;
	; CHECK IF THIS IS LOGIN, IF NOT, BYPASS MEDIA DETECTION
	; FIX: WHAT IF PREVIOUS MEDIA DETECTION FAILED???
	BIT	0,B		; TEST DRIVE LOGIN BIT
	JR	NZ,DSK_SELECT2	; BYPASS MEDIA DETECTION
;
	; DETERMINE MEDIA IN DRIVE
	LD	A,(SEKDU)	; GET DEVICE/UNIT
	LD	C,A		; STORE IN C
	LD	B,BF_DIOMED	; DRIVER FUNCTION = DISK MEDIA
	RST	08
	OR	A		; SET FLAGS
	LD	HL,0		; ASSUME FAILURE
	RET	Z		; BAIL OUT IF NO MEDIA
;
	; A HAS MEDIA ID, SET HL TO CORRESPONDING DPBMAP ENTRY
	LD	HL,DPBMAP	; HL = DPBMAP
	RLCA			; DPBMAP ENTRIES ARE 2 BYTES EACH
	CALL	ADDHLA		; ADD OFFSET TO HL
;
	; LOOKUP THE ACTUAL DPB ADDRESS NOW
	LD	E,(HL)		; DEREFERENCE HL...
	INC	HL		; INTO DE...
	LD	D,(HL)		; DE = ADDRESS OF DESIRED DPB
;	
	; PLUG DPB INTO THE ACTIVE DPH
	LD	HL,(SEKDPH)
	LD	BC,10		; OFFSET OF DPB IN DPH
	ADD	HL,BC		; HL := DPH.DPB
	LD	(HL),E		; SET LSB OF DPB IN DPH
	INC	HL		; BUMP TO MSB
	LD	(HL),D		; SET MSB OF DPB IN DPH
#ENDIF
;
DSK_SELECT2:
	LD	HL,(SEKDPH)	; HL = DPH ADDRESS FOR CP/M	
	XOR	A		; FLAG SUCCESS
	RET			; NORMAL RETURN
;
;
;
DSK_STATUS:
#IF (PLATFORM == PLT_UNA)
	XOR	A		; ASSUME OK FOR NOW
	RET			; RETURN
#ELSE
	; C HAS CPM DRIVE, LOOKUP DEVICE/UNIT AND CHECK FOR INVALID DRIVE
	CALL	DSK_GETINF	; B = DEVICE/UNIT
	RET	NZ		; INVALID DRIVE ERROR
	
	; VALID DRIVE, DISPATCH TO DRIVER
	LD	C,D		; C := DEVICE/UNIT
	LD	B,BF_DIOST	; B := FUNCTION: STATUS
	RST	08
	RET
#ENDIF
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
#IF (PLATFORM == PLT_UNA)

DSK_IO:
DSK_IO1:
	PUSH	BC
	LD	DE,(HSTTRK)	; GET TRACK INTO HL
	LD	B,4		; PREPARE TO LEFT SHIFT BY 4 BITS
DSK_IO2:
	SLA	E		; SHIFT DE LEFT BY 4 BITS
	RL	D
	DJNZ	DSK_IO2		; LOOP TILL ALL BITS DONE
	LD	A,(HSTSEC)	; GET THE SECTOR INTO A
	AND	$0F		; GET RID OF TOP NIBBLE
	OR	E		; COMBINE WITH E
	LD	E,A		; BACK IN E
	LD	HL,0		; HL:DE NOW HAS SLICE RELATIVE LBA
	; APPLY OFFSET NOW
	; OFFSET IS EXPRESSED AS NUMBER OF BLOCKS * 256 TO OFFSET!
	LD	A,(HSTOFF)	; LSB OF SLICE OFFSET TO A
	ADD	A,D		; ADD WITH D
	LD	D,A		; PUT IT BACK IN D
	LD	A,(HSTOFF+1)	; MSB OF SLICE OFFSET TO A
	CALL	ADDHLA		; ADD OFFSET
	POP	BC		; RECOVER FUNCTION IN B
	LD	A,(HSTDU)	; GET THE DEVICE/UNIT VALUE
	LD	C,A		; PUT IT IN C
	; DISPATCH TO DRIVER
	PUSH	BC
	EX	DE,HL		; DE:HL NOW HAS LBA
	LD	B,C		; UNIT TO B
	LD	C,$41		; UNA SET LBA
	RST	08		; CALL UNA
	CALL	NZ,PANIC
	POP	BC		; RECOVER B=FUNC, C=UNIT
	LD	E,C		; UNIT TO E
	LD	C,B		; FUNC TO C
	LD	B,E		; UNIT TO B
	LD	DE,(BUFADR)	; SET BUFFER ADDRESS
	LD	HL,1		; 1 SECTOR

	RST	08
	CALL	NZ,PANIC
	XOR	A		; SET FLAGS BASED ON RESULT
	RET

#ELSE

DSK_IO:
	LD	A,(HSTDU)	; GET ACTIVE DEVICE/UNIT BYTE
	AND	$F0		; ISOLATE DEVICE PORTION
	CP	DIODEV_FD	; FLOPPY?
	JR	NZ,DSK_IO1	; NO, USE LBA HANDLING
	; SET HL=TRACK (ADD IN TRACK OFFSET)
	LD	DE,(HSTOFF)	; DE = TRACK OFFSET FOR LU SUPPORT
	LD	HL,(HSTTRK)	; HL = TRACK #
	ADD	HL,DE		; APPLY OFFSET FOR ACTIVE SLICE
	; SET DE=SECTOR
	LD	DE,(HSTSEC)	; DE = SECTOR #
	; SET C = DEVICE/UNIT
	LD	A,(HSTDU)	; LOAD DEVICE/UNIT VALUE
	LD	C,A		; SAVE IN C
	; DISPATCH TO DRIVER
	RST	08
	OR	A		; SET FLAGS BASED ON RESULT
	RET
	; NEW LBA HANDLING
	; COERCE TRACK/SECTOR INTO HL:DE AS 0000:TTTS
DSK_IO1:
	PUSH	BC
	LD	DE,(HSTTRK)	; GET TRACK INTO HL
	LD	B,4		; PREPARE TO LEFT SHIFT BY 4 BITS
DSK_IO2:
	SLA	E		; SHIFT DE LEFT BY 4 BITS
	RL	D
	DJNZ	DSK_IO2		; LOOP TILL ALL BITS DONE
	LD	A,(HSTSEC)	; GET THE SECTOR INTO A
	AND	$0F		; GET RID OF TOP NIBBLE
	OR	E		; COMBINE WITH E
	LD	E,A		; BACK IN E
	LD	HL,0		; HL:DE NOW HAS SLICE RELATIVE LBA
	; APPLY OFFSET NOW
	; OFFSET IS EXPRESSED AS NUMBER OF BLOCKS * 256 TO OFFSET!
	LD	A,(HSTOFF)	; LSB OF SLICE OFFSET TO A
	ADD	A,D		; ADD WITH D
	LD	D,A		; PUT IT BACK IN D
	LD	A,(HSTOFF+1)	; MSB OF SLICE OFFSET TO A
	CALL	ADDHLA		; ADD OFFSET
	POP	BC		; RECOVER FUNCTION IN B
	LD	A,(HSTDU)	; GET THE DEVICE/UNIT VALUE
	LD	C,A		; PUT IT IN C
	; DISPATCH TO DRIVER
	RST	08
	OR	A		; SET FLAGS BASED ON RESULT
	RET

#ENDIF
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
;STR_READONLY	.DB 	"\r\nCBIOS Err: Read Only Drive$"
;STR_STALE	.DB 	"\r\nCBIOS Err: Stale Drive$"
;
SECADR		.DW 	0		; ADDRESS OF SECTOR IN ROM/RAM PAGE
DEFDRIVE	.DB	0		; DEFAULT DRIVE
CCPBUF		.DW	$7000		; ADDRESS OF CCP BUF IN BIOS BANK
;
; DOS DISK VARIABLES
;
DSKOP:		.DB	0		; DISK OPERATION (DOP_READ/DOP_WRITE)
WRTYPE:		.DB 	0		; WRITE TYPE (0=NORMAL, 1=DIR (FORCE), 2=FIRST RECORD OF BLOCK)
DMAADR:		.DW 	0		; DIRECT MEMORY ADDRESS
HSTWRT:		.DB	0		; TRUE = BUFFER IS DIRTY
BUFADR:		.DW	$8000-$0400	; ADDRESS OF PHYSICAL SECTOR BUFFER (DEFAULT MATCHES HBIOS)
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
; RESULT OF CPM TO PHYSICAL TRANSLATION
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
;==================================================================================================
; DISK CONTROL STRUCTURES (DPB, DPH)
;==================================================================================================
;
RAMBLKS		.EQU	(((BID_RAMDN - BID_RAMD0 + 1) * 32) / 2)
CKS_RAM		.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_RAM		.EQU	((RAMBLKS + 7) / 8)	; ALS: BLKS / 8 (ROUNDED UP)
;
ROMBLKS		.EQU	(((BID_ROMDN - BID_ROMD0 + 1) * 32) / 2)
CKS_ROM		.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_ROM		.EQU	((ROMBLKS + 7) / 8)	; ALS: BLKS / 8 (ROUNDED UP)
;
CKS_FD		.EQU	64			; CKS: DIR ENT / 4 = 256 / 4 = 64
ALS_FD		.EQU	128			; ALS: BLKS / 8 = 1024 / 8 = 128
;
CKS_HD		.EQU	0			; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_HD		.EQU	256			; ALS: BLKS / 8 = 2048 / 8 = 256 (ROUNDED UP)
;
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
; ROM DISK: 64 SECS/TRK (LOGICAL), 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; ROM DISK SIZE = TOTAL ROM - 32K RESERVED FOR SYSTEM USE
;
	.DW	CKS_ROM
	.DW	ALS_ROM
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_ROM:
	.DW  	64		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
#IF ((ROMBLKS - 1) < 256)
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
; RAM DISK: 64 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; RAM DISK SIZE = TOTAL RAM - 64K RESERVED FOR SYSTEM USE
;
	.DW	CKS_RAM
	.DW	ALS_RAM
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_RAM:
	.DW  	64		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
#IF ((RAMBLKS - 1) < 256)
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
; 4MB RAM FLOPPY DRIVE, 32 TRKS, 1024 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; SEC/TRK ENGINEERED SO THAT AFTER DEBLOCKING, SECTOR NUMBER OCCUPIES 1 BYTE (0-255)
;
	.DW	CKS_HD
	.DW	ALS_HD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_RF:
	.DW  	1024		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	2047		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = (4MB / 2K BLS) - 1 = 2047
	.DW  	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	0		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW  	0		; OFF: RESERVED TRACKS = 0 TRK
;__________________________________________________________________________________________________
;
; GENERIC HARD DISK DRIVE (8MB DATA SPACE + 128K RESERVED SPACE)
;   LOGICAL: 1040 TRKS (16 RESERVED), 64 SECS/TRK, 128 BYTES/SEC
;   PHYSICAL: 65 CYLS (1 RESERVED), 16 HEADS/CYL, 16 SECS/TRK, 512 BYTES/SEC
;   BLOCKSIZE (BLS) = 4K, DIRECTORY ENTRIES = 512
;
	.DW	CKS_HD
	.DW	ALS_HD
	.DB	(4096 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_HD:
	.DW  	64		; SPT: SECTORS PER TRACK
	.DB  	5		; BSH: BLOCK SHIFT FACTOR
	.DB  	31		; BLM: BLOCK MASK
	.DB  	1		; EXM: EXTENT MASK
	.DW  	2047		; DSM: TOTAL STORAGE IN BLOCKS - 1 = (8MB / 4K BLS) - 1 = 2047
	.DW  	511		; DRM: DIR ENTRIES - 1 = 512 - 1 = 511
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	0		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	16		; OFF: RESERVED TRACKS = 16 TRKS * (16 TRKS * 16 HEADS * 16 SECS * 512 BYTES) = 128K
;__________________________________________________________________________________________________
;
; IBM 720KB 3.5" FLOPPY DRIVE, 80 TRKS, 36 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 128
;
	.DW	CKS_FD
	.DW	ALS_FD
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
	.DW	CKS_FD
	.DW	ALS_FD
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
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD360:
	.DW  	36		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	1		; EXM: EXTENT MASK
	.DW  	170		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((360K - 18K OFF) / 2K BLS) - 1 = 170
	.DW  	127		; DRM: DIR ENTRIES - 1 = 128 - 1 = 127
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	32		; CKS: DIRECTORY CHECK VECTOR SIZE = 128 / 4
	.DW  	4		; OFF: RESERVED TRACKS = 4 TRKS * (512 B/SEC * 36 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 1.20MB 5.25" FLOPPY DRIVE, 80 TRKS, 15 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DW	CKS_FD
	.DW	ALS_FD
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
; IBM 1.11MB 8" FLOPPY DRIVE, 77 TRKS, 15 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD111:
	.DW  	60		; SPT: SECTORS PER TRACK
	.DB  	4		; BSH: BLOCK SHIFT FACTOR
	.DB  	15		; BLM: BLOCK MASK
	.DB  	0		; EXM: EXTENT MASK
	.DW  	569		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,155K - 15K OFF) / 2K BLS) - 1 = 569
	.DW  	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 60 SEC/TRK) = 15K
;
#IF (PLATFORM == PLT_UNA)
SECBUF	.FILL	512,0	; PHYSICAL DISK SECTOR BUFFER
#ENDIF
;
;==================================================================================================
; CBIOS BUFFERS
;==================================================================================================
;
;BUFFERS:
;
BUFPOOL	.EQU	$		; START OF BUFFER POOL
;
;==================================================================================================
; COLD BOOT INITIALIZATION
;
; THIS CODE IS PLACED IN THE BDOS BUFFER AREA TO CONSERVE SPACE.  SINCE
; COLD BOOT DOES NO DISK IO, SO THIS IS SAFE.
;
;==================================================================================================
;
	.FILL	16 * 4,0		; RESERVED FOR DRVMAP TABLE
	.FILL	16 * 16,0		; RESERVED FOR DPH TABLE
;
INIT:
	; THIS INIT CODE WILL BE OVERLAID, SO WE ARE GOING
	; TO MODIFY THE BOOT ENTRY POINT TO CAUSE A PANIC
	; TO EASILY IDENTIFY IF SOMETHING TRIES TO INVOKE
	; THE BOOT ENTRY POINT AFTER INIT IS DONE.
	LD	A,$CD			; "CALL" INSTRUCTION
	LD	(BOOT),A		; STORE IT BOOT ENTRY POINT
	LD	HL,PANIC		; ADDRESS OF PANIC ROUTINE
	LD	(BOOT+1),HL		; STORE IT AT BOOT ENTRY + 1
	
#IF (PLATFORM == PLT_UNA)
	; MAKE SURE UNA EXEC PAGE IS ACTIVE
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,BID_USR		; SWITCH BACK TO EXEC BANK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)

	; INSTALL UNA INVOCATION VECTOR FOR RST 08
	LD	A,$C3			; JP INSTRUCTION
	LD	(8),A			; STORE AT 0x0008
	LD	HL,($FFFE)		; UNA ENTRY VECTOR
	LD	(9),HL			; STORE AT 0x0009
#ELSE
	; MAKE SURE USER BANK IS ACTIVE
	LD	B,BF_SYSSETBNK
	LD	C,BID_USR
	CALL	$FFF0
	
	; INSTALL HBIOS INVOCATION VECTOR FOR RST 08
	LD	A,$C3			; JP INSTRUCTION
	LD	(8),A			; STORE AT 0x0008
	LD	HL,($FFF1)		; HBIOS ENTRY VECTOR
	LD	(9),HL			; STORE AT 0x0009
#ENDIF

	; PARAMETER INITIALIZATION
	LD	A,DEFIOBYTE		; LOAD DEFAULT IOBYTE
	LD	(IOBYTE),A		; STORE IT

#IF ((PLATFORM != PLT_N8) & (PLATFORM != PLT_MK4) & (PLATFORM != PLT_UNA))
	IN	A,(RTC)			; RTC PORT, BIT 6 HAS STATE OF CONFIG JUMPER
	BIT	6,A			; BIT 6 HAS CONFIG JUMPER STATE
	LD	A,DEFIOBYTE		; ASSUME WE WANT DEFAULT IOBYTE VALUE
	JR	NZ,INIT1		; IF BIT6=1, NOT SHORTED, CONTINUE WITH DEFAULT
	LD	A,ALTIOBYTE		; LOAD ALT IOBYTE VALUE
INIT1:	
	LD	(IOBYTE),A		; SET THE ACTIVE IOBYTE
#ENDIF

	; INIT DEFAULT DRIVE TO A: FOR NOW
	XOR	A			; ZERO
	LD	(DEFDRIVE),A		; STORE IT
	
	; STARTUP MESSAGE
	CALL	NEWLINE			; FORMATTING
	LD	DE,STR_CPM		; DEFAULT TO CP/M LABEL
	LD	A,(BDOS_LOC)		; GET FIRST BYTE OF BDOS
	CP	'Z'			; IS IT A 'Z' (FOR ZSDOS)?
	JR	NZ,INIT2		; NOPE, CP/M IS RIGHT
	LD	DE,STR_ZSDOS		; SWITCH TO ZSDOS LABEL
INIT2:
	CALL	WRITESTR		; DISPLAY OS LABEL
	LD	DE,STR_BANNER		; POINT TO BANNER
	CALL	WRITESTR		; DISPLAY IT
	CALL	NEWLINE			; FORMATTING

#IF (PLATFORM == PLT_UNA)
	; SAVE COMMAND PROCESSOR IMAGE TO MALLOCED CACHE IN UNA BIOS PAGE
	LD	C,$F7		; UNA MALLOC
	LD	DE,CCP_SIZ	; SIZE OF CCP
	RST	08		; DO IT
	CALL	NZ,PANIC	; BIG PROBLEM
	LD	(CCPBUF),HL	; SAVE THE ADDRESS (IN BIOS MEM)

	LD	BC,$01FB	; UNA FUNC = SET BANK
	LD	DE,BID_BIOS	; UBIOS_PAGE (SEE PAGES.INC)
	RST	08		; DO IT
	PUSH	DE		; SAVE PREVIOUS BANK

	LD	HL,CPM_LOC	; ADDRESS IN HI MEM OF CCP
	LD	DE,(CCPBUF)	; ADDRESS OF CCP BUF IN BIOS MEM
	LD	BC,CCP_SIZ	; SIZE OF CCP
	LDIR			; DO IT

	LD	BC,$01FB	; UNA FUNC = SET BANK
	POP	DE		; RECOVER OPERATING BANK
	RST	08		; DO IT
#ELSE
	; SAVE COMMAND PROCESSOR TO DEDICATED CACHE IN RAM BANK 1
	LD	B,BF_SYSXCPY	; HBIOS FUNC: SYSTEM EXTENDED COPY
	LD	E,BID_USR	; E = SRC BANK = USR BANK = TPA
	LD	D,BID_BIOS	; D = DEST BANK = HB BANK
	RST	08		; DO IT
	LD	B,BF_SYSCPY	; HBIOS FUNC: SYSTEM COPY
	LD	HL,CPM_LOC	; COPY FROM CCP LOCATION IN USR BANK
	LD	DE,(CCPBUF)	; TO FIXED LOCATION IN HB BANK
	LD	IX,CCP_SIZ	; COPY CONTENTS OF COMMAND PROCESSOR
	RST	08		; DO IT
#ENDIF

	; DISK SYSTEM INITIALIZATION
	CALL	BLKRES		; RESET DISK (DE)BLOCKING ALGORITHM
	CALL	MD_INIT		; INITIALIZE MEMORY DISK DRIVER (RAM/ROM)
	CALL	DRV_INIT	; INITIALIZE DRIVE MAP
	CALL	DPH_INIT	; INITIALIZE DPH TABLE AND BUFFERS
	CALL	NEWLINE		; FORMATTING
;
	; DISPLAY FREE MEMORY
	LD	DE,STR_LDR	; FORMATTING
	CALL	WRITESTR	; AND PRINT IT
	LD	HL,CBIOS_END	; SUBTRACT HIGH WATER
	LD	DE,(BUFTOP)	; ... FROM TOP OF CBIOS
	OR	A		; ... WITH CF CLEAR
	SBC	HL,DE		; ... SO HL GETS BYTES FREE
	CALL	PRTDEC		; PRINT IT
	LD	DE,STR_MEMFREE	; ADD DESCRIPTION
	CALL	WRITESTR	; AND PRINT IT
;
	LD	A,(DEFDRIVE)	; GET DEFAULT DRIVE
	LD	(CDISK),A	; ... AND SETUP CDISK
;
	; SETUP AUTOSTART COMMAND
	LD	HL,CMD		; ADDRESS OF STARTUP COMMAND
	LD	DE,CCP_LOC + 7	; START OF COMMAND BUFFER IN CCP
	LD	BC,CMDLEN	; LENGTH OF AUTOSTART COMMAND
	LDIR			; INSTALL IT
;
	RET
;
CMD	.DB	CMDLEN - 1
#IFDEF AUTOCMD
	.TEXT	AUTOCMD
#ENDIF
	.DB	0
CMDLEN	.EQU	$ - CMD
;
STR_CPM		.DB	"CP/M-80 2.2$"
STR_ZSDOS	.DB	"ZSDOS 1.1$"
STR_BANNER	.DB	" for ", PLATFORM_NAME, ", CBIOS v", BIOSVER, "$"
STR_MEMFREE	.DB	" Disk Buffer Bytes Free\r\n$"
;
;
;__________________________________________________________________________________________________
MD_INIT:
;
#IF (PLATFORM == PLT_UNA)
;
; INITIALIZE RAM DISK BY FILLING DIRECTORY WITH 'E5' BYTES
; FILL FIRST 8K OF RAM DISK TRACK 1 WITH 'E5'
;
#IF (CLRRAMDISK != CLR_NEVER)
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,BID_RAMD0		; FIRST BANK OF RAM DISK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)

#IF (CLRRAMDISK == CLR_AUTO)
	; CHECK FIRST 32 DIRECTORY ENTRIES.  IF ANY START WITH AN INVALID
	; VALUE, INIT THE RAM DISK.  VALID ENTRIES ARE E5 (EMPTY ENTRY) OR
	; 0-15 (USER NUMBER).
	LD	HL,0
	LD	DE,32
	LD	B,32
CLRRAM0:
	LD	A,(HL)
	CP	$E5
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
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,BID_USR		; SWITCH BACK TO EXEC BANK FOR WRITESTR
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)

	LD	DE,STR_INITRAMDISK	; RAM DISK INIT MESSAGE
	CALL	WRITESTR		; DISPLAY IT

	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,BID_RAMD0		; FIRST BANK OF RAM DISK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)

	LD	HL,0			; SOURCE ADR FOR FILL
	LD	BC,$2000		; LENGTH OF FILL IS 8K
	LD	A,$E5			; FILL VALUE
	CALL	FILL			; DO IT
CLRRAM3:
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,BID_USR		; SWITCH BACK TO EXEC BANK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)

#ENDIF

#ELSE
;
; INITIALIZE RAM DISK BY FILLING DIRECTORY WITH 'E5' BYTES
; FILL FIRST 8K OF RAM DISK TRACK 1 WITH 'E5'
;
#IF (CLRRAMDISK != CLR_NEVER)
	LD	B,BF_SYSSETBNK		; HBIOS FUNC: SET BANK
	LD	C,BID_RAMD0		; FIRST BANK OF RAM DISK
	CALL	$FFF0			; DO IT (RST 08 NOT SAFE)

#IF (CLRRAMDISK == CLR_AUTO)
	; CHECK FIRST 32 DIRECTORY ENTRIES.  IF ANY START WITH AN INVALID
	; VALUE, INIT THE RAM DISK.  VALID ENTRIES ARE E5 (EMPTY ENTRY) OR
	; 0-15 (USER NUMBER).
	LD	HL,0
	LD	DE,32
	LD	B,32
CLRRAM0:
	LD	A,(HL)
	CP	$E5
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
	LD	B,BF_SYSSETBNK		; HBIOS FUNC: SET BANK
	LD	C,BID_USR		; SWITCH BACK TO USR BANK
	CALL	$FFF0			; DO IT (RST 08 NOT SAFE)
	LD	DE,STR_INITRAMDISK	; RAM DISK INIT MESSAGE
	CALL	WRITESTR		; DISPLAY IT
	LD	B,BF_SYSSETBNK		; HBIOS FUNC: SET BANK
	LD	C,BID_RAMD0		; SWITCH BACK TO FIRST BANK
	CALL	$FFF0			; DO IT (RST 08 NOT SAFE)
	LD	HL,0			; SOURCE ADR FOR FILL
	LD	BC,$2000		; LENGTH OF FILL IS 8K
	LD	A,$E5			; FILL VALUE
	CALL	FILL			; DO IT
CLRRAM3:
	LD	B,BF_SYSSETBNK		; HBIOS FUNC: SET BANK
	LD	C,BID_USR		; USR BANK (TPA)
	CALL	$FFF0			; DO IT (RST 08 NOT SAFE)
#ENDIF
;
#ENDIF
;
	RET
;
;
;__________________________________________________________________________________________________
#IF (PLATFORM == PLT_UNA)
;
DRV_INIT:
;
; PERFORM UBIOS SPECIFIC INITIALIZATION
; BUILD DRVMAP BASED ON AVAILABLE UBIOS DISK DEVICE LIST
;
	; GET BOOT DEVICE/UNIT/LU INFO
	LD	BC,$00FC		; UNA FUNC: GET BOOTSTRAP HISTORY
	RST	08			; CALL UNA
	LD	D,L			; SAVE L AS DEVICE/UNIT
	LD	E,0			; LU IS ZERO
	LD	(BOOTVOL),DE		; D -> DEVICE/UNIT, E -> LU
;
; PERFORM UNA BIOS SPECIFIC INITIALIZATION
; UPDATE DRVMAP BASED ON AVAILABLE UNA UNITS
;
	; SETUP THE DRVMAP STRUCTURE
	LD	HL,(BUFTOP)		; GET CURRENT BUFFER TOP
	INC	HL			; SKIP 1 BYTE FOR ENTRY COUNT PREFIX
	LD	(DRVMAPADR),HL		; SAVE AS DRIVE MAP ADDRESS
	LD	(BUFTOP),HL		; ... AND AS NEW BUFTOP
;
	LD	B,0			; START WITH UNIT 0
;
DRV_INIT1:	; LOOP THRU ALL UNITS AVAILABLE
	LD	C,$48			; UNA FUNC: GET DISK TYPE
	LD	L,0			; PRESET UNIT COUNT TO ZERO
	CALL	$FFFD			; CALL UNA, B IS ASSUMED TO BE UNTOUCHED!!!
	LD	A,L			; UNIT COUNT TO A
	OR	A			; PAST END?
	JR	Z,DRV_INIT2		; WE ARE DONE
	PUSH	BC			; SAVE UNIT
	CALL	DRV_INIT3		; PROCESS THE UNIT
	POP	BC			; RESTORE UNIT
	INC	B			; NEXT UNIT
	JR	DRV_INIT1		; LOOP
;
DRV_INIT2:	; FINALIZE THE DRIVE MAP
	RET				; DONE
;
DRV_INIT3:	; PROCESS CURRENT UNIT (SEE UNA PROTOIDS.INC)
	LD	A,D			; MOVE DISK TYPE TO A
;	CALL	PC_LBKT			; *DEBUG*
;	CALL	PRTHEXBYTE		; *DEBUG*
;	CALL	PC_RBKT			; *DEBUG*
;
	CALL	DRV_INIT4		; MAKE A DRIVE MAP ENTRY
	LD	A,D			; LOAD DRIVE TYPE
	CP	$40			; RAM/ROM?
	RET	Z			; DONE IF SO
;	CP	$??			; FLOPPY DRIVE?
;	RET	Z			; DONE IF SO
	CALL	DRV_INIT4		; ANOTHER ENTRY FOR HARD DISK
	LD	A,1			; BUT WITH SLICE VALUE OF 1
	INC	HL			; BUMP TO SLICE POSITION
	LD	(HL),A			; SAVE IT
	RET				; DONE
;
DRV_INIT4:
	; ALLOCATE SPACE IN DRVMAP
	PUSH	BC			; SAVE INCOMING UNIT NUM
	LD	BC,4			; 4 BYTES PER ENTRY
	CALL	ALLOC			; ALLOCATE
	CALL	NZ,PANIC		; SHOULD NEVER ERROR HERE
	PUSH	BC			; MOVE MEM PTR
	POP	HL			; ... TO HL
	POP	BC			; RECOVER UNIT NUM
	LD	(HL),B			; SAVE IT IN FIRST BYTE OF DRV MAP ENTRY
	PUSH	HL			; SAVE HL
	LD	HL,(DRVMAPADR)		; POINT TO DRIVE MAP
	DEC	HL			; BACK TO ENTRY COUNT
	INC	(HL)			; INCREMENT THE ENTRY COUNT
	POP	HL			; RECOVER HL
	RET				; DONE
;
#ELSE
;
DRV_INIT:
;
; PERFORM HBIOS SPECIFIC INITIALIZATION
; BUILD DRVMAP BASED ON AVAILABLE HBIOS DISK DEVICE LIST
;
	; GET BOOT DEVICE/UNIT/LU INFO
	LD	B,BF_SYSATTR		; HBIOS FUNC: GET/SET ATTR
	LD	C,AID_BOOTVOL		; ATTRIB ID FOR BOOT DEVICE
	RST	08			; GET THE VALUE
	LD	(BOOTVOL),DE		; D -> DEVICE/UNIT, E -> LU
;
	; SETUP THE DRVMAP STRUCTURE
	LD	HL,(BUFTOP)		; GET CURRENT BUFFER TOP
	INC	HL			; SKIP 1 BYTE FOR ENTRY COUNT PREFIX
	LD	(DRVMAPADR),HL		; SAVE AS DRVMAP ADDRESS
	LD	(BUFTOP),HL		; AND AS NEW BUFTOP
;
	; SETUP TO LOOP THROUGH AVAILABLE DEVICES
	LD	B,BF_DIODEVCNT		; HBIOS FUNC: DEVICE COUNT
	RST	08			; CALL HBIOS, DEVICE COUNT TO B
	LD	A,B			; COUNT TO A
	OR	A			; SET FLAGS
	RET	Z			; HANDLE ZERO DEVICES (ALBEIT POORLY)
	LD	C,0			; USE C AS DEVICE LIST INDEX
;
DRV_INIT1:	; DEVICE ENUMERATION LOOP
	PUSH	BC			; PRESERVE LOOP CONTROL
	LD	B,BF_DIODEVINF		; HBIOS FUNC: DEVICE INFO
	RST	08			; CALL HBIOS, DEVICE/UNIT TO C
	CALL	DRV_INIT3		; MAKE DRIVE MAP ENTRY(S)
	POP	BC			; RESTORE LOOP CONTROL
	INC	C			; INCREMENT LIST INDEX
	DJNZ	DRV_INIT1		; LOOP AS NEEDED
	RET				; FINISHED
;
DRV_INIT3:	; PROCESS DEVICE/UNIT
	LD	A,C			; DEVICE/UNIT TO A
	PUSH	AF			; SAVE DEVICE/UNIT
	CALL	DRV_INIT4		; MAKE A DRIVE MAP ENTRY
	POP	AF			; RESTORE DEVICE/UNIT
	CP	DIODEV_IDE		; FIRST SLICE CAPABLE DEVICE?
	RET	C			; DONE IF NOT SLICE WORTHY
	CALL	DRV_INIT4		; MAKE ANOTHER ENTRY IF HARD DISK
	LD	A,1			; ... BUT WITH SLICE = 1
	INC	HL			; BUMP TO SLICE POSITION
	LD	(HL),A			; SAVE IT
	RET				; DONE
;
DRV_INIT4:	; MAKE A DRIVE MAP ENTRY
	; ALLOCATE SPACE FOR ENTRY
	PUSH	AF			; SAVE INCOMING DEVICE/UNIT
	LD	BC,4			; 4 BYTES PER ENTRY
	CALL	ALLOC			; ALLOCATE SPACE
	CALL	NZ,PANIC		; SHOULD NEVER ERROR HERE
	PUSH	BC			; MOVE MEM PTR
	POP	HL			; ... TO HL
	POP	AF			; RECOVER DEVICE/UNIT
	LD	(HL),A			; SAVE IT IN FIRST BYTE OF DRVMAP
	PUSH	HL			; SAVE ENTRY PTR
	LD	HL,(DRVMAPADR)		; POINT TO DRIVE MAP
	DEC	HL			; BACKUP TO ENTRY COUNT
	INC	(HL)			; INCREMENT THE ENTRY COUNT
	POP	HL			; RECOVER ENTRY POINTER
	RET				; DONE
;
#ENDIF
;
;
;__________________________________________________________________________________________________
;
DPH_INIT:
;
; ITERATE THROUGH DRIVE MAP TO BUILD DPH ENTRIES DYNAMICALLY
;
	LD	DE,STR_DPHINIT	; POINT TO MSG
	CALL	WRITESTR	; DISPLAY IT
	CALL	NEWLINE		; FORMATTING
;
	; ALLOCATE DPH POOL SPACE BASED ON DRIVE COUNT
	LD	HL,(DRVMAPADR)	; LOAD DRIVE MAP POINTER
	DEC	HL		; BACKUP TO ENTRY COUNT
	LD	A,(HL)		; GET THE ENTRY COUNT
	LD	L,A		; PUT DRIVE COUNT
	LD	H,0		; ... INTO HL
	ADD	HL,HL		; MULTIPLY
	ADD	HL,HL		; ... BY SIZE
	ADD	HL,HL		; ... OF DPH (16)
	ADD	HL,HL		; ... FOR TOTAL SIZE
	PUSH	HL		; MOVE POOL SIZE
	POP	BC		; ... INTO BC FOR MEM ALLOC
	CALL	ALLOC		; ALLOCATE THE SPACE
	CALL	NZ,PANIC	; SHOULD NEVER ERROR
;
	; SET DPHTOP TO START OF ALLOCATED SPACE
	PUSH	BC		; MOVE MEM POINTER
	POP	HL		; ... TO HL
	LD	(DPHTOP),HL	; ... AND SAVE IN DPHTOP
;
	; ALLOCATE DIRECTORY BUFFER
	LD	BC,128		; SIZE OF DIRECTORY BUFFER
	CALL	ALLOC		; ALLOCATE THE SPACE
	CALL	NZ,PANIC	; SHOULD NEVER ERROR
	PUSH	BC		; MOVE MEM POINTER
	POP	HL		; ... TO HL
	LD	(DIRBUF),HL	; ... AND SAVE IN DIRBUF
;
	; SETUP FOR DPH BUILD LOOP
	LD	HL,(DRVMAPADR)	; POINT TO DRIVE MAP
	DEC	HL		; BACKUP TO ENTRY COUNT
	LD	B,(HL)		; LOOP DRVCNT TIMES
	LD	C,0		; DRIVE INDEX
	INC	HL		; BUMP TO START OF DRIVE MAP
;
DPH_INIT1:
	; DISPLAY DRIVE LETTER
	LD	A,C		; LOAD DRIVE INDEX
	ADD	A,'A'		; MAKE IT A DISPLAY LETTER
	LD	DE,STR_LDR	; LEADER STRING
	CALL	WRITESTR	; DISPLAY IT
	CALL	COUT		; DISPLAY DRIVE LETTER
	CALL	PC_COLON	; DISPLAY COLON
	LD	A,'='		; SEPARATOR
	CALL	COUT		; DISPLAY IT
	; SETUP FOR DPH BUILD ROUTINE INCLUDING DPH BLOCK ALLOCATION
	LD	D,(HL)		; D := DEV/UNIT
	INC	HL		; BUMP
	LD	E,(HL)		; E := SLICE
	INC	HL		; BUMP
	CALL	PRTDUS		; PRINT DEVICE/UNIT/SLICE
	LD	A,D		; A := DEV/UNIT
	PUSH	HL		; SAVE DRIVE MAP POINTER
	PUSH	AF		; SAVE DEV/UNIT
	; MATCH AND SAVE DEFAULT DRIVE BASED ON BOOT DEVICE/UNIT/SLICE
	LD	HL,BOOTVOL + 1	; POINT TO BOOT DEVICE/UNIT
	LD	A,D		; LOAD CURRENT DEVICE/UNIT
	CP	(HL)		; MATCH?
	JR	NZ,DPH_INIT1A	; BYPASS IF NOT BOOT DEVICE/UNIT
	DEC	HL		; POINT TO BOOT SLICE
	LD	A,E		; LOAD CURRENT SLICE
	CP	(HL)		; MATCH?
	JR	NZ,DPH_INIT1A	; BYPASS IF NOT BOOT SLICE
	LD	A,C		; LOAD THE CURRENT DRIVE NUM
	LD	(DEFDRIVE),A	; SAVE AS DEFAULT
DPH_INIT1A:	
	POP	AF		; RESTORE DEV/UNIT
	LD	DE,(DPHTOP)	; GET ADDRESS OF NEXT DPH
	PUSH	DE		; ... AND SAVE IT
	; INVOKE THE DPH BUILD ROUTINE
	PUSH	BC		; SAVE LOOP CONTROL
	CALL	MAKDPH		; MAKE THE DPH AT DE, DEV/UNIT IN A
	;CALL	NZ,PANIC	; FOR NOW, PANIC ON ANY ERROR
	POP	BC		; RESTORE LOOP CONTROL
	; STORE THE DPH POINTER IN DRIVE MAP
	POP	DE		; RESTORE DPH ADDRESS TO DE
	POP	HL		; RESTORE DRIVE MAP POINTER TO HL
	JR	Z,DPH_INIT2	; IF MAKDPH OK, CONTINUE
	LD	DE,0		; ... OTHERWISE ZERO OUT THE DPH POINTER
DPH_INIT2:
	LD	(HL),E		; SAVE DPH POINTER
	INC	HL		; ... IN
	LD	(HL),D		; ... DRIVE MAP
	INC	HL		; AND BUMP TO START OF NEXT ENTRY
	; UPDATE DPH ALLOCATION TOP
	LD	A,16		; SIZE OF A DPH ENTRY
	EX	DE,HL		; HL := DPH POINTER
	CALL	ADDHLA		; CALC NEW DPHTOP
	LD	(DPHTOP),HL	; SAVE IT
	; HANDLE THE NEXT DRIVE MAP ENTRY
	EX	DE,HL		; HL := NEXT DRIVE MAP ENTRY
	INC	C		; NEXT DRIVE
	DJNZ	DPH_INIT1	; LOOP AS NEEDED
	RET			; DONE
;
MAKDPH:
;
; MAKE A DPH AT ADDRESS IN DE FOR DEV/UNIT IN A
;
	PUSH	DE		; SAVE INCOMING DPH ADDRESS
;
#IF (PLATFORM == PLT_UNA)
;
	LD	B,A		; UNIT NUM TO B
	LD	C,$48		; UNA FUNC: GET DISK TYPE
	CALL	$FFFD		; CALL UNA
	LD	A,D		; MOVE DISK TYPE TO A
;
	; DERIVE DPB ADDRESS BASED ON DISK TYPE
	CP	$40		; RAM/ROM DRIVE?
	JR	Z,MAKDPH0	; HANDLE RAM/ROM DRIVE IF SO
;	CP	$??		; FLOPPY DRIVE?
;	JR	Z,XXXXX		; HANDLE FLOPPY
	LD	DE,DPB_HD	; ASSUME HARD DISK
	JR	MAKDPH1		; CONTINUE
;
MAKDPH0:	; HANDLE RAM/ROM
	LD	C,$45		; UNA FUNC: GET DISK INFO
	LD	DE,$9000	; 512 BYTE BUFFER *** FIX!!! ***
	CALL	$FFFD		; CALL UNA
	BIT	7,B		; TEST RAM DRIVE BIT
	LD	DE,DPB_ROM	; ASSUME ROM
	JR	Z,MAKDPH1	; NOT SET, ROM DRIVE, CONTINUE
	LD	DE,DPB_RAM	; OTHERWISE, MUST BE RAM DRIVE
	JR	MAKDPH1		; CONTINUE
;
#ELSE
;
	; DETERMINE APPROPRIATE DPB
	LD	DE,DPB_ROM	; ASSUME ROM
	CP	DIODEV_MD+0	; ROM?
	JR	Z,MAKDPH1	; YES, JUMP AHEAD
	LD	DE,DPB_RAM	; ASSUME ROM
	CP	DIODEV_MD+1	; ROM?
	JR	Z,MAKDPH1	; YES, JUMP AHEAD
	AND	$F0		; IGNORE UNIT NIBBLE NOW
	LD	DE,DPB_FD144	; ASSUME FLOPPY
	CP	DIODEV_FD	; FLOPPY?
	JR	Z,MAKDPH1	; YES, JUMP AHEAD
	LD	DE,DPB_RF	; ASSUME RAM FLOPPY
	CP	DIODEV_RF	; RAM FLOPPY?
	JR	Z,MAKDPH1	; YES, JUMP AHEAD
	LD	DE,DPB_HD	; EVERYTHING ELSE IS ASSUMED TO BE HARD DISK
	JR	MAKDPH1		; JUMP AHEAD
;
#ENDIF
;
MAKDPH1:
;
	; BUILD THE DPH
	POP	HL		; HL := START OF DPH
	LD	A,8		; SIZE OF DPH RESERVED AREA
	CALL	ADDHLA		; LEAVE IT ALONE (ZERO FILLED)
	
	LD	BC,(DIRBUF)	; ADDRESS OF DIRBUF
	LD	(HL),C		; PLUG DIRBUF
	INC	HL		; ... INTO DPH
	LD	(HL),B		; ... AND BUMP
	INC	HL		; ... TO NEXT DPH ENTRY

	LD	(HL),E		; PLUG DPB ADDRESS
	INC	HL		; ... INTO DPH
	LD	(HL),D		; ... AND BUMP
	INC	HL		; ... TO NEXT ENTRY
	DEC	DE		; POINT
	DEC	DE		; ... TO START
	DEC	DE		; ... OF
	DEC	DE		; ... DPB
	DEC	DE		; ... PREFIX DATA (CKS & ALS BUF SIZES)
	CALL	MAKDPH2		; HANDLE CKS BUF, THEN FALL THRU FOR ALS BUF
	RET	NZ		; BAIL OUT ON ERROR
MAKDPH2:
	EX	DE,HL		; POINT HL TO CKS/ALS SIZE ADR
	LD	C,(HL)		; BC := CKS/ALS SIZE
	INC	HL		; ... AND BUMP
	LD	B,(HL)		; ... PAST
	INC	HL		; ... CKS/ALS SIZE
	EX	DE,HL		; BC AND HL ROLES RESTORED
	LD	A,B		; CHECK TO SEE
	OR	C		; ... IF BC IS ZERO
	JR	Z,MAKDPH3	; IF ZERO, BYPASS ALLOC, USE ZERO FOR ADDRESS
	CALL	ALLOC		; ALLOC BC BYTES, ADDRESS RETURNED IN BC
	JR	NZ,ERR_BUFOVF	; HANDLE OVERFLOW ERROR
MAKDPH3:
	LD	(HL),C		; SAVE CKS/ALS BUF
	INC	HL		; ... ADDRESS IN
	LD	(HL),B		; ... DPH AND BUMP
	INC	HL		; ... TO NEXT DPH ENTRY	
	XOR	A		; SIGNAL SUCCESS
	RET
;
ALLOC:
;
; ALLOCATE BC BYTES FROM BUF POOL, RETURN STARTING
; ADDRESS IN BC.  LEAVE ALL OTHER REGS ALONE EXCEPT A
; Z FOR SUCCESS, NZ FOR FAILURE
;
	PUSH	DE		; SAVE ORIGINAL DE
	PUSH	HL		; SAVE ORIGINAL HL
	LD	HL,(BUFTOP)	; HL := CURRENT BUFFER TOP
	PUSH	HL		; SAVE AS START OF NEW BUFFER
	PUSH	BC		; GET BYTE COUNT
	POP	DE		; ... INTO DE
	ADD	HL,DE		; ADD IT TO BUFFER TOP
	LD	A,$FF		; ASSUME OVERFLOW FAILURE
	JR	C,ALLOC1	; IF OVERFLOW, BYPASS WITH A == $FF
	PUSH	HL		; SAVE IT
	LD	DE,$10000 - CBIOS_END	; SETUP DE FOR OVERFLOW TEST
	ADD	HL,DE		; CHECK FOR OVERFLOW
	POP	HL		; RECOVER HL
	LD	A,$FF		; ASSUME FAILURE
	JR	C,ALLOC1	; IF OVERFLOW, CONTINUE WITH A == $FF
	LD	(BUFTOP),HL	; SAVE NEW TOP
	INC	A		; SIGNAL SUCCESS
;
ALLOC1:
	POP	BC		; BUF START ADDRESS TO BC
	POP	HL		; RESTORE ORIGINAL HL
	POP	DE		; RESTORE ORIGINAL DE
	OR	A		; SIGNAL SUCCESS
	RET
;
ERR_BUFOVF:
	LD	DE,STR_BUFOVF
	JR	ERR
;
ERR_INVMED:
	LD	DE,STR_INVMED
	JR	ERR
;
ERR:
	CALL	WRITESTR
	OR	$FF
	RET
;
PRTDUS:
;
; PRINT THE DEVICE/UNIT/SLICE INFO
; ON INPUT D HAS DEVICE/UNIT, E HAS SLICE
; DESTROY NO REGISTERS OTHER THAN A
;
#IF (PLATFORM == PLT_UNA)
;
	PUSH	BC		; PRESERVE BC
	PUSH	DE		; PRESERVE DE
	PUSH	HL		; PRESERVE HL
	
	LD	B,D		; B := UNIT
	LD	C,$48		; UNA FUNC: GET DISK TYPE
	CALL	$FFFD		; CALL UNA
	LD	A,D		; DISK TYPE TO A
	
	CP	$40
	JR	Z,PRTDUS1	; IF SO, HANDLE RAM/ROM
	
	LD	DE,DEVIDE	; IDE STRING
	CP	$41		; IDE?
	JR	Z,PRTDUSX	; IF YES, PRINT
	LD	DE,DEVPPIDE	; PPIDE STRING
	CP	$42		; PPIDE?
	JR	Z,PRTDUSX	; IF YES, PRINT
	LD	DE,DEVSD	; SD STRING
	CP	$43		; SD?
	JR	Z,PRTDUSX	; IF YES, PRINT
	LD	DE,DEVDSD	; DSD STRING
	CP	$44		; DSD?
	JR	Z,PRTDUSX	; IF YES, PRINT

	LD	DE,DEVUNK	; OTHERWISE, UNKNOWN
	JR	PRTDUSX		; PRINT IT

PRTDUS1:
	LD	C,$45		; UNA FUNC: GET DISK INFO
	LD	DE,$9000	; 512 BYTE BUFFER *** FIX!!! ***
	CALL	$FFFD		; CALL UNA
	BIT	7,B		; TEST RAM DRIVE BIT
	LD	DE,DEVROM	; ASSUME ROM
	JR	Z,PRTDUSX	; IF SO, DISPLAY ROM
	LD	DE,DEVRAM	; ELSE RAM
	JR	Z,PRTDUSX	; DO IT

PRTDUSX:
	CALL	WRITESTR	; PRINT DEVICE NAME
	POP	HL		; RECOVER HL
	POP	DE		; RECOVER DE
	POP	BC		; RECOVER BC
	LD	A,D		; LOAD DEVICE/UNIT
	CALL	PRTDECB		; PRINT IT
	CALL	PC_COLON	; FORMATTING
	LD	A,E		; LOAD SLICE
	CALL	PRTDECB		; PRINT IT
	RET
;
DEVRAM		.DB	"RAM$"
DEVROM		.DB	"ROM$"
DEVIDE		.DB	"IDE$"
DEVPPIDE	.DB	"PPIDE$"
DEVSD		.DB	"SD$"
DEVDSD		.DB	"DSD$"
DEVUNK		.DB	"UNK$"
;
#ELSE
;
	PUSH	DE		; PRESERVE DE
	PUSH	HL		; PRESERVE HL
	LD	A,D		; LOAD DEVICE/UNIT
	RRCA			; ROTATE DEVICE
	RRCA			; ... BITS
	RRCA			; ... INTO
	RRCA			; ... LOWEST 4 BITS
	AND	$0F		; ISOLATE DEVICE BITS
	ADD	A,A		; MULTIPLE BY TWO FOR WORD TABLE
	LD	HL,DEVTBL	; POINT TO START OF DEVICE NAME TABLE
	CALL	ADDHLA		; ADD A TO HL TO POINT TO TABLE ENTRY
	LD	A,(HL)		; DEREFERENCE HL TO LOC OF DEVICE NAME STRING
	INC	HL		; ...
	LD	D,(HL)		; ...
	LD	E,A		; ...
	CALL	WRITESTR	; PRINT THE DEVICE NMEMONIC
	POP	HL		; RECOVER HL
	POP	DE		; RECOVER DE
	LD	A,D		; LOAD DEVICE/UNIT
	AND	$0F		; ISOLATE UNIT
	CALL	PRTDECB		; PRINT IT
	CALL	PC_COLON	; FORMATTING
	LD	A,E		; LOAD SLICE
	CALL	PRTDECB		; PRINT IT
	RET
;
DEVTBL:	; DEVICE TABLE
	.DW	DEV00, DEV01, DEV02, DEV03
	.DW	DEV04, DEV05, DEV06, DEV07
	.DW	DEV08, DEV09, DEV10, DEV11
	.DW	DEV12, DEV13, DEV14, DEV15
;
DEVUNK	.DB	"???$"
DEV00	.DB	"MD$"
DEV01	.DB	"FD$"
DEV02	.DB	"RAMF$"
DEV03	.DB	"IDE$"
DEV04	.DB	"ATAPI$"
DEV05	.DB	"PPIDE$"
DEV06	.DB	"SD$"
DEV07	.DB	"PRPSD$"
DEV08	.DB	"PPPSD$"
DEV09	.DB	"HDSK$"
DEV10	.EQU	DEVUNK
DEV11	.EQU	DEVUNK
DEV12	.EQU	DEVUNK
DEV13	.EQU	DEVUNK
DEV14	.EQU	DEVUNK
DEV15	.EQU	DEVUNK
;
#ENDIF
;
DPHTOP		.DW	0		; CURRENT TOP OF DPH POOL
DIRBUF		.DW	0		; DIR BUF POINTER
BUFTOP		.DW	BUFPOOL		; CURRENT TOP OF BUF POOL
BOOTVOL		.DW			; BOOT VOLUME, MSB=BOOT DEVICE/UNIT, LSB=BOOT LU
;
STR_INITRAMDISK	.DB	"\r\nFormatting RAMDISK...$"
STR_LDR		.DB	"\r\n   $"
STR_DPHINIT	.DB	"\r\n\r\nConfiguring Drives...$"
STR_BUFOVF	.DB	" *** Insufficient Memory ***$"
STR_INVMED	.DB	" *** Invalid Device ID ***$"
;
;==================================================================================================
;
;==================================================================================================
;
	.FILL	CBIOS_END - $,$00
;
SLACK	.EQU	(CBIOS_END - BUFPOOL)
	.ECHO	"CBIOS buffer space: "
	.ECHO	SLACK
	.ECHO	" bytes.\n"
;
	.ECHO	"CBIOS total space used: "
	.ECHO	$ - CBIOS_LOC
	.ECHO	" bytes.\n"
;
	; PAD OUT AREA RESERVED FOR HBIOS PROXY
	.FILL	$10000 - $
;
	.END
