/* testv5.c 8/30/2012 dwg - derived from Wayne's TESTV5.BAS */
/* Simple VIDEO test for N8;        I/O Base assumed as 128 */

#include "tms9918.h"

int main(argc,argv)
	int argc;
	char *argv[];
{
	int i;

	vdp_clr16k();
	vdp_setregs();
	vdp_modes();
	vdp_pnt();
	vdp_pgt();
	vdp_colors();
	vdp_load_set450();

/*	vdp_clr_regen();	*/
/*	vdp_fill(); 		*/

/*	vdp_num_regen();	*/
/*	vdp_clr_regen();	*/
/*	vdp_sync_regen();	*/

	vdp_write_ram(40);
	for(i=0;i<40;i++) {
		out(DATAP,i);
	}


	func700();
/*	vdp_display();	*/
}
