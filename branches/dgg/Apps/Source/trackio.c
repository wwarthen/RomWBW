/*************************************************************/
/* track.c 6/6/2012 dwg - read and write physical sectors */
/*************************************************************/

#include "cpmbios.h"
#include "bioscall.h"

int rdtrack(drive,track,sector,buffer,mcnt)
	int drive;
	int track;
	int sector;
	unsigned int buffer;
	int mcnt;
{

/*	ireghl = pSELDSK;
	iregbc = drive;
	iregde = 0;
	bioscall();	*/
		
/*	ireghl = pSETTRK;
	iregbc = track;
	bioscall();	*/
		

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


int wrtrack(drive,track,sector,buffer,mcnt)
	int drive;
	int track;
	int sector;
	unsigned int buffer;
	int mcnt;
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
	bioscall();
	return irega;
}


/********************/
/* eof - sectorio.c */
/********************/
