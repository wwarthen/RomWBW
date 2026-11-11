; RZ.COM  --  X/Y/ZMODEM receive program for RomWBW CP/M (rz v1.04)
; Based on the CP/M 3 RZ.COM v1.04 (W. Schmitten 1992), from a disassembly
; of the original Z80 binary (see rz_orig.asm).  Source is in TASM syntax.
;
; Modem is on an HBIOS character unit.  Option letters: ? P R X Y Z, digits
; 0-9 selects the transfer port, and B is accepted but ignored.
;
; Tables: key bytes searched with CPIR, then N vectors in REVERSE key
; order, jumped to via the dispatch routine.
;
; Labels are descriptive; patched operand bytes are named with
; .equ <label>+n.
;
; Comments were cross-checked against an independent disassembly of the
; same binaries, the ZMODEM specification and the rz.c / sz.c sources.
;
; ----------------------------------------------------------------------
; Changes from the original (rz_orig.asm)
; ----------------------------------------------------------------------
;
; RomWBW HBIOS support:
; - Serial I/O uses HBIOS character units via FastPath (SYSGET CIOFN +
;   HB_BNKCALL) instead of the CP/M AUX device (BDOS 3/4/7/8).
; - Transfer port selectable with a digit option (0-9); default is the
;   console unit.  When the transfer runs on the console unit, console
;   output (position, spinner, errors) and the ESC check are suppressed.
; - CP/M 3 no longer required: removed the BDOS version check and the
;   SCB console redirection; only CP/M 2.2 BDOS functions are used.
; - Stack placed at the top of the TPA, with the HBIOS block I/O buffers
;   just below it (common RAM); XMODEM requires a file name.
;
; Performance:
; - Receive uses HBIOS block input (BF_CIOBLKIN) into a 256-byte buffer
;   just below the stack, falling back to byte mode calls on an HBIOS
;   without it.  aux_poll_input does at most one refill per call so it
;   cannot get stuck chasing a streaming sender.
; - Output uses HBIOS block output (BF_CIOBLKOUT): bytes are queued in a
;   256-byte transmit buffer that is sent at the end of each hex header
;   or CAN string, when it fills, and before any wait for input.  Byte
;   mode calls are used on an HBIOS without it.
; - File writes go straight from the receive buffer, one BDOS write per
;   128-byte record, with no byte copying (write_buf_file).
; - Fast path in aux_getc_timeout reads waiting bytes without the
;   timeout and console-check overhead.
;
; Functionality:
; - Receive buffer is written early when less than EWTHRESH bytes are
;   free (EARLYWR), for senders that ignore the advertised buffer size
;   (e.g. lrzsz 0.12.20); previously the buffer overflowed and forced
;   a resend every buffer's worth of data.
; - F_CLOSE result handled correctly (0-3 = success); ZMODEM transfers
;   of multi-extent files no longer abort at the end.
; - Disk write errors are now detected and reported.
; - YMODEM: the empty block 0 that ends a batch no longer aborts.
; - Register use fixed so timeouts in B survive the receive routines.
;
; Other:
; - All transfers are binary: line-end conversion and -c removed; -b is
;   accepted but ignored.
; - Build settings CFG_BLKIO (default 1; 0 forces the byte mode receive
;   path), CFG_EARLYWR (default 1) and CFG_RXSTATS (default 0) can be
;   set on the TASM command line with -d<name>=<value>.  CFG_RXSTATS=1
;   prints receive, error, framing and timing statistics at the end of
;   a transfer.
;

; ----------------------------------------------------------------------
; Configuration defaults
; ----------------------------------------------------------------------
;
; The following settings can be overridden on the TASM command line with
; -d<name>=<value> (e.g. -dCFG_BLKIO=0).  A #DEFINE here does not replace
; a value given on the command line, so these are the defaults.  A
; misspelled name on the command line is silently ignored, so the
; effective values are printed during assembly (see below).

; BLKIO: 1 = use HBIOS block I/O (BF_CIOBLKIN/BF_CIOBLKOUT) when
; available; 0 = byte mode FastPath calls only (diagnostic).
#DEFINE CFG_BLKIO 1

; Force a buffer flush prior to potential overflow.  This works around
; some sz applications that ignore the advertised buffer size and fail
; to send ZCRCW.
#DEFINE CFG_EARLYWR 1

; Enable recording and printing of detailed operational statistics.
#DEFINE CFG_RXSTATS 0

; ----------------------------------------------------------------------
; Application constants
; ----------------------------------------------------------------------
STKSIZE		.equ 128		; Stack size
RXBUFSZ		.equ 256		; HBIOS block receive buffer size (just below the stack)
TXBUFSZ		.equ 256		; HBIOS block transmit buffer size (below the receive buffer)
TOPRSV		.equ STKSIZE + 6 + RXBUFSZ + TXBUFSZ	; reserved at the top of the TPA
RINGSZ		.equ 4096		; AUX receive ring size (multiple of 256)
RXSTATS		.equ CFG_RXSTATS	; 1 = collect and print receive statistics (diagnostic)
BLKIO		.equ CFG_BLKIO		; 1 = use HBIOS CIO block reads and writes
EARLYWR		.equ CFG_EARLYWR	; 1 = write the receive buffer early when it is nearly full (see rx_early_write)
EWTHRESH	.equ 8192		; EARLYWR: write when less than this many bytes are free
WBWSTAMP	.equ 0040H		; RomWBW stamp address (see hb_init)

	; show the effective build settings during assembly
	.ECHO	"RZ build settings: BLKIO="
	.ECHO	BLKIO
	.ECHO	", EARLYWR="
	.ECHO	EARLYWR
	.ECHO	", RXSTATS="
	.ECHO	RXSTATS
	.ECHO	"\n"

; ----------------------------------------------------------------------
; CP/M page zero locations
; ----------------------------------------------------------------------
CPM			.equ 0000H	; Warm Boot Jump Vector (0000h: JP BIOS+3)
IOBYTE			.equ 0004H	; Intel I/O Byte (CP/M 2.2) / Current Drive & User (CP/M 3)
BDOS			.equ 0005H	; BDOS Function Call Entry Point (0005h: JP BDOS)
BDOSVEC			.equ 0006H	; BDOS address = top of the TPA 
DEFAULT_FCB		.equ 005CH	; Default File Control Block 1 (FCB)
DEFAULT_FCB2		.equ 006CH	; Default File Control Block 2 (FCB)
DEFAULT_DMA		.equ 0080H	; Default DMA / Command Tail Buffer (128 bytes)

; ----------------------------------------------------------------------
; CP/M BDOS function numbers (all CP/M 2.2)
; ----------------------------------------------------------------------
C_READ			.equ 1		; Function 1: Console Input (waits for char)
C_WRITE			.equ 2		; Function 2: Console Output (char in E)
C_WRITESTR		.equ 9		; Function 9: Write String to Console (DE points to string ending in '$')
C_STAT			.equ 11		; Function 11: Console Status (A=00h not ready, FFh ready)
DRV_RESET		.equ 13		; Function 13: Reset Disk System
DRV_SET			.equ 14		; Function 14: Select Active Disk Drive (E = drive 0=A, 1=B, ...)
F_OPEN			.equ 15		; Function 15: Open File (DE points to FCB)
F_CLOSE			.equ 16		; Function 16: Close File (DE points to FCB)
F_SFIRST		.equ 17		; Function 17: Search for First Directory Match (DE points to FCB)
F_SNEXT			.equ 18		; Function 18: Search for Next Directory Match
F_DELETE		.equ 19		; Function 19: Delete File (DE points to FCB)
F_READ			.equ 20		; Function 20: Read Sequential 128-byte Record
F_WRITE			.equ 21		; Function 21: Write Sequential 128-byte Record
F_MAKE			.equ 22		; Function 22: Create New File (DE points to FCB)
DRV_GET			.equ 25		; Function 25: Return Current Disk Drive (A = 0=A, 1=B, ...)
F_DMAOFF		.equ 26		; Function 26: Set DMA Offset Buffer Address (DE = buffer)
DRV_DPB			.equ 31		; Function 31: Return Disk Parameter Block Address (HL = DPB pointer)
F_USERNUM		.equ 32		; Function 32: Get / Set User Number (E=FFh get, E=0-15 set)
F_READRAND		.equ 33		; Function 33: Read Random Record
F_SIZE			.equ 35		; Function 35: Compute File Size in 128-byte records (into FCB r0,r1,r2)
F_RANDREC		.equ 36		; Function 36: Set Random Record Pointer from FCB sequential pointer

; ----------------------------------------------------------------------
; File control block (FCB) size and field offsets
; ----------------------------------------------------------------------
FCB_SIZE		.equ 36		; Standard CP/M FCB size (36 bytes)
FCB_DRV			.equ 0		; Drive code (0=default, 1=A, 2=B, ...)
FCB_NAME		.equ 1		; File name (8 ASCII bytes)
FCB_EXT			.equ 9		; File extension (3 ASCII bytes)
FCB_EX			.equ 12		; Extent byte (low byte)
FCB_S1			.equ 13		; Reserved / S1
FCB_S2			.equ 14		; Reserved / S2 (extent high bits in CP/M 3)
FCB_RC			.equ 15		; Record count in current extent (0-128)
FCB_AL			.equ 16		; Allocation block map (16 bytes, d0..d15)
FCB_CR			.equ 32		; Current record number within extent (0-127)
FCB_R0			.equ 33		; Random record pointer byte 0 (LSB)
FCB_R1			.equ 34		; Random record pointer byte 1
FCB_R2			.equ 35		; Random record pointer byte 2 (MSB / overflow)

; ----------------------------------------------------------------------
; ZCPR3 environment descriptor offsets
; ----------------------------------------------------------------------
Z3_NDR_OFF		.equ 15H	; Named Directory table pointer offset (16-bit word)
Z3_MDRV_OFF		.equ 2CH	; Maximum drive number offset (1 byte)
Z3_MUSR_OFF		.equ 2DH	; Maximum user number offset (1 byte)
Z3_DUOK_OFF		.equ 2EH	; ZCPR3 environment: "DU: form allowed" flag

; ----------------------------------------------------------------------
; RomWBW HBIOS
; ----------------------------------------------------------------------
BF_CIO			.equ 000H
BF_CIOIN		.equ BF_CIO + 0		; character input
BF_CIOOUT		.equ BF_CIO + 1		; character output
BF_CIOIST		.equ BF_CIO + 2		; character input status
BF_CIOOST		.equ BF_CIO + 3		; character output status
BF_CIOBLKIN		.equ BF_CIO + 7		; block read (non-blocking)
BF_CIOBLKOUT		.equ BF_CIO + 8		; block write (non-blocking)

BF_SYS			.equ 0F0H
BF_SYSGET		.equ BF_SYS + 8		; get hbios info
BF_SYSPEEK		.equ BF_SYS + 10	; get a byte value from alt bank
BF_SYSGET_BNKINFO	.equ 0F2H		; get bank assignment info
BF_SYSGET_TIMER		.equ 0D0H		; get current timer tick count
BC_SYSGET_BNKINFO	.equ BF_SYSGET * $100 + BF_SYSGET_BNKINFO
BF_SYSGET_CIOFN		.equ 01H		; get CIO function FastPath address
BC_SYSGET_CIOFN		.equ BF_SYSGET * $100 + BF_SYSGET_CIOFN

HB_BNKCALL		.equ 0FFF9H		; HBIOS bank call (FastPath: A=bank, IX=function, IY=unit data)

; ----------------------------------------------------------------------
; ZMODEM framing characters
; ----------------------------------------------------------------------
ZPAD			.equ 2AH	; '*' (42) Frame synchronization padding character
ZDLE			.equ 18H	; Control-X (24) Data Link Escape character
ZDLEE			.equ 58H	; Escaped ZDLE ('X' ^ 0100h)
ZBIN			.equ 41H	; 'A' (65) Binary frame header with 16-bit CRC
ZHEX			.equ 42H	; 'B' (66) Hexadecimal frame header with 16-bit CRC
ZBIN32			.equ 43H	; 'C' (67) Binary frame header with 32-bit CRC
ZBINR32			.equ 44H	; 'D' (68) Binary frame header with 32-bit CRC (RLE encoded)

; ----------------------------------------------------------------------
; ZMODEM frame types
; ----------------------------------------------------------------------
ZRQINIT			.equ 0		; Request receive init from sender
ZRINIT			.equ 1		; Receiver capabilities declaration
ZSINIT			.equ 2		; Sender init sequence (optional capabilities)
ZACK			.equ 3		; Acknowledgment to previous frame
ZFILE			.equ 4		; File name and metadata subpacket
ZSKIP			.equ 5		; Receiver skips this file
ZNAK			.equ 6		; Negative acknowledgment (corrupted frame)
ZABORT			.equ 7		; Receiver requests session abort
ZFIN			.equ 8		; Session termination / finish
ZRPOS			.equ 9		; Resume file transmission at position
ZDATA			.equ 10		; Data subpacket(s) header with 32-bit file offset
ZEOF			.equ 11		; End of file header with 32-bit file size
ZFERR			.equ 12		; Fatal disk or system I/O error
ZCRC			.equ 13		; Request remote file CRC calculation
ZCHALLENGE		.equ 14		; Challenge receiver with security sequence
ZCOMPL			.equ 15		; Request completed
ZCAN			.equ 16		; Remote end cancelled session (sent 5x CAN)
ZFREECNT		.equ 17		; Query free disk space on remote system
ZCOMMAND		.equ 18		; Execute remote command string
ZSTDERR			.equ 19		; Stream data to remote stderr

; ----------------------------------------------------------------------
; Characters that follow ZDLE: data subpacket terminators and rubout escapes
; ----------------------------------------------------------------------
ZCRCE			.equ 68H	; 'h' CRC follows; frame ends; header follows immediately
ZCRCG			.equ 69H	; 'i' CRC follows; frame continues without waiting for ACK
ZCRCQ			.equ 6AH	; 'j' CRC follows; frame continues; sender expects ZACK
ZCRCW			.equ 6BH	; 'k' CRC follows; frame ends; sender expects ZACK
ZRUB0			.equ 6CH	; 'l' Translate next character to rubout (0177h)
ZRUB1			.equ 6DH	; 'm' Translate next character to rubout (0377h)

; ----------------------------------------------------------------------
; Data subpacket return codes (terminator with bit 7 set)
; ----------------------------------------------------------------------
GOTCRCE			.equ ZCRCE+80H	; ZCRCE with bit 7 set: data subpacket ended with ZCRCE (return code of rx_data_subpkt)
GOTCRCG			.equ ZCRCG+80H	; ZCRCG received
GOTCRCQ			.equ ZCRCQ+80H	; ZCRCQ received
GOTCRCW			.equ ZCRCW+80H	; ZCRCW received
GOTCAN			.equ ZDLE+80H	; CAN CAN received while reading a header or subpacket

; ----------------------------------------------------------------------
; ZMODEM header byte positions (flag bytes ZF0-ZF3, position bytes ZP0-ZP3)
; ----------------------------------------------------------------------
ZF0			.equ 3		; Flag byte 0 (LSB / type-dependent flags)
ZF1			.equ 2		; Flag byte 1 (transfer options)
ZF2			.equ 1		; Flag byte 2 (transport options)
ZF3			.equ 0		; Flag byte 3 (MSB / extended flags)
ZP0			.equ 0		; Position byte 0 (least significant byte)
ZP1			.equ 1		; Position byte 1
ZP2			.equ 2		; Position byte 2
ZP3			.equ 3		; Position byte 3 (most significant byte)

; ----------------------------------------------------------------------
; ZRINIT capability flags (ZF0 of the ZRINIT header)
; ----------------------------------------------------------------------
CANFDX			.equ 01H	; Rx can handle full duplex communication
CANOVIO			.equ 02H	; Rx can overlap disk and serial I/O
CANBRK			.equ 04H	; Rx can send a break signal
CANCRY			.equ 08H	; Rx can decrypt data stream
CANLZW			.equ 10H	; Rx can decompress Lempel-Ziv stream
CANFC32			.equ 20H	; Rx can process 32-bit Frame Check Sequence (CRC-32)
ESCCTL			.equ 40H	; Control characters (00-1F, 80-9F) must be escaped
ESC8			.equ 80H	; 8th bit must be escaped (7-bit clean link)

; ----------------------------------------------------------------------
; ZFILE conversion options (ZF0 of the ZFILE header)
; ----------------------------------------------------------------------
ZF0_ZCBIN		.equ 1		; Binary transfer (no newline or EOF translation)
ZF0_ZCNL		.equ 2		; Text transfer (convert Unix LF <-> CP/M CR+LF)
ZF0_ZCRESUM		.equ 3		; Resume interrupted file transfer

; ----------------------------------------------------------------------
; ZFILE management options (ZF1 of the ZFILE header)
; ----------------------------------------------------------------------
ZF1_ZMNEW		.equ 1		; Transfer file only if source is newer or longer
ZF1_ZMCRC		.equ 2		; Transfer file only if CRC or length differs
ZF1_ZMAPND		.equ 3		; Append received data to destination file
ZF1_ZMCLOB		.equ 4		; Replace destination unconditionally (clobber)
ZF1_ZMNEWL		.equ 5		; Transfer file only if source is newer
ZF1_ZMDIFF		.equ 6		; Transfer file only if date or length differs
ZF1_ZMPROT		.equ 7		; Protect destination; do not overwrite if exists

; ----------------------------------------------------------------------
; ZFILE transport options (ZF2 of the ZFILE header)
; ----------------------------------------------------------------------
ZF2_ZTLZW		.equ 1		; Lempel-Ziv compression
ZF2_ZTCRYPT		.equ 2		; Encryption
ZF2_ZTRLE		.equ 3		; Run Length Encoding (RLE)

	.org 0100H


; ----------------------------------------------------------------------
; start: Program entry: show banner, parse command line, set up HBIOS,
; run the transfer, restore the default drive/user and exit.
; ----------------------------------------------------------------------
start:
	; Setup stack at top of memory
	ld hl,(BDOSVEC)			; Get BDOS vector loc
	ld bc,6				; Less 6 for BDOS image start
	or a				; Clear CF
	sbc hl,bc			; Adjust BDOS vector to BDOS start
	ld sp,hl			; Use as stack top
	;call prt_hex_word		; *debug*

	ld de,msg_banner		; point DE at banner text
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; show the banner
	call get_default_du		; remember the current drive/user

	; Get HBIOS bank id
	ld bc,BC_SYSGET_BNKINFO		; HBIOS SYSGET, Bank Info
	rst 08				; do it, no failure check
	ld a,d				; BIOS bank id to A
	ld (bios_bid),a			; save it

	; Lookup current console to use as default for transfer
	ld b,BF_SYSPEEK			; HBIOS PEEK
	ld a,(bios_bid)			; get BIOS bank id
	ld d,a				; ... and put in D
	ld hl,100H + 12H		; HCB console unit address
	rst 08				; E := value, no failure check
	ld a,e				; put in A
	ld (con_unit),a			; save as console unit
	ld (xfer_unit),a		; save as default transfer unit

	call clear_fcb			; initialize work FCB
	
	ld hl,(arg_table_ptr)		; HL -> free memory used for the argument table
	xor a				; clear the table
	ld b,14H			; fill 20 bytes
	call memset			; fill B bytes at HL with A
	ld a,(DEFAULT_DMA)		; is there a command tail?
	or a				; Is command tail empty?
	jr z,start_3			; no arguments: go straight to waiting for the sender
	ld (hl),02H			; argument table holds at most two entries
	ld de,0082H			; DE -> command tail text
	ex de,hl			; swap pointers
	ld a,0FFH			; terminate each argument with a zero
	call tokenize_args		; split the command tail
	jp nz,usage_exit		; too many arguments: show usage
	ld hl,(arg_table_ptr)		; get address of arg_table, the start of the free memory
	inc hl				; HL -> argument count
	ld a,(hl)			; A = (HL)
	or a				; no arguments?
	jp z,start_3			; none: start the transfer
	inc hl				; First argument token entry
	ld e,(hl)			; DE -> first argument
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	inc hl				; HL++
	ld a,(de)			; does it start with "-" ?
	cp 2DH				; compare A with 2DH
	jr nz,start_1			; no: it is a file specification
	call parse_options		; yes: process the option letters
	ld e,(hl)			; DE -> second argument, if any
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	ld a,d				; A = D
	or e				; A |= E
	jr z,start_3			; no file specification given
start_1:
	ld hl,work_fcb			; point HL at FCB for the file being received
	ex de,hl			; swap pointers
	call parse_filespec		; parse [du:]filename
	ld hl,work_fcb			; point HL at FCB for the file being received
	xor a				; no drive given?
	or (hl)				; Did filespec specify an explicit drive?
	jr nz,start_2			; if result is nonzero goto start_2
	ld a,(default_drive)		; use the current drive
	ld (hl),a			; store into FCB for the file being received
start_2:
	ld bc,FCB_S1			; Point to user number field in FCB extension
	add hl,bc			; HL += BC
	dec de				; DE--
	ldi				; copy the user number
	ld de,work_fcb			; point DE at FCB for the file being received
	call set_du			; select that drive and user for the received files
	call opt_xmodem			; a named file implies XMODEM
start_3:
	; Check for xfer on console
	ld c,0FFH			; assume xfer on console unit
	ld a,(con_unit)			; console unit to a
	ld b,a				; put in b
	ld a,(xfer_unit)		; xfer unit to a
	cp b				; compare con unit to xfer unit
	jr z,start_4			; if equal unit, assumed correctly
	ld c,0				; clear flag if different units
start_4:
	ld a,c				; flag -> a
	ld (con_xfer),a			; save flag
	ld a,(protocol)			; get active protocol
	cp 03H				; compare to YModem
	jr nc,start_5			; skip test if YModem or better
	ld a,(work_fcb)			; get first byte of work FCB
	or a				; Test for zero
	jp z,err_filename		; If so, no filename, abort
start_5:
	call hb_init			; initialize HBIOS FastPath, etc.
	jp nz,err_hbinit		; handle error

	ld a,(xfer_unit)		; get HBIOS xfer unit
	add a,'0'			; convert to ASCII char
	ld (msg_xfer_port),a		; insert in string
	ld de,msg_xfer_cfg		; point to xfer cfg string
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	ld a,(hb_blkok)			; get block mode flag
	ld de,msg_mode_byte		; assume byte mode
	or a				; test flag
	jr z,start_6			; if not set, print message
	ld de,msg_mode_block		; switch to block mode message
start_6:
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	ld de,msg_start_sender		; Tell user to start sender
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message

	call receive_main		; do the transfer
	call hb_flush			; send anything still buffered

	ld de,msg_abort			; load transfer abort message
	ld a,(xfer_abort)		; get abort flag
	or a				; test flag
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call nz,BDOS			; C_WRITESTR: display the $-terminated message
#IF RXSTATS
	call st_report			; print receive statistics
#ENDIF
	ld bc,0000H			; BC = original user/drive (patched at start)
restore_du		.equ $-2	; default user/drive restored at exit (patched operand)
	ld (saved_user),bc		; save as user number to select
	ld de,work_fcb			; point DE at FCB for the file being received
	call set_du			; go back to the original drive and user
	jp CPM				; exit to CP/M

; ----------------------------------------------------------------------
; get_default_du: Save the current user number and drive (from
; IOBYTE/0004H) so they can be restored at exit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
get_default_du:
	ld a,(IOBYTE)			; get IOBYTE
	ld b,a				; Preserve original byte in B
	rlca				; Rotate high nibble (user number) into low nibble
	rlca				; rotate A left
	rlca				; rotate A left
	rlca				; rotate A left
	and 0FH				; keep the low nibble
	ld (default_user),a		; save as user number at program start
	ld a,b				; Restore original I/O byte
	and 0FH				; keep the low nibble
	inc a				; Convert 0-based drive to 1-based (1=A, 2=B...)
	ld (default_drive),a		; save as drive
	ld hl,(default_user)		; get user number at program start
	ld (restore_du),hl		; save as default user/drive restored at exit
	ret				; return

; ----------------------------------------------------------------------
; set_du: Select user number and drive from a (user,drive+1) pair
; addressed by DE (BDOS F_USERNUM, DRV_SET).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
set_du:
	ld a,(de)			; Load drive number byte (1-based: 1=A, 2=B...)
	push af				; preserve AF
	dec de				; Point back to user number byte
	ld a,(de)			; Load user number (0..15)
	ld e,a				; E = user number parameter for BDOS
	ld c,F_USERNUM			; BDOS function: F_USERNUM
	call BDOS			; F_USERNUM: get/set the user number
	pop af				; restore AF
	dec a				; Convert 1-based drive (1=A) to 0-based (0=A)
	ld e,a				; E = drive number parameter for BDOS
	ld c,DRV_SET			; BDOS function: DRV_SET
	jp BDOS				; DRV_SET: select the drive

; ----------------------------------------------------------------------
; err_hbinit: Print "HBIOS initialization error" and exit.
; ----------------------------------------------------------------------
err_hbinit:
	ld de,msg_err_hbinit		; point DE at "HBIOS initialization error"
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	jp CPM				; warm boot: return to CP/M

; ----------------------------------------------------------------------
; err_filename: Print "Missing filename parameter" and exit.
; ----------------------------------------------------------------------
err_filename:
	ld de,msg_err_filename		; point DE at "Missing filename parameter"
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	; fall thru to usage_exit

; ----------------------------------------------------------------------
; usage_exit: Print the usage/help text and exit to CP/M.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
usage_exit:
	ld de,msg_usage			; point DE at usage / help text
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	jp CPM				; warm boot: return to CP/M
; Banner text
msg_banner:
	.db "ZModem Receive (RZ) for RomWBW CP/M   V 1.04",0DH,0AH
	.db "(C) 92 wshbg",0DH,0AH
	.db 0AH
	.db 24H
; Transfer configuration message
msg_xfer_cfg:
	.db "Using HBIOS COM"
msg_xfer_port:
	.db "?"
	.db 24H
; Mode text
msg_mode_byte:
	.db " (byte mode)"
	.db 24H
msg_mode_block:
	.db " (block mode)",
	.db 24H
; Start send message
msg_start_sender:
	.db ", start X/Y/ZModem send...",0DH,0AH
	.db 24H
; HBIOS initialization error message
msg_err_hbinit:
	.db "HBIOS initialization error!",0DH,0AH
	.db 0AH
	.db 24H
; Missing filename parameter error message
msg_err_filename:
	.db "Missing filename parameter",0DH,0AH
	.db 0AH
	.db 24H
; Transfer aborted message
msg_abort:
	.db 0DH,0AH
	.db "Transfer aborted!",0DH,0AH
	.db 0AH
	.db 24H
; FFH if the transfer was aborted (set by abort_receive)
xfer_abort:
	.db 00H
; Usage / help text
msg_usage:
	.db "Usage: rz [-?prxyz] [du:fn]",0DH,0AH
	.db 0AH
	.db "   Options for ZModem:",0DH,0AH
	.db "            ?      this help",0DH,0AH
	.db "            p      protect File",0DH,0AH
	.db "            r      resume transmission",0DH,0AH
	.db "            x,y,z  protocol",0DH,0AH
	.db "            0-9    port",0DH,0AH
	.db "            du:fn  defaults to XModem",0DH,0AH
	.db 0AH
	.db "   Values override options from sender",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; parse_options: Scan a "-xyz" option string; each letter is looked up in
; the option key table and its handler is run.
; ----------------------------------------------------------------------
parse_options:
	push hl				; preserve HL
	push de				; preserve DE
parse_options_1:
	inc de				; Advance to next character in argument string
	ld a,(de)			; A = (DE)
	or a				; Test for null terminator (end of string)
	jr z,parse_options_3		; if result is zero goto parse_options_2
	ld hl,opt_tab			; point HL at option letters and their handlers
	ld bc,0007H			; 7 keys in the table
	cpir				; look A up in the key table
	jp nz,parse_options_2		; if not in key list, look for comm port #
	call dispatch			; otherwise goto dispatch
	jr parse_options_1		; and loop back to parse_options_1
parse_options_2:
	sub '0'				; index based on character '0'
	cp 9+1				; test for max value of 9
	jp nc,usage_exit		; if out of range, display usage and exit
	ld (xfer_unit),a		; save as xfer unit
	jr parse_options_1		; and loop back to parse_options_1
parse_options_3:
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
; Option letters and their handlers (vectors are stored in reverse key order)
opt_tab:
	.db 3FH,50H,42H,58H,59H,5AH,52H	; keys: ?PBXYZR
	.dw opt_resume			; key 52H 'R'
	.dw opt_zmodem			; key 5AH 'Z'
	.dw opt_ymodem			; key 59H 'Y'
	.dw opt_xmodem			; key 58H 'X'
	.dw opt_binary			; key 42H 'B'
	.dw opt_protect			; key 50H 'P'
	.dw usage_exit			; key 3FH '?'

; ----------------------------------------------------------------------
; opt_xmodem: Option X: select XMODEM.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
opt_xmodem:
	ld a,01H			; protocol 1 = XMODEM
	jr set_protocol			; continue at set_protocol

; ----------------------------------------------------------------------
; opt_ymodem: Option Y: select YMODEM.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
opt_ymodem:
	ld a,03H			; protocol 3 = YMODEM
	jr set_protocol			; continue at set_protocol

; ----------------------------------------------------------------------
; opt_zmodem: Option Z: select ZMODEM.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
opt_zmodem:
	ld a,04H			; protocol 4 = ZMODEM

; ----------------------------------------------------------------------
; set_protocol: Store protocol number in A (1=XMODEM, 3=YMODEM, 4=ZMODEM).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
set_protocol:
	ld (protocol),a			; save as selected protocol
	ret				; return

; ----------------------------------------------------------------------
; opt_protect: Option P: protect existing files (do not overwrite).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
opt_protect:
	ld a,0FFH			; set the -p flag (protect an existing file)
	ld (opt_protect_flag),a		; FFH if -p = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; opt_binary: Option B: binary transfer.  All transfers are now binary, so
; this is accepted only for compatibility and does nothing.
; ----------------------------------------------------------------------
opt_binary:
	ret				; return

; ----------------------------------------------------------------------
; opt_resume: Option R: resume an interrupted transmission.
; ----------------------------------------------------------------------
opt_resume:
	ld a,0FFH			; set the -r flag (resume an interrupted transfer)
	ld (opt_resume_flag),a		; FFH if -r = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; bdos_dir: Call a BDOS directory function (C = function, DE = FCB) that
; returns a directory code 0-3 on success and FFH on failure (F_MAKE,
; F_OPEN, F_DELETE, F_SIZE).  Returns CF set on failure.
; ----------------------------------------------------------------------
bdos_dir:
	call BDOS			; Invoke BDOS service function in C
	inc a				; FFH (failure) -> 0
	scf				; assume failure
	ret z				; failure: CF set
	or a				; success: CF clear
	ret				; return

; ----------------------------------------------------------------------
; bdos_rec: Call a BDOS record function (C = function, DE = FCB) that
; returns 0 on success and nonzero on failure (F_READRAND).  Returns CF
; set on failure.
; ----------------------------------------------------------------------
bdos_rec:
	call BDOS			; Invoke BDOS service function in C
	or a				; success?
	ret z				; if so, CF clear
	scf				; failure: CF set
	ret				; return

; ----------------------------------------------------------------------
; skip_strings: Advance HL past B zero-terminated strings.
; ----------------------------------------------------------------------
skip_strings:
	push af				; preserve AF
skip_strings_1:
	push bc				; preserve BC
	xor a				; Search target character = 00h (null terminator)
	ld b,a				; BC = 0000h (search up to 65,536 bytes)
	ld c,a				; C = A
	cpir				; look A up in the key table
	pop bc				; restore BC
	djnz skip_strings_1		; repeat until all B items are done
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; print_err_count: Print the current error count / retry message on the
; console.
; ----------------------------------------------------------------------
print_err_count:
#IF RXSTATS
	ld hl,st_errs			; count every receive error
	call inc32			; ...
#ENDIF
	ld a,(con_xfer)			; transfer on console?
	or a				; test for zero
	ret nz				; abort print if set

	ld a,(error_count)		; get consecutive error/retry counter
	ld de,print_err_d1		; point DE at print_err_d1
	call a_to_decimal		; convert A to up to three decimal digits at DE
	ld de,msg_errors		; point DE at " error
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display " error
; " error(s)" message
; Common data: identical in RZ and SZ.
msg_errors:
	.db 0DH,0AH
print_err_d1:
	.db 00H
	.db 00H
	.db 00H
	.db " error(s)",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; print_filename: Print the current file name (DU:NAME.EXT) and its size.
; ----------------------------------------------------------------------
print_filename:
	ld a,(con_xfer)			; transfer on console?
	or a				; test for zero
	ret nz				; abort print if set

	ld de,work_fcb			; point DE at FCB for the file being received
	ld hl,print_filenam_d3		; point HL at print_filenam_d3
	ld (hl),3AH			; store into print_filenam_d3
	inc hl				; Advance to filename buffer
	xor a				; Fill byte = 00h
	ld b,0DH			; fill 13 bytes
	call memset			; fill B bytes at HL with A
	inc de				; Advance DE past drive byte to filename field (8+3)
	call fcb_to_name		; format the FCB name at DE as NAME.EXT at HL
	dec de				; Back up DE to drive byte
	ld a,(de)			; Load 1-based drive number (1=A, 2=B...)
	add a,40H			; Convert to ASCII letter ('A'..'P')
	ld (print_filenam_d1),a		; save as print_filenam_d1
	dec de				; Back up DE to user number byte
	ld a,(de)			; Load user number (0..15)
	ld de,print_filenam_d2		; point DE at print_filenam_d2
	call a_to_decimal		; convert A to up to three decimal digits at DE
	ld a,24H			; String terminator character
	ld (print_filenam_d4),a		; print_filenam_d4 = 24H
	ld de,name_line_buf		; point DE at console line buffer
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	ld hl,(info_size_ptr)		; get ... pointer to the file length/info string
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	ret z				; return: the 16-bit count is zero
	ld b,01H			; Skip past first null byte (skip filename)
	call skip_strings		; advance HL past B zero-terminated strings
	dec hl				; Point back to null byte separator
	ld (hl),24H			; Replace null with '$' terminator for BDOS output
	ld de,(info_size_ptr)		; get ... pointer to the file length/info string
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	ld de,print_filenam_d5		; point DE at print_filenam_d5
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display the $-terminated message
; Console line buffer: CR LF, "d:" and file name
name_line_buf:
	.db 0DH,0AH
print_filenam_d1:
	.db 00H
print_filenam_d2:
	.db 00H
	.db 00H
	.db 00H
print_filenam_d3:
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 00H
	.db 20H
print_filenam_d4:
	.db 00H
print_filenam_d5:
	.db 0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; print_position: Print the current file position as a decimal number on
; the console.
; ----------------------------------------------------------------------
print_position:
	ld a,(con_xfer)			; transfer on console?
	or a				; test for zero
	ret nz				; abort print if set
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,print_positio_d1		; point DE at print_positio_d1
	call ltoa32			; convert file_position to decimal text at print_positio_d1
	ld (hl),24H			; Append '$' string terminator
	ld de,pos_line_buf		; point DE at console line buffer for the position display
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display console line buffer for the position display
; Console line buffer for the position display
; Common data: identical in RZ and SZ.
pos_line_buf:
	.db 0DH
print_positio_d1:
	.fill 10,0
spinner_entry:

; ----------------------------------------------------------------------
; show_spinner: Advance and print the rotating "|/-\" activity spinner.
; ----------------------------------------------------------------------
show_spinner:
	ld a,(con_xfer)			; transfer on console?
	or a				; test for zero
	ret nz				; abort spinner if set

	ld hl,spinner_chars
show_spinner_1:
	ld a,00H			; A = 00H
spinner_index		.equ show_spinner_1+1	; spinner phase 0-3 (patched operand)
	inc a				; A++
	and 03H				; Wrap around modulo 4 (0..3)
	ld (spinner_index),a		; save as spinner phase 0-3
	ld e,a				; E = A
	ld d,00H			; D = 0
	add hl,de			; Index into spinner character array
	ld a,(hl)			; Load spinner character
	ld (spinner_char),a		; save as spinner character being displayed
	ld de,spinner_msg		; point DE at spinner message
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display spinner message
spinner_chars:
	.db "|/-",5CH
; Spinner message: blank, spinner char, two backspaces, "$"
spinner_msg:
	.db 20H
; Spinner character being displayed
spinner_char:
	.db 7CH,08H,08H,24H

; ----------------------------------------------------------------------
; print_skipped: Print "File skipped".
; ----------------------------------------------------------------------
print_skipped:
	ld a,(con_xfer)			; transfer on console?
	or a				; test for zero
	ret nz				; abort print if set
	ld de,msg_file_skipped		; point DE at "File skipped"
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display the $-terminated message
; "File skipped"
; Common data: identical in RZ and SZ.
msg_file_skipped:
	.db "File skipped",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; set_pending_char: Queue A (count in C) as pending input characters; used
; to inject CANs when ESC is pressed.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
set_pending_char:
	ld hl,pending_char		; point HL at queued input character
	ld (hl),a			; store into queued input character
	inc hl				; Advance HL to buffer count byte
	ld (hl),c			; store into queued input character
	ret				; return
; Queued input character (see set_pending_char)
; Common data: identical in RZ and SZ.
pending_char:
	.db 00H
; Number of times pending_char is still to be delivered
; Common data: identical in RZ and SZ.
pending_count:
	.db 00H

; ----------------------------------------------------------------------
; aux_poll_input: Poll the HBIOS transfer unit and move any waiting
; characters into the receive ring buffer.
;
; With block receive, at most ONE refill (BF_CIOBLKIN) is done per call.
; Bytes already in the block buffer are moved to the ring without any
; HBIOS call.  Without this limit, a refill's fixed cost means the next
; refill always finds another byte while the other side streams, so the
; loop never ends: the whole stream is routed through the ring and
; replies are delayed.  Anything not taken stays in the driver
; buffer/FIFO and the other side is held off by flow control.  Byte mode
; behaves as before.
; ----------------------------------------------------------------------
aux_poll_input:
	xor a				; init refill flag (no refill yet)
	ld (aux_poll_fill),a
aux_poll_input_1:
	ld hl,(aux_ring)		; get AUX receive ring buffer control block
	ld de,RINGSZ			; DE = maximum receive ring buffer capacity
	or a				; clear carry for sbc below
	sbc hl,de			; buffer full?
	jr z,aux_poll_input_5		; If buffer is full, do not read; check available count
	ld a,(hb_rxcnt)			; bytes already in the block buffer?
	or a
	jr nz,aux_poll_input_4		; if so, move one to the ring, no HBIOS call
	ld a,(hb_blkok)			; block receive in use?
	or a
	jr z,aux_poll_input_3		; if not, byte mode status call as before
	ld a,(aux_poll_fill)		; block refilled already in this call?
	or a
	jr z,aux_poll_input_2		; if not, allow one refill
	xor a				; if so, done: A := 0 (A was FFH) so
	jr aux_poll_input_5		; ... aux_poll_input_5 reports nothing taken
aux_poll_input_2:
	dec a				; A := FFH
	ld (aux_poll_fill),a		; note the refill
aux_poll_input_3:
	call hb_cinst			; input status (refills an empty block buffer)
	or a				; test A (sets Z if A = 0)
	jr z,aux_poll_input_5		; if result is zero goto aux_poll_input_5
aux_poll_input_4:
	call hb_cin			; get the byte in C
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_put			; insert byte C into the receive ring buffer
	jr aux_poll_input_1		; loop back to aux_poll_input_1
aux_poll_input_5:
	ld hl,pending_count		; point HL at number of times pending_char is still to be delivered
	or (hl)				; Test if single-byte buffer holds a character
	ret nz				; Return NZ if character ready
	ld hl,(aux_ring)		; get AUX receive ring buffer control block
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	ret				; return
; aux_poll_input: FFH once a block refill has been done in this call
aux_poll_fill:
	.db 00H

; ----------------------------------------------------------------------
; aux_get_char: Fetch next input character: pending queued char first,
; otherwise from the ring buffer. NZ if a char was returned.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
aux_get_char:
	ld a,(pending_count)		; get number of times pending_char is still to be delivered
	or a				; Is single-byte buffer empty?
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	jp z,ring_get			; if number of times pending_char is still to be delivered is zero/clear goto ring_get
	push af				; preserve AF
	ld hl,pending_count		; point HL at number of times pending_char is still to be delivered
	dec (hl)			; count down number of times pending_char is still to be delivered
	dec hl				; Point back to input index
	pop af				; restore AF
	ld a,(hl)			; get a byte of number of times pending_char is still to be delivered
	ret				; return

; ----------------------------------------------------------------------
; aux_putc: Send the character in A to the modem (HBIOS transfer unit).
; ----------------------------------------------------------------------
aux_putc:
	jp hb_cout			; byte mode FastPath output

; ----------------------------------------------------------------------
; aux_out_ready: Test whether the modem output is ready (NZ if ready).
; ----------------------------------------------------------------------
aux_out_ready:
	call hb_coutst			; byte mode FastPath output status
	or a				; set flags
	ret				; return

; ----------------------------------------------------------------------
; aux_wait_input: Wait roughly 100 ms-steps for an input character;
; returns it in A with NZ, Z on timeout.  The wait is a software delay
; loop, so it scales with CPU speed.
; ----------------------------------------------------------------------
aux_wait_input:
	push bc				; preserve BC
	ld b,5FH			; repeat count = 95
aux_wait_input_1:
	push bc				; preserve BC
	call aux_poll_input		; poll the modem input
	pop bc				; restore BC
	jr nz,aux_wait_input_2		; if input was waiting goto aux_wait_input_2
#IF RXSTATS
	call st_idle_pass		; statistics: idle pass (BC preserved)
#ENDIF
	call delay_short		; short software delay loop
	djnz aux_wait_input_1		; repeat until all B items are done
	call aux_poll_input		; poll the modem input
aux_wait_input_2:
#IF RXSTATS
	push af				; keep the input-ready flag
	call st_idle_end		; statistics: end any idle stretch
	pop af				; ...
#ENDIF
	call nz,aux_get_char		; If byte ready (NZ), fetch it into A
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; delay_short: Short software delay loop.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
delay_short:
	push bc				; preserve BC
	ld a,04H			; Outer delay loop count = 4
	ld b,00H			; repeat count = 0
delay_short_1:
	djnz delay_short_1		; repeat until all B items are done
	dec a				; Decrement outer loop count
	jr nz,delay_short_1		; Loop until outer count reaches 0
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; ring_get: Remove one byte from the receive ring buffer.
; ----------------------------------------------------------------------
ring_get:
	ld e,(hl)			; DE = number of bytes in the ring (offset 0)
	inc hl				; HL++
	ld d,(hl)			; Load high byte of queued byte count (DE = count)
	ld a,d				; empty?
	or e				; test DE for zero
	ret z				; ring empty: return with Z set
	dec de				; one byte fewer in the ring
	ld (hl),d			; store the new count (high)
	dec hl				; HL--
	ld (hl),e			; store the new count (low)
	ld de,0004H			; offset 4 = read index
	add hl,de			; HL -> read index
	push hl				; remember where the read index lives
	ld e,(hl)			; DE = read index
	inc hl				; HL++
	ld d,(hl)			; Load high byte of read pointer offset
	inc hl				; HL -> start of the data area (offset 6)
	add hl,de			; HL -> next byte to read
	ex (sp),hl			; stack = byte address, HL = read index address
	inc de				; advance the read index
	ld a,e				; wrap the index at the end of the ring
	and 0FFH			; Low 8 bits of ring buffer offset
	ld (hl),a			; store the new read index (low)
	inc hl				; HL++
	ld a,d				; High bits of ring buffer offset
	and (RINGSZ - 1) >> 8		; Mask to ring buffer size (high byte)
	ld (hl),a			; store the new read index (high)
	pop hl				; HL -> the byte being removed
	ld a,01H			; clear Z to show that a byte is returned
	or a				; test A (sets Z if A = 0)
	ld a,(hl)			; A = the byte taken from the ring
	ret				; return

; ----------------------------------------------------------------------
; ring_put: Insert byte C into the receive ring buffer.
; ----------------------------------------------------------------------
ring_put:
	or a				; clear carry
	push hl				; preserve HL
	ld e,(hl)			; DE = number of bytes in the ring
	inc hl				; HL++
	ld d,(hl)			; Load high byte of queued byte count
	ld hl,RINGSZ			; HL = ring capacity
	sbc hl,de			; HL = capacity - count
	pop hl				; restore the control block pointer
	ret z				; ring full: return with Z set (byte not stored)
	inc de				; one more byte in the ring
	ld (hl),e			; store the new count (low)
	inc hl				; HL++
	ld (hl),d			; store the new count (high)
	inc hl				; HL -> write index (offset 2)
	push hl				; preserve HL
	ld e,(hl)			; DE = write index
	inc hl				; HL++
	ld d,(hl)			; Load high byte of write pointer offset
	inc hl				; Advance past write pointer
	inc hl				; Skip read pointer field to buffer data start
	inc hl				; HL -> start of the data area (offset 6)
	add hl,de			; HL -> slot for the new byte
	ex (sp),hl			; stack = slot address, HL = write index address
	inc de				; advance the write index
	ld a,e				; wrap the index at the end of the ring
	and 0FFH			; Mask to ring buffer modulo boundary
	ld (hl),a			; store the new write index (low)
	inc hl				; HL++
	ld a,d				; High byte of write offset
	and (RINGSZ - 1) >> 8		; Mask to ring buffer size (high byte)
	ld (hl),a			; store the new write index (high)
	pop hl				; HL -> slot for the new byte
	ld (hl),c			; store the byte (passed in C)
	ret				; NZ: byte stored

; ----------------------------------------------------------------------
; clear_fcb: Zero the 37-byte FCB at HL.
; ----------------------------------------------------------------------
clear_fcb:
	ld hl,saved_user		; point HL at user number to select
	ld b,25H			; Count = 37 (25h) bytes to clear
	jr memset_a			; continue at memset_a

; ----------------------------------------------------------------------
; file_buf_reset: Reset the 128-byte file sector buffer control block.
; ----------------------------------------------------------------------
file_buf_reset:
	ld b,03H			; Count = 3 bytes to clear
	jr memset_a			; continue at memset_a

; ----------------------------------------------------------------------
; ring_reset: Clear the 6-byte ring buffer control block at HL.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
ring_reset:
	ld b,06H			; Count = 6 bytes to clear

; ----------------------------------------------------------------------
; memset_a: Fill using A and B.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
memset_a:
	xor a				; A = 00h (fill byte)
	jp memset			; continue at memset

; ----------------------------------------------------------------------
; file_buf_get: Get next byte from the sector buffer; carry/zero indicates
; empty.
; ----------------------------------------------------------------------
file_buf_get:
	xor a				; Clear A
	or (hl)				; Test FIFO count byte at (HL)
	ret z				; return: result is zero
	dec (hl)			; Decrement queued count
	inc hl				; Advance to read index field
	inc hl				; HL++
	ld e,(hl)			; Load current read index into E
	ld d,00H			; D = 0
	ld a,e				; Advance read index
	inc a				; A++
	and 7FH				; strip the parity bit (7-bit ASCII)
	ld (hl),a			; Store updated read index
	inc hl				; Point past index to FIFO buffer base
	adc hl,de			; HL = absolute address of next character
	ld a,(hl)			; Load character from FIFO into A
	ret nc				; If no carry, return with character in A
	ccf				; complement carry
	ret				; return

; ----------------------------------------------------------------------
; file_buf_put: Store byte C in the sector buffer; NZ when a sector is
; full.
; ----------------------------------------------------------------------
file_buf_put:
	ld a,80H			; FIFO maximum capacity = 128 (80h) bytes
	sub (hl)			; Check if FIFO is full ((HL) == 80h)
	ret z				; return if zero
	inc (hl)			; Increment queued character count
	inc hl				; Advance to write index field
	ld e,(hl)			; Load current write index into E
	ld d,00H			; D = 0
	ld a,e				; Advance write index
	inc a				; A++
	and 7FH				; strip the parity bit (7-bit ASCII)
	ld (hl),a			; Store updated write index
	inc hl				; Point past index to FIFO buffer base
	inc hl				; HL++
	adc hl,de			; HL = absolute address of write slot
	ld (hl),c			; Store character C into FIFO
	ret nc				; If no carry, return
	ccf				; complement carry
	ret				; return

; ----------------------------------------------------------------------
; dispatch: Table dispatcher: after CPIR over N keys, jump to the matching
; vector stored (in reverse order) after the key list.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
dispatch:
	add hl,bc			; HL += BC
	sla c				; Multiply remaining index count C by 2 (word offset)
	add hl,bc			; HL += BC
	ld c,(hl)			; Load low byte of handler routine address
	inc hl				; HL++
	ld h,(hl)			; Load high byte of handler routine address
	ld l,c				; HL = target handler address
	jp (hl)				; jump to the routine address in HL

; ----------------------------------------------------------------------
; zero32: Set the 32-bit value at (HL) to 0.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
zero32:
	xor a				; A = 00h (clear value)
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ld (hl),a			; Zero out first byte
	ld d,h				; DE = HL + 1 (destination for block clear)
	ld e,l				; E = L
	inc de				; DE++
	jr copy32_1			; continue at copy32_1

; ----------------------------------------------------------------------
; copy32: Copy 32-bit value (HL) to (DE).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
copy32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ldi				; Copy byte 1: (DE) = (HL), increment pointers, dec BC
copy32_1:
	ldi				; Copy byte 2
	ldi				; Copy byte 3
	ldi				; Copy byte 4
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; eq32: Compare 32-bit values (HL) and (DE) for equality (Z if equal).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
eq32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ld b,04H			; repeat count = 4
eq32_1:
	ld a,(de)			; Load byte from first buffer
	xor (hl)			; Compare with byte from second buffer
	jr nz,eq32_2			; If mismatch found, exit with NZ
	inc de				; Advance first pointer
	inc hl				; Advance second pointer
	djnz eq32_1			; repeat until all B items are done
eq32_2:
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; add32: (BC) = (DE) + (HL), 32-bit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
add32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	or a				; test A (sets Z if A = 0)
	ex af,af'			; Save cleared carry in alternate AF
	ld a,04H			; 4 bytes to add (32 bits)
add32_1:
	ex af,af'			; Restore carry from previous byte addition
	ld a,(de)			; Load addend byte from (DE)
	adc a,(hl)			; Add with carry addend byte from (HL)
	ld (bc),a			; Store sum byte to destination (BC)
	inc bc				; Advance destination pointer
	inc de				; Advance source pointer 1
	inc hl				; Advance source pointer 2
	ex af,af'			; Preserve carry in alternate AF
	dec a				; Decrement loop byte count
	jr nz,add32_1			; Continue for all 4 bytes
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; sub32: (BC) = (HL) - (DE), 32-bit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
sub32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	or a				; test A (sets Z if A = 0)
	ex af,af'			; Save cleared borrow in alternate AF
	ld a,04H			; 4 bytes to subtract (32 bits)
sub32_1:
	ex af,af'			; Restore borrow from previous byte subtraction
	ld a,(de)			; Load minuend byte from (DE)
	sbc a,(hl)			; Subtract with borrow subtrahend byte from (HL)
	ld (bc),a			; Store difference byte to destination (BC)
	inc bc				; Advance destination pointer
	inc hl				; Advance subtrahend pointer
	inc de				; Advance minuend pointer
	ex af,af'			; Preserve borrow in alternate AF
	dec a				; Decrement loop byte count
	jr nz,sub32_1			; Continue for all 4 bytes
	ex af,af'			; swap AF with AF'
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; inc32: Increment the 32-bit value at (HL).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
inc32:
	push bc				; preserve BC
	push hl				; preserve HL
	ld a,01H			; Add 1 to lowest byte
	add a,(hl)			; A += (HL)
	ld (hl),a			; Store updated low byte
	jr nc,inc32_2			; If no overflow, increment complete
	ld b,03H			; repeat count = 3
inc32_1:
	inc hl				; Advance to next higher byte
	ld a,00H			; Add carry bit
	adc a,(hl)			; A += (HL) + carry
	ld (hl),a			; Store updated byte
	djnz inc32_1			; repeat until all B items are done
inc32_2:
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; set32_minus1: Set the 32-bit value at (HL) to -1 (0FFFFFFFFH).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
set32_minus1:
	call zero32			; set the 32-bit value at

; ----------------------------------------------------------------------
; dec32: Decrement the 32-bit value at (HL).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
dec32:
	push bc				; preserve BC
	push hl				; preserve HL
	ld a,(hl)			; Load low byte
	sub 01H				; Subtract 1 from lowest byte
	ld (hl),a			; Store updated low byte
	ld b,03H			; repeat count = 3
dec32_1:
	inc hl				; Advance to next higher byte
	ld a,(hl)			; Load byte
	sbc a,00H			; Subtract borrow bit
	ld (hl),a			; Store updated byte
	djnz dec32_1			; repeat until all B items are done
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return

; Powers of ten for ltoa32: 10^9 down to 10, each a 32-bit little-endian value
; Common data: identical in RZ and SZ.
pow10_table:
	.db 00H,0CAH,9AH,3BH		; 1000000000
	.db 00H,0E1H,0F5H,05H		; 100000000
	.db 80H,96H,98H,00H		; 10000000
	.db 40H,42H,0FH,00H		; 1000000
	.db 0A0H,86H,01H,00H		; 100000
	.db 10H,27H,00H,00H		; 10000
	.db 0E8H,03H,00H,00H		; 1000
	.db 64H,00H,00H,00H		; 100
	.db 0AH,00H,00H,00H		; 10

; ----------------------------------------------------------------------
; ltoa32: Convert the 32-bit value at (HL) to decimal ASCII at (DE) (zero
; terminated).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
ltoa32:
	ld (ltoa_outptr),de		; remember where the text goes
	ld de,ltoa_value		; point DE at working copy of the 32-bit value being converted
	call copy32			; work on a copy of the value
	ld c,09H			; up to nine digits plus the final one
	ld de,pow10_table-4		; DE -> 4 bytes before the table of powers of ten (stepped forward before each use)
	xor a				; A = 0
	ld (ltoa_started),a		; no digit emitted yet (suppress leading zeros)
ltoa32_1:
	ld a,30H			; start the digit at "0"
	ld (ltoa_digit),a		; digit character being built = 30H
	inc de				; step to the next power of ten (4 bytes)
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	ld b,0AH			; at most ten subtractions per digit
ltoa32_2:
	push bc				; preserve BC
	ld hl,ltoa_value		; point HL at working copy of the 32-bit value being converted
	ld bc,ltoa_temp			; point BC at temporary 32-bit subtraction result
	call sub32			; temp = value - power of ten
	pop bc				; restore BC
	jr c,ltoa32_3			; value is smaller than the power: this digit is complete
	push de				; preserve DE
	ld a,(ltoa_digit)		; count one more subtraction
	inc a				; A++
	ld (ltoa_digit),a		; save as digit character being built
	ld de,ltoa_value		; point DE at working copy of the 32-bit value being converted
	ld hl,ltoa_temp			; point HL at temporary 32-bit subtraction result
	call copy32			; value = remainder
	pop de				; restore DE
	djnz ltoa32_2			; try subtracting again
ltoa32_3:
	ld a,30H			; digit finished: is it "0"?
ltoa_digit		.equ ltoa32_3+1	; ltoa32: digit character being built (patched operand)
	cp 30H				; Is it a leading zero ('0')?
	jr nz,ltoa32_5			; non-zero digit: always emit it
ltoa32_4:
	ld a,00H			; a zero: emit only if a digit was already emitted
ltoa_started		.equ ltoa32_4+1	; ltoa32: nonzero once a nonzero digit has been emitted
	or a				; test A (sets Z if A = 0)
	jr z,ltoa32_6			; leading zero: skip it
ltoa32_5:
	ld hl,0000H			; HL = output pointer
ltoa_outptr		.equ ltoa32_5+1	; ltoa32: output pointer (patched operand, 16 bits)
	ld (hl),a			; store the digit
	inc hl				; Advance output pointer
	ld (ltoa_outptr),hl		; advance the output pointer
	ld a,30H			; mark that digits have started
	ld (ltoa_started),a		; nonzero once a nonzero digit has been emitted = 30H
ltoa32_6:
	dec c				; next power of ten
	jr nz,ltoa32_1			; Process next decimal position
	ld a,(ltoa_value)		; last digit is the remaining value
	and 0FH				; keep the low nibble
	add a,30H			; convert to ASCII
	ld hl,(ltoa_outptr)		; get output pointer
	ld (hl),a			; Store units digit into buffer
	inc hl				; Advance pointer
	ld (hl),00H			; terminate the text with a zero
	ret				; return

; ----------------------------------------------------------------------
; checksum_add: Add A to the running 8-bit XMODEM checksum.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
checksum_add:
	push af				; preserve AF
checksum_add_1:
	add a,00H			; Add byte to running 8-bit checksum accumulator
xm_checksum		.equ checksum_add_1+1	; running 8-bit XMODEM checksum (patched operand)
	ld (xm_checksum),a		; save as running 8-bit XMODEM checksum
	pop af				; restore AF
	ret				; return
; CRC-32 polynomial 0EDB88320H (little endian)
; Common data: identical in RZ and SZ.
crc32_poly:
	.db 20H,83H,0B8H,0EDH
; CRC-32 residue 0DEBB20E3H expected after a good frame
; Common data: identical in RZ and SZ.
crc32_residue:
	.db 0E3H,20H,0BBH,0DEH

; ----------------------------------------------------------------------
; crc32_update: Update the running CRC-32 with byte A.  AF and DE are
; preserved; BC and HL are not.
;
; This routine has been updated to improve performance.  The table is
; held as four page-aligned 256-byte planes (crc32_table + 0/256/512/768
; hold bytes 0-3 of each entry), so each entry byte is reached with BC
; (B = plane page, C = index) instead of IX/IY indexing.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
crc32_update:
	push af				; preserve AF
	ld hl,crc32_value		; HL -> CRC byte 0
	xor (hl)			; index := byte XOR CRC byte 0
	ld c,a				; C := index
	ld b,crc32_table >> 8		; B := plane 0 page
	inc hl				; HL -> CRC byte 1
	ld a,(bc)			; new byte 0 := T0[index] XOR CRC byte 1
	xor (hl)			; ...
	dec hl				; ...
	ld (hl),a			; ...
	inc hl				; HL -> CRC byte 2
	inc hl				; ...
	inc b				; plane 1
	ld a,(bc)			; new byte 1 := T1[index] XOR CRC byte 2
	xor (hl)			; ...
	dec hl				; ...
	ld (hl),a			; ...
	inc hl				; HL -> CRC byte 3
	inc hl				; ...
	inc b				; plane 2
	ld a,(bc)			; new byte 2 := T2[index] XOR CRC byte 3
	xor (hl)			; ...
	dec hl				; ...
	ld (hl),a			; ...
	inc hl				; HL -> CRC byte 3
	inc b				; plane 3
	ld a,(bc)			; new byte 3 := T3[index]
	ld (hl),a			; ...
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; crc32_table_init: Build the 256-entry CRC-32 lookup table (reflected
; polynomial 0EDB88320H) as four 256-byte planes, one per entry byte (see
; crc32_update).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
crc32_table_init:
	push de				; preserve DE
	push hl				; preserve HL
	ld c,00H			; C := table index
crc32_table_1:
	ld e,c				; HLDE := index (E = low byte)
	ld d,00H			; ...
	ld hl,0000H			; ...
	ld b,08H			; eight bit steps
crc32_table_2:
	srl h				; shift the 32-bit value right ...
	rr l				; ...
	rr d				; ...
	rr e				; ... CF := bit shifted out
	jr nc,crc32_table_3		; bit was 0: no polynomial
	ld a,e				; bit was 1: XOR in the polynomial
	xor 20H				; ...
	ld e,a				; ...
	ld a,d				; ...
	xor 83H				; ...
	ld d,a				; ...
	ld a,l				; ...
	xor 0B8H			; ...
	ld l,a				; ...
	ld a,h				; ...
	xor 0EDH			; ...
	ld h,a				; ...
crc32_table_3:
	djnz crc32_table_2		; next bit
	ld b,crc32_table >> 8		; store byte 0 in plane 0
	ld a,e				; ...
	ld (bc),a			; ...
	inc b				; byte 1 in plane 1
	ld a,d				; ...
	ld (bc),a			; ...
	inc b				; byte 2 in plane 2
	ld a,l				; ...
	ld (bc),a			; ...
	inc b				; byte 3 in plane 3
	ld a,h				; ...
	ld (bc),a			; ...
	inc c				; next table entry
	jr nz,crc32_table_1		; repeat for all 256 entries
	pop hl				; restore HL
	pop de				; restore DE
	ret				; return

; ----------------------------------------------------------------------
; crc16_update: Update the running CRC-16 (CCITT, polynomial 1021H) with
; byte A. [updcrc]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
crc16_update:
	push af				; preserve AF
crc16_update_1:
	ld hl,0000H			; SMC: Running CRC-16 accumulator operand
crc16_lo		.equ crc16_update_1+1	; CRC-16 low byte (patched operand)
crc16_hi		.equ crc16_update_1+2	; CRC-16 high byte (patched operand)
	ld de,1021H			; CCITT CRC-16 polynomial generator (x^16 + x^12 + x^5 + 1)
	xor h				; XOR input byte with current high byte of CRC
	ld h,a				; Store XOR result into high byte of CRC
	ld b,08H			; Process 8 bits
crc16_update_2:
	add hl,hl			; Shift CRC left by 1 bit (HL << 1)
	jr nc,crc16_update_3		; If no carry shifted out, skip polynomial XOR
	ld a,h				; XOR high byte with polynomial high byte (10h)
	xor d				; A ^= D
	ld h,a				; H = A
	ld a,l				; XOR low byte with polynomial low byte (21h)
	xor e				; A ^= E
	ld l,a				; L = A
crc16_update_3:
	djnz crc16_update_2		; repeat until all B items are done
	ld (crc16_lo),hl		; save as CRC-16 low byte
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; crc_init: Reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
crc_init:
	xor a				; Clear A
	ld h,a				; HL = 0000h
	ld l,a				; L = A
	ld (xm_checksum),a		; clear running 8-bit XMODEM checksum
	ld (crc16_lo),hl		; save as CRC-16 low byte
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	jp set32_minus1			; loop back to set32_minus1
; Selected protocol: 1 = XMODEM, 3 = YMODEM, 4 = ZMODEM (default)
; Common data: identical in RZ and SZ.
protocol:
	.db 04H
; FFH if -p (protect existing files) was given
opt_protect_flag:
	.db 00H
; FFH if -r (resume) was given
opt_resume_flag:
	.db 00H
; Receive buffer size mask (power of two minus one)
buffer_mask:
	.db 00H
	.db 00H

; ----------------------------------------------------------------------
; calc_buffer_mask: Round the available buffer size down to a power of two
; and derive the wrap-around mask.
; ----------------------------------------------------------------------
calc_buffer_mask:
	xor a				; Clear accumulator
	ld c,a				; Initialize mask accumulator C = 00h
	ld b,08H			; repeat count = 8
	ld a,h				; A = memory top page high byte
calc_buffer_1:
	rlca				; Rotate highest bit into carry
	set 7,c				; Set highest bit of mask
	jr c,calc_buffer_2		; When highest set bit encountered, mask is complete
	rr c				; Shift mask right
	djnz calc_buffer_1		; repeat until all B items are done
calc_buffer_2:
	ld a,h				; A = top page byte
	and c				; Align memory boundary to power-of-two mask
	ld h,a				; HL = page-aligned memory buffer ceiling
	ld l,00H			; Set HL low byte to 0 (page-aligned)
	ld (rx_buffer_size),hl		; save as size of the receive data buffer
	dec hl				; Compute wrapping bitmask (size - 1)
	ld (buffer_mask),hl		; save as receive buffer size mask
	ret				; return

; ----------------------------------------------------------------------
; receive_main: Top-level receive: set up buffers and CRC table, then run
; ZMODEM or XMODEM/YMODEM reception. [rz.c wcreceive]
; ----------------------------------------------------------------------
receive_main:
	xor a				; clear the state variables
	ld hl,rx_state			; point HL at the protocol state area
	ld b,rx_state_end - rx_state	; size of the state area
	call memset			; fill B bytes at HL with A
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_reset			; empty the modem input ring
	call crc32_table_init		; prepare the CRC-32 table
	ld hl,(arg_table_ptr)		; the file buffer starts after the argument table ...
	ld (rx_buffer_base),hl		; save as start address of the receive data buffer
	ld de,(BDOSVEC)			; ... and ends at the top of the TPA
	ex de,hl			; swap pointers
	ld bc,TOPRSV			; Adjust for BDOS start, stack, and block receive buffer
	or a				; Clear CF
	sbc hl,bc			; Working RAM starts just below block receive buffer
	;call prt_hex_word		; *debug*
	or a				; Clear carry
	sbc hl,de			; HL = free memory size
	call calc_buffer_mask		; round it to a usable buffer size
	ld a,(opt_protect_flag)		; get FFH if -p
	cp 00H				; compare A with 00H
	jr z,receive_main_1		; if A = 00H goto receive_main_1
	ld a,ZF1_ZMPROT			; -p given: ZMPROT
receive_main_1:
	ld (protect_option),a		; save as 0, or 07H
	ld a,10H			; assume CRC-16
	ld (rx_crc_mode),a		; link CRC type = 10H (CRC-16)
	ld a,(protocol)			; XMODEM (below 3)?
	cp 03H				; is it YMODEM?
	jr c,receive_main_4		; yes
	ld a,ZRINIT			; ZMODEM/YMODEM: first send ZRINIT
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 01H (ZRINIT)
	call zrinit_handshake		; talk to the sender
	jp c,abort_receive		; if handshake failed / aborted goto abort_receive
	or a				; result 0: sender is using YMODEM
	jr z,receive_main_3		; if result is zero goto receive_main_3
	cp ZFILE			; ZFILE: a ZMODEM file follows
	jr z,receive_main_2		; if A is ZFILE goto receive_main_2
	cp ZCOMPL			; ZCOMPL: nothing to do
	jr nz,receive_main_2		; if A is not ZCOMPL goto receive_main_2
	jr receive_main_5		; done
receive_main_2:
	call zmodem_rx_files		; receive files until ZFIN
	jr c,abort_receive		; if carry goto abort_receive
	jr receive_main_5		; continue at receive_main_5
receive_main_3:
	ld a,03H			; YMODEM batch receive
	ld (protocol),a			; selected protocol = 03H (YMODEM)
	xor a				; Clear error count
	ld (error_count),a		; clear consecutive error/retry counter
	call xmodem_rx_start		; get the first (block 0) packet
	jr c,abort_receive		; if no sender / aborted goto abort_receive
	; An empty name in block 0 ends the batch normally (block 0 has
	; already been ACKed).  Avoid prep_output_file which returns
	; carry (error) for an empty name, which would abort the session.
	ld hl,(rx_buffer_base)		; HL -> file name from block 0
	ld a,(hl)			; empty name?
	or a				; ...
	jr z,receive_main_5		; if so, end of the batch
	call prep_output_file		; create the file named in block 0
	jr c,abort_receive		; if cannot create output file / abort goto abort_receive
	call xmodem_rx_file		; receive the file
	jr c,abort_receive		; if receive failed / aborted goto abort_receive
	jr receive_main_3		; next file of the batch
receive_main_4:
	call prep_output_file		; XMODEM: file name came from the command line
	jr c,abort_receive		; if cannot create output file / abort goto abort_receive
	call xmodem_rx_file		; receive all blocks of an XMODEM/YMODEM file
	jr c,abort_receive		; if receive failed / aborted goto abort_receive
receive_main_5:
	ret				; return

; ----------------------------------------------------------------------
; abort_receive: Abort: send the cancel string and close any open file.
; ----------------------------------------------------------------------
abort_receive:
	ld a,0FFH			; note the abort
	ld (xfer_abort),a		; ... for subsequent messaging
	call send_can_string		; send eight+ CAN characters followed by backspaces to
	ld a,(file_open_flag)		; get FFH while an output file is open
	cp 0FFH				; compare A with 0FFH
	call z,close_outfile		; if A = FFH: call close_outfile
	jr receive_main_5		; loop back to receive_main_5

; ----------------------------------------------------------------------
; prep_output_file: Work out transfer options and file name for the
; incoming file, check/handle an existing file and create the output file.
; [rz.c procheader]
; ----------------------------------------------------------------------
prep_output_file:
	; All data is stored unchanged (binary); the sender's conversion
	; request (ZF0 ZCNL/ZCBIN) is ignored.
	ld a,(protect_option)		; did -p force the protect option?
	or a				; test A (sets Z if A = 0)
	jr z,prep_output_3		; if 0, or 07H is zero/clear goto prep_output_3
	ld (zfile_zf1),a		; yes: override the sender's management option
prep_output_3:
	ld a,(zfile_zf1)		; management option: append (ZMAPND)?
	cp ZF1_ZMAPND			; compare A with 03H
	jr nz,prep_output_4		; if A != 03H goto prep_output_4
	ld a,ZF1_ZMPROT			; appending binary data is not supported: treat as protect
	ld (zfile_zf1),a		; ZFILE ZF1, management option = 07H
prep_output_4:
	ld a,(protocol)			; XMODEM takes its file name from the command line
	cp 03H				; is it YMODEM?
	jr c,prep_output_5		; if A < 03H goto prep_output_5
	call clear_fcb			; ZMODEM/YMODEM: the name comes from the sender
	ld hl,(rx_buffer_base)		; HL -> file info text
	xor a				; no name at all?
	or (hl)				; A |= (HL)
	scf				; error: no file name
	ret z				; return: result is zero
	push hl				; preserve HL
	ld b,01H			; skip over the name ...
	call skip_strings		; advance HL past B zero-terminated strings
	dec hl				; ... and turn its terminating zero into a blank so name and size form one string
	ld (hl),20H			; Replace null with space separator
	pop hl				; restore HL
	ld de,info_argv			; point DE at argument table built from the ZFILE data subpacket: max
	ld a,07H			; at most 7 arguments
	ld (de),a			; (DE) = A
	ld a,0FFH			; terminate each argument with a zero
	call tokenize_args		; split the info string into name, size, ...
	ld hl,(info_name_ptr)		; HL -> file name
	ld de,work_fcb			; point DE at FCB for the file being received
	call parse_filespec		; build the FCB (and DU) for the name
	ld hl,(default_user)		; select the default user/drive
	ld (saved_user),hl		; save as user number to select
prep_output_5:
	call print_filename		; show the name on the console
prep_output_6:
	ld de,work_fcb			; point DE at FCB for the file being received
	call file_exists		; does the file already exist?
	jr nz,handle_existing		; yes: decide what to do
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_MAKE			; no: create it (F_MAKE)
	call bdos_dir			; call BDOS, CF on failure
	ret c				; cannot create the file
	ld a,0FFH			; Mark file open and active
	ld (file_open_flag),a		; file is open
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_reset		; start with an empty sector buffer
	ld a,(info_argc)		; did the sender give a size?
	cp 02H				; compare A with 02H
	jr c,load_file_size_1		; if A < 02H goto load_file_size_1
load_file_size:
	ld de,(info_size_ptr)		; get ... pointer to the file length/info string
load_file_size_1:
	ld a,01H			; A = 1 (success condition)
	or a				; Clear carry
	ret				; return

; ----------------------------------------------------------------------
; handle_existing: Output file exists: skip, overwrite or resume
; depending on the options and the sender's flags.
; ----------------------------------------------------------------------
handle_existing:
	call load_file_size		; pick up the size announced by the sender
	ld a,(protocol)			; get selected protocol
	cp 04H				; ZMODEM?
	jr nz,handle_1			; no: just replace the file
	ld a,(zfile_zf1)		; sender asked for ZMPROT (protect)?
	cp ZF1_ZMPROT			; compare A with 07H
	jr nz,handle_3			; if A != 07H goto handle_3
	jr handle_2			; protect: skip this file
handle_1:
	ld de,work_fcb			; delete the old file (F_DELETE) and create it again
	ld c,F_DELETE			; C = 13H
	call bdos_dir			; call BDOS, CF on failure
	jr nc,prep_output_6		; deleted: go on and create the new file (name already shown)
handle_2:
	call print_skipped		; file skipped (protected or cannot be replaced)
	ld a,ZSKIP			; tell the sender: ZSKIP
	scf				; flag failure to caller (carry set)
	ret				; return
handle_3:
	ld a,(zfile_zf1)		; append (ZMAPND) requested?
	cp ZF1_ZMAPND			; compare A with 03H
	jr z,handle_4			; yes: open and position at the end
	ld a,(opt_resume_flag)		; otherwise resume only if -r was given
	cp 0FFH				; compare A with 0FFH
	jr nz,handle_1			; no: replace the file
handle_4:
	ld de,file_sector_buf		; open the existing file and find its length
	ld c,F_DMAOFF			; set DMA address
	call BDOS			; F_DMAOFF: set the DMA (transfer) address
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_OPEN			; open the file
	call bdos_dir			; call BDOS, CF on failure
	ret c				; If open failed, return carry
	ld a,0FFH			; Mark file active
	ld (file_open_flag),a		; FFH while an output file is open = FFH (set)
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_reset		; reset the 128-byte file sector buffer control block
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_SIZE			; compute the file size in records
	call bdos_dir			; call BDOS, CF on failure
	ret c				; Return if error
	ld hl,work_fcb_r3		; point HL at the extra byte after the FCB (offset 36)
	ld (hl),00H			; clear it so that r0-r3 form one 32-bit number
	ld hl,work_fcb_r0		; last record = size - 1
	call dec32			; subtract 1 from work_fcb_r0
	ld de,file_position		; point DE at current file position, 32 bits
	call copy32			; start from the last record number
	ex de,hl			; swap pointers
	ld b,07H			; multiply by 128 to get a byte position
handle_5:
	push hl				; preserve HL
	sla (hl)			; shift left (HL)
	inc hl				; HL++
	rl (hl)				; rotate left through carry (HL)
	inc hl				; HL++
	rl (hl)				; rotate left through carry (HL)
	inc hl				; HL++
	rl (hl)				; rotate left through carry (HL)
	pop hl				; restore HL
	djnz handle_5			; repeat until all B items are done
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_READRAND			; read that last record
	call bdos_rec			; call BDOS, CF on failure
	ret c				; Return if error
	ld a,(zfile_zf1)		; append?
	cp ZF1_ZMAPND			; compare A with 03H
	jr z,handle_6			; if A = 03H goto handle_6
	ld a,ZRPOS			; resume: answer ZRPOS from the end of the existing data
	or a				; test A (sets Z if A = 0)
	ret				; return
handle_6:
	ld a,80H			; append: look for the ^Z that marks the true end of a text file
	ld (file_buf_count),a		; output sector buffer = 80H
handle_7:
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_get		; get next byte from the sector buffer
	jr z,handle_8			; if buffer empty goto handle_8
	cp 1AH				; end-of-file marker?
	jr nz,handle_7			; if A != 1AH goto handle_7
	ld a,(file_buf_rd)		; found: position the buffer just before it
	dec a				; A--
	ld (file_buf_wr),a		; save as output sector buffer
	ld hl,file_buf_count		; point HL at output sector buffer
	ld a,7FH			; A = 7FH
	sub (hl)			; A -= (HL)
	jr handle_9			; continue at handle_9
handle_8:
	ld a,80H			; no ^Z: the sector is full of data
handle_9:
	ld (file_buf_count),a		; save as output sector buffer
	ld a,01H			; NZ: continue
	or a				; test A (sets Z if A = 0)
	ret				; return

; ----------------------------------------------------------------------
; zrinit_handshake: Send ZRINIT headers and wait for the sender's
; ZFILE/ZSINIT/ZFIN. [rz.c tryz]
; ----------------------------------------------------------------------
zrinit_handshake:
	xor a				; Clear accumulator
	ld (error_count),a		; clear consecutive error/retry counter
	ld a,04H			; A = 04H
	ld hl,protocol			; point HL at selected protocol
	cp (hl)				; is selected protocol = 04H (ZMODEM)?
	ld a,00H			; A = 00H
	ret nz				; not ZMODEM (XMODEM/YMODEM selected): no ZMODEM attempt, return 0 [rz.c: Nozmodem]
	ld hl,rx_buffer_ptr		; point HL at next free byte in the receive buffer
	ld b,11H			; fill 17 bytes
	xor a				; A = 0
	call memset			; fill B bytes at HL with A
	call rx_buffer_reset		; reset the receive buffer pointers to the start
	ld a,(header_ok_flag)		; get FFH once a valid header has been received
	cp 0FFH				; compare A with 0FFH
	ld b,05H			; up to 5 ZRINIT attempts when a header has already been seen [tryz: n = 5]
	jr z,zri_send_loop		; if A = FFH goto zri_send_loop
	ld b,0AH			; otherwise up to 10 attempts
zri_send_loop:
	push bc				; preserve BC
	ld ix,tx_header_data		; point IX at four argument bytes for the next header to send
	ld (ix+ZF0),CANFC32		; ZF0 = CANFC32: tell the sender 32-bit CRC is supported (later ZMODEM extension)
	ld (ix+ZF1),00H			; ZF1 = 0
	ld hl,(rx_buffer_size)		; get size of the receive data buffer
	ld (ix+ZP0),l			; ZP0: receiver buffer length, low byte (0 would mean nonstop I/O)
	ld (ix+ZP1),h			; ZP1: receiver buffer length, high byte; the sender must not overrun it
zri_send_header:
	ld a,ZRINIT			; frame type = ZRINIT
zri_frame_type		.equ zri_send_header+1	; frame type sent in the ZRINIT loop (patched operand)
	call send_hex_header		; send ZRINIT (or ZSKIP/ZFERR) as a hex header [zshhdr]
	ld a,(zri_frame_type)		; get frame type sent in the ZRINIT loop
	cp ZSKIP			; was the last frame ZSKIP? It is sent only once, then ZRINIT resumes
	jr nz,zri_read_hdr		; if A is not ZSKIP goto zri_read_hdr
	ld a,ZRINIT			; A = 01H
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 01H (ZRINIT)
; Read the next header without sending anything.
zri_read_hdr:
	call get_header			; wait for the sender's reply [zgethdr]
	ld hl,zri_reply_tab		; point HL at ZRINIT handshake
	ld bc,000AH			; 10 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; Count an error, then try again.
zri_count_err:
#IF RXSTATS
	ld hl,st_e_zri			; statistics: handshake error
	call inc32			; ...
#ENDIF
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
; Send ZRINIT again (no error counted).
zri_resend:
	pop bc				; restore BC
	djnz zri_send_loop		; repeat until all B items are done
	xor a				; return 0 (success)
	ret				; return
; ZCAN received, or a request this program does not support (ZCOMMAND): abandon the session.
zri_abort:
	pop bc				; restore BC
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; ZFIN: the sender has finished the session [tryz: ackbibi, return ZCOMPL].
zri_got_zfin:
	pop bc				; restore BC
	call send_zfin_wait		; ZFIN received: answer ZFIN and wait for "OO" [ackbibi]
	ld a,ZCOMPL			; return ZCOMPL: the session is finished
	ret				; return
; ZFREECNT: the sender asks for the free disk space; answer ZACK with 0 = unknown/unlimited.
zri_got_zfreecnt:
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	call zero32			; ZFREECNT: free disk space unknown, answer 0 [getfree()]
	jr zri_got_zsinit_1		; continue at zri_got_zsinit_1
; ZSINIT: the sender announces its flags and Attn string; read the data packet, answer ZACK, or ZNAK
; if it was damaged.
zri_got_zsinit:
	ld ix,rx_header_data		; point IX at four argument bytes of the most recently received header
	ld a,(ix+ZF0)			; get byte 3 of four argument bytes of the most recently received header
	and ESCCTL			; test the escape-control flag bit
	ld (escape_ctl_flag),a		; ZSINIT ZF0 bit 40H (TESCCTL): sender wants control characters escaped
	call rx_data_subpkt		; receive a ZMODEM data subpacket into the buffer
	cp GOTCRCW			; is it GOTCRCW?
	ld a,ZNAK			; bad data packet: answer ZNAK
	jr nz,zri_got_zsinit_2		; if A is not GOTCRCW goto zri_got_zsinit_2
	ld hl,(rx_buffer_base)		; get start address of the receive data buffer
	ld de,attn_string		; point DE at attention string from ZSINIT
	ld bc,0020H			; 32 bytes
	ldir				; keep the Attn string from the ZSINIT data packet (up to 32 bytes)
					; [zrbdata(Attn,ZATTNLEN)]
zri_got_zsinit_1:
	ld a,ZACK			; A = 03H
zri_got_zsinit_2:
	push af				; preserve AF
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	call zero32			; clear tx_header_data
	pop af				; restore AF
	call send_hex_header		; send a hex header
	call rx_pos_restore		; restore buffer pointer/count
	jp zri_count_err		; loop back to zri_count_err
; ZFILE: a file is offered; keep the option bytes, read the file-name data packet and return ZFILE.
zri_got_zfile:
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld de,zfile_zf3			; remember the ZFILE option bytes ZF3..ZF0 [zconv, zmanag, ztrans]
	call copy32			; copy rx_header_data to zfile_zf3
	ld a,ZRINIT			; A = 01H
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 01H (ZRINIT)
	call rx_data_subpkt		; receive a ZMODEM data subpacket into the buffer
	cp GOTCRCW			; is it GOTCRCW?
	ld a,ZNAK			; bad data packet: answer ZNAK
	jr nz,zri_got_zsinit_2		; if A is not GOTCRCW goto zri_got_zsinit_2
	pop bc				; restore BC
	ld a,ZFILE			; return ZFILE
	ret				; return
; ZRINIT handshake: frame type of the sender's reply
zri_reply_tab:
	.db ZRQINIT,ZEOF,0FEH,ZFILE,ZSINIT,ZFREECNT,ZCOMMAND,ZCOMPL,ZFIN,ZCAN	; keys: ..........
	.dw zri_abort			; key 10H ZCAN
	.dw zri_got_zfin		; key 08H ZFIN
	.dw zri_read_hdr		; key 0FH ZCOMPL
	.dw zri_abort			; key 12H ZCOMMAND
	.dw zri_got_zfreecnt		; key 11H ZFREECNT
	.dw zri_got_zsinit		; key 02H ZSINIT
	.dw zri_got_zfile		; key 04H ZFILE
	.dw zri_count_err		; key 0FEH timeout
	.dw zri_resend			; key 0BH ZEOF
	.dw zri_resend			; key 00H ZRQINIT

; ----------------------------------------------------------------------
; zmodem_rx_files: Receive successive files until ZFIN. [rz.c
; rzfiles]
; ----------------------------------------------------------------------
zmodem_rx_files:
	call zmodem_rx_file		; receive one file
	ret c				; return if carry
	cp ZEOF				; is it ZEOF?
	jr z,zmodem_rx_1		; if A is ZEOF goto zmodem_rx_1
	cp ZSKIP			; is it ZSKIP?
	jr z,zmodem_rx_1		; if A is ZSKIP goto zmodem_rx_1
	or a				; test A (sets Z if A = 0)
	ret				; return
zmodem_rx_1:
	call zrinit_handshake		; send ZRINIT headers and wait for the sender's
	ret c				; return: handshake failed / aborted
	cp ZFILE			; is it ZFILE?
	jr z,zmodem_rx_files		; if A is ZFILE goto zmodem_rx_files
	cp ZCOMPL			; is it ZCOMPL?
	ld a,00H			; A = 00H
	ret z				; return: A is ZCOMPL
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; zmodem_rx_file: Receive one file: send ZRPOS and process ZDATA/ZEOF
; until complete. [rz.c rzfile]
; ----------------------------------------------------------------------
zmodem_rx_file:
	call prep_output_file		; open or create the file named in the ZFILE data packet [procheader]
	jr nc,zmodem_rx_file_1		; if output file ready goto zmodem_rx_file_1
	ld a,ZSKIP			; cannot accept the file: reply ZSKIP [rzfile: zshhdr(ZSKIP)]
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 05H (ZSKIP)
	or a				; test A (sets Z if A = 0)
	ret				; return
zmodem_rx_file_1:
	cp ZRPOS			; did prep_output_file set up a resume (ZRPOS from the old end of file)?
	jr z,zmodem_rx_file_2		; if A = 09H goto zmodem_rx_file_2
	ld hl,file_position		; point HL at current file position, 32 bits
	call zero32			; clear file_position
zmodem_rx_file_2:
	xor a				; Reset error count
	ld (error_count),a		; clear consecutive error/retry counter
	call rx_buffer_reset		; reset the receive buffer pointers to the start
; Tell the sender where to (re)start: ZRPOS with the current file position [rzfile: stohdr(rxbytes);
; zshhdr(ZRPOS)].
rx_send_zrpos:
	call rx_pos_restore		; restore buffer pointer/count
	call write_buf_file		; flush the data received so far before (re)sending ZRPOS
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy file_position to tx_header_data
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_reset			; clear the 6-byte ring buffer control block at HL
	ld a,ZRPOS			; frame type = ZRPOS
	call send_hex_header		; send a hex header
; Wait for the next header from the sender and act on its type [rzfile: switch (zgethdr)].
rx_wait_header:
#IF RXSTATS
	ld a,2				; statistics: now receiving a header
	ld (st_src),a			; ...
#ENDIF
	call get_header			; receive a ZMODEM header
	ld hl,rx_hdr_tab		; point HL at ZModem file receive
	ld bc,0007H			; 7 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; Timeout, ZNAK or garbage: count the error (10 allowed) and send ZRPOS again.
rx_header_error:
#IF RXSTATS
	call st_hdr_err			; statistics: classify by reason code in A
#ENDIF
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
	ld hl,error_count		; point HL at consecutive error/retry counter
	ld a,0AH			; A = 0AH (LF)
	cp (hl)				; is consecutive error/retry counter = 0AH?
	jp nz,rx_send_zrpos		; if not zero goto rx_send_zrpos
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; ZFILE again: the sender did not see our ZRPOS; read its data packet again and repeat ZRPOS.
rx_got_zfile_2:
	call rx_data_subpkt		; ZFILE repeated: our ZRPOS was missed, take its data packet again
	jp rx_send_zrpos		; loop back to rx_send_zrpos
; ZEOF: if its offset equals the bytes received the file is complete, otherwise ask again with ZRPOS.
rx_got_zeof:
	ld de,rx_header_data		; point DE at four argument bytes of the most recently received header
	ld hl,file_position		; point HL at current file position, 32 bits
	call eq32			; compare file_position with rx_header_data
	jp nz,rx_send_zrpos		; if values differ goto rx_send_zrpos
	call close_outfile		; ZEOF at the expected offset: close the file [rzfile: closeit]
	jr z,rx_got_zeof_2		; Success: clear state
rx_got_zeof_1:
	ld a,ZFERR			; A = 0CH
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 0CH (ZFERR)
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
rx_got_zeof_2:
	call clear_fcb			; zero the 37-byte FCB at HL
	ld a,ZEOF			; return ZEOF
	or a				; test A (sets Z if A = 0)
	ret				; return
; Bad or misplaced data: count the error, send the Attn string to stop the sender, then ZRPOS.
rx_data_error:
#IF RXSTATS
	call st_data_err		; statistics: CRC/framing or wrong position
#ENDIF
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
	ld hl,error_count		; point HL at consecutive error/retry counter
	ld a,0AH			; A = 0AH (LF)
	cp (hl)				; is consecutive error/retry counter = 0AH?
	jr nz,rx_data_error_1		; if not zero goto rx_data_error_1
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
rx_data_error_1:
	ld hl,attn_string		; error: send the Attn string to interrupt the sender's streaming [zmputs(Attn)]
	call send_string		; send the zero-terminated string at HL to the modem
	jp rx_send_zrpos		; loop back to rx_send_zrpos
; ZDATA: its offset must equal the bytes received so far, otherwise resynchronise with ZRPOS.
rx_got_zdata:
#IF RXSTATS
	ld hl,st_c_zdata		; statistics: ZDATA header received
	call inc32			; ...
#ENDIF
	ld de,rx_header_data		; point DE at four argument bytes of the most recently received header
	ld hl,file_position		; point HL at current file position, 32 bits
	call eq32			; compare file_position with rx_header_data
#IF RXSTATS
	call nz,st_set_pos		; statistics: note a wrong-position error (flags kept)
#ENDIF
	jp nz,rx_data_error		; if values differ goto rx_data_error
; Receive one data subpacket and act on how it ended (ZCRCE/G/Q/W).
rx_get_data:
	call spinner_entry		; show progress
#IF RXSTATS
	ld a,1				; statistics: now receiving a data subpacket
	ld (st_src),a			; ...
#ENDIF
	call rx_data_subpkt		; receive the next data subpacket [zrbdata]
	ld hl,rx_data_tab		; point HL at ZModem file receive
	ld bc,0007H			; 7 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jp rx_header_error		; loop back to rx_header_error
; Sender cancelled the session.
rx_got_cancel:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; Count the subpacket just received into the file position and save the buffer state.
advance_position:
	xor a				; Reset transfer error count to 0
	ld (error_count),a		; clear consecutive error/retry counter
	ld de,subpacket_len		; point DE at length of the last data subpacket
	ld hl,file_position		; point HL at current file position, 32 bits
	ld bc,file_position		; point BC at current file position, 32 bits
	call add32			; file_position = subpacket_len + file_position
	jp rx_pos_save			; continue at rx_pos_save
; ZCRCE: last subpacket of the frame; no reply, a header follows.
rx_got_crce:
#IF RXSTATS
	ld hl,st_c_crce			; statistics: subpacket ended with ZCRCE
	call inc32			; ...
#ENDIF
	call advance_position		; ZCRCE: end of frame, a header follows, no reply
#IF EARLYWR
	call rx_early_write		; write the buffer now if it is nearly full
	jp c,rx_got_zeof_1		; if disk write error goto rx_got_zeof_1
#ENDIF
	jp rx_wait_header		; loop back to rx_wait_header
; ZCRCG: more data follows immediately; no reply.
rx_got_crcg:
#IF RXSTATS
	ld hl,st_c_crcg			; statistics: subpacket ended with ZCRCG
	call inc32			; ...
#ENDIF
	call advance_position		; ZCRCG: more data follows, no reply
#IF EARLYWR
	call rx_early_write		; write the buffer now if it is nearly full
	jp c,rx_got_zeof_1		; if disk write error goto rx_got_zeof_1
#ENDIF
	jp rx_get_data			; loop back to rx_get_data
; ZCRCQ: more data follows; acknowledge the position with ZACK.
rx_got_crcq:
#IF RXSTATS
	ld hl,st_c_crcq			; statistics: subpacket ended with ZCRCQ
	call inc32			; ...
#ENDIF
	call advance_position		; ZCRCQ: more data follows, ZACK expected
#IF EARLYWR
	call rx_early_write		; write the buffer now if it is nearly full
	jp c,rx_got_zeof_1		; if disk write error goto rx_got_zeof_1
#ENDIF
#IF RXSTATS
	call st_zack_start		; statistics: start timing the ZACK
#ENDIF
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy file_position to tx_header_data
	ld a,ZACK			; frame type = ZACK
	call send_hex_header		; send a hex header
#IF RXSTATS
	call st_zack_end		; statistics: add the ZACK send time
#ENDIF
	jp rx_get_data			; loop back to rx_get_data
; ZCRCW: write the buffered data to disk and acknowledge with ZACK; the sender waits for it.
rx_got_crcw:
#IF RXSTATS
	ld hl,st_c_crcw			; statistics: subpacket ended with ZCRCW
	call inc32			; ...
#ENDIF
	call advance_position		; ZCRCW: sender waits for a reply (the buffer is written to disk now)
	call write_buf_file		; write the received data buffer to the file
	jp c,rx_got_zeof_1		; if disk write error goto rx_got_zeof_1
#IF RXSTATS
	call st_zack_start		; statistics: start timing the ZACK
#ENDIF
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy file_position to tx_header_data
	ld a,ZACK			; frame type = ZACK
	call send_hex_header		; send a hex header
#IF RXSTATS
	call st_zack_end		; statistics: add the ZACK send time
#ENDIF
	jp rx_wait_header		; loop back to rx_wait_header
#IF EARLYWR
; ----------------------------------------------------------------------
; rx_early_write: Write the receive buffer to the file now if it could
; not hold another maximum-size subpacket (EWTHRESH bytes).
;
; rz advertises its buffer size in ZRINIT and normally writes the buffer
; only when the sender ends a frame with ZCRCW.  Senders that ignore the
; advertised size and stream continuously (lrzsz 0.12.20 has that check
; disabled, and 0.12.21rc behaves the same) would overflow the buffer, forcing
; an error and resend at every buffer's worth of data.  While the buffer
; is written, the sender is held off by hardware flow control.
;
; Called at the end of a good ZCRCG, ZCRCQ or ZCRCE subpacket, after
; advance_position has saved the buffer state.  Returns CF set on a
; disk write error (from write_buf_file).
; ----------------------------------------------------------------------
rx_early_write:
	ld hl,(rx_buffer_size)		; HL := buffer size
	ld de,(rx_buffer_count)		; DE := bytes in buffer
	or a				; clear carry
	sbc hl,de			; HL := bytes free
	ld de,EWTHRESH			; enough room for another subpacket?
	or a				; clear carry
	sbc hl,de			; free - threshold
	ret nc				; if so, nothing to do (CF clear)
#IF RXSTATS
	ld hl,st_c_early		; statistics: early write
	call inc32			; ...
#ENDIF
	jp write_buf_file		; else write the buffer now (CF on error)
#ENDIF

; ZModem file receive: frame type of the header that arrived
rx_hdr_tab:
	.db ZNAK,0FEH,ZFILE,ZEOF,0FFH,ZDATA,0FCH	; keys: .......
	.dw rx_header_error		; key 0FCH too much junk
	.dw rx_got_zdata		; key 0AH ZDATA
	.dw rx_data_error		; key 0FFH error
	.dw rx_got_zeof			; key 0BH ZEOF
	.dw rx_got_zfile_2		; key 04H ZFILE
	.dw rx_header_error		; key 0FEH timeout
	.dw rx_header_error		; key 06H ZNAK
; ZModem file receive: result of a data subpacket
rx_data_tab:
	.db GOTCRCW,GOTCRCQ,GOTCRCG,GOTCRCE,0FFH,0FEH,ZCAN	; keys: .......
	.dw rx_got_cancel		; key 10H ZCAN
	.dw rx_header_error		; key 0FEH TIMEOUT
	.dw rx_data_error		; key 0FFH ERROR
	.dw rx_got_crce			; key 0E8H GOTCRCE
	.dw rx_got_crcg			; key 0E9H GOTCRCG
	.dw rx_got_crcq			; key 0EAH GOTCRCQ
	.dw rx_got_crcw			; key 0EBH GOTCRCW

; ----------------------------------------------------------------------
; close_outfile: Flush buffered data, pad to a sector, and close the
; output file. [rz.c closeit]
; ----------------------------------------------------------------------
close_outfile:
	call print_position		; print the current file position as a decimal number on
	call write_buf_file		; write the received data buffer to the file
	ret c				; return: disk write error
close_outfile_1:
	ld a,1AH			; CP/M EOF marker (Ctrl-Z = 1Ah)
	call file_putc			; write byte A to the file via the sector buffer
	ret c				; return: disk write error
	ld hl,file_buf_count		; point HL at output sector buffer
	ld a,01H			; A = 01H
	cp (hl)				; is output sector buffer = 01H?
	jr nz,close_outfile_1		; Continue padding until 128-byte boundary reached
	ld a,00H			; A = 00H
	ld (file_open_flag),a		; FFH while an output file is open = 00H (clear)
	ld c,F_CLOSE			; C = 10H
	ld de,work_fcb			; point DE at FCB for the file being received
	call BDOS			; close it
	; F_CLOSE returns a directory code 0-3 on success and FFH on
	; failure.  Callers test Z (ZMODEM) or CF (XMODEM), so return
	; Z/NC on success and NZ/C on failure.
	inc a				; FFH (failure) -> 0
	jr z,close_outfile_2		; ...
	xor a				; success: Z, CF clear
	ret
close_outfile_2:
	dec a				; failure: A := FFH, NZ
	scf				; ... CF set
	ret

; ----------------------------------------------------------------------
; write_buf_file: Write the received data buffer to the file.  All data
; is stored unchanged (binary). [rz.c putsec]
;
; This routine has been substantially updated to improve performance by 
; attempting to write entire records at a time minimizing copying of bytes 
; between buffers.  Whole 128-byte records are now written straight from 
; the receive buffer (the DMA address points into the buffer), one BDOS 
; write per record, with no byte copying.  A partial record left over 
; from the previous call (kept in file_sector_buf, length in file_buf_count)
; is completed first, and a remainder of under 128 bytes is kept there 
; for the next call, or for close_outfile, which pads it with ^Z and writes
; it through file_putc.
;
; Returns CF set on a disk write error.
; ----------------------------------------------------------------------
write_buf_file:
	ld bc,(rx_saved_count)		; BC = number of bytes received
	ld a,b				; nothing to write?
	or c				; A |= C
	ret z				; Return immediately if buffer empty
	ld hl,(rx_buffer_base)		; HL -> data
	ld (wbf_src),hl			; source pointer
	ld (wbf_left),bc		; bytes still to write
;
	; 1) complete a partial record left from an earlier call
	ld a,(file_buf_count)		; bytes already in the sector buffer
	or a				; any?
	jr z,wbf_records		; if not, go straight to whole records
	ld e,a				; E := bytes held
	ld a,80H			; room := 128 - bytes held
	sub e				; ...
	ld c,a				; BC := room
	ld b,0				; ...
	ld hl,(wbf_left)		; available >= room?
	ld a,h				; ... 256+ bytes: yes
	or a				; ...
	jr nz,wbf_part1			; ...
	ld a,l				; ...
	cp c				; ...
	jr nc,wbf_part1			; ...
	ld c,l				; no: take everything available
wbf_part1:
	ld a,b				; anything to copy?
	or c				; (not if the record is already full)
	jr z,wbf_part2			; ...
	push bc				; save count
	ld d,0				; DE := file_sector_buf + bytes held
	ld hl,file_sector_buf		; ...
	add hl,de			; ...
	ex de,hl			; ...
	ld hl,(wbf_src)			; HL := source
	ldir				; copy into the sector buffer
	ld (wbf_src),hl			; advance source
	pop bc				; count copied
	ld hl,(wbf_left)		; reduce bytes still to write
	or a				; ...
	sbc hl,bc			; ...
	ld (wbf_left),hl		; ...
	ld a,(file_buf_count)		; bytes held += count copied
	add a,c				; ...
	ld (file_buf_count),a		; ...
	ld (file_buf_wr),a		; ... (write index follows)
wbf_part2:
	ld a,(file_buf_count)		; record complete?
	cp 80H				; ...
	jr nz,wbf_done			; no: all data used, record stays partial
	ld de,file_sector_buf		; write the completed record
	ld b,1				; ...
	call wbf_write			; ...
	ret c				; disk error
	ld hl,file_buf_count		; sector buffer is empty again
	call file_buf_reset		; ...
;
	; 2) whole records straight from the receive buffer
wbf_records:
	ld hl,(wbf_left)		; records := bytes / 128 (at most 256, as
	add hl,hl			; the buffer is at most 32K): H := low 8
	ld b,h				; bits, CF := bit 8; B = 0 means 256
	jr c,wbf_rec1			; 256 records
	ld a,b				; any whole records?
	or a				; ...
	jr z,wbf_tail			; if not, only a remainder is left
wbf_rec1:
	ld de,(wbf_src)			; write B records from the source
	call wbf_write			; DE := address after the last record
	ret c				; disk error
	ld (wbf_src),de			; advance source
	ld a,(wbf_left)			; remainder := bytes MOD 128
	and 7FH				; ...
	ld l,a				; ...
	ld h,0				; ...
	ld (wbf_left),hl		; ...
;
	; 3) keep the remainder (under 128 bytes) for the next call; the
	; sector buffer is empty at this point
wbf_tail:
	ld bc,(wbf_left)		; remainder (B = 0)
	ld a,c				; any?
	or a				; ...
	jr z,wbf_done			; if not, done
	ld (file_buf_count),a		; bytes held
	ld (file_buf_wr),a		; write index follows
	ld hl,(wbf_src)			; copy to the sector buffer
	ld de,file_sector_buf		; ...
	ldir				; ...
wbf_done:
	call print_position		; show progress
	call rx_buffer_reset		; buffer is empty again
	xor a				; success
	ret				; return

; ----------------------------------------------------------------------
; wbf_write: Write B (1-256, B = 0 means 256) consecutive 128-byte
; records from DE to the output file, one record per BDOS write.  The DMA
; address is pointed at each record in place, so nothing is copied.
; Returns CF set on a disk write error, else DE := address after the
; last record.
; ----------------------------------------------------------------------
wbf_write:
	push bc				; save record count
	push de				; save record address
	ld c,F_DMAOFF			; DMA := this record
	call BDOS			; ...
	ld de,work_fcb			; write one record
	ld c,F_WRITE			; ...
	call BDOS			; A := 0 on success
	pop de				; restore record address
	pop bc				; restore record count
	or a				; success?
	scf				; assume not
	ret nz				; if not, return CF set (disk error)
	ld hl,128			; next record
	add hl,de			; ...
	ex de,hl			; ...
	djnz wbf_write			; loop for all records
	or a				; success: CF clear
	ret

wbf_src		.dw	0		; write_buf_file: source pointer
wbf_left	.dw	0		; write_buf_file: bytes still to write

; ----------------------------------------------------------------------
; file_putc: Write byte A to the file via the sector buffer.
; ----------------------------------------------------------------------
file_putc:
	ld (file_char),a		; save as character being stored into the sector buffer
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
file_putc_1:
	ld c,00H			; Load character byte into C
file_char		.equ file_putc_1+1	; character being stored into the sector buffer (patched operand)
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_put		; store byte C in the sector buffer
	jr nz,file_putc_2		; if byte stored goto file_putc_2
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_reset		; reset the 128-byte file sector buffer control block
	ld c,F_DMAOFF			; BDOS function: F_DMAOFF
	ld de,file_sector_buf		; point DE at 128-byte file sector buffer
	call BDOS			; F_DMAOFF: set the DMA (transfer) address
	ld c,F_WRITE			; C = 15H
	ld de,work_fcb			; point DE at FCB for the file being received
	call BDOS			; write the record, A := 0 on success
	or a				; written?
	jr z,file_putc_1		; if so, store the byte in the emptied buffer
	scf				; else return CF set (disk write error)
file_putc_2:
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; send_zfin_wait: Send ZFIN and wait for the sender's "OO" over-and-
; out. [rz.c ackbibi]
; ----------------------------------------------------------------------
send_zfin_wait:
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	call zero32			; clear tx_header_data
	ld b,04H			; B = 04H
send_zfin_wait_1:
	push bc				; preserve BC
	ld a,ZFIN			; frame type = ZFIN
	call send_hex_header		; send a hex header
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,send_zfin_wait_2		; if timed out waiting for the modem goto send_zfin_wait_2
	cp 4FH				; is it 'O'?
	jr z,send_zfin_wait_3		; if A is 'O' goto send_zfin_wait_3
	cp 0FDH				; compare A with 0FDH
	jr z,send_zfin_wait_3		; if A = FDH goto send_zfin_wait_3
send_zfin_wait_2:
	pop bc				; restore BC
	djnz send_zfin_wait_1		; repeat until all B items are done
	push bc				; preserve BC
send_zfin_wait_3:
	pop bc				; restore BC
	ld b,01H			; wait up to 0.1 s
	call aux_getc_timeout		; get a character from the modem with timeout
	xor a				; return 0 (success)
	ret				; return
; Ten CAN (18H) followed by ten backspaces, zero terminated
; Common data: identical in RZ and SZ.
cancel_string:
	.db 18H,18H,18H,18H,18H,18H,18H,18H,18H,18H,08H,08H,08H,08H,08H
	.db 08H,08H,08H,08H,08H,00H

; ----------------------------------------------------------------------
; send_can_string: Send eight+ CAN characters followed by backspaces to
; abort the peer. [canit]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
send_can_string:
	ld hl,cancel_string		; point HL at ten CAN
	call send_string		; send them
	jp hb_flush			; ... now

; ----------------------------------------------------------------------
; send_string: Send the zero-terminated string at HL to the modem. [rz.c
; zmputs]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
send_string:
	ld a,(hl)			; Load next string character
	inc hl				; Advance string pointer
	or a				; Test for null terminator (00h)
	ret z				; return: result is zero
	push hl				; preserve HL
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	pop hl				; restore HL
	jr send_string			; loop back to send_string

; ----------------------------------------------------------------------
; aux_getc_timeout: Get a character from the modem with timeout (B =
; tenths of a second, approximate: see aux_wait_input). Carry set on
; timeout; checks ESC at console.  Anything waiting in the transmit
; buffer is sent before waiting. [readline]
; ----------------------------------------------------------------------
aux_getc_timeout:
	; performance optimization: avoid ring buffer overhead if possible
	ld a,(pending_count)		; injected ESC/CAN characters waiting?
	or a
	jr nz,aux_getc_slow		; yes: normal path
	ld hl,(aux_ring)		; bytes queued in the ring?
	ld a,h
	or l
	jr z,aux_getc_direct		; no: read the port directly
	ld hl,aux_ring			; yes: take the next byte from the ring,
	call ring_get			; without polling the port (lets the ring drain)
	or a				; test A, carry clear
	ret
aux_getc_direct:
	ld a,(hb_rxcnt)			; byte in the block receive buffer?
	or a
	jr z,aux_getc_port		; no: ask the port
	dec a				; yes: take it here (as hb_cin does)
	ld (hb_rxcnt),a
	ld hl,(hb_rxptr)
	ld a,(hl)
	inc hl
	ld (hb_rxptr),hl
	or a				; carry clear
	ret
aux_getc_port:
	call hb_cinst			; status (refills an empty block buffer)
	or a
	jr z,aux_getc_slow		; nothing waiting: normal path (timeout, console check)
	call hb_cin			; read the byte (returned in E and C)
	ld a,e
	or a				; carry clear
	ret
aux_getc_slow:
	ld a,(hb_txcnt)			; anything waiting to be sent?
	or a				; ...
	jr z,aux_getc_1			; if not, go wait
	push bc				; preserve timeout count
	call hb_flush			; send it before waiting for a reply
	pop bc				; ...
aux_getc_1:
	call aux_chk_esc		; ESC at console? queue CANs
	call aux_wait_input		; wait one ~100 ms step
	jr nz,aux_getc_2		; input (or queued CANs) ready
	djnz aux_getc_1			; next step
	ld a,0FEH			; Timeout status code (0FEh)
	scf				; flag failure to caller (carry set)
	ret				; return
aux_getc_2:
	or a				; test A (sets Z if A = 0)
	ret				; return

; ----------------------------------------------------------------------
; aux_chk_esc: if ESC was typed at the console, queue CANs to abort.
; Skipped when the transfer runs on the console.  BC preserved.
; ----------------------------------------------------------------------
aux_chk_esc:
	ld a,(con_xfer)			; transfer on console?
	or a
	ret nz				; yes: no console check
	ld hl,(aux_ring)		; input already waiting?
	ld a,h
	or l
	ret nz				; yes: skip the check
	push bc
	call console_status
	call nz,console_read
	cp 1BH				; ESC?
	ld a,18H			; CAN
	ld c,0AH			; ten of them
	call z,set_pending_char
	pop bc
	ret

; ----------------------------------------------------------------------
; getc_7bit_filt: Get a modem char, strip bit 7 and ignore
; XON/XOFF/CR/LF/ZDLE. [zm.c noxrd7]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
getc_7bit_filt:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	and 7FH				; strip the parity bit (7-bit ASCII)
	ld hl,filter7_keys		; point HL at characters getc_7bit_filt ignores
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jr z,getc_7bit_filt		; if A is in the key list goto getc_7bit_filt
	ld bc,0003H			; 3 keys in the table
	cpir				; look A up in the key table
	ret z				; return: A is in the key list
	ld b,a				; Preserve character in B
	and 60H				; isolate bits 5-6: zero means a control character
	jr nz,getc_7bit_filt_1		; if result is nonzero goto getc_7bit_filt_1
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr nz,getc_7bit_filt		; if nonzero is set/nonzero goto getc_7bit_filt
getc_7bit_filt_1:
	ld a,b				; Restore received character in A
	ret				; return
; Characters getc_7bit_filt ignores (XON, XOFF) and those it accepts (CR, LF, ZDLE)
; Common data: identical in RZ and SZ.
filter7_keys:
	.db 11H,13H			; keys: ..
	.db 0DH,0AH
	.db 18H

; ----------------------------------------------------------------------
; getc_zdl_filt: Get a modem char, ignore XON/XOFF and decode ZDLE
; escapes. [zm.c zdlread]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
getc_zdl_filt:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	ld e,a				; Preserve character in E
	and 60H				; isolate bits 5-6: zero means a control character
	ld a,e				; Restore character into A
	ret nz				; return: result is nonzero
	cp ZDLE				; compare A with 18H (ZDLE/CAN)
	jr z,zdlread_escape		; if A = 18H goto zdlread_escape
	ld hl,zdl_ign_keys		; point HL at characters getc_zdl_filt ignores
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jr z,getc_zdl_filt		; if A is in the key list goto getc_zdl_filt
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr nz,getc_zdl_filt		; if nonzero is set/nonzero goto getc_zdl_filt
	ld a,e				; Return unescaped control character
	ret				; return

; ----------------------------------------------------------------------
; zdlread_escape: Decode the byte following a ZDLE (CAN) escape: frame-end
; codes, ZRUB0/ZRUB1, or XOR 40H. [zm.c zdlread]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
zdlread_escape:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,zdlread_escape_1		; if A is not ZDLE/CAN goto zdlread_escape_1
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,zdlread_escape_1		; if A is not ZDLE/CAN goto zdlread_escape_1
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,zdlread_escape_1		; if A is not ZDLE/CAN goto zdlread_escape_1
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
zdlread_escape_1:
	ld hl,zdl_esc_tab		; point HL at character that follows ZDLE
	ld bc,000BH			; 11 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	ld l,a				; Save character in L
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr z,zdlread_escape_2		; if nonzero is zero/clear goto zdlread_escape_2
	ld a,l				; Check bits 5-6
	and 60H				; isolate bits 5-6: zero means a control character
	jr z,zdlread_escape		; if result is zero goto zdlread_escape
zdlread_escape_2:
	ld a,l				; Load character
	and 60H				; isolate bits 5-6: zero means a control character
	cp 40H				; Escaped standard control character?
	jr nz,zdl_rub1_1		; if A != 40H goto zdl_rub1_1
	ld a,l				; Unescape: invert bit 6 (XOR 40h) to restore control code
	xor 40H				; undo ZDLE escaping (flip bit 6)
	ret				; return
; Common routine: identical in RZ and SZ.
zdl_rub0:
	ld a,7FH			; Escaped rubout / DEL (7Fh)
	ret				; return
; Common routine: identical in RZ and SZ.
zdl_rub1:
	ld a,0FFH			; Escaped 0FFh byte
	ret				; return
zdl_rub1_1:
	ld a,0FFH			; Framing error code
; Common routine: identical in RZ and SZ.
zdl_crc_end:
	or 80H				; set bit 7 (marks a received subpacket terminator)
	scf				; flag failure to caller (carry set)
	ret				; return
; Characters getc_zdl_filt ignores: XON and XOFF with and without bit 7
; Common data: identical in RZ and SZ.
zdl_ign_keys:
	.db 11H,91H,13H,93H		; keys: ....
; Character that follows ZDLE: ignored flow control, subpacket terminators, rubout codes, ZDLE
; Common data: identical in RZ and SZ.
zdl_esc_tab:
	.db 11H,91H,13H,93H,ZDLE,ZCRCE,ZCRCG,ZCRCQ,ZCRCW,ZRUB0,ZRUB1	; keys: .....hijklm
	.dw zdl_rub1			; key 6DH 'm'
	.dw zdl_rub0			; key 6CH 'l'
	.dw zdl_crc_end			; key 6BH 'k'
	.dw zdl_crc_end			; key 6AH 'j'
	.dw zdl_crc_end			; key 69H 'i'
	.dw zdl_crc_end			; key 68H 'h'
	.dw zdl_crc_end			; key 18H
	.dw zdlread_escape		; key 93H
	.dw zdlread_escape		; key 13H
	.dw zdlread_escape		; key 91H
	.dw zdlread_escape		; key 11H

; ----------------------------------------------------------------------
; rx_data_subpkt: Receive a ZMODEM data subpacket into the buffer,
; check its CRC and terminator. [zm.c zrdata]
; ----------------------------------------------------------------------
rx_data_subpkt:
	or a				; Clear carry
	ld hl,(rx_buffer_size)		; get size of the receive data buffer
	ld de,(rx_buffer_count)		; get number of bytes in the receive buffer
	sbc hl,de			; Check if buffer has remaining space
	jp c,rx_err_return		; if carry goto rx_err_return
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	ld hl,0000H			; HL = 0000H
	ld (subpacket_len),hl		; save as length of the last data subpacket
rx_data_subpkt_1:
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	jp c,rx_data_term		; if timeout, CAN or error goto rx_data_term
	call is_crc32_mode		; Z if the link is using 32-bit CRC
	call z,crc32_update		; if link uses 32-bit CRC: call crc32_update
	call nz,crc16_update		; if link uses 16-bit CRC: call crc16_update
	ld hl,(rx_buffer_size)		; get size of the receive data buffer
	ld bc,(rx_buffer_count)		; get number of bytes in the receive buffer
	sbc hl,bc			; HL -= BC + carry
	jp z,rx_err_return		; if link uses 32-bit CRC goto rx_err_return
	inc bc				; Advance buffer write count
	ld (rx_buffer_count),bc		; save as number of bytes in the receive buffer
	ld hl,(subpacket_len)		; get length of the last data subpacket
	inc hl				; HL++
	ld (subpacket_len),hl		; save as length of the last data subpacket
	ld hl,(rx_buffer_ptr)		; get next free byte in the receive buffer
	ld (hl),a			; (HL) = A
	inc hl				; Advance memory pointer
	ld (rx_buffer_ptr),hl		; save as next free byte in the receive buffer
	jr rx_data_subpkt_1		; loop back to rx_data_subpkt_1
; End of a data subpacket (CRC-16): terminator code and what to do
crc16_end_tab:
	.db GOTCRCE,GOTCRCG,GOTCRCQ,GOTCRCW,GOTCAN,0FFH,0FEH	; keys: .......
	.dw rx_timeout			; key 0FEH TIMEOUT
	.dw rx_err_return		; key 0FFH ERROR
	.dw rx_cancel			; key 98H GOTCAN
	.dw rx_end_crc16		; key 0EBH GOTCRCW
	.dw rx_end_crc16		; key 0EAH GOTCRCQ
	.dw rx_end_crc16		; key 0E9H GOTCRCG
	.dw rx_end_crc16		; key 0E8H GOTCRCE
; End of a data subpacket (CRC-32): terminator code and what to do
crc32_end_tab:
	.db GOTCRCE,GOTCRCG,GOTCRCQ,GOTCRCW,GOTCAN,0FFH,0FEH	; keys: .......
	.dw rx_timeout			; key 0FEH TIMEOUT
	.dw rx_err_return		; key 0FFH ERROR
	.dw rx_cancel			; key 98H GOTCAN
	.dw rx_end_crc32		; key 0EBH GOTCRCW
	.dw rx_end_crc32		; key 0EAH GOTCRCQ
	.dw rx_end_crc32		; key 0E9H GOTCRCG
	.dw rx_end_crc32		; key 0E8H GOTCRCE
rx_data_term:
	ld hl,crc32_end_tab		; point HL at end of a data subpacket
	ld bc,0007H			; 7 keys in the table
	call is_crc32_mode		; Z if the link is using 32-bit CRC
	jr z,rx_data_term_1		; if link uses 32-bit CRC goto rx_data_term_1
	ld hl,crc16_end_tab		; point HL at end of a data subpacket
	ld bc,0007H			; 7 keys in the table
rx_data_term_1:
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; Return an error (carry set, A = FFH).
rx_err_return:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
rx_timeout:
	scf				; flag failure to caller (carry set)
	ret				; return
rx_cancel:
	ld a,ZCAN			; A = 10H
	scf				; flag failure to caller (carry set)
	ret				; return
rx_end_crc16:
	ld (subpkt_term),a		; save as terminator of the last data subpacket
	and 7FH				; strip the parity bit (7-bit ASCII)
	call crc16_update		; update the running CRC-16
	ld b,02H			; repeat count = 2
rx_end_crc16_1:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	jp c,rx_data_term		; if carry goto rx_data_term
	djnz rx_end_crc16_1		; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,rx_end_crc16_3		; if the 16-bit count is zero goto rx_end_crc16_3
rx_end_crc16_2:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
rx_end_crc16_3:
	ld a,(subpkt_term)		; get terminator of the last data subpacket
	or a				; Clear carry (success)
	ret				; return
rx_end_crc32:
	ld (subpkt_term),a		; save as terminator of the last data subpacket
	and 7FH				; strip the parity bit (7-bit ASCII)
	call crc32_update		; update the running CRC-32 with byte A
	ld b,04H			; repeat count = 4
rx_end_crc32_1:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop bc				; restore BC
	jp c,rx_data_term		; if carry goto rx_data_term
	djnz rx_end_crc32_1		; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld de,crc32_residue		; point DE at CRC-32 residue 0DEBB20E3H expected after a good frame
	call eq32			; compare crc32_value with crc32_residue
	jp z,rx_end_crc16_3		; if values are equal goto rx_end_crc16_3
	jp rx_end_crc16_2		; loop back to rx_end_crc16_2

; ----------------------------------------------------------------------
; is_crc32_mode: Z if the link is using 32-bit CRC (flag 20H).
; ----------------------------------------------------------------------
is_crc32_mode:
	ld e,a				; Preserve A in E
	ld a,(rx_crc_mode)		; get link CRC type
	cp 20H				; Compare with 20h (CRC-32)
	ld a,e				; Restore A
	ret				; return

; ----------------------------------------------------------------------
; rx_buffer_reset: Reset the receive buffer pointers to the start.
; ----------------------------------------------------------------------
rx_buffer_reset:
	ld hl,rx_buffer_base		; point HL at start address of the receive data buffer
	ld de,rx_buffer_ptr		; point DE at next free byte in the receive buffer
	ldi				; Copy low byte
	ldi				; Copy high byte
	ld hl,0000H			; Reset buffer offset high word to 0
	ld (rx_buffer_count),hl		; save as number of bytes in the receive buffer

; ----------------------------------------------------------------------
; rx_pos_save: Save buffer pointer/count.
; ----------------------------------------------------------------------
rx_pos_save:
	ld hl,rx_buffer_ptr		; point HL at next free byte in the receive buffer
	ld de,rx_saved_ptr		; point DE at saved receive buffer pointer
rx_pos_save_1:
	ldi				; Copy byte 0
	ldi				; Copy byte 1
	ldi				; Copy byte 2
	ldi				; Copy byte 3
	ret				; return

; ----------------------------------------------------------------------
; rx_pos_restore: Restore buffer pointer/count.
; ----------------------------------------------------------------------
rx_pos_restore:
	ld hl,rx_saved_ptr		; point HL at saved receive buffer pointer
	ld de,rx_buffer_ptr		; point DE at next free byte in the receive buffer
	jr rx_pos_save_1		; loop back to rx_pos_save_1

; ----------------------------------------------------------------------
; get_header: Receive a ZMODEM header (hex, binary16 or binary32); returns
; frame type in A, carry on error. [zm.c zgethdr]
; ----------------------------------------------------------------------
get_header:
	xor a				; A = 0
	ld (rx_frame_type),a		; clear frame type of the last header received
	ld hl,0400H			; give up after 1024 junk characters without a header
	ld (hdr_junk_limit),hl		; save as remaining number of junk characters tolerated
get_header_1:
	ld a,05H			; five CANs in a row mean "session cancelled" [zgethdr: cancount = 5]
	ld (hdr_can_count),a		; remaining CAN characters before abort = 05H
get_header_2:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jp c,hdr_return			; if timed out waiting for the modem goto hdr_return
	ld hl,hdr_idle_tab		; point HL at header scan, idle state
	ld bc,0003H			; 3 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr hdr_zdle_zcrcw_1		; continue at hdr_zdle_zcrcw_1
; Common routine: identical in RZ and SZ.
hdr_got_zdle:
	ld hl,hdr_can_count		; point HL at remaining CAN characters before abort
	dec (hl)			; count down remaining CAN characters before abort
	ld a,ZCAN			; CAN limit reached: report ZCAN
	jp z,hdr_return			; if remaining CAN characters before abort has run out goto hdr_return
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,get_header_2		; if timed out waiting for the modem goto get_header_2
	ld hl,hdr_zdle_tab		; point HL at header scan, after ZDLE
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr hdr_zdle_zcrcw_1		; continue at hdr_zdle_zcrcw_1
; A second ZDLE: count a CAN; five in a row return ZCAN.
; Common routine: identical in RZ and SZ.
hdr_zdle_zdle:
	ld hl,hdr_can_count		; point HL at remaining CAN characters before abort
	dec (hl)			; count down remaining CAN characters before abort
	ld a,ZCAN			; CRC-16 header: remember the CRC type
	jp z,hdr_return			; if remaining CAN characters before abort has run out goto hdr_return
	jr get_header_2			; loop back to get_header_2
; ZDLE then ZCRCW: wait briefly for one more character, otherwise return an error.
; Common routine: identical in RZ and SZ.
hdr_zdle_zcrcw:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,hdr_zdle_zcrcw_2		; if timed out waiting for the modem goto hdr_zdle_zcrcw_2
hdr_zdle_zcrcw_1:
	ld hl,(hdr_junk_limit)		; get remaining number of junk characters tolerated
	dec hl				; HL--
	ld (hdr_junk_limit),hl		; save as remaining number of junk characters tolerated
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	ld a,0FCH			; junk limit reached: no header found
	jp z,hdr_return			; if the 16-bit count is zero goto hdr_return
	jp get_header_1			; loop back to get_header_1
hdr_zdle_zcrcw_2:
	ld a,0FFH			; Timeout error status
	jp hdr_return			; continue at hdr_return
; Common routine: identical in RZ and SZ.
hdr_got_zpad:
	ld a,05H			; A = 05H
	ld (hdr_can_count),a		; remaining CAN characters before abort = 05H
; Another ZPAD: keep waiting for ZDLE.
; Common routine: identical in RZ and SZ.
hdr_pad_loop:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	jr c,hdr_return			; if timeout or error goto hdr_return
	ld hl,hdr_pad_tab		; point HL at header scan, after ZPAD
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr hdr_zdle_zcrcw_1		; loop back to hdr_zdle_zcrcw_1
; Common routine: identical in RZ and SZ.
hdr_zpad_zdle:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	jr c,hdr_return			; if timeout or error goto hdr_return
	ld hl,hdr_fmt_tab		; point HL at header scan, after ZPAD ZDLE
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr hdr_zdle_zcrcw_1		; loop back to hdr_zdle_zcrcw_1
; Common routine: identical in RZ and SZ.
hdr_hex:
	ld a,10H			; CRC-16 header: remember the CRC type
	ld (rx_crc_mode),a		; link CRC type = 10H (CRC-16)
	call get_hex_header		; receive a hex-encoded header
	jr hdr_bin32_1			; continue at hdr_bin32_1
; Common routine: identical in RZ and SZ.
hdr_bin16:
	ld a,10H			; CRC format = 16-bit CRC (10h)
	ld (rx_crc_mode),a		; link CRC type = 10H (CRC-16)
	call get_bin16_header		; receive a binary header with 16-bit CRC
	jr hdr_bin32_1			; continue at hdr_bin32_1
hdr_bin32:
	ld a,20H			; CRC-32 header (ZBIN32): remember the CRC type
	ld (rx_crc_mode),a		; link CRC type = 20H (CRC-32)
	call get_bin32_header		; receive a binary header with 32-bit CRC
hdr_bin32_1:
	push af				; preserve AF
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld de,rx_header_copy		; point DE at copy of the received header arguments
	call copy32			; copy rx_header_data to rx_header_copy
	pop af				; restore AF
; Common routine: identical in RZ and SZ.
hdr_return:
	ld hl,hdr_ret_keys		; point HL at header results that are returned with carry set
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jr nz,hdr_return_2		; if A is not in the key list goto hdr_return_2
	cp GOTCAN			; Special error status?
	jr nz,hdr_return_1		; if A != 98H goto hdr_return_1
	ld a,ZCAN			; return ZCAN
hdr_return_1:
	scf				; error/timeout/cancel: carry set
	ret				; return
hdr_return_2:
	or a				; Clear carry (success)
	ret				; return
; Header scan, idle state: ZPAD or ZDLE starts a header
; Common data: identical in RZ and SZ.
hdr_idle_tab:
	.db ZDLE,ZPAD+80H,ZPAD		; keys: ..*
	.dw hdr_got_zpad		; key 2AH ZPAD
	.dw hdr_got_zpad		; key 0AAH ZPAD (bit 7 set)
	.dw hdr_got_zdle		; key 18H ZDLE
; Header scan, after ZDLE: another ZDLE or ZCRCW
; Common data: identical in RZ and SZ.
hdr_zdle_tab:
	.db ZCRCW,ZDLE			; keys: k.
	.dw hdr_zdle_zdle		; key 18H ZDLE
	.dw hdr_zdle_zcrcw		; key 6BH ZCRCW after CAN: no header follows
; Header scan, after ZPAD: another ZPAD or ZDLE
; Common data: identical in RZ and SZ.
hdr_pad_tab:
	.db ZPAD,ZDLE			; keys: *.
	.dw hdr_zpad_zdle		; key 18H ZDLE
	.dw hdr_pad_loop		; key 2AH ZPAD
; Header scan, after ZPAD ZDLE: format character (ZBIN, ZHEX, ZBIN32) or ZDLE
; Common data: identical in RZ and SZ.
hdr_fmt_tab:
	.db ZBIN32,ZBIN,ZHEX,ZDLE	; keys: CAB.
	.dw hdr_got_zdle		; key 18H ZDLE
	.dw hdr_hex			; key 42H ZHEX (hex header)
	.dw hdr_bin16			; key 41H ZBIN (binary header, CRC-16)
	.dw hdr_bin32			; key 43H ZBIN32 (binary header, CRC-32)
; Header results that are returned with carry set
; Common data: identical in RZ and SZ.
hdr_ret_keys:
	.db GOTCAN,ZNAK,ZCAN,0FFH,0FEH,0FCH	; keys: ......

; ----------------------------------------------------------------------
; get_bin32_header: Receive a binary header with 32-bit CRC. [zm.c
; zrbhdr32]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
get_bin32_header:
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	ret c				; return: timeout, CAN or error
	ld (rx_frame_type),a		; save as frame type of the last header received
	call crc32_update		; update the running CRC-32 with byte A
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld b,04H			; 4 bytes to read
get_bin32_1:
	push bc				; preserve BC
	push hl				; preserve HL
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	ret c				; Return on read error
	djnz get_bin32_1		; repeat until all B items are done
	ld b,04H			; repeat count = 4
get_bin32_2:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop bc				; restore BC
	ret c				; Return on read error
	djnz get_bin32_2		; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld de,crc32_residue		; point DE at CRC-32 residue 0DEBB20E3H expected after a good frame
	call eq32			; compare crc32_value with crc32_residue
	jr z,get_bin16_3		; if values are equal goto get_bin16_3
	jr get_bin16_4			; continue at get_bin16_4

; ----------------------------------------------------------------------
; get_bin16_header: Receive a binary header with 16-bit CRC. [zm.c zrbhdr]
; ----------------------------------------------------------------------
get_bin16_header:
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	ret c				; return: timeout, CAN or error
	ld (rx_frame_type),a		; save as frame type of the last header received
	call crc16_update		; update the running CRC-16
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld b,04H			; 4 bytes to read
get_bin16_1:
	push bc				; preserve BC
	push hl				; preserve HL
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	ret c				; Return on read error
	djnz get_bin16_1		; repeat until all B items are done
	ld b,02H			; repeat count = 2
get_bin16_2:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	ret c				; Return on read error
	djnz get_bin16_2		; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,get_bin16_4		; if the 16-bit count is not zero goto get_bin16_4
get_bin16_3:
	ld a,0FFH			; A = 0FFH
	ld (header_ok_flag),a		; FFH once a valid header has been received = FFH (set)
	ld a,(rx_frame_type)		; get frame type of the last header received
	ret				; return
get_bin16_4:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; get_hex_header: Receive a hex-encoded header. [zm.c zrhhdr]
; ----------------------------------------------------------------------
get_hex_header:
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	call get_hex_byte		; receive two hex digits and combine them into a byte
	ret c				; Return on error
	ld (rx_frame_type),a		; save as frame type of the last header received
	call crc16_update		; update the running CRC-16
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld b,04H			; 4 bytes to read
get_hex_header_1:
	push bc				; preserve BC
	push hl				; preserve HL
	call get_hex_byte		; receive two hex digits and combine them into a byte
	jr nc,get_hex_header_2		; If byte received successfully, proceed
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return
get_hex_header_2:
	call crc16_update		; update the running CRC-16
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	djnz get_hex_header_1		; repeat until all B items are done
	ld b,02H			; Read 2 CRC-16 hex bytes
get_hex_header_3:
	push bc				; preserve BC
	call get_hex_byte		; receive two hex digits and combine them into a byte
	jr nc,get_hex_header_4		; If valid hex, process
	pop bc				; restore BC
	ret				; return
get_hex_header_4:
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	djnz get_hex_header_3		; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,get_hex_header_6		; if the 16-bit count is not zero goto get_hex_header_6
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	cp 0DH				; is it CR?
	jr nz,get_hex_header_5		; if A is not CR goto get_hex_header_5
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
get_hex_header_5:
	or a				; Clear carry (success)
	ld a,0FFH			; A = 0FFH
	ld (header_ok_flag),a		; FFH once a valid header has been received = FFH (set)
	ld a,(rx_frame_type)		; get frame type of the last header received
	ret				; return
get_hex_header_6:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; get_hex_byte: Receive two hex digits and combine them into a byte. [zm.c
; zgethex]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
get_hex_byte:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	ret c				; return: timeout or error
	call hex_digit_value		; convert an ASCII hex digit in A to 0-15
	jr nz,get_hex_byte_1		; Error if invalid hex character
	rlca				; Shift high nibble into bits 4-7
	rlca				; rotate A left
	rlca				; rotate A left
	rlca				; rotate A left
	ld b,a				; Save high nibble in B
	push bc				; preserve BC
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	pop bc				; restore BC
	ret c				; return: timeout or error
	call hex_digit_value		; convert an ASCII hex digit in A to 0-15
	jr nz,get_hex_byte_1		; Error if invalid hex character
	or b				; Merge high nibble from B with low nibble in A
	ret				; return
get_hex_byte_1:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; hex_digit_value: Convert an ASCII hex digit in A to 0-15.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
hex_digit_value:
	ld l,a				; Save original character in L
	sub 30H				; Subtract ASCII '0' offset
	cp 0AH				; In digit range '0'-'9'?
	jr c,hex_digit_1		; if A < 0AH goto hex_digit_1
	sub 27H				; Subtract offset for lowercase 'a'-'f'
hex_digit_1:
	ld l,a				; Save nibble value in L
	and 0F0H			; keep the high nibble
	ld a,l				; Return nibble in A
	ret				; return

; ----------------------------------------------------------------------
; xmodem_rx_start: Send the initial NAK or C to start XMODEM/YMODEM
; reception and read the first block. [rz.c wcrxpn]
; ----------------------------------------------------------------------
xmodem_rx_start:
	ld a,0FFH			; A = 0FFH
	ld (xm_first_flag),a		; FFH until the first valid XMODEM block has arrived = FFH (set)
	call rx_buffer_reset		; reset the receive buffer pointers to the start
	ld a,(rx_crc_mode)		; get link CRC type
	cp 10H				; compare A with 10H
	ld a,43H			; A = 43H ('C')
	jr z,xmodem_rx_1		; if A = 10H goto xmodem_rx_1
	ld a,15H			; character to send: NAK
xmodem_rx_1:
	call aux_putc_wait		; ask for CRC-16 with "C" (or checksum with NAK) [sendline(WANTCRC / NAK)]
	ld b,64H			; Timeout = 100 ticks
	call xmodem_get_block		; read block 0 (file name and size) [wcrxpn: wcgetsec]
	or a				; Test response status code
	jr z,xmodem_rx_3		; if result is zero goto xmodem_rx_3
	cp 0F6H				; WCEOT: EOT received (end of the previous file)?
	jr z,xmodem_rx_2		; if A = F6H goto xmodem_rx_2
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
xmodem_rx_2:
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; acknowledge
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr xmodem_rx_start		; loop back to xmodem_rx_start
xmodem_rx_3:
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; xmodem_rx_file: Receive all blocks of an XMODEM/YMODEM file. [rz.c
; wcrx]
; ----------------------------------------------------------------------
xmodem_rx_file:
	ld a,0FFH			; A = 0FFH
	ld (xm_first_flag),a		; FFH until the first valid XMODEM block has arrived = FFH (set)
	xor a				; A = 0
	ld (xm_block_no),a		; clear expected XMODEM block number
	call rx_buffer_reset		; reset the receive buffer pointers to the start
	ld hl,file_position		; point HL at current file position, 32 bits
	call zero32			; clear file_position
	ld a,(rx_crc_mode)		; get link CRC type
	cp 10H				; compare A with 10H
	ld a,43H			; A = 43H ('C')
	jr z,xmodem_rx_file_1		; if A = 10H goto xmodem_rx_file_1
	ld a,15H			; character to send: NAK
xmodem_rx_file_1:
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
xmodem_rx_file_2:
	ld a,(xm_block_no)		; get expected XMODEM block number
	or a				; test A (sets Z if A = 0)
	ld b,82H			; first block: wait up to 13 s [wcrx: (sectnum&0177)?50:130]
	jr z,xmodem_rx_file_3		; if expected XMODEM block number is zero/clear goto xmodem_rx_file_3
	ld b,32H			; later blocks: wait up to 5 s
xmodem_rx_file_3:
	call xmodem_get_block		; receive one block [wcgetsec]
	jr c,xmodem_rx_file_5		; if receive error goto xmodem_rx_file_5
	push af				; preserve AF
	call print_position		; print the current file position as a decimal number on
	pop af				; restore AF
	ld hl,xm_block_no		; point HL at expected XMODEM block number
	cp (hl)				; block number as expected? [sectcurr == sectnum+1]
	jr z,xmodem_rx_file_4		; if zero goto xmodem_rx_file_4
	dec a				; A--
	cp (hl)				; repeat of the previous block (our ACK was lost)? [Received dup Sector]
	jr nz,xmodem_rx_file_6		; if not zero goto xmodem_rx_file_6
	inc (hl)			; count up expected XMODEM block number
	ld de,rx_buffer_count		; point DE at number of bytes in the receive buffer
	ld hl,file_position		; point HL at current file position, 32 bits
	ld bc,file_position		; point BC at current file position, 32 bits
	call add32			; file_position = rx_buffer_count + file_position
	call rx_pos_save		; save buffer pointer/count
	call write_buf_file		; new block: append its data to the file [putsec]
	jr c,xmodem_rx_file_7		; if disk write error goto xmodem_rx_file_7
xmodem_rx_file_4:
	call rx_pos_restore		; restore buffer pointer/count
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	jr xmodem_rx_file_2		; loop back to xmodem_rx_file_2
xmodem_rx_file_5:
	cp 0F6H				; WCEOT: EOT received: end of file
	jr nz,xmodem_rx_file_6		; if A != F6H goto xmodem_rx_file_6
	call close_outfile		; close the file and acknowledge the EOT [closeit; sendline(ACK)]
	jr c,xmodem_rx_file_7		; if disk error closing file goto xmodem_rx_file_7
	call clear_fcb			; zero the 37-byte FCB at HL
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	xor a				; return 0 (success)
	ret				; return
xmodem_rx_file_6:
	cp 0FFH				; compare A with 0FFH
	jr nz,xmodem_rx_file_7		; if A != FFH goto xmodem_rx_file_7
	ld a,(xm_first_flag)		; get FFH until the first valid XMODEM block has arrived
	cp 0FFH				; compare A with 0FFH
	jr nz,xmodem_rx_file_7		; if A != FFH goto xmodem_rx_file_7
	ld a,(rx_crc_mode)		; get link CRC type
	or a				; test A (sets Z if A = 0)
	jr z,xmodem_rx_file_7		; if link CRC type is zero/clear goto xmodem_rx_file_7
	xor a				; A = 0
	ld (rx_crc_mode),a		; clear link CRC type
	jp xmodem_rx_file		; no CRC block arrived: fall back to checksum mode and start over [wcgetsec: Crcflg]
xmodem_rx_file_7:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; xmodem_get_block: Read one XMODEM block (SOH/STX/EOT/CAN) with its
; checksum or CRC. [rz.c wcgetsec]
; ----------------------------------------------------------------------
xmodem_get_block:
	ld a,b				; Save timeout counter
	ld (xm_timeout),a		; save as XMODEM receive timeout in tenths of a second
	xor a				; Reset transfer error count to 0
	ld (error_count),a		; clear consecutive error/retry counter
	ld a,00H			; A = 00H
	ld (xm_can_flag),a		; set after one CAN, abort on the second = 00H (clear)
xmodem_get_1:
#IF RXSTATS
	ld a,1				; statistics: stage 1, waiting for start character
	ld (st_xstage),a		; ...
#ENDIF
	ld a,(xm_timeout)		; get XMODEM receive timeout in tenths of a second
	ld b,a				; B = A
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	ld hl,xm_start_tab		; point HL at XModem receive
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jp xm_bad_block			; continue at xm_bad_block
; XModem receive: block start character (STX, SOH, EOT, CAN)
xm_start_tab:
	.db 02H,01H,04H,18H		; keys: ....
	.dw xm_got_can			; key 18H CAN
	.dw xm_got_eot			; key 04H EOT
	.dw xm_got_soh			; key 01H SOH (128-byte block)
	.dw xm_got_stx			; key 02H STX (1024-byte block)

; ----------------------------------------------------------------------
; xm_got_stx: XMODEM: 1024-byte block start.
; ----------------------------------------------------------------------
xm_got_stx:
	ld hl,0400H			; HL = 0400H
	jr xm_got_soh_1			; continue at xm_got_soh_1

; ----------------------------------------------------------------------
; xm_got_soh: XMODEM: 128-byte block start.
; ----------------------------------------------------------------------
xm_got_soh:
	ld hl,0080H			; 128-byte block
xm_got_soh_1:
	ld (xm_block_len),hl		; bytes still to read
#IF RXSTATS
	ld a,2				; statistics: stage 2, block number / complement
	ld (st_xstage),a		; ...
#ENDIF
	ld b,0AH			; wait up to 1 s for each byte
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (xm_blk_no_rx),a		; block number
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; complement of the block number
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
xm_got_soh_2:
	add a,00H			; block number + complement ...
xm_blk_no_rx		.equ xm_got_soh_2+1	; received XMODEM block number (patched operand)
	cp 0FFH				; ... must be FFH
	jp nz,xm_bad_block		; if A != FFH goto xm_bad_block
#IF RXSTATS
	ld a,3				; statistics: stage 3, data bytes
	ld (st_xstage),a		; ...
#ENDIF
	call crc_init			; start the CRC / checksum
	ld ix,(rx_buffer_ptr)		; IX = where the data goes
xm_got_soh_3:
	ld b,0AH			; Timeout = 10 ticks
	push ix				; preserve IX
	call aux_getc_timeout		; read a data byte
	pop ix				; restore IX
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	ld (ix+0),a			; store it
	inc ix				; Advance buffer pointer
	call checksum_add		; update the checksum ...
	call crc16_update		; ... and the CRC
	ld bc,(rx_buffer_count)		; get number of bytes in the receive buffer
	inc bc				; BC++
	ld (rx_buffer_count),bc		; one more byte in the buffer
	ld de,(xm_block_len)		; get XMODEM bytes still to read in the current block
	dec de				; DE--
	ld (xm_block_len),de		; save as XMODEM bytes still to read in the current block
	ld a,d				; block complete?
	or e				; A |= E
	jr nz,xm_got_soh_3		; if not zero goto xm_got_soh_3
	ld (rx_buffer_ptr),ix		; save the new buffer pointer
#IF RXSTATS
	ld a,4				; statistics: stage 4, CRC / checksum bytes
	ld (st_xstage),a		; ...
#ENDIF
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; read the checksum or CRC high byte
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	ld a,(rx_crc_mode)		; CRC mode?
	cp 10H				; compare A with 10H
	jr nz,xm_got_soh_5		; no: checksum
	ld a,(xm_rx_char)		; get last character received in XMODEM block handling
	call crc16_update		; update the running CRC-16
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; CRC low byte
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	call crc16_update		; update the running CRC-16
	ld a,h				; CRC over data + CRC must be zero
	or l				; A = H or L: zero only if HL = 0
#IF RXSTATS
	ld a,5				; statistics: stage 5, CRC mismatch (flags kept)
	ld (st_xstage),a		; ...
#ENDIF
	jp nz,xm_bad_block		; if the 16-bit count is not zero goto xm_bad_block
xm_got_soh_4:
	xor a				; good block: clear the error count
	ld (error_count),a		; clear consecutive error/retry counter
	ld a,00H			; no longer waiting for the first block
	ld (xm_first_flag),a		; FFH until the first valid XMODEM block has arrived = 00H (clear)
	ld a,(xm_blk_no_rx)		; return the block number
	ret				; return
xm_got_soh_5:
	ld a,(xm_rx_char)		; checksum mode: compare with our checksum
	ld l,a				; L = A
	ld a,(xm_checksum)		; get running 8-bit XMODEM checksum
	sub l				; A -= L
	jr z,xm_got_soh_4		; match: good block
#IF RXSTATS
	ld a,5				; statistics: stage 5, checksum mismatch
	ld (st_xstage),a		; ...
#ENDIF
	jp xm_bad_block			; continue at xm_bad_block

; ----------------------------------------------------------------------
; xm_got_eot: XMODEM: EOT received.
; ----------------------------------------------------------------------
xm_got_eot:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld a,0F6H			; A = 0F6H
	ret c				; return: timed out waiting for the modem
#IF RXSTATS
	ld a,6				; statistics: stage 6, junk after EOT
	ld (st_xstage),a		; ...
#ENDIF
	jp xm_bad_block			; continue at xm_bad_block

; ----------------------------------------------------------------------
; xm_got_can: XMODEM: CAN received.
; ----------------------------------------------------------------------
xm_got_can:
#IF RXSTATS
	ld a,7				; statistics: stage 7, CAN received
	ld (st_xstage),a		; ...
#ENDIF
	ld a,0FFH			; A = 0FFH
	ld hl,xm_can_flag		; point HL at set after one CAN, abort on the second
	cp (hl)				; is set after one CAN, abort on the second = FFH?
	jr nz,xm_got_can_1		; if not zero goto xm_got_can_1
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
xm_got_can_1:
	ld (hl),a			; (HL) = A
	jp xm_bad_block_4		; continue at xm_bad_block_4

; ----------------------------------------------------------------------
; xm_bad_block: XMODEM: bad block, discard input and NAK.
; ----------------------------------------------------------------------
xm_bad_block:
	ld a,00H			; A = 00H
	ld (xm_can_flag),a		; set after one CAN, abort on the second = 00H (clear)
xm_bad_block_1:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr nc,xm_bad_block_1		; if a character arrived goto xm_bad_block_1
	ld a,(xm_first_flag)		; get FFH until the first valid XMODEM block has arrived
	cp 0FFH				; compare A with 0FFH
	jr nz,xm_bad_block_2		; if A != FFH goto xm_bad_block_2
	ld a,(rx_crc_mode)		; get link CRC type
	cp 10H				; compare A with 10H
	ld a,43H			; A = 43H ('C')
	jr z,xm_bad_block_3		; if A = 10H goto xm_bad_block_3
	ld a,15H			; A = 15H
	jr xm_bad_block_3		; continue at xm_bad_block_3
xm_bad_block_2:
	ld a,28H			; Timeout = 40 ticks
	ld (xm_timeout),a		; XMODEM receive timeout in tenths of a second = 28H
	ld a,15H			; character to send: NAK
xm_bad_block_3:
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
xm_bad_block_4:
#IF RXSTATS
	ld hl,st_e_xm			; statistics: XMODEM error
	call inc32			; ...
	call st_logxm			; ... and record its details
#ENDIF
	call rx_pos_restore		; restore buffer pointer/count
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
	ld a,(error_count)		; get consecutive error/retry counter
	cp 05H				; compare A with 05H
	jp nz,xmodem_get_1		; if A != 05H goto xmodem_get_1
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; send_hex_header: Send a hex header: frame type in A, four argument bytes
; from the header buffer, CRC-16, CR LF. [zm.c zshhdr]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
send_hex_header:
	ld (tx_frame_type),a		; save as frame type of the header being sent
	ld hl,hex_hdr_prefix		; point HL at ZPAD ZPAD ZDLE ZHEX, introduces a hex header
	call send_string		; send the zero-terminated string at HL to the modem
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	ld a,(tx_frame_type)		; get frame type of the header being sent
	call crc16_update		; update the running CRC-16
	call put_hex_byte		; send A as two lowercase hex digits
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	ld b,04H			; Loop counter = 4 bytes
send_hex_1:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; Advance pointer
	push hl				; preserve HL
	call crc16_update		; update the running CRC-16
	call put_hex_byte		; send A as two lowercase hex digits
	pop hl				; restore HL
	pop bc				; restore BC
	djnz send_hex_1			; repeat until all B items are done
	ld a,(crc16_hi)			; get CRC-16 high byte
	call put_hex_byte		; send A as two lowercase hex digits
	ld a,(crc16_lo)			; get CRC-16 low byte
	call put_hex_byte		; send A as two lowercase hex digits
	ld a,0DH			; character to send: CR
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,0AH			; character to send: LF
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(tx_frame_type)		; get frame type of the header being sent
	cp ZFIN				; is it ZFIN?
	jr z,send_hex_2			; ZFIN: no XON
	ld a,11H			; A = 11H (XON)
	call aux_putc_wait		; send it
send_hex_2:
	jp hb_flush			; send the whole header now
; ZPAD ZPAD ZDLE ZHEX, introduces a hex header
; Common data: identical in RZ and SZ.
hex_hdr_prefix:
	.db ZPAD,ZPAD,ZDLE,ZHEX,00H
; "0123456789abcdef"
; Common data: identical in RZ and SZ.
hex_digits:
	.db "0123456789abcdef"

; ----------------------------------------------------------------------
; put_hex_byte: Send A as two lowercase hex digits. [zm.c zputhex]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
put_hex_byte:
	push af				; preserve AF
	ld hl,hex_digits		; point HL at "0123456789abcdef"
	ld b,00H			; BC = high nibble offset
	rra				; Shift high nibble into low 4 bits
	rra				; rotate A right through carry
	rra				; rotate A right through carry
	rra				; rotate A right through carry
	and 0FH				; keep the low nibble
	ld c,a				; Set offset
	add hl,bc			; Index into hex digits string
	ld a,(hl)			; get a byte of "0123456789abcdef"
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	pop af				; restore AF
	ld hl,hex_digits		; point HL at "0123456789abcdef"
	ld b,00H			; BC = low nibble offset
	and 0FH				; keep the low nibble
	ld c,a				; Set offset
	add hl,bc			; Index into hex digits string
	ld a,(hl)			; get a byte of "0123456789abcdef"
	jp aux_putc_wait		; continue at aux_putc_wait

; ----------------------------------------------------------------------
; aux_putc_wait: Send A to the modem.  In block mode the byte is queued
; in the transmit buffer, which is sent with BF_CIOBLKOUT when it fills,
; at the end of each hex header or CAN string, and before any wait for
; input (hb_flush).  In byte mode, input is polled while waiting for the
; output to be ready, then the byte is sent.
; ----------------------------------------------------------------------
aux_putc_wait:
	ld (aux_out_char),a		; save as last character sent to the modem
	ld e,a				; E := character
	ld a,(hb_blkok)			; block output in use?
	or a				; ...
	jr z,aux_putc_wait_1		; if not, byte mode
	ld hl,(hb_txptr)		; append to the transmit buffer
	ld (hl),e			; ...
	inc hl				; ...
	ld (hb_txptr),hl		; ...
	ld hl,hb_txcnt			; one more byte queued
	inc (hl)			; ...
	ld a,(hl)			; buffer full?
	cp TXBUFSZ - 1			; ... (BF_CIOBLKOUT sends at most 255)
	ret c				; if not, done
	jp hb_flush			; full: send it now
aux_putc_wait_1:
	call aux_poll_input		; poll the modem input
	call aux_out_ready		; test whether the modem output is ready
	jr z,aux_putc_wait_1		; if modem not ready for output goto aux_putc_wait_1
	ld a,(aux_out_char)		; character to send
	jp aux_putc			; send it
; Last character sent to the modem
aux_out_char:
	.db 00H

; ----------------------------------------------------------------------
; parse_filespec: Parse a [DU:|DIR:]filename into an FCB (Z3PLUS named
; directories supported).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_filespec:
	push bc				; preserve BC
	ld (parse_mode),a		; save as parse_filespec argument
	call upcase_string		; convert the zero-terminated string at HL to upper case
	push de				; preserve DE
	call clear_dirspec		; clear the drive/user part of the FCB
	ld (de),a			; Store drive byte
	pop de				; restore DE
	push de				; preserve DE
	call parse_fcb			; core of the filespec parser
	pop de				; restore DE
	pop bc				; restore BC
	jr parse_fcb_6			; continue at parse_fcb_6

; ----------------------------------------------------------------------
; parse_fcb: Core of the filespec parser.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_fcb:
	xor a				; Clear A
	ld (de),a			; Clear FCB drive field (0 = default drive)
	ld (parsed_drive),a		; clear drive from the file spec
	ld (wildcard_count),a		; clear number of wildcard characters in the file name
	call get_drive_user		; return current drive in B and user in C
	ld a,c				; C = current user area (0..15)
	ld (parsed_user),a		; save as user number from the file spec
	push de				; preserve DE
	ld a,(hl)			; Check first character of filespec
	cp 3AH				; Is it a colon (':')?
	jr nz,parse_fcb_1		; if A != 3AH goto parse_fcb_1
	inc hl				; Skip leading colon
parse_fcb_1:
	ld b,08H			; Up to 8 characters for filename primary field
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
	ld a,(hl)			; Check trailing delimiter character
	ld (parse_next_char),a		; save as character following the parsed name
	cp 3AH				; Was character a colon ':' (drive/user prefix)?
	jr nz,parse_fcb_4		; if A != 3AH goto parse_fcb_4
	inc hl				; Advance past colon
	ld a,(parse_mode)		; get parse_filespec argument
	or a				; test A (sets Z if A = 0)
	jr z,parse_fcb_2		; if parse_filespec argument is zero/clear goto parse_fcb_2
	call parse_du			; try to interpret a prefix as drive/user
	jr z,parse_fcb_3		; if a valid DU: prefix was found goto parse_fcb_3
parse_fcb_2:
	call parse_named_dir		; try to interpret a prefix as a named directory
	jr z,parse_fcb_3		; if a valid DIR: prefix was found goto parse_fcb_3
	ld a,(parse_mode)		; get parse_filespec argument
	or a				; test A (sets Z if A = 0)
	jr nz,parse_fcb_3		; if parse_filespec argument is set/nonzero goto parse_fcb_3
	call parse_du			; try to interpret a prefix as drive/user
parse_fcb_3:
	ld a,(parsed_drive)		; get drive from the file spec
	ld (de),a			; Store drive into FCB drive byte
	push de				; preserve DE
	inc de				; Advance past drive byte to filename
	call clear_fcb_tail		; clear the rest of the FCB
	pop de				; restore DE
	xor a				; A = 0
	ld (wildcard_count),a		; clear number of wildcard characters in the file name
	push de				; preserve DE
	ld b,08H			; Parse actual 8-character filename following prefix
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
	ld a,(hl)			; Load delimiter character following filename
	ld (parse_next_char),a		; save as character following the parsed name
parse_fcb_4:
	ld a,(parse_next_char)		; get character following the parsed name
	ex de,hl			; swap pointers
	ld bc,0008H			; Advance HL past 8 filename bytes to extension
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld b,03H			; Extension length = 3 characters
	cp 2EH				; Is delimiter a dot '.'?
	jr nz,parse_fcb_5		; if A != 2EH goto parse_fcb_5
	inc hl				; Advance past dot
	push de				; preserve DE
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
parse_fcb_5:
	ex de,hl			; swap pointers
	ld bc,0005H			; BC = 0005H
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld a,(parsed_user)		; get user number from the file spec
	ld (de),a			; Store user area into FCB extension
parse_fcb_6:
	ld a,(wildcard_count)		; get number of wildcard characters in the file name
	or a				; test A (sets Z if A = 0)
	ret				; return

; ----------------------------------------------------------------------
; parse_fcb_field: Copy up to B name characters, expanding "*" to "?"s.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_fcb_field:
	call is_delimiter		; end of the name?
	ret z				; yes: field is complete
	inc de				; step to the next FCB byte
	cp 2AH				; is it "*" ?
	jr nz,parse_fcb_7		; no: ordinary character
	ld a,3FH			; "*" fills the rest of the field with "?"
	ld (de),a			; (DE) = A
	call inc_wild_count		; note one wildcard
	jr parse_fcb_8			; go and fill the remaining positions
parse_fcb_7:
	ld (de),a			; store the character in the FCB
	inc hl				; advance in the source text
	cp 3FH				; is it "?" ?
	call z,inc_wild_count		; count it as a wildcard
parse_fcb_8:
	djnz parse_fcb_field		; next character of the field
parse_fcb_9:
	call is_delimiter		; field full: skip any extra characters of the name
	ret z				; return: character ends the name
	inc hl				; HL++
	jr parse_fcb_9			; loop back to parse_fcb_9

; ----------------------------------------------------------------------
; inc_wild_count: Count one wildcard character.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
inc_wild_count:
	push hl				; preserve HL
	ld hl,wildcard_count		; point HL at number of wildcard characters in the file name
	inc (hl)			; count up number of wildcard characters in the file name
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; parse_du: Try to interpret a prefix as drive/user (DU:).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_du:
	push hl				; preserve HL
	push de				; preserve DE
	call parse_du_inner		; decode "dU" / "d" / "U" form checking against the
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; parse_du_inner: Decode "dU" / "d" / "U" form checking against the
; environment limits.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_du_inner:
	call z3env_duok			; is a ZCPR3 environment present?
	jr z,named_dir_4		; no: not a DU specification
	ex de,hl			; swap pointers
	inc hl				; Advance to filename
	call z3env_max_drive		; highest valid drive
	ld b,a				; B = filename length
	inc b				; B = number of valid drives
	ld a,(hl)			; first character of the spec
	cp 41H				; a drive letter ("A"-"P")?
	jr c,parse_du_inner_1		; no: only a user number may follow
	sub 40H				; convert the letter to a drive number (A = 1)
	cp b				; is that drive valid?
	jr nc,named_dir_4		; no: not a DU specification
	ld (parsed_drive),a		; remember the drive
	inc hl				; HL++
	ld a,(hl)			; next character
	cp 20H				; blank: spec is just the drive
	ret z				; return: A = 20H
	call digit_value		; a digit starts the user number
	ret c				; neither: stop here
parse_du_inner_1:
	push hl				; try to read a user number (one or two digits)
	ld b,02H			; Check up to 2 user number digits
parse_du_inner_2:
	ld a,(hl)			; A = (HL)
	cp 20H				; compare A with 20H (' ')
	jr z,parse_du_inner_3		; if A = 20H goto parse_du_inner_3
	call digit_value		; A = A-'0'
	jr c,parse_du_inner_4		; not a number: give up
	inc hl				; HL++
	djnz parse_du_inner_2		; repeat until all B items are done
	ld a,(hl)			; the digits must be followed by a blank
	cp 20H				; compare A with 20H (' ')
	jr nz,parse_du_inner_4		; if A != 20H goto parse_du_inner_4
parse_du_inner_3:
	pop hl				; restore HL
	call z3env_max_user		; highest valid user number
	ld c,a				; C = A
	inc c				; C++
	call parse_decimal		; convert the digits
	cp c				; is the user number in range?
	jr nc,named_dir_4		; no: reject
	ld (parsed_user),a		; remember the user number
	xor a				; Z = valid DU specification
	ret				; return
parse_du_inner_4:
	pop hl				; restore HL
	jr named_dir_4			; reject

; ----------------------------------------------------------------------
; parse_named_dir: Try to interpret a prefix as a named directory (DIR:).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_named_dir:
	push hl				; preserve HL
	push de				; preserve DE
	call named_dir_lookup		; look up an 8-character name in the Z3 named directory
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; named_dir_lookup: Look up an 8-character name in the Z3 named directory
; register.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
named_dir_lookup:
	call z3env_ndr_ptr		; HL -> named directory register of the ZCPR3 environment
	jr z,named_dir_4		; none: not found
	ex de,hl			; swap pointers
	inc hl				; HL++
named_dir_1:
	ld a,(de)			; first byte of an entry: 0 ends the register
	or a				; test A (sets Z if A = 0)
	jr z,named_dir_4		; end of the register: not found
	inc de				; skip the drive/user bytes
	inc de				; DE++
	push hl				; preserve HL
	push de				; preserve DE
	ld b,08H			; compare the 8-character name
named_dir_2:
	ld a,(de)			; A = (DE)
	cp (hl)				; Character match?
	jr nz,named_dir_3		; if not zero goto named_dir_3
	inc hl				; HL++
	inc de				; DE++
	djnz named_dir_2		; repeat until all B items are done
named_dir_3:
	pop de				; restore DE
	pop hl				; restore HL
	jr z,named_dir_5		; all eight characters matched: found
	ex de,hl			; not this entry: step to the next one (16 bytes)
	ld bc,0010H			; Advance to next 16-byte template entry
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	jr named_dir_1			; loop back to named_dir_1
named_dir_4:
	or 0FFH				; NZ = name not found
	ret				; return
named_dir_5:
	dec de				; found: fetch the user number and drive stored before the name
	ld a,(de)			; Load user number
	ld (parsed_user),a		; save as user number from the file spec
	dec de				; DE--
	ld a,(de)			; Load drive number
	ld (parsed_drive),a		; save as drive from the file spec
	xor a				; Z = found
	ret				; return

; ----------------------------------------------------------------------
; is_delimiter: Z if A ends a file name token.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
is_delimiter:
	ld a,(hl)			; Load character
	cp 21H				; Below '!' is control char or space
	jr c,is_delimiter_1		; if A < 21H goto is_delimiter_1
	cp 3DH				; Invalid delimiter characters
	ret z				; return: A = 3DH
	cp 5FH				; compare A with 5FH
	ret z				; return: A = 5FH
	cp 2EH				; compare A with 2EH
	ret z				; return: A = 2EH
	cp 3AH				; compare A with 3AH
	ret z				; return: A = 3AH
	cp 2CH				; compare A with 2CH
	ret z				; return: A = 2CH
	cp 3CH				; compare A with 3CH
	ret z				; return: A = 3CH
	cp 3EH				; compare A with 3EH
	ret z				; return: A = 3EH
	or a				; Null terminator
	ret z				; return: result is zero
	cp 3BH				; Semicolon ';'
	ret				; return
is_delimiter_1:
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; parse_decimal: Parse a decimal user number.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_decimal:
	push bc				; preserve BC
	ld bc,1100H			; point BC at get_bin16_header
parse_decimal_1:
	ld a,(hl)			; Load next character
	call is_delimiter		; Z if A ends a file name token
	jr z,parse_decimal_2		; if character ends the name goto parse_decimal_2
	inc hl				; Advance pointer
	call digit_value		; A = A-'0'
	jr c,parse_decimal_3		; if not a decimal digit goto parse_decimal_3
	ld d,a				; D = digit value
	ld a,c				; Multiply accumulator C by 10 (C * 8 + C * 2)
	rlca				; rotate A left
	jr c,parse_decimal_3		; if not a decimal digit goto parse_decimal_3
	rlca				; rotate A left
	jr c,parse_decimal_3		; if not a decimal digit goto parse_decimal_3
	add a,c				; A += C
	jr c,parse_decimal_3		; if not a decimal digit goto parse_decimal_3
	rlca				; rotate A left
	jr c,parse_decimal_3		; if not a decimal digit goto parse_decimal_3
	add a,d				; Add new digit value
	jr c,parse_decimal_3		; if not a decimal digit goto parse_decimal_3
	ld c,a				; Update accumulator
	djnz parse_decimal_1		; repeat until all B items are done
parse_decimal_2:
	ld a,c				; A = parsed binary user number
	pop bc				; restore BC
	or a				; Clear carry (success)
	ret				; return
parse_decimal_3:
	pop bc				; restore BC
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; digit_value: A = A-'0'; carry if not a digit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
digit_value:
	sub 30H				; Subtract ASCII '0' (30h)
	ret c				; If < '0', Carry set (invalid)
	cp 0AH				; Compare against 10
	ccf				; Invert Carry: CY=0 if 0..9, CY=1 if > 9
	ret				; return

; ----------------------------------------------------------------------
; clear_dirspec: Clear the drive/user part of the FCB.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
clear_dirspec:
	xor a				; Clear A (default drive 0)
	ld (de),a			; Store into FCB drive byte
	inc de				; Advance to filename field
	call clear_fcb_tail		; clear the rest of the FCB

; ----------------------------------------------------------------------
; clear_fcb_tail: Clear the rest of the FCB.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
clear_fcb_tail:
	ld b,0BH			; 11 bytes (8 filename + 3 extension)
	ld a,20H			; Fill with spaces (' ')
	call fill_clear			; fill B bytes at DE with A
	xor a				; A = 0
	ld (de),a			; (DE) = A
	inc de				; DE++
	call get_drive_user		; return current drive in B and user in C
	ld a,c				; C = current user area
	ld (de),a			; Store into FCB extension user area
	inc de				; DE++
	ld b,03H			; repeat count = 3
	xor a				; A = 0

; ----------------------------------------------------------------------
; fill_clear: Fill B bytes at DE with A.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
fill_clear:
	ld (de),a			; Store fill byte into memory
	inc de				; Advance buffer pointer
	djnz fill_clear			; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; z3env_duok: Read the DU:-form-allowed flag (DUOK, offset 2EH) of the
; ZCPR3 environment descriptor; Z if there is none or DU: is not allowed.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
z3env_duok:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_DUOK_OFF		; DE = 002EH
	jp z3env_ndr_ptr_1		; continue at z3env_ndr_ptr_1

; ----------------------------------------------------------------------
; z3env_max_drive: Read the highest valid drive (offset 2CH) from the
; ZCPR3 environment descriptor.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
z3env_max_drive:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_MDRV_OFF		; DE = 002CH
	jp z3env_ndr_ptr_1		; continue at z3env_ndr_ptr_1

; ----------------------------------------------------------------------
; z3env_max_user: Read the highest valid user number (offset 2DH) from the
; ZCPR3 environment descriptor.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
z3env_max_user:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_MUSR_OFF		; DE = 002DH
	jp z3env_ndr_ptr_1		; continue at z3env_ndr_ptr_1

; ----------------------------------------------------------------------
; z3env_ndr_ptr: Get the named directory register address (offset 15H)
; from the ZCPR3 environment descriptor; its entry count is at 17H.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
z3env_ndr_ptr:
	push de				; preserve DE
	ld de,Z3_NDR_OFF		; DE = 0015H
	jp z3env_ndr_ptr_3		; continue at z3env_ndr_ptr_3
z3env_ndr_ptr_1:
	ld hl,(z3env_ptr)		; get address of the ZCPR3 environment descriptor
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,z3env_ndr_ptr_2		; if the 16-bit count is zero goto z3env_ndr_ptr_2
	add hl,de			; Add field offset to base
z3env_ndr_ptr_2:
	ld a,(hl)			; Fetch byte from descriptor
	pop de				; restore DE
	pop hl				; restore HL
	or a				; Set condition flags
	ret				; return
z3env_ndr_ptr_3:
	ld hl,(z3env_ptr)		; get address of the ZCPR3 environment descriptor
	add hl,de			; Add offset (15h)
	ld e,(hl)			; Load low byte of pointer
	inc hl				; Advance pointer
	ld d,(hl)			; Load high byte of pointer
	inc hl				; Advance pointer
	ld a,(hl)			; Load count byte
	ex de,hl			; swap pointers
	pop de				; restore DE
	or a				; Set flags
	ret				; return

; ----------------------------------------------------------------------
; get_drive_user: Return current drive in B and user in C.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
get_drive_user:
	push af				; preserve AF
	push de				; preserve DE
	push hl				; preserve HL
	ld c,DRV_GET			; BDOS Function 25: Return Current Disk
	call bdos_save_regs		; BDOS call preserving BC and DE
	push af				; preserve AF
	ld e,0FFH			; 0FFh = query current user area
	ld c,F_USERNUM			; BDOS Function 32: Get/Set User Code
	call bdos_save_regs		; BDOS call preserving BC and DE
	ld c,a				; C = current user number (0..15)
	pop af				; restore AF
	ld b,a				; B = current drive number (0=A..)
	pop hl				; restore HL
	pop de				; restore DE
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; file_exists: BDOS search-first on the FCB at DE; Z if not found.
; ----------------------------------------------------------------------
file_exists:
	ld a,F_SFIRST			; A = 11H (XON)
	call bdos_call_a		; BDOS call with function number in A, preserving BC, DE
	inc a				; A++
	ret				; return

; ----------------------------------------------------------------------
; console_read: Read a console character (BDOS C_READ).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
console_read:
	ld a,C_READ			; A = 01H
	jp bdos_call_a			; continue at bdos_call_a

; ----------------------------------------------------------------------
; console_status: Console input status (BDOS C_STAT).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
console_status:
	ld a,C_STAT			; A = 0BH
	jp bdos_call_a			; continue at bdos_call_a

; ----------------------------------------------------------------------
; bdos_save_regs: BDOS call preserving BC and DE.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
bdos_save_regs:
	push de				; preserve DE
	push bc				; preserve BC
	call BDOS			; Call BDOS function
	pop bc				; restore BC
	pop de				; restore DE
	or a				; Test return code in A
	ret				; return

; ----------------------------------------------------------------------
; bdos_call_a: BDOS call with function number in A, preserving BC, DE, HL.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
bdos_call_a:
	push hl				; preserve HL
	push de				; preserve DE
	push bc				; preserve BC
	ld c,a				; C = BDOS function number
	call BDOS			; Call BDOS
	or a				; Test return code in A
	pop bc				; restore BC
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; fcb_to_name: Format the FCB name at DE as NAME.EXT at HL.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
fcb_to_name:
	push bc				; preserve BC
	push hl				; preserve HL
	push de				; preserve DE
	push af				; preserve AF
	ld b,08H			; 8 filename characters
	call copy_name_part		; copy B characters of a name, dropping blanks
	ld (hl),2EH			; Insert dot separator
	inc hl				; Advance destination pointer
	ld b,03H			; 3 extension characters
	call copy_name_part		; copy B characters of a name, dropping blanks
	pop af				; restore AF
	pop de				; restore DE
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; copy_name_part: Copy B characters of a name, dropping blanks.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
copy_name_part:
	ld a,(de)			; Fetch character from FCB
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 20H				; Is character a space?
	jr z,copy_name_part_1		; if A = 20H goto copy_name_part_1
	ld (hl),a			; Store printable character into output buffer
	inc hl				; Advance output pointer
copy_name_part_1:
	inc de				; Advance source pointer
	djnz copy_name_part		; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; a_to_decimal: Convert A to up to three decimal digits at DE.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
a_to_decimal:
	push bc				; preserve BC
	ld b,00H			; B = 00H
	jp a_to_decimal_1		; continue at a_to_decimal_1
a_to_decimal_1:
	push hl				; preserve HL
	push af				; preserve AF
	ld h,64H			; Divisor = 100 (hundreds digit)
	call decimal_digit		; extract one decimal digit
	ld h,0AH			; Divisor = 10 (tens digit)
	call decimal_digit		; extract one decimal digit
	call decimal_emit		; store one decimal digit
	pop af				; restore AF
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; decimal_digit: Extract one decimal digit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
decimal_digit:
	ld l,0FFH			; Initialize quotient = -1
decimal_digit_1:
	sub h				; Subtract divisor
	inc l				; Increment quotient
	jr nc,decimal_digit_1		; Continue until underflow
	add a,h				; Restore remainder
	ld h,a				; Save remainder in H
	ld a,l				; A = quotient
	or a				; Is quotient zero?
	jr nz,decimal_emit		; if result is nonzero goto decimal_emit
	or b				; A |= B
	ld a,h				; A = remainder
	ret m				; If B negative, return
	ld a,20H			; Output space for suppressed zero (' ')
	jr z,decimal_emit_1		; if result is zero goto decimal_emit_1
	xor a				; A = 0

; ----------------------------------------------------------------------
; decimal_emit: Store one decimal digit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
decimal_emit:
	add a,30H			; Convert digit 0..9 to ASCII '0'..'9'
	ld b,a				; B non-zero (ends suppression)
decimal_emit_1:
	ld (de),a			; Store ASCII character into buffer
	inc de				; Advance destination pointer
	ld a,h				; Restore remainder in A
	ret				; return

; ----------------------------------------------------------------------
; upcase_string: Convert the zero-terminated string at HL to upper case.
; ----------------------------------------------------------------------
upcase_string:
	push af				; preserve AF
	push hl				; preserve HL
upcase_string_1:
	ld a,(hl)			; Fetch character
	or a				; Check for null terminator
	jr z,upcase_string_2		; if result is zero goto upcase_string_2
	call to_upper			; convert A to upper case
	ld (hl),a			; Store converted character back
	inc hl				; Advance string pointer
	jr upcase_string_1		; loop back to upcase_string_1
upcase_string_2:
	pop hl				; restore HL
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; tokenize_args: Split the command tail into blank-separated tokens,
; building a pointer table.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
tokenize_args:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ld c,a				; C = nonzero: terminate each token with a zero
	ex de,hl			; HL -> argument table, DE -> text
	ld b,(hl)			; B = maximum number of arguments
	push hl				; remember the table address
	inc hl				; skip the max/count bytes
	inc hl				; HL++
tokenize_args_1:
	call skip_blanks		; find the start of the next token
	or a				; end of text?
	jr z,tokenize_args_4		; yes: done
	ld (hl),e			; store the token address in the table
	inc hl				; HL++
	ld (hl),d			; Store token pointer high byte
	inc hl				; HL++
	dec b				; one more slot used
	jr z,tokenize_args_3		; table full
	call skip_token			; skip over the token
	or a				; End of command line?
	jr z,tokenize_args_4		; end of text
	ld a,c				; Delimiter replacement enabled?
	or a				; terminate the token?
	jr z,tokenize_args_2		; if result is zero goto tokenize_args_2
	xor a				; Replace whitespace with null terminator
	ld (de),a			; replace the delimiter by a zero
	inc de				; Advance past null
tokenize_args_2:
	ld a,b				; more slots free?
	or a				; test A (sets Z if A = 0)
	jr nz,tokenize_args_1		; yes: next token
tokenize_args_3:
	call skip_token			; table full: see whether more text remains
	call skip_blanks		; skip spaces and tabs at DE
	or a				; End of line?
	jr z,tokenize_args_4		; if result is zero goto tokenize_args_4
	or 0FFH				; NZ = too many arguments
tokenize_args_4:
	pop hl				; HL -> table
	push af				; preserve AF
	ld a,(hl)			; count = max - remaining
	sub b				; A = limit - remaining = tokens parsed
	inc hl				; Point to count byte (+1)
	ld (hl),a			; store the argument count
	pop af				; restore AF
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; skip_blanks: Skip spaces and tabs at DE.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
skip_blanks:
	ld a,(de)			; Fetch character
	and 7FH				; strip the parity bit (7-bit ASCII)
	inc de				; Advance pointer
	cp 20H				; Space?
	jr z,skip_blanks		; if A = 20H goto skip_blanks
	cp 09H				; Tab?
	jr z,skip_blanks		; if A = 09H goto skip_blanks
	dec de				; Back up to first non-space character
	ret				; return

; ----------------------------------------------------------------------
; skip_token: Skip a token at DE.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
skip_token:
	ld a,(de)			; Fetch character
	and 7FH				; strip the parity bit (7-bit ASCII)
	ret z				; return: result is zero
	cp 20H				; Space delimiter?
	ret z				; return: A = 20H
	cp 09H				; Tab delimiter?
	ret z				; return: A = 09H
	inc de				; Advance to next character
	jr skip_token			; loop back to skip_token

; ----------------------------------------------------------------------
; memset: Fill B bytes at HL with A (preserves HL).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
memset:
	push hl				; preserve HL
	call memset_inner		; fill B bytes at HL with A
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; memset_inner: Fill B bytes at HL with A.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
memset_inner:
	push bc				; preserve BC
memset_inner_1:
	ld (hl),a			; Store byte into buffer
	inc hl				; Advance pointer
	djnz memset_inner_1		; repeat until all B items are done
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; to_upper: Convert A to upper case.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
to_upper:
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 61H				; Less than 'a' (61h)?
	ret c				; return: A < 61H
	cp 7BH				; compare A with 7BH
	ret nc				; return: A >= 7BH
	and 5FH				; Convert lowercase to uppercase (clear bit 5)
	ret				; return

; ----------------------------------------------------------------------
; HBIOS Send/Receive Routines
; ----------------------------------------------------------------------

; ----------------------------------------------------------------------
; hb_init: Verify RomWBW is running and patch the FastPath function and
; unit data addresses into the hb_* routines for the transfer unit.
; Block I/O (BF_CIOBLKIN and BF_CIOBLKOUT) is enabled if this HBIOS
; supports it.  Returns Z on success, NZ (A = FFH) on error.
; ----------------------------------------------------------------------

hb_init:
	; Verify we are running under RomWBW
	ld hl,WBWSTAMP		; HL := adr of RomWBW zero page stamp
	ld a,(hl)		; get first byte of RomWBW marker
	cp 'W'			; match?
	jr nz,hb_init_err	; handle error
	inc hl			; next byte (marker byte 2)
	ld a,(hl)		; load it
	cp ~'W'			; match?
	jr nz,hb_init_err	; handle error

	; Patch the byte mode routines w/ FastPath addresses
	ld d,BF_CIOOUT		; hb_cout
	call hb_getfn		; HL := func adr, DE := unit data adr
	jr nz,hb_init_err	; handle API error
	ld (hb_udat),de		; Plug in data adr
	ld (hb_outfn),hl	; Plug in func adr
	ld d,BF_CIOIN		; hb_cin
	call hb_getfn		; ...
	jr nz,hb_init_err	; ...
	ld (hb_infn),hl		; ...
	ld d,BF_CIOIST		; hb_cinst
	call hb_getfn		; ...
	jr nz,hb_init_err	; ...
	ld (hb_istfn),hl	; ...
	ld d,BF_CIOOST		; hb_coutst
	call hb_getfn		; ...
	jr nz,hb_init_err	; ...
	ld (hb_ostfn),hl	; ...

	; The receive buffer sits just below the stack, and the transmit
	; buffer just below that.  Both must be in common RAM (8000h or
	; above) as the block functions require.
	ld hl,(BDOSVEC)		; top of TPA
	ld bc,STKSIZE + 6 + RXBUFSZ	; less BDOS start, stack, buffer
	or a			; clear CF
	sbc hl,bc		; HL := receive buffer address
	ld (hb_rxbuf),hl	; save it
	ld bc,TXBUFSZ		; transmit buffer below it
	or a			; ...
	sbc hl,bc		; HL := transmit buffer address
	ld (hb_txbuf),hl	; save it
	ld (hb_txptr),hl	; transmit buffer empty
	xor a			; ...
	ld (hb_txcnt),a		; ...

	; Enable block I/O if this HBIOS supports it.  Otherwise, the
	; hb_* routines fall back to byte mode FastPath calls.
	ld (hb_blkok),a		; assume not available
	ld (hb_rxcnt),a		; receive buffer empty
#IF (!BLKIO)
	jr hb_init_ok		; diagnostic: force the original byte mode path
#ENDIF
	bit 7,h			; lowest buffer in common RAM?
	jr z,hb_init_ok		; if not, no block I/O

	; The generic HBIOS block functions are called with the unit in C
	; and cannot resolve the special console unit code, so require a
	; real unit number.
	ld a,(xfer_unit)	; desired char unit
	bit 7,a			; special unit code?
	jr nz,hb_init_ok	; if so, no block I/O

	; Get FastPath addresses of BF_CIOBLKIN and BF_CIOBLKOUT.  An
	; HBIOS without block functions rejects the function numbers here.
	ld d,BF_CIOBLKIN	; Func=CIO BLKIN
	call hb_getfn		; HL := func adr
	jr nz,hb_init_ok	; not supported, no block I/O
	ld (hb_blkinfn),hl	; Plug in func adr
	ld d,BF_CIOBLKOUT	; Func=CIO BLKOUT
	call hb_getfn		; HL := func adr
	jr nz,hb_init_ok	; not supported, no block I/O
	ld (hb_blkoutfn),hl	; Plug in func adr
	ld a,0FFH		; enable
	ld (hb_blkok),a		; ... block I/O

hb_init_ok:
	xor	a
	ret

hb_init_err:
	or	0FFH
	ret

; ----------------------------------------------------------------------
; hb_getfn: Get the FastPath address of CIO function D for the transfer
; unit (SYSGET CIOFN).  Returns HL := function address, DE := unit data
; address, NZ on error.
; ----------------------------------------------------------------------

hb_getfn:
	ld bc,BC_SYSGET_CIOFN	; SYSGET CIOFN
	ld a,(xfer_unit)	; transfer unit
	ld e,a			; ... in E
	rst 08			; call HBIOS
	ret

hb_udat		.dw	0	; unit instance data address

hb_blkok	.db	0	; FFH if block I/O (BF_CIOBLKIN/BF_CIOBLKOUT) is in use
hb_rxcnt	.db	0	; bytes remaining in block receive buffer
hb_rxptr	.dw	0	; next byte in block receive buffer
hb_rxbuf	.dw	0	; block receive buffer address (common RAM)
hb_txcnt	.db	0	; bytes waiting in the transmit buffer
hb_txptr	.dw	0	; next free byte in the transmit buffer
hb_txbuf	.dw	0	; transmit buffer address (common RAM)
hb_txpoll	.db	0	; hb_flush call counter (input poll pacing)

; ----------------------------------------------------------------------
; hb_cin: Wait for and return the next received byte in E and C.
; Taken from the block receive buffer when in use, refilling it with a
; single BF_CIOBLKIN call when empty.
; ----------------------------------------------------------------------

hb_cin:
	ld a,(hb_rxcnt)		; bytes buffered?
	or a
	jr nz,hb_cin_buf	; yes: take the next one
	ld a,(hb_blkok)		; block receive in use?
	or a
	jr z,hb_cin_fp		; no: byte mode FastPath call
hb_cin_wait:
	call hb_fill		; refill buffer, A := bytes read
	or a
	jr z,hb_cin_wait	; wait until something arrives
hb_cin_buf:
	dec a			; one byte fewer
	ld (hb_rxcnt),a		; ...
	push hl			; preserve HL
	ld hl,(hb_rxptr)	; next byte
	ld e,(hl)		; ... to E
	inc hl			; advance pointer
	ld (hb_rxptr),hl	; ...
	pop hl			; restore HL
	ld c,e			; also return in C
	xor a			; success status
	ret

hb_cin_fp:
	ld iy,(hb_udat)
	ld a,(bios_bid)
	ld ix,0000H
hb_infn	.equ	$-2
	call HB_BNKCALL
	ld c,e
#IF RXSTATS
	; byte mode: only note the time of the first byte, so the
	; statistics add as little as possible to this path
	push af			; save status
	ld a,(st_t0ok)		; start time taken?
	or a			; ...
	call z,st_start_pb	; if not, take it now
	pop af			; restore status
#ENDIF
	ret

; ----------------------------------------------------------------------
; hb_fill: Refill the empty block receive buffer with whatever bytes
; are waiting (up to RXBUFSZ - 1) using one BF_CIOBLKIN FastPath call.
; Returns A := number of bytes now buffered (0 if none or on error).
;
; BC, DE and HL are preserved.  Callers rely on this: aux_getc_timeout
; holds its timeout count in B across hb_cinst, and the byte mode driver
; status routines used before did not disturb these registers.
; ----------------------------------------------------------------------

hb_fill:
	push bc			; preserve registers
	push de			; ...
	push hl			; ...
	ld hl,(hb_rxbuf)	; buffer
	ld (hb_rxptr),hl	; reset read pointer
	ld iy,(hb_udat)		; unit instance data
	ld a,(xfer_unit)	; unit, required in C
	ld c,a			; ...
	ld e,RXBUFSZ - 1	; max bytes
	ld a,(bios_bid)		; HBIOS bank
	ld ix,0000H		; BF_CIOBLKIN function address
hb_blkinfn	.equ	$-2
	call HB_BNKCALL		; do it, D := bytes read
	or a			; error?
	ld a,d			; bytes read
	jr z,hb_fill1		; if no error, use count
	xor a			; on error, nothing buffered
hb_fill1:
	ld (hb_rxcnt),a		; save count
#IF RXSTATS
	call st_record		; count this refill (A preserved)
#ENDIF
	pop hl			; restore registers
	pop de			; ...
	pop bc			; ...
	ret

; ----------------------------------------------------------------------
; hb_flush: Send everything in the transmit buffer with BF_CIOBLKOUT.
; Returns when the buffer is empty (on a driver error the rest is
; discarded).  Does nothing if the buffer is empty, as it always is in
; byte mode.  Uses all registers.
;
; Until all bytes are sent, the input is polled between calls so that
; data from the other side keeps flowing into the ring, but only when
; the device could take nothing (the wait is spent on input) or on every
; 8th call.  A device that holds only a byte or two (such as an SIO)
; takes a few bytes per call, and an input poll on every call would
; double the bank calls per byte sent.
; ----------------------------------------------------------------------

hb_flush:
	ld a,(hb_txcnt)		; bytes waiting
	or a			; any?
	ret z			; if not, done
	ld e,a			; E := bytes to send
	ld hl,(hb_txbuf)	; HL := first byte
hb_flush1:
	ld a,(xfer_unit)	; unit, required in C
	ld c,a			; ...
	ld iy,(hb_udat)		; unit instance data
	ld a,(bios_bid)		; HBIOS bank
	ld ix,0000H		; BF_CIOBLKOUT function address
hb_blkoutfn	.equ	$-2
	call HB_BNKCALL		; D := sent, E := remaining, HL := next
	or a			; error?
	jr nz,hb_flush2		; if so, discard the rest
	ld a,e			; anything left?
	or a			; ...
	jr z,hb_flush2		; if not, done
	ld a,d			; device busy (nothing sent)?
	or a			; ...
	jr z,hb_flush3		; if so, poll input while waiting
	ld a,(hb_txpoll)	; else poll only on every 8th call
	inc a			; ...
	ld (hb_txpoll),a	; ...
	and 07H			; ...
	jr nz,hb_flush1		; not this time: send the rest
hb_flush3:
	push de			; save remaining count
	push hl			; save next byte pointer
	call aux_poll_input	; keep receiving while the device is busy
	pop hl			; restore
	pop de			; ...
	jr hb_flush1		; send the rest
hb_flush2:
	xor a			; transmit buffer is empty again
	ld (hb_txcnt),a		; ...
	ld hl,(hb_txbuf)	; ...
	ld (hb_txptr),hl	; ...
	ret

; ----------------------------------------------------------------------
; hb_cout: Send byte A (byte mode).
; ----------------------------------------------------------------------

hb_cout:
	ld e,a
	ld iy,(hb_udat)
	ld a,(bios_bid)
	ld ix,0000H
hb_outfn	.equ	$-2
	jp HB_BNKCALL

; ----------------------------------------------------------------------
; hb_cinst: Input status.  A := nonzero if a received byte is ready.
; With block receive in use, an empty buffer is refilled first.
; ----------------------------------------------------------------------

hb_cinst:
	ld a,(hb_rxcnt)		; bytes buffered?
	or a
	ret nz			; yes: ready (A = count)
	ld a,(hb_blkok)		; block receive in use?
	or a
	jp nz,hb_fill		; yes: refill, A := bytes now buffered

hb_cinst_fp:
	ld iy,(hb_udat)
	ld a,(bios_bid)
	ld ix,0000H
hb_istfn	.equ	$-2
	jp HB_BNKCALL

; ----------------------------------------------------------------------
; hb_coutst: Output status.  A := nonzero if the transmitter can accept
; a byte.
; ----------------------------------------------------------------------

hb_coutst:
	ld iy,(hb_udat)
	ld a,(bios_bid)
	ld ix,0000H
hb_ostfn	.equ	$-2
	jp HB_BNKCALL

#IF RXSTATS
; ----------------------------------------------------------------------
; Receive statistics (diagnostic, RXSTATS = 1).
;
; Every BF_CIOBLKIN refill is counted, along with how many came back
; empty, total bytes, the largest single refill and a histogram of
; refill sizes.  Mostly empty refills of 1-2 bytes mean rz is waiting
; on the line; refills near the driver's buffer size mean rz is falling
; behind.  Elapsed time runs from the first byte received to the report
; and is in HBIOS timer ticks.
; ----------------------------------------------------------------------

; st_record: Count one refill.  A = bytes read.  A is preserved;
; BC, DE, HL are not (hb_fill saves them).
st_record:
	push af			; save count
	ld a,(st_frozen)	; report in progress?
	or a			; ...
	jr nz,st_recordx	; if so, stop counting
	ld hl,st_fills		; count the refill
	call inc32		; ...
	pop af			; count
	push af			; ...
	or a			; empty?
	jr nz,st_record1	; if not, record bytes
	ld hl,st_empty		; count empty refill
	call inc32		; ...
st_recordx:
	pop af			; restore count
	ret
st_record1:
	ld a,(st_t0ok)		; start time taken?
	or a			; ...
	call z,st_start		; if not, take it now (first byte)
	pop af			; count
	push af			; ...
	ld hl,st_bytes		; add to total bytes
	call st_add32a		; ...
	pop af			; count
	push af			; ...
	ld hl,st_max		; new largest refill?
	cp (hl)			; ...
	jr c,st_record2		; if smaller, skip
	ld (hl),a		; save new max
st_record2:
	; histogram bucket = floor(log2(count)), capped at 5:
	; 1, 2-3, 4-7, 8-15, 16-31, 32+
	ld b,0			; bucket
st_record3:
	srl a			; halve
	jr z,st_record4		; done when nothing left
	inc b			; next bucket
	jr st_record3		; loop
st_record4:
	ld a,b			; bucket
	cp 6			; cap at 5
	jr c,st_record5		; ...
	ld a,5			; ...
st_record5:
	add a,a			; * 4 bytes per counter
	add a,a			; ...
	ld e,a			; DE := offset
	ld d,0			; ...
	ld hl,st_hist		; histogram
	add hl,de		; counter for this bucket
	call inc32		; count it
	pop af			; restore count
	ret

; st_start: Record the start time (first byte received).
st_start:
	ld a,(st_frozen)	; report in progress?
	or a			; ...
	ret nz			; if so, too late to start timing
	ld hl,st_t0		; destination
	call st_gettime		; read timer
	ld a,0FFH		; mark
	ld (st_t0ok),a		; ... start time taken
	ret

; st_start_pb: st_start for the byte mode path, preserving BC, DE, HL
; (hb_cin returns the byte in E and C).
st_start_pb:
	push bc			; preserve registers
	push de			; ...
	push hl			; ...
	call st_start		; record start time
	pop hl			; restore registers
	pop de			; ...
	pop bc			; ...
	ret

; st_gettime: Store the current 32-bit HBIOS tick count at (HL) and
; the tick frequency at st_freq.
st_gettime:
	push hl			; save destination
	ld b,BF_SYSGET		; HBIOS SysGet
	ld c,BF_SYSGET_TIMER	; ... timer
	rst 08			; DE:HL := ticks, C := frequency
	ld a,c			; save frequency
	ld (st_freq),a		; ...
	ex de,hl		; HL := high word, DE := low word
	ex (sp),hl		; HL := destination, (SP) := high word
	ld (hl),e		; store low word
	inc hl			; ...
	ld (hl),d		; ...
	inc hl			; ...
	pop de			; high word
	ld (hl),e		; store high word
	inc hl			; ...
	ld (hl),d		; ...
	ret

; st_tacc: Accumulate an interval: (HL) += now - (DE), in timer ticks.
; HL = 32-bit accumulator, DE = 32-bit start mark.  Uses all registers.
st_tacc:
	push hl			; save accumulator
	push de			; save mark
	ld hl,st_tnow		; current time
	call st_gettime		; ...
	pop de			; mark
	ld hl,st_tnow		; tnow := tnow - mark
	ld bc,st_tnow		; ...
	call sub32		; ...
	pop hl			; accumulator
	ld de,st_tnow		; acc := tnow + acc
	ld b,h			; ...
	ld c,l			; ...
	jp add32		; ... and return

; st_active: Z clear (NZ) while a transfer is being measured: after the
; first byte and before the report starts.  Uses A.
st_active:
	ld a,(st_frozen)	; report started?
	or a			; ...
	jr nz,st_active1	; if so, not active
	ld a,(st_t0ok)		; first byte seen?
	or a			; NZ if so
	ret
st_active1:
	xor a			; Z: not active
	ret

; st_idle_pass: One pass of the aux_wait_input loop found nothing.
; Counts it and starts timing an idle stretch.  BC is preserved.
st_idle_pass:
	call st_active		; measuring?
	ret z			; if not, ignore
	push bc			; preserve BC
	ld hl,st_c_idle		; count the pass
	call inc32		; ...
	ld a,(st_inidle)	; already in an idle stretch?
	or a			; ...
	jr nz,st_idle_pass1	; if so, keep timing it
	ld a,0FFH		; start a stretch
	ld (st_inidle),a	; ...
	ld hl,st_imark		; ... at the current time
	call st_gettime		; ...
st_idle_pass1:
	pop bc			; restore BC
	ret

; st_idle_end: aux_wait_input is returning.  Ends any idle stretch and
; adds its length to the idle time.
st_idle_end:
	ld a,(st_inidle)	; in an idle stretch?
	or a			; ...
	ret z			; if not, nothing to do
	xor a			; end it
	ld (st_inidle),a	; ...
	ld hl,st_t_idle		; idle time += now - start
	ld de,st_imark		; ...
	jp st_tacc		; ...

; st_zack_start / st_zack_end: Time a data-phase ZACK, from just before
; it is built until send_hex_header returns.  Use all registers.
st_zack_start:
	ld hl,st_zmark		; mark the start time
	jp st_gettime		; ...
st_zack_end:
	ld hl,st_t_zack		; ZACK time += now - start
	ld de,st_zmark		; ...
	jp st_tacc		; ...

; st_add32a: Add A to the 32-bit value at (HL).
st_add32a:
	add a,(hl)		; low byte
	ld (hl),a		; ...
	ret nc			; done if no carry
	inc hl			; propagate carry
	inc (hl)		; ...
	ret nz			; ...
	inc hl			; ...
	inc (hl)		; ...
	ret nz			; ...
	inc hl			; ...
	inc (hl)		; ...
	ret

; st_hdr_err: Classify an rx_header_error by the reason code in A
; (left there by the dispatch that got us here).
st_hdr_err:
	ld hl,st_e_tmo		; FEH: timeout (header or data subpacket)
	cp 0FEH			; ...
	jr z,st_count		; ...
	ld hl,st_e_junk		; FCH: too much junk, no header found
	cp 0FCH			; ...
	jr z,st_count		; ...
	ld hl,st_e_znak		; ZNAK: sender rejected our header
	cp ZNAK			; ...
	jr z,st_count		; ...
	ld hl,st_e_hoth		; anything else
st_count:
	jp inc32		; count it and return

; st_data_err: Classify an rx_data_error: wrong file position if
; st_set_pos flagged it, otherwise a CRC or framing error.
st_data_err:
	ld a,(st_posflag)	; wrong position?
	or a			; ...
	jr z,st_data_crc	; if not, CRC/framing
	xor a			; clear the flag
	ld (st_posflag),a	; ...
	ld hl,st_e_pos		; wrong position
	jr st_count		; ...
st_data_crc:
	call st_logcrc		; record where it happened
	ld hl,st_e_crc		; CRC/framing
	jr st_count		; ...

; st_logcrc: Record the first ST_CRCMAX CRC/framing errors: file
; position (4 bytes), bytes of the subpacket received (2), receive
; buffer count (2) and whether a header or data was being received (1).
ST_CRCMAX	.equ	4	; entries logged
ST_CRCSZ	.equ	9	; bytes per entry
st_logcrc:
	ld a,(st_crcn)		; entries used
	cp ST_CRCMAX		; log full?
	ret nc			; if so, done
	ld l,a			; HL := entry * 9
	ld h,0			; ...
	ld d,h			; ...
	ld e,l			; ...
	add hl,hl		; * 2
	add hl,hl		; * 4
	add hl,hl		; * 8
	add hl,de		; * 9
	ld de,st_crclog		; + log base
	add hl,de		; ...
	inc a			; one more entry
	ld (st_crcn),a		; ...
	ex de,hl		; DE := entry
	ld hl,file_position	; file position, 32 bits
	ld bc,4			; ...
	ldir			; ...
	ld hl,subpacket_len	; subpacket bytes received, low 16 bits
	ldi			; ...
	ldi			; ...
	ld hl,rx_buffer_count	; receive buffer count
	ldi			; ...
	ldi			; ...
	ld a,(st_src)		; header (2) or data (1)
	ld (de),a		; ...
	ret

; st_logxm: Record the first ST_XMMAX XMODEM/YMODEM errors.  Entry:
; stage (1), last char (1), block number received (1), last good block
; number (1), data bytes still due (2), file position (4).
ST_XMMAX	.equ	6	; entries logged
ST_XMSZ		.equ	10	; bytes per entry
st_logxm:
	ld a,(st_xmn)		; entries used
	cp ST_XMMAX		; log full?
	ret nc			; if so, done
	ld l,a			; HL := entry * 10
	ld h,0			; ...
	ld d,h			; ...
	ld e,l			; ...
	add hl,hl		; * 2
	add hl,hl		; * 4
	add hl,de		; * 5
	add hl,hl		; * 10
	ld de,st_xmlog		; + log base
	add hl,de		; ...
	inc a			; one more entry
	ld (st_xmn),a		; ...
	ld a,(st_xstage)	; stage
	ld (hl),a		; ...
	inc hl			; ...
	ld a,(xm_rx_char)	; last character (FEH = timeout)
	ld (hl),a		; ...
	inc hl			; ...
	ld a,(xm_blk_no_rx)	; block number received
	ld (hl),a		; ...
	inc hl			; ...
	ld a,(xm_block_no)	; last good block number
	ld (hl),a		; ...
	inc hl			; ...
	ld de,(xm_block_len)	; data bytes still due
	ld (hl),e		; ...
	inc hl			; ...
	ld (hl),d		; ...
	inc hl			; ...
	ex de,hl		; DE := entry file position field
	ld hl,file_position	; file position
	ld bc,4			; ...
	ldir			; ...
	ret

; st_xmstage: Print the name of the XMODEM stage in A.
st_xmstage:
	cp 8			; known stage?
	jr c,st_xmstage1	; ...
	xor a			; else "?"
st_xmstage1:
	add a,a			; word index
	ld e,a			; ...
	ld d,0			; ...
	ld hl,st_xstab		; stage name table
	add hl,de		; ...
	ld e,(hl)		; DE := name
	inc hl			; ...
	ld d,(hl)		; ...
	jp st_puts		; print it

; st_set_pos: Flag a wrong-position ZDATA.  Flags are preserved.
st_set_pos:
	push af			; save flags
	ld a,0FFH		; set flag
	ld (st_posflag),a	; ...
	pop af			; restore flags
	ret

; st_report: Print the statistics.
st_report:
	ld a,0FFH		; stop counting
	ld (st_frozen),a	; ...
	ld a,(st_t0ok)		; any data at all?
	or a			; ...
	jr z,st_report0		; if not, no elapsed time
	ld hl,st_t1		; end time
	call st_gettime		; ...
	ld hl,st_t1		; elapsed := end - start
	ld de,st_t0		; ...
	ld bc,st_t1		; ...
	call sub32		; ...
st_report0:
	; The console is often the transfer port.  If the transfer ended
	; early, the sender may still be streaming, and anything printed
	; now would go to it instead of the screen.  So first wait until
	; the line has been quiet for 2 seconds, discarding any input.
	ld b,20			; 2.0 s with nothing received
	call aux_getc_timeout	; ...
	jr nc,st_report0	; something arrived: keep waiting
;
	ld de,st_msg_hdr	; heading
	call st_puts		; ...
	ld de,st_msg_errs	; error count
	call st_puts		; ...
	ld hl,st_errs		; ...
	call st_put32		; ...
	ld a,(xfer_abort)	; aborted?
	or a			; ...
	ld de,st_msg_abort	; ...
	call nz,st_puts		; if so, say so
;
	; error breakdown
	ld hl,st_err_tab	; table of (label, counter) pairs
	ld b,8			; eight categories
	call st_prtab		; print them
;
	; how the sender framed the data
	ld de,st_msg_sub	; heading
	call st_puts		; ...
	ld hl,st_sub_tab	; table of (label, counter) pairs
	ld b,9			; nine counters
	call st_prtab		; print them
;
	; where the first CRC/framing errors happened
	ld a,(st_crcn)		; entries logged
	or a			; any?
	jr z,st_report_c2	; if not, skip
	ld b,a			; entry count
	ld hl,st_crclog		; first entry
st_report_c:
	push bc			; save count
	push hl			; save entry pointer
	ld de,st_msg_cl1	; "CRC/framing error at file position "
	call st_puts		; ...
	pop hl			; entry: file position
	push hl			; ...
	call st_put32		; ...
	pop hl			; entry: header or data?
	push hl			; ...
	ld bc,8			; ...
	add hl,bc		; ...
	ld a,(hl)		; ...
	ld de,st_msg_clh	; assume header
	cp 2			; header?
	jr z,st_report_c1	; ...
	ld de,st_msg_cld	; data subpacket
st_report_c1:
	call st_puts		; ...
	ld de,st_msg_cl2	; ", subpacket bytes "
	call st_puts		; ...
	pop hl			; entry: subpacket bytes
	push hl			; ...
	ld bc,4			; ...
	add hl,bc		; ...
	call st_put16		; ...
	ld de,st_msg_cl3	; ", buffer "
	call st_puts		; ...
	pop hl			; entry: buffer count
	push hl			; ...
	ld bc,6			; ...
	add hl,bc		; ...
	call st_put16		; ...
	pop hl			; next entry
	ld bc,ST_CRCSZ		; ...
	add hl,bc		; ...
	pop bc			; restore count
	djnz st_report_c	; loop
st_report_c2:
;
	; details of the first XMODEM/YMODEM errors
	ld a,(st_xmn)		; entries logged
	or a			; any?
	jr z,st_report_x2	; if not, skip
	ld b,a			; entry count
	ld hl,st_xmlog		; first entry
st_report_x:
	push bc			; save count
	push hl			; save entry pointer
	ld de,st_msg_x1		; "XM err: "
	call st_puts		; ...
	pop hl			; stage
	push hl			; ...
	ld a,(hl)		; ...
	call st_xmstage		; ... by name
	ld de,st_msg_x2		; ", char "
	call st_puts		; ...
	pop hl			; last character
	push hl			; ...
	inc hl			; ...
	ld a,(hl)		; ...
	call prt_hex		; ...
	ld de,st_msg_x3		; "h, blk "
	call st_puts		; ...
	pop hl			; block number received
	push hl			; ...
	inc hl			; ...
	inc hl			; ...
	ld a,(hl)		; ...
	call prt_hex		; ...
	ld de,st_msg_x4		; "h, last "
	call st_puts		; ...
	pop hl			; last good block number
	push hl			; ...
	ld bc,3			; ...
	add hl,bc		; ...
	ld a,(hl)		; ...
	call prt_hex		; ...
	ld de,st_msg_x5		; "h, due "
	call st_puts		; ...
	pop hl			; data bytes still due
	push hl			; ...
	ld bc,4			; ...
	add hl,bc		; ...
	call st_put16		; ...
	ld de,st_msg_x6		; ", pos "
	call st_puts		; ...
	pop hl			; file position
	push hl			; ...
	ld bc,6			; ...
	add hl,bc		; ...
	call st_put32		; ...
	pop hl			; next entry
	ld bc,ST_XMSZ		; ...
	add hl,bc		; ...
	pop bc			; restore count
	djnz st_report_x	; loop
st_report_x2:
;
	ld a,(hb_blkok)		; block receive in use?
	or a			; ...
	jr nz,st_report1	; if so, full report
	ld de,st_msg_off	; byte mode: say so
	call st_puts		; ...
	call st_rep_time	; elapsed time only
	ld de,st_msg_crlf	; end line
	jp st_puts		; ... and done
st_report1:
	ld de,st_msg_bytes	; total bytes
	call st_puts
	ld hl,st_bytes
	call st_put32
	call st_rep_time	; elapsed time
	call st_rep_rate	; throughput
	jr st_report2		; continue with refill statistics

; st_rep_time: Print elapsed ticks (computed at the start of the report).
st_rep_time:
	ld a,(st_t0ok)		; any data at all?
	or a			; ...
	ret z			; if not, no elapsed time
	ld de,st_msg_time	; elapsed
	call st_puts
	ld hl,st_t1
	call st_put32
	ld de,st_msg_at		; " ticks at "
	call st_puts
	ld hl,st_tmp		; frequency as 32-bit
	call zero32		; ...
	ld a,(st_freq)		; ...
	ld (st_tmp),a		; ...
	call st_put32		; ...
	ld de,st_msg_hz		; " Hz"
	jp st_puts		; print and return

st_report2:
	ld de,st_msg_fills	; refills
	call st_puts
	ld hl,st_fills
	call st_put32
	ld de,st_msg_empty	; ", empty "
	call st_puts
	ld hl,st_empty
	call st_put32
;
	ld de,st_msg_max	; largest refill
	call st_puts
	ld hl,st_tmp		; max as 32-bit
	call zero32		; ...
	ld a,(st_max)		; ...
	ld (st_tmp),a		; ...
	call st_put32		; ...
;
	ld de,st_msg_hist	; histogram heading
	call st_puts
	ld hl,st_hist		; first counter
	ld de,st_msg_h0		; first label
	ld b,6			; six buckets
st_report3:
	push bc			; save count
	push hl			; save counter pointer
	push de			; save label pointer
	call st_puts		; print label
	pop de			; label pointer
	pop hl			; counter pointer
	push hl			; ...
	push de			; ...
	call st_put32		; print counter
	pop hl			; label pointer to HL
	ld bc,8			; each label is 8 bytes
	add hl,bc		; next label
	ex de,hl		; ... to DE
	pop hl			; counter pointer
	ld bc,4			; next counter
	add hl,bc		; ...
	pop bc			; restore count
	djnz st_report3		; loop
	ld de,st_msg_crlf	; end line
	jp st_puts

; st_prtab: Print B (label, counter) pairs from the table at HL.  Each
; entry is two words: address of a '$' terminated label, address of a
; 32-bit counter.
st_prtab:
	push bc			; save count
	ld e,(hl)		; DE := label
	inc hl			; ...
	ld d,(hl)		; ...
	inc hl			; ...
	ld c,(hl)		; BC := counter
	inc hl			; ...
	ld b,(hl)		; ...
	inc hl			; ...
	push hl			; save table pointer
	push bc			; save counter pointer
	call st_puts		; print label
	pop hl			; counter pointer
	call st_put32		; print counter
	pop hl			; table pointer
	pop bc			; restore count
	djnz st_prtab		; loop
	ret

; st_rep_rate: Print throughput = bytes received * tick frequency /
; elapsed ticks (bytes per second over the whole transfer, including
; any retransmitted data).  Skipped if there is no elapsed time.
st_rep_rate:
	ld a,(st_t0ok)		; any data at all?
	or a			; ...
	ret z			; if not, nothing to print
	ld hl,st_t1		; elapsed ticks zero?
	ld a,(hl)		; ...
	inc hl			; ...
	or (hl)			; ...
	inc hl			; ...
	or (hl)			; ...
	inc hl			; ...
	or (hl)			; ...
	ret z			; if so, cannot divide
	ld a,(st_freq)		; ticks per second
	or a			; ...
	ret z			; unknown: skip
	ld b,a			; dividend := bytes * frequency
	ld hl,st_dvd		; ... (by repeated addition)
	call zero32		; ...
st_rep_rate1:
	push bc			; save count
	ld de,st_bytes		; dividend := bytes + dividend
	ld hl,st_dvd		; ...
	ld bc,st_dvd		; ...
	call add32		; ...
	pop bc			; restore count
	djnz st_rep_rate1	; loop
	ld hl,st_t1		; divisor := elapsed ticks
	ld de,st_dvs		; ...
	call copy32		; ...
	call st_div32		; st_dvd := st_dvd / st_dvs
	ld de,st_msg_rate	; print it
	call st_puts		; ...
	ld hl,st_dvd		; ...
	call st_put32		; ...
	ld de,st_msg_bps	; " bytes/s"
	jp st_puts		; ...

; st_div32: Unsigned 32-bit divide, st_dvd := st_dvd / st_dvs (the
; remainder is left in st_rem).  Shift-and-subtract over the 64-bit
; value st_rem:st_dvd, which must be contiguous (st_dvd first).
st_div32:
	ld hl,st_rem		; remainder := 0
	call zero32		; ...
	ld b,32			; 32 quotient bits
st_div32_1:
	push bc			; save bit count
	ld hl,st_dvd		; shift st_rem:st_dvd left one bit
	or a			; ... shifting in 0
	ld b,8			; ... 8 bytes, low byte first
st_div32_2:
	rl (hl)			; ...
	inc hl			; ...
	djnz st_div32_2		; ...
	ld hl,st_rem		; trial := remainder - divisor
	ld de,st_dvs		; ...
	ld bc,st_dtmp		; ...
	call sub32		; ... CF set on borrow
	jr c,st_div32_3		; divisor too big: quotient bit stays 0
	ld hl,st_dtmp		; remainder := trial
	ld de,st_rem		; ...
	call copy32		; ...
	ld hl,st_dvd		; quotient bit := 1
	set 0,(hl)		; ...
st_div32_3:
	pop bc			; restore bit count
	djnz st_div32_1		; loop
	ret

; st_put16: Print the 16-bit value at (HL) in decimal.
st_put16:
	ld e,(hl)		; DE := value
	inc hl			; ...
	ld d,(hl)		; ...
	ld hl,st_tmp		; widen to 32 bits
	call zero32		; ... (HL, DE preserved)
	ld (hl),e		; ...
	inc hl			; ...
	ld (hl),d		; ...
	dec hl			; ...
	; fall through

; st_put32: Print the 32-bit value at (HL) in decimal.
st_put32:
	ld de,st_numbuf		; text buffer
	call ltoa32		; convert, HL := end of text
	ld (hl),24H		; '$' terminator
	ld de,st_numbuf		; print it
	; fall through

; st_puts: Print the '$' terminated string at DE.
st_puts:
	ld c,C_WRITESTR		; BDOS function: C_WRITESTR
	jp BDOS			; display it

st_fills	.db	0,0,0,0	; refills
st_empty	.db	0,0,0,0	; refills that returned nothing
st_bytes	.db	0,0,0,0	; total bytes received via refills
st_hist		.fill	24,0	; refill size histogram, 6 x 32-bit
st_max		.db	0	; largest single refill
st_t0ok		.db	0	; FFH once start time is taken
st_frozen	.db	0	; FFH once the report has started (stop counting)
st_errs		.db	0,0,0,0	; receive errors counted (print_err_count calls)
st_posflag	.db	0	; FFH: next rx_data_error is a wrong-position error
st_src		.db	0	; what is being received: 1 = data subpacket, 2 = header
st_xstage	.db	0	; XMODEM block stage (see st_logxm / st_xstab)
st_xmn		.db	0	; XMODEM errors logged
st_xmlog	.fill	ST_XMMAX * ST_XMSZ,0	; XMODEM error log (see st_logxm)
st_xstab	.dw	st_msg_xs0,st_msg_xs1,st_msg_xs2,st_msg_xs3
		.dw	st_msg_xs4,st_msg_xs5,st_msg_xs6,st_msg_xs7
st_crcn		.db	0	; CRC/framing errors logged
st_crclog	.fill	ST_CRCMAX * ST_CRCSZ,0	; CRC/framing error log (see st_logcrc)
st_e_zri	.db	0,0,0,0	; ZRINIT handshake errors (start of session / between files)
st_e_tmo	.db	0,0,0,0	; timeouts waiting for a header or data
st_e_junk	.db	0,0,0,0	; 1024 junk bytes with no header found
st_e_znak	.db	0,0,0,0	; ZNAK headers received
st_e_hoth	.db	0,0,0,0	; other header errors
st_e_crc	.db	0,0,0,0	; header or data subpacket CRC/framing errors
st_e_pos	.db	0,0,0,0	; ZDATA for the wrong file position
st_e_xm		.db	0,0,0,0	; XMODEM bad blocks / CAN
st_c_zdata	.db	0,0,0,0	; ZDATA headers received
st_c_crcg	.db	0,0,0,0	; subpackets ended ZCRCG (more follows, no reply)
st_c_crcq	.db	0,0,0,0	; subpackets ended ZCRCQ (more follows, ZACK sent)
st_c_crcw	.db	0,0,0,0	; subpackets ended ZCRCW (sender waits, write + ZACK)
st_c_crce	.db	0,0,0,0	; subpackets ended ZCRCE (end of frame, header follows)
st_c_early	.db	0,0,0,0	; early buffer writes (EARLYWR)
st_t_zack	.db	0,0,0,0	; total ticks spent sending data-phase ZACKs
st_t_idle	.db	0,0,0,0	; total ticks in aux_wait_input with nothing arriving
st_c_idle	.db	0,0,0,0	; aux_wait_input passes that found nothing
st_inidle	.db	0	; FFH while an idle stretch is being timed
st_imark	.db	0,0,0,0	; start of the current idle stretch
st_zmark	.db	0,0,0,0	; start of the current ZACK
st_tnow		.db	0,0,0,0	; scratch: current time / interval
st_sub_tab	.dw	st_msg_s1,st_c_zdata
		.dw	st_msg_s2,st_c_crcg
		.dw	st_msg_s3,st_c_crcq
		.dw	st_msg_s4,st_c_crcw
		.dw	st_msg_s5,st_c_crce
		.dw	st_msg_s6,st_c_early
		.dw	st_msg_s7,st_t_zack
		.dw	st_msg_s8,st_t_idle
		.dw	st_msg_s9,st_c_idle
st_err_tab	.dw	st_msg_e1,st_e_zri
		.dw	st_msg_e2,st_e_tmo
		.dw	st_msg_e3,st_e_junk
		.dw	st_msg_e4,st_e_znak
		.dw	st_msg_e5,st_e_hoth
		.dw	st_msg_e6,st_e_crc
		.dw	st_msg_e7,st_e_pos
		.dw	st_msg_e8,st_e_xm
st_freq		.db	0	; timer tick frequency (Hz)
st_t0		.db	0,0,0,0	; start time (ticks)
st_t1		.db	0,0,0,0	; end time, then elapsed (ticks)
st_tmp		.db	0,0,0,0	; scratch 32-bit value
st_dvd		.db	0,0,0,0	; st_div32 dividend / quotient (must precede st_rem)
st_rem		.db	0,0,0,0	; st_div32 remainder
st_dvs		.db	0,0,0,0	; st_div32 divisor
st_dtmp		.db	0,0,0,0	; st_div32 trial subtraction
st_numbuf	.fill	12,0	; decimal text

st_msg_hdr	.db	0DH,0AH,"Receive statistics:",24H
st_msg_off	.db	0DH,0AH,"  Block receive not in use (byte mode calls; bytes not counted)",24H
st_msg_errs	.db	0DH,0AH,"  Receive errors:  ",24H
st_msg_abort	.db	" (transfer ABORTED)",24H
st_msg_e1	.db	0DH,0AH,"    ZRINIT handshake:   ",24H
st_msg_e2	.db	0DH,0AH,"    Timeout:            ",24H
st_msg_e3	.db	0DH,0AH,"    Junk, no header:    ",24H
st_msg_e4	.db	0DH,0AH,"    ZNAK from sender:   ",24H
st_msg_e5	.db	0DH,0AH,"    Other header:       ",24H
st_msg_e6	.db	0DH,0AH,"    CRC/framing/full:   ",24H
st_msg_e7	.db	0DH,0AH,"    Wrong position:     ",24H
st_msg_e8	.db	0DH,0AH,"    XMODEM bad block:   ",24H
st_msg_sub	.db	0DH,0AH,"  Data framing:",24H
st_msg_s1	.db	0DH,0AH,"    ZDATA headers:      ",24H
st_msg_s2	.db	0DH,0AH,"    ZCRCG (no reply):   ",24H
st_msg_s3	.db	0DH,0AH,"    ZCRCQ (ZACK sent):  ",24H
st_msg_s4	.db	0DH,0AH,"    ZCRCW (ZACK, wait): ",24H
st_msg_s5	.db	0DH,0AH,"    ZCRCE (end frame):  ",24H
st_msg_s6	.db	0DH,0AH,"    Early writes:       ",24H
st_msg_s7	.db	0DH,0AH,"    ZACK send ticks:    ",24H
st_msg_s8	.db	0DH,0AH,"    Idle ticks:         ",24H
st_msg_s9	.db	0DH,0AH,"    Idle passes:        ",24H
st_msg_x1	.db	0DH,0AH,"  XM err: ",24H
st_msg_x2	.db	", char ",24H
st_msg_x3	.db	"h, blk ",24H
st_msg_x4	.db	"h, last ",24H
st_msg_x5	.db	"h, due ",24H
st_msg_x6	.db	", pos ",24H
st_msg_xs0	.db	"?",24H
st_msg_xs1	.db	"start",24H
st_msg_xs2	.db	"blk num",24H
st_msg_xs3	.db	"data",24H
st_msg_xs4	.db	"CRC read",24H
st_msg_xs5	.db	"CRC bad",24H
st_msg_xs6	.db	"EOT junk",24H
st_msg_xs7	.db	"CAN",24H
st_msg_cl1	.db	0DH,0AH,"  CRC/framing/full at pos ",24H
st_msg_clh	.db	", header",24H
st_msg_cld	.db	", data",24H
st_msg_cl2	.db	", subpacket bytes ",24H
st_msg_cl3	.db	", buffer ",24H
st_msg_bytes	.db	0DH,0AH,"  Bytes received:  ",24H
st_msg_time	.db	0DH,0AH,"  Elapsed:         ",24H
st_msg_at	.db	" ticks at ",24H
st_msg_hz	.db	" Hz",24H
st_msg_rate	.db	0DH,0AH,"  Throughput:      ",24H
st_msg_bps	.db	" bytes/s",24H
st_msg_fills	.db	0DH,0AH,"  Refills:         ",24H
st_msg_empty	.db	", empty ",24H
st_msg_max	.db	0DH,0AH,"  Largest refill:  ",24H
st_msg_hist	.db	0DH,0AH,"  Refill sizes:",0DH,0AH,24H
; Histogram labels: each exactly 8 bytes including the '$'
st_msg_h0	.db	"    1: ",24H
st_msg_h1	.db	"  2-3: ",24H
st_msg_h2	.db	"  4-7: ",24H
st_msg_h3	.db	" 8-15: ",24H
st_msg_h4	.db	" 16-31:",24H
st_msg_h5	.db	"   32+:",24H
st_msg_crlf	.db	0DH,0AH,24H
#ENDIF

; ----------------------------------------------------------------------
; Miscellaneous diagnostic support
; ----------------------------------------------------------------------
;
; print the hex word value in hl
;
prt_hex_word:
	push af
	ld a,h
	call prt_hex
	ld a,l
	call prt_hex
	pop af
	ret
;
; print the hex byte value in a
;
prt_hex:
	push af
	push de
	call hexascii
	ld a,d
	call cout
	ld a,e
	call cout
	pop de
	pop af
	ret

;
; convert binary value in a to ascii hex characters in de
;
hexascii:
	ld d,a
	call hexconv
	ld e,a
	ld a,d
	rlca
	rlca
	rlca
	rlca
	call hexconv
	ld d,a
	ret
;
; convert low nibble of a to ascii hex
;
hexconv:
	and 0FH	     		;low nibble only
	add a,90H
	daa
	adc a,40H
	daa
	ret

;
; print character in a
;
cout:
	push af
	push bc
	push de
	push hl
	ld e,a			; character to print in e
	ld c,C_WRITE		; bdos function to output a character
	call BDOS		; do it
	pop hl
	pop de
	pop bc
	pop af
	ret

; Address of arg_table, the start of the free memory (initialised in the image)
arg_table_ptr:
	.dw arg_table

; ---- Uninitialised RAM work area above the program image ----
; .ds only reserves space: nothing here is stored in the .COM file.
default_user		.ds 1		; User number at program start
default_drive		.ds 1		; Drive (1 = A:) at program start
saved_user		.ds 1		; User number to select (pair with work_fcb drive byte)
work_fcb		.ds 33		; FCB for the file being received (starts with the drive byte; r0-r2 follow)
work_fcb_r0		.ds 3		; Random record number r0-r2 of work_fcb (FCB offsets 33-35)
work_fcb_r3		.ds 1		; Extra byte after the 36-byte FCB (offset 36), not a standard FCB field: kept
					; zero so r0-r3 can be used as one 32-bit number
aux_ring		.ds 6		; AUX receive ring buffer control block: count, head, tail; 4096 data bytes follow
aux_ring_data		.ds RINGSZ	; Data area of the AUX receive ring (RINGSZ bytes)
file_buf_count		.ds 1		; Output sector buffer: number of bytes currently held (0-128)
file_buf_wr		.ds 1		; Output sector buffer: write index
file_buf_rd		.ds 1		; Output sector buffer: read index
file_sector_buf		.ds 128		; 128-byte file sector buffer (also the DMA address for file I/O)
ltoa_value		.ds 4		; ltoa32: working copy of the 32-bit value being converted
ltoa_temp		.ds 4		; ltoa32: temporary 32-bit subtraction result
crc32_value		.ds 4		; Running CRC-32 accumulator (4 bytes)
			.ds (0 - $) & 0FFH	; page-align the CRC-32 table
crc32_table		.ds 1024	; CRC-32 lookup table: four 256-byte planes (see crc32_update)
; Protocol state area: cleared by receive_main (rx_state..rx_state_end)
rx_state:
escape_ctl_flag		.ds 1		; Nonzero (40H) if the sender requested escaping of all control characters
					; (TESCCTL)
rx_crc_mode		.ds 1		; Link CRC type: 10H = CRC-16, 20H = CRC-32, 0 = XMODEM checksum
zfile_zf3		.ds 1		; ZFILE header byte ZF3 (ZF3..ZF0 are stored in received order)
zfile_zf2		.ds 1		; ZFILE header byte ZF2 (transport option), not used by the code
zfile_zf1		.ds 1		; ZFILE ZF1, management option: ZMAPND 3 = append to existing file, ZMPROT 7 =
					; protect existing file, ...
zfile_zf0		.ds 1		; ZFILE ZF0, conversion option: ZCBIN 1 = binary, ZCNL 2 = convert newlines to
					; the local convention
protect_option		.ds 1		; 0, or 07H (ZMPROT) when the -p option forces protection
file_open_flag		.ds 1		; FFH while an output file is open
header_ok_flag		.ds 1		; FFH once a valid header has been received
rx_header_data		.ds 4		; Four argument bytes of the most recently received header
file_position		.ds 4		; Current file position, 32 bits (next byte expected)
attn_string		.ds 32		; Attention string from ZSINIT (up to 32 bytes), sent to the sender on errors
			.ds 1		; not referenced by the code
info_argv		.ds 1		; Argument table built from the ZFILE data subpacket: max entries
info_argc		.ds 1		; ... number of entries found
info_name_ptr		.ds 2		; ... pointer to the file name string
info_size_ptr		.ds 2		; ... pointer to the file length/info string
			.ds 10		; not referenced by the code
tx_header_data		.ds 4		; Four argument bytes for the next header to send (position / flags)
rx_header_copy		.ds 4		; Copy of the received header arguments
tx_frame_type		.ds 1		; Frame type of the header being sent
rx_buffer_base		.ds 2		; Start address of the receive data buffer
rx_buffer_size		.ds 2		; Size of the receive data buffer
rx_buffer_ptr		.ds 2		; Next free byte in the receive buffer
rx_buffer_count		.ds 2		; Number of bytes in the receive buffer
			.ds 2		; not referenced by the code
rx_saved_ptr		.ds 2		; Saved receive buffer pointer (see rx_pos_save)
rx_saved_count		.ds 2		; Saved byte count; amount to write to the file
			.ds 2		; not referenced by the code
subpacket_len		.ds 4		; Length of the last data subpacket (32 bits, added to file_position)
subpkt_term		.ds 1		; Terminator of the last data subpacket (ZCRCE/G/Q/W | 80H)
rx_state_end:				; end of the state area cleared by receive_main
hdr_junk_limit		.ds 2		; get_header: remaining number of junk characters tolerated
hdr_can_count		.ds 1		; get_header: remaining CAN characters before abort
rx_frame_type		.ds 1		; Frame type of the last header received
xm_first_flag		.ds 1		; FFH until the first valid XMODEM block has arrived
xm_timeout		.ds 1		; XMODEM receive timeout in tenths of a second
error_count		.ds 1		; Consecutive error/retry counter
xm_block_len		.ds 2		; XMODEM bytes still to read in the current block
xm_block_no		.ds 1		; Expected XMODEM block number
xm_rx_char		.ds 1		; Last character received in XMODEM block handling
xm_can_flag		.ds 1		; Set after one CAN, abort on the second
parse_mode		.ds 1		; parse_filespec argument (nonzero: try DU form / named directory)
parse_next_char		.ds 1		; Character following the parsed name
wildcard_count		.ds 1		; Number of wildcard characters in the file name
parsed_drive		.ds 1		; Drive from the file spec (0 = default)
parsed_user		.ds 1		; User number from the file spec
bios_bid		.ds 1		; HBIOS BIOS bank id
xfer_unit		.ds 1		; HBIOS file transfer char unit number
con_unit		.ds 1		; HBIOS console unit number
con_xfer		.ds 1		; non-zero indicates xfer on console unit
z3env_ptr		.ds 2		; Address of the ZCPR3 environment descriptor (0 if none)
arg_table		.ds 6		; Argument pointers table built by tokenize_args: maximum count, count found, two
					; token pointers; the receive buffer starts here and overwrites it later
	.end
