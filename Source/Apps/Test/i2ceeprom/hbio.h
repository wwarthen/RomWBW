/* HBIO.H -- HBIOS RST 8 DIO helpers */

extern getbank();
extern devinfo();
extern blksize();
extern seekblock();
extern readblock();
extern writeblock();

#define DIODEV_I2CEEPROM 0x12
#define MAXBLKSIZ	128	/* driver caps SHIFT at 7, BLKSIZ can't exceed this */
#define MAXUNITS	16	/* devinfo() scan range, 0-15 */

extern inittail();
extern nexttoken();
extern parsenum();
extern dumpbuf();
extern scanunits();
extern listunits();
