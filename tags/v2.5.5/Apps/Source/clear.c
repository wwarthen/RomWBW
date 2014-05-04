/* clear.c 11/23/2012 dwg - */

#include "portab.h"
#include "globals.h"
  
#include "stdio.h"
#include "stdlib.h"
#include "memory.h"
#include "applvers.h"
#include "n8chars.h"
#include "tms9918.h"
#include "std.h"
#include "ctermcap.h"
#include "cpmbdos.h"
#include "bdoscall.h"
#include "hbios.h"
#include "asmiface.h"
#include "diagnose.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "cpmbind.h"
#include "infolist.h"
#include "metadata.h"
#include "clogical.h"

#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

struct CNFGDATA * pCNFGDATA;
struct SYSCFG * pSYSCFG;

int main(argc,argv)
	int argc;
	char *argv[];
{
	char column;

	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);
}

