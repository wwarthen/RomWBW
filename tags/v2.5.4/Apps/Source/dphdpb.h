
struct DPH {
	unsigned int xlt;	
	unsigned int rv1;
	unsigned int rv2;
	unsigned int rv3;
	unsigned int dbf;	
	void * dpb;	
	void * csv;	
	void * alv;	
	/* extension */
	unsigned char sigl;
	unsigned char sigu;
	unsigned int current;
	unsigned int number;
};

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
