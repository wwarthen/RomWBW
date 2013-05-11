/* cmemory.c 3/13/2012 dwg - */

#include "portab.h"
/* #include "cpmbind.h" */

memcmp(xptr,yptr,count)
	u8 * xptr;
	u8 * yptr;
	int count;
{
	u8 * x;
	u8 * y;
	int i;
	
	x = xptr;
	y = yptr;
	for(i=0;i<count;i++) {
		if(*x++ != *y++) return FALSE;
	}
	return TRUE;
}

memcpy(dstptr,srcptr,count)
	u8 * dstptr;
	u8 * srcptr;
	int count;
{
	u8 * s;
	u8 * d;
	int i;
		
	s = srcptr;
	d = dstptr;
	for(i=0;i<count;i++) {
	   *d++ = *s++;
	}
}

memset(dstptr,data,count)
	u8 * dstptr;
	u8 data;
	u16 count;
{
	u8 * p;
	int i;
		
	p = dstptr;
	for(i=0;i<count;i++) {
		*p++ = data;
	}	
}

	