;********************************************************
; Bob's very simple BIOS.  
;
; Work started in, oh, I don't know, probably 2008.

; Work RE-started on 02/14/2013
;
; Hardware description:
;
;    Northstar ZPU
;    CCS 2710 serial port.  Console on first port.
;    N8VEM 4MB RAM with only 1 MB installed
;    N8VEM IDE with a CF card
;
; This is a merge of many pieces of code from all over
; the net, very little of it is mine other than some
; glue logic.  So, here are some of the sources of info
; and code I borrowed from:
;
;    www.speakeasy.org/~rzh/bios.mac
;    http://www.s100computers.com/My%20System%20Pages/IDE%20Board/My%20IDE%20Card.htm
;
; These are some of my include files to make things easier
; for me.
;
#include "tasm.inc"
#include "cpm22.inc"
;
; Put out a bit of diagnostics
;
		.echo	"Building a BIOS for a RAM size of "
		.echo	RAMSIZE
		.echo	"K\n"
;
; Common CP/M items
;
DefaultDisk	equ	TDRIVE		;I like this name better
BDOSEntry	equ	(CCPBASE+CCPSIZE+6)
CPM_SECTOR_SIZE	equ	128
;
; Base ports of various I/O devices.
;
IDE_PORT	EQU	030H		;IDE board
;
; Base memory locations of various things
;
CCPEntry	EQU	CCPBASE
CPM_VERSION	.equ	22H		;CP/M version
;
; Constants
;
FALSE		.equ	0
TRUE		.equ	~FALSE
;
; ASCII constants
;
CR		.equ	0dh
LF		.equ	0ah
BELL		.equ	07h
EOF		.equ	01ah		;CTRL-Z is CP/M EOF
;
; IDE board constants
;
IDEportA	EQU	IDE_PORT+0	;Lower 8 bits of IDE interface (8255)
IDEportB	EQU	IDE_PORT+1	;Upper 8 bits of IDE interface
IDEportC	EQU	IDE_PORT+2	;Control lines for IDE interface
IDEportCtrl	EQU	IDE_PORT+3	;8255 configuration port

READcfg8255	EQU	10010010b	;Set 8255 IDEportC out, IDEportA/B input
WRITEcfg8255	EQU	10000000b	;Set all three 8255 ports output

;IDE control lines for use with IDEportC.  Change these 8
;constants to reflect where each signal of the 8255 each of the
;IDE control signals is connected.  All the control signals must
;be on the same port, but these 8 lines let you connect them to
;whichever pins on that port.

IDEa0line	EQU	01H	;direct from 8255 to IDE interface
IDEa1line	EQU	02H	;direct from 8255 to IDE interface
IDEa2line	EQU	04H	;direct from 8255 to IDE interface
IDEcs0line	EQU	08H	;inverter between 8255 and IDE interface
IDEcs1line	EQU	10H	;inverter between 8255 and IDE interface
IDEwrline	EQU	20H	;inverter between 8255 and IDE interface
IDErdline	EQU	40H	;inverter between 8255 and IDE interface
IDErstline	EQU	80H	;inverter between 8255 and IDE interface
;
;Symbolic constants for the IDE Drive registers, which makes the
;code more readable than always specifying the address pins

REGdata		EQU	IDEcs0line
REGerr		EQU	IDEcs0line + IDEa0line
REGseccnt	EQU	IDEcs0line + IDEa1line
REGsector	EQU	IDEcs0line + IDEa1line + IDEa0line
REGcylinderLSB	EQU	IDEcs0line + IDEa2line
REGcylinderMSB	EQU	IDEcs0line + IDEa2line + IDEa0line
REGshd		EQU	IDEcs0line + IDEa2line + IDEa1line		;(0EH)
REGcommand	EQU	IDEcs0line + IDEa2line + IDEa1line + IDEa0line	;(0FH)
REGstatus	EQU	IDEcs0line + IDEa2line + IDEa1line + IDEa0line
REGcontrol	EQU	IDEcs1line + IDEa2line + IDEa1line
REGastatus	EQU	IDEcs1line + IDEa2line + IDEa1line + IDEa0line

;IDE Command Constants.  These should never change.

COMMANDrecal	EQU	10H
COMMANDread	EQU	20H
COMMANDwrite	EQU	30H
COMMANDinit	EQU	91H
COMMANDid	EQU	0ECH
COMMANDspindown	EQU	0E0H
COMMANDspinup	EQU	0E1H
;
;
; IDE Status Register:
;  bit 7: Busy	1=busy, 0=not busy
;  bit 6: Ready 1=ready for command, 0=not ready yet
;  bit 5: DF	1=fault occured insIDE drive
;  bit 4: DSC	1=seek complete
;  bit 3: DRQ	1=data request ready, 0=not ready to xfer yet
;  bit 2: CORR	1=correctable error occured
;  bit 1: IDX	vendor specific
;  bit 0: ERR	1=error occured
;
;

;
; A Z80 JP instruction is manually put into a few locations
; by the BIOS, so here is an equate for that instruction.
;
JMP		equ	0c3h
		.page
;********************************************************
; PRIMARY JUMP TABLE. ALL CALLS FROM CP/M TO THE CBIOS
; COME THROUGH THIS TABLE.
;********************************************************
;
		.org	BIOSBASE
;
		JP	CBOOT		;COLD BOOT
WBOOTE:		JP	WBOOT		;WARM BOOT
		JP	CONST		;CONSOLE STATUS
		JP	CONIN		;CONSOLE CHARACTER IN
		JP	CONOUT		;CONSOLE CHARACTER OUT,
		JP	LIST		;LIST CHARACTER OUT
		JP	PUNCH		;PUNCH CHARACTER OUT
		JP	READER		;READER CHARACTER IN
		JP	HOME		;MOVE HEAD TO HOME POSITION
		JP	SELDSK		;SELECT DISK
		JP	SETTRK		;SET TRACK NUMBER
		JP	SETSEC		;SET SECTOR NUMBER
		JP	SETDMA		;SET DMA ADDRESS
		JP	READ		;READ DISK
		JP	WRITE		;WRITE DISK
		JP	LISTST		;RETURN LIST STATUS
		JP	SECTRA		;SECTOR TRANSLATE
;
;********************************************************
; Sneaking little Bob trick.  My program to write CP/M
; to the disk needs to know the end of the BIOS, so I
; decided to put the last memory location used by the
; BIOS into the two bytes before the CBOOT code.  So the
; program can find the end by picking up the first JP
; address in the jump table, and backing up two bytes.
;
		DW	BIOS_END
		.page
;
;********************************************************
;
; This is the cold boot entry point, called from the first
; entry in the jump table.  Control will be transfered here
; by the CP/M bootstrap loader.
;

CBOOT:		ld	sp,0080h	;set stack pointer
		call	initser		;initialize the serial port
		call	IDEinit		;initialize the IDE interface


		call	msg
		.db	CR,LF,LF
		.text	"Bob's BIOS :)"
		.db	CR,LF
		.text	"??"
		.text	"K CP/M v2.2"
		.db	CR,LF,
		.text	"Drives:"
		.db	CR,LF
		.text	"   A: = IDE"
		.db	CR,LF,LF,0

gocpm:		di			;disable interrupts
;
; Reset the IOBYTE to go to the main terminal
;
		ld	a,00000001B
		ld	(IOBYTE),a
;
; Set the default drive to A: and user to 0
;
		xor	a
		ld	(DefaultDisk),a
;
		jp	EnterCPM	;continue set-up
;
;********************************************************
; WARNING... The warm boot code is NOT COMPLETE!!!
;
WBOOT:		
		call	msg
		TEXT	"Entering WBOOT"
		db	CR,LF,0

;
; Need to add a lot of logic here to reload the CCP and
; BDOS from disk, but for now we know they're already
; loaded and no need to load again.


		jp	EnterCPM
;
;********************************************************
;
; This routine is entered either from the cold or warm
; boot code.  It sets up the JP instructions in the
; base page, and also sets the high-level disk driver's
; input/output address (also known as the DMA address).
;
EnterCPM:	ld	a,JMP		;Get machine code for JP
		ld	(0),a		;Set up Jp at location 0
		ld	(ENTRY),a	;...and at location 5
;
		ld	hl,WBOOTE	;Get BIOS vector address
		ld	(1),hl		;Put it at location 1
 
		ld	hl,BDOSEntry	;Get BDOS entry point address
		ld	(ENTRY+1),hl	;Put it at location 6
;
		ld	bc,80H		;Set disk I/O address to default
		call	SETDMA		;Use normal BIOS routine
;
		ei			;Ensure interrupts are enabled
		ld	a,(DefaultDisk) ;Transfer current default disk to
		ld	c,a		;  Console Command Processor
		jp	CCPEntry	;Jump to CCP



;********************************************************
; Select the disk drive for future reads/writes.  On entry
; C contains the drive index: C = 0 for A:, 1 for B:, etc.
; On Exit, HL contains the pointer to the disk parameter
; header (section 6.10 in the CP/M book) or 0000 if the
; requested drive is out of range.
;********************************************************

SELDSK:		push	bc
		call	msg
		TEXT	"SELDSK: "
		db	0
		pop	bc
		push	bc
		ld	a,c
		add	a,'A'
		ld	c,a
		call	CONOUT
		call	msg
		db	':',CR,LF,0
		pop	bc
;
; Temp patch... always do deblocking for now.  Some day
; I might add a disk that doesn't need it, but for now
; we always need it.
;
		push	af
		ld	a,0ffh
		ld	(DeblockingRequired),a
		pop	af
;
		ld	hl,0	;assume an error
		ld	a,c	;move drive into A
		cp	1	;compare to max drives
		ret	nc	;return if bad drive
;
; Compute offset to disk parameter table... drive * 16
;
		ld	l,a
		ld	h,0
		add	hl,hl	;*2
		add	hl,hl	;*4
		add	hl,hl	;*8
		add	hl,hl	;*16
		ld	de,DPBASE
		add	hl,de
		ret
;
;********************************************************
; FLOPPY DISK DPH TABLES.
;********************************************************
;
; CP/M manual, 6.10, page145
;
DPBASE:
IdeDPH:		dw	0	;no sector translation
		dw	0	;scratchpad
		dw	0
		dw	0
		dw	DirectoryBuffer
		dw	IdeDPB	;disk parameter block
		dw	IdeCSV	;checksum area
		dw	IdeALV

IdeCSV:		.FILL	0	;no directory checksum; non-removable drive
IdeALV:		.FILL	256,0	;drive size / BLS / 8

;__________________________________________________________________________________________________
;
; 8MB HARD DISK DRIVE, 65 TRKS, 1024 SECS/TRK, 128 BYTES/SEC
; BLOCKSIZE (BLS) = 4K, DIRECTORY ENTRIES = 128
; SEC/TRK ENGINEERED SO THAT AFTER DEBLOCKING, SECTOR NUMBER OCCUPIES 1 BYTE (0-255)
;
; The SPT value was taken from the track count from MYIDE (an Andrew Lynch
; program) and then multiplied by 4 since there are 4 CP/M 128 byte sectors
; in each 512 byte physical sector.
;
; Too many magic numbers in here; add some EQUs for these and use real math
; to compute the values at assembly time.
;
	.DB	(4096 / 128)	; RECORDS PER BLOCK (BLS / 128)
IdeDPB:
;	.DW  	1024		; SPT: SECTORS PER TRACK
	.DW	32*4		; SPT: Sectors per track, gotten from drive
	.DB  	5		; BSH: BLOCK SHIFT FACTOR
	.DB  	31		; BLM: BLOCK MASK
	.DB  	1		; EXM: EXTENT MASK
	.DW  	2047		; DSM: TOTAL STORAGE IN BLOCKS - 1 BLK = ((8MB - 128K OFF) / 4K BLS) - 1 = 2047
	.DW  	511		; DRM: DIR ENTRIES - 1 = 512 - 1 = 511
	.DB  	11110000B	; AL0: DIR BLK BIT MAP, FIRST BYTE
	.DB  	00000000B	; AL1: DIR BLK BIT MAP, SECOND BYTE
	.DW  	0		; CKS: DIRECTORY CHECK VECTOR SIZE = 256 / 4
	.DW  	1		; OFF: RESERVED TRACKS = 1 TRKS * (512 B/SEC * 1024 SEC/TRK) = 128K
;
DirectoryBuffer	ds	CPM_SECTOR_SIZE


;
; OLD CODE WARNING...
; This is my first attempt to calculate disk parameters.  Left it all in
; here because it's the right way to do it, but needs debugging.
;
;SECSZ:		equ	512	;bytes per sector
;CPMSECS:	equ	(SECSZ/128)	;CP/M records per phys sector
;SECTORS:	equ	64	;sectors per track
;TRACKS:		equ	(65536/SECTORS/CPMSECS);
;
;SPT:		equ	(SECTORS*CPMSECS)
;BLS:		equ	8192
;BLM:		equ	(BLS/128-1)
;	#if (BLS == 1024)
;BSH		equ	3
;	#endif
;	#if (BLS == 2048)
;BSH		equ	4
;	#endif
;	#if (BLS == 4096)
;BSH		equ	5
;	#endif
;	#if (BLS == 8192)
;BSH		equ	6
;	#endif
;	#if (BLS == 16384)
;BSH		equ	7
;	#endif
;OFF:		equ	1
;DSM:		equ	(((TRACKS-OFF)*SECSZ*SECTORS/BLS)-1)
;	#if (DSM < 256)
;EXM		equ	(BLS/1024-1)
;	#else
;EXM		equ	(BLS/2048-1)
;	#endif
;DRM:		equ	(1024-1);is this a good value?
;
;fldpb:		.dw	SPT	;CP/M records per track
;		.db	BSH	;allocation block shift
;		.db	BLM	;allocation block mask
;		.db	0	;extent mask
;		.dw	DSM	;max allocation block #
;		.dw	255	;max directory entry #
;		.db	0f0h,0	;directory allocation mask
;		.dw	64	;directory check alloc size
;		.dw	OFF	;number of reserved tracks

;IdeDPB:		dw	SECTORS	;sectors per track
;		db	BSH
;		db	BLM
;		db	EXM
;		dw	DSM
;		dw	DRM
;		db	AL0
;		db	AL1
;		dw	CKS
;		dw	OFF

	
;dphbase0:	.dw	trans		;LOGICAL TO PHYSICAL XLATE TAB
;		.dw	0		;SCRATCH
;		.dw	0
;		.dw	0
;		.dw	DIRBUF		;DIRECTORY BUFFER
;		.dw	fldpb		;DISK PARAMETER BLOCK
;		.dw	chk00		;CHECKSUM VECTOR
;		.dw	ALV0		;ALLOCATION VECTOR
;
;dphbase1:	.dw	trans
;		.dw	0
;		.dw	0
;		.dw	0
;		.dw	DIRBUF
;		.dw	fldpb
;		.dw	chk01
;		.dw	ALV1
;
;********************************************************
; Sector translation table.  The IDE drive does not do
; translation but left it here for future use.  Ie, it
; might be used later but could be removed for now.
;
trans:		.db	0,1,2,3,4,5,6,7
		.db	8,9,10,11,12,13,14,15
		.db	16,17,18,19,20,21,22,23
		.db	24,25,26,27,28,29,30,31
;
;********************************************************
; CP/M DPB
;
; AGAIN, OLD CODE WARNING!!!!  Some of this was carry-over
; from my previous attempt to read BoGUS format disks.
; BoGUS was a CP/M box made by Franklin Computer in 1984.
; There are about 3 in existance today.
;
; BoGUS = Bob Grieb's Underground System
;
; This has always been one of the most confusing bits of
; CP/M legacy.  To make things a tad easier, here are some
; bits of data that will make reading section 6.10 of the
; "CP/M Operating System Manual" a bit clearer.
;
; The CF drive I'm using (Sandisk SDCFB-192) has the
; following raw parameters.  Hex numbers first, decimal
; in parens:
;
;    Cylinders: 02DE  (734)
;    Heads:       10  (16)
;    Sectors:     20  (32)
;    Sector size:     (512)
;
; Total disk size = 734*16*32*512 = 192,413,696 bytes
;
;    SPT = 128		Sectors per track
;    BLS = 
;    1 Reserved track

;
;    BLS = 2048 (why, I don't know)
;    9 physical sectors per track, 4 CP/M sectors each
;    DOuble sided
;    2 reserved tracks
;
;TRACKS:		.equ	(80 * 2);total tracks (count both sides)
;SECTORS:	.equ	9	;sectors per track
;SECSZ:		.equ	512	;bytes per sector
;CPMSECS:	.equ	(SECSZ/128)	;CP/M records per phys sector
;
;SPT:		.equ	(SECTORS*CPMSECS)
;BLS:		.equ	2048	;ask Dave ask to why
;BSH:		.equ	4
;BLM:		.equ	((BLS/128)-1)
;OFF:		.equ	2
;DSM:		.equ	(((TRACKS-OFF)*SECSZ*SECTORS/BLS)-1)
;
;fldpb:		.dw	SPT	;CP/M records per track
;		.db	BSH	;allocation block shift
;		.db	BLM	;allocation block mask
;		.db	0	;extent mask
;		.dw	DSM	;max allocation block #
;		.dw	255	;max directory entry #
;		.db	0f0h,0	;directory allocation mask
;		.dw	64	;directory check alloc size
;		.dw	OFF	;number of reserved tracks





;********************************************************
; SET TRACK FOR FUTURE READS OR WRITES TO TRACK 0. ALSO
; PARTIALLY RESET THE DISK SYSTEM TO ALLOW FOR CHANGED
; DISKS.
;********************************************************

HOME:		call	msg
		.text	"HOME"
		db	CR,LF,0

		ld	a,(MustWriteBuffer)	;unwritten data?
		or	a
		jp	nz,HomeNoWrite
		ld	(DataInDiskBuffer),a
HomeNoWrite:	ld	c,0	;set to track 0
		jp	SETTRK


;********************************************************
; SET TRACK FOR FUTURE READS OR WRITES TO THAT PASSED
; IN REGISTER PAIR BC.
;********************************************************

SETTRK:		ld	l,c
		ld	h,b
		ld	(SelectedTrack),hl

;		call	msg
;		db	"SETTRK: ",0
;		ld	a,h
;		call	a_hex
;		ld	a,l
;		call	a_hex
;		call	crlf

		ret

;********************************************************
; SET SECTOR FOR FUTURE READS OR WRITES TO THAT PASSED
; IN REGISTER PAIR BC.
;********************************************************

SETSEC:		ld	a,c
		ld	(SelectedSector),a

;		push	af
;		call	msg
;		db	"SETSEC: ",0
;		pop	af
;		call	a_hex
;		call	crlf
		ret

;********************************************************
; SET DMA ADDRESS FOR FUTURE READS OR WRITES TO THAT
; PASSED IN REGISTER PAIR BC.
;********************************************************

SETDMA:		ld	l,c
		ld	h,b
		ld	(DMAAddress),hl

#IF 0	;debug code
		push	hl		;DEBUG
		call	msg
		db	"SETDMA: ",0
		pop	hl
		push	hl
		ld	a,h
		call	a_hex
		ld	a,l
		call	a_hex
		call	crlf
		pop	hl		;END DEBUG
#ENDIF

		ret

;********************************************************
; SECTOR TRANSLATION ROUTINE. THE ROUTINE ONLY
; TRANSLATES SECTORS ON THE USER TRACKS, SINCE CP/M
; ACCESSES THE SYSTEM TRACKS WITHOUT CALLING FOR
; TRANSLATION.
; BC contains the sector number to translate, and the
; translation table address is in DE.  Returns result
; in HL.
;********************************************************

SECTRA:		ld	l,c		;no translation
		ld	h,b
		ret

;********************************************************
; The main events... read and write routines!  They share
; a lot of common code, so each of these is pretty small,
; falls into common area, then eventually splits again.
;********************************************************

READ:
; Read in the 128-byte CP/M sector specified by previous calls
; to select disk and to set track and sector.  The sector will be read
; into the address specified in the previous call to set DMA address.
;
; If reading from a disk drive using sectors larger than 128 bytes,
; deblocking code will be used to "unpack" a 128-byte sector from
; the physical sector.

;		call	msg
;		db	"READ",CR,LF,0
		ld	a,(DeblockingRequired)	;Check if deblocking needed
		or	a			;(flag was set in SELDSK call)
		jp	z,ReadNoDeblock		;No, use normal nondeblocked
 
; The deblocking algorithm used is such
; that a read operation can be viewed
; up until the actual data transfer as
; though it was the first write to an
; unallocated allocation block.

		xor	a			;Set the record count to 0
		ld	(UnallocatedRecordCount),a ;  for first "write"
		inc	a			;Indicate that it is really a read
		ld	(ReadOperation),a	;that is to be performed
		ld	(MustPrereadSector),a	;and force a preread of the sector
						;to get it into the disk buffer
		ld	a,WriteUnallocated	;Fake deblocking code into responding
		ld	(WriteType),a		;as if this is the first write to an
						;unallocated allocation block.
		jp	PerformReadWrite	;Use common code to execute read



WRITE:
;
;  Write a 128-byte sector from the current DMA address to
;  the previously selected disk, track, and sector.
;
;  On arrival here, the BDOS will have set register C to indicate
;  whether this write operation is to an already allocated allocation
;  block (which means a preread of the sector may be needed),
;  to the directory (in which case the data will be written to the
;  disk immediately), or to the first 128-byte sector of a previously
;  unallocated allocation block (in which case no preread is required).
;
;  Only writes to the directory take place immediately.  In all other
;  cases, the data will be moved from the DMA address into the disk
;  buffer, and only written out when circumstances force the
;  transfer.  The number of physical disk operations can therefore
;  be reduced considerably.
;

   ld      a,(DeblockingRequired) ;Check if deblocking is required
   or      a                       ;(flag set in SELDSK call)
   jp      z,WriteNoDeblock
 
   xor     a                       ;Indicate that a write operation
   ld      (ReadOperation),a      ;  is required (i.e. NOT a read)
   ld      a,c                     ;Save the BDOS write type
   ld      (WriteType),a
   cp      WriteUnallocated       ;Check if the first write to an
				   ;  unallocated allocation block
   jp      nz,CheckUnallocatedBlock  ;No, check if in the middle of
				   ;  writing to an unallocated block
				   ;Yes, first write to unallocated
				   ;  allocation block -- initialize
				   ;  variables associated with
				   ;  unallocated writes.
   ld      a,AllocationBlockSize/128      ;Get number of 128-byte
					    ;  sectors and
   ld      (UnallocatedRecordCount),a     ;  set up a count.
					    ;
   ld      hl,SelectedDkTrkSec           ;Copy disk, track and sector
   ld      de,UnallocatedDkTrkSec        ;  into unallocated variables
   call    MoveDkTrkSec

;
;  Check if this is not the first write to an unallocated
;  allocation block -- if it is, the unallocated record count
;  has just been set to the number of 128-byte sectors in the
;  allocation block.
;
CheckUnallocatedBlock:
   ld      a,(UnallocatedRecordCount)
   or      a
   jp      z,RequestPreread       ;No, this is a write to an
				   ;  allocated block
				   ;Yes, this is a write to an
				   ;  unallocated block
   dec     a                       ;Count down on number of 128-byte sectors
				   ;  left unwritten to in allocation block
   ld      a,(UnallocatedRecordCount)    ;  and store back new value.
 
   ld      hl,SelectedDkTrkSec  ;Check if the selected disk, track,
   ld      de,UnallocatedDkTrkSec       ;  and sector are the same as for
   call    CompareDkTrkSec      ;  those in the unallocated block.
   jp      nz,RequestPreread      ;No, a preread is required
				   ;Yes, no preread is needed.
				   ;Now is a convenient time to
				   ;  update the current sector and see
				   ;  if the track also needs updating.
;
				   ;By design, Compare$Dk$Trk$Sec
				   ; returns with
				   ; DE -> Unallocated$Sector
   ex      de,hl                   ; HL -> Unallocated$Sector
   inc     (hl)                    ;Update Unallocated$Sector
   ld      a,(hl)                  ;Check if sector now > maximum
   cp      CPMSecPerTrack       ; on a track
   jp      c,NoTrackChange       ;No (A < (HL) )
				   ;Yes,
   ld      (hl),0                  ;Reset sector to 0
   ld      hl,(UnallocatedTrack)  ;Increase track by 1
   inc     hl
   ld      (UnallocatedTrack),hl
;
NoTrackChange:
				   ;Indicate to later code that
				   ;  no preread is needed.
   xor     a
   ld      (MustPrereadSector),a ;Must$Preread$Sector=0
   jp      PerformReadWrite

RequestPreread:
   xor     a                       ;Indicate that this is not a write
   ld      (UnallocatedRecordCount),a   ;  into an unallocated block.
   inc     a
   ld      (MustPrereadSector),a ;Indicate that a preread of the
				   ;  physical sector is required.
;
;
PerformReadWrite:                ;Common code to execute both reads and
				   ;  writes of 128-byte sectors.
   xor     a                       ;Assume that no disk errors will
   ld      (DiskErrorFlag),a     ;  occur
 
   ld      a,(SelectedSector)     ;Convert selected 128-byte sector
   rra                             ;  into physical sector by dividing by 4
   rra
   and     3fh                     ;Remove any unwanted bits
   ld      (SelectedPhysicalSector),a
				   ;
   ld      hl,DataInDiskBuffer  ;Check if disk buffer already has
   ld      a,(hl)                  ;  data in it.
   ld      (hl),1                  ;(Unconditionally indicate that
				   ; the buffer now has data in it)
   or      a                       ;Did it indeed have data in it?
   jp      z,ReadSectorIntoBuffer  ;No, proceed to read a physical
				   ;  sector into the buffer.
				   ;
			 ;The buffer does have a physical sector
			 ;  in it.
			 ;  Note: The disk, track, and PHYSICAL
			 ;  sector in the buffer need to be
			 ;  checked, hence the use of the
			 ;  Compare$Dk$Trk subroutine.
			 ;
   ld      de,InBufferDkTrkSec ;Check if sector in buffer is the
   ld      hl,SelectedDkTrkSec  ;  same as that selected earlier
   call    CompareDkTrk          ;Compare ONLY disk and track
   jp      nz,SectorNotInBuffer ;No, it must be read in
 
   ld      a,(InBufferSector)    ;Get physical sector in buffer
   ld      hl,SelectedPhysicalSector
   cp      (hl)                    ;Check if correct physical sector
   jp      z,SectorInBuffer      ;Yes, it is already in memory
SectorNotInBuffer:
				   ;No, it will have to be read in
				   ;  over current contents of buffer
		ld	a,(MustWriteBuffer)   ;Check if buffer has data in that
		or	a                       ;  must be written out first
		call	nz,WritePhysical       ;Yes, write it out
;
ReadSectorIntoBuffer:
   call    SetInBufferDkTrkSec        ;Set in buffer variables from
				   ; selected disk, track, and sector
				   ; to reflect which sector is in the
				   ; buffer now.
   ld      a,(MustPrereadSector) ;In practice, the sector need only
   or      a                       ;  be physically read in if a preread
				   ;  is required
   call    nz,ReadPhysical        ;Yes, preread the sector
   xor     a                       ;Reset the flag to reflect buffer
   ld      (MustWriteBuffer),a   ;  contents.
;
SectorInBuffer:         ;Selected sector on correct track and
			  ;  disk is already in the buffer.
			  ;Convert the selected CP/M (128-byte)
			  ;  sector into a relative address down
			  ;  the buffer.
   ld      a,(SelectedSector)     ;Get selected sector number
   and     SectorMask             ;Mask off only the least significant bits
   ld      l,a                     ;Multiply by 128 by shifting 16-bit value
   ld      h,0                     ;  left 7 bits
   add     hl,hl                   ;* 2
   add     hl,hl                   ;* 4
   add     hl,hl                   ;* 8
   add     hl,hl                   ;* 16
   add     hl,hl                   ;* 32
   add     hl,hl                   ;* 64
   add     hl,hl                   ;* 128
;
   ld      de,DiskBuffer          ;Get base address of disk buffer
   add     hl,de                   ;Add on sector number * 128
				   ;HL -> 128-byte sector number start
				   ;  address in disk buffer
   ex      de,hl                   ;DE -> sector in disk buffer
   ld      hl,(DMAAddress)        ;Get DMA address set in SETDMA call
   ex      de,hl                   ;Assume a read operation, so
				   ;  DE -> DMA address
				   ;  HL -> sector in disk buffer
   ld      c,128/8                 ;Because of the faster method used
				   ;  to move data in and out of the 
				   ;  disk buffer, (eight bytes moved per
				   ;  loop iteration) the count need only
				   ;  be 1/8th of normal.
				   ;At this point --
				   ;       C = loop count
				   ;       DE -> DMA address
				   ;       HL -> sector in disk buffer
   ld      a,(ReadOperation)      ;Determine whether data is to be moved
   or      a                       ;  out of the buffer (read) or into the
   jp      nz,BufferMove          ;  buffer (write)
				   ;Writing into buffer
				   ;(A must be 0 get here)
   inc     a                       ;Set flag to force a write
   ld      (MustWriteBuffer),a   ;  of the disk buffer later on.
   ex      de,hl                   ;Make DE -> sector in disk buffer
				   ;     HL -> DMA address
;
;
BufferMove:               ;The following move loop moves eight bytes
			   ;  at a time from (HL) to (DE), C contains
			   ;  the loop count.
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
   ld      a,(hl)          ;Get byte from source
   ld      (de),a          ;Put into destination
   inc     de              ;Update pointers
   inc     hl
 
   dec     c               ;Count down on loop counter
   jp      nz,BufferMove  ;Repeat until CP/M sector moved
                           ;
   ld      a,(WriteType)  ;If write to directory, write out
   cp      WriteDirectory ;  buffer immediately
   ld      a,(DiskErrorFlag)  ;Get error flag in case delayed write or read
   ret     nz              ;Return if delayed write or read
			   ;
   or      a               ;Check if any disk errors have occured
   ret     nz              ;Yes, abandon attempt to write to directory
			   ;
   xor     a               ;Clear flag that indicates buffer must be
   ld      (MustWriteBuffer),a   ;  written out
   call    WritePhysical  ;Write buffer out to physical sector
   ld      a,(DiskErrorFlag)     ;Return error flag to caller
   ret
;
;
SetInBufferDkTrkSec:          ;Indicate selected disk, track, and
				   ;  sector now residing in buffer
   ld      a,(SelectedDisk)
   ld      (InBufferDisk),a
 
   ld      hl,(SelectedTrack)
   ld      (InBufferTrack),hl
 
   ld      a,(SelectedPhysicalSector)
   ld      (InBufferSector),a
 
   ret
;
CompareDkTrk:            ;Compares just the disk and track
			   ;  pointed to by DE and HL
   ld      c,3             ;Disk (1), track (2)
   jp      CompareDkTrkSecLoop  ;Use common code
 
CompareDkTrkSec:        ;Compares the disk, track, and sector
			   ;  variables pointed to by DE and HL
   ld      c,4             ;Disk (1), track (2), and sector (1)
CompareDkTrkSecLoop:
   ld      a,(de)          ;Get comparitor
   cp      (hl)            ;Compare with comparand
   ret     nz              ;Abandon comparison if inequality found
   inc     de              ;Update comparitor pointer
   inc     hl              ;Update comparand pointer
   dec     c               ;Count down on loop count
   ret     z               ;Return (with zero flag set)
   jp      CompareDkTrkSecLoop
;
; Moves the disk, track and sector
; variables pointed at by HL to
; those pointed at by DE
;
MoveDkTrkSec:	ld	c,4	;Disk (1), track (2), and sector (1)
MoveDkTrkSecLoop:
		ld	a,(hl)	;Get source byte
		ld	(de),a	;Store in destination
		inc	de	;Update pointers
		inc	hl
		dec	c	;Count down on byte count
		ret	z	;Return if all bytes moved
		jp	MoveDkTrkSecLoop





;
; Should not get here with the IDE!
;

ReadNoDeblock:
		call	msg
		db	"ERROR - ReadNoDeblock",CR,LF,0
		ret

WriteNoDeblock:
		call	msg
		db	"ERROR - WriteNoDeblock",CR,LF,0
		ret



;
; Here's the big high-level view of the logic here.  It's
; rather involved since a lot of decisions needs to be made.
;
; First, the variables:
;
; DRIVE  = This is the drive the user has selected. It may not
;          be the same drive currently in use.
;
; TRACK  = This is the track the user wants to use, 0-79.  It
;          may not be the current track we're on.
;
; SECTOR = The CP/M logic sector the user wants to use.  0 - 35.
;          Again, this might not be the same as the current one.
;
; CURDRV = This is the currently selected drive OR NODRIVE if
;          none selected yet.  If NODRIVE that implies this is
;          the first disk access.
;
; CURTRK = Track where the current drive has its head located.
;          NOTRACK implies the location is unknown.
;
; CURSEC = Current physical sector with the side bit (bit 0) still
;          included.
;

; So here's the drive select logic...
;
; if (DRIVE != CURDRV) - a new drive is being selected
;    if (CURDRV != NODRIVE) - if a valid drive is already selected
;       Save the current track into the drive data area.
;       Load the new drive's data from the drive data area.
;       if (CURTRK == NOTRACK) - first time for this disk
;          Home disk
;          set CURTRK to 0
;       else
;          save track to FDC
;    else
;       Home disk
;       set CURTRK to 0
;
; ...followed by the track select logic...
;
; if (TRACK != CURTRK)
;    seek to TRACK
;    set CURTRK to TRACK
;
; ...and then compute physical sector and side...
;
; divide sector by 4 for temp sector
; if bit 0 is set then select side 0, else select side 1
; divide the temp sector by 2.  This is now CURSEC.
; load CURSEC into the sector register
;
; Perform read or write operation
; 





;
;********************************************************
; Initilze the 8255 and drive then do a hard reset on the drive, 
;
IDEinit:	ld	a,READcfg8255	;10010010b
		OUT	(IDEportCtrl),a	;Config 8255 chip, READ mode

		ld	a,IDErstline
		OUT	(IDEportC),a	;Hard reset the disk drive

		ld	B,020H		;<<<<< fine tune later
ResetDelay:	DJNZ	ResetDelay	;Delay (reset pulse width)
		xor	a
		out	(IDEportC),a	;No IDE control lines asserted
				
		ld	D,11100000b	;Data for IDE SDH reg (512bytes, LBA mode,single drive,head 0000)
					;For Trk,Sec,head (non LBA) use 10100000
					;Note. Cannot get LBA mode to work with an old Seagate Medalist 6531 drive.
					;have to use teh non-LBA mode. (Common for old hard disks).

		ld	E,REGshd	;00001110,(0EH) for CS0,A2,A1,  
		CALL	IDEwr8D		;Write byte to select the MASTER device
;
		ld	B,0FFH		;<<< May need to adjust delay time
WaitInit:	ld	E,REGstatus	;Get status after initilization
		CALL	IDErd8D		;Check Status (info in [D])
		BIT	7,D
		jp	z,DoneInit	;Return if ready bit is zero
		ld	A,2
		CALL	DELAYX		;Long delay, drive has to get up to speed
		DJNZ	WaitInit
		CALL	SHOWerrors	;Ret with NZ flag set if error (probably no drive)
		RET
DoneInit:	xor	A
		RET
;	
DELAYX:		ld	(DELAYStore),a
		PUSH	BC
		ld	bc,0FFFFH	;<<< May need to adjust delay time to allow cold drive to
DELAY2:		LD	a,(DELAYStore)	;    get up to speed.
DELAY1:		dec	a
		jp	nz,DELAY1
		dec	bc
		ld	A,C
		or	b
		jp	nz,DELAY2
		POP	BC
		RET
;
;********************************************************
; Read a sector, specified by the 4 bytes in LBA
; Z on success, NZ call error routine if problem
;
ReadPhysical:	ld	hl,DiskBuffer
		ld	a,042h
		ld	b,0
rpfill		ld	(hl),a
		inc	hl
		ld	(hl),a
		inc	hl
		djnz	rpfill

		call	msg
		db	"ReadPhysical",CR,LF,0

		CALL	wrlba		;Tell which sector we want to read from.
					;Note: Translate first in case of an error otherewise we 
					;will get stuck on bad sector 
		CALL	IDEwaitnotbusy	;make sure drive is ready
		jp	c,SHOWerrors	;Returned with NZ set if error

		ld	D,COMMANDread
		ld	E,REGcommand
		CALL	IDEwr8D		;Send sec read command to drive.
		CALL	IDEwaitdrq	;wait until it's got the data
		jp	c,SHOWerrors
;		
		ld	hl,DiskBuffer		;DMA address
		ld	B,0		;Read 512 bytes to [HL] (256X2 bytes)
MoreRD16:	ld	A,REGdata	;REG regsiter address
		OUT	(IDEportC),a	

		OR	IDErdline	;08H+40H, Pulse RD line
		OUT	(IDEportC),a	

		IN	a,(IDEportA)	;Read the lower byte first (Note early versions had high byte then low byte
		ld	(hl),a		;this made sector data incompatable with other controllers).
		inc	hl
		IN	a,(IDEportB)	;THEN read the upper byte
		ld	(hl),A
		inc	hl
	
		ld	A,REGdata	;Deassert RD line
		OUT	(IDEportC),a
		DJNZ	MoreRD16

		ld	E,REGstatus
		CALL	IDErd8D
		ld	A,D
		BIT	0,A
		call	nz,SHOWerrors	;If error display status
		RET
;
;********************************************************
;Write a sector, specified by the 3 bytes in LBA (@ IX+0)",
;Z on success, NZ to error routine if problem
;
WritePhysical:
;		call	msg
;		db	"WritePhysical",CR,LF,0

		CALL	wrlba		;Tell which sector we want to read from.
					;Note: Translate first in case of an error otherewise we 
					;will get stuck on bad sector 
		CALL	IDEwaitnotbusy	;make sure drive is ready
		jp	c,SHOWerrors

		ld	D,COMMANDwrite
		ld	E,REGcommand
		CALL	IDEwr8D		;tell drive to write a sector
		CALL	IDEwaitdrq	;wait unit it wants the data
		jp	c,SHOWerrors
;
		ld	hl,DiskBuffer
		ld	B,0		;256X2 bytes

		ld	A,WRITEcfg8255
		OUT	(IDEportCtrl),a
WRSEC1:		ld	A,(hl)
		inc	hl
		OUT	(IDEportA),a	;Write the lower byte first (Note early versions had high byte then low byte
		ld	A,(hl)		;this made sector data incompatable with other controllers).
		inc	hl
		OUT	(IDEportB),a	;THEN High byte on B
		ld	A,REGdata
		PUSH	af
		OUT	(IDEportC),a	;Send write command
		OR	IDEwrline	;Send WR pulse
		OUT	(IDEportC),a
		POP	af
		OUT	(IDEportC),a
		DJNZ	WRSEC1
	
		ld	A,READcfg8255	;Set 8255 back to read mode
		OUT	(IDEportCtrl),a	

		ld	E,REGstatus
		CALL	IDErd8D
		ld	A,D
		BIT	0,A
		call	nz,SHOWerrors	;If error display status
		RET
;
;********************************************************
; Write the logical block address to the drive's registers
; Note we do not need to set the upper nibble of the LBA
; It will always be 0 for these small drives.  Use the
; physical sector number which has already been divided
; down from the logical sector number.
;
wrlba:		ld	hl,(SelectedPhysicalSector)
		ld	a,l
		inc	a	;Sectors are numbered 1 to MAXSEC
		ld	(DRIVESEC),a	;For Diagnostic Display Only
		ld	D,A
		ld	E,REGsector	;Send info to drive
		call	IDEwr8D
				;Note: For drive we will have 0 - MAXSEC sectors only
;		ld	hl,TRK
		ld	hl,(SelectedTrack)
		ld	A,L
		ld	(DRIVETRK),a
		ld	D,L		;Send Low TRK#
		ld	E,REGcylinderLSB
		call	IDEwr8D

		ld	A,H
		ld	(DRIVETRK+1),a
		ld	D,H		;Send High TRK#
		ld	E,REGcylinderMSB
		call	IDEwr8D

		ld	D,1		;For now, one sector at a time
		ld	E,REGseccnt
		call	IDEwr8D

;DEBUG
		call	msg
		.text	"wrlba - Track "
		.db	0
		ld	a,(DRIVETRK+1)
		call	a_hex
		ld	a,(DRIVETRK)
		call	a_hex
		call	msg
		.db	", Sector ",0
		ld	a,(DRIVESEC)
		call	a_hex
		call	msg
		.db	CR,LF,0
;END DEBUG
		RET
;
;********************************************************
;ie Drive READY if 01000000
;
IDEwaitnotbusy:	ld	B,0FFH
		ld	A,0FFH		;Delay, must be above 80H for 4MHz Z80. Leave longer for slower drives
		ld	(DELAYStore),a

MoreWait:	ld	E,REGstatus	;wait for RDY bit to be set
		CALL	IDErd8D
		ld	A,D
		and	11000000B
		xor	01000000B
		jp	z,DoneNotBusy	
		DJNZ	MoreWait
		ld	a,(DELAYStore)	;Check timeout delay
		dec	A
		ld	(DELAYStore),a
		jp	nz,MoreWait
		scf			;Set carry to indicqate an error
		ret
DoneNotBusy:	or	A		;Clear carry it indicate no error
		RET
;
;Wait for the drive to be ready to transfer data.
;Returns the drive's status in Acc
;
IDEwaitdrq:	ld	B,0FFH
		ld	A,0FFH		;Delay, must be above 80H for 4MHz Z80. Leave longer for slower drives
		ld	(DELAYStore),a

MoreDRQ:	ld	E,REGstatus	;wait for DRQ bit to be set
		CALL	IDErd8D
		ld	A,D
		and	10001000B
		cp	00001000B
		jp	z,DoneDRQ
		DJNZ	MoreDRQ
		ld	a,(DELAYStore)	;Check timeout delay
		dec	A
		ld	(DELAYStore),a
		jp	nz,MoreDRQ
		scf			;Set carry to indicate error
		RET
DoneDRQ:	OR	A		;Clear carry
		RET
;
;********************************************************
; Low Level 8 bit R/W to the drive controller.  These are 
; the routines that talk directly to the drive controller
; registers, via the 8255 chip.  Note the 16 bit I/O to
; the drive (which is only for SEC R/W) is done directly 
; in the read/write functions for speed reasons.
;
; READ 8 bits from IDE register in [E], return info in [D]
;
IDErd8D:	ld	A,E
		OUT	(IDEportC),a		;drive address onto control lines

		OR	IDErdline		;RD pulse pin (40H)
		OUT	(IDEportC),a		;assert read pin

		IN	a,(IDEportA)
		ld	D,A			;return with data in [D]

		xor	A
		OUT	(IDEportC),a		;Zero all port C lines
		ret
;
; WRITE Data in [D] to IDE register in [E]
;
IDEwr8D:	ld	A,WRITEcfg8255		;Set 8255 to write mode
		OUT	(IDEportCtrl),a

		ld	A,D			;Get data put it in 8255 A port
		OUT	(IDEportA),a

		ld	A,E			;select IDE register
		OUT	(IDEportC),a

		OR	IDEwrline		;lower WR line
		OUT	(IDEportC),a
		NOP

		xor	A			;Deselect all lines including WR line
		OUT	(IDEportC),a

		ld	A,READcfg8255		;Config 8255 chip, read mode on return
		OUT	(IDEportCtrl),a
		RET


SHOWerrors:	call	msg
		.TEXT	"SHOWerrors called"
		.db	CR,LF,0

		.page
;********************************************************
; Input/Output devices.  For now, just call the TTY
; functions, but later I'll add iobyte support.
;
CONST:		jp	ttystat
CONIN:		jp	ttyin
CONOUT:		jp	ttyout
;
;********************************************************
; Message output subroutines.  msghl will print the null-
; terminated message pointed to by HL.  msg will
; print the null terminated string immediately following
; the "call MSG" line.
;
msg:		ex	(sp),hl
		call	msghl
		ex	(sp),hl
		ret
;
msghl:		ld	a,(hl)
		or	a
		ret	z
		ld	c,a
		call	CONOUT
		inc	hl
		jr	msghl
;
;********************************************************
; Display the contents of A as two hex digits
;
a_hex:		push	af
		rrca
		rrca
		rrca
		rrca
		call	ahex2
		pop	af
ahex2:		and	0fh
		add	a,90h
		daa
		adc	a,40h
		daa
		ld	c,a
		jr	ttyout
;
;********************************************************
; Do a CR/LF
;
crlf:		ld	c,CR
		call	ttyout
		ld	c,LF
		jr	ttyout
		.page
;
;********************************************************
; Other I/O devices.  Make them all do nothing for now.
;
LIST:		jp	ttyout
PUNCH:		ret
READER:		ld	a,EOF
		ret
LISTST:		ld	a,TRUE
		ret

#include "ccs2710.inc"



; stuff from bios.mac

InBufferDkTrkSec:                     ;Variables for physical sector
                                          ; currently in Disk$Buffer in memory
InBufferDisk:           db      0       ; These are moved and compared
InBufferTrack:          dw      0       ; as a group, so do not alter
InBufferSector:         db      0       ; these lines.
;
DataInDiskBuffer:      db      0       ;When nonzero, the disk buffer has
					  ; data from the disk in it.
MustWriteBuffer:        db      0       ;Nonzero when data has been
					  ; written into Disk$Buffer but
					  ; not yet written out to disk

DMAAddress:	dw	0

WriteType	db	0

		  ;These are the values handed over by the BDOS
		  ;  when it calls the WRITE operation.
		  ;The allocated/unallocated indicates whether the
		  ;  BDOS is set to write to an unallocated allocation
		  ;  block (it only indicates this for the first
		  ;  128-byte sector write) or to an allocation block
		  ;  that has already been allocated to a file.
		  ;The BDOS also indicates if it is set to write to
		  ;  the file directory.
		  ;
WriteAllocated           equ     0
WriteDirectory           equ     1
WriteUnallocated         equ     2

;
;Variables for selected disk, track, and sector
; (Selected by SELDSK, SETTRK,n and SETSEC)
;
; Note that these are in a specific order, so do not change
; the size nor order without checking where other pieces of
; code are affected!
;
SelectedDkTrkSec:
SelectedDisk:		db	0	; These are moved and
SelectedTrack:		dw	0	; compared as a group so
SelectedSector:		db	0	; do not alter order.
SelectedPhysicalSector:	db	0	;Selected physical sector derived
					;  from selected (CP/M) sector by
					;  shifting it right the number of
					;  bits specified by 
					;  Sector$Bit$Shift
;
SelectedDiskType:       db      0       ;Set by SELDSK to indicate either
					  ;  8" or 5 1/4" floppy
SelectedDiskDeblock:    db      0       ;Set by SELDSK to indicate whether
					  ;  deblocking is required.

UnallocatedDkTrkSec:           ;Parameters for writing to a previously
					  ;  unallocated allocation block.
UnallocatedDisk:         db      0       ; These are moved and compared
UnallocatedTrack:        dw      0       ; as a group so do not alter
UnallocatedSector:       db      0       ; these lines.
 
UnallocatedRecordCount: db      0       ;Number of unallocated "records"
					  ; in current previously unallocated
					  ; allocation block.
 
DiskErrorFlag:          db      0       ;Nonzero to indicate an error
					  ;  that could not be recovered
					  ;  by the disk drivers.  BDOS will
					  ;  output a "bad sector" message.

;
;Flags used inside the deblocking code
 
MustPrereadSector:	db	0	;Nonzero if a physical sector must
					;  be read into the disk buffer
					;  either before a write to an
					;  allocated block can occur, or
					;  for a normal CP/M 128-byte
					;  sector read
ReadOperation:		db	0	;Nonzero when a CP/M 128-byte
					;  sector is to be read
DeblockingRequired:	db	0	;Nonzero when the selected disk
					;  needs deblocking (set in SELDSK)
DiskType:		db	0	;Indicates 8" or 5 1/4" floppy
					;  selected (set in SELDSK).


;
; This is the actual sector size
; for the 5 1/4" mini-floppy diskettes.
; The 8" diskettes use 128-byte sectors.
; Declare the physical disk buffer for the
; 5 1/4" diskettes
;
; This is the low level buffer used to hold a sector of data.
;
PhysicalSectorSize	equ	512
DiskBuffer:	ds	PhysicalSectorSize
;
;  Data written to, or read from, the mini-floppy drive is transferred
;  via a physical buffer that is actually 512 bytes long (it was
;  declared at the front of the BIOS and holds the "one-time"
;  initialization code used for the cold boot procedure).
;
;  The blocking/deblocking code attempts to minimize the amount
;  of actual disk I/O by storing the disk, track, and physical sector
;  currently residing in the Physical Buffer.  If a read request is for
;  a 128-byte CP/M "sector" that already is in the physical buffer,
;  then no disk access occurs.
;
;
AllocationBlockSize	equ	2048
PhysicalSecPerTrack	equ	18
CPMSecPerPhysical	equ	PhysicalSectorSize/128
CPMSecPerTrack		equ	CPMSecPerPhysical*PhysicalSecPerTrack
SectorMask		equ	CPMSecPerPhysical-1
SectorBitShift		equ	2	;LOG2(CPM$Sec$Per$Physical)



; stuff from MYIDE

DELAYStore:	DS	1
DRIVESEC:	db	0
DRIVETRK:	dw	0

;
; This MUST BE the last label!
;
BIOS_END	.equ	*

		.end
