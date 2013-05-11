/* flip.c 11/17/2012 dwg - reverse the contrast */

#include "std.h"
#include "applvers.h"
#include "diagnose.h"

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
		printf("hregbc = 0x%04x\n",hregbc);
	hregde = vidmode;
		printf("hregde = 0x%04x\n",hregde);
	hreghl = bitmapp;
		printf("hreghl = 0x%04x\n",hreghl);
	diagnose();
		printf("VDAINI called, return code was 0x%02x\n",hrega);
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
		printf("hregbc = 0x%04x\n",hregbc);
	hreghl = bitmapp;

	if(hreghl != 0x8000) printf("vdaqry says hl != 0x8000\n");

	diagnose();
		printf("VDAQRY called, status       was 0x%02x\n",hrega);
		printf("               video mode   was 0x%02x\n",hregbc & 255);
		printf("               row count    was 0x%02x(%d)\n",
				(hregde >> 8),(hregde >> 8) );
		printf("               column count was 0x%02x(%d)\n",
				hregde & 255, hregde & 255);

/*	if(0 != bitmapp) {
		printf("vdaqry called with bitmap pointer\n");
		bitlook();
	}
*/

	return hrega;
}


int main(argc,argv)
	int argc;
	char *argv[];
{
	unsigned char * p;
	unsigned char byte;
	int offs;
	int retcode;
	
	printf("flip.com(c) 11/15/2012 dwg - \n\n");
	
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

