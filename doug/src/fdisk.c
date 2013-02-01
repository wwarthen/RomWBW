/***********************************************************/
/* fdisk.c 5/12/2011 dwg - fdisk in sdcc for cp/m-80 v2.2c */
/* written by douglas w goodall for N8VEM community use    */
/***********************************************************/

/*
 * This is a first  cut at a partition editor for CP/M-80 v2.2c
 * and perhaps CP/M-80 v3,  for the SBC V1 and V2 and perhaps
 * the N8VEM Home Computer.
 *
 * There were two approaches to this program. Dealing with sector
 * numbers or dealing with track numbers. Because of the eight bit 
 * nature of the processor, dealing with track numbers was much
 * better for the code generation. The track numbers can be changed
 * back into LBA sector numbers later on if desired.
 *
 * The only problem I forsee would be if we encountered a partition
 * table that already had LBA offsets that were no on track boundaries.
 * When I worked at DRI, we adjusted the partitions to start and stop 
 * on track boundaries. Compatibility with existing drive partitions
 * sounds nice but is not my highest priority. /s douglas goodall
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "portab.h"
#ifndef __GNUC__
#include "cpmbdos.h"
#include "cprintf.h"
#endif

/* 
 *  1MB = 1,048,576 bytes
 * 32MB = 1,048,576 * 32 = 33,554,432
 *
 * physical sector  is 512 bytes
 * physical  track  is 256 sectors = 131,072
 * physical  drive  is 33,554,432 
 * physical tracks are 33,554,432 / 131,072 = 256 
 * physical tracks per physical drive are 256
 *
 * logical  sector is 128 bytes
 * logical   track is 256 sectors (aka )
 * logical   drive is 8192KB (aka 8192KB/32KB = 256 logical tracks)
 *
 * 
 * 8,388,608 bytes is a logical drive
 *   131,072 bytes is a physical track
 * 8,388,608 / 131,072 = 64 physical tracks per logical drive 
 *
 * One byte (0-255) will just hold the number of physical tracks needing
 * to be shared amoung up to four logical drives.
 *
 * physical track    0 - partition sector and second-stage loader if needed
 * physical tracks   1 -  64 = 8.0MB partition ( 64 * 131,072 = 8,388,608 )
 * physical tracks  65 - 128 = 8.0MB partition ( 64 * 131,072 = 8,388,608 )
 * physical tracks 129 - 192 = 8.0MB partition ( 64 * 131,072 = 8,388,608 )
 * physical tracks 193 - 255 = 7.9MB partition ( 63 * 131,072 = 8,257,536 )
 *
 */

#define MAX_PARTS 4
#define TRKS_PER_PHY_DRV 256
#define TRKS_PER_LOG_DRV  64 	/* 256 sectors * 512 = 128k */ 

#define SAFESTRING 80	/* make large enough to avoid accidental overrun     */

#define U8 unsigned char

struct PART_TABLE {	/* in-memory instance of partition table             */
	U8 start;	/* starting track of a partition                     */
	U8  end;	/*  ending  track of a partition                     */
} pt[MAX_PARTS] = { { 0, 0 }, { 0, 0 }, { 0, 0 }, { 0, 0 } };

U8 bRunning;		/* scratchpad used used by the main loop             */
U8 end;			/* scratchpad used to hold ending track of a part    */
U8 Index;		/* scratchpad used as index for for loops            */
U8 NumParts;		/* scratchpad to hold the current number of parts    */
U8 LastEnd;		/* scratchpad to hold the last track allocated       */
U8 NewEnd;		/* scratchpad to hold the proposed ending track      */
U8 NewMax;		/* scratchpad to hold the proposed max part size     */
U8 NewSize;		/* scratchpad to hold the decided  new part size     */
U8 NewStart;		/* scratchpad to hold the decided  starting track    */
U8 start;		/* scratchpad to hold the starting track of a part   */
U8 Avail;		/* scratchpad to hold the remaining avialable tracks */

char szChoice[SAFESTRING];	/* string used to receive keystrokes */
char szTemp[SAFESTRING];	/* string used for general purposes  */

/* THESE ARE USED BY THE LIBRARY ROUTINES */
#ifndef __GNUC__
char getchar(void)
{
        struct BDOSCALL cread = { C_READ, { (unsigned int)0 } };
        return cpmbdos(&cread);
}
void outchar(char c)
{
        struct BDOSCALL cwrite = { C_WRITE, { (unsigned int)c } };
        cpmbdos(&cwrite);
}
#endif

void display_menu(void)
{
	if(NumParts < MAX_PARTS) {
		if(0 < Avail) {
			printf("a - add partition #%d\n",NumParts+1);
		}
	}
	if(0 < NumParts) {
		printf("d - delete partition #%d\n",NumParts);
	}
	if(1 < NumParts) {
		printf("D - delete all partitions, 1 - %d\n",NumParts);
	}
	if(0 == NumParts) {
		printf("A - create all 8MB partitions\n");
	}
	printf("q - quit fdisk\n\n");
}

char  query(char *str)
{
	printf("%s",str);
	gets(szTemp);
	if('Y' == szTemp[0]) {
	  return TRUE;
	} else {
	  return FALSE;
	}
}

void delete(void)
{
	if(0 < NumParts) {
		if(TRUE == query("Delete partition(Y/n)?")) {
			pt[NumParts-1].start = 0;
			pt[NumParts-1].end   = 0;
		}
	}
}

void deleteall(void)
{
	if(0 < NumParts) {
		if(TRUE == query("Delete all partitions(Y/n)?")) {
			for(Index=0;Index<MAX_PARTS;Index++) {
				pt[Index].start = 0;
				pt[Index].end = 0;
			}
		}
	}
}

U8 request(char *szPrompt)
{
	printf("%s",szPrompt);
	gets(szTemp);
	return(atoi(szTemp));
}

U8 request2(char *szPrompt,U8 Default)
{
	printf(szPrompt,Default);
	gets(szTemp);
#ifdef __GNUC__
	if(0 == strlen(szTemp)) return(Default);
#else
        if(1 == strlen(szTemp)) return(Default);
#endif

	return(atoi(szTemp));
}

U8 smaller(U8 a,U8 b)
{
        if(a<b) return a;
        else    return b;
}

void all(void)
{
	Avail = TRKS_PER_PHY_DRV-1;
	LastEnd = 0;

	for(Index=0;Index<MAX_PARTS;Index++) {
	  if(0 < Avail) {
		NewStart = LastEnd + 1;
		NewSize  = smaller(Avail,TRKS_PER_LOG_DRV);
		NewEnd   = NewStart + NewSize - 1;
              pt[Index].start = NewStart;
              pt[Index].end   = NewEnd;
	      LastEnd     = NewEnd;
	      Avail -= NewSize;
	  }
	}
}

void add(void)
{
	NewStart = LastEnd + 1;
	NewMax   = smaller(TRKS_PER_LOG_DRV,Avail);
	NewSize  = request2("Number of Tracks (Max %d)? ",NewMax);
	pt[NumParts].start = LastEnd+1;
	pt[NumParts].end   = NewStart + NewSize - 1;
}

void view(void)
{
	NumParts = 0;
	LastEnd = 0;

        for(Index=0;Index<MAX_PARTS;Index++) {
		start = pt[Index].start;
		end = pt[Index].end;
		
                if(0 < (start) ) {
                        NumParts++;
                        LastEnd = end;
                }	
        }
	Avail = TRKS_PER_PHY_DRV - LastEnd - 1;
	
	printf("N8VEM Partition Editor by Douglas Goodall\n\n");
	printf("  Available tracks are %d\n\n",Avail);
	NumParts = 0;
	for(Index=0;Index<MAX_PARTS;Index++) {
	  start = pt[Index].start;
	  end   = pt[Index].end;

	  if(0 != end) {
	    printf("Part#%d  ",Index+1);
	    printf("Start %6d (0x%05X), ",start,start);
	    printf("End   %6d (0X%05X)  ",end,end);
	    printf("Size  %6d (0x%05X) ", end-start+1,end-start+1);
	    printf("\n");
	    NumParts++;
	  }
	}
	printf("\n");
}

int main()
{

/*	FILE * fd = fopen("parttabl.bin","r");
	if(NULL != fd) {
		fread(&pt,1,sizeof(pt),fd);
		fclose(fd);
	} else {
		memset(&pt,0,(int)sizeof(pt));
	}
*/

	bRunning = 1;
	while(1 == bRunning) {
                view();
                display_menu();
		gets(szChoice);
		switch(szChoice[0]) {
			case 'a': 	add();		break;
			case 'd':	delete();	break;
			case 'D':	deleteall();	break;
			case 'q':	bRunning = 0;	break;
			case 'A':	all();		break;
		}
	}

/*
	FILE * fd2 = fopen("parttabl.bin","w");
	fwrite(&pt,1,sizeof(pt),fd2);
	fclose(fd2);
*/

	return (EXIT_SUCCESS);
}

