/* cnamept2.c 5/24/2012 dwg - */

#include "stdio.h"
#include "stdlib.h"

#include "portab.h"
#include "std.h"

#include "cnfgdata.h"
#include "syscfg.h"

extern pager();

char cache[17];

cnamept2(syscfg)
	struct SYSCFG * syscfg;
{
	strcpy(cache,"syscfg->cnfgdata");
	
	printf("%s.clrramdk      = ",cache);
	 switch(syscfg->cnfgdata.clrramdk) {
		case CLRNEV:	printf("CLR_NEVER");	break;
		case CLRAUTO:	printf("CLR_AUTO");		break;
		case CLRALLW:	printf("CLR_ALLWAYS");	break;
	}
	pager();
	
	printf("%s.dskyenable    = ",cache);
	 switch(syscfg->cnfgdata.dskyenable) {
	 	case TRUE:	printf("TRUE");		break;
	 	case FALSE:	printf("FALSE");	break;
	}
	pager();

	printf("%s.uartenable    = ",cache);
	 switch(syscfg->cnfgdata.uartenable) {
	 	case TRUE:	printf("TRUE");		break;
	 	case FALSE:	printf("FALSE");	break;
	}
	pager();
	
	printf("%s.vduenable     = ",cache);
	 switch(syscfg->cnfgdata.vduenable) {
	 	case TRUE:	printf("TRUE");		break;
	 	case FALSE:	printf("FALSE");	break;
	}
	pager();
	
	printf("%s.fdenable      = ",cache);
	 switch(syscfg->cnfgdata.fdenable) {
	 	case TRUE:	printf("TRUE");		break;
	 	case FALSE:	printf("FALSE");	break;
	}
	pager();

	if(TRUE == syscfg->cnfgdata.fdenable) {

		printf("%s.fdtrace       = ",cache);
	 	 switch(syscfg->cnfgdata.fdtrace) {
	 		case 0:		printf("Silent");		break;
	 		case 1:		printf("Fatal Errors");	break;
	 		case 2:		printf("All Errors");	break;
	 		case 3:		printf("Everything");	break;
	 		default:	printf("Unknown!!");	break;
		}	
		pager();
	
		printf("%s.fdmedia       = ",cache);
	 	 switch(syscfg->cnfgdata.fdmedia) {
			case FDM720: 	printf("FDM720");		
	 					printf("  3.5 720KB 2-sided 80 Trks 9 Sectors");
						break;
			case FDM144:	printf("FDM144");		
	 					printf("  3.5 1.44MB 2-sided 80 Trks 18 Sectors");
						break;
	 		case FDM360:	printf("FDM360");	
	 					printf("  5.25 360KB 2-sided 40 Trks 9 Sectors");
	 					break;
	 		case FDM120:	printf("FDM120");	
	 					printf("  3.5 1.2MB 2-sided 80 Trks 15 Sectors");
	 					break;
			default:		printf("Unknown!!");	
						break;
		}
		pager();
	
		printf("%s.fdmediaalt    = ",cache);
	 	 switch(syscfg->cnfgdata.fdmediaalt) {
	 		case FDM720:	printf("FDM720");	
	 					printf("  3.5 720KB 2-sided 80 Trks 9 Sectors");
	 					break;
	 		case FDM144:	printf("FDM144");	
	 					printf("  3.5 1.44MB 2-sided 80 Trks 18 Sectors");
	 					break;
	 		case FDM360:	printf("FDM360");	
	 					printf("  5.25 360KB 2-sided 40 Trks 9 Sectors");
	 					break;
	 		case FDM120:	printf("FDM120");	
	 					printf("  3.5 1.2MB 2-sided 80 Trks 15 Sectors");
	 					break;
		}
		pager();

	}	
}


/********************/
/* eof - cnamept2.c */
/********************/

