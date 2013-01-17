/*
 * metadata.h 3/12/2012 dwg - 
 *
 */


extern initmeta();
extern getmeta();
extern putmeta();

#define METATRACK 0
#define METASECT  11


/*
 * This structure is the same as the metadata sector 
 * in RomWBW storage drives. (track 0 sector 11)
 *
 */
 
struct MD_TAG {
	char sig5a;
	char siga5;

	char	platform;
	char	device;
	char	formatter[8];
	char	drive;
	char	lu;

	char filler[128-34-12];
	/* ... */
	char prot;
	int updates;
	char rmj;
	char rmn;
	char rup;
	char rtp;
	char label[16];
	char term;
	unsigned int infoloc;
	unsigned int cpmloc;
	unsigned int datend;
	unsigned int cpment;
};

struct METADATA {
	unsigned int signature;
	unsigned char platform;
	unsigned char device;
	unsigned char formatter[8];
	unsigned char drive;
	unsigned int logunit;
	unsigned char unused[0x51];
	unsigned char writeprot;
	unsigned int update;
	unsigned char rmj;
	unsigned char rmn;
	unsigned char rup;
	unsigned char rtp;
	unsigned char label[16];
	unsigned char term; 
	unsigned int infloc;
	unsigned int cpmloc;
	unsigned int cpmend;
	unsigned int cpment;
} metadata;

