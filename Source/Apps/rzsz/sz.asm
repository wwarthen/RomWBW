; SZ.COM  --  X/Y/ZMODEM send program for CP/M 3 (sz v1.11, W. Schmitten 1992)
; SZ.COM v1.11
; Derived from a byte-identical disassembly of the CP/M 3 ZMODEM/YMODEM/XMODEM program (Z80).
; Source is in TASM syntax (dotted directives); assembled and verified with uz80as.
; Modem is on the CP/M AUX device (BDOS 3/4/7/8). Option letters: ? P A B C X Y Z (A = append).
; Tables: key bytes searched with CPIR, then N vectors in REVERSE key order, jumped to via the dispatch routine.
; Labels are descriptive; patched operand bytes are named with .equ <label>+n.
; Comments were cross-checked against an independent disassembly of the same binaries,
; the ZMODEM specification and the rz.c / sz.c sources.

; ----------------------------------------------------------------------
; CP/M 3 page zero locations
; ----------------------------------------------------------------------
CPM			.equ 0000H	; Warm Boot Jump Vector (0000h: JP BIOS+3)
IOBYTE			.equ 0004H	; Intel I/O Byte (CP/M 2.2) / Current Drive & User (CP/M 3)
BDOS			.equ 0005H	; BDOS Function Call Entry Point (0005h: JP BDOS)
BDOSVEC			.equ 0006H	; BDOS address = top of the TPA
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
SCB_CIVEC		.equ 22H	; SCB offset 22H: console input redirection vector
SCB_COVEC		.equ 24H	; SCB offset 24H: console output redirection vector
SCB_AOVEC		.equ 28H	; SCB offset 28H: auxiliary (modem) output redirection vector

; ----------------------------------------------------------------------
; ZCPR3 environment descriptor offsets
; ----------------------------------------------------------------------
Z3_NDR_OFF		.equ 15H	; Named Directory table pointer offset (16-bit word)
Z3_MDRV_OFF		.equ 2CH	; Maximum drive number offset (1 byte)
Z3_MUSR_OFF		.equ 2DH	; Maximum user number offset (1 byte)
Z3_DUOK_OFF		.equ 2EH	; ZCPR3 environment: "DU: form allowed" flag

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
; start: Program entry: check for CP/M 3, show banner, parse command line,
; run the transfer, restore the default drive/user and exit.
; ----------------------------------------------------------------------
start:
	jp main				; continue at main
	.db "Z3ENV",01H
; ZCPR3 environment address, patched in by Z3INS
z3env_addr:
	.db 00H
	.db 00H

; ----------------------------------------------------------------------
; main: Program entry (after the ZCPR3 header): check for CP/M 3, show
; banner, parse command line and file list, run the transfer, restore
; drive/user and exit.
; ----------------------------------------------------------------------
main:
	ld sp,stack_top			; the stack grows down from stack_top
	ld hl,(z3env_addr)		; pick up the ZCPR3 environment address patched in by Z3INS
	call set_z3env			; store HL as the ZCPR3 environment pointer
	ld c,S_BDOSVER			; this program needs CP/M 3 (BDOS 3.0)
	call BDOS			; S_BDOSVER: get the BDOS version
	cp 30H				; Verify running on CP/M 3.0 or higher
	jp c,err_need_cpm3		; older CP/M: refuse to run
	ld de,msg_banner		; point DE at banner text
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; show the banner
	call get_default_du		; remember the current drive/user
	ld a,(DEFAULT_DMA)		; is there a command tail?
	or a				; Are there any command-line arguments?
	jp z,usage_exit			; no: show the usage text
	ld hl,(arg_table_ptr)		; argument table in free memory
	ld (hl),02H			; at most two arguments
	ld de,0082H			; DE -> command tail text
	ex de,hl			; swap pointers
	ld a,0FFH			; terminate each argument with a zero
	call tokenize_args		; split the command tail
	ld hl,(arg_table_ptr)		; get address of arg_table, the start of the free memory
	inc hl				; HL -> argument count
	ld a,(hl)			; A = number of parsed tokens
	or a				; no arguments?
	jp z,usage_exit			; if result is zero goto usage_exit
	inc hl				; Point to first argument string pointer
	ld e,(hl)			; DE -> first argument
	inc hl				; HL++
	ld d,(hl)			; DE = pointer to first argument string
	inc hl				; HL++
	ld a,(de)			; does it start with "-" ?
	cp 2DH				; Does first argument begin with dash '-'?
	jr nz,main_1			; no: it is the file specification
	call parse_options		; yes: process the option letters
	ld e,(hl)			; DE -> second argument (the file specification)
	inc hl				; HL++
	ld d,(hl)			; DE = pointer to filename argument string
main_1:
	ld a,d				; no file specification?
	or e				; Was a target filespec supplied?
	jr z,main_3			; none
	ld hl,work_fcb			; point HL at work FCB / DU pair for the command line file spec
	ex de,hl			; swap pointers
	call parse_filespec		; parse [du:]filename (wildcards allowed)
	ld hl,work_fcb			; point HL at work FCB / DU pair for the command line file spec
	xor a				; no drive given?
	or (hl)				; Did filespec specify an explicit drive?
	jr nz,main_2			; if result is nonzero goto main_2
	ld a,(default_drive)		; use the current drive
	ld (hl),a			; store into work FCB / DU pair for the command line file spec
main_2:
	ld (entry_drive),a		; drive for the file list entries
	ld bc,FCB_S1			; Offset 13: point to user number field in FCB
	add hl,bc			; HL += BC
	dec de				; DE--
	ldi				; copy the user number
	ld de,work_fcb			; point DE at work FCB / DU pair for the command line file spec
	call set_du			; select that drive and user
	or a				; Check if drive and user selection succeeded
	jp nz,main_4			; cannot select it
	ld hl,(arg_table_ptr)		; list of files goes after the argument table
	ld a,(saved_user)		; get user number to select
	or 0C0H				; selection mask: user | C0H = DIR and SYS files, this user only
	ld de,work_fcb			; point DE at work FCB / DU pair for the command line file spec
	call build_file_list		; search the directory and build the (sorted) file list
	ld (file_list_ptr),hl		; HL = end of the list
	ld a,c				; C = number of matching files
	ld (file_count),a		; save as number of files in the list to send
main_3:
	push af				; tell the user how many files were found
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ld de,msg_files_req		; point DE at "File
	call a_to_decimal		; put the count in front of "File(s) requested"
	ld de,msg_files_req		; point DE at "File
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	pop af				; restore AF
	or a				; no files?
	jp z,main_4			; nothing to send: exit
	ex de,hl			; swap pointers
	ld h,b				; BC = number of files
	ld l,c				; L = C
	add hl,hl			; x16: each list entry is 16 bytes
	add hl,hl			; HL += HL
	add hl,hl			; HL += HL
	add hl,hl			; HL += HL
	ex de,hl			; swap pointers
	add hl,de			; HL = first free byte after the list
	ld (file_buffer_base),hl	; the data buffer starts there ...
	ld de,(BDOSVEC)			; ... and extends to the top of the TPA
	ex de,hl			; swap pointers
	or a				; test A (sets Z if A = 0)
	sbc hl,de			; Calculate total free bytes available in TPA
	ld (file_buffer_size),hl	; save as size of the file data ring buffer
	ld hl,0000H			; HL = 0000H
	ld (file_buffer_base_hi),hl	; clear the high word of file_buffer_base
	ld (file_buffer_size_hi),hl	; clear the high word of file_buffer_size
	ld de,msg_start_rx		; ask the user to start the receiving program
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	call scb_setup			; change console settings for the transfer
	call send_main			; send the files
	call scb_restore		; restore the console settings
main_4:
	ld bc,0000H			; BC = original user/drive (patched at start)
restore_du		.equ main_4+1	; default user/drive restored at exit (patched operand)
	ld (saved_user),bc		; save as user number to select
	ld de,work_fcb			; point DE at work FCB / DU pair for the command line file spec
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
; err_need_cpm3: Print "sorry, CP/M 3 Tool" and exit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
err_need_cpm3:
	ld de,msg_need_cpm3		; point DE at "sorry, CP/M 3 Tool"
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message

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
	.db "SZ for CP/M 3   V 1.11",0DH,0AH
	.db "(C) 92 wshbg",0DH,0AH
	.db 0AH
	.db 24H
; "sorry, CP/M 3 Tool"
; Common data: identical in RZ and SZ.
msg_need_cpm3:
	.db "sorry, CP/M 3 Tool",0DH,0AH
	.db 24H
; Usage / help text
msg_usage:
	.db "usage: sz [-?pabcxyz] [du:]fn",0DH,0AH
	.db 0AH
	.db " options:",0DH,0AH
	.db "            ?     this help",0DH,0AH
	.db "            p     protect File at destination",0DH,0AH
	.db "            a     append",0DH,0AH
	.db "            b     receive binary",0DH,0AH
	.db "            c     convert to local linefeed",0DH,0AH
	.db "            x,y,z Protokoll",0DH,0AH
	.db 24H
; "File(s) requested"
msg_files_req:
	.db "    File(s) requested",0DH,0AH
	.db 0AH
	.db 24H
; "start your local ... receive program"
msg_start_rx:
	.db "start your local X/Y/ZModem receive program",0DH,0AH
	.db 24H

; ----------------------------------------------------------------------
; parse_options: Scan a "-xyz" option string; each letter is looked up in
; the option key table and its handler is run.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
parse_options:
	push hl				; preserve HL
	push de				; preserve DE
parse_options_1:
	inc de				; Advance to next character in argument string
	ld a,(de)			; A = (DE)
	or a				; Test for null terminator (end of string)
	jr z,parse_options_2		; if result is zero goto parse_options_2
	ld hl,opt_tab			; point HL at option letters and their handlers
	ld bc,0008H			; 8 keys in the table
	cpir				; look A up in the key table
	call z,dispatch			; if A is in the key list goto dispatch
	jr parse_options_1		; loop back to parse_options_1
parse_options_2:
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
; Option letters and their handlers (vectors are stored in reverse key order)
opt_tab:
	.db 3FH,50H,41H,42H,43H,58H,59H,5AH	; keys: ?PABCXYZ
	.dw opt_zmodem			; key 5AH 'Z'
	.dw opt_ymodem			; key 59H 'Y'
	.dw opt_xmodem			; key 58H 'X'
	.dw opt_convert			; key 43H 'C'
	.dw opt_binary			; key 42H 'B'
	.dw opt_append			; key 41H 'A'
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
; Option A: ask the receiver to append (ZF1 = ZMAPND).
opt_append:
	ld a,0FFH			; A = 0FFH
	ld (opt_append_flag),a		; FFH if -a = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; opt_binary: Option B: binary transfer.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
opt_binary:
	ld a,0FFH			; set the -b flag (binary transfer)
	ld (opt_binary_flag),a		; FFH if -b = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; opt_convert: Option C: convert to local linefeed convention.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
opt_convert:
	ld a,0FFH			; set the -c flag (convert line ends)
	ld (opt_convert_flag),a		; FFH if -c = FFH (set)
	ret				; return

; ----------------------------------------------------------------------
; scb_setup: Detach the modem port from the console: read AOVEC (SCB 28H)
; via BDOS 49 and clear its devices from COVEC (24H) and CIVEC (22H),
; keeping the originals.
; Common routine: identical in RZ and SZ.
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
scb_setup_1:
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
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
scb_restore:
	ld hl,(scb_sv_covec)		; put the original COVEC and CIVEC back into the parameter blocks ...
	ld (scb_covec_val),hl		; save as COVEC value word of its parameter block
	ld hl,(scb_sv_civec)		; get original CIVEC value, restored at exit
	ld (scb_civec_val),hl		; save as CIVEC value word of its parameter block
	jr scb_setup_1			; ... and write them to the System Control Block
; S_SCB parameter block: SCB offset 28H = AOVEC, the auxiliary (modem) output redirection vector
; Common data: identical in RZ and SZ.
scb_pb_aovec:
	.db SCB_AOVEC
; S_SCB set code for the AOVEC block (0 = get)
; Common data: identical in RZ and SZ.
scb_aovec_code:
	.db 00H
	.db 00H
	.db 00H
; S_SCB parameter block: SCB offset 24H = COVEC, the console output redirection vector
; Common data: identical in RZ and SZ.
scb_pb_covec:
	.db SCB_COVEC
; S_SCB set code for the COVEC block (0 = get, FEH = set word)
; Common data: identical in RZ and SZ.
scb_covec_code:
	.db 00H
; COVEC value word of its parameter block
; Common data: identical in RZ and SZ.
scb_covec_val:
	.db 00H
	.db 00H
; S_SCB parameter block: SCB offset 22H = CIVEC, the console input redirection vector
; Common data: identical in RZ and SZ.
scb_pb_civec:
	.db SCB_CIVEC
; S_SCB set code for the CIVEC block (0 = get, FEH = set word)
; Common data: identical in RZ and SZ.
scb_civec_code:
	.db 00H
; CIVEC value word of its parameter block
; Common data: identical in RZ and SZ.
scb_civec_val:
	.db 00H
	.db 00H
; Original COVEC value, restored at exit
; Common data: identical in RZ and SZ.
scb_sv_covec:
	.db 00H
	.db 00H
; Original CIVEC value, restored at exit
; Common data: identical in RZ and SZ.
scb_sv_civec:
	.db 00H
	.db 00H
; Complement of AOVEC: keeps the devices that are not used for AUX output
; Common data: identical in RZ and SZ.
scb_aovec_mask:
	.db 00H
	.db 00H

; ----------------------------------------------------------------------
; print_err_count: Print the current error count / retry message on the
; console.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
print_err_count:
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
	ld de,send_fcb			; point DE at FCB of the file being sent
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
	ld hl,file_size			; point HL at size of the current file in bytes
	ld de,print_filenam_d4		; point DE at print_filenam_d4
	call ltoa32			; convert file_size to decimal text at print_filenam_d4
	ld (hl),0DH			; Append CR
	inc hl				; HL++
	ld (hl),0AH			; Append LF
	inc hl				; HL++
	ld (hl),24H			; Replace null with '$' terminator for BDOS output
	ld de,name_line_buf		; point DE at console line buffer
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
	.fill 12,0

; ----------------------------------------------------------------------
; print_position: Print the current file position as a decimal number on
; the console.
; ----------------------------------------------------------------------
print_position:
	ld hl,pos_display		; point HL at copy of the file position shown on the console
	ld de,print_positio_d1		; point DE at print_positio_d1
	call ltoa32			; convert pos_display to decimal text at print_positio_d1
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

; ----------------------------------------------------------------------
; print_cant_open: Print "can't open any file".
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
print_cant_open:
	ld de,msg_cant_open		; point DE at "can't open any file"
	jr print_skipped_1		; continue at print_skipped_1

; ----------------------------------------------------------------------
; print_skipped: Print "File skipped".
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
print_skipped:
	ld de,msg_file_skipped		; point DE at "File skipped"
print_skipped_1:
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display the $-terminated message
; "File skipped"
; Common data: identical in RZ and SZ.
msg_file_skipped:
	.db "File skipped",0DH,0AH
	.db 24H
; "can't open any file"
; Common data: identical in RZ and SZ.
msg_cant_open:
	.db "can",27H,"t open any file",0DH,0AH
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
; aux_poll_input: Poll the AUX device (BDOS A_STATIN/A_READ) and move any
; waiting characters into the receive ring buffer.
; ----------------------------------------------------------------------
aux_poll_input:
	or a				; test A (sets Z if A = 0)
	ld hl,(aux_ring)		; get AUX receive ring buffer control block
	ld de,0200H			; DE = maximum receive ring buffer capacity
	sbc hl,de			; Test if buffer is full
	jr z,aux_poll_input_1		; If buffer is full, do not read; check available count
	ld c,A_STATIN			; BDOS function: A_STATIN
	call BDOS			; A_STATIN: is a character waiting at the AUX port?
	or a				; test A (sets Z if A = 0)
	jr z,aux_poll_input_1		; if result is zero goto aux_poll_input_1
	ld c,A_READ			; BDOS function: A_READ
	call BDOS			; A_READ: read a character from the AUX (modem) port
	ld c,a				; C = received character byte
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_put			; insert byte C into the receive ring buffer
	jr aux_poll_input		; loop back to aux_poll_input
aux_poll_input_1:
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
; aux_putc: Write the character in A to the AUX (modem) device.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
aux_putc:
	ld c,A_WRITE			; BDOS function: A_WRITE
	ld e,a				; E = A
	jp BDOS				; A_WRITE: send the character in E to the AUX (modem) port

; ----------------------------------------------------------------------
; aux_out_ready: Test whether the AUX output is ready (BDOS A_STATOUT).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
aux_out_ready:
	ld c,A_STATOUT			; BDOS function: A_STATOUT
	call BDOS			; A_STATOUT: is the AUX port ready for output?
	or a				; Test status in A (0 = busy, FFh = ready)
	ret				; return

; ----------------------------------------------------------------------
; aux_wait_input: Wait roughly 100 ms-steps for an input character;
; returns it in A with NZ, Z on timeout.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
aux_wait_input:
	push bc				; preserve BC
	ld b,5FH			; repeat count = 95
aux_wait_input_1:
	push bc				; preserve BC
	call aux_poll_input		; poll the AUX device
	pop bc				; restore BC
	jr nz,aux_wait_input_2		; if input was waiting goto aux_wait_input_2
	call delay_short		; short software delay loop
	djnz aux_wait_input_1		; repeat until all B items are done
	call aux_poll_input		; poll the AUX device
aux_wait_input_2:
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
	and 01H				; Mask to ring buffer size (512 bytes / 1FFh)
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
	ld hl,0200H			; HL = ring capacity
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
	and 01H				; Mask to ring buffer size (512 bytes)
	ld (hl),a			; store the new write index (high)
	pop hl				; HL -> slot for the new byte
	ld (hl),c			; store the byte (passed in C)
	ret				; NZ: byte stored

; ----------------------------------------------------------------------
; clear_fcb: Zero the 37-byte FCB at HL.
; ----------------------------------------------------------------------
clear_fcb:
	ld hl,entry_user		; point HL at user number of the current file list entry
	ld b,25H			; Count = 37 (25h) bytes to clear
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
; cmp32_signed: Signed compare of 32-bit values (HL) and (DE); sets
; carry/zero.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
cmp32_signed:
	push hl				; preserve HL
	pop ix				; restore IX
	push de				; preserve DE
	pop iy				; restore IY
	ld a,(ix+3)			; Compare most significant bytes (signs)
	xor (iy+3)			; A ^= (iy+3)
	jp p,cmp32_signed_2		; If signs are identical, do unsigned compare
	xor (ix+3)			; Restore sign byte
cmp32_signed_1:
	ret m				; return if negative
	ccf				; complement carry
	ret				; return
cmp32_signed_2:
	xor (ix+3)			; Restore sign byte
	jp p,cmp32_unsigned		; If positive, perform standard 32-bit subtract compare
	call cmp32_unsigned		; unsigned compare of 32-bit values
	scf				; flag failure to caller (carry set)
	jr cmp32_signed_1		; loop back to cmp32_signed_1

; ----------------------------------------------------------------------
; cmp32_unsigned: Unsigned compare of 32-bit values (HL) and (DE).
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
cmp32_unsigned:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	or a				; test A (sets Z if A = 0)
	ld b,04H			; repeat count = 4
cmp32_unsigned_1:
	ld a,(de)			; Load subtrahend byte
	sbc a,(hl)			; Subtract with borrow minuend byte
	inc de				; Advance subtrahend pointer
	inc hl				; Advance minuend pointer
	djnz cmp32_unsigned_1		; repeat until all B items are done
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

; ----------------------------------------------------------------------
; and32: (BC) = (DE) AND (HL), 32-bit.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
and32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	ld a,04H			; Process 4 bytes (32 bits)
and32_1:
	push af				; preserve AF
	ld a,(de)			; Load byte from source 1
	and (hl)			; Bitwise AND with byte from source 2
	ld (bc),a			; Store result byte into destination
	inc bc				; Advance destination pointer
	inc de				; Advance source 1 pointer
	inc hl				; Advance source 2 pointer
	pop af				; restore AF
	dec a				; Decrement byte counter
	jr nz,and32_1			; Repeat for all 4 bytes
	pop hl				; restore HL
	pop de				; restore DE
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
; crc32_update: Update the running CRC-32 with byte A.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
crc32_update:
	push af				; preserve AF
crc32_update_1:
	ld iy,crc32_table		; point IY at CRC-32 lookup table, 256 x 4 bytes
crc32_tab_ptr		.equ crc32_update_1+2	; address of the CRC-32 table (patched operand, 16 bits)
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
; Common routine: identical in RZ and SZ.
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
crc32_table_1:
	push af				; keep the index
	ld hl,0FFFFH			; CRC register = FFFFFFFFH (HL:DE)
	ld de,0FFFFH			; DE = 0FFFFH
	xor e				; mix the index into the low byte
	ld e,a				; E = A
	ld b,08H			; eight bit steps
crc32_table_2:
	scf				; shift in a 1 ...
	rr h				; ... shifting the 32-bit register right
	rr l				; rotate right through carry L
	rr d				; rotate right through carry D
	rr e				; rotate right through carry E
	jr nc,crc32_table_3		; bit shifted out was 0: no polynomial
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
crc32_table_3:
	djnz crc32_table_2		; next bit
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
; 32-bit constant 1024
const_1024:
	.db 00H
	.db 04H,00H
	.db 00H
; 32-bit constant -1024
const_minus_1024:
	.db 00H
	.db 0FCH,0FFH,0FFH
; Selected protocol: 1 = XMODEM, 3 = YMODEM, 4 = ZMODEM (default)
; Common data: identical in RZ and SZ.
protocol:
	.db 04H
; Default receiver window: value x 4 x 256 bytes
window_default:
	.db 20H

; ----------------------------------------------------------------------
; send_main: Top-level send: set up buffers and CRC table, then send all
; files. [sz.c wcsend]
; ----------------------------------------------------------------------
send_main:
	ld a,(protocol)			; get selected protocol
	cp 04H				; is it ZMODEM?
	jr nz,send_main_1		; if A is not ZMODEM goto send_main_1
	ld a,03H			; A = 03H
	ld (protocol),a			; selected protocol = 03H (YMODEM)
send_main_1:
	xor a				; A = 0
	ld hl,error_count		; point HL at consecutive error/retry counter
	ld b,50H			; fill 80 bytes
	call memset			; fill B bytes at HL with A
	call clear_fcb			; zero the 37-byte FCB at HL
	call crc32_table_init		; build the 256-entry CRC-32 lookup table
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_reset			; clear the 6-byte ring buffer control block at HL
	ld hl,(file_buffer_size)	; get size of the file data ring buffer
	call calc_buffer_mask		; round the available buffer size down to a power of two
	ld hl,0400H			; HL = 0400H
	ld (subpacket_size),hl		; save as current data subpacket size
	call send_files			; loop over all files in the list and send them
	jr c,send_main_2		; if transfer failed / aborted goto send_main_2
	or a				; test A (sets Z if A = 0)
	ret				; return
send_main_2:
	scf				; flag failure to caller (carry set)
	ret				; return

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
	ld (file_buffer_size),hl	; save as size of the file data ring buffer
	dec hl				; Compute wrapping bitmask (size - 1)
	ld (buffer_mask),hl		; save as receive buffer size mask
	ret				; return

; ----------------------------------------------------------------------
; fetch_file_entry: Fetch the next file name from the list into the
; working FCB.
; ----------------------------------------------------------------------
fetch_file_entry:
	ld hl,0000H			; Dynamically patched with matching files list
file_list_ptr		.equ fetch_file_entry+1	; pointer to the next entry of the file list (patched operand, 16 bits)
	ld de,entry_user		; point DE at user number of the current file list entry
	ldi				; Copy status/user byte
fetch_file_1:
	ld a,00H			; Dynamically patched default drive number
entry_drive		.equ fetch_file_1+1	; drive for list entries (patched operand)
	ld (de),a			; Store drive into FCB
	inc de				; Advance FCB pointer
	ld bc,000BH			; 11 bytes: 8 filename + 3 extension
	ldir				; copy the block
	ld hl,(file_list_ptr)		; get pointer to the next entry of the file list
	ld bc,0010H			; Directory entries are 16 bytes each
	add hl,bc			; Advance to next directory record
	ld (file_list_ptr),hl		; save as pointer to the next entry of the file list
	ret				; return

; ----------------------------------------------------------------------
; send_files: Loop over all files in the list and send them, then finish
; the session. [sz.c wcsend]
; ----------------------------------------------------------------------
send_files:
	xor a				; start with CRC-16 / no CRC-32
	ld (tx_crc_mode),a		; clear CRC type used for sending
	ld a,0FFH			; no block acknowledged yet
	ld (xm_first_flag),a		; FFH until the first block has been acknowledged = FFH (set)
	ld a,(file_count)		; get number of files in the list to send
	or a				; Were any matching files found?
	jr z,send_files_2		; no files in the list
	ld b,a				; B counts the files left (also the list index)
send_files_1:
	push bc				; preserve BC
	ld a,b				; A = current file index
	call fetch_file_entry		; get the next name into the FCB
	ld hl,buffer_start_pos		; the buffer starts empty at file position 0
	call zero32			; clear buffer_start_pos
	call send_one_file		; send this file
	push af				; preserve AF
	cp ZSKIP			; receiver answered ZSKIP?
	call z,print_skipped		; if A is ZSKIP: call print_skipped
	call file_close_input		; close the file
	pop af				; restore AF
	pop bc				; restore BC
	jr c,send_files_3		; failed or aborted
	djnz send_files_1		; next file
	ld a,(files_sent_count)		; were any files sent?
	or a				; Were any files transferred?
	jr nz,send_files_4		; yes: finish the session
send_files_2:
	call print_cant_open		; no file could be opened
send_files_3:
	call send_can_string		; abort the receiver
	ld a,0FFH			; return with error
	scf				; flag failure to caller (carry set)
	ret				; return
send_files_4:
	ld a,(protocol)			; all files sent: end the session
	cp 03H				; is it YMODEM?
	jr c,send_files_6		; XMODEM: nothing more to send
	jr nz,send_files_5		; ZMODEM: send ZFIN
	xor a				; YMODEM: send an empty block 0 to end the batch
	ld (xmodem_block_no),a		; clear current XMODEM block number
	ld hl,(file_buffer_base)	; get start of the file data ring buffer
	ld b,80H			; fill 128 bytes
	call memset			; block of 128 zero bytes
	ld hl,0080H			; HL = 0080H
	ld (block_len),hl		; save as length of the current block / subpacket
	call xmodem_snd_block		; send one block
	xor a				; Clear A
send_files_5:
	call nz,send_zfin_oo		; ZMODEM: finish with ZFIN and "OO"
send_files_6:
	xor a				; success
	ret				; return

; ----------------------------------------------------------------------
; send_one_file: Open one file, print its name and send it with the
; selected protocol. [sz.c wcs]
; ----------------------------------------------------------------------
send_one_file:
	ld de,send_fcb			; find out how big the file is
	call get_file_size		; get the file size
	ld de,0000H			; convert the record count to a byte count (x128)
	srl h				; DE:HL = records * 128
	rr l				; rotate right through carry L
	rr e				; rotate right through carry E
	ld d,l				; D = L
	ld l,h				; L = H
	ld h,00H			; H = 00H
	ld (file_size),de		; file size, low word
	ld (file_size_hi),hl		; file size, high word
	ld hl,file_read_pos		; start reading at position 0
	call zero32			; clear file_read_pos
	ld de,send_fcb			; point DE at FCB of the file being sent
	call file_open_input		; open the file
	jr z,send_one_file_1		; opened
	xor a				; could not open: skip this file
	ret				; return
send_one_file_1:
	xor a				; reset the per-file state
	ld (error_count),a		; clear consecutive error/retry counter
	ld a,00H			; A = 00H
	ld (eof_pending),a		; FFH when the end of the file has been read into the = 00H (clear)
	ld (eof_flag),a			; FFH when the disk file is at end of file = 00H (clear)
	ld de,send_fcb			; point DE at FCB of the file being sent
	call print_filename		; show the name and size
	ld hl,files_sent_count		; point HL at number of files sent so far
	inc (hl)			; count this file
	call build_file_info		; send the file header / block 0
	ret c				; aborted
	cp ZSKIP			; receiver does not want it (ZSKIP)?
	ret z				; return: A is ZSKIP
	ld a,(protocol)			; get selected protocol
	cp 04H				; ZMODEM?
	call nz,xmodem_wait_rx		; no: wait for the receiver to start, then send the data
	ret				; return

; ----------------------------------------------------------------------
; build_file_info: Build the ZFILE/block-0 information (name, size) for
; the current file. [sz.c wctxpn]
; ----------------------------------------------------------------------
build_file_info:
	ld hl,(file_buffer_base)	; build "name size" in the buffer
	xor a				; A = 0
	ld b,80H			; clear 128 bytes
	call memset			; fill B bytes at HL with A
	ld de,send_fcb_name		; point DE at name field of send_fcb
	call fcb_to_name		; NAME.EXT from the FCB
	ld b,0CH			; 12 characters at most
build_file_1:
	ld a,(hl)			; Load filename character
	call is_alpha			; a letter?
	jr nz,build_file_2		; if not zero goto build_file_2
	or 20H				; yes: make it lower case
	ld (hl),a			; Store lowercase character back to buffer
build_file_2:
	inc hl				; Advance character pointer
	djnz build_file_1		; repeat until all B items are done
	ld hl,(file_buffer_base)	; get start of the file data ring buffer
	call skip_to_blank		; find the end of the name
	ld (hl),00H			; terminate the name
	inc hl				; Advance past null terminator
	ld de,file_size			; point DE at size of the current file in bytes
	ex de,hl			; swap pointers
	push de				; preserve DE
	call ltoa32			; append the file size as decimal text
	pop de				; restore DE
	ld a,(protocol)			; XMODEM sends no header
	cp 03H				; is it YMODEM?
	ccf				; complement carry
	ret nc				; return: A >= 03H
	ld a,(subpkt_term)		; get terminator for the next data subpacket
	cp ZCRCE			; is it ZCRCE?
	call nz,wait_rx_start		; wait for the receiver to be ready
	ret c				; receiver aborted
	xor a				; block number 0
	ld (xmodem_block_no),a		; clear current XMODEM block number
	ld a,(protocol)			; get selected protocol
	cp 03H				; YMODEM?
	ld hl,0080H			; block 0 is 128 bytes
	ld (block_len),hl		; save as length of the current block / subpacket
	jp z,xmodem_snd_block		; YMODEM: send block 0
	ld hl,(file_buffer_base)	; ZMODEM: work out the length of the ZFILE info string
	call skip_to_blank		; advance HL to the next blank
	inc hl				; Skip null delimiter
	call skip_to_blank		; advance HL to the next blank
	ld de,(file_buffer_base)	; get start of the file data ring buffer
	or a				; test A (sets Z if A = 0)
	sbc hl,de			; HL -= DE + carry
	inc hl				; Include trailing null byte
	ex de,hl			; DE = length
	jp zmodem_snd_zfile		; send ZFILE and its data

; ----------------------------------------------------------------------
; wait_rx_start: Wait for the receiver's start character (C, NAK) or
; ZRINIT. [sz.c getnak]
; ----------------------------------------------------------------------
wait_rx_start:
	ld a,(protocol)			; get selected protocol
	cp 03H				; is it YMODEM?
	ld a,00H			; A = 00H
	call nc,send_hex_header		; if A >= 03H: call send_hex_header
	xor a				; Clear error / response status bytes
	ld (prev_rx_char),a		; clear previous received character
	ld (last_rx_char),a		; clear last character received from the modem
wait_rx_start_1:
	ld b,0FFH			; wait up to 25.5 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	ld hl,start_char_tab		; point HL at first character from the receiver
	ld bc,0005H			; 5 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
wait_rx_start_2:
	ld a,(last_rx_char)		; get last character received from the modem
	ld (prev_rx_char),a		; save as previous received character
	jr wait_rx_start_1		; loop back to wait_rx_start_1
wait_can_confirm:
	ld b,14H			; wait up to 2.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	cp 18H				; is it ZDLE/CAN?
	jr nz,wait_rx_start_2		; if A is not ZDLE/CAN goto wait_rx_start_2
	ld hl,prev_rx_char		; point HL at previous received character
	cp (hl)				; compare A with (HL)
	jr nz,wait_rx_start_2		; if not zero goto wait_rx_start_2
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; 'C': the receiver asks for CRC-16.
got_c_crc_mode:
	ld a,10H			; A = 10H
	ld (tx_crc_mode),a		; CRC type used for sending = 10H (CRC-16)
; NAK: the receiver wants a checksum.
got_nak:
	xor a				; return 0 (success)
	ret				; return
got_timeout:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; got_zpad_zmodem: Receiver started ZMODEM: switch to ZMODEM sending.
; ----------------------------------------------------------------------
got_zpad_zmodem:
	call zmodem_send_init		; send ZRQINIT and wait for the receiver's ZRINIT
	ret c				; return: no ZRINIT from receiver / aborted
	ld a,04H			; A = 04H
	ld (protocol),a			; selected protocol = 04H (ZMODEM)
	xor a				; return 0 (success)
	ret				; return
; wait_rx_start: first character from the receiver
start_char_tab:
	.db 2AH,0FEH,43H,15H,18H	; keys: *.C..
	.dw wait_can_confirm		; key 18H CAN
	.dw got_nak			; key 15H NAK
	.dw got_c_crc_mode		; key 43H 'C' (CRC requested)
	.dw got_timeout			; key 0FEH TIMEOUT
	.dw got_zpad_zmodem		; key 2AH ZPAD: receiver speaks ZMODEM
; xmodem_wait_rx: start character from the receiver
xm_start_tab:
	.db 15H,43H,0FEH,18H		; keys: .C..
	.dw xw_got_can			; key 18H CAN
	.dw xw_timeout			; key 0FEH TIMEOUT
	.dw xw_got_c			; key 43H 'C' (CRC requested)
	.dw xw_got_nak			; key 15H NAK

; ----------------------------------------------------------------------
; xmodem_wait_rx: XMODEM/YMODEM sender session: wait for the
; receiver's NAK / "C" / "G" (sz.c wctx), then send the file in 128- or
; 1024-byte blocks and finish with EOT. [sz.c wctx]
; ----------------------------------------------------------------------
xmodem_wait_rx:
	xor a				; Clear A
	ld (tx_crc_mode),a		; clear CRC type used for sending
	ld a,0FFH			; A = 0FFh
	ld (xm_first_flag),a		; FFH until the first block has been acknowledged = FFH (set)
	ld hl,tx_position		; point HL at position in the file of the next byte to send
	call zero32			; clear tx_position
	ld hl,buffer_start_pos		; point HL at file position corresponding to the start of the ring
	call zero32			; clear buffer_start_pos
xmodem_wait_rx_1:
	ld b,0FFH			; wait up to 25.5 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	ld hl,xm_start_tab		; point HL at start character from the receiver
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jr nz,xmodem_wait_rx_1		; if A is not in the key list goto xmodem_wait_rx_1
	jp dispatch			; loop back to dispatch
; CAN while waiting for the receiver: abort.
xw_got_can:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; 'C': the receiver wants CRC-16 blocks.
xw_got_c:
	ld a,10H			; A = 10H
	ld (tx_crc_mode),a		; CRC type used for sending = 10H (CRC-16)
; NAK: the receiver wants checksum blocks.
xw_got_nak:
	xor a				; A = 0
	ld (xmodem_block_no),a		; clear current XMODEM block number

; ----------------------------------------------------------------------
; xmodem_snd_blks: Send the file as a series of 128/1024-byte blocks.
; [sz.c wctx]
; ----------------------------------------------------------------------
xmodem_snd_blks:
	ld hl,file_size			; point HL at size of the current file in bytes
	ld de,tx_position		; point DE at position in the file of the next byte to send
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call sub32			; pos_scratch = file_size - tx_position
	ld hl,pos_scratch		; point HL at scratch 32-bit result for position arithmetic
	ld de,const_1024		; point DE at 32-bit constant 1024
	call cmp32_signed		; compare pos_scratch with const_1024
	ld hl,0400H			; HL = 0400H
	jr nc,xmodem_snd_1		; if first value >= second goto xmodem_snd_1
	ld hl,0080H			; HL = 0080H
xmodem_snd_1:
	ld (block_len),hl		; save as length of the current block / subpacket
	ld bc,(block_len)		; get length of the current block / subpacket
	call fill_file_buffer		; read BC bytes from the file into the ring buffer
	jr c,xw_timeout			; if disk read error goto xw_timeout
	or a				; Check bytes read status
	jr z,xmodem_snd_2		; if result is zero goto xmodem_snd_2
	ld a,d				; Check if remaining length is zero (EOF)
	or e				; A |= E
	jr z,xmodem_send_eot		; if result is zero goto xmodem_send_eot
xmodem_snd_2:
	ld hl,xmodem_block_no		; point HL at current XMODEM block number
	inc (hl)			; count up current XMODEM block number
	call xmodem_snd_block		; send one block
	ret c				; return: block not acknowledged / aborted
	ld hl,tx_position		; point HL at position in the file of the next byte to send
	ld de,block_len			; point DE at length of the current block / subpacket
	ld bc,tx_position		; point BC at position in the file of the next byte to send
	call add32			; tx_position = block_len + tx_position
	jr xmodem_snd_blks		; loop back to xmodem_snd_blks

; ----------------------------------------------------------------------
; xmodem_send_eot: Send EOT and wait for ACK. [sz.c wctx]
; ----------------------------------------------------------------------
xmodem_send_eot:
	ld b,05H			; Send EOT up to 5 times
xmodem_send_1:
	push bc				; preserve BC
	ld a,04H			; character to send: EOT
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	cp 06H				; is it ACK?
	jr z,xw_timeout_1		; if A is ACK goto xw_timeout_1
	pop bc				; restore BC
	djnz xmodem_send_1		; repeat until all B items are done
; No answer within 25.5 s: abort.
xw_timeout:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
xw_timeout_1:
	pop bc				; restore BC
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; xmodem_snd_block: Send one block: SOH/STX, block number and complement,
; data, checksum or CRC, then wait for the reply. [sz.c wcputsec]
; ----------------------------------------------------------------------
xmodem_snd_block:
	xor a				; no reply seen yet; no errors
	ld (last_rx_char),a		; clear last character received from the modem
	ld (error_count),a		; clear consecutive error/retry counter
xmodem_snd_3:
	ld a,(last_rx_char)		; (re)start of a send attempt
	ld (prev_rx_char),a		; save as previous received character
	ld hl,tx_position		; show where we are
	ld de,pos_display		; point DE at copy of the file position shown on the console
	call copy32			; copy tx_position to pos_display
	call print_position		; print the current file position as a decimal number on
	ld hl,(block_len)		; block length: 128 or 1024
	ld (blk_bytes_left),hl		; save as bytes still to send in the current block
	ld a,l				; Check low byte of length
	cp 80H				; 128 bytes?
	ld a,01H			; yes: start with SOH
	jr z,xmodem_snd_4		; if A = 80H goto xmodem_snd_4
	ld a,02H			; no: start with STX (1K block)
xmodem_snd_4:
	call aux_putc_wait		; send the block start character
	ld a,(xmodem_block_no)		; get current XMODEM block number
	call aux_putc_wait		; send the block number
	ld a,(xmodem_block_no)		; get current XMODEM block number
	cpl				; send its complement
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	call crc_init			; start the checksum / CRC
	ld ix,(file_buffer_base)	; IX -> block data
xmodem_snd_5:
	ld a,(ix+0)			; next data byte
	call checksum_add		; add A to the running 8-bit XMODEM checksum
	call crc16_update		; update the running CRC-16
	push ix				; preserve IX
	call aux_putc_wait		; send it
	pop ix				; restore IX
xmodem_snd_6:
	ld hl,0000H			; HL = bytes left (patched)
blk_bytes_left		.equ xmodem_snd_6+1	; bytes still to send in the current block (patched operand, 16 bits)
	dec hl				; Decrement remaining byte count
	ld (blk_bytes_left),hl		; save as bytes still to send in the current block
	inc ix				; Advance buffer pointer
	ld a,h				; block finished?
	or l				; A = H or L: zero only if HL = 0
	jr nz,xmodem_snd_5		; if the 16-bit count is not zero goto xmodem_snd_5
	ld a,(tx_crc_mode)		; trailer: CRC or checksum?
	cp 10H				; compare A with 10H
	jr z,xmodem_snd_7		; CRC
	ld a,(xm_checksum)		; checksum
	jr xmodem_snd_8			; continue at xmodem_snd_8
xmodem_snd_7:
	ld a,(crc16_hi)			; CRC high byte
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(crc16_lo)			; CRC low byte
xmodem_snd_8:
	call aux_putc_wait		; send the trailer
	ld b,64H			; wait up to 10 s for ACK/NAK
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem

; ----------------------------------------------------------------------
; xs_wait_ack: XMODEM send: wait for ACK/NAK reply.
; ----------------------------------------------------------------------
xs_wait_ack:
	ld a,(last_rx_char)		; get last character received from the modem
	ld hl,xs_reply_tab		; point HL at XModem sender
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jp xs_bad_response		; continue at xs_bad_response
; CAN received (two in a row cancel).
xs_got_can:
	ld a,(prev_rx_char)		; get previous received character
	cp 18H				; is it ZDLE/CAN?
	jp nz,xs_bad_response		; if A is not ZDLE/CAN goto xs_bad_response
xs_got_can_1:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; No reply within 10 s: resend the block.
xs_timeout:
	jp xs_retry			; continue at xs_retry
; 'C' received: the receiver wants CRC-16 instead of a checksum.
xs_got_c:
	ld a,(xm_first_flag)		; get FFH until the first block has been acknowledged
	cp 0FFH				; compare A with 0FFH
	jr nz,xs_got_nak		; if A != FFH goto xs_got_nak
	ld a,10H			; A = 10H
	ld (tx_crc_mode),a		; CRC type used for sending = 10H (CRC-16)
; NAK: the block was damaged; resend it.
xs_got_nak:
	jp xs_retry			; continue at xs_retry
; ACK: block accepted.
xs_got_ack:
	ld a,00H			; A = 00H
	ld (xm_first_flag),a		; FFH until the first block has been acknowledged = 00H (clear)
	xor a				; A = 0
	ld (error_count),a		; clear consecutive error/retry counter
	ret				; return
; Garbage instead of ACK/NAK: count it and resend.
xs_got_garbage:
	jp xs_bad_response		; continue at xs_bad_response
; XModem sender: response to a block
xs_reply_tab:
	.db 18H,0FEH,43H,15H,06H,0FFH	; keys: ..C...
	.dw xs_got_garbage		; key 0FFH ERROR
	.dw xs_got_ack			; key 06H ACK
	.dw xs_got_nak			; key 15H NAK
	.dw xs_got_c			; key 43H 'C' (CRC requested)
	.dw xs_timeout			; key 0FEH TIMEOUT
	.dw xs_got_can			; key 18H CAN
; XModem sender: response after unrecognized characters
xs_garbage_tab:
	.db 0FEH,15H,43H,18H		; keys: ..C.
	.dw xs_chk_can			; key 18H CAN
	.dw xs_wait_ack			; key 43H 'C' (CRC requested)
	.dw xs_wait_ack			; key 15H NAK
	.dw xs_retry			; key 0FEH TIMEOUT
xs_bad_response:
	ld a,(last_rx_char)		; get last character received from the modem
	ld (prev_rx_char),a		; save as previous received character
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	ld hl,xs_garbage_tab		; point HL at XModem sender
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; CAN received after garbage: abort if the previous character was also CAN.
xs_chk_can:
	ld a,(prev_rx_char)		; get previous received character
	cp 18H				; is it ZDLE/CAN?
	jp z,xs_got_can_1		; if A is ZDLE/CAN goto xs_got_can_1
	jr xs_bad_response		; loop back to xs_bad_response

; ----------------------------------------------------------------------
; xs_retry: XMODEM send: count error and resend.
; ----------------------------------------------------------------------
xs_retry:
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; print the current error count / retry message on the
	ld a,(error_count)		; get consecutive error/retry counter
	cp 05H				; Maximum 5 retries allowed
	jp c,xmodem_snd_3		; if A < 05H goto xmodem_snd_3
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; zmodem_send_init: Send ZRQINIT and wait for the receiver's ZRINIT. [sz.c
; getzrxinit]
; ----------------------------------------------------------------------
zmodem_send_init:
	ld a,0BH			; allow up to 10 ZRINIT/ZRQINIT exchanges [getzrxinit: for n=10]
	ld (zrqinit_retries),a		; remaining attempts to get ZRINIT = 0BH
zmodem_send_1:
	ld hl,zrqinit_retries		; point HL at remaining attempts to get ZRINIT
	dec (hl)			; count down remaining attempts to get ZRINIT
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret z				; return: remaining attempts to get ZRINIT has run out
	call get_header			; wait for the receiver's ZRINIT [zgethdr]
	ld hl,send_init_tab		; point HL at ZModem start
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
zmodem_send_2:
	ld a,ZNAK			; frame type = ZNAK
	call send_hex_header		; send a hex header
	jr zmodem_send_1		; loop back to zmodem_send_1
zi_got_zchall:
	ld hl,rx_header_data		; point HL at four argument bytes of the last received header
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy rx_header_data to tx_header_data
	ld a,ZACK			; frame type = ZACK
	call send_hex_header		; send a hex header
	jr zmodem_send_1		; loop back to zmodem_send_1
zi_got_zcommand:
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	call zero32			; clear tx_header_data
	ld a,ZRQINIT			; frame type = ZRQINIT
	call send_hex_header		; send a hex header
	jr zmodem_send_1		; loop back to zmodem_send_1

; ----------------------------------------------------------------------
; zmodem_got_zri: Process the ZRINIT flags from the receiver (CRC-32,
; escape-control, buffer size). [sz.c getzrxinit]
; ----------------------------------------------------------------------
zmodem_got_zri:
	ld ix,rx_header_data		; point IX at four argument bytes of the last received header
	ld a,(ix+ZF0)			; ZF0 = receiver capability flags (CANFDX 1, CANOVIO 2, CANBRK 4, CANCRY 8; 20H CANFC32
					; and 40H ESCCTL in later revisions)
	ld (zrinit_zf0),a		; save as ZF0 from the receiver's ZRINIT
	and CANFC32			; CANFC32: use 32-bit CRC when the receiver can read it
	ld (tx_crc_mode),a		; save as CRC type used for sending
	ld a,(zrinit_zf0)		; get ZF0 from the receiver's ZRINIT
	and ESCCTL			; ESCCTL: receiver wants all control characters escaped
	ld (escape_ctl_flag),a		; save as nonzero
	ld l,(ix+ZP0)			; ZP0, ZP1 = receiver buffer length, 0 = nonstop I/O [Rxbuflen]
	ld h,(ix+ZP1)			; get byte 1 of four argument bytes of the last received header
	ld (rx_window_size),hl		; save as receiver buffer length from ZRINIT ZP0/ZP1
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,zmodem_got_zri_1		; if the 16-bit count is not zero goto zmodem_got_zri_1
	ld a,(window_default)		; no limit announced: use a default window (32K) between acknowledgements
	rla				; Scale to buffer byte count (* 1024)
	rla				; rotate A left through carry
	ld h,a				; H = A
	ld l,00H			; Low byte = 0
	ld (rx_window_size),hl		; save as receiver buffer length from ZRINIT ZP0/ZP1
zmodem_got_zri_1:
	ld hl,0400H			; start with 1024-byte data subpackets [blklen = KSIZE]; no ZSINIT is sent
	ld (subpacket_size),hl		; save as current data subpacket size
	xor a				; return 0 (success)
	ret				; return
; ZCAN or timeout while waiting for ZRINIT: give up.
zi_abort:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; ZRQINIT received instead of ZRINIT: ignore it if it echoes our own, otherwise answer ZNAK.
zi_got_zrqinit:
	ld ix,rx_header_data		; point IX at four argument bytes of the last received header
	ld a,(ix+ZF0)			; get byte 3 of four argument bytes of the last received header
	cp ZCOMMAND			; Compare with 12h
	jp z,zmodem_send_1		; if A = 12H goto zmodem_send_1
	jp zmodem_send_2		; loop back to zmodem_send_2
; ZModem start: frame type of the receiver's answer
send_init_tab:
	.db ZCHALLENGE,ZCOMMAND,ZRINIT,ZCAN,0FEH,ZRQINIT	; keys: ......
	.dw zi_got_zrqinit		; key 00H ZRQINIT
	.dw zi_abort			; key 0FEH timeout
	.dw zi_abort			; key 10H ZCAN
	.dw zmodem_got_zri		; key 01H ZRINIT
	.dw zi_got_zcommand		; key 12H ZCOMMAND
	.dw zi_got_zchall		; key 0EH ZCHALLENGE

; ----------------------------------------------------------------------
; zmodem_snd_zfile: Send the ZFILE header and its data subpacket, then
; wait for ZRPOS/ZSKIP. [sz.c zsendfile]
; ----------------------------------------------------------------------
zmodem_snd_zfile:
	ld (zfile_info_len),de		; save as length of the ZFILE info subpacket
	ld hl,tx_position		; point HL at position in the file of the next byte to send
	call zero32			; clear tx_position
zmodem_snd_1:
	ld ix,tx_header_data		; point IX at four argument bytes for the next header to send
	ld a,(opt_binary_flag)		; get FFH if -b
	cp 0FFH				; Is binary transfer active?
	ld a,ZF0_ZCBIN			; ZF0 = 1 (ZCBIN: binary transfer)
	jr z,zmodem_snd_2		; if A = FFH goto zmodem_snd_2
	ld a,(opt_convert_flag)		; get FFH if -c
	cp 0FFH				; Is text conversion active?
	ld a,ZF0_ZCNL			; ZF0 = 2 (ZCNL: convert end-of-line)
	jr z,zmodem_snd_2		; if A = FFH goto zmodem_snd_2
	xor a				; Default ZF0 = 0 (standard transfer)
zmodem_snd_2:
	ld (ix+ZF0),a			; ZF0 conversion option: 1 = ZCBIN (-b), 2 = ZCNL (-c) [Lzconv]
	ld a,(opt_protect_flag)		; get FFH if -p
	cp 0FFH				; compare A with 0FFH
	ld a,ZF1_ZMPROT			; ZF1 = 7 (ZCRECOV: recover interrupted transfer)
	jr z,zmodem_snd_3		; if A = FFH goto zmodem_snd_3
	ld a,(opt_append_flag)		; get FFH if -a
	cp 0FFH				; compare A with 0FFH
	ld a,ZF1_ZMAPND			; A = 03H
	jr z,zmodem_snd_3		; if A = FFH goto zmodem_snd_3
	xor a				; Default ZF1 = 0
zmodem_snd_3:
	ld (ix+ZF1),a			; ZF1 management option: 7 = ZMPROT (-p), 3 = ZMAPND (-a) [Lzmanag]
	xor a				; Clear A
	ld (ix+ZF2),a			; ZF2 transport option = 0 [Lztrans]
	ld (ix+ZF3),a			; ZF3 = 0
	ld a,ZFILE			; frame type = ZFILE
	call send_bin_header		; send the ZFILE header [zsbhdr]
zmodem_snd_4:
	ld bc,0000H			; 0 keys in the table
zfile_info_len		.equ zmodem_snd_4+1	; length of the ZFILE info subpacket (patched operand, 16 bits)
	ld a,ZCRCW			; A = 6BH
	call send_subpacket		; file name and size as a ZCRCW data packet [zsbdata]
zmodem_snd_5:
	call get_header			; wait for ZRPOS, ZSKIP, ... [zgethdr]
	ld hl,zfile_reply_tab		; point HL at frame type of the receiver's answer
	ld bc,0008H			; 8 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr zmodem_snd_1			; loop back to zmodem_snd_1
; ZRINIT again: wait up to 5 s for ZPAD; if none arrives send the ZFILE again.
zf_wait_zpad:
	ld b,32H			; wait up to 5.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,zmodem_snd_1		; if timed out waiting for the modem goto zmodem_snd_1
	cp ZPAD				; is it ZPAD?
	jr z,zmodem_snd_5		; if A is ZPAD goto zmodem_snd_5
	jr zf_wait_zpad			; loop back to zf_wait_zpad
; Abort the ZModem transfer.
zf_abort:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; Ignore this frame and read the next header.
zf_ignore:
	jp zmodem_snd_5			; loop back to zmodem_snd_5
; ZSKIP: the receiver does not want the file.
zf_skip:
	ld a,ZSKIP			; return ZSKIP
	ret				; return
; ZRPOS: reposition the file and start streaming data.
zf_got_zrpos:
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	ld de,zrpos_target		; point DE at position requested by ZRPOS
	call copy32			; copy rx_pos_arg to zrpos_target
	call reposition_file		; ZRPOS: seek the file to the requested offset [fseek(in, Rxpos)]
	ret c				; return: cannot reposition
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	ld de,zack_pos			; point DE at position from the last ZACK
	call copy32			; copy rx_pos_arg to zack_pos
	ld de,tx_position		; point DE at position in the file of the next byte to send
	call copy32			; copy 32-bit value
	ld de,last_sync_pos		; point DE at position at the last synchronisation point
	call copy32			; copy 32-bit value
	ld de,last_zrpos_pos		; point DE at position of the last ZRPOS request
	call copy32			; copy 32-bit value
	ex de,hl			; swap pointers
	call dec32			; (step the saved position back by one)
	jp zmodem_send_data		; continue at zmodem_send_data
; ZFILE: frame type of the receiver's answer
zfile_reply_tab:
	.db ZRINIT,ZCAN,0FEH,ZABORT,ZFIN,ZCRC,ZSKIP,ZRPOS	; keys: ........
	.dw zf_got_zrpos		; key 09H ZRPOS
	.dw zf_skip			; key 05H ZSKIP
	.dw zf_ignore			; key 0DH ZCRC
	.dw zf_abort			; key 08H ZFIN
	.dw zf_abort			; key 07H ZABORT
	.dw zf_abort			; key 0FEH timeout
	.dw zf_abort			; key 10H ZCAN
	.dw zf_wait_zpad		; key 01H ZRINIT

; ----------------------------------------------------------------------
; zmodem_send_data: Start sending file data from the position requested.
; [sz.c zsendfdata]
; ----------------------------------------------------------------------
zmodem_send_data:
	xor a				; Clear consecutive error counter
	ld (same_zrpos_count),a		; clear number of times in a row ZRPOS asked for the same
	ld (error_count),a		; clear consecutive error/retry counter
zmodem_send_3:
	jp zmodem_stream		; continue at zmodem_stream
zmodem_send_4:
	xor a				; A = 0
	ld (resp_junk_count),a		; clear garbage characters seen while streaming
	ld a,0FFH			; A = 0FFH
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
zmodem_send_5:
	ld hl,zcrcw_reply_tab		; point HL at after a ZCRCW subpacket
	ld bc,0005H			; 5 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; ZCAN, timeout or error: abort.
zd_abort:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; ZSKIP: the receiver does not want this file.
zd_got_zskip:
	ld a,ZSKIP			; return ZSKIP
	ret				; return
; ZRINIT received: the file was accepted.
zd_ok:
	xor a				; return 0 (success)
	ret				; return
; After a ZCRCW subpacket: frame type of the receiver's answer
zcrcw_reply_tab:
	.db ZCAN,ZSKIP,ZACK,ZRPOS,ZRINIT	; keys: .....
	.dw zd_ok			; key 01H ZRINIT
	.dw zd_got_zrpos		; key 09H ZRPOS
	.dw zd_got_zack			; key 03H ZACK
	.dw zd_got_zskip		; key 05H ZSKIP
	.dw zd_abort			; key 10H ZCAN
; ZACK received: acknowledged; carry on streaming.
zd_got_zack:
	xor a				; A = 0
	ld (error_count),a		; clear consecutive error/retry counter

; ----------------------------------------------------------------------
; zd_got_zrpos: ZRPOS received while streaming.
; ----------------------------------------------------------------------
zd_got_zrpos:
	call aux_poll_input		; poll the AUX device
	jr z,zmodem_stream		; if nothing waiting at the modem goto zmodem_stream
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
zd_got_zrpos_1:
	ld hl,after_ack_tab		; point HL at after a ZACK
	ld bc,0005H			; 5 keys in the table
	cpir				; look A up in the key table
	jr nz,zd_got_zrpos		; if A is not in the key list goto zd_got_zrpos
	jp dispatch			; loop back to dispatch
; ZPAD or ZDLE seen: a header is coming; read it.
zd_got_pad:
	ld a,00H			; A = 00H
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
	jp zmodem_send_5		; loop back to zmodem_send_5
; XOFF seen: the line is paused; wait for it to be released.
zd_got_xoff:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr zd_got_zrpos_1		; loop back to zd_got_zrpos_1
; After a ZACK: character that arrived from the receiver
after_ack_tab:
	.db 0FEH,ZDLE,ZPAD,13H,93H	; keys: ..*..
	.dw zd_got_xoff			; key 93H XOFF (bit 7 set)
	.dw zd_got_xoff			; key 13H XOFF
	.dw zd_got_pad			; key 2AH ZPAD
	.dw zd_got_pad			; key 18H ZDLE/CAN
	.dw zd_abort			; key 0FEH timeout

; ----------------------------------------------------------------------
; zmodem_stream: Send ZDATA then stream data subpackets, checking for
; ZRPOS/ZACK from the receiver. [sz.c zsendfdata]
; ----------------------------------------------------------------------
zmodem_stream:
	ld hl,(rx_window_size)		; receiver's window = how much may be sent without an acknowledgement
	ld (window_remaining),hl	; save as bytes left before the receiver must acknowledge
	ld hl,tx_position		; header argument = position
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy tx_position to tx_header_data
	ld a,ZDATA			; frame type ZDATA
	call send_bin_header		; announce the data
zmodem_stream_1:
	call get_next_chunk		; HL = length of the next chunk (up to subpacket_size)
	ret c				; disk read error
	ld (chunk_len),hl		; save as number of bytes in the current chunk
	ld a,(eof_pending)		; last chunk of the file?
	cp 0FFH				; compare A with 0FFH
	jr nz,zmodem_stream_2		; if A != FFH goto zmodem_stream_2
	ld a,ZCRCE			; last (short) chunk: end the frame with ZCRCE, no reply expected [zsendfdata: c <
					; blklen]
	ld (subpkt_term),a		; terminator for the next data subpacket = 68H (ZCRCE)
	jp zmodem_stream_6		; continue at zmodem_stream_6
zmodem_stream_2:
	ld a,(resp_junk_count)		; trouble seen from the receiver?
	cp 04H				; compare A with 04H
	jr c,zmodem_stream_4		; if A < 04H goto zmodem_stream_4
zmodem_stream_3:
	ld a,ZCRCW			; end with ZCRCW: the receiver must acknowledge before more data is sent
	ld (subpkt_term),a		; terminator for the next data subpacket = 6BH (ZCRCW)
	jp zmodem_stream_6		; continue at zmodem_stream_6
zmodem_stream_4:
	ld hl,last_sync_pos		; just resent after a ZRPOS to the same position?
	ld de,last_zrpos_pos		; point DE at position of the last ZRPOS request
	call eq32			; compare last_sync_pos with last_zrpos_pos
	jr z,zmodem_stream_3		; yes: be careful, use ZCRCW
	ld hl,(rx_window_size)		; receiver has a window?
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,zmodem_stream_5		; no window: stream freely
	ld hl,(window_remaining)	; get bytes left before the receiver must acknowledge
	ld de,(chunk_len)		; get number of bytes in the current chunk
	sbc hl,de			; window left after this chunk [zsendfdata: newcnt -= c]
	ld (window_remaining),hl	; save as bytes left before the receiver must acknowledge
	jr z,zmodem_stream_3		; window used up: ZCRCW
	jr c,zmodem_stream_3		; if carry goto zmodem_stream_3
zmodem_stream_5:
	ld a,ZCRCG			; otherwise ZCRCG: more data follows, no reply needed [zsendfdata: e = ZCRCG]
	ld (subpkt_term),a		; terminator for the next data subpacket = 69H (ZCRCG)
zmodem_stream_6:
	ld a,(subpkt_term)		; send the chunk with the chosen terminator
	ld bc,(chunk_len)		; get number of bytes in the current chunk
	call send_subpacket		; send BC data bytes followed by ZDLE and the terminator
	ld de,chunk_len			; position += chunk length
	ld hl,tx_position		; point HL at position in the file of the next byte to send
	ld bc,tx_position		; point BC at position in the file of the next byte to send
	call add32			; tx_position = chunk_len + tx_position
	ld hl,tx_position		; remember the position of this subpacket
	ld de,last_sync_pos		; point DE at position at the last synchronisation point
	call copy32			; copy tx_position to last_sync_pos
	ld a,(subpkt_term)		; get terminator for the next data subpacket
	cp ZCRCW			; ZCRCW: the receiver must acknowledge
	jp z,zmodem_send_4		; go and wait for the ZACK
zmodem_stream_7:
	call aux_poll_input		; anything from the receiver?
	jr z,zs_got_xoff_1		; no: carry on
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
zmodem_stream_8:
	ld hl,rev_sample_tab		; point HL at reverse-channel sampling while streaming
	ld bc,0005H			; 5 keys in the table
	cpir				; XON/XOFF, ZPAD, ZDLE or timeout?
	jp z,dispatch			; if A is in the key list goto dispatch
	ld hl,resp_junk_count		; other junk: note it
	inc (hl)			; count up garbage characters seen while streaming
	jr zmodem_stream_7		; look again
zs_got_pad:
	ld a,00H			; A = 00H
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
	cp ZACK				; is it ZACK?
	jr z,zs_got_xoff_1		; if A is ZACK goto zs_got_xoff_1
	push af				; preserve AF
zs_got_pad_1:
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_reset			; clear the 6-byte ring buffer control block at HL
	call aux_poll_input		; poll the AUX device
	jr nz,zs_got_pad_1		; if input was waiting goto zs_got_pad_1
	ld a,ZCRCE			; a ZPAD arrived from the receiver: send an empty ZCRCE data packet first [spec 9.1,
					; sampling the reverse channel]
	ld bc,0000H			; BC = 0000H
	call send_subpacket		; send BC data bytes followed by ZDLE and the terminator
	pop af				; restore AF
	jp zmodem_send_5		; loop back to zmodem_send_5
zs_got_xoff:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld hl,resp_junk_count		; point HL at garbage characters seen while streaming
	inc (hl)			; count up garbage characters seen while streaming
	jr zmodem_stream_8		; loop back to zmodem_stream_8
; Reverse-channel sampling while streaming: character from the receiver
rev_sample_tab:
	.db 0FEH,ZDLE,ZPAD,13H,93H	; keys: ..*..
	.dw zs_got_xoff			; key 93H XOFF (bit 7 set)
	.dw zs_got_xoff			; key 13H XOFF
	.dw zs_got_pad			; key 2AH ZPAD
	.dw zs_got_pad			; key 18H ZDLE/CAN
	.dw zd_abort			; key 0FEH timeout
zs_got_xoff_1:
	ld a,(eof_pending)		; get FFH when the end of the file has been read into the
	cp 0FFH				; compare A with 0FFH
	jp nz,zmodem_stream_1		; if A != FFH goto zmodem_stream_1

; ----------------------------------------------------------------------
; zmodem_send_zeof: Send ZEOF and wait for the receiver's ZRINIT. [sz.c
; zsendfdata (ZEOF)]
; ----------------------------------------------------------------------
zmodem_send_zeof:
	ld hl,tx_position		; point HL at position in the file of the next byte to send
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy tx_position to tx_header_data
	ld a,ZEOF			; frame type = ZEOF
	call send_bin_header		; ZEOF: the position tells the receiver how many bytes were sent [zsbhdr]
	ld a,0FFH			; Wait for receiver response
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
	ld hl,zeof_reply_tab		; point HL at after ZEOF
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; ZACK after ZEOF: send ZEOF again.
zeof_retry:
	jr zmodem_send_zeof		; loop back to zmodem_send_zeof
; ZRPOS after ZEOF: the receiver is missing data; send from its offset again.
zeof_resend:
	jp zmodem_send_3		; loop back to zmodem_send_3

; ----------------------------------------------------------------------
; zeof_ok: Receiver acknowledged ZEOF.
; ----------------------------------------------------------------------
zeof_ok:
	xor a				; return 0 (success)
	ret				; return
; ZSKIP after ZEOF.
zeof_skip:
	ret				; return
; After ZEOF: frame type of the receiver's answer
zeof_reply_tab:
	.db ZACK,ZRPOS,ZRINIT,ZSKIP	; keys: ....
	.dw zeof_skip			; key 05H ZSKIP
	.dw zeof_ok			; key 01H ZRINIT
	.dw zeof_resend			; key 09H ZRPOS
	.dw zeof_retry			; key 03H ZACK

; ----------------------------------------------------------------------
; zmodem_get_resp: Wait for a header from the receiver and dispatch on
; its type. [sz.c getinsync]
; ----------------------------------------------------------------------
zmodem_get_resp:
	ld (resp_mode_flag),a		; A = FFH: accept only a ZACK for the current position; 0: any ZACK
zmodem_get_1:
	call get_header			; receive a ZMODEM header
	ld hl,resp_frame_tab		; point HL at frame type received
	ld bc,0009H			; 9 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; Bad header: send ZNAK and read again.
resp_send_znak:
	ld a,ZNAK			; frame type = ZNAK
	call send_bin_header		; send a binary header
	jr zmodem_get_1			; loop back to zmodem_get_1
; ZSKIP: return it to the caller.
resp_return:
	ret				; return
; ZRINIT: file finished; close it and return.
resp_zack_pass:
	push af				; preserve AF
	call file_close_input		; ZRINIT or ZSKIP: the file is finished, close it [getinsync]
	pop af				; restore AF
	ret				; return
; ZACK: remember its position and accept it if it matches what was sent.
resp_zack_check:
	ld de,zack_pos			; point DE at position from the last ZACK
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	call copy32			; copy rx_pos_arg to zack_pos
resp_zack_1:
	ld a,00H			; A = 00H
resp_mode_flag		.equ resp_zack_1+1	; FFH: wait for a ZACK at the current position (patched operand)
	cp 00H				; Compare with 0
	ld a,ZACK			; return ZACK
	ret z				; return: A = 00H
	ld de,tx_position		; point DE at position in the file of the next byte to send
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	call eq32			; compare rx_pos_arg with tx_position
	ld a,ZACK			; return ZACK
	ret z				; return: values are equal
	jp zmodem_get_1			; loop back to zmodem_get_1

; ----------------------------------------------------------------------
; zmodem_do_zrpos: Handle ZRPOS: reposition the file and restart
; streaming. [sz.c getinsync (ZRPOS)]
; ----------------------------------------------------------------------
zmodem_do_zrpos:
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	ld de,zrpos_target		; point DE at position requested by ZRPOS
	call copy32			; copy rx_pos_arg to zrpos_target
	call reposition_file		; seek the file to the offset the receiver asked for [fseek(in, Rxpos)]
	ret c				; return: cannot reposition
	ld a,00H			; A = 00H
	ld (eof_pending),a		; FFH when the end of the file has been read into the = 00H (clear)
	ld hl,error_count		; point HL at consecutive error/retry counter
	inc (hl)			; count up consecutive error/retry counter
	call print_err_count		; count the error
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	ld de,tx_position		; point DE at position in the file of the next byte to send
	call copy32			; copy rx_pos_arg to tx_position
	ld de,zack_pos			; point DE at position from the last ZACK
	call copy32			; copy 32-bit value
	ld de,last_sync_pos		; point DE at position at the last synchronisation point
	call copy32			; copy 32-bit value
	ld de,last_zrpos_pos		; point DE at position of the last ZRPOS request
	call eq32			; compare 32-bit values
	jr nz,zmodem_do_1		; if values differ goto zmodem_do_1
	ld a,(same_zrpos_count)		; get number of times in a row ZRPOS asked for the same
	inc a				; Increment consecutive error count
	ld (same_zrpos_count),a		; save as number of times in a row ZRPOS asked for the same
	cp 05H				; 5 consecutive errors at same position?
	jr c,zmodem_do_1		; if A < 05H goto zmodem_do_1
	ld hl,0020H			; HL = 0020H
	ld de,(subpacket_size)		; get current data subpacket size
	or a				; test A (sets Z if A = 0)
	sbc hl,de			; Is current size already at minimum (32 bytes)?
	jr nc,zmodem_do_1		; If at minimum, cannot reduce
	srl d				; repeated ZRPOS for the same offset: halve the data subpacket size
	rr e				; rotate right through carry E
	ld (subpacket_size),de		; save as current data subpacket size
zmodem_do_1:
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	ld de,last_zrpos_pos		; point DE at position of the last ZRPOS request
	call copy32			; copy rx_pos_arg to last_zrpos_pos
	ld a,ZRPOS			; return ZRPOS
	ret				; return
; Abort (ZCAN, ZABORT, ZFIN or timeout).
resp_abort:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; zmodem_get_resp: frame type received
resp_frame_tab:
	.db ZCAN,ZABORT,ZFIN,0FEH,ZRPOS,ZACK,ZRINIT,ZSKIP,0FFH	; keys: .........
	.dw resp_send_znak		; key 0FFH error
	.dw resp_return			; key 05H ZSKIP
	.dw resp_zack_pass		; key 01H ZRINIT
	.dw resp_zack_check		; key 03H ZACK
	.dw zmodem_do_zrpos		; key 09H ZRPOS
	.dw resp_abort			; key 0FEH timeout
	.dw resp_abort			; key 08H ZFIN
	.dw resp_abort			; key 07H ZABORT
	.dw resp_abort			; key 10H ZCAN

; ----------------------------------------------------------------------
; reposition_file: Seek the file buffer to the requested position (re-
; reading if necessary). [sz.c fseek(in, Rxpos)]
; ----------------------------------------------------------------------
reposition_file:
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	ld de,file_buffer_size		; point DE at size of the file data ring buffer
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call sub32			; pos_scratch = file_read_pos - file_buffer_size
	ld hl,zrpos_target		; point HL at position requested by ZRPOS
	ld de,pos_scratch		; point DE at scratch 32-bit result for position arithmetic
	call cmp32_signed		; compare zrpos_target with pos_scratch
	jp nc,reposition_1		; if first value >= second goto reposition_1
	ld a,00H			; A = 00H
	ld (eof_flag),a			; FFH when the disk file is at end of file = 00H (clear)
	ld hl,zrpos_target		; point HL at position requested by ZRPOS
	ld de,const_minus_1024		; point DE at 32-bit constant -1024
	ld bc,reposition_temp		; point BC at temporary position used while repositioning the file
	call and32			; reposition_temp = const_minus_1024 AND zrpos_target
	ld hl,reposition_temp		; point HL at temporary position used while repositioning the file
	call file_rewind_skip		; rewind the file and skip forward to the target position
	ret c				; If error, return
	ld hl,reposition_temp		; point HL at temporary position used while repositioning the file
	ld de,buffer_start_pos		; point DE at file position corresponding to the start of the ring
	call copy32			; copy reposition_temp to buffer_start_pos
	ld bc,(file_buffer_size)	; get size of the file data ring buffer
	call fill_file_buffer		; read BC bytes from the file into the ring buffer
	ret c				; return: disk read error
	xor a				; return 0 (success)
	ret				; return
reposition_1:
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	ld de,const_1024		; point DE at 32-bit constant 1024
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call sub32			; pos_scratch = file_read_pos - const_1024
	ld hl,pos_scratch		; point HL at scratch 32-bit result for position arithmetic
	ld de,zrpos_target		; point DE at position requested by ZRPOS
	call cmp32_signed		; compare pos_scratch with zrpos_target
	jp nc,reposition_2		; if first value >= second goto reposition_2
	ld a,00H			; Target lies beyond loaded buffer: seek forward
	ld (eof_flag),a			; FFH when the disk file is at end of file = 00H (clear)
	ld hl,zrpos_target		; point HL at position requested by ZRPOS
	ld de,const_minus_1024		; point DE at 32-bit constant -1024
	ld bc,reposition_temp		; point BC at temporary position used while repositioning the file
	call and32			; reposition_temp = const_minus_1024 AND zrpos_target
	ld hl,reposition_temp		; point HL at temporary position used while repositioning the file
	call file_skip_fwd		; advance the file read position to the target position
	ret c				; return if carry
	ld hl,reposition_temp		; point HL at temporary position used while repositioning the file
	ld de,buffer_start_pos		; point DE at file position corresponding to the start of the ring
	call copy32			; copy reposition_temp to buffer_start_pos
	ld bc,(file_buffer_size)	; get size of the file data ring buffer
	call fill_file_buffer		; read BC bytes from the file into the ring buffer
	ret c				; return: disk read error
	xor a				; return 0 (success)
	ret				; return
reposition_2:
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; file_skip_fwd: Advance the file read position to the target position
; by reading.
; ----------------------------------------------------------------------
file_skip_fwd:
	ex de,hl			; swap pointers
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	jr file_rewind_1		; continue at file_rewind_1

; ----------------------------------------------------------------------
; file_rewind_skip: Rewind the file and skip forward to the target
; position.
; ----------------------------------------------------------------------
file_rewind_skip:
	call file_close_input		; close the input file
	ld de,send_fcb			; point DE at FCB of the file being sent
	call file_open_input		; open the file named at DE for reading
	ex de,hl			; swap pointers
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	call zero32			; clear file_read_pos
file_rewind_1:
	call eq32			; compare 32-bit values
	ret z				; return: values are equal
	call file_getc			; read the next byte from the input file
	jr nz,file_rewind_2		; if end of file or error goto file_rewind_2
	call inc32			; increment the 32-bit value at
	jr file_rewind_1		; loop back to file_rewind_1
file_rewind_2:
	xor 04H				; Check for CP/M EOF (Ctrl-Z / status 4)
	ret z				; If EOF, return
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; get_next_chunk: Get the next chunk of file data to send; sets the end-
; of-file flag. [sz.c zfilbuf]
; ----------------------------------------------------------------------
get_next_chunk:
	ld hl,chunk_len			; point HL at number of bytes in the current chunk
	call zero32			; clear chunk_len
	ld hl,last_sync_pos		; point HL at position at the last synchronisation point
	ld de,buffer_mask		; point DE at file buffer size mask
	ld bc,buffer_start_pos		; point BC at file position corresponding to the start of the ring
	call and32			; buffer_start_pos = buffer_mask AND last_sync_pos
	ld hl,last_sync_pos		; point HL at position at the last synchronisation point
	ld de,file_read_pos		; point DE at position of the next byte to be read from the disk file
	call cmp32_signed		; compare last_sync_pos with file_read_pos
	jp c,get_next_chunk_1		; if first value is smaller goto get_next_chunk_1
	ld bc,(subpacket_size)		; get current data subpacket size
	call fill_file_buffer		; read BC bytes from the file into the ring buffer
	ret c				; return: disk read error
	ld a,(eof_flag)			; get FFH when the disk file is at end of file
	ld (eof_pending),a		; save as FFH when the end of the file has been read into the
	ex de,hl			; swap pointers
	ret				; return
get_next_chunk_1:
	ld hl,last_sync_pos		; point HL at position at the last synchronisation point
	ld de,subpacket_size		; point DE at current data subpacket size
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call add32			; pos_scratch = subpacket_size + last_sync_pos
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	ld de,pos_scratch		; point DE at scratch 32-bit result for position arithmetic
	call cmp32_signed		; compare file_read_pos with pos_scratch
	jp c,get_next_chunk_2		; if first value is smaller goto get_next_chunk_2
	ld hl,(subpacket_size)		; get current data subpacket size
	ret				; return
get_next_chunk_2:
	ld a,(eof_flag)			; get FFH when the disk file is at end of file
	ld (eof_pending),a		; save as FFH when the end of the file has been read into the
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	ld de,last_sync_pos		; point DE at position at the last synchronisation point
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call sub32			; pos_scratch = file_read_pos - last_sync_pos
	ld hl,(pos_scratch)		; get scratch 32-bit result for position arithmetic
	ret				; return

; ----------------------------------------------------------------------
; fill_file_buffer: Read BC bytes from the file into the ring buffer.
; [sz.c zfilbuf]
; ----------------------------------------------------------------------
fill_file_buffer:
	ld de,0000H			; Initialize buffer write offset = 0
fill_file_1:
	call ring_buffer_addr		; compute the address of the ring-buffer byte at offset
	call file_getc			; read the next byte from the input file
	jr nz,fill_file_2		; if end of file or error goto fill_file_2
	ld (hl),a			; Store byte into circular transmit buffer
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	call inc32			; add 1 to file_read_pos
	inc de				; DE++
	dec bc				; Decrement requested read byte count
	ld a,b				; Check if all bytes read
	or c				; A |= C
	jr nz,fill_file_1		; Loop until entire block is loaded
	ret				; return
fill_file_2:
	cp 04H				; CP/M EOF status (Ctrl-Z / status 4)?
	ld a,0FFH			; A = 0FFH
	ld (eof_flag),a			; FFH when the disk file is at end of file = FFH (set)
	ret z				; If normal EOF, return with NC
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; ring_buffer_addr: Compute the address of the ring-buffer byte at offset
; DE from the buffer start.
; ----------------------------------------------------------------------
ring_buffer_addr:
	push bc				; preserve BC
	push de				; preserve DE
	ld hl,(buffer_start_pos)	; get file position corresponding to the start of the ring
	add hl,de			; Add offset DE
	ld bc,(buffer_mask)		; get file buffer size mask
	ld a,h				; Apply mask high byte
	and b				; A &= B
	ld h,a				; H = A
	ld a,l				; Apply mask low byte
	and c				; A &= C
	ld l,a				; L = A
	ld de,(file_buffer_base)	; get start of the file data ring buffer
	add hl,de			; HL = absolute memory address of byte slot
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; send_zfin_oo: Send ZFIN, wait for the receiver's ZFIN and answer with
; "OO". [sz.c saybibi]
; ----------------------------------------------------------------------
send_zfin_oo:
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	call zero32			; clear tx_header_data
	ld a,ZFIN			; frame type = ZFIN
	call send_hex_header		; ZFIN: end of session [saybibi: zsbhdr(ZFIN)]
	call get_header			; receive a ZMODEM header
	ret c				; return: no valid header (timeout/error)
	cp ZCAN				; is it ZCAN?
	ret z				; return: A is ZCAN
	cp ZFIN				; is it ZFIN?
	jr nz,send_zfin_oo		; if A is not ZFIN goto send_zfin_oo
	ld a,4FH			; character to send: 'O'
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,4FH			; A = 4FH
	jp aux_putc_wait		; continue at aux_putc_wait

; ----------------------------------------------------------------------
; send_subpacket: Send BC data bytes followed by ZDLE and the
; terminator in A, with CRC-16 or CRC-32. [zm.c zsbdata]
; ----------------------------------------------------------------------
send_subpacket:
	ld (data_terminator),a		; A = terminator (ZCRCE/G/Q/W)
	push bc				; BC = number of data bytes
	ld hl,tx_position		; update the progress display
	ld de,pos_display		; point DE at copy of the file position shown on the console
	call copy32			; copy tx_position to pos_display
	call print_position		; print the current file position as a decimal number on
	pop bc				; restore BC
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	ld de,0000H			; DE = offset into the ring buffer
	ld a,(tx_crc_mode)		; CRC-32 in use?
	and CANFC32			; test the CRC-32 flag bit
	jr nz,send_subpacket_3		; yes
send_subpacket_1:
	ld a,b				; CRC-16: send BC data bytes
	or c				; A |= C
	jr z,send_subpacket_2		; if zero goto send_subpacket_2
	push bc				; preserve BC
	push de				; preserve DE
	call ring_buffer_addr		; HL -> byte in the ring buffer
	ld a,(hl)			; Load data byte
	call crc16_update		; include it in the CRC
	call put_zdle_char		; send it, escaped if necessary
	pop de				; restore DE
	pop bc				; restore BC
	inc de				; Advance offset
	dec bc				; Decrement remaining byte count
	jr send_subpacket_1		; next byte
send_subpacket_2:
	ld a,ZDLE			; end of data: ZDLE ...
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(data_terminator)		; ... then the terminator
	call crc16_update		; the terminator is part of the CRC
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(crc16_hi)			; send the CRC, high byte first
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	ld a,(crc16_lo)			; get CRC-16 low byte
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	ld a,(data_terminator)		; get terminator byte of the data subpacket being sent
	cp ZCRCW			; ZCRCW?
	ret z				; yes: no XON
	ld a,11H			; otherwise follow with XON
	jp aux_putc_wait		; continue at aux_putc_wait
send_subpacket_3:
	ld a,b				; CRC-32: send BC data bytes
	or c				; A |= C
	jr z,send_subpacket_4		; If done, send delimiter and CRC-32
	push bc				; preserve BC
	push de				; preserve DE
	call ring_buffer_addr		; compute the address of the ring-buffer byte at offset
	ld a,(hl)			; Load data byte
	call crc32_update		; update the running CRC-32 with byte A
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop de				; restore DE
	pop bc				; restore BC
	inc de				; Advance offset
	dec bc				; Decrement remaining byte count
	jr send_subpacket_3		; loop back to send_subpacket_3
send_subpacket_4:
	ld a,ZDLE			; end of data: ZDLE ...
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(data_terminator)		; get terminator byte of the data subpacket being sent
	call crc32_update		; update the running CRC-32 with byte A
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld b,04H			; send the four CRC bytes, complemented
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
send_subpacket_5:
	ld a,(hl)			; Load CRC byte
	inc hl				; Advance pointer
	push bc				; preserve BC
	push hl				; preserve HL
	cpl				; Invert bits (ones complement of CRC)
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz send_subpacket_5		; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; send_bin_header: Send a binary header (ZBIN or ZBIN32) with frame type A
; and the header buffer contents. [zm.c zsbhdr]
; ----------------------------------------------------------------------
send_bin_header:
	ld (tx_frame_type),a		; save as frame type of the header being sent
	ld a,ZPAD			; character to send: ZPAD
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,ZDLE			; character to send: ZDLE/CAN
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	ld a,(tx_crc_mode)		; get CRC type used for sending
	and CANFC32			; test the CRC-32 flag bit
	jp nz,send_bin_2		; if result is nonzero goto send_bin_2
	ld a,ZBIN			; character to send: ZBIN header marker
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(tx_frame_type)		; get frame type of the header being sent
	call crc16_update		; update the running CRC-16
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	ld b,04H			; 4 bytes to transmit
send_bin_1:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; Advance pointer
	push hl				; preserve HL
	call crc16_update		; update the running CRC-16
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz send_bin_1			; repeat until all B items are done
	ld a,(crc16_hi)			; get CRC-16 high byte
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	ld a,(crc16_lo)			; get CRC-16 low byte
	jp put_zdle_char		; continue at put_zdle_char
send_bin_2:
	ld a,ZBIN32			; character to send: 'C'
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(tx_frame_type)		; get frame type of the header being sent
	call crc32_update		; update the running CRC-32 with byte A
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	ld b,04H			; 4 bytes to transmit
send_bin_3:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; Advance pointer
	push hl				; preserve HL
	call crc32_update		; update the running CRC-32 with byte A
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz send_bin_3			; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld b,04H			; 4 CRC bytes to send
send_bin_4:
	push bc				; preserve BC
	ld a,(hl)			; Load CRC byte
	inc hl				; Advance pointer
	push hl				; preserve HL
	cpl				; Ones complement inversion
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz send_bin_4			; repeat until all B items are done
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
	ret z				; return: A is ZFIN
	ld a,11H			; A = 11H (XON)
	jp aux_putc_wait		; continue at aux_putc_wait
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
; put_zdle_char: Send A, escaping it with ZDLE if it is a control
; character. [zm.c zsendline]
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
put_zdle_char:
	ld (zdl_char),a			; save as character to send after a ZDLE
	ld bc,0009H			; nine characters get special treatment: ZDLE, DLE, XON, XOFF and CR (each also with
					; bit 7 set)
	ld hl,esc_set_tab		; point HL at characters that must be sent escaped with ZDLE
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	and 60H				; other bytes: only control characters (bits 5-6 clear) can need escaping
	jr nz,zdl_escape_1		; if result is nonzero goto zdl_escape_1
	ld a,(escape_ctl_flag)		; receiver/sender asked for ALL control characters to be escaped (ESCCTL)?
	or a				; test A (sets Z if A = 0)
	jr z,zdl_escape_1		; if nonzero is zero/clear goto zdl_escape_1
; Send ZDLE followed by the character XOR 40H, then fall through to send it.
; Common routine: identical in RZ and SZ.
zdl_escape:
	ld hl,zdl_char			; point HL at character to send after a ZDLE
	set 6,(hl)			; escape: send ZDLE followed by the byte with bit 6 flipped
	ld a,ZDLE			; character to send: ZDLE/CAN
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
zdl_escape_1:
	ld a,00H			; Byte to transmit
zdl_char		.equ zdl_escape_1+1	; character to send after a ZDLE (patched operand)

; ----------------------------------------------------------------------
; aux_putc_wait: Send A to the modem, waiting until the output is ready.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
aux_putc_wait:
	ld (aux_out_char),a		; save as character waiting to be sent to the modem
aux_putc_wait_1:
	call aux_poll_input		; poll the AUX device
	call aux_out_ready		; test whether the AUX output is ready
	jr z,aux_putc_wait_1		; if modem not ready for output goto aux_putc_wait_1
aux_putc_wait_2:
	ld a,00H			; Load character
aux_out_char		.equ aux_putc_wait_2+1	; character waiting to be sent to the modem (patched operand)
	jp aux_putc			; loop back to aux_putc
; CR is escaped only if the previous character sent was "@".
; Common routine: identical in RZ and SZ.
zdl_cr_rule:
	ld a,(aux_out_char)		; CR rule: the previous character sent ...
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 40H				; ... was "@"? (a CR after "@" is escaped so Telenet is not triggered)
	jr nz,zdl_escape_1		; if A != 40H goto zdl_escape_1
	jr zdl_escape			; loop back to zdl_escape
; Characters that must be sent escaped with ZDLE, and the routine that decides
; Common data: identical in RZ and SZ.
esc_set_tab:
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
	ld b,0FFH			; wait up to 25.5 s
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
	ld de,rx_pos_arg		; point DE at position argument of the last ZRPOS/ZACK from the
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
; tenths of a second). Carry set on timeout; checks ESC at console.
; [readline]
; Common routine: identical in RZ and SZ.
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
aux_getc_1:
	call aux_wait_input		; wait roughly 100 ms-steps for an input character
	jr nz,aux_getc_2		; if a character arrived goto aux_getc_2
	djnz aux_getc_1			; repeat until all B items are done
	ld a,0FEH			; Timeout status code (0FEh)
	scf				; flag failure to caller (carry set)
	ret				; return
aux_getc_2:
	or a				; test A (sets Z if A = 0)
	ret				; return

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
; set_z3env: Store HL as the ZCPR3 environment pointer.
; Common routine: identical in RZ and SZ.
; ----------------------------------------------------------------------
set_z3env:
	ld (z3env_ptr),hl		; save as address of the ZCPR3 environment descriptor
	ret				; return

; ----------------------------------------------------------------------
; build_file_list: Expand the command-line file specification into a table
; of matching directory entries (16 bytes each: user, name, extension,
; extent data), sorted by name; C = count. A = selection mask: bit 7
; include DIR files, bit 6 include SYS files, bit 5 any user number, bits
; 0-4 user number.
; ----------------------------------------------------------------------
build_file_list:
	push de				; preserve DE
	ld (dir_attr_mask),a		; save as selection mask
	call dir_table_init		; prepare the directory table at HL
	call dir_collect_ff		; scan the directory with BDOS Search First/Next and
	jp build_flist_1		; continue at build_flist_1

; ----------------------------------------------------------------------
; build_flist_alt: Same as build_file_list, but a file listed in
; several extents keeps its HIGHEST extent (dir_dup_mode = 0).
; ----------------------------------------------------------------------
build_flist_alt:
	push de				; preserve DE
	ld (dir_attr_mask),a		; save as selection mask
	call dir_table_init		; prepare the directory table at HL
	call dir_collect_00		; collect matching directory entries
build_flist_1:
	pop de				; restore DE
	ret z				; return if zero
	push af				; preserve AF
	ld a,(dir_attr_mask)		; get selection mask
	call dir_mark_matches		; compare every table entry with the file specification
	call dir_compact		; squeeze the table
	xor a				; A = 0 (sort order)
	call sort_file_list		; sort the BC directory entries at HL
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; sort_file_list: Sort the BC directory entries at HL: build a pointer
; index, Shell-sort the pointers with dir_compare, then rearrange the
; entries in place. A = sort key: 0 = name then extension, 1 = extension
; first.
; ----------------------------------------------------------------------
sort_file_list:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ld (dir_table_ptr),hl		; save as pointer into the directory table
	push hl				; preserve HL
	ld (sort_key_flag),a		; save as sort key
	ld de,dir_table_ptr		; point DE at pointer into the directory table
	ld (sort_count),bc		; save as sort control block
	ld hl,dir_compare		; point HL at dir_compare
	ld (sort_compare_fn),hl		; save as sort control block
	ld hl,(sort_aux)		; get sort control block
	call sort_alloc_index		; build an index of N pointers, one per item
	pop hl				; restore HL
	ld (dir_table_ptr),hl		; save as pointer into the directory table
	call sort_entries		; shell-sort the pointer index
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; dir_compare: Sort callback: compare the directory entries at HL and DE
; (name, extension and extent; extension first when sort_key_flag is
; nonzero; the user number breaks ties). Flags as for CP.
; ----------------------------------------------------------------------
dir_compare:
	push bc				; preserve BC
	push hl				; preserve HL
	push de				; preserve DE
	ld a,(sort_key_flag)		; get sort key
	or a				; 0 = filename then ext; 1 = ext then filename
	jr z,dir_compare_3		; if sort key is zero/clear goto dir_compare_3
	ld bc,FCB_EXT			; Offset to extension (+9)
	add hl,bc			; HL points to extension of first FCB
	ex de,hl			; swap pointers
	add hl,bc			; HL points to extension of second FCB
	ex de,hl			; swap pointers
	ld b,03H			; Compare 3-character extension
	call compare_mem		; compare B bytes at HL and DE
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,dir_compare_2		; if names differ goto dir_compare_2
	push hl				; preserve HL
	push de				; preserve DE
	inc hl				; Point to filename (+1)
	inc de				; DE++
	ld b,08H			; Compare 8-character filename
	call compare_mem		; compare B bytes at HL and DE
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,dir_compare_2		; if names differ goto dir_compare_2
	push hl				; preserve HL
	push de				; preserve DE
	ld bc,FCB_EX			; BC = 000CH
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld a,(de)			; A = (DE)
	cp (hl)				; compare A with (HL)
dir_compare_1:
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,dir_compare_2		; if not zero goto dir_compare_2
	ld a,(de)			; Compare drive/user byte
	cp (hl)				; compare A with (HL)
dir_compare_2:
	pop bc				; restore BC
	ret				; return
dir_compare_3:
	inc hl				; Advance past drive byte to filename (+1)
	inc de				; DE++
	ld b,0CH			; B = 0CH
	call compare_mem		; compare B bytes at HL and DE
	jr dir_compare_1		; loop back to dir_compare_1

; ----------------------------------------------------------------------
; dir_collect_ff: Scan the directory with BDOS Search First/Next and
; insert every file entry into the table. A file that appears in several
; extents keeps its LOWEST extent when entered here (dir_dup_mode
; nonzero); the second entry point (xor a) keeps the highest.
; ----------------------------------------------------------------------
dir_collect_ff:
	or 0AFH				; Opcode F6 AF (or 0AFh); at $+1 it executes xor a
dir_collect_00		.equ dir_collect_ff+1	; alternate entry point inside the instruction above (overlapping decode: xor
					; a)
	ld (dir_dup_mode),a		; save as file seen in several extents
	push hl				; preserve HL
	push de				; preserve DE
	ld (dir_table_ptr),hl		; save as pointer into the directory table
	ld (dir_table_start),hl		; save as start of the directory entry table
	ld hl,dir_search_fcb		; point HL at wildcard FCB used for BDOS search first/next
	ld a,3FH			; Fill drive and name with '?' (all files)
	ld b,0CH			; fill 12 bytes
	call memset_inner		; fill B bytes at HL with A
	xor a				; Zero remaining 24 bytes of FCB
	ld b,18H			; fill 24 bytes
	call memset_inner		; fill B bytes at HL with A
	ld hl,0000H			; Initialize match count = 0
	ld (dir_entry_count),hl		; save as number of directory entries collected
	ld de,0080H			; Default DMA buffer (0080h)
	ld c,F_DMAOFF			; BDOS function: F_DMAOFF
	call BDOS			; F_DMAOFF: set the DMA (transfer) address
	ld c,F_SFIRST			; BDOS Function 17: Search First
	jr dir_collect_ff_2		; continue at dir_collect_ff_2
dir_collect_ff_1:
	call dir_add_entry		; take directory entry number A
	jr z,dir_collect_ff_4		; if entry added goto dir_collect_ff_4
	ld c,F_SNEXT			; BDOS function: F_SNEXT
dir_collect_ff_2:
	ld de,dir_search_fcb		; point DE at wildcard FCB used for BDOS search first/next
	call BDOS			; F_SNEXT: search for the next match
	cp 0FFH				; 0FFh = no more directory entries
	jr nz,dir_collect_ff_1		; if A != FFH goto dir_collect_ff_1
	or 0FFH				; A |= 0FFH
dir_collect_ff_3:
	ld bc,(dir_entry_count)		; get number of directory entries collected
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
dir_collect_ff_4:
	xor a				; A = 0
	jr dir_collect_ff_3		; loop back to dir_collect_ff_3

; ----------------------------------------------------------------------
; dir_add_entry: Take directory entry number A (0-3) of the sector BDOS
; returned in the 0080H buffer. Erased entries (E5H) and special entries
; (user 21H and above) are ignored, a file already in the table is not
; added again, otherwise its first 16 bytes are appended. Z when the table
; is full (top of the TPA reached).
; ----------------------------------------------------------------------
dir_add_entry:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	rrca				; Multiply directory index by 32 (size of entry)
	rrca				; Shift right 3 bits with rotate wraps to bits 5,6
	rrca				; rotate A right
	and 60H				; isolate bits 5-6: zero means a control character
	ld de,0080H			; DE = base of CP/M default DMA buffer
	ld l,a				; HL = offset within DMA sector
	ld h,00H			; H = 00H
	add hl,de			; HL points to 32-byte directory entry in DMA buffer
	ld a,(hl)			; Check user number / status byte
	cp 0E5H				; 0E5h = deleted / empty entry
	jr z,dir_add_entry_2		; if A = E5H goto dir_add_entry_2
	cp 21H				; Greater than 32 (user 0..31)?
	jr nc,dir_add_entry_2		; if A >= 21H goto dir_add_entry_2
	call dir_find_dup		; look for the same user + file name
	jr z,dir_add_entry_2		; if duplicate entry found goto dir_add_entry_2
	push hl				; preserve HL
	ld hl,(dir_entry_count)		; get number of directory entries collected
	inc hl				; HL++
	ld (dir_entry_count),hl		; save as number of directory entries collected
	pop hl				; restore HL
	ld de,(dir_table_ptr)		; get pointer into the directory table
	ld bc,0010H			; BC = 0010H
	ldir				; copy the block
	ld (dir_table_ptr),de		; save as pointer into the directory table
	call get_tpa_top		; compute the top of the TPA
	ld a,h				; High byte of TPA limit
	dec a				; Safety margin of 256 bytes
	cp d				; Compare against current buffer high byte
	jr nz,dir_add_entry_2		; If memory remains, continue
	xor a				; A = 0
dir_add_entry_1:
	ld hl,0FFF6H			; Dummy instruction (never executed directly)
dir_add_entry_2		.equ dir_add_entry_1+1	; alternate entry point inside the instruction above (overlapping decode: or
					; 0FFH)
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; dir_find_dup: Look for the same user + file name (12 bytes) in the
; table. A hit is another extent of a file already listed, so only one
; entry is kept: the lowest extent when dir_dup_mode is nonzero, else the
; highest. Z = already listed.
; ----------------------------------------------------------------------
dir_find_dup:
	push hl				; preserve HL
	ex de,hl			; swap pointers
	ld bc,(dir_entry_count)		; get number of directory entries collected
	ld a,b				; Any entries in table yet?
	or c				; A |= C
	jr z,dir_find_dup_6		; If table empty, file is unique (NZ)
	ld hl,(dir_table_start)		; get start of the directory entry table
dir_find_dup_1:
	push bc				; preserve BC
	push hl				; preserve HL
	push de				; preserve DE
	ld b,0CH			; Compare 12 bytes (user, filename, and extension)
	call compare_mem		; compare B bytes at HL and DE
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,dir_find_dup_5		; if names differ goto dir_find_dup_5
	push hl				; preserve HL
	push de				; preserve DE
	ld bc,FCB_EX			; BC = 000CH
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	add hl,bc			; HL += BC
	ld a,(de)			; A = (DE)
	cp (hl)				; compare A with (HL)
	pop de				; restore DE
	pop hl				; restore HL
	jr nc,dir_find_dup_3		; if no carry goto dir_find_dup_3
	ld a,(dir_dup_mode)		; get file seen in several extents
	or a				; test A (sets Z if A = 0)
	jr nz,dir_find_dup_4		; if file seen in several extents is set/nonzero goto dir_find_dup_4
dir_find_dup_2:
	ex de,hl			; swap pointers
	ld bc,0010H			; 16 bytes
	ldir				; copy the block
	jr dir_find_dup_4		; continue at dir_find_dup_4
dir_find_dup_3:
	ld a,(dir_dup_mode)		; get file seen in several extents
	or a				; test A (sets Z if A = 0)
	jr nz,dir_find_dup_2		; if file seen in several extents is set/nonzero goto dir_find_dup_2
dir_find_dup_4:
	pop bc				; restore BC
	xor a				; A = 0
	pop hl				; restore HL
	ret				; return
dir_find_dup_5:
	ld bc,0010H			; Advance to next 16-byte table entry
	add hl,bc			; HL += BC
	pop bc				; restore BC
	dec bc				; Decrement entries remaining
	ld a,b				; A = B
	or c				; A |= C
	jr nz,dir_find_dup_1		; Continue checking remaining entries
dir_find_dup_6:
	or 0FFH				; A |= 0FFH
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; dir_compact: Squeeze the table: entries marked with bit 7 (they
; matched the file specification) are moved to the front and unmarked; BC
; = number kept.
; ----------------------------------------------------------------------
dir_compact:
	push hl				; preserve HL
	push de				; preserve DE
	push af				; preserve AF
	push hl				; preserve HL
	ld hl,0000H			; Initialize marked counter = 0
	ld (dir_marked_count),hl	; save as number of entries marked / kept
	pop hl				; restore HL
	ld (dir_table_ptr),hl		; save as pointer into the directory table
	push bc				; preserve BC
dir_compact_1:
	pop bc				; restore BC
	ld a,b				; Any entries remaining?
	or c				; A |= C
	jr z,dir_compact_3		; If all processed, finish
	dec bc				; Decrement loop counter
	push bc				; preserve BC
	bit 7,(hl)			; Check if entry was marked (bit 7 set)
	jr z,dir_compact_2		; If not marked, skip entry
	res 7,(hl)			; Clear mark bit
	ex de,hl			; swap pointers
	ld hl,(dir_marked_count)	; get number of entries marked / kept
	inc hl				; HL++
	ld (dir_marked_count),hl	; save as number of entries marked / kept
	ld hl,(dir_table_ptr)		; get pointer into the directory table
	ex de,hl			; swap pointers
	ld bc,0010H			; 16 bytes per entry
	ldir				; copy the block
	ld (dir_table_ptr),de		; save as pointer into the directory table
	jr dir_compact_1		; loop back to dir_compact_1
dir_compact_2:
	ld bc,0010H			; Advance past unmarked 16-byte entry
	add hl,bc			; HL += BC
	jr dir_compact_1		; loop back to dir_compact_1
dir_compact_3:
	ld bc,(dir_marked_count)	; get number of entries marked / kept
	pop af				; restore AF
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; dir_table_init: Prepare the directory table at HL: read the disk
; parameter block for the maximum number of directory entries, fill in the
; sort control block (item size 16) and reserve the pointer index; the
; 16-byte entries follow the index.
; ----------------------------------------------------------------------
dir_table_init:
	push de				; preserve DE
	push bc				; preserve BC
	ex de,hl			; swap pointers
	call get_disk_params		; read the disk parameter block
	ld hl,(dir_entries)		; get number of directory entries on the disk
	ld (sort_count),hl		; save as sort control block
	ld hl,0010H			; Entry size = 16 bytes (10h)
	ld (sort_elem_size),hl		; save as sort control block
	ld hl,0000H			; Clear callback
	ld (dir_table_ptr),hl		; save as pointer into the directory table
	ld hl,00FFH			; HL = 00FFH
	ld (sort_limit),hl		; save as sort control block
	ex de,hl			; swap pointers
	ld de,dir_table_ptr		; point DE at pointer into the directory table
	call sort_alloc_index		; build an index of N pointers, one per item
	pop bc				; restore BC
	pop de				; restore DE
	ret				; return

; ----------------------------------------------------------------------
; get_disk_params: Read the disk parameter block (BDOS 31) and keep BSH,
; BLM, EXM, the number of allocation blocks (DSM+1) and the number of
; directory entries (DRM+1).
; ----------------------------------------------------------------------
get_disk_params:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	push af				; preserve AF
	ld c,DRV_DPB			; BDOS function: DRV_DPB
	call BDOS			; DRV_DPB: get the disk parameter block address
	inc hl				; Skip DPB sectors per track (SPT)
	inc hl				; HL++
	ld de,dpb_bsh			; point DE at disk parameter block
	ldi				; Copy BSH (block shift)
	ldi				; Copy BLM (block mask)
	ldi				; copy one byte (HL)->(DE), HL++, DE++, BC--
	ld e,(hl)			; Read DSM (max allocation block number)
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	inc de				; Total blocks = DSM + 1
	ld (disk_blocks),de		; save as number of allocation blocks on the disk
	inc hl				; HL++
	ld e,(hl)			; Read DRM (max directory entry number)
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	inc de				; Total directory entries = DRM + 1
	ld (dir_entries),de		; save as number of directory entries on the disk
	pop af				; restore AF
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; dir_mark_matches: Compare every table entry with the file specification
; (name and extension, "?" matches any character) and the selection mask;
; matching entries get bit 7 of the user byte set.
; ----------------------------------------------------------------------
dir_mark_matches:
	push hl				; preserve HL
	push de				; preserve DE
	push bc				; preserve BC
	push af				; preserve AF
	ld (dir_attr_mask),a		; save as selection mask
	push bc				; preserve BC
dir_mark_1:
	pop bc				; restore BC
	ld a,b				; Any entries remaining?
	or c				; A |= C
	jr z,dir_mark_3			; If done, exit
	dec bc				; Decrement loop counter
	push bc				; preserve BC
	push hl				; preserve HL
	push de				; preserve DE
	inc hl				; Advance past user byte to filename (+1)
	inc de				; DE++
	ld b,08H			; Compare 8 filename characters
	ex de,hl			; swap pointers
	call compare_wild		; compare B bytes at HL and DE, "?" matches anything
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,dir_mark_2		; if names differ goto dir_mark_2
	push hl				; preserve HL
	push de				; preserve DE
	ld bc,FCB_EXT			; Offset to extension (+9)
	add hl,bc			; HL points to extension in table
	ex de,hl			; swap pointers
	add hl,bc			; HL points to extension in pattern
	ld b,03H			; Compare 3 extension characters
	call compare_wild		; compare B bytes at HL and DE, "?" matches anything
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,dir_mark_2		; if names differ goto dir_mark_2
	call dir_check_attr		; does the entry pass the selection mask? A DIR file
	jr nz,dir_mark_2		; if not zero goto dir_mark_2
	set 7,(hl)			; Mark entry as matched (set bit 7 of user byte)
dir_mark_2:
	ld bc,0010H			; Advance to next 16-byte table entry
	add hl,bc			; HL += BC
	jr dir_mark_1			; loop back to dir_mark_1
dir_mark_3:
	pop af				; restore AF
	pop bc				; restore BC
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; dir_check_attr: Does the entry pass the selection mask? A DIR file
; needs mask bit 7, a SYS file (bit 7 of the extension's third byte) needs
; bit 6; unless bit 5 is set the user number must also match the low bits.
; Z = accepted.
; ----------------------------------------------------------------------
dir_check_attr:
	push de				; preserve DE
	push hl				; preserve HL
	ld de,FCB_EXT+1			; DE = 000AH
	add hl,de			; HL += DE
	bit 7,(hl)			; Bit 7 set = System file ($SYS)
	pop hl				; restore HL
	pop de				; restore DE
	ld a,(dir_attr_mask)		; get selection mask
	jr z,dir_check_attr_2		; If DIR file (not SYS), branch
	bit 6,a				; test bit 6 of A
	jr nz,dir_check_attr_3		; If SYS allowed, check user area
dir_check_attr_1:
	or 0FFH				; A |= 0FFH
	ret				; return
dir_check_attr_2:
	bit 7,a				; test bit 7 of A
	jr z,dir_check_attr_1		; If DIR files excluded, reject
dir_check_attr_3:
	bit 5,a				; test bit 5 of A
	jr nz,dir_check_attr_4		; If all users allowed, accept
	xor (hl)			; Compare user area byte
	and 3FH				; Mask user area (0..31)
	jr nz,dir_check_attr_1		; if result is nonzero goto dir_check_attr_1
dir_check_attr_4:
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; sort_alloc_index: Build an index of N pointers, one per item, so the
; items can be sorted indirectly; the items start right after the index. A
; = 0 if the index does not fit below the BDOS.
; ----------------------------------------------------------------------
sort_alloc_index:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	call sort_params_save		; copy the caller's 12-byte sort control block
	pop de				; restore DE
	ld (sort_index_ptr),de		; save as pointer to the sort index array
	ld hl,(sort_blk_count)		; get ... element count
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,sort_alloc_4		; if the 16-bit count is zero goto sort_alloc_4
	ld b,h				; BC = item count N
	ld c,l				; C = L
	add hl,hl			; HL = N * 2 (size of 16-bit pointer array)
	jr c,sort_alloc_4		; Overflow check
	add hl,de			; End of pointer array
	jr c,sort_alloc_4		; Overflow check
	ex de,hl			; swap pointers
	ld hl,(BDOSVEC)			; get BDOSVEC
	sbc hl,de			; Ensure pointer array fits below BDOS top of RAM
	jr c,sort_alloc_4		; if carry goto sort_alloc_4
	ld hl,(sort_blk_base)		; get working copy of sort block
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,sort_alloc_1		; if the 16-bit count is zero goto sort_alloc_1
	ex de,hl			; swap pointers
sort_alloc_1:
	push de				; preserve DE
	ld hl,(sort_index_ptr)		; get pointer to the sort index array
sort_alloc_2:
	ld (hl),e			; Store item pointer low byte into array
	inc hl				; HL++
	ld (hl),d			; Store item pointer high byte into array
	inc hl				; HL++
	push hl				; preserve HL
	ld hl,(sort_blk_size)		; get ... element size
	add hl,de			; Advance DE to next item
	ex de,hl			; swap pointers
	pop hl				; restore HL
	dec bc				; Decrement item counter
	ld a,b				; Any items remaining?
	or c				; A |= C
	jr nz,sort_alloc_2		; Loop until all pointers stored
	pop hl				; restore HL
	ld (sort_blk_base),hl		; save as working copy of sort block
	push hl				; preserve HL
	call sort_prm_restore		; copy the working sort control block back to the caller
	pop hl				; restore HL
	dec a				; Decrement status
sort_alloc_3:
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return
sort_alloc_4:
	xor a				; Clear A (failure status)
	ld hl,(sort_index_ptr)		; get pointer to the sort index array
	jr sort_alloc_3			; loop back to sort_alloc_3

; ----------------------------------------------------------------------
; sort_entries: Sort: Shell-sort the pointer index (sort_shell), then
; rearrange the real items in place by following the permutation cycles.
; ----------------------------------------------------------------------
sort_entries:
	ex af,af'			; Preserve AF in alternate AF'
	push af				; preserve AF
	ex af,af'			; swap AF with AF'
	push hl				; preserve HL
	push de				; preserve DE
	push bc				; preserve BC
	push af				; preserve AF
	call sort_params_save		; copy the caller's 12-byte sort control block
	call sort_shell			; shell sort of the index. The gap starts at N/2 made odd
	ld a,(sort_blk_flag)		; get sort block flag
	or a				; test A (sets Z if A = 0)
	jr z,sort_entries_3		; if sort block flag is zero/clear goto sort_entries_3
	ld a,(sort_blk_flag2)		; get sort block second flag
	or a				; test A (sets Z if A = 0)
	jr nz,sort_entries_3		; if sort block second flag is set/nonzero goto sort_entries_3
	ld hl,(sort_blk_count)		; get ... element count
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,sort_entries_3		; if the 16-bit count is zero goto sort_entries_3
	ld (sort_i),hl			; save as sort loop index i
	ld hl,0000H			; Initialize item index
	ld (sort_j),hl			; save as sort loop index j
sort_entries_1:
	ld hl,(sort_i)			; get sort loop index i
	dec hl				; HL--
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,sort_entries_3		; if the 16-bit count is zero goto sort_entries_3
	ld (sort_i),hl			; save as sort loop index i
	ld hl,(sort_j)			; get sort loop index j
	inc hl				; HL++
	ld (sort_j),hl			; save as sort loop index j
	ld d,h				; DE = current item index
	ld e,l				; E = L
	call sort_index_addr		; HL = address of index entry HL
	ld a,(hl)			; Read target pointer
	inc hl				; HL++
	ld h,(hl)			; H = (HL)
	ld l,a				; HL = target item address
	ex de,hl			; swap pointers
	call sort_elem_addr		; HL = address of item number HL
	sbc hl,de			; Is item already in place?
	add hl,de			; HL += DE
	jr nc,sort_entries_1		; If already in place, continue
	push de				; preserve DE
	push hl				; preserve HL
	call sort_copy_ents		; swap the contents of two complete items
	ld hl,(sort_j)			; get sort loop index j
	call sort_index_addr		; HL = address of index entry HL
	pop de				; restore DE
	ld (hl),e			; Update pointer in table
	inc hl				; HL++
	ld (hl),d			; (HL) = D
	inc hl				; HL++
sort_entries_2:
	ld a,(hl)			; Search for next item in permutation cycle
	inc hl				; HL++
	cp e				; compare A with E
	inc hl				; HL++
	jr nz,sort_entries_2		; if not zero goto sort_entries_2
	dec hl				; HL--
	ld a,(hl)			; A = (HL)
	inc hl				; HL++
	cp d				; compare A with D
	jr nz,sort_entries_2		; if not zero goto sort_entries_2
	pop de				; restore DE
	dec hl				; HL--
	ld (hl),d			; Update permutation link
	dec hl				; HL--
	ld (hl),e			; (HL) = E
	jr sort_entries_1		; loop back to sort_entries_1
sort_entries_3:
	pop af				; restore AF
	pop bc				; restore BC
	pop de				; restore DE
	pop hl				; restore HL
	ex af,af'			; Restore AF from alternate
	pop af				; restore AF
	ex af,af'			; swap AF with AF'
	ret				; return

; ----------------------------------------------------------------------
; sort_swap: Swap items HL and DE: exchange the two index pointers when
; the sort is indirect, otherwise the whole items.
; ----------------------------------------------------------------------
sort_swap:
	push hl				; preserve HL
	push de				; preserve DE
	ld bc,1B0EH			; Push return address (tail-call exit)
	push bc				; preserve BC
	ld a,(sort_blk_flag)		; get sort block flag
	or a				; test A (sets Z if A = 0)
	jr nz,sort_copy_ents_1		; if sort block flag is set/nonzero goto sort_copy_ents_1
	call sort_elem_adr_de		; HL and DE become the addresses of items HL and DE

; ----------------------------------------------------------------------
; sort_copy_ents: Swap the contents of two complete items (item-size
; bytes each) at addresses HL and DE.
; ----------------------------------------------------------------------
sort_copy_ents:
	ld bc,(sort_blk_size)		; get ... element size
	jr sort_copy_ents_2		; continue at sort_copy_ents_2
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
sort_copy_ents_1:
	call sort_index_addr		; HL = address of index entry HL
	ex de,hl			; swap pointers
	dec hl				; Offset adjustment
	add hl,hl			; HL = (index 2 - 1) * 2
	add hl,bc			; HL = pointer 2 address in pointer table
	ld bc,0002H			; Size of 16-bit word = 2 bytes
sort_copy_ents_2:
	ld a,(de)			; Swap bytes between (DE) and (HL)
	ldi				; Copy (HL) to (DE), increment both, decrement BC
	dec hl				; Back up HL
	ld (hl),a			; Store original (DE) byte into (HL)
	inc hl				; Advance HL
	jp pe,sort_copy_ents_2		; Loop until BC reaches 0 (parity even = PE)
	ret				; return

; ----------------------------------------------------------------------
; sort_elem_adr_de: HL and DE become the addresses of items HL and DE.
; ----------------------------------------------------------------------
sort_elem_adr_de:
	call sort_elem_addr		; HL = address of item number HL
	ex de,hl			; swap pointers

; ----------------------------------------------------------------------
; sort_elem_addr: HL = address of item number HL: base + (HL - 1) * item
; size.
; ----------------------------------------------------------------------
sort_elem_addr:
	push de				; preserve DE
	dec hl				; HL = index - 1 (0-based)
	ld d,h				; DE = index - 1
	ld e,l				; E = L
	ld bc,(sort_blk_size)		; get ... element size
	ld hl,0FFE5H			; Threshold check (-27)
	add hl,bc			; HL += BC
	ld hl,0000H			; Initialize product = 0
	jr nc,sort_elem_addr_4		; If small size, use shift/add multiply
	ld a,10H			; 16-bit shift/add loop counter
sort_elem_addr_1:
	add hl,hl			; Shift product left
	ex de,hl			; swap pointers
	add hl,hl			; Shift multiplier left
	ex de,hl			; swap pointers
	jr nc,sort_elem_addr_2		; If bit not set, skip add
	add hl,bc			; Add multiplicand to product
sort_elem_addr_2:
	dec a				; Decrement bit counter
	jr nz,sort_elem_addr_1		; Loop for all 16 bits
	jr sort_elem_addr_5		; continue at sort_elem_addr_5
sort_elem_addr_3:
	dec bc				; Decrement multiplicand
	add hl,de			; Repeated addition multiply
sort_elem_addr_4:
	ld a,b				; Multiplicand reaches 0?
	or c				; A |= C
	jr nz,sort_elem_addr_3		; Loop until multiplied
sort_elem_addr_5:
	ld de,(sort_blk_base)		; get working copy of sort block
	add hl,de			; HL = base + (index - 1) * size
	pop de				; restore DE
	ret				; return

; ----------------------------------------------------------------------
; sort_compare: Call the caller's compare routine with HL and DE = the two
; items (found through the index when sorting indirectly); its flags are
; returned.
; ----------------------------------------------------------------------
sort_compare:
	push hl				; preserve HL
	push de				; preserve DE
	ld bc,1B0EH			; Tail-call cleanup on stack
	push bc				; preserve BC
	ld a,(sort_blk_flag)		; get sort block flag
	or a				; test A (sets Z if A = 0)
	jr nz,sort_compare_1		; if sort block flag is set/nonzero goto sort_compare_1
	call sort_elem_adr_de		; HL and DE become the addresses of items HL and DE
	jr sort_compare_2		; continue at sort_compare_2
sort_compare_1:
	call sort_index_addr		; HL = address of index entry HL
	ex de,hl			; swap pointers
	dec hl				; Offset adjustment
	add hl,hl			; (index 2 - 1) * 2
	add hl,bc			; HL = pointer 2 address in pointer table
	ld c,(hl)			; BC = target pointer 2
	inc hl				; HL++
	ld b,(hl)			; B = (HL)
	ex de,hl			; swap pointers
	ld e,(hl)			; DE = target pointer 1
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	ld h,b				; HL = target pointer 2
	ld l,c				; L = C
sort_compare_2:
	push hl				; preserve HL
	ld hl,(sort_blk_cmp)		; get ... compare function
	ex (sp),hl			; Push callback and restore HL = item 2 address
	ret				; return

; ----------------------------------------------------------------------
; sort_index_addr: HL = address of index entry HL: sort_index_ptr + (HL -
; 1) * 2.
; ----------------------------------------------------------------------
sort_index_addr:
	dec hl				; HL = index - 1
	add hl,hl			; HL = (index - 1) * 2
	ld bc,(sort_index_ptr)		; get pointer to the sort index array
	add hl,bc			; HL = pointer table address
	ret				; return

; ----------------------------------------------------------------------
; sort_params_save: Copy the caller's 12-byte sort control block (base,
; count, item size, compare routine, flags) into the working copy.
; ----------------------------------------------------------------------
sort_params_save:
	ex de,hl			; swap pointers
	ld (sort_blk_ptr),hl		; save as pointer to the caller's sort control block
	ld de,sort_blk_base		; point DE at working copy of sort block
sort_params_1:
	ld bc,000CH			; 12 bytes
	ldir				; copy the block
	ret				; return

; ----------------------------------------------------------------------
; sort_prm_restore: Copy the working sort control block back to the
; caller.
; ----------------------------------------------------------------------
sort_prm_restore:
	ld hl,sort_blk_base		; point HL at working copy of sort block
	ld de,(sort_blk_ptr)		; get pointer to the caller's sort control block
	jr sort_params_1		; loop back to sort_params_1

; ----------------------------------------------------------------------
; sort_shell: Shell sort of the index. The gap starts at N/2 made odd and
; is halved each pass; items are compared with the sort callback and
; swapped with sort_swap.
; ----------------------------------------------------------------------
sort_shell:
	ld hl,(sort_blk_count)		; get ... element count
	ld (sort_j),hl			; save as sort loop index j
sort_shell_1:
	ld hl,(sort_j)			; get sort loop index j
	srl h				; Shift right 1 bit
	rr l				; rotate right through carry L
	ld a,l				; Is gap == 0?
	or h				; A |= H
	ret z				; If gap == 0, sort is complete!
	bit 0,l				; Is gap odd?
	jr nz,sort_shell_2		; If odd, keep it
	dec hl				; If even, decrement to make odd (classic Shell sort optimization)
sort_shell_2:
	ld (sort_j),hl			; save as sort loop index j
	ld (sort_i),hl			; save as sort loop index i
sort_shell_3:
	ld hl,(sort_i)			; get sort loop index i
	inc hl				; HL++
	ld (sort_i),hl			; save as sort loop index i
	ex de,hl			; swap pointers
	ld hl,(sort_blk_count)		; get ... element count
	or a				; Clear Carry
	sbc hl,de			; Count - index
	jr c,sort_shell_1		; If index > count, reduce gap
sort_shell_4:
	ld hl,(sort_j)			; get sort loop index j
	ex de,hl			; swap pointers
	sbc hl,de			; Inner index -= gap
	jr c,sort_shell_3		; If below start, advance outer index
	jr z,sort_shell_3		; if zero goto sort_shell_3
	ex de,hl			; swap pointers
	add hl,de			; HL = inner index + gap
	call sort_compare		; call the caller's compare routine with HL and DE = the
	jr nc,sort_shell_3		; If in order, advance outer index
	call sort_swap			; swap items HL and DE
	jr sort_shell_4			; loop back to sort_shell_4

; ----------------------------------------------------------------------
; file_open_input: Open the file named at DE for reading.
; ----------------------------------------------------------------------
file_open_input:
	push hl				; preserve HL
	call sel_in_handle		; select the input file control block
	call file_oprd_impl		; open the file of the file object at HL for reading: an
	pop hl				; restore HL
	ret nz				; Return error if read failed
	cpl				; Invert status byte
	ld (in_file_active),a		; save as flag byte
	cpl				; Restore original A (0)
	ret				; return
	push hl				; preserve HL
	call sel_out_handle		; select the output file control block
	call file_opwr_impl		; create
	pop hl				; restore HL
	ret nz				; Return error if read failed
	cpl				; Invert status byte
	ld (out_file_active),a		; save as flag byte
	cpl				; Restore original A (0)
	ret				; return

; ----------------------------------------------------------------------
; file_getc: Read the next byte from the input file (A, Z/NZ status).
; ----------------------------------------------------------------------
file_getc:
	push hl				; preserve HL
	call sel_in_handle		; select the input file control block
	jp file_getc_impl		; continue at file_getc_impl
	push hl				; preserve HL
	push af				; preserve AF
	call sel_out_handle		; select the output file control block
	pop af				; restore AF
	jp file_putc_impl		; continue at file_putc_impl

; ----------------------------------------------------------------------
; file_close_input: Close the input file.
; ----------------------------------------------------------------------
file_close_input:
	push hl				; preserve HL
	call sel_in_handle		; select the input file control block
	call nz,file_clsrd_impl		; If previously open, close and reopen
	pop hl				; restore HL
	ret nz				; Return error if open failed
	ld (in_file_active),a		; save as flag byte
	ret				; return
	push hl				; preserve HL
	call sel_out_handle		; select the output file control block
	call nz,file_clswr_impl		; If previously open, flush and reopen
	pop hl				; restore HL
	ret nz				; Return error if open failed
	ld (out_file_active),a		; save as flag byte
	ret				; return

; ----------------------------------------------------------------------
; sel_in_handle: Select the input file control block.
; ----------------------------------------------------------------------
sel_in_handle:
	ld hl,in_file			; point HL at input file object
	ld a,(in_file_active)		; get flag byte
	ld (hl),a			; store into input file object
	or a				; Test sector count
	ret				; return

; ----------------------------------------------------------------------
; sel_out_handle: Select the output file control block.
; ----------------------------------------------------------------------
sel_out_handle:
	ld hl,out_file			; point HL at output file object
	ld a,(out_file_active)		; get flag byte
	ld (hl),a			; store into output file object
	or a				; Test sector count
	ret				; return
; Flag byte: input file object in use
in_file_active:
	.db 00H
; Flag byte: output file object in use
out_file_active:
	.db 00H

; ----------------------------------------------------------------------
; file_oprd_impl: Open the file of the file object at HL for reading:
; an already open object is closed first, the first 128-byte sector is
; read. A = error code on failure (3 open failed, 4 read failed, 7 already
; open).
; ----------------------------------------------------------------------
file_oprd_impl:
	push bc				; preserve BC
	push de				; preserve DE
	ld a,(hl)			; A = (HL)
	or a				; test A (sets Z if A = 0)
	ld a,07H			; Error code 7 (already open)
	jr nz,file_oprd_impl_2		; if result is nonzero goto file_oprd_impl_2
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	push hl				; preserve HL
	ld bc,FCB_SIZE			; BC = 0024H
	ex de,hl			; swap pointers
	ldir				; copy the block
	pop de				; restore DE
	call fcb_clear_tail		; clear the extent/record part of the FCB
	call fcb_open			; open the file
	ld a,03H			; Error code 3 (open failed)
	jr nz,file_oprd_impl_2		; if open failed goto file_oprd_impl_2
	call file_read_sector		; read the next 128-byte record of the current file
	ld a,04H			; Error code 4 (read failed)
	jr nz,file_oprd_impl_2		; If read failed, exit
file_oprd_impl_1:
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	ld (hl),0FFH			; Mark buffer as active/open
	inc hl				; HL++
	ld (hl),80H			; Initialize buffer pointer index (128 bytes)
	inc hl				; HL++
	ex de,hl			; swap pointers
	ld hl,CIO_BUF_OFF		; HL = 0026H
	add hl,de			; HL points to sector data buffer
	ex de,hl			; swap pointers
	ld (hl),e			; Store data pointer low byte
	inc hl				; HL++
	ld (hl),d			; Store data pointer high byte
	xor a				; Return success (A = 0)
file_oprd_impl_2:
	jp file_clswr_3			; continue at file_clswr_3

; ----------------------------------------------------------------------
; file_opwr_impl: Create (BDOS F_MAKE) the file of the file object
; at HL for writing and give it an empty buffer. Error 5 = create failed.
; ----------------------------------------------------------------------
file_opwr_impl:
	push bc				; preserve BC
	push de				; preserve DE
	ld a,(hl)			; A = (HL)
	or a				; test A (sets Z if A = 0)
	ld a,07H			; Error code 7 (already open)
	jr nz,file_oprd_impl_2		; if result is nonzero goto file_oprd_impl_2
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	push hl				; preserve HL
	ld bc,FCB_SIZE			; BC = 0024H
	ex de,hl			; swap pointers
	ldir				; copy the block
	pop de				; restore DE
	call fcb_clear_tail		; clear the extent/record part of the FCB
	call fcb_open_or_make		; open the file, or create it if it does not exist
	jr z,file_oprd_impl_1		; if file ready goto file_oprd_impl_1
	ld a,05H			; Error code 5 (create failed)
	jr file_oprd_impl_2		; loop back to file_oprd_impl_2

; ----------------------------------------------------------------------
; file_getc_impl: Return the next byte of an input file object (byte in A
; and in file_io_char, Z). The 128-byte buffer is refilled from disk when
; it runs out. Errors in A: 1 object not open, 4 end of file / read error.
; ----------------------------------------------------------------------
file_getc_impl:
	push bc				; preserve BC
	push de				; preserve DE
	ld a,(hl)			; Check if file is open
	or a				; test A (sets Z if A = 0)
	ld a,01H			; Error 1 (file not open)
	jr z,file_putc_impl_1		; if result is zero goto file_putc_impl_1
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; Advance to buffer data pointer (+2)
	inc hl				; HL++
	ld e,(hl)			; DE = current buffer data pointer
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	ld a,d				; Pointer null?
	or e				; A |= E
	ld a,04H			; Error 4 (buffer empty / EOF)
	jr z,file_putc_impl_1		; Exit if null
	ld a,(de)			; Fetch byte from buffer
	ld (file_io_char),a		; save as character passed through file get/put
	inc de				; Advance buffer pointer
	ld (hl),d			; Save updated pointer
	dec hl				; HL--
	ld (hl),e			; (HL) = E
	dec hl				; Point to remaining byte counter
	dec (hl)			; Decrement byte counter
	jr nz,file_getc_impl_1		; If bytes remain, return saved byte
	ld (hl),80H			; Reset sector byte counter = 128
	inc hl				; HL++
	ex de,hl			; swap pointers
	ld hl,CIO_BUF_OFF		; HL = 0026H
	add hl,de			; HL += DE
	ex de,hl			; swap pointers
	ld (hl),e			; (HL) = E
	inc hl				; HL++
	ld (hl),d			; (HL) = D
	call file_read_sector		; read the next 128-byte record of the current file
	jr z,file_getc_impl_1		; If refilled successfully, continue
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	inc hl				; HL++
	inc hl				; HL++
	ld (hl),00H			; (HL) = 00H
	inc hl				; HL++
	ld (hl),00H			; (HL) = 00H
file_getc_impl_1:
	ld a,(file_io_char)		; get character passed through file get/put
	cp a				; compare A with A
	jr file_putc_impl_2		; continue at file_putc_impl_2

; ----------------------------------------------------------------------
; file_putc_a: Put byte A to the output file.
; ----------------------------------------------------------------------
file_putc_a:
	push hl				; preserve HL
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on

; ----------------------------------------------------------------------
; file_putc_impl: Append byte A to an output file object; a full 128-byte
; buffer is written to disk. Error 2 = write error (disk full).
; ----------------------------------------------------------------------
file_putc_impl:
	push bc				; preserve BC
	push de				; preserve DE
	ld (file_io_char),a		; save as character passed through file get/put
	ld a,(hl)			; Check if file is open
	or a				; test A (sets Z if A = 0)
	ld a,01H			; Error 1 (file not open)
	jr z,file_putc_impl_1		; if result is zero goto file_putc_impl_1
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; Advance to buffer data pointer (+2)
	inc hl				; HL++
	ld e,(hl)			; DE = current buffer write pointer
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	ld a,(file_io_char)		; get character passed through file get/put
	ld (de),a			; Write byte into buffer
	inc de				; Advance buffer pointer
	ld (hl),d			; Save updated write pointer
	dec hl				; HL--
	ld (hl),e			; (HL) = E
	dec hl				; Point to sector byte counter
	dec (hl)			; Decrement remaining bytes in sector
	jr nz,file_getc_impl_1		; If sector not full, return success
	ld (hl),80H			; Reset sector byte counter = 128
	inc hl				; HL++
	ex de,hl			; swap pointers
	ld hl,CIO_BUF_OFF		; HL = 0026H
	add hl,de			; HL += DE
	ex de,hl			; swap pointers
	ld (hl),e			; (HL) = E
	inc hl				; HL++
	ld (hl),d			; (HL) = D
	call file_wr_sector		; write the buffer out as a sector
	jr z,file_getc_impl_1		; If written successfully, continue
	ld a,02H			; Error 2 (write error / disk full)
file_putc_impl_1:
	or a				; test A (sets Z if A = 0)
file_putc_impl_2:
	pop de				; restore DE
	pop bc				; restore BC
	pop hl				; restore HL
	ret				; return

; ----------------------------------------------------------------------
; file_clsrd_impl: Close the input file object and mark it unused
; (error 6 = close failed).
; ----------------------------------------------------------------------
file_clsrd_impl:
	push bc				; preserve BC
	push de				; preserve DE
	ld a,(hl)			; Check if file is open
	or a				; test A (sets Z if A = 0)
	jr z,file_clswr_3		; if result is zero goto file_clswr_3
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	jr file_clswr_2			; continue at file_clswr_2

; ----------------------------------------------------------------------
; file_clswr_impl: Finish an output file object: pad the last sector
; with ^Z (1AH) and zeros, write it, close the file and mark the object
; unused.
; ----------------------------------------------------------------------
file_clswr_impl:
	push bc				; preserve BC
	push de				; preserve DE
	ld a,(hl)			; Check if file is open
	or a				; test A (sets Z if A = 0)
	jr z,file_clswr_3		; if result is zero goto file_clswr_3
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; Check sector byte count
	ld a,(hl)			; A = (HL)
	cp 80H				; Is sector buffer empty (count == 128)?
	jr z,file_clswr_2		; if A = 80H goto file_clswr_2
	ld a,1AH			; Pad with CP/M EOF character (Ctrl-Z = 1Ah)
	call file_putc_a		; put byte A to the output file
file_clswr_1:
	ld a,(hl)			; Check sector byte count
	cp 80H				; Reached sector boundary?
	jr z,file_clswr_2		; if A = 80H goto file_clswr_2
	xor a				; Pad remainder of sector with 00h
	call file_putc_a		; put byte A to the output file
	jr file_clswr_1			; loop back to file_clswr_1
file_clswr_2:
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	ld (hl),00H			; Mark buffer as closed
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	ex de,hl			; swap pointers
	call fcb_close			; close the file
	ld a,06H			; Error code 6 (close failed)
	jr nz,file_clswr_3		; if close failed goto file_clswr_3
	xor a				; Return success (A = 0)
file_clswr_3:
	pop de				; restore DE
	pop bc				; restore BC
	or a				; Set flags based on status code
	ret				; return

; ----------------------------------------------------------------------
; file_read_sector: Read the next 128-byte record of the current file
; object into its buffer (BDOS F_READ); Z = success.
; ----------------------------------------------------------------------
file_read_sector:
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	ld de,CIO_BUF			; Offset to sector data buffer (+40)
	add hl,de			; HL points to sector DMA buffer
	call set_dma			; set the DMA address to DE
	ld de,(cur_file_ptr)		; get pointer to the file object being operated on
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	call fcb_read_sector		; read a sector
	jr file_wr_sector_1		; continue at file_wr_sector_1

; ----------------------------------------------------------------------
; file_wr_sector: Write the buffer out as a sector.
; ----------------------------------------------------------------------
file_wr_sector:
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	ld de,CIO_BUF			; Offset to sector data buffer (+40)
	add hl,de			; HL points to sector DMA buffer
	call set_dma			; set the DMA address to DE
	ld de,(cur_file_ptr)		; get pointer to the file object being operated on
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	call fcb_write_sector		; write a sector
file_wr_sector_1:
	push af				; preserve AF
	ld hl,0080H			; Restore default DMA buffer address (0080h)
	call set_dma			; set the DMA address to DE
	pop af				; restore AF
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
; get_file_size: Get the file size (BDOS F_SIZE).
; ----------------------------------------------------------------------
get_file_size:
	ld a,F_SIZE			; BDOS function 35 (F_SIZE): compute the file size in records
	jr get_rand_1			; continue at get_rand_1

; ----------------------------------------------------------------------
; get_rand_record: Get the random record number (BDOS F_RANDREC).
; ----------------------------------------------------------------------
get_rand_record:
	ld a,F_RANDREC			; BDOS function 36 (F_RANDREC): set the random record number from the sequential
					; position
get_rand_1:
	push de				; preserve DE
	push bc				; preserve BC
	push af				; preserve AF
	ld hl,fcb_copy			; point HL at scratch copy of a 36-byte FCB
	ld bc,FCB_SIZE			; BC = 0024H
	push hl				; preserve HL
	ex de,hl			; swap pointers
	ldir				; copy the block
	pop de				; restore DE
	pop af				; restore AF
	call bdos_call_a		; BDOS call with function number in A, preserving BC, DE
	ld hl,FCB_R0			; Offset 33 (21h) = random record field (R0, R1)
	add hl,de			; HL points to random record count in FCB
	ld e,(hl)			; E = low byte of record count
	inc hl				; HL++
	ld d,(hl)			; D = high byte of record count
	inc hl				; HL++
	ld a,(hl)			; A = overflow byte (R2)
	ex de,hl			; swap pointers
	pop bc				; restore BC
	pop de				; restore DE
	or a				; Set flags
	ret				; return

; ----------------------------------------------------------------------
; fcb_open_or_make: Open the file, or create it if it does not exist.
; ----------------------------------------------------------------------
fcb_open_or_make:
	call fcb_open			; open the file
	ret z				; return: open succeeded
	ld a,F_MAKE			; BDOS Function 22: Make File (F_MAKE)
	jp fcb_bdos_check		; continue at fcb_bdos_check

; ----------------------------------------------------------------------
; fcb_close: Close the file (BDOS F_CLOSE).
; ----------------------------------------------------------------------
fcb_close:
	ld a,F_CLOSE			; BDOS Function 16: Close File (F_CLOSE)
	jp fcb_bdos_check		; continue at fcb_bdos_check

; ----------------------------------------------------------------------
; fcb_open: Open the file (BDOS F_OPEN).
; ----------------------------------------------------------------------
fcb_open:
	ld a,F_OPEN			; BDOS Function 15: Open File (F_OPEN)

; ----------------------------------------------------------------------
; fcb_bdos_check: BDOS call with FCB; Z on success.
; ----------------------------------------------------------------------
fcb_bdos_check:
	call bdos_call_a		; BDOS call with function number in A, preserving BC, DE
	ret m				; Return negative (0FFh) on error
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; fcb_read_sector: Read a sector (BDOS F_READ).
; ----------------------------------------------------------------------
fcb_read_sector:
	ld a,F_READ			; BDOS Function 20: Read Sequential (F_READ)
	jp bdos_call_a			; continue at bdos_call_a

; ----------------------------------------------------------------------
; fcb_write_sector: Write a sector (BDOS F_WRITE).
; ----------------------------------------------------------------------
fcb_write_sector:
	ld a,F_WRITE			; BDOS Function 21: Write Sequential (F_WRITE)
	jp bdos_call_a			; continue at bdos_call_a

; ----------------------------------------------------------------------
; set_dma: Set the DMA address to DE (BDOS F_DMAOFF).
; ----------------------------------------------------------------------
set_dma:
	push af				; preserve AF
	ld a,F_DMAOFF			; BDOS Function 26: Set DMA Address (F_DMAOFF)
	ex de,hl			; swap pointers
	call bdos_call_a		; BDOS call with function number in A, preserving BC, DE
	ex de,hl			; swap pointers
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; fcb_clear_tail: Clear the extent/record part of the FCB.
; ----------------------------------------------------------------------
fcb_clear_tail:
	push hl				; preserve HL
	push de				; preserve DE
	push af				; preserve AF
	ex de,hl			; swap pointers
	ld de,FCB_EX			; DE = 000CH
	ld (hl),d			; Clear byte 0 (drive)
	add hl,de			; HL points to byte 12 (EX)
	ld e,15H			; Clear 21 bytes (12..32)
fcb_clear_tail_1:
	ld (hl),d			; Zero byte (D = 0)
	inc hl				; Advance pointer
	dec e				; Decrement loop counter
	jr nz,fcb_clear_tail_1		; Loop until all 21 bytes cleared
	pop af				; restore AF
	pop de				; restore DE
	pop hl				; restore HL
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
	push bc				; preserve BC
	ld b,0FFH			; B = 0FFH
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
	push af				; preserve AF

; ----------------------------------------------------------------------
; skip_blanks_str: Skip blank characters in the string at HL.
; ----------------------------------------------------------------------
skip_blanks_str:
	ld a,(hl)			; Fetch character
	inc hl				; Advance pointer
	or a				; Null terminator?
	jr z,skip_blanks_1		; if result is zero goto skip_blanks_1
	call is_space			; Z if A is a blank/control separator
	jr z,skip_blanks_str		; if character is blank/whitespace goto skip_blanks_str
skip_blanks_1:
	dec hl				; Point back to terminator
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; skip_to_blank: Advance HL to the next blank.
; ----------------------------------------------------------------------
skip_to_blank:
	push af				; preserve AF
skip_to_blank_1:
	ld a,(hl)			; Fetch character
	inc hl				; Advance pointer
	or a				; Null terminator?
	jr z,skip_blanks_1		; if result is zero goto skip_blanks_1
	call is_space			; Z if A is a blank/control separator
	jr nz,skip_to_blank_1		; If printable, continue
	jr skip_blanks_1		; loop back to skip_blanks_1

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
; is_alpha: Z if A is an upper-case letter (after case conversion).
; ----------------------------------------------------------------------
is_alpha:
	push bc				; preserve BC
	ld c,a				; Save original character in C
	and 7FH				; strip the parity bit (7-bit ASCII)
	call to_upper			; convert A to upper case
	cp 41H				; compare A with 41H ('A')
	jr c,is_alpha_1			; if A < 41H goto is_alpha_1
	cp 5BH				; compare A with 5BH
	jr c,is_alpha_2			; if A < 5BH goto is_alpha_2
is_alpha_1:
	or 0AFH				; A |= 0AFH
is_alpha_2		.equ is_alpha_1+1	; alternate entry point inside the instruction above (overlapping decode: xor
					; a)
	ld a,c				; Restore original character in A
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; is_space: Z if A is a blank/control separator.
; ----------------------------------------------------------------------
is_space:
	push af				; preserve AF
	and 7FH				; strip the parity bit (7-bit ASCII)
	jr z,is_space_1			; if result is zero goto is_space_1
	cp 7FH				; DEL (rubout)?
	jr z,is_space_1			; if A = 7FH goto is_space_1
	cp 20H				; Space?
	jr z,is_space_1			; if A = 20H goto is_space_1
	cp 08H				; Backspace or lower?
	jr c,is_space_2			; if A < 08H goto is_space_2
	cp 0EH				; Tab, LF, VT, FF, CR (8..13)?
	jr nc,is_space_2		; if A >= 0EH goto is_space_2
is_space_1:
	pop af				; restore AF
	cp a				; compare A with A
	ret				; return
is_space_2:
	pop af				; restore AF
	or a				; test A (sets Z if A = 0)
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
; get_tpa_top: Compute the top of the TPA.
; ----------------------------------------------------------------------
get_tpa_top:
	ld hl,(BDOSVEC)			; get BDOSVEC
	ld l,00H			; Page-align to 256-byte boundary
	ld a,(0002H)			; get 0002H
	sub 16H				; Safety margin below BIOS
	cp h				; Compare against BDOS page
	ret nc				; If BDOS page is lower, use BDOS page
	ld h,a				; Otherwise use BIOS margin page
	ret				; return

; ----------------------------------------------------------------------
; compare_wild: Compare B bytes at HL and DE, "?" matches anything.
; ----------------------------------------------------------------------
compare_wild:
	ld a,(hl)			; Fetch pattern character
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 3FH				; compare A with 3FH
	jr z,compare_wild_1		; if A = 3FH goto compare_wild_1
	ld c,a				; C = pattern character
	ld a,(de)			; Fetch target character
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp c				; Compare characters
	ret nz				; return if not zero
compare_wild_1:
	inc hl				; Advance pattern pointer
	inc de				; Advance target pointer
	djnz compare_wild		; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; compare_mem: Compare B bytes at HL and DE (7-bit).
; ----------------------------------------------------------------------
compare_mem:
	ld a,(hl)			; Fetch byte from first string
	and 7FH				; strip the parity bit (7-bit ASCII)
	ld c,a				; C = first character
	ld a,(de)			; Fetch byte from second string
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp c				; Compare characters
	ret nz				; Return mismatch (NZ)
	inc hl				; Advance first pointer
	inc de				; Advance second pointer
	djnz compare_mem		; repeat until all B items are done
	ret				; return

; Address of arg_table, the start of the free memory (initialised in the image)
arg_table_ptr:
	.dw arg_table

; ---- Uninitialised RAM work area above the program image ----
; .ds only reserves space: nothing here is stored in the .COM file.
			.ds 128+6	; not referenced by the code
default_user		.ds 1		; User number at program start
default_drive		.ds 1		; Drive (1 = A:) at program start
saved_user		.ds 1		; User number to select (pair with work_fcb drive byte)
work_fcb		.ds 33		; Work FCB / DU pair for the command line file spec (FCB offsets 0-32)
work_fcb_r0		.ds 3		; Random record number r0-r2 of work_fcb (FCB offsets 33-35)
stack			.ds 64		; Stack: grows down from stack_top
; Initial stack pointer: the stack grows down from here (same address as aux_ring)
stack_top:
aux_ring		.ds 6		; AUX receive ring buffer control block: count, write index, read index; 512 data
					; bytes follow
aux_ring_data		.ds 512		; Data area of the AUX receive ring (512 bytes)
entry_user		.ds 1		; User number of the current file list entry
send_fcb		.ds 36		; FCB of the file being sent
send_fcb_name		.equ send_fcb+1	; Name field of send_fcb
			.ds 1		; not referenced by the code
ltoa_value		.ds 4		; ltoa32: working copy of the value being converted
ltoa_temp		.ds 4		; ltoa32: temporary subtraction result
crc32_value		.ds 4		; Running CRC-32 accumulator (4 bytes)
crc32_table		.ds 1024	; CRC-32 lookup table, 256 x 4 bytes
error_count		.ds 1		; Consecutive error/retry counter
rx_header_data		.ds 4		; Four argument bytes of the last received header
pos_display		.ds 4		; Copy of the file position shown on the console
rx_crc_mode		.ds 1		; CRC type of the last received header (10H = CRC-16, 20H = CRC-32)
tx_crc_mode		.ds 1		; CRC type used for sending: 20H = CRC-32, 10H = CRC-16 (XMODEM CRC)
tx_header_data		.ds 4		; Four argument bytes for the next header to send
xm_first_flag		.ds 1		; FFH until the first block has been acknowledged
zack_pos		.ds 4		; Position from the last ZACK
rx_pos_arg		.ds 4		; Position argument of the last ZRPOS/ZACK from the receiver
tx_position		.ds 4		; Position in the file of the next byte to send (32 bits)
last_sync_pos		.ds 4		; Position at the last synchronisation point (ZCRCW)
last_zrpos_pos		.ds 4		; Position of the last ZRPOS request
file_read_pos		.ds 4		; Position of the next byte to be read from the disk file
pos_scratch		.ds 4		; Scratch 32-bit result for position arithmetic
rx_window_size		.ds 2		; Receiver buffer length from ZRINIT ZP0/ZP1 (0 = nonstop I/O) [Rxbuflen]
window_remaining	.ds 2		; Bytes left before the receiver must acknowledge
subpacket_size		.ds 2		; Current data subpacket size (starts at 1024, reduced after errors)
			.ds 2		; not referenced by the code
same_zrpos_count	.ds 1		; Number of times in a row ZRPOS asked for the same position
zrinit_zf0		.ds 1		; ZF0 from the receiver's ZRINIT: CANFDX 1, CANOVIO 2, CANBRK 4, CANCRY 8,
					; CANFC32 20H, ESCCTL 40H
escape_ctl_flag		.ds 1		; Nonzero (40H) if all control characters must be escaped
eof_pending		.ds 1		; FFH when the end of the file has been read into the buffer
eof_flag		.ds 1		; FFH when the disk file is at end of file
subpkt_term		.ds 1		; Terminator for the next data subpacket (68H ZCRCE, 69H ZCRCG, 6BH ZCRCW)
files_sent_count	.ds 1		; Number of files sent so far
buffer_mask		.ds 2		; File buffer size mask (power of two minus one)
buffer_start_pos	.ds 4		; File position corresponding to the start of the ring buffer
last_rx_char		.ds 1		; Last character received from the modem
xmodem_block_no		.ds 1		; Current XMODEM block number
prev_rx_char		.ds 1		; Previous received character
file_size		.ds 2		; Low word of the 32-bit size of the current file in bytes
file_size_hi		.ds 2		; High word of file_size (the 32-bit size is built in two halves)
block_len		.ds 2		; Length of the current block / subpacket
			.ds 2		; not referenced by the code
opt_protect_flag	.ds 1		; FFH if -p (protect) was given
opt_append_flag		.ds 1		; FFH if -a (append) was given
opt_convert_flag	.ds 1		; FFH if -c (convert to local line feeds) was given
opt_binary_flag		.ds 1		; FFH if -b (binary) was given
file_buffer_base	.ds 2		; Start of the file data ring buffer
file_buffer_base_hi	.ds 2		; High word of file_buffer_base: cleared at startup, never read
file_buffer_size	.ds 2		; Size of the file data ring buffer
file_buffer_size_hi	.ds 2		; High word of file_buffer_size: cleared at startup, never read
file_count		.ds 1		; Number of files in the list to send
zrqinit_retries		.ds 1		; Remaining attempts to get ZRINIT
resp_junk_count		.ds 1		; Garbage characters seen while streaming
zrpos_target		.ds 4		; Position requested by ZRPOS
reposition_temp		.ds 4		; Temporary position used while repositioning the file
chunk_len		.ds 4		; Number of bytes in the current chunk
data_terminator		.ds 1		; Terminator byte of the data subpacket being sent
tx_frame_type		.ds 1		; Frame type of the header being sent
hdr_junk_limit		.ds 2		; get_header: remaining number of junk characters tolerated
hdr_can_count		.ds 1		; get_header: remaining CAN characters before abort
rx_frame_type		.ds 1		; Frame type of the last header received
parse_mode		.ds 1		; parse_filespec argument (nonzero: try DU form / named directory)
parse_next_char		.ds 1		; Character following the parsed name
wildcard_count		.ds 1		; Number of wildcard characters in the file name
parsed_drive		.ds 1		; Drive from the file spec (0 = default)
parsed_user		.ds 1		; User number from the file spec
z3env_ptr		.ds 2		; Address of the ZCPR3 environment descriptor (0 if none)
sort_key_flag		.ds 1		; Sort key: 0 = name then extension, 1 = extension first
dir_search_fcb		.ds 36		; Wildcard FCB used for BDOS search first/next
dir_dup_mode		.ds 1		; File seen in several extents: 0 = keep the highest extent, nonzero = keep the
					; lowest
dir_table_start		.ds 2		; Start of the directory entry table (16 bytes per entry)
dir_entry_count		.ds 2		; Number of directory entries collected
dir_marked_count	.ds 2		; Number of entries marked / kept
dir_table_ptr		.ds 2		; Pointer into the directory table (also sort block base)
sort_count		.ds 2		; Sort control block: element count
sort_elem_size		.ds 2		; Sort control block: element size (16)
sort_compare_fn		.ds 2		; Sort control block: compare routine address
sort_aux		.ds 2		; Sort control block: auxiliary pointer
sort_limit		.ds 2		; Sort control block: limit (00FFH)
dpb_bsh			.ds 3		; Disk parameter block: BSH, BLM, EXM
disk_blocks		.ds 2		; Number of allocation blocks on the disk
dir_entries		.ds 2		; Number of directory entries on the disk
dir_attr_mask		.ds 1		; Selection mask: bit 7 include DIR files, bit 6 include SYS files, bit 5 any
					; user number, bits 0-4 user number
sort_blk_ptr		.ds 2		; Pointer to the caller's sort control block
sort_blk_base		.ds 2		; Working copy of sort block: base address
sort_blk_count		.ds 2		; ... element count
sort_blk_size		.ds 2		; ... element size
sort_blk_cmp		.ds 2		; ... compare function
sort_index_ptr		.ds 2		; Pointer to the sort index array
sort_blk_flag		.ds 1		; Sort block flag (indirect elements)
sort_blk_flag2		.ds 1		; Sort block second flag
sort_i			.ds 2		; Sort loop index i
sort_j			.ds 2		; Sort loop index j
in_file			.ds CIO_SIZE	; Input file object: open flag, count, pointer, 36-byte FCB, 128-byte buffer (168
					; bytes)
out_file		.ds CIO_SIZE	; Output file object (same layout as in_file)
cur_file_ptr		.ds 2		; Pointer to the file object being operated on
file_io_char		.ds 1		; Character passed through file get/put
fcb_copy		.ds 36		; Scratch copy of a 36-byte FCB
arg_table		.ds 6		; Argument pointers table built by tokenize_args: maximum count, count found, two
					; token pointers; the file list starts here and overwrites it later
	.end
