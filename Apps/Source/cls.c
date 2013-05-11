/* cls.c 7/21/2012 dwg - elegant form of clear screen program */

/*
#include "stdio.h"
#include "applvers.h"
*/

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
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

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
};

struct JMP {
	unsigned char opcode;	/* JMP opcode  */
	unsigned int address;	/* JMP address */
};

struct SYSCFG {
	struct JMP jmp;
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
	hregbc = GETSYSCFG;				/* function = Get System Config */
	hregde = HIGHSEG;				/* addr of dest (must be high)  */
	diagnose();						/* invoke the HBIOS function    */

	crtinit(pSYSCFG->cnfgdata.termtype);  /* pass termtype to init  */

	crtclr();

	crtlc(0,0);
}


