/* twodrive.c 7/11/2012 dwg - */

/* This program is experimental and is not for release because
   it contains techniques which are not recommended because
   there are better API functions to do these operations.       */

/*
	This code is in the crossdev folder because it is part of
	my development environment, and I said I would make everything
	available.
	
	The purpose of this code is to dynamically alter the BIOS
	data associated with PPIDE (or PPISD) drives. The default
	configuration is that mass storage devices get four drives.
	
	Each of the four drives can be remapped using the logical 
	unit utility MAP.
	
	The purpose of this code is to alter the runtime data so that
	instead of the PPIDE having four drives for the primary IDE
	device, it then has two for the primary and two for the secondary.
	
	The MAP command will properly display the status after this is
	run, but you must keep in mind that having two sets of logical
	units at the same time is twice as complicated to keep straight
	in your mind, and you have to be more careful you know exactly
	how the drives are mapped so you don't accidentally destroy your
	data.
	
	This utility is unsupported, and not recommended for general use.
	The reason this utility wasn't generally published is that it
	is very difficult to give support about this remotely.
	
	If you are brave, and talented, and you can figure out what I did
	with pointers in this program, then you get the prize, which is
	to be able to copy from one CF chip to another in a dual adapter.
	
	It has only been tested on my PPIDE, and I don't know what will 
	happen if you try it. You could wipe out your CF chip, so make
	sure you are backed up if you try this.
*/


#include "cpmbios.h"
#include "bioscall.h"

#include "cpmbdos.h"
#include "bdoscall.h"

#define u8  unsigned char
#define u16 unsigned int

struct DPH * pDPH_C;
struct DPB * pDPB_C;
u8 * pDU_C;
u16 * pCUR_C;
u16 * pNUM_C;

struct DPH * pDPH_D;
struct DPB * pDPB_D;
u8 * pDU_D;
u16 * pCUR_D;
u16 * pNUM_D;

main(argc,argv)
	int argc;
	char *argv[];
{

	ireghl = pSELDSK;
	iregbc = DRIVEC;
	iregde = 0;
	bioscall();
	pDPH_C = ireghl;
	pDPB_C = pDPH_C->dpb;
	pDU_C  = ireghl -1;
	*pDU_C = 0X41;
	printf("Current C: DevUnit        is %02x\n",*pDU_C);
	pCUR_C = ireghl + 18;
	*pCUR_C = 0;
	printf("Current C: Logical Unit   is %d\n",* pCUR_C);
	pNUM_C = ireghl + 20;
	*pNUM_C = 64/9;
	printf("Current C: Number of LU's is %d\n",* pNUM_C);
	
	ireghl = pSELDSK;
	iregbc = DRIVED;
	iregde = 0;
	bioscall();

	pDPH_D = ireghl;
	pDPB_D = pDPH_D->dpb;
	pDU_D  = ireghl -1;
	*pDU_D = 0x41;
	printf("Current D: DevUnit        is %02x\n",*pDU_D);

	pCUR_D = ireghl + 18;
	*pCUR_D = 1;
	printf("Current D: Logical Unit   is %d\n",* pCUR_D);

	pNUM_D = ireghl + 20;
	*pNUM_D = 64/9;
	printf("Current D: Number of LU's is %d\n",* pNUM_D);
		

}
