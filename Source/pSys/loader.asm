;===============================================================================
; LOADER.ASM
;
; BOOTLOADER FOR ROMWBW PSYSTEM
;
; CP/M DISK FORMATS ALLOW FOR RESERVED TRACKS THAT CONTAIN AN IMAGE OF THE
; OPERATING SYSTEM TO BE LOADED WHEN THE DISK IS BOOTED.  THE OPERATING SYSTEM
; IMAGE ITSELF IS NORMALLY PREFIXED BY A 1-N SECTORS CONTAINING OS BOOTSTRAP
; CODE AND DISK METADATA.
;
; THE RETROBREW COMPUTING GROUP HAS BEEN USING A CONVENTION OF PREFIXING THE
; OS IMAGE WITH 3 SECTORS (512 BYTES X 3 FOR A TOTAL OF 1536 BYTES):
;
;   SECTOR 1: IBM-PC STYLE BOOT BLOCK CONTAINING BOOTSTRAP, 
;             PARTITION TABLE, AND BOOT SIGNATURE
;   SECTOR 2: RESERVED
;   SECTOR 3: METADATA
;
; THE HARDWARE BIOS IS EXPECTED TO READ AND LOAD THE FIRST TWO SECTORS FROM THE
; DISK TO MEMORY ADDRESS $8000 AND JUMP TO THAT LOCATION TO BEGIN THE BOOT
; PROCESS.  THE BIOS IS EXPECTED TO VERIFY THAT A STANDARD BOOT SIGNATURE
; OF $55, $AA IS PRESENT AT OFFSET $1FE-$1FF.  IF THE SIGNATURE IS NOT FOUND,
; THE BIOS SHOULD ASSUME THE DISK HAS NOT BEEN PROPERLY INITIALIZED AND SHOULD
; NOT JUMP TO THE LOAD ADDRESS.
;
;===============================================================================
;
#INCLUDE "../ver.inc"
;
#INCLUDE "psys.inc"
;
SYS_ENT		.EQU	$0100		; SYSTEM (OS) ENTRY POINT ADDRESS
SYS_LOC		.EQU	$0100		; STARTING ADDRESS TO LOAD SYSTEM IMAGE
SYS_END		.EQU	$0100 + loader_size + bios_size + boot_size		; ENDING ADDRESS OF SYSTEM IMAGE
;
SEC_SIZE	.EQU	512		; DISK SECTOR SIZE
BLK_SIZE	.EQU	128		; OS BLOCK/RECORD SIZE
;
PREFIX_SIZE	.EQU	(SEC_SIZE * 3)	; 3 SECTORS
;
META_SIZE	.EQU	32		; SEE BELOW
META_LOC	.EQU	(PREFIX_SIZE - META_SIZE)
;
PT_LOC		.EQU	$1BE
PT_SIZ		.EQU	$40
;
		.ORG	0
;
;-------------------------------------------------------------------------------
; SECTOR 1
;
;   THIS SECTOR FOLLOWS THE CONVENTIONS OF AN IBM-PC MBR CONTAINING THE OS
;   BOOTSTRAP CODE, PARTITION TABLE, AND BOOT SIGNATURE
;
;----------------------------------------------------------------------------
;
	.FILL	PT_LOC - $,0		; FILL TO START OF PARTITION TABLE
;
; STANDARD IBM-PC PARTITION TABLE.  ALTHOUGH A
; PARTITION TABLE IS NOT RELEVANT FOR A FLOPPY DISK, IT DOES NO HARM.
; THE CONTENTS OF THE PARTITION TABLE CAN BE MANAGED BY FDISK80.
;
; BELOW WE ALLOW FOR 32 SLICES OF ROMWBW CP/M FILESYSTEMS
; FOLLOWED BY A FAT16 PARTITION.  THE SLICES FOLLOW THE ORIGINAL
; HD512 ROMWBW FORMAT.  IF THE DISK IS USING HD1K, A SEPARATE
; PARTITION TABLE WILL BE IN PLACE AND RENDER THIS PARTITION TABLE
; IRRELEVANT.
;
; THE CYL/SEC FIELDS ENCODE CYLINDER AND SECTOR AS:
;	CCCCCCCC:CCSSSSSS
;	76543210:98543210
;
PART0:
	.DB	0			; ACTIVE IF $80
	.DB	0			; CHS START ADDRESS (HEAD)
	.DW	0			; CHS START ADDRESS (CYL/SEC)
	.DB	0			; PART TYPE ID
	.DB	0			; CHS LAST ADDRESS (HEAD)
	.DW	0			; CHS LAST ADDRESS (CYL/SEC)
	.DW	0,0			; LBA FIRST (DWORD)
	.DW	0,0			; LBA COUNT (DWORD)
PART1:
	.DB	0			; ACTIVE IF $80
	.DB	0			; CHS START ADDRESS (HEAD)
	.DW	%1111111111000001	; CHS START ADDRESS (CYL/SEC)
	.DB	6			; PART TYPE ID
	.DB	15			; CHS LAST ADDRESS (HEAD)
	.DW	%1111111111010000	; CHS LAST ADDRESS (CYL/SEC)
	.DW	$4000,$0010		; LBA FIRST (DWORD)
	.DW	$0000,$000C		; LBA COUNT (DWORD)
PART2:
	.DB	0			; ACTIVE IF $80
	.DB	0			; CHS START ADDRESS (HEAD)
	.DW	0			; CHS START ADDRESS (CYL/SEC)
	.DB	0			; PART TYPE ID
	.DB	0			; CHS LAST ADDRESS (HEAD)
	.DW	0			; CHS LAST ADDRESS (CYL/SEC)
	.DW	0,0			; LBA FIRST (DWORD)
	.DW	0,0			; LBA COUNT (DWORD)
PART3:
	.DB	0			; ACTIVE IF $80
	.DB	0			; CHS START ADDRESS (HEAD)
	.DW	0			; CHS START ADDRESS (CYL/SEC)
	.DB	0			; PART TYPE ID
	.DB	0			; CHS LAST ADDRESS (HEAD)
	.DW	0			; CHS LAST ADDRESS (CYL/SEC)
	.DW	0,0			; LBA FIRST (DWORD)
	.DW	0,0			; LBA COUNT (DWORD)
;
; THE END OF THE FIRST SECTOR MUST CONTAIN THE TWO BYTE BOOT SIGNATURE.
;
BOOTSIG	.DB	$55,$AA			; STANDARD BOOT SIGNATURE
;
;-------------------------------------------------------------------------------
; SECTOR 2
;
;   THIS SECTOR HAS NOT BEEN DEFINED AND IS RESERVED.
;
;----------------------------------------------------------------------------
;
	.FILL	SEC_SIZE,0			; JUST FILL SECTOR WITH ZEROES
;
;-------------------------------------------------------------------------------
; SECTOR 3
;
;   OS AND DISK METADATA
;
;----------------------------------------------------------------------------
;
	.FILL	(BLK_SIZE * 3),0	; FIRST 384 BYTES ARE NOT YET DEFINED
;
; THE FOLLOWING TWO BYTES ARE AN ADDITIONAL SIGNATURE THAT IS VERIFIED BY
; SOME HARDWARE BIOSES.
;
PR_SIG		.DB	$5A,$A5		; SIGNATURE GOES HERE
;
		.FILL	(META_LOC - $),0
;
; METADATA
;
PR_WP		.DB	0		; (1) WRITE PROTECT BOOLEAN
PR_UPDSEQ	.DW	0		; (2) PREFIX UPDATE SEQUENCE NUMBER (DEPRECATED?)
PR_VER		.DB	RMJ,RMN,RUP,RTP	; (4) OS BUILD VERSION
PR_LABEL	.DB	"Unlabeled$$$$$$$","$"	; (17) DISK LABEL (EXACTLY 16 BYTES!!!)
		.DW	0		; (2) DEPRECATED
PR_LDLOC	.DW	SYS_LOC		; (2) ADDRESS TO START LOADING SYSTEM
PR_LDEND	.DW	SYS_END		; (2) ADDRESS TO STOP LOADING SYSTEM
PR_ENTRY	.DW	SYS_ENT		; (2) ADDRESS TO ENTER SYSTEM (OS)
;
#IF (META_SIZE != ($ - META_LOC))
	.ECHO "META_SIZE VALUE IS WRONG!!!\r\n"
	!!!
#ENDIF
;
#IF ($ != PREFIX_SIZE)
	.ECHO "LOADER PREFIX IS WRONG SIZE!!!\r\n"
	!!!
#ENDIF
;
;-------------------------------------------------------------------------------
; SECTOR 4+
;
;   PSYSTEM LOADER
;    - LOAD SBIOS TO HIGH MEMORY (JUST BELOW HBIOS PROXY)
;    - LOAD PSYSTEM BOOTSTRAP & JUMP TO IT
;
;----------------------------------------------------------------------------
;
#include "../HBIOS/hbios.inc"
;
;
bel	.equ	7	; ASCII bell
bs	.equ	8	; ASCII backspace
lf	.equ	10	; ASCII linefeed
cr	.equ	13	; ASCII carriage return
;
interp_base	.equ	$0100		; first loc used by the interpreter
low_memory	.equ	$0100		; lowest available ram location
interleave	.equ	1		; interleaving factor (n:1)
first_track	.equ	1		; first interleaved track
skew		.equ	0		; track-to-track skew
;
;
;
	.org	loader_loc
;
	ld	sp,stack		; setup private stack
;
	call	nl2			; formatting
	ld	hl,str_banner		; display boot banner
	call	pstr			; do it
;
; Copy BIOS to running location
;
	ld	hl,loader_end		; BIOS image is at end of loader
	ld	de,bios_loc		; BIOS execution location
	ld	bc,bios_size		; Size of BIOS
	ldir				; do it
;
; Copy p-System bootstrap to running location
;
	ld	hl,loader_end + bios_size	; bootstrap appended after BIOS
	ld	de,boot_loc			; bootstrap runs here
	ld	bc,boot_size			; size of bootstrap code
	ldir					; do it
;
; Print some interesting info
;
	call	nl2			; spacing
	ld	hl,str_info		; info string
	call	pstr			; print it
	ld	bc,bios_loc		; bios location adr
	call	prthexword		; print it
	ld	hl,str_info2		; additional info string
	call	pstr			; print it
	ld	bc,boot_loc		; bootstrap location adr
	call	prthexword		; print it
;
; Push key values onto the stack
;
	ld	hl,seclen	; maximum number of bytes per sector
	push	hl                
	ld	hl,sectors	; maximum number of sectors in table
	push	hl                
	ld	hl,skew		; track-to-track skew
	push	hl                
	ld	hl,first_track	; first interleaved track
	push	hl                
	ld	hl,interleave	; interleaving factor
	push	hl                
	ld	hl,seclen	; bytes per sector
	push	hl                
	ld	hl,sectors	; sectors per track
	push	hl                
	ld	hl,tracks	; tracks per disk
	push	hl
	ld	hl,bios_loc-2	; top word of available ram - sbios address-2
	push	hl                
	ld	hl,low_memory	; bottom word of available ram
	push	hl                
	ld	hl,bios_loc	; address of BIOS (start of jump table)
	push	hl                
	ld	hl,interp_base	; starting address of the interpreter
	push	hl
#ifdef TESTBIOS
	ld	hl,disks-1	; maximum (highest) disk drive number
	push	hl
#endif
;
	jp	boot_loc	; jump to bootloader
;
	ret
;
;
; Print string at HL on console, null terminated
;
pstr:
	ld	a,(hl)			; get next character
	or	a			; set flags
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	jr	pstr			; loop till done
;
; Print volume label string at HL, '$' terminated, 16 chars max
;
pvol:
	ld	b,16			; init max char downcounter
pvol1:
	ld	a,(hl)			; get next character
	cp	'$'			; set flags
	inc	hl			; bump pointer regardless
	ret	z			; done if null
	call	cout			; display character
	djnz	pvol1			; loop till done
	ret				; hit max of 16 chars
;
; Start a newline on console (cr/lf)
;
nl2:
	call	nl			; double newline
nl:
	ld	a,cr			; cr
	call	cout			; send it
	ld	a,lf			; lf
	jp	cout			; send it and return
;
; Print a dot on console
;
pdot:
	push	af
	ld	a,'.'
	call	cout
	pop	af
	ret
;
; Print the hex byte value in A
;
prthexbyte:
	push	af
	push	de
	call	hexascii
	ld	a,d
	call	cout
	ld	a,e
	call	cout
	pop	de
	pop	af
	ret
;
; Print the hex word value in BC
;
prthexword:
	push	af
	ld	a,b
	call	prthexbyte
	ld	a,c
	call	prthexbyte
	pop	af
	ret
;
; Convert binary value in A to ASCII hex characters in DE
;
hexascii:
	ld	d,a
	call	hexconv
	ld	e,a
	ld	a,d
	rlca
	rlca
	rlca
	rlca
	call	hexconv
	ld	d,a
	ret
;
; Convert low nibble of A to ASCII hex
;
hexconv:
	and	0Fh	     ; low nibble only
	add	a,90h
	daa
	adc	a,40h
	daa
	ret
;
; Output character from A
;
cout:
	; Save all incoming registers
	push	af
	push	bc
	push	de
	push	hl
;
	; Output character to console via HBIOS
	ld	e,a			; output char to E
	ld	c,CIO_CONSOLE		; console unit to C
	ld	b,BF_CIOOUT		; HBIOS func: output char
	rst	08			; HBIOS outputs character
;
	; Restore all registers
	pop	hl
	pop	de
	pop	bc
	pop	af
	ret
;
; Input character to A
;
cin:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Input character from console via hbios
	ld	c,CIO_CONSOLE		; console unit to c
	ld	b,BF_CIOIN		; HBIOS func: input char
	rst	08			; HBIOS reads character
	ld	a,e			; move character to A for return
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
; Return input status in A (0 = no char, != 0 char waiting)
;
cst:
	; Save incoming registers (AF is output)
	push	bc
	push	de
	push	hl
;
	; Get console input status via HBIOS
	ld	c,CIO_CONSOLE		; console unit to C
	ld	b,BF_CIOIST		; HBIOS func: input status
	rst	08			; HBIOS returns status in A
;
	; Restore registers (AF is output)
	pop	hl
	pop	de
	pop	bc
	ret
;
str_banner	.db	"RomWBW HBIOS p-System Loader v"
		.db	BIOSVER
		.db	0
str_info	.db	"Loading pSystem BIOS @ 0x",0
str_info2	.db	", Bootstrap @ 0x",0
;
	.fill	32,0
stack	.equ	$
;
	.fill	loader_end - $
;
	.end
