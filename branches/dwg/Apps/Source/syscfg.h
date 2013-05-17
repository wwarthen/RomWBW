/* syscfg.h 5/23/2012 dwg - declarations for the syscfg block */

struct SYSCFG {
	unsigned int marker;
	void * cnfloc;
	void * tstloc;
	void * varloc;
	/* cnfgdata starts here */
	struct CNFGDATA cnfgdata;
	char filler[256-3-2-2-2-sizeof(struct CNFGDATA)];	
};

#define CFGMARKER	0xA33A

/******************/
/* eof - syscfg.h */
/******************/
