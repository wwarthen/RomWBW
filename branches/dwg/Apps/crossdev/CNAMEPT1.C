/* cnamept1.c 5/24/2012 dwg - added bootlu */

#include "stdio.h"
#include "stdlib.h"

#include "portab.h"
#include "std.h"

#include "cnfgdata.h"
#include "syscfg.h"

extern pager();

char cache[17];

cnamept1(syscfg)
	struct SYSCFG * syscfg;
{
	strcpy(cache,"syscfg->cnfgdata");
	
	printf("syscfg->jmp            jp  0%04xh",syscfg->jmp.address);
	pager();
	
	printf("syscfg->cnfloc         .dw 0%04xh",syscfg->cnfloc);
	pager();
	
	printf("syscfg->tstloc         .dw 0%04xh",syscfg->tstloc);
	pager();
	
	printf("syscfg->varloc         .dw 0%04xh",syscfg->varloc);
	pager();
	
	printf("%s.rmj           = %d",cache,syscfg->cnfgdata.rmj);
	pager();
	
	printf("%s.rmn           = %d",cache,syscfg->cnfgdata.rmn);
	pager();
	
	printf("%s.rup           = %d",cache,syscfg->cnfgdata.rup);
	pager();
	
	printf("%s.rtp           = %d",cache,syscfg->cnfgdata.rtp);
	pager();
	
	printf("%s.diskboot      = ",cache);
	 switch(syscfg->cnfgdata.diskboot) {
		case TRUE:  printf("TRUE");  break;
		case FALSE: printf("FALSE"); break;
	} 
	pager();
	
	printf("%s.devunit       = 0x%02x",cache,
			syscfg->cnfgdata.devunit);
	pager();
	
	printf("%s.bootlu        = 0x%04x",cache,
			syscfg->cnfgdata.bootlu);
	pager();
	
	printf("%s.freq          = %dMHz",cache,syscfg->cnfgdata.freq);	
	pager();
	
	printf("%s.platform      = ",cache);
	 switch(syscfg->cnfgdata.platform) {
	 	case PLT_N8VEM:	printf("N8VEM");  break;
	 	case PLT_ZETA:	printf("ZETA");	break;
	 	case PLT_N8:	printf("N8");		break;
	 }
	pager();
	
	printf("%s.dioplat       = ",cache);
	 switch(syscfg->cnfgdata.dioplat) {
		case DPNONE: 	printf("DIOPLT_NONE");		break;
		case DPDIO:		printf("DIOPLT_DISKIO");	break;
		case DPZETA:	printf("DIOPLT_ZETA");		break;
		case DPDIDE:	printf("DIOPLT_DIDE");		break;
		case DPN8:		printf("DIOPLT_N8");		break;
		case DPDIO3:	printf("DIOPLT_DISKIO3");	break;
		default:		printf("Unknown");			break;
	 }
	pager();
		
	printf("%s.vdumode       = ",cache);
	 switch(syscfg->cnfgdata.vdumode) {
		case VPNONE: 	printf("VDUPLT_NONE");		break;
		case VPVDU:	 	printf("VDUPLT_VDU");		break;
		case VPVDUC: 	printf("VDUPLT_VDUC"); 		break;
		case VPPROPIO: 	printf("VDUPLT_PROPIO");	break;
		case VPN8:		printf("VDUPLT_VPN8");		break;	 
		default:		printf("Unknown!!");		break;
	}	
	pager();

	printf("%s.romsize       = %d",cache,
		    syscfg->cnfgdata.romsize);		 
	pager();
	
	printf("%s.ramsize       = %d",cache,
		    syscfg->cnfgdata.ramsize);		 
	pager();
	
}


/********************/
/* eof - cnamecp1.c */
/********************/
