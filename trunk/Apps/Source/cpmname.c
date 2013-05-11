/* cpmname.c 5/21/2012 dwg - */

#include "stdio.h"
#include "stdlib.h"
#include "portab.h"
#include "memory.h"
#include "globals.h"
#include "cpmbind.h"
#include "applvers.h"
#include "infolist.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "diagnose.h"
#include "std.h"

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */


extern cnamept1();
extern cnamept2();
extern cnamept3();
extern cnamept4();



struct SYSCFG * pSYSCFG;
int line;

int main(argc,argv)
	int argc;
	char *argv[];
{


	char *p;				
	char c;
	int i;

	char * pC;

	line = 5;



	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);
		
	printf("CPMNAME.COM %d/%d/%d v%d.%d.%d (%d)",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - Display System Configuration");
	pager();
	pager();
			
	ireghl = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;

	printf("pINFOLIST->banptr ==> ");

	dregde = pINFOLIST->banptr;
	dregbc = 9;
	bdoscall();
	pager();
			
	
	hregbc = 0xf000;
	hregde = HIGHSEG;	
	diagnose();

	pSYSCFG = HIGHSEG;
	

	cnamept1(pSYSCFG);
	cnamept2(pSYSCFG);
	cnamept3(pSYSCFG);
	cnamept4(pSYSCFG);
	
}

pager()
{
	line++;
	printf("\n");
	if(24 == line) {
		printf("     press any key to continue");
		dregbc = 1;
		bdoscall();
		line = 1;
	}
}

/********************/
/* eof - ccpmname.c */
/********************/

	