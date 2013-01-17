/* ctermcap.c 3/11/2012 dwg - terminal capbility file */

#include "stdio.h"
#include "stdlib.h"
#include "cpmbind.h"
#include "applvers.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "diagnose.h"

int tt;

crtinit()
{
	struct SYSCFG * pSYSCFG;
	hregbc = 0x0f000;
	hregde = 0x0C000;
	diagnose();
	pSYSCFG = 0x0C000;
	tt = pSYSCFG->cnfgdata.termtype;
}

crtclr()
{
	int i;

	switch(tt) {
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

	switch(tt) {
		case TERM_TTY:
			break;
		case TERM_ANSI:
			printf("%c[%d;%d%c",ESC,line,col,0x66);
			break;
		case TERM_WYSE:
			printf("%c+",ESC);
			break;
		case TERM_VT52:
			printf("%cY%c%c",ESC,' '+line,' '+col);
			break;
	};
}




/*

SINGLEQUOTE equ 0
RIGHTQUOTE  equ 0
LEFTQUOTE   equ 0

wy50row	db	' !"#$%&'
	db	39
	db	'()*+,-./01234567'

wy50col db	' !"#$%&'
	db	39
	db	'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_'
	db	96
	db	'abcdefghijklmno'

templine db 0
tempcol	 db 0

*/


/********************/
/* eof - ctermcap.c */
/********************/
