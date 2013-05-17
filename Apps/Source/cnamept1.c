/* cnamept1.c 5/24/2012 dwg - added bootlu */

#include "stdio.h"
#include "stdlib.h"

#include "portab.h"
#include "std.h"

#include "cnfgdata.h"
#include "syscfg.h"

extern pager();
extern char * fmthexbyte();
extern char * fmthexword();
extern char * fmtbool();
extern char * fmtenable();
extern putscpm();

char None[] = "*NONE*";
char * PltName[] = {None, "N8VEM Z80", "ZETA Z80", "N8 Z180"};
char * CIOName[] = {"UART", "ASCI", "VDU", "CVDU", "UPD7220", 
			"N8V", "PRPCON", "PPPCON", "CRT", "BAT", "NUL"};
char * DIOName[] = {"MD", "FD", "IDE", "ATAPI", "PPIDE",
			"SD", "PRPSD", "PPPSD", "HDSK"};
char * VDAName[] = {None, "VDU", "CVDU", "UPD7220", "N8V"};
char * EmuName[] = {None, "TTY", "ANSI"};
char * TermName[] = {"TTY", "ANSI", "WYSE", "VT52"};
char * DiskMapName[] = {None, "ROM", "RAM", "FD", "IDE", 
			"PPIDE", "SD", "PRPSD", "PPPSD", "HDSK"};
char * ClrRamName[] = {"Never", "Auto", "Always"};
char * FDModeName[] = {None, "DIO", "ZETA", "DIDE", "N8", "DIO3"};
char * FDMediaName[] = {"720K", "1.44M", "360k", "1.2M", "1.11M"};
char * IDEModeName[] = {None, "DIO", "DIDE"};

cnamept1(pSysCfg)
	struct SYSCFG * pSysCfg;
{
	struct CNFGDATA * pCfg;
	char buf[5];
	char buf2[5];
	
	pCfg = &(pSysCfg->cnfgdata);

	printf("%s @ %dMHz, RAM=%dMB, ROM=%dMB", 
		PltName[pCfg->platform], 
		pCfg->freq,
		pCfg->ramsize,
		pCfg->romsize);
	pager();
	printf("RomWBW Version %d.%d.%d.%d, ", 
		pCfg->rmj, pCfg->rmn,
		pCfg->rup, pCfg->rtp);
	putscpm((unsigned int)pSysCfg + (unsigned int)pSysCfg->tstloc);
	pager();
	if (pCfg->diskboot)
		printf("Disk Boot Device=%s, Unit=%d, LU=%d",
			DIOName[pCfg->devunit >> 4],
			pCfg->devunit & 0xF, pCfg->bootlu);
	else
		printf("ROM Boot");
	pager();
	pager();
	
	printf("Default Console: %s, Alternate Console: %s",
		CIOName[pCfg->defcon], CIOName[pCfg->altcon]);
	pager();
	printf ("Default Video Display: %s, Default Emulation: %s",
		VDAName[pCfg->defvda], EmuName[pCfg->defemu]);
	pager();
	printf ("Current Terminal Type: %s",
		TermName[pCfg->termtype]);
	pager();
	
	printf("Default IO Byte: 0x%s, Alternate IO Byte: 0x%s",
		fmthexbyte(pCfg->defiobyte, buf),
		fmthexbyte(pCfg->altiobyte, buf2));
	pager();
	printf("Disk Write Caching=%s, Disk IO Tracing=%s",
		fmtbool(pCfg->wrtcache), fmtbool(pCfg->dsktrace));
	pager();
	printf("Disk Mapping Priority: %s, Clear RAM Disk: %s",
		DiskMapName[pCfg->dskmap], ClrRamName[pCfg->clrramdsk]);
	pager();
	pager();
	
	printf("DSKY %s", fmtenable(pCfg->dskyenable));
	pager();
	printf("UART %s, FIFO=%s, AFC=%s, Baudrate=0x%s",
		fmtenable(pCfg->uartenable),
		fmtbool(pCfg->uartfifo), fmtbool(pCfg->uartafc),
		fmthexword(pCfg->baudrate, buf));
	pager();
	printf("VDU %s", fmtenable(pCfg->vduenable));
	pager();
	printf("CVDU %s", fmtenable(pCfg->cvduenable));
	pager();
	printf("UPD7220 %s", fmtenable(pCfg->upd7220enable));
	pager();
	printf("N8V %s", fmtenable(pCfg->n8venable));
	pager();
	pager();

	printf("FD %s, Mode=%s, TraceLevel=%d, Media=%s/%s, Auto=%s",
		fmtenable(pCfg->fdenable), FDModeName[pCfg->fdmode], 
		pCfg->fdtrace,
		FDMediaName[pCfg->fdmedia], FDMediaName[pCfg->fdmediaalt],
		fmtbool(pCfg->fdmauto));
	pager();
	printf("IDE %s, Mode=%s, TraceLevel=%d, 8bit=%s, Size=%dMB",
		fmtenable(pCfg->ideenable), IDEModeName[pCfg->idemode],
		pCfg->idetrace, fmtbool(pCfg->ide8bit), pCfg->idecapacity);
	pager();
	printf("PPIDE %s, Mode=%s, TraceLevel=%d, 8bit=%s, Slow=%s, Size=%dMB",
		fmtenable(pCfg->ppideenable), IDEModeName[pCfg->ppidemode],
		pCfg->ppidetrace, fmtbool(pCfg->ppide8bit), 
		fmtbool(pCfg->ppideslow), pCfg->ppidecapacity);
	pager();
	printf("PRP %s, SD %s, TraceLevel=%d, Size=%dMB, Console %s",
		fmtenable(pCfg->prpenable), fmtenable(pCfg->prpsdenable), 
		pCfg->prpsdtrace, pCfg->prpsdcapacity,
		fmtenable(pCfg->prpconenable));
	pager();
	printf("PPP %s, SD %s, TraceLevel=%d, Size=%dMB, Console %s",
		fmtenable(pCfg->pppenable), fmtenable(pCfg->pppsdenable), 
		pCfg->pppsdtrace, pCfg->pppsdcapacity,
		fmtenable(pCfg->pppconenable));
	pager();
	printf("HDSK %s, TraceLevel=%d, Size=%dMB",
		fmtenable(pCfg->hdskenable),
		pCfg->hdsktrace, pCfg->hdskcapacity);
	pager();
	pager();
	
	printf("PPK %s, TraceLevel=%d",
		fmtenable(pCfg->ppkenable), pCfg->ppktrace);
	pager();
	printf("KBD %s, TraceLevel=%d",
		fmtenable(pCfg->kbdenable), pCfg->kbdtrace);
	pager();
	pager();
	
	printf("TTY %s", fmtenable(pCfg->ttyenable));
	pager();
	printf("ANSI %s, TraceLevel=%d",
		fmtenable(pCfg->ansienable), pCfg->ansitrace);
	pager();
}


/********************/
/* eof - cnamecp1.c */
/********************/
