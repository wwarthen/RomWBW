#include "stdio.h"

extern unsigned char * bits;

main()
{
	int ascii;
	int index;
	
	
	FILE * fd;
	fd = fopen("n8chars2.h","w");
	
	index = 0;
	
	for(ascii=0;ascii<256;ascii++) {
		byte8 = charset[index++];
		byte7 = charset[index++];
		byte6 = charset[index++];
		byte5 = charset[index++];
		byte4 = charset[index++];
		byte3 = charset[index++];
		byte2 = charset[index++];
		byte1 = charset[index++];

		fprintf(fd,"/* %03d (%d) */ %d,%d,%d,%d,%d,%d,%d,%d,		
			}
	
}

