/* cnamept2.c 5/24/2012 dwg - */

#include "stdio.h"
#include "stdlib.h"

#include "portab.h"
#include "std.h"

#include "cnfgdata.h"
#include "syscfg.h"

extern pager();

char cache[17];

cnamept3(syscfg)
	struct SYSCFG * syscfg;
{
	strcpy(cache,"syscfg->cnfgdata");
	
	printf("%s.fdmauto       = ",cache);
	 switch(syscfg->cnfgdata.fdmauto) {
	 	case TRUE:	printf("TRUE");	
	 					break;
	 	case FALSE:	printf("FALSE");	
	 					break;
	}
	pager();
	
	printf("%s.ideenable     = ",cache);
	 switch(syscfg->cnfgdata.ideenable) {
	 	case TRUE:	printf("TRUE");	
	 					break;
	 	case FALSE:	printf("FALSE");	
	 					break;
	}
	pager();

	if(TRUE == syscfg->cnfgdata.ideenable) {

		printf("%s.idetrace  = ",cache);
	 	 switch(syscfg->cnfgdata.idetrace) {
	 		case 0:	printf("SILENT");	
	 					break;
	 		case 1:	printf("ERRORS");	
	 					break;
	 		case 2: printf("EVERYTHING");
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();

		printf("%s.de8bit       = ",cache);
	 	 switch(syscfg->cnfgdata.ide8bit) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
	 		default:	printf("Unknown!!");
	 					break;
		}
		pager();
	
		printf("%s.idecapacity   = %dMB",cache,
				syscfg->cnfgdata.idecapacity);
		pager();

	}
	
	printf("%s.ppideenable   = ",cache);
	 switch(syscfg->cnfgdata.ppideenable) {
	 	case TRUE:	printf("TRUE");	
	 					break;
	 	case FALSE:	printf("FALSE");	
	 					break;
	}
	pager();
	
	if(TRUE == syscfg->cnfgdata.ppideenable) {
	
		printf("%s.ppidetrace    = ",cache);
	 	 switch(syscfg->cnfgdata.ppidetrace) {
	 		case 0:	printf("SILENT");	
	 					break;
	 		case 1:	printf("ERRORS");	
	 					break;
	 		case 2: printf("EVERYTHING");
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();


		printf("%s.ppide8bit     = ",cache);
		 switch(syscfg->cnfgdata.ppide8bit) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();
	
		printf("%s.ppidecapacity = %dKB",cache,
				syscfg->cnfgdata.ppidecapacity);
		pager();
	
		printf("%s.ppideslow     = ",cache);
	 	 switch(syscfg->cnfgdata.ppideslow) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();
	
	}
	
	printf("%s.boottype      = ",cache);
	 switch(syscfg->cnfgdata.boottype) {
	 	case BTMENU:	printf("BT_MENU");	
	 					break;
	 	case BTAUTO:	printf("BT_AUTO");	
	 					break;
	}
	pager();
	
	printf("%s.boottimeout   = %d seconds",cache,
			syscfg->cnfgdata.boottimeout);
	pager();
	
	printf("%s.bootdefault   = %c:",cache,
			syscfg->cnfgdata.bootdefault);
	pager();
	
	printf("%s.baudrate      = %u (0x%04x) Baud",cache,
			syscfg->cnfgdata.baudrate,syscfg->cnfgdata.baudrate);
	pager();

	if(PLT_N8 == syscfg->cnfgdata.platform) {
	
		printf("%s.ckdiv         = %d",cache,
				syscfg->cnfgdata.ckdiv);
		pager();
	
		printf("%s.memwait       = 0x%02x",cache,
				syscfg->cnfgdata.memwait);
		pager();
	
		printf("%s.iowait        = 0x%02x",cache,syscfg->cnfgdata.iowait);
		pager();
	
		printf("%s.cntlb0        = 0x%02x",cache,syscfg->cnfgdata.cntlb0);
		pager();
	
		printf("%s.cntlb1        = 0x%02x",cache,syscfg->cnfgdata.cntlb1);
		pager();
	

		printf("%s.sdenable      = ",cache);
		 switch(syscfg->cnfgdata.sdenable) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
	 		default:	printf("Unknown!!");
	 					break;
		}
		pager();

		printf("%s.sdtrace       = ",cache);
	 	switch(syscfg->cnfgdata.sdtrace) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();

	}
}


/********************/
/* eof - cnamept3.c */
/********************/

/*
	unsigned char ckdiv;
	unsigned char memwait;
	
	unsigned char iowait;
	unsigned char cntlb0;
	unsigned char cntlb1;
	unsigned char sdenable;
	unsigned char sdtrace;
	unsigned int sdcapacity;
	unsigned char sdcsio;
	unsigned char sdcsiofast;
	unsigned char defiobyte;
	unsigned char termtype;
	unsigned int revision;
	unsigned char prpsdenable;
	unsigned char prpsdtrace;
	unsigned int prpsdcapacity;
	unsigned char prpconenable;
	unsigned int biossize;				
*/
