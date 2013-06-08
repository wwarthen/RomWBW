/* view.c 6/7/2012 dwg - */

#include "std.h"
#include "stdio.h"
#include "stdlib.h"
#include "memory.h"
#include "portab.h"
#define MAXDRIVE 8
#include "cpm80.h"
#include "cpmappl.h"
#include "applvers.h"
#include "cnfgdata.h"
#include "syscfg.h"

#define DSM144 0x02C6
#define DSM720 0x015E
#define DSM360 0x00AA
#define DSM120 0x024F
#define DSM111 0x0222

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

/* Drive List Geometry */
#define COL1 0
#define COL2 (80/4)
#define COL3 (80/2)
#define COL4 (COL2+COL3)
#define LINE 3

/* Logical Unit List Geometry */
#define LGUT  5
#define COL1A 0
#define COL2A (80/3)
#define COL3A (2*COL2A)

/* Nomenclature Geometry */
#define LINE2 8


/* BDOS Function number */
#define RETCURR 25

struct SYSCFG * pSYSCFG = HIGHSEG;

dispdpb(line,column,pDPB)
	int line;
	int column;
	struct DPB * pDPB; 
{
	crtlc(line+0,column);	
	printf("[%x] spt =%x",&pDPB->spt,pDPB->spt);
	crtlc(line+1,column);	
	printf("[%x] bsh =%x",&pDPB->bsh,pDPB->bsh);
	crtlc(line+2,column);	
	printf("[%x] blm =%x",&pDPB->blm,pDPB->blm);
	crtlc(line+3,column);	
	printf("[%x] exm =%x",&pDPB->exm,pDPB->exm);
	crtlc(line+4,column);	
	printf("[%x] dsm =%x",&pDPB->dsm,pDPB->dsm);
	crtlc(line+5,column);	
	printf("[%x] drm =%x",&pDPB->drm,pDPB->drm);
	crtlc(line+6,column);	
	printf("[%x] al0 =%x",&pDPB->al0,pDPB->al0);
	crtlc(line+7,column);	
	printf("[%x] al1 =%x",&pDPB->al1,pDPB->al1);
	crtlc(line+8,column);	
	printf("[%x] cks =%x",&pDPB->cks,pDPB->cks);
	crtlc(line+9,column);	
	printf("[%x] off =%x",&pDPB->off,pDPB->off);	
}

struct DPB * dispdph(drive,line,column)
	int drive;
	int line;
	int column;
{

	struct DPH * pDPH;
	struct DPB * pDPB;
		
	unsigned char * p;
	int devunit;
	
	ireghl = pSELDSK;
	iregbc = drive;
	iregde = 0;
	bioscall();
	if(0 ==  ireghl) {
		return NULL;
	}
	pDPH = ireghl;
	pDPB = pDPH->dpb;
		
	p    = ireghl - 1;
	devunit = (unsigned char)*p;
		
	crtlc(line-1,column+1);	printf("Drive %c: ",'A'+drive);

	switch(devunit) {
		case DEV_MD+1:		printf("   RAM");	break;
		case DEV_MD+0:		printf("   ROM");	break;
		case DEV_FD+0:		printf("   FD0");	break;
		case DEV_FD+1:		printf("   FD1");	break;
		case DEV_IDE+0:		printf("  IDE0");	break;
		case DEV_IDE+1:		printf("  IDE1");	break;
		case DEV_ATAPI+0:	printf("ATAPI0");	break;
		case DEV_ATAPI+1:	printf("ATAPI1");	break;
		case DEV_PPIDE+0:	printf("PPIDE0");	break;
		case DEV_PPIDE+1:	printf("PPIDE1");	break;
		case DEV_SD+0:		printf("   SD0");	break;
		case DEV_SD+1:		printf("   SD1");	break;
		case DEV_PRPSD+0:	printf("PRPSD0");	break;
		case DEV_PRPSD+1:	printf("PRPSD1");	break;
		case DEV_PPPSD+0:	printf("PPPSD0");	break;
		case DEV_PPPSD+1:	printf("PPPSD1");	break;
	}


	crtlc(line+0,column);	printf("[%x] xlt =%x",
								&pDPH->xlt,pDPH->xlt);
	crtlc(line+1,column);	printf("[%x] rv1 =%x",
								&pDPH->rv1,pDPH->rv1);
	crtlc(line+2,column);	printf("[%x] rv2 =%x",
								&pDPH->rv2,pDPH->rv2);
	crtlc(line+3,column);	printf("[%x] rv3 =%x",
								&pDPH->rv3,pDPH->rv3);
	crtlc(line+4,column);	printf("[%x] dbf =%x",
								&pDPH->dbf,pDPH->dbf);
	crtlc(line+5,column);	printf("[%x] dpb =%x",
								&pDPH->dpb,pDPH->dpb);
	crtlc(line+6,column);	printf("[%x] csv =%x",
								&pDPH->csv,pDPH->csv);
	crtlc(line+7,column);	printf("[%x] alv =%x",
								&pDPH->alv,pDPH->alv);
	if( ('L' == pDPH->sigl) && ('U' == pDPH->sigu) ) {
		crtlc(line+8,column);
		printf("[%x] sigl=%x",&pDPH->sigl,pDPH->sigl);
		crtlc(line+9,column);
		printf("[%x] sigu=%x",&pDPH->sigu,pDPH->sigu);
		crtlc(line+10,column);
		printf("[%x] curr=%x",&pDPH->current,pDPH->current);
		crtlc(line+11,column);
		printf("[%x] numb=%x",&pDPH->number,pDPH->number);
	}

	if(DSM720 == pDPB->dsm) {
		crtlc(line+9,column+1);		printf("3-1/2");
									printf("%c  9 SPT",'"');
		crtlc(line+10,column+1);	printf("720KB DSDD FMT");
	}				
	if(DSM144 == pDPB->dsm) {
		crtlc(line+9,column+1);		printf("3-1/2");
									printf("%c 18 SPT",'"');
		crtlc(line+10,column+1);	printf("1.44MB DSHD FMT");
	}				
	if(DSM360 == pDPB->dsm) {
		crtlc(line+9,column+1);		printf("5-1/4");
									printf("%c  9 SPT",'"');
		crtlc(line+10,column+1);	printf("360KB DSDD FMT");
	}				
	if(DSM120 == pDPB->dsm) {
		crtlc(line+9,column+1);		printf("5-1/4");
									printf("%c 15 SPT",'"');
		crtlc(line+10,column+1);	printf("1.2MB DSHD FMT");
	}				
	if(DSM111 == pDPB->dsm) {
		crtlc(line+9,column+1);		printf("    8");
									printf("%c 15 SPT",'"');
		crtlc(line+10,column+1);	printf("1.11MB DSDD FMT");
	}				

	dispdpb(line+12,column,pDPH->dpb);
}
	

int main(argc,argv)
	int argc;
	char *argv[] ;
{
	int base;
	int columns;
	char szParm[128];

	dregbc = RETCURRDISK;
	bdoscall();
	base = drega;

	switch(base) {
		case 0:
			columns = 4;
			break;
		case 1:
			columns = 4;
			break;
		case 2:
			columns = 4;
			break;
		case 3:
			columns = 4;
			break;
		case 4:
			columns = 4;
			break;
		case 5:
			columns = 3;
			break;
		case 6:
			columns = 2;
			break;
		case 7:
			columns = 1;
			break;
		default:
			columns = 0;
			break;
	}

	if(2 == argc) {
		strcpy(szParm,argv[1]);
		if(2 == strlen(szParm)) {
			if(':' == szParm[1]) {		
				switch(szParm[0])  {
					case 'A':
					case 'a':
						base = 0;
						columns = 4;
						break;
					case 'B':
					case 'b':
						base = 1;
						columns = 4;
						break;
					case 'C':
					case 'c':
						base = 2;
						columns = 4;
						break;
					case 'D':
					case 'd':
						base = 3;
						columns = 4;
						break;
					case 'E':
					case 'e':
						base = 4;
						columns = 4;
						break;
					case 'F':
					case 'f':
						base = 5;
						columns = 3;
						break;
					case 'G':
					case 'g':
						columns = 2;
						base = 6;
						break;
					case 'H':
					case 'h':
						base = 7;
						columns = 1;
						break;

					case 'I':
					case 'i':
						base = 8;
						columns = 1;
						break;

					case 'J':
					case 'j':
						base = 9;
						columns = 1;
						break;

					case 'K':
					case 'k':
						base = 10;
						columns = 1;
						break;

					case 'L':
					case 'l':
						base = 11;
						columns = 1;
						break;

				}
			}
		}		
	}


	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);

	printf("VIEW.COM %d/%d/%d v%d.%d.%d (%d)",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - System Storage Drives and Logical Units");

	if(0 < columns) {		
		dispdph(base+0,3,2+0);
	}
	if(1 < columns) { 
		dispdph(base+1,3,2+20);
	}
	if(2 < columns) {
		dispdph(base+2,3,2+40);
	}
	if(3 < columns) {
		dispdph(base+3,3,2+60);
	}

	dregbc = 0;
	bdoscall();
}

/*****************/
/* eof - cview.c */
/*****************/
