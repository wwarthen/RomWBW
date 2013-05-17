/* test.c 7/23/2012 dwg - */

#include "stdio.h"
#include "applvers.h"
#include "ctermcap.h"

/* declarations for HBIOS access */
extern	char         hrega;
extern	unsigned int hregbc;
extern  unsigned int hregde;
extern	unsigned int hreghl;
extern 	diagnose();

/* declaration dir BIOS and BDOS and low level calls */
extern	char         xrega;
extern	unsigned int xregbc;
extern  unsigned int xregde;
extern	unsigned int xreghl;
extern	asmif();				/* asmif(0x0E6**,bc,de,hl); */

#define BDOS    5			/* memory address of BDOS invocation */
#define PRIFCB  0x5C		/* memory address of primary   FCB   */
#define SECFCB  0x6C		/* memory address of secondary FCB   */
#define DEFBUF  0x80		/* memory address of default buffer  */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

#define TERMCPM		0		/* BDOS  function for System Reset  */
#define	CONIN		1		/* BDOS  function for Console Input */
#define CWRITE		2		/* BDOS  function for Console Output */
#define	DIRCONIO	6		/* BDOS  function for Direct Console I/O */
#define PRINTSTR	9		/* BDOS  function for Print String       */
#define	RDCONBUF	10		/* BDOS  function for Buffered Console Read */
#define	GETCONST	11		/* BDOS  function for Get Console Status */
#define RETVERNUM	12		/* BDOS  function for Return Version Number */
#define	RESDISKSYS	13		/* BDOS  function for Reset Disk System */
#define	SELECTDISK	14		/* BDOS  function for Select Disk */
#define	FOPEN		15		/* BDOS  function for File Open   */
#define	FCLOSE		16		/* BDOS  function for File Close  */
#define SEARCHFIRST	17		/* BDOS  function for Search First */
#define	SEARCHNEXT	18		/* BDOS  function for Search Next  */
#define	FDELETE		19		/* BDOS  function for File Delete  */
#define	FREADSEQ	20		/* BDOS  function for File Read  Sequential */
#define	FWRITESEQ	21		/* BDOS  function for File Write Sequential */
#define FMAKEFILE	22		/* BDOS  function for File Make             */
#define	FRENAME		23		/* BDOS  function for File Rename           */
#define	RETLOGINVEC	24		/* BDOS  function for Return Login Vector   */
#define	RETCURRDISK	25		/* BDOS  function for Return Current Disk   */
#define	SETDMAADDR	26		/* BDOS  function for Set DMA Address       */
#define	GETALLOCVEC	27		/* BDOS  function for Get Allocation Vector */
#define	WRPROTDISK	28		/* BDOS  function for Write Protect Disk    */
#define	GETROVECTOR	29		/* BDOS  function for Get Read Only Vector  */
#define	FSETATTRIB	30		/* BDOS  function for File Set Attribute    */
#define	GETDPBADDR	31		/* BDOS  function for Get DPB Address       */
#define	SETGETUSER	32		/* BDOS  function for Set & Get User Number */
#define	FREADRANDOM	33		/* BDOS  function for File Read  Random     */
#define	FWRITERAND	34		/* BDOS  function for File Write Random     */
#define FCOMPSIZE	35		/* BDOS  function for File Compare Size     */
#define	SETRANDREC	36		/* BDOS  function for Set Random Record #   */
#define	RESETDRIVE	37		/* BDOS  function for Reset Drive           */
#define	WRRANDFILL	38		/* BDOS  function for Write Random w/ Fill  */

#define BDOSDEFDR 0			/* BDOS Default (current) Drive Number      */
#define	BDOSDRA	  1			/* BDOS Drive A: number                     */
#define	BDOSDRB	  2			/* BDOS Drive B: number                     */
#define	BDOSDRC   3			/* BDOS Drive C: number                     */
#define	BDOSDRD	  4			/* BDOS Drive D: number                     */
#define	BDOSDRE	  5			/* BDOS Drive E: number                     */
#define	BDOSDRF	  6			/* BDOS Drive F: number                     */
#define	BDOSDRG	  7			/* BDOS Drive G: number                     */
#define	BDOSDRH   8			/* BDOS Drive H: number                     */

#define	BIOSDRA	  0			/* BIOS Drive A: number                     */
#define	BIOSDRB	  1			/* BIOS Drive B: number                     */
#define	BIOSDRC	  2			/* BIOS Drive C: number                     */
#define	BIOSDRD	  3			/* BIOS Drive D: number                     */
#define	BIOSDRE	  4			/* BIOS Drive E: number                     */
#define	BIOSDRF	  5			/* BIOS Drive F: number                     */
#define	BIOSDRG	  6			/* BIOS Drive G: number                     */
#define	BIOSDRH   7			/* BIOS Drive H: number                     */

struct FCB {
	char drive;				/* BDOS Drive Code             */
	char filename[8];		/* space padded file name      */
	char filetype[3];		/* space padded file extension */
	char filler[24];		/* remainder of FCB            */
};

struct FCB * pPriFcb = PRIFCB;	/* pointer to Primary FCB structure   */

struct FCB * pSecFcb = SECFCB;	/* pointer to secondary FCB structure */

struct {
	char length;			/* length of commad tail */
	char tail[127];			/* command tail          */
} * pDefBuf = DEFBUF;


#define CURDRV  0x00004
#define BIOSAD  0x0e600		/* base address of BIOS jumps */

/* addresses of BIOS jumps */
#define pBOOT	 0x0E600
#define pWBOOT	 0x0E603
#define pCONST	 0x0E606
#define pCONIN	 0x0E609
#define pCONOUT	 0x0E60C
#define pLIST	 0x0E60F
#define pPUNCH	 0x0E612
#define pREADER	 0x0E615
#define pHOME	 0x0E618
#define pSELDSK	 0x0E61B
#define pSETTRK	 0x0E61E
#define pSETSEC	 0x0E621	
#define pSETDMA	 0x0E624
#define pREAD	 0x0E627
#define pWRITE	 0x0E62A
#define pLISTST	 0x0E62D
#define pSECTRN	 0x0E630
#define pBNKSEL	 0x0E633
#define pGETLU   0x0E636
#define pSETLU   0x0E639
#define pGETINFO 0x0E63C

struct JMP {
	unsigned char opcode;	/* JMP opcode  */
	unsigned int address;	/* JMP address */
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

	char rmj;
	char rmn;
	char rup;
	char rtp;
	
} * pBIOS = 0xe600;

/* pointer based Disk Parameter Block structure */
struct DPB {
	unsigned int  spt;	
	unsigned char bsh;	
	unsigned char blm;	
	unsigned char exm;
	unsigned int  dsm;	
	unsigned int  drm;	
	unsigned char al0;	
	unsigned int  cks;	
	unsigned int  off;	
} * pDPB;

/* pointer based Disk Parameter Header structure */
struct DPH {
	unsigned int  xlt;	
	unsigned int  rv1;
	unsigned int  rv2;
	unsigned int  rv3;
	unsigned int  dbf;	
	struct DPB *  pDpb;	
	unsigned int  csv;	
	unsigned int  alv;	
	unsigned char sigl;
	unsigned char sigu;
	unsigned int  current;
	unsigned int  number;
} * pDPH;

/* pointer based Information List structure */
struct INFOLIST {
	int    version;
	void * banptr;
	void * varloc;
	void * tstloc;
	void * dpbmap;
	void * dphmap;
	void * ciomap;
} * pINFOLIST;

/* pointer based Configuration Data structure */
struct CNFGDATA {
	unsigned char rmj;
	unsigned char rmn;
	unsigned char rup;
	unsigned char rtp;
	unsigned char diskboot;
	unsigned char devunit;
	unsigned int  bootlu;
	unsigned char hour;
	unsigned char minute;
	unsigned char second;
	unsigned char month;
	unsigned char day;
	unsigned char year;
	unsigned char freq;
	unsigned char platform;
	unsigned char dioplat;
	unsigned char vdumode;
	unsigned int  romsize;
	unsigned int  ramsize;
	unsigned char clrramdk;
	unsigned char dskyenable;
	unsigned char uartenable;
	unsigned char vduenable;
	unsigned char fdenable;
	unsigned char fdtrace;
	unsigned char fdmedia;
	unsigned char fdmediaalt;
	unsigned char fdmauto;
	unsigned char ideenable;
	unsigned char idetrace;
	unsigned char ide8bit;
	unsigned int  idecapacity;
	unsigned char ppideenable;
	unsigned char ppidetrace;
	unsigned char ppide8bit;
	unsigned int  ppidecapacity;
	unsigned char ppideslow;
	unsigned char boottype;
	unsigned char boottimeout;
	unsigned char bootdefault;
	unsigned int  baudrate;
	unsigned char ckdiv;
	unsigned char memwait;
	unsigned char iowait;
	unsigned char cntlb0;
	unsigned char cntlb1;
	unsigned char sdenable;
	unsigned char sdtrace;
	unsigned int  sdcapacity;
	unsigned char sdcsio;
	unsigned char sdcsiofast;
	unsigned char defiobyte;
	unsigned char termtype;
	unsigned int  revision;
	unsigned char prpsdenable;
	unsigned char prpsdtrace;
	unsigned int  prpsdcapacity;
	unsigned char prpconenable;
	unsigned int  biossize;				
	unsigned char pppenable;
	unsigned char pppsdenable;
	unsigned char pppsdtrace;
	unsigned int  pppsdcapacity;
	unsigned char pppconenable;
	unsigned char prpenable;
} * pCNFGDATA;


struct JMP_TAG {
	unsigned char opcode;
	unsigned int address;
};


/* pointer based System Configuration structure */
struct SYSCFG {
	struct JMP_TAG jmp;
	void * cnfloc;
	void * tstloc;
	void * varloc;
	struct CNFGDATA cnfgdata;
	char filler[256-3-2-2-2-sizeof(struct CNFGDATA)];	
} * pSYSCFG = HIGHSEG;


main(argc,argv)
	int argc;
	char *argv[];
{
	FILE * fd;
	
	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	
	printf("TT is %d\n",pSYSCFG->cnfgdata.termtype); 

	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);

	printf(
	 "GETCFG.COM %d/%d/%d %d.%d.%d.%d dwg - Elegantly Expressed CP/M Program\n",
	 A_MONTH,A_DAY,A_YEAR,
	 pBIOS->rmj,pBIOS->rmn,pBIOS->rup,pBIOS->rtp);	
	
	fd = fopen("syscfg.bin","w");
	fwrite(HIGHSEG,1,256,fd);
	fclose(fd);
		


	asmif(pGETINFO,0,0,0);			/* get addr of the information list  */
	pINFOLIST = xreghl;				/* set base pointer of the structure */

	asmif(BDOS,RETCURRDISK,0,0);	/* get current drive into xrega      */
	asmif(pSELDSK,xrega,0,0);		/* get DPH of current drive          */
	pDPH = xreghl;					/* establish addressability to DPH   */
	pDPB = pDPH->pDpb;				/* establish addressability to DPB   */

/*	printf("spt is %d\n",pDPB->spt); */   	/* demonstrate DPB access    */	



}

