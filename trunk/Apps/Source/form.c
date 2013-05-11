/* form.c 8/21/2012 dwg - */


#define MAXDRIVE 8
#include "cpm80.h"
#include "cpmbdos.h"
#include "bdoscall.h"
#include "cpmappl.h"
#include "applvers.h"
#include "cnfgdata.h"
#include "syscfg.h"


#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */
#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */


struct SYSCFG * pSYSCFG = HIGHSEG;

#define FRMFLDS 2
#define FRSTLIN 6
#define VISCOL  3
#define VISSIZ  6
#define VALCOL  (VISCOL+VISSIZ+4)
#define VALSIZ  32

struct FORM {
	int visline;
	int viscol;
	int vissize;
	char visible[VISSIZ+1];
	int valline;
	int valcol;
	char value[VALSIZ+1];
} form[FRMFLDS] = { 
	{ FRSTLIN,   VISCOL, VISSIZ, "field1", FRSTLIN,   VALCOL, "default1" }, 
	{ FRSTLIN+1, VISCOL, VISSIZ, "field2", FRSTLIN+1, VALCOL, "default2" } 
};

																																																																						
int main(argc,argv)
	int argc;
	char *argv[];
{
	int i,j;
	char buffer[VALSIZ+2];
		
	hregbc = GETSYSCFG;				/* function = Get System Config      */
    hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */
	pSYSCFG = HIGHSEG;
	
	crtinit(pSYSCFG->cnfgdata.termtype);
	crtclr();
	crtlc(0,0);

	banner("FORM");

	for(i=0;i<FRMFLDS;i++) {
		crtlc(form[i].visline,form[i].viscol);
		printf("%s",form[i].visible);
		crtlc(form[i].valline,form[i].valcol);
		for(j=0;j<strlen(form[i].value);j++) {
			printf("_");
		}	
		crtlc(form[i].valline,form[i].valcol);
		printf("%s",form[i].value);
	}

	for(i=0;i<FRMFLDS;i++) {
		crtlc(form[i].valline,form[i].valcol);

		memset(buffer,0,sizeof(buffer));
		dregbc = 10;			/* READ CONSOLE BUFFER */
		dregde = &buffer;
		buffer[0] = VALSIZ-1;
		buffer[1] = 0;
		bdoscall();
		if(0 < buffer[1]) {
			memset(form[i].value,0,VALSIZ);
			strcpy(form[i].value,buffer[2]);		
		}
	}


	for(i=0;i<FRMFLDS;i++) {

		crtlc(form[i].visline,form[i].viscol);
		printf("%s",form[i].visible);

		crtlc(form[i].valline,form[i].valcol);
		for(j=0;j<strlen(form[i].value);j++) {
			printf(" ");
		}	

		crtlc(form[i].valline,form[i].valcol);
		printf("%s",form[i].value);
	}



}

/**************************************************************************/

