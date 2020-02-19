#include "zx.h"
#include "zxbdos.h"
#include "zxdbdos.h"

/* This file used to deal with all disc-based BDOS calls. 
  Now the calls have been moved into libcpmredir, it's a bit empty round
  here. 

   ZXCC does a few odd things when searching, to make Hi-Tech C behave
   properly.
*/


/* If a file could not be found on the default drive, try again on a "search"
  drive (A: for .COM files, B: for .LIB and .OBJ files) */
  
int fcbforce(byte *fcb, byte *odrv)
{
	byte drive;
	char typ[4];	
	int n;

	for (n = 0; n < 3; n++) typ[n] = fcb[n+9] & 0x7F;
	typ[3] = 0;
	
	Msg("fcbforce: typ=%s, fcb=%hhx\r\n", typ, *fcb);

	drive = 0;
	if (*fcb) return 0;	/* not using default drive */
	//if ((*fcb) != 16) return 0;	/* not using default drive */
	if (!strcmpi(typ, "COM")) drive = 1;
	if (!strcmpi(typ, "LIB")) drive = 2; 
	if (!strcmpi(typ, "OBJ")) drive = 2;
	if (!strcmpi(typ, "H  ")) drive = 3;
	
	Msg("fcbforce: drive=%i\r\n", drive);

	if (!drive) return 0;
	
	*odrv = *fcb;
	*fcb = drive;
	return 1;
}

/* zxcc has a trick with some filenames: If it can't find them where they
       should be, and a drive wasn't specified, it searches BINDIR80, 
       LIBDIR80 or INCDIR80 (depending on the type of the file).
 */

word x_fcb_open(byte *fcb, byte *dma)
{
	word rv = fcb_open(fcb, dma);
	byte odrv;
	
	Msg("x_fcb_open: rv=%X\r\n", rv);

	if (rv == 0xFF)
	{
		if (fcbforce(fcb, &odrv))
		{
			rv = fcb_open(fcb, dma);
			Msg("x_fcb_open: rv=%X\r\n", rv);
			*fcb = odrv;
		}
	}
	return rv;
}



word x_fcb_stat(byte *fcb)
{
        word rv = fcb_stat(fcb);
        byte odrv;

        if (rv == 0xFF)
        {
                if (fcbforce(fcb, &odrv))
                {
                        rv = fcb_stat(fcb);
                        *fcb = odrv;
                }
        }
        return rv;
}



