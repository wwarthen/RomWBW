/* editor.c 11/18/2012 dwg - */


#include "std.h"
#include "applvers.h"
#include "diagnose.h"
#include "cpmbdos.h"
#include "cpmbios.h"
#include "bdoscall.h"


#define VDA_N8 4
#define VDAINI 0x40
#define VDAQRY 0x41
#define VDARES 0x42
#define VDASCS 0x43


int vdaini(devunit,vidmode,bitmapp)
	unsigned int devunit;
	unsigned int vidmode;
	unsigned int bitmapp;
{
	hregbc = (VDAINI << 8) | devunit;
	hregde = vidmode;
	hreghl = bitmapp;
	diagnose();
	return hrega;
}


bitlook()
{
	unsigned char *p;
	int ascii,row;
	
	p = 0x8000;
	for(ascii=0;ascii<256;ascii++) {
		printf("ascii = 0x%02x ",ascii);
		for(row=0l;row<8;row++) {
			printf("0x%02x ",*p++);	
		}
		printf("\n");
	}
}


int vdaqry(devunit,bitmapp)
	unsigned int devunit;
	unsigned int bitmapp;
{
	hregbc = (VDAQRY << 8) | devunit;
	hreghl = bitmapp;
	diagnose();
	return hrega;
}


flip()
{
	unsigned char * p;
	unsigned char byte;
	int offs;
	int retcode;
	
	retcode = vdaqry(VDA_N8 << 4,0x8000);	

	p = 0x8000;
	for(offs=0;offs<256*8;offs++) {
		byte = *p;
		byte = byte ^ 255;
		*p = byte;
		p++;		
	}

/*	bitlook(); */

	vdaini(VDA_N8 << 4, 0, 0x8000);
}


int main(argc,argv)
	int argc;
	char *argv[];
{
	int bRunning;
	
	bRunning = 1;
	while(1 == bRunning) {

		crtlc (
		dregbc = 1;
		bdoscall();
		switch(drega) {
			case 'f':	flip();			break;
			case 3:		bRunning = 0;	break;
			default:	printf("%c",7);	break;
		}
	}

	flip();
}
