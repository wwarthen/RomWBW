;--------------------------------------------------------
; cbioshc.s derived from CPM22-HC.ASM by dwg 5/18-30/2011
;--------------------------------------------------------
	.module cbioshc
	.optsdcc -mz80
;--------------------------------------------------------
; Public variables in this module
;--------------------------------------------------------
	.globl _cbioshc
;--------------------------------------------------------
; special function registers
;--------------------------------------------------------
;--------------------------------------------------------
;  ram data
;--------------------------------------------------------
	.area _DATA
;--------------------------------------------------------
; overlayable items in  ram 
;--------------------------------------------------------
	.area _OVERLAY
;--------------------------------------------------------
; external initialized ram data
;--------------------------------------------------------
;--------------------------------------------------------
; global & static initialisations
;--------------------------------------------------------
	.area _HOME
	.area _GSINIT
	.area _GSFINAL
	.area _GSINIT
;--------------------------------------------------------
; Home
;--------------------------------------------------------
	.area _HOME
	.area _HOME
;--------------------------------------------------------
; code
;--------------------------------------------------------
	.area _CBIOS
_cbioshc_start::
_cbioshc:

;**************************************************************
;*
;*        C B I O S  f o r
;*
;*  T e s t   P r o t o t y p e
;* 
;*  by Andrew Lynch, with input from many sources
;* Updated  24-Mar-2009 Max Scane - changed seldsk: to not save bogus drive value
;* changed a: to be ram drive, B: to be rom disk
;* Updated 1-Jun-2010 Max Scane - Changed DPBs to be more sane
;* Updated 1-Jul-2010 Max Scane - Added PPIDE driver and conditionals
;* Updated April 2011 Max Scane - Adapted for the N8VEM Home Computer
;**************************************************************
;
;	SKELETAL CBIOS FOR FIRST LEVEL OF CP/M 2.0 ALTERATION
;             WITH MODS FOR CP/M  ROMDISK AND RAMDISK.
;
;             ENTIRELY IN 8080 MNEUMONICS (SO ASM CAN BE USED)
;             BUT ASSUMES A Z80! (remove)
;

MEM = 60 ; DOUGTEMP DOUGTEMP


;MSIZE	.EQU	20			;CP/M VERSION MEMORY SIZE IN KILOBYTES
;MSIZE	.EQU	62			;CP/M VERSION MEMORY SIZE IN KILOBYTES
; MEM defined in CPM22 above, line 0015

MSIZE = MEM	;CP/M VERSION MEMORY SIZE IN KILOBYTES

;
;	"BIAS" IS ADDRESS OFFSET FROM 3400H FOR MEMORY SYSTEMS
;	THAN 16K (REFERRED TO AS "B" THROUGHOUT THE TEXT).
;

BIAS = (MSIZE-20)*1024

CCP = 0x3400+BIAS	; base of ccp

BDOS = CCP+0x0806	; base of BDOS

BIOS = CCP+0x1600	; base of BIOS

CDISK = 0x0004		; current disk number 0=a,...,15=p

; IOBYTE already defined in CPM22 above, line 0017
;IOBYTE	.EQU	0003H			;INTEL I/O BYTE

; since the assembly has been broken into pieces,
; this symbols wasn't previously encountered.
; It could be exported from other module, but why?
IOBYTE = 0x0003

;
;	CONSTANTS


END = 0x0FF


CR = 0x0d
LF = 0x0a

DEFIOB = 0x94		; default IOBYTE (TTY,RDR,PUN,LPT)

;

ROMSTART_MON = 0x0100		; where the monitor is stored in ROM

RAMTARG_MON = 0x0f800		; where the monitor starts in RAM

MOVSIZ_MON = 0x0800		; monitor is 2K in length

ROMSTART_CPM = 0x0900		; where ccp+bdos+bios is stored in ROM

RAMTARG_CPM = 0x0D400		; where ccp+bdos+bios starts in RAM

;dwg; INTERESTING - 0x15FF is 4K+1K+512-1, not 5KB
;dwg;MOVSIZ_CPM:		.EQU	$15FF	; CCP, BDOS IS 5KB IN LENGTH
MOVSIZ_CPM = 0x15FF		; ccp+bdos is 5KB in length

HC_REG_BASE = 0x80		; N8 I/I Regs $80-9F

PPI1 = HC_REG_BASE+0x00

ACR = HC_REG_BASE+0x14

RMAP = ACR+2

IO_REG_BASE = 0x40		; IO reg base offset for Z1x80

CNTLA0 = IO_REG_BASE+0x00

CNTLB0 = IO_REG_BASE+0x02

STAT0 = IO_REG_BASE+0x04

TDR0 = IO_REG_BASE+0x06

RDR0 = IO_REG_BASE+0x08

ASEXT0 = IO_REG_BASE+0x12

CBR = IO_REG_BASE+0x38

BBR = IO_REG_BASE+0x39

CBAR = IO_REG_BASE+0x3A

;
;
; PIO 82C55 I/O IS ATTACHED TO THE FIRST IO BASE ADDRESS

IDELSB = PPI1+0 ; LSB

IDEMSB = PPI1+1 ; MSB

IDECTL = PPI1+2 ; Control Signals

PIO1CONT = PPI1+3 ; Control Byte PIO 82C55

; PPI control bytes for read and write to IDE drive

rd_ide_8255 = 0b10010010	; ide_8255_ctl out ide_8255_lsb/msb input

wr_ide_8255 = 0b10000000	; all three ports output

;ide control lines for use with ide_8255_ctl.  Change these 8
;constants to reflect where each signal of the 8255 each of the
;ide control signals is connected.  All the control signals must
;be on the same port, but these 8 lines let you connect them to
;whichever pins on that port.

ide_a0_line = 0x01		; direct from 8255 to ide interface

ide_a1_line = 0x02		; direct from 8255 to  ide intereface

ide_a2_line = 0x04		; direct from 8255 to ide interface

ide_cs0_line = 0x08		; inverter between 8255 and ide interface

ide_cs1_line = 0x10		; inverter between 8255 and ide interface

ide_wr_line = 0x20		; inverter between 8255 and ide interface

ide_rd_line = 0x40		; inverter between 8255 and ide interface

ide_rst_line = 0x80		; inverter between 8255 and ide interface

;------------------------------------------------------------------
; More symbolic constants... these should not be changed, unless of
; course the IDE drive interface changes, perhaps when drives get
; to 128G and the PC industry will do yet another kludge.

;some symbolic constants for the ide registers, which makes the
;code more readable than always specifying the address pins

ide_data    = ide_cs0_line
ide_err     = ide_cs0_line + ide_a0_line
ide_sec_cnt = ide_cs0_line + ide_a1_line
ide_sector  = ide_cs0_line + ide_a1_line + ide_a0_line
ide_cyl_lsb = ide_cs0_line + ide_a2_line
ide_cyl_msb = ide_cs0_line + ide_a2_line + ide_a0_line
ide_head    = ide_cs0_line + ide_a2_line + ide_a1_line
ide_command = ide_cs0_line + ide_a2_line + ide_a1_line + ide_a0_line
ide_status  = ide_cs0_line + ide_a2_line + ide_a1_line + ide_a0_line
ide_control = ide_cs1_line + ide_a2_line + ide_a1_line
ide_astatus = ide_cs1_line + ide_a2_line + ide_a1_line + ide_a0_line

;IDE Command Constants.  These should never change.

ide_cmd_recal    = 0x10
ide_cmd_read     = 0x20
ide_cmd_write    = 0x30
ide_cmd_init     = 0x91
ide_cmd_id       = 0x0ec
ide_cmd_spindown = 0xe0
ide_cmd_spinup   = 0xe1


;	.ORG	BIOS			;ORIGIN OF THIS PROGRAM


;dwg;NSECTS	.EQU	($-CCP)/128		;WARM START SECTOR COUNT

;
;	JUMP VECTOR FOR INDIVIDUAL SUBROUTINES

	JP	BOOT	;COLD START
WBOOTE:	JP	WBOOT	;WARM START
	JP	CONST	;CONSOLE STATUS
	JP	CONIN	;CONSOLE CHARACTER IN
	JP	CONOUT	;CONSOLE CHARACTER OUT
	JP	LIST	;LIST CHARACTER OUT (NULL ROUTINE)
	JP	PUNCH	;PUNCH CHARACTER OUT (NULL ROUTINE)
	JP	READER	;READER CHARACTER OUT (NULL ROUTINE)
	JP	HOME	;MOVE HEAD TO HOME POSITION
	JP	SELDSK	;SELECT DISK
	JP	SETTRK	;SET TRACK NUMBER
	JP	SETSEC	;SET SECTOR NUMBER
	JP	SETDMA	;SET DMA ADDRESS
	JP	READ	;READ DISK
	JP	WRITE	;WRITE DISK
	JP	LISTST	;RETURN LIST STATUS (NULL ROUTINE)
	JP	SECTRN	;SECTOR TRANSLATE

;
;   FIXED DATA TABLES FOR ALL DRIVES
;   0= RAMDISK, 1=ROMDISK, 2=HDPART1, 3=HDPART2
;   DISK PARAMETER HEADER FOR DISK 00 (RAM Disk)
DPBASE:	
	.DW	0x0000,0x0000
	.DW	0x0000,0x0000
	.DW	DIRBF,DPBLK0
	.DW	CHK00,ALL00

;   DISK PARAMETER HEADER FOR DISK 05	(Large ROM Disk)
	.DW	0x0000,0x0000
	.DW	0x0000,0x0000
	.DW	DIRBF,DPBLK5
	.DW	CHK05,ALL05


;   DISK PARAMETER HEADER FOR DISK 02 (8MB disk Partition)
	.DW	0x0000,0x0000
	.DW	0x0000,0x0000
	.DW	DIRBF,DPBLK2
	.DW	CHK02,ALL02

;   DISK PARAMETER HEADER FOR DISK 03 (8MB disk Partition)
	.DW	0x0000,0x0000
	.DW	0x0000,0x0000
	.DW	DIRBF,DPBLK3
	.DW	CHK03,ALL03

;   DISK PARAMETER HEADER FOR DISK 04 (??? third disk partition ???)
	.DW	0x0000,0x0000
	.DW	0x0000,0x0000
	.DW	DIRBF,DPBLK4
	.DW	CHK04,ALL04

DPBLK0:			;DISK PARAMETER BLOCK (RAMDISK 512K, 448K usable)
SPT_1:	.DW 	256	; 256 SECTORS OF 128 BYTES PER 32K TRACK
BSH_1:	.DB 	4 	; BLOCK SHIFT FACTOR (SIZE OF ALLOCATION BLOCK)
BLM_1: 	.DB 	15 	; PART OF THE ALLOCATION BLOCK SIZE MATH
EXM_1: 	.DB 	1 	; DEFINES SIZE OF EXTENT (DIRECTORY INFO)
DSM_1: 	.DW 	223 	; BLOCKSIZE [2048] * NUMBER OF BLOCKS + 1 = DRIVE SIZE
DRM_1: 	.DW 	255 		; NUMBER OF DIRECTORY ENTRIES
AL0_1: 	.DB 	0b11110000  	; BIT MAP OF SPACE ALLOCATED TO DIRECTORY
AL1_1: 	.DB 	0b00000000  	; DIRECTORY CAN HAVE UP TO 16 BLOCKS ALLOCATED
CKS_1: 	.DW 	0   		; SIZE OF DIRECTORY CHECK [0 IF NON REMOVEABLE]
OFF_1: 	.DW 	2   		; 2 TRACK RESERVED [FIRST 64K OF RAM]
; Note: changed to 2 tracks to skip over the 1st 64KB or RAM.

DPBLK1:	;DISK PARAMETER BLOCK (ROMDISK 32KB WITH 16 2K TRACKS, 22K usable)
SPT_0:	.DW 	16	; 16 SECTORS OF 128 BYTES PER 2K TRACK
BSH_0:	.DB 	3 	; BLOCK SHIFT FACTOR (SIZE OF ALLOCATION BLOCK)
BLM_0:	.DB 	7 	; PART OF THE ALLOCATION BLOCK SIZE MATH
EXM_0:	.DB 	0 	; DEFINES SIZE OF EXTENT (DIRECTORY INFO)
DSM_0:	.DW 	31 	; BLOCKSIZE [1024] * NUMBER OF BLOCKS + 1 = DRIVE SIZE
DRM_0:	.DW 	31 	; NUMBER OF DIRECTORY ENTRIES
AL0_0:	.DB 	0b10000000  	; BIT MAP OF SPACE ALLOCATED TO DIRECTORY
AL1_0:	.DB 	0b00000000  	; DIRECTORY CAN HAVE UP TO 16 BLOCKS ALLOCATED
CKS_0:	.DW 	0 		; SIZE OF DIRECTORY CHECK [0 IF NON REMOVEABLE]
OFF_0:	.DW 	5 	  	; FIRST 5 TRACKS TRACKS RESERVED (10K FOR SYSTEM)
	; SYSTEM IS ROM LOADER, CCP, BDOS, CBIOS, AND MONITOR
	;
	; IMPORTANT NOTE: TRACKS $00 - $04 OF 2K BYTES
	; EACH ARE MARKED WITH THE OFF_0 SET TO 5 AS 
	; SYSTEM TRACKS. USABLE ROM DRIVE SPACE
	; STARTING AFTER THE FIFTH TRACK (IE, TRACK $05)
	; MOST LIKELY FIX TO THIS IS PLACING A DUMMY
	; FIRST 10K ROM CONTAINS THE ROM LOADER, MONITOR,
 	; CCP, BDOS, BIOS, ETC (5 TRACKS * 2K EACH)


DPBLK2:			;DISK PARAMETER BLOCK (IDE HARD DISK 8MB)
SPT_2:	.DW 	256	; 256 SECTORS OF 128 BYTES PER 32K TRACK
BSH_2:	.DB 	5 	; BLOCK SHIFT FACTOR (SIZE OF ALLOCATION BLOCK)
BLM_2: 	.DB 	31 	; PART OF THE ALLOCATION BLOCK SIZE MATH
EXM_2: 	.DB 	1 	; DEFINES SIZE OF EXTENT (DIRECTORY INFO)
DSM_2: 	.DW 	2039 	; BLOCKSIZE [4096] * NUMBER OF BLOCKS + 1 = DRIVE SIZE
			; HD PARTITION 2 IS 16128 SECTORS LONG
			; AT 512 BYTES EACH WHICH IS 
			; 2016 BLOCKS AT 4096 BYTES A PIECE.
DRM_2: 	.DW 	511 	; NUMBER OF DIRECTORY ENTRIES
AL0_2: 	.DB 	0b11110000  	; BIT MAP OF SPACE ALLOCATED TO DIRECTORY
AL1_2: 	.DB 	0b00000000  	; DIRECTORY CAN HAVE UP TO 16 BLOCKS ALLOCATED
CKS_2: 	.DW 	0 	 	; SIZE OF DIRECTORY CHECK [0 IF NON REMOVEABLE]
OFF_2: 	.DW 	1 	  	; 1 TRACK (32K) RESERVED FOR SYSTEM

DPBLK3:			;DISK PARAMETER BLOCK (IDE HARD DISK 8MB)
SPT_3:	.DW 	256 	; 256 SECTORS OF 128 BYTES PER 32K TRACK
BSH_3:	.DB 	5 	; BLOCK SHIFT FACTOR (SIZE OF ALLOCATION BLOCK)
BLM_3: 	.DB 	31 	; PART OF THE ALLOCATION BLOCK SIZE MATH
EXM_3: 	.DB 	1 	; DEFINES SIZE OF EXTENT (DIRECTORY INFO)
DSM_3: 	.DW 	2039 ; BLOCKSIZE [4096] * NUMBER OF BLKS + 1 = DRIVE SIZE
			; HD PARTITION 3 IS 16128 SECTORS LONG
			; AT 512 BYTES EACH WHICH IS 
			; 2016 BLOCKS AT 4096 BYTES A PIECE.
DRM_3: 	.DW 	511 	; NUMBER OF DIRECTORY ENTRIES
AL0_3: 	.DB 	0b11110000  	; BIT MAP OF SPACE ALLOCATED TO DIRECTORY
AL1_3: 	.DB 	0b00000000  	; DIRECTORY CAN HAVE UP TO 16 BLOCKS ALLOCATED
CKS_3: 	.DW 	0 	; SIZE OF DIRECTORY CHECK [0 IF NON REMOVEABLE]
OFF_3: 	.DW 	1 	; 1 TRACK (32K) RESERVED FOR SYSTEM

DPBLK4:			;DISK PARAMETER BLOCK (IDE HARD DISK 1024K)
SPT_4:	.DW 	256	; 256 SECTORS OF 128 BYTES PER 32K TRACK
BSH_4:	.DB 	4 	; BLOCK SHIFT FACTOR (SIZE OF ALLOCATION BLOCK)
BLM_4: 	.DB 	15 	; PART OF THE ALLOCATION BLOCK SIZE MATH
EXM_4: 	.DB 	0 	; DEFINES SIZE OF EXTENT (DIRECTORY INFO)
DSM_4: 	.DW 	497 ; BLKSIZE [2048] * NUMBER OF BLKS + 1 = DRIVE SIZE
			; HD PARTITION 4 IS 4032 SECTORS LONG
			; AT 512 BYTES EACH WHICH IS 
			; 1008 BLOCKS AT 2048 BYTES A PIECE.
		; NOT USING ALL OF THE AVAILABLE SECTORS SINCE THIS
		; DRIVE IS INTENDED TO EMULATE A ROM DRIVE AND COPIED
		; INTO A ROM IN THE FUTURE.
DRM_4: 	.DW 	255 	    ; NUMBER OF DIRECTORY ENTRIES
AL0_4: 	.DB 	0b11110000  ; BIT MAP OF SPACE ALLOCATED TO DIRECTORY
AL1_4: 	.DB 	0b00000000  ; DIRECTORY CAN HAVE UP TO 16 BLOCKS ALLOCATED
CKS_4: 	.DW 	0 	    ; SIZE OF DIRECTORY CHECK [0 IF NON REMOVEABLE]
OFF_4: 	.DW 	1 	    ; 1 TRACK RESERVED [FIRST 32K OF PARTITION]

;
DPBLK5:			;DISK PARAMETER BLOCK (ROMDISK 1MB)
SPT_5:	.DW 	256	; 256 SECTORS OF 128 BYTES PER 32K TRACK
BSH_5:	.DB 	4 	; BLOCK SHIFT FACTOR (SIZE OF ALLOCATION BLOCK)
BLM_5: 	.DB 	15 	; PART OF THE ALLOCATION BLOCK SIZE MATH
EXM_5: 	.DB 	0 	; DEFINES SIZE OF EXTENT (DIRECTORY INFO)
DSM_5: 	.DW 	495 	; BLKSIZE [2048] * NUMBER OF BLKS +1 =DRIVE SIZE
;DSM_5: .DW 	511 	; BLKSIZE [2048] * NUMBER OF BLKS +1 =DRIVE SIZE
DRM_5: 	.DW 	255 		; NUMBER OF DIRECTORY ENTRIES
AL0_5: 	.DB 	0b11110000  	; BIT MAP OF SPACE ALLOCATED TO DIRECTORY
AL1_5: 	.DB 	0b00000000  	; DIR CAN HAVE UP TO 16 BLOCKS ALLOCATED
CKS_5: 	.DW 	0 	  	; SIZE OF DIR CHECK [0 IF NON REMOVEABLE]
OFF_5: 	.DW 	1 	  	; 1 TRACK RESERVED [FIRST 32K OF ROM]

;
;	END OF FIXED TABLES
;
;	INDIVIDUAL SUBROUTINES TO PERFORM EACH FUNCTION

BOOT:	;SIMPLEST CASE IS TO JUST PERFORM PARAMETER INITIALIZATION
	di			; disable interrupts
;	IM	1		; SET INTERRUPT MODE 1
;	.DB	$ED,$56		; Z80 "IM 1" INSTRUCTION
	
	ld	a,#0x80

;	out0	ACR
;	.BYTE	$ED,$39,ACR	; ensure that the ROM is switched out

	out	(ACR),a
	
	ld	a,#1
	ld	(CDISK),a	; select disk 0

	ld	a,#DEFIOB
	ld	(IOBYTE),a

;	ei				; enable interrupts

	ld	hl,#TXT_STARTUP_MSG
	CALL	PRTMSG

	JP	GOCPM			;INITIALIZE AND GO TO CP/M

;
WBOOT:	;SIMPLEST CASE IS TO READ THE DISK UNTIL ALL SECTORS LOADED
        ; WITH A ROMDISK WE SELECT THE ROM AND THE CORRECT PAGE [0]
        ; THEN COPY THE CP/M IMAGE (CCP, BDOS, BIOS, MONITOR) TO HIGH RAM
        ; LOAD ADDRESS.

	DI				; DISABLE INTERRUPT

	ld	SP,#0x0080		; use space below buffer for stack

;	IM	1			; SET INTERRUPT MODE 1
;	.DB	$ED,$56			; Z80 "IM 1" INSTRUCTION

	xor	a,a

      	; CHEAP ZERO IN ACC
;	mvi	a,00h				; switch in the ROM
;	out0	ACR
;	.BYTE	$ED,$39,ACR

	out	(ACR),a

	xor	a,a

;	out0	RMAP
;	.BYTE	$ED,$39,$F6

	out	(RMAP),a	; set the rom map

				; Just reload CCP and BDOS

	ld	hl,#ROMSTART_CPM	; where in rom cp/m is stored (1st byte)
	ld	de,#RAMTARG_CPM		; where in ram to move ccp+BDOS to
	ld	bc,#MOVSIZ_CPM
	ldir
	
	ld	a,#0x80
	out	(ACR),a

;	EI		; ENABLE INTERRUPTS

;
;	END OF LOAD OPERATION, SET PARAMETERS AND GO TO CP/M
GOCPM:
					;CPU RESET HANDLER
	ld	a,#0xC3			; C32 is a jump opcode
	ld	(0x0000),a
	ld	hl,#WBOOTE		; address of warm boot
	ld	(0x0001),hl		; set addr field for jmp at 0

	ld	(0x0005),a		; for jump to bdos
	ld	hl,#BDOS
	ld	(0x0006),hl

	ld	bc,#0x0080		; default DMA address
	CALL 	SETDMA

	ld	a,(CDISK)		; get current disk number
	ld	c,a			; send to the ccp
	JP	CCP			;GO TO CP/M FOR FURTHER PROCESSING
	

;
;----------------------------------------------------------------------------------------------------------------------
;	N8VEM Home computer I/O handlers
;
;	This implementation uses IOBYTE and allocates devices as follows:
;
;	TTY	-	Driver for the Z180 ASCI port 0 
;	CRT	-	Driver for the <TBA>
;	UC1	-	Driver for the <TBA>
;	xxx	-	Driver for the <TBA>
;
;	Logical device drivers - these pass control to the physical 
;	device drivers depending on the value of the IOBYTE
;

CONST:	;CONSOLE STATUS, RETURN 0FFH IF CHARACTER READY, 00H IF NOT

	ld	a,(IOBYTE)
	and	a,#3
	cp	#0
	jp	z,TTYISTS

	cp	#1
	jp	z,CRTISTS

	jp	NULLSTS




CONIN:	;CONSOLE CHARACTER INTO REGISTER A
	ld	a,(IOBYTE)
	and	a,#3
	cp	#0
	jp	z,TTYIN
	cp	#1
	jp	z,CRTIN
	jp	NULLIN
	

CONOUT: ;CONSOLE CHARACTER OUTPUT FROM REGISTER C
	ld	a,(IOBYTE)
	and	a,#3		; isolate console bits
	cp	#0
	jp	z,TTYOUT
	cp	#1
	jp	z,CRTOUT
	jp	NULLOUT
	
LIST:	;LIST CHARACTER FROM REGISTER C
	jp	NULLOUT



LISTST:	;RETURN LIST STATUS (0 IF NOT READY, 1 IF READY)
	jp	NULLSTS

	;
PUNCH:	;PUNCH CHARACTER FROM REGISTER C
    	jp	NULLOUT
	
;
READER:	;READ CHARACTER INTO REGISTER A FROM READER DEVICE

	jp	NULLIN			; currently not used



;----------------------------------------------------------------------------------------------------------------------------------------
;
;	Here are the physical io device drivers
;
; Null driver  - this is a dummy driver for the NULL device

NULLIN:
	ld	a,#0x1a
	ret
	
NULLOUT:
	ld	a,c
	ret

NULLSTS:
	ld	a,#1
	ret

;
;---------------------------------------------------------------------------------------------------------------------------------------------
;
; TTY Driver (programmed i/o)  this is the driver for the Home Computer console port
;
TTYIN:
	CALL	TTYISTS; IS A CHAR READY TO BE READ FROM UART?
	cp	#0
	jp	z,TTYIN

;	IN0	A,(RDR0)

;dwg;	.BYTE	$ED,$38,RDR0
	.byte	0xED,0x38,RDR0
	
	ret
	
TTYOUT:
	call	TTYOSTS
	and	a,a
	jp	z,TTYOUT		; if not repeat

	ld	a,c			; get to accum

;	OUT0	(TDR0),A
	.byte	0xed,0x39,TDR0

	ret
	
TTYISTS:
;	IN0	A,(STAT0)
;dwg;	.BYTE	$ED,$38,STAT0
;;dwg;;	in0	a,(STAT0)
	.byte	0xed,0x38,STAT0

	and	a,#0x80
	ret	z		; is there a char ready? 0=no 1=yes
	ld	a,#0xff
	ret			; NO, LEAVE $00 IN A AND RETURN

TTYOSTS:
;	IN0	A,(STAT0)
;dwg;	.BYTE	$ED,$38,STAT0
;;dwg;;	in0	a,(STAT0)
	.byte	0xed,0x38,STAT0

	and	a,#2
	ret	z
	ld	a,#0xff

	ret			; NO, LEAVE $00 IN A AND RETURN
;---------------------------------------------------------------------------------------------------------------------------------------------	
;	CRT Driver - This is the driver for the Prop VDU
;	

CRTIN:
	jp		NULLIN
	
CRTOUT:
	jp		NULLOUT
	
CRTISTS:
	jp		NULLSTS

CRTOSTS:
	jp		NULLSTS
	
	
;---------------------------------------------------------------------------------------------------------------------------------------------		
	;;
;	I/O DRIVERS FOR THE DISK FOLLOW
;	FOR NOW, WE WILL SIMPLY STORE THE PARAMETERS AWAY FOR USE
;	IN THE READ AND WRITE SUBROUTINES
;

;
;   SELECT DISK GIVEN BY REGISTER C
;
SELDSK:

	ld	hl,#0		; error return code

	ld	a,c

	cp	a,#4		; must be between 0 and 4
	ret	nc		; no carry if 4,5,6,7
	ld	a,c
	ld	(DISKNO),a	; save valid disk number

;
;   DISK NUMBER IS IN THE PROPER RANGE
;   COMPUTE PROPER DISK PARAMETER HEADER ADDRESS

	ld	l,a			; l = disk num 0,1,2,3,4
	ld	h,#0			; high order 
	add	hl,hl			; * 2
	add	hl,hl			; * 4
	add	hl,hl			; * 8
	add	hl,hl			; * 16 (size of each header)
	ld	de,#DPBASE
	add	hl,de			; hl = .DPBASE(DISKNO*16)
	RET
;
HOME:		;MOVE TO THE TRACK 00 POSITION OF CURRENT DRIVE
		; TRANSLATE THIS CALL INTO A SETTRK CALL WITH PARAMETER 00

	ld	bc,#0		; select track zero

;	CALL	SETTRK
;	RET			;WE WILL MOVE TO 00 ON FIRST READ/WRITE
				; FALL THROUGH TO SETTRK TO STORE VALUE

SETTRK:	;SET TRACK GIVEN BY REGISTER BC
	ld	h,b
	ld	l,c
	ld	(TRACK),hl
	RET
;
SETSEC:	;SET SECTOR GIVEN BY REGISTER BC
	ld	h,b
	ld	l,c
	ld	(SECTOR),hl
	RET
;
;   TRANSLATE THE SECTOR GIVEN BY BC USING THE
;   TRANSLATE TABLE GIVEN BY DE
; ONLY USED FOR FLOPPIES! FOR ROMDISK/RAMDISK IT'S 1:1
; DO THE NEXT ROUTINE IS A NULL (RETURNS THE SAME)
SECTRN:  
	ld	h,b
	ld	l,c
	RET
;

SETDMA:	;SET DMA ADDRESS GIVEN BY REGISTERS B AND C
	ld	l,c
	ld	h,b
	ld	(DMAAD),hl
	RET

;   READ DISK
;    USES DE,DL, BC,  ACC FLAGS
;      Z80 COULD USE BLOCK MOVE [LDIR] BUT WRITTEN IN 8080 	
READ:
;	DI			; DISABLE INTERRUPTS

	ld	a,(DISKNO)
				; FIND OUT WHICH DRIVE IS BEING REQUESTED
				; ARE WE READING RAM OR ROM?
	cp	#0
	jp	z,READ_RAM_DISK
	
	cp	#1
	jp	z,READ_ROM_DISK
	
	cp	#2
	jp	z,READ_HDPART1

	cp	#3
	jp	z,READ_HDPART2	; READ FROM 8 MB IDE HD, PARTITION 2

	cp	#4
	jp	z,READ_HDPART3	; READ FROM 1 MB IDE HD, PARTITION 4

	cp	#5
	jp	z,READ_HDPART4	; READ FROM 1 MB IDE HD, PARTITION 5	

	ld	a,#1 	; BDOS WILL ALSO PRINT ITS OWN ERROR MESSAGE
	ret


;
;   WRITE DISK
;
WRITE:
;	DI					; DISABLE INTERRUPTS

	ld	a,(DISKNO)	; get drive

;	ORA	A		; SET FLAGS

	cp	#0		; find out which drive is being requested

	jp	z,WRITE_RAM_DISK	; write to 448K ram disk
	
	cp	#1
	jp	z,RDONLY	; jump to read only routine

			; READ ONLY, FROM 22K EEPROM DISK, ERROR ON WRITE
	cp	#2
	jp	z,WRITE_HDPART1	; write to 8MB IDE HD, Part 2

	cp	#3
	jp	z,WRITE_HDPART2	; write to 8MB IDE HD, Part 3

	cp	#4
	jp	z,WRITE_HDPART3	; write to 1MB IDE HD, Part 4

	cp	#5
	jp	z,WRITE_HDPART4	; write to 1MB IDE HD Part 5


		; IF NONE OF THE OTHER DISKS, IT MUST BE
		; THE RAM DISK, SO FALL THROUGH

	ld	a,#1		; send bad sector error back
			; BDOS WILL ALSO PRINT ITS OWN ERROR MESSAGE
	ret

						
						
RDONLY:
;
;   HANDLE WRITE TO READ ONLY
;
;   SENDS A MESSAGE TO TERMINAL THAT ROM DRIVE IS NOT WRITEABLE
;   DOES A PAUSE THEN RETURNS TO CPM WITH ERROR FLAGGED. THIS IS
;   DONE TO ALLOW A POSSIBLE GRACEFUL EXIT (SOME APPS MAY PUKE).
;

	; CODE TBD, PRINT A HEY WRONG DISK AND PAUSE 5 SEC AND
	; CONTINUE.

	ld	hl,#TXT_RO_ERROR	; set hp --> error msg
	CALL	PRTMSG		; PRINT ERROR MESSAGE

	ld	a,#1		; send bad sector error back
			; BDOS WILL ALSO PRINT ITS OWN ERROR MESSAGE
				; ADD 5 SECOND PAUSE ROUTINE HERE
	ret

;
;--------------------------------------------------------------------------------------------------------------
;
;  DISK DRIVERS...
;
; DRIVER NEED TO DO SEVERAL THINGS FOR ROM AND RAM DISKS.
;   - INTERRUPTS ARE NOT ALLOWED DURING LOW RAM/ROM ACCESS (DISABLE!)
;   -TRANSLATE TRACK AND SECTOR INTO A POINTER TO WHERE THE 128 BYTE 
;     SECTOR BEGINS IN THE RAM/ROM
;   -TRANSLATE THE DRIVE INTO A RAM/ROM SELECT, COMBINE WITH TRACK ADDRESS
;     AND SEND TO THE MAP PORT.
;   -COPY 128 BYTE FROM OR TO THE ROM/RAMDISK AND MEM POINTED TO BY DMA 
;     ADDRESS PREVIOUSLY STORED.
;   -RESTORE MAP PORT TO PRIOR CONDITION BEFOR READ/WRITE
;
;   - FIRST TRICK IS THAT WE MADE SECTORS 256 AS 256*128=32768. SO WE COPY 
;     THE LOW SECTOR ADDRESS TO THE LOW BYTE OF THE HL REGISTER AND THEN 
;     MULTIPLY BY 128. THIS RESULTS IN THE STARTING ADDR IN THE RAM OR ROM
;     (0000 -> 7F80H) 32K PAGE.
;
;    - TRICK TWO IS THE TRACK ADDRESS EQUALS THE 32K PAGE ADDRESS AND IS A 
;      DIRECT SELECT THAT CAN BE COPIED TO THE MAP PORT D0 THROUGH D5.  D7
;      SELECTS THE DRIVE (ROM OR RAM).
;      THAT MEANS THE LOW BYTE OF TRACK CONTAINS THE D0-D5 VALUE AND 
;      DISKNO HAS THE DRIVE SELECTED.  WE FIRST COPY DISKNO TO ACC
;      AND RIGHTSHIFT IT TO PLACE THAT IN BIT7, WE THEN ADD LOW BYTE OF 
;      TRACK TO ACC AND THEN SEND THAT TO THE MAP PORT.
;
;      NOTE 1: A WRITE TO ROM SHOULD BE FLAGGED AS AN ERROR.
;      NOTE 2: RAM MUST START AS A "FORMATTED DISK"  IF BATTERY BACKED UP
;           IT'S A DO ONCE AT COLD COLD START.  IF NOT BATTERY BACKED UP
;           IT WILL HAVE TO BE DONE EVERY TIME THE SYSTEM IS POWERED.
;           FORMATTING THE RAM IS SIMPLE AS CLEARING THE DIRECTORY AREA 
;           TO A VALUE OF E5H (THE FIRST 8K OF TRACK 1 OR THE RAMDISK).
;           IT COULD BE DONE AS A SIMPLE UTILITY PROGRAM STORED IN ROMDISK
;                   OR ANYTIME COLBOOT IS CALLED(LESS DESIREABLE).
;
;     -WE NOW CAN COPY TO/FROM AS CORRECT FOR THE DEVICE 128 BYTES (SECTOR)
;      TO OR FROM THE DMA ADDRESS. ALMOST!  SINCE ROM OR RAM IS BEING PAGED
;      WE HAVE TO COPY ANYTHING DESTINED FOR BELOW 8000H TO TEMP BUFFER 
;      THEN HANDLE THE PAGING.
;        
;
;     - LAST STEP IS TO RESTORE THE MAP PORT TO POINT TO THE RAM (TRACK 0)
;	SO THE CP/M MEMORY MAP IS ALL RAM AGAIN AND NOT POINTING INTO THE 
;	DATA AREAS OR THE "DISK".
;       SINCE THE RAM 0TH PAGE IS NOMINALLY THE LOW 32K OF RAM IN THE i
;	SYSTEM WE CAN SEND A SIMPLE MVI A,80H ; OUT MPCL_ROM; MVI A,00H ; 
;	OUT MPCL_RAM.
;
;      - THE READ OR WRITE OPERATION IS DONE.
;
;
;
;
;
;

		; ACCESS ALGORITHM (ONLY APPLICABLE TO 32K ROM PART!)
READ_RAM_DISK:
	DI		; IF RAM, PROCEED WITH NORMAL TRACK/SECTOR READ
	CALL	SECPAGE	; SETUP FOR READ OF RAM OR ROM DISK
	
	ld	hl,(TRACK)		; multiply by 8 (4k segs)
							
;dwg;	dad	h				; *2
	add	hl,hl

;dwg;	dad	h				; *4
	add	hl,hl

;dwg;	dad	h				; *8
	add	hl,hl

;dwg;	MOV	A,L				; get track in L
	ld	a,l

;	out0	BBR				; select RAM bank

;dwg;	.BYTE	 $ED,$39,BBR
;;dwg;;	out0	BBR
	.byte	0xed,0x39,BBR

	ld	hl,#TMPBUF		; load hl with temp buf addr
	ld	d,h			; get it into de
	ld	e,l
	ld	hl,(SECST)		; rom/ram addr
	ld	bc,#128
	ldir

;
; NOW WITH THE ROM/RAM DATA IN THE BUFFER WE CAN NOW MOVE IT TO THE 
; DMA ADDRESS (IN RAM)
;

	ld	a,#0		; return to system bank

;	out0	BBR				; select RAM bank

;dwg;	.BYTE	 $ED,$39,BBR
;;dwg;;	out0	BBR
	.db	0xed,0x39,BBR

;	CALL	RPAGE			; SET PAGE TO CP/M RAM

;	EI			; RE-ENABLE INTERRUPTS

	ld	hl,(DMAAD)	; load hl  with dma addr
	ld	e,l
	ld	d,h		; get it into de
	ld	hl,#TMPBUF	; get rom/ram addr
	ld	bc,#128
	ldir

	ld	a,#0
	RET
	
READ_ROM_DISK:
	DI			; IF RAM, PROCEED WITH NORMAL TRACK/SECTOR READ
	CALL	SECPAGE		; SETUP FOR READ OF RAM OR ROM DISK
	CALL 	PAGERB		; SET PAGER WITH DRIVE AND TRACK

	ld	hl,#TMPBUF	; load hl with temp buf address
	ld	d,h
	ld	e,l		; get it into de
	ld	hl,(SECST)	; rom/ram address
	ld	bc,#128
	ldir

;
; NOW WITH THE ROM/RAM DATA IN THE BUFFER WE CAN NOW MOVE IT TO THE 
; DMA ADDRESS (IN RAM)
;
	CALL	RPAGE			; SET PAGE TO CP/M RAM
;	EI				; RE-ENABLE INTERRUPTS

	ld	hl,(DMAAD)		; load hl with dma address
	ld	e,l
	ld	d,h
	ld	hl,#TMPBUF		; get rom/ram address
	ld	bc,#128
	ldir

	ld	a,#0
	ret

	
WRITE_RAM_DISK:

	ld	hl,#TMPBUF		; load hl with temp buf address
	ld	d,h
	ld	e,l
	ld	hl,(DMAAD)
	ld	bc,#128
	ldir

;
;  NOW THAT DATA IS IN THE TEMP BUF WE SET TO RAM PAGE
;   FOR WRITE.
;
	DI
	CALL	SECPAGE 		; GET RAM PAGE WRITE ADDRESS

	ld	hl,(TRACK)

	add	hl,hl			; *2  multiply by 8 (4k segs)
	add	hl,hl			; *4
	add	hl,hl			; *8
	ld	a,l			; get track in l

;	out0	BBR				; select RAM bank
;dwg;	.BYTE	 $ED,$39,BBR	
;;dwg;;	out0	BBR
	.db	0xed,0x39,BBR
	
	ld	hl,(SECST)	; load hl with dma addr (where to write to)
	ld	d,h		; get it into de
	ld	e,l
	ld	hl,#TMPBUF	; get temp buffer address
	ld	bc,#128
	ldir

	ld	a,#0		; return to system bank

;	out0	BBR			; select RAM bank
;dwg;	.BYTE	 $ED,$39,BBR
;;dwg;;	out0	BBR
	.db	0xed,0x39,BBR

;	EI	
					; RE-ENABLE INTERRUPTS
	ld	a,#0
	ret
	
;-------------------------------------------------------------------	

; Logical disk drivers	

READ_HDPART1:

	ld	hl,#1			; init LBA offset sector lo word
	ld	(LBA_OFFSET_LO),hl
	ld	hl,#0			; init LBA offset sector hi word
	ld	(LBA_OFFSET_HI),hl
	JP	READ_HDPARTX

READ_HDPART2:
	ld	hl,#0x4001		; init LBA offset sector lo word
	ld	(LBA_OFFSET_LO),hl
	ld	hl,#0			; init LBA offset sector hi word
	ld	(LBA_OFFSET_HI),hl
	JP	READ_HDPARTX
	
READ_HDPART3:
READ_HDPART4:
	ret

	
READ_HDPARTX:

	; BDOS TRACK PARAMETER (16 BITS)
	; BDOS SECTOR PARAMETER (16 BITS)

	ld	hl,(TRACK)	; load track number (word)
	ld	b,l		; save lower 8 bits (tracks 0-255)
	ld	hl,(SECTOR)	; load sector number (word)
	ld	h,b		; hl is 8 bit track in h, 8 bit sector in l
	CALL	CONVERT_IDE_SECTOR_CPM	; COMPUTE WHERE CP/M SECTOR IS ON THE
					; IDE PARTITION

	; MAP COMPUTED IDE HD SECTOR TO LBA REGISTERS

	; LBA REGISTERS STORE 28 BIT VALUE OF IDE HD SECTOR ADDRESS

	ld	a,(LBA_TARGET_LO)	; load LBA reg 0 with sector addr to read
	ld	(IDE_LBA0),a
	ld	a,(LBA_TARGET_LO+1)	; load LBA reg 1 with sector addr t read
	ld	(IDE_LBA1),a
	ld	a,(LBA_TARGET_HI)	; load LBA reg 2 with sector addr to read
	ld	(IDE_LBA2),a
	ld	a,(LBA_TARGET_HI+1)	; load LBA reg 3 with sector addr to read
	and	a,#0b00001111		; only lower 4 bits are valid
	add	a,#0b11100000		; enable LBA bits 5:7=111 in IDE_LBA3
	ld	(IDE_LBA3),a
	CALL	IDE_READ_SECTOR		; READ THE IDE HARD DISK SECTOR

; NEED TO ADD ERROR CHECKING HERE, CARRY FLAG IS SET IF IDE_READ_SECTOR SUCCESSFUL!

	; COMPUTE STARTING ADDRESS OF CP/M SECTOR IN READ IDE HD SECTOR BUFFER

	ld	hl,#SECTOR_BUFFER	; load hl with sector buffer address

	ld	a,(SECTOR_INDEX)	; get the sector index (off in buff)

	RRC	a	; MOVE BIT 0 TO BIT 7
	RRC	a	; DO AGAIN - IN EFFECT MULTIPLY BY 64

	ld	d,#0	; put result as 16 value in de, upper byte in d is 0

	ld	e,a	; put addr offset in e

	add	hl,de	; multiply by 2, total mult is x 128

	add	hl,de	; cp/m sect starting addr in IDE HD sector buffer

	; COPY CP/M SECTOR TO BDOS DMA ADDRESS BUFFER

	ld	D,H		; TRANSFER HL REGISTERS TO DE
	ld	E,L
	ld	hl,(DMAAD)	; LOAD HL WITH DMA ADDRESS
	ex	de,hl
	ld	bc,#128
	ldir

;	EI					; RE-ENABLE INTERRUPTS

	ld	a,#0			; return err code read successful a=0
	ret




;-------------------------------------------------------------------	

	
WRITE_HDPART1:

;	DI			; DISABLE INTERRUPTS

	ld	hl,#1		; init LBA offset sector lo word
	ld	(LBA_OFFSET_LO),hl
	ld	hl,#0		; init LBA offset sector hi word
	ld	(LBA_OFFSET_HI),hl
	JP	WRITE_HDPARTX
	

WRITE_HDPART2:

;	DI			; DISABLE INTERRUPTS

	ld	hl,#0x4001		; init LBA offset sector lo word
	ld	(LBA_OFFSET_LO),hl
	ld	hl,#0			; init LBA offset sector hi word
	ld	(LBA_OFFSET_HI),hl
	JP	WRITE_HDPARTX

;-------------------------------------------------------------------	
	
WRITE_HDPART3:				; STUB
WRITE_HDPART4:				; STUB
	RET

;-------------------------------------------------------------------
	
	
WRITE_HDPARTX:

	; BDOS TRACK PARAMETER (16 BITS)
	; BDOS SECTOR PARAMETER (16 BITS)

	ld	hl,(TRACK)	; load track # (word)
	ld	b,l		; save lower 8 bits (tracks 0-255)
	ld	hl,(SECTOR)	; load sector # (word)
	ld	h,b		; hl is 8 bit track in h, 8 bit sector in l

	CALL	CONVERT_IDE_SECTOR_CPM	; COMPUTE WHERE THE CP/M SECT IS ON THE
					; IDE PARTITION

		; MAP COMPUTED IDE HD SECTOR TO LBA REGISTERS
		; LBA REGISTERS STORE 28 BIT VALUE OF IDE HD SECTOR ADDRESS

	ld	a,(LBA_TARGET_LO)	; load LBA reg 0 with sect addr to read
	ld	(IDE_LBA0),a
	ld	a,(LBA_TARGET_LO+1)	; load LBA reg 1 with sect addr to read
	ld	(IDE_LBA1),a
	ld	a,(LBA_TARGET_HI)	; load LBA reg 2 with sect addr to read
	ld	(IDE_LBA2),a
	ld	a,(LBA_TARGET_HI+1)	; load LBA reg 3 with sect addr to read
	and	a,#0b00001111		; only lower four bits are valid
	add	a,#0b11100000		; enable LBA bits 5:7=111 in IDE_LBA3
	ld	(IDE_LBA3),a
	CALL	IDE_READ_SECTOR		; READ THE IDE HARD DISK SECTOR

	; NEED TO ADD ERROR CHECKING HERE,
	; CARRY FLAG IS SET IF IDE_READ_SECTOR SUCCESSFUL!

	; COMPUTE STARTING ADDRESS OF CP/M SECTOR IN READ IDE HD SECTOR BUFFER

	ld	hl,#SECTOR_BUFFER	; load hl with sector buffer address

	ld	a,(SECTOR_INDEX)	; get the sector index (off in buffer)

	RRC	a		; MOVE BIT 0 TO BIT 7
	RRC	a		; DO AGAIN - IN EFFECT MULTIPLY BY 64

	ld	d,#0		; put result as 16 bit value in de
				; UPPER BYTE IN D IS $00
	ld	e,a		; put address offset in e

	add	hl,de		; cp/m starting addr in buffer

	add	hl,de	; *2, total mult is x128

        ; KEEP CP/M SECTOR ADDRESS FOR LATER USE
	; COPY CP/M SECTOR FROM BDOS DMA ADDRESS BUFFER
	ld	(SECST),hl

	ld	hl,(SECST)	; setup destination
	ex	de,hl		; swap for next LHLD
	ld	hl,(DMAAD)	; setup source
	ld	bc,#128		; byte count
	ldir
	
	; IDE HD SECTOR IS NOW UPDATED 
	; WITH CURRENT CP/M SECTOR DATA SO WRITE TO DISK

	CALL	IDE_WRITE_SECTOR ; WRITE THE UPDATED IDE HARD DISK SECTOR

	; NEED TO ADD ERROR CHECKING HERE, 
	; CARRY FLAG IS SET IF IDE_WRITE_SECTOR SUCCESSFUL!

;	EI					; RE-ENABLE INTERRUPTS

	ld	a,#0		; return error code write successful a=0
	ret

;-------------------------------------------------------------------


PRTMSG:
	ld	a,(hl)		; get char into A
	cp	a,#END		; test for end byte
	jp	z,PRTMSG1	; jump if end byte is found
	ld	c,a		; put char to print in C for conout
	CALL	CONOUT		; SEND CHARACTER TO CONSOLE FROM REG C
	inc	hl		; inc ptr to next char
	JP	PRTMSG		; TRANSMIT LOOP
PRTMSG1:
	ret


;
; UTILITY ROUTINE FOR SECTOR TO PAGE ADDRESS
;   USES HL AND CARRY
;
SECPAGE:
	ld	hl,(SECTOR)
	add	hl,hl		; * 2
	add	hl,hl		; * 4
	add	hl,hl		; * 8
	add	hl,hl		; * 16
	add	hl,hl		; * 32
	add	hl,hl		; * 64
	add	hl,hl		; * 128
	ld	(SECST),hl	; save sector starting address
	ret

;
;  PAGER BYTE CREATION
;  ASSEMBLES DRIVE AND TRACK AND SENDS IT TO PAGER PORT
;
PAGERB:
	ld	hl,(TRACK)
	ld	a,l	; or l with acc to combine track and drive
;	out0	ACR+2
	.db	0xed,0x39,ACR+2		; rom latch
	ld	a,#0			; switch in the rom
;	out0	ACR
	.db	0xed,0x39,ACR
	ld	(PAGER),a		; save copy (just because)
	ld	(DB_PAGER),a		; save another copy for debug
	RET

;
;   RESET PAGER BACK TO RAM.  
;
RPAGE:

	ld	a,#0x80			; deselect rom page
;	out0	ACR
	.db	0xed,0x39,ACR

	ld	a,#0			; set to RAM track 0
;dwg;	STA 	PAGER			; SAVE COPY OF PAGER BYTE
	ld	(PAGER),a

	RET


CONVERT_IDE_SECTOR_CPM:

	; COMPUTES WHERE THE CP/M SECTOR IS IN THE IDE PARTITION
	; IDE HD SECTORS ARE 512 BYTES EACH, CP/M SECTORS ARE 128 BYTES EACH
	; MAXIMUM SIZE OF CP/M DISK IS 8 MB = 65536 (16 BITS) X 128 BYTES PER SECTOR
	; IDE HD PARTITION CAN HAVE AT MOST 16384 IDE SECTORS -> 65536 CP/M SECTORS
	; EACH IDE HD SECTOR CONTAINS 4 ADJACENT CP/M SECTORS
	; 
	;
	; INPUT:
	; IDE HD PARTITION STARTING SECTOR NUMBER (FROM PARTITION TABLE)
	;  - LOWER 16 BITS STORED IN LBA_OFFSET_LO
	;  - UPPER 16 BITS STORED IN LBA_OFFSET_HI
	; PARTITION OFFSET IN HL (16 BITS)
	;  - A UNIQUELY COMPUTED FUNCTION BASED ON GEOMETRY OF DISKS NUMBER OF
	;    CP/M TRACKS AND SECTORS SPECIFIED IN DPB
	; 
	;
	; OUTPUT:
	; IDE TARGET SECTOR (SENT TO IDE HD CONTROLLER FOR READ OPERATION)
	;  - LOWER 16 BITS STORED IN LBA_TARGET_LO
	;  - UPPER 16 BITS STORED IN LBA_TARGET_HI
	; CP/M TO IDE HD SECTOR MAPPING PARAMETER STORED IN SECTOR_INDEX
	;  - 8 BIT VALUE WITH 4 LEGAL STATES (00, 01, 02, 04) WHICH IS
	;    TO BE USED TO COMPUTE STARTING ADDRESS OF 128 BYTE CP/M SECTOR ONCE
	;    512 BYTE IDE HD SECTOR READ INTO MEMORY BUFFER
	; 

	; ROTATE WITH CARRY 16 BIT TRACK,SECTOR VALUE IN HL TO GET 14 BIT IDE HD
	; TARGET SECTOR IN PARTITION
	; KEEP LAST TWO BITS IN B FOR IDE HD SECTOR TO CP/M SECTOR TRANSLATION

	; COMPUTE SECTOR_INDEX 

;;dwg;; What is the point of this? the next inst sets A anyway??
	xor	a,a			; zero accumulator

	ld	a,l			; store the last 2 bits of l in b
	and	a,#0b00000011
	ld	b,a

	ld	(SECTOR_INDEX),a	; locates the 128 cpm sector in buffer

	; COMPUTE WHICH IDE HD SECTOR TO READ TO WITHIN 4 CP/M SECTORS 
	; SHIFTS 16 BIT PARTITION OFFSET TO THE RIGHT 2 BITS AND ADDS RESULT TO
	; IDE HD PARTITION STARTING SECTOR

	; SHIFT PARTITION OFFSET RIGHT 1 BIT

	scf				; set the carry flag, so we can clear it
	ccf				; Complement Carry Flag

	ld	a,h			; 16 bit rotate hl with carry
	rra
	ld	h,a			; rotate HL right 1 bit (divide by 2)
	ld	a,l
	rra
	ld	l,a

	; SHIFT PARTITION OFFSET RIGHT 1 BIT

	scf
	ccf					; CLEAR CARRY FLAG

	ld	a,h			; 16 bit rotate HL with carry
	rra
	ld	H,A			; ROTATE HL RIGHT 1 BIT (DIVIDE BY 2)
	ld	A,L
	rra
	ld	L,A

	; ADD RESULTING 14 BIT VALUE TO IDE HD PARTITION STARTING SECTOR
	; STORE RESULT IN IDE HD TARGET SECTOR PARAMETER

	ld	a,(LBA_OFFSET_LO)	; 16 bit add of LBA_OFFSET_LO with hl
	ADD	L
	ld	(LBA_TARGET_LO),a
	ld	a,(LBA_OFFSET_LO+1)
	adc	a,h
	ld	(LBA_TARGET_LO+1),a	; store overflow bit in carry
	ld	hl,#0
	ld	a,(LBA_OFFSET_HI)	; 16 bit add w/carry of LBA_OFFSET_HI w/
	adc	a,l
	ld	(LBA_TARGET_HI),a
	ld	a,(LBA_OFFSET_HI+1)
	adc	a,h
	ld	(LBA_TARGET_HI+1),a
	RET


	
;------------------------------------------------------------------------------------		
; Parallel port IDE driver
;		
;
; -----------------------------------------------------------------------------	

	;read a sector, specified by the 4 bytes in "lba",
	;Return, acc is zero on success, non-zero for an error
IDE_READ_SECTOR:
	call	ide_wait_not_busy	;make sure drive is ready
	call	wr_lba			;tell it which sector we want

	ld	a,#ide_command		; select IDE reg
	ld	c,#ide_cmd_read
	call	ide_write		;ask the drive to read it
	call	ide_wait_drq		;wait until it's got the data
;	bit	0,a
;	ani	1
;	jnz	 get_err

	ld	hl,#SECTOR_BUFFER
	call	read_data		;grab the data
	ld	a,#0			; ? set successful return code ?

	ret

	
;-----------------------------------------------------------------------------


	;write a sector, specified by the 4 bytes in "lba",
	;whatever is in the buffer gets written to the drive!
	;Return, acc is zero on success, non-zero for an error
IDE_WRITE_SECTOR:
	call	ide_wait_not_busy	;make sure drive is ready
	call	wr_lba			;tell it which sector we want

	ld	a,#ide_command
	ld	c,#ide_cmd_write
	call	ide_write		;tell drive to write a sector
	call	ide_wait_drq		;wait unit it wants the data

;	bit	0,a			; check for error returned
;	ani	1
;	jnz	get_err

	ld	hl,#SECTOR_BUFFER
	call	write_data		;give the data to the drive
	call	ide_wait_not_busy	;wait until the write is complete

;	bit	0,a
;	ani	1
;	jnz	get_err

;	ld	a,#0			; SHOULD THIS BE HERE (Doug's idea)
	ret


;-----------------------------------------------------------------------------

;--------ide_hard_reset---------------------------------------------------------------
	;do a hard reset on the drive, by pulsing its reset pin.
	;this should usually be followed with a call to "ide_init".
;-------------------------------------------------------------------------------------------	
ide_hard_reset:
	call	set_ppi_rd
	ld	a,#ide_rst_line
	out	(IDECTL),a		; assert rst line on IDE interface
	ld	bc,#0
rst_dly:
	dec	b
	jp	nz,rst_dly
	ld	a,#0		; this could be XOR A,A (shorter)
	out	(IDECTL),a		; deassert RST line on IDE interface
	ret

;------------------------------------------------------------------------------
; IDE INTERNAL SUBROUTINES 
;------------------------------------------------------------------------------


	
;----------------------------------------------------------------------------
	;when an error occurs, we get bit 0 of A set from a call to ide_drq
	;or ide_wait_not_busy (which read the drive's status register).  If
	;that error bit is set, we should jump here to read the drive's
	;explaination of the error, to be returned to the user.  If for
	;some reason the error code is zero (shouldn't happen), we'll
	;return 255, so that the main program can always depend on a
	;return of zero to indicate success.
get_err:
	ld	a,#ide_err
	call	ide_read
	ld	a,c
	jp	z,gerr2
	ret
gerr2:
	ld	a,#255
	ret

;-----------------------------------------------------------------------------
	
ide_wait_not_busy:
	ld	a,#ide_status		; wait for RDY bit to be set
	call	ide_read
	ld	a,c
	and	a,#0x80			; isolate busy bit
	jp	nz,ide_wait_not_busy
	ret


ide_wait_ready:
	ld	a,#ide_status		; wait for RDY bit to be set
	call	ide_read
	ld	a,c
	and	a,#0b11000000		; mask off busy and ready bits
	xor	a,#0b01000000		; we want Busy(7) to be 0 and ready(6) to be 1
	jp	nz,ide_wait_ready
	ret

	;Wait for the drive to be ready to transfer data.
	;Returns the drive's status in Acc
ide_wait_drq:
	ld	a,#ide_status		; waut for DRQ bit to be set
	call	ide_read
	ld	a,c
	and	a,#0b10001000		; mask off busy(7) and DRQ(3)
	xor	a,#0b00001000		; we want busy(7) to be 0 and DRQ (3) to be 1
	jp	nz,ide_wait_drq
	ret



;------------------------------------------------------------------------------

	;Read a block of 512 bytes (one sector) from the drive
	;and store it in memory @ HL
read_data:
	ld	b,#0
rdblk2:
	push	bc
	push	hl
	ld	a,#ide_data
	call	ide_read		; read form data port
	pop	hl
	ld	(hl),c
	inc	hl
	ld	(hl),b
	inc	hl
	pop	bc
	dec	b
	jp	nz,rdblk2
	ret

;-----------------------------------------------------------------------------

	;Write a block of 512 bytes (at HL) to the drive
write_data:
	ld	b,#0
wrblk2: 
	push	bc
	ld	c,(hl)	; lsb
	inc	hl
	ld	b,(hl)	; msb
	inc	hl
	push	hl
	ld	a,#ide_data
	call	ide_write
	pop	hl
	pop	bc
	dec	b
	jp	nz,wrblk2
	ret


;-----------------------------------------------------------------------------

	;write the logical block address to the drive's registers
wr_lba:
	ld	a,(IDE_LBA0+3)		; MSB
	and	a,#0x0f
	or	a,#0xe0
	ld	c,a
	ld	a,#ide_head
	call	ide_write
	ld	a,(IDE_LBA0+2)
	ld	c,a
	ld	a,#ide_cyl_msb
	call	ide_write
	ld	a,(IDE_LBA0+1)
	ld	c,a
	ld	a,#ide_cyl_lsb
	call	ide_write
	ld	a,(IDE_LBA0)		; LSB
	ld	c,a
	ld	a,#ide_sector
	call	ide_write
	ld	c,#1
	ld	a,#ide_sec_cnt
	call	ide_write
	
	ret
	
;-------------------------------------------------------------------------------

; Low Level I/O to the drive.  These are the routines that talk
; directly to the drive, via the 8255 chip.  Normally a main
; program would not call to these.

	;Do a read bus cycle to the drive, using the 8255.
	;input A = ide regsiter address
	;output C = lower byte read from ide drive
	;output B = upper byte read from ide drive

ide_read:
	push	af			; save register value
	call	set_ppi_rd		; setup for a read cycle
	pop	af			; restore register value
	out	(IDECTL),a		;drive address onto control lines
	or	a,#ide_rd_line		; assert RD pin
	out	(IDECTL),a
	push	af			; save register value
	in	a,(IDELSB)		; read lower byte
	ld	c,a			; save in c reg
	in	a,(IDEMSB)		; read upper byte
	ld	b,a			; save in reg b
	pop	af			; restore reg value
	xor	a,#ide_rd_line		; deassert RD signal
	out	(IDECTL),a
	ld	a,#0		;; DWG SAYS couln't this be a 1 byter?
	out	(IDECTL),a		;deassert all control pins
	ret

	;Do a write bus cycle to the drive, via the 8255
	;input A = ide register address
	;input register C = lsb to write
	;input register B = msb to write
	;

	
ide_write:
	push	af			; save IDE reg valure
	call	set_ppi_wr		; setup for a write cycle
	ld	a,c			; get value to be written
	out	(IDELSB),a
	ld	a,b			; get value to be written
	out	(IDEMSB),a
	pop	af			; restore saved IDE reg
	out	(IDECTL),a		; drive address onto control lines
	or	a,#ide_wr_line		; assert write pin
	out	(IDECTL),a
	xor	a,#ide_wr_line		; deasser write pin
	out	(IDECTL),a		;drive address onto control lines
	ld	a,#0			;; DWG SAYS couldn't this be 1 byter?
	out	(IDECTL),a		; release bus signals
	ret


;-----------------------------------------------------------------------------------	
; ppi setup routine to configure the appropriate PPI mode
;
;------------------------------------------------------------------------------------

set_ppi_rd:
	ld	a,#rd_ide_8255
	out	(PIO1CONT),a			;config 8255 chip, read mode
	ret

set_ppi_wr:
	ld	a,#wr_ide_8255
	out	(PIO1CONT),a			;config 8255 chip, write mode
	ret
	
;-----------------------------------------------------------------------------
; End of PPIDE disk driver
;------------------------------------------------------------------------------------	

	
;	TEXT STRINGS

TXT_RO_ERROR:
	.DB CR,LF
	.ascii "ERROR: WRITE TO READ ONLY DISK"
	.DB END

TXT_STARTUP_MSG:
	.DB CR,LF
	.ascii "CP/M-80 VERSION 2.2C FOR THE "
	.ascii "N8VEM N8"
	.ascii " (PPIDE)"
	.DB CR,LF
	.DB END

;
;	THE REMAINDER OF THE CBIOS IS RESERVED UNINITIALIZED
;	DATA AREA, AND DOES NOT NEED TO BE A PART OF THE
;	SYSTEM MEMORY IMAGE
;
TRACK:			.DS	2		; TWO BYTES FOR TRACK #
SECTOR:			.DS	2		; TWO BYTES FOR SECTOR #
DMAAD:			.DS	2		; DIRECT MEMORY ADDRESS
DISKNO:			.DS	1		; DISK NUMBER 0-15


PAGER:			.DB	1		; COPY OF PAGER BYTE

DB_PAGER:		.db	0xff		; copy of pager byte

V_SECTOR:		.DS	2		; TWO BYTES FOR VIRTUAL SECTOR #
SECST:			.DS	2		; SECTOR IN ROM/RAM START ADDRESS


LBA_OFFSET_LO:	.DW	0	; IDE HD PART STARTING SECTOR (LOW 16 BITS)
LBA_OFFSET_HI:	.DW	0	; IDE HD PART STARTING SECTOR (HI 16 BITS, 12 USED)
LBA_TARGET_LO:	.DW	0	; IDE HD PART TARGET SECTOR (LOW 16 BITS)
LBA_TARGET_HI:	.DW	0	; IDE HD PART TARGET SECTOR (HI 16 BITS, 12 USED)

IDE_LBA0:	.DS	1	;SET LBA 0:7
IDE_LBA1:	.DS	1	;SET LBA 8:15
IDE_LBA2:	.DS	1	;SET LBA 16:23
IDE_LBA3:	.DS	1	;LOWEST 4 BITS USED ONLY TO ENABLE LBA MODE 

SECTOR_INDEX:	.DB	0		;WHERE 128 BYTE CP/M SECTOR IS IN 512 BYTE IDE HD SECTOR


;
;	SCRATCH RAM AREA FOR BDOS USE
;
; Note: this can extend up to the beginning of the debug monitor however
; there is a limitation in the amount of space available in the EPROM
;
;BEGDAT			.EQU	$				;BEGINNING OF DATA AREA
;
;

SECTOR_BUFFER:	.DS	512			;Deblocking STORAGE FOR 512 BYTE IDE HD SECTOR

;dwg;TMPBUF			.EQU 	SECTOR_BUFFER
TMPBUF = SECTOR_BUFFER

DIRBF:			.DS	128			;SCRATCH DIRECTORY AREA
ALL00:			.DS	4			;ALLOCATION VECTOR 0  (DSM/8 = 1 BIT PER BLOCK)
ALL01:			.DS	32			;ALLOCATION VECTOR 1 (225/8)
ALL02:			.DS	255			;ALLOCATION VECTOR 2 (2040/8)
ALL03:			.DS	255			;ALLOCATION VECTOR 3 (2040/8)
ALL04:			.DS	64			;ALLOCATION VECTOR 4 (511/8)
ALL05:			.DS	64			;ALLOCATION VECTOR 5 (495/8)
;
CHK00:			.DS	0			; NOT USED FOR FIXED MEDIA
CHK01:			.DS	0			; NOT USED FOR FIXED MEDIA
CHK02:			.DS	0			; NOT USED FOR FIXED MEDIA
CHK03:			.DS	0			; NOT USED FOR FIXED MEDIA
CHK04:			.DS	0			; NOT USED FOR FIXED MEDIA
CHK05:			.DS	0			; NOT USED FOR FIXED MEDIA

; DOUG SAYS - THIS NEEDS TO BE DONE ANOTHER WAY NO ORGS IN REL SEG
;
;	.ORG	$F2FF
;
;   F2FF	- desired org
; - E600	- BIOS ORG
; ______
;   0CFF	- necessary offset in this module
;
;   0CCF	; where we want to be
; - 0AA9	; where we are now
; ______
;   0256	- adjustment to reach desired org in rel segment
;

	.ds	0x0256		; THIS NEEDS TO BE ADJUSTED SO LASTBYTE IS AT 0CFF

LASTBYTE:	.DB	0xE5	; note this is just to force out the last byte.
				; this address will actually fall within the
				; allocation vector block

_cbioshc_end::
	.area _CODE
	.area _CABS
