/* map.c 6/7/2012 dwg - */

#include "portab.h"
#include "globals.h"
#include "stdio.h"
#include "stdlib.h"
#include "memory.h"

#include "cpmbind.h"

#include "infolist.h"
#include "dphdpb.h"
#include "dphmap.h"
#include "metadata.h"
#include "clogical.h"
#include "applvers.h"

#define MAXDRIVE 8

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

/* Misc Info Geometry */
#define CDLINE 6

/* BDOS Function number */
#define RETCURR 25

/* function defined in bdoscall.asm */
extern lurst();

struct BIOS * pBIOS;

struct DPH * pDPH;

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
	int line;
	char szDrive[32];
	char szLuNum[32];
				
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
					default:
						break;
				}			
			
			}			
		}
		exit(1);	
	}


	pBIOS = BIOSAD;
	
	crtinit();
	crtclr();
	crtlc(0,0);

	printf("MAP.COM %d/%d/%d v%d.%d.%d.%d",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - System Storage Drives and Logical Units");
	
	ireghl = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;

	crtlc(CDLINE,COL3A+LGUT);
	printf("infolist.version %d\n",pINFOLIST->version);			

	pDPHMAP = (struct DPHMAPA *)pINFOLIST->dphmap;

	dispdph(LINE,  COL1+LGUT-1,'A',(struct DPH *)pDPHMAP->drivea);
	dispdph(LINE+1,COL1+LGUT-1,'B',(struct DPH *)pDPHMAP->driveb);
	dispdph(LINE,  COL2+LGUT-1,'C',(struct DPH *)pDPHMAP->drivec);
	dispdph(LINE+1,COL2+LGUT-1,'D',(struct DPH *)pDPHMAP->drived);
	dispdph(LINE,  COL3+LGUT-1,'E',(struct DPH *)pDPHMAP->drivee);
	dispdph(LINE+1,COL3+LGUT-1,'F',(struct DPH *)pDPHMAP->drivef);
	dispdph(LINE,  COL4+LGUT-1,'G',(struct DPH *)pDPHMAP->driveg);
	dispdph(LINE+1,COL4+LGUT-1,'H',(struct DPH *)pDPHMAP->driveh);

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
		crtlc(LINE2,COL1A+LGUT);	
		printf("LU -----Label------");
		crtlc(LINE2,COL2A+LGUT);
		printf("LU -----Label------");
		crtlc(LINE2,COL3A+LGUT);
		printf("LU -----Label------");

		line   = LINE2+1;
		column = 0;
		for(i=0;i<numlu;i++) {
			luscur(drive,i);
			readsec(drive,0,11,&metadata);
			metadata.term = 0;
			switch(column++) {
				case 0:
					crtlc(line,COL1A+LGUT);
					printf("%2d %s",i,metadata.label);
					break;
				case 1:
					crtlc(line,COL2A+LGUT);
					printf("%2d %s",i,metadata.label);
					break;
				case 2:
					crtlc(line,COL3A+LGUT);
					printf("%2d %s",i,metadata.label);
					column = 0;
					line++;
					break;		
			}
		}
		luscur(drive,deflu);
	}
}

/****************/
/* eof - cmap.c */
/****************/