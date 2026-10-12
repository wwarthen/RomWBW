; RZ.COM  --  X/Y/ZMODEM receive program for CP/M 3 (rz v1.04, W. Schmitten 1992)
; RZ.COM v1.04
; Disassembly of the CP/M 3 ZMODEM/YMODEM/XMODEM program (Z80). Reassembles byte-identical to the original .COM.
; Source is in TASM syntax (dotted directives); assembled and verified with uz80as.
; Modem is on the CP/M AUX device (BDOS 3/4/7/8). Option letters: ? P B C R X Y Z (R = resume).
; Tables: key bytes searched with CPIR, then N vectors in REVERSE key order, jumped to via the dispatch routine.
; Labels L#### = code, D#### = data, V#### = work RAM above the image, X#### = patched operand bytes.
; Comments were cross-checked against an independent disassembly of the same binaries (rzsz2),
; the ZMODEM specification and the rz.c / sz.c sources.

; Constants: names and values come from rzsz2 (cpm3.inc and zmodem.inc), descriptions are quoted as written;
; entries marked "added in this disassembly" are not defined by rzsz2.
; rzsz2 also defines SCB_QERR, SCB_DMAERR and SCB_DISKERR; this program does not use them and they are not adopted.

; ----------------------------------------------------------------------
; CP/M 3 page zero locations
; ----------------------------------------------------------------------
CPM			.equ 0000H	; Warm Boot Jump Vector (0000h: JP BIOS+3)
IOBYTE			.equ 0004H	; Intel I/O Byte (CP/M 2.2) / Current Drive & User (CP/M 3)
BDOS			.equ 0005H	; BDOS Function Call Entry Point (0005h: JP BDOS)
BDOSVEC			.equ 0006H	; BDOS address = top of the TPA  (added in this disassembly)
DEFAULT_FCB		.equ 005CH	; Default File Control Block 1 (FCB)
DEFAULT_FCB2		.equ 006CH	; Default File Control Block 2 (FCB)
DEFAULT_DMA		.equ 0080H	; Default DMA / Command Tail Buffer (128 bytes)

; ----------------------------------------------------------------------
; CP/M 3 BDOS function numbers
; ----------------------------------------------------------------------
C_READ			.equ 1		; Function 1: Console Input (waits for char)
C_WRITE			.equ 2		; Function 2: Console Output (char in E)
A_READ			.equ 3		; Function 3: Auxiliary / Reader Input
A_WRITE			.equ 4		; Function 4: Auxiliary / Punch Output
C_RAWIO			.equ 6		; Function 6: Direct Console I/O
A_STATIN		.equ 7		; Function 7: Auxiliary Input Status (A=00h not ready, FFh ready)
A_STATOUT		.equ 8		; Function 8: Auxiliary Output Status (A=00h not ready, FFh ready)
A_STAT_OUT		.equ 8		; Compatibility alias for A_STATOUT
C_WRITESTR		.equ 9		; Function 9: Write String to Console (DE points to string ending in '$')
C_STAT			.equ 11		; Function 11: Console Status (A=00h not ready, FFh ready)
S_BDOSVER		.equ 12		; Function 12: Return BDOS Version Number (A=30h for CP/M 3.0+)
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
F_MULTISEC		.equ 44		; Function 44: Set Multi-Sector Count (E = record count 1-128)
S_SYSVAR		.equ 49		; Function 49: Get / Set System Control Block (SCB) Variables

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
; Buffered file object (CIO) layout
; ----------------------------------------------------------------------
CIO_FLAG		.equ 0		; Channel state / open flag (00h=closed, FFh=open)
CIO_COUNT		.equ 1		; Remaining bytes in sector buffer (0..128)
CIO_PTR			.equ 2		; Pointer to current byte in sector buffer (16-bit)
CIO_FCB			.equ 4		; Embedded CP/M File Control Block (36 bytes)
CIO_BUF			.equ 28H	; Sector data buffer (128 bytes)
CIO_BUF_OFF		.equ 26H	; Offset from CIO_PTR (+2) to CIO_BUF (+28h)
CIO_SIZE		.equ 0A8H	; Total channel control block size (168 bytes)

; ----------------------------------------------------------------------
; System Control Block (SCB) offsets (read and written with BDOS S_SYSVAR)
; ----------------------------------------------------------------------
SCB_CIVEC		.equ 22H	; SCB offset 22H: console input redirection vector  (added in this disassembly)
SCB_COVEC		.equ 24H	; SCB offset 24H: console output redirection vector  (added in this disassembly)
SCB_AOVEC		.equ 28H	; SCB offset 28H: auxiliary (modem) output redirection vector (added in this
					; disassembly)

; ----------------------------------------------------------------------
; ZCPR3 environment descriptor offsets
; ----------------------------------------------------------------------
Z3_NDR_OFF		.equ 15H	; Named Directory table pointer offset (16-bit word)
Z3_MDRV_OFF		.equ 2CH	; Maximum drive number offset (1 byte)
Z3_MUSR_OFF		.equ 2DH	; Maximum user number offset (1 byte)
Z3_DUOK_OFF		.equ 2EH	; ZCPR3 environment: "DU: form allowed" flag (called Z3_WHEEL_OFF in rzsz2) (added in
					; this disassembly)
Z3_WHEEL_OFF		.equ Z3_DUOK_OFF	; the name rzsz2 uses for the same offset

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
					; (added in this disassembly)
GOTCRCG			.equ ZCRCG+80H	; ZCRCG received  (added in this disassembly)
GOTCRCQ			.equ ZCRCQ+80H	; ZCRCQ received  (added in this disassembly)
GOTCRCW			.equ ZCRCW+80H	; ZCRCW received  (added in this disassembly)
GOTCAN			.equ ZDLE+80H	; CAN CAN received while reading a header or subpacket  (added in this disassembly)

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
; start: Program entry: check for CP/M 3, show banner, parse command line,
; run the transfer, restore the default drive/user and exit.
; ----------------------------------------------------------------------
start:
	ld sp,aux_ring			; the stack grows down from the work area
	ld c,S_BDOSVER			; this program needs CP/M 3 (BDOS 3.0)
	call BDOS			; S_BDOSVER: get the BDOS version
	cp 30H				; BDOS version 3.0 or later?
	jp c,err_need_cpm3		; no: refuse to run
	ld de,msg_banner		; point DE at banner text
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; show the banner
	call get_default_du		; remember the current drive/user
	ld hl,(argv_ptr)		; HL -> free memory used for the argument table
	xor a				; clear the table
	ld b,14H			; fill 20 bytes
	call memset			; fill B bytes at HL with A
	ld a,(DEFAULT_DMA)		; is there a command tail?
	or a				; Is command tail empty?
	jr z,L0174			; no arguments: go straight to waiting for the sender
	ld (hl),02H			; argument table holds at most two entries
	ld de,0082H			; DE -> command tail text
	ex de,hl			; swap pointers
	ld a,0FFH			; terminate each argument with a zero
	call tokenize_args		; split the command tail
	jp nz,usage_exit		; too many arguments: show usage
	ld hl,(argv_ptr)		; get pointer to the argument table built by tokenize_args
	inc hl				; HL -> argument count
	ld a,(hl)			; A = (HL)
	or a				; no arguments?
	jp z,L0174			; none: start the transfer
	inc hl				; First argument token entry
	ld e,(hl)			; DE -> first argument
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	inc hl				; HL++
	ld a,(de)			; does it start with "-" ?
	cp 2DH				; compare A with 2DH
	jr nz,L0152			; no: it is a file specification
	call parse_options		; yes: process the option letters
	ld e,(hl)			; DE -> second argument, if any
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	ld a,d				; A = D
	or e				; A |= E
	jr z,L0174			; no file specification given
L0152:
	ld hl,work_fcb			; point HL at FCB for the file being received
	ex de,hl			; swap pointers
	call parse_filespec		; parse [du:]filename
	ld hl,work_fcb			; point HL at FCB for the file being received
	xor a				; no drive given?
	or (hl)				; Did filespec specify an explicit drive?
	jr nz,L0164			; if result is nonzero goto L0164
	ld a,(default_drive)		; use the current drive
	ld (hl),a			; store into FCB for the file being received
L0164:
	ld bc,FCB_S1			; Point to user number field in FCB extension
	add hl,bc			; HL += BC
	dec de				; DE--
	ldi				; copy the user number
	ld de,work_fcb			; point DE at FCB for the file being received
	call set_du			; select that drive and user for the received files
	call opt_xmodem			; a named file implies XMODEM
L0174:
	ld de,msg_start_sender		; ask the user to start the sending program
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	call scb_setup			; change console settings for the transfer
	call receive_main		; do the transfer
	call scb_restore		; put the console settings back
L0185:
	ld bc,0000H			; BC = original user/drive (patched at start)
restore_du		.equ L0185+1	; default user/drive restored at exit (patched operand)
	ld (saved_user),bc		; save as user number to select
	ld de,work_fcb			; point DE at FCB for the file being received
	call set_du			; go back to the original drive and user
	jp CPM				; exit to CP/M

; ----------------------------------------------------------------------
; get_default_du: Save the current user number and drive (from
; IOBYTE/0004H) so they can be restored at exit.
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
; err_need_cpm3: Print "sorry, CP/M 3 Tool" and exit.
; ----------------------------------------------------------------------
err_need_cpm3:
	ld de,msg_need_cpm3		; point DE at "sorry, CP/M 3 Tool"
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message

; ----------------------------------------------------------------------
; usage_exit: Print the usage/help text and exit to CP/M.
; ----------------------------------------------------------------------
usage_exit:
	ld de,msg_usage			; point DE at usage / help text
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	jp CPM				; loop back to L0000
; Banner text
msg_banner:
	.db "RZ for CP/M 3   V 1.04",0DH,0AH
	.db "(C) 92 wshbg",0DH,0AH
	.db 0AH
	.db 24H
; "start your local ... sending program"
msg_start_sender:
	.db "start your local X/Y/ZModem sending program",0DH,0AH
	.db 0AH
	.db 24H
; "sorry, CP/M 3 Tool"
msg_need_cpm3:
	.db "sorry, CP/M 3 Tool",0DH,0AH
	.db 24H
; Usage / help text
msg_usage:
	.db "usage: rz [-?pbcrxyz] [du:fn]",0DH,0AH
	.db 0AH
	.db " options for ZModem:",0DH,0AH
	.db "            ?     this help",0DH,0AH
	.db "            p     protect File",0DH,0AH
	.db "            b     receive binary",0DH,0AH
	.db "            c     convert to local linefeed",0DH,0AH
	.db "            r     resume transmission",0DH,0AH
	.db "            x,y,z Protokoll",0DH,0AH
	.db "            du:fn defaults to XModem",0DH,0AH
	.db 0AH
	.db "these values override options from sender",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; parse_options: Scan a "-xyz" option string; each letter is looked up in
; the option key table and its handler is run.
; ----------------------------------------------------------------------
parse_options:
	push hl				; preserve HL
	push de				; preserve DE
L039C:
	inc de				; Advance to next character in argument string
	ld a,(de)			; A = (DE)
	or a				; Test for null terminator (end of string)
	jr z,L03AE			; if result is zero goto L03AE
	ld hl,D03B1			; point HL at D03B1
	ld bc,0008H			; 8 keys in the table
	cpir				; look A up in the key table
	call z,dispatch			; if A is in the key list goto dispatch
	jr L039C			; loop back to L039C
L03AE:
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
D03B1:
	.db 3FH,50H,42H,43H,58H,59H,5AH,52H	; keys: ?PBCXYZR
	.dw opt_resume			; key 52H 'R'
	.dw opt_zmodem			; key 5AH 'Z'
	.dw opt_ymodem			; key 59H 'Y'
	.dw opt_xmodem			; key 58H 'X'
	.dw opt_convert			; key 43H 'C'
	.dw opt_binary			; key 42H 'B'
	.dw opt_protect			; key 50H 'P'
	.dw usage_exit			; key 3FH '?'

; ----------------------------------------------------------------------
; opt_xmodem: Option X: select XMODEM.
; ----------------------------------------------------------------------
opt_xmodem:
	ld a,01H			; protocol 1 = XMODEM
	jr set_protocol			; continue at set_protocol

; ----------------------------------------------------------------------
; opt_ymodem: Option Y: select YMODEM.
; ----------------------------------------------------------------------
opt_ymodem:
	ld a,03H			; protocol 3 = YMODEM
	jr set_protocol			; continue at set_protocol

; ----------------------------------------------------------------------
; opt_zmodem: Option Z: select ZMODEM.
; ----------------------------------------------------------------------
opt_zmodem:
	ld a,04H			; protocol 4 = ZMODEM

; ----------------------------------------------------------------------
; set_protocol: Store protocol number in A (1=XMODEM, 3=YMODEM, 4=ZMODEM).
; ----------------------------------------------------------------------
set_protocol:
	ld (protocol),a			; save as selected protocol
	ret				; return

; ----------------------------------------------------------------------
; opt_protect: Option P: protect existing files (do not overwrite).
; ----------------------------------------------------------------------
opt_protect:
	ld a,0FFH			; set the -p flag (protect an existing file)
	ld (opt_protect_flag),a		; FFH if -p = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; opt_binary: Option B: binary transfer.
; ----------------------------------------------------------------------
opt_binary:
	ld a,0FFH			; set the -b flag (binary transfer)
	ld (opt_binary_flag),a		; FFH if -b = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; opt_convert: Option C: convert to local linefeed convention.
; ----------------------------------------------------------------------
opt_convert:
	ld a,0FFH			; set the -c flag (convert line ends)
	ld (opt_convert_flag),a		; FFH if -c = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; opt_resume: Option R: resume an interrupted transmission.
; ----------------------------------------------------------------------
opt_resume:
	ld a,0FFH			; set the -r flag (resume an interrupted transfer)
	ld (opt_resume_flag),a		; FFH if -r = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; scb_setup: Detach the modem port from the console: read AOVEC (SCB 28H)
; via BDOS 49 and clear its devices from COVEC (24H) and CIVEC (22H),
; keeping the originals.
; ----------------------------------------------------------------------
scb_setup:
	xor a				; prepare "get" requests (set code 0) for the three SCB fields
	ld (scb_aovec_code),a		; clear S_SCB set code for the AOVEC block
	ld (scb_covec_code),a		; clear S_SCB set code for the COVEC block
	ld c,S_SYSVAR			; BDOS 49 (S_SCB): get/set a System Control Block field
	ld de,scb_pb_aovec		; point DE at S_SCB parameter block
	call BDOS			; read AOVEC: the physical devices that serve as AUX (modem) output
	ld a,h				; invert it: the mask keeps every device NOT used for AUX output
	cpl				; invert A (one's complement)
	ld h,a				; H = A
	ld a,l				; A = L
	cpl				; invert A (one's complement)
	ld l,a				; L = A
	ld (scb_aovec_mask),hl		; save as complement of AOVEC
	ld c,S_SYSVAR			; BDOS function: S_SCB
	ld de,scb_pb_covec		; point DE at S_SCB parameter block
	call BDOS			; read COVEC: the devices that serve as console output
	ld (scb_sv_covec),hl		; remember the original so it can be restored at exit
	ld de,(scb_aovec_mask)		; get complement of AOVEC
	ld a,h				; remove the AUX devices from the console output vector ...
	and d				; A &= D
	ld h,a				; H = A
	ld a,l				; A = L
	and e				; A &= E
	ld l,a				; L = A
	ld (scb_covec_val),hl		; ... and keep the result as the new COVEC value
	ld c,S_SYSVAR			; BDOS function: S_SCB
	ld de,scb_pb_civec		; point DE at S_SCB parameter block
	call BDOS			; read CIVEC: the devices that serve as console input
	ld (scb_sv_civec),hl		; remember the original so it can be restored at exit
	ld de,(scb_aovec_mask)		; get complement of AOVEC
	ld a,h				; remove the AUX devices from the console input vector too
	and d				; A &= D
	ld h,a				; H = A
	ld a,l				; A = L
	and e				; A &= E
	ld l,a				; L = A
	ld (scb_civec_val),hl		; new CIVEC value (console and modem no longer share a device)
L0437:
	ld a,0FEH			; set code FEH = write a word into the SCB
	ld (scb_covec_code),a		; S_SCB set code for the COVEC block = FEH
	ld de,scb_pb_covec		; point DE at S_SCB parameter block
	ld c,S_SYSVAR			; BDOS function: S_SCB
	call BDOS			; write the new COVEC
	ld a,0FEH			; 0FEh = Set word in SCB parameter block
	ld (scb_civec_code),a		; S_SCB set code for the CIVEC block = FEH
	ld de,scb_pb_civec		; point DE at S_SCB parameter block
	ld c,S_SYSVAR			; BDOS function: S_SCB
	jp BDOS				; write the new CIVEC and return

; ----------------------------------------------------------------------
; scb_restore: Put the original console input/output redirection vectors
; (CIVEC, COVEC) back into the System Control Block.
; ----------------------------------------------------------------------
scb_restore:
	ld hl,(scb_sv_covec)		; put the original COVEC and CIVEC back into the parameter blocks ...
	ld (scb_covec_val),hl		; save as COVEC value word of its parameter block
	ld hl,(scb_sv_civec)		; get original CIVEC value, restored at exit
	ld (scb_civec_val),hl		; save as CIVEC value word of its parameter block
	jr L0437			; ... and write them to the System Control Block
; S_SCB parameter block: SCB offset 28H = AOVEC, the auxiliary (modem) output redirection vector
scb_pb_aovec:
	.db SCB_AOVEC
; S_SCB set code for the AOVEC block (0 = get)
scb_aovec_code:
	.db 00H
	.db 00H
	.db 00H
; S_SCB parameter block: SCB offset 24H = COVEC, the console output redirection vector
scb_pb_covec:
	.db SCB_COVEC
; S_SCB set code for the COVEC block (0 = get, FEH = set word)
scb_covec_code:
	.db 00H
; COVEC value word of its parameter block
scb_covec_val:
	.db 00H
	.db 00H
; S_SCB parameter block: SCB offset 22H = CIVEC, the console input redirection vector
scb_pb_civec:
	.db SCB_CIVEC
; S_SCB set code for the CIVEC block (0 = get, FEH = set word)
scb_civec_code:
	.db 00H
; CIVEC value word of its parameter block
scb_civec_val:
	.db 00H
	.db 00H
; Original COVEC value, restored at exit
scb_sv_covec:
	.db 00H
	.db 00H
; Original CIVEC value, restored at exit
scb_sv_civec:
	.db 00H
	.db 00H
; Complement of AOVEC: keeps the devices that are not used for AUX output
scb_aovec_mask:
	.db 00H
	.db 00H

; ----------------------------------------------------------------------
; bdos_check: Call BDOS (function in C) and set Z/NZ from the result in A.
; ----------------------------------------------------------------------
bdos_check:
	call BDOS			; Invoke BDOS service function in C
	or a				; Test accumulator return code; set Z/NZ flags
	ret				; return

; ----------------------------------------------------------------------
; skip_strings: Advance HL past B zero-terminated strings.
; ----------------------------------------------------------------------
skip_strings:
	push af				; preserve AF
L0477:
	push bc				; preserve BC
	xor a				; Search target character = 00h (null terminator)
	ld b,a				; BC = 0000h (search up to 65,536 bytes)
	ld c,a				; C = A
	cpir				; look A up in the key table
	pop bc				; restore BC
	djnz L0477			; repeat until all B items are done
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; print_err_count: Print the current error count / retry message on the
; console.
; ----------------------------------------------------------------------
print_err_count:
	ld a,(error_count)		; get consecutive error/retry counter
	ld de,D0495			; point DE at D0495
	call a_to_decimal		; convert A to up to three decimal digits at DE
	ld de,msg_errors		; point DE at " error
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display " error
; " error(s)" message
msg_errors:
	.db 0DH,0AH
D0495:
	.db 00H
	.db 00H
	.db 00H
	.db " error(s)",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; print_filename: Print the current file name (DU:NAME.EXT) and its size.
; ----------------------------------------------------------------------
print_filename:
	ld de,work_fcb			; point DE at FCB for the file being received
	ld hl,D04F8			; point HL at D04F8
	ld (hl),3AH			; store into D04F8
	inc hl				; Advance to filename buffer
	xor a				; Fill byte = 00h
	ld b,0DH			; fill 13 bytes
	call memset			; fill B bytes at HL with A
	inc de				; Advance DE past drive byte to filename field (8+3)
	call fcb_to_name		; format the FCB name at DE as NAME.EXT at HL
	dec de				; Back up DE to drive byte
	ld a,(de)			; Load 1-based drive number (1=A, 2=B...)
	add a,40H			; A += 40H
	ld (D04F4),a			; save as D04F4
	dec de				; Back up DE to user number byte
	ld a,(de)			; Load user number (0..15)
	ld de,D04F5			; point DE at D04F5
	call a_to_decimal		; convert A to up to three decimal digits at DE
	ld a,24H			; String terminator character
	ld (D0507),a			; D0507 = 24H
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
	ld de,D0508			; point DE at D0508
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display the $-terminated message
; Console line buffer: CR LF, "d:" and file name
name_line_buf:
	.db 0DH,0AH
D04F4:
	.db 00H
D04F5:
	.db 00H
	.db 00H
	.db 00H
D04F8:
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
D0507:
	.db 00H
D0508:
	.db 0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; print_position: Print the current file position as a decimal number on
; the console.
; ----------------------------------------------------------------------
print_position:
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,D051F			; point DE at D051F
	call ltoa32			; convert file_position to decimal text at D051F
	ld (hl),24H			; Append '$' string terminator
	ld de,pos_line_buf		; point DE at console line buffer for the position display
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display console line buffer for the position display
; Console line buffer for the position display
pos_line_buf:
	.db 0DH
D051F:
	.fill 10,0
spinner_entry:
	.db 21H

; ----------------------------------------------------------------------
; show_spinner: Advance and print the rotating "|/-\" activity spinner.
; ----------------------------------------------------------------------
show_spinner:
	ld b,h				; B = H
	dec b				; B--
L052C:
	ld a,00H			; A = 00H
spinner_index		.equ L052C+1	; spinner phase 0-3 (patched operand)
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
	.db "|/-",5CH
; Spinner message: blank, spinner char, two backspaces, "$"
spinner_msg:
	.db 20H
; Spinner character being displayed
spinner_char:
	.db 7CH,08H,08H,24H

; ----------------------------------------------------------------------
; print_cant_open: Print "can't open any file".
; ----------------------------------------------------------------------
print_cant_open:
	ld de,msg_cant_open		; point DE at "can't open any file"
	jr L0555			; continue at L0555

; ----------------------------------------------------------------------
; print_skipped: Print "File skipped".
; ----------------------------------------------------------------------
print_skipped:
	ld de,msg_file_skipped		; point DE at "File skipped"
L0555:
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display the $-terminated message
; "File skipped"
msg_file_skipped:
	.db "File skipped",0DH,0AH
	.db 24H
; "can't open any file"
msg_cant_open:
	.db "can",27H,"t open any file",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; set_pending_char: Queue A (count in C) as pending input characters; used
; to inject CANs when ESC is pressed.
; ----------------------------------------------------------------------
set_pending_char:
	ld hl,pending_char		; point HL at queued input character
	ld (hl),a			; store into queued input character
	inc hl				; Advance HL to buffer count byte
	ld (hl),c			; store into queued input character
	ret				; return
; Queued input character (see set_pending_char)
pending_char:
	.db 00H
; Number of times pending_char is still to be delivered
pending_count:
	.db 00H

; ----------------------------------------------------------------------
; aux_poll_input: Poll the AUX device (BDOS A_STATIN/A_READ) and move any
; waiting characters into the receive ring buffer.
; ----------------------------------------------------------------------
aux_poll_input:
	or a				; test A (sets Z if A = 0)
	ld hl,(aux_ring)		; get AUX receive ring buffer control block
	ld de,1000H			; DE = maximum receive ring buffer capacity
	sbc hl,de			; HL -= DE + carry
	jr z,L05A9			; If buffer is full, do not read; check available count
	ld c,A_STATIN			; BDOS function: A_STATIN
	call BDOS			; A_STATIN: is a character waiting at the AUX port?
	or a				; test A (sets Z if A = 0)
	jr z,L05A9			; if result is zero goto L05A9
	ld c,A_READ			; BDOS function: A_READ
	call BDOS			; A_READ: read a character from the AUX (modem) port
	ld c,a				; C = received character byte
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_put			; insert byte C into the receive ring buffer
	jr aux_poll_input		; loop back to aux_poll_input
L05A9:
	ld hl,pending_count		; point HL at number of times pending_char is still to be delivered
	or (hl)				; Test if single-byte buffer holds a character
	ret nz				; Return NZ if character ready
	ld hl,(aux_ring)		; get AUX receive ring buffer control block
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	ret				; return

; ----------------------------------------------------------------------
; aux_get_char: Fetch next input character: pending queued char first,
; otherwise from the ring buffer. NZ if a char was returned.
; ----------------------------------------------------------------------
aux_get_char:
	ld a,(pending_count)		; get number of times pending_char is still to be delivered
	or a				; Is single-byte buffer empty?
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	jp z,ring_get			; if number of times pending_char is still to be delivered is zero/clear goto ring_get
	push af				; preserve AF
	ld hl,pending_count		; point HL at number of times pending_char is still to be delivered
	dec (hl)			; count down number of times pending_char is still to be delivered
	dec hl				; HL--
	pop af				; restore AF
	ld a,(hl)			; get a byte of number of times pending_char is still to be delivered
	ret				; return

; ----------------------------------------------------------------------
; aux_putc: Write the character in A to the AUX (modem) device.
; ----------------------------------------------------------------------
aux_putc:
	ld c,A_WRITE			; BDOS function: A_WRITE
	ld e,a				; E = A
	jp BDOS				; A_WRITE: send the character in E to the AUX (modem) port

; ----------------------------------------------------------------------
; aux_out_ready: Test whether the AUX output is ready (BDOS A_STATOUT).
; ----------------------------------------------------------------------
aux_out_ready:
	ld c,A_STATOUT			; BDOS function: A_STATOUT
	call BDOS			; A_STATOUT: is the AUX port ready for output?
	or a				; Test status in A (0 = busy, FFh = ready)
	ret				; return

; ----------------------------------------------------------------------
; aux_wait_input: Wait roughly 100 ms-steps for an input character;
; returns it in A with NZ, Z on timeout.
; ----------------------------------------------------------------------
aux_wait_input:
	push bc				; preserve BC
	ld b,5FH			; repeat count = 95
L05D7:
	push bc				; preserve BC
	call aux_poll_input		; poll the AUX device
	pop bc				; restore BC
	jr nz,L05E6			; if input was waiting goto L05E6
	call delay_short		; short software delay loop
	djnz L05D7			; repeat until all B items are done
	call aux_poll_input		; poll the AUX device
L05E6:
	call nz,aux_get_char		; If byte ready (NZ), fetch it into A
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; delay_short: Short software delay loop.
; ----------------------------------------------------------------------
delay_short:
	push bc				; preserve BC
	ld a,04H			; Outer delay loop count = 4
	ld b,00H			; repeat count = 0
L05F0:
	djnz L05F0			; repeat until all B items are done
	dec a				; Decrement outer loop count
	jr nz,L05F0			; Loop until outer count reaches 0
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
	and 0FH				; keep the low nibble
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
	ld hl,1000H			; HL = ring capacity
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
	and 0FH				; keep the low nibble
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
	jr L0650			; continue at L0650

; ----------------------------------------------------------------------
; file_buf_reset: Reset the 128-byte file sector buffer control block.
; ----------------------------------------------------------------------
file_buf_reset:
	ld b,03H			; Count = 3 bytes to clear
	jr L0650			; continue at L0650

; ----------------------------------------------------------------------
; ring_reset: Clear the 6-byte ring buffer control block at HL.
; ----------------------------------------------------------------------
ring_reset:
	ld b,06H			; Count = 6 bytes to clear
L0650:
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
	jr L0697			; continue at L0697

; ----------------------------------------------------------------------
; copy32: Copy 32-bit value (HL) to (DE).
; ----------------------------------------------------------------------
copy32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ldi				; Copy byte 1: (DE) = (HL), increment pointers, dec BC
L0697:
	ldi				; Copy byte 2
	ldi				; Copy byte 3
	ldi				; Copy byte 4
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return
	push hl				; preserve HL
	pop ix				; restore IX
	push de				; preserve DE
	pop iy				; restore IY
	ld a,(ix+3)			; Compare most significant bytes (signs)
	xor (iy+3)			; A ^= (iy+3)
	jp p,L06B6			; If signs are identical, do unsigned compare
	xor (ix+3)			; Restore sign byte
L06B3:
	ret m				; return if negative
	ccf				; complement carry
	ret				; return
L06B6:
	xor (ix+3)			; Restore sign byte
	jp p,cmp32_unsigned		; If positive, perform standard 32-bit subtract compare
	call cmp32_unsigned		; unsigned compare of 32-bit values
	scf				; flag failure to caller (carry set)
	jr L06B3			; loop back to L06B3

; ----------------------------------------------------------------------
; cmp32_unsigned: Unsigned compare of 32-bit values (HL) and (DE).
; ----------------------------------------------------------------------
cmp32_unsigned:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	or a				; test A (sets Z if A = 0)
	ld b,04H			; repeat count = 4
L06C9:
	ld a,(de)			; Load subtrahend byte
	sbc a,(hl)			; Subtract with borrow minuend byte
	inc de				; Advance subtrahend pointer
	inc hl				; Advance minuend pointer
	djnz L06C9			; repeat until all B items are done
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; eq32: Compare 32-bit values (HL) and (DE) for equality (Z if equal).
; ----------------------------------------------------------------------
eq32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ld b,04H			; repeat count = 4
L06D8:
	ld a,(de)			; Load byte from first buffer
	xor (hl)			; Compare with byte from second buffer
	jr nz,L06E0			; If mismatch found, exit with NZ
	inc de				; Advance first pointer
	inc hl				; Advance second pointer
	djnz L06D8			; repeat until all B items are done
L06E0:
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; add32: (BC) = (DE) + (HL), 32-bit.
; ----------------------------------------------------------------------
add32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	or a				; test A (sets Z if A = 0)
	ex af,af'			; Save cleared carry in alternate AF
	ld a,04H			; 4 bytes to add (32 bits)
L06EB:
	ex af,af'			; Restore carry from previous byte addition
	ld a,(de)			; Load addend byte from (DE)
	adc a,(hl)			; Add with carry addend byte from (HL)
	ld (bc),a			; Store sum byte to destination (BC)
	inc bc				; Advance destination pointer
	inc de				; Advance source pointer 1
	inc hl				; Advance source pointer 2
	ex af,af'			; Preserve carry in alternate AF
	dec a				; Decrement loop byte count
	jr nz,L06EB			; Continue for all 4 bytes
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; sub32: (BC) = (HL) - (DE), 32-bit.
; ----------------------------------------------------------------------
sub32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	or a				; test A (sets Z if A = 0)
	ex af,af'			; Save cleared borrow in alternate AF
	ld a,04H			; 4 bytes to subtract (32 bits)
L0702:
	ex af,af'			; Restore borrow from previous byte subtraction
	ld a,(de)			; Load minuend byte from (DE)
	sbc a,(hl)			; Subtract with borrow subtrahend byte from (HL)
	ld (bc),a			; Store difference byte to destination (BC)
	inc bc				; Advance destination pointer
	inc hl				; Advance subtrahend pointer
	inc de				; Advance minuend pointer
	ex af,af'			; Preserve borrow in alternate AF
	dec a				; Decrement loop byte count
	jr nz,L0702			; Continue for all 4 bytes
	ex af,af'			; swap AF with AF'
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return
	push bc				; preserve BC
	push hl				; preserve HL
	ld a,01H			; Add 1 to lowest byte
	add a,(hl)			; A += (HL)
	ld (hl),a			; Store updated low byte
	jr nc,L0723			; If no overflow, increment complete
	ld b,03H			; repeat count = 3
L071C:
	inc hl				; Advance to next higher byte
	ld a,00H			; Add carry bit
	adc a,(hl)			; A += (HL) + carry
	ld (hl),a			; Store updated byte
	djnz L071C			; repeat until all B items are done
L0723:
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; set32_minus1: Set the 32-bit value at (HL) to -1 (0FFFFFFFFH).
; ----------------------------------------------------------------------
set32_minus1:
	call zero32			; set the 32-bit value at

; ----------------------------------------------------------------------
; dec32: Decrement the 32-bit value at (HL).
; ----------------------------------------------------------------------
dec32:
	push bc				; preserve BC
	push hl				; preserve HL
	ld a,(hl)			; Load low byte
	sub 01H				; Subtract 1 from lowest byte
	ld (hl),a			; Store updated low byte
	ld b,03H			; repeat count = 3
L0731:
	inc hl				; Advance to next higher byte
	ld a,(hl)			; Load byte
	sbc a,00H			; Subtract borrow bit
	ld (hl),a			; Store updated byte
	djnz L0731			; repeat until all B items are done
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	ld a,04H			; Process 4 bytes (32 bits)
L0741:
	push af				; preserve AF
	ld a,(de)			; Load byte from source 1
	and (hl)			; Bitwise AND with byte from source 2
	ld (bc),a			; Store result byte into destination
	inc bc				; Advance destination pointer
	inc de				; Advance source 1 pointer
	inc hl				; Advance source 2 pointer
	pop af				; restore AF
	dec a				; Decrement byte counter
	jr nz,L0741			; Repeat for all 4 bytes
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return
; Powers of ten for ltoa32: 10^9 down to 10, each a 32-bit little-endian value
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
; ----------------------------------------------------------------------
ltoa32:
	ld (ltoa_outptr),de		; remember where the text goes
	ld de,ltoa_value		; point DE at working copy of the 32-bit value being converted
	call copy32			; work on a copy of the value
	ld c,09H			; up to nine digits plus the final one
	ld de,pow10_table-4		; DE -> 4 bytes before the table of powers of ten (stepped forward before each use)
	xor a				; A = 0
	ld (ltoa_started),a		; no digit emitted yet (suppress leading zeros)
L0787:
	ld a,30H			; start the digit at "0"
	ld (ltoa_digit),a		; digit character being built = 30H
	inc de				; step to the next power of ten (4 bytes)
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	ld b,0AH			; at most ten subtractions per digit
L0792:
	push bc				; preserve BC
	ld hl,ltoa_value		; point HL at working copy of the 32-bit value being converted
	ld bc,ltoa_temp			; point BC at temporary 32-bit subtraction result
	call sub32			; temp = value - power of ten
	pop bc				; restore BC
	jr c,L07B3			; value is smaller than the power: this digit is complete
	push de				; preserve DE
	ld a,(ltoa_digit)		; count one more subtraction
	inc a				; A++
	ld (ltoa_digit),a		; save as digit character being built
	ld de,ltoa_value		; point DE at working copy of the 32-bit value being converted
	ld hl,ltoa_temp			; point HL at temporary 32-bit subtraction result
	call copy32			; value = remainder
	pop de				; restore DE
	djnz L0792			; try subtracting again
L07B3:
	ld a,30H			; digit finished: is it "0"?
ltoa_digit		.equ L07B3+1	; ltoa32: digit character being built (patched operand)
	cp 30H				; Is it a leading zero ('0')?
	jr nz,L07BE			; non-zero digit: always emit it
L07B9:
	ld a,00H			; a zero: emit only if a digit was already emitted
ltoa_started		.equ L07B9+1	; ltoa32: nonzero once a nonzero digit has been emitted
	or a				; test A (sets Z if A = 0)
	jr z,L07CB			; leading zero: skip it
L07BE:
	ld hl,0000H			; HL = output pointer
ltoa_outptr		.equ L07BE+1	; ltoa32: output pointer (patched operand, 16 bits)
	ld (hl),a			; store the digit
	inc hl				; Advance output pointer
	ld (ltoa_outptr),hl		; advance the output pointer
	ld a,30H			; mark that digits have started
	ld (ltoa_started),a		; nonzero once a nonzero digit has been emitted = 30H
L07CB:
	dec c				; next power of ten
	jr nz,L0787			; Process next decimal position
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
; ----------------------------------------------------------------------
checksum_add:
	push af				; preserve AF
L07DE:
	add a,00H			; Add byte to running 8-bit checksum accumulator
xm_checksum		.equ L07DE+1	; running 8-bit XMODEM checksum (patched operand)
	ld (xm_checksum),a		; save as running 8-bit XMODEM checksum
	pop af				; restore AF
	ret				; return
; CRC-32 polynomial 0EDB88320H (little endian)
crc32_poly:
	.db 20H,83H,0B8H,0EDH
; CRC-32 residue 0DEBB20E3H expected after a good frame
crc32_residue:
	.db 0E3H,20H,0BBH,0DEH

; ----------------------------------------------------------------------
; crc32_update: Update the running CRC-32 with byte A.
; ----------------------------------------------------------------------
crc32_update:
	push af				; preserve AF
L07EE:
	ld iy,crc32_table		; point IY at CRC-32 lookup table, 256 x 4 bytes
crc32_tab_ptr		.equ L07EE+2	; address of the CRC-32 table (patched operand, 16 bits)
	ld ix,crc32_value		; point IX at running CRC-32 accumulator
	xor (ix+0)			; Index = input byte XOR lowest CRC byte
	ld h,00H			; HL = table entry index * 4
	ld l,a				; L = A
	add hl,hl			; Multiply index by 2
	add hl,hl			; Multiply index by 4
	ld b,h				; BC = index * 4
	ld c,l				; C = L
	add iy,bc			; IY points to 4-byte CRC table entry
	ld a,(iy+0)			; Byte 0: Table[0] XOR CRC[1]
	xor (ix+1)			; A ^= (ix+1)
	ld (ix+0),a			; set byte 0 of running CRC-32 accumulator
	ld a,(iy+1)			; Byte 1: Table[1] XOR CRC[2]
	xor (ix+2)			; A ^= (ix+2)
	ld (ix+1),a			; set byte 1 of running CRC-32 accumulator
	ld a,(iy+2)			; Byte 2: Table[2] XOR CRC[3]
	xor (ix+3)			; A ^= (ix+3)
	ld (ix+2),a			; set byte 2 of running CRC-32 accumulator
	ld a,(iy+3)			; Byte 3: Table[3]
	ld (ix+3),a			; set byte 3 of running CRC-32 accumulator
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; crc32_table_init: Build the 256-entry CRC-32 lookup table.
; ----------------------------------------------------------------------
crc32_table_init:
	push de				; preserve DE
	push hl				; preserve HL
	ld hl,(crc32_tab_ptr)		; HL = start of the CRC table
	ld bc,03FFH			; table is 1024 bytes
	add hl,bc			; HL -> last byte (table is built backwards)
	push hl				; preserve HL
	pop iy				; IY = write pointer
	ld ix,crc32_poly		; IX -> the CRC-32 polynomial
	xor a				; start with table index 0
L0836:
	push af				; keep the index
	ld hl,0FFFFH			; CRC register = FFFFFFFFH (HL:DE)
	ld de,0FFFFH			; DE = 0FFFFH
	xor e				; mix the index into the low byte
	ld e,a				; E = A
	ld b,08H			; eight bit steps
L0841:
	scf				; shift in a 1 ...
	rr h				; ... shifting the 32-bit register right
	rr l				; rotate right through carry L
	rr d				; rotate right through carry D
	rr e				; rotate right through carry E
	jr nc,L0860			; bit shifted out was 0: no polynomial
	ld a,e				; bit was 1: XOR in the polynomial
	xor (ix+0)			; A ^= (ix+0)
	ld e,a				; E = A
	ld a,d				; XOR byte 1 with polynomial byte 1
	xor (ix+1)			; A ^= (ix+1)
	ld d,a				; D = A
	ld a,l				; XOR byte 2 with polynomial byte 2
	xor (ix+2)			; A ^= (ix+2)
	ld l,a				; L = A
	ld a,h				; XOR high byte with polynomial byte 3
	xor (ix+3)			; A ^= (ix+3)
	ld h,a				; H = A
L0860:
	djnz L0841			; next bit
	ld a,h				; store the inverted result, high byte first (table is filled downwards)
	cpl				; invert A (one's complement)
	ld (iy+0),a			; Store high byte in table
	dec iy				; Move down 1 byte
	ld a,l				; One's complement byte 2
	cpl				; invert A (one's complement)
	ld (iy+0),a			; Store byte 2 in table
	dec iy				; Move down 1 byte
	ld a,d				; One's complement byte 1
	cpl				; invert A (one's complement)
	ld (iy+0),a			; Store byte 1 in table
	dec iy				; Move down 1 byte
	ld a,e				; One's complement low byte
	cpl				; invert A (one's complement)
	ld (iy+0),a			; Store low byte in table
	dec iy				; Move down 1 byte
	pop af				; recover the index
	inc a				; next table entry
	jr nz,L0836			; repeat for all 256 entries
	pop hl				; restore HL
	pop de				; restore DE
	ret				; return

; ----------------------------------------------------------------------
; crc16_update: Update the running CRC-16 (CCITT, polynomial 1021H) with
; byte A. [updcrc]
; ----------------------------------------------------------------------
crc16_update:
	push af				; preserve AF
L0886:
	ld hl,0000H			; SMC: Running CRC-16 accumulator operand
crc16_lo		.equ L0886+1	; CRC-16 low byte (patched operand)
crc16_hi		.equ L0886+2	; CRC-16 high byte (patched operand)
	ld de,1021H			; CCITT CRC-16 polynomial generator (x^16 + x^12 + x^5 + 1)
	xor h				; XOR input byte with current high byte of CRC
	ld h,a				; Store XOR result into high byte of CRC
	ld b,08H			; Process 8 bits
L0890:
	add hl,hl			; Shift CRC left by 1 bit (HL << 1)
	jr nc,L0899			; If no carry shifted out, skip polynomial XOR
	ld a,h				; XOR high byte with polynomial high byte (10h)
	xor d				; A ^= D
	ld h,a				; H = A
	ld a,l				; XOR low byte with polynomial low byte (21h)
	xor e				; A ^= E
	ld l,a				; L = A
L0899:
	djnz L0890			; repeat until all B items are done
	ld (crc16_lo),hl		; save as CRC-16 low byte
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; crc_init: Reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH.
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
protocol:
	.db 04H
; FFH if -p (protect existing files) was given
opt_protect_flag:
	.db 00H
; FFH if -c (convert to local line feeds) was given
opt_convert_flag:
	.db 00H
; FFH if -b (binary) was given
opt_binary_flag:
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
L08BB:
	rlca				; Rotate highest bit into carry
	set 7,c				; Set highest bit of mask
	jr c,L08C4			; When highest set bit encountered, mask is complete
	rr c				; Shift mask right
	djnz L08BB			; repeat until all B items are done
L08C4:
	ld a,h				; A = top page byte
	and c				; Align memory boundary to power-of-two mask
	ld h,a				; HL = page-aligned memory buffer ceiling
	ld l,00H			; L = 00H
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
	ld hl,escape_ctl_flag		; point HL at nonzero
	ld b,61H			; fill 97 bytes
	call memset			; fill B bytes at HL with A
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_reset			; empty the modem input ring
	call crc32_table_init		; prepare the CRC-32 table
	ld hl,(argv_ptr)		; the file buffer starts after the argument table ...
	ld (rx_buffer_base),hl		; save as start address of the receive data buffer
	ld de,(BDOSVEC)			; ... and ends at the top of the TPA
	ex de,hl			; swap pointers
	or a				; Clear carry
	sbc hl,de			; HL = free memory size
	call calc_buffer_mask		; round it to a usable buffer size
	ld a,(opt_protect_flag)		; get FFH if -p
	cp 00H				; compare A with 00H
	jr z,L08FD			; if A = 00H goto L08FD
	ld a,ZF1_ZMPROT			; -p given: ZMPROT
L08FD:
	ld (protect_option),a		; save as 0, or 07H
	ld a,10H			; assume CRC-16
	ld (crc_mode),a			; link CRC type = 10H (CRC-16)
	ld a,(protocol)			; XMODEM (below 3)?
	cp 03H				; is it YMODEM?
	jr c,L0947			; yes
	ld a,ZRINIT			; ZMODEM/YMODEM: first send ZRINIT
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 01H (ZRINIT)
	call zrinit_handshake		; talk to the sender
	jp c,abort_receive		; if handshake failed / aborted goto abort_receive
	or a				; result 0: sender is using YMODEM
	jr z,L092B			; if result is zero goto L092B
	cp ZFILE			; ZFILE: a ZMODEM file follows
	jr z,L0924			; if A is ZFILE goto L0924
	cp ZCOMPL			; ZCOMPL: nothing to do
	jr nz,L0924			; if A is not ZCOMPL goto L0924
	jr L0953			; done
L0924:
	call zmodem_rx_files		; receive files until ZFIN
	jr c,abort_receive		; if carry goto abort_receive
	jr L0953			; continue at L0953
L092B:
	ld a,03H			; YMODEM batch receive
	ld (protocol),a			; selected protocol = 03H (YMODEM)
	xor a				; Clear error count
	ld (error_count),a		; clear consecutive error/retry counter
	call xmodem_rx_start		; get the first (block 0) packet
	jr c,abort_receive		; if no sender / aborted goto abort_receive
	call prep_output_file		; create the file named in block 0
	jr c,abort_receive		; if cannot create output file / abort goto abort_receive
	jr z,L0953			; empty name: end of the batch
	call xmodem_rx_file		; receive the file
	jr c,abort_receive		; if receive failed / aborted goto abort_receive
	jr L092B			; next file of the batch
L0947:
	call prep_output_file		; XMODEM: file name came from the command line
	jr c,abort_receive		; if cannot create output file / abort goto abort_receive
	jr z,L0953			; On success, exit
	call xmodem_rx_file		; receive all blocks of an XMODEM/YMODEM file
	jr c,abort_receive		; if receive failed / aborted goto abort_receive
L0953:
	ret				; return

; ----------------------------------------------------------------------
; abort_receive: Abort: send the cancel string and close any open file.
; ----------------------------------------------------------------------
abort_receive:
	call send_can_string		; send eight+ CAN characters followed by backspaces to
	ld a,(file_open_flag)		; get FFH while an output file is open
	cp 0FFH				; compare A with 0FFH
	call z,close_outfile		; if A = FFH: call close_outfile
	jr L0953			; loop back to L0953

; ----------------------------------------------------------------------
; prep_output_file: Work out transfer options and file name for the
; incoming file, check/handle an existing file and create the output file.
; [rz.c procheader]
; ----------------------------------------------------------------------
prep_output_file:
	ld a,(opt_convert_flag)		; work out whether data is stored unchanged (binary) or CR LF-translated
	cpl				; FFH if -c was not given
	ld hl,opt_binary_flag		; point HL at FFH if -b
	or (hl)				; -b forces binary
	ld (binary_mode_flag),a		; save as FFH = store data unmodified
	ld a,(protect_option)		; did -p force the protect option?
	or a				; test A (sets Z if A = 0)
	jr z,L0975			; if 0, or 07H is zero/clear goto L0975
	ld (zfile_zf1),a		; yes: override the sender's management option
L0975:
	ld a,(opt_binary_flag)		; -b given: ignore the sender's conversion request
	cp 0FFH				; compare A with 0FFH
	jr z,L0988			; if A = FFH goto L0988
	ld a,(zfile_zf0)		; sender asks for newline conversion (ZCNL)?
	cp ZF0_ZCNL			; compare A with 02H
	jr nz,L0988			; if A != 02H goto L0988
	ld a,00H			; yes: translate
	ld (binary_mode_flag),a		; FFH = store data unmodified = 00H (clear)
L0988:
	ld a,(zfile_zf0)		; sender says the file is binary (ZCBIN)?
	cp ZF0_ZCBIN			; compare A with 01H
	jr nz,L0994			; if A != 01H goto L0994
	ld a,0FFH			; yes: store it unchanged
	ld (binary_mode_flag),a		; FFH = store data unmodified = FFH (set)
L0994:
	ld a,(zfile_zf1)		; management option: protect (ZMPROT)?
	cp ZF1_ZMPROT			; compare A with 07H
	jr z,L09AE			; if A = 07H goto L09AE
	ld a,(zfile_zf1)		; append (ZMAPND) ...
	cp ZF1_ZMAPND			; compare A with 03H
	jr nz,L09AE			; if A != 03H goto L09AE
	ld a,(binary_mode_flag)		; ... of a binary file?
	cp 0FFH				; compare A with 0FFH
	jr nz,L09AE			; if A != FFH goto L09AE
	ld a,ZF1_ZMPROT			; appending binary data is not supported: treat as protect
	ld (zfile_zf1),a		; ZFILE ZF1, management option = 07H
L09AE:
	ld a,(protocol)			; XMODEM takes its file name from the command line
	cp 03H				; is it YMODEM?
	jr c,L09E3			; if A < 03H goto L09E3
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
L09E3:
	call print_filename		; show the name on the console
	ld de,work_fcb			; point DE at FCB for the file being received
	call file_exists		; does the file already exist?
	jr nz,handle_existing		; yes: decide what to do
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_MAKE			; no: create it (F_MAKE)
	call bdos_check			; call BDOS
	ret c				; cannot create the file
	ld a,0FFH			; Mark file open and active
	ld (file_open_flag),a		; file is open
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_reset		; start with an empty sector buffer
	ld a,(info_argc)		; did the sender give a size?
	cp 02H				; compare A with 02H
	jr c,L0A0D			; if A < 02H goto L0A0D
load_file_size:
	ld de,(info_size_ptr)		; get ... pointer to the file length/info string
L0A0D:
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
	jr nz,L0A24			; no: just replace the file
	ld a,(zfile_zf1)		; sender asked for ZMPROT (protect)?
	cp ZF1_ZMPROT			; compare A with 07H
	jr nz,L0A35			; if A != 07H goto L0A35
	jr L0A2E			; protect: skip this file
L0A24:
	ld de,work_fcb			; delete the old file (F_DELETE) and create it again
	ld c,F_DELETE			; C = 13H
	call bdos_check			; call BDOS
	jr nc,L09E3			; deleted: go on and create the new file
L0A2E:
	call print_skipped		; file skipped (protected or cannot be replaced)
	ld a,ZSKIP			; tell the sender: ZSKIP
	scf				; flag failure to caller (carry set)
	ret				; return
L0A35:
	ld a,(zfile_zf1)		; append (ZMAPND) requested?
	cp ZF1_ZMAPND			; compare A with 03H
	jr z,L0A43			; yes: open and position at the end
	ld a,(opt_resume_flag)		; otherwise resume only if -r was given
	cp 0FFH				; compare A with 0FFH
	jr nz,L0A24			; no: replace the file
L0A43:
	ld de,file_sector_buf		; open the existing file and find its length
	ld c,F_DMAOFF			; set DMA address
	call BDOS			; F_DMAOFF: set the DMA (transfer) address
	ld e,01H			; one sector at a time
	ld c,F_MULTISEC			; BDOS function: F_MULTISEC
	call BDOS			; F_MULTISEC: set multi-sector count
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_OPEN			; open the file
	call bdos_check			; call BDOS
	ret c				; If open failed, return carry
	ld a,0FFH			; Mark file active
	ld (file_open_flag),a		; FFH while an output file is open = FFH (set)
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_reset		; reset the 128-byte file sector buffer control block
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_SIZE			; compute the file size in records
	call bdos_check			; call BDOS
	ret c				; Return if error
	ld hl,work_fcb_r3		; point HL at random record overflow byte of work_fcb
	ld (hl),00H			; store into random record overflow byte of work_fcb
	ld hl,work_fcb_r0		; last record = size - 1
	call dec32			; subtract 1 from work_fcb_r0
	ld de,file_position		; point DE at current file position, 32 bits
	call copy32			; start from the last record number
	ex de,hl			; swap pointers
	ld b,07H			; multiply by 128 to get a byte position
L0A83:
	push hl				; preserve HL
	sla (hl)			; shift left (HL)
	inc hl				; HL++
	rl (hl)				; rotate left through carry (HL)
	inc hl				; HL++
	rl (hl)				; rotate left through carry (HL)
	inc hl				; HL++
	rl (hl)				; rotate left through carry (HL)
	pop hl				; restore HL
	djnz L0A83			; repeat until all B items are done
	ld de,work_fcb			; point DE at FCB for the file being received
	ld c,F_READRAND			; read that last record
	call bdos_check			; call BDOS
	ret c				; Return if error
	ld a,(zfile_zf1)		; append?
	cp ZF1_ZMAPND			; compare A with 03H
	jr z,L0AA6			; if A = 03H goto L0AA6
	ld a,ZRPOS			; resume: answer ZRPOS from the end of the existing data
	or a				; test A (sets Z if A = 0)
	ret				; return
L0AA6:
	ld a,80H			; append: look for the ^Z that marks the true end of a text file
	ld (file_buf_count),a		; output sector buffer = 80H
L0AAB:
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_get		; get next byte from the sector buffer
	jr z,L0AC6			; if buffer empty goto L0AC6
	cp 1AH				; end-of-file marker?
	jr nz,L0AAB			; if A != 1AH goto L0AAB
	ld a,(file_buf_rd)		; found: position the buffer just before it
	dec a				; A--
	ld (file_buf_wr),a		; save as output sector buffer
	ld hl,file_buf_count		; point HL at output sector buffer
	ld a,7FH			; A = 7FH
	sub (hl)			; A -= (HL)
	jr L0AC8			; continue at L0AC8
L0AC6:
	ld a,80H			; no ^Z: the sector is full of data
L0AC8:
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
	ld hl,D0B96			; point HL at D0B96
	ld bc,000AH			; 10 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; Count an error, then try again.
zri_count_err:
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
	jr L0B68			; continue at L0B68
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
	jr nz,L0B6A			; if A is not GOTCRCW goto L0B6A
	ld hl,(rx_buffer_base)		; get start address of the receive data buffer
	ld de,attn_string		; point DE at attention string from ZSINIT
	ld bc,0020H			; 32 bytes
	ldir				; keep the Attn string from the ZSINIT data packet (up to 32 bytes)
					; [zrbdata(Attn,ZATTNLEN)]
L0B68:
	ld a,ZACK			; A = 03H
L0B6A:
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
	jr nz,L0B6A			; if A is not GOTCRCW goto L0B6A
	pop bc				; restore BC
	ld a,ZFILE			; return ZFILE
	ret				; return
D0B96:
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
	jr z,L0BC2			; if A is ZEOF goto L0BC2
	cp ZSKIP			; is it ZSKIP?
	jr z,L0BC2			; if A is ZSKIP goto L0BC2
	or a				; test A (sets Z if A = 0)
	ret				; return
L0BC2:
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
	jr nc,L0BDF			; if output file ready goto L0BDF
	ld a,ZSKIP			; cannot accept the file: reply ZSKIP [rzfile: zshhdr(ZSKIP)]
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 05H (ZSKIP)
	or a				; test A (sets Z if A = 0)
	ret				; return
L0BDF:
	cp ZRPOS			; did prep_output_file set up a resume (ZRPOS from the old end of file)?
	jr z,L0BE9			; if A = 09H goto L0BE9
	ld hl,file_position		; point HL at current file position, 32 bits
	call zero32			; clear file_position
L0BE9:
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
	call get_header			; receive a ZMODEM header
	ld hl,D0CE4			; point HL at D0CE4
	ld bc,0007H			; 7 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; Timeout, ZNAK or garbage: count the error (10 allowed) and send ZRPOS again.
rx_header_error:
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
	jr z,L0C50			; Success: clear state
L0C47:
	ld a,ZFERR			; A = 0CH
	ld (zri_frame_type),a		; frame type sent in the ZRINIT loop = 0CH (ZFERR)
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
L0C50:
	call clear_fcb			; zero the 37-byte FCB at HL
	ld a,ZEOF			; return ZEOF
	or a				; test A (sets Z if A = 0)
	ret				; return
; Bad or misplaced data: count the error, send the Attn string to stop the sender, then ZRPOS.
rx_data_error:
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
	ld hl,error_count		; point HL at consecutive error/retry counter
	ld a,0AH			; A = 0AH (LF)
	cp (hl)				; is consecutive error/retry counter = 0AH?
	jr nz,L0C6A			; if not zero goto L0C6A
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
L0C6A:
	ld hl,attn_string		; error: send the Attn string to interrupt the sender's streaming [zmputs(Attn)]
	call send_string		; send the zero-terminated string at HL to the modem
	jp rx_send_zrpos		; loop back to rx_send_zrpos
; ZDATA: its offset must equal the bytes received so far, otherwise resynchronise with ZRPOS.
rx_got_zdata:
	ld de,rx_header_data		; point DE at four argument bytes of the most recently received header
	ld hl,file_position		; point HL at current file position, 32 bits
	call eq32			; compare file_position with rx_header_data
	jp nz,rx_data_error		; if values differ goto rx_data_error
; Receive one data subpacket and act on how it ended (ZCRCE/G/Q/W).
rx_get_data:
	call spinner_entry		; show progress
	call rx_data_subpkt		; receive the next data subpacket [zrbdata]
	ld hl,D0CF9			; point HL at D0CF9
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
	call advance_position		; ZCRCE: end of frame, a header follows, no reply
	jp rx_wait_header		; loop back to rx_wait_header
; ZCRCG: more data follows immediately; no reply.
rx_got_crcg:
	call advance_position		; ZCRCG: more data follows, no reply
	jp rx_get_data			; loop back to rx_get_data
; ZCRCQ: more data follows; acknowledge the position with ZACK.
rx_got_crcq:
	call advance_position		; ZCRCQ: more data follows, ZACK expected
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy file_position to tx_header_data
	ld a,ZACK			; frame type = ZACK
	call send_hex_header		; send a hex header
	jp rx_get_data			; loop back to rx_get_data
; ZCRCW: write the buffered data to disk and acknowledge with ZACK; the sender waits for it.
rx_got_crcw:
	call advance_position		; ZCRCW: sender waits for a reply (the buffer is written to disk now)
	call write_buf_file		; write the received data buffer to the file
	jp c,L0C47			; if disk write error goto L0C47
	ld hl,file_position		; point HL at current file position, 32 bits
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy file_position to tx_header_data
	ld a,ZACK			; frame type = ZACK
	call send_hex_header		; send a hex header
	jp rx_wait_header		; loop back to rx_wait_header
D0CE4:
	.db ZNAK,0FEH,ZFILE,ZEOF,0FFH,ZDATA,0FCH	; keys: .......
	.dw rx_header_error		; key 0FCH too much junk
	.dw rx_got_zdata		; key 0AH ZDATA
	.dw rx_data_error		; key 0FFH error
	.dw rx_got_zeof			; key 0BH ZEOF
	.dw rx_got_zfile_2		; key 04H ZFILE
	.dw rx_header_error		; key 0FEH timeout
	.dw rx_header_error		; key 06H ZNAK
D0CF9:
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
L0D15:
	ld a,1AH			; CP/M EOF marker (Ctrl-Z = 1Ah)
	call file_putc			; write byte A to the file via the sector buffer
	ret c				; return: disk write error
	ld hl,file_buf_count		; point HL at output sector buffer
	ld a,01H			; A = 01H
	cp (hl)				; is output sector buffer = 01H?
	jr nz,L0D15			; Continue padding until 128-byte boundary reached
	ld a,00H			; A = 00H
	ld (file_open_flag),a		; FFH while an output file is open = 00H (clear)
	ld c,F_CLOSE			; C = 10H
	ld de,work_fcb			; point DE at FCB for the file being received
	jp bdos_check			; loop back to bdos_check

; ----------------------------------------------------------------------
; write_buf_file: Write the received data buffer to the file,
; translating CR/LF if text conversion is on. [rz.c putsec]
; ----------------------------------------------------------------------
write_buf_file:
	ld bc,(rx_saved_count)		; BC = number of bytes received
	ld a,b				; nothing to write?
	or c				; A |= C
	ret z				; Return immediately if buffer empty
	ld hl,(rx_buffer_base)		; HL -> data
L0D3A:
	ld a,(binary_mode_flag)		; binary transfer: store bytes unchanged
	cp 0FFH				; compare A with 0FFH
	jr z,L0D52			; if A = FFH goto L0D52
L0D41:
	ld a,00H			; previous character (patched)
prev_char		.equ L0D41+1	; previous character written to the file (patched operand)
	cp 0DH				; text mode: LF after CR is already CR LF
	jr z,L0D52			; if A = 0DH goto L0D52
	ld a,(hl)			; a lone LF ...
	cp 0AH				; Is current character lone LF?
	jr nz,L0D52			; if A != 0AH goto L0D52
	ld a,0DH			; ... gets a CR in front of it
	call file_putc			; write byte A to the file via the sector buffer
	ret c				; disk error
L0D52:
	ld a,(hl)			; store the data byte
	ld (prev_char),a		; remember it for the CR LF test
	inc hl				; Advance memory buffer pointer
	dec bc				; Decrement pending byte counter
	call file_putc			; write byte A to the file via the sector buffer
	ret c				; disk error
	ld a,b				; more bytes?
	or c				; A |= C
	jr nz,L0D3A			; Loop until entire memory buffer flushed
	call print_position		; show progress
	call rx_buffer_reset		; buffer is empty again
	xor a				; success
	ret				; return

; ----------------------------------------------------------------------
; file_putc: Write byte A to the file via the sector buffer.
; ----------------------------------------------------------------------
file_putc:
	ld (file_char),a		; save as character being stored into the sector buffer
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
L0D6E:
	ld c,00H			; Load character byte into C
file_char		.equ L0D6E+1	; character being stored into the sector buffer (patched operand)
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_put		; store byte C in the sector buffer
	jr nz,L0D97			; if byte stored goto L0D97
	ld hl,file_buf_count		; point HL at output sector buffer
	call file_buf_reset		; reset the 128-byte file sector buffer control block
	ld c,F_DMAOFF			; BDOS function: F_DMAOFF
	ld de,file_sector_buf		; point DE at 128-byte file sector buffer
	call BDOS			; F_DMAOFF: set the DMA (transfer) address
	ld c,F_MULTISEC			; BDOS function: F_MULTISEC
	ld e,01H			; E = 01H
	call BDOS			; F_MULTISEC: set multi-sector count
	ld c,F_WRITE			; C = 15H
	ld de,work_fcb			; point DE at FCB for the file being received
	call bdos_check			; call BDOS
	jr nc,L0D6E			; If write succeeded, re-push any remaining bytes
L0D97:
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
L0DA3:
	push bc				; preserve BC
	ld a,ZFIN			; frame type = ZFIN
	call send_hex_header		; send a hex header
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,L0DB8			; if timed out waiting for the modem goto L0DB8
	cp 4FH				; is it 'O'?
	jr z,L0DBC			; if A is 'O' goto L0DBC
	cp 0FDH				; compare A with 0FDH
	jr z,L0DBC			; if A = FDH goto L0DBC
L0DB8:
	pop bc				; restore BC
	djnz L0DA3			; repeat until all B items are done
	push bc				; preserve BC
L0DBC:
	pop bc				; restore BC
	ld b,01H			; wait up to 0.1 s
	call aux_getc_timeout		; get a character from the modem with timeout
	xor a				; return 0 (success)
	ret				; return
; Ten CAN (18H) followed by ten backspaces, zero terminated
cancel_string:
	.db 18H,18H,18H,18H,18H,18H,18H,18H,18H,18H,08H,08H,08H,08H,08H
	.db 08H,08H,08H,08H,08H,00H

; ----------------------------------------------------------------------
; send_can_string: Send eight+ CAN characters followed by backspaces to
; abort the peer. [canit]
; ----------------------------------------------------------------------
send_can_string:
	ld hl,cancel_string		; point HL at ten CAN

; ----------------------------------------------------------------------
; send_string: Send the zero-terminated string at HL to the modem. [rz.c
; zmputs]
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
; tenths of a second). Carry set on timeout; checks ESC at console.
; [readline]
; ----------------------------------------------------------------------
aux_getc_timeout:
	push bc				; preserve BC
	call console_status		; console input status
	call nz,console_read		; if a key was pressed: call console_read
	cp 1BH				; Was ESC pressed (1Bh)?
	ld a,18H			; A = 18H (ZDLE/CAN)
	ld c,0AH			; C = 0AH
	call z,set_pending_char		; if A = 1BH: call set_pending_char
	pop bc				; restore BC
L0DF8:
	call aux_wait_input		; wait roughly 100 ms-steps for an input character
	jr nz,L0E03			; if a character arrived goto L0E03
	djnz L0DF8			; repeat until all B items are done
	ld a,0FEH			; Timeout status code (0FEh)
	scf				; flag failure to caller (carry set)
	ret				; return
L0E03:
	or a				; test A (sets Z if A = 0)
	ret				; return

; ----------------------------------------------------------------------
; getc_7bit_filt: Get a modem char, strip bit 7 and ignore
; XON/XOFF/CR/LF/ZDLE. [zm.c noxrd7]
; ----------------------------------------------------------------------
getc_7bit_filt:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	and 7FH				; strip the parity bit (7-bit ASCII)
	ld hl,D0E2A			; point HL at D0E2A
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jr z,getc_7bit_filt		; if A is in the key list goto getc_7bit_filt
	ld bc,0003H			; 3 keys in the table
	cpir				; look A up in the key table
	ret z				; return: A is in the key list
	ld b,a				; Preserve character in B
	and 60H				; isolate bits 5-6: zero means a control character
	jr nz,L0E28			; if result is nonzero goto L0E28
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr nz,getc_7bit_filt		; if nonzero is set/nonzero goto getc_7bit_filt
L0E28:
	ld a,b				; Restore received character in A
	ret				; return
D0E2A:
	.db 11H,13H			; keys: ..
	.db 0DH,0AH
	.db 18H

; ----------------------------------------------------------------------
; getc_zdl_filt: Get a modem char, ignore XON/XOFF and decode ZDLE
; escapes. [zm.c zdlread]
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
	ld hl,D0EA2			; point HL at D0EA2
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
; ----------------------------------------------------------------------
zdlread_escape:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,L0E74			; if A is not ZDLE/CAN goto L0E74
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,L0E74			; if A is not ZDLE/CAN goto L0E74
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,L0E74			; if A is not ZDLE/CAN goto L0E74
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
L0E74:
	ld hl,D0EA6			; point HL at D0EA6
	ld bc,000BH			; 11 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	ld l,a				; Save character in L
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr z,L0E8B			; if nonzero is zero/clear goto L0E8B
	ld a,l				; Check bits 5-6
	and 60H				; isolate bits 5-6: zero means a control character
	jr z,zdlread_escape		; if result is zero goto zdlread_escape
L0E8B:
	ld a,l				; Load character
	and 60H				; isolate bits 5-6: zero means a control character
	cp 40H				; compare A with 40H
	jr nz,L0E9C			; if A != 40H goto L0E9C
	ld a,l				; Unescape: invert bit 6 (XOR 40h) to restore control code
	xor 40H				; undo ZDLE escaping (flip bit 6)
	ret				; return
zdl_rub0:
	ld a,7FH			; Escaped rubout / DEL (7Fh)
	ret				; return
zdl_rub1:
	ld a,0FFH			; Escaped 0FFh byte
	ret				; return
L0E9C:
	ld a,0FFH			; Framing error code
zdl_crc_end:
	or 80H				; set bit 7 (marks a received subpacket terminator)
	scf				; flag failure to caller (carry set)
	ret				; return
D0EA2:
	.db 11H,91H,13H,93H		; keys: ....
D0EA6:
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
L0EDD:
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
	jr L0EDD			; loop back to L0EDD
D0F0E:
	.db GOTCRCE,GOTCRCG,GOTCRCQ,GOTCRCW,GOTCAN,0FFH,0FEH	; keys: .......
	.dw rx_timeout			; key 0FEH TIMEOUT
	.dw rx_err_return		; key 0FFH ERROR
	.dw rx_cancel			; key 98H GOTCAN
	.dw rx_end_crc16		; key 0EBH GOTCRCW
	.dw rx_end_crc16		; key 0EAH GOTCRCQ
	.dw rx_end_crc16		; key 0E9H GOTCRCG
	.dw rx_end_crc16		; key 0E8H GOTCRCE
D0F23:
	.db GOTCRCE,GOTCRCG,GOTCRCQ,GOTCRCW,GOTCAN,0FFH,0FEH	; keys: .......
	.dw rx_timeout			; key 0FEH TIMEOUT
	.dw rx_err_return		; key 0FFH ERROR
	.dw rx_cancel			; key 98H GOTCAN
	.dw rx_end_crc32		; key 0EBH GOTCRCW
	.dw rx_end_crc32		; key 0EAH GOTCRCQ
	.dw rx_end_crc32		; key 0E9H GOTCRCG
	.dw rx_end_crc32		; key 0E8H GOTCRCE
rx_data_term:
	ld hl,D0F23			; point HL at D0F23
	ld bc,0007H			; 7 keys in the table
	call is_crc32_mode		; Z if the link is using 32-bit CRC
	jr z,L0F49			; if link uses 32-bit CRC goto L0F49
	ld hl,D0F0E			; point HL at D0F0E
	ld bc,0007H			; 7 keys in the table
L0F49:
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
L0F62:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	jp c,rx_data_term		; if carry goto rx_data_term
	djnz L0F62			; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L0F77			; if the 16-bit count is zero goto L0F77
L0F73:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
L0F77:
	ld a,(subpkt_term)		; get terminator of the last data subpacket
	or a				; Clear carry (success)
	ret				; return
rx_end_crc32:
	ld (subpkt_term),a		; save as terminator of the last data subpacket
	and 7FH				; strip the parity bit (7-bit ASCII)
	call crc32_update		; update the running CRC-32 with byte A
	ld b,04H			; repeat count = 4
L0F86:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop bc				; restore BC
	jp c,rx_data_term		; if carry goto rx_data_term
	djnz L0F86			; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld de,crc32_residue		; point DE at CRC-32 residue 0DEBB20E3H expected after a good frame
	call eq32			; compare crc32_value with crc32_residue
	jp z,L0F77			; if values are equal goto L0F77
	jp L0F73			; loop back to L0F73

; ----------------------------------------------------------------------
; is_crc32_mode: Z if the link is using 32-bit CRC (flag 20H).
; ----------------------------------------------------------------------
is_crc32_mode:
	ld e,a				; Preserve A in E
	ld a,(crc_mode)			; get link CRC type
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
L0FC0:
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
	jr L0FC0			; loop back to L0FC0

; ----------------------------------------------------------------------
; get_header: Receive a ZMODEM header (hex, binary16 or binary32); returns
; frame type in A, carry on error. [zm.c zgethdr]
; ----------------------------------------------------------------------
get_header:
	xor a				; A = 0
	ld (rx_frame_type),a		; clear frame type of the last header received
	ld hl,0400H			; give up after 1024 junk characters without a header
	ld (hdr_junk_limit),hl		; save as remaining number of junk characters tolerated
L0FDB:
	ld a,05H			; five CANs in a row mean "session cancelled" [zgethdr: cancount = 5]
	ld (hdr_can_count),a		; remaining CAN characters before abort = 05H
L0FE0:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jp c,hdr_return			; if timed out waiting for the modem goto hdr_return
	ld hl,D109E			; point HL at D109E
	ld bc,0003H			; 3 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L1024			; continue at L1024
hdr_got_zdle:
	ld hl,hdr_can_count		; point HL at remaining CAN characters before abort
	dec (hl)			; count down remaining CAN characters before abort
	ld a,ZCAN			; CAN limit reached: report ZCAN
	jp z,hdr_return			; if remaining CAN characters before abort has run out goto hdr_return
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,L0FE0			; if timed out waiting for the modem goto L0FE0
	ld hl,D10A7			; point HL at D10A7
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L1024			; continue at L1024
; A second ZDLE: count a CAN; five in a row return ZCAN.
hdr_zdle_zdle:
	ld hl,hdr_can_count		; point HL at remaining CAN characters before abort
	dec (hl)			; count down remaining CAN characters before abort
	ld a,ZCAN			; CRC-16 header: remember the CRC type
	jp z,hdr_return			; if remaining CAN characters before abort has run out goto hdr_return
	jr L0FE0			; loop back to L0FE0
; ZDLE then ZCRCW: wait briefly for one more character, otherwise return an error.
hdr_zdle_zcrcw:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,L1035			; if timed out waiting for the modem goto L1035
L1024:
	ld hl,(hdr_junk_limit)		; get remaining number of junk characters tolerated
	dec hl				; HL--
	ld (hdr_junk_limit),hl		; save as remaining number of junk characters tolerated
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	ld a,0FCH			; junk limit reached: no header found
	jp z,hdr_return			; if the 16-bit count is zero goto hdr_return
	jp L0FDB			; loop back to L0FDB
L1035:
	ld a,0FFH			; A = 0FFH
	jp hdr_return			; continue at hdr_return
hdr_got_zpad:
	ld a,05H			; A = 05H
	ld (hdr_can_count),a		; remaining CAN characters before abort = 05H
; Another ZPAD: keep waiting for ZDLE.
hdr_pad_loop:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	jr c,hdr_return			; if timeout or error goto hdr_return
	ld hl,D10AD			; point HL at D10AD
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L1024			; loop back to L1024
hdr_zpad_zdle:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	jr c,hdr_return			; if timeout or error goto hdr_return
	ld hl,D10B3			; point HL at D10B3
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L1024			; loop back to L1024
hdr_hex:
	ld a,10H			; CRC-16 header: remember the CRC type
	ld (crc_mode),a			; link CRC type = 10H (CRC-16)
	call get_hex_header		; receive a hex-encoded header
	jr L107F			; continue at L107F
hdr_bin16:
	ld a,10H			; CRC format = 16-bit CRC (10h)
	ld (crc_mode),a			; link CRC type = 10H (CRC-16)
	call get_bin16_header		; receive a binary header with 16-bit CRC
	jr L107F			; continue at L107F
hdr_bin32:
	ld a,20H			; CRC-32 header (ZBIN32): remember the CRC type
	ld (crc_mode),a			; link CRC type = 20H (CRC-32)
	call get_bin32_header		; receive a binary header with 32-bit CRC
L107F:
	push af				; preserve AF
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld de,rx_header_copy		; point DE at copy of the received header arguments
	call copy32			; copy rx_header_data to rx_header_copy
	pop af				; restore AF
hdr_return:
	ld hl,D10BF			; point HL at D10BF
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jr nz,L109C			; if A is not in the key list goto L109C
	cp GOTCAN			; compare A with 98H
	jr nz,L109A			; if A != 98H goto L109A
	ld a,ZCAN			; return ZCAN
L109A:
	scf				; error/timeout/cancel: carry set
	ret				; return
L109C:
	or a				; Clear carry (success)
	ret				; return
D109E:
	.db ZDLE,ZPAD+80H,ZPAD		; keys: ..*
	.dw hdr_got_zpad		; key 2AH ZPAD
	.dw hdr_got_zpad		; key 0AAH ZPAD (bit 7 set)
	.dw hdr_got_zdle		; key 18H ZDLE
D10A7:
	.db ZCRCW,ZDLE			; keys: k.
	.dw hdr_zdle_zdle		; key 18H ZDLE
	.dw hdr_zdle_zcrcw		; key 6BH ZCRCW after CAN: no header follows
D10AD:
	.db ZPAD,ZDLE			; keys: *.
	.dw hdr_zpad_zdle		; key 18H ZDLE
	.dw hdr_pad_loop		; key 2AH ZPAD
D10B3:
	.db ZBIN32,ZBIN,ZHEX,ZDLE	; keys: CAB.
	.dw hdr_got_zdle		; key 18H ZDLE
	.dw hdr_hex			; key 42H ZHEX (hex header)
	.dw hdr_bin16			; key 41H ZBIN (binary header, CRC-16)
	.dw hdr_bin32			; key 43H ZBIN32 (binary header, CRC-32)
D10BF:
	.db GOTCAN,ZNAK,ZCAN,0FFH,0FEH,0FCH	; keys: ......

; ----------------------------------------------------------------------
; get_bin32_header: Receive a binary header with 32-bit CRC. [zm.c
; zrbhdr32]
; ----------------------------------------------------------------------
get_bin32_header:
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	ret c				; return: timeout, CAN or error
	ld (rx_frame_type),a		; save as frame type of the last header received
	call crc32_update		; update the running CRC-32 with byte A
	ld hl,rx_header_data		; point HL at four argument bytes of the most recently received header
	ld b,04H			; B = 04H
L10D7:
	push bc				; preserve BC
	push hl				; preserve HL
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	ret c				; Return on read error
	djnz L10D7			; repeat until all B items are done
	ld b,04H			; repeat count = 4
L10E8:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop bc				; restore BC
	ret c				; Return on read error
	djnz L10E8			; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld de,crc32_residue		; point DE at CRC-32 residue 0DEBB20E3H expected after a good frame
	call eq32			; compare crc32_value with crc32_residue
	jr z,L1132			; if values are equal goto L1132
	jr L113B			; continue at L113B

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
	ld b,04H			; B = 04H
L1112:
	push bc				; preserve BC
	push hl				; preserve HL
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	ret c				; Return on read error
	djnz L1112			; repeat until all B items are done
	ld b,02H			; repeat count = 2
L1123:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	ret c				; Return on read error
	djnz L1123			; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,L113B			; if the 16-bit count is not zero goto L113B
L1132:
	ld a,0FFH			; A = 0FFH
	ld (header_ok_flag),a		; FFH once a valid header has been received = FFH (set)
	ld a,(rx_frame_type)		; get frame type of the last header received
	ret				; return
L113B:
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
	ld b,04H			; B = 04H
L1151:
	push bc				; preserve BC
	push hl				; preserve HL
	call get_hex_byte		; receive two hex digits and combine them into a byte
	jr nc,L115B			; If byte received successfully, proceed
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return
L115B:
	call crc16_update		; update the running CRC-16
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	djnz L1151			; repeat until all B items are done
	ld b,02H			; Read 2 CRC-16 hex bytes
L1166:
	push bc				; preserve BC
	call get_hex_byte		; receive two hex digits and combine them into a byte
	jr nc,L116E			; if no carry goto L116E
	pop bc				; restore BC
	ret				; return
L116E:
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	djnz L1166			; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,L1190			; if the 16-bit count is not zero goto L1190
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	cp 0DH				; is it CR?
	jr nz,L1186			; if A is not CR goto L1186
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
L1186:
	or a				; Clear carry (success)
	ld a,0FFH			; A = 0FFH
	ld (header_ok_flag),a		; FFH once a valid header has been received = FFH (set)
	ld a,(rx_frame_type)		; get frame type of the last header received
	ret				; return
L1190:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; get_hex_byte: Receive two hex digits and combine them into a byte. [zm.c
; zgethex]
; ----------------------------------------------------------------------
get_hex_byte:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	ret c				; return: timeout or error
	call hex_digit_value		; convert an ASCII hex digit in A to 0-15
	jr nz,L11AF			; Error if invalid hex character
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
	jr nz,L11AF			; Error if invalid hex character
	or b				; Merge high nibble from B with low nibble in A
	ret				; return
L11AF:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; hex_digit_value: Convert an ASCII hex digit in A to 0-15.
; ----------------------------------------------------------------------
hex_digit_value:
	ld l,a				; Save original character in L
	sub 30H				; Subtract ASCII '0' offset
	cp 0AH				; In digit range '0'-'9'?
	jr c,L11BC			; if A < 0AH goto L11BC
	sub 27H				; Subtract offset for lowercase 'a'-'f'
L11BC:
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
	ld a,(crc_mode)			; get link CRC type
	cp 10H				; compare A with 10H
	ld a,43H			; A = 43H ('C')
	jr z,L11D4			; if A = 10H goto L11D4
	ld a,15H			; character to send: NAK
L11D4:
	call aux_putc_wait		; ask for CRC-16 with "C" (or checksum with NAK) [sendline(WANTCRC / NAK)]
	ld b,64H			; Timeout = 100 ticks
	call xmodem_get_block		; read block 0 (file name and size) [wcrxpn: wcgetsec]
	or a				; Test response status code
	jr z,L11F3			; if result is zero goto L11F3
	cp 0F6H				; WCEOT: EOT received (end of the previous file)?
	jr z,L11E7			; if A = F6H goto L11E7
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
L11E7:
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; acknowledge
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr xmodem_rx_start		; loop back to xmodem_rx_start
L11F3:
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
	ld (binary_mode_flag),a		; XMODEM data is stored unchanged
	xor a				; A = 0
	ld (xm_block_no),a		; clear expected XMODEM block number
	call rx_buffer_reset		; reset the receive buffer pointers to the start
	ld hl,file_position		; point HL at current file position, 32 bits
	call zero32			; clear file_position
	ld a,(crc_mode)			; get link CRC type
	cp 10H				; compare A with 10H
	ld a,43H			; A = 43H ('C')
	jr z,L121A			; if A = 10H goto L121A
	ld a,15H			; character to send: NAK
L121A:
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
L121D:
	ld a,(xm_block_no)		; get expected XMODEM block number
	or a				; test A (sets Z if A = 0)
	ld b,82H			; first block: wait up to 13 s [wcrx: (sectnum&0177)?50:130]
	jr z,L1227			; if expected XMODEM block number is zero/clear goto L1227
	ld b,32H			; later blocks: wait up to 5 s
L1227:
	call xmodem_get_block		; receive one block [wcgetsec]
	jr c,L125A			; if receive error goto L125A
	push af				; preserve AF
	call print_position		; print the current file position as a decimal number on
	pop af				; restore AF
	ld hl,xm_block_no		; point HL at expected XMODEM block number
	cp (hl)				; block number as expected? [sectcurr == sectnum+1]
	jr z,L1250			; if zero goto L1250
	dec a				; A--
	cp (hl)				; repeat of the previous block (our ACK was lost)? [Received dup Sector]
	jr nz,L126D			; if not zero goto L126D
	inc (hl)			; count up expected XMODEM block number
	ld de,rx_buffer_count		; point DE at number of bytes in the receive buffer
	ld hl,file_position		; point HL at current file position, 32 bits
	ld bc,file_position		; point BC at current file position, 32 bits
	call add32			; file_position = rx_buffer_count + file_position
	call rx_pos_save		; save buffer pointer/count
	call write_buf_file		; new block: append its data to the file [putsec]
	jr c,L1285			; if disk write error goto L1285
L1250:
	call rx_pos_restore		; restore buffer pointer/count
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	jr L121D			; loop back to L121D
L125A:
	cp 0F6H				; WCEOT: EOT received: end of file
	jr nz,L126D			; if A != F6H goto L126D
	call close_outfile		; close the file and acknowledge the EOT [closeit; sendline(ACK)]
	jr c,L1285			; if disk error closing file goto L1285
	call clear_fcb			; zero the 37-byte FCB at HL
	ld a,06H			; character to send: ACK
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	xor a				; return 0 (success)
	ret				; return
L126D:
	cp 0FFH				; compare A with 0FFH
	jr nz,L1285			; if A != FFH goto L1285
	ld a,(xm_first_flag)		; get FFH until the first valid XMODEM block has arrived
	cp 0FFH				; compare A with 0FFH
	jr nz,L1285			; if A != FFH goto L1285
	ld a,(crc_mode)			; get link CRC type
	or a				; test A (sets Z if A = 0)
	jr z,L1285			; if link CRC type is zero/clear goto L1285
	xor a				; A = 0
	ld (crc_mode),a			; clear link CRC type
	jp xmodem_rx_file		; no CRC block arrived: fall back to checksum mode and start over [wcgetsec: Crcflg]
L1285:
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
L1296:
	ld a,(xm_timeout)		; get XMODEM receive timeout in tenths of a second
	ld b,a				; B = A
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	ld hl,D12AE			; point HL at D12AE
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jp xm_bad_block			; continue at xm_bad_block
D12AE:
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
	jr L12C2			; continue at L12C2

; ----------------------------------------------------------------------
; xm_got_soh: XMODEM: 128-byte block start.
; ----------------------------------------------------------------------
xm_got_soh:
	ld hl,0080H			; 128-byte block
L12C2:
	ld (xm_block_len),hl		; bytes still to read
	ld b,0AH			; wait up to 1 s for each byte
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (xm_blk_no_rx),a		; block number
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; complement of the block number
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
L12D8:
	add a,00H			; block number + complement ...
xm_blk_no_rx		.equ L12D8+1	; received XMODEM block number (patched operand)
	cp 0FFH				; ... must be FFH
	jp nz,xm_bad_block		; if A != FFH goto xm_bad_block
	call crc_init			; start the CRC / checksum
	ld ix,(rx_buffer_ptr)		; IX = where the data goes
L12E6:
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
	jr nz,L12E6			; if not zero goto L12E6
	ld (rx_buffer_ptr),ix		; save the new buffer pointer
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; read the checksum or CRC high byte
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	ld a,(crc_mode)			; CRC mode?
	cp 10H				; compare A with 10H
	jr nz,L1352			; no: checksum
	ld a,(xm_rx_char)		; get last character received in XMODEM block handling
	call crc16_update		; update the running CRC-16
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; CRC low byte
	ld (xm_rx_char),a		; save as last character received in XMODEM block handling
	jp c,xm_bad_block		; if timed out waiting for the modem goto xm_bad_block
	call crc16_update		; update the running CRC-16
	ld a,h				; CRC over data + CRC must be zero
	or l				; A = H or L: zero only if HL = 0
	jp nz,xm_bad_block		; if the 16-bit count is not zero goto xm_bad_block
L1345:
	xor a				; good block: clear the error count
	ld (error_count),a		; clear consecutive error/retry counter
	ld a,00H			; no longer waiting for the first block
	ld (xm_first_flag),a		; FFH until the first valid XMODEM block has arrived = 00H (clear)
	ld a,(xm_blk_no_rx)		; return the block number
	ret				; return
L1352:
	ld a,(xm_rx_char)		; checksum mode: compare with our checksum
	ld l,a				; L = A
	ld a,(xm_checksum)		; get running 8-bit XMODEM checksum
	sub l				; A -= L
	jr z,L1345			; match: good block
	jp xm_bad_block			; continue at xm_bad_block

; ----------------------------------------------------------------------
; xm_got_eot: XMODEM: EOT received.
; ----------------------------------------------------------------------
xm_got_eot:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld a,0F6H			; A = 0F6H
	ret c				; return: timed out waiting for the modem
	jp xm_bad_block			; continue at xm_bad_block

; ----------------------------------------------------------------------
; xm_got_can: XMODEM: CAN received.
; ----------------------------------------------------------------------
xm_got_can:
	ld a,0FFH			; A = 0FFH
	ld hl,xm_can_flag		; point HL at set after one CAN, abort on the second
	cp (hl)				; is set after one CAN, abort on the second = FFH?
	jr nz,L1376			; if not zero goto L1376
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
L1376:
	ld (hl),a			; (HL) = A
	jp L13A4			; continue at L13A4

; ----------------------------------------------------------------------
; xm_bad_block: XMODEM: bad block, discard input and NAK.
; ----------------------------------------------------------------------
xm_bad_block:
	ld a,00H			; A = 00H
	ld (xm_can_flag),a		; set after one CAN, abort on the second = 00H (clear)
L137F:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr nc,L137F			; if a character arrived goto L137F
	ld a,(xm_first_flag)		; get FFH until the first valid XMODEM block has arrived
	cp 0FFH				; compare A with 0FFH
	jr nz,L139A			; if A != FFH goto L139A
	ld a,(crc_mode)			; get link CRC type
	cp 10H				; compare A with 10H
	ld a,43H			; A = 43H ('C')
	jr z,L13A1			; if A = 10H goto L13A1
	ld a,15H			; A = 15H
	jr L13A1			; continue at L13A1
L139A:
	ld a,28H			; Timeout = 40 ticks
	ld (xm_timeout),a		; XMODEM receive timeout in tenths of a second = 28H
	ld a,15H			; character to send: NAK
L13A1:
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
L13A4:
	call rx_pos_restore		; restore buffer pointer/count
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
	ld a,(error_count)		; get consecutive error/retry counter
	cp 05H				; compare A with 05H
	jp nz,L1296			; if A != 05H goto L1296
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; send_hex_header: Send a hex header: frame type in A, four argument bytes
; from the header buffer, CRC-16, CR LF. [zm.c zshhdr]
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
L13D4:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; HL++
	push hl				; preserve HL
	call crc16_update		; update the running CRC-16
	call put_hex_byte		; send A as two lowercase hex digits
	pop hl				; restore HL
	pop bc				; restore BC
	djnz L13D4			; repeat until all B items are done
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
	ret z				; return: A is ZFIN
	ld a,11H			; A = 11H (XON)
	jp aux_putc_wait		; continue at aux_putc_wait
; ZPAD ZPAD ZDLE ZHEX, introduces a hex header
hex_hdr_prefix:
	.db ZPAD,ZPAD,ZDLE,ZHEX,00H
; "0123456789abcdef"
hex_digits:
	.db "0123456789abcdef"

; ----------------------------------------------------------------------
; put_hex_byte: Send A as two lowercase hex digits. [zm.c zputhex]
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
	ld c,a				; C = A
	add hl,bc			; Index into hex digits string
	ld a,(hl)			; get a byte of "0123456789abcdef"
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	pop af				; restore AF
	ld hl,hex_digits		; point HL at "0123456789abcdef"
	ld b,00H			; BC = low nibble offset
	and 0FH				; keep the low nibble
	ld c,a				; C = A
	add hl,bc			; Index into hex digits string
	ld a,(hl)			; get a byte of "0123456789abcdef"
	jp aux_putc_wait		; continue at aux_putc_wait

; ----------------------------------------------------------------------
; put_zdle_char: Send A, escaping it with ZDLE if it is a control
; character. [zm.c zsendline]
; ----------------------------------------------------------------------
put_zdle_char:
	ld (zdl_char),a			; save as character to send after a ZDLE
	ld bc,0009H			; nine characters get special treatment: ZDLE, DLE, XON, XOFF and CR (each also with
					; bit 7 set)
	ld hl,D1477			; point HL at D1477
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	and 60H				; other bytes: only control characters (bits 5-6 clear) can need escaping
	jr nz,L145A			; if result is nonzero goto L145A
	ld a,(escape_ctl_flag)		; receiver/sender asked for ALL control characters to be escaped (ESCCTL)?
	or a				; test A (sets Z if A = 0)
	jr z,L145A			; if nonzero is zero/clear goto L145A
; Send ZDLE followed by the character XOR 40H, then fall through to send it.
zdl_escape:
	ld hl,zdl_char			; point HL at character to send after a ZDLE
	set 6,(hl)			; escape: send ZDLE followed by the byte with bit 6 flipped
	ld a,ZDLE			; character to send: ZDLE/CAN
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
L145A:
	ld a,00H			; Byte to transmit
zdl_char		.equ L145A+1	; character to send after a ZDLE (patched operand)

; ----------------------------------------------------------------------
; aux_putc_wait: Send A to the modem, waiting until the output is ready.
; ----------------------------------------------------------------------
aux_putc_wait:
	ld (aux_out_char),a		; save as character waiting to be sent to the modem
L145F:
	call aux_poll_input		; poll the AUX device
	call aux_out_ready		; test whether the AUX output is ready
	jr z,L145F			; if modem not ready for output goto L145F
L1467:
	ld a,00H			; Load character
aux_out_char		.equ L1467+1	; character waiting to be sent to the modem (patched operand)
	jp aux_putc			; loop back to aux_putc
; CR is escaped only if the previous character sent was "@".
zdl_cr_rule:
	ld a,(aux_out_char)		; CR rule: the previous character sent ...
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 40H				; ... was "@"? (a CR after "@" is escaped so Telenet is not triggered)
	jr nz,L145A			; if A != 40H goto L145A
	jr zdl_escape			; loop back to zdl_escape
D1477:
	.db ZDLE,0DH,8DH,10H,90H,11H,91H,13H,93H	; keys: .........
	.dw zdl_escape			; key 93H XOFF with bit 7
	.dw zdl_escape			; key 13H XOFF
	.dw zdl_escape			; key 91H XON with bit 7
	.dw zdl_escape			; key 11H XON
	.dw zdl_escape			; key 90H DLE with bit 7
	.dw zdl_escape			; key 10H DLE
	.dw zdl_cr_rule			; key 8DH CR with bit 7 (escaped only after "@")
	.dw zdl_cr_rule			; key 0DH CR (escaped only after "@")
	.dw zdl_escape			; key 18H ZDLE

; ----------------------------------------------------------------------
; parse_filespec: Parse a [DU:|DIR:]filename into an FCB (Z3PLUS named
; directories supported).
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
	jr L151D			; continue at L151D

; ----------------------------------------------------------------------
; parse_fcb: Core of the filespec parser.
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
	jr nz,L14BD			; if A != 3AH goto L14BD
	inc hl				; Skip leading colon
L14BD:
	ld b,08H			; Up to 8 characters for filename primary field
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
	ld a,(hl)			; Check trailing delimiter character
	ld (parse_next_char),a		; save as character following the parsed name
	cp 3AH				; Was character a colon ':' (drive/user prefix)?
	jr nz,L14FE			; if A != 3AH goto L14FE
	inc hl				; Advance past colon
	ld a,(parse_mode)		; get parse_filespec argument
	or a				; test A (sets Z if A = 0)
	jr z,L14D7			; if parse_filespec argument is zero/clear goto L14D7
	call parse_du			; try to interpret a prefix as drive/user
	jr z,L14E5			; if a valid DU: prefix was found goto L14E5
L14D7:
	call parse_named_dir		; try to interpret a prefix as a named directory
	jr z,L14E5			; if a valid DIR: prefix was found goto L14E5
	ld a,(parse_mode)		; get parse_filespec argument
	or a				; test A (sets Z if A = 0)
	jr nz,L14E5			; if parse_filespec argument is set/nonzero goto L14E5
	call parse_du			; try to interpret a prefix as drive/user
L14E5:
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
L14FE:
	ld a,(parse_next_char)		; get character following the parsed name
	ex de,hl			; swap pointers
	ld bc,0008H			; Advance HL past 8 filename bytes to extension
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld b,03H			; Extension length = 3 characters
	cp 2EH				; Is delimiter a dot '.'?
	jr nz,L1513			; if A != 2EH goto L1513
	inc hl				; Advance past dot
	push de				; preserve DE
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
L1513:
	ex de,hl			; swap pointers
	ld bc,0005H			; BC = 0005H
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld a,(parsed_user)		; get user number from the file spec
	ld (de),a			; Store user area into FCB extension
L151D:
	ld a,(wildcard_count)		; get number of wildcard characters in the file name
	or a				; test A (sets Z if A = 0)
	ret				; return

; ----------------------------------------------------------------------
; parse_fcb_field: Copy up to B name characters, expanding "*" to "?"s.
; ----------------------------------------------------------------------
parse_fcb_field:
	call is_delimiter		; end of the name?
	ret z				; yes: field is complete
	inc de				; step to the next FCB byte
	cp 2AH				; is it "*" ?
	jr nz,L1533			; no: ordinary character
	ld a,3FH			; "*" fills the rest of the field with "?"
	ld (de),a			; (DE) = A
	call inc_wild_count		; note one wildcard
	jr L153A			; go and fill the remaining positions
L1533:
	ld (de),a			; store the character in the FCB
	inc hl				; advance in the source text
	cp 3FH				; is it "?" ?
	call z,inc_wild_count		; count it as a wildcard
L153A:
	djnz parse_fcb_field		; next character of the field
L153C:
	call is_delimiter		; field full: skip any extra characters of the name
	ret z				; return: character ends the name
	inc hl				; HL++
	jr L153C			; loop back to L153C

; ----------------------------------------------------------------------
; inc_wild_count: Count one wildcard character.
; ----------------------------------------------------------------------
inc_wild_count:
	push hl				; preserve HL
	ld hl,wildcard_count		; point HL at number of wildcard characters in the file name
	inc (hl)			; count up number of wildcard characters in the file name
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; parse_du: Try to interpret a prefix as drive/user (DU:).
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
; ----------------------------------------------------------------------
parse_du_inner:
	call z3env_duok			; is a ZCPR3 environment present?
	jr z,L15CA			; no: not a DU specification
	ex de,hl			; swap pointers
	inc hl				; Advance to filename
	call z3env_max_drive		; highest valid drive
	ld b,a				; B = filename length
	inc b				; B = number of valid drives
	ld a,(hl)			; first character of the spec
	cp 41H				; a drive letter ("A"-"P")?
	jr c,L1574			; no: only a user number may follow
	sub 40H				; convert the letter to a drive number (A = 1)
	cp b				; is that drive valid?
	jr nc,L15CA			; no: not a DU specification
	ld (parsed_drive),a		; remember the drive
	inc hl				; HL++
	ld a,(hl)			; next character
	cp 20H				; blank: spec is just the drive
	ret z				; return: A = 20H
	call digit_value		; a digit starts the user number
	ret c				; neither: stop here
L1574:
	push hl				; try to read a user number (one or two digits)
	ld b,02H			; Check up to 2 user number digits
L1577:
	ld a,(hl)			; A = (HL)
	cp 20H				; compare A with 20H (' ')
	jr z,L1589			; if A = 20H goto L1589
	call digit_value		; A = A-'0'
	jr c,L159A			; not a number: give up
	inc hl				; HL++
	djnz L1577			; repeat until all B items are done
	ld a,(hl)			; the digits must be followed by a blank
	cp 20H				; compare A with 20H (' ')
	jr nz,L159A			; if A != 20H goto L159A
L1589:
	pop hl				; restore HL
	call z3env_max_user		; highest valid user number
	ld c,a				; C = A
	inc c				; C++
	call parse_decimal		; convert the digits
	cp c				; is the user number in range?
	jr nc,L15CA			; no: reject
	ld (parsed_user),a		; remember the user number
	xor a				; Z = valid DU specification
	ret				; return
L159A:
	pop hl				; restore HL
	jr L15CA			; reject

; ----------------------------------------------------------------------
; parse_named_dir: Try to interpret a prefix as a named directory (DIR:).
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
; ----------------------------------------------------------------------
named_dir_lookup:
	call z3env_ndr_ptr		; HL -> named directory register of the ZCPR3 environment
	jr z,L15CA			; none: not found
	ex de,hl			; swap pointers
	inc hl				; HL++
L15AC:
	ld a,(de)			; first byte of an entry: 0 ends the register
	or a				; test A (sets Z if A = 0)
	jr z,L15CA			; end of the register: not found
	inc de				; skip the drive/user bytes
	inc de				; DE++
	push hl				; preserve HL
	push de				; preserve DE
	ld b,08H			; compare the 8-character name
L15B6:
	ld a,(de)			; A = (DE)
	cp (hl)				; Character match?
	jr nz,L15BE			; if not zero goto L15BE
	inc hl				; HL++
	inc de				; DE++
	djnz L15B6			; repeat until all B items are done
L15BE:
	pop de				; restore DE
	pop hl				; restore HL
	jr z,L15CD			; all eight characters matched: found
	ex de,hl			; not this entry: step to the next one (16 bytes)
	ld bc,0010H			; Advance to next 16-byte template entry
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	jr L15AC			; loop back to L15AC
L15CA:
	or 0FFH				; NZ = name not found
	ret				; return
L15CD:
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
; ----------------------------------------------------------------------
is_delimiter:
	ld a,(hl)			; Load character
	cp 21H				; Below '!' is control char or space
	jr c,L15F8			; if A < 21H goto L15F8
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
L15F8:
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; parse_decimal: Parse a decimal user number.
; ----------------------------------------------------------------------
parse_decimal:
	push bc				; preserve BC
	ld bc,get_bin16_header		; point BC at get_bin16_header
L15FE:
	ld a,(hl)			; Load next character
	call is_delimiter		; Z if A ends a file name token
	jr z,L161E			; if character ends the name goto L161E
	inc hl				; Advance pointer
	call digit_value		; A = A-'0'
	jr c,L1622			; if not a decimal digit goto L1622
	ld d,a				; D = digit value
	ld a,c				; Multiply accumulator C by 10 (C * 8 + C * 2)
	rlca				; rotate A left
	jr c,L1622			; if not a decimal digit goto L1622
	rlca				; rotate A left
	jr c,L1622			; if not a decimal digit goto L1622
	add a,c				; A += C
	jr c,L1622			; if not a decimal digit goto L1622
	rlca				; rotate A left
	jr c,L1622			; if not a decimal digit goto L1622
	add a,d				; Add new digit value
	jr c,L1622			; if not a decimal digit goto L1622
	ld c,a				; Update accumulator
	djnz L15FE			; repeat until all B items are done
L161E:
	ld a,c				; A = parsed binary user number
	pop bc				; restore BC
	or a				; Clear carry (success)
	ret				; return
L1622:
	pop bc				; restore BC
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; digit_value: A = A-'0'; carry if not a digit.
; ----------------------------------------------------------------------
digit_value:
	sub 30H				; Subtract ASCII '0' (30h)
	ret c				; If < '0', Carry set (invalid)
	cp 0AH				; Compare against 10
	ccf				; Invert Carry: CY=0 if 0..9, CY=1 if > 9
	ret				; return

; ----------------------------------------------------------------------
; clear_dirspec: Clear the drive/user part of the FCB.
; ----------------------------------------------------------------------
clear_dirspec:
	xor a				; Clear A (default drive 0)
	ld (de),a			; Store into FCB drive byte
	inc de				; Advance to filename field
	call clear_fcb_tail		; clear the rest of the FCB

; ----------------------------------------------------------------------
; clear_fcb_tail: Clear the rest of the FCB.
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
; ----------------------------------------------------------------------
fill_clear:
	ld (de),a			; Store fill byte into memory
	inc de				; Advance buffer pointer
	djnz fill_clear			; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; z3env_duok: Read the DU:-form-allowed flag (DUOK, offset 2EH) of the
; ZCPR3 environment descriptor; Z if there is none or DU: is not allowed.
; ----------------------------------------------------------------------
z3env_duok:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_DUOK_OFF		; DE = 002EH
	jp L1669			; continue at L1669

; ----------------------------------------------------------------------
; z3env_max_drive: Read the highest valid drive (offset 2CH) from the
; ZCPR3 environment descriptor.
; ----------------------------------------------------------------------
z3env_max_drive:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_MDRV_OFF		; DE = 002CH
	jp L1669			; continue at L1669

; ----------------------------------------------------------------------
; z3env_max_user: Read the highest valid user number (offset 2DH) from the
; ZCPR3 environment descriptor.
; ----------------------------------------------------------------------
z3env_max_user:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_MUSR_OFF		; DE = 002DH
	jp L1669			; continue at L1669

; ----------------------------------------------------------------------
; z3env_ndr_ptr: Get the named directory register address (offset 15H)
; from the ZCPR3 environment descriptor; its entry count is at 17H.
; ----------------------------------------------------------------------
z3env_ndr_ptr:
	push de				; preserve DE
	ld de,Z3_NDR_OFF		; DE = 0015H
	jp L1676			; continue at L1676
L1669:
	ld hl,(z3env_ptr)		; get address of the ZCPR3 environment descriptor
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L1671			; if the 16-bit count is zero goto L1671
	add hl,de			; Add field offset to base
L1671:
	ld a,(hl)			; Fetch byte from descriptor
	pop de				; restore DE
	pop hl				; restore HL
	or a				; Set condition flags
	ret				; return
L1676:
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
	ld (z3env_ptr),hl		; save as address of the ZCPR3 environment descriptor
	ret				; return

; ----------------------------------------------------------------------
; get_drive_user: Return current drive in B and user in C.
; ----------------------------------------------------------------------
get_drive_user:
	push af				; preserve AF
	push de				; preserve DE
	push hl				; preserve HL
	ld c,DRV_GET			; C = 19H
	call bdos_save_regs		; BDOS call preserving BC and DE
	push af				; preserve AF
	ld e,0FFH			; E = 0FFH
	ld c,F_USERNUM			; C = 20H
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
; ----------------------------------------------------------------------
console_read:
	ld a,C_READ			; A = 01H
	jp bdos_call_a			; continue at bdos_call_a

; ----------------------------------------------------------------------
; console_status: Console input status (BDOS C_STAT).
; ----------------------------------------------------------------------
console_status:
	ld a,C_STAT			; A = 0BH
	jp bdos_call_a			; continue at bdos_call_a

; ----------------------------------------------------------------------
; bdos_save_regs: BDOS call preserving BC and DE.
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
; ----------------------------------------------------------------------
copy_name_part:
	ld a,(de)			; Fetch character from FCB
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 20H				; Is character a space?
	jr z,L16E3			; if A = 20H goto L16E3
	ld (hl),a			; Store printable character into output buffer
	inc hl				; Advance output pointer
L16E3:
	inc de				; Advance source pointer
	djnz copy_name_part		; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; a_to_decimal: Convert A to up to three decimal digits at DE.
; ----------------------------------------------------------------------
a_to_decimal:
	push bc				; preserve BC
	ld b,00H			; B = 00H
	jp L16F0			; continue at L16F0
	push bc				; preserve BC
	ld b,0FFH			; B = 0FFH
L16F0:
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
; ----------------------------------------------------------------------
decimal_digit:
	ld l,0FFH			; Initialize quotient = -1
L1705:
	sub h				; Subtract divisor
	inc l				; Increment quotient
	jr nc,L1705			; Continue until underflow
	add a,h				; Restore remainder
	ld h,a				; Save remainder in H
	ld a,l				; A = quotient
	or a				; Is quotient zero?
	jr nz,decimal_emit		; if result is nonzero goto decimal_emit
	or b				; A |= B
	ld a,h				; A = remainder
	ret m				; If B negative, return
	ld a,20H			; Output space for suppressed zero (' ')
	jr z,L171A			; if result is zero goto L171A
	xor a				; A = 0

; ----------------------------------------------------------------------
; decimal_emit: Store one decimal digit.
; ----------------------------------------------------------------------
decimal_emit:
	add a,30H			; Convert digit 0..9 to ASCII '0'..'9'
	ld b,a				; B non-zero (ends suppression)
L171A:
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
L1720:
	ld a,(hl)			; Fetch character
	or a				; Check for null terminator
	jr z,L172B			; if result is zero goto L172B
	call to_upper			; convert A to upper case
	ld (hl),a			; Store converted character back
	inc hl				; Advance string pointer
	jr L1720			; loop back to L1720
L172B:
	pop hl				; restore HL
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; tokenize_args: Split the command tail into blank-separated tokens,
; building a pointer table.
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
L1737:
	call skip_blanks		; find the start of the next token
	or a				; end of text?
	jr z,L1760			; yes: done
	ld (hl),e			; store the token address in the table
	inc hl				; HL++
	ld (hl),d			; Store token pointer high byte
	inc hl				; HL++
	dec b				; one more slot used
	jr z,L1755			; table full
	call skip_token			; skip over the token
	or a				; End of command line?
	jr z,L1760			; end of text
	ld a,c				; Delimiter replacement enabled?
	or a				; terminate the token?
	jr z,L1751			; if result is zero goto L1751
	xor a				; Replace whitespace with null terminator
	ld (de),a			; replace the delimiter by a zero
	inc de				; Advance past null
L1751:
	ld a,b				; more slots free?
	or a				; test A (sets Z if A = 0)
	jr nz,L1737			; yes: next token
L1755:
	call skip_token			; table full: see whether more text remains
	call skip_blanks		; skip spaces and tabs at DE
	or a				; End of line?
	jr z,L1760			; if result is zero goto L1760
	or 0FFH				; NZ = too many arguments
L1760:
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
; ----------------------------------------------------------------------
memset:
	push hl				; preserve HL
	call memset_inner		; fill B bytes at HL with A
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; memset_inner: Fill B bytes at HL with A.
; ----------------------------------------------------------------------
memset_inner:
	push bc				; preserve BC
L178D:
	ld (hl),a			; Store byte into buffer
	inc hl				; Advance pointer
	djnz L178D			; repeat until all B items are done
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; to_upper: Convert A to upper case.
; ----------------------------------------------------------------------
to_upper:
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 61H				; Less than 'a' (61h)?
	ret c				; return: A < 61H
	cp 7BH				; compare A with 7BH
	ret nc				; return: A >= 7BH
	and 5FH				; A &= 5FH
	ret				; return
; Pointer to the argument table built by tokenize_args
argv_ptr:
	.dw 2D11H
; User number at program start
default_user:
	.db 00H
; Drive (1 = A:) at program start
default_drive:
	.db 00H
; User number to select (pair with work_fcb drive byte)
saved_user:
	.db 00H
; FCB for the file being received (starts with the drive byte)
work_fcb:
	.fill 33,0
; Random record number r0-r2 of work_fcb
work_fcb_r0:
	.db 00H
	.db 00H
	.db 00H
; Random record overflow byte of work_fcb
work_fcb_r3:
	.db 00H
	.fill 56,0

; ---- Uninitialised RAM work area above the program image ----
; .ds only reserves space: nothing here is stored in the .COM file.
	.ds 8				; 1800H-1807H not referenced by the code
aux_ring		.ds 6		; 1808H AUX receive ring buffer control block: count, head, tail (6 bytes); 4096 data
					; bytes follow at 180EH-280DH
aux_ring_data		.ds 4096	; 180EH Data area of the AUX receive ring (4096 bytes)
file_buf_count		.ds 1		; 280EH Output sector buffer: number of bytes currently held (0-128)
file_buf_wr		.ds 1		; 280FH Output sector buffer: write index
file_buf_rd		.ds 1		; 2810H Output sector buffer: read index
file_sector_buf		.ds 128		; 2811H 128-byte file sector buffer (also the DMA address for file I/O)
ltoa_value		.ds 4		; 2891H ltoa32: working copy of the 32-bit value being converted
ltoa_temp		.ds 4		; 2895H ltoa32: temporary 32-bit subtraction result
crc32_value		.ds 4		; 2899H Running CRC-32 accumulator (4 bytes)
crc32_table		.ds 1024	; 289DH CRC-32 lookup table, 256 x 4 bytes (289DH-2C9CH)
escape_ctl_flag		.ds 1		; 2C9DH Nonzero (40H) if the sender requested escaping of all control characters
					; (TESCCTL)
crc_mode		.ds 1		; 2C9EH Link CRC type: 10H = CRC-16, 20H = CRC-32, 0 = XMODEM checksum
zfile_zf3		.ds 1		; 2C9FH ZFILE header bytes ZF3,ZF2,ZF1,ZF0 as received (2C9FH-2CA2H); ZF2 = transport
					; option, unused
zfile_zf2		.ds 1		; 2CA0H ZFILE header byte ZF2 (transport option), not used by the code
zfile_zf1		.ds 1		; 2CA1H ZFILE ZF1, management option: ZMAPND 3 = append to existing file, ZMPROT 7 =
					; protect existing file, ...
zfile_zf0		.ds 1		; 2CA2H ZFILE ZF0, conversion option: ZCBIN 1 = binary, ZCNL 2 = convert newlines to
					; the local convention
binary_mode_flag	.ds 1		; 2CA3H FFH = store data unmodified (binary); otherwise translate CR LF
protect_option		.ds 1		; 2CA4H 0, or 07H (ZMPROT) when the -p option forces protection
file_open_flag		.ds 1		; 2CA5H FFH while an output file is open
header_ok_flag		.ds 1		; 2CA6H FFH once a valid header has been received
rx_header_data		.ds 4		; 2CA7H Four argument bytes of the most recently received header
file_position		.ds 4		; 2CABH Current file position, 32 bits (next byte expected)
attn_string		.ds 32		; 2CAFH Attention string from ZSINIT (up to 32 bytes), sent to the sender on errors
	.ds 1				; 2CCFH not referenced by the code
info_argv		.ds 1		; 2CD0H Argument table built from the ZFILE data subpacket: max entries
info_argc		.ds 1		; 2CD1H ... number of entries found
info_name_ptr		.ds 2		; 2CD2H ... pointer to the file name string
info_size_ptr		.ds 2		; 2CD4H ... pointer to the file length/info string
	.ds 10				; 2CD6H-2CDFH not referenced by the code
tx_header_data		.ds 4		; 2CE0H Four argument bytes for the next header to send (position / flags)
rx_header_copy		.ds 4		; 2CE4H Copy of the received header arguments
tx_frame_type		.ds 1		; 2CE8H Frame type of the header being sent
rx_buffer_base		.ds 2		; 2CE9H Start address of the receive data buffer
rx_buffer_size		.ds 2		; 2CEBH Size of the receive data buffer
rx_buffer_ptr		.ds 2		; 2CEDH Next free byte in the receive buffer
rx_buffer_count		.ds 2		; 2CEFH Number of bytes in the receive buffer
	.ds 2				; 2CF1H-2CF2H not referenced by the code
rx_saved_ptr		.ds 2		; 2CF3H Saved receive buffer pointer (see rx_pos_save)
rx_saved_count		.ds 2		; 2CF5H Saved byte count; amount to write to the file
	.ds 2				; 2CF7H-2CF8H not referenced by the code
subpacket_len		.ds 4		; 2CF9H Length of the last data subpacket (32 bits, added to file_position)
subpkt_term		.ds 1		; 2CFDH Terminator of the last data subpacket (ZCRCE/G/Q/W | 80H)
hdr_junk_limit		.ds 2		; 2CFEH get_header: remaining number of junk characters tolerated
hdr_can_count		.ds 1		; 2D00H get_header: remaining CAN characters before abort
rx_frame_type		.ds 1		; 2D01H Frame type of the last header received
xm_first_flag		.ds 1		; 2D02H FFH until the first valid XMODEM block has arrived
xm_timeout		.ds 1		; 2D03H XMODEM receive timeout in tenths of a second
error_count		.ds 1		; 2D04H Consecutive error/retry counter
xm_block_len		.ds 2		; 2D05H XMODEM bytes still to read in the current block
xm_block_no		.ds 1		; 2D07H Expected XMODEM block number
xm_rx_char		.ds 1		; 2D08H Last character received in XMODEM block handling
xm_can_flag		.ds 1		; 2D09H Set after one CAN, abort on the second
parse_mode		.ds 1		; 2D0AH parse_filespec argument (nonzero: try DU form / named directory)
parse_next_char		.ds 1		; 2D0BH Character following the parsed name
wildcard_count		.ds 1		; 2D0CH Number of wildcard characters in the file name
parsed_drive		.ds 1		; 2D0DH Drive from the file spec (0 = default)
parsed_user		.ds 1		; 2D0EH User number from the file spec
z3env_ptr		.ds 2		; 2D0FH Address of the ZCPR3 environment descriptor (0 if none)
	.end
