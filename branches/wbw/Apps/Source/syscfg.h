/* syscfg.h 5/23/2012 dwg - declarations for the syscfg block */

struct JMP_TAG {
	unsigned char opcode;
	unsigned int address;
};


struct SYSCFG {
	struct JMP_TAG jmp;
	void * cnfloc;
	void * tstloc;
	void * varloc;
	/* cnfgdata starts here */
	struct CNFGDATA cnfgdata;
	char filler[256-3-2-2-2-sizeof(struct CNFGDATA)];	
};


/******************/
/* eof - syscfg.h */
/******************/
