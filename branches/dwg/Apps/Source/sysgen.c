/* sysgen.c 6/7/2012 dwg - 108 records 0,0 through 0,107 */

#include "std.h"
#include "stdio.h"
#include "globals.h"
#include "stdlib.h"
#include "memory.h"
#include "portab.h"
#include "cpm80.h"
#include "cpmappl.h"
#include "applvers.h"
#include "sectorio.h"	
#include "infolist.h"
#include "cnfgdata.h"
#include "syscfg.h"

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */


/* rdsector(drive,track,sector,buffer); */


struct DPH * pDPH;
struct DPB * pDPB;

struct SYSCFG * pSYSCFG = HIGHSEG;

unsigned char filespec[32];

unsigned char * pBUFFER;

unsigned char szDrive[32];

char szTemp[128];

rdimage(filename,bufptr,bufsiz)
	char * filename;
	char * bufptr;
	int    bufsiz;
{
	int bytes;
	FILE * fdsys;
	
/*	printf("rdimage called\n");
	printf("  filename is %s\n",filename);
	printf("  bufptr   is 0x%04x\n",bufptr);
	printf("  bufsiz   is 0x%04x\n",bufsiz);
*/

	fdsys = fopen(filename,"r");
	if(NULL == fdsys) {
		return 0;
	}
	bytes = fread(bufptr,1,bufsiz,fdsys);
	fclose(fdsys);
	return bytes;
}


strupr(ptr)
	char * ptr;
{
	int i;
	for(i=0;i<strlen(ptr);i++) {
		if( ptr[i] >= 'a' ) {
			if( ptr[i] <= 'z') {
				ptr[i] = ptr[i] & 0xdf;
			}
		}
	}

}	


sysgen(drive,trk,sec,ptr,spt,cnt)
	int drive;
	int trk;
	int sec;
	char * ptr;
	int spt;
	int cnt;
{
	while ( 0 < cnt ) {
	
		wrsector(drive,trk,sec,ptr);	

		printf("drive=%c:, trk=%d, sec=%3d,  ptr=0x0%4x   ",
				drive+'A', trk,    sec,      ptr);
		printf("%c",0x0d);				
		ptr += 128;
		sec++;
		if(sec == spt) {
			trk++;
			sec = 0;
		}
		cnt--;
	}
	printf("                                        ");
	printf("%c",0x0d);
}





int main(argc,argv)
	int argc;
	char *argv[] ;
{
	int base;
	int bytes;
	int columns;
	int spt;
	int trk;
	int sec;
	int cnt;
	int	drive;
	int dstdrive;
	int off;
			
	char szParm[128];
	unsigned char * ptr;
	unsigned char * p;	

	
	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */

/*	printf("TT is %d\n",pSYSCFG->cnfgdata.termtype); */

	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);

	printf("SYSGEN.COM %d/%d/%d v%d.%d.%d.%d",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - Write System Image to Storage Media\n");

	/* scenarios:
	
		1. "sysgen"
			Copies ROM:cpm.sys to current drive
					
		2. "sysgen filespec"
			Copies filespec to current drive
			
		3. "sysgen filespec x:"
			Copies filespec to x: drive
			
	*/

	dregbc = RETCURRDISK;
	bdoscall();
	dstdrive = drega;

	pBUFFER = 0x08000;

	if(1 == argc) {
		/* copy ROM:cpm.sys to current drive */

 		for(drive=0;drive<MAXDRIVE;drive++) {
			ireghl = pGETLU;
			iregbc = drive;
			bioscall();
			if(DEV_MD == (iregbc>>8) ) {
				break;
			}		
		}

		sprintf(filespec,"%c:CPM.SYS",drive+'A');
		bytes = rdimage(filespec,pBUFFER,16383);
		if(0 == bytes) {
			sprintf(filespec,"%c:ZSYS.SYS",drive+'A');
			bytes = rdimage(filespec,pBUFFER,16383);
			if(0 == bytes) {
				printf("Sorry, could not read default system file");
				exit(1);
			}
		}

	}

	if(2 == argc) {
		strcpy(filespec,argv[1]);			
		bytes = rdimage(filespec,pBUFFER,16383);
	}

	if(3 == argc) {
		strcpy(filespec,argv[1]);
		strcpy(szDrive,argv[2]);
		strupr(szDrive);
		dstdrive = szDrive[0]-'A';
		bytes = rdimage(filespec,pBUFFER,16383);
	}


	ireghl = pSELDSK;
	iregbc = dstdrive;
	iregde = 0;
	bioscall();
	pDPH = ireghl;
	pDPB = pDPH->dpb;
	spt  = pDPB->spt;
	off  = pDPB->off;
			
	trk = 0;
	sec = 0;
	ptr = pBUFFER;

	cnt = bytes/128;

	if(0 == off) {
		printf("Sorry, %c: Drive does not have reserved tracks\n",
				dstdrive+'A');
		exit(1);
	}

	printf("Preparing to transfer the CP/M system image to the ");
	printf("%c: drive from %s\nfile which is %d",dstdrive+'A',filespec,bytes);
	printf(" bytes long, OK? (Y/n): ");
	printf("\n");
	
	dregbc = 1;
	bdoscall();
	if('Y' != drega) {
		printf("Sysgen operation cancelled per your request.\n");
		exit(1);
	}	
	
	sysgen(dstdrive,trk,sec,pBUFFER,spt,cnt);
	printf("%c: drive should be bootable now :-)",dstdrive+'A');
}

/*******************/		
/* eof - csysgen.c */
/*******************/

