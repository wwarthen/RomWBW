/* banker.c 6/7/2012 dwg - */

#include "stdio.h"
#include "stdlib.h"
#include "memory.h"

/* #include "cpmbind.h" */

#include "std.h"
#include "infolist.h"
#include "metadata.h"

/* #include "setlunum.h" */

#include "applvers.h"
#include "bdoscall.h"
#include "cpmbdos.h"
#include "bioscall.h"
#include "cpmbios.h"
#include "diagnose.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "applvers.h"

#define COL1 0
#define COL2 (80/3)
#define COL3 (2*COL2)
#define LINE 2

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

struct SYSCFG 	* 	pSYSCFG;
struct BIOS   	* 	pCBIOS;

int main(argc,argv)
	int argc;
	char *argv[] ;
{
	
	char * varloc;
	char * tstloc;
	char temp[128];

	int i;
	int bFirst;
	
	bFirst = 0;
						
	ireghl = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;
	printf("post GETINFO ireghl is 0x%04x\n",pINFOLIST);

	pCBIOS = 0x0e600;

	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);

	printf("BANKER.COM %d/%d/%d v%d.%d.%d.%d",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - Display Memory Bank Characteristics");

	hregbc = 0x0f000;
	hregde = 0x0c000;
	diagnose();
	pSYSCFG = 0x0C000;
	
	crtlc(LINE+0,COL1);
	crtlc(LINE+1,COL1);
	printf("ROM Bank1");
	crtlc(LINE+2,COL1);
	printf("RMJ = %d",pSYSCFG->cnfgdata.rmj);
	crtlc(LINE+3,COL1);
	printf("RMN = %d",pSYSCFG->cnfgdata.rmn);
	crtlc(LINE+4,COL1);
	printf("RUP = %d",pSYSCFG->cnfgdata.rup);
	crtlc(LINE+5,COL1);
	printf("RTP = %d",pSYSCFG->cnfgdata.rtp);
	crtlc(LINE+7,COL1);
	varloc = pSYSCFG->varloc;
/*	dregde = (unsigned int)varloc-0x200+0x0c000; */
	dregde = (unsigned int)varloc+0x0c000; 

	dregbc = 9;
	bdoscall();
	crtlc(LINE+8,COL1);
/*	tstloc = 0x0c000-0x0200+(unsigned int)pSYSCFG->tstloc; */
	tstloc = 0x0c000+(unsigned int)pSYSCFG->tstloc;
	memset(temp,0,sizeof(temp));
	memcpy(temp,tstloc,11);	
	printf("%s",temp);
	
	crtlc(LINE+1,COL2);
	printf("CBIOS HDR");
	crtlc(LINE+2,COL2);
	printf("RMJ = %d",pCBIOS->rmj);
	crtlc(LINE+3,COL2);
	printf("RMN = %d",pCBIOS->rmn);
	crtlc(LINE+4,COL2);
	printf("RUP = %d",pCBIOS->rup);
	crtlc(LINE+5,COL2);	
	printf("RTP = %d",pCBIOS->rtp);
	/* */
	crtlc(LINE+7,COL2);
	varloc = pINFOLIST->varloc;
	memset(temp,0,sizeof(temp));
	memcpy(temp,varloc,sizeof(temp)-1);
	for(i=0;i<sizeof(temp);i++) {
	  if('-' == temp[i]) {
		if(0 != bFirst) {
			  	temp[i] = 0;
		} else {
				bFirst = 1;
		}
	  }
	}
	printf("%s",temp);
	
	crtlc(LINE+8,COL2);
	tstloc = pINFOLIST->tstloc;
	memset(temp,0,sizeof(temp));
	memcpy(temp,tstloc,11);	
	printf("%s",temp);

	crtlc(LINE+1,COL3);
	printf("BANKER.COM");
	crtlc(LINE+2,COL3);
	printf("RMJ = %d",A_RMJ);
	crtlc(LINE+3,COL3);
	printf("RMN = %d",A_RMN);
	crtlc(LINE+4,COL3);
	printf("RUP = %d",A_RUP);
	crtlc(LINE+5,COL3);	
	printf("RTP = %d",A_RTP);

	crtlc(LINE+8,COL3);
	printf("%02d%02d%02d",A_YR,A_MONTH,A_DAY);
	crtlc(23,0);
}

/*****************/
/* eof - cview.c */
/*****************/
