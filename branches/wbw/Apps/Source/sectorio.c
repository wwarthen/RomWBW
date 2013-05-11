/**************************************************************/
/* sectorio.c 7/30/2012 dwg - read and write physical sectors */
/**************************************************************/

/* 7/30/2012 dwg - wrsector now has c=0 for WRITE call per Wayne */

#include "cpmbios.h"
#include "bioscall.h"

int rdsector(drive,track,sector,buffer)
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


int wrsector(drive,track,sector,buffer)
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
		
	ireghl = pWRITE;
	iregbc = 0;			/* default to  0 per  wayne 7/30.2012 */
	bioscall();
	return irega;
}


/********************/
/* eof - sectorio.c */
/********************/
