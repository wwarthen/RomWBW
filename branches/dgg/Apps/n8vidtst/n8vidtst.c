/* n8video.c 9/11/2012 dwg - derived from Wayne's TESTV5.BAS */
/* Simple VIDEO test for N8;         I/O Base assumed as 128 */

#include "applvers.h"
#include "tms9918.h"


char szTemp[128];
char linenum;
char counter;

char outer;
char inner;
char limit;

int main(argc,argv)
	int argc;
	char *argv[];
{
	int i;
	char szTemp[64];
	unsigned char chardex;
	
	vdp_clr16k();
	vdp_setregs();
	vdp_modes();
	vdp_pnt();
	vdp_pgt();
	vdp_colors();
	vdp_load_set450();

	if(outer == 3) style = TRIPLE;
	vdp_main_frame("N8VIDTST(dwg)");
	chardex = 0;

	for(outer=0;outer<4;outer++) {
		linenum = 4;
		for(inner=0;inner<6;inner++) {
			if(inner < 5) limit=11;
			else          limit=9;
			for(i=0;i<limit;i++) {
				sprintf(szTemp,"%c",chardex);
				vdp_display(linenum,2+(i*3),szTemp);
				sprintf(szTemp,"%02x",chardex++);
				vdp_display(linenum+1,2+(i*3),szTemp);
			}
			linenum += 3;
			if(inner==5) {
				sprintf(szTemp,"Pg %d/4",outer+1);
				vdp_display(20,29,szTemp);
			}
		}
		if(outer < 3) {
			vdp_display(22,2," Press any key to continue");
			gets(szTemp);
		}
	}
	vdp_display(22,1,"Execution complete,returned to CP/M");

	if(argc == 2) {
		sprintf(szTemp,"%c",atoi(argv[1]));
		vdp_display(1,WIDTH-2,szTemp);
	}

}

