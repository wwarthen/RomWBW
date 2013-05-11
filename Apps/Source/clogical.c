/* clogical.c 6/4/2012 dwg - */

#include "portab.h"
#include "cpmbios.h"
#include "asmiface.h"

lugcur(drive)
{
	asmif(pGETLU,drive,0,0);
	return xregde;
}

lugnum(drive)
{
	asmif(pGETLU,drive,0,0);
	return xreghl;
}

lugdu(drive)
{
	asmif(pGETLU,drive,0,0);
	return xregbc>>8;
}

luscur(drive,lunum)
{
	asmif(pGETLU,drive,0,0);
	/* A = Result 0=OK */
	/* B = devunit     */
	/* DE = current    */
	/* HL = numlu      */
	
	/* BC = devunit*256+drive */
	/* DE = current           */
	/* HL = numlu             */
	asmif(pSETLU,xregbc,lunum,xreghl);
}

lusnum(drive,numlu)
{
	asmif(pGETLU,drive,0,0);
	/* A = Result 0=OK */
	/* B = devunit     */
	/* DE = current    */
	/* HL = numlu      */
	
	/* BC = devunit*256+drive */
	/* DE = current           */
	/* HL = numlu             */
	asmif(pSETLU,xregbc,xregde,numlu);
}


/********************/
/* eof - clogical.c */
/********************/
