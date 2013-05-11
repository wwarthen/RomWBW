/* cnamept2.c 5/24/2012 dwg - */

#include "stdio.h"
#include "stdlib.h"

#include "portab.h"
#include "std.h"

#include "cnfgdata.h"
#include "syscfg.h"

extern pager();

char cache[17];

cnamept4(syscfg)
	struct SYSCFG * syscfg;
{
	strcpy(cache,"syscfg->cnfgdata");
	
	if(PLT_N8 == syscfg->cnfgdata.platform) {
	
		printf("%s.sdcapacity    = %uKB",cache,
				syscfg->cnfgdata.sdcapacity);
		pager();


		printf("%s.sdcsio        = ",cache);
	 	 switch(syscfg->cnfgdata.sdcsio) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:
					printf("Unknown!!");
						break;
		}
		pager();

		printf("%s.sdcsiofast    = ",cache);
	 	 switch(syscfg->cnfgdata.sdcsiofast) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();

	}
	
	printf("%s.defiobyte     = 0x%02x",cache,
	 		syscfg->cnfgdata.defiobyte);
	pager();

	printf("%s.termtype      = ",cache);
	 switch(syscfg->cnfgdata.termtype) {
	 	case TERM_TTY:	printf("TERM_TTY");	
	 					break;
	 	case TERM_ANSI:	printf("TERM_ANSI");	
	 					break;
	 	case TERM_WYSE:	printf("TERM_WYSE");	
	 					break;
	 	case TERM_VT52:	printf("TERM_VT52");	
	 					break;
		default:		printf("Unknown!!");
						break;
	}
	pager();

	printf("%s.revision      = %d",cache,
	 		syscfg->cnfgdata.revision);
	pager();

	printf("%s.prpenable     = ",cache);
	 switch(syscfg->cnfgdata.prpenable) {
	 	case TRUE:	printf("TRUE");	
	 					break;
	 	case FALSE:	printf("FALSE");	
	 					break;
		default:	printf("Unknown!!");
						break;
	}
	pager();

	if(TRUE == syscfg->cnfgdata.prpenable) {
	
		printf("%s.prpsdenable   = ");
	 	 switch(syscfg->cnfgdata.prpsdenable) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();

		if(TRUE == syscfg->cnfgdata.prpsdenable) {
	
			printf("%s.prpsdtrace    = ",cache);
	 	 	 switch(syscfg->cnfgdata.prpsdtrace) {
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

			printf("%s.prpsdcapacity = ",cache);
			pager();

			printf("%s.prpconenable  = ",cache);
	 	 	 switch(syscfg->cnfgdata.prpconenable) {
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
	
	printf("%s.biossize      = %d",cache,
	 		syscfg->cnfgdata.biossize);
	pager();

	
	printf("%s.pppenable     = ",cache);
	 switch(syscfg->cnfgdata.pppenable) {
	 	case TRUE:	printf("TRUE");	
	 					break;
	 	case FALSE:	printf("FALSE");	
	 					break;
		default:	printf("Unknown!!");
						break;
	}
	pager();

	if(TRUE == syscfg->cnfgdata.pppenable) {

		printf("%s.pppsdenable  = ",cache);
	 	 switch(syscfg->cnfgdata.pppsdenable) {
	 		case TRUE:	printf("TRUE");	
	 					break;
	 		case FALSE:	printf("FALSE");	
	 					break;
			default:	printf("Unknown!!");
						break;
		}
		pager();

		printf("%s.pppsdtrace    = ",cache);
	 	 switch(syscfg->cnfgdata.pppsdtrace) {
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


		printf("%s.pppcapacity   = %d",cache,
	 		    syscfg->cnfgdata.prpsdcapacity);
		pager();

		printf("%s.pppconenable  = ",cache);
	 	 switch(syscfg->cnfgdata.pppconenable) {
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
/* eof - cnamept4.c */
/********************/

