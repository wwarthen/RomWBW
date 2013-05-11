/* view.c 6/7/2012 dwg - */

#include "std.h"
/* #include "hbios.h" */
#include "stdio.h"
#include "stdlib.h"
#include "memory.h"
#include "portab.h"
#define MAXDRIVE 8
#include "cpm80.h"
#include "cpmappl.h"
#include "applvers.h"

#include "trackio.h"

#define DSM144 0x02C6
#define DSM720 0x015E
#define DSM360 0x00AA
#define DSM120 0x024F
#define DSM111 0x0222

struct DPH * pDPH;
struct DPB * pDPB;

unsigned char buffer[72*128];
char gbFD[MAXDRIVE];
char gFDNums[MAXDRIVE];
char gNumFD;	/* this value is set by the fdcount function */

/*  the purpose of this function is to set the global variable 
	gNumFD to the number of floppy drives detected, and to set
	a boolean in the vector gbFD indicating the drive is present
	the drive number of each one in the vector 
*/

diomed(devunit)
	unsigned char devunit;
{
	hregbc = 0x1300 + devunit;
	diagnose();
	return hrega;
}

sensefd()
{
	char device;
	char unit;
	char devunit;
	
	/* init local variables */
	char drive;
	char result;
	drive  = 0;
	result = 0;

	/* init global variables */
	gNumFD = 0;
	memset(&gbFD,FALSE,MAXDRIVE);
	memset(&gFDNums,0,MAXDRIVE);
	/* for all valid drive numbers */
	while(0 == result) {	
		ireghl = pGETLU;
		iregbc = drive;
		bioscall();
		result = irega;
		/* return from GETLU goes to 1 if drive # invalid */
	
		devunit = iregbc >> 8;
		device  = devunit & 0xf0;
		unit    = devunit & 0x0f;
		if(DEV_FD == device) {
			gFDNums[gNumFD] = drive;
			gbFD[gNumFD++] = iregbc & 0xff;
		}		
		drive++;
	}
}


int main(argc,argv)
	int argc;
	char *argv[] ;
{
	char drive;
	int fd0,fd1;
	int i;
	int spt;
	int track;
	int tracks;
	int bValid;
			
	sensefd();
			
	if(2 != gNumFD) {
		printf("Sorry, this version of diskcopy only supports dual drives");
		exit(FAILURE);
	}
	printf("The copy will be from drive %c: to drive %c:\n",
			gFDNums[0]+'A',gFDNums[1]+'A');		
	
	printf("The media in FD0 is ");
	fd0 = diomed(DEV_FD);
	switch(fd0) {
		case MID_NONE:
					printf("Drive is empty");
					break;
		case MID_MDROM:
					printf("a memory ROM drive");
					break;
		case MID_MDRAM:
					printf("a memory RAM drive");
					break;
		case MID_HD:	
					printf("an HD drive");
					break;
		case MID_FD720:
					printf("a 720KB floppy disk");
					tracks = 80 * 2;
					break;
		case MID_FD144:
					printf("a 1.44MB floppy disk");
					tracks = 80 * 2;
					break;
		case MID_FD360:
					printf("a 360KB floppy disk");
					tracks = 40 * 2;
					break;
		case MID_FD120:
					printf("a 120KB floppy disk");
					tracks = 80 * 2;
					break;
		case MID_FD111:
					printf("a 111KB floppy disk");
					tracks = 74 * 2;
					break;
		default:
					printf("an unknown media type");
					break;
	}
	printf("\n");



	printf("The media in FD1 is ");
	fd1 = diomed(DEV_FD+1);
	switch(fd1) {
		case MID_NONE:
					printf("Drive is empty");
					break;
		case MID_MDROM:
					printf("a memory ROM drive");
					break;
		case MID_MDRAM:
					printf("a memory RAM drive");
					break;
		case MID_HD:	
					printf("an HD drive");
					break;
		case MID_FD720:
					printf("a 720KB floppy disk");
					break;
		case MID_FD144:
					printf("a 1.44MB floppy disk");
					break;
		case MID_FD360:
					printf("a 360KB floppy disk");
					break;
		case MID_FD120:
					printf("a 120KB floppy disk");
					break;
		case MID_FD111:
					printf("a 111KB floppy disk");
					break;
		default:
					printf("an unknown media type");
					break;
	}
	printf("\n");

	if(fd0 != fd1) {
		printf("Sorry, media types don't match, as required for diskcopy");
		exit(1);
	}

	for(track=0;track<tracks;track++) {
	
		ireghl = pSELDSK;
		iregbc = gFDNums[0];				/* G: */
		iregde = 0;
		bioscall();
		pDPH   = ireghl;
		pDPB   = pDPH->dpb;
		spt    = pDPB->spt;
		ireghl = pSETTRK;
		iregbc = track;
		bioscall();
		printf("%3d ",track);
		rdtrack(0,spt,buffer);	
		printf("%c",0x0d);

		bValid = FALSE;
		for(i=0;i<spt*128;i++) {
			if(0xe5 != buffer[i]) {
				bValid = TRUE;
				break;
			}
		}
		
		if(TRUE == bValid) {
		
			ireghl = pSELDSK;
			iregbc = gFDNums[1];				/* G: */
			iregde = 0;
			bioscall();
			pDPH   = ireghl;
			pDPB   = pDPH->dpb;
			spt    = pDPB->spt;
			ireghl = pSETTRK;
			iregbc = track;				/* Track 0 */
			bioscall();
			printf("%3d ",track);
			wrtrack(0,spt,buffer);	
			printf("%c",0x0d);

		}
		
	}		
}
