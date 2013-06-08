/* map.c 9/4/2012 dwg - added support for four more drives I: to L:        */
/* map.c 8/3/2012 dwg - added DEV_PPPSD and DEV_HDSK, fixed end of drives  */
/* map.c 6/7/2012 dwg - */

#include "portab.h"

#include "globals.h"

#include "stdio.h"

#include "stdlib.h"

#include "memory.h"

#include "cpmbind.h"

/* #include "cbioshdr.h" */

#include "infolist.h"

#include "dphdpb.h"

#include "dphmap.h"

#include "metadata.h"

#include "clogical.h"

#include "applvers.h"

#include "diagnose.h"

#include "cnfgdata.h"

#include "syscfg.h"

/* #define MAXDRIVE 12 */

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

/* Drive List Geometry */
#define COL1 5
#define COL2 25
#define COL3 45
#define COL4 65

#define LINE 3

/* Logical Unit List Geometry */
#define LGUT  5
#define COL1A 0
#define COL2A (80/3)
#define COL3A (2*COL2A)

/* Nomenclature Geometry */
#define LINE2 9

/* Misc Info Geometry */
#define CDLINE 7

/* BDOS Function number */
#define RETCURR 25

/* function defined in bdoscall.asm */
extern lurst();

struct BIOS * pBIOS;

struct DPH * pDPH;

struct CNFGDATA * pCNFGDATA;
struct SYSCFG * pSYSCFG;



int devunit;
int dev;
int unit;
int currlu;
int numlu;
int drivenum;
int drive;
int deflu;

char szTemp[128];

int readsec(drive,track,sector,buffer)
	int drive;
	int track;
	int sector;
	unsigned int buffer;
{
	ireghl = pSELDSK;
	iregbc = drive;
	iregde = 0;
	bioscall();
		
	ireghl = pSETTRK;
	iregbc = track;
	bioscall();
		
	ireghl = pSETSEC;
	iregbc = sector;
	bioscall();
		
	ireghl = pSETDMA;
	iregbc = buffer;
	bioscall();
		
	ireghl = pREAD;
	bioscall();
	return irega;
}




int haslu(dr)
	int dr;
{
	if(0 < lugnum(dr)) {
		return TRUE;
	} else {
		return FALSE;
	}
}



void dispdph(l,c,drive,ptr)
	int l;
	int c;
	char drive;
	struct DPH *ptr;
{

/*
		unsigned int xlt;	
		unsigned int rv1;
		unsigned int rv2;
		unsigned int rv3;
		unsigned int dbf;	
		unsigned int dpb;	
		unsigned int csv;	
		unsigned int alv;	
		unsigned char sigl;
		unsigned char sigu;
		unsigned int current;
		unsigned int number;
*/


	/* 8/3/2012 dwg - detect end of drives properly */
	ireghl = pGETLU;
	iregbc = drive-'A';
	bioscall();
	if(1 == irega) {
		return;
	}

	crtlc(l,c);
	printf("%c: ",drive);


	devunit = lugdu(drive-'A');


	dev     = devunit & 0xf0;
	unit    = devunit & 0x0f;	

	currlu  = lugcur(drive-'A');
	switch(dev) {
		case DEV_MD:
			if(0 == unit) printf("ROM");
			if(1 == unit) printf("RAM");
			break;
		case DEV_FD:
			printf("FD%d",unit);
			break;
		case DEV_IDE:
			printf("IDE%d",unit);
			break;
		case DEV_ATAPI:
			printf("ATAPI%d",unit);
			break;
		case DEV_PPIDE:
			printf("PPIDE%d",unit);
			break;
		case DEV_SD:
			printf("SD%d",unit);
			break;
		case DEV_PRPSD:
			printf("PRPSD%d",unit);
			break;
		case DEV_PPPSD:
			printf("PPPSD%d",unit);
			break;
		case DEV_HDSK:
			printf("HDSK%d",unit);
			break;
		default:	
			printf("UNK");
			break;
	};

	if('L' == (unsigned  char)ptr->sigl) {
		if('U' == (unsigned char)ptr->sigu) {
/*			printf("-LU%d",(int)ptr->current);	*/
			printf("-LU%d",currlu);
		}
	}
	
/*	printf("dpb=0x%04x, ",(unsigned int)ptr->dpb);
	printf("sigl=0x%02x, ",(unsigned char)ptr->sigl);
	printf("sigu=0x%02x, ",(unsigned char)ptr->sigu);
	printf("curr=0x%04x, ",(unsigned int)ptr->current);
	printf("numb=0x%04x",  (unsigned int)ptr->number);
*/

}

int main(argc,argv)
	int argc;
	char *argv[];
{
	int i;
	int	mylu;
	int drivenum;
	int column;
	int l;
	int line;
	int startlu;
	int limit;
	char bRunning;
	char szDrive[32];
	char szLuNum[32];
	char szWP[2];
	struct INFOLIST * pINFOLIST;
					
	if(argc == 3) {

		strcpy(szDrive,argv[1]);
		strcpy(szLuNum,argv[2]);

		mylu = atoi(szLuNum);		

		if(strlen(szDrive) == 2) {
			if(':' == szDrive[1]) {
				switch(szDrive[0]) {
					case 'a':
					case 'A':
						luscur(0,mylu);
						break;
					case 'b':
					case 'B':
						luscur(1,mylu);
						break;
					case 'c':
					case 'C':
						luscur(2,mylu);
						break;
					case 'd':
					case 'D':
						luscur(3,mylu);
						break;
					case 'e':
					case 'E':
						luscur(4,mylu);
						break;
					case 'f':
					case 'F':
						luscur(5,mylu);
						break;
					case 'g':
					case 'G':
						luscur(6,mylu);
						break;
					case 'h':
					case 'H':
						luscur(7,mylu);
						break;

					case 'i':
					case 'I':
						luscur(8,mylu);
						break;
					case 'j':
					case 'J':
						luscur(9,mylu);
						break;
					case 'k':
					case 'K':
						luscur(10,mylu);
						break;
					case 'l':
					case 'L':
						luscur(11,mylu);
						break;

					default:
						break;
				}			
			
			}			
		}
		exit(1);	
	}


	pBIOS = BIOSAD;
	

	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);

	printf("MAP.COM %d/%d/%d v%d.%d.%d (%d)",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - System Storage Drives and Logical Units");
	
	ireghl = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;

	crtlc(CDLINE,COL3A+LGUT);
	printf("infolist.version %d\n",pINFOLIST->version);			

	pDPHMAP = (struct DPHMAPA *)pINFOLIST->dphmap;


	dispdph(LINE,  COL1,'A',(struct DPH *)pDPHMAP->drivea);
	dispdph(LINE+1,COL1,'B',(struct DPH *)pDPHMAP->driveb);
	dispdph(LINE+2,COL1,'C',(struct DPH *)pDPHMAP->drivec);
	dispdph(LINE  ,COL2,'D',(struct DPH *)pDPHMAP->drived);
	dispdph(LINE+1,COL2,'E',(struct DPH *)pDPHMAP->drivee);
	dispdph(LINE+2,COL2,'F',(struct DPH *)pDPHMAP->drivef);
	dispdph(LINE,  COL3,'G',(struct DPH *)pDPHMAP->driveg);
	dispdph(LINE+1,COL3,'H',(struct DPH *)pDPHMAP->driveh);
	dispdph(LINE+2,COL3,'I',(struct DPH *)pDPHMAP->drivei);
	dispdph(LINE  ,COL4,'J',(struct DPH *)pDPHMAP->drivej);
	dispdph(LINE+1,COL4,'K',(struct DPH *)pDPHMAP->drivek);
	dispdph(LINE+2,COL4,'L',(struct DPH *)pDPHMAP->drivel);

	dregbc = RETCURR;
	bdoscall();
	drive = drega;

	crtlc(CDLINE,5);
	printf("Current drive is %c:",'A'+drive);

	devunit = lugdu(drive);
	dev     = devunit & 0xf0;
	unit    = devunit & 0x0f;	
	currlu  = lugcur(drive);
	deflu	= currlu;
	numlu   = lugnum(drive);
	
	crtlc(CDLINE,COL2A+LGUT);
	printf("Number of LUs is %d\n",lugnum(drive));

	if(0<numlu)  {
		crtlc(LINE2,COL1A+LGUT-1);	
		printf("LU P -----Label------");
		crtlc(LINE2,COL2A+LGUT-1);
		printf("LU P -----Label------");
		crtlc(LINE2,COL3A+LGUT-1);
		printf("LU P -----Label------");

		startlu = 0;
		limit = startlu+39;
		if(limit>numlu) limit = numlu;
		bRunning = 1;
		
		while(1 == bRunning) {

			line   = LINE2+1;
			column = 0;

			for(l=0;l<13;l++) {
				crtlc(line+l,0);
				/*               1         2         3         4	*/
				/*      1234567890123456789012345678901234567890	*/
				printf("				                        ");
				/*               5         6         7              */
				/*      123456789012345678901234567890123456789		*/
				printf("                            ");
			}
			
			for(i=startlu;i<limit;i++) {
				luscur(drive,i);
				readsec(drive,0,11,&metadata);
				metadata.term = 0;


				if(TRUE == metadata.writeprot) strcpy(szWP,"*");
				else                           strcpy(szWP," ");

				switch(column++) {
					case 0:
						crtlc(line,COL1A+LGUT-2);
						printf("%3d %s %s",i,szWP,metadata.label);
						break;
					case 1:
						crtlc(line,COL2A+LGUT-2);
						printf("%3d %s %s",i,szWP,metadata.label);
						break;
					case 2:
						crtlc(line,COL3A+LGUT-2);
						printf("%3d %s %s",i,szWP,metadata.label);
						column = 0;
						line++;
						break;		
				}
			}

			crtlc(23,0);
			printf("Options( N(ext), P(revious), Q(uit) )? ");
			
			dregbc = 1;	/* CONIN */
			bdoscall();
			
			switch(drega) {
				case 'Q':
				case 'q':
				case 'X':
				case 'x':
				case 3:			
					bRunning = 0;
					break;
				case 'N':
				case 'n':
				case ' ':
					startlu += 39;
					if(startlu>numlu) startlu=0;
					limit = startlu+39;
					if(limit > numlu) limit = numlu;					
					break;
				case 'P':
				case 'p':
					startlu -= 39;
					if(startlu < 0) startlu = 0;
					limit = startlu+39;
					if (limit > numlu) limit = numlu;
					break;
				default:
					printf("%c",7);
					break;
			}						
			
		} /* end of (1==bRunning)   */
		
		luscur(drive,deflu);
	}
}

/****************/
/* eof - cmap.c */
/****************/