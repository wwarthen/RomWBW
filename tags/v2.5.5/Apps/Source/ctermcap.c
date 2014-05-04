/* ctermcap.c 3/11/2012 dwg - terminal capbility file */

#include "stdio.h"
#include "stdlib.h"
#include "cpmbind.h"
#include "applvers.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "diagnose.h"

char termtype;



char wy50row[24] = { ' ', '!', '"', '#', '$', '%', '&', 39,
				  '(', ')', '*', '+', ',', '-', '.', '/',
				  '0', '1', '2', '3', '4', '5', '6', '7' };

char wy50col[80] = { ' ', '!', '"', '#', '$', '%', '&', 39,
				  '(', ')', '*', '+', ',', '-', '.', '/',
				  '0', '1', '2', '3', '4', '5', '6', '7',
				  '8', '9', ':', ';', '<', '=', '>', '?',
				  '@', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
				  'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
				  'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W',
				  'X', 'Y', 'Z', '[', '\\', ']', '^', '_',
				  96,  'a', 'b', 'c', 'd', 'e', 'f', 'g',
				  'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o' };
				  


crtinit(tt)
	char tt;
{
	termtype = tt;
}

crtclr()
{
	int i;

	switch(termtype) {
		case TERM_TTY:
			for(i=0;i<43;i++) {
				printf("%c%c",CR,LF);
			}
			break;
		case TERM_ANSI:
			printf("%c[2J",ESC);
			break;
		case TERM_WYSE:
			printf("%c+",ESC);
			break;
		case TERM_VT52:
			printf("%cJ%cH",ESC,ESC);
			break;
	};
}

crtlc(line,col)
int line;
int col;
{
	int i;

	switch(termtype) {
		case TERM_TTY:
			break;
		case TERM_ANSI:
			printf("%c[%d;%d%c",ESC,line,col,0x66);
			break;
		case TERM_WYSE:
			printf("%c=%c%c",ESC,wy50row[line-1],wy50col[col-1]);
			break;
		case TERM_VT52:
			printf("%cY%c%c",ESC,' '+line,' '+col);
			break;
	};
}

/*

wy50row	db	' !"#$%&'
	db	39
	db	'()*+,-./01234567'

wy50col db	' !"#$%&'
	db	39
	db	'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'
	db	96
	db	'abcdefghijklmno'

*/


/********************/
/* eof - ctermcap.c */
/********************/
