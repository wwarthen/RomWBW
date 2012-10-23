/* cnfgdata.h 6/04/2012 dwg - */

struct CNFGDATA {
	unsigned char rmj;
	unsigned char rmn;
	unsigned char rup;
	unsigned char rtp;
	unsigned char diskboot;
	unsigned char devunit;
	unsigned int  bootlu;
	unsigned char hour;
	unsigned char minute;
	unsigned char second;
	unsigned char month;
	unsigned char day;
	unsigned char year;
	unsigned char freq;
	unsigned char platform;
	unsigned char dioplat;
	unsigned char vdumode;
	unsigned int romsize;
	unsigned int ramsize;
	unsigned char clrramdk;
	unsigned char dskyenable;
	unsigned char uartenable;
	unsigned char vduenable;
	unsigned char fdenable;
	unsigned char fdtrace;
	unsigned char fdmedia;
	unsigned char fdmediaalt;
	unsigned char fdmauto;
	unsigned char ideenable;
	unsigned char idetrace;
	unsigned char ide8bit;
	unsigned int idecapacity;
	unsigned char ppideenable;
	unsigned char ppidetrace;
	unsigned char ppide8bit;
	unsigned int ppidecapacity;
	unsigned char ppideslow;
	unsigned char boottype;
	unsigned char boottimeout;
	unsigned char bootdefault;
	unsigned int baudrate;
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
	unsigned char pppenable;
	unsigned char pppsdenable;
	unsigned char pppsdtrace;
	unsigned int  pppsdcapacity;
	unsigned char pppconenable;
	unsigned char prpenable;
};

/********************/
/* eof - cnfgdata.h */
/********************/