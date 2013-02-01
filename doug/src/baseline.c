/*
 * baseline.c - Diagnostic EPROM for the N8VEM SBC V2
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "portab.h"
#include "sbcv2.h"
#include "ns16550.h"

/* #include "cpmbdos.h" */

/* THESE ARE USED BY THE LIBRARY ROUTINES */
char getchar(void)
{
/*
        struct BDOSCALL cread = { C_READ, { (unsigned int)0 } };
        return cpmbdos(&cread);
*/
	return 0;
}
void outchar(char c)
{
	if(c) ;
/*
        struct BDOSCALL cwrite = { C_WRITE, { (unsigned int)c } };
        cpmbdos(&cwrite);
*/
}


void xdisable(void)
{
}

void xenable(void)
{
}

void intmode(U8 xmode)
{
	if(xmode);
}

int main(void)
{
	pMPCL_ROM = 0x80; 	
	pMPCL_RAM = 0x81;	
	
	memcpy(0,0x0E5,0x2000);	

	pMPCL_ROM = 0x80;	
	pMPCL_RAM = 0x00;	

	xdisable();
	intmode(1);
	pMPCL_ROM = 0x00;	
	pMPCL_RAM = 0x00;	

	memcpy(RAMTARG_CPM,ROMSTART_CPM,CCPSIZ_CPM);

	pMPCL_ROM = 0x80;	
	pMPCL_RAM = 0x00;	
	return (0);
}

