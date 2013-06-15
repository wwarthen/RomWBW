/* multifmt.c 6/12/2012 dwg - */

/* 
 *
 * The purpose of this program is to prepare a new mass storage device
 * for use with the CP/M-80 Operating System with the RomWBW BIOS.
 *
 * Each Logical Unit has a prefix sector which must be initialized and
 * a set of directory sectors that must be cleared to E5's in order that
 * the directory entries wil be cleared for subsequent use.
 *
 * The Logical Units feature is implemented through the use of a DPH
 * extention that contains a signature word, a "current LU" word, and
 * a "number of LU's" word. The "number of LU's" word is assembled in
 * based on the configurtion files present at system build time.
 *
 * The configuration of the LU feature has been managed by poking values
 * into the "current" and "number of LU's" fields. As of the 2.0 BIOS,
 * the LU feature is now managed via OEM BIOS calls to GETLU and SETLU.
 *
 * The following list of concepts contains the methods by which needed
 * information can be accessed under the new architecture.
 *
 * To begin with, questions about disk drives can be answered through
 * sequences of operations as described here.
 *
 * The first operation is to call GETLU and pass it a drive number. If
 * the return code is 0, this means the drive exists. If a 1 is returned,
 * this indicates an invalid drive number.
 *
 * Once you know that a drive number is valid, the next thing to know is
 * the meaning of the Device/Unit returned by the call. The device numbers
 * are hard coded in the STD.ASM, and derived from that a STD.H file which
 * can be included into C programs. The known devices include DEV_MD,
 * DEV_FD, DEV_IDE, DEV_PPIDE... The high nybble of the byte contains the
 * device code, and the low nybble contains the unit number. The RAM disk
 * and ROM disk are both DEV_MD devices. They just have different unit
 * numbers. RAM and ROM drives do not have reserved tracks, and as well do
 * not have a prefix sector. Because of this, there is no space to write a
 * system image, and therefore are not usable for booting.
 *
 * The next more sophisticated storage device is the floppy disk. It does
 * have reserved tracks and a prefix sector and can therefore have a system
 * image written to it. Floppies, due to there size do not support "logical
 * unit extentions".
 *
 * Things become much more interesting once you have a media adapter such
 * as an IDE to compact flash adapter. Using a PPIDE miniboard attached
 * to the parallel port, a media adapter may be attached, and a storage
 * device as well, such as a CF chip.
 *
 * Compact Flash chips are generally many times larger than a maximum size
 * of a CP/M-80 disk drive. The Logical Unit feature takes advatage of this
 * by dividing the available space into a contiguous collection of 9MB slices
 * which we describe as "logical units". The first one is numbered from zero
 * and additional slices are numbered upwards from there.
 *
 * The maximum number of logical units supported on a single chip is 232.
 *
 * The RomWBW BIOS maps a device such as a PPIDE into four CP/M drives. By
 * default, the drives are assigned to logical units 0 to 3. When using the
 * DM_PPIDE configuration option, the four PPIDE drives are A: B: C: & D:.
 *
 * The A: drive is assigned to logical unit 0. The B: drive is assigned to
 * logical unit 1. The C: drive is assigned to logical unit 2, and the D:
 * drive is assigned to logical unit 3. This gives the appearance of having
 * four individual 8MB drives.
 *
 * In order to make all the space on the media available, you can change
 * the mapping of each of the drives through the use of the "MAP" program,
 * or by making system calls to the BIOS function SETLU. It is common to
 * lelave the A: drive mapped to logical unit 0. Then the A: drive can be
 * backed up through a simple copy operation dto any of the mappable logical
 * units on the media. Here is the sequence of operations used to back up 
 * the A: drive onto logical unit 8. (arbitrary)
 *
 * map d: 8
 * clrdir d:
 * pip d:=a:*.*
 * label d: 6/1/2012-12:30
 *
 * this operation creates a complete backup of the A: drive (LU0) onto LU8,
 * and labels the drive for future reference.
 *
 *
 * The problem this programs solves is how to prepare a large media device a few
 * logical units, or an entire device, possible having hundreds of logical
 * units.
 *
 * The prefix sector of each logical unit has a label, and a write protect
 * field. Once the logical united is protected, it makes it harder to 
 * destroy your data. As powerful as the MULTIFMT program is, if operated
 * incorrectly, it can format hundreds of logical units in several minutes
 * and potentially destroy a lot of your data and programs. Care is required.
 *
 * The program begins by asking for a starting and ending logical unit
 * number which provides a range within which to operate. Within that range
 * individual logical units can be protected or not. The program also asks
 * if you would like to override all the protected logical units, and thereby
 * format the entire device, regardless of prior contents.
 *
 * It should only be necessary to run multifmt once to create the prefixes
 * and clear the directories. The clrdir program can be used ad hoc to clear
 * individual logical units as needed.
 * 
 * Now that a this is understood, the code of the program will make a lot
 * more sense. The main function calls the gather funtion that queries the
 * for constraints, then it call the logical formatter to deal with high
 * level issues like how many logical units...
 * The logical formatter calls the physical formatter to actually get the
 * work done and make changes to the target media. Because of this structure,
 * it is possible to operate the program in a sort of demo mode by disabling
 * the operation of the physical format function.
 *
 */
 
#include "portab.h"
#include "globals.h"
#include "stdio.h"
#include "stdlib.h"
#include "std.h"
#include "memory.h"
#include "cpmbios.h"
#include "bioscall.h"
#include "cpmbdos.h"
#include "bdoscall.h"
#include "sectorio.h"
#include "infolist.h"
#include "metadata.h"
#include "clogical.h"
#include "applvers.h"
#include "diagnose.h"
#include "cnfgdata.h"
#include "syscfg.h"

#define BDOS    5			/* memory address of BDOS invocation */
#define HIGHSEG 0x0C000		/* memory address of system  config  */

#define GETSYSCFG 0x0F000	/* HBIOS function for Get System Configuration */


struct DPB * pDPB;	/* a pointer to a disk parameter block  */
struct DPH * pDPH;	/* a pointer to a disk parameter header */

struct SYSCFG * pSYSCFG;	/* a pointer to the system configuration data */

int gDrvNum;	/* The global drive number, A:=0, B:=1...                 */
int gDevUnit;	/* The globals drive's device type and unit               */
int gDefLU;		/* The global storage location for the default LU         */
int gCurLU;		/* The global storage location for the current LU         */
int gNumLU;		/* The global storage location for the number of LUs      */
int gStatus;
int gRetcode;
int g1st;		/* The global storage location for the first LU to format */
int gLast;		/* The global storage location for the  last LU to format */
int gOverAll;	/* The global boolean indicating protection overrides     */
char gTT;		/* Terminal Type                                          */

unsigned char e5buffer[128];	/* a buffer full of empty dir entries     */


dispattr(fg)
	char * fg;
{
	printf("%c[%sm",27,fg);
}


clrline()
{
	if(0 < gTT) {
		crtlc(2,0);
	}
	printf("\r                                     ");
	printf("                                     \r");
}

/* The purpose of this routine is to access the BIOS GETDSK function
	and determine the device, unit, current logical unit, and number
	of logical units present on the media.                           */
	
getinfo(drnum)
{
	ireghl = pGETLU;
	iregbc= drnum;
	bioscall();
	gStatus  = irega;	/* 0=ok, 1=invdrv */
	gDevUnit = iregbc;
	gCurLU   = iregde;
	gNumLU   = ireghl;
}


clrdir(line,col)
	int line;
	int col;
{
	int sector;
	int	sectors;
		
	if(0 == gTT)	printf("clrdir(%d) ",gDrvNum);

	memset(e5buffer,0x0e5,sizeof(e5buffer));
	
	ireghl = pSELDSK;
	iregbc = gDrvNum;
	iregde = 0;
	bioscall();
	pDPH   = ireghl;
	pDPB   = pDPH->dpb;

	sectors = (pDPB->drm+1)/4;
	wrsector(gDrvNum,pDPB->off,0,e5buffer,0);
	for(sector=1;sector<sectors;sector++) {

		if(-1 != line) {
			crtlc(line,col-1);
			printf("%d",sectors-sector);
		}

		wrsector(gDrvNum,pDPB->off,sector,e5buffer,1);
	}
	
	
	
}

clrmeta(lu,line,col)
	int lu;
	int line;
	int col;
{

	if(0 == gTT) printf("clrmeta(%d) ",lu);
	else {
		crtlc(line,col-1);
		printf("met");
	}

	rdsector(gDrvNum,0,11,&metadata,0);
	metadata.signature = 0x0a55a;
	metadata.platform  = pSYSCFG->cnfgdata.platform;

	memcpy(metadata.formatter,"multifmt",8);
	metadata.drive     = gDrvNum;
	metadata.logunit   = lu;
	metadata.writeprot = FALSE;
	metadata.rmj = A_RMJ;
	metadata.rmn = A_RMN;
	metadata.rup = A_RUP;
	metadata.rtp = A_RTP;
	memcpy(metadata.label,"[multiformatted]",16);
	metadata.term = '$';
	metadata.update = 0;
	wrsector(gDrvNum,0,11,&metadata,0);
}

/* The purpose of the physical format routine is to do last minute
	checks on logical unit protection status, and call the actual
	routines that initialize the metadata and clear the directory */

physfmt(lu)
	int lu;
{
	int line,col;
	
	rdsector(gDrvNum,0,11,&metadata,0);
	if(TRUE == metadata.writeprot) {
		if(gTT == 0) {
			printf("LU%d is protected,  ",lu);
		}
		if(FALSE == gOverAll) {
				if(0==gTT) printf("Override is not enabled, ");
				return FALSE;		
		}		
		if(gTT == 0) printf("Override is enabled, ");	
	}

	/* LU is not protected or override is enabled */

	if(0==gTT) { 
		printf("Formatting LU# %d\r",lu);
		clrmeta(lu,-1,-1);
		clrdir(-1,-1);
	} else {
		/* Produce formatted progress display */

		line = lu / 16;
		crtlc(26-16-4+line,0);
		printf("%d...",lu & 0xf0);

		col  = lu & 15;
		clrmeta(lu,24-16-2+line,((80-64)/2)+(col*4)+1);
		clrdir(    24-16-2+line,((80-64)/2)+(col*4)+1);

		crtlc(24-16-2+line,((80-64)/2)+(col*4));
		printf(" OK");
	}
	
	return  TRUE;
}


/* The purpose of the logical formatting routine is to implement the
	main format loop that traverses the range of logical units, and
	calls tyhe physical format routine above.						*/

lformat()
{
	int index;


	if(0 != gTT) {
		for(index=0;index<16;index++) {
			crtlc(24-16-2-2,((80-64)/2)+(index*4));
			printf("+%d",index);
		}
		for(index=0;index<16;index++) {
			crtlc(24-16-2-1,((80-64)/2)+(index*4));
			printf("---");
		}
	}

	gDefLU = lugcur(gDrvNum);
	for(index=g1st;index<=gLast;index++) {
		luscur(gDrvNum,index);		               
		rdsector(gDrvNum,0,11,&metadata,0);	
		if(TRUE == metadata.writeprot) {
			if(TRUE == gOverAll) {
				physfmt(index);
			}
		} else {
			physfmt(index);	
		}
	}
	luscur(gDrvNum,gDefLU);
}

/*	The purpose of the dispinfo routie is to display the formatted
	parameters gathered in the previous routine and ask the user
	for permission to proceed with the formatting on that basis.   */
	
int dispinfo()
{
	if(1 == gRetcode) {
		return FAILURE;
	}
	
	if(0 == gNumLU) {
		return FAILURE;
	}

	printf("\nDrive %c:, ",gDrvNum+'A');
	printf("Current LU is %d, ",gCurLU);
	printf("Number of LU's is %d, ",gNumLU);
	switch((gDevUnit>>8) & 0xf0) {
		case DEV_IDE:
			printf("Drive is IDE");
			break;
		case DEV_PPIDE:
			printf("Drive is PPIDE");
			break;
		default:
			printf("Drive is Unknown!!(%x)",gDevUnit);
			break;
		
	}
	clrline();
	printf("Would you like to format the logical units on this drive(Y/n)?");
	
	dregbc = 1;
	bdoscall();
	switch(drega) {
		case 'Y':
		case 'y':													
			return TRUE;
		default:
			return FALSE;
	}
}


/* The purpose of the gather routine is to have a dialog with the user
   end obtain the range of logical units to be formatted and the choice
   of whether logical unit protection will be overridden in the process. */
   
gather()
{

	char szTemp[128];

	clrline();
	g1st = 1;	

	printf("Please enter first logical unit to format 0-%d (%d):",
			gNumLU-1,g1st);
	gets(szTemp);
	if(0 < strlen(szTemp)) {
		g1st = atoi(szTemp);
	}

	clrline();
	gLast = gNumLU-1;
	printf("Please enter last logical unit to format 0-%d (%d):",
			gNumLU-1,gLast);
	gets(szTemp);
	if(0 < strlen(szTemp)) {
		gLast = atoi(szTemp);
	}

	clrline();
	gOverAll = FALSE;	
	printf("Do you want to override all protected logical units (Y/n): ");
	dregbc = 1;
	bdoscall();
	if('Y' == drega) {
		clrline();
		printf("Do you really want to DESTROY all logical units (D/n): ");
		dregbc = 1;
		bdoscall();
		if('D' == drega) {
			gOverAll = TRUE;
		}
	} else {
		printf("\n");
	}

}



main(argc,argv)
	int argc;
	char *argv[];
{	
	int retcode;
	struct INFOLIST * pINFOLIST;

	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = HIGHSEG;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the NBIOS function         */

	pSYSCFG = HIGHSEG;
	
/*	printf("TT is %d\n",pSYSCFG->cnfgdata.termtype); */

	gTT = pSYSCFG->cnfgdata.termtype;
	crtinit(gTT);
	if(0 < gTT) {
		crtclr();
		crtlc(0,0);
	}

	printf("MULTIFMT.COM %d/%d/%d v%d.%d.%d.%d",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - Prepare new mass storage media for use");

	ireghl = pGETINFO;
	bioscall();
	pINFOLIST = ireghl;

	dregbc = RETCURRDISK;
	bdoscall();
	gDrvNum = drega;

	getinfo(gDrvNum);
	retcode = dispinfo();	
	if(FALSE == retcode) {
		printf("\nFormat cancelled at user's request");
		exit(1);
	}
	gather();
	lformat();
}

/********************/
/* eof - multifmt.c */