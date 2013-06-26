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

char hexchar(val, bitoff)
{
	static char hexmap[] = "0123456789ABCDEF";

	return hexmap[(val >> bitoff) & 0xF];
}

char * fmthexbyte(val, buf)
	unsigned char val;
	char * buf;
{
	buf[0] = hexchar(val, 4);
	buf[1] = hexchar(val, 0);
	buf[2] = '\0';
	
	return buf;
}

char * fmthexword(val, buf)
	unsigned int val;
	char * buf;
{
	buf[0] = hexchar(val, 12);
	buf[1] = hexchar(val, 8);
	fmthexbyte(val, buf + 2);

	return buf;
}

dispdpb(line,column,pDPB)
	int line;
	int column;
	struct DPB * pDPB;
{
	char buf[5];
	char buf2[5];

	crtlc(line+0,column);	
	printf("[%s] spt =%s", fmthexword(&pDPB->spt, buf), fmthexword(pDPB->spt, buf2));
	crtlc(line+1,column);	
	printf("[%s] bsh =%s", fmthexword(&pDPB->bsh, buf), fmthexword(pDPB->bsh, buf2));
	crtlc(line+2,column);	
	printf("[%s] blm =%s", fmthexword(&pDPB->blm, buf), fmthexbyte(pDPB->blm, buf2));
	crtlc(line+3,column);	
	printf("[%s] exm =%s", fmthexword(&pDPB->exm, buf), fmthexbyte(pDPB->exm, buf2));
	crtlc(line+4,column);	
	printf("[%s] dsm =%s", fmthexword(&pDPB->dsm, buf), fmthexword(pDPB->dsm, buf2));
	crtlc(line+5,column);	
	printf("[%s] drm =%s", fmthexword(&pDPB->drm, buf), fmthexword(pDPB->drm, buf2));
	crtlc(line+6,column);	
	printf("[%s] al0 =%s", fmthexword(&pDPB->al0, buf), fmthexbyte(pDPB->al0, buf2));
	crtlc(line+7,column);	
	printf("[%s] al1 =%s", fmthexword(&pDPB->al1, buf), fmthexbyte(pDPB->al1, buf2));
	crtlc(line+8,column);	
	printf("[%s] cks =%s", fmthexword(&pDPB->cks, buf), fmthexword(pDPB->cks, buf2));
	crtlc(line+9,column);	
	printf("[%s] off =%s", fmthexword(&pDPB->off, buf), fmthexword(pDPB->off, buf2));
}

struct DPB * dispdph(drive,line,column)
	int drive;
	int line;
	int column;
{
	char buf[5];
	char buf2[5];
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


	crtlc(line+0,column);	
	printf("[%s] xlt =%s", fmthexword(&pDPH->xlt, buf), fmthexword(pDPH->xlt, buf2));
	crtlc(line+1,column);
	printf("[%s] rv1 =%s", fmthexword(&pDPH->rv1, buf), fmthexword(pDPH->rv1, buf2));
	crtlc(line+2,column);	
	printf("[%s] rv2 =%s", fmthexword(&pDPH->rv2, buf), fmthexword(pDPH->rv2, buf2));
	crtlc(line+3,column);	
	printf("[%s] rv3 =%s", fmthexword(&pDPH->rv3, buf), fmthexword(pDPH->rv3, buf2));
	crtlc(line+4,column);	
	printf("[%s] dbf =%s", fmthexword(&pDPH->dbf, buf), fmthexword(pDPH->dbf, buf2));
	crtlc(line+5,column);	
	printf("[%s] dpb =%s", fmthexword(&pDPH->dpb, buf), fmthexword(pDPH->dpb, buf2));
	crtlc(line+6,column);	
	printf("[%s] csv =%s", fmthexword(&pDPH->csv, buf), fmthexword(pDPH->csv, buf2));
	crtlc(line+7,column);	
	printf("[%s] alv =%s", fmthexword(&pDPH->alv, buf), fmthexword(pDPH->alv, buf2));
	if( ('L' == pDPH->sigl) && ('U' == pDPH->sigu) ) {
		crtlc(line+8,column);
		printf("[%s] sigl=%s", fmthexword(&pDPH->sigl, buf), fmthexbyte(pDPH->sigl, buf2));
		crtlc(line+9,column);
		printf("[%s] sigu=%s", fmthexword(&pDPH->sigu, buf), fmthexbyte(pDPH->sigu, buf2));
		crtlc(line+10,column);
		printf("[%s] curr=%s", fmthexword(&pDPH->current, buf), fmthexword(pDPH->current, buf2));
		crtlc(line+11,column);
		printf("[%s] numb=%s", fmthexword(&pDPH->number, buf), fmthexword(pDPH->number, buf2));
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