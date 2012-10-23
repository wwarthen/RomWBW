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



extern cnamept1();
extern cnamept2();
extern cnamept3();
extern cnamept4();

struct SYSCFG * syscfg;
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
		
	printf("CPMNAME.COM %d/%d/%d v%d.%d.%d.%d",
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
			
	syscfg = 0x8000;
	
	hregbc = 0xf000;
	hregde = syscfg;	
	diagnose();

	cnamept1(syscfg);
	cnamept2(syscfg);
	cnamept3(syscfg);
	cnamept4(syscfg);
	
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

	