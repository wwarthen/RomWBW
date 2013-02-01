/*
 * scsi2ide.c - main program for scsi2ide-0111 firmware
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "portab.h"
#include "scsi2ide.h"
#include "ns16550.h"


/* THESE ARE USED BY THE LIBRARY ROUTINES */
char get_char(void)
{
        while(UART_RDA & rUART_LSR) ;
        return rUART_RDR;
}
void out_char(char c)
{
        while(UART_TBE & rUART_LSR) ;
        wUART_TDR = c;
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
	/* uart init must be done before library
	   uses input or output primitives    */
        wUART_LCR    = UART_DLAB;
        wUART_DIV_HI = 0;
        wUART_DIV_LO = 12;	/* 9600 baud */
        wUART_LCR    = 0x03;	/* 8N1       */
        wUART_MCR    = 0x03;


	printf("\nN8VEM SCSI2IDE-0111 %s Dated %s %s\n",
		__FILE__,__DATE__,__TIME__);

	printf("\nmain() completed\n");

	return (0);
}

