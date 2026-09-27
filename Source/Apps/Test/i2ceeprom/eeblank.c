/* EEBLANK.C: blank block 0 of I2CEEPROM DIO units to 0xFF (the
   factory-erased value), via the real HBIOS DIO dispatch. A blank
   window at address 0 makes the driver's autodetect take its
   signature write path on the next boot.

   EEBLANK        blank block 0 of every I2CEEPROM unit
   EEBLANK n      blank block 0 of unit n only
   EEBLANK -R     dump block 0 of every I2CEEPROM unit, no write
   EEBLANK -R n   dump block 0 of unit n only, no write
 */

#include <stdio.h>
#include "hbio.h"

unsigned char wbuf[MAXBLKSIZ], rbuf[MAXBLKSIZ];
unsigned char bank;

/* blank (or with readonly, just dump) block 0 of one unit */
dounit(unit, readonly)
unsigned char unit;
unsigned char readonly;
{
    unsigned char i, bad;
    unsigned int blksz, blkcnt;

    blksz = blksize(unit, &blkcnt);
    if (blksz == 0 || blksz > MAXBLKSIZ) {
	printf("Unit %u reports an unusable block size (%u).\n", unit, blksz);
	return;
    }

    if (!readonly) {
	for (i = 0; i < blksz; i++)
	    wbuf[i] = 0xFF;
	if (seekblock(unit, 0) != 0 || writeblock(unit, wbuf, bank) != 0) {
	    printf("Write error on unit %u\n", unit);
	    return;
	}
    }
    if (seekblock(unit, 0) != 0 || readblock(unit, rbuf, bank) != 0) {
	printf("Read error on unit %u\n", unit);
	return;
    }

    if (readonly) {
	printf("Unit %u block 0, %u bytes\n", unit, blksz);
	dumpbuf("Read ", rbuf, blksz);
	return;
    }

    bad = 0;
    for (i = 0; i < blksz; i++)
	if (rbuf[i] != 0xFF)
	    bad++;
    if (bad == 0)
	printf("PASS: unit %u block 0 blanked, %u bytes of 0xff\n", unit, blksz);
    else {
	printf("FAIL: unit %u, %u byte(s) not 0xff\n", unit, bad);
	dumpbuf("Read ", rbuf, blksz);
    }
}

main()
{
    char arg[8];
    unsigned char i, cnt, readonly, dtype, unit;
    unsigned char units[MAXUNITS];
    unsigned int addr;

    bank = getbank();
    inittail();

    readonly = 0;
    nexttoken(arg, sizeof(arg));
    if (arg[0] == '-') {
	if (arg[1] != 'R') {
	    printf("Usage: EEBLANK [-R] [unit]\n");
	    return;
	}
	readonly = 1;
	nexttoken(arg, sizeof(arg));
    }

    if (arg[0] != 0) {
	unit = parsenum(arg);
	if (devinfo(unit, &dtype, &addr) != 0 || dtype != DIODEV_I2CEEPROM) {
	    printf("Unit %u is not an I2CEEPROM device.\n", unit);
	    return;
	}
	dounit(unit, readonly);
	return;
    }

    cnt = scanunits(units);
    if (cnt == 0) {
	printf("No I2CEEPROM units found.\n");
	return;
    }
    listunits(units, cnt);
    for (i = 0; i < cnt; i++)
	dounit(units[i], readonly);
}
