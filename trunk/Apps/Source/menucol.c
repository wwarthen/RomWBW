/* menu.c 8/4/2012 dwg - framework of newcode */

/* This code is known to work in bot ANSI and WSYSE termtype modes */

#include "stdio.h"
#include "portab.h"
#include "globals.h"
#include "cpmbios.h"
#include "bioscall.h"
#include "cpmbdos.h"
#include "bdoscall.h"
#include "sectorio.h"
#include "diagnose.h"
#include "ctermcap.h"
#include "clogical.h"
#include "metadata.h"
#include "applvers.h"
#include "cnfgdata.h"
#include "syscfg.h"

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

struct SYSCFG * pSYSCFG = HIGHSEG;

#define NORMAL  0
#define BRIGHT  1
#define UNDER   4
#define BLINK   5
#define REVERSE 7
#define CANCEL  8

#define BLACK   0
#define RED     1
#define GREEN   2
#define YELLOW  3
#define BLUE    4
#define MAGENTA 5
#define CYAN    6
#define WHITE   7

#define FG      30
#define BG      40

struct BOX {
	char ull;
	char ulc;
	char lrl;
	char lrc;
	char fgnd;
	char bgnd;
};

struct BOX mainbx = { 1, 1, 23, 80, 0, 0};

char normalco[] = { 27, '[', NORMAL, ';', BG+BLACK, ';', FG+GREEN, 'm', 0 };
/* char mainco[]   = { 27, '[', BRIGHT, ';', BG+RED,   ';', FG+BLACK, 'm', 0 }; */

char mainco[]   = { 27, '[', BG+RED,   ';', FG+BLACK, 'm', 0 };

box(bx,borderco)
	struct BOX * bx;
	char * borderco;
{

	char width;
	char height;
	char x;
	char y;

/*	printf("%s",borderco);	
*/

	width = bx->lrc-bx->ulc+1;
	height = bx->lrl-bx->ull+1;
	
	for(y=0;y<height;y++) {
		crtlc(bx->ull+y,bx->lrc);
		printf("|");
	}

	for(y=0;y<height;y++) {
		crtlc(bx->ull+y,bx->ulc);
		printf("|");
	}



	crtlc(bx->ull,bx->ulc);
	for(x=0;x<width;x++) {
		printf("-");
	}

	crtlc(bx->lrl,bx->ulc);
	for(x=0;x<width;x++) {
		printf("-");
	}
}

fill(bx,filler,fillco)
	struct BOX * bx;
	char filler;
	char * fillco;
{

	char width;
	char height;
	char x;
	char y;
	
	width = bx->lrc-bx->ulc-1;
	height = bx->lrl-bx->ull-1;
	
/*	printf("%s",fillco);
*/

	for(y=0;y<height;y++) {
		crtlc(bx->ull+y+1,bx->ulc+1);
		for(x=0;x<width;x++) {
			printf("%c",filler);
		}
	}


}


main(argc,argv)
	int argc;
	char *argv[];
{
	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */

	pSYSCFG = HIGHSEG;
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
		
/*	banner("MENU");
*/

	box(&mainbx,mainco);
	fill(&mainbx,'%',normalco);	
	
	crtlc(mainbx.lrl,mainbx.ulc);
}



