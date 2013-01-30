/*
 *
 * i8255.c
 *
 */

#include "portab.h"
#include "sbcv2.h"
#include "i8255.h"

void pport_init()
{
	pCNTRL = 0x80;
	pPORTA = 0x00;
	pCNTRL = 0x00;
	pPORTA = 0x00;
	pPORTB = 0x00;
	pPORTC = 0x00;
}        

/*
 *
 * eof - i8255.c
 *
 */

