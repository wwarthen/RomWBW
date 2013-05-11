/* convert.c 7/11/2012 dwg - 

	The purpose of this program is similar to the CP/M dump program
	except that in addition to the normal hexadecimal bytes, a field
	of ascii bytes to the right are displayed as well.

*/

#include "stdio.h"


char visible[256] = {
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* 00 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* 10 */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	/* 20 */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	/* 30 */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	/* 40 */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	/* 50 */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,	/* 60 */
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,	/* 70 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* 80 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* 90 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* A0 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* B0 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* C0 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* D0 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,	/* E0 */
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 	/* F0 */
};

#include "cvt2h.h"

unsigned char sector[32767];
	
main(argc,argv)
	int argc;
	char *argv[];
{
	int i,j;
	int offset;
	int result;
	unsigned char byte;
	char name[32];
	

	FILE * fd;

	for(i=0;i<sizeof(sector);i++) sector[i] = 0;
	
	banner("DUMP.COM");

/*	cvt2h(0x0100,12*1024,"dumpcomh.h");  */

		
	if(1 == argc) {
		printf("Sorry, no input file specified");
		exit(1);
	}

	fd = fopen(argv[1],"r");
	if(NULL == fd) {
		printf("Sorry, cannot open input file");
		exit(1);
	}

	printf("Converting %s\n\n",argv[1]);

	result = fread(sector,32767,1,fd);

	for(i=32767;i>0;i--) {
		if(sector[i] != 0) break;
	}

	sprintf(name,"sect%04x.h",0);
	cvt2h(sector,i,name);
	fclose(fd);	
	
	exit(0);
}
