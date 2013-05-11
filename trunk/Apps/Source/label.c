/* label.c 67/10/2012 dwg - */

#include "stdio.h"
#include "cpmbios.h"
#include "bioscall.h"
#include "cpmbdos.h"
#include "bdoscall.h"
#include "metadata.h"
#include "banner.h"

struct FCB * pPRIFCB;
struct FCB * pSECFCB;
struct DPH * pDPH;
struct DPB * pDPB;

testdrive(drive)
	int drive;
{
	ireghl = pSELDSK;
	iregbc = drive;
	bioscall();
	pDPH = ireghl;
	pDPB = pDPH->dpb;
	if(0 == pDPB->off) {
		printf("Sorry Drive %c: has no prefix area and cannot be labeled",
				drive+'A');
		exit(1);
	}

}

interactive(drive)
	int drive;
{
	int i;
	
	struct {
		char size;
		char len;
		char data[16];
	} rdcons;

	testdrive(drive);	
	ireghl = pGETLU;
	iregbc = drive;
	bioscall(); 
	if(1 == irega) {
		printf("interactive(%d) says drive %c: can't have label",drive,drive);
		printf("%c",7);
		exit(1);
	
	}
	rdsector(drive,0,11,&metadata,0);
	printf("Old label = ");	
	for(i=0;i<16;i++) {
 		printf("%c",metadata.label[i]);
	}
	
	printf("\nNew label = ");
	rdcons.size=16;
	rdcons.len =0;
	dregbc = RDCONBUF;
	dregde = &rdcons;
	bdoscall();
	
	if(0 < rdcons.len) {
		memset(metadata.label,' ',16);
		memcpy(metadata.label,rdcons.data,rdcons.len);
		wrsector(drive,0,11,&metadata,0);
	}

}

noninteractive(drive,label)
	int drive;
	char * label;
{
	int i;

	testdrive(drive);
	
	rdsector(drive,0,11,&metadata,0);
	memset(metadata.label,' ',16);
	for(i=0;i<strlen(label);i++) {
		metadata.label[i] = label[i];
	}
	wrsector(drive,0,11,&metadata,0); 
}

main(argc,argv)
	int argc;
	char *argv[];
{
	int i;
	int drive;
	char szDrive[3];
	
	sbanner("LABEL.COM");

	pPRIFCB = 0x5c;

	switch(argc) {
		case 1:
			dregbc = RETCURRDISK;
			bdoscall();
			drive = drega;
			interactive(drive);
			break;
		case 2:
			if(2 == strlen(argv[1])) {
				strcpy(szDrive,argv[1]);
				if(':' == szDrive[1]) {
					interactive(pPRIFCB->drive-1);
					exit(0);
				}
			}
			break;
		default:
			noninteractive(pPRIFCB->drive-1,0x85);			
			break;
	}
	exit(0);
}
