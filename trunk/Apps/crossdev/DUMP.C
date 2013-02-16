/* dump.c 7/11/2012 dwg - 

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
#include "cvt2inc.h"
	
main(argc,argv)
	int argc;
	char *argv[];
{
	int i,j;
	int offset;
	int result;
	unsigned char byte;
	unsigned char sector[128];
	char name[32];
	

	FILE * fd;

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

	printf("Dumping %s\n\n",argv[1]);

	offset = 0;
	result = fread(sector,sizeof(sector),1,fd);
	while(0 < result) {

		sprintf(name,"sect%04x.h",offset);
		cvt2h(sector,sizeof(sector),name);
		sprintf(name,"sect%04x.inc",offset);
		cvt2inc(sector,sizeof(sector),name);
		
		for(i=0;i<8;i++) {
			printf("%04x: ",offset);


			offset += 16;
			for(j=0;j<16;j++) {
				printf("%02x ",sector[(i*8)+j]);
			}
			printf("  ");
			for(j=0;j<16;j++) {
				byte = sector[(i*8)+j];
				if(1 == visible[byte]) {
					printf("%c",byte);
				} else {
					printf(".");
				}
			}
			printf("\n");
		}
		printf("\n");
		result = fread(sector,sizeof(sector),1,fd);
	}	
	fclose(fd);	
	
	exit(0);
}
