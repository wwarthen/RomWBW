/* tmsstat.c 10/30/2012 dwg - */

/* Ther purpose of this program is to read the VRAM of the
   TMS9918 video processor and display the contents in the
   most usable form. First is the raw hexadecimal dump of
   the first 16K of the VRAM, followed by a hexadecimal 
   dump of the name table by line number,  and finally the
   charactert generator bitmaps in ASCII order.
  */
  
#include "stdio.h"
#include "applvers.h"
#include "n8chars.h"
#include "tms9918.h"

char szTemp[128];
char linenum;
char counter;

char outer;
char inner;
char limit;

int index;

unsigned int line;
unsigned char ubyte;
unsigned char bitmask;

int row;
int bit;
int ascii;
int bool;

FILE * fd;
 
int main(argc,argv)
	int argc;
	char *argv[];
{
	char column;

	printf("tmsstat.com 10/04/2012 dwg - create tms9918.dmp files from VRAM\n");
	
	vdp_wrvram(0);
	in(DATAP);
	fd = fopen("tms9918.dmp","w");
	fprintf(fd,"This is a hexadecimal dump of the entire 16K VRAM\n");
	fprintf(fd,"Addr: 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F\n");
	fprintf(fd,"-----------------------------------------------------\n");
	for(line=0;line<16384/16;line++) {
		fprintf(fd,"%04x: ",line*16);
		for(column=0;column<16;column++) {
			fprintf(fd,"%02x ",in(DATAP));
		}
		fprintf(fd,"\n");
		printf("%cline %d",0x0d,line);
	}
	printf("\nDump of VRAM Completed\n");


	vdp_wrvram(0);
	in(DATAP);
	fprintf(fd,"\nThis is a hexadeci8mal dump of the Name Table for \n");
	fprintf(fd,"the 24 lines of the display in Text Mode.\n");
	fprintf(fd,"-----------------------------------------------------\n");
	for(line=0;line<24;line++) {
		fprintf(fd,"%2d: ",line);
		for(column=0;column<20;column++) {
			fprintf(fd,"%02x ",in(DATAP));
		}
		fprintf(fd,"\n");
		fprintf(fd,"%2d: ",line);
		for(column=0;column<20;column++) {
			fprintf(fd,"%02x ",in(DATAP));
		}
		fprintf(fd,"\n\n");
		printf("%cline %d",0x0d,line);
	}
	printf("\nDump of Name Table for 40x24 Text Mode Lines Completed\n");
	fprintf(fd,"\n	This is a Hexadecimal, Decimal, and Graphic dump\n");
	fprintf(fd,"of the Character Generator Bitmaps for all 256 ASCII ");
	fprintf(fd,"chars.\n\n");
	vdp_wrvram(0x800);
	in(DATAP);
	for(ascii=0;ascii<256;ascii++) {
		printf("%cDumping ASCII %d",0x0d,ascii);
		fprintf(fd,"0x%2x(%3d):\n",ascii,ascii);
		for(row=0;row<8;row++) {
			ubyte = in(DATAP);
			fprintf(fd,"0x%02x: ",ubyte);
			for(bit=0;bit<8;bit++) {
				bitmask = 1<<(7-bit);
				bool = ubyte & bitmask;
				if(0 == bool ) {
					fprintf(fd," ");
				} else {
					fprintf(fd,"*");
				}			
			}
			fprintf(fd,"\n");
		}
		fprintf(fd,"\n");
		printf("%cline %d",0x0d,line);
	}


	fprintf(fd,"-----------------------------------------------------\n");

	fclose(fd);
	printf("\nDump of Character Bitmap Data Completed.\n");
}

