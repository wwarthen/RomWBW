/* termtype.c 7/21/2012 dwg - */

#include "stdio.h"
#include "applvers.h"
#include "infolist.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "diagnose.h"
#include "asmiface.h"
#include "cpmbdos.h"
#include "cpmbios.h"

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */
#define PUTSYSCFG 0x0F100	/* HBIOS function for Put System Configuration */

struct SYSCFG * pSYSCFG = HIGHSEG;

#define TTY 0
#define ANSI 1
#define WYSE 2
#define VT52 3

char bRun = 1;
char c;
char newtt = -1;
char tt;
int i;

main(argc,argv)
	int argc;
	char *argv[];
{
	hregbc = GETSYSCFG;				/* function = Get System Config */
	hregde = HIGHSEG;				/* addr of dest (must be high)  */
	diagnose();						/* invoke the HBIOS function    */

	for(i=0;i<25;i++) printf("\n");

	printf(
	 "TERMTYPE.COM %d/%d/%d %d.%d.%d.%d dwg - Display/Change Terminal Type\n",
	 A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	
	while(1 == bRun) {
		printf("\nThe Terminal Type is ");
		tt = pSYSCFG->cnfgdata.termtype;
		switch(tt) {
			case 0:		
				printf(" TTY, Options: a(nsi), w(yse), v(t52), q(uit) ?");
				break;
			case 1: 	
				printf("ANSI, Options: t(ty),  w(yse), v(t52), q(uit) ?");
				break;
			case 2:		
				printf("WYSE, Options: t(ty),  a(nsi), v(t52), q(uit) ?");
				break;
			case 3:  	
				printf("VT52, Options: t(ty),  a(nsi), w(yse), q(uit) ?");
				break;
			default:	
				printf("Unknown, Options: ");
				printf("t(ty),  a(nsi), w(yse), v(t52), q(uit) ?");
				break;		

		};
			
	
		asmif(BDOS,1,0,0);
		c = xrega;

		if('q' == c) {
			bRun = 0;
		}
		if('x' == c) {
			bRun = 0;
		}
		if('Q' == c) {
			bRun = 0;
		}
		if('X' == c) {
			bRun = 0;

		}
		
		switch(tt) {
			case TTY: 
				switch(c) {
					case 'a':	
					case 'A':   newtt=ANSI;	break;
					case 'w':	
					case 'W':	newtt=WYSE;	break;
					case 'v':	
					case 'V':	newtt=VT52;	break;
				};
				break;
			case ANSI:
				switch(c) {
					case 't':	
					case 'T':	newtt=TTY;	break;
					case 'w':	
					case 'W':	newtt=WYSE;	break;
					case 'v':	
					case 'V':	newtt=VT52;	break;
				};
				break;
			case WYSE:
				switch(c) {
					case 't':	
					case 'T':	newtt=TTY;	break;
					case 'a':	
					case 'A':	newtt=ANSI;	break;
					case 'v':	
					case 'V':	newtt=VT52;	break;
				};
				break;
			case VT52:
				switch(c) {
					case 't':	
					case 'T':	newtt=TTY;	break;
					case 'a':	
					case 'A':	newtt=ANSI;	break;
					case 'w':	
					case 'W':	newtt=WYSE;	break;
				};
				break;
			default:	
				printf("%c",7);
				break;	
		}

		if(255 != newtt) {
			pSYSCFG->cnfgdata.termtype = newtt;
			hregbc = PUTSYSCFG;
			hregde = HIGHSEG;
			diagnose();
		}



	}
	
}

