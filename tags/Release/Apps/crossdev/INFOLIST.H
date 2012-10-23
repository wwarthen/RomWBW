/* infolist.h 6/7/2012 dwg - BIOS Information Structure version 2 */

struct INFOLIST {
	int version;
	void * banptr;
	void * varloc;
	void * tstloc;
	void * dpbmap;
	void * dphmap;
	void * ciomap;
} * pINFOLIST;

/********************/
/* eof - infolist.h */
/********************/
