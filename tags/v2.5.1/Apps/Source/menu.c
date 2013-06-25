/* menu.c 8/4/2012 dwg - framework of newcode */

/* This code is known to work in both ANSI and WSYSE termtype modes */

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

#define HORIZ "-"
#define VERTI "|"
#define SPACE ' '

struct SYSCFG * pSYSCFG = HIGHSEG;


struct MENUENT {
	char * szName;
	void (*meFunc)();
	struct MENUENT * pmeNext;	
};

mfFile();
mfEdit();
mfView();
mfOptions();
mfTransfer();
mfScript();
mfTools();
mfHelp();

struct MENUENT meHelp     = { "Help",     &mfHelp,     NULL        };
struct MENUENT meTools    = { "Tools",    &mfTools,    &meHelp     };
struct MENUENT meScript   = { "Script",   &mfScript,   &meTools    };
struct MENUENT meTransfer = { "Transfer", &mfTransfer, &meScripts  };
struct MENUENT meOptions  = { "Otions",   &mfOptions,  &meTransfer };
struct MENUENT meView     = { "View",     &mfView,     &meOptions  };
struct MENUENT meEdit     = { "Edit",     &mfEdit,     &meView     };
struct MENUENT meFile     = { "File",     &mfFile,     &meEdit     };

struct MENU {
	struct MENUENT * pFirstEnt;
};


struct MENU mMain = { &meFile };

struct WINDOW {
	char ull;
	char ulc;
	char lrl;
	char lrc;
	char bFill;
	struct MENU * pMenu;
};

struct WINDOW wRoot = { 1, 1, 23, 80, SPACE, &mMain};

window(win)
	struct WINDOW * win;
{	char width,height,x,y,filler,i;
	struct MENU    * pm;
	struct MENUENT * pme;
	i = 0;
	
	width = win->lrc-win->ulc+1;
	height = win->lrl-win->ull+1;
	for(y=0;y<height;y++) {
		crtlc(win->ull+y,win->lrc);
		printf(VERTI);
	}
	for(y=0;y<height;y++) {
		crtlc(win->ull+y,win->ulc);
		printf(VERTI);
	}
	crtlc(win->ull,win->ulc);
	for(x=0;x<width;x++) {
		printf(HORIZ);
	}
	crtlc(win->lrl,win->ulc);
	for(x=0;x<width;x++) {
		printf(HORIZ);
	}

	filler = win->bFill;
	if(0 != filler) {
		width = win->lrc-win->ulc-1;
		height = win->lrl-win->ull-1;
		for(y=0;y<height;y++) {
			crtlc(win->ull+y+1,win->ulc+1);
			for(x=0;x<width;x++) {
				printf("%c",filler);
			}
		}
	}


	pm = win->pMenu;
	if(0 != pm) {
		crtlc(win->ull+1,win->ulc+1);
		pme = pm->pFirstEnt;
		while(0 != pme) {
			printf("%s ",pme->szName);
			pme = pme->pmeNext;
		}	
	
	
	}


}


mfFile()
{

}

mfEdit()
{

}

mfView()
{
}

mfOptions()
{
}

mfTransfer()
{
}

mfScript()
{
}

mfTools()
{
}

mfHelp()
{
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
		
	window(&wRoot);
		
	crtlc(wRoot.lrl,wRoot.ulc);
}



