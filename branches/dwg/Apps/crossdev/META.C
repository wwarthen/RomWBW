/* meta.c 6/7/2012 dwg - view and edit the metadata */


#include "stdio.h"
#include "portab.h"
#include "globals.h"
#include "cpmbios.h"
#include "bioscall.h"
#include "cpmbdos.h"
#include "bdoscall.h"
#include "sectorio.h"
#include "diagnose.h"
#include "ctermcap.h"
#include "clogical.h"
#include "metadata.h"
#include "applvers.h"

#define METALINE	7
#define METACOL		0

/* Application Globals */

int bRunning;
int deflu;
int drive;
int logunit;
int numlu;



display()
{
	int i;

	/* Set Current Logical Unit */	
	luscur(drive,logunit);	

	/* Read the Prefix Sector */
	rdsector(drive,0,11,&metadata,0);

	crtlc(METALINE+0,METACOL);
	printf("metadata.signature = 0x%04x",metadata.signature);

	crtlc(METALINE+1,METACOL);
	printf("metadata.platform  = 0x%02x",metadata.platform);

	crtlc(METALINE+2,METACOL);
	printf("metadata.formatter = \"");
	for(i=0;i<8;i++) {
		printf("%c",metadata.formatter[i]);
	}			
	printf("\"");

	crtlc(METALINE+3,METACOL);
	printf("metadata.drive     = %c:",metadata.drive+'A');

	if(metadata.logunit != logunit) {
	   metadata.logunit  = logunit;	
	   metadata.update++;
	   wrsector(drive,0,11,&metadata);
	}

	crtlc(METALINE+4,METACOL);
	printf("metadata.logunit   = %d(rel0) of %d     ",metadata.logunit,numlu);

	crtlc(METALINE+5,METACOL);
	printf("metadata.writeprot = ");
	switch(metadata.writeprot) {
		case TRUE:	printf("TRUE ");	break;
		case FALSE:	printf("FALSE");	break;
		default:	printf("Unk!!");	break;
	}

	crtlc(METALINE+6,METACOL);
	printf("metadata.update    = %d",metadata.update);

	crtlc(METALINE+7,METACOL);
	printf("metadata.{ver}     = %d.%d.%d.%d",
		metadata.rmj,metadata.rmn,metadata.rup,metadata.rup);

	crtlc(METALINE+8,METACOL);
	printf("metadata.label     = \"");
	for(i=0;i<16;i++) {
		printf("%c",metadata.label[i]);
	}
	printf("\"");
	crtlc(METALINE+9,METACOL);
	printf("metadata.infloc    = 0x%04x",metadata.infloc);
	
	crtlc(METALINE+10,METACOL);
	printf("metadata.cpmloc    = 0x%04x",metadata.cpmloc);
	
	crtlc(METALINE+11,METACOL);
	printf("metadata.cpmend    = 0x%04x",metadata.cpmend);
	
	crtlc(METALINE+12,METACOL);
	printf("metadata.cpment    = 0x%04x",metadata.cpment);

}

int menu(state)
	int state;
{
	int retcode;
		
	crtlc(METALINE+14,METACOL);
	printf("                                       ");
	printf("                                       ");

	crtlc(METALINE+14,METACOL);
	
	printf("Options( ");
	
	if(0 < logunit) {
		printf(" -{prev lu}");
	}


	if(logunit < (numlu-1)) {
		printf(" +{next lu}");
	}
	
	if(TRUE == metadata.writeprot) {
		printf(" u{nprotect}"); 
	}
	
	if(FALSE == metadata.writeprot) {
		printf(" p{rotect}");
	}
	
	printf(" x{quit} ): ");
	
	dregbc = 1;
	bdoscall();

	retcode = TRUE;
	
	switch(drega) {
		case 'X':
		case 'x':
			retcode = FALSE;	break;	

		case '+':
			if(logunit < (numlu-1)) {
				logunit++;	
			} else {
				printf("%c",7);
			}
			break;
		
		case '-':
			if(0 < logunit) {
				logunit--;	
			} else {
				printf("%c",7);
			}
			break;

		case 'p':
			metadata.writeprot = TRUE;
			metadata.update++;
			wrsector(drive,0,11,&metadata,0);
			break;
		
		case 'u':
			metadata.writeprot = FALSE;
		    metadata.update++;
			wrsector(drive,0,11,&metadata,0);
			break;

		default:	printf("%c",7);	break;
	}

	return retcode;
}

main(argc,argv)
	int argc;
	char *argv[];
{
	crtinit();
	crtclr();
	crtlc(0,0);
		
	banner("META");

	dregbc = RETCURRDISK;
	bdoscall();
	drive = drega;

	numlu = lugnum(drive);
		

	deflu = lugcur(drive);		
	logunit = deflu;

	bRunning = TRUE;
	while(TRUE == bRunning) {	
		display();
		bRunning = menu(1);
	}

	luscur(drive,deflu);		
	crtlc(23,0);
}



