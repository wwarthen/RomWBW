/* cnfgdata.h 6/04/2012 dwg - */

struct CNFGDATA {

	unsigned char rmj;
	unsigned char rmn;
	unsigned char rup;
	unsigned char rtp;
	unsigned int revision;

	unsigned char diskboot;
	unsigned char devunit;
	unsigned int  bootlu;
	unsigned char year;
	unsigned char month;
	unsigned char day;
	unsigned char hour;
	unsigned char minute;
	unsigned char second;

	unsigned char platform;
	unsigned char freq;
	unsigned int ramsize;
	unsigned int romsize;

	unsigned char ckdiv;
	unsigned char memwait;
	unsigned char iowait;
	unsigned char cntlb0;
	unsigned char cntlb1;

	unsigned char boottype;
	unsigned char boottimeout;
	unsigned char bootdefault;

	unsigned char defcon;
	unsigned char altcon;
	unsigned char defvda;
	unsigned char defemu;
	unsigned char termtype;
	
	unsigned char defiobyte;
	unsigned char altiobyte;
	unsigned char wrtcache;
	unsigned char dsktrace;
	unsigned char dskmap;
	unsigned char clrramdsk;
	
	unsigned char dskyenable;

	unsigned char uartenable;
	unsigned char uartfifo;
	unsigned char uartafc;
	
	unsigned char ascienable;
	
	unsigned int baudrate;			/* actual baudrate / 10 */
	
	unsigned char vduenable;

	unsigned char cvduenable;

	unsigned char upd7220enable;

	unsigned char n8venable;
	
	unsigned char fdenable;
	unsigned char fdmode;
	unsigned char fdtrace;
	unsigned char fdmedia;
	unsigned char fdmediaalt;
	unsigned char fdmauto;
	
	unsigned char ideenable;
	unsigned char idemode;
	unsigned char idetrace;
	unsigned char ide8bit;
	unsigned int idecapacity;
	
	unsigned char ppideenable;
	unsigned char ppidemode;
	unsigned char ppidetrace;
	unsigned char ppide8bit;
	unsigned int ppidecapacity;
	unsigned char ppideslow;
	
	unsigned char sdenable;
	unsigned char sdmode;
	unsigned char sdtrace;
	unsigned int sdcapacity;
	unsigned char sdcsiofast;
	
	unsigned char prpenable;
	unsigned char prpsdenable;
	unsigned char prpsdtrace;
	unsigned int prpsdcapacity;
	unsigned char prpconenable;

	unsigned char pppenable;
	unsigned char pppsdenable;
	unsigned char pppsdtrace;
	unsigned int pppsdcapacity;
	unsigned char pppconenable;
	
	unsigned char hdskenable;
	unsigned char hdsktrace;
	unsigned int hdskcapacity;
	
	unsigned char ppkenable;
	unsigned char ppktrace;
	
	unsigned char kbdenable;
	unsigned char kbdtrace;
	
	unsigned char ttyenable;
	
	unsigned char ansienable;
	unsigned char ansitrace;
};

/********************/
/* eof - cnfgdata.h */
/********************/
