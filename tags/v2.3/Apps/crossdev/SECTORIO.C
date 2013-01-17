/*************************************************************/
/* sectorio.c 6/6/2012 dwg - read and write physical sectors */
/*************************************************************/

#include "cpmbios.h"
#include "bioscall.h"

int rdsector(drive,track,sector,buffer,select)
	int drive;
	int track;
	int sector;
	unsigned int buffer;
	int select;
{
	ireghl = pSELDSK;
	iregbc = drive;
	iregde = select;
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


int wrsector(drive,track,sector,buffer,select)
	int drive;
	int track;
	int sector;
	unsigned int buffer;
	int select;
{
	ireghl = pSELDSK;
	iregbc = drive;
	iregde = select;
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
	bioscall();
	return irega;
}


/********************/
/* eof - sectorio.c */
/********************/
