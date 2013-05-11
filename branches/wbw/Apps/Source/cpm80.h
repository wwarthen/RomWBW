/* cpmbios.h 3/11/2012 dwg - added CURDRV */

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
	struct JMP rsvd1;
	struct JMP rsvd2;
	struct JMP rsvd3;
	struct JMP rsvd4;

	char diskboot;
	char bootdrive;
	
	char rmj;
	char rmn;
	char rup;
	char rtp;
};


struct DPH {
	unsigned int xlt;	
	unsigned int rv1;
	unsigned int rv2;
	unsigned int rv3;
	unsigned int dbf;	
	unsigned int dpb;	
	unsigned int csv;	
	unsigned int alv;	
	unsigned char sigl;
	unsigned char sigu;
	unsigned int current;
	unsigned int number;
};

struct DPB {
	unsigned int spt;	
	unsigned char bsh;	
	unsigned char blm;	
	unsigned char exm;
	unsigned int dsm;	
	unsigned int drm;	
	unsigned char al0;	
	unsigned char al1;	
	unsigned int cks;	
	unsigned int off;	
};
	
/* bioscall.h 3/10/2012 dwg - header file for bdoscall */

	extern	char         irega;
	extern	unsigned int iregbc;
	extern  unsigned int iregde;
	extern	unsigned int ireghl;
	extern	bioscall();


/* bdoscall.h 3/10/2012 dwg - header file for bdoscall */

	extern	char         drega;
	extern	unsigned int dregbc;
	extern  unsigned int dregde;
	extern	unsigned int dreghl;
	extern	bdoscall();

/* diagnose.h 5/23/2012 dwg - */

	extern	char         hrega;
	extern	unsigned int hregbc;
	extern  unsigned int hregde;
	extern	unsigned int hreghl;

extern diagnose();

/* ctermcap.h 3/11/2012 dwg - declarations for termal capability */

extern crtinit();
extern crtclr();
extern crtlc();

/* cpmbdos.h */
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

/* dphmap.h 5/29/2012 dwg - declaration of DPH MAP structure */

struct DPHMAP {
	struct DPH * drivea;
	struct DPH * driveb;
	struct DPH * drivec;
	struct DPH * drived;
	struct DPH * drivee;
	struct DPH * drivef;
	struct DPH * driveg;
	struct DPH * driveh;
} * pDPHMAP;

struct DPHMAP * pDPHVEC[MAXDRIVE];


/******************/
/* eof - dphmap.h */
/******************/

/*****************/
/* eof - cpm80.h */
/*****************/
