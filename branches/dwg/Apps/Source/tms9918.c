/* tms9918.c 9/12/2012 dwg - information from TI Docs       */
/* http://www1.cs.columbia.edu/~sedwards/papers/TMS9918.pdf */


/* TMS9918 Modes:

	Graphics I
		Graphics Mode I provides 256x192 pixel display for generating 
		pattern graphics in 15 colors plus transparent.
			
	Graphics II
		Graphics mode II is an enhancement of Graphics Mode I, allowing
		it to generate more complex color and pattern displays.
		
	Multicolor
		The Muylticolor mode provides an unrestricted 64x48 
		color-dot display employing 15 colors plus transparent.
		
	Text Mode
		The Text Mode provides twenty-four 40-character in two colors
		and is intended to maximize the capacity of the TV screen to
		display alphanumeric characters. (24 lines of forty blocks (each 8x8).

*/

#include "applvers.h"
#include "n8chars.h"

/*
#define DEBUG 
*/

#define WIDTH 37
#define HEIGHT 24
#define GUTTER 3

#define BASE 128
#define DATAP (BASE+24)
#define CMDP (BASE+25)

#define WO_R0
#define WOR0B6

#define VDP_TRANSPARENT  0
#define VDP_BLACK        1
#define VDP_MED_GREEN    2
#define VDP_LGREEN  3
#define VDP_DBLUE    4
#define VDP_LBLUE   5
#define VDP_DRED     6
#define VDP_CYAN         7
#define VDP_MRED      8
#define VDP_LRED    9
#define VDP_DYELLOW  10
#define VDP_LYELLOW 11
#define VDP_DGREEN   12
#define VDP_MAGENTA      13
#define VDP_GRAY         14
#define VDP_WHITE        15

#define SINGLE 11
#define TRIPLE 0
char style;			/* can be SINGLE or TRIPPLE */

unsigned char vdp_regen[24*40];

void vdp_read()
{
	char c,v;

	for(c=0;c<17;c++) {
		v = in(DATAP);
		printf("0x2x ",v);	
	}
}




void vdp_display(line,column,string)
	int line;
	int column;
	char * string;
{
	char index;
	
	vdp_wrvram(GUTTER+(line*40)+column);
	for(index=0;index<strlen(string);index++) {
		out(DATAP,string[index]);
	}
}

void vdp_pad(line,column,string)
	int line;
	int column;
	char * string;
{
	char index;
	
	vdp_wrvram(GUTTER+(line*40)+column);
	for(index=0;index<strlen(string);index++) {
		out(DATAP,string[index]);
	}
	if(40>strlen(string)) {
		for(index=strlen(string);index<40;index++) {
			out(DATAP,' ');
		}
	}
}

void  vdp_hz_join(line)
	int line;
{
	char i;
	char szTemp[2];
		
	sprintf(szTemp,"%c",0x8a+style);
	for(i=1;i<WIDTH-1;i++) {
		vdp_display(line,i,szTemp);
	}

	sprintf(szTemp,"%c",0x88+style);
	vdp_display(line,0,szTemp);

	sprintf(szTemp,"%c",0x89+style);
	vdp_display(line,WIDTH-1,szTemp);
}


void vdp_main_frame(name)
	char * name;
{
	char i;	
	char szTemp[48];
	
	sprintf(szTemp,"%c",0x81+style);
	for(i=1;i<WIDTH-1;i++) {
		vdp_display(0,i,szTemp);
	}

	sprintf(szTemp,"%c",0x85+style);
	for(i=1;i<WIDTH-1;i++) {
		vdp_display(HEIGHT-1,i,szTemp);
	}

	sprintf(szTemp,"%c",0x87+style);
	for(i=1;i<HEIGHT-1;i++) {
		vdp_display(i,0,szTemp);
	}	

	sprintf(szTemp,"%c",0x83+style);
	for(i=1;i<HEIGHT-1;i++) {
		vdp_display(i,WIDTH-1,szTemp);		
	}	

	sprintf(szTemp,"%c",0x80+style);
	vdp_display(0,0,szTemp);
	
	sprintf(szTemp,"%c",0x82+style);
	vdp_display(0,WIDTH-1,szTemp);
	
	sprintf(szTemp,"%c",0x84+style);
	vdp_display(HEIGHT-1,WIDTH-1,szTemp);
	
	sprintf(szTemp,"%c",0x86+style);
	vdp_display(HEIGHT-1,0,szTemp);
	
	sprintf(szTemp,"%s %d/%d/%d Ver %d.%d.%d",
		name,A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP);
	vdp_display(1,(WIDTH-strlen(szTemp))/2,szTemp);

	vdp_hz_join(2);
	vdp_hz_join(HEIGHT-3);		
}


void vdp_clr16k()
{
	unsigned int a;

#ifdef DEBUG	
	printf("Let's set VDP write address to #0000 \n");
#endif
 	out(CMDP,0);	/* 0x00 - a6 a7 a8 a9 a10 a11 a12 a13 	- all zeroes */
	out(CMDP,64);	/* 0x40 - 01 a0 a1 a2 a3 a4 a5 			- all zeroes */
#ifdef DEBUG
	printf("Now let's clear first 16Kb of VDP memory\n");
#endif
	for(a=0;a<16384;a++) {
		out(DATAP,0);
	}
}

void vdp_setregs()
{
#ifdef DEBUG
	printf("Now it's time to set up VDP registers\n");
#endif
	out(CMDP,0);	/* 0x00 - 000000 - 0	M3	M3 of 0 required text mode */
					/*                  0   EX  EX of 0 disables extVDP inp */
					
	out(CMDP,128);	/* 0x80 - 1 0000 000 - reg 0 */
}

void vdp_modes()
{
#ifdef DEBUG
	printf("Select 40 column mode, ");
	printf("enable screen and disable vertical interrupt\n");
#endif
	out(CMDP,80);	/* 0x50 - 0101 0000  - 0        4/16K Select 4027 RAM operation            */
					/*                      1       BLANK Enables the active display           */
					/*                       0      IE    Disables VDP interrupt               */
					/*                        1     M1    M1 of 1 is required for text mode    */
					/*                         0    M2    M2 of zero is required for text mode */
					/*                          0   n/a   */
					/*                           0  SIZE  0 sprites 8x8                        */
					/*                            0 MAG   0 sprites 2X  */
	out(CMDP,129);	/* 0x81 - 1 0000 001 - reg 1 */
}

void vdp_pnt()
{
#ifdef DEBUG
	printf("Set pattern name table to #0000\n");
#endif
	out(CMDP,0);	/* 0x00 - 0000 0000  - name table base addr 0 */
	out(CMDP,130);	/* 0x82 - 1 0000 010 - reg 2 */
}

void vdp_pgt()
{
#ifdef DEBUG
	printf("Set pattern generator table to #800\n");
#endif
	out(CMDP,1);	/* 0x01 - 00000 001  - pattern generator base addr 1 */
	out(CMDP,132);	/* 0x84 - 1 0000 100 - reg  4 */
}

void vdp_colors()
{
#ifdef DEBUG
	printf("Set colors to white on black\n");
#endif
	out(CMDP,240);	/* 0xF0 - 1111 0000  - (text=1111 bkgd=0000 */
	out(CMDP,135);	/* 0x87 - 1 0000 111 - reg 7 */
}

void vdp_load_set()
{
	int c,d,index;
#ifdef DEBUG
	printf("Let's set VDP write address to #800 so ");
	printf("that we can write character set to memory\n");
#endif	
	out(CMDP,0);	/* 0x00 - a6 a7 a8 a9 a10 a11 a12 a13 - all zeroes */
	out(CMDP,72);	/* 0x48 - 01 a0=0 a1=0 a2=1 a3=0 a4=0 a5=0 */
				/* a0  a1  a2  a3  a4  a5  a6  a7  a8  a9  a10 a11 a12 a13 */
				/*  0   0   0   1   0   0   0   0   0   0    0   0   0   0 */
				/*  000 1000 0000 0000	*/

#ifdef DEBUG
	printf("Create a character set\n");
#endif	
	index=0;
	for(c=0;c<256;c++) {
		for(d=0;d<8;d++) {
			out(DATAP,charset[index++]);	
		}
	}
}

void vdp_fill()
{
	int c;
	char d;

#ifdef DEBUG
	printf("Let's set write address to start of name table\n");
#endif	
	out(CMDP,0);
	out(CMDP,64);	/* 0x40 */
#ifdef DEBUG
	printf("Let's put characters to screen\n");
#endif
	d = 0;
	for(c=0;c<(40*24);c++) {
		out(DATAP,d);
		d++;
		if(128 == d) d=0;
	}
	
}

void vdp_sync_vdp_regen()
{
	int c,d;

#ifdef DEBUG	
	printf("Let's set write address to start of name table\n");
#endif

	out(CMDP,0);
	out(CMDP,64);	/* 0x40 */

#ifdef DEBUG
	printf("Let's put characters to screen\n");
#endif
	d = 0;
	for(c=0;c<(40*24);c++) {
		out(DATAP,vdp_regen[c]);
	}
}

void func700()
{
	out(CMDP,0);
	out(CMDP,0);
}

void vdp_clr_vdp_regen()
{
	unsigned int index;
	
	for(index=0;index<(24*40);index++) {
		vdp_regen[index] = ' ';	
	}
}

void vdp_set_vdp_regen()
{
	unsigned int index;

	for(index=0;index<40*24;index++) {
		vdp_regen[index]=index&0x7f;
	}
}

void vdp_num_vdp_regen()
{
	unsigned int index;

	for(index=0;index<40*24;index++) {
		vdp_regen[index]=0x30+(index%10);
	}

}


vdp_wrvram(o)
{
	unsigned char byte1;
	unsigned char byte2;
	
	byte1 = o & 255;
	byte2 = (o >> 8) | 0x40;
	out(CMDP,byte1);
	out(CMDP,byte2);
}

/* eof - tms9918.c */
