; SZ.COM  --  X/Y/ZMODEM send program for CP/M 3 (sz v1.11, W. Schmitten 1992)
; SZ.COM v1.11
; Disassembly of the CP/M 3 ZMODEM/YMODEM/XMODEM program (Z80). Reassembles byte-identical to the original .COM.
; Source is in TASM syntax (dotted directives); assembled and verified with uz80as.
; Modem is on the CP/M AUX device (BDOS 3/4/7/8). Option letters: ? P A B C X Y Z (A = append).
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
	ld sp,aux_ring			; the stack grows down from the work area
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
	ld hl,(argv_ptr)		; argument table in free memory
	ld (hl),02H			; at most two arguments
	ld de,0082H			; DE -> command tail text
	ex de,hl			; swap pointers
	ld a,0FFH			; terminate each argument with a zero
	call tokenize_args		; split the command tail
	ld hl,(argv_ptr)		; get pointer to the argument table built by tokenize_args
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
	jr nz,L0157			; no: it is the file specification
	call parse_options		; yes: process the option letters
	ld e,(hl)			; DE -> second argument (the file specification)
	inc hl				; HL++
	ld d,(hl)			; DE = pointer to filename argument string
L0157:
	ld a,d				; no file specification?
	or e				; Was a target filespec supplied?
	jr z,L0196			; none
	ld hl,work_fcb			; point HL at work FCB / DU pair for the command line file spec
	ex de,hl			; swap pointers
	call parse_filespec		; parse [du:]filename (wildcards allowed)
	ld hl,work_fcb			; point HL at work FCB / DU pair for the command line file spec
	xor a				; no drive given?
	or (hl)				; Did filespec specify an explicit drive?
	jr nz,L016D			; if result is nonzero goto L016D
	ld a,(default_drive)		; use the current drive
	ld (hl),a			; store into work FCB / DU pair for the command line file spec
L016D:
	ld (entry_drive),a		; drive for the file list entries
	ld bc,FCB_S1			; Offset 13: point to user number field in FCB
	add hl,bc			; HL += BC
	dec de				; DE--
	ldi				; copy the user number
	ld de,work_fcb			; point DE at work FCB / DU pair for the command line file spec
	call set_du			; select that drive and user
	or a				; Check if drive and user selection succeeded
	jp nz,L01E1			; cannot select it
	ld hl,(argv_ptr)		; list of files goes after the argument table
	ld a,(saved_user)		; get user number to select
	or 0C0H				; selection mask: user | C0H = DIR and SYS files, this user only
	ld de,work_fcb			; point DE at work FCB / DU pair for the command line file spec
	call build_file_list		; search the directory and build the (sorted) file list
	ld (file_list_ptr),hl		; HL = end of the list
	ld a,c				; C = number of matching files
	ld (file_count),a		; save as number of files in the list to send
L0196:
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
	jp z,L01E1			; nothing to send: exit
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
	ld (unused_26F1),hl		; save as cleared at startup, never read
	ld (unused_26F5),hl		; save as cleared at startup, never read
	ld de,msg_start_rx		; ask the user to start the receiving program
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	call BDOS			; C_WRITESTR: display the $-terminated message
	call scb_setup			; change console settings for the transfer
	call send_main			; send the files
	call scb_restore		; restore the console settings
L01E1:
	ld bc,0000H			; BC = original user/drive (patched at start)
restore_du		.equ L01E1+1	; default user/drive restored at exit (patched operand)
	ld (saved_user),bc		; save as user number to select
	ld de,work_fcb			; point DE at work FCB / DU pair for the command line file spec
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
	.db "SZ for CP/M 3   V 1.11",0DH,0AH
	.db "(C) 92 wshbg",0DH,0AH
	.db 0AH
	.db 24H
; "sorry, CP/M 3 Tool"
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
; ----------------------------------------------------------------------
parse_options:
	push hl				; preserve HL
	push de				; preserve DE
L03B5:
	inc de				; Advance to next character in argument string
	ld a,(de)			; A = (DE)
	or a				; Test for null terminator (end of string)
	jr z,L03C7			; if result is zero goto L03C7
	ld hl,D03CA			; point HL at D03CA
	ld bc,0008H			; 8 keys in the table
	cpir				; look A up in the key table
	call z,dispatch			; if A is in the key list goto dispatch
	jr L03B5			; loop back to L03B5
L03C7:
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
D03CA:
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
; Option A: ask the receiver to append (ZF1 = ZMAPND).
opt_append:
	ld a,0FFH			; A = 0FFH
	ld (opt_append_flag),a		; FFH if -a = FFH (set)
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
L0450:
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
	jr L0450			; ... and write them to the System Control Block
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
; print_err_count: Print the current error count / retry message on the
; console.
; ----------------------------------------------------------------------
print_err_count:
	ld a,(error_count)		; get consecutive error/retry counter
	ld de,D049D			; point DE at D049D
	call a_to_decimal		; convert A to up to three decimal digits at DE
	ld de,msg_errors		; point DE at " error
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display " error
; " error(s)" message
msg_errors:
	.db 0DH,0AH
D049D:
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
	ld hl,D04ED			; point HL at D04ED
	ld (hl),3AH			; store into D04ED
	inc hl				; HL++
	xor a				; Clear accumulator
	ld b,0DH			; fill 13 bytes
	call memset			; fill B bytes at HL with A
	inc de				; Advance past drive byte to filename field (8+3)
	call fcb_to_name		; format the FCB name at DE as NAME.EXT at HL
	dec de				; Back up DE to drive byte
	ld a,(de)			; Load 1-based drive number
	add a,40H			; Convert to ASCII letter ('A'..'P')
	ld (D04E9),a			; save as D04E9
	dec de				; Back up DE to user number byte
	ld a,(de)			; Load user number (0..15)
	ld de,D04EA			; point DE at D04EA
	call a_to_decimal		; convert A to up to three decimal digits at DE
	ld hl,file_size			; point HL at size of the current file in bytes
	ld de,D04FC			; point DE at D04FC
	call ltoa32			; convert file_size to decimal text at D04FC
	ld (hl),0DH			; Append CR
	inc hl				; HL++
	ld (hl),0AH			; Append LF
	inc hl				; HL++
	ld (hl),24H			; Append '$' terminator for BDOS output
	ld de,name_line_buf		; point DE at console line buffer
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display console line buffer
; Console line buffer: CR LF, "d:" and file name
name_line_buf:
	.db 0DH,0AH
D04E9:
	.db 00H
D04EA:
	.db 00H
	.db 00H
	.db 00H
D04ED:
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
D04FC:
	.fill 12,0

; ----------------------------------------------------------------------
; print_position: Print the current file position as a decimal number on
; the console.
; ----------------------------------------------------------------------
print_position:
	ld hl,pos_display		; point HL at copy of the file position shown on the console
	ld de,D051C			; point DE at D051C
	call ltoa32			; convert pos_display to decimal text at D051C
	ld (hl),24H			; Append '$' string terminator
	ld de,pos_line_buf		; point DE at console line buffer for the position display
	ld c,C_WRITESTR			; BDOS function: C_WRITESTR
	jp BDOS				; C_WRITESTR: display console line buffer for the position display
; Console line buffer for the position display
pos_line_buf:
	.db 0DH
D051C:
	.fill 10,0

; ----------------------------------------------------------------------
; print_cant_open: Print "can't open any file".
; ----------------------------------------------------------------------
print_cant_open:
	ld de,msg_cant_open		; point DE at "can't open any file"
	jr L052E			; continue at L052E

; ----------------------------------------------------------------------
; print_skipped: Print "File skipped".
; ----------------------------------------------------------------------
print_skipped:
	ld de,msg_file_skipped		; point DE at "File skipped"
L052E:
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
	ld hl,D055F			; point HL at D055F
	ld (hl),a			; store into D055F
	inc hl				; Advance HL to buffer count byte
	ld (hl),c			; store into D055F
	ret				; return
D055F:
	.db 00H
D0560:
	.db 00H

; ----------------------------------------------------------------------
; aux_poll_input: Poll the AUX device (BDOS A_STATIN/A_READ) and move any
; waiting characters into the receive ring buffer.
; ----------------------------------------------------------------------
aux_poll_input:
	or a				; test A (sets Z if A = 0)
	ld hl,(aux_ring)		; get AUX receive ring buffer control block
	ld de,0200H			; DE = maximum receive ring buffer capacity (512 bytes)
	sbc hl,de			; Test if buffer is full
	jr z,L0582			; If buffer full, do not read; check available count
	ld c,A_STATIN			; BDOS function: A_STATIN
	call BDOS			; A_STATIN: is a character waiting at the AUX port?
	or a				; test A (sets Z if A = 0)
	jr z,L0582			; if result is zero goto L0582
	ld c,A_READ			; BDOS function: A_READ
	call BDOS			; A_READ: read a character from the AUX (modem) port
	ld c,a				; C = received character byte
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_put			; insert byte C into the receive ring buffer
	jr aux_poll_input		; loop back to aux_poll_input
L0582:
	ld hl,D0560			; point HL at D0560
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
	ld a,(D0560)			; get D0560
	or a				; Is single-byte buffer empty?
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	jp z,ring_get			; if D0560 is zero/clear goto ring_get
	push af				; preserve AF
	ld hl,D0560			; point HL at D0560
	dec (hl)			; count down D0560
	dec hl				; Point back to input index
	pop af				; restore AF
	ld a,(hl)			; get a byte of D0560
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
L05B0:
	push bc				; preserve BC
	call aux_poll_input		; poll the AUX device
	pop bc				; restore BC
	jr nz,L05BF			; if input was waiting goto L05BF
	call delay_short		; short software delay loop
	djnz L05B0			; repeat until all B items are done
	call aux_poll_input		; poll the AUX device
L05BF:
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
L05C9:
	djnz L05C9			; repeat until all B items are done
	dec a				; Decrement outer loop count
	jr nz,L05C9			; Loop until outer count reaches 0
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
	ld b,25H			; B = 25H
	jr memset_a			; continue at memset_a

; ----------------------------------------------------------------------
; ring_reset: Clear the 6-byte ring buffer control block at HL.
; ----------------------------------------------------------------------
ring_reset:
	ld b,06H			; Count = 6 bytes to clear

; ----------------------------------------------------------------------
; memset_a: Fill using A and B.
; ----------------------------------------------------------------------
memset_a:
	xor a				; Fill byte = 00h
	jp memset			; continue at memset

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
	jr L0641			; continue at L0641

; ----------------------------------------------------------------------
; copy32: Copy 32-bit value (HL) to (DE).
; ----------------------------------------------------------------------
copy32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ldi				; Copy byte 1: (DE) = (HL), increment pointers, dec BC
L0641:
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
; ----------------------------------------------------------------------
cmp32_signed:
	push hl				; preserve HL
	pop ix				; restore IX
	push de				; preserve DE
	pop iy				; restore IY
	ld a,(ix+3)			; Compare most significant bytes (signs)
	xor (iy+3)			; A ^= (iy+3)
	jp p,L0660			; If signs are identical, do unsigned compare
	xor (ix+3)			; Restore sign byte
L065D:
	ret m				; return if negative
	ccf				; complement carry
	ret				; return
L0660:
	xor (ix+3)			; Restore sign byte
	jp p,cmp32_unsigned		; If positive, perform standard 32-bit subtract compare
	call cmp32_unsigned		; unsigned compare of 32-bit values
	scf				; flag failure to caller (carry set)
	jr L065D			; loop back to L065D

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
L0673:
	ld a,(de)			; Load subtrahend byte
	sbc a,(hl)			; Subtract with borrow minuend byte
	inc de				; Advance subtrahend pointer
	inc hl				; Advance minuend pointer
	djnz L0673			; repeat until all B items are done
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
L0682:
	ld a,(de)			; Load byte from first buffer
	xor (hl)			; Compare with byte from second buffer
	jr nz,L068A			; If mismatch found, exit with NZ
	inc de				; Advance first pointer
	inc hl				; Advance second pointer
	djnz L0682			; repeat until all B items are done
L068A:
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
L0695:
	ex af,af'			; Restore carry from previous byte addition
	ld a,(de)			; Load addend byte from (DE)
	adc a,(hl)			; Add with carry addend byte from (HL)
	ld (bc),a			; Store sum byte to destination (BC)
	inc bc				; Advance destination pointer
	inc de				; Advance source pointer 1
	inc hl				; Advance source pointer 2
	ex af,af'			; Preserve carry in alternate AF
	dec a				; Decrement loop byte count
	jr nz,L0695			; Continue for all 4 bytes
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
L06AC:
	ex af,af'			; Restore borrow from previous byte subtraction
	ld a,(de)			; Load minuend byte from (DE)
	sbc a,(hl)			; Subtract with borrow subtrahend byte from (HL)
	ld (bc),a			; Store difference byte to destination (BC)
	inc bc				; Advance destination pointer
	inc hl				; Advance subtrahend pointer
	inc de				; Advance minuend pointer
	ex af,af'			; Preserve borrow in alternate AF
	dec a				; Decrement loop byte count
	jr nz,L06AC			; Continue for all 4 bytes
	ex af,af'			; swap AF with AF'
	pop hl				; restore HL
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; inc32: Increment the 32-bit value at (HL).
; ----------------------------------------------------------------------
inc32:
	push bc				; preserve BC
	push hl				; preserve HL
	ld a,01H			; Add 1 to lowest byte
	add a,(hl)			; A += (HL)
	ld (hl),a			; Store updated low byte
	jr nc,L06CD			; If no overflow, increment complete
	ld b,03H			; repeat count = 3
L06C6:
	inc hl				; Advance to next higher byte
	ld a,00H			; Add carry bit
	adc a,(hl)			; A += (HL) + carry
	ld (hl),a			; Store updated byte
	djnz L06C6			; repeat until all B items are done
L06CD:
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
L06DB:
	inc hl				; Advance to next higher byte
	ld a,(hl)			; Load byte
	sbc a,00H			; Subtract borrow bit
	ld (hl),a			; Store updated byte
	djnz L06DB			; repeat until all B items are done
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; and32: (BC) = (DE) AND (HL), 32-bit.
; ----------------------------------------------------------------------
and32:
	push bc				; preserve BC
	push de				; preserve DE
	push hl				; preserve HL
	ex de,hl			; swap pointers
	ld a,04H			; Process 4 bytes (32 bits)
L06EB:
	push af				; preserve AF
	ld a,(de)			; Load byte from source 1
	and (hl)			; Bitwise AND with byte from source 2
	ld (bc),a			; Store result byte into destination
	inc bc				; Advance destination pointer
	inc de				; Advance source 1 pointer
	inc hl				; Advance source 2 pointer
	pop af				; restore AF
	dec a				; Decrement byte counter
	jr nz,L06EB			; Repeat for all 4 bytes
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
	ld de,ltoa_value		; point DE at working copy of the value being converted
	call copy32			; work on a copy of the value
	ld c,09H			; up to nine digits plus the final one
	ld de,pow10_table-4		; DE -> 4 bytes before the table of powers of ten (stepped forward before each use)
	xor a				; A = 0
	ld (ltoa_started),a		; no digit emitted yet (suppress leading zeros)
L0731:
	ld a,30H			; start the digit at "0"
	ld (ltoa_digit),a		; digit character being built = 30H
	inc de				; step to the next power of ten (4 bytes)
	inc de				; DE++
	inc de				; DE++
	inc de				; DE++
	ld b,0AH			; at most ten subtractions per digit
L073C:
	push bc				; preserve BC
	ld hl,ltoa_value		; point HL at working copy of the value being converted
	ld bc,ltoa_temp			; point BC at temporary subtraction result
	call sub32			; temp = value - power of ten
	pop bc				; restore BC
	jr c,L075D			; value is smaller than the power: this digit is complete
	push de				; preserve DE
	ld a,(ltoa_digit)		; count one more subtraction
	inc a				; A++
	ld (ltoa_digit),a		; save as digit character being built
	ld de,ltoa_value		; point DE at working copy of the value being converted
	ld hl,ltoa_temp			; point HL at temporary subtraction result
	call copy32			; value = remainder
	pop de				; restore DE
	djnz L073C			; try subtracting again
L075D:
	ld a,30H			; digit finished: is it "0"?
ltoa_digit		.equ L075D+1	; ltoa32: digit character being built (patched operand)
	cp 30H				; Is it a leading zero ('0')?
	jr nz,L0768			; non-zero digit: always emit it
L0763:
	ld a,00H			; a zero: emit only if a digit was already emitted
ltoa_started		.equ L0763+1	; ltoa32: nonzero once a nonzero digit has been emitted
	or a				; test A (sets Z if A = 0)
	jr z,L0775			; leading zero: skip it
L0768:
	ld hl,0000H			; HL = output pointer
ltoa_outptr		.equ L0768+1	; ltoa32: output pointer (patched operand, 16 bits)
	ld (hl),a			; store the digit
	inc hl				; Advance output pointer
	ld (ltoa_outptr),hl		; advance the output pointer
	ld a,30H			; mark that digits have started
	ld (ltoa_started),a		; nonzero once a nonzero digit has been emitted = 30H
L0775:
	dec c				; next power of ten
	jr nz,L0731			; Process next decimal position
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
L0788:
	add a,00H			; SMC: Add byte to running 8-bit checksum accumulator
xm_checksum		.equ L0788+1	; running 8-bit XMODEM checksum (patched operand)
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
L0798:
	ld iy,crc32_table		; point IY at CRC-32 lookup table, 256 x 4 bytes
crc32_tab_ptr		.equ L0798+2	; address of the CRC-32 table (patched operand, 16 bits)
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
L07E0:
	push af				; keep the index
	ld hl,0FFFFH			; CRC register = FFFFFFFFH (HL:DE)
	ld de,0FFFFH			; DE = 0FFFFH
	xor e				; mix the index into the low byte
	ld e,a				; E = A
	ld b,08H			; eight bit steps
L07EB:
	scf				; shift in a 1 ...
	rr h				; ... shifting the 32-bit register right
	rr l				; rotate right through carry L
	rr d				; rotate right through carry D
	rr e				; rotate right through carry E
	jr nc,L080A			; bit shifted out was 0: no polynomial
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
L080A:
	djnz L07EB			; next bit
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
	jr nz,L07E0			; repeat for all 256 entries
	pop hl				; restore HL
	pop de				; restore DE
	ret				; return

; ----------------------------------------------------------------------
; crc16_update: Update the running CRC-16 (CCITT, polynomial 1021H) with
; byte A. [updcrc]
; ----------------------------------------------------------------------
crc16_update:
	push af				; preserve AF
L0830:
	ld hl,0000H			; SMC: Running CRC-16 accumulator operand
crc16_lo		.equ L0830+1	; CRC-16 low byte (patched operand)
crc16_hi		.equ L0830+2	; CRC-16 high byte (patched operand)
	ld de,1021H			; CCITT CRC-16 polynomial generator (x^16 + x^12 + x^5 + 1)
	xor h				; XOR input byte with current high byte of CRC
	ld h,a				; Store XOR result into high byte of CRC
	ld b,08H			; Process 8 bits
L083A:
	add hl,hl			; Shift CRC left by 1 bit (HL << 1)
	jr nc,L0843			; If no carry shifted out, skip polynomial XOR
	ld a,h				; XOR high byte with polynomial high byte (10h)
	xor d				; A ^= D
	ld h,a				; H = A
	ld a,l				; XOR low byte with polynomial low byte (21h)
	xor e				; A ^= E
	ld l,a				; L = A
L0843:
	djnz L083A			; repeat until all B items are done
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
	jr nz,L0860			; if A is not ZMODEM goto L0860
	ld a,03H			; A = 03H
	ld (protocol),a			; selected protocol = 03H (YMODEM)
L0860:
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
	jr c,L0888			; if transfer failed / aborted goto L0888
	or a				; test A (sets Z if A = 0)
	ret				; return
L0888:
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; calc_buffer_mask: Round the available buffer size down to a power of two
; and derive the wrap-around mask.
; ----------------------------------------------------------------------
calc_buffer_mask:
	xor a				; Clear accumulator
	ld c,a				; Initialize bit mask register C = 0
	ld b,08H			; repeat count = 8
	ld a,h				; Load memory page high byte into A
L088F:
	rlca				; Shift highest bit into carry
	set 7,c				; Set bit 7 in mask register C
	jr c,L0898			; If highest bit set, mask is complete
	rr c				; Shift mask bit right
	djnz L088F			; repeat until all B items are done
L0898:
	ld a,h				; A = high byte of available pages
	and c				; Mask to largest power-of-two page boundary
	ld h,a				; Set HL high byte to power-of-two page
	ld l,00H			; Set HL low byte to 0 (page-aligned)
	ld (file_buffer_size),hl	; save as size of the file data ring buffer
	dec hl				; Subtract 1 to create circular address wrap mask
	ld (buffer_mask),hl		; save as file buffer size mask
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
L08AD:
	ld a,00H			; Dynamically patched default drive number
entry_drive		.equ L08AD+1	; drive for list entries (patched operand)
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
	jr z,L08F4			; no files in the list
	ld b,a				; B counts the files left (also the list index)
L08D1:
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
	jr c,L08F7			; failed or aborted
	djnz L08D1			; next file
	ld a,(files_sent_count)		; were any files sent?
	or a				; Were any files transferred?
	jr nz,L08FE			; yes: finish the session
L08F4:
	call print_cant_open		; no file could be opened
L08F7:
	call send_can_string		; abort the receiver
	ld a,0FFH			; return with error
	scf				; flag failure to caller (carry set)
	ret				; return
L08FE:
	ld a,(protocol)			; all files sent: end the session
	cp 03H				; is it YMODEM?
	jr c,L0920			; XMODEM: nothing more to send
	jr nz,L091D			; ZMODEM: send ZFIN
	xor a				; YMODEM: send an empty block 0 to end the batch
	ld (xmodem_block_no),a		; clear current XMODEM block number
	ld hl,(file_buffer_base)	; get start of the file data ring buffer
	ld b,80H			; fill 128 bytes
	call memset			; block of 128 zero bytes
	ld hl,0080H			; HL = 0080H
	ld (block_len),hl		; save as length of the current block / subpacket
	call xmodem_snd_block		; send one block
	xor a				; Clear A
L091D:
	call nz,send_zfin_oo		; ZMODEM: finish with ZFIN and "OO"
L0920:
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
	jr z,L094C			; opened
	xor a				; could not open: skip this file
	ret				; return
L094C:
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
L0983:
	ld a,(hl)			; Load filename character
	call is_alpha			; a letter?
	jr nz,L098C			; if not zero goto L098C
	or 20H				; yes: make it lower case
	ld (hl),a			; Store lowercase character back to buffer
L098C:
	inc hl				; Advance character pointer
	djnz L0983			; repeat until all B items are done
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
L09EA:
	ld b,0FFH			; wait up to 25.5 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	ld hl,D0A31			; point HL at D0A31
	ld bc,0005H			; 5 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
L09FD:
	ld a,(last_rx_char)		; get last character received from the modem
	ld (prev_rx_char),a		; save as previous received character
	jr L09EA			; loop back to L09EA
wait_can_confirm:
	ld b,14H			; wait up to 2.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	cp 18H				; is it ZDLE/CAN?
	jr nz,L09FD			; if A is not ZDLE/CAN goto L09FD
	ld hl,prev_rx_char		; point HL at previous received character
	cp (hl)				; compare A with (HL)
	jr nz,L09FD			; if not zero goto L09FD
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
D0A31:
	.db 2AH,0FEH,43H,15H,18H	; keys: *.C..
	.dw wait_can_confirm		; key 18H CAN
	.dw got_nak			; key 15H NAK
	.dw got_c_crc_mode		; key 43H 'C' (CRC requested)
	.dw got_timeout			; key 0FEH TIMEOUT
	.dw got_zpad_zmodem		; key 2AH ZPAD: receiver speaks ZMODEM
D0A40:
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
L0A61:
	ld b,0FFH			; wait up to 25.5 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem
	ld hl,D0A40			; point HL at D0A40
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jr nz,L0A61			; if A is not in the key list goto L0A61
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
	jr nc,L0AA0			; if first value >= second goto L0AA0
	ld hl,0080H			; HL = 0080H
L0AA0:
	ld (block_len),hl		; save as length of the current block / subpacket
	ld bc,(block_len)		; get length of the current block / subpacket
	call fill_file_buffer		; read BC bytes from the file into the ring buffer
	jr c,xw_timeout			; if disk read error goto xw_timeout
	or a				; Check bytes read status
	jr z,L0AB3			; if result is zero goto L0AB3
	ld a,d				; Check if remaining length is zero (EOF)
	or e				; A |= E
	jr z,xmodem_send_eot		; if result is zero goto xmodem_send_eot
L0AB3:
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
L0ACB:
	push bc				; preserve BC
	ld a,04H			; character to send: EOT
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	cp 06H				; is it ACK?
	jr z,L0AE1			; if A is ACK goto L0AE1
	pop bc				; restore BC
	djnz L0ACB			; repeat until all B items are done
; No answer within 25.5 s: abort.
xw_timeout:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
L0AE1:
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
L0AEB:
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
	jr z,L0B0C			; if A = 80H goto L0B0C
	ld a,02H			; no: start with STX (1K block)
L0B0C:
	call aux_putc_wait		; send the block start character
	ld a,(xmodem_block_no)		; get current XMODEM block number
	call aux_putc_wait		; send the block number
	ld a,(xmodem_block_no)		; get current XMODEM block number
	cpl				; send its complement
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	call crc_init			; start the checksum / CRC
	ld ix,(file_buffer_base)	; IX -> block data
L0B23:
	ld a,(ix+0)			; next data byte
	call checksum_add		; add A to the running 8-bit XMODEM checksum
	call crc16_update		; update the running CRC-16
	push ix				; preserve IX
	call aux_putc_wait		; send it
	pop ix				; restore IX
L0B33:
	ld hl,0000H			; HL = bytes left (patched)
blk_bytes_left		.equ L0B33+1	; bytes still to send in the current block (patched operand, 16 bits)
	dec hl				; Decrement remaining byte count
	ld (blk_bytes_left),hl		; save as bytes still to send in the current block
	inc ix				; Advance buffer pointer
	ld a,h				; block finished?
	or l				; A = H or L: zero only if HL = 0
	jr nz,L0B23			; if the 16-bit count is not zero goto L0B23
	ld a,(tx_crc_mode)		; trailer: CRC or checksum?
	cp 10H				; compare A with 10H
	jr z,L0B4C			; CRC
	ld a,(xm_checksum)		; checksum
	jr L0B55			; continue at L0B55
L0B4C:
	ld a,(crc16_hi)			; CRC high byte
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(crc16_lo)			; CRC low byte
L0B55:
	call aux_putc_wait		; send the trailer
	ld b,64H			; wait up to 10 s for ACK/NAK
	call aux_getc_timeout		; get a character from the modem with timeout
	ld (last_rx_char),a		; save as last character received from the modem

; ----------------------------------------------------------------------
; xs_wait_ack: XMODEM send: wait for ACK/NAK reply.
; ----------------------------------------------------------------------
xs_wait_ack:
	ld a,(last_rx_char)		; get last character received from the modem
	ld hl,D0B9C			; point HL at D0B9C
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jp xs_bad_response		; continue at xs_bad_response
; CAN received (two in a row cancel).
xs_got_can:
	ld a,(prev_rx_char)		; get previous received character
	cp 18H				; is it ZDLE/CAN?
	jp nz,xs_bad_response		; if A is not ZDLE/CAN goto xs_bad_response
L0B79:
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
D0B9C:
	.db 18H,0FEH,43H,15H,06H,0FFH	; keys: ..C...
	.dw xs_got_garbage		; key 0FFH ERROR
	.dw xs_got_ack			; key 06H ACK
	.dw xs_got_nak			; key 15H NAK
	.dw xs_got_c			; key 43H 'C' (CRC requested)
	.dw xs_timeout			; key 0FEH TIMEOUT
	.dw xs_got_can			; key 18H CAN
D0BAE:
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
	ld hl,D0BAE			; point HL at D0BAE
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; CAN received after garbage: abort if the previous character was also CAN.
xs_chk_can:
	ld a,(prev_rx_char)		; get previous received character
	cp 18H				; is it ZDLE/CAN?
	jp z,L0B79			; if A is ZDLE/CAN goto L0B79
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
	jp c,L0AEB			; if A < 05H goto L0AEB
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
L0BF5:
	ld hl,zrqinit_retries		; point HL at remaining attempts to get ZRINIT
	dec (hl)			; count down remaining attempts to get ZRINIT
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret z				; return: remaining attempts to get ZRINIT has run out
	call get_header			; wait for the receiver's ZRINIT [zgethdr]
	ld hl,D0C79			; point HL at D0C79
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
L0C0B:
	ld a,ZNAK			; frame type = ZNAK
	call send_hex_header		; send a hex header
	jr L0BF5			; loop back to L0BF5
zi_got_zchall:
	ld hl,rx_header_data		; point HL at four argument bytes of the last received header
	ld de,tx_header_data		; point DE at four argument bytes for the next header to send
	call copy32			; copy rx_header_data to tx_header_data
	ld a,ZACK			; frame type = ZACK
	call send_hex_header		; send a hex header
	jr L0BF5			; loop back to L0BF5
zi_got_zcommand:
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	call zero32			; clear tx_header_data
	ld a,ZRQINIT			; frame type = ZRQINIT
	call send_hex_header		; send a hex header
	jr L0BF5			; loop back to L0BF5

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
	jr nz,L0C5E			; if the 16-bit count is not zero goto L0C5E
	ld a,(window_default)		; no limit announced: use a default window (32K) between acknowledgements
	rla				; Scale to buffer byte count (* 1024)
	rla				; rotate A left through carry
	ld h,a				; H = A
	ld l,00H			; Low byte = 0
	ld (rx_window_size),hl		; save as receiver buffer length from ZRINIT ZP0/ZP1
L0C5E:
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
	jp z,L0BF5			; if A = 12H goto L0BF5
	jp L0C0B			; loop back to L0C0B
D0C79:
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
L0C95:
	ld ix,tx_header_data		; point IX at four argument bytes for the next header to send
	ld a,(opt_binary_flag)		; get FFH if -b
	cp 0FFH				; Is binary transfer active?
	ld a,ZF0_ZCBIN			; ZF0 = 1 (ZCBIN: binary transfer)
	jr z,L0CAC			; if A = FFH goto L0CAC
	ld a,(opt_convert_flag)		; get FFH if -c
	cp 0FFH				; Is text conversion active?
	ld a,ZF0_ZCNL			; ZF0 = 2 (ZCNL: convert end-of-line)
	jr z,L0CAC			; if A = FFH goto L0CAC
	xor a				; Default ZF0 = 0 (standard transfer)
L0CAC:
	ld (ix+ZF0),a			; ZF0 conversion option: 1 = ZCBIN (-b), 2 = ZCNL (-c) [Lzconv]
	ld a,(opt_protect_flag)		; get FFH if -p
	cp 0FFH				; compare A with 0FFH
	ld a,ZF1_ZMPROT			; ZF1 = 7 (ZCRECOV: recover interrupted transfer)
	jr z,L0CC2			; if A = FFH goto L0CC2
	ld a,(opt_append_flag)		; get FFH if -a
	cp 0FFH				; compare A with 0FFH
	ld a,ZF1_ZMAPND			; A = 03H
	jr z,L0CC2			; if A = FFH goto L0CC2
	xor a				; Default ZF1 = 0
L0CC2:
	ld (ix+ZF1),a			; ZF1 management option: 7 = ZMPROT (-p), 3 = ZMAPND (-a) [Lzmanag]
	xor a				; Clear A
	ld (ix+ZF2),a			; ZF2 transport option = 0 [Lztrans]
	ld (ix+ZF3),a			; ZF3 = 0
	ld a,ZFILE			; frame type = ZFILE
	call send_bin_header		; send the ZFILE header [zsbhdr]
L0CD1:
	ld bc,0000H			; 0 keys in the table
zfile_info_len		.equ L0CD1+1	; length of the ZFILE info subpacket (patched operand, 16 bits)
	ld a,ZCRCW			; A = 6BH
	call send_subpacket		; file name and size as a ZCRCW data packet [zsbdata]
L0CD9:
	call get_header			; wait for ZRPOS, ZSKIP, ... [zgethdr]
	ld hl,D0D2F			; point HL at D0D2F
	ld bc,0008H			; 8 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L0C95			; loop back to L0C95
; ZRINIT again: wait up to 5 s for ZPAD; if none arrives send the ZFILE again.
zf_wait_zpad:
	ld b,32H			; wait up to 5.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,L0C95			; if timed out waiting for the modem goto L0C95
	cp ZPAD				; is it ZPAD?
	jr z,L0CD9			; if A is ZPAD goto L0CD9
	jr zf_wait_zpad			; loop back to zf_wait_zpad
; Abort the ZModem transfer.
zf_abort:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return
; Ignore this frame and read the next header.
zf_ignore:
	jp L0CD9			; loop back to L0CD9
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
D0D2F:
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
L0D4E:
	jp zmodem_stream		; continue at zmodem_stream
L0D51:
	xor a				; A = 0
	ld (resp_junk_count),a		; clear garbage characters seen while streaming
	ld a,0FFH			; A = 0FFH
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
L0D5A:
	ld hl,D0D6E			; point HL at D0D6E
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
D0D6E:
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
L0D8B:
	ld hl,D0DA7			; point HL at D0DA7
	ld bc,0005H			; 5 keys in the table
	cpir				; look A up in the key table
	jr nz,zd_got_zrpos		; if A is not in the key list goto zd_got_zrpos
	jp dispatch			; loop back to dispatch
; ZPAD or ZDLE seen: a header is coming; read it.
zd_got_pad:
	ld a,00H			; A = 00H
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
	jp L0D5A			; loop back to L0D5A
; XOFF seen: the line is paused; wait for it to be released.
zd_got_xoff:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr L0D8B			; loop back to L0D8B
D0DA7:
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
L0DCA:
	call get_next_chunk		; HL = length of the next chunk (up to subpacket_size)
	ret c				; disk read error
	ld (chunk_len),hl		; save as number of bytes in the current chunk
	ld a,(eof_pending)		; last chunk of the file?
	cp 0FFH				; compare A with 0FFH
	jr nz,L0DE0			; if A != FFH goto L0DE0
	ld a,ZCRCE			; last (short) chunk: end the frame with ZCRCE, no reply expected [zsendfdata: c <
					; blklen]
	ld (subpkt_term),a		; terminator for the next data subpacket = 68H (ZCRCE)
	jp L0E16			; continue at L0E16
L0DE0:
	ld a,(resp_junk_count)		; trouble seen from the receiver?
	cp 04H				; compare A with 04H
	jr c,L0DEF			; if A < 04H goto L0DEF
L0DE7:
	ld a,ZCRCW			; end with ZCRCW: the receiver must acknowledge before more data is sent
	ld (subpkt_term),a		; terminator for the next data subpacket = 6BH (ZCRCW)
	jp L0E16			; continue at L0E16
L0DEF:
	ld hl,last_sync_pos		; just resent after a ZRPOS to the same position?
	ld de,last_zrpos_pos		; point DE at position of the last ZRPOS request
	call eq32			; compare last_sync_pos with last_zrpos_pos
	jr z,L0DE7			; yes: be careful, use ZCRCW
	ld hl,(rx_window_size)		; receiver has a window?
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L0E11			; no window: stream freely
	ld hl,(window_remaining)	; get bytes left before the receiver must acknowledge
	ld de,(chunk_len)		; get number of bytes in the current chunk
	sbc hl,de			; window left after this chunk [zsendfdata: newcnt -= c]
	ld (window_remaining),hl	; save as bytes left before the receiver must acknowledge
	jr z,L0DE7			; window used up: ZCRCW
	jr c,L0DE7			; if carry goto L0DE7
L0E11:
	ld a,ZCRCG			; otherwise ZCRCG: more data follows, no reply needed [zsendfdata: e = ZCRCG]
	ld (subpkt_term),a		; terminator for the next data subpacket = 69H (ZCRCG)
L0E16:
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
	jp z,L0D51			; go and wait for the ZACK
L0E3D:
	call aux_poll_input		; anything from the receiver?
	jr z,L0E93			; no: carry on
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
L0E47:
	ld hl,D0E84			; point HL at D0E84
	ld bc,0005H			; 5 keys in the table
	cpir				; XON/XOFF, ZPAD, ZDLE or timeout?
	jp z,dispatch			; if A is in the key list goto dispatch
	ld hl,resp_junk_count		; other junk: note it
	inc (hl)			; count up garbage characters seen while streaming
	jr L0E3D			; look again
zs_got_pad:
	ld a,00H			; A = 00H
	call zmodem_get_resp		; wait for a header from the receiver and dispatch on its
	cp ZACK				; is it ZACK?
	jr z,L0E93			; if A is ZACK goto L0E93
	push af				; preserve AF
L0E62:
	ld hl,aux_ring			; point HL at AUX receive ring buffer control block
	call ring_reset			; clear the 6-byte ring buffer control block at HL
	call aux_poll_input		; poll the AUX device
	jr nz,L0E62			; if input was waiting goto L0E62
	ld a,ZCRCE			; a ZPAD arrived from the receiver: send an empty ZCRCE data packet first [spec 9.1,
					; sampling the reverse channel]
	ld bc,0000H			; BC = 0000H
	call send_subpacket		; send BC data bytes followed by ZDLE and the terminator
	pop af				; restore AF
	jp L0D5A			; loop back to L0D5A
zs_got_xoff:
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ld hl,resp_junk_count		; point HL at garbage characters seen while streaming
	inc (hl)			; count up garbage characters seen while streaming
	jr L0E47			; loop back to L0E47
D0E84:
	.db 0FEH,ZDLE,ZPAD,13H,93H	; keys: ..*..
	.dw zs_got_xoff			; key 93H XOFF (bit 7 set)
	.dw zs_got_xoff			; key 13H XOFF
	.dw zs_got_pad			; key 2AH ZPAD
	.dw zs_got_pad			; key 18H ZDLE/CAN
	.dw zd_abort			; key 0FEH timeout
L0E93:
	ld a,(eof_pending)		; get FFH when the end of the file has been read into the
	cp 0FFH				; compare A with 0FFH
	jp nz,L0DCA			; if A != FFH goto L0DCA

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
	ld hl,D0EC5			; point HL at D0EC5
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
	jp L0D4E			; loop back to L0D4E

; ----------------------------------------------------------------------
; zeof_ok: Receiver acknowledged ZEOF.
; ----------------------------------------------------------------------
zeof_ok:
	xor a				; return 0 (success)
	ret				; return
; ZSKIP after ZEOF.
zeof_skip:
	ret				; return
D0EC5:
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
L0ED4:
	call get_header			; receive a ZMODEM header
	ld hl,D0F74			; point HL at D0F74
	ld bc,0009H			; 9 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
; Bad header: send ZNAK and read again.
resp_send_znak:
	ld a,ZNAK			; frame type = ZNAK
	call send_bin_header		; send a binary header
	jr L0ED4			; loop back to L0ED4
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
L0EF9:
	ld a,00H			; A = 00H
resp_mode_flag		.equ L0EF9+1	; FFH: wait for a ZACK at the current position (patched operand)
	cp 00H				; Compare with 0
	ld a,ZACK			; return ZACK
	ret z				; return: A = 00H
	ld de,tx_position		; point DE at position in the file of the next byte to send
	ld hl,rx_pos_arg		; point HL at position argument of the last ZRPOS/ZACK from the
	call eq32			; compare rx_pos_arg with tx_position
	ld a,ZACK			; return ZACK
	ret z				; return: values are equal
	jp L0ED4			; loop back to L0ED4

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
	jr nz,L0F64			; if values differ goto L0F64
	ld a,(same_zrpos_count)		; get number of times in a row ZRPOS asked for the same
	inc a				; Increment consecutive error count
	ld (same_zrpos_count),a		; save as number of times in a row ZRPOS asked for the same
	cp 05H				; 5 consecutive errors at same position?
	jr c,L0F64			; if A < 05H goto L0F64
	ld hl,0020H			; HL = 0020H
	ld de,(subpacket_size)		; get current data subpacket size
	or a				; test A (sets Z if A = 0)
	sbc hl,de			; Is current size already at minimum (32 bytes)?
	jr nc,L0F64			; If at minimum, cannot reduce
	srl d				; repeated ZRPOS for the same offset: halve the data subpacket size
	rr e				; rotate right through carry E
	ld (subpacket_size),de		; save as current data subpacket size
L0F64:
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
D0F74:
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
	jp nc,L0FD2			; if first value >= second goto L0FD2
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
L0FD2:
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	ld de,const_1024		; point DE at 32-bit constant 1024
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call sub32			; pos_scratch = file_read_pos - const_1024
	ld hl,pos_scratch		; point HL at scratch 32-bit result for position arithmetic
	ld de,zrpos_target		; point DE at position requested by ZRPOS
	call cmp32_signed		; compare pos_scratch with zrpos_target
	jp nc,L1015			; if first value >= second goto L1015
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
L1015:
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; file_skip_fwd: Advance the file read position to the target position
; by reading.
; ----------------------------------------------------------------------
file_skip_fwd:
	ex de,hl			; swap pointers
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	jr L102D			; continue at L102D

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
L102D:
	call eq32			; compare 32-bit values
	ret z				; return: values are equal
	call file_getc			; read the next byte from the input file
	jr nz,L103B			; if end of file or error goto L103B
	call inc32			; increment the 32-bit value at
	jr L102D			; loop back to L102D
L103B:
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
	jp c,L1070			; if first value is smaller goto L1070
	ld bc,(subpacket_size)		; get current data subpacket size
	call fill_file_buffer		; read BC bytes from the file into the ring buffer
	ret c				; return: disk read error
	ld a,(eof_flag)			; get FFH when the disk file is at end of file
	ld (eof_pending),a		; save as FFH when the end of the file has been read into the
	ex de,hl			; swap pointers
	ret				; return
L1070:
	ld hl,last_sync_pos		; point HL at position at the last synchronisation point
	ld de,subpacket_size		; point DE at current data subpacket size
	ld bc,pos_scratch		; point BC at scratch 32-bit result for position arithmetic
	call add32			; pos_scratch = subpacket_size + last_sync_pos
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	ld de,pos_scratch		; point DE at scratch 32-bit result for position arithmetic
	call cmp32_signed		; compare file_read_pos with pos_scratch
	jp c,L108C			; if first value is smaller goto L108C
	ld hl,(subpacket_size)		; get current data subpacket size
	ret				; return
L108C:
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
L10A5:
	call ring_buffer_addr		; compute the address of the ring-buffer byte at offset
	call file_getc			; read the next byte from the input file
	jr nz,L10BB			; if end of file or error goto L10BB
	ld (hl),a			; Store byte into circular transmit buffer
	ld hl,file_read_pos		; point HL at position of the next byte to be read from the disk file
	call inc32			; add 1 to file_read_pos
	inc de				; DE++
	dec bc				; Decrement requested read byte count
	ld a,b				; Check if all bytes read
	or c				; A |= C
	jr nz,L10A5			; Loop until entire block is loaded
	ret				; return
L10BB:
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
	jr nz,L1156			; yes
L111B:
	ld a,b				; CRC-16: send BC data bytes
	or c				; A |= C
	jr z,L1131			; if zero goto L1131
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
	jr L111B			; next byte
L1131:
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
L1156:
	ld a,b				; CRC-32: send BC data bytes
	or c				; A |= C
	jr z,L116C			; If done, send delimiter and CRC-32
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
	jr L1156			; loop back to L1156
L116C:
	ld a,ZDLE			; end of data: ZDLE ...
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(data_terminator)		; get terminator byte of the data subpacket being sent
	call crc32_update		; update the running CRC-32 with byte A
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld b,04H			; send the four CRC bytes, complemented
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
L117F:
	ld a,(hl)			; Load CRC byte
	inc hl				; Advance pointer
	push bc				; preserve BC
	push hl				; preserve HL
	cpl				; Invert bits (ones complement of CRC)
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz L117F			; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; send_bin_header: Send a binary header (ZBIN or ZBIN32) with frame type A
; and the header buffer contents. [zm.c zsbhdr]
; ----------------------------------------------------------------------
send_bin_header:
	ld (out_frame_type),a		; save as frame type of the header being sent
	ld a,ZPAD			; character to send: ZPAD
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,ZDLE			; character to send: ZDLE/CAN
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	ld a,(tx_crc_mode)		; get CRC type used for sending
	and CANFC32			; test the CRC-32 flag bit
	jp nz,L11D1			; if result is nonzero goto L11D1
	ld a,ZBIN			; character to send: ZBIN header marker
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(out_frame_type)		; get frame type of the header being sent
	call crc16_update		; update the running CRC-16
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	ld b,04H			; 4 bytes to transmit
L11B7:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; Advance pointer
	push hl				; preserve HL
	call crc16_update		; update the running CRC-16
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz L11B7			; repeat until all B items are done
	ld a,(crc16_hi)			; get CRC-16 high byte
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	ld a,(crc16_lo)			; get CRC-16 low byte
	jp put_zdle_char		; continue at put_zdle_char
L11D1:
	ld a,ZBIN32			; character to send: 'C'
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(out_frame_type)		; get frame type of the header being sent
	call crc32_update		; update the running CRC-32 with byte A
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	ld b,04H			; 4 bytes to transmit
L11E4:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; Advance pointer
	push hl				; preserve HL
	call crc32_update		; update the running CRC-32 with byte A
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz L11E4			; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld b,04H			; 4 CRC bytes to send
L11F7:
	push bc				; preserve BC
	ld a,(hl)			; Load CRC byte
	inc hl				; Advance pointer
	push hl				; preserve HL
	cpl				; Ones complement inversion
	call put_zdle_char		; send A, escaping it with ZDLE if it is a control
	pop hl				; restore HL
	pop bc				; restore BC
	djnz L11F7			; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; send_hex_header: Send a hex header: frame type in A, four argument bytes
; from the header buffer, CRC-16, CR LF. [zm.c zshhdr]
; ----------------------------------------------------------------------
send_hex_header:
	ld (out_frame_type),a		; save as frame type of the header being sent
	ld hl,D124D			; point HL at D124D
	call send_string		; send the zero-terminated string at HL to the modem
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	ld a,(out_frame_type)		; get frame type of the header being sent
	call crc16_update		; update the running CRC-16
	call put_hex_byte		; send A as two lowercase hex digits
	ld hl,tx_header_data		; point HL at four argument bytes for the next header to send
	ld b,04H			; 4 bytes to transmit
L121E:
	push bc				; preserve BC
	ld a,(hl)			; A = (HL)
	inc hl				; Advance pointer
	push hl				; preserve HL
	call crc16_update		; update the running CRC-16
	call put_hex_byte		; send A as two lowercase hex digits
	pop hl				; restore HL
	pop bc				; restore BC
	djnz L121E			; repeat until all B items are done
	ld a,(crc16_hi)			; get CRC-16 high byte
	call put_hex_byte		; send A as two lowercase hex digits
	ld a,(crc16_lo)			; get CRC-16 low byte
	call put_hex_byte		; send A as two lowercase hex digits
	ld a,0DH			; character to send: CR
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,0AH			; character to send: LF
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	ld a,(out_frame_type)		; get frame type of the header being sent
	cp ZFIN				; is it ZFIN?
	ret z				; return: A is ZFIN
	ld a,11H			; A = 11H (XON)
	jp aux_putc_wait		; continue at aux_putc_wait
D124D:
	.db ZPAD,ZPAD,ZDLE,ZHEX,00H
D1252:
	.db "0123456789abcdef"

; ----------------------------------------------------------------------
; put_hex_byte: Send A as two lowercase hex digits. [zm.c zputhex]
; ----------------------------------------------------------------------
put_hex_byte:
	push af				; preserve AF
	ld hl,D1252			; point HL at D1252
	ld b,00H			; BC = high nibble index
	rra				; Shift high nibble into low nibble (A >> 4)
	rra				; rotate A right through carry
	rra				; rotate A right through carry
	rra				; rotate A right through carry
	and 0FH				; keep the low nibble
	ld c,a				; Set offset
	add hl,bc			; HL points to hex ASCII character
	ld a,(hl)			; get a byte of D1252
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
	pop af				; restore AF
	ld hl,D1252			; point HL at D1252
	ld b,00H			; BC = low nibble index
	and 0FH				; keep the low nibble
	ld c,a				; Set offset
	add hl,bc			; HL points to hex ASCII character
	ld a,(hl)			; get a byte of D1252
	jp aux_putc_wait		; continue at aux_putc_wait

; ----------------------------------------------------------------------
; put_zdle_char: Send A, escaping it with ZDLE if it is a control
; character. [zm.c zsendline]
; ----------------------------------------------------------------------
put_zdle_char:
	ld (zdl_char),a			; save as character to send after a ZDLE
	ld bc,0009H			; nine characters get special treatment: ZDLE, DLE, XON, XOFF and CR (each also with
					; bit 7 set)
	ld hl,D12C1			; point HL at D12C1
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	and 60H				; other bytes: only control characters (bits 5-6 clear) can need escaping
	jr nz,L12A4			; if result is nonzero goto L12A4
	ld a,(escape_ctl_flag)		; receiver/sender asked for ALL control characters to be escaped (ESCCTL)?
	or a				; test A (sets Z if A = 0)
	jr z,L12A4			; if nonzero is zero/clear goto L12A4
; Send ZDLE followed by the character XOR 40H, then fall through to send it.
zdl_escape:
	ld hl,zdl_char			; point HL at character to send after a ZDLE
	set 6,(hl)			; escape: send ZDLE followed by the byte with bit 6 flipped
	ld a,ZDLE			; character to send: ZDLE/CAN
	call aux_putc_wait		; send A to the modem, waiting until the output is ready
L12A4:
	ld a,00H			; Byte to transmit
zdl_char		.equ L12A4+1	; character to send after a ZDLE (patched operand)

; ----------------------------------------------------------------------
; aux_putc_wait: Send A to the modem, waiting until the output is ready.
; ----------------------------------------------------------------------
aux_putc_wait:
	ld (aux_out_char),a		; save as character waiting to be sent to the modem
L12A9:
	call aux_poll_input		; poll the AUX device
	call aux_out_ready		; test whether the AUX output is ready
	jr z,L12A9			; if modem not ready for output goto L12A9
L12B1:
	ld a,00H			; Load character
aux_out_char		.equ L12B1+1	; character waiting to be sent to the modem (patched operand)
	jp aux_putc			; loop back to aux_putc
; CR is escaped only if the previous character sent was "@".
zdl_cr_rule:
	ld a,(aux_out_char)		; CR rule: the previous character sent ...
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp 40H				; ... was "@"? (a CR after "@" is escaped so Telenet is not triggered)
	jr nz,L12A4			; if A != 40H goto L12A4
	jr zdl_escape			; loop back to zdl_escape
D12C1:
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
; ----------------------------------------------------------------------
crc_init:
	xor a				; A = 0
	ld h,a				; H = A
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
L12F5:
	ld a,05H			; five CANs in a row mean "session cancelled" [zgethdr: cancount = 5]
	ld (hdr_can_count),a		; remaining CAN characters before abort = 05H
L12FA:
	ld b,0FFH			; wait up to 25.5 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jp c,L13A4			; if timed out waiting for the modem goto L13A4
	ld hl,D13B8			; point HL at D13B8
	ld bc,0003H			; 3 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L133E			; continue at L133E
hdr_got_zdle:
	ld hl,hdr_can_count		; point HL at remaining CAN characters before abort
	dec (hl)			; count down remaining CAN characters before abort
	ld a,ZCAN			; CAN limit reached: report ZCAN
	jp z,L13A4			; if remaining CAN characters before abort has run out goto L13A4
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,L12FA			; if timed out waiting for the modem goto L12FA
	ld hl,D13C1			; point HL at D13C1
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L133E			; continue at L133E
; A second ZDLE: count a CAN; five in a row return ZCAN.
hdr_zdle_zdle:
	ld hl,hdr_can_count		; point HL at remaining CAN characters before abort
	dec (hl)			; count down remaining CAN characters before abort
	ld a,ZCAN			; CRC-16 header: remember the CRC type
	jp z,L13A4			; if remaining CAN characters before abort has run out goto L13A4
	jr L12FA			; loop back to L12FA
; ZDLE then ZCRCW: wait briefly for one more character, otherwise return an error.
hdr_zdle_zcrcw:
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	jr c,L134F			; if timed out waiting for the modem goto L134F
L133E:
	ld hl,(hdr_junk_limit)		; get remaining number of junk characters tolerated
	dec hl				; HL--
	ld (hdr_junk_limit),hl		; save as remaining number of junk characters tolerated
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	ld a,0FCH			; junk limit reached: no header found
	jp z,L13A4			; if the 16-bit count is zero goto L13A4
	jp L12F5			; loop back to L12F5
L134F:
	ld a,0FFH			; Timeout error status
	jp L13A4			; continue at L13A4
hdr_got_zpad:
	ld a,05H			; A = 05H
	ld (hdr_can_count),a		; remaining CAN characters before abort = 05H
; Another ZPAD: keep waiting for ZDLE.
hdr_pad_loop:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	jr c,L13A4			; if timeout or error goto L13A4
	ld hl,D13C7			; point HL at D13C7
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L133E			; loop back to L133E
hdr_zpad_zdle:
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	jr c,L13A4			; if timeout or error goto L13A4
	ld hl,D13CD			; point HL at D13CD
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	jr L133E			; loop back to L133E
hdr_hex:
	ld a,10H			; CRC-16 header: remember the CRC type
	ld (rx_crc_mode),a		; CRC type of the last received header = 10H (CRC-16)
	call get_hex_header		; receive a hex-encoded header
	jr L1399			; continue at L1399
hdr_bin16:
	ld a,10H			; CRC format = 16-bit
	ld (rx_crc_mode),a		; CRC type of the last received header = 10H (CRC-16)
	call get_bin16_header		; receive a binary header with 16-bit CRC
	jr L1399			; continue at L1399
hdr_bin32:
	ld a,20H			; CRC-32 header (ZBIN32): remember the CRC type
	ld (rx_crc_mode),a		; CRC type of the last received header = 20H (CRC-32)
	call get_bin32_header		; receive a binary header with 32-bit CRC
L1399:
	push af				; preserve AF
	ld hl,rx_header_data		; point HL at four argument bytes of the last received header
	ld de,rx_pos_arg		; point DE at position argument of the last ZRPOS/ZACK from the
	call copy32			; copy rx_header_data to rx_pos_arg
	pop af				; restore AF
L13A4:
	ld hl,D13D9			; point HL at D13D9
	ld bc,0006H			; 6 keys in the table
	cpir				; look A up in the key table
	jr nz,L13B6			; if A is not in the key list goto L13B6
	cp GOTCAN			; Special error status?
	jr nz,L13B4			; if A != 98H goto L13B4
	ld a,ZCAN			; return ZCAN
L13B4:
	scf				; error/timeout/cancel: carry set
	ret				; return
L13B6:
	or a				; test A (sets Z if A = 0)
	ret				; return
D13B8:
	.db ZDLE,ZPAD+80H,ZPAD		; keys: ..*
	.dw hdr_got_zpad		; key 2AH ZPAD
	.dw hdr_got_zpad		; key 0AAH ZPAD (bit 7 set)
	.dw hdr_got_zdle		; key 18H ZDLE
D13C1:
	.db ZCRCW,ZDLE			; keys: k.
	.dw hdr_zdle_zdle		; key 18H ZDLE
	.dw hdr_zdle_zcrcw		; key 6BH ZCRCW after CAN: no header follows
D13C7:
	.db ZPAD,ZDLE			; keys: *.
	.dw hdr_zpad_zdle		; key 18H ZDLE
	.dw hdr_pad_loop		; key 2AH ZPAD
D13CD:
	.db ZBIN32,ZBIN,ZHEX,ZDLE	; keys: CAB.
	.dw hdr_got_zdle		; key 18H ZDLE
	.dw hdr_hex			; key 42H ZHEX (hex header)
	.dw hdr_bin16			; key 41H ZBIN (binary header, CRC-16)
	.dw hdr_bin32			; key 43H ZBIN32 (binary header, CRC-32)
D13D9:
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
	ld hl,rx_header_data		; point HL at four argument bytes of the last received header
	ld b,04H			; 4 bytes to read
L13F1:
	push bc				; preserve BC
	push hl				; preserve HL
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	ret c				; Return on error
	djnz L13F1			; repeat until all B items are done
	ld b,04H			; repeat count = 4
L1402:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc32_update		; update the running CRC-32 with byte A
	pop bc				; restore BC
	ret c				; Return on error
	djnz L1402			; repeat until all B items are done
	ld hl,crc32_value		; point HL at running CRC-32 accumulator
	ld de,crc32_residue		; point DE at CRC-32 residue 0DEBB20E3H expected after a good frame
	call eq32			; compare crc32_value with crc32_residue
	jr z,L144C			; if values are equal goto L144C
	jr L1450			; continue at L1450

; ----------------------------------------------------------------------
; get_bin16_header: Receive a binary header with 16-bit CRC. [zm.c zrbhdr]
; ----------------------------------------------------------------------
get_bin16_header:
	call crc_init			; reset CRC-16 to 0 and CRC-32 to 0FFFFFFFFH
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	ret c				; return: timeout, CAN or error
	ld (rx_frame_type),a		; save as frame type of the last header received
	call crc16_update		; update the running CRC-16
	ld hl,rx_header_data		; point HL at four argument bytes of the last received header
	ld b,04H			; 4 bytes to read
L142C:
	push bc				; preserve BC
	push hl				; preserve HL
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	ret c				; Return on error
	djnz L142C			; repeat until all B items are done
	ld b,02H			; repeat count = 2
L143D:
	push bc				; preserve BC
	call getc_zdl_filt		; get a modem char, ignore XON/XOFF and decode ZDLE
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	ret c				; Return on error
	djnz L143D			; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,L1450			; if the 16-bit count is not zero goto L1450
L144C:
	ld a,(rx_frame_type)		; get frame type of the last header received
	ret				; return
L1450:
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
	ld hl,rx_header_data		; point HL at four argument bytes of the last received header
	ld b,04H			; 4 bytes to read
L1466:
	push bc				; preserve BC
	push hl				; preserve HL
	call get_hex_byte		; receive two hex digits and combine them into a byte
	jr nc,L1470			; If valid hex, store byte
	pop hl				; restore HL
	pop bc				; restore BC
	ret				; return
L1470:
	call crc16_update		; update the running CRC-16
	pop hl				; restore HL
	pop bc				; restore BC
	ld (hl),a			; (HL) = A
	inc hl				; Advance pointer
	djnz L1466			; repeat until all B items are done
	ld b,02H			; 2 CRC-16 bytes (4 hex chars) to read
L147B:
	push bc				; preserve BC
	call get_hex_byte		; receive two hex digits and combine them into a byte
	jr nc,L1483			; If valid hex, process
	pop bc				; restore BC
	ret				; return
L1483:
	call crc16_update		; update the running CRC-16
	pop bc				; restore BC
	djnz L147B			; repeat until all B items are done
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr nz,L14A0			; if the 16-bit count is not zero goto L14A0
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	cp 0DH				; is it CR?
	jr nz,L149B			; if A is not CR goto L149B
	ld b,0AH			; wait up to 1.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
L149B:
	or a				; test A (sets Z if A = 0)
	ld a,(rx_frame_type)		; get frame type of the last header received
	ret				; return
L14A0:
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
	jr nz,L14BF			; if not zero goto L14BF
	rlca				; Shift low nibble to high nibble (A << 4)
	rlca				; rotate A left
	rlca				; rotate A left
	rlca				; rotate A left
	ld b,a				; B = high nibble shifted
	push bc				; preserve BC
	call getc_7bit_filt		; get a modem char, strip bit 7 and ignore
	pop bc				; restore BC
	ret c				; return: timeout or error
	call hex_digit_value		; convert an ASCII hex digit in A to 0-15
	jr nz,L14BF			; if not zero goto L14BF
	or b				; Combine high and low nibbles (A = high | low)
	ret				; return
L14BF:
	ld a,0FFH			; return code: error
	scf				; flag failure to caller (carry set)
	ret				; return

; ----------------------------------------------------------------------
; hex_digit_value: Convert an ASCII hex digit in A to 0-15.
; ----------------------------------------------------------------------
hex_digit_value:
	ld l,a				; Preserve char in L
	sub 30H				; Subtract '0' (30h)
	cp 0AH				; Is it a decimal digit ('0'..'9')?
	jr c,L14CC			; if A < 0AH goto L14CC
	sub 27H				; A -= 27H
L14CC:
	ld l,a				; Save result in L
	and 0F0H			; keep the high nibble
	ld a,l				; A = nibble value (0..15)
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
	ld hl,D14F6			; point HL at D14F6
	ld bc,0002H			; 2 keys in the table
	cpir				; look A up in the key table
	jr z,getc_7bit_filt		; if A is in the key list goto getc_7bit_filt
	ld bc,0003H			; 3 keys in the table
	cpir				; look A up in the key table
	ret z				; return: A is in the key list
	ld b,a				; Preserve character in B
	and 60H				; isolate bits 5-6: zero means a control character
	jr nz,L14F4			; if result is nonzero goto L14F4
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr nz,getc_7bit_filt		; if nonzero is set/nonzero goto getc_7bit_filt
L14F4:
	ld a,b				; Restore character in A
	ret				; return
D14F6:
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
	ld a,e				; Restore character
	ret nz				; return: result is nonzero
	cp ZDLE				; compare A with 18H (ZDLE/CAN)
	jr z,zdlread_escape		; if A = 18H goto zdlread_escape
	ld hl,D156E			; point HL at D156E
	ld bc,0004H			; 4 keys in the table
	cpir				; look A up in the key table
	jr z,getc_zdl_filt		; if A is in the key list goto getc_zdl_filt
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr nz,getc_zdl_filt		; if nonzero is set/nonzero goto getc_zdl_filt
	ld a,e				; Otherwise return raw control byte
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
	jr nz,L1540			; if A is not ZDLE/CAN goto L1540
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,L1540			; if A is not ZDLE/CAN goto L1540
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
	cp ZDLE				; is it ZDLE/CAN?
	jr nz,L1540			; if A is not ZDLE/CAN goto L1540
	ld b,64H			; wait up to 10.0 s
	call aux_getc_timeout		; get a character from the modem with timeout
	ret c				; return: timed out waiting for the modem
L1540:
	ld hl,D1572			; point HL at D1572
	ld bc,000BH			; 11 keys in the table
	cpir				; look A up in the key table
	jp z,dispatch			; if A is in the key list goto dispatch
	ld l,a				; Save byte in L
	ld a,(escape_ctl_flag)		; get nonzero
	or a				; test A (sets Z if A = 0)
	jr z,L1557			; if nonzero is zero/clear goto L1557
	ld a,l				; Check if control character
	and 60H				; isolate bits 5-6: zero means a control character
	jr z,zdlread_escape		; if result is zero goto zdlread_escape
L1557:
	ld a,l				; Load escaped byte
	and 60H				; isolate bits 5-6: zero means a control character
	cp 40H				; Escaped standard control character?
	jr nz,L1568			; if A != 40H goto L1568
	ld a,l				; Load byte
	xor 40H				; undo ZDLE escaping (flip bit 6)
	ret				; return
zdl_rub0:
	ld a,7FH			; Unescape to Rubout / DEL (7Fh)
	ret				; return
zdl_rub1:
	ld a,0FFH			; Unescape to 0FFh (Rubout | 80h)
	ret				; return
L1568:
	ld a,0FFH			; Framing error status
zdl_crc_end:
	or 80H				; set bit 7 (marks a received subpacket terminator)
	scf				; flag failure to caller (carry set)
	ret				; return
D156E:
	.db 11H,91H,13H,93H		; keys: ....
D1572:
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
D1593:
	.db 18H,18H,18H,18H,18H,18H,18H,18H,18H,18H,08H,08H,08H,08H,08H
	.db 08H,08H,08H,08H,08H,00H

; ----------------------------------------------------------------------
; send_can_string: Send eight+ CAN characters followed by backspaces to
; abort the peer. [canit]
; ----------------------------------------------------------------------
send_can_string:
	ld hl,D1593			; point HL at D1593

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
L15C7:
	call aux_wait_input		; wait roughly 100 ms-steps for an input character
	jr nz,L15D2			; if a character arrived goto L15D2
	djnz L15C7			; repeat until all B items are done
	ld a,0FEH			; Timeout status code (0FEh)
	scf				; flag failure to caller (carry set)
	ret				; return
L15D2:
	or a				; test A (sets Z if A = 0)
	ret				; return

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
	jr L165F			; continue at L165F

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
	jr nz,L15FF			; if A != 3AH goto L15FF
	inc hl				; Skip leading colon
L15FF:
	ld b,08H			; Up to 8 characters for filename primary field
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
	ld a,(hl)			; Check trailing delimiter character
	ld (parse_next_char),a		; save as character following the parsed name
	cp 3AH				; Was character a colon ':' (drive/user prefix)?
	jr nz,L1640			; if A != 3AH goto L1640
	inc hl				; Advance past colon
	ld a,(parse_mode)		; get parse_filespec argument
	or a				; test A (sets Z if A = 0)
	jr z,L1619			; if parse_filespec argument is zero/clear goto L1619
	call parse_du			; try to interpret a prefix as drive/user
	jr z,L1627			; if a valid DU: prefix was found goto L1627
L1619:
	call parse_named_dir		; try to interpret a prefix as a named directory
	jr z,L1627			; if a valid DIR: prefix was found goto L1627
	ld a,(parse_mode)		; get parse_filespec argument
	or a				; test A (sets Z if A = 0)
	jr nz,L1627			; if parse_filespec argument is set/nonzero goto L1627
	call parse_du			; try to interpret a prefix as drive/user
L1627:
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
L1640:
	ld a,(parse_next_char)		; get character following the parsed name
	ex de,hl			; swap pointers
	ld bc,0008H			; Advance HL past 8 filename bytes to extension
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld b,03H			; Extension length = 3 characters
	cp 2EH				; Is delimiter a dot '.'?
	jr nz,L1655			; if A != 2EH goto L1655
	inc hl				; Advance past dot
	push de				; preserve DE
	call parse_fcb_field		; copy up to B name characters, expanding "*" to "?"s
	pop de				; restore DE
L1655:
	ex de,hl			; swap pointers
	ld bc,0005H			; BC = 0005H
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld a,(parsed_user)		; get user number from the file spec
	ld (de),a			; Store user area into FCB extension
L165F:
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
	jr nz,L1675			; no: ordinary character
	ld a,3FH			; "*" fills the rest of the field with "?"
	ld (de),a			; (DE) = A
	call inc_wild_count		; note one wildcard
	jr L167C			; go and fill the remaining positions
L1675:
	ld (de),a			; store the character in the FCB
	inc hl				; advance in the source text
	cp 3FH				; is it "?" ?
	call z,inc_wild_count		; count it as a wildcard
L167C:
	djnz parse_fcb_field		; next character of the field
L167E:
	call is_delimiter		; field full: skip any extra characters of the name
	ret z				; return: character ends the name
	inc hl				; HL++
	jr L167E			; loop back to L167E

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
	jr z,L170C			; no: not a DU specification
	ex de,hl			; swap pointers
	inc hl				; Advance to filename
	call z3env_max_drive		; highest valid drive
	ld b,a				; B = filename length
	inc b				; B = number of valid drives
	ld a,(hl)			; first character of the spec
	cp 41H				; a drive letter ("A"-"P")?
	jr c,L16B6			; no: only a user number may follow
	sub 40H				; convert the letter to a drive number (A = 1)
	cp b				; is that drive valid?
	jr nc,L170C			; no: not a DU specification
	ld (parsed_drive),a		; remember the drive
	inc hl				; HL++
	ld a,(hl)			; next character
	cp 20H				; blank: spec is just the drive
	ret z				; return: A = 20H
	call digit_value		; a digit starts the user number
	ret c				; neither: stop here
L16B6:
	push hl				; try to read a user number (one or two digits)
	ld b,02H			; Check up to 2 user number digits
L16B9:
	ld a,(hl)			; A = (HL)
	cp 20H				; compare A with 20H (' ')
	jr z,L16CB			; if A = 20H goto L16CB
	call digit_value		; A = A-'0'
	jr c,L16DC			; not a number: give up
	inc hl				; HL++
	djnz L16B9			; repeat until all B items are done
	ld a,(hl)			; the digits must be followed by a blank
	cp 20H				; compare A with 20H (' ')
	jr nz,L16DC			; if A != 20H goto L16DC
L16CB:
	pop hl				; restore HL
	call z3env_max_user		; highest valid user number
	ld c,a				; C = A
	inc c				; C++
	call parse_decimal		; convert the digits
	cp c				; is the user number in range?
	jr nc,L170C			; no: reject
	ld (parsed_user),a		; remember the user number
	xor a				; Z = valid DU specification
	ret				; return
L16DC:
	pop hl				; restore HL
	jr L170C			; reject

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
	jr z,L170C			; none: not found
	ex de,hl			; swap pointers
	inc hl				; HL++
L16EE:
	ld a,(de)			; first byte of an entry: 0 ends the register
	or a				; test A (sets Z if A = 0)
	jr z,L170C			; end of the register: not found
	inc de				; skip the drive/user bytes
	inc de				; DE++
	push hl				; preserve HL
	push de				; preserve DE
	ld b,08H			; compare the 8-character name
L16F8:
	ld a,(de)			; A = (DE)
	cp (hl)				; Character match?
	jr nz,L1700			; if not zero goto L1700
	inc hl				; HL++
	inc de				; DE++
	djnz L16F8			; repeat until all B items are done
L1700:
	pop de				; restore DE
	pop hl				; restore HL
	jr z,L170F			; all eight characters matched: found
	ex de,hl			; not this entry: step to the next one (16 bytes)
	ld bc,0010H			; Advance to next 16-byte template entry
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	jr L16EE			; loop back to L16EE
L170C:
	or 0FFH				; NZ = name not found
	ret				; return
L170F:
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
	jr c,L173A			; if A < 21H goto L173A
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
L173A:
	xor a				; return 0 (success)
	ret				; return

; ----------------------------------------------------------------------
; parse_decimal: Parse a decimal user number.
; ----------------------------------------------------------------------
parse_decimal:
	push bc				; preserve BC
	ld bc,1100H			; B = loop limit, C = accumulator (0)
L1740:
	ld a,(hl)			; Load next character
	call is_delimiter		; Z if A ends a file name token
	jr z,L1760			; if character ends the name goto L1760
	inc hl				; Advance pointer
	call digit_value		; A = A-'0'
	jr c,L1764			; if not a decimal digit goto L1764
	ld d,a				; D = digit value
	ld a,c				; Multiply accumulator C by 10 (C * 8 + C * 2)
	rlca				; rotate A left
	jr c,L1764			; if not a decimal digit goto L1764
	rlca				; rotate A left
	jr c,L1764			; if not a decimal digit goto L1764
	add a,c				; A += C
	jr c,L1764			; if not a decimal digit goto L1764
	rlca				; rotate A left
	jr c,L1764			; if not a decimal digit goto L1764
	add a,d				; Add new digit value
	jr c,L1764			; if not a decimal digit goto L1764
	ld c,a				; Update accumulator
	djnz L1740			; repeat until all B items are done
L1760:
	ld a,c				; A = parsed binary user number
	pop bc				; restore BC
	or a				; Clear carry (success)
	ret				; return
L1764:
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
	jp L17AB			; continue at L17AB

; ----------------------------------------------------------------------
; z3env_max_drive: Read the highest valid drive (offset 2CH) from the
; ZCPR3 environment descriptor.
; ----------------------------------------------------------------------
z3env_max_drive:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_MDRV_OFF		; DE = 002CH
	jp L17AB			; continue at L17AB

; ----------------------------------------------------------------------
; z3env_max_user: Read the highest valid user number (offset 2DH) from the
; ZCPR3 environment descriptor.
; ----------------------------------------------------------------------
z3env_max_user:
	push hl				; preserve HL
	push de				; preserve DE
	ld de,Z3_MUSR_OFF		; DE = 002DH
	jp L17AB			; continue at L17AB

; ----------------------------------------------------------------------
; z3env_ndr_ptr: Get the named directory register address (offset 15H)
; from the ZCPR3 environment descriptor; its entry count is at 17H.
; ----------------------------------------------------------------------
z3env_ndr_ptr:
	push de				; preserve DE
	ld de,Z3_NDR_OFF		; DE = 0015H
	jp L17B8			; continue at L17B8
L17AB:
	ld hl,(z3env_ptr)		; get address of the ZCPR3 environment descriptor
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L17B3			; if the 16-bit count is zero goto L17B3
	add hl,de			; Add field offset to base
L17B3:
	ld a,(hl)			; Fetch byte from descriptor
	pop de				; restore DE
	pop hl				; restore HL
	or a				; Set condition flags
	ret				; return
L17B8:
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
	jp L17E0			; continue at L17E0

; ----------------------------------------------------------------------
; build_flist_alt: Same as build_file_list, but a file listed in
; several extents keeps its HIGHEST extent (dir_dup_mode = 0).
; ----------------------------------------------------------------------
build_flist_alt:
	push de				; preserve DE
	ld (dir_attr_mask),a		; save as selection mask
	call dir_table_init		; prepare the directory table at HL
	call dir_collect_00		; collect matching directory entries
L17E0:
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
	jr z,L1853			; if sort key is zero/clear goto L1853
	ld bc,FCB_EXT			; Offset to extension (+9)
	add hl,bc			; HL points to extension of first FCB
	ex de,hl			; swap pointers
	add hl,bc			; HL points to extension of second FCB
	ex de,hl			; swap pointers
	ld b,03H			; Compare 3-character extension
	call compare_mem		; compare B bytes at HL and DE
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,L1851			; if names differ goto L1851
	push hl				; preserve HL
	push de				; preserve DE
	inc hl				; Point to filename (+1)
	inc de				; DE++
	ld b,08H			; Compare 8-character filename
	call compare_mem		; compare B bytes at HL and DE
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,L1851			; if names differ goto L1851
	push hl				; preserve HL
	push de				; preserve DE
	ld bc,FCB_EX			; BC = 000CH
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	add hl,bc			; HL += BC
	ex de,hl			; swap pointers
	ld a,(de)			; A = (DE)
	cp (hl)				; compare A with (HL)
L184B:
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,L1851			; if not zero goto L1851
	ld a,(de)			; Compare drive/user byte
	cp (hl)				; compare A with (HL)
L1851:
	pop bc				; restore BC
	ret				; return
L1853:
	inc hl				; Advance past drive byte to filename (+1)
	inc de				; DE++
	ld b,0CH			; B = 0CH
	call compare_mem		; compare B bytes at HL and DE
	jr L184B			; loop back to L184B

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
	jr L1892			; continue at L1892
L188B:
	call dir_add_entry		; take directory entry number A
	jr z,L18A5			; if entry added goto L18A5
	ld c,F_SNEXT			; BDOS function: F_SNEXT
L1892:
	ld de,dir_search_fcb		; point DE at wildcard FCB used for BDOS search first/next
	call BDOS			; F_SNEXT: search for the next match
	cp 0FFH				; 0FFh = no more directory entries
	jr nz,L188B			; if A != FFH goto L188B
	or 0FFH				; A |= 0FFH
L189E:
	ld bc,(dir_entry_count)		; get number of directory entries collected
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
L18A5:
	xor a				; A = 0
	jr L189E			; loop back to L189E

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
	jr z,L18E5			; if A = E5H goto L18E5
	cp 21H				; Greater than 32 (user 0..31)?
	jr nc,L18E5			; if A >= 21H goto L18E5
	call dir_find_dup		; look for the same user + file name
	jr z,L18E5			; if duplicate entry found goto L18E5
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
	jr nz,L18E5			; If memory remains, continue
	xor a				; A = 0
L18E4:
	ld hl,0FFF6H			; Dummy instruction (never executed directly)
L18E5			.equ L18E4+1	; alternate entry point inside the instruction above (overlapping decode: or 0FFH)
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
	jr z,L1934			; If table empty, file is unique (NZ)
	ld hl,(dir_table_start)		; get start of the directory entry table
L18F8:
	push bc				; preserve BC
	push hl				; preserve HL
	push de				; preserve DE
	ld b,0CH			; Compare 12 bytes (user, filename, and extension)
	call compare_mem		; compare B bytes at HL and DE
	pop de				; restore DE
	pop hl				; restore HL
	jr nz,L192A			; if names differ goto L192A
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
	jr nc,L1920			; if no carry goto L1920
	ld a,(dir_dup_mode)		; get file seen in several extents
	or a				; test A (sets Z if A = 0)
	jr nz,L1926			; if file seen in several extents is set/nonzero goto L1926
L1918:
	ex de,hl			; swap pointers
	ld bc,0010H			; 16 bytes
	ldir				; copy the block
	jr L1926			; continue at L1926
L1920:
	ld a,(dir_dup_mode)		; get file seen in several extents
	or a				; test A (sets Z if A = 0)
	jr nz,L1918			; if file seen in several extents is set/nonzero goto L1918
L1926:
	pop bc				; restore BC
	xor a				; A = 0
	pop hl				; restore HL
	ret				; return
L192A:
	ld bc,0010H			; Advance to next 16-byte table entry
	add hl,bc			; HL += BC
	pop bc				; restore BC
	dec bc				; Decrement entries remaining
	ld a,b				; A = B
	or c				; A |= C
	jr nz,L18F8			; Continue checking remaining entries
L1934:
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
L1947:
	pop bc				; restore BC
	ld a,b				; Any entries remaining?
	or c				; A |= C
	jr z,L1971			; If all processed, finish
	dec bc				; Decrement loop counter
	push bc				; preserve BC
	bit 7,(hl)			; Check if entry was marked (bit 7 set)
	jr z,L196B			; If not marked, skip entry
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
	jr L1947			; loop back to L1947
L196B:
	ld bc,0010H			; Advance past unmarked 16-byte entry
	add hl,bc			; HL += BC
	jr L1947			; loop back to L1947
L1971:
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
L19D3:
	pop bc				; restore BC
	ld a,b				; Any entries remaining?
	or c				; A |= C
	jr z,L1A06			; If done, exit
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
	jr nz,L1A00			; if names differ goto L1A00
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
	jr nz,L1A00			; if names differ goto L1A00
	call dir_check_attr		; does the entry pass the selection mask? A DIR file
	jr nz,L1A00			; if not zero goto L1A00
	set 7,(hl)			; Mark entry as matched (set bit 7 of user byte)
L1A00:
	ld bc,0010H			; Advance to next 16-byte table entry
	add hl,bc			; HL += BC
	jr L19D3			; loop back to L19D3
L1A06:
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
	jr z,L1A21			; If DIR file (not SYS), branch
	bit 6,a				; test bit 6 of A
	jr nz,L1A25			; If SYS allowed, check user area
L1A1E:
	or 0FFH				; A |= 0FFH
	ret				; return
L1A21:
	bit 7,a				; test bit 7 of A
	jr z,L1A1E			; If DIR files excluded, reject
L1A25:
	bit 5,a				; test bit 5 of A
	jr nz,L1A2E			; If all users allowed, accept
	xor (hl)			; Compare user area byte
	and 3FH				; Mask user area (0..31)
	jr nz,L1A1E			; if result is nonzero goto L1A1E
L1A2E:
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
	jr z,L1A7B			; if the 16-bit count is zero goto L1A7B
	ld b,h				; BC = item count N
	ld c,l				; C = L
	add hl,hl			; HL = N * 2 (size of 16-bit pointer array)
	jr c,L1A7B			; Overflow check
	add hl,de			; End of pointer array
	jr c,L1A7B			; Overflow check
	ex de,hl			; swap pointers
	ld hl,(BDOSVEC)			; get BDOSVEC
	sbc hl,de			; Ensure pointer array fits below BDOS top of RAM
	jr c,L1A7B			; if carry goto L1A7B
	ld hl,(sort_blk_base)		; get working copy of sort block
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L1A5A			; if the 16-bit count is zero goto L1A5A
	ex de,hl			; swap pointers
L1A5A:
	push de				; preserve DE
	ld hl,(sort_index_ptr)		; get pointer to the sort index array
L1A5E:
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
	jr nz,L1A5E			; Loop until all pointers stored
	pop hl				; restore HL
	ld (sort_blk_base),hl		; save as working copy of sort block
	push hl				; preserve HL
	call sort_prm_restore		; copy the working sort control block back to the caller
	pop hl				; restore HL
	dec a				; Decrement status
L1A78:
	pop de				; restore DE
	pop bc				; restore BC
	ret				; return
L1A7B:
	xor a				; Clear A (failure status)
	ld hl,(sort_index_ptr)		; get pointer to the sort index array
	jr L1A78			; loop back to L1A78

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
	jr z,L1AF1			; if sort block flag is zero/clear goto L1AF1
	ld a,(sort_blk_flag2)		; get sort block second flag
	or a				; test A (sets Z if A = 0)
	jr nz,L1AF1			; if sort block second flag is set/nonzero goto L1AF1
	ld hl,(sort_blk_count)		; get ... element count
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L1AF1			; if the 16-bit count is zero goto L1AF1
	ld (sort_i),hl			; save as sort loop index i
	ld hl,0000H			; Initialize item index
	ld (sort_j),hl			; save as sort loop index j
L1AAA:
	ld hl,(sort_i)			; get sort loop index i
	dec hl				; HL--
	ld a,h				; test whether HL is zero (first half)
	or l				; A = H or L: zero only if HL = 0
	jr z,L1AF1			; if the 16-bit count is zero goto L1AF1
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
	jr nc,L1AAA			; If already in place, continue
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
L1ADE:
	ld a,(hl)			; Search for next item in permutation cycle
	inc hl				; HL++
	cp e				; compare A with E
	inc hl				; HL++
	jr nz,L1ADE			; if not zero goto L1ADE
	dec hl				; HL--
	ld a,(hl)			; A = (HL)
	inc hl				; HL++
	cp d				; compare A with D
	jr nz,L1ADE			; if not zero goto L1ADE
	pop de				; restore DE
	dec hl				; HL--
	ld (hl),d			; Update permutation link
	dec hl				; HL--
	ld (hl),e			; (HL) = E
	jr L1AAA			; loop back to L1AAA
L1AF1:
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
	jr nz,L1B11			; if sort block flag is set/nonzero goto L1B11
	call sort_elem_adr_de		; HL and DE become the addresses of items HL and DE

; ----------------------------------------------------------------------
; sort_copy_ents: Swap the contents of two complete items (item-size
; bytes each) at addresses HL and DE.
; ----------------------------------------------------------------------
sort_copy_ents:
	ld bc,(sort_blk_size)		; get ... element size
	jr L1B1B			; continue at L1B1B
	pop de				; restore DE
	pop hl				; restore HL
	ret				; return
L1B11:
	call sort_index_addr		; HL = address of index entry HL
	ex de,hl			; swap pointers
	dec hl				; Offset adjustment
	add hl,hl			; HL = (index 2 - 1) * 2
	add hl,bc			; HL = pointer 2 address in pointer table
	ld bc,0002H			; Size of 16-bit word = 2 bytes
L1B1B:
	ld a,(de)			; Swap bytes between (DE) and (HL)
	ldi				; Copy (HL) to (DE), increment both, decrement BC
	dec hl				; Back up HL
	ld (hl),a			; Store original (DE) byte into (HL)
	inc hl				; Advance HL
	jp pe,L1B1B			; Loop until BC reaches 0 (parity even = PE)
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
	jr nc,L1B4A			; If small size, use shift/add multiply
	ld a,10H			; 16-bit shift/add loop counter
L1B3C:
	add hl,hl			; Shift product left
	ex de,hl			; swap pointers
	add hl,hl			; Shift multiplier left
	ex de,hl			; swap pointers
	jr nc,L1B43			; If bit not set, skip add
	add hl,bc			; Add multiplicand to product
L1B43:
	dec a				; Decrement bit counter
	jr nz,L1B3C			; Loop for all 16 bits
	jr L1B4E			; continue at L1B4E
L1B48:
	dec bc				; Decrement multiplicand
	add hl,de			; Repeated addition multiply
L1B4A:
	ld a,b				; Multiplicand reaches 0?
	or c				; A |= C
	jr nz,L1B48			; Loop until multiplied
L1B4E:
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
	jr nz,L1B66			; if sort block flag is set/nonzero goto L1B66
	call sort_elem_adr_de		; HL and DE become the addresses of items HL and DE
	jr L1B76			; continue at L1B76
L1B66:
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
L1B76:
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
L1B8B:
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
	jr L1B8B			; loop back to L1B8B

; ----------------------------------------------------------------------
; sort_shell: Shell sort of the index. The gap starts at N/2 made odd and
; is halved each pass; items are compared with the sort callback and
; swapped with sort_swap.
; ----------------------------------------------------------------------
sort_shell:
	ld hl,(sort_blk_count)		; get ... element count
	ld (sort_j),hl			; save as sort loop index j
L1BA0:
	ld hl,(sort_j)			; get sort loop index j
	srl h				; Shift right 1 bit
	rr l				; rotate right through carry L
	ld a,l				; Is gap == 0?
	or h				; A |= H
	ret z				; If gap == 0, sort is complete!
	bit 0,l				; Is gap odd?
	jr nz,L1BAF			; If odd, keep it
	dec hl				; If even, decrement to make odd (classic Shell sort optimization)
L1BAF:
	ld (sort_j),hl			; save as sort loop index j
	ld (sort_i),hl			; save as sort loop index i
L1BB5:
	ld hl,(sort_i)			; get sort loop index i
	inc hl				; HL++
	ld (sort_i),hl			; save as sort loop index i
	ex de,hl			; swap pointers
	ld hl,(sort_blk_count)		; get ... element count
	or a				; Clear Carry
	sbc hl,de			; Count - index
	jr c,L1BA0			; If index > count, reduce gap
L1BC5:
	ld hl,(sort_j)			; get sort loop index j
	ex de,hl			; swap pointers
	sbc hl,de			; Inner index -= gap
	jr c,L1BB5			; If below start, advance outer index
	jr z,L1BB5			; if zero goto L1BB5
	ex de,hl			; swap pointers
	add hl,de			; HL = inner index + gap
	call sort_compare		; call the caller's compare routine with HL and DE = the
	jr nc,L1BB5			; If in order, advance outer index
	call sort_swap			; swap items HL and DE
	jr L1BC5			; loop back to L1BC5

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
	jr nz,L1C72			; if result is nonzero goto L1C72
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
	jr nz,L1C72			; if open failed goto L1C72
	call file_read_sector		; read the next 128-byte record of the current file
	ld a,04H			; Error code 4 (read failed)
	jr nz,L1C72			; If read failed, exit
L1C5F:
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
L1C72:
	jp L1D52			; continue at L1D52

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
	jr nz,L1C72			; if result is nonzero goto L1C72
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
	jr z,L1C5F			; if file ready goto L1C5F
	ld a,05H			; Error code 5 (create failed)
	jr L1C72			; loop back to L1C72

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
	jr z,L1D11			; if result is zero goto L1D11
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; Advance to buffer data pointer (+2)
	inc hl				; HL++
	ld e,(hl)			; DE = current buffer data pointer
	inc hl				; HL++
	ld d,(hl)			; D = (HL)
	ld a,d				; Pointer null?
	or e				; A |= E
	ld a,04H			; Error 4 (buffer empty / EOF)
	jr z,L1D11			; Exit if null
	ld a,(de)			; Fetch byte from buffer
	ld (file_io_char),a		; save as character passed through file get/put
	inc de				; Advance buffer pointer
	ld (hl),d			; Save updated pointer
	dec hl				; HL--
	ld (hl),e			; (HL) = E
	dec hl				; Point to remaining byte counter
	dec (hl)			; Decrement byte counter
	jr nz,L1CD5			; If bytes remain, return saved byte
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
	jr z,L1CD5			; If refilled successfully, continue
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	inc hl				; HL++
	inc hl				; HL++
	ld (hl),00H			; (HL) = 00H
	inc hl				; HL++
	ld (hl),00H			; (HL) = 00H
L1CD5:
	ld a,(file_io_char)		; get character passed through file get/put
	cp a				; compare A with A
	jr L1D12			; continue at L1D12

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
	jr z,L1D11			; if result is zero goto L1D11
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
	jr nz,L1CD5			; If sector not full, return success
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
	jr z,L1CD5			; If written successfully, continue
	ld a,02H			; Error 2 (write error / disk full)
L1D11:
	or a				; test A (sets Z if A = 0)
L1D12:
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
	jr z,L1D52			; if result is zero goto L1D52
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	jr L1D40			; continue at L1D40

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
	jr z,L1D52			; if result is zero goto L1D52
	ld (cur_file_ptr),hl		; save as pointer to the file object being operated on
	inc hl				; Check sector byte count
	ld a,(hl)			; A = (HL)
	cp 80H				; Is sector buffer empty (count == 128)?
	jr z,L1D40			; if A = 80H goto L1D40
	ld a,1AH			; Pad with CP/M EOF character (Ctrl-Z = 1Ah)
	call file_putc_a		; put byte A to the output file
L1D35:
	ld a,(hl)			; Check sector byte count
	cp 80H				; Reached sector boundary?
	jr z,L1D40			; if A = 80H goto L1D40
	xor a				; Pad remainder of sector with 00h
	call file_putc_a		; put byte A to the output file
	jr L1D35			; loop back to L1D35
L1D40:
	ld hl,(cur_file_ptr)		; get pointer to the file object being operated on
	ld (hl),00H			; Mark buffer as closed
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	inc hl				; HL++
	ex de,hl			; swap pointers
	call fcb_close			; close the file
	ld a,06H			; Error code 6 (close failed)
	jr nz,L1D52			; if close failed goto L1D52
	xor a				; Return success (A = 0)
L1D52:
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
	jr L1D82			; continue at L1D82

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
L1D82:
	push af				; preserve AF
	ld hl,0080H			; Restore default DMA buffer address (0080h)
	call set_dma			; set the DMA address to DE
	pop af				; restore AF
	or a				; Set flags
	ret				; return

; ----------------------------------------------------------------------
; get_drive_user: Return current drive in B and user in C.
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
	ld c,a				; C = user area (0..31)
	pop af				; restore AF
	ld b,a				; B = drive number (0..15)
	pop hl				; restore HL
	pop de				; restore DE
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; get_file_size: Get the file size (BDOS F_SIZE).
; ----------------------------------------------------------------------
get_file_size:
	ld a,F_SIZE			; BDOS function 35 (F_SIZE): compute the file size in records
	jr L1DA9			; continue at L1DA9

; ----------------------------------------------------------------------
; get_rand_record: Get the random record number (BDOS F_RANDREC).
; ----------------------------------------------------------------------
get_rand_record:
	ld a,F_RANDREC			; BDOS function 36 (F_RANDREC): set the random record number from the sequential
					; position
L1DA9:
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
L1DFE:
	ld (hl),d			; Zero byte (D = 0)
	inc hl				; Advance pointer
	dec e				; Decrement loop counter
	jr nz,L1DFE			; Loop until all 21 bytes cleared
	pop af				; restore AF
	pop de				; restore DE
	pop hl				; restore HL
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
	jr z,L1E45			; if A = 20H goto L1E45
	ld (hl),a			; Store printable character into output buffer
	inc hl				; Advance output pointer
L1E45:
	inc de				; Advance source pointer
	djnz copy_name_part		; repeat until all B items are done
	ret				; return

; ----------------------------------------------------------------------
; a_to_decimal: Convert A to up to three decimal digits at DE.
; ----------------------------------------------------------------------
a_to_decimal:
	push bc				; preserve BC
	ld b,00H			; B = 00H
	jp L1E52			; continue at L1E52
	push bc				; preserve BC
	ld b,0FFH			; B = 0FFH
L1E52:
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
L1E67:
	sub h				; Subtract divisor
	inc l				; Increment quotient
	jr nc,L1E67			; Continue until underflow
	add a,h				; Restore remainder
	ld h,a				; Save remainder in H
	ld a,l				; A = quotient
	or a				; Is quotient zero?
	jr nz,decimal_emit		; if result is nonzero goto decimal_emit
	or b				; A |= B
	ld a,h				; A = remainder
	ret m				; If B negative, return
	ld a,20H			; Output space for suppressed zero (' ')
	jr z,L1E7C			; if result is zero goto L1E7C
	xor a				; A = 0

; ----------------------------------------------------------------------
; decimal_emit: Store one decimal digit.
; ----------------------------------------------------------------------
decimal_emit:
	add a,30H			; Convert digit 0..9 to ASCII '0'..'9'
	ld b,a				; B non-zero (ends suppression)
L1E7C:
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
L1E82:
	ld a,(hl)			; Fetch character
	or a				; Check for null terminator
	jr z,L1E8D			; if result is zero goto L1E8D
	call to_upper			; convert A to upper case
	ld (hl),a			; Store converted character back
	inc hl				; Advance string pointer
	jr L1E82			; loop back to L1E82
L1E8D:
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
	jr z,L1E9B			; if result is zero goto L1E9B
	call is_space			; Z if A is a blank/control separator
	jr z,skip_blanks_str		; if character is blank/whitespace goto skip_blanks_str
L1E9B:
	dec hl				; Point back to terminator
	pop af				; restore AF
	ret				; return

; ----------------------------------------------------------------------
; skip_to_blank: Advance HL to the next blank.
; ----------------------------------------------------------------------
skip_to_blank:
	push af				; preserve AF
L1E9F:
	ld a,(hl)			; Fetch character
	inc hl				; Advance pointer
	or a				; Null terminator?
	jr z,L1E9B			; if result is zero goto L1E9B
	call is_space			; Z if A is a blank/control separator
	jr nz,L1E9F			; If printable, continue
	jr L1E9B			; loop back to L1E9B

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
L1EB4:
	call skip_blanks		; find the start of the next token
	or a				; end of text?
	jr z,L1EDD			; yes: done
	ld (hl),e			; store the token address in the table
	inc hl				; HL++
	ld (hl),d			; Store token pointer high byte
	inc hl				; HL++
	dec b				; one more slot used
	jr z,L1ED2			; table full
	call skip_token			; skip over the token
	or a				; End of command line?
	jr z,L1EDD			; end of text
	ld a,c				; Delimiter replacement enabled?
	or a				; terminate the token?
	jr z,L1ECE			; if result is zero goto L1ECE
	xor a				; Replace whitespace with null terminator
	ld (de),a			; replace the delimiter by a zero
	inc de				; Advance past null
L1ECE:
	ld a,b				; more slots free?
	or a				; test A (sets Z if A = 0)
	jr nz,L1EB4			; yes: next token
L1ED2:
	call skip_token			; table full: see whether more text remains
	call skip_blanks		; skip spaces and tabs at DE
	or a				; End of line?
	jr z,L1EDD			; if result is zero goto L1EDD
	or 0FFH				; NZ = too many arguments
L1EDD:
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
L1F0A:
	ld (hl),a			; Store byte into buffer
	inc hl				; Advance pointer
	djnz L1F0A			; repeat until all B items are done
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
	jr c,L1F1F			; if A < 41H goto L1F1F
	cp 5BH				; compare A with 5BH
	jr c,L1F20			; if A < 5BH goto L1F20
L1F1F:
	or 0AFH				; A |= 0AFH
L1F20			.equ L1F1F+1	; alternate entry point inside the instruction above (overlapping decode: xor a)
	ld a,c				; Restore original character in A
	pop bc				; restore BC
	ret				; return

; ----------------------------------------------------------------------
; is_space: Z if A is a blank/control separator.
; ----------------------------------------------------------------------
is_space:
	push af				; preserve AF
	and 7FH				; strip the parity bit (7-bit ASCII)
	jr z,L1F39			; if result is zero goto L1F39
	cp 7FH				; DEL (rubout)?
	jr z,L1F39			; if A = 7FH goto L1F39
	cp 20H				; Space?
	jr z,L1F39			; if A = 20H goto L1F39
	cp 08H				; Backspace or lower?
	jr c,L1F3C			; if A < 08H goto L1F3C
	cp 0EH				; Tab, LF, VT, FF, CR (8..13)?
	jr nc,L1F3C			; if A >= 0EH goto L1F3C
L1F39:
	pop af				; restore AF
	cp a				; compare A with A
	ret				; return
L1F3C:
	pop af				; restore AF
	or a				; test A (sets Z if A = 0)
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
	jr z,L1F65			; if A = 3FH goto L1F65
	ld c,a				; C = pattern character
	ld a,(de)			; Fetch target character
	and 7FH				; strip the parity bit (7-bit ASCII)
	cp c				; Compare characters
	ret nz				; return if not zero
L1F65:
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
; Pointer to the argument table built by tokenize_args
argv_ptr:
	.dw 28DCH
	.fill 6,0

; ---- Uninitialised RAM work area above the program image ----
; .ds only reserves space: nothing here is stored in the .COM file.
	.ds 128				; 1F80H-1FFFH not referenced by the code
default_user		.ds 1		; 2000H User number at program start
default_drive		.ds 1		; 2001H Drive (1 = A:) at program start
saved_user		.ds 1		; 2002H User number to select (pair with work_fcb drive byte)
work_fcb		.ds 36		; 2003H Work FCB / DU pair for the command line file spec
stack_area		.ds 64		; 2027H Stack: grows down from aux_ring (SP is set to aux_ring at start)
aux_ring		.ds 6		; 2067H AUX receive ring buffer control block: count, write index, read index; 512 data
					; bytes follow (also initial stack top)
aux_ring_data		.ds 512		; 206DH Data area of the AUX receive ring (512 bytes)
entry_user		.ds 1		; 226DH User number of the current file list entry
send_fcb		.ds 36		; 226EH FCB of the file being sent
send_fcb_name		.equ send_fcb+1	; 226FH Name field of send_fcb
	.ds 1				; 2292H not referenced by the code
ltoa_value		.ds 4		; 2293H ltoa32: working copy of the value being converted
ltoa_temp		.ds 4		; 2297H ltoa32: temporary subtraction result
crc32_value		.ds 4		; 229BH Running CRC-32 accumulator (4 bytes)
crc32_table		.ds 1024	; 229FH CRC-32 lookup table, 256 x 4 bytes (229FH-269EH)
error_count		.ds 1		; 269FH Consecutive error/retry counter
rx_header_data		.ds 4		; 26A0H Four argument bytes of the last received header
pos_display		.ds 4		; 26A4H Copy of the file position shown on the console
rx_crc_mode		.ds 1		; 26A8H CRC type of the last received header (10H = CRC-16, 20H = CRC-32)
tx_crc_mode		.ds 1		; 26A9H CRC type used for sending: 20H = CRC-32, 10H = CRC-16 (XMODEM CRC)
tx_header_data		.ds 4		; 26AAH Four argument bytes for the next header to send
xm_first_flag		.ds 1		; 26AEH FFH until the first block has been acknowledged
zack_pos		.ds 4		; 26AFH Position from the last ZACK
rx_pos_arg		.ds 4		; 26B3H Position argument of the last ZRPOS/ZACK from the receiver
tx_position		.ds 4		; 26B7H Position in the file of the next byte to send (32 bits)
last_sync_pos		.ds 4		; 26BBH Position at the last synchronisation point (ZCRCW)
last_zrpos_pos		.ds 4		; 26BFH Position of the last ZRPOS request
file_read_pos		.ds 4		; 26C3H Position of the next byte to be read from the disk file
pos_scratch		.ds 4		; 26C7H Scratch 32-bit result for position arithmetic
rx_window_size		.ds 2		; 26CBH Receiver buffer length from ZRINIT ZP0/ZP1 (0 = nonstop I/O) [Rxbuflen]
window_remaining	.ds 2		; 26CDH Bytes left before the receiver must acknowledge
subpacket_size		.ds 2		; 26CFH Current data subpacket size (starts at 1024, reduced after errors)
	.ds 2				; 26D1H-26D2H not referenced by the code
same_zrpos_count	.ds 1		; 26D3H Number of times in a row ZRPOS asked for the same position
zrinit_zf0		.ds 1		; 26D4H ZF0 from the receiver's ZRINIT: CANFDX 1, CANOVIO 2, CANBRK 4, CANCRY 8,
					; CANFC32 20H, ESCCTL 40H
escape_ctl_flag		.ds 1		; 26D5H Nonzero (40H) if all control characters must be escaped
eof_pending		.ds 1		; 26D6H FFH when the end of the file has been read into the buffer
eof_flag		.ds 1		; 26D7H FFH when the disk file is at end of file
subpkt_term		.ds 1		; 26D8H Terminator for the next data subpacket (68H ZCRCE, 69H ZCRCG, 6BH ZCRCW)
files_sent_count	.ds 1		; 26D9H Number of files sent so far
buffer_mask		.ds 2		; 26DAH File buffer size mask (power of two minus one)
buffer_start_pos	.ds 4		; 26DCH File position corresponding to the start of the ring buffer
last_rx_char		.ds 1		; 26E0H Last character received from the modem
xmodem_block_no		.ds 1		; 26E1H Current XMODEM block number
prev_rx_char		.ds 1		; 26E2H Previous received character
file_size		.ds 2		; 26E3H Size of the current file in bytes (32 bits)
file_size_hi		.ds 2		; 26E5H High word of file_size (the 32-bit size is built in two halves)
block_len		.ds 2		; 26E7H Length of the current block / subpacket
	.ds 2				; 26E9H-26EAH not referenced by the code
opt_protect_flag	.ds 1		; 26EBH FFH if -p (protect) was given
opt_append_flag		.ds 1		; 26ECH FFH if -a (append) was given
opt_convert_flag	.ds 1		; 26EDH FFH if -c (convert to local line feeds) was given
opt_binary_flag		.ds 1		; 26EEH FFH if -b (binary) was given
file_buffer_base	.ds 2		; 26EFH Start of the file data ring buffer
unused_26F1		.ds 2		; 26F1H Cleared at startup, never read
file_buffer_size	.ds 2		; 26F3H Size of the file data ring buffer
unused_26F5		.ds 2		; 26F5H Cleared at startup, never read
file_count		.ds 1		; 26F7H Number of files in the list to send
zrqinit_retries		.ds 1		; 26F8H Remaining attempts to get ZRINIT
resp_junk_count		.ds 1		; 26F9H Garbage characters seen while streaming
zrpos_target		.ds 4		; 26FAH Position requested by ZRPOS
reposition_temp		.ds 4		; 26FEH Temporary position used while repositioning the file
chunk_len		.ds 4		; 2702H Number of bytes in the current chunk
data_terminator		.ds 1		; 2706H Terminator byte of the data subpacket being sent
out_frame_type		.ds 1		; 2707H Frame type of the header being sent
hdr_junk_limit		.ds 2		; 2708H get_header: remaining number of junk characters tolerated
hdr_can_count		.ds 1		; 270AH get_header: remaining CAN characters before abort
rx_frame_type		.ds 1		; 270BH Frame type of the last header received
parse_mode		.ds 1		; 270CH parse_filespec argument (nonzero: try DU form / named directory)
parse_next_char		.ds 1		; 270DH Character following the parsed name
wildcard_count		.ds 1		; 270EH Number of wildcard characters in the file name
parsed_drive		.ds 1		; 270FH Drive from the file spec (0 = default)
parsed_user		.ds 1		; 2710H User number from the file spec
z3env_ptr		.ds 2		; 2711H Address of the ZCPR3 environment descriptor (0 if none)
sort_key_flag		.ds 1		; 2713H Sort key: 0 = name then extension, 1 = extension first
dir_search_fcb		.ds 36		; 2714H Wildcard FCB used for BDOS search first/next
dir_dup_mode		.ds 1		; 2738H File seen in several extents: 0 = keep the highest extent, nonzero = keep the
					; lowest
dir_table_start		.ds 2		; 2739H Start of the directory entry table (16 bytes per entry)
dir_entry_count		.ds 2		; 273BH Number of directory entries collected
dir_marked_count	.ds 2		; 273DH Number of entries marked / kept
dir_table_ptr		.ds 2		; 273FH Pointer into the directory table (also sort block base)
sort_count		.ds 2		; 2741H Sort control block: element count
sort_elem_size		.ds 2		; 2743H Sort control block: element size (16)
sort_compare_fn		.ds 2		; 2745H Sort control block: compare routine address
sort_aux		.ds 2		; 2747H Sort control block: auxiliary pointer
sort_limit		.ds 2		; 2749H Sort control block: limit (00FFH)
dpb_bsh			.ds 3		; 274BH Disk parameter block: BSH, BLM, EXM
disk_blocks		.ds 2		; 274EH Number of allocation blocks on the disk
dir_entries		.ds 2		; 2750H Number of directory entries on the disk
dir_attr_mask		.ds 1		; 2752H Selection mask: bit 7 include DIR files, bit 6 include SYS files, bit 5 any
					; user number, bits 0-4 user number
sort_blk_ptr		.ds 2		; 2753H Pointer to the caller's sort control block
sort_blk_base		.ds 2		; 2755H Working copy of sort block: base address
sort_blk_count		.ds 2		; 2757H ... element count
sort_blk_size		.ds 2		; 2759H ... element size
sort_blk_cmp		.ds 2		; 275BH ... compare function
sort_index_ptr		.ds 2		; 275DH Pointer to the sort index array
sort_blk_flag		.ds 1		; 275FH Sort block flag (indirect elements)
sort_blk_flag2		.ds 1		; 2760H Sort block second flag
sort_i			.ds 2		; 2761H Sort loop index i
sort_j			.ds 2		; 2763H Sort loop index j
in_file			.ds CIO_SIZE	; 2765H Input file object: open flag, count, pointer, 36-byte FCB, 128-byte buffer (168
					; bytes)
out_file		.ds CIO_SIZE	; 280DH Output file object (same layout as in_file)
cur_file_ptr		.ds 2		; 28B5H Pointer to the file object being operated on
file_io_char		.ds 1		; 28B7H Character passed through file get/put
fcb_copy		.ds 36		; 28B8H Scratch copy of a 36-byte FCB
	.end
