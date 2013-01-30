/*
 * CP/M-80 v2.2 BDOS Interfaces
 * Copyright (C) Douglas W. Goodall
 * For Non-Commercial use by N8VEM
 * 5/10/2011 dwg - initial version
*/
#define EXIT_SUCCESS 0
#define EXIT_FAILURE 1

#define C_READ       1
#define C_WRITE      2
#define A_READ       3
#define A_WRITE      4
#define L_WRITE      5
#define C_RAWIO      6
#define GETIOBYTE    7
#define SETIOBYTE    8
#define C_WRITESTR   9
#define C_READSTR    10
#define F_OPEN       15
#define F_CLOSE      16
#define F_DELETE     19
#define F_READ       20
#define F_WRITE      21
#define F_MAKE       22
#define F_RENAME     23
#define DRV_LOGINVEC 24
#define DRV_GET      25
#define F_DMAOFF     26
#define DRV_ALLOCVEC 27
#define DRV_SETRO    28
#define DRV_ROVEC    29
#define F_ATTRIB     30
#define DRV_DPB      31
#define F_USERNUM    32
#define F_READRAND   33
#define F_WRITERAND  34
#define F_SIZE       35
#define F_RANDREC    36
#define DRV_RESET    37
#define F_WRITEZF    40


struct BDOSCALL {
	unsigned char func8;
	unsigned int  parm16;
};

unsigned char cpmbdos(struct BDOSCALL *p);

struct FCB {
	unsigned char drive;
	char filename[8];
	char filetype[3];
	unsigned char ex;
	unsigned char s1;
	unsigned char s2;
	unsigned char rc;
	unsigned char al[16];
	unsigned char cr;
	unsigned char r0;
	unsigned char r1;
	unsigned char r2;
};

struct READSTR {
        unsigned char size;
        unsigned char len;
        char bytes[80];
      } rsbuffer;

struct BDOSCALL readstr = { C_READSTR, { (unsigned int)&rsbuffer } };

char * mygets(char *p)
{
        memset(rsbuffer.bytes,0,sizeof(rsbuffer.bytes));
        rsbuffer.size = sizeof(rsbuffer.bytes); 
        rsbuffer.len = 0;
        cpmbdos(&readstr);
        rsbuffer.bytes[rsbuffer.len] = '\n';
        strcpy(p,rsbuffer.bytes);
        return p;
}

#define gets mygets

/*****************/
/* eof - cpm80.h */
/*****************/
