;__________________________________________________________________________________________________
;
;	CBIOS FOR SBC
;
;	BY ANDREW LYNCH, WITH INPUT FROM MANY SOURCES
;	ROMWBW ADAPTATION BY WAYNE WARTHEN
;__________________________________________________________________________________________________
;
; TODO:
;  1) STACK LOCATION DURING BOOT OR WBOOT???
;  2) REVIEW USE OF DI/EI IN INIT
;
FALSE		.EQU	0
TRUE		.EQU	~FALSE
;
BDOS		.EQU	5		; BDOS FUNC INVOCATION VECTOR
;
; DEFINE PLATFORM STRING
;
#IFDEF PLTWBW
#DEFINE		PLTSTR	"WBW"
#ENDIF
#IFDEF PLTUNA
#DEFINE		PLTSTR	"UNA"
#ENDIF
;
; RAM DISK INITIALIZATION OPTIONS
;
CLR_NEVER	.EQU	0		; NEVER CLEAR RAM DISK
CLR_AUTO	.EQU	1		; CLEAR RAM DISK IF INVALID DIR ENTRIES
CLR_ALWAYS	.EQU	2		; ALWAYS CLEAR RAM DISK
;
; DISK OPERATION CONSTANTS
;
DOP_READ	.EQU	0		; READ OPERATION
DOP_WRITE	.EQU	1		; WRITE OPERATION
;
; DEFAULT IOBYTE VALUE:
;   CON:=TTY:	------00
;   RDR:=PTR:	----01--
;   PUN:=PTP:	--01----
;   LST:=LPT:	10------
;		========
;		10010100
;
DEF_IOBYTE	.EQU	%10010100	; DEFAULT IOBYTE VALUE
;
; SPECIAL CHARACTER DEVICES IMPLEMENTED INTERNALLY
;
DEV_BAT		.EQU	$FE		; BAT:
DEV_NUL		.EQU	$FF		; NUL:
;
#INCLUDE "../ver.inc"
;
#INCLUDE "config.asm"
;
; MEMORY LAYOUT
;
IOBYTE		.EQU	3		; LOC IN PAGE 0 OF I/O DEFINITION BYTE
CDISK		.EQU	4		; LOC IN PAGE 0 OF CURRENT DISK NUMBER 0=A,...,15=P
;
CCP_LOC		.EQU	CPM_LOC
CCP_SIZ		.EQU	$800
;
BDOS_LOC	.EQU	CCP_LOC + CCP_SIZ
BDOS_SIZ	.EQU	$E00
;
CBIOS_LOC	.EQU	BDOS_LOC + BDOS_SIZ
CBIOS_END	.EQU	CPM_END
;
MEMTOP		.EQU	$10000
;
#IFDEF PLTWBW
#INCLUDE "../HBIOS/hbios.inc"
#ENDIF
;
#IFDEF PLTUNA
#INCLUDE "../UBIOS/ubios.inc"
#ENDIF
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
; as a scratch area for CBIOS.	This data below is copied there at
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
; RomWBW CBIOS.	 A pointer to the start of this section is stored with
; with the CBX data in page zero at $44 (see above).
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
; TIMDAT ROUTINE FOR QP/M
;==================================================================================================
;
#IFDEF PLTWBW
  #IF QPMTIMDAT
;
TIMDAT:
	; GET CURRENT DATE/TIME FROM RTC INTO BUFFER
	LD	B,BF_RTCGETTIM		; HBIOS GET TIME FUNCTION
	LD	HL,CLKDAT		; POINTER TO BUFFER
	RST	08			; DO IT
;
	; CONVERT ALL BYTES FROM BCD TO BINARY
	LD	HL,CLKDAT		; BUFFER
	LD	B,7			; DO 7 BYTES
TIMDAT1:
	LD	A,(HL)
	CALL	BCD2BYTE
	LD	(HL),A
	INC	HL
	DJNZ	TIMDAT1
;
	; SWAP BYTES 0 & 2 TO MAKE BUFFER INTO QP/M ORDER
	LD	A,(CLKDAT+0)
	PUSH	AF
	LD	A,(CLKDAT+2)
	LD	(CLKDAT+0),A
	POP	AF
	LD	(CLKDAT+2),A
;
	LD	HL,CLKDAT		; RETURN BUFFER ADDRESS
	RET
;
  #ENDIF
#ENDIF
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
;      Device	      LST:    PUN:    RDR:    CON:
; Bit positions	      7 6     5 4     3 2     1 0
;
; Dec	Binary
;
;  0	  00	      TTY:    TTY:    TTY:    TTY:
;  1	  01	      CRT:    PTP:    PTR:    CRT:
;  2	  10	      LPT:    UP1:    UR1:    BAT:
;  3	  11	      UL1:    UP2:    UR2:    UC1:
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
#IFDEF PLTUNA

LD_TTY	.EQU	0		; -> COM0:
LD_CRT	.EQU	0		; -> CRT:
LD_BAT	.EQU	DEV_BAT
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

LD_TTY	.EQU	CIO_CONSOLE	; -> COM0:
LD_CRT	.EQU	CIO_CONSOLE	; -> CRT:
LD_BAT	.EQU	DEV_BAT
LD_UC1	.EQU	CIO_CONSOLE	; -> COM1:
LD_PTR	.EQU	CIO_CONSOLE	; -> COM1:
LD_UR1	.EQU	CIO_CONSOLE	; -> COM2:
LD_UR2	.EQU	CIO_CONSOLE	; -> COM3:
LD_PTP	.EQU	CIO_CONSOLE	; -> COM1:
LD_UP1	.EQU	CIO_CONSOLE	; -> COM2:
LD_UP2	.EQU	CIO_CONSOLE	; -> COM3:
LD_LPT	.EQU	CIO_CONSOLE	; -> LPT0:
LD_UL1	.EQU	CIO_CONSOLE	; -> LPT1:

#ENDIF
;
DEVMAP:
;
	; CONSOLE (CON:)
	.DB	LD_TTY			; CON:=TTY: (IOBYTE XXXXXX00)
	.DB	LD_CRT			; CON:=CRT: (IOBYTE XXXXXX01)
	.DB	LD_BAT			; CON:=BAT: (IOBYTE XXXXXX10)
	.DB	LD_UC1			; CON:=UC1: (IOBYTE XXXXXX11)
	; READER (RDR:)
	.DB	LD_TTY			; RDR:=TTY: (IOBYTE XXXX00XX)
	.DB	LD_PTR			; RDR:=PTR: (IOBYTE XXXX01XX)
	.DB	LD_UR1			; RDR:=UR1: (IOBYTE XXXX10XX)
	.DB	LD_UR2			; RDR:=UR2: (IOBYTE XXXX11XX)
	; PUNCH (PUN:)
	.DB	LD_TTY			; PUN:=TTY: (IOBYTE XX00XXXX)
	.DB	LD_PTP			; PUN:=PTP: (IOBYTE XX01XXXX)
	.DB	LD_UP1			; PUN:=UP1: (IOBYTE XX10XXXX)
	.DB	LD_UP2			; PUN:=UP2: (IOBYTE XX11XXXX)
	; LIST (LST:)
	.DB	LD_TTY			; LST:=TTY: (IOBYTE 00XXXXXX)
	.DB	LD_CRT			; LST:=CRT: (IOBYTE 01XXXXXX)
	.DB	LD_LPT			; LST:=LPT: (IOBYTE 10XXXXXX)
	.DB	LD_UL1			; LST:=UL1: (IOBYTE 11XXXXXX)
;
;==================================================================================================
;   DRIVE MAPPING TABLE (DRVMAP)
;==================================================================================================
;
; Disk mapping is done using a drive map table (DRVMAP) which is built
; dynamically at cold boot.  See the DRV_INIT routine.	This table is
; made up of entries as documented below.  The table is prefixed with one
; byte indicating the number of entries.  The position of the entry indicates
; the drive letter, so the first entry is A:, the second entry is B:, etc.
;
;	UNIT:	BIOS DISK UNIT # (BYTE)
;	SLICE:	DISK SLICE NUMBER (BYTE)
;	DPH:	DPH ADDRESS OF DRIVE (WORD)
;
; DRVMAP --+
;	   |   DRIVE A		|   DRIVE B	     |	   |   DRIVE N		|
;    +-----V------+-------+-----+--------------------+	   +--------------------+
;    |	N  | UNIT | SLICE | DPH | UNIT | SLICE | DPH | ... | UNIT | SLICE | DPH |
;    +----8+-----8+------8+-+-16+-----8+------8+-+-16+	   +-----8+------8+-+-16+
;			    |			 |			    |
;      +--------------------+			 +-> [DPH]		    +-> [DPH]
;      |
;      V-----+-------+-------+-------+--------+-----+-----+-----+--------+
; DPH: | XLT | 0000H | 0000H | 0000H | DIRBUF | DPB | CSV | ALV | LBAOFF |
;      +---16+-----16+-----16+-----16+------16+-+-16+-+-16+-+-16+------32+
;		   (ONE DPH PER DRIVE)		|     |	    |
;						|     |	    +----------+
;						|     |		       |
;			 +----------------------+     V-------------+  V-------------+
;			 |			      |	  CSV BUF   |  |   ALV BUF   |
;			 |			      +-------------+  +-------------+
;			 |				(CSZ BYTES)	 (ASZ BYTES)
;			 |
;      +-----+-----+-----V-----+-----+-----+-----+-----+-----+-----+-----+-----+-----+
; DPB: | CSZ | ASZ | BLS | SPT | BSH | BLM | EXM | DSM | DRM | AL0 | AL1 | CKS | OFF |
;      +---16+---16+----8+---16+----8+----8+----8+---16+---16+----8+----8+---16+---16+
;      |<--- PREFIX ---->|<------------------- STANDARD CP/M DPB ------------------->|
;
;==================================================================================================
; DPB MAPPING TABLE
;==================================================================================================
;
; MAP MEDIA ID'S TO APPROPRIATE DPB ADDRESSES
; THE ENTRIES IN THIS TABLE MUST COINCIDE WITH THE VALUES
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
	.DW	DPB_HDNEW	; MID_HDNEW (1024 DIR ENTRIES)
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
	;LD	SP,STACK	; STACK FOR INITIALIZATION
	LD	SP,CCP_LOC	; PUT STACK JUST BELOW CCP
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nCBIOS Starting...$"
	CALL	PRTSTRD
	.DB	"\r\nCopying INIT code to 0x8000...$"
#ENDIF
;
	; COPY INITIALIZATION CODE TO RUNNING LOCATION $8000
	LD	HL,BUFPOOL
	LD	DE,$8000
	LD	BC,CBIOS_END - BUFPOOL
	PUSH	HL		; SAVE START ADR FOR BELOW
	PUSH	HL		; SAVE START ADR AGAIN FOR BELOW
	PUSH	BC		; SAVE LENGTH FOR BELOW
	LDIR			; COPY THE CODE
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nClearing disk buffer...$"
#ENDIF
;
	; CLEAR BUFFER
	POP	BC		; RECOVER LENGTH
	POP	HL		; RECOVER START
	POP	DE		; RECOVER START AS DEST
	LD	(HL),0		; SET FIRST BYTE TO ZERO
	INC	DE		; OFFSET DEST
	DEC	BC		; REDUCE LEN BY ONE
	LDIR			; USE LDIR TO FILL
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nStarting INIT routine at 0x8000$"
#ENDIF
;
	CALL	INIT		; PERFORM COLD BOOD ROUTINE
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nResetting CP/M...$"
#ENDIF
	CALL	RESCPM		; RESET CPM
;
#IF AUTOSUBMIT
  #IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nPerforming Auto Submit...$"
  #ENDIF
	CALL	AUTOSUB		; PREP AUTO SUBMIT, IF APPROPRIATE
#ENDIF
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nLaunching CP/M...$"
#ENDIF
;
	JR	GOCPM		; THEN OFF TO CP/M WE GO...
;
;__________________________________________________________________________________________________
REBOOT:
	; RESTART, REPLACES BOOT AFTER INIT
#IFDEF PLTUNA
	; FOR UNA, COLD BOOT
	DI				; NO INTERRUPTS
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,0			; ROM BOOT BANK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
#ENDIF
;
#IFDEF PLTWBW
	; WARM START
	LD	B,BF_SYSRESET		; SYSTEM RESTART
	LD	C,BF_SYSRES_WARM	; WARM START
	CALL	$FFF0			; CALL HBIOS
#ENDIF
;
	; JUMP TO RESTART ADDRESS
	JP	0
;
;__________________________________________________________________________________________________
WBOOT:
;
#IFDEF PLTWBW
	; GIVE HBIOS A CHANCE TO DIAGNOSE ISSUES, PRIMARILY
	; THE OCCURRENCE OF A Z180 INVALID OPCODE TRAP
	POP	HL			; SAVE PC FOR DIAGNOSIS
	LD	SP,STACK		; STACK FOR INITIALIZATION
	LD	BC,$F003		; HBIOS USER RESET FUNCTION
	RST	08			; DO IT
#ENDIF
;
#IFDEF PLTUNA
	LD	SP,STACK		; STACK FOR INITIALIZATION

	; RESTORE COMMAND PROCESSOR FROM UNA BIOS CACHE
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,(BNKBIOS)		; UBIOS_PAGE (SEE PAGES.INC)
	RST	08			; DO IT
	PUSH	DE			; SAVE PREVIOUS BANK
	
	LD	HL,(CCPBUF)		; ADDRESS OF CCP BUF IN BIOS MEM
	LD	DE,CCP_LOC		; ADDRESS IN HI MEM OF CCP
	LD	BC,CCP_SIZ		; SIZE OF CCP
	LDIR				; DO IT
	
	LD	BC,$01FB		; UNA FUNC = SET BANK
	POP	DE			; RECOVER OPERATING BANK
	RST	08			; DO IT
#ELSE
	; RESTORE COMMAND PROCESSOR FROM CACHE IN HB BANK
	LD	B,BF_SYSSETCPY		; HBIOS FUNC: SETUP BANK COPY
	LD	DE,(BNKBIOS)		; D = DEST (USER BANK), E = SRC (BIOS BANK)
	LD	HL,CCP_SIZ		; HL = COPY LEN = SIZE OF COMMAND PROCESSOR
	RST	08			; DO IT
	LD	B,BF_SYSBNKCPY		; HBIOS FUNC: PERFORM BANK COPY
	LD	HL,(CCPBUF)		; COPY FROM FIXED LOCATION IN HB BANK
	LD	DE,CCP_LOC		; TO CCP LOCATION IN USR BANK
	RST	08			; DO IT
#ENDIF
;
	; SOME APPLICATIONS STEAL THE BDOS SERIAL NUMBER STORAGE
	; AREA (FIRST 6 BYTES OF BDOS) ASSUMING IT WILL BE RESTORED
	; AT WARM BOOT BY RELOADING OF BDOS.  WE DON'T WANT TO RELOAD
	; BDOS, SO INSTEAD THE SERIAL NUMBER STORAGE IS FIXED HERE
	; SO THAT THE DRI SERIAL NUMBER VERIFICATION DOES NOT FAIL
	LD	HL,BDOS_LOC
	LD	BC,6
	XOR	A
	CALL	FILL
;
	CALL	RESCPM		; RESET CPM
	JR	GOCPM		; THEN OFF TO CP/M WE GO...
;
;__________________________________________________________________________________________________
RESCPM:
;
	LD	A,$C3			; LOAD A WITH 'JP' INSTRUCTION (USED BELOW)
;
	; CPU RESET / RST 0 / JP 0 -> WARM START CP/M
	LD	($0000),A		; JP OPCODE GOES HERE
	LD	HL,WBOOTE		; GET WARM BOOT ENTRY ADDRESS
	LD	($0001),HL		; AND PUT IT AT $0001

	; CALL 5 -> INVOKE BDOS
	LD	($0005),A		; JP OPCODE AT $0005
	LD	HL,BDOS_LOC + 6		; GET BDOS ENTRY ADDRESS
	LD	($0006),HL		; PUT IT AT $0006
;
	; INSTALL ROMWBW CBIOS PAGE ZERO STAMP AT $40
	LD	HL,STPIMG		; FROM STAMP DATA IMAGE
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
	RET
;
;__________________________________________________________________________________________________
GOCPM:
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
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nTransfer to CCP...$"
#ENDIF
;
	LD	C,A			; SETUP C WITH CURRENT USER/DISK, ASSUME IT IS OK
	JP	CCP_LOC			; JUMP TO COMMAND PROCESSOR
;
;
;==================================================================================================
;   CHARACTER BIOS FUNCTIONS
;==================================================================================================
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
	;OR	$00		; PUT LOGICAL DEVICE IN BITS 2-3 (CON:=$00, RDR:=$04, PUN:=$08, LST:=$0C
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
	;JR	LISTIO		; COMMENTED OUT, FALL THROUGH OK
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
	;JR	PUNCHIO		; COMMENTED OUT, FALL THROUGH OK
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
;	RET
;
;__________________________________________________________________________________________________
CIOST:
; COMPLETION ROUTINE FOR CHARACTER STATUS FUNCTIONS (IST/OST)
;
#IFDEF PLTUNA
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
#IFDEF PLTUNA
	LD	C,B		; MOVE FUNCTION TO C
	LD	B,A		; DEVICE GOES IN B
#ELSE
	LD	C,A		; SAVE IN C FOR BIOS USAGE
#ENDIF

	CP	DEV_BAT		; CHECK FOR SPECIAL DEVICE (BAT, NUL)
	JR	NC,CIO_DISP1	; HANDLE SPECIAL DEVICE
	RST	08		; RETURN VIA COMPLETION ROUTINE SET AT START
	RET

CIO_DISP1:
	; HANDLE SPECIAL DEVICES
	CP	DEV_BAT		; BAT: ?
	JR	Z,CIO_BAT	; YES, GO TO BAT DEVICE HANDLER
	CP	DEV_NUL		; NUL: ?
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
	CALL	PRTSELDSK
#ENDIF
;
	JP	DSK_SELECT
;
;__________________________________________________________________________________________________
HOME:
; SELECT TRACK 0 (BC = 0) AND FALL THRU TO SETTRK
#IF DSKTRACE
	CALL	PRTHOME
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
	LD	(DSKOP),A	; SET THE ACTIVE DISK OPERATION
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
	CALL	PRTDSKOP
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
	ADD	HL,DE		; HL PIONTS TO DPB ENTRY IN DPH
	LD	A,(HL)		; DEREFERENCE HL
	INC	HL		; ... TO GET
	LD	H,(HL)		; ... DPB ADDRESS
	LD	L,A		; ... SO HL NOW POINTS TO DPB ADDRESS
	LD	C,(HL)		; DEREFERENCE HL
	INC	HL		; ... INTO BC SO THAT
	LD	B,(HL)		; ... BC NOW HAS SPT
	LD	(UNASPT),BC	; SAVE SECTORS PER TRACK
	DEC	HL		; BACKUP TO START OF DPB
	DEC	HL		; BACKUP ONE BYTE FOR RECORDS PER BLOCK (BYTE IN FRONT OF DPB)
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
	CALL	PRTDSKOP
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
#IFDEF PLTUNA
	CALL	BLK_SETUP
	EX	DE,HL
	LD	BC,128
	LDIR
	RET
#ELSE
	LD	B,BF_SYSSETCPY	; HBIOS FUNC: SETUP BANK COPY
	LD	A,(BNKUSER)	; GET USER BANK
	LD	E,A		; E = SOURCE (USER BANK)
	LD	A,(BNKBIOS)	; GET DEST BANK
	LD	D,A		; D = DEST (BIOS BANK)
	LD	HL,128		; HL = COPY LEN = DMA BUFFER SIZE
	RST	08		; DO IT
	CALL	BLK_SETUP	; SETUP SOURCE AND DESTINATION
	LD	B,BF_SYSBNKCPY	; HBIOS FUNC: PERFORM BANK COPY
	EX	DE,HL		; SWAP HL/DE FOR BLOCK OPERATION
	RST	08		; DO IT
	RET
#ENDIF
;
;__________________________________________________________________________________________________
;
; DEBLOCK DATA - EXTRACT DESIRED CPM DMA BUF FROM PHYSICAL SECTOR BUFFER
;
BLK_DEBLOCK:
#IFDEF PLTUNA
	CALL	BLK_SETUP
	LD	BC,128
	LDIR
	RET
#ELSE
	LD	B,BF_SYSSETCPY	; HBIOS FUNC: SETUP BANK COPY
	LD	DE,(BNKBIOS)	; E = SOURCE (BIOS BANK), D = DEST (USER BANK)
	LD	HL,128		; HL = COPY LEN = DMA BUFFER SIZE
	RST	08		; DO IT
	CALL	BLK_SETUP	; SETUP SOURCE AND DESTINATION
	LD	B,BF_SYSBNKCPY	; HBIOS FUNC: PERFORM BANK COPY
	RST	08		; DO IT
	RET
#ENDIF
;
;__________________________________________________________________________________________________
;
; SETUP SOURCE AND DESTINATION POINTERS FOR BLOCK COPY OPERATION
; AT EXIT, HL = ADDRESS OF DESIRED BLOCK IN SECTOR BUFFER, DE = DMA
;
BLK_SETUP:
	LD		A,(SEKSEC)	; GET LOW BYTE OF SECTOR
	AND		3		; A = INDEX OF CPM BUF IN SEC BUF
	RRCA				; MULTIPLY BY 64
	RRCA
	LD		E,A		; INTO LOW ORDER BYTE OF DESTINATION
	LD		D,0		; HIGH ORDER BYTE IS ZERO
	LD		HL,(DSKBUF)	; HL = START OF SEC BUF
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
; ON RETURN, D=UNIT, E=SLICE, HL=DPH ADDRESS
;
DSK_GETINF:
	LD	HL,(DRVMAPADR)	; HL := START OF UNA DRIVE MAP
	DEC	HL		; POINT TO DRIVE COUNT
	LD	A,C		; A := CPM DRIVE
	CP	(HL)		; COMPARE TO NUMBER OF DRIVES CONFIGURED
	JR	NC,DSK_GETINF1	; IF OUT OF RANGE, GO TO ERROR RETURN
	INC	HL		; POINT TO START OF DRIVE MAP
;
	RLCA			; MULTIPLY A BY 4
	RLCA			; ... TO USE AS OFFSET INTO DRVMAP
	CALL	ADDHLA		; ADD OFFSET
	LD	D,(HL)		; D := UNIT
	
	LD	A,D		; PUT UNIT IN ACCUM
	INC	A		; $FF -> $00
	JR	Z,DSK_GETINF1	; HANDLE UNASSIGNED DRIVE LETTER
	
	INC	HL		; BUMP TO SLICE
	LD	E,(HL)		; E := SLICE
	INC	HL		; POINT TO DPH LSB
	LD	A,(HL)		; A := DPH LSB
	INC	HL		; POINT TO DPH MSB
	LD	H,(HL)		; H := DPH MSB
	LD	L,A		; L := DPH LSB

	;LD	A,H		; TEST FOR INVALID DPH
	;OR	L		; ... BY CHECKING FOR ZERO VALUE
	;JR	Z,DSK_GETINF1	; HANDLE ZERO DPH, DRIVE IS INVALID

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
	CALL	DSK_GETINF	; GET D=UNIT, E=SLICE, HL=DPH ADDRESS
	;CALL	NZ,PANIC	; *DEBUG*
	RET	NZ		; RETURN IF INVALID DRIVE (A=1, NZ SET, HL=0)
	PUSH	BC		; WE NEED  B LATER, SAVE ON STACK
;
	; SAVE ALL THE NEW STUFF
	LD	A,C		; A := CPM DRIVE NO
	LD	(SEKDSK),A	; SAVE IT
	LD	A,D		; A := UNIT
	LD	(SEKUNIT),A	; SAVE UNIT
	LD	(SEKDPH),HL	; SAVE DPH ADDRESS
;
	LD	A,E		; A := SLICE
	LD	(SLICE),A	; SAVE IT
	; UPDATE LBAOFF FROM DPH
	LD	HL,(SEKDPH)
	LD	A,16
	CALL	ADDHLA
	LD	DE,SEKLBA
	LD	BC,4
	LDIR
;
	; RESTORE DE TO BC (FOR ACCESS TO DRIVE LOGIN BIT)
	POP	BC		; GET ORIGINAL E INTO B
;
	; CHECK IF THIS IS LOGIN, IF NOT, BYPASS MEDIA DETECTION
	; FIX: WHAT IF PREVIOUS MEDIA DETECTION FAILED???
	BIT	0,B		; TEST DRIVE LOGIN BIT
	JR	NZ,DSK_SELECT2	; BYPASS MEDIA DETECTION
;
#IFDEF PLTUNA
;
	LD	A,(SEKUNIT)	; GET DISK UNIT
	LD	B,A		; UNIT NUM TO B
	LD	C,$48		; UNA FUNC: GET DISK TYPE
	CALL	$FFFD		; CALL UNA
	LD	A,D		; MOVE DISK TYPE TO A
	CP	$40		; RAM/ROM DRIVE?
	JR	Z,DSK_SELECT1	; HANDLE RAM/ROM DRIVE
	LD	A,MID_HD	; OTHERWISE WE HAVE A HARD DISK
	JR	DSK_SELECT1A	; DONE
;
DSK_SELECT1:
	; UNA RAM/ROM DRIVE
	LD	C,$45		; UNA FUNC: GET DISK INFO
	LD	DE,(DSKBUF)	; 512 BYTE BUFFER
	CALL	$FFFD		; CALL UNA
	BIT	7,B		; TEST RAM DRIVE BIT
	LD	A,MID_MDROM	; ASSUME ROM
	JR	Z,DSK_SELECT1A	; IS ROM, DONE
	LD	A,MID_MDRAM	; MUST BE RAM
;
DSK_SELECT1A:
	LD	(MEDID),A
;
#ELSE
;
	; DETERMINE MEDIA IN DRIVE
	LD	A,(SEKUNIT)	; GET UNIT
	LD	C,A		; STORE IN C
	LD	B,BF_DIOMEDIA	; DRIVER FUNCTION = DISK MEDIA
	LD	E,1		; ENABLE MEDIA CHECK/DISCOVERY
	RST	08		; DO IT
	LD	A,E		; RESULTANT MEDIA ID TO ACCUM
	LD	(MEDID),A	; SAVE IT
	OR	A		; SET FLAGS
	LD	HL,0		; ASSUME FAILURE
	RET	Z		; BAIL OUT IF NO MEDIA
;
#ENDIF
;
	; CLEAR LBA OFFSET (DWORD)
	; SET HI BIT FOR LBA ACCESS FOR NOW
	LD	HL,0		; ZERO
	LD	(SEKLBA),HL	; CLEAR FIRST WORD
	SET	7,H		; ASSUME LBA ACCESS FOR NOW
	LD	(SEKLBA+2),HL	; CLEAR SECOND WORD
;
#IFDEF PLTWBW
;
	LD	A,(SEKUNIT)	; GET UNIT
	LD	C,A		; STORE IN C
	LD	B,BF_DIODEVICE	; HBIOS FUNC: REPORT DEVICE INFO
	RST	08		; GET UNIT INFO, DEVICE TYPE IN D
	LD	A,D		; DEVICE TYPE -> A
	AND	$F0		; ISOLATE HIGH BITS
	CP	DIODEV_FD	; FLOPPY?
	JR	NZ,DSK_SELECT1B	; IF NOT, DO LBA IO
	LD	HL,SEKLBA+3	; POINT TO HIGH ORDER BYTE
	RES	7,(HL)		; SWITCH FROM LBA -> CHS
;
#ENDIF
;
DSK_SELECT1B:
	; SET LEGACY SECTORS PER SLICE
	LD	HL,16640	; LEGACY SECTORS PER SLICE
	LD	(SPS),HL	; SAVE IT
;
	; CHECK MBR OF PHYSICAL DISK BEING SELECTED
	; WILL UPDATE MEDID AND LBAOFF IF VALID CP/M PARTITION EXISTS
	CALL	DSK_MBR		; UPDATE MEDIA FROM MBR
	LD	HL,0		; ASSUME FAILURE
	RET	NZ		; ABORT ON I/O ERROR
;
	; SET HL TO DPBMAP ENTRY CORRESPONDING TO MEDIA ID
	LD	A,(MEDID)	; GET MEDIA ID
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
	LD	HL,(SEKDPH)	; POINT TO START OF DPH
	LD	BC,10		; OFFSET OF DPB IN DPH
	ADD	HL,BC		; HL := DPH.DPB
	LD	(HL),E		; SET LSB OF DPB IN DPH
	INC	HL		; BUMP TO MSB
	LD	(HL),D		; SET MSB OF DPB IN DPH
;
	; PLUG LBA OFFSET INTO ACTIVE DPH
	LD	HL,(SEKDPH)	; POINT TO START OF DPH
	LD	BC,16		; OFFSET OF LBA OFFSET IN DPH
	ADD	HL,BC		; HL := DPH.LBAOFF PTR
	EX	DE,HL		; DEST IS DPH.LBAOFF PTR
	LD	HL,SEKLBA	; SOURCE IS LBAOFF
	LD	BC,4		; 4 BYTES
	LDIR			; DO IT
;
DSK_SELECT2:
	LD	HL,(SEKDPH)	; HL = DPH ADDRESS FOR CP/M
	XOR	A		; FLAG SUCCESS
	RET			; NORMAL RETURN
;
; CHECK MBR OF DISK TO SEE IF IT HAS A PARTITION TABLE.
; IF SO, LOOK FOR A CP/M PARTITION.  IF FOUND, GET
; UPDATE THE PARTITION OFFSET (LBAOFF) AND UPDATE
; THE MEDIA ID (MEDID).
;
DSK_MBR:
	; CHECK MEDIA TYPE, ONLY HARD DISK IS APPLICABLE
	LD	A,(MEDID)	; GET MEDIA ID
	CP	MID_HD		; HARD DISK?
	JR	Z,DSK_MBR0	; IF SO, CONTINUE
	XOR	A		; ELSE, N/A, SIGNAL SUCCESS
	RET			; AND RETURN
	
DSK_MBR0:
;
#IFDEF PLTWBW
	; ACTIVATE BIOS BANK TO ACCESS DISK BUFFER
	LD	(STKSAV),SP	; SAVE CUR STACK
	LD	SP,STACK	; NEW STACK IN HI MEM
	LD	A,(BNKBIOS)	; ACTIVATE HBIOS BANK
	PUSH	IX		; SAVE IX
	LD	IX,DSK_MBR1	; ROUTINE TO RUN
	CALL	HB_BNKCALL	; DO IT
	POP	IX		; RESTORE IX
	LD	SP,(STKSAV)	; RESTORE ORIGINAL STACK
	RET
#ENDIF
;
DSK_MBR1:
	; FLUSH DSKBUF TO MAKE SURE IT IS SAFE TO USE IT.
	CALL	BLKFLSH		; MAKE SURE DISK BUFFER IS NOT DIRTY
	XOR	A		; CLEAR ACCUM
	LD	(HSTACT),A	; CLEAR HOST BUFFER ACTIVE FLAG
;
	; READ SECTOR ZERO (MBR)
	LD	B,BF_DIOREAD	; READ FUNCTION
	LD	A,(SEKUNIT)	; GET UNIT
	LD	C,A		; PUT IN C
	LD	DE,0		; LBA SECTOR ZERO
	LD	HL,0		; ...
#IFDEF PLTWBW
	SET	7,D		; MAKE SURE LBA ACCESS BIT SET
#ENDIF
	CALL	DSK_IO2		; DO IT
	RET	NZ		; ABORT ON ERROR
;
	; CHECK SIGNATURE
	LD	HL,(DSKBUF)	; DSKBUF ADR
	LD	DE,$1FE		; OFFSET TO SIGNATURE
	ADD	HL,DE		; POINT TO SIGNATURE
	LD	A,(HL)		; GET FIRST BYTE
	CP	$55		; CHECK FIRST BYTE
	JR	NZ,DSK_MBR5	; NO MATCH, NO PART TABLE
	INC	HL		; NEXT BYTE
	LD	A,(HL)		; GET SECOND BYTE
	CP	$AA		; CHECK SECOND BYTE
	JR	NZ,DSK_MBR5	; NO MATCH, NO PART TABLE, ABORT
;
	; TRY TO FIND OUR ENTRY IN PART TABLE AND CAPTURE LBA OFFSET
	LD	B,4		; FOUR ENTRIES IN PART TABLE
	LD	HL,(DSKBUF)	; DSKBUF ADR
	LD	DE,$1BE+4	; OFFSET OF FIRST ENTRY PART TYPE
	ADD	HL,DE		; POINT TO IT
DSK_MBR2:
	LD	A,(HL)		; GET PART TYPE
	CP	$2E		; CP/M PARTITION?
	JR	Z,DSK_MBR3	; COOL, GRAB THE LBA OFFSET
	LD	DE,16		; PART TABLE ENTRY SIZE
	ADD	HL,DE		; BUMP TO NEXT ENTRY PART TYPE
	DJNZ	DSK_MBR2	; LOOP THRU TABLE
	JR	DSK_MBR5	; TOO BAD, NO CP/M PARTITION
;
DSK_MBR3:
	; WE HAVE LOCATED A VALID CP/M PARTITION
	; HL POINTS TO PART TYPE FIELD OF PART ENTRY
;
	; CAPTURE THE LBA OFFSET
	LD	DE,4		; LBA IS 4 BYTES AFTER PART TYPE
	ADD	HL,DE		; POINT TO IT
	LD	DE,SEKLBA	; LOC TO STORE LBA OFFSET
	LD	BC,4		; 4 BYTES (32 BITS)
	LDIR			; COPY IT
;
	; CHECK THAT REQUESTED SLICE IS "INSIDE" PARTITION
	; SLICE SIZE IS EXACTLY 16,384 SECTORS (8MB), SO WE CAN JUST
	; RIGHT SHIFT PARTITION SECTOR COUNT BY 14 BITS
	LD	E,(HL)		; HL POINTS TO FIRST BYTE
	INC	HL		; ... OF 32 BIT PARTITION
	LD	D,(HL)		; ... SECTOR COUNT,
	INC	HL		; ... LOAD SECTOR COUNT
	PUSH	DE		; ... INTO DE:HL
	LD	E,(HL)		; ...
	INC	HL		; ...
	LD	D,(HL)		; ...
	POP	HL		; ... DE:HL = PART SIZE IN SECTORS
	LD	B,2		; DE = DE:HL >> 2  (TRICKY!)
	CALL	RL32		; DE = SLICECNT
	EX	DE,HL		; HL = SLICECNT
	LD	A,(SLICE)	; GET TARGET SLICE
	LD	C,A		; PUT IN C
	LD	B,0		; BC := REQUESTED SLICE #
	SCF			; SET CARRY!
	SBC	HL,BC		; MAX SLICES - SLICE - 1
	JR	NC,DSK_MBR4	; NO OVERFLOW, OK TO CONTINUE
	OR	$FF		; SLICE TOO HIGH, SIGNAL ERROR
	RET			; AND BAIL OUT
;
DSK_MBR4:
	; IF BOOT FROM PARTITION, USE NEW SECTORS PER SLICE VALUE
	LD	HL,16384		; NEW SECTORS PER SLICE
	LD	(SPS),HL		; SAVE IT

	; UPDATE MEDIA ID
	LD	A,MID_HDNEW	; NEW MEDIA ID
	LD	(MEDID),A	; SAVE IT
;
DSK_MBR5:
	; ADJUST LBA OFFSET BASED ON TARGET SLICE
	LD	A,(SLICE)		; GET SLICE, A IS LOOP CNT
	LD	HL,(SEKLBA)		; SET DE:HL
	LD	DE,(SEKLBA+2)		; ... TO STARTING LBA
	LD	BC,(SPS)		; SECTORS PER SLICE
DSK_MBR6:
	OR	A			; SET FLAGS TO CHECK LOOP CNTR
	JR	Z,DSK_MBR8		; DONE IF COUNTER EXHAUSTED
	ADD	HL,BC			; ADD ONE SLICE TO LOW WORD
	JR	NC,DSK_MBR7		; CHECK FOR CARRY
	INC	DE			; IF SO, BUMP HIGH WORD
DSK_MBR7:
	DEC	A			; DEC LOOP DOWNCOUNTER
	JR	DSK_MBR6		; AND LOOP
DSK_MBR8:
	SET	7,D		; SET LBA ACCESS FLAG
	; RESAVE IT
	LD	(SEKLBA),HL	; LOWORD
	LD	(SEKLBA+2),DE	; HIWORD
	; SUCCESSFUL FINISH
	XOR	A		; SUCCESS
	RET			; DONE
;
;
;
DSK_STATUS:
#IFDEF PLTUNA
	XOR	A		; ASSUME OK FOR NOW
	RET			; RETURN
#ELSE
	; C HAS CPM DRIVE, LOOKUP UNIT AND CHECK FOR INVALID DRIVE
	CALL	DSK_GETINF	; B := UNIT
	RET	NZ		; INVALID DRIVE ERROR

	; VALID DRIVE, DISPATCH TO DRIVER
	LD	C,D		; C := UNIT
	LD	B,BF_DIOSTATUS	; B := FUNCTION: STATUS
	RST	08
	RET
#ENDIF
;
;
;
DSK_READ:
	; SET B = FUNCTION: READ
	LD	B,BF_DIOREAD
	JR	DSK_IO
;
;
;
DSK_WRITE:
	; SET B = FUNCTION: WRITE
	LD	B,BF_DIOWRITE
	JR	DSK_IO
;
;
;
DSK_IO:
	LD	A,(HSTUNIT)		; GET UNIT
	LD	C,A			; UNIT -> C
;
#IFDEF PLTWBW
	LD	A,(HSTLBA+3)		; GET HIGH ORDER BYTE
	BIT	7,A			; LBA ACCESS?
	JR	NZ,LBA_IO		; IF SET, GO TO LBA I/O
;
; FLOPPY SPECIFIC TRANSLATION ASSUMES FLOPPY IS DOUBLE-SIDED AND
; USES LOW ORDER BIT OF TRACK AS HEAD VALUE
;
; HBIOS SEEK: HL=CYLINDER, D=HEAD, E=SECTOR
;
	LD	DE,(HSTSEC)		; SECTOR -> DE, HEAD(D) BECOMES ZERO
	LD	HL,(HSTTRK)		; TRACK -> HL (LOW BIT HAS HEAD)
	SRL	H			; SHIFT HEAD BIT OUT OF HL
	RR	L			; ... AND INTO CARRY
	RL	D			; CARRY BIT (HEAD) INTO D
	JR	DSK_IO2			; DO THE DISK I/O
;
#ENDIF
;
LBA_IO:
	PUSH	BC			; SAVE FUNC/UNIT
	; GET TRACK AND SHIFT TO MAKE ROOM FOR 4 BIT SECTOR VALUE
	LD	HL,(HSTTRK)		; GET TRACK
	LD	DE,0			; CLEAR HIWORD
	LD	B,4			; X16 (16 SPT ASSUMED)
	CALL	RL32			; DO IT
	; COMBINE WITH SECTOR
	LD	A,(HSTSEC)		; GET SECTOR
	OR	L
	LD	L,A
	; ADD IN LBA OFFSET FOR PARTITION AND/OR SLICE
	LD	BC,(HSTLBA)		; LBA OFFSET LOWORD
	ADD	HL,BC	
	EX	DE,HL	
	LD	BC,(HSTLBA+2)		; LBA OFFSET HIWORD
	ADC	HL,BC
	EX	DE,HL
	POP	BC			; RESTORE FUNC/UNIT
	;JR	DSK_IO2			; DO THE DISK I/O (FALL THRU)
;
#IFDEF PLTUNA
;
; MAKE UNA UBIOS CALL
; HBIOS FUNC SHOULD STILL BE IN B
; UNIT SHOULD STILL BE IN C
;
DSK_IO2:
	PUSH	BC			; SAVE INCOMING FUNCTION, UNIT
	RES	7,D			; CLEAR LBA BIT FOR UNA
	LD	B,C			; UNIT TO B
	LD	C,$41			; UNA SET LBA
	RST	08			; CALL UNA
	POP	BC			; RECOVER B=FUNC, C=UNIT
	RET	NZ			; ABORT IF SEEK RETURNED AN ERROR W/ ERROR IN A
	LD	E,C			; UNIT TO E
	LD	C,B			; FUNC TO C
	LD	B,E			; UNIT TO B
	LD	DE,(DSKBUF)		; SET BUFFER ADDRESS
	LD	HL,1			; 1 SECTOR
	; DISPATCH TO UBIOS
	RST	08			; CALL UNA
	RET				; DONE
;
#ELSE
;
; MAKE HBIOS CALL
; HBIOS FUNC SHOULD STILL BE IN B
; UNIT SHOULD STILL BE IN C
;
DSK_IO2:
	PUSH	BC			; SAVE INCOMING FUNCTION, UNIT
	LD	B,BF_DIOSEEK		; SETUP FOR NEW SEEK CALL
	RST	08			; DO IT
	POP	BC			; RESTORE INCOMING FUNCTION, DEVICE/UNIT
	RET	NZ			; ABORT IF SEEK RETURNED AN ERROR W/ ERROR IN A
	LD	HL,(DSKBUF)		; GET BUFFER ADDRESS
	LD	A,(BNKBIOS)		; GET BIOS BANK
	LD	D,A			; TRANSFER TO/FROM BIOS BANK
	LD	E,1			; TRANSFER ONE SECTOR
	RST	08			; DO IT
	OR	A			; SET FLAGS
	RET				; DONE
;
#ENDIF
;
;==================================================================================================
; UTILITY FUNCTIONS
;==================================================================================================
;
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
	RET
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
;STR_READONLY	.DB	"\r\nCBIOS Err: Read Only Drive$"
;STR_STALE	.DB	"\r\nCBIOS Err: Stale Drive$"
;
;SECADR		.DW	0		; ADDRESS OF SECTOR IN ROM/RAM PAGE
DEFDRIVE	.DB	0		; DEFAULT DRIVE
CCPBUF		.DW	0		; ADDRESS OF CCP BUF IN BIOS BANK
MEDID		.DB	0		; TEMP STORAGE FOR MEDIA ID
SLICE		.DB	0		; CURRENT SLICE
SPS		.DW	0		; SECTORS PER SLICE
STKSAV		.DW	0		; TEMP SAVED STACK POINTER
;
#IFDEF PLTWBW
  #IF QPMTIMDAT
CLKDAT		.FILL	7,0		; RTC CLOCK DATA BUFFER
  #ENDIF
#ENDIF
;
#IFDEF PLTWBW
BNKBIOS		.DB	0		; BIOS BANK ID
BNKUSER		.DB	0		; USER BANK ID
#ENDIF
;
#IFDEF PLTUNA
BNKBIOS		.DW	0		; BIOS BANK ID
BNKUSER		.DW	0		; USER BANK ID
#ENDIF
;
; DOS DISK VARIABLES
;
DSKOP		.DB	0		; DISK OPERATION (DOP_READ/DOP_WRITE)
WRTYPE		.DB	0		; WRITE TYPE (0=NORMAL, 1=DIR (FORCE), 2=FIRST RECORD OF BLOCK)
DMAADR		.DW	0		; DIRECT MEMORY ADDRESS
HSTWRT		.DB	0		; TRUE = BUFFER IS DIRTY
DSKBUF		.DW	0		; ADDRESS OF PHYSICAL SECTOR BUFFER
;
; LOGICAL DISK I/O REQUEST PENDING
;
SEK:
SEKDSK		.DB	0		; DISK NUMBER 0-15
SEKTRK		.DW	0		; TWO BYTES FOR TRACK # (LOGICAL)
SEKSEC		.DW	0		; TWO BYTES FOR SECTOR # (LOGICAL)
SEKUNIT		.DB	0		; DISK UNIT
SEKDPH		.DW	0		; ADDRESS OF ACTIVE (SELECTED) DPH
SEKOFF		.DW	0		; TRACK OFFSET IN EFFECT FOR SLICE
SEKACT		.DB	TRUE		; ALWAYS TRUE!
SEKLBA		.FILL	4,0		; LBA OFFSET
;
; RESULT OF CPM TO PHYSICAL TRANSLATION
;
XLT:
XLTDSK		.DB	0
XLTTRK		.DW	0
XLTSEC		.DW	0
XLTUNIT		.DB	0
XLTDPH		.DW	0
XLTOFF		.DW	0
XLTACT		.DB	TRUE		; ALWAYS TRUE!
XLTLBA		.FILL	4,0		; LBA OFFSET
;
XLTSIZ		.EQU	$ - XLT
;
; DSK/TRK/SEC IN BUFFER (VALID WHEN HSTACT=TRUE)
;
HST:
HSTDSK		.DB	0		; DISK IN BUFFER
HSTTRK		.DW	0		; TRACK IN BUFFER
HSTSEC		.DW	0		; SECTOR IN BUFFER
HSTUNIT		.DB	0		; DISK UNIT IN BUFFER
HSTDPH		.DW	0		; CURRENT DPH ADDRESS
HSTOFF		.DW	0		; TRACK OFFSET IN EFFECT FOR SLICE
HSTACT		.DB	0		; TRUE = BUFFER HAS VALID DATA
HSTLBA		.FILL	4,0		; LBA OFFSET
;
; SEQUENTIAL WRITE TRACKING FOR (UNA)LLOCATED BLOCK
;
UNA:
UNADSK		.DB	0		; DISK NUMBER 0-15
UNATRK		.DW	0		; TWO BYTES FOR TRACK # (LOGICAL)
UNASEC		.DW	0		; TWO BYTES FOR SECTOR # (LOGICAL)
;
UNASIZ		.EQU	$ - UNA
;
UNACNT		.DB	0		; COUNT DOWN UNALLOCATED RECORDS IN BLOCK
UNASPT		.DW	0		; SECTORS PER TRACK
;
;==================================================================================================
; DISK CONTROL STRUCTURES (DPB, DPH)
;==================================================================================================
;
CKS_RAM		.EQU	0	; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_RAM		.EQU	24	; ALS: BLKS / 8 = 192 / 8 = 24 (ASSUMES 512K DISK)
;
CKS_ROM		.EQU	0	; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_ROM		.EQU	24	; ALS: BLKS / 8 = 192 / 8 = 24 (ASSUMES 512K DISK)
;
CKS_FD		.EQU	64	; CKS: DIR ENT / 4 = 256 / 4 = 64
ALS_FD		.EQU	128	; ALS: BLKS / 8 = 1024 / 8 = 128
;
CKS_HD		.EQU	0	; CKS: 0 FOR NON-REMOVABLE MEDIA
ALS_HD		.EQU	256	; ALS: BLKS / 8 = 2048 / 8 = 256 (ROUNDED UP)
;
;
; DISK PARAMETER BLOCKS
;
; BLS		BSH	BLM	EXM (DSM<256)	EXM (DSM>255)
; ----------	---	---	-------------	-------------
; 1,024		3	7	0		N/A
; 2,048		4	15	1		0
; 4,096		5	31	3		1
; 8,192		6	63	7		3
; 16,384	7	127	15		7
;
; AL0/1: EACH BIT SET ALLOCATES A BLOCK OF DIR ENTRIES.	 EACH DIR ENTRY
;	 IS 32 BYTES.  BIT COUNT = (((DRM + 1) * 32) / BLS)
;
; CKS = (DIR ENT / 4), ZERO FOR NON-REMOVABLE MEDIA
;
; ALS = TOTAL BLKS (DSM + 1) / 8
;__________________________________________________________________________________________________
;
; ROM DISK: 64 SECS/TRK (LOGICAL), 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; ROM DISK SIZE = TOTAL ROM - 128K RESERVED FOR SYSTEM USE
;
; ALS_ROM, EXM, DSM MUST BE FILLED DYNAMICALLY:
;  - ALS_ROM := (BANKS * 2)
;  - EXM := (BANKS <= 16) ? 1 : 0
;  - DSM := (BANKS * 16)
;
; DEFAULT VALUES BELOW ARE FOR 512K ROM
;
	.DW	CKS_ROM		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW	ALS_ROM		; ALS: BLKS / 8
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_ROM:
	.DW	64		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	1		; EXM: (BLKS <= 256) ? 1 : 0
	.DW	192 - 1		; DSM: TOTAL STORAGE IN BLOCKS - 1
	.DW	255		; DRM: DIR ENTRIES - 1 = 255
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	0		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW	0		; OFF: ROM DISK HAS NO SYSTEM AREA
;__________________________________________________________________________________________________
;
; RAM DISK: 64 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
; RAM DISK SIZE = TOTAL RAM - 256K RESERVED FOR SYSTEM USE
;
; ALS_RAM, EXM, DSM MUST BE FILLED DYNAMICALLY:
;  - ALS_RAM := (BANKS * 2)
;  - EXM := (BANKS <= 16) ? 1 : 0
;  - DSM := (BANKS * 16)
;
; DEFAULT VALUES BELOW ARE FOR 512K RAM
;
	.DW	CKS_RAM		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW	ALS_RAM		; ALS: BLKS / 8
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_RAM:
	.DW	64		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	1		; EXM: (BLKS <= 256) ? 1 : 0
	.DW	128 - 1		; DSM: TOTAL STORAGE IN BLOCKS - 1
	.DW	255		; DRM: DIR ENTRIES - 1 = 255
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	0		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW	0		; OFF: RESERVED TRACKS = 0 TRK
;__________________________________________________________________________________________________
;
; 4MB RAM FLOPPY DRIVE, 32 TRKS, 1024 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DW	CKS_HD
	.DW	ALS_HD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_RF:
	.DW	64		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	0		; EXM: EXTENT MASK
	.DW	2047		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = (4MB / 2K BLS) - 1 = 2047
	.DW	511		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB	11111111B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	0		; CKS: ZERO FOR NON-REMOVABLE MEDIA
	.DW	0		; OFF: RESERVED TRACKS = 0 TRK
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
	.DW	64		; SPT: SECTORS PER TRACK
	.DB	5		; BSH: BLOCK SHIFT FACTOR
	.DB	31		; BLM: BLOCK MASK
	.DB	1		; EXM: EXTENT MASK
	.DW	2047		; DSM: TOTAL STORAGE IN BLOCKS - 1 = (8MB / 4K BLS) - 1 = 2047
	.DW	512 - 1		; DRM: DIR ENTRIES - 1
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	0		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW	16		; OFF: RESERVED TRACKS
;
;   BLOCKSIZE (BLS) = 4K, DIRECTORY ENTRIES = 1024
;
	.DW	CKS_HD
	.DW	ALS_HD
	.DB	(4096 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_HDNEW:
	.DW	64		; SPT: SECTORS PER TRACK
	.DB	5		; BSH: BLOCK SHIFT FACTOR
	.DB	31		; BLM: BLOCK MASK
	.DB	1		; EXM: EXTENT MASK
	.DW	2048 - 1 - 4	; DSM: STORAGE BLOCKS - 1 - RES TRKS
	.DW	1024 - 1	; DRM: DIR ENTRIES - 1
	.DB	11111111B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	0		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW	2		; OFF: RESERVED TRACKS
;__________________________________________________________________________________________________
;
; IBM 720KB 3.5" FLOPPY DRIVE, 80 TRKS, 36 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 128
;
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD720:
	.DW	36		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	0		; EXM: EXTENT MASK
	.DW	350		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((720K - 18K OFF) / 2K BLS) - 1 = 350
	.DW	127		; DRM: DIR ENTRIES - 1 = 128 - 1 = 127
	.DB	11000000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	32		; CKS: DIRECTORY CHECK VECTOR SIZE = 128 / 4
	.DW	4		; OFF: RESERVED TRACKS = 4 TRKS * (512 B/SEC * 36 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 1.44MB 3.5" FLOPPY DRIVE, 80 TRKS, 72 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD144:
	.DW	72		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	0		; EXM: EXTENT MASK
	.DW	710		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,440K - 18K OFF) / 2K BLS) - 1 = 710
	.DW	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 72 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 360KB 5.25" FLOPPY DRIVE, 40 TRKS, 9 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 128
;
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD360:
	.DW	36		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	1		; EXM: EXTENT MASK
	.DW	170		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((360K - 18K OFF) / 2K BLS) - 1 = 170
	.DW	127		; DRM: DIR ENTRIES - 1 = 128 - 1 = 127
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	32		; CKS: DIRECTORY CHECK VECTOR SIZE = 128 / 4
	.DW	4		; OFF: RESERVED TRACKS = 4 TRKS * (512 B/SEC * 36 SEC/TRK) = 18K
;__________________________________________________________________________________________________
;
; IBM 1.20MB 5.25" FLOPPY DRIVE, 80 TRKS, 15 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD120:
	.DW	60		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	0		; EXM: EXTENT MASK
	.DW	591		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,200K - 15K OFF) / 2K BLS) - 1 = 591
	.DW	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 60 SEC/TRK) = 15K
;__________________________________________________________________________________________________
;
; IBM 1.11MB 8" FLOPPY DRIVE, 77 TRKS, 15 SECS/TRK, 512 BYTES/SEC
; BLOCKSIZE (BLS) = 2K, DIRECTORY ENTRIES = 256
;
	.DW	CKS_FD
	.DW	ALS_FD
	.DB	(2048 / 128)	; RECORDS PER BLOCK (BLS / 128)
DPB_FD111:
	.DW	60		; SPT: SECTORS PER TRACK
	.DB	4		; BSH: BLOCK SHIFT FACTOR
	.DB	15		; BLM: BLOCK MASK
	.DB	0		; EXM: EXTENT MASK
	.DW	569		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((1,155K - 15K OFF) / 2K BLS) - 1 = 569
	.DW	255		; DRM: DIR ENTRIES - 1 = 256 - 1 = 255
	.DB	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW	64		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW	2		; OFF: RESERVED TRACKS = 2 TRKS * (512 B/SEC * 60 SEC/TRK) = 15K
;
#IFDEF PLTUNA
SECBUF	.FILL	512,0	; PHYSICAL DISK SECTOR BUFFER
#ENDIF
;
;==================================================================================================
; CBIOS BUFFERS
;==================================================================================================
;
BUFPOOL	.EQU	$		; START OF BUFFER POOL
;
;==================================================================================================
; COLD BOOT INITIALIZATION
;
; THIS CODE IS PLACED IN THE BDOS BUFFER AREA TO CONSERVE SPACE.  SINCE
; COLD BOOT DOES NO DISK IO, THIS IS SAFE.
;
;==================================================================================================
;
	.ORG	$8000			; INIT CODE RUNS AT $8000
;
HEAPEND	.EQU	CBIOS_END - 64		; TOP OF HEAP MEM, END OF CBIOS LESS 32 ENTRY STACK
;
INIT:
;
#IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nStarting INIT....$"
#ENDIF
;
	;DI				; NO INTERRUPTS FOR NOW

	; ADJUST BOOT VECTOR TO REBOOT ROUTINE
	LD	HL,REBOOT		; GET REBOOT ADDRESS
	LD	(CBIOS_LOC + 1),HL	; STORE IT IN FIRST ENTRY OF CBIOS JUMP TABLE

#IFDEF PLTUNA
	; GET CRITICAL BANK ID'S
	LD	BC,$03FA		; UNA FUNC = GET CUR EXEC ENV
	CALL	$FFFD			; DE = CUR EXEC PAGE, HL = UBIOS PAGE
	LD	(BNKBIOS),HL		; SAVE UBIOS PAGE
	LD	BC,$05FA		; UNA FUNC = GET USER EXEC ENV
	CALL	$FFFD			; DE = USER LOW PAGE, HL = USER HIGH PAGE (COMMMON)
	LD	(BNKUSER),DE		; SAVE USER PAGE
	LD	DE,$8000		; RAM DRIVE STARTS AT FIRST RAM BANK
	LD	(BNKRAMD),DE		; SAVE STARTING RAM DRIVE BANK

	; MAKE SURE UNA EXEC PAGE IS ACTIVE
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,(BNKUSER)			; SWITCH BACK TO EXEC BANK
	CALL	$FFFD			; DO IT (RST 08 NOT YET INSTALLED)

	; COPY BIOS PAGE ZERO TO USER BANK
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,(BNKBIOS)		; UBIOS_PAGE (SEE PAGES.INC)
	CALL	$FFFD			; DO IT (RST 08 NOT YET INSTALLED)
	PUSH	DE			; SAVE PREVIOUS BANK

	LD	HL,0			; FROM ADDRESS 0 (PAGE ZERO)
	LD	DE,SECBUF		; USE SECBUF AS BOUNCE BUFFER
	LD	BC,256			; ONE PAGE IS 256 BYTES
	LDIR				; DO IT

	LD	BC,$01FB		; UNA FUNC = SET BANK
	POP	DE			; RECOVER OPERATING BANK
	CALL	$FFFD			; DO IT (RST 08 NOT YET INSTALLED)

	LD	HL,SECBUF		; FROM SECBUF (BUNCE BUFFER)
	LD	DE,0			; TO PAGE ZERO OF OPERATING BANK
	LD	BC,256			; ONE PAGE IS 256 BYTES
	LDIR				; DO IT

	; INSTALL UNA INVOCATION VECTOR FOR RST 08
	LD	A,$C3			; JP INSTRUCTION
	LD	(8),A			; STORE AT 0x0008
	LD	HL,($FFFE)		; UNA ENTRY VECTOR
	LD	(9),HL			; STORE AT 0x0009

#ELSE
	; GET CRITICAL BANK ID'S
	LD	B,BF_SYSGET		; HBIOS FUNC=GET SYS INFO
	LD	C,BF_SYSGET_BNKINFO	; HBIOS SUBFUNC=GET BANK ASSIGNMENTS
	RST	08			; CALL HBIOS
	LD	A,D			; GET HBIOS BANK RETURNED IN D
	LD	(BNKBIOS),A		; ... AND SAVE IT
	LD	A,E			; GET USER BANK RETURNED IN E
	LD	(BNKUSER),A		; ... AND SAVE IT
;
  #IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nReseting HBIOS....$"
  #ENDIF
;
	; SOFT RESET HBIOS
	LD	B,BF_SYSRESET		; HB FUNC: RESET
	LD	C,BF_SYSRES_INT		; WARM START
	RST	08			; DO IT
;
  #IF DEBUG
	CALL	PRTSTRD
	.DB	"\r\nCopying HCB....$"
  #ENDIF
	; CREATE A TEMP COPY OF THE HBIOS CONFIG BLOCK (HCB)
	; FOR REFERENCE USE DURING INIT
	LD	B,BF_SYSSETCPY		; HBIOS FUNC: SETUP BANK COPY
	LD	DE,(BNKBIOS)		; D = DEST (USER BANK), E = SOURCE (BIOS BANK)
	LD	HL,HCB_SIZ		; HL = COPY LEN = SIZE OF HCB
	RST	08			; DO IT
	LD	B,BF_SYSBNKCPY		; HBIOS FUNC: PERFORM BANK COPY
	LD	HL,HCB_LOC		; COPY FROM FIXED LOCATION IN HB BANK
	LD	DE,HCB			; TO TEMP LOCATION IN USR BANK
	RST	08			; DO IT

	; CAPTURE RAM DRIVE STARTING BANK
	LD	A,(HCB + HCB_BIDRAMD0)
	LD	(BNKRAMD),A
#ENDIF

	; PARAMETER INITIALIZATION
	LD	A,DEF_IOBYTE		; LOAD DEFAULT IOBYTE
	LD	(IOBYTE),A		; STORE IT

	; CBIOS BANNER
	CALL	NEWLINE2		; FORMATTING
	LD	DE,STR_BANNER		; POINT TO BANNER
	CALL	WRITESTR		; DISPLAY IT

#IFDEF PLTWBW
	; CHECK FPR HBIOS/CBIOS VERSION MISMATCH
	LD	B,BF_SYSVER		; HBIOS VERSION
	RST	08			; DO IT, DE=MAJ/MIN/UP/PAT
	LD	A,D			; A := MAJ/MIN
	CP	((RMJ << 4) | RMN)	; MATCH?
	JR	NZ,INIT1		; HANDLE VER MISMATCH
	LD	A,E			; A := OS UP/PAT
	AND	$F0			; PAT NOT INCLUDED IN MATCH
	CP	(RUP << 4)		; MATCH?
	JR	NZ,INIT1		; HANDLE VER MISMATCH
	JR	INIT2			; ALL GOOD, CONTINUE
INIT1:
	; DISPLAY VERSION MISMATCH
	CALL	NEWLINE2		; FORMATTING
	LD	DE,STR_VERMIS		; VERSION MISMATCH
	CALL	WRITESTR		; DISPLAY IT
INIT2:
#ENDIF
;
#IFDEF PLTUNA
	; SAVE COMMAND PROCESSOR IMAGE TO MALLOCED CACHE IN UNA BIOS PAGE
	LD	C,$F7		; UNA MALLOC
	LD	DE,CCP_SIZ	; SIZE OF CCP
	RST	08		; DO IT
	CALL	NZ,ERR_BIOMEM	; BIG PROBLEM
	LD	(CCPBUF),HL	; SAVE THE ADDRESS (IN BIOS MEM)

	LD	BC,$01FB	; UNA FUNC = SET BANK
	LD	DE,(BNKBIOS)	; UBIOS_PAGE (SEE PAGES.INC)
	RST	08		; DO IT
	PUSH	DE		; SAVE PREVIOUS BANK

	LD	HL,CCP_LOC	; ADDRESS IN HI MEM OF CCP
	LD	DE,(CCPBUF)	; ADDRESS OF CCP BUF IN BIOS MEM
	LD	BC,CCP_SIZ	; SIZE OF CCP
	LDIR			; DO IT

	LD	BC,$01FB	; UNA FUNC = SET BANK
	POP	DE		; RECOVER OPERATING BANK
	RST	08		; DO IT
#ELSE
	; SAVE COMMAND PROCESSOR TO ALLOCATED CACHE IN RAM BANK 1
	LD	B,BF_SYSALLOC	; HBIOS FUNC: ALLOCATE HEAP MEMORY
	LD	HL,CCP_SIZ	; SIZE TO ALLOC (SIZE OF CCP)
	RST	08		; DO IT
	CALL	NZ,ERR_BIOMEM	; BIG PROBLEM
	LD	(CCPBUF),HL	; SAVE THE ADDRESS (IN BIOS MEM)
	LD	B,BF_SYSSETCPY	; HBIOS FUNC: SETUP BANK COPY
	LD	A,(BNKUSER)	; GET USER BANK
	LD	E,A		; E = SOURCE (USER BANK)
	LD	A,(BNKBIOS)	; GET BIOS BANK
	LD	D,A		; D = DEST (BIOS BANK)
	LD	HL,CCP_SIZ	; HL = COPY LEN = SIZE OF COMMAND PROCESSOR
	RST	08		; DO IT
	LD	B,BF_SYSBNKCPY	; HBIOS FUNC: PERFORM BANK COPY
	LD	HL,CCP_LOC	; COPY FROM CCP LOCATION IN USR BANK
	LD	DE,(CCPBUF)	; TO ALLOCATED LOCATION IN HB BANK
	RST	08		; DO IT
#ENDIF

	; DISK SYSTEM INITIALIZATION
	CALL	BLKRES		; RESET DISK (DE)BLOCKING ALGORITHM
	CALL	DEV_INIT	; INITIALIZE CHARACTER DEVICE MAP
	CALL	MD_INIT		; INITIALIZE MEMORY DISK DRIVER (RAM/ROM)
	CALL	DRV_INIT	; INITIALIZE DRIVE MAP
	CALL	DPH_INIT	; INITIALIZE DPH TABLE AND BUFFERS
;
	; SET THE DEFAULT DRIVE
	XOR	A		; ZERO ACCUM
	LD	(DEFDRIVE),A	; SET DEFAULT DRIVE TO A: TO START
;
#IFDEF PLTWBW
;
	; IF WE HAVE MULTIPLE DRIVES AND THE FIRST DRIVE IS RAM DRIVE
	; AND THE SECOND DRIVE IS ROM DRIVE OR FLASH DRIVE
	; THEN MAKE OUR DEFAULT STARTUP DRIVE THE SECOND DRIVE (B:)
;
	; CHECK FOR 2+ DRIVES
	LD	HL,(DRVMAPADR)	; POINT TO DRIVE MAP
	DEC	HL		; BUMP BACK TO DRIVE COUNT
	LD	A,(HL)		; GET IT
	CP 	2		; COMPARE TO 2
	JR	C,INIT2X	; IF LESS THAN 2, THEN DONE
;
	; CHECK IF FIRST UNIT IS RAM
	LD	B,BF_DIODEVICE	; HBIOS FUNC: REPORT DEVICE INFO
	INC	HL		; POINT TO UNIT FIELD OF FIRST DRIVE
	LD	C,(HL)		; PUT UNIT NUM IN C
	RST	08		; CALL HBIOS
	LD	A,C		; GET ATTRIBUTES
	AND	%00111000	; ISOLATE TYPE BITS
	CP	%00101000	; TYPE = RAM?
	JR	NZ,INIT2X	; IF NOT THEN DONE
;
	; CHECK IF SECOND UNIT IS ROM OR FLASH
	LD	B,BF_DIODEVICE	; HBIOS FUNC: REPORT DEVICE INFO
	LD	HL,(DRVMAPADR)	; POINT TO DRIVE MAP
	LD	A,4		; 4 BYTES PER ENTRY
	CALL	ADDHLA		; POINT TO UNIT FIELD OF SECOND DRIVE
	LD	C,(HL)		; PUT UNIT NUM IN C
	RST	08		; CALL HBIOS
	LD	A,C		; GET ATTRIBUTES
	AND	%00111000	; ISOLATE TYPE BITS
	CP	%00100000	; TYPE = ROM?
	JR	Z,INIT2A	; IF SO, ADJUST DEF DRIVE
	CP	%00111000	; TYPE = FLASH?
	JR	NZ,INIT2X	; IF NOT THEN DONE
;
INIT2A:
	; CRITERIA MET, ADJUST DEF DRIVE TO B:
	LD	A,1		; USE SECOND DRIVE AS DEFAULT
	LD	(DEFDRIVE),A	; RECORD DEFAULT DRIVE
;
INIT2X:
;
#ENDIF
;
#IFDEF PLTUNA
	; USE A DEDICATED BUFFER FOR UNA PHYSICAL DISK I/O
	LD	HL,SECBUF		; ADDRESS OF PHYSICAL SECTOR BUFFER
	LD	(DSKBUF),HL		; SAVE IT IN DSKBUF FOR LATER
#ELSE
	; ALLOCATE A SINGLE SECTOR DISK BUFFER ON THE HBIOS HEAP
	LD	B,BF_SYSALLOC		; BIOS FUNC: ALLOCATE HEAP MEMORY
	LD	HL,512			; 1 SECTOR, 512 BYTES
	RST	08			; DO IT
	CALL	NZ,PANIC		; HANDLE ERROR
	LD	(DSKBUF),HL		; RECORD THE BUFFER ADDRESS
#ENDIF
;
	; DISPLAY FREE MEMORY
	LD	DE,STR_LDR2		; FORMATTING
	CALL	WRITESTR		; AND PRINT IT
	;LD	HL,CBIOS_END		; SUBTRACT HIGH WATER
	LD	HL,HEAPEND		; SUBTRACT HIGH WATER
	LD	DE,(HEAPTOP)		; ... FROM TOP OF CBIOS
	OR	A			; ... WITH CF CLEAR
	SBC	HL,DE			; ... SO HL GETS BYTES FREE
	CALL	PRTDEC			; PRINT IT
	LD	DE,STR_MEMFREE		; ADD DESCRIPTION
	CALL	WRITESTR		; AND PRINT IT
;
	LD	A,(DEFDRIVE)		; GET DEFAULT DRIVE
	LD	(CDISK),A		; ... AND SETUP CDISK
;
	; OS BANNER
	CALL	NEWLINE2		; FORMATTING
	LD	DE,STR_CPM		; DEFAULT TO CP/M LABEL
	LD	A,(BDOS_LOC)		; GET FIRST BYTE OF BDOS
	CP	'Z'			; IS IT A 'Z' (FOR ZSDOS)?
	JR	NZ,INIT3		; NOPE, CP/M IS RIGHT
	LD	DE,STR_ZSDOS		; SWITCH TO ZSDOS LABEL
INIT3:
	CALL	WRITESTR		; DISPLAY OS LABEL
	LD	DE,STR_TPA1		; TPA PREFIX
	CALL	WRITESTR
	LD	A,BDOS_LOC / 1024	; TPA SIZE IS START OF BDOS
	CALL	PRTDECB			; PRINT IT
	CALL	PC_PERIOD		; DECIMAL POINT
	LD	A,0 + (((BDOS_LOC % 1024) * 100) / 1024)
	CALL	PRTDECB			; MANTISSA
	LD	DE,STR_TPA2		; AND TPA SUFFIX
	CALL	WRITESTR
	CALL	NEWLINE			; FORMATTING
;
; SETUP QP/M TIMDAT ROUTINE VECTOR IN ZERO PAGE AT 0x0010
;
#IFDEF PLTWBW
  #IF QPMTIMDAT
	LD	A,$C3			; JP INSTRUCTION
	LD	($0010),A		; STORE AT 0x0008
	LD	HL,TIMDAT		; ROUTINE ADDRESS
	LD	($0011),HL		; SET VECTOR
  #ENDIF
#ENDIF
;
	RET				; DONE
;
ERR_BIOMEM:
	CALL	NEWLINE2		; FORMATTING
	LD	DE,STR_BIOMEM		; HBIOS HEAP MEM OVERFLOW
	CALL	WRITESTR		; TELL THE USER
	CALL	PANIC			; AND GRIND TO A SCREACHING HALT
;
;
;__________________________________________________________________________________________________
;
#IF AUTOSUBMIT
;
AUTOSUB:
;
	; SETUP AUTO SUBMIT COMMAND (IF REQUIRED FILES EXIST)
	LD	A,(DEFDRIVE)		; GET DEFAULT DRIVE
	PUSH	AF			; SAVE DEFAULT DRIVE
	INC	A			; CONVERT FROM DRIVE NUM TO FCB DRIVE CODE
	LD	(FCB_SUB),A		; SET DRIVE OF SUBMIT.COM FCB
	LD	(FCB_PRO),A		; SET DRIVE OF PROFILE.SUB FCB
;
	LD	C,13			; RESET DISK SYSTEM
	CALL	BDOS			; DO IT
	POP	AF			; RESTORE DEFAULT DRIVE
;
	LD	C,17			; BDOS FUNCTION: FIND FIRST
	LD	DE,FCB_SUB		; CHECK FOR SUBMIT.COM
	CALL	BDOS			; INVOKE BDOS TO LOOK FOR FILE
	INC	A			; CHECK FOR ERR, $FF --> $00
	RET	Z			; ERR, DO NOT ATTEMPT AUTO SUBMIT
;
	LD	C,17			; BDOS FUNCTION: FIND FIRST
	LD	DE,FCB_PRO		; CHECK FOR PROFILE.SUB
	CALL	BDOS			; INVOKE BDOS TO LOOK FOR FILE
	INC	A			; CHECK FOR ERR, $FF --> $00
	RET	Z			; ERR, DO NOT ATTEMPT AUTO SUBMIT
;
	LD	HL,CMD			; ADDRESS OF STARTUP COMMANDS
	LD	DE,CCP_LOC + 7		; START OF COMMAND BUFFER IN CCP
	LD	BC,CMDLEN		; LENGTH OF AUTOSTART COMMAND
	LDIR				; PATCH COMMAND LINE INTO CCP
	RET				; DONE
;
#ENDIF
;
;
;__________________________________________________________________________________________________
DEV_INIT:
;
#IFDEF PLTWBW
;
	; PATCH IN CRT: DEVICE
	LD	A,(HCB + HCB_CRTDEV)	; GET CONSOLE DEVICE
	CP	$FF			; NUL MEANS NO CRT DEVICE
	JR	Z,DEV_INIT000		; IF SO, LEAVE IT ALONE
	LD	(DEVMAP + 1),A		; CONSOLE CRT
	LD	(DEVMAP + 13),A		; LIST CRT
;
	; UPDATE IOBYTE IF CRT DEVICE IS ACTIVE
	LD	A,(HCB + HCB_CRTDEV)	; GET CRT DEVICE
	LD	B,A			; SAVE IN B
	LD	A,(HCB + HCB_CONDEV)	; GET CONSOLE DEVICE
	CP	B			; COMPARE
	JR	NZ,DEV_INIT000		; IF DIFFERENT (CRT NOT ACTIVE), LEAVE IOBYTE ALONE
	LD	A,1			; IF SAME (CRT ACTIVE), SET IOBYTE FOR CON: = CRT:
	LD	(IOBYTE),A		; STORE IN IOBYTE
	LD	HL,DEV_INIT1		; INIT FIRST DEV ASSIGN ADR
	JR	DEV_INIT00		; SKIP AHEAD
;
DEV_INIT000:
	; CONSOLE IS NOT THE CRT, SO
	; ASSIGN CURRENT CONSOLE AS TTY
	LD	A,(HCB + HCB_CONDEV)	; GET CONSOLE DEVICE
	CALL	DEV_INIT1		; ASSIGN AS TTY
;
DEV_INIT00:
	; LOOP THRU DEVICES ADDING DEVICES TO DEVMAP
	; CONSOLE DEVICE WAS ALREADY DONE, SO IT IS SKIPPED HERE
	LD	B,BF_SYSGET		; HBIOS FUNC: GET SYS INFO
	LD	C,BF_SYSGET_CIOCNT	; SUBFUNC: GET CIO UNIT COUNT
	RST	08			; E := SERIAL UNIT COUNT
	LD	B,E			; COUNT TO B
	LD	C,0			; UNIT INDEX
DEV_INIT0:
	;PUSH	BC			; SAVE LOOP CONTROL
	;PUSH	HL			; SAVE TARGET
	;LD	B,BF_CIODEVICE		; HBIOS FUNC: GET DEVICE INFO
	;RST	08			; D := DEVICE TYPE, E := PHYSICAL UNIT NUMBER
	;POP	HL			; RESTORE TARGET
	;LD	A,D			; DEVICE TYPE TO A
	;; FIX: BELOW SHOULD TEST THE "TERMINAL" BIT INSTEAD OF CHECKING DEVICE NUMBER
	;CP	CIODEV_TERM		; COMPARE TO FIRST VIDEO DEVICE
	;POP	BC			; RESTORE LOOP CONTROL
	;LD	A,C			; UNIT INDEX TO ACCUM
	;;CALL	C,JPHL			; DO IT IF DEVICE TYPE < VDU

	LD	A,(HCB + HCB_CONDEV)	; CURRENT CONSOLE UNIT
	CP	C			; IS CURRENT CONSOLE?
	LD	A,C			; UNIT INDEX TO ACCUM
	CALL	NZ,JPHL			; DO IF NOT CURRENT CONSOLE
	INC	C			; NEXT UNIT
	DJNZ	DEV_INIT0		; LOOP TILL DONE
	RET				; ALL DONE
;
DEV_INIT1:
	; PATCH IN COM0: DEVICE ENTRIES, COM0: IS TTY:
	LD	(DEVMAP + 0),A		; TTY: @ CON:
	LD	(DEVMAP + 4),A		; TTY: @ RDR:
	LD	(DEVMAP + 8),A		; TTY: @ PUN:
	LD	(DEVMAP + 12),A		; TTY: @ LST:
	LD	HL,DEV_INIT2		; HL := CODE FOR NEXT DEVICE
	RET
;
DEV_INIT2:
	; PATCH IN COM1: DEVICE ENTRIES, COM1: IS UC1:, PTR:, PTP:, LPT:
	LD	(DEVMAP + 3),A		; UC1: @ CON:
	LD	(DEVMAP + 5),A		; PTR: @ RDR:
	LD	(DEVMAP + 9),A		; PTP: @ PUN:
	LD	(DEVMAP + 14),A		; LPT: @ LST:
	LD	HL,DEV_INIT3		; HL := CODE FOR NEXT DEVICE
	RET
;
DEV_INIT3:
	; PATCH IN COM2: DEVICE ENTRIES, COM2: IS UR1:, UP1:, UL1:
	LD	(DEVMAP + 6),A		; UR1: @ RDR:
	LD	(DEVMAP + 10),A		; UP1: @ PUN:
	LD	(DEVMAP + 15),A		; UL1: @ LST:
	LD	HL,DEV_INIT4		; HL := CODE FOR NEXT DEVICE
	RET
;
DEV_INIT4:
	; PATCH IN COM3: DEVICE ENTRIES, COM3: IS UR2:, UP2:
	LD	(DEVMAP + 7),A		; UR2: @ RDR:
	LD	(DEVMAP + 11),A		; UP2: @ PUN:
	LD	HL,DEV_INIT5		; HL := CODE FOR NEXT DEVICE
	RET
;
DEV_INIT5:
	RET				; FAILSAFE IN CASE MORE THAN 4 COM DEVICES
;
#ENDIF
	RET
;
;
;
;__________________________________________________________________________________________________
MD_INIT:
;
; UDPATE THE RAM/ROM DPB STRUCTURES BASED ON HARDWARE
;
#IFDEF PLTWBW
	; TODO: HANDLE DISABLED RAM/ROM DISK BETTER.
	; IF RAM OR ROM DISK ARE DISABLED, BELOW WILL STILL
	; TRY TO ADJUST THE DPB BASED ON RAM BANK CALCULATIONS.
	; IT SHOULD NOT MATTER BECAUSE THE DPB SHOULD NEVER BE
	; USED.  IT WOULD BE BETTER TO GET RAMD0/ROMD0 AND
	; RAMDN/ROMDN FROM THE HCB AND USE THOSE TO CALC THE
	; DPB ADJUSTMENT.  IF DN-D0=0, BYPASS ADJUSTMENT.
	LD	A,(HCB + HCB_ROMBANKS)	; ROM BANK COUNT
	SUB	4		; REDUCE BANK COUNT BY RESERVED PAGES
	LD	IX,DPB_ROM	; ADDRESS OF DPB
	CALL	MD_INIT1	; FIX IT UP
;
	LD	A,(HCB + HCB_RAMBANKS)	; RAM BANK COUNT
	SUB	8		; REDUCE BANK COUNT BY RESERVED PAGES
	LD	IX,DPB_RAM	; ADDRESS OF DPB
	CALL	MD_INIT1	; FIX IT UP
;
	JR	MD_INIT4	; DONE
;
MD_INIT1:
;
	; PUT USABLE BANK COUNT IN HL
	LD	L,A		; PUT IN LSB OF HL
	LD	H,0		; MSB IS ALWAYS ZERO
;
	; UPDATE ALS FIELD
	LD	A,L		; LSB OF PAGE COUNT
	RLCA			; DOUBLE IT
	LD	(IX - 3),A	; SAVE IT AS LSB OF ALS
;
	; UDPATE EXM FIELD
	LD	A,L		; LSB OF PAGE COUNT
	CP	16 + 1		; COMPARE TO EXM THRESHOLD
	LD	A,1		; ASSUME <= 16 BANKS, EXM := 1
	JR	C,MD_INIT2
	XOR	A		; > 16 BANKS, EXM := 0
MD_INIT2:
	LD	(IX + 4),A	; SAVE EXM VALUE
;
	; UPDATE DSM FIELD
	LD	B,4		; ROTATE 4 TIMES TO MULTIPLY BY 16
MD_INIT3:
	SLA	L		; SHIFT LSB
	RL	H		; SHIFT MSB W/ CARRY
	DJNZ	MD_INIT3	; REPEAT AS NEEDED
	DEC	HL		; SUBTRACT 1 FOR PROPER DSM VALUE
	LD	(IX+5),L	; SAVE UPDATED
	LD	(IX+6),H	; ... DSM VALUE
	RET
;
MD_INIT4:
;
#ENDIF
;
#IFDEF PLTUNA
;
; INITIALIZE RAM DISK BY FILLING DIRECTORY WITH 'E5' BYTES
; FILL FIRST 8K OF RAM DISK TRACK 1 WITH 'E5'
;
#IF (CLRRAMDISK != CLR_NEVER)
	DI				; NO INTERRUPTS
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,(BNKRAMD)		; FIRST BANK OF RAM DISK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
;
#IF (CLRRAMDISK == CLR_AUTO)
	; CHECK THE FIRST SECTOR (512 BYTES) FOR ALL ZEROES.  IF SO,
	; IT IMPLIES THE RAM IS UNINITIALIZED.
	LD	HL,0			; START AT BEGINING OF RAM DISK
	LD	BC,512			; COMPARE 512 BYTES
	XOR	A			; COMPARE TO ZERO
CLRRAM000:
	CPI				; A - (HL), HL++, BC--
	JR	NZ,CLRRAM00		; IF NOT ZERO, GO TO NEXT TEST
	JP	PE,CLRRAM000		; LOOP THRU ALL BYTES
	JR	CLRRAM2			; ALL ZEROES, JUMP TO INIT
CLRRAM00:
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
	LD	DE,(BNKUSER)		; SWITCH BACK TO EXEC BANK FOR WRITESTR
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
;
	CALL	NEWLINE2		; FORMATTING
	LD	DE,STR_INITRAMDISK	; RAM DISK INIT MESSAGE
	CALL	WRITESTR		; DISPLAY IT
;
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,(BNKRAMD)		; FIRST BANK OF RAM DISK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
;
	LD	HL,0			; SOURCE ADR FOR FILL
	LD	BC,$2000		; LENGTH OF FILL IS 8K
	LD	A,$E5			; FILL VALUE
	CALL	FILL			; DO IT
CLRRAM3:
	LD	BC,$01FB		; UNA FUNC = SET BANK
	LD	DE,(BNKUSER)		; SWITCH BACK TO EXEC BANK
	CALL	$FFFD			; DO IT (RST 08 NOT SAFE HERE)
	EI				; RESUME INTERRUPTS
;
#ENDIF
;
#ELSE
;
; INITIALIZE RAM DISK BY FILLING DIRECTORY WITH 'E5' BYTES
; FILL FIRST 8K OF RAM DISK TRACK 1 WITH 'E5'
;
#IF (CLRRAMDISK != CLR_NEVER)
	LD	A,(BNKRAMD)		; FIRST BANK OF RAM DISK
	CP	$FF			; $FF SIGNIFIES NO RAM DISK
	RET	Z			; BAIL OUT IF NO RAM DISK
	DI				; NO INTERRUPTS
	CALL	HB_BNKSEL		; SELECT BANK

#IF (CLRRAMDISK == CLR_AUTO)
	; CHECK THE FIRST SECTOR (512 BYTES) FOR ALL ZEROES.  IF SO,
	; IT IMPLIES THE RAM IS UNINITIALIZED.
	LD	HL,0			; START AT BEGINING OF RAM DISK
	LD	BC,512			; COMPARE 512 BYTES
	XOR	A			; COMPARE TO ZERO
CLRRAM000:
	CPI				; A - (HL), HL++, BC--
	JR	NZ,CLRRAM00		; IF NOT ZERO, GO TO NEXT TEST
	JP	PE,CLRRAM000		; LOOP THRU ALL BYTES
	JR	CLRRAM2			; ALL ZEROES, JUMP TO INIT
CLRRAM00:
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
	LD	A,(BNKUSER)		; SWITCH BACK TO USER BANK
	CALL	HB_BNKSEL		; SELECT BANK
	CALL	NEWLINE2		; FORMATTING
	LD	DE,STR_INITRAMDISK	; RAM DISK INIT MESSAGE
	CALL	WRITESTR		; DISPLAY IT
	LD	A,(BNKRAMD)		; SWITCH BACK TO FIRST BANK
	CALL	HB_BNKSEL		; SELECT BANK
	LD	HL,0			; SOURCE ADR FOR FILL
	LD	BC,$2000		; LENGTH OF FILL IS 8K
	LD	A,$E5			; FILL VALUE
	CALL	FILL			; DO IT
CLRRAM3:
	LD	A,(BNKUSER)		; USR BANK (TPA)
	CALL	HB_BNKSEL		; SELECT BANK
	EI				; RESUME INTERRUPTS
#ENDIF
;
#ENDIF
;
	RET
;
;
;__________________________________________________________________________________________________
#IFDEF PLTUNA
;
DRV_INIT:
;
; PERFORM UBIOS SPECIFIC INITIALIZATION
; BUILD DRVMAP BASED ON AVAILABLE UBIOS DISK DEVICE LIST
;
	; GET BOOT UNIT/SLICE INFO
	LD	BC,$00FC		; UNA FUNC: GET BOOTSTRAP HISTORY
	RST	08			; CALL UNA
	LD	A,L			; PUT IN ACCUM
	AND	$0F			; UNIT IN LOW NIBBLE
	LD	D,A			; UNIT NUM TO D
	LD	A,L			; GET ORIGINAL VALUE BACK
	RLCA				; MOVE SLICE TO LOW NIBBLE
	RLCA				; ...
	RLCA				; ...
	RLCA				; ...
	AND	$0F			; SLICE NOW IN LOW NIBBLE
	LD	E,A			; SLICE TO E
	LD	(BOOTVOL),DE		; D -> UNIT, E -> SLICE
;
	; INIT DEFAULT
	LD	A,D			; BOOT UNIT?
	CP	1			; IF ROM BOOT, DEF DRIVE SHOULD BE B:
	JR	Z,DRV_INIT1		; ... SO LEAVE AS IS AND SKIP AHEAD
	XOR	A			; ELSE FORCE TO DRIVE A:
DRV_INIT1:
	LD	(DEFDRIVE),A		; STORE IT
;
	; SETUP THE DRVMAP STRUCTURE
	LD	HL,(HEAPTOP)		; GET CURRENT HEAP TOP
	INC	HL			; SKIP 1 BYTE FOR ENTRY COUNT PREFIX
	LD	(DRVMAPADR),HL		; SAVE AS DRIVE MAP ADDRESS
	LD	(HEAPTOP),HL		; ... AND AS NEW HEAP TOP
;
	; LOOP THRU DEVICES TO COUNT TOTAL HARD DISK VOLUMES
	LD	B,0			; START WITH UNIT 0
	LD	L,0			; INIT HD VOL COUNT
;
DRV_INIT2:	; LOOP THRU ALL UNITS AVAILABLE
	PUSH	HL			; SAVE HD VOL COUNT
	LD	C,$48			; UNA FUNC: GET DISK TYPE
	LD	L,0			; PRESET UNIT COUNT TO ZERO
	CALL	$FFFD			; CALL UNA, B IS ASSUMED TO BE UNTOUCHED!!!
	LD	A,L			; UNIT COUNT TO A
	POP	HL			; RESTORE HD VOL COUNT
	OR	A			; PAST END?
	JR	Z,DRV_INIT4		; WE ARE DONE, MOVE ON
	CALL	DRV_INIT3		; PROCESS THE UNIT
	INC	B			; NEXT UNIT
	JR	DRV_INIT2		; LOOP
;
DRV_INIT3:
	LD	A,D			; DRIVER TYPE TO A
	CP	$40			; RAM/ROM?
	RET	Z			; DO NOT COUNT
	;CP	$??			; FLOPPY?
	;RET	Z			; DO NOT COUNT
	INC	L			; INCREMENT HARD DISK COUNT
	RET				; DONE
;
DRV_INIT4:	; SET SLICES PER VOLUME (HDSPV) BASED ON HARD DISK VOLUME COUNT
	LD	A,L			; HARD DISK VOLUME COUNT TO A
	LD	E,8			; ASSUME 8 SLICES PER VOLUME
	DEC	A			; DEC ACCUM TO CHECK FOR COUNT = 1
	JR	Z,DRV_INIT5		; YES, SKIP AHEAD TO IMPLEMENT 8 HDSPV
	LD	E,4			; NOW ASSUME 4 SLICES PER VOLUME
	DEC	A			; DEC ACCUM TO CHECK FOR COUNT = 2
	JR	Z,DRV_INIT5		; YES, SKIP AHEAD TO IMPLEMENT 4 HDSPV
	LD	E,2			; IN ALL OTHER CASES, WE USE 2 HDSPV
;
DRV_INIT5:
	LD	A,E			; SLICES PER VOLUME VALUE TO ACCUM
	LD	(HDSPV),A		; SAVE IT
;
	LD	DE,(BOOTVOL)		; BOOT VOLUME (UNIT, SLICE)
	LD	A,1			; ROM DISK UNIT?
	CP	D			; CHECK IT
	JR	Z,DRV_INIT5A		; IF SO, SKIP BOOT DRIVE
	LD	B,1			; JUST ONE SLICE PLEASE
	CALL	DRV_INIT8A		; DO THE BOOT DEVICE
;
DRV_INIT5A:
	; SETUP TO ENUMERATE DEVICES TO BUILD DRVMAP
	LD	B,0			; START WITH UNIT 0
;
DRV_INIT6:	; LOOP THRU ALL UNITS AVAILABLE
	LD	C,$48			; UNA FUNC: GET DISK TYPE
	LD	L,0			; PRESET UNIT COUNT TO ZERO
	CALL	$FFFD			; CALL UNA, B IS ASSUMED TO BE UNTOUCHED!!!
	LD	A,L			; UNIT COUNT TO A
	OR	A			; PAST END?
	RET	Z			; WE ARE DONE
	PUSH	BC			; SAVE UNIT
	CALL	DRV_INIT7		; PROCESS THE UNIT
	POP	BC			; RESTORE UNIT
	INC	B			; NEXT UNIT
	JR	DRV_INIT6		; LOOP
;
DRV_INIT7:	; PROCESS CURRENT UNIT (SEE UNA PROTOIDS.INC)
	LD	A,D			; DRIVE TYPE TO ACCUM
	LD	D,B			; UNIT TO D
	LD	E,0			; INIT SLICE INDEX
	LD	B,1			; DEFAULT LOOP COUNTER (1 SLICE)
	CP	$40			; RAM/ROM?
	JR	Z,DRV_INIT8		; SINGLE SLICE, DO IT
	;CP	$??			; FLOPPY?
	;JR	Z,DRV_INIT8		; SINGLE SLICE, DO IT
	LD	A,(HDSPV)		; GET SLICES PER VOLUME TO ACCUM
	LD	B,A			; MOVE TO B FOR LOOP COUNTER
;
DRV_INIT8:
	; SLICE CREATION LOOP
	; DE=UNIT/SLICE, B=SLICE CNT
	LD	A,(BOOTVOL + 1)		; GET BOOT UNIT
	CP	1			; ROM BOOT?
	JR	Z,DRV_INIT8A		; IF SO, OK TO CONTINUE
	CP	D			; COMPARE TO CUR UNIT
	JR	NZ,DRV_INIT8A		; IF NE, OK TO CONTINUE
	LD	A,(BOOTVOL)		; GET BOOT SLICE
	CP	E			; COMPARE TO CUR SLICE
	JR	NZ,DRV_INIT8A		; IF NE, OK TO CONTINUE
	INC	E			; IS BOOT DU/SLICE, SKIP IT
	DJNZ	DRV_INIT8		; LOOP AS NEEDED
	RET				; DONE
;
DRV_INIT8A:	; ENTRY POINT TO SKIP BOOT DISK/LU CHECK
;
	; INC DRVMAP ENTRY COUNT AND CHECK FOR 16 ENTRY MAXIMUM
	LD	HL,(DRVMAPADR)		; POINT TO DRIVE MAP
	DEC	HL			; BACKUP TO POINT TO ENTRY COUNT
	LD	A,(HL)			; CURRENT COUNT TO ACCUM
	CP	16			; AT MAX?
	RET	NC			; IF >= MAX, JUST BAIL OUT
	INC	(HL)			; INCREMENT THE ENTRY COUNT
;
	; ALLOCATE ENTRY AND FILL IN UNIT, SLICE
	LD	HL,4			; 4 BYTES PER ENTRY
	CALL	ALLOC			; ALLOCATE SPACE
	;CALL	NZ,PANIC		; SHOULD NEVER ERROR HERE
	CALL	C,PANIC			; SHOULD NEVER ERROR HERE
	LD	(HL),D			; SAVE UNIT IN FIRST BYTE OF DRVMAP ENTRY
	INC	HL			; POINT TO NEXT BYTE OF DRVMAP ENTRY
	LD	(HL),E			; SAVE SLICE NUM IN SECOND BYTE OF DRVMAP ENTRY
;
	INC	E			; INCREMENT SLICE INDEX
	DJNZ	DRV_INIT8		; LOOP AS NEEDED
	RET				; DONE
;
#ELSE
;
DRV_INIT:
;
; PERFORM HBIOS SPECIFIC INITIALIZATION
; BUILD DRVMAP BASED ON AVAILABLE HBIOS DISK DEVICE LIST
;
	; GET BOOT UNIT/SLICE INFO
	LD	DE,(HCB + HCB_BOOTVOL)	; BOOT VOLUME (UNIT, SLICE)
	LD	(BOOTVOL),DE		; D -> UNIT, E -> SLICE
;
	; SETUP THE DRVMAP STRUCTURE
	LD	HL,(HEAPTOP)		; GET CURRENT HEAP TOP
	INC	HL			; SKIP 1 BYTE FOR ENTRY COUNT PREFIX
	LD	(DRVMAPADR),HL		; SAVE AS DRVMAP ADDRESS
	LD	(HEAPTOP),HL		; AND AS NEW HEAP TOP
;
	; SETUP TO LOOP THROUGH AVAILABLE DEVICES BUILDING LIST OF
	; ACTIVE UNITS AND COUNTING NUMBER OF ACTIVE HARD DISK
	; DEVICES.  NON-HARD DISK UNITS ARE ALWAYS CONSIDERED
	; ACTIVE, BUT HARD DISK UNITS ARE ONLY CONSIDERED ACTIVE
	; IF THERE IS MEDIA IN THE DRIVE.
	LD	B,BF_SYSGET
	LD	C,BF_SYSGET_DIOCNT
	RST	08			; E := DISK UNIT COUNT
	LD	B,E			; COUNT TO B
	LD	A,B			; COUNT TO A
	OR	A			; SET FLAGS
	RET	Z			; HANDLE ZERO DEVICES (ALBEIT POORLY)
;
	; LOOP THRU DEVICES TO COUNT TOTAL HARD DISK VOLUMES
	LD	C,0			; INIT C AS DEVICE LIST INDEX
	LD	D,0			; INIT D AS TOTAL DEVICE COUNT
	LD	E,0			; INIT E FOR HARD DISK DEVICE COUNT
	LD	HL,DRVLST		; INIT HL PTR TO DRIVE LIST
;
DRV_INIT2:
	CALL	DRV_INIT3		; CHECK DRIVE
	INC	C			; NEXT UNIT
	DJNZ	DRV_INIT2		; LOOP
	LD	A,D			; TOTAL DEVICE COUNT TO D
	LD	(DRVLSTC),A		; SAVE THE COUNT
	JR	DRV_INIT4		; CONTINUE
;
DRV_INIT3:
	PUSH	DE			; SAVE DE (HARD DISK VOLUME COUNTER)
	PUSH	HL			; SAVE DRIVE LIST PTR
	PUSH	BC			; SAVE LOOP CONTROL
	LD	B,BF_DIODEVICE		; HBIOS FUNC: REPORT DEVICE INFO
	RST	08			; CALL HBIOS, UNIT TO C
	LD	A,D			; DEVICE TYPE TO A
	POP	BC			; RESTORE LOOP CONTROL
	POP	HL			; RESTORE DRIVE LIST PTR
	POP	DE			; RESTORE DE
	CP	DIODEV_IDE		; HARD DISK DEVICE?
	JR	NC,DRV_INIT3A		; IF SO, HANDLE SPECIAL
	LD	(HL),C			; SAVE UNIT NUM IN LIST
	INC	HL			; BUMP PTR
	INC	D			; INC TOTAL DEVICE COUNT
	RET
;
DRV_INIT3A:
	; CHECK FOR ACTIVE AND RETURN IF NOT
	PUSH	DE			; SAVE DE (HARD DISK VOLUME COUNTER)
	PUSH	HL			; SAVE DRIVE LIST PTR
	PUSH	BC			; SAVE LOOP CONTROL

	LD	B,BF_DIOMEDIA		; HBIOS FUNC: SENSE MEDIA
	LD	E,1			; PERFORM MEDIA DISCOVERY
	RST	08

	POP	BC			; RESTORE LOOP CONTROL
	POP	HL			; RESTORE DRIVE LIST PTR
	POP	DE			; RESTORE DE

	RET	NZ			; IF NO MEDIA, JUST RETURN

	; IF ACTIVE...
	LD	(HL),C			; SAVE UNIT NUM IN LIST
	INC	HL			; BUMP PTR
	INC	D			; INC TOTAL DEVICE COUNT
	INC	E			; INCREMENT HARD DISK COUNT
	RET				; AND RETURN
;
DRV_INIT4:	; SET SLICES PER VOLUME (HDSPV) BASED ON HARD DISK VOLUME COUNT
	LD	A,E			; HARD DISK VOLUME COUNT TO A
	LD	E,8			; ASSUME 8 SLICES PER VOLUME
	DEC	A			; DEC ACCUM TO CHECK FOR COUNT = 1
	JR	Z,DRV_INIT5		; YES, SKIP AHEAD TO IMPLEMENT 8 HDSPV
	LD	E,4			; NOW ASSUME 4 SLICES PER VOLUME
	DEC	A			; DEC ACCUM TO CHECK FOR COUNT = 2
	JR	Z,DRV_INIT5		; YES, SKIP AHEAD TO IMPLEMENT 4 HDSPV
	LD	E,2			; IN ALL OTHER CASES, WE USE 2 HDSPV
;
DRV_INIT5:
	LD	A,E			; SLICES PER VOLUME VALUE TO ACCUM
	LD	(HDSPV),A		; SAVE IT
	LD	DE,(BOOTVOL)		; BOOT VOLUME (UNIT, SLICE)
	LD	B,1			; JUST ONE SLICE PLEASE
	CALL	DRV_INIT8A		; DO THE BOOT UNIT & SLICE FIRST
;
DRV_INIT5A:
	LD	A,(DRVLSTC)		; ACTIVE DRIVE LIST COUNT TO ACCUM
	LD	B,A			; ... AND MOVE TO B FOR LOOP COUNTER
	LD	HL,DRVLST		; HL IS PTR TO ACTIVE DRIVE LIST
;
DRV_INIT6:	; LOOP THRU ALL UNITS AVAILABLE
	PUSH	HL			; PRESERVE DRIVE LIST PTR
	LD	C,(HL)			; GET UNIT NUM FROM LIST
	PUSH	BC			; PRESERVE LOOP CONTROL
	LD	B,BF_DIODEVICE		; HBIOS FUNC: REPORT DEVICE INFO
	RST	08			; CALL HBIOS, D := DEVICE TYPE
	POP	BC			; GET UNIT INDEX BACK IN C
	PUSH	BC			; RESAVE LOOP CONTROL
	CALL	DRV_INIT7		; MAKE DRIVE MAP ENTRY(S)
	POP	BC			; RESTORE LOOP CONTROL
	INC	C			; INCREMENT LIST INDEX
	POP	HL			; RESTORE DRIVE LIST PTR
	INC	HL			; INCREMENT ACTIVE DRIVE LIST PTR
	DJNZ	DRV_INIT6		; LOOP AS NEEDED
	RET				; FINISHED
;
DRV_INIT7:	; PROCESS UNIT
	LD	E,0			; INITIALIZE SLICE INDEX
	LD	B,1			; DEFAULT LOOP COUNTER
	LD	A,D			; DEVICE TYPE TO ACCUM
	LD	D,C			; UNIT NUMBER TO D
	CP	DIODEV_IDE		; HARD DISK DEVICE?
	JR	C,DRV_INIT8		; NOPE, LEAVE LOOP COUNT AT 1
	LD	A,(HDSPV)		; GET SLICES PER VOLUME TO ACCUM
	LD	B,A			; MOVE TO B FOR LOOP COUNTER
;
DRV_INIT8:
	; SLICE CREATION LOOP
	; DE=UNIT/SLICE, B=SLICE CNT
;
	; FIRST, CHECK TO SEE IF THIS IS THE BOOT VOL & SLICE.
	; IF SO, IT HAS ALREADY BEEN PROCESSED ABOVE, SO SKIP IT HERE.
	LD	A,(BOOTVOL + 1)		; GET BOOT UNIT
	CP	D			; COMPARE TO CUR UNIT
	JR	NZ,DRV_INIT8A		; IF NE, OK TO CONTINUE
	LD	A,(BOOTVOL)		; GET BOOT SLICE
	CP	E			; COMPARE TO CUR SLICE
	JR	NZ,DRV_INIT8A		; IF NE, OK TO CONTINUE
	INC	E			; IS BOOT DU/SLICE, SKIP IT
	DJNZ	DRV_INIT8		; LOOP AS NEEDED
	RET				; DONE
;
DRV_INIT8A:	; ENTRY POINT TO SKIP BOOT DISK/LU CHECK
;
	; INC DRVMAP ENTRY COUNT AND ENFORCE FOR 16 ENTRY MAXIMUM
	LD	HL,(DRVMAPADR)		; POINT TO DRIVE MAP
	DEC	HL			; BACKUP TO POINT TO ENTRY COUNT
	LD	A,(HL)			; CURRENT COUNT TO ACCUM
	CP	16			; AT MAX?
	RET	NC			; IF >= MAX, JUST BAIL OUT
	INC	(HL)			; INCREMENT THE ENTRY COUNT
;
	; ALLOCATE ENTRY AND FILL IN UNIT, SLICE
	LD	HL,4			; 4 BYTES PER ENTRY
	CALL	ALLOC			; ALLOCATE SPACE
	CALL	C,PANIC			; SHOULD NEVER ERROR HERE
	LD	(HL),D			; SAVE UNIT IN FIRST BYTE OF DRVMAP ENTRY
	INC	HL			; POINT TO NEXT BYTE OF DRVMAP ENTRY
	LD	(HL),E			; SAVE SLICE NUM IN SECOND BYTE OF DRVMAP ENTRY
;
	INC	E			; INCREMENT SLICE INDEX
	DJNZ	DRV_INIT8		; LOOP AS NEEDED
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
	CALL	NEWLINE2	; FORMATTING
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
	CALL	ADDHLA		; ...
	ADD	HL,HL		; ... OF DPH (20)
	ADD	HL,HL		; ... FOR TOTAL SIZE
	CALL	ALLOC		; ALLOCATE THE SPACE
	CALL	C,PANIC		; SHOULD NEVER ERROR
;
	; SET DPHTOP TO START OF ALLOCATED SPACE
	LD	(DPHTOP),HL	; ... AND SAVE IN DPHTOP
;
	; ALLOCATE DIRECTORY BUFFER
	LD	HL,128		; SIZE OF DIRECTORY BUFFER
	CALL	ALLOC		; ALLOCATE THE SPACE
	CALL	C,PANIC		; SHOULD NEVER ERROR
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
	LD	D,(HL)		; D := UNIT
	INC	HL		; BUMP
	LD	E,(HL)		; E := SLICE
	INC	HL		; BUMP
	CALL	PRTDRV		; PRINT DRIVE INFO
	LD	A,D		; A := UNIT
	PUSH	HL		; SAVE DRIVE MAP POINTER
DPH_INIT1A:
	LD	DE,(DPHTOP)	; GET ADDRESS OF NEXT DPH
	PUSH	DE		; ... AND SAVE IT
	; INVOKE THE DPH BUILD ROUTINE
	PUSH	BC		; SAVE LOOP CONTROL
	CALL	MAKDPH		; MAKE THE DPH AT DE, UNIT IN A
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
	;LD	A,16		; SIZE OF A DPH ENTRY
	LD	A,20		; SIZE OF A DPH ENTRY
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
; MAKE A DPH AT ADDRESS IN DE FOR UNIT IN A
;
	PUSH	DE		; SAVE INCOMING DPH ADDRESS
;
#IFDEF PLTUNA
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
	LD	DE,INIBUF	; 512 BYTE BUFFER
	CALL	$FFFD		; CALL UNA
	BIT	7,B		; TEST RAM DRIVE BIT
	LD	DE,DPB_ROM	; ASSUME ROM
	JR	Z,MAKDPH1	; NOT SET, ROM DRIVE, CONTINUE
	LD	DE,DPB_RAM	; OTHERWISE, MUST BE RAM DRIVE
	JR	MAKDPH1		; CONTINUE
;
#ELSE
;
	; DETERMINE APPROPRIATE DPB (UNIT NUMBER IN A)
	; GET DEVICE INFO
	LD	C,A		; UNIT NUMBER TO C
	LD	B,BF_DIODEVICE	; HBIOS FUNC: REPORT DEVICE INFO
	RST	08		; CALL HBIOS, RET W/ DEVICE TYPE IN D, PHYSICAL UNIT IN E
	LD	A,D		; DEVICE TYPE TO A
	CP	DIODEV_MD	; RAM/ROM DISK?
	JR	Z,MAKDPH0	; HANDLE SPECIAL
	LD	DE,DPB_FD144	; PRELOAD FLOPPY DPB
	CP	DIODEV_FD	; FLOPPY?
	JR	Z,MAKDPH1	; IF SO, PROCEED TO DPH CREATION
	LD	DE,DPB_RF	; PRELOAD RAM FLOPPY DPB
	CP	DIODEV_RF	; RAM FLOPPY?
	JR	Z,MAKDPH1	; IF SO, PROCEED TO DPH CREATION
	; EVERYTHING ELSE IS A HARD DISK
	LD	DE,DPB_HD	; PRELOAD HARD DISK DPB
	JR	MAKDPH1		; PROCEED TO DPH CREATION
;
MAKDPH0:
	; RAM/ROM DISK DPB DERIVATION
	; TYPE OF MEMORY DISK (RAM/ROM) DETERMINED BY PHYSICAL UNIT NUMBER
	LD	A,E		; LOAD PHYSICAL UNIT NUMBER
	LD	DE,DPB_RAM	; PRELOAD RAM DISK DPB
	OR	A		; UNIT=0 (RAM)?
	JR	Z,MAKDPH1	; IF SO, CREATE RAM DISK DPH
	LD	DE,DPB_ROM	; PRELOAD ROM DISK DPB
	CP	$01		; UNIT=1 (ROM)?
	JR	Z,MAKDPH1	; IF SO, CREATE ROM DISK DPH
	CALL	PANIC		; OTHERWISE UNKNOWN, NOT POSSIBLE, JUST PANIC
;
#ENDIF
;
MAKDPH1:
;
	; BUILD THE DPH (DE POINTS TO DPB)
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
	; FALL THRU FOR ALS BUF
MAKDPH2:
	PUSH	HL		; SAVE DPH PTR
	EX	DE,HL		; USE HL AS DPB PTR, DE IS NOW SCRATCH
	LD	E,(HL)		; DE := CKS/ALS SIZE
	INC	HL		; ... AND BUMP
	LD	D,(HL)		; ... PAST
	INC	HL		; ... CKS/ALS SIZE
	EX	DE,HL		; DPB PTR BACK TO DE, ALLOC SIZE TO HL
	LD	A,H		; CHECK TO SEE
	OR	L		; ... IF HL (ALLOC SIZE) IS ZERO
	CALL	NZ,ALLOC	; ALLOC BC BYTES, ADDRESS RETURNED IN BC
	PUSH	HL		; MOVE ALLOC RESULT PTR
	POP	BC		; ... TO BC
	POP	HL		; RECOVER DPH PTR TO HL
	JR	C,ERR_HEAPOVF	; HANDLE POSSIBLE ALLOC OVERFLOW HERE
	LD	(HL),C		; SAVE CKS/ALS BUF
	INC	HL		; ... ADDRESS IN
	LD	(HL),B		; ... DPH AND BUMP
	INC	HL		; ... TO NEXT DPH ENTRY
	XOR	A		; SIGNAL SUCCESS
	RET
;
; ALLOCATE HL BYTES FROM HEAP
; RETURN POINTER TO ALLOCATED MEMORY IN HL
; ON OVERFLOW ERROR, C SET
;
ALLOC:
	PUSH	DE		; SAVE DE SO WE CAN USE IT FOR WORK REG
	LD	DE,(HEAPTOP)	; GET CURRENT HEAP TOP
	PUSH	DE		; AND SAVE FOR RETURN VALUE
	ADD	HL,DE		; ADD REQUESTED SPACE, HL := NEW HEAP TOP
	JR	C,ALLOCX	; TEST FOR CPU MEMORY SPACE OVERFLOW
	LD	DE,HEAPEND	; LOAD DE WITH HEAP LIMIT
	EX	DE,HL		; DE=NEW HEAPTOP, HL=HEAPLIM
	SBC	HL,DE		; HEAPLIM - HEAPTOP
	JR	C,ALLOCX	; C SET ON OVERFLOW ERROR
	; ALLOCATION SUCCEEDED, COMMIT NEW HEAPTOP
	LD	(HEAPTOP),DE	; SAVE NEW HEAPTOP
ALLOCX:
	POP	HL		; RETURN VALUE TO HL
	POP	DE		; RECOVER DE
	RET
;
ERR_HEAPOVF:
	LD	DE,STR_HEAPOVF
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
PRTDRV:
;
; PRINT THE UNIT/SLICE INFO
; ON INPUT D HAS UNIT, E HAS SLICE
; DESTROY NO REGISTERS OTHER THAN A
;
#IFDEF PLTUNA
;
	PUSH	BC		; PRESERVE BC
	PUSH	DE		; PRESERVE DE
	PUSH	HL		; PRESERVE HL

	LD	B,D		; B := UNIT
	LD	C,$48		; UNA FUNC: GET DISK TYPE
	CALL	$FFFD		; CALL UNA
	LD	A,D		; DISK TYPE TO A

	CP	$40
	JR	Z,PRTDRV1	; IF SO, HANDLE RAM/ROM

	LD	DE,DEVIDE	; IDE STRING
	CP	$41		; IDE?
	JR	Z,PRTDRVX	; IF YES, PRINT
	LD	DE,DEVPPIDE	; PPIDE STRING
	CP	$42		; PPIDE?
	JR	Z,PRTDRVX	; IF YES, PRINT
	LD	DE,DEVSD	; SD STRING
	CP	$43		; SD?
	JR	Z,PRTDRVX	; IF YES, PRINT
	LD	DE,DEVDSD	; DSD STRING
	CP	$44		; DSD?
	JR	Z,PRTDRVX	; IF YES, PRINT

	LD	DE,DEVUNK	; OTHERWISE, UNKNOWN
	JR	PRTDRVX		; PRINT IT

PRTDRV1:
	LD	C,$45		; UNA FUNC: GET DISK INFO
	LD	DE,INIBUF	; 512 BYTE BUFFER
	CALL	$FFFD		; CALL UNA
	BIT	7,B		; TEST RAM DRIVE BIT
	LD	DE,DEVROM	; ASSUME ROM
	JR	Z,PRTDRVX	; IF SO, DISPLAY ROM
	LD	DE,DEVRAM	; ELSE RAM
	JR	Z,PRTDRVX	; DO IT

PRTDRVX:
	CALL	WRITESTR	; PRINT DEVICE NAME
	POP	HL		; RECOVER HL
	POP	DE		; RECOVER DE
	POP	BC		; RECOVER BC
	LD	A,D		; LOAD UNIT
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
	PUSH	BC		; PRESERVE BC
	PUSH	DE		; PRESERVE DE
	PUSH	HL		; PRESERVE HL
	LD	B,BF_DIODEVICE	; HBIOS FUNC: REPORT DEVICE INFO
	LD	C,D		; UNIT TO C
	RST	08		; CALL HBIOS
	LD	A,D		; RESULTANT DEVICE TYPE
	PUSH	DE		; NEED TO SAVE UNIT NUMBER (IN E)
	RRCA			; ROTATE DEVICE
	RRCA			; ... BITS
	RRCA			; ... INTO
	RRCA			; ... LOWEST 4 BITS
	AND	$0F		; ISOLATE DEVICE BITS
	ADD	A,A		; MULTIPLY BY TWO FOR WORD TABLE
	LD	HL,DEVTBL	; POINT TO START OF DEVICE NAME TABLE
	CALL	ADDHLA		; ADD A TO HL TO POINT TO TABLE ENTRY
	LD	A,(HL)		; DEREFERENCE HL TO LOC OF DEVICE NAME STRING
	INC	HL		; ...
	LD	D,(HL)		; ...
	LD	E,A		; ...
	CALL	WRITESTR	; PRINT THE DEVICE NMEMONIC
	POP	DE		; RECOVER UNIT (IN E)
	LD	A,E		; LOAD UNIT
	AND	$0F		; ISOLATE UNIT
	CALL	PRTDECB		; PRINT IT
	POP	HL		; RECOVER HL
	POP	DE		; RECOVER DE
	POP	BC		; RECOVER BC
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
DPHTOP	.DW	0			; CURRENT TOP OF DPH POOL
DIRBUF	.DW	0			; DIR BUF POINTER
HEAPTOP	.DW	BUFPOOL			; CURRENT TOP OF HEAP
BOOTVOL	.DW	0			; BOOT VOLUME, MSB=BOOT UNIT, LSB=BOOT SLICE
HDSPV	.DB	2			; SLICES PER VOLUME FOR HARD DISKS (MUST BE >= 1)
DRVLST	.FILL	32			; ACTIVE DRIVE LIST USED DURINT DRV_INIT
DRVLSTC	.DB	0			; ENTRY COUNT FOR ACTIVE DRIVE LIST
;
#IFDEF PLTWBW
BNKRAMD	.DB	0			; STARTING BANK ID FOR RAM DRIVE (WBW)
#ENDIF
#IFDEF PLTUNA
BNKRAMD	.DW	0			; STARTING BANK ID FOR RAM DRIVE (UNA)
#ENDIF
;
CMD	.DB	CMDLEN - 2
	.TEXT	"SUBMIT PROFILE"
	.DB	0
CMDLEN	.EQU	$ - CMD
;
FCB_SUB	.DB	'?'			; DRIVE CODE, 0 = CURRENT DRIVE
	.DB	"SUBMIT  "		; FILE NAME, 8 CHARS
	.DB	"COM"			; FILE TYPE, 3 CHARS
	.FILL	36-($-FCB_SUB),0	; ZERO FILL REMAINDER OF FCB
;
FCB_PRO	.DB	'?'			; DRIVE CODE, 0 = CURRENT DRIVE
	.DB	"PROFILE "		; FILE NAME, 8 CHARS
	.DB	"SUB"			; FILE TYPE, 3 CHARS
	.FILL	36-($-FCB_PRO),0	; ZERO FILL REMAINDER OF FCB
;
STR_BANNER	.DB	"CBIOS v", BIOSVER, " [", PLTSTR, "]$"
STR_INITRAMDISK	.DB	"Formatting RAMDISK...$"
STR_LDR2	.DB	"\r\n"
STR_LDR		.DB	"\r\n	$"
STR_DPHINIT	.DB	"Configuring Drives...$"
STR_HEAPOVF	.DB	" *** Insufficient Memory ***$"
STR_INVMED	.DB	" *** Invalid Device ID ***$"
STR_VERMIS	.DB	7,"*** WARNING: HBIOS/CBIOS Version Mismatch ***$"
STR_MEMFREE	.DB	" Disk Buffer Bytes Free$"
STR_CPM		.DB	"CP/M-80 v2.2$"
STR_ZSDOS	.DB	"ZSDOS v1.1$"
STR_TPA1	.DB	", $"
STR_TPA2	.DB	"K TPA$"
STR_BIOMEM	.DB	"*** HBIOS Heap Overflow ***$"

#IFDEF PLTUNA
INIBUF	.FILL	512,0			; LOCATION OF TEMP WORK BUF DURING INIT (512 BYTES)
#ELSE
HCB	.FILL	HCB_SIZ,0		; LOCATION OF TEMP COPY OF HCB DURING INIT (256 BYTES)
#ENDIF
;
;==================================================================================================
; END OF COLD BOOT INITIALIZATION
;==================================================================================================
;
	.ORG	BUFPOOL + ($ - $8000)
;
SLACK	.EQU	(CBIOS_END - $)
	.ECHO	"INIT code slack space: "
	.ECHO	SLACK
	.ECHO	" bytes.\n"
	.FILL	SLACK,$00
;
HEAPS	.EQU	(CBIOS_END - BUFPOOL)
	.ECHO	"HEAP space: "
	.ECHO	HEAPS
	.ECHO	" bytes.\n"
;
	.ECHO	"CBIOS total space used: "
	.ECHO	$ - CBIOS_LOC
	.ECHO	" bytes.\n"
;
	; PAD OUT AREA RESERVED FOR HBIOS PROXY
	.FILL	MEMTOP - $
;
	.END
