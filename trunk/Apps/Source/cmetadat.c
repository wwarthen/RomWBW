/* metadata.c 6/10/2012 dwg - functions for manipulating a drive's metadata */

#include "portab.h"
#include "globals.h"
#include "cpmbios.h"
#include "bioscall.h"
#include "sectorio.h"
#include "infolist.h"
#include "dphmap.h"

int hasmeta(drive)
	int drive;
{
	ireghl    = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;
	pDPHVEC   = pINFOLIST->dphmap;
	pDPH      = pDPHVEC[drive]
	pDPB      = pDPH->dpb;
	if(0 < pDPB->off) {
		return TRUE;
	} else {
		return FALSE;
	}

}

int getmeta(drive,buffer)
	int drive;
	struct METADATA * buffer;
{
	if(TRUE == hasmeta(drive)) {
		rdsector(drive,track,sector,buffer,0);
		return SUCCESS;
	} else {
		return FAILURE;
	}
}

int putmeta(drive,buffer)
	int drive;
	struct METADATA * buffer;
{
	if(TRUE == hasmeta(drive)) {
		wrsector(drive,track,sector,buffer,0);
		return SUCCESS;
	} else {
		return FAILURE;
	}
}

/********************/
/* eof - metadata.c */
/********************/



