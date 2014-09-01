/* monitor.c 7/22/2012 dwg - look around, see what's goin down */

#include "stdio.h"
#include "asmiface.h"
#include "ctermcap.h"
#include "cnfgdata.h"
#include "diagnose.h"
#include "syscfg.h"

struct SYSCFG * pSYSCFG;

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

display(sector)
	char * sector;
{
	int i,j;
	int offset;
	unsigned char byte;

	offset = 0;	
	for(i=0;i<8;i++) {
		printf("%04x: ",sector+offset);
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
}


#define HIGHSEG 0x0c000
#define GETSYSCFG 0x0f000

main()
{
	char bRun;
	unsigned int offset;
	struct SYSCFG * pSYSCFG;
	
	pSYSCFG = HIGHSEG;
	
	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();crtlc(0,0);
	printf("monitor.c 7/22/2012 dwg - view contents of memory");	
	offset = HIGHSEG;	
	bRun = 1;
	
	while(1 == bRun) {
		crtlc(3,0);
		display(offset);
		display(offset+128);
  printf(
  "Options: 0(0x0000) 1(0x1000) 2(0x2000)  3(0x3000) 4(0x4000) 5(0x5000)\n");
  printf(
  "         6(0x6000) 7(0x7000) 8(0x8000)  9(0x9000) a(0xa000) b(0xb000)\n");
  printf(
  "         c(syscfg) n(ext)    p(revious) q(uit) ?");		
		
		asmif(5,1,00);
		printf("%c",0x0d);
		switch(xrega) {
			case '0':	offset  = 0x00000;	break;
			case '1':	offset  = 0x01000;	break;
			case '2':	offset  = 0x02000;	break;
			case '3':	offset  = 0x03000;	break;
			case '4':	offset  = 0x04000;	break;
			case '5':	offset  = 0x05000;	break;
			case '6':	offset  = 0x06000;	break;
			case '7':	offset  = 0x07000;	break;
			case '8':	offset  = 0x08000;	break;
			case '9':	offset  = 0x09000;	break;
			case 'a':	offset  = 0x0a000;	break;
			case 'b':	offset  = 0x0b000;	break;
			case 'd':	offset  = 0x0d000;	break;
			case 'c':	offset  = 0x0c000;	break;
			case 'n':	offset += 2*128;	break;
			case 'p':	offset -= 2*128;	break;
			case 'x':
			case 'q':	bRun    = 0;	break;
		}
	}
}
