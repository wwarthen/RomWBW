/* cpmbind.h 5/21/2012 dwg - added b1f0peek and b1f0poke */
/* cpmbind.h 3/16/2012 dgw - created */


#define CR 0x0d
#define LF 0x0a
#define ESC 27

#define BIOSAD 0x0e600
#define pTermType 0x0E679

/*************************/
/* BIOS Memory Locations */
/*************************/

#define CURDRV  0x00004
#define BIOSAD  0x0e600

#define pBOOT	0x0E600
#define pWBOOT	0x0E603
#define pCONST	0x0E606
#define pCONIN	0x0E609
#define pCONOUT	0x0E60C
#define pLIST	0x0E60F
#define pPUNCH	0x0E612
#define pREADER	0x0E615
#define pHOME	0x0E618
#define pSELDSK	0x0E61B
#define pSETTRK	0x0E61E
#define pSETSEC	0x0E621	
#define pSETDMA	0x0E624
#define pREAD	0x0E627
#define pWRITE	0x0E62A
#define pLISTST	0x0E62D
#define pSECTRN	0x0E630
#define pBNKSEL	0x0E633
#define pGETLU  0x0E636
#define pSETLU  0x0E639
#define pGETINFO 0x0E63C
#define pB1F0PEEK 0x0E63F
#define pB1F0POKE 0x0E642

/*

struct JMP {
	unsigned char opcode;
	unsigned int address;
};

struct BIOS {
	struct JMP boot;
	struct JMP wboot;
	struct JMP const;
	struct JMP conin;
	struct JMP conout;
	struct JMP list;
	struct JMP punch;
	struct JMP reader;
	struct JMP home;
	struct JMP seldsk;
	struct JMP settrk;
	struct JMP setsec;
	struct JMP setdma;
	struct JMP read;
	struct JMP write;
	struct JMP listst;
	struct JMP sectrn;
	struct JMP bnksel;
	struct JMP getlu;
	struct JMP setlu;
	struct JMP getinfo;
	struct JMP b1f0peek;
	struct JMP b1f0poke;
	struct JMP res1;
	struct JMP res2;
	
	char rmj;
	char rmn;
	char rup;
	char rtp;
	char diskboot;
	char bootdrive;
	char timedate[6];
	char cpufreq;
	char platform;
	char dioplat;
	char vduplt;
	unsigned int romsize;
	unsigned int ramsize;
	char clrramdisk;
	char dskyenable;
	char uartenable;
	char vduenable;
	char fdenable;
	char fdtrace;
	char fdmedia;
	char fdmediaalt;
	char fdmauto;
	char ideenable;
	char idetrace;
	char ide8bit;
	unsigned int idecapacity;
	char ppideenable;
	char ppidetrace;
	char ppide8bit;
	unsigned int ppidecapacity;
	char ppideslow;
	char boottype;
	char boot_timeout;
	char boot_default;
	unsigned int baudrate;
	char clkdiv;
	char memwait;
	char iowait;
	char cntlb0;
	char cntlb1;
	char sdenable;
	char sdtrace;
	unsigned int sdcapacity;
	char sdcsio;
	char sdcsiofast;
	char defiobyte;
	char termtype;
	unsigned int revision;
	char prpsdenable;
	char prpsdtrace;
	char prpsdcapacity;
	char prpconenable;
	unsigned int biossize;
};

*/

/*


*/

/* bioscall.h 3/10/2012 dwg - header file for bdoscall */

	extern	char         irega;
	extern	unsigned int iregbc;
	extern  unsigned int iregde;
	extern	unsigned int ireghl;
	extern	bioscall();


/*********************/	
/* BDOS Declarations */
/*********************/

#define TERMCPM		0
#define	CONIN		1
#define CWRITE		2
#define	DIRCONIO	6
#define PRINTSTR	9
#define	RDCONBUF	10
#define	GETCONST	11
#define RETVERNUM	12
#define	RESDISKSYS	13
#define	SELECTDISK	14
#define	FOPEN		15
#define	FCLOSE		16
#define SEARCHFIRST	17
#define	SEARCHNEXT	18
#define	FDELETE		19
#define	FREADSEQ	20
#define	FWRITESEQ	21
#define FMAKEFILE	22
#define	FRENAME		23
#define	RETLOGINVEC	24
#define	RETCURRDISK	25
#define	SETDMAADDR	26
#define	GETALLOCVEC	27
#define	WRPROTDISK	28
#define	GETROVECTOR	29
#define	FSETATTRIB	30
#define	GETDPBADDR	31
#define	SETGETUSER	32
#define	FREADRANDOM	33
#define	FWRITERAND	34
#define FCOMPSIZE	35
#define	SETRANDREC	36
#define	RESETDRIVE	37
#define	WRRANDFILL	38

#define	DRIVEA		0

/* bdoscall.h 3/10/2012 dwg - header file for bdoscall */

	extern	char         drega;
	extern	unsigned int dregbc;
	extern  unsigned int dregde;
	extern	unsigned int dreghl;
	extern	bdoscall();

/* std.h 3/11/2012 dwg - c version of std.asm */

#define TERM_TTY 0
#define TERM_ANSI 1
#define TERM_WYSE 2
#define TERM_VT52 3

#define	DEV_MD		0x00
#define DEV_FD		0x10
#define DEV_IDE 	0x20
#define DEV_ATAPI 	0x30
#define DEV_PPIDE 	0x40
#define DEV_SD		0x50
#define DEV_PRPSD 	0x60

#define PLT_N8VEM 1
#define PLT_ZETA  2
#define PLT_N8    3


/*


; std.lib 2/21/2012 dwg - added TERM$VT52

; TRUE	equ	1
; FALSE	equ	00
; 
; PRIMARY HARDWARE PLATFORMS
; PLT$N8VEM	equ	1	; N8VEM ECB Z80 SBC
; PLT$ZETA	equ	2	; ZETA Z80 SBC
; PLT$N8		equ	3	; N8 (HOME COMPUTER) Z180 SBC
; 
; BOOT STYLE
; BT$MENU		equ	1	; WAIT FOR MENU SELECTION AT LOADER PROMPT
; BT$AUTO		equ	2	; AUTO SELECT BOOT$DEFAULT AFTER BOOT$TIMEOUT
; 
; VDU PLATFORM SELECTIONS
; 
;
; VDUPLT$NONE	equ	0	; NO VDU
; VDUPLT$VDU	equ	1	; ORIGINAL ECB VDU (6545 CHIP)
; VDUPLT$VDUC	equ	2	; ECB VDU COLOR (PENDING HARDWARE DEVELOPMENT)
; VDUPLT$PROPIO	equ	3	; ECB PROPIO (NOT IMPLEMENTED)
; VDUPLT$N8	equ	4	; N8 ONBOARD VIDEO SUBSYSTEM (NOT IMPLEMENTED)
; 
; RAM DISK INITIALIZATION OPTIONS
; CLR$NEVER	equ	0		; NEVER CLEAR RAM DISK
; CLR$AUTO	equ	1		; CLEAR RAM DISK IF INVALID DIR ENTRIES
; CLR$ALWAYS	equ	2		; ALWAYS CLEAR RAM DISK
; 
;
; ; DISK MAP SELECTION OPTIONS
; 
; DM$ROM		equ	1		; ROM DRIVE PRIORITY
; DM$RAM		equ	2		; RAM DRIVE PRIORITY
; DM$FD		equ	3		; FLOPPY DRIVE PRIORITY
; DM$IDE		equ	4		; IDE DRIVE PRIORITY
; DM$PPIDE	equ	5		; PPIDE DRIVE PRIORITY
; DM$SD		equ	6		; SD DRIVE PRIORITY
; DM$PRPSD	equ	7		; PROPIO SD DRIVE PRIORITY
; 
;
; ; FLOPPY DISK MEDIA SELECTIONS (ID'S MUST BE INDEX OF ENTRY IN FCD$TBL)
; 
;
; FDM720		equ	0		; 3.5" FLOPPY, 720KB, 2 SIDES, 80 TRKS, 9 SECTORS
; FDM144		equ	1		; 3.5" FLOPPY, 1.44MB, 2 SIDES, 80 TRKS, 18 SECTORS
; FDM360		equ	2		; 5.25" FLOPPY, 360KB, 2 SIDES, 40 TRKS, 9 SECTORS
; FDM120		equ	3		; 3.5" FLOPPY, 1.2MB, 2 SIDES, 80 TRKS, 15 SECTORS
; 
;
; ; DISK PLATFORM SELECTIONS
; 
; DIOPLT$NONE	equ	0		; NO DISK IO HARDWARE
; DIOPLT$DISKIO	equ	1		; N8VEM ECB DISK IO BOARD
; DIOPLT$ZETA	equ	2		; ZETA BUILT-IN DISK IO SECTION
; DIOPLT$DIDE	equ	3		; N8VEM ECB DUAL IDE W/ FLOPPY BOARD
; DIOPLT$N8	equ	4		; N8 BUILT-IN DISK IO SECTION
; DIOPLT$DISKIO3	equ	5		; N8VEM ECB DISK IO V3 BOARD
; 
; CONSOLE DEVICE CHOICES FOR LDRCON AND DBGCON IN CONFIG SETTINGS
; 
; CON$UART	equ	1
; CON$VDU		equ	2
; CON$PRP		equ	3
; 
; CONSOLE TERMINAL TYPE CHOICES
; 
TERM$TTY	equ	0
TERM$ANSI	equ	1
TERM$WYSE	equ	2
TERM$VT52	equ	3
; 
;
; ; SYSTEM GENERATION SETTINGS
; 
; SYS$CPM		equ	1		; CPM (IMPLIES BDOS + CCP)
; SYS$ZSYS	equ	2		; ZSYSTEM OS (IMPLIES ZSDOS + ZCPR)
; 
; DOS$BDOS	equ	1		; BDOS
; DOS$ZDDOS	equ	2		; ZDDOS VARIANT OF ZSDOS
; DOS$ZSDOS	equ	3		; ZSDOS
; 
; CP$CCP		equ	1		; CCP COMMAND PROCESSOR
; CP$ZCPR		equ	2		; ZCPR COMMAND PROCESSOR
; 
; CONFIGURE DOS (DOS) AND COMMAND PROCESSOR (CP) BASED ON SYSTEM SETTING (SYS)
; 
;
; #IFNDEF BLD$SYS
; SYS		equ	SYS$CPM
; #ELSE
; SYS		equ	BLD$SYS
; #ENDIF
; 
; #IF (SYS == SYS$CPM)
; DOS		equ	DOS$BDOS
; CP		equ	CP$CCP
; #DEFINE		OSLBL	"CP/M-80 2.2C"
; #ENDIF
; 
; #IF (SYS == SYS$ZSYS)
; DOS		equ	DOS$ZSDOS
; CP		equ	CP$ZCPR
; #DEFINE		OSLBL	"ZSYSTEM (ZSDOS 1.2, ZCPR 1.0)"
; #ENDIF
; 
;
; ; INCLUDE VERSION AND BUILD SETTINGS
; 
; #INCLUDE "ver.inc"			; ADD BIOSVER
; 
;
; #INCLUDE "build.inc"			; INCLUDE USER CONFIG, ADD VARIANT, TIMESTAMP, & ROMSIZE
; 
;
; #IF (PLATFORM NE PLT$N8)
; 
;
; ; N8VEM HARDWARE IO PORT ADDRESSES AND MEMORY LOCATIONS
; MPCL$RAM	equ 	78H		; BASE IO ADDRESS OF RAM MEMORY PAGER CONFIGURATION LATCH
; MPCL$ROM	equ 	7CH		; BASE IO ADDRESS OF ROM MEMORY PAGER CONFIGURATION LATCH
; 
;
; ; HARDWARE INTERFACES
; 
; PIO 82C55 I/O IS DECODED TO PORT 60-67
; PIOA		equ 	60H		; PORT A
; PIOB		equ 	61H		; PORT B
; PIOC		equ 	62H		; PORT C
; PIOX	 	equ 	63H		; PIO CONTROL PORT
; 
; 16C550 SERIAL LINE UART
; 
; SIO$BASE	equ	68H
; SIO$RBR		equ	SIO$BASE + 0	; DLAB=0: RCVR BUFFER REG (READ ONLY)
; SIO$THR		equ	SIO$BASE + 0	; DLAB=0: XMIT HOLDING REG (WRITE ONLY)
; SIO$IER		equ	SIO$BASE + 1	; DLAB=0: INT ENABLE REG
; SIO$IIR		equ	SIO$BASE + 2	; INT IDENT REGISTER (READ ONLY)
; SIO$FCR		equ	SIO$BASE + 2	; FIFO CONTROL REG (WRITE ONLY)
; SIO$LCR		equ	SIO$BASE + 3	; LINE CONTROL REG
; SIO$MCR		equ	SIO$BASE + 4	; MODEM CONTROL REG
; SIO$LSR		equ	SIO$BASE + 5	; LINE STATUS REG
; SIO$MSR		equ	SIO$BASE + 6	; MODEM STATUS REG
; SIO$SCR		equ	SIO$BASE + 7	; SCRATCH REGISTER
; SIO$DLL		equ	SIO$BASE + 0	; DLAB=1: DIVISOR LATCH (LS)
; SIO$DLM		equ	SIO$BASE + 1	; DLAB=1: DIVISOR LATCH (MS)
; #ENDIF		; (PLATFORM NE PLT$N8)
; 
;
; #IF (PLATFORM NE PLT$N8)
; 
;
; ; Z180 REGISTERS
; 
;
; CPU$IOBASE	equ	40H		; ONLY RELEVANT FOR Z180
; CPU$CNTLA0	equ	CPU$IOBASE+$00	;ASCI0 control A
; CPU$CNTLA1	equ	CPU$IOBASE+$01	;ASCI1 control A
; CPU$CNTLB0	equ	CPU$IOBASE+$02	;ASCI0 control B
; CPU$CNTLB1	equ	CPU$IOBASE+$03	;ASCI1 control B
; CPU$STAT0	equ	CPU$IOBASE+$04	;ASCI0 status
; CPU$STAT1	equ	CPU$IOBASE+$05	;ASCI1 status
; CPU$TDR0	equ	CPU$IOBASE+$06	;ASCI0 transmit
; CPU$TDR1	equ	CPU$IOBASE+$07	;ASCI1 transmit
; CPU$RDR0	equ	CPU$IOBASE+$08	;ASCI0 receive
; CPU$RDR1	equ	CPU$IOBASE+$09	;ASCI1 receive
; CPU$CNTR	equ	CPU$IOBASE+$0A	;CSI/O control
; CPU$TRDR	equ	CPU$IOBASE+$0B	;CSI/O transmit/receive
; CPU$TMDR0L	equ	CPU$IOBASE+$0C	;Timer 0 data lo
; CPU$TMDR0H	equ	CPU$IOBASE+$0D	;Timer 0 data hi
; CPU$RLDR0L	equ	CPU$IOBASE+$0E	;Timer 0 reload lo
; CPU$RLDR0H	equ	CPU$IOBASE+$0F	;Timer 0 reload hi
; CPU$TCR		equ	CPU$IOBASE+$10	;Timer control
; CPU$ASEXT0	equ	CPU$IOBASE+$12	;ASCI0 extension control (Z8S180)
; CPU$ASEXT1	equ	CPU$IOBASE+$13	;ASCI1 extension control (Z8S180)
; CPU$TMDR1L	equ	CPU$IOBASE+$14	;Timer 1 data lo
; CPU$TMDR1H	equ	CPU$IOBASE+$15	;Timer 1 data hi
; CPU$RLDR1L	equ	CPU$IOBASE+$16	;Timer 1 reload lo
; CPU$RLDR1H	equ	CPU$IOBASE+$17	;Timer 1 reload hi
; CPU$FRC		equ	CPU$IOBASE+$18	;Free running counter
; CPU$ASTC0L	equ	CPU$IOBASE+$1A	;ASCI0 Time constant lo (Z8S180)
; CPU$ASTC0H	equ	CPU$IOBASE+$1B	;ASCI0 Time constant hi (Z8S180)
; CPU$ASTC1L	equ	CPU$IOBASE+$1C	;ASCI1 Time constant lo (Z8S180)
; CPU$ASTC1H	equ	CPU$IOBASE+$1D	;ASCI1 Time constant hi (Z8S180)
; CPU$CMR		equ	CPU$IOBASE+$1E	;Clock multiplier (latest Z8S180)
; CPU$CCR		equ	CPU$IOBASE+$1F	;CPU control (Z8S180)
; CPU$SAR0L	equ	CPU$IOBASE+$20	;DMA0 source addr lo
; CPU$SAR0H	equ	CPU$IOBASE+$21	;DMA0 source addr hi
; CPU$SAR0B	equ	CPU$IOBASE+$22	;DMA0 source addr bank
; CPU$DAR0L	equ	CPU$IOBASE+$23	;DMA0 dest addr lo
; CPU$DAR0H	equ	CPU$IOBASE+$24	;DMA0 dest addr hi
; CPU$DAR0B	equ	CPU$IOBASE+$25	;DMA0 dest addr bank
; CPU$BCR0L	equ	CPU$IOBASE+$26	;DMA0 byte count lo
; CPU$BCR0H	equ	CPU$IOBASE+$27	;DMA0 byte count hi
; CPU$MAR1L	equ	CPU$IOBASE+$28	;DMA1 memory addr lo
; CPU$MAR1H	equ	CPU$IOBASE+$29	;DMA1 memory addr hi
; CPU$MAR1B	equ	CPU$IOBASE+$2A	;DMA1 memory addr bank
; CPU$IAR1L	equ	CPU$IOBASE+$2B	;DMA1 I/O addr lo
; CPU$IAR1H	equ	CPU$IOBASE+$2C	;DMA1 I/O addr hi
; CPU$IAR1B	equ	CPU$IOBASE+$2D	;DMA1 I/O addr bank (Z8S180)
; CPU$BCR1L	equ	CPU$IOBASE+$2E	;DMA1 byte count lo
; CPU$BCR1H	equ	CPU$IOBASE+$2F	;DMA1 byte count hi
; CPU$DSTAT	equ	CPU$IOBASE+$30	;DMA status
; CPU$DMODE	equ	CPU$IOBASE+$31	;DMA mode
; CPU$DCNTL	equ	CPU$IOBASE+$32	;DMA/WAIT control
; CPU$IL		equ	CPU$IOBASE+$33	;Interrupt vector load
; CPU$ITC		equ	CPU$IOBASE+$34	;INT/TRAP control
; CPU$RCR		equ	CPU$IOBASE+$36	;Refresh control
; CPU$CBR		equ	CPU$IOBASE+$38	;MMU common base register
; CPU$BBR		equ	CPU$IOBASE+$39	;MMU bank base register
; CPU$CBAR	equ	CPU$IOBASE+$3A	;MMU common/bank area register
; CPU$OMCR	equ	CPU$IOBASE+$3E	;Operation mode control
; CPU$ICR		equ	$3F		;I/O control register (not relocated)
; 
; N8 ONBOARD  I/O REGISTERS
; N8$IOBASE	equ	$80
; PIO		equ	N8$IOBASE+$00
; PIOA		equ 	PIO+$00		; PORT A
; PIOB		equ 	PIO+$01		; PORT B
; PIOC		equ 	PIO+$02		; PORT C
; PIOX	 	equ 	PIO+$03		; PIO CONTROL PORT
; PIO2		equ	N8$IOBASE+$04
; PIO2A		equ 	PIO2+$00	; PORT A
; PIO2B		equ 	PIO2+$01	; PORT B
; PIO2C		equ 	PIO2+$02	; PORT C
; PIO2X	 	equ 	PIO2+$03	; PIO CONTROL PORT
; 
; RTC		equ	N8$IOBASE+$08	;RTC latch and buffer
; FDC		equ	N8$IOBASE+$0C	;Floppy disk controller
; UTIL		equ	N8$IOBASE+$10	;Floppy disk utility 
; ACR		equ	N8$IOBASE+$14	;auxillary control register
; RMAP		equ	N8$IOBASE+$16	;ROM page register
; VDP		equ	N8$IOBASE+$18	;Video Display Processor (TMS9918A)
; PSG		equ	N8$IOBASE+$1C	;Programmable Sound Generator (AY-3-8910)
; 
; DEFACR		equ	$1B
; 
; #ENDIF
; 
;
; ; CHARACTER DEVICE FUNCTIONS
; 
;
; CF$INIT		equ	0
; CF$IN		equ	1
; CF$IST		equ	2
; CF$OUT		equ	3
; CF$OST		equ	4
; 
; DISK OPERATIONS
; DOP$READ	equ	0		; READ OPERATION
; DOP$WRITE	equ	1		; WRITE OPERATION
; DOP$FORMAT	equ	2		; FORMAT OPERATION
; DOP$READID	equ	3		; READ ID OPERATION
; 
; DISK DRIVER FUNCTIONS
; DF$READY	equ	1
; DF$SELECT	equ	2
; DF$READ		equ	3
; DF$WRITE	equ	4
; DF$FORMAT	equ	5
; 
; DISK DEVICES (ONLY FIRST NIBBLE RELEVANT, SECOND NIBBLE MUST BE ZERO)
; DEV$MD		equ	000H
; DEV$FD		equ	010H
; DEV$IDE		equ	020H
; DEV$ATAPI	equ	030H
; DEV$PPIDE	equ	040H
; DEV$SD		equ	050H
; DEV$PRPSD	equ	060H
; 
; IMG$START	equ	00000H		; IMMUTABLE: ROM IMAGE AREA START
; IMG$END		equ	08000H		; IMMUTABLE: ROM IMAGE AREA END
; 
; PG0$LOC		equ	00000H			; IMMUTABLE
; PG0$SIZ		equ	00100H			; IMMUTABLE
; PG0$END		equ	PG0$LOC + PG0$SIZ
; PG0$IMG		equ	IMG$START		; IMMUTABLE
; LDR$LOC		equ	PG0$END
; LDR$SIZ		equ	02000H - PG0$SIZ	; CONFIGURABLE
; LDR$END		equ	LDR$LOC + LDR$SIZ
; LDR$IMG		equ	PG0$IMG + PG0$SIZ
; CPM$LOC		equ	0D000H			; CONFIGURABLE: LOCATION OF CPM FOR RUNNING SYSTEM
; CPM$END		equ	10000H			; IMMUTABLE: TOP OF MEMORY
; CPM$SIZ		equ	CPM$END - CPM$LOC	; SIZE OF CPM IMAGE (CCP + BDOS + CBIOS (INCLUDING DATA))
; CPM$ENT		equ	CPM$LOC + 01600H	; IMMUTABLE: CPM ENTRY POINT
; CPM$IMG		equ	LDR$IMG + LDR$SIZ	; START OF CONCATENATED CPM IMAGE
; DAT$SIZ		equ	DATASIZE		; FROM CONFIG FILE
; DAT$END		equ	CPM$END
; DAT$LOC		equ	DAT$END - DAT$SIZ
; BIOS$LOC	equ	CPM$ENT
; BIOS$END	equ	DAT$LOC
; BIOS$SIZ	equ	DAT$LOC - CPM$ENT
; MON$IMG		equ	CPM$IMG + CPM$SIZ	; LOCATION OF MONITOR BINARY IMAGE IN ROM
; MON$LOC		equ	08000H			; LOCATION OF MONITOR FOR RUNNING SYSTEM
; MON$SIZ		equ	01000H			; SIZE OF MONITOR BINARY IMAGE
; MON$END		equ	MON$LOC + MON$SIZ
; MON$DSKY	equ	MON$LOC			; MONITOR ENTRY (DSKY)
; MON$UART	equ	MON$LOC + 3		; MONITOR ENTRY (UART)
; ROMX$LOC	equ	MON$IMG + MON$SIZ	; LOCATION OF ROM EXTENSION CODE
; 
;
; ROMX$SIZ	equ	02000H			; FIXED
; ROMX$END	equ	ROMX$LOC + ROMX$SIZ
; 
;
; VDU$LOC		equ	ROMX$LOC + 0		; LOCATION OF ROM VDU DRIVER
; 
;
; CBIOS$BOOT	equ	BIOS$LOC + 0
; CBIOS$WBOOT	equ	BIOS$LOC + 3
; CBIOS$CONST	equ	BIOS$LOC + 6
; CBIOS$CONIN	equ	BIOS$LOC + 9
; CBIOS$CONOUT	equ	BIOS$LOC + 12
; CBIOS$LIST	equ	BIOS$LOC + 15
; CBIOS$PUNCH	equ	BIOS$LOC + 18
; CBIOS$READER	equ	BIOS$LOC + 21
; CBIOS$HOME	equ	BIOS$LOC + 24
; CBIOS$SELDSK	equ	BIOS$LOC + 27
; CBIOS$SETTRK	equ	BIOS$LOC + 30
; CBIOS$SETSEC	equ	BIOS$LOC + 33
; CBIOS$SETDMA	equ	BIOS$LOC + 36
; CBIOS$READ	equ	BIOS$LOC + 39
; CBIOS$WRITE	equ	BIOS$LOC + 42
; CBIOS$LISTST	equ	BIOS$LOC + 45
; CBIOS$SECTRN	equ	BIOS$LOC + 48
; 
; MEMORY CONFIGURATION
; 
; MSIZE		equ	59	; CP/M VERSION MEMORY SIZE IN KILOBYTES
; 
; "BIAS" IS ADDRESS OFFSET FROM 3400H FOR MEMORY SYSTEMS
; ; THAN 16K (REFERRED TO AS "B" THROUGHOUT THE TEXT) 
; 
; BIAS	 	equ 	(MSIZE-20)*1024
; CCP	 	equ 	3400H+BIAS	; BASE OF CCP
; BDOS	 	equ 	CCP+806H	; BASE OF BDOS
; BIOS	 	equ 	CCP+1600H	; BASE OF BIOS
; CCPSIZ		equ	00800H
; 
; #IF (PLATFORM == PLT$N8VEM)
; 
; 
; ;   #DEFINE 	PLATFORM$NAME	"N8VEM Z80 SBC"
; 
; 
; ; #ENDIF
; 
; 
; ; #IF (PLATFORM == PLT$ZETA)
; ;   #DEFINE 	PLATFORM$NAME	"ZETA Z80 SBC"
; ; #ENDIF
; 
; 
; ; #IF (PLATFORM == PLT$N8)
; ;   #DEFINE 	PLATFORM$NAME	"N8 Z180 SBC"
; ; #ENDIF
; 
; #IF (DSKYENABLE)
; ;   #DEFINE	DSKYLBL	", DSKY"
; ; #ELSE
; ;   #DEFINE	DSKYLBL	""
; ; #ENDIF
; 
; #IF (VDUENABLE)
; #DEFINE	VDULBL	", VDU"
; #ELSE
; #DEFINE	VDULBL	""
; #ENDIF
; 
; #IF (DIOPLT NE DIOPLT$NONE)
; 
; 
; 	#IF (DIOPLT EQ DIOPLT$DISKIO)
;  		#DEFINE DIOLBL	", DISKIO"
;    	#ENDIF
; 
;
; 	#IF (DIOPLT EQ DIOPLT$ZETA)
; 		#DEFINE DIOLBL	""
; 	#ENDIF
; 
;
; 	#IF (DIOPLT EQ DIOPLT$DIDE)
;  		#DEFINE DIOLBL	", DUALIDE"
; 	#ENDIF
; 
;
; 	#IF (DIOPLT EQ DIOPLT$N8)
; 		#DEFINE DIOLBL	""
; 	#ENDIF
; 
;	#IF (DIOPLT EQ DIOPLT$DISKIO3)
; 		#DEFINE	DIOLBL	", DISKIO-V3"
; 	#ENDIF
; 
; #ELSE
; 	#DEFINE	DIOLBL	""
; #ENDIF
; 
;
; ; #ENDIF
; 
;
; #IF (FDENABLE)
; 	#IF (FDMAUTO)
; 		#DEFINE	FDLBL	", FLOPPY (AUTOSIZE)"
; 	#ELSE
; 		#IF (FDMEDIA == FDM720)
; 			#DEFINE	FDLBL	", FLOPPY (720KB)"
; 		#ENDIF
; 		#IF (FDMEDIA == FDM144)
; 			#DEFINE	FDLBL	", FLOPPY (1.44MB)"
; 		#ENDIF
; 	#ENDIF
; #ELSE
; 	#DEFINE	FDLBL	""
; #ENDIF
; 
;
; #IF (IDEENABLE)
; 	#DEFINE	IDELBL	", IDE"
; #ELSE
; 	#DEFINE	IDELBL	""
; #ENDIF
; 
;
; #IF (PPIDEENABLE)
; 	#DEFINE	PPIDELBL	", PPIDE"
; #ELSE
; 	#DEFINE	PPIDELBL	""
; #ENDIF
; 
; #IF (SDENABLE)
; 	#DEFINE	SDLBL		", SD CARD"
; #ELSE
; 	#DEFINE	SDLBL		""
; #ENDIF
; 
; 
; #IF (PRPSDENABLE)
; 	#DEFINE	PRPSDLBL	", PROPIO SD CARD"
; #ELSE
; 	#DEFINE	PRPSDLBL	""
; #ENDIF
; 
;
; ;	.ECHO	"Configuration: "
; ; 	.ECHO	PLATFORM$NAME
; ; 	.ECHO	DSKYLBL
; ; 	.ECHO	VDULBL
; ; 	.ECHO	DIOLBL
; ; 	.ECHO	FDLBL
; ; 	.ECHO	IDELBL
; ; 	.ECHO	PPIDELBL
; ; 	.ECHO	SDLBL
; ; 	.ECHO	PRPSDLBL
; ; 	.ECHO	"\n"
; ; 
; 
; eof - std.lib

*/
