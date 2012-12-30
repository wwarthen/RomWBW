/* dphdpb.h 6/10/2012 dwg - CP/M Disk Parameters */

struct DPB {
	unsigned int spt;	
	unsigned char bsh;	
	unsigned char blm;	
	unsigned char exm;
	unsigned int dsm;	
	unsigned int drm;	
	unsigned char al0;	
	unsigned char al1;	
	unsigned int cks;	
	unsigned int off;	
};

struct DPH {
	unsigned int xlt;	
	unsigned int rv1;
	unsigned int rv2;
	unsigned int rv3;
	unsigned int dbf;	
	struct DPB * dpb;	
	void * csv;	
	void * alv;	
	/* extension */
	char sigl;
	char sigu;
	int current;
	int number;
};

