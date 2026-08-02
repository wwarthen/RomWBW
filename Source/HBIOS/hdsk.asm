;
;==================================================================================================
;   HDSK DISK DRIVER
;==================================================================================================
;
; SIMH HDSK DEVICE INTERFACE DOCUMENTATION IS AT THE END OF THIS FILE.
;
; IO PORT ADDRESSES
;
HDSK_IOBASE	.EQU	$FD
;
; COMMAND VALUES
;
HDSK_CMD_NONE	.EQU	0
HDSK_CMD_RESET	.EQU	1
HDSK_CMD_READ	.EQU	2
HDSK_CMD_WRITE	.EQU	3
HDSK_CMD_PARAM	.EQU	4
;
; STATUS VALUES
;
HDSK_STOK	.EQU	0		; OK
HDSK_STNOTRDY	.EQU	-1		; NOT READY
;
; HDSK DEVICE CONFIGURATION
;
; PER DEVICE DATA OFFSETS IN CFG BLOCK
; BYTES 0-15 ARE STANDARD (SEE HBIOS.INC DRIVER CONFIG BLOCK STANDARD OFFSETS)
;
HDSK_CFG_IOBASE	.EQU	16		; IO BASE ADDRESS (BYTE)
;
HDSK_DEVCNT	.EQU	2		; NUMBER OF HDSK DEVICES SUPPORTED
HDSK_CFGSIZ	.EQU	17		; SIZE OF CFG TBL ENTRIES
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE HEADER
;--------------------------------------------------------------------------------------------------
;
ORG_HDSK	.EQU	$
;
	.DW	SIZ_HDSK		; MODULE SIZE
	.DW	HDSK_INITPHASE		; ADR OF INIT PHASE HANDLER
;
HDSK_INITPHASE:
	; INIT PHASE HANDLER, A=PHASE
	;CP	HB_PHASE_PREINIT	; PREINIT PHASE?
	;JP	Z,HDSK_PREINIT		; DO PREINIT
	CP	HB_PHASE_INIT		; INIT PHASE?
	JP	Z,HDSK_INIT		; DO INIT
	RET				; DONE
;
; HDSK DEVICE CONFIG BLOCKS
;
; NOTE THAT DISK CAPACITY/GEOMETRY IS HARD CODED HERE TO
; A 1GB LBA HARD DISK:
;   - CAPACITY = 1GB = 2,097,152 SECTORS = $200000 SECTORS
;
HDSK_CFGTBL:
;
#IF (HDSK_DEVCNT >= 1)
HDSK0_CFG:
	.DW	HDSK_FNTBL		; DRIVER FUNCTION TABLE ADDRESS
	.DB	'D'			; DRIVER TYPE
	.DB	0			; HBIOS UNIT NUMBER (FILLED DYNAMICALLY)
	.DB	0			; DRIVER UNIT NUMBER
	.DB	ERR_NOTRDY		; DEVICE STATUS (HBIOS STATUS)
	.DW	HDSK_STR_TAG		; DRIVER TAG STRING PTR
	.DW	0,0			; CURRENT DISK ADDRESS (LBA)
	.DW	0,$20			; DEVICE CAPACITY = $200000, LSW:MSW
	.DB	HDSK_IOBASE		; IO BASE ADDRESS
;
	DEVECHO	"HDSK: IO="
	DEVECHO	HDSK_IOBASE
	DEVECHO	"\n"
#ENDIF
;
#IF (HDSK_DEVCNT >= 2)
HDSK1_CFG:
	.DW	HDSK_FNTBL		; DRIVER FUNCTION TABLE ADDRESS
	.DB	'D'			; DRIVER TYPE
	.DB	0			; HBIOS UNIT NUMBER (FILLED DYNAMICALLY)
	.DB	1			; DRIVER UNIT NUMBER
	.DB	ERR_NOTRDY		; DEVICE STATUS (HBIOS STATUS)
	.DW	HDSK_STR_TAG		; DRIVER TAG STRING PTR
	.DW	0,0			; CURRENT DISK ADDRESS (LBA)
	.DW	0,$20			; DEVICE CAPACITY = $200000, LSW:MSW
	.DB	HDSK_IOBASE		; IO BASE ADDRESS
;
	DEVECHO	"HDSK: IO="
	DEVECHO	HDSK_IOBASE
	DEVECHO	"\n"
#ENDIF
;
#IF ($ - HDSK_CFGTBL) != (HDSK_DEVCNT * HDSK_CFGSIZ)
	.ECHO	"*** INVALID HDSK CONFIG TABLE ***\n"
	!!!	; FORCE AN ASSEMBLY ERROR
#ENDIF
;
	.DB	$FF			; END OF TABLE MARKER
;
;=============================================================================
; INITIALIZATION ENTRY POINT
;=============================================================================
;
HDSK_INIT:
	LD	IY,HDSK_CFGTBL		; POINT TO START OF CONFIG TABLE
;
HDSK_INIT1:
	LD	A,(IY)			; LOAD FIRST BYTE TO CHECK FOR END
	CP	$FF			; CHECK FOR END OF TABLE VALUE
	RET	Z			; RETURN IF DONE
;
	CALL	HDSK_INIT2		; REGISTER & INIT DEVICE
;
	LD	DE,HDSK_CFGSIZ		; SIZE OF CFG TABLE ENTRY
	ADD	IY,DE			; BUMP POINTER
	JP	HDSK_INIT1		; AND LOOP
;
HDSK_INIT2:
	; ADD UNIT TO GLOBAL DISK UNIT TABLE
	LD	BC,HDSK_FNTBL		; BC := FUNC TABLE ADR
	PUSH	IY			; CFG ENTRY POINTER
	POP	DE			; COPY TO DE
	CALL	DIO_ADDENT		; ADD ENTRY TO GLOBAL DISK DEV TABLE
	LD	(IY+CFG_UNIT),A		; RECORD HBIOS UNIT NUMBER ASSIGNED
;
	CALL	HDSK_INITDEV		; INITIALIZE DEVICE
	PUSH	AF			; SAVE INIT STATUS
;
	CALL	DRV_PRTTAG		; TAG FOR ACTIVE DEVICE
	PRTS(" IO=0x$")			; LABEL FOR IO ADDRESS
	LD	A,(IY+HDSK_CFG_IOBASE)	; GET IO BASE ADDRES
	CALL	PRTHEXBYTE		; DISPLAY IT
;
	POP	AF			; RECOVER INIT STATUS
	JR	Z,SCSI_INIT3		; IF Z, CONTINUE
	JP	ERR_PRT_SP		; ELSE ERROR TEXT AND ABORT
;
SCSI_INIT3:
	; PRINT STORAGE CAPACITY (BLOCK COUNT)
	PRTS(" BLOCKS=0x$")		; PRINT FIELD LABEL
	LD	A,CFG_DSKCAP		; OFFSET TO CAPACITY FIELD
	CALL	LDHLIYA			; HL := IY + A, REG A TRASHED
	CALL	LD32			; GET THE CAPACITY VALUE
	CALL	PRTHEX32		; PRINT HEX VALUE
;
	; PRINT STORAGE SIZE IN MB
	PRTS(" SIZE=$")			; PRINT FIELD LABEL
	LD	B,11			; 11 BIT SHIFT TO CONVERT BLOCKS --> MB
	CALL	SRL32			; RIGHT SHIFT
	CALL	PRTDEC32		; PRINT DWORD IN DECIMAL
	PRTS("MB$")			; PRINT SUFFIX
;
	XOR	A			; SUCCESS
	RET
;
;=============================================================================
; DRIVER FUNCTION TABLE
;=============================================================================
;
HDSK_FNTBL:
	.DW	HDSK_STATUS
	.DW	HDSK_RESET
	.DW	HDSK_SEEK
	.DW	HDSK_READ
	.DW	HDSK_WRITE
	.DW	HDSK_VERIFY
	.DW	HDSK_FORMAT
	.DW	HDSK_DEVICE
	.DW	HDSK_MEDIA
	.DW	HDSK_DEFMED
	.DW	HDSK_CAP
	.DW	HDSK_GEOM
#IF (($ - HDSK_FNTBL) != (DIO_FNCNT * 2))
	.ECHO	"*** INVALID HDSK FUNCTION TABLE ***\n"
#ENDIF
;
;
;
HDSK_VERIFY:
HDSK_FORMAT:
HDSK_DEFMED:
	SYSCHKERR(ERR_NOTIMPL)		; NOT IMPLEMENTED
	RET
;
;
;
HDSK_READ:
	CALL	HB_DSKREAD_NEW		; HOOK HBIOS DISK READ SUPERVISOR
	LD	E,HDSK_CMD_READ
	JP	HDSK_IO
;
;
;
HDSK_WRITE:
	CALL	HB_DSKWRITE_NEW		; HOOK HBIOS DISK WRITE SUPERVISOR
	LD	E,HDSK_CMD_WRITE
	JP	HDSK_IO
;
;
;
HDSK_STATUS:
	LD	A,(IY+CFG_STATUS)	; GET STATUS OF SELECTED DEVICE
	OR	A			; SET FLAGS
	RET				; AND RETURN
;
;
;
HDSK_RESET:
	JP	HDSK_INITDEV		; REINITIALIZE UNIT AND RETURN
;
;
;
HDSK_DEVICE:
	LD	D,DIODEV_HDSK		; D := DEVICE TYPE
	LD	E,(IY+CFG_DEVNUM)	; E := PHYSICAL DEVICE NUMBER
	LD	C,%00110000		; C := ATTRIBUTES, NON-REMOVABLE HARD DISK
	LD	H,0			; H := 0, DRIVER HAS NO MODES
	LD	L,(IY+HDSK_CFG_IOBASE)	; L := BASE I/O ADDRESS
	XOR	A			; SIGNAL SUCCESS
	RET
;
;
;
HDSK_MEDIA:
	; CHECK IF MEDIA DISCOVERY REQUESTED
	BIT	0,E			; IF BIT 0 OF E, CHECK MEDIA
	LD	D,0			; SIGNAL NO MEDIA CHANGE
	JR	Z,HDSK_MEDIA_Z		; IF NOT SET, REPORT CURRENT INFO
;
	; CHECK CURRENT DEVICE STATUS
	LD	A,(IY+CFG_STATUS)	; GET OUR CURRENT STATUS
	OR	A			; SET FLAGS
	JR	NZ,HDSK_MEDIA1		; IF NOT OK, FORCE INITDEV
;
	; IN THEORY, HERE, WE SHOULD CONFIRM DEVICE IS ACCESSIBLE,
	; BUT NOT MUCH WE CAN DO WITH EMULATED HARD DISK
	JR	HDSK_MEDIA_Z		; IF OK, GOOD EXIT
;
HDSK_MEDIA1:
	; ATTEMPT TO RECOVER FROM ERROR STATE USING INITDEV
	; CURRENT STATUS WILL BE SET/CLEARED BY INITDEV
	CALL	HDSK_INITDEV		; PERFORM INIT
	LD	D,1			; SIGNAL MEDIA CHANGE
	; AND FALL THRU
;
HDSK_MEDIA_Z:
	LD	A,(IY+CFG_STATUS)	; GET CURRENT STATUS
	OR	A			; SET FLAGS
	LD	E,MID_HD		; ASSUME HARD DISK MEDIA
	RET	Z			; RETURN IF GOOD
	LD	E,MID_NONE		; ELSE SIGNAL NO MEDIA
	RET				; AND RETURN ERROR
;
;
;
HDSK_SEEK:
	JP	HB_DSKSEEKLBA		; USE GENERIC LBA SEEK ROUTINE
;
; GET DISK CAPACITY
;
HDSK_CAP:
	JP	HB_DSKCAP		; USE GENERIC CAPACITY ROUTINE
;
; GET DISK GEOMETRY
;
HDSK_GEOM:
	JP	HB_DSKGEOMLBA		; USE GENERIC LBA GEOMETRY ROUTINE
;
;=============================================================================
; FUNCTION SUPPORT ROUTINES
;=============================================================================
;
;
; ON RETURN, ZF SET INDICATES HARDWARE FOUND
;
HDSK_DETECT:
	XOR	A			; SIGNAL SUCCESS
	RET				; AND DONE
;
; INITIALIZE OR REINITIALIZE DEVICE
; RETURN HBIOS RESULT CODE
;
HDSK_INITDEV:
	CALL	HDSK_RES		; JUST RESET THE INTERFACE
	JP	NZ,HDSK_ERR		; HANDLE ERROR
;
	; SUCCESS, SET GOOD STATUS
	XOR	A			; ASSUME STATUS = OK
	LD	(IY+CFG_STATUS),A	; SAVE IT
	RET
;
; PERFORM SECTOR READ/WRITE
; ON ENTRY, E=HDSK R/W CMD, HL=DATA BUFFER
; RETURN HBIOS RESULT CODE
;
HDSK_IO:
	CALL	HDSK_RW			; DO THE READ/WRITE
	JP	NZ,HDSK_ERR		; HANDLE ERROR AND RETURN
;
	CALL	HB_DSKINCLBA		; INCREMENT LBA
;
	XOR	A			; SIGNAL SUCCESS
	RET				; DONE
;
;=============================================================================
; HARDWARE INTERFACE ROUTINES
;=============================================================================
;
; RESET THE HDSK INTERFACE
; RETURNS AN HDSK RETURN CODE
; HDSK PROVIDES NO RETURN CODE FOR RESET, ASSUME SUCCESS
;
HDSK_RES:
;
#IF (HDSKTRACE >= 2)
	CALL	DRV_PRTTAG
	PRTS(" RESET$")
#ENDIF
;
	LD	B,32			; REPEAT 32 TIMES
	LD	A,HDSK_CMD_RESET	; RESET COMMAND
	LD	(HDSK_CMD),A		; FOR ERROR/DIAGNOSTIC LOGGING
HDSK_INITDEV1:
	OUT	(HDSK_IOBASE),A		; SEND CMD
	DJNZ	HDSK_INITDEV1		; LOOP AS NEEDED
;
	XOR	A			; ASSUME SUCCESS
	RET				; DONE
;
; ISSUE HDSK READ/WRITE COMMAND
; ON INPUT, E HAS SCSI R/W COMMAND, HL POINTS TO DATA BUFFER
; RETURNS HDSK STATUS CODE
;
HDSK_RW:
	; SETUP HDSK COMMAND BLOCK
	LD	A,E			; COMMAND BYTE TO ACCUM
	LD	(HDSK_CMD),A		; SET COMMAND BYTE
	LD	(HDSK_DMA),HL		; SAVE INITIAL DMA
	LD	A,(IY+CFG_DEVNUM)	; GET DEVICE NUMBER
	LD	(HDSK_DRV),A		; ... AND SET FIELD IN HDSK PARM BLOCK
;
	; CONVERT LBA HHHH:LLLL (4 BYTES)
	; TO HDSK TRACK/SECTOR TTTT:SS (3 BYTES)
	; SAVING TO HDSK PARM BLOCK
	; (IY+CFG_DSKADR+0) ==> (HDSK_SEC)
	LD	A,(IY+CFG_DSKADR+0)
	LD	(HDSK_SEC),A
	; (IY+CFG_DSKADR+1) ==> (HDSK_TRK+0)
	LD	A,(IY+CFG_DSKADR+1)
	LD	(HDSK_TRK+0),A
	; (IY+CFG_DSKADR+2) ==> (HDSK_TRK+1)
	LD	A,(IY+CFG_DSKADR+2)
	LD	(HDSK_TRK+1),A
;
	; EXECUTE COMMAND
	LD	B,7			; SIZE OF PARAMETER BLOCK
	LD	HL,HDSK_PARMBLK		; ADDRESS OF PARAMETER BLOCK
	LD	C,HDSK_IOBASE		; HDSK CMD PORT
	OTIR				; SEND IT
;
	; GET RESULT
	IN	A,(C)			; GET RESULT CODE
	LD	(HDSK_RC),A		; SAVE IT
	OR	A			; SET FLAGS
;
#IF (HDSKTRACE >= 2)
	PUSH	AF
	CALL	HDSK_DUMPCMD
	POP	AF
#ENDIF
	RET
;
;=============================================================================
; ERROR HANDLING AND DIAGNOSTICS
;=============================================================================
;
; EVALUATE HDSK STATUS BYTE, SET HBIOS ERROR
; HDSK ONLY HAS TWO RETURN CODES: 0=SUCCESS, 1=FAILURE
; WE MAP ANY FAILURE TO HBIOS IO ERROR
;
HDSK_ERR:
#IF (HDSKTRACE == 1)
	CALL	HDSK_DUMPCMD		; DISPLAY COMMAND
#ENDIF
	LD	A,ERR_IO		; HBIOS ERR TO ACCUM
	LD	(IY+CFG_STATUS),A	; SET PERSISTENT STATUS
	OR	A			; SET FLAGS
	RET				; AND RETURN
;
;
;
HDSK_DUMPCMD:
	CALL	DRV_PRTTAG
;	
	; COMMAND BYTE
	PRTS(" CMD=$")
	LD	A,(HDSK_CMD)
	CALL	PRTHEXBYTE
;
	; COMMAND STRING
	CALL	PC_SPACE
	CALL	PC_LBKT
	LD	A,(HDSK_CMD)
	LD	HL,HDSK_CMD_STR_TBL
	CALL	PRTLKUP
	CALL	PC_RBKT
;
	; IF READ OR WRITE, PRINT PARAMS AND RETURN CODE
	LD	A,(HDSK_CMD)
	CP	HDSK_CMD_READ
	JR	Z,HDSK_DUMP_RW
	CP	HDSK_CMD_WRITE
	JR	Z,HDSK_DUMP_RW
	RET
;
HDSK_DUMP_RW:
	; DRIVE NUM
	CALL	PC_SPACE
	LD	A,(HDSK_DRV)
	CALL	PRTHEXBYTE
;
	; TRACK
	CALL	PC_SPACE
	LD	BC,(HDSK_TRK)
	CALL	PRTHEXWORD
;
	; SECTOR
	CALL	PC_SPACE
	LD	A,(HDSK_SEC)
	CALL	PRTHEXBYTE
;
	; DMA
	CALL	PC_SPACE
	LD	BC,(HDSK_DMA)
	CALL	PRTHEXWORD
;
	; RETURN CODE
	PRTS(" ==> RC=$$")
	LD	A,(HDSK_RC)
	CALL	PRTHEXBYTE
;
	; RETURN CODE TEXT
	CALL	PC_SPACE
	CALL	PC_LBKT
	LD	A,(HDSK_RC)
	LD	DE,HDSK_STR_STOK
	CP	HDSK_STOK
	JP	Z,HDSK_DUMP_RW_Z
	LD	DE,HDSK_STR_STIOERR
;
HDSK_DUMP_RW_Z:
	CALL	WRITESTR
	CALL	PC_RBKT
	RET
;
;
;
;=============================================================================
; STRING DATA
;=============================================================================
;
HDSK_STR_TAG		.TEXT	"HDSK$"
;
HDSK_CMD_STR_TBL:
	.DW	HDSK_STR_CMD_NONE
	.DW	HDSK_STR_CMD_RESET
	.DW	HDSK_STR_CMD_READ
	.DW	HDSK_STR_CMD_WRITE
	.DW	HDSK_STR_CMD_PARAM
;
HDSK_STR_CMD_NONE	.TEXT	"NONE$"
HDSK_STR_CMD_RESET	.TEXT	"RESET$"
HDSK_STR_CMD_READ	.TEXT	"READ$"
HDSK_STR_CMD_WRITE	.TEXT	"WRITE$"
HDSK_STR_CMD_PARAM	.TEXT	"PARAM$"
;
HDSK_STR_STOK		.TEXT	"OK$"
HDSK_STR_STIOERR	.TEXT	"UNKNOWN ERROR$"
;
;==================================================================================================
;   HDSK DISK DRIVER - DATA
;==================================================================================================
;
HDSK_PARMBLK:
HDSK_CMD	.DB	0		; COMMAND (HDSK_READ, HDSK_WRITE, ...)
HDSK_DRV	.DB	0		; 0..7, HDSK DRIVE NUMBER
HDSK_SEC	.DB	0		; 0..255 SECTOR
HDSK_TRK	.DW	0		; 0..2047 TRACK
HDSK_DMA	.DW	0		; ADDRESS FOR SECTOR DATA EXCHANGE
;
HDSK_RC		.DB	0		; CURRENT RETURN CODE
;
;--------------------------------------------------------------------------------------------------
;   HBIOS MODULE TRAILER
;--------------------------------------------------------------------------------------------------
;
END_HDSK	.EQU	$
SIZ_HDSK	.EQU	END_HDSK - ORG_HDSK
;	
	MEMECHO	"HDSK occupies "
	MEMECHO	SIZ_HDSK
	MEMECHO	" bytes.\n"
;
;--------------------------------------------------------------------------------------------------
;   HDSK INTERFACE DOCUMENTATION
;--------------------------------------------------------------------------------------------------
;
; THIS IS DIRECTLY USURPED FROM THE SIMH PROJECT.  SEE
; https://github.com/open-simh/simh/blob/master/AltairZ80/altairz80_hdsk.c
;
; The hard disk port is 0xfd. It understands the following commands.
;
;    1.  Reset
;        ld  b,32
;        ld  a,HDSK_RESET
;    l:  out (0fdh),a
;        dec b
;        jp  nz,l
;
;    2.  Read / write
;        ; parameter block
;        cmd:        db  HDSK_READ or HDSK_WRITE
;        hd:         db  0   ; 0 .. 7, defines hard disk to be used
;        sector:     db  0   ; 0 .. 31, defines sector
;        track:      dw  0   ; 0 .. 2047, defines track
;        dma:        dw  0   ; defines where result is placed in memory
;
;        ; routine to execute
;        ld  b,7             ; size of parameter block
;        ld  hl,cmd          ; start address of parameter block
;    l:  ld  a,(hl)          ; get byte of parameter block
;        out (0fdh),a        ; send it to port
;        inc hl              ; point to next byte
;        dec b               ; decrement counter
;        jp  nz,l            ; again, if not done
;        in  a,(0fdh)        ; get result code
;
;    3.  Retrieve Disk Parameters from controller (Howard M. Harte)
;        Reads a 19-byte parameter block from the disk controller.
;        This parameter block is in CP/M DPB format for the first 17 bytes,
;        and the last two bytes are the lsb/msb of the disk's physical
;        sector size.
;
;        ; routine to execute
;        ld   a,hdskParam    ; hdskParam = 4
;        out  (hdskPort),a   ; Send 'get parameters' command, hdskPort = 0fdh
;        ld   a,(diskno)
;        out  (hdskPort),a   ; Send selected HDSK number
;        ld   b,17
;    1:  in   a,(hdskPort)   ; Read 17-bytes of DPB
;        ld   (hl), a
;        inc  hl
;        djnz 1
;        in   a,(hdskPort)   ; Read LSB of disk's physical sector size.
;        ld   (hsecsiz), a
;        in   a,(hdskPort)   ; Read MSB of disk's physical sector size.
;        ld   (hsecsiz+1), a
