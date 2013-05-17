/*****************************/
/* floppyio.h 7/4/2012 dwg - */
/*****************************/

/*
	Call DIOMED function first 
		on return A reg contains MID_XXXX (see std.asm)
		
	Then call DIORD or DIOWR as required
	
	Whendone do BDOS Drive Reset
	
*/

#define MID_NONE  0
#define MID_MDROM 1
#define MID_MDRAM 2
#define MID_HD    3
#define MID_FD720 4
#define MID_FD144 5
#define MID_FD360 6
#define MID_FD120 7
#define MID_FD111 8


setfldma(dmaaddr)
	void * dmaaddr;
{

}


rdpsec(sector,buffer)
	int sector;
	void * buffer;
{

}


wrpsec(sector,buffer)
	int sector;
	void * buffer;
{

}


rdptrk(sector,buffer,mcnt,pspt)
	int sector;
	void * buffer;
	int mcnt;
	int pspt;
{
	int sec;
	
	for(sec=sector;sec<pspt;sec++) {
		rdpsec(sector,buffer);	
	}
}


wrptrk(sector,buffer,mcnt,pspt)
	int sector;
	void * buffer;
	int mcnt;
	int pspt;
{
	int sec;

	for(sec=sector;sec<pspt;sec++) {
		wrpsec(sector,buffer);
	}
}

/********************/
/* eof - floppyio.h */
/********************/
