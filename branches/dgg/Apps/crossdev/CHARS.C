/* chars.c 6/7/2012 dwg - test command line arguments */

#include "stdio.h"

#include "portab.h"
#include "globals.h"
#include "std.h"
#include "cpm80.h"
#include "cpmappl.h"
#include "applvers.h"
#include "cnfgdata.h"
#include "syscfg.h"

#define TOP 0
#define LEFT 4

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

struct SYSCFG * pSYSCFG = HIGHSEG;

char map[256] = 
{ 
/*  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F		 */

	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,	/* 0 */
	1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, /* 1 */
	1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 2 */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 3 0 - 9 */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 4 A - O */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 5 P - Z */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 6 a - o */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, /* 7 p - z */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* 8 */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, /* 9 */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* A */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* B 0 - 9 */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* C A - O */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* D P - Z */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,	/* E a - o */
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	/* F p - z */
};
	
char  attroff[] = { 27, '[', 'm', 0 };
char attrbold[] = { 27, '[', '1', 'm', 0 };
char attrlow[]  = { 27, '[', '2', 'm', 0 };
char attrundr[] = { 27, '[', '4', 'm', 0 };
char attrblnk[] = { 27, '[', '5', 'm', 0 };
char attrrevs[] = { 27, '[', '7', 'm', 0 };
char attrinvs[] = { 27, '[', '8', 'm', 0 };
char graphon[]  = { 27, 'F', 0 };
char graphoff[] = { 27, 'G', 0 };


char atreset[]    = "0";
char atbold[]   = "1";
char atdim[]      = "2";
char atundrscr[]  = "4";
char atblink[]    = "5";
char atrevs[]     = "7";
char athidden[]   = "8";

char fgblack[]    = "30";
char fgred[]      = "31";
char fggreen[]    = "32";
char fgyellow[]   = "33";
char fgblue[]     = "34";
char fgmagenta[]  = "35";
char fgcyan[]     = "36";
char fgwhite[]    = "37";

char bgblack[]    = "40";
char bgred[]      = "41";
char bggreen[]    = "42";
char bgyellow[]   = "43";
char bgblue[]     = "44";
char bgmagenta[]  = "45";
char bgcyan[]     = "46";
char bgwhite[]    = "47";

dispattr(attr,fg,bg)
	char * attr;
	char * fg;
	char * bg;
{
	printf("%c[%s;%s;%sm",27,attr,fg,bg);
}

int main(argc,argv)
	int argc;
	char *argv[];
{
	int i,j,k;
	int x,y;

	if(1 < argc) {
		for(i=1;i<argc;i++) {
			printf("%c",atoi(argv[i]));
		}
	} else  {
	


	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	
/*	printf("TT is %d\n",pSYSCFG->cnfgdata.termtype); */


		crtinit(pSYSCFG->cnfgdata.termtype);				
		crtclr();
		crtlc(0,0);

		dispattr(atbold,fggreen,bgblack);
		banner("CHARS");

		printf("%s",attroff);
		
		dispattr(atbold,fgcyan,bgblack);
		for(x=0;x<16;x++) {
			crtlc(TOP+6,LEFT+(x*4)+5);			
			printf("[%x]",x);
		}
		printf("%s",attroff);
		
		for(y=0;y<16;y++) {
			crtlc(TOP+y+7,LEFT+0);
			dispattr(atbold,fgcyan,bgblack);
			printf("[%x]",y);
			printf("%s",attroff);

			for(x=0;x<16;x++) {
				crtlc(TOP+y+7,LEFT+(x*4)+6);
				if(1 == map[(y*16)+x]) {
					printf(".");
				} else {
					printf("%c",(y*16)+x);				
				}
			}
			dispattr(atbold,fgcyan,bgblack);
			printf("  [%x]",y);
			printf("%s",attroff);
		}
	}
	
	return 0;
}
