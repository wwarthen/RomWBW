/* putc.c 11/21/2012 dwg - output a test character to the TMS9918 */

#include <stdio.h>
#include <stdlib.h>
#include <diagnose.h>
#include <n8chars.h>
#include <memory.h>

copyup()
{
	unsigned char * p;
	int ascii;
	int byte;
	
	p = 0x8000;
	for(ascii=0;ascii<256;ascii++) {
		for(byte=0;byte<8;byte++) {
			*p++ = charset[(ascii*8)+7-byte];		
		}		
	}
}

main()
{
	int index;
	
	copyup();
	hregbc = 0x4040;	
	hregde = 0;
	hreghl = 0x8000;
	diagnose();

	hregbc = 0x4440;
	hregde = (12<<8)+12;
	diagnose();
	
	for(index=0;index<600;index++) {
		hregbc = 0x4740;
		hregde = '?';
		diagnose();
	}
}
