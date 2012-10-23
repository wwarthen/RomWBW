/* dphmap.h 5/29/2012 dwg - declaration of DPH MAP structure */

struct DPHMAP {
	struct DPH * drivea;
	struct DPH * driveb;
	struct DPH * drivec;
	struct DPH * drived;
	struct DPH * drivee;
	struct DPH * drivef;
	struct DPH * driveg;
	struct DPH * driveh;
} * pDPHMAP;

struct DPHMAP * pDPHVEC[MAXDRIVE];


/******************/
/* eof - dphmap.h */
/******************/