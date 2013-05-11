/* remote.c 11/20/2012 dwg - */

/* Ther purpose of this program is to read the VRAM of the
   TMS9918 video processor and display the contents in the
   most usable form. First is the raw hexadecimal dump of
   the first 16K of the VRAM, followed by a hexadecimal 
   dump of the name table by line number,  and finally the
   charactert generator bitmaps in ASCII order.
*/
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


char szTemp[128];
char linenum;
char counter;

char outer;
char inner;
char limit;

int index;

unsigned int line;
unsigned char ubyte;
unsigned char bitmask;

int row;
int bit;
int ascii;
int bool;

struct CNFGDATA * pCNFGDATA;
struct SYSCFG * pSYSCFG;

FILE * fd;
 
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

	vdp_wrvram(0);
	in(DATAP);
	in(DATAP);
	for(line=0;line<24;line++) {
		crtlc(line+1,0);
		printf("line %2d |",line+1);
		for(column=0;column<40;column++) {
			ubyte = in(DATAP);
			switch(ubyte) {
				case 0x0d:	ubyte = 0; 		break;
				case 0x0a:	ubyte = 0; 		break;			
				case 0x09:	ubyte = 0; 		break;			
				case 0x00:	ubyte = 0x20; 	break;
			}
			if(0 != ubyte ) printf("%c",ubyte);
		}
		crtlc(line+1,50);
		printf("|");
		if(line==0) printf(" remote.com 11/21/2012 dwg");
		if(line==1) printf("    display tms9918 screen");
		if(line==4) printf("   Note: semi-graphics not");
		if(line==5) printf("         supported.");
	}

	printf(" (press enter to exit)");
	dregbc=1;
	bdoscall();
}

