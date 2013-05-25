/* cpmname.c 5/21/2012 dwg - */

#include "applvers.h"
#include "infolist.h"
#include "cnfgdata.h"
#include "syscfg.h"
#include "diagnose.h"
#include "std.h"

#define HIGHSEG 0xC000		/* memory address of system config  */

#define GETSYSCFG 0xF000	/* HBIOS function for Get System Configuration */

char None[] = "*None*";
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
char * FDMediaName[] = {"720K", "1.44M", "360K", "1.2M", "1.11M"};
char * IDEModeName[] = {None, "DIO", "DIDE"};

char hexchar(val, bitoff)
{
	static char hexmap[] = "0123456789ABCDEF";

	return hexmap[(val >> bitoff) & 0xF];
}

char * fmthexbyte(val, buf)
	unsigned char val;
	char * buf;
{
	buf[0] = hexchar(val, 4);
	buf[1] = hexchar(val, 0);
	buf[2] = '\0';
	
	return buf;
}

char * fmthexword(val, buf)
	unsigned int val;
	char * buf;
{
	buf[0] = hexchar(val, 12);
	buf[1] = hexchar(val, 8);
	fmthexbyte(val, buf + 2);

	return buf;
}

char * fmtbool(val)
	unsigned char val;
{
	return (val ? "True" : "False");
}

char * fmtenable(val)
	unsigned char val;
{
	return (val ? "Enabled" : "Disabled");
}

putscpm(p)
	char * p;
{
	while (*p != '$')
		putchar(*(p++));
}

pager()
{
	static int line = 1;
	int i;

	line++;
	printf("\r\n");

	if(line >= 24)
	{
		printf("*** Press any key to continue...");
		while (bdos(6, 0xFF) == 0);
		putchar('\r');
		for (i = 0; i < 40; i++) {putchar(' ');}
		putchar('\r');
		line = 1;
	}
}

prtcfg1(pSysCfg)
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
	
	printf("Console: Default=%s, Alternate=%s, Init Baudrate=%d0",
		CIOName[pCfg->defcon], CIOName[pCfg->altcon],
		pCfg->conbaud);
	pager();
	printf ("Default Video Display: %s, Default Emulation: %s",
		VDAName[pCfg->defvda], EmuName[pCfg->defemu]);
	pager();
	printf ("Current Terminal Type: %s",
		TermName[pCfg->termtype]);
	pager();
	
	printf("Default IO Byte=0x%s, Alternate IO Byte=0x%s",
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
	if (pCfg->uartenable)
	{
		printf("UART Enabled");
		pager();
		if (pCfg->uartcnt >= 1)
			printf("UART0 FIFO=%s, AFC=%s, Baudrate=%d0",
				fmtbool(pCfg->uart0fifo), fmtbool(pCfg->uart0afc), pCfg->uart0baud);
		if (pCfg->uartcnt >= 2)
			printf("UART1 FIFO=%s, AFC=%s, Baudrate=%d0",
				fmtbool(pCfg->uart1fifo), fmtbool(pCfg->uart1afc), pCfg->uart1baud);
		if (pCfg->uartcnt >= 3)
			printf("UART2 FIFO=%s, AFC=%s, Baudrate=%d0",
				fmtbool(pCfg->uart2fifo), fmtbool(pCfg->uart2afc), pCfg->uart2baud);
		if (pCfg->uartcnt >= 4)
			printf("UART3 FIFO=%s, AFC=%s, Baudrate=%d0",
				fmtbool(pCfg->uart3fifo), fmtbool(pCfg->uart3afc), pCfg->uart3baud);
	}
	else
		printf("UART Disabled");
	pager();
	if (pCfg->ascienable)
	{
		printf("ASCI Enabled");
		pager();
		printf("ASCI0, Baudrate=%d0", pCfg->asci0baud);
		printf("ASCI1, Baudrate=%d0", pCfg->asci1baud);
	}
	else
		printf("ASCI Disabled");
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
}

prtcfg2(pSysCfg)
	struct SYSCFG * pSysCfg;
{
	struct CNFGDATA * pCfg;
	char buf[5];
	char buf2[5];
	
	pCfg = &(pSysCfg->cnfgdata);

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

int main(argc,argv)
	int argc;
	char *argv[];
{
	struct INFOLIST * pInfoList;
	struct SYSCFG * pSysCfg;

	printf("CPMNAME.COM %d/%d/%d v%d.%d.%d (%d)",
		A_MONTH,A_DAY,A_YEAR,A_RMJ,A_RMN,A_RUP,A_RTP);
	printf(" dwg - Display System Configuration");
	pager();
	pager();
	
	pInfoList = bioshl(20, 0, 0);
	
	putscpm(pInfoList->banptr);
	pager();
	pager();

	pSysCfg = HIGHSEG;
	hregbc = GETSYSCFG;				/* function = Get System Config      */
	hregde = pSysCfg;				/* addr of dest (must be high)       */
	diagnose();						/* invoke the HBIOS function         */
	
	if (pSysCfg->marker != CFGMARKER)
	{
		printf("*** Invalid configuration data ***\r\n");
		return;
	}
	
	prtcfg1(pSysCfg);
	prtcfg2(pSysCfg);
}

/********************/
/* eof - ccpmname.c */
/********************/
