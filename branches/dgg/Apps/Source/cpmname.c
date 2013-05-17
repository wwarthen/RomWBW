/* cpmname.c 5/21/2012 dwg - */

#include "stdio.h"
#include "stdlib.h"
#include "portab.h"
#include "memory.h"
#include "globals.h"
#include "cpmbind.h"
#include "applvers.h"
#include "infolist.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "diagnose.h"
#include "std.h"

#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */

extern cnamept1();

int line = 1;

char hexmap[] = "0123456789ABCDEF";

char * fmthexbyte(val, buf)
	unsigned char val;
	char * buf;
{
	buf[0] = hexmap[(val >> 4) & 0xF];
	buf[1] = hexmap[(val >> 0) & 0xF];
	buf[2] = '\0';
	
	return buf;
}

char * fmthexword(val, buf)
	unsigned int val;
	char * buf;
{
	buf[0] = hexmap[(val >> 12) & 0xF];
	buf[1] = hexmap[(val >> 8) & 0xF];
	buf[2] = hexmap[(val >> 4) & 0xF];
	buf[3] = hexmap[(val >> 0) & 0xF];
	buf[4] = '\0';
	
	return buf;
}

char * fmtbool(val)
	unsigned char val;
{
	return (val ? "True" : "False");
}

char * fmtenable(val)
	unsigned char val;
{
	return (val ? "Enabled" : "Disabled");
}

putscpm(p)
	char * p;
{
	while (*p != '$')
		putchar(*(p++));
}

pager()
{
	int i;

	line++;
	printf("\r\n");

	if(line >= 24)
	{
		printf("*** Press any key to continue...");
		while (bdos(6, 0xFF) == 0);
		putchar('\r');
		for (i = 0; i < 40; i++) {putchar(' ');}
		putchar('\r');
		line = 1;
	}
}

int main(argc,argv)
	int argc;
	char *argv[];
{
	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the HBIOS function         */
	
	printf("CPMNAME.COM %d/%d/%d v%d.%d.%d (%d)",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - Display System Configuration");
	pager();
	pager();
			
	ireghl = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;
	
	putscpm(pINFOLIST->banptr);
	pager();
	pager();

	hregbc = 0xF000;
	hregde = HIGHSEG;	
	diagnose();

	cnamept1(HIGHSEG);
}

/********************/
/* eof - ccpmname.c */
/********************/
