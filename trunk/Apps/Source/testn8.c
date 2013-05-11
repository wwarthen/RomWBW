/* lookn8.c 8/30/2012 dwg - look at n8 hardware */

#include "stdio.h"

#include "std21.h"


/*
	int in(unsigned int address);
	int out(unsigned int address,int data);
*/


#define BASE 128
#define DATAP (BASE+24)
#define CMDP (BASE+25)


int main(argc,argv)
	int argc;
	char *argv[];
{


/*
#define N8_IOBASE 0x80
#define PIO2 (N8_IOBASE+4)
#define PIO2A PIO2
#define PIO2B (PIO2+1)
#define PIO2C (PIO2+2)
#define PIO2X (PIO2+3)

#define RTC (N8_IOBASE+8)
#define ACR (N8_IOBASE+0x14)
#define RMAP (N8_IOBASE+0x16)
#define VDP (N8_IOBASE+0x18)
#define PSG (N8_IOBASE+0x1c)
*/



	printf("N8_IOBASE is 0x%04x\n",N8_IOBASE);
	printf("RTC       is 0x%04x value is 0x%2x\n",RTC,in(RTC));
	printf("ACR       is 0x%04x\n",ACR);
	printf("RMAP      is 0x%04x\n",RMAP);
	printf("VDP       is 0x%04x\n",VDP);
	printf("PSG       is 0x%04x\n",PSG);
}

 NN  